-- ============================================================
-- Dream Hub - JJS Animation Recorder (standalone)
-- Records EVERY animation your character plays so you can copy the ids and paste them.
-- Use: execute -> press Record -> do the move(s) in-game -> Stop -> Copy -> paste to chat.
-- ============================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local recording = false
local startT = 0
local lines = {}                 -- ordered log lines
local seenIds = {}               -- unique ids seen this recording

local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
local function animatorOf() local c = myChar(); local h = c and c:FindFirstChildOfClass("Humanoid"); return h and h:FindFirstChildOfClass("Animator") end

-- ---------- GUI ----------
local sg = Instance.new("ScreenGui")
sg.Name = "DreamAnimRec"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.DisplayOrder = 9800
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 300); frame.Position = UDim2.new(0, 40, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20); frame.BorderSizePixel = 0
frame.Active = true; frame.Draggable = true; frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(120, 80, 255); st.Thickness = 1.5; st.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 30); title.Position = UDim2.fromOffset(12, 6); title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold; title.Text = "Dream Hub  -  Anim Recorder"; title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = frame

local function mkBtn(text, x, w, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 30); b.Position = UDim2.fromOffset(x, 40)
	b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamSemibold; b.TextSize = 13; b.AutoButtonColor = true; b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end
local recBtn = mkBtn("Record", 12, 90, Color3.fromRGB(60, 170, 90))
local copyBtn = mkBtn("Copy", 110, 90, Color3.fromRGB(80, 90, 200))
local clearBtn = mkBtn("Clear", 208, 90, Color3.fromRGB(150, 60, 60))

local box = Instance.new("ScrollingFrame")
box.Size = UDim2.new(1, -20, 1, -84); box.Position = UDim2.fromOffset(10, 78)
box.BackgroundColor3 = Color3.fromRGB(10, 10, 13); box.BorderSizePixel = 0; box.ScrollBarThickness = 4
box.CanvasSize = UDim2.new(0, 0, 0, 0); box.AutomaticCanvasSize = Enum.AutomaticSize.Y; box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = box
Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 6)

local function addRow(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -8, 0, 16); l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code; l.Text = text; l.TextColor3 = Color3.fromRGB(210, 210, 220)
	l.TextSize = 12; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = box
end

local function fullText()
	return table.concat(lines, "\n")
end

-- ---------- recorder ----------
local hooked = setmetatable({}, { __mode = "k" })
local function hook()
	local a = animatorOf(); if not a or hooked[a] then return end
	hooked[a] = a.AnimationPlayed:Connect(function(track)
		if not recording then return end
		local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
		if not id then return end
		local t = tick() - startT
		local mark = seenIds[id] and "" or "  <-- NEW"
		seenIds[id] = true
		local line = string.format("[%.2fs] rbxassetid://%s%s", t, id, mark)
		lines[#lines + 1] = line
		addRow(line)
		box.CanvasPosition = Vector2.new(0, math.huge)
	end)
end
task.spawn(function() while true do pcall(hook) task.wait(0.5) end end)

recBtn.MouseButton1Click:Connect(function()
	recording = not recording
	if recording then
		startT = tick()
		recBtn.Text = "Stop"; recBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
		hook()
	else
		recBtn.Text = "Record"; recBtn.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
	end
end)
copyBtn.MouseButton1Click:Connect(function()
	local ok = false
	pcall(function() if setclipboard then setclipboard(fullText()); ok = true end end)
	copyBtn.Text = ok and "Copied!" or "print->F9"
	if not ok then print("===== Dream Anim Recorder =====\n" .. fullText()) end
	task.delay(1.2, function() copyBtn.Text = "Copy" end)
end)
clearBtn.MouseButton1Click:Connect(function()
	lines = {}; seenIds = {}
	for _, c in ipairs(box:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
end)

print("[Dream Anim Recorder] loaded. Record -> play moves -> Stop -> Copy. Draggable window.")
