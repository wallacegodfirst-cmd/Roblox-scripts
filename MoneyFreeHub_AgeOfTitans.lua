-- Money/Free Hub | Age of Titans | v4.0

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")

local player = Players.LocalPlayer
local UIS    = UserInputService

-- Theme (original v3.7/v3.8 style)
local T = {
    bg     = Color3.fromRGB(17,  18,  22),
    card   = Color3.fromRGB(23,  24,  29),
    tab    = Color3.fromRGB(22,  23,  28),
    tabsel = Color3.fromRGB(30,  32,  40),
    title  = Color3.fromRGB(14,  15,  18),
    border = Color3.fromRGB(38,  40,  50),
    accent = Color3.fromRGB(64,  110, 200),
    text   = Color3.fromRGB(215, 218, 225),
    dim    = Color3.fromRGB(120, 125, 140),
    fill   = Color3.fromRGB(40,  43,  52),
    check  = Color3.fromRGB(255, 255, 255),
}

-- State
local S = {
    KillAura       = false, KillAuraRange  = 40,
    SilentAim      = false,
    ExtendHitbox   = false, HitboxSize     = 15,
    ShowHitbox     = false,
    M1Expand       = false, M1Size         = 8,
    ShowExpand     = false,
    InfBlock       = false, AutoBlock      = false,
    AutoUlt        = false,
    AutoFarm       = false, AutoFarmRange  = 80,
    AutoPlay       = false, AutoPlayRange  = 100,
    BypassCooldown = false,
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
    ESP            = false, InfZoom        = false,
    Fullbright     = false,
    AntiAFK        = false,
    InfJump        = false, ClickTP        = false,
    Spinbot        = false, HideNames      = false,
    AntiFling      = false,
    Minimized      = false,
    ToggleKey      = Enum.KeyCode.RightShift,
}

local ATTACK_VALS = {
    4.4666666984558105, 4.4666666984558105, 4.4666666984558105,
    4.4666666984558105, 4.4666666984558105,
}

-- Internal timers / flags
local speedOriginal, speedStateLast        = nil, false
local godOrigMax,    godStateLast          = nil, false
local invisOrigTrans, invisStateLast       = {}, false
local ultClock,  ultWasFull               = 0, false
local farmClock, kauraClk, cdClock        = 0, 0, 0
local autoPlayClock                        = 0
local infBarClock, noStunClock, noclipClock = 0, 0, 0
local espClock, fbClock, hnClock           = 0, 0, 0
local blockHoldEnd, blockWasHeld           = 0, false
local respawnClock                         = 0
local saveActive, saveClock, savePos       = false, 0, Vector3.zero
local espBoxes, showHitboxBoxes            = {}, {}
local showHitboxLast                       = false
local autoBlockConns                       = {}
local origZoom                             = nil
local Connections                          = {}
local flyStateLast, noclipLast             = false, false
local spinAngle                            = 0
local expandPart, expandBox                = nil, nil
local AB_KEYS      = {"Attack1","Attack2","Attack3","Attack4","Attack5","Lc1","Lc2","Lc3"}
local AB_HOLD_TIME = 2.0

-- ── Helpers ────────────────────────────────────────────────────────────────────
local function chr() return player.Character end
local function hum() local c=chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()
    local c=chr(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end
local function re()
    local c = chr()
    if c then local r=c:FindFirstChild("RemoteEvent"); if r and r:IsA("RemoteEvent") then return r end end
    local rs=game:GetService("ReplicatedStorage")
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
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local ph=p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            if ph then local d=(ph.Position-mh.Position).Magnitude; if d<dist then best,dist=p,d end end
        end
    end
    return best
end
local function nearestTargetRoot(maxD)
    local best, dist = nil, maxD or math.huge
    local mh = hrp(); if not mh then return nil end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local ph=p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
            if ph then local d=(ph.Position-mh.Position).Magnitude; if d<dist then best,dist=ph,d end end
        end
    end
    for _,obj in pairs(workspace:GetChildren()) do
        if obj~=player.Character and obj:IsA("Model") then
            local h2=obj:FindFirstChildOfClass("Humanoid")
            local root=obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            if h2 and root and h2.Health>0 then
                local d=(root.Position-mh.Position).Magnitude; if d<dist then best,dist=root,d end
            end
        end
    end
    return best
end
local function pressBlockFor(t) blockHoldEnd=math.max(blockHoldEnd,tick()+t) end

-- ── Fly ───────────────────────────────────────────────────────────────────────
local function startFly()
    pcall(function()
        local mh=hrp()
        if mh then mh.AssemblyLinearVelocity=Vector3.zero; mh.AssemblyAngularVelocity=Vector3.zero end
    end)
end
local function stopFly() end

-- ── Block (multi-method: VIM + remote tries + attribute override) ─────────────
local function vimKey(down, key)
    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(down,key,false,game) end)
end
local function blockStop()
    local r=re(); if r then pcall(function() r:FireServer("BlockStop") end) end
end
local function tryBlock()
    vimKey(true, Enum.KeyCode.F)
    local r=re()
    if r then
        for _,name in ipairs({"Block","BlockStart","StartBlock","Guard","GuardStart","BlockActivate","Defend","DefendStart"}) do
            pcall(function() r:FireServer(name) end)
        end
    end
    pcall(function()
        local c=chr(); if not c then return end
        for _,a in ipairs({"Blocking","Block","IsBlocking","Guard","Guarding","Parry","Defending"}) do
            if c:GetAttribute(a)~=nil then c:SetAttribute(a,true) end
            local bv=c:FindFirstChild(a)
            if bv and bv:IsA("BoolValue") then bv.Value=true end
        end
    end)
end
local function tryUnblock()
    vimKey(false, Enum.KeyCode.F)
    local r=re()
    if r then
        for _,name in ipairs({"BlockStop","StopBlock","GuardStop","StopGuard","UnBlock","DefendStop"}) do
            pcall(function() r:FireServer(name) end)
        end
    end
    pcall(function()
        local c=chr(); if not c then return end
        for _,a in ipairs({"Blocking","Block","IsBlocking","Guard","Guarding","Parry","Defending"}) do
            if c:GetAttribute(a)~=nil then c:SetAttribute(a,false) end
            local bv=c:FindFirstChild(a)
            if bv and bv:IsA("BoolValue") then bv.Value=false end
        end
    end)
end

-- ── Hitbox spam ───────────────────────────────────────────────────────────────
local function spamHitbox(name, value, count, gap)
    task.spawn(function()
        for _=1,(count or 8) do
            local r=re(); if r then pcall(function() r:FireServer(name,value) end) end
            task.wait(gap or 0.05)
        end
    end)
end
local function fireAttack(n)
    task.spawn(function()
        local r=re(); if not r then return end
        pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
        if S.ExtendHitbox then pcall(function() r:FireServer("Attack"..n.."Hitbox",S.HitboxSize) end) end
    end)
end

-- ── Ult detection ─────────────────────────────────────────────────────────────
local ULT_KEYS = {"ult","charge","energy","special","rage","meter","super","fury","awaken","transform"}
local function nameMatchesUlt(n)
    n=tostring(n):lower()
    for _,k in ipairs(ULT_KEYS) do if n:find(k) then return true end end
    return false
end
local function barFull(f)
    local sx,sy=f.Size.X.Scale,f.Size.Y.Scale
    if sx>=0.97 and sx>=sy then return true end
    if sy>=0.97 and sy>sx  then return true end
    return false
end
local function ultIsFull()
    local gi=gameplayUI(); if not gi then return false end
    for _,d in ipairs(gi:GetDescendants()) do
        if d:IsA("Frame") and nameMatchesUlt(d.Name) then
            for _,c in ipairs(d:GetChildren()) do
                if c:IsA("Frame") or c:IsA("ImageLabel") then
                    local cn=c.Name:lower()
                    if (cn:find("fill") or cn:find("bar") or cn:find("progress") or cn:find("amount")) and barFull(c) then
                        return true
                    end
                end
            end
        end
    end
    for _,root in ipairs({chr(),player}) do
        if root then
            local ok=false
            pcall(function()
                for attr,v in pairs(root:GetAttributes()) do
                    if type(v)=="number" and nameMatchesUlt(attr) then
                        local mx=root:GetAttribute("Max"..attr) or root:GetAttribute(attr.."Max")
                        if type(mx)=="number" and mx>0 and v>=mx-0.01 then ok=true end
                    end
                end
            end)
            if ok then return true end
        end
    end
    return false
end

-- ── Inf Bar ───────────────────────────────────────────────────────────────────
local HP_KEYS = {"hp","health","stamina","energy","life","shield","vitality","bar"}
local function nameMatchesHP(n)
    n=tostring(n):lower()
    for _,k in ipairs(HP_KEYS) do if n:find(k) then return true end end
    return false
end
local function forceBarFull()
    local h=hum(); if h then pcall(function() h.Health=h.MaxHealth end) end
    local c=chr(); if not c then return end
    pcall(function()
        for attr,v in pairs(c:GetAttributes()) do
            if type(v)=="number" and nameMatchesHP(attr) then
                local mx=c:GetAttribute("Max"..attr) or c:GetAttribute(attr.."Max")
                if type(mx)=="number" and mx>0 then c:SetAttribute(attr,mx) end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GUI  (original top-tab, two-column card layout)
-- ══════════════════════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "MoneyFreeHub", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder   = 999
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local function make(cls, props, parent)
    local o=Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent=parent end
    return o
end
local function corner(p, r) return make("UICorner",{CornerRadius=UDim.new(0,r or 6)},p) end

local WIN_W, WIN_H = 560, 430
local TITLE_H, TAB_H = 26, 30

local main = make("Frame",{
    Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
    BackgroundColor3=T.bg, BorderSizePixel=0, Active=true, ClipsDescendants=true,
},gui)
corner(main,8)

-- Title bar
local titleBar = make("Frame",{Size=UDim2.new(1,0,0,TITLE_H),BackgroundColor3=T.title,BorderSizePixel=0},main)
make("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=T.accent,BorderSizePixel=0},titleBar)
make("TextLabel",{
    Text="MONEY/FREE HUB  |  AGE OF TITANS  |  v4.0",
    TextSize=11, TextColor3=T.text, Font=Enum.Font.GothamBold,
    BackgroundTransparency=1, Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-60,1,0),
    TextXAlignment=Enum.TextXAlignment.Left,
},titleBar)
local minBtn   = make("TextButton",{Text="—",TextSize=12,TextColor3=T.dim,Font=Enum.Font.GothamBold,
    BackgroundTransparency=1,Position=UDim2.new(1,-50,0,0),Size=UDim2.new(0,25,1,0)},titleBar)
local closeBtn = make("TextButton",{Text="✕",TextSize=12,TextColor3=T.dim,Font=Enum.Font.GothamBold,
    BackgroundTransparency=1,Position=UDim2.new(1,-26,0,0),Size=UDim2.new(0,26,1,0)},titleBar)

-- Tab bar
local tabBar = make("Frame",{
    Size=UDim2.new(1,0,0,TAB_H), Position=UDim2.new(0,0,0,TITLE_H),
    BackgroundColor3=T.tab, BorderSizePixel=0,
},main)
make("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.border,BorderSizePixel=0},tabBar)

local TAB_NAMES = {"Combat","Player","Visuals","Misc","Teleports","Settings"}
local tabBtns   = {}
local TAB_W     = math.floor(WIN_W / #TAB_NAMES)
for i,name in ipairs(TAB_NAMES) do
    tabBtns[name] = make("TextButton",{
        Text=name, TextSize=11, TextColor3=T.dim, Font=Enum.Font.GothamMedium,
        BackgroundColor3=T.tab, BackgroundTransparency=0,
        Size=UDim2.new(0,TAB_W,1,0), Position=UDim2.new(0,(i-1)*TAB_W,0,0),
        AutoButtonColor=false, BorderSizePixel=0,
    },tabBar)
end

-- Page area
local pageArea = make("Frame",{
    Size=UDim2.new(1,0,1,-(TITLE_H+TAB_H)), Position=UDim2.new(0,0,0,TITLE_H+TAB_H),
    BackgroundTransparency=1, BorderSizePixel=0,
},main)

local pageFrames = {}
local pages      = {}

local function makePage()
    local f = make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=false},pageArea)
    local function makeCol(xPos)
        local sf = make("ScrollingFrame",{
            Size=UDim2.new(0.5,-6,1,-4), Position=UDim2.new(xPos, xPos==0 and 4 or 2, 0,4),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=3, ScrollBarImageColor3=T.accent,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        },f)
        make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sf)
        make("UIPadding",{PaddingBottom=UDim.new(0,6)},sf)
        return sf
    end
    return f, makeCol(0), makeCol(0.5)
end

for _,name in ipairs(TAB_NAMES) do
    local f,l,r = makePage()
    pageFrames[name] = f
    pages[name]      = {l=l, r=r}
end

local function setTab(name)
    for n,btn in pairs(tabBtns) do
        local on = (n==name)
        btn.TextColor3       = on and T.accent or T.dim
        btn.BackgroundColor3 = on and T.tabsel or T.tab
        pageFrames[n].Visible = on
    end
end
for _,name in ipairs(TAB_NAMES) do
    tabBtns[name].MouseButton1Click:Connect(function() setTab(name) end)
end

-- ── Widget builders ──────────────────────────────────────────────────────────
local function makeGroup(col, title)
    local card = make("Frame",{BackgroundColor3=T.card,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},col)
    corner(card,6)
    local strip = make("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=T.accent,BorderSizePixel=0},card)
    corner(strip,6)
    make("TextLabel",{Text=title,TextSize=11,TextColor3=T.dim,Font=Enum.Font.GothamBold,
        BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,8,0,2),
        TextXAlignment=Enum.TextXAlignment.Left},card)
    local inner = make("Frame",{BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.new(0,0,0,22),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},card)
    make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},inner)
    make("UIPadding",{PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)},inner)
    return inner
end

local function makeCheck(parent, label, key, cb)
    local row = make("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,22)},parent)
    local box = make("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,4,0.5,-6.5),
        BackgroundColor3=S[key] and T.accent or T.fill,BorderSizePixel=0},row)
    corner(box,3)
    local fill = make("Frame",{Size=UDim2.new(0.7,0,0.7,0),Position=UDim2.new(0.15,0,0.15,0),
        BackgroundColor3=T.check,BorderSizePixel=0,Visible=S[key]},box)
    corner(fill,2)
    make("TextLabel",{Text=label,TextSize=12,TextColor3=T.text,Font=Enum.Font.GothamMedium,
        BackgroundTransparency=1,Position=UDim2.new(0,22,0,0),Size=UDim2.new(1,-26,1,0),
        TextXAlignment=Enum.TextXAlignment.Left},row)
    local btn = make("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=3},row)
    btn.MouseButton1Click:Connect(function()
        S[key]=not S[key]
        box.BackgroundColor3=S[key] and T.accent or T.fill
        fill.Visible=S[key]
        if cb then cb(S[key]) end
    end)
    return row
end

local function makeSlider(parent, label, key, minV, maxV, suffix)
    suffix = suffix or ""
    local row = make("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,34)},parent)
    make("TextLabel",{Text=label,TextSize=11,TextColor3=T.dim,Font=Enum.Font.GothamMedium,
        BackgroundTransparency=1,Size=UDim2.new(0.65,0,0,16),Position=UDim2.new(0,4,0,0),
        TextXAlignment=Enum.TextXAlignment.Left},row)
    local valLbl = make("TextLabel",{Text=tostring(S[key])..suffix,TextSize=11,TextColor3=T.accent,Font=Enum.Font.GothamBold,
        BackgroundTransparency=1,Size=UDim2.new(0.35,-4,0,16),Position=UDim2.new(0.65,0,0,0),
        TextXAlignment=Enum.TextXAlignment.Right},row)
    local track = make("Frame",{BackgroundColor3=T.fill,BorderSizePixel=0,
        Size=UDim2.new(1,-8,0,5),Position=UDim2.new(0,4,0,20)},row)
    corner(track,2)
    local pct  = math.clamp((S[key]-minV)/(maxV-minV),0,1)
    local fill2 = make("Frame",{BackgroundColor3=T.accent,Size=UDim2.new(pct,0,1,0),BorderSizePixel=0},track)
    corner(fill2,2)
    local knob = make("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(pct,-5,0.5,-5),
        BackgroundColor3=Color3.fromRGB(230,232,240),BorderSizePixel=0,ZIndex=2},track)
    corner(knob,5)
    local dragging=false
    local function set(px)
        local np=math.clamp((px-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(minV+(maxV-minV)*np+0.5)
        S[key]=v; fill2.Size=UDim2.new(np,0,1,0); knob.Position=UDim2.new(np,-5,0.5,-5)
        valLbl.Text=tostring(v)..suffix
    end
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;set(i.Position.X) end end)
    knob.InputBegan:Connect(function(i)  if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    table.insert(Connections,UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    table.insert(Connections,UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then set(i.Position.X) end end))
    return row
end

local function makeBtn(parent, label, h, cb)
    h = h or 24
    local btn = make("TextButton",{Text=label,TextSize=11,TextColor3=T.text,Font=Enum.Font.GothamMedium,
        BackgroundColor3=T.fill,Size=UDim2.new(1,0,0,h),AutoButtonColor=false,BorderSizePixel=0},parent)
    corner(btn,4)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3=T.accent end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=T.fill end)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function makeLabel(parent, text, dim)
    local lbl = make("TextLabel",{Text=text,TextSize=10,
        TextColor3=dim and T.dim or T.text,Font=Enum.Font.Gotham,
        BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),
        TextXAlignment=Enum.TextXAlignment.Left},parent)
    return lbl
end

-- ── Expand visual ─────────────────────────────────────────────────────────────
local function ensureExpandVisual()
    local mh=hrp(); if not mh then return end
    if not expandPart or expandPart.Parent==nil then
        expandPart=Instance.new("Part")
        expandPart.Shape,expandPart.Anchored=Enum.PartType.Ball,false
        expandPart.CanCollide,expandPart.CanQuery=false,false
        expandPart.CanTouch,expandPart.Massless=false,true
        expandPart.Transparency=1; expandPart.CFrame=mh.CFrame; expandPart.Parent=mh.Parent
        local w=Instance.new("Weld"); w.Part0,w.Part1,w.Parent=mh,expandPart,expandPart
        expandBox=Instance.new("SelectionBox")
        expandBox.Adornee,expandBox.Color3=expandPart,T.accent
        expandBox.SurfaceColor3=T.accent; expandBox.SurfaceTransparency=0.85
        expandBox.LineThickness=0.03; expandBox.Parent=gui
    end
    local sz=S.M1Size*2; expandPart.Size=Vector3.new(sz,sz,sz)
end
local function destroyExpandVisual()
    if expandBox  then pcall(function() expandBox:Destroy()  end); expandBox=nil  end
    if expandPart then pcall(function() expandPart:Destroy() end); expandPart=nil end
end

-- ── Auto Block wiring ─────────────────────────────────────────────────────────
local function hookAutoBlockPlayer(p2)
    if p2==player then return end
    local function wire(kbFolder)
        for _,keyName in pairs(AB_KEYS) do
            local kv=kbFolder:FindFirstChild(keyName)
            if kv then
                local conn=kv.Changed:Connect(function()
                    if not S.AutoBlock then return end
                    local ph=p2.Character and (p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart)
                    local mh=hrp()
                    if ph and mh and (ph.Position-mh.Position).Magnitude<120 then pressBlockFor(AB_HOLD_TIME) end
                end)
                table.insert(autoBlockConns,conn)
            end
        end
    end
    local kb=p2:FindFirstChild("Keybinds"); if kb then wire(kb) end
    local ac=p2.ChildAdded:Connect(function(ch)
        if ch.Name=="Keybinds" then task.defer(function() wire(ch) end) end
    end)
    table.insert(autoBlockConns,ac)
end
local function startAutoBlock()
    for _,c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
    autoBlockConns={}
    for _,p2 in pairs(Players:GetPlayers()) do hookAutoBlockPlayer(p2) end
    table.insert(autoBlockConns,Players.PlayerAdded:Connect(hookAutoBlockPlayer))
end
local function stopAutoBlock()
    for _,c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
    autoBlockConns={}; blockHoldEnd=0
end

-- ── Misc helpers ──────────────────────────────────────────────────────────────
local function applyFullbright()
    pcall(function()
        Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e9
        Lighting.GlobalShadows=false
        Lighting.Ambient=Color3.fromRGB(160,160,160); Lighting.OutdoorAmbient=Color3.fromRGB(160,160,160)
    end)
end
local function fpsBoost()
    pcall(function()
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled=false
            elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency=1
            elseif v:IsA("MeshPart") then v.Material=Enum.Material.Plastic end
        end
        Lighting.GlobalShadows=false
        local terr=workspace:FindFirstChildOfClass("Terrain")
        if terr then terr.WaterWaveSize=0;terr.WaterWaveSpeed=0;terr.WaterReflectance=0 end
        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    end)
end
local function rejoinServer() pcall(function() TeleportService:Teleport(game.PlaceId,player) end) end
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
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,sv.id,player) end); return
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

-- ══════════════════════════════════════════════════════════════════════════════
-- BUILD PAGES
-- ══════════════════════════════════════════════════════════════════════════════

-- COMBAT
do
    local L,R = pages["Combat"].l, pages["Combat"].r
    local g1  = makeGroup(L,"Attack")
    makeCheck(g1,"Kill Aura","KillAura")
    makeSlider(g1,"Aura Range","KillAuraRange",10,150)
    makeCheck(g1,"Silent Aim","SilentAim")
    makeCheck(g1,"Extend Hitbox","ExtendHitbox")
    makeSlider(g1,"Hitbox Size","HitboxSize",1,60)
    makeCheck(g1,"Show Hitbox","ShowHitbox",function(on)
        if not on then
            for _,b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
            showHitboxBoxes={}
        end
    end)
    makeCheck(g1,"M1 Expand","M1Expand")
    makeSlider(g1,"M1 Size","M1Size",1,40)
    makeCheck(g1,"Show Expand","ShowExpand",function(on) if not on then destroyExpandVisual() end end)
    makeCheck(g1,"Bypass Cooldown","BypassCooldown")
    local g2 = makeGroup(R,"Defense / Auto")
    makeCheck(g2,"Infinite Block","InfBlock")
    makeCheck(g2,"Auto Block","AutoBlock",function(on) if on then startAutoBlock() else stopAutoBlock() end end)
    makeCheck(g2,"Auto Ultimate","AutoUlt")
    makeCheck(g2,"Auto Play","AutoPlay")
    makeSlider(g2,"Auto Play Range","AutoPlayRange",20,300)
    makeCheck(g2,"Auto Farm","AutoFarm")
    makeSlider(g2,"Auto Farm Range","AutoFarmRange",20,300)
end

-- PLAYER
do
    local L,R = pages["Player"].l, pages["Player"].r
    local g1  = makeGroup(L,"Movement")
    makeCheck(g1,"Fly","Fly")
    makeSlider(g1,"Fly Speed","FlySpeed",10,300)
    makeLabel(g1,"W/A/S/D · Space=Up · Ctrl=Down",true)
    makeCheck(g1,"Noclip","Noclip")
    makeCheck(g1,"Speed Hack","SpeedHack")
    makeSlider(g1,"Walk Speed","WalkSpeed",16,250)
    makeCheck(g1,"Auto Sprint","AutoSprint")
    makeCheck(g1,"No Stun","NoStun")
    local g2 = makeGroup(R,"Survival")
    makeCheck(g2,"God Mode","GodMode")
    makeCheck(g2,"Infinite Bar (HP)","InfBar")
    makeCheck(g2,"Save System","SaveSystem")
    makeSlider(g2,"HP Threshold","SaveThreshold",1,99,"%")
    makeCheck(g2,"Instant Respawn","InstantRespawn")
    makeCheck(g2,"Invisible","Invisible")
end

-- VISUALS
do
    local L = pages["Visuals"].l
    local g1 = makeGroup(L,"Visuals")
    makeCheck(g1,"Player ESP","ESP")
    makeCheck(g1,"Infinite Zoom","InfZoom",function(on)
        if on then origZoom=player.CameraMaxZoomDistance;player.CameraMaxZoomDistance=9999
        else if origZoom then player.CameraMaxZoomDistance=origZoom end end
    end)
    makeCheck(g1,"Fullbright","Fullbright",function(on) if on then applyFullbright() end end)
end

-- MISC
do
    local L,R = pages["Misc"].l, pages["Misc"].r
    local g1  = makeGroup(L,"Utility")
    makeCheck(g1,"Anti-AFK","AntiAFK")
    makeCheck(g1,"Infinite Jump","InfJump")
    makeCheck(g1,"Click TP  [T]","ClickTP")
    makeCheck(g1,"Spinbot","Spinbot")
    makeCheck(g1,"Hide Names","HideNames")
    makeCheck(g1,"Anti-Fling","AntiFling")
    local g2 = makeGroup(R,"Server")
    makeBtn(g2,"FPS Boost",22,fpsBoost)
    makeBtn(g2,"Reset Character",22,resetCharacter)
    makeBtn(g2,"Rejoin Server",22,rejoinServer)
    makeBtn(g2,"Server Hop",22,serverHop)
end

-- TELEPORTS
do
    local L = pages["Teleports"].l
    local g1 = makeGroup(L,"Teleport To Player")
    local list = make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,160),ScrollBarThickness=3,ScrollBarImageColor3=T.accent,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},g1)
    make("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,3)},list)
    local function rebuild()
        for _,c in pairs(list:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        for _,p2 in pairs(Players:GetPlayers()) do
            if p2~=player then
                makeBtn(list,p2.Name,22,function()
                    pcall(function()
                        local ph=p2.Character and (p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart)
                        local mh=hrp()
                        if ph and mh then
                            local c=chr()
                            if c and c.PrimaryPart then c:SetPrimaryPartCFrame(ph.CFrame+Vector3.new(3,0,0))
                            else mh.CFrame=ph.CFrame+Vector3.new(3,0,0) end
                        end
                    end)
                end)
            end
        end
    end
    rebuild()
    Players.PlayerAdded:Connect(rebuild); Players.PlayerRemoving:Connect(rebuild)
    makeBtn(g1,"Refresh List",22,rebuild)
end

-- SETTINGS
do
    local L,R = pages["Settings"].l, pages["Settings"].r
    local g1  = makeGroup(L,"Keybinds")
    local kbBtn
    kbBtn = makeBtn(g1,"Toggle Key: RightShift",22,function()
        kbBtn.Text="Press any key..."
        local conn; conn=UIS.InputBegan:Connect(function(i,gpe)
            if gpe then return end
            if i.UserInputType~=Enum.UserInputType.Keyboard then return end
            S.ToggleKey=i.KeyCode; kbBtn.Text="Toggle Key: "..i.KeyCode.Name; conn:Disconnect()
        end)
    end)
    local g2 = makeGroup(L,"Script")
    makeBtn(g2,"Disconnect All",22,function()
        for _,c in pairs(Connections)    do pcall(function() c:Disconnect() end) end
        for _,c in pairs(autoBlockConns) do pcall(function() c:Disconnect() end) end
        stopFly(); destroyExpandVisual()
        Connections,autoBlockConns={},{};S.Fly,S.Noclip=false,false
    end)
    makeBtn(g2,"Close Hub",22,function() destroyExpandVisual();gui:Destroy() end)
    local g3 = makeGroup(R,"Accent Color")
    local ACCENT_PRESETS = {
        Color3.fromRGB(64,110,200), Color3.fromRGB(45,205,190),
        Color3.fromRGB(80,190,110), Color3.fromRGB(210,160,60),
        Color3.fromRGB(150,90,220), Color3.fromRGB(225,80,90),
    }
    local cr = make("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,26)},g3)
    make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),
        VerticalAlignment=Enum.VerticalAlignment.Center},cr)
    for _,col in ipairs(ACCENT_PRESETS) do
        local sw=make("TextButton",{Text="",BackgroundColor3=col,Size=UDim2.new(0,18,0,18),AutoButtonColor=false},cr)
        corner(sw,4)
        sw.MouseButton1Click:Connect(function() T.accent=col end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INPUT
-- ══════════════════════════════════════════════════════════════════════════════
local ATTACK_KEYS = {
    [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,
    [Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5,
}

table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType==Enum.UserInputType.Keyboard then
        local n=ATTACK_KEYS[i.KeyCode]
        if n then
            if S.ExtendHitbox   then spamHitbox("Attack"..n.."Hitbox",S.HitboxSize,6,0.05) end
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
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    if S.ExtendHitbox then for n=1,5 do spamHitbox("Attack"..n.."Hitbox",S.HitboxSize,4,0.05) end end
    if S.M1Expand     then for n=1,3 do spamHitbox("Lc"..n.."Hitbox",S.M1Size,4,0.05) end end
    if S.SilentAim then
        pcall(function()
            local tgt=nearest(300); if not tgt then return end
            for n=1,5 do spamHitbox("Attack"..n.."Hitbox",math.max(S.HitboxSize,25),4,0.05) end
            for n=1,3 do spamHitbox("Lc"..n.."Hitbox",math.max(S.HitboxSize,25),4,0.05) end
        end)
    end
end))

table.insert(Connections, UIS.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
end))

pcall(function()
    player.Idled:Connect(function()
        if not S.AntiAFK then return end
        local vu=game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new())
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

-- ══════════════════════════════════════════════════════════════════════════════
-- MAIN LOOP  (heavy ops throttled to fix lag)
-- ══════════════════════════════════════════════════════════════════════════════
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)

    -- Speed Hack
    if S.SpeedHack~=speedStateLast then
        speedStateLast=S.SpeedHack
        local h=hum()
        if S.SpeedHack then if h then speedOriginal=h.WalkSpeed end
        else if h and speedOriginal then h.WalkSpeed=speedOriginal end; speedOriginal=nil end
    end
    if S.SpeedHack then pcall(function() local h=hum();if h then h.WalkSpeed=S.WalkSpeed end end) end

    -- God Mode
    if S.GodMode~=godStateLast then
        godStateLast=S.GodMode
        local h=hum()
        if h then
            if S.GodMode then godOrigMax=h.MaxHealth;h.MaxHealth=math.huge;h.Health=math.huge
            else if godOrigMax then h.MaxHealth=godOrigMax;h.Health=godOrigMax end;godOrigMax=nil end
        end
    end
    if S.GodMode then pcall(function() local h=hum();if h then h.Health=math.huge end end) end

    -- Inf Bar (throttled 0.3s)
    if S.InfBar then
        infBarClock=infBarClock+dt
        if infBarClock>=0.3 then infBarClock=0;forceBarFull() end
    end

    -- No Stun (throttled 0.15s)
    if S.NoStun then
        noStunClock=noStunClock+dt
        if noStunClock>=0.15 then
            noStunClock=0
            pcall(function()
                local c=chr()
                if c then
                    for _,a in ipairs({"Stun","Stunned","Ragdoll","Ragdolled","Frozen","Knockback","Staggered","NoMove","Disabled"}) do
                        if c:GetAttribute(a)~=nil then c:SetAttribute(a,false) end
                    end
                    local mh2=c:FindFirstChild("HumanoidRootPart")
                    if mh2 and mh2.Anchored then mh2.Anchored=false end
                end
                local h=hum()
                if h then
                    h.PlatformStand=false;h.Sit=false
                    if h.WalkSpeed<=0.5 then h.WalkSpeed=(S.SpeedHack and S.WalkSpeed) or 16 end
                    if h.JumpPower~=nil and h.JumpPower<=0.5 then h.JumpPower=50 end
                end
            end)
        end
    end

    -- Invisible
    if S.Invisible~=invisStateLast then invisStateLast=S.Invisible;doInvisible(S.Invisible) end

    -- Fly
    if S.Fly~=flyStateLast then flyStateLast=S.Fly; if S.Fly then startFly() else stopFly() end end
    if S.Fly then
        pcall(function()
            local c=chr(); if not c then return end
            local mh=hrp(); if not mh then return end
            local cam=workspace.CurrentCamera.CFrame
            local dir=Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir=dir+cam.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir=dir-cam.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir=dir-cam.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir=dir+cam.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir=dir+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
            mh.AssemblyLinearVelocity=Vector3.zero; mh.AssemblyAngularVelocity=Vector3.zero
            if dir.Magnitude>0 then
                local move=dir.Unit*S.FlySpeed*dt
                if c.PrimaryPart then c:SetPrimaryPartCFrame(c.PrimaryPart.CFrame+move)
                else mh.CFrame=mh.CFrame+move end
            end
        end)
    end

    -- Noclip (throttled 0.2s)
    if S.Noclip then
        noclipLast=true; noclipClock=noclipClock+dt
        if noclipClock>=0.2 then
            noclipClock=0
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

    -- Block manager (Inf Block + Auto Block)
    do
        local want = S.InfBlock or (S.AutoBlock and tick()<blockHoldEnd)
        if want then tryBlock(); blockWasHeld=true
        elseif blockWasHeld then blockWasHeld=false;tryUnblock();blockStop() end
    end

    -- Auto Ult
    if S.AutoUlt then
        ultClock=ultClock+dt
        if ultClock>=0.3 then
            ultClock=0
            local full=false; pcall(function() full=ultIsFull() end)
            if full and not ultWasFull then
                ultWasFull=true
                task.spawn(function()
                    pcall(function()
                        local vim=game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true,Enum.KeyCode.V,false,game); task.wait(0.08)
                        vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                    end)
                end)
            elseif not full then ultWasFull=false end
        end
    else
        ultClock=0; ultWasFull=false
    end

    -- Kill Aura
    if S.KillAura then
        kauraClk=kauraClk+dt
        if kauraClk>=0.25 then
            kauraClk=0
            pcall(function()
                local tgt=nearestTargetRoot(S.KillAuraRange); if not tgt then return end
                local mh=hrp(); if not mh then return end
                local diff=tgt.Position-mh.Position
                if diff.Magnitude>10 then
                    local snap=tgt.Position-diff.Unit*6+Vector3.new(0,2,0)
                    local c=chr()
                    if c and c.PrimaryPart then c:SetPrimaryPartCFrame(CFrame.new(snap))
                    else mh.CFrame=CFrame.new(snap) end
                end
                local r=re(); if not r then return end
                for n=1,5 do
                    pcall(function() r:FireServer("Attack"..n,ATTACK_VALS[n] or 4.4666666984558105) end)
                    pcall(function() r:FireServer("Attack"..n.."Hitbox",S.HitboxSize) end)
                end
            end)
        end
    end

    -- Auto Farm
    if S.AutoFarm then
        farmClock=farmClock+dt
        if farmClock>=0.4 then
            farmClock=0
            pcall(function()
                local tgt=nearest(S.AutoFarmRange); if not tgt then return end
                local mh=hrp(); if not mh then return end
                local ph=tgt.Character and (tgt.Character:FindFirstChild("HumanoidRootPart") or tgt.Character.PrimaryPart)
                if not ph then return end
                local c=chr()
                if c and c.PrimaryPart then c:SetPrimaryPartCFrame(ph.CFrame+ph.CFrame.LookVector*-3)
                else mh.CFrame=ph.CFrame+ph.CFrame.LookVector*-3 end
                local r=re(); if not r then return end
                for n=1,5 do
                    pcall(function() r:FireServer("Attack"..n,ATTACK_VALS[n] or 4.4666666984558105) end)
                    pcall(function() r:FireServer("Attack"..n.."Hitbox",S.HitboxSize) end)
                end
                for n=1,3 do pcall(function() r:FireServer("Lc"..n.."Hitbox",S.HitboxSize) end) end
                task.spawn(function()
                    pcall(function()
                        local vim=game:GetService("VirtualInputManager")
                        local vp=workspace.CurrentCamera.ViewportSize
                        vim:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,0)
                        vim:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,0)
                        task.wait(0.1)
                        if ultIsFull() then
                            vim:SendKeyEvent(true,Enum.KeyCode.V,false,game);task.wait(0.05)
                            vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                        end
                    end)
                end)
            end)
        end
    end

    -- Auto Play
    if S.AutoPlay then
        autoPlayClock=autoPlayClock+dt
        if autoPlayClock>=0.35 then
            autoPlayClock=0
            pcall(function()
                local tgt=nearestTargetRoot(S.AutoPlayRange); if not tgt then return end
                local mh=hrp(); if not mh then return end
                local dist=(tgt.Position-mh.Position).Magnitude
                if dist>14 then
                    local h=hum()
                    if h then h:MoveTo(tgt.Position)
                    else
                        local c=chr()
                        local dir=(tgt.Position-mh.Position).Unit
                        local step=math.min(dist-10,20)
                        if c and c.PrimaryPart then c:SetPrimaryPartCFrame(c.PrimaryPart.CFrame+dir*step)
                        else mh.CFrame=mh.CFrame+dir*step end
                    end
                else
                    local r=re(); if not r then return end
                    for n=1,5 do
                        pcall(function() r:FireServer("Attack"..n,ATTACK_VALS[n] or 4.4666666984558105) end)
                        pcall(function() r:FireServer("Attack"..n.."Hitbox",S.HitboxSize) end)
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
                                vim:SendKeyEvent(true,Enum.KeyCode.V,false,game);task.wait(0.05)
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
        cdClock=cdClock+dt
        if cdClock>=0.1 then
            cdClock=0
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

    -- Fullbright
    if S.Fullbright then fbClock=fbClock+dt; if fbClock>=1 then fbClock=0;applyFullbright() end end

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
                mh.CFrame=CFrame.new(savePos+Vector3.new(0,500,0)); mh.AssemblyLinearVelocity=Vector3.zero
                if saveClock>=4 or (h.Health/h.MaxHealth*100)>S.SaveThreshold+20 then
                    saveActive=false;saveClock=0;mh.CFrame=CFrame.new(savePos+Vector3.new(0,8,0))
                end
            elseif (h.Health/h.MaxHealth*100)<=S.SaveThreshold then
                savePos=mh.Position;saveActive=true;saveClock=0
            end
        end
    end

    -- Show Hitbox
    if S.ShowHitbox~=showHitboxLast then
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
                        box.Adornee=root;box.Color3=T.accent;box.LineThickness=0.05
                        box.SurfaceTransparency=0.7;box.SurfaceColor3=T.accent;box.Parent=gui
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
                if not Players:FindFirstChild(name) then pcall(function() data.bill:Destroy() end);espBoxes[name]=nil end
            end
            for _,p2 in pairs(Players:GetPlayers()) do
                if p2~=player and p2.Character then
                    local root=p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                    if root and not espBoxes[p2.Name] then
                        local bill=Instance.new("BillboardGui")
                        bill.Size=UDim2.new(0,80,0,28);bill.AlwaysOnTop=true
                        bill.StudsOffset=Vector3.new(0,3,0);bill.Adornee=root;bill.Parent=gui
                        make("TextLabel",{Text=p2.Name,TextSize=13,TextColor3=T.accent,Font=Enum.Font.GothamMedium,
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

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local dragging,dragStart,startPos=false,nil,nil
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true;dragStart=i.Position;startPos=main.Position end
    end)
    titleBar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    table.insert(Connections,UIS.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                                startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end))
end

-- ── Minimize / Close ──────────────────────────────────────────────────────────
minBtn.MouseButton1Click:Connect(function()
    S.Minimized=not S.Minimized
    tabBar.Visible=not S.Minimized
    pageArea.Visible=not S.Minimized
    main.Size=S.Minimized and UDim2.new(0,WIN_W,0,TITLE_H) or UDim2.new(0,WIN_W,0,WIN_H)
end)
closeBtn.MouseButton1Click:Connect(function() destroyExpandVisual();gui:Destroy() end)

-- ── Toggle keybind ────────────────────────────────────────────────────────────
table.insert(Connections,UIS.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==S.ToggleKey then main.Visible=not main.Visible end
end))

-- ── Init ──────────────────────────────────────────────────────────────────────
setTab("Combat")
print("[Money/Free Hub] v4.0 | Toggle: "..S.ToggleKey.Name)
