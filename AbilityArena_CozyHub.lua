-- Cozy Hub | Ability Arena | v2.1
-- v2.1: Anti Void/Water float plate, hard anti-ragdoll/push/fling rework,
--        Kill Aura now lands M1s (real clicks + enemy hitbox expander).
--
-- Research notes:
--   * The game networks through the "Jolt" library (typed successor to Warp).
--     All combat goes through ReplicatedStorage.Files.Shared.Components.Jolt.
--     Utils.Remotes.Jolt_Reliable as a pre-serialized binary blob.
--   * The M1 and Dash blobs embed a "Timestamp": an 8-byte little-endian double
--     equal to workspace:GetServerTimeNow(). We splice a FRESH stamp every fire.
--   * The M1 blob's "Hits" array is EMPTY (\16\0\0 = 0 entries). Hit detection
--     is CLIENT-side: the game's own M1 code fills Hits with what it detected.
--     A blob with empty Hits is a whiff. So Kill Aura sends REAL mouse clicks
--     (the game's code then detects + reports hits itself) and we expand enemy
--     HumanoidRootParts locally so those clicks connect from far away.

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

-- ── Services ───────────────────────────────────────────────────────────────────
local Players               = game:GetService("Players")
local RS                    = game:GetService("ReplicatedStorage")
local Workspace             = game:GetService("Workspace")
local RunService            = game:GetService("RunService")
local UserInputService      = game:GetService("UserInputService")
local Lighting              = game:GetService("Lighting")
local TeleportService       = game:GetService("TeleportService")
local VirtualInputManager   = game:GetService("VirtualInputManager")
local HttpService           = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ── Live character getters (never trust a stale upvalue across respawns) ────────
local function getChar() return LP.Character end
local function getHum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()
    local c=LP.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end

-- ── Jolt remote ────────────────────────────────────────────────────────────────
local JoltReliable
pcall(function()
    JoltReliable = RS:WaitForChild("Files", 10)
        :WaitForChild("Shared"):WaitForChild("Components")
        :WaitForChild("Jolt"):WaitForChild("Utils")
        :WaitForChild("Remotes"):WaitForChild("Jolt_Reliable")
end)

-- ── Serialized payloads with LIVE timestamps ───────────────────────────────────
local M1_Prefix = string.char(5,85,115,101,77,49,65,16,3,9,84,105,109,101,115,116,97,109,112,2,199)
local M1_Suffix = string.char(3,5,73,110,100,101,120,17,32,3,4,72,105,116,115,16,0,0)

local function nowStamp()
    local t = 0
    pcall(function() t = Workspace:GetServerTimeNow() end)
    if t == 0 then pcall(function() t = os.clock() end) end
    return string.pack("<d", t)
end

local function buildM1()
    return M1_Prefix .. nowStamp() .. M1_Suffix
end

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

-- Real M1: synthesized mouse click so the GAME's own client code runs its hit
-- detection and reports the targets (the path the server actually trusts).
-- Click lands at 78% screen height so the Rayfield window can't eat it.
local function clickM1()
    pcall(function()
        local cam = Workspace.CurrentCamera
        local x, y = cam.ViewportSize.X/2, cam.ViewportSize.Y*0.78
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true,  game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

-- ── Settings ────────────────────────────────────────────────────────────────────
local S = {
    -- Combat
    GodMode=false, AntiRagdoll=false, AntiPush=false, AntiVoid=false,
    KillAura=false, KillAuraRange=24, KillAuraFace=true, KillAuraAll=false, KillAuraE=true,
    M1Hitbox=false, M1HitboxSize=14,
    AutoM1=false,
    AutoAbility=false, AutoAbilityRange=25,
    CastE=true, CastQ=false, CastR=false, CastT=false,
    AutoDash=false,
    Reach=false, ReachSize=1.5,
    CamLock=false, CamLockRange=120,
    -- Movement
    Fly=false, FlySpeed=60,
    Noclip=false,
    SpeedHack=false, Speed=16,
    JumpMod=false, JumpPower=50,
    InfiniteJump=false,
    SpinBot=false, AntiFling=false,
    -- Visuals
    ESP=false, ESPColor=true, Tracers=false,
    EnemyHighlight=false, HighlightColor="Bright blue",
    FullBright=false,
    -- Farm
    AutoFarm=false, FarmTarget=nil, FarmUnder=true,
    -- Utility
    AntiAFK=false, InstantRespawn=false, ClickTP=false,
}

-- ── Connection manager ───────────────────────────────────────────────────────────
local Conns = {}
local function bind(name, conn)
    if Conns[name] then pcall(function() Conns[name]:Disconnect() end) end
    Conns[name] = conn
end

-- ── Helpers ─────────────────────────────────────────────────────────────────────
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
    local root = getRoot(); if root then root.CFrame = CFrame.new(root.Position, Vector3.new(pos.X, root.Position.Y, pos.Z)) end
end
local function tapKey(kc)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, kc, false, game); task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, kc, false, game)
    end)
end

-- ── M1 Hitbox Expander (client-side enemy HRP enlargement) ──────────────────────
-- Hit detection is client-side, so locally enlarging enemy HumanoidRootParts makes
-- the game's own M1 hit-scan connect from far away — and the server accepts the
-- reported hits. Size changes are local-only; originals restored on disable.
local hbOriginal = {}   -- [playerName] = {size=Vector3, transp=number, collide=bool}
local function restoreHitboxes()
    for name,orig in pairs(hbOriginal) do
        local p = Players:FindFirstChild(name)
        local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if r then pcall(function()
            r.Size = orig.size; r.Transparency = orig.transp; r.CanCollide = orig.collide
        end) end
    end
    hbOriginal = {}
end
task.spawn(function()
    while task.wait(0.25) do
        if S.M1Hitbox then
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local r = p.Character:FindFirstChild("HumanoidRootPart")
                    local h = p.Character:FindFirstChildOfClass("Humanoid")
                    if r and h and h.Health > 0 then
                        if not hbOriginal[p.Name] then
                            hbOriginal[p.Name] = {size=r.Size, transp=r.Transparency, collide=r.CanCollide}
                        end
                        local sz = S.M1HitboxSize
                        pcall(function()
                            if r.Size.X ~= sz then r.Size = Vector3.new(sz, sz, sz) end
                            r.Transparency = 0.7
                            r.CanCollide = false
                            r.CanQuery = true
                            r.CanTouch = true
                        end)
                    end
                end
            end
        elseif next(hbOriginal) then
            restoreHitboxes()
        end
    end
end)

-- ── Per-character rebind ─────────────────────────────────────────────────────────
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

    bind("godHealth", hum.HealthChanged:Connect(function()
        if S.GodMode and hum.Health < hum.MaxHealth then
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end))

    bind("antiRag", hum.StateChanged:Connect(function(_, new)
        if not (S.AntiRagdoll or S.GodMode) then return end
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
    if S.SpeedHack then pcall(function() hum.WalkSpeed = S.Speed end) end
    if S.JumpMod   then pcall(function() hum.JumpPower = S.JumpPower; hum.UseJumpPower = true end) end
end

LP.CharacterAdded:Connect(function(char) task.wait(0.2); pcall(applyCharacter, char) end)
if LP.Character then pcall(applyCharacter, LP.Character) end

-- ── Anti-Ragdoll: hard mode ──────────────────────────────────────────────────────
-- Layer 1: ragdoll-ish humanoid states fully DISABLED (re-applied every 0.5s
--          because games re-enable them when they ragdoll you).
-- Layer 2: per-frame PlatformStand/Sit clear + bad-state bounce.
-- Layer 3: ragdoll constraints destroyed, Motor6Ds re-enabled, stun flags cleared.
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

-- ── Anti-Push / Anti-Fling: pre-physics velocity clamps ──────────────────────────
-- Runs on Stepped (BEFORE physics integrates) and covers every body part, because
-- ragdoll flings split the character into separate assemblies per limb.
RunService.Stepped:Connect(function()
    if S.Fly then return end   -- fly drives its own high velocities
    if not (S.AntiPush or S.AntiFling) then return end
    local char, root, hum = getChar(), getRoot(), getHum()
    if not (char and root) then return end
    if S.AntiFling then
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
        local v = root.AssemblyLinearVelocity
        local cap = ((hum and hum.WalkSpeed) or 16) * 2.5 + 25
        local hv = Vector3.new(v.X, 0, v.Z)
        if hv.Magnitude > cap then
            root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(v.Y, -90, 60), 0)
        end
    end
end)

-- ── Anti Void / Water: float plate ───────────────────────────────────────────────
-- A local anchored ForceField plate that catches you: over water it sits at the
-- surface so you stand ON the water; over the void it rides under your feet like
-- a flying carpet. Plus an emergency snap-back if you're already below the map.
local floatPart, lastSafeCF
local function ensureFloat()
    if not floatPart or floatPart.Parent == nil then
        floatPart = Instance.new("Part")
        floatPart.Name = "CozyFloat"
        floatPart.Size = Vector3.new(16, 1, 16)
        floatPart.Anchored = true
        floatPart.CanCollide = true
        floatPart.CanQuery = false
        floatPart.Material = Enum.Material.ForceField
        floatPart.Color = Color3.fromRGB(120, 170, 255)
        floatPart.Transparency = 0.6
        floatPart.Parent = Workspace
    end
    return floatPart
end
local function showFloat(pos)
    local plat = ensureFloat()
    plat.CanCollide = true
    plat.Transparency = 0.6
    plat.Position = pos
end
local function hideFloat()
    if floatPart then floatPart.CanCollide = false; floatPart.Transparency = 1 end
end

RunService.Heartbeat:Connect(function()
    if not S.AntiVoid then
        if floatPart then pcall(function() floatPart:Destroy() end); floatPart = nil end
        return
    end
    local root, hum, char = getRoot(), getHum(), getChar()
    if not (root and hum and char) then return end

    local floor = hum.FloorMaterial
    local onOurPlate = (floor == Enum.Material.ForceField)

    -- Remember the last real ground we stood on
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
    local vy        = root.AssemblyLinearVelocity.Y

    if swimming then
        -- Pop out of the water onto a plate at the surface
        showFloat(Vector3.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z))
        root.CFrame = root.CFrame + Vector3.new(0, 4, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    elseif overWater and (root.Position.Y - hit.Position.Y) < 12 then
        -- Near the water surface: plate AT the surface so we land/stand on it
        showFloat(Vector3.new(root.Position.X, hit.Position.Y + 0.5, root.Position.Z))
    elseif overVoid and (vy < -5 or onOurPlate) then
        -- Nothing below at all: carpet plate under our feet
        local y = onOurPlate and floatPart.Position.Y or (root.Position.Y - 6)
        showFloat(Vector3.new(root.Position.X, y, root.Position.Z))
        if vy < -120 then
            root.AssemblyLinearVelocity = Vector3.new(0, -40, 0)
        end
    else
        hideFloat()
    end

    -- Emergency: already below the kill plane -> snap back to last safe ground
    local killY = -480
    pcall(function() killY = Workspace.FallenPartsDestroyHeight + 100 end)
    if root.Position.Y < killY and lastSafeCF then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = lastSafeCF + Vector3.new(0, 6, 0)
    end
end)

-- ── Global input hooks ───────────────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if S.InfiniteJump then local h=getHum(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
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

-- ── Fly ──────────────────────────────────────────────────────────────────────────
local flyBV, flyBG
local flyKeys = {W=false,A=false,S=false,D=false,Up=false,Down=false}
local function flyCleanup()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
end
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local k=i.KeyCode
    if     k==Enum.KeyCode.W then flyKeys.W=true
    elseif k==Enum.KeyCode.A then flyKeys.A=true
    elseif k==Enum.KeyCode.S then flyKeys.S=true
    elseif k==Enum.KeyCode.D then flyKeys.D=true
    elseif k==Enum.KeyCode.Space then flyKeys.Up=true
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=true end
end)
UserInputService.InputEnded:Connect(function(i)
    local k=i.KeyCode
    if     k==Enum.KeyCode.W then flyKeys.W=false
    elseif k==Enum.KeyCode.A then flyKeys.A=false
    elseif k==Enum.KeyCode.S then flyKeys.S=false
    elseif k==Enum.KeyCode.D then flyKeys.D=false
    elseif k==Enum.KeyCode.Space then flyKeys.Up=false
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=false end
end)
RunService.RenderStepped:Connect(function()
    if not S.Fly then if flyBV then flyCleanup() end return end
    local root = getRoot(); if not root then return end
    if not flyBV or flyBV.Parent ~= root then
        flyCleanup()
        flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.P=9e4; flyBG.CFrame=root.CFrame; flyBG.Parent=root
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(9e9,9e9,9e9); flyBV.Velocity=Vector3.zero; flyBV.Parent=root
    end
    local cam = Workspace.CurrentCamera
    flyBG.CFrame = cam.CFrame
    local dir = Vector3.zero
    if flyKeys.W then dir += cam.CFrame.LookVector end
    if flyKeys.S then dir -= cam.CFrame.LookVector end
    if flyKeys.A then dir -= cam.CFrame.RightVector end
    if flyKeys.D then dir += cam.CFrame.RightVector end
    if flyKeys.Up then dir += Vector3.yAxis end
    if flyKeys.Down then dir -= Vector3.yAxis end
    flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit * S.FlySpeed) or Vector3.zero
end)

-- ── Noclip ───────────────────────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local c = getChar(); if not c then return end
    for _,pt in ipairs(c:GetDescendants()) do
        if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end
    end
end)

-- ── Camera lock ──────────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not S.CamLock then return end
    local tgt = nearestPlayer(S.CamLockRange); if not tgt or not tgt.Character then return end
    local head = tgt.Character:FindFirstChild("Head") or tgt.Character:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local cam = Workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
end)

-- ── Reach (self hitbox sphere) ───────────────────────────────────────────────────
local reachPart
RunService.Heartbeat:Connect(function()
    if S.Reach then
        local root = getRoot(); if not root then return end
        if not reachPart or reachPart.Parent == nil then
            reachPart = Instance.new("Part")
            reachPart.Shape=Enum.PartType.Ball; reachPart.Anchored=false; reachPart.CanCollide=false
            reachPart.Massless=true; reachPart.Transparency=0.7; reachPart.Color=Color3.fromRGB(255,60,60)
            reachPart.Material=Enum.Material.ForceField
            local w=Instance.new("Weld"); w.Part0=root; w.Part1=reachPart; w.Parent=reachPart
            reachPart.Parent=root.Parent
        end
        local s = S.ReachSize*2
        reachPart.Size = Vector3.new(s,s,s)
    elseif reachPart then
        pcall(function() reachPart:Destroy() end); reachPart=nil
    end
end)

-- ── Enemy highlight ──────────────────────────────────────────────────────────────
local highlights = {}
local function clearHighlights()
    for _,h in pairs(highlights) do pcall(function() h:Destroy() end) end
    highlights = {}
end
RunService.Heartbeat:Connect(function()
    if not S.EnemyHighlight then if next(highlights) then clearHighlights() end return end
    for name,h in pairs(highlights) do
        local p = Players:FindFirstChild(name)
        if not p or not p.Character or h.Parent==nil then pcall(function() h:Destroy() end); highlights[name]=nil end
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

-- ── ESP + tracers ────────────────────────────────────────────────────────────────
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
                bill.Name="CozyESP"; bill.Adornee=p.Character.Head; bill.Size=UDim2.new(0,200,0,40)
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
        local p = Players:FindFirstChild(name)
        local char = p and p.Character
        local head = char and char:FindFirstChild("Head")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        d.bill.Enabled = S.ESP and head ~= nil
        if S.ESP and head and hum then
            local myRoot = getRoot()
            local dist = (myRoot and root) and math.floor((root.Position-myRoot.Position).Magnitude) or 0
            local hp = math.floor(hum.Health)
            d.lbl.Text = string.format("%s | %d HP | %dm", name, hp, dist)
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

-- ── Full bright ──────────────────────────────────────────────────────────────────
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

-- ════════════════════════════════════════════════════════════════════════════════
-- BACKGROUND LOOPS
-- ════════════════════════════════════════════════════════════════════════════════

-- God mode hard peg
task.spawn(function()
    while task.wait(0.1) do
        if S.GodMode then
            local h = getHum()
            if h and h.MaxHealth > 0 and h.Health < h.MaxHealth then pcall(function() h.Health = h.MaxHealth end) end
        end
    end
end)

-- Speed / jump enforcement
task.spawn(function()
    while task.wait(0.3) do
        local h = getHum(); if not h then continue end
        if S.SpeedHack then pcall(function() if h.WalkSpeed ~= S.Speed then h.WalkSpeed = S.Speed end end) end
        if S.JumpMod  then pcall(function() h.UseJumpPower = true; if h.JumpPower ~= S.JumpPower then h.JumpPower = S.JumpPower end end) end
    end
end)

-- Kill aura: face target, REAL M1 click (game's own hit detection fills Hits),
-- raw blob as backup, optional E. Combine with M1 Hitbox Expander for range.
task.spawn(function()
    while task.wait(0.12) do
        if not S.KillAura then continue end
        local targets = S.KillAuraAll and enemiesInRange(S.KillAuraRange) or {nearestPlayer(S.KillAuraRange)}
        local primary = targets[1]
        if primary and primary.Character then
            local r = primary.Character:FindFirstChild("HumanoidRootPart") or primary.Character.PrimaryPart
            if r then
                if S.KillAuraFace then faceTo(r.Position) end
                clickM1()                       -- the path that actually lands damage
                for _ = 1, #targets do fireM1() end   -- blob backup per target
                if S.KillAuraE then tapKey(Enum.KeyCode.E) end
            end
        end
    end
end)

-- Auto M1 (click + blob spam, no targeting)
task.spawn(function()
    while task.wait(0.12) do
        if S.AutoM1 then clickM1(); fireM1() end
    end
end)

-- Auto ability (E/Q/R/T near a target)
task.spawn(function()
    while task.wait(0.25) do
        if not S.AutoAbility then continue end
        if not nearestPlayer(S.AutoAbilityRange) then continue end
        if S.CastE then tapKey(Enum.KeyCode.E) end
        if S.CastQ then tapKey(Enum.KeyCode.Q) end
        if S.CastR then tapKey(Enum.KeyCode.R) end
        if S.CastT then tapKey(Enum.KeyCode.T) end
    end
end)

-- Auto dash (around nearest)
task.spawn(function()
    while task.wait(0.4) do
        if not S.AutoDash then continue end
        local p = nearestPlayer(35); local root = getRoot()
        if p and p.Character and root then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local side = (tr.Position-root.Position).Unit:Cross(Vector3.yAxis)
                fireDash(side.X >= 0 and "Right" or "Left")
            end
        end
    end
end)

-- Auto farm (stick to one target, click + blob + E)
task.spawn(function()
    while task.wait(0.15) do
        if not (S.AutoFarm and S.FarmTarget) then continue end
        local t = Players:FindFirstChild(S.FarmTarget)
        local root = getRoot()
        if t and t.Character and root then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local pos = S.FarmUnder and (tr.Position + Vector3.new(0,-7,0)) or (tr.Position - tr.CFrame.LookVector*3)
                root.CFrame = CFrame.new(pos, tr.Position)
                clickM1()
                fireM1()
                if S.KillAuraE then tapKey(Enum.KeyCode.E) end
            end
        end
    end
end)

-- Spin bot (fling)
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

-- ════════════════════════════════════════════════════════════════════════════════
-- SERVER HOP
-- ════════════════════════════════════════════════════════════════════════════════
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
-- GUI (Rayfield)
-- ════════════════════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "Cozy Hub | Ability Arena",
    LoadingTitle = "Cozy Hub",
    LoadingSubtitle = "v2.1 — clicks that land",
    ConfigurationSaving = { Enabled = true, FolderName = "CozyHub", FileName = "AbilityArena" },
    Discord = { Enabled = false },
    KeySystem = false,
})

local CombatTab   = Window:CreateTab("Combat",   4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local VisualsTab  = Window:CreateTab("Visuals",  4483362458)
local FarmTab     = Window:CreateTab("Farm",     4483362458)
local UtilityTab  = Window:CreateTab("Utility",  4483362458)

-- Combat
CombatTab:CreateSection("Survival")
CombatTab:CreateToggle({Name="God Mode (client peg)", CurrentValue=false, Flag="GodMode", Callback=function(v) S.GodMode=v end})
CombatTab:CreateToggle({Name="Anti-Ragdoll (hard)", CurrentValue=false, Flag="AntiRagdoll", Callback=function(v)
    S.AntiRagdoll=v
    local h=getHum()
    if h then setRagdollStates(h, not v) end
end})
CombatTab:CreateToggle({Name="Anti-Push (knockback)", CurrentValue=false, Flag="AntiPush", Callback=function(v) S.AntiPush=v end})
CombatTab:CreateToggle({Name="Anti Void / Water (float)", CurrentValue=false, Flag="AntiVoid", Callback=function(v) S.AntiVoid=v end})

CombatTab:CreateSection("Kill Aura")
CombatTab:CreateToggle({Name="Kill Aura (real M1 clicks)", CurrentValue=false, Flag="KillAura", Callback=function(v) S.KillAura=v end})
CombatTab:CreateSlider({Name="Aura Range", Range={5,150}, Increment=1, Suffix="studs", CurrentValue=24, Flag="KillAuraRange", Callback=function(v) S.KillAuraRange=v end})
CombatTab:CreateToggle({Name="M1 Hitbox Expander", CurrentValue=false, Flag="M1Hitbox", Callback=function(v)
    S.M1Hitbox=v
    if not v then restoreHitboxes() end
end})
CombatTab:CreateSlider({Name="M1 Hitbox Size", Range={4,40}, Increment=1, Suffix="studs", CurrentValue=14, Flag="M1HitboxSize", Callback=function(v) S.M1HitboxSize=v end})
CombatTab:CreateToggle({Name="Face Target", CurrentValue=true, Flag="KillAuraFace", Callback=function(v) S.KillAuraFace=v end})
CombatTab:CreateToggle({Name="Hit All In Range (blob)", CurrentValue=false, Flag="KillAuraAll", Callback=function(v) S.KillAuraAll=v end})
CombatTab:CreateToggle({Name="Also Cast E", CurrentValue=true, Flag="KillAuraE", Callback=function(v) S.KillAuraE=v end})

CombatTab:CreateSection("Auto")
CombatTab:CreateToggle({Name="Auto M1 (click spam)", CurrentValue=false, Flag="AutoM1", Callback=function(v) S.AutoM1=v end})
CombatTab:CreateToggle({Name="Auto Ability", CurrentValue=false, Flag="AutoAbility", Callback=function(v) S.AutoAbility=v end})
CombatTab:CreateSlider({Name="Auto Ability Range", Range={5,80}, Increment=1, Suffix="studs", CurrentValue=25, Flag="AutoAbilityRange", Callback=function(v) S.AutoAbilityRange=v end})
CombatTab:CreateToggle({Name="Cast E", CurrentValue=true, Flag="CastE", Callback=function(v) S.CastE=v end})
CombatTab:CreateToggle({Name="Cast Q", CurrentValue=false, Flag="CastQ", Callback=function(v) S.CastQ=v end})
CombatTab:CreateToggle({Name="Cast R", CurrentValue=false, Flag="CastR", Callback=function(v) S.CastR=v end})
CombatTab:CreateToggle({Name="Cast T", CurrentValue=false, Flag="CastT", Callback=function(v) S.CastT=v end})
CombatTab:CreateToggle({Name="Auto Dash (around target)", CurrentValue=false, Flag="AutoDash", Callback=function(v) S.AutoDash=v end})

CombatTab:CreateSection("Aim")
CombatTab:CreateToggle({Name="Reach (self hitbox)", CurrentValue=false, Flag="Reach", Callback=function(v) S.Reach=v end})
CombatTab:CreateSlider({Name="Reach Size", Range={1,10}, Increment=0.5, Suffix="x", CurrentValue=1.5, Flag="ReachSize", Callback=function(v) S.ReachSize=v end})
CombatTab:CreateToggle({Name="Camera Lock (nearest)", CurrentValue=false, Flag="CamLock", Callback=function(v) S.CamLock=v end})
CombatTab:CreateSlider({Name="Cam Lock Range", Range={20,300}, Increment=5, Suffix="studs", CurrentValue=120, Flag="CamLockRange", Callback=function(v) S.CamLockRange=v end})

-- Movement
MovementTab:CreateToggle({Name="Fly (WASD + Space/Ctrl)", CurrentValue=false, Flag="Fly", Callback=function(v) S.Fly=v end})
MovementTab:CreateSlider({Name="Fly Speed", Range={10,250}, Increment=5, Suffix="spd", CurrentValue=60, Flag="FlySpeed", Callback=function(v) S.FlySpeed=v end})
MovementTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v)
    S.Noclip=v
    if not v then local c=getChar(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then pcall(function() p.CanCollide=true end) end end end end
end})
MovementTab:CreateToggle({Name="Speed Hack", CurrentValue=false, Flag="SpeedHack", Callback=function(v)
    S.SpeedHack=v; if not v then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end
end})
MovementTab:CreateSlider({Name="Walk Speed", Range={16,300}, Increment=1, Suffix="spd", CurrentValue=16, Flag="Speed", Callback=function(v) S.Speed=v end})
MovementTab:CreateToggle({Name="Jump Mod", CurrentValue=false, Flag="JumpMod", Callback=function(v)
    S.JumpMod=v; if not v then local h=getHum(); if h then pcall(function() h.JumpPower=50 end) end end
end})
MovementTab:CreateSlider({Name="Jump Power", Range={50,500}, Increment=5, Suffix="pwr", CurrentValue=50, Flag="JumpPower", Callback=function(v) S.JumpPower=v end})
MovementTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Flag="InfiniteJump", Callback=function(v) S.InfiniteJump=v end})
MovementTab:CreateToggle({Name="Spin Bot (fling)", CurrentValue=false, Flag="SpinBot", Callback=function(v) S.SpinBot=v end})
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
FarmTab:CreateToggle({Name="Auto Farm Target", CurrentValue=false, Flag="AutoFarm", Callback=function(v)
    if v and not S.FarmTarget then
        Rayfield:Notify({Title="Cozy Hub", Content="Pick a target first.", Duration=3})
        v=false
    end
    S.AutoFarm=v
end})
FarmTab:CreateToggle({Name="Go Under Target", CurrentValue=true, Flag="FarmUnder", Callback=function(v) S.FarmUnder=v end})
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
UtilityTab:CreateButton({Name="Unload Cozy Hub", Callback=function()
    for _,c in pairs(Conns) do pcall(function() c:Disconnect() end) end
    clearESP(); clearHighlights(); flyCleanup(); restoreHitboxes()
    if reachPart then pcall(function() reachPart:Destroy() end) end
    if floatPart then pcall(function() floatPart:Destroy() end) end
    local h=getHum(); if h then setRagdollStates(h, true) end
    for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
    pcall(function() Rayfield:Destroy() end)
end})

UtilityTab:CreateSection("Status")
UtilityTab:CreateParagraph({Title="Remote", Content = JoltReliable and "Jolt_Reliable linked. Live timestamps active." or "Jolt_Reliable NOT found — combat remotes disabled. Rejoin and retry."})
UtilityTab:CreateParagraph({Title="Kill Aura tip", Content="Turn on Kill Aura + M1 Hitbox Expander together. Clicks do the damage; the expander makes them land from range."})

Rayfield:Notify({Title="Cozy Hub v2.1", Content = JoltReliable and "Loaded — remotes linked." or "Loaded, but Jolt remote missing.", Duration=6})
