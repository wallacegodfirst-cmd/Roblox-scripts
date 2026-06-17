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
    Name             = "Wallace Chaos Hub  |  FREE",
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
local fireprompt = (typeof(fireproximityprompt)=="function") and fireproximityprompt or function() end
local fireclick  = (typeof(fireclickdetector)=="function")  and fireclickdetector  or function() end

local MAP        = WS:WaitForChild("Map", 10)
local MAP_MODELS = MAP and MAP:FindFirstChild("MapModels")
local CHEF_NAMES = {"ChefOne","ChefTwo","ChefThree","ChefFour"}

-- folders we never treat as loose items
local SYS_FOLDERS = {
    Map=true, Chefs=true, Ghosts=true, Minefield=true, Camera=true,
    Terrain=true, Characters=true, DownedCharacters=true, PvpZones=true,
    Hover=true, ["Project Alpha"]=true, ["Project Beta"]=true, ["Project Delta"]=true,
}

-- ── ESP STORE ───────────────────────────────────────────────
local espStore = {}
local function addESP(obj, color, tag)
    if not obj or not obj.Parent then return end
    local ex = espStore[obj]
    if ex then
        if ex[2] and tag then
            local l = ex[2]:FindFirstChildOfClass("TextLabel")
            if l then l.Text = tag end
        end
        return
    end
    local h = Instance.new("Highlight")
    h.FillColor=color; h.OutlineColor=Color3.fromRGB(255,255,255)
    h.FillTransparency=0.5; h.Parent=obj
    local bb
    if tag then
        bb=Instance.new("BillboardGui")
        bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,150,0,26)
        bb.StudsOffset=Vector3.new(0,3.5,0); bb.Parent=obj
        local l=Instance.new("TextLabel",bb)
        l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=1
        l.TextColor3=color; l.TextStrokeTransparency=0
        l.Font=Enum.Font.GothamBold; l.TextScaled=true; l.Text=tag
    end
    espStore[obj]={h,bb}
end
local function removeESP(obj)
    local t=espStore[obj]; if not t then return end
    for _,v in ipairs(t) do if v and v.Parent then v:Destroy() end end
    espStore[obj]=nil
end
local function clearAllESP() for o in pairs(espStore) do removeESP(o) end end

-- ── STATE ───────────────────────────────────────────────────
local S = {
    playerESP=false, itemESP=false,
    noStun=false, speedHack=false, speed=28, invis=false, godMode=false,
    noDark=false, antiPush=false, infStam=false,
    hitbox=false, hitboxSize=12, hitboxVisible=false,
    autoOpenDoor=false, bypassLock=false, stayCircle=false, autoRevive=false,
}

-- ── ITEM DETECTION (loose models in workspace) ──────────────
local function isItemModel(obj)
    if SYS_FOLDERS[obj.Name] then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    return true
end

local function updatePlayerESP()
    local myHRP=getHRP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local c=plr.Character; if not c then continue end
        if S.playerESP then
            local tHRP=c:FindFirstChild("HumanoidRootPart")
            local d=(myHRP and tHRP) and math.round((myHRP.Position-tHRP.Position).Magnitude) or 0
            addESP(c, Color3.fromRGB(255,220,50), plr.Name.."  ["..d.."m]")
        else removeESP(c) end
    end
end

local function updateItemESP()
    for _,child in ipairs(WS:GetChildren()) do
        if isItemModel(child) then
            if S.itemESP then addESP(child, Color3.fromRGB(0,255,150), child.Name)
            else removeESP(child) end
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
-- Players.[name].PlayerGui.PlayerGUI.StaminaBar  (pin values to max)
local stamMax={}
local function doInfStam()
    local pg=LP:FindFirstChild("PlayerGui"); if not pg then return end
    local bar=pg:FindFirstChild("StaminaBar",true) or pg
    for _,d in ipairs(bar:GetDescendants()) do
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            stamMax[d]=math.max(stamMax[d] or 0, d.Value)
            d.Value=stamMax[d]
        end
    end
    -- attributes named stamina anywhere on character/humanoid
    local hum=getHum()
    if hum then
        for _,a in ipairs({"Stamina","CurrentStamina","stamina"}) do
            if hum:GetAttribute(a)~=nil then hum:SetAttribute(a,100) end
        end
    end
end

-- ── INVIS / GOD / NODARK ────────────────────────────────────
local function applyInvis(on)
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if (p:IsA("BasePart") or p:IsA("MeshPart")) and p.Name~="HumanoidRootPart" then
            p.LocalTransparencyModifier=on and 1 or 0
        end
    end
end
local function doGodMode()
    local h=getHum(); if not h then return end
    h.Health=h.MaxHealth
    pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
end
local function applyNoDark()
    Lighting.ClockTime=14; Lighting.Brightness=3
    Lighting.Ambient=Color3.fromRGB(200,200,200)
    Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200); Lighting.FogEnd=100000
    for _,o in ipairs(Lighting:GetChildren()) do
        if o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect") or o:IsA("BlurEffect") then o.Enabled=false end
    end
end

-- ── HITBOX EXPANDER ─────────────────────────────────────────
local hbOriginal={}
local function doHitbox()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local c=plr.Character; if not c then continue end
        local hrp=c:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not hbOriginal[hrp] then hbOriginal[hrp]=hrp.Size end
            hrp.Size=Vector3.new(S.hitboxSize,S.hitboxSize,S.hitboxSize)
            hrp.CanCollide=false
            hrp.Transparency=S.hitboxVisible and 0.6 or 1
            if S.hitboxVisible then
                hrp.Material=Enum.Material.ForceField
                hrp.Color=Color3.fromRGB(255,40,60)
            end
        end
    end
end
local function resetHitbox()
    for hrp,size in pairs(hbOriginal) do
        if hrp and hrp.Parent then hrp.Size=size; hrp.Transparency=1 end
    end
    hbOriginal={}
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
                if pp and pp.Parent:IsA("BasePart") and (myHRP.Position-pp.Parent.Position).Magnitude<25 then
                    pcall(fireprompt,pp)
                end
            end
        end
    end
end
-- bypass lock: force every door prompt (ignores distance/lock) + drop barriers
local function doBypassLock()
    local doorsF=MAP and MAP:FindFirstChild("Doors"); if not doorsF then return end
    for _,dm in ipairs(doorsF:GetChildren()) do
        for _,d in ipairs(dm:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function() d.Enabled=true end)
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
            if o:IsA("BasePart") then
                local n=o.Name:lower()
                if n:find("zone") or n:find("circle") or n:find("king") then return o end
            end
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
            pcall(function() v.Velocity=Vector3.zero end)
            pcall(function() v.Force=Vector3.zero end)
        end
    end
end

-- ── AUTO REVIVE (fire REVIVE prompts on downed) ─────────────
local function doAutoRevive()
    local downed=WS:FindFirstChild("DownedCharacters")
    if downed then
        for _,d in ipairs(downed:GetChildren()) do
            for _,pp in ipairs(d:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then
                    pcall(function() pp.Enabled=true end)
                    pcall(fireprompt,pp)
                end
            end
        end
    end
    local hum=getHum()
    if hum and hum.Health<=0 then pcall(function() LP:LoadCharacter() end) end
end

-- ── MAIN LOOPS ──────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    pcall(function()
        if S.speedHack  then local h=getHum(); if h then h.WalkSpeed=S.speed end end
        if S.godMode    then doGodMode()    end
        if S.noDark     then applyNoDark()  end
        if S.antiPush   then doAntiPush()   end
        if S.stayCircle then doStayInCircle() end
        if S.infStam    then doInfStam()    end
        if S.hitbox     then doHitbox()     end
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
    while true do task.wait(0.4)
        pcall(function()
            if S.autoOpenDoor then doAutoOpenDoors() end
            if S.bypassLock   then doBypassLock()   end
            if S.autoRevive   then doAutoRevive()   end
        end)
    end
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
local tVis = Window:CreateTab("Visuals", 4483362458)
tVis:CreateToggle({Name="Player ESP", CurrentValue=false, Callback=function(v)
    S.playerESP=v
    if not v then for _,p in ipairs(Players:GetPlayers()) do if p.Character then removeESP(p.Character) end end end
end})
tVis:CreateToggle({Name="Item ESP  (loose workspace items)", CurrentValue=false, Callback=function(v)
    S.itemESP=v; if not v then clearAllESP() end
end})
tVis:CreateToggle({Name="No Dark  (Always Bright)", CurrentValue=false, Callback=function(v)
    S.noDark=v
    if not v then
        Lighting.ClockTime=8; Lighting.Brightness=1
        Lighting.Ambient=Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127)
        for _,o in ipairs(Lighting:GetChildren()) do
            if o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect") then o.Enabled=true end
        end
    end
end})

local tCom = Window:CreateTab("Combat", 4483362458)
tCom:CreateToggle({Name="God Mode", CurrentValue=false, Callback=function(v) S.godMode=v end})
tCom:CreateToggle({Name="No Stun", CurrentValue=false, Callback=function(v) S.noStun=v; if v then connectNoStun() end end})
tCom:CreateToggle({Name="Inf Stamina", CurrentValue=false, Callback=function(v) S.infStam=v end})
tCom:CreateToggle({Name="Anti Push", CurrentValue=false, Callback=function(v) S.antiPush=v end})
tCom:CreateDivider()
tCom:CreateToggle({Name="Hitbox Expander", CurrentValue=false, Callback=function(v)
    S.hitbox=v; if not v then resetHitbox() end
end})
tCom:CreateSlider({Name="Hitbox Size", Range={3,40}, Increment=1, CurrentValue=12, Callback=function(v) S.hitboxSize=v end})
tCom:CreateToggle({Name="Hitbox Visible", CurrentValue=false, Callback=function(v) S.hitboxVisible=v; if not v then resetHitbox() end end})

local tMov = Window:CreateTab("Movement", 4483362458)
tMov:CreateToggle({Name="Speed Hack", CurrentValue=false, Callback=function(v) S.speedHack=v end})
tMov:CreateSlider({Name="Speed", Range={16,150}, Increment=1, CurrentValue=28, Callback=function(v) S.speed=v end})
tMov:CreateToggle({Name="Invisibility  (local)", CurrentValue=false, Callback=function(v) S.invis=v; applyInvis(v) end})
tMov:CreateDivider()
tMov:CreateDropdown({Name="Teleport to Player",
    Options=(function() local t={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then t[#t+1]=p.Name end end; return t end)(),
    CurrentOption={}, MultipleOptions=false,
    Callback=function(o) if o and o[1] then tpToPlayer(o[1]) end end})
tMov:CreateDivider()
for _,c in ipairs(CHEF_NAMES) do tMov:CreateButton({Name="TP to "..c, Callback=function() tpToChef(c) end}) end

local tAut = Window:CreateTab("Auto", 4483362458)
tAut:CreateToggle({Name="Auto Open Doors", CurrentValue=false, Callback=function(v) S.autoOpenDoor=v end})
tAut:CreateToggle({Name="Bypass Lock  (force locked doors)", CurrentValue=false, Callback=function(v) S.bypassLock=v end})
tAut:CreateToggle({Name="Stay in King Circle", CurrentValue=false, Callback=function(v) S.stayCircle=v end})
tAut:CreateToggle({Name="Auto Revive Downed", CurrentValue=false, Callback=function(v) S.autoRevive=v end})

local tSet = Window:CreateTab("Settings", 4483362458)
tSet:CreateLabel("Wallace Chaos Hub  —  FREE")
tSet:CreateLabel("F6 = Panic / close")

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.F6 then
        for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
        clearAllESP(); resetHitbox()
        local h=getHum(); if h then h.WalkSpeed=16 end
        pcall(function() Rayfield:Destroy() end)
    end
end)

Rayfield:Notify({Title="Wallace Chaos Hub", Content="FREE loaded!", Duration=4})
