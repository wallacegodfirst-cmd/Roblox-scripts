--[[  DREAM HUB — TELEPORT RECORDER  ]]--
-- Run this FIRST, then run your friend's script and do a teleport that WORKS.
-- It watches everything that could move you and writes down exactly what happened, then copies a report to
-- your clipboard. Paste that in chat and the exact method can be copied.
--
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/wallacegodfirst-cmd/Roblox-scripts/refs/heads/claude/improve-ai-system-tUhhn/DreamHub_TPRecorder.lua"))()
--
-- It records:
--   * every RemoteEvent/RemoteFunction fired (name, full path, and the arguments)
--   * every :PivotTo / :MoveTo / :SetPrimaryPartCFrame call
--   * direct CFrame / Position / Anchored / Velocity writes on your character
--   * the exact moment your position jumps, and the last ~2 seconds of events before it
--
-- Buttons: COPY REPORT (to clipboard) · CLEAR · STOP

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LP          = Players.LocalPlayer

local function myChar()
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end

----------------------------------------------------------------------------------------------------
-- EVENT LOG
----------------------------------------------------------------------------------------------------
local log        = {}      -- rolling buffer of everything seen
local captures   = {}      -- finished teleport captures
local running    = true
local MAX_LOG    = 400

local function now() return tick() end
local function push(kind, text)
	log[#log + 1] = { t = now(), kind = kind, text = text }
	if #log > MAX_LOG then table.remove(log, 1) end
end

-- Describe a value compactly but usefully (this is what tells us the real argument shape).
local function describe(v, depth)
	depth = depth or 0
	local ok, out = pcall(function()
		local ty = typeof(v)
		if ty == "Instance" then
			local okp, full = pcall(function() return v:GetFullName() end)
			return "<" .. v.ClassName .. " " .. (okp and full or v.Name) .. ">"
		elseif ty == "Vector3" then
			return string.format("Vector3(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
		elseif ty == "CFrame" then
			local p = v.Position
			return string.format("CFrame(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
		elseif ty == "table" then
			if depth > 1 then return "{...}" end
			local parts = {}
			for k, val in pairs(v) do
				parts[#parts + 1] = tostring(k) .. "=" .. describe(val, depth + 1)
				if #parts >= 6 then parts[#parts + 1] = "..." break end
			end
			return "{" .. table.concat(parts, ", ") .. "}"
		elseif ty == "string" then
			return '"' .. (#v > 60 and (v:sub(1, 60) .. "...") or v) .. '"'
		end
		return tostring(v) .. " (" .. ty .. ")"
	end)
	return ok and out or "<?>"
end

local function describeArgs(...)
	local n = select("#", ...)
	if n == 0 then return "(no args)" end
	local parts = {}
	for i = 1, n do parts[#parts + 1] = describe((select(i, ...))) end
	return table.concat(parts, ",  ")
end

----------------------------------------------------------------------------------------------------
-- HOOK: every remote fire + every movement method call
----------------------------------------------------------------------------------------------------
local hookOK = false
pcall(function()
	local hookmeta = hookmetamethod or (getgenv and getgenv().hookmetamethod)
	local getnc    = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
	if not (hookmeta and getnc) then return end

	local oldNamecall
	oldNamecall = hookmeta(game, "__namecall", newcclosure and newcclosure(function(self, ...)
		local method = getnc()
		if running then
			pcall(function()
				if method == "FireServer" or method == "InvokeServer" then
					push("REMOTE", method .. "  " .. self:GetFullName() .. "\n        args: " .. describeArgs(...))
				elseif method == "PivotTo" or method == "SetPrimaryPartCFrame" or method == "MoveTo" then
					-- only care when it is OUR body being moved
					local c = myChar()
					if self == c or (c and self:IsDescendantOf(c)) or self == myHRP() then
						push("MOVE", method .. " on " .. self.Name .. "  ->  " .. describeArgs(...))
					end
				end
			end)
		end
		return oldNamecall(self, ...)
	end) or function(self, ...)
		local method = getnc()
		if running then
			pcall(function()
				if method == "FireServer" or method == "InvokeServer" then
					push("REMOTE", method .. "  " .. self:GetFullName() .. "\n        args: " .. describeArgs(...))
				elseif method == "PivotTo" or method == "SetPrimaryPartCFrame" or method == "MoveTo" then
					local c = myChar()
					if self == c or (c and self:IsDescendantOf(c)) or self == myHRP() then
						push("MOVE", method .. " on " .. self.Name .. "  ->  " .. describeArgs(...))
					end
				end
			end)
		end
		return oldNamecall(self, ...)
	end)
	hookOK = true
end)

----------------------------------------------------------------------------------------------------
-- WATCH: property changes on your own body (CFrame / Anchored / Velocity), and the teleport itself
----------------------------------------------------------------------------------------------------
local lastPos, lastAnchored, lastVel = nil, nil, nil
local watchedHRP = nil

local function watchHRP(hrp)
	if not hrp or watchedHRP == hrp then return end
	watchedHRP = hrp
	lastPos, lastAnchored = hrp.Position, hrp.Anchored
	pcall(function()
		hrp:GetPropertyChangedSignal("Anchored"):Connect(function()
			if running then push("ANCHOR", "HumanoidRootPart.Anchored = " .. tostring(hrp.Anchored)) end
		end)
	end)
end

local function snapshot(reason, jump)
	local lines = {}
	local t0 = now()
	lines[#lines + 1] = "================ TELEPORT CAPTURED ================"
	lines[#lines + 1] = reason
	if jump then lines[#lines + 1] = string.format("distance moved in one frame: %.1f studs", jump) end
	lines[#lines + 1] = "---- events in the 2.0s before it ----"
	local any = false
	for _, e in ipairs(log) do
		if t0 - e.t <= 2.0 then
			any = true
			lines[#lines + 1] = string.format("  [-%.2fs] %-7s %s", t0 - e.t, e.kind, e.text)
		end
	end
	if not any then lines[#lines + 1] = "  (nothing recorded - the mover may not use remotes or PivotTo)" end
	lines[#lines + 1] = "==================================================="
	captures[#captures + 1] = table.concat(lines, "\n")
	return captures[#captures]
end

local statusLabel
RunService.Heartbeat:Connect(function()
	if not running then return end
	local hrp = myHRP(); if not hrp then return end
	watchHRP(hrp)
	local p = hrp.Position
	if lastPos then
		local d = (p - lastPos).Magnitude
		if d > 20 then                                    -- a real teleport, not walking
			local cap = snapshot("A teleport moved you.", d)
			if statusLabel then statusLabel.Text = "CAPTURED " .. #captures .. " teleport(s) - press COPY REPORT" end
			push("JUMP", string.format("position jumped %.1f studs", d))
		end
	end
	lastPos = p
	local v = hrp.AssemblyLinearVelocity
	if lastVel and (v - lastVel).Magnitude > 60 then
		push("VELOCITY", string.format("velocity changed to %.0f studs/s %s", v.Magnitude, describe(v)))
	end
	lastVel = v
end)

----------------------------------------------------------------------------------------------------
-- SMALL UI
----------------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "DreamTPRecorder"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999999
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local f = Instance.new("Frame")
f.Size = UDim2.fromOffset(330, 150); f.Position = UDim2.new(0, 14, 0.5, -75)
f.BackgroundColor3 = Color3.fromRGB(16, 15, 20); f.Active = true; f.Draggable = true; f.Parent = gui
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", f); st.Color = Color3.fromRGB(120, 90, 255); st.Thickness = 1

local function mk(cls, props)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = f
	return o
end

mk("TextLabel", { Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1,
	Text = "TELEPORT RECORDER", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(235, 232, 255),
	TextXAlignment = Enum.TextXAlignment.Left })

statusLabel = mk("TextLabel", { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 30), BackgroundTransparency = 1,
	Text = (hookOK and "Watching. Now run your friend's script and teleport." or "Watching (limited: this executor has no metamethod hook - remote args will not be logged)."),
	Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(170, 168, 190), TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })

local function button(text, x, w, color, cb)
	local b = mk("TextButton", { Size = UDim2.fromOffset(w, 30), Position = UDim2.fromOffset(x, 108),
		BackgroundColor3 = color, Text = text, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 255, 255), AutoButtonColor = true })
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(cb)
	return b
end

button("COPY REPORT", 8, 130, Color3.fromRGB(88, 101, 242), function()
	local report
	if #captures == 0 then
		report = "DREAM HUB TP RECORDER - no teleport captured yet.\nRun the other script and teleport, then press COPY REPORT again."
	else
		report = "DREAM HUB TP RECORDER\nexecutor hook: " .. (hookOK and "full" or "limited") .. "\n\n" .. table.concat(captures, "\n\n")
	end
	local okc = pcall(function() setclipboard(report) end)
	print(report)                                   -- always print so F9 has it even with no clipboard
	statusLabel.Text = okc and ("Copied " .. #captures .. " capture(s) to clipboard. Also printed to F9.")
		or ("No clipboard on this executor - the report is printed in F9 (" .. #captures .. " capture(s)).")
end)

button("CLEAR", 146, 76, Color3.fromRGB(60, 58, 72), function()
	captures = {}; log = {}
	statusLabel.Text = "Cleared. Waiting for a teleport..."
end)

button("STOP", 228, 76, Color3.fromRGB(150, 50, 60), function()
	running = false
	statusLabel.Text = "Stopped. Press COPY REPORT to grab what was recorded."
end)

print("[Dream Hub] Teleport Recorder running. Hook: " .. (hookOK and "FULL" or "LIMITED"))
