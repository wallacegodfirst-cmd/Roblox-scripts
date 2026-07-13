--[[  Dream Hub · JJS — Link Gate (your black GUI base). Copy the link, complete it in your browser,
      then press Get Script. Load: loadstring(game:HttpGet("<this url>"))()  ]]

local LINK = "https://rekonise.com/jjs-free-script-jpqps"
local SCRIPT_URL = "https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/DreamHub_JJS_Free.lua"

-- Create the main ScreenGui container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomDraggableGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Create the Main Frame (Small & Black/Dark Charcoal)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 200)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -100) -- centered
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 9)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(50, 50, 50)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Logo ABOVE the frame (Dream logo)
local Logo = Instance.new("ImageLabel")
Logo.Name = "TopLogo"
Logo.Size = UDim2.new(0, 65, 0, 65)
Logo.Position = UDim2.new(0.5, -32.5, 0, -75)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://82151574125055"
Logo.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 26); Title.Position = UDim2.new(0, 10, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "GET JJS FREE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold; Title.TextSize = 16
Title.Parent = MainFrame

-- Instruction
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 28); Info.Position = UDim2.new(0, 10, 0, 36)
Info.BackgroundTransparency = 1
Info.Text = "Copy the link, open it in your browser and complete it, then press Get Script."
Info.TextColor3 = Color3.fromRGB(180, 180, 180)
Info.Font = Enum.Font.Gotham; Info.TextSize = 11; Info.TextWrapped = true
Info.Parent = MainFrame

-- Link box (selectable)
local LinkBox = Instance.new("TextBox")
LinkBox.Size = UDim2.new(1, -20, 0, 28); LinkBox.Position = UDim2.new(0, 10, 0, 70)
LinkBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
LinkBox.Text = LINK
LinkBox.TextColor3 = Color3.fromRGB(120, 200, 255)
LinkBox.Font = Enum.Font.Code; LinkBox.TextSize = 10
LinkBox.ClearTextOnFocus = false; LinkBox.TextEditable = false
LinkBox.TextTruncate = Enum.TextTruncate.AtEnd
LinkBox.Parent = MainFrame
local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 6); lc.Parent = LinkBox

local function mkBtn(text, y, bg)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -20, 0, 30); b.Position = UDim2.new(0, 10, 0, y)
	b.BackgroundColor3 = bg
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamMedium; b.TextSize = 13
	b.Text = text
	b.Parent = MainFrame
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
	return b
end

local CopyBtn = mkBtn("Copy Link", 106, Color3.fromRGB(40, 40, 40))
local GetBtn  = mkBtn("Get Script", 142, Color3.fromRGB(200, 25, 35))

CopyBtn.MouseButton1Click:Connect(function()
	local ok = false
	pcall(function() if setclipboard then setclipboard(LINK); ok = true elseif toclipboard then toclipboard(LINK); ok = true end end)
	pcall(function() LinkBox:CaptureFocus() end)
	CopyBtn.Text = ok and "Copied!" or "Select link + Ctrl+C"
	task.delay(2, function() if CopyBtn and CopyBtn.Parent then CopyBtn.Text = "Copy Link" end end)
end)

GetBtn.MouseButton1Click:Connect(function()
	GetBtn.Text = "Loading..."
	task.spawn(function()
		local src
		for _ = 1, 4 do
			pcall(function() src = game:HttpGet(SCRIPT_URL .. "?cb=" .. tostring(math.floor(os.clock() * 100000))) end)
			if type(src) == "string" and #src > 100000 then break end
			task.wait(1)
		end
		if type(src) == "string" and #src > 100000 then
			local fn = loadstring(src)
			if type(fn) == "function" then ScreenGui:Destroy(); pcall(fn); return end
		end
		GetBtn.Text = "Failed — try again"
		task.delay(2, function() if GetBtn and GetBtn.Parent then GetBtn.Text = "Get Script" end end)
	end)
end)

-- ==========================================
-- SMOOTH DRAGGING SYSTEM
-- ==========================================
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then update(input) end
end)
