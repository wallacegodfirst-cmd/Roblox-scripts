-- Money/Free Hub | Age of Titans | v3.6

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local TeleportService   = game:GetService("TeleportService")

local player = Players.LocalPlayer
local UIS    = UserInputService

-- ── Theme ──────────────────────────────────────────────────────────────────
local T = {
    bg       = Color3.fromRGB(17,  18,  22),
    titlebar = Color3.fromRGB(24,  25,  30),
    card     = Color3.fromRGB(20,  21,  26),
    cardhead = Color3.fromRGB(26,  27,  33),
    input    = Color3.fromRGB(28,  29,  35),
    tabsel   = Color3.fromRGB(31,  33,  40),
    border   = Color3.fromRGB(50,  53,  62),
    outline  = Color3.fromRGB(86,  91,  103),
    accent   = Color3.fromRGB(64,  110, 200),
    text     = Color3.fromRGB(206, 210, 219),
    dim      = Color3.fromRGB(120, 125, 138),
}

local ACCENT_PRESETS = {
    Color3.fromRGB(64,  110, 200),
    Color3.fromRGB(190, 70,  70),
    Color3.fromRGB(80,  180, 100),
    Color3.fromRGB(200, 150, 60),
    Color3.fromRGB(140, 80,  200),
    Color3.fromRGB(60,  185, 190),
    Color3.fromRGB(200, 80,  150),
    Color3.fromRGB(200, 200, 200),
}

local FONTS      = {Enum.Font.Code, Enum.Font.RobotoMono, Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.SourceSans}
local FONT_NAMES = {"Code","RobotoMono","Gotham","GothamBold","SourceSans"}
local CurFont    = Enum.Font.Code

local allTextObjs   = {}
local accentFrames  = {}
local accentStrokes = {}
local scrollFrames  = {}

local function refreshTheme()
    for _, pr in pairs(allTextObjs) do
        pcall(function()
            local role = pr[2]
            if     role == "accent" then pr[1].TextColor3 = T.accent
            elseif role == "dim"    then pr[1].TextColor3 = T.dim
            elseif role == "tab"    then -- managed by setTab
            else                         pr[1].TextColor3 = T.text end
            pr[1].Font = CurFont
        end)
    end
    for _, f  in pairs(accentFrames)  do pcall(function() f.BackgroundColor3       = T.accent end) end
    for _, s  in pairs(accentStrokes) do pcall(function() s.Color                  = T.accent end) end
    for _, sf in pairs(scrollFrames)  do pcall(function() sf.ScrollBarImageColor3  = T.accent end) end
end

-- ── State ──────────────────────────────────────────────────────────────────
local S = {
    ExtendHitbox     = false,
    HitboxSize       = 15,
    ShowHitbox       = false,
    M1Expand         = false,
    M1Size           = 8,
    ShowExpand       = false,
    InfBlock         = false,
    AutoBlock        = false,
    SilentAim        = false,
    AutoUlt          = false,
    Fly              = false,
    FlySpeed         = 80,
    Noclip           = false,
    SpeedHack        = false,
    WalkSpeed        = 50,
    AutoSprint       = false,
    NoStun           = false,
    GodMode          = false,
    SaveSystem       = false,
    SaveThreshold    = 30,
    InstantRespawn   = false,
    Invisible        = false,
    AutoFarm         = false,
    AutoFarmRange    = 80,
    ESP              = false,
    InfZoom          = false,
    BypassCooldown   = false,
    AntiAFK          = false,
    Fullbright       = false,
    InfJump          = false,
    ClickTP          = false,
    Spinbot          = false,
    HideNames        = false,
    AntiFling        = false,
    Minimized        = false,
    ToggleKey        = Enum.KeyCode.RightShift,
}

local speedOriginal   = nil
local speedStateLast  = false
local godOrigMax      = nil
local godStateLast    = false
local invisOrigTrans  = {}
local invisStateLast  = false
local ultClock        = 0
local ultWasFull      = false
local farmClock       = 0
local cdClock         = 0
local espClock        = 0
local fbClock         = 0
local hnClock         = 0
local blockClock      = 0
local blockHoldEnd    = 0
local blockHolding    = false
local respawnClock    = 0
local saveActive      = false
local saveClock       = 0
local savePos         = Vector3.zero
local espBoxes        = {}
local showHitboxBoxes = {}
local showHitboxLast  = false
local autoBlockConns  = {}
local origZoom        = nil
local Connections     = {}
local flyBV           = nil
local flyBG           = nil
local flyStateLast    = false
local noclipLast      = false
local spinAngle       = 0
local expandPart      = nil
local expandBox       = nil

-- Attack key names stored on enemy Player objects (player.Keybinds.Attack1 etc.)
local AB_KEYS      = {"Attack1","Attack2","Attack3","Attack4","Attack5","Lc1","Lc2","Lc3"}
local AB_HOLD_TIME = 2.0   -- seconds to hold block after detecting an enemy attack

-- ── Helpers ────────────────────────────────────────────────────────────────
local function chr() return player.Character end
local function hum() local c = chr(); return c and c:FindFirstChildOfClass("Humanoid") end
-- Character is a MODEL (Kaiju), not always a standard Humanoid rig — fall back
-- to the PrimaryPart / any BasePart so movement features still work.
local function hrp()
    local c = chr(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end

-- RemoteEvent lives INSIDE the character: LocalPlayer.Character.RemoteEvent
local function re()
    local c = chr()
    if c then
        local r = c:FindFirstChild("RemoteEvent")
        if r and r:IsA("RemoteEvent") then return r end
    end
    local rs = game:GetService("ReplicatedStorage")
    return rs:FindFirstChild("RemoteEvent") or rs:FindFirstChildWhichIsA("RemoteEvent")
end

-- PlayerGui.GameplayInterface.Moveset — holds Attack1..Attack5, each with a
-- .Cooldown frame (used by Bypass Cooldown, no full-descendant scan = no lag).
local function moveset()
    local pg = player:FindFirstChild("PlayerGui"); if not pg then return nil end
    local gi = pg:FindFirstChild("GameplayInterface"); if not gi then return nil end
    return gi:FindFirstChild("Moveset")
end
local function gameplayUI()
    local pg = player:FindFirstChild("PlayerGui"); if not pg then return nil end
    return pg:FindFirstChild("GameplayInterface")
end

local function diedRemote()
    local rs  = game:GetService("ReplicatedStorage")
    local rem = rs:FindFirstChild("Remotes")
    return rem and rem:FindFirstChild("Died")
end

local function nearest(maxD)
    local best, dist = nil, maxD or math.huge
    local mh = hrp(); if not mh then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local ph = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            if ph then
                local d = (ph.Position - mh.Position).Magnitude
                if d < dist then best, dist = p, d end
            end
        end
    end
    return best
end

local function pressBlockFor(t)
    blockHoldEnd = math.max(blockHoldEnd, tick() + t)
end

-- ── Fly (Model-safe) ─────────────────────────────────────────────────────────
-- No Humanoid/PlatformStand reliance. BodyVelocity drives movement, BodyGyro
-- keeps the body from tumbling. Works on a Model whose root is just a BasePart.
local function startFly()
    local mh = hrp(); if not mh then return end
    local h  = hum()
    if h then pcall(function() h.PlatformStand = true end) end
    if flyBV then pcall(function() flyBV:Destroy() end) end
    if flyBG then pcall(function() flyBG:Destroy() end) end
    flyBV          = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1, 1, 1) * 1e7
    flyBV.Velocity = Vector3.zero
    flyBV.Parent   = mh
    flyBG          = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1, 1, 1) * 1e7
    flyBG.P        = 12000
    flyBG.D        = 600
    flyBG.CFrame   = mh.CFrame
    flyBG.Parent   = mh
end

local function stopFly()
    local h = hum()
    if h then pcall(function() h.PlatformStand = false end) end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
end

-- ── Block (hold F to block; BlockStop remote ends the block) ──────────────────
local function blockKey(down)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(down, Enum.KeyCode.F, false, game)
    end)
end
local function blockStop()
    local r = re(); if r then pcall(function() r:FireServer("BlockStop") end) end
end

-- ── Hitbox: fire Attack{N}Hitbox with a large value to extend reach ──────────
-- The attack itself is the game's own remote (fired when you press the key);
-- we only fire the matching Hitbox remote, repeatedly across the swing window
-- so it lands while the active frames are live.
local function spamHitbox(name, value, count, gap)
    task.spawn(function()
        for _ = 1, (count or 6) do
            local r = re()
            if r then pcall(function() r:FireServer(name, value) end) end
            task.wait(gap or 0.05)
        end
    end)
end

-- ── M1 Expand visual ─────────────────────────────────────────────────────────
local function ensureExpandVisual()
    local mh = hrp(); if not mh then return end
    if not expandPart or expandPart.Parent == nil then
        expandPart = Instance.new("Part")
        expandPart.Shape       = Enum.PartType.Ball
        expandPart.Anchored    = false
        expandPart.CanCollide  = false
        expandPart.CanQuery    = false
        expandPart.CanTouch    = false
        expandPart.Massless    = true
        expandPart.Transparency= 1
        expandPart.CFrame      = mh.CFrame
        expandPart.Parent      = mh.Parent
        local w = Instance.new("Weld")
        w.Part0  = mh
        w.Part1  = expandPart
        w.Parent = expandPart
        expandBox = Instance.new("SelectionBox")
        expandBox.Adornee            = expandPart
        expandBox.Color3             = T.accent
        expandBox.SurfaceColor3      = T.accent
        expandBox.SurfaceTransparency= 0.85
        expandBox.LineThickness      = 0.03
        expandBox.Parent             = gui
    end
    local sz = S.M1Size * 2
    expandPart.Size = Vector3.new(sz, sz, sz)
    expandBox.Color3        = T.accent
    expandBox.SurfaceColor3 = T.accent
end
local function destroyExpandVisual()
    if expandBox  then pcall(function() expandBox:Destroy() end);  expandBox  = nil end
    if expandPart then pcall(function() expandPart:Destroy() end); expandPart = nil end
end

-- ── Ult detection (scoped to GameplayInterface so it's cheap) ─────────────────
local ULT_KEYS = {"ult","charge","energy","special","rage","meter","super","fury","awaken","transform"}
local function nameMatchesUlt(n)
    n = tostring(n):lower()
    for _, k in ipairs(ULT_KEYS) do if n:find(k) then return true end end
    return false
end
local function barIsFull(frame)
    -- a "bar" is full when its scale on its dominant axis is ~1
    local sx, sy = frame.Size.X.Scale, frame.Size.Y.Scale
    if sx >= 0.97 and sx >= sy then return true end
    if sy >= 0.97 and sy >  sx then return true end
    return false
end
local function ultIsFull()
    local gi = gameplayUI(); if not gi then return false end
    for _, d in ipairs(gi:GetDescendants()) do
        if d:IsA("Frame") and nameMatchesUlt(d.Name) then
            -- the container, or a child fill bar inside it
            for _, c in ipairs(d:GetChildren()) do
                if c:IsA("Frame") or c:IsA("ImageLabel") then
                    local cn = c.Name:lower()
                    if (cn:find("fill") or cn:find("bar") or cn:find("progress") or cn:find("amount"))
                       and barIsFull(c) then
                        return true
                    end
                end
            end
        end
    end
    -- attribute fallback on character/player
    for _, root in ipairs({chr(), player}) do
        if root then
            local ok = false
            pcall(function()
                for attr, v in pairs(root:GetAttributes()) do
                    if type(v) == "number" and nameMatchesUlt(attr) then
                        local maxV = root:GetAttribute("Max"..attr) or root:GetAttribute(attr.."Max")
                        if type(maxV) == "number" and maxV > 0 and v >= maxV - 0.01 then ok = true end
                    end
                end
            end)
            if ok then return true end
        end
    end
    return false
end

-- ── GUI root ───────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "MoneyFreeHub"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder   = 999
gui.Parent         = (gethui and gethui()) or game:GetService("CoreGui")

local function make(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function stroke(parent, color, thick)
    return make("UIStroke", {Color = color or T.border, Thickness = thick or 1}, parent)
end

local WIN_W, WIN_H = 560, 430
local TITLE_H, TAB_H = 26, 30

local main = make("Frame", {
    Size             = UDim2.new(0, WIN_W, 0, WIN_H),
    Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = T.bg,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 5)}, main)
stroke(main, T.outline, 1)

local titleBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundColor3 = T.titlebar, BorderSizePixel = 0,
}, main)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = T.border, BorderSizePixel = 0,
}, titleBar)

local titleLbl = make("TextLabel", {
    Text = "Money/Free Hub", TextSize = 12, TextColor3 = T.text, Font = CurFont,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 9, 0, 0), Size = UDim2.new(1, -70, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)
table.insert(allTextObjs, {titleLbl, "normal"})

local minBtn = make("TextButton", {
    Text = "-", TextSize = 16, TextColor3 = T.dim, Font = CurFont,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -44, 0, 0), Size = UDim2.new(0, 22, 1, 0),
}, titleBar)
local closeBtn = make("TextButton", {
    Text = "x", TextSize = 14, TextColor3 = T.dim, Font = CurFont,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 22, 1, 0),
}, titleBar)

local content = make("Frame", {
    Size = UDim2.new(1, 0, 1, -TITLE_H), Position = UDim2.new(0, 0, 0, TITLE_H),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, main)

local tabBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, TAB_H), BackgroundColor3 = T.bg, BorderSizePixel = 0,
}, content)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = T.border, BorderSizePixel = 0,
}, tabBar)
local tabRow = make("Frame", {
    Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, tabBar)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, tabRow)

local pageArea = make("Frame", {
    Size = UDim2.new(1, 0, 1, -TAB_H), Position = UDim2.new(0, 0, 0, TAB_H),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, content)

local TAB_NAMES = {"Combat","Player","Visuals","Misc","Teleports","Settings"}
local tabBtns   = {}
local pages     = {}

-- Square boxed tabs (Money Hub style) on the same dark format.
local function makeTabBtn(name)
    local btn = make("TextButton", {
        Text = name, TextSize = 11, TextColor3 = T.dim, Font = CurFont,
        BackgroundColor3 = T.tabsel, BackgroundTransparency = 1,
        Size = UDim2.new(0, 84, 0, 21), AutoButtonColor = false,
    }, tabRow)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, btn)
    local st = stroke(btn, T.border)
    st.Transparency = 1
    table.insert(allTextObjs, {btn, "tab"})
    return btn, st
end

local function makePage()
    local page = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false,
    }, pageArea)
    local function col(xScale, xOff)
        local c = make("ScrollingFrame", {
            Size = UDim2.new(0.5, -10, 1, -12), Position = UDim2.new(xScale, xOff, 0, 6),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, page)
        table.insert(scrollFrames, c)
        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        }, c)
        return c
    end
    return {page = page, left = col(0, 6), right = col(0.5, 4)}
end

for _, name in pairs(TAB_NAMES) do
    local btn, st = makeTabBtn(name)
    tabBtns[name] = {btn = btn, st = st}
    pages[name]   = makePage()
end

local function setTab(name)
    for n, d in pairs(tabBtns) do
        local sel = (n == name)
        d.btn.TextColor3            = sel and T.text or T.dim
        d.btn.BackgroundTransparency= sel and 0 or 1
        d.st.Transparency           = sel and 0 or 1
        pcall(function() pages[n].page.Visible = sel end)
    end
end
for _, name in pairs(TAB_NAMES) do
    tabBtns[name].btn.MouseButton1Click:Connect(function() setTab(name) end)
end

-- ── Widget builders ────────────────────────────────────────────────────────
local function makeGroup(col, title)
    local frame = make("Frame", {
        BackgroundColor3 = T.card, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = false,
    }, col)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, frame)
    stroke(frame, T.border)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0),
    }, frame)

    local al = make("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.accent,
        BorderSizePixel = 0, LayoutOrder = 0,
    }, frame)
    table.insert(accentFrames, al)

    local head = make("Frame", {
        Size = UDim2.new(1, 0, 0, 19), BackgroundColor3 = T.cardhead,
        BorderSizePixel = 0, LayoutOrder = 1,
    }, frame)
    make("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.border, BorderSizePixel = 0,
    }, head)
    local htxt = make("TextLabel", {
        Text = title, TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
    }, head)
    table.insert(allTextObjs, {htxt, "normal"})

    local inner = make("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = 2,
    }, frame)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder,
    }, inner)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
    }, inner)
    return inner
end

local function makeCheck(parent, label, key, cb, hasConfig, cfgCb)
    local row = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 17), BorderSizePixel = 0,
    }, parent)
    local box = make("Frame", {
        Size = UDim2.new(0, 13, 0, 13), Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = T.input, BorderSizePixel = 0,
    }, row)
    make("UICorner", {CornerRadius = UDim.new(0, 2)}, box)
    stroke(box, T.border)
    local fill = make("Frame", {
        Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = T.accent, BorderSizePixel = 0, Visible = S[key],
    }, box)
    make("UICorner", {CornerRadius = UDim.new(0, 1)}, fill)
    table.insert(accentFrames, fill)
    local lbl = make("TextLabel", {
        Text = label, TextSize = 12, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -50, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    table.insert(allTextObjs, {lbl, "normal"})
    if hasConfig then
        local cfg = make("TextButton", {
            Text = "...", TextSize = 12, TextColor3 = T.dim, Font = CurFont,
            BackgroundColor3 = T.input, Size = UDim2.new(0, 26, 0, 15),
            Position = UDim2.new(1, -26, 0.5, -7), AutoButtonColor = false,
        }, row)
        make("UICorner", {CornerRadius = UDim.new(0, 2)}, cfg)
        stroke(cfg, T.border)
        table.insert(allTextObjs, {cfg, "dim"})
        if cfgCb then cfg.MouseButton1Click:Connect(cfgCb) end
    end
    local btn = make("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, hasConfig and -30 or 0, 1, 0), ZIndex = 2,
    }, row)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        fill.Visible = S[key]
        if cb then cb(S[key]) end
    end)
    return row
end

local function makeSlider(parent, label, key, minV, maxV, suffix)
    suffix = suffix or ""
    local row = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0,
    }, parent)
    local lbl = make("TextLabel", {
        Text = label, TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 13),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    table.insert(allTextObjs, {lbl, "normal"})
    local bar = make("Frame", {
        BackgroundColor3 = T.input, Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 16), BorderSizePixel = 0,
    }, row)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, bar)
    stroke(bar, T.border)
    local pct  = math.clamp((S[key] - minV) / (maxV - minV), 0, 1)
    local fill = make("Frame", {
        BackgroundColor3 = T.accent, Size = UDim2.new(pct, 0, 1, 0), BorderSizePixel = 0,
    }, bar)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, fill)
    table.insert(accentFrames, fill)
    local val = make("TextLabel", {
        Text = tostring(S[key]) .. suffix, TextSize = 10, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
    }, bar)
    table.insert(allTextObjs, {val, "normal"})
    local dragging = false
    local function set(px)
        local np  = math.clamp((px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v   = math.floor(minV + (maxV - minV) * np + 0.5)
        S[key]    = v
        fill.Size = UDim2.new(np, 0, 1, 0)
        val.Text  = tostring(v) .. suffix
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; set(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then set(i.Position.X) end
    end)
    return row
end

local function makeBtn(parent, label, h, cb)
    local btn = make("TextButton", {
        Text = label, TextSize = 12, TextColor3 = T.text, Font = CurFont,
        BackgroundColor3 = T.input, Size = UDim2.new(1, 0, 0, h or 21),
        AutoButtonColor = false,
    }, parent)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, btn)
    stroke(btn, T.border)
    table.insert(allTextObjs, {btn, "normal"})
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeLabel(parent, text, dim)
    local l = make("TextLabel", {
        Text = text, TextSize = 11, TextColor3 = dim and T.dim or T.text, Font = CurFont,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    table.insert(allTextObjs, {l, dim and "dim" or "normal"})
    return l
end

-- ── Auto Block: watch each enemy's Keybinds.Attack1-5 / Lc1-3 ────────────────
-- When a nearby enemy fires an attack key (the value flips), we block (hold F)
-- for AB_HOLD_TIME via the same path Inf Block uses.
local function hookAutoBlockPlayer(p2)
    if p2 == player then return end
    local function wireKeybinds(kbFolder)
        for _, keyName in pairs(AB_KEYS) do
            local kv = kbFolder:FindFirstChild(keyName)
            if kv then
                local conn = kv.Changed:Connect(function()
                    if not S.AutoBlock then return end
                    local ph = p2.Character and (p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart)
                    local mh = hrp()
                    if ph and mh and (ph.Position - mh.Position).Magnitude < 120 then
                        pressBlockFor(AB_HOLD_TIME)
                    end
                end)
                table.insert(autoBlockConns, conn)
            end
        end
    end
    local kbNow = p2:FindFirstChild("Keybinds")
    if kbNow then wireKeybinds(kbNow) end
    local addConn = p2.ChildAdded:Connect(function(child)
        if child.Name == "Keybinds" then task.defer(function() wireKeybinds(child) end) end
    end)
    table.insert(autoBlockConns, addConn)
end

local function startAutoBlock()
    for _, c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
    autoBlockConns = {}
    for _, p2 in pairs(Players:GetPlayers()) do hookAutoBlockPlayer(p2) end
    table.insert(autoBlockConns, Players.PlayerAdded:Connect(hookAutoBlockPlayer))
end

local function stopAutoBlock()
    for _, c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
    autoBlockConns = {}
    blockHoldEnd = 0
end

-- ── Misc one-shot helpers ────────────────────────────────────────────────────
local function applyFullbright()
    pcall(function()
        Lighting.Brightness    = 2
        Lighting.ClockTime     = 14
        Lighting.FogEnd        = 1e9
        Lighting.GlobalShadows = false
        Lighting.Ambient       = Color3.fromRGB(160, 160, 160)
        Lighting.OutdoorAmbient= Color3.fromRGB(160, 160, 160)
    end)
end

local function fpsBoost()
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
               or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("Texture") or v:IsA("Decal") then
                v.Transparency = 1
            elseif v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
            end
        end
        Lighting.GlobalShadows = false
        local terr = workspace:FindFirstChildOfClass("Terrain")
        if terr then terr.WaterWaveSize = 0; terr.WaterWaveSpeed = 0; terr.WaterReflectance = 0 end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end)
end

local function rejoinServer()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end

local function serverHop()
    task.spawn(function()
        local body
        pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            if game.HttpGetAsync then body = game:HttpGetAsync(url)
            elseif game.HttpGet  then body = game:HttpGet(url) end
        end)
        if not body then rejoinServer(); return end
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(body)
        end)
        if ok and data and data.data then
            for _, sv in ipairs(data.data) do
                if sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, player) end)
                    return
                end
            end
        end
        rejoinServer()
    end)
end

local function resetCharacter()
    pcall(function()
        local h = hum()
        if h then h.Health = 0
        else local c = chr(); if c then c:BreakJoints() end end
    end)
end

-- ── Build tabs ─────────────────────────────────────────────────────────────

-- COMBAT
do
    local L, R = pages["Combat"].left, pages["Combat"].right

    local hb = makeGroup(L, "Hitbox")
    makeCheck(hb, "Extend Hitbox", "ExtendHitbox")
    makeCheck(hb, "Show Hitbox",   "ShowHitbox", function(on)
        if not on then
            for _, b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes = {}
        end
    end)
    makeSlider(hb, "Hitbox Size", "HitboxSize", 1, 60)

    local mb = makeGroup(L, "M1 Expand")
    makeCheck(mb, "M1 Expand",   "M1Expand")
    makeCheck(mb, "Show Expand", "ShowExpand", function(on)
        if not on then destroyExpandVisual() end
    end)
    makeSlider(mb, "M1 Size", "M1Size", 1, 40)

    local df = makeGroup(R, "Defense")
    makeCheck(df, "Inf Block",  "InfBlock")
    makeCheck(df, "Auto Block", "AutoBlock", function(on)
        if on then startAutoBlock() else stopAutoBlock() end
    end)
    makeLabel(df, "Blocks enemy Attack1-5 + M1s", true)

    local am = makeGroup(R, "Aim & Ult")
    makeCheck(am, "Silent Aim",    "SilentAim")
    makeCheck(am, "Auto Ult  [V]", "AutoUlt")

    local fm = makeGroup(R, "Farm")
    makeCheck(fm, "Auto Farm",  "AutoFarm")
    makeSlider(fm, "Farm Range", "AutoFarmRange", 20, 300)
end

-- PLAYER
do
    local L, R = pages["Player"].left, pages["Player"].right

    local mv = makeGroup(L, "Movement")
    makeCheck(mv, "Fly",        "Fly")
    makeSlider(mv, "Fly Speed", "FlySpeed", 10, 300)
    makeCheck(mv, "Noclip", "Noclip")
    makeCheck(mv, "Speed Hack",  "SpeedHack")
    makeSlider(mv, "Walk Speed", "WalkSpeed", 16, 250)
    makeCheck(mv, "Auto Sprint", "AutoSprint")
    makeCheck(mv, "No Stun", "NoStun")

    local sv = makeGroup(R, "Survival")
    makeCheck(sv, "God Mode",       "GodMode")
    makeCheck(sv, "Save System",    "SaveSystem")
    makeSlider(sv, "HP Threshold",  "SaveThreshold", 1, 99, "%")
    makeCheck(sv, "Instant Respawn","InstantRespawn")
    makeCheck(sv, "Invisible",      "Invisible")
end

-- VISUALS
do
    local L, R = pages["Visuals"].left, pages["Visuals"].right
    local es = makeGroup(L, "ESP")
    makeCheck(es, "Player ESP", "ESP")
    local cm = makeGroup(R, "Camera")
    makeCheck(cm, "Inf Zoom", "InfZoom", function(on)
        if on then
            origZoom = player.CameraMaxZoomDistance
            player.CameraMaxZoomDistance = 9999
        else
            if origZoom then player.CameraMaxZoomDistance = origZoom end
        end
    end)
end

-- MISC
do
    local L, R = pages["Misc"].left, pages["Misc"].right

    local cd = makeGroup(L, "Cooldown")
    makeCheck(cd, "Bypass Cooldowns", "BypassCooldown")
    makeLabel(cd, "Clears skill cooldowns 1-5", true)

    local util = makeGroup(L, "Utility")
    makeCheck(util, "Anti-AFK",        "AntiAFK")
    makeCheck(util, "Fullbright",      "Fullbright", function(on) if on then applyFullbright() end end)
    makeCheck(util, "Infinite Jump",   "InfJump")
    makeCheck(util, "Click TP  [T]",   "ClickTP")
    makeCheck(util, "Spinbot",         "Spinbot")

    local sys = makeGroup(R, "World & Server")
    makeCheck(sys, "Hide Names",  "HideNames")
    makeCheck(sys, "Anti-Fling",  "AntiFling")
    makeBtn(sys, "FPS Boost",       20, fpsBoost)
    makeBtn(sys, "Reset Character", 20, resetCharacter)
    makeBtn(sys, "Rejoin Server",   20, rejoinServer)
    makeBtn(sys, "Server Hop",      20, serverHop)
end

-- TELEPORTS
do
    local L = pages["Teleports"].left

    local pt = makeGroup(L, "Player Teleport")
    local list = make("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 150),
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, pt)
    table.insert(scrollFrames, list)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 3)}, list)

    local function rebuild()
        for _, c in pairs(list:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        for _, p2 in pairs(Players:GetPlayers()) do
            if p2 ~= player then
                makeBtn(list, p2.Name, 20, function()
                    pcall(function()
                        local ph = p2.Character and (p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart)
                        local mh = hrp()
                        if ph and mh then mh.CFrame = ph.CFrame + Vector3.new(3, 0, 0) end
                    end)
                end)
            end
        end
    end
    rebuild()
    Players.PlayerAdded:Connect(rebuild)
    Players.PlayerRemoving:Connect(rebuild)
    makeBtn(pt, "Refresh", 20, rebuild)
end

-- SETTINGS
do
    local L, R = pages["Settings"].left, pages["Settings"].right

    local kb = makeGroup(L, "Keybinds")
    local kbLbl = makeLabel(kb, "Toggle GUI: RightShift")
    makeBtn(kb, "Set Toggle Key", 21, function()
        kbLbl.Text = "Press any key..."
        local conn; conn = UIS.InputBegan:Connect(function(i, gpe)
            if gpe then return end
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
            S.ToggleKey = i.KeyCode
            kbLbl.Text  = "Toggle GUI: " .. i.KeyCode.Name
            conn:Disconnect()
        end)
    end)

    local sc = makeGroup(L, "Script")
    makeBtn(sc, "Disconnect All", 21, function()
        for _, c in pairs(Connections)     do pcall(function() c:Disconnect() end) end
        for _, c in pairs(autoBlockConns)  do pcall(function() c:Disconnect() end) end
        stopFly()
        destroyExpandVisual()
        Connections, autoBlockConns = {}, {}
        S.Fly, S.Noclip = false, false
    end)
    makeBtn(sc, "Close Hub", 21, function() destroyExpandVisual(); gui:Destroy() end)

    local hub = makeGroup(R, "Hub Appearance")
    makeLabel(hub, "Accent Color")
    local colorRow = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), BorderSizePixel = 0,
    }, hub)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4)}, colorRow)
    for _, col in pairs(ACCENT_PRESETS) do
        local sw = make("TextButton", {
            Text = "", BackgroundColor3 = col, Size = UDim2.new(0, 18, 0, 18), AutoButtonColor = false,
        }, colorRow)
        make("UICorner", {CornerRadius = UDim.new(0, 3)}, sw)
        sw.MouseButton1Click:Connect(function() T.accent = col; refreshTheme() end)
    end

    makeLabel(hub, "Font")
    local fontRow = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), BorderSizePixel = 0,
    }, hub)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3)}, fontRow)
    for i, fnt in pairs(FONTS) do
        local fb = make("TextButton", {
            Text = FONT_NAMES[i], TextSize = 9, TextColor3 = T.text, Font = fnt,
            BackgroundColor3 = T.input, Size = UDim2.new(0, 46, 0, 20), AutoButtonColor = false,
        }, fontRow)
        make("UICorner", {CornerRadius = UDim.new(0, 3)}, fb)
        stroke(fb, T.border)
        fb.MouseButton1Click:Connect(function()
            CurFont = fnt
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    pcall(function() obj.Font = CurFont end)
                end
            end
        end)
    end
end

-- ── Attack hitbox input (keys 1-5 + M1) ──────────────────────────────────────
local ATTACK_KEYS = {
    [Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two]  = 2, [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four]  = 4, [Enum.KeyCode.Five] = 5,
}

table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end

    -- Number keys 1-5 → fire the matching Attack{N}Hitbox so the swing reaches.
    if i.UserInputType == Enum.UserInputType.Keyboard then
        local n = ATTACK_KEYS[i.KeyCode]
        if n and S.ExtendHitbox then
            spamHitbox("Attack"..n.."Hitbox", S.HitboxSize, 6, 0.05)
        end
        if i.KeyCode == Enum.KeyCode.T and S.ClickTP then
            pcall(function()
                local m  = player:GetMouse()
                local mh = hrp()
                if m and mh and m.Hit then mh.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 4, 0)) end
            end)
        end
        return
    end

    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    -- Extend Hitbox also covers raw clicks across all attacks.
    if S.ExtendHitbox then
        for n = 1, 5 do spamHitbox("Attack"..n.."Hitbox", S.HitboxSize, 4, 0.05) end
    end
    -- M1 Expand → the Lc1-3 light-combo hitboxes.
    if S.M1Expand then
        for n = 1, 3 do spamHitbox("Lc"..n.."Hitbox", S.M1Size, 4, 0.05) end
    end
    if S.SilentAim then
        pcall(function()
            local tgt = nearest(300); if not tgt then return end
            for n = 1, 5 do spamHitbox("Attack"..n.."Hitbox", math.max(S.HitboxSize, 25), 4, 0.05) end
            for n = 1, 3 do spamHitbox("Lc"..n.."Hitbox", math.max(S.HitboxSize, 25), 4, 0.05) end
        end)
    end
end))

-- Infinite Jump
table.insert(Connections, UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local h = hum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end))

-- Anti-AFK
pcall(function()
    player.Idled:Connect(function()
        if not S.AntiAFK then return end
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

local function doInvisible(state)
    pcall(function()
        local c = chr(); if not c then return end
        if state then
            for _, pt in pairs(c:GetDescendants()) do
                if pt:IsA("BasePart") or pt:IsA("Decal") then
                    if not invisOrigTrans[pt] then invisOrigTrans[pt] = pt.Transparency end
                    pt.Transparency = 1
                end
            end
        else
            for pt, t in pairs(invisOrigTrans) do
                pcall(function() if pt and pt.Parent then pt.Transparency = t end end)
            end
            invisOrigTrans = {}
        end
    end)
end

-- ── Main loop ──────────────────────────────────────────────────────────────
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)

    -- Speed Hack
    if S.SpeedHack ~= speedStateLast then
        speedStateLast = S.SpeedHack
        local h = hum()
        if S.SpeedHack then
            if h then speedOriginal = h.WalkSpeed end
        else
            if h and speedOriginal then h.WalkSpeed = speedOriginal end
            speedOriginal = nil
        end
    end
    if S.SpeedHack then
        pcall(function() local h = hum(); if h then h.WalkSpeed = S.WalkSpeed end end)
    end

    -- God Mode
    if S.GodMode ~= godStateLast then
        godStateLast = S.GodMode
        local h = hum()
        if h then
            if S.GodMode then
                godOrigMax  = h.MaxHealth
                h.MaxHealth = math.huge
                h.Health    = math.huge
            else
                if godOrigMax then h.MaxHealth = godOrigMax; h.Health = godOrigMax end
                godOrigMax = nil
            end
        end
    end
    if S.GodMode then
        pcall(function() local h = hum(); if h then h.Health = math.huge end end)
    end

    -- No Stun: keep the character free to move during combat/stun
    if S.NoStun then
        pcall(function()
            local c = chr()
            if c then
                for _, a in ipairs({"Stun","Stunned","Stunning","Ragdoll","Ragdolled",
                                    "Frozen","Knockback","Staggered","NoMove","Disabled"}) do
                    if c:GetAttribute(a) ~= nil then c:SetAttribute(a, false) end
                end
                local mh = c:FindFirstChild("HumanoidRootPart")
                if mh and mh.Anchored then mh.Anchored = false end
            end
            local h = hum()
            if h then
                h.PlatformStand = false
                h.Sit           = false
                if h.WalkSpeed <= 0.5 then h.WalkSpeed = (S.SpeedHack and S.WalkSpeed) or 16 end
                if h.JumpPower ~= nil and h.JumpPower <= 0.5 then h.JumpPower = 50 end
            end
        end)
    end

    -- Invisible
    if S.Invisible ~= invisStateLast then
        invisStateLast = S.Invisible
        doInvisible(S.Invisible)
    end

    -- Fly (Model-safe: BodyVelocity + BodyGyro on the root part)
    if S.Fly ~= flyStateLast then
        flyStateLast = S.Fly
        if S.Fly then startFly() else stopFly() end
    end
    if S.Fly then
        pcall(function()
            local mh = hrp(); if not mh then return end
            if not (flyBV and flyBV.Parent == mh) then startFly() end
            local cf  = workspace.CurrentCamera.CFrame
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            if flyBV then flyBV.Velocity = (dir.Magnitude > 0) and (dir.Unit * S.FlySpeed) or Vector3.zero end
            local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            if flyBG and flat.Magnitude > 0.05 then
                flyBG.CFrame = CFrame.lookAt(mh.Position, mh.Position + flat)
            end
        end)
    end

    -- Noclip
    if S.Noclip then
        noclipLast = true
        local c = chr()
        if c then
            for _, pt in pairs(c:GetDescendants()) do
                if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end
            end
        end
    elseif noclipLast then
        noclipLast = false
        local c = chr()
        if c then
            for _, pt in pairs(c:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" then pt.CanCollide = true end
            end
        end
    end

    -- Auto Sprint
    if S.AutoSprint then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        end)
    end

    -- Spinbot
    if S.Spinbot then
        pcall(function()
            local mh = hrp()
            if mh then
                spinAngle = spinAngle + dt * 12
                mh.CFrame = CFrame.new(mh.Position) * CFrame.Angles(0, spinAngle, 0)
            end
        end)
    end

    -- Anti-Fling
    if S.AntiFling then
        pcall(function()
            local mh = hrp()
            if mh then
                mh.AssemblyAngularVelocity = Vector3.zero
                if mh.AssemblyLinearVelocity.Magnitude > 200 then
                    mh.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    end

    -- Block manager: hold F (block). Release F + fire BlockStop to end the block.
    do
        local want = S.InfBlock or (S.AutoBlock and tick() < blockHoldEnd)
        if want then
            if not blockHolding then
                blockHolding = true
                blockClock   = 0
                blockKey(true)
            else
                blockClock = blockClock + dt
                if blockClock >= 0.3 then blockClock = 0; blockKey(true) end
            end
        elseif blockHolding then
            blockHolding = false
            blockKey(false)
            blockStop()
        end
    end

    -- Auto Ult: press V only on the rising edge of "ult bar full"
    if S.AutoUlt then
        ultClock = ultClock + dt
        if ultClock >= 0.3 then
            ultClock = 0
            local full = false
            pcall(function() full = ultIsFull() end)
            if full and not ultWasFull then
                ultWasFull = true
                task.spawn(function()
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true,  Enum.KeyCode.V, false, game)
                        task.wait(0.08)
                        vim:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                    end)
                end)
            elseif not full then
                ultWasFull = false
            end
        end
    else
        ultClock   = 0
        ultWasFull = false
    end

    -- Auto Farm
    if S.AutoFarm then
        farmClock = farmClock + dt
        if farmClock >= 0.35 then
            farmClock = 0
            pcall(function()
                local tgt = nearest(S.AutoFarmRange); if not tgt then return end
                local mh  = hrp(); if not mh then return end
                local ph  = tgt.Character and (tgt.Character:FindFirstChild("HumanoidRootPart") or tgt.Character.PrimaryPart)
                if not ph then return end
                mh.CFrame = ph.CFrame + (ph.CFrame.LookVector * -3)
                for n = 1, 3 do spamHitbox("Lc"..n.."Hitbox",     S.HitboxSize, 2, 0.04) end
                for n = 1, 5 do spamHitbox("Attack"..n.."Hitbox", S.HitboxSize, 2, 0.04) end
                task.spawn(function()
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        local vp  = workspace.CurrentCamera.ViewportSize
                        vim:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, true,  game, 0)
                        vim:SendMouseButtonEvent(vp.X/2, vp.Y/2, 0, false, game, 0)
                    end)
                end)
            end)
        end
    end

    -- Bypass Cooldown: only touch Moveset.Attack{1-5}.Cooldown (no lag)
    if S.BypassCooldown then
        cdClock = cdClock + dt
        if cdClock >= 0.1 then
            cdClock = 0
            pcall(function()
                local ms = moveset(); if not ms then return end
                for n = 1, 5 do
                    local atk = ms:FindFirstChild("Attack"..n)
                    if atk then
                        local cd = atk:FindFirstChild("Cooldown")
                        if cd then
                            if cd:IsA("GuiObject") then
                                cd.Size    = UDim2.new(0, 0, 0, 0)
                                cd.Visible = false
                            end
                            local txt = cd:FindFirstChildWhichIsA("TextLabel")
                            if txt then txt.Text = "" end
                        end
                        if atk:GetAttribute("Cooldown") ~= nil then atk:SetAttribute("Cooldown", 0) end
                    end
                end
            end)
        end
    end

    -- Hide Names
    if S.HideNames then
        hnClock = hnClock + dt
        if hnClock >= 1 then
            hnClock = 0
            pcall(function()
                for _, p2 in pairs(Players:GetPlayers()) do
                    if p2 ~= player and p2.Character then
                        local h = p2.Character:FindFirstChildOfClass("Humanoid")
                        if h then
                            h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                    end
                end
            end)
        end
    end

    -- Fullbright (re-assert; some games fight back)
    if S.Fullbright then
        fbClock = fbClock + dt
        if fbClock >= 1 then fbClock = 0; applyFullbright() end
    end

    -- M1 Expand visual
    if S.ShowExpand and S.M1Expand then
        ensureExpandVisual()
    elseif expandPart then
        destroyExpandVisual()
    end

    -- Instant Respawn via ReplicatedStorage.Remotes.Died
    if S.InstantRespawn then
        local h = hum()
        if h and h.Health <= 0 then
            respawnClock = respawnClock + dt
            if respawnClock >= 0.5 then
                respawnClock = 0
                pcall(function()
                    local d = diedRemote()
                    if d then d:FireServer("Real", 3.8333332538604736) end
                end)
            end
        else
            respawnClock = 0
        end
    end

    -- Save System
    if S.SaveSystem then
        local h, mh = hum(), hrp()
        if h and mh and h.MaxHealth > 0 then
            if saveActive then
                saveClock = saveClock + dt
                mh.CFrame = CFrame.new(savePos + Vector3.new(0, 500, 0))
                mh.AssemblyLinearVelocity = Vector3.zero
                if saveClock >= 4 or (h.Health / h.MaxHealth * 100) > S.SaveThreshold + 20 then
                    saveActive = false
                    saveClock  = 0
                    mh.CFrame  = CFrame.new(savePos + Vector3.new(0, 8, 0))
                end
            elseif (h.Health / h.MaxHealth * 100) <= S.SaveThreshold then
                savePos    = mh.Position
                saveActive = true
                saveClock  = 0
            end
        end
    end

    -- Show Hitbox
    if S.ShowHitbox ~= showHitboxLast then
        showHitboxLast = S.ShowHitbox
        if not S.ShowHitbox then
            for _, b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes = {}
        else
            for _, p2 in pairs(Players:GetPlayers()) do
                if p2 ~= player and p2.Character then
                    local root = p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                    if root then
                        local box = Instance.new("SelectionBox")
                        box.Adornee             = root
                        box.Color3              = T.accent
                        box.LineThickness       = 0.05
                        box.SurfaceTransparency = 0.7
                        box.SurfaceColor3       = T.accent
                        box.Parent              = gui
                        table.insert(showHitboxBoxes, box)
                    end
                end
            end
        end
    end

    -- ESP
    if S.ESP then
        espClock = espClock + dt
        if espClock >= 0.5 then
            espClock = 0
            for name, data in pairs(espBoxes) do
                if not Players:FindFirstChild(name) then
                    pcall(function() data.bill:Destroy() end)
                    espBoxes[name] = nil
                end
            end
            for _, p2 in pairs(Players:GetPlayers()) do
                if p2 ~= player and p2.Character then
                    local root = p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                    if root and not espBoxes[p2.Name] then
                        local bill = Instance.new("BillboardGui")
                        bill.Size        = UDim2.new(0, 80, 0, 28)
                        bill.AlwaysOnTop = true
                        bill.StudsOffset = Vector3.new(0, 3, 0)
                        bill.Adornee     = root
                        bill.Parent      = gui
                        local lbl2 = make("TextLabel", {
                            Text = p2.Name, TextSize = 13, TextColor3 = T.accent, Font = CurFont,
                            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                            TextStrokeTransparency = 0, TextStrokeColor3 = Color3.new(0,0,0),
                        }, bill)
                        table.insert(allTextObjs, {lbl2, "accent"})
                        espBoxes[p2.Name] = {bill = bill}
                    end
                end
            end
        end
    else
        if next(espBoxes) then
            for _, data in pairs(espBoxes) do pcall(function() data.bill:Destroy() end) end
            espBoxes = {}
        end
    end

end))

-- ── Drag ───────────────────────────────────────────────────────────────────
do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = main.Position
        end
    end)
    titleBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    table.insert(Connections, UIS.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = i.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end))
end

-- ── Minimize / Close ───────────────────────────────────────────────────────
minBtn.MouseButton1Click:Connect(function()
    S.Minimized      = not S.Minimized
    content.Visible  = not S.Minimized
    main.Size = S.Minimized and UDim2.new(0, WIN_W, 0, TITLE_H) or UDim2.new(0, WIN_W, 0, WIN_H)
end)
closeBtn.MouseButton1Click:Connect(function() destroyExpandVisual(); gui:Destroy() end)

-- ── Toggle keybind ─────────────────────────────────────────────────────────
table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == S.ToggleKey then gui.Enabled = not gui.Enabled end
end))

-- ── Init ───────────────────────────────────────────────────────────────────
setTab("Combat")
refreshTheme()

print("[Money/Free Hub] v3.6 | Toggle: " .. S.ToggleKey.Name)
