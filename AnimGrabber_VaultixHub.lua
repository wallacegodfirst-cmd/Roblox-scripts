--[[
VAULTIX ANIM GRABBER + PREVIEW HUB v1.2 - FIXED
Fixes in this version:
- Theme.Bad was undefined (crashed every toggle-off / Del / Unload) -> defined.
- Minimize button captured Side/MainContent before they existed -> forward-declared.
- 3D PREVIEW now actually ANIMATES: ViewportFrame models don't auto-step
  animations, so we drive Animator:StepAnimations(dt) every RenderStepped.
- Real rig: clones YOUR character (perfect match for the game's anims); falls
  back to a built R15 dummy if you have no character.
- RightShift toggle is now actually wired.
- Logger no longer re-hooks the same Animator over and over (dedup set).
- Forward-declared the mutually-referenced functions so order can't bite us.
Execute -> Logger / Hit IDs tab -> Play on any ID -> dummy animates in viewport.
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local LocalPlayer      = Players.LocalPlayer

local Theme = {
    Bg      = Color3.fromRGB(14, 7, 9),
    Sidebar = Color3.fromRGB(19, 10, 12),
    Content = Color3.fromRGB(21, 11, 14),
    Header  = Color3.fromRGB(11, 5, 7),
    Accent  = Color3.fromRGB(235, 40, 55),
    Outline = Color3.fromRGB(42, 18, 23),
    Element = Color3.fromRGB(26, 13, 16),
    Hover   = Color3.fromRGB(38, 16, 20),
    Text    = Color3.fromRGB(252, 245, 248),
    Sub     = Color3.fromRGB(160, 118, 128),
    Good    = Color3.fromRGB(55, 195, 115),
    Warn    = Color3.fromRGB(225, 175, 45),
    Bad     = Color3.fromRGB(220, 45, 60),   -- FIX: was missing -> nil crashes
    Font    = Enum.Font.Code,
}

local function new(c, p) local o=Instance.new(c); for k,v in pairs(p or {}) do o[k]=v end; return o end
local function stroke(o, col, th) return new("UIStroke", {Color=col or Theme.Outline, Thickness=th or 1, Parent=o}) end
local function corner(o, r) return new("UICorner", {CornerRadius=UDim.new(0, r or 6), Parent=o}) end

-- ==================== RESEARCH LISTS ====================
local JJS_POPULAR = {
    {id="rbxassetid://100962226150441", name="Divergent Fist (JJS)"},
    {id="rbxassetid://95852624447551",  name="Black Flash 1"},
    {id="rbxassetid://74145636023952",  name="Black Flash 2"},
    {id="rbxassetid://72475960800126",  name="Focus Strike"},
    {id="rbxassetid://123171106092050", name="Straight Hit"},
    {id="rbxassetid://137865634124104", name="Lapse Blue"},
    {id="rbxassetid://137654778575373", name="Reversal Red"},
    {id="rbxassetid://77200218033775",  name="Cursed Strike"},
    {id="rbxassetid://134461702265323", name="Blade Mode"},
    {id="rbxassetid://127171275866632", name="Piercing Blood"},
}
local TSB_POPULAR = {
    {id="rbxassetid://10468665991", name="Normal Punch (TSB)"},
    {id="rbxassetid://10466974800", name="Consecutive Punches"},
    {id="rbxassetid://10471336737", name="Shove"},
    {id="rbxassetid://12510170988", name="Uppercut"},
    {id="rbxassetid://12983333733", name="Serious Punch"},
    {id="rbxassetid://13532562418", name="Garou M1"},
    {id="rbxassetid://17889458563", name="Suiryu M1"},
    {id="rbxassetid://10469493270", name="Saitama M1"},
}

local DETECTED_GAME = "Universal"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    local nm = (info and info.Name or ""):lower()
    if nm:find("jujutsu") or nm:find("shenanigans") then DETECTED_GAME = "JJS"
    elseif nm:find("strongest") or nm:find("battlegrounds") then DETECTED_GAME = "TSB" end
end)

-- ==================== STATE ====================
local LoggerEnabled = true
local HitIDEnabled  = true
local LoggedAnims = {}
local HitIDs      = {}
local Favorites   = {}
local CurrentPreviewTrack, CurrentDummy
local LoggerConns = {}
local LogRows, HitRows = {}, {}
local speed = 1
local hookedAnimators = setmetatable({}, {__mode="k"})  -- dedup so we don't re-hook

-- forward declarations (used by callbacks defined out of order)
local Side, SideScroll, MainContent
local loadPreview, recreateDummy, cleanupPreview, refreshFavs, addLogged, addHitID, buildFallbackRig

-- ==================== GUI ROOT ====================
local Screen = new("ScreenGui", {Name="VaultixAnimGrabber_v1.2", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=7500, Parent=(gethui and gethui()) or game:GetService("CoreGui")})

local Win = new("Frame", {Size=UDim2.fromOffset(740, 630), Position=UDim2.new(0.5,-370,0.5,-315), BackgroundColor3=Theme.Bg, BorderSizePixel=0, Active=true, Parent=Screen})
stroke(Win, Theme.Accent, 1.5); corner(Win, 8)

-- Header (draggable)
local Head = new("Frame", {Size=UDim2.new(1,0,0,36), BackgroundColor3=Theme.Header, Parent=Win})
new("Frame", {Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2), BackgroundColor3=Theme.Accent, Parent=Head})
new("TextLabel", {Size=UDim2.fromOffset(210,36), Position=UDim2.fromOffset(12,0), BackgroundTransparency=1, Text="VAULTIX ANIM GRABBER", TextColor3=Theme.Text, Font=Theme.Font, TextSize=15, TextXAlignment=Enum.TextXAlignment.Left, Parent=Head})
new("TextLabel", {Size=UDim2.fromOffset(90,14), Position=UDim2.fromOffset(218,11), BackgroundTransparency=1, Text="v1.2 - "..DETECTED_GAME, TextColor3=Theme.Accent, Font=Theme.Font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, Parent=Head})

do
    local dragging, dragStart, startPos
    Head.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=Win.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local minned = false
local function headBtn(x, txt, cb)
    local b = new("TextButton", {Size=UDim2.fromOffset(20,17), Position=UDim2.new(1,x,0,9), BackgroundColor3=Theme.Element, Text=txt, TextColor3=Theme.Sub, Font=Theme.Font, TextSize=11, AutoButtonColor=false, Parent=Head})
    stroke(b, Theme.Outline, 0.5); corner(b, 3)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3=Theme.Accent, TextColor3=Theme.Text}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3=Theme.Element, TextColor3=Theme.Sub}):Play() end)
    b.MouseButton1Click:Connect(cb)
    return b
end
headBtn(-24, "X", function() Win.Visible=false end)
headBtn(-48, "-", function()
    minned = not minned
    if Side then Side.Visible = not minned end
    if MainContent then MainContent.Visible = not minned end
    TweenService:Create(Win, TweenInfo.new(0.12), {Size = minned and UDim2.fromOffset(740,36) or UDim2.fromOffset(740,630)}):Play()
end)

-- Search
local SearchFrame = new("Frame", {Size=UDim2.fromOffset(200,20), Position=UDim2.fromOffset(300,8), BackgroundColor3=Theme.Element, Parent=Head})
stroke(SearchFrame, Theme.Outline, 0.5); corner(SearchFrame, 4)
local SearchBox = new("TextBox", {Size=UDim2.new(1,-8,1,0), Position=UDim2.fromOffset(4,0), BackgroundTransparency=1, PlaceholderText="Search...", PlaceholderColor3=Theme.Sub, Text="", TextColor3=Theme.Text, Font=Theme.Font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=SearchFrame})

-- Sidebar + content
Side = new("Frame", {Size=UDim2.new(0,128,1,-52), Position=UDim2.fromOffset(8,44), BackgroundColor3=Theme.Sidebar, Parent=Win})
stroke(Side, Theme.Outline, 0.6); corner(Side, 6)
SideScroll = new("ScrollingFrame", {Size=UDim2.new(1,-3,1,-6), Position=UDim2.fromOffset(2,3), BackgroundTransparency=1, ScrollBarThickness=0, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(), Parent=Side})
new("UIListLayout", {Padding=UDim.new(0,3), Parent=SideScroll})

MainContent = new("Frame", {Size=UDim2.new(1,-148,1,-52), Position=UDim2.fromOffset(140,44), BackgroundColor3=Theme.Content, Parent=Win})
stroke(MainContent, Theme.Outline, 0.6); corner(MainContent, 6)

local Pages, ActivePage, ActiveTabBtn = {}, nil, nil
local function makePage(n) local p=new("Frame",{Name=n,Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4),BackgroundTransparency=1,Visible=false,Parent=MainContent}); Pages[n]=p; return p end
local function switchPage(n) if ActivePage then ActivePage.Visible=false end; ActivePage=Pages[n]; if ActivePage then ActivePage.Visible=true end end

local function sideTab(txt, pn)
    local b = new("TextButton", {Size=UDim2.new(1,0,0,24), BackgroundColor3=Theme.Sidebar, Text="  "..txt, TextColor3=Theme.Sub, Font=Theme.Font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false, Parent=SideScroll})
    stroke(b, Theme.Outline, 0.4); corner(b, 4)
    local function setActive()
        for _,bb in ipairs(SideScroll:GetChildren()) do if bb:IsA("TextButton") then bb.BackgroundColor3=Theme.Sidebar; bb.TextColor3=Theme.Sub end end
        b.BackgroundColor3=Theme.Element; b.TextColor3=Theme.Text; ActiveTabBtn=b
        switchPage(pn)
    end
    b.MouseEnter:Connect(function() if b~=ActiveTabBtn then TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3=Theme.Hover, TextColor3=Theme.Text}):Play() end end)
    b.MouseLeave:Connect(function() if b~=ActiveTabBtn then TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3=Theme.Sidebar, TextColor3=Theme.Sub}):Play() end end)
    b.MouseButton1Click:Connect(setActive)
    return b, setActive
end

local _, selLogger = sideTab("LOGGER", "Logger")
sideTab("HIT IDS", "HitIDs")
sideTab("PREVIEW 3D", "Preview")
sideTab("FAVORITES", "Favs")
sideTab("POPULAR", "Popular")
sideTab("SETTINGS", "Settings")

-- ==================== LOGGER PAGE ====================
local LoggerPage = makePage("Logger")
local LogHead = new("Frame", {Size=UDim2.new(1,0,0,26), BackgroundColor3=Theme.Element, Parent=LoggerPage}); corner(LogHead,4)
new("TextLabel", {Size=UDim2.fromOffset(120,26), Position=UDim2.fromOffset(8,0), BackgroundTransparency=1, Text="ANIMATION LOGGER", TextColor3=Theme.Accent, Font=Theme.Font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=LogHead})
local LogToggle = new("TextButton", {Size=UDim2.fromOffset(48,16), Position=UDim2.fromOffset(130,5), BackgroundColor3=Theme.Good, Text="ON", TextColor3=Color3.new(1,1,1), Font=Theme.Font, TextSize=9, AutoButtonColor=false, Parent=LogHead}); corner(LogToggle,3)
LogToggle.MouseButton1Click:Connect(function()
    LoggerEnabled = not LoggerEnabled
    LogToggle.Text = LoggerEnabled and "ON" or "OFF"
    LogToggle.BackgroundColor3 = LoggerEnabled and Theme.Good or Theme.Bad
end)
local ClearLog = new("TextButton", {Size=UDim2.fromOffset(48,16), Position=UDim2.fromOffset(184,5), BackgroundColor3=Theme.Sidebar, Text="Clear", TextColor3=Theme.Text, Font=Theme.Font, TextSize=9, AutoButtonColor=false, Parent=LogHead}); stroke(ClearLog,Theme.Outline,0.4); corner(ClearLog,3)
ClearLog.MouseButton1Click:Connect(function()
    for _,r in pairs(LogRows) do if r.Parent then r:Destroy() end end
    LogRows={}; LoggedAnims={}
end)
local LogCount = new("TextLabel", {Size=UDim2.fromOffset(120,26), Position=UDim2.new(1,-126,0,0), BackgroundTransparency=1, Text="0 logged", TextColor3=Theme.Sub, Font=Theme.Font, TextSize=9, TextXAlignment=Enum.TextXAlignment.Right, Parent=LogHead})

local LogScroll = new("ScrollingFrame", {Size=UDim2.new(1,0,1,-30), Position=UDim2.fromOffset(0,30), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(), Parent=LoggerPage})
new("UIListLayout", {Padding=UDim.new(0,2), Parent=LogScroll})

function addLogged(id, nm)
    if LoggedAnims[id] then LoggedAnims[id].count = LoggedAnims[id].count + 1; return end
    LoggedAnims[id] = {id=id, name=nm or ("Anim_"..string.sub(id,-6)), time=os.date("%X"), count=1, game=DETECTED_GAME}
    LogCount.Text = tostring((tonumber(LogCount.Text:match("%d+")) or 0)+1).." logged"
    local row = new("Frame", {Size=UDim2.new(1,-4,0,22), BackgroundColor3=Theme.Element, Parent=LogScroll}); stroke(row,Theme.Outline,0.3); corner(row,3)
    LogRows[#LogRows+1] = row
    new("TextLabel", {Size=UDim2.fromOffset(168,22), Position=UDim2.fromOffset(6,0), BackgroundTransparency=1, Text=LoggedAnims[id].name, TextColor3=Theme.Text, Font=Theme.Font, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=row})
    new("TextLabel", {Size=UDim2.fromOffset(54,22), Position=UDim2.fromOffset(176,0), BackgroundTransparency=1, Text=LoggedAnims[id].time, TextColor3=Theme.Sub, Font=Theme.Font, TextSize=8, Parent=row})
    local function sbtn(t,x,cb) local bb=new("TextButton",{Size=UDim2.fromOffset(38,15),Position=UDim2.fromOffset(x,3.5),BackgroundColor3=Theme.Sidebar,Text=t,TextColor3=Theme.Text,Font=Theme.Font,TextSize=8,AutoButtonColor=false,Parent=row}); stroke(bb,Theme.Outline,0.3); corner(bb,2); bb.MouseButton1Click:Connect(cb) end
    sbtn("Copy", 236, function() if setclipboard then setclipboard(id) end end)
    sbtn("Play", 278, function() selLogger() ; switchPage("Preview"); loadPreview(id) end)
    sbtn("Save", 320, function() Favorites[id]={name=LoggedAnims[id].name, notes="Logged"}; refreshFavs() end)
    sbtn("Del",  362, function() row:Destroy(); LoggedAnims[id]=nil end)
end

-- ==================== HIT IDS PAGE ====================
local HitPage = makePage("HitIDs")
local HitHead = new("Frame", {Size=UDim2.new(1,0,0,26), BackgroundColor3=Theme.Element, Parent=HitPage}); corner(HitHead,4)
new("TextLabel", {Size=UDim2.fromOffset(90,26), Position=UDim2.fromOffset(8,0), BackgroundTransparency=1, Text="HIT IDS", TextColor3=Theme.Accent, Font=Theme.Font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=HitHead})
local HitToggle = new("TextButton", {Size=UDim2.fromOffset(48,16), Position=UDim2.fromOffset(90,5), BackgroundColor3=Theme.Good, Text="ON", TextColor3=Color3.new(1,1,1), Font=Theme.Font, TextSize=9, AutoButtonColor=false, Parent=HitHead}); corner(HitToggle,3)
HitToggle.MouseButton1Click:Connect(function()
    HitIDEnabled = not HitIDEnabled
    HitToggle.Text = HitIDEnabled and "ON" or "OFF"
    HitToggle.BackgroundColor3 = HitIDEnabled and Theme.Good or Theme.Bad
end)
local ClearHit = new("TextButton", {Size=UDim2.fromOffset(48,16), Position=UDim2.fromOffset(144,5), BackgroundColor3=Theme.Sidebar, Text="Clear", TextColor3=Theme.Text, Font=Theme.Font, TextSize=9, AutoButtonColor=false, Parent=HitHead}); stroke(ClearHit,Theme.Outline,0.4); corner(ClearHit,3)
ClearHit.MouseButton1Click:Connect(function()
    for _,r in pairs(HitRows) do if r.Parent then r:Destroy() end end
    HitRows={}; HitIDs={}
end)
new("TextLabel", {Size=UDim2.new(1,-200,0,26), Position=UDim2.new(0,200,0,0), BackgroundTransparency=1, Text="[MY] your moves   [HIT] hit you", TextColor3=Theme.Sub, Font=Theme.Font, TextSize=8, TextXAlignment=Enum.TextXAlignment.Right, Parent=HitHead})

local HitScroll = new("ScrollingFrame", {Size=UDim2.new(1,0,1,-30), Position=UDim2.fromOffset(0,30), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(), Parent=HitPage})
new("UIListLayout", {Padding=UDim.new(0,2), Parent=HitScroll})

function addHitID(id, nm, isMine)
    if HitIDs[id] then return end
    HitIDs[id] = {id=id, name=nm or "HitAnim", time=os.date("%X"), mine=isMine or false}
    local row = new("Frame", {Size=UDim2.new(1,-4,0,20), BackgroundColor3=Theme.Element, Parent=HitScroll}); stroke(row,Theme.Outline,0.3); corner(row,3)
    HitRows[#HitRows+1] = row
    local tag = isMine and "[MY]" or "[HIT]"
    new("TextLabel", {Size=UDim2.fromOffset(196,20), Position=UDim2.fromOffset(6,0), BackgroundTransparency=1, Text=tag.." "..HitIDs[id].name, TextColor3=isMine and Theme.Good or Theme.Warn, Font=Theme.Font, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=row})
    local function sbtn(t,x,cb) local bb=new("TextButton",{Size=UDim2.fromOffset(36,14),Position=UDim2.fromOffset(x,3),BackgroundColor3=Theme.Sidebar,Text=t,TextColor3=Theme.Text,Font=Theme.Font,TextSize=7,AutoButtonColor=false,Parent=row}); stroke(bb,Theme.Outline,0.3); corner(bb,2); bb.MouseButton1Click:Connect(cb) end
    sbtn("Copy", 210, function() if setclipboard then setclipboard(id) end end)
    sbtn("Play", 248, function() switchPage("Preview"); loadPreview(id) end)
    sbtn("Save", 286, function() Favorites[id]={name=HitIDs[id].name, notes="HitID"}; refreshFavs() end)
    sbtn("Del",  324, function() row:Destroy(); HitIDs[id]=nil end)
end

-- ==================== PREVIEW 3D ====================
local PreviewPage = makePage("Preview")
local CtrlBar = new("Frame", {Size=UDim2.new(1,0,0,58), Position=UDim2.fromOffset(0,0), BackgroundColor3=Theme.Element, Parent=PreviewPage}); stroke(CtrlBar,Theme.Outline,0.4); corner(CtrlBar,4)
local IDBox = new("TextBox", {Size=UDim2.fromOffset(250,18), Position=UDim2.fromOffset(6,5), BackgroundColor3=Theme.Sidebar, Text="rbxassetid://", TextColor3=Theme.Text, Font=Theme.Font, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=CtrlBar}); stroke(IDBox,Theme.Outline,0.4); corner(IDBox,3)
local LoadBtn = new("TextButton", {Size=UDim2.fromOffset(48,18), Position=UDim2.fromOffset(260,5), BackgroundColor3=Theme.Accent, Text="LOAD", TextColor3=Color3.new(1,1,1), Font=Theme.Font, TextSize=9, AutoButtonColor=false, Parent=CtrlBar}); corner(LoadBtn,3)
LoadBtn.MouseButton1Click:Connect(function() loadPreview(IDBox.Text) end)

local function ctrlBtn(txt, x, cb)
    local b = new("TextButton", {Size=UDim2.fromOffset(46,18), Position=UDim2.fromOffset(x,30), BackgroundColor3=Theme.Sidebar, Text=txt, TextColor3=Theme.Text, Font=Theme.Font, TextSize=8, AutoButtonColor=false, Parent=CtrlBar}); stroke(b,Theme.Outline,0.3); corner(b,3)
    b.MouseButton1Click:Connect(cb); return b
end
ctrlBtn("PLAY", 6,   function() if CurrentPreviewTrack then CurrentPreviewTrack:Play() end end)
ctrlBtn("STOP", 56,  function() if CurrentPreviewTrack then CurrentPreviewTrack:Stop() end end)
ctrlBtn("PAUSE",106, function() if CurrentPreviewTrack then CurrentPreviewTrack:AdjustSpeed(CurrentPreviewTrack.Speed==0 and speed or 0) end end)
ctrlBtn("LOOP", 156, function() if CurrentPreviewTrack then CurrentPreviewTrack.Looped = not CurrentPreviewTrack.Looped end end)
ctrlBtn("RESET",206, function() recreateDummy() end)
ctrlBtn("CLEAR",256, function() cleanupPreview() end)

local SpeedLabel = new("TextLabel", {Size=UDim2.fromOffset(110,18), Position=UDim2.fromOffset(316,5), BackgroundTransparency=1, Text="Speed: 1.00x", TextColor3=Theme.Text, Font=Theme.Font, TextSize=9, TextXAlignment=Enum.TextXAlignment.Right, Parent=CtrlBar})
local SpeedBar = new("TextButton", {Size=UDim2.fromOffset(116,8), Position=UDim2.fromOffset(312,33), BackgroundColor3=Theme.Sidebar, Text="", AutoButtonColor=false, Parent=CtrlBar}); stroke(SpeedBar,Theme.Outline,0.3); corner(SpeedBar,2)
local SpeedFill = new("Frame", {Size=UDim2.fromScale(0.5,1), BackgroundColor3=Theme.Accent, Parent=SpeedBar}); corner(SpeedFill,2)
local dragSp=false
SpeedBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragSp=true end end)
UserInputService.InputChanged:Connect(function(i)
    if dragSp and i.UserInputType==Enum.UserInputType.MouseMovement then
        local rel = math.clamp((i.Position.X - SpeedBar.AbsolutePosition.X)/math.max(SpeedBar.AbsoluteSize.X,1), 0, 1)
        speed = math.floor(rel*40+0.5)/20  -- 0 .. 2.0x
        SpeedFill.Size = UDim2.fromScale(rel,1)
        SpeedLabel.Text = "Speed: "..string.format("%.2f", speed).."x"
        if CurrentPreviewTrack then CurrentPreviewTrack:AdjustSpeed(speed) end
    end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragSp=false end end)

local Viewport = new("ViewportFrame", {Size=UDim2.new(1,0,1,-86), Position=UDim2.fromOffset(0,62), BackgroundColor3=Color3.fromRGB(6,4,5), BorderSizePixel=0, Ambient=Color3.fromRGB(150,150,150), LightColor=Color3.fromRGB(255,255,255), Parent=PreviewPage}); corner(Viewport,5); stroke(Viewport,Theme.Outline,0.6)
local World = new("WorldModel", {Parent=Viewport})
local Cam = new("Camera", {Parent=Viewport}); Viewport.CurrentCamera = Cam
local PrevStatus = new("TextLabel", {Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,1,-18), BackgroundTransparency=1, Text="Load an ID from Logger / Hit IDs / Popular, or type above.", TextColor3=Theme.Sub, Font=Theme.Font, TextSize=8, Parent=PreviewPage})

-- a full R15 dummy as a fallback when you have no character to clone
function buildFallbackRig()
    local m = new("Model", {Name="PreviewDummy"})
    local function part(n,sz) return new("Part",{Name=n,Size=sz,Anchored=false,CanCollide=false,Color=Color3.fromRGB(200,80,95),Parent=m}) end
    local hrp = part("HumanoidRootPart", Vector3.new(2,2,1)); hrp.Transparency=1; hrp.Anchored=true
    local lt  = part("LowerTorso", Vector3.new(2,0.9,1))
    local ut  = part("UpperTorso", Vector3.new(2,1.7,1))
    local hd  = part("Head", Vector3.new(1.4,1.4,1.4))
    local lua_, lla, lh = part("LeftUpperArm",Vector3.new(0.9,1.3,0.9)),  part("LeftLowerArm",Vector3.new(0.9,1.2,0.9)),  part("LeftHand",Vector3.new(0.9,0.4,0.9))
    local rua, rla, rh  = part("RightUpperArm",Vector3.new(0.9,1.3,0.9)), part("RightLowerArm",Vector3.new(0.9,1.2,0.9)), part("RightHand",Vector3.new(0.9,0.4,0.9))
    local lul = part("LeftUpperLeg",  Vector3.new(1,1.5,1)); local lll = part("LeftLowerLeg",  Vector3.new(1,1.4,1)); local lf = part("LeftFoot",  Vector3.new(1,0.4,1))
    local rul = part("RightUpperLeg", Vector3.new(1,1.5,1)); local rll = part("RightLowerLeg", Vector3.new(1,1.4,1)); local rf = part("RightFoot", Vector3.new(1,0.4,1))
    local hum = new("Humanoid", {Parent=m, RigType=Enum.HumanoidRigType.R15})
    new("Animator", {Parent=hum})
    local function joint(name, p0, p1, c0, c1) new("Motor6D",{Name=name,Part0=p0,Part1=p1,C0=c0 or CFrame.new(),C1=c1 or CFrame.new(),Parent=p0}) end
    joint("Root", hrp, lt, CFrame.new(0,0,0), CFrame.new(0,0,0))
    joint("Waist", lt, ut, CFrame.new(0,0.45,0), CFrame.new(0,-0.85,0))
    joint("Neck", ut, hd, CFrame.new(0,0.85,0), CFrame.new(0,-0.7,0))
    joint("LeftShoulder", ut, lua_, CFrame.new(-1.45,0.55,0), CFrame.new(0,0.65,0))
    joint("LeftElbow", lua_, lla, CFrame.new(0,-0.65,0), CFrame.new(0,0.6,0))
    joint("LeftWrist", lla, lh, CFrame.new(0,-0.6,0), CFrame.new(0,0.2,0))
    joint("RightShoulder", ut, rua, CFrame.new(1.45,0.55,0), CFrame.new(0,0.65,0))
    joint("RightElbow", rua, rla, CFrame.new(0,-0.65,0), CFrame.new(0,0.6,0))
    joint("RightWrist", rla, rh, CFrame.new(0,-0.6,0), CFrame.new(0,0.2,0))
    joint("LeftHip", lt, lul, CFrame.new(-0.5,-0.45,0), CFrame.new(0,0.75,0))
    joint("LeftKnee", lul, lll, CFrame.new(0,-0.75,0), CFrame.new(0,0.7,0))
    joint("LeftAnkle", lll, lf, CFrame.new(0,-0.7,0), CFrame.new(0,0.2,0))
    joint("RightHip", lt, rul, CFrame.new(0.5,-0.45,0), CFrame.new(0,0.75,0))
    joint("RightKnee", rul, rll, CFrame.new(0,-0.75,0), CFrame.new(0,0.7,0))
    joint("RightAnkle", rll, rf, CFrame.new(0,-0.7,0), CFrame.new(0,0.2,0))
    m.PrimaryPart = hrp
    return m
end

function cleanupPreview()
    if CurrentPreviewTrack then pcall(function() CurrentPreviewTrack:Stop(0) end); CurrentPreviewTrack=nil end
    if CurrentDummy then pcall(function() CurrentDummy:Destroy() end); CurrentDummy=nil end
    for _,c in ipairs(World:GetChildren()) do pcall(function() c:Destroy() end) end
end

-- Clone YOUR character so the rig matches the game's animations exactly.
function recreateDummy()
    cleanupPreview()
    local dummy
    local src = LocalPlayer.Character
    if src and src:FindFirstChildOfClass("Humanoid") then
        local ok, clone = pcall(function()
            local was = src.Archivable; src.Archivable = true
            local c = src:Clone(); src.Archivable = was; return c
        end)
        if ok and clone then dummy = clone end
    end
    if not dummy then dummy = buildFallbackRig() end

    -- sanitize the clone so it just stands and animates
    for _,d in ipairs(dummy:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool")
        or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") or d:IsA("Sound") then
            pcall(function() d:Destroy() end)
        end
    end
    dummy.Name = "PreviewDummy"
    local hum = dummy:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        if not hum:FindFirstChildOfClass("Animator") then new("Animator", {Parent=hum}) end
        for _,t in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
    end
    local hrp = dummy:FindFirstChild("HumanoidRootPart") or dummy.PrimaryPart
    if hrp then hrp.Anchored = true end
    dummy.Parent = World
    pcall(function() dummy:PivotTo(CFrame.new(0, 3, 0)) end)

    CurrentDummy = dummy
    if hrp then Cam.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 0.5, -8), hrp.Position) end
    return dummy
end

function loadPreview(idStr)
    if not idStr or idStr=="" then idStr = IDBox.Text end
    idStr = tostring(idStr)
    if not idStr:find("rbxassetid://") then idStr = "rbxassetid://"..idStr:gsub("%D","") end
    if idStr:gsub("%D","")=="" then PrevStatus.Text="Invalid ID."; return end
    IDBox.Text = idStr

    local dummy = recreateDummy()
    local hum = dummy and dummy:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then PrevStatus.Text="No rig/animator."; return end

    local anim = new("Animation", {AnimationId=idStr})
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        CurrentPreviewTrack = track
        track.Looped = true
        track:Play()
        track:AdjustSpeed(speed)
        PrevStatus.Text = "Playing "..idStr
    else
        PrevStatus.Text = "Failed to load animation (id may be private/invalid)."
    end
end

-- THE FIX that makes the preview actually animate: ViewportFrame models don't
-- auto-advance animations, so step the Animator ourselves every frame.
RunService.RenderStepped:Connect(function(dt)
    if not (CurrentDummy and CurrentPreviewTrack) then return end
    local hum = CurrentDummy:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then pcall(function() animator:StepAnimations(dt) end) end
end)

-- ==================== FAVORITES ====================
local FavsPage = makePage("Favs")
local FavHead = new("Frame", {Size=UDim2.new(1,0,0,26), BackgroundColor3=Theme.Element, Parent=FavsPage}); corner(FavHead,4)
new("TextLabel", {Size=UDim2.fromOffset(100,26), Position=UDim2.fromOffset(8,0), BackgroundTransparency=1, Text="FAVORITES", TextColor3=Theme.Accent, Font=Theme.Font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=FavHead})
local ExportBtn = new("TextButton", {Size=UDim2.fromOffset(56,16), Position=UDim2.fromOffset(108,5), BackgroundColor3=Theme.Sidebar, Text="Export", TextColor3=Theme.Text, Font=Theme.Font, TextSize=8, AutoButtonColor=false, Parent=FavHead}); stroke(ExportBtn,Theme.Outline,0.4); corner(ExportBtn,3)
ExportBtn.MouseButton1Click:Connect(function()
    local t=""; for id,d in pairs(Favorites) do t=t..d.name.." = "..id.."\n" end
    if setclipboard then setclipboard(t) end
end)
local FavScroll = new("ScrollingFrame", {Size=UDim2.new(1,0,1,-30), Position=UDim2.fromOffset(0,30), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(), Parent=FavsPage})
new("UIListLayout", {Padding=UDim.new(0,2), Parent=FavScroll})

function refreshFavs()
    for _,c in ipairs(FavScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for id,d in pairs(Favorites) do
        local row = new("Frame", {Size=UDim2.new(1,-4,0,18), BackgroundColor3=Theme.Element, Parent=FavScroll}); stroke(row,Theme.Outline,0.3); corner(row,3)
        new("TextLabel", {Size=UDim2.fromOffset(190,18), Position=UDim2.fromOffset(6,0), BackgroundTransparency=1, Text=d.name, TextColor3=Theme.Text, Font=Theme.Font, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=row})
        local pb = new("TextButton", {Size=UDim2.fromOffset(34,13), Position=UDim2.fromOffset(204,2.5), BackgroundColor3=Theme.Sidebar, Text="Play", TextColor3=Theme.Text, Font=Theme.Font, TextSize=7, AutoButtonColor=false, Parent=row}); stroke(pb,Theme.Outline,0.3); corner(pb,2)
        pb.MouseButton1Click:Connect(function() switchPage("Preview"); loadPreview(id) end)
        local db = new("TextButton", {Size=UDim2.fromOffset(30,13), Position=UDim2.fromOffset(240,2.5), BackgroundColor3=Theme.Bad, Text="Del", TextColor3=Color3.new(1,1,1), Font=Theme.Font, TextSize=7, AutoButtonColor=false, Parent=row}); corner(db,2)
        db.MouseButton1Click:Connect(function() Favorites[id]=nil; refreshFavs() end)
    end
end

-- ==================== POPULAR ====================
local PopPage = makePage("Popular")
local PopHead = new("Frame", {Size=UDim2.new(1,0,0,26), BackgroundColor3=Theme.Element, Parent=PopPage}); corner(PopHead,4)
new("TextLabel", {Size=UDim2.fromOffset(220,26), Position=UDim2.fromOffset(8,0), BackgroundTransparency=1, Text="POPULAR ("..DETECTED_GAME..")", TextColor3=Theme.Accent, Font=Theme.Font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, Parent=PopHead})
local PopScroll = new("ScrollingFrame", {Size=UDim2.new(1,0,1,-30), Position=UDim2.fromOffset(0,30), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(), Parent=PopPage})
new("UIListLayout", {Padding=UDim.new(0,2), Parent=PopScroll})
local function addPop(id, nm)
    local row = new("Frame", {Size=UDim2.new(1,-4,0,18), BackgroundColor3=Theme.Element, Parent=PopScroll}); stroke(row,Theme.Outline,0.3); corner(row,3)
    new("TextLabel", {Size=UDim2.fromOffset(200,18), Position=UDim2.fromOffset(6,0), BackgroundTransparency=1, Text=nm, TextColor3=Theme.Text, Font=Theme.Font, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=row})
    local pb = new("TextButton", {Size=UDim2.fromOffset(34,13), Position=UDim2.fromOffset(212,2.5), BackgroundColor3=Theme.Sidebar, Text="Play", TextColor3=Theme.Text, Font=Theme.Font, TextSize=7, AutoButtonColor=false, Parent=row}); stroke(pb,Theme.Outline,0.3); corner(pb,2)
    pb.MouseButton1Click:Connect(function() switchPage("Preview"); loadPreview(id) end)
    local sb = new("TextButton", {Size=UDim2.fromOffset(34,13), Position=UDim2.fromOffset(248,2.5), BackgroundColor3=Theme.Sidebar, Text="Save", TextColor3=Theme.Text, Font=Theme.Font, TextSize=7, AutoButtonColor=false, Parent=row}); stroke(sb,Theme.Outline,0.3); corner(sb,2)
    sb.MouseButton1Click:Connect(function() Favorites[id]={name=nm, notes="Popular"}; refreshFavs() end)
end
if DETECTED_GAME=="JJS" then for _,v in ipairs(JJS_POPULAR) do addPop(v.id, v.name) end
elseif DETECTED_GAME=="TSB" then for _,v in ipairs(TSB_POPULAR) do addPop(v.id, v.name) end
else
    for _,v in ipairs(JJS_POPULAR) do addPop(v.id, v.name.." (JJS)") end
    for _,v in ipairs(TSB_POPULAR) do addPop(v.id, v.name.." (TSB)") end
end

-- ==================== SETTINGS ====================
local SetPage = makePage("Settings")
local sBox = new("Frame", {Size=UDim2.new(1,0,0,116), Position=UDim2.fromOffset(0,0), BackgroundColor3=Theme.Element, Parent=SetPage}); stroke(sBox,Theme.Outline,0.4); corner(sBox,5)
new("TextLabel", {Size=UDim2.fromOffset(120,18), Position=UDim2.fromOffset(8,6), BackgroundTransparency=1, Text="SETTINGS v1.2", TextColor3=Theme.Accent, Font=Theme.Font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, Parent=sBox})
new("TextLabel", {Size=UDim2.new(1,-16,0,80), Position=UDim2.fromOffset(8,26), BackgroundTransparency=1, Text="- Draggable header (drag the top bar)\n- Preview clones YOUR character + steps anims each frame (PLAY works)\n- Logger + Hit IDs grab real rbxassetid anim IDs\n- Hit IDs = your moves [MY] + enemy attacks that reached you [HIT]\n- Favorites persist this session (Export copies them)\n- RightShift = show/hide the whole hub", TextColor3=Theme.Sub, Font=Theme.Font, TextSize=8, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, Parent=sBox})
local UnloadB = new("TextButton", {Size=UDim2.fromOffset(80,20), Position=UDim2.fromOffset(0,124), BackgroundColor3=Theme.Bad, Text="UNLOAD", TextColor3=Color3.new(1,1,1), Font=Theme.Font, TextSize=9, AutoButtonColor=false, Parent=SetPage}); corner(UnloadB,3)
UnloadB.MouseButton1Click:Connect(function() pcall(cleanupPreview); Screen:Destroy() end)

-- ==================== LOGGER CORE (dedup hooks) ====================
local function hookAnim(animator, isLocal)
    if not animator or hookedAnimators[animator] then return end
    hookedAnimators[animator] = true
    local c = animator.AnimationPlayed:Connect(function(track)
        local a = track and track.Animation
        if not a then return end
        local id = tostring(a.AnimationId or "")
        if id=="" or not id:find("rbxassetid") then return end
        if LoggerEnabled then addLogged(id, a.Name or "Anim") end
        if HitIDEnabled and isLocal then addHitID(id, a.Name or "MyMove", true) end
    end)
    table.insert(LoggerConns, c)
end

local function scanAll()
    for _,p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local an = h and h:FindFirstChildOfClass("Animator")
        if an then hookAnim(an, p==LocalPlayer) end
    end
end
task.spawn(function() while true do scanAll(); task.wait(2.5) end end)
for _,p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(ch)
        local h = ch:WaitForChild("Humanoid", 6)
        local an = h and h:WaitForChild("Animator", 6)
        if an then hookAnim(an, p==LocalPlayer) end
    end)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(ch)
        local h = ch:WaitForChild("Humanoid", 6)
        local an = h and h:WaitForChild("Animator", 6)
        if an then hookAnim(an, p==LocalPlayer) end
    end)
end)

-- ==================== HIT-ON-ME DETECTION ====================
local function detectHitsOnMe()
    if not HitIDEnabled or not LocalPlayer.Character then return end
    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            local an = h and h:FindFirstChildOfClass("Animator")
            if hrp and an and (hrp.Position-myHRP.Position).Magnitude < 22 then
                for _,tr in ipairs(an:GetPlayingAnimationTracks()) do
                    if tr.IsPlaying and tr.Animation and tr.Animation.AnimationId~="" then
                        addHitID(tostring(tr.Animation.AnimationId), tr.Animation.Name or "EnemyHit", false)
                    end
                end
            end
        end
    end
end
task.spawn(function() while true do detectHitsOnMe(); task.wait(1.0) end end)

-- ==================== SEARCH FILTER ====================
local function filterScroll(scroll, q)
    for _,r in ipairs(scroll:GetChildren()) do
        if r:IsA("Frame") then local l=r:FindFirstChildOfClass("TextLabel"); r.Visible = q=="" or (l~=nil and l.Text:lower():find(q,1,true)~=nil) end
    end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBox.Text:lower()
    filterScroll(LogScroll, q); filterScroll(HitScroll, q); filterScroll(FavScroll, q); filterScroll(PopScroll, q)
end)

-- ==================== RIGHTSHIFT TOGGLE (now wired) ====================
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode==Enum.KeyCode.RightShift then Win.Visible = not Win.Visible end
end)

-- ==================== INIT ====================
selLogger()       -- highlight + show Logger tab
refreshFavs()
print("[Vaultix AnimGrabber v1.2] loaded for "..DETECTED_GAME..". Draggable. Preview clones your rig + steps anims. RightShift toggles.")
