-- Money/Free Hub | Age of Titans | v3.0 (Sierra-style layout)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

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
    green    = Color3.fromRGB(80,  180, 100),
    red      = Color3.fromRGB(190, 70,  70),
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

local allTextObjs   = {}   -- {obj, role}  role = normal | accent | dim | tab
local accentFrames  = {}
local accentStrokes = {}
local scrollFrames  = {}

local function refreshTheme()
    for _, pr in pairs(allTextObjs) do
        pcall(function()
            local role = pr[2]
            if role == "accent" then pr[1].TextColor3 = T.accent
            elseif role == "dim" then pr[1].TextColor3 = T.dim
            elseif role == "tab"  then -- color managed by setTab
            else pr[1].TextColor3 = T.text end
            pr[1].Font = CurFont
        end)
    end
    for _, f in pairs(accentFrames)  do pcall(function() f.BackgroundColor3 = T.accent end) end
    for _, s in pairs(accentStrokes) do pcall(function() s.Color = T.accent end) end
    for _, sf in pairs(scrollFrames) do pcall(function() sf.ScrollBarImageColor3 = T.accent end) end
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
    SelectedMap      = "Pit",
    SelectedSkin     = "None",
    Minimized        = false,
    ToggleKey        = Enum.KeyCode.RightShift,
}

-- internal
local speedOriginal   = nil
local speedStateLast  = false
local godOrigMax      = nil
local godStateLast    = false
local invisOrigTrans  = {}
local invisStateLast  = false
local ultClock        = 0
local farmClock       = 0
local cdClock         = 0
local espClock        = 0
local espBoxes        = {}
local showHitboxBoxes = {}
local showHitboxLast  = false
local noclipConn      = nil
local autoBlockConns  = {}
local origZoom        = nil
local Connections     = {}

-- ── Helpers ────────────────────────────────────────────────────────────────
local function chr() return player.Character end
local function hum()
    local c = chr(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function hrp()
    local c = chr(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function re()
    local rs = game:GetService("ReplicatedStorage")
    return rs:FindFirstChild("RemoteEvent") or rs:FindFirstChildWhichIsA("RemoteEvent")
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

-- Title bar
local titleBar = make("Frame", {
    Size             = UDim2.new(1, 0, 0, TITLE_H),
    BackgroundColor3 = T.titlebar,
    BorderSizePixel  = 0,
}, main)
make("Frame", {  -- bottom hairline
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

-- Body (everything under the title; toggled by minimize)
local content = make("Frame", {
    Size = UDim2.new(1, 0, 1, -TITLE_H), Position = UDim2.new(0, 0, 0, TITLE_H),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, main)

-- Top tab bar
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
make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2),
    VerticalAlignment = Enum.VerticalAlignment.Center}, tabRow)

-- Page area
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
        make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, c)
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
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)}, frame)

    local al = make("Frame", {  -- blue top accent line
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.accent,
        BorderSizePixel = 0, LayoutOrder = 0,
    }, frame)
    table.insert(accentFrames, al)

    local head = make("Frame", {  -- header strip
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
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, inner)
    make("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8)}, inner)
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

-- ── Build Tabs ─────────────────────────────────────────────────────────────

-- COMBAT
do
    local L, R = pages["Combat"].left, pages["Combat"].right

    local hb = makeGroup(L, "Hitbox")
    makeCheck(hb, "Extend Hitbox", "ExtendHitbox", nil, true)
    makeCheck(hb, "Show Hitbox", "ShowHitbox", function(on)
        if not on then
            for _, b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes = {}
        end
    end)
    makeCheck(hb, "M1 Expand", "M1Expand")
    makeSlider(hb, "Hitbox Size", "HitboxMultiplier", 1, 20)
    makeSlider(hb, "M1 Size", "M1Multiplier", 1, 15)

    local df = makeGroup(L, "Defense")
    makeCheck(df, "Inf Block", "InfBlock")
    makeCheck(df, "Auto Block", "AutoBlock", function(on)
        for _, c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
        autoBlockConns = {}
        if on then
            local function hookPlayer(p2)
                if p2 == player then return end
                local function hookChar(c2)
                    if not c2 then return end
                    local h2 = c2:FindFirstChildOfClass("Humanoid"); if not h2 then return end
                    local ani = h2:FindFirstChildOfClass("Animator"); if not ani then return end
                    local conn = ani.AnimationPlayed:Connect(function(tr)
                        local id = (tr.Animation and tr.Animation.AnimationId) or ""
                        local low = id:lower()
                        if not (low:find("attack") or low:find("hit") or low:find("swing")) then return end
                        local ph = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart")
                        local mh = hrp()
                        if not ph or not mh then return end
                        if (ph.Position - mh.Position).Magnitude > 50 then return end
                        task.spawn(function()
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                vim:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
                                task.wait(0.05)
                                vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                            end)
                        end)
                    end)
                    table.insert(autoBlockConns, conn)
                end
                hookChar(p2.Character)
                table.insert(autoBlockConns, p2.CharacterAdded:Connect(hookChar))
            end
            for _, p2 in pairs(Players:GetPlayers()) do hookPlayer(p2) end
            table.insert(autoBlockConns, Players.PlayerAdded:Connect(hookPlayer))
        end
    end)

    local am = makeGroup(R, "Aim")
    makeCheck(am, "Silent Aim", "SilentAim", nil, true)

    local ul = makeGroup(R, "Ultimate")
    makeCheck(ul, "Auto Ult  [V]", "AutoUlt")

    local fm = makeGroup(R, "Farm")
    makeCheck(fm, "Auto Farm", "AutoFarm")
    makeSlider(fm, "Farm Range", "AutoFarmRange", 20, 300)
end

-- PLAYER
do
    local L, R = pages["Player"].left, pages["Player"].right

    local mv = makeGroup(L, "Movement")
    makeCheck(mv, "Fly", "Fly")
    makeSlider(mv, "Fly Speed", "FlySpeed", 10, 300)
    makeCheck(mv, "Noclip", "Noclip", function(on)
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if on then
            noclipConn = RunService.Stepped:Connect(function()
                local c = chr(); if not c then return end
                for _, pt in pairs(c:GetDescendants()) do
                    if pt:IsA("BasePart") then pt.CanCollide = false end
                end
            end)
        else
            pcall(function()
                local c = chr(); if not c then return end
                for _, pt in pairs(c:GetDescendants()) do
                    if pt:IsA("BasePart") then pt.CanCollide = true end
                end
            end)
        end
    end)
    makeCheck(mv, "Speed Hack", "SpeedHack")
    makeSlider(mv, "Walk Speed", "WalkSpeed", 16, 250)
    makeCheck(mv, "Auto Sprint", "AutoSprint")

    local sv = makeGroup(R, "Survival")
    makeCheck(sv, "God Mode", "GodMode")
    makeCheck(sv, "Save System", "SaveSystem")
    makeSlider(sv, "HP Threshold", "SaveThreshold", 1, 99, "%")
    makeCheck(sv, "Instant Respawn", "InstantRespawn")
    makeCheck(sv, "Invisible", "Invisible")
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

    local sk = makeGroup(L, "Skins")
    local allSkins = {"None",
        "EvolvedGodzillaRemodel/DefaultEvolvedGodzillaRemodel",
        "EvolvedGodzillaRemodel/EvolvedGodzillaRemodelEnergized",
        "EvolvedGodzillaRemodel/EvolvedGodzillaRemodelGold",
        "EvolvedGodzillaRemodel/EvolvedGodzillaRemodelPreEvolved",
        "EvolvedGodzillaRemodel/EvolvedGodzillaRemodelSuperCharged",
        "EvolvedGodzillaRemodel/EvolvedGodzillaRemodelThermoNuclear",
    }
    pcall(function()
        local built = {"None"}
        local kf = player:FindFirstChild("Kaijus")
        if kf then
            for _, kaiju in pairs(kf:GetChildren()) do
                local sf = kaiju:FindFirstChild("Skins")
                if sf then
                    for _, s2 in pairs(sf:GetChildren()) do
                        table.insert(built, kaiju.Name .. "/" .. s2.Name)
                    end
                end
            end
        end
        if #built > 1 then allSkins = built end
    end)
    makeDD(sk, "Skin", allSkins, "SelectedSkin")
    makeBtn(sk, "Apply Skin", 22, function()
        if S.SelectedSkin == "None" then return end
        pcall(function()
            local parts = S.SelectedSkin:split("/")
            if #parts < 2 then return end
            local kname, sname = parts[1], parts[2]
            local kf = player:FindFirstChild("Kaijus"); if not kf then return end
            local k  = kf:FindFirstChild(kname); if not k then return end
            local sf = k:FindFirstChild("Skins"); if not sf then return end
            local s3 = sf:FindFirstChild(sname); if not s3 then return end
            if s3:IsA("BoolValue") then s3.Value = true
            elseif s3:IsA("StringValue") then s3.Value = sname end
        end)
    end)

    local cd = makeGroup(R, "Cooldown")
    makeCheck(cd, "Bypass Cooldowns", "BypassCooldown")
end

-- TELEPORTS
do
    local L, R = pages["Teleports"].left, pages["Teleports"].right
    local MAPS = {"Pit","Village","Abandoned City","Mountain","Final Valley","Desert"}

    local mp = makeGroup(L, "Map Teleport")
    makeDD(mp, "Map", MAPS, "SelectedMap")
    makeBtn(mp, "Teleport", 22, function()
        pcall(function()
            local r = re(); if not r then return end
            r:FireServer("MapTeleport", S.SelectedMap)
        end)
    end)

    local pt = makeGroup(R, "Player Teleport")
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
                        if ph and mh then mh.CFrame = ph.CFrame + Vector3.new(3,0,0) end
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
        for _, c in pairs(Connections) do pcall(function() c:Disconnect() end) end
        for _, c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
        if noclipConn then pcall(function() noclipConn:Disconnect() end) end
        Connections, autoBlockConns, noclipConn = {}, {}, nil
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

-- Extend Hitbox / M1 Expand / Silent Aim: fire only on real M1 click
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
            r:FireServer("Attack1Hitbox", S.M1Multiplier)
            r:FireServer("Attack2Hitbox", S.M1Multiplier)
        end)
    end
    if S.SilentAim then
        pcall(function()
            local tgt = nearest(300); if not tgt then return end
            local ph  = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
            if not ph then return end
            local r = re(); if not r then return end
            r:FireServer("SilentAim", ph.Position)
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

    if S.Invisible ~= invisStateLast then
        invisStateLast = S.Invisible
        doInvisible(S.Invisible)
    end

    if S.Fly then
        pcall(function()
            local mh = hrp(); local h = hum()
            if not mh or not h then return end
            h:ChangeState(Enum.HumanoidStateType.Physics)
            mh.AssemblyLinearVelocity = Vector3.zero
            local cf  = workspace.CurrentCamera.CFrame
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then
                mh.CFrame = mh.CFrame + dir.Unit * S.FlySpeed * dt
            end
        end)
    end

    if S.AutoSprint then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        end)
    end

    if S.InfBlock then
        pcall(function() local r = re(); if r then r:FireServer("InfBlock") end end)
    end

    if S.AutoUlt then
        ultClock = ultClock + dt
        if ultClock >= 2 then
            ultClock = 0
            task.spawn(function()
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true,  Enum.KeyCode.V, false, game)
                    task.wait(0.1)
                    vim:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                end)
            end)
        end
    else
        ultClock = 0
    end

    if S.AutoFarm then
        farmClock = farmClock + dt
        if farmClock >= 0.4 then
            farmClock = 0
            pcall(function()
                local tgt = nearest(S.AutoFarmRange); if not tgt then return end
                local mh = hrp(); if not mh then return end
                local ph = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
                if not ph then return end
                mh.CFrame = ph.CFrame + Vector3.new(3, 0, 0)
                local r = re(); if not r then return end
                r:FireServer("Attack1Hitbox", S.HitboxMultiplier)
            end)
        end
    end

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
                                if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                                    desc.Value = 0
                                end
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

    if S.InstantRespawn then
        local h = hum()
        if h and h.Health <= 0 then
            pcall(function() player:LoadCharacter() end)
        end
    end

    if S.SaveSystem then
        local h = hum()
        if h and h.MaxHealth > 0 then
            if (h.Health / h.MaxHealth * 100) <= S.SaveThreshold then
                pcall(function() local r = re(); if r then r:FireServer("Heal") end end)
            end
        end
    end

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
                        box.Adornee            = root
                        box.Color3             = T.accent
                        box.LineThickness      = 0.05
                        box.SurfaceTransparency = 0.7
                        box.SurfaceColor3      = T.accent
                        box.Parent             = gui
                        table.insert(showHitboxBoxes, box)
                    end
                end
            end
        end
    end

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
                            BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
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

    if S.AutoBlock then
        local mh = hrp(); if not mh then return end
        for _, p2 in pairs(Players:GetPlayers()) do
            if p2 ~= player and p2.Character then
                local ph = p2.Character:FindFirstChild("HumanoidRootPart")
                if ph and (ph.Position - mh.Position).Magnitude < 14 then
                    task.spawn(function()
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
                            task.wait(0.03)
                            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        end)
                    end)
                end
            end
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
    S.Minimized = not S.Minimized
    content.Visible = not S.Minimized
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

print("[Money/Free Hub] v3.0 | Toggle: " .. S.ToggleKey.Name)
