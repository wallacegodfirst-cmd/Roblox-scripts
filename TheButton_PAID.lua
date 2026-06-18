-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  PAID Edition
-- Black / Blue / Red theme  |  F6 = Panic
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local WS         = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name="Wallace Chaos Hub  |  PAID", LoadingTitle="Wallace Chaos Hub",
    LoadingSubtitle="Black Edition — All Features",
    Theme={
        TextColor=Color3.fromRGB(235,235,235),Background=Color3.fromRGB(10,10,14),
        Topbar=Color3.fromRGB(18,22,38),Shadow=Color3.fromRGB(0,0,0),
        NotificationBackground=Color3.fromRGB(15,15,20),NotificationActionsBackground=Color3.fromRGB(30,40,70),
        TabBackground=Color3.fromRGB(20,25,45),TabStroke=Color3.fromRGB(200,30,50),
        TabBackgroundSelected=Color3.fromRGB(180,25,45),TabTextColor=Color3.fromRGB(210,210,230),
        SelectedTabTextColor=Color3.fromRGB(255,255,255),ElementBackground=Color3.fromRGB(16,20,36),
        ElementBackgroundHover=Color3.fromRGB(30,40,75),SecondaryElementBackground=Color3.fromRGB(14,18,32),
        ElementStroke=Color3.fromRGB(40,60,110),SecondaryElementStroke=Color3.fromRGB(120,20,35),
        SliderBackground=Color3.fromRGB(180,25,45),SliderProgress=Color3.fromRGB(30,100,220),
        SliderStroke=Color3.fromRGB(80,130,220),ToggleBackground=Color3.fromRGB(20,30,60),
        ToggleEnabled=Color3.fromRGB(220,30,50),ToggleDisabled=Color3.fromRGB(40,45,60),
        ToggleEnabledStroke=Color3.fromRGB(255,80,100),ToggleDisabledStroke=Color3.fromRGB(60,80,130),
        ToggleEnabledOuterStroke=Color3.fromRGB(30,100,220),ToggleDisabledOuterStroke=Color3.fromRGB(40,60,100),
        DropdownSelected=Color3.fromRGB(180,25,45),DropdownUnselected=Color3.fromRGB(20,25,45),
        InputBackground=Color3.fromRGB(15,18,30),InputStroke=Color3.fromRGB(180,30,50),
        PlaceholderColor=Color3.fromRGB(150,150,170),
    },
    DisableRayfieldPrompts=true,DisableBuildWarnings=true,
})

-- ── HELPERS ─────────────────────────────────────────────────
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local fireprompt = (typeof(fireproximityprompt)=="function") and fireproximityprompt or function() end
local fireclick  = (typeof(fireclickdetector)=="function")  and fireclickdetector  or function() end

local MAP        = WS:WaitForChild("Map", 10)
local MAP_MODELS = MAP and MAP:FindFirstChild("MapModels")
local CHEF_NAMES = {"ChefOne","ChefTwo","ChefThree","ChefFour"}
local VOID_POS   = Vector3.new(0,-5000,0)
local PROJECTS   = {"Project Alpha","Project Beta","Project Delta"}

local SYS={
    Map=true,Chefs=true,Ghosts=true,Minefield=true,Camera=true,Terrain=true,
    Characters=true,DownedCharacters=true,PvpZones=true,Hover=true,
    ["Project Alpha"]=true,["Project Beta"]=true,["Project Delta"]=true,
}

-- ── ESP ─────────────────────────────────────────────────────
local espStore={}
local function addESP(obj,color,tag)
    if not obj or not obj.Parent then return end
    local ex=espStore[obj]
    if ex then if ex[2] and tag then local l=ex[2]:FindFirstChildOfClass("TextLabel"); if l then l.Text=tag end end; return end
    local h=Instance.new("Highlight")
    h.FillColor=color; h.OutlineColor=Color3.fromRGB(255,255,255); h.FillTransparency=0.5; h.Parent=obj
    local bb
    if tag then
        bb=Instance.new("BillboardGui"); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,160,0,26)
        bb.StudsOffset=Vector3.new(0,3.5,0); bb.Parent=obj
        local l=Instance.new("TextLabel",bb); l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=1
        l.TextColor3=color; l.TextStrokeTransparency=0; l.Font=Enum.Font.GothamBold; l.TextScaled=true; l.Text=tag
    end
    espStore[obj]={h,bb}
end
local function removeESP(obj)
    local t=espStore[obj]; if not t then return end
    for _,v in ipairs(t) do if v and v.Parent then v:Destroy() end end; espStore[obj]=nil
end
local function clearAllESP() for o in pairs(espStore) do removeESP(o) end end

-- ── STATE ───────────────────────────────────────────────────
local S={
    playerESP=false,itemESP=false,mineESP=false,ghostESP=false,
    noStun=false,speedHack=false,speed=28,invis=false,godMode=false,
    noDark=false,antiPush=false,infStam=false,
    hitbox=false,hitboxSize=12,hitboxVisible=false,
    autoOpenDoor=false,bypassLock=false,stayCircle=false,autoRevive=false,
    killAura=false,killRadius=20,autoAttack=false,fling=false,autoKillNPC=false,
    alwaysButton=false,autoGrab=false,grabRadius=50,autoFarm=false,
    autoAlpha=false,autoBeta=false,autoDelta=false,
    autoCarry=false,savedCF=nil,
}

-- ── ITEM DETECTION ──────────────────────────────────────────
-- Tool class (Bandage, Sledge etc.) does NOT inherit Model — must check explicitly
local function isItem(obj)
    if SYS[obj.Name] then return false end
    if obj:IsA("Tool") then return true end
    if obj:IsA("Model") then
        if obj:FindFirstChildOfClass("Humanoid") then return false end
        if Players:GetPlayerFromCharacter(obj) then return false end
        return true
    end
    if obj:IsA("BasePart") then
        return obj:FindFirstChildOfClass("ProximityPrompt")~=nil
            or obj:FindFirstChildOfClass("ClickDetector")~=nil
    end
    return false
end
local function itemRoot(obj)
    if obj:IsA("Tool") then return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart") end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChildWhichIsA("BasePart")
end

-- ── ESP UPDATES ─────────────────────────────────────────────
local function updatePlayerESP()
    local myHRP=getHRP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end; local c=plr.Character; if not c then continue end
        if S.playerESP then
            local t=c:FindFirstChild("HumanoidRootPart")
            local d=(myHRP and t) and math.round((myHRP.Position-t.Position).Magnitude) or 0
            addESP(c,Color3.fromRGB(255,220,50),plr.Name.."  ["..d.."m]")
        else removeESP(c) end
    end
end
local function updateItemESP()
    for _,child in ipairs(WS:GetChildren()) do
        if isItem(child) then
            local root=itemRoot(child); local target=(child:IsA("Tool") and root) or child
            if target then
                if S.itemESP then addESP(target,Color3.fromRGB(0,255,150),child.Name)
                else removeESP(target) end
            end
        end
    end
end
local function updateMineESP()
    local mf=WS:FindFirstChild("Minefield"); if not mf then return end
    for _,o in ipairs(mf:GetChildren()) do
        if o.Name:lower():find("mine") then
            if S.mineESP then addESP(o,Color3.fromRGB(255,40,40),"MINE")
            else removeESP(o) end
        end
    end
end
local function updateGhostESP()
    local gf=WS:FindFirstChild("Ghosts"); if not gf then return end
    for _,g in ipairs(gf:GetChildren()) do
        if S.ghostESP then
            addESP(g,Color3.fromRGB(0,220,255),"GHOST: "..g.Name)
            for _,d in ipairs(g:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("MeshPart") then d.LocalTransparencyModifier=0.35 end
            end
        else removeESP(g) end
    end
end

-- ── NO STUN ─────────────────────────────────────────────────
local stunConn=nil
local function connectNoStun()
    if stunConn then stunConn:Disconnect(); stunConn=nil end
    local char=getChar(); if not char then return end
    local function hook(h)
        local ev=h:FindFirstChild("StunEvent")
        if ev then stunConn=ev.Event:Connect(function()
            if not S.noStun then return end
            local hum=getHum(); if hum then hum.WalkSpeed=S.speedHack and S.speed or 16 end
        end) end
    end
    local h=char:FindFirstChild("StunHandler"); if h then hook(h) end
    char.ChildAdded:Connect(function(c) if c.Name=="StunHandler" and S.noStun then hook(c) end end)
end

-- ── INF STAMINA ─────────────────────────────────────────────
-- Stamina is a Frame (not a NumberValue).
-- Fix: disable StaminaScript + pin Frame size to full every frame.
local function getStamBar()
    local pg=LP:FindFirstChild("PlayerGui"); if not pg then return nil,nil end
    local bar=pg:FindFirstChild("StaminaBar",true); if not bar then return nil,nil end
    local scr=bar:FindFirstChild("StaminaScript")
    local frame=bar:FindFirstChild("Stamina")  -- Frame, NOT NumberValue
    return scr, frame
end
local function applyInfStam(on)
    local scr,frame=getStamBar()
    if scr  then pcall(function() scr.Disabled=on end) end  -- disable script = stop depletion
    if frame and frame:IsA("Frame") and on then
        pcall(function() frame.Size=UDim2.new(1,0,frame.Size.Y.Scale,0) end)
    end
end
local function doInfStam()  -- called every Heartbeat to keep bar full
    local scr,frame=getStamBar()
    if scr  then pcall(function() scr.Disabled=true end) end
    if frame and frame:IsA("Frame") then
        pcall(function() frame.Size=UDim2.new(1,0,frame.Size.Y.Scale,0) end)
    end
end

-- ── GOD MODE ────────────────────────────────────────────────
-- Uses ghost Humanoid health as reference — workspace.Ghosts.[name]
-- has a server Health Script keeping ghost unkillable. We copy its
-- MaxHealth and layer a reactive GetPropertyChangedSignal hook on top.
local godConns={}
local function getGhostMaxHealth()
    local gf=WS:FindFirstChild("Ghosts"); if not gf then return 1e6 end
    for _,g in ipairs(gf:GetChildren()) do
        local gh=g:FindFirstChildOfClass("Humanoid")
        if gh and gh.MaxHealth>0 then return gh.MaxHealth end
    end
    return 1e6
end
local function setupGodMode()
    for _,c in ipairs(godConns) do c:Disconnect() end; godConns={}
    if not S.godMode then return end
    local hum=getHum(); if not hum then return end
    local mx=getGhostMaxHealth()  -- match ghost's unkillable health value
    pcall(function() hum.MaxHealth=mx; hum.Health=mx end)
    pcall(function() hum.RequiresNeck=false end)
    pcall(function() hum.BreakJointsOnDeath=false end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
    -- reactive hook: resets health the instant the server changes it
    local ok,conn=pcall(function()
        return hum:GetPropertyChangedSignal("Health"):Connect(function()
            if S.godMode and hum.Parent then
                pcall(function() hum.Health=hum.MaxHealth end)
            end
        end)
    end)
    if ok and conn then table.insert(godConns,conn) end
end

-- ── INVIS ───────────────────────────────────────────────────
local function applyInvis(on)
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if (p:IsA("BasePart") or p:IsA("MeshPart")) and p.Name~="HumanoidRootPart" then
            p.LocalTransparencyModifier=on and 1 or 0
        end
    end
end

-- ── NO DARK ─────────────────────────────────────────────────
local function applyNoDark()
    Lighting.ClockTime=14; Lighting.Brightness=3
    Lighting.Ambient=Color3.fromRGB(200,200,200); Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200); Lighting.FogEnd=100000
    for _,o in ipairs(Lighting:GetChildren()) do
        if o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect") or o:IsA("BlurEffect") then o.Enabled=false end
    end
end

-- ── HITBOX EXPANDER ─────────────────────────────────────────
local hbOrig={}
local function doHitbox()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end; local c=plr.Character; if not c then continue end
        local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        if not hbOrig[hrp] then hbOrig[hrp]=hrp.Size end
        pcall(function()
            hrp.Size=Vector3.new(S.hitboxSize,S.hitboxSize,S.hitboxSize); hrp.CanCollide=false
            hrp.Transparency=S.hitboxVisible and 0.6 or 1
            if S.hitboxVisible then hrp.Material=Enum.Material.ForceField; hrp.Color=Color3.fromRGB(255,40,60) end
        end)
    end
end
local function resetHitbox()
    for hrp,sz in pairs(hbOrig) do pcall(function() if hrp and hrp.Parent then hrp.Size=sz; hrp.Transparency=1 end end) end; hbOrig={}
end

-- ── TELEPORTS ───────────────────────────────────────────────
local function tpToPlayer(name)
    local plr=Players:FindFirstChild(name); if not plr or not plr.Character then return end
    local hrp=getHRP(); local t=plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp and t then hrp.CFrame=t.CFrame*CFrame.new(0,0,3.5) end
end
local function tpToChef(name)
    local f=WS:FindFirstChild("Chefs"); if not f then return end
    local chef=f:FindFirstChild(name); if not chef then return end
    local hrp=getHRP(); local r=chef:FindFirstChildWhichIsA("BasePart")
    if hrp and r then hrp.CFrame=r.CFrame*CFrame.new(0,0,5) end
end

-- ── DOORS ───────────────────────────────────────────────────
local function doAutoOpenDoors()
    local myHRP=getHRP(); if not myHRP then return end
    local doorsF=MAP and MAP:FindFirstChild("Doors")
    if doorsF then
        for _,dm in ipairs(doorsF:GetChildren()) do
            local main=dm:FindFirstChild("Door") and dm.Door:FindFirstChild("Main")
            if main then local pp=main:FindFirstChild("DoorPrompt")
                if pp and (myHRP.Position-main.Position).Magnitude<25 then pcall(fireprompt,pp) end end
        end
    end
    if MAP_MODELS then
        for _,o in ipairs(MAP_MODELS:GetChildren()) do
            if o.Name=="Door" then
                local pp=o:FindFirstChildOfClass("ProximityPrompt",true)
                if pp and pp.Parent:IsA("BasePart") and (myHRP.Position-pp.Parent.Position).Magnitude<25 then pcall(fireprompt,pp) end
            end
        end
    end
end
local function doBypassLock()
    local doorsF=MAP and MAP:FindFirstChild("Doors"); if not doorsF then return end
    for _,dm in ipairs(doorsF:GetChildren()) do
        for _,d in ipairs(dm:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function() d.Enabled=true; d.MaxActivationDistance=100; d.HoldDuration=0 end)
                pcall(fireprompt,d)
            elseif d:IsA("BasePart") and d.Name:lower():find("barrier") then
                pcall(function() d.CanCollide=false end)
            end
        end
    end
end

-- ── STAY IN CIRCLE / ANTI PUSH ──────────────────────────────
local function getCircle()
    if MAP_MODELS then
        local bz=MAP_MODELS:FindFirstChild("ButtonZone")
        if bz and bz:IsA("BasePart") then return bz end
        for _,o in ipairs(MAP_MODELS:GetDescendants()) do
            if o:IsA("BasePart") then local n=o.Name:lower()
                if n:find("zone") or n:find("circle") or n:find("king") then return o end end
        end
    end
end
local function doStayInCircle()
    local hrp=getHRP(); local c=getCircle(); if not hrp or not c then return end
    local center=c.Position; local radius=math.min(c.Size.X,c.Size.Z)/2-0.8
    local p=hrp.Position; local flat=Vector3.new(p.X,center.Y,p.Z)
    if (flat-center).Magnitude>radius then
        local dir=(flat-center).Unit; local safe=center+dir*(radius-0.3)
        hrp.CFrame=CFrame.new(Vector3.new(safe.X,p.Y,safe.Z),Vector3.new(center.X,p.Y,center.Z))
    end
end
local function doAntiPush()
    local hrp=getHRP(); if not hrp then return end
    for _,v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") or v:IsA("BodyForce") then
            pcall(function() v.Velocity=Vector3.zero end); pcall(function() v.Force=Vector3.zero end)
        end
    end
end

-- ── AUTO REVIVE ─────────────────────────────────────────────
local function doAutoRevive()
    local downed=WS:FindFirstChild("DownedCharacters")
    if downed then
        for _,d in ipairs(downed:GetChildren()) do
            for _,pp in ipairs(d:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then
                    pcall(function() pp.Enabled=true; pp.MaxActivationDistance=100; pp.HoldDuration=0 end)
                    pcall(fireprompt,pp)
                end
            end
        end
    end
    local hum=getHum(); if hum and hum.Health<=0 then pcall(function() LP:LoadCharacter() end) end
end

-- ═══════════════════════════════════════════════════════════
-- ██ ALWAYS GET BUTTON
-- TP to button first + force prompt properties + fire
-- ═══════════════════════════════════════════════════════════
local function tryGetButton()
    if not MAP_MODELS then return end
    local tb=MAP_MODELS:FindFirstChild("TheButton"); if not tb then return end
    local btn=tb:FindFirstChild("Button"); if not btn then return end
    -- TP to button so we're definitely in range
    local hrp=getHRP()
    local btnPart=btn:IsA("BasePart") and btn or btn:FindFirstChildWhichIsA("BasePart")
    if hrp and btnPart then
        pcall(function() hrp.CFrame=CFrame.new(btnPart.Position+Vector3.new(0,3,0)) end)
    end
    -- Force-enable prompt with no hold/distance requirement
    local pp=btn:FindFirstChild("ButtonPrompt") or btn:FindFirstChildOfClass("ProximityPrompt",true)
    if pp then
        pcall(function()
            pp.Enabled=true
            pp.MaxActivationDistance=100
            pp.HoldDuration=0
            pp.RequiresLineOfSight=false
        end)
        pcall(fireprompt,pp)
    end
    local cd=btn:FindFirstChildOfClass("ClickDetector")
    if cd then pcall(function() cd.MaxActivationDistance=100 end); pcall(fireclick,cd) end
end

-- ═══════════════════════════════════════════════════════════
-- ██ COMBAT
-- ═══════════════════════════════════════════════════════════
local function doKillAura()
    local hrp=getHRP(); if not hrp then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end; local c=plr.Character; if not c then continue end
        local t=c:FindFirstChild("HumanoidRootPart"); if not t then continue end
        if (hrp.Position-t.Position).Magnitude<=S.killRadius then
            local behind=t.Position-t.CFrame.LookVector*3
            hrp.CFrame=CFrame.new(Vector3.new(behind.X,t.Position.Y,behind.Z),t.Position)
            local bv=Instance.new("BodyVelocity")
            bv.Velocity=t.CFrame.LookVector*-90+Vector3.new(0,55,0); bv.MaxForce=Vector3.one*1e7; bv.Parent=t
            task.delay(0.12,function() if bv.Parent then bv:Destroy() end end)
        end
    end
end
local function findNearest()
    local hrp=getHRP(); if not hrp then return nil end
    local best,bd=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end; local c=plr.Character; if not c then continue end
        local t=c:FindFirstChild("HumanoidRootPart"); if not t then continue end
        local d=(hrp.Position-t.Position).Magnitude; if d<bd then best=plr; bd=d end
    end
    return best
end
local function doAutoAttack()
    local best=findNearest(); if not best or not best.Character then return end
    local hrp=getHRP(); local t=best.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not t then return end
    local behind=t.Position-t.CFrame.LookVector*2.5
    hrp.CFrame=CFrame.new(Vector3.new(behind.X,t.Position.Y,behind.Z),t.Position)
    local bv=Instance.new("BodyVelocity")
    bv.Velocity=t.CFrame.LookVector*-70+Vector3.new(0,40,0); bv.MaxForce=Vector3.one*1e7; bv.Parent=t
    task.delay(0.1,function() if bv.Parent then bv:Destroy() end end)
end
local function doFling(plr)
    if not plr or not plr.Character then return end
    local hrp=getHRP(); local t=plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not t then return end
    hrp.CFrame=CFrame.new(t.Position+Vector3.new(0,0,2),t.Position)
    local bv=Instance.new("BodyVelocity")
    bv.Velocity=(t.Position-hrp.Position).Unit*600+Vector3.new(0,250,0); bv.MaxForce=Vector3.one*1e9; bv.Parent=t
    task.delay(0.2,function() if bv.Parent then bv:Destroy() end end)
end
local function doAutoKillNPC()
    local hrp=getHRP(); if not hrp then return end
    for _,fn in ipairs({"Zombies","Enemies","Chefs"}) do
        local f=WS:FindFirstChild(fn); if not f then continue end
        for _,e in ipairs(f:GetChildren()) do
            local eh=e:FindFirstChildOfClass("Humanoid"); local er=e:FindFirstChild("HumanoidRootPart")
            if eh and er and eh.Health>0 and (hrp.Position-er.Position).Magnitude<80 then
                pcall(function() eh.Health=0 end)
                pcall(function() eh:TakeDamage(math.huge) end)
                pcall(function() er.CFrame=CFrame.new(VOID_POS) end)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO GRAB ITEMS (Tools by touch, other items by prompt)
-- ═══════════════════════════════════════════════════════════
local function doAutoGrab()
    local hrp=getHRP(); if not hrp then return end
    for _,child in ipairs(WS:GetChildren()) do
        if not isItem(child) then continue end
        local root=itemRoot(child); if not root then continue end
        if (hrp.Position-root.Position).Magnitude>S.grabRadius then continue end
        -- Tools: TP to Handle so the touch-pickup fires
        if child:IsA("Tool") then
            pcall(function() hrp.CFrame=CFrame.new(root.Position+Vector3.new(0,2,0)) end)
            pcall(function() child.Parent=LP.Backpack end)  -- force into backpack
        else
            local pp=child:FindFirstChildOfClass("ProximityPrompt",true)
            if pp then
                pcall(function() pp.Enabled=true; pp.MaxActivationDistance=200; pp.HoldDuration=0 end)
                pcall(fireprompt,pp)
            else
                local cd=child:FindFirstChildOfClass("ClickDetector",true)
                if cd then pcall(function() cd.MaxActivationDistance=200 end); pcall(fireclick,cd)
                else pcall(function() hrp.CFrame=CFrame.new(root.Position+Vector3.new(0,2,0)) end) end
            end
        end
    end
end

-- ── AUTO FARM ───────────────────────────────────────────────
local farmIdx=1
local function doAutoFarm()
    local targets={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then targets[#targets+1]=p end end
    if #targets==0 then return end
    farmIdx=(farmIdx%#targets)+1
    local t=targets[farmIdx]; local hrp=getHRP(); local tHRP=t.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    local behind=tHRP.Position-tHRP.CFrame.LookVector*3
    hrp.CFrame=CFrame.new(Vector3.new(behind.X,tHRP.Position.Y,behind.Z),tHRP.Position)
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO PROJECT — kill all NPCs + fire Evacuate
-- workspace.Project Alpha/Beta/Delta
-- NPCs: Gunner, Medic, Riot, Striker, Warden etc.
-- Evacuate = BindableEvent/RemoteEvent that signals completion
-- ═══════════════════════════════════════════════════════════
local function killProjectNPC(e)
    local eh=e:FindFirstChildOfClass("Humanoid")
    local er=e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
    if eh then
        pcall(function() eh.Health=0 end)
        pcall(function() eh:TakeDamage(1e9) end)
    end
    if er then
        pcall(function() er.CFrame=CFrame.new(VOID_POS) end)
        local bv=Instance.new("BodyVelocity")
        bv.Velocity=Vector3.new(0,500,0); bv.MaxForce=Vector3.one*1e9; bv.Parent=er
        task.delay(0.1,function() if bv.Parent then bv:Destroy() end end)
    end
    pcall(function() e:BreakJoints() end)
end

local function doProject(folderName)
    local folder=WS:FindFirstChild(folderName) or RS:FindFirstChild(folderName)
    if not folder then return end
    -- Fire Evacuate if present — this may directly complete the project server-side
    local ev=folder:FindFirstChild("Evacuate")
    if ev then
        pcall(function() ev:FireServer() end)   -- RemoteEvent path
        pcall(function() ev:Fire() end)          -- BindableEvent path
    end
    -- Kill every NPC model
    for _,e in ipairs(folder:GetChildren()) do
        if e:IsA("Model") then killProjectNPC(e) end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO CARRY  ([Q] CARRY prompt on downed/players)
-- ═══════════════════════════════════════════════════════════
local function findCarryPrompt(model)
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at=(d.ActionText or ""):lower(); local kk=d.KeyboardKeyCode
            if at:find("carry") or kk==Enum.KeyCode.Q then return d end
        end
    end
    return model:FindFirstChildOfClass("ProximityPrompt",true)
end
local function nearestCarryable()
    local hrp=getHRP(); if not hrp then return nil end
    local best,bd=nil,math.huge
    local downed=WS:FindFirstChild("DownedCharacters")
    if downed then
        for _,d in ipairs(downed:GetChildren()) do
            local r=d:FindFirstChildWhichIsA("BasePart")
            if r then local dist=(hrp.Position-r.Position).Magnitude; if dist<bd then best=d; bd=dist end end
        end
    end
    if not best then
        local plr=findNearest(); best=plr and plr.Character or nil
    end
    return best
end
local function doAutoCarry()
    local target=nearestCarryable(); if not target then return end
    local pp=findCarryPrompt(target)
    if pp then pcall(function() pp.Enabled=true; pp.MaxActivationDistance=100; pp.HoldDuration=0 end); pcall(fireprompt,pp) end
end
local function doCarryKill()
    local target=nearestCarryable()
    if target then
        local pp=findCarryPrompt(target)
        if pp then pcall(function() pp.Enabled=true; pp.MaxActivationDistance=100; pp.HoldDuration=0 end); pcall(fireprompt,pp) end
        task.wait(0.35)
    end
    local hrp=getHRP(); if not hrp then return end
    S.savedCF=hrp.CFrame
    pcall(function() hrp.CFrame=CFrame.new(VOID_POS) end)
    task.wait(1.2)
    if S.savedCF then pcall(function() hrp.CFrame=S.savedCF end) end
end

-- ═══════════════════════════════════════════════════════════
-- ██ LOOPS
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    pcall(function()
        if S.speedHack  then local h=getHum(); if h then h.WalkSpeed=S.speed end end
        if S.godMode    then local h=getHum(); if h then
            pcall(function() h.Health=h.MaxHealth end)
            pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end) end end
        if S.noDark     then applyNoDark()    end
        if S.antiPush   then doAntiPush()     end
        if S.stayCircle then doStayInCircle() end
        if S.infStam    then doInfStam()      end  -- pins Stamina Frame + keeps script disabled
        if S.hitbox     then doHitbox()       end
    end)
end)

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

-- always-get-button: tight loop (0.05s) — wins button race from anywhere
task.spawn(function()
    while true do task.wait(0.05)
        if S.alwaysButton then pcall(tryGetButton) end
    end
end)

-- fast loop: combat, grab, carry
task.spawn(function()
    while true do task.wait(0.12)
        pcall(function()
            if S.killAura   then doKillAura()   end
            if S.autoAttack then doAutoAttack() end
            if S.autoGrab   then doAutoGrab()   end
            if S.autoCarry  then doAutoCarry()  end
        end)
    end
end)

-- project kill loop (0.25s — catches NPCs as they spawn in)
task.spawn(function()
    while true do task.wait(0.25)
        pcall(function()
            if S.autoAlpha   then doProject("Project Alpha") end
            if S.autoBeta    then doProject("Project Beta")  end
            if S.autoDelta   then doProject("Project Delta") end
            if S.autoKillNPC then doAutoKillNPC()            end
        end)
    end
end)

-- slow loop: doors, revive, farm, fling
task.spawn(function()
    while true do task.wait(0.4)
        pcall(function()
            if S.autoOpenDoor then doAutoOpenDoors() end
            if S.bypassLock   then doBypassLock()   end
            if S.autoRevive   then doAutoRevive()   end
            if S.autoFarm     then doAutoFarm()     end
            if S.fling        then doFling(findNearest()) end
        end)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if S.invis   then applyInvis(true) end
    if S.noStun  then connectNoStun()  end
    if S.godMode then setupGodMode()   end
end)
connectNoStun()

-- ═══════════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════════
local tVis=Window:CreateTab("Visuals",4483362458)
tVis:CreateToggle({Name="Player ESP",CurrentValue=false,Callback=function(v)
    S.playerESP=v; if not v then for _,p in ipairs(Players:GetPlayers()) do if p.Character then removeESP(p.Character) end end end
end})
tVis:CreateToggle({Name="Item ESP  (Tools + workspace models)",CurrentValue=false,Callback=function(v)
    S.itemESP=v; if not v then clearAllESP() end
end})
tVis:CreateToggle({Name="Mine ESP",CurrentValue=false,Callback=function(v)
    S.mineESP=v; if not v then local mf=WS:FindFirstChild("Minefield"); if mf then for _,o in ipairs(mf:GetChildren()) do removeESP(o) end end end
end})
tVis:CreateToggle({Name="Ghost ESP",CurrentValue=false,Callback=function(v)
    S.ghostESP=v; if not v then local gf=WS:FindFirstChild("Ghosts"); if gf then for _,o in ipairs(gf:GetChildren()) do removeESP(o) end end end
end})
tVis:CreateToggle({Name="No Dark",CurrentValue=false,Callback=function(v)
    S.noDark=v
    if not v then Lighting.ClockTime=8; Lighting.Brightness=1
        Lighting.Ambient=Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127)
        for _,o in ipairs(Lighting:GetChildren()) do if o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect") then o.Enabled=true end end end
end})

local tCom=Window:CreateTab("Combat",4483362458)
tCom:CreateToggle({Name="God Mode",CurrentValue=false,Callback=function(v)
    S.godMode=v; if v then setupGodMode() else for _,c in ipairs(godConns) do c:Disconnect() end; godConns={} end
end})
tCom:CreateToggle({Name="No Stun",CurrentValue=false,Callback=function(v) S.noStun=v; if v then connectNoStun() end end})
tCom:CreateToggle({Name="Inf Stamina",CurrentValue=false,Callback=function(v) S.infStam=v; applyInfStam(v) end})
tCom:CreateToggle({Name="Anti Push",CurrentValue=false,Callback=function(v) S.antiPush=v end})
tCom:CreateDivider()
tCom:CreateToggle({Name="Hitbox Expander",CurrentValue=false,Callback=function(v) S.hitbox=v; if not v then resetHitbox() end end})
tCom:CreateSlider({Name="Hitbox Size",Range={3,40},Increment=1,CurrentValue=12,Callback=function(v) S.hitboxSize=v end})
tCom:CreateToggle({Name="Hitbox Visible",CurrentValue=false,Callback=function(v) S.hitboxVisible=v; if not v then resetHitbox() end end})
tCom:CreateDivider()
tCom:CreateToggle({Name="Kill Aura",CurrentValue=false,Callback=function(v) S.killAura=v end})
tCom:CreateSlider({Name="Kill Aura Radius",Range={5,60},Increment=1,CurrentValue=20,Callback=function(v) S.killRadius=v end})
tCom:CreateToggle({Name="Auto Attack (nearest)",CurrentValue=false,Callback=function(v) S.autoAttack=v end})
tCom:CreateToggle({Name="Fling (nearest)",CurrentValue=false,Callback=function(v) S.fling=v end})
tCom:CreateToggle({Name="Auto Kill Chefs / Zombies",CurrentValue=false,Callback=function(v) S.autoKillNPC=v end})

local tMov=Window:CreateTab("Movement",4483362458)
tMov:CreateToggle({Name="Speed Hack",CurrentValue=false,Callback=function(v) S.speedHack=v end})
tMov:CreateSlider({Name="Speed",Range={16,150},Increment=1,CurrentValue=28,Callback=function(v) S.speed=v end})
tMov:CreateToggle({Name="Invisibility (local)",CurrentValue=false,Callback=function(v) S.invis=v; applyInvis(v) end})
tMov:CreateDivider()
tMov:CreateDropdown({Name="Teleport to Player",
    Options=(function() local t={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then t[#t+1]=p.Name end end; return t end)(),
    CurrentOption={},MultipleOptions=false,Callback=function(o) if o and o[1] then tpToPlayer(o[1]) end end})
tMov:CreateDivider()
for _,c in ipairs(CHEF_NAMES) do tMov:CreateButton({Name="TP to "..c,Callback=function() tpToChef(c) end}) end

local tAut=Window:CreateTab("Auto",4483362458)
tAut:CreateToggle({Name="Always Get Button  (wins from anywhere)",CurrentValue=false,Callback=function(v) S.alwaysButton=v end})
tAut:CreateToggle({Name="Auto Open Doors",CurrentValue=false,Callback=function(v) S.autoOpenDoor=v end})
tAut:CreateToggle({Name="Bypass Lock",CurrentValue=false,Callback=function(v) S.bypassLock=v end})
tAut:CreateToggle({Name="Stay in King Circle",CurrentValue=false,Callback=function(v) S.stayCircle=v end})
tAut:CreateToggle({Name="Auto Revive Downed",CurrentValue=false,Callback=function(v) S.autoRevive=v end})
tAut:CreateDivider()
tAut:CreateToggle({Name="Auto Grab Items",CurrentValue=false,Callback=function(v) S.autoGrab=v end})
tAut:CreateSlider({Name="Grab Radius",Range={10,200},Increment=5,CurrentValue=50,Callback=function(v) S.grabRadius=v end})
tAut:CreateToggle({Name="Auto Farm Player",CurrentValue=false,Callback=function(v) S.autoFarm=v end})

local tProj=Window:CreateTab("Projects",4483362458)
tProj:CreateLabel("Kills all NPCs + fires Evacuate each tick")
tProj:CreateToggle({Name="Auto Alpha",CurrentValue=false,Callback=function(v) S.autoAlpha=v end})
tProj:CreateToggle({Name="Auto Beta", CurrentValue=false,Callback=function(v) S.autoBeta=v  end})
tProj:CreateToggle({Name="Auto Delta",CurrentValue=false,Callback=function(v) S.autoDelta=v end})
tProj:CreateDivider()
tProj:CreateButton({Name="Force All Projects Now",Callback=function()
    for _,pn in ipairs(PROJECTS) do pcall(doProject,pn) end
end})

local tCar=Window:CreateTab("Carry",4483362458)
tCar:CreateToggle({Name="Auto Carry (nearest/downed)",CurrentValue=false,Callback=function(v) S.autoCarry=v end})
tCar:CreateButton({Name="Carry Kill (void + return)",Callback=function() task.spawn(function() pcall(doCarryKill) end) end})
tCar:CreateDivider()
tCar:CreateButton({Name="Save Position",Callback=function() local h=getHRP(); if h then S.savedCF=h.CFrame; Rayfield:Notify({Title="Saved",Content="Position saved",Duration=2}) end end})
tCar:CreateButton({Name="Return to Saved",Callback=function() local h=getHRP(); if h and S.savedCF then h.CFrame=S.savedCF end end})

local tSet=Window:CreateTab("Settings",4483362458)
tSet:CreateLabel("Wallace Chaos Hub  —  PAID  |  F6 = Panic")

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.F6 then
        for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
        clearAllESP(); resetHitbox()
        for _,c in ipairs(godConns) do c:Disconnect() end; godConns={}
        local h=getHum(); if h then h.WalkSpeed=16 end
        pcall(function() Rayfield:Destroy() end)
    end
end)

Rayfield:Notify({Title="Wallace Chaos Hub",Content="PAID — all features active!",Duration=5})
