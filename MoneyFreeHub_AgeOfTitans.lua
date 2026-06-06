-- Money/Free Hub | Age of Titans | v3.5

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local player = Players.LocalPlayer
local UIS    = UserInputService

-- ── Theme ──────────────────────────────────────────────────────────────────
local T = {
    bg       = Color3.fromRGB(17,  18,  22),
    titlebar = Color3.fromRGB(24,  25,  30),
    card     = Color3.fromRGB(20,  21,  26),
    cardhead = Color3.fromRGB(24,  25,  31),
    input    = Color3.fromRGB(26,  27,  33),
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
    HitboxMultiplier = 5,
    ShowHitbox       = false,
    M1Expand         = false,
    M1Multiplier     = 3,
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
    RemoteLogger     = false,
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
local ultWasFull      = false  -- debounce: only press V on the rising edge of "full"
local farmClock       = 0
local cdClock         = 0
local espClock        = 0
local blockClock      = 0      -- block re-assert timer
local blockHoldEnd    = 0      -- tick() deadline: keep blocking until this time
local blockHolding    = false  -- whether we currently have F held down
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
local flyBV           = nil    -- BodyVelocity used for Fly
local flyBG           = nil    -- BodyGyro used to keep Fly stable (no spin)
local flyStateLast    = false
local noclipLast      = false
local loggerInstalled = false
local loggerActive    = false
local loggerSeen      = {}

-- Attack key names stored on enemy Player objects (player.Keybinds.Attack1 etc.)
local AB_KEYS = {"Attack1","Attack2","Attack3","Attack4","Attack5","Lc1","Lc2","Lc3"}
local AB_HOLD_TIME = 4.5   -- seconds to hold F after detecting an enemy attack

-- ── Helpers ────────────────────────────────────────────────────────────────
local function chr() return player.Character end
local function hum() local c = chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c = chr(); return c and c:FindFirstChild("HumanoidRootPart") end

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

-- ReplicatedStorage.Remotes.Died used for Instant Respawn bypass
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
            local ph = p.Character:FindFirstChild("HumanoidRootPart")
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

-- Fly uses BodyVelocity (movement, no gravity) + BodyGyro (locks orientation so
-- the character can't tumble/spin). PlatformStand stops the Humanoid balancing.
local function startFly()
    local mh, h = hrp(), hum()
    if not mh then return end
    if h then pcall(function() h.PlatformStand = true end) end
    if flyBV then pcall(function() flyBV:Destroy() end) end
    if flyBG then pcall(function() flyBG:Destroy() end) end
    flyBV          = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1, 1, 1) * 1e6
    flyBV.Velocity = Vector3.zero
    flyBV.Parent   = mh
    flyBG          = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1, 1, 1) * 1e6
    flyBG.P        = 9000
    flyBG.D        = 800
    flyBG.CFrame   = mh.CFrame
    flyBG.Parent   = mh
end

local function stopFly()
    local h = hum()
    if h then pcall(function() h.PlatformStand = false end) end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
end

-- Blocking is remote-driven in this game (you gave me the "BlockStop" remote).
-- We fire the block-START remote AND hold F, so it works whether block is
-- remote- or key-driven. Once the Remote Logger reveals the exact start remote,
-- trim BLOCK_START down to that one name.
local BLOCK_START = {"Block", "BlockStart", "StartBlock", "Blocking"}
local function blockKey(down)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(down, Enum.KeyCode.F, false, game)
    end)
end
local function blockEngage()
    blockKey(true)
    local r = re()
    if r then for _, n in ipairs(BLOCK_START) do pcall(function() r:FireServer(n) end) end end
end
local function blockRelease()
    blockKey(false)
    local r = re(); if r then pcall(function() r:FireServer("BlockStop") end) end
end

-- Remote Logger: prints every RemoteEvent/Function the game fires so you can
-- find the exact remote for block, cooldowns, etc. Needs an executor with
-- hookmetamethod (Synapse / Script-Ware / Wave / Delta / etc.).
local function ensureLoggerHook()
    if loggerInstalled then return true end
    if not (hookmetamethod and getnamecallmethod) then
        warn("[Money/Free Hub] Remote Logger needs an executor with hookmetamethod.")
        return false
    end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if loggerActive then
            local ok, method = pcall(getnamecallmethod)
            if ok and (method == "FireServer" or method == "InvokeServer") then
                local args  = {...}
                local parts = {}
                for _, a in ipairs(args) do parts[#parts + 1] = tostring(a) end
                local full = "?"; pcall(function() full = self:GetFullName() end)
                local sig  = full .. "|" .. (parts[1] or "")
                local now  = tick()
                if not loggerSeen[sig] or now - loggerSeen[sig] > 2 then
                    loggerSeen[sig] = now
                    print(("[Hub][Remote] %s :%s(%s)"):format(full, method, table.concat(parts, ", ")))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    loggerInstalled = true
    return true
end

-- Detect when the ultimate bar is full so Auto Ult only presses V then.
-- Looks at (1) number attributes, (2) NumberValue/IntValue with a Max sibling,
-- (3) a fill bar in PlayerGui — whichever exists, matched by name keyword.
local ULT_KEYS = {"ult","charge","energy","special","rage","meter","super","mana","fury"}
local function nameMatchesUlt(n)
    n = tostring(n):lower()
    for _, k in ipairs(ULT_KEYS) do if n:find(k) then return true end end
    return false
end
local function ultIsFull()
    for _, root in ipairs({chr(), player}) do
        if root then
            -- (1) attributes
            local hit = false
            pcall(function()
                for attr, v in pairs(root:GetAttributes()) do
                    if type(v) == "number" and nameMatchesUlt(attr) then
                        local maxV = root:GetAttribute("Max"..attr) or root:GetAttribute(attr.."Max")
                        if type(maxV) == "number" and maxV > 0 and v >= maxV - 0.01 then hit = true end
                    end
                end
            end)
            if hit then return true end
            -- (2) value objects with a Max sibling
            for _, d in ipairs(root:GetDescendants()) do
                if (d:IsA("NumberValue") or d:IsA("IntValue")) and nameMatchesUlt(d.Name) then
                    local p = d.Parent
                    local m = p and (p:FindFirstChild("Max"..d.Name) or p:FindFirstChild(d.Name.."Max") or p:FindFirstChild("Max"))
                    if m and (m:IsA("NumberValue") or m:IsA("IntValue")) and m.Value > 0 and d.Value >= m.Value - 0.01 then
                        return true
                    end
                end
            end
        end
    end
    -- (3) GUI fill bar
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("Frame") and nameMatchesUlt(d.Name) and d.AbsoluteSize.X > 0 then
                for _, c in ipairs(d:GetDescendants()) do
                    if c:IsA("Frame") and c.AbsoluteSize.X > 0 then
                        local cn = c.Name:lower()
                        if (cn:find("fill") or cn:find("bar") or cn:find("progress"))
                           and c.AbsoluteSize.X / d.AbsoluteSize.X >= 0.95 then
                            return true
                        end
                    end
                end
            end
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

local WIN_W, WIN_H = 720, 560
local TITLE_H, TAB_H = 26, 28

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
    Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, tabBar)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, tabRow)

local pageArea = make("Frame", {
    Size = UDim2.new(1, 0, 1, -TAB_H), Position = UDim2.new(0, 0, 0, TAB_H),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, content)

local TAB_NAMES = {"Combat","Player","Visuals","Misc","Teleports","Settings"}
local tabBtns   = {}
local pages     = {}

local function makeTabBtn(name)
    local btn = make("TextButton", {
        Text = name, TextSize = 12, TextColor3 = T.dim, Font = CurFont,
        BackgroundColor3 = T.titlebar, BackgroundTransparency = 1,
        Size = UDim2.new(0, 104, 1, -1), AutoButtonColor = false,
    }, tabRow)
    local under = make("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.accent, BorderSizePixel = 0, Visible = false,
    }, btn)
    table.insert(accentFrames, under)
    table.insert(allTextObjs, {btn, "tab"})
    return btn, under
end

local function makePage()
    local page = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false,
    }, pageArea)
    local function col(xScale, xOff)
        local c = make("ScrollingFrame", {
            Size = UDim2.new(0.5, -12, 1, -16), Position = UDim2.new(xScale, xOff, 0, 8),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, page)
        table.insert(scrollFrames, c)
        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        }, c)
        return c
    end
    return {page = page, left = col(0, 8), right = col(0.5, 4)}
end

for _, name in pairs(TAB_NAMES) do
    local btn, under = makeTabBtn(name)
    tabBtns[name] = {btn = btn, under = under}
    pages[name]   = makePage()
end

local function setTab(name)
    for n, d in pairs(tabBtns) do
        d.btn.TextColor3 = (n == name) and T.text or T.dim
        d.under.Visible  = (n == name)
        pcall(function() pages[n].page.Visible = (n == name) end)
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
        Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = T.cardhead,
        BorderSizePixel = 0, LayoutOrder = 1,
    }, frame)
    make("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.border, BorderSizePixel = 0,
    }, head)
    local htxt = make("TextLabel", {
        Text = title, TextSize = 12, TextColor3 = T.text, Font = CurFont,
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
        PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8),
    }, inner)
    return inner
end

local function makeCheck(parent, label, key, cb, hasConfig, cfgCb)
    local row = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), BorderSizePixel = 0,
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
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), BorderSizePixel = 0,
    }, parent)
    local lbl = make("TextLabel", {
        Text = label, TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    table.insert(allTextObjs, {lbl, "normal"})
    local bar = make("Frame", {
        BackgroundColor3 = T.input, Size = UDim2.new(1, 0, 0, 15),
        Position = UDim2.new(0, 0, 0, 17), BorderSizePixel = 0,
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
        BackgroundColor3 = T.input, Size = UDim2.new(1, 0, 0, h or 22),
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
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    table.insert(allTextObjs, {l, dim and "dim" or "normal"})
    return l
end

local function makeDD(parent, label, opts, key, cb)
    local con = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38),
        BorderSizePixel = 0, ClipsDescendants = false,
    }, parent)
    local lbl = make("TextLabel", {
        Text = label, TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, con)
    table.insert(allTextObjs, {lbl, "normal"})
    local sel = S[key] or opts[1]
    local mb  = make("TextButton", {
        Text = "  " .. sel, TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundColor3 = T.input, Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 17), AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, con)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, mb)
    stroke(mb, T.border)
    table.insert(allTextObjs, {mb, "normal"})
    local arrow = make("TextLabel", {
        Text = "v", TextSize = 10, TextColor3 = T.dim, Font = CurFont,
        BackgroundTransparency = 1, Position = UDim2.new(1, -16, 0, 17),
        Size = UDim2.new(0, 14, 0, 18),
    }, con)
    table.insert(allTextObjs, {arrow, "dim"})
    local df = make("Frame", {
        BackgroundColor3 = T.card, Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 36), BorderSizePixel = 0, Visible = false,
        ZIndex = 20, ClipsDescendants = true,
    }, con)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, df)
    stroke(df, T.border)
    local ds = make("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.accent, ZIndex = 20,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, df)
    table.insert(scrollFrames, ds)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical}, ds)
    local open = false
    local function close() open = false; df.Visible = false; df.Size = UDim2.new(1, 0, 0, 0) end
    for _, opt in pairs(opts) do
        local ob = make("TextButton", {
            Text = "  " .. opt, TextSize = 11, TextColor3 = T.text, Font = CurFont,
            BackgroundColor3 = T.input, Size = UDim2.new(1, 0, 0, 20),
            AutoButtonColor = false, ZIndex = 21, TextXAlignment = Enum.TextXAlignment.Left,
        }, ds)
        table.insert(allTextObjs, {ob, "normal"})
        ob.MouseButton1Click:Connect(function()
            S[key] = opt; mb.Text = "  " .. opt; close()
            if cb then cb(opt) end
        end)
    end
    mb.MouseButton1Click:Connect(function()
        open = not open
        if open then df.Size = UDim2.new(1, 0, 0, math.min(#opts * 20, 110)); df.Visible = true
        else close() end
    end)
    return con
end

-- ── Auto Block: watch enemy Keybinds folder ────────────────────────────────
-- Each enemy player has player.Keybinds.Attack1 … Attack5, Lc1 … Lc3.
-- When any of those values fires (Changed → truthy) AND that player is within
-- range, we hold F for AB_HOLD_TIME seconds.

local function hookAutoBlockPlayer(p2)
    if p2 == player then return end

    local function wireKeybinds(kbFolder)
        for _, keyName in pairs(AB_KEYS) do
            local kv = kbFolder:FindFirstChild(keyName)
            if kv then
                local conn = kv.Changed:Connect(function(val)
                    if not (S.AutoBlock and val) then return end
                    local ph = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart")
                    local mh = hrp()
                    if ph and mh and (ph.Position - mh.Position).Magnitude < 120 then
                        pressBlockFor(AB_HOLD_TIME)
                    end
                end)
                table.insert(autoBlockConns, conn)
            end
        end
    end

    -- Wire existing Keybinds folder
    local kbNow = p2:FindFirstChild("Keybinds")
    if kbNow then wireKeybinds(kbNow) end

    -- Also wire if Keybinds appears later (sometimes added after load)
    local addConn = p2.ChildAdded:Connect(function(child)
        if child.Name == "Keybinds" then
            -- ChildAdded fires synchronously — values may not be parented yet,
            -- wait one frame before iterating
            task.defer(function() wireKeybinds(child) end)
        end
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
    blockHoldEnd = 0   -- the block manager releases F on the next frame
end

-- ── Build tabs ─────────────────────────────────────────────────────────────

-- COMBAT
do
    local L, R = pages["Combat"].left, pages["Combat"].right

    local hb = makeGroup(L, "Hitbox")
    makeCheck(hb, "Extend Hitbox", "ExtendHitbox", nil, true)
    makeCheck(hb, "Show Hitbox",   "ShowHitbox", function(on)
        if not on then
            for _, b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes = {}
        end
    end)
    makeCheck(hb, "M1 Expand", "M1Expand")
    makeSlider(hb, "Hitbox Size",  "HitboxMultiplier", 1, 20)
    makeSlider(hb, "M1 Size",      "M1Multiplier",     1, 15)

    local df = makeGroup(L, "Defense")
    makeCheck(df, "Inf Block",  "InfBlock")
    makeCheck(df, "Auto Block", "AutoBlock", function(on)
        if on then startAutoBlock() else stopAutoBlock() end
    end)
    makeLabel(df, "Watches enemy Attack1-5, Lc1-3", true)
    makeLabel(df, "Holds F for 4.5s on detect", true)

    local am = makeGroup(R, "Aim")
    makeCheck(am, "Silent Aim", "SilentAim", nil, true)

    local ul = makeGroup(R, "Ultimate")
    makeCheck(ul, "Auto Ult  [V]", "AutoUlt")

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

    local dbg = makeGroup(R, "Debug")
    makeCheck(dbg, "Remote Logger", "RemoteLogger", function(on)
        if on then
            if ensureLoggerHook() then
                loggerActive = true
                print("[Money/Free Hub] Remote Logger ON. Press F (block), attack, use a cooldown -- copy the printed lines.")
            else
                S.RemoteLogger = false
            end
        else
            loggerActive = false
        end
    end)
    makeLabel(dbg, "Logs every remote the game fires", true)
    makeLabel(dbg, "to the console (F9 / executor).", true)
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
                        local ph = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart")
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
    makeBtn(kb, "Set Toggle Key", 22, function()
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
    makeBtn(sc, "Disconnect All", 22, function()
        for _, c in pairs(Connections)     do pcall(function() c:Disconnect() end) end
        for _, c in pairs(autoBlockConns)  do pcall(function() c:Disconnect() end) end
        stopFly()
        Connections, autoBlockConns = {}, {}
        S.Fly, S.Noclip = false, false
    end)
    makeBtn(sc, "Close Hub", 22, function() gui:Destroy() end)

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
            BackgroundColor3 = T.input, Size = UDim2.new(0, 60, 0, 20), AutoButtonColor = false,
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

-- ── Feature Loops ──────────────────────────────────────────────────────────

-- Extend Hitbox / M1 Expand / Silent Aim fire on real M1 clicks only
table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    if S.ExtendHitbox then
        pcall(function()
            local r = re(); if not r then return end
            local m = S.HitboxMultiplier
            for n = 1, 5 do r:FireServer("Attack"..n.."Hitbox", m) end
            for n = 1, 3 do r:FireServer("Lc"..n.."Hitbox",    m) end
        end)
    end
    if S.M1Expand then
        pcall(function()
            local r = re(); if not r then return end
            for n = 1, 3 do r:FireServer("Lc"..n.."Hitbox", S.M1Multiplier) end
        end)
    end
    if S.SilentAim then
        pcall(function()
            local tgt = nearest(300); if not tgt then return end
            local ph  = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
            if not ph then return end
            local r = re(); if not r then return end
            for n = 1, 5 do r:FireServer("Attack"..n.."Hitbox", 30) end
            for n = 1, 3 do r:FireServer("Lc"..n.."Hitbox",    30) end
        end)
    end
end))

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

    -- Invisible
    if S.Invisible ~= invisStateLast then
        invisStateLast = S.Invisible
        doInvisible(S.Invisible)
    end

    -- Fly (BodyVelocity + BodyGyro — stable, no spin)
    if S.Fly ~= flyStateLast then
        flyStateLast = S.Fly
        if S.Fly then startFly() else stopFly() end
    end
    if S.Fly then
        pcall(function()
            local mh = hrp(); if not mh then return end
            -- Re-create the movers if we respawned (old ones died with old HRP)
            if not (flyBV and flyBV.Parent == mh) then startFly() end
            local cf  = workspace.CurrentCamera.CFrame
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            flyBV.Velocity = (dir.Magnitude > 0) and (dir.Unit * S.FlySpeed) or Vector3.zero
            -- Keep the body upright, facing where the camera looks (yaw only)
            local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            if flat.Magnitude > 0.05 then
                flyBG.CFrame = CFrame.lookAt(mh.Position, mh.Position + flat)
            end
        end)
    end

    -- Noclip (flag-driven; runs every frame so it survives respawns)
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

    -- Block manager: Inf Block (always) and Auto Block (while its 4.5s deadline
    -- is live) both feed into this. Engages via remote + F, re-asserts every
    -- 0.4s, releases + fires BlockStop when nothing wants to block.
    do
        local want = S.InfBlock or (S.AutoBlock and tick() < blockHoldEnd)
        if want then
            if not blockHolding then
                blockHolding = true
                blockClock   = 0
                blockEngage()
            else
                blockClock = blockClock + dt
                if blockClock >= 0.4 then blockClock = 0; blockEngage() end
            end
        elseif blockHolding then
            blockHolding = false
            blockRelease()
        end
    end

    -- Auto Ult: press V only on the moment the ult bar becomes full
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
                        task.wait(0.1)
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

    -- Auto Farm: TP behind target, extend hitboxes, swing M1
    if S.AutoFarm then
        farmClock = farmClock + dt
        if farmClock >= 0.35 then
            farmClock = 0
            pcall(function()
                local tgt = nearest(S.AutoFarmRange); if not tgt then return end
                local mh  = hrp(); if not mh then return end
                local ph  = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
                if not ph then return end
                mh.CFrame = ph.CFrame + (ph.CFrame.LookVector * -3)
                local r   = re()
                if r then
                    for n = 1, 3 do r:FireServer("Lc"..n.."Hitbox",     S.HitboxMultiplier) end
                    for n = 1, 5 do r:FireServer("Attack"..n.."Hitbox", S.HitboxMultiplier) end
                end
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

    -- Bypass Cooldown: zero every cooldown-looking value and attribute
    if S.BypassCooldown then
        cdClock = cdClock + dt
        if cdClock >= 0.25 then
            cdClock = 0
            pcall(function()
                local objs = {player, chr()}
                for _, obj in pairs(objs) do
                    if obj then
                        for _, desc in pairs(obj:GetDescendants()) do
                            local n = desc.Name:lower()
                            if n:find("cool") or n:find("^cd") or n:find("nexttp") or n:find("timer") then
                                if desc:IsA("NumberValue") or desc:IsA("IntValue") then desc.Value = 0 end
                            end
                        end
                        for _, attr in pairs({"Cooldown","CD","NextTP","Timer","MapCooldown","TpCooldown"}) do
                            pcall(function()
                                local v = obj:GetAttribute(attr)
                                if type(v) == "number" then obj:SetAttribute(attr, 0) end
                            end)
                        end
                    end
                end
            end)
        end
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

    -- Save System: on low HP launch to sky, drop back after 4s
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
                    local root = p2.Character:FindFirstChild("HumanoidRootPart")
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
                    local root = p2.Character:FindFirstChild("HumanoidRootPart")
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
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ── Toggle keybind ─────────────────────────────────────────────────────────
table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == S.ToggleKey then gui.Enabled = not gui.Enabled end
end))

-- ── Init ───────────────────────────────────────────────────────────────────
setTab("Combat")
refreshTheme()

print("[Money/Free Hub] v3.5 | Toggle: " .. S.ToggleKey.Name)
