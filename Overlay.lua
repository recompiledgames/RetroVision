-- RetroVision: retro screen layers (the "shader" part).
-- Add-ons can't run pixel shaders, so every effect is a texture drawn over the
-- screen with BLEND (darken), ADD (brighten) or MOD (multiply) blending.
--
-- Techniques borrowed from well-known shaders (re-implemented, no code copied):
--   * CRT-Lottes / CRT-Royale / Guest-Advanced: Gaussian electron-beam scanlines set
--     by line count with adjustable hardness, sub-pixel phosphor masks (2-px
--     magenta/green, 3-px RGB, slot, dot triad) and brightness compensation.
--   * Film grain models: zero-mean Gaussian grain (dark and light), animated frames,
--     optional chroma grain; dust and scratches.
--   * VHS/NTSC simulators (ntsc-rs etc.): tracking band, head-switching noise at the
--     bottom, snow, tape dropouts, on-screen display.
local ADDON, ns = ...

local Overlay = {}
ns.Overlay = Overlay

local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Textures\\"
local random, floor, max, min = math.random, math.floor, math.max, math.min

local root = CreateFrame("Frame", "RetroVisionOverlay", WorldFrame)
root:SetAllPoints(WorldFrame)
root:EnableMouse(false)
root:Hide()
Overlay.root = root

local function prep(t, blend)
	if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
	if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
	t._blend = blend or "BLEND"
	t:Hide()
	return t
end

local function full(layer, sub, blend)
	local t = root:CreateTexture(nil, layer, nil, sub)
	t:SetAllPoints(root)
	return prep(t, blend)
end

-- bottom to top
local L = {
	tint     = full("BACKGROUND", -8, "MOD"),
	lift     = full("BACKGROUND", -6, "ADD"),
	dim      = full("BACKGROUND", -4, "BLEND"),
	ditherD  = full("BORDER", -8, "BLEND"),
	ditherL  = full("BORDER", -7, "ADD"),
	lcd      = full("BORDER", -6, "BLEND"),
	scan     = full("ARTWORK", -8, "BLEND"),
	mask     = full("ARTWORK", -6, "MOD"),
	grainD   = full("ARTWORK", 0, "BLEND"),
	grainL   = full("ARTWORK", 1, "ADD"),
	snow     = full("ARTWORK", 2, "ADD"),
	glare    = full("OVERLAY", -7, "ADD"),
	vignette = full("OVERLAY", -8, "BLEND"),
	flicker  = full("OVERLAY", -6, "BLEND"),
}

local vhs = prep(root:CreateTexture(nil, "ARTWORK", nil, 4), "ADD")
local roll = prep(root:CreateTexture(nil, "ARTWORK", nil, 5), "ADD")
local headDark = prep(root:CreateTexture(nil, "ARTWORK", nil, 5), "BLEND")
local headNoise = prep(root:CreateTexture(nil, "ARTWORK", nil, 6), "ADD")

local drops = {}
for i = 1, 6 do drops[i] = prep(root:CreateTexture(nil, "ARTWORK", nil, 6), "ADD") end
local dust = {}
for i = 1, 6 do dust[i] = prep(root:CreateTexture(nil, "ARTWORK", nil, 3), "BLEND") end
local scratches = {}
for i = 1, 2 do scratches[i] = prep(root:CreateTexture(nil, "ARTWORK", nil, 3), "ADD") end

local corners = {}
local CORNER_POINTS = {
	{ "TOPLEFT", 0, 1, 0, 1 }, { "TOPRIGHT", 1, 0, 0, 1 },
	{ "BOTTOMLEFT", 0, 1, 1, 0 }, { "BOTTOMRIGHT", 1, 0, 1, 0 },
}
for i, c in ipairs(CORNER_POINTS) do
	local t = prep(root:CreateTexture(nil, "OVERLAY", nil, 2))
	t:SetPoint(c[1], root, c[1])
	t._coords = { c[2], c[3], c[4], c[5] }
	corners[i] = t
end

local bars = {}
for i = 1, 4 do
	bars[i] = prep(root:CreateTexture(nil, "OVERLAY", nil, 7))
	bars[i]:SetColorTexture(0, 0, 0, 1)
end

-- camcorder on-screen display
local osd = {}
for _, k in ipairs({ "play", "mode", "clock" }) do
	osd[k] = root:CreateFontString(nil, "OVERLAY")
	osd[k]:Hide()
end

-- phosphor masks: texture size, filtering, and how much light each lets through
-- at full strength (measured when the textures were generated)
local MASKS = {
	mg2    = { w = 2, h = 2, filter = "NEAREST", lum = 0.59 },
	rgb3   = { w = 64, h = 4, filter = "LINEAR", px = 3, lum = 0.457 },
	grille = { w = 4, h = 4, filter = "NEAREST", lum = 0.59 },
	slot   = { w = 8, h = 4, filter = "NEAREST", lum = 0.5725 },
	dots   = { w = 4, h = 4, filter = "NEAREST", lum = 0.615 },
}
local SCAN_DARK = { 0.42, 0.507, 0.592, 0.68, 0.75 }   -- average darkening per beam hardness

---------------------------------------------------------------------------
-- pixel helpers
---------------------------------------------------------------------------
-- UI units per physical screen pixel
function Overlay:PixelSize()
	local _, ph = GetPhysicalScreenSize()
	local scale = root:GetEffectiveScale()
	if not ph or ph <= 0 or not scale or scale <= 0 then return 1 end
	return (768 / ph) / scale
end

function Overlay:ScreenPixels()
	local px = self:PixelSize()
	local w, h = root:GetWidth(), root:GetHeight()
	if not w or w <= 0 or not h or h <= 0 then return GetPhysicalScreenSize() end
	return w / px, h / px
end

-- repeat a texture so one tile covers tilePxW x tilePxH screen pixels
local function setTiled(t, file, tilePxW, tilePxH, filter)
	t:SetTexture(TEX .. file, "REPEAT", "REPEAT", filter or "NEAREST")
	t:SetBlendMode(t._blend)
	t._tpw, t._tph = tilePxW, tilePxH
	Overlay:Retile(t)
	t:Show()
end

function Overlay:Retile(t, ou, ov)
	if not t._tpw then return end
	local pw, ph = self:ScreenPixels()
	ou, ov = ou or 0, ov or 0
	t:SetTexCoord(ou, ou + pw / t._tpw, ov, ov + ph / t._tph)
end

local function solid(t, r, g, b, a)
	t:SetColorTexture(r, g, b, a or 1)
	t:SetBlendMode(t._blend)
	t:Show()
end

-- how much light the scanlines + mask keep (0..1), for brightness compensation
function Overlay:LightKept(s)
	local kept = 1
	if s.scanlines then
		kept = kept * (1 - s.scanAlpha * (SCAN_DARK[s.scanHard] or 0.59))
	end
	local m = MASKS[s.mask]
	if m then kept = kept * (1 - (1 - m.lum) * s.maskStrength) end
	return kept
end

-- gamma multiplier that gives back the light scanlines and masks take away
function Overlay:Compensation(s)
	if not s.crtBoost or not (s.scanlines or MASKS[s.mask]) then return 1 end
	return min(2.2, 1 + (1 - self:LightKept(s)) * 2 * s.crtBoostAmt)
end

---------------------------------------------------------------------------
-- layout (screen size / UI scale changes)
---------------------------------------------------------------------------
function Overlay:Layout()
	local s = self.s
	if not s then return end
	for _, t in pairs(L) do
		if t:IsShown() then self:Retile(t) end
	end

	local px = self:PixelSize()
	local size = (s.cornerRadius or 32) * px
	for _, t in ipairs(corners) do t:SetSize(size, size) end

	local w, h = root:GetWidth(), root:GetHeight()
	vhs:SetHeight(math.max(1, h * 0.08))
	roll:SetHeight(math.max(1, h * 0.35))

	-- head-switching noise lives in the bottom few lines of the picture
	local hh = h * 0.025
	headDark:ClearAllPoints()
	headDark:SetPoint("BOTTOMLEFT"); headDark:SetPoint("BOTTOMRIGHT"); headDark:SetHeight(hh)
	headNoise:ClearAllPoints()
	headNoise:SetPoint("BOTTOMLEFT"); headNoise:SetPoint("BOTTOMRIGHT"); headNoise:SetHeight(hh)

	-- camcorder text
	local fs = math.max(10, h * 0.042)
	for _, f in pairs(osd) do
		f:SetFont("Fonts\\ARIALN.TTF", fs, "OUTLINE")
		f:SetShadowOffset(fs * 0.08, -fs * 0.08)
		f:SetShadowColor(0, 0, 0, 0.8)
		f:ClearAllPoints()
	end
	osd.play:SetPoint("TOPLEFT", root, "TOPLEFT", w * 0.06, -h * 0.07)
	osd.mode:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", w * 0.06, h * 0.08)
	osd.clock:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -w * 0.06, h * 0.08)

	for _, b in ipairs(bars) do b:ClearAllPoints(); b:Hide() end
	local A = (type(s.letterbox) == "number" and s.letterbox >= 1) and s.letterbox or nil
	if A and w > 0 and h > 0 then
		if w / h > A + 0.001 then -- pillarbox
			local bw = (w - h * A) / 2
			bars[1]:SetPoint("TOPLEFT"); bars[1]:SetPoint("BOTTOMLEFT"); bars[1]:SetWidth(bw)
			bars[2]:SetPoint("TOPRIGHT"); bars[2]:SetPoint("BOTTOMRIGHT"); bars[2]:SetWidth(bw)
			bars[1]:Show(); bars[2]:Show()
		elseif w / h < A - 0.001 then -- letterbox
			local bh = (h - w / A) / 2
			bars[3]:SetPoint("TOPLEFT"); bars[3]:SetPoint("TOPRIGHT"); bars[3]:SetHeight(bh)
			bars[4]:SetPoint("BOTTOMLEFT"); bars[4]:SetPoint("BOTTOMRIGHT"); bars[4]:SetHeight(bh)
			bars[3]:Show(); bars[4]:Show()
		end
	end
end

---------------------------------------------------------------------------
-- animation
---------------------------------------------------------------------------
local anim = { grain = 0, frame = 1, flick = 0, inter = 0, interOn = false, vhsY = -0.3, vhsJ = 0,
	rollY = 0, head = 0, snow = 0, film = 0, osd = 0, start = 0 }

local function grainFrame(s)
	anim.frame = anim.frame % 4 + 1
	local f = anim.frame
	L.grainD:SetTexture(TEX .. "grainD_" .. f, "REPEAT", "REPEAT", "LINEAR")
	L.grainL:SetTexture(TEX .. (s.grainChroma and "grainC_" or "grainL_") .. f, "REPEAT", "REPEAT", "LINEAR")
	Overlay:Retile(L.grainD, random(), random())
	Overlay:Retile(L.grainL, random(), random())
end

local function onUpdate(self, elapsed)
	local s = Overlay.s
	local W, H = root:GetWidth(), root:GetHeight()
	if s.grain then
		anim.grain = anim.grain + elapsed
		if anim.grain >= 1 / s.grainFPS then
			anim.grain = 0
			grainFrame(s)
		end
	end
	if s.flicker then
		anim.flick = anim.flick + elapsed
		if anim.flick >= 0.05 then
			anim.flick = 0
			L.flicker:SetAlpha(random() * s.flickerAmount)
		end
	end
	if s.scanlines and s.interlace then
		anim.inter = anim.inter + elapsed
		if anim.inter >= 1 / 30 then
			anim.inter = 0
			anim.interOn = not anim.interOn
			Overlay:Retile(L.scan, 0, anim.interOn and 0.5 or 0)
		end
	end
	if s.rollBar then
		anim.rollY = (anim.rollY + elapsed * s.rollSpeed) % 1.35
		roll:ClearAllPoints()
		roll:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -(anim.rollY - 0.35) * H)
		roll:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, -(anim.rollY - 0.35) * H)
	end
	if s.vhs then
		anim.vhsY = anim.vhsY + elapsed * s.vhsSpeed * 0.25
		if anim.vhsY > 1.1 then anim.vhsY = -0.15 - random() * 0.8 end -- random pause off-screen
		local y = -anim.vhsY * H
		vhs:ClearAllPoints()
		vhs:SetPoint("TOPLEFT", root, "TOPLEFT", 0, y)
		vhs:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, y)
		anim.vhsJ = anim.vhsJ + elapsed
		if anim.vhsJ >= 1 / 30 then
			anim.vhsJ = 0
			local o = random()
			vhs:SetTexCoord(o, o + 1.5, 0, 1)
			local a = s.vhsAlpha * (0.6 + 0.4 * random())
			vhs:SetVertexColor(a, a, a)
		end
	end
	if s.vhsHead or s.vhsSnow > 0 or s.vhsDrop > 0 then
		anim.head = anim.head + elapsed
		if anim.head >= 1 / 30 then
			anim.head = 0
			if s.vhsHead then
				local o = random()
				headNoise:SetTexCoord(o, o + 2 + random(), random() * 0.5, 0.5 + random() * 0.5)
				local a = 0.5 + 0.5 * random()
				headNoise:SetVertexColor(a, a, a)
			end
			if s.vhsSnow > 0 then Overlay:Retile(L.snow, random(), random()) end
			if s.vhsDrop > 0 then
				for _, d in ipairs(drops) do
					if d:IsShown() then
						d._life = d._life - 1 / 30
						if d._life <= 0 then d:Hide() end
					elseif random() < s.vhsDrop * 0.05 then
						d:ClearAllPoints()
						d:SetPoint("TOPLEFT", root, "TOPLEFT", random() * W, -random() * H)
						d:SetSize(W * (0.02 + random() * 0.12), H * (0.002 + random() * 0.003))
						d._life = 0.04 + random() * 0.1
						d:Show()
					end
				end
			end
		end
	end
	if s.filmDamage > 0 then
		anim.film = anim.film + elapsed
		if anim.film >= 1 / 24 then
			anim.film = 0
			local amt = s.filmDamage
			for _, d in ipairs(dust) do
				if random() < amt * 0.25 then
					local sz = H * (0.004 + random() * 0.018)
					d:ClearAllPoints()
					d:SetPoint("CENTER", root, "BOTTOMLEFT", random() * W, random() * H)
					d:SetSize(sz, sz * (0.6 + random() * 0.8))
					d:SetAlpha(0.35 + random() * 0.5)
					d:Show()
				else
					d:Hide()
				end
			end
			for _, sc in ipairs(scratches) do
				if sc:IsShown() then
					if random() < 0.12 then sc:Hide() else
						sc._x = sc._x + (random() - 0.5) * W * 0.004
						sc:ClearAllPoints()
						sc:SetPoint("TOP", root, "TOPLEFT", sc._x, 0)
						sc:SetPoint("BOTTOM", root, "BOTTOMLEFT", sc._x, 0)
						sc:SetAlpha((0.2 + random() * 0.3) * amt)
					end
				elseif random() < amt * 0.04 then
					sc._x = random() * W
					sc:ClearAllPoints()
					sc:SetPoint("TOP", root, "TOPLEFT", sc._x, 0)
					sc:SetPoint("BOTTOM", root, "BOTTOMLEFT", sc._x, 0)
					sc:SetWidth(max(1, Overlay:PixelSize() * (1 + random() * 2)))
					sc:Show()
				end
			end
		end
	end
	if s.vhsOSD then
		anim.osd = anim.osd + elapsed
		if anim.osd >= 0.5 then
			anim.osd = 0
			local t = floor(GetTime() - anim.start)
			osd.clock:SetText(string.format("%d:%02d:%02d", floor(t / 3600), floor(t / 60) % 60, t % 60))
			osd.play:SetAlpha(0.75 + 0.25 * random())
		end
	end
end

---------------------------------------------------------------------------
-- apply settings
---------------------------------------------------------------------------
function Overlay:Apply(s, enabled, coverUI)
	self.s = s
	if not enabled then
		root:Hide()
		root:SetScript("OnUpdate", nil)
		return
	end

	if coverUI then
		root:SetFrameStrata("FULLSCREEN")
		root:SetFrameLevel(5010)
	else
		root:SetFrameStrata("BACKGROUND")
		root:SetFrameLevel(10)
	end

	for _, t in pairs(L) do t:Hide(); t._tpw = nil end
	for _, t in ipairs({ vhs, roll, headDark, headNoise }) do t:Hide() end
	for _, t in ipairs(drops) do t:Hide() end
	for _, t in ipairs(dust) do t:Hide() end
	for _, t in ipairs(scratches) do t:Hide() end
	for _, t in ipairs(corners) do t:Hide() end
	for _, f in pairs(osd) do f:Hide() end

	local pw, ph = self:ScreenPixels()

	-- color: multiply tint, additive shadow lift, dimming
	if s.tint then
		local k = s.tintStrength
		solid(L.tint, 1 - (1 - s.tintR) * k, 1 - (1 - s.tintG) * k, 1 - (1 - s.tintB) * k, 1)
	end
	if s.lift then
		local a = s.liftAlpha
		solid(L.lift, s.liftR * a, s.liftG * a, s.liftB * a, 1)
	end
	if s.dim > 0 then solid(L.dim, 0, 0, 0, s.dim) end

	-- dithering: Bayer 4x4, Bayer 8x8 or blue noise
	if s.dither then
		local base, n = "dither", 4
		if s.ditherType == "bayer8" then base, n = "dither8", 8
		elseif s.ditherType == "blue" then base, n = "bluenoise", 64 end
		local sc = s.ditherScale
		setTiled(L.ditherD, base .. "_dark", n * sc, n * sc)
		L.ditherD:SetAlpha(s.ditherAlpha)
		setTiled(L.ditherL, base .. "_light", n * sc, n * sc)
		L.ditherL:SetVertexColor(s.ditherAlpha, s.ditherAlpha, s.ditherAlpha)
	end

	-- handheld LCD pixel grid, lined up with the virtual pixels
	if s.lcdGrid then
		local cell = s.lcdCell
		if cell <= 0 then cell = (s.rPixel < 0.995) and (1 / s.rPixel) or 3 end
		setTiled(L.lcd, "lcdgrid", cell, cell, "LINEAR")
		L.lcd:SetAlpha(s.lcdAlpha)
	end

	-- Gaussian beam scanlines: one tile = one scanline, sized by line count
	if s.scanlines then
		local lineH = ph / max(60, s.scanLines)
		setTiled(L.scan, "scanbeam_" .. max(1, min(5, floor(s.scanHard + 0.5))), 4, lineH, "LINEAR")
		L.scan:SetAlpha(s.scanAlpha)
	end

	-- phosphor mask
	local m = MASKS[s.mask]
	if m then
		local lvl = max(1, min(20, floor(s.maskStrength * 20 + 0.5)))
		local mult = s.maskScale
		local tw = (m.px or m.w) * mult
		local th = m.h * mult
		setTiled(L.mask, "mask_" .. s.mask .. "_" .. lvl, tw, th, m.filter)
	end

	-- film grain: zero-mean Gaussian, dark and light halves, 4 animated frames
	if s.grain then
		local gs = s.grainSize
		setTiled(L.grainD, "grainD_1", 256 * gs, 256 * gs, "LINEAR")
		L.grainD:SetAlpha(min(1, s.grainAlpha * 1.6))
		setTiled(L.grainL, (s.grainChroma and "grainC_1" or "grainL_1"), 256 * gs, 256 * gs, "LINEAR")
		local a = min(1, s.grainAlpha * 1.4)
		L.grainL:SetVertexColor(a, a, a)
	end

	-- VHS
	if s.vhs then
		vhs:SetTexture(TEX .. "vhs", "REPEAT", "CLAMP")
		vhs:SetBlendMode("ADD")
		vhs:SetVertexColor(s.vhsAlpha, s.vhsAlpha, s.vhsAlpha)
		vhs:Show()
	end
	if s.vhsHead then
		headDark:SetColorTexture(0, 0, 0, 0.55); headDark:SetBlendMode("BLEND"); headDark:Show()
		headNoise:SetTexture(TEX .. "vhs", "REPEAT", "REPEAT"); headNoise:SetBlendMode("ADD"); headNoise:Show()
	end
	if s.vhsSnow > 0 then
		setTiled(L.snow, "snow", 256, 256)
		L.snow:SetVertexColor(s.vhsSnow, s.vhsSnow, s.vhsSnow)
	end
	for _, d in ipairs(drops) do
		d:SetTexture(TEX .. "p_line")
		d:SetBlendMode("ADD")
		d:SetVertexColor(0.9, 0.9, 0.9)
	end
	if s.vhsOSD then
		anim.start = GetTime()
		osd.play:SetText("PLAY  >"); osd.play:SetTextColor(1, 1, 1)
		osd.mode:SetText("SP"); osd.mode:SetTextColor(1, 1, 1)
		osd.clock:SetText("0:00:00"); osd.clock:SetTextColor(1, 1, 1)
		for _, f in pairs(osd) do f:Show() end
	end

	-- film damage textures
	for _, d in ipairs(dust) do d:SetTexture(TEX .. "dust"); d:SetBlendMode("BLEND"); d:SetVertexColor(0.05, 0.04, 0.03) end
	for _, sc in ipairs(scratches) do sc:SetTexture(TEX .. "scratch"); sc:SetBlendMode("ADD") end

	-- CRT glass glare and rolling refresh bar
	if s.glare then
		L.glare:SetTexture(TEX .. "glare")
		L.glare:SetTexCoord(0, 1, 0, 1)
		L.glare:SetBlendMode("ADD")
		L.glare:SetVertexColor(s.glareAlpha, s.glareAlpha, s.glareAlpha)
		L.glare:Show()
	end
	if s.rollBar then
		roll:SetTexture(TEX .. "rollbar")
		roll:SetBlendMode("ADD")
		roll:SetVertexColor(s.rollAlpha, s.rollAlpha, s.rollAlpha)
		roll:Show()
	end

	if s.vignette then
		L.vignette:SetTexture(TEX .. "vignette_hd")
		L.vignette:SetTexCoord(0, 1, 0, 1)
		L.vignette:SetBlendMode("BLEND")
		L.vignette:SetAlpha(s.vignetteAlpha)
		L.vignette:Show()
	end

	if s.flicker then
		solid(L.flicker, 0, 0, 0, 1)
		L.flicker:SetAlpha(0)
	end

	if s.corners then
		for _, t in ipairs(corners) do
			t:SetTexture(TEX .. "corner")
			t:SetTexCoord(unpack(t._coords))
			t:SetBlendMode("BLEND")
			t:Show()
		end
	end

	self:Layout()
	root:Show()

	local animated = s.grain or s.flicker or s.vhs or (s.scanlines and s.interlace) or s.rollBar
		or s.vhsHead or s.vhsSnow > 0 or s.vhsDrop > 0 or s.filmDamage > 0 or s.vhsOSD
	root:SetScript("OnUpdate", animated and onUpdate or nil)
end
