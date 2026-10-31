--[[ DREAM HUB - TELEPORT RECORDER (PASSIVE / SAFE)
     v2: NO metamethod hooks. The previous version hooked game.__namecall to read remote arguments, and a
     global namecall hook is one of the first things an anti-cheat scans for -> Error 267 kick.
     This version only WATCHES your own character: position, velocity, anchoring, humanoid state and any
     mover/weld that appears on you. That is enough to identify HOW a teleport moved you.

     Run this FIRST, then run the other script and teleport. It auto-copies a report. F8 re-copies. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local function myChar()
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local captures, running = {}, true
local samples = {}          -- rolling ring of per-frame physical state
local MAXS = 240            -- ~4s at 60fps

local MOVERS = {
	BodyVelocity = true, BodyPosition = true, BodyGyro = true, BodyThrust = true,
	LinearVelocity = true, AlignPosition = true, AlignOrientation = true, VectorForce = true,
	AngularVelocity = true, Torque = true, Weld = true, WeldConstraint = true, Motor6D = false,
}
local moverLog = {}
local function watchChar(c)
	if not c then return end
	pcall(function()
		c.DescendantAdded:Connect(function(d)
			if running and MOVERS[d.ClassName] then
				moverLog[#moverLog + 1] = { t = tick(), text = d.ClassName .. " added to " .. (d.Parent and d.Parent.Name or "?") }
			end
		end)
	end)
end

local function snap()
	local hrp = myHRP(); if not hrp then return nil end
	local c = myChar()
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	return {
		t   = tick(),
		pos = hrp.Position,
		vel = hrp.AssemblyLinearVelocity,
		anc = hrp.Anchored,
		ps  = hum and hum.PlatformStand or false,
		st  = hum and tostring(hum:GetState()) or "?",
		fm  = hum and tostring(hum.FloorMaterial) or "?",
	}
end

local function classify(pre, at, post)
	-- Work out WHICH mechanism moved you, from the physical evidence alone.
	local notes = {}
	local jump = (at.pos - pre.pos).Magnitude
	local vBefore = pre.vel.Magnitude
	local vAt     = at.vel.Magnitude
	if pre.anc or at.anc then
		notes[#notes + 1] = "ANCHORED during the move -> the mover anchors the root, writes position, then unanchors."
	end
	if jump > 20 and vAt < 15 and vBefore < 15 then
		notes[#notes + 1] = "INSTANT CFRAME WRITE -> position jumped " .. string.format("%.0f", jump) ..
			" studs in ONE frame while velocity stayed near zero (" .. string.format("%.0f", vAt) .. " studs/s)."
	elseif vBefore > 60 or vAt > 60 then
		notes[#notes + 1] = "VELOCITY FLIGHT -> you were travelling at " .. string.format("%.0f", math.max(vBefore, vAt)) ..
			" studs/s, so it pushed you there with physics rather than writing a position."
	else
		notes[#notes + 1] = "MIXED/UNCLEAR -> jump " .. string.format("%.0f", jump) .. " studs, velocity " ..
			string.format("%.0f", vBefore) .. " -> " .. string.format("%.0f", vAt) .. " studs/s."
	end
	if at.ps or post.ps then notes[#notes + 1] = "PlatformStand was ON (physics handling disabled during the move)." end
	if pre.st ~= at.st then notes[#notes + 1] = "Humanoid state " .. pre.st .. " -> " .. at.st .. "." end
	-- did it STICK?
	local drift = (post.pos - at.pos).Magnitude
	if drift > 25 then
		notes[#notes + 1] = "IT DID NOT STICK - you drifted " .. string.format("%.0f", drift) .. " studs back within ~1s (server setback)."
	else
		notes[#notes + 1] = "IT STUCK - still within " .. string.format("%.0f", drift) .. " studs ~1s later."
	end
	return notes
end

local function buildReport()
	if #captures == 0 then
		return "DREAM HUB TP RECORDER (passive)\nNothing captured yet. Do a teleport, then press F8."
	end
	return "DREAM HUB TP RECORDER (passive - no hooks)\n\n" .. table.concat(captures, "\n\n")
end
local function copyReport()
	local r = buildReport()
	print(r)
	local ok = pcall(function() setclipboard(r) end)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",
			{ Title = "TP Recorder", Text = ok and ("Copied " .. #captures .. " capture(s)") or "Printed to F9", Duration = 5 })
	end)
end

local function capture(i)
	-- i = index in samples of the frame the jump happened on
	local pre  = samples[math.max(1, i - 2)]
	local at   = samples[i]
	local post = samples[#samples]         -- most recent (filled ~1s later by the delayed call)
	local lines = {}
	lines[#lines + 1] = "============ TELEPORT CAPTURED ============"
	lines[#lines + 1] = string.format("jump: %.1f studs in one frame", (at.pos - pre.pos).Magnitude)
	lines[#lines + 1] = "-- what moved you --"
	for _, n in ipairs(classify(pre, at, post)) do lines[#lines + 1] = "  * " .. n end
	lines[#lines + 1] = "-- physical trace (t = seconds around the jump) --"
	for k = math.max(1, i - 6), math.min(#samples, i + 6) do
		local s = samples[k]
		lines[#lines + 1] = string.format("  [%+.2fs] pos(%.0f,%.0f,%.0f) vel=%.0f anchored=%s pstand=%s state=%s",
			s.t - at.t, s.pos.X, s.pos.Y, s.pos.Z, s.vel.Magnitude, tostring(s.anc), tostring(s.ps), s.st)
	end
	local mv = {}
	for _, m in ipairs(moverLog) do
		if math.abs(m.t - at.t) <= 2 then mv[#mv + 1] = string.format("  [%+.2fs] %s", m.t - at.t, m.text) end
	end
	if #mv > 0 then
		lines[#lines + 1] = "-- movers/welds attached near the jump --"
		for _, l in ipairs(mv) do lines[#lines + 1] = l end
	end
	lines[#lines + 1] = "=========================================="
	captures[#captures + 1] = table.concat(lines, "\n")
	copyReport()
end

local pendingIdx = nil
RunService.Heartbeat:Connect(function()
	if not running then return end
	local s = snap(); if not s then return end
	samples[#samples + 1] = s
	if #samples > MAXS then table.remove(samples, 1); if pendingIdx then pendingIdx = pendingIdx - 1 end end
	local prev = samples[#samples - 1]
	if prev and not pendingIdx and (s.pos - prev.pos).Magnitude > 20 then
		pendingIdx = #samples
		-- wait ~1s so we can also report whether it STUCK or got set back
		task.delay(1.0, function()
			if pendingIdx and samples[pendingIdx] then capture(pendingIdx) end
			pendingIdx = nil
		end)
	end
end)

LP.CharacterAdded:Connect(function(c) task.wait(0.3); watchChar(myChar() or c) end)
watchChar(myChar())

UIS.InputBegan:Connect(function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.F8 then copyReport() end
end)

pcall(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DreamTPRec"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999999
	local ok = pcall(function() gui.Parent = gethui() end)
	if not ok or not gui.Parent then pcall(function() gui.Parent = game:GetService("CoreGui") end) end
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui", 5) end
	if not gui.Parent then return end
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(190, 40); b.Position = UDim2.new(0, 14, 0.5, -20)
	b.BackgroundColor3 = Color3.fromRGB(88, 101, 242); b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold; b.TextSize = 13; b.Text = "COPY TP REPORT (F8)"
	b.Active = true; b.Draggable = true; b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(copyReport)
end)

pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification",
		{ Title = "TP Recorder ON (safe mode)", Text = "No hooks. Teleport now - it auto-copies. F8 = copy.", Duration = 8 })
end)
print("[Dream Hub] TP Recorder (PASSIVE - no metamethod hooks). Teleport now; it auto-copies. F8 to re-copy.")
