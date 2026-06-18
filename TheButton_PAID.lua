-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  PAID Edition
-- Black / Purple theme  |  F6 = Panic
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
local sethidden  = (typeof(sethiddenproperty)=="function") and sethiddenproperty or nil

-- ── NETWORK OWNERSHIP (FE physics) ───────────────────────────
-- Maxing the local player's simulation radius makes the server grant us network
-- ownership of every unanchored part we touch, so when we move those parts their
-- positions REPLICATE to the server and to every other player. This is what makes
-- Float Weapons visible to everyone, not just on our own screen.
local function claimOwnership()
    if sethidden then
        pcall(sethidden, LP, "SimulationRadius", math.huge)
        pcall(sethidden, LP, "MaximumSimulationRadius", math.huge)
    end
    pcall(function() LP.SimulationRadius = math.huge end)
    pcall(function() LP.MaximumSimulationRadius = math.huge end)
end

-- Out-of-map TP position (far outside map boundary, causes fall death)
local OUTOFMAP = Vector3.new(9999, 200, 9999)

-- ── SAFE TELEPORT (anti-kick) ────────────────────────────────
-- Many anti-cheats kick on a single large position jump per frame ("teleport"
-- detection) or on high velocity ("fling" detection). safeTP moves in small
-- hops (<= MAX_HOP studs) across consecutive frames so no single step looks
-- suspicious, and zeroes velocity each hop so it never reads as a fling.
local MAX_HOP = 90
local function safeTP(targetCF)
    local hrp = getHRP(); if not hrp then return end
    local goal = targetCF.Position
    local rot  = targetCF - targetCF.Position   -- rotation-only component
    while true do
        local h = getHRP(); if not h then return end
        local cur  = h.Position
        local diff = goal - cur
        local dist = diff.Magnitude
        if dist <= MAX_HOP then
            pcall(function()
                h.CFrame = CFrame.new(goal) * rot
                h.AssemblyLinearVelocity  = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero
            end)
            return
        end
        local step = cur + diff.Unit * MAX_HOP
        pcall(function()
            h.CFrame = CFrame.new(step)
            h.AssemblyLinearVelocity  = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end)
        RunService.Heartbeat:Wait()
    end
end

-- ── STATE ────────────────────────────────────────────────────
local S = {
    playerESP      = false,
    itemESP        = false,
    ghostESP       = false,
    mineESP        = false,

    speedHack      = false,
    speed          = 32,
    autoSprint     = false,
    invis          = false,
    antiPush       = false,
    antiKick       = true,

    godMode        = false,
    infStam        = false,
    noStun         = false,
    noDark         = false,
    hitboxExp      = false,
    hitboxSize     = 10,

    killAura       = false,
    killAuraRadius = 20,
    autoAttack     = false,
    fling          = false,

    floatWeapons   = false,
    floatShape     = "Orbit",
    floatRadius    = 8,
    floatSpeed     = 2,
    floatMax       = 24,
    gunKill        = false,
    gunKillRadius  = 15,

    autoKillZombies = false,

    autoOpenDoors   = false,
    noclip          = false,
    antiCarry       = false,
    stayKingCircle  = false,
    alwaysGetButton = false,

    autoRevive     = false,
    autoGrab       = false,
    grabRadius     = 50,
    autoItem       = false,
    autoCarry      = false,
    carryKill      = false,
    autoFarm       = false,

    autoAlpha      = false,
    autoBeta       = false,
    autoDelta      = false,
}

local SYS = {
    Map=true, Chefs=true, Ghosts=true, Minefield=true, Camera=true, Terrain=true,
    Characters=true, DownedCharacters=true, PvpZones=true, Hover=true, Zombies=true,
    ["Project Alpha"]=true, ["Project Beta"]=true, ["Project Delta"]=true,
}

-- Mine cache: built once at load, updated on ChildAdded/Removed.
-- Avoids calling GetDescendants() every ESP frame which causes lag.
local mineCache = {}
task.defer(function()
    local mf = WS:FindFirstChild("Minefield"); if not mf then return end
    for _, child in ipairs(mf:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            mineCache[#mineCache+1] = child
        end
    end
    mf.ChildAdded:Connect(function(c)
        if c:IsA("Model") or c:IsA("BasePart") then mineCache[#mineCache+1]=c end
    end)
    mf.ChildRemoved:Connect(function(c)
        for i, m in ipairs(mineCache) do
            if m==c then table.remove(mineCache,i); removeESP(c); break end
        end
    end)
end)

-- ── ESP (Highlight + BillboardGui with health bar) ───────────
local espData = {}

local function getOrMakeESP(obj, outlineColor)
    if not obj or not obj.Parent then return end
    local ex = espData[obj]
    if ex and ex[1] and ex[1].Parent then return ex end

    local hl = Instance.new("Highlight")
    hl.FillColor=outlineColor; hl.OutlineColor=outlineColor
    hl.FillTransparency=0.45; hl.OutlineTransparency=0; hl.Parent=obj

    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,240,0,76)
    bb.StudsOffset=Vector3.new(0,6.5,0); bb.Parent=obj

    -- name + distance row
    local nm = Instance.new("TextLabel", bb)
    nm.Name="_nm"; nm.Size=UDim2.new(1,0,0.48,0)
    nm.BackgroundTransparency=1; nm.TextColor3=outlineColor
    nm.TextStrokeTransparency=1
    nm.Font=Enum.Font.GothamBlack; nm.TextScaled=true; nm.Text="..."
    local nmS = Instance.new("UIStroke", nm)
    nmS.Color=Color3.fromRGB(0,0,0); nmS.Thickness=1.8; nmS.Transparency=0

    -- health bar background
    local bg = Instance.new("Frame", bb)
    bg.Name="_hpbg"; bg.Size=UDim2.new(1,-10,0.22,0); bg.Position=UDim2.new(0,5,0.54,0)
    bg.BackgroundColor3=Color3.fromRGB(10,10,10); bg.BorderSizePixel=0
    Instance.new("UICorner", bg).CornerRadius=UDim.new(1,0)
    local bgS = Instance.new("UIStroke", bg)
    bgS.Color=outlineColor; bgS.Thickness=1; bgS.Transparency=0.35

    -- health fill
    local fill = Instance.new("Frame", bg)
    fill.Name="_hpf"; fill.Size=UDim2.new(1,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,235,80); fill.BorderSizePixel=0
    Instance.new("UICorner", fill).CornerRadius=UDim.new(1,0)

    -- hp text (percentage + number)
    local txt = Instance.new("TextLabel", bg)
    txt.Name="_hpt"; txt.Size=UDim2.fromScale(1,1)
    txt.BackgroundTransparency=1; txt.TextColor3=Color3.fromRGB(255,255,255)
    txt.TextStrokeTransparency=1; txt.Font=Enum.Font.GothamBlack
    txt.TextScaled=true; txt.ZIndex=3; txt.Text="100%"
    local txS = Instance.new("UIStroke", txt)
    txS.Color=Color3.fromRGB(0,0,0); txS.Thickness=1.2; txS.Transparency=0

    -- HP value label below bar
    local hl2 = Instance.new("TextLabel", bb)
    hl2.Name="_hpv"; hl2.Size=UDim2.new(1,0,0.2,0); hl2.Position=UDim2.new(0,0,0.79,0)
    hl2.BackgroundTransparency=1; hl2.TextColor3=Color3.fromRGB(200,200,200)
    hl2.TextStrokeTransparency=1; hl2.Font=Enum.Font.GothamBlack; hl2.TextScaled=true; hl2.Text=""
    local hv2S = Instance.new("UIStroke", hl2)
    hv2S.Color=Color3.fromRGB(0,0,0); hv2S.Thickness=1.2; hv2S.Transparency=0

    espData[obj] = {hl, bb}
    return espData[obj]
end

local function updateESP(obj, label, hpPct, maxHp)
    local e = espData[obj]; if not e then return end
    local bb = e[2]; if not bb or not bb.Parent then return end
    local nm = bb:FindFirstChild("_nm"); if nm then nm.Text=label or "" end
    local bg = bb:FindFirstChild("_hpbg"); if not bg then return end
    local fill = bg:FindFirstChild("_hpf"); local txt=bg:FindFirstChild("_hpt")
    local pct = math.clamp(hpPct or 1, 0, 1)
    if fill then
        fill.Size=UDim2.new(pct,0,1,0)
        fill.BackgroundColor3 = pct>0.6 and Color3.fromRGB(0,235,80)
            or pct>0.3 and Color3.fromRGB(255,190,0) or Color3.fromRGB(240,50,50)
    end
    if txt then txt.Text=math.round(pct*100).."%" end
    local hpv = bb:FindFirstChild("_hpv")
    if hpv then
        if maxHp and maxHp > 0 then
            hpv.Text = math.round(pct*maxHp).." / "..math.round(maxHp).." HP"
        end
    end
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
        if gh and gh.MaxHealth>0 then return gh.MaxHealth end
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
    local ok1,c1=pcall(function()
        return hum:GetPropertyChangedSignal("Health"):Connect(function()
            if S.godMode and hum.Parent then pcall(function() hum.Health=hum.MaxHealth end) end
        end)
    end); if ok1 and c1 then table.insert(godConns,c1) end
    local ok2,c2=pcall(function()
        return hum.StateChanged:Connect(function(_,new)
            if not S.godMode or not hum.Parent then return end
            if new==Enum.HumanoidStateType.Dead then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running); hum.Health=hum.MaxHealth end)
            end
        end)
    end); if ok2 and c2 then table.insert(godConns,c2) end
    local ok3,c3=pcall(function()
        return hum.Died:Connect(function()
            if not S.godMode then return end
            task.wait(0.05); pcall(function() hum.Health=hum.MaxHealth end)
        end)
    end); if ok3 and c3 then table.insert(godConns,c3) end
end

-- ── INF STAMINA ──────────────────────────────────────────────
-- Search ALL descendants of PlayerGui AND character for stam/sprint scripts and frames.
local function doInfStam()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, desc in ipairs(pg:GetDescendants()) do
            local nm = desc.Name:lower()
            if desc:IsA("LocalScript") and (nm:find("stam") or nm:find("sprint") or nm:find("energy")) then
                pcall(function() desc.Disabled=true end)
            end
            if desc:IsA("Frame") and (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("bar")) then
                pcall(function() desc.Size=UDim2.new(1,0,desc.Size.Y.Scale,0) end)
            end
            if (desc:IsA("NumberValue") or desc:IsA("IntValue")) and (nm:find("stam") or nm:find("energy")) then
                pcall(function() desc.Value = desc.MaxValue or 100 end)
            end
        end
    end
    local char = LP.Character
    if char then
        for _, desc in ipairs(char:GetDescendants()) do
            local nm = desc.Name:lower()
            if desc:IsA("LocalScript") and (nm:find("stam") or nm:find("sprint")) then
                pcall(function() desc.Disabled=true end)
            end
        end
    end
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

-- ── NEAREST ENEMY ────────────────────────────────────────────
local function findNearest(radius)
    local hrp = getHRP(); if not hrp then return nil, nil end
    radius = radius or 9999
    local best, bestDist, bestHRP = nil, radius+1, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char = plr.Character; if not char then continue end
        local phrp = char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health>0 then
            local d = (hrp.Position-phrp.Position).Magnitude
            if d<bestDist then best=plr; bestDist=d; bestHRP=phrp end
        end
    end
    return best, bestHRP
end

-- ── KILL AURA ────────────────────────────────────────────────
local function doKillAura()
    local hrp = getHRP(); if not hrp then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char = plr.Character; if not char then continue end
        local phrp = char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then continue end
        if (hrp.Position-phrp.Position).Magnitude <= S.killAuraRadius then
            pcall(function() hum:TakeDamage(1e9) end)
        end
    end
end

-- ── FLING ────────────────────────────────────────────────────
-- WARNING: flinging sets another character's velocity, which is exactly what the
-- game's "Fling detected" anti-cheat looks for. We keep the magnitude moderate and
-- apply it as a short series of pushes rather than one massive spike, which is far
-- less likely to trip detection than the old 3000-velocity slam.
local function doFling()
    local _, targetHRP = findNearest(200)
    if not targetHRP then return end
    for _ = 1, 4 do
        local h = getHRP()
        local t = targetHRP
        if not t or not t.Parent then break end
        pcall(function()
            t.AssemblyLinearVelocity = Vector3.new(
                math.random(-120,120), 180, math.random(-120,120)
            )
        end)
        RunService.Heartbeat:Wait()
    end
end

-- ── FLOAT WEAPONS ────────────────────────────────────────────
-- Gathers nearby item parts and floats them around the player in a chosen shape
-- (Orbit ring, Ball/sphere, Sword, Halo, Wings). Parts are unanchored and their
-- CFrame is set every frame; because they are unanchored and near you, the server
-- usually grants you network ownership, so OTHER players see the formation too.
local floatParts = {}    -- [BasePart] = originalAnchored
local floatAngle = 0
local floatRegather = 0

local function floatRelease(part)
    local orig = floatParts[part]
    if orig ~= nil and part and part.Parent then
        pcall(function() part.Anchored = orig end)
    end
    floatParts[part] = nil
end

local function floatReleaseAll()
    for p in pairs(floatParts) do floatRelease(p) end
end

local function floatGather()
    local hrp = getHRP(); if not hrp then return {} end
    local found = {}
    for _, child in ipairs(WS:GetChildren()) do
        if isItem(child) then
            local r = itemRoot(child)
            if r and r:IsA("BasePart") then found[#found+1] = r end
        end
    end
    table.sort(found, function(a, b)
        return (a.Position-hrp.Position).Magnitude < (b.Position-hrp.Position).Magnitude
    end)
    local picked = {}
    for i = 1, math.min(#found, S.floatMax) do picked[i] = found[i] end
    return picked
end

-- Humanoid silhouette for the JoJo "Stand" formation. Ordered so even a few items
-- still read as a figure (head, torso, pelvis, hands, feet first; detail fills in).
local STAND_OFFSETS = {
    {x= 0.0, y=5.2}, {x= 0.0, y=3.6}, {x= 0.0, y=2.1},          -- head, torso, pelvis
    {x=-2.4, y=2.0}, {x= 2.4, y=2.0},                            -- hands
    {x=-0.95,y=0.05},{x= 0.95,y=0.05},                           -- feet
    {x=-1.3, y=4.3}, {x= 1.3, y=4.3},                            -- shoulders
    {x=-0.85,y=0.8}, {x= 0.85,y=0.8},                            -- knees
    {x=-2.0, y=3.0}, {x= 2.0, y=3.0},                            -- elbows
    {x= 0.0, y=4.5}, {x= 0.0, y=4.1}, {x= 0.0, y=2.8},           -- neck, chest, abdomen
    {x=-0.7, y=2.0}, {x= 0.7, y=2.0},                            -- hips
    {x=-0.8, y=1.4}, {x= 0.8, y=1.4},                            -- thighs
    {x=-0.9, y=0.4}, {x= 0.9, y=0.4},                            -- shins
    {x=-2.2, y=2.5}, {x= 2.2, y=2.5},                            -- forearms
    {x=-1.7, y=3.6}, {x= 1.7, y=3.6},                            -- upper arms
    {x=-0.5, y=5.2}, {x= 0.5, y=5.2},                            -- head sides
    {x=-0.65,y=4.1}, {x= 0.65,y=4.1},                            -- upper chest
}

local function floatShapeCF(shape, i, n, center, lookCF)
    local r = S.floatRadius
    if shape == "Ball" then
        -- fibonacci sphere distribution
        local k   = i - 1
        local off = 2 / n
        local y   = (k * off) - 1 + (off / 2)
        local rad = math.sqrt(math.max(0, 1 - y*y))
        local phi = k * 2.399963229728653 + floatAngle   -- golden angle
        return CFrame.new(center + Vector3.new(math.cos(phi)*rad, y, math.sin(phi)*rad) * r)
    elseif shape == "Cube" then
        -- sphere points projected to a cube surface, slowly rotating
        local k   = i - 1
        local off = 2 / n
        local y   = (k * off) - 1 + (off / 2)
        local rad = math.sqrt(math.max(0, 1 - y*y))
        local phi = k * 2.399963229728653 + floatAngle
        local dir = Vector3.new(math.cos(phi)*rad, y, math.sin(phi)*rad)
        local m   = math.max(math.abs(dir.X), math.abs(dir.Y), math.abs(dir.Z), 1e-3)
        return CFrame.new(center + (dir / m) * r) * CFrame.Angles(0, floatAngle, 0)
    elseif shape == "Spiral" then
        -- rising tornado that widens toward the top
        local t      = (i - 1) / math.max(1, n - 1)
        local ang    = floatAngle * 1.5 + t * math.pi * 6
        local radius = r * (0.3 + 0.7 * t)
        local height = t * r * 2.2 - r
        return CFrame.new(center + Vector3.new(math.cos(ang)*radius, height, math.sin(ang)*radius))
    elseif shape == "Stand" then
        -- JoJo Stand: humanoid figure hovering behind-right of the player, facing forward
        local o     = STAND_OFFSETS[((i - 1) % #STAND_OFFSETS) + 1]
        local scale = r / 5
        local bob   = math.sin(floatAngle) * 0.4
        local origin = center
            - lookCF.LookVector * 3
            + lookCF.RightVector * 2.5
            + Vector3.new(0, bob - 2.5, 0)
        local pos = origin
            + lookCF.RightVector * (o.x * scale)
            + Vector3.new(0, o.y * scale, 0)
        return CFrame.new(pos, pos + lookCF.LookVector)   -- parts face same way as player
    elseif shape == "Sword" then
        -- vertical blade in front of the player
        local t      = (i - 1) / math.max(1, n - 1)
        local height = t * r * 2 - r * 0.5
        local fwd    = lookCF.LookVector * (r * 0.4)
        return CFrame.new(center + fwd + Vector3.new(0, height, 0))
            * CFrame.Angles(math.rad(90), 0, 0)
    elseif shape == "Halo" then
        local ang = floatAngle + (i / n) * math.pi * 2
        return CFrame.new(center + Vector3.new(math.cos(ang), 2.4, math.sin(ang)) * r)
            * CFrame.Angles(math.rad(80), -ang, 0)
    elseif shape == "Wings" then
        local side      = (i % 2 == 0) and 1 or -1
        local idx       = math.floor((i - 1) / 2)
        local pairCount = math.ceil(n / 2)
        local t         = idx / math.max(1, pairCount)
        local back = -lookCF.LookVector * (1 + t * r)
        local up   = Vector3.new(0, t * r, 0)
        local out  = lookCF.RightVector * side * (1 + t * r * 0.7)
        return CFrame.new(center + back + up + out)
    else -- "Orbit" ring
        local ang = floatAngle + (i / n) * math.pi * 2
        return CFrame.new(center + Vector3.new(math.cos(ang), 0, math.sin(ang)) * r)
            * CFrame.Angles(0, -ang, 0)
    end
end

local function doFloatWeapons(dt)
    local hrp = getHRP(); if not hrp then return end
    floatAngle = floatAngle + dt * S.floatSpeed
    claimOwnership()   -- force network ownership so everyone sees the formation

    -- refresh the controlled item set a couple times per second
    floatRegather = floatRegather + dt
    if floatRegather >= 0.5 or next(floatParts) == nil then
        floatRegather = 0
        local picked, pickedSet = floatGather(), {}
        for _, p in ipairs(picked) do pickedSet[p] = true end
        for p in pairs(floatParts) do
            if not pickedSet[p] or not p.Parent then floatRelease(p) end
        end
        for _, p in ipairs(picked) do
            if floatParts[p] == nil then floatParts[p] = p.Anchored end
        end
    end

    -- deterministic ordering so each item keeps a stable slot
    local list = {}
    for p in pairs(floatParts) do
        if p.Parent then list[#list+1] = p else floatRelease(p) end
    end
    table.sort(list, function(a, b) return a:GetFullName() < b:GetFullName() end)

    local n = #list; if n == 0 then return end
    local center = hrp.Position + Vector3.new(0, 1, 0)
    local lookCF = hrp.CFrame
    for i, part in ipairs(list) do
        local cf = floatShapeCF(S.floatShape, i, n, center, lookCF)
        pcall(function()
            part.Anchored = false
            part.CanCollide = false
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
            part.CFrame = cf
        end)
    end
end

-- ── GUN KILL ─────────────────────────────────────────────────
-- While Float Weapons is spinning, radiates damage to every humanoid within
-- (floatRadius + gunKillRadius) studs. No teleport — pure proximity damage.
-- Players receive moderate repeated damage; zombies/NPCs are one-shot.
local function doGunKill()
    if not S.floatWeapons then return end
    local hrp = getHRP(); if not hrp then return end
    local pos      = hrp.Position
    local killRange = S.floatRadius + S.gunKillRadius

    -- Players in range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character; if not char then continue end
        local phrp = char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        if (pos - phrp.Position).Magnitude <= killRange then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                pcall(function() hum:TakeDamage(30) end)
            end
        end
    end

    -- Zombies folder
    local zombieFolder = WS:FindFirstChild("Zombies")
    if zombieFolder then
        for _, zombie in ipairs(zombieFolder:GetChildren()) do
            local zhrp = zombie:FindFirstChild("HumanoidRootPart")
                or zombie:FindFirstChildWhichIsA("BasePart")
            if not zhrp then continue end
            if (pos - zhrp.Position).Magnitude <= killRange then
                local hum = zombie:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    pcall(function() hum:TakeDamage(hum.MaxHealth + 1e9) end)
                    pcall(function() hum.Health = 0 end)
                end
            end
        end
    end

    -- WS-level NPCs/Ghosts/other characters
    for _, child in ipairs(WS:GetChildren()) do
        if Players:GetPlayerFromCharacter(child) then continue end
        if SYS[child.Name] then continue end
        local hum = child:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local root = child:FindFirstChild("HumanoidRootPart")
                or child:FindFirstChildWhichIsA("BasePart")
            if root and (pos - root.Position).Magnitude <= killRange then
                pcall(function() hum:TakeDamage(hum.MaxHealth + 1e9) end)
                pcall(function() hum.Health = 0 end)
            end
        end
    end
end

-- ── AUTO KILL ZOMBIES ────────────────────────────────────────
-- Robust: does NOT require an exactly-named HumanoidRootPart. Searches the whole
-- descendant tree for a Humanoid, applies every client-side kill method, zeroes any
-- "Health" value/attribute, disables the ZombieScript, and breaks + anchors the body
-- so it can no longer chase or attack. No high-velocity launch (would trip fling kick).
local function killOneZombie(zombie)
    -- find a Humanoid anywhere inside
    local zHum = zombie:FindFirstChildOfClass("Humanoid")
    if not zHum then
        for _, d in ipairs(zombie:GetDescendants()) do
            if d:IsA("Humanoid") then zHum = d; break end
        end
    end
    if zHum then
        pcall(function() zHum:TakeDamage(zHum.MaxHealth + 1e9) end)
        pcall(function() zHum.Health = 0 end)
        pcall(function() zHum.MaxHealth = 0 end)
        pcall(function() zHum.Health = 0 end)
        pcall(function() zHum:ChangeState(Enum.HumanoidStateType.Dead) end)
        pcall(function() zHum:SetStateEnabled(Enum.HumanoidStateType.Running, false) end)
    end
    -- zero any health-like Value/Attribute, disable behaviour scripts, and fire any
    -- damage-style event the ZombieScript exposes inside the model
    for _, d in ipairs(zombie:GetDescendants()) do
        local nm = d.Name:lower()
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and nm:find("health") then
            pcall(function() d.Value = 0 end)
        elseif d:IsA("Script") or d:IsA("LocalScript") then
            pcall(function() d.Disabled = true end)   -- stop its behaviour
        elseif d:IsA("RemoteEvent") and (nm:find("damage") or nm:find("hit") or nm:find("kill") or nm:find("die")) then
            pcall(function() d:FireServer(zHum, 1e9) end)
        elseif d:IsA("BindableEvent") and (nm:find("damage") or nm:find("hit") or nm:find("kill") or nm:find("die")) then
            pcall(function() d:Fire(zHum, 1e9) end)
        end
    end
    pcall(function() if zombie:GetAttribute("Health") ~= nil then zombie:SetAttribute("Health", 0) end end)
    -- break it apart and freeze every part so it cannot move/attack
    pcall(function() zombie:BreakJoints() end)
    for _, d in ipairs(zombie:GetDescendants()) do
        if d:IsA("BasePart") then
            pcall(function() d.Anchored = true; d.CanCollide = false end)
        end
    end
end

local function doAutoKillZombies()
    -- Primary: dedicated Zombies folder
    local zombieFolder = WS:FindFirstChild("Zombies")
    if zombieFolder then
        for _, zombie in ipairs(zombieFolder:GetChildren()) do
            local isZombie = zombie.Name == "Zombie"
                or zombie:FindFirstChild("ZombieScript")
                or zombie:FindFirstChildOfClass("Humanoid")
            if isZombie then pcall(killOneZombie, zombie) end
        end
    end
    -- Secondary: WS-level sweep for any stray models with a ZombieScript
    -- (catches zombies that spawn outside the Zombies folder)
    for _, child in ipairs(WS:GetChildren()) do
        if not SYS[child.Name] and not Players:GetPlayerFromCharacter(child) then
            if child:FindFirstChild("ZombieScript") or
               (child.Name=="Zombie" and child:FindFirstChildOfClass("Humanoid")) then
                pcall(killOneZombie, child)
            end
        end
    end
end

-- ── ALWAYS GET BUTTON ────────────────────────────────────────
local function doAlwaysGetButton()
    local mm  = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("MapModels")
    local btn = mm and mm:FindFirstChild("TheButton")
    local bp  = btn and (btn:FindFirstChild("Button") or btn)
    if not bp then return end
    local pp = bp:FindFirstChildOfClass("ProximityPrompt")
        or bp:FindFirstChild("ButtonPrompt")
        or bp:FindFirstChildWhichIsA("ProximityPrompt")
    if pp then
        pcall(function() pp.Enabled=true; pp.MaxActivationDistance=200; pp.HoldDuration=0 end)
        pcall(fireprompt, pp)
    end
end

-- ── AUTO REVIVE ──────────────────────────────────────────────
local function doAutoRevive()
    local downed = WS:FindFirstChild("DownedCharacters"); if not downed then return end
    local hrp = getHRP(); if not hrp then return end
    for _, d in ipairs(downed:GetChildren()) do
        local dRoot = d:FindFirstChildWhichIsA("BasePart"); if not dRoot then continue end
        safeTP(CFrame.new(dRoot.Position+Vector3.new(0,2,2)))
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

-- ── AUTO GRAB ────────────────────────────────────────────────
-- For Tools: force into Backpack directly.
-- For non-Tools: fire prompt from current position with huge MaxActivationDistance
-- (do NOT move the item — server validates against the item's server-side position,
--  so moving it client-side breaks the server's range check).
local function doAutoGrab()
    local hrp = getHRP(); if not hrp then return end
    for _, child in ipairs(WS:GetChildren()) do
        if not isItem(child) then continue end
        local root = itemRoot(child); if not root then continue end
        if (hrp.Position-root.Position).Magnitude > S.grabRadius then continue end
        if child:IsA("Tool") then
            pcall(function() child.Parent=LP.Backpack end)
        else
            -- Fire prompts and clicks from distance; server accepts because MaxActivationDistance=1000
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    pcall(function()
                        d.Enabled=true; d.MaxActivationDistance=1000
                        d.HoldDuration=0; d.RequiresLineOfSight=false
                    end)
                    pcall(fireprompt, d); pcall(fireprompt, d, 0)
                end
                if d:IsA("ClickDetector") then
                    pcall(function() d.MaxActivationDistance=1000 end)
                    pcall(fireclick, d)
                end
            end
        end
    end
end

-- ── AUTO ITEM (TP to each item → pick up → TP back) ─────────
local autoItemRunning = false

local function doAutoItemCycle()
    if autoItemRunning then return end
    autoItemRunning = true
    local hrp = getHRP(); if not hrp then autoItemRunning=false; return end
    local savedCF = hrp.CFrame

    local items = {}
    for _, child in ipairs(WS:GetChildren()) do
        if isItem(child) then items[#items+1]=child end
    end

    for _, item in ipairs(items) do
        if not S.autoItem or not item.Parent then continue end
        local root = itemRoot(item); if not root then continue end
        local hrp2 = getHRP(); if not hrp2 then break end
        safeTP(CFrame.new(root.Position+Vector3.new(0,3,0)))
        task.wait(0.35)
        if item:IsA("Tool") then pcall(function() item.Parent=LP.Backpack end) end
        for _, d in ipairs(item:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function() d.Enabled=true; d.HoldDuration=0; d.MaxActivationDistance=50; d.RequiresLineOfSight=false end)
                pcall(fireprompt, d); pcall(fireprompt, d, 0)
            end
            if d:IsA("ClickDetector") then
                pcall(function() d.MaxActivationDistance=50 end)
                pcall(fireclick, d)
            end
        end
        task.wait(0.35)
    end

    local hrp3 = getHRP()
    if hrp3 and savedCF then pcall(function() hrp3.CFrame=savedCF end) end
    task.wait(1.5)   -- cooldown: prevents accelerating spiral
    autoItemRunning = false
end

-- ── AUTO CARRY / CARRY KILL ──────────────────────────────────
local function findCarryPrompt(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = (d.ActionText or ""):lower()
            if at:find("carry") or d.KeyboardKeyCode==Enum.KeyCode.Q then return d end
        end
    end
    return model:FindFirstChildOfClass("ProximityPrompt", true)
end

local function findCarryTarget()
    local downed = WS:FindFirstChild("DownedCharacters")
    if downed then
        for _, d in ipairs(downed:GetChildren()) do
            local r = d:FindFirstChildWhichIsA("BasePart")
            if r then return d, r end
        end
    end
    local _, bestHRP = findNearest()
    if bestHRP then
        local char = bestHRP.Parent
        if char then return char, bestHRP end
    end
    return nil, nil
end

local function doAutoCarry()
    local target, root = findCarryTarget(); if not target or not root then return end
    local hrp = getHRP(); if not hrp then return end
    -- TP very close (within 2 studs)
    safeTP(CFrame.new(root.Position+Vector3.new(0,2,1.5)))
    task.wait(0.08)
    local pp = findCarryPrompt(target)
    if pp then
        pcall(function() pp.Enabled=true; pp.MaxActivationDistance=20; pp.HoldDuration=0; pp.RequiresLineOfSight=false end)
        pcall(fireprompt, pp); pcall(fireprompt, pp, 0)
    end
end

local carryKillRunning = false

local function doCarryKill()
    if carryKillRunning then return end
    carryKillRunning = true

    local target, root = findCarryTarget()
    local hrp = getHRP()
    if not hrp then carryKillRunning=false; return end

    -- Step 1: TP near target and carry them (Q) — safeTP avoids the kick
    if root then
        safeTP(CFrame.new(root.Position+Vector3.new(0,2,1.5)))
        task.wait(0.15)
    end
    if target then
        local pp = findCarryPrompt(target)
        if pp then
            pcall(function() pp.Enabled=true; pp.MaxActivationDistance=20; pp.HoldDuration=0; pp.RequiresLineOfSight=false end)
            pcall(fireprompt, pp); pcall(fireprompt, pp, 0)
        end
    end

    -- Step 2: Wait for carry to register server-side
    task.wait(0.7)

    -- Step 3: Save position and hop out of the map (they come with us)
    local savedCF = getHRP() and getHRP().CFrame
    safeTP(CFrame.new(OUTOFMAP))

    -- Step 4: Wait for target to die from fall / out-of-bounds
    task.wait(3.5)

    -- Step 5: hop back
    if savedCF then safeTP(savedCF) end
    task.wait(0.5)
    carryKillRunning = false
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
    if bpos then safeTP(CFrame.new(bpos+Vector3.new(0,3,0))) end
end

-- ── ANTI CARRY ───────────────────────────────────────────────
-- Disables carry (Q) prompts on our own character so others can't pick us up.
local function doAntiCarry()
    local char = LP.Character; if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = (d.ActionText or ""):lower()
            if at:find("carry") or d.KeyboardKeyCode==Enum.KeyCode.Q then
                pcall(function() d.Enabled=false end)
            end
        end
    end
    -- Also disable carry prompt if we appear in DownedCharacters
    local downed = WS:FindFirstChild("DownedCharacters")
    if downed then
        for _, d in ipairs(downed:GetChildren()) do
            if d.Name==LP.Name then
                for _, pp in ipairs(d:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then
                        local at = (pp.ActionText or ""):lower()
                        if at:find("carry") or pp.KeyboardKeyCode==Enum.KeyCode.Q then
                            pcall(function() pp.Enabled=false end)
                        end
                    end
                end
            end
        end
    end
end

-- ── AUTO PROJECTS ────────────────────────────────────────────
-- Tries every known event type on "Evacuate" by name, then does a broad sweep
-- of all descendants so it works even if the event was renamed or nested deeper.
local function fireProjectEvacuate(projName)
    local proj = WS:FindFirstChild(projName); if not proj then return end
    -- named Evacuate first (fast path)
    local ev = proj:FindFirstChild("Evacuate")
    if ev then
        if ev:IsA("BindableEvent")   then pcall(function() ev:Fire() end) end
        if ev:IsA("RemoteEvent")     then pcall(function() ev:FireServer() end) end
        if ev:IsA("RemoteFunction")  then pcall(function() ev:InvokeServer() end) end
        if ev:IsA("BindableFunction") then pcall(function() ev:Invoke() end) end
    end
    -- broad sweep: fire all remote/bindable events in the folder
    for _, child in ipairs(proj:GetDescendants()) do
        if child:IsA("RemoteEvent")      then pcall(function() child:FireServer() end)
        elseif child:IsA("BindableEvent") then pcall(function() child:Fire() end)
        elseif child:IsA("RemoteFunction") then pcall(function() child:InvokeServer() end)
        elseif child:IsA("BindableFunction") then pcall(function() child:Invoke() end)
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
                pcall(function() g.Visible=not on end)
            end
        end
    end
end

-- ── ANTI PUSH ────────────────────────────────────────────────
-- Only cancels velocity when an external force spikes it above normal walking range.
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
-- Keep Y at 2 (original height) to prevent sinking into the ground.
local function doHitboxExpander()
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(function() hrp.Size=Vector3.new(S.hitboxSize, 2, S.hitboxSize) end)
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
            local hp   = hum and hum.Health or 0
            local mxhp = hum and hum.MaxHealth or 100
            local pct  = mxhp>0 and (hp/mxhp) or 1
            local dist = (myHRP and phrp) and math.round((myHRP.Position-phrp.Position).Magnitude) or 0
            getOrMakeESP(char, Color3.fromRGB(255,90,90))
            updateESP(char, plr.Name.." ["..dist.."m]", pct, mxhp)
        elseif espData[char] then removeESP(char) end
    end

    local ghostFolder = WS:FindFirstChild("Ghosts")
    if ghostFolder then
        for _, ghost in ipairs(ghostFolder:GetChildren()) do
            if S.ghostESP then
                local hum  = ghost:FindFirstChildOfClass("Humanoid")
                local ghrp = ghost:FindFirstChildWhichIsA("BasePart")
                local hp   = hum and hum.Health or 0
                local mxhp = hum and hum.MaxHealth or 100
                local pct  = mxhp>0 and (hp/mxhp) or 1
                local dist = (myHRP and ghrp) and math.round((myHRP.Position-ghrp.Position).Magnitude) or 0
                getOrMakeESP(ghost, Color3.fromRGB(200,110,255))
                updateESP(ghost, "GHOST:"..ghost.Name.." ["..dist.."m]", pct, mxhp)
            elseif espData[ghost] then removeESP(ghost) end
        end
    end

    -- Mine ESP: uses pre-built cache, only renders within 80 studs to avoid lag
    for _, mine in ipairs(mineCache) do
        if not mine.Parent then continue end
        if S.mineESP then
            local mpos = mine:IsA("BasePart") and mine.Position
                or (mine:FindFirstChildWhichIsA("BasePart") and mine:FindFirstChildWhichIsA("BasePart").Position)
            if not mpos then continue end
            local dist = myHRP and math.round((myHRP.Position-mpos).Magnitude) or 0
            if dist > 80 then
                if espData[mine] then removeESP(mine) end
                continue
            end
            getOrMakeESP(mine, Color3.fromRGB(255,180,0))
            updateESP(mine, "MINE ["..dist.."m]", 1)
        elseif espData[mine] then removeESP(mine) end
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

LOOPS.heartbeat = RunService.Heartbeat:Connect(function(dt)
    if S.floatWeapons then doFloatWeapons(dt) end
    if S.infStam then doInfStam() end
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
        if hum and hum.WalkSpeed<exp then pcall(function() hum.WalkSpeed=exp end) end
    end
    if S.antiPush  then doAntiPush() end
    -- Anti Kick: clamp our own velocity so a fling (by others, or a physics spike
    -- after a teleport) never reaches the magnitude the anti-cheat kicks for.
    if S.antiKick then
        local hrp = getHRP()
        if hrp then
            pcall(function()
                local v = hrp.AssemblyLinearVelocity
                local ny = v.Y
                if ny > 90 then ny = 90 end          -- cap upward launch (above a jump)
                local horiz = Vector3.new(v.X, 0, v.Z)
                local hcap = math.max(S.speed + 80, 160)
                if horiz.Magnitude > hcap then
                    local c = horiz.Unit * hcap
                    hrp.AssemblyLinearVelocity = Vector3.new(c.X, ny, c.Z)
                elseif ny ~= v.Y then
                    hrp.AssemblyLinearVelocity = Vector3.new(v.X, ny, v.Z)
                end
            end)
        end
    end
    if S.noDark    then applyNoDark(true) end
    if S.hitboxExp then doHitboxExpander() end
    -- NoClip: keep all character parts non-collidable every frame
    if S.noclip then
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
            end
        end
    end
end)

local grabTimer     = 0
local espTimer      = 0
local combatTimer   = 0
local miscTimer     = 0
local zombieTimer   = 0
local projectTimer  = 0
local gunKillTimer  = 0

LOOPS.stepped = RunService.Stepped:Connect(function(_, dt)
    grabTimer    = grabTimer    + dt
    espTimer     = espTimer     + dt
    combatTimer  = combatTimer  + dt
    miscTimer    = miscTimer    + dt
    zombieTimer  = zombieTimer  + dt
    projectTimer = projectTimer + dt
    gunKillTimer = gunKillTimer + dt

    if grabTimer >= 0.12 then
        grabTimer = 0
        if S.autoGrab  then doAutoGrab() end
        if S.killAura  then doKillAura() end
        if S.autoAttack then
            local _, tHRP = findNearest(S.killAuraRadius*2)
            if tHRP then
                if getHRP() then safeTP(CFrame.new(tHRP.Position+Vector3.new(0,2,3))) end
                local tHum = tHRP.Parent and tHRP.Parent:FindFirstChildOfClass("Humanoid")
                if tHum then pcall(function() tHum:TakeDamage(1e9) end) end
            end
        end
    end

    if espTimer >= 0.25 then
        espTimer = 0
        runESP()
    end

    if combatTimer >= 0.3 then
        combatTimer = 0
        if S.fling then doFling() end
    end

    if zombieTimer >= 0.1 then
        zombieTimer = 0
        if S.autoKillZombies then doAutoKillZombies() end
    end

    if gunKillTimer >= 0.12 then
        gunKillTimer = 0
        if S.gunKill then doGunKill() end
    end

    if miscTimer >= 0.4 then
        miscTimer = 0
        if S.autoOpenDoors   then doAutoOpenDoors() end
        if S.antiCarry       then doAntiCarry() end
        if S.stayKingCircle  then doStayKingCircle() end
        if S.alwaysGetButton then doAlwaysGetButton() end
        if S.autoRevive or S.autoFarm then doAutoRevive() end
        if S.autoFarm        then doAutoGrab() end
        if S.autoCarry       then doAutoCarry() end
        if S.carryKill       then doCarryKill() end
    end

    if projectTimer >= 0.5 then
        projectTimer = 0
        if S.autoAlpha then fireProjectEvacuate("Project Alpha") end
        if S.autoBeta  then fireProjectEvacuate("Project Beta") end
        if S.autoDelta then fireProjectEvacuate("Project Delta") end
    end
end)

-- Auto Item runs in its own task (rate-limited internally by autoItemRunning flag)
task.spawn(function()
    while true do
        task.wait(0.1)
        if S.autoItem then task.spawn(doAutoItemCycle) end
    end
end)

-- ── F6 PANIC ─────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.F6 then
        for _, c in pairs(LOOPS) do pcall(function() c:Disconnect() end) end
        clearAllESP()
        floatReleaseAll()
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
    Name             = "Wallace Chaos Hub  |  PAID",
    LoadingTitle     = "Wallace Chaos Hub",
    LoadingSubtitle  = "Black / Purple Edition — All Features",
    Theme = {
        TextColor                    = Color3.fromRGB(235,235,235),
        Background                   = Color3.fromRGB(8,8,12),
        Topbar                       = Color3.fromRGB(18,8,30),
        Shadow                       = Color3.fromRGB(0,0,0),
        NotificationBackground       = Color3.fromRGB(14,8,22),
        NotificationActionsBackground= Color3.fromRGB(40,10,70),
        TabBackground                = Color3.fromRGB(20,8,38),
        TabStroke                    = Color3.fromRGB(150,0,230),
        TabBackgroundSelected        = Color3.fromRGB(110,0,185),
        TabTextColor                 = Color3.fromRGB(205,180,230),
        SelectedTabTextColor         = Color3.fromRGB(255,255,255),
        ElementBackground            = Color3.fromRGB(16,8,28),
        ElementBackgroundHover       = Color3.fromRGB(40,10,72),
        SecondaryElementBackground   = Color3.fromRGB(12,6,22),
        ElementStroke                = Color3.fromRGB(75,15,135),
        SecondaryElementStroke       = Color3.fromRGB(130,0,210),
        SliderBackground             = Color3.fromRGB(90,0,160),
        SliderProgress               = Color3.fromRGB(165,0,255),
        SliderStroke                 = Color3.fromRGB(185,70,255),
        ToggleBackground             = Color3.fromRGB(28,8,52),
        ToggleEnabled                = Color3.fromRGB(155,0,240),
        ToggleDisabled               = Color3.fromRGB(38,18,58),
        ToggleEnabledStroke          = Color3.fromRGB(210,90,255),
        ToggleDisabledStroke         = Color3.fromRGB(65,28,100),
        ToggleEnabledOuterStroke     = Color3.fromRGB(120,0,210),
        ToggleDisabledOuterStroke    = Color3.fromRGB(48,18,85),
        DropdownSelected             = Color3.fromRGB(110,0,185),
        DropdownUnselected           = Color3.fromRGB(20,8,38),
        InputBackground              = Color3.fromRGB(14,6,26),
        InputStroke                  = Color3.fromRGB(140,0,220),
        PlaceholderColor             = Color3.fromRGB(160,130,195),
    },
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled=true, FolderName="WallaceChaos_PAID", FileName="Config" },
    KeySystem              = false,
})

-- ESP Tab
local TabESP = Window:CreateTab("ESP", 4483362458)

TabESP:CreateToggle({
    Name="Player ESP", CurrentValue=false, Flag="playerESP",
    Callback=function(v)
        S.playerESP=v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr~=LP and plr.Character then removeESP(plr.Character) end
            end
        end
    end,
})
TabESP:CreateToggle({
    Name="Ghost ESP", CurrentValue=false, Flag="ghostESP",
    Callback=function(v)
        S.ghostESP=v
        if not v then
            local gf = WS:FindFirstChild("Ghosts")
            if gf then for _, g in ipairs(gf:GetChildren()) do removeESP(g) end end
        end
    end,
})
TabESP:CreateToggle({
    Name="Mine ESP", CurrentValue=false, Flag="mineESP",
    Callback=function(v)
        S.mineESP=v
        if not v then
            local mf = WS:FindFirstChild("Minefield")
            if mf then for _, m in ipairs(mf:GetDescendants()) do removeESP(m) end end
        end
    end,
})
TabESP:CreateToggle({
    Name="Item ESP", CurrentValue=false, Flag="itemESP",
    Callback=function(v)
        S.itemESP=v
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
        S.speedHack=v
        if not v and not S.autoSprint then
            local hum=getHum(); if hum then pcall(function() hum.WalkSpeed=16 end) end
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
        S.autoSprint=v
        if not v and not S.speedHack then
            local hum=getHum(); if hum then pcall(function() hum.WalkSpeed=16 end) end
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
TabMove:CreateToggle({
    Name="Anti Kick (Fling Detection Bypass)", CurrentValue=true, Flag="antiKick",
    Callback=function(v) S.antiKick=v end,
})
TabMove:CreateButton({
    Name="Fling Nearest",
    Description="Launches the nearest player into the sky",
    Callback=function() doFling() end,
})
TabMove:CreateToggle({
    Name="Auto Fling", CurrentValue=false, Flag="fling",
    Callback=function(v) S.fling=v end,
})

-- Combat Tab
local TabCombat = Window:CreateTab("Combat", 4483362458)

TabCombat:CreateToggle({
    Name="Kill Aura", CurrentValue=false, Flag="killAura",
    Callback=function(v) S.killAura=v end,
})
TabCombat:CreateSlider({
    Name="Kill Aura Radius", Range={5,100}, Increment=1, Suffix="studs",
    CurrentValue=20, Flag="killAuraRadius",
    Callback=function(v) S.killAuraRadius=v end,
})
TabCombat:CreateToggle({
    Name="Auto Attack", CurrentValue=false, Flag="autoAttack",
    Callback=function(v) S.autoAttack=v end,
})
TabCombat:CreateToggle({
    Name="Auto Kill Zombies", CurrentValue=false, Flag="autoKillZombies",
    Callback=function(v) S.autoKillZombies=v end,
})

-- Fun Tab
local TabFun = Window:CreateTab("Fun", 4483362458)

TabFun:CreateParagraph({
    Title   = "Float Weapons",
    Content = "Pulls nearby items and floats them around you in a shape. EVERYONE can see it: the script maxes your simulation radius to claim network ownership of the parts, so their positions replicate to the whole server. Try the 'Stand' shape for a JoJo-style figure that hovers behind you.",
})
TabFun:CreateToggle({
    Name="Float Weapons", CurrentValue=false, Flag="floatWeapons",
    Callback=function(v)
        S.floatWeapons=v
        if v then claimOwnership() else floatReleaseAll() end
    end,
})
TabFun:CreateDropdown({
    Name="Shape",
    Options={"Orbit","Ball","Cube","Spiral","Sword","Halo","Wings","Stand"},
    CurrentOption={"Orbit"},
    Flag="floatShape",
    Callback=function(opt)
        S.floatShape = (type(opt)=="table") and opt[1] or opt
    end,
})
TabFun:CreateSlider({
    Name="Float Radius", Range={3,30}, Increment=1, Suffix="studs",
    CurrentValue=8, Flag="floatRadius",
    Callback=function(v) S.floatRadius=v end,
})
TabFun:CreateSlider({
    Name="Spin Speed", Range={0,10}, Increment=1, Suffix="x",
    CurrentValue=2, Flag="floatSpeed",
    Callback=function(v) S.floatSpeed=v end,
})
TabFun:CreateSlider({
    Name="Max Items", Range={4,60}, Increment=1, Suffix="items",
    CurrentValue=24, Flag="floatMax",
    Callback=function(v) S.floatMax=v end,
})
TabFun:CreateParagraph({
    Title   = "Gun Kill",
    Content = "While Float Weapons is spinning, damages every player, zombie, and NPC inside the orbit radius. Players take 30 damage per hit; zombies/NPCs are one-shot. Only active when Float Weapons is ON.",
})
TabFun:CreateToggle({
    Name="Gun Kill (Damages nearby while spinning)", CurrentValue=false, Flag="gunKill",
    Callback=function(v) S.gunKill=v end,
})
TabFun:CreateSlider({
    Name="Gun Kill Extra Radius", Range={0,40}, Increment=1, Suffix="studs",
    CurrentValue=15, Flag="gunKillRadius",
    Callback=function(v) S.gunKillRadius=v end,
})

-- Survival Tab
local TabSurv = Window:CreateTab("Survival", 4483362458)

TabSurv:CreateToggle({
    Name="God Mode", CurrentValue=false, Flag="godMode",
    Callback=function(v) S.godMode=v; setupGodMode() end,
})
TabSurv:CreateToggle({
    Name="Inf Stamina", CurrentValue=false, Flag="infStam",
    Callback=function(v) S.infStam=v end,
})
TabSurv:CreateToggle({
    Name="No Stun", CurrentValue=false, Flag="noStun",
    Callback=function(v) S.noStun=v; if v then connectNoStun() end end,
})
TabSurv:CreateToggle({
    Name="Anti Carry (Block Others Picking You Up)", CurrentValue=false, Flag="antiCarry",
    Callback=function(v) S.antiCarry=v end,
})
TabSurv:CreateToggle({
    Name="No Dark", CurrentValue=false, Flag="noDark",
    Callback=function(v) S.noDark=v; if not v then applyNoDark(false) end end,
})
TabSurv:CreateToggle({
    Name="Hitbox Expander", CurrentValue=false, Flag="hitboxExp",
    Callback=function(v)
        S.hitboxExp=v
        if not v then
            local char=LP.Character
            if char then
                local hrp=char:FindFirstChild("HumanoidRootPart")
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
    Name="NoClip (Walk Through Walls)", CurrentValue=false, Flag="noclip",
    Callback=function(v)
        S.noclip=v
        if not v then
            local char=LP.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end
                end
            end
        end
    end,
})
TabAuto:CreateToggle({
    Name="Stay in King Circle", CurrentValue=false, Flag="stayKingCircle",
    Callback=function(v) S.stayKingCircle=v end,
})
TabAuto:CreateToggle({
    Name="Always Get Button", CurrentValue=false, Flag="alwaysGetButton",
    Callback=function(v) S.alwaysGetButton=v end,
})
TabAuto:CreateToggle({
    Name="Auto Grab Items", CurrentValue=false, Flag="autoGrab",
    Callback=function(v) S.autoGrab=v end,
})
TabAuto:CreateSlider({
    Name="Grab Radius", Range={10,300}, Increment=5, Suffix="studs",
    CurrentValue=50, Flag="grabRadius",
    Callback=function(v) S.grabRadius=v end,
})
TabAuto:CreateToggle({
    Name="Auto Item (TP to each item)", CurrentValue=false, Flag="autoItem",
    Callback=function(v) S.autoItem=v end,
})
TabAuto:CreateToggle({
    Name="Auto Revive", CurrentValue=false, Flag="autoRevive",
    Callback=function(v) S.autoRevive=v end,
})
TabAuto:CreateToggle({
    Name="Auto Carry [Q]", CurrentValue=false, Flag="autoCarry",
    Callback=function(v) S.autoCarry=v end,
})
TabAuto:CreateToggle({
    Name="Carry Kill (Outside Map)", CurrentValue=false, Flag="carryKill",
    Callback=function(v) S.carryKill=v end,
})
TabAuto:CreateToggle({
    Name="Auto Farm (Revive + Grab)", CurrentValue=false, Flag="autoFarm",
    Callback=function(v) S.autoFarm=v end,
})

-- Projects Tab
local TabProj = Window:CreateTab("Projects", 4483362458)

TabProj:CreateToggle({
    Name="Auto Project Alpha", CurrentValue=false, Flag="autoAlpha",
    Callback=function(v) S.autoAlpha=v end,
})
TabProj:CreateToggle({
    Name="Auto Project Beta", CurrentValue=false, Flag="autoBeta",
    Callback=function(v) S.autoBeta=v end,
})
TabProj:CreateToggle({
    Name="Auto Project Delta", CurrentValue=false, Flag="autoDelta",
    Callback=function(v) S.autoDelta=v end,
})
TabProj:CreateButton({
    Name="Fire Alpha Now", Description="Instantly fires Project Alpha evacuate",
    Callback=function() fireProjectEvacuate("Project Alpha") end,
})
TabProj:CreateButton({
    Name="Fire Beta Now", Description="Instantly fires Project Beta evacuate",
    Callback=function() fireProjectEvacuate("Project Beta") end,
})
TabProj:CreateButton({
    Name="Fire Delta Now", Description="Instantly fires Project Delta evacuate",
    Callback=function() fireProjectEvacuate("Project Delta") end,
})

-- Info Tab
local TabInfo = Window:CreateTab("Info", 4483362458)
TabInfo:CreateParagraph({
    Title   = "The Button  |  PAID Edition",
    Content = "F6 = Panic / kill script.\n\nAuto Item: TPs to each item one-by-one, picks it up (E), TPs back. 1.5s cooldown.\nAuto Carry: TPs close, fires Q.\nCarry Kill: Carries target → TPs outside map → waits for death → TPs back.\nAuto Grab: Items fly to you — you stay still.",
})

-- ── INIT ─────────────────────────────────────────────────────
task.wait(1)
connectNoStun()
if S.godMode then setupGodMode() end
Rayfield:LoadConfiguration()
