--[[  Dream Hub · JJS DIAGNOSTIC  (standalone, tiny)
      Not the hub — a focused test tool for the three features you said fail: Auto BF, M1 BF, Teleport.
      Each has its own button and a live status line so you can SEE what fires. Load it, press each
      button in-game, and read the status. Load: loadstring(game:HttpGet("<this url>"))()

      What the lines mean:
        BF   — presses 3 on your M1 windup. Status shows when it hooks your body and when it presses 3.
        TP   — steps you 120 studs forward and acknowledges the anti-cheat. Status shows arrival vs set-back.
        QUAKE— on YOUR press of 3 it holds 3 for 2s. Status shows the hold start and release.  ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local function myChar()
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
local function myHRP()
	local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart")
end

-- ───────────────────────── tiny GUI ─────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "JJSDiag"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 250); frame.Position = UDim2.fromOffset(20, 120)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 20); frame.BorderSizePixel = 0; frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28); title.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
title.Text = "JJS DIAGNOSTIC"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
title.TextSize = 14; title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 90); status.Position = UDim2.fromOffset(8, 150)
status.BackgroundColor3 = Color3.fromRGB(10, 10, 12); status.TextColor3 = Color3.fromRGB(120, 255, 140)
status.Font = Enum.Font.Code; status.TextSize = 12; status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left; status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "ready. press a button, then act in-game."; status.Parent = frame
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

local function say(s) status.Text = s; print("[JJS Diag] " .. s) end

local function mkBtn(text, y, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -16, 0, 30); b.Position = UDim2.fromOffset(8, y)
	b.BackgroundColor3 = Color3.fromRGB(40, 40, 46); b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamMedium; b.TextSize = 13; b.Text = text; b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(cb)
	return b
end

-- ───────────────────────── BF test ─────────────────────────
-- Hook your animator; on any Action-priority anim right after an M1 click, press 3. Reports each stage.
local bfOn = false
local BF_ANIMS = {
	["rbxassetid://100962226150441"]=true, ["rbxassetid://95852624447551"]=true,
	["rbxassetid://74145636023952"]=true, ["rbxassetid://72475960800126"]=true,
	["rbxassetid://123171106092050"]=true,
}
local lastClick, lastFire = 0, 0
local function press3()
	pcall(function()
		VIM:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
		task.wait(0.09)
		VIM:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
	end)
end
local hooked = setmetatable({}, {__mode="k"})
local function onAnim(track)
	if not bfOn then return end
	local ok, id = pcall(function() return track.Animation.AnimationId end); if not ok then return end
	local known = BF_ANIMS[tostring(id)]
	local pr = track.Priority
	local isAction = pr==Enum.AnimationPriority.Action or pr==Enum.AnimationPriority.Action2 or pr==Enum.AnimationPriority.Action3 or pr==Enum.AnimationPriority.Action4
	local recent = tick() - lastClick < 0.5
	if known or (isAction and recent) then
		if tick() - lastFire < 0.25 then return end
		lastFire = tick()
		say("BF: windup seen (" .. (known and "known id" or "action+click") .. ") -> pressing 3")
		task.delay(0.19, function() if bfOn then press3() end end)
	end
end
task.spawn(function()
	while true do
		pcall(function()
			local c = myChar()
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			local an = hum and hum:FindFirstChildOfClass("Animator")
			if an and not hooked[an] then hooked[an] = an.AnimationPlayed:Connect(onAnim); if bfOn then say("BF: hooked your body. now M1.") end end
		end)
		task.wait(0.5)
	end
end)
-- click stamp (poll raw button so a sunk M1 still counts)
do
	local wasDown = false
	RunService.RenderStepped:Connect(function()
		if not bfOn then wasDown = false; return end
		local down = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		if down and not wasDown and not UIS:GetFocusedTextBox() then lastClick = tick() end
		wasDown = down
	end)
end

-- ───────────────────────── TP test ─────────────────────────
local function acAck()
	pcall(function()
		local k = game:GetService("ReplicatedStorage"):FindFirstChild("Knit")
		k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local svc = k and k:FindFirstChild("AntiCheatService")
		local re = svc and svc:FindFirstChild("RE"); re = re and re:FindFirstChild("Teleport")
		if re then re:FireServer(workspace:GetServerTimeNow()) end
	end)
end
local function testTP()
	local hrp = myHRP(); if not hrp then say("TP: no HRP found (body path wrong).") return end
	local hum = myChar():FindFirstChildOfClass("Humanoid")
	local startP = hrp.Position
	local target = startP + hrp.CFrame.LookVector * 120
	say("TP: moving 120 studs forward...")
	if hum then pcall(function() hum.PlatformStand = true end) end
	acAck()
	local steps = math.ceil(120 / 60)
	for i = 1, steps do
		local h = myHRP(); if not h then break end
		local p = startP:Lerp(target, i/steps)
		pcall(function() h.CFrame = CFrame.new(p, target); h.AssemblyLinearVelocity = Vector3.zero end)
		acAck(); RunService.Heartbeat:Wait()
	end
	local h = myHRP(); if h then pcall(function() h.CFrame = CFrame.new(target, target + hrp.CFrame.LookVector); h.AssemblyLinearVelocity = Vector3.zero end) end
	acAck()
	if hum then task.delay(0.4, function() pcall(function() hum.PlatformStand = false end) end) end
	task.delay(0.8, function()
		local nowP = myHRP() and myHRP().Position
		if nowP then
			local moved = (nowP - startP).Magnitude
			if moved > 90 then say("TP: ARRIVED ("..math.floor(moved).." studs). teleport works.")
			elseif moved > 15 then say("TP: PARTIAL ("..math.floor(moved).." studs) - server clamped you.")
			else say("TP: SET BACK ("..math.floor(moved).." studs) - anti-cheat rejected it.") end
		end
	end)
end

-- ───────────────────────── QUAKE test ─────────────────────────
local quakeOn = false
local holding = false
local function doQuake()
	if holding then return end
	holding = true
	task.spawn(function()
		say("QUAKE: holding 3 for 2s...")
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Three] = tick() + 2.4
		pcall(function()
			local t0 = tick()
			VIM:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
			while tick() - t0 < 2 do
				_G.VX_INJ_KEYS[Enum.KeyCode.Three] = tick() + 0.4
				VIM:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
				task.wait(0.08)
			end
			VIM:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
		end)
		say("QUAKE: released 3 -> shockwave. done.")
		holding = false
	end)
end
UIS.InputBegan:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.Three then return end
	if not quakeOn then return end
	if UIS:GetFocusedTextBox() then return end
	local injK = _G.VX_INJ_KEYS
	if injK and injK[Enum.KeyCode.Three] and tick() < injK[Enum.KeyCode.Three] then return end
	doQuake()
end)

-- three buttons, stacked cleanly under the title
local bfBtn
bfBtn = mkBtn("Auto/M1 BF: OFF", 38, function()
	bfOn = not bfOn
	bfBtn.Text = "Auto/M1 BF: " .. (bfOn and "ON" or "OFF")
	if bfOn then say("BF: ON. M1 an enemy/dummy and watch this line.") else say("BF: OFF.") end
end)
local qBtn
qBtn = mkBtn("Earthquake hold: OFF", 73, function()
	quakeOn = not quakeOn
	qBtn.Text = "Earthquake hold: " .. (quakeOn and "ON" or "OFF")
	say(quakeOn and "QUAKE: ON. now press 3 yourself." or "QUAKE: OFF.")
end)
mkBtn("Test Teleport (120 fwd)", 108, testTP)

frame.Size = UDim2.fromOffset(260, 250)
status.Position = UDim2.fromOffset(8, 150); status.Size = UDim2.new(1, -16, 0, 92)

say("ready. toggle BF / Earthquake, or press Test Teleport.")
