--[[  Dream Hub · Ability Arena — "No Risky" build
      The SAME hub, but with three features fully REMOVED (never built, and force-off even from a saved config):
        · Auto Dodge   (+ Dodge Player dropdown / Refresh list)
        · Instant 1v1 Win   (+ 1v1 Win Position)
        · M1 Warp   (+ M1 Warp Range / Warp Back After Swing)
      Everything else is identical to the normal hub.
      Load:  loadstring(game:HttpGet("<raw url to this file>"))()

      To also get PLUS features (God Mode / Auto Heal), add:  _G.AA_PLUS = true   BEFORE the loadstring.
      To also get PREMIUM, add:  _G.AA_PREM = true                                                        ]]

-- strip these three (the hub reads _G.AA_REMOVE at build time)
_G.AA_REMOVE = { AutoDodge = true, Win1v1 = true, M1Warp = true }

local URLS = {
    "https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/AbilityArena_CozyHub.lua",
    "https://github.com/wallacegodfirst-cmd/roblox-scripts/raw/claude/improve-ai-system-tUhhn/AbilityArena_CozyHub.lua",
}
local function toast(m) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Ability Arena", Text = m, Duration = 6 }) end) end

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
toast("Loaded — Auto Dodge, Instant 1v1 Win and M1 Warp are removed in this build.")
