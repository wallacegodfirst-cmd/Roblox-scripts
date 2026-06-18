-- ============================================================
-- Wallace Chaos Hub  |  The Button  —  PAID Edition
-- Black / Blue / Red theme  |  F6 = Panic
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

-- Out-of-map TP position (far outside map boundary, causes fall death)
local OUTOFMAP = Vector3.new(9999, 200, 9999)

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
    hl.FillTransparency=0.6; hl.OutlineTransparency=0; hl.Parent=obj

    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,180,0,54)
    bb.StudsOffset=Vector3.new(0,5,0); bb.Parent=obj

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
    local nm = bb:FindFirstChild("_nm"); if nm then nm.Text=label or "" end
    local bg = bb:FindFirstChild("_hpbg"); if not bg then return end
    local fill = bg:FindFirstChild("_hpf"); local txt=bg:FindFirstChild("_hpt")
    local pct = math.clamp(hpPct or 1, 0, 1)
    if fill then
        fill.Size=UDim2.new(pct,0,1,0)
        fill.BackgroundColor3 = pct>0.6 and Color3.fromRGB(0,210,60)
            or pct>0.3 and Color3.fromRGB(230,170,0) or Color3.fromRGB(210,40,40)
    end
    if txt then txt.Text=math.round(pct*100).."%" end
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
local function doFling()
    local _, targetHRP = findNearest(200)
    if targetHRP then
        pcall(function()
            targetHRP.AssemblyLinearVelocity = Vector3.new(
                math.random(-800,800), 3000, math.random(-800,800)
            )
        end)
    end
end

-- ── AUTO KILL ZOMBIES ────────────────────────────────────────
local function doAutoKillZombies()
    local zombieFolder = WS:FindFirstChild("Zombies"); if not zombieFolder then return end
    for _, zombie in ipairs(zombieFolder:GetChildren()) do
        if zombie.Name~="Zombie" then continue end
        local zHum = zombie:FindFirstChildOfClass("Humanoid")
        local zHRP = zombie:FindFirstChild("HumanoidRootPart")
        if not zHum or not zHRP or zHum.Health<=0 then continue end
        -- Launch zombie far out-of-bounds so the game's void/boundary kills it
        pcall(function()
            zHRP.CFrame = CFrame.new(9999, 3000, 9999)
            zHRP.AssemblyLinearVelocity = Vector3.new(0, -9999, 0)
        end)
        -- Attempt every client-side kill method
        pcall(function() zHum.Health = 0 end)
        pcall(function() zHum:TakeDamage(zHum.MaxHealth) end)
        pcall(function() zHum:ChangeState(Enum.HumanoidStateType.Dead) end)
        pcall(function() zombie:BreakJoints() end)
        -- Anchor so it cannot walk back even if still alive
        pcall(function() zHRP.Anchored = true end)
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
        pcall(function() hrp.CFrame=CFrame.new(dRoot.Position+Vector3.new(0,2,2)) end)
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
        pcall(function() hrp2.CFrame=CFrame.new(root.Position+Vector3.new(0,3,0)) end)
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
    pcall(function() hrp.CFrame=CFrame.new(root.Position+Vector3.new(0,2,1.5)) end)
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

    -- Step 1: TP near target and carry them (Q)
    if root then
        pcall(function() hrp.CFrame=CFrame.new(root.Position+Vector3.new(0,2,1.5)) end)
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

    -- Step 3: Save position and TP outside the map (they come with us)
    local savedCF = getHRP() and getHRP().CFrame
    pcall(function() local h=getHRP(); if h then h.CFrame=CFrame.new(OUTOFMAP) end end)

    -- Step 4: Wait for target to die from fall / out-of-bounds
    task.wait(3.5)

    -- Step 5: TP back
    if savedCF then
        pcall(function() local h=getHRP(); if h then h.CFrame=savedCF end end)
    end
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
    if bpos then pcall(function() hrp.CFrame=CFrame.new(bpos+Vector3.new(0,3,0)) end) end
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
local function fireProjectEvacuate(projName)
    local proj = WS:FindFirstChild(projName); if not proj then return end
    local ev = proj:FindFirstChild("Evacuate"); if not ev then return end
    if ev:IsA("BindableEvent") then pcall(function() ev:Fire() end)
    elseif ev:IsA("RemoteEvent") then pcall(function() ev:FireServer() end) end
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
            local pct  = (hum and hum.MaxHealth>0) and (hum.Health/hum.MaxHealth) or 1
            local dist = (myHRP and phrp) and math.round((myHRP.Position-phrp.Position).Magnitude) or 0
            getOrMakeESP(char, Color3.fromRGB(255,80,80))
            updateESP(char, plr.Name.." ["..dist.."m]", pct)
        elseif espData[char] then removeESP(char) end
    end

    local ghostFolder = WS:FindFirstChild("Ghosts")
    if ghostFolder then
        for _, ghost in ipairs(ghostFolder:GetChildren()) do
            if S.ghostESP then
                local hum  = ghost:FindFirstChildOfClass("Humanoid")
                local ghrp = ghost:FindFirstChildWhichIsA("BasePart")
                local pct  = (hum and hum.MaxHealth>0) and (hum.Health/hum.MaxHealth) or 1
                local dist = (myHRP and ghrp) and math.round((myHRP.Position-ghrp.Position).Magnitude) or 0
                getOrMakeESP(ghost, Color3.fromRGB(180,100,255))
                updateESP(ghost, "GHOST:"..ghost.Name.." ["..dist.."m]", pct)
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

LOOPS.heartbeat = RunService.Heartbeat:Connect(function()
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

LOOPS.stepped = RunService.Stepped:Connect(function(_, dt)
    grabTimer    = grabTimer    + dt
    espTimer     = espTimer     + dt
    combatTimer  = combatTimer  + dt
    miscTimer    = miscTimer    + dt
    zombieTimer  = zombieTimer  + dt
    projectTimer = projectTimer + dt

    if grabTimer >= 0.12 then
        grabTimer = 0
        if S.autoGrab  then doAutoGrab() end
        if S.killAura  then doKillAura() end
        if S.autoAttack then
            local _, tHRP = findNearest(S.killAuraRadius*2)
            if tHRP then
                local hrp = getHRP()
                if hrp then pcall(function() hrp.CFrame=CFrame.new(tHRP.Position+Vector3.new(0,2,3)) end) end
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

    if zombieTimer >= 0.25 then
        zombieTimer = 0
        if S.autoKillZombies then doAutoKillZombies() end
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
    LoadingSubtitle  = "Black Edition — All Features",
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
