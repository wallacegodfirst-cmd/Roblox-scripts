--[[  Dream Hub · PE SPEED FINDER — find the exact run speed the server tolerates.
      HOW TO USE:
        1. Run this (works alongside the hub or alone), turn on INF Stam, and run around.
        2. The HUD (top middle) shows your LIVE speed in studs/s.
        3. Press LEFT SHIFT any time to RECORD the current speed — it's saved to the log
           AND copied to your clipboard, so you can paste the whole log to support/Claude.
        4. SNAPBACKS are detected AUTOMATICALLY: the moment the server yanks you back, the
           speed you were running at gets logged as "SNAPBACK at X" — no button needed.
           Run a little faster each time until you see snapbacks; the best speed is just
           under the lowest snapback number.
      Load: loadstring(game:HttpGet("<this url>"))()  ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer

local function toast(msg, dur)
	pcall(function() StarterGui:SetCore("SendNotification", {Title="Speed Finder", Text=msg, Duration=dur or 5}) end)
	print("[Speed Finder] "..tostring(msg))
end

-- PE dinos live under workspace.Characters[name] and are NOT Humanoid rigs — there is no HumanoidRootPart
-- (that's why v1 read 0.0 forever). The real steer/physics part is TurningAnimation.Body; we use the hub's
-- exact lookup chain and, if every named part misses, fall back to the model pivot (that can never miss).
local trackedName = "?"
local function myModel()
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
local function trackPos()
	local c = myModel()
	if not c then trackedName = "no dino (spawn in)"; return nil end
	local ta = c:FindFirstChild("TurningAnimation")
	local body = ta and ta:FindFirstChild("Body")
	if body and body:IsA("BasePart") then trackedName = "TurningAnimation.Body"; return body.Position end
	for _, nm in ipairs({"HumanoidRootPart","Root","RootPart","Torso","UpperTorso","Body","Main","MainPart","Hitbox"}) do
		local p = c:FindFirstChild(nm)
		if p and p:IsA("BasePart") then trackedName = nm; return p.Position end
	end
	if c.PrimaryPart then trackedName = "PrimaryPart"; return c.PrimaryPart.Position end
	local ok, pv = pcall(function() return c:GetPivot().Position end)
	if ok then trackedName = "model pivot"; return pv end
	trackedName = "no part found"; return nil
end

-- ═══ HUD ═══
local gui = Instance.new("ScreenGui")
gui.Name = "PE_SpeedFinder"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
local ok = pcall(function() gui.Parent = (typeof(gethui)=="function" and gethui()) or game:GetService("CoreGui") end)
if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
local box = Instance.new("Frame")
box.Size = UDim2.fromOffset(280, 74); box.Position = UDim2.new(0.5, -140, 0, 8)
box.BackgroundColor3 = Color3.fromRGB(18,18,22); box.BackgroundTransparency = 0.15; box.BorderSizePixel = 0; box.Parent = gui
local corner = Instance.new("UICorner", box); corner.CornerRadius = UDim.new(0, 8)
local function lbl(y, size, color)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -12, 0, size+4); t.Position = UDim2.fromOffset(6, y)
	t.BackgroundTransparency = 1; t.TextColor3 = color; t.TextSize = size
	t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = box
	return t
end
local lSpeed = lbl(4, 20, Color3.fromRGB(120, 235, 140))
local lInfo  = lbl(30, 12, Color3.fromRGB(220, 220, 220))
local lSnap  = lbl(48, 12, Color3.fromRGB(255, 120, 120))
lSpeed.Text = "-- studs/s"; lInfo.Text = "SHIFT = record · log copies to clipboard"; lSnap.Text = "no snapback seen yet"

-- ═══ SAMPLING ═══
local samples = {}          -- ring of {t, speed} for the rolling window
local LOG = {}              -- recorded lines (Shift presses + auto snapbacks)
local lastPos, lastT = nil, nil
local curSpeed, lowestSnap = 0, nil

local function windowStats(secs)
	local now = tick(); local sum, n, mx = 0, 0, 0
	for i = #samples, 1, -1 do
		local s = samples[i]
		if now - s[1] > secs then break end
		sum += s[2]; n += 1; if s[2] > mx then mx = s[2] end
	end
	if n == 0 then return 0, 0 end
	return sum / n, mx
end

local function pushLog(line)
	LOG[#LOG+1] = line
	print("[Speed Finder] "..line)
	pcall(function() if setclipboard then setclipboard(table.concat(LOG, "\n")) end end)
end

RunService.RenderStepped:Connect(function()
	local pos = trackPos(); local now = tick()
	if not pos then lastPos = nil; lSpeed.Text = "-- studs/s"; lInfo.Text = "tracking: "..trackedName; return end
	if lastPos and lastT and now > lastT then
		local dt = now - lastT
		local dp = pos - lastPos
		local flatJump = Vector3.new(dp.X, 0, dp.Z).Magnitude
		if dt < 0.2 and flatJump / math.max(dt, 1/240) > 80 and flatJump > 10 then
			-- position jumped way faster than any run = the server yanked you (or you teleported).
			local avg = select(1, windowStats(0.6))
			if avg > 6 then   -- ignore jumps while standing still (those are teleports, not snapbacks)
				if not lowestSnap or avg < lowestSnap then lowestSnap = avg end
				lSnap.Text = ("SNAPBACK at %.1f  (lowest: %.1f)"):format(avg, lowestSnap)
				pushLog(("SNAPBACK while running %.1f studs/s"):format(avg))
			end
			samples = {}   -- don't let the jump pollute the speed readout
		else
			curSpeed = flatJump / dt
			samples[#samples+1] = {now, curSpeed}
			if #samples > 600 then table.remove(samples, 1) end
		end
	end
	lastPos, lastT = pos, now
	local avg1 = select(1, windowStats(1))
	lSpeed.Text = ("%.1f studs/s   (1s avg %.1f)"):format(curSpeed, avg1)
	lInfo.Text = "SHIFT = record · tracking: "..trackedName
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end   -- typing in chat etc.
	if input.KeyCode ~= Enum.KeyCode.LeftShift and input.KeyCode ~= Enum.KeyCode.RightShift then return end
	local avg1 = select(1, windowStats(1))
	local mx3 = select(2, windowStats(3))
	pushLog(("RECORD  now %.1f | 1s avg %.1f | 3s max %.1f studs/s"):format(curSpeed, avg1, mx3))
	toast(("Recorded %.1f studs/s (copied to clipboard, %d lines)"):format(avg1, #LOG), 4)
end)

toast("Speed Finder on — run around; SHIFT records, snapbacks log themselves.", 8)
