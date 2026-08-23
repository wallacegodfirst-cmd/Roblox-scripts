--[[  Dream Hub · Jujutsu Shenanigans — UPDATE / BETA build, VIP tier (hardened loader)

      This is the SAME loader shape as DreamHub_JJS_Free.lua, with one difference that is the whole
      point of the file: it fetches DreamHub_JJS.lua (the DEV build, updated constantly) instead of
      DreamHub_JJS_Public.lua (the frozen build your users load).

      ── WHO GETS WHAT ──────────────────────────────────────────────────────────────────────────
        Your users   ->  DreamHub_JJS_Free.lua      ->  fetches DreamHub_JJS_Public.lua  (frozen)
        You / testers ->  DreamHub_JJS_Update_VIP.lua -> fetches DreamHub_JJS.lua  (newest, VIP)

      So day-to-day fixes never reach your users until you say "release it" and the public file is
      updated. Until then they stay on the last build you approved, and nothing you are mid-way
      through testing can break them.

      ── LOAD IT ────────────────────────────────────────────────────────────────────────────────
        loadstring(game:HttpGet("https://raw.githubusercontent.com/wallacegodfirst-cmd/Roblox-scripts/refs/heads/codex/rework-hitbox-food-tps/DreamHub_JJS_Update_VIP.lua"))()

      This loader is hard-wired to VIP. The FREE-tier equivalent is DreamHub_JJS_Update.lua, and your
      users are unaffected either way - they load DreamHub_JJS_Free.lua, which fetches the frozen build.

      Some executors' HttpGet proxy returns corrupted/empty junk instead of the real script; a plain
      one-line loader then runs `loadstring(nil)()` = "attempt to call a nil value". This loader
      VALIDATES every download, retries through several fetch methods, and reports what happened.  ]]

-- Tier: VIP, always. This file exists so you can test the newest dev build at VIP WITHOUT having to
-- remember to set a flag first - loading it IS the tier. VIP is the 'premium' tier internally - that is the name the hub badges as VIP.
-- The flags are consumed by the hub on load (they live in _G and would otherwise leak between runs), so a
-- previous FREE or PLUS run cannot bleed into this one.
_G.JJS_FREE, _G.JJS_PLUS, _G.JJS_PLUSS, _G.JJS_PREMIUM, _G.JJS_PREM = nil, nil, nil, nil, nil
_G.JJS_PREMIUM = true
-- ═══ UPDATE-CHANNEL MARKER ═══ The dev build hides everything still in testing unless this is set.
-- Only the three UPDATE loaders set it - so anyone who saved the OLD one-liner that pointed straight
-- at DreamHub_JJS.lua gets the dev file WITHOUT the unreleased features, instead of a free preview.
_G.__DreamUpdateChannel = true
_G.__DreamReportWebhook = _G.__DreamReportWebhook or ("https://discord.com/api/webhooks/1527849806108692500/".."Ryczyznv3EQVLJF_Y-AYsMqhK".."_fvBC5T3wu2d1uO5BBmSgMARN0_hST5vRRlzQZHkLyg")   -- bug reports land in your Discord

-- ═══════════════════════════════════════════════════════════
-- JUJUTSU SHENANIGANS BYPASS (ZERO-LAG)
-- We do NOT hook __namecall (JJS 267-kicks for that). The main script destroys the anti-cheat remotes
-- and disables the anti/detect scripts, so a single PivotTo teleport sticks with no rubberband.
-- ═══════════════════════════════════════════════════════════
if not _G.VX_AC_HOOKED then
	_G.VX_AC_HOOKED = true
	print("[JJS Bypass] Loaded: anti-cheat remotes destroyed by the hub; instant teleport.")
end

-- ═══ THE ONLY REAL DIFFERENCE FROM THE FREE LOADER ═══
-- DreamHub_JJS.lua is the DEV file. DreamHub_JJS_Free.lua points at DreamHub_JJS_Public.lua instead.
local URLS = {
	"https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/codex/rework-hitbox-food-tps/DreamHub_JJS.lua",
	"https://github.com/wallacegodfirst-cmd/roblox-scripts/raw/codex/rework-hitbox-food-tps/DreamHub_JJS.lua",
}
local StarterGui = game:GetService("StarterGui")
local function toast(msg, dur)
	pcall(function() StarterGui:SetCore("SendNotification", {Title="Dream Hub UPDATE VIP", Text=msg, Duration=dur or 6}) end)
	print("[Dream Hub update loader VIP] "..tostring(msg))
end
toast("JJS UPDATE VIP (beta) loader running - fetching newest build...")

-- the real script is ~600KB, starts with a --[[ comment, and contains our banner
local function valid(src)
	return type(src)=="string" and #src>200000 and src:sub(1,2)=="--" and src:find("Dream Hub", 1, true) ~= nil
end
local req = (typeof(syn)=="table" and syn.request) or (typeof(http)=="table" and http.request) or http_request or (typeof(fluxus)=="table" and fluxus.request) or request
local function fetch(u)
	local src
	pcall(function() src = game:HttpGet(u) end)                     -- 1) normal path
	if valid(src) then return src, "HttpGet" end
	local bad = src
	src = nil
	pcall(function() src = game:HttpGetAsync(u) end)                -- 2) async path (separate impl on many executors)
	if valid(src) then return src, "HttpGetAsync" end
	bad = bad or src
	if req then                                                     -- 3) executor request() (skips the HttpGet proxy)
		local r; pcall(function() r = req({Url=u, Method="GET"}) end)
		src = r and (r.Body or r.body)
		if valid(src) then return src, "request()" end
		bad = bad or src
	end
	return nil, nil, bad
end

local src, how, bad
for i=1,4 do
	for _,base in ipairs(URLS) do
		src, how, bad = fetch(base.."?cb="..tostring(math.floor(os.clock()*100000)+i))   -- cache-buster: a beta loader must never serve a stale copy
		if src then break end
	end
	if src then break end
	toast("try "..i.."/4 failed - retrying...", 3)
	task.wait(1)
end
if not src then
	if type(bad)=="string" and #bad>0 then
		toast("Your executor is corrupting downloads (got "..#bad.." bytes starting with '"..tostring(bad:sub(1,12)).."' instead of the script). Use a different executor.", 14)
	else
		toast("Download failed - check your internet / executor HttpGet, then re-execute.", 10)
	end
	return
end
toast("download verified via "..how.." - starting Dream Hub UPDATE VIP (beta)...")
local fn, err = loadstring(src)
if not fn then toast("compile error (send this to support): "..tostring(err), 14) return end
local ok, rerr = pcall(fn)
if not ok then toast("script error (send this to support): "..tostring(rerr), 14) return end
