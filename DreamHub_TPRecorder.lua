--[[ DREAM HUB - TELEPORT RECORDER
     Run this FIRST, then run the other script and do a teleport that WORKS.
     It AUTO-COPIES the report the moment it catches a teleport (no button needed).
     Press F8 any time to re-copy. Everything is also printed to F9. ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local function myChar()
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local log, captures, running, MAX = {}, {}, true, 300
local function push(kind, text)
	log[#log + 1] = { t = tick(), kind = kind, text = text }
	if #log > MAX then table.remove(log, 1) end
end

local function describe(v, d)
	d = d or 0
	local ok, out = pcall(function()
		local ty = typeof(v)
		if ty == "Instance" then
			local okp, full = pcall(function() return v:GetFullName() end)
			return "<" .. v.ClassName .. " " .. (okp and full or v.Name) .. ">"
		elseif ty == "Vector3" then return string.format("Vector3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
		elseif ty == "CFrame" then local p = v.Position; return string.format("CFrame(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z)
		elseif ty == "table" then
			if d > 1 then return "{...}" end
			local t = {}
			for k, val in pairs(v) do
				t[#t + 1] = tostring(k) .. "=" .. describe(val, d + 1)
				if #t >= 6 then t[#t + 1] = "..." break end
			end
			return "{" .. table.concat(t, ",") .. "}"
		elseif ty == "string" then return '"' .. (#v > 60 and v:sub(1, 60) .. "..." or v) .. '"' end
		return tostring(v) .. " (" .. ty .. ")"
	end)
	return ok and out or "<?>"
end
local function dargs(...)
	local n = select("#", ...)
	if n == 0 then return "(none)" end
	local t = {}
	for i = 1, n do t[#t + 1] = describe((select(i, ...))) end
	return table.concat(t, ",  ")
end

-- hook every remote fire + every move call
local hookOK = false
pcall(function()
	local hm, gn = hookmetamethod, getnamecallmethod
	if not (hm and gn) then return end
	local old
	old = hm(game, "__namecall", function(self, ...)
		if running then
			local m = gn()
			-- Varargs must be packed BEFORE the pcall: "..." is illegal inside a nested non-vararg
			-- function, which is a COMPILE error - the whole script refuses to load.
			local a = table.pack(...)
			pcall(function()
				local shown = dargs(table.unpack(a, 1, a.n))
				if m == "FireServer" or m == "InvokeServer" then
					push("REMOTE", m .. "  " .. self:GetFullName() .. "\n         args: " .. shown)
				elseif m == "PivotTo" or m == "SetPrimaryPartCFrame" or m == "MoveTo" then
					local c = myChar()
					if self == c or self == myHRP() or (c and self:IsDescendantOf(c)) then
						push("MOVE", m .. " on " .. self.Name .. " -> " .. shown)
					end
				end
			end)
		end
		return old(self, ...)
	end)
	hookOK = true
end)

local function buildReport()
	if #captures == 0 then return "DREAM HUB TP RECORDER - nothing captured yet. Teleport, then press F8." end
	return "DREAM HUB TP RECORDER  (hook: " .. (hookOK and "FULL" or "LIMITED") .. ")\n\n" .. table.concat(captures, "\n\n")
end
local function copyReport()
	local r = buildReport()
	print(r)
	local ok = pcall(function() setclipboard(r) end)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",
			{ Title = "TP Recorder", Text = ok and ("Copied " .. #captures .. " capture(s)") or "Printed to F9 (no clipboard)", Duration = 5 })
	end)
	return ok
end

local function capture(dist)
	local t0, lines = tick(), {}
	lines[#lines + 1] = "=============== TELEPORT CAPTURED ==============="
	lines[#lines + 1] = string.format("moved %.1f studs in one frame", dist)
	lines[#lines + 1] = "---- events in the 2s before it ----"
	local any = false
	for _, e in ipairs(log) do
		if t0 - e.t <= 2.0 then
			any = true
			lines[#lines + 1] = string.format("  [-%.2fs] %-8s %s", t0 - e.t, e.kind, e.text)
		end
	end
	if not any then lines[#lines + 1] = "  (nothing recorded - mover may not use remotes/PivotTo)" end
	lines[#lines + 1] = "================================================"
	captures[#captures + 1] = table.concat(lines, "\n")
	copyReport()                                    -- AUTO-COPY: no button needed
end

local lastPos, lastVel
RunService.Heartbeat:Connect(function()
	if not running then return end
	local hrp = myHRP(); if not hrp then return end
	local p = hrp.Position
	if lastPos and (p - lastPos).Magnitude > 20 then capture((p - lastPos).Magnitude) end
	lastPos = p
	local v = hrp.AssemblyLinearVelocity
	if lastVel and (v - lastVel).Magnitude > 60 then
		push("VELOCITY", string.format("velocity -> %.0f studs/s %s", v.Magnitude, describe(v)))
	end
	lastVel = v
	if hrp.Anchored then push("ANCHOR", "HumanoidRootPart.Anchored = true") end
end)

UIS.InputBegan:Connect(function(i, gpe)
	if not gpe and i.KeyCode == Enum.KeyCode.F8 then copyReport() end
end)

-- optional panel; the recorder works fully without it
pcall(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DreamTPRec"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999999
	local okp = pcall(function() gui.Parent = gethui() end)
	if not okp or not gui.Parent then pcall(function() gui.Parent = game:GetService("CoreGui") end) end
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
		{ Title = "TP Recorder ON", Text = "Teleport now. It auto-copies. F8 = copy again.", Duration = 8 })
end)
print("[Dream Hub] TP Recorder running. Hook: " .. (hookOK and "FULL" or "LIMITED") .. " | teleport now, it auto-copies. F8 to re-copy.")
