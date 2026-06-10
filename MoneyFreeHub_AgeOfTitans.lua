-- Titan Hub | Age of Titans | v4.16

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")

local player = Players.LocalPlayer
local UIS    = UserInputService

-- ── State ─────────────────────────────────────────────────────────────────────
local S = {
    KillAura       = false, KillAuraRange  = 40,
    SilentAim      = false,
    ExtendHitbox   = false, HitboxSize     = 15,
    ShowHitbox     = false,
    M1Expand       = false, M1Size         = 8,
    ShowExpand     = false,
    AutoUlt        = false,
    AutoFarm       = false, AutoFarmRange  = 80,
    AutoPlay       = false, AutoPlayRange  = 100,
    Noclip         = false,
    SpeedHack      = false, WalkSpeed      = 50,
    AutoSprint     = false,
    NoStun         = false,
    GodMode        = false,
    SaveSystem     = false, SaveThreshold  = 30,
    InstantRespawn = false,
    Invisible      = false,
    DesyncInvis    = false, DesyncDepth = 2000,
    ESP            = false, InfZoom        = false,
    Fullbright     = false,
    AntiAFK        = false,
    InfJump        = false, ClickTP        = false,
    Spinbot        = false, HideNames      = false,
    AntiFling      = false,
}

local ATTACK_VALS = {
    4.4666666984558105, 4.4666666984558105, 4.4666666984558105,
    4.4666666984558105, 4.4666666984558105,
}

-- ── Loop vars ─────────────────────────────────────────────────────────────────
local speedOriginal, speedStateLast  = nil, false
local invisOrigTrans, invisStateLast = {}, false
local ultClock,  ultWasFull          = 0, false
local farmClock, kauraClk           = 0, 0
local autoPlayClock                  = 0
local noStunClock, noclipClock       = 0, 0
local godRebuildClock, invisClock    = 0, 0
local espClock, fbClock, hnClock     = 0, 0, 0
local respawnClock                   = 0
local saveActive, saveClock, savePos = false, 0, Vector3.zero
local espBoxes, showHitboxBoxes      = {}, {}
local showHitboxLast                 = false
local origZoom                       = nil
local Connections                    = {}
local noclipLast                     = false
local spinAngle                      = 0
local expandPart, expandBox          = nil, nil

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function chr() return player.Character end
local function hum() local c=chr(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()
    local c=chr(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
end
local function re()
    local c=chr()
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
    local mh=hrp(); if not mh then return nil end
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
    local mh=hrp(); if not mh then return nil end
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
        expandBox.Adornee=expandPart; expandBox.Color3=Color3.fromRGB(64,110,200)
        expandBox.SurfaceColor3=Color3.fromRGB(64,110,200); expandBox.SurfaceTransparency=0.85
        expandBox.LineThickness=0.03; expandBox.Parent=workspace
    end
    local sz=S.M1Size*2; expandPart.Size=Vector3.new(sz,sz,sz)
end
local function destroyExpandVisual()
    if expandBox  then pcall(function() expandBox:Destroy()  end); expandBox=nil  end
    if expandPart then pcall(function() expandPart:Destroy() end); expandPart=nil end
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
-- ── Invisible (client-side; re-applies every frame to fight game resets) ────────
-- NOTE: In FilteringEnabled games other players render you from server data, so a
-- local transparency change can't be hidden from them by the client. This makes the
-- local effect as complete and persistent as a client script can.
local function doInvisible(state)
    pcall(function()
        local c=chr(); if not c then return end
        -- Also cover the desync clone so it doesn't appear as a second copy of you
        local targets = {c}
        if desyncClone and desyncClone.Parent then table.insert(targets, desyncClone) end
        if state then
            for _,tgt in ipairs(targets) do
                for _,pt in pairs(tgt:GetDescendants()) do
                    if pt:IsA("BasePart") then
                        if invisOrigTrans[pt]==nil then invisOrigTrans[pt]=pt.Transparency end
                        if pt.Transparency<1 then pt.Transparency=1 end
                    elseif pt:IsA("Decal") or pt:IsA("Texture") then
                        if invisOrigTrans[pt]==nil then invisOrigTrans[pt]=pt.Transparency end
                        if pt.Transparency<1 then pt.Transparency=1 end
                    elseif pt:IsA("ParticleEmitter") or pt:IsA("Trail") or pt:IsA("Beam")
                        or pt:IsA("Smoke") or pt:IsA("Fire") or pt:IsA("Sparkles") then
                        pt.Enabled=false
                    end
                end
            end
        else
            for pt,t in pairs(invisOrigTrans) do
                pcall(function()
                    if pt and pt.Parent and (pt:IsA("BasePart") or pt:IsA("Decal") or pt:IsA("Texture")) then
                        pt.Transparency=t
                    end
                end)
            end
            invisOrigTrans={}
        end
    end)
end

-- ── God Mode engine: lock EVERY client-accessible health source ────────────────
-- Covers: Humanoid.Health, NumberValue/IntValue HP objects, and numeric HP
-- attributes — each with an instant-revert change-signal hook plus a max-seen
-- tracker so it restores to the true max even if enabled mid-fight.
local HP_NAMES = {"health","hp","hitpoint","currenthp","currenthealth","life","heart","vitality","durability"}
local function isHpName(n)
    n=tostring(n):lower()
    for _,k in ipairs(HP_NAMES) do if n:find(k) then return true end end
    return false
end
local godConns      = {}
local godMaxSeen    = setmetatable({}, {__mode="k"})   -- weak: dead objects GC out
local godWatched    = setmetatable({}, {__mode="k"})
local godWatchedAttr = {}

local function clearGodConns()
    for _,c in ipairs(godConns) do pcall(function() c:Disconnect() end) end
    godConns={}
end
local function recMax(key, val)
    if type(val)~="number" then return godMaxSeen[key] end
    if not godMaxSeen[key] or val>godMaxSeen[key] then godMaxSeen[key]=val end
    return godMaxSeen[key]
end
local function findMaxCap(container, baseName)
    if not container then return nil end
    for _,form in ipairs({"Max"..tostring(baseName), tostring(baseName).."Max", "MaxHealth","MaxHP","MaxHp"}) do
        local a=container:GetAttribute(form)
        if type(a)=="number" and a>0 then return a end
    end
    for _,obj in ipairs(container:GetChildren()) do
        if (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
            local on=obj.Name:lower()
            if on:find("max") and (on:find("health") or on:find("hp")) then return obj.Value end
        end
    end
    return nil
end
local function lockValueObj(obj)
    if godWatched[obj] then return end
    godWatched[obj]=true
    local cap=findMaxCap(obj.Parent, obj.Name)
    recMax(obj, math.max(obj.Value, cap or obj.Value))
    local mx=godMaxSeen[obj]
    if mx and obj.Value<mx then pcall(function() obj.Value=mx end) end
    local c=obj.Changed:Connect(function()
        if not S.GodMode then return end
        local m=recMax(obj,obj.Value)
        if m and obj.Value<m then pcall(function() obj.Value=m end) end
    end)
    table.insert(godConns,c)
end
local function lockAttribute(container, attr)
    local key="attr:"..tostring(container)..":"..attr
    if godWatchedAttr[key] then return end
    godWatchedAttr[key]=true
    local cap=findMaxCap(container, attr)
    recMax(key, math.max(container:GetAttribute(attr) or 0, cap or container:GetAttribute(attr) or 0))
    local m0=godMaxSeen[key]
    if m0 and (container:GetAttribute(attr) or 0)<m0 then pcall(function() container:SetAttribute(attr,m0) end) end
    local c=container:GetAttributeChangedSignal(attr):Connect(function()
        if not S.GodMode then return end
        local v=container:GetAttribute(attr); if type(v)~="number" then return end
        local m=recMax(key,v)
        if m and v<m then pcall(function() container:SetAttribute(attr,m) end) end
    end)
    table.insert(godConns,c)
end
local function lockHumanoid()
    local h=hum(); if not h then return end
    -- Do NOT set BreakJointsOnDeath/RequiresNeck — they cause a frozen dead-but-alive state
    if h.MaxHealth>0 then pcall(function() h.Health=h.MaxHealth end) end
    local c=h:GetPropertyChangedSignal("Health"):Connect(function()
        if not S.GodMode then return end
        if h.MaxHealth>0 and h.Health<h.MaxHealth then
            pcall(function() h.Health=h.MaxHealth end)
        end
    end)
    table.insert(godConns,c)
    local c2=h.HealthChanged:Connect(function(hp)
        if not S.GodMode then return end
        if h.MaxHealth>0 and hp<h.MaxHealth then
            pcall(function() h.Health=h.MaxHealth end)
        end
        -- If the Humanoid slipped into Dead state, kick it back to GettingUp so we can move
        pcall(function()
            if h:GetState()==Enum.HumanoidStateType.Dead then
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end)
    table.insert(godConns,c2)
end
local function scanGodTargets()
    local containers={chr(), player, player:FindFirstChild("leaderstats")}
    for _,container in ipairs(containers) do
        if container then
            for _,obj in ipairs(container:GetDescendants()) do
                if (obj:IsA("NumberValue") or obj:IsA("IntValue"))
                   and isHpName(obj.Name) and not tostring(obj.Name):lower():find("max") then
                    lockValueObj(obj)
                end
            end
            local ok,attrs=pcall(function() return container:GetAttributes() end)
            if ok and attrs then
                for attr,v in pairs(attrs) do
                    if type(v)=="number" and isHpName(attr) and not tostring(attr):lower():find("max") then
                        lockAttribute(container,attr)
                    end
                end
            end
        end
    end
end
local function enableGodMode()
    clearGodConns()
    godWatched     = setmetatable({}, {__mode="k"})
    godWatchedAttr = {}
    lockHumanoid()
    scanGodTargets()
end
local function disableGodMode()
    clearGodConns()
end

-- ── Desync Invisible (void-clone) ──────────────────────────────────────────────
-- Real body sinks into the void (others stop seeing you at the surface); a local-only
-- clone stays where you were so you can still see yourself and pan the camera.
-- While active the server thinks you're in the void, so combat won't register here —
-- toggle off to fight. Deep void can cause fall/void-death in some games.
local desyncClone, desyncConn = nil, nil
local desyncAnchor            = nil

local function stopDesync()
    if desyncConn  then pcall(function() desyncConn:Disconnect() end);  desyncConn=nil  end
    if desyncClone then pcall(function() desyncClone:Destroy()   end);  desyncClone=nil end
    pcall(function()
        local c=chr(); local h=hum()
        if workspace.CurrentCamera and h then workspace.CurrentCamera.CameraSubject=h end
        if c and desyncAnchor then c:PivotTo(desyncAnchor) end
    end)
    desyncAnchor=nil
end

local function startDesync()
    stopDesync()
    local c=chr(); local mh=hrp(); if not c or not mh then return end
    desyncAnchor=c:GetPivot()
    -- Local-only visual clone at the surface (created client-side => not replicated)
    pcall(function()
        local clone=c:Clone()
        for _,d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy() end
        end
        for _,d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then d.Anchored=true; d.CanCollide=false; d.CanQuery=false; d.CanTouch=false end
        end
        local ch=clone:FindFirstChildOfClass("Humanoid")
        if ch then ch.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
        clone.Name=c.Name.."_Local"
        clone:PivotTo(desyncAnchor)
        clone.Parent=workspace
        desyncClone=clone
        if ch and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject=ch end
    end)
    -- Continuously park the REAL body in the void so others can't see you at the surface
    desyncConn=RunService.Heartbeat:Connect(function()
        if not S.DesyncInvis then return end
        pcall(function()
            local m=hrp()
            if m and desyncAnchor then
                m.AssemblyLinearVelocity=Vector3.zero
                m.AssemblyAngularVelocity=Vector3.zero
                m.CFrame=CFrame.new(desyncAnchor.Position-Vector3.new(0,S.DesyncDepth,0))
            end
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GUI — Fluent library
-- ══════════════════════════════════════════════════════════════════════════════
local Fluent           = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title       = "Titan Hub",
    SubTitle    = "Age of Titans  •  v4.16",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(600, 480),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "sword"         }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "person-running" }),
    Visual   = Window:AddTab({ Title = "Visual",   Icon = "eye"           }),
    Utility  = Window:AddTab({ Title = "Utility",  Icon = "wrench"        }),
    Warp     = Window:AddTab({ Title = "Warp",     Icon = "map-pin"       }),
    Config   = Window:AddTab({ Title = "Config",   Icon = "settings"      }),
}

-- ── Combat tab ────────────────────────────────────────────────────────────────
do
    local t = Tabs.Combat

    t:AddParagraph({ Title = "Kill Aura", Content = "Attacks nearby targets from your position — no teleport" })
    t:AddToggle("KillAura", { Title = "Kill Aura", Default = false,
        Callback = function(v) S.KillAura = v end })
    t:AddSlider("KillAuraRange", { Title = "Aura Range", Default = 40, Min = 10, Max = 10000, Rounding = 0,
        Callback = function(v) S.KillAuraRange = v end })

    t:AddParagraph({ Title = "Hitbox", Content = "" })
    t:AddToggle("SilentAim", { Title = "Silent Aim", Default = false,
        Callback = function(v) S.SilentAim = v end })
    t:AddToggle("ExtendHitbox", { Title = "Extend Hitbox", Default = false,
        Callback = function(v) S.ExtendHitbox = v end })
    t:AddSlider("HitboxSize", { Title = "Hitbox Size", Default = 30, Min = 1, Max = 500, Rounding = 0,
        Callback = function(v) S.HitboxSize = v end })
    t:AddToggle("ShowHitbox", { Title = "Show Hitbox", Default = false,
        Callback = function(v)
            S.ShowHitbox = v
            if not v then
                for _,b in pairs(showHitboxBoxes) do pcall(function() b:Destroy() end) end
                showHitboxBoxes = {}
            end
        end })
    t:AddToggle("M1Expand", { Title = "M1 Expand", Default = false,
        Callback = function(v) S.M1Expand = v end })
    t:AddSlider("M1Size", { Title = "M1 Expand Size", Default = 8, Min = 1, Max = 10000, Rounding = 0,
        Callback = function(v) S.M1Size = v end })
    t:AddToggle("ShowExpand", { Title = "Show Expand Visual", Default = false,
        Callback = function(v) S.ShowExpand = v; if not v then destroyExpandVisual() end end })

    t:AddParagraph({ Title = "Auto", Content = "" })
    t:AddToggle("AutoUlt", { Title = "Auto Ultimate", Default = false,
        Callback = function(v) S.AutoUlt = v end })
    t:AddToggle("AutoPlay", { Title = "Auto Play", Default = false,
        Callback = function(v) S.AutoPlay = v end })
    t:AddSlider("AutoPlayRange", { Title = "Auto Play Range", Default = 100, Min = 20, Max = 300, Rounding = 0,
        Callback = function(v) S.AutoPlayRange = v end })
    t:AddToggle("AutoFarm", { Title = "Auto Farm", Default = false,
        Callback = function(v) S.AutoFarm = v end })
    t:AddSlider("AutoFarmRange", { Title = "Auto Farm Range", Default = 80, Min = 20, Max = 300, Rounding = 0,
        Callback = function(v) S.AutoFarmRange = v end })
end

-- ── Movement tab ──────────────────────────────────────────────────────────────
do
    local t = Tabs.Movement

    t:AddParagraph({ Title = "Movement", Content = "" })
    t:AddToggle("Noclip", { Title = "Noclip", Default = false,
        Callback = function(v) S.Noclip = v end })
    t:AddToggle("SpeedHack", { Title = "Speed Hack", Default = false,
        Callback = function(v) S.SpeedHack = v end })
    t:AddSlider("WalkSpeed", { Title = "Walk Speed", Default = 50, Min = 16, Max = 250, Rounding = 0,
        Callback = function(v) S.WalkSpeed = v end })
    t:AddToggle("AutoSprint", { Title = "Auto Sprint", Default = false,
        Callback = function(v) S.AutoSprint = v end })
    t:AddToggle("InfJump", { Title = "Infinite Jump", Default = false,
        Callback = function(v) S.InfJump = v end })

    t:AddParagraph({ Title = "Survival", Content = "" })
    t:AddToggle("GodMode", { Title = "God Mode", Default = false,
        Callback = function(v) S.GodMode = v; if v then enableGodMode() else disableGodMode() end end })
    t:AddToggle("NoStun", { Title = "No Stun", Default = false,
        Callback = function(v) S.NoStun = v end })
    t:AddToggle("SaveSystem", { Title = "Save System", Default = false,
        Callback = function(v) S.SaveSystem = v end })
    t:AddSlider("SaveThreshold", { Title = "HP Threshold %", Default = 30, Min = 1, Max = 99, Rounding = 0,
        Callback = function(v) S.SaveThreshold = v end })
    t:AddToggle("InstantRespawn", { Title = "Instant Respawn", Default = false,
        Callback = function(v) S.InstantRespawn = v end })
    t:AddToggle("Invisible", { Title = "Invisible", Default = false,
        Callback = function(v) S.Invisible = v; doInvisible(v) end })
    t:AddToggle("DesyncInvis", { Title = "Desync Invisible (void-clone)", Default = false,
        Callback = function(v) S.DesyncInvis = v; if v then startDesync() else stopDesync() end end })
    t:AddSlider("DesyncDepth", { Title = "Desync Void Depth", Default = 2000, Min = 300, Max = 50000, Rounding = 0,
        Callback = function(v) S.DesyncDepth = v end })
    t:AddToggle("AntiFling", { Title = "Anti-Fling", Default = false,
        Callback = function(v) S.AntiFling = v end })
end

-- ── Visual tab ────────────────────────────────────────────────────────────────
do
    local t = Tabs.Visual

    t:AddToggle("ESP", { Title = "Player ESP", Default = false,
        Callback = function(v) S.ESP = v end })
    t:AddToggle("InfZoom", { Title = "Infinite Zoom", Default = false,
        Callback = function(v)
            S.InfZoom = v
            if v then origZoom=player.CameraMaxZoomDistance; player.CameraMaxZoomDistance=9999
            else if origZoom then player.CameraMaxZoomDistance=origZoom end end
        end })
    t:AddToggle("Fullbright", { Title = "Fullbright", Default = false,
        Callback = function(v) S.Fullbright = v; if v then applyFullbright() end end })
end

-- ── Utility tab ───────────────────────────────────────────────────────────────
do
    local t = Tabs.Utility

    t:AddParagraph({ Title = "Player", Content = "" })
    t:AddToggle("AntiAFK", { Title = "Anti-AFK", Default = false,
        Callback = function(v) S.AntiAFK = v end })
    t:AddToggle("ClickTP", { Title = "Click Teleport  [T]", Default = false,
        Callback = function(v) S.ClickTP = v end })
    t:AddToggle("Spinbot", { Title = "Spinbot", Default = false,
        Callback = function(v) S.Spinbot = v end })
    t:AddToggle("HideNames", { Title = "Hide Names", Default = false,
        Callback = function(v) S.HideNames = v end })

    t:AddParagraph({ Title = "Server", Content = "" })
    t:AddButton({ Title = "FPS Boost",       Callback = fpsBoost       })
    t:AddButton({ Title = "Reset Character", Callback = resetCharacter  })
    t:AddButton({ Title = "Rejoin Server",   Callback = rejoinServer    })
    t:AddButton({ Title = "Server Hop",      Callback = serverHop       })
    t:AddButton({ Title = "Disconnect All",  Callback = function()
        for _,c in pairs(Connections) do pcall(function() c:Disconnect() end) end
        destroyExpandVisual(); stopDesync(); disableGodMode()
        Connections={}; S.Noclip=false; S.DesyncInvis=false; S.GodMode=false
    end })
end

-- ── Warp tab ──────────────────────────────────────────────────────────────────
do
    local t = Tabs.Warp
    t:AddParagraph({ Title = "Teleport to Player", Content = "Players online when script loaded" })
    for _,p2 in pairs(Players:GetPlayers()) do
        if p2 ~= player then
            local pname = p2.Name
            t:AddButton({ Title = pname, Callback = function()
                pcall(function()
                    local c=chr(); if not c then return end
                    local pc=Players:FindFirstChild(pname)
                    local ph=pc and pc.Character and (pc.Character:FindFirstChild("HumanoidRootPart") or pc.Character.PrimaryPart)
                    if ph then c:PivotTo(ph.CFrame+Vector3.new(3,0,0)) end
                end)
            end })
        end
    end
end

-- ── Config tab ────────────────────────────────────────────────────────────────
do
    local t = Tabs.Config
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("TitanHub")
    SaveManager:SetFolder("TitanHub/profiles")
    InterfaceManager:BuildInterfaceSection(t)
    SaveManager:BuildConfigSection(t)
end

-- ── Input ─────────────────────────────────────────────────────────────────────
local ATTACK_KEYS = {
    [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,
    [Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5,
}

table.insert(Connections, UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType==Enum.UserInputType.Keyboard then
        local n=ATTACK_KEYS[i.KeyCode]
        if n then
            if S.ExtendHitbox then spamHitbox("Attack"..n.."Hitbox",S.HitboxSize,6,0.05) end
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
    if S.ExtendHitbox then for n=1,5 do spamHitbox("Attack"..n.."Hitbox",S.HitboxSize,10,0.02) end end
    if S.M1Expand then
        local hitSz=math.max(S.M1Size,50)
        -- Instant triple burst on click
        local r=re()
        if r then
            for _burst=1,3 do
                for n=1,5 do
                    pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
                    pcall(function() r:FireServer("Attack"..n.."Hitbox", hitSz) end)
                end
                for n=1,3 do pcall(function() r:FireServer("Lc"..n.."Hitbox", hitSz) end) end
            end
        end
        -- Rapid follow-up bursts across the full swing window (~300ms)
        task.spawn(function()
            for _=1,5 do
                if not S.M1Expand then break end
                local r2=re()
                if r2 then
                    for n=1,5 do
                        pcall(function() r2:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
                        pcall(function() r2:FireServer("Attack"..n.."Hitbox", hitSz) end)
                    end
                    for n=1,3 do pcall(function() r2:FireServer("Lc"..n.."Hitbox", hitSz) end) end
                end
                task.wait(0.04)
            end
        end)
        for n=1,5 do spamHitbox("Attack"..n.."Hitbox",hitSz,8,0.02) end
        for n=1,3 do spamHitbox("Lc"..n.."Hitbox",hitSz,8,0.02) end
    end
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

-- Re-apply God Mode / Invisible after a respawn (new character = new HP sources & parts)
table.insert(Connections, player.CharacterAdded:Connect(function()
    task.wait(0.4)
    if S.GodMode    then pcall(enableGodMode) end
    if S.Invisible  then pcall(function() doInvisible(true) end) end
    if S.DesyncInvis then pcall(startDesync) end
end))

pcall(function()
    player.Idled:Connect(function()
        if not S.AntiAFK then return end
        local vu=game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end)
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- MAIN LOOP
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

    -- God Mode: per-frame brute force; hooks handle instant reversion; rebuild hooks every 1s
    if S.GodMode then
        pcall(function()
            local h=hum()
            if h then
                if h.MaxHealth>0 and h.Health<h.MaxHealth then h.Health=h.MaxHealth end
                -- If the Humanoid ended up Dead (server killed us), kick it back moveable locally
                -- then fire an instant-respawn so the fresh character gets God Mode re-applied
                pcall(function()
                    if h:GetState()==Enum.HumanoidStateType.Dead then
                        h:ChangeState(Enum.HumanoidStateType.GettingUp)
                        task.delay(0.15, function()
                            if S.GodMode then
                                pcall(function()
                                    local d=diedRemote()
                                    if d then d:FireServer("Real",3.8333332538604736) end
                                end)
                            end
                        end)
                    end
                end)
            end
            local c=chr()
            if c then
                for attr,v in pairs(c:GetAttributes()) do
                    if type(v)=="number" and isHpName(attr) and not tostring(attr):lower():find("max") then
                        local key="attr:"..tostring(c)..":"..attr
                        local m=recMax(key,v)
                        if m and v<m then c:SetAttribute(attr,m) end
                    end
                end
            end
        end)
        godRebuildClock=godRebuildClock+dt
        if godRebuildClock>=1 then godRebuildClock=0; enableGodMode() end
    end

    -- Invisible: re-apply periodically so the game can't reset it visually (local-only)
    if S.Invisible then
        invisClock=invisClock+dt
        if invisClock>=0.25 then invisClock=0; doInvisible(true) end
    end

    -- No Stun
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
                    h.PlatformStand=false; h.Sit=false
                    if h.WalkSpeed<=0.5 then h.WalkSpeed=(S.SpeedHack and S.WalkSpeed) or 16 end
                    if h.JumpPower~=nil and h.JumpPower<=0.5 then h.JumpPower=50 end
                end
            end)
        end
    end

    -- Invisible
    if S.Invisible~=invisStateLast then invisStateLast=S.Invisible; doInvisible(S.Invisible) end

    -- Noclip
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

    -- Auto Ult (standalone: presses V whenever ult bar fills, regardless of other features)
    if S.AutoUlt then
        ultClock=ultClock+dt
        if ultClock>=0.15 then
            ultClock=0
            local full=false; pcall(function() full=ultIsFull() end)
            if full and not ultWasFull then
                ultWasFull=true
                task.spawn(function()
                    pcall(function()
                        local vim=game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true,Enum.KeyCode.V,false,game); task.wait(0.08)
                        vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                        task.wait(0.1)
                        -- Re-fire in case the first press was eaten
                        if S.AutoUlt then
                            vim:SendKeyEvent(true,Enum.KeyCode.V,false,game); task.wait(0.08)
                            vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                        end
                    end)
                end)
                -- Also fire the ult remote directly if it exists
                task.spawn(function()
                    pcall(function()
                        local r=re()
                        if r then
                            for _,name in ipairs({"Ult","Ultimate","Special","Ult1"}) do
                                pcall(function() r:FireServer(name) end)
                            end
                        end
                    end)
                end)
            elseif not full then ultWasFull=false end
        end
    else ultClock=0; ultWasFull=false end

    -- Kill Aura: fires every ~30ms, triple burst per target, heavy background spam
    if S.KillAura then
        kauraClk=kauraClk+dt
        if kauraClk>=0.03 then
            kauraClk=0
            pcall(function()
                local mh=hrp(); if not mh then return end
                local r=re(); if not r then return end
                local range=S.KillAuraRange
                local hitSz=math.max(S.M1Size,S.HitboxSize,range*0.5,50)
                ensureExpandVisual()
                local targets={}
                for _,p2 in pairs(Players:GetPlayers()) do
                    if p2~=player and p2.Character then
                        local ph=p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                        local h2=p2.Character:FindFirstChildOfClass("Humanoid")
                        if ph and h2 and h2.Health>0 and (ph.Position-mh.Position).Magnitude<=range then
                            targets[#targets+1]=ph
                        end
                    end
                end
                for _,obj in pairs(workspace:GetChildren()) do
                    if obj~=player.Character and obj:IsA("Model") then
                        local h2=obj:FindFirstChildOfClass("Humanoid")
                        local root=obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                        if h2 and root and h2.Health>0 and (root.Position-mh.Position).Magnitude<=range then
                            targets[#targets+1]=root
                        end
                    end
                end
                if #targets==0 then return end
                -- Triple burst per target this tick
                for _=1,#targets do
                    for _burst=1,3 do
                        for n=1,5 do
                            pcall(function() r:FireServer("Attack"..n, ATTACK_VALS[n] or 4.4666666984558105) end)
                            pcall(function() r:FireServer("Attack"..n.."Hitbox", hitSz) end)
                        end
                        for n=1,3 do
                            pcall(function() r:FireServer("Lc"..n.."Hitbox", hitSz) end)
                        end
                    end
                end
                -- Heavy background spam for the next ~300ms
                for n=1,5 do spamHitbox("Attack"..n.."Hitbox",hitSz,8,0.02) end
                for n=1,3 do spamHitbox("Lc"..n.."Hitbox",hitSz,8,0.02) end
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
                local c=chr(); if c then c:PivotTo(ph.CFrame+ph.CFrame.LookVector*-3) end
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
                            vim:SendKeyEvent(true,Enum.KeyCode.V,false,game); task.wait(0.05)
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
                        if c then c:PivotTo(c:GetPivot()+dir*step) end
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
                                vim:SendKeyEvent(true,Enum.KeyCode.V,false,game); task.wait(0.05)
                                vim:SendKeyEvent(false,Enum.KeyCode.V,false,game)
                            end)
                        end)
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
    if S.Fullbright then fbClock=fbClock+dt; if fbClock>=1 then fbClock=0; applyFullbright() end end

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
                pcall(function() local d=diedRemote(); if d then d:FireServer("Real",3.8333332538604736) end end)
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
                    saveActive=false; saveClock=0; mh.CFrame=CFrame.new(savePos+Vector3.new(0,8,0))
                end
            elseif (h.Health/h.MaxHealth*100)<=S.SaveThreshold then
                savePos=mh.Position; saveActive=true; saveClock=0
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
                        box.Adornee=root; box.Color3=Color3.fromRGB(64,110,200)
                        box.LineThickness=0.05; box.SurfaceTransparency=0.7
                        box.SurfaceColor3=Color3.fromRGB(64,110,200); box.Parent=workspace
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
                if not Players:FindFirstChild(name) then pcall(function() data.bill:Destroy() end); espBoxes[name]=nil end
            end
            for _,p2 in pairs(Players:GetPlayers()) do
                if p2~=player and p2.Character then
                    local root=p2.Character:FindFirstChild("HumanoidRootPart") or p2.Character.PrimaryPart
                    if root and not espBoxes[p2.Name] then
                        local bill=Instance.new("BillboardGui")
                        bill.Size=UDim2.new(0,80,0,28); bill.AlwaysOnTop=true
                        bill.StudsOffset=Vector3.new(0,3,0); bill.Adornee=root; bill.Parent=workspace
                        local lbl=Instance.new("TextLabel"); lbl.Parent=bill
                        lbl.Text=p2.Name; lbl.TextSize=13; lbl.Font=Enum.Font.GothamMedium
                        lbl.TextColor3=Color3.fromRGB(64,110,200); lbl.BackgroundTransparency=1
                        lbl.Size=UDim2.new(1,0,1,0)
                        lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.new(0,0,0)
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

-- ── Init ──────────────────────────────────────────────────────────────────────
Window:SelectTab(1)
print("[Titan Hub] v4.16 loaded | Toggle: RightShift")
