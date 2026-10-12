-- RetroVision: settings UI.
-- The same controls are built twice: in the floating /retro window and in the game's
-- own Settings menu (Esc > Options > AddOns > RetroVision). Both stay in sync.
local ADDON, ns = ...

local Options = {}
ns.Options = Options

local RV = ns.RV
local CW, CH = 724, 704         -- content size
local LEFT_W, COL2, WW = 170, 262, 236
local PAGE_X = LEFT_W + 22
local ACCENT = { 1, 0.70, 0.30 }
local ACCENT2 = { 0.5, 0.83, 1 }
local LIST_ROWS = 17
local ACCENT3 = { 1, 0.42, 0.84 }
local syncing = false

Options.panels = {}

local function S() return RV.db.settings end
local function St(page) return page.store and page.store() or RV.db.settings end

local function changed()
	if syncing then return end
	RV.db.modified = true
	RV:Refresh(true)
	Options:Sync(true)
end

local function addTip(frame, title, text)
	if not text then return end
	frame:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		GameTooltip:AddLine(text, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- value formats: m = display multiplier, d = decimals, u = unit, off(v) = "leave alone" test
---------------------------------------------------------------------------
local PCT = { m = 100, d = 0, u = "%" }
local function fmtValue(spec, v)
	if spec.off and spec.off(v) then return spec.offLabel or "Off" end
	return string.format("%." .. spec.d .. "f", v * spec.m) .. (spec.u or "")
end

---------------------------------------------------------------------------
-- widgets (each one registers a Sync function on its panel)
---------------------------------------------------------------------------
local function place(page, col, w, h)
	w:SetPoint("TOPLEFT", page, "TOPLEFT", col == 1 and 0 or COL2, -page.y[col])
	page.y[col] = page.y[col] + h
end

local function Header(page, col, text)
	local fs = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetText(text)
	fs:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
	page.y[col] = page.y[col] + (page.y[col] > 0 and 8 or 0)
	place(page, col, fs, 22)
end

local function Check(page, col, label, key, tip)
	local c = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
	c:SetSize(24, 24)
	local t = c:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	t:SetPoint("LEFT", c, "RIGHT", 2, 0)
	t:SetText(label)
	c:SetScript("OnClick", function(self)
		St(page)[key] = self:GetChecked() and true or false
		changed()
	end)
	addTip(c, label, tip)
	place(page, col, c, 26)
	table.insert(page.panel.syncs, function() c:SetChecked(St(page)[key] and true or false) end)
end

local function Slider(page, col, label, key, minv, maxv, step, spec, tip, onSet)
	spec = spec or PCT
	local f = CreateFrame("Frame", nil, page)
	f:SetSize(WW, 36)
	local name = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	name:SetPoint("TOPLEFT", 4, 0)
	name:SetText(label)

	-- the value is an edit box: click it and type an exact number
	local eb = CreateFrame("EditBox", nil, f)
	eb:SetSize(84, 14)
	eb:SetPoint("TOPRIGHT", -2, 1)
	eb:SetFontObject(GameFontNormalSmall)
	eb:SetJustifyH("RIGHT")
	eb:SetAutoFocus(false)
	eb:SetMaxLetters(12)
	local ebBG = eb:CreateTexture(nil, "BACKGROUND")
	ebBG:SetPoint("TOPLEFT", -2, 1); ebBG:SetPoint("BOTTOMRIGHT", 2, -1)
	ebBG:SetColorTexture(1, 1, 1, 0)
	eb:SetScript("OnEnter", function() ebBG:SetColorTexture(1, 1, 1, 0.08) end)
	eb:SetScript("OnLeave", function() if not eb:HasFocus() then ebBG:SetColorTexture(1, 1, 1, 0) end end)
	eb:SetScript("OnEditFocusGained", function(self) ebBG:SetColorTexture(1, 1, 1, 0.12); self:HighlightText() end)

	local s = CreateFrame("Slider", nil, f)
	s:SetOrientation("HORIZONTAL")
	s:SetHeight(16)
	s:SetPoint("TOPLEFT", 4, -14)
	s:SetPoint("TOPRIGHT", -2, -14)
	s:SetHitRectInsets(0, 0, -4, -4)
	local track = s:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(1, 1, 1, 0.15)
	track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4)
	local thumb = s:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
	thumb:SetSize(8, 16)
	s:SetThumbTexture(thumb)
	s:SetMinMaxValues(minv, maxv)
	s:SetValueStep(step)
	if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end

	local function round(v) return math.floor((v - minv) / step + 0.5) * step + minv end
	local function show(v) if not eb:HasFocus() then eb:SetText(fmtValue(spec, v)) end end

	s:SetScript("OnValueChanged", function(self, v)
		if syncing then return end
		v = round(v)
		show(v)
		if math.abs((St(page)[key] or 0) - v) > 1e-6 then
			St(page)[key] = v
			if onSet then onSet(v) end
			changed()
		end
	end)
	s:EnableMouseWheel(true)
	s:SetScript("OnMouseWheel", function(self, d)
		local v = round(St(page)[key] or minv) + d * step * (IsShiftKeyDown() and 10 or 1)
		self:SetValue(math.min(maxv, math.max(minv, v)))
	end)

	local function sync()
		local v = St(page)[key]
		local was = syncing
		syncing = true
		s:SetValue(v)
		syncing = was
		show(v)
	end
	eb:SetScript("OnEnterPressed", function(self)
		local txt = self:GetText():lower()
		local n = tonumber((txt:gsub("[^%d%.%-]", "")))
		if spec.offLabel and (txt == "off" or txt:find("leave")) then
			n = spec.offValue
		elseif n then
			n = math.min(maxv, math.max(minv, n / spec.m)) -- typed values keep full precision
		end
		self:ClearFocus()
		if n then
			St(page)[key] = n
			if onSet then onSet(n) end
			changed()
		end
		sync()
	end)
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); sync() end)
	eb:SetScript("OnEditFocusLost", function(self)
		ebBG:SetColorTexture(1, 1, 1, 0)
		self:SetText(fmtValue(spec, St(page)[key]))
	end)

	addTip(s, label, (tip and (tip .. "\n\n") or "") ..
		"Mouse wheel: fine steps (hold Shift for big steps).\nClick the number to type an exact value.")
	place(page, col, f, 40)
	table.insert(page.panel.syncs, sync)
	return f
end

-- options = { {value, "Label"}, ... }
local function Cycle(page, col, label, key, options, tip, onSet)
	local f = CreateFrame("Frame", nil, page)
	f:SetSize(WW, 24)
	local name = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 4, 0)
	name:SetText(label)

	local nextB = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	nextB:SetSize(24, 20); nextB:SetPoint("RIGHT"); nextB:SetText(">")
	local valT = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	valT:SetPoint("RIGHT", nextB, "LEFT", -2, 0)
	valT:SetWidth(100)
	valT:SetJustifyH("CENTER")
	local prevB = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	prevB:SetSize(24, 20); prevB:SetPoint("RIGHT", valT, "LEFT", -2, 0); prevB:SetText("<")

	local function idx()
		for i, o in ipairs(options) do
			if o[1] == St(page)[key] then return i end
		end
		return 1
	end
	local function go(d)
		local i = idx() + d
		if i < 1 then i = #options elseif i > #options then i = 1 end
		St(page)[key] = options[i][1]
		valT:SetText(options[i][2])
		if onSet then onSet(options[i][1]) end
		changed()
	end
	nextB:SetScript("OnClick", function() go(1) end)
	prevB:SetScript("OnClick", function() go(-1) end)
	f:EnableMouse(true)
	f:EnableMouseWheel(true)
	f:SetScript("OnMouseWheel", function(_, d) go(d > 0 and 1 or -1) end)
	addTip(f, label, tip)
	place(page, col, f, 28)
	table.insert(page.panel.syncs, function() valT:SetText(options[idx()][2]) end)
end

-- color swatch: click to open the game's color picker. keys: prefix.."R"/"G"/"B"
local function openPicker(r, g, b, apply)
	local CPF = ColorPickerFrame
	if not CPF then return end
	local function current()
		local nr, ng, nb = CPF:GetColorRGB()
		apply(nr, ng, nb)
	end
	if CPF.SetupColorPickerAndShow then
		CPF:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false,
			swatchFunc = current, cancelFunc = function() apply(r, g, b) end })
	else
		CPF.hasOpacity = false
		CPF.previousValues = { r, g, b }
		CPF.func = current
		CPF.opacityFunc = nil
		CPF.cancelFunc = function() apply(r, g, b) end
		CPF:SetColorRGB(r, g, b)
		CPF:Hide()
		CPF:Show()
	end
	CPF:SetFrameStrata("FULLSCREEN_DIALOG")
	if CPF.SetToplevel then CPF:SetToplevel(true) end
	CPF:Raise()
end

local function Color(page, col, label, prefix, tip)
	local f = CreateFrame("Button", nil, page)
	f:SetSize(WW, 22)
	local name = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 4, 0)
	name:SetText(label)
	local border = f:CreateTexture(nil, "BORDER")
	border:SetSize(56, 18)
	border:SetPoint("RIGHT", -2, 0)
	border:SetColorTexture(1, 1, 1, 0.5)
	local sw = f:CreateTexture(nil, "ARTWORK")
	sw:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
	sw:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
	local hex = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hex:SetPoint("RIGHT", border, "LEFT", -6, 0)
	local function sync()
		local s = St(page)
		local r, g, b = s[prefix .. "R"], s[prefix .. "G"], s[prefix .. "B"]
		sw:SetColorTexture(r, g, b, 1)
		hex:SetText(string.format("#%02X%02X%02X", r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5))
	end
	f:SetScript("OnClick", function()
		local s = St(page)
		openPicker(s[prefix .. "R"], s[prefix .. "G"], s[prefix .. "B"], function(r, g, b)
			s[prefix .. "R"], s[prefix .. "G"], s[prefix .. "B"] = r, g, b
			sync()
			changed()
		end)
	end)
	addTip(f, label, (tip and (tip .. "\n\n") or "") .. "Click to pick a color.")
	place(page, col, f, 26)
	table.insert(page.panel.syncs, sync)
end

-- a row of small buttons that set one value
local function QuickRow(page, col, key, choices)
	local row = CreateFrame("Frame", nil, page)
	row:SetSize(WW, 20)
	local wEach = math.floor((WW - 4 * (#choices - 1)) / #choices)
	for i, c in ipairs(choices) do
		local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		b:SetSize(wEach, 18)
		b:SetPoint("LEFT", (i - 1) * (wEach + 4), 0)
		b:SetText(c[2])
		b:SetScript("OnClick", function() St(page)[key] = c[1]; changed() end)
	end
	place(page, col, row, 26)
end

local function Button(page, col, label, width, onClick, tip)
	local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
	b:SetSize(width or 200, 22)
	b:SetText(label)
	b:SetScript("OnClick", onClick)
	addTip(b, label, tip)
	place(page, col, b, 28)
end

local function Note(page, col, text)
	local fs = page:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	fs:SetWidth(WW)
	fs:SetJustifyH("LEFT")
	fs:SetText(text)
	place(page, col, fs, fs:GetStringHeight() + 6)
end

---------------------------------------------------------------------------
-- specs
---------------------------------------------------------------------------
local MULT = { m = 1, d = 0, u = "x" }
local PX = { m = 1, d = 0, u = " px" }
local INT = { m = 1, d = 0 }
local DEC2 = { m = 1, d = 2 }
local SPEED = { m = 1, d = 1, u = "x" }
local PIXEL = { m = 100, d = 0, u = "%", off = function(v) return math.abs(v - 1) < 0.005 end, offLabel = "Native (100%)", offValue = 1 }
local LEAVE = { m = 1, d = 0, off = function(v) return v < 0 end, offLabel = "Leave alone", offValue = -1 }
local ZOOM = { m = 1, d = 1, u = "x", off = function(v) return v < 1 end, offLabel = "Leave alone", offValue = 0.9 }
local FOV = { m = 1, d = 0, u = "\194\176", off = function(v) return v < 50 end, offLabel = "Leave alone", offValue = 49 }
local PULSE = { m = 1, d = 2, u = " Hz", off = function(v) return v <= 0 end, offLabel = "Steady", offValue = 0 }
local HZ = { m = 1, d = 2, u = " Hz" }
local SPEED2 = { m = 1, d = 2, u = "x" }
local SIGNED = { m = 1, d = 2 }
local FPS = { m = 1, d = 0, u = " fps", off = function(v) return v <= 0 end, offLabel = "Leave alone", offValue = 0 }
local VIEWD = { m = 1, d = 0, off = function(v) return v <= 0 end, offLabel = "Leave alone", offValue = 0 }
local ASPECT = { m = 1, d = 2, u = " : 1", off = function(v) return v < 1 end, offLabel = "Off", offValue = 0 }
local LIFT = { m = 255, d = 0 }

---------------------------------------------------------------------------
-- pages
---------------------------------------------------------------------------
local LINES = { m = 1, d = 0, u = " lines" }
local HARD = { m = 1, d = 0 }

local function BuildScreen(p)
	Header(p, 1, "Scanlines")
	Check(p, 1, "Scanlines", "scanlines", "Gaussian electron-beam scanlines, modelled on CRT-Lottes and CRT-Royale.")
	Slider(p, 1, "Line count", "scanLines", 120, 1080, 1, LINES,
		"How many scanlines fill the screen. 224-240 = arcade/console CRT, 480 = PC monitor or PVM. Works at any resolution.")
	Slider(p, 1, "Beam hardness", "scanHard", 1, 5, 1, HARD, "1 = soft TV beams that blend together, 5 = sharp, thin beams with deep gaps.")
	Slider(p, 1, "Scanline strength", "scanAlpha", 0, 1, 0.01)
	Check(p, 1, "Interlace shimmer", "interlace", "Lines jump half a step 30 times a second, like an interlaced TV. Can be tiring on the eyes.")

	Header(p, 1, "Phosphor mask")
	Cycle(p, 1, "Mask", "mask", { { "none", "None" }, { "mg2", "Magenta/green 2px" }, { "rgb3", "RGB grille 3px" },
		{ "grille", "Aperture grille 4px" }, { "slot", "Slot mask" }, { "dots", "Dot triad" } },
		"The RGB phosphor pattern of a CRT. Magenta/green and 3px RGB line up with your screen's sub-pixels and look most real at 1080p-1440p; use Mask size 2x at 4K.")
	Slider(p, 1, "Mask strength", "maskStrength", 0.05, 1, 0.05)
	Slider(p, 1, "Mask size", "maskScale", 1, 4, 1, MULT)

	Header(p, 1, "Brightness")
	Check(p, 1, "Brightness compensation", "crtBoost", "Scanlines and masks darken the picture. This raises the game's gamma to give the light back, like CRT shaders' bright boost.")
	Slider(p, 1, "Compensation amount", "crtBoostAmt", 0, 1.5, 0.01)

	Header(p, 2, "Glass")
	Check(p, 2, "Vignette", "vignette", "Darker edges and corners, with a natural lens falloff.")
	Slider(p, 2, "Vignette strength", "vignetteAlpha", 0, 1, 0.01)
	Check(p, 2, "Rounded CRT corners", "corners")
	Slider(p, 2, "Corner radius", "cornerRadius", 1, 400, 1, PX)
	Check(p, 2, "Glass glare", "glare", "A soft reflection on the tube glass.")
	Slider(p, 2, "Glare strength", "glareAlpha", 0, 0.4, 0.005)

	Header(p, 2, "Dithering")
	Check(p, 2, "Dither", "dither", "Ordered dither like old 8/16-bit color modes. Match the size to your render scale.")
	Cycle(p, 2, "Pattern", "ditherType", { { "bayer4", "Bayer 4x4" }, { "bayer8", "Bayer 8x8" }, { "blue", "Blue noise" } },
		"Bayer 4x4 = PS1/SNES look. Bayer 8x8 = finer crosshatch. Blue noise = smooth, organic grain without a visible pattern.")
	Slider(p, 2, "Dither strength", "ditherAlpha", 0, 1, 0.01)
	Slider(p, 2, "Dither size", "ditherScale", 1, 8, 1, MULT)

	Header(p, 2, "LCD grid")
	Check(p, 2, "Handheld LCD grid", "lcdGrid", "Thin dark gaps between pixels, like a Game Boy or GBA screen. Lines up with your render scale automatically.")
	Slider(p, 2, "Grid strength", "lcdAlpha", 0, 1, 0.01)
	Slider(p, 2, "Cell size", "lcdCell", 0, 12, 0.5, { m = 1, d = 1, u = " px", off = function(v) return v <= 0 end, offLabel = "Auto", offValue = 0 },
		"Auto matches the pixel size from Render scale.")
end

local SWATCHES = {
	{ "Warm", 1, 0.9, 0.75 }, { "Sepia", 1, 0.82, 0.55 }, { "Amber", 1, 0.62, 0.15 },
	{ "Green", 0.3, 1, 0.35 }, { "Cool", 0.75, 0.85, 1 }, { "Rose", 1, 0.8, 0.9 },
}

local function BuildColor(p)
	Header(p, 1, "Tint (multiply)")
	Check(p, 1, "Tint", "tint", "Multiplies the screen by a color. Great for sepia, amber and green-screen looks.")
	Slider(p, 1, "Red", "tintR", 0, 1, 0.01)
	Slider(p, 1, "Green", "tintG", 0, 1, 0.01)
	Slider(p, 1, "Blue", "tintB", 0, 1, 0.01)
	Slider(p, 1, "Tint strength", "tintStrength", 0, 1, 0.01)

	local row = CreateFrame("Frame", nil, p)
	row:SetSize(WW, 22)
	for i, sw in ipairs(SWATCHES) do
		local b = CreateFrame("Button", nil, row)
		b:SetSize(36, 20)
		b:SetPoint("LEFT", (i - 1) * 40, 0)
		local t = b:CreateTexture(nil, "ARTWORK")
		t:SetAllPoints()
		t:SetColorTexture(sw[2], sw[3], sw[4], 1)
		b:SetScript("OnClick", function()
			local s = S()
			s.tint, s.tintR, s.tintG, s.tintB = true, sw[2], sw[3], sw[4]
			if s.tintStrength < 0.3 then s.tintStrength = 0.6 end
			changed()
		end)
		addTip(b, sw[1], "Set the tint to this color.")
	end
	place(p, 1, row, 28)
	Note(p, 1, "Addons can't read the image, so true grayscale or palette remapping isn't possible. Strong tints get you most of the way.")

	Header(p, 2, "Shadow lift (add)")
	Check(p, 2, "Lift shadows", "lift", "Adds a little color to every pixel, washing out blacks like old phosphor screens and tape.")
	Slider(p, 2, "Red", "liftR", 0, 0.5, 1 / 255, LIFT, "Shown on the 0-255 color scale.")
	Slider(p, 2, "Green", "liftG", 0, 0.5, 1 / 255, LIFT, "Shown on the 0-255 color scale.")
	Slider(p, 2, "Blue", "liftB", 0, 0.5, 1 / 255, LIFT, "Shown on the 0-255 color scale.")
	Slider(p, 2, "Lift amount", "liftAlpha", 0, 3, 0.01)

	Header(p, 2, "Exposure")
	Slider(p, 2, "Darken", "dim", 0, 1, 0.01)

	Header(p, 2, "Color fringe")
	Check(p, 2, "Misregistered color edges", "fringe", "Colored light bleeding in from the left and right edges, like an off-register comic print.")
	Color(p, 2, "Left color", "fringeL")
	Color(p, 2, "Right color", "fringeR")
	Slider(p, 2, "Fringe strength", "fringeAlpha", 0, 1, 0.01)
	Slider(p, 2, "Fringe width", "fringeWidth", 0.02, 0.5, 0.01)

	Header(p, 1, "Paper")
	Check(p, 1, "Paper texture", "paper", "Fibers, grain and blotches like painting on paper or parchment.")
	Color(p, 1, "Paper ink color", "paper")
	Slider(p, 1, "Paper strength", "paperAlpha", 0, 1, 0.01)
	Slider(p, 1, "Paper grain size", "paperScale", 0.5, 4, 0.05, SPEED2)
end

local function BuildMotion(p)
	Header(p, 1, "Film grain")
	Check(p, 1, "Film grain", "grain", "Zero-mean Gaussian grain that both darkens and brightens, like real film.")
	Slider(p, 1, "Grain strength", "grainAlpha", 0, 1, 0.01)
	Slider(p, 1, "Grain size", "grainSize", 0.5, 4, 0.05, SPEED2)
	Slider(p, 1, "Grain speed", "grainFPS", 1, 60, 1, { m = 1, d = 0, u = " fps" })
	Check(p, 1, "Color grain", "grainChroma", "Colored specks like fast color film.")

	Header(p, 1, "Film damage")
	Slider(p, 1, "Dust and scratches", "filmDamage", 0, 1, 0.01, { m = 100, d = 0, u = "%", off = function(v) return v <= 0 end, offLabel = "Off", offValue = 0 })

	Header(p, 1, "Flicker")
	Check(p, 1, "Brightness flicker", "flicker", "Random small brightness drops, like an old projector or tube.")
	Slider(p, 1, "Flicker amount", "flickerAmount", 0, 0.5, 0.01)

	Header(p, 1, "Rolling refresh bar")
	Check(p, 1, "Rolling bar", "rollBar", "A faint bright band drifting down the screen, like a CRT filmed on camera.")
	Slider(p, 1, "Bar strength", "rollAlpha", 0, 0.3, 0.005)
	Slider(p, 1, "Bar speed", "rollSpeed", 0.01, 1, 0.01, SPEED2)

	Header(p, 2, "VHS")
	Check(p, 2, "Tracking noise band", "vhs", "A noisy band that rolls down the screen every so often.")
	Slider(p, 2, "Band strength", "vhsAlpha", 0, 1, 0.01)
	Slider(p, 2, "Roll speed", "vhsSpeed", 0.1, 5, 0.1, SPEED)
	Check(p, 2, "Head-switching noise", "vhsHead", "The jittery noisy strip at the bottom of every VHS picture.")
	Slider(p, 2, "Snow", "vhsSnow", 0, 1, 0.01, { m = 100, d = 0, u = "%", off = function(v) return v <= 0 end, offLabel = "Off", offValue = 0 }, "Random white specks of tape noise.")
	Slider(p, 2, "Tape dropouts", "vhsDrop", 0, 1, 0.01, { m = 100, d = 0, u = "%", off = function(v) return v <= 0 end, offLabel = "Off", offValue = 0 }, "Short white streaks where the tape lost signal.")
	Check(p, 2, "Camcorder display", "vhsOSD", "PLAY, SP and a running tape counter on screen.")
end

local TEXF = { { -1, "Leave alone" }, { 0, "Bilinear" }, { 1, "Trilinear" }, { 2, "2x Aniso" }, { 3, "4x Aniso" }, { 4, "8x Aniso" }, { 5, "16x Aniso" } }
local SHADOW = { { -1, "Leave alone" }, { 0, "Lowest" }, { 1, "Low" }, { 2, "Fair" }, { 3, "Good" }, { 4, "High" }, { 5, "Ultra" } }
local SSAO = { { -1, "Leave alone" }, { 0, "Off" }, { 1, "Low" }, { 2, "Good" }, { 3, "High" }, { 4, "Ultra" } }

local function BuildRender(p)
	Header(p, 1, "Resolution")
	Slider(p, 1, "Render scale", "rPixel", 0.1, 2, 0.01, PIXEL,
		"Below 100% pixelates the 3D world. Above 100% supersamples it for extra-sharp edges (heavy on the GPU). The interface stays sharp.")
	Check(p, 1, "Crisp pixels (point upscale)", "rPoint", "Upscales the low-res picture without smoothing, so pixels stay square.")

	Header(p, 1, "Old-school look")
	Cycle(p, 1, "Texture filtering", "rTexFilter", TEXF, "Bilinear is how 2004 looked.")
	Cycle(p, 1, "Full-screen glow", "rGlow", { { "keep", "Leave alone" }, { "on", "On" }, { "off", "Off" } }, "The classic soft glow / bloom.")
	Slider(p, 1, "View distance", "rView", 0, 10, 1, VIEWD, "1 is a short, foggy draw distance.")
	Slider(p, 1, "FPS cap", "rFPS", 0, 240, 1, FPS)

	Header(p, 1, "Aspect bars")
	Slider(p, 1, "Picture shape", "letterbox", 0.99, 3, 0.01, ASPECT,
		"Black bars that crop the picture to this width-to-height ratio. All the way left turns bars off.")
	QuickRow(p, 1, "letterbox", { { 0, "Off" }, { 4 / 3, "4:3" }, { 10 / 9, "10:9" }, { 16 / 9, "16:9" }, { 2.39, "Film" } })

	Header(p, 2, "Lighting")
	Cycle(p, 2, "Shadows", "rShadow", SHADOW)
	Cycle(p, 2, "Ambient occlusion", "rSSAO", SSAO)
	Check(p, 2, "Anti-aliasing off", "rAAOff", "Hard, jagged edges like old hardware.")

	Header(p, 2, "Picture")
	Check(p, 2, "Override gamma", "rGammaOn")
	Slider(p, 2, "Gamma", "rGamma", 0.3, 2.8, 0.01, DEC2)
	Check(p, 2, "Override contrast", "rContrastOn")
	Slider(p, 2, "Contrast", "rContrast", 0, 100, 1, INT)
	Check(p, 2, "Override brightness", "rBrightOn")
	Slider(p, 2, "Brightness", "rBright", 0, 100, 1, INT)

	p.y[2] = p.y[2] + 4
	Button(p, 2, "Restore my graphics settings", WW, function() RV:RestoreGraphics() end,
		"Sets every option on this page to 'Leave alone' and puts back what RetroVision changed.\n\nYour originals also come back when you turn an option off, switch effects off, or log out.")
end

local function BuildLight(p)
	Header(p, 1, "Color gradient")
	Check(p, 1, "Sky-to-ground gradient", "grad", "Colors the top and bottom of the screen differently, like a graded film shot.")
	Cycle(p, 1, "Blend", "gradMode", { { "mod", "Multiply" }, { "add", "Glow" }, { "paint", "Paint" } },
		"Multiply: tints like a lens filter.\nGlow: adds light in that color.\nPaint: washes a translucent color over the scene.")
	Color(p, 1, "Top color", "gradTop")
	Color(p, 1, "Bottom color", "gradBot")
	Slider(p, 1, "Gradient strength", "gradStrength", 0, 1, 0.01)

	Header(p, 1, "Edge glow")
	Check(p, 1, "Colored edge glow", "aura", "A soft colored light around the edges of the screen.")
	Color(p, 1, "Glow color", "aura")
	Slider(p, 1, "Glow strength", "auraAlpha", 0, 1, 0.01)
	Slider(p, 1, "Glow pulse", "auraPulse", 0, 3, 0.01, PULSE, "How fast the glow breathes. All the way left keeps it steady.")

	Header(p, 1, "Haze")
	Check(p, 1, "Atmospheric haze", "haze", "Lifts the whole picture with a soft colored light, like mist or bloom.")
	Color(p, 1, "Haze color", "haze")
	Slider(p, 1, "Haze strength", "hazeAlpha", 0, 0.5, 0.005)

	Header(p, 2, "Light leaks")
	Check(p, 2, "Light leaks", "leaks", "Big soft blooms of colored light drifting around the edges, like an old film camera.")
	Color(p, 2, "Leak color", "leaks")
	Slider(p, 2, "Leak strength", "leaksAlpha", 0, 1, 0.01)
	Slider(p, 2, "Drift speed", "leaksSpeed", 0, 3, 0.01, SPEED2)

	Header(p, 2, "Sun rays")
	Check(p, 2, "God rays", "rays", "Shafts of light fanning out from a corner of the screen and slowly swaying.")
	Color(p, 2, "Ray color", "rays")
	Slider(p, 2, "Ray strength", "raysAlpha", 0, 1, 0.01)
	Slider(p, 2, "Sway speed", "raysSpeed", 0, 3, 0.01, SPEED2)
	Cycle(p, 2, "Light source", "raysPos", { { "topleft", "Top left" }, { "top", "Top" }, { "topright", "Top right" } })
	Slider(p, 2, "Number of beams", "raysCount", 1, 30, 1, INT)
	Slider(p, 2, "Beam width", "raysWidth", 0.2, 3, 0.01, SPEED2)
	Slider(p, 2, "Beam length", "raysLength", 0.3, 1.6, 0.01, SPEED2)
end

local function BuildMagic(p)
	Header(p, 1, "Color cycle")
	Check(p, 1, "Rainbow color drift", "hue", "Slowly cycles a tint through every color.")
	Slider(p, 1, "Drift strength", "hueStrength", 0, 1, 0.01)
	Slider(p, 1, "Drift speed", "hueSpeed", 0.01, 5, 0.01, SPEED2)

	Header(p, 1, "Holographic shimmer")
	Check(p, 1, "Holographic shimmer", "holo", "Iridescent rainbow bands sliding across the screen.")
	Slider(p, 1, "Shimmer strength", "holoAlpha", 0, 0.6, 0.005)
	Slider(p, 1, "Shimmer speed", "holoSpeed", 0, 3, 0.01, SPEED2)
	Slider(p, 1, "Band size", "holoScale", 1, 12, 1, MULT)

	Header(p, 1, "Pulse")
	Check(p, 1, "Breathing light", "pulse", "The whole screen gently glows brighter and dimmer in a color.")
	Color(p, 1, "Pulse color", "pulse")
	Slider(p, 1, "Pulse strength", "pulseAlpha", 0, 0.5, 0.005)
	Slider(p, 1, "Pulse speed", "pulseSpeed", 0.01, 3, 0.01, HZ)

	Header(p, 2, "Aurora")
	Check(p, 2, "Northern lights", "aurora", "Rippling aurora curtains across the top of the screen.")
	Slider(p, 2, "Aurora strength", "auroraAlpha", 0, 1.5, 0.01)
	Slider(p, 2, "Aurora speed", "auroraSpeed", 0, 3, 0.01, SPEED2)
	Slider(p, 2, "Aurora height", "auroraHeight", 0.1, 1, 0.01)

	Header(p, 2, "Caustics")
	Check(p, 2, "Underwater light", "caustics", "Rippling light patterns like sunlight through water.")
	Color(p, 2, "Light color", "caus")
	Slider(p, 2, "Caustic strength", "causAlpha", 0, 1, 0.01)
	Slider(p, 2, "Ripple speed", "causSpeed", 0, 3, 0.01, SPEED2)
	Slider(p, 2, "Ripple size", "causScale", 2, 16, 0.5, SPEED2)

	Header(p, 2, "Bokeh")
	Check(p, 2, "Bokeh and lens dust", "bokeh", "Soft out-of-focus circles of light drifting over the lens.")
	Color(p, 2, "Bokeh color", "bokeh")
	Slider(p, 2, "Bokeh strength", "bokehAlpha", 0, 1, 0.01)
	Slider(p, 2, "Drift speed", "bokehSpeed", 0, 3, 0.01, SPEED2)
end

local function particleColumn(p, col, P, title)
	local types = {}
	for _, t in ipairs(ns.Pretty.TYPES) do types[#types + 1] = { t.key, t.name } end
	Header(p, col, title)
	Check(p, col, "Enabled", P .. "on")
	Cycle(p, col, "Type", P .. "type", types, "Switching type also resets the color to that type's natural color.", function(key)
		for _, t in ipairs(ns.Pretty.TYPES) do
			if t.key == key then
				local s = S()
				s[P .. "R"], s[P .. "G"], s[P .. "B"] = t.color[1], t.color[2], t.color[3]
			end
		end
		Options:Sync()
	end)
	Color(p, col, "Color", P, "Arcane motes always use rainbow colors, and leaves vary their color a little.")
	Slider(p, col, "Amount", P .. "count", 1, 400, 1, INT, "How many particles are on screen. Hundreds can cost a few FPS.")
	Slider(p, col, "Size", P .. "size", 0.2, 5, 0.01, SPEED2)
	Slider(p, col, "Speed", P .. "speed", 0, 5, 0.01, SPEED2)
	Slider(p, col, "Opacity", P .. "alpha", 0, 1, 0.01)
	Slider(p, col, "Wind", P .. "wind", -2, 2, 0.01, SIGNED, "Negative blows left, positive blows right.")
	Check(p, col, "Twinkle", P .. "twinkle", "Fireflies, embers, stars and motes pulse their brightness.")
end

local function BuildParticles(p)
	particleColumn(p, 1, "p1", "Particle layer 1")
	particleColumn(p, 2, "p2", "Particle layer 2")
end

local FILTERS = { { -1, "Leave alone" }, { 0, "Off" }, { 1, "Remap 1" }, { 2, "Remap 2" }, { 3, "Remap 3" } }

local function BuildStyle(p)
	Header(p, 1, "Comic ink frame")
	Check(p, 1, "Ink border", "ink", "A thick, brushy hand-inked border around the screen.")
	Slider(p, 1, "Border thickness", "inkThick", 0.05, 1, 0.01)
	Color(p, 1, "Ink color", "ink")

	Header(p, 1, "Halftone dots")
	Check(p, 1, "Halftone", "halftone", "Printed comic dots, like Spider-Verse or Persona.")
	Color(p, 1, "Dot color", "ht")
	Slider(p, 1, "Dot strength", "htAlpha", 0, 1, 0.01)
	Slider(p, 1, "Dot size", "htScale", 0.5, 5, 0.05, SPEED2)
	Check(p, 1, "Edges only", "htEdges", "Fade the dots out toward the center of the screen.")

	Header(p, 1, "Crosshatch")
	Check(p, 1, "Ink crosshatching", "hatch", "Hand-drawn pen shading lines, like Borderlands.")
	Color(p, 1, "Line color", "hatch")
	Slider(p, 1, "Hatch strength", "hatchAlpha", 0, 1, 0.01)
	Slider(p, 1, "Line spacing", "hatchScale", 0.5, 5, 0.05, SPEED2)
	Check(p, 1, "Edges only", "hatchEdges", "Shade only toward the edges of the screen.")

	Header(p, 2, "Speed lines")
	Check(p, 2, "Anime speed lines", "speed", "Flickering lines rushing in from the screen edges.")
	Color(p, 2, "Line color", "speed")
	Slider(p, 2, "Number of lines", "speedCount", 1, 150, 1, INT)
	Slider(p, 2, "Line strength", "speedAlpha", 0, 1, 0.01)
	Slider(p, 2, "Reach toward center", "speedLen", 0.05, 0.95, 0.01)
	Slider(p, 2, "Flicker rate", "speedFPS", 1, 30, 1, { m = 1, d = 0, u = " /s" })

	Header(p, 2, "Graffiti splatter")
	Check(p, 2, "Paint splatters", "splat", "Graffiti-style spray-paint splats in the corners.")
	Color(p, 2, "Color A", "splatA")
	Color(p, 2, "Color B", "splatB")
	Slider(p, 2, "Splat size", "splatSize", 0.1, 1, 0.01)
	Slider(p, 2, "Splat opacity", "splatAlpha", 0, 1, 0.01)
end

local function lookList()
	local l = { { "custom", "Custom" } }
	for _, f in ipairs(ns.FILTERS) do l[#l + 1] = { f.key, f.name } end
	return l
end

local function BuildFilter(p)
	Header(p, 1, "Color filter")
	Check(p, 1, "Color filter", "filter", "Grades every pixel of the picture, like an Instagram filter.")
	Cycle(p, 1, "Look", "fLook", lookList(), "Pick a ready-made look, then fine-tune it below.", function(key)
		local s = S()
		for _, f in ipairs(ns.FILTERS) do
			if f.key == key then
				for k, v in pairs(ns.NEUTRAL) do
					if k:match("^f%u") and k ~= "fAmount" and k ~= "fAuto" then s[k] = v end
				end
				for k, v in pairs(f.v) do s[k] = v end
				s.filter = true
			end
		end
		Options:Sync()
	end)
	Slider(p, 1, "Intensity", "fAmount", 0, 2, 0.01, nil, "How strongly the whole filter is applied. Above 100% exaggerates it.")

	Header(p, 1, "Adjust")
	Slider(p, 1, "Warmth", "fWarm", -1, 1, 0.01, SIGNED, "Left: cooler and bluer. Right: warmer and more orange.")
	Slider(p, 1, "Tint", "fTint", -1, 1, 0.01, SIGNED, "Left: greener. Right: more magenta.")
	Slider(p, 1, "Fade", "fFade", 0, 1, 0.01, nil, "Lifts the blacks for a washed-out film look.")
	Slider(p, 1, "Contrast", "fContrast", -50, 50, 1, INT)
	Slider(p, 1, "Brightness", "fBright", -50, 50, 1, INT)
	Check(p, 1, "Auto exposure", "fAuto", "Brightens the midtones to make up for strong color filters darkening the picture.")

	Header(p, 2, "Highlights")
	Color(p, 2, "Highlight color", "fHi", "The color bright areas lean toward.")
	Slider(p, 2, "Highlight tint", "fHi", 0, 1, 0.01)
	Header(p, 2, "Shadows")
	Color(p, 2, "Shadow color", "fSh", "The color dark areas glow with.")
	Slider(p, 2, "Shadow tint", "fSh", 0, 1, 0.01)
	Header(p, 2, "Vignette")
	Slider(p, 2, "Filter vignette", "fVig", 0, 1, 0.01)

	Header(p, 2, "Game color remap")
	Cycle(p, 2, "Remap", "colorFilter", FILTERS,
		"Uses the game's built-in full-screen color filter (made for colorblind players) to genuinely shift hues between channels. Results depend on your client; 'Leave alone' never touches it.")
	Slider(p, 2, "Remap strength", "colorFilterStrength", 0.05, 1, 0.01)
end

local function BuildTrippy(p)
	Header(p, 1, "Color wobble")
	Check(p, 1, "Wobbling colors", "tripWobble", "Each color channel swells and fades at its own pace, so the whole world keeps shifting hue.")
	Slider(p, 1, "Wobble depth", "wobDepth", 0, 1, 0.01)
	Slider(p, 1, "Wobble speed", "wobSpeed", 0.01, 3, 0.01, HZ)
	Slider(p, 1, "Glow", "wobGlow", 0, 1, 0.01, nil, "Adds the opposite color back as light, for stronger swings.")

	Header(p, 1, "Rainbow sweep")
	Check(p, 1, "Rainbow sweep", "tripRainbow", "Rainbow bands that color the world as they slide across it.")
	Slider(p, 1, "Rainbow strength", "rbStrength", 0.1, 1, 0.1)
	Slider(p, 1, "Sweep speed", "rbSpeed", 0, 3, 0.01, SPEED2)
	Slider(p, 1, "Band size", "rbSize", 0.2, 4, 0.01, SPEED2)
	Slider(p, 1, "Angle", "rbAngle", 0, 180, 1, { m = 1, d = 0, u = "\194\176" })

	Header(p, 1, "Strobe")
	Check(p, 1, "Color strobe", "tripStrobe", "Colored flashes on a beat. Avoid if you are sensitive to flashing lights.")
	Slider(p, 1, "Beats per minute", "strobeBPM", 30, 200, 1, INT)
	Slider(p, 1, "Flash strength", "strobeAlpha", 0, 1, 0.01)

	Header(p, 2, "Hue remap cycle")
	Check(p, 2, "Cycling hue remap", "tripRemap", "Animates the game's own color filter, cycling between its palettes. This truly moves hues around.")
	Slider(p, 2, "Cycle speed", "remapSpeed", 0.01, 2, 0.01, HZ)

	Header(p, 2, "Gamma pulse")
	Check(p, 2, "Breathing brightness", "tripGamma", "The picture slowly brightens and darkens.")
	Slider(p, 2, "Pulse amount", "gPulse", 0, 0.8, 0.01)
	Slider(p, 2, "Pulse speed", "gSpeed", 0.01, 2, 0.01, HZ)

	Header(p, 2, "Camera sway")
	Check(p, 2, "Swaying camera", "tripSway", "The camera drifts side to side. Can cause motion sickness.")
	Slider(p, 2, "Sway amount", "swayAmt", 0, 3, 0.01, SPEED2)
	Slider(p, 2, "Sway speed", "swaySpeed", 0.01, 1, 0.01, HZ)

	Header(p, 2, "FOV breathing")
	Check(p, 2, "Breathing field of view", "tripFov", "The view zooms gently in and out. Can cause motion sickness.")
	Slider(p, 2, "Zoom amount", "fovAmt", 1, 20, 1, { m = 1, d = 0, u = "\194\176" })
	Slider(p, 2, "Zoom speed", "fovSpeed", 0.01, 1, 0.01, HZ)
end

local function BuildQuality(p)
	Header(p, 1, "High-end graphics")
	Slider(p, 1, "Render scale", "rPixel", 0.1, 2, 0.01, PIXEL, "Above 100% supersamples the world for extra-sharp edges. Heavy on the GPU.")
	Slider(p, 1, "Sun shafts", "qSunshafts", -1, 2, 1, LEAVE)
	Slider(p, 1, "Particle density", "qParticles", -1, 5, 1, LEAVE)
	Slider(p, 1, "Spell density", "qSpell", -1, 5, 1, LEAVE)
	Slider(p, 1, "Ground clutter", "qClutter", -1, 10, 1, LEAVE, "Grass and small plants.")
	Slider(p, 1, "Environment detail", "qEnv", -1, 10, 1, LEAVE)
	Slider(p, 1, "Liquid detail", "qLiquid", -1, 3, 1, LEAVE)
	Slider(p, 1, "Depth effects", "qDepth", -1, 3, 1, LEAVE)
	Slider(p, 1, "Projected textures", "qProjected", -1, 1, 1, LEAVE)
	Slider(p, 1, "Weather density", "qWeather", -1, 3, 1, LEAVE, "How heavy the game's own rain and snow look.")
	Slider(p, 1, "Outlines", "qOutline", -1, 2, 1, LEAVE, "Glowing outlines around targets and interactables. 0 off, 1 outline, 2 high.")

	Header(p, 2, "Camera")
	Slider(p, 2, "Max zoom-out", "cZoom", 0.9, 2.6, 0.1, ZOOM, "How far the camera can pull back. 2.6x is the game's limit.")
	Slider(p, 2, "Field of view", "cFov", 49, 90, 1, FOV, "Wider FOV feels more cinematic.")

	Header(p, 2, "Cinematic camera")
	Check(p, 2, "Action camera", "cAction", "Uses the game's hidden ActionCam settings. Turning it off puts your camera back.")
	Slider(p, 2, "Over-the-shoulder", "cShoulder", -2, 2, 0.01, SIGNED, "Moves the camera sideways. Negative is over the left shoulder.")
	Check(p, 2, "Dynamic pitch", "cPitch", "Tilts the camera to show more of the world ahead.")
	Slider(p, 2, "Head movement", "cBob", 0, 2, 0.01, SPEED2, "Camera follows your character's head as they move.")
	Note(p, 2, "Any setting your game version doesn't have is skipped. Everything here is put back when you turn it off, toggle effects off, or log out.")
end

---------------------------------------------------------------------------
-- panel (built once for the window, once for the Settings menu)
---------------------------------------------------------------------------
local function flatButton(parent, w, h, sel)
	sel = sel or ACCENT
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w, h)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	b.bg:SetColorTexture(1, 1, 1, 0.05)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.08)
	b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	b.text:SetPoint("LEFT", 8, 0)
	b.text:SetPoint("RIGHT", -6, 0)
	b.text:SetJustifyH("LEFT")
	b.SetSelected = function(self, on)
		if on then
			self.bg:SetColorTexture(sel[1], sel[2], sel[3], 0.35)
		else
			self.bg:SetColorTexture(1, 1, 1, 0.05)
		end
	end
	return b
end

local function headerCheck(root, label, tip, onClick)
	local c = CreateFrame("CheckButton", nil, root, "UICheckButtonTemplate")
	c:SetSize(24, 24)
	local t = c:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	t:SetPoint("LEFT", c, "RIGHT", 2, 0)
	t:SetText(label)
	c:SetScript("OnClick", onClick)
	addTip(c, label, tip)
	return c
end

function Options:CreatePanel(root, withClose)
	local P = { root = root, syncs = {} }
	table.insert(self.panels, P)

	local icon = root:CreateTexture(nil, "ARTWORK")
	icon:SetSize(26, 26)
	icon:SetPoint("TOPLEFT", 12, -9)
	icon:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Textures\\icon")
	local title = root:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
	title:SetText("|cffffb347Retro|r|cff7fd4ffVision|r")
	local sub = root:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	sub:SetPoint("LEFT", title, "RIGHT", 10, -1)
	sub:SetText("retro screen filters")

	if withClose then
		local close = CreateFrame("Button", nil, root, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", 2, 2)
	end

	P.enabledCheck = headerCheck(root, "Effects on",
		"Master switch. Turning it off also restores your graphics settings.",
		function(self) RV.db.enabled = self:GetChecked() and true or false; RV:Refresh(true); Options:Sync(true) end)
	P.enabledCheck:SetPoint("TOPRIGHT", -300, -10)
	P.coverCheck = headerCheck(root, "Cover interface",
		"Off: effects only touch the 3D world, so action bars and text stay clean.\nOn: the whole screen, UI included, gets the effect.",
		function(self) RV.db.coverUI = self:GetChecked() and true or false; RV:Refresh(true) end)
	P.coverCheck:SetPoint("LEFT", P.enabledCheck, "RIGHT", 90, 0)

	-- preset list
	local lbl = root:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	lbl:SetPoint("TOPLEFT", 16, -48)
	lbl:SetText("Presets")
	lbl:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

	-- scrolling list of built-in presets with section headers
	-- preset strength
	local box = CreateFrame("Frame", nil, root)
	box:SetPoint("TOPLEFT", 12, -64)
	box:SetSize(LEFT_W - 16, 40)
	box.y = { 0, 0 }
	box.panel = P
	local ps = Slider(box, 1, "Preset strength", "presetStrength", 0, 2, 0.01, nil,
		"Turns the active preset's key ingredients up or down: its color strength, overlays, particles, contrast and so on. 100% is the preset as designed.",
		function(v) ns.ScalePreset(v); Options:Sync() end)
	ps:SetWidth(LEFT_W - 16)

	P.listOffset = 0
	P.listButtons = {}
	local listTop = -110
	for i = 1, LIST_ROWS do
		local b = flatButton(root, LEFT_W - 30, 21)
		b:SetPoint("TOPLEFT", 14, listTop - (i - 1) * 22)
		b:SetScript("OnClick", function(self) if self.preset then RV:ApplyPreset(self.preset) end end)
		b:SetScript("OnEnter", function(self)
			if not self.preset then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.preset.name, 1, 1, 1)
			GameTooltip:AddLine(self.preset.desc, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		b:EnableMouseWheel(true)
		b:SetScript("OnMouseWheel", function(_, d) Options:ScrollList(P, -d * 3) end)
		P.listButtons[i] = b
	end
	local function arrow(tex, dy, dir)
		local b = CreateFrame("Button", nil, root)
		b:SetSize(16, 16)
		b:SetNormalTexture(tex .. "-Up")
		b:SetPushedTexture(tex .. "-Down")
		b:SetHighlightTexture(tex .. "-Up", "ADD")
		b:SetPoint("TOPLEFT", LEFT_W - 14, dy)
		b:SetScript("OnClick", function() Options:ScrollList(P, dir * 5) end)
		return b
	end
	arrow("Interface\\Buttons\\Arrow-Up", listTop - 2, -1)
	arrow("Interface\\Buttons\\Arrow-Down", listTop - (LIST_ROWS - 1) * 22, 1)
	local track = root:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(1, 1, 1, 0.06)
	track:SetPoint("TOPLEFT", LEFT_W - 9, listTop - 20)
	track:SetSize(6, (LIST_ROWS - 2) * 22 - 4)
	P.listThumb = root:CreateTexture(nil, "ARTWORK")
	P.listThumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.6)
	P.listThumb:SetWidth(6)
	P.listTrack = track
	local y = listTop - LIST_ROWS * 22

	local clbl = root:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	clbl:SetPoint("TOPLEFT", 16, y - 8)
	clbl:SetText("Your presets")
	clbl:SetTextColor(0.5, 0.83, 1)
	local save = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
	save:SetSize(62, 20)
	save:SetPoint("TOPLEFT", LEFT_W - 64, y - 6)
	save:SetText("Save...")
	save:SetScript("OnClick", function() StaticPopup_Show("RETROVISION_SAVE") end)
	addTip(save, "Save current settings", "Saves everything as a named preset. Using an existing name overwrites it.")

	P.customButtons = {}
	for i = 1, 5 do
		local b = flatButton(root, LEFT_W - 16, 20)
		b:SetPoint("TOPLEFT", 14, y - 30 - (i - 1) * 22)
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetScript("OnClick", function(self, button)
			if not self.preset then return end
			if button == "RightButton" then
				ns.DeleteCustom(self.preset.name)
				RV:Print("deleted preset " .. self.preset.name)
				Options:Sync()
			else
				RV:ApplyPreset(self.preset)
			end
		end)
		addTip(b, "Your preset", "Left-click to load. Right-click to delete.")
		b:Hide()
		P.customButtons[i] = b
	end

	local div = root:CreateTexture(nil, "ARTWORK")
	div:SetColorTexture(1, 1, 1, 0.08)
	div:SetPoint("TOPLEFT", LEFT_W + 8, -44)
	div:SetPoint("BOTTOMLEFT", LEFT_W + 8, 30)
	div:SetWidth(1)

	-- tabs + pages
	local tabs = {
		{ "Screen", BuildScreen }, { "Color", BuildColor }, { "Motion", BuildMotion }, { "Graphics", BuildRender },
		{ "Light", BuildLight }, { "Magic", BuildMagic }, { "Particles", BuildParticles }, { "Quality", BuildQuality },
		{ "Filter", BuildFilter }, { "Trippy", BuildTrippy }, { "Style", BuildStyle },
	}
	local rowCount = { 4, 4, 3 }
	local rowColor = { ACCENT, ACCENT2, ACCENT3 }
	local rowW = CW - PAGE_X - 12
	P.pages, P.tabs = {}, {}
	for i, t in ipairs(tabs) do
		local page = CreateFrame("Frame", nil, root)
		page:SetPoint("TOPLEFT", root, "TOPLEFT", PAGE_X, -128)
		page:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -12, 30)
		page.y = { 0, 0 }
		page.panel = P
		page:Hide()
		t[2](page)
		P.pages[i] = page
		local row = i <= 4 and 0 or (i <= 8 and 1 or 2)
		local c = i - 1 - row * 4
		local n = rowCount[row + 1]
		local tw = math.floor((rowW - 5 * (n - 1)) / n)
		local col = rowColor[row + 1]
		local b = flatButton(root, tw, 22, col)
		b:SetPoint("TOPLEFT", PAGE_X + c * (tw + 5), -44 - row * 26)
		b.text:SetText(t[1])
		b.text:SetJustifyH("CENTER")
		if row > 0 then b.text:SetTextColor(col[1], col[2], col[3]) end
		b:SetScript("OnClick", function() Options.lastTab = i; Options:ShowTab(P, i) end)
		addTip(b, t[1], ({ "Retro effects", "Pretty effects", "Color filters and stylized effects" })[row + 1])
		P.tabs[i] = b
	end

	P.status = root:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	P.status:SetPoint("BOTTOMLEFT", 16, 10)
	local hint = root:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("BOTTOMRIGHT", -14, 10)
	hint:SetText("Click any number to type a value  ·  scroll the preset list  ·  /retro help")

	self:ShowTab(P, self.lastTab or 1)
	return P
end

function Options:RefreshList(P)
	local items = ns.PRESETS
	local maxOff = math.max(0, #items - LIST_ROWS)
	P.listOffset = math.max(0, math.min(maxOff, P.listOffset))
	for i, b in ipairs(P.listButtons) do
		local it = items[i + P.listOffset]
		b.preset = nil
		if not it then
			b:Hide()
		elseif it.header then
			b:Show()
			local hc = ({ Retro = "ffb347", Pretty = "7fd4ff", Stylized = "ff6ad5", Trippy = "b6ff5c", Filters = "ffe066" })[it.header] or "ffffff"
			b.text:SetText("|cff" .. hc .. "-- " .. it.header .. " --|r")
			b.text:SetJustifyH("CENTER")
			b.bg:SetColorTexture(0, 0, 0, 0)
		else
			b:Show()
			b.preset = it
			b.text:SetText(it.name)
			b.text:SetJustifyH("LEFT")
			b:SetSelected(it.name == RV.db.preset)
		end
	end
	local trackH = (LIST_ROWS - 2) * 22 - 4
	local frac = LIST_ROWS / math.max(LIST_ROWS, #items)
	local h = math.max(12, trackH * frac)
	local pos = maxOff > 0 and (P.listOffset / maxOff) * (trackH - h) or 0
	P.listThumb:ClearAllPoints()
	P.listThumb:SetPoint("TOPLEFT", P.listTrack, "TOPLEFT", 0, -pos)
	P.listThumb:SetHeight(h)
end

function Options:ScrollList(P, delta)
	P.listOffset = P.listOffset + delta
	self:RefreshList(P)
end

function Options:ShowTab(P, i)
	for j, page in ipairs(P.pages) do
		page:SetShown(i == j)
		P.tabs[j]:SetSelected(i == j)
	end
end

StaticPopupDialogs["RETROVISION_SAVE"] = {
	text = "Name for your RetroVision preset:",
	button1 = SAVE or "Save",
	button2 = CANCEL or "Cancel",
	hasEditBox = true,
	maxLetters = 32,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(self)
		local eb = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
		local name = eb and strtrim(eb:GetText() or "")
		if name and name ~= "" then
			ns.SaveCustom(name)
			Options:Sync()
			RV:Print("saved preset |cffffffff" .. name .. "|r")
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		StaticPopupDialogs.RETROVISION_SAVE.OnAccept(parent)
		parent:Hide()
	end,
}

---------------------------------------------------------------------------
-- syncing
---------------------------------------------------------------------------
local function syncPanel(P, statusOnly)
	if not statusOnly then
		syncing = true
		for _, f in ipairs(P.syncs) do f() end
		syncing = false
	end
	P.enabledCheck:SetChecked(RV.db.enabled)
	P.coverCheck:SetChecked(RV.db.coverUI)

	local list = RV.db.custom
	for i, b in ipairs(P.customButtons) do
		local p = list[i]
		b.preset = p
		if p then b.text:SetText(p.name); b:Show() else b:Hide() end
	end

	local txt = "Preset: |cffffffff" .. (RV.db.preset or "?") .. "|r"
	if RV.db.modified then txt = txt .. "  (edited)" end
	if not RV.db.enabled then txt = txt .. "  |cffff5555- effects off|r" end
	P.status:SetText(txt)
	Options:RefreshList(P)
	for _, b in ipairs(P.customButtons) do b:SetSelected(b.preset ~= nil and b.preset.name == RV.db.preset) end
end

-- fromWidget: a control changed one value. Other panels still need a full refresh,
-- but the changed control is already showing the right thing.
function Options:Sync(fromWidget)
	for _, P in ipairs(self.panels) do
		if P.root:IsVisible() or not fromWidget then
			syncPanel(P, false)
		else
			P.dirty = true
		end
	end
end

-- kept for older callers
function Options:UpdateStatus() self:Sync(true) end
function Options:RebuildCustom() self:Sync() end

---------------------------------------------------------------------------
-- floating window (/retro)
---------------------------------------------------------------------------
function Options:BuildWindow()
	if self.frame then return end
	local f = CreateFrame("Frame", "RetroVisionOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	self.frame = f
	f:SetSize(CW, CH)
	f:SetPoint("CENTER")
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	if f.SetBackdrop then
		f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		f:SetBackdropColor(0.055, 0.045, 0.07, 0.97)
		f:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.5)
	end
	tinsert(UISpecialFrames, "RetroVisionOptions")
	f:Hide()
	self.windowPanel = self:CreatePanel(f, true)
end

function Options:Toggle()
	self:BuildWindow()
	if self.frame:IsShown() then
		self.frame:Hide()
	else
		syncPanel(self.windowPanel)
		self.frame:Show()
	end
end

---------------------------------------------------------------------------
-- the game's Settings menu (Esc > Options > AddOns > RetroVision)
---------------------------------------------------------------------------
function Options:RegisterSettingsCategory()
	if self.canvas then return end
	local canvas = CreateFrame("Frame")
	canvas.name = "RetroVision"
	canvas:Hide()
	self.canvas = canvas

	local content = CreateFrame("Frame", nil, canvas)
	content:SetSize(CW, CH)
	content:SetPoint("TOPLEFT")

	-- shrink the whole panel if the Settings window is narrower than it
	local function fit()
		local w, h = canvas:GetWidth(), canvas:GetHeight()
		if not w or w <= 0 or not h or h <= 0 then return end
		content:SetScale(math.min(1, w / CW, h / CH))
	end
	canvas:SetScript("OnSizeChanged", fit)
	canvas:SetScript("OnShow", function()
		if not self.settingsPanel then self.settingsPanel = self:CreatePanel(content, false) end
		fit()
		syncPanel(self.settingsPanel)
	end)

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local cat = Settings.RegisterCanvasLayoutCategory(canvas, "RetroVision")
		Settings.RegisterAddOnCategory(cat)
		self.category = cat
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(canvas)
	end
end

function Options:OpenSettingsMenu()
	if self.category and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(self.category.GetID and self.category:GetID() or self.category.ID)
	elseif InterfaceOptionsFrame_OpenToCategory and self.canvas then
		InterfaceOptionsFrame_OpenToCategory(self.canvas)
	else
		self:Toggle()
	end
end
