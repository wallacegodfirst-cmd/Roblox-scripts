-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  FREE Edition
-- Default Rayfield theme
-- F6 = Panic / destroy UI
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local WS         = game:GetService("Workspace")
local LP         = Players.LocalPlayer

-- ── RAYFIELD ────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "Wallace Chaos Hub  |  FREE",
    Icon             = 0,
    LoadingTitle     = "Wallace Chaos Hub",
    LoadingSubtitle  = "Free Edition",
    Theme            = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
})

-- ── HELPERS ─────────────────────────────────────────────────
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ── ESP ─────────────────────────────────────────────────────
local espStore = {}

local function addESP(obj, color, tag)
    if espStore[obj] then
        -- refresh tag text if BillboardGui exists
        local bb = espStore[obj][2]
        if bb then
            local lbl = bb:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = tag end
        end
        return
    end
    local h = Instance.new("Highlight")
    h.FillColor        = color
    h.OutlineColor     = Color3.fromRGB(255,255,255)
    h.FillTransparency = 0.5
    h.Parent           = obj
    local bb
    if tag then
        bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0,140,0,28)
        bb.StudsOffset = Vector3.new(0,3.5,0)
        bb.Parent      = obj
        local lbl = Instance.new("TextLabel",bb)
        lbl.Size                   = UDim2.fromScale(1,1)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3             = color
        lbl.TextStrokeTransparency = 0
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextScaled             = true
        lbl.Text                   = tag
    end
    espStore[obj] = {h, bb}
end

local function removeESP(obj)
    local t = espStore[obj]; if not t then return end
    for _, v in ipairs(t) do if v and v.Parent then v:Destroy() end end
    espStore[obj] = nil
end

local function clearAllESP()
    for obj in pairs(espStore) do removeESP(obj) end
end

-- ── STATE ───────────────────────────────────────────────────
local S = {
    playerESP    = false,
    itemESP      = false,
    noStun       = false,
    speedHack    = false,
    speed        = 28,
    invis        = false,
    godMode      = false,
    noDark       = false,
    autoOpenDoor = false,
    stayCircle   = false,
    antiPush     = false,
    autoRevive   = false,
}

-- ── MAP REFERENCES ──────────────────────────────────────────
local MAP        = WS:WaitForChild("Map", 10)
local MAP_MODELS = MAP and MAP:FindFirstChild("MapModels")
local CHEF_NAMES = {"ChefOne","ChefTwo","ChefThree","ChefFour"}

-- ── PLAYER ESP ──────────────────────────────────────────────
local function updatePlayerESP()
    local myHRP = getHRP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        if S.playerESP then
            local tHRP = char:FindFirstChild("HumanoidRootPart")
            local dist = (myHRP and tHRP) and math.round((myHRP.Position-tHRP.Position).Magnitude) or 0
            addESP(char, Color3.fromRGB(255,220,50), plr.Name.."  ["..dist.."m]")
        else
            removeESP(char)
        end
    end
end

-- ── ITEM ESP (broad workspace scan) ─────────────────────────
-- Skips known non-item folders so we only catch actual game items
local KNOWN_FOLDERS = {
    Map=true, Chefs=true, Ghosts=true, Minefield=true,
    Camera=true, Terrain=true, Characters=true,
}
local function updateItemESP()
    for _, child in ipairs(WS:GetChildren()) do
        if KNOWN_FOLDERS[child.Name] then continue end
        -- scan folder children
        if child:IsA("Folder") then
            for _, item in ipairs(child:GetChildren()) do
                if S.itemESP then
                    addESP(item, Color3.fromRGB(0,255,150), item.Name)
                else
                    removeESP(item)
                end
            end
        -- lone model/part with a prompt = likely a pickup
        elseif child:IsA("Model") or child:IsA("BasePart") then
            local hasPrompt = child:FindFirstChildOfClass("ProximityPrompt",true)
                           or child:FindFirstChildOfClass("ClickDetector",true)
            if hasPrompt then
                if S.itemESP then
                    addESP(child, Color3.fromRGB(0,255,150), child.Name)
                else
                    removeESP(child)
                end
            end
        end
    end
end

-- ── NO STUN ─────────────────────────────────────────────────
-- workspace.[name].StunHandler.StunEvent  (BindableEvent)
local stunConn = nil
local function connectNoStun()
    if stunConn then stunConn:Disconnect(); stunConn = nil end
    local char = getChar(); if not char then return end
    local function hook(handler)
        local ev = handler:FindFirstChild("StunEvent")
        if ev then
            stunConn = ev.Event:Connect(function()
                if not S.noStun then return end
                local hum = getHum()
                if hum then hum.WalkSpeed = S.speedHack and S.speed or 16 end
            end)
        end
    end
    local h = char:FindFirstChild("StunHandler")
    if h then hook(h) end
    char.ChildAdded:Connect(function(c)
        if c.Name == "StunHandler" and S.noStun then hook(c) end
    end)
end

-- ── INVIS ───────────────────────────────────────────────────
local function applyInvis(on)
    local char = getChar(); if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if (p:IsA("BasePart") or p:IsA("MeshPart")) and p.Name ~= "HumanoidRootPart" then
            p.LocalTransparencyModifier = on and 1 or 0
        end
    end
end

-- ── GOD MODE ────────────────────────────────────────────────
local function doGodMode()
    local hum = getHum(); if not hum then return end
    hum.Health = hum.MaxHealth
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
end

-- ── NO DARK ─────────────────────────────────────────────────
local function applyNoDark()
    Lighting.ClockTime      = 14
    Lighting.Brightness     = 3
    Lighting.Ambient        = Color3.fromRGB(200,200,200)
    Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    Lighting.FogEnd         = 100000
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
            obj.Enabled = false
        end
    end
end

-- ── TELEPORTS ───────────────────────────────────────────────
local function tpToPlayer(name)
    local plr = Players:FindFirstChild(name)
    if not plr or not plr.Character then return end
    local hrp = getHRP()
    local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then hrp.CFrame = tHRP.CFrame * CFrame.new(0,0,3.5) end
end

local function tpToChef(name)
    local chefs = WS:FindFirstChild("Chefs"); if not chefs then return end
    local chef  = chefs:FindFirstChild(name); if not chef then return end
    local hrp   = getHRP()
    local root  = chef:FindFirstChildOfClass("Part") or chef:FindFirstChildOfClass("MeshPart")
    if hrp and root then hrp.CFrame = root.CFrame * CFrame.new(0,0,5) end
end

-- ── AUTO OPEN DOOR ──────────────────────────────────────────
local function doAutoOpenDoors()
    local myHRP = getHRP(); if not myHRP then return end
    -- colored doors
    local doorsF = MAP and MAP:FindFirstChild("Doors")
    if doorsF then
        for _, dm in ipairs(doorsF:GetChildren()) do
            local main = dm:FindFirstChild("Door") and dm.Door:FindFirstChild("Main")
            if main then
                local pp = main:FindFirstChild("DoorPrompt")
                if pp and (myHRP.Position - main.Position).Magnitude < 25 then
                    pcall(fireproximityprompt, pp)
                end
            end
        end
    end
    -- plain Door models in MapModels
    if MAP_MODELS then
        for _, obj in ipairs(MAP_MODELS:GetChildren()) do
            if obj.Name == "Door" then
                local pp = obj:FindFirstChildOfClass("ProximityPrompt",true)
                if pp then
                    local anchor = pp.Parent
                    if anchor:IsA("BasePart") and (myHRP.Position - anchor.Position).Magnitude < 25 then
                        pcall(fireproximityprompt, pp)
                    end
                end
            end
        end
    end
end

-- ── STAY IN KING CIRCLE ─────────────────────────────────────
-- ButtonZone confirmed at workspace.Map.MapModels.ButtonZone
local function getCircle()
    if MAP_MODELS then
        local bz = MAP_MODELS:FindFirstChild("ButtonZone")
        if bz and bz:IsA("BasePart") then return bz end
        for _, obj in ipairs(MAP_MODELS:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("zone") or n:find("circle") or n:find("king") then return obj end
            end
        end
    end
    return nil
end

local function doStayInCircle()
    local hrp = getHRP(); local circle = getCircle()
    if not hrp or not circle then return end
    local center = circle.Position
    local radius = math.min(circle.Size.X, circle.Size.Z)/2 - 0.8
    local myPos  = hrp.Position
    local flat   = Vector3.new(myPos.X, center.Y, myPos.Z)
    if (flat-center).Magnitude > radius then
        local dir    = (flat-center).Unit
        local safeXZ = center + dir * (radius-0.3)
        hrp.CFrame   = CFrame.new(Vector3.new(safeXZ.X,myPos.Y,safeXZ.Z),
                                  Vector3.new(center.X, myPos.Y,center.Z))
    end
end

-- ── ANTI PUSH ───────────────────────────────────────────────
local function doAntiPush()
    local hrp = getHRP(); if not hrp then return end
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") or v:IsA("BodyForce") then
            pcall(function() v.Velocity = Vector3.zero end)
            pcall(function() v.Force    = Vector3.zero end)
        end
    end
end

-- ── AUTO REVIVE ─────────────────────────────────────────────
local function doAutoRevive()
    local hum = getHum()
    if hum and hum.Health <= 0 then pcall(function() LP:LoadCharacter() end) end
end

-- ── MAIN LOOP ───────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    pcall(function()
        if S.speedHack   then local h=getHum(); if h then h.WalkSpeed=S.speed end end
        if S.godMode     then doGodMode()     end
        if S.noDark      then applyNoDark()   end
        if S.antiPush    then doAntiPush()    end
        if S.stayCircle  then doStayInCircle() end
        if S.autoRevive  then doAutoRevive()  end
    end)
end)

local espT = 0
RunService.Heartbeat:Connect(function(dt)
    espT += dt; if espT < 0.3 then return end; espT = 0
    pcall(function()
        if S.playerESP then updatePlayerESP() end
        if S.itemESP   then updateItemESP()   end
    end)
end)

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if S.invis  then applyInvis(true) end
    if S.noStun then connectNoStun()  end
end)
connectNoStun()

-- ═══════════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════════

-- TAB: VISUALS
local tVis = Window:CreateTab("Visuals", 4483362458)

tVis:CreateToggle({ Name="Player ESP", CurrentValue=false, Callback=function(v)
    S.playerESP = v
    if not v then for _,p in ipairs(Players:GetPlayers()) do if p.Character then removeESP(p.Character) end end end
end})

tVis:CreateToggle({ Name="Item ESP", CurrentValue=false, Callback=function(v)
    S.itemESP = v
    if not v then clearAllESP() end
end})

tVis:CreateToggle({ Name="No Dark  (Always Bright)", CurrentValue=false, Callback=function(v)
    S.noDark = v
    if not v then
        Lighting.ClockTime=8; Lighting.Brightness=1
        Lighting.Ambient=Color3.fromRGB(127,127,127)
        Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127)
        for _,obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") then obj.Enabled=true end
        end
    end
end})

-- TAB: COMBAT
local tCom = Window:CreateTab("Combat", 4483362458)

tCom:CreateToggle({ Name="God Mode", CurrentValue=false, Callback=function(v) S.godMode=v end})
tCom:CreateToggle({ Name="No Stun",  CurrentValue=false, Callback=function(v)
    S.noStun=v; if v then connectNoStun() end
end})
tCom:CreateToggle({ Name="Anti Push",   CurrentValue=false, Callback=function(v) S.antiPush=v end})
tCom:CreateToggle({ Name="Auto Revive", CurrentValue=false, Callback=function(v) S.autoRevive=v end})

-- TAB: MOVEMENT
local tMov = Window:CreateTab("Movement", 4483362458)

tMov:CreateToggle({ Name="Speed Hack", CurrentValue=false, Callback=function(v) S.speedHack=v end})
tMov:CreateSlider({ Name="Speed", Range={16,150}, Increment=1, CurrentValue=28,
    Callback=function(v) S.speed=v end})
tMov:CreateToggle({ Name="Invisibility  (local)", CurrentValue=false, Callback=function(v)
    S.invis=v; applyInvis(v)
end})
tMov:CreateDivider()

tMov:CreateDropdown({
    Name="Teleport to Player",
    Options=(function() local t={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then t[#t+1]=p.Name end end; return t end)(),
    CurrentOption={}, MultipleOptions=false,
    Callback=function(opt) if opt and opt[1] then tpToPlayer(opt[1]) end end,
})

tMov:CreateDivider()
for _, cname in ipairs(CHEF_NAMES) do
    tMov:CreateButton({ Name="TP to "..cname, Callback=function() tpToChef(cname) end})
end

-- TAB: AUTO
local tAut = Window:CreateTab("Auto", 4483362458)

tAut:CreateToggle({ Name="Auto Open Doors", CurrentValue=false, Callback=function(v)
    S.autoOpenDoor=v
    if v then task.spawn(function() while S.autoOpenDoor do pcall(doAutoOpenDoors); task.wait(0.4) end end) end
end})
tAut:CreateToggle({ Name="Stay in King Circle", CurrentValue=false, Callback=function(v) S.stayCircle=v end})

-- TAB: SETTINGS
local tSet = Window:CreateTab("Settings", 4483362458)
tSet:CreateLabel("Wallace Chaos Hub  —  FREE Edition")
tSet:CreateLabel("Press F6 to panic / destroy UI")
tSet:CreateDivider()
tSet:CreateLabel("Upgrade to PAID for:")
tSet:CreateLabel("Mine ESP, Ghost ESP, Kill Aura, Fling,")
tSet:CreateLabel("Always Get Button, Auto Attack,")
tSet:CreateLabel("Auto Alpha/Beta/Delta, Carry Kill, + more")

-- PANIC
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F6 then
        S.godMode=false; S.speedHack=false; S.autoOpenDoor=false
        S.stayCircle=false; S.antiPush=false; S.playerESP=false; S.itemESP=false
        clearAllESP()
        local h=getHum(); if h then h.WalkSpeed=16 end
        pcall(function() Rayfield:Destroy() end)
    end
end)

Rayfield:Notify({ Title="Wallace Chaos Hub", Content="FREE Edition loaded!", Duration=4 })
