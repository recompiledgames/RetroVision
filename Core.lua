-- RetroVision: core, saved variables, slash commands, events
local ADDON, ns = ...

local RV = CreateFrame("Frame")
ns.RV = RV
RetroVision = RV -- global, used by Bindings.xml and macros

BINDING_HEADER_RETROVISION = "RetroVision"
BINDING_NAME_RETROVISION_TOGGLE = "Toggle all effects"
BINDING_NAME_RETROVISION_NEXT = "Next preset"
BINDING_NAME_RETROVISION_PREV = "Previous preset"
BINDING_NAME_RETROVISION_OPTIONS = "Open settings"

local function deepcopy(t)
	if type(t) ~= "table" then return t end
	local c = {}
	for k, v in pairs(t) do c[k] = deepcopy(v) end
	return c
end
ns.deepcopy = deepcopy

function RV:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffb347Retro|r|cff7fd4ffVision|r: " .. tostring(msg))
end

function RV:InitDB()
	RetroVisionDB = RetroVisionDB or {}
	local db = RetroVisionDB
	if db.enabled == nil then db.enabled = true end
	if db.coverUI == nil then db.coverUI = false end
	db.custom = db.custom or {}
	db.ui = nil   -- 1.9: the ability grid / XP bar were removed
	db.cvarBackup = db.cvarBackup or {}
	self.db = db

	if not db.settings then
		-- first run: start on a gentle preset that touches no graphics settings
		self:ApplyPreset(ns.FindPreset("CRT Monitor") or ns.PRESETS[1], true)
	end
	ns.Migrate(db.settings)
	for _, p in ipairs(db.custom) do ns.Migrate(p.s) end
	for k, v in pairs(ns.NEUTRAL) do
		if db.settings[k] == nil then db.settings[k] = deepcopy(v) end
	end
	db.preset = db.preset or "Off"
	if not db.presetBase then
		local p = ns.FindPreset(db.preset)
		db.presetBase = p and deepcopy(p.s) or {}
	end
end

-- fromUI: the options window caused this change, so it doesn't need re-syncing
function RV:Refresh(fromUI)
	if not self.db then return end
	ns.Overlay:Apply(self.db.settings, self.db.enabled, self.db.coverUI)
	ns.Pretty:Apply(self.db.settings, self.db.enabled, self.db.coverUI)
	ns.Style:Apply(self.db.settings, self.db.enabled, self.db.coverUI)
	ns.Render:Apply(self.db.settings, self.db.enabled)
	ns.Filter:Apply(self.db.settings, self.db.enabled, self.db.coverUI)
	if not fromUI and ns.Options then ns.Options:Sync() end
end

function RV:ApplyPreset(p, silent)
	if not p or not p.s then return end
	local s = deepcopy(ns.NEUTRAL)
	for k, v in pairs(p.s) do s[k] = deepcopy(v) end
	ns.Migrate(s)
	self.db.settings = s
	self.db.presetBase = deepcopy(p.s)
	s.presetStrength = 1
	self.db.preset = p.name
	self.db.modified = false
	self.db.enabled = true
	if not silent then
		self:Refresh()
		self:Print("preset |cffffffff" .. p.name .. "|r")
	end
end

function RV:CyclePreset(dir)
	local list, cur = {}, 1
	for _, p in ipairs(ns.PRESETS) do
		if p.name then list[#list + 1] = p end
	end
	for i, p in ipairs(list) do
		if p.name == self.db.preset then cur = i end
	end
	local i = ((cur - 1 + (dir or 1)) % #list) + 1
	self:ApplyPreset(list[i])
end

function RV:Toggle()
	self.db.enabled = not self.db.enabled
	self:Refresh()
	self:Print(self.db.enabled and "effects |cff55ff55on|r"
		or "effects |cffff5555off|r (your original graphics settings are restored)")
end

function RV:ToggleOptions()
	ns.Options:Toggle()
end

function RV:RestoreGraphics()
	for _, k in ipairs(ns.RENDER_KEYS) do
		self.db.settings[k] = deepcopy(ns.NEUTRAL[k])
	end
	self.db.modified = true
	self:Refresh()
	self:Print("graphics settings restored to what they were before RetroVision changed them.")
end

local function help()
	RV:Print("commands:")
	print("  /retro  - open the settings window")
	print("  /retro settings  - open RetroVision in the game's Options > AddOns menu")
	print("  /retro on | off | toggle")
	print("  /retro <preset>  - e.g. /retro vhs, /retro arcade")
	print("  /retro next | prev | list")
	print("  /retro ui  - toggle effects over the interface too")
	print("  /retro restore  - undo every graphics setting RetroVision changed")
end

-- the add-on menu button next to the minimap (clients that have one)
function RetroVision_OnAddonCompartmentClick(_, button)
	if button == "RightButton" then RV:Toggle() else ns.Options:Toggle() end
end
function RetroVision_OnAddonCompartmentEnter(_, frame)
	GameTooltip:SetOwner(frame or UIParent, "ANCHOR_LEFT")
	GameTooltip:SetText("RetroVision")
	GameTooltip:AddLine("Preset: " .. (RV.db.preset or "?"), 1, 1, 1)
	GameTooltip:AddLine("Left-click: settings   Right-click: effects on/off", 0.7, 0.7, 0.7)
	GameTooltip:Show()
end
function RetroVision_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

SLASH_RETROVISION1 = "/retro"
SLASH_RETROVISION2 = "/retrovision"
SlashCmdList.RETROVISION = function(msg)
	msg = strtrim(msg or ""):lower()
	if msg == "" or msg == "config" or msg == "window" then
		ns.Options:Toggle()
	elseif msg == "settings" or msg == "options" or msg == "menu" then
		ns.Options:OpenSettingsMenu()
	elseif msg == "help" or msg == "?" then
		help()
	elseif msg == "on" then
		RV.db.enabled = true; RV:Refresh(); RV:Print("effects |cff55ff55on|r")
	elseif msg == "off" then
		RV.db.enabled = false; RV:Refresh(); RV:Print("effects |cffff5555off|r")
	elseif msg == "toggle" then
		RV:Toggle()
	elseif msg == "next" then
		RV:CyclePreset(1)
	elseif msg == "prev" then
		RV:CyclePreset(-1)
	elseif msg == "ui" then
		RV.db.coverUI = not RV.db.coverUI; RV:Refresh()
		RV:Print(RV.db.coverUI and "effects now cover the interface too" or "effects now apply to the 3D world only")
	elseif msg == "restore" then
		RV:RestoreGraphics()
	elseif msg == "list" then
		local names = {}
		for _, p in ipairs(ns.PRESETS) do
			if p.name then names[#names + 1] = p.name end
		end
		for _, p in ipairs(RV.db.custom) do names[#names + 1] = "|cff7fd4ff" .. p.name .. "|r" end
		RV:Print(table.concat(names, ", "))
	else
		local p = ns.FindPreset(msg, true)
		if p then RV:ApplyPreset(p) else RV:Print("unknown preset or command '" .. msg .. "'. Try /retro help") end
	end
end

RV:RegisterEvent("ADDON_LOADED")
RV:RegisterEvent("PLAYER_LOGIN")
RV:RegisterEvent("PLAYER_LOGOUT")
RV:RegisterEvent("PLAYER_REGEN_ENABLED")
RV:RegisterEvent("DISPLAY_SIZE_CHANGED")
RV:RegisterEvent("UI_SCALE_CHANGED")
RV:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON then
			self:InitDB()
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif event == "PLAYER_LOGIN" then
		ns.Options:RegisterSettingsCategory()
		self:Refresh()
		self:Print("loaded. Type |cffffffff/retro|r for settings (preset: " .. (self.db.preset or "?") .. ").")
	elseif event == "PLAYER_LOGOUT" then
		-- put the user's real settings back so Config.wtf never keeps our tweaks
		-- (safe if the addon is later removed); they are re-applied at next login
		ns.Render:RestoreAll()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if ns.Render.pending then self:Refresh() end
	else
		ns.Overlay:Layout()
		if RV.db then
			ns.Pretty:Apply(RV.db.settings, RV.db.enabled, RV.db.coverUI)
			ns.Style:Apply(RV.db.settings, RV.db.enabled, RV.db.coverUI)
			ns.Filter:Apply(RV.db.settings, RV.db.enabled, RV.db.coverUI)
		end
	end
end)
