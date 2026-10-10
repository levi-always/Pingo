--[[
    Pingo UI Library | v2.0.0 Ultimate Edition
    ------------------------------------------------------------------
    A top-tier, highly customized Luau UI framework built for performance,
    smooth animations, interactive glassmorphism, responsive font-scaling,
    and extensive configuration features.

    Features:
      - 32+ Built-in themes + Custom Theme Engine (Runtime RGBA customization)
      - Smart Label / Dynamic Text Auto-Scaling (prevents clipping for long names)
      - Integrated Keybind system with custom binding and Quick-toggle modes
      - Custom Free-Form RGB & HSV Color Picker element with live preview
      - Responsive SideTabs (Top Level) & Nested Tabs (Child Level)
      - Hold-to-Favorite / Unfavorite system with star indicators & auto-sorting
      - Unique, Glassmorphic Notification system with custom icons, actions, and progress bars
      - Advanced Blur Effect for full UI depth of field (Toggleable in Settings)
      - Dynamic Floating Buttons / Sliders / ColorPickers
      - Built-in Profile & Config Engine (Storage & Auto-Load)
      - Code Viewer, Stepper, Dropdowns, Steppers, Info Pages, and Custom Modals
--]]

local Pingo = {
	Version = "2.0.0",
	Name = "Pingo Ultimate",
	TintIcons = true,
	ActiveInstance = nil,
}

-- Services
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

-- Easing Shortcuts
local Q = Enum.EasingStyle.Quint
local BACK = Enum.EasingStyle.Back
local QUAD = Enum.EasingStyle.Quad
local SINE = Enum.EasingStyle.Sine
local IN = Enum.EasingDirection.In
local OUT = Enum.EasingDirection.Out
local INOUT = Enum.EasingDirection.InOut

local GAP = 6
local CELL_H = 68
local HOLD_TIME = 0.75

local ICON = {
	Star = 5078542968,
	Themes = 88003022051687,
	Config = 137882818389597,
	Settings = 9405931578,
	Minus = 12338394619,
	Plus = 12338396009,
	Search = 6031154871,
	Copy = 103287906385313,
	Keybind = 10734920149,
	ColorPicker = 10734924219,
	Check = 10734922324,
	Eye = 10734898110,
	Palette = 10734895856,
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function tw(obj, t, props, style, dir)
	if not obj then return end
	local tween = TweenService:Create(obj, TweenInfo.new(t or 0.22, style or QUAD, dir or OUT), props)
	tween:Play()
	return tween
end

local function new(class, props, children)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end

local function corner(r)
	return new("UICorner", {CornerRadius = UDim.new(0, r)})
end

local function icon(i)
	if not i then return nil end
	if type(i) == "number" or tostring(i):match("^%d+$") then return "rbxassetid://" .. tostring(i) end
	return tostring(i)
end

local function merge(o, extra)
	if type(extra) == "table" then
		for k, v in pairs(extra) do
			if o[k] == nil then o[k] = v end
		end
	end
	return o
end

local function sanitize(n)
	n = tostring(n or ""):gsub("[^%w%s%-_%.]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return string.sub(n, 1, 32)
end

-- Smart auto-scaling for element labels & descriptions
local function autoFitText(label, maxWidth, minSize, maxSize)
	minSize = minSize or 9
	maxSize = maxSize or 14
	local text = label.Text
	local font = label.Font
	if not text or text == "" then return end
	
	for size = maxSize, minSize, -1 do
		local textSize = TextService:GetTextSize(text, size, font, Vector2.new(maxWidth, 200))
		if textSize.X <= maxWidth then
			label.TextSize = size
			return
		end
	end
	label.TextSize = minSize
	label.TextTruncate = Enum.TextTruncate.AtEnd
end

-- Color Conversions
local function rgbToHsv(col)
	return Color3.toHSV(col)
end

local function hsvToRgb(h, s, v)
	return Color3.fromHSV(h, s, v)
end

-- ============================================================
-- THEMES ENGINE & PRESETS
-- ============================================================
local BASE = {
	Background = rgb(16, 17, 22), Sidebar = rgb(22, 23, 30), Card = rgb(28, 30, 38),
	Off = rgb(50, 53, 65), Text = rgb(242, 242, 248), SubText = rgb(135, 140, 155),
	White = rgb(255, 255, 255), Stroke = rgb(40, 42, 54), Glass = rgb(255, 255, 255)
}

local THEME_LIST = {
	{"Ruby", rgb(255, 59, 83), rgb(255, 110, 80)},
	{"Crimson", rgb(220, 40, 60), rgb(255, 70, 110)},
	{"Rose", rgb(255, 100, 140), rgb(255, 150, 170)},
	{"Magenta", rgb(255, 70, 180), rgb(255, 95, 110)},
	{"Coral", rgb(255, 110, 100), rgb(255, 160, 120)},
	{"Tangerine", rgb(255, 130, 37), rgb(255, 190, 60)},
	{"Amber", rgb(255, 176, 0), rgb(255, 215, 80)},
	{"Gold", rgb(255, 200, 40), rgb(255, 235, 120)},
	{"Lime", rgb(110, 255, 70), rgb(50, 230, 140)},
	{"Mint", rgb(120, 255, 190), rgb(90, 230, 230)},
	{"Emerald", rgb(46, 220, 130), rgb(30, 200, 200)},
	{"Teal", rgb(20, 200, 180), rgb(40, 150, 230)},
	{"Aurora", rgb(110, 255, 190), rgb(150, 110, 255)},
	{"Cyan", rgb(40, 230, 255), rgb(60, 150, 255)},
	{"Sky", rgb(120, 200, 255), rgb(170, 150, 255)},
	{"Azure", rgb(60, 130, 255), rgb(90, 210, 255)},
	{"Ocean", rgb(0, 190, 210), rgb(40, 110, 255)},
	{"Sapphire", rgb(40, 90, 255), rgb(100, 60, 230)},
	{"Indigo", rgb(90, 80, 255), rgb(160, 90, 255)},
	{"Violet", rgb(190, 80, 255), rgb(255, 90, 200)},
	{"Orchid", rgb(165, 130, 230), rgb(120, 140, 255)},
	{"Grape", rgb(160, 90, 255), rgb(225, 90, 255)},
	{"Lavender", rgb(190, 160, 255), rgb(255, 170, 220)},
	{"Neon", rgb(0, 235, 255), rgb(220, 70, 220)},
	{"Sunset", rgb(255, 115, 90), rgb(255, 160, 20)},
	{"Candy", rgb(255, 120, 200), rgb(120, 200, 255)},
	{"Ice", rgb(200, 240, 255), rgb(130, 190, 255)},
	{"Mono", rgb(200, 200, 205), rgb(120, 122, 130)},
}

local BLACK = Color3.new(0, 0, 0)
local THEMES = {}

local function generateThemeData(acc1, acc2)
	local d = {
		Accent = acc1,
		Accent2 = acc2,
		AccentDark = acc1:Lerp(BLACK, 0.35),
		Accent2Dark = acc2:Lerp(BLACK, 0.35)
	}
	for k, v in pairs(BASE) do d[k] = v end
	return d
end

for _, t in ipairs(THEME_LIST) do
	THEMES[t[1]] = generateThemeData(t[2], t[3])
end
THEMES["Custom"] = generateThemeData(rgb(140, 80, 255), rgb(255, 90, 180))

local currentTheme = "Ruby"
local function T(key) return THEMES[currentTheme][key] or BASE[key] end

local bindings = setmetatable({}, {__mode = "k"})
local gradients = setmetatable({}, {__mode = "k"})
local themeListeners = {}

local function bind(obj, prop, key, animate)
	if not obj then return end
	local b = bindings[obj]
	if not b then b = {}; bindings[obj] = b end
	b[prop] = key
	if animate then tw(obj, 0.28, {[prop] = T(key)}) else obj[prop] = T(key) end
end

local function unbindTree(root)
	if not root then return end
	bindings[root] = nil
	gradients[root] = nil
	for _, d in ipairs(root:GetDescendants()) do
		bindings[d] = nil
		gradients[d] = nil
	end
end

local function seq(keys)
	local pts, n = {}, #keys
	for i, k in ipairs(keys) do
		pts[i] = ColorSequenceKeypoint.new((i - 1) / math.max(n - 1, 1), T(k))
	end
	return ColorSequence.new(pts)
end

local function grad(keys, parent, props)
	local g = new("UIGradient", props or {})
	g.Parent = parent
	gradients[g] = keys
	g.Color = seq(keys)
	return g
end

function Pingo.SetTheme(name, customAcc1, customAcc2)
	if name == "Custom" and customAcc1 and customAcc2 then
		THEMES["Custom"] = generateThemeData(customAcc1, customAcc2)
	end
	if not THEMES[name] then return end
	currentTheme = name
	for obj, b in pairs(bindings) do
		if obj and obj.Parent then
			for prop, key in pairs(b) do
				local target = T(key)
				if obj[prop] ~= target then tw(obj, 0.3, {[prop] = target}) end
			end
		end
	end
	for g, keys in pairs(gradients) do
		if g and g.Parent then g.Color = seq(keys) end
	end
	for _, fn in pairs(themeListeners) do pcall(fn) end
end

function Pingo.GetThemeNames()
	local list = {}
	for _, t in ipairs(THEME_LIST) do table.insert(list, t[1]) end
	table.insert(list, "Custom")
	return list
end

local function mkText(class, props, key)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.BorderSizePixel = 0
	props.Font = props.Font or Enum.Font.GothamMedium
	local o = new(class, props)
	bind(o, "TextColor3", key or "Text")
	return o
end

local function candidates()
	local list = {}
	if gethui then pcall(function() table.insert(list, gethui()) end) end
	pcall(function() table.insert(list, game:GetService("CoreGui")) end)
	local lp = Players.LocalPlayer
	if lp then table.insert(list, lp:WaitForChild("PlayerGui")) end
	return list
end

-- Element Header Builder with Auto text sizing
local function header(body, o, rs, rp, regionH)
	regionH = regionH or CELL_H
	rs, rp = rs or 0, rp or 12
	local x = 14
	if o.Icon then
		local img = new("ImageLabel", {
			Name = "Icon", Image = icon(o.Icon), AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0, regionH / 2), Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1, ZIndex = 2, Parent = body
		})
		if o.IconColor then
			img.ImageColor3 = o.IconColor
		elseif o.Tint ~= false and Pingo.TintIcons then
			bind(img, "ImageColor3", "Accent")
		end
		x = 44
	end
	
	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local nameY = hasDesc and (regionH / 2 - 16) or 0
	local nameH = hasDesc and 16 or regionH
	local availableW = body.AbsoluteSize.X > 0 and (body.AbsoluteSize.X - x - rp - 10) or 180

	local nameLbl = mkText("TextLabel", {
		Text = tostring(o.Name), Font = Enum.Font.GothamBold, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		Position = UDim2.fromOffset(x, nameY), Size = UDim2.new(1 - rs, -(x + rp), 0, nameH), Parent = body,
	})
	
	task.defer(function()
		autoFitText(nameLbl, availableW, 9, 14)
	end)

	local descLbl
	if hasDesc then
		descLbl = mkText("TextLabel", {
			Text = tostring(o.Description), Font = Enum.Font.Gotham, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(x, nameY + 16), Size = UDim2.new(1 - rs, -(x + rp), 0, 14), Parent = body,
		}, "SubText")
	end
	return nameLbl, descLbl
end

-- Pill Button Helper
local function pill(parent, spec, props)
	spec = spec or {}
	props = props or {}
	local style = spec.Style or "Default"
	local b = new("TextButton", {
		Name = "Pill", Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = props.Size or UDim2.fromOffset(96, 32), Position = props.Position or UDim2.new(),
		Parent = parent,
	}, {corner(props.Radius or 8)})
	if props.AnchorPoint then b.AnchorPoint = props.AnchorPoint end
	
	if style == "Primary" then
		grad({"Accent", "Accent2"}, b, {Rotation = 15})
	elseif style == "Danger" then
		new("UIGradient", {Rotation = 15, Color = ColorSequence.new(rgb(225, 45, 70), rgb(255, 80, 105)), Parent = b})
	else
		bind(b, "BackgroundColor3", "Off")
		local st = new("UIStroke", {Thickness = 1, Transparency = 0.3, Parent = b})
		bind(st, "Color", "Stroke")
	end
	
	local ico, textX = icon(spec.Icon), 0
	if ico then
		new("ImageLabel", {
			Image = ico, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = b
		})
		textX = 12
	end
	
	local lbl = mkText("TextLabel", {
		Text = tostring(spec.Text or "Button"), Font = Enum.Font.GothamBold, TextSize = props.TextSize or 11,
		Position = UDim2.fromOffset(textX, 0), Size = UDim2.new(1, -textX, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = b
	}, style == "Default" and "Text" or "White")
	
	local sc = new("UIScale", {Parent = b})
	b.MouseEnter:Connect(function() tw(sc, 0.16, {Scale = 1.04}, BACK) end)
	b.MouseLeave:Connect(function() tw(sc, 0.2, {Scale = 1}) end)
	b.MouseButton1Down:Connect(function() tw(sc, 0.08, {Scale = 0.94}) end)
	b.MouseButton1Up:Connect(function() tw(sc, 0.2, {Scale = 1.04}, BACK) end)
	return b, lbl
end

-- ============================================================
-- MAIN WINDOW CREATION
-- ============================================================
function Pingo.CreateWindow(title, version, config)
	config = config or {}
	title = title or "Pingo UI"
	version = version or Pingo.Version
	local updateName = config.Update or "v2.0 Ultimate"
	
	-- Expanded dimensions
	local W, H = config.Width or 740, config.Height or 480
	if config.Theme and THEMES[config.Theme] then currentTheme = config.Theme end

	local win = {
		SideTabs = {}, Elements = {}, Registry = {}, TabRegistry = {}, UsedIds = {}, Conns = {}, Floats = {},
		Counter = 0, FavCounter = 0, FloatCount = 0,
		Opened = false, SearchText = "", SizeMul = 1, Locked = false, NotifyEnabled = true, ReduceMotion = false, BlurEnabled = true,
	}

	Pingo.ActiveInstance = win

	local function A(signal, fn)
		local c = signal:Connect(fn)
		table.insert(win.Conns, c)
		return c
	end

	-- Forward Declarations
	local selectTab, selectSideTab, layoutTabs, openMenu, closeMenu, openTabMenu, openElementMenu, openFloatMenu
	local createFloating, removeFloating, setElementFav, setElementHidden, setTabFav, setTabHidden
	local recountHidden, openDropdownPanel

	-- ScreenGui
	local guiName = "PingoUI_" .. title
	for _, p in ipairs(candidates()) do
		local old = p:FindFirstChild(guiName)
		if old then old:Destroy() end
	end
	local gui = new("ScreenGui", {Name = guiName, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	for _, p in ipairs(candidates()) do
		local ok = pcall(function() gui.Parent = p end)
		if ok and gui.Parent == p then break end
	end

	local function isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end
	local function guiPos(v) return v + GuiService:GetGuiInset() end

	-- Dragging utility
	local function makeDraggable(handle, target, onTap, canDrag)
		local dragging, moved, startMouse, startPos = false, false, nil, nil
		handle.InputBegan:Connect(function(input)
			if isPress(input) then
				dragging, moved = true, false
				startMouse, startPos = input.Position, target.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						if dragging and not moved and onTap then onTap() end
						dragging = false
					end
				end)
			end
		end)
		return A(UIS.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - startMouse
				if d.Magnitude > 6 then moved = true end
				if moved and (not canDrag or canDrag()) then
					target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end
		end)
	end
	local function menuCanDrag() return not win.Locked end

	-- Blur Effect setup
	local blurEffect = Lighting:FindFirstChild("PingoBlurEffect")
	if not blurEffect then
		blurEffect = new("BlurEffect", {Name = "PingoBlurEffect", Size = 0, Parent = Lighting})
	end

	local function setBlurState(enabled)
		if enabled and win.Opened then
			tw(blurEffect, 0.4, {Size = 18})
		else
			tw(blurEffect, 0.3, {Size = 0})
		end
	end

	-- Hold Manager
	local hold = {down = false, moved = false, token = 0, consumed = false}
	local function attachHold(obj, cb)
		obj.InputBegan:Connect(function(input)
			if not isPress(input) then return end
			hold.token = hold.token + 1
			local my = hold.token
			hold.down, hold.moved, hold.start = true, false, input.Position
			task.delay(HOLD_TIME, function()
				if hold.token == my and hold.down and not hold.moved then
					hold.down = false
					hold.consumed = true
					cb(guiPos(hold.start))
				end
			end)
		end)
	end
	A(UIS.InputChanged, function(input)
		if hold.down and hold.start and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if (input.Position - hold.start).Magnitude > 10 then hold.moved = true end
		end
	end)
	A(UIS.InputEnded, function(input)
		if isPress(input) then
			hold.down = false
			if hold.consumed then
				task.delay(0.25, function() hold.consumed = false end)
			end
		end
	end)

	-- Holder / Main Structure
	local Holder = new("Frame", {
		Name = "Holder", Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui
	})
	local fitScale = new("UIScale", {Parent = Holder})

	local function targetScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local fit = math.clamp(math.min((vp.X - 20) / W, (vp.Y - 20) / (H + 56)), 0.4, 1)
		return math.clamp(fit * win.SizeMul, 0.3, 1.8)
	end
	local function refit(animate)
		if animate then tw(fitScale, 0.3, {Scale = targetScale()}, Q) else fitScale.Scale = targetScale() end
	end
	refit(false)
	if workspace.CurrentCamera then
		A(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function() refit(false) end)
	end

	local Main = new("CanvasGroup", {
		Name = "Main", Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 0, GroupTransparency = 1, Parent = Holder
	}, {corner(14)})
	bind(Main, "BackgroundColor3", "Background")
	local openScale = new("UIScale", {Scale = 0.88, Parent = Main})
	local mainStroke = new("UIStroke", {Thickness = 1.5, Parent = Main})
	bind(mainStroke, "Color", "Stroke")

	-- Subtle Background Glow Auras
	local function aura(x, y, size, dx, dy, dur)
		local a = new("Frame", {
			Size = UDim2.fromOffset(size, size), Position = UDim2.fromScale(x, y), AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = Main
		}, {corner(size / 2)})
		bind(a, "BackgroundColor3", "Accent")
		TweenService:Create(a, TweenInfo.new(dur, SINE, INOUT, -1, true), {Position = UDim2.fromScale(x + dx, y + dy)}):Play()
	end
	aura(0.75, 0.3, 320, 0.1, 0.18, 8)
	aura(0.5, 0.8, 260, -0.12, -0.12, 10)

	-- Sidebar Setup
	local Sidebar = new("Frame", {Name = "Sidebar", Size = UDim2.new(0, 184, 1, 0), BorderSizePixel = 0, Parent = Main})
	bind(Sidebar, "BackgroundColor3", "Sidebar")
	local divider = new("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BorderSizePixel = 0, Parent = Sidebar})
	bind(divider, "BackgroundColor3", "Stroke")

	local dragArea = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Active = true, Parent = Sidebar})
	makeDraggable(dragArea, Holder, nil, menuCanDrag)

	local titleRow = new("Frame", {Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 30), BackgroundTransparency = 1, Parent = Sidebar}, {
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local titleLbl = mkText("TextLabel", {Text = title, Font = Enum.Font.GothamBold, TextSize = 22, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 30), LayoutOrder = 1, Parent = titleRow}, "Accent")
	local tg = grad({"Accent", "Accent2", "Accent"}, titleLbl, {Offset = Vector2.new(-0.6, 0)})
	TweenService:Create(tg, TweenInfo.new(2.6, SINE, INOUT, -1, true), {Offset = Vector2.new(0.6, 0)}):Play()
	mkText("TextLabel", {Text = version, Font = Enum.Font.Gotham, TextSize = 10, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 18), LayoutOrder = 2, Parent = titleRow}, "SubText")

	local navH = H - 62
	local SYS_TOP = navH - 3 * 42 - 8
	local Nav = new("Frame", {Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, -1, 1, -62), BackgroundTransparency = 1, Parent = Sidebar})
	local navLine = new("Frame", {Position = UDim2.fromOffset(16, SYS_TOP - 6), Size = UDim2.new(1, -33, 0, 1), BorderSizePixel = 0, Parent = Nav})
	bind(navLine, "BackgroundColor3", "Stroke")
	
	local Pill = new("Frame", {Name = "Pill", Position = UDim2.fromOffset(10, 2), Size = UDim2.new(1, -20, 0, 38), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, Parent = Nav}, {corner(9)})
	grad({"AccentDark", "Accent2Dark"}, Pill)
	local pillStroke = new("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Pill})
	bind(pillStroke, "Color", "Accent")

	local pillY, pillToken = nil, 0
	local function movePill(y)
		if not pillY then
			Pill.Position = UDim2.fromOffset(10, y)
			Pill.Visible = true
			pillY = y
			return
		end
		if pillY == y then return end
		pillToken = pillToken + 1
		local my = pillToken
		local from = pillY
		pillY = y
		local top, span = math.min(from, y), math.abs(y - from) + 38
		tw(Pill, 0.16, {Position = UDim2.fromOffset(10, top), Size = UDim2.new(1, -20, 0, span)}, QUAD)
		task.delay(0.12, function()
			if pillToken ~= my then return end
			tw(Pill, 0.36, {Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 38)}, Q)
		end)
	end

	-- Content Area Setup
	local Content = new("Frame", {Name = "Content", Position = UDim2.fromOffset(184, 0), Size = UDim2.new(1, -184, 1, 0), BackgroundTransparency = 1, Parent = Main})
	local dragTop = new("Frame", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Active = true, Parent = Content})
	makeDraggable(dragTop, Holder, nil, menuCanDrag)

	local topLine = new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 50, Parent = Main})
	local lg = grad({"Accent", "Accent2", "Accent"}, topLine, {Offset = Vector2.new(-1, 0)})
	TweenService:Create(lg, TweenInfo.new(3, Enum.EasingStyle.Linear, INOUT, -1, false), {Offset = Vector2.new(1, 0)}):Play()

	local SearchBar = new("Frame", {Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 38), BorderSizePixel = 0, Parent = Content}, {corner(8)})
	bind(SearchBar, "BackgroundColor3", "Sidebar")
	local searchStroke = new("UIStroke", {Thickness = 1, Parent = SearchBar})
	bind(searchStroke, "Color", "Stroke")
	local searchIcon = new("ImageLabel", {
		Image = icon(ICON.Search), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = SearchBar
	})
	bind(searchIcon, "ImageColor3", "SubText")
	local SearchBox = mkText("TextBox", {
		Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -48, 1, 0), Text = "", PlaceholderText = "Search features...",
		Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = SearchBar
	}, "Text")
	bind(SearchBox, "PlaceholderColor3", "SubText")
	SearchBox.Focused:Connect(function() bind(searchStroke, "Color", "Accent", true); tw(searchIcon, 0.2, {Size = UDim2.fromOffset(20, 20)}, BACK) end)
	SearchBox.FocusLost:Connect(function() bind(searchStroke, "Color", "Stroke", true); tw(searchIcon, 0.2, {Size = UDim2.fromOffset(18, 18)}) end)

	local TabBarHolder = new("Frame", {Position = UDim2.fromOffset(16, 60), Size = UDim2.new(1, -32, 0, 36), BackgroundTransparency = 1, Parent = Content})
	local PagesHolder = new("Frame", {Position = UDim2.fromOffset(16, 106), Size = UDim2.new(1, -32, 1, -118), BackgroundTransparency = 1, ClipsDescendants = true, Parent = Content})

	local SearchPage = new("ScrollingFrame", {
		Name = "SearchPage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, Parent = PagesHolder
	}, {
		new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}),
		new("UIGridLayout", {CellSize = UDim2.new(0.5, -8, 0, CELL_H), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	bind(SearchPage, "ScrollBarImageColor3", "SubText")

	-- SideTab / Tab Logic Helpers
	local function tabsOf(st)
		local l = {}
		for _, t in ipairs(st.Tabs) do l[#l + 1] = t end
		l[#l + 1] = st.HiddenTab
		return l
	end

	local function visibleList(st)
		local favs, norm = {}, {}
		for _, t in ipairs(st.Tabs) do
			if not t.Hidden then
				if t.Fav then table.insert(favs, t) else table.insert(norm, t) end
			end
		end
		table.sort(favs, function(a, b) return a.FavOrder > b.FavOrder end)
		local list = {}
		for _, t in ipairs(favs) do list[#list + 1] = t end
		for _, t in ipairs(norm) do list[#list + 1] = t end
		if st.HiddenCount > 0 then list[#list + 1] = st.HiddenTab end
		return list
	end

	local function firstVisibleTab(st)
		for _, t in ipairs(visibleList(st)) do
			if not t.Virtual then return t end
		end
	end

	local function playIn(tab)
		if win.ReduceMotion then return end
		for i, outer in ipairs(tab.Cards) do
			if i > 16 then break end
			local body = outer:FindFirstChild("Body")
			if body then
				body.Position = UDim2.new(0.5, 0, 0.5, 18)
				task.delay((i - 1) * 0.025, function()
					if body.Parent then tw(body, 0.45, {Position = UDim2.fromScale(0.5, 0.5)}, Q) end
				end)
			end
		end
	end

	local function showPage(tab, dx, dy)
		local g = tab.Group
		tab.HideToken = (tab.HideToken or 0) + 1
		g.ZIndex = 2
		g.Position = UDim2.fromOffset(dx * 46, dy * 30)
		g.GroupTransparency = 1
		g.Visible = true
		tw(g, 0.42, {Position = UDim2.new()}, Q)
		tw(g, 0.3, {GroupTransparency = 0})
		playIn(tab)
	end

	local function hidePage(tab, dx, dy)
		local g = tab.Group
		if not g.Visible then return end
		tab.HideToken = (tab.HideToken or 0) + 1
		local my = tab.HideToken
		g.ZIndex = 1
		tw(g, 0.2, {GroupTransparency = 1, Position = UDim2.fromOffset(-dx * 30, -dy * 20)}, QUAD, IN)
		task.delay(0.22, function()
			if tab.HideToken == my then g.Visible = false end
		end)
	end

	local function hideAllPages()
		for _, st in ipairs(win.SideTabs) do
			for _, t in ipairs(tabsOf(st)) do
				t.HideToken = (t.HideToken or 0) + 1
				t.Group.Visible = false
			end
		end
	end

	local function tabSpan(n, a, b)
		local lo, hi = math.min(a, b), math.max(a, b)
		local ls, lo_o = (lo - 1) / n, (lo - 1) * GAP / n
		local rs = (hi - 1) / n + 1 / n
		local ro = (hi - 1) * GAP / n - GAP * (n - 1) / n
		return UDim2.new(ls, lo_o, 0, 0), UDim2.new(rs - ls, ro - lo_o, 1, 0)
	end

	local function placePill(st, slot, animate)
		local n = st.SlotCount or 0
		if n == 0 then return end
		st.IndToken = (st.IndToken or 0) + 1
		local p, s = tabSpan(n, slot, slot)
		st.IndIdx = slot
		st.TabInd.Visible = true
		if animate then tw(st.TabInd, 0.35, {Position = p, Size = s}, Q) else st.TabInd.Position, st.TabInd.Size = p, s end
	end

	local function moveTabPill(st, slot)
		local n = st.SlotCount or 0
		if n == 0 then return end
		if not st.IndIdx then placePill(st, slot, false) return end
		if st.IndIdx == slot then return end
		st.IndToken = (st.IndToken or 0) + 1
		local my = st.IndToken
		local p1, s1 = tabSpan(n, st.IndIdx, slot)
		local p2, s2 = tabSpan(n, slot, slot)
		st.IndIdx = slot
		tw(st.TabInd, 0.14, {Position = p1, Size = s1}, QUAD)
		task.delay(0.1, function()
			if st.IndToken ~= my then return end
			tw(st.TabInd, 0.36, {Position = p2, Size = s2}, Q)
		end)
	end

	layoutTabs = function(st, animate)
		local list = visibleList(st)
		local n = #list
		st.SlotCount = n
		for _, t in ipairs(tabsOf(st)) do t.Slot = nil end
		for i, t in ipairs(list) do
			t.Slot = i
			local pos = UDim2.new((i - 1) / n, (i - 1) * GAP / n, 0, 0)
			local size = UDim2.new(1 / n, -GAP * (n - 1) / n, 1, 0)
			t.Button.Visible = true
			if animate and t.Placed then
				tw(t.Button, 0.35, {Position = pos, Size = size}, Q)
			else
				t.Button.Position, t.Button.Size = pos, size
			end
			t.Placed = true
		end
		for _, t in ipairs(tabsOf(st)) do
			if not t.Slot then t.Button.Visible = false; t.Placed = false end
		end
		if st.Display and st.Display.Slot then placePill(st, st.Display.Slot, animate) end
	end

	selectTab = function(tab)
		if win.SearchText ~= "" then SearchBox.Text = "" end
		local st = tab.SideTab
		local display = (tab.Hidden and st.HiddenTab) or tab
		local prev = win.CurrentTab
		if prev == tab and tab.Group.Visible then return end
		local dx, dy = 1, 0
		if prev then
			if prev.SideTab == st then
				local pd = (prev.Hidden and st.HiddenTab) or prev
				dx = ((display.Slot or 1) >= (pd.Slot or 1)) and 1 or -1
			else
				dx, dy = 0, ((st.Order >= prev.SideTab.Order) and 1 or -1)
			end
		end
		for _, o in ipairs(win.SideTabs) do
			for _, t in ipairs(tabsOf(o)) do
				if t ~= tab then
					if t == prev then
						hidePage(t, dx, dy)
					elseif t.Group.Visible then
						t.HideToken = (t.HideToken or 0) + 1
						t.Group.Visible = false
					end
				end
			end
		end
		for _, t in ipairs(tabsOf(st)) do
			bind(t.Button, "TextColor3", (t == display) and "Accent" or "SubText", true)
		end
		st.ActiveTab, st.Display = tab, display
		win.ActiveSideTab, win.CurrentTab = st, tab
		if display.Slot then moveTabPill(st, display.Slot) end
		showPage(tab, dx, dy)
	end

	selectSideTab = function(st)
		if win.SearchText ~= "" then SearchBox.Text = "" end
		local was = win.ActiveSideTab
		for _, o in ipairs(win.SideTabs) do
			local active = (o == st)
			o.Active = active
			bind(o.Label, "TextColor3", active and "White" or "Text", true)
			tw(o.Label, 0.28, {Position = UDim2.new(0, o.Pad + (active and 5 or 0), 0, 0)}, Q)
			if o.Icon then
				bind(o.Icon, "ImageColor3", active and "White" or "Text", true)
				if active and was ~= st then o.Icon.Rotation = -20; tw(o.Icon, 0.45, {Rotation = 0}, BACK) end
			end
			if not active then o.TabBar.Visible = false end
		end
		win.ActiveSideTab = st
		movePill(st.Y)
		if (st.SlotCount or 0) > 0 then
			local bar = st.TabBar
			bar.Visible = true
			if was ~= st then
				bar.GroupTransparency = 1
				bar.Position = UDim2.fromOffset(0, -10)
				tw(bar, 0.35, {Position = UDim2.new()}, Q)
				tw(bar, 0.28, {GroupTransparency = 0})
			end
		end
		local t = st.ActiveTab or firstVisibleTab(st)
		if t then selectTab(t) else hideAllPages() end
	end

	-- Search Execution
	local function homePage(rec)
		if rec.Hidden then return rec.Tab.SideTab.HiddenTab.Page end
		return rec.Tab.Page
	end

	local function performSearch(q)
		q = string.lower(q):gsub("^%s+", ""):gsub("%s+$", "")
		win.SearchText = q
		if q == "" then
			for _, rec in ipairs(win.Elements) do
				if rec.Outer.Parent == SearchPage then rec.Outer.Parent = homePage(rec) end
			end
			SearchPage.Visible = false
			TabBarHolder.Visible = true
			local ct = win.CurrentTab
			if ct and ct.SideTab == win.ActiveSideTab then
				local g = ct.Group
				g.Position = UDim2.new()
				g.GroupTransparency = 0
				g.ZIndex = 2
				g.Visible = true
			end
			return
		end
		hideAllPages()
		TabBarHolder.Visible = false
		SearchPage.Visible = true
		local shownCount = 0
		for _, rec in ipairs(win.Elements) do
			if string.find(rec.Search, q, 1, true) then
				if rec.Outer.Parent ~= SearchPage then
					rec.Outer.Parent = SearchPage
					shownCount = shownCount + 1
					local sc = rec.Body:FindFirstChild("Scale")
					if sc and shownCount <= 12 then
						sc.Scale = 0.88
						task.delay(shownCount * 0.025, function() tw(sc, 0.35, {Scale = 1}, BACK) end)
					end
				end
			elseif rec.Outer.Parent == SearchPage then
				rec.Outer.Parent = homePage(rec)
			end
		end
	end
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function() performSearch(SearchBox.Text) end)

	-- Card Factory
	local function newCard(name)
		win.Counter = win.Counter + 1
		local outer = new("Frame", {Name = tostring(name), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = win.Counter})
		local body = new("Frame", {Name = "Body", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = outer}, {corner(8)})
		bind(body, "BackgroundColor3", "Card")
		local st = new("UIStroke", {Name = "CardStroke", Thickness = 1, Transparency = 0.35, Parent = body})
		bind(st, "Color", "Stroke")
		new("UIScale", {Name = "Scale", Parent = body})
		new("Frame", {Name = "Shine", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = body}, {corner(8)})
		new("Frame", {Name = "Ripples", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = body}, {corner(8)})
		return body
	end

	local function hover(body, src)
		local shine, stroke = body.Shine, body.CardStroke
		src.MouseEnter:Connect(function()
			tw(shine, 0.15, {BackgroundTransparency = 0.94})
			tw(stroke, 0.2, {Color = T("Accent"), Transparency = 0.1})
			tw(body, 0.25, {Position = UDim2.new(0.5, 0, 0.5, -2)}, Q)
		end)
		src.MouseLeave:Connect(function()
			tw(shine, 0.2, {BackgroundTransparency = 1})
			tw(stroke, 0.25, {Color = T("Stroke"), Transparency = 0.35})
			tw(body, 0.3, {Position = UDim2.fromScale(0.5, 0.5)}, Q)
		end)
	end

	local function ripple(body, input)
		local holder = body:FindFirstChild("Ripples")
		if not holder then return end
		local ip = guiPos(input.Position)
		local ap, as = body.AbsolutePosition, body.AbsoluteSize
		local fx = math.clamp((ip.X - ap.X) / math.max(as.X, 1), 0, 1)
		local fy = math.clamp((ip.Y - ap.Y) / math.max(as.Y, 1), 0, 1)
		local r = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(fx, fy), Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = holder
		}, {corner(200)})
		tw(r, 0.55, {Size = UDim2.fromOffset(320, 320), BackgroundTransparency = 1}, Q)
		task.delay(0.6, function() r:Destroy() end)
	end

	local function hitButton(body)
		local hit = new("TextButton", {Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = body})
		hit.InputBegan:Connect(function(input) if isPress(input) then ripple(body, input) end end)
		return hit
	end

	local function holdZone(body, size, pos)
		return new("TextButton", {Name = "HoldZone", Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = body})
	end

	local function pressFx(body, hit)
		local sc = body.Scale
		hit.MouseButton1Down:Connect(function() tw(sc, 0.1, {Scale = 0.95}) end)
		hit.MouseButton1Up:Connect(function() tw(sc, 0.35, {Scale = 1}, BACK) end)
		hit.MouseLeave:Connect(function() tw(sc, 0.2, {Scale = 1}) end)
	end

	local function makeId(tab, name)
		local base = tab.SideTab.Name .. "/" .. tab.Name .. "/" .. name
		local id, n = base, 1
		while win.UsedIds[id] do
			n = n + 1
			id = base .. "#" .. n
		end
		win.UsedIds[id] = true
		return id
	end

	local function finish(tab, body, o, kind, obj, targets)
		local outer = body.Parent
		outer.Parent = tab.Page
		table.insert(tab.Cards, outer)
		local rec = {Name = tostring(o.Name), Kind = kind, Tab = tab, Body = body, Outer = outer, Obj = obj, Fav = false, Hidden = false, BaseOrder = outer.LayoutOrder}
		rec.Search = string.lower(rec.Name .. " " .. (o.Description or ""))
		if obj then obj.Rec = rec end
		if o.Searchable ~= false then table.insert(win.Elements, rec) end
		if not tab.System then
			rec.Id = makeId(tab, rec.Name)
			win.Registry[rec.Id] = rec
			table.insert(tab.Recs, rec)
			for _, tgt in ipairs(targets or {body}) do
				attachHold(tgt, function(pos) openElementMenu(rec, pos) end)
			end
		end
		return rec
	end

	-- Properties Context Menu
	local menuOpen
	closeMenu = function()
		local m = menuOpen
		if not m then return end
		menuOpen = nil
		tw(m.card, 0.15, {GroupTransparency = 1})
		tw(m.scale, 0.15, {Scale = 0.92})
		task.delay(0.18, function() unbindTree(m.root); m.root:Destroy() end)
	end

	openMenu = function(heading, subject, items, pos)
		closeMenu()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local MW, ROW = 220, 36
		local MH = 54 + #items * ROW + 8
		local root = new("TextButton", {Name = "PingoMenu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 40, Parent = gui})
		root.MouseButton1Click:Connect(function() closeMenu() end)
		local x, y = pos.X + 8, pos.Y + 8
		if x + MW > vp.X - 8 then x = pos.X - MW - 8 end
		if y + MH > vp.Y - 8 then y = pos.Y - MH - 8 end
		x, y = math.max(8, x), math.max(8, y)
		local card = new("CanvasGroup", {
			Position = UDim2.fromOffset(x, y + 10), Size = UDim2.fromOffset(MW, MH),
			BackgroundTransparency = 0, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 41, Active = true, Parent = root
		}, {corner(12)})
		bind(card, "BackgroundColor3", "Sidebar")
		local scale = new("UIScale", {Scale = 0.9, Parent = card})
		local cs = new("UIStroke", {Thickness = 1.5, Transparency = 0.35, Parent = card})
		bind(cs, "Color", "Accent")
		local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = card})
		grad({"Accent", "Accent2"}, bar)
		mkText("TextLabel", {Text = string.upper(heading), Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 11), Size = UDim2.new(1, -28, 0, 12), Parent = card}, "SubText")
		mkText("TextLabel", {Text = tostring(subject), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(14, 24), Size = UDim2.new(1, -28, 0, 20), Parent = card})
		local sep = new("Frame", {Position = UDim2.fromOffset(12, 49), Size = UDim2.new(1, -24, 0, 1), BorderSizePixel = 0, Parent = card})
		bind(sep, "BackgroundColor3", "Stroke")

		for i, it in ipairs(items) do
			local row = new("TextButton", {
				Position = UDim2.fromOffset(20, 54 + (i - 1) * ROW), Size = UDim2.new(1, -16, 0, ROW - 4),
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = card
			}, {corner(8)})
			local tx = 12
			if it.Icon then
				local im = new("ImageLabel", {Image = icon(it.Icon), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = row})
				bind(im, "ImageColor3", "Accent")
				tx = 34
			end
			local lbl = mkText("TextLabel", {Text = it.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -tx - 8, 1, 0), Parent = row}, "Text")
			if it.Style == "Danger" then lbl.TextColor3 = rgb(255, 95, 110); bindings[lbl] = nil end
			row.MouseEnter:Connect(function() tw(row, 0.15, {BackgroundTransparency = 0.92}) end)
			row.MouseLeave:Connect(function() tw(row, 0.2, {BackgroundTransparency = 1}) end)
			row.MouseButton1Click:Connect(function()
				closeMenu()
				if it.Callback then task.spawn(it.Callback) end
			end)
			row.Position = UDim2.fromOffset(34, 54 + (i - 1) * ROW)
			task.delay(0.04 + i * 0.03, function()
				if row.Parent then tw(row, 0.38, {Position = UDim2.fromOffset(8, 54 + (i - 1) * ROW)}, Q) end
			end)
		end

		menuOpen = {root = root, card = card, scale = scale}
		tw(card, 0.38, {Position = UDim2.fromOffset(x, y)}, Q)
		tw(card, 0.2, {GroupTransparency = 0})
		tw(scale, 0.38, {Scale = 1}, BACK)
	end

	-- Favourite & Hidden Handlers
	recountHidden = function(st, preferTab)
		local n = 0
		for _, t in ipairs(st.Tabs) do
			if t.Hidden then n = n + 1 end
			for _, r in ipairs(t.Recs) do
				if r.Hidden then n = n + 1 end
			end
		end
		st.HiddenCount = n
		layoutTabs(st, true)
		if n == 0 and win.CurrentTab == st.HiddenTab then
			local t = preferTab or firstVisibleTab(st)
			if t then selectTab(t) end
		end
	end

	setElementFav = function(rec, v)
		v = v == true
		if rec.Fav == v then return end
		rec.Fav = v
		if v then
			win.FavCounter = win.FavCounter + 1
			rec.FavOrder = win.FavCounter
			rec.Outer.LayoutOrder = -(10000 + win.FavCounter)
			if not rec.Star then
				rec.Star = new("ImageLabel", {
					Name = "Star", Image = icon(ICON.Star), AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, ZIndex = 5, Parent = rec.Body
				})
				bind(rec.Star, "ImageColor3", "Accent")
			end
			rec.Star.Visible = true
			tw(rec.Star, 0.4, {Size = UDim2.fromOffset(13, 13)}, BACK)
		else
			rec.Outer.LayoutOrder = rec.BaseOrder
			if rec.Star then
				tw(rec.Star, 0.2, {Size = UDim2.fromOffset(0, 0)})
				task.delay(0.22, function() if not rec.Fav and rec.Star then rec.Star.Visible = false end end)
			end
		end
	end

	setElementHidden = function(rec, v, instant)
		v = v == true
		if rec.Hidden == v then return end
		local st = rec.Tab.SideTab
		rec.Hidden = v
		if v and rec.Fav then setElementFav(rec, false) end
		local sc = rec.Body:FindFirstChild("Scale")
		local function move()
			if rec.Outer.Parent ~= SearchPage then
				rec.Outer.Parent = v and st.HiddenTab.Page or rec.Tab.Page
			end
			if sc then
				sc.Scale = 0.6
				tw(sc, 0.42, {Scale = 1}, BACK)
			end
			recountHidden(st)
		end
		if instant or not sc then move() else tw(sc, 0.22, {Scale = 0.6}, QUAD, IN); task.delay(0.24, move) end
	end

	setTabFav = function(tab, v)
		v = v == true
		if tab.Fav == v then return end
		tab.Fav = v
		if v then
			win.FavCounter = win.FavCounter + 1
			tab.FavOrder = win.FavCounter
		end
		tab.Star.Visible = v
		tab.Star.Size = UDim2.fromOffset(0, 0)
		if v then tw(tab.Star, 0.4, {Size = UDim2.fromOffset(13, 13)}, BACK) end
		layoutTabs(tab.SideTab, true)
	end

	local function makeHiddenTabCard(tab)
		local st = tab.SideTab
		local body = newCard(tab.Name)
		header(body, {Name = tab.Name, Description = "Hidden tab - tap to unhide"}, 0, 40)
		mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, -2), Size = UDim2.fromOffset(18, 24), Text = "›", Font = Enum.Font.GothamBold, TextSize = 24, Parent = body}, "SubText")
		local hit = hitButton(body)
		hover(body, hit)
		pressFx(body, hit)
		hit.MouseButton1Click:Connect(function()
			if hold.consumed then return end
			selectTab(tab)
		end)
		attachHold(hit, function(pos)
			openMenu("Properties", tab.Name, {{Text = "Unhide", Callback = function() setTabHidden(tab, false) end}}, pos)
		end)
		local outer = body.Parent
		outer.Parent = st.HiddenTab.Page
		table.insert(st.HiddenTab.Cards, outer)
		return outer
	end

	setTabHidden = function(tab, v)
		v = v == true
		if tab.Hidden == v then return end
		local st = tab.SideTab
		if v then
			if tab.Fav then tab.Fav = false; tab.Star.Visible = false end
			tab.Hidden = true
			tab.HCard = makeHiddenTabCard(tab)
			recountHidden(st)
			if win.CurrentTab == tab then selectTab(st.HiddenTab) end
		else
			tab.Hidden = false
			if tab.HCard then
				local i = table.find(st.HiddenTab.Cards, tab.HCard)
				if i then table.remove(st.HiddenTab.Cards, i) end
				unbindTree(tab.HCard)
				tab.HCard:Destroy()
				tab.HCard = nil
			end
			recountHidden(st, tab)
		end
	end

	local function resetTab(tab)
		for _, rec in ipairs(tab.Recs) do
			if rec.Obj and rec.Obj.Reset then pcall(function() rec.Obj:Reset() end) end
		end
		win:Notify("Reset Tab", tab.Name .. " reset to default values.", 2.5)
	end

	openTabMenu = function(tab, pos)
		openMenu("Properties", tab.Name, {
			{Text = tab.Fav and "Unfavourite" or "Favourite", Icon = ICON.Star, Callback = function() setTabFav(tab, not tab.Fav) end},
			{Text = "Hide", Callback = function() setTabHidden(tab, true) end},
			{Text = "Reset Tab", Callback = function() resetTab(tab) end},
		}, pos)
	end

	openElementMenu = function(rec, pos)
		local items = {}
		if rec.Hidden then
			items[1] = {Text = "Unhide", Callback = function() setElementHidden(rec, false) end}
		else
			local fname = (rec.Kind == "button" or rec.Kind == "toggle") and "Floating Button" or (rec.Kind == "slider" and "Floating Slider" or nil)
			if fname then
				if rec.Float then
					items[#items + 1] = {Text = "Remove " .. fname, Callback = function() removeFloating(rec) end}
				else
					items[#items + 1] = {Text = fname, Callback = function() createFloating(rec) end}
				end
			end
			items[#items + 1] = {Text = rec.Fav and "Unfavourite" or "Favourite", Icon = ICON.Star, Callback = function() setElementFav(rec, not rec.Fav) end}
			items[#items + 1] = {Text = "Hide", Callback = function() setElementHidden(rec, true) end}
			if not fname and rec.Obj and rec.Obj.Reset then
				items[#items + 1] = {Text = "Reset", Callback = function() rec.Obj:Reset() end}
			end
		end
		openMenu("Properties", rec.Name, items, pos)
	end

	-- Floating Widgets
	local FLOAT_SCALES = {0.85, 1, 1.25}
	openFloatMenu = function(fl, pos)
		openMenu("Floating", fl.Rec.Name, {
			{Text = fl.Locked and "Move" or "Lock", Callback = function()
				fl.Locked = not fl.Locked
				fl.LockDot.Visible = fl.Locked
			end},
			{Text = "Resize", Callback = function()
				fl.SizeIdx = fl.SizeIdx % 3 + 1
				tw(fl.Scale, 0.35, {Scale = FLOAT_SCALES[fl.SizeIdx]}, BACK)
			end},
			{Text = "Hide", Callback = function() removeFloating(fl.Rec) end},
		}, pos)
	end

	removeFloating = function(rec, instant)
		local fl = rec.Float
		if not fl then return end
		rec.Float = nil
		if rec.Id then win.Floats[rec.Id] = nil end
		fl.Destroy(not instant)
	end

	createFloating = function(rec, saved)
		if rec.Float then return rec.Float end
		local kind = rec.Kind
		if kind ~= "button" and kind ~= "toggle" and kind ~= "slider" then return end
		local obj = rec.Obj
		win.FloatCount = win.FloatCount + 1
		local fl = {Rec = rec, Locked = false, SizeIdx = 2, Conns = {}}
		if saved then
			fl.Locked = saved.locked == true
			fl.SizeIdx = math.clamp(tonumber(saved.size) or 2, 1, 3)
		end
		local isSlider = kind == "slider"
		local FW, FH = isSlider and 216 or 164, isSlider and 62 or 40
		local k = win.FloatCount % 6
		local pos = UDim2.new(0.5, k * 16, 0.2, k * 20)
		if saved and type(saved.pos) == "table" and #saved.pos == 4 then
			pos = UDim2.new(saved.pos[1], saved.pos[2], saved.pos[3], saved.pos[4])
		end

		local root = new("TextButton", {
			Name = "Float", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(FW, FH),
			Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = gui
		}, {corner(12)})
		bind(root, "BackgroundColor3", "Card")
		fl.Scale = new("UIScale", {Scale = 0, Parent = root})
		local fs = new("UIStroke", {Thickness = 1.5, Transparency = 0.2, Parent = root})
		bind(fs, "Color", "Accent")
		fl.LockDot = new("Frame", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -7, 0, 7), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = fl.Locked, ZIndex = 8, Parent = root
		}, {corner(3)})

		if not isSlider then
			local on = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = root}, {corner(12)})
			grad({"Accent", "Accent2"}, on, {Rotation = 15})
			local dot = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = rgb(110, 115, 130), BorderSizePixel = 0, ZIndex = 4, Parent = root}, {corner(6)})
			mkText("TextLabel", {Text = rec.Name, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -52, 1, 0), ZIndex = 4, Parent = root}, "White")
			local function paint(state, instant)
				local tr = state and 0 or 1
				local dc = state and Color3.new(1, 1, 1) or rgb(110, 115, 130)
				if instant then
					on.BackgroundTransparency, dot.BackgroundColor3 = tr, dc
				else
					tw(on, 0.25, {BackgroundTransparency = tr})
					tw(dot, 0.25, {BackgroundColor3 = dc})
				end
			end
			if kind == "toggle" then
				paint(obj:Get(), true)
				fl.Sync = function(state) paint(state, false) end
			else
				on.BackgroundTransparency = 0.1
				dot.BackgroundColor3 = Color3.new(1, 1, 1)
			end
		else
			local min, max, suffix = obj.Min or 0, obj.Max or 100, obj.Suffix or ""
			mkText("TextLabel", {Text = rec.Name, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -92, 0, 18), ZIndex = 4, Parent = root})
			local valLbl = mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.fromOffset(70, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Text = "", ZIndex = 4, Parent = root}, "Accent")
			local track = new("Frame", {Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -24, 0, 6), BorderSizePixel = 0, ZIndex = 4, Parent = root}, {corner(3)})
			bind(track, "BackgroundColor3", "Off")
			local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4, Parent = track}, {corner(3)})
			grad({"Accent", "Accent2"}, fill)
			local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5, Parent = track}, {corner(6)})
			local function refresh(instant)
				local v = obj:Get()
				local pct = (max - min) == 0 and 0 or (v - min) / (max - min)
				valLbl.Text = tostring(v) .. suffix
				if instant then
					fill.Size, knob.Position = UDim2.fromScale(pct, 1), UDim2.fromScale(pct, 0.5)
				else
					tw(fill, 0.12, {Size = UDim2.fromScale(pct, 1)})
					tw(knob, 0.12, {Position = UDim2.fromScale(pct, 0.5)})
				end
			end
			refresh(true)
			fl.Sync = function() refresh(false) end
			local trackHit = new("TextButton", {Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 6, Parent = root})
			local dragging = false
			local function fromX(x)
				local pct = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
				obj:Set(min + (max - min) * pct)
			end
			trackHit.InputBegan:Connect(function(input)
				if isPress(input) then dragging = true; fromX(input.Position.X) end
			end)
			table.insert(fl.Conns, A(UIS.InputChanged, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					fromX(input.Position.X)
				end
			end))
			table.insert(fl.Conns, A(UIS.InputEnded, function(input)
				if isPress(input) then dragging = false end
			end))
		end

		if fl.Sync then table.insert(obj.Listeners, fl.Sync) end

		local dragConn = makeDraggable(root, root, function()
			if hold.consumed then return end
			if kind == "toggle" then obj:Set(not obj:Get()) elseif kind == "button" then obj.Fire() end
		end, function() return not fl.Locked end)
		attachHold(root, function(p) openFloatMenu(fl, p) end)

		fl.Destroy = function(animated)
			pcall(function() dragConn:Disconnect() end)
			for _, c in ipairs(fl.Conns) do pcall(function() c:Disconnect() end) end
			if fl.Sync and obj.Listeners then
				for i, f in ipairs(obj.Listeners) do
					if f == fl.Sync then table.remove(obj.Listeners, i) break end
				end
			end
			if animated then
				tw(fl.Scale, 0.28, {Scale = 0}, BACK, IN)
				task.delay(0.3, function() unbindTree(root); root:Destroy() end)
			else
				unbindTree(root)
				root:Destroy()
			end
		end
		fl.Export = function()
			local p = root.Position
			return {pos = {p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset}, locked = fl.Locked, size = fl.SizeIdx}
		end

		rec.Float = fl
		if rec.Id then win.Floats[rec.Id] = fl end
		tw(fl.Scale, 0.45, {Scale = FLOAT_SCALES[fl.SizeIdx]}, BACK)
		return fl
	end

	-- Tab Builder (Nested Level)
	local function buildTab(st, name, opts)
		opts = opts or {}
		local tab = {Name = name, SideTab = st, Cards = {}, Recs = {}, System = opts.System == true, Virtual = opts.Virtual == true, Fav = false, Hidden = false, FavOrder = 0}

		local btn = new("TextButton", {Name = name, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, Visible = false, Parent = st.TabInner})
		bind(btn, "TextColor3", "SubText")
		tab.Button = btn
		tab.Star = new("ImageLabel", {Name = "Star", Image = icon(ICON.Star), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(13, 13), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = btn})
		bind(tab.Star, "ImageColor3", "Accent")

		local group = new("CanvasGroup", {Name = st.Name .. "_" .. name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Parent = PagesHolder})
		local layout
		if opts.Layout == "list" then
			layout = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
		else
			layout = new("UIGridLayout", {CellSize = opts.CellSize or UDim2.new(0.5, -8, 0, CELL_H), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder})
		end
		local page = new("ScrollingFrame", {
			Name = "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = group
		}, {
			new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}),
			layout,
		})
		bind(page, "ScrollBarImageColor3", "SubText")
		tab.Group, tab.Page = group, page

		btn.MouseButton1Click:Connect(function()
			if hold.consumed then return end
			selectTab(tab)
		end)
		btn.MouseEnter:Connect(function() if st.Display ~= tab then bind(btn, "TextColor3", "Text", true) end end)
		btn.MouseLeave:Connect(function() if st.Display ~= tab then bind(btn, "TextColor3", "SubText", true) end end)
		if not tab.System and not tab.Virtual then
			attachHold(btn, function(pos) openTabMenu(tab, pos) end)
		end
		return tab
	end

	local function createTab(st, name, opts)
		local tab = buildTab(st, name, opts)
		tab.Id = st.Name .. "/" .. name
		table.insert(st.Tabs, tab)
		if not tab.System then win.TabRegistry[tab.Id] = tab end
		layoutTabs(st, false)
		if win.ActiveSideTab == st then
			st.TabBar.GroupTransparency = 0
			st.TabBar.Visible = true
		end
		if win.ActiveSideTab == st and not st.ActiveTab then selectTab(tab) end

		-- ===== BUTTON ELEMENT =====
		function tab:AddButton(a, callback, extra)
			local o = type(a) == "table" and a or merge({Name = a, Callback = callback}, extra)
			local body = newCard(o.Name)
			header(body, o, 0, 14)
			local hit = hitButton(body)
			hover(body, hit)
			pressFx(body, hit)
			local function fire() if o.Callback then task.spawn(o.Callback) end end
			hit.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				fire()
			end)
			local obj = {Card = body, Fire = fire}
			finish(tab, body, o, "button", obj, {hit})
			return obj
		end

		-- ===== TOGGLE ELEMENT =====
		function tab:AddToggle(a, default, callback, extra)
			local o = type(a) == "table" and a or merge({Name = a, Default = default, Callback = callback}, extra)
			local default0 = o.Default == true
			local state = default0
			local fmt = o.Format
			local body = newCard(o.Name)
			local nameLbl = header(body, o, 0, 64)
			if fmt then nameLbl.Text = fmt(state, o.Name) end
			local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(40, 22), BorderSizePixel = 0, Parent = body}, {corner(11)})
			bind(sw, "BackgroundColor3", state and "Accent" or "Off")
			local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(16, 16), Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sw}, {corner(8)})
			local hit = hitButton(body)
			hover(body, hit)
			pressFx(body, hit)

			local obj = {Card = body, Listeners = {}}
			local function apply(v, fire)
				state = v
				bind(sw, "BackgroundColor3", state and "Accent" or "Off", true)
				if fmt then nameLbl.Text = fmt(state, o.Name) end
				tw(knob, 0.12, {Size = UDim2.fromOffset(24, 16)})
				task.delay(0.1, function()
					tw(knob, 0.35, {Size = UDim2.fromOffset(16, 16), Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, BACK)
				end)
				for _, f in ipairs(obj.Listeners) do pcall(f, state) end
				if fire and o.Callback then task.spawn(o.Callback, state) end
			end
			function obj:Set(v) if (v == true) ~= state then apply(v == true, true) end end
			function obj:Get() return state end
			function obj:Reset() obj:Set(default0) end
			function obj:SetText(t) nameLbl.Text = tostring(t) end
			hit.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				apply(not state, true)
			end)

			finish(tab, body, o, "toggle", obj, {hit})
			if state and o.Callback then task.spawn(o.Callback, true) end
			return obj
		end

		-- ===== SLIDER ELEMENT =====
		function tab:AddSlider(a, mn, mx, default, callback, increment, extra)
			local o = type(a) == "table" and a or merge({Name = a, Min = mn, Max = mx, Default = default, Callback = callback, Increment = increment}, extra)
			local min, max = o.Min or 0, o.Max or 100
			local inc = o.Increment or 1
			local suffix = o.Suffix or ""
			local default0 = o.Default or min
			local dec = 0
			local d = tostring(inc):match("%.(%d+)")
			if d then dec = #d end
			local function snap(v)
				v = math.floor((v - min) / inc + 0.5) * inc + min
				v = math.clamp(v, min, max)
				return tonumber(string.format("%." .. dec .. "f", v))
			end

			local hasDesc = o.Description ~= nil and o.Description ~= ""
			local body = newCard(o.Name)
			header(body, o, 0, 84, 44)
			local valLbl = mkText("TextLabel", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, hasDesc and 6 or 0),
				Size = UDim2.fromOffset(68, hasDesc and 16 or 44), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = "", Parent = body
			}, "Accent")
			local valScale = new("UIScale", {Parent = valLbl})
			local track = new("Frame", {Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 0, 6), BorderSizePixel = 0, Parent = body}, {corner(3)})
			bind(track, "BackgroundColor3", "Off")
			local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track}, {corner(3)})
			grad({"Accent", "Accent2"}, fill)
			local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = track}, {corner(6)})
			local knobStroke = new("UIStroke", {Thickness = 0, Transparency = 0.6, Parent = knob})
			bind(knobStroke, "Color", "Accent")

			local shown, targetPct, conn = 0, 0, nil
			local function render(p)
				fill.Size = UDim2.fromScale(p, 1)
				knob.Position = UDim2.fromScale(p, 0.5)
			end
			local function stopLoop() if conn then conn:Disconnect(); conn = nil end end
			local function startLoop()
				if conn then return end
				conn = RunService.RenderStepped:Connect(function(dt)
					if not fill.Parent then stopLoop() return end
					local diff = targetPct - shown
					if math.abs(diff) < 0.0008 then
						shown = targetPct
						render(shown)
						stopLoop()
						return
					end
					shown = shown + diff * (1 - math.exp(-dt * 26))
					render(shown)
				end)
			end

			local obj = {Card = body, Listeners = {}, Min = min, Max = max, Suffix = suffix}
			local value, lastPop = nil, 0
			local function apply(v, fire, instant)
				v = snap(v)
				local pct = (max - min) == 0 and 0 or (v - min) / (max - min)
				targetPct = pct
				valLbl.Text = tostring(v) .. suffix
				if instant then
					shown = pct
					render(pct)
					stopLoop()
				else
					startLoop()
				end
				if v ~= value then
					value = v
					for _, f in ipairs(obj.Listeners) do pcall(f, v) end
					if fire then
						local now = os.clock()
						if now - lastPop > 0.1 then
							lastPop = now
							valScale.Scale = 1.16
							tw(valScale, 0.25, {Scale = 1}, BACK)
						end
						if o.Callback then task.spawn(o.Callback, v) end
					end
				end
			end
			apply(default0, false, true)

			local hit = new("TextButton", {Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3, Parent = body})
			local zone = holdZone(body, UDim2.new(1, 0, 0, 34))
			hover(body, body)
			local dragging = false
			local function fromX(x)
				local pct = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
				apply(min + (max - min) * pct, true, false)
			end
			hit.InputBegan:Connect(function(input)
				if isPress(input) then
					dragging = true
					tab.Page.ScrollingEnabled = false
					tw(knob, 0.2, {Size = UDim2.fromOffset(18, 18)}, BACK)
					tw(knobStroke, 0.2, {Thickness = 5})
					fromX(input.Position.X)
				end
			end)
			A(UIS.InputChanged, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					fromX(input.Position.X)
				end
			end)
			A(UIS.InputEnded, function(input)
				if dragging and isPress(input) then
					dragging = false
					tab.Page.ScrollingEnabled = true
					tw(knob, 0.3, {Size = UDim2.fromOffset(12, 12)}, BACK)
					tw(knobStroke, 0.25, {Thickness = 0})
				end
			end)

			function obj:Set(v) apply(v, true, false) end
			function obj:Get() return value end
			function obj:Reset() apply(default0, true, false) end
			finish(tab, body, o, "slider", obj, {zone})
			return obj
		end

		-- ===== KEYBIND ELEMENT =====
		function tab:AddKeybind(a, defaultKey, callback, extra)
			local o = type(a) == "table" and a or merge({Name = a, Key = defaultKey, Callback = callback}, extra)
			local currentKey = o.Key or Enum.KeyCode.E
			local quickMode = o.Quick == true
			local bindingKey = false

			local body = newCard(o.Name)
			header(body, o, 0.44, 16)
			local zone = holdZone(body, UDim2.new(0.5, 0, 1, 0))

			local keyBtn = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(84, 28),
				Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = body
			}, {corner(6)})
			bind(keyBtn, "BackgroundColor3", "Sidebar")
			local kst = new("UIStroke", {Thickness = 1, Parent = keyBtn})
			bind(kst, "Color", "Stroke")

			local keyLbl = mkText("TextLabel", {
				Size = UDim2.fromScale(1, 1), Text = currentKey.Name or "None", Font = Enum.Font.GothamBold,
				TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = keyBtn
			}, "Accent")

			local function setKey(newKey)
				currentKey = newKey
				keyLbl.Text = currentKey.Name or "None"
				bindingKey = false
				bind(kst, "Color", "Stroke", true)
				if o.Callback then task.spawn(o.Callback, currentKey) end
			end

			keyBtn.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				bindingKey = true
				keyLbl.Text = "..."
				bind(kst, "Color", "Accent", true)
			end)

			A(UIS.InputBegan, function(input, gp)
				if bindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode ~= Enum.KeyCode.Unknown then
						setKey(input.KeyCode)
					end
				elseif not gp and input.KeyCode == currentKey then
					if quickMode then
						if o.Callback then task.spawn(o.Callback, currentKey) end
						keyLbl.TextSize = 14
						tw(keyLbl, 0.25, {TextSize = 11}, BACK)
					end
				end
			end)

			hover(body, body)
			local obj = {Card = body}
			function obj:Set(k) setKey(k) end
			function obj:Get() return currentKey end
			function obj:Reset() setKey(o.Key or Enum.KeyCode.E) end
			finish(tab, body, o, "keybind", obj, {zone})
			return obj
		end

		-- ===== COLORPICKER ELEMENT =====
		function tab:AddColorpicker(a, defaultCol, callback, extra)
			local o = type(a) == "table" and a or merge({Name = a, Default = defaultCol, Callback = callback}, extra)
			local currentColor = o.Default or Color3.fromRGB(255, 59, 83)
			local body = newCard(o.Name)
			header(body, o, 0.44, 16)
			local zone = holdZone(body, UDim2.new(0.6, 0, 1, 0))

			local preview = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(36, 24),
				BackgroundColor3 = currentColor, AutoButtonColor = false, Text = "", BorderSizePixel = 0, Parent = body
			}, {corner(6)})
			local pst = new("UIStroke", {Thickness = 1, Transparency = 0.2, Parent = preview})
			bind(pst, "Color", "Stroke")

			local pickerOpen = false
			local pickerOverlay, pickerDlg

			local function openPicker()
				if pickerOpen then return end
				pickerOpen = true

				local h, s, v = rgbToHsv(currentColor)
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				
				pickerOverlay = new("TextButton", {
					Name = "PickerOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 65, Parent = Main
				})
				
				pickerDlg = new("CanvasGroup", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(260, 240),
					BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 66, Parent = pickerOverlay
				}, {corner(12)})
				bind(pickerDlg, "BackgroundColor3", "Sidebar")
				local dst = new("UIStroke", {Thickness = 1.5, Parent = pickerDlg})
				bind(dst, "Color", "Accent")

				mkText("TextLabel", {
					Text = o.Name .. " Picker", Font = Enum.Font.GothamBold, TextSize = 13,
					Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 20), ZIndex = 67, Parent = pickerDlg
				})

				-- Saturation / Value Box
				local svBox = new("Frame", {
					Position = UDim2.fromOffset(14, 38), Size = UDim2.fromOffset(180, 150),
					BackgroundColor3 = hsvToRgb(h, 1, 1), BorderSizePixel = 0, ZIndex = 67, Parent = pickerDlg
				}, {corner(6)})
				
				local satGrad = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 68, Parent = svBox}, {corner(6)})
				new("UIGradient", {Rotation = 0, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0, 1), Parent = satGrad})
				
				local valGrad = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 69, Parent = svBox}, {corner(6)})
				new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)), Transparency = NumberSequence.new(1, 0), Parent = valGrad})

				local svCursor = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s, 1 - v), Size = UDim2.fromOffset(10, 10),
					BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 70, Parent = svBox
				}, {corner(5)})
				new("UIStroke", {Thickness = 1.5, Color = Color3.new(0, 0, 0), Parent = svCursor})

				-- Hue Bar
				local hueBar = new("Frame", {
					Position = UDim2.fromOffset(204, 38), Size = UDim2.fromOffset(20, 150),
					BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 67, Parent = pickerDlg
				}, {corner(6)})
				local hueG = new("UIGradient", {
					Rotation = 90, Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, rgb(255, 0, 0)),
						ColorSequenceKeypoint.new(0.17, rgb(255, 255, 0)),
						ColorSequenceKeypoint.new(0.33, rgb(0, 255, 0)),
						ColorSequenceKeypoint.new(0.5, rgb(0, 255, 255)),
						ColorSequenceKeypoint.new(0.67, rgb(0, 0, 255)),
						ColorSequenceKeypoint.new(0.83, rgb(255, 0, 255)),
						ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
					}), Parent = hueBar
				})

				local hueCursor = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, h), Size = UDim2.new(1, 4, 0, 6),
					BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 70, Parent = hueBar
				}, {corner(3)})
				new("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0), Parent = hueCursor})

				local function updateColor()
					currentColor = hsvToRgb(h, s, v)
					preview.BackgroundColor3 = currentColor
					svBox.BackgroundColor3 = hsvToRgb(h, 1, 1)
					if o.Callback then task.spawn(o.Callback, currentColor) end
				end

				-- SV Dragging
				local svDrag = false
				local svHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 71, Parent = svBox})
				local function updateSV(input)
					local pos = input.Position
					local abs = svBox.AbsolutePosition
					local size = svBox.AbsoluteSize
					s = math.clamp((pos.X - abs.X) / size.X, 0, 1)
					v = 1 - math.clamp((pos.Y - abs.Y) / size.Y, 0, 1)
					svCursor.Position = UDim2.fromScale(s, 1 - v)
					updateColor()
				end
				svHit.InputBegan:Connect(function(i) if isPress(i) then svDrag = true; updateSV(i) end end)

				-- Hue Dragging
				local hueDrag = false
				local hueHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 71, Parent = hueBar})
				local function updateHue(input)
					local pos = input.Position
					local abs = hueBar.AbsolutePosition
					local size = hueBar.AbsoluteSize
					h = math.clamp((pos.Y - abs.Y) / size.Y, 0, 1)
					hueCursor.Position = UDim2.fromScale(0.5, h)
					updateColor()
				end
				hueHit.InputBegan:Connect(function(i) if isPress(i) then hueDrag = true; updateHue(i) end end)

				A(UIS.InputChanged, function(i)
					if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
						if svDrag then updateSV(i) end
						if hueDrag then updateHue(i) end
					end
				end)
				A(UIS.InputEnded, function(i)
					if isPress(i) then svDrag = false; hueDrag = false end
				end)

				local closeBtn = pill(pickerDlg, {Text = "Done", Style = "Primary"}, {Size = UDim2.fromOffset(230, 28), Position = UDim2.fromOffset(15, 198), Radius = 6})
				closeBtn.ZIndex = 72
				local function close()
					pickerOpen = false
					tw(pickerDlg, 0.2, {GroupTransparency = 1})
					task.delay(0.22, function() unbindTree(pickerOverlay); pickerOverlay:Destroy() end)
				end
				closeBtn.MouseButton1Click:Connect(close)
				pickerOverlay.MouseButton1Click:Connect(close)

				tw(pickerDlg, 0.35, {GroupTransparency = 0}, Q)
			end

			preview.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				openPicker()
			end)

			hover(body, body)
			local obj = {Card = body}
			function obj:Set(col) currentColor = col; preview.BackgroundColor3 = currentColor end
			function obj:Get() return currentColor end
			function obj:Reset() obj:Set(o.Default or Color3.fromRGB(255, 59, 83)) end
			finish(tab, body, o, "colorpicker", obj, {zone})
			return obj
		end

		-- ===== TEXTBOX ELEMENT =====
		function tab:AddTextbox(a, placeholder, callback, default, extra)
			local o = type(a) == "table" and a or merge({Name = a, Placeholder = placeholder, Callback = callback, Default = default}, extra)
			local default0 = o.Default or ""
			local body = newCard(o.Name)
			header(body, o, 0.44, 16)
			local zone = holdZone(body, UDim2.new(0.5, 0, 1, 0))
			local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 30), ClipsDescendants = true, BorderSizePixel = 0, Parent = body}, {corner(6)})
			bind(box, "BackgroundColor3", "Sidebar")
			local bs = new("UIStroke", {Thickness = 1, Parent = box})
			bind(bs, "Color", "Stroke")
			local input = mkText("TextBox", {
				Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), Text = default0,
				PlaceholderText = o.Placeholder or "Type...", Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, ClearTextOnFocus = false, Parent = box
			})
			bind(input, "PlaceholderColor3", "SubText")
			hover(body, body)
			input.Focused:Connect(function()
				bind(bs, "Color", "Accent", true)
				tw(bs, 0.2, {Thickness = 2})
			end)
			input.FocusLost:Connect(function(enter)
				bind(bs, "Color", "Stroke", true)
				tw(bs, 0.2, {Thickness = 1})
				if o.Callback then task.spawn(o.Callback, input.Text, enter) end
			end)
			local obj = {Card = body}
			function obj:Set(text, fire)
				input.Text = tostring(text)
				if fire and o.Callback then task.spawn(o.Callback, input.Text, false) end
			end
			function obj:Get() return input.Text end
			function obj:Reset() obj:Set(default0, true) end
			finish(tab, body, o, "textbox", obj, {zone})
			return obj
		end

		-- ===== LABEL ELEMENT =====
		function tab:AddLabel(a, value, shimmer, extra)
			local o = type(a) == "table" and a or merge({Name = a, Value = value, Shimmer = shimmer}, extra)
			local body = newCard(o.Name)
			header(body, o, 0.45, 8)
			local v = mkText("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0.45, -14, 0, 22),
				Text = tostring(o.Value or ""), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = body
			}, o.Shimmer and "White" or "SubText")
			if o.Shimmer then
				local g = grad({"Accent", "Accent2", "Accent"}, v, {Offset = Vector2.new(-0.6, 0)})
				TweenService:Create(g, TweenInfo.new(2.4, SINE, INOUT, -1, true), {Offset = Vector2.new(0.6, 0)}):Play()
			end
			local zone = holdZone(body, UDim2.fromScale(1, 1))
			hover(body, zone)
			local obj = {Card = body}
			function obj:Set(t) v.Text = tostring(t) end
			finish(tab, body, o, "label", obj, {zone})
			return obj
		end

		-- ===== STEPPER ELEMENT =====
		function tab:AddStepper(a, mn, mx, default, step, callback, extra)
			local o = type(a) == "table" and a or merge({Name = a, Min = mn, Max = mx, Default = default, Step = step, Callback = callback}, extra)
			local min, max = o.Min or 0, o.Max or 100
			step = o.Step or 1
			local fmt = o.Format or function(v) return tostring(v) end
			local default0 = math.clamp(o.Default or min, min, max)
			local value = default0
			local body = newCard(o.Name)
			header(body, o, 0, 116)
			local zone = holdZone(body, UDim2.new(1, -120, 1, 0))
			local valBase = UDim2.new(1, -60, 0.5, 0)
			local valLbl = mkText("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = valBase, Size = UDim2.fromOffset(40, 24), Text = fmt(value), Font = Enum.Font.GothamBold, TextSize = 12, Parent = body}, "Text")
			local valScale = new("UIScale", {Parent = valLbl})

			local function apply(v, fire, dir)
				v = math.clamp(v, min, max)
				if v == value then
					if fire then
						valLbl.Position = UDim2.new(1, -60 + (dir or 1) * 5, 0.5, 0)
						tw(valLbl, 0.3, {Position = valBase}, BACK)
					end
					return false
				end
				value = v
				valLbl.Text = fmt(v)
				valLbl.Position = UDim2.new(1, -60, 0.5, (dir or 0) * 8)
				valLbl.TextTransparency = 0.6
				valScale.Scale = 1.12
				tw(valLbl, 0.22, {Position = valBase, TextTransparency = 0}, Q)
				tw(valScale, 0.3, {Scale = 1}, BACK)
				if fire and o.Callback then task.spawn(o.Callback, v) end
				return true
			end

			local function mkBtn(img, xoff, dir, glyph)
				local b = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xoff, 0.5, 0), Size = UDim2.fromOffset(26, 26), Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 4, Parent = body}, {corner(8)})
				bind(b, "BackgroundColor3", "Sidebar")
				local s = new("UIScale", {Parent = b})
				local im
				if img then
					im = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1, Image = icon(img), ZIndex = 5, Parent = b})
					bind(im, "ImageColor3", "Text")
				else
					im = mkText("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Text = glyph, Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 5, Parent = b}, "Text")
				end
				local token = 0
				b.InputBegan:Connect(function(input)
					if isPress(input) then
						token = token + 1
						local my = token
						tw(s, 0.1, {Scale = 0.78})
						tw(b, 0.1, {BackgroundColor3 = T("AccentDark")})
						tw(im, 0.1, {Rotation = dir * 18})
						ripple(body, input)
						apply(value + dir * step, true, dir)
						task.spawn(function()
							task.wait(0.38)
							local interval = 0.11
							while token == my and b.Parent do
								if not apply(value + dir * step, true, dir) then break end
								task.wait(interval)
								interval = math.max(0.035, interval * 0.93)
							end
						end)
					end
				end)
				local function release()
					token = token + 1
					tw(s, 0.35, {Scale = 1}, BACK)
					tw(b, 0.25, {BackgroundColor3 = T("Sidebar")})
					tw(im, 0.35, {Rotation = 0}, BACK)
				end
				A(UIS.InputEnded, function(input) if token > 0 and isPress(input) then release() end end)
				b.MouseLeave:Connect(release)
				return b
			end
			mkBtn(o.MinusIcon or ICON.Minus, -84, -1, "−")
			mkBtn(o.PlusIcon or ICON.Plus, -10, 1, "+")

			hover(body, body)
			local obj = {Card = body}
			function obj:Set(v) apply(v, true, 0) end
			function obj:Get() return value end
			function obj:Reset() apply(default0, true, 0) end
			finish(tab, body, o, "stepper", obj, {zone})
			return obj
		end

		-- ===== POPUP ELEMENT =====
		function tab:AddPopup(a, popupOpts, extra)
			local o = type(a) == "table" and a or merge({Name = a, Popup = popupOpts}, extra)
			local body = newCard(o.Name)
			header(body, o, 0, 40)
			mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, -2), Size = UDim2.fromOffset(18, 24), Text = "›", Font = Enum.Font.GothamBold, TextSize = 24, Parent = body}, "SubText")
			local hit = hitButton(body)
			hover(body, hit)
			pressFx(body, hit)
			local function show()
				local p = {}
				for k, v in pairs(o.Popup or {}) do p[k] = v end
				p.Title = p.Title or o.Name
				return win:Popup(p)
			end
			hit.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				show()
			end)
			local obj = {Card = body, Show = show}
			finish(tab, body, o, "popup", obj, {hit})
			return obj
		end

		-- ===== CODE VIEW ELEMENT =====
		function tab:AddCode(a, code, extra)
			local o = type(a) == "table" and a or merge({Name = a, Code = code}, extra)
			local body = newCard(o.Name or "Code")
			header(body, o, 0, 52)
			local copyBtn = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 26), Size = UDim2.fromOffset(28, 28), Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 4, Parent = body}, {corner(7)})
			bind(copyBtn, "BackgroundColor3", "Off")
			local copyIcon = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Image = icon(o.CopyIcon or ICON.Copy), ZIndex = 5, Parent = copyBtn})
			bind(copyIcon, "ImageColor3", "Text")

			local codeBox = new("Frame", {Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 1, -66), BorderSizePixel = 0, ClipsDescendants = true, Parent = body}, {corner(8)})
			bind(codeBox, "BackgroundColor3", "Sidebar")
			local codeScroll = new("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
				AutomaticCanvasSize = Enum.AutomaticSize.XY, CanvasSize = UDim2.new(), Parent = codeBox
			}, {
				new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8)}),
			})
			bind(codeScroll, "ScrollBarImageColor3", "SubText")

			local KEYWORDS = {["local"]=1,["function"]=1,["end"]=1,["if"]=1,["then"]=1,["else"]=1,["elseif"]=1,["for"]=1,["while"]=1,["do"]=1,["return"]=1,["nil"]=1,["true"]=1,["false"]=1}
			local function colorize(line)
				local out, i, n = {}, 1, #line
				while i <= n do
					local c = line:sub(i, i)
					local rest = line:sub(i)
					local piece, key
					if rest:sub(1, 2) == "--" then
						piece, key = rest, "SubText"
					elseif c == '"' or c == "'" then
						local j = i + 1
						while j <= n and line:sub(j, j) ~= c do if line:sub(j, j) == "\\" then j = j + 1 end; j = j + 1 end
						piece, key = line:sub(i, j), "Accent2"
					elseif c:match("%d") then
						piece = rest:match("^%d+%.?%d*") or c; key = "Accent"
					elseif c:match("[%a_]") then
						local word = rest:match("^[%a_][%w_]*")
						piece = word; key = KEYWORDS[word] and "Accent" or "Text"
					else
						piece, key = c, "SubText"
					end
					piece = piece or c
					table.insert(out, {piece, key})
					i = i + #piece
				end
				return out
			end

			local codeLines = {}
			local function render(src)
				for _, l in ipairs(codeLines) do l:Destroy() end
				codeLines = {}
				local y = 0
				for lineNo, line in ipairs(string.split(tostring(src), "\n")) do
					local lbl = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 16), Text = "", Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3, Parent = codeScroll})
					local rich = {}
					for _, seg in ipairs(colorize(line)) do
						local col = T(seg[2]) or T("Text")
						table.insert(rich, string.format('<font color="#%02X%02X%02X">%s</font>', col.R * 255, col.G * 255, col.B * 255, (seg[1]:gsub("<", "&lt;"):gsub(">", "&gt;"))))
					end
					lbl.RichText = true
					lbl.Text = table.concat(rich)
					table.insert(codeLines, lbl)
					y = y + 16
				end
				codeScroll.CanvasSize = UDim2.fromOffset(0, y + 16)
			end
			render(o.Code or "")

			local obj = {Card = body}
			function obj:SetCode(src) render(src) end
			function obj:Get() return o.Code end
			copyBtn.MouseButton1Click:Connect(function()
				local text = tostring(o.Code or "")
				if type(setclipboard) == "function" then setclipboard(text) end
				bind(copyBtn, "BackgroundColor3", "Accent", true)
				tw(copyIcon, 0.25, {Rotation = 360}, Q)
				task.delay(0.6, function()
					bind(copyBtn, "BackgroundColor3", "Off", true)
					copyIcon.Rotation = 0
				end)
				win:Notify("Copied", "Code copied to clipboard.", 2)
			end)
			hover(body, body)
			finish(tab, body, o, "code", obj, {copyBtn})
			return obj
		end

		-- ===== INFO PAGE ELEMENT =====
		function tab:AddInfoPage(a, spec, extra)
			local o = type(a) == "table" and a or merge({Name = a, Info = spec}, extra)
			local info = o.Info or {}
			local body = newCard(o.Name)
			header(body, o, 0, 40)
			mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, -2), Size = UDim2.fromOffset(18, 24), Text = "›", Font = Enum.Font.GothamBold, TextSize = 24, Parent = body}, "SubText")
			local hit = hitButton(body)
			hover(body, hit)
			pressFx(body, hit)

			local function show()
				local overlay = new("TextButton", {Name = "InfoOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 60, Parent = Main})
				local dlg = new("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.86, 0, 0.82, 0), BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 61, Parent = overlay}, {corner(14)})
				bind(dlg, "BackgroundColor3", "Sidebar")
				local dst = new("UIStroke", {Thickness = 1.5, Parent = dlg})
				bind(dst, "Color", "Accent")

				local back = pill(dlg, {Text = "Back", Icon = o.BackIcon}, {Size = UDim2.fromOffset(74, 30), Position = UDim2.fromOffset(12, 12), Radius = 8, TextSize = 11})
				back.ZIndex = 62
				local function close()
					tw(dlg, 0.2, {GroupTransparency = 1})
					task.delay(0.22, function() unbindTree(overlay); overlay:Destroy() end)
				end
				back.MouseButton1Click:Connect(close)

				local ix = 12
				if info.Icon then
					ix = 96
					local img = new("ImageLabel", {Image = icon(info.Icon), Position = UDim2.fromOffset(14, 52), Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 1, ZIndex = 62, Parent = dlg}, {corner(10)})
					if info.Tint then bind(img, "ImageColor3", "Accent") end
				end
				mkText("TextLabel", {Text = tostring(info.Title or o.Name), Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(ix, 56), Size = UDim2.new(1, -ix - 14, 0, 26), ZIndex = 62, Parent = dlg})
				mkText("TextLabel", {Text = tostring(info.Subtitle or ""), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(ix, 84), Size = UDim2.new(1, -ix - 14, 0, 16), ZIndex = 62, Parent = dlg}, "SubText")

				local scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(14, 130), Size = UDim2.new(1, -28, 1, -(130 + 60)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 62, Parent = dlg})
				bind(scroll, "ScrollBarImageColor3", "SubText")
				mkText("TextLabel", {Text = tostring(info.Text or ""), Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -6, 0, 0), ZIndex = 62, Parent = scroll}, "SubText")

				local buttons = info.Buttons or {}
				if #buttons > 0 then
					local bar = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -28, 0, 34), BackgroundTransparency = 1, ZIndex = 62, Parent = dlg}, {
						new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
					})
					for i, spec2 in ipairs(buttons) do
						local pb = pill(bar, {Text = spec2.Text, Icon = spec2.Icon, Style = spec2.Style or "Default"}, {Size = UDim2.new(1 / #buttons, -8, 1, 0), Radius = 9, TextSize = 11})
						pb.LayoutOrder = i
						pb.ZIndex = 63
						pb.MouseButton1Click:Connect(function()
							if spec2.Callback then task.spawn(spec2.Callback) end
							if spec2.Close ~= false then close() end
						end)
					end
				end

				dlg.Position = UDim2.fromScale(0.5, 0.56)
				tw(dlg, 0.35, {GroupTransparency = 0})
				tw(dlg, 0.45, {Position = UDim2.fromScale(0.5, 0.5)}, Q)
			end

			hit.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				show()
			end)
			local obj = {Card = body, Show = show}
			finish(tab, body, o, "info", obj, {hit})
			return obj
		end

		-- ===== DROPDOWN ELEMENT =====
		function tab:AddDropdown(a, options, default, callback, extra)
			local o = type(a) == "table" and a or merge({Name = a, Options = options, Default = default, Callback = callback}, extra)
			local dd = {Name = tostring(o.Name), Options = o.Options or {}, Max = (o.Max == nil) and 1 or o.Max, Placeholder = o.Placeholder or "Select...", Selected = {}, Swatches = o.Swatches, Callback = o.Callback}
			if dd.Max <= 0 then dd.Max = math.huge end
			local function loadDefault(def)
				dd.Selected = {}
				if type(def) == "string" then
					dd.Selected = {def}
				elseif type(def) == "table" then
					for _, v in ipairs(def) do
						if #dd.Selected < dd.Max then table.insert(dd.Selected, v) end
					end
				end
			end
			loadDefault(o.Default)
			local default0 = {}
			for _, v in ipairs(dd.Selected) do table.insert(default0, v) end

			local body = newCard(o.Name)
			header(body, o, 0.46, 12)
			local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.44, 0, 0, 32), BorderSizePixel = 0, Parent = body}, {corner(8)})
			bind(box, "BackgroundColor3", "Sidebar")
			local bst = new("UIStroke", {Thickness = 1, Parent = box})
			bind(bst, "Color", "Stroke")
			local valLbl = mkText("TextLabel", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -30, 1, 0), Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box}, "Text")
			local chev = mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16), Text = "›", Font = Enum.Font.GothamBold, TextSize = 18, Rotation = 90, Parent = box}, "SubText")
			dd.Chev = chev

			function dd.Refresh()
				local n = #dd.Selected
				if n == 0 then
					valLbl.Text = dd.Placeholder
					bind(valLbl, "TextColor3", "SubText")
				else
					bind(valLbl, "TextColor3", "Text")
					if n == 1 then valLbl.Text = tostring(dd.Selected[1]) else valLbl.Text = n .. " selected" end
				end
			end
			dd.Refresh()

			local hit = hitButton(body)
			hover(body, hit)
			pressFx(body, hit)
			hit.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				openDropdownPanel(dd)
			end)

			local obj = {Card = body, Listeners = {}}
			local function fireCb()
				if dd.Callback then
					if dd.Max == 1 then task.spawn(dd.Callback, dd.Selected[1])
					else
						local copy = {}
						for _, v in ipairs(dd.Selected) do table.insert(copy, v) end
						task.spawn(dd.Callback, copy)
					end
				end
				for _, f in ipairs(obj.Listeners) do pcall(f) end
			end
			dd.Fire = fireCb
			function obj:Set(v, fire)
				loadDefault(v)
				dd.Refresh()
				if fire then fireCb() end
			end
			function obj:Get()
				if dd.Max == 1 then return dd.Selected[1] end
				local copy = {}
				for _, v in ipairs(dd.Selected) do table.insert(copy, v) end
				return copy
			end
			function obj:GetList()
				local copy = {}
				for _, v in ipairs(dd.Selected) do table.insert(copy, v) end
				return copy
			end
			function obj:SetOptions(list) dd.Options = list or {} end
			function obj:Reset() obj:Set(default0, true) end
			dd.Obj = obj
			finish(tab, body, o, "dropdown", obj, {hit})
			return obj
		end

		return tab
	end

	-- SideTab Builder (Top Level)
	local topCount = 0
	local function createSideTab(name, iconId, slot)
		local st = {Name = name, Tabs = {}, System = slot ~= nil, HiddenCount = 0}
		if slot then
			st.Y = SYS_TOP + (slot - 1) * 42
			st.Order = 1000 + slot
		else
			topCount = topCount + 1
			st.Y = 2 + (topCount - 1) * 42
			st.Order = topCount
		end

		local btn = new("TextButton", {
			Name = name, Position = UDim2.fromOffset(10, st.Y), Size = UDim2.new(1, -20, 0, 38),
			Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, Parent = Nav
		})
		st.Button = btn

		local pad = 14
		local ico = icon(iconId)
		if ico then
			pad = 42
			st.Icon = new("ImageLabel", {Image = ico, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 13, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = 3, Parent = btn})
			bind(st.Icon, "ImageColor3", "Text")
		end
		st.Pad = pad
		st.Label = mkText("TextLabel", {Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(pad, 0), Size = UDim2.new(1, -pad - 8, 1, 0), ZIndex = 3, Parent = btn})

		st.TabBar = new("CanvasGroup", {Name = name, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 0, Visible = false, Parent = TabBarHolder}, {corner(8)})
		bind(st.TabBar, "BackgroundColor3", "Sidebar")
		local tbs = new("UIStroke", {Thickness = 1, Parent = st.TabBar})
		bind(tbs, "Color", "Stroke")
		st.TabInner = new("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = st.TabBar})
		st.TabInd = new("Frame", {Name = "Pill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, Parent = st.TabInner}, {corner(6)})
		grad({"AccentDark", "Accent2Dark"}, st.TabInd)

		st.HiddenTab = buildTab(st, "Hidden", {Virtual = true, System = true})

		btn.MouseEnter:Connect(function() if not st.Active then tw(st.Label, 0.22, {Position = UDim2.new(0, pad + 3, 0, 0)}, Q) end end)
		btn.MouseLeave:Connect(function() if not st.Active then tw(st.Label, 0.22, {Position = UDim2.new(0, pad, 0, 0)}, Q) end end)
		btn.MouseButton1Click:Connect(function() selectSideTab(st) end)

		table.insert(win.SideTabs, st)
		function st:CreateTab(tabName) return createTab(st, tabName) end
		return st
	end

	function win:CreateSideTab(name, iconId)
		if topCount >= 5 then warn("[Pingo] Max top-level SideTabs reached.") end
		local st = createSideTab(name, iconId, nil)
		if not win.UserSelected then
			win.UserSelected = true
			selectSideTab(st)
		end
		return st
	end

	function win:SetSizeMultiplier(m)
		win.SizeMul = math.clamp(m, 0.3, 1.8)
		refit(true)
	end

	function win:SetLocked(state)
		win.Locked = state == true
		if win.LockToggle and win.LockToggle:Get() ~= win.Locked then win.LockToggle:Set(win.Locked) end
	end

	-- ============================================================
	-- TOGGLE BUTTON (Custom image support & styling)
	-- ============================================================
	local btnText = tostring(config.ButtonText or title)
	local textW = TextService:GetTextSize(btnText, 14, Enum.Font.GothamBold, Vector2.new(400, 46)).X
	local BTN_H = 44
	local BTN_W = math.ceil(7 + 32 + 10 + textW + 18)

	local OpenBtn = new("TextButton", {
		Name = "PingoOpen", Size = UDim2.fromOffset(BTN_W, BTN_H), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14), Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 10, Parent = gui
	}, {corner(12)})
	grad({"AccentDark", "Accent2Dark"}, OpenBtn, {Rotation = 20})
	local obStroke = new("UIStroke", {Thickness = 1.5, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = OpenBtn})
	bind(obStroke, "Color", "Accent")
	local obScale = new("UIScale", {Parent = OpenBtn})

	local gloss = new("Frame", {Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0.5, -2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 11, Parent = OpenBtn}, {corner(10)})
	new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(1, 1)}), Parent = gloss})

	local iconBox = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 13, Parent = OpenBtn}, {corner(8)})
	local iconPop = new("UIScale", {Parent = iconBox})
	if config.Icon then
		new("ImageLabel", {Image = icon(config.Icon), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 14, Parent = iconBox}, {corner(6)})
	else
		new("TextLabel", {Text = string.upper(string.sub(btnText, 1, 1)), Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 14, Parent = iconBox})
	end
	new("TextLabel", {Text = btnText, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -46, 1, 0), ZIndex = 13, Parent = OpenBtn})

	OpenBtn.MouseEnter:Connect(function() tw(obScale, 0.22, {Scale = 1.05}, BACK); tw(obStroke, 0.2, {Transparency = 0}) end)
	OpenBtn.MouseLeave:Connect(function() tw(obScale, 0.22, {Scale = 1}, BACK); tw(obStroke, 0.2, {Transparency = 0.15}) end)
	makeDraggable(OpenBtn, OpenBtn, function()
		obScale.Scale = 0.92
		tw(obScale, 0.35, {Scale = 1}, BACK)
		win:Toggle()
	end)
	win.OpenButton = OpenBtn

	-- Bottom Navigation Controls
	local hideSpec = {Text = config.HideText or "Hide Menu", Icon = config.HideIcon, Style = "Default"}
	local unloadSpec = {Text = config.UnloadText or "Unload Menu", Icon = config.UnloadIcon, Style = "Primary"}
	local function pillW(spec)
		return math.ceil(TextService:GetTextSize(spec.Text, 12, Enum.Font.GothamBold, Vector2.new(300, 34)).X + 36 + (spec.Icon and 22 or 0))
	end
	local hw, uw, BAR_GAP = pillW(hideSpec), pillW(unloadSpec), 10
	local Bar = new("Frame", {Name = "BottomBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 12), Size = UDim2.fromOffset(hw + BAR_GAP + uw, 34), BackgroundTransparency = 1, Parent = Holder})
	local barScale = new("UIScale", {Parent = Bar})
	local hideBtn = pill(Bar, hideSpec, {Size = UDim2.fromOffset(hw, 34), Radius = 9, TextSize = 12})
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, hw + BAR_GAP + uw / 2, 0.5, 0), Size = UDim2.fromOffset(uw + 14, 48), BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = Bar}, {corner(15)})
	bind(glow, "BackgroundColor3", "Accent")
	TweenService:Create(glow, TweenInfo.new(1.4, SINE, INOUT, -1, true), {BackgroundTransparency = 0.64}):Play()
	local unloadBtn = pill(Bar, unloadSpec, {Size = UDim2.fromOffset(uw, 34), Position = UDim2.fromOffset(hw + BAR_GAP, 0), Radius = 9, TextSize = 12})
	
	hideBtn.MouseButton1Click:Connect(function() win:Toggle(false) end)
	unloadBtn.MouseButton1Click:Connect(function()
		if config.ConfirmUnload == false then win:Unload() return end
		win:Popup({
			Title = "Unload " .. title .. "?",
			Text = "This will terminate the interface and clean up active threads.",
			Icon = config.UnloadIcon or config.Icon,
			Buttons = {{Text = "Cancel"}, {Text = "Unload", Style = "Primary", Callback = function() win:Unload() end}},
		})
	end)

	-- Open / Close Core Logic
	local token = 0
	function win:Toggle(state)
		if state == nil then state = not win.Opened end
		if state == win.Opened then return end
		win.Opened = state
		token = token + 1
		local my = token
		iconPop.Scale = 0.75
		tw(iconPop, 0.45, {Scale = 1}, BACK)
		
		setBlurState(win.BlurEnabled)

		if state then
			Holder.Visible = true
			openScale.Scale = 0.9
			Main.GroupTransparency = 1
			Sidebar.Position = UDim2.fromOffset(-40, 0)
			Content.Position = UDim2.fromOffset(210, 0)
			tw(openScale, 0.45, {Scale = 1}, BACK)
			tw(Main, 0.3, {GroupTransparency = 0})
			Main.Position = UDim2.new(0.5, 0, 0.5, 24)
			tw(Main, 0.55, {Position = UDim2.fromScale(0.5, 0.5)}, Q)
			Bar.Position = UDim2.new(0.5, 0, 1, -8)
			barScale.Scale = 0.85
			task.delay(0.1, function()
				tw(Bar, 0.5, {Position = UDim2.new(0.5, 0, 1, 12)}, Q)
				tw(barScale, 0.45, {Scale = 1}, BACK)
			end)
			tw(Sidebar, 0.55, {Position = UDim2.fromOffset(0, 0)}, Q)
			tw(Content, 0.55, {Position = UDim2.fromOffset(184, 0)}, Q)
			local t = win.CurrentTab
			if t then playIn(t) end
		else
			closeMenu()
			tw(openScale, 0.25, {Scale = 0.9}, QUAD, IN)
			tw(Main, 0.25, {Position = UDim2.new(0.5, 0, 0.5, 14)}, QUAD, IN)
			tw(Main, 0.22, {GroupTransparency = 1})
			task.delay(0.26, function()
				if token == my then Holder.Visible = false end
			end)
		end
	end

	A(UIS.InputBegan, function(input, gp)
		if gp then return end
		if input.KeyCode == (config.Key or Enum.KeyCode.RightShift) then win:Toggle() end
	end)

	-- ============================================================
	-- GLASSMORPHIC NOTIFICATION ENGINE
	-- ============================================================
	local NW = 310
	local NotifHolder = new("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, NW, 1, -32), BackgroundTransparency = 1, ZIndex = 30, Parent = gui
	}, {
		new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local notifCount, notifList = 0, {}

	function win:Notify(nTitle, text, duration, extra)
		local o = {}
		if type(nTitle) == "table" then
			o = nTitle; nTitle, text, duration = o.Title, o.Text, o.Duration
		elseif type(extra) == "table" then
			o = extra
		elseif extra ~= nil then
			o = {Icon = extra}
		end
		if not win.NotifyEnabled and not o.Force then return {Dismiss = function() end} end
		
		local buttons = o.Buttons or {}
		local nb = #buttons
		if duration == nil then duration = (nb > 0) and 8 or 4 end
		notifCount = notifCount + 1
		nTitle, text = tostring(nTitle or ""), tostring(text or "")

		local tx = 64
		local textW2 = NW - tx - 14
		local th = 0
		if text ~= "" then
			th = TextService:GetTextSize(text, 11, Enum.Font.Gotham, Vector2.new(textW2, 600)).Y
		end
		local contentBottom = math.max(52, 34 + th)
		local BH, BG = 28, 6
		local cols = math.min(math.max(nb, 1), 3)
		local rows = nb > 0 and math.ceil(nb / cols) or 0
		local btnH = rows > 0 and (rows * BH + (rows - 1) * BG) or 0
		local h = contentBottom + 14
		if nb > 0 then h = contentBottom + 10 + btnH + 14 end

		local wrap = new("Frame", {Size = UDim2.fromOffset(NW, 0), BackgroundTransparency = 1, LayoutOrder = notifCount, Parent = NotifHolder})
		local n = new("CanvasGroup", {
			Size = UDim2.fromOffset(NW, h), Position = UDim2.fromOffset(NW + 40, 0), BorderSizePixel = 0,
			BackgroundTransparency = 0, GroupTransparency = 1, Parent = wrap
		}, {corner(12)})
		bind(n, "BackgroundColor3", "Sidebar")
		local ns = new("UIStroke", {Thickness = 1, Parent = n})
		bind(ns, "Color", "Stroke")

		-- Unique Glassmorphic background
		local tint = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = n})
		local tintG = grad({"Accent", "Accent2"}, tint)
		tintG.Transparency = NumberSequence.new(0.88, 0.97)

		local accentBar = new("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = n})
		grad({"Accent", "Accent2"}, accentBar, {Rotation = 90})

		local badge = new("Frame", {Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(38, 38), BorderSizePixel = 0, BackgroundTransparency = 0.82, Parent = n}, {corner(10)})
		bind(badge, "BackgroundColor3", "Accent")
		local bst = new("UIStroke", {Thickness = 1.5, Transparency = 0.55, Parent = badge})
		bind(bst, "Color", "Accent")

		local dot
		if o.Icon then
			local im = new("ImageLabel", {Image = icon(o.Icon), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1, Parent = badge}, {corner(7)})
			if o.Tint then bind(im, "ImageColor3", "Accent") end
		else
			dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0), BorderSizePixel = 0, Parent = badge}, {corner(8)})
			bind(dot, "BackgroundColor3", "Accent")
		end

		mkText("TextLabel", {Text = nTitle, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(tx, 13), Size = UDim2.new(1, -(tx + 14), 0, 18), Parent = n})
		if text ~= "" then
			mkText("TextLabel", {Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Position = UDim2.fromOffset(tx, 34), Size = UDim2.fromOffset(textW2, th), Parent = n}, "SubText")
		end

		local fill
		if duration > 0 then
			local track = new("Frame", {Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), BorderSizePixel = 0, BackgroundTransparency = 0.5, Parent = n})
			bind(track, "BackgroundColor3", "Off")
			fill = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track})
			grad({"Accent", "Accent2"}, fill)
		end

		local clickArea = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = n})

		local dead = false
		local dismiss
		dismiss = function()
			if dead then return end
			dead = true
			for i, v in ipairs(notifList) do if v == dismiss then table.remove(notifList, i) break end end
			tw(n, 0.4, {Position = UDim2.fromOffset(NW + 40, 0)}, Q, IN)
			tw(n, 0.3, {GroupTransparency = 1}, QUAD, IN)
			task.delay(0.3, function() if wrap.Parent then tw(wrap, 0.28, {Size = UDim2.fromOffset(NW, 0)}, Q) end end)
			task.delay(0.6, function() unbindTree(wrap); wrap:Destroy() end)
		end
		clickArea.MouseButton1Click:Connect(dismiss)

		if nb > 0 then
			local grid = new("Frame", {Position = UDim2.fromOffset(14, contentBottom + 10), Size = UDim2.new(1, -28, 0, btnH), BackgroundTransparency = 1, Parent = n}, {
				new("UIGridLayout", {CellSize = UDim2.new(1 / cols, -(BG * (cols - 1)) / cols, 0, BH), CellPadding = UDim2.fromOffset(BG, BG), SortOrder = Enum.SortOrder.LayoutOrder}),
			})
			for i, spec in ipairs(buttons) do
				local sp = {Text = spec.Text, Icon = spec.Icon, Style = spec.Style or ((nb == 1) and "Primary" or "Default")}
				local pb = pill(grid, sp, {Radius = 8, TextSize = 11})
				pb.LayoutOrder = i
				pb.MouseButton1Click:Connect(function()
					if spec.Callback then task.spawn(spec.Callback) end
					if spec.Keep ~= true then dismiss() end
				end)
			end
		end

		tw(wrap, 0.35, {Size = UDim2.fromOffset(NW, h + 8)}, Q)
		tw(n, 0.55, {Position = UDim2.fromOffset(0, 0)}, Q)
		tw(n, 0.35, {GroupTransparency = 0})
		if dot then task.delay(0.25, function() if dot.Parent then tw(dot, 0.45, {Size = UDim2.fromOffset(12, 12)}, BACK) end end) end
		if fill then tw(fill, duration, {Size = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Linear) end
		if duration > 0 then task.delay(duration, dismiss) end

		table.insert(notifList, dismiss)
		if #notifList > 5 then notifList[1]() end
		return {Dismiss = dismiss}
	end

	-- Modal Popups
	local activePopup
	function win:Popup(o)
		o = o or {}
		if activePopup then activePopup.Close(true) end
		local buttons = o.Buttons
		if not buttons or #buttons == 0 then buttons = {{Text = "OK", Style = "Primary"}} end
		local PW = 340
		local inner = PW - 36
		local hasIcon = o.Icon ~= nil
		local text = tostring(o.Text or "")
		local th = 0
		if text ~= "" then th = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(inner, 600)).Y end
		local textY = hasIcon and 74 or 48
		local nextY = (text ~= "") and (textY + th + 16) or textY
		local inputY
		if o.Input then inputY = nextY; nextY = nextY + 36 + 14 else nextY = nextY + 2 end
		local btnY = nextY
		local nb = #buttons
		local cols = nb <= 3 and nb or 2
		local rows = math.ceil(nb / cols)
		local BH, BG = 36, 8
		local btnH = rows * BH + (rows - 1) * BG
		local PH = btnY + btnH + 18

		local overlay = new("TextButton", {
			Name = "PopupOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 60, Parent = Main
		})
		local dlg = new("CanvasGroup", {
			Active = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 24),
			Size = UDim2.fromOffset(PW, PH), BackgroundTransparency = 0, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 61, Parent = overlay
		}, {corner(14)})
		bind(dlg, "BackgroundColor3", "Sidebar")
		local dscale = new("UIScale", {Scale = 0.92, Parent = dlg})
		local dst = new("UIStroke", {Thickness = 1.5, Transparency = 0.35, Parent = dlg})
		bind(dst, "Color", "Accent")
		local topBar = new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = dlg})
		grad({"Accent", "Accent2"}, topBar)

		local titleX = 18
		if hasIcon then
			titleX = 72
			local badge = new("Frame", {Position = UDim2.fromOffset(18, 20), Size = UDim2.fromOffset(44, 44), BorderSizePixel = 0, BackgroundTransparency = 0.82, Parent = dlg}, {corner(12)})
			bind(badge, "BackgroundColor3", "Accent")
			local im = new("ImageLabel", {Image = icon(o.Icon), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1, Parent = badge}, {corner(8)})
			if o.Tint then bind(im, "ImageColor3", "Accent") end
		end
		mkText("TextLabel", {Text = tostring(o.Title or ""), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(titleX, hasIcon and 20 or 16), Size = UDim2.new(1, -(titleX + 18), 0, hasIcon and 44 or 24), Parent = dlg})
		if text ~= "" then
			mkText("TextLabel", {Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Position = UDim2.fromOffset(18, textY), Size = UDim2.fromOffset(inner, th), Parent = dlg}, "SubText")
		end

		local inputBox
		if o.Input then
			local ib = new("Frame", {Position = UDim2.fromOffset(18, inputY), Size = UDim2.fromOffset(inner, 36), BorderSizePixel = 0, Parent = dlg}, {corner(9)})
			bind(ib, "BackgroundColor3", "Card")
			local ibs = new("UIStroke", {Thickness = 1, Parent = ib})
			bind(ibs, "Color", "Stroke")
			inputBox = mkText("TextBox", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Text = tostring(o.Input.Default or ""), PlaceholderText = tostring(o.Input.Placeholder or "Type here..."), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = ib}, "Text")
			bind(inputBox, "PlaceholderColor3", "SubText")
			inputBox.Focused:Connect(function() bind(ibs, "Color", "Accent", true) end)
			inputBox.FocusLost:Connect(function() bind(ibs, "Color", "Stroke", true) end)
		end

		local handle = {}
		local closed = false
		local function close(instant)
			if closed then return end
			closed = true
			if activePopup == handle then activePopup = nil end
			if instant then unbindTree(overlay); overlay:Destroy() return end
			tw(overlay, 0.22, {BackgroundTransparency = 1})
			tw(dlg, 0.2, {GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 12)}, QUAD, IN)
			tw(dscale, 0.2, {Scale = 0.94}, QUAD, IN)
			task.delay(0.26, function() unbindTree(overlay); overlay:Destroy() end)
		end
		handle.Close = close
		activePopup = handle

		local grid = new("Frame", {Position = UDim2.fromOffset(18, btnY), Size = UDim2.fromOffset(inner, btnH), BackgroundTransparency = 1, Parent = dlg}, {
			new("UIGridLayout", {CellSize = UDim2.new(1 / cols, -(BG * (cols - 1)) / cols, 0, BH), CellPadding = UDim2.fromOffset(BG, BG), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
		for i, spec in ipairs(buttons) do
			local pb = pill(grid, spec, {Radius = 9, TextSize = 12})
			pb.LayoutOrder = i
			pb.MouseButton1Click:Connect(function()
				local txt = inputBox and inputBox.Text or nil
				if spec.RequireInput and (not txt or txt:gsub("%s", "") == "") then
					dlg.Position = UDim2.new(0.5, 8, 0.5, 0)
					tw(dlg, 0.35, {Position = UDim2.fromScale(0.5, 0.5)}, BACK)
					return
				end
				if spec.Callback then task.spawn(spec.Callback, txt) end
				if spec.Keep ~= true then close() end
			end)
		end
		if o.Dismissable ~= false then overlay.MouseButton1Click:Connect(function() close() end) end

		tw(overlay, 0.25, {BackgroundTransparency = 0.45})
		tw(dlg, 0.45, {Position = UDim2.fromScale(0.5, 0.5)}, Q)
		tw(dlg, 0.3, {GroupTransparency = 0})
		tw(dscale, 0.45, {Scale = 1}, BACK)
		if inputBox then task.delay(0.35, function() if inputBox.Parent then inputBox:CaptureFocus() end end) end
		return handle
	end

	-- Extended Dropdown Overlay Panel
	local activeDD
	openDropdownPanel = function(dd)
		if activeDD then activeDD.close(true) end
		local PWIDTH = 250
		local multi = dd.Max ~= 1
		local footerH = multi and 54 or 12

		local overlay = new("TextButton", {Name = "DropdownOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 55, Parent = Main})
		local panel = new("CanvasGroup", {Active = true, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, PWIDTH + 30, 0.5, 0), Size = UDim2.new(0, PWIDTH, 1, -24), BackgroundTransparency = 0, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 56, Parent = overlay}, {corner(14)})
		bind(panel, "BackgroundColor3", "Sidebar")
		local ps = new("UIStroke", {Thickness = 1.5, Transparency = 0.3, Parent = panel})
		bind(ps, "Color", "Accent")
		local topBar = new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = panel})
		grad({"Accent", "Accent2"}, topBar)

		mkText("TextLabel", {Text = dd.Name, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -86, 0, 22), Parent = panel})
		local counter = mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14), Size = UDim2.fromOffset(60, 22), Text = "", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = panel}, "Accent")
		local function updateCounter()
			if multi then counter.Text = (dd.Max == math.huge) and (#dd.Selected .. " selected") or (#dd.Selected .. "/" .. dd.Max) end
		end
		updateCounter()

		local sb = new("Frame", {Position = UDim2.fromOffset(14, 46), Size = UDim2.new(1, -28, 0, 34), BorderSizePixel = 0, Parent = panel}, {corner(9)})
		bind(sb, "BackgroundColor3", "Card")
		local sbs = new("UIStroke", {Thickness = 1, Parent = sb})
		bind(sbs, "Color", "Stroke")
		local si = new("ImageLabel", {Image = icon(ICON.Search), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = sb})
		bind(si, "ImageColor3", "SubText")
		local search = mkText("TextBox", {Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -42, 1, 0), Text = "", PlaceholderText = "Search...", Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = sb}, "Text")
		bind(search, "PlaceholderColor3", "SubText")

		local list = new("ScrollingFrame", {Position = UDim2.fromOffset(8, 90), Size = UDim2.new(1, -16, 1, -(90 + footerH)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel}, {
			new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
			new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6)}),
		})
		bind(list, "ScrollBarImageColor3", "SubText")

		local closed = false
		local function close(instant)
			if closed then return end
			closed = true
			if activeDD and activeDD.overlay == overlay then activeDD = nil end
			if dd.Chev then tw(dd.Chev, 0.3, {Rotation = 90}, Q) end
			if instant then unbindTree(overlay); overlay:Destroy() return end
			tw(overlay, 0.25, {BackgroundTransparency = 1})
			tw(panel, 0.35, {Position = UDim2.new(1, PWIDTH + 30, 0.5, 0)}, Q, IN)
			tw(panel, 0.25, {GroupTransparency = 1})
			task.delay(0.4, function() unbindTree(overlay); overlay:Destroy() end)
		end
		activeDD = {close = close, overlay = overlay}
		overlay.MouseButton1Click:Connect(function() close() end)

		local rowRefs = {}
		local function refreshRows()
			for _, r in ipairs(rowRefs) do
				local sel = table.find(dd.Selected, r.opt) ~= nil
				r.bar.Visible = sel
				r.dot.Visible = sel
				bind(r.lbl, "TextColor3", sel and "Accent" or "Text", true)
			end
			updateCounter()
		end

		local function pick(r)
			local idx = table.find(dd.Selected, r.opt)
			if not multi then
				dd.Selected = {r.opt}
				dd.Refresh()
				dd.Fire()
				refreshRows()
				task.delay(0.12, function() close() end)
				return
			end
			if idx then
				table.remove(dd.Selected, idx)
			else
				if #dd.Selected >= dd.Max then
					r.btn.Position = UDim2.fromOffset(8, 0)
					tw(r.btn, 0.35, {Position = UDim2.fromOffset(0, 0)}, BACK)
					win:Notify("Limit Reached", "Maximum of " .. dd.Max .. " items allowed.", 2.5)
					return
				end
				table.insert(dd.Selected, r.opt)
			end
			dd.Refresh()
			dd.Fire()
			refreshRows()
		end

		local emptyLbl = mkText("TextLabel", {Text = "No matching items", Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1, 0, 0, 40), Visible = false, LayoutOrder = 9999, Parent = list}, "SubText")

		local function buildRows(filter)
			for _, r in ipairs(rowRefs) do unbindTree(r.outer); r.outer:Destroy() end
			rowRefs = {}
			filter = string.lower(filter or "")
			local count = 0
			for i, opt in ipairs(dd.Options) do
				if filter == "" or string.find(string.lower(tostring(opt)), filter, 1, true) then
					count = count + 1
					local outer = new("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = i, Parent = list})
					local btn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = outer}, {corner(8)})
					local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(3, 16), BorderSizePixel = 0, Visible = false, Parent = btn}, {corner(2)})
					bind(bar, "BackgroundColor3", "Accent")
					local tx = 14
					local sw = dd.Swatches and dd.Swatches[opt]
					if sw then
						new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = btn}, {
							corner(8),
							new("UIGradient", {Rotation = 35, Color = ColorSequence.new(sw[1], sw[2])}),
						})
						tx = 38
					end
					local lbl = mkText("TextLabel", {Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -tx - 28, 1, 0), Parent = btn}, "Text")
					local dot = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, Visible = false, Parent = btn}, {corner(4)})
					bind(dot, "BackgroundColor3", "Accent")
					local r = {opt = opt, outer = outer, btn = btn, bar = bar, lbl = lbl, dot = dot}
					table.insert(rowRefs, r)
					btn.MouseEnter:Connect(function() tw(btn, 0.15, {BackgroundTransparency = 0.93}) end)
					btn.MouseLeave:Connect(function() tw(btn, 0.2, {BackgroundTransparency = 1}) end)
					btn.MouseButton1Click:Connect(function() pick(r) end)
				end
			end
			emptyLbl.Visible = count == 0
			refreshRows()
		end
		buildRows("")
		search:GetPropertyChangedSignal("Text"):Connect(function() buildRows(search.Text) end)

		if multi then
			local clear = pill(panel, {Text = "Clear"}, {Size = UDim2.new(0.4, -14, 0, 34), Position = UDim2.new(0, 14, 1, -46), Radius = 9, TextSize = 12})
			local done = pill(panel, {Text = "Done", Style = "Primary"}, {Size = UDim2.new(0.6, -20, 0, 34), Position = UDim2.new(0.4, 6, 1, -46), Radius = 9, TextSize = 12})
			clear.MouseButton1Click:Connect(function()
				dd.Selected = {}
				dd.Refresh()
				dd.Fire()
				refreshRows()
			end)
			done.MouseButton1Click:Connect(function() close() end)
		end

		if dd.Chev then tw(dd.Chev, 0.3, {Rotation = -90}, Q) end
		tw(overlay, 0.3, {BackgroundTransparency = 0.5})
		tw(panel, 0.5, {Position = UDim2.new(1, -12, 0.5, 0)}, Q)
		tw(panel, 0.3, {GroupTransparency = 0})
	end

	-- Configuration Persistence Manager
	local FS = {}
	do
		local has = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
			and type(isfolder) == "function" and type(makefolder) == "function" and type(listfiles) == "function" and type(delfile) == "function"
		local root = "Pingo"
		local dir = root .. "/" .. sanitize(title)
		local cdir = dir .. "/configs"
		local mem = {files = {}, auto = nil}
		FS.Supported = has
		FS.Path = has and cdir or "(Memory Storage)"
		local function ensure()
			if not has then return end
			pcall(function()
				for _, p in ipairs({root, dir, cdir}) do if not isfolder(p) then makefolder(p) end end
			end)
		end
		function FS.list()
			ensure()
			local out = {}
			if has then
				local ok, files = pcall(listfiles, cdir)
				if ok and type(files) == "table" then
					for _, f in ipairs(files) do
						local n = tostring(f):match("([^/\\]+)%.json$")
						if n then out[#out + 1] = n end
					end
				end
			else
				for n in pairs(mem.files) do out[#out + 1] = n end
			end
			table.sort(out, function(a, b) return a:lower() < b:lower() end)
			return out
		end
		function FS.exists(n) ensure(); return has and pcall(isfile, cdir .. "/" .. n .. ".json") or (mem.files[n] ~= nil) end
		function FS.write(n, data) ensure(); if has then return (pcall(writefile, cdir .. "/" .. n .. ".json", data)) end; mem.files[n] = data; return true end
		function FS.read(n) if has then local ok, r = pcall(readfile, cdir .. "/" .. n .. ".json"); return ok and r or nil end; return mem.files[n] end
		function FS.delete(n) if has then pcall(delfile, cdir .. "/" .. n .. ".json") else mem.files[n] = nil end end
		function FS.getAuto()
			if has then
				local ok, r = pcall(function() if isfile(dir .. "/autoload.txt") then return readfile(dir .. "/autoload.txt") end end)
				return (ok and type(r) == "string" and r ~= "") and r or nil
			end
			return mem.auto
		end
		function FS.setAuto(n)
			if has then
				pcall(function()
					ensure()
					if n then writefile(dir .. "/autoload.txt", n) elseif isfile(dir .. "/autoload.txt") then delfile(dir .. "/autoload.txt") end
				end)
			else mem.auto = n end
		end
	end

	local STATEFUL = {toggle = true, slider = true, stepper = true, textbox = true, dropdown = true, keybind = true, colorpicker = true}

	local function collectState()
		local s = {v = 2, theme = currentTheme, saved = os.time(), menu = {size = math.floor(win.SizeMul * 100 + 0.5), locked = win.Locked, notify = win.NotifyEnabled, reduce = win.ReduceMotion, blur = win.BlurEnabled}, tabs = {}, elements = {}, floating = {}}
		for id, tab in pairs(win.TabRegistry) do
			if tab.Fav or tab.Hidden then s.tabs[id] = {fav = tab.Fav or nil, hidden = tab.Hidden or nil, order = tab.Fav and tab.FavOrder or nil} end
		end
		for id, rec in pairs(win.Registry) do
			local d = {}
			local o = rec.Obj
			if STATEFUL[rec.Kind] and o then
				if rec.Kind == "dropdown" then d.value = o:GetList()
				elseif rec.Kind == "colorpicker" then local c = o:Get(); d.value = {c.R, c.G, c.B}
				elseif rec.Kind == "keybind" then d.value = o:Get().Name
				else d.value = o:Get() end
			end
			if rec.Fav then d.fav = true; d.order = rec.FavOrder end
			if rec.Hidden then d.hidden = true end
			if next(d) ~= nil then s.elements[id] = d end
			if rec.Float then s.floating[id] = rec.Float.Export() end
		end
		return s
	end

	local function applyState(st)
		if type(st) ~= "table" then return false end
		if st.theme and THEMES[st.theme] then Pingo.SetTheme(st.theme) end
		local m = st.menu or {}
		if m.size and win.SizeStepper then win.SizeStepper:Set(m.size) end
		if m.locked ~= nil and win.LockToggle then win.LockToggle:Set(m.locked == true) end
		if m.notify ~= nil and win.NotifyToggle then win.NotifyToggle:Set(m.notify == true) end
		if m.reduce ~= nil and win.MotionToggle then win.MotionToggle:Set(m.reduce == true) end
		if m.blur ~= nil and win.BlurToggle then win.BlurToggle:Set(m.blur == true) end

		local tabs = st.tabs or {}
		for id, tab in pairs(win.TabRegistry) do
			local d = tabs[id] or {}
			setTabHidden(tab, d.hidden == true)
			setTabFav(tab, d.fav == true)
			if d.fav and d.order then tab.FavOrder = d.order; if d.order > win.FavCounter then win.FavCounter = d.order end end
		end
		for _, sd in ipairs(win.SideTabs) do layoutTabs(sd, true) end

		local els = st.elements or {}
		for id, rec in pairs(win.Registry) do
			local d = els[id] or {}
			setElementHidden(rec, d.hidden == true, true)
			setElementFav(rec, d.fav == true)
			if d.fav and d.order then rec.FavOrder = d.order; rec.Outer.LayoutOrder = -(10000 + d.order); if d.order > win.FavCounter then win.FavCounter = d.order end end
			if STATEFUL[rec.Kind] and d.value ~= nil and rec.Obj then
				pcall(function()
					if rec.Kind == "colorpicker" then
						rec.Obj:Set(Color3.new(d.value[1], d.value[2], d.value[3]))
					elseif rec.Kind == "keybind" then
						rec.Obj:Set(Enum.KeyCode[d.value] or Enum.KeyCode.E)
					else
						rec.Obj:Set(d.value, true)
					end
				end)
			end
		end

		local fls = st.floating or {}
		for id, rec in pairs(win.Registry) do
			if fls[id] then
				if rec.Float then removeFloating(rec, true) end
				createFloating(rec, fls[id])
			elseif rec.Float then removeFloating(rec) end
		end
		return true
	end

	local function readProfile(name)
		local raw = FS.read(name)
		if not raw then return nil end
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		return (ok and type(data) == "table") and data or nil
	end

	function win:ListConfigs() return FS.list() end
	function win:SaveConfig(name)
		name = sanitize(name)
		if name == "" then return false end
		return FS.write(name, HttpService:JSONEncode(collectState()))
	end
	function win:LoadConfig(name)
		local data = readProfile(sanitize(name))
		if not data then return false end
		return applyState(data)
	end
	function win:LoadAutoConfig()
		local n = FS.getAuto()
		if n and FS.exists(n) then
			if win:LoadConfig(n) then win:Notify("Auto-Load", "Applied auto config: \"" .. n .. "\".", 3); return true end
		end
		return false
	end

	-- Built-in System SideTabs
	local ThemesST = createSideTab("Themes", ICON.Themes, 1)
	local ConfigST = createSideTab("Config", ICON.Config, 2)
	local SettingsST = createSideTab("Settings", ICON.Settings, 3)

	-- Themes Gallery Tab
	local Gallery = createTab(ThemesST, "Gallery", {System = true, CellSize = UDim2.new(0.25, -9, 0, 96)})
	local ringList = {}
	for _, info in ipairs(THEME_LIST) do
		local tname = info[1]
		local body = newCard(tname)
		new("Frame", {Name = "Swatch", Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -34), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = body}, {
			corner(6),
			new("UIGradient", {Rotation = 25, Color = ColorSequence.new(info[2], info[3])}),
		})
		mkText("TextLabel", {Text = tname, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 10, 1, -26), Size = UDim2.new(1, -20, 0, 22), Parent = body})
		local ring = new("Frame", {Name = "Ring", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = body}, {corner(8)})
		local rs = new("UIStroke", {Thickness = 2, Color = info[2], Transparency = (tname == currentTheme) and 0 or 1, Parent = ring})
		ringList[tname] = rs
		local hit = hitButton(body)
		hover(body, hit)
		pressFx(body, hit)
		hit.MouseButton1Click:Connect(function() Pingo.SetTheme(tname) end)
		finish(Gallery, body, {Name = tname, Searchable = false}, "theme", nil, {hit})
	end

	-- Custom Theme Tab
	local CustomTab = createTab(ThemesST, "Custom Theme", {System = true})
	local customAcc1 = rgb(140, 80, 255)
	local customAcc2 = rgb(255, 90, 180)

	CustomTab:AddColorpicker("Primary Accent", customAcc1, function(c)
		customAcc1 = c
		Pingo.SetTheme("Custom", customAcc1, customAcc2)
	end)
	CustomTab:AddColorpicker("Secondary Accent", customAcc2, function(c)
		customAcc2 = c
		Pingo.SetTheme("Custom", customAcc1, customAcc2)
	end)
	CustomTab:AddButton("Apply Custom Theme", function()
		Pingo.SetTheme("Custom", customAcc1, customAcc2)
		win:Notify("Theme Applied", "Custom RGB Theme activated!", 2.5)
	end)

	themeListeners[win] = function()
		for tname, rs in pairs(ringList) do tw(rs, 0.25, {Transparency = (tname == currentTheme) and 0 or 1}) end
	end

	-- Settings Tab
	local General = createTab(SettingsST, "General", {System = true})
	win.SizeStepper = General:AddStepper("Menu Scale", 60, 140, 100, 10, function(v) win:SetSizeMultiplier(v / 100) end, {
		Format = function(v) return v .. "%" end, Description = "Adjust UI overall size",
	})
	win.LockToggle = General:AddToggle("Lock Position", false, function(s)
		win.Locked = s
		win:Notify("Lock State", s and "Window position locked." or "Window position unlocked.", 2.5)
	end, {Description = "Disable dragging interface"})
	
	win.BlurToggle = General:AddToggle("Background Blur", true, function(s)
		win.BlurEnabled = s
		setBlurState(s)
	end, {Description = "Enable background depth-of-field blur"})
	
	win.NotifyToggle = General:AddToggle("Enable Notifications", true, function(s) win.NotifyEnabled = s end, {Description = "Toggle pop-up alerts"})
	win.MotionToggle = General:AddToggle("Reduce Motion", false, function(s) win.ReduceMotion = s end, {Description = "Disable entrance animations"})

	General:AddButton("Center Window", function() tw(Holder, 0.5, {Position = UDim2.fromScale(0.5, 0.5)}, Q) end, {Description = "Reset position to screen center"})

	local About = createTab(SettingsST, "About", {System = true})
	About:AddLabel("Version", version)
	About:AddLabel("Library Engine", "Pingo UI " .. Pingo.Version)

	-- Profile Profiles Management
	local ProfilesTab = createTab(ConfigST, "Profiles", {System = true, Layout = "list"})
	do
		local page = ProfilesTab.Page
		local cfg = {Selected = nil, Rows = {}}

		local top = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 1, Parent = page})
		local nameWrap = new("Frame", {Size = UDim2.new(1, -258, 1, 0), BorderSizePixel = 0, Parent = top}, {corner(9)})
		bind(nameWrap, "BackgroundColor3", "Sidebar")
		local nws = new("UIStroke", {Thickness = 1, Parent = nameWrap})
		bind(nws, "Color", "Stroke")
		local nameBox = mkText("TextBox", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Text = "", PlaceholderText = "Config Name...", Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = nameWrap}, "Text")
		bind(nameBox, "PlaceholderColor3", "SubText")

		local createBtn = pill(top, {Text = "Create", Style = "Primary"}, {Size = UDim2.fromOffset(78, 40), Position = UDim2.new(1, -252, 0, 0), Radius = 9, TextSize = 12})
		local saveBtn = pill(top, {Text = "Save"}, {Size = UDim2.fromOffset(78, 40), Position = UDim2.new(1, -168, 0, 0), Radius = 9, TextSize = 12})
		local folderBtn = pill(top, {Text = "Folder"}, {Size = UDim2.fromOffset(78, 40), Position = UDim2.new(1, -84, 0, 0), Radius = 9, TextSize = 12})

		local listFrame = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = page}, {
			new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
		local emptyLbl = mkText("TextLabel", {Text = "No saved profiles found", Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(1, 0, 0, 100), LayoutOrder = 4, Visible = false, Parent = page}, "SubText")

		local function paintSelection()
			for name, r in pairs(cfg.Rows) do
				local sel = name == cfg.Selected
				tw(r.stroke, 0.2, {Color = sel and T("Accent") or T("Stroke"), Transparency = sel and 0.1 or 0.35})
				r.bar.Visible = sel
			end
		end

		local refresh
		local function doLoad(name)
			if win:LoadConfig(name) then win:Notify("Config Loaded", "\"" .. name .. "\" applied successfully.", 3)
			else win:Notify("Load Error", "Failed to load profile: \"" .. name .. "\".", 3) end
		end
		local function doAuto(name)
			if FS.getAuto() == name then FS.setAuto(nil); win:Notify("Auto-Load", "Disabled auto-load.", 2.5)
			else FS.setAuto(name); win:Notify("Auto-Load", "\"" .. name .. "\" set as default profile.", 3) end
			refresh()
		end
		local function doDelete(name)
			win:Popup({
				Title = "Delete Profile?", Text = "Are you sure you want to delete \"" .. name .. "\"?",
				Buttons = {{Text = "Cancel"}, {Text = "Delete", Style = "Danger", Callback = function()
					FS.delete(name)
					if FS.getAuto() == name then FS.setAuto(nil) end
					if cfg.Selected == name then cfg.Selected = nil end
					refresh(); win:Notify("Deleted", "\"" .. name .. "\" removed.", 2.5)
				end}}},
			})
		end

		local function buildRow(name, i, autoName)
			local data = readProfile(name)
			local sub = "Saved Config Profile"
			if data then
				local cnt = 0; for _ in pairs(data.elements or {}) do cnt = cnt + 1 end
				sub = (data.saved and os.date("%b %d  %H:%M", data.saved) or "Saved") .. "  •  " .. cnt .. " Settings"
			end
			local row = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = i, Parent = listFrame})
			local body = new("TextButton", {Name = "Body", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), AutoButtonColor = false, Text = "", BorderSizePixel = 0, Parent = row}, {corner(10)})
			bind(body, "BackgroundColor3", "Card")
			local stroke = new("UIStroke", {Thickness = 1, Transparency = 0.35, Parent = body})
			bind(stroke, "Color", "Stroke")
			local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 26), BorderSizePixel = 0, Visible = false, Parent = body}, {corner(2)})
			bind(bar, "BackgroundColor3", "Accent")
			local ic = new("ImageLabel", {Image = icon(ICON.Config), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Parent = body})
			bind(ic, "ImageColor3", "Accent")
			mkText("TextLabel", {Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(50, 9), Size = UDim2.new(1, -140, 0, 18), Parent = body})
			mkText("TextLabel", {Text = sub, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(50, 28), Size = UDim2.new(1, -140, 0, 16), Parent = body}, "SubText")
			
			if autoName == name then
				local chip = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(58, 20), BorderSizePixel = 0, BackgroundTransparency = 0.8, Parent = body}, {corner(10)})
				bind(chip, "BackgroundColor3", "Accent")
				mkText("TextLabel", {Text = "AUTO", Font = Enum.Font.GothamBold, TextSize = 10, Size = UDim2.fromScale(1, 1), Parent = chip}, "Accent")
			end
			
			cfg.Rows[name] = {stroke = stroke, bar = bar}
			body.MouseEnter:Connect(function() tw(body, 0.22, {Position = UDim2.new(0.5, 0, 0.5, -2)}, Q) end)
			body.MouseLeave:Connect(function() tw(body, 0.25, {Position = UDim2.fromScale(0.5, 0.5)}, Q) end)
			body.MouseButton1Click:Connect(function()
				if hold.consumed then return end
				cfg.Selected = name; nameBox.Text = ""; paintSelection()
			end)
			attachHold(body, function(pos)
				cfg.Selected = name; paintSelection()
				local isAuto = FS.getAuto() == name
				openMenu("Properties", name, {
					{Text = isAuto and "Remove Auto-Load" or "Set Auto-Load", Callback = function() doAuto(name) end},
					{Text = "Load Profile", Callback = function() doLoad(name) end},
					{Text = "Delete Profile", Style = "Danger", Callback = function() doDelete(name) end},
				}, pos)
			end)
		end

		refresh = function()
			for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("Frame") then unbindTree(c); c:Destroy() end end
			cfg.Rows = {}
			local profiles = FS.list()
			local autoName = FS.getAuto()
			for i, n in ipairs(profiles) do buildRow(n, i, autoName) end
			emptyLbl.Visible = #profiles == 0
			if cfg.Selected and not cfg.Rows[cfg.Selected] then cfg.Selected = nil end
			paintSelection()
		end

		createBtn.MouseButton1Click:Connect(function()
			local name = sanitize(nameBox.Text)
			if name == "" then win:Notify("Profile Error", "Please enter a profile name.", 2.5) return end
			if FS.exists(name) then win:Notify("Profile Error", "\"" .. name .. "\" already exists.", 3) return end
			if win:SaveConfig(name) then
				cfg.Selected = name; nameBox.Text = ""; refresh()
				win:Notify("Profile Created", "\"" .. name .. "\" saved successfully.", 3)
			end
		end)
		saveBtn.MouseButton1Click:Connect(function()
			local name = cfg.Selected or sanitize(nameBox.Text)
			if name == "" then win:Notify("Save Error", "Select a profile to overwrite.", 2.5) return end
			if win:SaveConfig(name) then cfg.Selected = name; nameBox.Text = ""; refresh(); win:Notify("Saved", "\"" .. name .. "\" updated.", 2.5) end
		end)
		folderBtn.MouseButton1Click:Connect(function()
			if type(setclipboard) == "function" then setclipboard(FS.Path); win:Notify("Clipboard", "Folder path copied.", 3) end
		end)

		refresh()
		win.RefreshProfiles = refresh
	end

	-- Cleanup & Unload Logic
	local unloadHooks = {}
	function win:OnUnload(fn) table.insert(unloadHooks, fn) end

	function win:Destroy()
		for _, c in ipairs(win.Conns) do pcall(function() c:Disconnect() end) end
		themeListeners[win] = nil
		if blurEffect then tw(blurEffect, 0.2, {Size = 0}) end
		unbindTree(gui)
		gui:Destroy()
	end

	function win:Unload()
		if win.Unloaded then return end
		win.Unloaded = true
		if win.Opened then win:Toggle(false) end
		task.delay(0.35, function()
			for _, fn in ipairs(unloadHooks) do pcall(fn) end
			if config.OnUnload then pcall(config.OnUnload) end
			win:Destroy()
		end)
	end

	-- Startup Execution
	task.defer(function()
		if not win.UserSelected then selectSideTab(ThemesST) end
		if not config.StartHidden then win:Toggle(true) end
		task.delay(config.AutoLoadDelay or 0.6, function()
			if not win.Unloaded then win:LoadAutoConfig() end
		end)
	end)

	return win
end

return Pingo
