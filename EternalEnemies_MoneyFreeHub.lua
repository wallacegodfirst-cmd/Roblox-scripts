-- ╔══════════════════════════════════════════════════════════════════╗
-- ║       Eternal Enemies — MoneyFreeHub  v11.1                     ║
-- ║  Fixes: teleport rubber-band · hitbox cache · CamLock restore   ║
-- ║         Fullbright post-FX · SaveDeath thresholds · DodgeCooldown║
-- ║         safeWriteFile · Kill Aura SG parent · MFH_DEBUG off     ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ── services ────────────────────────────────────────────────────────
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local VIM           = game:GetService("VirtualInputManager")
local Lighting      = game:GetService("Lighting")
local TweenService  = game:GetService("TweenService")
local LP            = Players.LocalPlayer
local SG            = LP:WaitForChild("PlayerGui")

-- ── executor capability flags ────────────────────────────────────────
local HAS_WRITEFILE = pcall(function() writefile("_mfh_test.tmp","1") end)
local HAS_READFILE  = type(readfile)  == "function"
local HAS_ISFILE    = type(isfile)    == "function"
local HAS_GETHUI    = type(gethui)    == "function"
local HAS_SYN       = type(syn)       == "table"
local MFH_DEBUG     = false   -- FIX: was true in v11.0

-- ── safe file I/O ────────────────────────────────────────────────────
local function safeWriteFile(name, data)
    if HAS_WRITEFILE then pcall(writefile, name, data) end
end

local function safeReadFile(name)
    if HAS_READFILE and HAS_ISFILE then
        local ok, exists = pcall(isfile, name)
        if ok and exists then
            local ok2, data = pcall(readfile, name)
            if ok2 then return data end
        end
    end
    return nil
end

-- ── config ──────────────────────────────────────────────────────────
local CFG = {
    -- combat
    KillAura        = false,
    AuraRange       = 20,
    AuraRate        = 0.08,
    AutoM1          = false,
    M1Rate          = 0.12,
    AutoLatch       = false,
    LatchTarget     = "Nearest",
    LatchHold       = true,
    LatchHoldTime   = 0.5,
    AutoFarm        = false,
    FarmTarget      = "Nearest",
    FarmRange       = 5,
    FarmHitsPerCycle= 3,
    FarmHitInterval = 0.08,
    FarmLoopRate    = 0.15,
    FarmRespawnWait = 1.5,

    -- movement
    SpeedHack       = false,
    SpeedValue      = 50,
    Fly             = false,
    FlySpeed        = 60,
    Noclip          = false,
    AutoSprint      = false,
    AutoStalk       = false,
    StalkTarget     = "Nearest",
    StalkDistance   = 12,

    -- survival
    InfStamina      = false,
    SaveDeath       = false,
    LowHP           = 25,   -- FIX: Save Death uses these, not hardcoded 25/70
    HealHP          = 70,
    AutoDodge       = false,
    DodgeKey        = Enum.KeyCode.Q,
    DodgeCooldownTime = 1.2,   -- FIX: was missing, causing spam
    DodgeTriggerRange = 8,
    SmartHeal       = false,
    HealThreshold   = 50,
    HealCooldown    = 3,
    HealKey         = Enum.KeyCode.H,

    -- visuals
    ESP             = false,
    ESPTracer       = true,
    ESPColor        = Color3.fromRGB(255, 50, 50),
    PlayerTracker   = false,
    Radar           = false,
    StatHUD         = false,
    TargetInfo      = false,
    Fullbright      = false,
    Invisible       = false,

    -- camera
    CamLock         = false,
    LockTarget      = "Nearest",

    -- hitbox
    HitboxEnabled   = false,
    HitboxSize      = 8,
    HitboxNPC       = true,

    -- utility
    AutoCollect     = false,
    CollectFilter   = "loot",
    CollectRange    = 30,
    AutoRejoin      = false,
    RejoinOnDeath   = false,
    RejoinDelay     = 3,
    AntiAFK         = true,
    InstantInteract = false,

    -- misc
    FarmLoopRate    = 0.15,
}

-- ── globals ──────────────────────────────────────────────────────────
local RUNNING   = true
local Conns     = {}
local myChar    = LP.Character or LP.CharacterAdded:Wait()
local myName    = LP.Name
local myR       = myChar:WaitForChild("HumanoidRootPart", 5)

-- remote refs (filled lazily)
local CombatEvent   = nil
local StaminaEvent  = nil
local HealEvent     = nil

-- ── helper: find remotes lazily ─────────────────────────────────────
task.spawn(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("combat") or n:find("attack") then CombatEvent  = CombatEvent  or v end
            if n:find("stamina")or n:find("energy")  then StaminaEvent = StaminaEvent or v end
            if n:find("heal")                         then HealEvent    = HealEvent    or v end
        end
    end
end)

-- ── helper functions ─────────────────────────────────────────────────
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function getHumanoid2(model)
    return model and (model:FindFirstChildOfClass("Humanoid")
        or model:FindFirstChildWhichIsA("Humanoid"))
end

local function getRootPart(model)
    return model and (model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Root")
        or model:FindFirstChildOfClass("BasePart"))
end

local function getLatchAttachment(npc)
    for _, v in ipairs(npc:GetDescendants()) do
        if v:IsA("Attachment") and v.Name:lower():find("latch") then
            return v
        end
    end
end

-- ── NPC cache (2s TTL — avoids GetDescendants every 0.1s) ───────────
local npcCache     = {}
local npcCacheTime = 0
local NPC_TTL      = 2

local function getAllNPCsRaw()
    local folder = workspace:FindFirstChild("Characters")
        or workspace:FindFirstChild("Enemies")
        or workspace:FindFirstChild("NPCs")
    local results = {}
    local source  = folder and folder:GetChildren() or workspace:GetChildren()
    for _, v in ipairs(source) do
        if v:IsA("Model") and v ~= LP.Character and v:FindFirstChildOfClass("Humanoid") then
            results[#results+1] = v
        end
    end
    return results
end

local function getCachedNPCs()
    local now = tick()
    if (now - npcCacheTime) >= NPC_TTL then
        npcCache     = getAllNPCsRaw()
        npcCacheTime = now
    end
    return npcCache
end

-- target resolver
local function resolveNPCTarget(mode)
    local hrp = getHRP()
    if not hrp then return nil end
    if mode == "Nearest" then
        local best, bd = nil, math.huge
        for _, npc in ipairs(getCachedNPCs()) do
            local r = getRootPart(npc)
            local h = getHumanoid(npc)
            if r and h and h.Health > 0 then
                local d = (hrp.Position - r.Position).Magnitude
                if d < bd then bd = d; best = npc end
            end
        end
        return best
    end
    -- named target
    for _, npc in ipairs(getCachedNPCs()) do
        if npc.Name == mode then return npc end
    end
    return nil
end

-- fire combat remote (raw)
local function fireCombatRaw(hum2)
    if CombatEvent and hum2 then
        pcall(function() CombatEvent:FireServer("Attack", hum2) end)
    end
end

-- ── safeTeleport — repeats 5× across Heartbeat frames ───────────────
-- FIX: single CFrame write rubber-bands; server correction window is
--      ~1 frame; 5 consecutive writes across Heartbeat saturate it.
local function safeTeleport(targetPos, lookAtPos)
    local hrp = getHRP()
    if not hrp then return end
    local finalCF
    if lookAtPos then
        finalCF = CFrame.new(targetPos, lookAtPos)
    else
        finalCF = CFrame.new(targetPos) * (hrp.CFrame - hrp.CFrame.Position)
    end
    for i = 1, 5 do
        hrp.CFrame = finalCF
        pcall(function() hrp.AssemblyLinearVelocity  = Vector3.zero end)
        pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end)
        if i < 5 then RunService.Heartbeat:Wait() end
    end
end

local function teleportNear(root, dist)
    if not root then return end
    local offset = root.CFrame.LookVector * (-dist)
    safeTeleport(root.Position + offset + Vector3.new(0, 0.5, 0))
end

-- ══════════════════════════════════════════════════════════════════════
-- GUI
-- ══════════════════════════════════════════════════════════════════════
local MFH_GUI = Instance.new("ScreenGui")
MFH_GUI.Name           = "EE_MFH_v11"
MFH_GUI.ResetOnSpawn   = false
MFH_GUI.IgnoreGuiInset = true
MFH_GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MFH_GUI.Parent         = SG

-- main frame
local MainFrame = Instance.new("Frame", MFH_GUI)
MainFrame.Name              = "Main"
MainFrame.Size              = UDim2.new(0, 280, 0, 480)
MainFrame.Position          = UDim2.new(0, 20, 0.5, -240)
MainFrame.BackgroundColor3  = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel   = 0
MainFrame.Active            = true
MainFrame.Draggable         = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- title bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size              = UDim2.new(1, -40, 1, 0)
TitleLabel.Position          = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text              = "Eternal Enemies  MFH  v11.1"
TitleLabel.TextColor3        = Color3.fromRGB(80, 200, 255)
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextSize          = 14
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size              = UDim2.new(0, 30, 0, 24)
MinBtn.Position          = UDim2.new(1, -35, 0.5, -12)
MinBtn.BackgroundColor3  = Color3.fromRGB(60, 60, 80)
MinBtn.TextColor3        = Color3.new(1,1,1)
MinBtn.Text              = "—"
MinBtn.Font              = Enum.Font.GothamBold
MinBtn.TextSize          = 14
MinBtn.BorderSizePixel   = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- scroll container
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size                  = UDim2.new(1, 0, 1, -40)
Scroll.Position              = UDim2.new(0, 0, 0, 40)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel       = 0
Scroll.ScrollBarThickness    = 4
Scroll.ScrollBarImageColor3  = Color3.fromRGB(80, 200, 255)
Scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y

local Layout = Instance.new("UIListLayout", Scroll)
Layout.SortOrder     = Enum.SortOrder.LayoutOrder
Layout.Padding       = UDim.new(0, 4)

local Padding = Instance.new("UIPadding", Scroll)
Padding.PaddingLeft   = UDim.new(0, 8)
Padding.PaddingRight  = UDim.new(0, 8)
Padding.PaddingTop    = UDim.new(0, 6)
Padding.PaddingBottom = UDim.new(0, 6)

-- minimize toggle
local guiVisible = true
MinBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    Scroll.Visible = guiVisible
    MainFrame.Size = guiVisible
        and UDim2.new(0, 280, 0, 480)
        or  UDim2.new(0, 280, 0, 36)
end)

-- ── GUI helpers ──────────────────────────────────────────────────────
local function makeSection(title, order)
    local lbl = Instance.new("TextLabel", Scroll)
    lbl.LayoutOrder         = order
    lbl.Size                = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundColor3    = Color3.fromRGB(30, 30, 50)
    lbl.BorderSizePixel     = 0
    lbl.Text                = " ── " .. title
    lbl.TextColor3          = Color3.fromRGB(140, 180, 255)
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 12
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 5)
    return lbl
end

local function makeToggle(label, cfgKey, order, callback)
    local btn = Instance.new("TextButton", Scroll)
    btn.LayoutOrder         = order
    btn.Size                = UDim2.new(1, 0, 0, 28)
    btn.BorderSizePixel     = 0
    btn.Font                = Enum.Font.Gotham
    btn.TextSize            = 13
    btn.TextColor3          = Color3.new(1, 1, 1)
    btn:SetAttribute("CFGKey",   cfgKey)
    btn:SetAttribute("Label",    label)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function refresh()
        local on = CFG[cfgKey]
        btn.BackgroundColor3 = on
            and Color3.fromRGB(40, 180, 80)
            or  Color3.fromRGB(180, 40, 40)
        btn.Text = label .. (on and "  ON" or "  OFF")
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        refresh()
        if callback then callback(CFG[cfgKey]) end
        pcall(saveConfig)
    end)
    return btn
end

local function makeSlider(label, cfgKey, minV, maxV, order)
    local container = Instance.new("Frame", Scroll)
    container.LayoutOrder        = order
    container.Size               = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3   = Color3.fromRGB(20, 20, 32)
    container.BorderSizePixel    = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", container)
    lbl.Size              = UDim2.new(1, -50, 0, 20)
    lbl.Position          = UDim2.new(0, 8, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = Color3.fromRGB(200, 200, 220)
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 12
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", container)
    valLbl.Size           = UDim2.new(0, 44, 0, 20)
    valLbl.Position       = UDim2.new(1, -50, 0, 2)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3     = Color3.fromRGB(80, 200, 255)
    valLbl.Font           = Enum.Font.GothamBold
    valLbl.TextSize       = 12

    local track = Instance.new("Frame", container)
    track.Size            = UDim2.new(1, -16, 0, 8)
    track.Position        = UDim2.new(0, 8, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local v    = CFG[cfgKey]
        local pct  = (v - minV) / (maxV - minV)
        fill.Size  = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
        lbl.Text   = label
        valLbl.Text = tostring(v)
    end
    refresh()

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local absPos  = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        local rel     = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
        CFG[cfgKey]   = math.round(minV + rel * (maxV - minV))
        refresh()
    end)

    return container
end

-- ── build GUI tabs ───────────────────────────────────────────────────
local o = 0
local function ord() o += 1; return o end

makeSection("COMBAT", ord())
makeToggle("Kill Aura",    "KillAura",    ord())
makeSlider("Aura Range",   "AuraRange",   4, 60, ord())
makeToggle("Auto M1",      "AutoM1",      ord())
makeToggle("Auto Latch",   "AutoLatch",   ord())
makeToggle("Auto Farm",    "AutoFarm",    ord())

makeSection("MOVEMENT", ord())
makeToggle("Speed Hack",   "SpeedHack",   ord())
makeSlider("Speed Value",  "SpeedValue",  16, 200, ord())
makeToggle("Fly",          "Fly",         ord())
makeSlider("Fly Speed",    "FlySpeed",    10, 200, ord())
makeToggle("No-Clip",      "Noclip",      ord())
makeToggle("Auto Sprint",  "AutoSprint",  ord())
makeToggle("Auto Stalk",   "AutoStalk",   ord())

makeSection("SURVIVAL", ord())
makeToggle("Inf Stamina",  "InfStamina",  ord())
makeToggle("Save Death",   "SaveDeath",   ord())
makeSlider("Low HP %",     "LowHP",       5, 50, ord())
makeSlider("Heal HP %",    "HealHP",      50, 95, ord())
makeToggle("Auto Dodge",   "AutoDodge",   ord())
makeToggle("Smart Heal",   "SmartHeal",   ord())

makeSection("VISUALS", ord())
makeToggle("ESP",           "ESP",           ord())
makeToggle("ESP Tracers",   "ESPTracer",     ord())
makeToggle("Player Tracker","PlayerTracker", ord())
makeToggle("Radar",         "Radar",         ord())
makeToggle("Stat HUD",      "StatHUD",       ord())
makeToggle("Target Info",   "TargetInfo",    ord())
makeToggle("Fullbright",    "Fullbright",    ord())
makeToggle("Invisible",     "Invisible",     ord())

makeSection("CAMERA", ord())
makeToggle("Cam Lock",     "CamLock",     ord())

makeSection("HITBOX", ord())
makeToggle("Hitbox",       "HitboxEnabled", ord())
makeSlider("Hitbox Size",  "HitboxSize",  4, 40, ord())

makeSection("UTILITY", ord())
makeToggle("Auto Collect", "AutoCollect", ord())
makeToggle("Auto Rejoin",  "AutoRejoin",  ord())
makeToggle("Anti-AFK",     "AntiAFK",     ord())
makeToggle("Instant Interact","InstantInteract", ord())

-- ══════════════════════════════════════════════════════════════════════
-- HITBOX EXPANDER
-- ══════════════════════════════════════════════════════════════════════
local function isMine(m)
    if m.Name == myName then return true end
    local c = LP.Character
    if c and (m == c or m:IsDescendantOf(c) or c:IsDescendantOf(m)) then return true end
    if Players:GetPlayerFromCharacter(m) == LP then return true end
    local r = getHRP()
    if r and r:IsDescendantOf(m) then return true end
    return false
end

local expandedParts = {}

local function expandParts(npc)
    if isMine(npc) then return end
    local hum = getHumanoid(npc)
    if not hum or hum.Health <= 0 then return end
    for _, p in ipairs(npc:GetDescendants()) do
        if p:IsA("BasePart") and not p:FindFirstChild("MFHBox") then
            local box = Instance.new("Part")
            box.Name         = "MFHBox"
            box.Size         = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize)
            box.CFrame       = p.CFrame
            box.Anchored     = false
            box.CanCollide   = false
            box.CanQuery     = true
            box.CanTouch     = false
            box.Massless     = true
            box.Transparency = 1
            local weld       = Instance.new("WeldConstraint")
            weld.Part0       = p
            weld.Part1       = box
            weld.Parent      = box
            box.Parent       = p
            expandedParts[#expandedParts+1] = box
        end
    end
end

local function clearHitboxes()
    for _, b in ipairs(expandedParts) do pcall(function() b:Destroy() end) end
    expandedParts = {}
end

-- hitbox update loop
task.spawn(function()
    while RUNNING do
        if CFG.HitboxEnabled then
            -- FIX: getCachedNPCs not getAllNPCs (avoids GetDescendants hitch)
            for _, npc in ipairs(getCachedNPCs()) do expandParts(npc) end
        else
            if #expandedParts > 0 then clearHitboxes() end
        end
        -- safety: remove own boxes
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p.Name == "MFHBox" then p:Destroy() end
            end
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- KILL AURA
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.KillAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                for _, npc in ipairs(getCachedNPCs()) do
                    local root = getRootPart(npc)
                    local hum  = getHumanoid(npc)
                    local hum2 = getHumanoid2(npc)
                    if not root or not hum or hum.Health <= 0 or not hum2 then continue end
                    local d = (hrp.Position - root.Position).Magnitude
                    if d <= CFG.AuraRange then
                        fireCombatRaw(hum2)
                        -- HP label above npc
                        if CFG.StatHUD then
                            pcall(function()
                                local existing = root:FindFirstChild("MFH_HP")
                                if not existing then
                                    local bb = Instance.new("BillboardGui")
                                    bb.Name          = "MFH_HP"
                                    bb.Size          = UDim2.new(0,60,0,20)
                                    bb.StudsOffset   = Vector3.new(0,3,0)
                                    bb.AlwaysOnTop   = true
                                    -- FIX: parent to SG not CoreGui (executor compat)
                                    bb.Parent        = SG
                                    bb.Adornee       = root
                                    local tl = Instance.new("TextLabel", bb)
                                    tl.Size  = UDim2.new(1,0,1,0)
                                    tl.BackgroundTransparency = 1
                                    tl.TextColor3 = Color3.fromRGB(255,80,80)
                                    tl.Font  = Enum.Font.GothamBold
                                    tl.TextSize = 13
                                    tl.Name = "HPText"
                                end
                                local bb2 = root:FindFirstChild("MFH_HP")
                                    or SG:FindFirstChild("MFH_HP")
                                if bb2 then
                                    local tl = bb2:FindFirstChild("HPText")
                                    if tl then
                                        tl.Text = math.floor(hum.Health) .. " HP"
                                    end
                                end
                            end)
                        end
                    end
                end
            end)
        end
        task.wait(CFG.AuraRate)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO M1
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.AutoM1 then
            pcall(function()
                local npc  = resolveNPCTarget("Nearest")
                local hum2 = npc and getHumanoid2(npc)
                if hum2 then fireCombatRaw(hum2) end
            end)
        end
        task.wait(CFG.M1Rate)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO LATCH
-- ══════════════════════════════════════════════════════════════════════
local latchedNPC = nil
task.spawn(function()
    while RUNNING do
        if CFG.AutoLatch then
            pcall(function()
                local npc = latchedNPC
                if npc then
                    local valid = npc.Parent ~= nil
                    if valid then local h = getHumanoid2(npc); valid = h and h.Health > 0 end
                    if valid then valid = getRootPart(npc) ~= nil end
                    if valid then valid = getLatchAttachment(npc) ~= nil end
                    if not valid then
                        pcall(function() if CombatEvent then CombatEvent:FireServer("Unlatch") end end)
                        latchedNPC = nil; npc = nil
                    end
                end
                if not npc then npc = resolveNPCTarget(CFG.LatchTarget); latchedNPC = npc end
                if not npc or not CombatEvent then return end
                local hum2   = getHumanoid2(npc)
                local attach = getLatchAttachment(npc)
                local root   = getRootPart(npc)
                if hum2 and attach then
                    if root then teleportNear(root, 4); task.wait(0.05) end
                    CombatEvent:FireServer("Latch", hum2, attach)
                    if CFG.LatchHold then
                        local holdEnd = tick() + CFG.LatchHoldTime
                        while tick() < holdEnd and CFG.AutoLatch and RUNNING do
                            for _=1,2 do fireCombatRaw(hum2) end
                            task.wait(0.08)
                        end
                    end
                    if hum2.Health <= 0 then
                        CombatEvent:FireServer("Unlatch"); latchedNPC = nil
                    end
                else
                    latchedNPC = nil
                end
            end)
        else
            if latchedNPC then
                pcall(function() if CombatEvent then CombatEvent:FireServer("Unlatch") end end)
                latchedNPC = nil
            end
        end
        task.wait(0.15)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO FARM
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.AutoFarm then
            pcall(function()
                local npc  = resolveNPCTarget(CFG.FarmTarget)
                if not npc then task.wait(0.5); return end
                local hum  = getHumanoid(npc)
                local hum2 = getHumanoid2(npc)
                if not hum or hum.Health <= 0 then task.wait(0.5); return end
                local root = getRootPart(npc)
                if root then teleportNear(root, CFG.FarmRange); task.wait(0.05) end
                if hum2 then
                    for _=1, CFG.FarmHitsPerCycle do
                        fireCombatRaw(hum2)
                        task.wait(CFG.FarmHitInterval)
                    end
                end
                if hum.Health <= 0 then task.wait(CFG.FarmRespawnWait) end
            end)
        end
        task.wait(CFG.FarmLoopRate)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- SPEED HACK  (3-method: WalkSpeed + ALV boost)
-- ══════════════════════════════════════════════════════════════════════
local speedConn = nil

local function applySpeedHack()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    if not CFG.SpeedHack then return end
    speedConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local hrp = getHRP()
            local hum = getHumanoid(LP.Character)
            if not hrp or not hum then return end
            hum.WalkSpeed = CFG.SpeedValue
            local mv = hum.MoveDirection
            if mv.Magnitude > 0.1 then
                local boost = mv.Unit * (CFG.SpeedValue - 16) * 0.5
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        boost.X,
                        hrp.AssemblyLinearVelocity.Y,
                        boost.Z
                    )
                end)
            end
        end)
    end)
end

local function removeSpeedHack()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    pcall(function()
        local hum = getHumanoid(LP.Character)
        if hum then hum.WalkSpeed = 16 end
    end)
end

task.spawn(function()
    while RUNNING do
        if CFG.SpeedHack then
            if not speedConn then applySpeedHack() end
        else
            if speedConn then removeSpeedHack() end
        end
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- FLY
-- ══════════════════════════════════════════════════════════════════════
local flyConn = nil
local flyBV   = nil
local flyBG   = nil

local function cleanFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV   then flyBV:Destroy();      flyBV   = nil end
    if flyBG   then flyBG:Destroy();      flyBG   = nil end
    pcall(function()
        local hum = getHumanoid(LP.Character)
        if hum then hum.PlatformStand = false; hum.AutoRotate = true end
    end)
end

local function startFly()
    cleanFly()
    local hrp = getHRP()
    local hum = getHumanoid(LP.Character)
    if not hrp or not hum then return end
    hum.PlatformStand = false
    hum.AutoRotate    = false

    flyBV             = Instance.new("BodyVelocity")
    flyBV.Velocity    = Vector3.zero
    flyBV.MaxForce    = Vector3.new(1e5, 1e5, 1e5)
    flyBV.P           = 1e4
    flyBV.Parent      = hrp

    flyBG             = Instance.new("BodyGyro")
    flyBG.MaxTorque   = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P           = 1e4
    flyBG.D           = 100
    flyBG.CFrame      = hrp.CFrame
    flyBG.Parent      = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        if not CFG.Fly then cleanFly(); return end
        local cam = workspace.CurrentCamera
        if not cam or not hrp or not hrp.Parent then cleanFly(); return end
        local fwd = cam.CFrame.LookVector
        local rgt = cam.CFrame.RightVector
        local up  = Vector3.new(0, 1, 0)
        local spd = CFG.FlySpeed
        local vel = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel += fwd * spd end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel -= fwd * spd end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel -= rgt * spd end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel += rgt * spd end
        if UIS:IsKeyDown(Enum.KeyCode.Space)       then vel += up * spd end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.C)           then vel -= up * spd end
        flyBV.Velocity = vel
        if vel.Magnitude > 0.5 then flyBG.CFrame = CFrame.new(Vector3.zero, vel.Unit) end
    end)
end

task.spawn(function()
    while RUNNING do
        if CFG.Fly then
            if not flyConn then startFly() end
        else
            if flyConn then cleanFly() end
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- INFINITE STAMINA
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.InfStamina then
            pcall(function()
                local hum = getHumanoid(LP.Character)
                if not hum then return end
                for _, name in ipairs({"Stamina","StaminaValue","Energy","SP"}) do
                    local v = hum:FindFirstChild(name)
                        or (LP.Character and LP.Character:FindFirstChild(name))
                    if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                        v.Value = v.MaxValue or 100
                    end
                end
                if StaminaEvent then
                    pcall(function() StaminaEvent:FireServer("Restore") end)
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO SPRINT
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.AutoSprint then
            pcall(function()
                local hum = getHumanoid(LP.Character)
                if hum and hum.MoveDirection.Magnitude > 0.1 then
                    VIM:SendKeyEvent(true,  Enum.KeyCode.LeftShift, false, game)
                else
                    VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
                end
            end)
        end
        task.wait(0.05)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO STALK
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.AutoStalk then
            pcall(function()
                local npc  = resolveNPCTarget(CFG.StalkTarget)
                if not npc then return end
                local root = getRootPart(npc)
                local hrp  = getHRP()
                if not root or not hrp then return end
                local dist = (hrp.Position - root.Position).Magnitude
                local sd   = CFG.StalkDistance
                if dist > sd + 2 then
                    local back   = root.CFrame.LookVector * (-sd)
                    local target = root.Position + back
                    if dist < 80 then
                        local hum = getHumanoid(LP.Character)
                        if hum then hum:MoveTo(target) end
                    else
                        safeTeleport(target)
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- ESP  (diff-based — no clearESP flicker)
-- ══════════════════════════════════════════════════════════════════════
local espObjects  = {}
local espLastSeen = {}
local ESP_TTL     = 4

local function removeESPEntry(npc)
    local e = espObjects[npc]
    if not e then return end
    for _, d in pairs(e) do pcall(function() d:Remove() end) end
    espObjects[npc]  = nil
    espLastSeen[npc] = nil
end

local function getOrMakeESP(npc)
    if espObjects[npc] then return espObjects[npc] end
    local box   = Drawing.new("Square")
    box.Filled  = false; box.Thickness = 1.5; box.Transparency = 1

    local lbl   = Drawing.new("Text")
    lbl.Size    = 13; lbl.Font = Drawing.Fonts.UI
    lbl.Outline = true; lbl.Transparency = 1

    local hpBg  = Drawing.new("Square")
    hpBg.Filled = true; hpBg.Transparency = 0.5
    hpBg.Color  = Color3.new(0,0,0)

    local hpFg  = Drawing.new("Square")
    hpFg.Filled = true; hpFg.Transparency = 1

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1; tracer.Transparency = 1

    local e = { box=box, lbl=lbl, hpBg=hpBg, hpFg=hpFg, tracer=tracer }
    espObjects[npc] = e
    return e
end

table.insert(Conns, RunService.RenderStepped:Connect(function()
    if not CFG.ESP then
        for _, e in pairs(espObjects) do
            for _, d in pairs(e) do pcall(function() d.Visible = false end) end
        end
        return
    end

    local cam     = workspace.CurrentCamera
    local vp      = cam.ViewportSize
    local botMid  = Vector2.new(vp.X * 0.5, vp.Y)
    local now     = tick()
    local liveSet = {}
    local col     = CFG.ESPColor or Color3.fromRGB(255,50,50)

    for _, npc in ipairs(getCachedNPCs()) do
        local hum  = getHumanoid(npc)
        local root = getRootPart(npc)
        if not hum or not root then continue end
        liveSet[npc]      = true
        espLastSeen[npc]  = now

        local e             = getOrMakeESP(npc)
        local s, vis        = cam:WorldToViewportPoint(root.Position + Vector3.new(0,2.5,0))
        if not vis then
            for _, d in pairs(e) do pcall(function() d.Visible = false end) end
            continue
        end

        local scale  = 1 / s.Z * 1000
        local bw, bh = 40 * scale, 70 * scale
        local bx, by = s.X - bw * 0.5, s.Y - bh * 0.5

        e.box.Position = Vector2.new(bx, by)
        e.box.Size     = Vector2.new(bw, bh)
        e.box.Color    = col
        e.box.Visible  = true

        e.lbl.Text     = npc.Name
        e.lbl.Position = Vector2.new(bx, by - 15)
        e.lbl.Visible  = true

        local pct   = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bH    = math.max(3, 5 * scale)
        local bY    = by + bh + 2
        e.hpBg.Position = Vector2.new(bx, bY)
        e.hpBg.Size     = Vector2.new(bw, bH)
        e.hpBg.Visible  = true
        e.hpFg.Position = Vector2.new(bx, bY)
        e.hpFg.Size     = Vector2.new(bw * pct, bH)
        e.hpFg.Color    = Color3.fromHSV(pct * 0.33, 1, 1)
        e.hpFg.Visible  = true

        if CFG.ESPTracer then
            e.tracer.From    = botMid
            e.tracer.To      = Vector2.new(s.X, s.Y)
            e.tracer.Color   = col
            e.tracer.Visible = true
        else
            e.tracer.Visible = false
        end
    end

    for npc, lastT in pairs(espLastSeen) do
        if not liveSet[npc] or (now - lastT) > ESP_TTL then
            removeESPEntry(npc)
        end
    end
end))

-- ══════════════════════════════════════════════════════════════════════
-- CAMERA LOCK
-- ══════════════════════════════════════════════════════════════════════
local camLockConn = nil
local camOrigType = nil

local function stopCamLock()
    if camLockConn then camLockConn:Disconnect(); camLockConn = nil end
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam and camOrigType then cam.CameraType = camOrigType end
    end)
    camOrigType = nil
end

local function startCamLock()
    stopCamLock()
    local cam = workspace.CurrentCamera
    if not cam then return end
    camOrigType    = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable
    camLockConn    = RunService.RenderStepped:Connect(function()
        if not CFG.CamLock then stopCamLock(); return end
        local npc  = resolveNPCTarget(CFG.LockTarget)
        local root = npc and getRootPart(npc)
        local hrp  = getHRP()
        if not root or not hrp then return end
        cam.CFrame = CFrame.new(
            hrp.Position + Vector3.new(0,1.5,0),
            root.Position + Vector3.new(0,1.5,0)
        )
    end)
end

task.spawn(function()
    while RUNNING do
        if CFG.CamLock then
            if not camLockConn then startCamLock() end
        else
            if camLockConn then stopCamLock() end
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- FULLBRIGHT  (FIX: disables Atmosphere + all post-processing effects)
-- ══════════════════════════════════════════════════════════════════════
local savedLighting = {}

local function applyFullbright()
    savedLighting.Ambient        = Lighting.Ambient
    savedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    savedLighting.Brightness     = Lighting.Brightness
    savedLighting.FogEnd         = Lighting.FogEnd
    savedLighting.GlobalShadows  = Lighting.GlobalShadows
    savedLighting.ClockTime      = Lighting.ClockTime

    Lighting.Ambient        = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    Lighting.Brightness     = 10
    Lighting.FogEnd         = 1e6
    Lighting.GlobalShadows  = false
    Lighting.ClockTime      = 14

    savedLighting.effects = {}
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("Atmosphere")     or fx:IsA("Bloom")
        or fx:IsA("ColorCorrection") or fx:IsA("DepthOfField")
        or fx:IsA("SunRays") then
            savedLighting.effects[fx] = fx.Enabled
            fx.Enabled = false
        end
    end
end

local function removeFullbright()
    if savedLighting.Ambient == nil then return end
    Lighting.Ambient        = savedLighting.Ambient
    Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
    Lighting.Brightness     = savedLighting.Brightness
    Lighting.FogEnd         = savedLighting.FogEnd
    Lighting.GlobalShadows  = savedLighting.GlobalShadows
    Lighting.ClockTime      = savedLighting.ClockTime
    if savedLighting.effects then
        for fx, was in pairs(savedLighting.effects) do
            pcall(function() fx.Enabled = was end)
        end
    end
    savedLighting = {}
end

task.spawn(function()
    local wasOn = false
    while RUNNING do
        if CFG.Fullbright and not wasOn then
            applyFullbright(); wasOn = true
        elseif not CFG.Fullbright and wasOn then
            removeFullbright(); wasOn = false
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- NO-CLIP
-- ══════════════════════════════════════════════════════════════════════
local noclipConn = nil

task.spawn(function()
    while RUNNING do
        if CFG.Noclip then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    if not CFG.Noclip then
                        noclipConn:Disconnect(); noclipConn = nil; return
                    end
                    local c = LP.Character
                    if c then
                        for _, p in ipairs(c:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = false end
                        end
                    end
                end)
            end
        else
            if noclipConn then
                noclipConn:Disconnect(); noclipConn = nil
                local c = LP.Character
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = true end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- INSTANT INTERACT
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.InstantInteract then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then
                        local root = v.Parent
                        local rp   = root and getRootPart(root)
                        local d    = rp and (hrp.Position - rp.Position).Magnitude or math.huge
                        if d <= v.MaxActivationDistance + 10 then
                            pcall(function() fireproximityprompt(v) end)
                        end
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- SAVE DEATH  (FIX: CFG.LowHP / CFG.HealHP instead of hardcoded 25/70)
-- ══════════════════════════════════════════════════════════════════════
local savedDeathPos = nil

task.spawn(function()
    while RUNNING do
        if CFG.SaveDeath then
            pcall(function()
                local hrp = getHRP()
                local hum = getHumanoid(LP.Character)
                if not hrp or not hum then return end
                local hpPct = hum.MaxHealth > 0
                    and (hum.Health / hum.MaxHealth * 100) or 100

                if hpPct <= CFG.LowHP and hum.Health > 0 then
                    savedDeathPos = hrp.CFrame
                elseif hpPct >= CFG.HealHP and savedDeathPos then
                    safeTeleport(savedDeathPos.Position)
                    savedDeathPos = nil
                end
            end)
        else
            savedDeathPos = nil
        end
        task.wait(0.2)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO DODGE  (FIX: lastDodgeTime cooldown prevents spam)
-- ══════════════════════════════════════════════════════════════════════
local lastDodgeTime = 0

task.spawn(function()
    while RUNNING do
        if CFG.AutoDodge then
            pcall(function()
                local now = tick()
                if (now - lastDodgeTime) < CFG.DodgeCooldownTime then return end
                local hrp = getHRP()
                if not hrp then return end
                local closest = CFG.DodgeTriggerRange
                local found   = false
                for _, npc in ipairs(getCachedNPCs()) do
                    local root = getRootPart(npc)
                    local hum  = getHumanoid(npc)
                    if not root or not hum or hum.Health <= 0 then continue end
                    if (hrp.Position - root.Position).Magnitude < closest then
                        found = true; break
                    end
                end
                if found then
                    lastDodgeTime = now
                    VIM:SendKeyEvent(true,  CFG.DodgeKey, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, CFG.DodgeKey, false, game)
                end
            end)
        end
        task.wait(0.05)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- STAT HUD  (FPS via delta accumulation — no :Wait() blocking)
-- ══════════════════════════════════════════════════════════════════════
local hudLabels   = {}
local fpsFrames   = 0
local fpsElapsed  = 0
local fpsCurrent  = 0

do
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
            or Vector2.new(1920, 1080)
    local function makeHL(y)
        local l = Drawing.new("Text")
        l.Visible = false; l.Size = 14
        l.Font    = Drawing.Fonts.Monospace
        l.Outline = true; l.OutlineColor = Color3.new(0,0,0)
        l.Color   = Color3.new(1,1,1)
        l.Position = Vector2.new(10, vp.Y + y)
        return l
    end
    hudLabels.fps  = makeHL(-60)
    hudLabels.ping = makeHL(-45)
    hudLabels.pos  = makeHL(-30)
    hudLabels.hp   = makeHL(-15)
end

table.insert(Conns, RunService.RenderStepped:Connect(function(dt)
    fpsFrames  += 1
    fpsElapsed += dt
    if fpsElapsed >= 0.5 then
        fpsCurrent = math.round(fpsFrames / fpsElapsed)
        fpsFrames  = 0
        fpsElapsed = 0
    end

    if not CFG.StatHUD then
        for _, l in pairs(hudLabels) do l.Visible = false end
        return
    end
    for _, l in pairs(hudLabels) do l.Visible = true end

    hudLabels.fps.Text  = ("FPS: %d"):format(fpsCurrent)
    local ping = LP.GetNetworkPing and math.round(LP:GetNetworkPing() * 1000) or -1
    hudLabels.ping.Text = ("Ping: %dms"):format(ping)
    local hrp = getHRP()
    if hrp then
        local p = hrp.Position
        hudLabels.pos.Text = ("Pos: %.0f, %.0f, %.0f"):format(p.X, p.Y, p.Z)
    end
    local hum = getHumanoid(LP.Character)
    if hum then
        hudLabels.hp.Text = ("HP: %.0f / %.0f"):format(hum.Health, hum.MaxHealth)
    end
end))

-- ══════════════════════════════════════════════════════════════════════
-- TARGET INFO PANEL
-- ══════════════════════════════════════════════════════════════════════
local infoLabels = {}
do
    local keys = {"tName","tHP","tDist","tStatus"}
    for i, k in ipairs(keys) do
        local l = Drawing.new("Text")
        l.Visible = false; l.Size = 13; l.Font = Drawing.Fonts.UI
        l.Outline = true; l.OutlineColor = Color3.new(0,0,0)
        l.Color   = Color3.fromRGB(255, 215, 60)
        l.Position = Vector2.new(10, 10 + (i-1)*16)
        infoLabels[k] = l
    end
end

table.insert(Conns, RunService.Heartbeat:Connect(function()
    if not CFG.TargetInfo then
        for _, l in pairs(infoLabels) do l.Visible = false end
        return
    end
    for _, l in pairs(infoLabels) do l.Visible = true end
    local npc  = resolveNPCTarget(CFG.LockTarget)
    if not npc then for _, l in pairs(infoLabels) do l.Text = "" end; return end
    local hum  = getHumanoid(npc)
    local root = getRootPart(npc)
    local hrp  = getHRP()
    infoLabels.tName.Text   = "Target: " .. npc.Name
    infoLabels.tHP.Text     = hum
        and ("HP: %.0f / %.0f"):format(hum.Health, hum.MaxHealth) or "HP: ?"
    infoLabels.tDist.Text   = (root and hrp)
        and ("Dist: %.1f"):format((hrp.Position - root.Position).Magnitude) or "Dist: ?"
    infoLabels.tStatus.Text = (hum and hum.Health <= 0) and "Status: DEAD" or "Status: Alive"
end))

-- ══════════════════════════════════════════════════════════════════════
-- RADAR
-- ══════════════════════════════════════════════════════════════════════
local radarDots   = {}
local RADAR_C     = Vector2.new(200, 200)
local RADAR_R     = 60
local RADAR_RANGE = 120

local RADAR_BG = Drawing.new("Circle")
RADAR_BG.Filled = true; RADAR_BG.Color = Color3.new(0,0,0)
RADAR_BG.Transparency = 0.5; RADAR_BG.Radius = RADAR_R; RADAR_BG.Visible = false
RADAR_BG.Position = RADAR_C

local RADAR_RIM = Drawing.new("Circle")
RADAR_RIM.Filled = false; RADAR_RIM.Thickness = 1.5
RADAR_RIM.Color = Color3.fromRGB(80,200,255)
RADAR_RIM.Transparency = 1; RADAR_RIM.Radius = RADAR_R; RADAR_RIM.Visible = false
RADAR_RIM.Position = RADAR_C

table.insert(Conns, RunService.RenderStepped:Connect(function()
    if not CFG.Radar then
        RADAR_BG.Visible = false; RADAR_RIM.Visible = false
        for _, d in pairs(radarDots) do pcall(function() d.Visible = false end) end
        return
    end
    RADAR_BG.Visible = true; RADAR_RIM.Visible = true
    local hrp = getHRP()
    if not hrp then return end
    local myPos = hrp.Position
    local myYaw = math.atan2(-hrp.CFrame.LookVector.Z, hrp.CFrame.LookVector.X)
    local used  = {}
    for i, npc in ipairs(getCachedNPCs()) do
        local root = getRootPart(npc)
        if not root then continue end
        local diff  = root.Position - myPos
        local dist  = diff.Magnitude
        if dist > RADAR_RANGE then continue end
        local ang = math.atan2(-diff.Z, diff.X) - myYaw
        local r   = dist / RADAR_RANGE * RADAR_R
        local dot = radarDots[i]
        if not dot then
            dot = Drawing.new("Circle")
            dot.Filled = true; dot.Radius = 3; dot.Transparency = 1
            radarDots[i] = dot
        end
        dot.Color    = Color3.fromRGB(255, 60, 60)
        dot.Position = RADAR_C + Vector2.new(math.cos(ang) * r, -math.sin(ang) * r)
        dot.Visible  = true
        used[i] = true
    end
    for i, dot in pairs(radarDots) do
        if not used[i] then dot.Visible = false end
    end
end))

-- ══════════════════════════════════════════════════════════════════════
-- SMART HEAL
-- ══════════════════════════════════════════════════════════════════════
local lastHealTime = 0
task.spawn(function()
    while RUNNING do
        if CFG.SmartHeal then
            pcall(function()
                local hum = getHumanoid(LP.Character)
                local now = tick()
                if not hum then return end
                local pct = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth * 100) or 100
                if pct < CFG.HealThreshold and (now - lastHealTime) > CFG.HealCooldown then
                    lastHealTime = now
                    if HealEvent then pcall(function() HealEvent:FireServer() end) end
                    VIM:SendKeyEvent(true,  CFG.HealKey, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, CFG.HealKey, false, game)
                end
            end)
        end
        task.wait(0.15)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO COLLECT
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while RUNNING do
        if CFG.AutoCollect then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name:lower():find(CFG.CollectFilter) then
                        if (hrp.Position - v.Position).Magnitude < CFG.CollectRange then
                            local pp = v:FindFirstChildOfClass("ProximityPrompt")
                            if pp then pcall(function() fireproximityprompt(pp) end) end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER TRACKER
-- ══════════════════════════════════════════════════════════════════════
local playerESP = {}

table.insert(Conns, RunService.RenderStepped:Connect(function()
    if not CFG.PlayerTracker then
        for _, e in pairs(playerESP) do
            for _, d in pairs(e) do pcall(function() d.Visible = false end) end
        end
        return
    end
    local cam = workspace.CurrentCamera
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            if playerESP[plr] then
                for _, d in pairs(playerESP[plr]) do pcall(function() d.Visible = false end) end
            end
            continue
        end
        if not playerESP[plr] then
            local box = Drawing.new("Square")
            box.Filled = false; box.Color = Color3.fromRGB(50,150,255)
            box.Thickness = 1.5; box.Transparency = 1
            local lbl = Drawing.new("Text")
            lbl.Size = 13; lbl.Font = Drawing.Fonts.UI
            lbl.Outline = true; lbl.Color = Color3.fromRGB(50,200,255); lbl.Transparency = 1
            playerESP[plr] = { box=box, lbl=lbl }
        end
        local e         = playerESP[plr]
        local s, vis    = cam:WorldToViewportPoint(root.Position + Vector3.new(0,2,0))
        if not vis then e.box.Visible = false; e.lbl.Visible = false; continue end
        local scale     = 1/s.Z*1000
        local bw, bh    = 40*scale, 70*scale
        e.box.Size      = Vector2.new(bw, bh)
        e.box.Position  = Vector2.new(s.X - bw*0.5, s.Y - bh*0.5)
        e.box.Visible   = true
        e.lbl.Text      = plr.Name
        e.lbl.Position  = Vector2.new(s.X - bw*0.5, s.Y - bh*0.5 - 15)
        e.lbl.Visible   = true
    end
    -- prune disconnected
    for plr, e in pairs(playerESP) do
        if not plr.Parent then
            for _, d in pairs(e) do pcall(function() d:Remove() end) end
            playerESP[plr] = nil
        end
    end
end))

-- ══════════════════════════════════════════════════════════════════════
-- AUTO REJOIN
-- ══════════════════════════════════════════════════════════════════════
local TS = game:GetService("TeleportService")
task.spawn(function()
    while RUNNING do
        if CFG.AutoRejoin then
            pcall(function()
                local hum = getHumanoid(LP.Character)
                if hum and hum.Health <= 0 and CFG.RejoinOnDeath then
                    task.wait(CFG.RejoinDelay)
                    TS:Teleport(game.PlaceId, LP)
                end
            end)
        end
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- INVISIBLE
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    local wasOn = false
    while RUNNING do
        if CFG.Invisible and not wasOn then
            wasOn = true
            local c = LP.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") or p:IsA("Decal") then
                        p.LocalTransparencyModifier = 1
                    end
                end
            end
        elseif not CFG.Invisible and wasOn then
            wasOn = false
            local c = LP.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") or p:IsA("Decal") then
                        p.LocalTransparencyModifier = 0
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- ANTI-AFK
-- ══════════════════════════════════════════════════════════════════════
table.insert(Conns, LP.Idled:Connect(function()
    if CFG.AntiAFK then
        VIM:SendKeyEvent(true,  Enum.KeyCode.W, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
    end
end))

-- ══════════════════════════════════════════════════════════════════════
-- RESPAWN WATCHER  (re-applies fly/speed/camlock after respawn)
-- ══════════════════════════════════════════════════════════════════════
table.insert(Conns, LP.CharacterAdded:Connect(function(c)
    myChar = c
    myR    = c:WaitForChild("HumanoidRootPart", 5)
    myName = LP.Name
    task.wait(1.5)
    if CFG.Fly       then startFly()       end
    if CFG.SpeedHack then applySpeedHack() end
    if CFG.CamLock   then startCamLock()   end
end))

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG AUTO-SAVE / LOAD
-- ══════════════════════════════════════════════════════════════════════
local SAVE_FILE = "EE_MFH_v11_cfg.json"
local HS = game:GetService("HttpService")

local function saveConfig()
    local ok, data = pcall(function()
        local t = {}
        for k, v in pairs(CFG) do
            -- skip non-serialisable types (Color3, KeyCode)
            local tp = type(v)
            if tp == "boolean" or tp == "number" or tp == "string" then
                t[k] = v
            end
        end
        return HS:JSONEncode(t)
    end)
    if ok and data then safeWriteFile(SAVE_FILE, data) end
end

local function loadConfig()
    local data = safeReadFile(SAVE_FILE)
    if not data then return end
    local ok, t = pcall(function() return HS:JSONDecode(data) end)
    if not ok or type(t) ~= "table" then return end
    for k, v in pairs(t) do
        if CFG[k] ~= nil and type(v) == type(CFG[k]) then
            CFG[k] = v
        end
    end
end

loadConfig()

task.spawn(function()
    while RUNNING do
        task.wait(30)
        pcall(saveConfig)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- KEYBIND SYSTEM
-- ══════════════════════════════════════════════════════════════════════
local Keybinds = {
    [Enum.KeyCode.F1]  = "ESP",
    [Enum.KeyCode.F2]  = "Radar",
    [Enum.KeyCode.F3]  = "CamLock",
    [Enum.KeyCode.F4]  = "Fly",
    [Enum.KeyCode.F5]  = "SpeedHack",
    [Enum.KeyCode.F6]  = "Noclip",
    [Enum.KeyCode.F7]  = "AutoFarm",
    [Enum.KeyCode.F8]  = "SaveDeath",
    [Enum.KeyCode.F9]  = "Fullbright",
    [Enum.KeyCode.F10] = "StatHUD",
}

local function syncToggleVisual(cfgKey, newVal)
    for _, btn in ipairs(SG:GetDescendants()) do
        if btn:IsA("TextButton") and btn:GetAttribute("CFGKey") == cfgKey then
            btn.BackgroundColor3 = newVal
                and Color3.fromRGB(40, 180, 80)
                or  Color3.fromRGB(180, 40, 40)
            btn.Text = (btn:GetAttribute("Label") or cfgKey)
                .. (newVal and "  ON" or "  OFF")
        end
    end
end

table.insert(Conns, UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    local cfgKey = Keybinds[inp.KeyCode]
    if cfgKey and CFG[cfgKey] ~= nil then
        CFG[cfgKey] = not CFG[cfgKey]
        syncToggleVisual(cfgKey, CFG[cfgKey])
        pcall(saveConfig)
    end
end))

-- ══════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ══════════════════════════════════════════════════════════════════════
local function cleanup()
    RUNNING = false
    for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    Conns = {}

    pcall(function()
        local hum = getHumanoid(LP.Character)
        if hum then
            hum.WalkSpeed     = 16
            hum.JumpPower     = 50
            hum.PlatformStand = false
            hum.AutoRotate    = true
        end
    end)

    cleanFly()
    removeSpeedHack()
    stopCamLock()
    removeFullbright()
    clearHitboxes()

    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if speedConn  then speedConn:Disconnect();  speedConn  = nil end

    local c = LP.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
                p.LocalTransparencyModifier = 0
            end
        end
    end

    for npc in pairs(espObjects)  do removeESPEntry(npc) end
    for _, e in pairs(playerESP)  do
        for _, d in pairs(e) do pcall(function() d:Remove() end) end
    end
    for _, l in pairs(hudLabels)  do pcall(function() l:Remove() end) end
    for _, l in pairs(infoLabels) do pcall(function() l:Remove() end) end
    for _, d in pairs(radarDots)  do pcall(function() d:Remove() end) end
    pcall(function() RADAR_BG:Remove()  end)
    pcall(function() RADAR_RIM:Remove() end)

    pcall(saveConfig)
    pcall(function() MFH_GUI:Destroy() end)

    print("[EE MFH v11.1] Unloaded cleanly.")
end

if _G.EE_MFH_CLEANUP then pcall(_G.EE_MFH_CLEANUP) end
_G.EE_MFH_CLEANUP = cleanup

-- ══════════════════════════════════════════════════════════════════════
-- STARTUP NOTIFICATION
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(0.5)
    local notif = Instance.new("ScreenGui")
    notif.Name           = "MFH_Notif"
    notif.ResetOnSpawn   = false
    notif.IgnoreGuiInset = true
    notif.Parent         = SG

    local f = Instance.new("Frame", notif)
    f.Size             = UDim2.new(0, 360, 0, 48)
    f.Position         = UDim2.new(0.5, -180, 0, 18)
    f.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    f.BorderSizePixel  = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color     = Color3.fromRGB(80, 200, 255)
    stroke.Thickness = 1.5

    local lbl = Instance.new("TextLabel", f)
    lbl.Size  = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text  = "Eternal Enemies  MFH v11.1  |  F1-F10 Keybinds Active"
    lbl.TextColor3 = Color3.fromRGB(80, 210, 255)
    lbl.Font  = Enum.Font.GothamBold
    lbl.TextSize = 13

    task.delay(3.5, function()
        for i = 1, 20 do
            f.BackgroundTransparency = i / 20
            lbl.TextTransparency     = i / 20
            task.wait(0.05)
        end
        notif:Destroy()
    end)
end)

print("[EE MFH v11.1] Loaded OK | _G.EE_MFH_CLEANUP() to unload | F1-F10 keybinds")
