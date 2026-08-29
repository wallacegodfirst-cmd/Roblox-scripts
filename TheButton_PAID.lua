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

local fireprompt  = (typeof(fireproximityprompt)=="function") and fireproximityprompt or function() end
local fireclick   = (typeof(fireclickdetector)=="function")  and fireclickdetector  or function() end
local sethidden   = (typeof(sethiddenproperty)=="function") and sethiddenproperty or nil
local firetouchif = (typeof(firetouchinterest)=="function") and firetouchinterest or nil

-- Void position: straight down into the kill plane. Much closer than (9999,200,9999)
-- which was ~14000 studs away and caused 940+ safeTP hops → Error 267.
local OUTOFMAP = Vector3.new(0, -600, 0)

-- ── SAFE TELEPORT (anti-kick) ────────────────────────────────
-- Many anti-cheats kick on a single large position jump per frame ("teleport"
-- detection) or on high velocity ("fling" detection). safeTP moves in small
-- hops (<= MAX_HOP studs) across consecutive frames so no single step looks
-- suspicious, and zeroes velocity each hop so it never reads as a fling.
local MAX_HOP = 15   -- ≤15 studs/frame → ~900 studs/s; 50 was 3000 studs/s which tripped Error 267
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
    infFood        = false,
    noStun         = false,
    noDark         = false,

    autoAttack     = false,
    fling          = false,

    autoKillZombies = false,

    autoOpenDoors   = false,
    noclip          = false,
    antiCarry       = false,
    stayKingCircle  = false,
    autoRevive     = false,
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

-- Mine cache: built once, updated on ChildAdded/Removed.
-- Uses task.spawn + retry because Minefield children may load AFTER this script runs.
local mineCache = {}
task.spawn(function()
    -- Wait up to 60 s for Minefield to appear
    local mf
    local t0 = tick()
    while not mf and tick()-t0 < 60 do
        mf = WS:FindFirstChild("Minefield")
        if not mf then task.wait(1) end
    end
    if not mf then return end
    task.wait(2)   -- extra wait for LandmineSpawner to populate children
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
    bb.StudsOffset=Vector3.new(0,6.5,0)
    -- BillboardGui must have an Adornee BasePart or it defaults to world origin (0,0,0).
    -- For Models without PrimaryPart (e.g. Landmine) we find the nearest BasePart manually.
    local adornee = obj:IsA("BasePart") and obj
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")
    if adornee then bb.Adornee = adornee end
    bb.Parent = obj

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
    local function maxVal(desc)
        pcall(function() desc.Value = 1e6 end)
    end
    local function scanValues(root)
        if not root then return end
        for _, desc in ipairs(root:GetDescendants()) do
            local nm = desc.Name:lower()
            if (desc:IsA("NumberValue") or desc:IsA("IntValue")) and
               (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then
                maxVal(desc)
            end
        end
    end
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
                maxVal(desc)
            end
        end
    end
    local char = LP.Character
    if char then
        for _, desc in ipairs(char:GetDescendants()) do
            local nm = desc.Name:lower()
            if desc:IsA("LocalScript") and (nm:find("stam") or nm:find("sprint") or nm:find("energy")) then
                pcall(function() desc.Disabled=true end)
            end
            if (desc:IsA("NumberValue") or desc:IsA("IntValue")) and
               (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then
                maxVal(desc)
            end
        end
        -- Attributes (some games store stamina as a character attribute)
        for k, v in pairs(char:GetAttributes()) do
            local nm = k:lower()
            if type(v) == "number" and (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then
                pcall(function() char:SetAttribute(k, 1e6) end)
            end
        end
    end
    -- PlayerData / Values / Stats folders on the player
    scanValues(LP:FindFirstChild("PlayerData"))
    scanValues(LP:FindFirstChild("Values"))
    scanValues(LP:FindFirstChild("Stats"))
    scanValues(LP:FindFirstChild("leaderstats"))
    -- Force sprint speed so you can always run regardless of other toggles
    local hum = getHum()
    if hum then pcall(function()
        local spd = S.speedHack and S.speed or 24
        if hum.WalkSpeed < spd then hum.WalkSpeed = spd end
    end) end
end

-- ── INF FOOD (keep hunger / food bar full) ───────────────────
local FOOD_KEYS = {"food","hunger","saturation","calories","fed","starve","eat","nourish","fill"}

local function doInfFood()
    local function maxFood(desc)
        pcall(function()
            local mx = rawget(desc,"MaxValue") or desc.Value or 100
            if type(mx)~="number" or mx<=0 then mx=100 end
            desc.Value = mx
        end)
    end
    local function scanForFood(root)
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            local nm = d.Name:lower()
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                for _, k in ipairs(FOOD_KEYS) do
                    if nm:find(k) then maxFood(d); break end
                end
            end
            if d:IsA("LocalScript") then
                for _, k in ipairs(FOOD_KEYS) do
                    if nm:find(k) then pcall(function() d.Disabled=true end); break end
                end
            end
            if d:IsA("Frame") then
                for _, k in ipairs(FOOD_KEYS) do
                    if nm:find(k) then
                        pcall(function() d.Size=UDim2.new(1,0,d.Size.Y.Scale,0) end)
                        break
                    end
                end
            end
        end
    end
    local char = LP.Character
    if char then
        for k, v in pairs(char:GetAttributes()) do
            local nm = k:lower()
            if type(v)=="number" then
                for _, fk in ipairs(FOOD_KEYS) do
                    if nm:find(fk) then
                        pcall(function() char:SetAttribute(k, math.max(v, 100)) end)
                        break
                    end
                end
            end
        end
        scanForFood(char)
    end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then scanForFood(pg) end
    scanForFood(LP:FindFirstChild("PlayerData"))
    scanForFood(LP:FindFirstChild("Values"))
    scanForFood(LP:FindFirstChild("Stats"))
    scanForFood(LP:FindFirstChild("leaderstats"))
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

-- ── ZOMBIE / NPC KILL ────────────────────────────────────────
-- In FilteringEnabled, client-side Health=0 / BreakJoints() / Anchored=true do NOT
-- replicate: the zombie only "dies" on YOUR screen while everyone else still sees it
-- alive and attacking (this is exactly the "I can't see them but others can, and it's
-- not dying" bug). The only operations that actually replicate are:
--   (A) firing the game's own damage RemoteEvents (inside the zombie + ReplicatedStorage)
--   (B) the game's touch-damage, triggered via firetouchinterest
--   (C) physics on parts we hold network ownership of (drop it into the void)
-- so killOneZombie does all three and skips the misleading client-only destruction.

-- Cached list of likely combat RemoteEvents in ReplicatedStorage (rebuilt every 5s).
local _combatRemotes, _combatRemotesAt = nil, 0
local function getCombatRemotes()
    if _combatRemotes and (tick() - _combatRemotesAt) < 5 then return _combatRemotes end
    _combatRemotes = {}
    local ok, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
    if ok and rs then
        for _, d in ipairs(rs:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                local nm = d.Name:lower()
                if nm:find("damage") or nm:find("hit") or nm:find("kill")
                or nm:find("attack") or nm:find("zombie") or nm:find("combat") or nm:find("hurt") then
                    _combatRemotes[#_combatRemotes+1] = d
                end
            end
        end
    end
    _combatRemotesAt = tick()
    return _combatRemotes
end

local function killOneZombie(zombie)
    local zHum = zombie:FindFirstChildOfClass("Humanoid")
    if not zHum then
        for _, d in ipairs(zombie:GetDescendants()) do
            if d:IsA("Humanoid") then zHum = d; break end
        end
    end
    local zRoot = zombie:FindFirstChild("HumanoidRootPart")
        or (zHum and zHum.RootPart)
        or zombie:FindFirstChildWhichIsA("BasePart")

    -- (A1) local TakeDamage — only works in non-strict FE, but free to try
    if zHum then pcall(function() zHum:TakeDamage(zHum.MaxHealth + 1e9) end) end

    -- (A2) fire the zombie's own internal damage events with several arg shapes
    local function fireDmg(ev)
        pcall(function() ev:FireServer() end)
        pcall(function() ev:FireServer(zHum) end)
        pcall(function() ev:FireServer(zHum, math.huge) end)
        pcall(function() ev:FireServer(zombie) end)
        pcall(function() ev:FireServer(zRoot) end)
        pcall(function() ev:FireServer(LP) end)
        pcall(function() ev:FireServer(LP.Character) end)
    end
    for _, d in ipairs(zombie:GetDescendants()) do
        local nm = d.Name:lower()
        if d:IsA("RemoteEvent") and (nm:find("damage") or nm:find("hit") or nm:find("kill") or nm:find("die") or nm:find("attack")) then
            fireDmg(d)
        elseif d:IsA("BindableEvent") and (nm:find("damage") or nm:find("hit") or nm:find("kill") or nm:find("die")) then
            pcall(function() d:Fire(zHum, math.huge) end)
            pcall(function() d:Fire() end)
        end
    end
    -- fire cached ReplicatedStorage combat remotes
    for _, ev in ipairs(getCombatRemotes()) do fireDmg(ev) end

    -- (B) firetouchinterest — BOTH directions because the game may listen on either end:
    --   • firetouchif(zombiePart, charPart, 0) → fires zombiePart.Touched with charPart as toucher
    --     (handles ZombieScripts that detect being hit by a character/weapon)
    --   • firetouchif(charPart, zombiePart, 0) → fires charPart.Touched with zombiePart as toucher
    --     (handles weapon scripts that deal damage when touching an enemy)
    if firetouchif then
        local char = LP.Character
        -- collect our character's parts: HRP + any equipped weapon parts
        local charParts = {}
        if char then
            local myHRP = char:FindFirstChild("HumanoidRootPart")
            if myHRP then charParts[#charParts+1] = myHRP end
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                for _, tp in ipairs(tool:GetDescendants()) do
                    if tp:IsA("BasePart") then charParts[#charParts+1] = tp end
                end
            end
            -- also add other limb parts so touch-based damage covering "any body part" fires
            for _, bp in ipairs(char:GetChildren()) do
                if bp:IsA("BasePart") and bp.Name ~= "HumanoidRootPart" then
                    charParts[#charParts+1] = bp
                    if #charParts >= 6 then break end
                end
            end
        end
        -- collect zombie's BaseParts (cap at 4)
        local zombieParts = {}
        if zRoot then zombieParts[1] = zRoot end
        for _, d in ipairs(zombie:GetDescendants()) do
            if d:IsA("BasePart") and #zombieParts < 4 then
                zombieParts[#zombieParts+1] = d
            end
        end
        -- fire every combination, both directions
        for _, cp in ipairs(charParts) do
            for _, zp in ipairs(zombieParts) do
                pcall(function() firetouchif(zp, cp, 0) end)  -- zombie detects us
                pcall(function() firetouchif(cp, zp, 0) end)  -- we detect zombie
            end
        end
    end

    -- zero health values (harmless if FE; effective if game reads them)
    for _, d in ipairs(zombie:GetDescendants()) do
        local nm = d.Name:lower()
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and nm:find("health") then
            pcall(function() d.Value = 0 end)
        end
    end
    pcall(function() if zombie:GetAttribute("Health") ~= nil then zombie:SetAttribute("Health", 0) end end)
end

-- ── AUTO KILL ZOMBIES ────────────────────────────────────────
-- killOneZombie is defined further up (before Gun Kill, which also calls it).
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

-- ── AUTO REVIVE ──────────────────────────────────────────────
local autoReviveRunning = false
local function doAutoRevive()
    if autoReviveRunning then return end
    autoReviveRunning = true
    local downed = WS:FindFirstChild("DownedCharacters")
    if not downed then autoReviveRunning=false; return end
    local hrp = getHRP(); if not hrp then autoReviveRunning=false; return end
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
    autoReviveRunning = false
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

-- Fires every carry/drop prompt we can find so a currently-carried player is RELEASED.
-- After you carry someone the drop prompt usually moves onto your own character, but
-- some games keep it on the victim — so we fire both, plus any Q-bound prompt anywhere
-- on either model.
local function dropCarried(target)
    local function fireDropPrompts(model)
        if not model then return end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at = (d.ActionText or ""):lower()
                if at:find("carry") or at:find("drop") or at:find("release")
                   or d.KeyboardKeyCode==Enum.KeyCode.Q then
                    pcall(function() d.Enabled=true; d.MaxActivationDistance=9999; d.HoldDuration=0; d.RequiresLineOfSight=false end)
                    pcall(fireprompt, d); pcall(fireprompt, d, 0)
                end
            end
        end
    end
    fireDropPrompts(LP.Character)
    fireDropPrompts(target)
end

local carryKillRunning = false
local carryKillSavedCF = nil   -- module-level so toggle-off callback can TP back immediately

local function doCarryKill()
    if carryKillRunning then return end
    carryKillRunning = true

    local target, root = findCarryTarget()
    local hrp = getHRP()
    if not hrp then carryKillRunning=false; return end

    -- Step 1: TP near target and carry them (Q)
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

    -- Step 2: Wait for carry to register
    task.wait(0.7)

    -- Step 3: Save pre-void position (module-level so toggle-off can use it)
    carryKillSavedCF = getHRP() and getHRP().CFrame

    -- Step 4: TP straight down into the void carrying the victim
    safeTP(CFrame.new(OUTOFMAP))
    task.wait(0.25)

    -- Step 5: DROP the victim while we're in the void so they fall and die.
    -- We fire the drop prompt a few times in case the first frame doesn't register.
    for _ = 1, 5 do
        if not S.carryKill then break end
        dropCarried(target)
        task.wait(0.15)
    end

    -- Step 6: Hold in the void briefly so the void/fall damage kills the dropped
    -- player, aborting early if the toggle is turned off.
    for _ = 1, 20 do
        task.wait(0.1)
        if not S.carryKill then break end   -- user turned it off mid-run → abort
    end

    -- Step 7: TP back to safety (victim has been left in the void)
    local returnCF = carryKillSavedCF
    carryKillSavedCF = nil
    if returnCF then safeTP(returnCF) end
    task.wait(0.5)
    carryKillRunning = false
end

-- ── MINEFIELD RESCUE ─────────────────────────────────────────
-- When Auto Farm is ON and we're inside the Minefield, this automatically:
--   1. TPs to downed players in the Minefield area
--   2. Fires the carry prompt (Q) to pick them up
--   3. TPs to the ButtonZone (safe zone) carrying them
-- Detects "inside minefield" by checking proximity to any cached Landmine (<150 studs).
local mineRescueRunning = false

local function isInsideMinefield()
    local hrp = getHRP(); if not hrp then return false end
    local myPos = hrp.Position
    for _, mine in ipairs(mineCache) do
        if not mine.Parent then continue end
        local mpos = mine:IsA("BasePart") and mine.Position
            or (mine:FindFirstChildWhichIsA("BasePart") and mine:FindFirstChildWhichIsA("BasePart").Position)
        if mpos and (myPos - mpos).Magnitude < 150 then return true end
    end
    -- Fallback: check by folder existence + rough horizontal distance from origin
    local mf = WS:FindFirstChild("Minefield")
    if mf then
        local mhrp = mf:FindFirstChildWhichIsA("BasePart")
        if mhrp and (hrp.Position - mhrp.Position).Magnitude < 200 then return true end
    end
    return false
end

local function getMinefieldExitCF()
    -- Primary: ButtonZone (king circle) — the acknowledged safe destination
    local mm = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("MapModels")
    local bz = mm and mm:FindFirstChild("ButtonZone")
    if bz then
        local pos = bz:IsA("BasePart") and bz.Position
            or (bz:FindFirstChildWhichIsA("BasePart") and bz:FindFirstChildWhichIsA("BasePart").Position)
        if pos then return CFrame.new(pos + Vector3.new(0, 4, 0)) end
    end
    -- Fallback: near the Button itself
    local btn = mm and mm:FindFirstChild("TheButton")
    if btn then
        local bp = btn:FindFirstChild("Button") or btn:FindFirstChildWhichIsA("BasePart")
        local bpPos = bp and (bp:IsA("BasePart") and bp.Position
            or (bp:FindFirstChildWhichIsA("BasePart") and bp:FindFirstChildWhichIsA("BasePart").Position))
        if bpPos then return CFrame.new(bpPos + Vector3.new(5, 3, 5)) end
    end
    return CFrame.new(Vector3.new(0, 10, 0))   -- last resort: map origin
end

local function doMineRescue()
    if mineRescueRunning then return end
    if not isInsideMinefield() then return end
    mineRescueRunning = true

    local downed = WS:FindFirstChild("DownedCharacters")
    if downed then
        for _, d in ipairs(downed:GetChildren()) do
            if not S.autoFarm then break end
            local dRoot = d:FindFirstChildWhichIsA("BasePart"); if not dRoot then continue end
            -- TP close to the downed player
            safeTP(CFrame.new(dRoot.Position + Vector3.new(0, 2, 1.5)))
            task.wait(0.2)
            -- Fire the carry (Q) prompt
            local pp = findCarryPrompt(d)
            if pp then
                pcall(function()
                    pp.Enabled=true; pp.MaxActivationDistance=20
                    pp.HoldDuration=0; pp.RequiresLineOfSight=false
                end)
                pcall(fireprompt, pp); pcall(fireprompt, pp, 0)
            end
            task.wait(0.6)   -- let carry register server-side
            -- TP out of minefield to safety (they come with us)
            safeTP(getMinefieldExitCF())
            task.wait(1.0)
        end
    end

    mineRescueRunning = false
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
-- Fires every event type found in the project folder. Tries multiple argument
-- shapes because we don't know whether the server handler expects (player),
-- (character), (humanoid), or nothing. Also fires ProximityPrompts / ClickDetectors
-- with MaxActivationDistance=9999 so no TP is needed.
local autoProjectRunning = {}

local function fireProjectEvacuate(projName)
    if autoProjectRunning[projName] then return end
    autoProjectRunning[projName] = true
    task.spawn(function()
        local proj = WS:FindFirstChild(projName)
        if not proj then autoProjectRunning[projName]=false; return end

        local hrp     = getHRP()
        local savedCF = hrp and hrp.CFrame
        local char    = LP.Character
        local hum     = char and char:FindFirstChildOfClass("Humanoid")

        local function tryRemote(ev)
            pcall(function() ev:FireServer() end)
            pcall(function() ev:FireServer(LP) end)
            pcall(function() ev:FireServer(char) end)
            pcall(function() ev:FireServer(hum) end)
        end
        local function tryBindable(ev)
            pcall(function() ev:Fire() end)
            pcall(function() ev:Fire(LP) end)
            pcall(function() ev:Fire(char) end)
        end
        local function tryFunction(fn)
            pcall(function() fn:InvokeServer() end)
            pcall(function() fn:InvokeServer(LP) end)
        end

        -- TP inside the project zone so server-side proximity checks pass
        local projRoot = proj:FindFirstChildWhichIsA("BasePart")
            or proj:FindFirstChild("HumanoidRootPart")
        if projRoot then
            safeTP(CFrame.new(projRoot.Position + Vector3.new(0, 3, 0)))
            task.wait(0.15)
        end

        -- named Evacuate fast path
        local ev = proj:FindFirstChild("Evacuate")
        if ev then
            if ev:IsA("RemoteEvent")        then tryRemote(ev)
            elseif ev:IsA("BindableEvent")   then tryBindable(ev)
            elseif ev:IsA("RemoteFunction")  then tryFunction(ev)
            elseif ev:IsA("BindableFunction") then pcall(function() ev:Invoke() end) end
        end

        -- broad sweep of everything in the folder
        for _, d in ipairs(proj:GetDescendants()) do
            if d:IsA("RemoteEvent")         then tryRemote(d)
            elseif d:IsA("BindableEvent")    then tryBindable(d)
            elseif d:IsA("RemoteFunction")   then tryFunction(d)
            elseif d:IsA("BindableFunction") then pcall(function() d:Invoke() end)
            elseif d:IsA("ProximityPrompt")  then
                pcall(function() d.Enabled=true; d.MaxActivationDistance=9999; d.HoldDuration=0 end)
                pcall(fireprompt, d); pcall(fireprompt, d, 0)
            elseif d:IsA("ClickDetector") then
                pcall(function() d.MaxActivationDistance=9999 end)
                pcall(fireclick, d)
            end
        end

        -- TP back to saved position
        if savedCF then
            task.wait(0.2)
            safeTP(savedCF)
        end

        task.wait(0.8)   -- cooldown between project fire attempts
        autoProjectRunning[projName] = false
    end)
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
            if dist > 200 then
                if espData[mine] then removeESP(mine) end
                continue
            end
            getOrMakeESP(mine, Color3.fromRGB(255,200,0))
            updateESP(mine, "LANDMINE ["..dist.."m]", 1)
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
    if S.godMode  then setupGodMode() end
    if S.noStun   then connectNoStun() end
    if S.invis    then applyInvis(true) end
end)

-- ── LOOPS ────────────────────────────────────────────────────
local LOOPS = {}

LOOPS.heartbeat = RunService.Heartbeat:Connect(function(dt)
    if S.infStam then doInfStam() end
    if S.infFood then doInfFood() end
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

LOOPS.stepped = RunService.Stepped:Connect(function(_, dt)
    grabTimer    = grabTimer    + dt
    espTimer     = espTimer     + dt
    combatTimer  = combatTimer  + dt
    miscTimer    = miscTimer    + dt
    zombieTimer  = zombieTimer  + dt
    projectTimer = projectTimer + dt

    if grabTimer >= 0.12 then
        grabTimer = 0
        if S.autoAttack then
            local _, tHRP = findNearest(40)
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

    if zombieTimer >= 0.2 then
        zombieTimer = 0
        if S.autoKillZombies then doAutoKillZombies() end
    end

    if miscTimer >= 0.4 then
        miscTimer = 0
        if S.autoOpenDoors   then doAutoOpenDoors() end
        if S.antiCarry       then doAntiCarry() end
        if S.stayKingCircle  then doStayKingCircle() end
        if S.autoRevive or S.autoFarm then task.spawn(doAutoRevive) end
        if S.autoFarm        then task.spawn(doAutoItemCycle) end
        if S.autoCarry       then task.spawn(doAutoCarry) end
        if S.carryKill       then task.spawn(doCarryKill) end
        -- Minefield Rescue: when Auto Farm is ON and we're inside the minefield,
        -- carry downed players out to ButtonZone safety.
        if S.autoFarm        then task.spawn(doMineRescue) end
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
    Name="Auto Attack", CurrentValue=false, Flag="autoAttack",
    Callback=function(v) S.autoAttack=v end,
})
TabCombat:CreateToggle({
    Name="Auto Kill Zombies", CurrentValue=false, Flag="autoKillZombies",
    Callback=function(v) S.autoKillZombies=v end,
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
    Name="Inf Food (Keep Hunger Full)", CurrentValue=false, Flag="infFood",
    Callback=function(v) S.infFood=v end,
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
    Callback=function(v)
        S.carryKill=v
        if not v then
            -- If we're currently at the void, TP back immediately
            task.spawn(function()
                local cf = carryKillSavedCF
                if cf then
                    carryKillSavedCF = nil
                    safeTP(cf)
                else
                    -- Safety fallback: TP to ButtonZone if savedCF not set
                    local mm = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("MapModels")
                    local bz = mm and mm:FindFirstChild("ButtonZone")
                    if bz then
                        local pos = bz:IsA("BasePart") and bz.Position
                            or (bz:FindFirstChildWhichIsA("BasePart") and bz:FindFirstChildWhichIsA("BasePart").Position)
                        if pos then safeTP(CFrame.new(pos + Vector3.new(0, 5, 0))) end
                    end
                end
            end)
        end
    end,
})
TabAuto:CreateToggle({
    Name="Auto Farm (Revive + Item TP)", CurrentValue=false, Flag="autoFarm",
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
    Content = "F6 = Panic / kill script.\n\nAuto Item: TPs to each item one-by-one, picks it up (E), TPs back. 1.5s cooldown.\nAuto Carry: TPs close, fires Q.\nCarry Kill: Carries target → TPs into the void → drops them → TPs back.",
})

-- ── INIT ─────────────────────────────────────────────────────
task.wait(1)
connectNoStun()
if S.godMode then setupGodMode() end

-- Zombie spawn watcher: kills each zombie the moment it appears in workspace.Zombies
-- instead of only checking on a 0.2s poll. Works retroactively for zombies already
-- present at script load (existing zombies are caught by doAutoKillZombies polling).
task.spawn(function()
    local t0 = tick()
    local zf
    while not zf and tick()-t0 < 60 do
        zf = WS:FindFirstChild("Zombies")
        if not zf then task.wait(1) end
    end
    if not zf then return end
    zf.ChildAdded:Connect(function(zombie)
        task.spawn(function()
            task.wait(0.25)   -- let Humanoid and ZombieScript fully initialize
            for i = 1, 100 do
                if not zombie.Parent then break end
                if S.autoKillZombies then pcall(killOneZombie, zombie) end
                if not zombie.Parent then break end
                task.wait(0.1)
            end
        end)
    end)
end)

Rayfield:LoadConfiguration()
