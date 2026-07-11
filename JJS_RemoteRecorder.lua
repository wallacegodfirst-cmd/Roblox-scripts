--[[ Dream Hub — Remote Recorder (JJS)
     Run this, then do a move MANUALLY in-game (earthquake, black flash, teleport, whatever).
     Every RemoteEvent:FireServer / RemoteFunction:InvokeServer you send is captured and shown as
     ready-to-paste Lua. Tap an entry to COPY it to your clipboard, then paste it to me in chat and
     I'll wire that exact remote into the hub.

     It also prints each capture to the F9 console. If your executor blocks clipboard, copy from F9.  ]]

local Players             = game:GetService("Players")
local CoreGui             = game:GetService("CoreGui")
local LP                  = Players.LocalPlayer

local clip = (typeof(setclipboard) == "function" and setclipboard)
    or (typeof(toclipboard) == "function" and toclipboard)
    or (syn and syn.write_clipboard)
    or function() end

local function notify(msg, dur)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Recorder", Text = msg, Duration = dur or 4 }) end)
end

-- ── serialize any arg to a copyable Lua literal ──────────────────────────────────
local function isBinary(s)
    for i = 1, #s do local b = s:byte(i); if b < 9 or (b > 13 and b < 32) or b > 126 then return true end end
    return false
end
local function strLit(s)
    if not isBinary(s) then return string.format("%q", s) end
    local t = {}
    for i = 1, #s do t[i] = "\\" .. s:byte(i) end
    return '"' .. table.concat(t) .. '"'   -- byte-escaped, safe for any binary payload
end
local function instPath(o)
    local ok, full = pcall(function() return o:GetFullName() end)
    if not ok then return "nil --[[instance]]" end
    -- turn "ReplicatedStorage.Files.X.Y" into game:GetService("ReplicatedStorage"):WaitForChild("Files")...
    local parts = string.split(full, ".")
    local expr = 'game:GetService("' .. parts[1] .. '")'
    for i = 2, #parts do expr = expr .. ':WaitForChild("' .. parts[i] .. '")' end
    return expr
end
local ser
local function serTable(t, seen)
    seen = seen or {}
    if seen[t] then return "{--[[cycle]]}" end
    seen[t] = true
    local out, isArr, n = {}, true, 0
    for k in pairs(t) do n += 1; if type(k) ~= "number" then isArr = false end end
    if isArr then
        for i = 1, n do out[#out + 1] = ser(t[i], seen) end
    else
        for k, v in pairs(t) do
            local key = (type(k) == "string" and k:match("^%a[%w_]*$")) and k .. " = " or "[" .. ser(k, seen) .. "] = "
            out[#out + 1] = key .. ser(v, seen)
        end
    end
    return "{ " .. table.concat(out, ", ") .. " }"
end
ser = function(v, seen)
    local tp = typeof(v)
    if tp == "string" then return strLit(v)
    elseif tp == "number" or tp == "boolean" then return tostring(v)
    elseif tp == "nil" then return "nil"
    elseif tp == "buffer" then local ok, s = pcall(buffer.tostring, v); return ok and ("buffer.fromstring(" .. strLit(s) .. ")") or "buffer --[[?]]"
    elseif tp == "Instance" then return instPath(v)
    elseif tp == "Vector3" then return string.format("Vector3.new(%s, %s, %s)", v.X, v.Y, v.Z)
    elseif tp == "CFrame" then return "CFrame.new(" .. table.concat({ v:GetComponents() }, ", ") .. ")"
    elseif tp == "table" then return serTable(v, seen)
    else return tostring(v) .. " --[[" .. tp .. "]]" end
end

-- ── the capture list GUI ─────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "DreamRecorder"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 99999
pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
local win = Instance.new("Frame"); win.Size = UDim2.fromOffset(420, 300); win.Position = UDim2.fromOffset(30, 120)
win.BackgroundColor3 = Color3.fromRGB(12, 12, 15); win.BorderSizePixel = 0; win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local strokeE = Instance.new("UIStroke"); strokeE.Color = Color3.fromRGB(220, 30, 40); strokeE.Thickness = 1.3; strokeE.Parent = win
local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1; title.Position = UDim2.fromOffset(12, 6); title.Size = UDim2.new(1, -80, 0, 22)
title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextColor3 = Color3.fromRGB(240, 240, 245); title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Remote Recorder — tap a line to copy"; title.Parent = win
local clr = Instance.new("TextButton"); clr.AnchorPoint = Vector2.new(1, 0); clr.Position = UDim2.new(1, -8, 0, 6); clr.Size = UDim2.fromOffset(60, 20)
clr.BackgroundColor3 = Color3.fromRGB(40, 40, 46); clr.Text = "Clear"; clr.TextColor3 = Color3.fromRGB(235, 235, 235); clr.TextSize = 12; clr.Font = Enum.Font.GothamBold; clr.Parent = win
Instance.new("UICorner", clr).CornerRadius = UDim.new(0, 6)
local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(8, 32); list.Size = UDim2.new(1, -16, 1, -40)
list.BackgroundColor3 = Color3.fromRGB(8, 8, 10); list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.CanvasSize = UDim2.new(0, 0, 0, 0); list.Parent = win
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 3); lay.Parent = list
clr.MouseButton1Click:Connect(function() for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end end)
-- drag
do
    local UIS = game:GetService("UserInputService"); local drag, ds, sp
    title.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; ds = i.Position; sp = win.Position end end)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

local seen = {}
local function addEntry(code, label)
    if seen[code] then return end   -- dedupe identical captures
    seen[code] = true
    print("[Recorder] " .. code)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -6, 0, 0); b.AutomaticSize = Enum.AutomaticSize.Y
    b.BackgroundColor3 = Color3.fromRGB(22, 22, 26); b.TextColor3 = Color3.fromRGB(120, 235, 150)
    b.Font = Enum.Font.Code; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left; b.TextYAlignment = Enum.TextYAlignment.Top
    b.TextWrapped = true; b.Text = " " .. label .. "\n " .. code; b.Parent = list
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 3); pad.PaddingBottom = UDim.new(0, 3); pad.Parent = b
    b.MouseButton1Click:Connect(function() pcall(clip, code); notify("Copied — paste it to me in chat", 3); b.TextColor3 = Color3.fromRGB(255, 220, 90); task.delay(0.6, function() b.TextColor3 = Color3.fromRGB(120, 235, 150) end) end)
    task.defer(function() list.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 6) end)
end

-- skip the high-frequency spam remotes so the list stays useful
local SKIP = { Heartbeat = true, RenderStepped = true, Stepped = true, Ping = true, Replicate = true }
local function onFire(method, remote, args)
    if not (remote and remote.FireServer) then end
    local ok, name = pcall(function() return remote.Name end); if not ok then return end
    if SKIP[name] then return end
    local parts = {}
    for i = 1, #args do parts[i] = ser(args[i]) end
    local code = ("%s:%s(%s)"):format(instPath(remote), method, table.concat(parts, ", "))
    addEntry(code, name .. "  (" .. method .. ")")
end

-- ── the hook ──────────────────────────────────────────────────────────────────────
local hooked = false
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
            local a = { ... }
            task.spawn(function() pcall(onFire, m, self, a) end)
        end
        return old(self, ...)
    end)
    hooked = true
elseif typeof(hookfunction) == "function" then
    -- fallback: hook the RemoteEvent.FireServer function directly
    local mt = getrawmetatable and getrawmetatable(game)
    pcall(function()
        local re = Instance.new("RemoteEvent")
        local old; old = hookfunction(re.FireServer, function(self, ...)
            local a = { ... }; task.spawn(function() pcall(onFire, "FireServer", self, a) end)
            return old(self, ...)
        end)
        re:Destroy(); hooked = true
    end)
end

if hooked then
    notify("Recorder ON — do a move (earthquake / BF / teleport), then tap a line to copy it.", 8)
    addEntry('-- do your move now; captures appear here --', "ready")
else
    notify("Your executor can't hook remotes — try a different one (SimpleSpy also works).", 10)
    addEntry("-- executor lacks hookmetamethod/hookfunction; use SimpleSpy instead --", "no hook")
end
