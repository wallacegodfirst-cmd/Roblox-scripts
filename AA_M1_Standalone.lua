-- Dream Hub | Ability Arena — M1 EXPANDER + M1 FLING (standalone, no menu)
-- Just the two combat features from the full hub, always ON while this runs:
--   1) M1 EXPANDER  — grows YOUR arms (long spear reach, fling-proofed) + the enemy Hitbox parts,
--                     so your real M1s land from far away. Same engine as the full hub (all bug fixes).
--   2) M1 FLING     — every M1 click also sends a burst of real-format UseM1A packets with fresh
--                     timestamps, so one punch lands like many (One Punch).
-- Tune below or set the _G values BEFORE the loadstring.

local ARM_REACH   = tonumber(_G.AA_M1_SIZE)   or 80    -- arm reach (studs); the hub slider's default
local PUNCHES     = tonumber(_G.AA_M1_HITS)   or 8     -- extra M1 packets per click (1-25)
local SHOW_HITBOX = (_G.AA_M1_SHOW ~= false)           -- cyan enemy hitboxes; _G.AA_M1_SHOW=false hides them

local Players             = game:GetService("Players")
local Workspace           = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local PhysicsService      = game:GetService("PhysicsService")
local RS                  = game:GetService("ReplicatedStorage")
local LP                  = Players.LocalPlayer

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Dream Hub", Text = "M1 Expander + Fling ON", Duration = 4 })
end)

-- ── helpers (ported from the hub) ─────────────────────────────────────────────
local function getRoot()
    local c = LP.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end
local function isAlive(char)
    if not char or not char.Parent then return false end
    if char:GetAttribute("Dead") == true or char:FindFirstChild("Dead") then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then return h.Health > 0 end
    local hp = char:GetAttribute("Health")
    if type(hp) == "number" then return hp > 0 end
    return true   -- custom health we cannot read -> assume alive so they stay targetable
end
local function typingNow()
    local ok, box = pcall(function() return UserInputService:GetFocusedTextBox() end)
    return ok and box ~= nil
end

-- ── remote layer (Jolt_Reliable wants BUFFERS) ────────────────────────────────
local JoltReliable
pcall(function()
    JoltReliable = RS:WaitForChild("Files", 10)
        :WaitForChild("Shared"):WaitForChild("Components")
        :WaitForChild("Jolt"):WaitForChild("Utils")
        :WaitForChild("Remotes"):WaitForChild("Jolt_Reliable")
end)
local CAN_BUFFER = (type(buffer) == "table" and type(buffer.fromstring) == "function")
local function toWire(s)
    if CAN_BUFFER then local ok, b = pcall(buffer.fromstring, s); if ok then return b end end
    return s
end
local function fireRaw(payload)
    if not JoltReliable then return end
    pcall(function() JoltReliable:FireServer(toWire(payload), {}) end)
end
local function nowStamp()
    local t = 0
    pcall(function() t = Workspace:GetServerTimeNow() end)
    if t == 0 then pcall(function() t = os.clock() end) end
    return string.pack("<d", t)
end

-- ── enemy hitbox targets/parts ────────────────────────────────────────────────
local function hitboxParts(char)
    local out = {}
    for _, nm in ipairs({ "Hitbox", "HitBox", "HitboxPart", "Hit" }) do
        local hb = char:FindFirstChild(nm)
        if hb then
            if hb:IsA("BasePart") then out[#out+1] = hb
            elseif hb:IsA("Model") or hb:IsA("Folder") or hb:IsA("Configuration") then
                for _, d in ipairs(hb:GetDescendants()) do if d:IsA("BasePart") then out[#out+1] = d end end
            end
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then out[#out+1] = hrp end
    return out   -- ONLY the dedicated hit parts: growing the visible body made enemies invisible giants
end
local function hitboxTargets()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then out[#out+1] = p.Character end
    end
    local chars = Workspace:FindFirstChild("Characters")
    if chars then
        for _, m in ipairs(chars:GetChildren()) do
            if m:IsA("Model") and m.Name ~= LP.Name and not Players:FindFirstChild(m.Name) and isAlive(m) then out[#out+1] = m end
        end
    end
    return out
end

-- ── collision group so the giant arms hit NOTHING (no fling/reset on you) ─────
local HITBOX_GROUP = "MH_M1NoCollide"
pcall(function() PhysicsService:RegisterCollisionGroup(HITBOX_GROUP) end)
local function sweepCollisionGroups()
    pcall(function()
        PhysicsService:CollisionGroupSetCollidable(HITBOX_GROUP, "Default", false)
        for _, g in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
            pcall(function() PhysicsService:CollisionGroupSetCollidable(HITBOX_GROUP, g.name, false) end)
        end
    end)
end
sweepCollisionGroups()
task.spawn(function() while true do task.wait(5); sweepCollisionGroups() end end)   -- groups added later must not collide either

-- ── ARM EXPANDER ──────────────────────────────────────────────────────────────
-- The game runs CLIENT-SIDE hit detection off your REAL arm parts, then reports the hits itself.
-- Growing YOUR arms (long + thin, shoved forward through the shoulder Motor6D.C0) makes the native
-- detector reach far enemies and fire the correct packets for us.
local realArmOriginals = {}   -- arm part -> original props
local armC0 = {}              -- Motor6D -> original C0
local function armMotor(arm)
    local char = LP.Character; if not char then return nil end
    for _, j in ipairs(char:GetDescendants()) do
        if j:IsA("Motor6D") and j.Part1 == arm then return j end
    end
end
local function myArmParts()   -- OUTERMOST part only (R15 Hand, else R6 Arm) — the whole chain flings
    local out = {}
    local char = LP.Character
    if not char then return out end
    for _, nm in ipairs({ "LeftHand", "RightHand" }) do
        local a = char:FindFirstChild(nm); if a and a:IsA("BasePart") then out[#out+1] = a end
    end
    if #out == 0 then
        for _, nm in ipairs({ "Left Arm", "Right Arm", "LeftArm", "RightArm" }) do
            local a = char:FindFirstChild(nm); if a and a:IsA("BasePart") then out[#out+1] = a end
        end
    end
    return out
end
local function clearMyHitLog()   -- cleared at swing START only (per-frame clearing = repeat-hit kick)
    pcall(function()
        local mine = Workspace:FindFirstChild(LP.Name)
        local log = mine and mine:FindFirstChild("HitLog")
        if log then for _, c in ipairs(log:GetChildren()) do c:Destroy() end end
    end)
end

local hbOriginal = {}
local armSpawnT = tick()
LP.CharacterAdded:Connect(function() armSpawnT = tick() end)
RunService.Heartbeat:Connect(function()
    -- YOUR arms
    if tick() - armSpawnT >= 3 then   -- 3s spawn grace: normal arms while the game places you
        for arm in pairs(realArmOriginals) do if (not arm) or (not arm.Parent) then realArmOriginals[arm] = nil end end
        for m in pairs(armC0) do if (not m) or (not m.Parent) then armC0[m] = nil end end
        local fwdLen = ARM_REACH * 1.5
        local side   = math.min(ARM_REACH * 0.6, 14)   -- long + thin: a fat cube swallowed your own hitbox
        local targetSize = Vector3.new(side, side, fwdLen)
        local fwdOff = fwdLen * 0.35
        for _, arm in ipairs(myArmParts()) do
            local m = armMotor(arm)
            if m then
                if not realArmOriginals[arm] then
                    realArmOriginals[arm] = { size = arm.Size }
                    armC0[m] = armC0[m] or m.C0
                end
                pcall(function()
                    pcall(function() arm.CollisionGroup = HITBOX_GROUP end)
                    arm.CanCollide = false
                    arm.Massless   = true
                    arm.CanQuery   = true    -- the game's GetPartBoundsInBox reads this
                    arm.CanTouch   = false   -- MUST stay false: kill bricks .Touched on giant arms = death on spawn
                    if (arm.Size - targetSize).Magnitude > 0.1 then arm.Size = targetSize end
                    arm.LocalTransparencyModifier = 0.3
                    m.C0 = CFrame.new(0, 0, -fwdOff) * armC0[m]   -- refresh EVERY frame from the original C0
                end)
            end
        end
    end
    -- ENEMY hitboxes
    for part in pairs(hbOriginal) do if not part or not part.Parent then hbOriginal[part] = nil end end
    local sz = ARM_REACH
    local cube = Vector3.new(sz, sz, sz)
    for _, char in ipairs(hitboxTargets()) do
        for _, part in ipairs(hitboxParts(char)) do
            if not hbOriginal[part] then
                hbOriginal[part] = { size = part.Size, transp = part.Transparency, touch = part.CanTouch, color = part.Color, material = part.Material }
            end
            local o = hbOriginal[part]
            pcall(function()
                part.Massless   = true
                part.CanCollide = false
                part.CanQuery   = true
                part.CanTouch   = (o and o.touch) or false   -- keep ORIGINAL CanTouch: forcing true let their touch-damage hurt YOU
                if (part.Size - cube).Magnitude > 0.1 then part.Size = cube end
                if SHOW_HITBOX then
                    if part.Transparency ~= 0.82 then part.Transparency = 0.82; part.Color = Color3.fromRGB(0, 220, 255); part.Material = Enum.Material.ForceField end
                elseif o and part.Transparency ~= o.transp then
                    part.Transparency = o.transp; part.Color = o.color; part.Material = o.material
                end
            end)
        end
    end
end)

-- ── M1 FLING (One Punch packet burst) ─────────────────────────────────────────
-- Real M1 wire format (SimpleSpy capture of a live swing):
--   \005 UseM1A \003 .  <8-byte GetServerTimeNow>  \000\000  <32-hex session id>  \001\000\000\000
-- Each click sends PUNCHES extra ones with fresh timestamps on top of your real swing.
local OP_PRE  = string.char(5) .. "UseM1A" .. string.char(3) .. "."
local OP_MID  = string.char(0, 0)
local OP_TAIL = string.char(1, 0, 0, 0)
local function opRandomId()
    local hex, t = "0123456789abcdef", {}
    for i = 1, 32 do local n = math.random(1, 16); t[i] = hex:sub(n, n) end
    return table.concat(t)
end
local function opIs32Hex(v) return type(v) == "string" and #v == 32 and v:match("^%x+$") ~= nil end
local opFoundId = nil
local function opSessionId()
    if opIs32Hex(_G.AA_M1_GUID) then return _G.AA_M1_GUID end   -- paste from a fresh capture if auto misses
    if opFoundId then return opFoundId end
    pcall(function()
        local char = LP.Character
        if not char then return end
        for _, v in pairs(char:GetAttributes()) do if opIs32Hex(v) then opFoundId = v; return end end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("StringValue") and opIs32Hex(d.Value) then opFoundId = d.Value; return end
            for _, v in pairs(d:GetAttributes()) do if opIs32Hex(v) then opFoundId = v; return end end
        end
    end)
    return opFoundId or opRandomId()
end
LP.CharacterAdded:Connect(function() opFoundId = nil end)   -- session id may change on respawn
local function buildM1A() return OP_PRE .. nowStamp() .. OP_MID .. opSessionId() .. OP_TAIL end

local onePunchCD = 0
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if typingNow() then return end
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
    clearMyHitLog()   -- swing start: repeated swings keep landing on the same target
    if tick() - onePunchCD < 0.25 then return end
    onePunchCD = tick()
    task.spawn(function()
        local n = math.clamp(PUNCHES, 1, 25)
        for _ = 1, n do
            fireRaw(buildM1A())   -- your real click already fired the game's own M1; these stack on top
            task.wait(0.03)
        end
    end)
end)
