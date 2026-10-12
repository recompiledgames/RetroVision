-- RetroVision: the game's own graphics settings (CVars).
-- Every CVar we change is backed up first and put back when the option is turned off,
-- the addon is toggled off, or the player logs out.
local ADDON, ns = ...

local Render = {}
ns.Render = Render

local function getCVar(name)
	if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
	return GetCVar(name)
end

local function setCVar(name, value)
	local fn = (C_CVar and C_CVar.SetCVar) or SetCVar
	return pcall(fn, name, tostring(value))
end

-- Everything we might ever touch. Names that don't exist in this client are skipped.
Render.MANAGED = {
	"renderScale", "ResampleQuality", "textureFilteringMode", "ffxGlow",
	"maxFPS", "useMaxFPS", "graphicsViewDistance", "farclip",
	"graphicsShadowQuality", "graphicsSSAO", "MSAAQuality", "ffxAntiAliasingMode",
	"Gamma", "Contrast", "Brightness",
	"SunShafts", "graphicsSunshafts", "graphicsParticleDensity", "graphicsGroundClutter",
	"graphicsEnvironmentDetail", "graphicsLiquidDetail", "graphicsDepthEffects", "graphicsOutlineMode",
	"graphicsSpellDensity", "graphicsProjectedTextures", "weatherDensity",
	"cameraDistanceMaxZoomFactor", "cameraFov",
	"test_cameraOverShoulder", "test_cameraDynamicPitch", "test_cameraHeadMovementStrength",
	"colorblindShader", "colorblindSimulator", "colorblindWeaknessFactor",
}

-- quality settings: setting key -> game setting(s); -1 means leave alone
local QUALITY = {
	qSunshafts = { "SunShafts", "graphicsSunshafts" },
	qParticles = { "graphicsParticleDensity" },
	qClutter = { "graphicsGroundClutter" },
	qEnv = { "graphicsEnvironmentDetail" },
	qLiquid = { "graphicsLiquidDetail" },
	qDepth = { "graphicsDepthEffects" },
	qOutline = { "graphicsOutlineMode" },
	qSpell = { "graphicsSpellDensity" },
	qProjected = { "graphicsProjectedTextures" },
	qWeather = { "weatherDensity" },
}

function Render:Desired(s)
	local d = {}
	if math.abs(s.rPixel - 1) > 0.005 then
		d.renderScale = string.format("%.2f", s.rPixel)
		if s.rPoint then d.ResampleQuality = 0 end -- 0 = point / nearest upscaling
	end
	if s.rTexFilter >= 0 then d.textureFilteringMode = s.rTexFilter end
	if s.rGlow == "on" then d.ffxGlow = 1 elseif s.rGlow == "off" then d.ffxGlow = 0 end
	if s.rFPS > 0 then d.maxFPS = s.rFPS; d.useMaxFPS = 1 end
	if s.rView > 0 then
		if getCVar("graphicsViewDistance") ~= nil then
			d.graphicsViewDistance = s.rView
		else
			d.farclip = math.floor(177 + (s.rView - 1) * 600 / 9)
		end
	end
	if s.rShadow >= 0 then d.graphicsShadowQuality = s.rShadow end
	if s.rSSAO >= 0 then d.graphicsSSAO = s.rSSAO end
	if s.rAAOff then
		d.MSAAQuality = 0
		d.ffxAntiAliasingMode = 0
	end
	-- picture: explicit overrides, plus the color filter's contrast/brightness/exposure
	local gamma = s.rGammaOn and s.rGamma or nil
	local contrast = s.rContrastOn and s.rContrast or nil
	local bright = s.rBrightOn and s.rBright or nil
	if s.filter then
		local k = s.fAmount or 1
		if (s.fContrast or 0) ~= 0 then contrast = (contrast or 50) + s.fContrast * k end
		if (s.fBright or 0) ~= 0 then bright = (bright or 50) + s.fBright * k end
		local comp = ns.Filter:ExposureComp(s)
		if comp > 1.001 then gamma = (gamma or 1) * comp end
	end
	local crt = ns.Overlay:Compensation(s)
	if crt > 1.001 then gamma = (gamma or 1) * crt end
	if s.tripGamma then gamma = gamma or 1 end
	if gamma then d.Gamma = string.format("%.2f", math.max(0.3, math.min(2.8, gamma))) end
	if contrast then d.Contrast = math.floor(math.max(0, math.min(100, contrast)) + 0.5) end
	if bright then d.Brightness = math.floor(math.max(0, math.min(100, bright)) + 0.5) end
	for key, names in pairs(QUALITY) do
		if (s[key] or -1) >= 0 then
			for _, n in ipairs(names) do d[n] = math.floor(s[key] + 0.5) end
		end
	end
	if (s.cZoom or 0) >= 1 then d.cameraDistanceMaxZoomFactor = string.format("%.1f", s.cZoom) end
	if (s.cFov or 0) >= 50 then d.cameraFov = math.floor(s.cFov + 0.5) end
	if (s.colorFilter or -1) >= 0 then
		-- the game's own full-screen color remap (built for colorblind players)
		if getCVar("colorblindShader") ~= nil then
			d.colorblindShader = s.colorFilter
		else
			d.colorblindSimulator = s.colorFilter
		end
		d.colorblindWeaknessFactor = string.format("%.2f", s.colorFilterStrength)
	end
	if s.cAction then
		d.test_cameraOverShoulder = string.format("%.2f", s.cShoulder)
		d.test_cameraDynamicPitch = s.cPitch and 1 or 0
		d.test_cameraHeadMovementStrength = string.format("%.2f", s.cBob)
	end
	-- trippy effects animate these; here we only claim them so they get backed up
	if s.tripRemap then
		if getCVar("colorblindShader") ~= nil then d.colorblindShader = 1 else d.colorblindSimulator = 1 end
		d.colorblindWeaknessFactor = "0.50"
	end
	if s.tripSway and not d.test_cameraOverShoulder then d.test_cameraOverShoulder = "0.00" end
	if s.tripFov and not d.cameraFov then
		local orig = ns.RV.db.cvarBackup.cameraFov or getCVar("cameraFov")
		if orig then d.cameraFov = orig end
	end
	return d
end

function Render:Apply(s, enabled)
	if InCombatLockdown and InCombatLockdown() then
		-- some clients refuse CVar changes in combat; finish after combat
		if not self.pending then ns.RV:Print("graphics changes will apply when combat ends.") end
		self.pending = true
		return
	end
	self.pending = false

	local want = enabled and self:Desired(s) or {}
	self.lastWant = want
	if want.test_cameraOverShoulder and UIParent and UIParent.UnregisterEvent then
		-- skip the "experimental feature" popup the game shows for ActionCam settings
		pcall(UIParent.UnregisterEvent, UIParent, "EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
	end
	local backup = ns.RV.db.cvarBackup
	for _, name in ipairs(self.MANAGED) do
		local current = getCVar(name)
		if current ~= nil then
			local target = want[name]
			if target ~= nil then
				target = tostring(target)
				if backup[name] == nil then backup[name] = current end
				if current ~= target then setCVar(name, target) end
			elseif backup[name] ~= nil then
				if current ~= backup[name] then setCVar(name, backup[name]) end
				backup[name] = nil
			end
		end
	end
end

function Render:RestoreAll()
	local backup = ns.RV.db and ns.RV.db.cvarBackup
	if not backup then return end
	for name, value in pairs(backup) do
		setCVar(name, value)
		backup[name] = nil
	end
end

-- set game settings every few frames for animated effects. Only settings already
-- claimed (and backed up) by Render:Apply are touched.
function Render:Animate(set)
	local backup = ns.RV.db and ns.RV.db.cvarBackup
	if not backup then return end
	for name, value in pairs(set) do
		if backup[name] ~= nil and getCVar(name) ~= nil then
			setCVar(name, value)
		end
	end
end
