-- ============================================================
-- Valtix Hub  |  Criminality  —  FREE Edition
-- Blue theme  |  F6 = Panic
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local WS         = game:GetService("Workspace")
local Lighting   = game:GetService("Lighting")
local LP         = Players.LocalPlayer

local function getChar() return LP.Character end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local fireprompt  = (typeof(fireproximityprompt)=="function") and fireproximityprompt or function() end
local fireclick   = (typeof(fireclickdetector)=="function")  and fireclickdetector  or function() end
local firetouchif = (typeof(firetouchinterest)=="function")  and firetouchinterest  or nil

-- ── SAFE TELEPORT (anti-kick: ≤15 stud hops per frame) ──────
local MAX_HOP = 15
local function safeTP(targetCF)
    local hrp = getHRP(); if not hrp then return end
    local goal = targetCF.Position
    local rot  = targetCF - targetCF.Position
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
    -- Auto tab
    autoOpenDoors = false,
    autoSprint    = false,
    autoRespawn   = false,
    antiPickup    = false,
    antiFallDmg   = false,
    autoFinisher  = false,
    -- ESP & Visuals tab
    playerESP     = false,
    lootESP       = false,
    tracers       = false,
    showCrosshair = false,
    showFOV       = false,
    fullbright    = false,
    -- Movement tab
    autoJump      = false,
    speedHack     = false,
    speed         = 32,
    infStam       = false,
    bunnyHop      = false,
    antiKick      = true,
    customJump    = false,
    jumpPower     = 50,
}

-- ── ESP ──────────────────────────────────────────────────────
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
    local adornee = obj:IsA("BasePart") and obj
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")
    if adornee then bb.Adornee = adornee end
    bb.Parent = obj

    local nm = Instance.new("TextLabel", bb)
    nm.Name="_nm"; nm.Size=UDim2.new(1,0,0.48,0)
    nm.BackgroundTransparency=1; nm.TextColor3=outlineColor
    nm.TextStrokeTransparency=1
    nm.Font=Enum.Font.GothamBlack; nm.TextScaled=true; nm.Text="..."
    local nmS = Instance.new("UIStroke", nm)
    nmS.Color=Color3.fromRGB(0,0,0); nmS.Thickness=1.8; nmS.Transparency=0

    local bg = Instance.new("Frame", bb)
    bg.Name="_hpbg"; bg.Size=UDim2.new(1,-10,0.22,0); bg.Position=UDim2.new(0,5,0.54,0)
    bg.BackgroundColor3=Color3.fromRGB(10,10,10); bg.BorderSizePixel=0
    Instance.new("UICorner", bg).CornerRadius=UDim.new(1,0)
    local bgS = Instance.new("UIStroke", bg)
    bgS.Color=outlineColor; bgS.Thickness=1; bgS.Transparency=0.35

    local fill = Instance.new("Frame", bg)
    fill.Name="_hpf"; fill.Size=UDim2.new(1,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,235,80); fill.BorderSizePixel=0
    Instance.new("UICorner", fill).CornerRadius=UDim.new(1,0)

    local txt = Instance.new("TextLabel", bg)
    txt.Name="_hpt"; txt.Size=UDim2.fromScale(1,1)
    txt.BackgroundTransparency=1; txt.TextColor3=Color3.fromRGB(255,255,255)
    txt.TextStrokeTransparency=1; txt.Font=Enum.Font.GothamBlack
    txt.TextScaled=true; txt.ZIndex=3; txt.Text="100%"
    local txS = Instance.new("UIStroke", txt)
    txS.Color=Color3.fromRGB(0,0,0); txS.Thickness=1.2; txS.Transparency=0

    local hpv = Instance.new("TextLabel", bb)
    hpv.Name="_hpv"; hpv.Size=UDim2.new(1,0,0.2,0); hpv.Position=UDim2.new(0,0,0.79,0)
    hpv.BackgroundTransparency=1; hpv.TextColor3=Color3.fromRGB(200,200,200)
    hpv.TextStrokeTransparency=1; hpv.Font=Enum.Font.GothamBlack; hpv.TextScaled=true; hpv.Text=""
    local hv2S = Instance.new("UIStroke", hpv)
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
    if hpv and maxHp and maxHp > 0 then
        hpv.Text = math.round(pct*maxHp).." / "..math.round(maxHp).." HP"
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

-- ── DRAWING (tracers + FOV circle + crosshair) ───────────────
-- Drawing is executor-specific; wrapped so script loads on any executor
local drawOK = pcall(function() local t = Drawing.new("Line"); t:Remove() end)
local tracerLines = {}
local fovCircle, crosshairDot

local function ensureDrawing()
    if not drawOK then return end
    if not fovCircle then
        pcall(function()
            fovCircle           = Drawing.new("Circle")
            fovCircle.Visible   = false
            fovCircle.Thickness = 1.5
            fovCircle.Color     = Color3.fromRGB(255,255,255)
            fovCircle.Transparency = 0.6
            fovCircle.Filled    = false
        end)
    end
    if not crosshairDot then
        pcall(function()
            crosshairDot              = Drawing.new("Circle")
            crosshairDot.Visible      = false
            crosshairDot.Radius       = 3
            crosshairDot.Filled       = true
            crosshairDot.Color        = Color3.fromRGB(255,80,80)
            crosshairDot.Transparency = 1
        end)
    end
end

local function updateTracers()
    for _, ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
    tracerLines = {}
    if not drawOK or not S.tracers then return end
    local cam = WS.CurrentCamera
    if not cam then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character; if not char then continue end
        local phrp = char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        local sp, onScreen = cam:WorldToViewportPoint(phrp.Position)
        if onScreen then
            pcall(function()
                local ln        = Drawing.new("Line")
                ln.From         = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                ln.To           = Vector2.new(sp.X, sp.Y)
                ln.Color        = Color3.fromRGB(240,50,50)
                ln.Thickness    = 1
                ln.Transparency = 1
                ln.Visible      = true
                table.insert(tracerLines, ln)
            end)
        end
    end
end

local function updateOverlays()
    if not drawOK then return end
    local cam = WS.CurrentCamera; if not cam then return end
    local cx, cy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
    if fovCircle then
        pcall(function()
            fovCircle.Radius   = 120
            fovCircle.Position = Vector2.new(cx, cy)
            fovCircle.Visible  = S.showFOV
        end)
    end
    if crosshairDot then
        pcall(function()
            crosshairDot.Position = Vector2.new(cx, cy)
            crosshairDot.Visible  = S.showCrosshair
        end)
    end
end

-- ── CRIMINALITY: DOWNED DETECTION ────────────────────────────
local DOWNED_KEYS = {"downed","ko","knocked","knockedout","incapacitated","down","bled","bleedout"}

local function isDowned(char)
    if not char then return false end
    for _, k in ipairs({"Downed","KO","Knocked","KnockedOut","Incapacitated","Down"}) do
        local v = char:GetAttribute(k)
        if v == true then return true end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BoolValue") then
            local nm = d.Name:lower()
            for _, k in ipairs(DOWNED_KEYS) do
                if nm:find(k) and d.Value then return true end
            end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 and char.Parent then return true end
    return false
end

-- ── CRIMINALITY: LOOT DETECTION ──────────────────────────────
local LOOT_KEYWORDS = {
    "m4","ak","ar","usp","glock","pistol","revolver","shotgun","smg","mp5","rifle",
    "sniper","awp","deagle","desert","beretta","magnum","p90","mac","uzi",
    "knife","bat","sword","crowbar",
    "cash","money","bag","loot","drug","cocaine","weed","contraband","package",
    "briefcase","wallet","jewel","gold","diamond",
}
local IGNORE_MODELS = {Terrain=true,Camera=true,Workspace=true}

local function isCriminalityLoot(obj)
    if IGNORE_MODELS[obj.Name] then return false end
    if not (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart")) then return false end
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local nm = obj.Name:lower()
    for _, k in ipairs(LOOT_KEYWORDS) do
        if nm:find(k) then return true end
    end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = (d.ActionText or ""):lower()
            if at:find("pick") or at:find("grab") or at:find("take") or at:find("collect") then
                return true
            end
        end
        if d:IsA("ClickDetector") then return true end
    end
    return false
end

-- ── FIND NEAREST ─────────────────────────────────────────────
local function findNearest(radius)
    local hrp = getHRP(); if not hrp then return nil,nil end
    radius = radius or 9999
    local best, bestDist, bestHRP = nil, radius+1, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        local phrp=char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health>0 then
            local d=(hrp.Position-phrp.Position).Magnitude
            if d<bestDist then best=plr; bestDist=d; bestHRP=phrp end
        end
    end
    return best, bestHRP
end

-- ── FULLBRIGHT ────────────────────────────────────────────────
local origLighting = {}
local function applyFullbright(on)
    if on then
        origLighting.Brightness    = Lighting.Brightness
        origLighting.ClockTime     = Lighting.ClockTime
        origLighting.GlobalShadows = Lighting.GlobalShadows
        origLighting.FogEnd        = Lighting.FogEnd
        origLighting.FogStart      = Lighting.FogStart
        pcall(function()
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.GlobalShadows = false
            Lighting.FogEnd        = 1e6
            Lighting.FogStart      = 1e6
        end)
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                pcall(function() e.Enabled = false end)
            end
        end
    else
        pcall(function()
            Lighting.Brightness    = origLighting.Brightness    or 1
            Lighting.ClockTime     = origLighting.ClockTime     or 14
            Lighting.GlobalShadows = (origLighting.GlobalShadows ~= nil) and origLighting.GlobalShadows or true
            Lighting.FogEnd        = origLighting.FogEnd        or 1000
            Lighting.FogStart      = origLighting.FogStart      or 0
        end)
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                pcall(function() e.Enabled = true end)
            end
        end
    end
end

-- ── INFINITE STAMINA ─────────────────────────────────────────
local function doInfStam()
    local function maxVal(d) pcall(function() d.Value = 1e6 end) end
    local function scan(root)
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            local nm = d.Name:lower()
            if (d:IsA("NumberValue") or d:IsA("IntValue")) and
               (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then
                maxVal(d)
            end
            if d:IsA("LocalScript") and (nm:find("stam") or nm:find("sprint") or nm:find("energy")) then
                pcall(function() d.Disabled=true end)
            end
        end
    end
    local char = LP.Character
    if char then
        for k, v in pairs(char:GetAttributes()) do
            local nm = k:lower()
            if type(v)=="number" and (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then
                pcall(function() char:SetAttribute(k, 1e6) end)
            end
        end
        scan(char)
    end
    scan(LP:FindFirstChild("PlayerGui"))
    scan(LP:FindFirstChild("PlayerData"))
    scan(LP:FindFirstChild("Values"))
    scan(LP:FindFirstChild("Stats"))
    local hum = getHum()
    if hum then pcall(function()
        local spd = S.speedHack and S.speed or 24
        if hum.WalkSpeed < spd then hum.WalkSpeed = spd end
    end) end
end

-- ── AUTO OPEN DOORS / GATES ───────────────────────────────────
-- Cache doors once; update on DescendantAdded/Removing to avoid scanning every 0.5s
local doorCache = {}
local function isDoorModel(nm)
    return nm:match("^Door") or nm:match("N_ARM_Door") or nm:match("^Elevator") or nm:match("DoubleDoors")
end
local function rebuildDoorCache()
    doorCache = {}
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Model") then
            local nm = obj.Name
            local match = isDoorModel(nm)
            if not match then
                local vals = obj:FindFirstChild("Values")
                if vals and vals:FindFirstChild("DoubleDoors") then match = true end
            end
            if match then table.insert(doorCache, obj) end
        end
    end
end
rebuildDoorCache()
WS.DescendantAdded:Connect(function(obj)
    if not obj:IsA("Model") then return end
    local nm = obj.Name
    local match = isDoorModel(nm)
    if not match then
        local vals = obj:FindFirstChild("Values")
        if vals and vals:FindFirstChild("DoubleDoors") then match = true end
    end
    if match then table.insert(doorCache, obj) end
end)
WS.DescendantRemoving:Connect(function(obj)
    for i, v in ipairs(doorCache) do
        if v == obj then table.remove(doorCache, i); break end
    end
end)

local function doAutoOpenDoors()
    local hrp = getHRP(); if not hrp then return end
    for _, obj in ipairs(doorCache) do
        if not obj.Parent then continue end
        local root = obj:FindFirstChildWhichIsA("BasePart")
        if not root or (hrp.Position - root.Position).Magnitude > 60 then continue end
        for _, pp in ipairs(obj:GetDescendants()) do
            if pp:IsA("ProximityPrompt") then
                pcall(function() pp.Enabled=true; pp.MaxActivationDistance=70; pp.HoldDuration=0 end)
                pcall(fireprompt, pp)
            elseif pp:IsA("ClickDetector") then
                pcall(function() pp.MaxActivationDistance=70 end)
                pcall(fireclick, pp)
            end
        end
    end
end

-- ── AUTO RESPAWN ──────────────────────────────────────────────
local lastRespawn = 0
local function doAutoRespawn()
    local hum = getHum()
    if not (hum and hum.Health <= 0) then return end
    if (tick() - lastRespawn) < 4 then return end
    lastRespawn = tick()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local events = RS:WaitForChild("Events", 3)
        if not events then return end
        local deathRespawn = events:WaitForChild("DeathRespawn", 3)
        if not deathRespawn then return end
        deathRespawn:InvokeServer("KMG4R904")
    end)
end

-- ── AUTO SPRINT (one-shot apply, not per-frame) ──────────────
local function applyAutoSprint()
    if not S.autoSprint then return end
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = 24 end) end
end

-- ── ANTI PICKUP ───────────────────────────────────────────────
-- Disables prompts on our character that let others rob/carry/execute us
local function doAntiPickup()
    local char = LP.Character; if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = (d.ActionText or ""):lower()
            if at:find("carry") or at:find("rob") or at:find("grab") or at:find("pick")
               or at:find("execute") or at:find("finish") or at:find("revive") or at:find("search")
               or d.KeyboardKeyCode==Enum.KeyCode.Q or d.KeyboardKeyCode==Enum.KeyCode.E then
                pcall(function() d.Enabled = false end)
            end
        end
    end
end

-- ── AUTO FINISHER ─────────────────────────────────────────────
local finisherRunning = false
local function doAutoFinisher()
    if finisherRunning then return end
    finisherRunning = true
    local myHRP = getHRP()
    if not myHRP then finisherRunning=false; return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char = plr.Character; if not char then continue end
        if not isDowned(char) then continue end
        local phrp = char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        if (myHRP.Position - phrp.Position).Magnitude > 15 then continue end

        safeTP(CFrame.new(phrp.Position + Vector3.new(0, 2, 1.5)))
        task.wait(0.15)

        -- Press F (FINISH key in Criminality)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.1)
            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)

        -- Fallback: fire execute proximity prompts
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at = (d.ActionText or ""):lower()
                if at:find("execute") or at:find("finish") or at:find("kill") or at:find("stab") then
                    pcall(function() d.Enabled=true; d.MaxActivationDistance=20; d.HoldDuration=0; d.RequiresLineOfSight=false end)
                    pcall(fireprompt, d)
                end
            end
        end
        task.wait(0.3)
    end
    finisherRunning = false
end

-- ── ESP TICK ─────────────────────────────────────────────────
local function getTeamColor(plr)
    pcall(function()
        local ts = game:GetService("Teams")
        for _, t in ipairs(ts:GetTeams()) do
            if plr.Team == t then return t.TeamColor.Color end
        end
    end)
    local char = plr.Character
    if char then
        local role = char:GetAttribute("Role") or char:GetAttribute("Team") or char:GetAttribute("Faction")
        if role then
            local rs = tostring(role):lower()
            if rs:find("cop") or rs:find("police") or rs:find("law") then
                return Color3.fromRGB(80,140,255)
            end
        end
    end
    return Color3.fromRGB(255,80,80)
end

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
            local downed = isDowned(char)
            local color  = downed and Color3.fromRGB(160,160,160) or getTeamColor(plr)
            local label  = plr.Name.." ["..dist.."m]"..(downed and " [DOWN]" or "")
            getOrMakeESP(char, color)
            updateESP(char, label, pct, mxhp)
        elseif espData[char] then removeESP(char) end
    end

    if S.lootESP then
        for _, obj in ipairs(WS:GetChildren()) do
            if isCriminalityLoot(obj) then
                local root = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                local dist = (myHRP and root) and math.round((myHRP.Position-root.Position).Magnitude) or 0
                getOrMakeESP(obj, Color3.fromRGB(80,255,80))
                updateESP(obj, obj.Name.." ["..dist.."m]", 1)
            elseif espData[obj] then removeESP(obj) end
        end
    end
end

-- ── CHARACTER ADDED ───────────────────────────────────────────
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if S.fullbright  then applyFullbright(true) end
    if S.infStam     then doInfStam() end
    if S.autoSprint  then applyAutoSprint() end
end)

-- ── LOOPS ────────────────────────────────────────────────────
local LOOPS = {}

LOOPS.heartbeat = RunService.Heartbeat:Connect(function()
    if S.speedHack then
        local hum = getHum()
        if hum then pcall(function() hum.WalkSpeed=S.speed end) end
    end
    if S.customJump then
        local hum = getHum()
        if hum then pcall(function() hum.JumpPower=S.jumpPower end) end
    end
    if S.infStam then doInfStam() end
    if S.antiFallDmg then
        local hrp = getHRP()
        if hrp then pcall(function()
            local vel = hrp.AssemblyLinearVelocity
            if vel.Y < -80 then
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -20, vel.Z)
            end
        end) end
    end
    if S.bunnyHop then
        local hum = getHum()
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Landed then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end
    if S.autoJump then
        local hum = getHum()
        if hum then pcall(function() hum.Jump=true end) end
    end
    if S.antiKick then
        local hrp = getHRP()
        if hrp then pcall(function()
            local v  = hrp.AssemblyLinearVelocity
            local ny = math.min(v.Y, 90)
            local horiz = Vector3.new(v.X, 0, v.Z)
            local hcap = math.max(S.speed+80, 160)
            if horiz.Magnitude > hcap then
                local c = horiz.Unit * hcap
                hrp.AssemblyLinearVelocity = Vector3.new(c.X, ny, c.Z)
            elseif ny ~= v.Y then
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, ny, v.Z)
            end
        end) end
    end
end)

local espT      = 0
local doorT     = 0
local autoT     = 0
local tracerT   = 0
local overlayT  = 0

LOOPS.stepped = RunService.Stepped:Connect(function(_, dt)
    espT     = espT     + dt
    doorT    = doorT    + dt
    autoT    = autoT    + dt
    tracerT  = tracerT  + dt
    overlayT = overlayT + dt

    if espT >= 0.25 then
        espT = 0
        runESP()
    end
    if doorT >= 0.5 then
        doorT = 0
        if S.autoOpenDoors then doAutoOpenDoors() end
        if S.antiPickup    then doAntiPickup() end
    end
    if autoT >= 0.4 then
        autoT = 0
        if S.autoRespawn  then doAutoRespawn() end
        if S.autoFinisher then task.spawn(doAutoFinisher) end
    end
    if tracerT >= 0.1 then
        tracerT = 0
        if S.tracers then
            updateTracers()
        elseif #tracerLines > 0 then
            for _, ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
            tracerLines = {}
        end
    end
    if overlayT >= 0.05 then
        overlayT = 0
        updateOverlays()
    end
end)

-- ── F6 PANIC ─────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F6 then
        for _, c in pairs(LOOPS) do pcall(function() c:Disconnect() end) end
        clearAllESP()
        applyFullbright(false)
        for _, ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
        tracerLines = {}
        if fovCircle    then pcall(function() fovCircle.Visible=false    end) end
        if crosshairDot then pcall(function() crosshairDot.Visible=false end) end
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            for _, g in ipairs(pg:GetChildren()) do
                if g.Name:find("Rayfield") or g.Name:find("Valtix") then
                    pcall(function() g:Destroy() end)
                end
            end
        end
    end
end)

-- ── RAYFIELD GUI ─────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "Valtix Hub  |  Criminality  FREE",
    Icon            = 0,
    LoadingTitle    = "Valtix Hub",
    LoadingSubtitle = "Criminality  —  FREE Edition",
    Theme = {
        Background          = Color3.fromRGB(8,10,14),
        Header              = Color3.fromRGB(10,14,20),
        TextColor           = Color3.fromRGB(230,240,255),
        ElementBackground   = Color3.fromRGB(14,18,28),
        SecondaryBackground = Color3.fromRGB(11,15,22),
        Stroke              = Color3.fromRGB(0,60,160),
        SubTextColor        = Color3.fromRGB(140,170,220),
        PlaceholderColor    = Color3.fromRGB(80,110,180),
        TabBackground       = Color3.fromRGB(8,12,18),
        TabStroke           = Color3.fromRGB(0,120,255),
        TabTextColor        = Color3.fromRGB(180,200,240),
        SelectedTabTextColor= Color3.fromRGB(255,255,255),
        SliderBackground    = Color3.fromRGB(14,18,28),
        SliderProgress      = Color3.fromRGB(0,100,220),
        SliderStroke        = Color3.fromRGB(0,80,180),
        ToggleBackground    = Color3.fromRGB(14,18,28),
        ToggleEnabled       = Color3.fromRGB(0,120,255),
        ToggleDisabled      = Color3.fromRGB(35,40,55),
        ToggleEnabledStroke = Color3.fromRGB(0,150,255),
        ToggleDisabledStroke= Color3.fromRGB(50,60,80),
        ToggleEnabledOuterStroke  = Color3.fromRGB(0,100,220),
        ToggleDisabledOuterStroke = Color3.fromRGB(30,36,50),
        InputBackground     = Color3.fromRGB(12,16,24),
        InputStroke         = Color3.fromRGB(0,70,160),
        PlaceholderText     = Color3.fromRGB(80,110,180),
    },
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled=true, FolderName="Valtix_Criminality", FileName="FREE_Config" },
    KeySystem              = false,
})

-- ── AUTO TAB ─────────────────────────────────────────────────
local TabAuto = Window:CreateTab("Auto", 4483362458)

TabAuto:CreateToggle({
    Name="Auto Open Doors / Gates", CurrentValue=false, Flag="autoOpenDoors",
    Callback=function(v) S.autoOpenDoors=v end,
})
TabAuto:CreateToggle({
    Name="Auto Sprint", CurrentValue=false, Flag="autoSprint",
    Callback=function(v)
        S.autoSprint=v
        if v then
            applyAutoSprint()
        elseif not S.speedHack then
            local hum=getHum(); if hum then pcall(function() hum.WalkSpeed=16 end) end
        end
    end,
})
TabAuto:CreateToggle({
    Name="Auto Respawn", CurrentValue=false, Flag="autoRespawn",
    Callback=function(v) S.autoRespawn=v end,
})
TabAuto:CreateToggle({
    Name="Anti Pick-Up (Block Rob / Carry When Downed)", CurrentValue=false, Flag="antiPickup",
    Callback=function(v) S.antiPickup=v end,
})
TabAuto:CreateToggle({
    Name="Anti Fall Damage", CurrentValue=false, Flag="antiFallDmg",
    Callback=function(v) S.antiFallDmg=v end,
})
TabAuto:CreateToggle({
    Name="Auto Finisher (Execute Nearby Downed Players)", CurrentValue=false, Flag="autoFinisher",
    Callback=function(v) S.autoFinisher=v end,
})

-- ── ESP & VISUALS TAB ────────────────────────────────────────
local TabESP = Window:CreateTab("ESP & Visuals", 4483362458)

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
    Name="Loot ESP (Guns / Cash / Bags)", CurrentValue=false, Flag="lootESP",
    Callback=function(v)
        S.lootESP=v
        if not v then
            for _, obj in ipairs(WS:GetChildren()) do
                if isCriminalityLoot(obj) then removeESP(obj) end
            end
        end
    end,
})
TabESP:CreateToggle({
    Name="Tracers", CurrentValue=false, Flag="tracers",
    Callback=function(v)
        S.tracers=v
        if not v then
            for _, ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
            tracerLines = {}
        end
    end,
})
TabESP:CreateToggle({
    Name="Crosshair Dot", CurrentValue=false, Flag="showCrosshair",
    Callback=function(v)
        S.showCrosshair=v
        ensureDrawing()
        if crosshairDot then pcall(function() crosshairDot.Visible=v end) end
    end,
})
TabESP:CreateToggle({
    Name="FOV Circle", CurrentValue=false, Flag="showFOV",
    Callback=function(v)
        S.showFOV=v
        ensureDrawing()
        if fovCircle then pcall(function() fovCircle.Visible=v end) end
    end,
})
TabESP:CreateToggle({
    Name="Fullbright + No Fog", CurrentValue=false, Flag="fullbright",
    Callback=function(v) S.fullbright=v; applyFullbright(v) end,
})

-- ── MOVEMENT TAB ─────────────────────────────────────────────
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateToggle({
    Name="Auto Jump", CurrentValue=false, Flag="autoJump",
    Callback=function(v) S.autoJump=v end,
})
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
    Name="Speed Value", Range={16,300}, Increment=1, Suffix="studs/s",
    CurrentValue=32, Flag="speedValue",
    Callback=function(v) S.speed=v end,
})
TabMove:CreateToggle({
    Name="Infinite Stamina", CurrentValue=false, Flag="infStam",
    Callback=function(v) S.infStam=v end,
})
TabMove:CreateToggle({
    Name="Bunny Hop", CurrentValue=false, Flag="bunnyHop",
    Callback=function(v) S.bunnyHop=v end,
})
TabMove:CreateToggle({
    Name="Anti Kick (Velocity Clamp)", CurrentValue=true, Flag="antiKick",
    Callback=function(v) S.antiKick=v end,
})
TabMove:CreateToggle({
    Name="Custom Jump Power", CurrentValue=false, Flag="customJump",
    Callback=function(v)
        S.customJump=v
        if not v then
            local hum=getHum(); if hum then pcall(function() hum.JumpPower=50 end) end
        end
    end,
})
TabMove:CreateSlider({
    Name="Jump Power", Range={50,500}, Increment=5, Suffix="",
    CurrentValue=50, Flag="jumpPower",
    Callback=function(v) S.jumpPower=v end,
})

-- ── TELEPORT TAB ─────────────────────────────────────────────
local TabTP = Window:CreateTab("Teleport", 4483362458)

local function tpToMapFolder(folderName)
    local mapFolder = WS:FindFirstChild("Map"); if not mapFolder then return end
    local target = mapFolder:FindFirstChild(folderName); if not target then return end
    local root = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
    if not root then
        for _, child in ipairs(target:GetChildren()) do
            local p = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart")
            if p then root = p; break end
        end
    end
    if root then safeTP(CFrame.new(root.Position + Vector3.new(0, 3, 0))) end
end

TabTP:CreateButton({ Name = "Teleport  →  ATMs (Map/ATMz)",
    Callback = function() task.spawn(tpToMapFolder, "ATMz") end })
TabTP:CreateButton({ Name = "Teleport  →  Safes / Registers (Map/BredMakurz)",
    Callback = function() task.spawn(tpToMapFolder, "BredMakurz") end })
TabTP:CreateButton({ Name = "Teleport  →  Shop / Armory Dealer (Map/Shopz)",
    Callback = function() task.spawn(tpToMapFolder, "Shopz") end })
TabTP:CreateButton({ Name = "Teleport  →  Nearest Player",
    Callback = function()
        task.spawn(function()
            local _, nearHRP = findNearest(9999)
            if nearHRP then safeTP(CFrame.new(nearHRP.Position + Vector3.new(0, 3, 2))) end
        end)
    end })

-- ── INFO TAB ─────────────────────────────────────────────────
local TabInfo = Window:CreateTab("Info", 4483362458)
TabInfo:CreateParagraph({
    Title   = "Criminality  |  FREE Edition",
    Content = "F6 = Panic / kill script.\n\nAuto Finisher: TPs to downed players and presses F (FINISH key).\nAnti Pick-Up: disables rob/carry prompts on your character when you're downed.\nLoot ESP: highlights dropped guns, cash, and bags.\nFullbright: maxes Lighting brightness + removes fog/atmosphere.\nTeleport: TP to ATMs, Safes, Shops, or nearest player via the game's Map folder.\n\nUpgrade to PREM for aimbot, gun mods, auto-heal and auto-rob.\nUpgrade to PLUS for silent aim, god mode, and full money automation.",
})

-- ── INIT ─────────────────────────────────────────────────────
task.wait(1)
ensureDrawing()
Rayfield:LoadConfiguration()
