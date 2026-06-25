-- ============================================================
-- Valtix Hub  |  Criminality  —  PREMIUM Edition
-- Red theme  |  F6 = Panic
-- Includes everything in FREE + Combat, Gun Mods, Survival, Farming
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
local sethidden   = (typeof(sethiddenproperty)=="function")  and sethiddenproperty  or nil

-- ── SAFE TELEPORT ────────────────────────────────────────────
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
    -- ── FREE features ──
    autoOpenDoors = false,
    autoSprint    = false,
    autoRespawn   = false,
    antiPickup    = false,
    antiFallDmg   = false,
    autoFinisher  = false,
    playerESP     = false,
    lootESP       = false,
    tracers       = false,
    showCrosshair = false,
    showFOV       = false,
    fullbright    = false,
    autoJump      = false,
    speedHack     = false,
    speed         = 32,
    infStam       = false,
    bunnyHop      = false,
    antiKick      = true,
    customJump    = false,
    jumpPower     = 50,
    -- ── PREM features ──
    aimbot        = false,
    aimbotFOV     = 120,
    aimbotSmooth  = 0.2,
    aimbotPart    = "Head",   -- "Head" or "HumanoidRootPart"
    aimbotKey     = Enum.KeyCode.Q,
    teamCheck     = true,
    ignoreKnocked = true,
    triggerBot    = false,
    noRecoil      = false,
    noSpread      = false,
    noSway        = false,
    fastFire      = false,
    instReload    = false,
    infAmmo       = false,
    weaponESP     = false,
    cashESP       = false,
    skeletonESP   = false,
    visibilityColor = false,
    autoBandage   = false,
    autoHeal      = false,
    antiBleed     = false,
    antiDown      = false,
    fly           = false,
    noclip        = false,
    noFallDmg     = false,
    autoRob       = false,
    autoLoot      = false,
}

-- ── FOV CHECK ────────────────────────────────────────────────
local function inFOV(worldPos, fovRadius)
    local cam = WS.CurrentCamera; if not cam then return false end
    local sp, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local cx = cam.ViewportSize.X / 2
    local cy = cam.ViewportSize.Y / 2
    local dx = sp.X - cx
    local dy = sp.Y - cy
    return (dx*dx + dy*dy) <= (fovRadius*fovRadius), Vector2.new(sp.X, sp.Y)
end

local function isVisible(hrp)
    local cam = WS.CurrentCamera; if not cam then return false end
    local origin = cam.CFrame.Position
    local dir    = (hrp.Position - origin)
    local ray    = RaycastParams.new()
    ray.FilterDescendantsInstances = {LP.Character, hrp.Parent}
    ray.FilterType = Enum.RaycastFilterType.Exclude
    local result = WS:Raycast(origin, dir, ray)
    return result == nil
end

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
    bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,260,0,90)
    bb.StudsOffset=Vector3.new(0,7,0)
    local adornee = obj:IsA("BasePart") and obj
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")
    if adornee then bb.Adornee=adornee end
    bb.Parent=obj

    local nm=Instance.new("TextLabel",bb)
    nm.Name="_nm"; nm.Size=UDim2.new(1,0,0.4,0)
    nm.BackgroundTransparency=1; nm.TextColor3=outlineColor
    nm.TextStrokeTransparency=1; nm.Font=Enum.Font.GothamBlack
    nm.TextScaled=true; nm.Text="..."
    local nmS=Instance.new("UIStroke",nm)
    nmS.Color=Color3.fromRGB(0,0,0); nmS.Thickness=1.8

    local sub=Instance.new("TextLabel",bb)
    sub.Name="_sub"; sub.Size=UDim2.new(1,0,0.2,0); sub.Position=UDim2.new(0,0,0.4,0)
    sub.BackgroundTransparency=1; sub.TextColor3=Color3.fromRGB(200,200,200)
    sub.TextStrokeTransparency=1; sub.Font=Enum.Font.GothamBlack
    sub.TextScaled=true; sub.Text=""
    local subS=Instance.new("UIStroke",sub)
    subS.Color=Color3.fromRGB(0,0,0); subS.Thickness=1.2

    local bg=Instance.new("Frame",bb)
    bg.Name="_hpbg"; bg.Size=UDim2.new(1,-10,0.18,0); bg.Position=UDim2.new(0,5,0.64,0)
    bg.BackgroundColor3=Color3.fromRGB(10,10,10); bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    local bgS=Instance.new("UIStroke",bg)
    bgS.Color=outlineColor; bgS.Thickness=1; bgS.Transparency=0.35

    local fill=Instance.new("Frame",bg)
    fill.Name="_hpf"; fill.Size=UDim2.new(1,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,235,80); fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local txt=Instance.new("TextLabel",bg)
    txt.Name="_hpt"; txt.Size=UDim2.fromScale(1,1)
    txt.BackgroundTransparency=1; txt.TextColor3=Color3.fromRGB(255,255,255)
    txt.TextStrokeTransparency=1; txt.Font=Enum.Font.GothamBlack
    txt.TextScaled=true; txt.ZIndex=3; txt.Text="100%"
    local txS=Instance.new("UIStroke",txt)
    txS.Color=Color3.fromRGB(0,0,0); txS.Thickness=1.2

    local hpv=Instance.new("TextLabel",bb)
    hpv.Name="_hpv"; hpv.Size=UDim2.new(1,0,0.16,0); hpv.Position=UDim2.new(0,0,0.84,0)
    hpv.BackgroundTransparency=1; hpv.TextColor3=Color3.fromRGB(200,200,200)
    hpv.TextStrokeTransparency=1; hpv.Font=Enum.Font.GothamBlack; hpv.TextScaled=true; hpv.Text=""
    local hv2S=Instance.new("UIStroke",hpv)
    hv2S.Color=Color3.fromRGB(0,0,0); hv2S.Thickness=1.2

    espData[obj]={hl,bb}
    return espData[obj]
end

local function updateESP(obj, label, hpPct, maxHp, subLabel)
    local e=espData[obj]; if not e then return end
    local bb=e[2]; if not bb or not bb.Parent then return end
    local nm=bb:FindFirstChild("_nm"); if nm then nm.Text=label or "" end
    local sub=bb:FindFirstChild("_sub"); if sub then sub.Text=subLabel or "" end
    local bg=bb:FindFirstChild("_hpbg"); if not bg then return end
    local fill=bg:FindFirstChild("_hpf"); local txt=bg:FindFirstChild("_hpt")
    local pct=math.clamp(hpPct or 1, 0, 1)
    if fill then
        fill.Size=UDim2.new(pct,0,1,0)
        fill.BackgroundColor3=pct>0.6 and Color3.fromRGB(0,235,80)
            or pct>0.3 and Color3.fromRGB(255,190,0) or Color3.fromRGB(240,50,50)
    end
    if txt then txt.Text=math.round(pct*100).."%" end
    local hpv=bb:FindFirstChild("_hpv")
    if hpv and maxHp and maxHp>0 then
        hpv.Text=math.round(pct*maxHp).." / "..math.round(maxHp).." HP"
    end
end

local function removeESP(obj)
    local e=espData[obj]; if not e then return end
    for _,v in ipairs(e) do if v and v.Parent then v:Destroy() end end
    espData[obj]=nil
end

local function clearAllESP()
    for o in pairs(espData) do removeESP(o) end
end

-- ── DRAWING ───────────────────────────────────────────────────
local drawOK = pcall(function() local t=Drawing.new("Line"); t:Remove() end)
local tracerLines={}
local fovCircle, crosshairDot
local skeletonLines={}

local function ensureDrawing()
    if not drawOK then return end
    if not fovCircle then
        pcall(function()
            fovCircle=Drawing.new("Circle")
            fovCircle.Visible=false; fovCircle.Thickness=1.5
            fovCircle.Color=Color3.fromRGB(255,255,255)
            fovCircle.Transparency=0.6; fovCircle.Filled=false
        end)
    end
    if not crosshairDot then
        pcall(function()
            crosshairDot=Drawing.new("Circle")
            crosshairDot.Visible=false; crosshairDot.Radius=3
            crosshairDot.Filled=true; crosshairDot.Color=Color3.fromRGB(255,80,80)
            crosshairDot.Transparency=1
        end)
    end
end

local function updateTracers()
    for _,ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
    tracerLines={}
    if not drawOK or not S.tracers then return end
    local cam=WS.CurrentCamera; if not cam then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        local phrp=char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        local sp,onScreen=cam:WorldToViewportPoint(phrp.Position)
        if onScreen then
            pcall(function()
                local ln=Drawing.new("Line")
                ln.From=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                ln.To=Vector2.new(sp.X,sp.Y)
                ln.Color=Color3.fromRGB(240,50,50)
                ln.Thickness=1; ln.Transparency=1; ln.Visible=true
                table.insert(tracerLines,ln)
            end)
        end
    end
end

-- Skeleton: draw lines between character body parts
local BONE_PAIRS = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

local function updateSkeleton()
    for _,ln in pairs(skeletonLines) do pcall(function() ln:Remove() end) end
    skeletonLines={}
    if not drawOK or not S.skeletonESP then return end
    local cam=WS.CurrentCamera; if not cam then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        for _,pair in ipairs(BONE_PAIRS) do
            local p1=char:FindFirstChild(pair[1])
            local p2=char:FindFirstChild(pair[2])
            if p1 and p2 then
                local sp1,on1=cam:WorldToViewportPoint(p1.Position)
                local sp2,on2=cam:WorldToViewportPoint(p2.Position)
                if on1 and on2 then
                    pcall(function()
                        local ln=Drawing.new("Line")
                        ln.From=Vector2.new(sp1.X,sp1.Y)
                        ln.To=Vector2.new(sp2.X,sp2.Y)
                        ln.Color=Color3.fromRGB(255,255,80)
                        ln.Thickness=1; ln.Transparency=0.85; ln.Visible=true
                        table.insert(skeletonLines,ln)
                    end)
                end
            end
        end
    end
end

local function updateOverlays()
    if not drawOK then return end
    local cam=WS.CurrentCamera; if not cam then return end
    local cx,cy=cam.ViewportSize.X/2, cam.ViewportSize.Y/2
    if fovCircle then pcall(function()
        fovCircle.Radius=S.aimbotFOV; fovCircle.Position=Vector2.new(cx,cy); fovCircle.Visible=S.showFOV
    end) end
    if crosshairDot then pcall(function()
        crosshairDot.Position=Vector2.new(cx,cy); crosshairDot.Visible=S.showCrosshair
    end) end
end

-- ── DOWNED + LOOT DETECTION ───────────────────────────────────
local DOWNED_KEYS={"downed","ko","knocked","knockedout","incapacitated","down","bled","bleedout"}
local function isDowned(char)
    if not char then return false end
    for _,k in ipairs({"Downed","KO","Knocked","KnockedOut","Incapacitated","Down"}) do
        local v=char:GetAttribute(k); if v==true then return true end
    end
    for _,d in ipairs(char:GetDescendants()) do
        if d:IsA("BoolValue") then
            local nm=d.Name:lower()
            for _,k in ipairs(DOWNED_KEYS) do
                if nm:find(k) and d.Value then return true end
            end
        end
    end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health<=0 and char.Parent then return true end
    return false
end

local LOOT_KEYWORDS={
    "m4","ak","ar","usp","glock","pistol","revolver","shotgun","smg","mp5","rifle",
    "sniper","awp","deagle","desert","beretta","magnum","p90","mac","uzi",
    "knife","bat","sword","crowbar",
    "cash","money","bag","loot","drug","cocaine","weed","contraband","package",
    "briefcase","wallet","jewel","gold","diamond",
}
local IGNORE_MODELS={Terrain=true,Camera=true,Workspace=true}

local function isCriminalityLoot(obj)
    if IGNORE_MODELS[obj.Name] then return false end
    if not (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart")) then return false end
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local nm=obj.Name:lower()
    for _,k in ipairs(LOOT_KEYWORDS) do if nm:find(k) then return true end end
    for _,d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at=(d.ActionText or ""):lower()
            if at:find("pick") or at:find("grab") or at:find("take") or at:find("collect") then return true end
        end
        if d:IsA("ClickDetector") then return true end
    end
    return false
end

-- ── FIND NEAREST ─────────────────────────────────────────────
local function findNearest(radius)
    local hrp=getHRP(); if not hrp then return nil,nil end
    radius=radius or 9999
    local best,bestDist,bestHRP=nil,radius+1,nil
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        local phrp=char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health>0 then
            local d=(hrp.Position-phrp.Position).Magnitude
            if d<bestDist then best=plr; bestDist=d; bestHRP=phrp end
        end
    end
    return best,bestHRP
end

-- Aimbot target: nearest player inside FOV circle
local function findAimbotTarget()
    local cam=WS.CurrentCamera; if not cam then return nil end
    local hrp=getHRP(); if not hrp then return nil end
    local best, bestDist = nil, S.aimbotFOV+1
    local cx=cam.ViewportSize.X/2; local cy=cam.ViewportSize.Y/2

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then continue end
        if S.ignoreKnocked and isDowned(char) then continue end
        if S.teamCheck then
            if plr.Team and LP.Team and plr.Team==LP.Team then continue end
        end
        local targetPart=char:FindFirstChild(S.aimbotPart) or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end
        local sp,onScreen=cam:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        local dist=math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2)
        if dist<bestDist then bestDist=dist; best=targetPart end
    end
    return best
end

-- ── AIMBOT ────────────────────────────────────────────────────
local aimbotActive=false
local function doAimbot()
    if not aimbotActive then return end
    local target=findAimbotTarget(); if not target then return end
    local cam=WS.CurrentCamera; if not cam then return end
    local targetCF=CFrame.new(cam.CFrame.Position, target.Position)
    local smooth=math.clamp(S.aimbotSmooth, 0.05, 1.0)
    cam.CFrame=cam.CFrame:Lerp(targetCF, smooth)
end

-- Trigger bot: fire if crosshair on target
local triggerDebounce=false
local function doTriggerBot()
    if triggerDebounce then return end
    local cam=WS.CurrentCamera; if not cam then return end
    local origin=cam.CFrame.Position
    local dir=cam.CFrame.LookVector * 1000
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={LP.Character}
    params.FilterType=Enum.RaycastFilterType.Exclude
    local result=WS:Raycast(origin, dir, params)
    if not result then return end
    local hit=result.Instance
    local model=hit:FindFirstAncestorOfClass("Model")
    if not model then return end
    local plr=Players:GetPlayerFromCharacter(model)
    if not plr or plr==LP then return end
    local hum=model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return end
    triggerDebounce=true
    -- Simulate fire via VirtualInputManager
    pcall(function()
        local vim=game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0,0,0,false,game,0)
    end)
    task.wait(0.1)
    triggerDebounce=false
end

-- ── GUN MODS ─────────────────────────────────────────────────
-- These scan for gun-related scripts/values in the character's equipped tool
local function applyGunMods()
    local char=LP.Character; if not char then return end
    local tool=char:FindFirstChildOfClass("Tool"); if not tool then return end
    for _,d in ipairs(tool:GetDescendants()) do
        local nm=d.Name:lower()
        -- No recoil: zero out recoil values
        if S.noRecoil and (nm:find("recoil") or nm:find("kickback")) then
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                pcall(function() d.Value=0 end)
            end
        end
        -- No spread
        if S.noSpread and (nm:find("spread") or nm:find("accuracy") or nm:find("bloom")) then
            if d:IsA("NumberValue") then pcall(function() d.Value=0 end) end
        end
        -- No sway
        if S.noSway and (nm:find("sway") or nm:find("bob")) then
            if d:IsA("NumberValue") then pcall(function() d.Value=0 end) end
        end
        -- Fast fire rate
        if S.fastFire and (nm:find("firerate") or nm:find("fire_rate") or nm:find("rpm") or nm:find("cooldown") or nm:find("delay")) then
            if d:IsA("NumberValue") then pcall(function() d.Value=math.min(d.Value, 0.03) end) end
        end
        -- Instant reload
        if S.instReload and (nm:find("reloadtime") or nm:find("reload_time") or nm:find("reloadspeed")) then
            if d:IsA("NumberValue") then pcall(function() d.Value=0.01 end) end
        end
        -- Infinite ammo
        if S.infAmmo and (nm:find("ammo") or nm:find("bullets") or nm:find("magazine") or nm:find("clip")) then
            if d:IsA("IntValue") or d:IsA("NumberValue") then
                pcall(function() d.Value=math.max(d.Value, 999) end)
            end
        end
    end
    -- Also patch attributes
    for k,v in pairs(tool:GetAttributes()) do
        local nm=k:lower()
        if S.noRecoil and (nm:find("recoil") or nm:find("kick")) then
            pcall(function() tool:SetAttribute(k,0) end)
        end
        if S.noSpread and (nm:find("spread") or nm:find("bloom") or nm:find("accuracy")) then
            pcall(function() tool:SetAttribute(k,0) end)
        end
        if S.infAmmo and (nm:find("ammo") or nm:find("bullets") or nm:find("magazine") or nm:find("clip")) then
            pcall(function() tool:SetAttribute(k,999) end)
        end
        if S.fastFire and (nm:find("firerate") or nm:find("cooldown") or nm:find("delay")) then
            if type(v)=="number" then pcall(function() tool:SetAttribute(k,0.03) end) end
        end
        if S.instReload and nm:find("reload") then
            if type(v)=="number" then pcall(function() tool:SetAttribute(k,0.01) end) end
        end
    end
end

-- ── SURVIVAL ─────────────────────────────────────────────────
-- Auto bandage / heal: scans inventory + character for heal items and uses them
local healRunning=false
local function doAutoHeal()
    if healRunning then return end
    local hum=getHum(); if not hum then return end
    local hp=hum.Health; local mx=hum.MaxHealth
    -- only trigger if below 60%
    if (mx>0 and hp/mx > 0.6) then return end
    healRunning=true

    local HEAL_WORDS={"bandage","medkit","heal","first","aid","health","kit","inject","syringe","pill"}

    -- Check backpack + character for heal tools
    local function tryHeal(container)
        if not container then return end
        for _,item in ipairs(container:GetChildren()) do
            local nm=item.Name:lower()
            local isHeal=false
            for _,w in ipairs(HEAL_WORDS) do if nm:find(w) then isHeal=true; break end end
            if not isHeal then continue end
            -- Equip and activate
            if item:IsA("Tool") then
                pcall(function() item.Parent=LP.Character end)
                task.wait(0.05)
                for _,d in ipairs(item:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function() d.Enabled=true; d.MaxActivationDistance=20; d.HoldDuration=0 end)
                        pcall(fireprompt,d)
                    end
                end
                -- Try activating the tool
                pcall(function()
                    local vim=game:GetService("VirtualInputManager")
                    vim:SendMouseButtonEvent(0,0,0,true,game,0)
                    task.wait(0.1)
                    vim:SendMouseButtonEvent(0,0,0,false,game,0)
                end)
                task.wait(0.3)
                -- Put back in backpack
                pcall(function() item.Parent=LP.Backpack end)
            end
        end
    end
    tryHeal(LP.Backpack)
    tryHeal(LP.Character)
    task.wait(1)
    healRunning=false
end

-- Anti-bleed: max out bleed/bleedout values and disable bleed scripts
local function doAntiBleed()
    local function scan(root)
        if not root then return end
        for _,d in ipairs(root:GetDescendants()) do
            local nm=d.Name:lower()
            if (d:IsA("NumberValue") or d:IsA("IntValue")) and
               (nm:find("bleed") or nm:find("blood") or nm:find("wound") or nm:find("damage")) then
                pcall(function() d.Value=0 end)
            end
            if d:IsA("BoolValue") and (nm:find("bleed") or nm:find("bleeding")) then
                pcall(function() d.Value=false end)
            end
            if d:IsA("LocalScript") and (nm:find("bleed") or nm:find("damage") or nm:find("wound")) then
                pcall(function() d.Disabled=true end)
            end
        end
    end
    scan(LP.Character)
    -- Attributes
    local char=LP.Character
    if char then
        for k,v in pairs(char:GetAttributes()) do
            local nm=k:lower()
            if nm:find("bleed") or nm:find("blood") or nm:find("wound") then
                if type(v)=="number" then pcall(function() char:SetAttribute(k,0) end)
                elseif type(v)=="boolean" then pcall(function() char:SetAttribute(k,false) end)
                end
            end
        end
    end
end

-- Anti-down: prevent entering downed/ragdoll states
local antiDownConns={}
local function setupAntiDown()
    for _,c in ipairs(antiDownConns) do pcall(function() c:Disconnect() end) end
    antiDownConns={}
    if not S.antiDown then return end
    local hum=getHum(); if not hum then return end
    for _,st in ipairs({
        Enum.HumanoidStateType.Dead,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.GettingUp,
    }) do
        pcall(function() hum:SetStateEnabled(st,false) end)
    end
    local ok,c=pcall(function()
        return hum.StateChanged:Connect(function(_,new)
            if not S.antiDown then return end
            if new==Enum.HumanoidStateType.Dead or new==Enum.HumanoidStateType.Ragdoll
               or new==Enum.HumanoidStateType.FallingDown then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    hum.Health=math.max(hum.Health, 1)
                end)
            end
        end)
    end)
    if ok and c then table.insert(antiDownConns,c) end
end

-- ── FLY ───────────────────────────────────────────────────────
local flyConn, bv, bg_fly
local function setFly(on)
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn=nil end
    if bv  then pcall(function() bv:Destroy()  end); bv=nil  end
    if bg_fly then pcall(function() bg_fly:Destroy() end); bg_fly=nil end
    if not on then
        local hum=getHum()
        if hum then pcall(function() hum.PlatformStand=false end) end
        return
    end
    local hrp=getHRP(); if not hrp then return end
    local hum=getHum(); if hum then pcall(function() hum.PlatformStand=true end) end

    bv=Instance.new("BodyVelocity",hrp)
    bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1e5,1e5,1e5)
    bg_fly=Instance.new("BodyGyro",hrp)
    bg_fly.MaxTorque=Vector3.new(1e5,1e5,1e5); bg_fly.P=1e4

    flyConn=RunService.RenderStepped:Connect(function()
        if not S.fly then setFly(false); return end
        local h=getHRP(); if not h then return end
        local cam=WS.CurrentCamera; if not cam then return end
        local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        local flySpeed=60
        if bv then bv.Velocity=dir.Magnitude>0 and dir.Unit*flySpeed or Vector3.zero end
        if bg_fly then bg_fly.CFrame=cam.CFrame end
    end)
end

-- ── AUTO ROB (nearest downed player) ─────────────────────────
local robRunning=false
local function doAutoRob()
    if robRunning then return end
    robRunning=true
    local myHRP=getHRP(); if not myHRP then robRunning=false; return end
    local savedCF=myHRP.CFrame

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        if not isDowned(char) then continue end
        local phrp=char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end

        safeTP(CFrame.new(phrp.Position+Vector3.new(0,2,1.5)))
        task.wait(0.12)

        for _,d in ipairs(char:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at=(d.ActionText or ""):lower()
                if at:find("rob") or at:find("loot") or at:find("search") or at:find("steal") or at:find("take") then
                    pcall(function() d.Enabled=true; d.MaxActivationDistance=20; d.HoldDuration=0; d.RequiresLineOfSight=false end)
                    pcall(fireprompt,d); pcall(fireprompt,d,0)
                    task.wait(0.1)
                    pcall(fireprompt,d)
                end
            end
        end
        task.wait(0.3)
    end

    local h=getHRP()
    if h and savedCF then safeTP(savedCF) end
    task.wait(1)
    robRunning=false
end

-- ── AUTO LOOT (pick up dropped items) ─────────────────────────
local lootRunning=false
local function doAutoLoot()
    if lootRunning then return end
    lootRunning=true
    local hrp=getHRP(); if not hrp then lootRunning=false; return end
    local savedCF=hrp.CFrame

    for _,obj in ipairs(WS:GetChildren()) do
        if not isCriminalityLoot(obj) then continue end
        if not obj.Parent then continue end
        local root=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
        if not root then continue end
        safeTP(CFrame.new(root.Position+Vector3.new(0,3,0)))
        task.wait(0.3)
        if obj:IsA("Tool") then pcall(function() obj.Parent=LP.Backpack end) end
        for _,d in ipairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function() d.Enabled=true; d.HoldDuration=0; d.MaxActivationDistance=50; d.RequiresLineOfSight=false end)
                pcall(fireprompt,d); pcall(fireprompt,d,0)
            end
            if d:IsA("ClickDetector") then
                pcall(function() d.MaxActivationDistance=50 end)
                pcall(fireclick,d)
            end
        end
        task.wait(0.3)
    end

    local h=getHRP()
    if h and savedCF then safeTP(savedCF) end
    task.wait(1.5)
    lootRunning=false
end

-- ── FULLBRIGHT ────────────────────────────────────────────────
local origLighting={}
local function applyFullbright(on)
    if on then
        origLighting.Brightness=Lighting.Brightness
        origLighting.ClockTime=Lighting.ClockTime
        origLighting.GlobalShadows=Lighting.GlobalShadows
        origLighting.FogEnd=Lighting.FogEnd
        origLighting.FogStart=Lighting.FogStart
        pcall(function()
            Lighting.Brightness=2; Lighting.ClockTime=14
            Lighting.GlobalShadows=false; Lighting.FogEnd=1e6; Lighting.FogStart=1e6
        end)
        for _,e in ipairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                pcall(function() e.Enabled=false end)
            end
        end
    else
        pcall(function()
            Lighting.Brightness=origLighting.Brightness or 1
            Lighting.ClockTime=origLighting.ClockTime or 14
            Lighting.GlobalShadows=(origLighting.GlobalShadows~=nil) and origLighting.GlobalShadows or true
            Lighting.FogEnd=origLighting.FogEnd or 1000
            Lighting.FogStart=origLighting.FogStart or 0
        end)
        for _,e in ipairs(Lighting:GetChildren()) do
            if e:IsA("Atmosphere") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                pcall(function() e.Enabled=true end)
            end
        end
    end
end

-- ── INF STAMINA ───────────────────────────────────────────────
local function doInfStam()
    local function maxVal(d) pcall(function() d.Value=1e6 end) end
    local function scan(root)
        if not root then return end
        for _,d in ipairs(root:GetDescendants()) do
            local nm=d.Name:lower()
            if (d:IsA("NumberValue") or d:IsA("IntValue")) and
               (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then maxVal(d) end
            if d:IsA("LocalScript") and (nm:find("stam") or nm:find("sprint") or nm:find("energy")) then
                pcall(function() d.Disabled=true end)
            end
        end
    end
    local char=LP.Character
    if char then
        for k,v in pairs(char:GetAttributes()) do
            local nm=k:lower()
            if type(v)=="number" and (nm:find("stam") or nm:find("energy") or nm:find("sprint") or nm:find("run")) then
                pcall(function() char:SetAttribute(k,1e6) end)
            end
        end
        scan(char)
    end
    scan(LP:FindFirstChild("PlayerGui"))
    scan(LP:FindFirstChild("PlayerData"))
    scan(LP:FindFirstChild("Values"))
    scan(LP:FindFirstChild("Stats"))
    local hum=getHum()
    if hum then pcall(function()
        local spd=S.speedHack and S.speed or 24
        if hum.WalkSpeed<spd then hum.WalkSpeed=spd end
    end) end
end

-- ── AUTO OPEN DOORS ───────────────────────────────────────────
-- Cache doors once; update on DescendantAdded/Removing to avoid scanning every 0.5s
local doorCache={}
local function isDoorModel(nm)
    return nm:match("^Door") or nm:match("N_ARM_Door") or nm:match("^Elevator") or nm:match("DoubleDoors")
end
local function rebuildDoorCache()
    doorCache={}
    for _,obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Model") then
            local nm=obj.Name; local match=isDoorModel(nm)
            if not match then
                local vals=obj:FindFirstChild("Values")
                if vals and vals:FindFirstChild("DoubleDoors") then match=true end
            end
            if match then table.insert(doorCache,obj) end
        end
    end
end
rebuildDoorCache()
WS.DescendantAdded:Connect(function(obj)
    if not obj:IsA("Model") then return end
    local nm=obj.Name; local match=isDoorModel(nm)
    if not match then
        local vals=obj:FindFirstChild("Values")
        if vals and vals:FindFirstChild("DoubleDoors") then match=true end
    end
    if match then table.insert(doorCache,obj) end
end)
WS.DescendantRemoving:Connect(function(obj)
    for i,v in ipairs(doorCache) do
        if v==obj then table.remove(doorCache,i); break end
    end
end)

local function doAutoOpenDoors()
    local hrp=getHRP(); if not hrp then return end
    for _,obj in ipairs(doorCache) do
        if not obj.Parent then continue end
        local root=obj:FindFirstChildWhichIsA("BasePart")
        if not root or (hrp.Position-root.Position).Magnitude>60 then continue end
        for _,pp in ipairs(obj:GetDescendants()) do
            if pp:IsA("ProximityPrompt") then
                pcall(function() pp.Enabled=true; pp.MaxActivationDistance=70; pp.HoldDuration=0 end)
                pcall(fireprompt,pp)
            elseif pp:IsA("ClickDetector") then
                pcall(function() pp.MaxActivationDistance=70 end)
                pcall(fireclick,pp)
            end
        end
    end
end

-- ── AUTO RESPAWN ──────────────────────────────────────────────
local lastRespawn=0
local function doAutoRespawn()
    local hum=getHum()
    if not (hum and hum.Health<=0) then return end
    if (tick()-lastRespawn)<4 then return end
    lastRespawn=tick()
    pcall(function()
        local RS=game:GetService("ReplicatedStorage")
        local events=RS:WaitForChild("Events",3)
        if not events then return end
        local deathRespawn=events:WaitForChild("DeathRespawn",3)
        if not deathRespawn then return end
        deathRespawn:InvokeServer("KMG4R904")
    end)
end

-- ── AUTO SPRINT (one-shot apply, not per-frame) ──────────────
local function applyAutoSprint()
    if not S.autoSprint then return end
    local hum=getHum()
    if hum then pcall(function() hum.WalkSpeed=24 end) end
end

-- ── ANTI PICKUP ───────────────────────────────────────────────
local function doAntiPickup()
    local char=LP.Character; if not char then return end
    for _,d in ipairs(char:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at=(d.ActionText or ""):lower()
            if at:find("carry") or at:find("rob") or at:find("grab") or at:find("pick")
               or at:find("execute") or at:find("finish") or at:find("revive") or at:find("search")
               or d.KeyboardKeyCode==Enum.KeyCode.Q or d.KeyboardKeyCode==Enum.KeyCode.E then
                pcall(function() d.Enabled=false end)
            end
        end
    end
end

-- ── AUTO FINISHER ─────────────────────────────────────────────
local finisherRunning=false
local function doAutoFinisher()
    if finisherRunning then return end
    finisherRunning=true
    local myHRP=getHRP(); if not myHRP then finisherRunning=false; return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character; if not char then continue end
        if not isDowned(char) then continue end
        local phrp=char:FindFirstChild("HumanoidRootPart"); if not phrp then continue end
        if (myHRP.Position-phrp.Position).Magnitude>15 then continue end
        safeTP(CFrame.new(phrp.Position+Vector3.new(0,2,1.5)))
        task.wait(0.15)
        -- Press F (FINISH key in Criminality)
        pcall(function()
            local vim=game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true,Enum.KeyCode.F,false,game)
            task.wait(0.1)
            vim:SendKeyEvent(false,Enum.KeyCode.F,false,game)
        end)
        -- Fallback: proximity prompts
        for _,d in ipairs(char:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at=(d.ActionText or ""):lower()
                if at:find("execute") or at:find("finish") or at:find("kill") or at:find("stab") then
                    pcall(function() d.Enabled=true; d.MaxActivationDistance=20; d.HoldDuration=0; d.RequiresLineOfSight=false end)
                    pcall(fireprompt,d)
                end
            end
        end
        task.wait(0.3)
    end
    finisherRunning=false
end

-- ── ESP TICK ─────────────────────────────────────────────────
local function getTeamColor(plr)
    pcall(function()
        local ts=game:GetService("Teams")
        for _,t in ipairs(ts:GetTeams()) do
            if plr.Team==t then return t.TeamColor.Color end
        end
    end)
    local char=plr.Character
    if char then
        local role=char:GetAttribute("Role") or char:GetAttribute("Team") or char:GetAttribute("Faction")
        if role then
            local rs=tostring(role):lower()
            if rs:find("cop") or rs:find("police") or rs:find("law") then
                return Color3.fromRGB(80,140,255)
            end
        end
    end
    return Color3.fromRGB(255,80,80)
end

local function getHeldWeapon(char)
    if not char then return "" end
    local tool=char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or ""
end

local function getCashAmount(plr)
    -- Try player data / leaderstats
    for _,folder in ipairs({"leaderstats","PlayerData","Values","Stats"}) do
        local f=plr:FindFirstChild(folder)
        if f then
            for _,d in ipairs(f:GetChildren()) do
                local nm=d.Name:lower()
                if nm:find("cash") or nm:find("money") or nm:find("dollar") or nm:find("coin") then
                    if d:IsA("IntValue") or d:IsA("NumberValue") then
                        return "$"..tostring(d.Value)
                    end
                end
            end
        end
    end
    return ""
end

local function runESP()
    local myHRP=getHRP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then continue end
        local char=plr.Character
        if char and S.playerESP then
            local hum=char:FindFirstChildOfClass("Humanoid")
            local phrp=char:FindFirstChild("HumanoidRootPart")
            local hp=hum and hum.Health or 0
            local mxhp=hum and hum.MaxHealth or 100
            local pct=mxhp>0 and (hp/mxhp) or 1
            local dist=(myHRP and phrp) and math.round((myHRP.Position-phrp.Position).Magnitude) or 0
            local downed=isDowned(char)
            local visible=phrp and isVisible(phrp)

            -- Visibility color mode
            local color
            if S.visibilityColor then
                color=visible and Color3.fromRGB(240,50,50) or Color3.fromRGB(255,190,0)
            elseif downed then
                color=Color3.fromRGB(160,160,160)
            else
                color=getTeamColor(plr)
            end

            local label=plr.Name.." ["..dist.."m]"..(downed and " [DOWN]" or "")
            local sub=""
            if S.weaponESP then sub=sub..getHeldWeapon(char) end
            if S.cashESP then
                local cash=getCashAmount(plr)
                if cash~="" then sub=sub..(sub~="" and "  " or "")..cash end
            end

            getOrMakeESP(char, color)
            updateESP(char, label, pct, mxhp, sub)
        elseif espData[char] then removeESP(char) end
    end

    if S.lootESP then
        for _,obj in ipairs(WS:GetChildren()) do
            if isCriminalityLoot(obj) then
                local root=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                local dist=(myHRP and root) and math.round((myHRP.Position-root.Position).Magnitude) or 0
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
    if S.antiDown    then setupAntiDown() end
    if S.fly         then setFly(true) end
end)

-- ── INPUT: AIMBOT HOLD KEY + F6 ──────────────────────────────
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==S.aimbotKey then aimbotActive=true end
    if inp.KeyCode==Enum.KeyCode.F6 then
        for _,c in pairs(LOOPS) do pcall(function() c:Disconnect() end) end
        pcall(function() setFly(false) end)
        clearAllESP()
        applyFullbright(false)
        for _,ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
        for _,ln in pairs(skeletonLines) do pcall(function() ln:Remove() end) end
        tracerLines={}; skeletonLines={}
        if fovCircle    then pcall(function() fovCircle.Visible=false    end) end
        if crosshairDot then pcall(function() crosshairDot.Visible=false end) end
        local pg=LP:FindFirstChild("PlayerGui")
        if pg then
            for _,g in ipairs(pg:GetChildren()) do
                if g.Name:find("Rayfield") or g.Name:find("Valtix") then pcall(function() g:Destroy() end) end
            end
        end
    end
end)
UIS.InputEnded:Connect(function(inp,gpe)
    if inp.KeyCode==S.aimbotKey then aimbotActive=false end
end)

-- ── LOOPS ─────────────────────────────────────────────────────
local LOOPS={}

LOOPS.heartbeat=RunService.Heartbeat:Connect(function()
    if S.speedHack then
        local hum=getHum()
        if hum then pcall(function() hum.WalkSpeed=S.speed end) end
    end
    if S.customJump then
        local hum=getHum()
        if hum then pcall(function() hum.JumpPower=S.jumpPower end) end
    end
    if S.infStam then doInfStam() end
    if S.antiFallDmg or S.noFallDmg then
        local hrp=getHRP()
        if hrp then pcall(function()
            local vel=hrp.AssemblyLinearVelocity
            if vel.Y<-80 then hrp.AssemblyLinearVelocity=Vector3.new(vel.X,-20,vel.Z) end
        end) end
    end
    if S.bunnyHop then
        local hum=getHum()
        if hum then
            local st=hum:GetState()
            if st==Enum.HumanoidStateType.Landed then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end
    if S.autoJump then
        local hum=getHum(); if hum then pcall(function() hum.Jump=true end) end
    end
    if S.antiKick then
        local hrp=getHRP()
        if hrp then pcall(function()
            local v=hrp.AssemblyLinearVelocity
            local ny=math.min(v.Y,90)
            local horiz=Vector3.new(v.X,0,v.Z)
            local hcap=math.max(S.speed+80,160)
            if horiz.Magnitude>hcap then
                local c=horiz.Unit*hcap
                hrp.AssemblyLinearVelocity=Vector3.new(c.X,ny,c.Z)
            elseif ny~=v.Y then
                hrp.AssemblyLinearVelocity=Vector3.new(v.X,ny,v.Z)
            end
        end) end
    end
    if S.noclip then
        local char=LP.Character
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
            end
        end
    end
    -- Aimbot
    if S.aimbot then doAimbot() end
    -- Gun mods every frame
    applyGunMods()
    -- Anti-bleed
    if S.antiBleed then doAntiBleed() end
end)

local espT=0; local doorT=0; local autoT=0; local tracerT=0; local overlayT=0
local gunT=0; local skeleT=0; local trigT=0

LOOPS.stepped=RunService.Stepped:Connect(function(_,dt)
    espT=espT+dt; doorT=doorT+dt; autoT=autoT+dt
    tracerT=tracerT+dt; overlayT=overlayT+dt
    gunT=gunT+dt; skeleT=skeleT+dt; trigT=trigT+dt

    if espT>=0.25 then espT=0; runESP() end
    if doorT>=0.5 then
        doorT=0
        if S.autoOpenDoors then doAutoOpenDoors() end
        if S.antiPickup    then doAntiPickup() end
    end
    if autoT>=0.4 then
        autoT=0
        if S.autoRespawn  then doAutoRespawn() end
        if S.autoFinisher then task.spawn(doAutoFinisher) end
        if S.autoHeal or S.autoBandage then task.spawn(doAutoHeal) end
        if S.autoRob  then task.spawn(doAutoRob) end
    end
    if tracerT>=0.1 then
        tracerT=0
        if S.tracers then updateTracers()
        elseif #tracerLines>0 then
            for _,ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end
            tracerLines={}
        end
    end
    if skeleT>=0.1 then
        skeleT=0
        if S.skeletonESP then updateSkeleton()
        elseif #skeletonLines>0 then
            for _,ln in pairs(skeletonLines) do pcall(function() ln:Remove() end) end
            skeletonLines={}
        end
    end
    if overlayT>=0.05 then overlayT=0; updateOverlays() end
    if trigT>=0.05 then
        trigT=0
        if S.triggerBot then doTriggerBot() end
    end
    if gunT>=0.1 then gunT=0; applyGunMods() end
end)

-- Auto loot runs in its own task
task.spawn(function()
    while true do
        task.wait(0.1)
        if S.autoLoot then task.spawn(doAutoLoot) end
    end
end)

-- ── RAYFIELD GUI ─────────────────────────────────────────────
local Rayfield=loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window=Rayfield:CreateWindow({
    Name            = "Valtix Hub  |  Criminality  PREMIUM",
    Icon            = 0,
    LoadingTitle    = "Valtix Hub",
    LoadingSubtitle = "Criminality  —  PREMIUM Edition",
    Theme={
        Background=Color3.fromRGB(10,8,8), Header=Color3.fromRGB(16,10,10),
        TextColor=Color3.fromRGB(255,235,235), ElementBackground=Color3.fromRGB(22,14,14),
        SecondaryBackground=Color3.fromRGB(18,10,10), Stroke=Color3.fromRGB(160,0,0),
        SubTextColor=Color3.fromRGB(220,160,160), PlaceholderColor=Color3.fromRGB(180,100,100),
        TabBackground=Color3.fromRGB(12,8,8), TabStroke=Color3.fromRGB(220,30,30),
        TabTextColor=Color3.fromRGB(240,180,180), SelectedTabTextColor=Color3.fromRGB(255,255,255),
        SliderBackground=Color3.fromRGB(22,14,14), SliderProgress=Color3.fromRGB(200,20,20),
        SliderStroke=Color3.fromRGB(160,10,10), ToggleBackground=Color3.fromRGB(22,14,14),
        ToggleEnabled=Color3.fromRGB(220,30,30), ToggleDisabled=Color3.fromRGB(50,35,35),
        ToggleEnabledStroke=Color3.fromRGB(255,50,50), ToggleDisabledStroke=Color3.fromRGB(80,50,50),
        ToggleEnabledOuterStroke=Color3.fromRGB(200,20,20), ToggleDisabledOuterStroke=Color3.fromRGB(40,28,28),
        InputBackground=Color3.fromRGB(18,10,10), InputStroke=Color3.fromRGB(140,0,0),
        PlaceholderText=Color3.fromRGB(180,100,100),
    },
    DisableRayfieldPrompts=true, DisableBuildWarnings=true,
    ConfigurationSaving={Enabled=true, FolderName="Valtix_Criminality", FileName="PREM_Config"},
    KeySystem=false,
})

-- AUTO TAB
local TabAuto=Window:CreateTab("Auto",4483362458)
TabAuto:CreateToggle({Name="Auto Open Doors / Gates",CurrentValue=false,Flag="autoOpenDoors",Callback=function(v) S.autoOpenDoors=v end})
TabAuto:CreateToggle({Name="Auto Sprint",CurrentValue=false,Flag="autoSprint",Callback=function(v) S.autoSprint=v; if v then applyAutoSprint() elseif not S.speedHack then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end end})
TabAuto:CreateToggle({Name="Auto Respawn",CurrentValue=false,Flag="autoRespawn",Callback=function(v) S.autoRespawn=v end})
TabAuto:CreateToggle({Name="Anti Pick-Up (Block Rob / Carry)",CurrentValue=false,Flag="antiPickup",Callback=function(v) S.antiPickup=v end})
TabAuto:CreateToggle({Name="Anti Fall Damage",CurrentValue=false,Flag="antiFallDmg",Callback=function(v) S.antiFallDmg=v end})
TabAuto:CreateToggle({Name="Auto Finisher",CurrentValue=false,Flag="autoFinisher",Callback=function(v) S.autoFinisher=v end})

-- ESP & VISUALS TAB
local TabESP=Window:CreateTab("ESP & Visuals",4483362458)
TabESP:CreateToggle({Name="Player ESP",CurrentValue=false,Flag="playerESP",Callback=function(v) S.playerESP=v; if not v then for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP and plr.Character then removeESP(plr.Character) end end end end})
TabESP:CreateToggle({Name="Loot ESP (Guns / Cash / Bags)",CurrentValue=false,Flag="lootESP",Callback=function(v) S.lootESP=v; if not v then for _,obj in ipairs(WS:GetChildren()) do if isCriminalityLoot(obj) then removeESP(obj) end end end end})
TabESP:CreateToggle({Name="Weapon Held ESP",CurrentValue=false,Flag="weaponESP",Callback=function(v) S.weaponESP=v end})
TabESP:CreateToggle({Name="Cash Amount ESP",CurrentValue=false,Flag="cashESP",Callback=function(v) S.cashESP=v end})
TabESP:CreateToggle({Name="Skeleton ESP",CurrentValue=false,Flag="skeletonESP",Callback=function(v) S.skeletonESP=v end})
TabESP:CreateToggle({Name="Visibility Color (Red=Visible / Yellow=Behind Wall)",CurrentValue=false,Flag="visibilityColor",Callback=function(v) S.visibilityColor=v end})
TabESP:CreateToggle({Name="Tracers",CurrentValue=false,Flag="tracers",Callback=function(v) S.tracers=v; if not v then for _,ln in pairs(tracerLines) do pcall(function() ln:Remove() end) end; tracerLines={} end end})
TabESP:CreateToggle({Name="Crosshair Dot",CurrentValue=false,Flag="showCrosshair",Callback=function(v) S.showCrosshair=v; ensureDrawing(); if crosshairDot then pcall(function() crosshairDot.Visible=v end) end end})
TabESP:CreateToggle({Name="FOV Circle",CurrentValue=false,Flag="showFOV",Callback=function(v) S.showFOV=v; ensureDrawing(); if fovCircle then pcall(function() fovCircle.Visible=v end) end end})
TabESP:CreateToggle({Name="Fullbright + No Fog",CurrentValue=false,Flag="fullbright",Callback=function(v) S.fullbright=v; applyFullbright(v) end})

-- MOVEMENT TAB
local TabMove=Window:CreateTab("Movement",4483362458)
TabMove:CreateToggle({Name="Auto Jump",CurrentValue=false,Flag="autoJump",Callback=function(v) S.autoJump=v end})
TabMove:CreateToggle({Name="Speed Hack",CurrentValue=false,Flag="speedHack",Callback=function(v) S.speedHack=v; if not v and not S.autoSprint then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end end})
TabMove:CreateSlider({Name="Speed Value",Range={16,300},Increment=1,Suffix="studs/s",CurrentValue=32,Flag="speedValue",Callback=function(v) S.speed=v end})
TabMove:CreateToggle({Name="Infinite Stamina",CurrentValue=false,Flag="infStam",Callback=function(v) S.infStam=v end})
TabMove:CreateToggle({Name="Bunny Hop",CurrentValue=false,Flag="bunnyHop",Callback=function(v) S.bunnyHop=v end})
TabMove:CreateToggle({Name="Fly",CurrentValue=false,Flag="fly",Callback=function(v) S.fly=v; setFly(v) end})
TabMove:CreateToggle({Name="Noclip",CurrentValue=false,Flag="noclip",Callback=function(v) S.noclip=v; if not v then local char=LP.Character; if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end end end end end})
TabMove:CreateToggle({Name="No Fall Damage",CurrentValue=false,Flag="noFallDmg",Callback=function(v) S.noFallDmg=v end})
TabMove:CreateToggle({Name="Anti Kick",CurrentValue=true,Flag="antiKick",Callback=function(v) S.antiKick=v end})
TabMove:CreateToggle({Name="Custom Jump Power",CurrentValue=false,Flag="customJump",Callback=function(v) S.customJump=v; if not v then local h=getHum(); if h then pcall(function() h.JumpPower=50 end) end end end})
TabMove:CreateSlider({Name="Jump Power",Range={50,500},Increment=5,Suffix="",CurrentValue=50,Flag="jumpPower",Callback=function(v) S.jumpPower=v end})

-- COMBAT TAB
local TabCombat=Window:CreateTab("Combat",4483362458)
TabCombat:CreateToggle({
    Name="Legit Aimbot (Hold Q)",CurrentValue=false,Flag="aimbot",
    Callback=function(v) S.aimbot=v end,
})
TabCombat:CreateSlider({Name="Aimbot FOV",Range={30,400},Increment=5,Suffix="px",CurrentValue=120,Flag="aimbotFOV",Callback=function(v) S.aimbotFOV=v end})
TabCombat:CreateSlider({Name="Aimbot Smoothness",Range={1,20},Increment=1,Suffix="",CurrentValue=5,Flag="aimbotSmooth",Callback=function(v) S.aimbotSmooth=v/20 end})
TabCombat:CreateToggle({
    Name="Target: Head (off = Body)",CurrentValue=true,Flag="aimbotHead",
    Callback=function(v) S.aimbotPart=v and "Head" or "HumanoidRootPart" end,
})
TabCombat:CreateToggle({Name="Team Check (Skip Teammates)",CurrentValue=true,Flag="teamCheck",Callback=function(v) S.teamCheck=v end})
TabCombat:CreateToggle({Name="Ignore Knocked Targets",CurrentValue=true,Flag="ignoreKnocked",Callback=function(v) S.ignoreKnocked=v end})
TabCombat:CreateToggle({Name="Trigger Bot (Auto-Fire on Target)",CurrentValue=false,Flag="triggerBot",Callback=function(v) S.triggerBot=v end})

-- GUN MODS TAB
local TabGun=Window:CreateTab("Gun Mods",4483362458)
TabGun:CreateToggle({Name="No Recoil",CurrentValue=false,Flag="noRecoil",Callback=function(v) S.noRecoil=v end})
TabGun:CreateToggle({Name="No Spread / No Bloom",CurrentValue=false,Flag="noSpread",Callback=function(v) S.noSpread=v end})
TabGun:CreateToggle({Name="No Sway",CurrentValue=false,Flag="noSway",Callback=function(v) S.noSway=v end})
TabGun:CreateToggle({Name="Fast Fire Rate",CurrentValue=false,Flag="fastFire",Callback=function(v) S.fastFire=v end})
TabGun:CreateToggle({Name="Instant Reload",CurrentValue=false,Flag="instReload",Callback=function(v) S.instReload=v end})
TabGun:CreateToggle({Name="Infinite Ammo",CurrentValue=false,Flag="infAmmo",Callback=function(v) S.infAmmo=v end})

-- SURVIVAL TAB
local TabSurv=Window:CreateTab("Survival",4483362458)
TabSurv:CreateToggle({Name="Auto Bandage / Heal (below 60% HP)",CurrentValue=false,Flag="autoHeal",Callback=function(v) S.autoHeal=v end})
TabSurv:CreateToggle({Name="Anti Bleed",CurrentValue=false,Flag="antiBleed",Callback=function(v) S.antiBleed=v end})
TabSurv:CreateToggle({
    Name="Anti Down (Block Knockout State)",CurrentValue=false,Flag="antiDown",
    Callback=function(v) S.antiDown=v; setupAntiDown() end,
})

-- FARMING TAB
local TabFarm=Window:CreateTab("Farming",4483362458)
TabFarm:CreateToggle({Name="Auto Rob (Loot Nearby Downed Players)",CurrentValue=false,Flag="autoRob",Callback=function(v) S.autoRob=v end})
TabFarm:CreateToggle({Name="Auto Loot (Pick Up Dropped Guns / Cash)",CurrentValue=false,Flag="autoLoot",Callback=function(v) S.autoLoot=v end})

-- TELEPORT TAB
local TabTP=Window:CreateTab("Teleport",4483362458)
local function tpToMapFolder(folderName)
    local mapFolder=WS:FindFirstChild("Map"); if not mapFolder then return end
    local target=mapFolder:FindFirstChild(folderName); if not target then return end
    local root=target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
    if not root then
        for _,child in ipairs(target:GetChildren()) do
            local p=child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart")
            if p then root=p; break end
        end
    end
    if root then safeTP(CFrame.new(root.Position+Vector3.new(0,3,0))) end
end
TabTP:CreateButton({Name="Teleport  →  ATMs (Map/ATMz)",Callback=function() task.spawn(tpToMapFolder,"ATMz") end})
TabTP:CreateButton({Name="Teleport  →  Safes / Registers (Map/BredMakurz)",Callback=function() task.spawn(tpToMapFolder,"BredMakurz") end})
TabTP:CreateButton({Name="Teleport  →  Shop / Armory Dealer (Map/Shopz)",Callback=function() task.spawn(tpToMapFolder,"Shopz") end})
TabTP:CreateButton({Name="Teleport  →  Nearest Player",Callback=function()
    task.spawn(function()
        local _,nearHRP=findNearest(9999)
        if nearHRP then safeTP(CFrame.new(nearHRP.Position+Vector3.new(0,3,2))) end
    end)
end})

-- INFO TAB
local TabInfo=Window:CreateTab("Info",4483362458)
TabInfo:CreateParagraph({
    Title="Criminality  |  PREMIUM Edition",
    Content="F6 = Panic / kill script.\n\nAimbot: hold Q (default). Uses smooth camera lock — does NOT hook __namecall. Works without ban risk.\nGun Mods: client-side; effectiveness depends on how the game validates shots server-side.\nAnti Down: best-effort state block — may not hold against server-authoritative knockouts.\nAuto Rob: TPs to downed players and fires their rob/search prompt.\nTeleport: TP to ATMs, Safes, Shops, or nearest player via the game's Map folder.\n\nUpgrade to PLUS for silent aim, god mode, and full money automation.",
})

-- INIT
task.wait(1)
ensureDrawing()
setupAntiDown()
Rayfield:LoadConfiguration()
