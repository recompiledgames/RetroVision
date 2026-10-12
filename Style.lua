-- RetroVision: stylized "game look" layers - comic ink frame, halftone dots,
-- crosshatching, anime speed lines, graffiti paint splatters, color fringing
-- and paper texture. Sits above the pretty effects and below the retro filters.
local ADDON, ns = ...

local Style = {}
ns.Style = Style

local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Textures\\"
local random, sin, cos, max, min = math.random, math.sin, math.cos, math.max, math.min
local TAU = math.pi * 2

local root = CreateFrame("Frame", "RetroVisionStyle", WorldFrame)
root:SetAllPoints(WorldFrame)
root:EnableMouse(false)
root:Hide()
Style.root = root

local function tex(layer, sub)
	local t = root:CreateTexture(nil, layer, nil, sub)
	if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
	if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
	t:Hide()
	return t
end

local L = {
	paper = tex("BACKGROUND", 0),
	halftone = tex("BORDER", 0),
	hatch = tex("BORDER", 1),
	fringeL = tex("ARTWORK", 0),
	fringeR = tex("ARTWORK", 0),
	ink = tex("OVERLAY", 7),
}
for _, k in ipairs({ "paper", "halftone", "hatch" }) do L[k]:SetAllPoints(root) end
local splats = { tex("OVERLAY", 4), tex("OVERLAY", 4), tex("OVERLAY", 4), tex("OVERLAY", 4) }
local SPLAT = {
	{ "TOPLEFT", 0, 1, 0, 1, "A" }, { "TOPRIGHT", 1, 0, 0, 1, "B" },
	{ "BOTTOMLEFT", 0, 1, 1, 0, "B" }, { "BOTTOMRIGHT", 1, 0, 1, 0, "A" },
}

-- "edges only" masks (clients without mask textures just show the full pattern)
local function edgeMask(t)
	if not root.CreateMaskTexture or not t.AddMaskTexture then return nil end
	local ok, m = pcall(root.CreateMaskTexture, root)
	if not ok or not m then return nil end
	pcall(m.SetTexture, m, TEX .. "edgeglow", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(root)
	return m
end
local masks = {}
local function setMasked(t, key, on)
	if on and not masks[key] then masks[key] = edgeMask(t) end
	local m = masks[key]
	if not m then return end
	if on and not t._masked then
		pcall(t.AddMaskTexture, t, m); t._masked = true
	elseif not on and t._masked then
		pcall(t.RemoveMaskTexture, t, m); t._masked = false
	end
end

local function tile(t, tw, th, mult)
	local pw, ph = ns.Overlay:ScreenPixels()
	t:SetTexCoord(0, pw / (tw * mult), 0, ph / (th * mult))
end

---------------------------------------------------------------------------
-- speed lines (drawn as Line regions so they stay crisp at any angle)
---------------------------------------------------------------------------
local lines = {}
local canLine = root.CreateLine ~= nil
local function getLine(i)
	local l = lines[i]
	if not l then
		l = root:CreateLine(nil, "ARTWORK", nil, 3)
		if l.SetSnapToPixelGrid then pcall(l.SetSnapToPixelGrid, l, false) end
		if l.SetTexelSnappingBias then pcall(l.SetTexelSnappingBias, l, 0) end
		l:SetTexture(TEX .. "speedline")
		l:SetBlendMode("BLEND")
		lines[i] = l
	end
	return l
end

local function rollSpeedLines(s, W, H)
	local cx, cy = W / 2, H / 2
	local R = math.sqrt(cx * cx + cy * cy)
	local n = math.floor(s.speedCount + 0.5)
	for i = 1, n do
		local l = getLine(i)
		local a = random() * TAU
		local inner = R * (1 - s.speedLen * (0.55 + 0.45 * random()))
		local ca, sa = cos(a), sin(a)
		l:SetStartPoint("BOTTOMLEFT", root, cx + ca * R * 1.05, cy + sa * R * 1.05)
		l:SetEndPoint("BOTTOMLEFT", root, cx + ca * inner, cy + sa * inner)
		l:SetThickness(2 + random() * 9)
		l:SetVertexColor(s.speedR, s.speedG, s.speedB)
		l:SetAlpha(s.speedAlpha * (0.4 + 0.6 * random()))
		l:Show()
	end
	for i = n + 1, #lines do lines[i]:Hide() end
end

local acc = 0
local function onUpdate(self, dt)
	local s = Style.s
	acc = acc + dt
	if acc >= 1 / max(1, s.speedFPS) then
		acc = 0
		rollSpeedLines(s, root:GetWidth(), root:GetHeight())
	end
end

---------------------------------------------------------------------------
-- apply
---------------------------------------------------------------------------
function Style:Apply(s, enabled, coverUI)
	self.s = s
	if not enabled then
		root:Hide()
		root:SetScript("OnUpdate", nil)
		return
	end
	if coverUI then
		root:SetFrameStrata("FULLSCREEN"); root:SetFrameLevel(5005)
	else
		root:SetFrameStrata("BACKGROUND"); root:SetFrameLevel(5)
	end
	local W, H = root:GetWidth(), root:GetHeight()
	if not W or W <= 0 then W, H = 1366, 768 end

	for _, t in pairs(L) do t:Hide() end
	for _, t in ipairs(splats) do t:Hide() end
	for _, l in ipairs(lines) do l:Hide() end

	if s.paper then
		local t = L.paper
		t:SetTexture(TEX .. "paper", "REPEAT", "REPEAT")
		t:SetBlendMode("BLEND")
		t:SetVertexColor(s.paperR, s.paperG, s.paperB)
		t:SetAlpha(s.paperAlpha)
		tile(t, 1024, 1024, s.paperScale)
		t:Show()
	end
	if s.halftone then
		local t = L.halftone
		t:SetTexture(TEX .. "halftone", "REPEAT", "REPEAT")
		t:SetBlendMode("BLEND")
		t:SetVertexColor(s.htR, s.htG, s.htB)
		t:SetAlpha(s.htAlpha)
		tile(t, 256, 256, s.htScale)
		setMasked(t, "halftone", s.htEdges)
		t:Show()
	end
	if s.hatch then
		local t = L.hatch
		t:SetTexture(TEX .. "hatch", "REPEAT", "REPEAT")
		t:SetBlendMode("BLEND")
		t:SetVertexColor(s.hatchR, s.hatchG, s.hatchB)
		t:SetAlpha(s.hatchAlpha)
		tile(t, 256, 256, s.hatchScale)
		setMasked(t, "hatch", s.hatchEdges)
		t:Show()
	end
	if s.fringe then
		local w = W * s.fringeWidth
		local a = s.fringeAlpha
		for side, t in pairs({ L = L.fringeL, R = L.fringeR }) do
			t:SetTexture(TEX .. "fringe")
			t:SetBlendMode("ADD")
			t:ClearAllPoints()
			if side == "L" then
				t:SetPoint("TOPLEFT", root, "TOPLEFT"); t:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT")
				t:SetTexCoord(0, 1, 0, 1)
				t:SetVertexColor(s.fringeLR * a, s.fringeLG * a, s.fringeLB * a)
			else
				t:SetPoint("TOPRIGHT", root, "TOPRIGHT"); t:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT")
				t:SetTexCoord(1, 0, 0, 1)
				t:SetVertexColor(s.fringeRR * a, s.fringeRG * a, s.fringeRB * a)
			end
			t:SetWidth(w)
			t:Show()
		end
	end
	if s.splat then
		local size = H * s.splatSize
		for i, t in ipairs(splats) do
			local c = SPLAT[i]
			t:SetTexture(TEX .. "splatter")
			t:SetBlendMode("BLEND")
			t:ClearAllPoints()
			t:SetPoint(c[1], root, c[1])
			t:SetSize(size, size)
			t:SetTexCoord(c[2], c[3], c[4], c[5])
			if c[6] == "A" then
				t:SetVertexColor(s.splatAR, s.splatAG, s.splatAB)
			else
				t:SetVertexColor(s.splatBR, s.splatBG, s.splatBB)
			end
			t:SetAlpha(s.splatAlpha)
			t:Show()
		end
	end
	if s.ink then
		local t = L.ink
		local o = (1 - s.inkThick) * 0.1024 * H
		t:SetTexture(TEX .. "inkframe")
		t:SetBlendMode("BLEND")
		t:SetVertexColor(s.inkR, s.inkG, s.inkB)
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", root, "TOPLEFT", -o, o)
		t:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", o, -o)
		t:Show()
	end

	root:Show()
	local animated = s.speed and canLine
	if animated then rollSpeedLines(s, W, H) end
	root:SetScript("OnUpdate", animated and onUpdate or nil)
end
