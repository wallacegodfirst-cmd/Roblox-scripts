-- ============================================================
-- Wallace Chaos Hub  |  The Button (Roblox)
-- FREE  : Rayfield default theme
-- PAID  : Black / Blue / Red theme  +  all extra features
--
-- To unlock PAID, run this BEFORE loading:
--   getgenv().WallaceKey = "WC-PAID-2026"
-- Then paste-and-run this script.
-- ============================================================

-- ── PAID AUTH ───────────────────────────────────────────────
local PAID_KEYS = {
    "WC-PAID-2026",
    -- add more keys here
}
local isPaid = false
if getgenv and getgenv().WallaceKey then
    for _, k in ipairs(PAID_KEYS) do
        if getgenv().WallaceKey == k then isPaid = true; break end
    end
end

-- ── SERVICES ────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local WS         = game:GetService("Workspace")
local LP         = Players.LocalPlayer

-- ── RAYFIELD ────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local PAID_THEME = {
    TextColor                    = Color3.fromRGB(235, 235, 235),
    Background                   = Color3.fromRGB(10,  10,  14),
    Topbar                       = Color3.fromRGB(18,  22,  38),
    Shadow                       = Color3.fromRGB(0,   0,   0),
    NotificationBackground       = Color3.fromRGB(15,  15,  20),
    NotificationActionsBackground= Color3.fromRGB(30,  40,  70),
    TabBackground                = Color3.fromRGB(20,  25,  45),
    TabStroke                    = Color3.fromRGB(200, 30,  50),
    TabBackgroundSelected        = Color3.fromRGB(180, 25,  45),
    TabTextColor                 = Color3.fromRGB(210, 210, 230),
    SelectedTabTextColor         = Color3.fromRGB(255, 255, 255),
    ElementBackground            = Color3.fromRGB(16,  20,  36),
    ElementBackgroundHover       = Color3.fromRGB(30,  40,  75),
    SecondaryElementBackground   = Color3.fromRGB(14,  18,  32),
    ElementStroke                = Color3.fromRGB(40,  60,  110),
    SecondaryElementStroke       = Color3.fromRGB(120, 20,  35),
    SliderBackground             = Color3.fromRGB(180, 25,  45),
    SliderProgress               = Color3.fromRGB(30,  100, 220),
    SliderStroke                 = Color3.fromRGB(80,  130, 220),
    ToggleBackground             = Color3.fromRGB(20,  30,  60),
    ToggleEnabled                = Color3.fromRGB(220, 30,  50),
    ToggleDisabled               = Color3.fromRGB(40,  45,  60),
    ToggleEnabledStroke          = Color3.fromRGB(255, 80,  100),
    ToggleDisabledStroke         = Color3.fromRGB(60,  80,  130),
    ToggleEnabledOuterStroke     = Color3.fromRGB(30,  100, 220),
    ToggleDisabledOuterStroke    = Color3.fromRGB(40,  60,  100),
    DropdownSelected             = Color3.fromRGB(180, 25,  45),
    DropdownUnselected           = Color3.fromRGB(20,  25,  45),
    InputBackground              = Color3.fromRGB(15,  18,  30),
    InputStroke                  = Color3.fromRGB(180, 30,  50),
    PlaceholderColor             = Color3.fromRGB(150, 150, 170),
}

local Window = Rayfield:CreateWindow({
    Name             = isPaid and "Wallace Chaos Hub  |  PAID" or "Wallace Chaos Hub  |  FREE",
    Icon             = 0,
    LoadingTitle     = "Wallace Chaos Hub",
    LoadingSubtitle  = isPaid and "Black Edition — All Features" or "Free Edition",
    Theme            = isPaid and PAID_THEME or "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
})

-- ── HELPERS ─────────────────────────────────────────────────
local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ── GAME PATHS ──────────────────────────────────────────────
local MAP        = WS:WaitForChild("Map", 10)
local MAP_MODELS = MAP and MAP:FindFirstChild("MapModels")

-- confirmed from Explorer:
--   workspace.Map.MapModels.TheButton.Button.ButtonPrompt
--   workspace.Map.MapModels.ButtonZone
--   workspace.Map.Doors.{Color}Door.Door.Main.DoorPrompt
--   workspace.Chefs.ChefOne/Two/Three/Four
--   workspace.Ghosts.<playerName>
--   workspace.[name].StunHandler.StunEvent  (BindableEvent)

local ITEM_FOLDERS   = {"Items", "Drops", "ItemDrops", "Pickups"}
local ZOMBIE_FOLDERS = {"Zombies", "Enemies"}
local MINE_NAMES     = {"Mine", "Landmine", "Bomb", "Explosive", "Mina"}
local CHEF_NAMES     = {"ChefOne", "ChefTwo", "ChefThree", "ChefFour"}
local VOID_POS       = Vector3.new(0, -5000, 0)

-- ── STATE ───────────────────────────────────────────────────
local S = {
    playerESP      = false,
    itemESP        = false,
    ghostESP       = false,
    mineESP        = false,

    noStun         = false,
    speedHack      = false,
    speed          = 28,
    invis          = false,
    godMode        = false,
    noDark         = false,

    autoOpenDoor   = false,
    stayInCircle   = false,
    antiPush       = false,
    autoRevive     = false,

    killAura       = false,
    killRadius     = 20,
    autoGrab       = false,
    grabRadius     = 35,
    autoFarm       = false,
    autoCarry      = false,
    autoCarryKill  = false,
    fling          = false,
    alwaysButton   = false,
    autoKillZombie = false,

    savedCF        = nil,
    carryTarget    = nil,
}

-- ═══════════════════════════════════════════════════════════
-- ██ ESP
-- ═══════════════════════════════════════════════════════════
local espStore = {}  -- [obj] = {Highlight, BillboardGui}

local function addESP(obj, color, tag)
    if espStore[obj] then return end
    local h = Instance.new("Highlight")
    h.FillColor        = color
    h.OutlineColor     = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.Parent           = obj
    local bb
    if tag then
        bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop  = true
        bb.Size         = UDim2.new(0, 140, 0, 28)
        bb.StudsOffset  = Vector3.new(0, 3.5, 0)
        bb.Parent       = obj
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size                 = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3           = color
        lbl.TextStrokeTransparency = 0
        lbl.Font                 = Enum.Font.GothamBold
        lbl.TextScaled           = true
        lbl.Text                 = tag
    end
    espStore[obj] = {h, bb}
end

local function removeESP(obj)
    local t = espStore[obj]
    if not t then return end
    for _, v in ipairs(t) do if v and v.Parent then v:Destroy() end end
    espStore[obj] = nil
end

local function clearAllESP()
    for obj in pairs(espStore) do removeESP(obj) end
end

-- player ESP (updates label each tick)
local function updatePlayerESP()
    local myHRP = getHRP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        if S.playerESP then
            local tHRP = char:FindFirstChild("HumanoidRootPart")
            local dist = (myHRP and tHRP) and math.round((myHRP.Position - tHRP.Position).Magnitude) or 0
            removeESP(char)  -- refresh label
            addESP(char, Color3.fromRGB(255, 220, 50), plr.Name .. "  [" .. dist .. "m]")
        else
            removeESP(char)
        end
    end
end

local function updateItemESP()
    for _, fname in ipairs(ITEM_FOLDERS) do
        local folder = WS:FindFirstChild(fname)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if S.itemESP then addESP(item, Color3.fromRGB(0, 255, 150), item.Name)
                else removeESP(item) end
            end
        end
    end
end

local function updateGhostESP()
    local ghosts = WS:FindFirstChild("Ghosts")
    if not ghosts then return end
    for _, g in ipairs(ghosts:GetChildren()) do
        if S.ghostESP then
            addESP(g, Color3.fromRGB(0, 220, 255), "GHOST: " .. g.Name)
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("MeshPart") then
                    d.LocalTransparencyModifier = 0.35
                end
            end
        else
            removeESP(g)
        end
    end
end

local function updateMineESP()
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _, mn in ipairs(MINE_NAMES) do
                if obj.Name:lower():find(mn:lower()) then
                    if S.mineESP then addESP(obj, Color3.fromRGB(255, 50, 50), "MINE!")
                    else removeESP(obj) end
                    break
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ NO STUN
-- workspace.[charname].StunHandler.StunEvent  (BindableEvent)
-- ═══════════════════════════════════════════════════════════
local stunConn = nil

local function connectNoStun()
    if stunConn then stunConn:Disconnect(); stunConn = nil end
    local char = getChar()
    if not char then return end
    local function hookStun(handler)
        local ev = handler:FindFirstChild("StunEvent")
        if ev then
            stunConn = ev.Event:Connect(function()
                if not S.noStun then return end
                local hum = getHum()
                if hum then hum.WalkSpeed = S.speedHack and S.speed or 16 end
            end)
        end
    end
    local handler = char:FindFirstChild("StunHandler")
    if handler then hookStun(handler) end
    char.ChildAdded:Connect(function(c)
        if c.Name == "StunHandler" and S.noStun then hookStun(c) end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- ██ INVISIBILITY
-- ═══════════════════════════════════════════════════════════
local function applyInvis(on)
    local char = getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if (p:IsA("BasePart") or p:IsA("MeshPart")) and p.Name ~= "HumanoidRootPart" then
            p.LocalTransparencyModifier = on and 1 or 0
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ GOD MODE
-- ═══════════════════════════════════════════════════════════
local function doGodMode()
    local hum = getHum()
    if not hum then return end
    hum.Health = hum.MaxHealth
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
end

-- ═══════════════════════════════════════════════════════════
-- ██ NO DARK
-- ═══════════════════════════════════════════════════════════
local function applyNoDark()
    Lighting.ClockTime       = 14
    Lighting.Brightness      = 3
    Lighting.Ambient         = Color3.fromRGB(200, 200, 200)
    Lighting.OutdoorAmbient  = Color3.fromRGB(200, 200, 200)
    Lighting.FogEnd          = 100000
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
            obj.Enabled = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ TELEPORTS
-- ═══════════════════════════════════════════════════════════
local function tpToPlayer(name)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then return end
    local hrp  = getHRP()
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then
        hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3.5)
    end
end

local function tpToChef(name)
    local chefs = WS:FindFirstChild("Chefs")
    if not chefs then return end
    local chef = chefs:FindFirstChild(name)
    if not chef then return end
    local hrp  = getHRP()
    local root = chef:FindFirstChildOfClass("Part") or chef:FindFirstChildOfClass("MeshPart")
    if hrp and root then
        hrp.CFrame = root.CFrame * CFrame.new(0, 0, 5)
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO OPEN DOOR
-- ═══════════════════════════════════════════════════════════
local function doAutoOpenDoors()
    local myHRP = getHRP()
    if not myHRP then return end

    -- Colored doors: workspace.Map.Doors.*.Door.Main.DoorPrompt
    local doorsF = MAP and MAP:FindFirstChild("Doors")
    if doorsF then
        for _, doorModel in ipairs(doorsF:GetChildren()) do
            local main = doorModel:FindFirstChild("Door")
                and doorModel.Door:FindFirstChild("Main")
            if main then
                local pp = main:FindFirstChild("DoorPrompt")
                if pp and pp:IsA("ProximityPrompt") then
                    if (myHRP.Position - main.Position).Magnitude < 25 then
                        pcall(fireproximityprompt, pp)
                    end
                end
            end
        end
    end

    -- MapModels plain Door × 8
    if MAP_MODELS then
        for _, obj in ipairs(MAP_MODELS:GetChildren()) do
            if obj.Name == "Door" then
                local pp = obj:FindFirstChildOfClass("ProximityPrompt") or
                           (obj:IsA("Model") and obj:FindFirstChildOfClass("ProximityPrompt", true))
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

-- ═══════════════════════════════════════════════════════════
-- ██ STAY IN KING CIRCLE
-- ButtonZone confirmed at workspace.Map.MapModels.ButtonZone
-- ═══════════════════════════════════════════════════════════
local function getCirclePart()
    if MAP_MODELS then
        -- first try the confirmed name
        local bz = MAP_MODELS:FindFirstChild("ButtonZone")
        if bz and bz:IsA("BasePart") then return bz end
        -- fallback scan
        for _, obj in ipairs(MAP_MODELS:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("zone") or n:find("circle") or n:find("king") then
                    return obj
                end
            end
        end
    end
    -- scan whole workspace as last resort
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("kingcircle") or n:find("safezone") or n:find("kingzone") then
                return obj
            end
        end
    end
    return nil
end

local function doStayInCircle()
    local hrp    = getHRP()
    local circle = getCirclePart()
    if not hrp or not circle then return end
    local center = circle.Position
    local radius = math.min(circle.Size.X, circle.Size.Z) / 2 - 0.8
    local myPos  = hrp.Position
    local flat   = Vector3.new(myPos.X, center.Y, myPos.Z)
    if (flat - center).Magnitude > radius then
        local dir    = (flat - center).Unit
        local safeXZ = center + dir * (radius - 0.3)
        hrp.CFrame   = CFrame.new(Vector3.new(safeXZ.X, myPos.Y, safeXZ.Z),
                                  Vector3.new(center.X,  myPos.Y, center.Z))
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ ANTI PUSH
-- ═══════════════════════════════════════════════════════════
local function doAntiPush()
    local hrp = getHRP()
    if not hrp then return end
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") or v:IsA("BodyForce") then
            pcall(function() v.Velocity = Vector3.zero end)
            pcall(function() v.Force    = Vector3.zero end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO REVIVE
-- ═══════════════════════════════════════════════════════════
local function doAutoRevive()
    local hum = getHum()
    if hum and hum.Health <= 0 then
        pcall(function() LP:LoadCharacter() end)
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ ALWAYS GET BUTTON  (PAID)
-- workspace.Map.MapModels.TheButton.Button.ButtonPrompt
-- ═══════════════════════════════════════════════════════════
local function tryGetButton()
    if not MAP_MODELS then return end
    local theButton = MAP_MODELS:FindFirstChild("TheButton")
    if not theButton then return end
    local btn = theButton:FindFirstChild("Button")
    if not btn then return end
    local pp = btn:FindFirstChild("ButtonPrompt")
    if pp and pp:IsA("ProximityPrompt") then
        pcall(fireproximityprompt, pp)
    end
    local cd = btn:FindFirstChildOfClass("ClickDetector")
    if cd then pcall(fireclickdetector, cd) end
end

-- ═══════════════════════════════════════════════════════════
-- ██ KILL AURA  (PAID)
-- ═══════════════════════════════════════════════════════════
local function doKillAura()
    local hrp = getHRP()
    if not hrp then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local tHRP = char:FindFirstChild("HumanoidRootPart")
        if not tHRP then continue end
        if (hrp.Position - tHRP.Position).Magnitude <= S.killRadius then
            local behind = tHRP.Position - tHRP.CFrame.LookVector * 3
            hrp.CFrame = CFrame.new(Vector3.new(behind.X, tHRP.Position.Y, behind.Z), tHRP.Position)
            local bv = Instance.new("BodyVelocity")
            bv.Velocity  = tHRP.CFrame.LookVector * -90 + Vector3.new(0, 55, 0)
            bv.MaxForce  = Vector3.one * 1e7
            bv.Parent    = tHRP
            task.delay(0.12, function() if bv and bv.Parent then bv:Destroy() end end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO GRAB ITEMS / AURA  (PAID)
-- ═══════════════════════════════════════════════════════════
local function doAutoGrabItems()
    local hrp = getHRP()
    if not hrp then return end
    for _, fname in ipairs(ITEM_FOLDERS) do
        local folder = WS:FindFirstChild(fname)
        if not folder then continue end
        for _, item in ipairs(folder:GetChildren()) do
            local p = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
            if not p then continue end
            if (hrp.Position - p.Position).Magnitude > S.grabRadius then continue end
            local pp = item:FindFirstChildOfClass("ProximityPrompt", true)
            if pp then pcall(fireproximityprompt, pp); continue end
            local cd = item:FindFirstChildOfClass("ClickDetector", true)
            if cd then pcall(fireclickdetector, cd); continue end
            hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0))
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO FARM PLAYER  (PAID)
-- ═══════════════════════════════════════════════════════════
local farmIdx = 1
local function doAutoFarmPlayer()
    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then targets[#targets+1] = p end
    end
    if #targets == 0 then return end
    farmIdx = (farmIdx % #targets) + 1
    local t   = targets[farmIdx]
    local hrp = getHRP()
    local tHRP = t.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    local behind = tHRP.Position - tHRP.CFrame.LookVector * 3
    hrp.CFrame = CFrame.new(Vector3.new(behind.X, tHRP.Position.Y, behind.Z), tHRP.Position)
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO KILL ZOMBIES / CHEFS  (PAID)
-- ═══════════════════════════════════════════════════════════
local function doAutoKillZombies()
    local hrp = getHRP()
    if not hrp then return end
    local sources = {}
    for _, fname in ipairs(ZOMBIE_FOLDERS) do
        local f = WS:FindFirstChild(fname)
        if f then sources[#sources+1] = f end
    end
    local chefsF = WS:FindFirstChild("Chefs")
    if chefsF then sources[#sources+1] = chefsF end

    for _, folder in ipairs(sources) do
        for _, enemy in ipairs(folder:GetChildren()) do
            local eHum = enemy:FindFirstChildOfClass("Humanoid")
            local eHRP = enemy:FindFirstChild("HumanoidRootPart")
            if eHum and eHRP and eHum.Health > 0 then
                if (hrp.Position - eHRP.Position).Magnitude < 70 then
                    hrp.CFrame = CFrame.new(eHRP.Position + Vector3.new(0, 0, 3), eHRP.Position)
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity  = Vector3.new(0, 120, 0)
                    bv.MaxForce  = Vector3.one * 9e9
                    bv.Parent    = eHRP
                    task.delay(0.15, function() if bv.Parent then bv:Destroy() end end)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ██ AUTO CARRY + CARRY KILL  (PAID)
-- ═══════════════════════════════════════════════════════════
local function findNearestTarget()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local c = plr.Character
        if not c then continue end
        local tHRP = c:FindFirstChild("HumanoidRootPart")
        if tHRP then
            local d = (hrp.Position - tHRP.Position).Magnitude
            if d < bestDist then best = plr; bestDist = d end
        end
    end
    return best
end

local function doAutoCarry()
    local target = findNearestTarget()
    if not target or not target.Character then S.carryTarget = nil; return end
    S.carryTarget = target
    local hrp  = getHRP()
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    tHRP.CFrame = hrp.CFrame * CFrame.new(0, 4, 0)
    local pp = target.Character:FindFirstChildOfClass("ProximityPrompt", true)
    if pp then pcall(fireproximityprompt, pp) end
end

local function doCarryKill()
    if not S.carryTarget or not S.carryTarget.Character then
        -- grab nearest if no carry target
        S.carryTarget = findNearestTarget()
    end
    if not S.carryTarget or not S.carryTarget.Character then return end
    local hrp  = getHRP()
    if not hrp then return end
    S.savedCF = hrp.CFrame
    local tHRP = S.carryTarget.Character:FindFirstChild("HumanoidRootPart")
    -- TP to void
    hrp.CFrame = CFrame.new(VOID_POS)
    if tHRP then tHRP.CFrame = CFrame.new(VOID_POS) end
    task.wait(1.2)
    -- TP back
    if S.savedCF then hrp.CFrame = S.savedCF end
    S.carryTarget = nil
end

-- ═══════════════════════════════════════════════════════════
-- ██ FLING  (PAID)
-- ═══════════════════════════════════════════════════════════
local function flingTarget(plr)
    if not plr or not plr.Character then return end
    local hrp  = getHRP()
    local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    hrp.CFrame = CFrame.new(tHRP.Position + Vector3.new(0, 0, 2), tHRP.Position)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = (tHRP.Position - hrp.Position).Unit * 600 + Vector3.new(0, 250, 0)
    bv.MaxForce  = Vector3.one * 1e9
    bv.Parent    = tHRP
    task.delay(0.2, function() if bv.Parent then bv:Destroy() end end)
end

-- ═══════════════════════════════════════════════════════════
-- ██ MAIN LOOPS
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    pcall(function()
        if S.speedHack then
            local hum = getHum(); if hum then hum.WalkSpeed = S.speed end
        end
        if S.godMode    then doGodMode() end
        if S.noDark     then applyNoDark() end
        if S.antiPush   then doAntiPush() end
        if S.stayInCircle then doStayInCircle() end
        if S.autoRevive then doAutoRevive() end
    end)
end)

-- ESP tick (0.3s)
local espT = 0
RunService.Heartbeat:Connect(function(dt)
    espT += dt
    if espT < 0.3 then return end; espT = 0
    pcall(function()
        if S.playerESP then updatePlayerESP() end
        if S.itemESP   then updateItemESP()   end
        if S.ghostESP  then updateGhostESP()  end
        if S.mineESP   then updateMineESP()   end
    end)
end)

-- fast paid loop (0.12s)
task.spawn(function()
    while true do
        task.wait(0.12)
        pcall(function()
            if S.killAura then doKillAura()    end
            if S.autoGrab then doAutoGrabItems() end
            if S.autoCarry then doAutoCarry()  end
        end)
    end
end)

-- slower paid loop (0.5s)
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if S.autoFarmPlayer then doAutoFarmPlayer()   end
            if S.autoKillZombie then doAutoKillZombies()  end
            if S.alwaysButton   then tryGetButton()        end
        end)
    end
end)

-- fling loop
task.spawn(function()
    while true do
        task.wait(0.3)
        if S.fling then
            pcall(function() flingTarget(findNearestTarget()) end)
        end
    end
end)

-- re-apply on respawn
LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    if S.invis  then applyInvis(true) end
    if S.noStun then connectNoStun()  end
end)
connectNoStun()

-- ═══════════════════════════════════════════════════════════
-- ██ UI — TAB: VISUALS
-- ═══════════════════════════════════════════════════════════
local tVisuals = Window:CreateTab("Visuals", 4483362458)

tVisuals:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v)
        S.playerESP = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character then removeESP(plr.Character) end
            end
        end
    end,
})

tVisuals:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Callback = function(v) S.itemESP = v end,
})

if isPaid then
    tVisuals:CreateToggle({
        Name = "Ghost ESP  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.ghostESP = v end,
    })
    tVisuals:CreateToggle({
        Name = "Mine ESP  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.mineESP = v end,
    })
end

tVisuals:CreateToggle({
    Name = "No Dark  (Always Bright)",
    CurrentValue = false,
    Callback = function(v)
        S.noDark = v
        if not v then
            Lighting.ClockTime      = 8
            Lighting.Brightness     = 1
            Lighting.Ambient        = Color3.fromRGB(127,127,127)
            Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") then
                    obj.Enabled = true
                end
            end
        end
    end,
})

-- ═══════════════════════════════════════════════════════════
-- ██ UI — TAB: COMBAT
-- ═══════════════════════════════════════════════════════════
local tCombat = Window:CreateTab("Combat", 4483362458)

tCombat:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(v) S.godMode = v end,
})

tCombat:CreateToggle({
    Name = "No Stun",
    CurrentValue = false,
    Callback = function(v)
        S.noStun = v
        if v then connectNoStun() end
    end,
})

tCombat:CreateToggle({
    Name = "Anti Push",
    CurrentValue = false,
    Callback = function(v) S.antiPush = v end,
})

tCombat:CreateToggle({
    Name = "Auto Revive",
    CurrentValue = false,
    Callback = function(v) S.autoRevive = v end,
})

if isPaid then
    tCombat:CreateDivider()

    tCombat:CreateToggle({
        Name = "Kill Aura  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.killAura = v end,
    })
    tCombat:CreateSlider({
        Name = "Kill Aura Radius",
        Range = {5, 60},
        Increment = 1,
        CurrentValue = 20,
        Callback = function(v) S.killRadius = v end,
    })
    tCombat:CreateToggle({
        Name = "Fling Nearest Player  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.fling = v end,
    })
    tCombat:CreateToggle({
        Name = "Auto Kill Zombies / Chefs  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.autoKillZombie = v end,
    })
end

-- ═══════════════════════════════════════════════════════════
-- ██ UI — TAB: MOVEMENT
-- ═══════════════════════════════════════════════════════════
local tMove = Window:CreateTab("Movement", 4483362458)

tMove:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(v) S.speedHack = v end,
})
tMove:CreateSlider({
    Name = "Speed",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = 28,
    Callback = function(v) S.speed = v end,
})

tMove:CreateToggle({
    Name = "Invisibility  (local only)",
    CurrentValue = false,
    Callback = function(v) S.invis = v; applyInvis(v) end,
})

tMove:CreateDivider()

tMove:CreateDropdown({
    Name = "Teleport to Player",
    Options = (function()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then t[#t+1] = p.Name end
        end
        return t
    end)(),
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(opt) if opt and opt[1] then tpToPlayer(opt[1]) end end,
})

tMove:CreateDivider()

for _, cname in ipairs(CHEF_NAMES) do
    tMove:CreateButton({
        Name = "TP to " .. cname,
        Callback = function() tpToChef(cname) end,
    })
end

-- ═══════════════════════════════════════════════════════════
-- ██ UI — TAB: AUTO
-- ═══════════════════════════════════════════════════════════
local tAuto = Window:CreateTab("Auto", 4483362458)

tAuto:CreateToggle({
    Name = "Auto Open Doors",
    CurrentValue = false,
    Callback = function(v)
        S.autoOpenDoor = v
        if v then
            task.spawn(function()
                while S.autoOpenDoor do
                    pcall(doAutoOpenDoors)
                    task.wait(0.4)
                end
            end)
        end
    end,
})

tAuto:CreateToggle({
    Name = "Stay in King Circle  (King Mode)",
    CurrentValue = false,
    Callback = function(v) S.stayInCircle = v end,
})

if isPaid then
    tAuto:CreateDivider()

    tAuto:CreateToggle({
        Name = "Always Get Button  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.alwaysButton = v end,
    })

    tAuto:CreateToggle({
        Name = "Auto Grab Items / Aura  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.autoGrab = v end,
    })
    tAuto:CreateSlider({
        Name = "Grab Radius",
        Range = {5, 80},
        Increment = 1,
        CurrentValue = 35,
        Callback = function(v) S.grabRadius = v end,
    })

    tAuto:CreateToggle({
        Name = "Auto Farm Player  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.autoFarmPlayer = v end,
    })
end

-- ═══════════════════════════════════════════════════════════
-- ██ UI — TAB: CARRY  (PAID)
-- ═══════════════════════════════════════════════════════════
if isPaid then
    local tCarry = Window:CreateTab("Carry", 4483362458)

    tCarry:CreateToggle({
        Name = "Auto Carry Nearest  [PAID]",
        CurrentValue = false,
        Callback = function(v) S.autoCarry = v end,
    })

    tCarry:CreateButton({
        Name = "Carry Kill  (TP to void + return)  [PAID]",
        Callback = function()
            task.spawn(function() pcall(doCarryKill) end)
        end,
    })

    tCarry:CreateDivider()

    tCarry:CreateButton({
        Name = "Save Position",
        Callback = function()
            local hrp = getHRP()
            if hrp then
                S.savedCF = hrp.CFrame
                Rayfield:Notify({ Title="Saved", Content="Position saved!", Duration=2 })
            end
        end,
    })
    tCarry:CreateButton({
        Name = "Return to Saved Position",
        Callback = function()
            local hrp = getHRP()
            if hrp and S.savedCF then hrp.CFrame = S.savedCF end
        end,
    })
end

-- ═══════════════════════════════════════════════════════════
-- ██ UI — TAB: SETTINGS
-- ═══════════════════════════════════════════════════════════
local tSettings = Window:CreateTab("Settings", 4483362458)

tSettings:CreateLabel(isPaid and "Wallace Chaos Hub  —  PAID Edition" or "Wallace Chaos Hub  —  FREE Edition")
tSettings:CreateLabel("Press F6 to Panic / destroy UI")

if not isPaid then
    tSettings:CreateDivider()
    tSettings:CreateLabel("Unlock PAID features:")
    tSettings:CreateLabel("getgenv().WallaceKey = \"WC-PAID-2026\"")
    tSettings:CreateLabel("...then re-execute the script")
end

tSettings:CreateDivider()
tSettings:CreateLabel("Game: The Button by Overcell")
tSettings:CreateLabel("Script by Wallace Chaos")

-- ═══════════════════════════════════════════════════════════
-- ██ PANIC KEY  F6
-- ═══════════════════════════════════════════════════════════
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F6 then
        -- kill all loops
        S.godMode=false S.speedHack=false S.killAura=false
        S.alwaysButton=false S.autoFarmPlayer=false S.autoGrab=false
        S.autoCarry=false S.autoKillZombie=false S.fling=false
        S.autoOpenDoor=false S.stayInCircle=false S.antiPush=false
        S.playerESP=false S.itemESP=false S.ghostESP=false S.mineESP=false
        clearAllESP()
        -- restore speed
        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end
        -- destroy UI
        pcall(function() Rayfield:Destroy() end)
    end
end)

-- ═══════════════════════════════════════════════════════════
Rayfield:Notify({
    Title   = "Wallace Chaos Hub",
    Content = isPaid and "PAID Edition active — all features unlocked!" or "FREE Edition loaded — enjoy!",
    Duration = 5,
})
