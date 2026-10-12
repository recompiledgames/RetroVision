-- RetroVision: color filters (Instagram-style grading) and trippy color effects.
--
-- Add-ons can only multiply the picture (MOD) or add light to it (ADD), so every
-- channel becomes  out = in * m + a.  That covers warmth, tint, fade, split toning
-- and animated color wobble. For real cross-channel hue shifts we drive the game's
-- own full-screen color filter, and gamma/contrast/camera through game settings.
local ADDON, ns = ...

local Filter = {}
ns.Filter = Filter

local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Textures\\"
local sin, cos, floor, min, max, abs = math.sin, math.cos, math.floor, math.min, math.max, math.abs
local TAU = math.pi * 2

local root = CreateFrame("Frame", "RetroVisionFilter", WorldFrame)
root:SetAllPoints(WorldFrame)
root:EnableMouse(false)
root:Hide()
Filter.root = root

local function tex(layer, sub)
	local t = root:CreateTexture(nil, layer, nil, sub)
	if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
	if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
	t:SetAllPoints(root)
	t:Hide()
	return t
end

local L = {
	mul = tex("BACKGROUND", -8),
	wobMul = tex("BACKGROUND", -7),
	rainbow = tex("BACKGROUND", -6),
	add = tex("BORDER", -8),
	wobAdd = tex("BORDER", -7),
	strobe = tex("ARTWORK", 0),
	vig = tex("OVERLAY", 0),
}

local function clamp(x, a, b) return max(a or 0, min(b or 1, x)) end

---------------------------------------------------------------------------
-- static grade: returns multiply color, add color
---------------------------------------------------------------------------
function Filter:Grade(s)
	local k = s.fAmount
	local mr, mg, mb = 1, 1, 1
	local w = s.fWarm
	if w > 0 then
		mb = mb * (1 - 0.42 * w); mg = mg * (1 - 0.1 * w)
	elseif w < 0 then
		mr = mr * (1 + 0.42 * w); mg = mg * (1 + 0.08 * w)
	end
	local t = s.fTint
	if t > 0 then
		mg = mg * (1 - 0.35 * t)
	elseif t < 0 then
		mr = mr * (1 + 0.3 * t); mb = mb * (1 + 0.3 * t)
	end
	local h = s.fHi
	mr = mr * (1 - (1 - s.fHiR) * h)
	mg = mg * (1 - (1 - s.fHiG) * h)
	mb = mb * (1 - (1 - s.fHiB) * h)
	local f = s.fFade
	mr, mg, mb = mr * (1 - 0.14 * f), mg * (1 - 0.14 * f), mb * (1 - 0.14 * f)
	local sh = s.fSh * 0.28
	local ar, ag, ab = s.fShR * sh + 0.17 * f, s.fShG * sh + 0.17 * f, s.fShB * sh + 0.17 * f
	-- overall intensity: mix toward "no change"
	mr, mg, mb = 1 - (1 - mr) * k, 1 - (1 - mg) * k, 1 - (1 - mb) * k
	return clamp(mr), clamp(mg), clamp(mb), ar * k, ag * k, ab * k
end

-- how much to brighten midtones (via gamma) to make up for the multiply darkening
function Filter:ExposureComp(s)
	if not (s.filter and s.fAuto) then return 1 end
	local mr, mg, mb = self:Grade(s)
	local lum = 0.3 * mr + 0.59 * mg + 0.11 * mb
	return min(1.7, 1 + (1 - lum) * 1.5)
end

---------------------------------------------------------------------------
-- animation
---------------------------------------------------------------------------
local cvarAcc, lastRemapType = 0, nil

local function onUpdate(self, dt)
	local s = Filter.s
	local now = GetTime()

	if s.tripWobble then
		local d, sp = s.wobDepth, s.wobSpeed * TAU
		local r = 1 - d * (0.5 + 0.5 * sin(now * sp))
		local g = 1 - d * (0.5 + 0.5 * sin(now * sp * 1.13 + 2.1))
		local b = 1 - d * (0.5 + 0.5 * sin(now * sp * 0.87 + 4.2))
		L.wobMul:SetColorTexture(r, g, b, 1)
		local gl = s.wobGlow * 0.22
		L.wobAdd:SetColorTexture((1 - r) * gl, (1 - g) * gl, (1 - b) * gl, 1)
	end
	if s.tripRainbow then
		Filter:PlaceRainbow(s, now)
	end
	if s.tripStrobe then
		local beat = 60 / max(30, s.strobeBPM)
		local n = floor(now / beat)
		local tIn = now - n * beat
		local env = math.exp(-tIn * 10) * s.strobeAlpha
		local r, g, b = ns.Pretty.hsv(n * 0.37, 0.85, 1)
		L.strobe:SetColorTexture(r * env, g * env, b * env, 1)
	end

	-- game-setting animation (throttled)
	cvarAcc = cvarAcc + dt
	if cvarAcc >= 0.05 then
		cvarAcc = 0
		local set = {}
		local base = ns.Render.lastWant or {}
		if s.tripRemap then
			local ph = now * s.remapSpeed
			local ty = 1 + floor(ph) % 3
			if ty ~= lastRemapType then
				lastRemapType = ty
				if base.colorblindShader then set.colorblindShader = ty else set.colorblindSimulator = ty end
			end
			set.colorblindWeaknessFactor = string.format("%.2f", 0.25 + 0.75 * (0.5 + 0.5 * sin(ph * TAU)))
		end
		if s.tripGamma then
			local g0 = tonumber(base.Gamma) or 1
			set.Gamma = string.format("%.2f", clamp(g0 * (1 + s.gPulse * sin(now * s.gSpeed * TAU)), 0.3, 2.8))
		end
		if s.tripSway then
			local o0 = tonumber(base.test_cameraOverShoulder) or 0
			set.test_cameraOverShoulder = string.format("%.2f", o0 + s.swayAmt * sin(now * s.swaySpeed * TAU))
		end
		if s.tripFov then
			local f0 = tonumber(base.cameraFov) or 75
			set.cameraFov = string.format("%d", clamp(f0 + s.fovAmt * sin(now * s.fovSpeed * TAU), 50, 90))
		end
		ns.Render:Animate(set)
	end
end

function Filter:PlaceRainbow(s, now)
	local W, H = root:GetWidth(), root:GetHeight()
	if not W or W <= 0 then return end
	local a = math.rad(s.rbAngle)
	local ca, sa = cos(a), sin(a)
	local period = 900 * s.rbSize
	local off = now * s.rbSpeed * 0.25
	local function u(x, y) return (x * ca + y * sa) / period + off end
	-- corners: UL, LL, UR, LR (y measured downward)
	L.rainbow:SetTexCoord(u(0, 0), 0.5, u(0, H), 0.5, u(W, 0), 0.5, u(W, H), 0.5)
end

---------------------------------------------------------------------------
-- apply
---------------------------------------------------------------------------
function Filter:Apply(s, enabled, coverUI)
	self.s = s
	for _, t in pairs(L) do t:Hide() end
	if not enabled then
		root:Hide()
		root:SetScript("OnUpdate", nil)
		return
	end
	if coverUI then
		root:SetFrameStrata("FULLSCREEN"); root:SetFrameLevel(5003)
	else
		root:SetFrameStrata("BACKGROUND"); root:SetFrameLevel(3)
	end

	if s.filter then
		local mr, mg, mb, ar, ag, ab = self:Grade(s)
		L.mul:SetBlendMode("MOD"); L.mul:SetColorTexture(mr, mg, mb, 1); L.mul:Show()
		L.add:SetBlendMode("ADD"); L.add:SetColorTexture(ar, ag, ab, 1); L.add:Show()
		if s.fVig > 0 then
			L.vig:SetTexture(TEX .. "vignette_hd")
			L.vig:SetBlendMode("BLEND")
			L.vig:SetAlpha(s.fVig * s.fAmount)
			L.vig:Show()
		end
	end
	if s.tripWobble then
		L.wobMul:SetBlendMode("MOD"); L.wobMul:SetColorTexture(1, 1, 1, 1); L.wobMul:Show()
		L.wobAdd:SetBlendMode("ADD"); L.wobAdd:SetColorTexture(0, 0, 0, 1); L.wobAdd:Show()
	end
	if s.tripRainbow then
		local lvl = clamp(floor(s.rbStrength * 10 + 0.5), 1, 10)
		L.rainbow:SetTexture(TEX .. "rainbow_" .. lvl, "REPEAT", "REPEAT")
		L.rainbow:SetBlendMode("MOD")
		L.rainbow:Show()
		self:PlaceRainbow(s, GetTime())
	end
	if s.tripStrobe then
		L.strobe:SetBlendMode("ADD"); L.strobe:SetColorTexture(0, 0, 0, 1); L.strobe:Show()
	end
	lastRemapType = nil

	root:Show()
	local animated = s.tripWobble or s.tripRainbow or s.tripStrobe or s.tripRemap or s.tripGamma or s.tripSway or s.tripFov
	root:SetScript("OnUpdate", animated and onUpdate or nil)
	if animated then onUpdate(root, 0.05) end
end
