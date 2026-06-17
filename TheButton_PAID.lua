-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  PAID Edition
-- Black / Blue / Red theme  —  ALL features
-- F6 = Panic / destroy UI
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local WS         = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer

-- ── RAYFIELD ────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "Wallace Chaos Hub  |  PAID",
    Icon             = 0,
    LoadingTitle     = "Wallace Chaos Hub",
    LoadingSubtitle  = "Black Edition  —  All Features",
    Theme = {
        TextColor                    = Color3.fromRGB(235,235,235),
        Background                   = Color3.fromRGB(10,10,14),
        Topbar                       = Color3.fromRGB(18,22,38),
        Shadow                       = Color3.fromRGB(0,0,0),
        NotificationBackground       = Color3.fromRGB(15,15,20),
        NotificationActionsBackground= Color3.fromRGB(30,40,70),
        TabBackground                = Color3.fromRGB(20,25,45),
        TabStroke                    = Color3.fromRGB(200,30,50),
        TabBackgroundSelected        = Color3.fromRGB(180,25,45),
        TabTextColor                 = Color3.fromRGB(210,210,230),
        SelectedTabTextColor         = Color3.fromRGB(255,255,255),
        ElementBackground            = Color3.fromRGB(16,20,36),
        ElementBackgroundHover       = Color3.fromRGB(30,40,75),
        SecondaryElementBackground   = Color3.fromRGB(14,18,32),
        ElementStroke                = Color3.fromRGB(40,60,110),
        SecondaryElementStroke       = Color3.fromRGB(120,20,35),
        SliderBackground             = Color3.fromRGB(180,25,45),
        SliderProgress               = Color3.fromRGB(30,100,220),
        SliderStroke                 = Color3.fromRGB(80,130,220),
        ToggleBackground             = Color3.fromRGB(20,30,60),
        ToggleEnabled                = Color3.fromRGB(220,30,50),
        ToggleDisabled               = Color3.fromRGB(40,45,60),
        ToggleEnabledStroke          = Color3.fromRGB(255,80,100),
        ToggleDisabledStroke         = Color3.fromRGB(60,80,130),
        ToggleEnabledOuterStroke     = Color3.fromRGB(30,100,220),
        ToggleDisabledOuterStroke    = Color3.fromRGB(40,60,100),
        DropdownSelected             = Color3.fromRGB(180,25,45),
        DropdownUnselected           = Color3.fromRGB(20,25,45),
        InputBackground              = Color3.fromRGB(15,18,30),
        InputStroke                  = Color3.fromRGB(180,30,50),
        PlaceholderColor             = Color3.fromRGB(150,150,170),
    },
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
    if not obj or not obj.Parent then return end
    local existing = espStore[obj]
    if existing then
        local bb = existing[2]
        if bb then
            local lbl = bb:FindFirstChildOfClass("TextLabel")
            if lbl and tag then lbl.Text = tag end
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
        bb.Size        = UDim2.new(0,160,0,28)
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
    -- free
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
    -- paid visuals
    mineESP      = false,
    ghostESP     = false,
    -- paid combat
    killAura     = false,
    killRadius   = 20,
    autoAttack   = false,
    fling        = false,
    autoKillNPC  = false,
    -- paid auto
    alwaysButton  = false,
    autoGrab      = false,
    grabRadius    = 35,
    autoFarm      = false,
    autoAlpha     = false,
    autoBeta      = false,
    autoDelta     = false,
    -- paid carry
    autoCarry     = false,
    carryTarget   = nil,
    savedCF       = nil,
}

-- ── MAP REFERENCES ──────────────────────────────────────────
local MAP        = WS:WaitForChild("Map", 10)
local MAP_MODELS = MAP and MAP:FindFirstChild("MapModels")
local CHEF_NAMES = {"ChefOne","ChefTwo","ChefThree","ChefFour"}
local VOID_POS   = Vector3.new(0,-5000,0)
local KNOWN_FOLDERS = {
    Map=true, Chefs=true, Ghosts=true, Minefield=true,
    Camera=true, Terrain=true, Characters=true,
}

-- ═══════════════════════════════════════════════════════════
-- ██ ESP UPDATES
-- ═══════════════════════════════════════════════════════════
local function updatePlayerESP()
    local myHRP = getHRP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character; if not char then continue end
        if S.playerESP then
            local tHRP = char:FindFirstChild("HumanoidRootPart")
            local dist = (myHRP and tHRP) and math.round((myHRP.Position-tHRP.Position).Magnitude) or 0
            addESP(char, Color3.fromRGB(255,220,50), plr.Name.."  ["..dist.."m]")
        else removeESP(char) end
    end
end

-- Items: broad workspace scan + RS project folders
local function updateItemESP()
    -- workspace loose items
    for _, child in ipairs(WS:GetChildren()) do
        if KNOWN_FOLDERS[child.Name] then continue end
        if child:IsA("Folder") then
            for _, item in ipairs(child:GetChildren()) do
                if S.itemESP then addESP(item, Color3.fromRGB(0,255,150), item.Name)
                else removeESP(item) end
            end
        elseif child:IsA("Model") or child:IsA("BasePart") then
            local hasPrompt = child:FindFirstChildOfClass("ProximityPrompt",true)
                           or child:FindFirstChildOfClass("ClickDetector",true)
            if hasPrompt then
                if S.itemESP then addESP(child, Color3.fromRGB(0,255,150), child.Name)
                else removeESP(child) end
            end
        end
    end
end

-- Mine ESP: workspace.Minefield.Landmine (confirmed)
local function updateMineESP()
    local mf = WS:FindFirstChild("Minefield"); if not mf then return end
    for _, obj in ipairs(mf:GetChildren()) do
        if obj.Name == "Landmine" then
            local root = obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChildOfClass("MeshPart")
            if root then
                if S.mineESP then addESP(obj, Color3.fromRGB(255,40,40), "MINE")
                else removeESP(obj) end
            end
        end
    end
end

-- Ghost ESP: workspace.Ghosts.*
local function updateGhostESP()
    local ghosts = WS:FindFirstChild("Ghosts"); if not ghosts then return end
    for _, g in ipairs(ghosts:GetChildren()) do
        if S.ghostESP then
            addESP(g, Color3.fromRGB(0,220,255), "GHOST: "..g.Name)
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("MeshPart") then
                    d.LocalTransparencyModifier = 0.35
                end
            end
        else removeESP(g) end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ FREE FEATURES
-- ═══════════════════════════════════════════════════════════
local stunConn = nil
local function connectNoStun()
    if stunConn then stunConn:Disconnect(); stunConn=nil end
    local char = getChar(); if not char then return end
    local function hook(handler)
        local ev = handler:FindFirstChild("StunEvent")
        if ev then
            stunConn = ev.Event:Connect(function()
                if not S.noStun then return end
                local hum=getHum(); if hum then hum.WalkSpeed=S.speedHack and S.speed or 16 end
            end)
        end
    end
    local h = char:FindFirstChild("StunHandler")
    if h then hook(h) end
    char.ChildAdded:Connect(function(c)
        if c.Name=="StunHandler" and S.noStun then hook(c) end
    end)
end

local function applyInvis(on)
    local char = getChar(); if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if (p:IsA("BasePart") or p:IsA("MeshPart")) and p.Name~="HumanoidRootPart" then
            p.LocalTransparencyModifier = on and 1 or 0
        end
    end
end

local function doGodMode()
    local hum=getHum(); if not hum then return end
    hum.Health=hum.MaxHealth
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
end

local function applyNoDark()
    Lighting.ClockTime=14; Lighting.Brightness=3
    Lighting.Ambient=Color3.fromRGB(200,200,200)
    Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200)
    Lighting.FogEnd=100000
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
            obj.Enabled=false
        end
    end
end

local function tpToPlayer(name)
    local plr=Players:FindFirstChild(name); if not plr or not plr.Character then return end
    local hrp=getHRP(); local tHRP=plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,3.5) end
end

local function tpToChef(name)
    local chefs=WS:FindFirstChild("Chefs"); if not chefs then return end
    local chef=chefs:FindFirstChild(name); if not chef then return end
    local hrp=getHRP()
    local root=chef:FindFirstChildOfClass("Part") or chef:FindFirstChildOfClass("MeshPart")
    if hrp and root then hrp.CFrame=root.CFrame*CFrame.new(0,0,5) end
end

local function doAutoOpenDoors()
    local myHRP=getHRP(); if not myHRP then return end
    local doorsF=MAP and MAP:FindFirstChild("Doors")
    if doorsF then
        for _, dm in ipairs(doorsF:GetChildren()) do
            local main=dm:FindFirstChild("Door") and dm.Door:FindFirstChild("Main")
            if main then
                local pp=main:FindFirstChild("DoorPrompt")
                if pp and (myHRP.Position-main.Position).Magnitude<25 then
                    pcall(fireproximityprompt,pp)
                end
            end
        end
    end
    if MAP_MODELS then
        for _, obj in ipairs(MAP_MODELS:GetChildren()) do
            if obj.Name=="Door" then
                local pp=obj:FindFirstChildOfClass("ProximityPrompt",true)
                if pp then
                    local anchor=pp.Parent
                    if anchor:IsA("BasePart") and (myHRP.Position-anchor.Position).Magnitude<25 then
                        pcall(fireproximityprompt,pp)
                    end
                end
            end
        end
    end
end

local function getCircle()
    if MAP_MODELS then
        local bz=MAP_MODELS:FindFirstChild("ButtonZone")
        if bz and bz:IsA("BasePart") then return bz end
        for _, obj in ipairs(MAP_MODELS:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n=obj.Name:lower()
                if n:find("zone") or n:find("circle") or n:find("king") then return obj end
            end
        end
    end
    return nil
end

local function doStayInCircle()
    local hrp=getHRP(); local circle=getCircle()
    if not hrp or not circle then return end
    local center=circle.Position
    local radius=math.min(circle.Size.X,circle.Size.Z)/2-0.8
    local myPos=hrp.Position
    local flat=Vector3.new(myPos.X,center.Y,myPos.Z)
    if (flat-center).Magnitude>radius then
        local dir=(flat-center).Unit
        local safe=center+dir*(radius-0.3)
        hrp.CFrame=CFrame.new(Vector3.new(safe.X,myPos.Y,safe.Z),
                              Vector3.new(center.X,myPos.Y,center.Z))
    end
end

local function doAntiPush()
    local hrp=getHRP(); if not hrp then return end
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") or v:IsA("BodyForce") then
            pcall(function() v.Velocity=Vector3.zero end)
            pcall(function() v.Force=Vector3.zero end)
        end
    end
end

local function doAutoRevive()
    local hum=getHum()
    if hum and hum.Health<=0 then pcall(function() LP:LoadCharacter() end) end
end

-- ═══════════════════════════════════════════════════════════
-- ██ PAID FEATURES
-- ═══════════════════════════════════════════════════════════

-- ── ALWAYS GET BUTTON ───────────────────────────────────────
-- workspace.Map.MapModels.TheButton.Button.ButtonPrompt
local function tryGetButton()
    if not MAP_MODELS then return end
    local theBtn = MAP_MODELS:FindFirstChild("TheButton"); if not theBtn then return end
    local btn    = theBtn:FindFirstChild("Button");        if not btn    then return end
    local pp     = btn:FindFirstChild("ButtonPrompt")
    if pp then pcall(fireproximityprompt,pp) end
    local cd = btn:FindFirstChildOfClass("ClickDetector")
    if cd then pcall(fireclickdetector,cd) end
end

-- ── KILL AURA ───────────────────────────────────────────────
local function doKillAura()
    local hrp=getHRP(); if not hrp then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        local tHRP=char:FindFirstChild("HumanoidRootPart"); if not tHRP then continue end
        if (hrp.Position-tHRP.Position).Magnitude<=S.killRadius then
            local behind=tHRP.Position-tHRP.CFrame.LookVector*3
            hrp.CFrame=CFrame.new(Vector3.new(behind.X,tHRP.Position.Y,behind.Z),tHRP.Position)
            local bv=Instance.new("BodyVelocity")
            bv.Velocity=tHRP.CFrame.LookVector*-90+Vector3.new(0,55,0)
            bv.MaxForce=Vector3.one*1e7
            bv.Parent=tHRP
            task.delay(0.12,function() if bv and bv.Parent then bv:Destroy() end end)
        end
    end
end

-- ── AUTO ATTACK (targeted, nearest) ─────────────────────────
local function doAutoAttack()
    local hrp=getHRP(); if not hrp then return end
    local best,bestDist=nil,math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local c=plr.Character; if not c then continue end
        local tHRP=c:FindFirstChild("HumanoidRootPart"); if not tHRP then continue end
        local d=(hrp.Position-tHRP.Position).Magnitude
        if d<bestDist then best=plr; bestDist=d end
    end
    if not best or not best.Character then return end
    local tHRP=best.Character:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
    -- snap behind and hit
    local behind=tHRP.Position-tHRP.CFrame.LookVector*2.5
    hrp.CFrame=CFrame.new(Vector3.new(behind.X,tHRP.Position.Y,behind.Z),tHRP.Position)
    local bv=Instance.new("BodyVelocity")
    bv.Velocity=tHRP.CFrame.LookVector*-70+Vector3.new(0,40,0)
    bv.MaxForce=Vector3.one*1e7
    bv.Parent=tHRP
    task.delay(0.1,function() if bv and bv.Parent then bv:Destroy() end end)
end

-- ── AUTO KILL NPC (Chefs / Zombies) ─────────────────────────
local NPC_FOLDERS = {"Zombies","Enemies","Chefs"}
local function doAutoKillNPC()
    local hrp=getHRP(); if not hrp then return end
    for _, fname in ipairs(NPC_FOLDERS) do
        local folder=WS:FindFirstChild(fname); if not folder then continue end
        for _, enemy in ipairs(folder:GetChildren()) do
            local eHum=enemy:FindFirstChildOfClass("Humanoid")
            local eHRP=enemy:FindFirstChild("HumanoidRootPart")
            if eHum and eHRP and eHum.Health>0 and (hrp.Position-eHRP.Position).Magnitude<80 then
                hrp.CFrame=CFrame.new(eHRP.Position+Vector3.new(0,0,3),eHRP.Position)
                local bv=Instance.new("BodyVelocity")
                bv.Velocity=Vector3.new(0,120,0); bv.MaxForce=Vector3.one*9e9; bv.Parent=eHRP
                task.delay(0.15,function() if bv.Parent then bv:Destroy() end end)
            end
        end
    end
end

-- ── FLING ───────────────────────────────────────────────────
local function findNearest()
    local hrp=getHRP(); if not hrp then return nil end
    local best,bestD=nil,math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local c=plr.Character; if not c then continue end
        local tHRP=c:FindFirstChild("HumanoidRootPart"); if not tHRP then continue end
        local d=(hrp.Position-tHRP.Position).Magnitude
        if d<bestD then best=plr; bestD=d end
    end
    return best
end

local function doFling(plr)
    if not plr or not plr.Character then return end
    local hrp=getHRP()
    local tHRP=plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    hrp.CFrame=CFrame.new(tHRP.Position+Vector3.new(0,0,2),tHRP.Position)
    local bv=Instance.new("BodyVelocity")
    bv.Velocity=(tHRP.Position-hrp.Position).Unit*600+Vector3.new(0,250,0)
    bv.MaxForce=Vector3.one*1e9; bv.Parent=tHRP
    task.delay(0.2,function() if bv.Parent then bv:Destroy() end end)
end

-- ── AUTO GRAB ITEMS ─────────────────────────────────────────
local function doAutoGrab()
    local hrp=getHRP(); if not hrp then return end
    for _, child in ipairs(WS:GetChildren()) do
        if KNOWN_FOLDERS[child.Name] then continue end
        local items = child:IsA("Folder") and child:GetChildren() or {child}
        for _, item in ipairs(items) do
            local p=item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
            if not p then continue end
            if (hrp.Position-p.Position).Magnitude>S.grabRadius then continue end
            local pp=item:FindFirstChildOfClass("ProximityPrompt",true)
            if pp then pcall(fireproximityprompt,pp); continue end
            local cd=item:FindFirstChildOfClass("ClickDetector",true)
            if cd then pcall(fireclickdetector,cd); continue end
            hrp.CFrame=CFrame.new(p.Position+Vector3.new(0,3,0))
        end
    end
end

-- ── AUTO FARM PLAYER ────────────────────────────────────────
local farmIdx=1
local function doAutoFarm()
    local targets={}
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then targets[#targets+1]=p end
    end
    if #targets==0 then return end
    farmIdx=(farmIdx%#targets)+1
    local t=targets[farmIdx]; local hrp=getHRP()
    local tHRP=t.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    local behind=tHRP.Position-tHRP.CFrame.LookVector*3
    hrp.CFrame=CFrame.new(Vector3.new(behind.X,tHRP.Position.Y,behind.Z),tHRP.Position)
end

-- ── AUTO ALPHA / BETA / DELTA ───────────────────────────────
-- ReplicatedStorage.["Project Alpha/Beta/Delta"] — models spawn inside during round
-- We interact with every model that appears: fire ProximityPrompts / ClickDetectors,
-- or TP to them so any touch-trigger fires.
local function interactWithFolder(folderName)
    -- check ReplicatedStorage first, then workspace
    local folder = RS:FindFirstChild(folderName) or WS:FindFirstChild(folderName)
    if not folder then return end
    local hrp = getHRP(); if not hrp then return end
    for _, obj in ipairs(folder:GetChildren()) do
        -- try ProximityPrompt
        local pp = obj:FindFirstChildOfClass("ProximityPrompt",true)
        if pp then pcall(fireproximityprompt,pp) end
        -- try ClickDetector
        local cd = obj:FindFirstChildOfClass("ClickDetector",true)
        if cd then pcall(fireclickdetector,cd) end
        -- TP to model root to trigger any touch events
        local root = obj:IsA("BasePart") and obj
                  or obj:FindFirstChildOfClass("BasePart")
                  or obj:FindFirstChildOfClass("MeshPart")
        if root then
            hrp.CFrame = CFrame.new(root.Position + Vector3.new(0,3,0))
        end
    end
end

-- ── AUTO CARRY ──────────────────────────────────────────────
local function doAutoCarry()
    local target=findNearest(); if not target or not target.Character then S.carryTarget=nil; return end
    S.carryTarget=target
    local hrp=getHRP(); local tHRP=target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    tHRP.CFrame=hrp.CFrame*CFrame.new(0,4,0)
    local pp=target.Character:FindFirstChildOfClass("ProximityPrompt",true)
    if pp then pcall(fireproximityprompt,pp) end
end

local function doCarryKill()
    if not S.carryTarget or not S.carryTarget.Character then S.carryTarget=findNearest() end
    if not S.carryTarget or not S.carryTarget.Character then return end
    local hrp=getHRP(); if not hrp then return end
    S.savedCF=hrp.CFrame
    local tHRP=S.carryTarget.Character:FindFirstChild("HumanoidRootPart")
    hrp.CFrame=CFrame.new(VOID_POS)
    if tHRP then tHRP.CFrame=CFrame.new(VOID_POS) end
    task.wait(1.2)
    if S.savedCF then hrp.CFrame=S.savedCF end
    S.carryTarget=nil
end

-- ═══════════════════════════════════════════════════════════
-- ██ MAIN LOOPS
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    pcall(function()
        if S.speedHack  then local h=getHum(); if h then h.WalkSpeed=S.speed end end
        if S.godMode    then doGodMode()     end
        if S.noDark     then applyNoDark()   end
        if S.antiPush   then doAntiPush()    end
        if S.stayCircle then doStayInCircle() end
        if S.autoRevive then doAutoRevive()  end
    end)
end)

-- ESP 0.3s tick
local espT=0
RunService.Heartbeat:Connect(function(dt)
    espT+=dt; if espT<0.3 then return end; espT=0
    pcall(function()
        if S.playerESP then updatePlayerESP() end
        if S.itemESP   then updateItemESP()   end
        if S.mineESP   then updateMineESP()   end
        if S.ghostESP  then updateGhostESP()  end
    end)
end)

-- fast paid loop 0.12s
task.spawn(function()
    while true do task.wait(0.12)
        pcall(function()
            if S.killAura  then doKillAura()   end
            if S.autoAttack then doAutoAttack() end
            if S.autoCarry  then doAutoCarry()  end
            if S.autoGrab   then doAutoGrab()   end
        end)
    end
end)

-- slower paid loop 0.5s
task.spawn(function()
    while true do task.wait(0.5)
        pcall(function()
            if S.autoFarm       then doAutoFarm()        end
            if S.autoKillNPC    then doAutoKillNPC()     end
            if S.alwaysButton   then tryGetButton()       end
            if S.autoAlpha      then interactWithFolder("Project Alpha") end
            if S.autoBeta       then interactWithFolder("Project Beta")  end
            if S.autoDelta      then interactWithFolder("Project Delta") end
        end)
    end
end)

-- fling loop
task.spawn(function()
    while true do task.wait(0.28)
        if S.fling then pcall(function() doFling(findNearest()) end) end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if S.invis  then applyInvis(true) end
    if S.noStun then connectNoStun()  end
end)
connectNoStun()

-- ═══════════════════════════════════════════════════════════
-- ██ UI TABS
-- ═══════════════════════════════════════════════════════════

-- TAB: VISUALS
local tVis = Window:CreateTab("Visuals", 4483362458)

tVis:CreateToggle({ Name="Player ESP", CurrentValue=false, Callback=function(v)
    S.playerESP=v
    if not v then for _,p in ipairs(Players:GetPlayers()) do if p.Character then removeESP(p.Character) end end end
end})
tVis:CreateToggle({ Name="Item ESP", CurrentValue=false, Callback=function(v)
    S.itemESP=v; if not v then clearAllESP() end
end})
tVis:CreateToggle({ Name="Mine ESP  (workspace.Minefield.Landmine)", CurrentValue=false, Callback=function(v)
    S.mineESP=v
    if not v then
        local mf=WS:FindFirstChild("Minefield")
        if mf then for _,obj in ipairs(mf:GetChildren()) do removeESP(obj) end end
    end
end})
tVis:CreateToggle({ Name="Ghost ESP  (workspace.Ghosts)", CurrentValue=false, Callback=function(v)
    S.ghostESP=v
    if not v then
        local gh=WS:FindFirstChild("Ghosts")
        if gh then for _,obj in ipairs(gh:GetChildren()) do removeESP(obj) end end
    end
end})
tVis:CreateToggle({ Name="No Dark  (Always Bright)", CurrentValue=false, Callback=function(v)
    S.noDark=v
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
tCom:CreateDivider()
tCom:CreateToggle({ Name="Kill Aura", CurrentValue=false, Callback=function(v) S.killAura=v end})
tCom:CreateSlider({ Name="Kill Aura Radius", Range={5,60}, Increment=1, CurrentValue=20,
    Callback=function(v) S.killRadius=v end})
tCom:CreateToggle({ Name="Auto Attack  (nearest player)", CurrentValue=false, Callback=function(v) S.autoAttack=v end})
tCom:CreateToggle({ Name="Fling  (nearest player)", CurrentValue=false, Callback=function(v) S.fling=v end})
tCom:CreateToggle({ Name="Auto Kill Chefs / Zombies", CurrentValue=false, Callback=function(v) S.autoKillNPC=v end})

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
tAut:CreateToggle({ Name="Always Get Button", CurrentValue=false, Callback=function(v) S.alwaysButton=v end})
tAut:CreateDivider()
tAut:CreateToggle({ Name="Auto Grab Items / Aura", CurrentValue=false, Callback=function(v) S.autoGrab=v end})
tAut:CreateSlider({ Name="Grab Radius", Range={5,80}, Increment=1, CurrentValue=35,
    Callback=function(v) S.grabRadius=v end})
tAut:CreateToggle({ Name="Auto Farm Player", CurrentValue=false, Callback=function(v) S.autoFarm=v end})

-- TAB: PROJECTS
local tProj = Window:CreateTab("Projects", 4483362458)

tProj:CreateLabel("Auto-interact with spawned models in each Project folder")
tProj:CreateLabel("(ReplicatedStorage / Workspace — scans both)")
tProj:CreateDivider()
tProj:CreateToggle({ Name="Auto Alpha  (Project Alpha)", CurrentValue=false, Callback=function(v) S.autoAlpha=v end})
tProj:CreateToggle({ Name="Auto Beta   (Project Beta)",  CurrentValue=false, Callback=function(v) S.autoBeta=v  end})
tProj:CreateToggle({ Name="Auto Delta  (Project Delta)", CurrentValue=false, Callback=function(v) S.autoDelta=v end})
tProj:CreateDivider()
tProj:CreateButton({ Name="Manual — Interact Alpha Now", Callback=function() pcall(interactWithFolder,"Project Alpha") end})
tProj:CreateButton({ Name="Manual — Interact Beta Now",  Callback=function() pcall(interactWithFolder,"Project Beta")  end})
tProj:CreateButton({ Name="Manual — Interact Delta Now", Callback=function() pcall(interactWithFolder,"Project Delta") end})

-- TAB: CARRY
local tCar = Window:CreateTab("Carry", 4483362458)

tCar:CreateToggle({ Name="Auto Carry  (nearest player)", CurrentValue=false, Callback=function(v) S.autoCarry=v end})
tCar:CreateButton({ Name="Carry Kill  (TP void + return)", Callback=function()
    task.spawn(function() pcall(doCarryKill) end)
end})
tCar:CreateDivider()
tCar:CreateButton({ Name="Save Position", Callback=function()
    local hrp=getHRP(); if hrp then S.savedCF=hrp.CFrame; Rayfield:Notify({Title="Saved",Content="Position saved!",Duration=2}) end
end})
tCar:CreateButton({ Name="Return to Saved Position", Callback=function()
    local hrp=getHRP(); if hrp and S.savedCF then hrp.CFrame=S.savedCF end
end})

-- TAB: SETTINGS
local tSet = Window:CreateTab("Settings", 4483362458)
tSet:CreateLabel("Wallace Chaos Hub  —  PAID Edition")
tSet:CreateLabel("Press F6 to panic / destroy UI")
tSet:CreateDivider()
tSet:CreateLabel("Mine path: workspace.Minefield.Landmine")
tSet:CreateLabel("Button:    workspace.Map.MapModels.TheButton")
tSet:CreateLabel("Stun:      workspace.[name].StunHandler.StunEvent")
tSet:CreateLabel("Projects:  RS / WS  Project Alpha / Beta / Delta")

-- PANIC F6
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.F6 then
        for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
        clearAllESP()
        local h=getHum(); if h then h.WalkSpeed=16 end
        pcall(function() Rayfield:Destroy() end)
    end
end)

Rayfield:Notify({ Title="Wallace Chaos Hub", Content="PAID Edition — all features active!", Duration=5 })
