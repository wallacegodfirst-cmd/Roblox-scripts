--[[  Dream Hub · Jujutsu Shenanigans — FREE build (hardened loader)
      Red & black theme. Trimmed feature set (auto BF chain modes, auto Rika sword, side/back dash,
      auto evasive, auto adapt, emote/jump counter, feint BF, Crow Ult + Lock On are Premium-only).
      Everything else — including Auto Uppercut/Down Slam and Auto Air — is included.

      Some executors' HttpGet proxy returns corrupted/empty junk instead of the real script; the old
      one-line loader then ran `loadstring(nil)()` = "attempt to call a nil value". This loader
      VALIDATES every download, retries through several fetch methods, and reports plainly what happened.
      Load: loadstring(game:HttpGet("<this url>"))()  ]]
_G.JJS_FREE = true
_G.__DreamReportWebhook = _G.__DreamReportWebhook or ""   -- PASTE YOUR DISCORD WEBHOOK URL here to receive bug reports live   -- switches the shared hub to the FREE tier (red/black + trimmed features + FREE badge)

-- ═══════════════════════════════════════════════════════════
-- JUJUTSU SHENANIGANS BYPASS (ZERO-LAG)
-- We do NOT hook __namecall (JJS 267-kicks for that). The main script destroys the anti-cheat remotes and
-- disables the anti/detect scripts, so a single PivotTo teleport sticks with no rubberband and no lag.
-- ═══════════════════════════════════════════════════════════
if not _G.VX_AC_HOOKED then
	_G.VX_AC_HOOKED = true
	print("[JJS Bypass] Loaded: anti-cheat remotes destroyed by the hub; instant teleport.")
end

local URLS = {
	"https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/DreamHub_JJS.lua",
	"https://github.com/wallacegodfirst-cmd/roblox-scripts/raw/claude/improve-ai-system-tUhhn/DreamHub_JJS.lua",
}
local StarterGui = game:GetService("StarterGui")
local function toast(msg, dur)
	pcall(function() StarterGui:SetCore("SendNotification", {Title="Dream Hub", Text=msg, Duration=dur or 6}) end)
	print("[Dream Hub loader] "..tostring(msg))
end
toast("JJS FREE loader running - fetching...")

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
		src, how, bad = fetch(base.."?cb="..tostring(math.floor(os.clock()*100000)+i))   -- cache-buster: never accept a stale copy
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
toast("download verified via "..how.." - starting Dream Hub FREE...")
local fn, err = loadstring(src)
if not fn then toast("compile error (send this to support): "..tostring(err), 14) return end
local ok, rerr = pcall(fn)
if not ok then toast("script error (send this to support): "..tostring(rerr), 14) return end
