-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  FREE Edition
-- Default Rayfield theme  |  F6 = Panic
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local WS         = game:GetService("Workspace")
local LP         = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name="Wallace Chaos Hub  |  FREE", LoadingTitle="Wallace Chaos Hub",
    LoadingSubtitle="Free Edition", Theme="Default",
    DisableRayfieldPrompts=true, DisableBuildWarnings=true,
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

-- system folders — never treated as items
local SYS = {
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
        bb=Instance.new("BillboardGui"); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,150,0,26)
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
    playerESP=false, itemESP=false,
    noStun=false, speedHack=false, speed=28, invis=false, godMode=false,
    noDark=false, antiPush=false, infStam=false,
    hitbox=false, hitboxSize=12, hitboxVisible=false,
    autoOpenDoor=false, bypassLock=false, stayCircle=false, autoRevive=false,
}

-- ── ITEM DETECTION ──────────────────────────────────────────
-- Tool = Bandage, Sledge etc. — NOT a Model, must check separately
local function isItem(obj)
    if SYS[obj.Name] then return false end
    if obj:IsA("Tool") then return true end   -- <-- FIX: Tools are NOT Models
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

local function itemRoot(obj) -- get the BasePart to highlight/TP to
    if obj:IsA("Tool") then return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart") end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChildWhichIsA("BasePart")
end

-- ── ESP UPDATES ─────────────────────────────────────────────
local function updatePlayerESP()
    local myHRP=getHRP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local c=plr.Character; if not c then continue end
        if S.playerESP then
            local t=c:FindFirstChild("HumanoidRootPart")
            local d=(myHRP and t) and math.round((myHRP.Position-t.Position).Magnitude) or 0
            addESP(c, Color3.fromRGB(255,220,50), plr.Name.."  ["..d.."m]")
        else removeESP(c) end
    end
end

local function updateItemESP()
    for _,child in ipairs(WS:GetChildren()) do
        if isItem(child) then
            local root=itemRoot(child)
            local target=child:IsA("Tool") and (root or child) or child
            if S.itemESP then addESP(target, Color3.fromRGB(0,255,150), child.Name)
            else removeESP(target) end
        end
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
local function doInfStam()
    local pg=LP:FindFirstChild("PlayerGui"); if not pg then return end
    local bar=pg:FindFirstChild("StaminaBar",true); if not bar then return end
    -- "Stamina" child of StaminaBar (confirmed from Explorer)
    local sv=bar:FindFirstChild("Stamina")
    if sv and (sv:IsA("NumberValue") or sv:IsA("IntValue") or sv:IsA("Frame")) then
        if sv:IsA("NumberValue") or sv:IsA("IntValue") then sv.Value=sv.Value<50 and 100 or sv.Value end
    end
    -- also pin any NumberValue descendants
    for _,d in ipairs(bar:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and d.Value>=0 and d.Value<=100 then
            d.Value=100
        end
    end
end

-- ── GOD MODE (reactive + Heartbeat) ─────────────────────────
local godConns={}
local function setupGodMode()
    for _,c in ipairs(godConns) do c:Disconnect() end; godConns={}
    if not S.godMode then return end
    local hum=getHum(); if not hum then return end
    pcall(function() hum.MaxHealth=1e6; hum.Health=1e6 end)
    pcall(function() hum.RequiresNeck=false end)
    pcall(function() hum.BreakJointsOnDeath=false end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
    -- reactive hook: fires the instant Health changes on server
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
        if plr==LP then continue end
        local c=plr.Character; if not c then continue end
        local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        if not hbOrig[hrp] then hbOrig[hrp]=hrp.Size end
        pcall(function()
            hrp.Size=Vector3.new(S.hitboxSize,S.hitboxSize,S.hitboxSize)
            hrp.CanCollide=false
            hrp.Transparency=S.hitboxVisible and 0.6 or 1
            if S.hitboxVisible then hrp.Material=Enum.Material.ForceField; hrp.Color=Color3.fromRGB(255,40,60) end
        end)
    end
end
local function resetHitbox()
    for hrp,sz in pairs(hbOrig) do pcall(function() if hrp and hrp.Parent then hrp.Size=sz; hrp.Transparency=1 end end) end
    hbOrig={}
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

-- ── DOORS / BYPASS LOCK ─────────────────────────────────────
local function doAutoOpenDoors()
    local myHRP=getHRP(); if not myHRP then return end
    local doorsF=MAP and MAP:FindFirstChild("Doors")
    if doorsF then
        for _,dm in ipairs(doorsF:GetChildren()) do
            local main=dm:FindFirstChild("Door") and dm.Door:FindFirstChild("Main")
            if main then
                local pp=main:FindFirstChild("DoorPrompt")
                if pp and (myHRP.Position-main.Position).Magnitude<25 then pcall(fireprompt,pp) end
            end
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

-- ── STAY IN CIRCLE ──────────────────────────────────────────
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

-- ── ANTI PUSH ───────────────────────────────────────────────
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

-- ── MAIN LOOPS ──────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    pcall(function()
        if S.speedHack  then local h=getHum(); if h then h.WalkSpeed=S.speed end end
        if S.godMode    then local h=getHum(); if h then pcall(function() h.Health=h.MaxHealth end); pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end) end end
        if S.noDark     then applyNoDark()    end
        if S.antiPush   then doAntiPush()     end
        if S.stayCircle then doStayInCircle() end
        if S.infStam    then doInfStam()      end
        if S.hitbox     then doHitbox()       end
    end)
end)

local espT=0
RunService.Heartbeat:Connect(function(dt)
    espT+=dt; if espT<0.3 then return end; espT=0
    pcall(function()
        if S.playerESP then updatePlayerESP() end
        if S.itemESP   then updateItemESP()   end
    end)
end)

task.spawn(function()
    while true do task.wait(0.4) pcall(function()
        if S.autoOpenDoor then doAutoOpenDoors() end
        if S.bypassLock   then doBypassLock()   end
        if S.autoRevive   then doAutoRevive()   end
    end) end
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
tVis:CreateToggle({Name="Item ESP  (Tools + Models in workspace)",CurrentValue=false,Callback=function(v)
    S.itemESP=v; if not v then clearAllESP() end
end})
tVis:CreateToggle({Name="No Dark",CurrentValue=false,Callback=function(v)
    S.noDark=v
    if not v then Lighting.ClockTime=8; Lighting.Brightness=1; Lighting.Ambient=Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127)
        for _,o in ipairs(Lighting:GetChildren()) do if o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect") then o.Enabled=true end end end
end})

local tCom=Window:CreateTab("Combat",4483362458)
tCom:CreateToggle({Name="God Mode",CurrentValue=false,Callback=function(v)
    S.godMode=v; if v then setupGodMode() else for _,c in ipairs(godConns) do c:Disconnect() end; godConns={} end
end})
tCom:CreateToggle({Name="No Stun",CurrentValue=false,Callback=function(v) S.noStun=v; if v then connectNoStun() end end})
tCom:CreateToggle({Name="Inf Stamina",CurrentValue=false,Callback=function(v) S.infStam=v end})
tCom:CreateToggle({Name="Anti Push",CurrentValue=false,Callback=function(v) S.antiPush=v end})
tCom:CreateDivider()
tCom:CreateToggle({Name="Hitbox Expander",CurrentValue=false,Callback=function(v) S.hitbox=v; if not v then resetHitbox() end end})
tCom:CreateSlider({Name="Hitbox Size",Range={3,40},Increment=1,CurrentValue=12,Callback=function(v) S.hitboxSize=v end})
tCom:CreateToggle({Name="Hitbox Visible",CurrentValue=false,Callback=function(v) S.hitboxVisible=v; if not v then resetHitbox() end end})

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
tAut:CreateToggle({Name="Auto Open Doors",CurrentValue=false,Callback=function(v) S.autoOpenDoor=v end})
tAut:CreateToggle({Name="Bypass Lock",CurrentValue=false,Callback=function(v) S.bypassLock=v end})
tAut:CreateToggle({Name="Stay in King Circle",CurrentValue=false,Callback=function(v) S.stayCircle=v end})
tAut:CreateToggle({Name="Auto Revive Downed",CurrentValue=false,Callback=function(v) S.autoRevive=v end})

local tSet=Window:CreateTab("Settings",4483362458)
tSet:CreateLabel("Wallace Chaos Hub  —  FREE  |  F6 = Panic")

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

Rayfield:Notify({Title="Wallace Chaos Hub",Content="FREE loaded!",Duration=4})
