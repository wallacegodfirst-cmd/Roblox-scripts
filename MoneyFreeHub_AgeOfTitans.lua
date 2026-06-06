--// Money/Free Hub - Age of Titans
--// Sierra-style GUI with full feature set

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local States = {
	ExtendHitbox = false,
	HitboxMultiplier = 5,
	ShowHitbox = false,
	M1Expand = false,
	M1Multiplier = 3,
	InfBlock = false,
	AutoBlock = false,
	SilentAim = false,

	Fly = false,
	FlySpeed = 80,
	Noclip = false,
	SpeedHack = false,
	WalkSpeed = 50,
	AutoSprint = false,
	GodMode = false,
	SaveSystem = false,
	SaveThreshold = 30,
	InstantRespawn = false,
	Invisible = false,

	ESP = false,
	InfZoom = false,

	AutoFarm = false,
	SelectedSkin = "None",

	ScriptEnabled = true,
	Minimized = false,
}

local Connections = {}
local ESPHighlights = {}
local HitboxVisuals = {}
local FlyBody = { velocity = nil, gyro = nil }
local SavedPosition = nil
local IsSaving = false

local function make(className, props, parent)
	local obj = Instance.new(className)
	for prop, value in pairs(props or {}) do
		obj[prop] = value
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local colors = {
	bg = Color3.fromRGB(13, 15, 15),
	panel = Color3.fromRGB(19, 21, 21),
	panel2 = Color3.fromRGB(16, 18, 18),
	border = Color3.fromRGB(3, 6, 8),
	blue = Color3.fromRGB(54, 89, 174),
	text = Color3.fromRGB(235, 235, 235),
	muted = Color3.fromRGB(90, 90, 90),
	button = Color3.fromRGB(22, 24, 24),
	red = Color3.fromRGB(174, 54, 54),
	green = Color3.fromRGB(54, 174, 74),
	checkbox_off = Color3.fromRGB(17, 19, 19),
}

local function addStroke(parent, color, thickness)
	return make("UIStroke", {
		Color = color or colors.border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function addPadding(parent, left, right, top, bottom)
	return make("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	}, parent)
end

local function makeLabel(text, size, pos, parent)
	return make("TextLabel", {
		Name = text .. "Label",
		BackgroundTransparency = 1,
		Position = pos,
		Size = size,
		Text = text,
		TextColor3 = colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = Enum.Font.Code,
		TextSize = 14,
	}, parent)
end

local gui = Instance.new("ScreenGui")
gui.Name = "MoneyFreeHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = make("Frame", {
	Name = "MainFrame",
	BackgroundColor3 = colors.bg,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -310, 0.5, -370),
	Size = UDim2.new(0, 620, 0, 740),
	ClipsDescendants = true,
}, gui)

addStroke(main, Color3.fromRGB(2, 2, 2), 2)

local blueLine = make("Frame", {
	Name = "BlueOutline",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 2, 0, 2),
	Size = UDim2.new(1, -4, 1, -4),
}, main)
addStroke(blueLine, colors.blue, 1)

local titleBar = make("Frame", {
	Name = "TitleBar",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 7, 0, 3),
	Size = UDim2.new(1, -14, 0, 28),
}, main)

local titleText = make("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0.7, 0, 1, 0),
	Text = "Money/Free Hub  |  Age of Titans",
	TextColor3 = colors.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Code,
	TextSize = 15,
}, titleBar)

local minimizeBtn = make("TextButton", {
	Name = "MinimizeBtn",
	BackgroundColor3 = colors.button,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -60, 0, 2),
	Size = UDim2.new(0, 24, 0, 22),
	Text = "_",
	TextColor3 = colors.text,
	Font = Enum.Font.Code,
	TextSize = 16,
	AutoButtonColor = false,
}, titleBar)
addStroke(minimizeBtn, colors.border, 1)

local closeBtn = make("TextButton", {
	Name = "CloseBtn",
	BackgroundColor3 = colors.red,
	BorderSizePixel = 0,
	Position = UDim2.new(1, -30, 0, 2),
	Size = UDim2.new(0, 24, 0, 22),
	Text = "X",
	TextColor3 = colors.text,
	Font = Enum.Font.Code,
	TextSize = 14,
	AutoButtonColor = false,
}, titleBar)
addStroke(closeBtn, colors.border, 1)

local content = make("Frame", {
	Name = "Content",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 12, 0, 35),
	Size = UDim2.new(1, -24, 1, -47),
}, main)

local topTabs = make("Frame", {
	Name = "TopTabs",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 27),
}, content)

local pages = make("Frame", {
	Name = "Pages",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 36),
	Size = UDim2.new(1, 0, 1, -36),
}, content)

local tabNames = { "Combat", "Player", "Visuals", "Misc", "Teleports", "Settings" }
local tabButtons = {}
local tabPages = {}
local activeTab = "Combat"

for i, tabName in ipairs(tabNames) do
	local tabWidth = math.floor(596 / #tabNames) - 2
	local tab = make("TextButton", {
		Name = tabName .. "Tab",
		BackgroundColor3 = (i == 1) and colors.blue or colors.button,
		BorderSizePixel = 0,
		Position = UDim2.new(0, (i - 1) * (tabWidth + 4), 0, 0),
		Size = UDim2.new(0, tabWidth, 0, 26),
		Text = tabName,
		TextColor3 = colors.text,
		Font = Enum.Font.Code,
		TextSize = 14,
		AutoButtonColor = false,
	}, topTabs)
	addStroke(tab, colors.border, 1)
	tabButtons[tabName] = tab

	local page = make("ScrollingFrame", {
		Name = tabName .. "Page",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 700),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.blue,
		BorderSizePixel = 0,
		Visible = (i == 1),
	}, pages)
	tabPages[tabName] = page
end

local function switchTab(name)
	activeTab = name
	for tName, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (tName == name) and colors.blue or colors.button
	end
	for tName, pg in pairs(tabPages) do
		pg.Visible = (tName == name)
	end
end

for tName, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		switchTab(tName)
	end)
end

local function makeGroup(name, pos, size, parent)
	local group = make("Frame", {
		Name = name,
		BackgroundColor3 = colors.panel,
		BorderSizePixel = 0,
		Position = pos,
		Size = size,
	}, parent)
	addStroke(group, Color3.fromRGB(0, 0, 0), 2)

	make("Frame", {
		Name = "TopBlueLine",
		BackgroundColor3 = colors.blue,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 2),
	}, group)

	make("TextLabel", {
		Name = "GroupTitle",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 4),
		Size = UDim2.new(1, -16, 0, 22),
		Text = name,
		TextColor3 = colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Code,
		TextSize = 14,
	}, group)

	return group
end

local function makeCheckbox(parent, text, y, stateKey)
	local row = make("Frame", {
		Name = text:gsub("%s+", "") .. "Row",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, y),
		Size = UDim2.new(1, -16, 0, 22),
	}, parent)

	local box = make("TextButton", {
		Name = "Box",
		BackgroundColor3 = States[stateKey] and colors.blue or colors.checkbox_off,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(0, 18, 0, 18),
		Text = "",
		AutoButtonColor = false,
	}, row)
	addStroke(box, Color3.fromRGB(4, 4, 4), 1)

	make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Text = text,
		TextColor3 = colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Code,
		TextSize = 14,
	}, row)

	local statusDot = make("Frame", {
		Name = "Status",
		BackgroundColor3 = States[stateKey] and colors.green or colors.red,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0, 7),
		Size = UDim2.new(0, 8, 0, 8),
	}, row)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, statusDot)

	box.MouseButton1Click:Connect(function()
		States[stateKey] = not States[stateKey]
		box.BackgroundColor3 = States[stateKey] and colors.blue or colors.checkbox_off
		statusDot.BackgroundColor3 = States[stateKey] and colors.green or colors.red
	end)

	return box, row
end

local function makeValueSlider(parent, label, y, min, max, default, stateKey)
	makeLabel(label, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, y), parent)

	local valLabel = make("TextLabel", {
		Name = label .. "Val",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -60, 0, y),
		Size = UDim2.new(0, 52, 0, 16),
		Text = tostring(default),
		TextColor3 = colors.blue,
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Enum.Font.Code,
		TextSize = 13,
	}, parent)

	local holder = make("Frame", {
		Name = label .. "Slider",
		BackgroundColor3 = Color3.fromRGB(16, 18, 18),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, y + 18),
		Size = UDim2.new(1, -16, 0, 14),
	}, parent)
	addStroke(holder, Color3.fromRGB(0, 0, 0), 1)

	local pct = (default - min) / (max - min)
	local fill = make("Frame", {
		Name = "Fill",
		BackgroundColor3 = colors.blue,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(pct, -4, 1, -4),
	}, holder)

	local sliding = false

	local function update(input)
		local rel = math.clamp((input.Position.X - holder.AbsolutePosition.X) / holder.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(rel, -4, 1, -4)
		local val = math.floor(min + (max - min) * rel)
		States[stateKey] = val
		valLabel.Text = tostring(val)
	end

	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			update(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)

	return holder
end

local function makeButton(parent, text, y, callback)
	local btn = make("TextButton", {
		Name = text:gsub("%s+", "") .. "Btn",
		BackgroundColor3 = colors.button,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, y),
		Size = UDim2.new(1, -16, 0, 26),
		Text = text,
		TextColor3 = colors.text,
		Font = Enum.Font.Code,
		TextSize = 14,
		AutoButtonColor = false,
	}, parent)
	addStroke(btn, colors.border, 1)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(28, 30, 30)
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = colors.button
	end)
	btn.MouseButton1Click:Connect(callback)

	return btn
end

local function makeDropdown(parent, labelText, y, options, stateKey)
	makeLabel(labelText, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, y), parent)

	local box = make("TextButton", {
		Name = labelText:gsub("%s+", "") .. "DD",
		BackgroundColor3 = Color3.fromRGB(18, 20, 20),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, y + 18),
		Size = UDim2.new(1, -16, 0, 24),
		Text = "  " .. (options[1] or "None"),
		TextColor3 = colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Code,
		TextSize = 13,
		AutoButtonColor = false,
		ClipsDescendants = false,
	}, parent)
	addStroke(box, Color3.fromRGB(0, 0, 0), 1)

	make("TextLabel", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -25, 0, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Text = "▼",
		TextColor3 = colors.text,
		Font = Enum.Font.Code,
		TextSize = 10,
	}, box)

	local dropFrame = make("Frame", {
		Name = "DropList",
		BackgroundColor3 = Color3.fromRGB(16, 18, 18),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 2),
		Size = UDim2.new(1, 0, 0, math.min(#options * 22, 176)),
		Visible = false,
		ZIndex = 50,
		ClipsDescendants = true,
	}, box)
	addStroke(dropFrame, colors.border, 1)

	local scroll = make("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, #options * 22),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = colors.blue,
		BorderSizePixel = 0,
		ZIndex = 51,
	}, dropFrame)

	for i, opt in ipairs(options) do
		local optBtn = make("TextButton", {
			Name = opt,
			BackgroundColor3 = Color3.fromRGB(18, 20, 20),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, (i - 1) * 22),
			Size = UDim2.new(1, 0, 0, 22),
			Text = "  " .. opt,
			TextColor3 = colors.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Code,
			TextSize = 13,
			AutoButtonColor = false,
			ZIndex = 52,
		}, scroll)

		optBtn.MouseEnter:Connect(function()
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 32)
		end)
		optBtn.MouseLeave:Connect(function()
			optBtn.BackgroundColor3 = Color3.fromRGB(18, 20, 20)
		end)
		optBtn.MouseButton1Click:Connect(function()
			box.Text = "  " .. opt
			if stateKey then
				States[stateKey] = opt
			end
			dropFrame.Visible = false
		end)
	end

	box.MouseButton1Click:Connect(function()
		dropFrame.Visible = not dropFrame.Visible
	end)

	return box
end

-------------------------------------------------------
-- COMBAT TAB
-------------------------------------------------------
local combatPage = tabPages["Combat"]

local hitboxGroup = makeGroup("Hitbox", UDim2.new(0, 0, 0, 0), UDim2.new(0, 284, 0, 230), combatPage)
makeCheckbox(hitboxGroup, "Extend Hitbox", 28, "ExtendHitbox")
makeValueSlider(hitboxGroup, "Hitbox Multiplier", 54, 1, 20, 5, "HitboxMultiplier")
makeCheckbox(hitboxGroup, "Show Hitbox", 90, "ShowHitbox")
makeCheckbox(hitboxGroup, "M1 Hitbox Expand", 114, "M1Expand")
makeValueSlider(hitboxGroup, "M1 Multiplier", 140, 1, 10, 3, "M1Multiplier")
makeButton(hitboxGroup, "Fire Lc1 Hitbox", 178, function()
	pcall(function()
		local char = player.Character
		if char then
			char:WaitForChild("RemoteEvent"):FireServer("Lc1Hitbox", States.M1Multiplier)
		end
	end)
end)
makeButton(hitboxGroup, "Fire Lc2 Hitbox", 208, function()
	pcall(function()
		local char = player.Character
		if char then
			char:WaitForChild("RemoteEvent"):FireServer("Lc2Hitbox", States.M1Multiplier)
		end
	end)
end)

local hitboxGroup2 = makeGroup("M1 Extra", UDim2.new(0, 0, 0, 238), UDim2.new(0, 284, 0, 60), combatPage)
makeButton(hitboxGroup2, "Fire Lc3 Hitbox", 28, function()
	pcall(function()
		local char = player.Character
		if char then
			char:WaitForChild("RemoteEvent"):FireServer("Lc3Hitbox", States.M1Multiplier)
		end
	end)
end)

local defenseGroup = makeGroup("Defense", UDim2.new(0, 292, 0, 0), UDim2.new(0, 284, 0, 110), combatPage)
makeCheckbox(defenseGroup, "INF Block", 28, "InfBlock")
makeCheckbox(defenseGroup, "Auto Block", 54, "AutoBlock")
makeLabel("[Fires BlockStop remote]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 82), defenseGroup).TextColor3 = colors.muted

local aimGroup = makeGroup("Aim", UDim2.new(0, 292, 0, 118), UDim2.new(0, 284, 0, 80), combatPage)
makeCheckbox(aimGroup, "Silent Aim", 28, "SilentAim")
makeLabel("[Faces nearest enemy]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 54), aimGroup).TextColor3 = colors.muted

local autoFarmGroup = makeGroup("Farming", UDim2.new(0, 292, 0, 206), UDim2.new(0, 284, 0, 92), combatPage)
makeCheckbox(autoFarmGroup, "Auto Farm Players", 28, "AutoFarm")
makeLabel("[Walk + attack nearest]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 54), autoFarmGroup).TextColor3 = colors.muted

-------------------------------------------------------
-- PLAYER TAB
-------------------------------------------------------
local playerPage = tabPages["Player"]

local moveGroup = makeGroup("Movement", UDim2.new(0, 0, 0, 0), UDim2.new(0, 284, 0, 230), playerPage)
makeCheckbox(moveGroup, "Fly", 28, "Fly")
makeValueSlider(moveGroup, "Fly Speed", 54, 10, 300, 80, "FlySpeed")
makeCheckbox(moveGroup, "Noclip", 90, "Noclip")
makeCheckbox(moveGroup, "Speed Hack", 114, "SpeedHack")
makeValueSlider(moveGroup, "Walk Speed", 140, 16, 500, 50, "WalkSpeed")
makeCheckbox(moveGroup, "Auto Sprint", 178, "AutoSprint")
makeLabel("[Holds Shift for you]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 204), moveGroup).TextColor3 = colors.muted

local survivalGroup = makeGroup("Survival", UDim2.new(0, 292, 0, 0), UDim2.new(0, 284, 0, 300), playerPage)
makeCheckbox(survivalGroup, "God Mode", 28, "GodMode")
makeCheckbox(survivalGroup, "Save System", 54, "SaveSystem")
makeValueSlider(survivalGroup, "Save HP Threshold", 80, 5, 80, 30, "SaveThreshold")
makeLabel("[Sky TP → Heal → Return]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 118), survivalGroup).TextColor3 = colors.muted
makeCheckbox(survivalGroup, "Instant Respawn", 140, "InstantRespawn")
makeButton(survivalGroup, "Respawn Now", 166, function()
	pcall(function()
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Died"):FireServer("Real", 3.8333332538604736)
	end)
end)
makeCheckbox(survivalGroup, "Invisible", 200, "Invisible")
makeLabel("[Client-side transparency]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 228), survivalGroup).TextColor3 = colors.muted

-------------------------------------------------------
-- VISUALS TAB
-------------------------------------------------------
local visualsPage = tabPages["Visuals"]

local espGroup = makeGroup("ESP", UDim2.new(0, 0, 0, 0), UDim2.new(0, 284, 0, 110), visualsPage)
makeCheckbox(espGroup, "ESP Players", 28, "ESP")
makeLabel("[Highlight all players]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 54), espGroup).TextColor3 = colors.muted
makeLabel("Shows name + distance", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 72), espGroup).TextColor3 = colors.muted

local camGroup = makeGroup("Camera", UDim2.new(0, 292, 0, 0), UDim2.new(0, 284, 0, 80), visualsPage)
makeCheckbox(camGroup, "INF Zoom", 28, "InfZoom")
makeLabel("[Removes zoom limits]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 54), camGroup).TextColor3 = colors.muted

local hitboxVisGroup = makeGroup("Hitbox Visuals", UDim2.new(0, 0, 0, 118), UDim2.new(0, 284, 0, 80), visualsPage)
makeCheckbox(hitboxVisGroup, "Show Hitbox", 28, "ShowHitbox")
makeLabel("[Visualize attack boxes]", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 54), hitboxVisGroup).TextColor3 = colors.muted

-------------------------------------------------------
-- MISC TAB
-------------------------------------------------------
local miscPage = tabPages["Misc"]

local skinsList = {
	"None",
	"UncLizard2.0",
	"Gubby",
	"Obsidian Dagon",
	"Amythest Dagon",
	"Diamond Dagon",
	"Lizard Dagon",
	"Supercharged Dagon",
	"Ruby Dagon",
	"Lemon Dagon",
	"Corrupted Dagon",
	"MonsterX-Kaizer",
	"MonsterX-Xilien",
	"Albino Godzilla 2014",
	"Albino Godzilla 2019",
}

local skinsGroup = makeGroup("Free Skins", UDim2.new(0, 0, 0, 0), UDim2.new(0, 284, 0, 130), miscPage)
makeDropdown(skinsGroup, "Select Skin", 28, skinsList, "SelectedSkin")
makeButton(skinsGroup, "Apply Skin (Client)", 78, function()
	if States.SelectedSkin == "None" then return end
	pcall(function()
		local kaijus = player:FindFirstChild("Kaijus")
		if kaijus then
			for _, kaiju in pairs(kaijus:GetChildren()) do
				local skinsFolder = kaiju:FindFirstChild("Skins")
				if skinsFolder then
					local skinObj = skinsFolder:FindFirstChild(States.SelectedSkin)
					if skinObj and skinObj:IsA("BoolValue") then
						skinObj.Value = true
					end
				end
			end
		end
	end)
end)

local extraGroup = makeGroup("Extras", UDim2.new(0, 292, 0, 0), UDim2.new(0, 284, 0, 130), miscPage)
makeButton(extraGroup, "Reset Character", 28, function()
	pcall(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)
end)
makeButton(extraGroup, "Rejoin Server", 60, function()
	pcall(function()
		local ts = game:GetService("TeleportService")
		ts:Teleport(game.PlaceId, player)
	end)
end)
makeButton(extraGroup, "Copy Game ID", 92, function()
	pcall(function()
		setclipboard(tostring(game.PlaceId))
	end)
end)

-------------------------------------------------------
-- TELEPORTS TAB
-------------------------------------------------------
local teleportsPage = tabPages["Teleports"]

local tpGroup = makeGroup("Teleport to Player", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 660), teleportsPage)

local tpScroll = make("ScrollingFrame", {
	Name = "PlayerScroll",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 4, 0, 28),
	Size = UDim2.new(1, -8, 1, -32),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = colors.blue,
	BorderSizePixel = 0,
}, tpGroup)

local function refreshPlayerList()
	for _, child in pairs(tpScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local yPos = 0
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player then
			local row = make("Frame", {
				Name = plr.Name .. "Row",
				BackgroundColor3 = colors.panel2,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 2, 0, yPos),
				Size = UDim2.new(1, -4, 0, 30),
			}, tpScroll)

			make("TextLabel", {
				Name = "Name",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(0.55, 0, 1, 0),
				Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
				TextColor3 = colors.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Code,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)

			local tpBtn = make("TextButton", {
				Name = "TpBtn",
				BackgroundColor3 = colors.blue,
				BorderSizePixel = 0,
				Position = UDim2.new(0.6, 0, 0, 4),
				Size = UDim2.new(0.18, 0, 0, 22),
				Text = "Teleport",
				TextColor3 = colors.text,
				Font = Enum.Font.Code,
				TextSize = 12,
				AutoButtonColor = false,
			}, row)
			addStroke(tpBtn, colors.border, 1)

			tpBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local myChar = player.Character
					local targetChar = plr.Character
					if myChar and targetChar then
						local hrp = myChar:FindFirstChild("HumanoidRootPart")
						local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
						if hrp and targetHrp then
							hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 5)
						end
					end
				end)
			end)

			local spectBtn = make("TextButton", {
				Name = "SpectBtn",
				BackgroundColor3 = colors.button,
				BorderSizePixel = 0,
				Position = UDim2.new(0.8, 4, 0, 4),
				Size = UDim2.new(0.18, -4, 0, 22),
				Text = "Spectate",
				TextColor3 = colors.text,
				Font = Enum.Font.Code,
				TextSize = 12,
				AutoButtonColor = false,
			}, row)
			addStroke(spectBtn, colors.border, 1)

			local spectating = false
			spectBtn.MouseButton1Click:Connect(function()
				spectating = not spectating
				if spectating then
					spectBtn.BackgroundColor3 = colors.blue
					pcall(function()
						if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
							Camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid")
						end
					end)
				else
					spectBtn.BackgroundColor3 = colors.button
					pcall(function()
						if player.Character then
							Camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
						end
					end)
				end
			end)

			yPos = yPos + 34
		end
	end

	tpScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function()
	task.wait(0.1)
	refreshPlayerList()
end)

makeButton(tpGroup, "Refresh Player List", 4, refreshPlayerList).Position = UDim2.new(0.6, 0, 0, 4)
tabPages["Teleports"].CanvasSize = UDim2.new(0, 0, 0, 700)

-------------------------------------------------------
-- SETTINGS TAB
-------------------------------------------------------
local settingsPage = tabPages["Settings"]

local keybindGroup = makeGroup("Keybinds", UDim2.new(0, 0, 0, 0), UDim2.new(0, 284, 0, 160), settingsPage)
makeLabel("Toggle GUI: RightControl", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 30), keybindGroup)
makeLabel("Minimize: RightShift", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 52), keybindGroup)
makeLabel("Fly Toggle: F (while enabled)", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 74), keybindGroup)
makeLabel("Noclip Toggle: V", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 96), keybindGroup)
makeLabel("Instant Respawn: R", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 118), keybindGroup)
makeLabel("All keybinds work in-game", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 140), keybindGroup).TextColor3 = colors.muted

local scriptGroup = makeGroup("Script", UDim2.new(0, 292, 0, 0), UDim2.new(0, 284, 0, 160), settingsPage)
makeButton(scriptGroup, "Destroy Script", 30, function()
	States.ScriptEnabled = false
	for _, conn in pairs(Connections) do
		pcall(function() conn:Disconnect() end)
	end
	for _, hl in pairs(ESPHighlights) do
		pcall(function() hl:Destroy() end)
	end
	gui:Destroy()
end)
makeButton(scriptGroup, "Reset All Toggles", 62, function()
	for key, _ in pairs(States) do
		if typeof(States[key]) == "boolean" and key ~= "ScriptEnabled" and key ~= "Minimized" then
			States[key] = false
		end
	end
	switchTab(activeTab)
end)
makeLabel("Money/Free Hub v1.0", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 100), scriptGroup).TextColor3 = colors.blue
makeLabel("Age of Titans Edition", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 120), scriptGroup).TextColor3 = colors.muted

local infoGroup = makeGroup("Info", UDim2.new(0, 0, 0, 168), UDim2.new(1, 0, 0, 120), settingsPage)
makeLabel("Game: [2x XP!!] Age of Titans", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 30), infoGroup)
makeLabel("RightCtrl = Show/Hide GUI", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 52), infoGroup)
makeLabel("RightShift = Minimize/Expand", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 74), infoGroup)
makeLabel("All features are use-at-your-own-risk", UDim2.new(1, -16, 0, 14), UDim2.new(0, 8, 0, 96), infoGroup).TextColor3 = colors.red

-------------------------------------------------------
-- DRAGGING
-------------------------------------------------------
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end))

-------------------------------------------------------
-- MINIMIZE / CLOSE / TOGGLE
-------------------------------------------------------
local expandedSize = UDim2.new(0, 620, 0, 740)
local minimizedSize = UDim2.new(0, 620, 0, 35)

minimizeBtn.MouseButton1Click:Connect(function()
	States.Minimized = not States.Minimized
	if States.Minimized then
		content.Visible = false
		main.Size = minimizedSize
		minimizeBtn.Text = "+"
	else
		main.Size = expandedSize
		content.Visible = true
		minimizeBtn.Text = "_"
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
	States.ScriptEnabled = false
end)

-------------------------------------------------------
-- KEYBIND INPUT
-------------------------------------------------------
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.RightControl then
		gui.Enabled = not gui.Enabled
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		States.Minimized = not States.Minimized
		if States.Minimized then
			content.Visible = false
			main.Size = minimizedSize
			minimizeBtn.Text = "+"
		else
			main.Size = expandedSize
			content.Visible = true
			minimizeBtn.Text = "_"
		end
	end
end))

-------------------------------------------------------
-- FEATURE LOGIC
-------------------------------------------------------

local function getCharacter()
	return player.Character
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNearestPlayer(maxDist)
	maxDist = maxDist or 9999
	local hrp = getHRP()
	if not hrp then return nil, nil end

	local nearest, dist = nil, maxDist
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local theirHrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local theirHum = plr.Character:FindFirstChildOfClass("Humanoid")
			if theirHrp and theirHum and theirHum.Health > 0 then
				local d = (hrp.Position - theirHrp.Position).Magnitude
				if d < dist then
					nearest = plr
					dist = d
				end
			end
		end
	end
	return nearest, dist
end

-- Extend Hitbox loop
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.ExtendHitbox then return end
	pcall(function()
		local char = getCharacter()
		if char then
			char:WaitForChild("RemoteEvent"):FireServer("Attack1Hitbox", States.HitboxMultiplier)
		end
	end)
end))

-- M1 Expand loop
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.M1Expand then return end
	pcall(function()
		local char = getCharacter()
		if char then
			local re = char:WaitForChild("RemoteEvent")
			re:FireServer("Lc1Hitbox", States.M1Multiplier)
			re:FireServer("Lc2Hitbox", States.M1Multiplier)
			re:FireServer("Lc3Hitbox", States.M1Multiplier)
		end
	end)
end))

-- INF Block loop
local infBlockClock = 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
	if not States.InfBlock then return end
	infBlockClock = infBlockClock + dt
	if infBlockClock < 0.15 then return end
	infBlockClock = 0
	pcall(function()
		local char = getCharacter()
		if char then
			char:WaitForChild("RemoteEvent"):FireServer("BlockStop")
		end
	end)
end))

-- Auto Block
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.AutoBlock then return end
	pcall(function()
		local hrp = getHRP()
		if not hrp then return end

		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character then
				local theirHrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if theirHrp and (hrp.Position - theirHrp.Position).Magnitude < 30 then
					local hum = plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						local animator = hum:FindFirstChildOfClass("Animator")
						if animator then
							for _, track in pairs(animator:GetPlayingAnimationTracks()) do
								local animName = track.Animation and track.Animation.Name or ""
								if animName:lower():find("attack") or animName:lower():find("punch")
									or animName:lower():find("lc1") or animName:lower():find("lc2")
									or animName:lower():find("lc3") or animName:lower():find("m1") then
									pcall(function()
										local vim = game:GetService("VirtualInputManager")
										vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
										task.wait(0.05)
										vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
									end)
									return
								end
							end
						end
					end
				end
			end
		end
	end)
end))

-- Silent Aim
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.SilentAim then return end
	pcall(function()
		local hrp = getHRP()
		if not hrp then return end
		local nearest = getNearestPlayer(200)
		if nearest and nearest.Character then
			local targetHrp = nearest.Character:FindFirstChild("HumanoidRootPart")
			if targetHrp then
				hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z))
			end
		end
	end)
end))

-- Auto Farm
local autoFarmClock = 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
	if not States.AutoFarm then return end
	autoFarmClock = autoFarmClock + dt
	pcall(function()
		local hrp = getHRP()
		local hum = getHumanoid()
		if not hrp or not hum then return end

		local nearest, dist = getNearestPlayer(500)
		if not nearest or not nearest.Character then return end
		local targetHrp = nearest.Character:FindFirstChild("HumanoidRootPart")
		if not targetHrp then return end

		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z))
		hum:MoveTo(targetHrp.Position)

		if dist < 25 and autoFarmClock > 0.3 then
			autoFarmClock = 0
			pcall(function()
				local vim = game:GetService("VirtualInputManager")
				vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
				task.wait(0.05)
				vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
			end)
		end
	end)
end))

-- Fly
local flyActive = false

local function startFly()
	if flyActive then return end
	flyActive = true
	pcall(function()
		local hrp = getHRP()
		local hum = getHumanoid()
		if not hrp or not hum then flyActive = false return end

		FlyBody.velocity = Instance.new("BodyVelocity")
		FlyBody.velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		FlyBody.velocity.Velocity = Vector3.zero
		FlyBody.velocity.Parent = hrp

		FlyBody.gyro = Instance.new("BodyGyro")
		FlyBody.gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		FlyBody.gyro.D = 200
		FlyBody.gyro.P = 40000
		FlyBody.gyro.Parent = hrp

		hum.PlatformStand = true
	end)
end

local function stopFly()
	if not flyActive then return end
	flyActive = false
	pcall(function()
		if FlyBody.velocity then FlyBody.velocity:Destroy() FlyBody.velocity = nil end
		if FlyBody.gyro then FlyBody.gyro:Destroy() FlyBody.gyro = nil end
		local hum = getHumanoid()
		if hum then hum.PlatformStand = false end
	end)
end

table.insert(Connections, RunService.Heartbeat:Connect(function()
	if States.Fly then
		if not flyActive then startFly() end
	else
		if flyActive then stopFly() end
	end

	if flyActive and FlyBody.velocity and FlyBody.gyro then
		pcall(function()
			local speed = States.FlySpeed
			local cf = Camera.CFrame
			local dir = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

			if dir.Magnitude > 0 then
				dir = dir.Unit * speed
			end

			FlyBody.velocity.Velocity = dir
			FlyBody.gyro.CFrame = cf
		end)
	end
end))

-- Noclip
table.insert(Connections, RunService.Stepped:Connect(function()
	if not States.Noclip then return end
	pcall(function()
		local char = getCharacter()
		if char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
end))

-- Speed Hack
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.SpeedHack then return end
	pcall(function()
		local hum = getHumanoid()
		if hum then
			hum.WalkSpeed = States.WalkSpeed
		end
	end)
end))

-- Auto Sprint
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.AutoSprint then return end
	pcall(function()
		local hum = getHumanoid()
		if hum and hum.MoveDirection.Magnitude > 0 then
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
		end
	end)
end))

-- God Mode
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.GodMode then return end
	pcall(function()
		local hum = getHumanoid()
		if hum then
			hum.Health = hum.MaxHealth
		end
	end)
end))

-- Save System
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.SaveSystem or IsSaving then return end
	pcall(function()
		local hum = getHumanoid()
		local hrp = getHRP()
		if not hum or not hrp then return end

		local pct = (hum.Health / hum.MaxHealth) * 100
		if pct <= States.SaveThreshold and pct > 0 then
			IsSaving = true
			SavedPosition = hrp.CFrame

			hrp.CFrame = CFrame.new(hrp.Position.X, 5000, hrp.Position.Z)
			hrp.Anchored = true

			task.spawn(function()
				for i = 1, 50 do
					task.wait(0.1)
					pcall(function()
						local h = getHumanoid()
						if h then h.Health = h.MaxHealth end
					end)
				end

				pcall(function()
					local h = getHRP()
					if h and SavedPosition then
						h.Anchored = false
						h.CFrame = SavedPosition
					end
				end)

				IsSaving = false
			end)
		end
	end)
end))

-- Instant Respawn
table.insert(Connections, player.CharacterAdded:Connect(function()
	if not States.InstantRespawn then return end
	task.wait(0.5)
	pcall(function()
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Died"):FireServer("Real", 3.8333332538604736)
	end)
end))

-- Invisible
table.insert(Connections, RunService.Heartbeat:Connect(function()
	pcall(function()
		local char = getCharacter()
		if not char then return end
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				if States.Invisible then
					part.Transparency = 1
				end
			elseif part:IsA("Decal") or part:IsA("Texture") then
				if States.Invisible then
					part.Transparency = 1
				end
			end
		end
		local face = char:FindFirstChild("Head") and char.Head:FindFirstChildOfClass("Decal")
		if face and States.Invisible then
			face.Transparency = 1
		end
	end)
end))

-- ESP
local function createESP(targetPlayer)
	if ESPHighlights[targetPlayer] then return end

	local function applyESP()
		pcall(function()
			if not targetPlayer.Character then return end

			local highlight = Instance.new("Highlight")
			highlight.Name = "MoneyFreeESP"
			highlight.FillColor = Color3.fromRGB(54, 89, 174)
			highlight.FillTransparency = 0.6
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.OutlineTransparency = 0
			highlight.Adornee = targetPlayer.Character
			highlight.Parent = targetPlayer.Character

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "MoneyFreeESPInfo"
			billboard.Size = UDim2.new(0, 200, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 4, 0)
			billboard.AlwaysOnTop = true
			billboard.Adornee = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			billboard.Parent = targetPlayer.Character

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = targetPlayer.DisplayName
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextStrokeTransparency = 0.3
			nameLabel.Font = Enum.Font.Code
			nameLabel.TextSize = 14
			nameLabel.Parent = billboard

			local distLabel = Instance.new("TextLabel")
			distLabel.Size = UDim2.new(1, 0, 0.5, 0)
			distLabel.Position = UDim2.new(0, 0, 0.5, 0)
			distLabel.BackgroundTransparency = 1
			distLabel.Text = "0m"
			distLabel.TextColor3 = colors.blue
			distLabel.TextStrokeTransparency = 0.3
			distLabel.Font = Enum.Font.Code
			distLabel.TextSize = 12
			distLabel.Parent = billboard

			local healthBar = Instance.new("Frame")
			healthBar.Name = "HealthBG"
			healthBar.Size = UDim2.new(0.6, 0, 0, 4)
			healthBar.Position = UDim2.new(0.2, 0, 1, 2)
			healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			healthBar.BorderSizePixel = 0
			healthBar.Parent = billboard

			local healthFill = Instance.new("Frame")
			healthFill.Name = "Fill"
			healthFill.Size = UDim2.new(1, 0, 1, 0)
			healthFill.BackgroundColor3 = colors.green
			healthFill.BorderSizePixel = 0
			healthFill.Parent = healthBar

			ESPHighlights[targetPlayer] = { highlight = highlight, billboard = billboard, distLabel = distLabel, healthFill = healthFill }
		end)
	end

	applyESP()
	targetPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		if States.ESP then
			if ESPHighlights[targetPlayer] then
				pcall(function()
					ESPHighlights[targetPlayer].highlight:Destroy()
					ESPHighlights[targetPlayer].billboard:Destroy()
				end)
				ESPHighlights[targetPlayer] = nil
			end
			applyESP()
		end
	end)
end

local function removeESP(targetPlayer)
	if ESPHighlights[targetPlayer] then
		pcall(function()
			ESPHighlights[targetPlayer].highlight:Destroy()
			ESPHighlights[targetPlayer].billboard:Destroy()
		end)
		ESPHighlights[targetPlayer] = nil
	end
end

local function updateAllESP()
	if States.ESP then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				createESP(plr)
			end
		end
	else
		for plr, _ in pairs(ESPHighlights) do
			removeESP(plr)
		end
	end
end

local espLastState = false
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if States.ESP ~= espLastState then
		espLastState = States.ESP
		updateAllESP()
	end

	if States.ESP then
		local hrp = getHRP()
		for plr, data in pairs(ESPHighlights) do
			pcall(function()
				if data.distLabel and hrp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local dist = math.floor((hrp.Position - plr.Character.HumanoidRootPart.Position).Magnitude)
					data.distLabel.Text = dist .. "m"
				end
				if data.healthFill and plr.Character then
					local hum = plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						data.healthFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
						local pct = hum.Health / hum.MaxHealth
						if pct > 0.5 then
							data.healthFill.BackgroundColor3 = colors.green
						elseif pct > 0.25 then
							data.healthFill.BackgroundColor3 = Color3.fromRGB(200, 170, 0)
						else
							data.healthFill.BackgroundColor3 = colors.red
						end
					end
				end
			end)
		end
	end
end))

Players.PlayerAdded:Connect(function(plr)
	if States.ESP then
		task.wait(1)
		createESP(plr)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	removeESP(plr)
end)

-- INF Zoom
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not States.InfZoom then return end
	pcall(function()
		player.CameraMaxZoomDistance = 9999
		player.CameraMinZoomDistance = 0.5
	end)
end))

-- Show Hitbox
table.insert(Connections, RunService.Heartbeat:Connect(function()
	if States.ShowHitbox then
		pcall(function()
			for _, plr in pairs(Players:GetPlayers()) do
				if plr.Character then
					for _, part in pairs(plr.Character:GetChildren()) do
						if part:IsA("BasePart") then
							if not HitboxVisuals[part] then
								local box = Instance.new("SelectionBox")
								box.Name = "MFH_Hitbox"
								box.Adornee = part
								box.Color3 = (plr == player) and colors.green or colors.red
								box.LineThickness = 0.02
								box.Transparency = 0.5
								box.Parent = part
								HitboxVisuals[part] = box
							end
						end
					end
				end
			end
		end)
	else
		for part, box in pairs(HitboxVisuals) do
			pcall(function() box:Destroy() end)
		end
		HitboxVisuals = {}
	end
end))

-------------------------------------------------------
-- NOTIFICATION
-------------------------------------------------------
pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Money/Free Hub",
		Text = "Loaded! RightCtrl = Toggle | RightShift = Minimize",
		Duration = 5,
	})
end)

print("[Money/Free Hub] Age of Titans script loaded successfully!")
print("[Money/Free Hub] RightControl = Toggle GUI | RightShift = Minimize")
