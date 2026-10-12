-- RetroVision: "pretty" effects - color gradients, glows, light leaks, sun rays,
-- aurora, caustics, holographic shimmer, bokeh and two ambient particle layers.
-- Drawn just under the retro filters, so scanlines etc. still sit on top.
local ADDON, ns = ...

local Pretty = {}
ns.Pretty = Pretty

local TEX = "Interface\\AddOns\\" .. ADDON .. "\\Textures\\"
local TAU = math.pi * 2
local random, sin, cos, floor, min, max = math.random, math.sin, math.cos, math.floor, math.min, math.max

local root = CreateFrame("Frame", "RetroVisionPretty", WorldFrame)
root:SetAllPoints(WorldFrame)
root:EnableMouse(false)
root:Hide()
Pretty.root = root

local function tex(layer, sub)
	local t = root:CreateTexture(nil, layer, nil, sub)
	if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
	if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
	t:Hide()
	return t
end

local function full(layer, sub)
	local t = tex(layer, sub)
	t:SetAllPoints(root)
	return t
end

local L = {
	hue      = full("BACKGROUND", -8),
	grad     = full("BACKGROUND", -7),
	caustA   = full("BACKGROUND", 0),
	caustB   = full("BACKGROUND", 1),
	holo     = full("BORDER", 0),
	bokeh    = full("BORDER", 2),
	haze     = full("OVERLAY", -8),
	pulse    = full("OVERLAY", -7),
	aura     = full("OVERLAY", -6),
}
local aurora = { tex("BORDER", 4), tex("BORDER", 5) }
local leaks = { tex("OVERLAY", -4), tex("OVERLAY", -4), tex("OVERLAY", -4) }
local rays = tex("OVERLAY", -2)   -- fallback for clients without line regions
local beams = {}
local canLine = root.CreateLine ~= nil
local function getBeam(i)
	local b = beams[i]
	if not b then
		b = { l = root:CreateLine(nil, "OVERLAY", nil, -2) }
		if b.l.SetSnapToPixelGrid then pcall(b.l.SetSnapToPixelGrid, b.l, false) end
		if b.l.SetTexelSnappingBias then pcall(b.l.SetTexelSnappingBias, b.l, 0) end
		b.l:SetTexture(TEX .. "beam")
		b.l:SetBlendMode("ADD")
		beams[i] = b
	end
	return b
end

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function hsv(h, s, v)
	h = (h % 1) * 6
	local i = floor(h)
	local f = h - i
	local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
	if i == 0 then return v, t, p elseif i == 1 then return q, v, p elseif i == 2 then return p, v, t
	elseif i == 3 then return p, q, v elseif i == 4 then return t, p, v else return v, p, q end
end
Pretty.hsv = hsv

local function setGradient(t, r1, g1, b1, a1, r2, g2, b2, a2) -- 1 = bottom, 2 = top
	t:SetColorTexture(1, 1, 1, 1)
	if CreateColor and t.SetGradient then
		local ok = pcall(t.SetGradient, t, "VERTICAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
		if ok then return end
	end
	if t.SetGradientAlpha then
		t:SetGradientAlpha("VERTICAL", r1, g1, b1, a1, r2, g2, b2, a2)
	else
		t:SetColorTexture((r1 + r2) / 2, (g1 + g2) / 2, (b1 + b2) / 2, (a1 + a2) / 2)
	end
end

local function tile(t, file, tw, th, mult, ou, ov)
	local pw, ph = ns.Overlay:ScreenPixels()
	ou, ov = ou or 0, ov or 0
	t:SetTexCoord(ou, ou + pw / (tw * mult), ov, ov + ph / (th * mult))
end

---------------------------------------------------------------------------
-- particles
---------------------------------------------------------------------------
-- size in UI units (the screen is 768 units tall at UI scale 1)
Pretty.TYPES = {
	{ key = "fireflies", name = "Fireflies", tex = "p_glow", blend = "ADD", color = { 1, 0.88, 0.35 }, size = { 7, 15 }, motion = "wander", speed = 22, twinkle = 1.6 },
	{ key = "snow", name = "Snow", tex = "p_dot", blend = "BLEND", color = { 1, 1, 1 }, size = { 2.5, 7 }, motion = "fall", speed = 42, sway = 16 },
	{ key = "embers", name = "Embers", tex = "p_glow", blend = "ADD", color = { 1, 0.42, 0.1 }, size = { 4, 10 }, motion = "rise", speed = 60, sway = 18, twinkle = 4 },
	{ key = "dust", name = "Dust motes", tex = "p_glow", blend = "ADD", color = { 1, 0.95, 0.85 }, size = { 3, 8 }, motion = "drift", speed = 7, alpha = 0.5 },
	{ key = "rain", name = "Rain", tex = "p_streak", blend = "BLEND", color = { 0.75, 0.85, 1 }, size = { 1.2, 2 }, stretch = 16, motion = "rain", speed = 750, alpha = 0.55 },
	{ key = "petals", name = "Cherry petals", tex = "p_petal", blend = "BLEND", color = { 1, 0.74, 0.84 }, size = { 7, 12 }, motion = "flutter", speed = 38, sway = 40, spin = 2 },
	{ key = "leaves", name = "Autumn leaves", tex = "p_leaf", blend = "BLEND", color = { 0.95, 0.5, 0.18 }, size = { 10, 17 }, motion = "flutter", speed = 55, sway = 55, spin = 2.5, vary = true },
	{ key = "stars", name = "Twinkling stars", tex = "p_star", blend = "ADD", color = { 0.85, 0.9, 1 }, size = { 5, 14 }, motion = "still", twinkle = 1.2 },
	{ key = "sparkles", name = "Sparkles", tex = "p_star", blend = "ADD", color = { 1, 0.95, 0.7 }, size = { 7, 18 }, motion = "pop", life = 1.3 },
	{ key = "bubbles", name = "Bubbles", tex = "p_ring", blend = "ADD", color = { 0.7, 0.9, 1 }, size = { 6, 18 }, motion = "rise", speed = 40, sway = 12 },
	{ key = "arcane", name = "Arcane motes", tex = "p_glow", blend = "ADD", color = { 0.7, 0.5, 1 }, size = { 5, 12 }, motion = "rise", speed = 18, sway = 25, twinkle = 2.2, rainbow = true },
	{ key = "ash", name = "Falling ash", tex = "p_dot", blend = "BLEND", color = { 0.35, 0.33, 0.32 }, size = { 2, 5 }, motion = "fall", speed = 20, sway = 30 },
}
local TYPE = {}
for _, t in ipairs(Pretty.TYPES) do TYPE[t.key] = t end

-- particle sprites ship at several sizes; use the smallest one that is at least as
-- big as the particle on screen (addon textures have no mipmaps, so shrinking a
-- large image a lot makes it jagged and shimmery)
local SPRITE_SIZES = { 16, 32, 64, 128, 256 }
local STREAK_SIZES = { 32, 64, 128, 256 }
local function spriteFor(base, pixels, list)
	for _, n in ipairs(list) do
		if n >= pixels then return TEX .. base .. "_" .. n end
	end
	return TEX .. base .. "_" .. list[#list]
end

local Layer = {}
Layer.__index = Layer

local function newLayer(prefix, sub)
	return setmetatable({ prefix = prefix, sub = sub, p = {} }, Layer)
end

function Layer:Spawn(q, W, H, anywhere)
	local T = self.T
	q.x = random() * W
	q.y = anywhere and random() * H or (T.motion == "rise" and -20 or H + 20)
	if T.motion == "still" or T.motion == "pop" or T.motion == "wander" or T.motion == "drift" then q.y = random() * H end
	q.size = T.size[1] + random() * (T.size[2] - T.size[1])
	q.ph = random() * TAU
	q.sp = 0.6 + random() * 0.8
	q.vx, q.vy = (random() - 0.5) * 2, (random() - 0.5) * 2
	q.rot = random() * TAU
	q.spin = (random() - 0.5) * 2 * (T.spin or 0)
	q.life = random()
	local c = self.color
	if T.rainbow then
		c = { hsv(random(), 0.6, 1) }
	elseif T.vary then
		local k = 0.75 + random() * 0.5
		c = { min(1, c[1] * k), min(1, c[2] * (0.6 + random() * 0.8)), c[3] * k }
	end
	q.r, q.g, q.b = c[1], c[2], c[3]
	local t = q.t
	local s = q.size * self.size
	if q.isLine then
		t:SetTexture(TEX .. "p_line")
		t:SetBlendMode(T.blend)
		t:SetThickness(s)
		q.len = s * (T.stretch or 1)
		t:SetVertexColor(q.r, q.g, q.b)
		return
	end
	t:SetSize(s, s * (T.stretch or 1))
	local px = s * (T.stretch or 1) / ns.Overlay:PixelSize()
	t:SetTexture(spriteFor(T.tex, px, T.stretch and STREAK_SIZES or SPRITE_SIZES))
	t:SetBlendMode(T.blend)
	t:SetVertexColor(q.r, q.g, q.b)
end

function Layer:Apply(s, W, H)
	local P = self.prefix
	local on = s[P .. "on"]
	local T = TYPE[s[P .. "type"]] or Pretty.TYPES[1]
	local count = on and floor(s[P .. "count"] + 0.5) or 0
	local newColor = { s[P .. "R"], s[P .. "G"], s[P .. "B"] }
	local reset = self.T ~= T or self.size ~= s[P .. "size"]
	local recolor = not reset and self.color
		and (self.color[1] ~= newColor[1] or self.color[2] ~= newColor[2] or self.color[3] ~= newColor[3])
	self.T, self.on, self.count = T, on, count
	self.size, self.speed, self.alpha, self.wind = s[P .. "size"], s[P .. "speed"], s[P .. "alpha"], s[P .. "wind"]
	self.twinkle = s[P .. "twinkle"]
	local oldColor = self.color
	self.color = newColor
	for i = 1, max(count, #self.p) do
		local q = self.p[i]
		if i <= count then
			if not q then
				q = {}
				self.p[i] = q
				q.fresh = true
			end
			if q.fresh or reset then
				-- rain is drawn with line regions (crisp at any angle); everything else is a sprite
				local useLine = T.motion == "rain" and root.CreateLine ~= nil
				if useLine and not q.line then
					q.line = root:CreateLine(nil, "ARTWORK", nil, self.sub)
					if q.line.SetSnapToPixelGrid then pcall(q.line.SetSnapToPixelGrid, q.line, false) end
					if q.line.SetTexelSnappingBias then pcall(q.line.SetTexelSnappingBias, q.line, 0) end
				elseif not useLine and not q.tex then
					q.tex = root:CreateTexture(nil, "ARTWORK", nil, self.sub)
					-- let particles glide between pixels instead of snapping
					if q.tex.SetSnapToPixelGrid then q.tex:SetSnapToPixelGrid(false) end
					if q.tex.SetTexelSnappingBias then q.tex:SetTexelSnappingBias(0) end
				end
				if q.t then q.t:Hide() end
				q.t = useLine and q.line or q.tex
				q.isLine = useLine
				self:Spawn(q, W, H, true)
				q.fresh = false
			elseif recolor and not T.rainbow then
				local k = T.vary and (q.g / math.max(0.01, oldColor[2])) or 1
				q.r, q.g, q.b = newColor[1], math.min(1, newColor[2] * (T.vary and k or 1)), newColor[3]
				q.t:SetVertexColor(q.r, q.g, q.b)
			end
			q.t:Show()
		elseif q then
			q.t:Hide()
		end
	end
end

function Layer:Update(dt, now, W, H)
	if not self.on or self.count == 0 then return end
	local T = self.T
	local spd = self.speed
	local wind = self.wind * 120
	local baseA = self.alpha * (T.alpha or 1)
	local m = T.motion
	for i = 1, self.count do
		local q = self.p[i]
		local a = baseA
		if m == "fall" then
			q.y = q.y - T.speed * spd * q.sp * dt
			q.x = q.x + (wind + cos(now * 1.3 * q.sp + q.ph) * T.sway) * dt
		elseif m == "rise" then
			q.y = q.y + T.speed * spd * q.sp * dt
			q.x = q.x + (wind + sin(now * 1.7 * q.sp + q.ph) * T.sway) * dt
		elseif m == "flutter" then
			q.y = q.y - T.speed * spd * q.sp * dt
			q.x = q.x + (wind + sin(now * 1.1 * q.sp + q.ph) * T.sway) * dt
			q.rot = q.rot + q.spin * dt * spd
			q.t:SetRotation(q.rot)
		elseif m == "rain" then
			local vy = T.speed * spd * q.sp
			local vx = wind * 3
			q.y = q.y - vy * dt
			q.x = q.x + vx * dt
			if q.isLine then
				local v = math.sqrt(vx * vx + vy * vy)
				q.lx, q.ly = vx / v * q.len, -vy / v * q.len
			else
				q.t:SetRotation(math.atan2(vx, vy))
			end
		elseif m == "wander" or m == "drift" then
			local k = (m == "wander") and 1.6 or 0.6
			q.vx = q.vx + (random() - 0.5) * k * dt * 4
			q.vy = q.vy + (random() - 0.5) * k * dt * 4
			local len = math.sqrt(q.vx * q.vx + q.vy * q.vy)
			if len > 1 then q.vx, q.vy = q.vx / len, q.vy / len end
			q.x = q.x + (q.vx * T.speed * spd + wind * 0.3) * dt
			q.y = q.y + q.vy * T.speed * spd * dt
		elseif m == "pop" then
			q.life = q.life + dt * spd / T.life
			if q.life >= 1 then
				q.life = 0
				q.x, q.y = random() * W, random() * H
			end
			a = a * sin(math.pi * q.life)
			q.rot = q.rot + dt
			q.t:SetRotation(q.rot)
		end
		if T.twinkle and self.twinkle then
			a = a * (0.45 + 0.55 * (0.5 + 0.5 * sin(now * T.twinkle * TAU * 0.5 * q.sp + q.ph)))
		end
		-- wrap around the screen edges
		local pad = 30
		if q.y < -pad then q.y = H + pad; q.x = random() * W
		elseif q.y > H + pad then q.y = -pad; q.x = random() * W end
		if q.x < -pad then q.x = W + pad elseif q.x > W + pad then q.x = -pad end
		if q.isLine then
			q.t:SetStartPoint("BOTTOMLEFT", root, q.x - (q.lx or 0), q.y - (q.ly or 0))
			q.t:SetEndPoint("BOTTOMLEFT", root, q.x, q.y)
		else
			q.t:ClearAllPoints()
			q.t:SetPoint("CENTER", root, "BOTTOMLEFT", q.x, q.y)
		end
		q.t:SetAlpha(a)
	end
end

local layers = { newLayer("p1", 0), newLayer("p2", 2) }
Pretty.layers = layers

---------------------------------------------------------------------------
-- animation
---------------------------------------------------------------------------
local RAYPOS = { topleft = { 0.04, 1.06 }, top = { 0.5, 1.1 }, topright = { 0.96, 1.06 } }
-- fan of beam directions (degrees, 0 = right, -90 = straight down)
local RAYFAN = { topleft = { -8, -82 }, top = { -35, -145 }, topright = { -98, -172 } }

local function placeBeams(s, now, W, H)
	local pos = RAYPOS[s.raysPos] or RAYPOS.topleft
	local sx, sy = W * pos[1], H * pos[2]
	local diag = math.sqrt(W * W + H * H)
	local sp = s.raysSpeed
	for i = 1, Pretty.beamCount do
		local b = beams[i]
		local ang = b.base + sin(now * sp * 0.35 * (0.6 + b.k) + b.ph) * 0.045
		local L = diag * s.raysLength * (0.75 + 0.45 * b.k)
		local ex, ey = sx + cos(ang) * L, sy + sin(ang) * L
		b.l:SetStartPoint("BOTTOMLEFT", root, sx, sy)
		b.l:SetEndPoint("BOTTOMLEFT", root, ex, ey)
		b.l:SetThickness(L * 0.2 * s.raysWidth * (0.55 + 0.9 * b.w))
		local f = s.raysAlpha * b.a * (0.7 + 0.3 * sin(now * sp * 0.9 + b.ph * 3))
		b.l:SetVertexColor(s.raysR * f, s.raysG * f, s.raysB * f)
	end
end

local function onUpdate(self, dt)
	local s = Pretty.s
	local now = GetTime()
	local W, H = root:GetWidth(), root:GetHeight()
	if not W or W <= 0 then return end

	if s.hue then
		local r, g, b = hsv(now * s.hueSpeed * 0.1, 1, 1)
		local k = s.hueStrength
		L.hue:SetColorTexture(1 - (1 - r) * k, 1 - (1 - g) * k, 1 - (1 - b) * k, 1)
	end
	if s.aura and s.auraPulse > 0 then
		local f = (0.6 + 0.4 * sin(now * s.auraPulse * TAU)) * s.auraAlpha
		L.aura:SetVertexColor(s.auraR * f, s.auraG * f, s.auraB * f)
	end
	if s.pulse then
		local f = s.pulseAlpha * (0.5 + 0.5 * sin(now * s.pulseSpeed * TAU))
		L.pulse:SetColorTexture(s.pulseR * f, s.pulseG * f, s.pulseB * f, 1)
	end
	if s.holo then
		local o = now * s.holoSpeed * 0.05
		tile(L.holo, "holo", 256, 256, s.holoScale, o, o * 0.3)
	end
	if s.caustics then
		local o = now * s.causSpeed * 0.02
		tile(L.caustA, "caustics", 1024, 1024, s.causScale / 4, o, o * 0.6)
		tile(L.caustB, "caustics", 1024, 1024, s.causScale * 1.3 / 4, -o * 0.7 + 0.37, o * 0.9 + 0.11)
	end
	if s.bokeh then
		local o = now * s.bokehSpeed * 0.01
		tile(L.bokeh, "bokeh", 1024, 1024, 1, o, o * 0.4)
	end
	if s.aurora then
		local o = now * s.auroraSpeed * 0.02
		aurora[1]:SetTexCoord(o, o + 1.4, 0, 1)
		aurora[2]:SetTexCoord(-o * 0.6 + 0.5, -o * 0.6 + 2.2, 0, 1)
		local b1 = s.auroraAlpha * (0.75 + 0.25 * sin(now * 0.4))
		local b2 = s.auroraAlpha * 0.6 * (0.7 + 0.3 * sin(now * 0.31 + 2))
		aurora[1]:SetVertexColor(b1, b1, b1)
		aurora[2]:SetVertexColor(b2, b2, b2)
	end
	if s.leaks then
		local sp = s.leaksSpeed
		for i, t in ipairs(leaks) do
			local x = W * (0.5 + 0.62 * sin(now * sp * 0.13 * (0.8 + i * 0.25) + i * 2.1))
			local y = H * (0.5 + 0.62 * cos(now * sp * 0.11 * (0.7 + i * 0.3) + i * 1.3))
			t:ClearAllPoints()
			t:SetPoint("CENTER", root, "BOTTOMLEFT", x, y)
			local f = s.leaksAlpha * (0.7 + 0.3 * sin(now * sp * 0.5 + i))
			local hueShift = (i - 2) * 0.08
			t:SetVertexColor(min(1, s.leaksR + hueShift) * f, s.leaksG * f, max(0, s.leaksB - hueShift) * f)
		end
	end
	if s.rays and canLine then
		placeBeams(s, now, W, H)
	elseif s.rays then
		rays:SetRotation(sin(now * s.raysSpeed * 0.25) * 0.14 + now * s.raysSpeed * 0.01)
		local f = s.raysAlpha * (0.85 + 0.15 * sin(now * 1.3))
		rays:SetVertexColor(s.raysR * f, s.raysG * f, s.raysB * f)
	end
	for _, l in ipairs(layers) do l:Update(dt, now, W, H) end
end

---------------------------------------------------------------------------
-- apply
---------------------------------------------------------------------------
function Pretty:Apply(s, enabled, coverUI)
	self.s = s
	if not enabled then
		root:Hide()
		root:SetScript("OnUpdate", nil)
		return
	end
	if coverUI then
		root:SetFrameStrata("FULLSCREEN"); root:SetFrameLevel(5000)
	else
		root:SetFrameStrata("BACKGROUND"); root:SetFrameLevel(1)
	end
	local W, H = root:GetWidth(), root:GetHeight()
	if not W or W <= 0 then W, H = 1366, 768 end

	for _, t in pairs(L) do t:Hide() end
	for _, t in ipairs(aurora) do t:Hide() end
	for _, t in ipairs(leaks) do t:Hide() end
	rays:Hide()
	for _, b in ipairs(beams) do b.l:Hide() end

	if s.grad then
		local k = s.gradStrength
		local t = L.grad
		if s.gradMode == "add" then
			t:SetBlendMode("ADD")
			setGradient(t, s.gradBotR * k, s.gradBotG * k, s.gradBotB * k, 1, s.gradTopR * k, s.gradTopG * k, s.gradTopB * k, 1)
		elseif s.gradMode == "paint" then
			t:SetBlendMode("BLEND")
			setGradient(t, s.gradBotR, s.gradBotG, s.gradBotB, k, s.gradTopR, s.gradTopG, s.gradTopB, k)
		else
			t:SetBlendMode("MOD")
			setGradient(t, 1 - (1 - s.gradBotR) * k, 1 - (1 - s.gradBotG) * k, 1 - (1 - s.gradBotB) * k, 1,
				1 - (1 - s.gradTopR) * k, 1 - (1 - s.gradTopG) * k, 1 - (1 - s.gradTopB) * k, 1)
		end
		t:Show()
	end
	if s.hue then
		L.hue:SetBlendMode("MOD"); L.hue:SetColorTexture(1, 1, 1, 1); L.hue:Show()
	end
	if s.haze then
		local a = s.hazeAlpha
		L.haze:SetColorTexture(s.hazeR * a, s.hazeG * a, s.hazeB * a, 1)
		L.haze:SetBlendMode("ADD"); L.haze:Show()
	end
	if s.pulse then
		L.pulse:SetColorTexture(0, 0, 0, 1); L.pulse:SetBlendMode("ADD"); L.pulse:Show()
	end
	if s.aura then
		L.aura:SetTexture(TEX .. "edgeglow")
		L.aura:SetBlendMode("ADD")
		local a = s.auraAlpha
		L.aura:SetVertexColor(s.auraR * a, s.auraG * a, s.auraB * a)
		L.aura:Show()
	end
	if s.holo then
		L.holo:SetTexture(TEX .. "holo", "REPEAT", "REPEAT")
		L.holo:SetBlendMode("ADD")
		L.holo:SetVertexColor(s.holoAlpha, s.holoAlpha, s.holoAlpha)
		tile(L.holo, "holo", 256, 256, s.holoScale)
		L.holo:Show()
	end
	if s.caustics then
		for _, t in ipairs({ L.caustA, L.caustB }) do
			t:SetTexture(TEX .. "caustics_hd", "REPEAT", "REPEAT")
			t:SetBlendMode("ADD")
			local a = s.causAlpha * 0.7
			t:SetVertexColor(s.causR * a, s.causG * a, s.causB * a)
			tile(t, "caustics", 1024, 1024, s.causScale / 4)
			t:Show()
		end
	end
	if s.bokeh then
		L.bokeh:SetTexture(TEX .. "bokeh_hd", "REPEAT", "REPEAT")
		L.bokeh:SetBlendMode("ADD")
		local a = s.bokehAlpha
		L.bokeh:SetVertexColor(s.bokehR * a, s.bokehG * a, s.bokehB * a)
		tile(L.bokeh, "bokeh", 1024, 1024, 1)
		L.bokeh:Show()
	end
	if s.aurora then
		for i, t in ipairs(aurora) do
			t:SetTexture(TEX .. "aurora_hd", "REPEAT", "CLAMP")
			t:SetBlendMode("ADD")
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", root, "TOPLEFT", 0, i == 2 and -H * 0.03 or 0)
			t:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, i == 2 and -H * 0.03 or 0)
			t:SetHeight(H * s.auroraHeight * (i == 2 and 0.8 or 1))
			t:Show()
		end
	end
	if s.leaks then
		for _, t in ipairs(leaks) do
			t:SetTexture(TEX .. "p_glow_256")
			t:SetBlendMode("ADD")
			t:SetSize(H * 1.3, H * 1.1)
			t:Show()
		end
	end
	if s.rays and canLine then
		local n = math.floor(s.raysCount + 0.5)
		local fan = RAYFAN[s.raysPos] or RAYFAN.topleft
		local seedChanged = Pretty.beamPos ~= s.raysPos or Pretty.beamCount ~= n
		Pretty.beamCount, Pretty.beamPos = n, s.raysPos
		for i = 1, n do
			local b = getBeam(i)
			if seedChanged or not b.base then
				local step = (fan[2] - fan[1]) / n
				b.base = math.rad(fan[1] + step * (i - 0.5) + (random() - 0.5) * step * 0.8)
				b.k, b.w, b.a, b.ph = random(), random(), 0.45 + random() * 0.55, random() * TAU
			end
			b.l:Show()
		end
		placeBeams(s, GetTime(), W, H)
	elseif s.rays then
		local pos = RAYPOS[s.raysPos] or RAYPOS.topleft
		local size = max(W, H) * 2.1
		rays:SetTexture(TEX .. "rays_hd")
		rays:SetBlendMode("ADD")
		rays:SetSize(size, size)
		rays:ClearAllPoints()
		rays:SetPoint("CENTER", root, "BOTTOMLEFT", W * pos[1], H * pos[2])
		rays:Show()
	end

	for _, l in ipairs(layers) do l:Apply(s, W, H) end

	root:Show()
	local animated = s.hue or (s.aura and s.auraPulse > 0) or s.pulse or s.holo or s.caustics or s.bokeh
		or s.aurora or s.leaks or s.rays or s.p1on or s.p2on
	root:SetScript("OnUpdate", animated and onUpdate or nil)
	if animated then onUpdate(root, 0) end
end
