--[[  Dream Hub · Jujutsu Shenanigans — FREE build (hardened loader)
      Red & black theme. Trimmed feature set (auto BF chain modes, auto Rika sword, side/back dash,
      auto evasive, auto adapt, emote/jump counter, feint BF, Crow Ult + Lock On are Premium-only).
      Everything else — including Auto Uppercut/Down Slam and Auto Air — is included.

      Some executors' HttpGet proxy returns corrupted/empty junk instead of the real script; the old
      one-line loader then ran `loadstring(nil)()` = "attempt to call a nil value". This loader
      VALIDATES every download, retries through several fetch methods, and reports plainly what happened.
      Load: loadstring(game:HttpGet("<this url>"))()  ]]
_G.JJS_FREE = true   -- switches the shared hub to the FREE tier (red/black + trimmed features + FREE badge)

-- ═══════════════════════════════════════════════════════════
-- JUJUTSU SHENANIGANS BYPASS (your EXACT script, verbatim) — runs FIRST, before the download.
-- ═══════════════════════════════════════════════════════════
if not _G.VX_AC_HOOKED then
	_G.VX_AC_HOOKED = true
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer

	local allowAntiCheatTP = false
	local AntiCheatTP = nil

	-- 1. Dynamically find the AntiCheat Teleport Remote
	local function findAntiCheatRemote()
		local rs = game:GetService("ReplicatedStorage")
		for _, v in ipairs(rs:GetDescendants()) do
			if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name == "Teleport" then
				local parent = v.Parent
				for i = 1, 5 do
					if not parent then break end
					if parent.Name:lower():find("anticheat") then
						return v
					end
					parent = parent.Parent
				end
			end
		end
		return nil
	end

	AntiCheatTP = findAntiCheatRemote()

	-- 2. Hook Metamethods (Block Kick & Block Anti-Cheat Remote)
	pcall(function()
		local mt = getrawmetatable(game)
		local oldNamecall = mt.__namecall
		setreadonly(mt, false)

		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()

			-- Intercept and block any kick attempts (Prevents Error 267)
			if method == "Kick" and self == LP then
				return nil
			end

			-- Intercept and block the AntiCheat Teleport remote
			if (method == "FireServer" or method == "InvokeServer") and not allowAntiCheatTP then
				if self == AntiCheatTP then
					return nil
				end
				-- Fallback check just in case the instance reference was lost
				if self and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) and self.Name == "Teleport" then
					local p = self.Parent
					local isAC = false
					for i=1, 5 do
						if not p then break end
						if p.Name:lower():find("anticheat") then
							isAC = true
							break
						end
						p = p.Parent
					end
					if isAC then return nil end
				end
			end

			return oldNamecall(self, ...)
		end)

		setreadonly(mt, true)
	end)

	-- 3. Disable Local Anti-Cheat Scripts
	task.spawn(function()
		local function disableScripts(parent)
			if not parent then return end
			for _, v in ipairs(parent:GetDescendants()) do
				if v:IsA("LocalScript") then
					local name = v.Name:lower()
					if name:find("anti") or name:find("cheat") or name:find("detect") then
						pcall(function()
							v.Disabled = true
							v.Parent = nil -- Destroy to prevent restart
						end)
					end
				end
			end
		end

		local function disableAll()
			if LP:FindFirstChild("PlayerScripts") then disableScripts(LP.PlayerScripts) end
			if LP:FindFirstChild("Character") then disableScripts(LP.Character) end
			disableScripts(game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"))
		end

		disableAll()
		task.wait(2) -- Wait for Knit to fully load
		disableAll()
	end)

	print("[JJS Bypass] Loaded: Kick Blocked & Anti-Cheat Disabled!")
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
