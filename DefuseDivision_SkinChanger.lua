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

-- a skin folder's "look": ANY SurfaceAppearance, plus a fallback texture string.
local function getSkinAppearance(skinFolder)
    if not skinFolder then return nil end
    local direct = skinFolder:FindFirstChild("Texture")
    if direct and direct:IsA("SurfaceAppearance") then return direct end
    for _, d in ipairs(skinFolder:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then return d end
    end
    return nil
end
local function getSkinTexture(skinFolder)
    if not skinFolder then return nil end
    local wm = skinFolder:FindFirstChild("Worldmodel") or skinFolder:FindFirstChild("TextureID")
    if wm and wm:IsA("StringValue") and wm.Value ~= "" then return wm.Value end
    for _, d in ipairs(skinFolder:GetDescendants()) do
        if d:IsA("StringValue") and tostring(d.Value):find("rbxassetid") then return d.Value end
    end
    return nil
end

-- apply a skin folder's look to every MeshPart under `root`
local function applySkinToRoot(root, skinFolder)
    if not (root and skinFolder) then return end
    local sa  = getSkinAppearance(skinFolder)
    local tex = getSkinTexture(skinFolder)
    if not (sa or tex) then return end
    for _, part in ipairs(root:GetDescendants()) do
        if part:IsA("MeshPart") then
            if sa then
                for _, old in ipairs(part:GetChildren()) do
                    if old:IsA("SurfaceAppearance") then old:Destroy() end
                end
                sa:Clone().Parent = part
            elseif tex then
                pcall(function() part.TextureID = tex end)
            end
        end
    end
end

local function getSkinFolder(weaponName, skinName)
    local wf = SkinsFolder:FindFirstChild(weaponName)
    return wf and wf:FindFirstChild(skinName) or nil
end

-- bake the skin into the game's weapon blueprint so newly-spawned models inherit it
local function InjectIntoGameBlueprints(weaponName, skinName)
    if not weaponName or not skinName or skinName == "None" then return end
    local template = findWeaponTemplate(weaponName)
    local skinFolder = getSkinFolder(weaponName, skinName)
    if template and skinFolder then applySkinToRoot(template, skinFolder) end
end

-- re-skin what you actually SEE: the first-person Viewmodel + your character
local function LiveWorkspaceOverride()
    local camera = workspace.CurrentCamera
    local vm  = camera and camera:FindFirstChild("Viewmodel")
    local char = LP.Character
    for weaponName, currentSkin in pairs(_G.ActiveSkins) do
        if currentSkin and currentSkin ~= "None" then
            local skinFolder = getSkinFolder(weaponName, currentSkin)
            if skinFolder then
                InjectIntoGameBlueprints(weaponName, currentSkin)
                if vm then applySkinToRoot(vm, skinFolder) end        -- first-person hands/knife/gun
                if char then applySkinToRoot(char, skinFolder) end    -- third-person gloves / held knife
            end
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
