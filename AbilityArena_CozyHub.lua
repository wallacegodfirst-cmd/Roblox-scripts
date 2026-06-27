-- Valutix Hub | Ability Arena | v2.13.3
-- by Valutix Hub Owner
-- v2.8.0: Kill Aura fixed (crash bug killed the loop), real clicking, One Shot Punch
--         remote wired into every M1, fixed M1 packet bytes, buffer sends, hitbox
--         expanders reworked (M1 + Ability share one engine), Teleports tab added.
-- v2.8.1: manual-click one shot debounced (no more self-kick from click flooding)
--         + skipped while typing; Kill Aura no longer secretly forces the M1 Hitbox
--         toggle on (it used to stay stuck on after you turned Kill Aura off).
-- v2.9.0: Kill Aura targeting reworked - this game's characters often have NO
--         Humanoid (they use a custom "Hitbox" part + a "Health" script), so the
--         old "require a Humanoid" target test matched nobody = Kill Aura did
--         nothing. Now targets the Hitbox directly. Added God Mode (best effort,
--         off the Health object) and an Add Aura feature (client-side visual).
-- v2.9.1: removed the M1 + Ability hitbox expanders (server-side hit validation
--         meant they never landed - they only made enemies look big). Auras now
--         force every emitter/light ON and re-emit every 0.5s so you SEE the glow
--         (not just the mesh), it stays on, and re-applies after you respawn.
-- v2.9.2: removed God Mode + One Shot. Added Save Health (low HP -> fly to sky,
--         hold, drop back when healed). Anti Void/Water no longer needs a
--         Humanoid (raycast ground-memory). Kill Aura auto-click now SKIPS firing
--         whenever your real cursor is over the Rayfield menu.
-- v2.9.3: brought BACK the M1 + Ability hitbox expanders (this game does
--         client-side hit detection - the M1 packet has a "Hits" list - so
--         growing the enemy Hitbox makes your real M1s reach farther; now
--         targets via isAlive so it applies with no Humanoid). Removed Kill Aura.
-- v2.9.4: Auto Dash -> "Dash Behind On Hit" (M1 snaps you behind the nearest
--         enemy - which also LANDS the M1 point-blank - then dashes Q; removed the
--         LeftShift/shift-lock that messed your camera). Save Health now ANCHORS you
--         in the sky (default 700) so knockback can't pull you out. Auras strip
--         GUIs + weld every VFX part to your body so all the effects actually show.
-- v2.9.5: Ability Grabber now RETURNS you to a real map spawn (workspace.GameMap
--         .Spawns) after grabbing instead of stranding you in the lobby to die;
--         "Return to map spawn" defaults ON. TP To Spawn button uses GameMap.Spawns too.
-- v2.9.6: GameMap.Spawns turned out to BE the lobby, so the grab now returns you to
--         your EXACT pre-grab spot on the map (backCF) instead. Hitbox + Ability
--         Hitbox sizes bumped (50/40, up to 150) so the reach is big enough for the
--         game's overlap check to register your hits.
-- v2.9.7: ESP now reads HP for characters with NO Humanoid (custom Health) so the
--         label is never blank. Added "Remove Water Border" (destroys the invisible
--         Border.Water walls so Anti Water actually holds) and "Anti Kill Bricks"
--         (destroys Workspace.KillBricks so they can't touch-kill you). Both are
--         toggles that re-clear every second to beat re-replication.
-- v2.9.8: neon-red Rayfield theme (near-black UI, glowing red toggles/sliders/tabs).
-- v2.9.9: rebranded to Valutix Hub; added a Home tab + per-tab sidebar icons.
-- v2.10.0: teleport fixes (no fling, removed lobby TP-to-Spawn, safe Click-TP, auto-refresh
--          target lists, Save-Health-safe Safe-Spawn) + full Unload disconnect + lighting restore.
-- v2.11.0: richer ESP (ability + colored health bar + 2D boxes + max-distance), View Player
--          (spectate), and a stronger hitbox (handles Model hitboxes + whole-body, cap 300).
-- v2.11.1: fixed Auto Farm / Auto Play - now face the target, no fling, correct position.
-- v2.11.2: Auto Farm/Play only teleport when out of range (>8 studs), then just face the
--          target - stops the constant snap-back/rubber-banding.
-- v2.12.0: added best-effort God Mode (re-applies full HP + flips existing safe/damage flags).
-- v2.13.0: added Ability Aim Assist (face nearest enemy w/ velocity lead on skill cast).
-- v2.13.1: removed God Mode.
-- v2.13.2: Auto Farm/Play now actually deal damage - auto-grow the enemy hitbox while on,
--          and force the M1 click so it fires even with the menu open.
-- v2.13.3: Auto Farm/Play M1 lands consistently - throttled swing cadence (~0.35s) so the M1
--          isn't cancelled before its hit-frame; abilities spaced out so they don't interrupt it.

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

-- ============================================================
-- SETTINGS (must be defined BEFORE any function that reads it)
-- ============================================================
local S = {
    AntiRagdoll=false, AntiPush=false, AntiVoid=false,
    SaveHealth=false, SaveHealthPct=35, SaveHealthHeight=700,
    RemoveWaterBorder=false, AntiKillBricks=false,
    M1Hitbox=false, M1HitboxSize=50,
    HitboxAbility=false, HitboxAbilitySize=40, HitboxAllParts=false,
    AutoM1=false,
    AutoAbility=false, AutoAbilityRange=25,
    CastE=true, CastQ=false, CastR=false, CastT=false,
    DashBehind=false, DashRange=45,
    AutoDash=false, AutoDashKey="Q", AutoDashDelay=0.6,
    CamLock=false, CamLockRange=120,
    AimAssist=false, AimAssistRange=140, AimAssistLead=0.12,
    Fly=false, FlySpeed=60,
    Noclip=false,
    SpeedHack=false, Speed=16,
    InfiniteJump=false,
    SpinBot=false, AntiFling=false,
    ESP=false, ESPColor=true, Tracers=false, ESPBox=false, ESPAbility=true, ESPMaxDist=0,
    Viewing=nil, ViewTarget=nil,
    EnemyHighlight=false, HighlightColor="Bright blue",
    FullBright=false,
    AutoFarm=false, FarmTarget=nil,
    AutoPlay=false, AutoPlayRange=100,
    AntiAFK=false, InstantRespawn=false, ClickTP=false,
    GrabDelay=3, GrabReturn=true,
    TPTarget=nil,
}

local function getChar() return LP.Character end
local function getHum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()
    local c=LP.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end

-- This game's player characters live in Workspace named by username, each with a
-- custom "Hitbox" part and a "Health" script - MANY HAVE NO STANDARD HUMANOID.
-- Targeting must NOT require a Humanoid (that is exactly why Kill Aura found
-- nobody). charPart() returns the best part to aim at; isAlive() never excludes
-- a player just because we cannot read a Humanoid.
local function charPart(char)
    if not char then return nil end
    local hb = char:FindFirstChild("Hitbox")
    if hb then
        if hb:IsA("BasePart") then return hb end
        if hb:IsA("Model")    then return hb.PrimaryPart or hb:FindFirstChildWhichIsA("BasePart") end
    end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
end
local function isAlive(char)
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then return h.Health > 0 end
    local hp = char:GetAttribute("Health")
    if type(hp) == "number" then return hp > 0 end
    return true -- custom health we cannot read -> assume alive so they stay targetable
end

-- A safe MAP SPAWN to land on (workspace.GameMap.Spawns = invisible neon Parts).
-- Used to return you to the map after grabbing an ability so you don't get
-- stranded in the lobby / ability area and die.

-- ============================================================
-- REMOTE LAYER (Jolt_Reliable wants BUFFERS, not strings)
-- ============================================================
local JoltReliable
pcall(function()
    JoltReliable = RS:WaitForChild("Files",10)
        :WaitForChild("Shared"):WaitForChild("Components")
        :WaitForChild("Jolt"):WaitForChild("Utils")
        :WaitForChild("Remotes"):WaitForChild("Jolt_Reliable")
end)

local CAN_BUFFER = (type(buffer) == "table" and type(buffer.fromstring) == "function")
local function toWire(s)
    if CAN_BUFFER then
        local ok, b = pcall(buffer.fromstring, s)
        if ok then return b end
    end
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

-- M1 packet. NOTE: old version had a stray byte (199) glued to the timestamp
-- marker which corrupted every M1 - removed. Timestamp is exactly 8 bytes.
local M1_HEAD = string.char(5).."UseM1"..string.char(65,16,3,9).."Timestamp"..string.char(2)
local M1_TAIL = string.char(3,5).."Index"..string.char(17,32,3,4).."Hits"..string.char(16,0,0)
local function buildM1() return M1_HEAD .. nowStamp() .. M1_TAIL end

-- StartSkill packet, NEW format (taken from the One Shot Punch capture):
-- \10 StartSkill \131\17\0 \3 <len><name> \16\3 \9 Timestamp \2 <8-byte time> \0
local SK_HEAD = string.char(10).."StartSkill"..string.char(131,17,0,3)
local SK_MID  = string.char(16,3,9).."Timestamp"..string.char(2)
local function buildSkillNew(name)
    return SK_HEAD .. string.char(#name) .. name .. SK_MID .. nowStamp() .. string.char(0)
end

-- legacy StartSkill format (kept as a fallback for direction skills like Dash)
local function buildSkillOld(skill, direction)
    direction = direction or "Forward"
    return string.char(10).."StartSkillB"..string.char(3)..string.char(#skill)..skill
        ..string.char(16,3,9).."Direction"..string.char(3)..string.char(#direction)..direction
        ..string.char(3,9).."Timestamp"..string.char(2)..nowStamp()..string.char(0)
end
-- new format + a Direction field (best guess for dash on the new schema)
local function buildSkillNewDir(skill, direction)
    direction = direction or "Forward"
    return SK_HEAD .. string.char(#skill) .. skill
        ..string.char(16,3,9).."Direction"..string.char(3)..string.char(#direction)..direction
        ..string.char(3,9).."Timestamp"..string.char(2)..nowStamp()..string.char(0)
end

local function fireM1() fireRaw(buildM1()) end
local function fireSkill(skill) fireRaw(buildSkillNew(skill)) end
local function fireDash(direction)
    fireRaw(buildSkillNewDir("Dash", direction))
    fireRaw(buildSkillOld("Dash", direction))
end

-- ============================================================
-- CLICKING (real M1s come from real clicks)
-- ============================================================
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
    return nil -- every candidate is under the menu: skip rather than click the menu
end

local function doClick(pt)
    if not pt then return end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, true,  game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, false, game, 0)
    end)
end

-- true when the user's REAL cursor is over a GUI (the Rayfield menu etc.). The
-- auto-clicker skips clicking then, so hovering the menu never fires a click.
local function mouseOverGui()
    local m = LP:GetMouse(); if not m then return false end
    local conts = {}
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if pg then conts[#conts+1] = pg end
    pcall(function() if gethui then conts[#conts+1] = gethui() end end)
    pcall(function() conts[#conts+1] = game:GetService("CoreGui") end)
    for _,c in ipairs(conts) do
        local ok, objs = pcall(function() return c:GetGuiObjectsAtPosition(m.X, m.Y) end)
        if ok and objs and #objs > 0 then return true end
    end
    return false
end

local function clickM1(force)
    if typingNow() then return end
    if not force and mouseOverGui() then return end
    doClick(safeClickPoint())
end

local function clickAtTarget(target)
    if typingNow() or mouseOverGui() then return end
    local char = target and target.Character
    local tr   = char and charPart(char)
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

local Conns = {}
local function bind(name, conn)
    if Conns[name] then pcall(function() Conns[name]:Disconnect() end) end
    Conns[name] = conn
end

-- Track every top-level event connection so Unload can fully disconnect them.
local Listeners = {}
local function hook(sig, fn) local c = sig:Connect(fn); Listeners[#Listeners+1] = c; return c end

-- ============================================================
-- TARGET HELPERS
-- ============================================================
local function enemiesInRange(range)
    local out, root = {}, getRoot()
    if not root then return out end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then
            local r = charPart(p.Character)
            if r and (r.Position-root.Position).Magnitude <= range then
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
        if p ~= LP and p.Character and isAlive(p.Character) then
            local r = charPart(p.Character)
            if r then
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

-- ============================================================
-- HITBOX EXPANDERS (M1 + Ability). This game does CLIENT-SIDE hit
-- detection (the M1 packet carries a "Hits" list), so growing the
-- ENEMY hitbox on your client lets your real M1s + abilities reach
-- them from much farther. Both expanders grow the enemy "Hitbox"
-- part (+ HumanoidRootPart). Ability pulses 1.5x bigger on E. The
-- enlarged hitbox is shown faint-red so you can SEE the reach.
-- Targets via isAlive() (NOT a Humanoid - this game's chars lack one).
-- ============================================================
local hbOriginal = {}   -- keyed by the BasePart instance -> original props
local abilityBurstUntil = 0
local function restoreHitboxes()
    for part, orig in pairs(hbOriginal) do
        if part and part.Parent then pcall(function()
            part.Size = orig.size; part.Transparency = orig.transp
            part.CanCollide = orig.collide; part.Massless = orig.massless
            part.CanTouch = orig.touch; part.CanQuery = orig.query
            part.Color = orig.color; part.Material = orig.material
        end) end
    end
    hbOriginal = {}
end

local function wantedHitboxSize()
    local sz = 0
    if S.M1Hitbox or S.AutoFarm or S.AutoPlay then sz = math.max(sz, S.M1HitboxSize) end
    if S.HitboxAbility then
        local a = S.HitboxAbilitySize
        if tick() < abilityBurstUntil then a = a * 1.5 end
        sz = math.max(sz, a)
    end
    return sz
end

-- Parts to grow on an enemy. Fixes the old bug where a Model "Hitbox" was
-- skipped entirely (only direct BaseParts were grown). Optionally grows EVERY
-- BasePart in the character for maximum reach.
local function hitboxParts(char)
    local out = {}
    local hb = char:FindFirstChild("Hitbox")
    if hb then
        if hb:IsA("BasePart") then out[#out+1] = hb
        elseif hb:IsA("Model") then
            for _,d in ipairs(hb:GetDescendants()) do if d:IsA("BasePart") then out[#out+1] = d end end
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then out[#out+1] = hrp end
    if S.HitboxAllParts then
        for _,d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then out[#out+1] = d end end
    end
    return out
end

hook(RunService.Heartbeat, function()
    local sz = wantedHitboxSize()
    if sz <= 0 then
        if next(hbOriginal) then restoreHitboxes() end
        return
    end
    -- prune destroyed/removed parts so hbOriginal can't grow without bound
    for part in pairs(hbOriginal) do
        if not part or not part.Parent then hbOriginal[part] = nil end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isAlive(p.Character) then
            for _,part in ipairs(hitboxParts(p.Character)) do
                if not hbOriginal[part] then
                    hbOriginal[part] = {
                        size=part.Size, transp=part.Transparency,
                        collide=part.CanCollide, massless=part.Massless,
                        touch=part.CanTouch, query=part.CanQuery,
                        color=part.Color, material=part.Material
                    }
                end
                pcall(function()
                    part.Massless    = true
                    part.CanCollide  = false
                    part.CanQuery    = true
                    part.CanTouch    = true
                    if part.Size.X ~= sz then part.Size = Vector3.new(sz, sz, sz) end
                    part.Transparency = 0.55
                    part.Color        = Color3.fromRGB(255, 60, 60)
                    part.Material     = Enum.Material.ForceField
                end)
            end
        end
    end
end)

-- pressing E pulses the Ability expand bigger for a moment
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.E and S.HitboxAbility then
        abilityBurstUntil = tick() + 0.6
    end
end)

-- a faint ball on YOU so you can see your ability reach (visual only)
local abilityHbPart = nil
local function destroyAbilityHb()
    if abilityHbPart then pcall(function() abilityHbPart:Destroy() end); abilityHbPart = nil end
end
task.spawn(function()
    while task.wait(0.2) do
        if S.HitboxAbility then
            local root = getRoot()
            if root then
                if not abilityHbPart or abilityHbPart.Parent == nil then
                    destroyAbilityHb()
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
                    local w = Instance.new("Weld")
                    w.Part0 = root; w.Part1 = abilityHbPart; w.Parent = abilityHbPart
                    abilityHbPart.Parent = root.Parent
                end
                local sz = S.HitboxAbilitySize
                if tick() < abilityBurstUntil then sz = sz * 1.5 end
                pcall(function() abilityHbPart.Size = Vector3.new(sz, sz, sz) end)
            end
        else
            destroyAbilityHb()
        end
    end
end)

-- ============================================================
-- ABILITY GRABBER
-- ============================================================
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
local grabNoclip = false  -- forces noclip while grabbing so the TP can't get you stuck or killed
local function grabAbility(name)
    if grabbing or not name or name == "" then return end
    local f = findElementFolder()
    if not f then
        Rayfield:Notify({Title="Valutix Hub", Content="ElementSelection not found - are you in the lobby?", Duration=4})
        return
    end
    local pad = f:FindFirstChild(name); if not pad then return end
    local root = getRoot(); if not root then return end
    grabbing = true
    task.spawn(function()
        local backCF = root.CFrame
        grabNoclip = true                    -- noclip ON in the background for the whole trip
        local padPos = pad:IsA("BasePart") and pad.Position or pad:GetPivot().Position
        pcall(function()
            root.CFrame = CFrame.new(padPos + Vector3.new(0, 4, 0))
            root.Anchored = true             -- HOLD at the pad so noclip can't sink you through the floor (that was the death)
        end)
        task.wait(0.5)
        tapKey(Enum.KeyCode.E)
        task.wait(S.GrabDelay)               -- wait the seconds you set, THEN teleport back
        local r = getRoot() or root
        pcall(function() r.Anchored = false end)   -- release before returning
        if S.GrabReturn and r then           -- back to EXACTLY where you were on the map
            pcall(function() r.CFrame = backCF end)
        end
        task.wait(0.3)                        -- settle a moment before collisions return
        grabNoclip = false
        if not S.Noclip then                  -- restore collisions (unless you have Noclip on)
            local c = getChar()
            if c then for _,pt in ipairs(c:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" then pcall(function() pt.CanCollide = true end) end
            end end
        end
        grabbing = false
    end)
end

-- ============================================================
-- AURAS  (client-side visual: clones a VFX onto your arms and KEEPS it
-- emitting so it stays on and you actually see the glow, not just the
-- mesh. Shows on YOUR screen - a server-side aura everyone sees needs the
-- equip remote remote-spied, same as the One Shot Punch capture.)
-- ============================================================
local function vfxFolder()
    local a = RS:FindFirstChild("Assets");   if not a then return nil end
    local v = a:FindFirstChild("VfxAssets"); if not v then return nil end
    return v:FindFirstChild("AbilitiesVfx")
end
local function auraNames()
    local out, f = {}, vfxFolder()
    if f then
        for _,c in ipairs(f:GetChildren()) do out[#out+1] = c.Name end
        table.sort(out)
    end
    return out
end

-- turn EVERY visual component on (this is the fix for "I only see the physics":
-- the emitters ship disabled because the game fires them on cast, so a plain
-- clone showed just the solid part).
local function enableVfx(inst)
    local function on(d)
        if d:IsA("ParticleEmitter") then
            pcall(function() d.Enabled = true; if d.Rate < 1 then d.Rate = 25 end; d:Emit(40) end)
        elseif d:IsA("Beam") or d:IsA("Trail") then
            pcall(function() d.Enabled = true end)
        elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
            pcall(function() d.Enabled = true end)
        elseif d:IsA("BasePart") then
            pcall(function() d.CanCollide=false; d.CanQuery=false; d.Massless=true; d.Anchored=false end)
        end
    end
    on(inst)
    for _,d in ipairs(inst:GetDescendants()) do on(d) end
end

local activeAura = nil
local auraParts = {}
local function clearAura()
    activeAura = nil
    for _,inst in ipairs(auraParts) do pcall(function() inst:Destroy() end) end
    auraParts = {}
end
local function auraMounts(char)
    local mounts = {}
    -- body centre first so the aura wraps you, then the game's own arm spots
    for _,nm in ipairs({"Torso","UpperTorso","HumanoidRootPart"}) do
        local part = char:FindFirstChild(nm)
        if part and part:IsA("BasePart") then mounts[#mounts+1] = part; break end
    end
    for _,armName in ipairs({"Left Arm","Right Arm"}) do
        local arm = char:FindFirstChild(armName)
        if arm then
            local fx   = arm:FindFirstChild("Effects")
            local hand = fx and fx:FindFirstChild("Hand")
            local m = hand or arm
            if not m:IsA("BasePart") then m = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") end
            if m then mounts[#mounts+1] = m end
        end
    end
    if #mounts == 0 then local cp = charPart(char); if cp then mounts[1] = cp end end
    return mounts
end
local function applyAuraNow(name)
    local f = vfxFolder(); if not f then return end
    local src = name and f:FindFirstChild(name); if not src then return end
    local char = getChar(); if not char then return end
    for _,mount in ipairs(auraMounts(char)) do
        local clone = src:Clone()
        clone.Name = "MFHAura"
        pcall(function()
            -- drop the non-visual bits (Interface GUIs, AbilitiesDesc config, scripts)
            -- so only the actual VFX remain
            local junk = {}
            for _,d in ipairs(clone:GetDescendants()) do
                if d:IsA("LayerCollector") or d:IsA("GuiObject") or d:IsA("GuiBase")
                or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                    junk[#junk+1] = d
                end
            end
            for _,d in ipairs(junk) do pcall(function() d:Destroy() end) end
            clone.Parent = mount
            -- glue EVERY part to the mount so no VFX part is left stranded at world origin
            local function glue(part)
                pcall(function()
                    part.CanCollide=false; part.CanQuery=false; part.Massless=true; part.Anchored=false
                    part.CFrame = mount.CFrame
                    local w = Instance.new("WeldConstraint"); w.Part0 = mount; w.Part1 = part; w.Parent = part
                end)
            end
            if clone:IsA("BasePart") then glue(clone) end
            for _,d in ipairs(clone:GetDescendants()) do if d:IsA("BasePart") then glue(d) end end
            enableVfx(clone)
        end)
        auraParts[#auraParts+1] = clone
    end
end
local function addAura(name)
    local f = vfxFolder()
    if not f then Rayfield:Notify({Title="Valutix Hub", Content="VFX assets folder not found.", Duration=3}); return end
    if not (name and f:FindFirstChild(name)) then Rayfield:Notify({Title="Valutix Hub", Content="Pick an aura first.", Duration=3}); return end
    clearAura()
    activeAura = name
    applyAuraNow(name)
    Rayfield:Notify({Title="Valutix Hub", Content="Aura '"..name.."' on - it stays until you Remove it.", Duration=4})
end
-- keep the aura alive + emitting so it "stands longer" (re-emits every 0.5s)
task.spawn(function()
    while task.wait(0.5) do
        if activeAura and #auraParts > 0 then
            pcall(function()
                for _,inst in ipairs(auraParts) do
                    if inst and inst.Parent then enableVfx(inst) end
                end
            end)
        end
    end
end)

-- ============================================================
-- SURVIVAL (anti ragdoll / push / void)
-- ============================================================
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

-- Save-Health panic state - declared BEFORE CharacterAdded so the respawn reset
-- below binds to THESE locals (declaring them later made it write a dead global).
local healPanic = false
local healSaveCF = nil
local healPanicT = 0
hook(LP.CharacterAdded, function(char)
    destroyAbilityHb()
    healPanic = false
    task.wait(0.2)
    pcall(applyCharacter, char)
    if activeAura then task.wait(0.4); pcall(function() applyAuraNow(activeAura) end) end
end)
if LP.Character then pcall(applyCharacter, LP.Character) end

local STUN_ATTRS = {"Ragdoll","Ragdolled","Stunned","Stun","Knocked","Knockback","KO","Downed"}
local ragClock = 0
hook(RunService.Heartbeat, function(dt)
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

hook(RunService.Stepped, function()
    if S.Fly then return end
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

-- read the LOCAL player's health, with or without a standard Humanoid
local function getHealth()
    local char = getChar(); if not char then return nil end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.MaxHealth and h.MaxHealth > 0 then return h.Health, h.MaxHealth end
    local cur = char:GetAttribute("Health")
    if type(cur) == "number" then
        local mx = char:GetAttribute("MaxHealth")
        return cur, (type(mx) == "number" and mx > 0 and mx) or 100
    end
    local hv = char:FindFirstChild("Health")
    if hv and (hv:IsA("NumberValue") or hv:IsA("IntValue")) then
        local mv = char:FindFirstChild("MaxHealth")
        local mx = (mv and (mv:IsA("NumberValue") or mv:IsA("IntValue")) and mv.Value) or 100
        return hv.Value, (mx > 0 and mx) or 100
    end
    return nil
end

-- read ANY character's health the same way (used by ESP so the label is never
-- blank for this game's Humanoid-less characters)
local function getTargetHealth(char)
    if not char then return nil end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.MaxHealth and h.MaxHealth > 0 then return h.Health, h.MaxHealth end
    local cur = char:GetAttribute("Health")
    if type(cur) == "number" then
        local mx = char:GetAttribute("MaxHealth")
        return cur, (type(mx) == "number" and mx > 0 and mx) or 100
    end
    local hv = char:FindFirstChild("Health")
    if hv and (hv:IsA("NumberValue") or hv:IsA("IntValue")) then
        local mv = char:FindFirstChild("MaxHealth")
        local mx = (mv and (mv:IsA("NumberValue") or mv:IsA("IntValue")) and mv.Value) or 100
        return hv.Value, (mx > 0 and mx) or 100
    end
    return nil
end

-- Best-effort: which ability/element a player has. This game exposes no
-- guaranteed signal, so we try attributes, StringValue children, a child named
-- like a known ability, then a Tool. Returns nil if it can't tell.
local ABILITY_ATTRS = {"Element","Ability","Move","Class","Skill","Power","Weapon","Kit","Stand","Fruit"}
local _knownAbil, _knownAbilT = nil, 0
local function knownAbilities()
    if _knownAbil and (tick()-_knownAbilT) < 5 then return _knownAbil end
    _knownAbil = {}; _knownAbilT = tick()
    pcall(function() for _,n in ipairs(abilityNames()) do _knownAbil[n] = true end end)
    pcall(function() for _,n in ipairs(auraNames())    do _knownAbil[n] = true end end)
    return _knownAbil
end
local function getPlayerAbility(char)
    if not char then return nil end
    for _,k in ipairs(ABILITY_ATTRS) do
        local v = char:GetAttribute(k); if type(v)=="string" and #v>0 then return v end
    end
    for _,k in ipairs(ABILITY_ATTRS) do
        local sv = char:FindFirstChild(k)
        if sv and sv:IsA("StringValue") and #sv.Value>0 then return sv.Value end
    end
    local known = knownAbilities()
    for _,c in ipairs(char:GetChildren()) do if known[c.Name] then return c.Name end end
    local tool = char:FindFirstChildOfClass("Tool"); if tool then return tool.Name end
    return nil
end

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

hook(RunService.Heartbeat, function()
    if not S.AntiVoid then
        if floatPart then pcall(function() floatPart:Destroy() end); floatPart = nil end
        return
    end
    if S.Fly or S.InfiniteJump or healPanic then hideFloat(); return end  -- don't yank you back while you're meant to be airborne (Fly / Inf Jump / Save-Health)
    local root, char = getRoot(), getChar()
    if not (root and char) then return end
    local hum = getHum()  -- optional: this game's characters may have no Humanoid

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, floatPart}
    local hit = Workspace:Raycast(root.Position, Vector3.new(0, -2000, 0), params)

    local overWater = hit ~= nil and hit.Instance ~= nil and hit.Instance:IsA("Terrain") and hit.Material == Enum.Material.Water
    local overKill  = hit ~= nil and isKillPart(hit.Instance)
    local overVoid  = (hit == nil)
    local floor     = hum and hum.FloorMaterial or nil
    local swimming  = (hum and hum:GetState() == Enum.HumanoidStateType.Swimming) or floor == Enum.Material.Water

    -- remember the last solid, safe ground (works with NO Humanoid - pure raycast)
    if hit and not overWater and not overKill and (root.Position.Y - hit.Position.Y) <= 14 then
        lastSafeCF = root.CFrame
    end

    if swimming then
        showFloat(Vector3.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z))
        root.CFrame = root.CFrame + Vector3.new(0, 4, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
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

-- ============================================================
-- ANTI WATER BORDER + ANTI KILL BRICKS
-- The map fences the water with invisible "Border Part"s under
-- Workspace.Border.Water that shove you back / drown you, and KillBricks
-- under Workspace.KillBricks insta-kill on touch. Removing them client-side
-- is what actually makes "Anti Water" hold and stops the kill bricks. Both
-- toggles destroy on enable AND re-clear every second (the server can
-- re-stream the parts in, so a one-shot wouldn't be enough).
-- ============================================================
local function destroyWaterBorder()
    local cleared = 0
    local roots = {}
    local border = Workspace:FindFirstChild("Border")
    if border then
        local w = border:FindFirstChild("Water")
        if w then roots[#roots+1] = w end
    end
    local w2 = Workspace:FindFirstChild("Water")   -- in case it sits at the top level
    if w2 then roots[#roots+1] = w2 end
    for _,r in ipairs(roots) do
        if r:IsA("BasePart") then pcall(function() r:Destroy() end); cleared += 1 end
        for _,d in ipairs(r:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d:Destroy() end); cleared += 1 end
        end
    end
    return cleared
end

local function destroyKillBricks()
    local cleared = 0
    local kb = Workspace:FindFirstChild("KillBricks")
    if kb then
        for _,d in ipairs(kb:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d:Destroy() end); cleared += 1 end
        end
        if kb:IsA("BasePart") then pcall(function() kb:Destroy() end); cleared += 1 end
    end
    return cleared
end

task.spawn(function()
    while task.wait(1) do
        if S.RemoveWaterBorder then pcall(destroyWaterBorder) end
        if S.AntiKillBricks    then pcall(destroyKillBricks) end
        if S.FullBright        then pcall(function() setFullBright(true) end) end
    end
end)

-- ============================================================
-- SAVE HEALTH (panic): when HP drops below the threshold, fly you up into
-- the sky and HOLD you there so nothing can reach you; when HP is back up
-- (you finished healing), drop you back to exactly where you were.
-- ============================================================
hook(RunService.Heartbeat, function()
    if not S.SaveHealth then
        if healPanic then               -- toggled off mid-panic: bring us back down
            healPanic = false
            local root = getRoot()
            if root then pcall(function() root.Anchored = false end) end
            if root and healSaveCF then pcall(function() root.CFrame = healSaveCF end) end
        end
        return
    end
    local root = getRoot(); if not root then return end
    local cur, max = getHealth()
    local pct = (cur and max and max > 0) and (cur / max * 100) or nil
    if not healPanic and not pct then return end  -- not in panic and HP unreadable -> nothing to do

    -- don't start a sky-escape while you're deliberately airborne (Fly / Inf Jump)
    if not healPanic and pct and pct <= S.SaveHealthPct and not S.Fly and not S.InfiniteJump then
        healPanic  = true
        healSaveCF = root.CFrame
        healPanicT = tick()
    end

    -- if you start flying / inf-jumping mid-panic, release so it can't hold you
    if healPanic and (S.Fly or S.InfiniteJump) then
        healPanic = false
        pcall(function() root.Anchored = false end)
    end

    if healPanic then
        local base = (healSaveCF and healSaveCF.Position) or root.Position
        pcall(function()
            root.Anchored = true        -- anchored so knockback / abilities can't fling you out of the sky
            root.CFrame = CFrame.new(base + Vector3.new(0, S.SaveHealthHeight, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end)
        -- come down when HP recovers a margin ABOVE the trigger (a fixed 90% can be
        -- unreachable if the game heals slowly / caps HP), OR after a 30s safety
        -- timeout. The timeout works even if HP becomes unreadable, so you can
        -- NEVER get stuck anchored in the sky.
        local exitPct = math.min(95, S.SaveHealthPct + 25)
        if (pct and pct >= exitPct) or (tick() - healPanicT) > 30 then
            healPanic = false
            pcall(function() root.Anchored = false end)
            if healSaveCF then pcall(function() root.CFrame = healSaveCF + Vector3.new(0, 3, 0) end) end
        end
    end
end)

-- ============================================================
-- INPUT EXTRAS
-- ============================================================
hook(UserInputService.JumpRequest, function()
    if S.InfiniteJump then
        local h = getHum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- Click TP moved to V (T is an ability key in this game - it was clashing)
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe then return end
    if S.ClickTP and i.KeyCode == Enum.KeyCode.V then
        pcall(function()
            local m = LP:GetMouse()
            if m and m.Target and m.Hit then tpTo(CFrame.new(m.Hit.Position + Vector3.new(0,4,0))) end
        end)
    end
end)

pcall(function()
    hook(LP.Idled, function()
        if not S.AntiAFK then return end
        local vu = game:GetService("VirtualUser")
        vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end)
end)

-- ============================================================
-- MOVEMENT
-- ============================================================
local flyKeys = {W=false,A=false,S=false,D=false,Up=false,Down=false}
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe then return end
    local k=i.KeyCode
    if     k==Enum.KeyCode.W           then flyKeys.W=true
    elseif k==Enum.KeyCode.A           then flyKeys.A=true
    elseif k==Enum.KeyCode.S           then flyKeys.S=true
    elseif k==Enum.KeyCode.D           then flyKeys.D=true
    elseif k==Enum.KeyCode.Space       then flyKeys.Up=true
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=true end
end)
hook(UserInputService.InputEnded, function(i)
    local k=i.KeyCode
    if     k==Enum.KeyCode.W           then flyKeys.W=false
    elseif k==Enum.KeyCode.A           then flyKeys.A=false
    elseif k==Enum.KeyCode.S           then flyKeys.S=false
    elseif k==Enum.KeyCode.D           then flyKeys.D=false
    elseif k==Enum.KeyCode.Space       then flyKeys.Up=false
    elseif k==Enum.KeyCode.LeftControl then flyKeys.Down=false end
end)
hook(RunService.RenderStepped, function(dt)
    if not S.Fly then return end
    local root = getRoot(); if not root then return end
    local hum = getHum()
    if hum then
        pcall(function()
            hum.PlatformStand = true
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end
    local cam = Workspace.CurrentCamera
    local dir = Vector3.zero
    if flyKeys.W    then dir += cam.CFrame.LookVector end
    if flyKeys.S    then dir -= cam.CFrame.LookVector end
    if flyKeys.A    then dir -= cam.CFrame.RightVector end
    if flyKeys.D    then dir += cam.CFrame.RightVector end
    if flyKeys.Up   then dir += Vector3.yAxis end
    if flyKeys.Down then dir -= Vector3.yAxis end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        if dir.Magnitude > 0 then
            root.CFrame = root.CFrame + dir.Unit * S.FlySpeed * dt
        end
    end)
end)
task.spawn(function()
    local wasFlying = false
    while task.wait(0.1) do
        if S.Fly then
            wasFlying = true
        elseif wasFlying then
            wasFlying = false
            local hum = getHum()
            if hum then
                pcall(function()
                    hum.PlatformStand = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
        end
    end
end)

hook(RunService.Stepped, function()
    if not (S.Noclip or grabNoclip) then return end
    local c = getChar(); if not c then return end
    for _,pt in ipairs(c:GetDescendants()) do
        if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end
    end
end)

hook(RunService.RenderStepped, function()
    if not S.CamLock then return end
    local tgt = nearestPlayer(S.CamLockRange); if not tgt or not tgt.Character then return end
    local head = tgt.Character:FindFirstChild("Head") or tgt.Character:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local cam = Workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
end)

-- ============================================================
-- VISUALS
-- ============================================================
local highlights = {}
local function clearHighlights()
    for _,h in pairs(highlights) do pcall(function() h:Destroy() end) end
    highlights = {}
end
hook(RunService.Heartbeat, function()
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
local hasDrawing = (typeof(Drawing) == "table") or (Drawing ~= nil)
local function clearESP()
    for _,d in pairs(espPool) do
        pcall(function() d.bill:Destroy() end)
        if d.line then pcall(function() d.line:Remove() end) end
        if d.box  then pcall(function() d.box:Remove()  end) end
    end
    espPool = {}
end
local function hpColor(frac)
    frac = math.clamp(frac, 0, 1)
    return Color3.fromRGB(math.floor(255*(1-frac)), math.floor(255*frac), 55)
end
local function espLabel(parent, posY, sizeY, txtSize, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0,0,posY,0)
    l.Size     = UDim2.new(1,0,0,sizeY)
    l.Font     = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = txtSize
    l.TextColor3 = Color3.new(1,1,1)
    l.TextStrokeTransparency = 0
    l.Parent = parent
    return l
end
local espTimer = 0
hook(RunService.RenderStepped, function(dt)
    if not (S.ESP or S.Tracers or S.ESPBox) then if next(espPool) then clearESP() end return end
    espTimer += dt
    if espTimer >= 0.3 then
        espTimer = 0
        for name,d in pairs(espPool) do
            local p = Players:FindFirstChild(name)
            if not p or not p.Character then
                pcall(function() d.bill:Destroy() end)
                if d.line then pcall(function() d.line:Remove() end) end
                if d.box  then pcall(function() d.box:Remove()  end) end
                espPool[name] = nil
            end
        end
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and not espPool[p.Name] then
                local head = p.Character.Head
                local bill = Instance.new("BillboardGui")
                bill.Name="MFHESP"; bill.Adornee=head; bill.Size=UDim2.new(0,210,0,58)
                bill.StudsOffset=Vector3.new(0,3,0); bill.AlwaysOnTop=true
                local nameLbl = espLabel(bill, 0.00, 16, 14, true)
                local abilLbl = espLabel(bill, 0.27, 13, 13, true); abilLbl.TextColor3 = Color3.fromRGB(255,70,70)
                local barBG = Instance.new("Frame")
                barBG.Position=UDim2.new(0.1,0,0.54,0); barBG.Size=UDim2.new(0.8,0,0,7)
                barBG.BackgroundColor3=Color3.fromRGB(15,15,15); barBG.BorderSizePixel=0
                barBG.BackgroundTransparency=0.2; barBG.Parent=bill
                local barFill = Instance.new("Frame")
                barFill.Size=UDim2.new(1,0,1,0); barFill.BorderSizePixel=0
                barFill.BackgroundColor3=Color3.fromRGB(0,200,0); barFill.Parent=barBG
                local infoLbl = espLabel(bill, 0.74, 13, 11, false); infoLbl.TextColor3=Color3.fromRGB(215,215,215)
                bill.Parent = head
                local line, box
                if hasDrawing then
                    line = Drawing.new("Line");   line.Thickness=1.5; line.Transparency=1; line.Color=Color3.fromRGB(255,70,70)
                    box  = Drawing.new("Square"); box.Thickness=1.5; box.Filled=false; box.Transparency=1; box.Color=Color3.fromRGB(255,70,70)
                end
                espPool[p.Name] = {bill=bill, nameLbl=nameLbl, abilLbl=abilLbl, barBG=barBG, barFill=barFill, infoLbl=infoLbl, line=line, box=box}
            end
        end
    end
    local cam = Workspace.CurrentCamera
    local myRoot = getRoot()
    for name,d in pairs(espPool) do
        local p    = Players:FindFirstChild(name)
        local char = p and p.Character
        local head = char and char:FindFirstChild("Head")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or charPart(char))
        local dist = (myRoot and root) and math.floor((root.Position-myRoot.Position).Magnitude) or 0
        local within = (S.ESPMaxDist or 0) <= 0 or dist <= S.ESPMaxDist
        local hp, maxHp = getTargetHealth(char)
        local frac = (hp and maxHp and maxHp > 0) and math.clamp(hp/maxHp, 0, 1) or nil
        local col  = (S.ESPColor and frac) and hpColor(frac) or Color3.fromRGB(255,70,70)
        local showText = S.ESP and head ~= nil and within
        d.bill.Enabled = showText
        if showText then
            d.nameLbl.Text = name; d.nameLbl.TextColor3 = col
            d.abilLbl.Text = S.ESPAbility and (getPlayerAbility(char) or "?") or ""
            if frac then
                d.barBG.Visible = true
                d.barFill.Size = UDim2.new(frac,0,1,0)
                d.barFill.BackgroundColor3 = col
                d.infoLbl.Text = string.format("%d/%d  -  %dm", math.floor(hp), math.floor(maxHp), dist)
            else
                d.barBG.Visible = false
                d.infoLbl.Text = string.format("?? HP  -  %dm", dist)
            end
        end
        if d.line then
            if S.Tracers and root and within then
                local sp, on = cam:WorldToViewportPoint(root.Position)
                if on then
                    d.line.Visible=true; d.line.Color=col
                    d.line.From=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    d.line.To=Vector2.new(sp.X, sp.Y)
                else d.line.Visible=false end
            else d.line.Visible=false end
        end
        if d.box then
            if S.ESPBox and head and root and within then
                local topV = cam:WorldToViewportPoint(head.Position + Vector3.new(0,2,0))
                local botV = cam:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
                if topV.Z > 0 and botV.Z > 0 then
                    local bh = math.abs(botV.Y - topV.Y); local bw = bh*0.6
                    local cx = (topV.X + botV.X)/2; local topY = math.min(topV.Y, botV.Y)
                    d.box.Visible=true; d.box.Color=col
                    d.box.Size=Vector2.new(bw, bh); d.box.Position=Vector2.new(cx - bw/2, topY)
                else d.box.Visible=false end
            else d.box.Visible=false end
        end
    end
end)

-- ── VIEW PLAYER (spectate) - reuses Camera.CameraSubject ───────────────────
local function viewPlayer(name)
    local pl = name and Players:FindFirstChild(name); local char = pl and pl.Character
    local subj = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Head") or charPart(char))
    local cam = Workspace.CurrentCamera
    if subj and cam then
        pcall(function() cam.CameraSubject = subj end); S.Viewing = name
        Rayfield:Notify({Title="Valutix Hub", Content="Now viewing "..name..".", Duration=3})
    else
        Rayfield:Notify({Title="Valutix Hub", Content="Player not found.", Duration=3})
    end
end
local function stopView()
    local cam = Workspace.CurrentCamera; local me = getHum() or getRoot()
    if cam and me then pcall(function() cam.CameraSubject = me end) end
    S.Viewing = nil
end
hook(RunService.RenderStepped, function()           -- re-assert subject across respawns
    if not S.Viewing then return end
    local pl = Players:FindFirstChild(S.Viewing); local char = pl and pl.Character
    local subj = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Head"))
    local cam = Workspace.CurrentCamera
    if subj and cam and cam.CameraSubject ~= subj then pcall(function() cam.CameraSubject = subj end) end
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

hook(RunService.Heartbeat, function()
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

-- ============================================================
-- COMBAT LOOPS (every body is pcall-wrapped so one error can
-- never kill the loop - that crash is what broke Kill Aura)
-- ============================================================
-- (Kill Aura removed in v2.9.3 per request - use the hitbox expanders + your own M1.)

task.spawn(function()
    while task.wait(0.12) do
        if S.AutoM1 then
            pcall(function()
                clickM1()
                fireM1()
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if S.AutoAbility then
            pcall(function()
                local enemy = nearestPlayer(S.AutoAbilityRange)
                if enemy and enemy.Character then
                    local r = enemy.Character:FindFirstChild("HumanoidRootPart") or enemy.Character.PrimaryPart
                    if r then faceTo(r.Position) end
                end
                if S.CastE then tapKey(Enum.KeyCode.E) end
                if S.CastQ then tapKey(Enum.KeyCode.Q) end
                if S.CastR then tapKey(Enum.KeyCode.R) end
                if S.CastT then tapKey(Enum.KeyCode.T) end
            end)
        end
    end
end)

-- DASH BEHIND ON HIT: when you M1 (left click) with an enemy near, snap just
-- behind them (this also lands your M1 point-blank) and dash (Q). No more
-- LeftShift / shift-lock messing with your camera.
local lastDashHit = 0
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe then return end
    if not S.DashBehind then return end
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if typingNow() or mouseOverGui() then return end
    local now = tick()
    if now - lastDashHit < 0.25 then return end
    lastDashHit = now
    task.spawn(function()
        local p = nearestPlayer(S.DashRange); local root = getRoot()
        if not (p and p.Character and root) then return end
        local tr = charPart(p.Character)
        if not tr then return end
        local behind = tr.Position - (tr.CFrame.LookVector * 3)
        pcall(function() root.CFrame = CFrame.new(behind, tr.Position) end)  -- behind, facing them = M1 lands
        fireDash("Forward")
        tapKey(Enum.KeyCode.Q)
    end)
end)

-- AUTO DASH: spam-dashes on a loop. Fires the dash remote AND taps the dash key
-- you pick below (default Q). NO LeftShift, so it never touches your camera.
local DASH_KEYS = {
    Q=Enum.KeyCode.Q, E=Enum.KeyCode.E, F=Enum.KeyCode.F, R=Enum.KeyCode.R,
    X=Enum.KeyCode.X, C=Enum.KeyCode.C, V=Enum.KeyCode.V, ["Left Shift"]=Enum.KeyCode.LeftShift,
}
task.spawn(function()
    while true do
        if S.AutoDash then
            pcall(function()
                fireDash("Forward")
                local kc = DASH_KEYS[S.AutoDashKey or "Q"]
                if kc then tapKey(kc) end
            end)
            task.wait(math.max(0.1, S.AutoDashDelay or 0.6))
        else
            task.wait(0.1)
        end
    end
end)

-- ── ABILITY AIM ASSIST ─────────────────────────────────────────
-- On a skill keypress, snap to face the nearest enemy (with simple velocity
-- lead) so directional abilities land. Facing-based, same as Auto Ability.
local AIM_KEYS = {
    [Enum.KeyCode.E]=true, [Enum.KeyCode.Q]=true, [Enum.KeyCode.R]=true,
    [Enum.KeyCode.T]=true, [Enum.KeyCode.F]=true,
}
hook(UserInputService.InputBegan, function(i, gpe)
    if gpe or not S.AimAssist then return end
    if not AIM_KEYS[i.KeyCode] or typingNow() then return end
    local tgt = nearestPlayer(S.AimAssistRange)
    local tr  = tgt and tgt.Character and charPart(tgt.Character)
    if not tr then return end
    local lead = tr.Position + tr.AssemblyLinearVelocity * (S.AimAssistLead or 0.12)
    faceTo(lead)
end)

-- Auto-attack one target: stand ~3 studs off FACING them (so directional M1s
-- land), kill momentum so you don't fling, then M1 + abilities. (tpTo() is
-- defined later in the file, so the velocity-zero is inlined here.)
local lastFarmM1, lastFarmAbil = 0, 0
local function attackTarget(target)
    local char = target and target.Character
    local tr   = char and charPart(char)
    local root = getRoot()
    if not (tr and root) then return end
    -- aim at a real body part, not the (possibly expanded) Hitbox cube
    local dest = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or tr
    local d = (dest.Position - root.Position).Magnitude
    if d > 8 then
        -- out of range: snap beside them ONCE, facing them, momentum killed
        local aim = CFrame.new(dest.Position - dest.CFrame.LookVector*3 + Vector3.new(0,1.5,0), dest.Position)
        pcall(function()
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = aim
        end)
    else
        -- already in range: only ROTATE to face them (no position write), so the
        -- server stops fighting/rolling you back every cycle
        pcall(function()
            root.CFrame = CFrame.new(root.Position, Vector3.new(dest.Position.X, root.Position.Y, dest.Position.Z))
        end)
    end
    local now = tick()
    -- M1 at a real SWING cadence. Spamming clickM1 every 0.1s cancelled the swing
    -- before its hit-frame, so damage rarely registered. ~0.35s lets each land.
    if now - lastFarmM1 >= 0.35 then
        lastFarmM1 = now
        clickM1(true); fireM1()
    end
    -- abilities on a slower cadence so they don't keep interrupting the M1 swing
    if now - lastFarmAbil >= 1.0 then
        lastFarmAbil = now
        tapKey(Enum.KeyCode.E)
        tapKey(Enum.KeyCode.R)
        if S.CastQ then tapKey(Enum.KeyCode.Q) end
        if S.CastT then tapKey(Enum.KeyCode.T) end
    end
end

task.spawn(function()
    while task.wait(0.1) do
        if S.AutoFarm and S.FarmTarget then
            pcall(function()
                local t = Players:FindFirstChild(S.FarmTarget)
                if t and t.Character and isAlive(t.Character) then attackTarget(t) end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if S.AutoPlay then
            pcall(function()
                local target = nearestPlayer(S.AutoPlayRange)
                if target then attackTarget(target) end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if S.SpinBot then
            pcall(function()
                local root = getRoot()
                if root then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(tick()*900 % 360), 0)
                    root.AssemblyLinearVelocity = Vector3.new(0, 60, 0)
                end
            end)
            task.wait(0.03)
        end
    end
end)

-- ============================================================
-- TELEPORT HELPERS
-- ============================================================
-- Safe teleport: always zero velocity first so you never fling/snap-back/die.
local function tpTo(cf)
    local root = getRoot(); if not (root and cf) then return false end
    pcall(function()
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = cf
    end)
    return true
end
local function tpToPlayer(name, behind)
    local p = name and Players:FindFirstChild(name)
    local char = p and p.Character
    local tr = char and charPart(char)
    if not (tr and getRoot()) then
        Rayfield:Notify({Title="Valutix Hub", Content="Target not found.", Duration=3})
        return
    end
    local off = (behind and -1 or 1) * tr.CFrame.LookVector * 4 + Vector3.new(0,1,0)
    -- look at the target so a follow-up M1 lands
    tpTo(CFrame.new(tr.Position + off, tr.Position))
end

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

-- ============================================================
-- GUI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Valutix Hub | Ability Arena",
    LoadingTitle = "Valutix Hub",
    LoadingSubtitle = "v2.13.3 - by Valutix Hub Owner",
    ConfigurationSaving = { Enabled = true, FolderName = "MoneyFreeHub", FileName = "AbilityArena" },
    Discord = { Enabled = false },
    KeySystem = false,
    -- Neon-red dark theme (near-black bg, glowing red toggles/sliders/selected tab)
    Theme = {
        TextColor                    = Color3.fromRGB(235, 235, 235),
        Background                   = Color3.fromRGB(15, 12, 13),
        Topbar                       = Color3.fromRGB(22, 16, 18),
        Shadow                       = Color3.fromRGB(8, 6, 7),

        NotificationBackground       = Color3.fromRGB(20, 14, 16),
        NotificationActionsBackground= Color3.fromRGB(255, 45, 45),

        TabBackground                = Color3.fromRGB(28, 20, 22),
        TabStroke                    = Color3.fromRGB(70, 22, 26),
        TabBackgroundSelected        = Color3.fromRGB(255, 40, 40),  -- selected tab = neon red
        TabTextColor                 = Color3.fromRGB(200, 190, 192),
        SelectedTabTextColor         = Color3.fromRGB(20, 12, 13),   -- dark text on red for contrast

        ElementBackground            = Color3.fromRGB(26, 19, 21),
        ElementBackgroundHover       = Color3.fromRGB(38, 24, 27),
        SecondaryElementBackground   = Color3.fromRGB(22, 16, 18),
        ElementStroke                = Color3.fromRGB(58, 26, 30),
        SecondaryElementStroke       = Color3.fromRGB(50, 24, 28),

        SliderBackground             = Color3.fromRGB(120, 18, 22),  -- dark red track
        SliderProgress               = Color3.fromRGB(255, 45, 45),  -- neon red fill
        SliderStroke                 = Color3.fromRGB(255, 85, 85),

        ToggleBackground             = Color3.fromRGB(30, 22, 24),
        ToggleEnabled                = Color3.fromRGB(255, 45, 45),  -- neon red ON
        ToggleDisabled               = Color3.fromRGB(85, 80, 82),   -- grey OFF
        ToggleEnabledStroke          = Color3.fromRGB(255, 95, 95),
        ToggleDisabledStroke         = Color3.fromRGB(115, 110, 112),
        ToggleEnabledOuterStroke     = Color3.fromRGB(180, 30, 34),
        ToggleDisabledOuterStroke    = Color3.fromRGB(55, 50, 52),

        DropdownSelected             = Color3.fromRGB(40, 24, 27),
        DropdownUnselected           = Color3.fromRGB(26, 19, 21),

        InputBackground              = Color3.fromRGB(28, 21, 23),
        InputStroke                  = Color3.fromRGB(75, 34, 38),
        PlaceholderColor             = Color3.fromRGB(150, 138, 140),
    },
})

local HomeTab      = Window:CreateTab("Home",      "home")
local CombatTab    = Window:CreateTab("Combat",    "swords")
local AbilitiesTab = Window:CreateTab("Abilities", "sparkles")
local TeleportsTab = Window:CreateTab("Teleports", "navigation")
local MovementTab  = Window:CreateTab("Movement",  "footprints")
local VisualsTab   = Window:CreateTab("Visuals",   "eye")
local FarmTab      = Window:CreateTab("Farm",      "target")
local UtilityTab   = Window:CreateTab("Utility",   "wrench")

-- \u2500\u2500 HOME (landing page) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
HomeTab:CreateSection("Welcome")
HomeTab:CreateParagraph({Title="Valutix Hub", Content="Ability Arena  -  v2.13.3\nPick a tab on the left to get started."})
HomeTab:CreateParagraph({Title="Status", Content = JoltReliable and "Ready." or "Not ready - rejoin and retry."})
HomeTab:CreateParagraph({Title="Best combo", Content="Dash Behind On Hit (lands your M1 + puts you behind them) + M1 Hitbox. Anti-Ragdoll + Anti Void + Remove Water Border + Anti Kill Bricks for survival. Auras on the Visuals tab. Click TP is on V (T is an ability key)."})
HomeTab:CreateSection("Credits")
HomeTab:CreateParagraph({Title="Credits", Content="Valutix Hub v2.13.3 - by Valutix Hub Owner"})

CombatTab:CreateSection("Survival")
CombatTab:CreateToggle({Name="Anti-Ragdoll (hard)", CurrentValue=false, Flag="AntiRagdoll", Callback=function(v)
    S.AntiRagdoll=v
    local h=getHum()
    if h then setRagdollStates(h, not v) end
end})
CombatTab:CreateToggle({Name="Anti-Push (knockback)", CurrentValue=false, Flag="AntiPush", Callback=function(v) S.AntiPush=v end})
CombatTab:CreateToggle({Name="Anti Void / Water (instant TP back)", CurrentValue=false, Flag="AntiVoid", Callback=function(v) S.AntiVoid=v end})
CombatTab:CreateToggle({Name="Remove Water Border (makes Anti Water hold)", CurrentValue=false, Flag="RemoveWaterBorder", Callback=function(v)
    S.RemoveWaterBorder=v
    if v then
        local n=destroyWaterBorder()
        Rayfield:Notify({Title="Valutix Hub", Content="Water border removed ("..n.." parts). Keeps clearing while on.", Duration=4})
    end
end})
CombatTab:CreateToggle({Name="Anti Kill Bricks (remove them)", CurrentValue=false, Flag="AntiKillBricks", Callback=function(v)
    S.AntiKillBricks=v
    if v then
        local n=destroyKillBricks()
        Rayfield:Notify({Title="Valutix Hub", Content="Kill bricks removed ("..n.." parts). Keeps clearing while on.", Duration=4})
    end
end})
CombatTab:CreateToggle({Name="Save Health (low HP -> fly to sky, heal, drop back)", CurrentValue=false, Flag="SaveHealth", Callback=function(v) S.SaveHealth=v end})
CombatTab:CreateSlider({Name="Save Health: trigger at HP %", Range={5,90}, Increment=5, Suffix="%", CurrentValue=35, Flag="SaveHealthPct", Callback=function(v) S.SaveHealthPct=v end})
CombatTab:CreateSlider({Name="Save Health: sky height", Range={100,2000}, Increment=50, Suffix="studs", CurrentValue=700, Flag="SaveHealthHeight", Callback=function(v) S.SaveHealthHeight=v end})

CombatTab:CreateSection("Hitboxes")
CombatTab:CreateToggle({Name="M1 Hitbox Expander (your M1 reaches farther)", CurrentValue=false, Flag="M1Hitbox", Callback=function(v)
    S.M1Hitbox=v
    if not v then restoreHitboxes() end
end})
CombatTab:CreateSlider({Name="M1 Hitbox Size", Range={1,300}, Increment=1, Suffix="studs", CurrentValue=50, Flag="M1HitboxSize", Callback=function(v) S.M1HitboxSize=v end})
CombatTab:CreateToggle({Name="Ability Hitbox Expander (pulses bigger on E)", CurrentValue=false, Flag="HitboxAbility", Callback=function(v)
    S.HitboxAbility=v
    if not v then destroyAbilityHb(); restoreHitboxes() end
end})
CombatTab:CreateSlider({Name="Ability Hitbox Size", Range={1,300}, Increment=1, Suffix="studs", CurrentValue=40, Flag="HitboxAbilitySize", Callback=function(v) S.HitboxAbilitySize=v end})
CombatTab:CreateToggle({Name="Expand Whole Body (max reach, looks huge)", CurrentValue=false, Flag="HitboxAllParts", Callback=function(v) S.HitboxAllParts=v; if not v then restoreHitboxes() end end})

CombatTab:CreateSection("Auto")
CombatTab:CreateToggle({Name="Auto M1 (click spam)", CurrentValue=false, Flag="AutoM1", Callback=function(v) S.AutoM1=v end})
CombatTab:CreateToggle({Name="Auto Ability", CurrentValue=false, Flag="AutoAbility", Callback=function(v) S.AutoAbility=v end})
CombatTab:CreateSlider({Name="Auto Ability Range", Range={5,80}, Increment=1, Suffix="studs", CurrentValue=25, Flag="AutoAbilityRange", Callback=function(v) S.AutoAbilityRange=v end})
CombatTab:CreateToggle({Name="Cast E", CurrentValue=true,  Flag="CastE", Callback=function(v) S.CastE=v end})
CombatTab:CreateToggle({Name="Cast Q", CurrentValue=false, Flag="CastQ", Callback=function(v) S.CastQ=v end})
CombatTab:CreateToggle({Name="Cast R", CurrentValue=false, Flag="CastR", Callback=function(v) S.CastR=v end})
CombatTab:CreateToggle({Name="Cast T", CurrentValue=false, Flag="CastT", Callback=function(v) S.CastT=v end})
CombatTab:CreateToggle({Name="Dash Behind On Hit (M1 -> snap behind + dash)", CurrentValue=false, Flag="DashBehind", Callback=function(v) S.DashBehind=v end})
CombatTab:CreateSlider({Name="Dash Behind Range", Range={10,80}, Increment=1, Suffix="studs", CurrentValue=45, Flag="DashRange", Callback=function(v) S.DashRange=v end})
CombatTab:CreateToggle({Name="Auto Dash (spam dash, no shift-lock)", CurrentValue=false, Flag="AutoDash", Callback=function(v) S.AutoDash=v end})
CombatTab:CreateDropdown({Name="Dash Key (whatever key dashes in-game)", Options={"Q","E","F","R","X","C","V","Left Shift"}, CurrentOption={"Q"}, Flag="AutoDashKey", Callback=function(o) S.AutoDashKey=(type(o)=="table" and o[1]) or o end})
CombatTab:CreateSlider({Name="Auto Dash Speed (lower = faster)", Range={1,20}, Increment=1, Suffix="x0.1s", CurrentValue=6, Flag="AutoDashTenths", Callback=function(v) S.AutoDashDelay=v/10 end})

CombatTab:CreateSection("Aim")
CombatTab:CreateToggle({Name="Camera Lock (nearest)", CurrentValue=false, Flag="CamLock", Callback=function(v) S.CamLock=v end})
CombatTab:CreateSlider({Name="Cam Lock Range", Range={20,300}, Increment=5, Suffix="studs", CurrentValue=120, Flag="CamLockRange", Callback=function(v) S.CamLockRange=v end})
CombatTab:CreateToggle({Name="Ability Aim Assist (face enemy on skill cast)", CurrentValue=false, Flag="AimAssist", Callback=function(v) S.AimAssist=v end})
CombatTab:CreateSlider({Name="Aim Assist Range", Range={20,400}, Increment=10, Suffix="studs", CurrentValue=140, Flag="AimAssistRange", Callback=function(v) S.AimAssistRange=v end})
CombatTab:CreateSlider({Name="Aim Assist Lead (prediction)", Range={0,50}, Increment=1, Suffix="x0.01s", CurrentValue=12, Flag="AimAssistLead100", Callback=function(v) S.AimAssistLead=v/100 end})

AbilitiesTab:CreateSection("Ability Grabber")
AbilitiesTab:CreateParagraph({Title="Ability Grabber", Content="Pick any ability from the list to equip it instantly. Raise Grab Delay if an ability needs a moment longer to register."})
AbilitiesTab:CreateSlider({Name="Grab Delay (sec)", Range={1,8}, Increment=1, Suffix="sec", CurrentValue=3, Flag="GrabDelay", Callback=function(v) S.GrabDelay=v end})
AbilitiesTab:CreateToggle({Name="Return to map spawn after grab", CurrentValue=true, Flag="GrabReturn", Callback=function(v) S.GrabReturn=v end})
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

TeleportsTab:CreateSection("Players")
local tpDrop = TeleportsTab:CreateDropdown({Name="Teleport Target", Options=playerNames(), CurrentOption={}, Flag="TPTarget", Callback=function(o)
    S.TPTarget = (type(o)=="table" and o[1]) or o
end})
TeleportsTab:CreateButton({Name="TP To Target (in front)", Callback=function() tpToPlayer(S.TPTarget, false) end})
TeleportsTab:CreateButton({Name="TP Behind Target", Callback=function() tpToPlayer(S.TPTarget, true) end})
TeleportsTab:CreateButton({Name="TP Behind Nearest Player", Callback=function()
    local p = nearestPlayer()
    if p then tpToPlayer(p.Name, true)
    else Rayfield:Notify({Title="Valutix Hub", Content="No players nearby.", Duration=3}) end
end})
TeleportsTab:CreateButton({Name="Refresh Player List", Callback=function()
    pcall(function() tpDrop:Refresh(playerNames()) end)
end})

TeleportsTab:CreateSection("Places")
TeleportsTab:CreateButton({Name="TP To Ability Pads (lobby)", Callback=function()
    local f = findElementFolder()
    local root = getRoot()
    if f and root then
        local pos = f:GetChildren()[1]
        if pos and (pos:IsA("BasePart") or pos:IsA("Model")) then
            local pp = pos:IsA("BasePart") and pos.Position or pos:GetPivot().Position
            tpTo(CFrame.new(pp + Vector3.new(0, 5, 0)))
        end
    else
        Rayfield:Notify({Title="Valutix Hub", Content="Ability pads not found - are you in the lobby?", Duration=3})
    end
end})
TeleportsTab:CreateToggle({Name="Click Teleport  [V]", CurrentValue=false, Flag="ClickTP", Callback=function(v) S.ClickTP=v end})

TeleportsTab:CreateSection("Safe Spawn")
TeleportsTab:CreateButton({Name="Set Safe Spawn (save position)", Callback=function()
    local root = getRoot()
    if root then
        savedSpawnCF = root.CFrame
        Rayfield:Notify({Title="Valutix Hub", Content="Safe spawn saved!", Duration=4})
    end
end})
TeleportsTab:CreateButton({Name="TP to Safe Spawn", Callback=function()
    local tpCF = savedSpawnCF or lastSafeCF
    if tpCF then
        healPanic = false                     -- cancel any Save Health sky-anchor first
        local r = getRoot(); if r then pcall(function() r.Anchored = false end) end
        tpTo(tpCF + Vector3.new(0, 3, 0))
    else
        Rayfield:Notify({Title="Valutix Hub", Content="No safe spawn set yet.", Duration=4})
    end
end})
TeleportsTab:CreateButton({Name="Clear Safe Spawn", Callback=function()
    savedSpawnCF = nil
    Rayfield:Notify({Title="Valutix Hub", Content="Safe spawn cleared.", Duration=3})
end})

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

VisualsTab:CreateToggle({Name="Player ESP", CurrentValue=false, Flag="ESP", Callback=function(v) S.ESP=v end})
VisualsTab:CreateToggle({Name="Color By HP", CurrentValue=true, Flag="ESPColor", Callback=function(v) S.ESPColor=v end})
VisualsTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="Tracers", Callback=function(v) S.Tracers=v end})
VisualsTab:CreateToggle({Name="ESP Boxes (2D)", CurrentValue=false, Flag="ESPBox", Callback=function(v) S.ESPBox=v end})
VisualsTab:CreateToggle({Name="Show Ability on ESP", CurrentValue=true, Flag="ESPAbility", Callback=function(v) S.ESPAbility=v end})
VisualsTab:CreateSlider({Name="ESP Max Distance (0 = unlimited)", Range={0,2000}, Increment=10, Suffix="studs", CurrentValue=0, Flag="ESPMaxDist", Callback=function(v) S.ESPMaxDist=v end})
VisualsTab:CreateToggle({Name="Enemy Highlight", CurrentValue=false, Flag="EnemyHighlight", Callback=function(v) S.EnemyHighlight=v end})
VisualsTab:CreateDropdown({Name="Highlight Color", Options={"Bright blue","Bright red","Lime green","New Yeller","White","Magenta"}, CurrentOption={"Bright blue"}, Flag="HighlightColor", Callback=function(o)
    S.HighlightColor = (type(o)=="table" and o[1]) or o
    clearHighlights()
end})
VisualsTab:CreateToggle({Name="Full Bright", CurrentValue=false, Flag="FullBright", Callback=function(v) S.FullBright=v; setFullBright(v) end})

VisualsTab:CreateSection("View Player")
local viewDrop = VisualsTab:CreateDropdown({Name="Spectate Target", Options=playerNames(), CurrentOption={}, Flag="ViewTarget", Callback=function(o)
    S.ViewTarget = (type(o)=="table" and o[1]) or o
end})
VisualsTab:CreateButton({Name="View Player", Callback=function() viewPlayer(S.ViewTarget) end})
VisualsTab:CreateButton({Name="Stop Viewing", Callback=stopView})

VisualsTab:CreateSection("Auras")
VisualsTab:CreateParagraph({Title="Add Aura", Content="Pick any aura and click Add Aura to wear its effect. Use Remove Aura to take it off."})
local selAura = nil
local auraDrop = VisualsTab:CreateDropdown({Name="Aura", Options=auraNames(), CurrentOption={}, Flag="AuraPick", Callback=function(o)
    selAura = (type(o)=="table" and o[1]) or o
end})
VisualsTab:CreateButton({Name="Add Aura", Callback=function() addAura(selAura) end})
VisualsTab:CreateButton({Name="Remove Aura", Callback=clearAura})
VisualsTab:CreateButton({Name="Refresh Aura List", Callback=function() pcall(function() auraDrop:Refresh(auraNames()) end) end})

FarmTab:CreateSection("Auto Play")
FarmTab:CreateToggle({Name="Auto Play (fight nearest enemy automatically)", CurrentValue=false, Flag="AutoPlay", Callback=function(v) S.AutoPlay=v end})
FarmTab:CreateSlider({Name="Auto Play Search Range", Range={10,300}, Increment=5, Suffix="studs", CurrentValue=100, Flag="AutoPlayRange", Callback=function(v) S.AutoPlayRange=v end})

FarmTab:CreateSection("Auto Farm")
FarmTab:CreateToggle({Name="Auto Farm Target", CurrentValue=false, Flag="AutoFarm", Callback=function(v)
    if v and not S.FarmTarget then
        Rayfield:Notify({Title="Valutix Hub", Content="Pick a target first.", Duration=3})
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

-- Keep the Teleport + Farm target lists current as players join/leave.
local function refreshPlayerDrops()
    pcall(function() tpDrop:Refresh(playerNames()) end)
    pcall(function() farmDrop:Refresh(playerNames()) end)
    pcall(function() viewDrop:Refresh(playerNames()) end)
end
hook(Players.PlayerAdded,    function() task.delay(0.3, refreshPlayerDrops) end)
hook(Players.PlayerRemoving, function() task.delay(0.3, refreshPlayerDrops) end)

UtilityTab:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AntiAFK", Callback=function(v) S.AntiAFK=v end})
UtilityTab:CreateToggle({Name="Instant Respawn", CurrentValue=false, Flag="InstantRespawn", Callback=function(v) S.InstantRespawn=v end})
UtilityTab:CreateButton({Name="Rejoin Server", Callback=rejoin})
UtilityTab:CreateButton({Name="Server Hop", Callback=serverHop})

UtilityTab:CreateSection("Admin")
UtilityTab:CreateButton({Name="Unload Valutix Hub", Callback=function()
    for _,c in pairs(Conns) do pcall(function() c:Disconnect() end) end
    for _,c in ipairs(Listeners) do pcall(function() c:Disconnect() end) end
    pcall(function() setFullBright(false) end)   -- restore lighting if Full Bright was on
    pcall(function() stopView() end)             -- restore camera if spectating
    clearESP(); clearHighlights(); restoreHitboxes(); destroyAbilityHb(); clearAura()
    if floatPart then pcall(function() floatPart:Destroy() end) end
    local h=getHum(); if h then setRagdollStates(h, true) end
    for k in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
    pcall(function() Rayfield:Destroy() end)
end})


Rayfield:Notify({Title="Valutix Hub v2.13.3", Content="Loaded - by Valutix Hub Owner", Duration=6})
