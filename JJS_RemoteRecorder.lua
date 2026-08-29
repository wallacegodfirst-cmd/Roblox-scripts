--[[ Dream Hub — Remote Recorder (JJS)  v2
     Run this, then do a move MANUALLY (earthquake / black flash / teleport). Every FireServer /
     InvokeServer you send is captured as ready-to-paste Lua. Tap a line (or "COPY LAST") to copy it,
     then paste it to me in chat. Everything is also printed to the F9 console as a backup.  ]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LP      = Players.LocalPlayer

-- robust clipboard: try every known executor function
local function copy(text)
    local fns = { setclipboard, toclipboard, (syn and syn.write_clipboard), (Clipboard and Clipboard.set), writeclipboard }
    for _, f in ipairs(fns) do if typeof(f) == "function" then local ok = pcall(f, text); if ok then return true end end end
    return false
end
local function notify(m, d) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Recorder", Text = m, Duration = d or 4 }) end) end

-- ── serialize any value to copyable Lua ─────────────────────────────────────────
local function isBinary(s) for i = 1, #s do local b = s:byte(i); if b < 9 or (b > 13 and b < 32) or b > 126 then return true end end return false end
local function strLit(s)
    if not isBinary(s) then return string.format("%q", s) end
    local t = {}; for i = 1, #s do t[i] = "\\" .. s:byte(i) end; return '"' .. table.concat(t) .. '"'
end
local function instPath(o)
    local ok, full = pcall(function() return o:GetFullName() end)
    if not ok then return "nil" end
    local parts = string.split(full, "."); local expr = 'game:GetService("' .. parts[1] .. '")'
    for i = 2, #parts do expr = expr .. ':WaitForChild("' .. parts[i] .. '")' end
    return expr
end
local ser
ser = function(v, seen)
    seen = seen or {}
    local tp = typeof(v)
    if tp == "string" then return strLit(v)
    elseif tp == "number" or tp == "boolean" or tp == "nil" then return tostring(v)
    elseif tp == "buffer" then local ok, s = pcall(buffer.tostring, v); return ok and ("buffer.fromstring(" .. strLit(s) .. ")") or "nil"
    elseif tp == "Instance" then return instPath(v)
    elseif tp == "Vector3" then return ("Vector3.new(%s, %s, %s)"):format(v.X, v.Y, v.Z)
    elseif tp == "CFrame" then return "CFrame.new(" .. table.concat({ v:GetComponents() }, ", ") .. ")"
    elseif tp == "table" then
        if seen[v] then return "{}" end; seen[v] = true
        local out = {}; for k, val in pairs(v) do
            local key = (type(k) == "string" and k:match("^%a[%w_]*$")) and (k .. " = ") or ("[" .. ser(k, seen) .. "] = ")
            out[#out + 1] = key .. ser(val, seen)
        end
        return "{ " .. table.concat(out, ", ") .. " }"
    else return tostring(v) end
end

-- ── GUI ─────────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui"); gui.Name = "DreamRecorder"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 2e9
pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
local win = Instance.new("Frame"); win.Size = UDim2.fromOffset(440, 320); win.Position = UDim2.fromOffset(30, 110)
win.BackgroundColor3 = Color3.fromRGB(12, 12, 15); win.BorderSizePixel = 0; win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local s0 = Instance.new("UIStroke"); s0.Color = Color3.fromRGB(220, 30, 40); s0.Thickness = 1.3; s0.Parent = win
local hdr = Instance.new("TextLabel"); hdr.BackgroundTransparency = 1; hdr.Position = UDim2.fromOffset(12, 6); hdr.Size = UDim2.new(1, -24, 0, 20)
hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 13; hdr.TextColor3 = Color3.fromRGB(240, 240, 245); hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.Text = "Recorder — do a move, then tap a line to copy   (fired: 0)"; hdr.Parent = win
local copyLast = Instance.new("TextButton"); copyLast.Position = UDim2.fromOffset(12, 28); copyLast.Size = UDim2.fromOffset(110, 22)
copyLast.BackgroundColor3 = Color3.fromRGB(220, 30, 40); copyLast.Text = "COPY LAST"; copyLast.TextColor3 = Color3.new(1, 1, 1); copyLast.TextSize = 12; copyLast.Font = Enum.Font.GothamBold; copyLast.Parent = win
Instance.new("UICorner", copyLast).CornerRadius = UDim.new(0, 6)
local clrB = Instance.new("TextButton"); clrB.Position = UDim2.fromOffset(128, 28); clrB.Size = UDim2.fromOffset(60, 22)
clrB.BackgroundColor3 = Color3.fromRGB(40, 40, 46); clrB.Text = "Clear"; clrB.TextColor3 = Color3.new(1, 1, 1); clrB.TextSize = 12; clrB.Font = Enum.Font.GothamBold; clrB.Parent = win
Instance.new("UICorner", clrB).CornerRadius = UDim.new(0, 6)
local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(8, 56); list.Size = UDim2.new(1, -16, 1, -64)
list.BackgroundColor3 = Color3.fromRGB(8, 8, 10); list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.CanvasSize = UDim2.new(); list.Parent = win
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 3); lay.Parent = list
do
    local UIS = game:GetService("UserInputService"); local drag, ds, sp
    hdr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; ds = i.Position; sp = win.Position end end)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

local total, lastCode = 0, nil
clrB.MouseButton1Click:Connect(function() for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end end)
copyLast.MouseButton1Click:Connect(function()
    if not lastCode then notify("Nothing captured yet — do a move first", 3); return end
    local ok = copy(lastCode); notify(ok and "Copied the last capture — paste it to me" or "Clipboard blocked — copy it from the F9 console", 5)
end)

local function addEntry(code, label)
    total += 1; lastCode = code
    hdr.Text = ("Recorder — tap a line to copy   (fired: %d)"):format(total)
    print("[Recorder] " .. label .. "  ==>  " .. code)   -- F9 backup
    local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -6, 0, 0); b.AutomaticSize = Enum.AutomaticSize.Y
    b.BackgroundColor3 = Color3.fromRGB(22, 22, 26); b.TextColor3 = Color3.fromRGB(120, 235, 150)
    b.Font = Enum.Font.Code; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left; b.TextYAlignment = Enum.TextYAlignment.Top
    b.TextWrapped = true; b.Text = " " .. label .. "\n " .. code; b.LayoutOrder = -total; b.Parent = list
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local p = Instance.new("UIPadding"); p.PaddingTop = UDim.new(0, 3); p.PaddingBottom = UDim.new(0, 3); p.PaddingLeft = UDim.new(0, 4); p.Parent = b
    b.MouseButton1Click:Connect(function()
        local ok = copy(code); notify(ok and "Copied — paste it to me in chat" or "Clipboard blocked — copy from F9 console", 5)
        b.TextColor3 = Color3.fromRGB(255, 220, 90); task.delay(0.6, function() b.TextColor3 = Color3.fromRGB(120, 235, 150) end)
    end)
    task.defer(function() list.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 6) end)
    -- keep the list from growing forever
    local kids = {}; for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then kids[#kids + 1] = c end end
    if #kids > 40 then table.sort(kids, function(a, c) return a.LayoutOrder > c.LayoutOrder end); kids[#kids]:Destroy() end
end

local function onFire(method, remote, args)
    local ok, name = pcall(function() return remote.Name end); if not ok then return end
    local parts = {}; for i = 1, select("#", table.unpack(args)) do parts[i] = ser(args[i]) end
    -- fallback if select# on a sparse table misbehaves
    if #parts == 0 and #args > 0 then for i = 1, #args do parts[i] = ser(args[i]) end end
    local code = ("%s:%s(%s)"):format(instPath(remote), method, table.concat(parts, ", "))
    addEntry(code, name .. " (" .. method .. ")")
end

-- ── HOOK — captures ALL FireServer / InvokeServer (no filtering) ────────────────────
local installed = false
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
    local ok = pcall(function()
        local old; old = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
                local a = { ... }
                task.spawn(function() pcall(onFire, m, self, a) end)
            end
            return old(self, ...)
        end)
    end)
    installed = ok
end
if not installed and typeof(hookfunction) == "function" then
    pcall(function()
        local re = Instance.new("RemoteEvent")
        local old; old = hookfunction(re.FireServer, function(self, ...)
            local a = { ... }; task.spawn(function() pcall(onFire, "FireServer", self, a) end)
            return old(self, ...)
        end)
        re:Destroy(); installed = true
    end)
end

if installed then
    notify("Recorder ON. Do the earthquake / BF / teleport now — captures appear in the window.", 8)
    addEntry("-- ready: do your move now --", "ready")
else
    notify("Your executor can't hook remotes. Use SimpleSpy instead (same result).", 10)
    hdr.Text = "Recorder — this executor can't hook remotes (use SimpleSpy)"
end
