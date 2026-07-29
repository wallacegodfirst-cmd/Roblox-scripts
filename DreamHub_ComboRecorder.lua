--[[  DREAM HUB — AUTO UPPERCUT / DOWN SLAM RECORDER
      Run this FIRST, then run your friend's script and use their Auto Uppercut / Auto Down Slam.
      It watches what ACTUALLY happens and writes a report you can paste back to me.

      HOW TO USE
        1) Execute this script.
        2) Execute your friend's hub and turn ON their auto uppercut (or auto down slam).
        3) Click START RECORD (or press F7).
        4) Fight a dummy/player and let their script do ONE uppercut, then ONE down slam.
        5) Click STOP + COPY (or press F8). The report is on your clipboard. Paste it to me.

      SAFETY
        Passive by default: it only READS animations, key state, humanoid state and velocity. It installs
        NO metamethod hook, because that is what got the last recorder Error 267 kicked.

        If you want it to also capture the REMOTE their script fires (the single most useful piece of
        information), set this BEFORE running:

            _G.REC_REMOTES = true

        That installs a __namecall hook. It is the only way to see remote arguments from the client, and it
        carries a real kick risk on this game. Your call - the passive report is still useful without it.
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local REC_REMOTES = _G.REC_REMOTES == true

--=================================================================================================
-- character resolution (JJS keeps your real body under workspace.Characters, NOT LP.Character)
--=================================================================================================
local function myChar()
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
local function myHum() local c = myChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end

--=================================================================================================
-- state
--=================================================================================================
local recording  = false
local t0         = 0
local events     = {}        -- every observed event, in order
local MAXEV      = 4000

local function stamp() return tick() - t0 end
local function add(kind, text)
	if not recording then return end
	if #events >= MAXEV then return end
	events[#events + 1] = { t = stamp(), kind = kind, text = text }
end

--=================================================================================================
-- 1) KEY STATE — which keys are held, and for how long.
--    This is the whole question for uppercut/down slam: does their script HOLD a direction key across
--    the swing, or does it only fire a remote? A held key shows up here as DOWN ... UP with a duration.
--=================================================================================================
local WATCH = {
	Space = Enum.KeyCode.Space, W = Enum.KeyCode.W, A = Enum.KeyCode.A,
	S = Enum.KeyCode.S, D = Enum.KeyCode.D, Q = Enum.KeyCode.Q, E = Enum.KeyCode.E,
	R = Enum.KeyCode.R, F = Enum.KeyCode.F,
	One = Enum.KeyCode.One, Two = Enum.KeyCode.Two, Three = Enum.KeyCode.Three, Four = Enum.KeyCode.Four,
	LeftShift = Enum.KeyCode.LeftShift, LeftControl = Enum.KeyCode.LeftControl,
}
local keyWas, keyDownAt = {}, {}
local m1Was, m1DownAt = false, 0

RunService.RenderStepped:Connect(function()
	if not recording then return end
	for name, kc in pairs(WATCH) do
		local ok, down = pcall(function() return UIS:IsKeyDown(kc) end)
		if ok then
			if down and not keyWas[name] then
				keyDownAt[name] = stamp()
				add("KEY", name .. " DOWN")
			elseif (not down) and keyWas[name] then
				local held = stamp() - (keyDownAt[name] or stamp())
				add("KEY", string.format("%s UP   (held %.3fs)", name, held))
			end
			keyWas[name] = down
		end
	end
	-- the game SINKS the attack click, so poll the raw button instead of using InputBegan
	local okm, mdown = pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end)
	if okm then
		if mdown and not m1Was then
			m1DownAt = stamp(); add("M1", "click DOWN")
		elseif (not mdown) and m1Was then
			add("M1", string.format("click UP   (held %.3fs)", stamp() - m1DownAt))
		end
		m1Was = mdown
	end
end)

--=================================================================================================
-- 2) ANIMATIONS — every track your character plays, with its id and priority.
--    The uppercut / down slam each have their own animation. Seeing WHICH id plays and WHEN, relative
--    to the keys and the remote, is what tells us how the move is actually triggered.
--=================================================================================================
local hookedAnimators = setmetatable({}, { __mode = "k" })
local function hookAnims()
	local rigs = {}
	local c = myChar(); if c then rigs[#rigs + 1] = c end
	if LP.Character and LP.Character ~= c then rigs[#rigs + 1] = LP.Character end
	for _, rig in ipairs(rigs) do
		local h = rig:FindFirstChildOfClass("Humanoid")
		local a = h and h:FindFirstChildOfClass("Animator")
		if a and not hookedAnimators[a] then
			hookedAnimators[a] = true
			a.AnimationPlayed:Connect(function(track)
				if not recording then return end
				local ok, id = pcall(function() return tostring(track.Animation.AnimationId):match("%d+") end)
				if not ok or not id then return end
				local pr = "?"
				pcall(function() pr = tostring(track.Priority):gsub("Enum.AnimationPriority.", "") end)
				local nm = "?"
				pcall(function() nm = track.Animation.Name end)
				add("ANIM", string.format("id=%s  priority=%s  name=%s", id, pr, tostring(nm)))
			end)
		end
	end
end
task.spawn(function() while true do pcall(hookAnims); task.wait(0.5) end end)

--=================================================================================================
-- 3) PHYSICAL STATE — sampled ~10x/sec while recording, plus on every interesting change.
--    Tells us whether the move needs you airborne, whether it launches you, and how high.
--=================================================================================================
local lastState, lastFloor = nil, nil
task.spawn(function()
	while true do
		task.wait(0.1)
		if recording then
			local h = myHum(); local r = myHRP()
			if h and r then
				local st = tostring(h:GetState()):gsub("Enum.HumanoidStateType.", "")
				local fm = tostring(h.FloorMaterial):gsub("Enum.Material.", "")
				if st ~= lastState or fm ~= lastFloor then
					add("STATE", string.format("humanoid=%s  floor=%s  vel=(%.0f,%.0f,%.0f)",
						st, fm, r.AssemblyLinearVelocity.X, r.AssemblyLinearVelocity.Y, r.AssemblyLinearVelocity.Z))
					lastState, lastFloor = st, fm
				end
			end
		end
	end
end)

--=================================================================================================
-- 4) REMOTES — OPT-IN ONLY (_G.REC_REMOTES = true). This is the metamethod hook that risks a kick.
--=================================================================================================
local function argSummary(...)
	local a = table.pack(...)
	local parts = {}
	for i = 1, a.n do
		local v = a[i]
		local tv = typeof(v)
		if tv == "string" then parts[#parts + 1] = '"' .. v .. '"'
		elseif tv == "number" or tv == "boolean" then parts[#parts + 1] = tostring(v)
		elseif tv == "Instance" then parts[#parts + 1] = v.ClassName .. "(" .. v:GetFullName() .. ")"
		elseif tv == "Vector3" then parts[#parts + 1] = string.format("Vector3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
		elseif tv == "CFrame" then parts[#parts + 1] = "CFrame(...)"
		elseif tv == "nil" then parts[#parts + 1] = "nil"
		else parts[#parts + 1] = tv end
	end
	return table.concat(parts, ", ")
end

if REC_REMOTES then
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		setreadonly(mt, false)
		local old = mt.__namecall
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if recording and (method == "FireServer" or method == "InvokeServer") then
				pcall(function()
					add("REMOTE", self:GetFullName() .. ":" .. method .. "(" .. argSummary(...) .. ")")
				end)
			end
			return old(self, ...)
		end)
		setreadonly(mt, true)
	end)
	if ok then
		print("[ComboRecorder] REMOTE CAPTURE ON (namecall hook installed - kick risk accepted)")
	else
		print("[ComboRecorder] remote capture FAILED to install; continuing passively")
		REC_REMOTES = false
	end
end

--=================================================================================================
-- report
--=================================================================================================
local function buildReport()
	local lines = {}
	lines[#lines + 1] = "======== DREAM HUB COMBO RECORDER ========"
	lines[#lines + 1] = "remote capture: " .. (REC_REMOTES and "ON" or "OFF (passive)")
	local c = myChar()
	lines[#lines + 1] = "rig: " .. tostring(c and c.Name)
	do
		local mv = c and c:FindFirstChild("Moveset")
		local names = {}
		if mv then for _, m in ipairs(mv:GetChildren()) do names[#names + 1] = m.Name end end
		lines[#lines + 1] = "Moveset: { " .. table.concat(names, ", ") .. " }"
	end
	lines[#lines + 1] = "events: " .. #events .. (#events >= MAXEV and "  (TRUNCATED - recorded too long)" or "")
	lines[#lines + 1] = "------------------------------------------"
	lines[#lines + 1] = "  time   | kind   | what"
	for _, e in ipairs(events) do
		lines[#lines + 1] = string.format("%+8.3f | %-6s | %s", e.t, e.kind, e.text)
	end
	lines[#lines + 1] = "======== END ========"
	return table.concat(lines, "\n")
end

local function copyReport()
	local r = buildReport()
	print(r)
	local ok = pcall(function() setclipboard(r) end)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Combo Recorder",
			Text = ok and ("Copied " .. #events .. " events") or "Clipboard failed - it is printed in F9",
			Duration = 6,
		})
	end)
end

--=================================================================================================
-- UI
--=================================================================================================
local btn
local function setRecording(on)
	recording = on
	if on then
		t0 = tick(); events = {}; keyWas = {}; lastState, lastFloor = nil, nil
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification",
				{ Title = "Combo Recorder", Text = "RECORDING - do the uppercut / down slam now", Duration = 5 })
		end)
	end
	if btn then
		btn.Text = on and "STOP + COPY  (F8)" or "START RECORD  (F7)"
		btn.BackgroundColor3 = on and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(60, 170, 90)
	end
	if not on then copyReport() end
end

pcall(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DreamComboRec"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999999
	local okh = pcall(function() gui.Parent = gethui() end)
	if not okh or not gui.Parent then pcall(function() gui.Parent = game:GetService("CoreGui") end) end
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui", 5) end
	if not gui.Parent then return end

	btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(210, 44); btn.Position = UDim2.new(0, 14, 0.5, -22)
	btn.BackgroundColor3 = Color3.fromRGB(60, 170, 90); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.Text = "START RECORD  (F7)"
	btn.Active = true; btn.Draggable = true; btn.Parent = gui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
	btn.MouseButton1Click:Connect(function() setRecording(not recording) end)
end)

UIS.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	if i.KeyCode == Enum.KeyCode.F7 then setRecording(true)
	elseif i.KeyCode == Enum.KeyCode.F8 then setRecording(false) end
end)

pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Combo Recorder ready",
		Text = "Run your friend's script, then F7 to record, F8 to copy.",
		Duration = 9,
	})
end)
print("[Dream Hub] Combo Recorder loaded. F7 = start, F8 = stop + copy. Passive unless _G.REC_REMOTES = true.")
