--[[  Dream Hub · Ability Arena — PREMIUM build
      Everything in Plus (God Mode: lobby TP-to-fight, can't be hurt) plus the Premium-only
      features as they land. This is a thin loader: it flips the Premium flags, then loads
      the shared Ability Arena hub. Premium counts as Plus, so nothing Plus is ever missing.
      Load:  loadstring(game:HttpGet("<raw url to this file>"))()  ]]
_G.AA_PLUS = true
_G.AA_PREM = true
_G.AA_TIER = "PREMIUM"
pcall(function()
    local env = getgenv()
    env.AA_PLUS = true
    env.AA_PREM = true
    env.AA_TIER = "PREMIUM"
end)
-- Optional: set _G.__DreamReportWebhook before loading to enable reports.

local URLS = {
    "https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/129b3d18b31cfcd18c907ceb6c3eb767d2a904dc/AbilityArena_CozyHub.lua",
    "https://github.com/wallacegodfirst-cmd/roblox-scripts/raw/129b3d18b31cfcd18c907ceb6c3eb767d2a904dc/AbilityArena_CozyHub.lua",
}
local function toast(m) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Ability Arena PREMIUM", Text = m, Duration = 6 }) end) end

local req = (typeof(syn) == "table" and syn.request) or (typeof(http) == "table" and http.request) or http_request or (typeof(fluxus) == "table" and fluxus.request) or request
local function valid(s) return type(s) == "string" and #s > 50000 end
local function fetch(u)
    local s
    pcall(function() s = game:HttpGet(u) end); if valid(s) then return s end
    pcall(function() s = game:HttpGetAsync(u) end); if valid(s) then return s end
    if req then local r; pcall(function() r = req({ Url = u, Method = "GET" }) end); s = r and (r.Body or r.body); if valid(s) then return s end end
    return nil
end

local src
for i = 1, 4 do
    for _, base in ipairs(URLS) do
        src = fetch(base .. "?cb=" .. tostring(math.floor(os.clock() * 100000) + i))
        if src then break end
    end
    if src then break end
    task.wait(1)
end
if not src then toast("Download failed — check your executor / internet, then re-execute.") return end
local fn, err = loadstring(src)
if not fn then toast("compile error: " .. tostring(err)) return end
local ok, rerr = pcall(fn)
if not ok then toast("run error: " .. tostring(rerr)) return end

