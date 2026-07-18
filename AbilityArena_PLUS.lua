--[[  Dream Hub · Ability Arena — PLUS build
      Same hub as the free one, PLUS God Mode (lobby TP-to-fight, can't be hurt).
      This is a thin loader: it flips the PLUS flag, then loads the shared Ability Arena hub.
      Load:  loadstring(game:HttpGet("<raw url to this file>"))()  ]]
_G.AA_PLUS = true
_G.__DreamReportWebhook = _G.__DreamReportWebhook or ("https://discord.com/api/webhooks/1527849806108692500/".."Ryczyznv3EQVLJF_Y-AYsMqhK".."_fvBC5T3wu2d1uO5BBmSgMARN0_hST5vRRlzQZHkLyg")   -- PASTE YOUR DISCORD WEBHOOK URL here to receive bug reports live

local URLS = {
    "https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/AbilityArena_CozyHub.lua",
    "https://github.com/wallacegodfirst-cmd/roblox-scripts/raw/claude/improve-ai-system-tUhhn/AbilityArena_CozyHub.lua",
}
local function toast(m) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Ability Arena PLUS", Text = m, Duration = 6 }) end) end

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
