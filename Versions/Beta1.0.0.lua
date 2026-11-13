--[[ Pingo UI Library | v1.2.0 (Redz Hub Style & Top Controls) -----------------------------------
 HOLD (0.8s) on any Tab or Element to open the "Properties" menu:
 Tab -> Favourite / Hide / Reset Tab (hidden tabs live in the "Hidden" tab)
 Element -> Floating Button|Slider / Favourite / Hide (Reset for inputs)
 Floating -> Lock|Move / Resize / Hide
-------------------------------------------------------------------------------------------------- ]]

local Pingo = {Version = "1.2.0", Name = "Pingo", TintIcons = true}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local Q = Enum.EasingStyle.Quint
local BACK = Enum.EasingStyle.Back
local QUAD = Enum.EasingStyle.Quad
local IN = Enum.EasingDirection.In
local GAP = 10
local CELL_H = 64
local HOLD_TIME = 0.8

local ICON = {
	Star = 5078542968,
	Minus = 12338394619,
	Plus = 12338396009,
	Search = 6031154871,
	Copy = 103287906385313,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function tw(obj, t, props, style, dir)
	if not obj then return end
	local tween = TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
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

local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r)}) end

local function icon(i)
	if not i then return nil end
	if type(i) == "number" then return "rbxassetid://" .. i end
	if tostring(i):match("^%d+$") then return "rbxassetid://" .. i end
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

-- ============================================================
-- THEMES (32)
-- ============================================================
local BASE = {
	Background = rgb(18, 19, 24), Sidebar = rgb(24, 25, 31), Card = rgb(32, 34, 42),
	Off = rgb(55, 58, 70), Text = rgb(240, 240, 245), SubText = rgb(140, 145, 160),
	White = rgb(255, 255, 255), Stroke = rgb(44, 46, 58),
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
	{"Sun", rgb(240, 225, 50), rgb(190, 255, 70)},
	{"Lemon", rgb(235, 255, 90), rgb(160, 255, 130)},
	{"Lime", rgb(110, 255, 70), rgb(50, 230, 140)},
	{"Mint", rgb(120, 255, 190), rgb(90, 230, 230)},
	{"Emerald", rgb(46, 220, 130), rgb(30, 200, 200)},
	{"Forest", rgb(60, 180, 90), rgb(140, 220, 90)},
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
	{"Gurple", rgb(140, 60, 235), rgb(60, 120, 255)},
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
for _, t in ipairs(THEME_LIST) do
	local d = {Accent = t[2], Accent2 = t[3], AccentDark = t[2]:Lerp(BLACK, 0.35), Accent2Dark = t[3]:Lerp(BLACK, 0.35)}
	for k, v in pairs(BASE) do d[k] = v end
	THEMES[t[1]] = d
end

local currentTheme = "Ruby"
local function T(key) return THEMES[currentTheme][key] end
local bindings = setmetatable({}, {__mode = "k"})
local gradients = setmetatable({}, {__mode = "k"})
local themeListeners = {}

local function bind(obj, prop, key, animate)
	local b = bindings[obj]
	if not b then b = {}; bindings[obj] = b end
	b[prop] = key
	if animate then tw(obj, 0.25, {[prop] = T(key)}) else obj[prop] = T(key) end
end

local function unbindTree(root)
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
		pts[i] = ColorSequenceKeypoint.new((i - 1) / (n - 1), T(k))
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

function Pingo.SetTheme(name)
	if not THEMES[name] then return end
	currentTheme = name
	for obj, b in pairs(bindings) do
		if obj.Parent then
			for prop, key in pairs(b) do
				local target = T(key)
				if obj[prop] ~= target then tw(obj, 0.35, {[prop] = target}) end
			end
		end
	end
	for g, keys in pairs(gradients) do
		if g.Parent then g.Color = seq(keys) end
	end
	for _, fn in pairs(themeListeners) do pcall(fn) end
end

function Pingo.GetThemeNames()
	local list = {}
	for _, t in ipairs(THEME_LIST) do table.insert(list, t[1]) end
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

local function header(body, o, rs, rp, regionH)
	regionH = regionH or CELL_H
	rs, rp = rs or 0, rp or 12
	local x = 14
	if o.Icon then
		local img = new("ImageLabel", {Name = "Icon", Image = icon(o.Icon), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0, regionH / 2), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 2, Parent = body})
		if o.IconColor then
			img.ImageColor3 = o.IconColor
		elseif o.Tint ~= false and Pingo.TintIcons then
			bind(img, "ImageColor3", "Accent")
		end
		x = 46
	end
	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local nameY = hasDesc and (regionH / 2 - 16) or 0
	local nameH = hasDesc and 16 or regionH
	local nameLbl = mkText("TextLabel", {
		Text = tostring(o.Name), Font = Enum.Font.GothamBold, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(x, nameY), Size = UDim2.new(1 - rs, -(x + rp), 0, nameH), Parent = body,
	})
	local descLbl
	if hasDesc then
		descLbl = mkText("TextLabel", {
			Text = tostring(o.Description), Font = Enum.Font.Gotham, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(x, nameY + 17), Size = UDim2.new(1 - rs, -(x + rp), 0, 14), Parent = body,
		}, "SubText")
	end
	return nameLbl, descLbl
end

local function pill(parent, spec, props)
	spec = spec or {}
	props = props or {}
	local style = spec.Style or "Default"
	local b = new("TextButton", {
		Name = "Pill", Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = props.Size or UDim2.fromOffset(100, 32), Position = props.Position or UDim2.new(),
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
		new("ImageLabel", {Image = ico, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = b})
		textX = 14
	end
	local lbl = mkText("TextLabel", {Text = tostring(spec.Text or "Button"), Font = Enum.Font.GothamBold, TextSize = props.TextSize or 12, Position = UDim2.fromOffset(textX, 0), Size = UDim2.new(1, -textX, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = b}, style == "Default" and "Text" or "White")
	local sc = new("UIScale", {Parent = b})
	b.MouseEnter:Connect(function() tw(sc, 0.18, {Scale = 1.04}, BACK) end)
	b.MouseLeave:Connect(function() tw(sc, 0.2, {Scale = 1}) end)
	b.MouseButton1Down:Connect(function() tw(sc, 0.08, {Scale = 0.94}) end)
	b.MouseButton1Up:Connect(function() tw(sc, 0.25, {Scale = 1.04}, BACK) end)
	return b, lbl
end

-- ============================================================
-- WINDOW
-- ============================================================
function Pingo.CreateWindow(title, version, config)
	config = config or {}
	title = title or "Pingo"
	version = version or Pingo.Version
	local W, H = config.Width or 660, config.Height = config.Height or 420
	if config.Theme and THEMES[config.Theme] then currentTheme = config.Theme end

	local win = {
		SideTabs = {}, Elements = {}, Registry = {}, TabRegistry = {}, UsedIds = {}, Conns = {}, Floats = {},
		Counter = 0, FavCounter = 0, FloatCount = 0,
		Opened = false, SearchText = "", SizeMul = 1, Locked = false, NotifyEnabled = true, ReduceMotion = false,
	}

	local function A(signal, fn)
		local c = signal:Connect(fn)
		table.insert(win.Conns, c)
		return c
	end

	local selectTab, selectSideTab, layoutTabs, openMenu, closeMenu, openTabMenu, openElementMenu, openFloatMenu
	local createFloating, removeFloating, setElementFav, setElementHidden, setTabFav, setTabHidden
	local recountHidden, openDropdownPanel

	local guiName = "Pingo_" .. title
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

	local Holder = new("Frame", {Name = "Holder", Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui})
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

	local Main = new("CanvasGroup", {Name = "Main", Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 0, GroupTransparency = 1, Parent = Holder}, {corner(12)})
	bind(Main, "BackgroundColor3", "Background")
	local openScale = new("UIScale", {Scale = 0.88, Parent = Main})
	local mainStroke = new("UIStroke", {Thickness = 1.5, Parent = Main})
	bind(mainStroke, "Color", "Stroke")

	local function aura(x, y, size, dx, dy, dur)
		local a = new("Frame", {Size = UDim2.fromOffset(size, size), Position = UDim2.fromScale(x, y), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0.93, BorderSizePixel = 0, Parent = Main}, {corner(size / 2)})
		bind(a, "BackgroundColor3", "Accent")
		TweenService:Create(a, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.fromScale(x + dx, y + dy)}):Play()
	end
	aura(0.75, 0.3, 300, 0.12, 0.2, 7)
	aura(0.55, 0.85, 240, -0.15, -0.15, 9)

	local Sidebar = new("Frame", {Name = "Sidebar", Size = UDim2.new(0, 170, 1, 0), BorderSizePixel = 0, Parent = Main})
	bind(Sidebar, "BackgroundColor3", "Sidebar")

	local divider = new("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BorderSizePixel = 0, Parent = Sidebar})
	bind(divider, "BackgroundColor3", "Stroke")

	local dragArea = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Active = true, Parent = Sidebar})
	makeDraggable(dragArea, Holder, nil, menuCanDrag)

	local titleRow = new("Frame", {Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 42), BackgroundTransparency = 1, Parent = Sidebar}, {
		new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}),
	})

	local titleLbl = mkText("TextLabel", {
		Text = title, Font = Enum.Font.GothamBold, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = titleRow
	}, "Accent")

	local tg = grad({"Accent", "Accent2", "Accent"}, titleLbl, {Offset = Vector2.new(-0.6, 0)})
	TweenService:Create(tg, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.6, 0)}):Play()

	mkText("TextLabel", {
		Text = version, Font = Enum.Font.Gotham, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 15), LayoutOrder = 2, Parent = titleRow
	}, "Accent")

	local Nav = new("Frame", {Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, -1, 1, -62), BackgroundTransparency = 1, Parent = Sidebar})
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
			tw(Pill, 0.38, {Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 38)}, Q)
		end)
	end

	local Content = new("Frame", {Name = "Content", Position = UDim2.fromOffset(170, 0), Size = UDim2.new(1, -170, 1, 0), BackgroundTransparency = 1, Parent = Main})
	local dragTop = new("Frame", {Size = UDim2.new(1, -70, 0, 12), BackgroundTransparency = 1, Active = true, Parent = Content})
	makeDraggable(dragTop, Holder, nil, menuCanDrag)

	-- ==========================================================
	-- TOP WINDOW CONTROLS (- & X) مثل Redz Hub
	-- ==========================================================
	local topControls = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(60, 24), BackgroundTransparency = 1, ZIndex = 30, Parent = Content})
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})

	local function winBtn(glyph, cb)
		local b = new("TextButton", {Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.9, Text = glyph, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, BorderSizePixel = 0, Parent = topControls}, {corner(6)})
		bind(b, "TextColor3", "SubText")
		b.MouseEnter:Connect(function() tw(b, 0.15, {BackgroundTransparency = 0.7}); bind(b, "TextColor3", "Accent", true) end)
		b.MouseLeave:Connect(function() tw(b, 0.2, {BackgroundTransparency = 0.9}); bind(b, "TextColor3", "SubText", true) end)
		b.MouseButton1Click:Connect(cb)
		return b
	end

	winBtn("-", function() win:Toggle(false) end)
	winBtn("×", function() win:Unload() end)

	local topLine = new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 50, Parent = Main})
	local lg = grad({"Accent", "Accent2", "Accent"}, topLine, {Offset = Vector2.new(-1, 0)})
	TweenService:Create(lg, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false), {Offset = Vector2.new(1, 0)}):Play()

	local SearchBar = new("Frame", {Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 38), BorderSizePixel = 0, Parent = Content}, {corner(8)})
	bind(SearchBar, "BackgroundColor3", "Sidebar")
	local searchStroke = new("UIStroke", {Thickness = 1, Parent = SearchBar})
	bind(searchStroke, "Color", "Stroke")

	local searchIcon = new("ImageLabel", {Image = icon(ICON.Search), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = SearchBar})
	bind(searchIcon, "ImageColor3", "SubText")

	local SearchBox = mkText("TextBox", {Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -48, 1, 0), Text = "", PlaceholderText = "Search...", Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = SearchBar}, "Text")
	bind(SearchBox, "PlaceholderColor3", "SubText")

	SearchBox.Focused:Connect(function() bind(searchStroke, "Color", "Accent", true); tw(searchIcon, 0.2, {Size = UDim2.fromOffset(21, 21)}, BACK) end)
	SearchBox.FocusLost:Connect(function() bind(searchStroke, "Color", "Stroke", true); tw(searchIcon, 0.2, {Size = UDim2.fromOffset(18, 18)}) end)

	local TabBarHolder = new("Frame", {Position = UDim2.fromOffset(16, 60), Size = UDim2.new(1, -32, 0, 36), BackgroundTransparency = 1, Parent = Content})
	local PagesHolder = new("Frame", {Position = UDim2.fromOffset(16, 106), Size = UDim2.new(1, -32, 1, -118), BackgroundTransparency = 1, ClipsDescendants = true, Parent = Content})

	local SearchPage = new("ScrollingFrame", {Name = "SearchPage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, Parent = PagesHolder}, {
		new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}),
		new("UIListLayout", {Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	bind(SearchPage, "ScrollBarImageColor3", "SubText")

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
				task.delay((i - 1) * 0.03, function()
					if body.Parent then tw(body, 0.5, {Position = UDim2.fromScale(0.5, 0.5)}, Q) end
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
		tw(g, 0.45, {Position = UDim2.new()}, Q)
		tw(g, 0.32, {GroupTransparency = 0})
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
		if animate then tw(st.TabInd, 0.4, {Position = p, Size = s}, Q) else st.TabInd.Position, st.TabInd.Size = p, s end
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
		tw(st.TabInd, 0.15, {Position = p1, Size = s1}, QUAD)
		task.delay(0.11, function()
			if st.IndToken ~= my then return end
			tw(st.TabInd, 0.4, {Position = p2, Size = s2}, Q)
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
				tw(t.Button, 0.4, {Position = pos, Size = size}, Q)
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
			tw(o.Label, 0.3, {Position = UDim2.new(0, o.Pad + (active and 5 or 0), 0, 0)}, Q)
			if o.Icon then
				bind(o.Icon, "ImageColor3", active and "White" or "Text", true)
				if active and was ~= st then o.Icon.Rotation = -25; tw(o.Icon, 0.5, {Rotation = 0}, BACK) end
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
				bar.Position = UDim2.fromOffset(0, -12)
				tw(bar, 0.4, {Position = UDim2.new()}, Q)
				tw(bar, 0.3, {GroupTransparency = 0})
			end
		end
		local t = st.ActiveTab or firstVisibleTab(st)
		if t then selectTab(t) else hideAllPages() end
	end

	local function homePage(rec)
		if rec.Hidden then return rec.Tab.SideTab.HiddenTab.Page end
		return rec.Tab.Page
	end

	local searchAnimationToken = 0
	local function animateSearchResult(rec, index)
		if win.ReduceMotion then return end
		local body = rec.Body
		if not body or not body.Parent then return end
		local scale = body:FindFirstChild("Scale")
		searchAnimationToken = searchAnimationToken + 1
		local token = searchAnimationToken
		body.GroupTransparency = 1
		if scale then scale.Scale = 0.92 end
		body.Position = UDim2.new(0.5, 0, 0.5, 10)
		task.delay(math.min(index * 0.025, 0.28), function()
			if not body.Parent or not rec.Outer.Parent then return end
			tw(body, 0.32, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, Q)
			if scale then tw(scale, 0.42, {Scale = 1}, BACK) end
		end)
	end

	local function performSearch(q)
		q = string.lower(q):gsub("^%s+", ""):gsub("%s+$", "")
		win.SearchText = q
		if q == "" then
			for _, rec in ipairs(win.Elements) do if rec.Outer.Parent == SearchPage then rec.Outer.Parent = homePage(rec) end end
			SearchPage.Visible = false
			TabBarHolder.Visible = true
			local ct = win.CurrentTab
			if ct and ct.SideTab == win.ActiveSideTab then local g = ct.Group; g.Position = UDim2.new(); g.GroupTransparency = 0; g.ZIndex = 2; g.Visible = true end
			return
		end
		hideAllPages()
		TabBarHolder.Visible = false
		SearchPage.Visible = true
		local shownCount = 0
		for _, rec in ipairs(win.Elements) do
			if string.find(rec.Search, q, 1, true) then
				shownCount = shownCount + 1
				if rec.Outer.Parent ~= SearchPage then rec.Outer.Parent = SearchPage end
				animateSearchResult(rec, shownCount)
			elseif rec.Outer.Parent == SearchPage then rec.Outer.Parent = homePage(rec) end
		end
	end
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function() performSearch(SearchBox.Text) end)

	local function newCard(name)
		win.Counter = win.Counter + 1
		local outer = new("Frame", {Name = tostring(name), Size = UDim2.new(1, 0, 0, CELL_H), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = win.Counter})
		local body = new("CanvasGroup", {Name = "Body", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), GroupTransparency = 0, BorderSizePixel = 0, Parent = outer}, {corner(8)})
		bind(body, "BackgroundColor3", "Card")
		local st = new("UIStroke", {Name = "CardStroke", Thickness = 1, Transparency = 0.35, Parent = body})
		bind(st, "Color", "Stroke")
		new("UIScale", {Name = "Scale", Parent = body})
		new("Frame", {Name = "Shine", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = body}, {corner(8)})
		new("Frame", {Name = "Ripples", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = body}, {corner(8)})
		return body
	end

	local revealedItems = setmetatable({}, {__mode = "k"})
	local function revealVisible(page)
		if win.ReduceMotion or not page.Visible then return end
		local top, bottom = page.AbsolutePosition.Y, page.AbsolutePosition.Y + page.AbsoluteSize.Y
		for _, item in ipairs(page:GetChildren()) do
			if item:IsA("GuiObject") and item.Visible then
				local y1, y2 = item.AbsolutePosition.Y, item.AbsolutePosition.Y + item.AbsoluteSize.Y
				if y2 >= top and y1 <= bottom and not revealedItems[item] then
					revealedItems[item] = true
					local body = item:FindFirstChild("Body") or (item:IsA("CanvasGroup") and item)
					if body and body:IsA("CanvasGroup") then
						local scale = body:FindFirstChild("Scale")
						body.GroupTransparency = 1
						body.Position = UDim2.new(0.5, 0, 0.5, 9)
						if scale then scale.Scale = 0.96 end
						tw(body, 0.38, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, Q)
						if scale then tw(scale, 0.42, {Scale = 1}, BACK) end
					end
				end
			end
		end
	end

	local function watchScroll(page)
		page:GetPropertyChangedSignal("CanvasPosition"):Connect(function() revealVisible(page) end)
		page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() task.defer(function() revealVisible(page) end) end)
		page.ChildAdded:Connect(function() task.defer(function() revealVisible(page) end) end)
		task.defer(function() revealVisible(page) end)
	end
	watchScroll(SearchPage)

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
		local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(fx, fy), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = holder}, {corner(200)})
		tw(r, 0.6, {Size = UDim2.fromOffset(300, 300), BackgroundTransparency = 1}, Q)
		task.delay(0.65, function() r:Destroy() end)
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

	local menuOpen, closeMenu, openMenu
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
		local MW, ROW = 214, 36
		local MH = 54 + #items * ROW + 8
		local root = new("TextButton", {Name = "PingoMenu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 40, Parent = gui})
		root.MouseButton1Click:Connect(function() closeMenu() end)
		local x, y = pos.X + 8, pos.Y + 8
		if x + MW > vp.X - 8 then x = pos.X - MW - 8 end
		if y + MH > vp.Y - 8 then y = pos.Y - MH - 8 end
		x, y = math.max(8, x), math.max(8, y)
		local card = new("CanvasGroup", {Position = UDim2.fromOffset(x, y + 10), Size = UDim2.fromOffset(MW, MH), BackgroundTransparency = 0, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 41, Active = true, Parent = root}, {corner(12)})
		bind(card, "BackgroundColor3", "Sidebar")
		local scale = new("UIScale", {Scale = 0.9, Parent = card})
		local cs = new("UIStroke", {Thickness = 1.5, Transparency = 0.35, Parent = card})
		bind(cs, "Color", "Accent")
		local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = card})
		grad({"Accent", "Accent2"}, bar)
		mkText("TextLabel", {Text = string.upper(heading), Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 11), Size = UDim2.new(1, -28, 0, 12), Parent = card}, "SubText")
		mkText("TextLabel", {Text = tostring(subject), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(14, 24), Size = UDim2.new(1, -28, 0, 20), Parent = card})
		local sep = new("Frame", {Position = UDim2.fromOffset(12, 49), Size = UDim2.new(1, -24, 0, 1), BorderSizePixel = 0, Parent = card})
		bind(sep, "BackgroundColor3", "Stroke")
		for i, it in ipairs(items) do
			local row = new("TextButton", {Position = UDim2.fromOffset(20, 54 + (i - 1) * ROW), Size = UDim2.new(1, -16, 0, ROW - 4), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = card}, {corner(8)})
			local tx = 12
			if it.Icon then
				local im = new("ImageLabel", {Image = icon(it.Icon), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = row})
				bind(im, "ImageColor3", "Accent")
				tx = 34
			end
			local lbl = mkText("TextLabel", {Text = it.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -tx - 8, 1, 0), Parent = row}, "Text")
			if it.Style == "Danger" then lbl.TextColor3 = rgb(255, 95, 110); bindings[lbl] = nil end
			row.MouseEnter:Connect(function() tw(row, 0.15, {BackgroundTransparency = 0.92}) end)
			row.MouseLeave:Connect(function() tw(row, 0.2, {BackgroundTransparency = 1}) end)
			row.MouseButton1Click:Connect(function()
				closeMenu()
				if it.Callback then task.spawn(it.Callback) end
			end)
			row.Position = UDim2.fromOffset(34, 54 + (i - 1) * ROW)
			task.delay(0.04 + i * 0.035, function()
				if row.Parent then tw(row, 0.4, {Position = UDim2.fromOffset(8, 54 + (i - 1) * ROW)}, Q) end
			end)
		end
		menuOpen = {root = root, card = card, scale = scale}
		tw(card, 0.4, {Position = UDim2.fromOffset(x, y)}, Q)
		tw(card, 0.2, {GroupTransparency = 0})
		tw(scale, 0.4, {Scale = 1}, BACK)
	end

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
				rec.Star = new("ImageLabel", {Name = "Star", Image = icon(ICON.Star), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, ZIndex = 4, Parent = rec.Body})
				bind(rec.Star, "ImageColor3", "Accent")
			end
			rec.Star.Visible = true
			tw(rec.Star, 0.4, {Size = UDim2.fromOffset(12, 12)}, BACK)
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
		local sc = rec.Body and rec.Body:FindFirstChild("Scale")
		local function move()
			if rec.Outer.Parent ~= SearchPage then
				rec.Outer.Parent = v and st.HiddenTab.Page or rec.Tab.Page
			end
			if sc then
				sc.Scale = 0.6
				tw(sc, 0.45, {Scale = 1}, BACK)
			end
			recountHidden(st)
		end
		if instant or not sc then
			move()
		else
			tw(sc, 0.22, {Scale = 0.6}, QUAD, IN)
			task.delay(0.24, move)
		end
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
		header(body, {Name = tab.Name, Description = "Hidden tab - tap to open"}, 0, 40)
		mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, -2), Size = UDim2.fromOffset(18, 24), Text = "›", Font = Enum.Font.GothamBold, TextSize = 26, Parent = body}, "SubText")
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
			if tab.Fav then
				tab.Fav = false
				tab.Star.Visible = false
			end
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
		win:Notify("Reset", tab.Name .. " was reset to defaults.", 2.5)
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
		local root = new("TextButton", {Name = "Float", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(FW, FH), Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = gui}, {corner(12)})
		bind(root, "BackgroundColor3", "Card")
		fl.Scale = new("UIScale", {Scale = 0, Parent = root})
		local fs = new("UIStroke", {Thickness = 1.5, Transparency = 0.2, Parent = root})
		bind(fs, "Color", "Accent")
		fl.LockDot = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -7, 0, 7), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = fl.Locked, ZIndex = 8, Parent = root}, {corner(3)})
		if not isSlider then
			local on = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = root}, {corner(12)})
			grad({"Accent", "Accent2"}, on, {Rotation = 15})
			local dot = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = rgb(110, 115, 130), BorderSizePixel = 0, ZIndex = 4, Parent = root}, {corner(6)})
			mkText("TextLabel", {Text = rec.Name, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -52, 1, 0), ZIndex = 4, Parent = root}, "White")
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
			mkText("TextLabel", {Text = rec.Name, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -92, 0, 18), ZIndex = 4, Parent = root})
			local valLbl = mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.fromOffset(70, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = "", ZIndex = 4, Parent = root}, "Accent")
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
		rec.Float = fl
		if rec.Id then win.Floats[rec.Id] = fl end
		tw(fl.Scale, 0.5, {Scale = FLOAT_SCALES[fl.SizeIdx]}, BACK)
		return fl
	end

	local function buildTab(st, name, opts)
		opts = opts or {}
		local tab = {Name = name, SideTab = st, Cards = {}, Recs = {}, System = opts.System == true, Virtual = opts.Virtual == true, Fav = false, Hidden = false, FavOrder = 0}
		local btn = new("TextButton", {Name = name, Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, Visible = false, Parent = st.TabInner})
		bind(btn, "TextColor3", "SubText")
		tab.Button = btn
		tab.Star = new("ImageLabel", {Name = "Star", Image = icon(ICON.Star), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(13, 13), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = btn})
		bind(tab.Star, "ImageColor3", "Accent")
		local group = new("CanvasGroup", {Name = st.Name .. "_" .. name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Parent = PagesHolder})

		local layout = new("UIListLayout", {Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder})
		local page = new("ScrollingFrame", {Name = "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = group}, {
			new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12)}),
			layout,
		})
		bind(page, "ScrollBarImageColor3", "SubText")
		watchScroll(page)
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

		function tab:AddSection(name, description)
			win.Counter = win.Counter + 1
			local outer = new("CanvasGroup", {Name = "Section_" .. tostring(name), Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = win.Counter, Parent = tab.Page})
			mkText("TextLabel", {Text = tostring(name), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Parent = outer}, "Accent")
			local rec = {Name = tostring(name), Kind = "section", Tab = tab, Body = outer, Outer = outer, BaseOrder = outer.LayoutOrder}
			rec.Search = string.lower(rec.Name)
			table.insert(win.Elements, rec)
			if not tab.System then
				rec.Id = makeId(tab, rec.Name)
				win.Registry[rec.Id] = rec
				table.insert(tab.Recs, rec)
			end
			local api = {}
			function api:SetText(t) rec.Outer:FindFirstChildOfClass("TextLabel").Text = tostring(t) end
			function api:SetVisible(v) outer.Visible = v == true end
			return api
		end

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
			local valLbl = mkText("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, hasDesc and 6 or 0), Size = UDim2.fromOffset(68, hasDesc and 16 or 44), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = "", Parent = body}, "Accent")
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

		return tab
	end

	local topCount = 0
	local function createSideTab(name, iconId)
		local st = {Name = name, Tabs = {}, HiddenCount = 0}
		topCount = topCount + 1
		st.Y = 2 + (topCount - 1) * 42
		st.Order = topCount
		local btn = new("TextButton", {Name = name, Position = UDim2.fromOffset(10, st.Y), Size = UDim2.new(1, -20, 0, 38), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, Parent = Nav})
		st.Button = btn
		local pad = 14
		local ico = icon(iconId)
		if ico then
			pad = 42
			st.Icon = new("ImageLabel", {Image = ico, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 13, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = 3, Parent = btn})
			bind(st.Icon, "ImageColor3", "Text")
		end
		st.Pad = pad
		st.Label = mkText("TextLabel", {Text = name, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(pad, 0), Size = UDim2.new(1, -pad - 8, 1, 0), ZIndex = 3, Parent = btn})
		st.TabBar = new("CanvasGroup", {Name = name, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 0, Visible = false, Parent = TabBarHolder}, {corner(8)})
		bind(st.TabBar, "BackgroundColor3", "Sidebar")
		local tbs = new("UIStroke", {Thickness = 1, Parent = st.TabBar})
		bind(tbs, "Color", "Stroke")
		st.TabInner = new("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = st.TabBar})
		st.TabInd = new("Frame", {Name = "Pill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, Parent = st.TabInner}, {corner(6)})
		grad({"AccentDark", "Accent2Dark"}, st.TabInd)
		st.HiddenTab = buildTab(st, "Hidden", {Virtual = true, System = true})
		btn.MouseEnter:Connect(function() if not st.Active then tw(st.Label, 0.25, {Position = UDim2.new(0, pad + 3, 0, 0)}, Q) end end)
		btn.MouseLeave:Connect(function() if not st.Active then tw(st.Label, 0.25, {Position = UDim2.new(0, pad, 0, 0)}, Q) end end)
		btn.MouseButton1Click:Connect(function() selectSideTab(st) end)
		table.insert(win.SideTabs, st)
		function st:CreateTab(tabName) return createTab(st, tabName) end
		return st
	end

	function win:CreateSideTab(name, iconId)
		local st = createSideTab(name, iconId)
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
	end

	local btnText = tostring(config.ButtonText or title)
	local textW = TextService:GetTextSize(btnText, 15, Enum.Font.GothamBold, Vector2.new(400, 46)).X
	local BTN_H = 46
	local BTN_W = math.ceil(7 + 32 + 10 + textW + 20)
	local OpenBtn = new("TextButton", {Name = "PingoOpen", Size = UDim2.fromOffset(BTN_W, BTN_H), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 10, Parent = gui}, {corner(12)})
	grad({"AccentDark", "Accent2Dark"}, OpenBtn, {Rotation = 20})
	local obStroke = new("UIStroke", {Thickness = 1.5, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = OpenBtn})
	bind(obStroke, "Color", "Accent")
	local obScale = new("UIScale", {Parent = OpenBtn})
	local gloss = new("Frame", {Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0.5, -2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 11, Parent = OpenBtn}, {corner(10)})
	new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(1, 1)}), Parent = gloss})
	local sweep = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 12, Parent = OpenBtn}, {corner(12)})
	local sg = new("UIGradient", {Rotation = 20, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.72),
		NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1),
	}), Parent = sweep})
	TweenService:Create(sg, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 3), {Offset = Vector2.new(1, 0)}):Play()

	local iconBox = new("Frame", {Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 13, Parent = OpenBtn}, {corner(9)})
	local iconPop = new("UIScale", {Parent = iconBox})
	if config.Icon then
		new("ImageLabel", {Image = icon(config.Icon), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 14, Parent = iconBox}, {corner(7)})
	else
		new("TextLabel", {Text = string.upper(string.sub(btnText, 1, 1)), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 14, Parent = iconBox})
	end

	new("TextLabel", {Text = btnText, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.fromOffset(49, 0), Size = UDim2.new(1, -49, 1, 0), ZIndex = 13, Parent = OpenBtn})
	OpenBtn.MouseEnter:Connect(function() tw(obScale, 0.25, {Scale = 1.06}, BACK); tw(obStroke, 0.2, {Transparency = 0}) end)
	OpenBtn.MouseLeave:Connect(function() tw(obScale, 0.25, {Scale = 1}, BACK); tw(obStroke, 0.2, {Transparency = 0.15}) end)
	makeDraggable(OpenBtn, OpenBtn, function()
		obScale.Scale = 0.92
		tw(obScale, 0.35, {Scale = 1}, BACK)
		win:Toggle()
	end)
	win.OpenButton = OpenBtn

	local token = 0
	function win:Toggle(state)
		if state == nil then state = not win.Opened end
		if state == win.Opened then return end
		win.Opened = state
		token = token + 1
		local my = token
		iconPop.Scale = 0.75
		tw(iconPop, 0.45, {Scale = 1}, BACK)
		if state then
			Holder.Visible = true
			openScale.Scale = 0.9
			Main.GroupTransparency = 1
			Sidebar.Position = UDim2.fromOffset(-40, 0)
			Content.Position = UDim2.fromOffset(210, 0)
			tw(openScale, 0.5, {Scale = 1}, BACK)
			tw(Main, 0.3, {GroupTransparency = 0})
			Main.Position = UDim2.new(0.5, 0, 0.5, 24)
			tw(Main, 0.6, {Position = UDim2.fromScale(0.5, 0.5)}, Q)
			tw(Sidebar, 0.6, {Position = UDim2.fromOffset(0, 0)}, Q)
			tw(Content, 0.6, {Position = UDim2.fromOffset(170, 0)}, Q)
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

	function win:Notify(nTitle, text, duration)
		print("[" .. nTitle .. "]: " .. text)
	end

	function win:Destroy()
		for _, c in ipairs(win.Conns) do pcall(function() c:Disconnect() end) end
		themeListeners[win] = nil
		unbindTree(gui)
		gui:Destroy()
	end

	function win:Unload()
		if win.Unloaded then return end
		win.Unloaded = true
		if win.Opened then win:Toggle(false) end
		task.delay(0.4, function()
			if config.OnUnload then pcall(config.OnUnload) end
			win:Destroy()
		end)
	end

	task.defer(function()
		if not config.StartHidden then win:Toggle(true) end
	end)

	return win
end

return Pingo
