-- Simple Hub - Fly / Noclip / Speed (Rayfield, universal)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local S = { Fly=false, FlySpeed=60, Noclip=false, SpeedOn=false, Speed=16 }

local function getChar() return LP.Character end
local function getHum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c=LP.Character; return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end

-- ── SPEED ──────────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if S.SpeedOn then local h=getHum(); if h then pcall(function() h.WalkSpeed=S.Speed end) end end
end)

-- ── NOCLIP ─────────────────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then pcall(function() p.CanCollide=false end) end
    end
end)

-- ── FLY ────────────────────────────────────────────────────────────────────
local keys = {W=false,A=false,S=false,D=false,Up=false,Down=false}
UIS.InputBegan:Connect(function(i,gpe) if gpe then return end local k=i.KeyCode
    if k==Enum.KeyCode.W then keys.W=true elseif k==Enum.KeyCode.A then keys.A=true
    elseif k==Enum.KeyCode.S then keys.S=true elseif k==Enum.KeyCode.D then keys.D=true
    elseif k==Enum.KeyCode.Space then keys.Up=true elseif k==Enum.KeyCode.LeftControl then keys.Down=true end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode
    if k==Enum.KeyCode.W then keys.W=false elseif k==Enum.KeyCode.A then keys.A=false
    elseif k==Enum.KeyCode.S then keys.S=false elseif k==Enum.KeyCode.D then keys.D=false
    elseif k==Enum.KeyCode.Space then keys.Up=false elseif k==Enum.KeyCode.LeftControl then keys.Down=false end end)

RunService.RenderStepped:Connect(function(dt)
    if not S.Fly then return end
    local root=getRoot(); local cam=workspace.CurrentCamera
    if not (root and cam) then return end
    local hum=getHum()
    if hum then pcall(function() hum.PlatformStand=true end) end
    local dir=Vector3.zero
    if keys.W then dir+=cam.CFrame.LookVector end
    if keys.S then dir-=cam.CFrame.LookVector end
    if keys.A then dir-=cam.CFrame.RightVector end
    if keys.D then dir+=cam.CFrame.RightVector end
    if keys.Up then dir+=Vector3.yAxis end
    if keys.Down then dir-=Vector3.yAxis end
    pcall(function()
        root.AssemblyLinearVelocity=Vector3.zero
        if dir.Magnitude>0 then root.CFrame=root.CFrame+dir.Unit*S.FlySpeed*dt end
    end)
end)
-- release PlatformStand when fly turns off
task.spawn(function()
    local was=false
    while task.wait(0.1) do
        if S.Fly then was=true
        elseif was then was=false; local h=getHum(); if h then pcall(function() h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end
    end
end)

-- ── GUI ────────────────────────────────────────────────────────────────────
local Win = Rayfield:CreateWindow({
    Name = "Simple Hub",
    LoadingTitle = "Fly / Noclip / Speed",
    LoadingSubtitle = "simple",
    ConfigurationSaving = { Enabled = false },
})
local Tab = Win:CreateTab("Main", 4483362458)

Tab:CreateToggle({Name="Fly  (WASD + Space/Ctrl)", CurrentValue=false, Flag="Fly", Callback=function(v) S.Fly=v end})
Tab:CreateSlider({Name="Fly Speed", Range={10,250}, Increment=5, Suffix="spd", CurrentValue=60, Flag="FlySpeed", Callback=function(v) S.FlySpeed=v end})
Tab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v)
    S.Noclip=v
    if not v then local c=getChar(); if c then for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then pcall(function() p.CanCollide=true end) end end end end
end})
Tab:CreateToggle({Name="Speed", CurrentValue=false, Flag="SpeedOn", Callback=function(v)
    S.SpeedOn=v; if not v then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end
end})
Tab:CreateSlider({Name="Walk Speed", Range={1,100}, Increment=1, Suffix="spd", CurrentValue=16, Flag="Speed", Callback=function(v) S.Speed=v end})

Rayfield:Notify({Title="Simple Hub", Content="Loaded.", Duration=4})
