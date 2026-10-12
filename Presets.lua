-- RetroVision: default settings and built-in presets
local ADDON, ns = ...

-- Every setting, in its "does nothing" state. Presets only list what they change.
ns.NEUTRAL = {
	-- screen
	scanlines = false, scanLines = 240, scanHard = 3, scanAlpha = 0.45, interlace = false,
	crtBoost = true, crtBoostAmt = 0.35, glare = false, glareAlpha = 0.06,
	rollBar = false, rollAlpha = 0.05, rollSpeed = 0.08,
	lcdGrid = false, lcdAlpha = 0.4, lcdCell = 0, ditherType = "bayer4",
	grainChroma = false, filmDamage = 0,
	vhsHead = false, vhsSnow = 0, vhsDrop = 0, vhsOSD = false,
	mask = "none", maskStrength = 0.5, maskScale = 1,
	vignette = false, vignetteAlpha = 0.5,
	corners = false, cornerRadius = 32,
	dither = false, ditherAlpha = 0.2, ditherScale = 2,
	letterbox = 0, -- 0 = off, otherwise the picture's width / height
	-- color
	tint = false, tintR = 1, tintG = 1, tintB = 1, tintStrength = 0.5,
	lift = false, liftR = 0.05, liftG = 0.05, liftB = 0.05, liftAlpha = 1,
	dim = 0,
	-- motion
	grain = false, grainAlpha = 0.15, grainSize = 1, grainFPS = 24,
	vhs = false, vhsAlpha = 0.35, vhsSpeed = 0.5,
	flicker = false, flickerAmount = 0.05,
	-- game render settings. "Leave alone" values: rPixel 1, rFPS 0, rView 0, -1 for the
	-- quality levels, "keep"/false for the rest, so the player's own setting is untouched
	rPixel = 1, rPoint = false, rTexFilter = -1, rGlow = "keep",
	rFPS = 0, rView = 0, rShadow = -1, rSSAO = -1, rAAOff = false,
	rGammaOn = false, rGamma = 1.0,
	rContrastOn = false, rContrast = 50,
	rBrightOn = false, rBright = 50,

	-- pretty: lighting
	grad = false, gradMode = "mod", gradStrength = 0.5,
	gradTopR = 1, gradTopG = 0.8, gradTopB = 0.55, gradBotR = 0.55, gradBotG = 0.75, gradBotB = 1,
	aura = false, auraR = 0.6, auraG = 0.4, auraB = 1, auraAlpha = 0.35, auraPulse = 0,
	leaks = false, leaksR = 1, leaksG = 0.5, leaksB = 0.22, leaksAlpha = 0.3, leaksSpeed = 0.4,
	rays = false, raysR = 1, raysG = 0.9, raysB = 0.7, raysAlpha = 0.3, raysSpeed = 0.3, raysPos = "topleft",
	haze = false, hazeR = 1, hazeG = 0.95, hazeB = 0.9, hazeAlpha = 0.06,
	-- pretty: magic
	hue = false, hueStrength = 0.2, hueSpeed = 0.3,
	holo = false, holoAlpha = 0.1, holoSpeed = 0.4, holoScale = 3,
	caustics = false, causR = 0.55, causG = 0.85, causB = 1, causAlpha = 0.25, causSpeed = 0.5, causScale = 3,
	aurora = false, auroraAlpha = 0.5, auroraSpeed = 0.4, auroraHeight = 0.4,
	pulse = false, pulseR = 1, pulseG = 0.4, pulseB = 0.8, pulseAlpha = 0.08, pulseSpeed = 0.3,
	bokeh = false, bokehR = 1, bokehG = 0.9, bokehB = 0.75, bokehAlpha = 0.15, bokehSpeed = 0.4,
	-- pretty: particles (two layers)
	p1on = false, p1type = "fireflies", p1count = 60, p1size = 1, p1speed = 1, p1alpha = 0.8, p1wind = 0, p1twinkle = true,
	p1R = 1, p1G = 0.88, p1B = 0.35,
	p2on = false, p2type = "dust", p2count = 40, p2size = 1, p2speed = 1, p2alpha = 0.6, p2wind = 0, p2twinkle = true,
	p2R = 1, p2G = 0.95, p2B = 0.85,
	-- high-end graphics and camera (-1 / below range = leave alone)
	qSunshafts = -1, qParticles = -1, qClutter = -1, qEnv = -1, qLiquid = -1, qDepth = -1,
	qOutline = -1, qSpell = -1, qProjected = -1, qWeather = -1,
	cZoom = 0.9, cFov = 49, cAction = false, cShoulder = 0.6, cPitch = true, cBob = 0,
	raysCount = 9, raysWidth = 1, raysLength = 1,
	-- stylized looks
	ink = false, inkThick = 0.5, inkR = 0.04, inkG = 0.03, inkB = 0.05,
	halftone = false, htR = 0.1, htG = 0.05, htB = 0.15, htAlpha = 0.25, htScale = 1, htEdges = true,
	hatch = false, hatchR = 0.1, hatchG = 0.07, hatchB = 0.05, hatchAlpha = 0.25, hatchScale = 1, hatchEdges = true,
	speed = false, speedR = 1, speedG = 1, speedB = 1, speedCount = 40, speedAlpha = 0.35, speedLen = 0.45, speedFPS = 12,
	splat = false, splatAR = 0.65, splatAG = 1, splatAB = 0.1, splatBR = 1, splatBG = 0.15, splatBB = 0.75, splatSize = 0.42, splatAlpha = 0.9,
	fringe = false, fringeAlpha = 0.3, fringeWidth = 0.12, fringeLR = 1, fringeLG = 0.1, fringeLB = 0.6, fringeRR = 0.1, fringeRG = 0.9, fringeRB = 1,
	paper = false, paperAlpha = 0.25, paperScale = 1, paperR = 0.35, paperG = 0.22, paperB = 0.1,
	colorFilter = -1, colorFilterStrength = 0.6,
	-- color filter (Instagram-style grade)
	filter = false, fLook = "custom", fAmount = 1, fWarm = 0, fTint = 0, fFade = 0, fContrast = 0, fBright = 0, fAuto = true,
	fHiR = 1, fHiG = 1, fHiB = 1, fHi = 0, fShR = 0, fShG = 0, fShB = 0, fSh = 0, fVig = 0,
	-- trippy
	tripWobble = false, wobDepth = 0.5, wobSpeed = 0.3, wobGlow = 0.4,
	tripRainbow = false, rbStrength = 0.4, rbSpeed = 0.3, rbSize = 1, rbAngle = 30,
	tripStrobe = false, strobeBPM = 120, strobeAlpha = 0.2,
	tripRemap = false, remapSpeed = 0.15,
	tripGamma = false, gPulse = 0.25, gSpeed = 0.2,
	tripSway = false, swayAmt = 0.8, swaySpeed = 0.12,
	tripFov = false, fovAmt = 10, fovSpeed = 0.15,
	presetStrength = 1,
}

-- Preset strength: which settings carry the "intensity" of a look.
-- mode "x": scale from zero; mode "c": scale the distance from a center value.
-- when = only scale this key if the preset turns that feature on.
local STRENGTH = {
	{ "scanAlpha" }, { "maskStrength", max = 1, min = 0.05 }, { "vignetteAlpha" }, { "ditherAlpha" },
	{ "tintStrength" }, { "liftAlpha", when = "lift", max = 3 }, { "dim" },
	{ "grainAlpha" }, { "vhsAlpha" }, { "flickerAmount", max = 0.5 },
	{ "gradStrength" }, { "auraAlpha" }, { "leaksAlpha" }, { "raysAlpha" }, { "hazeAlpha", max = 0.5 },
	{ "hueStrength" }, { "holoAlpha", max = 0.6 }, { "causAlpha" }, { "auroraAlpha", max = 1.5 },
	{ "pulseAlpha", max = 0.5 }, { "bokehAlpha" },
	{ "p1alpha" }, { "p2alpha" }, { "p1count", max = 400, min = 1, round = true }, { "p2count", max = 400, min = 1, round = true },
	{ "htAlpha" }, { "hatchAlpha" }, { "speedAlpha" }, { "splatAlpha" }, { "fringeAlpha" }, { "paperAlpha" },
	{ "inkThick", min = 0.05 }, { "glareAlpha", max = 0.4 }, { "rollAlpha", max = 0.3 }, { "lcdAlpha" },
	{ "vhsSnow" }, { "vhsDrop" }, { "filmDamage" }, { "colorFilterStrength", min = 0.05 },
	{ "fAmount", when = "filter", max = 2 },
	{ "wobDepth" }, { "wobGlow" }, { "rbStrength", min = 0.1 }, { "strobeAlpha" }, { "gPulse", max = 0.8 },
	{ "swayAmt", max = 3 }, { "fovAmt", max = 20, min = 1 },
	{ "rContrast", center = 50, max = 100, when = "rContrastOn" }, { "rBright", center = 50, max = 100, when = "rBrightOn" },
	{ "rGamma", center = 1, min = 0.3, max = 2.8, when = "rGammaOn" },
	{ "rPixel", center = 1, min = 0.1, max = 2 },
}

-- Re-derive every intensity setting from the preset's own values times k (0..2).
function ns.ScalePreset(k)
	local RV = ns.RV
	local base = RV.db.presetBase
	if not base then return end
	local s = RV.db.settings
	for _, e in ipairs(STRENGTH) do
		local key = e[1]
		local b = base[key]
		if b == nil and e.when and base[e.when] then b = ns.NEUTRAL[key] end
		if type(b) == "number" then
			local v
			if e.center then
				v = e.center + (b - e.center) * k
			else
				v = b * k
			end
			v = math.max(e.min or 0, math.min(e.max or 1, v))
			if e.round then v = math.floor(v + 0.5) end
			s[key] = v
		end
	end
end

-- color filter looks: values applied on top of a neutral filter
local function C(r, g, b) return r, g, b end
ns.FILTERS = {
	{ key = "vivid", name = "Vivid Pop", desc = "Punchy contrast, slightly warm highlights, cool deep shadows.",
		v = { fContrast = 22, fWarm = 0.12, fSh = 0.35, fShR = 0.05, fShG = 0.15, fShB = 0.45 } },
	{ key = "golden", name = "Golden", desc = "Warm, honeyed light with a soft fade.",
		v = { fWarm = 0.55, fFade = 0.12, fHi = 0.3, fHiR = 1, fHiG = 0.9, fHiB = 0.7, fContrast = 8 } },
	{ key = "coolmatte", name = "Cool Matte", desc = "Cold, flat, faded blacks - moody.",
		v = { fWarm = -0.45, fFade = 0.38, fContrast = -12, fSh = 0.3, fShR = 0.1, fShG = 0.2, fShB = 0.35 } },
	{ key = "rose", name = "Rose Film", desc = "Pink-tinted film with plum shadows.",
		v = { fTint = 0.35, fWarm = 0.2, fFade = 0.2, fSh = 0.45, fShR = 0.5, fShG = 0.15, fShB = 0.4 } },
	{ key = "tealorange", name = "Teal & Orange", desc = "Blockbuster grade: teal shadows, orange highlights.",
		v = { fSh = 0.65, fShR = 0.0, fShG = 0.45, fShB = 0.55, fHi = 0.45, fHiR = 1, fHiG = 0.8, fHiB = 0.6, fContrast = 22 } },
	{ key = "polaroid", name = "Faded Polaroid", desc = "Washed out, warm and nostalgic.",
		v = { fFade = 0.55, fWarm = 0.3, fHi = 0.3, fHiR = 1, fHiG = 0.95, fHiB = 0.8, fSh = 0.35, fShR = 0.3, fShG = 0.4, fShB = 0.5, fContrast = -15 } },
	{ key = "lomo", name = "Lomo", desc = "Toy-camera look: heavy contrast, deep vignette, blue-ish shadows.",
		v = { fContrast = 38, fVig = 0.8, fWarm = 0.12, fTint = -0.1, fSh = 0.3, fShR = 0.1, fShG = 0.2, fShB = 0.45 } },
	{ key = "bleach", name = "Bleach Bypass", desc = "Harsh, metallic, drained of color.",
		v = { fContrast = 50, fFade = 0.15, fHi = 0.7, fHiR = 0.82, fHiG = 0.86, fHiB = 0.88, fWarm = -0.2, fBright = -5 } },
	{ key = "cross", name = "Cross Process", desc = "Film developed in the wrong chemicals: yellow-green highlights, purple shadows.",
		v = { fTint = -0.3, fHi = 0.5, fHiR = 1, fHiG = 1, fHiB = 0.55, fSh = 0.55, fShR = 0.3, fShG = 0, fShB = 0.5, fContrast = 25 } },
	{ key = "kodachrome", name = "Kodachrome", desc = "Rich, warm, saturated-feeling slide film.",
		v = { fWarm = 0.25, fContrast = 26, fHi = 0.2, fHiR = 1, fHiG = 0.92, fHiB = 0.8, fSh = 0.25, fShR = 0.15, fShG = 0.08, fShB = 0.05 } },
	{ key = "cyanotype", name = "Cyanotype", desc = "Blueprint blue monochrome.",
		v = { fHi = 0.9, fHiR = 0.5, fHiG = 0.78, fHiB = 1, fSh = 0.5, fShR = 0, fShG = 0.12, fShB = 0.35, fContrast = 18 } },
	{ key = "infrared", name = "Infrared Pink", desc = "Surreal false-color: pinks and magentas everywhere.",
		v = { fHi = 0.7, fHiR = 1, fHiG = 0.62, fHiB = 0.85, fSh = 0.45, fShR = 0.45, fShG = 0, fShB = 0.35, fTint = 0.5, fContrast = 15 } },
	{ key = "moonlight", name = "Moonlight", desc = "Deep blue night, as if lit by the moon.",
		v = { fWarm = -0.85, fBright = -10, fHi = 0.5, fHiR = 0.7, fHiG = 0.8, fHiB = 1, fFade = 0.12 } },
	{ key = "sunset", name = "Sunset Pop", desc = "Orange highlights over violet shadows.",
		v = { fHi = 0.6, fHiR = 1, fHiG = 0.65, fHiB = 0.5, fSh = 0.55, fShR = 0.45, fShG = 0.1, fShB = 0.45, fContrast = 20 } },
	{ key = "mint", name = "Mint", desc = "Fresh green-teal, light and airy.",
		v = { fTint = -0.45, fHi = 0.4, fHiR = 0.8, fHiG = 1, fHiB = 0.9, fFade = 0.22 } },
	{ key = "lavender", name = "Lavender Haze", desc = "Dreamy lilac, soft and faded.",
		v = { fHi = 0.5, fHiR = 0.9, fHiG = 0.8, fHiB = 1, fSh = 0.5, fShR = 0.3, fShG = 0.2, fShB = 0.45, fFade = 0.3 } },
	{ key = "sepia", name = "Sepia", desc = "Old brown photograph.",
		v = { fHi = 1, fHiR = 1, fHiG = 0.74, fHiB = 0.4, fSh = 0.4, fShR = 0.3, fShG = 0.17, fShB = 0.05, fFade = 0.12, fContrast = 10 } },
	{ key = "neonpop", name = "Neon Pop", desc = "Electric: magenta shadows, cyan highlights, huge contrast.",
		v = { fContrast = 45, fSh = 0.5, fShR = 0.6, fShG = 0, fShB = 0.8, fHi = 0.3, fHiR = 0.8, fHiG = 1, fHiB = 1 } },
	{ key = "toxic", name = "Toxic", desc = "Sickly radioactive green.",
		v = { fTint = -0.8, fHi = 0.6, fHiR = 0.75, fHiG = 1, fHiB = 0.45, fSh = 0.4, fShR = 0.05, fShG = 0.3, fShB = 0, fContrast = 20 } },
	{ key = "bloodmoon", name = "Blood Moon", desc = "Everything bathed in deep red.",
		v = { fHi = 0.85, fHiR = 1, fHiG = 0.35, fHiB = 0.32, fSh = 0.35, fShR = 0.35, fShG = 0, fShB = 0.02, fContrast = 25, fBright = -5 } },
}

ns.RENDER_KEYS = {
	"rPixel", "rPoint", "rTexFilter", "rGlow", "rFPS", "rView", "rShadow", "rSSAO", "rAAOff",
	"rGammaOn", "rGamma", "rContrastOn", "rContrast", "rBrightOn", "rBright",
	"qSunshafts", "qParticles", "qClutter", "qEnv", "qLiquid", "qDepth", "qOutline", "qSpell", "qProjected", "qWeather",
	"cZoom", "cFov", "cAction", "cShoulder", "cPitch", "cBob", "colorFilter", "colorFilterStrength",
	"tripRemap", "tripGamma", "tripSway", "tripFov",
}

-- Settings saved by RetroVision 1.0 used named steps; convert them to the 1.1 numbers.
local LETTERBOX = { off = 0, ["4:3"] = 4 / 3, ["10:9"] = 10 / 9, ["16:9"] = 16 / 9, ["2.39:1"] = 2.39 }
local VIEW = { keep = 0, medium = 4, short = 1 }
function ns.Migrate(s)
	if type(s) ~= "table" then return end
	-- 1.5: scanlines are set by line count + beam hardness (reference: 1440p)
	if s.scanStyle then
		local period = ({ fine = 2, medium = 4, chunky = 8 })[s.scanStyle] or 4
		s.scanLines = s.scanLines or math.floor(1440 / (period * (s.scanScale or 1)) + 0.5)
		s.scanHard = s.scanHard or ((s.scanStyle == "chunky") and 4 or 3)
		s.scanStyle, s.scanScale = nil, nil
	end
	if type(s.letterbox) == "string" then s.letterbox = LETTERBOX[s.letterbox] or 0 end
	if s.rPixel == "keep" then s.rPixel = 1 end
	if s.rTexFilter == "keep" then s.rTexFilter = -1 elseif s.rTexFilter == "bilinear" then s.rTexFilter = 0 end
	if s.rFPS == "keep" then s.rFPS = 0 end
	if type(s.rView) == "string" then s.rView = VIEW[s.rView] or 0 end
	if s.rLowSpec then s.rShadow, s.rSSAO, s.rAAOff = 0, 0, true end
	s.rLowSpec = nil
	if type(s.maskStrength) == "number" and s.maskStrength > 1 then
		s.maskStrength = math.floor(math.min(1, s.maskStrength * 0.15 / 0.8) * 20 + 0.5) / 20
	end
end

ns.PRESETS = {
	{ name = "Off", group = "", desc = "Every effect off. Any graphics settings RetroVision changed are put back.", s = {} },

	{ header = "Retro" },
	{ name = "CRT Monitor", desc = "A late-90s PC monitor: 480 Gaussian scanlines, a 3px RGB phosphor grille, glass glare, a rounded tube and brightness compensation.", s = {
		scanlines = true, scanLines = 480, scanHard = 3, scanAlpha = 0.5,
		mask = "rgb3", maskStrength = 0.45,
		glare = true, glareAlpha = 0.05,
		vignette = true, vignetteAlpha = 0.4, corners = true, cornerRadius = 28,
		lift = true, liftR = 0.03, liftG = 0.03, liftB = 0.04,
		rGlow = "on",
	} },

	{ name = "Trinitron PVM", desc = "A pro broadcast monitor: razor-sharp 480-line beams with deep gaps, crisp RGB grille, flat glass.", s = {
		scanlines = true, scanLines = 480, scanHard = 5, scanAlpha = 0.65,
		mask = "rgb3", maskStrength = 0.55, crtBoostAmt = 0.45,
		glare = true, glareAlpha = 0.03,
		vignette = true, vignetteAlpha = 0.2,
		rGlow = "on",
	} },

	{ name = "Arcade Cabinet", desc = "240p arcade tube: thick hard beams, slot mask, heavy curvature, low-res point-sampled picture in 4:3 and a faint rolling bar.", s = {
		scanlines = true, scanLines = 240, scanHard = 4, scanAlpha = 0.7,
		mask = "slot", maskStrength = 0.6, crtBoostAmt = 0.4,
		glare = true, glareAlpha = 0.07,
		rollBar = true, rollAlpha = 0.03, rollSpeed = 0.06,
		vignette = true, vignetteAlpha = 0.6, corners = true, cornerRadius = 56, letterbox = 4 / 3,
		tint = true, tintR = 1, tintG = 0.95, tintB = 0.88, tintStrength = 0.4,
		rPixel = 0.5, rPoint = true, rGlow = "on",
	} },

	{ name = "VHS Tape", desc = "Worn rental tape: washed-out warm color, soft picture, tracking band, head-switching noise, snow, dropouts and color grain.", s = {
		filter = true, fFade = 0.3, fWarm = 0.25, fContrast = -8, fSh = 0.45, fShR = 0.35, fShG = 0.1, fShB = 0.45, fHi = 0.15, fHiR = 1, fHiG = 0.92, fHiB = 0.85,
		scanlines = true, scanLines = 480, scanHard = 1, scanAlpha = 0.25,
		vhs = true, vhsAlpha = 0.45, vhsSpeed = 0.6,
		vhsHead = true, vhsSnow = 0.25, vhsDrop = 0.35,
		grain = true, grainAlpha = 0.1, grainSize = 1.5, grainFPS = 30, grainChroma = true,
		vignette = true, vignetteAlpha = 0.3,
		rPixel = 0.7,
	} },

	{ name = "Camcorder '94", desc = "Home video: PLAY and tape counter on screen, soft picture, head-switching noise, a little snow and warm faded color.", s = {
		filter = true, fFade = 0.22, fWarm = 0.3, fHi = 0.2, fHiR = 1, fHiG = 0.93, fHiB = 0.82, fContrast = 5,
		vhsOSD = true, vhsHead = true, vhsSnow = 0.12, vhsDrop = 0.15,
		vhs = true, vhsAlpha = 0.25, vhsSpeed = 0.4,
		scanlines = true, scanLines = 480, scanHard = 1, scanAlpha = 0.2,
		grain = true, grainAlpha = 0.08, grainSize = 1.5, grainFPS = 30, grainChroma = true,
		rPixel = 0.66,
	} },

	{ name = "2004 Vanilla", desc = "Modern lighting off, old full-screen glow on, older texture filtering and a warmer palette. Like a 2004 PC on medium.", s = {
		rTexFilter = 0, rGlow = "on", rShadow = 0, rSSAO = 0, rAAOff = true, rView = 4,
		tint = true, tintR = 1, tintG = 0.96, tintB = 0.88, tintStrength = 0.4,
		lift = true, liftR = 0.03, liftG = 0.03, liftB = 0.02,
		vignette = true, vignetteAlpha = 0.25,
	} },

	{ name = "Pixel Art", desc = "One-third internal resolution with crisp point upscaling and a smooth blue-noise dither.", s = {
		rPixel = 0.33, rPoint = true,
		dither = true, ditherType = "blue", ditherAlpha = 0.14, ditherScale = 3,
	} },

	{ name = "Lo-Fi 32-bit", desc = "Late-90s console: low res, 4x4 Bayer dither like the PS1, 30 FPS cap, short foggy draw distance.", s = {
		rPixel = 0.5, rPoint = true, rFPS = 30, rView = 1, rTexFilter = 0, rShadow = 0, rSSAO = 0, rAAOff = true,
		dither = true, ditherType = "bayer4", ditherAlpha = 0.25, ditherScale = 2,
		tint = true, tintR = 0.95, tintG = 0.95, tintB = 1, tintStrength = 0.3,
		vignette = true, vignetteAlpha = 0.2,
	} },

	{ name = "Pocket Green", desc = "Original handheld: green LCD with visible pixel grid, heavy dithering, 10:9 window.", s = {
		rPixel = 0.25, rPoint = true, rFPS = 30,
		tint = true, tintR = 0.55, tintG = 0.75, tintB = 0.25, tintStrength = 1,
		lift = true, liftR = 0.06, liftG = 0.11, liftB = 0.03,
		dither = true, ditherType = "bayer4", ditherAlpha = 0.3, ditherScale = 4,
		lcdGrid = true, lcdAlpha = 0.45,
		corners = true, cornerRadius = 16, vignette = true, vignetteAlpha = 0.25,
		letterbox = 10 / 9,
	} },

	{ name = "Amber Terminal", desc = "Monochrome-style amber phosphor monitor with sharp 400-line beams and glass glare.", s = {
		tint = true, tintR = 1, tintG = 0.62, tintB = 0.15, tintStrength = 0.9,
		lift = true, liftR = 0.09, liftG = 0.045, liftB = 0,
		scanlines = true, scanLines = 400, scanHard = 4, scanAlpha = 0.6,
		mask = "mg2", maskStrength = 0.25,
		glare = true, glareAlpha = 0.06,
		corners = true, cornerRadius = 36, vignette = true, vignetteAlpha = 0.55,
		flicker = true, flickerAmount = 0.03,
		rPixel = 0.5, rPoint = true, rGlow = "on",
	} },

	{ name = "Green Phosphor", desc = "Old green-screen terminal glow with sharp 400-line beams.", s = {
		tint = true, tintR = 0.25, tintG = 1, tintB = 0.35, tintStrength = 0.9,
		lift = true, liftR = 0.01, liftG = 0.08, liftB = 0.02,
		scanlines = true, scanLines = 400, scanHard = 4, scanAlpha = 0.6,
		mask = "dots", maskStrength = 0.3,
		glare = true, glareAlpha = 0.06,
		corners = true, cornerRadius = 36, vignette = true, vignetteAlpha = 0.55,
		flicker = true, flickerAmount = 0.03,
		rPixel = 0.5, rPoint = true, rGlow = "on",
	} },

	{ name = "Old Film", desc = "Sepia film reel: Gaussian grain, dust and scratches, flicker, heavy vignette, cinema bars and a 24 fps cap.", s = {
		tint = true, tintR = 1, tintG = 0.82, tintB = 0.55, tintStrength = 0.75,
		lift = true, liftR = 0.09, liftG = 0.06, liftB = 0.03,
		grain = true, grainAlpha = 0.22, grainSize = 1.2, grainFPS = 24,
		filmDamage = 0.7,
		flicker = true, flickerAmount = 0.1,
		vignette = true, vignetteAlpha = 0.8, letterbox = 2.39,
		rFPS = 24,
	} },

	{ name = "Noir", desc = "Cold, contrasty and dark. Addons can't fully desaturate the picture, so this is near-monochrome rather than true black and white.", s = {
		tint = true, tintR = 0.72, tintG = 0.78, tintB = 0.9, tintStrength = 0.65,
		dim = 0.1,
		grain = true, grainAlpha = 0.18, grainSize = 1, grainFPS = 24,
		filmDamage = 0.2,
		vignette = true, vignetteAlpha = 0.9, letterbox = 2.39,
		rContrastOn = true, rContrast = 65, rGlow = "off",
	} },

	{ name = "Dreamy Bloom", desc = "Hazy late-90s bloom with lifted pastel shadows.", s = {
		rGlow = "on",
		lift = true, liftR = 0.1, liftG = 0.06, liftB = 0.12,
		tint = true, tintR = 1, tintG = 0.9, tintB = 0.95, tintStrength = 0.25,
		vignette = true, vignetteAlpha = 0.3,
	} },

	{ header = "Pretty" },

	{ name = "Golden Hour", desc = "Warm low sun: drifting god rays, honey-toned sky fading to cool shadows, floating dust in the light.", s = {
		grad = true, gradMode = "mod", gradStrength = 0.45, gradTopR = 1, gradTopG = 0.78, gradTopB = 0.5, gradBotR = 0.8, gradBotG = 0.82, gradBotB = 1,
		rays = true, raysR = 1, raysG = 0.82, raysB = 0.55, raysAlpha = 0.32, raysSpeed = 0.25, raysPos = "topleft",
		haze = true, hazeR = 1, hazeG = 0.85, hazeB = 0.6, hazeAlpha = 0.05,
		p1on = true, p1type = "dust", p1count = 70, p1size = 1.1, p1speed = 0.8, p1alpha = 0.55, p1R = 1, p1G = 0.88, p1B = 0.6,
		vignette = true, vignetteAlpha = 0.3, rGlow = "on",
	} },

	{ name = "Enchanted Forest", desc = "Fireflies, soft green glow at the edges, dappled light and a little bloom.", s = {
		p1on = true, p1type = "fireflies", p1count = 70, p1size = 1.1, p1speed = 0.9, p1alpha = 0.9, p1R = 0.85, p1G = 1, p1B = 0.45,
		aura = true, auraR = 0.3, auraG = 0.9, auraB = 0.45, auraAlpha = 0.22, auraPulse = 0.15,
		grad = true, gradMode = "mod", gradStrength = 0.35, gradTopR = 0.85, gradTopG = 1, gradTopB = 0.8, gradBotR = 0.75, gradBotG = 0.9, gradBotB = 0.85,
		bokeh = true, bokehR = 0.8, bokehG = 1, bokehB = 0.6, bokehAlpha = 0.08, bokehSpeed = 0.3,
		rGlow = "on", vignette = true, vignetteAlpha = 0.35,
	} },

	{ name = "Winter Wonderland", desc = "Gentle snowfall, icy blue grade, bright cold haze.", s = {
		p1on = true, p1type = "snow", p1count = 160, p1size = 1, p1speed = 0.9, p1alpha = 0.85, p1wind = 0.15, p1R = 1, p1G = 1, p1B = 1,
		p2on = true, p2type = "snow", p2count = 40, p2size = 2.2, p2speed = 1.4, p2alpha = 0.5, p2wind = 0.15, p2R = 1, p2G = 1, p2B = 1,
		grad = true, gradMode = "mod", gradStrength = 0.4, gradTopR = 0.85, gradTopG = 0.93, gradTopB = 1, gradBotR = 0.92, gradBotG = 0.96, gradBotB = 1,
		haze = true, hazeR = 0.85, hazeG = 0.92, hazeB = 1, hazeAlpha = 0.07,
		aura = true, auraR = 0.8, auraG = 0.9, auraB = 1, auraAlpha = 0.18,
	} },

	{ name = "Sakura Spring", desc = "Drifting cherry petals, pink-and-peach sky, soft dreamy light.", s = {
		p1on = true, p1type = "petals", p1count = 55, p1size = 1, p1speed = 0.8, p1alpha = 0.9, p1wind = 0.25, p1R = 1, p1G = 0.74, p1B = 0.84,
		grad = true, gradMode = "mod", gradStrength = 0.35, gradTopR = 1, gradTopG = 0.82, gradTopB = 0.9, gradBotR = 1, gradBotG = 0.92, gradBotB = 0.85,
		haze = true, hazeR = 1, hazeG = 0.85, hazeB = 0.92, hazeAlpha = 0.06,
		bokeh = true, bokehR = 1, bokehG = 0.8, bokehB = 0.9, bokehAlpha = 0.1,
		rGlow = "on",
	} },

	{ name = "Autumn Breeze", desc = "Falling leaves on the wind with a warm orange grade.", s = {
		p1on = true, p1type = "leaves", p1count = 45, p1size = 1, p1speed = 0.9, p1alpha = 0.95, p1wind = 0.35, p1R = 0.95, p1G = 0.5, p1B = 0.18,
		grad = true, gradMode = "mod", gradStrength = 0.4, gradTopR = 1, gradTopG = 0.85, gradTopB = 0.65, gradBotR = 1, gradBotG = 0.88, gradBotB = 0.75,
		leaks = true, leaksR = 1, leaksG = 0.55, leaksB = 0.2, leaksAlpha = 0.18, leaksSpeed = 0.3,
		vignette = true, vignetteAlpha = 0.3,
	} },

	{ name = "Aurora Night", desc = "Northern lights rippling across the top of the screen, twinkling stars and a cold night grade.", s = {
		aurora = true, auroraAlpha = 0.6, auroraSpeed = 0.4, auroraHeight = 0.45,
		p1on = true, p1type = "stars", p1count = 70, p1size = 0.9, p1alpha = 0.8, p1R = 0.85, p1G = 0.9, p1B = 1,
		grad = true, gradMode = "mod", gradStrength = 0.45, gradTopR = 0.6, gradTopG = 0.75, gradTopB = 1, gradBotR = 0.7, gradBotG = 0.8, gradBotB = 1,
		vignette = true, vignetteAlpha = 0.5,
	} },

	{ name = "Underwater", desc = "Rippling caustic light, deep teal water color and rising bubbles.", s = {
		caustics = true, causR = 0.55, causG = 0.9, causB = 1, causAlpha = 0.3, causSpeed = 0.5, causScale = 3,
		p1on = true, p1type = "bubbles", p1count = 35, p1size = 1, p1speed = 0.8, p1alpha = 0.7, p1R = 0.7, p1G = 0.95, p1B = 1,
		grad = true, gradMode = "mod", gradStrength = 0.6, gradTopR = 0.6, gradTopG = 0.9, gradTopB = 1, gradBotR = 0.3, gradBotG = 0.55, gradBotB = 0.75,
		vignette = true, vignetteAlpha = 0.55, rView = 3,
	} },

	{ name = "Neon Nights", desc = "Synthwave city: magenta-to-cyan grade, pulsing neon edge glow, rain.", s = {
		grad = true, gradMode = "mod", gradStrength = 0.5, gradTopR = 0.75, gradTopG = 0.45, gradTopB = 1, gradBotR = 0.4, gradBotG = 0.9, gradBotB = 1,
		aura = true, auraR = 1, auraG = 0.2, auraB = 0.8, auraAlpha = 0.35, auraPulse = 0.4,
		p1on = true, p1type = "rain", p1count = 140, p1size = 1, p1speed = 1, p1alpha = 0.45, p1wind = 0.2, p1R = 0.7, p1G = 0.85, p1B = 1,
		haze = true, hazeR = 0.5, hazeG = 0.1, hazeB = 0.6, hazeAlpha = 0.05,
		rContrastOn = true, rContrast = 58, rGlow = "on",
	} },

	{ name = "Inferno", desc = "Rising embers, falling ash, a red-hot grade and a flickering heat glow at the edges.", s = {
		p1on = true, p1type = "embers", p1count = 90, p1size = 1, p1speed = 1, p1alpha = 0.9, p1R = 1, p1G = 0.42, p1B = 0.1,
		p2on = true, p2type = "ash", p2count = 60, p2size = 1, p2speed = 0.8, p2alpha = 0.7, p2R = 0.35, p2G = 0.33, p2B = 0.32,
		grad = true, gradMode = "mod", gradStrength = 0.5, gradTopR = 0.9, gradTopG = 0.6, gradTopB = 0.5, gradBotR = 1, gradBotG = 0.65, gradBotB = 0.4,
		aura = true, auraR = 1, auraG = 0.35, auraB = 0.05, auraAlpha = 0.3, auraPulse = 0.25,
	} },

	{ name = "Dreamscape", desc = "Holographic shimmer, slow color drift, floating bokeh and pastel light.", s = {
		holo = true, holoAlpha = 0.08, holoSpeed = 0.3, holoScale = 4,
		hue = true, hueStrength = 0.15, hueSpeed = 0.2,
		bokeh = true, bokehR = 1, bokehG = 0.85, bokehB = 1, bokehAlpha = 0.16, bokehSpeed = 0.5,
		haze = true, hazeR = 1, hazeG = 0.9, hazeB = 1, hazeAlpha = 0.07,
		p1on = true, p1type = "sparkles", p1count = 25, p1alpha = 0.8, p1R = 1, p1G = 0.95, p1B = 0.8,
		rGlow = "on",
	} },

	{ name = "Arcane", desc = "Rainbow arcane motes rising, violet edge glow that breathes, sparkles.", s = {
		p1on = true, p1type = "arcane", p1count = 70, p1size = 1, p1speed = 1, p1alpha = 0.9,
		p2on = true, p2type = "sparkles", p2count = 25, p2alpha = 0.8, p2R = 0.8, p2G = 0.7, p2B = 1,
		aura = true, auraR = 0.6, auraG = 0.35, auraB = 1, auraAlpha = 0.3, auraPulse = 0.3,
		grad = true, gradMode = "mod", gradStrength = 0.3, gradTopR = 0.85, gradTopG = 0.75, gradTopB = 1, gradBotR = 0.9, gradBotG = 0.85, gradBotB = 1,
	} },

	{ name = "Ultra Cinematic", desc = "Maxed-out graphics, supersampling, long view, sun shafts, wide FOV, over-the-shoulder camera and cinema bars. Heavy on the GPU.", s = {
		rPixel = 1.25, rShadow = 5, rSSAO = 4, rTexFilter = 5, rView = 10, rGlow = "on",
		qSunshafts = 2, qParticles = 5, qClutter = 10, qEnv = 10, qLiquid = 3, qDepth = 3, qProjected = 1, qWeather = 3,
		cZoom = 2.6, cFov = 85, cAction = true, cShoulder = 0.6, cPitch = true, cBob = 0,
		letterbox = 2.39, vignette = true, vignetteAlpha = 0.35,
		rays = true, raysAlpha = 0.18, raysSpeed = 0.2, raysPos = "top",
	} },

	{ header = "Stylized" },

	{ name = "Comic Multiverse", desc = "Inspired by Spider-Verse: magenta/cyan split toning, misprinted color edges, print dots and 24 fps 'on twos' motion.", s = {
		filter = true, fContrast = 26, fSh = 0.55, fShR = 0.35, fShG = 0, fShB = 0.45, fHi = 0.35, fHiR = 0.85, fHiG = 0.97, fHiB = 1,
		fringe = true, fringeAlpha = 0.4, fringeWidth = 0.16,
		halftone = true, htAlpha = 0.12, htScale = 1, htEdges = true, htR = 0.2, htG = 0.05, htB = 0.3,
		rFPS = 24,
	} },

	{ name = "Phantom Thief", desc = "Inspired by Persona 5: the world drenched in red with crushed blacks and a pulsing red edge.", s = {
		filter = true, fContrast = 38, fHi = 0.6, fHiR = 1, fHiG = 0.35, fHiB = 0.35, fSh = 0.25, fShR = 0.3, fShG = 0, fShB = 0,
		aura = true, auraR = 1, auraG = 0.05, auraB = 0.1, auraAlpha = 0.3, auraPulse = 0.5,
		speed = true, speedCount = 24, speedAlpha = 0.2, speedLen = 0.3, speedFPS = 12,
	} },

	{ name = "Celestial Brush", desc = "Inspired by Okami: warm parchment tones, faded ink-wash blacks and paper texture.", s = {
		filter = true, fWarm = 0.5, fFade = 0.28, fContrast = -8, fHi = 0.5, fHiR = 1, fHiG = 0.9, fHiB = 0.72, fSh = 0.3, fShR = 0.25, fShG = 0.15, fShB = 0.08,
		paper = true, paperAlpha = 0.35, paperScale = 1.2,
	} },

	{ name = "Pandora Ink", desc = "Inspired by Borderlands: dusty warm grade, crunchy contrast, ink shading at the edges.", s = {
		filter = true, fWarm = 0.38, fContrast = 32, fHi = 0.3, fHiR = 1, fHiG = 0.88, fHiB = 0.7, fSh = 0.3, fShR = 0.2, fShG = 0.12, fShB = 0.05,
		hatch = true, hatchAlpha = 0.28, hatchScale = 1, hatchEdges = true,
		qOutline = 2,
	} },

	{ name = "Rubber Hose '30s", desc = "Inspired by Cuphead: deep sepia, film grain, flicker and a 24 fps cap.", s = {
		filter = true, fLook = "sepia", fHi = 0.85, fHiR = 1, fHiG = 0.82, fHiB = 0.58, fSh = 0.35, fShR = 0.25, fShG = 0.15, fShB = 0.05, fFade = 0.2, fContrast = 20, fVig = 0.7,
		grain = true, grainAlpha = 0.25, grainSize = 1, grainFPS = 24,
		flicker = true, flickerAmount = 0.08,
		filmDamage = 0.8,
		rFPS = 24,
	} },

	{ name = "Neon Hotline", desc = "Inspired by Hotline Miami: hot pink and cyan everywhere, colors that won't sit still.", s = {
		filter = true, fContrast = 40, fHi = 0.55, fHiR = 1, fHiG = 0.4, fHiB = 0.9, fSh = 0.7, fShR = 0, fShG = 0.5, fShB = 0.6,
		tripWobble = true, wobDepth = 0.3, wobSpeed = 0.25, wobGlow = 0.5,
		fringe = true, fringeAlpha = 0.4, fringeWidth = 0.15,
		colorFilter = 3, colorFilterStrength = 0.5,
		scanlines = true, scanLines = 480, scanHard = 2, scanAlpha = 0.25,
	} },

	{ name = "Silhouette", desc = "Inspired by Limbo and Inside: cold, drained, crushed and foggy.", s = {
		filter = true, fHi = 0.9, fHiR = 0.74, fHiG = 0.77, fHiB = 0.82, fBright = -15, fContrast = 42, fFade = 0.06, fVig = 0.95, fAuto = false,
		grain = true, grainAlpha = 0.25, grainSize = 1, grainFPS = 24,
	} },

	{ name = "Watercolor Dream", desc = "Inspired by Gris: soft pastel wash, lifted lilac shadows and paper texture.", s = {
		filter = true, fFade = 0.45, fContrast = -25, fHi = 0.35, fHiR = 1, fHiG = 0.85, fHiB = 0.92, fSh = 0.45, fShR = 0.4, fShG = 0.35, fShB = 0.6,
		paper = true, paperAlpha = 0.28, paperScale = 1.6, paperR = 0.35, paperG = 0.28, paperB = 0.3,
	} },

	{ name = "High-Key Runner", desc = "Inspired by Mirror's Edge: bright, bleached, clean white world with cool highlights.", s = {
		filter = true, fFade = 0.3, fBright = 15, fContrast = 15, fHi = 0.4, fHiR = 0.93, fHiG = 0.97, fHiB = 1,
		aura = true, auraR = 1, auraG = 0.1, auraB = 0.1, auraAlpha = 0.1,
	} },

	{ name = "Samurai Cinema", desc = "Inspired by Ghost of Tsushima's Kurosawa mode: drained to near-monochrome, high contrast, grain and wind.", s = {
		filter = true, fHi = 0.92, fHiR = 0.82, fHiG = 0.83, fHiB = 0.86, fContrast = 42,
		grain = true, grainAlpha = 0.3, grainSize = 1, grainFPS = 24,
		vignette = true, vignetteAlpha = 0.5, letterbox = 2.39,
		p1on = true, p1type = "leaves", p1count = 40, p1size = 0.9, p1speed = 1.3, p1alpha = 0.85, p1wind = 1.2, p1R = 0.6, p1G = 0.6, p1B = 0.6,
	} },

	{ name = "Desert Pilgrim", desc = "Inspired by Journey: glowing amber sand and golden light.", s = {
		filter = true, fWarm = 0.7, fFade = 0.1, fHi = 0.5, fHiR = 1, fHiG = 0.85, fHiB = 0.6, fSh = 0.3, fShR = 0.4, fShG = 0.2, fShB = 0.1,
		rays = true, raysR = 1, raysG = 0.85, raysB = 0.55, raysAlpha = 0.32, raysSpeed = 0.3, raysPos = "top", raysCount = 11,
		p1on = true, p1type = "dust", p1count = 70, p1alpha = 0.55, p1wind = 0.4, p1R = 1, p1G = 0.85, p1B = 0.6,
	} },

	{ name = "Toon Seas", desc = "Inspired by The Wind Waker: bright cartoon blues and greens with bold contrast.", s = {
		filter = true, fWarm = -0.15, fTint = -0.15, fContrast = 30, fBright = 8, fHi = 0.35, fHiR = 0.82, fHiG = 1, fHiB = 1, fSh = 0.45, fShR = 0, fShG = 0.25, fShB = 0.45,
		qOutline = 2,
	} },

	{ header = "Trippy" },

	{ name = "Acid Trip", desc = "Colors wobble and bleed, rainbow bands sweep across the world and hues remap themselves.", s = {
		tripWobble = true, wobDepth = 0.65, wobSpeed = 0.35, wobGlow = 0.6,
		tripRainbow = true, rbStrength = 0.5, rbSpeed = 0.4, rbSize = 1.2, rbAngle = 35,
		tripRemap = true, remapSpeed = 0.2,
		filter = true, fContrast = 20,
	} },

	{ name = "Kaleidoscope", desc = "Slow rainbow sweeps, holographic shimmer and floating bokeh.", s = {
		tripRainbow = true, rbStrength = 0.6, rbSpeed = 0.2, rbSize = 0.7, rbAngle = 60,
		holo = true, holoAlpha = 0.12, holoSpeed = 0.5, holoScale = 3,
		bokeh = true, bokehR = 1, bokehG = 0.85, bokehB = 1, bokehAlpha = 0.18, bokehSpeed = 0.6,
	} },

	{ name = "Rave", desc = "Strobing colored flashes on the beat over a neon grade, with speed lines.", s = {
		tripStrobe = true, strobeBPM = 128, strobeAlpha = 0.3,
		filter = true, fContrast = 40, fSh = 0.5, fShR = 0.6, fShG = 0, fShB = 0.8, fHi = 0.3, fHiR = 0.8, fHiG = 1, fHiB = 1,
		speed = true, speedCount = 30, speedAlpha = 0.2, speedLen = 0.35, speedFPS = 16,
		aura = true, auraR = 0.3, auraG = 0.2, auraB = 1, auraAlpha = 0.3, auraPulse = 2.13,
	} },

	{ name = "Vaporwave", desc = "Pink and teal pastel grade, a slow rainbow drift and scanlines.", s = {
		filter = true, fFade = 0.25, fContrast = 10, fHi = 0.5, fHiR = 1, fHiG = 0.7, fHiB = 0.95, fSh = 0.6, fShR = 0.1, fShG = 0.45, fShB = 0.55,
		tripRainbow = true, rbStrength = 0.3, rbSpeed = 0.1, rbSize = 2, rbAngle = 0,
		scanlines = true, scanLines = 480, scanHard = 2, scanAlpha = 0.25,
	} },

	{ name = "Fever Dream", desc = "The picture breathes: pulsing brightness, slowly drifting colors and a heavy vignette.", s = {
		tripGamma = true, gPulse = 0.3, gSpeed = 0.18,
		tripWobble = true, wobDepth = 0.35, wobSpeed = 0.15, wobGlow = 0.3,
		filter = true, fVig = 0.6, fWarm = 0.2,
	} },

	{ name = "Chromatic Storm", desc = "The game's color remap cycles fast between palettes while color fringes flare.", s = {
		tripRemap = true, remapSpeed = 0.5,
		fringe = true, fringeAlpha = 0.5, fringeWidth = 0.2,
		filter = true, fContrast = 30,
		tripWobble = true, wobDepth = 0.25, wobSpeed = 0.6, wobGlow = 0.4,
	} },

	{ name = "Drunk", desc = "The camera sways and the view zooms in and out. The only preset that moves the camera; not for the motion-sick.", s = {
		tripSway = true, swayAmt = 1.4, swaySpeed = 0.15,
		tripFov = true, fovAmt = 12, fovSpeed = 0.11,
		filter = true, fWarm = 0.2, fFade = 0.15, fVig = 0.5,
	} },

	{ header = "Filters" },
}

-- one preset per color filter look
for _, f in ipairs(ns.FILTERS) do
	local v = { filter = true, fLook = f.key, fAmount = 1 }
	for k, x in pairs(f.v) do v[k] = x end
	table.insert(ns.PRESETS, { name = f.name, desc = f.desc .. " (color filter)", s = v })
end

-- Find a built-in or custom preset. loose = accept a partial, case-insensitive match.
function ns.FindPreset(name, loose)
	if not name then return nil end
	local lname = name:lower()
	local custom = (ns.RV.db and ns.RV.db.custom) or {}
	for _, list in ipairs({ ns.PRESETS, custom }) do
		for _, p in ipairs(list) do
			if p.name and p.name:lower() == lname then return p end
		end
	end
	if loose then
		for _, list in ipairs({ ns.PRESETS, custom }) do
			for _, p in ipairs(list) do
				if p.name and p.name:lower():find(lname, 1, true) then return p end
			end
		end
	end
end

function ns.SaveCustom(name)
	local RV = ns.RV
	local entry = { name = name, desc = "Your preset.", s = ns.deepcopy(RV.db.settings) }
	for i, p in ipairs(RV.db.custom) do
		if p.name:lower() == name:lower() then
			RV.db.custom[i] = entry
			RV.db.preset, RV.db.modified = name, false
			return
		end
	end
	table.insert(RV.db.custom, entry)
	RV.db.preset, RV.db.modified = name, false
end

function ns.DeleteCustom(name)
	local list = ns.RV.db.custom
	for i = #list, 1, -1 do
		if list[i].name == name then table.remove(list, i) end
	end
end
