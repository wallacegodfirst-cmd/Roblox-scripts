-- Money/Free Hub | Age of Titans | v2.0

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local UIS    = UserInputService

-- ── Theme ──────────────────────────────────────────────────────────────────
local T = {
    bg     = Color3.fromRGB(13,  15,  15),
    panel  = Color3.fromRGB(19,  21,  21),
    panel2 = Color3.fromRGB(16,  18,  18),
    border = Color3.fromRGB(3,   6,   8),
    accent = Color3.fromRGB(54,  89,  174),
    text   = Color3.fromRGB(235, 235, 235),
    button = Color3.fromRGB(22,  24,  24),
    red    = Color3.fromRGB(174, 54,  54),
    green  = Color3.fromRGB(54,  174, 74),
    off    = Color3.fromRGB(17,  19,  19),
}

local ACCENT_PRESETS = {
    Color3.fromRGB(54,  89,  174),
    Color3.fromRGB(174, 54,  54),
    Color3.fromRGB(54,  174, 74),
    Color3.fromRGB(174, 140, 54),
    Color3.fromRGB(120, 54,  174),
    Color3.fromRGB(54,  174, 174),
    Color3.fromRGB(174, 54,  120),
    Color3.fromRGB(200, 200, 200),
}

local FONTS      = {Enum.Font.GothamBold, Enum.Font.Gotham, Enum.Font.SourceSans, Enum.Font.RobotoMono, Enum.Font.Code}
local FONT_NAMES = {"GothamBold","Gotham","SourceSans","RobotoMono","Code"}
local CurFont    = Enum.Font.GothamBold

local allTextObjs   = {}
local accentFrames  = {}
local accentStrokes = {}
local scrollFrames  = {}

local function refreshTheme()
    for _, pair in pairs(allTextObjs) do
        pcall(function()
            pair[1].TextColor3 = (pair[2] == "accent") and T.accent or T.text
            pair[1].Font       = CurFont
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

-- ── GUI ────────────────────────────────────────────────────────────────────
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

local WIN_W, WIN_H = 530, 430

local main = make("Frame", {
    Size                = UDim2.new(0, WIN_W, 0, WIN_H),
    Position            = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3    = T.bg,
    BorderSizePixel     = 0,
    ClipsDescendants    = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, main)
stroke(main, T.border)

-- Title bar
local titleBar = make("Frame", {
    Size             = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = T.panel,
    BorderSizePixel  = 0,
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, titleBar)
make("Frame", {
    Size             = UDim2.new(1, 0, 0, 6),
    Position         = UDim2.new(0, 0, 1, -6),
    BackgroundColor3 = T.panel,
    BorderSizePixel  = 0,
}, titleBar)

local accentLine = make("Frame", {
    Size             = UDim2.new(1, 0, 0, 2),
    Position         = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = T.accent,
    BorderSizePixel  = 0,
}, titleBar)
table.insert(accentFrames, accentLine)

local titleDot = make("Frame", {
    Size             = UDim2.new(0, 7, 0, 7),
    Position         = UDim2.new(0, 11, 0.5, -3),
    BackgroundColor3 = T.accent,
    BorderSizePixel  = 0,
}, titleBar)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, titleDot)
table.insert(accentFrames, titleDot)

local titleLbl = make("TextLabel", {
    Text              = "Money / Free Hub",
    TextSize          = 12,
    TextColor3        = T.text,
    Font              = CurFont,
    BackgroundTransparency = 1,
    Position          = UDim2.new(0, 24, 0, 0),
    Size              = UDim2.new(1, -90, 1, 0),
    TextXAlignment    = Enum.TextXAlignment.Left,
}, titleBar)
table.insert(allTextObjs, {titleLbl, "normal"})

local minBtn = make("TextButton", {
    Text = "–", TextSize = 16, TextColor3 = T.text, Font = CurFont,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -60, 0, 0), Size = UDim2.new(0, 30, 1, 0),
}, titleBar)
table.insert(allTextObjs, {minBtn, "normal"})

local closeBtn = make("TextButton", {
    Text = "×", TextSize = 18, TextColor3 = T.text, Font = CurFont,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -30, 0, 0), Size = UDim2.new(0, 30, 1, 0),
}, titleBar)
table.insert(allTextObjs, {closeBtn, "normal"})

-- Content area
local content = make("Frame", {
    Size             = UDim2.new(1, 0, 1, -30),
    Position         = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
}, main)

-- Sidebar
local sidebar = make("Frame", {
    Size             = UDim2.new(0, 110, 1, 0),
    BackgroundColor3 = T.panel2,
    BorderSizePixel  = 0,
}, content)
stroke(sidebar, T.border)

local sideScroll = make("ScrollingFrame", {
    Size                   = UDim2.new(1, 0, 1, -8),
    Position               = UDim2.new(0, 0, 0, 4),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ScrollBarThickness     = 2,
    ScrollBarImageColor3   = T.accent,
    CanvasSize             = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
}, sidebar)
table.insert(scrollFrames, sideScroll)
make("UIListLayout", {
    FillDirection      = Enum.FillDirection.Vertical,
    Padding            = UDim.new(0, 2),
    HorizontalAlignment= Enum.HorizontalAlignment.Center,
}, sideScroll)

-- Page area
local pageArea = make("Frame", {
    Size             = UDim2.new(1, -110, 1, 0),
    Position         = UDim2.new(0, 110, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
}, content)

local TAB_NAMES = {"Combat","Player","Visuals","Misc","Teleports","Settings"}
local tabBtns   = {}
local pages     = {}

local function makeTabBtn(name)
    local btn = make("TextButton", {
        Text             = name,
        TextSize         = 12,
        TextColor3       = T.text,
        Font             = CurFont,
        BackgroundColor3 = T.button,
        Size             = UDim2.new(0.9, 0, 0, 28),
        AutoButtonColor  = false,
    }, sideScroll)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, btn)
    local s = stroke(btn, T.border)
    table.insert(allTextObjs, {btn, "normal"})
    return btn, s
end

local function makePage()
    local scroll = make("ScrollingFrame", {
        Size                   = UDim2.new(1, -8, 1, -8),
        Position               = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = T.accent,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Visible                = false,
    }, pageArea)
    table.insert(scrollFrames, scroll)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6)}, scroll)
    make("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), PaddingTop=UDim.new(0,4)}, scroll)
    return scroll
end

for _, name in pairs(TAB_NAMES) do
    tabBtns[name] = {btn = makeTabBtn(name)}
    pages[name]   = makePage()
end

local function setTab(name)
    for n, data in pairs(tabBtns) do
        data.btn.BackgroundColor3 = (n == name) and T.panel or T.button
        if data.stroke then
            data.stroke.Color = (n == name) and T.accent or T.border
        end
    end
    for n, page in pairs(pages) do page.Visible = (n == name) end
end

-- redo makeTabBtn to capture stroke
for _, name in pairs(TAB_NAMES) do
    local btn, s = tabBtns[name].btn, stroke(tabBtns[name].btn, T.border)
    tabBtns[name].stroke = s
    btn.MouseButton1Click:Connect(function() setTab(name) end)
end

-- ── Widget builders ────────────────────────────────────────────────────────
local function makeGroup(page, title)
    -- Outer card: a vertical UIListLayout drives its height so AutomaticSize
    -- resolves reliably (the previous absolute-positioned version collapsed to
    -- ~0px, which the page's ScrollingFrame then clipped -> blank tabs).
    local frame = make("Frame", {
        BackgroundColor3    = T.panel,
        BorderSizePixel     = 0,
        AutomaticSize       = Enum.AutomaticSize.Y,
        Size                = UDim2.new(1, 0, 0, 0),
        ClipsDescendants    = false,
    }, page)
    make("UICorner", {CornerRadius = UDim.new(0, 5)}, frame)
    stroke(frame, T.border)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 0),
    }, frame)

    -- full-width accent line at the very top
    local al = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.accent,
        BorderSizePixel  = 0,
        LayoutOrder      = 0,
    }, frame)
    table.insert(accentFrames, al)

    -- header
    local header = make("TextLabel", {
        Text           = title,
        TextSize       = 12,
        TextColor3     = T.accent,
        Font           = CurFont,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder    = 1,
    }, frame)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, header)
    table.insert(allTextObjs, {header, "accent"})

    -- body that holds the rows
    local inner = make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1, 0, 0, 0),
        LayoutOrder            = 2,
    }, frame)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, inner)
    make("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,8), PaddingTop=UDim.new(0,2)}, inner)
    return inner
end

local function makeCheck(parent, label, key, cb)
    local row = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 23),
        BorderSizePixel = 0,
    }, parent)

    local dot = make("Frame", {
        Size             = UDim2.new(0, 9, 0, 9),
        Position         = UDim2.new(0, 0, 0.5, -4),
        BackgroundColor3 = S[key] and T.green or T.red,
        BorderSizePixel  = 0,
    }, row)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)

    local lbl = make("TextLabel", {
        Text           = label,
        TextSize       = 12,
        TextColor3     = T.text,
        Font           = CurFont,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 16, 0, 0),
        Size           = UDim2.new(1, -16, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    table.insert(allTextObjs, {lbl, "normal"})

    local btn = make("TextButton", {
        Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 2,
    }, row)

    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        dot.BackgroundColor3 = S[key] and T.green or T.red
        if cb then cb(S[key]) end
    end)
    return row, dot
end

local function makeSlider(parent, label, key, minV, maxV)
    local row = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        BorderSizePixel = 0,
    }, parent)

    local lbl = make("TextLabel", {
        Text = label .. ": " .. tostring(S[key]),
        TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 15),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    table.insert(allTextObjs, {lbl, "normal"})

    local track = make("Frame", {
        BackgroundColor3 = T.border,
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0, 20),
        BorderSizePixel = 0,
    }, row)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

    local pct  = math.clamp((S[key] - minV) / (maxV - minV), 0, 1)
    local fill = make("Frame", {
        BackgroundColor3 = T.accent,
        Size = UDim2.new(pct, 0, 1, 0),
        BorderSizePixel = 0,
    }, track)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    table.insert(accentFrames, fill)

    local handle = make("TextButton", {
        Text = "", BackgroundColor3 = T.text,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(pct, -6, 0.5, -6),
        BorderSizePixel = 0,
    }, track)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, handle)

    local dragging = false
    handle.MouseButton1Down:Connect(function() dragging = true end)
    track.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local np  = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minV + (maxV - minV) * np)
        S[key]       = val
        fill.Size     = UDim2.new(np, 0, 1, 0)
        handle.Position = UDim2.new(np, -6, 0.5, -6)
        lbl.Text     = label .. ": " .. tostring(val)
    end)
    return row
end

local function makeBtn(parent, label, h, cb)
    local btn = make("TextButton", {
        Text = label, TextSize = 13, TextColor3 = T.text, Font = CurFont,
        BackgroundColor3 = T.button,
        Size = UDim2.new(1, 0, 0, h or 28),
        AutoButtonColor = false,
    }, parent)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, btn)
    stroke(btn, T.border)
    table.insert(allTextObjs, {btn, "normal"})
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeLabel(parent, text, size)
    local l = make("TextLabel", {
        Text = text, TextSize = size or 11, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    table.insert(allTextObjs, {l, "normal"})
    return l
end

local function makeDD(parent, label, opts, key, cb)
    local con = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, parent)

    local lbl = make("TextLabel", {
        Text = label, TextSize = 12, TextColor3 = T.text, Font = CurFont,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.44, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, con)
    table.insert(allTextObjs, {lbl, "normal"})

    local sel = S[key] or opts[1]
    local mb  = make("TextButton", {
        Text = sel .. " ▾", TextSize = 11, TextColor3 = T.text, Font = CurFont,
        BackgroundColor3 = T.button,
        Size = UDim2.new(0.54, 0, 1, 0),
        Position = UDim2.new(0.46, 0, 0, 0),
        AutoButtonColor = false, ClipsDescendants = false,
    }, con)
    make("UICorner", {CornerRadius = UDim.new(0, 3)}, mb)
    stroke(mb, T.border)
    table.insert(allTextObjs, {mb, "normal"})

    local df = make("Frame", {
        BackgroundColor3 = T.panel,
        Size = UDim2.new(0.54, 0, 0, 0),
        Position = UDim2.new(0.46, 0, 1, 2),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex  = 10,
        ClipsDescendants = true,
    }, con)
    make("UICorner", {CornerRadius = UDim.new(0, 4)}, df)
    stroke(df, T.border)

    local ds = make("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, df)
    table.insert(scrollFrames, ds)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical}, ds)

    local open = false
    local function close()
        open = false; df.Visible = false; df.Size = UDim2.new(0.54, 0, 0, 0)
    end

    for _, opt in pairs(opts) do
        local ob = make("TextButton", {
            Text = opt, TextSize = 11, TextColor3 = T.text, Font = CurFont,
            BackgroundColor3 = T.button,
            Size = UDim2.new(1, 0, 0, 22), AutoButtonColor = false, ZIndex = 11,
        }, ds)
        table.insert(allTextObjs, {ob, "normal"})
        ob.MouseButton1Click:Connect(function()
            S[key] = opt; mb.Text = opt .. " ▾"; close()
            if cb then cb(opt) end
        end)
    end

    mb.MouseButton1Click:Connect(function()
        open = not open
        if open then
            local h2 = math.min(#opts * 22, 120)
            df.Size = UDim2.new(0.54, 0, 0, h2); df.Visible = true
        else close() end
    end)
    return con
end

-- ── Build Tabs ─────────────────────────────────────────────────────────────

-- COMBAT -----------------------------------------------------------------------
do
    local p = pages["Combat"]

    local hbGrp = makeGroup(p, "Hitbox")
    makeCheck(hbGrp, "Extend Hitbox", "ExtendHitbox")
    makeSlider(hbGrp, "Hitbox Size", "HitboxMultiplier", 1, 20)
    makeCheck(hbGrp, "Show Hitbox", "ShowHitbox", function(on)
        if not on then
            for _, b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes = {}
        end
    end)
    makeCheck(hbGrp, "M1 Expand", "M1Expand")
    makeSlider(hbGrp, "M1 Size", "M1Multiplier", 1, 15)

    local ultGrp = makeGroup(p, "Ultimate")
    makeCheck(ultGrp, "Auto Ult  [V]", "AutoUlt")

    local defGrp = makeGroup(p, "Defense")
    makeCheck(defGrp, "Inf Block",  "InfBlock")
    makeCheck(defGrp, "Auto Block", "AutoBlock", function(on)
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
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
                            task.wait(0.05)
                            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
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

    local aimGrp = makeGroup(p, "Aim")
    makeCheck(aimGrp, "Silent Aim", "SilentAim")

    local farmGrp = makeGroup(p, "Farm")
    makeCheck(farmGrp, "Auto Farm", "AutoFarm")
    makeSlider(farmGrp, "Farm Range", "AutoFarmRange", 20, 300)
end

-- PLAYER -----------------------------------------------------------------------
do
    local p = pages["Player"]

    local movGrp = makeGroup(p, "Movement")
    makeCheck(movGrp, "Fly",        "Fly")
    makeSlider(movGrp, "Fly Speed", "FlySpeed", 10, 300)
    makeCheck(movGrp, "Noclip", "Noclip", function(on)
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
    makeCheck(movGrp, "Speed Hack",   "SpeedHack")
    makeSlider(movGrp, "Walk Speed",  "WalkSpeed", 16, 250)
    makeCheck(movGrp, "Auto Sprint",  "AutoSprint")

    local survGrp = makeGroup(p, "Survival")
    makeCheck(survGrp, "God Mode",         "GodMode")
    makeCheck(survGrp, "Save System",      "SaveSystem")
    makeSlider(survGrp, "HP Threshold %",  "SaveThreshold", 1, 99)
    makeCheck(survGrp, "Instant Respawn",  "InstantRespawn")
    makeCheck(survGrp, "Invisible",        "Invisible")
end

-- VISUALS -----------------------------------------------------------------------
do
    local p = pages["Visuals"]
    local espGrp = makeGroup(p, "ESP")
    makeCheck(espGrp, "Player ESP", "ESP")
    local camGrp = makeGroup(p, "Camera")
    makeCheck(camGrp, "Inf Zoom", "InfZoom", function(on)
        if on then
            origZoom = player.CameraMaxZoomDistance
            player.CameraMaxZoomDistance = 9999
        else
            if origZoom then player.CameraMaxZoomDistance = origZoom end
        end
    end)
end

-- MISC -----------------------------------------------------------------------
do
    local p = pages["Misc"]

    local skinGrp = makeGroup(p, "Skins")
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
                    for _, sk in pairs(sf:GetChildren()) do
                        table.insert(built, kaiju.Name .. "/" .. sk.Name)
                    end
                end
            end
        end
        if #built > 1 then allSkins = built end
    end)
    makeDD(skinGrp, "Skin", allSkins, "SelectedSkin")
    makeBtn(skinGrp, "Apply Skin", 26, function()
        if S.SelectedSkin == "None" then return end
        pcall(function()
            local parts = S.SelectedSkin:split("/")
            if #parts < 2 then return end
            local kname, sname = parts[1], parts[2]
            local kf = player:FindFirstChild("Kaijus"); if not kf then return end
            local k  = kf:FindFirstChild(kname); if not k then return end
            local sf = k:FindFirstChild("Skins"); if not sf then return end
            local sk = sf:FindFirstChild(sname); if not sk then return end
            if sk:IsA("BoolValue") then sk.Value = true
            elseif sk:IsA("StringValue") then sk.Value = sname end
        end)
    end)

    local cdGrp = makeGroup(p, "Cooldown Bypass")
    makeCheck(cdGrp, "Bypass Cooldowns", "BypassCooldown")
end

-- TELEPORTS -----------------------------------------------------------------------
do
    local p = pages["Teleports"]
    local MAPS = {"Pit","Village","Abandoned City","Mountain","Final Valley","Desert"}

    local mapGrp = makeGroup(p, "Map Teleport")
    makeDD(mapGrp, "Map", MAPS, "SelectedMap")
    makeBtn(mapGrp, "Teleport", 28, function()
        pcall(function()
            local r = re(); if not r then return end
            r:FireServer("MapTeleport", S.SelectedMap)
        end)
    end)

    local ptpGrp = makeGroup(p, "Player Teleport")
    local ptpScroll = make("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 140),
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, ptpGrp)
    table.insert(scrollFrames, ptpScroll)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 3)}, ptpScroll)

    local function rebuildPTP()
        for _, c in pairs(ptpScroll:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        for _, p2 in pairs(Players:GetPlayers()) do
            if p2 ~= player then
                makeBtn(ptpScroll, "→ " .. p2.Name, 24, function()
                    pcall(function()
                        local ph = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart")
                        local mh = hrp()
                        if ph and mh then mh.CFrame = ph.CFrame + Vector3.new(3,0,0) end
                    end)
                end)
            end
        end
    end
    rebuildPTP()
    Players.PlayerAdded:Connect(rebuildPTP)
    Players.PlayerRemoving:Connect(rebuildPTP)
    makeBtn(ptpGrp, "Refresh", 24, rebuildPTP)
end

-- SETTINGS -----------------------------------------------------------------------
do
    local p = pages["Settings"]

    local kbGrp = makeGroup(p, "Keybinds")
    local kbLbl = makeLabel(kbGrp, "Toggle GUI: RightShift")
    makeBtn(kbGrp, "Set Toggle Key", 26, function()
        kbLbl.Text = "Press any key..."
        local conn; conn = UIS.InputBegan:Connect(function(i, gpe)
            if gpe then return end
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
            S.ToggleKey  = i.KeyCode
            kbLbl.Text   = "Toggle GUI: " .. i.KeyCode.Name
            conn:Disconnect()
        end)
    end)

    local scGrp = makeGroup(p, "Script")
    makeBtn(scGrp, "Disconnect All", 26, function()
        for _, c in pairs(Connections) do pcall(function() c:Disconnect() end) end
        for _, c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
        if noclipConn then pcall(function() noclipConn:Disconnect() end) end
        Connections, autoBlockConns, noclipConn = {}, {}, nil
    end)
    makeBtn(scGrp, "Close Hub", 26, function() gui:Destroy() end)

    local hubGrp = makeGroup(p, "Hub Appearance")

    -- Accent color swatches
    makeLabel(hubGrp, "Accent Color")
    local colorRow = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), BorderSizePixel = 0,
    }, hubGrp)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4)}, colorRow)
    for _, col in pairs(ACCENT_PRESETS) do
        local sw = make("TextButton", {
            Text = "", BackgroundColor3 = col,
            Size = UDim2.new(0, 18, 0, 18), AutoButtonColor = false,
        }, colorRow)
        make("UICorner", {CornerRadius = UDim.new(0, 3)}, sw)
        sw.MouseButton1Click:Connect(function() T.accent = col; refreshTheme() end)
    end

    -- Font picker
    makeLabel(hubGrp, "Font")
    local fontRow = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), BorderSizePixel = 0,
    }, hubGrp)
    make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3)}, fontRow)
    for i, fnt in pairs(FONTS) do
        local fb = make("TextButton", {
            Text = FONT_NAMES[i], TextSize = 10, TextColor3 = T.text, Font = fnt,
            BackgroundColor3 = T.button, Size = UDim2.new(0, 70, 0, 24), AutoButtonColor = false,
        }, fontRow)
        make("UICorner", {CornerRadius = UDim.new(0, 3)}, fb)
        stroke(fb, T.border)
        table.insert(allTextObjs, {fb, "normal"})
        fb.MouseButton1Click:Connect(function()
            CurFont = fnt
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    pcall(function() obj.Font = CurFont end)
                end
            end
        end)
    end

    makeLabel(hubGrp, "Drag title bar to move")
end

-- ── Feature Loops ──────────────────────────────────────────────────────────

-- Extend Hitbox: fires only on real M1 click, all attack slots
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

-- Invisible helper
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

-- Main Heartbeat
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)

    -- Speed hack with restore on toggle-off
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

    -- God mode
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

    -- Fly (CFrame-based, WASD + Space/Ctrl)
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

    -- Auto Sprint
    if S.AutoSprint then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        end)
    end

    -- Inf Block
    if S.InfBlock then
        pcall(function() local r = re(); if r then r:FireServer("InfBlock") end end)
    end

    -- Auto Ult (V key every 2s)
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

    -- Auto Farm
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

    -- Cooldown bypass (zero numeric values named with cooldown keywords)
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

    -- Instant Respawn
    if S.InstantRespawn then
        local h = hum()
        if h and h.Health <= 0 then
            pcall(function() player:LoadCharacter() end)
        end
    end

    -- Save System
    if S.SaveSystem then
        local h = hum()
        if h and h.MaxHealth > 0 then
            if (h.Health / h.MaxHealth * 100) <= S.SaveThreshold then
                pcall(function() local r = re(); if r then r:FireServer("Heal") end end)
            end
        end
    end

    -- Show Hitbox (event-driven)
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
                        box.Adornee          = root
                        box.Color3           = T.accent
                        box.LineThickness     = 0.05
                        box.SurfaceTransparency = 0.7
                        box.SurfaceColor3    = T.accent
                        box.Parent           = gui
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
            -- remove stale
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

    -- Auto Block proximity panic (supplement to anim hooks)
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
    main.Size = S.Minimized and UDim2.new(0, WIN_W, 0, 30) or UDim2.new(0, WIN_W, 0, WIN_H)
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

print("[Money/Free Hub] v2.0 | Toggle: " .. S.ToggleKey.Name)
