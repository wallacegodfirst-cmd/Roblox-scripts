-- Joob Hub - safari/animal game (Rayfield)
-- Core hooks (from user): Harpoon Spear ToolEvent remote (damage/points),
-- LakeCrocodiles "crocodile water" TouchInterest (anti-croc).
-- Best-effort flags: God Mode, FE Invisibility, send-back bypass (can't test live).

local Rayfield   = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

local S = {
    SpeedOn=false, Speed=50, Fly=false, FlySpeed=60, Noclip=false,
    AutoPoints=false, AutoFarm=false, KillAura=false, KillAuraRange=200,
    HitboxPlayers=false, HitboxNPC=false, HitboxVisible=true, HitboxSize=12,
    ESPPlayers=false, ESPElephant=false, ESPHippo=false, ESPLion=false, ESPCroc=false,
    AntiCroc=false, GodMode=false, TPTarget=nil,
}

local function getChar() return LP.Character end
local function getHum()  local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c=LP.Character; return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end
local function vec3(x,y,z)
    if vector and typeof(vector.create)=="function" then return vector.create(x,y,z) end
    return Vector3.new(x,y,z)
end

-- ── NPC detection ─────────────────────────────────────────────────────────
local ANIMAL_WORDS = {"elephant","giantelephant","giraffe","hippo","rhino","lion"}
local function isPlayerChar(m) return Players:GetPlayerFromCharacter(m) ~= nil end
local function aimPart(m)
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
end
local function npcAlive(m)
    if not m or not m.Parent then return false end
    local h = m:FindFirstChildOfClass("Humanoid"); if h then return h.Health > 0 end
    return true
end
local function npcModels(words)
    local out = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and not isPlayerChar(d) and aimPart(d) then
            local n = string.lower(d.Name)
            for _, w in ipairs(words) do
                if n:find(w, 1, true) then out[#out+1] = d; break end
            end
        end
    end
    return out
end
local function allAnimals() return npcModels(ANIMAL_WORDS) end
local function nearestAnimal()
    local root = getRoot(); if not root then return nil end
    local best, dist
    for _, m in ipairs(allAnimals()) do
        if npcAlive(m) then
            local p = aimPart(m)
            if p then local d=(p.Position-root.Position).Magnitude; if not dist or d<dist then best,dist=m,d end end
        end
    end
    return best
end
local function animalNames()
    local seen, out = {}, {}
    for _, m in ipairs(allAnimals()) do if not seen[m.Name] then seen[m.Name]=true; out[#out+1]=m.Name end end
    table.sort(out); return out
end

-- ── Harpoon (damage / points) ─────────────────────────────────────────────
local function harpoonAt(pos)
    local c = LP.Character; if not c then return end
    local tool = c:FindFirstChild("Harpoon Spear"); if not tool then return end
    local ev = tool:FindFirstChild("ToolEvent"); if not ev then return end
    local origin = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
    if not origin then return end
    local d = pos - origin.Position
    if d.Magnitude > 0 then d = d.Unit end
    pcall(function() ev:FireServer("InputStart") end)
    task.wait(0.03)
    pcall(function() ev:FireServer("InputEnd", vec3(d.X, d.Y, d.Z)) end)
end

-- ── SPEED / NOCLIP ────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if S.SpeedOn then local h=getHum(); if h then pcall(function() h.WalkSpeed=S.Speed end) end end
    if S.GodMode then
        local h=getHum()
        if h then pcall(function() h.MaxHealth=math.huge; h.Health=h.MaxHealth; h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end) end
    end
end)
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local c=getChar(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then pcall(function() p.CanCollide=false end) end
    end
end)

-- ── FLY ───────────────────────────────────────────────────────────────────
local keys={W=false,A=false,S=false,D=false,Up=false,Down=false}
UIS.InputBegan:Connect(function(i,gpe) if gpe then return end local k=i.KeyCode
    if k==Enum.KeyCode.W then keys.W=true elseif k==Enum.KeyCode.A then keys.A=true
    elseif k==Enum.KeyCode.S then keys.S=true elseif k==Enum.KeyCode.D then keys.D=true
    elseif k==Enum.KeyCode.Space then keys.Up=true elseif k==Enum.KeyCode.LeftControl then keys.Down=true end end)
UIS.InputEnded:Connect(function(i) local k=i.KeyCode
    if k==Enum.KeyCode.W then keys.W=false elseif k==Enum.KeyCode.A then keys.A=false
    elseif k==Enum.KeyCode.S then keys.S=false elseif k==Enum.KeyCode.D then keys.D=false
    elseif k==Enum.KeyCode.Space then keys.Up=false elseif k==Enum.KeyCode.LeftControl then keys.Down=false end end)
RunService.RenderStepped:Connect(function(dt)
    if not S.Fly then return end
    local root=getRoot(); local cam=workspace.CurrentCamera; if not(root and cam) then return end
    local h=getHum(); if h then pcall(function() h.PlatformStand=true end) end
    local dir=Vector3.zero
    if keys.W then dir+=cam.CFrame.LookVector end
    if keys.S then dir-=cam.CFrame.LookVector end
    if keys.A then dir-=cam.CFrame.RightVector end
    if keys.D then dir+=cam.CFrame.RightVector end
    if keys.Up then dir+=Vector3.yAxis end
    if keys.Down then dir-=Vector3.yAxis end
    pcall(function() root.AssemblyLinearVelocity=Vector3.zero; if dir.Magnitude>0 then root.CFrame=root.CFrame+dir.Unit*S.FlySpeed*dt end end)
end)
task.spawn(function() local was=false; while task.wait(0.1) do
    if S.Fly then was=true elseif was then was=false; local h=getHum(); if h then pcall(function() h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end
end end)

-- ── TELEPORT (send-back bypass: hold the position for a window) ────────────
local function holdCFrame(cf, dur)
    task.spawn(function()
        local t=0
        local c
        c = RunService.RenderStepped:Connect(function(dt)
            local root=getRoot()
            if root then pcall(function() root.AssemblyLinearVelocity=Vector3.zero; root.CFrame=cf end) end
            t+=dt; if t>=dur then c:Disconnect() end
        end)
    end)
end
local function tpToAnimalName(name)
    local root=getRoot(); if not (root and name) then return end
    for _, m in ipairs(allAnimals()) do
        if m.Name==name then local p=aimPart(m); if p then holdCFrame(p.CFrame*CFrame.new(0,0,6), 0.6); return end end
    end
end

-- ── HITBOX EXPANDER (players + NPC, visible, size) ────────────────────────
local hbOrig = setmetatable({}, {__mode="k"})
local function restoreHitboxes()
    for part,o in pairs(hbOrig) do if part and part.Parent then pcall(function()
        part.Size=o.s; part.Transparency=o.t; part.CanCollide=o.c; part.Color=o.col; part.Material=o.m
    end) end end
    hbOrig={}
end
local function expandPart(part, sz)
    if not hbOrig[part] then hbOrig[part]={s=part.Size,t=part.Transparency,c=part.CanCollide,col=part.Color,m=part.Material} end
    pcall(function()
        part.Size=Vector3.new(sz,sz,sz); part.CanCollide=false; part.Massless=true; part.CanQuery=true; part.CanTouch=true
        part.Transparency = S.HitboxVisible and 0.6 or 1
        if S.HitboxVisible then part.Color=Color3.fromRGB(255,60,60); part.Material=Enum.Material.ForceField end
    end)
end
RunService.Heartbeat:Connect(function()
    if not (S.HitboxPlayers or S.HitboxNPC) then if next(hbOrig) then restoreHitboxes() end return end
    for part in pairs(hbOrig) do if not part.Parent then hbOrig[part]=nil end end
    if S.HitboxPlayers then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then local r=p.Character:FindFirstChild("HumanoidRootPart"); if r then expandPart(r,S.HitboxSize) end end
        end
    end
    if S.HitboxNPC then
        for _,m in ipairs(allAnimals()) do if npcAlive(m) then local r=aimPart(m); if r then expandPart(r,S.HitboxSize) end end end
    end
end)

-- ── ESP ───────────────────────────────────────────────────────────────────
local espPool = {}  -- instance -> {hl, bill}
local function clearESP()
    for _,d in pairs(espPool) do pcall(function() d.hl:Destroy() end); if d.bill then pcall(function() d.bill:Destroy() end) end end
    espPool={}
end
local function espTargets()
    local list = {}  -- {inst, adornee, color, label}
    if S.ESPPlayers then for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then list[#list+1]={p.Character,p.Character,Color3.fromRGB(0,170,255),p.Name} end end end
    local function add(words, col)
        for _,m in ipairs(npcModels(words)) do list[#list+1]={m,m,col,m.Name} end
    end
    if S.ESPElephant then add({"elephant"}, Color3.fromRGB(180,180,180)) end
    if S.ESPHippo    then add({"hippo"},    Color3.fromRGB(170,120,200)) end
    if S.ESPLion     then add({"lion"},     Color3.fromRGB(255,180,40))  end
    if S.ESPCroc then
        local lake = workspace:FindFirstChild("LakeCrocodiles")
        if lake then for _,d in ipairs(lake:GetChildren()) do if d:IsA("BasePart") then list[#list+1]={d,nil,Color3.fromRGB(60,220,90),"Crocodile"} end end end
    end
    return list
end
task.spawn(function()
    while task.wait(0.5) do
        local anyESP = S.ESPPlayers or S.ESPElephant or S.ESPHippo or S.ESPLion or S.ESPCroc
        if not anyESP then if next(espPool) then clearESP() end
        else
            local want = {}
            for _, t in ipairs(espTargets()) do
                local inst = t[1]; want[inst]=true
                if not espPool[inst] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor=t[3]; hl.FillTransparency=0.5; hl.OutlineColor=Color3.new(1,1,1)
                    pcall(function() hl.Adornee=t[2] or inst; hl.Parent=t[2] or inst end)
                    espPool[inst]={hl=hl}
                end
            end
            for inst,d in pairs(espPool) do
                if not want[inst] or not inst.Parent then pcall(function() d.hl:Destroy() end); espPool[inst]=nil end
            end
        end
    end
end)

-- ── ANTI CROCODILE ────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if S.AntiCroc then
            local lake = workspace:FindFirstChild("LakeCrocodiles")
            if lake then for _,d in ipairs(lake:GetDescendants()) do
                if d:IsA("BasePart") then pcall(function() d.CanTouch=false end) end
                if d.ClassName=="TouchInterest" or d:IsA("TouchTransmitter") then pcall(function() d:Destroy() end) end
            end end
        end
    end
end)

-- ── AUTO POINTS / AUTO FARM / KILL AURA (harpoon) ─────────────────────────
task.spawn(function()
    while task.wait(0.12) do
        pcall(function()
            if S.AutoPoints then
                local m = nearestAnimal(); local p = m and aimPart(m)
                if p then harpoonAt(p.Position) end
            end
            if S.KillAura then
                local root=getRoot()
                if root then for _,m in ipairs(allAnimals()) do
                    if npcAlive(m) then local p=aimPart(m); if p and (p.Position-root.Position).Magnitude<=S.KillAuraRange then harpoonAt(p.Position) end end
                end end
            end
            if S.AutoFarm then
                for _,m in ipairs(allAnimals()) do if npcAlive(m) then local p=aimPart(m); if p then harpoonAt(p.Position) end end end
            end
        end)
    end
end)

-- ── INVISIBILITY (FE, experimental) ───────────────────────────────────────
local function feInvisible()
    pcall(function()
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); local saved = root and root.CFrame
        char.Archivable = true
        local clone = char:Clone()
        char.Archivable = false
        clone.Parent = workspace
        LP.Character = clone
        workspace.CurrentCamera.CameraSubject = clone:FindFirstChildOfClass("Humanoid")
        if saved then local cr=clone:FindFirstChild("HumanoidRootPart"); if cr then cr.CFrame=saved end end
        task.wait(0.1)
        char:Destroy()
        Rayfield:Notify({Title="Joob Hub", Content="FE Invisible applied (experimental).", Duration=4})
    end)
end

-- ══════════════════════════ GUI ══════════════════════════
local Win = Rayfield:CreateWindow({
    Name = "Joob Hub",
    LoadingTitle = "Joob Hub",
    LoadingSubtitle = "safari",
    ConfigurationSaving = { Enabled = false },
})

local MoveTab = Win:CreateTab("Movement", 4483362458)
MoveTab:CreateToggle({Name="Speed", CurrentValue=false, Flag="SpeedOn", Callback=function(v) S.SpeedOn=v; if not v then local h=getHum(); if h then pcall(function() h.WalkSpeed=16 end) end end end})
MoveTab:CreateSlider({Name="Walk Speed", Range={16,200}, Increment=1, Suffix="spd", CurrentValue=50, Flag="Speed", Callback=function(v) S.Speed=v end})
MoveTab:CreateToggle({Name="Fly (WASD + Space/Ctrl)", CurrentValue=false, Flag="Fly", Callback=function(v) S.Fly=v end})
MoveTab:CreateSlider({Name="Fly Speed", Range={10,250}, Increment=5, Suffix="spd", CurrentValue=60, Flag="FlySpeed", Callback=function(v) S.FlySpeed=v end})
MoveTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v) S.Noclip=v; if not v then local c=getChar(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then pcall(function() p.CanCollide=true end) end end end end end})
MoveTab:CreateSection("Teleport (anti send-back)")
local tpDrop = MoveTab:CreateDropdown({Name="NPC", Options=animalNames(), CurrentOption={}, Flag="TPTarget", Callback=function(o) S.TPTarget=(type(o)=="table" and o[1]) or o end})
MoveTab:CreateButton({Name="Teleport to NPC", Callback=function() tpToAnimalName(S.TPTarget) end})
MoveTab:CreateButton({Name="Refresh NPC List", Callback=function() pcall(function() tpDrop:Refresh(animalNames()) end) end})

local FarmTab = Win:CreateTab("Farm", 4483362458)
FarmTab:CreateToggle({Name="Auto Points (harpoon nearest)", CurrentValue=false, Flag="AutoPoints", Callback=function(v) S.AutoPoints=v end})
FarmTab:CreateToggle({Name="Auto Farm NPC (kill all)", CurrentValue=false, Flag="AutoFarm", Callback=function(v) S.AutoFarm=v end})
FarmTab:CreateToggle({Name="Kill Aura NPC", CurrentValue=false, Flag="KillAura", Callback=function(v) S.KillAura=v end})
FarmTab:CreateSlider({Name="Kill Aura Range", Range={20,500}, Increment=10, Suffix="studs", CurrentValue=200, Flag="KillAuraRange", Callback=function(v) S.KillAuraRange=v end})
FarmTab:CreateSection("Hitbox Expander")
FarmTab:CreateToggle({Name="Hitbox: Players", CurrentValue=false, Flag="HitboxPlayers", Callback=function(v) S.HitboxPlayers=v; if not v and not S.HitboxNPC then restoreHitboxes() end end})
FarmTab:CreateToggle({Name="Hitbox: NPCs", CurrentValue=false, Flag="HitboxNPC", Callback=function(v) S.HitboxNPC=v; if not v and not S.HitboxPlayers then restoreHitboxes() end end})
FarmTab:CreateToggle({Name="Hitbox: Visible", CurrentValue=true, Flag="HitboxVisible", Callback=function(v) S.HitboxVisible=v end})
FarmTab:CreateSlider({Name="Hitbox Size", Range={2,80}, Increment=1, Suffix="studs", CurrentValue=12, Flag="HitboxSize", Callback=function(v) S.HitboxSize=v end})

local ESPTab = Win:CreateTab("ESP", 4483362458)
ESPTab:CreateToggle({Name="ESP Players", CurrentValue=false, Flag="ESPPlayers", Callback=function(v) S.ESPPlayers=v end})
ESPTab:CreateToggle({Name="ESP Elephants", CurrentValue=false, Flag="ESPElephant", Callback=function(v) S.ESPElephant=v end})
ESPTab:CreateToggle({Name="ESP Hippos", CurrentValue=false, Flag="ESPHippo", Callback=function(v) S.ESPHippo=v end})
ESPTab:CreateToggle({Name="ESP Lions", CurrentValue=false, Flag="ESPLion", Callback=function(v) S.ESPLion=v end})
ESPTab:CreateToggle({Name="ESP Crocodiles", CurrentValue=false, Flag="ESPCroc", Callback=function(v) S.ESPCroc=v end})

local PlayerTab = Win:CreateTab("Player", 4483362458)
PlayerTab:CreateToggle({Name="Anti Crocodile (no grab)", CurrentValue=false, Flag="AntiCroc", Callback=function(v) S.AntiCroc=v end})
PlayerTab:CreateToggle({Name="God Mode (best-effort)", CurrentValue=false, Flag="GodMode", Callback=function(v) S.GodMode=v end})
PlayerTab:CreateButton({Name="Invisibility (FE, experimental)", Callback=feInvisible})
PlayerTab:CreateSection("Debug")
PlayerTab:CreateButton({Name="Dump NPCs + Harpoon path", Callback=function()
    print("===== JOOB HUB DUMP =====")
    local c=LP.Character
    print("Harpoon Spear:", c and c:FindFirstChild("Harpoon Spear"), "ToolEvent:", c and c:FindFirstChild("Harpoon Spear") and c["Harpoon Spear"]:FindFirstChild("ToolEvent"))
    local seen={}
    for _,d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and not isPlayerChar(d) and aimPart(d) and not seen[d.Name] then
            seen[d.Name]=true; print("Model:", d.Name)
        end
    end
    Rayfield:Notify({Title="Joob Hub", Content="Dumped to console (F9).", Duration=4})
end})

Rayfield:Notify({Title="Joob Hub", Content="Loaded. Harpoon farm + ESP + movement ready.", Duration=5})
