-- Money/Free Hub | Age of Titans | v3.9

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")

local player = Players.LocalPlayer
local UIS    = UserInputService

-- ── Theme (sidebar-style dark hub, matches reference image) ────────────────
local T = {
    bg        = Color3.fromRGB(21,  24,  32),   -- main content bg
    sidebar   = Color3.fromRGB(16,  18,  25),   -- left nav bg
    header    = Color3.fromRGB(16,  18,  25),   -- top bar bg
    row       = Color3.fromRGB(26,  30,  40),   -- row background
    rowAlt    = Color3.fromRGB(29,  33,  44),   -- hover
    tabsel    = Color3.fromRGB(30,  35,  47),   -- selected nav item
    track     = Color3.fromRGB(48,  53,  66),   -- toggle off / slider track
    border    = Color3.fromRGB(40,  44,  56),
    accent    = Color3.fromRGB(58,  130, 232),  -- blue toggle-on / accent
    text      = Color3.fromRGB(222, 226, 234),
    dim       = Color3.fromRGB(132, 138, 152),
}

local ACCENT_PRESETS = {
    Color3.fromRGB(58,  130, 232), Color3.fromRGB(45,  205, 190),
    Color3.fromRGB(80,  190, 110), Color3.fromRGB(210, 160, 60),
    Color3.fromRGB(150, 90,  220), Color3.fromRGB(225, 80,  90),
    Color3.fromRGB(225, 90,  165), Color3.fromRGB(220, 220, 220),
}

local FONTS      = {Enum.Font.GothamMedium, Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.Code, Enum.Font.RobotoMono}
local FONT_NAMES = {"GothamMed","Gotham","GothamBold","Code","Mono"}
local CurFont    = Enum.Font.GothamMedium

local allTextObjs, accentObjs = {}, {}
local function regText(o, role) table.insert(allTextObjs, {o, role or "normal"}) end
local function regAccent(o, prop) table.insert(accentObjs, {o, prop or "BackgroundColor3"}) end

local function refreshTheme()
    for _, pr in ipairs(allTextObjs) do
        pcall(function()
            local role = pr[2]
            if role=="accent" then pr[1].TextColor3=T.accent
            elseif role=="dim" then pr[1].TextColor3=T.dim
            elseif role~="skip" then pr[1].TextColor3=T.text end
            pr[1].Font = CurFont
        end)
    end
    for _, pr in ipairs(accentObjs) do pcall(function() pr[1][pr[2]] = T.accent end) end
end

-- ── State ──────────────────────────────────────────────────────────────────
local S = {
    -- Combat
    KillAura       = false, KillAuraRange  = 40,
    SilentAim      = false,
    ExtendHitbox   = false, HitboxSize     = 15,
    ShowHitbox     = false,
    M1Expand       = false, M1Size         = 8,
    ShowExpand     = false,
    InfBlock       = false, AutoBlock      = false,
    AutoUlt        = false, InstantUlt     = false,
    AutoFarm       = false, AutoFarmRange  = 80,
    AutoPlay       = false, AutoPlayRange  = 100,
    BypassCooldown = false,
    -- Player
    Fly            = false, FlySpeed       = 80,
    Noclip         = false,
    SpeedHack      = false, WalkSpeed      = 50,
    AutoSprint     = false,
    NoStun         = false,
    GodMode        = false,
    InfBar         = false,
    SaveSystem     = false, SaveThreshold  = 30,
    InstantRespawn = false,
    Invisible      = false,
    -- Visuals
    ESP            = false, InfZoom        = false,
    Fullbright     = false,
    -- Misc
    AntiAFK        = false,
    InfJump        = false, ClickTP        = false,
    Spinbot        = false, HideNames      = false,
    AntiFling      = false,
    -- Meta
    Minimized      = false,
    ToggleKey      = Enum.KeyCode.RightShift,
}

-- The float arg the game sends with each attack remote
local ATTACK_VALS = {
    4.4666666984558105, 4.4666666984558105, 4.4666666984558105,
    4.4666666984558105, 4.4666666984558105,
}

-- ── Internal timers / flags ────────────────────────────────────────────────
local speedOriginal, speedStateLast   = nil, false
local godOrigMax,    godStateLast     = nil, false
local invisOrigTrans, invisStateLast  = {}, false
local ultClock,  ultWasFull           = 0, false
local farmClock, kauraClk, cdClock    = 0, 0, 0
local autoPlayClock                   = 0
local infBarClock, noStunClock, noclipClock = 0, 0, 0
local espClock,  fbClock,  hnClock    = 0, 0, 0
local blockHoldEnd   = 0
local blockWasHeld   = false
local respawnClock   = 0
local saveActive, saveClock, savePos  = false, 0, Vector3.zero
local espBoxes        = {}
local showHitboxBoxes = {}
local showHitboxLast  = false
local autoBlockConns  = {}
local origZoom        = nil
local Connections     = {}
local flyStateLast    = false
local noclipLast      = false
local spinAngle       = 0
local expandPart, expandBox = nil, nil
local AB_KEYS      = {"Attack1","Attack2","Attack3","Attack4","Attack5","Lc1","Lc2","Lc3"}
local AB_HOLD_TIME = 2.0

-- ── Helpers ────────────────────────────────────────────────────────────────
local function chr() return player.Character end
local function hum() local c=chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()
    local c=chr(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end

local function re()
    local c = chr()
    if c then
        local r = c:FindFirstChild("RemoteEvent")
        if r and r:IsA("RemoteEvent") then return r end
    end
    local rs = game:GetService("ReplicatedStorage")
    return rs:FindFirstChild("RemoteEvent") or rs:FindFirstChildWhichIsA("RemoteEvent")
end

local function moveset()
    local pg=player:FindFirstChild("PlayerGui"); if not pg then return nil end
    local gi=pg:FindFirstChild("GameplayInterface"); if not gi then return nil end
    return gi:FindFirstChild("Moveset")
end
local function gameplayUI()
    local pg=player:FindFirstChild("PlayerGui"); if not pg then return nil end
    return pg:FindFirstChild("GameplayInterface")
end
local function diedRemote()
    local rs=game:GetService("ReplicatedStorage")
    local rem=rs:FindFirstChild("Remotes")
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

-- Nearest enemy root part — checks Players AND workspace NPC Models
local function nearestTargetRoot(maxD)
    local best, dist = nil, maxD or math.huge
    local mh = hrp(); if not mh then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local ph = p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            if ph then
                local d = (ph.Position - mh.Position).Magnitude
                if d < dist then best, dist = ph, d end
            end
        end
    end
    for _, obj in pairs(workspace:GetChildren()) do
        if obj ~= player.Character and obj:IsA("Model") then
            local h2   = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            if h2 and root and h2.Health > 0 then
                local d = (root.Position - mh.Position).Magnitude
                if d < dist then best, dist = root, d end
            end
        end
    end
    return best
end

local function pressBlockFor(t) blockHoldEnd = math.max(blockHoldEnd, tick()+t) end

-- ── Fly (Model-safe) ────────────────────────────────────────────────────────
local function startFly()
    pcall(function()
        local mh = hrp()
        if mh then mh.AssemblyLinearVelocity=Vector3.zero; mh.AssemblyAngularVelocity=Vector3.zero end
    end)
end
local function stopFly() end

-- ── Block ────────────────────────────────────────────────────────────────────
local function vimKey(down, key)
    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(down, key, false, game) end)
end
local function blockStop()
    local r = re(); if r then pcall(function() r:FireServer("BlockStop") end) end
end
local function tryBlock()
    vimKey(true, Enum.KeyCode.F)
    pcall(function()
        local c = chr(); if not c then return end
        for _, a in ipairs({"Blocking","Block","IsBlocking","Guard","Guarding","Parry"}) do
            if c:GetAttribute(a) ~= nil then c:SetAttribute(a, true) end
            local bv = c:FindFirstChild(a)
            if bv and bv:IsA("BoolValue") then bv.Value = true end
        end
    end)
end
local function tryUnblock()
    vimKey(false, Enum.KeyCode.F)
    pcall(function()
        local c = chr(); if not c then return end
        for _, a in ipairs({"Blocking","Block","IsBlocking","Guard","Guarding","Parry"}) do
            if c:GetAttribute(a) ~= nil then c:SetAttribute(a, false) end
            local bv = c:FindFirstChild(a)
            if bv and bv:IsA("BoolValue") then bv.Value = false end
        end
    end)
end

-- ── Hitbox spam helper ─────────────────────────────────────────────────────
local function spamHitbox(name, value, count, gap)
    task.spawn(function()
        for _ = 1, (count or 8) do
            local r = re()
            if r then pcall(function() r:FireServer(name, value) end) end
            task.wait(gap or 0.05)
        end
    end)
end

local function fireAttack(n)
    task.spawn(function()
        local r = re(); if not r then return end
        pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
        if S.ExtendHitbox then
            pcall(function() r:FireServer("Attack"..n.."Hitbox", S.HitboxSize) end)
        end
    end)
end

-- ── M1 Expand visual ──────────────────────────────────────────────────────
local gui -- forward-declared
local function ensureExpandVisual()
    local mh = hrp(); if not mh then return end
    if not expandPart or expandPart.Parent == nil then
        expandPart = Instance.new("Part")
        expandPart.Shape, expandPart.Anchored      = Enum.PartType.Ball, false
        expandPart.CanCollide, expandPart.CanQuery  = false, false
        expandPart.CanTouch, expandPart.Massless    = false, true
        expandPart.Transparency = 1
        expandPart.CFrame  = mh.CFrame
        expandPart.Parent  = mh.Parent
        local w = Instance.new("Weld")
        w.Part0, w.Part1, w.Parent = mh, expandPart, expandPart
        expandBox = Instance.new("SelectionBox")
        expandBox.Adornee, expandBox.Color3   = expandPart, T.accent
        expandBox.SurfaceColor3               = T.accent
        expandBox.SurfaceTransparency         = 0.85
        expandBox.LineThickness               = 0.03
        expandBox.Parent = gui
    end
    local sz = S.M1Size * 2
    expandPart.Size = Vector3.new(sz, sz, sz)
    expandBox.Color3, expandBox.SurfaceColor3 = T.accent, T.accent
end
local function destroyExpandVisual()
    if expandBox  then pcall(function() expandBox:Destroy()  end); expandBox  = nil end
    if expandPart then pcall(function() expandPart:Destroy() end); expandPart = nil end
end

-- ── Ult detection ──────────────────────────────────────────────────────────
local ULT_KEYS = {"ult","charge","energy","special","rage","meter","super","fury","awaken","transform"}
local function nameMatchesUlt(n)
    n = tostring(n):lower()
    for _,k in ipairs(ULT_KEYS) do if n:find(k) then return true end end
    return false
end
local function barFull(f) local sx,sy=f.Size.X.Scale,f.Size.Y.Scale
    if sx>=0.97 and sx>=sy then return true end
    if sy>=0.97 and sy>sx  then return true end
    return false
end
local function ultIsFull()
    local gi = gameplayUI(); if not gi then return false end
    for _, d in ipairs(gi:GetDescendants()) do
        if d:IsA("Frame") and nameMatchesUlt(d.Name) then
            for _, c in ipairs(d:GetChildren()) do
                if (c:IsA("Frame") or c:IsA("ImageLabel")) then
                    local cn = c.Name:lower()
                    if (cn:find("fill") or cn:find("bar") or cn:find("progress") or cn:find("amount"))
                       and barFull(c) then return true end
                end
            end
        end
    end
    for _, root in ipairs({chr(), player}) do
        if root then
            local ok = false
            pcall(function()
                for attr, v in pairs(root:GetAttributes()) do
                    if type(v)=="number" and nameMatchesUlt(attr) then
                        local mx = root:GetAttribute("Max"..attr) or root:GetAttribute(attr.."Max")
                        if type(mx)=="number" and mx>0 and v>=mx-0.01 then ok=true end
                    end
                end
            end)
            if ok then return true end
        end
    end
    return false
end
local function forceUltFull()
    local c = chr(); if not c then return end
    pcall(function()
        for attr, v in pairs(c:GetAttributes()) do
            if type(v)=="number" and nameMatchesUlt(attr) then
                local mx = c:GetAttribute("Max"..attr) or c:GetAttribute(attr.."Max")
                if type(mx)=="number" and mx>0 then c:SetAttribute(attr, mx) end
            end
        end
    end)
    local gi = gameplayUI(); if not gi then return end
    for _, d in ipairs(gi:GetDescendants()) do
        if d:IsA("Frame") and nameMatchesUlt(d.Name) then
            for _, c2 in ipairs(d:GetChildren()) do
                local cn = c2.Name:lower()
                if c2:IsA("Frame") and (cn:find("fill") or cn:find("bar") or cn:find("progress")) then
                    pcall(function() c2.Size = UDim2.new(1,0,c2.Size.Y.Scale,0) end)
                end
            end
        end
    end
end

-- ── Inf Bar ─────────────────────────────────────────────────────────────────
local HP_KEYS = {"hp","health","stamina","energy","life","shield","vitality","bar"}
local function nameMatchesHP(n)
    n = tostring(n):lower()
    for _,k in ipairs(HP_KEYS) do if n:find(k) then return true end end
    return false
end
local function forceBarFull()
    local h = hum()
    if h then pcall(function() h.Health = h.MaxHealth end) end
    local c = chr(); if not c then return end
    pcall(function()
        for attr, v in pairs(c:GetAttributes()) do
            if type(v)=="number" and nameMatchesHP(attr) then
                local mx = c:GetAttribute("Max"..attr) or c:GetAttribute(attr.."Max")
                if type(mx)=="number" and mx>0 then c:SetAttribute(attr, mx) end
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════════════════════════════════════
gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "MoneyFreeHub", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder   = 999
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local function make(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent=parent end
    return o
end
local function corner(p, r) return make("UICorner",{CornerRadius=UDim.new(0,r or 6)},p) end
local function stroke(p, color, thick)
    return make("UIStroke",{Color=color or T.border, Thickness=thick or 1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p)
end

local WIN_W, WIN_H = 560, 410
local HEAD_H, NAV_W = 34, 116

local main = make("Frame",{
    Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    BackgroundColor3=T.bg, BorderSizePixel=0, ClipsDescendants=true, Active=true,
},gui)
corner(main,9); stroke(main,Color3.fromRGB(46,52,66),1)

-- ── Header bar ──────────────────────────────────────────────────────────────
local header = make("Frame",{Size=UDim2.new(1,0,0,HEAD_H),BackgroundColor3=T.header,BorderSizePixel=0},main)
make("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.border,BorderSizePixel=0},header)
local dot = make("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,12,0.5,-4),
    BackgroundColor3=T.accent,BorderSizePixel=0},header); corner(dot,4); regAccent(dot)

local titleLbl = make("TextLabel",{
    Text="MONEY/FREE HUB  |  AGE OF TITANS  |  v3.9", TextSize=12, TextColor3=T.text, Font=Enum.Font.GothamBold,
    BackgroundTransparency=1, Position=UDim2.new(0,28,0,0),
    Size=UDim2.new(1,-90,1,0), TextXAlignment=Enum.TextXAlignment.Left,
},header)
regText(titleLbl,"normal")

local minBtn   = make("TextButton",{Text="—",TextSize=14,TextColor3=T.dim,Font=Enum.Font.GothamBold,
    BackgroundTransparency=1,Position=UDim2.new(1,-52,0,0),Size=UDim2.new(0,26,1,0)},header)
local closeBtn = make("TextButton",{Text="✕",TextSize=14,TextColor3=T.dim,Font=Enum.Font.GothamBold,
    BackgroundTransparency=1,Position=UDim2.new(1,-26,0,0),Size=UDim2.new(0,26,1,0)},header)
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3=Color3.fromRGB(230,90,90) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3=T.dim end)

local body = make("Frame",{
    Size=UDim2.new(1,0,1,-HEAD_H),Position=UDim2.new(0,0,0,HEAD_H),
    BackgroundTransparency=1,BorderSizePixel=0,
},main)

-- ── Left nav sidebar ─────────────────────────────────────────────────────────
local nav = make("Frame",{Size=UDim2.new(0,NAV_W,1,0),BackgroundColor3=T.sidebar,BorderSizePixel=0},body)
make("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=T.border,BorderSizePixel=0},nav)
make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,4),
    HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},nav)
make("UIPadding",{PaddingTop=UDim.new(0,10)},nav)

-- ── Page area ────────────────────────────────────────────────────────────────
local pageArea = make("Frame",{
    Size=UDim2.new(1,-NAV_W,1,0),Position=UDim2.new(0,NAV_W,0,0),
    BackgroundTransparency=1,BorderSizePixel=0,
},body)

local TAB_NAMES = {"Combat","Player","Visuals","Misc","Settings"}
local TAB_ICONS = {Combat="⚔",Player="◉",Visuals="◎",Misc="▦",Settings="⚙"}
local tabBtns, pages = {}, {}

local function makeNavBtn(name)
    local btn = make("TextButton",{
        BackgroundColor3=T.tabsel, BackgroundTransparency=1,
        Size=UDim2.new(1,-12,0,30), AutoButtonColor=false, Text="",
    },nav)
    corner(btn,6)
    local sel = make("Frame",{Size=UDim2.new(0,3,0.62,0),Position=UDim2.new(0,0,0.19,0),
        BackgroundColor3=T.accent,BorderSizePixel=0,Visible=false},btn)
    corner(sel,2); regAccent(sel)
    local ico = make("TextLabel",{Text=TAB_ICONS[name] or "•",TextSize=14,TextColor3=T.dim,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        Position=UDim2.new(0,12,0,0),Size=UDim2.new(0,20,1,0),
        TextXAlignment=Enum.TextXAlignment.Center},btn)
    local lbl = make("TextLabel",{Text=name,TextSize=12,TextColor3=T.dim,Font=Enum.Font.GothamMedium,
        BackgroundTransparency=1,Position=UDim2.new(0,36,0,0),Size=UDim2.new(1,-40,1,0),
        TextXAlignment=Enum.TextXAlignment.Left},btn)
    regText(lbl,"skip"); regText(ico,"skip")
    return {btn=btn,sel=sel,ico=ico,lbl=lbl}
end

local function makePage()
    local sf = make("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,
        ScrollBarThickness=3,ScrollBarImageColor3=T.accent,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    },pageArea)
    regAccent(sf,"ScrollBarImageColor3")
    make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,5),
        SortOrder=Enum.SortOrder.LayoutOrder},sf)
    make("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,12),
        PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)},sf)
    return sf
end

for _,name in ipairs(TAB_NAMES) do
    tabBtns[name] = makeNavBtn(name)
    pages[name]   = makePage()
end

local function setTab(name)
    for n,d in pairs(tabBtns) do
        local on = (n==name)
        d.btn.BackgroundTransparency = on and 0 or 1
        d.sel.Visible    = on
        d.lbl.TextColor3 = on and T.text or T.dim
        d.ico.TextColor3 = on and T.accent or T.dim
        pcall(function() pages[n].Visible = on end)
    end
end
for _,name in ipairs(TAB_NAMES) do
    tabBtns[name].btn.MouseButton1Click:Connect(function() setTab(name) end)
end

-- ── Section header ───────────────────────────────────────────────────────────
local function makeHeading(parent, text)
    local l = make("TextLabel",{Text=string.upper(text),TextSize=12,TextColor3=T.dim,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),
        TextXAlignment=Enum.TextXAlignment.Left},parent)
    regText(l,"dim")
    return l
end

-- ── Toggle row (pill switch) ─────────────────────────────────────────────────
local TW = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function makeToggle(parent, label, key, cb)
    local row = make("Frame",{BackgroundColor3=T.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,34)},parent)
    corner(row,6); stroke(row,T.border)
    local lbl = make("TextLabel",{Text=label,TextSize=13,TextColor3=T.text,Font=CurFont,
        BackgroundTransparency=1,Position=UDim2.new(0,12,0,0),
        Size=UDim2.new(1,-70,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)
    regText(lbl,"normal")
    local pill = make("Frame",{Size=UDim2.new(0,38,0,18),Position=UDim2.new(1,-50,0.5,-9),
        BackgroundColor3=S[key] and T.accent or T.track,BorderSizePixel=0},row)
    corner(pill,9)
    if S[key] then regAccent(pill) end
    local knob = make("Frame",{Size=UDim2.new(0,14,0,14),
        Position=S[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
        BackgroundColor3=Color3.fromRGB(240,242,247),BorderSizePixel=0},pill)
    corner(knob,7)
    local function render(on)
        TweenService:Create(pill,TW,{BackgroundColor3=on and T.accent or T.track}):Play()
        TweenService:Create(knob,TW,{Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
    end
    local btn = make("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=3},row)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]; render(S[key])
        if cb then cb(S[key]) end
    end)
    return row
end

-- ── Slider row (label + value box on right + track) ──────────────────────────
local function makeSlider(parent, label, key, minV, maxV, suffix)
    suffix = suffix or ""
    local row = make("Frame",{BackgroundColor3=T.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,46)},parent)
    corner(row,6); stroke(row,T.border)
    local lbl = make("TextLabel",{Text=label,TextSize=13,TextColor3=T.text,Font=CurFont,
        BackgroundTransparency=1,Position=UDim2.new(0,12,0,5),
        Size=UDim2.new(1,-70,0,16),TextXAlignment=Enum.TextXAlignment.Left},row)
    regText(lbl,"normal")
    local vbox = make("Frame",{Size=UDim2.new(0,40,0,16),Position=UDim2.new(1,-52,0,6),
        BackgroundColor3=T.track,BorderSizePixel=0},row); corner(vbox,4)
    local val = make("TextLabel",{Text=tostring(S[key])..suffix,TextSize=11,TextColor3=T.text,Font=CurFont,
        BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Center},vbox)
    regText(val,"normal")
    local bar = make("Frame",{BackgroundColor3=T.track,Size=UDim2.new(1,-24,0,6),
        Position=UDim2.new(0,12,1,-14),BorderSizePixel=0},row); corner(bar,3)
    local pct  = math.clamp((S[key]-minV)/(maxV-minV),0,1)
    local fill = make("Frame",{BackgroundColor3=T.accent,Size=UDim2.new(pct,0,1,0),BorderSizePixel=0},bar)
    corner(fill,3); regAccent(fill)
    local knob = make("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(pct,-6,0.5,-6),
        BackgroundColor3=Color3.fromRGB(240,242,247),BorderSizePixel=0,ZIndex=2},bar); corner(knob,6)
    local dragging = false
    local function set(px)
        local np = math.clamp((px-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local v  = math.floor(minV+(maxV-minV)*np+0.5)
        S[key]=v
        fill.Size=UDim2.new(np,0,1,0); knob.Position=UDim2.new(np,-6,0.5,-6)
        val.Text=tostring(v)..suffix
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;set(i.Position.X) end end)
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    table.insert(Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    table.insert(Connections, UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then set(i.Position.X) end end))
    return row
end

-- ── Button row ───────────────────────────────────────────────────────────────
local function makeButton(parent, label, cb)
    local btn = make("TextButton",{Text=label,TextSize=12,TextColor3=T.text,Font=CurFont,
        BackgroundColor3=T.row,Size=UDim2.new(1,0,0,30),AutoButtonColor=false},parent)
    corner(btn,6); stroke(btn,T.border)
    regText(btn,"normal")
    btn.MouseEnter:Connect(function() btn.BackgroundColor3=T.rowAlt end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=T.row end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeNote(parent, text)
    local l = make("TextLabel",{Text=text,TextSize=11,TextColor3=T.dim,Font=CurFont,
        BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),TextXAlignment=Enum.TextXAlignment.Left},parent)
    regText(l,"dim")
    return l
end

-- ── Auto Block wiring ────────────────────────────────────────────────────────
local function hookAutoBlockPlayer(p2)
    if p2==player then return end
    local function wire(kbFolder)
        for _,keyName in pairs(AB_KEYS) do
            local kv = kbFolder:FindFirstChild(keyName)
            if kv then
                local conn = kv.Changed:Connect(function()
                    if not S.AutoBlock then return end
                    local ph = p2.Character and (p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart)
                    local mh = hrp()
                    if ph and mh and (ph.Position-mh.Position).Magnitude < 120 then
                        pressBlockFor(AB_HOLD_TIME)
                    end
                end)
                table.insert(autoBlockConns,conn)
            end
        end
    end
    local kb = p2:FindFirstChild("Keybinds")
    if kb then wire(kb) end
    local ac = p2.ChildAdded:Connect(function(ch)
        if ch.Name=="Keybinds" then task.defer(function() wire(ch) end) end
    end)
    table.insert(autoBlockConns,ac)
end
local function startAutoBlock()
    for _,c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
    autoBlockConns = {}
    for _,p2 in pairs(Players:GetPlayers()) do hookAutoBlockPlayer(p2) end
    table.insert(autoBlockConns, Players.PlayerAdded:Connect(hookAutoBlockPlayer))
end
local function stopAutoBlock()
    for _,c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
    autoBlockConns = {}; blockHoldEnd = 0
end

-- ── Misc helpers ─────────────────────────────────────────────────────────────
local function applyFullbright()
    pcall(function()
        Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e9
        Lighting.GlobalShadows=false
        Lighting.Ambient=Color3.fromRGB(160,160,160)
        Lighting.OutdoorAmbient=Color3.fromRGB(160,160,160)
    end)
end
local function fpsBoost()
    pcall(function()
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
               or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false
            elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency=1
            elseif v:IsA("MeshPart") then v.Material=Enum.Material.Plastic end
        end
        Lighting.GlobalShadows=false
        local terr=workspace:FindFirstChildOfClass("Terrain")
        if terr then terr.WaterWaveSize=0;terr.WaterWaveSpeed=0;terr.WaterReflectance=0 end
        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    end)
end
local function rejoinServer() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end
local function serverHop()
    task.spawn(function()
        local body2
        pcall(function()
            local url=("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            if game.HttpGetAsync then body2=game:HttpGetAsync(url)
            elseif game.HttpGet  then body2=game:HttpGet(url) end
        end)
        if not body2 then rejoinServer();return end
        local ok,data=pcall(function() return game:GetService("HttpService"):JSONDecode(body2) end)
        if ok and data and data.data then
            for _,sv in ipairs(data.data) do
                if sv.playing and sv.maxPlayers and sv.playing<sv.maxPlayers and sv.id~=game.JobId then
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,sv.id,player) end)
                    return
                end
            end
        end
        rejoinServer()
    end)
end
local function resetCharacter()
    pcall(function()
        local h=hum()
        if h then h.Health=0 else local c=chr();if c then c:BreakJoints() end end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- BUILD PAGES
-- ════════════════════════════════════════════════════════════════════════════

-- COMBAT
do
    local P = pages["Combat"]
    makeHeading(P,"Combat")
    makeToggle(P,"Kill Aura","KillAura")
    makeSlider(P,"Kill Aura Range","KillAuraRange",10,150)
    makeToggle(P,"Silent Aim","SilentAim")
    makeToggle(P,"Extend Hitbox","ExtendHitbox")
    makeSlider(P,"Hitbox Size","HitboxSize",1,60)
    makeToggle(P,"Show Hitbox","ShowHitbox",function(on)
        if not on then
            for _,b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes={}
        end
    end)
    makeToggle(P,"M1 Expand","M1Expand")
    makeSlider(P,"M1 Size","M1Size",1,40)
    makeToggle(P,"Show Expand","ShowExpand",function(on) if not on then destroyExpandVisual() end end)
    makeToggle(P,"Infinite Block","InfBlock")
    makeToggle(P,"Auto Block","AutoBlock",function(on) if on then startAutoBlock() else stopAutoBlock() end end)
    makeToggle(P,"Auto Ultimate","AutoUlt")
    makeToggle(P,"Instant Ultimate","InstantUlt")
    makeToggle(P,"Auto Play","AutoPlay")
    makeSlider(P,"Auto Play Range","AutoPlayRange",20,300)
    makeToggle(P,"Auto Farm","AutoFarm")
    makeSlider(P,"Auto Farm Range","AutoFarmRange",20,300)
    makeToggle(P,"Bypass Cooldown","BypassCooldown")
end

-- PLAYER
do
    local P = pages["Player"]
    makeHeading(P,"Movement")
    makeToggle(P,"Fly","Fly")
    makeSlider(P,"Fly Speed","FlySpeed",10,300)
    makeNote(P,"W/A/S/D · Space = up · Ctrl = down")
    makeToggle(P,"Noclip","Noclip")
    makeToggle(P,"Speed Hack","SpeedHack")
    makeSlider(P,"Walk Speed","WalkSpeed",16,250)
    makeToggle(P,"Auto Sprint","AutoSprint")
    makeToggle(P,"No Stun","NoStun")
    makeHeading(P,"Survival")
    makeToggle(P,"God Mode","GodMode")
    makeToggle(P,"Infinite Bar (HP)","InfBar")
    makeToggle(P,"Save System","SaveSystem")
    makeSlider(P,"HP Threshold","SaveThreshold",1,99,"%")
    makeToggle(P,"Instant Respawn","InstantRespawn")
    makeToggle(P,"Invisible","Invisible")
end

-- VISUALS
do
    local P = pages["Visuals"]
    makeHeading(P,"Visuals")
    makeToggle(P,"Player ESP","ESP")
    makeToggle(P,"Infinite Zoom","InfZoom",function(on)
        if on then origZoom=player.CameraMaxZoomDistance; player.CameraMaxZoomDistance=9999
        else if origZoom then player.CameraMaxZoomDistance=origZoom end end
    end)
    makeToggle(P,"Fullbright","Fullbright",function(on) if on then applyFullbright() end end)
end

-- MISC
do
    local P = pages["Misc"]
    makeHeading(P,"Utility")
    makeToggle(P,"Anti-AFK","AntiAFK")
    makeToggle(P,"Infinite Jump","InfJump")
    makeToggle(P,"Click TP  [T]","ClickTP")
    makeToggle(P,"Spinbot","Spinbot")
    makeToggle(P,"Hide Names","HideNames")
    makeToggle(P,"Anti-Fling","AntiFling")
    makeHeading(P,"Server")
    makeButton(P,"FPS Boost",fpsBoost)
    makeButton(P,"Reset Character",resetCharacter)
    makeButton(P,"Rejoin Server",rejoinServer)
    makeButton(P,"Server Hop",serverHop)

    makeHeading(P,"Teleport To Player")
    local list = make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,120),ScrollBarThickness=3,ScrollBarImageColor3=T.accent,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},P)
    regAccent(list,"ScrollBarImageColor3")
    make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,4)},list)
    local function rebuild()
        for _,c in pairs(list:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        for _,p2 in pairs(Players:GetPlayers()) do
            if p2~=player then
                makeButton(list,p2.Name,function()
                    pcall(function()
                        local ph=p2.Character and (p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart)
                        local mh=hrp()
                        if ph and mh then mh.CFrame=ph.CFrame+Vector3.new(3,0,0) end
                    end)
                end)
            end
        end
    end
    rebuild()
    Players.PlayerAdded:Connect(rebuild); Players.PlayerRemoving:Connect(rebuild)
    makeButton(P,"Refresh List",rebuild)
end

-- SETTINGS
do
    local P = pages["Settings"]
    makeHeading(P,"Keybinds")
    local kbBtn
    kbBtn = makeButton(P,"Toggle Key: RightShift",function()
        kbBtn.Text="Press any key..."
        local conn; conn=UIS.InputBegan:Connect(function(i,gpe)
            if gpe then return end
            if i.UserInputType~=Enum.UserInputType.Keyboard then return end
            S.ToggleKey=i.KeyCode; kbBtn.Text="Toggle Key: "..i.KeyCode.Name
            conn:Disconnect()
        end)
    end)

    makeHeading(P,"Appearance")
    makeNote(P,"Accent Color")
    local cr = make("Frame",{BackgroundColor3=T.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,32)},P)
    corner(cr,6); stroke(cr,T.border)
    make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),
        VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center},cr)
    for _,col in ipairs(ACCENT_PRESETS) do
        local sw=make("TextButton",{Text="",BackgroundColor3=col,Size=UDim2.new(0,18,0,18),AutoButtonColor=false},cr)
        corner(sw,4)
        sw.MouseButton1Click:Connect(function() T.accent=col;refreshTheme() end)
    end

    makeNote(P,"Font")
    local fr = make("Frame",{BackgroundColor3=T.row,BorderSizePixel=0,Size=UDim2.new(1,0,0,30)},P)
    corner(fr,6); stroke(fr,T.border)
    make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),
        VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center},fr)
    for i,fnt in ipairs(FONTS) do
        local fb=make("TextButton",{Text=FONT_NAMES[i],TextSize=10,TextColor3=T.text,Font=fnt,
            BackgroundColor3=T.track,Size=UDim2.new(0,58,0,20),AutoButtonColor=false},fr)
        corner(fb,4)
        fb.MouseButton1Click:Connect(function() CurFont=fnt; refreshTheme() end)
    end

    makeHeading(P,"Script")
    makeButton(P,"Disconnect All",function()
        for _,c in pairs(Connections)    do pcall(function() c:Disconnect() end) end
        for _,c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
        stopFly(); destroyExpandVisual()
        Connections,autoBlockConns={},{};S.Fly,S.Noclip=false,false
    end)
    makeButton(P,"Close Hub",function() destroyExpandVisual();gui:Destroy() end)
end

-- ── Input: keys 1-5 and M1 ───────────────────────────────────────────────────
local ATTACK_KEYS = {
    [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,
    [Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5,
}

table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end

    if i.UserInputType == Enum.UserInputType.Keyboard then
        local n = ATTACK_KEYS[i.KeyCode]
        if n then
            if S.ExtendHitbox then spamHitbox("Attack"..n.."Hitbox", S.HitboxSize, 6, 0.05) end
            if S.BypassCooldown then fireAttack(n) end
        end
        if i.KeyCode==Enum.KeyCode.T and S.ClickTP then
            pcall(function()
                local m=player:GetMouse(); local mh=hrp()
                if m and mh and m.Hit then mh.CFrame=CFrame.new(m.Hit.Position+Vector3.new(0,4,0)) end
            end)
        end
        return
    end

    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if S.ExtendHitbox then for n=1,5 do spamHitbox("Attack"..n.."Hitbox",S.HitboxSize,4,0.05) end end
    if S.M1Expand then for n=1,3 do spamHitbox("Lc"..n.."Hitbox",S.M1Size,4,0.05) end end
    if S.SilentAim then
        pcall(function()
            local tgt=nearest(300); if not tgt then return end
            for n=1,5 do spamHitbox("Attack"..n.."Hitbox",math.max(S.HitboxSize,25),4,0.05) end
            for n=1,3 do spamHitbox("Lc"..n.."Hitbox",math.max(S.HitboxSize,25),4,0.05) end
        end)
    end
end))

-- Infinite Jump
table.insert(Connections, UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local h=hum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end))

-- Anti-AFK
pcall(function()
    player.Idled:Connect(function()
        if not S.AntiAFK then return end
        local vu=game:GetService("VirtualUser")
        vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end)
end)

local function doInvisible(state)
    pcall(function()
        local c=chr(); if not c then return end
        if state then
            for _,pt in pairs(c:GetDescendants()) do
                if pt:IsA("BasePart") or pt:IsA("Decal") then
                    if not invisOrigTrans[pt] then invisOrigTrans[pt]=pt.Transparency end
                    pt.Transparency=1
                end
            end
        else
            for pt,t in pairs(invisOrigTrans) do
                pcall(function() if pt and pt.Parent then pt.Transparency=t end end)
            end
            invisOrigTrans={}
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- MAIN LOOP  (heavy ops throttled to fix lag)
-- ════════════════════════════════════════════════════════════════════════════
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)

    -- Speed Hack
    if S.SpeedHack ~= speedStateLast then
        speedStateLast = S.SpeedHack
        local h=hum()
        if S.SpeedHack then if h then speedOriginal=h.WalkSpeed end
        else if h and speedOriginal then h.WalkSpeed=speedOriginal end; speedOriginal=nil end
    end
    if S.SpeedHack then pcall(function() local h=hum();if h then h.WalkSpeed=S.WalkSpeed end end) end

    -- God Mode
    if S.GodMode ~= godStateLast then
        godStateLast=S.GodMode
        local h=hum()
        if h then
            if S.GodMode then godOrigMax=h.MaxHealth;h.MaxHealth=math.huge;h.Health=math.huge
            else if godOrigMax then h.MaxHealth=godOrigMax;h.Health=godOrigMax end;godOrigMax=nil end
        end
    end
    if S.GodMode then pcall(function() local h=hum();if h then h.Health=math.huge end end) end

    -- Inf Bar (throttled 0.3s — was every frame = laggy)
    if S.InfBar then
        infBarClock = infBarClock + dt
        if infBarClock >= 0.3 then infBarClock=0; forceBarFull() end
    end

    -- Instant Ult (throttled)
    if S.InstantUlt then
        ultClock = ultClock + dt
        if ultClock >= 0.2 then ultClock=0; forceUltFull() end
    end

    -- No Stun (throttled 0.15s)
    if S.NoStun then
        noStunClock = noStunClock + dt
        if noStunClock >= 0.15 then
            noStunClock = 0
            pcall(function()
                local c=chr()
                if c then
                    for _,a in ipairs({"Stun","Stunned","Ragdoll","Ragdolled","Frozen","Knockback","Staggered","NoMove","Disabled"}) do
                        if c:GetAttribute(a)~=nil then c:SetAttribute(a,false) end
                    end
                    local mh=c:FindFirstChild("HumanoidRootPart")
                    if mh and mh.Anchored then mh.Anchored=false end
                end
                local h=hum()
                if h then
                    h.PlatformStand=false; h.Sit=false
                    if h.WalkSpeed<=0.5 then h.WalkSpeed=(S.SpeedHack and S.WalkSpeed) or 16 end
                    if h.JumpPower~=nil and h.JumpPower<=0.5 then h.JumpPower=50 end
                end
            end)
        end
    end

    -- Invisible
    if S.Invisible ~= invisStateLast then invisStateLast=S.Invisible; doInvisible(S.Invisible) end

    -- FLY (Model-safe direct CFrame)
    if S.Fly ~= flyStateLast then
        flyStateLast = S.Fly
        if S.Fly then startFly() else stopFly() end
    end
    if S.Fly then
        pcall(function()
            local c  = chr();  if not c  then return end
            local mh = hrp();  if not mh then return end
            local cam = workspace.CurrentCamera.CFrame
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cam.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cam.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cam.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cam.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            mh.AssemblyLinearVelocity  = Vector3.zero
            mh.AssemblyAngularVelocity = Vector3.zero
            if dir.Magnitude > 0 then
                local move = dir.Unit * S.FlySpeed * dt
                if c.PrimaryPart then c:SetPrimaryPartCFrame(c.PrimaryPart.CFrame + move)
                else mh.CFrame = mh.CFrame + move end
            end
        end)
    end

    -- Noclip (throttled 0.2s)
    if S.Noclip then
        noclipLast=true
        noclipClock = noclipClock + dt
        if noclipClock >= 0.2 then
            noclipClock = 0
            local c=chr()
            if c then for _,pt in pairs(c:GetDescendants()) do
                if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide=false end
            end end
        end
    elseif noclipLast then
        noclipLast=false
        local c=chr()
        if c then for _,pt in pairs(c:GetDescendants()) do
            if pt:IsA("BasePart") and pt.Name~="HumanoidRootPart" then pt.CanCollide=true end
        end end
    end

    -- Auto Sprint
    if S.AutoSprint then
        pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true,Enum.KeyCode.LeftShift,false,game) end)
    end

    -- Spinbot
    if S.Spinbot then
        pcall(function()
            local mh=hrp(); if not mh then return end
            spinAngle=spinAngle+dt*12
            mh.CFrame=CFrame.new(mh.Position)*CFrame.Angles(0,spinAngle,0)
        end)
    end

    -- Anti-Fling
    if S.AntiFling then
        pcall(function()
            local mh=hrp(); if not mh then return end
            mh.AssemblyAngularVelocity=Vector3.zero
            if mh.AssemblyLinearVelocity.Magnitude>200 then mh.AssemblyLinearVelocity=Vector3.zero end
        end)
    end

    -- Block manager
    do
        local want = S.InfBlock or (S.AutoBlock and tick() < blockHoldEnd)
        if want then tryBlock(); blockWasHeld = true
        elseif blockWasHeld then blockWasHeld=false; tryUnblock(); blockStop() end
    end

    -- Auto Ult (rising edge)
    if S.AutoUlt then
        ultClock = ultClock + dt
        if ultClock >= 0.3 then
            ultClock = 0
            local full = false; pcall(function() full=ultIsFull() end)
            if full and not ultWasFull then
                ultWasFull = true
                task.spawn(function()
                    pcall(function()
                        local vim=game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true, Enum.KeyCode.V,false,game)
                        task.wait(0.08)
                        vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                    end)
                end)
            elseif not full then ultWasFull=false end
        end
    elseif not S.InstantUlt then
        ultClock=0; ultWasFull=false
    end

    -- Kill Aura
    if S.KillAura then
        kauraClk = kauraClk + dt
        if kauraClk >= 0.25 then
            kauraClk = 0
            pcall(function()
                local tgt = nearestTargetRoot(S.KillAuraRange); if not tgt then return end
                local mh  = hrp();                               if not mh  then return end
                local diff = tgt.Position - mh.Position
                if diff.Magnitude > 10 then
                    local snap = tgt.Position - diff.Unit * 6 + Vector3.new(0, 2, 0)
                    local c = chr()
                    if c and c.PrimaryPart then c:SetPrimaryPartCFrame(CFrame.new(snap))
                    else mh.CFrame = CFrame.new(snap) end
                end
                local r = re(); if not r then return end
                for n=1,5 do
                    pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
                    pcall(function() r:FireServer("Attack"..n.."Hitbox", S.HitboxSize) end)
                end
            end)
        end
    end

    -- Auto Farm
    if S.AutoFarm then
        farmClock = farmClock + dt
        if farmClock >= 0.4 then
            farmClock = 0
            pcall(function()
                local tgt=nearest(S.AutoFarmRange); if not tgt then return end
                local mh=hrp();                    if not mh  then return end
                local ph=tgt.Character and (tgt.Character:FindFirstChild("HumanoidRootPart") or tgt.Character.PrimaryPart)
                if not ph then return end
                local c=chr()
                if c and c.PrimaryPart then c:SetPrimaryPartCFrame(ph.CFrame + ph.CFrame.LookVector*-3)
                else mh.CFrame = ph.CFrame + ph.CFrame.LookVector*-3 end
                local r = re(); if not r then return end
                for n=1,5 do
                    pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
                    pcall(function() r:FireServer("Attack"..n.."Hitbox", S.HitboxSize) end)
                end
                for n=1,3 do pcall(function() r:FireServer("Lc"..n.."Hitbox", S.HitboxSize) end) end
                task.spawn(function()
                    pcall(function()
                        local vim=game:GetService("VirtualInputManager")
                        local vp=workspace.CurrentCamera.ViewportSize
                        vim:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,0)
                        vim:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,0)
                        task.wait(0.1)
                        if ultIsFull() then
                            vim:SendKeyEvent(true, Enum.KeyCode.V,false,game)
                            task.wait(0.05)
                            vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                        end
                    end)
                end)
            end)
        end
    end

    -- Auto Play
    if S.AutoPlay then
        autoPlayClock = autoPlayClock + dt
        if autoPlayClock >= 0.35 then
            autoPlayClock = 0
            pcall(function()
                local tgt = nearestTargetRoot(S.AutoPlayRange); if not tgt then return end
                local mh  = hrp();                               if not mh  then return end
                local dist = (tgt.Position - mh.Position).Magnitude
                if dist > 14 then
                    local h = hum()
                    if h then h:MoveTo(tgt.Position)
                    else
                        local c   = chr()
                        local dir = (tgt.Position - mh.Position).Unit
                        local step = math.min(dist - 10, 20)
                        if c and c.PrimaryPart then c:SetPrimaryPartCFrame(c.PrimaryPart.CFrame + dir * step)
                        else mh.CFrame = mh.CFrame + dir * step end
                    end
                else
                    local r = re(); if not r then return end
                    for n=1,5 do
                        pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
                        pcall(function() r:FireServer("Attack"..n.."Hitbox", S.HitboxSize) end)
                    end
                    task.spawn(function()
                        pcall(function()
                            local vim=game:GetService("VirtualInputManager")
                            local vp=workspace.CurrentCamera.ViewportSize
                            vim:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,0)
                            vim:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,0)
                        end)
                    end)
                    if ultIsFull() then
                        task.spawn(function()
                            pcall(function()
                                local vim=game:GetService("VirtualInputManager")
                                vim:SendKeyEvent(true, Enum.KeyCode.V,false,game)
                                task.wait(0.05)
                                vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                            end)
                        end)
                    end
                end
            end)
        end
    end

    -- Bypass Cooldown
    if S.BypassCooldown then
        cdClock = cdClock + dt
        if cdClock >= 0.1 then
            cdClock = 0
            pcall(function()
                local ms=moveset(); if not ms then return end
                for n=1,5 do
                    local atk=ms:FindFirstChild("Attack"..n)
                    if atk then
                        local cd=atk:FindFirstChild("Cooldown")
                        if cd then
                            if cd:IsA("GuiObject") then cd.Size=UDim2.new(0,0,0,0);cd.Visible=false end
                            local txt=cd:FindFirstChildWhichIsA("TextLabel")
                            if txt then txt.Text="" end
                        end
                        if atk:GetAttribute("Cooldown")~=nil then atk:SetAttribute("Cooldown",0) end
                    end
                end
            end)
        end
    end

    -- Hide Names
    if S.HideNames then
        hnClock=hnClock+dt
        if hnClock>=1 then
            hnClock=0
            pcall(function()
                for _,p2 in pairs(Players:GetPlayers()) do
                    if p2~=player and p2.Character then
                        local h=p2.Character:FindFirstChildOfClass("Humanoid")
                        if h then h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
                    end
                end
            end)
        end
    end

    -- Fullbright refresh
    if S.Fullbright then
        fbClock=fbClock+dt; if fbClock>=1 then fbClock=0;applyFullbright() end
    end

    -- M1 Expand visual
    if S.ShowExpand and S.M1Expand then ensureExpandVisual()
    elseif expandPart then destroyExpandVisual() end

    -- Instant Respawn
    if S.InstantRespawn then
        local h=hum()
        if h and h.Health<=0 then
            respawnClock=respawnClock+dt
            if respawnClock>=0.5 then
                respawnClock=0
                pcall(function() local d=diedRemote();if d then d:FireServer("Real",3.8333332538604736) end end)
            end
        else respawnClock=0 end
    end

    -- Save System
    if S.SaveSystem then
        local h,mh=hum(),hrp()
        if h and mh and h.MaxHealth>0 then
            if saveActive then
                saveClock=saveClock+dt
                mh.CFrame=CFrame.new(savePos+Vector3.new(0,500,0))
                mh.AssemblyLinearVelocity=Vector3.zero
                if saveClock>=4 or (h.Health/h.MaxHealth*100)>S.SaveThreshold+20 then
                    saveActive=false;saveClock=0
                    mh.CFrame=CFrame.new(savePos+Vector3.new(0,8,0))
                end
            elseif (h.Health/h.MaxHealth*100)<=S.SaveThreshold then
                savePos=mh.Position;saveActive=true;saveClock=0
            end
        end
    end

    -- Show Hitbox
    if S.ShowHitbox ~= showHitboxLast then
        showHitboxLast=S.ShowHitbox
        if not S.ShowHitbox then
            for _,b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes={}
        else
            for _,p2 in pairs(Players:GetPlayers()) do
                if p2~=player and p2.Character then
                    local root=p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                    if root then
                        local box=Instance.new("SelectionBox")
                        box.Adornee=root; box.Color3=T.accent; box.LineThickness=0.05
                        box.SurfaceTransparency=0.7; box.SurfaceColor3=T.accent; box.Parent=gui
                        table.insert(showHitboxBoxes,box)
                    end
                end
            end
        end
    end

    -- ESP
    if S.ESP then
        espClock=espClock+dt
        if espClock>=0.5 then
            espClock=0
            for name,data in pairs(espBoxes) do
                if not Players:FindFirstChild(name) then
                    pcall(function() data.bill:Destroy() end); espBoxes[name]=nil
                end
            end
            for _,p2 in pairs(Players:GetPlayers()) do
                if p2~=player and p2.Character then
                    local root=p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                    if root and not espBoxes[p2.Name] then
                        local bill=Instance.new("BillboardGui")
                        bill.Size=UDim2.new(0,80,0,28); bill.AlwaysOnTop=true
                        bill.StudsOffset=Vector3.new(0,3,0); bill.Adornee=root; bill.Parent=gui
                        make("TextLabel",{Text=p2.Name,TextSize=13,TextColor3=T.accent,Font=CurFont,
                            BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
                            TextStrokeTransparency=0,TextStrokeColor3=Color3.new(0,0,0)},bill)
                        espBoxes[p2.Name]={bill=bill}
                    end
                end
            end
        end
    else
        if next(espBoxes) then
            for _,data in pairs(espBoxes) do pcall(function() data.bill:Destroy() end) end
            espBoxes={}
        end
    end

end))

-- ── Drag ─────────────────────────────────────────────────────────────────────
do
    local dragging,dragStart,startPos=false,nil,nil
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true;dragStart=i.Position;startPos=main.Position end
    end)
    header.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    table.insert(Connections,UIS.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                                startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end))
end

-- ── Minimize / Close ─────────────────────────────────────────────────────────
minBtn.MouseButton1Click:Connect(function()
    S.Minimized=not S.Minimized; body.Visible=not S.Minimized
    main.Size=S.Minimized and UDim2.new(0,WIN_W,0,HEAD_H) or UDim2.new(0,WIN_W,0,WIN_H)
end)
closeBtn.MouseButton1Click:Connect(function() destroyExpandVisual();gui:Destroy() end)

-- ── Toggle keybind ───────────────────────────────────────────────────────────
table.insert(Connections,UIS.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==S.ToggleKey then main.Visible=not main.Visible end
end))

-- ── Init ─────────────────────────────────────────────────────────────────────
setTab("Combat")
refreshTheme()
print("[Money/Free Hub] v3.9 | Toggle: "..S.ToggleKey.Name)
