-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  FREE Edition
-- Default Rayfield theme  |  F6 = Panic
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local WS         = game:GetService("Workspace")
local LP         = Players.LocalPlayer

local function getChar() return LP.Character end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local fireprompt = (typeof(fireproximityprompt)=="function") and fireproximityprompt or function() end
local fireclick  = (typeof(fireclickdetector)=="function")  and fireclickdetector  or function() end

-- ── STATE ────────────────────────────────────────────────────
local S = {
    playerESP      = false,
    itemESP        = false,

    speedHack      = false,
    speed          = 32,
    autoSprint     = false,
    invis          = false,
    antiPush       = false,

    godMode        = false,
    noStun         = false,
    noDark         = false,
    hitboxExp      = false,
    hitboxSize     = 10,

    autoOpenDoors  = false,
    bypassLock     = false,
    stayKingCircle = false,
    autoRevive     = false,
}

local SYS = {
    Map=true, Chefs=true, Ghosts=true, Minefield=true, Camera=true, Terrain=true,
    Characters=true, DownedCharacters=true, PvpZones=true, Hover=true, Zombies=true,
    ["Project Alpha"]=true, ["Project Beta"]=true, ["Project Delta"]=true,
}

-- ── ESP (Highlight + BillboardGui with health bar) ───────────
local espData = {}

local function getOrMakeESP(obj, outlineColor)
    if not obj or not obj.Parent then return end
    local ex = espData[obj]
    if ex and ex[1] and ex[1].Parent then return ex end

    local hl = Instance.new("Highlight")
    hl.FillColor = outlineColor; hl.OutlineColor = outlineColor
    hl.FillTransparency = 0.6; hl.OutlineTransparency = 0; hl.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true; bb.Size = UDim2.new(0,180,0,54)
    bb.StudsOffset = Vector3.new(0,5,0); bb.Parent = obj

    local nm = Instance.new("TextLabel", bb)
    nm.Name="_nm"; nm.Size=UDim2.new(1,0,0.5,0)
    nm.BackgroundTransparency=1; nm.TextColor3=outlineColor
    nm.TextStrokeTransparency=0.3; nm.TextStrokeColor3=Color3.new(0,0,0)
    nm.Font=Enum.Font.GothamBold; nm.TextScaled=true; nm.Text="..."

    local bg = Instance.new("Frame", bb)
    bg.Name="_hpbg"; bg.Size=UDim2.new(1,-8,0.22,0); bg.Position=UDim2.new(0,4,0.58,0)
    bg.BackgroundColor3=Color3.fromRGB(18,18,18); bg.BorderSizePixel=0
    Instance.new("UICorner", bg).CornerRadius=UDim.new(1,0)

    local fill = Instance.new("Frame", bg)
    fill.Name="_hpf"; fill.Size=UDim2.new(1,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,210,60); fill.BorderSizePixel=0
    Instance.new("UICorner", fill).CornerRadius=UDim.new(1,0)

    local txt = Instance.new("TextLabel", bg)
    txt.Name="_hpt"; txt.Size=UDim2.fromScale(1,1)
    txt.BackgroundTransparency=1; txt.TextColor3=Color3.fromRGB(255,255,255)
    txt.TextStrokeTransparency=0.3; txt.Font=Enum.Font.GothamBold
    txt.TextScaled=true; txt.ZIndex=3; txt.Text="100%"

    espData[obj] = {hl, bb}
    return espData[obj]
end

local function updateESP(obj, label, hpPct)
    local e = espData[obj]; if not e then return end
    local bb = e[2]; if not bb or not bb.Parent then return end
    local nm = bb:FindFirstChild("_nm"); if nm then nm.Text = label or "" end
    local bg = bb:FindFirstChild("_hpbg"); if not bg then return end
    local fill = bg:FindFirstChild("_hpf"); local txt = bg:FindFirstChild("_hpt")
    local pct = math.clamp(hpPct or 1, 0, 1)
    if fill then
        fill.Size = UDim2.new(pct,0,1,0)
        fill.BackgroundColor3 = pct>0.6 and Color3.fromRGB(0,210,60)
            or pct>0.3 and Color3.fromRGB(230,170,0) or Color3.fromRGB(210,40,40)
    end
    if txt then txt.Text = math.round(pct*100).."%" end
end

local function removeESP(obj)
    local e = espData[obj]; if not e then return end
    for _, v in ipairs(e) do if v and v.Parent then v:Destroy() end end
    espData[obj] = nil
end

local function clearAllESP()
    for o in pairs(espData) do removeESP(o) end
end

-- ── ITEM DETECTION ───────────────────────────────────────────
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

-- ── GOD MODE ─────────────────────────────────────────────────
local godConns = {}

local function getGhostMaxHealth()
    local gf = WS:FindFirstChild("Ghosts"); if not gf then return 1000000 end
    for _, g in ipairs(gf:GetChildren()) do
        local gh = g:FindFirstChildOfClass("Humanoid")
        if gh and gh.MaxHealth > 0 then return gh.MaxHealth end
    end
    return 1000000
end

local function setupGodMode()
    for _, c in ipairs(godConns) do pcall(function() c:Disconnect() end) end
    godConns = {}
    if not S.godMode then return end
    local hum = getHum(); if not hum then return end
    local mx = getGhostMaxHealth()
    pcall(function() hum.MaxHealth=mx; hum.Health=mx end)
    pcall(function() hum.RequiresNeck=false end)
    pcall(function() hum.BreakJointsOnDeath=false end)
    for _, st in ipairs({Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.FallingDown}) do
        pcall(function() hum:SetStateEnabled(st,false) end)
    end
    local ok1,c1 = pcall(function()
        return hum:GetPropertyChangedSignal("Health"):Connect(function()
            if S.godMode and hum.Parent then pcall(function() hum.Health=hum.MaxHealth end) end
        end)
    end)
    if ok1 and c1 then table.insert(godConns,c1) end
    local ok2,c2 = pcall(function()
        return hum.StateChanged:Connect(function(_,new)
            if not S.godMode or not hum.Parent then return end
            if new==Enum.HumanoidStateType.Dead then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running); hum.Health=hum.MaxHealth end)
            end
        end)
    end)
    if ok2 and c2 then table.insert(godConns,c2) end
    local ok3,c3 = pcall(function()
        return hum.Died:Connect(function()
            if not S.godMode then return end
            task.wait(0.05)
            pcall(function() hum.Health=hum.MaxHealth end)
        end)
    end)
    if ok3 and c3 then table.insert(godConns,c3) end
end

-- ── NO STUN ──────────────────────────────────────────────────
local stunConn

local function connectNoStun()
    if stunConn then pcall(function() stunConn:Disconnect() end); stunConn=nil end
    local char = LP.Character; if not char then return end
    local function hookHandler(h)
        pcall(function() h.Disabled=true end)
        local ev = h:FindFirstChild("StunEvent")
        if ev then
            stunConn = ev.Event:Connect(function()
                if not S.noStun then return end
                local hum = getHum()
                if hum then pcall(function() hum.WalkSpeed=S.speedHack and S.speed or (S.autoSprint and 24 or 16) end) end
            end)
        end
    end
    local h = char:FindFirstChild("StunHandler"); if h then hookHandler(h) end
    char.ChildAdded:Connect(function(c)
        if c.Name=="StunHandler" and S.noStun then hookHandler(c) end
    end)
end

-- ── AUTO REVIVE ──────────────────────────────────────────────
local function doAutoRevive()
    local downed = WS:FindFirstChild("DownedCharacters"); if not downed then return end
    local hrp = getHRP(); if not hrp then return end
    for _, d in ipairs(downed:GetChildren()) do
        local dRoot = d:FindFirstChildWhichIsA("BasePart"); if not dRoot then continue end
        pcall(function() hrp.CFrame = CFrame.new(dRoot.Position + Vector3.new(0,2,2)) end)
        task.wait(0.08)
        for _, pp in ipairs(d:GetDescendants()) do
            if pp:IsA("ProximityPrompt") then
                local at = (pp.ActionText or ""):lower()
                if at:find("revive") or pp.KeyboardKeyCode==Enum.KeyCode.E or at=="" then
                    pcall(function()
                        pp.Enabled=true; pp.MaxActivationDistance=20
                        pp.HoldDuration=0; pp.RequiresLineOfSight=false
                    end)
                    -- fire multiple times to simulate holding E
                    pcall(fireprompt, pp); pcall(fireprompt, pp, 0)
                    task.wait(0.1)
                    pcall(fireprompt, pp); pcall(fireprompt, pp, 0)
                end
            end
        end
    end
    local hum = getHum()
    if hum and hum.Health<=0 then pcall(function() LP:LoadCharacter() end) end
end

-- ── AUTO OPEN DOORS ──────────────────────────────────────────
local function doAutoOpenDoors()
    local mapDoors = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("Doors")
    if not mapDoors then return end
    local hrp = getHRP(); if not hrp then return end
    for _, desc in ipairs(mapDoors:GetDescendants()) do
        if not desc:IsA("ProximityPrompt") then continue end
        local p = desc.Parent
        local pos = p and p:IsA("BasePart") and p.Position
        if not pos and p and p.Parent then
            local bp = p.Parent:FindFirstChildWhichIsA("BasePart"); if bp then pos=bp.Position end
        end
        if pos and (hrp.Position-pos).Magnitude < 40 then
            pcall(function() desc.Enabled=true; desc.MaxActivationDistance=50; desc.HoldDuration=0 end)
            pcall(fireprompt, desc)
        end
    end
end

-- ── STAY KING CIRCLE ─────────────────────────────────────────
local function doStayKingCircle()
    local mm = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("MapModels")
    local bz = mm and mm:FindFirstChild("ButtonZone"); if not bz then return end
    local hrp = getHRP(); if not hrp then return end
    local bpos = bz:IsA("BasePart") and bz.Position
        or (bz:FindFirstChildWhichIsA("BasePart") and bz:FindFirstChildWhichIsA("BasePart").Position)
    if bpos then pcall(function() hrp.CFrame=CFrame.new(bpos+Vector3.new(0,3,0)) end) end
end

-- ── BYPASS LOCK ──────────────────────────────────────────────
local function doBypassLock()
    local hrp = getHRP(); if not hrp then return end
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and not obj.Enabled then
            local p = obj.Parent
            local pos = p and p:IsA("BasePart") and p.Position
            if pos and (hrp.Position-pos).Magnitude < 20 then
                pcall(function() obj.Enabled=true; obj.MaxActivationDistance=30; obj.HoldDuration=0 end)
                pcall(fireprompt, obj)
            end
        end
    end
end

-- ── INVIS ────────────────────────────────────────────────────
local function applyInvis(on)
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
            pcall(function() p.LocalTransparencyModifier = on and 1 or 0 end)
        end
    end
end

-- ── NO DARK ──────────────────────────────────────────────────
local function applyNoDark(on)
    local pg = LP:FindFirstChild("PlayerGui"); if not pg then return end
    for _, g in ipairs(pg:GetDescendants()) do
        if g:IsA("Frame") then
            local nm = g.Name:lower()
            if nm:find("dark") or nm:find("overlay") or nm:find("dim") or nm:find("black") then
                pcall(function() g.Visible = not on end)
            end
        end
    end
end

-- ── ANTI PUSH ────────────────────────────────────────────────
-- Only cancel velocity when an external force spikes it (being launched/pushed),
-- not during normal movement.
local function doAntiPush()
    local hrp = getHRP(); if not hrp then return end
    pcall(function()
        local vel = hrp.AssemblyLinearVelocity
        hrp.AssemblyAngularVelocity = Vector3.zero
        if math.abs(vel.X) > 60 or math.abs(vel.Z) > 60 then
            hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
        end
    end)
end

-- ── HITBOX EXPANDER ──────────────────────────────────────────
local function doHitboxExpander()
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(function() hrp.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize) end)
end

-- ── ESP TICK ─────────────────────────────────────────────────
local function runESP()
    local myHRP = getHRP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char = plr.Character
        if char and S.playerESP then
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local phrp = char:FindFirstChild("HumanoidRootPart")
            local pct  = (hum and hum.MaxHealth>0) and (hum.Health/hum.MaxHealth) or 1
            local dist = (myHRP and phrp) and math.round((myHRP.Position-phrp.Position).Magnitude) or 0
            getOrMakeESP(char, Color3.fromRGB(255,80,80))
            updateESP(char, plr.Name.." ["..dist.."m]", pct)
        elseif espData[char] then removeESP(char) end
    end
    for _, obj in ipairs(WS:GetChildren()) do
        if isItem(obj) then
            if S.itemESP then
                local root = itemRoot(obj)
                local dist = (myHRP and root) and math.round((myHRP.Position-root.Position).Magnitude) or 0
                getOrMakeESP(obj, Color3.fromRGB(80,255,80))
                updateESP(obj, obj.Name.." ["..dist.."m]", 1)
            elseif espData[obj] then removeESP(obj) end
        end
    end
end

-- ── CHARACTER RESPAWN ────────────────────────────────────────
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if S.godMode then setupGodMode() end
    if S.noStun  then connectNoStun() end
    if S.invis   then applyInvis(true) end
end)

-- ── LOOPS ────────────────────────────────────────────────────
local LOOPS = {}

LOOPS.heartbeat = RunService.Heartbeat:Connect(function()
    if S.speedHack then
        local hum = getHum()
        if hum then pcall(function() hum.WalkSpeed=S.speed end) end
    elseif S.autoSprint then
        local hum = getHum()
        if hum then pcall(function() hum.WalkSpeed=24 end) end
    end
    if S.noStun then
        local hum = getHum()
        local exp = S.speedHack and S.speed or (S.autoSprint and 24 or 16)
        if hum and hum.WalkSpeed < exp then
            pcall(function() hum.WalkSpeed=exp end)
        end
    end
    if S.antiPush  then doAntiPush() end
    if S.noDark    then applyNoDark(true) end
    if S.hitboxExp then doHitboxExpander() end
end)

local espTimer  = 0
local miscTimer = 0

LOOPS.stepped = RunService.Stepped:Connect(function(_, dt)
    espTimer  = espTimer  + dt
    miscTimer = miscTimer + dt

    if espTimer >= 0.25 then
        espTimer = 0
        runESP()
    end

    if miscTimer >= 0.4 then
        miscTimer = 0
        if S.autoOpenDoors  then doAutoOpenDoors() end
        if S.bypassLock     then doBypassLock() end
        if S.stayKingCircle then doStayKingCircle() end
        if S.autoRevive     then doAutoRevive() end
    end
end)

-- ── F6 PANIC ─────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F6 then
        for _, c in pairs(LOOPS) do pcall(function() c:Disconnect() end) end
        clearAllESP()
        local hum = getHum()
        if hum then pcall(function() hum.WalkSpeed=16 end) end
        applyInvis(false)
        local rl = LP.PlayerGui and LP.PlayerGui:FindFirstChild("RayfieldLib")
        if rl then rl:Destroy() end
    end
end)

-- ── RAYFIELD GUI ─────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name                   = "Wallace Chaos Hub  |  FREE",
    LoadingTitle           = "Wallace Chaos Hub",
    LoadingSubtitle        = "Free Edition",
    Theme                  = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled=true, FolderName="WallaceChaos_FREE", FileName="Config" },
    KeySystem              = false,
})

-- ESP Tab
local TabESP = Window:CreateTab("ESP", 4483362458)

TabESP:CreateToggle({
    Name="Player ESP", CurrentValue=false, Flag="playerESP",
    Callback=function(v)
        S.playerESP = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr~=LP and plr.Character then removeESP(plr.Character) end
            end
        end
    end,
})

TabESP:CreateToggle({
    Name="Item ESP", CurrentValue=false, Flag="itemESP",
    Callback=function(v)
        S.itemESP = v
        if not v then
            for _, obj in ipairs(WS:GetChildren()) do
                if isItem(obj) then removeESP(obj) end
            end
        end
    end,
})

-- Movement Tab
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateToggle({
    Name="Speed Hack", CurrentValue=false, Flag="speedHack",
    Callback=function(v)
        S.speedHack = v
        if not v and not S.autoSprint then
            local hum = getHum()
            if hum then pcall(function() hum.WalkSpeed=16 end) end
        end
    end,
})

TabMove:CreateSlider({
    Name="Speed Value", Range={16,250}, Increment=1, Suffix="studs/s",
    CurrentValue=32, Flag="speedValue",
    Callback=function(v) S.speed=v end,
})

TabMove:CreateToggle({
    Name="Auto Sprint", CurrentValue=false, Flag="autoSprint",
    Callback=function(v)
        S.autoSprint = v
        if not v and not S.speedHack then
            local hum = getHum()
            if hum then pcall(function() hum.WalkSpeed=16 end) end
        end
    end,
})

TabMove:CreateToggle({
    Name="Invisible", CurrentValue=false, Flag="invis",
    Callback=function(v) S.invis=v; applyInvis(v) end,
})

TabMove:CreateToggle({
    Name="Anti Push", CurrentValue=false, Flag="antiPush",
    Callback=function(v) S.antiPush=v end,
})

-- Survival Tab
local TabSurv = Window:CreateTab("Survival", 4483362458)

TabSurv:CreateToggle({
    Name="God Mode", CurrentValue=false, Flag="godMode",
    Callback=function(v) S.godMode=v; setupGodMode() end,
})

TabSurv:CreateToggle({
    Name="No Stun", CurrentValue=false, Flag="noStun",
    Callback=function(v) S.noStun=v; if v then connectNoStun() end end,
})

TabSurv:CreateToggle({
    Name="No Dark", CurrentValue=false, Flag="noDark",
    Callback=function(v) S.noDark=v; if not v then applyNoDark(false) end end,
})

TabSurv:CreateToggle({
    Name="Hitbox Expander", CurrentValue=false, Flag="hitboxExp",
    Callback=function(v)
        S.hitboxExp = v
        if not v then
            local char = LP.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Size=Vector3.new(2,2,1) end) end
            end
        end
    end,
})

TabSurv:CreateSlider({
    Name="Hitbox Size", Range={2,60}, Increment=1, Suffix="studs",
    CurrentValue=10, Flag="hitboxSize",
    Callback=function(v) S.hitboxSize=v end,
})

-- Auto Tab
local TabAuto = Window:CreateTab("Auto", 4483362458)

TabAuto:CreateToggle({
    Name="Auto Open Doors", CurrentValue=false, Flag="autoOpenDoors",
    Callback=function(v) S.autoOpenDoors=v end,
})

TabAuto:CreateToggle({
    Name="Bypass Lock", CurrentValue=false, Flag="bypassLock",
    Callback=function(v) S.bypassLock=v end,
})

TabAuto:CreateToggle({
    Name="Stay in King Circle", CurrentValue=false, Flag="stayKingCircle",
    Callback=function(v) S.stayKingCircle=v end,
})

TabAuto:CreateToggle({
    Name="Auto Revive", CurrentValue=false, Flag="autoRevive",
    Callback=function(v) S.autoRevive=v end,
})

-- Info Tab
local TabInfo = Window:CreateTab("Info", 4483362458)
TabInfo:CreateParagraph({
    Title   = "The Button  |  FREE Edition",
    Content = "F6 = Panic / kill script.\n\nPAID version includes: Inf Stamina, Auto Grab, Auto Item, Kill Aura, Auto Zombies, Ghost ESP, Auto Carry, Carry Kill, Auto Farm, Auto Projects and more.",
})

-- ── INIT ─────────────────────────────────────────────────────
task.wait(1)
connectNoStun()
if S.godMode then setupGodMode() end
Rayfield:LoadConfiguration()
