-- Money/FreeHub | Ability Arena | v2.7.1
-- by Money/FreeHub Owner

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Players             = game:GetService("Players")
local RS                  = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService         = game:GetService("HttpService")

local LP = Players.LocalPlayer

local function getChar() return LP.Character end
local function getHum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()
    local c=LP.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end

local JoltReliable
pcall(function()
    JoltReliable = RS:WaitForChild("Files",10)
        :WaitForChild("Shared"):WaitForChild("Components")
        :WaitForChild("Jolt"):WaitForChild("Utils")
        :WaitForChild("Remotes"):WaitForChild("Jolt_Reliable")
end)

local M1_Prefix = string.char(5,85,115,101,77,49,65,16,3,9,84,105,109,101,115,116,97,109,112,2,199)
local M1_Suffix = string.char(3,5,73,110,100,101,120,17,32,3,4,72,105,116,115,16,0,0)

local function nowStamp()
    local t = 0
    pcall(function() t = Workspace:GetServerTimeNow() end)
    if t == 0 then pcall(function() t = os.clock() end) end
    return string.pack("<d", t)
end

local function buildM1() return M1_Prefix .. nowStamp() .. M1_Suffix end

local function buildSkillString(skill, direction)
    direction = direction or "Forward"
    return "\10StartSkillB\003" .. string.char(#skill) .. skill
        .. "\016\003\tDirection\003" .. string.char(#direction) .. direction
        .. "\003\tTimestamp\002" .. nowStamp() .. "\000"
end

local function fireM1()
    if not JoltReliable then return end
    pcall(function() JoltReliable:FireServer(buildM1(), {}) end)
end
local function fireSkill(skill, direction)
    if not JoltReliable then return end
    pcall(function() JoltReliable:FireServer(buildSkillString(skill, direction), {}) end)
end
local function fireDash(direction) fireSkill("Dash", direction) end

local function typingNow()
    local ok, box = pcall(function() return UserInputService:GetFocusedTextBox() end)
    return ok and box ~= nil
end

local function safeClickPoint()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local candidates = {
        Vector2.new(vp.X*0.50, vp.Y*0.62),
        Vector2.new(vp.X*0.50, vp.Y*0.50),
        Vector2.new(vp.X*0.35, vp.Y*0.55),
        Vector2.new(vp.X*0.65, vp.Y*0.55),
        Vector2.new(vp.X*0.50, vp.Y*0.40),
        Vector2.new(vp.X*0.25, vp.Y*0.70),
        Vector2.new(vp.X*0.75, vp.Y*0.70),
        Vector2.new(vp.X*0.50, vp.Y*0.78),
        Vector2.new(vp.X*0.40, vp.Y*0.35),
        Vector2.new(vp.X*0.60, vp.Y*0.35),
    }
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return candidates[1] end
    for _, pt in ipairs(candidates) do
        local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(pt.X, pt.Y) end)
        if ok and objs and #objs == 0 then return pt end
    end
    return nil
end

local function doClick(pt)
    if not pt then return end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, true,  game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, false, game, 0)
    end)
end

local function clickM1()
    if typingNow() then return end
    doClick(safeClickPoint())
end

-- Clicks at target's actual screen position; falls back to safe point if GUI-covered
local function clickAtTarget(target)
    if typingNow() then return end
    local char = target and target.Character
    local tr   = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not tr then doClick(safeClickPoint()); return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local sp, onScreen = cam:WorldToViewportPoint(tr.Position)
    local pt = onScreen and Vector2.new(sp.X, sp.Y) or nil
    if pt then
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        if pg then
            local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(pt.X, pt.Y) end)
            if ok and objs and #objs > 0 then pt = nil end
        end
    end
    doClick(pt or safeClickPoint())
end

local function tapKey(kc)
    if typingNow() then return end
    pcall(function() VirtualInputManager:SendKeyEvent(true,  kc, false, game) end)
    task.wait(0.06)
    pcall(function() VirtualInputManager:SendKeyEvent(false, kc, false, game) end)
end

local S = {
    AntiRagdoll=false, AntiPush=false, AntiVoid=false,
    KillAura=false, KillAuraRange=24, KillAuraFace=true, KillAuraAll=false, KillAuraE=true,
    M1Hitbox=false, M1HitboxSize=35,
    HitboxAbility=false, HitboxAbilitySize=20,
    Fling=false, FlingPower=800,
    AutoM1=false,
    AutoAbility=false, AutoAbilityRange=25,
    CastE=true, CastQ=false, CastR=false, CastT=false,
    AutoDash=false,
    CamLock=false, CamLockRange=120,
    Fly=false, FlySpeed=60,
    Noclip=false,
    SpeedHack=false, Speed=16,
    InfiniteJump=false,
    SpinBot=false, AntiFling=false,
    ESP=false, ESPColor=true, Tracers=false,
    EnemyHighlight=false, HighlightColor="Bright blue",
    FullBright=false,
    AutoFarm=false, FarmTarget=nil,
    AutoPlay=false, AutoPlayRange=100,
    AntiAFK=false, InstantRespawn=false, ClickTP=false,
    GrabDelay=3,
}

local Conns = {}
local function bind(name, conn)
    if Conns[name] then pcall(function() Conns[name]:Disconnect() end) end
    Conns[name] = conn
end

local function enemiesInRange(range)
    local out, root = {}, getRoot()
    if not root then return out end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 and (r.Position-root.Position).Magnitude <= range then
                out[#out+1] = p
            end
        end
    end
    return out
end
local function nearestPlayer(range)
    local best, dist, root = nil, range or math.huge, getRoot()
    if not root then return nil end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position-root.Position).Magnitude
                if d < dist then best, dist = p, d end
            end
        end
    end
    return best
end
local function playerNames()
    local n = {}
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then n[#n+1] = p.Name end end
    return n
end
local function faceTo(pos)
    local root = getRoot()
    if root then root.CFrame = CFrame.new(root.Position, Vector3.new(pos.X, root.Position.Y, pos.Z)) end
end

-- M1 Hitbox Expander
local hbOriginal = {}
local function restoreHitboxes()
    for name, parts in pairs(hbOriginal) do
        local p = Players:FindFirstChild(name)
        local char = p and p.Character
        if char then
            for partName, orig in pairs(parts) do
                local part = char:FindFirstChild(partName)
                if part then pcall(function()
                    part.Size = orig.size; part.Transparency = orig.transp
                    part.CanCollide = orig.collide; part.Massless = orig.massless
                    part.CanTouch = orig.touch; part.Color = orig.color
                    part.Material = orig.material
                end) end
            end
        end
    end
    hbOriginal = {}
end
RunService.Heartbeat:Connect(function()
    if not S.M1Hitbox then
        if next(hbOriginal) then restoreHitboxes() end
        return
    end
    local sz = S.M1HitboxSize
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local char = p.Character
            local h = char:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                for _,partName in ipairs({"Hitbox","HumanoidRootPart"}) do
                    local part = char:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        hbOriginal[p.Name] = hbOriginal[p.Name] or {}
                        if not hbOriginal[p.Name][partName] then
                            hbOriginal[p.Name][partName] = {
                                size=part.Size, transp=part.Transparency,
                                collide=part.CanCollide, massless=part.Massless,
                                touch=part.CanTouch, color=part.Color,
                                material=part.Material
                            }
                        end
                        pcall(function()
                            part.Massless    = true
                            part.CanCollide  = false
                            part.CanQuery    = true
                            part.CanTouch    = false
                            if part.Size.X ~= sz then part.Size = Vector3.new(sz, sz, sz) end
                            part.Transparency = 0.6
                            part.Color       = Color3.fromRGB(255, 50, 50)
                            part.Material    = Enum.Material.ForceField
                        end)
                    end
                end
            end
        end
    end
end)

-- Hitbox Ability (ghost visual sphere; CanQuery/CanTouch off so you can't be hit through it)
local abilityHbPart = nil
local abilityHbBurst = false
local function destroyAbilityHb()
    if abilityHbPart then pcall(function() abilityHbPart:Destroy() end); abilityHbPart = nil end
end
task.spawn(function()
    while task.wait(0.2) do
        if S.HitboxAbility then
            local root = getRoot()
            if not root then continue end
            if not abilityHbPart or abilityHbPart.Parent == nil then
                destroyAbilityHb()
                local sz = S.HitboxAbilitySize
                abilityHbPart = Instance.new("Part")
                abilityHbPart.Name         = "MFHAbilityHB"
                abilityHbPart.Shape        = Enum.PartType.Ball
                abilityHbPart.Anchored     = false
                abilityHbPart.CanCollide   = false
                abilityHbPart.Massless     = true
                abilityHbPart.CastShadow   = false
                abilityHbPart.CanQuery     = false
                abilityHbPart.CanTouch     = false
                abilityHbPart.Transparency = 0.8
                abilityHbPart.Material     = Enum.Material.ForceField
                abilityHbPart.Color        = Color3.fromRGB(100, 200, 255)
                abilityHbPart.Size         = Vector3.new(sz, sz, sz)
                local w = Instance.new("Weld")
                w.Part0 = root; w.Part1 = abilityHbPart; w.Parent = abilityHbPart
                abilityHbPart.Parent = root.Parent
            else
                if not abilityHbBurst then
                    local sz = S.HitboxAbilitySize
                    pcall(function() abilityHbPart.Size = Vector3.new(sz, sz, sz) end)
                end
            end
        else
            destroyAbilityHb()
        end
    end
end)

-- E-key burst: expand the Hitbox Ability sphere for 0.5s on every E press
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode ~= Enum.KeyCode.E then return end
    if not S.HitboxAbility or abilityHbBurst then return end
    task.spawn(function()
        abilityHbBurst = true
        local bsz = S.HitboxAbilitySize * 3
        if abilityHbPart then
            pcall(function() abilityHbPart.Size = Vector3.new(bsz, bsz, bsz) end)
        end
        task.wait(0.5)
        abilityHbBurst = false
        if abilityHbPart then
            pcall(function() abilityHbPart.Size = Vector3.new(S.HitboxAbilitySize, S.HitboxAbilitySize, S.HitboxAbilitySize) end)
        end
    end)
end)

-- Ability Grabber (TP -> E tap -> TP back)
local elementFolder
local function findElementFolder()
    if elementFolder and elementFolder.Parent then return elementFolder end
    elementFolder = Workspace:FindFirstChild("ElementSelection", true)
    return elementFolder
end
local function abilityNames()
    local out = {}
    local f = findElementFolder()
    if f then
        for _,c in ipairs(f:GetChildren()) do
            if c:IsA("BasePart") or c:IsA("Model") then out[#out+1] = c.Name end
        end
        table.sort(out)
    end
    return out
end
local grabbing = false
local function grabAbility(name)
    if grabbing or not name or name == "" then return end
    local f = findElementFolder()
    if not f then
        Rayfield:Notify({Title="Money/FreeHub", Content="ElementSelection not found — are you in the lobby?", Duration=4})
        return
    end
    local pad = f:FindFirstChild(name); if not pad then return end
    local root = getRoot(); if not root then return end
    grabbing = true
    task.spawn(function()
        local backCF = root.CFrame
        local padPos = pad:IsA("BasePart") and pad.Position or pad:GetPivot().Position
        pcall(function() root.CFrame = CFrame.new(padPos + Vector3.new(0, 4, 0)) end)
        task.wait(0.5)
        tapKey(Enum.KeyCode.E)
        -- give time to actually pick the ability before TP-ing back
        task.wait(S.GrabDelay)
        local root2 = getRoot()
        if root2 then pcall(function() root2.CFrame = backCF end) end
        grabbing = false
    end)
end

local BAD_STATES = {
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Physics,
    Enum.HumanoidStateType.PlatformStanding,
}
local function setRagdollStates(hum, enabled)
    for _,st in ipairs(BAD_STATES) do
        pcall(function() hum:SetStateEnabled(st, enabled) end)
    end
end

local function applyCharacter(char)
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then return end

    bind("antiRag", hum.StateChanged:Connect(function(_, new)
        if not S.AntiRagdoll then return end
        if new == Enum.HumanoidStateType.Physics
        or new == Enum.HumanoidStateType.PlatformStanding
        or new == Enum.HumanoidStateType.FallingDown
        or new == Enum.HumanoidStateType.Ragdoll then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end))

    bind("respawn", hum.Died:Connect(function()
        if S.InstantRespawn then
            task.delay(0.2, function() pcall(function() LP:LoadCharacter() end) end)
        end
    end))

    if S.AntiRagdoll then setRagdollStates(hum, false) end
    if S.SpeedHack   then pcall(function() hum.WalkSpeed = S.Speed end) end
end

LP.CharacterAdded:Connect(function(char)
    destroyAbilityHb()
    task.wait(0.2)
    pcall(applyCharacter, char)
end)
if LP.Character then pcall(applyCharacter, LP.Character) end

local STUN_ATTRS = {"Ragdoll","Ragdolled","Stunned","Stun","Knocked","Knockback","KO","Downed"}
local ragClock = 0
RunService.Heartbeat:Connect(function(dt)
    if not S.AntiRagdoll then return end
    local hum, char = getHum(), getChar()
    if not (hum and char) then return end
    pcall(function()
        hum.PlatformStand = false
        hum.Sit = false
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.PlatformStanding then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    ragClock += dt
    if ragClock >= 0.5 then
        ragClock = 0
        setRagdollStates(hum, false)
        for _,attr in ipairs(STUN_ATTRS) do
            pcall(function()
                if char:GetAttribute(attr) == true then char:SetAttribute(attr, false) end
            end)
        end
        for _,d in ipairs(char:GetDescendants()) do
            if d:IsA("BallSocketConstraint") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("Motor6D") then
                pcall(function() if d.Enabled == false then d.Enabled = true end end)
            elseif d:IsA("BoolValue") then
                local n = d.Name:lower()
                if (n:find("ragdoll") or n:find("stun") or n:find("knock") or n:find("down")) and d.Value then
                    pcall(function() d.Value = false end)
                end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if S.Fly then return end
    if not (S.AntiPush or S.AntiFling) then return end
    local char, root, hum = getChar(), getRoot(), getHum()
    if not (char and root) then return end
    if S.AntiFling and not S.Fling then
        for _,pt in ipairs(char:GetDescendants()) do
            if pt:IsA("BasePart") then
                if pt.AssemblyAngularVelocity.Magnitude > 20 then
                    pt.AssemblyAngularVelocity = Vector3.zero
                end
                if pt.AssemblyLinearVelocity.Magnitude > 130 then
                    pt.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
    end
    if S.AntiPush then
        local v   = root.AssemblyLinearVelocity
        local cap = ((hum and hum.WalkSpeed) or 16) * 2.5 + 25
        local hv  = Vector3.new(v.X, 0, v.Z)
        if hv.Magnitude > cap then
            root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(v.Y, -90, 60), 0)
        end
    end
end)

local savedSpawnCF = nil
local floatPart, lastSafeCF

local function ensureFloat()
    if not floatPart or floatPart.Parent == nil then
        floatPart = Instance.new("Part")
        floatPart.Name         = "MFHFloat"
        floatPart.Size         = Vector3.new(16, 1, 16)
        floatPart.Anchored     = true
        floatPart.CanCollide   = true
        floatPart.CanQuery     = false
        floatPart.Material     = Enum.Material.ForceField
        floatPart.Color        = Color3.fromRGB(120, 170, 255)
        floatPart.Transparency = 0.6
        floatPart.Parent       = Workspace
    end
    return floatPart
end
local function showFloat(pos)
    local plat = ensureFloat()
    plat.CanCollide   = true
    plat.Transparency = 0.6
    plat.Position     = pos
end
local function hideFloat()
    if floatPart then floatPart.CanCollide = false; floatPart.Transparency = 1 end
end
local function isKillPart(inst)
    if not inst then return false end
    local kb = Workspace:FindFirstChild("KillBricks")
    if kb and inst:IsDescendantOf(kb) then return true end
    return tostring(inst.Name):lower():find("kill") ~= nil
end

RunService.Heartbeat:Connect(function()
    if not S.AntiVoid then
        if floatPart then pcall(function() floatPart:Destroy() end); floatPart = nil end
        return
    end
    local root, hum, char = getRoot(), getHum(), getChar()
    if not (root and hum and char) then return end

    local floor      = hum.FloorMaterial
    local onOurPlate = (floor == Enum.Material.ForceField)

    if floor ~= Enum.Material.Air and floor ~= Enum.Material.Water and not onOurPlate then
        lastSafeCF = root.CFrame
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, floatPart}
    local hit = Workspace:Raycast(root.Position, Vector3.new(0, -2000, 0), params)

    local swimming  = hum:GetState() == Enum.HumanoidStateType.Swimming or floor == Enum.Material.Water
    local overWater = hit ~= nil and hit.Instance ~= nil and hit.Instance:IsA("Terrain") and hit.Material == Enum.Material.Water
    local overVoid  = (hit == nil)
    local overKill  = hit ~= nil and isKillPart(hit.Instance)

    if swimming then
        showFloat(Vector3.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z))
        root.CFrame = root.CFrame + Vector3.new(0, 4, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    elseif overWater and (root.Position.Y - hit.Position.Y) < 12 then
        showFloat(Vector3.new(root.Position.X, hit.Position.Y + 0.5, root.Position.Z))
    elseif overVoid or overKill then
        hideFloat()
        local tpCF = savedSpawnCF or lastSafeCF
        if tpCF then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = tpCF + Vector3.new(0, 5, 0)
        else
            showFloat(root.Position - Vector3.new(0, 6, 0))
        end
    else
        hideFloat()
    end

    local killY = -480
    pcall(function() killY = Workspace.FallenPartsDestroyHeight + 100 end)
    if root.Position.Y < killY then
        local tpCF = savedSpawnCF or lastSafeCF
        if tpCF then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = tpCF + Vector3.new(0, 6, 0)
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if S.InfiniteJump then
        local h = getHum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if S.ClickTP and i.KeyCode == Enum.KeyCode.T then
        pcall(function()
            local m = LP:GetMouse(); local root = getRoot()
            if m and root and m.Hit then root.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0,4,0)) end
        end)
    end
end)

pcall(function()
    LP.Idled:Connect(function()
        if not S.AntiAFK then return end
        local vu = game:GetService("VirtualUser")
        vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end)
end)

local flyBV, flyBG
local flyKeys = {W=false,A=false,S=false,D=false,Up=false,Down=false}
local function flyCleanup()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
end
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local k=i.KeyCode
    if     k==Enum.KeyCode.W           then flyKeys.W=true
    elseif k==Enum.KeyCode.A           then flyKeys.A=true
    elseif k==Enum.KeyCode.S           then flyKeys.S=true
    elseif k==Enum.KeyCode.D           then flyKeys.D=true
    elseif k==Enum.KeyCode.Space       then flyKeys.Up=true
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=true end
end)
UserInputService.InputEnded:Connect(function(i)
    local k=i.KeyCode
    if     k==Enum.KeyCode.W           then flyKeys.W=false
    elseif k==Enum.KeyCode.A           then flyKeys.A=false
    elseif k==Enum.KeyCode.S           then flyKeys.S=false
    elseif k==Enum.KeyCode.D           then flyKeys.D=false
    elseif k==Enum.KeyCode.Space       then flyKeys.Up=false
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=false end
end)
RunService.RenderStepped:Connect(function()
    if not S.Fly then if flyBV then flyCleanup() end return end
    local root = getRoot(); if not root then return end
    if not flyBV or flyBV.Parent ~= root then
        flyCleanup()
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.P=9e4; flyBG.CFrame=root.CFrame; flyBG.Parent=root
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce=Vector3.new(9e9,9e9,9e9); flyBV.Velocity=Vector3.zero; flyBV.Parent=root
    end
    local cam = Workspace.CurrentCamera
    flyBG.CFrame = cam.CFrame
    local dir = Vector3.zero
    if flyKeys.W  then dir += cam.CFrame.LookVector end
    if flyKeys.S  then dir -= cam.CFrame.LookVector end
    if flyKeys.A  then dir -= cam.CFrame.RightVector end
    if flyKeys.D  then dir += cam.CFrame.RightVector end
    if flyKeys.Up   then dir += Vector3.yAxis end
    if flyKeys.Down then dir -= Vector3.yAxis end
    flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit * S.FlySpeed) or Vector3.zero
end)

RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local c = getChar(); if not c then return end
    for _,pt in ipairs(c:GetDescendants()) do
        if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end
    end
end)

RunService.RenderStepped:Connect(function()
    if not S.CamLock then return end
    local tgt = nearestPlayer(S.CamLockRange); if not tgt or not tgt.Character then return end
    local head = tgt.Character:FindFirstChild("Head") or tgt.Character:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local cam = Workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
end)

local highlights = {}
local function clearHighlights()
    for _,h in pairs(highlights) do pcall(function() h:Destroy() end) end
    highlights = {}
end
RunService.Heartbeat:Connect(function()
    if not S.EnemyHighlight then if next(highlights) then clearHighlights() end return end
    for name,h in pairs(highlights) do
        local p = Players:FindFirstChild(name)
        if not p or not p.Character or h.Parent==nil then
            pcall(function() h:Destroy() end); highlights[name]=nil
        end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and not highlights[p.Name] then
            local hl = Instance.new("Highlight")
            hl.FillColor = BrickColor.new(S.HighlightColor).Color
            hl.FillTransparency = 0.6; hl.OutlineColor = Color3.new(1,1,1)
            hl.Adornee = p.Character; hl.Parent = p.Character
            highlights[p.Name] = hl
        end
    end
end)

local espPool = {}
local function clearESP()
    for _,d in pairs(espPool) do
        pcall(function() d.bill:Destroy() end)
        if d.line then pcall(function() d.line:Remove() end) end
    end
    espPool = {}
end
local hasDrawing = (typeof(Drawing) == "table") or (Drawing ~= nil)
local espTimer = 0
RunService.RenderStepped:Connect(function(dt)
    if not S.ESP and not S.Tracers then if next(espPool) then clearESP() end return end
    espTimer += dt
    if espTimer >= 0.4 then
        espTimer = 0
        for name,d in pairs(espPool) do
            local p = Players:FindFirstChild(name)
            if not p or not p.Character then
                pcall(function() d.bill:Destroy() end)
                if d.line then pcall(function() d.line:Remove() end) end
                espPool[name] = nil
            end
        end
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and not espPool[p.Name] then
                local bill = Instance.new("BillboardGui")
                bill.Name="MFHESP"; bill.Adornee=p.Character.Head; bill.Size=UDim2.new(0,200,0,40)
                bill.StudsOffset=Vector3.new(0,2.5,0); bill.AlwaysOnTop=true
                local lbl = Instance.new("TextLabel"); lbl.Parent=bill
                lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
                lbl.Font=Enum.Font.GothamBold; lbl.TextScaled=false; lbl.TextSize=14
                lbl.TextStrokeTransparency=0; lbl.TextColor3=Color3.new(1,1,1)
                bill.Parent = p.Character.Head
                local line
                if hasDrawing then
                    line = Drawing.new("Line"); line.Thickness=1.5; line.Transparency=1
                    line.Color = Color3.fromRGB(120,170,255)
                end
                espPool[p.Name] = {bill=bill, lbl=lbl, line=line}
            end
        end
    end
    local cam = Workspace.CurrentCamera
    for name,d in pairs(espPool) do
        local p    = Players:FindFirstChild(name)
        local char = p and p.Character
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        d.bill.Enabled = S.ESP and head ~= nil
        if S.ESP and head and hum then
            local myRoot = getRoot()
            local dist   = (myRoot and root) and math.floor((root.Position-myRoot.Position).Magnitude) or 0
            local hp     = math.floor(hum.Health)
            d.lbl.Text   = string.format("%s | %d HP | %dm", name, hp, dist)
            d.lbl.TextColor3 = S.ESPColor
                and Color3.fromRGB(255*(1-hp/math.max(hum.MaxHealth,1)), 255*(hp/math.max(hum.MaxHealth,1)), 60)
                or Color3.new(1,1,1)
        end
        if d.line then
            if S.Tracers and root then
                local sp, on = cam:WorldToViewportPoint(root.Position)
                if on then
                    d.line.Visible = true
                    d.line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    d.line.To   = Vector2.new(sp.X, sp.Y)
                else d.line.Visible = false end
            else d.line.Visible = false end
        end
    end
end)

local function setFullBright(on)
    pcall(function()
        if on then
            Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
            Lighting.Brightness=2; Lighting.FogEnd=1e9; Lighting.ClockTime=12; Lighting.GlobalShadows=false
        else
            Lighting.Ambient=Color3.fromRGB(70,70,70); Lighting.OutdoorAmbient=Color3.fromRGB(110,110,110)
            Lighting.Brightness=1; Lighting.FogEnd=1e5; Lighting.ClockTime=14; Lighting.GlobalShadows=true
        end
    end)
end

-- Speed bypass
RunService.Heartbeat:Connect(function()
    local h, root = getHum(), getRoot()
    if not (h and root) then return end
    if S.SpeedHack then
        pcall(function() h.WalkSpeed = S.Speed end)
        local mv = h.MoveDirection
        if mv.Magnitude > 0.1 then
            local vel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(mv.X * S.Speed, vel.Y, mv.Z * S.Speed)
        end
    end
end)

-- Kill Aura: clicks at enemy screen position for accurate hit registration
task.spawn(function()
    while task.wait(0.08) do
        if not S.KillAura then continue end
        local targets = S.KillAuraAll and enemiesInRange(S.KillAuraRange) or {nearestPlayer(S.KillAuraRange)}
        local primary = targets[1]
        if primary and primary.Character then
            local r = primary.Character:FindFirstChild("HumanoidRootPart") or primary.Character.PrimaryPart
            if r then
                if S.KillAuraFace then faceTo(r.Position) end
                clickM1()
                clickAtTarget(primary)
                fireM1(); fireM1(); fireM1()
                if S.KillAuraAll and #targets > 1 then
                    for i = 2, #targets do fireM1() end
                end
                if S.KillAuraE then tapKey(Enum.KeyCode.E) end
            end
        end
    end
end)

-- Auto M1
task.spawn(function()
    while task.wait(0.12) do
        if S.AutoM1 then clickM1(); fireM1() end
    end
end)

-- Auto Ability: fires the moment it's on (no target gate so it works mid-battle)
task.spawn(function()
    while task.wait(0.25) do
        if not S.AutoAbility then continue end
        local enemy = nearestPlayer(S.AutoAbilityRange)
        if enemy and enemy.Character then
            local r = enemy.Character:FindFirstChild("HumanoidRootPart") or enemy.Character.PrimaryPart
            if r then faceTo(r.Position) end
        end
        if S.CastE then tapKey(Enum.KeyCode.E) end
        if S.CastQ then tapKey(Enum.KeyCode.Q) end
        if S.CastR then tapKey(Enum.KeyCode.R) end
        if S.CastT then tapKey(Enum.KeyCode.T) end
    end
end)

-- Auto Dash: dashes toward/around nearest enemy, or forward if none
task.spawn(function()
    while task.wait(0.4) do
        if not S.AutoDash then continue end
        local p = nearestPlayer(80); local root = getRoot()
        local dir = "Forward"
        if p and p.Character and root then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local side = (tr.Position-root.Position).Unit:Cross(Vector3.yAxis)
                dir = side.X >= 0 and "Right" or "Left"
            end
        end
        fireDash(dir)
    end
end)

-- Auto Farm: TPs under enemy feet so they can't hit back; uses all abilities
task.spawn(function()
    while task.wait(0.1) do
        if not (S.AutoFarm and S.FarmTarget) then continue end
        local t    = Players:FindFirstChild(S.FarmTarget)
        local root = getRoot()
        if t and t.Character and root then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                -- position under their feet — we can swing up, they swing over us
                local pos = tr.Position - Vector3.new(0, 4, 0)
                pcall(function() root.CFrame = CFrame.new(pos) end)
                clickAtTarget(t)
                fireM1(); fireM1(); fireM1()
                tapKey(Enum.KeyCode.E)
                tapKey(Enum.KeyCode.T)
                tapKey(Enum.KeyCode.R)
                if S.CastQ then tapKey(Enum.KeyCode.Q) end
            end
        end
    end
end)

-- Auto Play: same under-feet TP strategy as Auto Farm
task.spawn(function()
    while task.wait(0.1) do
        if not S.AutoPlay then continue end
        local target = nearestPlayer(S.AutoPlayRange)
        if not target or not target.Character then continue end
        local tr   = target.Character:FindFirstChild("HumanoidRootPart")
        local root = getRoot()
        if not (tr and root) then continue end
        local pos = tr.Position - Vector3.new(0, 4, 0)
        pcall(function() root.CFrame = CFrame.new(pos) end)
        clickAtTarget(target)
        fireM1(); fireM1()
        tapKey(Enum.KeyCode.E)
        tapKey(Enum.KeyCode.T)
    end
end)

-- Fling: spin-touch method
local flingSpinning = false
RunService.Heartbeat:Connect(function()
    local root = getRoot()
    if not S.Fling then
        if flingSpinning then
            flingSpinning = false
            if root then pcall(function() root.AssemblyAngularVelocity = Vector3.zero end) end
        end
        return
    end
    if not root then return end
    local target = nearestPlayer(S.KillAuraRange + 8)
    local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if tr then
        flingSpinning = true
        local power = S.FlingPower
        pcall(function()
            root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 0.5, 0))
            root.AssemblyAngularVelocity = Vector3.new(0, power * 30, 0)
            root.AssemblyLinearVelocity  = Vector3.zero
        end)
    elseif flingSpinning then
        flingSpinning = false
        pcall(function() root.AssemblyAngularVelocity = Vector3.zero end)
    end
end)

-- Spin Bot
task.spawn(function()
    while task.wait() do
        if S.SpinBot then
            local root = getRoot()
            if root then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(tick()*900 % 360), 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 60, 0)
            end
            task.wait(0.03)
        end
    end
end)

local function rejoin() pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end
local function serverHop()
    task.spawn(function()
        local body
        pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            body = game:HttpGet(url)
        end)
        if body then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and data and data.data then
                for _,sv in ipairs(data.data) do
                    if sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP) end)
                        return
                    end
                end
            end
        end
        rejoin()
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "Money/FreeHub | Ability Arena",
    LoadingTitle = "Money/FreeHub",
    LoadingSubtitle = "v2.7.1 — by Money/FreeHub Owner",
    ConfigurationSaving = { Enabled = true, FolderName = "MoneyFreeHub", FileName = "AbilityArena" },
    Discord = { Enabled = false },
    KeySystem = false,
})

local CombatTab    = Window:CreateTab("Combat",    4483362458)
local AbilitiesTab = Window:CreateTab("Abilities", 4483362458)
local MovementTab  = Window:CreateTab("Movement",  4483362458)
local VisualsTab   = Window:CreateTab("Visuals",   4483362458)
local FarmTab      = Window:CreateTab("Farm",      4483362458)
local UtilityTab   = Window:CreateTab("Utility",   4483362458)

-- Combat
CombatTab:CreateSection("Survival")
CombatTab:CreateToggle({Name="Anti-Ragdoll (hard)", CurrentValue=false, Flag="AntiRagdoll", Callback=function(v)
    S.AntiRagdoll=v
    local h=getHum()
    if h then setRagdollStates(h, not v) end
end})
CombatTab:CreateToggle({Name="Anti-Push (knockback)", CurrentValue=false, Flag="AntiPush", Callback=function(v) S.AntiPush=v end})
CombatTab:CreateToggle({Name="Anti Void / Water (instant TP back)", CurrentValue=false, Flag="AntiVoid", Callback=function(v) S.AntiVoid=v end})

CombatTab:CreateSection("Kill Aura")
CombatTab:CreateToggle({Name="Kill Aura (auto-fights for you)", CurrentValue=false, Flag="KillAura", Callback=function(v) S.KillAura=v end})
CombatTab:CreateSlider({Name="Aura Range", Range={5,150}, Increment=1, Suffix="studs", CurrentValue=24, Flag="KillAuraRange", Callback=function(v) S.KillAuraRange=v end})
CombatTab:CreateToggle({Name="Face Target", CurrentValue=true, Flag="KillAuraFace", Callback=function(v) S.KillAuraFace=v end})
CombatTab:CreateToggle({Name="Hit All In Range", CurrentValue=false, Flag="KillAuraAll", Callback=function(v) S.KillAuraAll=v end})
CombatTab:CreateToggle({Name="Also Cast E", CurrentValue=true, Flag="KillAuraE", Callback=function(v) S.KillAuraE=v end})

CombatTab:CreateSection("Hitboxes")
CombatTab:CreateToggle({Name="M1 Hitbox Expander (hit enemies from long range)", CurrentValue=false, Flag="M1Hitbox", Callback=function(v)
    S.M1Hitbox=v
    if not v then restoreHitboxes() end
end})
CombatTab:CreateSlider({Name="M1 Hitbox Size", Range={1,50}, Increment=1, Suffix="studs", CurrentValue=35, Flag="M1HitboxSize", Callback=function(v) S.M1HitboxSize=v end})
CombatTab:CreateToggle({Name="Abilities Expand (expand ability hitbox on E press)", CurrentValue=false, Flag="HitboxAbility", Callback=function(v)
    S.HitboxAbility=v
    if not v then destroyAbilityHb() end
end})
CombatTab:CreateSlider({Name="Abilities Expand Size", Range={1,50}, Increment=1, Suffix="studs", CurrentValue=20, Flag="HitboxAbilitySize", Callback=function(v) S.HitboxAbilitySize=v end})

CombatTab:CreateSection("Fling")
CombatTab:CreateToggle({Name="Fling (spin-touch — WARNING: TPs you onto target)", CurrentValue=false, Flag="Fling", Callback=function(v)
    S.Fling=v
    if not v then
        local r=getRoot()
        if r then pcall(function() r.AssemblyAngularVelocity = Vector3.zero end) end
    end
end})
CombatTab:CreateSlider({Name="Fling Power", Range={100,3000}, Increment=50, Suffix="vel", CurrentValue=800, Flag="FlingPower", Callback=function(v) S.FlingPower=v end})

CombatTab:CreateSection("Auto")
CombatTab:CreateToggle({Name="Auto M1 (click spam)", CurrentValue=false, Flag="AutoM1", Callback=function(v) S.AutoM1=v end})
CombatTab:CreateToggle({Name="Auto Ability", CurrentValue=false, Flag="AutoAbility", Callback=function(v) S.AutoAbility=v end})
CombatTab:CreateSlider({Name="Auto Ability Range", Range={5,80}, Increment=1, Suffix="studs", CurrentValue=25, Flag="AutoAbilityRange", Callback=function(v) S.AutoAbilityRange=v end})
CombatTab:CreateToggle({Name="Cast E", CurrentValue=true,  Flag="CastE", Callback=function(v) S.CastE=v end})
CombatTab:CreateToggle({Name="Cast Q", CurrentValue=false, Flag="CastQ", Callback=function(v) S.CastQ=v end})
CombatTab:CreateToggle({Name="Cast R", CurrentValue=false, Flag="CastR", Callback=function(v) S.CastR=v end})
CombatTab:CreateToggle({Name="Cast T", CurrentValue=false, Flag="CastT", Callback=function(v) S.CastT=v end})
CombatTab:CreateToggle({Name="Auto Dash (around target)", CurrentValue=false, Flag="AutoDash", Callback=function(v) S.AutoDash=v end})

CombatTab:CreateSection("Aim")
CombatTab:CreateToggle({Name="Camera Lock (nearest)", CurrentValue=false, Flag="CamLock", Callback=function(v) S.CamLock=v end})
CombatTab:CreateSlider({Name="Cam Lock Range", Range={20,300}, Increment=5, Suffix="studs", CurrentValue=120, Flag="CamLockRange", Callback=function(v) S.CamLockRange=v end})

-- Abilities
AbilitiesTab:CreateSection("Ability Grabber")
AbilitiesTab:CreateParagraph({Title="How it works", Content="Pick an ability. You TP to its pad, E is tapped for you, then you TP back where you were. Raise Grab Delay if you need more time to pick before TP-ing back."})
AbilitiesTab:CreateSlider({Name="Grab Delay (time before TP back)", Range={1,8}, Increment=1, Suffix="sec", CurrentValue=3, Flag="GrabDelay", Callback=function(v) S.GrabDelay=v end})
local selectedAbility = nil
local abilityDrop = AbilitiesTab:CreateDropdown({Name="Ability", Options=abilityNames(), CurrentOption={}, Flag="AbilityPick", Callback=function(o)
    selectedAbility = (type(o)=="table" and o[1]) or o
    grabAbility(selectedAbility)
end})
AbilitiesTab:CreateButton({Name="Get Ability Again", Callback=function() grabAbility(selectedAbility) end})
AbilitiesTab:CreateButton({Name="Refresh Ability List", Callback=function()
    elementFolder = nil
    pcall(function() abilityDrop:Refresh(abilityNames()) end)
end})

-- Movement
MovementTab:CreateToggle({Name="Fly (WASD + Space/Ctrl)", CurrentValue=false, Flag="Fly", Callback=function(v) S.Fly=v end})
MovementTab:CreateSlider({Name="Fly Speed", Range={10,250}, Increment=5, Suffix="spd", CurrentValue=60, Flag="FlySpeed", Callback=function(v) S.FlySpeed=v end})
MovementTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v)
    S.Noclip=v
    if not v then
        local c=getChar()
        if c then for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then pcall(function() p.CanCollide=true end) end
        end end
    end
end})
MovementTab:CreateToggle({Name="Speed Hack", CurrentValue=false, Flag="SpeedHack", Callback=function(v)
    S.SpeedHack=v
    if not v then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end
end})
MovementTab:CreateSlider({Name="Walk Speed", Range={16,300}, Increment=1, Suffix="spd", CurrentValue=16, Flag="Speed", Callback=function(v) S.Speed=v end})
MovementTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Flag="InfiniteJump", Callback=function(v) S.InfiniteJump=v end})
MovementTab:CreateToggle({Name="Spin Bot", CurrentValue=false, Flag="SpinBot", Callback=function(v) S.SpinBot=v end})
MovementTab:CreateToggle({Name="Anti-Fling", CurrentValue=false, Flag="AntiFling", Callback=function(v) S.AntiFling=v end})

-- Visuals
VisualsTab:CreateToggle({Name="Player ESP", CurrentValue=false, Flag="ESP", Callback=function(v) S.ESP=v end})
VisualsTab:CreateToggle({Name="Color By HP", CurrentValue=true, Flag="ESPColor", Callback=function(v) S.ESPColor=v end})
VisualsTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="Tracers", Callback=function(v) S.Tracers=v end})
VisualsTab:CreateToggle({Name="Enemy Highlight", CurrentValue=false, Flag="EnemyHighlight", Callback=function(v) S.EnemyHighlight=v end})
VisualsTab:CreateDropdown({Name="Highlight Color", Options={"Bright blue","Bright red","Lime green","New Yeller","White","Magenta"}, CurrentOption={"Bright blue"}, Flag="HighlightColor", Callback=function(o)
    S.HighlightColor = (type(o)=="table" and o[1]) or o
    clearHighlights()
end})
VisualsTab:CreateToggle({Name="Full Bright", CurrentValue=false, Flag="FullBright", Callback=function(v) S.FullBright=v; setFullBright(v) end})

-- Farm
FarmTab:CreateSection("Auto Play")
FarmTab:CreateToggle({Name="Auto Play (fight nearest enemy automatically)", CurrentValue=false, Flag="AutoPlay", Callback=function(v) S.AutoPlay=v end})
FarmTab:CreateSlider({Name="Auto Play Search Range", Range={10,300}, Increment=5, Suffix="studs", CurrentValue=100, Flag="AutoPlayRange", Callback=function(v) S.AutoPlayRange=v end})

FarmTab:CreateSection("Auto Farm")
FarmTab:CreateToggle({Name="Auto Farm Target", CurrentValue=false, Flag="AutoFarm", Callback=function(v)
    if v and not S.FarmTarget then
        Rayfield:Notify({Title="Money/FreeHub", Content="Pick a target first.", Duration=3})
        v=false
    end
    S.AutoFarm=v
end})
local farmDrop = FarmTab:CreateDropdown({Name="Target Player", Options=playerNames(), CurrentOption={}, Flag="FarmTarget", Callback=function(o)
    S.FarmTarget = (type(o)=="table" and o[1]) or o
end})
FarmTab:CreateButton({Name="Refresh Player List", Callback=function()
    pcall(function() farmDrop:Refresh(playerNames()) end)
end})

-- Utility
UtilityTab:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AntiAFK", Callback=function(v) S.AntiAFK=v end})
UtilityTab:CreateToggle({Name="Instant Respawn", CurrentValue=false, Flag="InstantRespawn", Callback=function(v) S.InstantRespawn=v end})
UtilityTab:CreateToggle({Name="Click Teleport  [T]", CurrentValue=false, Flag="ClickTP", Callback=function(v) S.ClickTP=v end})
UtilityTab:CreateButton({Name="Rejoin Server", Callback=rejoin})
UtilityTab:CreateButton({Name="Server Hop", Callback=serverHop})

UtilityTab:CreateSection("Safe Spawn")
UtilityTab:CreateParagraph({Title="Anti Void TP target", Content="Walk to your safe spot, then click Set Safe Spawn. Anti Void will TP you there."})
UtilityTab:CreateButton({Name="Set Safe Spawn (save position)", Callback=function()
    local root = getRoot()
    if root then
        savedSpawnCF = root.CFrame
        Rayfield:Notify({Title="Money/FreeHub", Content="Safe spawn saved!", Duration=4})
    end
end})
UtilityTab:CreateButton({Name="TP to Safe Spawn", Callback=function()
    local root = getRoot()
    local tpCF = savedSpawnCF or lastSafeCF
    if root and tpCF then
        pcall(function() root.CFrame = tpCF + Vector3.new(0, 3, 0) end)
    else
        Rayfield:Notify({Title="Money/FreeHub", Content="No safe spawn set yet.", Duration=4})
    end
end})
UtilityTab:CreateButton({Name="Clear Safe Spawn", Callback=function()
    savedSpawnCF = nil
    Rayfield:Notify({Title="Money/FreeHub", Content="Safe spawn cleared.", Duration=3})
end})

UtilityTab:CreateSection("Admin")
UtilityTab:CreateButton({Name="Unload Money/FreeHub", Callback=function()
    for _,c in pairs(Conns) do pcall(function() c:Disconnect() end) end
    clearESP(); clearHighlights(); flyCleanup(); restoreHitboxes()
    destroyAbilityHb()
    if floatPart then pcall(function() floatPart:Destroy() end) end
    local h=getHum(); if h then setRagdollStates(h, true) end
    for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
    pcall(function() Rayfield:Destroy() end)
end})

UtilityTab:CreateSection("Status")
UtilityTab:CreateParagraph({Title="Credits", Content="Money/FreeHub v2.7.1 — by Money/FreeHub Owner"})
UtilityTab:CreateParagraph({Title="Status", Content = JoltReliable and "Combat remotes linked." or "Combat remotes NOT found — rejoin and retry."})
UtilityTab:CreateParagraph({Title="Best combo", Content="Kill Aura + M1 Hitbox (size 100+) + Hitbox Ability (E bursts it 3x). Set Safe Spawn near tree before Anti Void."})

Rayfield:Notify({Title="Money/FreeHub v2.7.1", Content="Loaded — by Money/FreeHub Owner", Duration=6})
