--[[  Ability Arena — GOD MODE (standalone)  extracted from Dream Hub | Ability Arena
      HOW IT WORKS: stand in the LOBBY, then toggle God Mode ON. It teleports you straight into the
      fight. Because the game never "armed" you for combat when you left the lobby this way, the server
      never registers you as a hittable combatant = you cannot be hurt. TRADE-OFF of the trick itself:
      you also can't M1 in that state (the game never armed your combat), so use it to survive / troll,
      or pair it with abilities. Toggle it while IN THE LOBBY for the effect.
      Load:  loadstring(game:HttpGet("<raw url to this file>"))()  ]]

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

-- ── helpers (from the AA hub, verbatim) ──────────────────────────────────────────
local function getRoot()
    local c = LP.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end
local function charPart(char)
    if not char then return nil end
    local hb = char:FindFirstChild("Hitbox")
    if hb then
        if hb:IsA("BasePart") then return hb end
        if hb:IsA("Model")    then return hb.PrimaryPart or hb:FindFirstChildWhichIsA("BasePart") end
    end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
end
local function isAlive(char)
    if not char or not char.Parent then return false end
    if char:GetAttribute("Dead") == true or char:FindFirstChild("Dead") then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then return h.Health > 0 end
    local hp = char:GetAttribute("Health")
    if type(hp) == "number" then return hp > 0 end
    return true
end
local function nearestPlayer(range)
    local best, dist, root = nil, range or math.huge, getRoot()
    if not root then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then
            local r = charPart(p.Character)
            if r then
                local d = (r.Position - root.Position).Magnitude
                if d < dist then best, dist = p, d end
            end
        end
    end
    return best
end

-- ── THE GOD MODE ACTION (verbatim from the hub's GodModeLobby toggle) ─────────────
local function doGodMode()
    task.spawn(function()
        local root = getRoot(); if not root then return end
        local dest
        -- PRIMARY: teleport onto a GameMap.Spawns part (your explorer) - this is what arms you into the fight
        pcall(function()
            local gm = Workspace:FindFirstChild("GameMap")
            local sp = gm and gm:FindFirstChild("Spawns")
            if sp then
                local parts = {}
                for _, c in ipairs(sp:GetChildren()) do if c:IsA("BasePart") then parts[#parts+1] = c end end
                if #parts == 0 then for _, c in ipairs(sp:GetDescendants()) do if c:IsA("BasePart") then parts[#parts+1] = c end end end
                if #parts > 0 then
                    local part = parts[(tick() // 1) % #parts + 1]   -- vary which spawn without Math.random
                    dest = part.Position + Vector3.new(0, 4, 0)
                end
            end
        end)
        -- FALLBACK: no GameMap yet -> land next to the nearest player
        if not dest then
            local p = nearestPlayer(math.huge)
            local tr = p and p.Character and charPart(p.Character)
            if tr then dest = tr.Position + Vector3.new(4, 3, 0) end
        end
        if dest then
            pcall(function() root.CFrame = CFrame.new(dest); root.AssemblyLinearVelocity = Vector3.zero end)
        end
    end)
end

-- ── tiny GUI ──────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AA_GodMode"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 2e9
pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(230, 92); win.Position = UDim2.fromOffset(24, 150)
win.BackgroundColor3 = Color3.fromRGB(12, 12, 14); win.BorderSizePixel = 0; win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(200, 30, 40); st.Thickness = 1.4; st.Parent = win

local hdr = Instance.new("TextLabel")
hdr.BackgroundTransparency = 1; hdr.Position = UDim2.fromOffset(12, 6); hdr.Size = UDim2.new(1, -24, 0, 18)
hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 13; hdr.TextColor3 = Color3.fromRGB(240, 240, 245)
hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.Text = "Ability Arena — God Mode"; hdr.Parent = win

local btn = Instance.new("TextButton")
btn.Position = UDim2.fromOffset(12, 30); btn.Size = UDim2.fromOffset(206, 30)
btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); btn.Text = "God Mode: OFF"
btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.Parent = win
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

local note = Instance.new("TextLabel")
note.BackgroundTransparency = 1; note.Position = UDim2.fromOffset(12, 64); note.Size = UDim2.new(1, -24, 0, 22)
note.Font = Enum.Font.Gotham; note.TextSize = 10; note.TextColor3 = Color3.fromRGB(170, 170, 178)
note.TextXAlignment = Enum.TextXAlignment.Left; note.TextWrapped = true
note.Text = "Turn ON while in the LOBBY. TPs you to the fight, can't be hurt (no M1 in this state)."
note.Parent = win

local on = false
local function setBtn()
    btn.Text = "God Mode: " .. (on and "ON" or "OFF")
    btn.BackgroundColor3 = on and Color3.fromRGB(200, 30, 40) or Color3.fromRGB(45, 45, 50)
end
btn.MouseButton1Click:Connect(function()
    on = not on; setBtn()
    if on then doGodMode() end
end)

-- draggable
do
    local drag, ds, sp
    hdr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; ds = i.Position; sp = win.Position end end)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "God Mode", Text = "Loaded. Toggle it ON in the lobby.", Duration = 5 }) end)
