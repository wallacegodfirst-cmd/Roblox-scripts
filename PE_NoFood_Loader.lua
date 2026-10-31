--[[  Dream Hub · Prior Extinction NO-FOOD — hardened loader
      Some executors' HttpGet proxy returns corrupted/cached junk instead of the real script
      (the console then shows `[string "Luraph "]... attempt to call a nil value` = you ran
      someone else's obfuscated garbage, not Dream Hub). This loader VALIDATES every download
      is really Prior Ex Plus, retries through several fetch methods to route around a bad
      proxy, and tells you in plain words what happened.  ]]

_G.PE_HIDE_LITE = true   -- hide the food/alert/bot sections (No-Food build)
-- TWO mirrors of the same file: if an executor proxy has poisoned its cache for one host,
-- the other host path fetches clean.
local URLS = {
	"https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/PriorExtinction_MoneyFreeHub.lua",
	"https://github.com/wallacegodfirst-cmd/roblox-scripts/raw/claude/improve-ai-system-tUhhn/PriorExtinction_MoneyFreeHub.lua",
}
local StarterGui = game:GetService("StarterGui")
local function toast(msg, dur)
	pcall(function() StarterGui:SetCore("SendNotification", {Title="Dream Hub loader", Text=msg, Duration=dur or 6}) end)
	print("[Dream Hub loader] "..tostring(msg))
end
toast("loader running - fetching Prior Ex No-Food...")

-- the real script is ~290KB, starts with a --[[ comment, and contains our banner
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
toast("download verified via "..how.." - starting Dream Hub...")
local fn, err = loadstring(src)
if not fn then toast("compile error (send this to support): "..tostring(err), 14) return end
local ok, rerr = pcall(fn)
if not ok then toast("script error (send this to support): "..tostring(rerr), 14) return end

-- proof the menu really exists a few seconds after boot
task.delay(6, function()
	local found = false
	local hosts = {}
	pcall(function() if typeof(gethui)=="function" then hosts[#hosts+1]=gethui() end end)
	pcall(function() hosts[#hosts+1]=game:GetService("CoreGui") end)
	pcall(function() local lp=game:GetService("Players").LocalPlayer; hosts[#hosts+1]=lp and lp:FindFirstChildOfClass("PlayerGui") end)
	for _,h in ipairs(hosts) do
		if h then for _,g in ipairs(h:GetChildren()) do if g.Name=="MoneyHubPE" then found=true break end end end
		if found then break end
	end
	if found then toast("Dream Hub is up - press RightShift (or the on-screen button on mobile)", 8)
	else toast("script ran but no menu detected - send this message to support", 10) end
end)
