-- // MONEY/FREE HUB V14.1 // --
-- // Forward-only movement | Tech picker | BF rebuild | Lock fix //--

repeat task.wait() until game:IsLoaded()
task.wait(2)

-- ===== RAYFIELD =====
local Rayfield = nil
for _, url in ipairs({'https://sirius.menu/rayfield','https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'}) do
    local ok, res = pcall(function() return loadstring(game:HttpGet(url))() end)
    if ok and res then Rayfield = res; break end
end
if not Rayfield then return end

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- ===== UTILS =====
local function getChar() return LP.Character end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function pChar(p) return p and p.Character end
local function pRoot(p) local c = pChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function pHum(p) local c = pChar(p) return c and c:FindFirstChildOfClass("Humanoid") end

local scriptPressing = false
local function tapKey(key, holdTime)
    if not key then return end
    scriptPressing = true
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(holdTime or 0.03)
    VIM:SendKeyEvent(false, key, false, game)
    scriptPressing = false
end
local function tapKeyAsync(k, h) task.spawn(tapKey, k, h) end
local function holdKey(key, isDown) VIM:SendKeyEvent(isDown, key, false, game) end
local function clickMouse()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.012)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end
local function getPing()
    local p = 80
    pcall(function() p = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return p
end
local function isHardStunned(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local ok, s = pcall(function() return hum:GetState() end)
    if not ok then return false end
    return s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll
        or s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.PlatformStanding
end

local K = {
    Q=Enum.KeyCode.Q, E=Enum.KeyCode.E, R=Enum.KeyCode.R, F=Enum.KeyCode.F, G=Enum.KeyCode.G,
    One=Enum.KeyCode.One, Two=Enum.KeyCode.Two, Three=Enum.KeyCode.Three, Four=Enum.KeyCode.Four,
    Space=Enum.KeyCode.Space,
}

-- ===== STATE =====
getgenv().MoneyHub = {
    Enabled = false,
    Difficulty = "Expert",
    SelectedChar = "Vessel",
    SelectedTech = "Random", -- NEW: specific tech selection
    Target = nil, LockedTarget = nil, LockHard = false,
    M1Count = 0, HitCount = 0, MissCount = 0, ComboStep = 0,
    ChainActive = false, IsBlocking = false,
    LastAttack = 0, LastTech = 0, LastDash = 0, LastBF = 0,
    LastUlt = 0, LastJump = 0, LastBlock = 0, LastFeint = 0, LastDodge = 0,
    KeyState = {}, Kills = 0, Deaths = 0, PreviousHP = 0,
    MovementStyle = "Kimbaap",
    Viewing = nil,
    BFLoaded = false, TBOLoaded = false,
    FleeMode = false, RageMode = false,
    TotalDamageDealt = 0, TotalDamageTaken = 0,
    SessionStart = tick(),
    LoggedAnims = {}, LogAnims = false,

    Settings = {
        -- Combat
        AutoTechs = true, EnableDash = true, AutoUlt = false,
        AutoBlock = false, AutoBFChain = true, AdaptiveAI = false, -- OFF by default now
        AttackDelay = 0.06, AttackRange = 11, DashAggro = 1.2, TechFreq = 1.5,
        M1BeforeCombo = 3, M1Speed = 0.022,
        -- Movement
        Speed = 24, PreferredDistance = 4.0, -- closer default
        AutoJump = true, JumpCooldown = 1.2, JumpPower = 30,
        WallCheck = true, UseKeyboardMove = true,
        StrafeAmplitude = 4.0, StrafeFrequency = 5.5,
        -- Lock-On
        LockOnEnabled = true, LockKey = Enum.KeyCode.L,
        LockMode = "Nearest", LockCamera = true,
        AutoLockOnDamage = true, IgnoreOthers = true,
        LockSmoothness = 0.35, -- tighter default
        -- BF Chain
        BFChainReps = 4, BFAutoClose = true, BFCloseRange = 4,
        BFGoldenWindow = 0.28, BFUseLoader = false, BFAutoFire = true,
        -- Visuals
        ESP = false, RainbowESP = false, ShowHealth = true,
        ShowLockedTarget = true, ViewTarget = false,
        -- Ult
        UltHP = 0.55, UltMyHP = 0.35, UltSpam = true, UltCooldown = 2.5,
        -- Defense
        AutoFeint = true, AutoDodge = false,
        BlockHoldTime = 0.45, ParryMode = true,
        -- Misc
        NoClip = false, InfJump = false, StrictStun = true,
        UseTBOBlock = false, HideTBOGui = true,
        AntiRagdoll = false,
    },

    Profiles = {
        Noob = {attack=0.35, tech=4.5, m1chain=4, dashAggro=0.3, techChance=0.25, blockChance=0.20, reactionJitter=0.15, feintChance=0.0, dodgeChance=0.1, useBFChain=false, useFeint=false, m1Speed=0.05, m1count=2, perfectBlockRate=0.1},
        Pro = {attack=0.18, tech=3.0, m1chain=3, dashAggro=0.6, techChance=0.55, blockChance=0.60, reactionJitter=0.08, feintChance=0.3, dodgeChance=0.25, useBFChain=true, useFeint=false, m1Speed=0.035, m1count=3, perfectBlockRate=0.3},
        Good = {attack=0.10, tech=2.0, m1chain=3, dashAggro=0.9, techChance=0.80, blockChance=0.80, reactionJitter=0.04, feintChance=0.5, dodgeChance=0.4, useBFChain=true, useFeint=true, m1Speed=0.022, m1count=3, perfectBlockRate=0.6},
        Expert = {attack=0.05, tech=1.3, m1chain=3, dashAggro=1.4, techChance=0.98, blockChance=0.95, reactionJitter=0.02, feintChance=0.7, dodgeChance=0.6, useBFChain=true, useFeint=true, m1Speed=0.015, m1count=3, perfectBlockRate=0.85},
    },
}

local function profile()
    return getgenv().MoneyHub.Profiles[getgenv().MoneyHub.Difficulty] or getgenv().MoneyHub.Profiles.Expert
end

local clearMoveKeys, isValidEnemy

local function setMoveKey(key, down)
    local ks = getgenv().MoneyHub.KeyState
    if ks[key] == down then return end
    ks[key] = down
    holdKey(key, down)
end

clearMoveKeys = function()
    setMoveKey(Enum.KeyCode.W, false)
    setMoveKey(Enum.KeyCode.A, false)
    setMoveKey(Enum.KeyCode.S, false)
    setMoveKey(Enum.KeyCode.D, false)
end

local function fullStopAI()
    clearMoveKeys()
    if getgenv().MoneyHub.IsBlocking then
        holdKey(K.F, false)
        getgenv().MoneyHub.IsBlocking = false
    end
    getgenv().MoneyHub.ChainActive = false
    getgenv().MoneyHub.Target = nil
    local hum = getHum()
    if hum then pcall(function() hum.JumpPower = 50 end) end
end

-- ===== GUI HIDE HELPER =====
local function hideExternalGui(loaderFn)
    local preExisting = {}
    pcall(function()
        for _, gui in ipairs(LP.PlayerGui:GetChildren()) do preExisting[gui] = true end
        local cg = game:GetService("CoreGui")
        for _, gui in ipairs(cg:GetChildren()) do preExisting[gui] = true end
    end)
    local ok, err = pcall(loaderFn)
    task.wait(1.5)
    pcall(function()
        for _, gui in ipairs(LP.PlayerGui:GetChildren()) do
            if not preExisting[gui] and (gui:IsA("ScreenGui") or gui:IsA("Frame")) then
                local name = gui.Name:lower()
                if name ~= "rayfield" and not name:find("money") then
                    gui.Enabled = false
                    pcall(function() gui:Destroy() end)
                end
            end
        end
    end)
    return ok, err
end

-- ===== BF LOADER (Drakkiosauro) =====
local BFLoaderGlobals = {}

local function loadBFLoader()
    if getgenv().MoneyHub.BFLoaded then return true end
    local preG, preGenv = {}, {}
    for k in pairs(_G) do preG[k] = true end
    for k in pairs(getgenv()) do preGenv[k] = true end

    local ok, err = hideExternalGui(function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/Drakkiosauro/d6e6d82c7530dab2871391f9a82083d5/raw/9c0b22fb1bd23853abf29adb283d1726d53e93ce/gistfile1.txt"))()
    end)

    for k, v in pairs(_G) do
        if not preG[k] and type(v) == "function" then
            BFLoaderGlobals[k] = v
            print("[MoneyHub] BF gist exposed _G."..k)
        end
    end
    for k, v in pairs(getgenv()) do
        if not preGenv[k] and type(v) == "function" then
            BFLoaderGlobals[k] = v
            print("[MoneyHub] BF gist exposed getgenv()."..k)
        end
    end

    if ok then
        getgenv().MoneyHub.BFLoaded = true
        return true
    end
    warn("[MoneyHub] BF loader failed: " .. tostring(err))
    return false
end

local function callExternalBF(target)
    for _, fname in ipairs({"AutoBlackFlash","BlackFlashChain","TriggerBF","BFChain","blackflash","BlackFlash","startBF","startChain","runBF","fireBF","bf","BF"}) do
        local fn = BFLoaderGlobals[fname] or _G[fname] or getgenv()[fname]
        if type(fn) == "function" then
            local ok = pcall(fn, target)
            if ok then return true end
        end
    end
    for name, fn in pairs(BFLoaderGlobals) do
        if type(fn) == "function" then
            local ok = pcall(fn)
            if ok then return true end
        end
    end
    return false
end

-- ===== TBO LOADER =====
local function loadTBO(hideGui)
    if getgenv().MoneyHub.TBOLoaded then return true end
    local urls = {
        "https://raw.githubusercontent.com/cool5013/TBO/main/TBOscript",
        "https://raw.githubusercontent.com/cool5013/TBO/refs/heads/main/TBOscript",
    }
    for _, url in ipairs(urls) do
        local ok
        if hideGui then
            ok = hideExternalGui(function() loadstring(game:HttpGet(url))() end)
        else
            ok = pcall(function() loadstring(game:HttpGet(url))() end)
        end
        if ok then
            getgenv().MoneyHub.TBOLoaded = true
            return true
        end
    end
    return false
end

-- ===== CHARACTER MOVES =====
local CharMoves = setmetatable({}, {__index = function()
    return {dash=K.Q, skill1=K.One, skill2=K.Two, skill3=K.Three, skill4=K.Four, special=K.R, ult=K.G}
end})

-- ===== TECH LIBRARY =====
local TechLibrary = {
    Vessel = {
        {name="WikiCombo", seq={{K.Q,0.08},{"m1",0.04},{"m1",0.04},{"m1",0.04},{K.One,0.18},{K.Three,0.15}}},
        {name="Dash-CS", seq={{K.Q,0.06},{K.One,0.18}}},
        {name="Groundslam", seq={{K.Two,0.20}}},
        {name="DivergentBF", seq={{K.Three,0.08},{K.Three,0.18}}},
        {name="ManjiKick", seq={{K.Four,0.15}}},
        {name="Feint-CS-Crush", seq={{K.One,0.05},{K.R,0.04},{K.Two,0.18}}},
        {name="Feint-Crush-CS", seq={{K.Two,0.05},{K.R,0.04},{K.One,0.18}}},
        {name="Aerial-Dash-CS", seq={{K.Space,0.05},{K.Q,0.06},{K.One,0.18}}},
        {name="M1-DivergentBF", seq={{"m1",0.04},{"m1",0.04},{K.Three,0.08},{K.Three,0.15}}},
        {name="M1-Crush", seq={{"m1",0.04},{"m1",0.04},{K.Two,0.18}}},
    },
    ["Honored One"] = {
        {name="Blue-Red", seq={{K.One,0.15},{K.Two,0.20}}},
        {name="Red-Rapid", seq={{K.Two,0.12},{K.Three,0.18}}},
        {name="Purple", seq={{K.One,0.08},{K.Two,0.08},{K.Three,0.18}}},
        {name="Limitless-Blue", seq={{K.R,0.10},{K.One,0.15}}},
        {name="Twofold-Rapid", seq={{K.Three,0.10},{K.Four,0.15}}},
    },
    ["Restless Gambler"] = {
        {name="Doors-Rough", seq={{K.Two,0.12},{K.Three,0.18}}},
        {name="Reserve-Doors", seq={{K.One,0.12},{K.Two,0.15}}},
        {name="Fever", seq={{K.Four,0.15}}},
        {name="Guard-Rough", seq={{K.R,0.10},{K.Three,0.15}}},
    },
    ["Ten Shadows"] = {
        {name="Nue-Dog", seq={{K.Two,0.12},{K.Four,0.18}}},
        {name="Toad-Slam", seq={{K.Three,0.18}}},
        {name="Shadow-Dog", seq={{K.R,0.08},{K.Four,0.15}}},
    },
    Perfection = {
        {name="Stockpile-Fire", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Body-Repel", seq={{K.Four,0.15}}},
        {name="Focus-Repel", seq={{K.Three,0.12},{K.Four,0.15}}},
    },
    ["Blood Manipulator"] = {
        {name="Pierce-Scale", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Supernova", seq={{K.Three,0.18}}},
        {name="Edge-Conv", seq={{K.Four,0.10},{K.R,0.12}}},
    },
    Switcher = {
        {name="Swap-Kick", seq={{K.R,0.08},{K.One,0.15}}},
        {name="Brute-Elbow", seq={{K.Two,0.12},{K.Four,0.18}}},
        {name="Pebble-Kick", seq={{K.Three,0.08},{K.One,0.15}}},
    },
    ["Defense Attorney"] = {
        {name="Swings-Justice", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Reach-Charges", seq={{K.Three,0.12},{K.Four,0.18}}},
    },
    ["Cursed Partners"] = {
        {name="Sever-Slash", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Veilstep-Revolve", seq={{K.Three,0.10},{K.Four,0.15}}},
        {name="Rika-Slam", seq={{K.R,0.08},{K.One,0.15}}},
    },
    ["Puppet Master"] = {
        {name="Spin-Boost", seq={{K.One,0.10},{K.Two,0.15}}},
        {name="Cannon-Heat", seq={{K.Three,0.12},{K.Four,0.18}}},
    },
    ["Head of the Hei"] = {
        {name="Break-Bleed", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Decisive-Impact", seq={{K.Three,0.10},{K.Four,0.15}}},
    },
    Salaryman = {
        {name="Whirlwind-Sever", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Blunt-Stab", seq={{K.Three,0.12},{K.Four,0.15}}},
    },
    ["Disaster Plants"] = {
        {name="Root-Thorns", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Bud-Defense", seq={{K.Three,0.12},{K.Four,0.15}}},
    },
    ["True Cannon"] = {{name="Granite-Unsat", seq={{K.One,0.12},{K.Two,0.18}}}},
    ["Locust Guy"] = {{name="Clever-Mucus", seq={{K.One,0.12},{K.Two,0.18}}}},
    ["Star Rage"] = {{name="Garuda-Rising", seq={{K.One,0.12},{K.Two,0.18}}}},
    ["Aspiring Mangaka"] = {{name="Despair-Shut", seq={{K.One,0.12},{K.Two,0.18}}}},
    ["Lucky Coward"] = {
        {name="Ambush-Stab", seq={{K.One,0.12},{K.Two,0.18}}},
        {name="Ankle-Help", seq={{K.R,0.06},{K.One,0.15}}},
    },
    ["Crow Charmer"] = {{name="Updraft-Circle", seq={{K.One,0.12},{K.Two,0.18}}}},
}
setmetatable(TechLibrary, {__index = function() return {{name="Basic", seq={{K.One,0.15},{K.Two,0.15}}}} end})

local ALL_CHARS = {
    "Vessel","Honored One","Restless Gambler","Ten Shadows","Perfection","Blood Manipulator",
    "Switcher","Defense Attorney","Cursed Partners","Puppet Master","Head of the Hei","Salaryman",
    "Disaster Plants","True Cannon","Locust Guy","Star Rage","Aspiring Mangaka","Lucky Coward","Crow Charmer",
}

-- Get list of tech names for a character (for the dropdown)
local function getTechNames(charName)
    local techs = TechLibrary[charName] or {}
    local names = {"Random"}
    for _, t in ipairs(techs) do
        table.insert(names, t.name)
    end
    return names
end

-- Find a specific tech by name
local function findTech(charName, techName)
    local techs = TechLibrary[charName] or {}
    for _, t in ipairs(techs) do
        if t.name == techName then return t end
    end
    return nil
end

local function executeTech(seq)
    for _, action in ipairs(seq) do
        if action[1] == "m1" then clickMouse()
        else tapKey(action[1]) end
        task.wait(action[2])
    end
end

-- ===== KILL TRACKER + STATS =====
local lastTargetHealth = {}
task.spawn(function()
    while true do
        task.wait(0.15)
        if getgenv().MoneyHub.Enabled and getgenv().MoneyHub.Target then
            local hum = pHum(getgenv().MoneyHub.Target)
            if hum then
                local hp = hum.Health
                local prev = lastTargetHealth[getgenv().MoneyHub.Target] or hp
                if hp <= 0 and prev > 0 then getgenv().MoneyHub.Kills += 1 end
                if hp < prev then getgenv().MoneyHub.TotalDamageDealt += (prev - hp) end
                lastTargetHealth[getgenv().MoneyHub.Target] = hp
            end
        end
    end
end)

-- ===== ESP =====
local espTracked = {}
local function clearAllESP()
    for _, data in pairs(espTracked) do
        pcall(function() if data.hl then data.hl:Destroy() end end)
        pcall(function() if data.bb then data.bb:Destroy() end end)
    end
    espTracked = {}
end

task.spawn(function()
    while true do
        task.wait(0.3)
        for p, data in pairs(espTracked) do
            if not p.Character or (data.hl and not data.hl.Parent) then
                pcall(function() if data.hl then data.hl:Destroy() end end)
                pcall(function() if data.bb then data.bb:Destroy() end end)
                espTracked[p] = nil
            end
        end

        local showAnything = getgenv().MoneyHub.Settings.ESP or getgenv().MoneyHub.Settings.ShowLockedTarget
        if showAnything then
            local hue = tick() % 5 / 5
            local rainbow = Color3.fromHSV(hue, 1, 1)
            local mr = getRoot()
            local lockedP = getgenv().MoneyHub.LockedTarget

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local isLocked = p == lockedP
                    local shouldShow = getgenv().MoneyHub.Settings.ESP or (getgenv().MoneyHub.Settings.ShowLockedTarget and isLocked)

                    if shouldShow then
                        if not espTracked[p] then
                            local hl = Instance.new("Highlight")
                            hl.Name = "MoneyHubESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.new(1, 1, 1)
                            hl.FillTransparency = 0.6
                            hl.Parent = p.Character
                            local head = p.Character:FindFirstChild("Head")
                            local bb
                            if head and getgenv().MoneyHub.Settings.ShowHealth then
                                bb = Instance.new("BillboardGui")
                                bb.Adornee = head; bb.Size = UDim2.new(0, 140, 0, 44)
                                bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
                                bb.Parent = head
                                local nm = Instance.new("TextLabel", bb)
                                nm.Size = UDim2.new(1,0,0,14); nm.BackgroundTransparency = 1
                                nm.Text = p.DisplayName; nm.TextColor3 = Color3.new(1,1,1)
                                nm.TextSize = 12; nm.Font = Enum.Font.GothamBold; nm.TextStrokeTransparency = 0
                                local hpLbl = Instance.new("TextLabel", bb)
                                hpLbl.Name = "HP"; hpLbl.Size = UDim2.new(1,0,0,11)
                                hpLbl.Position = UDim2.new(0,0,0,14); hpLbl.BackgroundTransparency = 1
                                hpLbl.TextSize = 10; hpLbl.Font = Enum.Font.Gotham; hpLbl.TextStrokeTransparency = 0.1
                                local dtLbl = Instance.new("TextLabel", bb)
                                dtLbl.Name = "D"; dtLbl.Size = UDim2.new(1,0,0,10)
                                dtLbl.Position = UDim2.new(0,0,0,25); dtLbl.BackgroundTransparency = 1
                                dtLbl.TextColor3 = Color3.fromRGB(180,180,210)
                                dtLbl.TextSize = 9; dtLbl.Font = Enum.Font.Gotham
                                local tagLbl = Instance.new("TextLabel", bb)
                                tagLbl.Name = "TAG"; tagLbl.Size = UDim2.new(1,0,0,10)
                                tagLbl.Position = UDim2.new(0,0,0,34); tagLbl.BackgroundTransparency = 1
                                tagLbl.TextSize = 10; tagLbl.Font = Enum.Font.GothamBold
                            end
                            espTracked[p] = {hl=hl, bb=bb}
                        end

                        local color
                        if isLocked then
                            color = Color3.fromRGB(255, 220, 0)
                            espTracked[p].hl.FillTransparency = 0.3
                        else
                            color = getgenv().MoneyHub.Settings.RainbowESP and rainbow or Color3.fromRGB(255,0,0)
                            espTracked[p].hl.FillTransparency = 0.6
                        end
                        espTracked[p].hl.FillColor = color
                        espTracked[p].hl.OutlineColor = isLocked and Color3.fromRGB(255,255,0) or (getgenv().MoneyHub.Settings.RainbowESP and rainbow or Color3.new(1,1,1))

                        if espTracked[p].bb then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            local hpLb = espTracked[p].bb:FindFirstChild("HP")
                            local dtLb = espTracked[p].bb:FindFirstChild("D")
                            local tagLb = espTracked[p].bb:FindFirstChild("TAG")
                            if hum and hpLb then
                                local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth,1),0,1)
                                hpLb.Text = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                                hpLb.TextColor3 = ratio > 0.5 and Color3.fromRGB(70,220,100) or ratio > 0.25 and Color3.fromRGB(220,180,50) or Color3.fromRGB(220,60,60)
                            end
                            if mr and dtLb and p.Character:FindFirstChild("HumanoidRootPart") then
                                dtLb.Text = math.floor((mr.Position - p.Character.HumanoidRootPart.Position).Magnitude).."m"
                            end
                            if tagLb then
                                tagLb.Text = isLocked and "[LOCKED]" or ""
                                tagLb.TextColor3 = Color3.fromRGB(255, 220, 0)
                            end
                        end
                    elseif espTracked[p] then
                        pcall(function() espTracked[p].hl:Destroy() end)
                        pcall(function() espTracked[p].bb:Destroy() end)
                        espTracked[p] = nil
                    end
                end
            end
        else clearAllESP() end
    end
end)

-- ===== TARGETING =====
isValidEnemy = function(player)
    if not player or player == LP then return false end
    local c = pChar(player); local h = pHum(player); local r = pRoot(player)
    return c and h and r and h.Health > 0
end

local function getNearest(range)
    range = range or 300
    local meRoot = getRoot()
    if not meRoot then return nil end
    local target, minDist = nil, range
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidEnemy(p) then
            local dist = (meRoot.Position - pRoot(p).Position).Magnitude
            if dist < minDist then minDist = dist; target = p end
        end
    end
    return target
end

local function getNearestToCrosshair()
    local camera = WS.CurrentCamera
    local meRoot = getRoot()
    if not camera or not meRoot then return nil end
    local center = camera.ViewportSize / 2
    local best, bestScore = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidEnemy(p) then
            local tr = pRoot(p)
            local sp, onScreen = camera:WorldToViewportPoint(tr.Position)
            if onScreen then
                local score = (Vector2.new(sp.X,sp.Y) - center).Magnitude + (meRoot.Position - tr.Position).Magnitude * 0.5
                if score < bestScore then bestScore = score; best = p end
            end
        end
    end
    return best
end

local function acquireLockTarget()
    if getgenv().MoneyHub.Settings.LockMode == "Crosshair" then
        return getNearestToCrosshair() or getNearest()
    end
    return getNearest()
end

local function findAttacker()
    local meRoot = getRoot()
    if not meRoot then return nil end
    local best, bd = nil, 40
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidEnemy(p) then
            local r = pRoot(p)
            local h = pHum(p)
            local dist = (meRoot.Position - r.Position).Magnitude
            if dist < bd then
                local toMe = (meRoot.Position - r.Position).Unit
                local facingDot = toMe:Dot(r.CFrame.LookVector)
                local valid = false
                if dist < 15 and facingDot > 0.2 then valid = true
                elseif dist < 40 and facingDot > 0.4 then
                    pcall(function()
                        local an = h:FindFirstChildOfClass("Animator")
                        if an then
                            for _, tr in ipairs(an:GetPlayingAnimationTracks()) do
                                if tr.IsPlaying then valid = true; return end
                            end
                        end
                    end)
                end
                if valid and dist < bd then bd = dist; best = p end
            end
        end
    end
    return best or getNearest()
end

-- Auto lock on damage (IMPROVED - won't override hard lock)
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().MoneyHub.Enabled and getgenv().MoneyHub.Settings.AutoLockOnDamage then
            local hum = getHum()
            if hum and hum.Health > 0 then
                local hp = hum.Health
                if getgenv().MoneyHub.PreviousHP > 0 and hp < getgenv().MoneyHub.PreviousHP - 0.3 then
                    local dmg = getgenv().MoneyHub.PreviousHP - hp
                    getgenv().MoneyHub.TotalDamageTaken += dmg
                    -- If already hard locked with ignore others, DON'T override
                    local alreadyLocked = getgenv().MoneyHub.LockHard
                        and getgenv().MoneyHub.Settings.IgnoreOthers
                        and isValidEnemy(getgenv().MoneyHub.LockedTarget)
                    if not alreadyLocked then
                        local attacker = findAttacker()
                        if attacker and attacker ~= getgenv().MoneyHub.LockedTarget then
                            getgenv().MoneyHub.LockHard = true
                            getgenv().MoneyHub.LockedTarget = attacker
                            pcall(function() Rayfield:Notify({Title="Auto Lock", Content=attacker.DisplayName, Duration=2}) end)
                        end
                    end
                end
                getgenv().MoneyHub.PreviousHP = hp
            else getgenv().MoneyHub.PreviousHP = 0 end
        end
    end
end)

-- Lock-on camera (tighter)
RS.RenderStepped:Connect(function()
    local s = getgenv().MoneyHub
    if not s.Settings.LockOnEnabled then return end
    if not s.Settings.LockCamera then return end
    if not s.LockHard then return end
    if not isValidEnemy(s.LockedTarget) then
        if s.Settings.IgnoreOthers then
            -- Wait for respawn, don't release
            if s.LockedTarget and s.LockedTarget.Parent then return end
            s.LockHard = false; s.LockedTarget = nil; return
        else
            local nt = acquireLockTarget()
            if nt then s.LockedTarget = nt
            else s.LockHard = false; return end
        end
    end
    local tr = pRoot(s.LockedTarget); if not tr then return end
    local cam = WS.CurrentCamera; if not cam then return end
    local head = s.LockedTarget.Character and s.LockedTarget.Character:FindFirstChild("Head")
    local aimPos = head and head.Position or (tr.Position + Vector3.new(0,1.4,0))
    local targetCF = CFrame.new(cam.CFrame.Position, aimPos)
    cam.CFrame = cam.CFrame:Lerp(targetCF, s.Settings.LockSmoothness)
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp or scriptPressing then return end
    if not getgenv().MoneyHub.Settings.LockOnEnabled then return end
    if input.KeyCode == getgenv().MoneyHub.Settings.LockKey then
        getgenv().MoneyHub.LockHard = not getgenv().MoneyHub.LockHard
        if getgenv().MoneyHub.LockHard then
            getgenv().MoneyHub.LockedTarget = acquireLockTarget()
        else
            getgenv().MoneyHub.LockedTarget = nil
        end
        Rayfield:Notify({
            Title = "Lock-On",
            Content = getgenv().MoneyHub.LockHard
                and (getgenv().MoneyHub.LockedTarget and ("Locked: "..getgenv().MoneyHub.LockedTarget.DisplayName) or "No target")
                or "Unlocked",
            Duration = 1.5,
        })
    end
end)

local function getTarget()
    local s = getgenv().MoneyHub
    if s.LockHard and s.Settings.IgnoreOthers then
        if s.LockedTarget and s.LockedTarget.Parent then
            if isValidEnemy(s.LockedTarget) then return s.LockedTarget end
            return nil -- respawning, wait
        end
        s.LockHard = false; s.LockedTarget = nil
        return nil
    end
    if s.LockHard then
        if isValidEnemy(s.LockedTarget) then return s.LockedTarget end
        s.LockedTarget = acquireLockTarget()
        if not isValidEnemy(s.LockedTarget) then s.LockHard = false; s.LockedTarget = nil end
        return s.LockedTarget
    end
    return acquireLockTarget()
end

-- ===== NOCLIP =====
local noclipConn = nil
local function enableNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RS.Stepped:Connect(function()
        if not getgenv().MoneyHub.Settings.NoClip then return end
        local char = getChar()
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
        end
    end)
end

-- ============================================
-- MOVEMENT (FORWARD-ONLY REWRITE)
-- ============================================
-- KEY RULE: AI never backs up when close to target.
-- When too close: strafes sideways to find a new angle, never retreats.
-- When too far: walks straight toward target.
-- When in range: circle-strafes around target.
-- Flee mode is the ONLY case where AI moves away.
local function doSmartMove(hum, root, tRoot, dist)
    local style = getgenv().MoneyHub.MovementStyle
    local settings = getgenv().MoneyHub.Settings
    local toTarget = tRoot.Position - root.Position
    local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
    local forward = flat.Magnitude > 0 and flat.Unit or root.CFrame.LookVector
    local right = Vector3.new(forward.Z, 0, -forward.X)
    local desiredDist = settings.PreferredDistance
    local t = tick()
    local amp = settings.StrafeAmplitude
    local freq = settings.StrafeFrequency

    -- FLEE MODE = the only case we move away from target
    if getgenv().MoneyHub.FleeMode then
        local fleePos = root.Position - forward * 10
        hum:MoveTo(fleePos)
        if settings.UseKeyboardMove then setMoveKey(Enum.KeyCode.S, true) end
        return
    end

    -- Calculate strafe offset based on movement style
    local strafeOffset = Vector3.zero

    if style == "Kimbaap" then
        -- Tight side-to-side weaving at close range
        desiredDist = 3.5
        strafeOffset = right * (math.sin(t * 7) * amp)
    elseif style == "Circle" then
        -- Continuous circle around target
        local angle = t * 2.2
        strafeOffset = right * math.cos(angle) * amp + forward * math.sin(angle) * (amp * 0.3)
    elseif style == "Orbital" then
        -- Wider orbit
        local angle = t * 1.8
        strafeOffset = right * math.cos(angle) * (amp * 1.5) + forward * math.sin(angle) * (amp * 0.5)
    elseif style == "Pro" then
        -- Unpredictable sine weaving with micro-jukes
        strafeOffset = right * (math.sin(t * freq) * amp + math.sin(t * freq * 2.1) * (amp * 0.3))
    elseif style == "Aggro" then
        -- Minimal strafe, stay glued close
        desiredDist = 2.5
        strafeOffset = right * (math.sin(t * freq * 1.5) * (amp * 0.4))
    elseif style == "Straight" then
        -- No strafing, just chase
        strafeOffset = Vector3.zero
    end

    -- CRITICAL FIX: Always move TOWARD target, never back up
    -- chasePos is always at or past the target, offset sideways
    local chasePos
    if dist > desiredDist then
        -- Too far: walk toward target, applying strafe
        chasePos = tRoot.Position + strafeOffset - forward * desiredDist
    else
        -- In range: pure strafe around target, NO backing up
        -- We pick a point tangent to our current position
        chasePos = tRoot.Position + strafeOffset - forward * desiredDist
        -- If somehow this would put us behind our current pos relative to target,
        -- just strafe sideways instead
        local proposedDist = (chasePos - tRoot.Position).Magnitude
        if proposedDist > dist + 1 then
            -- Would move us further - force sideways strafe instead
            chasePos = root.Position + right * (strafeOffset.Magnitude > 0 and (strafeOffset.X > 0 and 3 or -3) or 3)
        end
    end

    hum:MoveTo(chasePos)

    if settings.UseKeyboardMove then
        local toChase = Vector3.new((chasePos - root.Position).X, 0, (chasePos - root.Position).Z)
        if toChase.Magnitude > 0.5 then
            local fDot = toChase.Unit:Dot(Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit)
            local rDot = toChase.Unit:Dot(Vector3.new(root.CFrame.RightVector.X, 0, root.CFrame.RightVector.Z).Unit)
            -- FIXED: NEVER press S (backward) except in flee mode
            setMoveKey(Enum.KeyCode.W, fDot > 0.2)
            setMoveKey(Enum.KeyCode.S, false) -- never back up
            setMoveKey(Enum.KeyCode.D, rDot > 0.3)
            setMoveKey(Enum.KeyCode.A, rDot < -0.3)
        else
            clearMoveKeys()
        end
    end

    -- Always face target
    root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))

    -- Jump logic (unchanged)
    if settings.AutoJump and (tick() - getgenv().MoneyHub.LastJump) > settings.JumpCooldown then
        local shouldJump = false
        if settings.WallCheck then
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {getChar()}
            pcall(function() rp.FilterType = Enum.RaycastFilterType.Exclude end)
            local md = chasePos - root.Position
            if md.Magnitude > 1 then
                local wallRay = WS:Raycast(root.Position, Vector3.new(md.X,0,md.Z).Unit * 4, rp)
                if wallRay then shouldJump = true end
            end
        end
        if dist < 12 and math.random() < 0.008 then shouldJump = true end
        if shouldJump then
            pcall(function() hum.JumpPower = settings.JumpPower end)
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics then
                hum.Jump = true
                getgenv().MoneyHub.LastJump = tick()
            end
        end
    end
end

-- ===== AUTO BLOCK =====
local ATTACK_KEYWORDS = {
    "punch","attack","hit","slash","combo","kick","fist","swing","m1","strike","blow",
    "curse","cleav","crush","divergent","manji","lapse","reversal","purple","twofold",
    "rapid","rough","pierc","blood","severance","whirlwind","blunt","spin","cannon",
    "stab","root","thorn","rush","slam","dismantle","open","cleave","reserve","shutter",
    "fever","rabbit","nue","toad","dog","shadow","stockpile","soul","focus","repel",
    "transfig","flowing","scale","supernova","edge","converg","swift","brute","pebble",
    "elbow","boogie","extend","justice","judge","pressing","escape","severing","resolute",
    "veil","revolve","rika","ultra","boost","heat","emission","offload","projection",
    "bleed","decisive","cursory","impact","cleaving","ratio","stabilize","ambush",
    "backstab","trip","cheap","updraft","circle","glid","bird","garuda","rising","mass",
    "clever","mucus","jaw","wing","flutter","despair","shut","catching","sacrilege",
    "granite","blast","helping","appetizer","restyle","sever"
}
local HEAVY_KEYWORDS = {"crushing","supernova","hollow","purple","malevolent","world","cutting","domain","infinite","void","kamutoke","shrine","plasma","embodiment"}

local function animLooksLikeAttack(name)
    name = name:lower()
    for _, kw in ipairs(ATTACK_KEYWORDS) do if name:find(kw) then return true end end
    return false
end
local function animLooksHeavy(name)
    name = name:lower()
    for _, kw in ipairs(HEAVY_KEYWORDS) do if name:find(kw) then return true end end
    return false
end

local seenAttackAnims = {}

local function detectAttackFromTarget(target)
    if not target or not target.Character then return false, false end
    local r = pRoot(target); local h = pHum(target); local myRoot = getRoot()
    if not r or not h or not myRoot then return false, false end
    if (myRoot.Position - r.Position).Magnitude > 16 then return false, false end
    local toMe = (myRoot.Position - r.Position).Unit
    if toMe:Dot(r.CFrame.LookVector) < 0.25 then return false, false end
    local detected, heavy = false, false
    pcall(function()
        local an = h:FindFirstChildOfClass("Animator")
        if not an then return end
        for _, tr in ipairs(an:GetPlayingAnimationTracks()) do
            if tr.IsPlaying then
                local name = tr.Name
                if getgenv().MoneyHub.LogAnims then
                    getgenv().MoneyHub.LoggedAnims[name] = (getgenv().MoneyHub.LoggedAnims[name] or 0) + 1
                end
                if animLooksLikeAttack(name) then
                    local key = tostring(target.UserId).."_"..name
                    if not seenAttackAnims[key] or (tick() - seenAttackAnims[key]) > 1.5 then
                        seenAttackAnims[key] = tick()
                        detected = true
                        if animLooksHeavy(name) then heavy = true end
                        return
                    end
                end
            end
        end
    end)
    return detected, heavy
end

local function setBlocking(block)
    if block ~= getgenv().MoneyHub.IsBlocking then
        getgenv().MoneyHub.IsBlocking = block
        holdKey(K.F, block)
        if block then getgenv().MoneyHub.LastBlock = tick() end
    end
end

local function tryDodge(target)
    if tick() - getgenv().MoneyHub.LastDodge < 1.5 then return false end
    local moves = CharMoves[getgenv().MoneyHub.SelectedChar]
    if not moves then return false end
    -- Dodge = sidestep + dash (NOT backward)
    setMoveKey(Enum.KeyCode.A, true)
    task.wait(0.04)
    tapKey(moves.dash or K.Q)
    task.delay(0.15, function() setMoveKey(Enum.KeyCode.A, false) end)
    getgenv().MoneyHub.LastDodge = tick()
    return true
end

local function tryFeintCancel()
    if tick() - getgenv().MoneyHub.LastFeint < 0.8 then return false end
    if not profile().useFeint then return false end
    tapKey(K.R, 0.04)
    getgenv().MoneyHub.LastFeint = tick()
    return true
end

local function handleAutoBlock(target)
    if not getgenv().MoneyHub.Settings.AutoBlock then return end
    if getgenv().MoneyHub.Settings.UseTBOBlock and getgenv().MoneyHub.TBOLoaded then return end
    local detected, heavy = detectAttackFromTarget(target)
    if detected then
        local prof = profile()
        if heavy and getgenv().MoneyHub.Settings.AutoDodge and math.random() < prof.dodgeChance then
            tryDodge(target)
            return
        end
        if math.random() < prof.blockChance then
            local jitter = prof.reactionJitter * (0.5 + math.random())
            task.delay(jitter, function()
                if getgenv().MoneyHub.Settings.AutoFeint and math.random() < prof.feintChance then
                    tryFeintCancel()
                    task.wait(0.03)
                end
                setBlocking(true)
                local holdTime = getgenv().MoneyHub.Settings.BlockHoldTime
                if getgenv().MoneyHub.Settings.ParryMode and math.random() < prof.perfectBlockRate then
                    holdTime = 0.25
                end
                task.delay(holdTime, function()
                    if tick() - getgenv().MoneyHub.LastBlock >= holdTime - 0.05 then
                        setBlocking(false)
                    end
                end)
            end)
        end
    end
end

-- ============================================
-- BLACK FLASH CHAIN (REBUILT - my own clean version)
-- ============================================
-- New approach:
-- 1. Press 3 (Divergent Fist starts)
-- 2. Wait the golden window (ping compensated)
-- 3. Press 3 again (Black Flash triggers)
-- 4. Walk (not teleport) behind target using MoveTo
-- 5. Repeat for chainReps
-- Key fix: no more CFrame snap that caused "glitch behind" issue
-- Also: if external loader is enabled AND loaded, try it first, fall back to this
local function doBlackFlashChain(target)
    if not target then return false end
    if getgenv().MoneyHub.ChainActive then return false end
    if tick() - getgenv().MoneyHub.LastBF < 4 then return false end

    local myRoot = getRoot()
    local tRoot = pRoot(target)
    if not myRoot or not tRoot then return false end

    -- External loader first if enabled
    if getgenv().MoneyHub.Settings.BFUseLoader and getgenv().MoneyHub.BFLoaded then
        if callExternalBF(target) then
            getgenv().MoneyHub.LastBF = tick()
            return true
        end
    end

    -- Built-in BF chain
    getgenv().MoneyHub.ChainActive = true
    local bfKey = getgenv().MoneyHub.SelectedChar == "Vessel" and K.Three or K.One

    task.spawn(function()
        local ping = getPing()
        local goldenWindow = math.clamp(getgenv().MoneyHub.Settings.BFGoldenWindow - (ping / 2000), 0.12, 0.38)

        -- Pre-hit with an M1 to get hit-stun started
        clickMouse()
        task.wait(0.08)

        local reps = getgenv().MoneyHub.Settings.BFChainReps
        for i = 1, reps do
            if not getgenv().MoneyHub.Enabled then break end
            local tHum = pHum(target)
            if not tHum or tHum.Health <= 0 then break end
            if not target.Character then break end

            -- Press 3 to start Divergent Fist
            tapKey(bfKey, 0.05)
            -- Wait the golden window
            task.wait(goldenWindow)
            -- Press 3 again for Black Flash trigger
            tapKey(bfKey, 0.05)
            -- Wait for animation to complete
            task.wait(0.30)

            -- Walk behind target for next rep (no CFrame snap)
            if i < reps and getgenv().MoneyHub.Settings.BFAutoClose then
                local newTR = pRoot(target)
                local newMR = getRoot()
                local hum = getHum()
                if newTR and newMR and hum then
                    local closeRange = getgenv().MoneyHub.Settings.BFCloseRange
                    local behindDir = -newTR.CFrame.LookVector
                    local goalPos = newTR.Position + behindDir * closeRange
                    -- Smooth walk, no snap
                    hum:MoveTo(goalPos)
                    -- Face target after walking
                    task.wait(0.08)
                    local currentRoot = getRoot()
                    if currentRoot then
                        currentRoot.CFrame = CFrame.lookAt(
                            Vector3.new(currentRoot.Position.X, currentRoot.Position.Y, currentRoot.Position.Z),
                            Vector3.new(newTR.Position.X, currentRoot.Position.Y, newTR.Position.Z)
                        )
                    end
                end
            end

            -- M1 between reps to maintain hit-stun
            if i < reps then
                clickMouse()
                task.wait(0.04)
            end
        end

        getgenv().MoneyHub.ChainActive = false
        getgenv().MoneyHub.LastBF = tick()
        getgenv().MoneyHub.M1Count = 0
    end)
    return true
end

-- ============================================
-- TECHS (with selected tech support)
-- ============================================
local function applyCharacterTechs()
    if not getgenv().MoneyHub.Settings.AutoTechs then return end
    if getgenv().MoneyHub.ChainActive then return end
    local prof = profile()
    local cd = prof.tech / math.max(getgenv().MoneyHub.Settings.TechFreq, 0.1)
    if tick() - getgenv().MoneyHub.LastTech < cd then return end
    if math.random() > prof.techChance then return end

    local techs = TechLibrary[getgenv().MoneyHub.SelectedChar]
    if not techs or #techs == 0 then return end

    local pick
    -- If user selected a specific tech, use it; otherwise random
    if getgenv().MoneyHub.SelectedTech and getgenv().MoneyHub.SelectedTech ~= "Random" then
        pick = findTech(getgenv().MoneyHub.SelectedChar, getgenv().MoneyHub.SelectedTech)
    end
    if not pick then
        pick = techs[math.random(1, #techs)]
    end

    task.spawn(function() executeTech(pick.seq) end)
    getgenv().MoneyHub.LastTech = tick()
end

local function tryAutoUlt(target, dist)
    if not getgenv().MoneyHub.Settings.AutoUlt then return end
    local settings = getgenv().MoneyHub.Settings
    if tick() - getgenv().MoneyHub.LastUlt < settings.UltCooldown then return end
    local moves = CharMoves[getgenv().MoneyHub.SelectedChar]
    if not moves or not moves.ult then return end
    local tHum = pHum(target); if not tHum or tHum.Health <= 0 then return end
    local myHum = getHum()
    local myRatio = myHum and (myHum.Health / math.max(myHum.MaxHealth,1)) or 1
    local tRatio = tHum.Health / math.max(tHum.MaxHealth,1)
    local shouldUlt = (tRatio <= settings.UltHP and dist <= 22) or (myRatio <= settings.UltMyHP and dist <= 18)
    if shouldUlt then
        task.spawn(function()
            local count = settings.UltSpam and 4 or 2
            for _ = 1, count do tapKey(moves.ult, 0.08); task.wait(0.07) end
            tapKey(moves.ult, 0.18)
        end)
        getgenv().MoneyHub.LastUlt = tick()
    end
end

local function doM1Pressure(dist)
    local clicks = getgenv().MoneyHub.Settings.M1BeforeCombo
    if dist > 9 then clicks = math.min(clicks, 1) end
    local speed = getgenv().MoneyHub.Settings.M1Speed
    for _ = 1, clicks do clickMouse(); task.wait(speed) end
end

-- Anti ragdoll
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().MoneyHub.Settings.AntiRagdoll then
            local hum = getHum()
            if hum then
                pcall(function() hum.PlatformStand = false end)
                local state = hum:GetState()
                if state == Enum.HumanoidStateType.PlatformStanding or state == Enum.HumanoidStateType.Physics then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if getgenv().MoneyHub.Settings.InfJump and getHum() then
        getHum():ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    getgenv().MoneyHub.PreviousHP = 0
    getgenv().MoneyHub.ChainActive = false
    getgenv().MoneyHub.IsBlocking = false
    getgenv().MoneyHub.M1Count = 0
    getgenv().MoneyHub.Deaths += 1
    if getgenv().MoneyHub.Settings.NoClip then task.wait(0.3); enableNoclip() end
end)

-- Player viewer
local function viewPlayer(p)
    if not p or not p.Character then return false end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    getgenv().MoneyHub.Viewing = p
    WS.CurrentCamera.CameraSubject = hum
    return true
end

local function unviewPlayer()
    getgenv().MoneyHub.Viewing = nil
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then WS.CurrentCamera.CameraSubject = hum end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if getgenv().MoneyHub.Viewing then
            if not getgenv().MoneyHub.Viewing.Parent then unviewPlayer()
            elseif getgenv().MoneyHub.Viewing.Character then
                local hum = getgenv().MoneyHub.Viewing.Character:FindFirstChildOfClass("Humanoid")
                if hum and WS.CurrentCamera.CameraSubject ~= hum then
                    WS.CurrentCamera.CameraSubject = hum
                end
            end
        end
    end
end)

-- ===== MAIN AI LOOP =====
RS.Heartbeat:Connect(function()
    if not getgenv().MoneyHub.Enabled then
        if next(getgenv().MoneyHub.KeyState) then clearMoveKeys() end
        if getgenv().MoneyHub.IsBlocking then holdKey(K.F, false); getgenv().MoneyHub.IsBlocking = false end
        return
    end
    local char = getChar(); local root = getRoot(); local hum = getHum()
    if not root or not hum or hum.Health <= 0 then clearMoveKeys(); setBlocking(false); return end
    hum.WalkSpeed = getgenv().MoneyHub.Settings.Speed
    local target = getTarget()
    getgenv().MoneyHub.Target = target
    if not target then clearMoveKeys(); setBlocking(false); return end
    local tRoot = pRoot(target); local tHum = pHum(target)
    if not tRoot or not tHum or tHum.Health <= 0 then clearMoveKeys(); setBlocking(false); return end
    local dist = (root.Position - tRoot.Position).Magnitude

    if getgenv().MoneyHub.Settings.ViewTarget then
        local cam = WS.CurrentCamera
        if cam then cam.CameraSubject = tHum end
    end

    local stunned = isHardStunned(char)
    if stunned and getgenv().MoneyHub.Settings.StrictStun then clearMoveKeys(); setBlocking(false); return end

    if not getgenv().MoneyHub.FleeMode then handleAutoBlock(target) end

    if getgenv().MoneyHub.IsBlocking and (tick() - getgenv().MoneyHub.LastBlock) > getgenv().MoneyHub.Settings.BlockHoldTime + 0.2 then
        setBlocking(false)
    end

    if not getgenv().MoneyHub.IsBlocking and not stunned and not getgenv().MoneyHub.ChainActive then
        doSmartMove(hum, root, tRoot, dist)
    end

    if getgenv().MoneyHub.FleeMode then return end

    tryAutoUlt(target, dist)

    if dist < getgenv().MoneyHub.Settings.AttackRange and not getgenv().MoneyHub.ChainActive and not getgenv().MoneyHub.IsBlocking then
        if tick() - getgenv().MoneyHub.LastAttack > getgenv().MoneyHub.Settings.AttackDelay then
            local hpBefore = tHum.Health
            doM1Pressure(dist)
            getgenv().MoneyHub.ComboStep = (getgenv().MoneyHub.ComboStep % 4) + 1
            local moves = CharMoves[getgenv().MoneyHub.SelectedChar]
            if moves then
                if getgenv().MoneyHub.ComboStep == 3 then tapKeyAsync(moves.skill1)
                elseif getgenv().MoneyHub.ComboStep == 4 then tapKeyAsync(moves.skill2) end
            end
            getgenv().MoneyHub.LastAttack = tick()
            getgenv().MoneyHub.M1Count += 1
            task.delay(0.18, function()
                if tHum and tHum.Parent then
                    if tHum.Health < hpBefore then
                        getgenv().MoneyHub.HitCount = math.min(getgenv().MoneyHub.HitCount + 1, 8)
                        getgenv().MoneyHub.MissCount = math.max(getgenv().MoneyHub.MissCount - 1, 0)
                    else
                        getgenv().MoneyHub.MissCount = math.min(getgenv().MoneyHub.MissCount + 1, 8)
                        getgenv().MoneyHub.HitCount = math.max(getgenv().MoneyHub.HitCount - 1, 0)
                    end
                end
            end)
            if getgenv().MoneyHub.Settings.AutoBFChain and getgenv().MoneyHub.Settings.BFAutoFire
               and getgenv().MoneyHub.SelectedChar == "Vessel"
               and getgenv().MoneyHub.M1Count >= profile().m1chain and profile().useBFChain then
                doBlackFlashChain(target)
            end
            applyCharacterTechs()
        end
    end

    if dist > 14 and getgenv().MoneyHub.Settings.EnableDash then
        local moves = CharMoves[getgenv().MoneyHub.SelectedChar]
        if moves and moves.dash then
            local dashCD = 2.0 - (profile().dashAggro * getgenv().MoneyHub.Settings.DashAggro)
            if tick() - getgenv().MoneyHub.LastDash > dashCD then
                tapKey(moves.dash); getgenv().MoneyHub.LastDash = tick()
            end
        end
    end
end)

-- ============================================
-- RAYFIELD UI
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Dream Hub",
    LoadingTitle = "Dream Hub",
    LoadingSubtitle = "JJS · Dream Hub (Sovereign V14.1)",
    Theme = "Amethyst",
    ConfigurationSaving = {Enabled = false},
})

local MainTab = Window:CreateTab("Combat AI")
local DefTab = Window:CreateTab("Defense")
local LockTab = Window:CreateTab("Lock-On")
local BFTab = Window:CreateTab("BF Chain")
local MovTab = Window:CreateTab("Movement")
local ViewTab = Window:CreateTab("View Player")
local ESPTab = Window:CreateTab("Visuals")
local UltTab = Window:CreateTab("Ultimate")
local StatsTab = Window:CreateTab("Stats")
local MiscTab = Window:CreateTab("Misc")

-- COMBAT AI
MainTab:CreateToggle({Name="Enable AI", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.Enabled = v
    if not v then fullStopAI() end
    Rayfield:Notify({Title = v and "AI ON" or "AI OFF", Content = v and "Bot active" or "Stopped", Duration = 2})
end})

-- Character dropdown
local TechDropdown
MainTab:CreateDropdown({Name="Character", Options=ALL_CHARS, CurrentOption={"Vessel"}, Callback=function(v)
    if type(v) == "table" then v = v[1] end
    getgenv().MoneyHub.SelectedChar = v
    getgenv().MoneyHub.SelectedTech = "Random"
    getgenv().MoneyHub.M1Count = 0
    -- Refresh the tech dropdown with this character's techs
    if TechDropdown then
        pcall(function() TechDropdown:Refresh(getTechNames(v), false) end)
    end
    local techs = TechLibrary[v] or {}
    Rayfield:Notify({Title="Character", Content=v.." ("..#techs.." techs)", Duration=2})
end})

-- TECH PICKER DROPDOWN (NEW FEATURE)
TechDropdown = MainTab:CreateDropdown({
    Name = "Tech to Use",
    Options = getTechNames("Vessel"),
    CurrentOption = {"Random"},
    Callback = function(v)
        if type(v) == "table" then v = v[1] end
        getgenv().MoneyHub.SelectedTech = v
        Rayfield:Notify({Title="Tech", Content="Selected: "..v, Duration=2})
    end,
})

MainTab:CreateButton({Name="Preview Selected Tech", Callback=function()
    local charName = getgenv().MoneyHub.SelectedChar
    local techName = getgenv().MoneyHub.SelectedTech
    if techName == "Random" then
        local techs = TechLibrary[charName] or {}
        if #techs == 0 then return end
        local pick = techs[math.random(1, #techs)]
        task.spawn(function() executeTech(pick.seq) end)
        Rayfield:Notify({Title="Preview", Content="Random: "..pick.name, Duration=2})
    else
        local tech = findTech(charName, techName)
        if tech then
            task.spawn(function() executeTech(tech.seq) end)
            Rayfield:Notify({Title="Preview", Content=techName, Duration=2})
        end
    end
end})

MainTab:CreateDropdown({Name="Difficulty", Options={"Noob","Pro","Good","Expert"}, CurrentOption={"Expert"}, Callback=function(v)
    if type(v) == "table" then v = v[1] end
    getgenv().MoneyHub.Difficulty = v
    local p = getgenv().MoneyHub.Profiles[v]
    if p then
        getgenv().MoneyHub.Settings.AttackDelay = p.attack
        getgenv().MoneyHub.Settings.M1Speed = p.m1Speed
        getgenv().MoneyHub.Settings.M1BeforeCombo = p.m1count
    end
end})

MainTab:CreateToggle({Name="Flee Mode", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.FleeMode = v
    if v then getgenv().MoneyHub.ChainActive = false; setBlocking(false) end
end})

MainTab:CreateToggle({Name="Rage Mode", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.RageMode = v
    if v then
        getgenv().MoneyHub.Settings.AttackDelay = 0.03
        getgenv().MoneyHub.Settings.M1Speed = 0.010
        getgenv().MoneyHub.Settings.DashAggro = 2.0
        getgenv().MoneyHub.Settings.TechFreq = 2.5
        getgenv().MoneyHub.Settings.PreferredDistance = 3.0
    end
end})

MainTab:CreateSection("Attack Tuning")
MainTab:CreateSlider({Name="Attack Delay (s)", Range={0.03,0.50}, Increment=0.01, CurrentValue=0.06, Callback=function(v) getgenv().MoneyHub.Settings.AttackDelay = v end})
MainTab:CreateSlider({Name="Attack Range", Range={5,18}, Increment=0.5, CurrentValue=11, Callback=function(v) getgenv().MoneyHub.Settings.AttackRange = v end})
MainTab:CreateSlider({Name="M1s Before Combo", Range={1,3}, Increment=1, CurrentValue=3, Callback=function(v) getgenv().MoneyHub.Settings.M1BeforeCombo = v end})
MainTab:CreateSlider({Name="M1 Speed (s)", Range={0.01,0.10}, Increment=0.005, CurrentValue=0.022, Callback=function(v) getgenv().MoneyHub.Settings.M1Speed = v end})

MainTab:CreateSection("Techs")
MainTab:CreateToggle({Name="Auto Techs", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.AutoTechs = v end})
MainTab:CreateSlider({Name="Tech Frequency", Range={0.2,3.0}, Increment=0.1, CurrentValue=1.5, Callback=function(v) getgenv().MoneyHub.Settings.TechFreq = v end})
MainTab:CreateToggle({Name="Enable Dash", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.EnableDash = v end})
MainTab:CreateSlider({Name="Dash Aggression", Range={0.1,2.0}, Increment=0.1, CurrentValue=1.2, Callback=function(v) getgenv().MoneyHub.Settings.DashAggro = v end})

MainTab:CreateButton({Name="Show Tech List (F9)", Callback=function()
    local techs = TechLibrary[getgenv().MoneyHub.SelectedChar] or {}
    print("=== "..getgenv().MoneyHub.SelectedChar.." TECHS ===")
    for i, t in ipairs(techs) do print("  "..i..". "..t.name) end
    print("=== "..#techs.." techs ===")
end})

-- DEFENSE
DefTab:CreateSection("Auto Block")
DefTab:CreateToggle({Name="Auto Block", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.Settings.AutoBlock = v
    if not v then setBlocking(false) end
end})
DefTab:CreateToggle({Name="Auto Feint Cancel", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.AutoFeint = v end})
DefTab:CreateToggle({Name="Auto Dodge Heavy", CurrentValue=false, Callback=function(v) getgenv().MoneyHub.Settings.AutoDodge = v end})
DefTab:CreateToggle({Name="Parry Mode", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.ParryMode = v end})
DefTab:CreateSlider({Name="Block Hold (s)", Range={0.15,1.0}, Increment=0.05, CurrentValue=0.45, Callback=function(v) getgenv().MoneyHub.Settings.BlockHoldTime = v end})

DefTab:CreateSection("TBO")
DefTab:CreateToggle({Name="Use TBO for Block", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.Settings.UseTBOBlock = v
    if v and not getgenv().MoneyHub.TBOLoaded then
        task.spawn(function() loadTBO(getgenv().MoneyHub.Settings.HideTBOGui) end)
    end
end})
DefTab:CreateToggle({Name="Hide TBO GUI", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.HideTBOGui = v end})
DefTab:CreateButton({Name="Force Load TBO", Callback=function()
    task.spawn(function()
        local ok = loadTBO(getgenv().MoneyHub.Settings.HideTBOGui)
        Rayfield:Notify({Title="TBO", Content=ok and "Loaded" or "Failed", Duration=3})
    end)
end})

DefTab:CreateSection("Other")
DefTab:CreateToggle({Name="Strict Stun", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.StrictStun = v end})
DefTab:CreateToggle({Name="Anti-Ragdoll", CurrentValue=false, Callback=function(v) getgenv().MoneyHub.Settings.AntiRagdoll = v end})

DefTab:CreateSection("Anim Debug")
DefTab:CreateToggle({Name="Log Enemy Animations", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.LogAnims = v
    if v then getgenv().MoneyHub.LoggedAnims = {} end
end})
DefTab:CreateButton({Name="Dump Anims to F9", Callback=function()
    print("=== LOGGED ANIMS ===")
    local list = {}
    for name, count in pairs(getgenv().MoneyHub.LoggedAnims) do
        table.insert(list, {name=name, count=count})
    end
    table.sort(list, function(a,b) return a.count > b.count end)
    for _, e in ipairs(list) do print(e.count.."x  "..e.name) end
    print("=== "..#list.." unique ===")
end})

-- LOCK-ON (improved)
LockTab:CreateSection("Main Controls")
LockTab:CreateToggle({Name="Enable Lock-On", CurrentValue=true, Callback=function(v)
    getgenv().MoneyHub.Settings.LockOnEnabled = v
    if not v then getgenv().MoneyHub.LockHard = false; getgenv().MoneyHub.LockedTarget = nil end
end})
LockTab:CreateToggle({Name="Camera Rotates to Target", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.LockCamera = v end})
LockTab:CreateSlider({Name="Camera Smoothness", Range={5,100}, Increment=5, CurrentValue=35, Suffix="%", Callback=function(v) getgenv().MoneyHub.Settings.LockSmoothness = v / 100 end})
LockTab:CreateToggle({Name="Ignore Others (STRICT)", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.IgnoreOthers = v end})
LockTab:CreateToggle({Name="Auto Lock On Damage", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.AutoLockOnDamage = v end})

LockTab:CreateSection("Keybind")
LockTab:CreateDropdown({Name="Lock-On Key", Options={"L","X","C","V","B","T","Y","Z","H","J","K","N","M"}, CurrentOption={"L"}, Callback=function(v)
    if type(v) == "table" then v = v[1] end
    local map = {L=Enum.KeyCode.L,X=Enum.KeyCode.X,C=Enum.KeyCode.C,V=Enum.KeyCode.V,B=Enum.KeyCode.B,T=Enum.KeyCode.T,Y=Enum.KeyCode.Y,Z=Enum.KeyCode.Z,H=Enum.KeyCode.H,J=Enum.KeyCode.J,K=Enum.KeyCode.K,N=Enum.KeyCode.N,M=Enum.KeyCode.M}
    getgenv().MoneyHub.Settings.LockKey = map[v] or Enum.KeyCode.L
end})
LockTab:CreateDropdown({Name="Target Mode", Options={"Nearest","Crosshair"}, CurrentOption={"Nearest"}, Callback=function(v)
    if type(v) == "table" then v = v[1] end
    getgenv().MoneyHub.Settings.LockMode = v
end})

LockTab:CreateSection("Lock Specific Player")
local bindQuery = ""
LockTab:CreateInput({Name="Player Name", PlaceholderText="Username/display", RemoveTextAfterFocusLost=false, Callback=function(t) bindQuery = t end})
LockTab:CreateButton({Name="Lock This Player", Callback=function()
    if bindQuery == "" then return end
    local q = bindQuery:lower():gsub("^@","")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower() == q or p.DisplayName:lower() == q
               or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
                getgenv().MoneyHub.LockHard = true
                getgenv().MoneyHub.LockedTarget = p
                Rayfield:Notify({Title="Locked", Content=p.DisplayName, Duration=2})
                return
            end
        end
    end
    Rayfield:Notify({Title="Not Found", Content=bindQuery, Duration=2})
end})

LockTab:CreateSection("Actions")
LockTab:CreateButton({Name="Lock Nearest Now", Callback=function()
    local t = acquireLockTarget()
    if t then
        getgenv().MoneyHub.LockHard = true
        getgenv().MoneyHub.LockedTarget = t
        Rayfield:Notify({Title="Locked", Content=t.DisplayName, Duration=2})
    end
end})
LockTab:CreateButton({Name="Release Lock", Callback=function()
    getgenv().MoneyHub.LockHard = false
    getgenv().MoneyHub.LockedTarget = nil
end})

-- BF CHAIN
BFTab:CreateSection("Built-in BF Chain")
BFTab:CreateToggle({Name="Auto BF Chain", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.AutoBFChain = v end})
BFTab:CreateToggle({Name="Fire in Combat Auto", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.BFAutoFire = v end})
BFTab:CreateSlider({Name="Chain Reps", Range={1,6}, Increment=1, CurrentValue=4, Callback=function(v) getgenv().MoneyHub.Settings.BFChainReps = v end})
BFTab:CreateSlider({Name="Golden Window (s)", Range={0.15,0.40}, Increment=0.01, CurrentValue=0.28, Callback=function(v) getgenv().MoneyHub.Settings.BFGoldenWindow = v end})
BFTab:CreateToggle({Name="Walk Behind Target", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.BFAutoClose = v end})
BFTab:CreateSlider({Name="Close Range", Range={2,10}, Increment=0.5, CurrentValue=4, Callback=function(v) getgenv().MoneyHub.Settings.BFCloseRange = v end})

BFTab:CreateSection("External Drakkiosauro Loader")
BFTab:CreateToggle({Name="Use Drakkiosauro Gist", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.Settings.BFUseLoader = v
    if v and not getgenv().MoneyHub.BFLoaded then task.spawn(loadBFLoader) end
end})
BFTab:CreateButton({Name="Force Load BF Gist", Callback=function()
    task.spawn(function()
        local ok = loadBFLoader()
        Rayfield:Notify({Title="BF Loader", Content=ok and "Loaded" or "Failed", Duration=3})
    end)
end})
BFTab:CreateButton({Name="Dump BF Functions to F9", Callback=function()
    print("=== BF LOADER FUNCTIONS ===")
    local count = 0
    for name, fn in pairs(BFLoaderGlobals) do
        print("  "..name.." ("..type(fn)..")")
        count = count + 1
    end
    print("=== "..count.." total ===")
    Rayfield:Notify({Title="BF Functions", Content=count.." found (F9)", Duration=3})
end})

BFTab:CreateSection("Manual Trigger")
BFTab:CreateButton({Name="TRIGGER BF CHAIN NOW", Callback=function()
    local target = getgenv().MoneyHub.LockedTarget or getNearest()
    if not target then Rayfield:Notify({Title="BF", Content="No target", Duration=2}); return end
    getgenv().MoneyHub.LastBF = 0
    local ok = doBlackFlashChain(target)
    Rayfield:Notify({Title="BF", Content=ok and ("Triggered on "..target.DisplayName) or "Failed", Duration=2})
end})

-- MOVEMENT
MovTab:CreateDropdown({Name="Movement Style", Options={"Kimbaap","Circle","Orbital","Pro","Aggro","Straight"}, CurrentOption={"Kimbaap"}, Callback=function(v)
    if type(v) == "table" then v = v[1] end
    getgenv().MoneyHub.MovementStyle = v
end})
MovTab:CreateLabel("All styles now forward-only, no backing up")

MovTab:CreateSlider({Name="Walk Speed", Range={16,60}, Increment=1, CurrentValue=24, Callback=function(v)
    getgenv().MoneyHub.Settings.Speed = v
    local h = getHum() if h then h.WalkSpeed = v end
end})
MovTab:CreateSlider({Name="Preferred Distance", Range={2,12}, Increment=0.5, CurrentValue=4.0, Callback=function(v) getgenv().MoneyHub.Settings.PreferredDistance = v end})
MovTab:CreateSlider({Name="Strafe Amplitude", Range={1,10}, Increment=0.5, CurrentValue=4.0, Callback=function(v) getgenv().MoneyHub.Settings.StrafeAmplitude = v end})
MovTab:CreateSlider({Name="Strafe Frequency", Range={0.5,12}, Increment=0.5, CurrentValue=5.5, Callback=function(v) getgenv().MoneyHub.Settings.StrafeFrequency = v end})
MovTab:CreateToggle({Name="Auto Jump", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.AutoJump = v end})
MovTab:CreateToggle({Name="Wall Check Jump", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.WallCheck = v end})
MovTab:CreateSlider({Name="Jump Power", Range={15,80}, Increment=1, CurrentValue=30, Callback=function(v) getgenv().MoneyHub.Settings.JumpPower = v end})
MovTab:CreateSlider({Name="Jump Cooldown (s)", Range={0.3,3.0}, Increment=0.1, CurrentValue=1.2, Callback=function(v) getgenv().MoneyHub.Settings.JumpCooldown = v end})

-- VIEW PLAYER
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.DisplayName.." (@"..p.Name..")") end
    end
    table.sort(list)
    if #list == 0 then table.insert(list, "No players") end
    return list
end

local ViewDropdown = ViewTab:CreateDropdown({Name="Player List", Options=getPlayerList(), CurrentOption={}, Flag="ViewDropdown", Callback=function() end})
ViewTab:CreateButton({Name="Refresh", Callback=function() ViewDropdown:Refresh(getPlayerList()) end})
ViewTab:CreateButton({Name="View Selected", Callback=function()
    local sel
    pcall(function()
        if Rayfield.Flags and Rayfield.Flags.ViewDropdown then
            local v = Rayfield.Flags.ViewDropdown.CurrentOption
            sel = type(v) == "table" and v[1] or v
        end
    end)
    if not sel or sel == "" or sel == "No players" then return end
    local username = sel:match("@(.+)%)$")
    if username then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == username then
                if viewPlayer(p) then Rayfield:Notify({Title="Viewing", Content=p.DisplayName, Duration=2}) end
                return
            end
        end
    end
end})

local viewSearchQuery = ""
ViewTab:CreateInput({Name="Search", PlaceholderText="Name/UserID", RemoveTextAfterFocusLost=false, Callback=function(t) viewSearchQuery = t end})
ViewTab:CreateButton({Name="View by Search", Callback=function()
    if viewSearchQuery == "" then return end
    local q = viewSearchQuery:lower():gsub("^@","")
    local asNum = tonumber(q)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if (asNum and p.UserId == asNum) or p.Name:lower() == q or p.DisplayName:lower() == q
           or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
            if viewPlayer(p) then Rayfield:Notify({Title="Viewing", Content=p.DisplayName, Duration=2}) end
            return
        end
    end
end})
ViewTab:CreateButton({Name="Next Player", Callback=function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(list, p) end end
    if #list == 0 then return end
    local idx = 0
    if getgenv().MoneyHub.Viewing then
        for i, p in ipairs(list) do if p == getgenv().MoneyHub.Viewing then idx = i; break end end
    end
    local n = list[(idx % #list) + 1]
    if viewPlayer(n) then Rayfield:Notify({Title="Viewing", Content=n.DisplayName, Duration=2}) end
end})
ViewTab:CreateButton({Name="Previous Player", Callback=function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(list, p) end end
    if #list == 0 then return end
    local idx = 1
    if getgenv().MoneyHub.Viewing then
        for i, p in ipairs(list) do if p == getgenv().MoneyHub.Viewing then idx = i; break end end
    end
    local prev = idx - 1
    if prev < 1 then prev = #list end
    if viewPlayer(list[prev]) then Rayfield:Notify({Title="Viewing", Content=list[prev].DisplayName, Duration=2}) end
end})
ViewTab:CreateButton({Name="Go Back to Me", Callback=function() unviewPlayer() end})

Players.PlayerAdded:Connect(function() task.wait(0.5); pcall(function() ViewDropdown:Refresh(getPlayerList()) end) end)
Players.PlayerRemoving:Connect(function(p)
    if getgenv().MoneyHub.Viewing == p then unviewPlayer() end
    if getgenv().MoneyHub.LockedTarget == p then
        getgenv().MoneyHub.LockedTarget = nil
        getgenv().MoneyHub.LockHard = false
    end
    task.wait(0.5); pcall(function() ViewDropdown:Refresh(getPlayerList()) end)
end)

-- VISUALS
ESPTab:CreateToggle({Name="Player ESP", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.Settings.ESP = v
    if not v then clearAllESP() end
end})
ESPTab:CreateToggle({Name="Rainbow ESP", CurrentValue=false, Callback=function(v) getgenv().MoneyHub.Settings.RainbowESP = v; if v then getgenv().MoneyHub.Settings.ESP = true end end})
ESPTab:CreateToggle({Name="Show Locked Target Highlight", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.ShowLockedTarget = v end})
ESPTab:CreateToggle({Name="Show Health + Distance", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.ShowHealth = v end})
ESPTab:CreateButton({Name="Clear ESP", Callback=clearAllESP})
ESPTab:CreateButton({Name="Fullbright", Callback=function()
    pcall(function()
        local L = game:GetService("Lighting")
        L.Brightness = 3; L.ClockTime = 12; L.FogEnd = 999999; L.GlobalShadows = false
        for _, v in ipairs(L:GetDescendants()) do
            if v:IsA("Atmosphere") then v.Density = 0 end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then v.Enabled = false end
        end
    end)
end})

-- ULTIMATE
UltTab:CreateToggle({Name="Auto Ult", CurrentValue=false, Callback=function(v) getgenv().MoneyHub.Settings.AutoUlt = v end})
UltTab:CreateToggle({Name="Ult Spam", CurrentValue=true, Callback=function(v) getgenv().MoneyHub.Settings.UltSpam = v end})
UltTab:CreateSlider({Name="Enemy HP% to Ult", Range={20,100}, Increment=5, CurrentValue=55, Suffix="%", Callback=function(v) getgenv().MoneyHub.Settings.UltHP = v / 100 end})
UltTab:CreateSlider({Name="My HP% Emergency", Range={5,80}, Increment=5, CurrentValue=35, Suffix="%", Callback=function(v) getgenv().MoneyHub.Settings.UltMyHP = v / 100 end})
UltTab:CreateSlider({Name="Ult Cooldown (s)", Range={1,10}, Increment=0.5, CurrentValue=2.5, Callback=function(v) getgenv().MoneyHub.Settings.UltCooldown = v end})

-- STATS
StatsTab:CreateButton({Name="Print Stats to F9", Callback=function()
    local s = getgenv().MoneyHub
    local uptime = tick() - s.SessionStart
    print("========================================")
    print("MONEY/FREE HUB STATS")
    print("========================================")
    print("Uptime: "..math.floor(uptime).."s")
    print("Kills: "..s.Kills.."  Deaths: "..s.Deaths)
    print("K/D: "..(s.Deaths > 0 and string.format("%.2f", s.Kills/s.Deaths) or tostring(s.Kills)))
    print("Damage Dealt: "..math.floor(s.TotalDamageDealt))
    print("Damage Taken: "..math.floor(s.TotalDamageTaken))
    print("Character: "..s.SelectedChar)
    print("Tech: "..s.SelectedTech)
    print("Difficulty: "..s.Difficulty)
    print("========================================")
end})
StatsTab:CreateButton({Name="Reset Stats", Callback=function()
    getgenv().MoneyHub.Kills = 0
    getgenv().MoneyHub.Deaths = 0
    getgenv().MoneyHub.TotalDamageDealt = 0
    getgenv().MoneyHub.TotalDamageTaken = 0
    getgenv().MoneyHub.SessionStart = tick()
end})

-- MISC
MiscTab:CreateToggle({Name="NoClip (best effort)", CurrentValue=false, Callback=function(v)
    getgenv().MoneyHub.Settings.NoClip = v
    if v then enableNoclip() end
end})
MiscTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Callback=function(v) getgenv().MoneyHub.Settings.InfJump = v end})
MiscTab:CreateButton({Name="Stop All + Reset", Callback=function()
    getgenv().MoneyHub.Enabled = false
    fullStopAI()
    clearAllESP()
end})
MiscTab:CreateButton({Name="Rejoin", Callback=function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end) end})
MiscTab:CreateButton({Name="Server Hop", Callback=function()
    pcall(function()
        local HS = game:GetService("HttpService")
        local data = HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=10"))
        if data and data.data then
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id, LP); break
                end
            end
        end
    end)
end})

Rayfield:Notify({Title="V14.1", Content="Forward movement | Tech picker | Clean BF", Duration=5})
print("[Money/Free Hub V14.1] Loaded")