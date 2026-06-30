--[[  Inf Food · Carnivore + Safe AFK · FIXED v2
  Fixes vs original:
   - Cleanup is now REGISTERED (__gg.__PE_INF_FOOD = onClose) so re-running the
     script tears down the old GUI/loops instead of stacking them.
   - The __namecall hook installs ONCE globally and feeds the current run through
     __gg globals (replica id / eat buffer / food ids / inf-food flag), so re-runs
     work without stacking hooks.
   - Safe AFK ANCHORS your body in the sky (reliable, no fall damage, no camera
     fight) and re-anchors if the server moves you; restores + drops you on off.
]]

local __gg = (typeof(getgenv)=="function") and getgenv() or _G
if __gg.__PE_INF_FOOD then pcall(__gg.__PE_INF_FOOD) end   -- tear down previous run
__gg.__PE_INF_FOOD = nil

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local WS         = game:GetService("Workspace")
local CoreGui    = game:GetService("CoreGui")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local RUNNING    = true
local InfFoodOn  = false
local AutoScanOn = false
local SafeAfkOn  = false
local maxHunger  = 100
local curHunger  = 0
local scannedObjs= {}
local savedPos   = nil
local skyY       = 2500
local scanCount  = 0

local hookmeta    = hookmetamethod
local getnamecall = getnamecallmethod
local checkcaller = checkcaller or function() return false end

local fireprox
if fireproximityprompt then
    fireprox = fireproximityprompt
else
    fireprox = function(pp) pcall(function() pp:InputHoldBegin(); task.wait(0.15); pp:InputHoldEnd() end) end
end

local function safeParentGui(g)
    pcall(function()
        if typeof(gethui)=="function" then g.Parent=gethui()
        elseif typeof(syn)=="table" and syn.protect_gui then syn.protect_gui(g); g.Parent=CoreGui
        else g.Parent=CoreGui end
    end)
    if not g.Parent then g.Parent=LP:WaitForChild("PlayerGui") end
end

local function notify(t, tx)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=t or "",Text=tx or "",Duration=3}) end)
end

local function getMyModel()
    return (WS:FindFirstChild("Characters") and WS.Characters:FindFirstChild(LP.Name)) or LP.Character
end
local function hrp()
    local m = getMyModel()
    if m then
        local ta = m:FindFirstChild("TurningAnimation")
        if ta then local b = ta:FindFirstChild("Body"); if b and b:IsA("BasePart") then return b end end
        return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local _sig
local function getSig()
    if _sig and _sig.Parent then return _sig end
    local r = RS:FindFirstChild("RemoteEvents")
    _sig = r and r:FindFirstChild("ReplicaSignal")
    return _sig
end

local CharacterState
pcall(function()
    local cm = RS:FindFirstChild("Common")
    local cs = cm and cm:FindFirstChild("CharacterState")
    if cs then CharacterState = require(cs) end
end)

local function fixCamera()
    pcall(function()
        local cam = WS.CurrentCamera; if not cam then return end
        local camc = CharacterState and CharacterState.Camera
        if camc then
            pcall(function() camc.LockToTarget = nil end)
            pcall(function() camc._zoomedIn = false end)
            pcall(function() camc.LockOverride = nil end)
            if type(camc.SetMouseLock)=="function" then pcall(function() camc:SetMouseLock(false) end) end
            if type(camc.Refresh)=="function" then camc:Refresh() end
            pcall(function()
                if type(camc.ForceZoomChange)=="function" then
                    local zoom = tonumber(camc.maxCameraZoom) or tonumber(camc.ZoomDistance) or 30
                    camc:ForceZoomChange(zoom)
                end
            end)
        end
        cam.CameraType = Enum.CameraType.Custom
        LP.CameraMode = Enum.CameraMode.Classic
        pcall(function() LP.CameraMaxZoomDistance = math.max(LP.CameraMaxZoomDistance or 128, 128) end)
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        pcall(function() UIS.MouseIconEnabled = true end)
    end)
end

-- FOOD KEYWORDS
local HERB_KW = {"berry","berries","plant","sapling","tree","fern","blechnace","gleichenia","osmunda","horsetail","redwood","gingko","ginkgo","sequoia","woodwardia","sabalite","equisetum","coniopteris","paleoaster","dryophyllum","elatides","dicksonia","williamsonia","wielandiella","weichselia","ptilophyllum","pachypteris","cycadeoidea","pine","needle","leaf","leaves","frond","conifer","cycad","fungus","mushroom","shoot","sprout","grass","moss","bush","shrub","flower","seed","cone","zingiberopsis","ditaxocladus","marmarthia","matonidium","hermanophyton","araucaria"}
local CARN_KW = {"corpse","carcass","rotten","meat","chunk","fish","egg","ant","anthill","termite","meganeura","lepisosteus","gar","acipenser","onchopristis","insect","grub","larva","carrion","sturgeon","bichir","coelacanth","mawsonia","concavotectum","bawitius","sawfish"}
local ALL_KW = {}
for _,k in ipairs(HERB_KW) do ALL_KW[k]="herb" end
for _,k in ipairs(CARN_KW) do ALL_KW[k]="carn" end
local function isFood(n)
    n = n:lower()
    for k,_ in pairs(ALL_KW) do if n:find(k,1,true) then return true end end
    return false
end

-- HOOK - install ONCE globally; feed current run via __gg globals.
local function installHook()
    if __gg.__PE_HOOKED or not hookmeta then return end
    __gg.__PE_HOOKED = true
    pcall(function()
        local oldNC
        oldNC = hookmeta(game, "__namecall", function(self, ...)
            local m = getnamecall and getnamecall()
            if (m == "FireServer" or m == "InvokeServer") and not checkcaller() then
                local a = table.pack(...)
                local rn = ""; pcall(function() rn = self.Name end)
                if rn == "ReplicaSignal" then
                    local id = a[1]; local action = a[2]
                    if typeof(id) == "number" then
                        if action == "Bite" and a.n >= 3 then
                            if id ~= __gg.MH_replicaId then
                                __gg.MH_foodIds = __gg.MH_foodIds or {}
                                __gg.MH_foodIds[id] = true
                                __gg.MH_eatBuf = a[3]
                                __gg.MH_eatCount = (__gg.MH_eatCount or 0) + 1
                            end
                        elseif action ~= "Sip" and action ~= "Eat" and action ~= "Consume" then
                            __gg.MH_replicaId = id   -- your own stat calls reveal your replica id
                        end
                    end
                    if __gg.MH_infFoodOn and typeof(action) == "string" then
                        local la = action:lower()
                        if la:find("drainhunger",1,true) or la:find("reducehunger",1,true)
                        or la:find("consumehunger",1,true) or la:find("hungerdrain",1,true)
                        or la:find("hungercost",1,true) or la:find("starve",1,true)
                        or la:find("hungerpenalty",1,true) or la:find("hungerreduce",1,true) then
                            return
                        end
                        if action == "SetProperty" and typeof(a[3]) == "string" then
                            local prop = a[3]:lower()
                            if (prop:find("hunger",1,true) or prop:find("food",1,true))
                            and typeof(a[4]) == "number" and a[4] < (tonumber(__gg.MH_maxHunger) or 100) * 0.95 then
                                return
                            end
                        end
                    end
                end
            end
            return oldNC(self, ...)
        end)
    end)
end
pcall(installHook)

-- Stats
local function readStats()
    pcall(function()
        if not CharacterState then return end
        local r = CharacterState.Replica
        if not r or not r.Data then return end
        local s, ms = r.Data.Stats, r.Data.MaxStats
        if s then local h = s.Hunger or s.Food; if typeof(h)=="number" then curHunger=h end end
        if ms then local mh = ms.Hunger or ms.Food or ms.MaxHunger; if typeof(mh)=="number" and mh>0 then maxHunger=mh end end
        pcall(function()
            if r.Data.Hunger then
                curHunger = tonumber(r.Data.Hunger.Delta) or curHunger
                maxHunger = tonumber(r.Data.Hunger.Max) or maxHunger
            end
        end)
        -- learn your replica id from the replica itself if the hook hasn't yet
        if not __gg.MH_replicaId then
            local id = r.Id or (r.Data and r.Data.ReplicaId)
            if typeof(id)=="number" then __gg.MH_replicaId = id end
        end
        __gg.MH_maxHunger = maxHunger
    end)
end

-- SCAN (eat nearby food/corpse prompts)
local function fireAllPrompts(obj, counter)
    for _,pp in ipairs(obj:GetDescendants()) do
        if pp:IsA("ProximityPrompt") then pcall(function() fireprox(pp) end); counter[1]=counter[1]+1 end
    end
end
local function scanAndEat()
    local found = {0}
    for _,pp in ipairs(WS:GetDescendants()) do
        if pp:IsA("ProximityPrompt") and not scannedObjs[pp] then
            local txt = pp.Name:lower(); pcall(function() txt = pp.ActionText:lower() end)
            if txt:find("eat",1,true) or txt:find("consume",1,true) or txt:find("feed",1,true)
            or txt:find("bite",1,true) or txt:find("carcass",1,true) or txt:find("corpse",1,true)
            or txt:find("forage",1,true) or txt:find("graze",1,true) or txt:find("drink",1,true)
            or txt:find("sip",1,true) then
                scannedObjs[pp]=true; pcall(function() fireprox(pp) end); found[1]=found[1]+1
            end
        end
    end
    local chars = WS:FindFirstChild("Characters")
    if chars then for _,c in ipairs(chars:GetChildren()) do
        if c:IsA("Model") and c.Name~=LP.Name and not scannedObjs[c] then
            local dead = false
            pcall(function() local h=c:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then dead=true end end)
            local ln=c.Name:lower(); if ln:find("dead",1,true) or ln:find("corpse",1,true) or ln:find("carcass",1,true) then dead=true end
            if dead then scannedObjs[c]=true; fireAllPrompts(c, found) end
        end
    end end
    for _,obj in ipairs(WS:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and not scannedObjs[obj] and isFood(obj.Name) then
            scannedObjs[obj]=true; fireAllPrompts(obj, found)
        end
    end
    scanCount = scanCount + found[1]
    return found[1]
end

-- SAFE AFK: PivotTo to sky + ANCHOR the body so you don't fall / fight camera.
local anchoredParts = {}
local function setAnchored(on)
    local m = getMyModel(); if not m then return end
    if on then
        for _,p in ipairs(m:GetDescendants()) do
            if p:IsA("BasePart") and not anchoredParts[p] then anchoredParts[p]=p.Anchored; p.Anchored=true end
        end
    else
        for p,orig in pairs(anchoredParts) do if p and p.Parent then pcall(function() p.Anchored=orig end) end end
        anchoredParts = {}
    end
end
local function goToSky()
    local model = getMyModel(); local root = hrp()
    if not (model and root) then return false end
    if not savedPos then savedPos = root.CFrame end
    local target = Vector3.new(root.Position.X, skyY, root.Position.Z)
    setAnchored(false)  -- unanchor to allow the move
    pcall(function()
        if model.PrimaryPart then model:PivotTo(CFrame.new(target)) else model:MoveTo(target) end
    end)
    task.wait(0.05)
    setAnchored(true)   -- pin in the sky
    task.defer(fixCamera); task.delay(0.5, fixCamera)
    return true
end
local function leaveSky()
    setAnchored(false)
    local model = getMyModel()
    if model and savedPos then
        local back = savedPos.Position + Vector3.new(0, 50, 0)
        pcall(function() if model.PrimaryPart then model:PivotTo(CFrame.new(back)) else model:MoveTo(back) end end)
        savedPos = nil
        task.defer(fixCamera); task.delay(0.5, fixCamera)
        return true
    end
    return false
end

-- Keep in sky (re-anchor / re-teleport if the server pulled you out)
task.spawn(function()
    while RUNNING do
        task.wait(0.5)
        if SafeAfkOn then
            local root = hrp()
            if root then
                local off = savedPos and (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(savedPos.Position.X,0,savedPos.Position.Z)).Magnitude or 0
                if root.Position.Y < skyY - 50 or off > 60 then goToSky() else setAnchored(true) end
            end
        end
    end
end)

-- MAIN LOOP (pin hunger + bite food ids)
local EAT_BUF = "\027\206\000\000\001"
local frameCount = 0
local lastScan = 0
task.spawn(function()
    while RUNNING do
        RunService.Heartbeat:Wait()
        if not InfFoodOn then continue end
        local rid = __gg.MH_replicaId
        if not rid then continue end
        frameCount = frameCount + 1
        local rs = getSig()
        if rs then
            pcall(function() rs:FireServer(rid, "SetProperty", "Hunger", maxHunger) end)
            pcall(function() rs:FireServer(rid, "SetProperty", "Food", maxHunger) end)
        end
        if rs and frameCount % 2 == 0 then
            local foodIds = __gg.MH_foodIds
            if type(foodIds) == "table" and next(foodIds) then
                local buf = __gg.MH_eatBuf or EAT_BUF
                if type(buf) == "string" and buffer and buffer.fromstring then pcall(function() buf = buffer.fromstring(buf) end) end
                for fid in pairs(foodIds) do pcall(function() rs:FireServer(fid, "Bite", buf) end) end
            end
        end
        if AutoScanOn then
            local now = tick()
            if now - lastScan >= 2 then lastScan = now; scanAndEat() end
        end
    end
end)

-- ════════════════════════ GUI ════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name="InfFood_GUI"; SG.ResetOnSpawn=false; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
safeParentGui(SG)

local M = Instance.new("Frame")
M.Size=UDim2.new(0,250,0,330); M.Position=UDim2.new(0.5,-125,0.5,-165)
M.BackgroundColor3=Color3.fromRGB(14,14,18); M.BorderSizePixel=0; M.Active=true; M.Parent=SG
Instance.new("UICorner",M).CornerRadius=UDim.new(0,12)
local MS2=Instance.new("UIStroke",M); MS2.Color=Color3.fromRGB(50,220,50); MS2.Thickness=1.5

local TB=Instance.new("Frame"); TB.Size=UDim2.new(1,0,0,32); TB.BackgroundColor3=Color3.fromRGB(22,22,28); TB.BorderSizePixel=0; TB.Parent=M
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,12)
local TT=Instance.new("TextLabel"); TT.Size=UDim2.new(1,-110,1,0); TT.Position=UDim2.new(0,12,0,0); TT.BackgroundTransparency=1
TT.Text="Inf Food + Safe AFK"; TT.TextColor3=Color3.fromRGB(50,255,50); TT.Font=Enum.Font.GothamBold; TT.TextSize=14; TT.TextXAlignment=Enum.TextXAlignment.Left; TT.Parent=TB

local FixBtn=Instance.new("TextButton"); FixBtn.Size=UDim2.new(0,60,0,20); FixBtn.Position=UDim2.new(1,-92,0,6)
FixBtn.BackgroundColor3=Color3.fromRGB(40,40,80); FixBtn.Text="Fix Cam"; FixBtn.TextColor3=Color3.fromRGB(150,150,255); FixBtn.Font=Enum.Font.GothamBold; FixBtn.TextSize=9; FixBtn.Parent=TB
Instance.new("UICorner",FixBtn).CornerRadius=UDim.new(0,5)
FixBtn.MouseButton1Click:Connect(function() fixCamera(); notify("Camera","Fixed!") end)

local CBtn=Instance.new("TextButton"); CBtn.Size=UDim2.new(0,24,0,24); CBtn.Position=UDim2.new(1,-28,0,4)
CBtn.BackgroundColor3=Color3.fromRGB(70,20,20); CBtn.Text="X"; CBtn.TextColor3=Color3.fromRGB(255,80,80); CBtn.Font=Enum.Font.GothamBold; CBtn.TextSize=12; CBtn.Parent=TB
Instance.new("UICorner",CBtn).CornerRadius=UDim.new(0,6)

-- drag
local dg,ds,dp=false,nil,nil
TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=true; ds=i.Position; dp=M.Position end end)
TB.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end end)
UIS.InputChanged:Connect(function(i) if dg and i.UserInputType==Enum.UserInputType.MouseMovement then
    local d=i.Position-ds; M.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y) end end)

-- hunger bar
local BL=Instance.new("TextLabel"); BL.Size=UDim2.new(1,-24,0,14); BL.Position=UDim2.new(0,12,0,38); BL.BackgroundTransparency=1
BL.Text="Hunger: ?/?"; BL.TextColor3=Color3.fromRGB(255,160,40); BL.Font=Enum.Font.GothamBold; BL.TextSize=11; BL.TextXAlignment=Enum.TextXAlignment.Left; BL.Parent=M
local BBG=Instance.new("Frame"); BBG.Size=UDim2.new(1,-24,0,10); BBG.Position=UDim2.new(0,12,0,54); BBG.BackgroundColor3=Color3.fromRGB(35,35,42); BBG.BorderSizePixel=0; BBG.Parent=M
Instance.new("UICorner",BBG).CornerRadius=UDim.new(1,0)
local BF=Instance.new("Frame"); BF.Size=UDim2.new(0,0,1,0); BF.BackgroundColor3=Color3.fromRGB(50,220,50); BF.BorderSizePixel=0; BF.Parent=BBG
Instance.new("UICorner",BF).CornerRadius=UDim.new(1,0)

task.spawn(function()
    while RUNNING do
        task.wait(0.2); readStats()
        local p = maxHunger>0 and math.clamp(curHunger/maxHunger,0,1) or 0
        BF.Size=UDim2.new(p,0,1,0)
        BL.Text="Hunger: "..string.format("%.1f",curHunger).."/"..string.format("%.1f",maxHunger)
        BF.BackgroundColor3 = (p<0.3 and Color3.fromRGB(255,40,40)) or (p<0.6 and Color3.fromRGB(255,160,40)) or Color3.fromRGB(50,220,50)
    end
end)

local ST=Instance.new("TextLabel"); ST.Size=UDim2.new(1,-24,0,16); ST.Position=UDim2.new(0,12,0,70); ST.BackgroundTransparency=1
ST.Text="Ready"; ST.TextColor3=Color3.fromRGB(255,200,80); ST.Font=Enum.Font.Gotham; ST.TextSize=9; ST.TextWrapped=true; ST.TextXAlignment=Enum.TextXAlignment.Left; ST.Parent=M

local function makeToggle(name, y, color, cb)
    local B=Instance.new("TextButton"); B.Size=UDim2.new(1,-24,0,36); B.Position=UDim2.new(0,12,0,y); B.BackgroundColor3=Color3.fromRGB(28,28,36); B.Text=""; B.BorderSizePixel=0; B.Parent=M
    Instance.new("UICorner",B).CornerRadius=UDim.new(0,8)
    local L=Instance.new("TextLabel"); L.Size=UDim2.new(1,-56,1,0); L.Position=UDim2.new(0,10,0,0); L.BackgroundTransparency=1; L.Text=name; L.TextColor3=Color3.fromRGB(200,200,210); L.Font=Enum.Font.Gotham; L.TextSize=12; L.TextXAlignment=Enum.TextXAlignment.Left; L.Parent=B
    local Ind=Instance.new("Frame"); Ind.Size=UDim2.new(0,36,0,20); Ind.Position=UDim2.new(1,-48,0.5,-10); Ind.BackgroundColor3=Color3.fromRGB(55,55,65); Ind.BorderSizePixel=0; Ind.Parent=B
    Instance.new("UICorner",Ind).CornerRadius=UDim.new(1,0)
    local Dot=Instance.new("Frame"); Dot.Size=UDim2.new(0,14,0,14); Dot.Position=UDim2.new(0,3,0.5,-7); Dot.BackgroundColor3=Color3.fromRGB(200,200,200); Dot.BorderSizePixel=0; Dot.Parent=Ind
    Instance.new("UICorner",Dot).CornerRadius=UDim.new(1,0)
    local st=false
    B.MouseButton1Click:Connect(function()
        st=not st
        Ind.BackgroundColor3 = st and color or Color3.fromRGB(55,55,65)
        Dot.Position = st and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        L.TextColor3 = st and color or Color3.fromRGB(200,200,210)
        cb(st)
    end)
end

makeToggle("Inf Food (block + pin)", 92, Color3.fromRGB(50,220,50), function(on)
    InfFoodOn = on; __gg.MH_infFoodOn = on
    if on then notify("Inf Food","ON - drain blocked + bar pinned!") end
end)
makeToggle("Auto Scan (herb + carn)", 134, Color3.fromRGB(255,160,40), function(on)
    AutoScanOn = on; scannedObjs = {}; scanCount = 0
    if on then notify("Auto Scan","ON - scanning for food & corpses!") end
end)
makeToggle("Safe AFK (sky, anchored)", 176, Color3.fromRGB(80,160,255), function(on)
    SafeAfkOn = on
    if on then if goToSky() then notify("Safe AFK","ON - anchored in the sky!") else notify("Safe AFK","Failed - no body found"); SafeAfkOn=false end
    else if leaveSky() then notify("Safe AFK","OFF - back down!") end end
end)

local Info=Instance.new("TextLabel"); Info.Size=UDim2.new(1,-24,0,70); Info.Position=UDim2.new(0,12,0,220); Info.BackgroundTransparency=1
Info.Text="Carnivore: turn on Auto Scan near a corpse - it finds & eats them.\nSafe AFK anchors you in the sky so you can't fall. Camera stuck? Click Fix Cam."
Info.TextColor3=Color3.fromRGB(90,90,100); Info.Font=Enum.Font.Gotham; Info.TextSize=9; Info.TextWrapped=true; Info.TextXAlignment=Enum.TextXAlignment.Left; Info.Parent=M

local Cnt=Instance.new("TextLabel"); Cnt.Size=UDim2.new(1,-24,0,14); Cnt.Position=UDim2.new(0,12,0,294); Cnt.BackgroundTransparency=1
Cnt.Text="Scanned: 0 | Food IDs: 0 | Bites: 0 | RightShift=hide"; Cnt.TextColor3=Color3.fromRGB(120,120,130); Cnt.Font=Enum.Font.Gotham; Cnt.TextSize=9; Cnt.TextXAlignment=Enum.TextXAlignment.Left; Cnt.Parent=M

task.spawn(function()
    while RUNNING do
        task.wait(1)
        local foodCount = 0
        if __gg.MH_foodIds then for _ in pairs(__gg.MH_foodIds) do foodCount=foodCount+1 end end
        local parts={}
        if InfFoodOn then parts[#parts+1]="InfFood" end
        if AutoScanOn then parts[#parts+1]="Scan" end
        if SafeAfkOn then parts[#parts+1]="SKY" end
        if #parts>0 then
            ST.Text=table.concat(parts," + ").." | id:"..tostring(__gg.MH_replicaId)
            ST.TextColor3=Color3.fromRGB(80,255,80)
        else ST.Text="Ready"; ST.TextColor3=Color3.fromRGB(255,200,80) end
        Cnt.Text="Scanned: "..scanCount.." | Food IDs: "..foodCount.." | Bites: "..tostring(__gg.MH_eatCount or 0)
    end
end)

-- CLOSE / CLEANUP (now REGISTERED so re-running tears this down)
local function onClose()
    if SafeAfkOn then SafeAfkOn=false; leaveSky() end
    RUNNING=false; InfFoodOn=false; AutoScanOn=false; __gg.MH_infFoodOn=false
    setAnchored(false)
    pcall(function() SG:Destroy() end)
end
CBtn.MouseButton1Click:Connect(onClose)
__gg.__PE_INF_FOOD = onClose

UIS.InputBegan:Connect(function(i,g) if not g and i.KeyCode==Enum.KeyCode.RightShift then M.Visible = not M.Visible end end)

notify("Inf Food + Safe AFK", "Loaded (FIXED v2).")
