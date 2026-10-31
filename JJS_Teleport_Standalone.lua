--[[  Jujutsu Shenanigans — TELEPORT (standalone, kick-safe)
      This is ONLY the bypass + teleport (your exact code) with a small GUI. Because it's minimal —
      no combat modules, no ownership loop — nothing trips the anti-cheat, so it won't 267-kick you.
      Bypass: blocks :Kick() (Error 267), disables local anti-cheat scripts, blocks the AntiCheat
      Teleport remote (no set-back). Teleport: plain CFrame + a short Heartbeat lock.
      Load:  loadstring(game:HttpGet("<raw url>"))()  ]]

-- ═══════════════════════════════════════════════════════════
-- JUJUTSU SHENANIGANS BYPASS (your exact script, verbatim)
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local allowAntiCheatTP = false
local AntiCheatTP = nil

local function findAntiCheatRemote()
    local rs = game:GetService("ReplicatedStorage")
    for _, v in ipairs(rs:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name == "Teleport" then
            local parent = v.Parent
            for i = 1, 5 do
                if not parent then break end
                if parent.Name:lower():find("anticheat") then
                    return v
                end
                parent = parent.Parent
            end
        end
    end
    return nil
end

AntiCheatTP = findAntiCheatRemote()

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if method == "Kick" and self == LP then
            return nil
        end

        if (method == "FireServer" or method == "InvokeServer") and not allowAntiCheatTP then
            if self == AntiCheatTP then
                return nil
            end
            if self and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) and self.Name == "Teleport" then
                local p = self.Parent
                local isAC = false
                for i=1, 5 do
                    if not p then break end
                    if p.Name:lower():find("anticheat") then
                        isAC = true
                        break
                    end
                    p = p.Parent
                end
                if isAC then return nil end
            end
        end

        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
end)

task.spawn(function()
    local function disableScripts(parent)
        if not parent then return end
        for _, v in ipairs(parent:GetDescendants()) do
            if v:IsA("LocalScript") then
                local name = v.Name:lower()
                if name:find("anti") or name:find("cheat") or name:find("detect") then
                    pcall(function()
                        v.Disabled = true
                        v.Parent = nil
                    end)
                end
            end
        end
    end
    local function disableAll()
        if LP:FindFirstChild("PlayerScripts") then disableScripts(LP.PlayerScripts) end
        if LP:FindFirstChild("Character") then disableScripts(LP.Character) end
        disableScripts(game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"))
    end
    disableAll()
    task.wait(2)
    disableAll()
end)

print("[JJS Teleport] Bypass loaded: Kick blocked & Anti-Cheat disabled.")

-- ═══════════════════════════════════════════════════════════
-- TELEPORT (your exact safeTeleport: CFrame + Heartbeat lock)
-- ═══════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local teleportLock = false
local currentTargetCFrame = nil
local savedTick = nil

RunService.Heartbeat:Connect(function()
    if teleportLock and currentTargetCFrame then
        local char = LP.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = currentTargetCFrame
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end
        end
    end
end)

local function safeTeleport(targetCFrame)
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if not savedTick then savedTick = tick() end
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("AlignPosition") or v:IsA("AlignOrientation") or v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("BodyGyro") then pcall(function() v:Destroy() end) end
    end
    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    currentTargetCFrame = targetCFrame
    teleportLock = true
    hrp.CFrame = targetCFrame
    task.delay(0.5, function() teleportLock = false; currentTargetCFrame = nil end)
    return true
end

-- ═══════════════════════════════════════════════════════════
-- GUI: teleport to any player (behind them) + save / goto a spot
-- ═══════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "\0"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 2e9
pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(250, 320); win.Position = UDim2.fromOffset(24, 130)
win.BackgroundColor3 = Color3.fromRGB(12, 12, 14); win.BorderSizePixel = 0; win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(200, 30, 40); st.Thickness = 1.4; st.Parent = win

local hdr = Instance.new("TextLabel")
hdr.BackgroundTransparency = 1; hdr.Position = UDim2.fromOffset(12, 6); hdr.Size = UDim2.new(1, -24, 0, 20)
hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 13; hdr.TextColor3 = Color3.fromRGB(240, 240, 245)
hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.Text = "JJS Teleport  (kick-safe)"; hdr.Parent = win

local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Position = UDim2.fromOffset(10, 30); row.Size = UDim2.new(1, -20, 0, 26); row.Parent = win
local function mkBtn(txt, w, x)
    local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(w, 26); b.Position = UDim2.fromOffset(x, 0)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 46); b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Parent = row; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); return b
end
local saveB = mkBtn("Save Spot", 110, 0)
local gotoB = mkBtn("Go To Spot", 110, 120)
local savedSpot
saveB.MouseButton1Click:Connect(function() local c=LP.Character; local h=c and c:FindFirstChild("HumanoidRootPart"); if h then savedSpot=h.CFrame; saveB.Text="Saved!"; task.delay(1,function() saveB.Text="Save Spot" end) end end)
gotoB.MouseButton1Click:Connect(function() if savedSpot then safeTeleport(savedSpot) end end)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(10, 62); list.Size = UDim2.new(1, -20, 1, -72)
list.BackgroundColor3 = Color3.fromRGB(8, 8, 10); list.BorderSizePixel = 0; list.ScrollBarThickness = 4; list.CanvasSize = UDim2.new(); list.Parent = win
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 3); lay.Parent = list

local function refresh()
    for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -4, 0, 26)
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 34); b.Text = "  " .. p.Name; b.TextColor3 = Color3.fromRGB(225, 225, 230)
            b.Font = Enum.Font.Gotham; b.TextSize = 12; b.TextXAlignment = Enum.TextXAlignment.Left; b.Parent = list
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
            b.MouseButton1Click:Connect(function()
                if p.Character then
                    local cf = p.Character:GetPivot()
                    local behind = cf * CFrame.new(0, 0, 5)
                    safeTeleport(CFrame.lookAt(behind.Position, cf.Position))
                end
            end)
        end
    end
    task.defer(function() list.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 6) end)
end
refresh()
Players.PlayerAdded:Connect(function() task.wait(1); refresh() end)
Players.PlayerRemoving:Connect(function() task.wait(1); refresh() end)

do
    local drag, ds, sp
    hdr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; ds = i.Position; sp = win.Position end end)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "JJS Teleport", Text = "Loaded. Kick blocked, teleport ready.", Duration = 5 }) end)
