-- Universal Name Hider / Randomizer (Rayfield) - works in any game
-- Scrambles the name shown over YOUR head into random unreadable text and keeps
-- re-applying it (games often overwrite the nametag every frame).
-- NOTE: this is CLIENT-SIDE. It changes what YOU see above your character; Roblox
-- does not replicate name/display changes to other players in most games, so it
-- won't reliably hide your name from everyone.

local Rayfield   = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local S = { On = false, Len = 10, Zalgo = false }
local current = ""
local realName, realDisplay = LP.Name, LP.DisplayName

local CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz0123456789#$%&@!?*"
local ZALGO = {"\u{0301}","\u{0300}","\u{0334}","\u{0489}","\u{0353}","\u{036F}","\u{0488}","\u{0316}"}

local function randName()
    local t = {}
    for i = 1, math.max(3, S.Len) do
        local idx = math.random(1, #CHARS)
        t[i] = CHARS:sub(idx, idx)
        if S.Zalgo then
            for _ = 1, math.random(1, 3) do
                t[i] = t[i] .. ZALGO[math.random(1, #ZALGO)]
            end
        end
    end
    return table.concat(t)
end

local function isMyNameText(txt)
    return txt == realName or txt == realDisplay or txt == current
end

local function apply()
    if not S.On then return end
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.DisplayName = current end) end
    for _, d in ipairs(char:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and isMyNameText(d.Text) then
            pcall(function() d.Text = current end)
        end
    end
end

local function restore()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.DisplayName = realDisplay end) end
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text == current then
                pcall(function() d.Text = realDisplay end)
            end
        end
    end
end

current = randName()
RunService.Heartbeat:Connect(function() pcall(apply) end)
LP.CharacterAdded:Connect(function() task.wait(0.5); pcall(apply) end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Win = Rayfield:CreateWindow({
    Name = "Universal Name Hider",
    LoadingTitle = "Name Randomizer",
    LoadingSubtitle = "works in any game",
    ConfigurationSaving = { Enabled = false },
})
local Tab = Win:CreateTab("Name", 4483362458)

Tab:CreateSection("Randomize")
Tab:CreateToggle({Name="Hide / Randomize My Name", CurrentValue=false, Flag="On", Callback=function(v)
    S.On = v
    if v then current = randName(); apply() else restore() end
end})
Tab:CreateButton({Name="Re-roll Name", Callback=function()
    current = randName(); apply()
    Rayfield:Notify({Title="Name", Content="New name applied.", Duration=3})
end})
Tab:CreateSlider({Name="Length", Range={3,24}, Increment=1, Suffix="chars", CurrentValue=10, Flag="Len", Callback=function(v)
    S.Len = v; if S.On then current = randName(); apply() end
end})
Tab:CreateToggle({Name="Zalgo (glitchy / unreadable)", CurrentValue=false, Flag="Zalgo", Callback=function(v)
    S.Zalgo = v; if S.On then current = randName(); apply() end
end})
Tab:CreateButton({Name="Restore Real Name", Callback=function() S.On = false; restore() end})

Tab:CreateSection("Info")
Tab:CreateParagraph({Title="Heads up", Content="Client-side only: this changes the name YOU see over your head. Roblox doesn't replicate name changes to other players in most games, so it may not hide you from everyone."})

Rayfield:Notify({Title="Name Randomizer", Content="Loaded - toggle 'Hide My Name'.", Duration=5})
