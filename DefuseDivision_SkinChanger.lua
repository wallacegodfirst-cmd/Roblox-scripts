-- Defuse Division Skin Changer - FIXED
-- Fixes:
--  * Storage resolved by NAME (finds the child holding Import.Assets.Skins)
--    instead of the brittle game:GetChildren()[118].
--  * Skin appearance is found generically (ANY SurfaceAppearance / texture in the
--    skin folder), so gloves & knives whose skin isn't literally named "Texture"
--    now apply.
--  * Weapon template matching is lenient (exact, then partial) so Skins-folder
--    names that differ from Weapons-folder names (Knife vs Knives, etc.) still hit.
--  * Nil guards everywhere (no more crashes on Load config / missing folders).
--  * Live override re-skins the Viewmodel AND your character (held knife / gloves).

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LP          = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Defuse Division Skin Changer",
    LoadingTitle = "I just Doxxed you 💀🤡",
    LoadingSubtitle = "by Bro",
    ConfigurationSaving = { Enabled = false }
})

-- ── resolve storage robustly (was game:GetChildren()[118]) ───────────────────
local Storage, SkinsFolder, WeaponsFolder
do
    local function tryResolve()
        for _, c in ipairs(game:GetChildren()) do
            local imp = c:FindFirstChild("Import")
            local assets = imp and imp:FindFirstChild("Assets")
            if assets and assets:FindFirstChild("Skins") then return c end
        end
        return game:GetChildren()[118]  -- last-resort fallback (original behaviour)
    end
    for _ = 1, 40 do            -- wait a bit in case Import streams in late
        Storage = tryResolve()
        if Storage and Storage:FindFirstChild("Import") then break end
        task.wait(0.25)
    end
    local ok = pcall(function()
        SkinsFolder   = Storage.Import.Assets.Skins
        WeaponsFolder = Storage.Import.Assets.Weapons
    end)
    if not (ok and SkinsFolder and WeaponsFolder) then
        Rayfield:Notify({Title="Skin Changer", Content="Couldn't find Import.Assets.Skins/Weapons - wrong game or not loaded.", Duration=8})
        return
    end
end

_G.ActiveSkins = _G.ActiveSkins or {}
local DropdownElements = {}

-- ── helpers ──────────────────────────────────────────────────────────────────
local function GetSkinNames(weaponFolderName)
    local list = {"None"}
    local folder = SkinsFolder:FindFirstChild(weaponFolderName)
    if folder then
        for _, skin in ipairs(folder:GetChildren()) do
            table.insert(list, skin.Name)
        end
    end
    return list
end

-- exact match first, then lenient (names contain each other)
local function findWeaponTemplate(weaponName)
    local wn = string.lower(weaponName)
    for _, w in ipairs(WeaponsFolder:GetChildren()) do
        if string.lower(w.Name) == wn then return w end
    end
    for _, w in ipairs(WeaponsFolder:GetChildren()) do
        local n = string.lower(w.Name)
        if n:find(wn, 1, true) or wn:find(n, 1, true) then return w end
    end
    return nil
end

-- Map partName -> {sa=SurfaceAppearance, tex=textureID} from a skin folder, plus a
-- generic "*" entry for a single folder-level SurfaceAppearance / texture (guns).
-- Gloves & multi-part knives store ONE SurfaceAppearance PER MeshPart (e.g.
-- Wrap1_lowLeftMain, Wrap2_lowLeft), so we copy each part's look onto the
-- matching-named target part instead of cloning one look onto everything.
local function buildSkinMap(skinFolder)
    local map = {}
    if not skinFolder then return map end
    for _, d in ipairs(skinFolder:GetDescendants()) do
        if d:IsA("MeshPart") then
            local e = map[d.Name] or {}; map[d.Name] = e
            local sa = d:FindFirstChildOfClass("SurfaceAppearance")
            if sa then e.sa = sa end
            if d.TextureID ~= "" then e.tex = d.TextureID end
        elseif d:IsA("SurfaceAppearance") and d.Parent and not d.Parent:IsA("MeshPart") then
            local g = map["*"] or {}; map["*"] = g; g.sa = d           -- e.g. a "Texture" SA at folder root
        elseif d:IsA("StringValue") and tostring(d.Value):find("rbxassetid") then
            local g = map["*"] or {}; map["*"] = g; g.tex = d.Value     -- worldmodel / textureid fallback
        end
    end
    return map
end

local function applyEntry(part, e)
    if not e then return end
    if e.sa then
        for _, old in ipairs(part:GetChildren()) do
            if old:IsA("SurfaceAppearance") then old:Destroy() end
        end
        e.sa:Clone().Parent = part
    elseif e.tex then
        pcall(function() part.TextureID = e.tex end)
    end
end

-- copy each skin part's appearance onto the matching-named MeshPart under `root`,
-- falling back to the generic "*" entry for parts with no name match.
local function applySkinToRoot(root, skinFolder, allowGeneric)
    if not (root and skinFolder) then return end
    local map = buildSkinMap(skinFolder)
    if not next(map) then return end
    local function handle(part)
        local e = map[part.Name]
        if not e and allowGeneric then e = map["*"] end
        applyEntry(part, e)
    end
    if root:IsA("MeshPart") then handle(root) end
    for _, part in ipairs(root:GetDescendants()) do
        if part:IsA("MeshPart") then handle(part) end
    end
end

local function getSkinFolder(weaponName, skinName)
    local wf = SkinsFolder:FindFirstChild(weaponName)
    return wf and wf:FindFirstChild(skinName) or nil
end

-- first-person weapons live under Camera.Arms in this game (NOT Camera.Viewmodel)
local function viewmodelRoots()
    local cam = workspace.CurrentCamera
    local roots = {}
    if cam then
        for _, nm in ipairs({"Arms", "Viewmodel", "ViewModel"}) do
            local r = cam:FindFirstChild(nm); if r then roots[#roots+1] = r end
        end
        if #roots == 0 then
            for _, c in ipairs(cam:GetChildren()) do if c:IsA("Model") then roots[#roots+1] = c end end
        end
    end
    return roots
end

-- find the equipped weapon model/part under a root by lenient name match
local function findWeaponModel(root, weaponName)
    local wn = string.lower(weaponName)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("Model") or d:IsA("MeshPart") then
            local n = string.lower(d.Name)
            if n == wn or n:find(wn, 1, true) or wn:find(n, 1, true) then return d end
        end
    end
    return nil
end

-- ── KNIFE MODEL SWAP (change the knife MESH itself, e.g. -> Karambit) ──────────
-- A knife "skin" is a different mesh, not just a texture. MeshPart.MeshId can't be
-- set at runtime, so we overlay a CLONE of the skin's mesh onto the equipped knife
-- part (welded so it follows the swing) and hide the original.
local knifeSwaps = setmetatable({}, {__mode = "k"})  -- targetPart -> {skin, clone, origTrans}

local function clearKnifeSwap(target)
    local s = knifeSwaps[target]
    if s then
        if s.clone then pcall(function() s.clone:Destroy() end) end
        if target and target.Parent then pcall(function() target.Transparency = s.origTrans or 0 end) end
        knifeSwaps[target] = nil
    end
end
local function clearAllKnifeSwaps()
    for target in pairs(knifeSwaps) do clearKnifeSwap(target) end
end

local function sourceMesh(skinFolder)
    for _, d in ipairs(skinFolder:GetDescendants()) do
        if d:IsA("MeshPart") and d.MeshId ~= "" then return d end
    end
    return nil
end

local function applyKnifeModel(root, skinFolder, skinName, weaponName)
    local wm = findWeaponModel(root, weaponName)
    if not wm then return end
    local src = sourceMesh(skinFolder)
    if not src then return end
    local targets = {}
    if wm:IsA("MeshPart") then targets[1] = wm
    else for _, d in ipairs(wm:GetDescendants()) do
        if d:IsA("MeshPart") and string.lower(d.Name) ~= "handle" then targets[#targets+1] = d end
    end end
    for _, target in ipairs(targets) do
        local cur = knifeSwaps[target]
        if not (cur and cur.skin == skinName and cur.clone and cur.clone.Parent) then
            clearKnifeSwap(target)
            local clone = src:Clone()
            clone.Name = "SkinSwap"
            clone.Anchored = false; clone.CanCollide = false; clone.Massless = true; clone.CanQuery = false
            pcall(function() clone.CFrame = target.CFrame end)
            clone.Parent = target.Parent
            local w = Instance.new("WeldConstraint"); w.Part0 = target; w.Part1 = clone; w.Parent = clone
            local origTrans = target.Transparency
            pcall(function() target.Transparency = 1 end)
            knifeSwaps[target] = {skin = skinName, clone = clone, origTrans = origTrans}
        end
    end
end

-- bake texture skins into the game's weapon blueprint so new models inherit them
local function InjectIntoGameBlueprints(weaponName, skinName)
    if not weaponName or not skinName or skinName == "None" then return end
    local template = findWeaponTemplate(weaponName)
    local skinFolder = getSkinFolder(weaponName, skinName)
    if template and skinFolder then applySkinToRoot(template, skinFolder, true) end
end

local function isKnifeName(weaponName)
    local lw = string.lower(weaponName)
    return lw:find("knife") or lw:find("karambit") or lw:find("melee") or lw:find("blade") or lw:find("dagger")
end

-- ── KNIFE MODEL PICKER (swap the equipped T-knife to a Weapons-folder model) ──
local SelectedKnifeModel = nil          -- chosen Weapons-folder model name, or nil = default

local KNIFE_WORDS = {"knife","karambit","talon","bayonet","butterfly","dagger","melee","kara"}
local function looksKnife(name)
    local n = string.lower(name)
    for _, w in ipairs(KNIFE_WORDS) do if n:find(w, 1, true) then return true end end
    return false
end

local function knifeWeapons()           -- knife models in the Weapons folder
    local out = {}
    for _, w in ipairs(WeaponsFolder:GetChildren()) do
        local isk = looksKnife(w.Name)
        if not isk then for _, d in ipairs(w:GetDescendants()) do
            if string.lower(d.Name):find("knife", 1, true) then isk = true; break end end
        end
        if isk then out[#out+1] = w end
    end
    return out
end

local function inSwapClone(d)            -- true if part belongs to OUR clone (named VXKnifeSwap)
    local a = d
    while a do if a.Name == "VXKnifeSwap" then return true end; a = a.Parent end
    return false
end
local function equippedKnifeParts()     -- the equipped knife's meshparts under the viewmodel
    local parts = {}
    for _, root in ipairs(viewmodelRoots()) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("MeshPart") and looksKnife(d.Name) and not inSwapClone(d) then parts[#parts+1] = d end
        end
    end
    return parts
end

local function modelMeshes(model)
    local out = {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("MeshPart") and d.MeshId ~= "" then out[#out+1] = d end
    end
    return out
end

-- ── KNIFE MODEL OPTIONS (build a big list of selectable models) ───────────────
-- Pulls from THREE sources so you actually have lots to choose from:
--   1) every knife model in the Weapons folder
--   2) every OTHER weapon model that has a mesh (so you can put any model in hand)
--   3) every knife SKIN folder that ships its own mesh (distinct skin-models)
local KnifeModelMap = {}            -- displayName -> source Instance (model or skin folder)
local function addKnifeOption(list, name, src)
    if name and src and not KnifeModelMap[name] then KnifeModelMap[name] = src; list[#list+1] = name end
end
local function knifeModelOptions()
    local list = {}
    KnifeModelMap = {}
    for _, w in ipairs(knifeWeapons()) do addKnifeOption(list, w.Name, w) end                       -- 1) knife models
    for _, w in ipairs(WeaponsFolder:GetChildren()) do                                              -- 2) all other weapon models w/ a mesh
        if not KnifeModelMap[w.Name] and #modelMeshes(w) > 0 then addKnifeOption(list, w.Name, w) end
    end
    for _, cat in ipairs(SkinsFolder:GetChildren()) do                                              -- 3) knife skin meshes
        if looksKnife(cat.Name) then
            for _, skin in ipairs(cat:GetChildren()) do
                if #modelMeshes(skin) > 0 then addKnifeOption(list, "Skin · "..skin.Name, skin) end
            end
        end
    end
    table.sort(list)
    return list
end

-- ── GRIP HANDLE: the part the knife is actually held by = Camera.Arms.Handle ───
-- Anchoring the swapped model to THIS (not the blade mesh) is what puts it in-hand.
local function findGripHandle()
    local cam = workspace.CurrentCamera; if not cam then return nil end
    local arms = cam:FindFirstChild("Arms")
    if arms then
        local h = arms:FindFirstChild("Handle")
        if h and h:IsA("BasePart") and not inSwapClone(h) then return h end
        for _, d in ipairs(arms:GetDescendants()) do
            if d:IsA("BasePart") and string.lower(d.Name) == "handle" and not inSwapClone(d) then return d end
        end
    end
    for _, root in ipairs(viewmodelRoots()) do                                                       -- fallback: any viewmodel Handle
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BasePart") and string.lower(d.Name) == "handle" and not inSwapClone(d) then return d end
        end
    end
    return nil
end

-- Persistent follower: build the clone ONCE under the Camera (survives the game's
-- constant viewmodel rebuilds), then every frame snap it onto the live knife and
-- hide the real one via LocalTransparencyModifier (which also survives rebuilds).
local knifeClone, knifeCloneModel
local knifeHidden = {}             -- live knife parts we hid (restore on Default)
local knifeOffset = CFrame.new()   -- recomputed from the sliders below
local knifePos   = Vector3.new(0, 0, 0)   -- studs
local knifeRot   = Vector3.new(0, 0, 0)   -- degrees
local knifeScale = 1
local function updateKnifeOffset()
    knifeOffset = CFrame.new(knifePos)
        * CFrame.Angles(math.rad(knifeRot.X), math.rad(knifeRot.Y), math.rad(knifeRot.Z))
end

local function setHidden(part, on) pcall(function() part.LocalTransparencyModifier = on and 1 or 0 end) end
local function destroyKnifeClone()
    if knifeClone then pcall(function() knifeClone:Destroy() end) end
    knifeClone, knifeCloneModel = nil, nil
end

local function restoreKnifeModel()
    destroyKnifeClone()
    for _, p in ipairs(knifeHidden) do if p and p.Parent then setHidden(p, false) end end
    knifeHidden = {}
end

-- the grip reference inside a template: its OWN "Handle" part if it has one, else the
-- centroid of its meshes. This is the point we line up with Camera.Arms.Handle, so EVERY
-- model (even ones with no Handle of their own) seats in the hand the same way.
local function templateGripCF(template, meshes)
    for _, d in ipairs(template:GetDescendants()) do
        if d:IsA("BasePart") and string.lower(d.Name) == "handle" then return d.CFrame end
    end
    if #meshes > 0 then
        local sum = Vector3.zero
        for _, m in ipairs(meshes) do sum = sum + m.Position end
        return CFrame.new(sum / #meshes)
    end
    return CFrame.new()
end

local function buildKnifeClone(template)
    destroyKnifeClone()
    local meshes = modelMeshes(template)
    if #meshes == 0 then return end
    local holder = Instance.new("Model"); holder.Name = "VXKnifeSwap"
    local gripCF = templateGripCF(template, meshes)
    -- invisible GRIP primary at the template's handle -> this is what aligns onto Camera.Arms.Handle
    local grip = Instance.new("Part")
    grip.Name="Grip"; grip.Size=Vector3.new(0.05,0.05,0.05); grip.Transparency=1
    grip.Anchored=false; grip.CanCollide=false; grip.Massless=true; grip.CanQuery=false
    grip.CFrame = gripCF; grip.Parent = holder
    for _, m in ipairs(meshes) do
        local c = m:Clone()
        c.Anchored=false; c.CanCollide=false; c.Massless=true; c.CanQuery=false
        local rel = gripCF:ToObjectSpace(m.CFrame)       -- keep each mesh posed RELATIVE to the grip
        if knifeScale ~= 1 then
            c.Size = c.Size * knifeScale
            rel = CFrame.new(rel.Position * knifeScale) * (rel - rel.Position)
        end
        c.CFrame = grip.CFrame * rel
        c.Parent = holder
        local w = Instance.new("WeldConstraint"); w.Part0 = grip; w.Part1 = c; w.Parent = c
    end
    holder.PrimaryPart = grip                            -- PivotTo uses this -> grip lands on the hand handle
    holder.Parent = workspace.CurrentCamera
    knifeClone, knifeCloneModel = holder, SelectedKnifeModel
end

local function knifeTemplate()             -- resolve the chosen option to a source instance
    if not SelectedKnifeModel then return nil end
    return KnifeModelMap[SelectedKnifeModel] or WeaponsFolder:FindFirstChild(SelectedKnifeModel)
end
local function applyKnifeModelSwap()       -- GUI calls this on select
    local template = knifeTemplate()
    if template then buildKnifeClone(template) end
end

RunService.RenderStepped:Connect(function()
    if not SelectedKnifeModel then return end
    local template = knifeTemplate(); if not template then return end
    if not knifeClone or knifeClone.Parent == nil or knifeCloneModel ~= SelectedKnifeModel then
        buildKnifeClone(template)
    end
    if not knifeClone then return end

    -- GRIP: anchor to the actual hand handle (Camera.Arms.Handle); fall back to the biggest knife mesh.
    local handle = findGripHandle()
    local eq = equippedKnifeParts()
    local anchor = handle
    if not anchor and #eq > 0 then
        anchor = eq[1]
        for _, p in ipairs(eq) do if p.Size.Magnitude > anchor.Size.Magnitude then anchor = p end end
    end
    if not anchor then        -- nothing to grip onto yet (knife not out) -> hide our clone
        for _, c in ipairs(knifeClone:GetDescendants()) do if c:IsA("MeshPart") then setHidden(c, true) end end
        return
    end

    -- Hide ONLY the original knife meshes (NEVER the whole Arms model, or your hands vanish).
    knifeHidden = {}
    local function hidePart(p) setHidden(p, true); knifeHidden[#knifeHidden+1] = p end
    for _, p in ipairs(eq) do hidePart(p) end
    local km = eq[1] and eq[1].Parent
    if km and km:IsA("Model") and looksKnife(km.Name) then        -- also hide blade+guard siblings inside the knife MODEL
        for _, d in ipairs(km:GetDescendants()) do
            if d:IsA("MeshPart") and not inSwapClone(d) then hidePart(d) end
        end
    end

    for _, c in ipairs(knifeClone:GetDescendants()) do if c:IsA("MeshPart") then setHidden(c, false) end end
    pcall(function() knifeClone:PivotTo(anchor.CFrame * knifeOffset) end)              -- snap onto the hand handle
end)

-- re-skin what you SEE: Camera.Arms viewmodel + your character.
-- Knives = MODEL swap; everything else = texture / SurfaceAppearance swap.
local function LiveWorkspaceOverride()
    local roots = viewmodelRoots()
    if LP.Character then roots[#roots+1] = LP.Character end
    for weaponName, currentSkin in pairs(_G.ActiveSkins) do
        local knife = isKnifeName(weaponName)
        if currentSkin and currentSkin ~= "None" then
            local skinFolder = getSkinFolder(weaponName, currentSkin)
            if skinFolder then
                if knife then
                    for _, root in ipairs(roots) do applyKnifeModel(root, skinFolder, currentSkin, weaponName) end
                else
                    local template = findWeaponTemplate(weaponName)
                    if template then applySkinToRoot(template, skinFolder, true) end
                    for _, root in ipairs(roots) do
                        local wm = findWeaponModel(root, weaponName)
                        if wm then applySkinToRoot(wm, skinFolder, true)
                        else applySkinToRoot(root, skinFolder, false) end
                    end
                end
            end
        elseif knife and currentSkin == "None" then
            clearAllKnifeSwaps()
        end
    end
end

task.spawn(function()
    while task.wait(0.3) do
        pcall(LiveWorkspaceOverride)
    end
end)

-- ── GUI ──────────────────────────────────────────────────────────────────────
local TabWeapons = Window:CreateTab("All Weapons", 4483362458)

TabWeapons:CreateSection("Configuration Manager")

TabWeapons:CreateButton({
    Name = "Apply / Refresh All",
    Callback = function() pcall(LiveWorkspaceOverride) end,
})

TabWeapons:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        local success, err = pcall(function()
            writefile("Bros_Skins_Config.json", HttpService:JSONEncode(_G.ActiveSkins))
        end)
        if success then
            Rayfield:Notify({Title = "Config Saved", Content = "Saved setup to Bros_Skins_Config.json", Duration = 3})
        else
            Rayfield:Notify({Title = "Error Saving", Content = tostring(err), Duration = 4})
        end
    end,
})

TabWeapons:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        if not isfile("Bros_Skins_Config.json") then
            Rayfield:Notify({Title = "Load Aborted", Content = "No saved configuration file located.", Duration = 3})
            return
        end
        local success, err = pcall(function()
            local parsed = HttpService:JSONDecode(readfile("Bros_Skins_Config.json"))
            for weapon, skin in pairs(parsed) do
                _G.ActiveSkins[weapon] = skin
                InjectIntoGameBlueprints(weapon, skin)
                if DropdownElements[weapon] then
                    pcall(function() DropdownElements[weapon]:Set({skin}) end)
                end
            end
        end)
        if success then
            pcall(LiveWorkspaceOverride)
            Rayfield:Notify({Title = "Config Loaded", Content = "Weapons synchronized successfully.", Duration = 3})
        else
            Rayfield:Notify({Title = "Error Loading", Content = tostring(err), Duration = 4})
        end
    end,
})

TabWeapons:CreateSection("Knife Model")
do
    local function buildOpts()
        local opts = {"TKnife (Default)"}
        for _, name in ipairs(knifeModelOptions()) do opts[#opts+1] = name end
        return opts
    end
    local knifeDrop = TabWeapons:CreateDropdown({
        Name = "Swap Knife To",
        Options = buildOpts(),
        CurrentOption = {"TKnife (Default)"},
        MultipleOptions = false,
        Callback = function(sel)
            local choice = (type(sel) == "table" and sel[1]) or sel
            if choice == "TKnife (Default)" then
                SelectedKnifeModel = nil; restoreKnifeModel()
            else
                SelectedKnifeModel = choice; pcall(applyKnifeModelSwap)
            end
        end,
    })
    TabWeapons:CreateButton({
        Name = "Refresh model list",                  -- re-scan Weapons + Skins for new models
        Callback = function()
            local opts = buildOpts()
            pcall(function() knifeDrop:Refresh(opts, false) end)
            Rayfield:Notify({Title="Knife Models", Content=("Found %d models."):format(#opts-1), Duration=4})
        end,
    })
end

TabWeapons:CreateSection("Knife Position (drag to grip it in hand)")
do
    local function mk(name, lo, hi, inc, def, setter)
        TabWeapons:CreateSlider({Name=name, Range={lo,hi}, Increment=inc, Suffix="", CurrentValue=def,
            Callback=function(v) setter(v) end})
    end
    mk("Pos X", -5,5, 0.05, 0, function(v) knifePos = Vector3.new(v, knifePos.Y, knifePos.Z); updateKnifeOffset() end)
    mk("Pos Y", -5,5, 0.05, 0, function(v) knifePos = Vector3.new(knifePos.X, v, knifePos.Z); updateKnifeOffset() end)
    mk("Pos Z", -5,5, 0.05, 0, function(v) knifePos = Vector3.new(knifePos.X, knifePos.Y, v); updateKnifeOffset() end)
    mk("Rot X", -180,180, 1, 0, function(v) knifeRot = Vector3.new(v, knifeRot.Y, knifeRot.Z); updateKnifeOffset() end)
    mk("Rot Y", -180,180, 1, 0, function(v) knifeRot = Vector3.new(knifeRot.X, v, knifeRot.Z); updateKnifeOffset() end)
    mk("Rot Z", -180,180, 1, 0, function(v) knifeRot = Vector3.new(knifeRot.X, knifeRot.Y, v); updateKnifeOffset() end)
    mk("Scale", 0.2,3, 0.05, 1, function(v) knifeScale = v; if SelectedKnifeModel then pcall(applyKnifeModelSwap) end end)
end

TabWeapons:CreateSection("Weapon Inventory")

local function BuildDropdown(tab, folder)
    local weaponName = folder.Name
    local dropdown = tab:CreateDropdown({
        Name = string.upper(weaponName),
        Options = GetSkinNames(weaponName),
        CurrentOption = {"None"},
        MultipleOptions = false,
        Callback = function(Selected)
            local choice = (type(Selected) == "table" and Selected[1]) or Selected
            _G.ActiveSkins[weaponName] = choice
            InjectIntoGameBlueprints(weaponName, choice)
            pcall(LiveWorkspaceOverride)
        end,
    })
    DropdownElements[weaponName] = dropdown
end

-- sort folders so gloves/knives are easy to find
local folders = {}
for _, folder in ipairs(SkinsFolder:GetChildren()) do folders[#folders+1] = folder end
table.sort(folders, function(a, b) return a.Name:lower() < b.Name:lower() end)
for _, folder in ipairs(folders) do
    BuildDropdown(TabWeapons, folder)
end

Rayfield:Notify({Title="Skin Changer", Content=("Loaded %d weapon/skin categories. Pick a skin from any dropdown."):format(#folders), Duration=5})
