--[[  VAULTIX HUB - JJS combined build  (auto block + auto black flash + bf chain)
      ONE big script for now; will be split into Free / Premium / Plus tiers later.
      Sources: friend's Auto Block engine, Autoblackflash.lua, ULTIMATE BACK-LOCK BF CHAIN.
      No emojis. Toggle the menu with RightShift. Press E to trigger the BF chain manually.   ]]

-- ═══════════════════════════════════════════════════════════
-- JUJUTSU SHENANIGANS BYPASS (ZERO-LAG)
-- We do NOT hook __namecall (JJS 267-kicks for that). Instead we take away the server's ability to reject a
-- teleport: destroy the anti-cheat RE/RF remotes (leaving harmless dummies so other scripts do not crash on
-- WaitForChild) and disable the anti/detect scripts once. With no channel to report a bad position, a single
-- PivotTo teleport just sticks — no per-frame stepping, no rubberband, no lag. See safeTeleport below.
-- ═══════════════════════════════════════════════════════════
if not _G.VX_AC_HOOKED then
	_G.VX_AC_HOOKED = true
	print("[JJS Bypass] Loaded: anti-cheat remotes destroyed; instant teleport, no rubberband.")
end

-- ── ISOLATED ANTI-CHEAT BYPASS (runs FIRST, before any hub code) ─────────────────────────────────────────
-- Destroy the anti-cheat RE/RF remotes with :Destroy() (not Parent=nil — the AC VM already cached the remote,
-- so re-parenting doesn't stop it; :Destroy() nukes its connections so FireServer silently fails). Leave a
-- same-named dummy so other scripts' WaitForChild doesn't freeze. Then disable the local anti/detect scripts.
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local function destroyACRemotes()
		local rs = game:GetService("ReplicatedStorage")
		local knit = rs:FindFirstChild("Knit"); knit = (knit and knit:FindFirstChild("Knit")) or knit
		if not knit then return end
		for _, svc in ipairs(knit:GetDescendants()) do
			if svc.Name:lower():find("anti") then
				for _, folderName in ipairs({ "RE", "RF" }) do
					local folder = svc:FindFirstChild(folderName)
					if folder then
						for _, v in ipairs(folder:GetChildren()) do
							-- ═══ SETTLED BY TESTING, NOT THEORY ═══ AntiCheatService.RE.Teleport used to be kept,
							-- on the reading that the client fires it to announce a sanctioned move (a capture does
							-- show the client firing it with a server timestamp). In-game it went the other way:
							-- "when I click kill AC remote it destroys it, meaning I can teleport". So it is the
							-- server's REPORTER channel, and DESTROYING it is now the default.
							-- Set _G.VX_KEEP_AC_TP = true to go back to keeping it.
							local isACTeleport = (v.Name == "Teleport")
							local skip = isACTeleport and (_G.VX_KEEP_AC_TP == true)
							if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and not v:GetAttribute("VX_Dummy") and not skip then
								local dummy = Instance.new(v.ClassName)
								dummy.Name = v.Name
								dummy:SetAttribute("VX_Dummy", true)   -- tag it so the re-run loop skips our own dummy (no churn)
								dummy.Parent = folder
								pcall(function() v:Destroy() end)
							end
						end
					end
				end
			end
		end
	end
	local function disableACScripts()
		local function process(parent)
			if not parent then return end
			for _, v in ipairs(parent:GetDescendants()) do
				if v:IsA("LocalScript") or v:IsA("ModuleScript") then
					local name = v.Name:lower()
					if name:find("anti") or name:find("cheat") or name:find("detect") or name:find("namecall") then
						pcall(function() v.Disabled = true end)
					end
				end
			end
		end
		pcall(process, LP:FindFirstChild("PlayerScripts"))
		if LP.Character then pcall(process, LP.Character) end
	end
	_G.VX_DESTROY_AC = function() pcall(destroyACRemotes); pcall(disableACScripts) end
	pcall(destroyACRemotes)
	pcall(disableACScripts)
	pcall(function()
		LP.CharacterAdded:Connect(function()
			task.wait(1)
			pcall(destroyACRemotes)
			pcall(disableACScripts)
		end)
	end)
	-- KEEP RE-DESTROYING: Knit lazy-loads its services, so the load-time pass can run BEFORE AntiCheatService
	-- has replicated in (then it finds nothing and the AC remote survives = you still get set back). Re-run for
	-- a while so it catches the remote the moment Knit finishes loading it, and re-nukes any the game recreates.
	-- The VX_Dummy tag makes this a no-op once everything is already destroyed, so there is no churn or lag.
	task.spawn(function()
		for _ = 1, 60 do            -- ~30s of coverage right after load (services can appear seconds late)
			task.wait(0.5)
			pcall(destroyACRemotes)
		end
		-- STOP after a short window. Re-destroying the AC remotes every 5s forever makes the server watch its
		-- own remotes vanish and reappear on a loop - a detectable tampering pattern, and a kick risk in a
		-- public server. Knit lazy-loads within seconds, so a brief watchdog covers the real need.
		for _ = 1, 3 do task.wait(5); pcall(destroyACRemotes) end
	end)
end

-- (LOADING SCREEN REMOVED per request — the hub builds straight away, no splash.)
-- Dream Hub loading screen
_G.__DreamGameName = "JUJUTSU SHENANIGANS"
do
	local _plus = _G.JJS_PLUS or _G.JJS_PLUSS
	local _prem = _G.JJS_PREMIUM or _G.JJS_PREM
	local _free = _G.JJS_FREE
	-- CONSUME them: _G survives between executions, so a flag from an earlier run would otherwise keep
	-- overriding the one you set for THIS run (running FREE after PLUS gave you PLUS, and vice versa).
	_G.JJS_PLUS, _G.JJS_PLUSS, _G.JJS_PREMIUM, _G.JJS_PREM, _G.JJS_FREE = nil, nil, nil, nil, nil
	_G.__DreamTierKey = (_plus and "plus") or (_prem and "premium") or (_free and "free") or "full"
	_G.__DreamTier = (_plus and "PLUS") or (_prem and "PREMIUM") or (_free and "FREE") or "FULL"
end

-- ═══════════════════ DREAM HUB — LOADING SCREEN ═══════════════════
-- (Loading screen + menu removed by request - the hub loads straight in.)
-- ═══════════════════ END LOADING SCREEN ═══════════════════
-- ═══ DREAM HUB — MOD OVERHEAD TITLE (only script-users see it) ═══
-- Rendered LOCALLY by every Dream Hub client: your script draws a floating rainbow title above any whitelisted
-- moderator in the server. Because ONLY people running the script execute this, only they see it — exactly
-- "only people using my scripts can see it". Non-users see nothing. Follows respawns; cheap single loop.
task.spawn(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local MODS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }   -- whitelist (matches Name or DisplayName)
	local ROLE = { ["chloeflash9563"]="OWNER", ["real_revvybxnned11"]="DEV", ["hvdkssl25"]="HEAD MOD", ["bruckner_tempest"]="GAME MOD", ["babbage_sparse"]="MOD" }
	local host; pcall(function() host = (typeof(gethui)=="function" and gethui()) or game:GetService("CoreGui") end)
	if not host then host = Players.LocalPlayer:WaitForChild("PlayerGui") end
	local tags = {}   -- [player] = {gui=BillboardGui, grad=UIGradient}
	local function isMod(plr) return MODS[string.lower(plr.Name)] or MODS[string.lower(plr.DisplayName or "")] end
	local function head(plr)
		local c=plr.Character
		if c then local h=c:FindFirstChild("Head") or c:FindFirstChildWhichIsA("BasePart"); if h then return h end end
		-- Prior Extinction (and games like it): the playable model is NOT plr.Character. Find a workspace model
		-- named after the player (checks folders one level deep too) so mods ALWAYS get their title.
		for _,m in ipairs(workspace:GetChildren()) do
			if (m:IsA("Model")) and (m.Name==plr.Name or m.Name==plr.DisplayName) then local h=m:FindFirstChild("Head") or m:FindFirstChildWhichIsA("BasePart"); if h then return h end end
			if m:IsA("Folder") then local c2=m:FindFirstChild(plr.Name) or (plr.DisplayName and m:FindFirstChild(plr.DisplayName)); if c2 and c2:IsA("Model") then local h=c2:FindFirstChild("Head") or c2:FindFirstChildWhichIsA("BasePart"); if h then return h end end end
		end
		return nil
	end
	local function ensure(plr)
		if not isMod(plr) then return end
		local h=head(plr); if not h then return end
		local t=tags[plr]
		if t and t.gui and t.gui.Parent and t.gui.Adornee==h then return end
		if t and t.gui then pcall(function() t.gui:Destroy() end) end
		local bb=Instance.new("BillboardGui")
		bb.Name="DreamModTag"; bb.Adornee=h; bb.Size=UDim2.fromOffset(280,50); bb.StudsOffsetWorldSpace=Vector3.new(0,(h.Size and h.Size.Y/2 or 1)+3,0); bb.AlwaysOnTop=true; bb.MaxDistance=1200; bb.ResetOnSpawn=false
		local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,26); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack; title.Text="DREAM HUB  "..(ROLE[string.lower(plr.Name)] or ROLE[string.lower(plr.DisplayName or "")] or "GAME MOD"); title.TextSize=20; title.TextColor3=Color3.fromRGB(255,255,255); title.TextStrokeColor3=Color3.fromRGB(10,8,16); title.TextStrokeTransparency=0.15; title.Parent=bb
		local grad=Instance.new("UIGradient"); grad.Color=ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255,80,80)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,190,60)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120,255,120)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80,200,255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(180,120,255)), ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255,90,180)) }); grad.Parent=title
		local sub=Instance.new("TextLabel"); sub.Position=UDim2.new(0,0,0,26); sub.Size=UDim2.new(1,0,0,18); sub.BackgroundTransparency=1; sub.Font=Enum.Font.GothamBold; sub.Text="@"..plr.Name; sub.TextSize=13; sub.TextColor3=Color3.fromRGB(215,215,225); sub.TextStrokeTransparency=0.5; sub.Parent=bb
		bb.Parent=host
		tags[plr]={gui=bb, grad=grad}
	end
	Players.PlayerRemoving:Connect(function(plr) local t=tags[plr]; if t and t.gui then pcall(function() t.gui:Destroy() end) end tags[plr]=nil end)
	-- ensure loop (handles join / respawn / late head)
	task.spawn(function() while true do
		for _,plr in ipairs(Players:GetPlayers()) do pcall(ensure, plr) end
		local ov = _G.__DreamTitleOv
		for plr,t in pairs(tags) do pcall(function()
			local want
			if type(ov) == "table" then want = ov[string.lower(plr.Name)] or ov[string.lower(plr.DisplayName or "")] end
			local lbl = t.gui and t.gui:FindFirstChildOfClass("TextLabel")
			if lbl then
				local base = "DREAM HUB  "..(ROLE[string.lower(plr.Name)] or ROLE[string.lower(plr.DisplayName or "")] or "GAME MOD")
				local goal = want or base
				if lbl.Text ~= goal then lbl.Text = goal end
			end
		end) end
		task.wait(0.5)
	end end)
	-- rainbow animate all tags
	RunService.RenderStepped:Connect(function()
		local off=Vector2.new(((tick()*0.4)%2)-1, 0)
		for _,t in pairs(tags) do if t.grad then pcall(function() t.grad.Offset=off end) end end
	end)
end)
-- ═══ END MOD OVERHEAD TITLE ═══
-- ═══ DREAM HUB — AI RULE WATCHER (admin clients only) ═══
-- Watches public chat locally on a moderator's client. When a message trips a rule, it auto-reports to the admin
-- Discord with the player + the EXACT message as evidence. (Roblox scripts can't capture/upload a real image
-- screenshot, so the verbatim chat line is the proof — cleaner than a screenshot anyway.) Per-player cooldown so
-- it never spams. Only runs for whitelisted admins, so no duplicate reports from normal users.
-- Add your own flagged words:  _G.__DreamBadWords = {"word1","word2"}   before loading.
task.spawn(function()
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local TextChatService = game:GetService("TextChatService")
	local me = Players.LocalPlayer
	if not me then return end
	local MODS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
	if type(_G.__DreamExtraAdmins)=="table" then for _,n in ipairs(_G.__DreamExtraAdmins) do MODS[string.lower(tostring(n))]=true end end
	if not (MODS[string.lower(me.Name)] or MODS[string.lower(me.DisplayName or "")]) then return end
	local HOOK = ("https://discord.com/api/webhooks/1527860474488688732/".."ObBmSPJv0jp9nZHbIoJryLOPrsuyQsTr".."tuwVVwdQ0c759WQa6X0g0j-G4n-VCH-CMH7a")

	local HATE = { "nigg","fagg","retard","kike","tranny","chink","spic" }
	if type(_G.__DreamBadWords)=="table" then for _,w in ipairs(_G.__DreamBadWords) do HATE[#HATE+1]=string.lower(tostring(w)) end end
	local CATS = {
		{ "Rule 2 - hate speech / slur", HATE },
		{ "Rule 7 - advertising", { "discord.gg","join my","my server","buy script","selling script","dm to buy","cheap robux","i sell " } },
		{ "Rule 5 - scam", { "free robux","robux generator","robux gen","tinyurl.com","bit.ly/","claim your","gift card code","rbx.","freerobux" } },
		{ "Rule 1/4 - threats / harassment", { "kys","kill yourself","neck yourself","gonna dox","i'll dox","get cancer","you should die" } },
	}
	local cooldown = {}
	local req = (typeof(syn)=="table" and syn.request) or http_request or (typeof(fluxus)=="table" and fluxus.request) or request
	local function report(pl, msg, rule)
		local uid = (pl and pl.UserId) or 0
		if cooldown[uid] and tick()-cooldown[uid] < 8 then return end
		cooldown[uid] = tick()
		if not req then return end
		task.spawn(function() pcall(function()
			local body = HttpService:JSONEncode({ username="Dream AI Mod", embeds={{ title="Auto-flag: possible rule break in chat", color=15158332, fields={
				{ name="Player", value=(pl and (pl.DisplayName.." (@"..pl.Name..")  ["..tostring(pl.UserId).."]")) or "?", inline=false },
				{ name="Rule", value=rule, inline=false },
				{ name="Message (evidence)", value=string.sub(tostring(msg),1,900), inline=false },
				{ name="Profile", value=(pl and ("https://www.roblox.com/users/"..tostring(pl.UserId).."/profile")) or "-", inline=false },
				{ name="Game", value=tostring(_G.__DreamGameName or "Jujutsu Shenanigans"), inline=true },
				{ name="Caught by", value=me.Name, inline=true },
			} }} })
			local r1=req({ Url=HOOK, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body }) if not (r1 and ((r1.StatusCode and r1.StatusCode>=200 and r1.StatusCode<300) or r1.Success)) then req({ Url=(HOOK:gsub("^https://discord%.com","https://webhook.lewisakura.moe")), Method="POST", Headers={["Content-Type"]="application/json"}, Body=body }) end
		end) end)
	end
	local function scan(pl, msg)
		if not msg or msg=="" or pl==me then return end
		local low = string.lower(msg)
		for _,c in ipairs(CATS) do for _,w in ipairs(c[2]) do if w~="" and low:find(w,1,true) then report(pl, msg, c[1]); return end end end
	end
	-- modern TextChatService
	pcall(function()
		local function hook(ch) if ch:IsA("TextChannel") then ch.MessageReceived:Connect(function(m)
			local pl; pcall(function() local src=m.TextSource; if src then pl=Players:GetPlayerByUserId(src.UserId) end end)
			scan(pl, m.Text)
		end) end end
		for _,d in ipairs(TextChatService:GetDescendants()) do hook(d) end
		TextChatService.DescendantAdded:Connect(hook)
	end)
	-- legacy Chatted (works when the game still uses the old chat)
	local function bind(pl) pcall(function() pl.Chatted:Connect(function(msg) scan(pl, msg) end) end) end
	for _,pl in ipairs(Players:GetPlayers()) do if pl~=me then bind(pl) end end
	Players.PlayerAdded:Connect(function(pl) if pl~=me then bind(pl) end end)
end)
-- ═══ END AI RULE WATCHER ═══
-- ═══ DREAM HUB — LIVE CHAT + AI MOD (all script users) ═══
-- Cross-server chat for everyone running Dream Hub, shared across all supported games. Backed by a tiny
-- public key-value relay (textdb.online): every client polls it and appends its messages, so ONLY people
-- running the hub can see or talk in it. Each row shows the player's avatar, username and plan, plus a MOD
-- badge for staff. The AI mod lives in here too — your message is scanned BEFORE it sends (blocked +
-- reported if it breaks a rule) and incoming messages are censored on arrival. Staff warns are delivered
-- through the same relay and pop up as a NOTIFICATION + warning card (not chat).
-- Honest limit: this can only reach players who are running the hub — it's a relay, not a Roblox feature.
task.spawn(function()
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local StarterGui = game:GetService("StarterGui")
	local UIS = game:GetService("UserInputService")
	local me = Players.LocalPlayer
	if not me then return end
	local GAME = "Jujutsu Shenanigans"
	local TIER = tostring(_G.__DreamTier or "FREE")
	local KEY, WKEY = "dreamhub_lc_v1", "dreamhub_warn_v1"
	local MKEY = "dreamhub_mod_v1"   -- shared moderation state: mutes + emoji bans
	local LKEY = "dreamhub_warnlog_v1"   -- staff warning history (the tracker)
	local MODSTATE = { mu={}, ne={}, sl=0, lk=0, bw={}, tt={} }
	local lastMuteNotif = 0
	local MODS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
	if type(_G.__DreamExtraAdmins)=="table" then for _,n in ipairs(_G.__DreamExtraAdmins) do MODS[string.lower(tostring(n))]=true end end
	local IS_MOD = (MODS[string.lower(me.Name)] or MODS[string.lower(me.DisplayName or "")]) and true or false
	local req = (typeof(syn)=="table" and syn.request) or http_request or (typeof(fluxus)=="table" and fluxus.request) or request
	local HOOK = ("https://discord.com/api/webhooks/1527860474488688732/".."ObBmSPJv0jp9nZHbIoJryLOPrsuyQsTr".."tuwVVwdQ0c759WQa6X0g0j-G4n-VCH-CMH7a")

	-- ---- relay helpers ----
	local function readKey(k)
		local ok, r = pcall(function() return game:HttpGet("https://textdb.online/"..k) end)
		if ok and type(r)=="string" and r~="" then
			local ok2, d = pcall(function() return HttpService:JSONDecode(r) end)
			if ok2 and type(d)=="table" then return d end
		end
		return nil
	end
	local function writeKey(k, tbl)
		local body
		pcall(function() body = "key="..k.."&value="..HttpService:UrlEncode(HttpService:JSONEncode(tbl)) end)
		if not body then return end
		if req then pcall(function() req({ Url="https://textdb.online/update/", Method="POST", Headers={["Content-Type"]="application/x-www-form-urlencoded"}, Body=body }) end)
		else pcall(function() game:HttpGet("https://textdb.online/update/?"..body) end) end
	end

	-- ---- AI mod (same rules as the in-game watcher) ----
	local HATE = { "nigg","fagg","retard","kike","tranny","chink","spic" }
	if type(_G.__DreamBadWords)=="table" then for _,w in ipairs(_G.__DreamBadWords) do HATE[#HATE+1]=string.lower(tostring(w)) end end
	local CATS = {
		{ "Rule 2 - hate speech / slur", HATE },
		{ "Rule 7 - advertising", { "discord.gg","join my","my server","buy script","selling script","dm to buy","cheap robux","i sell " } },
		{ "Rule 5 - scam", { "free robux","robux generator","robux gen","tinyurl.com","bit.ly/","claim your","gift card code","freerobux" } },
		{ "Rule 1/4 - threats / harassment", { "kys","kill yourself","neck yourself","gonna dox","i'll dox","get cancer","you should die" } },
	}
	local function scanText(msg)
		local low = string.lower(tostring(msg or ""))
		for _,c in ipairs(CATS) do for _,w in ipairs(c[2]) do if w~="" and low:find(w,1,true) then return c[1] end end end
		for _,w in ipairs(MODSTATE.bw or {}) do local lw=string.lower(tostring(w)) if lw~="" and low:find(lw,1,true) then return "staff filter" end end
		return nil
	end
	local function reportMsg(uname, uid, msg, rule, note)
		if not req then return end
		task.spawn(function() pcall(function()
			local body = HttpService:JSONEncode({ username="Dream AI Mod", embeds={{ title="Auto-flag: rule break in LIVE CHAT", color=15158332, fields={
				{ name="Player", value=tostring(uname).."  ["..tostring(uid).."]", inline=false },
				{ name="Rule", value=tostring(rule), inline=false },
				{ name="Message (evidence)", value=string.sub(tostring(msg),1,900), inline=false },
				{ name="Profile", value="https://www.roblox.com/users/"..tostring(uid).."/profile", inline=false },
				{ name="Where", value="Live chat ("..GAME..")  -  "..tostring(note or ""), inline=true },
				{ name="Caught by", value=me.Name, inline=true },
			} }} })
			local r1=req({ Url=HOOK, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body }) if not (r1 and ((r1.StatusCode and r1.StatusCode>=200 and r1.StatusCode<300) or r1.Success)) then req({ Url=(HOOK:gsub("^https://discord%.com","https://webhook.lewisakura.moe")), Method="POST", Headers={["Content-Type"]="application/json"}, Body=body }) end
		end) end)
	end

	-- ---- UI ----
	local function esc(s) return tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;") end
	-- emoji shortcodes: typing :skull: sends the actual emoji, Discord-style
	local EMO = { skull="\u{1F480}", fire="\u{1F525}", joy="\u{1F602}", sob="\u{1F62D}", cry="\u{1F622}", smile="\u{1F604}", grin="\u{1F601}", heart="\u{2764}\u{FE0F}", heart_eyes="\u{1F60D}", thumbsup="\u{1F44D}", thumbsdown="\u{1F44E}", crown="\u{1F451}", eyes="\u{1F440}", goat="\u{1F410}", clown="\u{1F921}", cap="\u{1F9E2}", pray="\u{1F64F}", rage="\u{1F621}", cool="\u{1F60E}", ghost="\u{1F47B}", shrug="\u{1F937}", moyai="\u{1F5FF}", x="\u{274C}", check="\u{2705}", wave="\u{1F44B}", ["100"]="\u{1F4AF}" }
	local function emojify(s) local r=tostring(s):gsub("%:([%w_]+)%:", function(k) return EMO[string.lower(k)] or (":"..k..":") end) return r end
	local par
	pcall(function() par = (gethui and gethui()) end)
	if not par then pcall(function() par = game:GetService("CoreGui") end) end
	if not par then par = me:WaitForChild("PlayerGui") end
	local gui = Instance.new("ScreenGui")
	gui.Name = "DH_LC_"..tostring(math.floor(tick()%97))
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = par

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,86,0,30); btn.Position = UDim2.new(1,-96,1,-120)
	btn.BackgroundColor3 = Color3.fromRGB(28,26,40); btn.TextColor3 = Color3.fromRGB(235,232,255)
	btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.Text = "CHAT"; btn.AutoButtonColor = true; btn.Parent = gui
	do local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=btn
	   local st=Instance.new("UIStroke") st.Color=Color3.fromRGB(120,90,255) st.Thickness=1 st.Parent=btn end

	local win = Instance.new("Frame")
	win.Size = UDim2.new(0,320,0,400); win.Position = UDim2.new(1,-340,1,-540)
	win.BackgroundColor3 = Color3.fromRGB(22,20,32); win.Visible = false; win.Active = true; win.Parent = gui
	do local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,10) c.Parent=win
	   local st=Instance.new("UIStroke") st.Color=Color3.fromRGB(120,90,255) st.Thickness=1 st.Parent=win end

	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1,-34,0,32); head.BackgroundTransparency = 1
	head.Font = Enum.Font.GothamBold; head.TextSize = 13; head.TextXAlignment = Enum.TextXAlignment.Left
	head.Text = "   DREAM HUB  -  LIVE CHAT"; head.TextColor3 = Color3.fromRGB(235,232,255); head.Parent = win
	local hide = Instance.new("TextButton")
	hide.Size = UDim2.new(0,26,0,26); hide.Position = UDim2.new(1,-30,0,3)
	hide.BackgroundTransparency = 1; hide.Font = Enum.Font.GothamBold; hide.TextSize = 16
	hide.Text = "-"; hide.TextColor3 = Color3.fromRGB(200,196,220); hide.Parent = win

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1,-12,1,-78); scroll.Position = UDim2.new(0,6,0,34)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 4
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.Parent = win
	local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0,6) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = scroll

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1,-76,0,32); box.Position = UDim2.new(0,6,1,-38)
	box.BackgroundColor3 = Color3.fromRGB(32,30,46); box.TextColor3 = Color3.fromRGB(235,232,255)
	box.PlaceholderText = "Say something...  (:skull: :fire: :100:)"; box.PlaceholderColor3 = Color3.fromRGB(120,116,140)
	box.Font = Enum.Font.Gotham; box.TextSize = 12; box.Text = ""; box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left; box.Parent = win
	do local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=box
	   local pd=Instance.new("UIPadding") pd.PaddingLeft=UDim.new(0,8) pd.PaddingRight=UDim.new(0,8) pd.Parent=box end
	local send = Instance.new("TextButton")
	send.Size = UDim2.new(0,58,0,32); send.Position = UDim2.new(1,-64,1,-38)
	send.BackgroundColor3 = Color3.fromRGB(120,90,255); send.TextColor3 = Color3.fromRGB(255,255,255)
	send.Font = Enum.Font.GothamBold; send.TextSize = 12; send.Text = "SEND"; send.Parent = win
	do local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=send end

	-- drag by header
	do
		local dragging, dragStart, startPos
		head.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true dragStart=i.Position startPos=win.Position end end)
		UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-dragStart win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
		UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
	end

	local function notifyLocal(t, m)
		pcall(function() StarterGui:SetCore("SendNotification", { Title=t, Text=m, Duration=6 }) end)
	end

	-- ---- render ----
	local cache = {}
	local ROLES = { ["chloeflash9563"]={"OWNER","#ffd35a"}, ["real_revvybxnned11"]={"DEV","#5ad1ff"}, ["hvdkssl25"]={"HEAD MOD","#ff9d5a"}, ["bruckner_tempest"]={"MOD","#ff5c5c"}, ["babbage_sparse"]={"MOD","#ff5c5c"} }
	local function tierChip(m)
		local r = ROLES[string.lower(tostring(m.u or ""))]
		if r then return '<font color="'..r[2]..'">['..r[1]..']</font>' end
		if m.md then return '<font color="#ff5c5c">[MOD]</font>' end
		local t = string.upper(tostring(m.t or "FREE"))
		if t == "FREE" then return '<font color="#9a96b0">[FREE]</font>' end
		return '<font color="#ffc85a">['..esc(t)..']</font>'
	end
	local function render()
		for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for i,m in ipairs(cache) do
			if type(m)=="table" then
				local row = Instance.new("Frame")
				row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-6,0,36)
				row.AutomaticSize = Enum.AutomaticSize.Y; row.LayoutOrder = i; row.Parent = scroll
				local av = Instance.new("ImageLabel")
				av.Size = UDim2.new(0,26,0,26); av.Position = UDim2.new(0,0,0,2)
				av.BackgroundColor3 = Color3.fromRGB(40,38,56); av.Image = "rbxthumb://type=AvatarHeadShot&id="..tostring(tonumber(m.id) or 1).."&w=48&h=48"
				av.Parent = row
				do local c2=Instance.new("UICorner") c2.CornerRadius=UDim.new(1,0) c2.Parent=av end
				local nm = Instance.new("TextLabel")
				nm.Size = UDim2.new(1,-34,0,14); nm.Position = UDim2.new(0,32,0,0)
				nm.BackgroundTransparency = 1; nm.RichText = true; nm.Font = Enum.Font.GothamBold; nm.TextSize = 11
				nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextColor3 = Color3.fromRGB(235,232,255)
				nm.Text = esc(m.u or "?").."  "..tierChip(m)..'  <font color="#6f6a88">'..esc(m.g or "")..'</font>'
				nm.Parent = row
				local tx = Instance.new("TextLabel")
				tx.Size = UDim2.new(1,-34,0,0); tx.Position = UDim2.new(0,32,0,15)
				tx.AutomaticSize = Enum.AutomaticSize.Y; tx.BackgroundTransparency = 1
				tx.Font = Enum.Font.Gotham; tx.TextSize = 12; tx.TextWrapped = true
				tx.TextXAlignment = Enum.TextXAlignment.Left
				local rule = scanText(m.m)
				if rule then
					tx.Text = "[removed by AI mod]"; tx.TextColor3 = Color3.fromRGB(255,110,110)
				else
					tx.Text = emojify(tostring(m.m or "")); tx.TextColor3 = Color3.fromRGB(208,204,226)
				end
				tx.Parent = row
				if IS_MOD then
					local del = Instance.new("TextButton")
					del.AnchorPoint = Vector2.new(1,0); del.Position = UDim2.new(1,-2,0,2); del.Size = UDim2.fromOffset(16,16)
					del.BackgroundTransparency = 0.35; del.BackgroundColor3 = Color3.fromRGB(60,26,32)
					del.Font = Enum.Font.GothamBold; del.TextSize = 10; del.Text = "x"; del.TextColor3 = Color3.fromRGB(255,120,120); del.ZIndex = 5; del.Parent = row
					do local cc2 = Instance.new("UICorner") cc2.CornerRadius = UDim.new(0,4) cc2.Parent = del end
					local mkey = tostring(m.ts or 0).."|"..tostring(m.u or "").."|"..tostring(m.m or "")
					del.MouseButton1Click:Connect(function()
						local cur = readKey(KEY) or {}
						local kept = {}
						for _,mm in ipairs(cur) do if type(mm)~="table" or (tostring(mm.ts or 0).."|"..tostring(mm.u or "").."|"..tostring(mm.m or "")) ~= mkey then kept[#kept+1]=mm end end
						writeKey(KEY, kept); cache = kept; render()
					end)
				end
			end
		end
		task.defer(function() pcall(function() scroll.CanvasPosition = Vector2.new(0, math.max(0, lay.AbsoluteContentSize.Y)) end) end)
	end

	btn.MouseButton1Click:Connect(function() win.Visible = not win.Visible; btn.Text = "CHAT"; if win.Visible then render() end end)
	hide.MouseButton1Click:Connect(function() win.Visible = false end)

	-- ---- send ----
	-- ---- staff chat commands (?cmds shows all of them) + relay moderation ----
	local TeleS = game:GetService("TeleportService")
	local Light = game:GetService("Lighting")
	local function resolveName(q)
		q = string.lower(tostring(q or "")) if q == "" then return nil end
		local names = {}
		for _,pl in ipairs(Players:GetPlayers()) do names[#names+1] = pl.Name end
		for _,mm in ipairs(cache) do if type(mm)=="table" and mm.u then names[#names+1] = tostring(mm.u) end end
		for _,n in ipairs(names) do if string.lower(n) == q then return n end end
		for _,n in ipairs(names) do if string.lower(n):sub(1,#q) == q then return n end end
		return q
	end
	local function setState2(fn)
		local ms = readKey(MKEY) or {}
		if type(ms.mu) ~= "table" then ms.mu = {} end
		if type(ms.ne) ~= "table" then ms.ne = {} end
		if type(ms.bw) ~= "table" then ms.bw = {} end
		if type(ms.tt) ~= "table" then ms.tt = {} end
		ms.sl = tonumber(ms.sl) or 0
		ms.lk = tonumber(ms.lk) or 0
		fn(ms)
		writeKey(MKEY, ms)
		MODSTATE = { mu=ms.mu, ne=ms.ne, sl=ms.sl, lk=ms.lk, bw=ms.bw, tt=ms.tt }
		pcall(function() _G.__DreamTitleOv = ms.tt end)
	end
	local function makeListWin(titleTxt)
		local w = Instance.new("Frame")
		w.Size = UDim2.new(0,370,0,430); w.Position = UDim2.new(0.5,-185,0.5,-215)
		w.BackgroundColor3 = Color3.fromRGB(22,20,32); w.Visible = false; w.Active = true; w.ZIndex = 30; w.Parent = gui
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,10) c.Parent = w
		local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(120,90,255) st.Thickness = 1 st.Parent = w
		local h = Instance.new("TextLabel") h.Size = UDim2.new(1,-34,0,32) h.BackgroundTransparency = 1 h.Font = Enum.Font.GothamBold h.TextSize = 13 h.TextXAlignment = Enum.TextXAlignment.Left h.Text = "   "..titleTxt h.TextColor3 = Color3.fromRGB(235,232,255) h.ZIndex = 31 h.Parent = w
		local xb = Instance.new("TextButton") xb.Size = UDim2.new(0,26,0,26) xb.Position = UDim2.new(1,-30,0,3) xb.BackgroundTransparency = 1 xb.Font = Enum.Font.GothamBold xb.TextSize = 16 xb.Text = "x" xb.TextColor3 = Color3.fromRGB(200,196,220) xb.ZIndex = 31 xb.Parent = w
		xb.MouseButton1Click:Connect(function() w.Visible = false end)
		local sc = Instance.new("ScrollingFrame") sc.Size = UDim2.new(1,-12,1,-40) sc.Position = UDim2.new(0,6,0,34) sc.BackgroundTransparency = 1 sc.BorderSizePixel = 0 sc.ScrollBarThickness = 4 sc.AutomaticCanvasSize = Enum.AutomaticSize.Y sc.CanvasSize = UDim2.new(0,0,0,0) sc.ZIndex = 31 sc.Parent = w
		local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0,4) ll.SortOrder = Enum.SortOrder.LayoutOrder ll.Parent = sc
		return { win=w, set=function(lines)
			for _,c2 in ipairs(sc:GetChildren()) do if c2:IsA("TextLabel") then c2:Destroy() end end
			for i,ln in ipairs(lines) do
				local t = Instance.new("TextLabel") t.LayoutOrder = i t.Size = UDim2.new(1,-8,0,0) t.AutomaticSize = Enum.AutomaticSize.Y t.BackgroundTransparency = 1 t.Font = Enum.Font.Gotham t.TextSize = 11 t.TextWrapped = true t.RichText = true t.TextXAlignment = Enum.TextXAlignment.Left t.TextColor3 = Color3.fromRGB(208,204,226) t.Text = ln t.ZIndex = 32 t.Parent = sc
			end
		end }
	end
	local cmdsWin, warnsWin
	local savedPos, spdOrig, jmpOrig = nil, nil, nil
	local flyOn, clipOff, invisOn, brightOn = false, false, false, false
	local lightSaved = nil
	local function myRoot() local c = me.Character return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")) end
	local function myHum() local c = me.Character return c and c:FindFirstChildOfClass("Humanoid") end
	local function findPlr(nm) nm = string.lower(tostring(nm or "")) for _,pl in ipairs(Players:GetPlayers()) do if string.lower(pl.Name) == nm or string.lower(pl.DisplayName or "") == nm then return pl end end end
	local function tpToPlr(pl)
		local c = pl and pl.Character; local tr = c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart"))
		local mr = myRoot(); if not (tr and mr) then return false end
		savedPos = mr.CFrame
		pcall(function() mr.AssemblyLinearVelocity = Vector3.zero end)
		mr.CFrame = tr.CFrame * CFrame.new(0,0,-5)
		return true
	end
	local function needPlr(rest) local who = tostring(rest or ""):match("^(%S+)") if not who then return nil, "Give a username." end local nm = resolveName(who) return findPlr(nm), nm end
	local CMDS
	CMDS = {
		-- ============ MODERATION ============
		warn = { "user msg", "red warning popup on their screen + logged in the tracker", function(rest)
			local who, msg = rest:match("^(%S+)%s+(.+)$") if not who then return "Use:  ?warn user your message" end
			local nm = resolveName(who) _G.__DreamWarnSend(nm, msg) return "Warned "..nm.."." end },
		warnall = { "msg", "warning popup for EVERY hub user", function(rest)
			if rest == "" then return "Use:  ?warnall message" end _G.__DreamWarnSend("*", rest) return "Warned everyone." end },
		announce = { "msg", "blue announcement popup for every hub user", function(rest)
			if rest == "" then return "Use:  ?announce message" end _G.__DreamWarnSend("*", rest, "a") return "Announced." end },
		dm = { "user msg", "private popup only they see", function(rest)
			local who, msg = rest:match("^(%S+)%s+(.+)$") if not who then return "Use:  ?dm user message" end
			local nm = resolveName(who) _G.__DreamWarnSend(nm, msg, "d") return "DM sent to "..nm.."." end },
		notify = { "user msg", "small corner notification only they see", function(rest)
			local who, msg = rest:match("^(%S+)%s+(.+)$") if not who then return "Use:  ?notify user message" end
			local nm = resolveName(who) _G.__DreamWarnSend(nm, msg, "n") return "Notified "..nm.."." end },
		mute = { "user mins", "block them from live chat (cross-server)", function(rest)
			local who, mins = rest:match("^(%S+)%s*(%d*)$") if not who then return "Use:  ?mute user minutes" end
			local nm = resolveName(who) local m = math.clamp(tonumber(mins) or 5, 1, 1440)
			setState2(function(ms) ms.mu[string.lower(nm)] = os.time() + m*60 end) return "Muted "..nm.." for "..m.." min." end },
		unmute = { "user", "lift a mute early", function(rest)
			local who = rest:match("^(%S+)") if not who then return "Use:  ?unmute user" end
			local nm = resolveName(who) setState2(function(ms) ms.mu[string.lower(nm)] = 0 end) return nm.." unmuted." end },
		noemoji = { "user mins", "their :codes: stop turning into emoji", function(rest)
			local who, mins = rest:match("^(%S+)%s*(%d*)$") if not who then return "Use:  ?noemoji user minutes" end
			local nm = resolveName(who) local m = math.clamp(tonumber(mins) or 5, 1, 1440)
			setState2(function(ms) ms.ne[string.lower(nm)] = os.time() + m*60 end) return "Emojis off for "..nm.." ("..m.." min)." end },
		okemoji = { "user", "give their emojis back", function(rest)
			local who = rest:match("^(%S+)") if not who then return "Use:  ?okemoji user" end
			local nm = resolveName(who) setState2(function(ms) ms.ne[string.lower(nm)] = 0 end) return "Emojis back for "..nm.."." end },
		del = { "user", "delete that user's LAST chat message", function(rest)
			local who = rest:match("^(%S+)") if not who then return "Use:  ?del user" end
			local nm = string.lower(resolveName(who))
			local cur = readKey(KEY) or {}
			for i = #cur, 1, -1 do local mm = cur[i]
				if type(mm)=="table" and string.lower(tostring(mm.u or "")) == nm then table.remove(cur, i) writeKey(KEY, cur) cache = cur render() return "Deleted "..nm.."'s last message." end
			end
			return "No message from "..nm.." in the feed." end },
		delall = { "user", "delete EVERY message that user has in the feed", function(rest)
			local who = rest:match("^(%S+)") if not who then return "Use:  ?delall user" end
			local nm = string.lower(resolveName(who))
			local cur = readKey(KEY) or {}
			local kept, n = {}, 0
			for _,mm in ipairs(cur) do if type(mm)=="table" and string.lower(tostring(mm.u or "")) == nm then n += 1 else kept[#kept+1] = mm end end
			writeKey(KEY, kept) cache = kept render() return "Deleted "..n.." message"..(n==1 and "" or "s").." from "..nm.."." end },
		clearchat = { "", "wipe the whole live chat feed", function()
			writeKey(KEY, {}) cache = {} render() return "Chat cleared." end },
		warns = { "", "open the warning tracker (who has warnings + reasons)", function()
			local l = readKey(LKEY) or {}
			local per, order = {}, {}
			for _,e in ipairs(l) do if type(e)=="table" then
				local k = string.lower(tostring(e.to or "?"))
				if not per[k] then per[k] = { n=0, name=tostring(e.to or "?"), rs={} } order[#order+1] = k end
				per[k].n += 1
				table.insert(per[k].rs, 1, tostring(e.m or "").."  (by "..tostring(e.by or "?")..")")
			end end
			local lines = {}
			for _,k in ipairs(order) do local p2 = per[k]
				lines[#lines+1] = '<font color="#ff9d5a"><b>'..p2.name..'</b></font>   '..p2.n..' warning'..(p2.n==1 and "" or "s")
				for i = 1, math.min(3, #p2.rs) do lines[#lines+1] = "      - "..p2.rs[i] end
			end
			if #lines == 0 then lines = { "No warnings on record." } end
			if not warnsWin then warnsWin = makeListWin("WARNING TRACKER") end
			warnsWin.set(lines) warnsWin.win.Visible = true
			return "Warning tracker opened." end },
		clearwarns = { "user", "remove a user's warnings from the tracker", function(rest)
			local who = rest:match("^(%S+)") if not who then return "Use:  ?clearwarns user" end
			local nm = string.lower(resolveName(who))
			local l = readKey(LKEY) or {}
			local kept, n = {}, 0
			for _,e in ipairs(l) do if type(e)=="table" and string.lower(tostring(e.to or "")) == nm then n += 1 else kept[#kept+1] = e end end
			writeKey(LKEY, kept) return "Removed "..n.." warning"..(n==1 and "" or "s").." for "..nm.."." end },
		slowmode = { "secs", "everyone must wait N seconds between messages", function(rest)
			local n = math.clamp(tonumber(rest:match("%d+")) or 10, 2, 300)
			setState2(function(ms) ms.sl = n end) return "Slowmode: "..n.."s." end },
		slowoff = { "", "turn slowmode off", function() setState2(function(ms) ms.sl = 0 end) return "Slowmode off." end },
		lockchat = { "", "only staff can send in live chat", function() setState2(function(ms) ms.lk = 1 end) return "Chat locked (staff only)." end },
		unlockchat = { "", "unlock live chat for everyone", function() setState2(function(ms) ms.lk = 0 end) return "Chat unlocked." end },
		badword = { "word", "add a word to the AI filter (blocks + auto-reports)", function(rest)
			local w = rest:match("^(%S+)") if not w then return "Use:  ?badword word" end
			setState2(function(ms) ms.bw[#ms.bw+1] = string.lower(w) end) return "Added to the filter." end },
		goodword = { "word", "remove a word from the staff filter", function(rest)
			local w = string.lower(rest:match("^(%S+)") or "") if w == "" then return "Use:  ?goodword word" end
			setState2(function(ms) for i = #ms.bw, 1, -1 do if string.lower(tostring(ms.bw[i])) == w then table.remove(ms.bw, i) end end end) return "Removed from the filter." end },
		settitle = { "user text", "override someone's overhead title (hub users see it)", function(rest)
			local who, txt2 = rest:match("^(%S+)%s+(.+)$") if not who then return "Use:  ?settitle user New Title" end
			local nm = resolveName(who) setState2(function(ms) ms.tt[string.lower(nm)] = string.sub(txt2, 1, 40) end) return "Title set for "..nm.."." end },
		cleartitle = { "user", "put their normal overhead title back", function(rest)
			local who = rest:match("^(%S+)") if not who then return "Use:  ?cleartitle user" end
			local nm = resolveName(who) setState2(function(ms) ms.tt[string.lower(nm)] = nil end) return "Title reset for "..nm.."." end },
		-- ============ INFO ============
		cmds = { "", "show every staff command", function()
			local names = {}
			for k in pairs(CMDS) do names[#names+1] = k end
			table.sort(names)
			local lines = { #names.." staff commands. Type them in the chat box:", "" }
			for _,k in ipairs(names) do local e2 = CMDS[k]
				lines[#lines+1] = '<font color="#a78bfa"><b>?'..k..(e2[1] ~= "" and (" "..e2[1]) or "")..'</b></font>   '..e2[2]
			end
			if not cmdsWin then cmdsWin = makeListWin("STAFF COMMANDS") end
			cmdsWin.set(lines) cmdsWin.win.Visible = true
			return "Command list opened." end },
		who = { "user", "profile info about a player in your server", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end
			return pl.DisplayName.."  (@"..pl.Name..")  id "..pl.UserId.."  |  account "..pl.AccountAge.." days old" end },
		id = { "user", "their UserId", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end return pl.Name.." = "..pl.UserId end },
		age = { "user", "their account age in days", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end return pl.Name.." is "..pl.AccountAge.." days old" end },
		list = { "", "who is in this server", function()
			local t = {}
			for _,pl in ipairs(Players:GetPlayers()) do t[#t+1] = pl.Name end
			return #t.." here: "..table.concat(t, ", ", 1, math.min(#t, 10))..(#t > 10 and " ..." or "") end },
		staff = { "", "which staff are in this server", function()
			local t = {}
			for _,pl in ipairs(Players:GetPlayers()) do if MODS[string.lower(pl.Name)] or MODS[string.lower(pl.DisplayName or "")] then t[#t+1] = pl.Name end end
			return #t == 0 and "No other staff here." or ("Staff here: "..table.concat(t, ", ")) end },
		online = { "", "how many different people talked in chat recently", function()
			local seen, n = {}, 0
			for _,mm in ipairs(cache) do if type(mm)=="table" and mm.u and not seen[mm.u] then seen[mm.u] = true n += 1 end end
			return n.." different hub user"..(n==1 and "" or "s").." in the recent feed." end },
		server = { "", "place + job id of this server", function()
			pcall(function() setclipboard(tostring(game.JobId)) end) return "Place "..game.PlaceId.."  |  JobId copied to clipboard." end },
		ping = { "", "relay round-trip time", function()
			local t0 = tick() readKey(KEY) return "Relay ping: "..math.floor((tick()-t0)*1000).."ms" end },
		time = { "", "current UTC time", function() return os.date("!%H:%M:%S UTC  (%d %b)") end },
		ver = { "", "game + your plan", function() return GAME.."  |  plan "..TIER end },
		-- ============ SELF / UTILITY ============
		tp = { "user", "teleport to a player in your server", function(rest)
			local pl, nm = needPlr(rest) if not pl then return "They aren't in this server." end
			return tpToPlr(pl) and ("Teleported to "..pl.Name..".  ?back to return.") or "No character to teleport to." end },
		rtp = { "", "teleport to a RANDOM player", function()
			local opts = {}
			for _,pl in ipairs(Players:GetPlayers()) do if pl ~= me and pl.Character then opts[#opts+1] = pl end end
			if #opts == 0 then return "Nobody else here." end
			local pl = opts[math.random(#opts)]
			return tpToPlr(pl) and ("Teleported to "..pl.Name..".  ?back to return.") or "Couldn't reach them." end },
		back = { "", "return to where you were before ?tp / ?rtp", function()
			local mr = myRoot() if not (savedPos and mr) then return "No saved spot." end
			pcall(function() mr.AssemblyLinearVelocity = Vector3.zero end) mr.CFrame = savedPos return "Back." end },
		view = { "user", "spectate a player", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end
			local c = pl.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
			local cam = workspace.CurrentCamera
			if cam and h then cam.CameraSubject = h return "Viewing "..pl.Name..".  ?unview to stop." end
			local pt = c and c:FindFirstChildWhichIsA("BasePart")
			if cam and pt then cam.CameraSubject = pt return "Viewing "..pl.Name..".  ?unview to stop." end
			return "Their character isn't loaded for you." end },
		unview = { "", "camera back on you", function()
			local cam = workspace.CurrentCamera local h = myHum()
			if cam then pcall(function() cam.CameraSubject = h end) end return "Camera back on you." end },
		speed = { "n", "set your WalkSpeed", function(rest)
			local n = tonumber(rest:match("%d+%.?%d*")) if not n then return "Use:  ?speed 32" end
			local h = myHum() if not h then return "No humanoid." end
			if spdOrig == nil then spdOrig = h.WalkSpeed end
			h.WalkSpeed = math.clamp(n, 1, 500) return "Speed "..h.WalkSpeed.."." end },
		speedreset = { "", "back to normal speed", function()
			local h = myHum() if h and spdOrig then h.WalkSpeed = spdOrig end return "Speed reset." end },
		jump = { "n", "set your JumpPower", function(rest)
			local n = tonumber(rest:match("%d+%.?%d*")) if not n then return "Use:  ?jump 80" end
			local h = myHum() if not h then return "No humanoid." end
			if jmpOrig == nil then jmpOrig = h.JumpPower end
			pcall(function() h.UseJumpPower = true end) h.JumpPower = math.clamp(n, 1, 500) return "Jump "..h.JumpPower.."." end },
		jumpreset = { "", "back to normal jump", function()
			local h = myHum() if h and jmpOrig then h.JumpPower = jmpOrig end return "Jump reset." end },
		fly = { "", "simple fly (WASD + Space up / Ctrl down)", function()
			if flyOn then return "Already flying - ?unfly to stop." end
			flyOn = true
			task.spawn(function()
				while flyOn do
					local r = myRoot()
					if r then pcall(function()
						local cam = workspace.CurrentCamera
						local v = Vector3.zero
						if cam then
							if UIS:IsKeyDown(Enum.KeyCode.W) then v += cam.CFrame.LookVector end
							if UIS:IsKeyDown(Enum.KeyCode.S) then v -= cam.CFrame.LookVector end
							if UIS:IsKeyDown(Enum.KeyCode.D) then v += cam.CFrame.RightVector end
							if UIS:IsKeyDown(Enum.KeyCode.A) then v -= cam.CFrame.RightVector end
							if UIS:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.new(0,1,0) end
							if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v -= Vector3.new(0,1,0) end
						end
						r.AssemblyLinearVelocity = (v.Magnitude > 0 and v.Unit * 60 or Vector3.zero)
					end) end
					task.wait()
				end
				local r = myRoot() if r then pcall(function() r.AssemblyLinearVelocity = Vector3.zero end) end
			end)
			return "Fly ON.  WASD + Space / Ctrl.  ?unfly to stop." end },
		unfly = { "", "stop flying", function() flyOn = false return "Fly off." end },
		noclip = { "", "walk through walls", function()
			if clipOff then return "Noclip already on - ?clip to stop." end
			clipOff = true
			task.spawn(function()
				while clipOff do
					local c = me.Character
					if c then pcall(function() for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end end end) end
					task.wait(0.1)
				end
			end)
			return "Noclip ON.  ?clip to stop." end },
		clip = { "", "collisions back on", function()
			clipOff = false
			local c = me.Character
			if c then pcall(function() for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide = true end end end) end
			return "Noclip off." end },
		invis = { "", "your character goes see-through ON YOUR SCREEN only", function()
			if invisOn then return "Already invisible - ?visible" end
			invisOn = true
			task.spawn(function()
				while invisOn do
					local c = me.Character
					if c then pcall(function() for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0.85 end end end) end
					task.wait(0.25)
				end
				local c = me.Character
				if c then pcall(function() for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end end) end
			end)
			return "Invisible (your screen only - others still see you)." end },
		visible = { "", "stop being see-through", function() invisOn = false return "Visible again." end },
		unstuck = { "", "nudge yourself up 8 studs", function()
			local mr = myRoot() if not mr then return "No character." end
			pcall(function() mr.AssemblyLinearVelocity = Vector3.zero end) mr.CFrame = mr.CFrame + Vector3.new(0,8,0) return "Nudged up." end },
		sit = { "", "sit down", function() local h = myHum() if h then h.Sit = true end return "Sitting." end },
		reset = { "", "reset your character", function()
			local h = myHum() if h then pcall(function() h.Health = 0 end) end
			pcall(function() me.Character:BreakJoints() end) return "Reset." end },
		rejoin = { "", "rejoin THIS server", function()
			pcall(function() TeleS:TeleportToPlaceInstance(game.PlaceId, game.JobId, me) end) return "Rejoining..." end },
		hop = { "", "jump to a fresh server", function()
			pcall(function() TeleS:Teleport(game.PlaceId, me) end) return "Hopping..." end },
		fov = { "n", "camera field of view (10-120)", function(rest)
			local n = tonumber(rest:match("%d+")) if not n then return "Use:  ?fov 90" end
			pcall(function() workspace.CurrentCamera.FieldOfView = math.clamp(n, 10, 120) end) return "FOV "..math.clamp(n,10,120).."." end },
		fovreset = { "", "normal FOV (70)", function()
			pcall(function() workspace.CurrentCamera.FieldOfView = 70 end) return "FOV reset." end },
		bright = { "", "fullbright (see in the dark)", function()
			if not lightSaved then lightSaved = { b = Light.Brightness, c = Light.ClockTime, f = Light.FogEnd, g = Light.GlobalShadows } end
			pcall(function() Light.Brightness = 2 Light.ClockTime = 14 Light.FogEnd = 1e6 Light.GlobalShadows = false end)
			brightOn = true return "Fullbright ON.  ?unbright to undo." end },
		unbright = { "", "normal lighting", function()
			if lightSaved then pcall(function() Light.Brightness = lightSaved.b Light.ClockTime = lightSaved.c Light.FogEnd = lightSaved.f Light.GlobalShadows = lightSaved.g end) end
			brightOn = false return "Lighting back to normal." end },
		day = { "", "make it daytime (your screen only)", function() pcall(function() Light.ClockTime = 12 end) return "Daytime." end },
		night = { "", "make it night (your screen only)", function() pcall(function() Light.ClockTime = 0 end) return "Night." end },
		copyid = { "user", "copy their UserId", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end
			pcall(function() setclipboard(tostring(pl.UserId)) end) return "Copied "..pl.UserId.."." end },
		copyname = { "user", "copy their exact username", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end
			pcall(function() setclipboard(pl.Name) end) return "Copied @"..pl.Name.."." end },
		copyprofile = { "user", "copy their profile link", function(rest)
			local pl = needPlr(rest) if not pl then return "They aren't in this server." end
			pcall(function() setclipboard("https://www.roblox.com/users/"..pl.UserId.."/profile") end) return "Profile link copied." end },
	}
	local function runCmd(t)
		local cmd, rest = t:match("^%?(%w+)%s*(.*)$")
		cmd = string.lower(tostring(cmd or ""))
		if cmd == "help" then cmd = "cmds" end
		local e = CMDS[cmd]
		if not e then notifyLocal("Staff", "Unknown command - type  ?cmds") return end
		local ok, res = pcall(e[3], rest or "")
		notifyLocal("Staff", ok and tostring(res or "Done.") or "That command hit an error.")
	end
	local lastSend = 0
	local function doSend()
		local txt = tostring(box.Text or ""):gsub("^%s+",""):gsub("%s+$","")
		if txt == "" then return end
		if IS_MOD and txt:sub(1,1) == "?" then box.Text = "" runCmd(txt) return end
		local myLow = string.lower(me.Name)
		local mts = tonumber(MODSTATE.mu[myLow] or MODSTATE.mu[string.lower(me.DisplayName or "")] or 0) or 0
		if mts > os.time() then box.Text = "" notifyLocal("Live Chat","You are muted by staff for another "..math.ceil((mts-os.time())/60).." min.") return end
		if #txt > 120 then txt = string.sub(txt,1,120) end
		if not IS_MOD and (tonumber(MODSTATE.lk) or 0) == 1 then box.Text = "" notifyLocal("Live Chat","Chat is locked by staff right now.") return end
		if (tonumber(MODSTATE.ne[myLow] or 0) or 0) <= os.time() then txt = emojify(txt) end
		local cool = IS_MOD and 2 or math.max(2, tonumber(MODSTATE.sl) or 0)
		if tick()-lastSend < cool then notifyLocal("Live Chat","Slow down a little"..(cool > 2 and ("  (slowmode "..cool.."s)") or "")..".") return end
		lastSend = tick()
		local rule = scanText(txt)
		if rule then
			box.Text = ""
			notifyLocal("AI Mod","Message blocked ("..rule..") and reported to staff.")
			reportMsg(me.Name, me.UserId, txt, rule, "blocked before send")
			return
		end
		box.Text = ""
		local c = readKey(KEY) or {}
		c[#c+1] = { u=me.Name, id=me.UserId, t=TIER, g=GAME, m=txt, ts=os.time(), md=IS_MOD and 1 or nil }
		while #c > 20 do table.remove(c,1) end
		cache = c; writeKey(KEY, c); render()
	end
	send.MouseButton1Click:Connect(doSend)
	box.FocusLost:Connect(function(enter) if enter then doSend() end end)

	-- ---- warn delivery (relay -> popup notification, NOT chat) ----
	_G.__DreamWarnSend = function(target, msg, kind)
		local w = readKey(WKEY) or {}
		w[#w+1] = { to=tostring(target), m=tostring(msg), by=me.Name, ts=os.time(), k=kind }
		while #w > 10 do table.remove(w,1) end
		writeKey(WKEY, w)
		if kind == nil or kind == "w" then   -- real warnings land in the tracker
			local l = readKey(LKEY) or {}
			l[#l+1] = { to=tostring(target), m=tostring(msg), by=me.Name, ts=os.time() }
			while #l > 40 do table.remove(l,1) end
			writeKey(LKEY, l)
		end
		return true
	end
	local boot = os.time()
	local shownW = {}
	local function handleWarn(x)
		if type(x) ~= "table" then return end
		local id = tostring(x.ts or 0)..string.lower(tostring(x.to or ""))..tostring(x.k or "w")
		if shownW[id] then return end
		shownW[id] = true
		local tgt = string.lower(tostring(x.to or ""))
		if tgt ~= "*" and tgt ~= string.lower(me.Name) then return end
		if (tonumber(x.ts) or 0) < boot - 60 then return end  -- ignore anything from before this session
		local kind = tostring(x.k or "w")
		local head1, cAcc, cBg, nTitle
		if kind == "a" then head1="ANNOUNCEMENT  ("..tostring(x.by or "staff")..")" cAcc=Color3.fromRGB(90,160,255) cBg=Color3.fromRGB(14,20,32) nTitle="ANNOUNCEMENT"
		elseif kind == "d" then head1="DM FROM STAFF  ("..tostring(x.by or "?")..")" cAcc=Color3.fromRGB(180,150,255) cBg=Color3.fromRGB(22,18,34) nTitle="Staff DM"
		elseif kind == "n" then notifyLocal("Message from staff", tostring(x.m)) return
		else head1="WARNING FROM STAFF  ("..tostring(x.by or "?")..")" cAcc=Color3.fromRGB(255,80,80) cBg=Color3.fromRGB(30,16,18) nTitle="ADMIN WARNING" end
		notifyLocal(nTitle, tostring(x.m))
		pcall(function()
			local card = Instance.new("Frame")
			card.Size = UDim2.new(0,380,0,110); card.Position = UDim2.new(0.5,-190,0.22,0)
			card.BackgroundColor3 = cBg; card.Parent = gui
			local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,12) c.Parent=card
			local st=Instance.new("UIStroke") st.Color=cAcc st.Thickness=2 st.Parent=card
			local t1=Instance.new("TextLabel") t1.Size=UDim2.new(1,-20,0,30) t1.Position=UDim2.new(0,10,0,10)
			t1.BackgroundTransparency=1 t1.Font=Enum.Font.GothamBold t1.TextSize=16
			t1.TextColor3=cAcc t1.Text=head1 t1.Parent=card
			local t2=Instance.new("TextLabel") t2.Size=UDim2.new(1,-20,0,56) t2.Position=UDim2.new(0,10,0,44)
			t2.BackgroundTransparency=1 t2.Font=Enum.Font.Gotham t2.TextSize=13 t2.TextWrapped=true
			t2.TextColor3=Color3.fromRGB(235,220,222) t2.Text=tostring(x.m) t2.Parent=card
			task.delay(7, function() pcall(function() card:Destroy() end) end)
		end)
	end

	-- ---- poll loop ----
	local lastJson = ""
	local reported = {}
	while true do
		task.wait(4)
		if not gui.Parent then break end
		local w = readKey(WKEY)
		if w then for _,x in ipairs(w) do handleWarn(x) end end
		local ms = readKey(MKEY)
		if type(ms) == "table" then
			MODSTATE.mu = (type(ms.mu)=="table" and ms.mu) or {}
			MODSTATE.ne = (type(ms.ne)=="table" and ms.ne) or {}
			MODSTATE.sl = tonumber(ms.sl) or 0
			MODSTATE.lk = tonumber(ms.lk) or 0
			MODSTATE.bw = (type(ms.bw)=="table" and ms.bw) or {}
			MODSTATE.tt = (type(ms.tt)=="table" and ms.tt) or {}
			pcall(function() _G.__DreamTitleOv = MODSTATE.tt end)
		end
		local myL = string.lower(me.Name)
		local mts2 = tonumber(MODSTATE.mu[myL] or 0) or 0
		if mts2 > os.time() and mts2 ~= lastMuteNotif then lastMuteNotif = mts2 notifyLocal("Live Chat","A staff member muted you for "..math.ceil((mts2-os.time())/60).." min.") end
		local c = readKey(KEY)
		if c then
			local j = ""
			pcall(function() j = HttpService:JSONEncode(c) end)
			if j ~= lastJson then
				lastJson = j
				cache = c
				if win.Visible then render() else btn.Text = "CHAT  •" end
				-- mods auto-report NEW flagged messages that slipped into the feed
				if IS_MOD then
					for _,m in ipairs(c) do
						if type(m)=="table" and (tonumber(m.ts) or 0) >= boot then
							local rid = tostring(m.ts or 0)..tostring(m.u or "")
							if not reported[rid] then
								local rule = scanText(m.m)
								if rule then reported[rid]=true reportMsg(m.u, m.id, m.m, rule, "seen in feed") end
							end
						end
					end
				end
			end
		end
	end
end)
-- ═══ END LIVE CHAT ═══



_G.VX_HUB_READY = false

-- (Removed the duplicate VX_DreamCircle button — the GUI's own logo toggle button, which uses the Dream logo
--  image LOGO_ID = 82151574125055, is the single one now.)

-- ===================== SHARED STATE (the GUI flips these; the modules read them) =====================
local BlockFlags = { Dash = false, M1 = false, Abilities = false, CameraFollow = true }
local BFApi    -- forward-declared: Auto Black Flash control API (assigned in its module below)
local ChainApi -- forward-declared: BF Chain control API (assigned in its module below)

-- ============================================================
-- MODULE: AUTO BLACK FLASH  (the user's AutoBlackFlash.lua, VERBATIM)
-- ============================================================
do
	-- ═══ YOUR EXACT Black Flash script (the correct one) ═══ instant press, hooks the Humanoid's animator,
	-- presses 3 after the trigger anim's delay. Wrapped to expose the API the GUI uses + hook BOTH rigs
	-- (LP.Character AND workspace.Characters[you], since JJS plays combat anims on either).
	local Players = game:GetService("Players")
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local player = Players.LocalPlayer

	local AnimationTriggers = {
		-- 100962226150441 (Divergent Fist) DELIBERATELY NOT LISTED. It is Itadori's AUTOMATIC 4th M1, not a
		-- Black Flash windup. Having it here made the engine schedule a key-3 press 0.19s into an animation
		-- already committed to Divergent Fist, so the flash could never come out - that is exactly "3 M1s
		-- and then it just does Divergent Fist". It also BURNED a swing count, pushing every later count
		-- out of phase with the real combo, which is why the failure looked random.
		["rbxassetid://95852624447551"]  = 0.19,
		["rbxassetid://74145636023952"]  = 0.19,
		["rbxassetid://72475960800126"]  = 0.20,
		["rbxassetid://123171106092050"] = 0.19,
	}

	local enabled = false   -- the GUI toggle turns it on
	local offset = 0        -- BF Timing slider

	local function pressKey(keyCode)
		-- mark this as our own injected press so other key-3 features (e.g. Auto Earthquake) don't treat the
		-- Black Flash press as a real player tap and cross-trigger.
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[keyCode] = tick() + 0.2
		VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		task.wait(0.09)   -- hold the key a touch (JJS eats instant taps for abilities); this is what makes 3 register
		VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
	end

	local function normalizeAnimationId(id)
		id = tostring(id or "")
		if id == "" then return "" end
		if id:match("^%d+$") then return "rbxassetid://" .. id end
		return id
	end

	-- UNIVERSAL M1 DETECTION: fire on a known BF windup id OR on ANY Action-priority attack anim that plays
	-- right after your click. This works on every character (no need for the exact anim id to be listed) and
	-- the click gate (your mouse poll updates _G.VX_LAST_CLICK) stops random anims from firing it.
	-- BF After (M1s): only flash after _G.VX_BF_AFTER swings (the dropdown), so you pick how many M1s first.
	local lastFire, swingCount, lastSwing = 0, 0, 0
	local lastAnimId, lastAnimAt = nil, 0   -- per-id dedupe: the same swing arriving from both hooked rigs
	-- A chain that wants to flash on THIS swing resets the counter first; otherwise it inherits however many
	-- swings were already counted and appears to "need 2 or 3 M1s" even with BF After (M1s) set to 1.
	_G.VX_BF_RESETCOUNT = function() swingCount = 0; lastSwing = 0 end
	local function onAnim(track)
		if not enabled then return end
		-- ═══ "I TURNED M1 BLACK FLASH OFF AND IT STILL FLASHES ON MY M1s" ═══
		-- The dash modes ARM this engine for their own flash beat (_G.VX_BFAPI_SET(true)) and hand it back a
		-- second later. During that window the engine is indistinguishable from M1 Black Flash being switched
		-- on, so every ordinary M1 you threw in that second also flashed - with the mode dropdown showing
		-- Side Dash and the M1 BF toggle showing off. A BORROW is now single-shot: it may produce exactly ONE
		-- flash and then disarms itself, so it can never bleed into your normal swings.
		if _G.VX_BF_BORROWED and (_G.VX_BF_BORROW_USED or 0) > 0 then return end
		local ok, id = pcall(function() return track.Animation.AnimationId end)
		if not ok then return end
		local delayTime = AnimationTriggers[normalizeAnimationId(id)]
		-- ═══ WHY THIS ONLY EVER WORKED ON THE VESSEL ═══ Every id in AnimationTriggers is an ITADORI move
		-- (Black Flash 1, Black Flash 2, Focus Strike, Straight Hit). Any other character had no entry, so it
		-- could only reach the priority fallback below - and a swing whose track is not authored at an Action
		-- tier falls straight through to `return` with no flash. That is "M1 Black Flash only works on Vessel".
		-- _G.VX_M1_IDS already holds the captured M1 ids for ALL 20 characters (Gojo's included) and this engine
		-- never looked at it. Consulting it makes a known M1 on ANY character a windup, with no reliance on how
		-- that character's animation happens to be prioritised.
		if not delayTime then
			local nid = tostring(id):match("%d+")
			if nid and _G.VX_M1_IDS and _G.VX_M1_IDS[nid] and tick() - (_G.VX_LAST_CLICK or 0) < 0.5 then
				delayTime = 0.19
			end
		end
		if not delayTime then
			local pr = track.Priority
			local isAction = pr == Enum.AnimationPriority.Action or pr == Enum.AnimationPriority.Action2 or pr == Enum.AnimationPriority.Action3 or pr == Enum.AnimationPriority.Action4
			local clickedRecently = tick() - (_G.VX_LAST_CLICK or 0) < 0.5
            if isAction and clickedRecently then delayTime = 0.19 end
		end
		if delayTime then
			-- SAME SWING ON BOTH RIGS. hookAll connects to LP.Character AND workspace.Characters[you], so one
			-- swing can arrive twice; the 0.25s global debounce below misses it whenever the two rigs report
			-- further apart than that, and the swing counts twice. Dedupe on the id as well.
			local nid = normalizeAnimationId(id)
			if lastAnimId == nid and tick() - lastAnimAt < 0.45 then return end
			lastAnimId, lastAnimAt = nid, tick()
			if tick() - lastFire < 0.25 then return end   -- one count per swing
			lastFire = tick()
			if tick() - lastSwing > 1.2 then swingCount = 0 end   -- new combo. 1.2 not 2.5: JJS drops a combo at ~1.2s, so a 2.5s window kept counting into a combo the game had already reset and the press landed on the wrong swing index
			lastSwing = tick()
			swingCount = swingCount + 1
			local need = tonumber(_G.VX_BF_AFTER) or 1
			if swingCount < need then return end   -- wait until your chosen number of M1s
			swingCount = 0
			_G.VX_BF_LAST_FIRE = tick(); _G.VX_BF_LASTMSG = "flash fired (M1 tap + key 3)"
			-- a borrowed arm is spent by this flash; nothing else may ride it
			if _G.VX_BF_BORROWED then _G.VX_BF_BORROW_USED = (_G.VX_BF_BORROW_USED or 0) + 1 end
			if _G.VX_BF_DEBUG then pcall(function() print(string.format("[BF] windup id=%s  ->  firing flash (M1 tap + key 3) in %.2fs", tostring(id), math.max(0, delayTime + offset))) end) end
			task.delay(math.max(0, delayTime + offset), function()
				if not enabled then return end
				-- Black Flash lands on a PERFECTLY-TIMED input on the M1 windup. Cover both ways it can be bound so it
				-- works no matter your character/keybind: a left-click re-tap at the flash frame -- the real timing
				-- mechanic on most characters -- plus the ability key. A stray unbound key does nothing; the extra
				-- click is harmless mid-M1. This is a synthetic input, NOT a raw remote packet, so it does not kick.
				-- The re-click is the PRIMARY Black Flash trigger on most characters, but it lands an EXTRA in-game M1
			-- per swing, and that extra hit is what stacks the server's knockback on the target ('it flings them').
			-- Default ON so flash reliability is unchanged; the Combat toggle lets you trade it for less launch.
			if _G.VX_BF_RECLICK ~= false then
				-- MARK IT AS OURS. This re-click was the only injected click in the file that did not stamp
				-- _G.VX_SYNTH_CLICK, so the shared poll handed it to every M1 subscriber and the Action-priority
				-- animation it produced could be counted as a SECOND swing. Whether it was depended on where that
				-- animation landed against the 0.25s debounce - which is why the failure was intermittent.
				_G.VX_SYNTH_CLICK = tick() + 0.3
				-- ═══ CLICK THE MIDDLE OF THE SCREEN, NOT (0,0) ═══ This was sending the re-click at the
					-- top-left CORNER of the viewport. Every other injected click in this file uses the viewport
					-- centre, and for good reason: a click at (0,0) lands on empty GUI space, so the game does not
					-- register an attack, no swing animation plays, and there is nothing for the flash to land on.
					pcall(function()
						local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
						local cx, cy = (vp and vp.X / 2) or 400, (vp and vp.Y / 2) or 300
						VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
						task.wait(0.02)
						VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
					end)
			end
				pressKey(Enum.KeyCode.Three)
			end)
		end
	end

	-- hook every animator your body can have (both rigs); re-hook after respawn/character swap
	local hooked = setmetatable({}, { __mode = "k" })
	local function hookAll()
		local bodies = {}
		if player.Character then bodies[#bodies+1] = player.Character end
		local chs = workspace:FindFirstChild("Characters")
		local resolved = chs and chs:FindFirstChild(player.Name)
		if resolved and resolved ~= player.Character then bodies[#bodies+1] = resolved end
		for _, char in ipairs(bodies) do
			local hum = char:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			if animator and not hooked[animator] then hooked[animator] = animator.AnimationPlayed:Connect(onAnim) end
		end
	end
	task.spawn(function() while true do pcall(hookAll); task.wait(0.5) end end)
	local function reconnect() hooked = setmetatable({}, { __mode = "k" }); pcall(hookAll); return true end

	BFApi = {
		SetEnabled = function(v) enabled = v == true; _G.VX_BFAPI_ON = enabled end,   -- exposed so VXBF2 knows the real flash engine is live
		IsEnabled = function() return enabled end,
		SetCooldown = function() end,
		SetTimingOffset = function(v) if type(v) == "number" then offset = v end end,
		SetDebugUnknownAnimations = function() end,
		AddTrigger = function(animationId, delayTime) if type(delayTime) ~= "number" then return false end AnimationTriggers[normalizeAnimationId(animationId)] = delayTime return true end,
		RemoveTrigger = function(animationId) AnimationTriggers[normalizeAnimationId(animationId)] = nil end,
		Reconnect = reconnect,
		Status = function() return { enabled = enabled } end,
	}
	_G.VX_BFAPI_SET = BFApi.SetEnabled   -- lets VXBF2's dash modes re-arm the flash engine

end

-- ============================================================
-- MODULE: AUTO BF CHAIN  (ULTIMATE BACK-LOCK BF CHAIN; standalone GUI stripped)
-- ============================================================
do
	local ContextActionService = game:GetService("ContextActionService")
	local VirtualInputManager  = game:GetService("VirtualInputManager")
	local Players              = game:GetService("Players")
	local RunService           = game:GetService("RunService")
	local LocalPlayer          = Players.LocalPlayer
	local Camera               = workspace.CurrentCamera

	local ScriptEnabled = false
	-- shared back-lock state: overlapping chain hits must NOT each snapshot the already-frozen
	-- (0/0/false) humanoid values, or you get left permanently stuck. Snapshot the REAL pre-lock
	-- values ONCE (first hit), and only restore when the LAST overlapping loop finishes.
	local lockActive = false
	local lastApproach = 0  -- the jump/dash flourish must fire ONLY on the first hit of a chain; doing it every chained hit breaks the chain (dash knocks you off / airborne jump kills the flash)
	-- AUTO FEINT (two modes):
	--   "BF" = Feint Black Flash: after feintBFStop black flashes, press R (feint) then stop.
	--   "M1" = Feint M1: after feintM1Count of YOUR M1s, press R (feint) then a chosen move key (1-4).
	local feintMode = "Off"          -- "Off" / "BF" / "M1" / "Moves"
	local feintBFStop = 2            -- Mode A: stop after this many black flashes
	local feintM1Count = 2           -- Mode B: press R after this many of your M1s
	local feintMove = 1              -- Mode B: which move (1-4) to press after the R feint
	local bfCount, lastBF = 0, 0
	local bfSuppressUntil = 0        -- Mode A: after the feint R, HARD-STOP the chain for a window (this is the 'it must stop' fix)
	local feintMovesOn = false       -- separate on/off for the abilities feint (1/2/3/4 -> R)
	local m1FeintCount, lastM1Feint = 0, 0
	local lastM1 = 0      -- M1 Black Flash: debounce so a fast M1 burst only starts the chain once per click
	local burstUntil = 0  -- self-driving modes (M1 Black Flash / Back Dash / Auto Counter) run the PROVEN teleport chain even if the master "Auto Chain" toggle is off, for a short burst after each trigger
	local runChain        -- forward-declared: fires the proven teleport black-flash chain (doBackstab), optionally snapping to a specific attacker first (Auto Counter)
	local fireFlashInPlace
	local m1bfArmed = 0
	local function vxMarkKey(kc) _G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[kc] = tick() + 0.5 end
	local function pressR() _G.VX_INJECT_UNTIL = tick() + 0.35; vxMarkKey(Enum.KeyCode.R); pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game); task.wait(0.05); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game) end) end
	local FEINT_MOVE_KEYS = { [1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three, [4] = Enum.KeyCode.Four }
	local function pressKeyTap(kc) _G.VX_INJECT_UNTIL = tick() + 0.35; vxMarkKey(kc); pcall(function() VirtualInputManager:SendKeyEvent(true, kc, false, game); task.wait(0.045); VirtualInputManager:SendKeyEvent(false, kc, false, game) end) end
	local function pressMove(n) local kc = FEINT_MOVE_KEYS[tonumber(n) or 0]; if kc then pressKeyTap(kc) end end
	local savedWS, savedJP, savedAR, bfCollideSaved
	local liveLoops = 0

	local chainTarget = nil   -- LOCKED target for the whole combo/chain: once a hit starts, keep the SAME enemy (no random switching to whoever drifts closer). Cleared when the chain ends.
	local chainTargetT = 0    -- when chainTarget was last set. A lock older than the TTL is ignored, so an ABANDONED Back Dash stage-0 lock can't poison a later combo.
	local Settings = {
		BackDistance    = 1.5,    -- dead-center on the back
		LockRange       = 34,
		LockDuration    = 0.32,   -- firmer back-lock (was 0.22 = 'loses lock halfway'). getBehind smoothing + collision-off make a longer hold safe now.
		PreAttackDelay  = 0.05,
		KeyHoldDuration = 0.09,
		PosLead         = 0.14,   -- lead a MOVING target harder so a runner/dasher's back stays under you
		AbilityKey      = Enum.KeyCode.Three,
		Mode            = "Teleport",  -- how to approach before the flash: Teleport / Jump / Side Dash / Back Dash
	}
	local AnimationTriggers = {
		-- Divergent Fist (100962226150441) removed here too - see the note in the main engine table above.
		["rbxassetid://95852624447551"]  = 0.19,
		["rbxassetid://74145636023952"]  = 0.19,
		["rbxassetid://72475960800126"]  = 0.20,
	}
	local StraightAnimations = { ["rbxassetid://123171106092050"] = true }

	local function getHRP(char)
		return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
	end
	local function getNearestEnemy(maxDist)
		local chs = workspace:FindFirstChild("Characters")
		local myChar = (chs and chs:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character  -- JJS keeps your live body under workspace.Characters; LP.Character can be nil/lagged (that made the whole chain no-op)
		local myHRP = getHRP(myChar)
		if not myHRP then return nil end
		local nearest, nearestDist = nil, maxDist
		local function checkChar(char)
			if not char or char == myChar or char == LocalPlayer.Character or char.Name == LocalPlayer.Name then return end  -- never target your own body
			local tHRP = getHRP(char); if not tHRP then return end
			local hum = char:FindFirstChildOfClass("Humanoid"); if hum and hum.Health <= 0 then return end  -- include a DUMMY (no humanoid, or alive); skip only the dead
			local dist = (myHRP.Position - tHRP.Position).Magnitude
			if dist < nearestDist then nearestDist = dist; nearest = char end
		end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then checkChar(plr.Character) end end
		if chs then for _, m in ipairs(chs:GetChildren()) do if m:IsA("Model") then checkChar(m) end end end  -- JJS enemies/dummies live HERE
		for _, obj in ipairs(workspace:GetChildren()) do if obj:IsA("Model") then checkChar(obj) end end
		return nearest
	end
	local bhCache = { hrp = nil, dir = nil, dirT = 0, spd = 0 }   -- per-target smoothing memory for getBehind
	local function getBehind(targetHRP)  -- behind them, with SMOOTHED math so a ragdolling/knocked-back body can't make the lock spasm
		local tPos = targetHRP.Position
		local okv, lv = pcall(function() return targetHRP.AssemblyLinearVelocity end)
		if bhCache.hrp ~= targetHRP then bhCache.hrp = targetHRP; bhCache.dir = nil; bhCache.spd = 0 end
		-- SMOOTHED SPEED (EMA): a Black-Flashed body's velocity spikes forward, then instantly reverses off a wall.
		-- Chasing the RAW value made the behind-point jump 5 studs back then 10 forward frame-to-frame = the fling.
		-- The EMA tracks real running speed but barely reacts to one-frame ragdoll spikes.
		local rawFlat = (okv and lv) and Vector3.new(lv.X, 0, lv.Z) or Vector3.zero
		bhCache.spd = bhCache.spd + (math.min(rawFlat.Magnitude, 60) - bhCache.spd) * 0.15
		if rawFlat.Magnitude > 1 and bhCache.spd > 1 then
			tPos = tPos + rawFlat.Unit * math.min(bhCache.spd, 30) * Settings.PosLead   -- lead with the SMOOTHED speed, capped
		end
		-- FACING with HITSTUN FALLBACK: in hitstun/ragdoll the LookVector points up/down or spins with the tumble.
		-- When its flat part collapses, reuse the last GOOD facing (cached ~1.5s) instead of a random vertical slice —
		-- this is what keeps you ON their back through the whole Black Flash instead of under/above them.
		local look = targetHRP.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z); local mag = flat.Magnitude
		local dir
		if mag >= 0.35 then dir = flat / mag; bhCache.dir = dir; bhCache.dirT = tick()
		elseif bhCache.dir and tick() - bhCache.dirT < 1.5 then dir = bhCache.dir
		else dir = (mag < 0.01) and Vector3.new(0, 0, -1) or (flat / mag) end
		-- CLEARANCE from the SMOOTHED speed only, small + stable (the old raw-velocity clearance breathed in and out
		-- every frame = the spastic lock the flings came from).
		local clear = math.max(Settings.BackDistance, 2.8) + math.min(bhCache.spd * 0.05, 1.6)
		return tPos - dir * clear, tPos
	end
	local function myCharResolved()  -- JJS keeps your live body under workspace.Characters; LP.Character can lag/differ
		local chs = workspace:FindFirstChild("Characters")
		return (chs and chs:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
	end
	local function jumpNow() pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.03); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
	local dashGen = 0  -- kill switch: the snap bumps this so a leftover approach-dash can NEVER push you off the target's back
	local function clientDash(dir, speed, dur)  -- a REAL client-side velocity dash (the Dash remote alone is validation-only)
		local hrp = getHRP(myCharResolved()); if not hrp then return end
		local cf = hrp.CFrame
		local vmap = { Right = cf.RightVector, Left = -cf.RightVector, Front = cf.LookVector, Back = -cf.LookVector }
		local v = (vmap[dir] or cf.LookVector) * (speed or 55)
		dashGen = dashGen + 1; local g = dashGen
		task.spawn(function()
			local t0 = tick()
			while tick() - t0 < (dur or 0.12) do
				if dashGen ~= g then return end  -- the snap started -> stop pushing instantly
				pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.min(hrp.AssemblyLinearVelocity.Y, 0), v.Z) end)  -- flat (no jump/glide)
				task.wait()
			end
		end)
	end
	-- DASH REMOTE — RESILIENT: the exact captured path (Knit.Knit.Services.MovementService.RE.Dash) is tried first,
	-- but if the game update renamed/moved anything we fall back to searching ReplicatedStorage for ANY RemoteEvent
	-- named "Dash" (cached once found). If NO remote exists at all, we do a real client-side velocity dash instead —
	-- so Side Dash always visibly dashes instead of silently doing nothing.
	local dashRE
	local function findDashRemote()
		if dashRE and dashRE.Parent then return dashRE end
		dashRE = nil
		local RS = game:GetService("ReplicatedStorage")
		pcall(function()
			local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
			local svc = k and k:FindFirstChild("MovementService")
			local re = svc and (svc:FindFirstChild("RE") or svc:FindFirstChild("RemoteEvents") or svc:FindFirstChild("Remotes"))
			dashRE = re and re:FindFirstChild("Dash") or nil
		end)
		if dashRE then return dashRE end
		pcall(function()
			for _, d in ipairs(RS:GetDescendants()) do
				if d:IsA("RemoteEvent") and d.Name == "Dash" then dashRE = d; break end
			end
		end)
		return dashRE
	end
	local function fireDash(dir)  -- fire the REAL JJS dash remote; falls back to a client velocity dash if the remote is gone
		local re = findDashRemote()
		if re then pcall(function() re:FireServer(dir, true) end)
		else clientDash(dir, 55, 0.12) end
	end
	local backDashStage = 0
	local function playAnim(id, prio)
		pcall(function()
			local c = myCharResolved(); local h = c and c:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
			if a then local anim = Instance.new("Animation"); anim.AnimationId = id; local t = a:LoadAnimation(anim); t.Priority = prio or Enum.AnimationPriority.Action2; t:Play(0.05); task.delay(0.6, function() pcall(function() t:Stop() end) end) end
		end)
	end
	-- ═══ USER-CAPTURED combo animation sequences (SimpleSpy movement recordings) ═══ Each mode now plays the REAL
	-- anims from the recordings the user sent: Side Dash BF, Jump BF, and the base M1→Black-Flash. These are the exact
	local COMBO_ANIMS = {
		["Side Dash"]      = { "rbxassetid://95295463826732", "rbxassetid://96489184596023", "rbxassetid://100962226150441", "rbxassetid://120133391090244" },
		["Jump"]           = { "rbxassetid://126572575938378", "rbxassetid://97446412066176", "rbxassetid://100962226150441", "rbxassetid://120133391090244" },
		["M1 Black Flash"] = { "rbxassetid://100962226150441", "rbxassetid://138196552148011", "rbxassetid://120133391090244" },
		["default"]        = { "rbxassetid://100962226150441", "rbxassetid://120133391090244" },
	}
	local function playCombo(mode)
		local seq = COMBO_ANIMS[mode] or COMBO_ANIMS.default
		for _, id in ipairs(seq) do playAnim(id) end
	end
	-- CINEMATIC ORBIT: curve smoothly AROUND the target (no teleport / no snap), easing accel + decel,
	-- always facing them, radius + angle interpolated, re-reading the target's LIVE position each frame so
	-- the arc wraps around them if they move. opts: duration, endRadius, endBehind, extraSweep(rad),
	-- radialBias(push out mid-arc = retreat), yArc(jump arc height).
	local function orbitAround(targetHRP, opts)
		opts = opts or {}
		local dur        = opts.duration or 0.42
		local endRadius  = opts.endRadius or (Settings.BackDistance + 0.5)
		local endBehind  = opts.endBehind ~= false
		local extraSweep = opts.extraSweep or 0
		local radialBias = opts.radialBias or 0
		local yArc       = opts.yArc or 0
		-- endBias (radians): offset the FINAL angle off dead-centre-back. Landing exactly on the spine triggers the
		-- game's back-hit knockdown, which ends the combo; a ~35 deg bias puts you at the SIDE of their back, where
		-- the M1 keeps them standing so the combo can continue.
		local endBias    = opts.endBias or 0
		local myC = myCharResolved()
		local h0 = getHRP(myC); if not (h0 and targetHRP and targetHRP.Parent) then return end
		local tp0 = targetHRP.Position
		local rel0 = Vector3.new(h0.Position.X - tp0.X, 0, h0.Position.Z - tp0.Z)
		local startRadius = rel0.Magnitude; if startRadius < 1.5 then startRadius = 6 end
		if startRadius > 24 then return end                                    -- target too FAR: a giant arc from here is the 'fling across the map' - skip the orbit, the chain still works
		dur = dur + startRadius * 0.006                                        -- a longer path gets a touch more time (constant SPEED, not constant time = no whip)
		local startAngle = math.atan2(rel0.Z, rel0.X)
		local baseY = h0.Position.Y
		local lastPos = h0.Position                                            -- per-frame SPEED CAP: no single frame may move you a huge distance (kills every fling)
		-- ANTI-FLING: pass through the enemy instead of colliding (collisions at orbit speed = physics explosions
		-- that launch you AND them). Restore collision after the arc.
		local savedCollide = {}
		if myC then for _, p in ipairs(myC:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then savedCollide[p] = true; pcall(function() p.CanCollide = false end) end end end
		-- decide the sweep DIRECTION once (stable arc, no mid-flight flip-flop)
		-- ═══ THE "IT DOESN'T GO BEHIND THEIR BACK" BUG ═══ LookVector is the way the target is FACING, so using
		-- it as the landing direction put you at target.Position + look*radius = directly IN FRONT of them,
		-- every time, in every mode that asks for endBehind. Behind is the NEGATIVE look vector. (faceEnemyBack
		-- and the non-orbit fallback both already had the minus sign - only the orbit was missing it.)
		local look0 = targetHRP.CFrame.LookVector
		local flat0 = Vector3.new(look0.X, 0, look0.Z); local mag0 = flat0.Magnitude
		local behind0 = (mag0 < 0.01) and Vector3.new(0, 0, 1) or (-flat0 / mag0)
		local endAngle0 = endBehind and (math.atan2(behind0.Z, behind0.X) + endBias) or startAngle
		local diff0 = ((endAngle0 - startAngle + math.pi) % (2 * math.pi)) - math.pi
		local sweepDir = opts.dir or (diff0 >= 0 and 1 or -1)   -- opts.dir forces LEFT(-1)/RIGHT(1) (Side Dash Assist alternates)
		local t0 = tick()
		local lastT = t0                                                       -- real frame delta for the speed cap below
		while true do
			local h = getHRP(myCharResolved()); if not (h and targetHRP and targetHRP.Parent) then break end
			local a = math.clamp((tick() - t0) / dur, 0, 1)
			local e = a * a * (3 - 2 * a)                                     -- smoothstep = smooth accel + decel
			local tp = targetHRP.Position                                     -- LIVE center -> wraps around them if they move
			local okv, tv = pcall(function() return targetHRP.AssemblyLinearVelocity end)
			if okv and tv and tv.Magnitude > 1 then tp = tp + Vector3.new(tv.X, 0, tv.Z) * 0.1 * e end   -- PREDICT a moving target (lead grows toward the end = lands where they'll BE)
			local endAngle = startAngle
			if endBehind then
				-- Same sign fix as behind0 above: NEGATIVE look vector = behind them. This one is re-evaluated
				-- every frame so the arc keeps tracking their back while they turn.
				local look = targetHRP.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z); local mag = flat.Magnitude
				local bd = (mag < 0.01) and Vector3.new(0, 0, 1) or (-flat / mag)
				endAngle = math.atan2(bd.Z, bd.X) + endBias
			end
			local diff = ((endAngle - startAngle + math.pi) % (2 * math.pi)) - math.pi
			diff = diff + sweepDir * extraSweep                               -- widen the arc in a stable direction (real circling)
			local angle = startAngle + diff * e
			local radius = startRadius + (endRadius - startRadius) * e + radialBias * math.sin(e * math.pi)
			if radius < 4.5 then radius = 4.5 end                             -- never INSIDE their body (that overlap is what launches THEM)
			local y = baseY + (tp.Y - tp0.Y) + yArc * math.sin(e * math.pi)   -- follow their height + optional jump arc
			local pos = Vector3.new(tp.X + math.cos(angle) * radius, y, tp.Z + math.sin(angle) * radius)
			local step = pos - lastPos
			-- FRAMERATE-CORRECT cap (was hardcoded 1/60 = a per-FRAME cap, so high-refresh clients got a 2-4x
			-- faster arc than intended — that is the "it whips/teleports" on a 144/240Hz monitor).
			local nowT = tick(); local fdt = math.clamp(nowT - (lastT or nowT), 1 / 240, 1 / 15); lastT = nowT
			local maxStep = 110 * fdt                                          -- cap ~110 studs/s: fast dash speed, but under the server's movement-check threshold (kick mitigation)
			if step.Magnitude > maxStep then pos = lastPos + step.Unit * maxStep end
			lastPos = pos
			if _G.VX_ACPASS then _G.VX_ACPASS() end
			pcall(function()
				h.CFrame = CFrame.lookAt(pos, Vector3.new(tp.X, pos.Y, tp.Z)) -- always FACE the target
				h.AssemblyLinearVelocity = Vector3.zero                        -- no residual physics = no launch
				h.AssemblyAngularVelocity = Vector3.zero
			end)
			pcall(function()   -- camera aims at them through the arc - LERPED so it's silky, rotation only (zoom untouched)
				local cam = workspace.CurrentCamera
				cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, tp), 0.4)
			end)
			if a >= 1 then break end
			task.wait()
		end
		for p in pairs(savedCollide) do if p.Parent then pcall(function() p.CanCollide = true end) end end   -- restore collisions
		local hEnd = getHRP(myCharResolved())
		if hEnd then pcall(function() hEnd.AssemblyLinearVelocity = Vector3.zero; hEnd.AssemblyAngularVelocity = Vector3.zero end) end  -- clean exit: zero momentum so NOTHING flings
	end
	_G.VX_ORBIT = orbitAround   -- shared: Side Dash Assist uses the same cinematic arc
	local function doApproach(targetHRP, myHRP)  -- PRE-flash movement per mode; the flash + back-lock happens right after (in doBackstab)
		local m = Settings.Mode
		if m == "Side Dash" then                                                                   -- CURVE around them to their back (anime run-around), then flash
			playCombo("Side Dash")
			fireDash("Right")
			task.wait(0.1)   -- let the REAL dash impulse actually move you before the orbit takes over — the orbit's first frame zeroes velocity, which was instantly cancelling the dash (= "side dash does nothing")
			orbitAround(targetHRP, { duration = 0.24, endRadius = math.max(Settings.BackDistance, 3), extraSweep = math.pi * 0.4, endBehind = true })   -- wider, weightier wrap = reads like a real player circling them
		elseif m == "Jump" then                                                                    -- SPRINT to them (real movement, NO teleport) -> JUMP over -> flash lands on the back
			playCombo("Jump")
			local t0 = tick()
			while tick() - t0 < 1.4 do                                                             -- run-up: drive toward them at sprint speed, facing them
				local h = getHRP(myCharResolved()); if not (h and targetHRP.Parent) then break end
				local to = targetHRP.Position - h.Position
				local flat = Vector3.new(to.X, 0, to.Z)
				if flat.Magnitude <= 6.5 then break end                                            -- close enough - time to jump
				local dir = flat.Unit
				if _G.VX_ACPASS then _G.VX_ACPASS() end
				pcall(function()
					h.CFrame = CFrame.lookAt(h.Position, Vector3.new(targetHRP.Position.X, h.Position.Y, targetHRP.Position.Z))
					h.AssemblyLinearVelocity = Vector3.new(dir.X * 34, h.AssemblyLinearVelocity.Y, dir.Z * 34)   -- sprint-speed RUN, real physics, no teleport
				end)
				pcall(function() local cam = workspace.CurrentCamera; cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, targetHRP.Position), 0.4) end)  -- AIM the camera at them through the run-up
				task.wait()
			end
			jumpNow()                                                                              -- real jump...
			task.wait(0.06)
			orbitAround(targetHRP, { duration = 0.22, endRadius = Settings.BackDistance, extraSweep = math.pi * 0.15, endBehind = true, yArc = 7 })   -- ...arc OVER their head to the back
		end  -- "Teleport"/"M1 Black Flash" = no pre-move; "Back Dash" is its own handler below
	end
	local function doBackstab(fromE)
		if fromE then burstUntil = tick() + 1.0 end                    -- a MANUAL E press is ALWAYS a valid trigger (this was the bug: E did nothing unless Auto Chain was already on)
		if not ScriptEnabled and tick() >= burstUntil then return end  -- run when the master chain is on OR during a self-driving burst (E press / M1 / Back Dash / Counter)
		local myChar = myCharResolved()
		local myHRP = getHRP(myChar)
		local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if not (myHRP and hum) or hum.Health <= 0 then if _G.VX_BF_DEBUG then print("[DreamHub BF] no body/dead - myHRP=", myHRP ~= nil) end return end
		local targetChar
		if chainTarget and chainTarget.Parent and getHRP(chainTarget) and tick() - chainTargetT < 4 then   -- STAY locked on the same enemy through the chain. TTL raised 1.5s -> 4s: a Black Flash chain animates LONGER than 1.5s, so the old TTL expired MID-COMBO and the next hit re-picked "nearest" (a passerby) = the lock visibly broke. 4s covers the slowest chain; an abandoned lock still can't poison a later combo.
			local ch = chainTarget:FindFirstChildOfClass("Humanoid")
			if not ch or ch.Health > 0 then targetChar = chainTarget end
		end
		if not targetChar then targetChar = getNearestEnemy(Settings.LockRange) end
		if not targetChar then if _G.VX_BF_DEBUG then print("[DreamHub BF] NO ENEMY within LockRange "..tostring(Settings.LockRange)) end return end
		if _G.VX_BF_DEBUG then print("[DreamHub BF] target="..targetChar.Name.." | snapping behind | ability key="..tostring(Settings.AbilityKey)) end
		chainTarget = targetChar; chainTargetT = tick()   -- lock it (fresh stamp) for the follow-up hits
		local targetHRP = getHRP(targetChar)
		if not targetHRP then return end
		-- APPROACH PRELUDES REMOVED (user: "when I press E it should lock onto the enemy's back like it used to").
		-- The sprint/orbit/jump preludes ran BEFORE the snap and made Jump/Side Dash E-presses feel broken — E now
		-- IMMEDIATELY snap-locks behind the target + aims the camera + presses the flash, for EVERY mode. The mode
		-- only changes the M1-anim behavior (Side Dash left-dash / M1 BF), not the E behavior.
		if not lockActive then
			lockActive = true
			savedWS = hum.WalkSpeed
			savedJP = hum.JumpPower
			savedAR = hum.AutoRotate
		end
		liveLoops = liveLoops + 1
		dashGen = dashGen + 1  -- KILL any still-running approach dash so nothing pushes you off the back after the snap
		-- ANTI-FLING (the PivotTo-vs-physics war): if the behind-point clips even slightly INTO the target's hitbox,
		-- two solid bodies overlap → the engine blasts you out → the snap forces you back in → physics explosion =
		-- launched across the map. So YOUR collision is OFF for the whole snap+lock (shared across stacked locks via
		-- bfCollideSaved; the LAST lock to end restores it).
		bfCollideSaved = bfCollideSaved or {}
		if myChar then for _, p in ipairs(myChar:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then bfCollideSaved[p] = true; pcall(function() p.CanCollide = false end) end
		end end
		local behindPos, targetPos = getBehind(targetHRP)
		if _G.VX_ACPASS then _G.VX_ACPASS() end
		local snapCF = CFrame.lookAt(behindPos, targetPos)
		myHRP.CFrame = snapCF
		pcall(function() myChar:PivotTo(snapCF) end)   -- move the WHOLE model too (some rigs don't follow a bare HRP write) = reliably AT their back
		myHRP.AssemblyLinearVelocity = Vector3.zero
		myHRP.AssemblyAngularVelocity = Vector3.zero
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)  -- ground the state after a jump so the flash (ability) isn't blocked mid-air
		hum.AutoRotate = false
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		task.wait(Settings.PreAttackDelay)
		do
			-- the old downward slam, combined with collision-off, tunneled you into the floor = the fling on every mode.
			local t0 = tick()
			while hum.FloorMaterial == Enum.Material.Air and tick() - t0 < 0.3 do
				pcall(function() myHRP.AssemblyLinearVelocity = Vector3.zero; myHRP.AssemblyAngularVelocity = Vector3.zero end)
				task.wait(0.03)
			end
			pcall(function() myHRP.AssemblyLinearVelocity = Vector3.zero end)
		end
		_G.VX_INJECT_UNTIL = tick() + 0.4; vxMarkKey(Settings.AbilityKey)   -- OUR flash press: Feint Abilities must NOT see this 3 and feint the flash away
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Settings.AbilityKey, false, game)
			task.wait(Settings.KeyHoldDuration)
			VirtualInputManager:SendKeyEvent(false, Settings.AbilityKey, false, game)
		end)
		-- ANTI-FLING: the flash move itself (e.g. Divergent Fist) launches YOU forward past the target. For a
		-- short window after the flash, cap your horizontal speed so the move's shove can't yeet you across the map.
		task.spawn(function()
			local t0 = tick()
			while tick() - t0 < 0.7 do
				local c = myCharResolved(); local r = c and getHRP(c)
				if r then pcall(function()
					local v = r.AssemblyLinearVelocity; local flat = Vector3.new(v.X, 0, v.Z)
					if flat.Magnitude > 38 then local u = flat.Unit * 38; r.AssemblyLinearVelocity = Vector3.new(u.X, math.min(v.Y, 12), u.Z) end
				end) end
				task.wait()
			end
		end)
		local lockEnd = tick() + Settings.LockDuration
		local lockLoop
		lockLoop = RunService.Heartbeat:Connect(function()
			local shouldBreak = false
			if not ScriptEnabled or not myHRP.Parent or hum.Health <= 0 then
				shouldBreak = true
			else
				local par = targetHRP.Parent; local tHum = par and par:FindFirstChildOfClass("Humanoid")
				if not par or (tHum and tHum.Health <= 0) then shouldBreak = true end   -- target died/vanished -> END the chain (re-picking mid-hold snapped you across the map = 'fling')
			end
			if shouldBreak or tick() >= lockEnd then
				lockLoop:Disconnect()
				liveLoops = liveLoops - 1
				if liveLoops <= 0 then
					liveLoops = 0
					lockActive = false
					chainTarget = nil   -- chain fully over -> the NEXT combo re-picks its target fresh
					if hum and hum.Parent then
						hum.AutoRotate = savedAR
						hum.WalkSpeed = savedWS
						hum.JumpPower = savedJP
					end
					if bfCollideSaved then   -- last lock ended -> give your body its collision back
						for p in pairs(bfCollideSaved) do if p.Parent then pcall(function() p.CanCollide = true end) end end
						bfCollideSaved = nil
					end
					end
				return
			end
			behindPos, targetPos = getBehind(targetHRP)
			if _G.VX_ACPASS then _G.VX_ACPASS() end
			local snapCF = CFrame.lookAt(behindPos, targetPos)
			myHRP.CFrame = snapCF
			pcall(function() myChar:PivotTo(snapCF) end)   -- keep the WHOLE model pinned to their back
			myHRP.AssemblyLinearVelocity = Vector3.zero
			myHRP.AssemblyAngularVelocity = Vector3.zero
			-- CAMERA AIM (rotation only): turn the camera to face THEIR BACK so the flash aims true.
			-- We never touch CameraType or camera position, so your ZOOM keeps working (no zoom-in lock).
			-- LERPED (0.5/frame), not hard-set — the hard set left the view one frame behind the body every frame,
			-- which read as "I'm not locked on their back" jitter even when the math had you exactly there.
			pcall(function() Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 0.5) end)
		end)
	end
	local convGuard = 0   -- shared dedupe: the LP.Character hook AND the resolved-model hook can both see one anim — only ONE may convert
	local function setupCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end
		local animator = humanoid:WaitForChild("Animator", 5)
		if not animator then return end
		animator.AnimationPlayed:Connect(function(track)
			local animId = track.Animation and track.Animation.AnimationId
			if not animId then return end
			-- (M1 Black Flash triggers ONLY from the landed-click path now - the anim path double-fired the chain
			-- on top of it: two overlapping snap-holds = the fling.)
			-- (Feint M1 is handled SOLELY by the click path below — R only, no move key. The old anim path here also
			--  pressed a skill 1-4 after R, which is exactly what "overlapped" Yuji's skills. Removed.)
			-- (BF conversion also lives in the SINGLE resolved-model conversion authority below, not here.)
		end)
	end
	if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
	LocalPlayer.CharacterAdded:Connect(setupCharacter)
	-- ═══════════════ SINGLE M1 → BLACK FLASH CONVERSION AUTHORITY ═══════════════
	-- ONE listener, on the RESOLVED model's animator (workspace.Characters[you] — the rig your combat anims
	-- actually play on; LP.Character lags), re-hooked every 0.5s (weak-keyed) so it survives respawn/char-swap.
	-- Handles EVERY approach mode with the FULL per-character M1 database. All the old competing paths (the
	-- LP.Character conversion, fireFlashInPlace, tryM1Flash) are gone — this is the only thing that converts.
	do
		-- shared one-shot flash press (aim camera at nearest, press the ability key = 3)
		local function pressFlash()
			_G.VX_INJECT_UNTIL = tick() + 0.35; vxMarkKey(Settings.AbilityKey)
			pcall(function()
				VirtualInputManager:SendKeyEvent(true, Settings.AbilityKey, false, game)
				task.wait(Settings.KeyHoldDuration)
				VirtualInputManager:SendKeyEvent(false, Settings.AbilityKey, false, game)
			end)
		end
		local function lockCam(dur)   -- lock the camera onto the nearest enemy for the flash window
			task.spawn(function()
				local tgt = getNearestEnemy(24); local t0 = tick()
				while tgt and tgt.Parent and tick() - t0 < (dur or 0.5) do
					local tr = getHRP(tgt); local cam = workspace.CurrentCamera
					if tr and cam then pcall(function() cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tr.Position) end) end
					task.wait()
				end
			end)
		end
		local function faceBack()   -- turn to face the nearest enemy (rotation only)
			pcall(function()
				local mh = getHRP(myCharResolved()); local tgt = getNearestEnemy(18); local tr = tgt and getHRP(tgt)
				if mh and tr then mh.CFrame = CFrame.lookAt(mh.Position, Vector3.new(tr.Position.X, mh.Position.Y, tr.Position.Z)) end
			end)
		end
		local function dashLeft()   -- short fast pure-LEFT client dash (0.1s), then stop dead
			task.spawn(function()
				local t0 = tick()
				while tick() - t0 < 0.1 do
					local r = getHRP(myCharResolved()); if not r then break end
					local v = -r.CFrame.RightVector * 80
					pcall(function() r.AssemblyLinearVelocity = Vector3.new(v.X, math.min(r.AssemblyLinearVelocity.Y, 0), v.Z) end)
					task.wait()
				end
				local rS = getHRP(myCharResolved()); if rS then pcall(function() local vv = rS.AssemblyLinearVelocity; rS.AssemblyLinearVelocity = Vector3.new(0, vv.Y, 0) end) end
			end)
		end
		-- THE conversion: called once per detected M1 swing. Dispatches by mode.
		local function convert(delayTime)
			-- one conversion per swing (an anim can fire its track twice)
			if tick() - convGuard < 0.45 then return end
			convGuard = tick()
			-- FEINT (Mode A "Feint Black Flash"): count flashes, stop after N with an R feint
			if feintMode == "BF" and feintBFStop > 0 then
				if tick() - lastBF > 1.5 then bfCount = 0 end
				lastBF = tick(); bfCount = bfCount + 1
				if bfCount >= feintBFStop then bfCount = 0; bfSuppressUntil = tick() + 1.2; burstUntil = 0; task.delay(delayTime + 0.05, pressR); return end
			end
			-- GATE: the chain must actually be enabled (Auto Chain) or in a self-driving burst, and not feint-suppressed.
			-- This is what stops the conflict with Auto Single (which sets ScriptEnabled=false).
			if not (ScriptEnabled or tick() < burstUntil) or tick() < bfSuppressUntil then return end
			local mode = Settings.Mode
			-- (Side Dash / Back Dash / Jump / Teleport). On the FIRST swing of a burst we play the visible mode approach
			-- (the jump / back-dash / side-dash movement), then press the black flash; chained swings just snap+flash so
			if mode == "Side Dash" then
				dashLeft()
				task.delay(delayTime, function() if Settings.Mode == "Side Dash" then faceBack(); playCombo("Side Dash"); pressFlash() end end)
			else   -- Teleport / Jump / Back Dash = (approach on first hit) + snap behind + flash + lock
				local firstOfBurst = tick() - lastApproach > 1.0
				if firstOfBurst and (mode == "Jump" or mode == "Back Dash") then
					lastApproach = tick()
					if mode == "Jump" then playCombo("Jump") else playCombo("Side Dash") end
					task.spawn(function()   -- run the visible approach without blocking the anim listener, THEN flash
						local tgt = getNearestEnemy(Settings.LockRange)
						if tgt then local tr = getHRP(tgt); local mh = getHRP(myCharResolved())
							if tr and mh then chainTarget = tgt; chainTargetT = tick(); doApproach(tr, mh) end end
						doBackstab(false)
					end)
				else
					task.delay(delayTime, function()
						if Settings.Mode ~= "Side Dash" then doBackstab(false) end
					end)
				end
			end
		end
		local function matchDelay(animId)
			local d = AnimationTriggers[animId]
			if not d and StraightAnimations[animId] then d = 0.19 end
			if not d then local num = tostring(animId):match("%d+"); if num and _G.VX_M1_IDS and _G.VX_M1_IDS[num] then d = 0.19 end end
			return d
		end
		local resHooked = setmetatable({}, { __mode = "k" })
		task.spawn(function()
			while true do
				pcall(function()
					local m = myCharResolved(); local h = m and m:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
					if a and not resHooked[a] then
						resHooked[a] = a.AnimationPlayed:Connect(function(track)
							local animId = track.Animation and track.Animation.AnimationId
							if not animId then return end
							local d = matchDelay(animId)
							if d then convert(d) end
						end)
					end
				end)
				task.wait(0.5)
			end
		end)
	end
	local bdWatchGen = 0   -- one watcher at a time: a new E press supersedes the old watcher
	local function handleBackDashE()  -- Back Dash: E = a NORMAL side-dash BF; then a background WATCHER on that target - the moment they turn to FACE you, dash behind + black flash again.
		task.spawn(function()
			local tgt = getNearestEnemy(Settings.LockRange)
			if not tgt then return end
			chainTarget = tgt; chainTargetT = tick()
			local tr = getHRP(tgt)
			if tr and tr.Parent then                                            -- 1) normal side-dash black flash
				playCombo("Side Dash")
				fireDash("Right")
				local mh0 = getHRP(myCharResolved()); if mh0 then pcall(function() mh0.AssemblyLinearVelocity = Vector3.zero end) end   -- kill the dash-remote velocity BEFORE the orbit (that burst was the back-dash fling)
				orbitAround(tr, { duration = 0.16, endRadius = math.max(Settings.BackDistance, 3), extraSweep = math.pi * 0.25, endBehind = true })
			end
			if runChain then runChain(tgt) end
			-- 2) BACKGROUND WATCHER on THAT target: when they're FACING you (their back turned away), dash behind + flash
			bdWatchGen = bdWatchGen + 1; local gen = bdWatchGen
			task.spawn(function()
				local t0 = tick()
				task.wait(0.5)                                                  -- let the first flash resolve
				while tick() - t0 < 4 do                                        -- watch up to 4s for them to turn on you
					if gen ~= bdWatchGen then return end                        -- a newer E press took over
					local tr2 = getHRP(tgt); local mh = getHRP(myCharResolved())
					if not (tr2 and tr2.Parent and mh) then return end
					local th = tgt:FindFirstChildOfClass("Humanoid"); if th and th.Health <= 0 then return end
					local toMe = mh.Position - tr2.Position
					if toMe.Magnitude > 0.1 and tr2.CFrame.LookVector:Dot(toMe.Unit) > 0.45 then   -- they're LOOKING at you = their back is open
						chainTarget = tgt; chainTargetT = tick()
						playAnim("rbxassetid://134581973800784")                -- back-dash anim
						fireDash("Back")
						local mh2 = getHRP(myCharResolved()); if mh2 then pcall(function() mh2.AssemblyLinearVelocity = Vector3.zero end) end   -- no dash-burst fling
						orbitAround(tr2, { duration = 0.18, endRadius = math.max(Settings.BackDistance, 3), extraSweep = math.pi * 0.3, endBehind = true })  -- quick dash AROUND to the open back
						if runChain then runChain(tgt) end                      -- black flash
						return                                                  -- one counter-flash per E press
					end
					task.wait(0.06)
				end
			end)
		end)
	end
	local function doEPress()   -- E = the enemy's back, for EVERY mode. Jump/Side Dash play their REAL movement
		-- flourish first ("it doesn't even jump/side dash, it just teleports" — doApproach existed but was
		-- orphaned; it's wired back in here), THEN doBackstab's snap+lock+flash guarantees you land on the back
		-- precisely even if the flourish didn't line you up perfectly. Teleport/Back Dash are unchanged (instant).
		if _G.VX_BF_DEBUG then print("[DreamHub BF] E press -> mode="..Settings.Mode) end
		if Settings.Mode == "Back Dash" then handleBackDashE()
		elseif Settings.Mode == "Jump" or Settings.Mode == "Side Dash" then
			task.spawn(function()
				local tgt = getNearestEnemy(Settings.LockRange)
				if tgt then
					local tr = getHRP(tgt); local mh = getHRP(myCharResolved())
					if tr and mh then
						chainTarget = tgt; chainTargetT = tick()   -- doBackstab reuses this same target right after
						doApproach(tr, mh)                          -- the visible sprint+jump / dash+curve
					end
				end
				doBackstab(true)
			end)
		else task.spawn(function() doBackstab(true) end) end   -- Teleport: instant snap behind, face back, lock, flash
	end
	-- (Old E-key chain trigger REMOVED — the BF chain keybind is now 3, handled by the VXBF2 engine below.)
	do  -- FEINT input hooks (click/key based - the anim path missed on most characters)
		local UIS_F = game:GetService("UserInputService")
		local MOVEKEYS = { [Enum.KeyCode.One] = true, [Enum.KeyCode.Two] = true, [Enum.KeyCode.Three] = true, [Enum.KeyCode.Four] = true }
		UIS_F.InputBegan:Connect(function(input, gpe)
			-- DON'T bail on gpe: the game binds M1/1-4 itself, so every combat press arrives gpe=true — bailing
			-- meant Feint M1 NEVER fired. Only skip while typing in a textbox (same fix the Gojo module needed).
			if UIS_F:GetFocusedTextBox() then return end
			-- Mode B "Feint M1" (user spec): count your M1 CLICKS; at the number you picked (1/2/3) -> press R.
			-- No landed-hit strictness (that gate ate real clicks = "feint m1 don't work") and NO extra move after,
			-- just the R feint. Count resets if you pause >1.5s between clicks.
			if feintMode == "M1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
				if tick() - lastM1Feint > 1.5 then m1FeintCount = 0 end
				lastM1Feint = tick(); m1FeintCount = m1FeintCount + 1
				if m1FeintCount >= feintM1Count then
					m1FeintCount = 0
					task.delay(0.18, function() pressR() end)   -- let the M1 come out, then R = the feint
				end
			end
			-- Feint Abilities: you cast ANY skill (1/2/3/4) -> R right after = feint the move (own toggle OR the dropdown mode)
			local injKeys = _G.VX_INJ_KEYS
			local keyInjected = injKeys and injKeys[input.KeyCode] and tick() < injKeys[input.KeyCode]
			if feintMode ~= "M1" and (feintMovesOn or feintMode == "Moves") and MOVEKEYS[input.KeyCode] and tick() >= (_G.VX_INJECT_UNTIL or 0) and not keyInjected then
				task.delay(0.14, function() pressR() end)
			end
		end)
	end
		-- (Dead M1-in-place fireFlashInPlace block removed — the single conversion authority above handles M1 BF.)

	-- MOBILE SUPPORT: a floating tap button so phone players (no keyboard E) can fire the chosen chain approach. Toggled via ChainApi.setMobile. M1 Black Flash needs no button (M1 auto-fires) but the button still works.
	local mobileGui, mobileBtn
	local function mobileLabel()
		if _G.JJS_FREE then return "Black Flash" end   -- FREE: single "Black Flash" button (no chain modes)
		local m = Settings.Mode
		if m == "Teleport" then return "Teleport BF"
		elseif m == "Side Dash" then return "Side Dash BF"
		elseif m == "Back Dash" then return "Back Dash BF"
		elseif m == "Jump" then return "Jump BF"
		elseif m == "M1 Black Flash" then return "Just M1" end
		return "Black Flash"
	end
	local function buildMobile()
		if mobileGui then return end
		local Plr = game:GetService("Players").LocalPlayer
		mobileGui = Instance.new("ScreenGui")
		mobileGui.Name = "\0"; mobileGui.ResetOnSpawn = false; mobileGui.IgnoreGuiInset = true; mobileGui.DisplayOrder = 9400
		pcall(function() mobileGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
		if not mobileGui.Parent then mobileGui.Parent = Plr:WaitForChild("PlayerGui") end
		mobileBtn = Instance.new("TextButton")
		mobileBtn.Size = UDim2.fromOffset(108, 46); mobileBtn.Position = UDim2.new(1, -128, 1, -170); mobileBtn.AnchorPoint = Vector2.new(0, 0)
		mobileBtn.BackgroundColor3 = Color3.fromRGB(226, 46, 58); mobileBtn.Text = mobileLabel(); mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		mobileBtn.Font = Enum.Font.GothamBold; mobileBtn.TextSize = 13; mobileBtn.AutoButtonColor = true
		mobileBtn.Active = true; mobileBtn.Draggable = false; mobileBtn.Visible = false; mobileBtn.ZIndex = 20; mobileBtn.Parent = mobileGui
		local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 9); uc.Parent = mobileBtn
		local us = Instance.new("UIStroke"); us.Color = Color3.fromRGB(255, 255, 255); us.Thickness = 1.2; us.Transparency = 0.55; us.Parent = mobileBtn
		local UISm = game:GetService("UserInputService"); local VIMm = game:GetService("VirtualInputManager")
		local dragging, moved, ds, sp = false, false, nil, nil
		mobileBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; moved = false; ds = i.Position; sp = mobileBtn.Position end end)
		UISm.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - ds; if (math.abs(d.X) + math.abs(d.Y)) > 6 then moved = true end
				mobileBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
		UISm.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				if dragging and not moved then
					if _G.JJS_FREE then pcall(function() local _vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize; local _cx, _cy = (_vp and _vp.X/2) or 400, (_vp and _vp.Y/2) or 300; VIMm:SendMouseButtonEvent(_cx,_cy,0,true,game,0); task.wait(0.03); VIMm:SendMouseButtonEvent(_cx,_cy,0,false,game,0); task.wait(0.14); VIMm:SendKeyEvent(true, Enum.KeyCode.Three, false, game); task.wait(0.04); VIMm:SendKeyEvent(false, Enum.KeyCode.Three, false, game) end)   -- mobile BF: M1 then 3
					else pcall(doEPress) end
				end
				dragging = false
			end
		end)
	end
	local function setMobileBtn(v)
		buildMobile()
		if mobileBtn then mobileBtn.Text = mobileLabel(); mobileBtn.Visible = (v == true) end
	end

	runChain = function(tgt)
		burstUntil = tick() + 1.0
		if tgt and tgt.Parent then
			chainTarget = tgt; chainTargetT = tick()   -- Auto Counter: lock onto WHO swung and stay on them
			local myHRP = getHRP(myCharResolved()); local tHRP = getHRP(tgt)
			if myHRP and tHRP then
				dashGen = dashGen + 1
				local bp = getBehind(tHRP)
				local faceAt = Vector3.new(tHRP.Position.X, bp.Y, tHRP.Position.Z)   -- face the attacker, dead flat
				if _G.VX_ACPASS then _G.VX_ACPASS() end
				pcall(function() myHRP.CFrame = CFrame.lookAt(bp, faceAt); myHRP.AssemblyLinearVelocity = Vector3.zero end)
			end
		end
		doBackstab()
	end
	_G.VX_RUNCHAIN = runChain   -- expose the black-flash chain so Anti-Domain "Hit Caster" can flash the domain caster
	ChainApi = {
		setEnabled = function(v) ScriptEnabled = v == true end,
		isEnabled = function() return ScriptEnabled end,
		setBackDistance = function(v) if type(v) == "number" then Settings.BackDistance = v end end,
		setLockRange = function(v) if type(v) == "number" then Settings.LockRange = v end end,
		setKey = function(kc) if typeof(kc) == "EnumItem" then Settings.AbilityKey = kc end end,
		setMode = function(m) if type(m) == "string" then Settings.Mode = m; _G.VX_M1BF_ON = (m == "M1 Black Flash"); backDashStage = 0; chainTarget = nil; if mobileBtn then mobileBtn.Text = mobileLabel() end end end,   -- Teleport / Jump / Side Dash / Back Dash (2-stage E) / M1 Black Flash (M1 fires the chain)
		setFeintMode = function(m) feintMode = (m == "BF" or m == "M1" or m == "Moves") and m or "Off"; bfCount = 0; m1FeintCount = 0; bfSuppressUntil = 0 end,  -- Off / BF / M1 / Moves (no toast: don't reveal the mechanism)
		setFeintBFStop = function(n) feintBFStop = tonumber(n) or 2 end,                  -- Mode A: press R after this many black flashes
		setFeintM1Count = function(n) feintM1Count = tonumber(n) or 2 end,                -- Mode B: press R after this many of your M1s
		setFeintMove = function(n) feintMove = tonumber(n) or 1 end,                      -- Mode B: which move (1-4) to press after the feint
		setFeintMoves = function(v) feintMovesOn = v == true end,                          -- Feint Abilities toggle (1/2/3/4 -> R)
		backstab = function(tgt) if runChain then runChain(tgt) end end,                 -- Auto Counter -> the proven teleport black flash on WHO swung
		setMobile = function(v) setMobileBtn(v == true) end,                             -- MOBILE: show/hide the floating tap-to-fire button (phone = no keyboard E)
	}
end

-- ============================================================
-- BATCH 2 MODULES  (Item ESP + Auto Grab, Auto Skills, Invisibility, Auto Parkour, Teleport)
-- Each module exposes a small API; the GUI below wires them.
-- ============================================================
local ItemsApi, SkillsApi, InvisApi, ParkourApi, TPApi, M1ComboApi, CounterApi, LockOnApi, AutoUltApi, AntiAfkApi, NoclipApi, FarmApi, SpeedApi, FlyApi, PlayerEspApi, DashApi, TrainApi, DrinkApi, AntiStunApi, AntiRagdollApi, SideDashApi, EvasiveApi, AntiDomainApi, ResetApi, InfJumpApi, AntiCounterApi, AutoAdaptApi, JumpHeadApi, AntiBlackHoleApi, CrowUltApi, CrowHitApi, AutoDomainAdaptApi, HeadUltApi, RikaSwordApi, SlamApi, GokuApi, HollowApi, VisualApi, AimAssistApi, RemoveTreesApi, GojoTpApi, ReversalRedApi, ControlDummyApi, DesyncFreezeApi, TargetApi, AutoQTEApi, MahitoGrabApi

-- EVERY character's M1 anim id (user-captured) - set EARLY so Head of Hei / Goku M1 / Side Dash all detect a real M1 regardless of module load order
do
	local ids = {}
	for _, id in ipairs({
		-- FULL per-character M1 capture (user-provided, every character):
		"127851700400958","72548435296350","84547415708554",                        -- Gojo
		"95295463826732","105077924973072","124862357369335",                       -- Vessel
		"94588892125071","97868312130612","140588454098230",                        -- Restless Gambler
		"75337033003776","138489871864252","96185406489877",                        -- Ten Shadows
		"126277739156443","99710481887795","121322029260156",                       -- Perfection
		"119042572747325",                                                          -- Blood Manipulator (uniques)
		"96327114254575","107029561762376","117831239064143",                       -- Switcher
		"133936641185614","122573730331631","82400997593751",                       -- Defense Attorney
		"133240987753043","130806585141471","131967150738931",                      -- Cursed Partners
		"98783064085844","85148168523745","108686045412945",                        -- Puppet Master
		"101283990868172","108708446862011","77583711129628",                       -- Head of Hei
		"84359513001979","79436586236026","102285403332509",                        -- Salaryman
		"89537672683114",                                                           -- Disaster Plants
		"116910683335467","92698956945928",                                         -- True Cannon (uniques)
		"139479927693015","85068785050521","79086910454958","108027796023968",      -- Locust
		"131909724908049","72575786212990","119248903710146",                       -- Star Rage
		"82881042739459","125689391910002","84080901810314","139833047658617",      -- Mangaka
		"133447840605824","113963875117859","138196552148011",                      -- Lucky Coward
		"105961366724096","86519781516542","123591522021548",                       -- Black Death
		"78418813242411","114985590391235","108449614447004",                       -- Crow (MeiMei)
		"120133391090244","9443519528",                                             -- legacy extras
	}) do ids[id] = true end
	_G.VX_M1_IDS = ids
	-- real-M1 detection: the anim id ALONE false-fires (a walk anim id is in the list) and clicks alone false-fire (GUI clicks).
	-- A REAL M1 = a listed anim id playing right after a LEFT CLICK. Both together = can't miss, can't false-fire.
	local UIS = game:GetService("UserInputService")
	local LPc = game:GetService("Players").LocalPlayer
	_G.VX_LAST_CLICK = 0
	UIS.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then _G.VX_LAST_CLICK = tick() end end)
	pcall(function() LPc:GetMouse().Button1Down:Connect(function() _G.VX_LAST_CLICK = tick() end) end)

	-- ═══ SHARED REAL-M1 DETECTOR (_G.VX_ON_M1) ═══════════════════════════════════════════════════════════════
	-- THE GAME SINKS THE M1 CLICK. InputBegan and Mouse.Button1Down fire for GUI/empty clicks but NOT for a real
	-- attack click, which is why every feature bound to them silently never ran (Auto Uppercut, Auto Down Slam).
	-- The only reliable detector is polling the raw button state and catching the rising edge - the same trick
	-- the working Black Flash engine uses. One poll here, and any module can subscribe.
	do
		local RSm = game:GetService("RunService")
		local UISm = game:GetService("UserInputService")
		-- RE-EXECUTE SAFETY: _G survives between runs. Keeping the old subscriber table would leave DEAD closures
		-- from the previous script instance registered, and guarding the poll on a sticky flag meant the poll was
		-- never re-created on a second run - so every subscriber (Down Slam, Uppercut, M1 Chain) silently stopped
		-- working the moment you re-executed. Always start fresh and always reconnect.
		if _G.VX_M1_POLL_CONN then pcall(function() _G.VX_M1_POLL_CONN:Disconnect() end) end
		if _G.VX_KEY_POLL_CONN then pcall(function() _G.VX_KEY_POLL_CONN:Disconnect() end) end
		_G.VX_M1_SUBS = {}
		_G.VX_M1_SUB = function(key, fn)            -- subscribe: VX_M1_SUB("uppercut", myHandler); pass nil to remove
		-- NB: NOT named VX_ON_M1 - that global already exists later in the file as a zero-arg click stamper.
			if type(key) ~= "string" then return end
			_G.VX_M1_SUBS[key] = (type(fn) == "function") and fn or nil
		end
		_G.VX_KEY_SUBS = {}
		_G.VX_ON_KEY = function(key, fn)           -- subscribe: VX_ON_KEY("autoair", function(kc) ... end)
			if type(key) ~= "string" then return end
			_G.VX_KEY_SUBS[key] = (type(fn) == "function") and fn or nil
		end
		do
			local WATCH = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
				Enum.KeyCode.R, Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.G }
			local wasKey = {}
			_G.VX_KEY_POLL_CONN = RSm.RenderStepped:Connect(function()
				-- ═══ LAG ═══ This used to run 9 pcall-wrapped IsKeyDown calls EVERY FRAME, FOREVER, gated on
				-- nothing - so the hub cost CPU at 60Hz even with every single feature switched off. Two fixes:
				-- bail immediately when nothing is subscribed, and drop the per-key pcall for one pcall around
				-- the whole sweep (a pcall in a hot path allocates every call).
				if next(_G.VX_KEY_SUBS) == nil then return end
				if UISm:GetFocusedTextBox() then return end
				pcall(function()
					for _, kc in ipairs(WATCH) do
						local down = UISm:IsKeyDown(kc)
						if down and not wasKey[kc] then
							for _, fn in pairs(_G.VX_KEY_SUBS) do task.spawn(function() pcall(fn, kc) end) end
						end
						wasKey[kc] = down
					end
				end)
			end)
		end
		do
			local wasDown = false
			_G.VX_M1_POLL_CONN = RSm.RenderStepped:Connect(function()
				-- Same treatment as the key poll: skip entirely when nothing consumes M1 events AND no flash
				-- engine is armed. _G.VX_BFAPI_ON covers the Black Flash engine, which needs the click stamp
				-- even when it has no M1 subscriber of its own.
				if next(_G.VX_M1_SUBS) == nil and not _G.VX_BFAPI_ON then return end
				local ok, down = pcall(function() return UISm:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end)
				if not ok then return end
				if down and not UISm:GetFocusedTextBox() then
					-- ═══ THE ONE THAT BROKE EVERYTHING ═══ A recorder capture settled this: JJS advances the M1
					-- combo while you HOLD the button. One click held for 1.38s produced FOUR swings ~0.35s apart.
					-- This stamp used to live inside `down and not wasDown` - the rising edge only - so swings 2,
					-- 3 and 4 landed 0.41s / 0.76s / 1.12s after the last stamp, and every gate that asks "did
					-- they click recently" (the Black Flash engine's 0.5s test, the combo module's 0.40s
					-- realM1Now) answered NO. Only the first swing of a held combo ever counted. That single line
					-- is both "auto uppercut/down slam don't work" and "it doesn't black flash".
					-- Button still down = still attacking, so the stamp stays fresh while it is held.
					_G.VX_LAST_CLICK = tick()
					-- SUBSCRIBERS stay on the rising edge: they are per-click actions and must not repeat every
					-- frame. A click WE injected stamps the timing above but never re-enters them.
					if not wasDown and tick() >= (tonumber(_G.VX_SYNTH_CLICK) or 0) then
						for _, fn in pairs(_G.VX_M1_SUBS) do task.spawn(function() pcall(fn) end) end
					end
				end
				wasDown = down
			end)
		end
	end
	_G.VX_IS_M1 = function(track)
		if not track or not track.Animation then return false end
		local id = tostring(track.Animation.AnimationId):match("%d+")
		if not (id and _G.VX_M1_IDS[id]) then return false end
		return tick() - (_G.VX_LAST_CLICK or 0) < 0.4   -- anim + a click within 0.4s = a real M1 swing
	end
end

-- ═══ NETWORK OWNERSHIP CLAIM (the REAL root cause of "teleport sets me back" / "jump teleports instead of
-- jumping" / uppercut&downslam never registering) ═══ Every CFrame/AssemblyLinearVelocity write in this whole
-- file (doBackstab's snap, the teleport glide, the uppercut jump-velocity, downslam's fall-velocity check) is
-- COSMETIC unless the CLIENT owns network ownership of the HumanoidRootPart's assembly. If the SERVER owns it
-- simulation silently reverts on its next replication tick — which is EXACTLY "sets me back" and "the server
-- never sees me as airborne so uppercut/downslam won't trigger". This was never claimed anywhere in the file.
-- Claiming it is a standard, well-established exploit technique (SetNetworkOwner) and, when the executor's
-- security context permits it, makes every physics write in this hub actually stick server-side.
-- NO-OP now: the old SetNetworkOwner loop (called every 2s across all body parts) is a server-only API
-- and was very likely what tripped the anti-cheat into 267-kicking you ("your script kicks, mine doesn't").
-- The teleport doesn't need it anymore — the bypass blocks the set-back report instead. Kept as an empty
-- function so every existing call site is a harmless no-op.
local function vxClaimOwnership() end
_G.VX_CLAIMOWN = vxClaimOwnership
-- Shared anti-setback teleport BYPASS: JJS snaps you back if a single frame moves you faster than
-- maxSpeed*dt, so instead of one big jump we step to the target in capped per-frame hops that stay under
-- that limit. VX_TP_SPEED is the studs-per-frame step and safeTeleport reads it directly, so lowering the
-- TP Step slider genuinely makes the teleport gentler if a server still sets you back.
local VX_TP_SPEED = 60   -- studs PER FRAME (back-compat local; the LIVE value the glide reads is _G.VX_TP_SPEED)
_G.VX_TP_SPEED  = tonumber(_G.VX_TP_SPEED) or 60      -- studs/frame the glide steps in (lower = gentler if a server still sets you back)
_G.VX_TP_METHOD = _G.VX_TP_METHOD or "Instant"          -- "Glide" (default: anti-setback stepping + AC pass each hop) | "Instant" (single snap) | "Auto" (snap short, glide long)
-- game updates -> teleports set back). Try the known path first, else search for any RemoteEvent named
local vxACRemote = nil
local vxACStamp = 0
task.spawn(function() while true do task.wait(20); vxACRemote = nil; vxACStamp = 0 end end)   -- "TP works ~1min then stops": the game swaps the remote instance; drop the cache every 20s so we re-find the live one
local function vxResolveAC()
	if vxACRemote and vxACRemote.Parent then return vxACRemote end
	local RS = game:GetService("ReplicatedStorage")
	local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
	if vxACStamp < 0 and tick() + vxACStamp < 20 then return nil end   -- negative cache: the remote is destroyed (our default); do not rescan all of ReplicatedStorage on every pass
	local svc = k and k:FindFirstChild("AntiCheatService"); local re = svc and svc:FindFirstChild("RE"); re = re and re:FindFirstChild("Teleport")
	-- Skip OUR OWN dummy. The real remote is replaced by a tagged stand-in by default; firing
	-- that is pure noise, so the AC pass has to cleanly no-op instead of pretending it announced anything.
	if re and re:IsA("RemoteEvent") and not re:GetAttribute("VX_Dummy") then vxACRemote = re; return re end
	for _, d in ipairs(RS:GetDescendants()) do
		if d:IsA("RemoteEvent") and not d:GetAttribute("VX_Dummy") and string.lower(d.Name) == "teleport" and string.find(string.lower(d:GetFullName()), "anticheat") then vxACRemote = d; return d end
	end
	vxACStamp = -tick()   -- remember the miss (see the negative cache above)
	return nil
end
local vxTeleLastActive = 0  -- last time a teleport actually moved you; the safety loop uses it to know when NO teleport is running
local function vxACPass()
	vxTeleLastActive = tick()
	local re = vxResolveAC()
	if re then pcall(function() re:FireServer(workspace:GetServerTimeNow()) end) end
end
_G.VX_ACPASS = vxACPass
local vxTeleGen = 0  -- overlap guard: each teleport takes the next number; a newer one supersedes older holds so rapid teleports (Rika sword) do not fight over your CFrame or leave PlatformStand stuck on (frozen)
-- SAFETY: never leave you stuck in PlatformStand (the "frozen after teleport" pose in the screenshot).
-- Once no teleport has touched you for ~0.4s, force PlatformStand OFF so you can ALWAYS move again.
-- Forward-declared ON PURPOSE: the respawn reset and the collision sweeper below both live ABOVE the noclip
-- helpers, and Lua upvalue capture is LEXICAL - declaring these later would make every reference above a
-- GLOBAL (always nil), so the guards would silently never fire.
local vxNoclipParts
local vxLockChar          -- the rig a teleport hold belongs to; a respawn voids the hold
local vxLastPinPass = 0   -- throttle for the AC pass fired by the re-pin
local VX_NOTIFY   -- the GUI assigns this = its toast fn; forward-declared so teleport code above can use it
task.spawn(function()
	local Players = game:GetService("Players"); local LP = Players.LocalPlayer
	while true do
		task.wait(0.3)
		if tick() - vxTeleLastActive > 0.4 then
			local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if h and h.PlatformStand then pcall(function() h.PlatformStand = false end) end
			-- COLLISION SWEEPER: vxNoclipOff bails on a generation mismatch, and the Instant branch never
			-- noclipped at all - so a superseded glide could leave every part CanCollide=false permanently.
			-- 1.2s (not 0.4) because vxACPass bumps vxTeleLastActive at ~3Hz during flight; a tighter window
			-- could restore collisions MID-FLIGHT and slam you into the wall the noclip existed to pass.
			-- If a flight died mid-way the in-flight flag would stay set and permanently disable the position
			-- lock. Nothing has moved you for >1.2s here, so nothing can still be in flight.
			if _G.VX_TP_INFLIGHT and tick() - vxTeleLastActive > 1.2 then _G.VX_TP_INFLIGHT = false end
			if vxNoclipParts and tick() - vxTeleLastActive > 1.2 then
				for _, v in ipairs(vxNoclipParts) do pcall(function() v.CanCollide = true end) end
				vxNoclipParts = nil
			end
		end
	end
end)
-- TELEPORT = zero-lag bypass. The isolated anti-cheat bypass at the TOP of this file already destroyed the AC
-- remotes and disabled the anti/detect scripts (and re-applies on respawn), so the server has no channel to
-- reject a move: a single PivotTo just sticks. A throttled Heartbeat lock re-pins you if the server nudges you.
-- vxGlide / vxTeleportHard stay as thin wrappers so every call site (locations, players, slots) routes here.

local vxTeleportLock = false
local vxCurrentTargetCF = nil
-- SINGLE position lock (the rubberband fix): this Heartbeat is now the ONLY thing holding you after a
-- teleport. The old version ALSO ran a second while-loop inside safeTeleport doing the same job -- the two
-- fought over your CFrame/velocity every frame and the physics engine ping-ponged you between the target
-- and where the server thought you were. And it zeroed your velocity EVERY frame for the whole hold, which
-- froze you in place if you tried to walk/dash right after landing. Now: re-pin ONLY when the server shoves
-- you (>3 studs), never touch velocity per-frame.
game:GetService("RunService").Heartbeat:Connect(function()
	-- NEVER fight a teleport that is still in progress. While a hop or a glide is actively moving you,
	-- this lock would drag you toward a target you have not reached yet; the server corrects, the lock
	-- re-drags, and that tug-of-war IS the 'it sends me back'. The lock only guards you AFTER you land.
	if _G.VX_TP_INFLIGHT then return end
	if not (vxTeleportLock and vxCurrentTargetCF) then return end
	local LP = game:GetService("Players").LocalPlayer
	-- Characters-FIRST (matches vxMyChar and the PlatformStand loop).
	local chs = workspace:FindFirstChild("Characters")
	local resolved = chs and chs:FindFirstChild(LP.Name)
	local char = (resolved and resolved:FindFirstChild("HumanoidRootPart")) and resolved or (LP.Character or resolved)
	if not char then return end
	-- A hold belongs to ONE rig. A respawn VOIDS it - otherwise the hold finds your BRAND NEW character and
	-- drags it to the previous teleport's destination for the rest of the hold.
	if vxLockChar and char ~= vxLockChar then
		vxTeleportLock = false; vxCurrentTargetCF = nil; vxLockChar = nil
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if (hrp.Position - vxCurrentTargetCF.Position).Magnitude > 3 then
		-- ANSWER the correction on the anti-cheat's own channel. THIS is the private-vs-public difference:
		-- the glide fires this every few ticks while it moves (so it survives), while the re-pin fired it
		-- ZERO times - every correction was met with another unannounced jump, which escalates instead of
		-- settling. Throttled so we announce at most ~10x/sec.
		local now = tick()
		if now - vxLastPinPass > 0.1 then vxLastPinPass = now; vxACPass() end
		vxHardWrite(char, hrp, vxCurrentTargetCF)
	end
end)
-- A RESPAWN VOIDS EVERY HOLD (nothing used to do this - and with Instant Respawn on, a new rig exists a
-- fraction of a second after death, squarely inside every 2-5s hold).
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
	vxTeleportLock = false
	vxCurrentTargetCF = nil
	vxLockChar = nil
	vxNoclipParts = nil          -- recorded parts belong to the DEAD rig
	vxTeleGen = vxTeleGen + 1    -- supersede any in-flight leg and any pending release timer
	_G.VX_TELEPORTING = false
end)
local isTeleporting = false
local function vxMyChar()
	-- ORDER MATTERS: the JJS body lives under workspace.Characters, and LP.Character can point at a stale/decoy
	-- rig. Resolving LP.Character FIRST meant safeTeleport moved the wrong model — the teleport "did nothing"
	-- because your real body never left. Every other resolver in this file is Characters-first; now so is this.
	local LP = game:GetService("Players").LocalPlayer
	local chs = workspace:FindFirstChild("Characters")
	local c = chs and chs:FindFirstChild(LP.Name)
	if c and c:FindFirstChild("HumanoidRootPart") then return c end
	return LP.Character or c
end
-- AC acknowledge: only fire the REAL remote. The bypass at the top of the file replaces the AC remotes with
-- dummies tagged VX_Dummy -- the old version happily fired the dummy, which does nothing, so the server never
-- got the acknowledgement.
local function vxACAck()
	pcall(function()
		local k = game:GetService("ReplicatedStorage"):FindFirstChild("Knit")
		k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local svc = k and k:FindFirstChild("AntiCheatService")
		local re = svc and svc:FindFirstChild("RE"); re = re and re:FindFirstChild("Teleport")
		if re and not re:GetAttribute("VX_Dummy") then
			re:FireServer(workspace:GetServerTimeNow())
		end
	end)
end
-- Hard write: PivotTo ONLY (the fling fix). Setting hrp.CFrame first snapped the joints, then PivotTo moved
-- the whole model AGAIN -- the double write made constraints spasm and flung/jittered you. One PivotTo moves
-- everything coherently. Unseat/unanchor first so the write can't be silently overridden.
function vxHardWrite(char, hrp, cf)
	pcall(function()
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false
			if hum.PlatformStand then hum.PlatformStand = false end
			-- Only when ACTUALLY ragdolled. Re-issuing this on every re-pin frame pinned the humanoid in a
			-- getting-up transition for the whole hold.
			local st = hum:GetState()
			if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		local seatWeld = hrp:FindFirstChild("SeatWeld"); if seatWeld then seatWeld:Destroy() end
		if not _G.VX_TP_ANCHORING then hrp.Anchored = false end
		-- PIVOT MUST BE THE HRP. PivotTo moves the model's WorldPivot; if PrimaryPart is nil the HRP lands at
		-- an offset, and the re-pin (which measures HRP vs target) then never converges - it re-writes every
		-- frame for the whole hold. That reads exactly as "Instant did nothing / I jitter".
		if char.PrimaryPart ~= hrp then pcall(function() char.PrimaryPart = hrp end) end
		char:PivotTo(cf)
		if (hrp.Position - cf.Position).Magnitude > 0.5 then hrp.CFrame = cf end   -- pivot still missed: correct it
		-- DO NOT ZERO VELOCITY. A several-hundred-stud position change on one frame while velocity reads
		-- exactly 0,0,0 is physically impossible, and the server's own simulation flags that desync and
		-- reverts you. Leaving your real velocity intact makes the jump look like ordinary motion.
	end)
end
-- FLIGHT PATH CHECK: is the straight line to the target blocked by anything solid (a building)?
local function vxRouteClear(a, b)
	local d = b - a
	if d.Magnitude < 1 then return true end
	local ok, hit = pcall(function()
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local ig = { workspace.CurrentCamera }
		local c = vxMyChar(); if c then ig[#ig + 1] = c end
		local chars = workspace:FindFirstChild("Characters"); if chars then ig[#ig + 1] = chars end
		rp.FilterDescendantsInstances = ig
		rp.RespectCanCollide = true
		return workspace:Raycast(a, d, rp)
	end)
	-- BUG: this used to be `return ok and hit == nil`, so a pcall FAILURE reported "route blocked" — which forced
	-- the 400-stud up-and-dive detour on a perfectly clear line. A raycast error must never cause a detour.
	if not ok then return true end
	return hit == nil
end
-- VELOCITY FLIGHT (the TP method that works): instead of writing CFrames at the target, we push the character
-- there with plain physics VELOCITY every frame — the server watches you MOVE, so there is nothing to reject.
-- Collisions are turned off on your own parts for the flight (restored after) so walls/floors can't stop you,
-- and when the straight line is blocked by a building we fly UP 400 studs first, then dive to the target.
-- Returns when you're within 3 studs (or the safety timeout fires — then we hard-write and let the lock hold).
-- SHARED noclip save-list: with two overlapping teleports (Rika-sword spam), the OLD leg used to restore
-- collisions mid-flight of the NEW one — and the new leg had recorded nothing (parts were already off), so
-- you ended solid in a wall or permanently noclipped. One shared list: first leg records, only the CURRENT
-- teleport's landing restores, superseded legs leave it alone.
vxNoclipParts = nil
local function vxNoclipOn()
	if vxNoclipParts then return end
	vxNoclipParts = {}
	local c = vxMyChar()
	if c then for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false; vxNoclipParts[#vxNoclipParts + 1] = v end
	end end
end
local function vxNoclipOff(myGen)
	if myGen ~= vxTeleGen then return end            -- a newer teleport is still flying; it restores when IT lands
	if vxNoclipParts then for _, v in ipairs(vxNoclipParts) do pcall(function() v.CanCollide = true end) end end
	vxNoclipParts = nil
end
local function vxVelocityLeg(targetPos, speed, myGen)
	vxNoclipOn()
	local c = vxMyChar()
	local h0 = c and c:FindFirstChild("HumanoidRootPart")
	local t0 = tick()
	local timeout = (h0 and (targetPos - h0.Position).Magnitude or 400) / speed * 2 + 2
	while tick() - t0 < timeout do
		if myGen ~= vxTeleGen then break end                          -- superseded by a newer teleport
		local cc = vxMyChar(); local hrp = cc and cc:FindFirstChild("HumanoidRootPart")
		if not hrp then break end
		local dist = targetPos - hrp.Position
		if dist.Magnitude < 3 then break end
		hrp.AssemblyLinearVelocity = (dist.Magnitude > 0.01) and (dist.Unit * speed) or Vector3.zero
		-- lock OFF while flying: on a low-FPS client you cover >3 studs between frames, and the lock's re-pin
		-- (which also zeroes velocity) would fight the flight. The flight self-corrects anyway — it re-aims from
		-- wherever you are every frame — and the landing hard-write re-engages the lock at the exact target.
		vxCurrentTargetCF = nil
		if math.floor((tick() - t0) * 10) % 3 == 0 then vxACPass() end
		task.wait()
	end
	-- (THE "teleport broken" BUG: this used to restore a `changed` list that no longer exists after the shared
	-- noclip-list refactor — ipairs(nil) ERRORED here at the end of EVERY leg, so the landing hard-write never ran
	-- and collisions never restored. vxNoclipOff is the correct restore: only the current teleport's landing
	-- restores; a superseded leg leaves the shared list for the newer teleport.)
	vxNoclipOff(myGen)
	local cc = vxMyChar(); local hrp = cc and cc:FindFirstChild("HumanoidRootPart")
	if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end) end
end
-- Teleport = THE GLIDE METHOD (default). Instead of one impossible-speed snap, we walk the server to the target
-- in small believable hops and fire the anti-cheat "I teleported legitimately" pass on each hop -- the SAME
-- trick that makes it stick even when a server's AC is still alive. Two things made the old stepping useless and
-- are fixed here: (1) the Heartbeat lock re-pinned you to the FINAL target every frame, so it snapped instead of
-- gliding -- now the lock target MOVES WITH the glide (it reinforces each hop instead of fighting it); (2) no AC
-- pass was fired during the move -- now every few hops we fire it so the server accepts the motion. VX_TP_METHOD
-- picks Glide (default) / Instant / Auto; VX_TP_SPEED is the hop size (lower = gentler if a server still resists).
local function safeTeleport(targetCFrame, holdTime)
	local char = vxMyChar(); if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return false end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("AlignPosition") or v:IsA("AlignOrientation") or v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("BodyGyro") or v:IsA("BodyAngularVelocity") or v:IsA("VectorForce") or v:IsA("LinearVelocity") then
			pcall(function() v:Destroy() end)
		end
	end
	isTeleporting = true
	if _G.VX_DESTROY_AC then pcall(_G.VX_DESTROY_AC) end
	vxACAck()
	vxACPass()
	vxTeleGen = vxTeleGen + 1
	local myGen = vxTeleGen
	vxLockChar = char            -- stamp the hold with the rig that owns it (a respawn voids it)        -- overlap guard: a newer teleport supersedes this one's hops + lock
	local method = _G.VX_TP_METHOD or "Glide"
	local step = tonumber(_G.VX_TP_SPEED) or 60
	local from = hrp.Position
	local dist = (targetCFrame.Position - from).Magnitude
	local hold = tonumber(holdTime) or 0.5
	-- engage the lock anchored to WHERE WE ARE, so the Heartbeat can't yank us to the final spot mid-glide
	vxCurrentTargetCF = CFrame.new(from) * targetCFrame.Rotation
	vxTeleportLock = true
	local anchored = (method == "Anchor")
	local instant = anchored or (method == "Instant") or (method == "Auto" and dist <= step * 1.5)
	local glideSecs = 0
	if instant or dist < 1 then
		vxCurrentTargetCF = targetCFrame
		vxNoclipOff(myGen)                      -- reclaim collisions a superseded glide leaked
		-- NEVER engage the Heartbeat position lock for an instant hop. The lock forces you back every time
		-- the server nudges you, the server reverts again, and the two fight forever - that IS the
		-- rubberband. Land the hop, then leave the server alone.
		-- The lock stays ON, but VX_TP_INFLIGHT suspends it for the duration of the hop so it cannot fight our
		-- own writes. After we land it guards the position for a SHORT window - long enough to undo one server
		-- revert, short enough that it can never turn into the endless tug-of-war that caused the rubberband.
		vxTeleportLock = true
		_G.VX_TP_INFLIGHT = true
		-- ═══ STEPPED + VELOCITY-MATCHED TELEPORT (from real capture data) ═══
		-- A recorder run over many teleports showed the discriminator exactly: EVERY reverted teleport had
		-- AssemblyLinearVelocity == 0 at the moment of the jump, and the ones that STUCK had real velocity
		-- present through it. A large position change with zero velocity is impossible physics, so the
		-- server's own simulation rejects it - which is why firing the anti-cheat remote never helped.
		-- So: advance in believable hops AND carry a velocity that matches the direction we are travelling.
		-- The server sees position and motion agreeing with each other, and there is nothing to reject.
		task.spawn(function()
			local c1 = vxMyChar(); local h1 = c1 and c1:FindFirstChild("HumanoidRootPart")
			if h1 and not anchored then
				local rot   = targetCFrame.Rotation
				local start = h1.Position
				local delta = targetCFrame.Position - start
				local total = delta.Magnitude
				if total > 1 then
					local dirU  = delta.Unit
					-- Tuned to the capture data, not theory: the teleports that STUCK carried ~22 studs/s through
					-- 145-460 stud jumps, so the server is not demanding the speed EXPLAIN the distance - it
					-- rejects a large move whose velocity is exactly ZERO. Generous hops, believable velocity.
					-- ═══ PRIVATE WORKS, PUBLIC DOESN'T ═══ In an empty private server the anti-cheat has almost
						-- nothing to do and a 90-stud write sails through. A populated server is the opposite: the
						-- AC is actively servicing everyone, your updates are interleaved with theirs, and ping is
						-- higher - so the same 90-stud write lands as a single implausible jump and gets reverted.
						-- Smaller steps at a believable speed cost a few frames and survive the check. We pick the
						-- profile from the actual player count so you never have to think about it; set
						-- _G.VX_TP_STEP to override.
						local populated = #game:GetService("Players"):GetPlayers() > 1
						local STEP  = tonumber(_G.VX_TP_STEP) or (populated and 28 or 90)
						-- Within one step = ONE write. No walking, no glide feel - just there.
						local hops  = (total <= STEP) and 1 or math.clamp(math.ceil(total / STEP), 1, 80)
					for k = 1, hops do
						if myGen ~= vxTeleGen then break end
						local cc = vxMyChar(); local hh = cc and cc:FindFirstChild("HumanoidRootPart")
						if not hh then break end
						local p = start:Lerp(targetCFrame.Position, k / hops)
						if _G.VX_ACPASS then _G.VX_ACPASS() end
						pcall(function()
							cc:PivotTo(CFrame.new(p) * rot)   -- PivotTo: moves the whole model coherently, not just the root
							-- MATCHING velocity: this is the whole point. Position moved, so momentum must
							-- agree with it, otherwise the move is physically impossible and gets reverted.
							hh.AssemblyLinearVelocity = dirU * 26   -- ~ the value observed on the teleports that stuck
						end)
						game:GetService("RunService").Heartbeat:Wait()   -- resolved here: RunService is not a file-level local
					end
					-- settle ON the target, still carrying a little motion rather than a dead stop
					local cf = vxMyChar(); local hf = cf and cf:FindFirstChild("HumanoidRootPart")
					if hf then pcall(function()
						cf:PivotTo(targetCFrame)
						hf.AssemblyLinearVelocity = dirU * 12
					end) end
					-- ═══ VERIFY, THEN RETRY ONCE ═══ The walker used to be fire-and-forget: it wrote the hops and
					-- assumed you arrived. If the server reverted mid-walk you ended up back where you started with no
					-- sign anything had failed - that is "teleports don't work". Now we measure, re-walk once (which
					-- covers a single revert), and if it STILL fails we say so instead of leaving you guessing.
					task.wait(0.35)
					if myGen == vxTeleGen then
						local cv = vxMyChar(); local hv = cv and cv:FindFirstChild("HumanoidRootPart")
						local off = hv and (hv.Position - targetCFrame.Position).Magnitude or 9e9
						if off > 25 then
							if _G.VX_TP_DEBUG then print(string.format("[DreamHub TP] reverted (%.0f studs off) - retrying once", off)) end
							local start2 = hv and hv.Position or start
							local hops2 = math.clamp(math.ceil((targetCFrame.Position - start2).Magnitude / STEP), 1, 80)
							for k = 1, hops2 do
								if myGen ~= vxTeleGen then break end
								local cc2 = vxMyChar(); local hh2 = cc2 and cc2:FindFirstChild("HumanoidRootPart")
								if not hh2 then break end
								local p2 = start2:Lerp(targetCFrame.Position, k / hops2)
								if _G.VX_ACPASS then _G.VX_ACPASS() end
								pcall(function()
									cc2:PivotTo(CFrame.new(p2) * rot)
									hh2.AssemblyLinearVelocity = dirU * 26
								end)
								game:GetService("RunService").Heartbeat:Wait()
							end
							task.wait(0.35)
							local cw = vxMyChar(); local hw = cw and cw:FindFirstChild("HumanoidRootPart")
							local off2 = hw and (hw.Position - targetCFrame.Position).Magnitude or 9e9
							if off2 > 25 and VX_NOTIFY then
								VX_NOTIFY(string.format("Teleport reverted by the server (%.0f studs off). Try TP Method = Glide.", off2), false)
							end
						end
					end
				end
			end
		end)
		task.spawn(function()
			-- Only the ANCHOR method needs this forcing loop. For the normal path the stepped+velocity-matched
			-- walker above owns the movement; running both would jump you to the target on frame one and throw
			-- away the whole point of stepping.
			if not anchored then return end
			-- ANCHOR MODE: an anchored part is not physics-simulated, so a server correction applied as
			-- velocity or a BodyMover cannot move you while it is set. Anchor -> write -> unanchor.
			local anchoredPart = nil
			if anchored then
				local c0 = vxMyChar(); local h0 = c0 and c0:FindFirstChild("HumanoidRootPart")
				if h0 then anchoredPart = h0; _G.VX_TP_ANCHORING = true; pcall(function() h0.Anchored = true end) end
			end
			-- ~15 FRAMES OF INSISTENCE instead of ONE. A single frame's write can be lost to a server-owned
			-- assembly, a weld from someone else's ability, hitstun, a grab or a seat. Those conditions
			-- basically never occur in an empty private server and occur constantly in a public one - which
			-- is the whole private-vs-public difference. Every write is announced on the AC channel.
			for _ = 1, 5 do   -- 5, not 15: enough to survive a lost frame, few enough that it is not a fight
				-- BREAK, never RETURN: returning here would skip the unanchor below and leave you ANCHORED
				-- (= frozen in place, permanently) whenever a newer teleport superseded this one.
				if myGen ~= vxTeleGen then break end                  -- superseded by a newer teleport
				local c2 = vxMyChar(); local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
				if not h2 then break end
				if (h2.Position - targetCFrame.Position).Magnitude > 0.35 then
					vxACPass()
					vxHardWrite(c2, h2, targetCFrame)
				end
				task.wait()
			end
			if anchoredPart then _G.VX_TP_ANCHORING = false; pcall(function() anchoredPart.Anchored = false end) end   -- ALWAYS release
			_G.VX_TP_INFLIGHT = false            -- writes settled; the lock may guard now
			vxCurrentTargetCF = targetCFrame
			task.delay(0.8, function()           -- BOUNDED guard: never an endless fight
				if myGen ~= vxTeleGen then return end
				vxTeleportLock = false
				vxCurrentTargetCF = nil
			end)
		end)
		-- WATCHDOG: nothing may EVER leave you anchored (that would freeze you in place). Runs independently
		-- of the loop above, so even an unexpected error cannot strand you.
		if anchored then
			task.delay(1.5, function()
				_G.VX_TP_ANCHORING = false
				local cw = vxMyChar(); local hw = cw and cw:FindFirstChild("HumanoidRootPart")
				if hw and hw.Anchored then pcall(function() hw.Anchored = false end) end
			end)
		end
		-- (Auto-demote to Glide REMOVED: it silently switched the method behind your back, and every later
		--  teleport then glided - exactly the "it glides, I don't want that" complaint. The method is now
		--  only ever the one selected in the TP Method dropdown.)
	else
		-- VELOCITY FLIGHT (the working method): push yourself to the target with plain physics velocity —
		-- the server just sees you moving, nothing to reject. If a building blocks the straight line we fly
		-- UP 400 studs first, then dive to the target. Collisions off during flight, restored after.
		-- SPEED: _G.VX_TP_VEL was never assigned anywhere, so every teleport flew at a fixed 100 studs/s (a
		-- 500-stud hop took 5s, and 10s+ with a detour) = "teleport doesn't work". Default is now 260 and the
		-- Teleports page exposes a slider that writes _G.VX_TP_VEL.
		local vel = math.clamp(tonumber(_G.VX_TP_VEL) or 90, 30, 200)   -- 90 = believable dash speed; 260 was ~16x walk and gets reverted
		-- Only consider the up-and-over detour for LONG hops; short hops that clip a curb no longer fly 400 studs up.
		local blocked = dist > 150 and not vxRouteClear(from, targetCFrame.Position)
		local total = dist + (blocked and 240 or 0)                      -- up + dive when routing over a building
		glideSecs = total / vel + 0.4
		vxCurrentTargetCF = nil                                          -- lock idles during the flight (see vxVelocityLeg)
		_G.VX_TP_INFLIGHT = true                                         -- the lock must not fight the flight
		task.spawn(function()
			if blocked then vxVelocityLeg(from + Vector3.new(0, 120, 0), vel, myGen) end   -- was 400: a 400-stud vertical hop is an obvious flag
			vxVelocityLeg(targetCFrame.Position, vel, myGen)
			if myGen ~= vxTeleGen then _G.VX_TP_INFLIGHT = false; return end
			_G.VX_TP_INFLIGHT = false                                    -- landed: the lock may guard again
			local c = vxMyChar(); local h = c and c:FindFirstChild("HumanoidRootPart")
			if c and h then
				vxHardWrite(c, h, targetCFrame); vxACPass()   -- exact landing (position + facing)
				-- Kill the flight velocity HERE, not inside vxHardWrite. The glide arrives travelling at speed,
				-- so without this you sail straight past the target. It belongs to the glide landing alone -
				-- instant hops are never braked at all.
				-- But we brake to a DRIFT, not a dead stop. The recorder data is unambiguous: a big position
				-- change carrying velocity exactly (0,0,0) is impossible physics and the server reverts it, and
				-- this landing is a big position change. A small downward drift stops the overshoot just as
				-- well while still reading as a body under gravity rather than a desync. Keeping a tenth of the
				-- incoming horizontal speed makes it a decel rather than a hard stop, which reads more like a
				-- landing and less like a snap.
				pcall(function()
					local v = h.AssemblyLinearVelocity
					h.AssemblyLinearVelocity = Vector3.new(v.X * 0.1, -2, v.Z * 0.1)
					h.AssemblyAngularVelocity = Vector3.zero
				end)
			end
			vxCurrentTargetCF = targetCFrame
		end)
	end
	task.delay(glideSecs + hold, function()
		if myGen ~= vxTeleGen then return end                         -- don't clear a newer teleport's lock
		vxTeleportLock = false
		vxCurrentTargetCF = nil
		isTeleporting = false
		_G.VX_TP_INFLIGHT = false
		-- A teleport completed, so stop counting old failures - otherwise three unlucky hops ANYWHERE
		-- demoted you to Glide for the rest of the session.
		_G.VX_TP_SETBACKS = 0
		-- ...and give the user back the method they actually chose.
		if _G.VX_TP_METHOD == "Glide" and _G.VX_TP_USER_METHOD and _G.VX_TP_USER_METHOD ~= "Glide" then
			_G.VX_TP_METHOD = _G.VX_TP_USER_METHOD
		end
	end)
	return true
end
-- wrappers: everything in the hub that used to glide now just safe-teleports (the bypass makes it stick)
local function vxGlide(target, onArrive, holdTime)
	local hrp
	do local c = vxMyChar(); hrp = c and c:FindFirstChild("HumanoidRootPart") end   -- Characters-FIRST (LP.Character can be a stale/decoy rig)
	local cf = (typeof(target) == "CFrame") and target or (hrp and (CFrame.new(target) * hrp.CFrame.Rotation)) or CFrame.new(target)
	safeTeleport(cf, holdTime or 0.5)
	if onArrive then task.delay((holdTime or 0.5) + 0.05, function() pcall(onArrive) end) end
end
local function vxTeleportHard(dest, holdTime)
	if typeof(dest) == "CFrame" then safeTeleport(dest, holdTime or 0.6); return end
	local hrp
	do local c = vxMyChar(); hrp = c and c:FindFirstChild("HumanoidRootPart") end   -- Characters-FIRST (LP.Character can be a stale/decoy rig)
	local cf = hrp and (CFrame.new(dest) * hrp.CFrame.Rotation) or CFrame.new(dest)
	safeTeleport(cf, holdTime or 0.6)
end

-- Fire a Knit service RemoteEvent by name. Resolves the path fresh each call so it survives character
-- switches / lazy loading, and silently no-ops if the remote is not present (e.g. wrong character).
local VX_DEBUG = false
-- (VX_NOTIFY is forward-declared near the teleport state so earlier code can use it too)
local vxDbgGui, vxDbgLabel
local function vxLog(msg)  -- prints to console AND shows an on-screen line (top-left) when Debug is on - so you can SEE what fires
	if not VX_DEBUG then return end
	pcall(function() print("[Vaultix] " .. tostring(msg)) end)
	if not vxDbgLabel then
		pcall(function()
			vxDbgGui = Instance.new("ScreenGui"); vxDbgGui.Name = "VX_DBG"; vxDbgGui.ResetOnSpawn = false; vxDbgGui.IgnoreGuiInset = true; vxDbgGui.DisplayOrder = 99999
			vxDbgGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
			vxDbgLabel = Instance.new("TextLabel"); vxDbgLabel.Size = UDim2.fromOffset(480, 24); vxDbgLabel.Position = UDim2.fromOffset(12, 12)
			vxDbgLabel.BackgroundColor3 = Color3.fromRGB(8, 8, 10); vxDbgLabel.BackgroundTransparency = 0.2; vxDbgLabel.BorderSizePixel = 0
			vxDbgLabel.Font = Enum.Font.Code; vxDbgLabel.TextSize = 14; vxDbgLabel.TextColor3 = Color3.fromRGB(120, 235, 140)
			vxDbgLabel.TextXAlignment = Enum.TextXAlignment.Left; vxDbgLabel.Text = ""; vxDbgLabel.Parent = vxDbgGui
		end)
	end
	if vxDbgLabel then pcall(function() vxDbgLabel.Text = " [VX] " .. tostring(msg); vxDbgLabel.Visible = true end) end
end
local function vxSetDebug(b) VX_DEBUG = b == true; if vxDbgLabel then pcall(function() vxDbgLabel.Visible = VX_DEBUG end) end if VX_DEBUG then vxLog("debug ON") end end
-- REMOTE RESOLVER — RESILIENT + CACHED. Every remote-based feature (Side Dash, Auto Skills, Uppercut/Downslam,
-- Dash, Counter…) fires through here. The old code ONLY looked at the exact path
-- ReplicatedStorage.Knit.Knit.Services.<service>.RE.<reName>; if a game update renamed "Knit"/"Services"/"RE" or
-- moved the service, EVERY one of those features silently no-op'd (this was the shared root cause of "side dash /
-- auto skills / uppercut do nothing"). Now we: (1) try the exact path, (2) fall back to searching RS for a service
-- folder of that name holding the remote, (3) fall back to ANY RemoteEvent named reName under a service-named
-- ancestor, and cache whatever we find so the search runs at most once per (service,reName).
local _knitRoot
local function knitServices()
	if _knitRoot and _knitRoot.Parent then return _knitRoot end
	local RS = game:GetService("ReplicatedStorage")
	local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); _knitRoot = k and k:FindFirstChild("Services")
	return _knitRoot
end
local _reCache = {}
local function resolveRemote(service, reName)
	local key = service .. "\0" .. reName
	local cached = _reCache[key]
	if cached and cached.Parent then return cached end
	local RS = game:GetService("ReplicatedStorage")
	-- 1) exact captured path
	local svc = knitServices() and knitServices():FindFirstChild(service)
	if svc then
		local container = svc:FindFirstChild("RE") or svc:FindFirstChild("RemoteEvents") or svc:FindFirstChild("Remotes") or svc
		local re = container and container:FindFirstChild(reName)
		if re and re:IsA("RemoteEvent") then _reCache[key] = re; return re end
	end
	-- 2) any folder named <service> anywhere in RS that holds the remote (renamed/moved Knit tree)
	local found
	pcall(function()
		for _, d in ipairs(RS:GetDescendants()) do
			if d:IsA("RemoteEvent") and d.Name == reName then
				local anc = d.Parent
				while anc and anc ~= RS do
					if anc.Name == service then found = d; return end
					anc = anc.Parent
				end
			end
		end
	end)
	if found then _reCache[key] = found; return found end
	-- 3) last resort: the FIRST RemoteEvent named reName anywhere (covers a fully-flattened remote tree)
	pcall(function()
		for _, d in ipairs(RS:GetDescendants()) do
			if d:IsA("RemoteEvent") and d.Name == reName then found = d; return end
		end
	end)
	if found then _reCache[key] = found end
	return found
end
local function fireKnit(service, reName, ...)
	local re = resolveRemote(service, reName)
	if not re then vxLog("NOT FOUND " .. tostring(service) .. ".RE." .. tostring(reName)); if VX_DEBUG and VX_NOTIFY then VX_NOTIFY("NOT FOUND: " .. tostring(service) .. "." .. tostring(reName), false) end return false end
	local ok, err = pcall(re.FireServer, re, ...)  -- fire-and-forget: ok=true only means SENT, not that the server accepted
	vxLog((ok and "sent " or ("ERR " .. tostring(err) .. " ")) .. service .. "." .. reName)
	if VX_DEBUG and not ok and VX_NOTIFY then VX_NOTIFY("ERROR firing " .. service .. "." .. reName, false) end
	return ok
end

-- Known JJS playable characters (each = <Name>Service). Used to read an enemy's character name for ESP and to
-- auto-pick which Service.Activated to fire for Down Slam / Uppercut without a dropdown.
local CHAR_NAMES = { "Itadori", "Gojo", "Hakari", "Megumi", "Mahito", "Choso", "Todo", "Hiromi", "Yuta", "Mechamaru", "Naoya", "Nanami", "Hanami", "Ryu", "Locust", "Yuki", "Charles", "Haruta", "MeiMei", "Kurourushi", "Sukuna" }
local CHAR_SET = {}
for _, n in ipairs(CHAR_NAMES) do CHAR_SET[n] = true end
local function detectCharName(model)  -- find a value/child on a character model that names a known character
	if not model then return nil end
	local found
	pcall(function()
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("StringValue") and CHAR_SET[d.Value] then found = d.Value; return end
			if CHAR_SET[d.Name] and not d:IsA("BasePart") then found = d.Name; return end
		end
	end)
	return found
end
local function vxMyChar()  -- your live body (JJS keeps it under workspace.Characters)
	local LP = game:GetService("Players").LocalPlayer
	local chs = workspace:FindFirstChild("Characters")
	return (chs and chs:FindFirstChild(LP.Name)) or LP.Character
end
-- ═══ WHICH SERVICE IS MINE ═══ Down Slam / Uppercut fire <Char>Service.RE.Activated("Down"/"Up"), so we
-- must land on the RIGHT service. Guessing from a character name is unreliable, so we SCAN instead:
--   1) match a move in your Moveset to the service that owns it (captured names, most reliable)
--   2) match a detected character name
--   3) scan every service under Knit.Services and take one whose name matches a token on your character
-- Then we verify the candidate actually HAS RE.Activated before returning it.
local MOVE_TO_CHARSVC = {         -- move you own  ->  the character service that owns your M1 chain
	["cursedstrikes"] = "Itadori",  ["divergentfist"] = "Itadori",  ["blackflash"] = "Itadori",
	["lapseblue"]     = "Gojo",     ["twofoldkick"]   = "Gojo",     ["reversalred"] = "Gojo",  ["hollowpurple"] = "Gojo",
	["nue"]           = "Megumi",   ["rabbitescape"]  = "Megumi",   ["divinedog"]   = "Megumi", ["toad"] = "Megumi",
	["roughenergy"]   = "Hakari",   ["gamble"]        = "Hakari",
	["flowingredscale"] = "Choso",  ["piercingblood"] = "Choso",    ["bloodedge"]   = "Choso",  ["supernova"] = "Choso",
	["crushingjaws"]  = "Locust",   ["wingthrow"]     = "Locust",   ["clever"]      = "Locust",
	["idletransfiguration"] = "Mahito", ["polymorphicsoul"] = "Mahito",
	["crow"]          = "MeiMei",   ["blackbird"]     = "MeiMei",
	["worldcutting"]  = "Toji",     ["playfulcloud"]  = "Toji",     ["inverted"]    = "Toji",
	["rika"]          = "Yuta",     ["truelove"]      = "Yuta",
}
local function vxNorm(x) return (string.gsub(string.lower(tostring(x or "")), "[^%a%d]", "")) end
local function vxServicesFolder()
	local k = game:GetService("ReplicatedStorage"):FindFirstChild("Knit")
	k = k and k:FindFirstChild("Knit")
	return k and k:FindFirstChild("Services")
end
local function vxSvcHasActivated(name)
	local svcs = vxServicesFolder(); if not svcs then return false end
	local s = svcs:FindFirstChild(name); local re = s and s:FindFirstChild("RE")
	return (re and re:FindFirstChild("Activated")) and true or false
end
local function vxMyCharSvc()  -- which <Char>Service to fire for M1 / Down / Up
	local c = vxMyChar()
	-- 1) MOVESET MATCH (most reliable: your moves are unique to your character)
	if c then
		local mv = c:FindFirstChild("Moveset")
		if mv then
			for _, m in ipairs(mv:GetChildren()) do
				local who = MOVE_TO_CHARSVC[vxNorm(m.Name)]
				if who and vxSvcHasActivated(who .. "Service") then
					if _G.VX_M1_DEBUG then print("[M1COMBO] service via move '" .. m.Name .. "' -> " .. who .. "Service") end
					return who .. "Service"
				end
			end
		end
	end
	-- 2) DETECTED CHARACTER NAME
	local n = detectCharName(c)
	if n and vxSvcHasActivated(n .. "Service") then
		if _G.VX_M1_DEBUG then print("[M1COMBO] service via character name -> " .. n .. "Service") end
		return n .. "Service"
	end
	-- 3) SCAN: any service whose name appears on your character (model/humanoid/moveset text)
	local svcs = vxServicesFolder()
	if svcs and c then
		local hay = vxNorm(c.Name)
		local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hay = hay .. vxNorm(hum.DisplayName) end
		local mv = c:FindFirstChild("Moveset")
		if mv then for _, m in ipairs(mv:GetChildren()) do hay = hay .. vxNorm(m.Name) end end
		for _, sv in ipairs(svcs:GetChildren()) do
			local base = sv.Name:gsub("Service$", "")
			if #base >= 4 and string.find(hay, vxNorm(base), 1, true) and vxSvcHasActivated(sv.Name) then
				if _G.VX_M1_DEBUG then print("[M1COMBO] service via scan -> " .. sv.Name) end
				return sv.Name
			end
		end
	end
	if _G.VX_M1_DEBUG then print("[M1COMBO] NO service resolved for your character") end
	return nil
end
local function vxClientDash(dir, speed, dur)  -- a REAL velocity dash relative to facing; guarantees visible motion even if the Dash remote is validation-only
	local char = vxMyChar(); local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local cf = hrp.CFrame
	local vmap = { Right = cf.RightVector, Left = -cf.RightVector, Front = cf.LookVector, Back = -cf.LookVector }
	local v = (vmap[dir] or cf.LookVector) * (speed or 95)
	task.spawn(function()
		local t0 = tick()
		while tick() - t0 < (dur or 0.13) do
			pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.min(hrp.AssemblyLinearVelocity.Y, 0), v.Z) end)  -- FLAT dash: never add upward velocity (no more "jump high"/glide up), still lets you fall
			task.wait()
		end
	end)
end

-- MODULE: ITEM ESP + AUTO GRAB  (workspace.Items)
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local espOn, grabOn, grabFilter = false, false, "Any"
	local espFolder = Instance.new("Folder")
	espFolder.Name = "VX_ItemESP"
	pcall(function() espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not espFolder.Parent then espFolder.Parent = LP:WaitForChild("PlayerGui") end
	local boards = {}

	-- RESILIENT: the game may not keep drops in workspace.Items. Try the common folder names; cache the first that
	-- actually has children so grab/ESP find items regardless of the exact folder name.
	local _itemsF
	local function itemsFolder()
		if _itemsF and _itemsF.Parent and #_itemsF:GetChildren() > 0 then return _itemsF end
		for _, nm in ipairs({ "Items", "Drops", "ItemDrops", "Pickups", "Loot", "WorldItems", "DroppedItems", "Collectables", "Collectibles" }) do
			local f = workspace:FindFirstChild(nm)
			if f and #f:GetChildren() > 0 then _itemsF = f; return f end
		end
		-- JJS: throwable items (Trash / TNT / etc) live under workspace.Map.Destructible.Throwable
		-- (your explorer). Also check workspace.Destructible.Throwable in case a map has no Map wrapper.
		for _, base in ipairs({ workspace:FindFirstChild("Map"), workspace }) do
			if base then
				local d = base:FindFirstChild("Destructible"); local t = d and d:FindFirstChild("Throwable")
				if t and #t:GetChildren() > 0 then _itemsF = t; return t end
			end
		end
		return workspace:FindFirstChild("Items")
	end
	local function itemPart(m)
		if not m then return nil end
		if m:IsA("BasePart") then return m end
		return m:FindFirstChild("Handle") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	end
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end  -- JJS body lives under workspace.Characters (LP.Character lags = grab did nothing)
	local function myHRP() local c = myChar(); return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart")) end
	local function clearESP() for m, o in pairs(boards) do if o then if o.bb then o.bb:Destroy() end if o.hl then o.hl:Destroy() end end end boards = {} end
	local function buildESP()
		clearESP()
		local f = itemsFolder(); if not f then return end
		for _, m in ipairs(f:GetChildren()) do
			local part = itemPart(m)
			if part then
					-- clean floating PILL:  [dot]  Name  200m  (auto-width, dark rounded, like the game's own tracker)
					local bb = Instance.new("BillboardGui")
					bb.Adornee = part; bb.Size = UDim2.fromOffset(0, 24); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 2, 0); bb.MaxDistance = 800; bb.Parent = espFolder
					local pill = Instance.new("Frame"); pill.AutomaticSize = Enum.AutomaticSize.X; pill.Size = UDim2.new(0, 0, 1, 0); pill.AnchorPoint = Vector2.new(0.5, 0.5); pill.Position = UDim2.fromScale(0.5, 0.5)
					pill.BackgroundColor3 = Color3.fromRGB(22, 22, 26); pill.BackgroundTransparency = 0.06; pill.BorderSizePixel = 0; pill.Parent = bb
					Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
					local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255, 190, 60); ps.Thickness = 1.4; ps.Transparency = 0.35; ps.Parent = pill
					local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 9); pad.PaddingRight = UDim.new(0, 11); pad.Parent = pill
					local row = Instance.new("UIListLayout"); row.FillDirection = Enum.FillDirection.Horizontal; row.VerticalAlignment = Enum.VerticalAlignment.Center; row.SortOrder = Enum.SortOrder.LayoutOrder; row.Padding = UDim.new(0, 6); row.Parent = pill
					local dot = Instance.new("Frame"); dot.LayoutOrder = 1; dot.Size = UDim2.fromOffset(7, 7); dot.BackgroundColor3 = Color3.fromRGB(255, 190, 60); dot.BorderSizePixel = 0; dot.Parent = pill
					Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
					local lbl = Instance.new("TextLabel"); lbl.LayoutOrder = 2; lbl.AutomaticSize = Enum.AutomaticSize.X; lbl.Size = UDim2.new(0, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13; lbl.RichText = true; lbl.TextColor3 = Color3.fromRGB(245, 245, 250); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = m.Name; lbl.Parent = pill
					boards[m] = { bb = bb, hl = nil, lbl = lbl, name = m.Name }
			end
		end
	end
	task.spawn(function()
		while true do task.wait(0.4)
			if espOn then
				local f = itemsFolder()
				local count = f and #f:GetChildren() or 0
				local have = 0; for _ in pairs(boards) do have = have + 1 end
				if have ~= count then buildESP() end
				local hrp = myHRP()
				for m, o in pairs(boards) do
					if not (m and m.Parent) then if o.bb then o.bb:Destroy() end if o.hl then o.hl:Destroy() end boards[m] = nil
					else local part = itemPart(m)
						if part and o.lbl and hrp then o.lbl.Text = o.name .. "  <font color='rgb(160,160,168)'>" .. math.floor((part.Position - hrp.Position).Magnitude) .. "m</font>" end
					end
				end
			elseif next(boards) then clearESP() end
		end
	end)
	task.spawn(function()
		local VIM = game:GetService("VirtualInputManager")
		while true do task.wait(0.5)
			if grabOn then
				local f = itemsFolder(); local hrp = myHRP()
				if f and hrp then
					local bestModel, bestPart, bd
					for _, m in ipairs(f:GetChildren()) do
						if grabFilter == "Any" or m.Name == grabFilter then
							local part = itemPart(m)
							if part then local d = (part.Position - hrp.Position).Magnitude; if not bd or d < bd then bestModel, bestPart, bd = m, part, d end end
						end
					end
					if bestPart then
						if bd and bd > 5 then vxGlide(bestPart.Position + Vector3.new(0, 2, 0)); task.wait(0.85) end  -- glide ONTO the item first
						local me = myChar()
						if me then
							-- JJS items pick up by touch OR a ProximityPrompt OR the E key - do all three to be safe
							if typeof(firetouchinterest) == "function" then
								for _, ip in ipairs((bestModel and bestModel:GetDescendants()) or { bestPart }) do
									if ip:IsA("BasePart") then
										for _, mp in ipairs(me:GetChildren()) do
											if mp:IsA("BasePart") then pcall(function() firetouchinterest(mp, ip, 0); firetouchinterest(mp, ip, 1) end) end
										end
									end
								end
							end
							if typeof(fireproximityprompt) == "function" and bestModel then
								for _, dpp in ipairs(bestModel:GetDescendants()) do if dpp:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(dpp) end) end end
							end
							pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
						end
					end
				end
			end
		end
	end)
	ItemsApi = {
		setESP = function(v) espOn = v == true; if not espOn then clearESP() end end,
		setGrab = function(v) grabOn = v == true end,
		setFilter = function(name) if type(name) == "table" then name = name[1] end grabFilter = name or "Any" end,
		names = function()
			local out, seen = { "Any" }, { Any = true }
			local f = itemsFolder()
			if f then for _, m in ipairs(f:GetChildren()) do if not seen[m.Name] then seen[m.Name] = true; out[#out + 1] = m.Name end end end
			return out
		end,
	}
end

-- ============================================================
-- MODULE: TARGET  (type a username -> TP / bring item / auto-farm / view / kills / throw trash)
-- ============================================================
do
    local Players = game:GetService("Players")
    local VIM = game:GetService("VirtualInputManager")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local targetName = ""
    local farmOn, viewOn = false, false
    local savedCamSubj = nil
    local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
    local function myHRP() local c = myChar(); return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart")) end
    local function partOf(m) return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) end
    -- resolve the typed name (case-insensitive, partial) to a Player + their live character model
    local function resolve()
        if targetName == "" then return nil, nil end
        local low = string.lower(targetName)
        local plr
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and (string.lower(p.Name) == low or string.lower(p.DisplayName) == low) then plr = p; break end
        end
        if not plr then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and (string.find(string.lower(p.Name), low, 1, true) or string.find(string.lower(p.DisplayName), low, 1, true)) then plr = p; break end end end
        if not plr then return nil, nil end
        local chs = workspace:FindFirstChild("Characters")
        local mdl = (chs and chs:FindFirstChild(plr.Name)) or plr.Character
        return plr, mdl
    end
    local function faceTo(pos) local r = myHRP(); if r and pos then pcall(function() r.CFrame = CFrame.lookAt(r.Position, Vector3.new(pos.X, r.Position.Y, pos.Z)) end) end end
    -- read the target's move cooldowns from their Moveset (each move often carries a CD attribute or a Debounce)
    local function readCooldowns(mdl)
        local out = {}
        local mv = mdl and mdl:FindFirstChild("Moveset")
        if mv then for _, m in ipairs(mv:GetChildren()) do
            local cd = m:GetAttribute("Cooldown") or m:GetAttribute("CD") or (m:GetAttribute("Debounce") and "on CD")
            out[#out + 1] = m.Name .. (cd and (": " .. tostring(cd)) or ": ready")
        end end
        return out
    end
    local function usedUlt(mdl, plr)
        -- awakening shows up as an attribute/tag or an "Awakened"/"Domain" object; best-effort read
        if mdl then
            for _, a in ipairs({ "Awakened", "Awakening", "Ult", "Ultimate", "Domain" }) do
                if mdl:GetAttribute(a) then return true end
            end
            if mdl:FindFirstChild("Domain") or mdl:FindFirstChild("Awakened") then return true end
        end
        return false
    end
    -- REAL CLICK on a world part: fire its ClickDetector directly (the reliable path), and ALSO aim a real
    -- mouse click at its on-screen position so click-scripted pickups that need a genuine click get one.
    local function clickOn(obj)
        local part = obj:IsA("BasePart") and obj or partOf(obj)
        if not part then return end
        pcall(function()
            if typeof(fireclickdetector) == "function" then
                local holder = obj:IsA("Model") and obj or part
                for _, cd in ipairs(holder:GetDescendants()) do if cd:IsA("ClickDetector") then fireclickdetector(cd) end end
                local cd = part:FindFirstChildOfClass("ClickDetector"); if cd then fireclickdetector(cd) end
            end
        end)
        pcall(function()
            local cam = workspace.CurrentCamera
            local sp, on = cam:WorldToViewportPoint(part.Position)
            if on then VIM:SendMouseButtonEvent(sp.X, sp.Y, 0, true, game, 0); task.wait(0.04); VIM:SendMouseButtonEvent(sp.X, sp.Y, 0, false, game, 0) end
        end)
    end
    -- did the pickup actually happen? you're holding a Tool, OR the item vanished / got welded onto you
    local function holdingSomething(item)
        local me = myChar()
        if me and me:FindFirstChildOfClass("Tool") then return true end
        if item and (not item.Parent or (me and item:IsDescendantOf(me))) then return true end
        return false
    end
    -- pick THIS item up and make sure it took: TP onto it, then CLICK it (detector + real mouse click) + touch
    -- + prompt + E, and verify; up to 3 tries before giving up. Returns true only when the pickup really landed.
    local function grabThis(best)
        local part = best:IsA("BasePart") and best or partOf(best)
        if not part then return false end
        vxTeleportHard(part.Position + Vector3.new(0, 2, 0), 1.2); task.wait(0.6)
        for _ = 1, 3 do
            local me = myChar()
            if me and typeof(firetouchinterest) == "function" then
                for _, ip in ipairs(best:IsA("Model") and best:GetDescendants() or { best }) do
                    if ip:IsA("BasePart") then
                        for _, mp in ipairs(me:GetChildren()) do
                            if mp:IsA("BasePart") then pcall(function() firetouchinterest(mp, ip, 0); firetouchinterest(mp, ip, 1) end) end
                        end
                    end
                end
            end
            if typeof(fireproximityprompt) == "function" and best:IsA("Model") then
                for _, dpp in ipairs(best:GetDescendants()) do
                    if dpp:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(dpp) end) end
                end
            end
            clickOn(best)
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
            task.wait(0.3)
            if holdingSomething(best) then return true end
        end
        return holdingSomething(best)
    end
    local function grabNearestItem(filter)   -- pick up an item (filter name or "Any"), returns true if grabbed
        local hrp = myHRP(); if not hrp then return false end
        local best, bd
        -- roots to search: Map.Destructible.Throwable FIRST (resolved inline — itemsFolder() lives in the ITEMS
        -- do-block and is NOT visible here; the old pcall(itemsFolder) was silently calling nil), then fallbacks
        local roots = {}
        for _, base in ipairs({ workspace:FindFirstChild("Map"), workspace }) do
            if base then local d = base:FindFirstChild("Destructible"); local t = d and d:FindFirstChild("Throwable"); if t then roots[#roots+1] = t end end
        end
        local mp = workspace:FindFirstChild("Map")
        for _, base in ipairs({ mp, workspace }) do
            if base then for _, fn in ipairs({ "Destructible", "Throwable", "Items", "Drops", "Loot" }) do
                local f = base:FindFirstChild(fn); if f then roots[#roots+1] = f end
            end end
        end
        for _, f in ipairs(roots) do
            for _, m in ipairs(f:GetDescendants()) do
                if (m:IsA("Model") or m:IsA("BasePart")) and (filter == "Any" or filter == nil or m.Name == filter) then
                    local part = m:IsA("BasePart") and m or partOf(m)
                    if part then local d = (part.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = m, d end end
                end
            end
            if best then break end
        end
        if not best then return false end
        return grabThis(best)
    end
    -- AUTO FARM the target: TP behind + M1 loop
    task.spawn(function()
        while true do
            if farmOn then
                local _, mdl = resolve(); local tr = partOf(mdl)
                if tr and tr.Parent then
                    vxTeleportHard(tr.Position - (tr.CFrame.LookVector * 4) + Vector3.new(0, 0.5, 0), 0.5)
                    faceTo(tr.Position)
                    pcall(function()
                        local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
                        local cx, cy = vp.X / 2, vp.Y / 2   -- click SCREEN CENTER (0,0 was hitting the GUI corner = no M1)
                        VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0); task.wait(0.04); VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                    end)
                    task.wait(0.28)
                else task.wait(0.4) end
            else task.wait(0.25) end
        end
    end)
    -- VIEW the target (spectate camera)
    task.spawn(function()
        while true do
            if viewOn then
                local _, mdl = resolve(); local h = mdl and mdl:FindFirstChildOfClass("Humanoid")
                local cam = workspace.CurrentCamera
                if cam and h then if savedCamSubj == nil then savedCamSubj = cam.CameraSubject end pcall(function() cam.CameraSubject = h end) end
                task.wait(0.3)
            else task.wait(0.3) end
        end
    end)
    -- FLOATING INFO CARD: the menu's Label element can't live-update on this UI lib ("I don't see their info"),
    -- so the target's profile shows on its OWN card: avatar, name, HP bar, ult, kills. Appears while a name is
    -- typed and a match exists; disappears when the box is cleared.
    local card = {}
    local function buildCard()
        if card.gui and card.gui.Parent then return end
        local g = Instance.new("ScreenGui"); g.Name = "VX_TargetCard"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 9500
        pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end
        local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(1, 0); f.Position = UDim2.new(1, -14, 0, 96)
        f.Size = UDim2.fromOffset(240, 104); f.BackgroundColor3 = Color3.fromRGB(12, 12, 14); f.BackgroundTransparency = 0.04; f.BorderSizePixel = 0; f.Parent = g
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local acc = (typeof(_G.VX_ACCENT) == "Color3") and _G.VX_ACCENT or Color3.fromRGB(220, 30, 40)
        local st = Instance.new("UIStroke"); st.Color = acc; st.Thickness = 1.3; st.Transparency = 0.2; st.Parent = f
        -- title bar
        local ttl = Instance.new("TextLabel"); ttl.BackgroundTransparency = 1; ttl.Position = UDim2.fromOffset(12, 6); ttl.Size = UDim2.new(1, -24, 0, 14)
        ttl.Font = Enum.Font.GothamBold; ttl.TextSize = 11; ttl.TextColor3 = acc; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Text = "TARGET INFO"; ttl.Parent = f
        local av = Instance.new("ImageLabel"); av.Position = UDim2.fromOffset(10, 26); av.Size = UDim2.fromOffset(44, 44); av.BackgroundColor3 = Color3.fromRGB(24, 24, 28); av.BorderSizePixel = 0; av.Parent = f
        Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
        local nm = Instance.new("TextLabel"); nm.BackgroundTransparency = 1; nm.Position = UDim2.fromOffset(62, 26); nm.Size = UDim2.new(1, -70, 0, 16)
        nm.Font = Enum.Font.GothamBold; nm.TextSize = 12; nm.TextColor3 = Color3.fromRGB(240, 240, 244); nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextTruncate = Enum.TextTruncate.AtEnd; nm.Parent = f
        local meta = Instance.new("TextLabel"); meta.BackgroundTransparency = 1; meta.Position = UDim2.fromOffset(62, 43); meta.Size = UDim2.new(1, -70, 0, 14)
        meta.Font = Enum.Font.Gotham; meta.TextSize = 11; meta.TextColor3 = Color3.fromRGB(175, 175, 182); meta.TextXAlignment = Enum.TextXAlignment.Left; meta.Parent = f
        local hpBg = Instance.new("Frame"); hpBg.Position = UDim2.fromOffset(62, 61); hpBg.Size = UDim2.new(1, -74, 0, 8); hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 34); hpBg.BorderSizePixel = 0; hpBg.Parent = f
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)
        local hpF = Instance.new("Frame"); hpF.Size = UDim2.fromScale(1, 1); hpF.BackgroundColor3 = Color3.fromRGB(90, 220, 100); hpF.BorderSizePixel = 0; hpF.Parent = hpBg
        Instance.new("UICorner", hpF).CornerRadius = UDim.new(1, 0)
        local hpT = Instance.new("TextLabel"); hpT.BackgroundTransparency = 1; hpT.Position = UDim2.fromOffset(12, 78); hpT.Size = UDim2.new(1, -20, 0, 16)
        hpT.Font = Enum.Font.Gotham; hpT.TextSize = 11; hpT.TextColor3 = Color3.fromRGB(210, 210, 216); hpT.TextXAlignment = Enum.TextXAlignment.Left; hpT.Parent = f
        card = { gui = g, frame = f, av = av, nm = nm, meta = meta, hpF = hpF, hpT = hpT, avFor = nil }
    end
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                -- Card is ON by default (the in-GUI labels can't live-update on this UI lib). Set
                -- _G.VX_TARGET_CARD=false before the loadstring to hide it.
                if _G.VX_TARGET_CARD == false then if card.gui then card.gui.Enabled = false end return end
                if targetName == "" then if card.gui then card.gui.Enabled = false end return end
                local plr, mdl = resolve()
                if not plr then if card.gui then card.gui.Enabled = false end return end
                buildCard(); card.gui.Enabled = true
                local h = mdl and mdl:FindFirstChildOfClass("Humanoid")
                local hp, mx = (h and math.floor(h.Health) or 0), (h and math.floor(h.MaxHealth) or 100)
                card.nm.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
                local ls = plr:FindFirstChild("leaderstats"); local kills = "?"
                if ls then for _, s in ipairs(ls:GetChildren()) do if s.Name:lower():find("kill") then kills = tostring(s.Value) break end end end
                -- FRIENDS: fetch the count once per target (async + cached; harmless if the API is rate-limited)
                if card.friendsFor ~= plr.UserId then
                    card.friendsFor = plr.UserId; card.friends = "..."
                    task.spawn(function()
                        local ok, pages = pcall(function() return Players:GetFriendsAsync(plr.UserId) end)
                        if ok and pages then
                            local n = 0
                            pcall(function() while true do for _ in ipairs(pages:GetCurrentPage()) do n += 1 end; if pages.IsFinished then break end; pages:AdvanceToNextPageAsync() end end)
                            card.friends = tostring(n)
                        else card.friends = "?" end
                    end)
                end
                card.meta.Text = "Ult: " .. (usedUlt(mdl, plr) and "USED" or "no") .. "   Kills: " .. kills .. "   Friends: " .. tostring(card.friends or "...")
                card.hpF.Size = UDim2.fromScale(math.clamp(hp / math.max(mx, 1), 0, 1), 1)
                card.hpF.BackgroundColor3 = (hp / math.max(mx, 1)) > 0.5 and Color3.fromRGB(90, 220, 100) or ((hp / math.max(mx, 1)) > 0.25 and Color3.fromRGB(235, 200, 70) or Color3.fromRGB(230, 70, 70))
                card.hpT.Text = "HP " .. hp .. " / " .. mx
                if card.avFor ~= plr.UserId then
                    card.avFor = plr.UserId
                    task.spawn(function() local ok, u = pcall(function() return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end); if ok and u then card.av.Image = u end end)
                end
            end)
        end
    end)
    TargetApi = {
        setName = function(n) targetName = tostring(n or "") end,
        tpTo = function() local _, mdl = resolve(); local tr = partOf(mdl); if tr then vxTeleportHard(tr.Position - (tr.CFrame.LookVector * 4) + Vector3.new(0, 1, 0), 2) elseif VX_NOTIFY then VX_NOTIFY("Target not found", false) end end,
        bringItem = function(filter)
            task.spawn(function()
                if grabNearestItem(filter) then
                    task.wait(0.15)
                    local _, mdl = resolve(); local tr = partOf(mdl)
                    if tr then vxTeleportHard(tr.Position + Vector3.new(0, 1, 0), 2) end   -- the held item comes with you
                elseif VX_NOTIFY then VX_NOTIFY("No item to bring", false) end
            end)
        end,
        throwTrash = function()
            task.spawn(function()
                -- STEP 1 — GET TRASH IN HAND (verified, not assumed): grab a loose Trash item; if there is none,
                -- find the nearest TRASH CAN and CLICK IT (detector + a real mouse click on it) to get trash out,
                -- then grab that. grabThis/grabNearestItem only return true when you're actually holding it.
                local got = grabNearestItem("Trash")
                if not got then
                    local hrp = myHRP()
                    local can, cd
                    if hrp then
                        for _, m in ipairs(workspace:GetDescendants()) do
                            if (m:IsA("Model") or m:IsA("BasePart")) then
                                local n = string.lower(m.Name)
                                if n:find("trash", 1, true) and (n:find("can", 1, true) or n:find("bin", 1, true) or m:FindFirstChildWhichIsA("ClickDetector", true)) then
                                    local p = m:IsA("BasePart") and m or partOf(m)
                                    if p then local d = (p.Position - hrp.Position).Magnitude; if not cd or d < cd then can, cd = m, d end end
                                end
                            end
                        end
                    end
                    if can then
                        local p = can:IsA("BasePart") and can or partOf(can)
                        if p then vxTeleportHard(p.Position + Vector3.new(0, 2, 0), 1.2); task.wait(0.5) end
                        clickOn(can)   -- click ON the trash can to get the trash out
                        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
                        task.wait(0.5)
                        got = grabNearestItem("Trash") or holdingSomething(nil)
                    end
                end
                if not got then if VX_NOTIFY then VX_NOTIFY("No trash found (checked loose trash + trash cans)", false) end return end
                -- STEP 2 — THROW IT AT THE TARGET: TP in front, face them, M1 at SCREEN CENTER (a 0,0 click hits
                -- the GUI corner and throws nothing — same fix the Auto Farm click needed).
                task.wait(0.2)
                local _, mdl = resolve(); local tr = partOf(mdl)
                if not tr then if VX_NOTIFY then VX_NOTIFY("Holding trash, but the target wasn't found", false) end return end
                vxTeleportHard(tr.Position - (tr.CFrame.LookVector * 5) + Vector3.new(0, 1, 0), 1.5); task.wait(0.35)
                faceTo(tr.Position)
                pcall(function()
                    local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
                    local cx, cy = vp.X / 2, vp.Y / 2
                    VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0); task.wait(0.05); VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                end)
            end)
        end,
        setFarm = function(v) farmOn = v == true end,
        setView = function(v)
            viewOn = v == true
            if not viewOn then local cam = workspace.CurrentCamera; if cam and savedCamSubj then pcall(function() cam.CameraSubject = savedCamSubj end) end; savedCamSubj = nil end
        end,
        kills = function()
            local plr = resolve()
            if not plr then return "N/A" end
            local ls = plr:FindFirstChild("leaderstats")
            for _, nm in ipairs({ "Kills", "Wins", "KOs", "Kill" }) do local s = ls and ls:FindFirstChild(nm); if s then return tostring(s.Value) end end
            return "0"
        end,
        info = function()
            local plr, mdl = resolve()
            if not plr then return { found = false } end
            local h = mdl and mdl:FindFirstChildOfClass("Humanoid")
            return {
                found = true,
                name = plr.DisplayName .. " (@" .. plr.Name .. ")",
                userId = plr.UserId,
                health = h and math.floor(h.Health) or 0,
                maxHealth = h and math.floor(h.MaxHealth) or 100,
                ult = usedUlt(mdl, plr),
                cooldowns = readCooldowns(mdl),
            }
        end,
    }
end

-- ============================================================
-- MODULE: AUTO QTE CLICK  (Higuruma "Final Judgment" / Deadly Sentencing)
-- When you're judged, a QTE appears (buttons Confess / Silence / Denial, 3s timer; no answer = Silence auto-picked
-- and that's the losing outcome). This auto-clicks your chosen answer the instant the QTE shows, at Click Delay.
-- Also handles any generic mash-button QTE that pops in PlayerGui.
-- ============================================================
do
    local Players = game:GetService("Players")
    local VIM = game:GetService("VirtualInputManager")
    local LP = Players.LocalPlayer
    local enabled, choice, clickDelay = false, "Silence", 0
    local qteCPS, qteTapGap = 45, 0.02   -- Final Judgment key-sequence solver: presses/sec + down->up gap (both slider-set)
    local WANT = { "confess", "silence", "denial" }   -- the Deadly Sentencing options
    -- PC answers with KEYS (W / A / D), one per option; clicking the button is the MOBILE path only.
    -- Default map matches the on-screen layout (left/up/right); remap via the dropdowns if the game differs.
    local KEYMAP = { confess = Enum.KeyCode.A, silence = Enum.KeyCode.W, denial = Enum.KeyCode.D }
    local UIS_Q = game:GetService("UserInputService")
    local function clickGuiButton(btn)
        local ap, sz = btn.AbsolutePosition, btn.AbsoluteSize
        local x, y = ap.X + sz.X / 2, ap.Y + sz.Y / 2
        pcall(function() VIM:SendMouseButtonEvent(x, y, 0, true, game, 0); task.wait(0.03); VIM:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
    end
    -- THE REAL ANSWER REMOTES (user captures):
    -- We fire BOTH so it lands regardless of which the current game build uses.
    local ANSWER_NUM = { confess = 3, silence = 2, denial = 1 }
    local function myCharQ() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
    local function fireAnswer(word)
        local n = ANSWER_NUM[word]
        local ok = false
        pcall(function()
            local doms = workspace:FindFirstChild("Domains")
            local dom = doms and doms:FindFirstChild("Domain")
            local re = dom and dom:FindFirstChild("UnreliableRemoteEvent") or (dom and dom:FindFirstChildWhichIsA("UnreliableRemoteEvent")) or (dom and dom:FindFirstChildWhichIsA("RemoteEvent"))
            if re and n then re:FireServer(n); ok = true end
        end)
        pcall(function()   -- per-character confirm remote
            local c = myCharQ(); local cre = c and c:FindFirstChild("RemoteEvent")
            if cre then cre:FireServer(true); ok = true end
        end)
        return ok
    end
    local function pressAnswer(word)
        if fireAnswer(word) then return end   -- remote answered: done (the reliable path)
        local kc = KEYMAP[word]; if not kc then return end
        pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(0.06); VIM:SendKeyEvent(false, kc, false, game) end)
    end
    -- ZERO-LAG detection: NO full PlayerGui sweep (that GetDescendants scan 12x/sec was the "FPS drop when
    -- Final Judgment is on"). We keep a tiny CANDIDATE cache filled by DescendantAdded (cheap, event-driven)
    -- plus one initial sweep, and the loop only checks the handful of cached judgment elements.
    local candidates = setmetatable({}, { __mode = "k" })
    local function consider(d)
        if not (d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("TextLabel")) then return end
        local txt = string.lower(((d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text or "") .. " " .. d.Name)
        for _, w in ipairs(WANT) do if string.find(txt, w, 1, true) then candidates[d] = w; return end end
    end
    task.spawn(function()
        local pg = LP:WaitForChild("PlayerGui", 10)
        if not pg then return end
        pcall(function() for _, d in ipairs(pg:GetDescendants()) do consider(d) end end)   -- one-time seed
        pg.DescendantAdded:Connect(function(d) task.defer(function() pcall(consider, d) end) end)
    end)
    -- the nil-instance ANSWER remote (user's SimpleSpy capture: a nil-parented RemoteEvent fired with `true`)
    local function fireJudgmentRemote()
        if typeof(getnilinstances) ~= "function" then return end
        pcall(function()
            for _, v in ipairs(getnilinstances()) do
                if v.ClassName == "RemoteEvent" then
                    local n = string.lower(v.Name)
                    if n:find("judg") or n:find("answer") or n:find("choice") or n:find("sentenc") or n:find("court") or n:find("qte") then
                        pcall(function() v:FireServer(true) end)
                    end
                end
            end
        end)
    end
    -- Is a Deadly Sentencing judgment ACTIVE on us? (the domain remote exists = we're in someone's judgment)
    local function judgmentActive()
        local doms = workspace:FindFirstChild("Domains"); local dom = doms and doms:FindFirstChild("Domain")
        if dom and (dom:FindFirstChild("UnreliableRemoteEvent") or dom:FindFirstChildWhichIsA("UnreliableRemoteEvent")) then return true end
        local c = myChar(); if c and c:FindFirstChild("RemoteEvent") then return true end   -- per-char confirm remote present
        for d in pairs(candidates) do if d.Parent and d.Visible then return true end end
        return false
    end
    task.spawn(function()
        local lastFire = 0
        while true do
            if enabled then
                local want = string.lower(choice)
                local picked, anyBtn, anyWord
                for d, w in pairs(candidates) do
                    if d.Parent and d.Visible then anyBtn, anyWord = d, w; if w == want then picked = d end end
                end
                -- Fire when we SEE the option buttons OR when a judgment is simply active (the game may not
                -- expose the option words in PlayerGui) — throttled so we don't spam the remote.
                if (anyBtn or judgmentActive()) and tick() - lastFire > 0.5 then
                    lastFire = tick()
                    local word = picked and want or (anyWord or want)
                    if anyBtn and UIS_Q.TouchEnabled and not UIS_Q.KeyboardEnabled then   -- MOBILE: tap the option
                        local hit = picked or anyBtn
                        if hit:IsA("TextButton") or hit:IsA("ImageButton") then clickGuiButton(hit) end
                    end
                    fireAnswer(word)          -- the real remotes (domain n + per-char true)
                    pressAnswer(word)         -- + W/A/D keys as backup
                    fireJudgmentRemote()      -- + the nil-instance remote as backup
                    task.wait(0.3)
                end
                task.wait(clickDelay > 0 and clickDelay or 0.12)
            else task.wait(0.25) end
        end
    end)
    -- ANTI FINAL JUDGMENT: an enemy Higuruma starts the judgment -> DASH AWAY before it lands (face away + Q + hold S).
    local antiJudge = false
    task.spawn(function()
        local VIMj = game:GetService("VirtualInputManager")
        local lastDodge = 0
        while true do
            if antiJudge then
                local hit = false
                for d in pairs(candidates) do if d.Parent and d.Visible then hit = true break end end   -- judgment UI just showed on us
                if hit and tick() - lastDodge > 2 then
                    lastDodge = tick()
                    pcall(function()
                        local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        -- face AWAY from the nearest enemy then dash
                        local nearest
                        if r then local bd for _, m in ipairs((chs and chs:GetChildren()) or {}) do if m.Name ~= LP.Name then local tr = m:FindFirstChild("HumanoidRootPart"); if tr then local dd = (tr.Position - r.Position).Magnitude; if not bd or dd < bd then nearest, bd = tr, dd end end end end end
                        if r and nearest then
                            if _G.VX_ACPASS then _G.VX_ACPASS() end
                            local away = (r.Position - nearest.Position); away = Vector3.new(away.X, 0, away.Z)
                            if away.Magnitude > 0.1 then r.CFrame = CFrame.lookAt(r.Position, r.Position + away.Unit) end
                        end
                        VIMj:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        VIMj:SendKeyEvent(true, Enum.KeyCode.Q, false, game); task.wait(0.06); VIMj:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                        task.wait(0.5)
                        VIMj:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end)
                end
                task.wait(0.15)
            else task.wait(0.3) end
        end
    end)
    -- ── FINAL JUDGMENT KEY-SEQUENCE SOLVER ─────────────────────────────────────────────────────────────
    -- Some Final Judgment builds don't use Confess/Silence/Denial buttons — they FLASH A SEQUENCE OF KEYS
    -- (digits/letters) you must press fast. This rides the same Auto QTE toggle: it finds the "QTE" GUI, reads
    -- the currently-shown key, and taps it at qteCPS presses/sec. Speed + tap gap are slider-adjustable.
    local QDIGITS = {
        ["0"] = Enum.KeyCode.Zero, ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three,
        ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five, ["6"] = Enum.KeyCode.Six, ["7"] = Enum.KeyCode.Seven,
        ["8"] = Enum.KeyCode.Eight, ["9"] = Enum.KeyCode.Nine,
    }
    local function qUpper(s) return type(s) == "string" and string.upper(s) or "" end
    local function qKeyFrom(str)
        str = qUpper(str):gsub("%s+", "")
        if #str ~= 1 then return nil end
        if str:match("%a") then return Enum.KeyCode[str] end
        return QDIGITS[str]
    end
    local cachedQTE
    local function findQTE()
        if cachedQTE and cachedQTE.Parent then return cachedQTE end
        cachedQTE = nil
        local pGui = LP:FindFirstChild("PlayerGui"); if not pGui then return nil end
        for _, g in ipairs(pGui:GetChildren()) do
            if string.find(qUpper(g.Name), "QTE") then
                if not g:IsA("ScreenGui") or g.Enabled then cachedQTE = g; return g end
            end
        end
        for _, d in ipairs(pGui:GetDescendants()) do
            if d:IsA("GuiObject") and string.find(qUpper(d.Name), "QTE") then cachedQTE = d; return d end
        end
        return nil
    end
    local function qShown(o)
        local node = o
        while node and node:IsA("GuiObject") do if node.Visible == false then return false end; node = node.Parent end
        return true
    end
    local function qCurrentKey(qte)
        local best, bestScore
        for _, o in ipairs(qte:GetDescendants()) do
            if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Visible then
                local key = qKeyFrom(o.Text) or qKeyFrom(o.Name)
                if key and qShown(o) then
                    local opaque = 1 - math.clamp(o.TextTransparency or 0, 0, 1)
                    local score = opaque * 10 + (o.ZIndex or 0)
                    if not bestScore or score > bestScore then bestScore, best = score, key end
                end
            end
        end
        return best
    end
    local function qTap(key)
        pcall(function() VIM:SendKeyEvent(true, key, false, game); task.wait(qteTapGap > 0 and qteTapGap or 0.02); VIM:SendKeyEvent(false, key, false, game) end)
    end
    task.spawn(function()
        local last = 0
        while true do
            if enabled then
                local gap = 1 / math.max(qteCPS, 1)
                if os.clock() - last >= gap then
                    local qte = findQTE()
                    if qte then local key = qCurrentKey(qte); if key then qTap(key); last = os.clock() end end
                end
                task.wait()
            else task.wait(0.25) end
        end
    end)
    AutoQTEApi_setAnti = function(v) antiJudge = v == true end
    AutoQTEApi = {
        set = function(v) enabled = v == true end,
        setChoice = function(c) choice = tostring(c or "Silence") end,
        setDelay = function(v) if type(v) == "number" then clickDelay = v / 100 end end,   -- slider is 0-100 -> 0-1s
        setSpeed = function(v) if type(v) == "number" then qteCPS = math.clamp(v, 1, 120) end end,           -- Final Judgment: presses per second
        setTapGap = function(v) if type(v) == "number" then qteTapGap = math.clamp(v / 1000, 0, 0.2) end end, -- Final Judgment: ms slider -> seconds between down/up
    }
end

-- ============================================================
-- MODULE: VXBF2  — reworked Black Flash chain engine (keybind 3, not E). No GUI; driven by _G.VXBF2 setters.
-- Ported from the user's v13.0 logic, adapted for JJS: bodies live under workspace.Characters, teleports use
-- ============================================================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VIM = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer

    local Settings = {
        DashKey = Enum.KeyCode.Q, DashRange = 80, DashCooldown = 0.20,
        SideChoice = "Auto", SideCurveTime = 0.35, SideM1 = true, SideFaceAfter = true,
        Enabled = false, Mode = "Side Dash", BFKey = Enum.KeyCode.Three,
        BFCooldown = 0.5, BFTeleportDist = 3.0, BFM1 = false,
        SideAssist = false, BackAssist = false,
    }
    local AnimationTriggers = {
        -- Divergent Fist (100962226150441) removed: automatic 4th M1, not a BF windup.
        ["rbxassetid://95852624447551"] = 0.19,
        ["rbxassetid://74145636023952"] = 0.19, ["rbxassetid://72475960800126"] = 0.20,
        ["rbxassetid://123171106092050"] = 0.19,
    }
    local R = { held = {}, stamp = {}, lastDash = 0, lockTarget = nil, lockKind = nil, lockEnd = 0, bfCD = 0, bfActive = false, curving = false, chainUntil = 0, gen = 0 }
    local WIN = 0.15
    local function status(_) end   -- no-op: don't announce which BF mode fired (hide the mechanism)
    local function acPass() if _G.VX_ACPASS then _G.VX_ACPASS() end end
    local function GetChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character end
    local function GetRoot() local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
    local function IsAlive() local c = GetChar(); local h = c and c:FindFirstChildOfClass("Humanoid"); return h ~= nil and h.Health > 0 end
    local function VKeyDown(k) if not k then return end R.stamp[k] = tick(); if not R.held[k] then R.held[k] = true; VIM:SendKeyEvent(true, k, false, game) end end
    local function VKeyUp(k) if not k then return end if R.held[k] then R.held[k] = nil; VIM:SendKeyEvent(false, k, false, game) end end
    local function VKeyTap(k, hold) VKeyDown(k); task.wait(hold or 0.05); VKeyUp(k) end
    -- A synthetic click CANCELS an in-flight Crow ult, so every scripted click is suppressed while it is out.
    local function VMouseClick()
        if tick() < (tonumber(_G.VX_CROW_FLYING) or 0) then return end
        _G.VX_SYNTH_CLICK = tick() + 0.25   -- ours: the shared M1 detector must not re-enter its subscribers
        -- Viewport CENTRE, not (0,0) - see the note in the Black Flash engine. A corner click is not an attack.
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        local cx, cy = (vp and vp.X / 2) or 400, (vp and vp.Y / 2) or 300
        VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0); task.wait(0.03); VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
    end
    local function ReleaseAll() for k in pairs(R.held) do pcall(function() VIM:SendKeyEvent(false, k, false, game) end) end table.clear(R.held) end
    local function markThree() R.stamp[Enum.KeyCode.Three] = tick(); _G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Three] = tick() + 0.4 end
    local function pressBF() markThree(); VIM:SendKeyEvent(true, Settings.BFKey, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Settings.BFKey, false, game) end
    -- ═══ WHY THE OTHER BF MODES NEVER FLASHED ═══ Black Flash only lands when it is timed onto a CONNECTING M1.
    -- "M1 Chain" works because it triggers off your click, so an M1 is already landing. Side Dash / Back Dash /
    -- Jump / Teleport trigger off key 3, so they pressed 3 with nothing connecting and it just did nothing.
    -- This throws the M1 first and presses 3 in the same window the proven M1-BF path uses (~0.19s after the
    -- swing starts), which is what actually produces the flash.
    -- Rather than guessing a fixed delay, this ARMS the same anim-timed path the working M1-BF uses: it watches
    -- your real M1 animation and presses 3 at the exact frame offset. We just throw the M1 and let that hook do
    -- the timing. R.bfCD is cleared first because the mode functions stamp it on entry, which would otherwise
    -- make the hook's own cooldown check swallow the flash.
    -- Throw the M1 and let the PROVEN engine (BFApi, armed by the Mode dropdown) time the key-3 press off your
    -- real swing animation. We deliberately do NOT press 3 ourselves here — a blind press does nothing, and two
    -- presses would fight. The pressBF fallback only runs if BFApi is unavailable for some reason.
    -- BORROW the flash engine for THIS beat only, then give it straight back. Leaving it armed is what made
    -- every ordinary M1 auto-flash while the user's own "M1 Black Flash" toggle was off. _G.VX_BFAPI_WANT holds
    -- the user's real choice (bfM1On or bfAutoOn); we restore exactly that, never just "on".
    -- ═══ NEVER FLASH BEFORE YOU ARRIVE ═══ "it must not press 3 until it's at the target, no matter how far
    -- they are". The dash can be cut short (target moved, MAXDASH refused, the arc bailed on radius), and the
    -- old code pressed on a fixed delay regardless - so the flash went off from wherever you happened to be.
    -- This blocks the beat until you are genuinely in M1 range, and gives up rather than flashing from range.
    local function arrivedAt(t, maxWait)
        local e = t and t:FindFirstChild("HumanoidRootPart"); if not e then return false end
        local t0 = tick()
        while tick() - t0 < (maxWait or 0.5) do
            local p = GetRoot()
            local ee = t.Parent and t:FindFirstChild("HumanoidRootPart")
            if not (p and ee) then return false end
            if (ee.Position - p.Position).Magnitude <= 9 then return true end   -- inside M1 reach
            task.wait()
        end
        local p = GetRoot()
        local ee = t.Parent and t:FindFirstChild("HumanoidRootPart")
        return (p and ee and (ee.Position - p.Position).Magnitude <= 9) or false
    end
    local function m1ThenBF()
        -- Do NOT touch R.bfCD here: it is doBFM1Chain's own entry gate, and zeroing it made the BF Cooldown
        -- slider unreachable. BFApi keeps its own separate cooldown, so there is nothing to clear.
        if _G.VX_BF_RESETCOUNT then pcall(_G.VX_BF_RESETCOUNT) end   -- flash on THIS swing, not after N more
        local borrowed = false
        if not _G.VX_BFAPI_ON and _G.VX_BFAPI_SET then
            borrowed = true
            _G.VX_BF_BORROWED = true; _G.VX_BF_BORROW_USED = 0   -- single-shot: one flash, then the engine is deaf
            pcall(function() _G.VX_BFAPI_SET(true) end)
        end
        local firedBefore = _G.VX_BF_LAST_FIRE or 0
        -- ═══ THE "3 3 3 3 AND M1 M1 M1" SPAM ═══ FOUR different things were each throwing an input for one
        -- press. (1) this click, (2) the BF engine's own re-click on the windup, (3) the engine's key-3, and
        -- (4) the InputBegan click path pressing 3 again, plus my retry doubling 1-3. The engine's re-click is
        -- also the "it flings them": every extra landed M1 stacks the server's knockback on the target.
        -- So for the duration of a chain we suppress the engine's re-click and the InputBegan path, and the
        -- chain throws EXACTLY ONE click. R.chainUntil is the window both of those check.
        R.chainUntil = tick() + 1.0
        local myGen = R.gen or 0
        _G.VX_BF_RECLICK = false                    -- the chain's own click IS the M1; no second one
        VMouseClick()
        if not _G.VX_BFAPI_ON then      -- no engine at all -> best-effort blind press so something happens
            task.wait(0.19); pressBF()
        else
            -- VERIFY, DON'T HOPE: if the engine never flashed (mid-dash the game can refuse the click, so no
            -- animation plays and it never sees a windup), press the key ONCE. No second click - that was the
            -- extra M1 you were seeing.
            task.spawn(function()
                task.wait(0.42)
                if (R.gen or 0) ~= myGen then return end                     -- mode was turned off; stand down
                if (_G.VX_BF_LAST_FIRE or 0) > firedBefore then return end   -- it flashed; nothing to do
                if _G.VX_BF_DEBUG then print("[DreamHub BF] engine did not flash - one key press") end
                pressBF()
            end)
        end
        task.delay(1.0, function() _G.VX_BF_RECLICK = _G.VX_BF_RECLICK_USER ~= false end)   -- give the setting back
        if borrowed then
            task.delay(1.2, function()  -- covers the swing, the flash frame AND the retry above before handing back
                if _G.VX_BFAPI_SET then pcall(function() _G.VX_BFAPI_SET(_G.VX_BFAPI_WANT == true) end) end
                _G.VX_BF_BORROWED = false; _G.VX_BF_BORROW_USED = 0
            end)
        end
    end
    local function GetClosestTarget(maxD)
        local myRoot = GetRoot(); if not myRoot then return nil end
        -- LOCK TARGET: if you clicked a target, every feature acts on THAT one, at any range.
        local _g=_G.VX_LOCK; local _lt=(_g and _g.manualActive and _g.manualActive() and _g.get) and _g.get() or nil
        if _lt and _lt.Parent and _lt:FindFirstChild("HumanoidRootPart") then local _lh=_lt:FindFirstChildOfClass("Humanoid"); if not _lh or _lh.Health > 0 then return _lt end end
        local folder = workspace:FindFirstChild("Characters") or workspace
        local me = GetChar(); local best, bd = nil, maxD or 60
        for _, ch in ipairs(folder:GetChildren()) do
            if ch:IsA("Model") and ch ~= me and ch.Name ~= LocalPlayer.Name then
                local root = ch:FindFirstChild("HumanoidRootPart"); local hum = ch:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then local d = (myRoot.Position - root.Position).Magnitude; if d < bd then best, bd = ch, d end end
            end
        end
        return best
    end
    local function aimCameraDir(dir) local cam = workspace.CurrentCamera; if not cam then return end local pos = cam.CFrame.Position; local flat = Vector3.new(dir.X, 0, dir.Z); if flat.Magnitude < 0.01 then return end cam.CFrame = CFrame.new(pos, pos + flat.Unit) end
    local function aimCameraAt(p) local cam = workspace.CurrentCamera; if not cam then return end local pos = cam.CFrame.Position; cam.CFrame = CFrame.new(pos, Vector3.new(p.X, pos.Y, p.Z)) end
    local function faceRootDir(dir) local r = GetRoot(); if not r then return end local flat = Vector3.new(dir.X, 0, dir.Z); if flat.Magnitude < 0.01 then return end acPass(); r.CFrame = CFrame.new(r.Position, r.Position + flat.Unit) end
    local function faceEnemyBack(t)
        local p = GetRoot(); local e = t and t:FindFirstChild("HumanoidRootPart"); if not p or not e then return end
        local fwd = Vector3.new(e.CFrame.LookVector.X, 0, e.CFrame.LookVector.Z)
        if fwd.Magnitude > 0.01 then acPass(); p.CFrame = CFrame.new(e.Position - fwd * 5.2, e.Position) end   -- match the lock's hold distance (was 3 = a visible yank backwards)
    end
    local function autoSide(p, e) local eR = Vector3.new(e.CFrame.RightVector.X, 0, e.CFrame.RightVector.Z); if eR.Magnitude < 0.01 then return -1 end eR = eR.Unit; local off = Vector3.new((p.Position - e.Position).X, 0, (p.Position - e.Position).Z); return (off:Dot(eR) >= 0) and 1 or -1 end
    local function chooseSide(p, e, c) if UserInputService:IsKeyDown(Enum.KeyCode.A) then return -1 end if UserInputService:IsKeyDown(Enum.KeyCode.D) then return 1 end if c == "Left" then return -1 end if c == "Right" then return 1 end return autoSide(p, e) end
    local function smoothTP(pos) local p = GetRoot(); if not p then return end acPass(); p.CFrame = CFrame.new(pos); local cc = GetChar(); if cc then pcall(function() cc:PivotTo(CFrame.new(pos)) end) end end
    -- ALWAYS AIM AT THE BACK: turn your body AND the camera to look at their spine after any approach. Rotation
    -- only — no position write — so it cannot shove them or trip the movement checks.
    local function faceBackOf(t)
        local e = t and t:FindFirstChild("HumanoidRootPart"); if not e then return end
        local p = GetRoot(); if not p then return end
        pcall(function()
            p.CFrame = CFrame.lookAt(p.Position, Vector3.new(e.Position.X, p.Position.Y, e.Position.Z))
        end)
        aimCameraAt(e.Position)
    end
    -- ═══ LEGIT DASH TO THE BACK (replaces the old smoothTP+faceEnemyBack teleport) ═══
    -- Presses the REAL dash key so the game plays its own dash animation, then rides the shared anti-fling arc
    -- (_G.VX_ORBIT: per-frame speed cap, collisions off, velocity zeroed, live target tracking) around to their
    -- back. This is a travelled path, not a position write — it reads as a player dashing, never a blink.
    -- opts: duration, endRadius, extraSweep (rad; math.pi*2 = full 360), yArc (jump arc), dir (-1 L / 1 R).
    local MAXDASH = 26   -- studs. Past this a dash would visibly glide you across the map = obvious. Just don't.
    local function dashToBack(t, opts)
        local e = t and t:FindFirstChild("HumanoidRootPart"); if not e then return false end
        opts = opts or {}
        do
            local mr = GetRoot()
            if mr and (e.Position - mr.Position).Magnitude > MAXDASH then
                if _G.VX_BF_DEBUG then print("[DreamHub BF] target too far ("..math.floor((e.Position-mr.Position).Magnitude).." studs) - not dashing") end
                return false
            end
        end
        -- NO REAL SPACE PRESS. A physics jump leaves the Humanoid in Freefall with upward velocity while the arc
        -- writes CFrame every frame — the two fight and the resolver launches you. That was the "back dash /
        -- M1 chain jumps me and flings me". The airborne LOOK now comes from the arc's own yArc (pure CFrame),
        -- and we force the humanoid back to a grounded state first so nothing is mid-jump when the arc starts.
        pcall(function()
            local c = GetChar(); local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Running) end
        end)
        VKeyTap(Settings.DashKey, 0.04)   -- REAL dash key = the game's own dash anim + impulse
        task.wait(0.06)                   -- let that impulse start before the arc takes over (else it looks cancelled)
        local p = GetRoot(); if p then pcall(function() p.AssemblyLinearVelocity = Vector3.zero end) end   -- kill the dash burst so the arc can't fling
        if _G.VX_ORBIT then
            _G.VX_ORBIT(e, {
                duration   = opts.duration   or 0.26,
                endRadius  = opts.endRadius  or math.max(Settings.BFTeleportDist, 3),
                extraSweep = opts.extraSweep or (math.pi * 0.35),
                endBehind  = true,
                yArc       = opts.yArc or 0,
                dir        = opts.dir,
                endBias    = opts.endBias or 0,   -- 0 = dead behind the spine; ~0.55 = corner of the back
            })
            return true
        end
        -- orbit unavailable (very old build): fall back to the old instant move so the chain still lands
        local fwd = Vector3.new(e.CFrame.LookVector.X, 0, e.CFrame.LookVector.Z)
        if fwd.Magnitude > 0.01 then smoothTP(e.Position - fwd.Unit * Settings.BFTeleportDist) end
        return true
    end

    -- ═══ TELEPORT MODE: JUST GO BEHIND THEIR BACK ═══ No arc, no dash key, no orbit. One write to the spot
    -- directly behind their spine. This is what makes Teleport look different from every dash mode instead of
    -- playing the same arc as all of them.
    local function tpBehind(t)
        local e = t and t:FindFirstChild("HumanoidRootPart"); if not e then return false end
        local p = GetRoot(); if not p then return false end
        if (e.Position - p.Position).Magnitude > Settings.DashRange then return false end
        local fwd = Vector3.new(e.CFrame.LookVector.X, 0, e.CFrame.LookVector.Z)
        if fwd.Magnitude < 0.01 then fwd = Vector3.new(0, 0, 1) end
        fwd = fwd.Unit
        local dest = e.Position - fwd * math.max(Settings.BFTeleportDist, 4)
        acPass()
        pcall(function()
            local c = GetChar()
            local cf = CFrame.lookAt(dest, Vector3.new(e.Position.X, dest.Y, e.Position.Z))
            if c then c:PivotTo(cf) else p.CFrame = cf end
            -- never a dead zero: a position change with (0,0,0) velocity is the desync the server reverts
            p.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
        end)
        aimCameraAt(e.Position)
        return true
    end

    -- lock-on: hold you behind the target for the flash window
    -- ═══ THE BF FLING ═══ The back-lock pins you ~3 studs behind the target every frame. The orbit turns your
    -- collisions off for its arc and RESTORES them on exit — so the lock then held a SOLID body overlapping
    -- theirs, and the engine resolves that overlap by blasting both of you apart. That is the fling in every BF
    -- mode. Your collisions now stay OFF for the whole lock and are restored the moment it ends.
    local lockNoclip = nil
    local function lockClipOff()
        if lockNoclip then return end
        lockNoclip = {}
        local c = GetChar(); if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then lockNoclip[p] = true; pcall(function() p.CanCollide = false end) end
        end
    end
    local function lockClipOn()
        if not lockNoclip then return end
        for p in pairs(lockNoclip) do if p.Parent then pcall(function() p.CanCollide = true end) end end
        lockNoclip = nil
    end
    -- CAMERA-ONLY LOCK. The old bf_back lock wrote your CFrame into the enemy's hitbox every frame; the moment
    -- you M1 or flash, the physics engine resolves that overlap by launching you. No CFrame write here at all
    -- now - the dash already puts you on their back, so the lock just keeps the camera on them.
    RunService.RenderStepped:Connect(function(dt)
        if not R.lockTarget or tick() >= R.lockEnd then
            lockClipOn()
            return
        end
        if R.lockKind == "cam" or R.lockKind == "bf_back" then
            local e = R.lockTarget:FindFirstChild("HumanoidRootPart")
            if e then aimCameraAt(e.Position) end
        end
    end)

    -- SIDE DASH: orbit LEFT around the enemy (proven anti-fling arc _G.VX_ORBIT), soft-lock the camera on them
    -- the whole time, then auto-release (no lingering lock icon). Matches "click Q -> side around left, lock, off".
    local function doSideDash(isBF)
        if tick() - R.lastDash < Settings.DashCooldown and not isBF then return false end
        if R.curving then return false end
        local t = GetClosestTarget(Settings.DashRange); if not t then return false end
        local e = t:FindFirstChild("HumanoidRootPart"); if not e then return false end
        if not isBF then R.lastDash = tick() end
        R.curving = true
        R.lockTarget = t; R.lockKind = "cam"; R.lockEnd = tick() + 0.55   -- soft camera lock (no icon), auto-expires
        task.spawn(function()
            -- SIDE DASH ASSIST (Q) = the M1 CHAIN dash, verbatim, with NO Black Flash (per request).
            -- Same duration and same half-circle sweep, so it whips AROUND them fast and lands on their back.
            -- It never calls pressBF/m1ThenBF, so pressing Q can never flash.
            -- SMALL, FAST, SHARP: a quick clip around to the CORNER of their back (endBias offsets off the
            -- spine so the M1 does not land the knockdown), not a long orbit.
            dashToBack(t, { duration = 0.16, extraSweep = math.pi * 0.18, endBias = 0.55 })
            faceBackOf(t)
        end)
        if Settings.SideM1 and not isBF then task.delay(0.34, function() aimCameraAt((t:FindFirstChild("HumanoidRootPart") or e).Position); VMouseClick() end) end
        task.delay(0.55, function() R.curving = false; if R.lockKind == "cam" then R.lockTarget = nil; R.lockKind = nil end end)
        if not isBF then status("Side Dash L") end
        return true
    end
    -- BACK DASH: W+Q through them, M1 their back (no teleport)
    local function doBackDash(isBF)
        if tick() - R.lastDash < Settings.DashCooldown and not isBF then return false end
        local p = GetRoot(); if not p then return false end
        local t = GetClosestTarget(Settings.DashRange); if not t then return false end
        local e = t:FindFirstChild("HumanoidRootPart"); if not e then return false end
        if not isBF then R.lastDash = tick() end
        ReleaseAll(); task.wait(0.01)
        aimCameraAt(e.Position)
        -- BACK DASH ASSIST (E): a FULL 360 sweep around them ending on their back. extraSweep = 2*pi is one
        -- complete lap, ridden on the anti-fling arc (speed-capped, collisions off, velocity zeroed each frame),
        -- so it stays fast and tight without launching anyone or drifting out of the area.
        dashToBack(t, { duration = 0.42, extraSweep = math.pi * 2, endRadius = math.max(Settings.BFTeleportDist, 3.5) })
        if not isBF then task.delay(0.05, function() aimCameraAt((t:FindFirstChild("HumanoidRootPart") or e).Position); VMouseClick() end); status("Back Dash 360 + M1") end
        return true
    end
    -- BF MODES
    local function doBFTeleport()
        if tick() - R.bfCD < Settings.BFCooldown or R.bfActive then return end
        local t = GetClosestTarget(Settings.DashRange); if not t then return end
        local e = t:FindFirstChild("HumanoidRootPart"); if not e then return end
        R.bfCD = tick(); R.bfActive = true
        -- "Teleport" mode keeps its instant feel by design (it is the blink option); every OTHER mode dashes.
        -- DISTANCE BOUND: this is a raw CFrame write. A locked target ignores the range scan, so without
        -- this a far lock became a several-hundred-stud blink - exactly what gets you kicked.
        local _mr = GetRoot()
        if _mr and (e.Position - _mr.Position).Magnitude > Settings.DashRange then R.bfActive = false; return end
        -- "for teleport it should just teleport behind the back" - one write, no arc, no dash key.
        if not tpBehind(t) then R.bfActive = false; return end
        faceBackOf(t)
        R.lockTarget = t; R.lockKind = "cam"; R.lockEnd = tick() + 1.0
        task.wait(0.1); m1ThenBF(); task.delay(0.3, function() R.bfActive = false end); status("BF Teleport")
    end
    local function doBFJump()
        if tick() - R.bfCD < Settings.BFCooldown or R.bfActive then return end
        local t = GetClosestTarget(Settings.DashRange); if not t then return end
        local e = t:FindFirstChild("HumanoidRootPart"); if not e then return end
        R.bfCD = tick(); R.bfActive = true; ReleaseAll()
        -- "jump nee dot jump, press q but side dash behind them and m1": a REAL jump first, then the same short
        -- Q dash the Side Dash uses, then the M1. It used to be a flat CFrame arc with no jump in it at all.
        aimCameraAt(e.Position)
        -- "for jump it should jump and press q behind them" - a REAL jump, then the dash key, ending behind.
        -- Its own signature movement: airborne with a visible vertical arc, unlike the flat Side Dash clip.
        pcall(function()
            local c = GetChar(); local h = c and c:FindFirstChildOfClass("Humanoid")
            if h and h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
        end)
        task.wait(0.12)                                                  -- let the jump actually leave the ground
        dashToBack(t, { duration = 0.30, extraSweep = math.pi * 0.30, endRadius = 5.0, yArc = 7 })
        faceBackOf(t)
        R.lockTarget = t; R.lockKind = "cam"; R.lockEnd = tick() + 1.0
        task.wait(0.12)                                   -- let the dash settle before we test the distance
        if not arrivedAt(t, 0.5) then
            if _G.VX_BF_DEBUG then print("[DreamHub BF] never reached the target - not flashing from range") end
            R.bfActive = false
            return
        end
        m1ThenBF()
        task.delay(0.3, function() R.bfActive = false end); status("BF Jump Chain")
    end
    local function doBFSideDash()
        if tick() - R.bfCD < Settings.BFCooldown or R.bfActive then return end
        local t = GetClosestTarget(Settings.DashRange); if not t then return end
        R.bfCD = tick(); R.bfActive = true
        local e = t:FindFirstChild("HumanoidRootPart"); if not e then R.bfActive = false return end
        -- ORDER FIX: this used to press BF *before* moving, so the flash fired from your old position and whiffed
        -- ("it dashes behind them but doesn't black flash"). Dash to their back FIRST, then flash.
        -- "for a side dash you need to make it more legit and fast" - the shortest, flattest clip of any mode:
        -- 0.14s, a tight 0.10pi sweep, no vertical arc, ending just off the spine. Reads as a real Q dash.
        dashToBack(t, { duration = 0.14, extraSweep = math.pi * 0.10, endRadius = 4.4, endBias = 0.35, yArc = 0 })
        faceBackOf(t)
        R.lockTarget = t; R.lockKind = "cam"; R.lockEnd = tick() + 1.0
        task.wait(0.12)                                   -- let the dash settle before we test the distance
        if not arrivedAt(t, 0.5) then
            if _G.VX_BF_DEBUG then print("[DreamHub BF] never reached the target - not flashing from range") end
            R.bfActive = false
            return
        end
        m1ThenBF()
        task.delay(0.3, function() R.bfActive = false end); status("BF Side Chain")
    end
    local function doBFBackDash()
        if tick() - R.bfCD < Settings.BFCooldown or R.bfActive then return end
        local t = GetClosestTarget(Settings.DashRange); if not t then return end
        R.bfCD = tick(); R.bfActive = true
        local e = t:FindFirstChild("HumanoidRootPart"); if not e then R.bfActive = false return end
        ReleaseAll()
        -- ═══ BACK DASH — ALTERNATES ON EVERY PRESS OF 3 ═══
        --   press 1: plain dash around to their back  -> black flash
        --   press 2: JUMP (space) first, then dash behind -> black flash   (then it flips back to press-1 behavior)
        -- The counter resets after 6s idle so a fresh engagement always starts on the plain dash.
        if tick() - (R.backDashT or 0) > 6 then R.backDashAlt = false end
        R.backDashAlt = not R.backDashAlt
        R.backDashT = tick()
        local jumpThis = R.backDashAlt == false   -- false after the 2nd toggle -> the jump variant
        aimCameraAt(e.Position)
        -- Same short clip as the (good) Side Dash. The alternate press does a REAL jump first rather than a
        -- fake vertical CFrame lift, so it reads as a player jumping and dashing rather than floating.
        if jumpThis then
            pcall(function()
                local c = GetChar(); local h = c and c:FindFirstChildOfClass("Humanoid")
                if h and h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
            end)
            task.wait(0.10)
        end
        -- Distinct from Side Dash on purpose: a wider half-circle sweep that reads as going AROUND them
        -- rather than clipping past their side.
        dashToBack(t, { duration = 0.26, extraSweep = math.pi * 0.55, endRadius = 4.8 })
        faceBackOf(t)
        R.lockTarget = t; R.lockKind = "cam"; R.lockEnd = tick() + 1.0
        task.wait(0.12)                                   -- let the dash settle before we test the distance
        if not arrivedAt(t, 0.5) then
            if _G.VX_BF_DEBUG then print("[DreamHub BF] never reached the target - not flashing from range") end
            R.bfActive = false
            return
        end
        m1ThenBF()
        task.delay(0.3, function() R.bfActive = false end)
        status(jumpThis and "BF Back Chain (jump)" or "BF Back Chain")
    end
    -- ═══ ENGAGEMENT RANGE ═══ The chain may only ever act on someone you are ALREADY fighting. DashRange (80)
    -- is the ranged-search radius for the assist keys; using it here is what made one M1 glide you across the
    -- map at a stranger. An M1 lands at ~7 studs, so anything past this is not a fight you are in.
    local CHAIN_RANGE = 20
    local function targetInChainRange()
        local t = GetClosestTarget(CHAIN_RANGE); if not t then return nil end
        local e = t:FindFirstChild("HumanoidRootPart"); local p = GetRoot()
        if not e or not p then return nil end
        if (e.Position - p.Position).Magnitude > CHAIN_RANGE then return nil end
        return t
    end
    local function doBFM1Chain()
        if tick() - R.bfCD < Settings.BFCooldown or R.bfActive then return end
        -- NO TARGET NEAR YOU = DO NOTHING. Not a dash, not a flash, not a camera move. Checked BEFORE bfActive
        -- is claimed so a whiff never eats the cooldown.
        local t = targetInChainRange()
        if not t then
            if _G.VX_BF_DEBUG then print("[DreamHub BF] M1 chain: nobody within " .. CHAIN_RANGE .. " studs - standing down") end
            return
        end
        R.bfCD = tick(); R.bfActive = true
        -- ═══ ONE M1. ═══ YOUR click is the M1 - that is what triggered this. m1ThenBF() used to run here and it
        -- calls VMouseClick(), so every chain threw a SECOND swing on top of yours (and a third if the engine
        -- was unavailable and it blind-pressed 3). That is the "2 or 3 M1s" problem. We now borrow the flash
        -- engine WITHOUT clicking: it hooks your real swing animation and presses 3 at the right frame, so the
        -- flash lands on the M1 you already threw.
        local borrowed = false
        if not _G.VX_BFAPI_ON and _G.VX_BFAPI_SET then
            borrowed = true
            _G.VX_BF_BORROWED = true; _G.VX_BF_BORROW_USED = 0   -- single-shot (see the note in the BF engine)
            pcall(function() _G.VX_BFAPI_SET(true) end)
        end
        if _G.VX_BF_RESETCOUNT then pcall(_G.VX_BF_RESETCOUNT) end   -- flash on THIS swing, not after N more
        -- No engine at all (very old build): press 3 ourselves on the same beat the engine would have. Still no
        -- extra click - the swing being flashed is the one you already threw.
        if not _G.VX_BFAPI_ON then task.delay(0.19, function() pressBF() end) end
        R.lockTarget = t; R.lockKind = "cam"; R.lockEnd = tick() + 1.4   -- camera stays on them through the chain
        -- side dash AROUND to their back (real dash key + anti-fling arc). If the dash itself declines - the
        -- target moved out of MAXDASH in the meantime - we stop rather than snapping to them.
        -- endRadius 4.6 = right on their back and inside M1 range. The orbit already zeroes velocity every
        -- frame and on exit, and the chain now suppresses the engine's re-click, which was the actual source of
        -- "it flings the person" - each extra landed M1 stacks the server's knockback on them.
        -- M1 Chain's own signature: a medium sweep ending DEAD behind the spine (endBias 0), distinct from
        -- Side Dash's off-spine clip and Back Dash's wide half-circle.
        local dashed = dashToBack(t, { duration = 0.22, extraSweep = math.pi * 0.22, endRadius = 4.6, endBias = 0 })
        if dashed then faceBackOf(t) end
        if borrowed then
            task.delay(0.6, function()   -- hand the engine back exactly as we found it
                if _G.VX_BFAPI_SET then pcall(function() _G.VX_BFAPI_SET(_G.VX_BFAPI_WANT == true) end) end
                _G.VX_BF_BORROWED = false; _G.VX_BF_BORROW_USED = 0
            end)
        end
        task.delay(0.3, function() R.bfActive = false end); status("BF M1 Chain")
    end
    local function doBlackFlash()
        if not Settings.Enabled or R.bfActive then return end
        local m = Settings.Mode
        if m == "Teleport" then doBFTeleport() elseif m == "Jump" then doBFJump()
        elseif m == "Side Dash" then doBFSideDash() elseif m == "Back Dash" then doBFBackDash()
        elseif m == "M1" then doBFM1Chain() end
    end

    -- ═══ M1 BLACK FLASH — user's AutoBlackFlash logic ═══ Fires key 3 ONLY when one of the KNOWN Black-Flash
    -- offset, guarded by a single cooldown + pending flag so one anim can't double-fire. Narrow id list = it
    -- NEVER flashes randomly, and it flashes at the correct frame when you actually swing into a BF.
    local bfPending = false
    local function bfOnChar(char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 6); if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 6); if not animator then return end
        if animator:GetAttribute("VXBFM1Hooked") then return end
        animator:SetAttribute("VXBFM1Hooked", true)
        animator.AnimationPlayed:Connect(function(track)
            if not (Settings.BFM1 or Settings.AutoBF) then return end
            local id = track.Animation and track.Animation.AnimationId
            local dly = id and AnimationTriggers[id]
            -- Otherwise ANY real M1 swing of THIS character rides the standard window. VX_IS_M1 requires a real
            -- click within 0.4s, so it fires only on genuine M1s, never randomly, and works on every character.
            if not dly and _G.VX_IS_M1 and _G.VX_IS_M1(track) then dly = 0.19 end
            if not dly then return end
            -- SAME RULE AS THE CHAIN: swinging at thin air must not burn a Black Flash. Nobody within
            -- engagement range = no flash at all.
            -- EXCEPT mid-chain: a dash mode has already picked and validated its target, and this hook fires
            -- while the arc may still be moving you. Re-gating here would cancel the flash the chain exists to
            -- produce - which is the "the other modes dash but never flash" failure.
            if not R.bfActive and not targetInChainRange() then
                if _G.VX_BF_DEBUG then print("[DreamHub BF] M1 BF: nobody in range - not flashing") end
                return
            end
            if bfPending or tick() - R.bfCD < Settings.BFCooldown then return end
            bfPending = true
            task.delay(dly, function()
                bfPending = false
                if (Settings.BFM1 or Settings.AutoBF) and tick() - R.bfCD >= Settings.BFCooldown then R.bfCD = tick(); pressBF() end
            end)
        end)
    end
    task.spawn(function()
        if LocalPlayer.Character then pcall(bfOnChar, LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.25); pcall(bfOnChar, c) end)
        while true do task.wait(1)   -- JJS body lives under workspace.Characters; re-hook it (and after respawn)
            local chs = workspace:FindFirstChild("Characters"); local b = chs and chs:FindFirstChild(LocalPlayer.Name)
            if b then pcall(bfOnChar, b) end
            if LocalPlayer.Character then pcall(bfOnChar, LocalPlayer.Character) end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, _)
        if UserInputService:GetFocusedTextBox() then return end
        local st = R.stamp[input.KeyCode]; if st and tick() - st < WIN then return end
        if input.KeyCode == Settings.BFKey and Settings.Enabled and Settings.Mode ~= "M1" then
            doBlackFlash(); return
        end
        -- CLICK path for BF: covers characters whose M1 anim isn't in the database (the anim path can't catch
        if input.UserInputType == Enum.UserInputType.MouseButton1 and (Settings.AutoBF or Settings.BFM1) then
            -- A chain is running and it owns the flash. This path pressing 3 as well is one of the duplicate
            -- key-3s ("it keeps pressing 3 when I only did once").
            if tick() < (R.chainUntil or 0) then return end
            if not R.bfActive and not targetInChainRange() then return end   -- same range rule as the anim path above
            if tick() - R.bfCD >= Settings.BFCooldown then
                R.bfCD = tick()
                task.delay(0.14, function() if Settings.AutoBF or Settings.BFM1 then pressBF() end end)
            end
        end
    end)
    LocalPlayer.CharacterAdded:Connect(ReleaseAll)

    -- OFF MEANS OFF: turning a mode off (or switching modes) used to leave the back-lock still running and your
    -- collisions still disabled, so it kept moving you after you thought you had stopped it. This tears
    -- everything down: lock cleared, collisions restored, held keys released, in-flight flags reset.
    local function vxbfStop()
        -- OFF MEANS OFF, INCLUDING WORK ALREADY SCHEDULED. Every chain queues task.delay callbacks (the flash
        -- retry, the engine hand-back). Without a generation stamp those still fire after you switch the mode
        -- off, which is "I turned it off and it still pressed 3".
        R.gen = (R.gen or 0) + 1
        R.chainUntil = 0
        -- Hand the flash engine back IMMEDIATELY on stop. Waiting for the queued hand-back is what let a mode
        -- you had already switched off keep flashing your next few M1s.
        _G.VX_BF_BORROWED = false; _G.VX_BF_BORROW_USED = 0
        if _G.VX_BFAPI_SET then pcall(function() _G.VX_BFAPI_SET(_G.VX_BFAPI_WANT == true) end) end
        R.lockTarget = nil; R.lockKind = nil; R.lockEnd = 0
        R.bfActive = false; R.curving = false
        _G.VX_BF_RECLICK = _G.VX_BF_RECLICK_USER ~= false   -- restore the user's re-click setting immediately
        pcall(lockClipOn)
        pcall(ReleaseAll)
        local p = GetRoot()
        if p then pcall(function() p.AssemblyLinearVelocity = Vector3.zero; p.AssemblyAngularVelocity = Vector3.zero end) end
    end
    -- M1 CHAIN: fires on EVERY real M1 (poll-based detector; the game sinks the click so InputBegan cannot see
    -- it). One M1 -> side dash around them -> black flash. No counting, no waiting for a 3rd swing.
    -- ═══ M1 CHAIN HONOURS "BF After (M1s)" ═══ "if you do two M1s it will do it, one M1 it would do, three
    -- M1s it would do it" - the same selector that governs M1 BF now governs the chain, instead of the chain
    -- firing on every single click. Counted off REAL swings (the animation hook), not clicks, because a held
    -- button produces four swings from one click.
    local chainSwings, chainLastSwing, chainFiredAt = 0, 0, 0
    _G.VX_CHAIN_COUNT = function()
        if not (Settings.Enabled and Settings.Mode == "M1") then return end
        -- ═══ NO CLICK = NO CHAIN ═══ "when I don't even click it glides/TPs around and M1s". This is driven
        -- off the swing counter, and that counter accepts any Action-priority animation for characters whose
        -- M1 ids were never captured - so a dash, an ability, or another module's injected swing all looked
        -- like an M1 and launched a whole chain. _G.VX_LAST_CLICK is stamped only by the real mouse poll, so
        -- requiring a click inside 0.4s means the chain can only ever run off something you actually did.
        if (tick() - (tonumber(_G.VX_LAST_CLICK) or 0)) > 0.40 then
            if _G.VX_BF_DEBUG then print("[DreamHub BF] chain: swing with no real click behind it - ignored") end
            return
        end
        -- And never off OUR OWN injected click (the chain's own M1 would retrigger the chain).
        if tick() < (tonumber(_G.VX_SYNTH_CLICK) or 0) then return end
        local nowT = tick()
        -- ═══ ONE CHAIN PER COMBO ═══ A held click produces FOUR swings ~0.35s apart, and this used to fire a
        -- fresh chain every time the count came round - "one M1 equals three M1s and three black flashes".
        -- After a chain fires, every further swing of the SAME combo is ignored; the window only reopens after
        -- the combo has actually dropped (1.2s of silence, the game's own combo timeout).
        if nowT - chainFiredAt < 1.2 then chainLastSwing = nowT; return end
        if nowT - chainLastSwing > 1.2 then chainSwings = 0 end   -- JJS drops a combo at ~1.2s
        chainLastSwing = nowT
        chainSwings = chainSwings + 1
        local need = math.clamp(tonumber(_G.VX_BF_AFTER) or 1, 1, 3)
        if chainSwings < need then
            if _G.VX_BF_DEBUG then print("[DreamHub BF] chain: swing " .. chainSwings .. "/" .. need) end
            return
        end
        chainSwings = 0
        chainFiredAt = nowT
        doBFM1Chain()
    end
    if _G.VX_M1_SUB then
        -- Kept as a fallback for characters whose swings never reach the animation hook: if no swing has been
        -- counted for a while, treat the raw click as the swing so the chain still works.
        _G.VX_M1_SUB("vxbf2_m1chain", function()
            if not (Settings.Enabled and Settings.Mode == "M1") then return end
            if tick() - chainLastSwing < 1.2 then return end   -- the animation path is counting; don't double
            _G.VX_CHAIN_COUNT()
        end)
    end

    _G.VXBF2 = {
        setEnabled = function(v) Settings.Enabled = v == true; if not Settings.Enabled then vxbfStop() end end,
        setMode = function(m) if type(m) == "string" then vxbfStop(); Settings.Mode = m end end,   -- Side Dash / Back Dash / Jump / Teleport / M1
        setBFM1 = function(v) Settings.BFM1 = v == true end,
        setAutoBF = function(v) Settings.AutoBF = v == true end,
        setSideAssist = function(v) Settings.SideAssist = v == true end,
        setBackAssist = function(v) Settings.BackAssist = v == true end,
        setCooldown = function(v) if type(v) == "number" then Settings.BFCooldown = v end end,
        setTeleportDist = function(v) if type(v) == "number" then Settings.BFTeleportDist = v end end,
        doSide = function() doSideDash(false) end,
        doBack = function() doBackDash(false) end,
    }
    -- assist keys: Q = side dash assist, E = back dash assist (only when their toggle is on)
    UserInputService.InputBegan:Connect(function(input, _)
        if UserInputService:GetFocusedTextBox() then return end
        local st = R.stamp[input.KeyCode]; if st and tick() - st < WIN then return end
        if input.KeyCode == Enum.KeyCode.Q and Settings.SideAssist and not Settings.Enabled then doSideDash(false) end
        if input.KeyCode == Enum.KeyCode.E and Settings.BackAssist then doBackDash(false) end
    end)
end

-- ============================================================
-- MODULE: AUTO MAHITO GRAB ESCAPE  (when Mahito grabs you, spam SPACE to break out)
-- Detects the Mahito grab animation (rbxassetid://72343192576784) playing on ANY nearby character; while it's
-- up, spam the spacebar (the grab-escape QTE) so you mash out automatically.
-- ============================================================
do
    local Players = game:GetService("Players")
    local VIM = game:GetService("VirtualInputManager")
    local LP = Players.LocalPlayer
    local enabled = false
    -- The grab shows a "JUMP TO ESCAPE!" QTE with a fill bar. We mash Space CONTINUOUSLY the WHOLE time that
    -- prompt is on screen (a fixed burst only filled part of the bar). We detect the prompt by its text.
    local function labelSaysEscape(d)
        if not (d:IsA("TextLabel") and d.Visible) then return false end
        local t = string.lower(d.Text or "")
        return (t:find("jump to escape") ~= nil) or (t:find("escape") ~= nil and t:find("jump") ~= nil)
    end
    local function escapePromptUp()
        -- The "JUMP TO ESCAPE!" prompt is a BILLBOARD over the grabbed character (in the world), NOT PlayerGui.
        -- Scan BOTH: your character's billboards (workspace.Characters[you]) + PlayerGui.
        local chs = workspace:FindFirstChild("Characters"); local me = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
        if me then for _, d in ipairs(me:GetDescendants()) do if labelSaysEscape(d) then return true end end end
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then for _, d in ipairs(pg:GetDescendants()) do if labelSaysEscape(d) then return true end end end
        return false
    end
    task.spawn(function()
        while true do
            if enabled and escapePromptUp() then
                pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.015); VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                task.wait(0.03)   -- hammer Space fast until the prompt disappears
            else
                task.wait(0.12)
            end
        end
    end)
    MahitoGrabApi = { set = function(v) enabled = v == true end }
end

-- MODULE: AUTO SKILLS  (press chosen keys 1/2/3/4 on a nearby enemy)
do
	local Players = game:GetService("Players")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer
	local enabled, rate, range = false, 0.4, 30
	local keys = { [1] = false, [2] = false, [3] = false, [4] = false, [5] = false, [6] = false }
	local KC = { [1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three, [4] = Enum.KeyCode.Four, [5] = Enum.KeyCode.R, [6] = Enum.KeyCode.G }
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end  -- JJS body lives under workspace.Characters
	local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end
	local function nearestEnemyHRP()  -- the NEAREST living enemy in range (correct target, not a stale LP.Character read)
		local hrp = myHRP(); if not hrp then return nil end
		local _g=_G.VX_LOCK; local _lt=(_g and _g.manualActive and _g.manualActive() and _g.get) and _g.get() or nil   -- LOCK TARGET wins over any range scan
		if _lt and _lt.Parent then local _lh=_lt:FindFirstChildOfClass("Humanoid"); local _lr = _lt:FindFirstChild("HumanoidRootPart"); if _lr and (not _lh or _lh.Health > 0) then return _lr end end
		local best, bd
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local h = m:FindFirstChildOfClass("Humanoid"); local r = m:FindFirstChild("HumanoidRootPart"); if h and h.Health > 0 and r then local d = (r.Position - hrp.Position).Magnitude; if d <= range and (not bd or d < bd) then best, bd = r, d end end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chars = workspace:FindFirstChild("Characters"); if chars then for _, m in ipairs(chars:GetChildren()) do chk(m) end end
		return best
	end
	local function faceEnemy(tr) local hrp = myHRP(); if hrp and tr and tr.Parent then pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tr.Position.X, hrp.Position.Y, tr.Position.Z)) end) end end  -- aim at them so the skill lands on the RIGHT target
	local function press(kc)
		_G.VX_INJECT_UNTIL = tick() + 0.35   -- OUR press: feints / Auto Air / Reversal Red must not chain off it
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[kc] = tick() + 0.5
		pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(0.09); VIM:SendKeyEvent(false, kc, false, game) end)  -- longer hold so the game reliably registers the key
	end
	local cycleIdx = 0
	task.spawn(function()
		while true do
			if enabled then
				-- PRESS THE KEY NO MATTER WHAT (user: "when I click 1 it clicks 1"). The old enemy-in-30-studs
				-- gate meant nothing happened unless someone stood next to you = "auto skills don't work".
				-- If an enemy IS around we still face them first so the cast lands on the right target.
				local tried = 0
				repeat cycleIdx = (cycleIdx % 6) + 1; tried = tried + 1 until keys[cycleIdx] or tried >= 6
				if keys[cycleIdx] then
					local tr = nearestEnemyHRP()
					if tr then if _G.VX_ACPASS then _G.VX_ACPASS() end faceEnemy(tr); task.wait(0.03) end
					press(KC[cycleIdx])
				end
				task.wait(rate)
			else task.wait(0.2) end
		end
	end)
	SkillsApi = {
		setEnabled = function(v)
			enabled = v == true
			-- NO auto-default: master ON presses ONLY the skills you toggled (it used to force 1-4 on,
			-- which pressed 3 etc before you picked anything).
		end,
		setKey = function(n, v)
			if KC[n] then
				keys[n] = v == true
				if v then enabled = true
				else
					local any = false; for i = 1, 6 do if keys[i] then any = true break end end
					if not any then enabled = false end   -- last skill toggled OFF -> the system fully stops (OFF means OFF)
				end
			end
		end,
		setRate = function(v) if type(v) == "number" then rate = v end end,
	}
end

-- MODULE: INVISIBILITY  (client + replicated transparency, RE-ASSERTED every frame so the game's animations can't un-hide you. You can still move + attack normally.)
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local on = false
	local parts = {}   -- cached BaseParts of your body (rebuilt on toggle / respawn) so the per-frame re-assert is cheap
	local function bodies()
		local t = {}
		local c1 = LP.Character; if c1 then t[#t + 1] = c1 end
		local chs = workspace:FindFirstChild("Characters"); local c2 = chs and chs:FindFirstChild(LP.Name); if c2 and c2 ~= c1 then t[#t + 1] = c2 end
		return t
	end
	local function rebuild()
		parts = {}
		for _, m in ipairs(bodies()) do
			for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end
		end
	end
	local function setVis(hidden)
		rebuild()
		for _, p in ipairs(parts) do
			if p.Name ~= "HumanoidRootPart" then pcall(function() p.Transparency = hidden and 1 or 0 end) end   -- REPLICATED transparency = others can't see you either
			pcall(function() p.LocalTransparencyModifier = hidden and 1 or 0 end)
		end
		for _, m in ipairs(bodies()) do
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("Decal") or d:IsA("Texture") then pcall(function() d.Transparency = hidden and 1 or 0 end)
				elseif d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Trail") then pcall(function() d.Enabled = not hidden end) end
			end
		end
	end
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		if not on then return end
		acc = acc + (dt or 0.016)
		if acc > 1 then acc = 0; rebuild() end   -- refresh the part list (respawns / gear / transformations add new limbs)
		for _, p in ipairs(parts) do
			if p.Parent then pcall(function()
				if p.Name ~= "HumanoidRootPart" then p.Transparency = 1 end   -- RE-ASSERT the REPLICATED transparency every frame: the game can't un-hide you, and OTHERS stay unable to see you
				p.LocalTransparencyModifier = 1
			end) end
		end
	end)
	LP.CharacterAdded:Connect(function() task.wait(0.4); if on then setVis(true) end end)   -- re-hide decals / particles after a respawn
	InvisApi = { set = function(v) on = v == true; setVis(on) end }
end

-- MODULE: AUTO PARKOUR  (real parkour anim sequence jump->park->fall->land + wall-climb velocity + the Parkour remote)
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on, last, climbing = false, 0, false
	local ANIMS = { jump = "rbxassetid://134343219970072", parkRight = "rbxassetid://113609963676386", parkLeft = "rbxassetid://94327920127463", fall = "rbxassetid://126572575938378", land = "rbxassetid://97446412066176" }
	local tracks = {}
	local sideTracks = {}   -- declared here so the shared animator-cache invalidator below can clear it
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end
	local function animatorOf() local c = myChar(); local h = c and c:FindFirstChildOfClass("Humanoid"); return h and h:FindFirstChildOfClass("Animator") end
	-- ANIMATION CACHE INVALIDATION: a respawn/character swap creates a NEW Animator, and a track loaded on the
	-- old one just silently refuses to play - which is exactly "parkour works but does no animation".
	local trackAnimator = nil
	local function freshAnimator()
		local a = animatorOf()
		if a ~= trackAnimator then trackAnimator = a; table.clear(tracks); table.clear(sideTracks) end
		return a
	end
	local function play(key)
		local a = freshAnimator(); if not a then return end
		local t = tracks[key]
		if not t then local anim = Instance.new("Animation"); anim.AnimationId = ANIMS[key]; local ok, tr = pcall(function() return a:LoadAnimation(anim) end); if ok and tr then t = tr; tracks[key] = tr end end
		if t then pcall(function() t:Play() end) end
	end
	local function exclude()  -- ray filter: your body + EVERY character (an enemy you're fighting must NOT count as a "wall") + effects
		local list = { myChar() }
		for _, plr in ipairs(Players:GetPlayers()) do if plr.Character then list[#list + 1] = plr.Character end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do list[#list + 1] = m end end
		local eff = workspace:FindFirstChild("Effects"); if eff then list[#list + 1] = eff end
		return list
	end
	local function wallNear()  -- a REAL wall within reach ahead or to a side (players/enemies excluded)
		local hrp = myHRP(); if not hrp then return false end
		local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances = exclude()
		for _, dir in ipairs({ hrp.CFrame.LookVector, hrp.CFrame.RightVector, -hrp.CFrame.RightVector, -hrp.CFrame.LookVector }) do
			if workspace:Raycast(hrp.Position, dir * 8, p) then return true end   -- wider reach so a wall is actually detected
		end
		return false
	end
	local function sideTrack(key)  -- looped wall-run track per side (parkLeft / parkRight)
		local a = freshAnimator(); if not a then return nil end
		if sideTracks[key] then return sideTracks[key] end
		local anim = Instance.new("Animation"); anim.AnimationId = ANIMS[key]
		local ok, t = pcall(function() return a:LoadAnimation(anim) end)
		if ok and t then t.Looped = true; sideTracks[key] = t end
		return sideTracks[key]
	end
	local function stopSides() for _, t in pairs(sideTracks) do if t.IsPlaying then pcall(function() t:Stop() end) end end end
	local function forwardWall()  -- a REAL wall DIRECTLY ahead (you're running into it) = climb; players/enemies excluded so fighting doesn't launch you
		local hrp = myHRP(); if not hrp then return false end
		local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances = exclude()
		return workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 4.5, p) ~= nil
	end
	local function doClimb()  -- jump INTO a wall = vault + climb up
		if climbing then return end
		local hrp = myHRP(); if not hrp then return end
		climbing = true
		fireKnit("MovementService", "Parkour"); play("jump"); vxLog("Parkour")
		task.spawn(function()
			for _ = 1, 10 do local h = myHRP(); if not h then break end pcall(function() h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, 44, h.AssemblyLinearVelocity.Z) end) task.wait(0.03) end
			play("fall"); task.wait(0.35); play("land"); climbing = false
		end)
	end
	RunService.Heartbeat:Connect(function()
		if not on then return end
		local hrp = myHRP(); if not hrp then return end
		local c = myChar(); local hum = c and c:FindFirstChildOfClass("Humanoid")
		local airborne = hum ~= nil and hum.FloorMaterial == Enum.Material.Air
		local rising = hrp.AssemblyLinearVelocity.Y > 2                            -- you jumped / are going up
		local intoWall = UIS:IsKeyDown(Enum.KeyCode.W) and forwardWall()           -- running INTO a wall on the ground also counts
		-- parkour when airborne/rising near a wall OR running straight into one.
		if ((airborne or rising) and wallNear() or intoWall) and not climbing then
			-- movement key -> anim (swapped to match in-game: A/going-left uses the right-lean clip, D/going-right uses the left-lean clip)
			local key = (UIS:IsKeyDown(Enum.KeyCode.A) and "parkRight") or (UIS:IsKeyDown(Enum.KeyCode.D) and "parkLeft") or "parkRight"
			for k, t in pairs(sideTracks) do if k ~= key and t.IsPlaying then pcall(function() t:Stop() end) end end  -- stop the other side's anim
			local pt = sideTrack(key); if pt and not pt.IsPlaying then pcall(function() pt:Play() end) end            -- PLAY the anim for your movement direction
			if forwardWall() then pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 34, hrp.AssemblyLinearVelocity.Z) end) end  -- CLIMB only when a wall is directly AHEAD (no launching past side walls)
			if tick() - last >= 0.35 then last = tick(); fireKnit("MovementService", "Parkour") end
		else
			stopSides()
		end
	end)
	UIS.InputBegan:Connect(function(input, gpe)
		if on and not gpe and input.KeyCode == Enum.KeyCode.Space and wallNear() then doClimb() end
	end)
	ParkourApi = { set = function(v) on = v == true; if not on then stopSides() end end }
end

-- MODULE: TELEPORT  (anti-setback glide bypass + named JJS locations + saved spots)
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local slots = { nil, nil, nil }
	local SPOTS = {  -- user-saved coordinate spots (ordered so the dropdown keeps this order)
		{ "Main Map", Vector3.new(-16.2, 24.4, 14.1) },
		{ "Leaderboard", Vector3.new(51.8, 23.6, -96.0) },
		{ "Cute", Vector3.new(261.7, 61.8, 467.6) },
		{ "Green screen", Vector3.new(292.8, 23.7, 169.2) },
		{ "Mall", Vector3.new(76.4, -60.2, -262.6) },
		{ "Train", Vector3.new(168.8, -9.7, 158.5) },
		{ "Train spawner", Vector3.new(182.3, 0.1, 557.0) },
		{ "tze place", Vector3.new(-49.1, 37.6, 255.7) },
		{ "Blue buildings", Vector3.new(32.7, 197.1, 136.9) },
		{ "sewer", Vector3.new(-88.5, -30.1, -153.5) },
		{ "arcade", Vector3.new(244.1, 25.2, -49.2) },
		{ "Death (not real death)", Vector3.new(218.3, 24.1, -130.3) },
		{ "DEATH", Vector3.new(377.3, -3.9, -113.1) },
		{ "BILLBOARD", Vector3.new(-217.5, 55.2, -0.9) },
		{ "HOME", Vector3.new(265.3, 73.0, 120.3) },
		{ "GET SOME MILK", Vector3.new(-240.9, 28.9, -124.2) },
	}
	local function hrp() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end  -- JJS body lives under workspace.Characters
	local function locate(names)
		for _, nm in ipairs(names) do
			local obj = workspace:FindFirstChild(nm, true)
			if obj then
				if obj:IsA("BasePart") then return obj.Position end
				local ok, cf = pcall(function() return obj.GetBoundingBox and select(1, obj:GetBoundingBox()) or nil end)
				if ok and typeof(cf) == "CFrame" then return cf.Position end
				local ok2, pv = pcall(function() return obj:GetPivot() end)
				if ok2 and typeof(pv) == "CFrame" then return pv.Position end
			end
		end
		return nil
	end
	TPApi = {
		setSpeed = function(v) if type(v) == "number" then _G.VX_TP_SPEED = v end end,
		setMethod = function(m) if type(m) == "table" then m = m[1] end _G.VX_TP_METHOD = (m == "Instant" or m == "Glide" or m == "Anchor") and m or "Auto"; _G.VX_TP_USER_METHOD = _G.VX_TP_METHOD end,   -- "Reset" REMOVED: it killed you to get a clean position baseline, which is not a trade worth making
		up = function() local r = hrp(); if r then vxTeleportHard(r.Position + Vector3.new(0, 120, 0), 1.25) end end,
		spawn = function()
			-- FindFirstChildOfClass is NOT recursive; JJS spawns sit inside workspace.Map, so the old call found
			-- nothing on most maps and the button silently did nothing.
			local sp = workspace:FindFirstChildOfClass("SpawnLocation") or workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			if sp then vxTeleportHard(sp.Position + Vector3.new(0, 4, 0), 1.25)
			elseif VX_NOTIFY then VX_NOTIFY("No SpawnLocation found on this map", false) end
		end,
		nearest = function()
			local r = hrp(); if not r then return end
			local best, bd
			local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local h = m:FindFirstChildOfClass("Humanoid"); local rr = m:FindFirstChild("HumanoidRootPart"); if h and h.Health > 0 and rr then local d = (rr.Position - r.Position).Magnitude; if not bd or d < bd then best, bd = rr, d end end end end
			for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
			local chars = workspace:FindFirstChild("Characters"); if chars then for _, m in ipairs(chars:GetChildren()) do chk(m) end end
			if best then vxTeleportHard(best.Position, 2) end
		end,
		location = function(names) local p = locate(names); if p then vxTeleportHard(p + Vector3.new(0, 5, 0), 1.25) elseif VX_NOTIFY then VX_NOTIFY("Location '" .. tostring(names[1]) .. "' not found", false) end return p ~= nil end,
		save = function(n) local r = hrp(); if r then slots[n] = r.Position end end,
		goto_ = function(n) if slots[n] then vxTeleportHard(slots[n], 1.25) end end,
		spotNames = function() local t = {}; for _, s in ipairs(SPOTS) do t[#t + 1] = s[1] end return t end,
		spot = function(name) for _, s in ipairs(SPOTS) do if s[1] == name then vxTeleportHard(s[2] + Vector3.new(0, 4, 0), 2); return true end end return false end,  -- stepped teleport + 2s hold (4s of being pinned after arriving felt broken)
		playerNames = function() local t = {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then t[#t + 1] = plr.Name end end return t end,   -- list other players
		tpPlayer = function(name)  -- teleport just BEHIND a chosen player (setback-resistant)
			local hrpTarget
			local plr = name and Players:FindFirstChild(name)
			if plr and plr.Character then hrpTarget = plr.Character:FindFirstChild("HumanoidRootPart") end
			if not hrpTarget then local chs = workspace:FindFirstChild("Characters"); local mdl = chs and chs:FindFirstChild(name); hrpTarget = mdl and mdl:FindFirstChild("HumanoidRootPart") end
			if hrpTarget then vxTeleportHard(hrpTarget.Position - hrpTarget.CFrame.LookVector * 4 + Vector3.new(0, 3, 0), 1.25); return true end
			if VX_NOTIFY then VX_NOTIFY("Player '" .. tostring(name) .. "' not found", false) end
			return false
		end,
	}
end

-- MODULE: M1 COMBO  (Down Slam / Uppercut for EVERY character)
-- Counts your REAL M1 hits by ANIMATION using the full per-character M1 id database (_G.VX_M1_IDS - all 20
-- fires at the wrong combo step ('auto uppercut no work'). An M1 ANIM only plays when your character
-- actually swings - so hit #3 is exactly when the launcher window is open, on any character.
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer
	local mode, lastSwing, count, busy = "Off", 0, 0, false
	local needHits = 3   -- chain hits before the launcher fires (slider-adjustable: characters have different chain lengths)
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function act(arg)
		local svc = vxMyCharSvc()
		if svc then
			fireKnit(svc, "Activated", arg)
		else
			for _, c in ipairs(CHAR_NAMES) do fireKnit(c .. "Service", "Activated", arg) end   -- char not detected: hit all 21 - only YOURS exists server-side
		end
	end
	local function realM1()  -- a REAL M1 click at screen center: the game's own input converts held-space M1 -> uptilt / airborne falling M1 -> slam
		-- FACE THE TARGET FIRST. A centre-screen click whiffs entirely if nobody is in front of you, and a
		-- whiffed swing produces no slam/uppercut no matter how the timing is set up.
		pcall(function()
			local c = myModel(); local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local best, bd
			local function chk(m)
				if not m or m.Name == LP.Name or m == LP.Character then return end
				local r = m:FindFirstChild("HumanoidRootPart"); local hh = m:FindFirstChildOfClass("Humanoid")
				if r and (not hh or hh.Health > 0) then
					local d = (r.Position - hrp.Position).Magnitude
					if d < 18 and (not bd or d < bd) then best, bd = r, d end
				end
			end
			for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do if pl ~= LP then chk(pl.Character) end end
			local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
			if best then hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(best.Position.X, hrp.Position.Y, best.Position.Z)) end
		end)
		local cam = workspace.CurrentCamera; local v = (cam and cam.ViewportSize) or Vector2.new(800, 600)
		pcall(function() VIM:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, true, game, 0); task.wait(0.04); VIM:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, false, game, 0) end)
	end
	local function jump()  -- small BUNNY HOP for the DOWN SLAM (a 50-stud rocket looked obvious)
		_G.VX_LAUNCHING = tick()  -- tell Side Dash (its flat dash clamps Y) to stand down for a moment so it can't cancel this lift
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Space] = tick() + 0.5
		local c = myModel()
		local h = c and c:FindFirstChildOfClass("Humanoid"); local hrp = c and c:FindFirstChild("HumanoidRootPart")
		pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.02); VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)  -- real Space press
		if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end                                          -- force jump state
		if hrp then pcall(function() local v = hrp.AssemblyLinearVelocity; hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 26), v.Z) end) end  -- nudge to hop height only = natural bunny hop
	end
	-- (Removed: dead duplicate `finisher()`/`note()` from an earlier rewrite — the LIVE trigger below is the only
	-- uppercut/downslam implementation now. Per user spec: UPPERCUT = hold Space + 4 M1s; DOWN SLAM = 3 M1s, jump, M1.)
	-- FULL per-character UPPERCUT M1 database (user-captured): every swing of every character's M1 chain,
	-- so the 3-swing count works on ALL of them. The old DB only had SOME swings per character -> the count
	-- never reached 3 on most characters ('auto uppercut/downslam no work').
	-- NOT captured yet (uppercut coming soon): Crow (Mei Mei), Mangaka, Black Death, Disaster Plants.
	local UPPERCUT_M1 = {
		-- Vessel                Gojo                    Restless
		"95295463826732","105077924973072","124862357369335","134243365075812",
		"127851700400958","72548435296350","84547415708554",
		"94588892125071","97868312130612","140588454098230","109299799610861",
		-- 92966188946988 = the AIRBORNE attack swing, captured from a live recording and previously unknown to
		-- this file at all. In the capture it plays on every air M1 and is always followed by a landing at
		-- ~-42 Y velocity, i.e. it IS the down slam swing. Without it here an airborne M1 counted as no swing,
		-- which is exactly why the armed slam never landed.
		"92966188946988",
		-- Ten Shadows           Perfection              Blood Main
		"75337033003776","138489871864252","96185406489877",
		"126277739156443","99710481887795","121322029260156","98845475810982",
		"119042572747325",
		-- Switcher              Defense Attorney        Cursed Part (Yuta)
		"96327114254575","107029561762376","117831239064143",
		"133936641185614","122573730331631","82400997593751","115586282387431",
		"133240987753043","130806585141471","131967150738931","73456086297777",
		-- Puppet Master         Head of Hei             Salary Man
		"98783064085844","85148168523745","108686045412945",
		"101283990868172","108708446862011","77583711129628","116910683335467",
		"84359513001979","79436586236026","102285403332509","78540777177847",
		-- True Cannon           Locust                  Star Rage             Lucky Coward
		"139479927693015","85068785050521","120133391090244","79086910454958","108027796023968","138196552148011",
		"131909724908049","72575786212990","119248903710146",
		"133447840605824","113963875117859","106282708121342",
	}
	local COMBO_IDS = {}
	for _, id in ipairs(UPPERCUT_M1) do COMBO_IDS[id] = true end
	if _G.VX_M1_IDS then for id in pairs(_G.VX_M1_IDS) do COMBO_IDS[id] = true end end   -- merge with the master DB (never clobber)
	for id in pairs(COMBO_IDS) do if _G.VX_M1_IDS then _G.VX_M1_IDS[id] = true end end   -- and feed the new ids BACK so every module sees them
	-- ═══════════ v5 (user's script, ported FAITHFULLY - this is the version that works) ═══════════
	--   Down: fire "Down" instantly with every M1 (the working path, untouched)
	--   Up  : Space held from the 3rd M1; on the 4th, wait for the game's own M1 to register (0.15s),
	--         THEN fire "Up" — no race, no t=0 fire.
	-- Exactly ONE change from the standalone: no `if gp then return end` (this game marks every M1 click
	-- game-processed, so the standalone's gpe bail would stop it from EVER firing inside the hub).
	-- eating your REAL clicks = "uppercut/downslam not working".
	local Config = {
		Cooldown = 0.12,   -- was 0.30: longer than a JJS swing, so it swallowed every other real M1
		Manual   = nil,
		UpArg          = "Up",
		UpFireDelay    = 0.15,  -- wait for the game's own 4th M1 to register, then fire
		UpFireDelay2   = 0.30,  -- insurance second fire
		M1ResetWindow  = 1.20,  -- clicks farther apart than this reset the combo count
		SpaceHold      = 0.45,  -- Space released this long after the 4th M1
	}
	local V5CharNames = {
		"Itadori", "Gojo", "Hakari", "Megumi", "Mahito", "Choso", "Todo",
		"Hiromi", "Yuta", "Mechamaru", "Naoya", "Nanami", "Hanami", "Ryu",
		"Locust", "Yuki", "Charles", "Haruta", "MeiMei", "Kurourushi", "Sukuna",
	}
	local State = { char = nil, remote = nil, lastFire = 0, m1Count = 0, lastM1 = 0, spaceHeld = false, downHeld = false, spaceToken = nil }
	local function scanFor(container, lowerName)
		if not container then return false end
		for aName, aVal in pairs(container:GetAttributes()) do
			if string.find(string.lower(aName), lowerName, 1, true)
				or string.find(string.lower(tostring(aVal)), lowerName, 1, true) then
				return true
			end
		end
		return false
	end
	local function detectCharacter()
		if Config.Manual and Config.Manual ~= "" then return Config.Manual end
		local char = myModel()   -- JJS keeps your real body under workspace.Characters; LP.Character is often the wrong rig
		if not char then return nil end
		for _, name in ipairs(V5CharNames) do
			local ln = string.lower(name)
			if scanFor(LP, ln) or scanFor(char, ln) then return name end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and scanFor(hum, ln) then return name end
			for _, v in ipairs(char:GetDescendants()) do
				if string.find(string.lower(v.Name), ln, 1, true) then return name end
				if (v:IsA("StringValue") or v:IsA("ObjectValue"))
					and v.Value and string.find(string.lower(tostring(v.Value)), ln, 1, true) then
					return name
				end
			end
		end
		return nil
	end
	local function resolveV5Remote()
		State.remote = nil
		if not State.char then return end
		local knit = game:GetService("ReplicatedStorage"):FindFirstChild("Knit")
		knit = knit and knit:FindFirstChild("Knit")
		local services = knit and knit:FindFirstChild("Services")
		local svc = services and services:FindFirstChild(State.char .. "Service")
		local re  = svc and svc:FindFirstChild("RE")
		State.remote = re and re:FindFirstChild("Activated")
	end
	local function refreshDetection()
		local d = detectCharacter()
		if d and d ~= State.char then
			State.char = d
			resolveV5Remote()
		elseif State.char and not State.remote then
			resolveV5Remote()
		end
	end
	local function fireDir(dir)
		-- Fire BOTH the v5-resolved remote AND the hub's per-char resolver (act = your <Char>Service, or all 21
		-- if undetected — only YOURS responds server-side). Guarantees the correct Activated("Down"/"Up") lands
		-- even when v5 character detection misses = "auto down slam / uppercut doesn't work" fix.
		-- EXACT captured shape: <Char>Service.RE.Activated:FireServer("Down") / ("Up") - one string, no nil.
		-- ═══ WHY THIS USED TO GIVE UP TOO EARLY ═══ `fired` was set from pcall(), and pcall succeeds as long as
		-- the CALL did not error. Firing the WRONG character's Activated remote does not error - it is simply
		-- ignored server-side - so a mis-resolved service still set fired = true and the fallbacks below never
		-- ran. pcall tells us "sent", never "accepted". So we now branch on whether we actually RESOLVED your
		-- character, not on whether a send succeeded.
		local svcName = vxMyCharSvc()                     -- scans moveset -> name -> services
		local resolved = false
		if svcName then
			local svcs = game:GetService("ReplicatedStorage"):FindFirstChild("Knit")
			svcs = svcs and svcs:FindFirstChild("Knit"); svcs = svcs and svcs:FindFirstChild("Services")
			local sv = svcs and svcs:FindFirstChild(svcName)
			local re = sv and sv:FindFirstChild("RE"); re = re and re:FindFirstChild("Activated")
			if re then
				resolved = true
				local ok = pcall(function() re:FireServer(dir) end)
				if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] fired " .. svcName .. '.RE.Activated("' .. dir .. '") -> ' .. tostring(ok)) end
			end
		end
		-- The v5 resolver is a SEPARATE detection path, so fire it too rather than only as a fallback: when the
		-- two disagree one of them is right, and the wrong one is a no-op. Two sends, not eleven.
		if State.remote then
			local ok = pcall(function() State.remote:FireServer(dir) end)
			if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] also fired State.remote -> " .. tostring(ok)) end
		end
		if not resolved and not State.remote then
			-- Nothing identified your character at all. Sweep the real character services - only yours answers,
			-- and this is the difference between "does nothing" and "works". Set _G.VX_M1_NOSWEEP = true to
			-- opt out if you would rather it stay quiet than send a burst.
			-- ═══ SWEEP IS NOW OPT-IN (_G.VX_M1_SWEEP = true) ═══ It fired up to 11 OTHER characters' Activated
			-- remotes in one frame on every finisher. Firing remotes for characters you do not own is exactly
			-- the pattern a server anti-cheat flags, and a 267 kick followed a session with it on. Detection
			-- failing should mean "nothing happens", never "you get kicked".
			if _G.VX_M1_SWEEP then
				for _, nm in ipairs({ "Itadori", "Gojo", "Megumi", "Hakari", "Choso", "Locust", "Mahito", "MeiMei", "Toji", "Yuta", "Sukuna" }) do
					if vxSvcHasActivated(nm .. "Service") then pcall(function() fireKnit(nm .. "Service", "Activated", dir) end) end
				end
			end
			if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] no service resolved - swept the known character services") end
		end
	end
	-- ═══ WHY THE SPACE HOLD IS BACK ═══
	-- Deleting spaceDown() killed the uppercut outright ("dont even work at all"). So the direction is NOT
	-- carried by the remote argument alone: JJS reads your held MOVEMENT KEY at the moment the swing lands and
	-- the remote only names it. Up = Space, Down = S. Both have to be held across the swing.
	-- The actual cause of "it makes me jump when I don't M1" was never the Space press itself - it was
	-- onSwing() firing on animations that were not real M1s (the character-agnostic fallback counts any
	-- Action-priority track). So the press is restored and the TRIGGER is what got tightened: realM1Now()
	-- below requires a genuine click inside 0.4s, and nothing in this module acts without it.
	-- ═══ UP IS W, NOT SPACE ═══ Down Slam works and Uppercut does not, and the ONLY difference between them
	-- was the key each holds: the slam holds S, the uppercut held Space. Space is JUMP, not a direction - so
	-- the uppercut was hopping you instead of naming a direction, which is both why it did nothing and why it
	-- made you jump. S means "down", so the symmetric key for "up" is W. Same shape as the slam now.
	local function spaceDown()
		if State.spaceHeld then return end
		State.spaceHeld = true
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.W] = tick() + 3   -- our own key: Auto Air/feints must ignore it
		VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
	end
	local function spaceUp()
		if not State.spaceHeld then return end
		State.spaceHeld = false
		VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
		pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)   -- release any Space an older build left held
	end
	-- DOWN SLAM / UPPERCUT are decided by your PHYSICAL STATE (airborne / holding space), not by a string
	-- argument. The old path fired Activated("Down"), which JJS does not accept - so nothing happened. Both
	-- modes now reproduce what a real player does with real inputs.
	-- RESTORED to the version that worked: Down Slam fires the real direction remote, Uppercut counts to 4
	-- while holding Space. The bug was never this logic - it was the TRIGGER (InputBegan never fires for a
	-- sunk attack click). The trigger is now the shared poll; the behaviour below is byte-for-byte the
	-- original, so what worked on FREE works again.
	-- ═══ SWING COUNTING IS ANIMATION-DRIVEN, NOT CLICK-DRIVEN ═══
	-- Counting CLICKS is why Uppercut "only worked if I paused": you can click faster than the game swings,
	-- clicks get deduped/dropped by the input paths, and injected clicks from other features add phantom
	-- counts - so the count and the real combo drift apart. The per-character M1 ANIMATION database in this
	-- module (COMBO_IDS, built above) is exact: one entry plays per real landed swing. It was built and then
	-- never read by anything. Now it drives the counter, so 1-2-3-4 always matches what you actually threw.
	local slamArmed = 0   -- set after the hop; YOUR next M1 inside this window is the down slam
	-- ═══ THE ONE GATE THAT MATTERS ═══ Nothing in this module may act unless you REALLY clicked. The animation
	-- path counts any Action-priority track for characters whose M1 ids were never captured, so without this a
	-- dash / ability / hit-reaction animation counted as a swing - and with the Space hold restored that is
	-- literally "it jumps me when I don't M1". _G.VX_LAST_CLICK is stamped by the shared poll on real clicks
	-- only (injected clicks are excluded), so this is the honest "was that you" test.
	local function realM1Now()
		return (tick() - (tonumber(_G.VX_LAST_CLICK) or 0)) < 0.40
	end
	-- DOWN direction = holding S, the same way Up = holding Space. Movement keys never launch you, so this one
	-- needs no extra guard beyond realM1Now().
	local function downDown()
		if State.downHeld then return end
		State.downHeld = true
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.S] = tick() + 3
		VIM:SendKeyEvent(true, Enum.KeyCode.S, false, game)
	end
	local function downUp()
		if not State.downHeld then return end
		State.downHeld = false
		VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game)
	end
	local function airborneNow()
		local c0 = myModel(); local h0 = c0 and c0:FindFirstChildOfClass("Humanoid")
		if not h0 then return false end
		-- FloorMaterial is the primary test, but it lags a frame or two after a launch and reads Concrete while
		-- you are already rising. The humanoid STATE flips immediately, so accept either.
		if h0.FloorMaterial == Enum.Material.Air then return true end
		local st = h0:GetState()
		return st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
	end
	-- Captured ids for the AIRBORNE attack swing. Seeing one of these is proof you just air-M1'd, which is a
	-- down slam regardless of what FloorMaterial happens to say on that frame.
	local AIR_ATTACK_IDS = { ["92966188946988"] = true }
	-- ONE place fires the slam, with ONE cooldown, so the animation path and the raw-click path below cannot
	-- both announce the same slam (that double-fire burned the cooldown and the second one did nothing).
	local function doSlam(why)
		if tick() - (State.lastDown or 0) < 0.30 then return false end
		State.lastDown = tick()
		slamArmed = 0
		State.m1Count = 0
		if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] DOWN SLAM (" .. tostring(why) .. ")") end
		-- Symmetric with the uppercut: hold the DIRECTION key across the swing and name it on the remote. Firing
		-- the remote alone is what did nothing, exactly as it did for "Up".
		downDown()
		fireDir("Down")
		task.delay(0.40, function() downUp() end)   -- same reason as the uppercut's Space hold
		return true
	end
	-- THE RAW-CLICK SLAM PATH. onSwing() is animation-driven, and an AIRBORNE M1 usually plays a different
	-- (or no) track than the ground combo - so after the hop your slam click produced no counted swing and the
	-- slam never fired. That was the whole "down slam is bad" bug. This runs off the actual click instead.
	local function slamOnClick()
		if mode ~= "Down Slam" then return end
		if tick() >= slamArmed then return end
		-- NO airborne re-check. FloorMaterial lags the hop by a frame or two, so this test kept rejecting the
		-- very click it was armed for. We hopped you ourselves 3 swings ago - the arming window IS the proof.
		doSlam("armed click")
	end
	local function onSwing()
		if mode == "Off" then return end
		-- HARD GATE: no real click in the last 0.4s means this was not your M1, so we do nothing at all. This is
		-- the fix for "don't make me jump when I don't M1" - not deleting the Space press, which is what the
		-- uppercut actually needs.
		if not realM1Now() then
			if _G.VX_M1_DEBUG then print("[M1COMBO] ignored a swing-shaped anim - no real click behind it") end
			return
		end
		local now = tick()
		if now - State.lastM1 > Config.M1ResetWindow then State.m1Count = 0 end
		State.lastM1 = now
		State.m1Count = State.m1Count + 1
		local n = State.m1Count
		if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] swing " .. n .. "  mode=" .. tostring(mode)) end
		-- SLAM: if we hopped for you and you are now airborne, THIS swing is the down slam - announce it on
		-- the same beat you actually clicked, which is the timing that was wrong before.
		-- ═══ FIRE ON THE Nth SWING ═══ "every time you do the 4th M1 it uses the service and the remote".
		-- Counting to 4 is only reliable now that the click stamp survives a HELD combo - before this the
		-- counter never got past 1, which is why "just do it on the 4th M1" kept not happening.
		-- ═══ AUTOMATIC, NO SELECTOR ═══ The dropdown is gone. The direction has to be held and named BEFORE the
		-- finisher lands - once the game has committed to an ordinary M1 the remote arrives too late - so we act
		-- from the 2nd swing onward and the NEXT swing comes out as the uppercut / down slam. That is the timing
		-- that already works for the slam, so the uppercut now uses it too. Each has its own cooldown below, so
		-- acting from swing 2 cannot spam: one finisher per combo.
		-- Act on swing 3 so M1 #4 comes out as the uppercut / down slam. The direction has to be held and
		-- named BEFORE the finisher lands - once the game commits to an ordinary M1 the remote is too late.
		local need = 3
		if mode == "Down Slam" then
			-- ALREADY IN THE AIR? Then this swing IS the slam, whatever the count says - an air M1 is a slam.
			if airborneNow() then
				doSlam("airborne swing")
				return
			end
			if n >= need then
				State.m1Count = 0
				State.lastFire = now
				-- THE SIMPLE PATH FIRST: announce the direction on this swing exactly the way the capture shows.
				-- The hop below is only a fallback for characters whose slam needs you off the ground.
				doSlam("swing " .. n)
				task.spawn(function()
					local c = myModel()
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if h and h.FloorMaterial ~= Enum.Material.Air then
						_G.VX_LAUNCHING = tick()
						-- Humanoid.Jump alone can be swallowed while the combo animation owns the state, and then
						-- you never go airborne and the slam never arms. A modest Y floor guarantees the lift
						-- without the rocket the old 65/30-plus-three-mechanisms stack produced.
						pcall(function()
							local r = c and c:FindFirstChild("HumanoidRootPart")
							if r then
								local v = r.AssemblyLinearVelocity
								r.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 34), v.Z)
							end
						end)
						pcall(function() h.Jump = true end)
					end
					slamArmed = tick() + 1.6      -- your next M1 within this window announces the slam again
				end)
			end
		elseif mode == "Uppercut" then
			-- One finisher per combo: a 0.9s cooldown, matching how the slam behaves in practice. The old 0.18s
			-- let it re-fire on every remaining swing of the same combo, which spends the move repeatedly.

			-- On the Nth swing, hold the direction across the swing and name it on the remote. It used to fire
			-- on EVERY swing, which spent the move on hit 1 of a combo where the game only accepts it on the
			-- finisher - and made it look like it "does nothing".
			if n >= need and tick() - (State.lastUp or 0) >= 0.9 then
				State.lastUp = tick()
				State.lastFire = now
				State.m1Count = 0
				-- (This print used to concatenate a variable that no longer exists. Concatenating nil THROWS, and
				-- it threw BEFORE the key hold and the remote below - so with debug on, the uppercut never ran
				-- at all. That was "auto uppercut doesn't even work" in every debug-enabled test.)
				if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] swing " .. n .. " -> UPPERCUT") end
				spaceDown()
				fireDir("Up")
				-- 0.40, not 0.22: the game reads the held direction when the swing LANDS, and a JJS M1 takes
				-- longer than 0.22s to connect - so the old hold was released before it was ever read.
				task.delay(0.40, function() spaceUp() end)
			end
		end
	end

	-- Hook the animator and count real swings. Re-hooks whenever the Animator instance changes (respawn /
	-- character swap), because a track bound to a dead Animator never fires again.
	-- Hook EVERY rig that can play your combat animations. JJS uses workspace.Characters[name] and
	-- LP.Character at different moments; hooking only one meant swings on the other never counted, so the
	-- 3rd/4th hit never arrived. Weak-keyed so dead animators drop out on their own.
	local comboHooked = setmetatable({}, { __mode = "k" })
	local comboAnimLive = false   -- true once at least one animator is hooked (the click fallback stands down)
	local function hookComboAnims()
		local rigs = {}
		local chs = workspace:FindFirstChild("Characters")
		local resolved = chs and chs:FindFirstChild(LP.Name)
		if resolved then rigs[#rigs + 1] = resolved end
		if LP.Character and LP.Character ~= resolved then rigs[#rigs + 1] = LP.Character end
		for _, char in ipairs(rigs) do
			local h = char:FindFirstChildOfClass("Humanoid")
			local a = h and h:FindFirstChildOfClass("Animator")
			if a and not comboHooked[a] then
				comboHooked[a] = true
				comboAnimLive = true
				a.AnimationPlayed:Connect(function(track)
					if mode == "Off" then return end
					local ok, id = pcall(function() return tostring(track.Animation.AnimationId):match("%d+") end)
					if not ok or not id then return end
					-- CHARACTER-AGNOSTIC SWING DETECTION. Relying on an id database means any character whose
					-- M1 ids were never captured simply never counts a swing - which is exactly "it does not
					-- work at all" on that character. A listed id still counts instantly; otherwise ANY
					-- Action-priority animation that starts right after a real click is a swing. That is the
					-- same universal test the working Black Flash engine uses, and it needs no database.
					local isKnown = COMBO_IDS[id] or (_G.VX_M1_IDS and _G.VX_M1_IDS[id])
					local isSwing = isKnown
					if not isSwing then
						local pr = track.Priority
						local action = (pr == Enum.AnimationPriority.Action or pr == Enum.AnimationPriority.Action2
							or pr == Enum.AnimationPriority.Action3 or pr == Enum.AnimationPriority.Action4)
						local clickedJustNow = (tick() - (tonumber(_G.VX_LAST_CLICK) or 0)) < 0.45
						isSwing = action and clickedJustNow
						if isSwing and _G.VX_M1_DEBUG then print("[M1COMBO] unlisted M1 anim " .. id .. " counted via click+Action") end
					end
					-- An AIRBORNE attack animation is a down slam by definition - announce it directly rather than
					-- routing it through the ground-combo counter, which has no concept of an air swing.
					if AIR_ATTACK_IDS[id] and mode == "Down Slam" then
						if realM1Now() then doSlam("air attack anim " .. id) end
						return
					end
					if isSwing then
						onSwing()
						-- Feed the Black Flash chain the same REAL swing. It used to count raw clicks, which a
						-- held combo does not produce - four swings arrive from one click.
						if _G.VX_CHAIN_COUNT then pcall(_G.VX_CHAIN_COUNT) end
					end
				end)
			end
		end
	end
	task.spawn(function() while true do pcall(hookComboAnims); task.wait(0.5) end end)

	-- Kept for compatibility: the click paths no longer count. If the animation DB somehow misses this
	-- character entirely, this is the safety net that still advances the combo.
	local function onM1()
		if mode == "Off" then return end
		if comboAnimLive and tick() - State.lastM1 < 1.5 then return end   -- the animation path is counting; do not double-count this click
		onSwing()
	end
	-- REAL M1s come from the shared poll detector, NOT InputBegan: the game sinks the attack click, so the old
	-- InputBegan hook only ever fired on GUI/empty clicks = Auto Uppercut / Down Slam never ran at all.
	-- BOTH triggers, de-duplicated. It used to work off InputBegan, so that path stays; the poll is added
	-- because InputBegan does not see a sunk attack click on every build. Whichever fires first wins and the
	-- other is ignored for 0.05s, so a single M1 can never run onM1 twice.
	local __m1Guard = 0
	local function __m1Once()
		if UIS:GetFocusedTextBox() then return end
		if tick() < (tonumber(_G.VX_SYNTH_CLICK) or 0) then return end   -- ignore clicks WE injected
		if tick() - __m1Guard < 0.05 then return end
		__m1Guard = tick()
		-- The armed down slam runs off the RAW click, ahead of (and independently of) the swing counter: onM1
		-- refuses to count while the animation path is live, and an airborne M1 often plays no counted track at
		-- all, so routing the slam through the counter is what made it miss. doSlam's own cooldown stops this
		-- and the animation path from ever announcing the same slam twice.
		slamOnClick()
		onM1()
	end
	UIS.InputBegan:Connect(function(input, _)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then __m1Once() end
	end)
	if _G.VX_M1_SUB then _G.VX_M1_SUB("m1combo", function() __m1Once() end) end
	LP.CharacterAdded:Connect(function()
		task.wait(0.4)
		spaceUp(); downUp()   -- never carry a held direction key across a respawn
		State.spaceToken = nil
		State.m1Count = 0
		State.char = nil
		State.remote = nil
		refreshDetection()
	end)
	task.spawn(function()
		while true do
			if mode ~= "Off" then refreshDetection() end
			task.wait(1)
		end
	end)
	-- STUCK-KEY WATCHDOG. A held Space or S that never gets released is far worse than a missed uppercut: you
	-- would jump or walk backwards forever. Both are only ever held for 0.22s, so anything still down after 1s
	-- means a task.delay was lost (respawn, error, mode change mid-flight) and we release it unconditionally.
	task.spawn(function()
		while true do
			task.wait(0.25)
			if State.spaceHeld and tick() - (State.lastUp or 0) > 1 then pcall(spaceUp) end
			if State.downHeld and tick() - (State.lastDown or 0) > 1 then pcall(downUp) end
		end
	end)

	M1ComboApi = {
		setMode = function(m)
			if type(m) == "table" then m = m[1] end
			mode = m or "Off"; count = 0; busy = false; State.m1Count = 0; State.spaceToken = nil; spaceUp(); downUp()
			if mode ~= "Off" then refreshDetection() end
			-- Observable on purpose: with _G.VX_M1_DEBUG = true this proves the dropdown actually reached the
			-- module and what string it set, which separates "mode never set" from "swings never counted".
			if _G.VX_M1_DEBUG or _G.VX_BF_DEBUG then print("[M1COMBO] mode set to: " .. tostring(mode)) end
		end,   -- unwrap Fluriore's {"Down Slam"} table (else the mode check never matched = "doesn't work")
		setDelay = function() end,
		setCount = function() end,
		-- ═══ DIAGNOSTIC: RUN THE ACTION WITH NO DETECTION IN THE WAY ═══ Uppercut / Down Slam have two halves,
		-- the TRIGGER (did we notice your swing) and the ACTION (hold the direction + fire the remote). When it
		-- "doesn't work" we cannot tell which half failed. These run the ACTION alone, on demand, so one press
		-- of the button separates them: works here but not in a fight = the trigger; does nothing here either =
		-- the action, and the printout says exactly which service it resolved.
		testUp = function()
			print("[M1COMBO TEST] Uppercut: svc=" .. tostring(vxMyCharSvc()) .. "  v5remote=" .. tostring(State.remote and State.remote:GetFullName() or "nil"))
			spaceDown(); fireDir("Up"); task.delay(0.40, function() spaceUp() end)
		end,
		testDown = function()
			print("[M1COMBO TEST] Down Slam: svc=" .. tostring(vxMyCharSvc()) .. "  v5remote=" .. tostring(State.remote and State.remote:GetFullName() or "nil"))
			downDown(); fireDir("Down"); task.delay(0.40, function() downUp() end)
		end,
		-- Reports whether the swing detector is alive and when it last saw a real click/swing.
		testStatus = function()
			print("[M1COMBO TEST] mode=" .. tostring(mode)
				.. "  animHookLive=" .. tostring(comboAnimLive)
				.. "  swingsCounted=" .. tostring(State.m1Count)
				.. "  lastRealClick=" .. string.format("%.2fs ago", tick() - (tonumber(_G.VX_LAST_CLICK) or 0))
				.. "  lastSwing=" .. string.format("%.2fs ago", tick() - (State.lastM1 or 0)))
		end,
		setChar = function(c) Config.Manual = (c and c ~= "" and c ~= "Auto") and c or nil; State.char = nil; State.remote = nil; refreshDetection() end,
	}
end

-- MODULE: DASH  (no-cooldown directional dash via MovementService; forward = Itadori Chase)
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local noCd = false
	local DASH_ANIM = { Right = "rbxassetid://75203303352791", Left = "rbxassetid://117223862448096", Front = "rbxassetid://110978068388232", Back = "rbxassetid://110978068388232" }  -- user-captured dash anim ids
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function playDash(dir)  -- play the real dash animation so the no-CD dash LOOKS like a dash
		local m = myChar(); local h = m and m:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator"); if not a then return end
		local anim = Instance.new("Animation"); anim.AnimationId = DASH_ANIM[dir] or DASH_ANIM.Front
		local ok, t = pcall(function() return a:LoadAnimation(anim) end)
		if ok and t then pcall(function() t.Priority = Enum.AnimationPriority.Action2; t:Play(0.05) end); task.delay(0.55, function() pcall(function() t:Stop() end) end) end
	end
	local function moveDir()
		if UIS:IsKeyDown(Enum.KeyCode.S) then return "Back" end
		if UIS:IsKeyDown(Enum.KeyCode.A) then return "Left" end
		if UIS:IsKeyDown(Enum.KeyCode.D) then return "Right" end
		return "Front"
	end
	UIS.InputBegan:Connect(function(input, gpe)
		if not noCd or gpe then return end
		if input.KeyCode == Enum.KeyCode.Q then local d = moveDir(); fireKnit("MovementService", "Dash", d, true); vxClientDash(d, 105, 0.15); playDash(d) end  -- remote + velocity + the real dash ANIMATION
	end)
	DashApi = {
		setNoCd = function(v) noCd = v == true end,
		forward = function() fireKnit("ItadoriService", "Chase", false) end,
		dash = function(dir) fireKnit("MovementService", "Dash", dir or "Front") end,
	}
end

-- MODULE: TRAIN  (spawn / auto-spawn the station train; 3 minute cooldown)
do
	local on, lastFire = false, 0
	local function trainRE()
		local map = workspace:FindFirstChild("Map"); local d = map and map:FindFirstChild("Destructible")
		local m = d and d:FindFirstChild("Model"); local sc = m and m:FindFirstChild("StationControl")
		local h = sc and sc:FindFirstChild("Handle"); return h and h:FindFirstChild("Train")
	end
	local function fire()
		local re = trainRE(); if re then pcall(function() re:FireServer() end); lastFire = tick(); return true end
		return false
	end
	task.spawn(function()
		while true do
			if on and (tick() - lastFire >= 180) then fire() end
			task.wait(1)
		end
	end)
	TrainApi = {
		spawn = function() if tick() - lastFire >= 180 then return fire() end return false end,
		setAuto = function(v) on = v == true end,
		cooldownLeft = function() local l = 180 - (tick() - lastFire); return (l > 0 and l <= 180) and l or 0 end,
	}
end

-- MODULE: GET DRINK WHEN LOW  (buy soda to heal once HP drops below the threshold)
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local on, threshold, last = false, 35, 0
	task.spawn(function()
		while true do
			if on then
				local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
				if h and h.MaxHealth > 0 and (h.Health / h.MaxHealth * 100) <= threshold and (tick() - last > 3) then
					last = tick(); fireKnit("ShopService", "PurchaseSoda")
				end
			end
			task.wait(0.5)
		end
	end)
	DrinkApi = { set = function(v) on = v == true end, setThreshold = function(v) if type(v) == "number" then threshold = v end end }
end

-- MODULE: AUTO COUNTER  (blocks with F the instant a nearby enemy swings - F is JJS block)
do
	local Players = game:GetService("Players")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer
	local on, lockedOnly, last = false, false, 0
	local ACTION = { [Enum.AnimationPriority.Action] = true, [Enum.AnimationPriority.Action2] = true, [Enum.AnimationPriority.Action3] = true, [Enum.AnimationPriority.Action4] = true }
	local KW = { "punch", "hit", "swing", "strike", "slam", "kick", "combo", "m1", "slash", "rush", "stab" }
	-- per-character COUNTER keybind (vessel/Itadori/Sukuna = 4, Mahito = 4, restless gambler/Hakari = 3, blood manip/Choso = 3). No F fallback: unknown character = do nothing.
	local CKEY = { Itadori = Enum.KeyCode.Four, Sukuna = Enum.KeyCode.Four, Mahito = Enum.KeyCode.Four, Hakari = Enum.KeyCode.Three, Choso = Enum.KeyCode.Three }  -- vessel(Itadori/Sukuna)=4, Hakari=3, Mahito=4, Choso=3
	local function counterKey()
		local chs = workspace:FindFirstChild("Characters"); local m = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local n = detectCharName(m)
		return n and CKEY[n] or nil   -- nil = no counter key for this character (F fallback removed)
	end
	local function lockedTarget() local g = _G.VX_LOCK; return (g and g.get) and g.get() or nil end
	local function myHRP() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local M1_ID = "75337033003776"  -- the JJS M1 anim id
	local function pressCounter()  -- TAP the per-character COUNTER key (short hold so it can re-counter fast M1s)
		local ck = counterKey(); if ck then last = tick(); pcall(function() VIM:SendKeyEvent(true, ck, false, game); task.wait(0.08); VIM:SendKeyEvent(false, ck, false, game) end) end
	end
	local function isAttackId(id)   -- EVERY known attack id: M1 + the full captured list + the block dict + the counter ids
		if not id then return false end
		if id == M1_ID then return true end
		local a = _G.VX_ADAPT_IDS; if a and a[id] then return true end
		local d = _G.VX_ANIMDICT; if d and d[id] then return true end
		local c = _G.VX_COUNTER_IDS; if c and c[id] then return true end
		return false
	end
	local function isAttacking(h)
		local anim = h:FindFirstChildOfClass("Animator"); if not anim then return false end
		local ok, tracks = pcall(function() return anim:GetPlayingAnimationTracks() end); if not ok then return false end
		local dict = _G.VX_ANIMDICT       -- the block engine's attack-animation-id map (hundreds of ids)
		local cdict = _G.VX_COUNTER_IDS   -- the user's captured counter ids
		local adict = _G.VX_ADAPT_IDS     -- the FULL user-captured attack/skill/domain id list
		for _, t in ipairs(tracks) do
			if t.IsPlaying and t.Animation then
				local id = tostring(t.Animation.AnimationId):match("%d+")
				if id and dict and dict[id] then return true end   -- KNOWN JJS attack animation (most reliable)
				if id and cdict and cdict[id] then return true end -- a captured counter id
				if id and adict and adict[id] then return true end -- any of the full captured id list
				if ACTION[t.Priority] then return true end          -- fallback: any Action-priority swing
				local nm = string.lower(tostring(t.Name)); for _, kw in ipairs(KW) do if string.find(nm, kw, 1, true) then return true end end
			end
		end
		return false
	end
	task.spawn(function()
		while true do
			if on and tick() - last > 0.2 then   -- just a key press now, so it can react fast to each attack
				local hrp = myHRP(); local chars = workspace:FindFirstChild("Characters")
				local lockT = lockedOnly and lockedTarget() or nil   -- Locked Only: react to just this one target (nil target = counter nobody)
				if hrp and chars and not (lockedOnly and not lockT) then
					for _, m in ipairs(chars:GetChildren()) do
						if m.Name ~= LP.Name and m ~= LP.Character and (not lockedOnly or m == lockT) then
							local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid")
							if r and h and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= 16 then
								local toMe = hrp.Position - r.Position
								if toMe.Magnitude > 0 and r.CFrame.LookVector:Dot(toMe.Unit) > 0.2 and isAttacking(h) then
									pressCounter(m)
									break
								end
							end
						end
					end
				end
				task.wait(0.05)
			else task.wait(0.1) end
		end
	end)
	-- EVENT-DRIVEN reaction: the ANIM THREAT SYSTEM hooks every enemy Animator and calls this the INSTANT any anim starts, so we counter BEFORE the hit lands - on every M1 and every captured attack id, not a 0.05s poll.
	_G.VX_AUTOCOUNTER = function(enemyChar, id)
		if not on or tick() - last <= 0.2 then return end   -- just a key press now, react fast
		if not isAttackId(id) then return end
		local hrp = myHRP(); if not hrp then return end
		local r = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart"); if not r then return end
		if (r.Position - hrp.Position).Magnitude > 18 then return end
		local toMe = hrp.Position - r.Position
		if toMe.Magnitude > 0 and r.CFrame.LookVector:Dot(toMe.Unit) < 0.1 then return end   -- enemy must roughly FACE you (skip attacks aimed at a third party / facing away, so it doesn't waste your counter)
		if lockedOnly then local lt = lockedTarget(); if not lt or enemyChar ~= lt then return end end   -- Locked Only: only the locked target
		pressCounter(enemyChar)
	end
	CounterApi = { set = function(v) on = v == true; _G.VX_AUTOCOUNTER_ON = on end, setLockedOnly = function(v) lockedOnly = v == true; if _G.VX_LOCK then _G.VX_LOCK.want("counter", lockedOnly) end end }
end

-- ============================================================
-- MODULE: LOCK TARGET SYSTEM  (shared) - click a user to lock onto them (red outline); click the same user again to release.
-- Feeds Crow lock-on + Auto Counter "Locked Only". Highlight is client-side (gethui/CoreGui), outline only, shows through walls.
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local mouse = LP:GetMouse()
	-- executors re-run the whole hub: tear down the PREVIOUS run's lock (disconnect its handlers, kill its leftover outline) so nothing stacks or lingers
	if _G.VX_LOCK and _G.VX_LOCK._cleanup then pcall(_G.VX_LOCK._cleanup) end
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, o in ipairs(host:GetChildren()) do if o.Name == "VX_LockHighlight" then o:Destroy() end end
	end)
	local locked, hl = nil, nil
	local curColor = Color3.fromRGB(255, 40, 52)   -- live lock-outline colour (Lock Color dropdown)
	local manualOn = false                        -- true only while the user's Lock Target toggle is on
	local conns = {}  -- our RBXScriptConnections, so a later re-run can disconnect them
	local want = {}   -- feature key -> wants click-to-lock active (any true = active)
	local function clickActive() for _, v in pairs(want) do if v then return true end end return false end
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function clearHL() if hl then pcall(function() hl:Destroy() end); hl = nil end end
	local function makeHL(m)
		clearHL(); if not m then return end
		local h = Instance.new("Highlight")
		h.Name = "VX_LockHighlight"
		h.FillTransparency = 1                          -- outline only, no fill
		h.OutlineTransparency = 0
		h.OutlineColor = curColor
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Adornee = m
		pcall(function() h.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
		if not h.Parent then pcall(function() h.Parent = m end) end
		hl = h
	end
	local function release() locked = nil; clearHL() end
	local function enemyUnderMouse()  -- walk up from the clicked part to the character Model (has HRP/Humanoid), never your own body
		local t = mouse.Target; if not t then return nil end
		local node, mine = t, myModel()
		while node and node ~= workspace do
			if node:IsA("Model") and (node:FindFirstChild("HumanoidRootPart") or node:FindFirstChildOfClass("Humanoid")) then
				if node ~= mine and node.Name ~= LP.Name and node ~= LP.Character then return node end
			end
			node = node.Parent
		end
		return nil
	end
	pcall(function() conns[#conns + 1] = mouse.Button1Down:Connect(function()
		if not clickActive() then return end
		local m = enemyUnderMouse()
		-- ═══ CLICKING A TARGET MUST RETARGET ═══ This used to bail whenever anything was already locked, so
		-- once you had a target you could never pick a different one - clicking the enemy you actually wanted
		-- silently did nothing ("the lock is not working, when I click the target it needs to go to the
		-- target"). Now: clicking a DIFFERENT enemy moves the lock to them. Clicking anything that is not an
		-- enemy (ground, sky, your own body) still leaves the current lock alone, so ordinary combat clicking
		-- can never drop it - that stickiness was the part worth keeping.
		if not m then return end
		if locked == m and locked.Parent then return end     -- already on this one; nothing to do
		locked = m; makeHL(m)
		if _G.VX_LOCK_NOTIFY then pcall(function() _G.VX_LOCK_NOTIFY(m.Name) end) end
	end) end)
	conns[#conns + 1] = RunService.Heartbeat:Connect(function()
		if locked then
			local _lh = locked:FindFirstChildOfClass("Humanoid")
			if not locked.Parent or (_lh and _lh.Health <= 0) then release() end   -- despawned OR dead (a lingering corpse used to lock you out)
		end
		if locked and hl and hl.Adornee ~= locked then pcall(function() hl.Adornee = locked end) end
	end)
	_G.VX_LOCK = {
		get = function() return (locked and locked.Parent) and locked or nil end,   -- the currently locked Model, or nil
		set = function(m) if m and m.Parent then locked = m; makeHL(m) else locked = nil; clearHL() end end,     -- programmatic lock + red outline (set(nil) clears it) - used by Auto Rika Sword
		want = function(key, v) want[key] = v == true; if not clickActive() then release() end end,  -- register a feature that needs click-to-lock; auto-clears the lock when nothing needs it
		setColor = function(c) if typeof(c) == "Color3" then curColor = c; if hl then pcall(function() hl.OutlineColor = c end) end end end,   -- Lock Color dropdown
		manual = function(v) manualOn = (v == true); want["manual"] = manualOn; if not manualOn then release() end end,   -- turning the toggle off ALWAYS clears, even if another feature still wants click-lock   -- the user's own Lock Target toggle
		manualActive = function() return manualOn == true end,   -- ONLY a user click-lock retargets combat (a programmatic Rika lock must not)
		_cleanup = function() for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end; clearHL() end,  -- called by a later re-run to remove this run's handlers + outline
	}
end

-- ============================================================
-- MODULE: AUTO ULT CROW  (MeiMei) - the crow ult targets an enemy; remembers who you M1, sends the bird to them on G
-- ============================================================
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer
	local on, crowHitOn, lastTarget, flying = false, false, nil, false
	local crowGen = 0   -- generation counter: a newer G cast owns the click-suppression window
	local function myHRP() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function nearestEnemy()
		local hrp = myHRP(); if not hrp then return nil end
		local best, bd
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local h = m:FindFirstChildOfClass("Humanoid"); local r = m:FindFirstChild("HumanoidRootPart"); if r and (not h or h.Health > 0) then local d = (r.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = m, d end end end end  -- include the Dummy (HRP, maybe no living Humanoid)
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
		return best
	end
	local function onM1() if on or crowHitOn then local t = nearestEnemy(); if t then lastTarget = t end end end  -- clicking a user locks the crow onto them (target = who you last M1)
	pcall(function() LP:GetMouse().Button1Down:Connect(onM1) end)
	local function crowModel()  -- the spawned crow: workspace.Crows.Crow (has a HumanoidRootPart) - Effects.Crow kept as fallback
		local crows = workspace:FindFirstChild("Crows")
		if crows then local c = crows:FindFirstChildWhichIsA("Model") or crows:FindFirstChildWhichIsA("BasePart"); if c then return c end end
		local eff = workspace:FindFirstChild("Effects"); return eff and eff:FindFirstChild("Crow")
	end
	local function crowControlRemote()
		local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local info = c and c:FindFirstChild("Info"); local re = info and info:FindFirstChild("ControlRemote")
		if re and (re:IsA("RemoteEvent") or re:IsA("UnreliableRemoteEvent")) then return re end
		return nil
	end
	local expandedCrow = setmetatable({}, { __mode = "k" })   -- expand each crow's hitbox ONCE
	local function dressCrow(crow, expandMult)  -- expand the hitbox + apply the chosen color (no anchoring when the SERVER is flying it)
		local function one(p)
			if not p:IsA("BasePart") then return end
			pcall(function() p.CanCollide = false end)
			if not expandedCrow[p] then expandedCrow[p] = true; pcall(function() p.Size = p.Size * (expandMult or 5) end) end   -- BIG hitbox: it clips everything near the target
		end
		if crow:IsA("BasePart") then one(crow) else for _, p in ipairs(crow:GetDescendants()) do one(p) end end
	end
	local function anchorCrow(crow)  -- FALLBACK ONLY (no ControlRemote): anchor + client-drive so gravity can't drag it down
		local function one(p) if p:IsA("BasePart") then pcall(function() p.Anchored = true; p.AssemblyLinearVelocity = Vector3.zero end) end end
		if crow:IsA("BasePart") then one(crow) else for _, p in ipairs(crow:GetDescendants()) do one(p) end end
		dressCrow(crow)
	end
	local function moveCrow(crow, cf)  -- move the WHOLE crow (all parts together via PivotTo) so nothing lags behind and snaps
		pcall(function() if crow:IsA("BasePart") then crow.CFrame = cf else crow:PivotTo(cf) end end)
	end
	local function lockedTarget() local g = _G.VX_LOCK; return (g and g.get) and g.get() or nil end  -- the shared locked target (from clicking a user with the outline on)
	local function posOf(t) local r = t and (t:FindFirstChild("HumanoidRootPart") or t:FindFirstChildWhichIsA("BasePart")); return r and r.Position end
	local function click()  -- detonate: one M1 at the screen center
		local cam = workspace.CurrentCamera; local v = (cam and cam.ViewportSize) or Vector2.new(800, 600)
		pcall(function() VIM:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, true, game, 0); task.wait(0.03); VIM:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, false, game, 0) end)
	end
	-- CONTROLLER: re-read the target's LIVE position every frame (lock-on), ANCHOR + hard-drive the WHOLE crow HIGH toward the target so it never touches the ground or snaps back, then click ONCE to detonate on arrival.
	-- Runs for Crow Ult (G -> flying) AND Crow Lock On (crowHitOn -> auto-home ANY crow that spawns).  We connect after the game loads, so our per-frame write wins = the crow can't get pulled off course.
	local HOVER, STEP, DET = 8, 14, 7
	local lastCtl = 0
	RunService.Heartbeat:Connect(function()
		if not (flying or crowHitOn) then return end
		local crow = crowModel(); if not crow then return end
		-- TARGET = the LOCKED (clicked) user, ONLY. No lock + G-cast homes who you last M1. It never picks a random enemy.
		local lt = lockedTarget()
		local tp
		if lt then tp = posOf(lt)
		elseif flying then
			tp = posOf((lastTarget and lastTarget.Parent) and lastTarget)
			-- FALLBACK (was missing = "crow going to target doesn't work"): with no click-lock and no remembered
			-- M1 victim there was NO target at all, so the crow just sat there. Home the nearest enemy instead.
			if not tp then local ne = nearestEnemy(); if ne then lastTarget = ne; tp = posOf(ne) end end
		end
		if not tp then return end
		dressCrow(crow)                                                             -- big hitbox + your color, every frame (covers newly-streamed parts)
		local ctl = crowControlRemote()
		if ctl then
			-- REAL control: the game's own ControlRemote flies the crow SERVER-side to the position we send.
			-- Send the target's LIVE chest position (slightly above) ~8x/sec: tracks moving enemies, any distance,
			-- never touches the ground (the game path-flies it), and the hit registers because the SERVER moves it.
			if tick() - lastCtl > 0.12 then
				lastCtl = tick()
				local aim = Vector3.new(tp.X, tp.Y + 2.5, tp.Z)
				pcall(function()
					local v = aim
					pcall(function() if vector and vector.create then v = vector.create(aim.X, aim.Y, aim.Z) end end)   -- the capture used vector.create; Vector3 also encodes the same
					ctl:FireServer(v)
				end)
			end
			return
		end
		-- FALLBACK (no ControlRemote found): client-drive like before
		anchorCrow(crow)
		local cp = crow:GetPivot().Position
		local hd = Vector3.new(tp.X - cp.X, 0, tp.Z - cp.Z).Magnitude
		if hd <= DET then moveCrow(crow, CFrame.new(Vector3.new(tp.X, tp.Y + 3.5, tp.Z))); return end
		local aimY = tp.Y + math.clamp(hd * 0.6, 10, 70)
		if aimY < cp.Y then aimY = cp.Y end
		if aimY < tp.Y + 8 then aimY = tp.Y + 8 end
		local aim = Vector3.new(tp.X, aimY, tp.Z)
		local dir = aim - cp
		local stepCap = (hd < 26) and 4 or STEP
		local nextPos = cp + dir.Unit * math.min(dir.Magnitude, stepCap)
		local look = Vector3.new(tp.X, nextPos.Y, tp.Z)
		if (look - nextPos).Magnitude < 0.05 then moveCrow(crow, CFrame.new(nextPos))
		else moveCrow(crow, CFrame.new(nextPos, look)) end
	end)
	UIS.InputBegan:Connect(function(input, gpe)  -- (M1 target-memory is handled by the GetMouse().Button1Down hook above, not duplicated here)
		if on and not gpe and input.KeyCode == Enum.KeyCode.G then  -- ult: spawn the crow + take control of its flight to the target
			local tgt = lockedTarget() or ((lastTarget and lastTarget.Parent) and lastTarget) or nearestEnemy()
			-- WHILE THE CROW IS FLYING, NO SYNTHETIC CLICKS. A click cancels the ult ("if u click, it go away"),
			-- and the BF / M1-chain / dash-assist paths all send VirtualInputManager mouse clicks. This flag is
			-- checked by those paths so they hold off until the crow lands.
			if tgt then
				lastTarget = tgt; fireKnit("MeiMeiService", "Activated", false, tgt); vxLog("Crow -> " .. tgt.Name)
				-- Only suppress scripted clicks once a crow ACTUALLY exists. Setting the flag on every G press
				-- meant a G on cooldown (no crow spawns) silently killed the dash-assist M1s for 25s.
				crowGen = crowGen + 1
				local myGen = crowGen
				task.spawn(function()
					local t0 = tick()
					repeat task.wait(0.1) until crowModel() or tick() - t0 > 2 or crowGen ~= myGen
					if crowGen ~= myGen then return end
					if not crowModel() then vxLog("Crow: none spawned (cooldown?) - clicks NOT suppressed"); return end
					flying = true; _G.VX_CROW_FLYING = tick() + 25
					task.delay(25, function()
						if crowGen ~= myGen then return end   -- a newer cast owns the suppression now
						flying = false; _G.VX_CROW_FLYING = 0
					end)
				end)
			end
		end
	end)
	CrowUltApi = {
		set = function(v) on = v == true; if not v then flying = false end end,
	}
	-- Crow Hit / Lock On: turning this on lets you CLICK a user to lock + red-outline them; any crow you send auto-homes onto that locked target and hits from any distance.
	CrowHitApi = { set = function(v) crowHitOn = v == true; if _G.VX_LOCK then _G.VX_LOCK.want("crow", crowHitOn) end end }
end

-- MODULE: LOCK ON  (Camera / Character lock + JJS-style targeting reticle on the locked target)
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local mode, smooth, showReticle, locked = "Off", 0.4, true, nil  -- mode: Off / Camera / Character / Both
	local function myHRP() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end

	local screen = Instance.new("ScreenGui")
	screen.Name = "VX_LockOn"; screen.ResetOnSpawn = false; screen.IgnoreGuiInset = true; screen.DisplayOrder = 9001
	pcall(function() screen.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not screen.Parent then pcall(function() screen.Parent = LP:WaitForChild("PlayerGui") end) end
	-- LOCK-ON ICON: clean WHITE corner brackets + a small center dot (no more purple circle). Classic "target
	-- locked" look, matches the black/white theme.
	local ret = Instance.new("Frame"); ret.BackgroundTransparency = 1; ret.AnchorPoint = Vector2.new(0.5, 0.5); ret.Visible = false; ret.Parent = screen
	local WHT = Color3.fromRGB(255, 255, 255)
	-- four L-shaped corner brackets built from thin frames
	local function bracket(hx, hy)   -- hx/hy = -1 (left/top) or 1 (right/bottom)
		local armLen = 0.32
		local ax = (hx < 0) and 0 or (1 - armLen)
		local ay = (hy < 0) and 0 or (1 - armLen)
		-- horizontal arm
		local h = Instance.new("Frame"); h.BorderSizePixel = 0; h.BackgroundColor3 = WHT; h.Size = UDim2.new(armLen, 0, 0, 2)
		h.Position = UDim2.new(ax, 0, (hy < 0) and 0 or 1, (hy < 0) and 0 or -2); h.Parent = ret
		-- vertical arm
		local v = Instance.new("Frame"); v.BorderSizePixel = 0; v.BackgroundColor3 = WHT; v.Size = UDim2.new(0, 2, armLen, 0)
		v.Position = UDim2.new((hx < 0) and 0 or 1, (hx < 0) and 0 or -2, ay, 0); v.Parent = ret
	end
	bracket(-1, -1); bracket(1, -1); bracket(-1, 1); bracket(1, 1)
	local dot = Instance.new("Frame"); dot.Size = UDim2.fromOffset(4, 4); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(0.5, 0.5); dot.BackgroundColor3 = WHT; dot.BorderSizePixel = 0; dot.Parent = ret
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	local function layoutReticle(size)
		ret.Size = UDim2.fromOffset(size, size)
	end
	local function acquire()
		local hrp = myHRP(); local cam = workspace.CurrentCamera; if not (hrp and cam) then return nil end
		local vp = cam.ViewportSize; local center = Vector2.new(vp.X / 2, vp.Y / 2)
		local best, bestScore
		local function chk(m)
			if not m or m == LP.Character then return end
			local h = m:FindFirstChildOfClass("Humanoid"); local r = m:FindFirstChild("HumanoidRootPart")
			if not (h and r and h.Health > 0) then return end
			local d = (r.Position - hrp.Position).Magnitude; if d > 300 then return end
			local sp = cam:WorldToViewportPoint(r.Position); if sp.Z <= 0 then return end  -- in-front check only; off-screen targets are still lockable
			local sc = (Vector2.new(sp.X, sp.Y) - center).Magnitude + d * 0.5
			if not bestScore or sc < bestScore then best, bestScore = m, sc end
		end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chars = workspace:FindFirstChild("Characters"); if chars then for _, m in ipairs(chars:GetChildren()) do chk(m) end end
		return best
	end
	local function valid(m)
		if not m or not m.Parent then return false end
		local h = m:FindFirstChildOfClass("Humanoid"); local r = m:FindFirstChild("HumanoidRootPart")
		return h ~= nil and r ~= nil and h.Health > 0
	end
	local function setAR(v) local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if h and h.AutoRotate ~= v then pcall(function() h.AutoRotate = v end) end end
	RunService.RenderStepped:Connect(function()
		if mode == "Off" then setAR(true); ret.Visible = false; locked = nil; return end
		if not valid(locked) then locked = acquire() end
		if not valid(locked) then setAR(true); ret.Visible = false; return end
		local cam = workspace.CurrentCamera; local hrp = myHRP(); local tr = locked:FindFirstChild("HumanoidRootPart")
		if not (cam and hrp and tr) then setAR(true); ret.Visible = false; return end
		if mode == "Camera" or mode == "Both" then
			cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, tr.Position), smooth)
		end
		if mode == "Character" or mode == "Both" then
			setAR(false)  -- stop the Humanoid's auto-rotate from fighting our facing while we walk
			pcall(function() hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, Vector3.new(tr.Position.X, hrp.Position.Y, tr.Position.Z)), 0.5) end)
		else
			setAR(true)
		end
		if showReticle then
			local head = locked:FindFirstChild("Head") or tr
			local sp, vis = cam:WorldToViewportPoint(head.Position)
			if vis and sp.Z > 0 then
				local dist = (tr.Position - hrp.Position).Magnitude
				layoutReticle(math.clamp(2600 / math.max(dist, 6), 26, 120))
				ret.Position = UDim2.fromOffset(sp.X, sp.Y); ret.Visible = true
			else ret.Visible = false end
		else ret.Visible = false end
	end)
	LockOnApi = {
		setMode = function(m) mode = m or "Off"; if mode == "Off" then locked = nil end end,
		setReticle = function(v) showReticle = v == true end,
		setSmooth = function(s) if type(s) == "number" then smooth = s end end,
		set = function(v) mode = (v == true) and "Camera" or "Off" end,
	}
end

-- MODULE: AUTO ULT  (spams the ult key G)
do
	local VIM = game:GetService("VirtualInputManager")
	local on = false
	task.spawn(function()
		while true do
			if on then pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.G, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.G, false, game) end); task.wait(0.4)
			else task.wait(0.2) end
		end
	end)
	AutoUltApi = { set = function(v) on = v == true end }
end

-- MODULE: ANTI-AFK
do
	local Players = game:GetService("Players")
	local VirtualUser = game:GetService("VirtualUser")
	local LP = Players.LocalPlayer
	local on = true
	LP.Idled:Connect(function() if on then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)
	AntiAfkApi = { set = function(v) on = v == true end }
end

-- MODULE: NOCLIP  (removed per request)

-- MODULE: AUTO FARM PLAYER  (approach a chosen target - or nearest - and M1 it)
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local on, targetName = false, nil
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end
	local function act(arg)  -- real M1 on ONLY your detected character (firing all 21 services can get rejected/kicked)
		local svc = vxMyCharSvc()
		if svc then fireKnit(svc, "Activated", arg) else for _, c in ipairs(CHAR_NAMES) do fireKnit(c .. "Service", "Activated", arg) end end
	end
	local function acPass() fireKnit("AntiCheatService", "Teleport", workspace:GetServerTimeNow()) end
	local function nearest()
		local hrp = myHRP(); if not hrp then return nil end
		local best, bd
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local h = m:FindFirstChildOfClass("Humanoid"); local r = m:FindFirstChild("HumanoidRootPart"); if h and h.Health > 0 and r then local d = (r.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = m, d end end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chars = workspace:FindFirstChild("Characters"); if chars then for _, m in ipairs(chars:GetChildren()) do chk(m) end end
		return best
	end
	local function pickTarget()
		if targetName then
			local p = Players:FindFirstChild(targetName)
			if p and p.Character then local h = p.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then return p.Character end end
			local chars = workspace:FindFirstChild("Characters"); if chars then local m = chars:FindFirstChild(targetName); if m then local h = m:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then return m end end end
			return nil
		end
		return nearest()
	end
	task.spawn(function()
		while true do
			if on then
				local hrp = myHRP(); local tgt = pickTarget()
				if hrp and tgt then
					local tr = tgt:FindFirstChild("HumanoidRootPart")
					if tr then
						local dist = (tr.Position - hrp.Position).Magnitude
						if dist > 6 then acPass(); local goal = tr.Position - (tr.Position - hrp.Position).Unit * 5; pcall(function() hrp.CFrame = CFrame.new(goal, tr.Position) end)
						else pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tr.Position.X, hrp.Position.Y, tr.Position.Z)) end) end
						act(false)  -- real M1 on the faced target
					end
				end
				task.wait(0.2)
			else task.wait(0.2) end
		end
	end)
	FarmApi = { set = function(v) on = v == true end, setTarget = function(name) targetName = (name and name ~= "Nearest" and name ~= "(none)") and name or nil end }
end

-- ============================================================
-- MODULE: SPEED HACK  (drive WASD by velocity at a set speed)
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on, speed = false, 70
	local function hrp() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	RunService.Heartbeat:Connect(function()
		if not on then return end
		local r = hrp(); local cam = workspace.CurrentCamera
		if not (r and cam) then return end
		local dir = Vector3.zero; local cf = cam.CFrame
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude > 0 then
			flat = flat.Unit * speed
			pcall(function() r.AssemblyLinearVelocity = Vector3.new(flat.X, r.AssemblyLinearVelocity.Y, flat.Z) end)
		end
	end)
	SpeedApi = { set = function(v) on = v == true end, setSpeed = function(s) if type(s) == "number" then speed = s end end }
end

-- ============================================================
-- MODULE: FLY  (camera-steered: WASD + Space up / Ctrl down)
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on, speed = false, 80
	local bv, bg, conn
	local function char() return LP.Character end
	local function hrp() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
	local function stop()
		if conn then conn:Disconnect(); conn = nil end
		if bv then pcall(function() bv:Destroy() end); bv = nil end
		if bg then pcall(function() bg:Destroy() end); bg = nil end
		local c = char(); local h = c and c:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.PlatformStand = false end) end
	end
	local function start()
		local r = hrp(); local c = char(); local h = c and c:FindFirstChildOfClass("Humanoid")
		if not (r and h) then return end
		stop()
		bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.P = 90000; bv.Velocity = Vector3.zero; bv.Parent = r
		bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 30000; bg.CFrame = r.CFrame; bg.Parent = r
		pcall(function() h.PlatformStand = true end)
		conn = RunService.RenderStepped:Connect(function()
			if not on then return end
			local rr = hrp(); local cam = workspace.CurrentCamera
			if not (rr and cam and bv and bg) then return end
			local dir = Vector3.zero; local cf = cam.CFrame
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
			bv.Velocity = (dir.Magnitude > 0 and dir.Unit * speed) or Vector3.zero
			bg.CFrame = cf
		end)
	end
	FlyApi = { set = function(v) on = v == true; if on then start() else stop() end end, setSpeed = function(s) if type(s) == "number" then speed = s end end }
	LP.CharacterAdded:Connect(function() if on then task.wait(0.6); start() end end)
end

-- ============================================================
-- MODULE: PLAYER ESP  (chams + name + character + health + distance + move + cooldowns + tracers)
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local ACCENT = Color3.fromRGB(255, 46, 58)
	local cfg = { master = false, chams = true, name = true, character = false, health = true, distance = true, move = false, cooldowns = false, tracers = false, box = false, tracerThick = 2, accent = Color3.fromRGB(255, 46, 58) }

	local screen = Instance.new("ScreenGui")
	screen.Name = "VX_ESP"; screen.ResetOnSpawn = false; screen.IgnoreGuiInset = true; screen.DisplayOrder = 9000
	pcall(function() screen.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not screen.Parent then pcall(function() screen.Parent = LP:WaitForChild("PlayerGui") end) end

	local pool = {}
	local function build(model, adornee)
		local hl = Instance.new("Highlight")
		hl.FillColor = ACCENT; hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.FillTransparency = 0.65; hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = model; hl.Enabled = false; hl.Parent = model
		local bb = Instance.new("BillboardGui")
		bb.Name = "VXTag"; bb.Size = UDim2.fromOffset(244, 86); bb.StudsOffset = Vector3.new(0, 3.6, 0); bb.AlwaysOnTop = true; bb.Adornee = adornee; bb.Parent = adornee
		local nameL = Instance.new("TextLabel")
		nameL.BackgroundTransparency = 1; nameL.Size = UDim2.new(1, 0, 0, 16); nameL.Font = Enum.Font.GothamBlack; nameL.TextSize = 14
		nameL.TextColor3 = Color3.fromRGB(255, 255, 255); nameL.TextStrokeTransparency = 0.2; nameL.TextStrokeColor3 = Color3.new(0, 0, 0); nameL.Parent = bb
		local hpBg = Instance.new("Frame")
		hpBg.BackgroundColor3 = Color3.fromRGB(8, 8, 10); hpBg.BackgroundTransparency = 0.15; hpBg.BorderSizePixel = 0
		hpBg.Size = UDim2.new(0.72, 0, 0, 5); hpBg.Position = UDim2.new(0.14, 0, 0, 18); hpBg.Parent = bb
		local hpC = Instance.new("UICorner"); hpC.CornerRadius = UDim.new(1, 0); hpC.Parent = hpBg
		local hpS = Instance.new("UIStroke"); hpS.Color = Color3.fromRGB(0, 0, 0); hpS.Thickness = 1; hpS.Transparency = 0.4; hpS.Parent = hpBg
		local hpFill = Instance.new("Frame"); hpFill.BackgroundColor3 = Color3.fromRGB(70, 220, 90); hpFill.BorderSizePixel = 0; hpFill.Size = UDim2.fromScale(1, 1); hpFill.Parent = hpBg
		local hpFC = Instance.new("UICorner"); hpFC.CornerRadius = UDim.new(1, 0); hpFC.Parent = hpFill
		local infoL = Instance.new("TextLabel")
		infoL.BackgroundTransparency = 1; infoL.Position = UDim2.new(0, 0, 0, 26); infoL.Size = UDim2.new(1, 0, 0, 13); infoL.Font = Enum.Font.GothamMedium; infoL.TextSize = 11.5
		infoL.TextColor3 = Color3.fromRGB(230, 230, 232); infoL.TextStrokeTransparency = 0.35; infoL.Parent = bb
		local cdRow = Instance.new("Frame")
		cdRow.BackgroundTransparency = 1; cdRow.Position = UDim2.new(0, 0, 0, 54); cdRow.Size = UDim2.new(1, 0, 0, 28); cdRow.Visible = false; cdRow.Parent = bb
		local cdLayout = Instance.new("UIListLayout"); cdLayout.FillDirection = Enum.FillDirection.Horizontal; cdLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; cdLayout.VerticalAlignment = Enum.VerticalAlignment.Center; cdLayout.Padding = UDim.new(0, 3); cdLayout.Parent = cdRow
		local tracer = Instance.new("Frame"); tracer.BackgroundColor3 = ACCENT; tracer.BorderSizePixel = 0; tracer.AnchorPoint = Vector2.new(0.5, 0.5); tracer.Visible = false; tracer.ZIndex = 2; tracer.Parent = screen
		local box = Instance.new("Frame"); box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false; box.ZIndex = 3; box.Parent = screen
		local boxS = Instance.new("UIStroke"); boxS.Color = ACCENT; boxS.Thickness = 1.6; boxS.Parent = box
		local boxC = Instance.new("UICorner"); boxC.CornerRadius = UDim.new(0, 3); boxC.Parent = box
		local o = { hl = hl, bb = bb, nameL = nameL, hpBg = hpBg, hpFill = hpFill, infoL = infoL, cdRow = cdRow, cdBoxes = {}, charName = nil, charT = 0, tracer = tracer, box = box, boxS = boxS }
		pool[model] = o
		return o
	end
	local function destroy(model)
		local o = pool[model]; if not o then return end
		pcall(function() o.hl:Destroy() end); pcall(function() o.bb:Destroy() end); pcall(function() o.tracer:Destroy() end); pcall(function() o.box:Destroy() end)
		pool[model] = nil
	end
	local function clearAll() for m in pairs(pool) do destroy(m) end end

	local function makeCdBox(parent)  -- one small box per move: shows short name + a live cooldown timer
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(34, 26); f.BackgroundColor3 = Color3.fromRGB(20, 20, 24); f.BackgroundTransparency = 0.1; f.BorderSizePixel = 0; f.Parent = parent
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 4); cc.Parent = f
		local ss = Instance.new("UIStroke"); ss.Thickness = 1; ss.Color = Color3.fromRGB(0, 0, 0); ss.Transparency = 0.3; ss.Parent = f
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1, 1); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 9
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255); lbl.TextStrokeTransparency = 0.45; lbl.Parent = f
		return { f = f, lbl = lbl }
	end
	local function readMove(model)
		local hum = model:FindFirstChildOfClass("Humanoid")
		local anim = hum and hum:FindFirstChildOfClass("Animator")
		if not anim then return nil end
		local best, pr
		for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
			if t.IsPlaying and t.Animation then
				local nm = t.Animation.Name; local low = nm and nm:lower() or ""
				if nm and nm ~= "" and low ~= "idle" and low ~= "walk" and low ~= "run" and low ~= "fall" then
					local p = (t.Priority and t.Priority.Value) or 0
					if not pr or p >= pr then best, pr = nm, p end
				end
			end
		end
		return best
	end
	local function readCooldowns(model)
		local src = model:FindFirstChild("Moveset") or model:FindFirstChild("Cooldowns")  -- Moveset holds a NumberValue per move = its cooldown
		if not src then return nil end
		local act = {}
		for _, v in ipairs(src:GetChildren()) do
			if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Value and v.Value > 0.05 then
				act[#act + 1] = v.Name .. " " .. string.format("%.1f", v.Value) .. "s"
			end
		end
		if #act == 0 then return nil end
		return "CD: " .. table.concat(act, ", ")
	end
	local function enemyList()
		local out, seen = {}, {}
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then out[#out + 1] = plr.Character; seen[plr.Character] = true end end
		local chars = workspace:FindFirstChild("Characters")
		if chars then for _, m in ipairs(chars:GetChildren()) do if m:IsA("Model") and m.Name ~= LP.Name and not seen[m] then out[#out + 1] = m end end end
		return out
	end

	-- ═══ LAG ═══ ESP was the second-heaviest thing in the hub: for EVERY enemy, EVERY frame, it did a
	-- GetBoundingBox plus eight WorldToViewportPoint calls for the box corners, and rebuilt cooldown labels with
	-- fresh string.format allocations. At 60fps in a busy lobby that is thousands of projection calls a second.
	-- ESP does not need to update at render rate to look smooth - 30Hz is indistinguishable and halves the cost.
	-- _G.VX_ESP_HZ lets you raise it back if you want it perfectly glued.
	local espLast = 0
	RunService.RenderStepped:Connect(function()
		if not cfg.master then return end
		local espInterval = 1 / math.clamp(tonumber(_G.VX_ESP_HZ) or 30, 10, 60)
		if tick() - espLast < espInterval then return end
		espLast = tick()
		local cam = workspace.CurrentCamera; if not cam then return end
		local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		local vp = cam.ViewportSize
		local present = {}
		for _, model in ipairs(enemyList()) do
			local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
			local head = model:FindFirstChild("Head") or hrp
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hrp and head then
				present[model] = true
				local o = pool[model] or build(model, head)
				o.hl.Enabled = cfg.chams
				if cfg.name or cfg.character then
					local txt = cfg.name and model.Name or ""
					if cfg.character then
						if o.charName == nil or (tick() - o.charT > 3) then
							local nm = detectCharName(model)
							if not nm then local ms = model:FindFirstChild("Moveset"); if ms then local mv = {}; for _, v in ipairs(ms:GetChildren()) do mv[#mv + 1] = v.Name end; if #mv > 0 then nm = table.concat(mv, "/") end end end
							o.charName = nm or false; o.charT = tick()  -- name if found, else the moveset (the moves identify the character)
						end
						if o.charName then txt = txt .. (txt ~= "" and "  " or "") .. "[" .. o.charName .. "]" end
					end
					o.nameL.Visible = true; o.nameL.Text = txt
				else o.nameL.Visible = false end
				if cfg.health and hum and hum.MaxHealth > 0 then
					local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
					o.hpBg.Visible = true; o.hpFill.Size = UDim2.fromScale(frac, 1)
					o.hpFill.BackgroundColor3 = Color3.fromRGB(math.floor(235 * (1 - frac)) + 20, math.floor(200 * frac) + 30, 55)
				else o.hpBg.Visible = false end
				local parts = {}
				if cfg.distance and myHRP then parts[#parts + 1] = string.format("%dm", math.floor((hrp.Position - myHRP.Position).Magnitude)) end
				if cfg.move then local mv = readMove(model); if mv then parts[#parts + 1] = mv end end
				if #parts > 0 then o.infoL.Visible = true; o.infoL.Text = table.concat(parts, "  -  ") else o.infoL.Visible = false end
				if cfg.cooldowns then
					local ms = model:FindFirstChild("Moveset")
					if ms then
						o.cdRow.Visible = true
						local seen2 = {}
						for _, v in ipairs(ms:GetChildren()) do
							if v:IsA("NumberValue") or v:IsA("IntValue") then
								seen2[v.Name] = true
								local box = o.cdBoxes[v.Name]; if not box then box = makeCdBox(o.cdRow); o.cdBoxes[v.Name] = box end
								local val = v.Value or 0
								local short = (#v.Name > 5) and v.Name:sub(1, 5) or v.Name
								if val > 0.05 then
									box.f.BackgroundColor3 = Color3.fromRGB(70, 18, 20); box.lbl.TextColor3 = Color3.fromRGB(255, 120, 120)
									box.lbl.Text = short .. "\n" .. string.format("%.1f", val)
								else
									box.f.BackgroundColor3 = Color3.fromRGB(18, 40, 22); box.lbl.TextColor3 = Color3.fromRGB(120, 235, 140)
									box.lbl.Text = short .. "\nOK"
								end
							end
						end
						for nm, box in pairs(o.cdBoxes) do if not seen2[nm] then pcall(function() box.f:Destroy() end); o.cdBoxes[nm] = nil end end
					else o.cdRow.Visible = false end
				else o.cdRow.Visible = false end
				if cfg.box then
						local okb, bcf, bsize = pcall(function() local a, b = model:GetBoundingBox() return a, b end)  -- fitted 2D box: project the oriented bounding box, screen min/max = a rect that hugs them
						if okb and bcf and bsize then
							local hx, hy, hz = bsize.X / 2, bsize.Y / 2, bsize.Z / 2
							local minX, minY, maxX, maxY, onScreen = math.huge, math.huge, -math.huge, -math.huge, false
							for _, cx in ipairs({ -hx, hx }) do for _, cy in ipairs({ -hy, hy }) do for _, cz in ipairs({ -hz, hz }) do
								local sp2 = cam:WorldToViewportPoint((bcf * CFrame.new(cx, cy, cz)).Position)
								if sp2.Z > 0 then
									onScreen = true
									if sp2.X < minX then minX = sp2.X end; if sp2.Y < minY then minY = sp2.Y end
									if sp2.X > maxX then maxX = sp2.X end; if sp2.Y > maxY then maxY = sp2.Y end
								end
							end end end
							if onScreen then
								o.box.Visible = true; o.boxS.Color = cfg.accent
								o.box.Position = UDim2.fromOffset(minX, minY); o.box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
							else o.box.Visible = false end
						else o.box.Visible = false end
					else o.box.Visible = false end
					if cfg.tracers then
					local sp, vis = cam:WorldToViewportPoint(hrp.Position)
					if vis and sp.Z > 0 then
						local ax, ay = vp.X / 2, vp.Y
						local dx, dy = sp.X - ax, sp.Y - ay
						local len = math.sqrt(dx * dx + dy * dy)
						o.tracer.Visible = true; o.tracer.Size = UDim2.fromOffset(len, cfg.tracerThick); o.tracer.BackgroundColor3 = cfg.accent
						o.tracer.Position = UDim2.fromOffset((ax + sp.X) / 2, (ay + sp.Y) / 2)
						o.tracer.Rotation = math.deg(math.atan2(dy, dx))
					else o.tracer.Visible = false end
				else o.tracer.Visible = false end
			end
		end
		for m in pairs(pool) do if not present[m] then destroy(m) end end
	end)

	PlayerEspApi = {
		setMaster = function(v) cfg.master = v == true; if not cfg.master then clearAll() end end,
		setOpt = function(k, v) if type(cfg[k]) == "boolean" then cfg[k] = v == true end end,  -- boolean opts only (chams/name/box/tracers/...)
		setThick = function(v) if type(v) == "number" then cfg.tracerThick = v end end,
		setColor = function(c) if typeof(c) == "Color3" then cfg.accent = c end end,
		set = function(v) cfg.master = v == true; if not cfg.master then clearAll() end end,
	}
end

-- ============================================================
-- MODULE: ANTI STUN  (zero your Info.Stun - throttled 0.1s loop, NOT every frame, so it won't lag your body)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local RunService = game:GetService("RunService")
	local on = false
	local function myModel() local chars = workspace:FindFirstChild("Characters"); return (chars and chars:FindFirstChild(LP.Name)) or LP.Character end
	local NAMES = { "Stun", "Stunned", "HitStun", "Hitstun", "eStun", "Knockback", "Knockbacked", "Blockstun", "BlockStun", "Guardbreak", "GuardBreak", "Stagger" }
	local baseWS, baseJP = 16, 50
	RunService.Heartbeat:Connect(function()  -- every frame so a stun is cleared the instant it lands (value writes = cheap). Covers every common stun/knockback flag JJS uses.
		if not on then return end
		local m = myModel(); if not m then return end
		local hum = m:FindFirstChildOfClass("Humanoid")
		local info = m:FindFirstChild("Info")
		if info then
			for _, nm in ipairs(NAMES) do
				local v = info:FindFirstChild(nm)
				if v and (v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("BoolValue")) then
					pcall(function() if typeof(v.Value) == "boolean" then v.Value = false else v.Value = 0 end end)
				end
			end
		end
		if hum then
			pcall(function()
				if hum.WalkSpeed > 8 then baseWS = hum.WalkSpeed end        -- remember your real speed while un-stunned
				if hum.JumpPower > 8 then baseJP = hum.JumpPower end
				if hum.WalkSpeed < 1 then hum.WalkSpeed = baseWS end        -- a stun froze you (WS=0) -> restore movement
				if hum.JumpPower < 1 then hum.JumpPower = baseJP end
				local st = hum:GetState()
				if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			end)
			for _, nm in ipairs(NAMES) do if hum:GetAttribute(nm) ~= nil then pcall(function() hum:SetAttribute(nm, false) end) end end
		end
	end)
	AntiStunApi = { set = function(v) on = v == true end }
end

-- ============================================================
-- MODULE: ANTI RAGDOLL  (clear ragdoll ONLY while actually ragdolled - throttled, no per-frame GetDescendants = no lag)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local on = false
	local function myModel() local chars = workspace:FindFirstChild("Characters"); return (chars and chars:FindFirstChild(LP.Name)) or LP.Character end
	local hookedHum = nil
	local function protectStates(hum)  -- disable the ragdoll/falling states + snap OUT if the game forces one
		if not hum then return end
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		end)
		if hookedHum ~= hum then
			hookedHum = hum
			hum.StateChanged:Connect(function(_, new)
				if not on then return end
				if new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.FallingDown then
					pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
				end
			end)
		end
	end
	task.spawn(function()
		while true do
			if on then
				local m = myModel()
				if m then
					local hum = m:FindFirstChildOfClass("Humanoid")
					protectStates(hum)
					if hum and hum.PlatformStand then pcall(function() hum.PlatformStand = false end) end
					local info = m:FindFirstChild("Info")
					local rag = info and (info:FindFirstChild("Ragdoll") or info:FindFirstChild("Ragdolled"))
					if rag then pcall(function() if typeof(rag.Value) == "boolean" then rag.Value = false else rag.Value = 0 end end) end
					local rc = m:FindFirstChild("RagdollConstraints")
					if rc then for _, c in ipairs(rc:GetDescendants()) do if c:IsA("Constraint") and c.Enabled then pcall(function() c.Enabled = false end) end end end
					for _, d in ipairs(m:GetDescendants()) do   -- kill custom ragdoll joints, re-enable the normal ones
						pcall(function()
							if d:IsA("BallSocketConstraint") then d.Enabled = false
							elseif d:IsA("Motor6D") and not d.Enabled then d.Enabled = true end
						end)
					end
				end
			end
			task.wait(0.15)
		end
	end)
	AntiRagdollApi = { set = function(v) on = v == true end }
end

-- ============================================================
-- MODULE: ANIM THREAT SYSTEM  (real JJS animation IDs: domain casts, counters, and the block script's AnimDict)
-- Powers Anti-Domain (react to the cast anim, earlier than workspace.Domains), Anti-Counter (dodge a counter), Auto-Adapt (block every known attack).
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer

	-- user-captured domain CAST animation ids -> name
	local DOMAINS = {
		["132725601768618"] = "Gojo", ["121984128639453"] = "Vessel", ["118861398234801"] = "Gambler",
		["127843796051633"] = "Mahoraga", ["75736902190737"] = "Mahito", ["125335594549446"] = "Rika", ["101617544363219"] = "Higuruma",
	}
	-- ONLY the 3 REAL counter moves -> Anti Counter jumps on head. (The other ~19 ids were common attacks and made it false-fire on every hit; they live in ADAPT_IDS below.)
	local COUNTERS = { ["82987093810211"] = 1, ["92529934565092"] = 1, ["86073608599582"] = 1 }
	_G.VX_COUNTER_IDS = COUNTERS  -- shared with Auto Counter (per-character counter key)
	-- EVERY attack/skill/domain id the user captured -> Auto Adapt (press 4), Auto Counter (per-character counter key), Anti Counter all fire on ANY of these
	local ADAPT_IDS = {}
	for _, aid in ipairs({
		"137865634124104","137654778575373","95421145178968","104749346956269","101162958113766","124937162378188","132748613906344","77200218033775",
		"124901309160375","100962226150441","131506102901134","137611726964398","107554693613496","82541714192027","72063002791216","72467492674240",
		"108123475959041","95901746347992","132281807148575","120480195428173","132653290201368","111077341852080","116432619539029","81112033595734",
		"131219281339199","75390215999547","115683433001643","138852224035589","85024950165903","84870056161157","103493656287292","89092734635186",
		"72475960800126","108319980293313","125455197945793","123690534435200","128779949980528","127727754867974","76313364850487","105068005007692",
		"89888040037257","127171275866632","84039122607068","117045209683198","100446064103831","114321791577837","95097480425566","117371289990421",
		"107067953428369","94720627091769","136536827155962","111720035828971","100081544058065","121343824534765","89652378115594","76519264603956",
		"133869529005453","135411487367370","132704398648016","106649604455931","132754851925571","124243904748268","125904281673524","89582140026963",
		"95077220586856","108418554887656","93796567192197","88005970155216","131031842057158","123778544771528","71783955283661","120136894011461",
		"87472283043607","93901924492394","114277419400774","136523051723440","89009042593684","137638103122538","118652212972529","105121164520635",
		"118607369830566","86045680364061","119211164876773","94616006376147","70890372338556","115589615022077","82149987460883","115561023870463",
		"81210313723714","130957217409359","100811576955331","113359849246757","78578012001859","134622628645994","89891294371787","122015481201264",
		"113722638806911","92595499555055","96466374346823","81953935260783","73243807139765","114822879878184","138826705245289","70394890117813",
		"113479860283691","129678103897608","129132347098646","134777193523837","121550561336691","94590184881876","115097960689033","94347210073500",
		"104793932628579","77833820443705","103013818601982","79860101129549","72933571933445","72932825817330","123476590646783","120914276661831",
		"102053631728986","76957377224584","126362899488198","90781290293652","81007905598407","99180695169591","130209038947701","83430571986421",
		"78636717376287","85938446097801","116119661056362",
		-- day-11 additions: Brothers ult, Rika yellow-beam/love-ladder, Head of Hei domain hit (all -> Auto Adapt presses 4)
		"121572833341748","84448423136678","89677028738408","72828071138653",  -- Brothers ult
		"73482562876920",  -- Rika yellow beam / love ladder
		"125442768208685",  -- Head of Hei domain HIT
	}) do ADAPT_IDS[aid] = true end
	_G.VX_ADAPT_IDS = ADAPT_IDS

	local domainOn, domainMode, counterOn, adaptOn, blackholeOn, domainAdaptOn = false, "Safe Teleport", false, false, false, false
	local domainCd, counterCd, adaptCd, selfDomainCast = 0, 0, 0, 0
	local function idOf(s) return tostring(s):match("%d+") end
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local m = myModel(); return m and m:FindFirstChild("HumanoidRootPart") end
	local function tapF() pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game); task.wait(0.16); VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end) end
	local ADAPT_LEAD = 0.09  -- seconds to wait after the enemy STARTS the attack before pressing 4, so the adapt lands as the hit connects (raise if it fires too early, lower toward 0 if too late)
	local function pressFour()  -- Auto Adapt presses the 4 KEY (the Adapt skill) - it never plays an animation itself
		pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Four, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.Four, false, game) end)
	end
	local function clickM1()  -- an M1 click at screen-center (used by the moves that need a CLICK to adapt, not just 4)
		pcall(function()
			local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
			VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0); task.wait(0.04); VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
		end)
	end
	-- These moves ADAPT BY CLICKING (M1) as soon as they come, NOT by pressing 4: Hollow Purple + the fire move.
	local CLICK_ADAPT_IDS = { ["132748613906344"] = true, ["137611726964398"] = true }
	local function playAdapt(id)
		if id and CLICK_ADAPT_IDS[id] then                         -- Hollow Purple / fire: adapt by CLICKING, not 4
			-- lands in the parry window (starts the instant it's detected).
			task.spawn(function() for _ = 1, 4 do clickM1(); task.wait(0.12) end end)
			return
		end
		task.delay(ADAPT_LEAD, pressFour)                          -- everything else: press 4 on the short lead
	end
	local function dist(er) local mr = myHRP(); return (mr and er) and (er.Position - mr.Position).Magnitude or 9999 end
	local function randomEnemyHRP()
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local r = plr.Character:FindFirstChild("HumanoidRootPart"); if r then list[#list + 1] = r end end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if m.Name ~= LP.Name then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); if r and h and h.Health > 0 then list[#list + 1] = r end end end end
		if #list == 0 then return nil end
		return list[math.random(1, #list)]
	end
	local function trainPos()
		local map = workspace:FindFirstChild("Map"); local d = map and map:FindFirstChild("Destructible"); local m = d and d:FindFirstChild("Model")
		local sc = m and m:FindFirstChild("StationControl"); local h = sc and sc:FindFirstChild("Handle")
		if h and h:IsA("BasePart") then return h.Position end
		local sp = workspace:FindFirstChildOfClass("SpawnLocation"); if sp then return sp.Position end
		return nil
	end
	local function domainCenter()  -- where the active domain is, so we can flee directly AWAY from it
		local domains = workspace:FindFirstChild("Domains")
		if domains then for _, ch in ipairs(domains:GetChildren()) do local ok, cf = pcall(function() return ch:GetPivot() end); if ok and cf then return cf.Position end end end
		return nil
	end
	local function enemyOutsideDomain(c)  -- a user/DUMMY that is OUTSIDE the domain (so teleporting to them actually ESCAPES, never loops you back inside)
		local me = myHRP()
		local function far(r)
			if not r then return false end
			if c then return (r.Position - c).Magnitude > 150 end
			return me and (r.Position - me.Position).Magnitude > 80 or false   -- no center found: at least far from YOU (never TP into the dome around you)
		end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local r = plr.Character:FindFirstChild("HumanoidRootPart"); if far(r) then return r end end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if m.Name ~= LP.Name then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); if r and h and h.Health > 0 and far(r) then return r end end end end
		return nil
	end
	local function safeTeleport()  -- ESCAPE the domain: to a user/DUMMY OUTSIDE it, else bolt AWAY from the center + up, else train / straight up. Never lands you back inside.
		local hrp = myHRP(); if not hrp then return end
		local c = domainCenter()
		local out = enemyOutsideDomain(c)
		if out then vxTeleportHard(out.Position - out.CFrame.LookVector * 4 + Vector3.new(0, 3, 0), 1.25); return end   -- go to a user who is OUTSIDE the domain
		if c then local away = hrp.Position - c; local dir = away.Magnitude > 1 and away.Unit or hrp.CFrame.LookVector; vxTeleportHard(c + dir * 320 + Vector3.new(0, 140, 0), 1.25); return end  -- none outside: bolt far away from the center + high UP (out of the dome)
		local tp = trainPos(); if tp then vxTeleportHard(tp + Vector3.new(0, 6, 0), 1.25); return end               -- no center found: train station
		vxTeleportHard(hrp.Position + Vector3.new(0, 400, 0), 1.25)                                                  -- last resort: straight UP, high enough to clear the dome
	end
	local function domainCaster()  -- the enemy who CAST the domain = the living enemy nearest the domain center
		local c = domainCenter(); if not c then return randomEnemyHRP() end
		local best, bd
		local function chk(r) if r then local d = (r.Position - c).Magnitude; if not bd or d < bd then best, bd = r, d end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then local h = plr.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then chk(plr.Character:FindFirstChild("HumanoidRootPart")) end end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if m.Name ~= LP.Name then local h = m:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then chk(m:FindFirstChild("HumanoidRootPart")) end end end end
		return best
	end
	local function domainReact(name, caster)
		local hrp = myHRP(); if not hrp then return end
		if domainMode == "To User + Hit" then
			-- go to the CASTER (the one whose cast anim triggered this) and HIT them to interrupt the domain
			local r = (caster and caster:FindFirstChild("HumanoidRootPart")) or domainCaster()
			local cchar = caster or (r and r.Parent)
			if r then
				vxTeleportHard(r.Position - r.CFrame.LookVector * 3 + Vector3.new(0, 2, 0), 1.5)
				task.delay(0.12, function()
					if _G.VX_RUNCHAIN and cchar and cchar.Parent then pcall(function() _G.VX_RUNCHAIN(cchar) end)   -- black flash the caster
					else pcall(function()                                                                            -- fallback: raw M1s
						local VIM = game:GetService("VirtualInputManager")
						for _ = 1, 4 do VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0); task.wait(0.05); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0); task.wait(0.14) end
					end) end
				end)
			end
		else
			safeTeleport()   -- Safe Teleport (default): OUT of the domain
		end
	end
	local counterMode, counterEmote = "Jump On Head", 1   -- what to do when an enemy counters: jump on their head OR play a saved emote
	local function emoteRE(name)
		local RSs = game:GetService("ReplicatedStorage")
		local k = RSs:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild("EmoteService"); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild(name)
	end
	local function counterReact(enemyChar)  -- enemy countered -> Jump On Head OR taunt them with your saved emote
		if counterMode == "Emote" then
			local re = emoteRE("Emote")
			if re then pcall(function() re:FireServer(counterEmote) end) end   -- play emote slot #counterEmote
			task.delay(2.6, function()                                          -- end it once their counter is done
				local re2 = emoteRE("EmoteEnd"); if re2 then pcall(function() re2:FireServer() end) end
			end)
		else
			if JumpHeadApi then JumpHeadApi.jump((enemyChar and enemyChar.Name) or "Nearest") end
		end
	end
	local function blackholeReact()  -- black hole = get OUT: blink way up, then to a random user
		if VX_NOTIFY then VX_NOTIFY("Black Hole - teleporting out", false) end
		local hrp = myHRP(); if hrp then vxGlide(hrp.Position + Vector3.new(0, 320, 0)) end
		task.delay(1.2, function() local r = randomEnemyHRP(); if r then vxGlide(r.Position - r.CFrame.LookVector * 4 + Vector3.new(0, 3, 0)) end end)
	end
	local function blackHoleObject()  -- detect the ACTUAL black-hole effect part (the anim id was Megumi's dive - it false-fired)
		local hrp = myHRP(); if not hrp then return nil end
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") then local n = d.Name:lower()
				if (n:find("black") and n:find("hole")) or n:find("voidsphere") or n:find("blackhole") then
					if (d.Position - hrp.Position).Magnitude <= 140 then return d end
				end
			end
		end
		return nil
	end
	local function onAnim(enemyChar, animId)
		local id = idOf(animId); if not id then return end
		local er = enemyChar:FindFirstChild("HumanoidRootPart")
		if domainOn and DOMAINS[id] and tick() - domainCd > 3 then domainCd = tick(); domainReact(DOMAINS[id], enemyChar) end   -- caster passed -> 'To User + Hit' hits the RIGHT person
		if counterOn and COUNTERS[id] and er and dist(er) <= 26 and tick() - counterCd > 0.8 then counterCd = tick(); counterReact(enemyChar) end
		-- AUTO ADAPT: on the AnimationPlayed event (so it is TIMED to the attack, not polled), if an enemy starts ANY
		-- of the full captured attack-id list OR a block-dict attack -> press 4 (after ADAPT_LEAD). 0.35s de-dupe.
		-- Range is 60 (was 20 = melee only) so Gojo's ULT / ranged casts (Purple, Red, Unlimited Void) trigger it too.
		if adaptOn and er and dist(er) <= 60 and tick() - adaptCd > 0.35 then local dict = _G.VX_ANIMDICT; if ADAPT_IDS[id] or (dict and dict[id]) then adaptCd = tick(); playAdapt(id) end end
		-- AUTO EVASIVE rides the SAME proven event: nearby enemy starts any attack -> the i-frame dash fires
		if _G.VX_EVADE and er and dist(er) <= 30 then local dict = _G.VX_ANIMDICT; if ADAPT_IDS[id] or (dict and dict[id]) or COUNTERS[id] then _G.VX_EVADE() end end
		if _G.VX_AUTOCOUNTER_ON and _G.VX_AUTOCOUNTER then _G.VX_AUTOCOUNTER(enemyChar, id) end  -- AUTO COUNTER reacts on the SAME event = counters before the hit lands, on every attack id
	end
	local hooked = setmetatable({}, { __mode = "k" })  -- animator -> connection (weak so dead chars GC)
	local function hookChar(char)
		if not char or char.Name == LP.Name or char == LP.Character then return end
		local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController")
		local anim = hum and hum:FindFirstChildOfClass("Animator")
		if anim and not hooked[anim] then hooked[anim] = anim.AnimationPlayed:Connect(function(track) if track.Animation then onAnim(char, track.Animation.AnimationId) end end) end
	end
	pcall(function()  -- hook brand-new enemies THE MOMENT they spawn, so their first swing is already caught (no up-to-a-second blind window)
		local chs = workspace:FindFirstChild("Characters")
		if chs then chs.ChildAdded:Connect(function(m) task.wait(0.2); if domainOn or counterOn or adaptOn or blackholeOn or _G.VX_AUTOCOUNTER_ON then hookChar(m) end end) end
	end)
	task.spawn(function()
		while true do
			if domainOn or counterOn or adaptOn or blackholeOn or _G.VX_AUTOCOUNTER_ON then
				local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do hookChar(m) end end
				for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then hookChar(plr.Character) end end
			end
			task.wait(0.6)  -- re-scan often so a newly-appeared enemy is hooked in time to adapt to their attacks
		end
	end)
	-- AUTO DOMAIN ADAPT: while you are trapped inside an enemy domain, keep pressing 4 to adapt to it (blood rain, Gojo, Head of Hei, etc.). Per-type time cap; Rika domain is skipped (no ult there).
	local DOMAIN_CAP = { vessel = 8 }  -- seconds to keep spamming 4 for this domain type; any type NOT listed = spam the whole time the domain is up
	local function activeDomain()
		local domains = workspace:FindFirstChild("Domains"); if not domains then return nil end
		for _, ch in ipairs(domains:GetChildren()) do if ch:IsA("Model") or ch:IsA("Folder") then return ch end end
		return nil
	end
	local function domainTypeOf(dom)  -- classify ONCE (on domain appear) by a name keyword anywhere inside it (e.g. DomainCollider.YutaDomain)
		if not dom then return "other" end
		local function kw(n) n = n:lower()
			if n:find("yuta") or n:find("vessel") or n:find("authentic") then return "vessel" end   -- check BEFORE rika (Yuta's domain contains Rika parts but should be "vessel" = 8s cap)
			if n:find("rika") then return "rika" end
			if n:find("gojo") or n:find("void") or n:find("infinite") then return "gojo" end
			if n:find("choso") or n:find("blood") then return "blood" end
			if n:find("hei") then return "hei" end
			if n:find("mahito") then return "mahito" end
			return nil
		end
		local t = kw(dom.Name); if t then return t end
		for _, d in ipairs(dom:GetDescendants()) do local k = kw(d.Name); if k then return k end end
		return "other"
	end
	local function domainCenterPos(dom)
		local ok, cf = pcall(function() return dom:GetPivot() end); if ok and cf then return cf.Position end
		local p = dom:FindFirstChildWhichIsA("BasePart", true); return p and p.Position
	end
	local function insideDomain(dom)  -- are you caught in it? within ~160 studs of its center - or ASSUME yes if we can't resolve a center (domain exists = you're likely in it)
		local hrp = myHRP(); if not hrp then return false end
		local c = dom and domainCenterPos(dom)
		if not c then return true end
		return (hrp.Position - c).Magnitude <= 160
	end
	local function domainMine(dom)  -- is this YOUR OWN domain? (don't adapt against it) - check an Owner ObjectValue if the game exposes one anywhere inside
		local o = dom:FindFirstChild("Owner", true)
		if o and o:IsA("ObjectValue") and o.Value then return o.Value == myModel() or o.Value == LP.Character or o.Value.Name == LP.Name end
		return false
	end
	local SUKUNA_DOMAIN_IDS = { ["125442768208685"] = true, ["134795274895344"] = true, ["121752268008113"] = true }  -- Sukuna domain HIT anims -> spam 4 for 10s
	local GOJO_DOMAIN_IDS = { ["138196552148011"] = true }  -- Gojo domain HIT anim -> press 4 ONCE
	local sukunaSpamUntil, gojoAdaptCd, frozenCd = 0, 0, 0
	local selfHooked = setmetatable({}, { __mode = "k" })  -- hook YOUR animator so we know when YOU cast a domain / are caught in Sukuna's or Gojo's
	local function hookSelfDomain()
		local m = myModel(); local h = m and m:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
		if not a or selfHooked[a] then return end
		selfHooked[a] = a.AnimationPlayed:Connect(function(track)
			local id = track.Animation and idOf(track.Animation.AnimationId); if not id then return end
			if DOMAINS[id] then selfDomainCast = tick() end                          -- you cast a domain -> the active one is YOURS
			if SUKUNA_DOMAIN_IDS[id] and domainAdaptOn then                          -- caught in SUKUNA'S domain -> ADAPT: hammer 4 for 10s straight
				local wasActive = tick() < sukunaSpamUntil
				sukunaSpamUntil = tick() + 10
				if not wasActive then task.spawn(function() while tick() < sukunaSpamUntil do pressFour(); task.wait(0.25) end end) end
			end
			if GOJO_DOMAIN_IDS[id] and domainAdaptOn and tick() - gojoAdaptCd > 2 then gojoAdaptCd = tick(); pressFour() end   -- caught in GOJO'S domain -> ADAPT: press 4 ONCE
		end)
	end
	-- GOJO / frozen detection: if you are TRYING to move (input a direction) but your body isn't actually
	-- moving (frozen by Gojo's Infinite Void), press 4 ONCE to adapt.
	task.spawn(function()
		local UIS = game:GetService("UserInputService")
		while true do
			task.wait(0.15)
			if domainAdaptOn and tick() - frozenCd > 2 then
				local m = myModel(); local hum = m and m:FindFirstChildOfClass("Humanoid"); local hrp = m and m:FindFirstChild("HumanoidRootPart")
				if hum and hrp then
					local wantsMove = hum.MoveDirection.Magnitude > 0.1 or UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D)
					local vel = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
					if wantsMove and vel < 1.5 then frozenCd = tick(); pressFour() end   -- you're inputting movement but not moving = frozen -> adapt once
				end
			end
		end
	end)
	task.spawn(function()  -- workspace.Domains scan: Anti-Domain escape (ANY domain, incl. vessel - not just anim-id) + Auto-Domain-Adapt spam + black-hole EFFECT scan
		local lastDom, lastReactedDom, domType, domStart, bhCd, dbgCd = nil, nil, "other", 0, 0, 0
		local function dbg(msg) if VX_DEBUG and VX_NOTIFY and tick() - dbgCd > 2 then dbgCd = tick(); pcall(function() VX_NOTIFY(msg, nil) end) end end  -- ONLY with Debug on; never leaks internals during normal play
		while true do
			local dom = (domainOn or domainAdaptOn) and activeDomain() or nil
			if domainOn or domainAdaptOn then hookSelfDomain() end  -- track when YOU cast a domain
			if not dom then lastDom = nil; if domainAdaptOn then dbg("Domain Adapt: none active") end
			else
				if dom ~= lastDom then lastDom = dom; domType = domainTypeOf(dom); domStart = tick() end  -- classify the new domain ONCE (avoid re-scanning its many parts each tick)
				local mine = domainMine(dom) or (tick() - selfDomainCast <= 13)                          -- is this YOUR OWN domain? (Owner value or you just cast one)
				if domainOn and not mine and (dom ~= lastReactedDom or insideDomain(dom)) and tick() - domainCd > 3 then
					domainCd = tick(); lastReactedDom = dom; domainReact("Domain")                        -- ESCAPE: fire once on any new domain, then RETRY every 3s while still trapped (so a set-back can't leave you stuck)
				end
				if domainAdaptOn and not mine then                                                        -- ADAPT: press 4 whenever an ENEMY domain is up (the inside-check was a false-negative that made it do nothing). Per-type time cap.
					local cap = DOMAIN_CAP[domType]
					if not cap or tick() - domStart <= cap then pressFour(); dbg("Domain Adapt: 4 (" .. domType .. ")") else dbg("Domain Adapt: cap (" .. domType .. ")") end
				elseif domainAdaptOn and mine then dbg("Domain Adapt: own domain (skip)")
				end
			end
			if blackholeOn and tick() - bhCd > 4 and blackHoleObject() then bhCd = tick(); blackholeReact() end
			task.wait(0.25)
		end
	end)
	AntiDomainApi = { set = function(v) domainOn = v == true end, setMode = function(m) domainMode = m or "Safe Teleport" end }
	AntiCounterApi = {
		set = function(v) counterOn = v == true end,
		setMode = function(m) counterMode = (m == "Emote") and "Emote" or "Jump On Head" end,   -- what to do on their counter
		setEmote = function(n) counterEmote = tonumber(n) or 1 end,                              -- which saved emote slot to play
	}
	AutoAdaptApi = { set = function(v) adaptOn = v == true end }
	AutoDomainAdaptApi = { set = function(v) domainAdaptOn = v == true end }
	AntiBlackHoleApi = { set = function(v) blackholeOn = v == true end }
end

-- ============================================================
-- MODULE: MAHORAGA SAFE TP + AUTO EARTHQUAKE + AUTO KILL-EMOTE
-- ============================================================
do
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local LP = Players.LocalPlayer
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local m = myModel(); return m and m:FindFirstChild("HumanoidRootPart") end
	local function emoteRE(name)
		local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild("EmoteService"); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild(name)
	end

	-- ---------- MAHORAGA SAFE TP ----------
	-- When ANY enemy summons Mahoraga (they play the summon anim rbxassetid://127843796051633, or the model
	-- appears), teleport ME to a fixed SAFE spot far off the map, hold there while the summon danger passes,
	-- then teleport ME back to the main map. Fixed coords the user gave.
	local mahoOn, mahoCd = false, 0
	local MAHO_SAFE   = Vector3.new(-66.9, 50.8, 424.0)   -- safe spot to sit out the Mahoraga summon
	local MAHO_RETURN = Vector3.new(-16.2, 24.4, 14.1)    -- main map spawn to return to when it's done
	local MAHO_ANIM = { ["127843796051633"] = true }      -- Mahoraga summon/cast id
	local function mahoNameHit(n) n = n:lower(); return n:find("mahoraga") or n:find("mahoro") or (n:find("divine") and n:find("general")) end
	local function scanMahoraga()  -- a Mahoraga model present in the world near you
		local hrp = myHRP(); if not hrp then return false end
		local function chkList(parent)
			if not parent then return false end
			for _, m in ipairs(parent:GetChildren()) do
				if m:IsA("Model") and mahoNameHit(m.Name) then
					local r = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
					if r and (r.Position - hrp.Position).Magnitude <= 260 then return true end
				end
			end
			return false
		end
		return chkList(workspace) or chkList(workspace:FindFirstChild("Characters")) or chkList(workspace:FindFirstChild("Summons")) or chkList(workspace:FindFirstChild("Shadows"))
	end
	local mahoBusy = false
	local function mahoEscape()
		if mahoBusy then return end
		mahoBusy = true
		if VX_NOTIFY then VX_NOTIFY("Mahoraga sensed - safe teleport", false) end
		vxTeleportHard(MAHO_SAFE + Vector3.new(0, 4, 0), 5)          -- the WORKING glide teleport (same engine as the Teleports tab) to the safe spot + hold 5s
		task.delay(7, function()
			vxTeleportHard(MAHO_RETURN + Vector3.new(0, 4, 0), 1.25)     -- summon done -> back to the main map
			if VX_NOTIFY then VX_NOTIFY("Back to main map", true) end
			task.delay(1.5, function() mahoBusy = false end)
		end)
	end
	-- CATCH THE SPAWN ANYWHERE: the Mahoraga model can stream in under any folder - a workspace-wide
	-- DescendantAdded listener catches it wherever it lands (the 4-folder poll kept missing it).
	pcall(function()
		workspace.DescendantAdded:Connect(function(d)
			if not mahoOn then return end
			if not (d:IsA("Model") and mahoNameHit(d.Name)) then return end
			if tick() - mahoCd > 5 then mahoCd = tick(); mahoEscape() end
		end)
	end)
	-- CHANT path (most reliable): the Mahoraga summon makes the summoner SAY the ritual chant
	-- ("With this treasure I summon..."). The moment ANY enemy chats it, safe TP - fires even if
	-- the anim/model never streams in on your client.
	local CHANT = "with this treasure"
	local function chantHook(plr)
		pcall(function() plr.Chatted:Connect(function(msg)
			if mahoOn and tostring(msg):lower():find(CHANT, 1, true) and tick() - mahoCd > 5 then mahoCd = tick(); mahoEscape() end
		end) end)
	end
	for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then chantHook(p) end end
	Players.PlayerAdded:Connect(function(p) if p ~= LP then chantHook(p) end end)
	pcall(function()
		game:GetService("TextChatService").MessageReceived:Connect(function(m)
			if not (mahoOn and m and m.Text) then return end
			local src = m.TextSource
			if src and src.UserId == LP.UserId then return end   -- your OWN summon must not teleport you away
			if m.Text:lower():find(CHANT, 1, true) and tick() - mahoCd > 5 then mahoCd = tick(); mahoEscape() end
		end)
	end)
	-- anim path: catch the summon the instant an enemy plays it (earlier than the model streaming in)
	local mahoHooked = setmetatable({}, { __mode = "k" })
	local function hookMahoAnim(char)
		if not char or char.Name == LP.Name or char == LP.Character then return end
		local h = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController")
		local a = h and h:FindFirstChildOfClass("Animator")
		if a and not mahoHooked[a] then mahoHooked[a] = a.AnimationPlayed:Connect(function(track)
			if not mahoOn then return end
			local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
			if id and MAHO_ANIM[id] and tick() - mahoCd > 5 then mahoCd = tick(); mahoEscape() end
		end) end
	end
	task.spawn(function()
		while true do
			if mahoOn then
				local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do hookMahoAnim(m) end end
				for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then hookMahoAnim(plr.Character) end end
				if tick() - mahoCd > 5 and scanMahoraga() then mahoCd = tick(); mahoEscape() end   -- model-appearance fallback
			end
			task.wait(0.4)
		end
	end)

	-- ---------- AUTO EARTHQUAKE ----------
	-- Fire the Earthquake move ONCE, then WAIT for its real cooldown before firing again (the old 1.4s loop
	-- machine-gunned the remote = 'just spams the moves'). The move only lands when you're GROUNDED and it's
	-- off cooldown, so we gate on both.
	local quakeOn = false
	local function quakeRE()
		local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild("EarthquakeService"); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild("Activated")
	end
	local function fireQuake()
		local m = myModel(); local ms = m and m:FindFirstChild("Moveset"); local eq = ms and ms:FindFirstChild("Earthquake")
		local hum = m and m:FindFirstChildOfClass("Humanoid")
		if not eq then return false end                                    -- your character has no Earthquake move -> no-op
		if hum and hum.FloorMaterial == Enum.Material.Air then return false end   -- must be grounded for the quake to land
		local re = quakeRE()
		if re then pcall(function() re:FireServer(eq) end); return true end
		return false
	end
	-- fireQuake is the fallback used by the key trigger below when the key hold didn't actually start the move.

	-- ---------- AUTO KILL-EMOTE ----------
	-- When a nearby enemy DIES, play your emote (taunt on the kill) via the EmoteService remote. No teleport
	-- onto the body - it just fires the emote where you stand. Death is detected by watching each enemy's
	-- health drop from >0 to <=0 (reliable for JJS enemies that ragdoll instead of firing Humanoid.Died).
	local killEmoteOn, killEmoteSlot, keCd = false, 1, 0
	local hpSeen = setmetatable({}, { __mode = "k" })   -- humanoid -> last seen health
	local function doKillEmote()
		if tick() - keCd < 1.5 then return end
		keCd = tick()
		local re = emoteRE("Emote"); if re then pcall(function() re:FireServer(killEmoteSlot) end) end
		task.delay(2.8, function()
			local re2 = emoteRE("EmoteEnd"); if re2 then pcall(function() re2:FireServer() end) end
		end)
	end
	task.spawn(function()
		while true do
			if killEmoteOn then
				local mh = myHRP()
				local function chk(char)
					if not char or char.Name == LP.Name or char == LP.Character then return end
					local hum = char:FindFirstChildOfClass("Humanoid"); local r = char:FindFirstChild("HumanoidRootPart")
					if not hum or not r then return end
					local prev = hpSeen[hum]
					if prev ~= nil and prev > 0 and hum.Health <= 0 then   -- just died
						if mh and (r.Position - mh.Position).Magnitude <= 130 then doKillEmote() end   -- only taunt a kill near you (yours)
					end
					hpSeen[hum] = hum.Health
				end
				for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
				local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
			end
			task.wait(0.25)
		end
	end)

	MahoTpApi   = { set = function(v) mahoOn = v == true end }
	AutoQuakeApi = { set = function(v) quakeOn = v == true end }
	-- Earthquake: you tap 3, the script does the charged hold for you (Quake Hold slider = the length).
	-- TWO paths so it ALWAYS lands: (1) the key hold; (2) if your body never actually played the quake
	-- windup anim, the move clearly didn't start — fire it directly through its own service as a fallback.
	do
		local VIMq = game:GetService("VirtualInputManager")
		local UISq = game:GetService("UserInputService")
		local QUAKE_ANIM = "rbxassetid://85024950165903"
		local holding = false
		local quakeAnimSeen = 0
		task.spawn(function()   -- watch your live rig for the quake windup anim (proof the move started)
			local hooked = setmetatable({}, { __mode = "k" })
			while true do
				task.wait(0.6)
				pcall(function()
					local chs = workspace:FindFirstChild("Characters")
					local body = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
					local hum = body and body:FindFirstChildOfClass("Humanoid")
					local a = hum and hum:FindFirstChildOfClass("Animator")
					if a and not hooked[a] then
						hooked[a] = a.AnimationPlayed:Connect(function(tr)
							local ok, id = pcall(function() return tr.Animation.AnimationId end)
							if ok and tostring(id):find("85024950165903") then quakeAnimSeen = tick() end
						end)
					end
				end)
			end
		end)
		-- nearest player OR dummy within range (the trigger for the auto quake)
		local function enemyNear(range)
			local mh = myHRP(); if not mh then return false end
			local function chk(m)
				if not m or m == myModel() or m.Name == LP.Name then return false end
				local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid")
				if not r then return false end
				if h and h.Health <= 0 then return false end
				return (r.Position - mh.Position).Magnitude <= range
			end
			for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP and chk(pl.Character) then return true end end
			local chs = workspace:FindFirstChild("Characters")
			if chs then for _, m in ipairs(chs:GetChildren()) do if chk(m) then return true end end end
			local dummies = workspace:FindFirstChild("Dummies") or workspace:FindFirstChild("Training")
			if dummies then for _, m in ipairs(dummies:GetChildren()) do if chk(m) then return true end end end
			return false
		end
		-- One charged quake. You tap 3; from that instant the key is kept down for the full charge time and
		-- re-asserted every 80ms, so even if your finger lifts early the charge never drops. One clean release
		-- fires the shockwave, and the move's own service is fired in parallel as a backup.
		local function doQuake()
			if holding then return end
			holding = true
			task.spawn(function()
				local hold = tonumber(_G.VX_QUAKE_HOLD) or 2
				local began = tick()
				_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Three] = tick() + hold + 0.4
				pcall(function()
					local t0 = tick()
					VIMq:SendKeyEvent(true, Enum.KeyCode.Three, false, game)     -- 3 down
					while tick() - t0 < hold do
						_G.VX_INJ_KEYS[Enum.KeyCode.Three] = tick() + 0.4
						VIMq:SendKeyEvent(true, Enum.KeyCode.Three, false, game)  -- keep it held for you
						task.wait(0.04)
					end
					VIMq:SendKeyEvent(false, Enum.KeyCode.Three, false, game)     -- let go -> shockwave
				end)
				task.wait(0.25)
				local sawAnim = quakeAnimSeen >= began
				if not sawAnim then pcall(fireQuake) end
				_G.VX_QUAKE_LAST = tick(); _G.VX_QUAKE_LASTMSG = string.format("held 3 for %.1fs | windup seen=%s", hold, tostring(sawAnim))
				if _G.VX_QUAKE_DEBUG then pcall(function() print(string.format("[QUAKE] held 3 for %.1fs | windup anim seen=%s | service backup fired=%s", hold, tostring(sawAnim), tostring(not sawAnim))) end) end
				holding = false
			end)
		end
		-- Free build: no auto-pressing. The move only starts when YOU tap 3 — then it is held 2s for you.
		-- Non-free (future Plus): keep the near-enemy auto loop.
		if not _G.JJS_FREE then
			task.spawn(function()
				while true do
					task.wait(0.3)
					if quakeOn and not holding and enemyNear(tonumber(_G.VX_QUAKE_RANGE) or 60) then
						doQuake()
						task.wait((tonumber(_G.VX_QUAKE_HOLD) or 2) + 2.5)
					end
				end
			end)
		end
		-- The trigger: your own tap on 3. On the press we take over and hold it for the charge length.
		-- (No gameProcessedEvent check — the game sinks the ability key, which would otherwise swallow the trigger.)
		UISq.InputBegan:Connect(function(input)
			if input.KeyCode ~= Enum.KeyCode.Three then return end
			if not quakeOn then return end
			if UISq:GetFocusedTextBox() then return end
			local injK = _G.VX_INJ_KEYS
			if injK and injK[Enum.KeyCode.Three] and tick() < injK[Enum.KeyCode.Three] then return end   -- our own injected press
			doQuake()
		end)
		-- If you TAP (finger lifts right after), that physical key-up would end the charge early on a
		-- hold-to-charge move. While we hold it for you, re-press the instant your release is seen.
		UISq.InputEnded:Connect(function(input)
			if input.KeyCode ~= Enum.KeyCode.Three then return end
			if not (quakeOn and holding) then return end
			pcall(function() VIMq:SendKeyEvent(true, Enum.KeyCode.Three, false, game) end)
		end)
	end
	KillEmoteApi = { set = function(v) killEmoteOn = v == true end, setSlot = function(n) killEmoteSlot = tonumber(n) or 1 end }
end

-- ============================================================
-- MODULE: YUTA BLACK FLASH  (manual assist on your Yuta M1 + fully-auto teleport-kill flash)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local manualOn, autoOn, last = false, false, 0
	-- every Yuta / Yuta-Ult M1 anim id (from the M1 database) -> detect YOUR Yuta M1 landing
	local YUTA_M1 = {
		["133240987753043"] = true, ["130806585141471"] = true, ["131967150738931"] = true, ["84442064935420"] = true,
		["109432265703187"] = true, ["137919635923292"] = true, ["135256592475167"] = true, ["121403322067812"] = true,
	}
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function getHRP(m) return m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("UpperTorso")) end
	local function nearestEnemy(maxD)
		local mh = getHRP(myModel()); if not mh then return nil end
		local best, bd = nil, maxD
		local function chk(m)
			if not m or m == myModel() or m.Name == LP.Name then return end
			local r = getHRP(m); local h = m:FindFirstChildOfClass("Humanoid")
			if not r or (h and h.Health <= 0) then return end
			local d = (r.Position - mh.Position).Magnitude; if d < bd then bd = d; best = m end
		end
		for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then chk(pl.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if m:IsA("Model") then chk(m) end end end
		return best
	end
	local LOW_HP = 0.35   -- Yuta kill only fires when the target is LOW: at or below 35% health (the finisher)
	local function isLow(tgt)
		local h = tgt and tgt:FindFirstChildOfClass("Humanoid")
		if not h or h.MaxHealth <= 0 then return false end
		return (h.Health / h.MaxHealth) <= LOW_HP and h.Health > 0
	end
	-- YUTA BLACK FLASH mechanic (user): press move "2" TWICE and it black-flashes. Anim rbxassetid://89582140026963
	-- is the black-flash itself. So we double-tap the 2 key (its own move), not a custom teleport chain.
	local VIMy = game:GetService("VirtualInputManager")
	local function flash(tgt, requireLow)
		if tick() - last < 1.6 then return end
		if not (tgt and tgt.Parent) then return end
		if requireLow and not isLow(tgt) then return end   -- low-HP gate is ONLY for the auto kill mode (it blocked the manual toggle on full-HP targets = 'don't work')
		last = tick()
		_G.VX_INJECT_UNTIL = tick() + 1.2   -- our 2-taps must not trigger other features
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Two] = tick() + 1.2
		task.spawn(function()               -- Resolute Slash: press 2, wait for the slash, press 2 AGAIN = the black flash
			pcall(function() VIMy:SendKeyEvent(true, Enum.KeyCode.Two, false, game); task.wait(0.06); VIMy:SendKeyEvent(false, Enum.KeyCode.Two, false, game) end)
			task.wait(0.45)                  -- 'USE AGAIN' window: the first slash has to come out before the re-press converts
			pcall(function() VIMy:SendKeyEvent(true, Enum.KeyCode.Two, false, game); task.wait(0.06); VIMy:SendKeyEvent(false, Enum.KeyCode.Two, false, game) end)
		end)
	end
	-- MANUAL "Yuta Black Flash" (user spec): when YOUR animator plays rbxassetid://89582140026963 (the
	-- black-flash-ready anim), the script presses 2 TWICE for you = the flash. No HP gate.
	local YUTA_BF_ANIM = "89582140026963"
	local function doubleTapTwo()
		if tick() - last < 1.4 then return end
		last = tick()
		_G.VX_INJECT_UNTIL = tick() + 1.2
		_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Two] = tick() + 1.2
		task.spawn(function()
			pcall(function() VIMy:SendKeyEvent(true, Enum.KeyCode.Two, false, game); task.wait(0.06); VIMy:SendKeyEvent(false, Enum.KeyCode.Two, false, game) end)
			task.wait(0.4)
			pcall(function() VIMy:SendKeyEvent(true, Enum.KeyCode.Two, false, game); task.wait(0.06); VIMy:SendKeyEvent(false, Enum.KeyCode.Two, false, game) end)
		end)
		if VX_NOTIFY then pcall(function() VX_NOTIFY("Yuta BF: 2 + 2", nil) end) end
	end
	local hookedY = setmetatable({}, { __mode = "k" })
	local function hookSelfY()
		local m = myModel(); local h = m and m:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
		if not a or hookedY[a] then return end
		hookedY[a] = a.AnimationPlayed:Connect(function(track)
			if not manualOn then return end
			local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
			if id == YUTA_BF_ANIM then doubleTapTwo() end
		end)
	end
	task.spawn(function() while true do if manualOn then pcall(hookSelfY) end task.wait(0.6) end end)
	-- SECOND trigger (in case the anim never reaches your animator): YOU press 2 as Yuta -> the script
	-- adds the second 2 = the 'use again' black flash. Shared debounce with the anim path.
	local function charIsYuta()
		local c = myModel(); if not c then return false end
		local h = c:FindFirstChildOfClass("Humanoid")
		local hay = string.lower((c.Name or "") .. " " .. (h and h.DisplayName or ""))
		local mv = c:FindFirstChild("Moveset"); if mv then for _, m in ipairs(mv:GetChildren()) do hay = hay .. " " .. string.lower(m.Name) end end
		return (hay:find("yuta", 1, true) or hay:find("resolute", 1, true) or hay:find("severing", 1, true) or hay:find("true love", 1, true)) ~= nil
	end
	local UISy = game:GetService("UserInputService")
	UISy.InputBegan:Connect(function(input)
		if not manualOn or UISy:GetFocusedTextBox() then return end
		if input.KeyCode ~= Enum.KeyCode.Two then return end
		local injK = _G.VX_INJ_KEYS
		if injK and injK[Enum.KeyCode.Two] and tick() < injK[Enum.KeyCode.Two] then return end   -- our own re-press: don't loop
		if not charIsYuta() then return end
		if tick() - last < 1.4 then return end
		last = tick()
		task.delay(0.45, function()   -- your 2 fired the slash -> the script presses 2 AGAIN = the flash
			_G.VX_INJECT_UNTIL = tick() + 0.5
			_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Two] = tick() + 0.5
			pcall(function() VIMy:SendKeyEvent(true, Enum.KeyCode.Two, false, game); task.wait(0.06); VIMy:SendKeyEvent(false, Enum.KeyCode.Two, false, game) end)
			if VX_NOTIFY then pcall(function() VX_NOTIFY("Yuta BF: second 2", nil) end) end
		end)
	end)
	-- AUTO "Yuta Teleport Kill Black Flash": fully automatic - hunt the nearest LOW-HP enemy and finish them.
	local function nearestLowEnemy(maxD)
		local mh = getHRP(myModel()); if not mh then return nil end
		local best, bd = nil, maxD
		local function chk(m)
			if not m or m == myModel() or m.Name == LP.Name then return end
			local r = getHRP(m); if not r or not isLow(m) then return end
			local d = (r.Position - mh.Position).Magnitude; if d < bd then bd = d; best = m end
		end
		for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then chk(pl.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if m:IsA("Model") then chk(m) end end end
		return best
	end
	task.spawn(function()
		while true do
			if autoOn then local t = nearestLowEnemy(45); if t then flash(t, true) end task.wait(0.25) else task.wait(0.3) end
		end
	end)
	YutaBFApi = {
		setManual = function(v) manualOn = v == true end,
		setAuto   = function(v) autoOn = v == true end,
	}
end

-- ============================================================
-- MODULE: MISC EXTRAS  (Walk Into Domains, Spam Dash Noises, Unlock Extra Emote Slot, Instant Respawn)
-- ============================================================
do
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local LP = Players.LocalPlayer
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end

	-- ---------- WALK INTO DOMAINS ----------
	-- Normally a domain's barrier/collider traps you (sure-hit dome). This drops CanCollide/CanTouch on the
	-- domain's barrier parts so you can walk straight in/out of any domain.
	local walkDomOn = false
	local function isBarrier(n) n = n:lower(); return n:find("collider") or n:find("barrier") or n:find("wall") or n:find("dome") or n:find("border") or n:find("shell") or n:find("sphere") end
	-- ═══ WHY THIS DID NOTHING ═══ It only ever looked inside workspace.Domains and only matched parts BY NAME.
	-- JJS does not reliably park a cast domain there - it can sit directly in workspace, under the caster's
	-- model, or in a per-domain folder - and the barrier part is often generically named ("Part", "Union").
	-- Now: find domain CONTAINERS by keyword anywhere in workspace, and inside one treat any part that is
	-- barrier-named OR simply huge (a sure-hit dome is enormous; nothing else in a domain is) as the barrier.
	local DOM_WORDS = { "domain", "expansion", "malevolent", "shrine", "unlimited", "void", "chimera", "selfembodiment", "coffin", "horizon" }
	local function looksLikeDomain(name)
		local n = string.lower(tostring(name)):gsub("[%s_%-]", "")
		for _, w in ipairs(DOM_WORDS) do if string.find(n, w, 1, true) then return true end end
		return false
	end
	local function openPart(d)
		if not d:IsA("BasePart") then return end
		local sz = d.Size
		local huge = (sz.X > 55 or sz.Y > 55 or sz.Z > 55)     -- a sure-hit dome; regular props are not this big
		if huge or isBarrier(d.Name) or isBarrier((d.Parent and d.Parent.Name) or "") then
			pcall(function() d.CanCollide = false; d.CanTouch = false; d.CanQuery = false end)
		end
	end
	local function sweepDomains()
		local roots = {}
		local folder = workspace:FindFirstChild("Domains")
		if folder then roots[#roots + 1] = folder end
		for _, v in ipairs(workspace:GetChildren()) do
			if v ~= folder and looksLikeDomain(v.Name) then roots[#roots + 1] = v end
		end
		for _, root in ipairs(roots) do
			for _, d in ipairs(root:GetDescendants()) do openPart(d) end
		end
	end
	task.spawn(function()
		while true do
			if walkDomOn then pcall(sweepDomains) end
			task.wait(0.35)
		end
	end)
	-- LIVE: a domain cast AFTER you switched this on has to be opened on the frame it appears, not up to
	-- 0.35s later - by then the sure-hit has already closed around you. This catches it as it spawns.
	workspace.DescendantAdded:Connect(function(d)
		if not walkDomOn then return end
		if not d:IsA("BasePart") then return end
		task.defer(function()
			if not walkDomOn or not d.Parent then return end
			local a = d
			for _ = 1, 6 do                              -- walk up a few levels looking for a domain container
				if not a or a == workspace then return end
				if looksLikeDomain(a.Name) then openPart(d); return end
				a = a.Parent
			end
		end)
	end)

	-- ---------- SPAM DASH NOISES ----------
	-- Rapidly fire the game's own dash remote alternating opposite directions (net movement ~0) = the dash
	-- swoosh spams without launching you across the map.
	local dashNoiseOn = false
	task.spawn(function()
		local flip = true
		while true do
			if dashNoiseOn then
				flip = not flip
				pcall(function() fireKnit("MovementService", "Dash", flip and "Left" or "Right", false) end)
				task.wait(0.14)
			else task.wait(0.3) end
		end
	end)

	-- ---------- UNLOCK EXTRA EMOTE SLOT ----------
	-- Best-effort: ping the EmoteService for the extra slot (some builds gate a bonus slot behind a remote).
	local function emoteRE(name)
		local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild("EmoteService"); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild(name)
	end
	local function unlockEmoteSlot()
		for _, nm in ipairs({ "Unlock", "UnlockSlot", "ExtraSlot", "Purchase" }) do
			local re = emoteRE(nm); if re then pcall(function() re:FireServer() end) end
		end
		if VX_NOTIFY then VX_NOTIFY("Emote slot unlock sent", true) end
	end

	-- ---------- INSTANT RESPAWN ----------
	-- On death, immediately request a fresh character (skip the death screen wait) via the reset binding.
	local instaOn = false
	local function requestRespawn()
		pcall(function() LP:LoadCharacter() end)  -- executors with elevated context respawn instantly; no-op otherwise
	end
	task.spawn(function()
		while true do
			if instaOn then
				local m = LP.Character or myModel()
				local h = m and m:FindFirstChildOfClass("Humanoid")
				if h and h.Health <= 0 then requestRespawn(); task.wait(1.2) end
			end
			task.wait(0.3)
		end
	end)

	WalkDomainApi = { set = function(v) walkDomOn = v == true end }
	DashNoiseApi  = { set = function(v) dashNoiseOn = v == true end }
	EmoteSlotApi  = { unlock = unlockEmoteSlot }
	InstaRespawnApi = { set = function(v) instaOn = v == true end, now = requestRespawn }   -- now() = respawn RIGHT NOW (the button)
end

-- ============================================================
-- MODULE: JUMP ON HEAD  (teleport above a target's head, play walk then jump animation)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local WALK, JUMP = "rbxassetid://96489184596023", "rbxassetid://134343219970072"
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function animatorOf() local m = myModel(); local h = m and m:FindFirstChildOfClass("Humanoid"); return h and h:FindFirstChildOfClass("Animator") end
	local function play(id) local a = animatorOf(); if not a then return end local anim = Instance.new("Animation"); anim.AnimationId = id; local ok, t = pcall(function() return a:LoadAnimation(anim) end); if ok and t then pcall(function() t:Play() end) end end
	local function nearestModel()
		local m = myModel(); local hrp = m and m:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
		local best, bd
		local function chk(c) if c and c.Name ~= LP.Name and c ~= LP.Character then local h = c:FindFirstChildOfClass("Humanoid"); local r = c:FindFirstChild("HumanoidRootPart"); if h and h.Health > 0 and r then local d = (r.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = c, d end end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, c in ipairs(chs:GetChildren()) do chk(c) end end
		return best
	end
	local function resolve(name)
		if name and name ~= "Nearest" and name ~= "(none)" then
			local p = Players:FindFirstChild(name); if p and p.Character then return p.Character end
			local chs = workspace:FindFirstChild("Characters"); if chs then local m = chs:FindFirstChild(name); if m then return m end end
		end
		return nearestModel()
	end
	JumpHeadApi = { jump = function(name)
		local tgt = resolve(name); local head = tgt and (tgt:FindFirstChild("Head") or tgt:FindFirstChild("HumanoidRootPart"))
		if not head then if VX_NOTIFY then VX_NOTIFY("No target for Jump On Head", false) end return end
		play(WALK)
		vxGlide(head.Position + Vector3.new(0, 4.5, 0))
		task.delay(0.3, function() play(JUMP) end)
	end }
end

-- ============================================================
-- MODULE: SPECIAL ULTS  (Auto Ult Head of Hei: your M1 -> press G | Auto Rika Love Sword: inside a domain, slash 4 users then press 4)
-- ============================================================
do
	local Players = game:GetService("Players")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer
	local headOn, swordOn = false, false
	local SWORD_ANIM = "rbxassetid://72914783159396"         -- Rika love-ladder sword slash
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local m = myModel(); return m and m:FindFirstChild("HumanoidRootPart") end
	local function animatorOf() local m = myModel(); local h = m and m:FindFirstChildOfClass("Humanoid"); return h and h:FindFirstChildOfClass("Animator") end
	local function play(id) local a = animatorOf(); if not a then return end local anim = Instance.new("Animation"); anim.AnimationId = id; local ok, t = pcall(function() return a:LoadAnimation(anim) end); if ok and t then pcall(function() t:Play() end) end end
	local function pressKey(kc) pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(0.05); VIM:SendKeyEvent(false, kc, false, game) end) end

	-- AUTO ULT HEAD OF HEI: when YOUR character plays an M1 ANIMATION (any character's M1 id, shared via _G.VX_M1_IDS) -> press G to ult. Anim-based = fires on a real M1 (incl. hitting the dummy), not just a raw click.
	local UIS = game:GetService("UserInputService")
	local HEI_LEAD = 0.26    -- press G as the M1 CONNECTS; adjustable in the UI ('Hei Ult Timing' slider).
	local heiCd = 0
	local function heiFire()
		if tick() - heiCd < 1.2 then return end
		heiCd = tick()
		task.delay(HEI_LEAD, function() if headOn then pressKey(Enum.KeyCode.G); if VX_NOTIFY then pcall(function() VX_NOTIFY("Head of Hei: G", nil) end) end end end)
	end
	local heiHooked = setmetatable({}, { __mode = "k" })
	local function hookHei()
		local a = animatorOf(); if not a or heiHooked[a] then return end
		heiHooked[a] = a.AnimationPlayed:Connect(function(track)
			if not headOn then return end
			if _G.VX_IS_M1 and _G.VX_IS_M1(track) then heiFire() end  -- strict: real M1 swings only
		end)
	end
	task.spawn(function() while true do if headOn then hookHei() end task.wait(0.7) end end)
	-- G is pressed ONLY off the detected M1 ANIMATION (any character's M1 id) + a 1.2s cooldown = one timed G per
	-- M1 swing, not a spam. (Removed the raw-click backup, which fired G on every click incl. GUI clicks.)
	HeadUltApi = { set = function(v) headOn = v == true end, setLead = function(v) HEI_LEAD = math.clamp(tonumber(v) or 0.26, 0.05, 0.6) end }

	local function findSwords()  -- ONLY the exact "Sword" objects at workspace.Domains.Domain.DomainCollider.Sword (NOT the "long" swords)
		local domains = workspace:FindFirstChild("Domains"); if not domains then return {} end
		local list = {}
		local dom = domains:FindFirstChild("Domain"); local coll = dom and dom:FindFirstChild("DomainCollider")
		if coll then for _, d in ipairs(coll:GetChildren()) do if d.Name == "Sword" then list[#list + 1] = d end end end   -- exact name = only these swords, not longs
		if #list == 0 then for _, d in ipairs(domains:GetDescendants()) do if d.Name == "Sword" then list[#list + 1] = d end end end  -- fallback if the domain nests differently
		return list
	end
	local function swordPos(s)
		if s:IsA("BasePart") then return s.Position end
		local ok, cf = pcall(function() return s:GetPivot() end); if ok and cf then return cf.Position end
		local p = s:FindFirstChildWhichIsA("BasePart", true); return p and p.Position
	end
	local function grabSword(sword)  -- EQUIP the sword: if it's a Tool -> EquipTool/reparent to your character; also fire any ProximityPrompt / ClickDetector / Touched so the pickup registers
		local hrp = myHRP(); if not hrp then return end
		local m = myModel(); local hum = m and m:FindFirstChildOfClass("Humanoid")
		local tool = (sword:IsA("Tool") and sword) or sword:FindFirstChildWhichIsA("Tool")
		if tool and m then pcall(function() if hum then hum:EquipTool(tool) else tool.Parent = m end end) end
		local parts = sword:IsA("BasePart") and { sword } or sword:GetDescendants()
		for _, d in ipairs(parts) do
			pcall(function()
				if d:IsA("ProximityPrompt") and fireproximityprompt then fireproximityprompt(d) end
				if d:IsA("ClickDetector") and fireclickdetector then fireclickdetector(d) end
				if d:IsA("BasePart") and firetouchinterest then firetouchinterest(hrp, d, 0); task.wait(); firetouchinterest(hrp, d, 1) end
			end)
		end
	end
	local function nearbyEnemies()  -- living enemies near you (you are standing in the domain)
		local hrp = myHRP(); if not hrp then return {} end
		local list = {}
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); if r and (not h or h.Health > 0) and (r.Position - hrp.Position).Magnitude <= 220 then list[#list + 1] = m end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
		return list
	end
	local function domainActive() local d = workspace:FindFirstChild("Domains"); if d then for _, ch in ipairs(d:GetChildren()) do if ch:IsA("Model") or ch:IsA("Folder") then return true end end end return false end
	local function note(msg) if VX_NOTIFY then pcall(function() VX_NOTIFY(msg, nil) end) end end  -- shows only when Debug is on
	local busy = false
	task.spawn(function()
		while true do
			if swordOn and not busy and (domainActive() or #findSwords() > 0) then   -- run when you are inside a domain (swords present)
				busy = true
				task.spawn(function()
					local hits = 0
					local swords = findSwords()
					note("Rika: " .. tostring(#swords) .. " swords found")
					-- LOCK ON one target (nearest user) for the whole barrage - every slash goes to THEM
					local hrp0 = myHRP(); local users = nearbyEnemies()
					if #users == 0 or not hrp0 then note("Rika: no users near"); task.wait(0.5); busy = false; return end
					local target, td
					for _, u in ipairs(users) do local r = u:FindFirstChild("HumanoidRootPart"); if r then local dd = (r.Position - hrp0.Position).Magnitude; if not td or dd < td then target, td = u, dd end end end
					if _G.VX_LOCK and _G.VX_LOCK.set then pcall(function() _G.VX_LOCK.set(target) end) end; note("Rika: locked " .. (target and target.Name or "?"))
					-- GRAB every sword (up to 30) and slash the LOCKED target with each one
					local n = math.min(#swords, 30)
					for i = 1, n do
						if not swordOn or not (target and target.Parent) then break end
						local sw = swords[i]; local sp = sw and sw.Parent and swordPos(sw)
						if sp then vxGlide(sp + Vector3.new(0, 3, 0)); task.wait(0.14); grabSword(sw) end   -- grab this sword
						if not swordOn then break end
						local r = target:FindFirstChild("HumanoidRootPart")
						if r then
							local ang = i * 1.4; local off = Vector3.new(math.cos(ang), 0, math.sin(ang)) * 4   -- CIRCLE around them so slashes land from every angle = breaks their block
							vxGlide(CFrame.lookAt(r.Position + off + Vector3.new(0, 2, 0), r.Position)); task.wait(0.05); play(SWORD_ANIM); hits = hits + 1
						end
						task.wait(0.2)
					end
					if swordOn and hits > 0 then pressKey(Enum.KeyCode.Four) end                -- finish: press 4
					note("Rika: done, " .. hits .. " slashes")
					task.wait(1.2)
					busy = false
				end)
			end
			task.wait(0.3)
		end
	end)
	RikaSwordApi = { set = function(v) swordOn = v == true; if not swordOn and _G.VX_LOCK and _G.VX_LOCK.set then pcall(function() _G.VX_LOCK.set(nil) end) end end }  -- clear the red outline when turned off
end

-- ============================================================
-- MODULE: AUTO RIKA DOWN SLAM  (toggle - near a target / the locked target: press R, then press 2)
-- ============================================================
do
	local Players = game:GetService("Players")
	local VIM = game:GetService("VirtualInputManager")
	local LP = Players.LocalPlayer
	local on, last = false, 0
	local function myHRP() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function targetNear()  -- near an enemy/dummy OR the locked target, within ~16 studs
		local hrp = myHRP(); if not hrp then return false end
		local function isNear(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); return r ~= nil and (not h or h.Health > 0) and (r.Position - hrp.Position).Magnitude <= 16 end return false end
		local g = _G.VX_LOCK; local lt = (g and g.get) and g.get() or nil; if lt and isNear(lt) then return true end  -- the locked target
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and isNear(plr.Character) then return true end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if isNear(m) then return true end end end
		return false
	end
	local function press(kc) pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(0.05); VIM:SendKeyEvent(false, kc, false, game) end) end
	task.spawn(function()
		while true do
			if on and tick() - last > 1.2 and targetNear() then
				last = tick()
				press(Enum.KeyCode.R)     -- 1) press R
				task.wait(0.12)
				press(Enum.KeyCode.Two)   -- 2) then press 2 = the down slam
			end
			task.wait(0.1)
		end
	end)
	SlamApi = { set = function(v) on = v == true end }
end

-- ============================================================
-- MODULE: GOKU M1  (toggle - when YOU play an M1, instant-transmission BEHIND the nearest enemy/dummy with a Goku pose + sound)
-- ============================================================
do
	local Players = game:GetService("Players")
	local Debris = game:GetService("Debris")
	local LP = Players.LocalPlayer
	local on, last = false, 0
	local GOKU_ANIM = "rbxassetid://96489184596023"
	local GOKU_SOUND = ""  -- <<< put your Goku SFX asset id here, e.g. "rbxassetid://123..."; empty = no sound until you give me the id
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local m = myModel(); return m and m:FindFirstChild("HumanoidRootPart") end
	local function animatorOf()  -- your Animator (under Humanoid OR AnimationController)
		local m = myModel(); if not m then return nil end
		local h = m:FindFirstChildOfClass("Humanoid") or m:FindFirstChildOfClass("AnimationController")
		return h and h:FindFirstChildOfClass("Animator")
	end
	local function note(msg) if VX_NOTIFY then pcall(function() VX_NOTIFY(msg, nil) end) end end  -- shows only with Debug on
	local function playGoku()
		task.spawn(function()
			local a; for _ = 1, 5 do a = animatorOf(); if a then break end task.wait(0.06) end  -- wait out the teleport for the animator to be ready
			if not a then note("Goku: no animator"); return end
			pcall(function() for _, tr in ipairs(a:GetPlayingAnimationTracks()) do local p = tr.Priority; if p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action4 then tr:Stop(0.05) end end end)  -- clear the M1 anim so the pose isn't buried
			local anim = Instance.new("Animation"); anim.AnimationId = GOKU_ANIM
			local ok, t = pcall(function() return a:LoadAnimation(anim) end)
			if not (ok and t) then note("Goku: anim FAILED to load (bad/private id?)"); return end
			pcall(function() t.Priority = Enum.AnimationPriority.Action4; t:Play(0.1) end)
			note("Goku: pose")
			for _ = 1, 12 do if not t.IsPlaying then pcall(function() t:Play(0.05) end) end task.wait(0.1) end  -- keep re-asserting for ~1.2s so PlatformStand/the game can't kill it
			pcall(function() t:Stop() end)
		end)
		if GOKU_SOUND ~= "" then pcall(function() local s = Instance.new("Sound"); s.SoundId = GOKU_SOUND; s.Volume = 3; s.Parent = myHRP() or workspace; s:Play(); Debris:AddItem(s, 3) end) end
	end
	local RS = game:GetService("ReplicatedStorage")
	local busy = false
	local function acPass() local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services"); local svc = k and k:FindFirstChild("AntiCheatService"); local re = svc and svc:FindFirstChild("RE"); re = re and re:FindFirstChild("Teleport"); if re then pcall(function() re:FireServer(workspace:GetServerTimeNow()) end) end end
	local function behindPos(er)  -- a point behind their back, ON THE GROUND (raycast down - floating in the air broke the follow-up M1)
		local look = er.CFrame.LookVector; local flat = Vector3.new(look.X, 0, look.Z); local dir = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
		local p = er.Position - dir * 3
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
		local ex = { myModel() }; if er.Parent then ex[#ex + 1] = er.Parent end
		rp.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -22, 0), rp)
		if hit then return Vector3.new(p.X, hit.Position.Y + 3, p.Z) end        -- feet on the floor behind them
		return Vector3.new(p.X, er.Position.Y, p.Z)                              -- no floor found: at least match THEIR height
	end
	local function goBehind(enemyChar)  -- TELEPORT-style Goku blink to behind them (grounded), then STAY behind ~1s
		local er = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart"); if not er or busy then return end
		busy = true
		playGoku()
		task.spawn(function()
			local hum = myModel() and myModel():FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum.PlatformStand = true end) end
			local t0 = tick()
			while tick() - t0 < 1.1 do
				local hrp = myHRP(); if not (hrp and er.Parent) then break end
				acPass()
				local dest = behindPos(er)
				local to = dest - hrp.Position; local d = to.Magnitude
				local step = math.min(d, 5)                                     -- ~5 studs/frame = a visible FLY, then tracks (stays behind) once there
				local nextPos = d > 0.05 and (hrp.Position + to.Unit * step) or hrp.Position
				pcall(function() hrp.CFrame = CFrame.lookAt(nextPos, er.Position); hrp.AssemblyLinearVelocity = Vector3.zero end)  -- face them the whole time
				task.wait()
			end
			if hum then pcall(function() hum.PlatformStand = false end) end
			busy = false
		end)
	end
	local function nearestEnemy()  -- closest enemy/DUMMY to you
		local hrp = myHRP(); if not hrp then return nil end
		local best, bd
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); if r and (not h or h.Health > 0) then local d = (r.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = m, d end end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
		return best
	end
	-- CLICK fallback: a LANDED left-click (enemy in front, melee range) triggers the Goku blink even when the
	-- anim-id detection misses (that miss = 'Goku M1 no work at all').
	do
		local UISg = game:GetService("UserInputService")
		UISg.InputBegan:Connect(function(input, gpe)
			if gpe or not on then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if tick() - last <= 0.6 then return end
			local mh = myHRP(); if not mh then return end
			local tgt = nearestEnemy(); local er = tgt and tgt:FindFirstChild("HumanoidRootPart")
			if not er then return end
			local to = er.Position - mh.Position
			if to.Magnitude <= 9 and mh.CFrame.LookVector:Dot(to.Unit) > 0.35 then last = tick(); task.delay(0.15, function() goBehind(tgt) end) end
		end)
	end
	-- fire on YOUR M1 (so it works when you M1 the dummy): flash behind the nearest enemy + Goku pose
	local hooked = setmetatable({}, { __mode = "k" })
	local function hookSelf()
		local a = animatorOf(); if not a or hooked[a] then return end
		hooked[a] = a.AnimationPlayed:Connect(function(track)
			if not on then return end
			if _G.VX_IS_M1 and _G.VX_IS_M1(track) and tick() - last > 0.6 then  -- strict: real M1 swings only
				local tgt = nearestEnemy(); local hrp = myHRP(); local er = tgt and tgt:FindFirstChild("HumanoidRootPart")
				if er and hrp and (er.Position - hrp.Position).Magnitude <= 45 then last = tick(); goBehind(tgt) end
			end
		end)
	end
	task.spawn(function() while true do if on then hookSelf() end task.wait(0.7) end end)
	-- ── GOKU DODGE ── blink LEFT or RIGHT the instant a NEARBY ENEMY plays an M1 animation, so their swing
	-- whiffs. Alternates side each dodge. Grounded sidestep (~13 studs) via the same AC-pass write as the blink.
	local dodgeOn, lastDodge, dodgeSide = false, 0, 1
	local dHooked = setmetatable({}, { __mode = "k" })
	local function sidestep()
		local hrp = myHRP(); if not hrp then return end
		dodgeSide = -dodgeSide
		local right = hrp.CFrame.RightVector; local flat = Vector3.new(right.X, 0, right.Z)
		local dir = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(1, 0, 0)
		local dest = hrp.Position + dir * (13 * dodgeSide)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = { myModel() }
		local hit = workspace:Raycast(dest + Vector3.new(0, 6, 0), Vector3.new(0, -24, 0), rp)
		if hit then dest = Vector3.new(dest.X, hit.Position.Y + 3, dest.Z) end
		acPass()
		pcall(function() hrp.CFrame = CFrame.new(dest, dest + hrp.CFrame.LookVector); hrp.AssemblyLinearVelocity = Vector3.zero end)
	end
	local function hookEnemyAnimsForDodge()
		local hrp = myHRP(); if not hrp then return end
		local chs = workspace:FindFirstChild("Characters"); if not chs then return end
		for _, m in ipairs(chs:GetChildren()) do
			if m.Name ~= LP.Name and m ~= LP.Character then
				local er = m:FindFirstChild("HumanoidRootPart")
				if er and (er.Position - hrp.Position).Magnitude <= 30 then
					local h = m:FindFirstChildOfClass("Humanoid") or m:FindFirstChildOfClass("AnimationController")
					local a = h and h:FindFirstChildOfClass("Animator")
					if a and not dHooked[a] then
						dHooked[a] = a.AnimationPlayed:Connect(function(track)
							if not dodgeOn then return end
							if _G.VX_IS_M1 and _G.VX_IS_M1(track) and tick() - lastDodge > 0.5 then
								local mh = myHRP(); local eh = m:FindFirstChild("HumanoidRootPart")
								if mh and eh and (eh.Position - mh.Position).Magnitude <= 22 then lastDodge = tick(); sidestep() end
							end
						end)
					end
				end
			end
		end
	end
	task.spawn(function() while true do if dodgeOn then pcall(hookEnemyAnimsForDodge) end task.wait(0.5) end end)
	GokuApi = { set = function(v) on = v == true end, setDodge = function(v) dodgeOn = v == true end }
end

-- ============================================================
-- MODULE: AUTO HOLLOW NUKE  (Hollow Purple: teleport to the lowest target -> Lapse Blue MAX -> aim at the blue orb -> Reversal Red MAX)
-- ============================================================
do
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local LP = Players.LocalPlayer
	local Camera = workspace.CurrentCamera
	local busy = false
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end
	local function note(m) if VX_NOTIFY then pcall(function() VX_NOTIFY(m, nil) end) end end
	local function activatedRE(svcName)
		local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild(svcName); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild("Activated")
	end
	local function moveObj(name)  -- the Moveset entry (LP.Character.Moveset[name]); try both char sources
		local chs = workspace:FindFirstChild("Characters")
		for _, c in ipairs({ (chs and chs:FindFirstChild(LP.Name)) or nil, LP.Character }) do
			if c then local mv = c:FindFirstChild("Moveset"); local m = mv and mv:FindFirstChild(name); if m then return m end end
		end
		return nil
	end
	local function fireMove(svcName, moveName)
		local re = activatedRE(svcName); local mv = moveObj(moveName)
		if re and mv then pcall(function() re:FireServer(mv) end); return true end
		note("Hollow: missing " .. (mv and svcName or ("Moveset " .. moveName)))
		return false
	end
	local function lowestTarget()  -- the living enemy with the LOWEST health
		local hrp = myHRP(); if not hrp then return nil end
		local best, bhp
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); if r and h and h.Health > 0 and (not bhp or h.Health < bhp) then best, bhp = m, h.Health end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
		return best
	end
	local function aimAt(pos)  -- face the character AND the camera at the point so the ability fires toward it
		local hrp = myHRP(); if not (hrp and pos) then return end
		pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(pos.X, hrp.Position.Y, pos.Z)) end)
		pcall(function() Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, pos) end)
	end
	HollowApi = { set = function(v)
		if not v or busy then return end
		busy = true
		task.spawn(function()
			local tgt = lowestTarget()
			local tr = tgt and tgt:FindFirstChild("HumanoidRootPart")
			if not tr then note("Hollow: no target"); busy = false; return end
			-- 1) move BACK away from the target (get distance to nuke), facing them
			local hrp = myHRP()
			if hrp then
				local away = hrp.Position - tr.Position; local dir = away.Magnitude > 1 and away.Unit or -tr.CFrame.LookVector
				local backPos = tr.Position + dir * 16 + Vector3.new(0, 3, 0)  -- back off only a LITTLE (closer to the target)
				vxGlide(CFrame.lookAt(backPos, Vector3.new(tr.Position.X, backPos.Y, tr.Position.Z)))
				note("Hollow: backed off from " .. tgt.Name); task.wait(0.3)
			end
			aimAt(tr.Position)                                                    -- face the target
			fireMove("LapseBlueMaxService", "Lapse Blue MAX")                     -- 2) Lapse Blue MAX
			task.wait(1.6)                                                        -- 3) FASTER charge before Red (was 3s)
			if tr and tr.Parent then aimAt(tr.Position); note("Hollow: aim target -> Red") end  -- 4) AIM at the SAME target it did, then fire Red
			task.wait(0.12)
			pcall(function() local VIM = game:GetService("VirtualInputManager"); VIM:SendKeyEvent(true, Enum.KeyCode.Two, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.Two, false, game) end)  -- CLICK 2 after Blue = combine into Hollow Purple
			fireMove("ReversalRedMaxService", "Reversal Red MAX")                 -- + fire the remote as backup
			task.wait(0.4); busy = false
		end)
	end }
end

-- ============================================================
-- MODULE: FORCE RESET  (force your character to reset / respawn)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	ResetApi = { reset = function()
		-- Force Reset that ACTUALLY kills you in JJS (Health=0 alone gets ignored by the custom-health system).
		-- Try every real kill path: Humanoid.Health=0, the Health attribute/value, the game's own reset request,
		-- and finally BreakJoints (the guaranteed one) — whatever the game respects, one of these ends you.
		local chs = workspace:FindFirstChild("Characters")
		local bodies = {}
		if chs and chs:FindFirstChild(LP.Name) then bodies[#bodies+1] = chs:FindFirstChild(LP.Name) end
		if LP.Character then bodies[#bodies+1] = LP.Character end
		for _, c in ipairs(bodies) do
			pcall(function()
				local h = c:FindFirstChildOfClass("Humanoid")
				if h then
					h:SetStateEnabled(Enum.HumanoidStateType.Dead, true)   -- JJS often DISABLES the Dead state so Health=0 is ignored; re-enable it first
					h.Health = 0; h.MaxHealth = 0
					h:TakeDamage(1e9)
					h:ChangeState(Enum.HumanoidStateType.Dead)             -- force the death state directly
				end
				c:SetAttribute("Health", 0)
				local hv = c:FindFirstChild("Health")
				if hv and hv:IsA("ValueBase") then hv.Value = 0 end
			end)
		end
		-- try the game's OWN reset/respawn remote (Knit services) - the path the game itself uses
		pcall(function()
			local RS = game:GetService("ReplicatedStorage")
			local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
			if k then for _, svc in ipairs(k:GetChildren()) do
				local re = svc:FindFirstChild("RE")
				if re then for _, nm in ipairs({ "Reset", "Respawn", "Die", "Kill", "Suicide" }) do
					local r = re:FindFirstChild(nm); if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
				end end
			end end
		end)
		-- the built-in reset button, fired programmatically via a BindableEvent (works when the game keeps default reset)
		pcall(function()
			local ev = Instance.new("BindableEvent")
			game:GetService("StarterGui"):SetCore("ResetButtonCallback", ev)
			ev:Fire()
		end)
		pcall(function() game:GetService("StarterGui"):SetCore("ResetButtonCallback", true) end)
		-- guaranteed fallback: break the rig so you die for sure
		for _, c in ipairs(bodies) do pcall(function() c:BreakJoints() end) end
	end }
end

-- ============================================================
-- MODULE: SIDE DASH ASSIST  (on M1, fire an L/R side dash - NO rotation snap, so it can't break your M1 combo state)
-- ============================================================
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on, last = false, 0
	-- EVERY character's M1 anim id (user-captured) -> detect a REAL M1 by animation, not an unreliable mouse click
	local M1_IDS = {}
	for _, id in ipairs({
		"133240987753043","127851700400958","120133391090244","94588892125071","75337033003776","126277739156443","96185406489877",
		"96327114254575","133936641185614","98783064085844","101283990868172","9443519528","84359513001979","89537672683114",
		"105077924973072","85068785050521","131909724908049","125689391910002","133447840605824","114985590391235","86519781516542",
	}) do M1_IDS[id] = true end
	if _G.VX_M1_IDS then for id in pairs(_G.VX_M1_IDS) do M1_IDS[id] = true end end
	_G.VX_M1_IDS = M1_IDS  -- MERGED with the master per-character list (this module used to clobber it with its short list = detection missing for most characters)
	-- RIGHT dash anim = rbxassetid://75203303352791 (what plays when you dash right; kept for reference)
	local function myModel() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function getHRP(m) return m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")) end
	local function nearestEnemy(maxD)  -- closest living enemy/dummy
		local mh = getHRP(myModel()); if not mh then return nil end
		local best, bd = nil, maxD
		local function chk(m)
			if not m or m == myModel() or m.Name == LP.Name then return end
			local r = getHRP(m); if not r then return end
			local h = m:FindFirstChildOfClass("Humanoid"); if h and h.Health <= 0 then return end
			local d = (r.Position - mh.Position).Magnitude; if d < bd then bd = d; best = m end
		end
		for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then chk(pl.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do if m:IsA("Model") then chk(m) end end end
		return best
	end
	-- play a client animation (the flourish the user asked for) so the left dash LOOKS like the real curve-around
	local function playAnim(id)
		pcall(function()
			local m = myModel(); local h = m and m:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
			if not a then return end
			local anim = Instance.new("Animation"); anim.AnimationId = id
			local t = a:LoadAnimation(anim); t.Priority = Enum.AnimationPriority.Action2; t:Play(0.05)
			task.delay(0.5, function() pcall(function() t:Stop() end) end)
		end)
	end
	local sdaInjecting = 0
	-- SIDE DASH ASSIST (user spec v2): fires ONLY when YOU press Q — never off an M1 anim (that dashed you when you
	-- never clicked). Q -> short FAST LEFT dash (the game's Dash remote is validation-only per the user's own test,
	-- so we drive a client velocity LEFT) -> face the enemy -> throw one M1. Left = -RightVector. Short = no over-glide.
	local function trigger()
		if not on then return end
		if tick() - last < 0.4 then return end                     -- one dash per press
		if tick() < sdaInjecting then return end
		if tick() - (_G.VX_LAUNCHING or 0) < 0.3 then return end   -- not during an uppercut launch
		if tick() < (_G.VX_BUSY or 0) then return end              -- not during an Auto Air sequence
		local mh = getHRP(myModel()); if not mh then return end
		local tgt = nearestEnemy(18); local tr = tgt and getHRP(tgt)
		if not tr then return end   -- no enemy nearby -> don't dash for nothing (was firing with no target = felt broken)
		last = tick(); sdaInjecting = tick() + 0.3
		_G.VX_INJECT_UNTIL = tick() + 0.3
		if _G.VX_CLAIMOWN then pcall(_G.VX_CLAIMOWN) end   -- the velocity write below is cosmetic without network ownership
		playAnim("rbxassetid://95295463826732"); playAnim("rbxassetid://75203303352791")   -- the two anim ids the user gave
		fireKnit("MovementService", "Dash", "Left", true)   -- harmless if validation-only; the velocity below is the real mover
		task.spawn(function()
			-- SHORT pure-LEFT push (0.1s @ 80 ≈ 8 studs) — enough to whip left, short enough it can't "glide too far"
			local t0 = tick()
			while tick() - t0 < 0.10 do
				local mh2 = getHRP(myModel()); if not mh2 then break end
				local v = -mh2.CFrame.RightVector * 80   -- PURE LEFT (no forward/right component)
				pcall(function() mh2.AssemblyLinearVelocity = Vector3.new(v.X, math.min(mh2.AssemblyLinearVelocity.Y, 0), v.Z) end)
				task.wait()
			end
			local mhS = getHRP(myModel()); if mhS then pcall(function() local vv = mhS.AssemblyLinearVelocity; mhS.AssemblyLinearVelocity = Vector3.new(0, vv.Y, 0) end) end   -- stop dead, no residual slide
			local mh3 = getHRP(myModel()); local tr3 = tgt and tgt.Parent and getHRP(tgt)
			if mh3 and tr3 then pcall(function() mh3.CFrame = CFrame.lookAt(mh3.Position, Vector3.new(tr3.Position.X, mh3.Position.Y, tr3.Position.Z)) end) end   -- face them
			local VIM = game:GetService("VirtualInputManager")
			local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(800, 600)
			pcall(function() VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0); task.wait(0.04); VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0) end)   -- M1 for you
		end)
		if _G.VX_BF_DEBUG then print("[DreamHub SideDash] Q -> Left dash + M1 at "..(tgt and tgt.Name or "no target")) end
	end
	UIS.InputBegan:Connect(function(input, gpe)
		if not on or gpe then return end
		if UIS:GetFocusedTextBox() then return end
		if input.KeyCode ~= Enum.KeyCode.Q then return end
		do local injK = _G.VX_INJ_KEYS; if injK and injK[Enum.KeyCode.Q] and tick() < injK[Enum.KeyCode.Q] then return end end
		trigger()
	end)
	-- BLOCK PUNISH (part of Side Dash Assist): the enemy you're hitting raises BLOCK -> instantly get BEHIND
	-- them and M1 (their block faces the wrong way = free hit). This is the 'escape their block and hit them'.
	local lastPunish = 0
	local function targetBlocking(tgt)
		if not tgt then return false end
		local info = tgt:FindFirstChild("Info")
		if info then for _, nm in ipairs({ "Block", "Blocking", "IsBlocking", "Guard" }) do
			local v = info:FindFirstChild(nm); if v and v.Value and v.Value ~= false and v.Value ~= 0 then return true end
		end end
		local h = tgt:FindFirstChildOfClass("Humanoid")
		if h and (h:GetAttribute("Blocking") == true or h:GetAttribute("Block") == true) then return true end
		return false
	end
	task.spawn(function()
		local VIMs = game:GetService("VirtualInputManager")
		while true do
			task.wait(0.12)
			if on and tick() - lastPunish > 1.6 and tick() >= (_G.VX_BUSY or 0) then
				local mh = getHRP(myModel())
				local tgt = nearestEnemy(10); local tr = tgt and getHRP(tgt)
				if mh and tr and targetBlocking(tgt) then
					lastPunish = tick()
					-- DASH around their guard (real dash remote + velocity), NO CFrame teleport
					local side = math.random(1, 2) == 1 and "Left" or "Right"
					fireKnit("MovementService", "Dash", side, true)
					local rv = side == "Left" and -mh.CFrame.RightVector or mh.CFrame.RightVector
					task.spawn(function()
						local t0 = tick()
						while tick() - t0 < 0.16 do
							local h = getHRP(myModel()); if not h then break end
							pcall(function() h.AssemblyLinearVelocity = Vector3.new(rv.X * 70, math.min(h.AssemblyLinearVelocity.Y, 0), rv.Z * 70); h.CFrame = CFrame.lookAt(h.Position, Vector3.new(tr.Position.X, h.Position.Y, tr.Position.Z)) end)
							task.wait()
						end
					end)
					task.wait(0.16)
					pcall(function()   -- and HIT
						local cam = workspace.CurrentCamera; local v = (cam and cam.ViewportSize) or Vector2.new(800, 600)
						VIMs:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, true, game, 0); task.wait(0.04); VIMs:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, false, game, 0)
					end)
					vxLog("Block punish -> dash + M1")
				end
			end
		end
	end)
	-- SUPERSEDED: VXBF2's doSideDash is the live Side Dash Assist (bound to Q at ~3192). This older module is
	-- also bound to Q; leaving it settable risked two handlers firing on one press ("dashes weird"). Hard-off.
	SideDashApi = { set = function() on = false end }
end

-- ============================================================
-- MODULE: AUTO EVASIVE  (i-frame dash - Dash(dir, true) - when a nearby enemy swings; direction is configurable)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local on, last, idx, dmode = false, 0, 0, "Cycle"  -- dmode: Back / Right / Left / Toward Target / Cycle
	local CYCLE = { "Back", "Left", "Right" }
	local function myHRP() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local ATTACK = { [Enum.AnimationPriority.Action] = true, [Enum.AnimationPriority.Action2] = true, [Enum.AnimationPriority.Action3] = true, [Enum.AnimationPriority.Action4] = true }
	local function enemyAttacking()  -- dodge when a nearby enemy uses ANY attack/skill: Action-priority anim OR any captured attack/skill/M1 id (wider range so ranged SKILLS trigger it too)
		local hrp = myHRP(); local chars = workspace:FindFirstChild("Characters"); if not (hrp and chars) then return false end
		local dict = _G.VX_ANIMDICT       -- block engine's attack-anim map
		local adict = _G.VX_ADAPT_IDS     -- the FULL captured attack/skill/domain id list (catches SKILLS, not just M1s)
		local mdict = _G.VX_M1_IDS
		for _, m in ipairs(chars:GetChildren()) do
			if m.Name ~= LP.Name then
				local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid")
				if r and h and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= 45 then   -- wider: a skill thrown from range still triggers a dodge
					local anim = h:FindFirstChildOfClass("Animator")
					if anim then for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
						if tr.IsPlaying then
							if ATTACK[tr.Priority] then return true end
							if tr.Animation then local id = tostring(tr.Animation.AnimationId):match("%d+"); if id and ((dict and dict[id]) or (adict and adict[id]) or (mdict and mdict[id])) then return true end end
						end
					end end
				end
			end
		end
		return false
	end
	local function pickDir()
		if dmode == "Toward Target" then return "Front" end  -- dash forward (toward them, since you face the enemy)
		if dmode == "Cycle" then idx = (idx % #CYCLE) + 1; return CYCLE[idx] end
		return dmode  -- Back / Right / Left
	end
	local function selfHit()  -- YOU got hit / are inside a move (stun/knockback marker on YOUR body) -> dash out NOW
		local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		if not c then return false end
		local info = c:FindFirstChild("Info")
		if info then for _, nm in ipairs({ "Stun", "Stunned", "HitStun", "Hitstun", "eStun", "BlockStun", "Knockback" }) do
			local v = info:FindFirstChild(nm); if v and v.Value and v.Value ~= false and v.Value ~= 0 then return true end
		end end
		local h = c:FindFirstChildOfClass("Humanoid")
		if h and (h.PlatformStand or h:GetAttribute("Stun") == true or h:GetAttribute("HitStun") == true) then return true end
		return false
	end
	local function evade()
		last = tick()
		fireKnit("MovementService", "Dash", pickDir(), true)  -- Dash(dir, true) = the i-frame evasive dash (back/left/right), exactly your capture
	end
	-- HARD trigger: your HEALTH DROPPED = you were hit by a move -> evasive dash IMMEDIATELY (event, not a poll)
	local hookedHum = nil
	local function hookHealth()
		local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not h or hookedHum == h then return end
		hookedHum = h
		local lastHp = h.Health
		h.HealthChanged:Connect(function(hp)
			local dropped = hp < lastHp - 0.5
			lastHp = hp
			if on and dropped and tick() - last > 0.22 then evade() end   -- damage taken -> dash out NOW
		end)
	end
	task.spawn(function()
		while true do
			if on then
				hookHealth()
				if tick() - last > 0.22 and (enemyAttacking() or selfHit()) then evade() end   -- incoming swing / skill OR you're stunned
			end
			task.wait(0.04)
		end
	end)
	_G.VX_EVADE = function() if on and tick() - last > 0.22 then evade() end end   -- fired by the anim-threat pipeline (same event Auto Adapt provably rides)
	EvasiveApi = { set = function(v) on = v == true end, setDir = function(m) dmode = m or "Cycle" end }
end

-- ============================================================
-- MODULE: GOJO TP (R) + REVERSAL RED (3 -> R)
-- ============================================================
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local VIM = game:GetService("VirtualInputManager")
	local RS = game:GetService("ReplicatedStorage")
	local LP = Players.LocalPlayer
	local gojoOn, redOn, lastGojo = false, false, 0
	local function myHRP() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function nearestEnemyChar(raw)   -- raw = ignore the lock (used by the 'is anyone near me' gate)
		local hrp = myHRP(); if not hrp then return nil end
		if not raw then
			local _g=_G.VX_LOCK; local _lt=(_g and _g.manualActive and _g.manualActive() and _g.get) and _g.get() or nil   -- LOCK TARGET wins over any range scan
			if _lt and _lt.Parent and _lt:FindFirstChild("HumanoidRootPart") then local _lh=_lt:FindFirstChildOfClass("Humanoid"); if not _lh or _lh.Health > 0 then return _lt end end
		end
		local best, bd
		-- Health check is now `not h or h.Health > 0`: training dummies often have NO Humanoid at all, and the
		-- old `h and h.Health > 0` rejected them outright.
		local function chk(m)
			if m and m.Name ~= LP.Name and m ~= LP.Character then
				local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid")
				if r and (not h or h.Health > 0) then
					local d = (r.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = m, d end
				end
			end
		end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
		-- DUMMY FOLDERS: Auto Air's 60-stud presence gate rides this. Training dummies usually live outside
		-- workspace.Characters, so testing on one left the gate permanently false = "Auto Air does nothing".
		for _, folderName in ipairs({ "Dummies", "Training", "NPCs", "Dummy" }) do
			local f = workspace:FindFirstChild(folderName)
			if f then for _, m in ipairs(f:GetChildren()) do chk(m) end end
		end
		return best
	end
	local function gojoRE()  -- GojoService.RE.RightActivated -> fires with a target Character = TP behind them
		local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild("GojoService"); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild("RightActivated")
	end
	local function asPlayerCharacter(mdl)  -- the remote wants the PLAYER's .Character (the working capture used Players[name].Character), not the workspace.Characters model
		if not mdl then return nil end
		local plr = Players:GetPlayerFromCharacter(mdl) or Players:FindFirstChild(mdl.Name)
		return (plr and plr.Character) or mdl
	end
	local function faceTargetNow(tgtModel)  -- AIM at the user before/while the ability fires (Gojo R requires aiming at them)
		local hrp = myHRP(); local tr = tgtModel and (tgtModel:FindFirstChild("HumanoidRootPart") or tgtModel:FindFirstChildWhichIsA("BasePart"))
		if hrp and tr then
			pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tr.Position.X, hrp.Position.Y, tr.Position.Z)) end)
			pcall(function() local cam = workspace.CurrentCamera; cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tr.Position) end)
		end
	end
	local function currentTarget()
		local g = _G.VX_LOCK; local lt = (g and g.get) and g.get() or nil
		return (lt and lt.Parent) and lt or nearestEnemyChar()
	end
	-- helpers for the Auto Air / mid-M1 sequences
	local autoAirOn = false
	local lastVesselAir = 0
	-- Auto Air's OWN injected-key stamps. Kept separate from the shared _G.VX_INJ_KEYS on purpose: that global is
	-- written by several modules (Auto Earthquake re-stamps key 3 every 40ms while charging, Yuta stamps key 2),
	-- and checking it made Auto Air suppress ITSELF whenever another feature was running — the real reason Rough
	-- Energy / Crushing Jaws never fired. We must only ignore keys WE pressed, not keys another module claimed.
	local airSelfInj = {}
	local function dbgAir(msg) if _G.VX_BF_DEBUG then print("[DreamHub AutoAir] " .. tostring(msg)) end end
	-- The keys Auto Air actually reacts to. Used by the always-on refusal report so pressing W or a hotkey it
	-- has no opinion about never prints anything.
	local AIR_KEYS = {
		[Enum.KeyCode.One] = true, [Enum.KeyCode.Two] = true, [Enum.KeyCode.Three] = true,
		[Enum.KeyCode.Four] = true, [Enum.KeyCode.R] = true, [Enum.KeyCode.Space] = true,
	}
	-- PER-CHARACTER Auto Air switches ("make the user pick which auto air it wants on"). All default ON; the
	-- Combat page exposes one toggle each. A sequence only runs if BOTH the master Auto Air toggle and its own
	-- switch are on AND you actually own the move.
	local airOpt = { Vessel = true, Twofold = true, Hakari = true, Megumi = true, Choso = true, LapseBlue = true, LapseRed = true, Locust = true }
	AutoAirOptSet = function(k, v) if k ~= nil then airOpt[k] = v == true end end
	local lastM1Tgt = nil                 -- the enemy your last LANDED M1 hit (all sequences target THEM, like the Dummy in your captures)
	local function knitRE(svcName, reName)
		local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
		local s = k and k:FindFirstChild(svcName); local re = s and s:FindFirstChild("RE"); return re and re:FindFirstChild(reName)
	end
	local function myMoveset(name)
		local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local mv = c and c:FindFirstChild("Moveset"); return mv and mv:FindFirstChild(name)
	end
	local function airborneMe()
		local hrp = myHRP(); if not hrp then return false end
		local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		return (h and h.FloorMaterial == Enum.Material.Air) or false
	end
	local function landedM1Target()  -- an enemy in melee range IN FRONT = your M1 landed on them
		local mh = myHRP(); if not mh then return nil end
		local mdl = nearestEnemyChar(); if not mdl then return nil end
		local tr = mdl:FindFirstChild("HumanoidRootPart"); if not tr then return nil end
		local to = tr.Position - mh.Position
		if to.Magnitude <= 9 and mh.CFrame.LookVector:Dot(to.Unit) > 0.35 then return mdl end
		return nil
	end
	local lastThree = 0   -- you pressed 3 (Lapse Blue etc): R now means REVERSAL RED, so the mid-M1 auto-R must stand down
	local function __airHandler(input, gpe)
		-- DON'T bail on gpe: pressing 1/2/3/R to use a move sets gpe=true (the game bound the key), and those
		-- are EXACTLY the presses Auto Air chains off. Only skip while you're TYPING in a textbox.
		if UIS:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.Three then lastThree = tick() end
		-- GOJO TP BACK: configurable. Mode "Q Dash" = TP behind the moment you press Q. Mode "After M1s" =
		-- TP behind after your chosen number of Gojo M1s land (counted by anim below). Both fire GojoService TP.
		local function pressR()
			_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.R] = tick() + 0.3
			pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game) end)
		end
		local function doGojoTpBack()
			if tick() - lastGojo < 0.9 then return end
			local mdl = lastM1Tgt or landedM1Target() or nearestEnemyChar()
			if not mdl then return end
			lastM1Tgt = mdl; lastGojo = tick()
			task.spawn(function()
				-- LOCK ON THE BACK for ~1s: keep facing + snapping just behind them, so the TP lands on their back.
				local hold = tonumber(_G.VX_GOJO_LOCK) or 1
				local t0 = tick()
				while tick() - t0 < hold and mdl and mdl.Parent do
					faceTargetNow(mdl)
					task.wait(0.05)
				end
				-- then TELEPORT: press R, R (double) + the GojoService remote = TP behind them
				faceTargetNow(mdl)
				pressR(); task.wait(0.06); pressR()
				local re = gojoRE(); if re then pcall(function() re:FireServer(asPlayerCharacter(mdl)) end) end
			end)
		end
		_G.VX_GOJO_TPBACK = doGojoTpBack   -- the anim counter (below) calls this when the M1 count is reached
		if input.UserInputType == Enum.UserInputType.MouseButton1 then local mdl = landedM1Target(); if mdl then lastM1Tgt = mdl end end
		-- Q DASH mode: press Q -> TP behind them right away
		if input.KeyCode == Enum.KeyCode.Q and gojoOn and (tostring(_G.VX_GOJO_MODE or "Q Dash") == "Q Dash") then
			doGojoTpBack()
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then local mdl = landedM1Target(); if mdl then lastM1Tgt = mdl end end   -- remember who you're hitting (Auto Air targets THEM)
		if input.KeyCode == Enum.KeyCode.Three and redOn and tick() >= (_G.VX_INJECT_UNTIL or 0) then
			task.delay(0.12, function() pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game); task.wait(0.12); VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game) end) end)
		end
		-- ══ AUTO AIR sequences ══
		-- KEYS, not remotes: the remotes were server-rejected out of context ('nothing works at all').
		-- Pressing the real key is identical to you pressing it, so the game itself aims/validates.
		local function myCharName()
			local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
			return c and detectCharName(c) or nil
		end
		local function tapKey(kc, hold)
			_G.VX_INJECT_UNTIL = tick() + 0.35
			_G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[kc] = tick() + 0.5   -- tell OTHER modules this key was synthetic
			airSelfInj[kc] = tick() + 0.5                                               -- and remember it was OURS
			pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(hold or 0.09); VIM:SendKeyEvent(false, kc, false, game) end)
		end
		-- EVERY M1, which was eating your real 1/2/3/R presses = 'Auto Air doesn't work'). Now a key is only
		-- ═══ AUTO AIR ROOT CAUSE #2 ═══ These two guards used to `return` out of the WHOLE shared InputBegan
		-- handler. Two consequences, both of which read as "Auto Air doesn't work":
		--   (a) Auto Earthquake re-stamps VX_INJ_KEYS[Three] every 40ms while it is on, so the key-3 branches
		--       (Rough Energy / Crushing Jaws) could NEVER run. The Yuta module does the same to key 2 (Nue).
		--   (b) With no enemy in range the handler returned early, silently disabling unrelated features below.
		-- They are now BOOLEANS that gate only the Auto Air branches, never the rest of the handler.
		-- Only ignore a key WE just injected (self-retrigger guard). Reading the SHARED _G.VX_INJ_KEYS here was the
		-- bug: Auto Earthquake re-stamps key 3 every 40ms while charging and Yuta stamps key 2, so Auto Air was
		-- being suppressed by other features rather than by its own presses.
		local injBlocked = false
		do local k = input.KeyCode; local t = k and airSelfInj[k]; if t and tick() < t then injBlocked = true end end
		-- ENEMY-PRESENCE GATE (root cause of "Auto Air activates randomly"): every sequence below fires off a real
		-- key/click (jump, 1/2/3, M1). With no enemy engaged, jumping to move or pressing 1 in the open used to launch
		-- the whole air combo. Require an enemy within engagement range (40 studs) before ANY sequence runs. This is a
		-- correctness condition, not a timing tweak — it does not change WHEN a valid air combo fires, only that one is
		-- actually intended. (The lines ABOVE this guard — Gojo-TP / lastM1Tgt memory — are separate and unaffected.)
		-- airOK gates the Auto Air branches ONLY (see the note above) — it no longer returns out of the handler.
		local airOK = false
		local _airWhy = "off"
		-- The test button sets this so the enemy-presence gate cannot hide whether the branches themselves work.
		local _airForced = tick() < (tonumber(_G.VX_AIR_FORCE) or 0)
		if autoAirOn then
			if injBlocked then _airWhy = "ignored (we pressed this key ourselves)"
			elseif not _G.VX_AIR_NEEDENEMY then
				-- Gate disabled (the default). Your key press is the intent; we do not second-guess it.
				airOK = true; _airWhy = "ok (enemy gate off)"
			else
				local _am = myHRP(); local _ae = nearestEnemyChar(true); local _ar = _ae and _ae:FindFirstChild("HumanoidRootPart")   -- raw: a far-away LOCK must not disable Auto Air
				if not _am then _airWhy = "no HumanoidRootPart on you"
				elseif not _ar then _airWhy = "NO ENEMY FOUND (need a player/dummy in workspace.Characters)"
				else
					-- ═══ THE GATE THAT KEPT AUTO AIR SILENT ═══ The test button forces this open and the
					-- sequences fire; the normal path did not, so the gate WAS the blocker. It exists to stop a
					-- stray key in the open launching an air combo, which is worth keeping - but 60 studs and a
					-- hard requirement that an enemy be resolvable was far too strict, and nearestEnemyChar can
					-- miss dummies that live outside the folders it knows. Range raised, and the whole gate is
					-- now optional (Combat page toggle, default OFF = no gate) so it can never be the reason
					-- nothing happens.
					local lim = tonumber(_G.VX_AIR_RANGE) or 150
					local d = (_ar.Position - _am.Position).Magnitude
					if d <= lim then airOK = true; _airWhy = "ok (enemy " .. math.floor(d) .. " studs)"
					else _airWhy = "enemy too far: " .. math.floor(d) .. " studs (limit " .. lim .. ")" end
				end
			end
			if _airForced and not airOK then airOK = true; _airWhy = "FORCED by the test button (" .. _airWhy .. ")" end
		end
		-- DIAGNOSTIC: with _G.VX_BF_DEBUG = true every key press prints whether Auto Air was allowed to run and,
		-- if not, exactly why. This is the fastest way to find out why a sequence stays silent.
		if _G.VX_BF_DEBUG and autoAirOn and input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
			dbgAir("key=" .. tostring(input.KeyCode.Name) .. "  airOK=" .. tostring(airOK) .. "  (" .. _airWhy .. ")")
		end
		-- ═══ ALWAYS-ON BLOCK REPORT ═══ Auto Air has been "fixed" several times against a guessed gate and kept
		-- staying silent, so when it is ON and you press one of its keys and it DECLINES, it now says why in F9
		-- without any debug flag. Throttled to one line every 2s per reason, so it is a hint and not a spam.
		-- (It prints only on refusal - a working sequence stays quiet.)
		if autoAirOn and not airOK and input.KeyCode and AIR_KEYS[input.KeyCode] then
			if tick() - (_G.VX_AIRWHY_T or 0) > 2 or _G.VX_AIRWHY_LAST ~= _airWhy then
				_G.VX_AIRWHY_T = tick(); _G.VX_AIRWHY_LAST = _airWhy
				print("[DreamHub AutoAir] " .. tostring(input.KeyCode.Name) .. " did nothing: " .. _airWhy)
			end
		end
		-- BULLETPROOF character check: detected name, model name, DISPLAY name, or any Moveset entry containing the word.
		local function charIs(...)
			local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
			if not c then return false end
			local n = c:FindFirstChildOfClass("Humanoid")
			local hay = string.lower((c.Name or "") .. " " .. (n and n.DisplayName or "") .. " " .. (detectCharName(c) or ""))
			local mv = c:FindFirstChild("Moveset"); if mv then for _, m in ipairs(mv:GetChildren()) do hay = hay .. " " .. string.lower(m.Name) end end
			-- NORMALISED compare: the game writes names unspaced ("BlackFlash"), so a raw search for "black flash"
			-- could never match. Strip spaces/underscores/hyphens from BOTH sides, same as normMove does for moves.
			local nhay = (string.gsub(hay, "[%s_%-]", ""))
			for _, w in ipairs({ ... }) do
				local nw = (string.gsub(string.lower(tostring(w)), "[%s_%-]", ""))
				if nw ~= "" and string.find(nhay, nw, 1, true) then return true end
			end
			return false
		end
		-- MOVE-BASED detection (user's exact captures): check YOUR Moveset for the move name, not the character name.
		-- ═══ THE AUTO AIR BUG ═══ The game stores move names UNSPACED ("RoughEnergy", "LapseBlue",
		-- "TwofoldKick", "CrushingJaws"), but every call below asks for the SPACED display name
		-- ("Rough Energy"). A plain substring search for "rough energy" inside "roughenergy" never matches, so
		-- ONLY the single-word "Nue" branches could ever fire — that is why Auto Air did nothing for the
		-- Vessel / Gambler / Locust. We now NORMALISE both sides (strip spaces, underscores, hyphens, case)
		-- before comparing, and we look in EVERY place a moveset is known to live:
		--   char.Moveset/*            (folder of move objects  - original)
		--   char.Info.Moveset         (StringValue             - newer layout)
		--   char.Info.Character/Moveset attributes
		local function normMove(s) return (string.gsub(string.lower(tostring(s or "")), "[%s_%-]", "")) end
		local function hasMove(name)
			local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
			if not c then return false end
			local want = normMove(name); if want == "" then return false end
			-- ONE-SHOT DEBUG DUMP: with _G.VX_BF_DEBUG = true, print your character's real Moveset child names to
			-- F9 the first time this runs. That tells us definitively whether the game spells moves "RoughEnergy"
			-- or "Rough Energy" — send me that line and any future move can be matched exactly.
			if _G.VX_BF_DEBUG and not _G.VX_MOVEDUMPED then
				_G.VX_MOVEDUMPED = true
				pcall(function()
					local mv0 = c:FindFirstChild("Moveset")
					local names = {}
					if mv0 then for _, mm in ipairs(mv0:GetChildren()) do names[#names + 1] = mm.Name end end
					print("[DreamHub AutoAir] character=" .. tostring(c.Name) .. "  Moveset children = { " .. table.concat(names, ", ") .. " }")
				end)
			end
			-- 1) the Moveset FOLDER (each child is a move)
			local mv = c:FindFirstChild("Moveset")
			if mv then for _, mm in ipairs(mv:GetChildren()) do if string.find(normMove(mm.Name), want, 1, true) then return true end end end
			-- FALLBACKS BELOW ARE DELIBERATELY NARROW. They only run when the Moveset FOLDER did not answer, and
			-- only for needles of 5+ chars. A short needle like "nue" is a substring of ordinary words such as
			-- "Continue", so searching attributes / animation names with it would auto-press keys for a character
			-- that has no Nue. Long needles ("roughenergy", "crushingjaws", "twofoldkick", "lapseblue") are safe.
			if #want < 5 then return false end
			-- 2) a Moveset StringValue (folder absent / renamed after a game update)
			local hay = ""
			pcall(function()
				local info = c:FindFirstChild("Info")
				if info then
					local msv = info:FindFirstChild("Moveset")
					if msv and msv:IsA("StringValue") then hay = hay .. " " .. msv.Value end
					local cv = info:FindFirstChild("Character")
					if cv and cv:IsA("StringValue") then hay = hay .. " " .. cv.Value end
				end
				if mv and mv:IsA("StringValue") then hay = hay .. " " .. mv.Value end
				for _, an in ipairs({ "Moveset", "Character", "Class" }) do
					local av = c:GetAttribute(an); if type(av) == "string" then hay = hay .. " " .. av end
				end
			end)
			if hay ~= "" and string.find(normMove(hay), want, 1, true) then return true end
			-- 3) last resort: the equipped tool / animation names sometimes carry the move name
			local okd, res = pcall(function()
				local h = c:FindFirstChildOfClass("Humanoid"); local an = h and h:FindFirstChildOfClass("Animator")
				if not an then return false end
				for _, tr in ipairs(an:GetPlayingAnimationTracks()) do
					if tr.Animation and string.find(normMove(tr.Animation.Name), want, 1, true) then return true end
				end
				return false
			end)
			if okd and res then return true end
			return false
		end
		local function holdJump() _G.VX_INJECT_UNTIL = tick() + 0.35; _G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Space] = tick() + 0.5; airSelfInj[Enum.KeyCode.Space] = tick() + 0.5; pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.08); VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
		local kc = input.KeyCode

		-- ═══════════════════ AUTO AIR — built from the user's exact remote captures ═══════════════════
		-- Every sequence below fires the REAL Knit service RemoteEvent the user captured, with the real Moveset
		-- object as the argument, exactly as the capture showed. Key presses are kept only where the capture
		-- itself was a key (jump / R / 1). Each character has its own toggle so you pick what runs.
		-- Cache resolved moves per (character, name). The descendant scan below is only reached when the folder
		-- lookups fail, and that is a PERSISTENT state - without a cache it would re-scan the whole rig on every
		-- single press of that key for the rest of the session.
		local function moveObj(nm)
			local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
			local mv = c and c:FindFirstChild("Moveset")
			-- ONE-SHOT DEBUG DUMP (moved here from hasMove, which is no longer on the hot path): with
			-- _G.VX_BF_DEBUG = true this prints your character's REAL Moveset child names to F9 the first time
			-- Auto Air looks one up. If Auto Air ever goes quiet, that line tells us exactly why.
			if _G.VX_BF_DEBUG and not _G.VX_MOVEDUMPED then
				_G.VX_MOVEDUMPED = true
				pcall(function()
					local names = {}
					if mv and mv:IsA("Folder") or (mv and mv:IsA("Model")) then
						for _, mm in ipairs(mv:GetChildren()) do names[#names + 1] = mm.Name end
					end
					print("[DreamHub AutoAir] char=" .. tostring(c and c.Name) ..
						"  Moveset=" .. tostring(mv and mv.ClassName or "MISSING") ..
						"  children = { " .. table.concat(names, ", ") .. " }")
				end)
			end
			if not mv then dbgAir("no Moveset folder - falling back to a descendant scan") end
			local want = normMove(nm)                                   -- spacing-proof ("RoughEnergy" == "Rough Energy")
			_G.VX_MOVECACHE = _G.VX_MOVECACHE or {}
			local ck = tostring(c) .. "|" .. want
			local hit = _G.VX_MOVECACHE[ck]
			if hit and hit.Parent then return hit end
			if mv then
				local direct = mv:FindFirstChild(nm); if direct then _G.VX_MOVECACHE[ck]=direct; return direct end
				for _, mm in ipairs(mv:GetChildren()) do if normMove(mm.Name) == want then _G.VX_MOVECACHE[ck]=mm; return mm end end
				-- SUBSTRING fallback: covers suffixed entries like "Lapse Blue MAX"
				for _, mm in ipairs(mv:GetChildren()) do if string.find(normMove(mm.Name), want, 1, true) then _G.VX_MOVECACHE[ck]=mm; return mm end end
			end
			-- LAST RESORT: a game update can relocate/rename the Moveset container. Scan all descendants for an
			-- Instance whose normalised name matches EXACTLY (strict equality, never substring - a loose match
			-- here could hand FireServer an unrelated Sound/Animation and get the call rejected).
			-- Only container-ish classes are plausible Moveset entries. Accepting an Animation/Sound here would
			-- hand FireServer a junk instance (silently rejected) AND mask the key fallback below it.
			for _, d in ipairs(c:GetDescendants()) do
				if normMove(d.Name) == want then
					local cn = d.ClassName
					if cn == "Folder" or cn == "Model" or cn == "Configuration" or cn == "ModuleScript"
						or cn == "ObjectValue" or cn == "StringValue" or cn == "Tool" or cn == "Part" then
						_G.VX_MOVECACHE[ck]=d; return d
					end
				end
			end
			return nil
		end
		local function svcRE(svc, re)
			local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services")
			local s = k and k:FindFirstChild(svc); local r = s and s:FindFirstChild("RE")
			return r and r:FindFirstChild(re)
		end
		local function fireSvc(svc, re, ...)
			local r = svcRE(svc, re)
			if not r then
				-- ═══ SAY IT OUT LOUD ═══ A missing remote was only reported behind a debug flag, so every
				-- wrong service name in this module failed completely silently - which is what "auto air does
				-- nothing" looks like from the outside. Several of these names are guesses at MOVE-named
				-- services (RoughEnergyService, CrushJawService...) while the capture only ever proved the
				-- CHARACTER-named pattern (<Char>Service.RE.Activated). Report it unconditionally, throttled,
				-- so one run in-game names the ones that are wrong instead of another round of guessing.
				if tick() - (_G.VX_AIRMISS_T or 0) > 2 then
					_G.VX_AIRMISS_T = tick()
					print("[DreamHub AutoAir] remote MISSING: " .. svc .. ".RE." .. re .. "  (send me this line)")
				end
				return false
			end
			local a = table.pack(...)
			local ok = pcall(function() r:FireServer(table.unpack(a, 1, a.n)) end)
			dbgAir((ok and "fired " or "FAILED ") .. svc .. "." .. re)
			return ok
		end
		-- Fire the remote if it exists; otherwise press the key the game itself binds to that move. A wrong
		-- service name then degrades to "the key press still happens" instead of "nothing happens at all".
		local function fireOrKey(svc, re, key, ...)
			if fireSvc(svc, re, ...) then return true end
			if key then tapKey(key) end
			return false
		end
		local function airTarget()   -- the capture used workspace.Characters.Dummy; live play wants the real enemy
			local e = nearestEnemyChar(); if e then return e end
			local chs = workspace:FindFirstChild("Characters"); return chs and chs:FindFirstChild("Dummy")
		end

		-- PRINCIPLE: your own key press already casts the move. Each branch adds ONLY the follow-up the capture
		-- describes — it never re-sends the same ability the key just fired, and it never both presses the key
		-- AND fires the remote that key triggers (that double-cast burns a second cooldown or cancels the first).

		-- Every branch below stamps _G.VX_BUSY, so comparing it before/after tells us whether ANY sequence
		-- matched. That is how the report at the bottom can say "the range gate passed but no branch owns your
		-- character + that key" without threading a flag through twenty branches.
		local _airBusyBefore = _G.VX_BUSY or 0

		-- ── VESSEL (Itadori) — key 1 -> Cursed Strikes (air variant: the captured `true` flag) ──
		if airOK and airOpt.Vessel and kc == Enum.KeyCode.One and (hasMove("Cursed Strikes") or charIs("vessel","itadori","sukuna","divergent")) then
			_G.VX_BUSY = tick() + 1.2; dbgAir("Vessel 1 -> Cursed Strikes")
			task.delay(0.05, function()
				local mv = moveObj("Cursed Strikes"); if autoAirOn and mv then fireSvc("CursedStrikesService", "Activated", mv, true) end   -- no key fallback: it would just re-press the key you already hit
			end)
		end

		-- ── HAKARI (Restless Gambler) — key 3 -> jump + Rough Energy (air variant) ──
		if airOK and airOpt.Hakari and kc == Enum.KeyCode.Three and (hasMove("Rough Energy") or charIs("hakari","gambler")) then
			_G.VX_BUSY = tick() + 1.4; dbgAir("Hakari 3 -> jump + Rough Energy")
			task.spawn(function() holdJump() end)
			task.delay(0.10, function()
				local mv = moveObj("Rough Energy"); if autoAirOn then if mv then fireSvc("RoughEnergyService", "Activated", mv, true) else tapKey(Enum.KeyCode.Three) end end
			end)

		-- ── LOCUST — key 3 -> Crushing Jaws. Your key 3 already casts it, so we add NOTHING here; the single
		--    R press happens in the anim hook when the fly-up plays. (No R spam, per request.)
		elseif airOK and airOpt.Locust and kc == Enum.KeyCode.Three and (hasMove("Crushing Jaws") or charIs("locust","bug")) then
			_G.VX_BUSY = tick() + 1.6; dbgAir("Locust 3 -> Crushing Jaws (R waits for the fly-up anim)")
		end

		-- ── MEGUMI — key 2 (Nue) -> add the R effect. We fire RightActivated directly INSTEAD of tapping R:
		--    tapping R would make the game fire the same remote, double-casting it. ──
		if airOK and airOpt.Megumi and kc == Enum.KeyCode.Two and (hasMove("Nue") or charIs("megumi","shadows","fushiguro")) then
			_G.VX_BUSY = tick() + 1.4; dbgAir("Megumi 2 -> R")
			task.delay(0.03, function()
				if not autoAirOn then return end
				if svcRE("MegumiService", "RightActivated") then fireSvc("MegumiService", "RightActivated")
				else tapKey(Enum.KeyCode.R) end          -- remote missing -> just press the key
			end)

		-- ── CHOSO (Blood Manip) — key 2 -> Flowing Red Scale, must JUMP ──
		elseif airOK and airOpt.Choso and kc == Enum.KeyCode.Two and (hasMove("Flowing Red Scale") or charIs("choso","blood")) then
			_G.VX_BUSY = tick() + 1.4; dbgAir("Choso 2 -> jump + Flowing Red Scale")
			task.spawn(function() holdJump() end)
			task.delay(0.08, function()
				local mv = moveObj("Flowing Red Scale"); if autoAirOn then if mv then fireSvc("RedScaleService", "Activated", mv, true) else tapKey(Enum.KeyCode.Two) end end
			end)
		end

		-- ── MEGUMI — key R -> Rabbit Escape. Firing the remote IS the "press 1" the capture shows, so we do not
		--    also tap 1 (that would cast Rabbit Escape twice). ──
		if airOK and airOpt.Megumi and kc == Enum.KeyCode.R and (hasMove("Rabbit Escape") or charIs("megumi","shadows","fushiguro")) then
			_G.VX_BUSY = tick() + 1.4; dbgAir("Megumi R -> Rabbit Escape / 1")
			task.delay(0.03, function()
				if not autoAirOn then return end
				local mv = moveObj("Rabbit Escape")
				if mv and svcRE("RabbitEscapeService", "Activated") then fireSvc("RabbitEscapeService", "Activated", mv, airTarget())
				else tapKey(Enum.KeyCode.One) end        -- no Moveset/remote -> just press 1
			end)
		end

		-- ── GOJO — key 1 (Lapse Blue) -> press R during it ──
		if airOK and airOpt.LapseBlue and kc == Enum.KeyCode.One and (hasMove("Lapse Blue") or charIs("gojo","limitless")) then
			_G.VX_BUSY = tick() + 1.6; dbgAir("Gojo 1 -> Lapse Blue -> R")
			task.delay(0.22, function() if autoAirOn then tapKey(Enum.KeyCode.R) end end)   -- anim 99920923658527
		end

		-- ── GOJO — Lapse Blue -> Reversal Red on the same beat. Fires the two captured remotes directly (no R tap
		--    here: GojoService.RightActivated IS what R does, and tapping it too would double-cast). ──
		if airOK and airOpt.LapseRed and kc == Enum.KeyCode.One and (hasMove("Lapse Blue") or charIs("gojo","limitless")) then
			_G.VX_BUSY = tick() + 1.6; dbgAir("Gojo 1 -> + Reversal Red")
			task.delay(0.24, function()
				if not autoAirOn then return end
				local mvr = moveObj("Reversal Red"); if mvr then fireSvc("ReversalRedService", "Activated", mvr) end
				fireSvc("GojoService", "RightActivated", asPlayerCharacter(airTarget()))   -- this remote wants the PLAYER's .Character
			end)
		end

		-- ── GOJO Twofold Kick — key 4 casts it; the R after the SECOND kick is fired by the anim hook. ──
		-- ═══ VESSEL (Itadori / Sukuna) — you JUMP -> auto-press 1 to carry them up ═══
		-- Recovered from commit b0034dc; kept CHARACTER-based because the launcher is the jump itself, not a
		-- named move, so hasMove()/moveObj() cannot express it.
		if airOK and airOpt.Vessel and kc == Enum.KeyCode.Space and charIs("vessel", "itadori", "sukuna", "black flash", "divergent") then
			if tick() - (lastVesselAir or 0) > 0.9 then
				lastVesselAir = tick(); _G.VX_BUSY = tick() + 1.2; dbgAir("Vessel: Jump -> 1")
				task.delay(0.12, function() if autoAirOn then tapKey(Enum.KeyCode.One) end end)
			end
		end
		-- ═══ SECOND HALF OF THE BLOCK REPORT ═══ The range gate passed and you pressed one of Auto Air's keys,
		-- but no branch claimed it. That means the character/move test failed, so print what your rig ACTUALLY
		-- has - that is the one piece of information needed to add or fix the branch. Throttled, once per key.
		if autoAirOn and airOK and kc and AIR_KEYS[kc] and (_G.VX_BUSY or 0) == _airBusyBefore then
			if tick() - (_G.VX_AIRNOBRANCH_T or 0) > 2 or _G.VX_AIRNOBRANCH_K ~= kc then
				_G.VX_AIRNOBRANCH_T = tick(); _G.VX_AIRNOBRANCH_K = kc
				local chs = workspace:FindFirstChild("Characters")
				local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
				local mv = c and c:FindFirstChild("Moveset")
				local names = {}
				if mv then for _, m in ipairs(mv:GetChildren()) do names[#names + 1] = m.Name end end
				print("[DreamHub AutoAir] " .. tostring(kc.Name) .. ": no sequence for this character."
					.. "  rig=" .. tostring(c and c.Name)
					.. "  detected=" .. tostring(c and detectCharName(c))
					.. "  Moveset={ " .. table.concat(names, ", ") .. " }")
			end
		end
	end
	-- Driven by BOTH the normal input event AND a raw key poll. If the game sinks an ability key, InputBegan
	-- never fires for it and every Auto Air sequence is silently dead - the poll sees the press regardless.
	-- A short per-key stamp stops the two paths from double-running the same press.
	local __airLast = {}
	local function __airOnce(kc)
		if not kc then return end
		if __airLast[kc] and tick() - __airLast[kc] < 0.05 then return end   -- ~3 frames: collapses one press seen by both paths, never a real follow-up
		__airLast[kc] = tick()
		__airHandler({ KeyCode = kc, UserInputType = Enum.UserInputType.Keyboard }, false)
	end
	UIS.InputBegan:Connect(function(input, gpe) if input and input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then __airOnce(input.KeyCode) else __airHandler(input, gpe) end end)
	if _G.VX_ON_KEY then _G.VX_ON_KEY("autoair", function(kc) __airOnce(kc) end) end
	if _G.VX_M1_SUB then _G.VX_M1_SUB("autoair_m1tgt", function() local m = landedM1Target(); if m then lastM1Tgt = m end end) end   -- real M1s only come from the poll
	-- AUTO AIR anim triggers: Twofold Kick (Gojo) kicks them UP -> click R (RightActivated at the target).
	-- Gambler: your landed M1 -> fire Rough Energy (the 'click 3 for you' launcher).
	AutoAirApi_set = function(v) autoAirOn = v == true end
	-- ═══ DIAGNOSTIC ═══ Force one Auto Air pass for a key with the enemy gate BYPASSED, and say what it saw.
	-- Auto Air has been patched against three different guessed gates and still reports as dead, so this proves
	-- which half is broken: if the branch fires here but not in a fight, the gate is the problem; if no branch
	-- claims the key even here, the character/move test is.
	AutoAirApi_test = function(keyName)
		local kc = Enum.KeyCode[keyName or "One"]
		local chs = workspace:FindFirstChild("Characters")
		local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local mv = c and c:FindFirstChild("Moveset")
		local names = {}
		if mv then for _, m in ipairs(mv:GetChildren()) do names[#names + 1] = m.Name end end
		local hrp = myHRP(); local en = nearestEnemyChar(true)
		local er = en and en:FindFirstChild("HumanoidRootPart")
		print("[AutoAir TEST] key=" .. tostring(keyName)
			.. "  autoAirOn=" .. tostring(autoAirOn)
			.. "  rig=" .. tostring(c and c.Name)
			.. "  detected=" .. tostring(c and detectCharName(c))
			.. "  Moveset={ " .. table.concat(names, ", ") .. " }")
		print("[AutoAir TEST] you=" .. tostring(hrp ~= nil)
			.. "  nearestEnemy=" .. tostring(en and en.Name or "NONE")
			.. "  dist=" .. tostring((er and hrp) and math.floor((er.Position - hrp.Position).Magnitude) or "n/a"))
		local savedOn = autoAirOn
		autoAirOn = true
		_G.VX_AIR_FORCE = tick() + 1        -- __airHandler treats this as "range gate satisfied"
		__airOnce(kc)
		task.delay(1, function() autoAirOn = savedOn; _G.VX_AIR_FORCE = 0 end)
	end
	-- ANIM-DRIVEN backup (your captured ids): keeps aiming through Gojo's R (99920923658527), and the RED
	-- charge anim (137654778575373) auto-clicks R even if the key-3 press was missed/eaten.
	local GOJO_R_ANIM, RED_ANIM = "99920923658527", "137654778575373"
	-- Auto Air anim ids (user captures): Twofold Kick, and the two Locust fly-up anims.
	local TWOFOLD_ANIM = "104749346956269"
	local LOCUST_UP = { ["134777193523837"] = true, ["112223227323175"] = true }
	local twofoldCount, lastTwofold, lastLocustR = 0, 0, 0
	-- Gojo M1 landing anims (your capture) -> count them for the "After N M1s" TP-back mode
	local GOJO_M1 = { ["127851700400958"] = true, ["72548435296350"] = true, ["84547415708554"] = true }
	local gojoM1Count, lastGojoM1 = 0, 0
	local lastRedR = 0
	local hookedA = setmetatable({}, { __mode = "k" })
	local function hookSelfAnims()
		local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character
		local h = c and c:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
		if not a or hookedA[a] then return end
		hookedA[a] = a.AnimationPlayed:Connect(function(track)
			local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+"); if not id then return end
			if id == GOJO_R_ANIM and gojoOn then                                          -- Gojo R started: keep AIMING at the target through the grab window
				task.spawn(function() local mdl = currentTarget(); for _ = 1, 8 do if not (mdl and mdl.Parent) then break end faceTargetNow(mdl); task.wait(0.04) end end)
			end
			-- AFTER-M1s mode: count YOUR Gojo M1s; at the chosen count, TP behind. Reset the count if you stop M1ing.
			if GOJO_M1[id] and gojoOn and (tostring(_G.VX_GOJO_MODE or "Q Dash") == "After M1s") then
				if tick() - lastGojoM1 > 2 then gojoM1Count = 0 end   -- new combo
				lastGojoM1 = tick(); gojoM1Count = gojoM1Count + 1
				if gojoM1Count >= (tonumber(_G.VX_GOJO_COUNT) or 2) then
					gojoM1Count = 0
					if _G.VX_GOJO_TPBACK then task.spawn(_G.VX_GOJO_TPBACK) end
				end
			end
			if id == RED_ANIM and redOn and tick() - lastRedR > 0.6 then                  -- Red charge anim: click R
				lastRedR = tick()
				task.spawn(function() pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game); task.wait(0.12); VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game) end) end)
			end
			-- ═══ AUTO AIR — ANIM-DRIVEN R PRESSES (user's captured ids) ═══
			-- TWOFOLD KICK (104749346956269): press R after the SECOND kick. The anim plays once per kick, so we
			-- count plays and act on the 2nd; the counter resets after 1.5s idle so a new cast starts clean.
			if autoAirOn and airOpt.Twofold and id == TWOFOLD_ANIM then
				if tick() - lastTwofold > 1.5 then twofoldCount = 0 end
				lastTwofold = tick(); twofoldCount = twofoldCount + 1
				if twofoldCount >= 2 then
					twofoldCount = 0
					dbgAir("Twofold: 2nd kick -> R")
					task.spawn(function()
						pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game); task.wait(0.10); VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game) end)
					end)
				end
			end
			-- LOCUST fly-up (134777193523837 / 112223227323175): press R ONCE when it lifts — no more R spam.
			if autoAirOn and airOpt.Locust and LOCUST_UP[id] and tick() - lastLocustR > 0.8 then
				lastLocustR = tick()
				dbgAir("Locust fly-up -> R")
				task.spawn(function()
					pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game); task.wait(0.10); VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game) end)
				end)
			end
		end)
	end
	task.spawn(function() while true do if gojoOn or redOn or autoAirOn then pcall(hookSelfAnims) end task.wait(0.7) end end)
	GojoTpApi = { set = function(v) gojoOn = v == true end }
	ReversalRedApi = { set = function(v) redOn = v == true end }
end

-- ============================================================
-- MODULE: DESYNC FREEZE  (experimental invis: the server keeps you at the frozen spot, YOU keep moving)
-- Anchoring your root LOCALLY stops your physics replication -> everyone sees you standing at the freeze
-- point while you actually move around (local WASD driver). Turning it off glides you back legit.
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on = false
	local ghost, ghostRoot, freezeCF = nil, nil, nil
	local function myC() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myR() local c = myC(); return c and c:FindFirstChild("HumanoidRootPart") end
	-- GHOST method: your REAL body stays put (server + everyone genuinely sees you frozen, because you
	-- send no movement at all). YOU roam as a local see-through clone with full WASD/Space/Ctrl flight.
	local function makeGhost()
		local c = myC(); if not c then return end
		local ok, cl = pcall(function() c.Archivable = true; return c:Clone() end)
		if not (ok and cl) then return end
		cl.Name = "DreamGhost"
		for _, d in ipairs(cl:GetDescendants()) do
			pcall(function()
				if d:IsA("BasePart") then d.Transparency = math.clamp(d.Transparency + 0.6, 0, 1); d.CanCollide = false; d.Anchored = (d.Name == "HumanoidRootPart")
				elseif d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
			end)
		end
		local h = cl:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end) end
		cl.Parent = workspace
		ghost = cl; ghostRoot = cl:FindFirstChild("HumanoidRootPart")
		local r = myR(); if r and ghostRoot then pcall(function() ghost:PivotTo(r.CFrame) end) end
		pcall(function() workspace.CurrentCamera.CameraSubject = h or ghostRoot end)   -- your camera follows the ghost
	end
	RunService.RenderStepped:Connect(function(dt)
		if not on then return end
		local r = myR()
		if r then
			if not freezeCF then freezeCF = r.CFrame end   -- capture the freeze point ONCE
			-- ABSOLUTE pin: the real body NEVER moves while frozen - not for attacks, not for anything.
			-- (Attacks you throw while ghosting fire from the frozen spot; the body stays exactly still.)
			pcall(function() r.Anchored = true; r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero; r.CFrame = freezeCF end)
		end
		if not (ghost and ghost.Parent and ghostRoot) then makeGhost(); if not ghostRoot then return end end
		local cam = workspace.CurrentCamera; if not cam then return end
		local fwd = cam.CFrame.LookVector; fwd = Vector3.new(fwd.X, 0, fwd.Z); if fwd.Magnitude > 0 then fwd = fwd.Unit end
		local right = cam.CFrame.RightVector; right = Vector3.new(right.X, 0, right.Z); if right.Magnitude > 0 then right = right.Unit end
		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
		if move.Magnitude > 0 then
			local dir = move.Unit
			pcall(function() ghostRoot.CFrame = CFrame.new(ghostRoot.Position + dir * (30 * dt)) * (ghostRoot.CFrame - ghostRoot.CFrame.Position) end)
		end
	end)
	DesyncFreezeApi = { set = function(v)
		if v then
			on = true
		else
			on = false
			freezeCF = nil
			if ghost then pcall(function() ghost:Destroy() end) end
			ghost, ghostRoot = nil, nil
			local c = myC(); local r = myR(); local h = c and c:FindFirstChildOfClass("Humanoid")
			if r then pcall(function() r.Anchored = false end) end
			pcall(function() workspace.CurrentCamera.CameraSubject = h or r end)   -- camera back on your real body
		end
	end }
end

-- ============================================================
-- MODULE: CONTROL DUMMY  (take the wheel: WASD walks the dummy around, Space hops it)
-- ============================================================
do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on, dummy = false, nil
	local function myHRP() local chs = workspace:FindFirstChild("Characters"); local c = (chs and chs:FindFirstChild(LP.Name)) or LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function findDummy()  -- nearest non-player model (Dummy) in workspace.Characters
		local mh = myHRP(); local chs = workspace:FindFirstChild("Characters"); if not (mh and chs) then return nil end
		local best, bd
		for _, m in ipairs(chs:GetChildren()) do
			if m:IsA("Model") and m.Name ~= LP.Name and not Players:FindFirstChild(m.Name) then
				local r = m:FindFirstChild("HumanoidRootPart")
				if r then local d = (r.Position - mh.Position).Magnitude; if not bd or d < bd then best, bd = m, r and d end end
			end
		end
		return best
	end
	local flyOn, attackOn, atkTarget = false, false, nil
	local function targetHRPOf(name)
		local p = Players:FindFirstChild(name); if p and p.Character then local r = p.Character:FindFirstChild("HumanoidRootPart"); if r then return r end end
		local chs = workspace:FindFirstChild("Characters"); local m = chs and chs:FindFirstChild(name); return m and m:FindFirstChild("HumanoidRootPart")
	end
	RunService.Heartbeat:Connect(function(dt)
		if not on then return end
		if not (dummy and dummy.Parent) then dummy = findDummy(); if not dummy then return end end
		local r = dummy:FindFirstChild("HumanoidRootPart"); if not r then return end
		pcall(function() r.Anchored = false end)   -- an ANCHORED dummy ignores everything ('nothing works') - free it first
		local cam = workspace.CurrentCamera; if not cam then return end
		local hum = dummy:FindFirstChildOfClass("Humanoid")
		-- ATTACK MODE (JoJo stand): the dummy chases the chosen player and body-slams through them
		if attackOn and atkTarget then
			local tr = targetHRPOf(atkTarget)
			if tr then
				local to = tr.Position - r.Position
				local dir = to.Magnitude > 0.1 and to.Unit or Vector3.zero
				pcall(function()
					r.CFrame = CFrame.lookAt(r.Position + dir * (30 * dt), Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z))   -- ALWAYS moves (CFrame step)...
					r.AssemblyLinearVelocity = Vector3.new(dir.X * 42, math.clamp(to.Y * 2, -18, 26), dir.Z * 42)                      -- ...and velocity so it REPLICATES when you own its physics
				end)
				if hum then pcall(function() hum:Move(dir) end) end
			end
			return
		end
		-- WASD control (camera-relative). VELOCITY-driven, not CFrame: physics replicates -> everyone SEES it walk/fly.
		local fwd = cam.CFrame.LookVector; fwd = Vector3.new(fwd.X, 0, fwd.Z); if fwd.Magnitude > 0 then fwd = fwd.Unit end
		local right = cam.CFrame.RightVector; right = Vector3.new(right.X, 0, right.Z); if right.Magnitude > 0 then right = right.Unit end
		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right end
		local vy = r.AssemblyLinearVelocity.Y
		if flyOn then
			vy = 0
			if UIS:IsKeyDown(Enum.KeyCode.Space) then vy = 26 end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vy = -26 end
		elseif UIS:IsKeyDown(Enum.KeyCode.Space) then vy = 30 end
		if move.Magnitude > 0 or flyOn then
			local dir = move.Magnitude > 0 and move.Unit or Vector3.zero
			if hum then pcall(function() hum:Move(dir) end) end   -- walk animation
			pcall(function()
				local stepV = Vector3.new(dir.X * 20 * dt, (flyOn and vy or 0) * dt, dir.Z * 20 * dt)
				if dir.Magnitude > 0 or flyOn then r.CFrame = CFrame.lookAt(r.Position + stepV, r.Position + stepV + (dir.Magnitude > 0 and dir * 8 or r.CFrame.LookVector * 8)) end   -- ALWAYS moves
				r.AssemblyLinearVelocity = Vector3.new(dir.X * 22, vy, dir.Z * 22)   -- and replicated physics when owned
			end)
		elseif UIS:IsKeyDown(Enum.KeyCode.Space) then
			pcall(function() r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 30, r.AssemblyLinearVelocity.Z) end)
		end
	end)
	ControlDummyApi = {
		set = function(v) on = v == true; if not on then dummy = nil; attackOn = false end end,
		setFly = function(v) flyOn = v == true end,
		setAttack = function(v) attackOn = v == true end,
		setTarget = function(n) atkTarget = (n and n ~= "(none)") and n or nil end,
		blackFlash = function()   -- DUMMY BLACK FLASH: slam the dummy behind the chosen player and shove through their back
			if not (dummy and dummy.Parent and atkTarget) then return end
			local r = dummy:FindFirstChild("HumanoidRootPart"); local tr = targetHRPOf(atkTarget)
			if not (r and tr) then return end
			local look = tr.CFrame.LookVector; local flat = Vector3.new(look.X, 0, look.Z)
			local dir = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
			pcall(function()
				r.CFrame = CFrame.lookAt(tr.Position - dir * 4 + Vector3.new(0, 1, 0), tr.Position)
				r.AssemblyLinearVelocity = dir * 60   -- drive THROUGH their back
			end)
		end,
	}
end

-- ============================================================
-- MODULE: REMOVE TREES  (hide the map trees so you can see the fight better)
-- ============================================================
do
	local on = false
	local hidden = setmetatable({}, { __mode = "k" })   -- part -> its original transparency (so we can restore)
	local function treesRoot()
		local map = workspace:FindFirstChild("Map"); local d = map and map:FindFirstChild("Destructible")
		if d then local t = d:FindFirstChild("Trees", true); if t then return t end end   -- workspace.Map.Destructible...Trees
		return nil
	end
	task.spawn(function()
		while true do
			if on then
				local t = treesRoot()
				if t then
					for _, p in ipairs(t:GetDescendants()) do
						-- SAVE everything we hide (parts AND decals/textures). Decals were hidden WITHOUT being saved,
						-- so turning trees back on restored trunks but left leaves/bark invisible = "trees don't come back".
						if (p:IsA("BasePart") or p:IsA("Decal") or p:IsA("Texture")) and hidden[p] == nil then
							hidden[p] = p.Transparency; pcall(function() p.Transparency = 1 end)
						end
					end
				end
			end
			task.wait(0.6)   -- re-hide trees that stream back in
		end
	end)
	RemoveTreesApi = { set = function(v)
		on = v == true
		if not on then for p, tr in pairs(hidden) do if p and p.Parent then pcall(function() p.Transparency = tr end) end hidden[p] = nil end end   -- restore
	end }
end

-- ============================================================
-- MODULE: AIM ASSIST  (face the enemy the moment you cast ANY move - detected by every captured move anim id)
-- ============================================================
do
	local Players = game:GetService("Players")
	local LP = Players.LocalPlayer
	local Camera = workspace.CurrentCamera
	local on = false
	local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
	local function myHRP() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end
	local function idOf(s) return tostring(s):match("%d+") end
	local function nearestEnemy()
		local hrp = myHRP(); if not hrp then return nil end
		local best, bd
		local function chk(m) if m and m.Name ~= LP.Name and m ~= LP.Character then local r = m:FindFirstChild("HumanoidRootPart"); local h = m:FindFirstChildOfClass("Humanoid"); if r and h and h.Health > 0 then local d = (r.Position - hrp.Position).Magnitude; if not bd or d < bd then best, bd = r, d end end end end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then chk(plr.Character) end end
		local chs = workspace:FindFirstChild("Characters"); if chs then for _, m in ipairs(chs:GetChildren()) do chk(m) end end
		return best
	end
	local function targetPart()
		local g = _G.VX_LOCK; local lt = (g and g.get) and g.get() or nil   -- prefer the LOCKED (clicked) enemy
		if lt and lt.Parent then return lt:FindFirstChild("HumanoidRootPart") or lt:FindFirstChildWhichIsA("BasePart") end
		return nearestEnemy()
	end
	-- IMPROVED AIM ASSIST: was a single hard snap on the frame the move started, which missed anyone moving and
	-- read as an obvious camera jerk. Now it TRACKS for a short window, LEADS the target using their velocity,
	-- and eases the camera instead of teleporting it - so it stays on a strafing enemy and looks hand-aimed.
	local aimGen = 0
	local function faceTarget()
		aimGen = aimGen + 1
		local myGen = aimGen
		task.spawn(function()
			local t0 = tick()
			while tick() - t0 < 0.45 and aimGen == myGen do          -- track through the cast, not one frame
				local hrp = myHRP(); local tr = targetPart()
				if not (hrp and tr and tr.Parent) then return end
				local d = (tr.Position - hrp.Position).Magnitude
				if d > 120 then return end                            -- do not swing the camera at someone across the map
				-- LEAD the target: aim where they will be, scaled by distance (travel time), so a strafing
				-- enemy is still hit instead of the shot trailing behind them.
				local tv = Vector3.zero
				pcall(function() tv = tr.AssemblyLinearVelocity end)
				local lead = math.clamp(d / 180, 0, 0.16)
				local tp = tr.Position + Vector3.new(tv.X, 0, tv.Z) * lead
				pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(tp.X, hrp.Position.Y, tp.Z)) end)   -- body faces them so the move fires at them
				pcall(function()                                       -- camera EASES onto them (no snap = looks aimed, not scripted)
					Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, tp), 0.45)
				end)
				task.wait()
			end
		end)
	end
	local function isMove(track)  -- ANY of your captured MOVE anims (all skills/ults + M1 ids)
		if not track or not track.Animation then return false end
		local id = idOf(track.Animation.AnimationId)
		return (id and ((_G.VX_ADAPT_IDS and _G.VX_ADAPT_IDS[id]) or (_G.VX_M1_IDS and _G.VX_M1_IDS[id]))) and true or false
	end
	local hooked = setmetatable({}, { __mode = "k" })
	local function hook()
		local c = myChar(); local h = c and c:FindFirstChildOfClass("Humanoid"); local a = h and h:FindFirstChildOfClass("Animator")
		if not a or hooked[a] then return end
		hooked[a] = a.AnimationPlayed:Connect(function(track) if on and isMove(track) then faceTarget() end end)
	end
	task.spawn(function() while true do if on then hook() end task.wait(0.6) end end)
	AimAssistApi = { set = function(v) on = v == true end }
end

-- ============================================================
-- MODULE: INFINITE JUMP  (press Space in mid-air to jump again)
-- ============================================================
do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local on = false
	UIS.InputBegan:Connect(function(input, gp)
		if not on or gp then return end
		if input.KeyCode == Enum.KeyCode.Space then
			local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
		end
	end)
	InfJumpApi = { set = function(v) on = v == true end }
end

-- ============================================================
-- MODULE: VISUALS  (world lighting: fullbright, no fog, FOV - held in RenderStepped so the game can't reset them)
-- ============================================================
do
	local Lighting = game:GetService("Lighting")
	local RunService = game:GetService("RunService")
	local saved = { Brightness = Lighting.Brightness, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, ClockTime = Lighting.ClockTime }
	local fullbright, fov = false, 0
	RunService.RenderStepped:Connect(function()
		if fullbright then pcall(function()
			Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(178, 178, 178); Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
		end) end
		if fov > 0 then local cam = workspace.CurrentCamera; if cam then pcall(function() cam.FieldOfView = fov end) end end
	end)
	VisualApi = {
		setFullbright = function(v)
			fullbright = v == true
			if not fullbright then pcall(function()
				Lighting.Brightness = saved.Brightness; Lighting.GlobalShadows = saved.GlobalShadows
				Lighting.Ambient = saved.Ambient; Lighting.OutdoorAmbient = saved.OutdoorAmbient; Lighting.ClockTime = saved.ClockTime
			end) end
		end,
		setFov = function(v) fov = (type(v) == "number" and v >= 40 and v <= 120 and v ~= 70) and v or 0; if fov == 0 then local cam = workspace.CurrentCamera; if cam then pcall(function() cam.FieldOfView = 70 end) end end end,
		setNoFog = function(v)
			pcall(function() if v then Lighting.FogEnd = 1e9; Lighting.FogStart = 1e9 else Lighting.FogEnd = saved.FogEnd; Lighting.FogStart = saved.FogStart end end)
			for _, e in ipairs(Lighting:GetChildren()) do if e:IsA("Atmosphere") then pcall(function() e.Density = v and 0 or 0.3 end) end end
		end,
	}
end

-- ============================================================
-- GUI  (VAULTIX v3.1 - samet / joestar._3 "esdeeeeee" library, EXACT; per-tier accent)
-- library credit: samet (joestar._3 on discord) https://discord.gg/VhvTd5HV8d
-- ============================================================
-- TIERS: free (trimmed) < premium (VIP) < plus (top). The Free loadstring sets _G.JJS_FREE=true; the Plus
-- loadstring sets _G.JJS_PLUS=true and unlocks everything premium has PLUS the plus-only extras.
-- TIER PRECEDENCE — order matters. `_G` PERSISTS between executions in most executors, so once you have run the
-- FREE loadstring in a session, `_G.JJS_FREE` stays true forever. With FREE tested first, a later PLUS run still
-- resolved to "free", which silently removed every premium-gated feature — including the Auto Air toggle, the
-- ONLY thing that can turn Auto Air on. That is why Auto Air "did not work" no matter what was fixed inside it.
-- An explicitly requested higher tier now wins, and we clear the stale lower flags so nothing can resurrect them.
-- Derived from the ONE tier resolved (and consumed) at the top of the file, so it always matches the flag you
-- set for this run. "full" (no flag at all) keeps the historical everything-unlocked behaviour.
local VX_TIER = (_G.__DreamTierKey == "full") and "premium" or (_G.__DreamTierKey or "premium")
local VX_VERSION = "5.8"
local VX_BUILD = "B58"   -- bump every push; shows in the title so you can tell a stale cached download from the real newest build

if getgenv and getgenv().Library then
    pcall(function() getgenv().Library:Unload() end)
end

local Library do
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local Vector2New = Vector2.new

    local MathClamp = math.clamp
    local MathFloor = math.floor

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLen = string.len
    local StringSub = string.sub

    local InstanceNew = Instance.new

    Library = {
        Theme =  { },

        MenuKeybind = tostring(Enum.KeyCode.RightShift),

        Flags = { },

        Tween = {
            Time = 0.4,
            Style = Enum.EasingStyle.Quint,
            Direction = Enum.EasingDirection.Out
        },

        FadeSpeed = 0.2,

        Folders = {
            Directory = "Vaultix",
            Configs = "Vaultix/Configs",
            Assets = "Vaultix/Assets",
            Fonts = "Vaultix/Fonts",
        },

        -- Ignore below
        Pages = { },
        Sections = { },

        Connections = { },
        Threads = { },

        ThemeMap = { },
        ThemeItems = { },

        OpenFrames = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,

        Font = nil
    }

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "/",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "Backquote",
        ["LeftCurly"]         = "LeftCurly",
        ["Pipe"]              = "Pipe",
        ["RightCurly"]        = "RightCurly",
        ["Tilde"]             = "Tilde",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    local Themes = {
        ["Preset"] = {
            ["Background"] = FromRGB(16, 18, 18),
            ["Inline"] = FromRGB(21, 24, 24),
            ["Element"] = FromRGB(30, 34, 34),
            ["Accent"] = FromRGB(255, 255, 255),
            ["Border"] = FromRGB(30, 34, 34),
            ["Border 2"] = FromRGB(56, 62, 62)
        }
    }

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    Library.Theme = TableClone(Themes["Preset"])

    -- RED & BLACK for every tier (same look as the Ability Arena hub) — near-black panels, red accent.
    -- The accent is changeable live from Settings > Theme (Library:ChangeTheme repaints registered items).
    Library.Theme["Background"] = FromRGB(6, 6, 8)
    Library.Theme["Inline"]     = FromRGB(11, 11, 13)
    Library.Theme["Element"]    = FromRGB(18, 18, 20)
    Library.Theme["Accent"]     = FromRGB(220, 30, 40)
    Library.Theme["Border"]     = FromRGB(26, 26, 28)
    Library.Theme["Border 2"]   = FromRGB(58, 58, 60)

    -- Folders
    pcall(function()
        for Index, Value in Library.Folders do
            if not isfolder(Value) then
                makefolder(Value)
            end
        end
    end)

    -- Tweening
    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end

        Tween.GetProperty = function(self, Item)
            Item = Item or self.Item

            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then
                return { "Transparency" }
            end
        end

        Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item

            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then
                    task.wait()
                    Item[Property] = OldTransparency
                end
            end)

            return NewTween
        end

        Tween.Get = function(self)
            if not self.Tween then
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    -- Instances
    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then
                return
            end

            if not self.Instance[Event] then
                return
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then
                return
            end

            local Gui = self.Instance

            local Dragging = false
            local DragStart
            local StartPosition

            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                self:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
            end

            local InputChanged

            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true

                    DragStart = Input.Position
                    StartPosition = Gui.Position

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end)

            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum)
            if not self.Instance then
                return
            end

            local Gui = self.Instance
            -- INVISIBLE grips in ALL 4 CORNERS (24px hit areas): drag ANY corner to scale the menu up/down.
            local Corners = {
                { Pos = UDim2New(1, -2, 1, -2), Anchor = Vector2New(1, 1), Sign = Vector2New(1, 1) },    -- bottom-right
                { Pos = UDim2New(0, 2, 1, -2),  Anchor = Vector2New(0, 1), Sign = Vector2New(-1, 1) },   -- bottom-left
                { Pos = UDim2New(1, -2, 0, 2),  Anchor = Vector2New(1, 0), Sign = Vector2New(1, -1) },   -- top-right
                { Pos = UDim2New(0, 2, 0, 2),   Anchor = Vector2New(0, 0), Sign = Vector2New(-1, -1) },  -- top-left
            }
            for _, C in ipairs(Corners) do
                local Grip = Instances:Create("ImageButton", {
                    Parent = Gui,
                    Image = "rbxassetid://",
                    AnchorPoint = C.Anchor,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 24, 0, 24),
                    Position = C.Pos,
                    Name = "\0",
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    ZIndex = 5,
                    AutoButtonColor = false,
                    Visible = true,
                })
                local Resizing = false
                local StartMouse, StartSize
                local InputChanged
                Grip:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Resizing = true
                        StartMouse = Input.Position
                        StartSize = Gui.AbsoluteSize
                        if InputChanged then return end
                        InputChanged = Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Resizing = false
                                InputChanged:Disconnect()
                                InputChanged = nil
                            end
                        end)
                    end
                end)
                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Resizing and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                        local D = Input.Position - StartMouse
                        local W = math.clamp(StartSize.X + D.X * C.Sign.X, Minimum.X, (Maximum and Maximum.X) or 9999)
                        local H = math.clamp(StartSize.Y + D.Y * C.Sign.Y, Minimum.Y, (Maximum and Maximum.Y) or 9999)
                        Gui.Size = UDim2New(0, W, 0, H)
                    end
                end)
            end
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then
                return
            end

            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then
                return
            end

            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Custom font (exact InterSemiBold; falls back to built-in Inter SemiBold if the download fails)
    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if not isfile(Data.Id) then
                writefile(Data.Id, game:HttpGet(Data.Url))
            end

            local Data = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Data.Id)
                    }
                }
            }

            writefile(`{Library.Folders.Fonts}/{Name}.font`, HttpService:JSONEncode(Data))
            return Font.new(getcustomasset(`{Library.Folders.Fonts}/{Name}.font`), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end

        local ok, f = pcall(function()
            return CustomFont:New("InterSemiBold", "Regular", "Normal", {
                Id = "Inter",
                Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/InterSemibold.ttf"
            })
        end)
        Library.Font = (ok and f) or Font.new("rbxasset://fonts/families/Inter.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = UDim2New(0, 0, 1, 0),
        BorderColor3 = FromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })

    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        Padding = UDimNew(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    Instances:Create("UIPadding", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        PaddingTop = UDimNew(0, 12),
        PaddingBottom = UDimNew(0, 12),
        PaddingRight = UDimNew(0, 12),
        PaddingLeft = UDimNew(0, 12)
    })

    Library.Unload = function(self)
        for Index, Value in self.Connections do
            Value.Connection:Disconnect()
        end

        for Index, Value in self.Threads do
            coroutine.close(Value)
        end

        if self.Holder then
            self.Holder:Clean()
        end

        Library = nil
        getgenv().Library = nil
    end

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)

        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)
        return NewThread
    end

    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))

        if not Success then
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("connection_number_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("flag_number_%s_%s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

	Library.ToRich = function(self, Text, Color)
		return `<font color="rgb({MathFloor(Color.R * 255)}, {MathFloor(Color.G * 255)}, {MathFloor(Color.B * 255)})">{Text}</font>`
	end

    Library.GetConfig = function(self)
        local Config = { }

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do
                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Decoded do
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key then
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)

        return Success, Result
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then
            delfile(Library.Folders.Configs .. "/" .. Config)
        end
    end

    Library.RefreshConfigsList = function(self, Element)
        local CurrentList = { }
        local List = { }

        local ConfigFolderName = StringGSub(Library.Folders.Configs, Library.Folders.Directory .. "/", "")

        for Index, Value in listfiles(Library.Folders.Configs) do
            local FileName = StringGSub(Value, Library.Folders.Directory .. "\\" .. ConfigFolderName .. "\\", "")
            List[Index] = FileName
        end

        local IsNew = #List ~= CurrentList

        if not IsNew then
            for Index = 1, #List do
                if List[Index] ~= CurrentList[Index] then
                    IsNew = true
                    break
                end
            end
        else
            CurrentList = List
            Element:Refresh(CurrentList)
        end
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end

    Library.IsMouseOverFrame = function(self, Frame)
        Frame = Frame.Instance

        local MousePosition = Vector2New(Mouse.X, Mouse.Y)

        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.Lerp = function(self, Start, Finish, Time)
        return Start + (Finish - Start) * Time
    end

    Library.CompareVectors = function(self, PointA, PointB)
        return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
    end

    Library.IsClipped = function(self, Object, Column)
        local Parent = Column

        local BoundryTop = Parent.AbsolutePosition
        local BoundryBottom = BoundryTop + Parent.AbsoluteSize

        local Top = Object.AbsolutePosition
        local Bottom = Top + Object.AbsoluteSize

        return Library:CompareVectors(Top, BoundryTop) or Library:CompareVectors(BoundryBottom, Bottom)
    end

    do
        Library.CreateColorpicker = function(self, Data)
            local Colorpicker = {
                Hue = 0,
                Saturation = 0,
                Value = 0,

                Color = FromRGB(0, 0, 0),
                HexValue = "000000",

                Flag = Data.Flag,

                IsOpen = false
            }

            local Items = { } do
                Items["ColorpickerButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(0, 14, 0, 14),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(164, 229, 255)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = FromRGB(56, 62, 62),
                    Thickness = 1.5
                }):AddToTheme({Color = "Border 2"})

                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["ColorpickerWindow"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 115, 0, 102),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 183, 0, 201),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 18)
                })  Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Inline"] = Instances:Create("Frame", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 6, 0, 6),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -12, 1, -12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Inline"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIStroke", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Palette"] = Instances:Create("TextButton", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "-,",
                    AutoButtonColor = false,
                    Position = UDim2New(0, 6, 0, 6),
                    Size = UDim2New(1, -12, 1, -40),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(164, 229, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Saturation"] = Instances:Create("ImageLabel", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Image = "rbxassetid://130624743341203",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Value"] = Instances:Create("ImageLabel", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 2, 1, 0),
                    Image = "rbxassetid://96192970265863",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, -1, 0, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["PaletteDragger"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 3, 0, 3),
                    Position = UDim2New(0, 5, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(120, 120, 120),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Items["Hue"] = Instances:Create("TextButton", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 6, 1, -6),
                    Size = UDim2New(1, -12, 0, 18),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UIGradient", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 0, 0)), RGBSequenceKeypoint(0.17, FromRGB(255, 255, 0)), RGBSequenceKeypoint(0.33, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(0, 255, 255)), RGBSequenceKeypoint(0.67, FromRGB(0, 0, 255)), RGBSequenceKeypoint(0.83, FromRGB(255, 0, 255)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                })

                Items["HueDragger"] = Instances:Create("Frame", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 2, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})
            end

            local Debounce = false
            local RenderStepped

            function Colorpicker:Get()
                return Colorpicker.Color
            end

            function Colorpicker:SetVisibility(Bool)
                Items["ColorpickerButton"].Instance.Visible = Bool
            end

            function Colorpicker:SetOpen(Bool)
                if Debounce then
                    return
                end

                Colorpicker.IsOpen = Bool

                Debounce = true

                if Colorpicker.IsOpen then
                    Items["ColorpickerWindow"].Instance.Visible = true
                    Items["ColorpickerWindow"].Instance.Parent = Library.Holder.Instance

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["ColorpickerWindow"].Instance.Position = UDim2New(0, Items["ColorpickerButton"].Instance.AbsolutePosition.X + 18, 0, Items["ColorpickerButton"].Instance.AbsolutePosition.Y - 25)
                    end)

                    for Index, Value in Library.OpenFrames do
                        if not Data.Section.IsSettings then
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Colorpicker] = Colorpicker
                else
                    if Library.OpenFrames[Colorpicker] then
                        Library.OpenFrames[Colorpicker] = nil
                    end

                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = Colorpicker.IsOpen and 4 or 1
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    Debounce = false
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                    task.wait(0.2)
                    Items["ColorpickerWindow"].Instance.Parent = not Colorpicker.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Colorpicker:Update()
                local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
                Colorpicker.Color = FromHSV(Hue, Saturation, Value)
                Colorpicker.HexValue = Colorpicker.Color:ToHex()

                Library.Flags[Colorpicker.Flag] = {
                    Color = Colorpicker.Color,
                    HexValue = Colorpicker.HexValue,
                }

                Items["ColorpickerButton"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Colorpicker.Color, Colorpicker.Alpha)
                end
            end

            local SlidingPalette = false
            local PaletteChanged

            function Colorpicker:SlidePalette(Input)
                if not Input or not SlidingPalette then
                    return
                end

                local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
                local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Saturation = ValueX
                Colorpicker.Value = ValueY

                local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.98)
                local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.98)

                Items["PaletteDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
                Colorpicker:Update()
            end

            local SlidingHue = false
            local HueChanged

            function Colorpicker:SlideHue(Input)
                if not Input or not SlidingHue then
                    return
                end

                local ValueX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Hue = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 0.995)

                Items["HueDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0, 0)})
                Colorpicker:Update()
            end

            function Colorpicker:Set(Color, Alpha)
                if type(Color) == "table" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                    Alpha = Color[4]
                elseif type(Color) == "string" then
                    Color = FromHex(Color)
                end

                Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
                Colorpicker.Alpha = Alpha or 0

                local PaletteValueX = MathClamp(1 - Colorpicker.Saturation, 0, 0.98)
                local PaletteValueY = MathClamp(1 - Colorpicker.Value, 0, 0.98)

                local HuePositionX = MathClamp(Colorpicker.Hue, 0, 0.99)

                Items["PaletteDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(PaletteValueX, 0, PaletteValueY, 0)})
                Items["HueDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(HuePositionX, 0, 0, 0)})
                Colorpicker:Update()
            end

            Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
                Colorpicker:SetOpen(not Colorpicker.IsOpen)
            end)

            Items["Palette"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    SlidingPalette = true

                    Colorpicker:SlidePalette(Input)

                    if PaletteChanged then
                        return
                    end

                    PaletteChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingPalette = false

                            PaletteChanged:Disconnect()
                            PaletteChanged = nil
                        end
                    end)
                end
            end)

            Items["Hue"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    SlidingHue = true

                    Colorpicker:SlideHue(Input)

                    if HueChanged then
                        return
                    end

                    HueChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingHue = false

                            HueChanged:Disconnect()
                            HueChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Colorpicker.IsOpen then
                        if Library:IsMouseOverFrame(Items["ColorpickerWindow"]) then
                            return
                        end

                        Colorpicker:SetOpen(false)
                    end
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if SlidingPalette then
                        Colorpicker:SlidePalette(Input)
                    end

                    if SlidingHue then
                        Colorpicker:SlideHue(Input)
                    end
                end
            end)

            Items["ColorpickerButton"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Colorpicker.IsOpen then
                    Colorpicker.IsOpen = not Library:IsClipped(Items["ColorpickerButton"].Instance, Data.Section.Items["Section"].Instance.Parent)
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                end
            end)

            if Data.Default then
                Colorpicker:Set(Data.Default)
            end

            Library.SetFlags[Colorpicker.Flag] = function(Color, Alpha)
                Colorpicker:Set(Color, Alpha)
            end

            return Colorpicker, Items
        end

        Library.CreateKeybind = function(self, Data)
            local Keybind = {
                Flag = Data.Flag,

                Key = "",
                Value = "",
                Mode = "",
                Toggled = false,

                Picking = false,
                IsOpen = false
            }

            local Items = { } do
                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "-",
                    AutoButtonColor = false,
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(30, 34, 34)
                })  Items["KeyButton"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["KeyButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["KeyButton"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 4),
                    PaddingLeft = UDimNew(0, 5)
                })

                Items["KeybindWindow"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 231, 0, 102),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 67, 0, 92),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 18)
                })  Items["KeybindWindow"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Inline"] = Instances:Create("Frame", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 6, 0, 6),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -12, 1, -12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Inline"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIStroke", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Toggle",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 4)
                })

                Items["Hold"] = Instances:Create("TextButton", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Hold",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Always"] = Instances:Create("TextButton", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Always",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end

            local Modes = {
                ["Always"] = Items["Always"],
                ["Hold"] = Items["Hold"],
                ["Toggle"] = Items["Toggle"]
            }

            local Debounce = false
            local RenderStepped

            function Keybind:SetOpen(Bool)
                if Debounce then
                    return
                end

                Keybind.IsOpen = Bool

                Debounce = true

                if Keybind.IsOpen then
                    Items["KeybindWindow"].Instance.Visible = true
                    Items["KeybindWindow"].Instance.Parent = Library.Holder.Instance

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["KeybindWindow"].Instance.Position = UDim2New(0, Items["KeyButton"].Instance.AbsolutePosition.X + 18, 0, Items["KeyButton"].Instance.AbsolutePosition.Y - 25)
                    end)

                    for Index, Value in Library.OpenFrames do
                        if not Data.Section.IsSettings then
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Keybind] = Keybind
                else
                    if Library.OpenFrames[Keybind] then
                        Library.OpenFrames[Keybind] = nil
                    end

                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["KeybindWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["KeybindWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = Keybind.IsOpen and 2 or 1
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    Debounce = false
                    Items["KeybindWindow"].Instance.Visible = Keybind.IsOpen
                    task.wait(0.2)
                    Items["KeybindWindow"].Instance.Parent = not Keybind.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Keybind:SetMode(Mode)
                for Index, Value in Modes do
                    if Index == Mode then
                        Value:Tween(nil, {TextColor3 = FromRGB(255, 255, 255)})
                    else
                        Value:Tween(nil, {TextColor3 = FromRGB(190, 196, 202)})
                    end
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.Mode,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
            end

            function Keybind:Get()
                return Keybind.Key, Keybind.Mode, Keybind.Toggled
            end

            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then
                    Keybind.Key = tostring(Key)

                    Key = Key.Name == "Backspace" and "None" or Key.Name

                    local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.", "") or "None"
                    local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    Library.Flags[Keybind.Flag] = {
                        Mode = Keybind.Mode,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }

                    if Data.Callback then
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end
                elseif type(Key) == "table" then
                    local RealKey = Key.Key == "Backspace" and "None" or Key.Key
                    Keybind.Key = tostring(Key.Key)

                    if Key.Mode then
                        Keybind.Mode = Key.Mode
                        Keybind:SetMode(Key.Mode)
                    else
                        Keybind.Mode = "Toggle"
                        Keybind:SetMode("Toggle")
                    end

                    local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
                    local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "")

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    if Data.Callback then
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end
                elseif TableFind({"Toggle", "Hold", "Always"}, Key) then
                    Keybind.Mode = Key
                    Keybind:SetMode(Key)

                    if Data.Callback then
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end
                end

                Keybind.Picking = false
            end

            function Keybind:Press(Bool)
                if Keybind.Mode == "Toggle" then
                    Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.Mode == "Hold" then
                    Keybind.Toggled = Bool
                elseif Keybind.Mode == "Always" then
                    Keybind.Toggled = true
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.Mode,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
            end

            Items["KeyButton"]:Connect("MouseButton1Click", function()
                Keybind.Picking = true

                Items["KeyButton"].Instance.Text = "."
                Library:Thread(function()
                    local Count = 1

                    while true do
                        if not Keybind.Picking then
                            break
                        end

                        if Count == 4 then
                            Count = 1
                        end

                        Items["KeyButton"].Instance.Text = Count == 1 and "." or Count == 2 and ".." or Count == 3 and "..."
                        Count += 1
                        task.wait(0.35)
                    end
                end)

                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind:Set(Input.KeyCode)
                    else
                        Keybind:Set(Input.UserInputType)
                    end

                    InputBegan:Disconnect()
                    InputBegan = nil
                end)
            end)

            Items["KeyButton"]:Connect("MouseButton2Down", function()
                Keybind:SetOpen(not Keybind.IsOpen)
            end)

            Items["KeyButton"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Keybind.IsOpen then
                    Keybind.IsOpen = not Library:IsClipped(Items["KeybindWindow"].Instance, Data.Section.Items["Section"].Instance.Parent)
                    Items["KeybindWindow"].Instance.Visible = Keybind.IsOpen
                end
            end)

            Items["Toggle"]:Connect("MouseButton1Down", function()
                Keybind.Mode = "Toggle"
                Keybind:SetMode("Toggle")
            end)

            Items["Hold"]:Connect("MouseButton1Down", function()
                Keybind.Mode = "Hold"
                Keybind:SetMode("Hold")
            end)

            Items["Always"]:Connect("MouseButton1Down", function()
                Keybind.Mode = "Always"
                Keybind:SetMode("Always")
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.Mode == "Toggle" then
                        Keybind:Press()
                    elseif Keybind.Mode == "Hold" then
                        Keybind:Press(true)
                    elseif Keybind.Mode == "Always" then
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.Mode == "Toggle" then
                        Keybind:Press()
                    elseif Keybind.Mode == "Hold" then
                        Keybind:Press(true)
                    elseif Keybind.Mode == "Always" then
                        Keybind:Press(true)
                    end
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Keybind.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["KeybindWindow"]) then
                        return
                    end

                    Keybind:SetOpen(false)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.Mode == "Hold" then
                        Keybind:Press(false)
                    elseif Keybind.Mode == "Always" then
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.Mode == "Hold" then
                        Keybind:Press(false)
                    elseif Keybind.Mode == "Always" then
                        Keybind:Press(true)
                    end
                end
            end)

            if Data.Default then
                Keybind:Set({
                    Mode = Data.Mode or "Toggle",
                    Key = Data.Default,
                })
            end

            Library.SetFlags[Keybind.Flag] = function(Value)
                Keybind:Set(Value)
            end

            return Keybind, Items
        end

        Library.Notification = function(self, Name, Duration, Icon)
            local Items = { } do
                Items["Notification"] = Instances:Create("Frame", {
                    Parent = Library.NotifHolder.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(16, 18, 18)
                })  Items["Notification"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["UIStroke"] = Instances:Create("UIStroke", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })  Items["UIStroke"]:AddToTheme({Color = "Border"})

                Instances:Create("UIPadding", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                if Icon then
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Notification"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://"..Icon,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 0, 0.5, 0),
                        Size = UDim2New(0, 16, 0, 16),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                end

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, Icon and 24 or 0, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end

            local Size = Items["Notification"].Instance.AbsoluteSize

            for Index, Value in Items do
                if Value.Instance:IsA("Frame") then
                    Value.Instance.BackgroundTransparency = 1
                elseif Value.Instance:IsA("TextLabel") then
                    Value.Instance.TextTransparency = 1
                elseif Value.Instance:IsA("ImageLabel") then
                    Value.Instance.ImageTransparency = 1
                elseif Value.Instance:IsA("UIStroke") then
                    Value.Instance.Transparency = 1
                end
            end

            task.wait(0.3)

            Items["Notification"].Instance.AutomaticSize = Enum.AutomaticSize.Y

            Library:Thread(function()
                for Index, Value in Items do
                    if Value.Instance:IsA("Frame") then
                        Value:Tween(nil, {BackgroundTransparency = 0})
                    elseif Value.Instance:IsA("TextLabel") then
                        Value:Tween(nil, {TextTransparency = 0})
                    elseif Value.Instance:IsA("ImageLabel") then
                        Value:Tween(nil, {ImageTransparency = 0.5})
                    elseif Value.Instance:IsA("UIStroke") then
                        Value:Tween(nil, {Transparency = 0})
                    end
                end

                Items["Notification"]:Tween(nil, {Size = UDim2New(0, Size.X, 0, Size.Y)})

                task.delay(Duration, function()
                    for Index, Value in Items do
                        if Value.Instance:IsA("Frame") then
                            Value:Tween(nil, {BackgroundTransparency = 1})
                        elseif Value.Instance:IsA("TextLabel") then
                            Value:Tween(nil, {TextTransparency = 1})
                        elseif Value.Instance:IsA("ImageLabel") then
                            Value:Tween(nil, {ImageTransparency = 1})
                        elseif Value.Instance:IsA("UIStroke") then
                            Value:Tween(nil, {Transparency = 1})
                        end
                    end

                    Items["Notification"]:Tween(nil, {Size = UDim2New(0, 0, 0, 0)})
                    task.wait(0.5)
                    Items["Notification"]:Clean()
                end)
            end)
        end

        Library.Window = function(self, Data)
            local StartTime = tick()
            Data = Data or { }

            local Window = {
                Name = Data.Name or Data.name or "Window",
                SubTitle = Data.SubTitle or Data.subtitle or "for PUBG",
                ExpiresIn = Data.ExpiresIn or Data.expiresin or "23d",

                Pages = { },
                Items = { },
                IsOpen = false
            }

            local Items = { } do
                local FirstLetterOfName = StringSub(Window.Name, 1, 1)
                Items["MainFrame"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 920, 0, 665),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(16, 18, 18)
                })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})
                -- HARD TOGGLE exposed for the Dream button: sets MainFrame.Visible directly, bypassing the fade
                -- tween + Debounce (which could get stuck = "clicking Dream doesn't hide the GUI"). Instant, reliable.
                _G.VX_HARDTOGGLE = function()
                    local f = Items["MainFrame"].Instance
                    local vis = not f.Visible
                    f.Visible = vis
                    Window.IsOpen = vis   -- keep RightShift's state in sync
                end

                Items["MainFrame"]:MakeDraggable()
                Items["MainFrame"]:MakeResizeable(Vector2New(540, 400), Vector2New(9999, 9999))   -- min 540x400 so the corner grip can scale the menu DOWN as well as up

                Instances:Create("UICorner", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Side"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 215, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Title"] = Instances:Create("Frame", {
                    Parent = Items["Side"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 6, 0, 6),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -12, 0, 60),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Title"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 12, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 40, 0, 40),
                    BorderSizePixel = 0,
                    Visible = false,
                    BackgroundColor3 = FromRGB(207, 207, 207)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = FirstLetterOfName,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(1, -10, 1, -10),
                    BorderSizePixel = 0,
                    TextSize = 22,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["RealTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Window.Name,
                    Size = UDim2New(0, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0, 10),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 20,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Game"] = Instances:Create("TextLabel", {
                    Parent = Items["Title"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.28,
                    Text = Window.SubTitle,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0, 36),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Pages"] = Instances:Create("Frame", {
                    Parent = Items["Side"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 75),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, -80),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Pages"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Pages"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 220, 0, 6),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -226, 1, -12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Content"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Bottom_"] = Instances:Create("Frame", {
                    Parent = Items["Side"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 6, 1, -6),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -12, 0, 45),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Bottom_"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Bottom_"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Bottom_"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["SubExpires"] = Instances:Create("TextLabel", {
                    Parent = Items["Bottom_"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = "Sub expires in "..Window.ExpiresIn,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0, 8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SessionDuration"] = Instances:Create("TextLabel", {
                    Parent = Items["Bottom_"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Session duration: ",
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0, 23),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Library:Thread(function()
                    while task.wait(1) do
                        local SecondsPassed = MathFloor(tick() - StartTime)
                        local MinutesPassed = MathFloor(SecondsPassed / 60)

                        if MinutesPassed > 0 then
                            SecondsPassed = SecondsPassed - MinutesPassed * 60
                        end

                        Items["SessionDuration"].Instance.Text = "Session duration: "..MinutesPassed..":"..SecondsPassed
                    end
                end)

                Window.Items = Items
            end

            local Debounce = false

            function Window:SetCenter()
                local CenterPosition = Items["MainFrame"].Instance.AbsolutePosition
                task.wait()
                Items["MainFrame"].Instance.AnchorPoint = Vector2New(0, 0)

                Items["MainFrame"].Instance.Position = UDim2New(0, CenterPosition.X, 0, CenterPosition.Y)
            end

            function Window:SetOpen(Bool)
                if Debounce then
                    return
                end

                Window.IsOpen = Bool

                Debounce = true
                -- GUARANTEED RELEASE (root cause of the stuck Dream button): Debounce was only cleared inside the
                -- tween's Completed callback. If the tween errored or never fired, Debounce stayed true forever and
                -- NOTHING could toggle the menu again. This always releases it and enforces final visibility.
                task.delay((Library.FadeSpeed or 0.2) + 0.3, function()
                    Debounce = false
                    pcall(function() Items["MainFrame"].Instance.Visible = Window.IsOpen end)
                end)

                if Window.IsOpen then
                    Items["MainFrame"].Instance.Visible = true
                end

                local Descendants = Items["MainFrame"].Instance:GetDescendants()
                TableInsert(Descendants, Items["MainFrame"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                if NewTween and NewTween.Tween then   -- may be nil if nothing was tweenable — the task.delay above releases Debounce regardless
                    NewTween.Tween.Completed:Connect(function()
                        Debounce = false
                        Items["MainFrame"].Instance.Visible = Window.IsOpen
                    end)
                end
            end

            Library:Connect(UserInputService.InputBegan, function(Input)
                if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)

            Window:SetCenter()
            task.wait()
            Window:SetOpen(true)
            return setmetatable(Window, Library)
        end

        Library.Page = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self,

                Name = Data.Name or Data.name or "Page",
                Icon = Data.Icon or Data.icon or "136879043989014",

                Items = { },
                SubPages = { },
                Active = false
            }

            local Items = { } do
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Window.Items["Pages"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 200, 0, 30),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Inline"})

                Items["UIStroke"] = Instances:Create("UIStroke", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    Transparency = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })  Items["UIStroke"]:AddToTheme({Color = "Border"})

                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Page.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 38, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Page"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["PageName"] = Instances:Create("TextLabel", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0, 15),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 18,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SubPages"] = Instances:Create("Frame", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 30),
                    Position = UDim2New(0, 13, 0, 42),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(16, 18, 18)
                })  Items["SubPages"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UIPadding", {
                    Parent = Items["SubPages"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 2),
                    PaddingBottom = UDimNew(0, 2),
                    PaddingRight = UDimNew(0, 2),
                    PaddingLeft = UDimNew(0, 2)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["SubPages"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 2),
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UICorner", {
                    Parent = Items["SubPages"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Columns"] = Instances:Create("Frame", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, -20, 1, -82),
                    Position = UDim2New(0, 10, 0, 75),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BackgroundTransparency = 1
                })

                Page.Items = Items
            end

            local Debounce = false

            function Page:Turn(Bool)
                if Debounce then
                    return
                end

                Page.Active = Bool

                Debounce = true
                Items["Page"].Instance.Visible = Bool
                Items["Page"].Instance.Parent = Bool and Page.Window.Items["Content"].Instance or Library.UnusedHolder.Instance

                if Page.Active then
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0})
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(200, 200, 200)})
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(200, 200, 200)})
                    Items["UIStroke"]:Tween(nil, {Transparency = 0})
                else
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1})
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(190, 196, 202)})
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(190, 196, 202)})
                    Items["UIStroke"]:Tween(nil, {Transparency = 1})
                end

                Debounce = false
            end

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in Page.Window.Pages do
                    if Value == Page and Page.Active then
                        return
                    end

                    Value:Turn(Value == Page)
                end
            end)

            if #Page.Window.Pages == 0 then
                Page:Turn(true)
            end

            TableInsert(Page.Window.Pages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Category = function(self, Name)
            local Items = { } do
                Items["Category"] = Instances:Create("TextLabel", {
                    Parent = self.Items["Pages"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = Name,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end

            return Items
        end

        Library.Pages.SubPage = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "SubPage",
                Columns = Data.Columns or Data.columns or 2,

                Items = { },
                ColumnsData = { },
                Active = false
            }

            local Items = { } do
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Page.Items["SubPages"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.5,
                    Text = Page.Name,
                    AutoButtonColor = false,
                    Size = UDim2New(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(30, 34, 34)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UIPadding", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })

                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Page"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill
                })

                for Index = 1, Page.Columns do
                    local NewColumn = Instances:Create("ScrollingFrame", {
                        Parent = Items["Page"].Instance,
                        Name = "\0",
                        ScrollBarImageColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ScrollBarThickness = 0,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        CanvasSize = UDim2New(0, 0, 0, 0),
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })

                    if Index == 1 then
                        Instances:Create("UIPadding", {
                            Parent = NewColumn.Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 3),
                            PaddingBottom = UDimNew(0, 3),
                            PaddingRight = UDimNew(0, 8),
                            PaddingLeft = UDimNew(0, 3)
                        })
                    elseif Index == 2 then
                        Instances:Create("UIPadding", {
                            Parent = NewColumn.Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 3),
                            PaddingBottom = UDimNew(0, 3),
                            PaddingRight = UDimNew(0, 20),
                            PaddingLeft = UDimNew(0, 8)
                        })
                    end

                    Instances:Create("UIListLayout", {
                        Parent = NewColumn.Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 8),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Page.ColumnsData[Index] = NewColumn
                end
            end

            local Debounce = false

            function Page:Turn(Bool)
                if Debounce then
                    return
                end

                Page.Active = Bool

                Debounce = true
                Items["Page"].Instance.Visible = Bool
                Items["Page"].Instance.Parent = Bool and Page.Page.Items["Columns"].Instance or Library.UnusedHolder.Instance

                if Page.Active then
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0, TextTransparency = 0})
                else
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1, TextTransparency = 0.5})
                end

                Debounce = false
            end

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in Page.Page.SubPages do
                    if Value == Page and Page.Active then
                        return
                    end

                    Value:Turn(Value == Page)
                end
            end)

            if #Page.Page.SubPages == 0 then
                Page:Turn(true)
            end

            TableInsert(Page.Page.SubPages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.Section = function(self, Data)
            Data = Data or { }

            local Section = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "Section",
                Icon = Data.Icon or Data.icon or "",
                Side = Data.Side or Data.side or 1,

                Items = { }
            }

            local Items = { } do
                Items["Section"] = Instances:Create("Frame", {
                    Parent = Section.Page.ColumnsData[Section.Side].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["Section"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UICorner", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Image = "rbxassetid://"..Section.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 12),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 12)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Name,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 35, 0, 12),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 42),
                    Size = UDim2New(1, -24, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Section.Items = Items
            end

            return setmetatable(Section, Library.Sections)
        end

        Library.Sections.Toggle = function(self, Data)
            Data = Data or { }

            local Toggle = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Toggle",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or false,
                Callback = Data.Callback or Data.callback or function() end,

                Value = false
            }

            local Items = { } do
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Toggle.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 16),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Toggle.Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Indicator"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 14, 0, 14),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(30, 33, 33)
                })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UIStroke", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = FromRGB(56, 62, 62),
                    Thickness = 2
                }):AddToTheme({Color = "Border 2"})

                Instances:Create("UICorner", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Inline"] = Instances:Create("Frame", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Inline"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["CheckImage"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://132128200461292",
                    ImageTransparency = 1,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(1, -4, 1, -4),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDimNew(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            function Toggle:Get()
                return Toggle.Value
            end

            function Toggle:Set(Value)
                Toggle.Value = Value
                Library.Flags[Toggle.Flag] = Value

                if Toggle.Value then
                    Items["Inline"]:Tween(nil,  {BackgroundTransparency = 0})
                    Items["CheckImage"]:Tween(nil, {ImageTransparency = 0})
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(255, 255, 255)})
                else
                    Items["Inline"]:Tween(nil,  {BackgroundTransparency = 1})
                    Items["CheckImage"]:Tween(nil, {ImageTransparency = 1})
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(190, 196, 202)})
                end

                if Toggle.Callback then
                    Library:SafeCall(Toggle.Callback, Toggle.Value)
                end
            end

            function Toggle:SetVisibility(Bool)
                Items["Toggle"].Instance.Visible = Bool
            end

            function Toggle:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end
                }

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback
                })

                return NewColorpicker
            end

            function Toggle:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.E,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle"
                }

                local NewKeybind = Library:CreateKeybind({
                    Parent = Items["SubElements"],
                    Page = Keybind.Page,
                    Section = Keybind.Section,
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback
                })

                return NewKeybind
            end

            Items["Toggle"]:Connect("MouseButton1Down", function()
                Toggle:Set(not Toggle.Value)
            end)

            Toggle:Set(Toggle.Default)

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end

            return Toggle
        end

        Library.Sections.Button = function(self, Data)
            Data = Data or { }

            local Button = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name,
                Callback = Data.Callback or Data.callback or function() end
            }

            local Items = { } do
                Items["Button"] = Instances:Create("TextButton", {
                    Parent = Button.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Button.Name,
                    AutoButtonColor = false,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(30, 34, 34)
                })  Items["Button"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = FromRGB(56, 62, 62),
                    Thickness = 2
                }):AddToTheme({Color = "Border 2"})

                Instances:Create("UIPadding", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 1)
                })
            end

            function Button:SetVisibility(Bool)
                Items["Button"].Instance.Visible = Bool
            end

            function Button:Press()
                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent, TextColor3 = FromRGB(0, 0, 0)})

                task.wait(0.1)

                Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element, TextColor3 = FromRGB(255, 255, 255)})

                Library:SafeCall(Button.Callback)
            end

            Items["Button"]:Connect("MouseButton1Down", function()
                Button:Press()
            end)

            return Button
        end

        Library.Sections.Slider = function(self, Data)
            Data = Data or { }

            local Slider = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Slider",
                Min = Data.Min or Data.min or 0,
                Max = Data.Max or Data.max or 100,
                Callback = Data.Callback or Data.callback or function() end,
                Default = Data.Default or Data.default or 0,
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Decimals = Data.Decimals or Data.decimals or 1,
                Suffix = Data.Suffix or Data.suffix or "",

                Value = 0,
                Sliding = false
            }

            local Items = { } do
                Items["Slider"] = Instances:Create("Frame", {
                    Parent = Slider.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 30),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Slider.Name,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AnchorPoint = Vector2New(1, 0),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["RealSlider"] = Instances:Create("TextButton", {
                    Parent = Items["Slider"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(30, 34, 34)
                })  Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0.4000000059604645, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Items["Circle"] = Instances:Create("Frame", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 5, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 8, 0, 8),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Circle"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Circle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(180, 180, 180)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })
            end

            function Slider:Get()
                return Slider.Value
            end

            function Slider:SetVisibility(Bool)
                Items["Slider"].Instance.Visible = Bool
            end

            function Slider:Set(Value)
                Slider.Value = Library:Round(MathClamp(Value, Slider.Min, Slider.Max), Slider.Decimals)
                Library.Flags[Slider.Flag] = Slider.Value

                Items["Accent"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), -2, 1, 0)})
                Items["Value"].Instance.Text = StringFormat("%s%s", Slider.Value, Slider.Suffix)

                if Slider.Callback then
                    Library:SafeCall(Slider.Callback, Slider.Value)
                end
            end

            local InputChanged
            local InputChanged2

            Items["RealSlider"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Slider.Sliding = true

                    local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Slider.Sliding = false

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Items["Circle"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Slider.Sliding = true

                    local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)

                    if InputChanged2 or InputChanged then
                        return
                    end

                    InputChanged2 = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Slider.Sliding = false

                            InputChanged2:Disconnect()
                            InputChanged2 = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Slider.Sliding then
                        local SizeX = (Input.Position.X - Items["RealSlider"].Instance.AbsolutePosition.X) / Items["RealSlider"].Instance.AbsoluteSize.X
                        local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                        Slider:Set(Value)
                    end
                end
            end)

            Slider:Set(Slider.Default)

            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end

            return Slider
        end

        Library.Sections.Dropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { },
                Default = Data.Default or Data.default or "",
                Callback = Data.Callback or Data.callback or function() end,
                Multi = Data.Multi or Data.multi or false,

                Value = { },
                Options = { },
                IsOpen = false
            }

            local Items = { } do
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Dropdown.Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 0, 0.5, 0),
                    Size = UDim2New(0, 110, 0, 25),
                    BorderSizePixel = 0,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(30, 34, 34)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "...",
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(1, -26, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 6, 0.5, 0),
                    BorderSizePixel = 0,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://135448248851234",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["OptionHolder"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0),
                    Position = UDim2New(1, 0, 0.5, 0),
                    Size = UDim2New(0, 80, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(21, 24, 24)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Inline"})

                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(30, 33, 33),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Border"})

                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.XY,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})

                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 4)
                })
            end

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            local Debounce = false
            local RenderStepped

            function Dropdown:SetOpen(Bool)
                if Debounce then
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true

                if Dropdown.IsOpen then
                    Items["OptionHolder"].Instance.Visible = true
                    Items["OptionHolder"].Instance.Parent = Library.Holder.Instance

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["OptionHolder"].Instance.Position = UDim2New(0, Items["RealDropdown"].Instance.AbsolutePosition.X, 0, Items["RealDropdown"].Instance.AbsolutePosition.Y + 27)
                        Items["OptionHolder"].Instance.Size = UDim2New(0, math.max(Items["RealDropdown"].Instance.AbsoluteSize.X, 210), 0, 0)   -- wider open list so long names (players) aren't cut off
                    end)

                    for Index, Value in Library.OpenFrames do
                        if Value ~= Dropdown and not Dropdown.Section.IsSettings then
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Dropdown] = Dropdown
                else
                    if Library.OpenFrames[Dropdown] then
                        Library.OpenFrames[Dropdown] = nil
                    end

                    if RenderStepped then
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween

                for Index, Value in Descendants do
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue
                    end

                    if not Value.ClassName:find("UI") then
                        Value.ZIndex = Dropdown.IsOpen and 3 or 1
                    end

                    if type(TransparencyProperty) == "table" then
                        for _, Property in TransparencyProperty do
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                NewTween.Tween.Completed:Connect(function()
                    Debounce = false
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    Items["OptionHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then
                    if type(Option) ~= "table" then
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]

                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true
                        OptionData:Toggle("Active")
                    end

                    Items["Value"].Instance.Text = TableConcat(Option, ", ")
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true
                            Value:Toggle("Active")
                        end
                    end

                    Items["Value"].Instance.Text = Option
                end

                if Dropdown.Callback then
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Option,
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionButton:AddToTheme({BackgroundColor3 = "Accent"})

                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    Selected = false
                }

                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionData.Button:Tween(nil, {BackgroundTransparency = 0, TextColor3 = FromRGB(0, 0, 0)})
                    else
                        OptionData.Button:Tween(nil, {BackgroundTransparency = 1, TextColor3 = FromRGB(190, 196, 202)})
                    end
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "..."
                        Items["Value"].Instance.Text = TextFormat
                    else
                        if OptionData.Selected then
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do
                                if Value ~= OptionData then
                                    Value.Selected = false
                                    Value:Toggle("Inactive")
                                end
                            end

                            Items["Value"].Instance.Text = OptionData.Name
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")

                            Items["Value"].Instance.Text = "..."
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Down", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do
                    Dropdown:Remove(Value.Name)
                end

                for Index, Value in List do
                    Dropdown:Add(Value)
                end
            end

            Items["RealDropdown"]:Connect("MouseButton1Down", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dropdown.IsOpen then
                        if Library:IsMouseOverFrame(Items["OptionHolder"]) or Library:IsMouseOverFrame(Items["RealDropdown"]) then
                            return
                        end

                        Dropdown:SetOpen(false)
                    end
                end
            end)

            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default and Dropdown.Default ~= "" then
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            return Dropdown
        end

        Library.Sections.Label = function(self, Name)
            local Label = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Name or "Label"
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Label.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 17),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(190, 196, 202),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Label.Name,
                    Size = UDim2New(1, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 0),
                    BorderSizePixel = 0,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 0, 0, 17),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDimNew(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            function Label:SetText(Text)
               Text = tostring(Text)
               Items["Text"].Instance.Text = Text
            end

            function Label:SetVisibility(Bool)
                Items["Label"].Instance.Visible = Bool
            end

            function Label:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Label.Window,
                    Page = Label.Page,
                    Section = Label.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end
                }

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback
                })

                return NewColorpicker
            end

            function Label:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = Label.Window,
                    Page = Label.Page,
                    Section = Label.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.E,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle"
                }

                local NewKeybind = Library:CreateKeybind({
                    Parent = Items["SubElements"],
                    Page = Keybind.Page,
                    Section = Keybind.Section,
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback
                })

                return NewKeybind
            end

            return Label
        end

        Library.Sections.Textbox = function(self, Data)
            Data = Data or { }

            local Textbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Callback = Data.Callback or Data.callback or function() end,
                Placeholder = Data.Placeholder or Data.placeholder or "Placeholder",
                Numeric = Data.Numeric or Data.numeric or false,
                Finished = Data.Finished or Data.finished or false,

                Value = ""
            }

            local Items = { } do
                Items["Textbox"] = Instances:Create("Frame", {
                    Parent = Textbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    CursorPosition = -1,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(1, 0, 1, 0),
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    PlaceholderColor3 = FromRGB(190, 196, 202),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = Textbox.Placeholder,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(30, 34, 34)
                })  Items["Input"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Color = FromRGB(56, 62, 62),
                    Thickness = 2
                }):AddToTheme({Color = "Border 2"})

                Instances:Create("UIPadding", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 8)
                })
            end

            function Textbox:Get()
                return Textbox.Value
            end

            function Textbox:SetVisibility(Bool)
                Items["Textbox"].Instance.Visible = Bool
            end

            function Textbox:Set(Value)
                if Textbox.Numeric then
                    if (not tonumber(Value)) and StringLen(tostring(Value)) > 0 then
                        Value = Textbox.Value
                    end
                end

                Textbox.Value = Value
                Items["Input"].Instance.Text = Value
                Library.Flags[Textbox.Flag] = Value

                if Textbox.Callback then
                    Library:SafeCall(Textbox.Callback, Value)
                end
            end

            if Textbox.Finished then
                Items["Input"]:Connect("FocusLost", function(PressedEnterQuestionMark)
                    if PressedEnterQuestionMark then
                        Textbox:Set(Items["Input"].Instance.Text)
                    end
                end)
            else
                Items["Input"].Instance:GetPropertyChangedSignal("Text"):Connect(function()
                    Textbox:Set(Items["Input"].Instance.Text)
                end)
            end

            if Textbox.Default then
                Textbox:Set(Textbox.Default)
            end

            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end

            return Textbox
        end
    end

    Library.CreateSettingsPage = function(self, Window)
        local SettingsPage = Window:Page({Name = "Settings", Icon = "72732892493295"}) do
            local ConfigsSubPage = SettingsPage:SubPage({Name = "Configs"})
            local ThemingSubPage = SettingsPage:SubPage({Name = "Theming"})
            local SettingsSubPage = SettingsPage:SubPage({Name = "Settings"})

            do -- Configs
                local ConfigsSection = ConfigsSubPage:Section({Name = "Configs", Side = 1, Icon = "97491613646216"})

                local ConfigName = ""
                local ConfigSelected

                local ConfigsList = ConfigsSection:Dropdown({
                    Name = "Configs",
                    Flag = "ConfigsList",
                    Items = { },
                    Multi = false,
                    Callback = function(Value)
                        ConfigSelected = Value
                    end
                })

                ConfigsSection:Textbox({
                    Default = "",
                    Flag = "ConfigName",
                    Placeholder = "Config name",
                    Callback = function(Value)
                        ConfigName = Value
                    end
                })

                ConfigsSection:Button({
                    Name = "Create",
                    Callback = function()
                    if ConfigName and ConfigName ~= "" then
                        if not isfile(Library.Folders.Configs .. "/" .. ConfigName .. ".json") then
                            writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
                            Library:RefreshConfigsList(ConfigsList)
                        else
                            return
                        end
                    end
                end})

                ConfigsSection:Button({
                    Name = "Delete",
                    Callback = function()
                    if ConfigSelected then
                        Library:DeleteConfig(ConfigSelected)
                        Library:RefreshConfigsList(ConfigsList)
                    end
                end})

                ConfigsSection:Button({
                    Name = "Load",
                    Callback = function()
                    if ConfigSelected then
                        Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected))
                    end
                end})

                ConfigsSection:Button({
                    Name = "Save",
                    Callback = function()
                    if ConfigName and ConfigName ~= "" then
                        writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
                        Library:RefreshConfigsList(ConfigsList)
                    end
                end})

                ConfigsSection:Button({
                    Name = "Refresh",
                    Callback = function()
                    Library:RefreshConfigsList(ConfigsList)
                end})

                Library:RefreshConfigsList(ConfigsList)
            end

            do -- Theming
                local ThemingSection = ThemingSubPage:Section({Name = "Theming", Icon = "131595494666590", Side = 1})
                for Index, Value in Library.Theme do
                    ThemingSection:Label(Index):Colorpicker({
                        Flag = Index.."Theme",
                        Default = Value,
                        Callback = function(Value)
                            Library.Theme[Index] = Value
                            Library:ChangeTheme(Index, Value)
                        end
                    })
                end
            end

            do -- Settings
                local SettingsSection = SettingsSubPage:Section({Name = "Settings", Icon = "72732892493295", Side = 1})

                SettingsSection:Button({
                    Name = "Unload",
                    Callback = function()
                        Library:Unload()
                    end
                })

                SettingsSection:Label("Menu Keybind"):Keybind({
                    Name = "Menu Keybind",
                    Flag = "MenuKeybind",
                    Default = Library.MenuKeybind,
                    Mode = "Toggle",
                    Callback = function()
                        Library.MenuKeybind = Library.Flags["MenuKeybind"].Key
                    end
                })

                SettingsSection:Slider({
                    Name = "Tween Speed",
                    Default = 0.3,
                    Flag = "Tween Speed",
                    Decimals = 0.01,
                    Suffix = "s",
                    Max = 10,
                    Min = 0,
                    Callback = function(Value)
                        Library.Tween.Time = Value
                    end
                })

                SettingsSection:Dropdown({
                    Name = "Tween Style",
                    Flag = "Tween style",
                    Items = { "Linear", "Quad", "Quart", "Back", "Bounce", "Circular", "Cubic", "Elastic", "Exponential", "Sine", "Quint" },
                    Default = "Quart",
                    Callback = function(Value)
                        if not Value then Value = "Quint" end
                        Library.Tween.Style = Enum.EasingStyle[Value]
                    end
                })

                SettingsSection:Dropdown({
                    Name = "Tween Direction",
                    Flag = "Tween direction",
                    Items = { "In", "Out", "InOut" },
                    Default = "Out",
                    Callback = function(Value)
                        if not Value then Value = "Out" end
                        Library.Tween.Direction = Enum.EasingDirection[Value]
                    end
                })
            end
        end
    end
end

-- ===================== VAULTIX FEATURE WIRING =====================
do
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local function tier(min) local r = { free = 1, premium = 2, plus = 3 } return (r[VX_TIER] or 3) >= (r[min] or 99) end
    local function playerList()
        local t = { "Nearest" }
        for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LocalPlayer then t[#t + 1] = pl.Name end end
        local chs = workspace:FindFirstChild("Characters")   -- DUMMIES too (any non-player model with a Humanoid, e.g. 'Dummy') so Auto Farm can grind on them
        if chs then for _, m in ipairs(chs:GetChildren()) do
            if m:IsA("Model") and m.Name ~= LocalPlayer.Name and not Players:FindFirstChild(m.Name) and m:FindFirstChildOfClass("Humanoid") then t[#t + 1] = m.Name end
        end end
        return t
    end

    local tierNice = (VX_TIER == "free" and "FREE") or (VX_TIER == "plus" and "PLUS") or "VIP"

    -- ════════ ABILITY-ARENA GUI PORT (Fluriore) ════════
    -- The hub uses the "Ability Arena" GUI library (Fluriore) instead of the embedded Vaultix UI, per request.
    -- SAFETY: this is a drop-in ADAPTER — every existing `sec:Toggle{...}` / `:Slider` / `:Dropdown` call below is
    -- UNCHANGED; we only swap what `Library` points at. The adapter maps JJS's API
    -- (Window:Category/Page -> Page:SubPage -> SubPage:Section -> Section:Toggle/Slider/Dropdown/Button/Label/Textbox)
    -- onto Fluriore's MakeGui/CreateTab/AddSection/AddToggle/... Each adapter method is TOTAL: it pcall-wraps the
    -- Fluriore call and ALWAYS returns a valid stub object, so a signature mismatch degrades to "that one control is
    -- missing" — it can never crash the wiring. If Fluriore fails to load at all, we keep the original working GUI
    -- (Library is left untouched), so the menu can never end up bricked.
    do
        local FluLib
        -- Load the external UI lib DEFENSIVELY. If the third-party repo returns broken/mangled source, a raw
        -- loadstring(...)() throws a scary ":1: Expected identifier..." compile error. Here we fetch, then
        -- COMPILE-CHECK (loadstring returns nil+err on bad source instead of throwing), and only call it when it
        -- compiled to a function. Any failure just leaves FluLib nil, so the hub silently uses its built-in GUI.
        pcall(function()
            local src
            pcall(function() src = game:HttpGet("https://raw.githubusercontent.com/Mc4121ban/Fluriore-UI/main/source.lua") end)
            if type(src) == "string" and #src > 100 and src:sub(1, 1) ~= "<" then   -- guard against HTML/404 pages
                local fn = loadstring(src)                                          -- nil,err on a syntax error (no throw)
                if type(fn) == "function" then
                    local ok, lib = pcall(fn)
                    if ok then FluLib = lib end
                end
            end
        end)
        if type(FluLib) == "table" and type(FluLib.MakeGui) == "function" then
            local RED = Color3.fromRGB(220, 30, 40)   -- Ability Arena accent: deeper blood red on near-black
            local function arr(t) local o = {}; if type(t) == "table" then for _, v in ipairs(t) do o[#o + 1] = v end elseif t ~= nil then o[1] = t end return o end
            local function asTable(v) if type(v) == "table" then return v elseif v ~= nil then return { v } else return {} end end
            local flWin
            local STUB = {}   -- returned for any element; every sub-method is a safe no-op so chained calls never error
            setmetatable(STUB, { __index = function() return function() end end })
            local function elemWrap(el)   -- wrap a real Fluriore element so :Refresh/:Set/:Get/:Colorpicker/:Keybind never error
                return setmetatable({
                    Refresh = function(_, opts) if el and type(el.Refresh) == "function" then pcall(function() el:Refresh(arr(opts)) end) end end,
                    Set = function(_, v) if el and type(el.Set) == "function" then pcall(function() el:Set(v) end) end end,
                    Get = function() if el and type(el.Get) == "function" then local ok, r = pcall(function() return el:Get() end); if ok then return r end end end,
                    SetText = function(_, t) if el and type(el.SetText) == "function" then pcall(function() el:SetText(t) end) end end,
                    Colorpicker = function() return STUB end,   -- Fluriore has no colorpicker; theming falls back silently
                    Keybind = function() return STUB end,       -- menu keybind still works via the RightShift handler
                }, { __index = function() return function() return STUB end end })
            end
            local adapter = {}
            local function guard(o) return setmetatable(o, { __index = function() return function() return STUB end end }) end   -- any UNDEFINED method -> safe stub (menu can never crash on a missing method)
            function adapter:Window(cfg)
                cfg = cfg or {}
                -- snapshot the GUI hosts BEFORE MakeGui so we can find the exact ScreenGui it creates -> the Dream
                -- icon can then hide/show it. (Under Fluriore the original _G.VX_HARDTOGGLE never runs = "icon no work".)
                local hosts = {}
                pcall(function() if gethui then hosts[#hosts + 1] = gethui() end end)
                pcall(function() hosts[#hosts + 1] = game:GetService("CoreGui") end)
                pcall(function() hosts[#hosts + 1] = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
                local before = {}
                for _, h in ipairs(hosts) do pcall(function() for _, g in ipairs(h:GetChildren()) do before[g] = true end end) end
                pcall(function() flWin = FluLib:MakeGui({ NameHub = cfg.Name or "Dream Hub", Description = cfg.SubTitle or "", Color = RED }) end)
                local flScreen
                for _, h in ipairs(hosts) do pcall(function() for _, g in ipairs(h:GetChildren()) do if not before[g] and g:IsA("ScreenGui") then flScreen = g; break end end end); if flScreen then break end end
                -- DARKER BLACK theme: pull Fluriore's grey panels toward near-black (keeps the red accent popping).
                -- Gentle: only recolours dark-grey backgrounds (leaves the red accent + text alone), and re-applies
                -- to elements added later.
                local function darken(o)
                    pcall(function()
                        if (o:IsA("Frame") or o:IsA("ScrollingFrame") or o:IsA("TextButton") or o:IsA("ImageButton")) and o.BackgroundTransparency < 0.95 then
                            local c = o.BackgroundColor3
                            local mx = math.max(c.R, c.G, c.B)
                            if mx < 0.30 and math.abs(c.R - c.B) < 0.12 and math.abs(c.G - c.B) < 0.12 then   -- a neutral dark grey (not the red accent)
                                o.BackgroundColor3 = Color3.new(c.R * 0.3, c.G * 0.3, c.B * 0.3)   -- AA-dark: pull the greys to near-black
                            end
                        end
                    end)
                end
                task.spawn(function()
                    task.wait(0.3)
                    if flScreen then
                        pcall(function() for _, d in ipairs(flScreen:GetDescendants()) do darken(d) end end)
                        pcall(function() flScreen.DescendantAdded:Connect(function(d) task.defer(darken, d) end) end)
                    end
                end)
                _G.VX_HARDTOGGLE = function()   -- the Dream icon calls this: flip the Fluriore menu's visibility
                    if flWin then
                        if type(flWin.Toggle) == "function" then pcall(function() flWin:Toggle() end); return end
                        if type(flWin.SetOpen) == "function" then pcall(function() flWin:SetOpen(not flWin.IsOpen) end); return end
                    end
                    if flScreen then pcall(function() flScreen.Enabled = not flScreen.Enabled end) end
                end
                local W = {}
                function W:Category() end   -- Fluriore has no categories; wiring calls this as a bare statement
                function W:SetOpen() if _G.VX_HARDTOGGLE then pcall(_G.VX_HARDTOGGLE) end end   -- minimize button routes through the hard toggle
                -- SAME ICON SET AS THE ABILITY ARENA HUB: Fluriore only renders rbxassetid (a Lucide name falls
                -- back to the default flame), so map each tab's name to the real asset id, exactly like AA does.
                local FL_TAB_ICON = "rbxassetid://16932740082"
                local FL_ICONS = {
                    home = "rbxassetid://7733960981", swords = "rbxassetid://7733798747", sparkles = "rbxassetid://8997388430",
                    navigation = "rbxassetid://7734020989", footprints = "rbxassetid://7743870731", eye = "rbxassetid://7733774602",
                    target = "rbxassetid://7743872758", wrench = "rbxassetid://7743878358",
                    -- aliases for this hub's tab names -> the closest AA icon
                    bot = "rbxassetid://8997388430", crosshair = "rbxassetid://7743872758",
                    user = "rbxassetid://7733960981", settings = "rbxassetid://7743878358",
                }
                function W:Page(pc)
                    pc = pc or {}
                    local _ic = pc.Icon
                    if _ic ~= nil and tostring(_ic):match("^%d+$") then _ic = "rbxassetid://" .. tostring(_ic)
                    else _ic = FL_ICONS[tostring(_ic or ""):lower()] or FL_TAB_ICON end
                    local flTab; pcall(function() flTab = flWin:CreateTab({ Name = pc.Name or "Tab", Icon = _ic }) end)
                    local P = {}
                    function P:SubPage()   -- Fluriore has no sub-pages; a SubPage just forwards to the tab
                        local SP = {}
                        function SP:Section(sc)
                            sc = sc or {}
                            local flSec; pcall(function() flSec = flTab:AddSection(sc.Name or "Section") end)
                            local S = {}
                            local function sec() return flSec or flTab end
                            function S:Toggle(c) c = c or {}; local el; pcall(function() el = sec():AddToggle({ Title = c.Name or "Toggle", Content = c.Info or "", Default = c.Default and true or false, Callback = c.Callback or function() end }) end); return elemWrap(el) end
                            function S:Slider(c) c = c or {}; local el; pcall(function() el = sec():AddSlider({ Title = c.Name or "Slider", Content = c.Suffix or "", Min = c.Min or 0, Max = c.Max or 100, Increment = c.Decimals or 1, Default = c.Default or c.Min or 0, Callback = c.Callback or function() end }) end); return elemWrap(el) end
                            function S:Dropdown(c) c = c or {}; local el; pcall(function() el = sec():AddDropdown({ Title = c.Name or "Dropdown", Content = "", Multi = false, Options = arr(c.Items), Default = asTable(c.Default), Callback = c.Callback or function() end }) end); return elemWrap(el) end
                            function S:Button(c) c = c or {}; pcall(function() sec():AddButton({ Title = c.Name or "Button", Content = "", Callback = c.Callback or function() end }) end); return elemWrap(nil) end
                            function S:Label(t) local el; pcall(function() el = sec():AddParagraph({ Title = tostring(t or ""), Content = "" }) end); return elemWrap(el) end
                            function S:Textbox(c) c = c or {}; local el; local nm=c.Name or "Input"; local ph=c.Placeholder or c.PlaceholderText or ""
                                pcall(function() el = sec():AddInput({ Title = nm, Content = ph, Callback = c.Callback or function() end }) end)
                                task.defer(function() pcall(function()
                                    local host=(typeof(gethui)=="function" and gethui()) or game:GetService("CoreGui")
                                    for _,d in ipairs(host:GetDescendants()) do
                                        if d:IsA("TextBox") and d.PlaceholderText=="Write your input there" then d.PlaceholderText=(ph~="" and ph or "type here...") break end
                                    end
                                end) end)
                                return elemWrap(el) end
                            return guard(S)
                        end
                        return guard(SP)
                    end
                    return guard(P)
                end
                return guard(W)
            end
            function adapter:CreateSettingsPage() end   -- config/theming page is skipped under the ported GUI (non-critical)
            function adapter:Notification(msg) pcall(function() if flWin and flWin.MakeNotify then flWin:MakeNotify({ Title = "Dream Hub", Description = tostring(msg), Time = 3 }) end end) end
            Library = adapter   -- take over; all the wiring below now builds on the Ability Arena GUI
        end
    end

    local Window = Library:Window({ Name = "Dream Hub  |  " .. tierNice .. "  " .. (VX_BUILD or ""), SubTitle = "", ExpiresIn = "lifetime" })   -- tier + build in the title, empty subtitle = no red badge overlapping the name

    -- MINIMIZE button (PC + mobile): a small floating, draggable tap button that hides/shows the whole menu.
    pcall(function()
        local mmGui = Instance.new("ScreenGui")
        mmGui.Name = "DreamMin"; mmGui.ResetOnSpawn = false; mmGui.IgnoreGuiInset = false; mmGui.DisplayOrder = 9600
        pcall(function() mmGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not mmGui.Parent then mmGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        local btn = Instance.new("ImageButton")
        -- LOGO FIX (was: a blank purple circle): the rbxthumb image often never loads in-game, and the old
        -- fallback was a flat purple disc with tiny text. Now the button ALWAYS looks finished from frame one —
        -- a purple→blue gradient circle, white ring, and "DREAM" across it — and the real logo image only fades
        -- in ON TOP if (and only if) it verifiably loads. No more blank circle in any case.
        local LOGO_ID = "82151574125055"
        btn.Size = UDim2.fromOffset(52, 52); btn.Position = UDim2.new(0.5, -26, 0, 4); btn.AnchorPoint = Vector2.new(0, 0)
        btn.BackgroundTransparency = 0; btn.BackgroundColor3 = Color3.fromRGB(124, 86, 255)
        btn.AutoButtonColor = true
        btn.Image = "rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=150&h=150"
        btn.ImageTransparency = 1   -- hidden until we KNOW it loaded
        btn.ScaleType = Enum.ScaleType.Fit
        btn.Active = true; btn.ZIndex = 10; btn.Parent = mmGui
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local grad = Instance.new("UIGradient"); grad.Rotation = 55
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(158, 96, 255)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(110, 82, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 120, 255)),
        }); grad.Parent = btn
        local ring = Instance.new("UIStroke"); ring.Color = Color3.fromRGB(255, 255, 255); ring.Transparency = 0.45; ring.Thickness = 1.6; ring.Parent = btn
        local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBlack; tl.Text = "DREAM"; tl.TextScaled = true; tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.ZIndex = 11; tl.Parent = btn
        local pad2 = Instance.new("UIPadding"); pad2.PaddingLeft = UDim.new(0, 6); pad2.PaddingRight = UDim.new(0, 6)
        pad2.PaddingTop = UDim.new(0, 17); pad2.PaddingBottom = UDim.new(0, 17); pad2.Parent = tl
        task.spawn(function()   -- show the real logo image only once it has ACTUALLY loaded
            for _ = 1, 40 do
                if not btn.Parent then return end
                if btn.IsLoaded then break end
                task.wait(0.15)
            end
            if btn.Parent and btn.IsLoaded then pcall(function() btn.ImageTransparency = 0; tl.Visible = false end) end
        end)
        -- DRAG (custom - won't capture-freeze movement) + TAP toggles the menu only if you didn't drag
        do
            local dragging, moved, startPos, startMouse = false, false, nil, nil
            local UISm = game:GetService("UserInputService")
            btn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; moved = false; startPos = btn.Position; startMouse = i.Position
                end
            end)
            UISm.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - startMouse
                    if math.abs(d.X) + math.abs(d.Y) > 6 then moved = true end
                    btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            UISm.InputEnded:Connect(function(i)
                if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and dragging then
                    dragging = false   -- just end the drag; the toggle is handled by Activated below (one path = no double-toggle)
                end
            end)
            -- HARD toggle (fixes "clicking Dream doesn't hide the GUI"): use the direct MainFrame.Visible toggle
            -- exposed by the window, which bypasses the fade tween + Debounce that could get stuck. Fires on both
            -- Activated AND InputEnded (whichever the executor delivers), guarded by `moved` + a small debounce so
            -- one tap = one toggle.
            local lastToggle = 0
            local function hardToggle()
                if moved then return end
                if tick() - lastToggle < 0.25 then return end
                lastToggle = tick()
                if _G.VX_HARDTOGGLE then pcall(_G.VX_HARDTOGGLE)
                elseif Window then pcall(function() Window:SetOpen(not Window.IsOpen) end) end
            end
            btn.Activated:Connect(hardToggle)
            btn.MouseButton1Click:Connect(hardToggle)
        end
    end)

    Window:Category("Vaultix")

    -- ===================== COMBAT =====================
    local CombatPage = Window:Page({ Name = "Combat", Icon = "swords" })

    local bfSub = CombatPage:SubPage({ Name = "Black Flash", Columns = 2 })
    local bfSec = bfSub:Section({ Name = "Black Flash", Side = 1 })
    -- M1 BF: count your M1 clicks; after the chosen count, press 3 = black flash, then reset.
    -- (NO remote hook: the previous build's global remote hook intercepted the SAME remotes your
    -- moves fire, which is what broke 1-4/R/ult. This version never touches the game's remotes.)
    local bfM1On, bfAutoOn = false, false
    local bfClickOffset = 0
    local bfCount = 1   -- press 3 after this many M1 clicks (1 = every click)
    do
        local UISbf = game:GetService("UserInputService")
        local VIMbf = game:GetService("VirtualInputManager")
        local function press3()
            _G.VX_INJ_KEYS = _G.VX_INJ_KEYS or {}; _G.VX_INJ_KEYS[Enum.KeyCode.Three] = tick() + 0.3
            pcall(function()
                VIMbf:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
                task.wait(0.025)   -- the small hold from your working AutoBlackFlash script
                VIMbf:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
            end)
        end
        local m1s, lastM1, lastCount = 0, 0, 0
        local function onClick()
            -- ONLY stamp the click now. The Black Flash engine does the actual press (gated by BF After (M1s))
            -- off your M1 animation, so this no longer double-presses or ignores the count.
            _G.VX_LAST_CLICK = tick()
            -- The poll now calls this EVERY FRAME the button is held (that is the fix for held combos), so the
            -- debug probe below has to be throttled or one held M1 queues sixty of them.
            if _G.VX_BF_DEBUG and tick() - (_G.VX_BF_PROBE_T or 0) > 1 then
                _G.VX_BF_PROBE_T = tick()
                local at = _G.VX_LAST_CLICK
                task.delay(0.7, function()   -- if no flash fired after this click, the M1 windup anim was never caught
                    if _G.VX_BF_DEBUG and (_G.VX_BF_LAST_FIRE or 0) < at then
                        pcall(function() print("[BF] click seen but NO windup anim detected in 0.7s -> the engine can't see your M1 animation (send me this)") end)
                    end
                end)
            end
        end
        local _ = press3   -- kept for reference; the engine handles the press now
        _G.VX_ON_M1 = onClick   -- the bypass __namecall hook pings this when your M1 remote (...Service.RE.Activated) fires
        UISbf.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not UISbf:GetFocusedTextBox() then onClick() end
        end)
        pcall(function() LP:GetMouse().Button1Down:Connect(onClick) end)
        -- THIRD path (the real fix): the game SINKS the M1 click, so InputBegan/Button1Down don't fire for it
        -- (they fire for GUI/empty clicks, which is why "it works when I click the GUI but not when I M1"). Poll
        -- the raw mouse-button state every frame and catch the rising edge - this sees the click even when the
        -- game consumes it.
        do
            local RS_bf = game:GetService("RunService")
            local wasDown = false
            RS_bf.RenderStepped:Connect(function()
                -- Stamp the click for BOTH M1 BF and Auto BF. The engine's universal fallback (fire on any
                -- Action-priority attack anim right after a click) needs this stamp; without it Auto BF only
                -- caught the handful of hardcoded windup ids and missed most characters' M1 windups.
                -- Gate on the ENGINE's real state, not the GUI toggles: dash modes borrow the engine
                -- transiently, and the old check made the poll bail during exactly those borrows = no flash.
                if not (bfM1On or bfAutoOn or _G.VX_BFAPI_ON) then wasDown = false; return end
                local down = UISbf:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                -- HELD = still attacking (see the note on the shared poll at the top of the file). JJS advances
                -- the combo while the button is down, so the stamp has to stay fresh or the engine only ever
                -- sees swing 1 of a held combo and never flashes on 2/3/4.
                if down and not UISbf:GetFocusedTextBox() then onClick() end
                wasDown = down
            end)
        end
    end
    -- M1 BF AND Auto BF both run your verbatim AutoBlackFlash engine (the anim watcher that presses 3 on the
    -- BF windup anims) — so M1 BF = your exact script running on your character's M1 + the click press below.
    -- bfSync is the ONLY place the user's real flash preference is expressed. Record it globally so a dash
    -- mode that temporarily borrows the engine can restore exactly this, instead of leaving it stuck on.
    local function bfSync() _G.VX_BFAPI_WANT = (bfAutoOn or bfM1On) and true or false; if BFApi then BFApi.SetEnabled(_G.VX_BFAPI_WANT) end end
    bfSec:Dropdown({ Name = "Mode", Items = (tier("premium") and { "Off", "M1 BF", "Side Dash", "Back Dash", "Jump", "Teleport", "M1 Chain" } or { "Off", "M1 BF" }), Default = "Off", Callback = function(m)
        m = (type(m) == "table") and m[1] or m
        if not _G.VXBF2 then return end
        -- BFApi is the engine that actually produces a Black Flash (it polls for the real M1 click, which the
        -- game sinks, and presses 3 on the correct animation frame). A dash mode needs it — but ONLY for its own
        -- flash beat. Arming it permanently here is what made EVERY M1 auto-flash with the "M1 Black Flash"
        -- toggle off. So the dropdown no longer touches bfM1On for dash modes: the mode borrows the engine for
        -- ~0.6s inside m1ThenBF and hands it straight back to whatever YOU chose (bfM1On / bfAutoOn).
        if m == "Off" then _G.VXBF2.setEnabled(false); _G.VXBF2.setBFM1(false); bfM1On = false; bfSync()
        elseif m == "M1 BF" then _G.VXBF2.setEnabled(false); _G.VXBF2.setBFM1(false); bfM1On = true; bfSync()
        elseif m == "M1 Chain" then _G.VXBF2.setBFM1(false); _G.VXBF2.setMode("M1"); _G.VXBF2.setEnabled(true); bfSync()
        else _G.VXBF2.setBFM1(false); _G.VXBF2.setMode(m); _G.VXBF2.setEnabled(true); bfSync() end
    end })
    -- M1 BF as a direct TOGGLE too: the Mode dropdown callback is flaky on this UI lib (that is why Feint M1
    -- is a toggle), so selecting "M1 BF" from the dropdown sometimes never fired and M1 BF stayed off. This
    -- toggle always fires, so it is the reliable way to turn M1 Black Flash on.
    bfSec:Toggle({ Name = "M1 Black Flash", Default = false, Callback = function(b)
        bfM1On = (b == true); bfSync()
        if _G.VXBF2 then _G.VXBF2.setBFM1(bfM1On) end
    end })
    _G.VX_BF_AFTER = 1
    -- Governs BOTH M1 Black Flash and the M1 Chain: pick which swing of your combo the flash lands on.
    bfSec:Dropdown({ Name = "BF After (M1s)", Items = { "1", "2", "3" }, Default = "1", Callback = function(v) v = (type(v) == "table") and v[1] or v; bfCount = tonumber(v) or 1; _G.VX_BF_AFTER = bfCount end })
    bfSec:Toggle({ Name = "Auto Black Flash", Default = false, Callback = function(b)
        bfAutoOn = (b == true); bfSync()
        if _G.VXBF2 then _G.VXBF2.setAutoBF(false) end   -- avoid the weaker VXBF2 path double-pressing
    end })
    bfSec:Toggle({ Name = "BF Uses Reclick (off = less fling)", Default = true, Callback = function(b) _G.VX_BF_RECLICK = (b == true); _G.VX_BF_RECLICK_USER = (b == true) end })   -- _USER is the real preference; chains suppress the live one transiently and restore from this
    -- "BF Debug (print)" and "Debug On Screen" toggles REMOVED from the menu (they were clutter). The globals
    -- still exist, so a debug run is `_G.VX_BF_DEBUG = true` / `_G.VX_DEBUG_HUD = true` before the loadstring.
    bfSec:Slider({ Name = "BF Cooldown", Min = 0.1, Max = 2, Default = 0.5, Decimals = 0.05, Suffix = "s", Callback = function(v) if _G.VXBF2 then _G.VXBF2.setCooldown(v) end end })
    -- BF Timing: nudge the flash input earlier(-)/later(+) to hit the exact flash frame for YOUR character.
    bfSec:Slider({ Name = "BF Timing", Min = -0.12, Max = 0.4, Default = 0, Decimals = 0.01, Suffix = "s", Callback = function(v) v = tonumber(v) or 0; bfClickOffset = v; if BFApi then BFApi.SetTimingOffset(v) end end })
    if tier("premium") then bfSec:Slider({ Name = "Teleport/Jump Dist", Min = 2, Max = 8, Default = 3, Decimals = 0.5, Callback = function(v) if _G.VXBF2 then _G.VXBF2.setTeleportDist(v) end end }) end
    -- FREE feint keeps only M1 + Moves(skills); premium adds Feint Black Flash
    -- Feint M1 as a direct TOGGLE (dropdown Callbacks are unreliable on this UI lib; toggles always fire).
    bfSec:Toggle({ Name = "Feint M1", Default = false, Callback = function(b) if ChainApi then ChainApi.setFeintMode(b and "M1" or "Off") end end })
    bfSec:Dropdown({ Name = "Feint After (M1 count)", Items = { "1", "2", "3" }, Default = "2", Callback = function(v) if ChainApi then ChainApi.setFeintM1Count(v) end end })
    if tier("premium") then bfSec:Dropdown({ Name = "Stop After", Items = { "1", "2", "3", "4" }, Default = "2", Callback = function(v) if ChainApi then ChainApi.setFeintBFStop(v) end end }) end
    if tier("premium") then bfSec:Dropdown({ Name = "Move After Feint", Items = { "1", "2", "3", "4" }, Default = "1", Callback = function(v) if ChainApi then ChainApi.setFeintMove(v) end end }) end
    bfSec:Toggle({ Name = "Feint Abilities", Default = false, Callback = function(b) if ChainApi and ChainApi.setFeintMoves then ChainApi.setFeintMoves(b) end end })
    if tier("premium") then bfSec:Toggle({ Name = "Aim Assist", Default = false, Callback = function(b) if AimAssistApi then AimAssistApi.set(b) end end }) end
    bfSec:Toggle({ Name = "Yuta Black Flash", Default = false, Callback = function(b) if YutaBFApi then YutaBFApi.setManual(b) end end })
    bfSec:Slider({ Name = "Cooldown", Min = 0.1, Max = 1, Default = 0.45, Decimals = 0.01, Suffix = "s", Callback = function(v) if BFApi then BFApi.SetCooldown(v) end end })
    bfSec:Toggle({ Name = "Mobile BF Button", Default = false, Callback = function(b)   -- phone: floating tap button that fires the black flash for the current mode
        if ChainApi then ChainApi.setMobile(b) end
    end })
    if tier("premium") then
        bfSec:Slider({ Name = "Back Dist", Min = 1, Max = 6, Default = 2, Decimals = 0.1, Callback = function(v) if ChainApi then ChainApi.setBackDistance(v) end end })
        bfSec:Slider({ Name = "Range", Min = 10, Max = 60, Default = 30, Decimals = 1, Callback = function(v) if ChainApi then ChainApi.setLockRange(v) end end })
    end
    local blockSec = bfSub:Section({ Name = "Auto Block", Side = 2 })
    blockSec:Toggle({ Name = "Dash Block", Default = false, Callback = function(b) BlockFlags.Dash = b end })
    blockSec:Toggle({ Name = "M1 Block", Default = false, Callback = function(b) BlockFlags.M1 = b end })
    blockSec:Toggle({ Name = "Abilities Block", Default = false, Callback = function(b) BlockFlags.Abilities = b end })
    blockSec:Toggle({ Name = "Camera Follow", Default = true, Callback = function(b) BlockFlags.CameraFollow = b end })

    local skSub = CombatPage:SubPage({ Name = "Skills", Columns = 2 })
    local skSec = skSub:Section({ Name = "Skills & M1", Side = 1 })
    skSec:Toggle({ Name = "Gojo TP Back", Callback = function(b) if GojoTpApi then GojoTpApi.set(b) end end })
    skSec:Dropdown({ Name = "TP Back Trigger", Items = { "Q Dash", "After M1s" }, Default = "Q Dash", Callback = function(v) _G.VX_GOJO_MODE = (type(v) == "table") and v[1] or v end })
    skSec:Dropdown({ Name = "TP Back After (M1s)", Items = { "1", "2", "3", "4" }, Default = "2", Callback = function(v) v = (type(v) == "table") and v[1] or v; _G.VX_GOJO_COUNT = tonumber(v) or 2 end })
    skSec:Slider({ Name = "Back Lock Time", Min = 0, Max = 2, Default = 1, Decimals = 0.05, Suffix = "s", Callback = function(v) _G.VX_GOJO_LOCK = tonumber(v) or 1 end })
    skSec:Toggle({ Name = "Reversal Red", Callback = function(b) if ReversalRedApi then ReversalRedApi.set(b) end end })
    skSec:Toggle({ Name = "Auto Rika Down Slam", Callback = function(b) if SlamApi then SlamApi.set(b) end end })   -- near a player/dummy -> auto down slam them
    local ultSec = skSub:Section({ Name = "Ults", Side = 2 })
    if tier("premium") then   -- FREE: no Crow Ult / Crow Lock On
        ultSec:Toggle({ Name = "Crow Ult", Callback = function(b) if CrowUltApi then CrowUltApi.set(b) end end })
        ultSec:Toggle({ Name = "Crow Lock On", Callback = function(b) if CrowHitApi then CrowHitApi.set(b) end end })
    end
    ultSec:Toggle({ Name = "Head of Hei Ult", Callback = function(b) if HeadUltApi then HeadUltApi.set(b) end end })
    ultSec:Slider({ Name = "Hei Ult Timing", Min = 0.05, Max = 0.6, Default = 0.26, Decimals = 0.01, Suffix = "s", Callback = function(v) if HeadUltApi and HeadUltApi.setLead then HeadUltApi.setLead(v) end end })
    if tier("premium") then ultSec:Toggle({ Name = "Rika Love Sword", Callback = function(b) if RikaSwordApi then RikaSwordApi.set(b) end end }) end   -- FREE: no auto Rika sword
    ultSec:Toggle({ Name = "Goku M1", Callback = function(b) if GokuApi then GokuApi.set(b) end end })
    ultSec:Toggle({ Name = "Goku Dodge", Callback = function(b) if GokuApi then GokuApi.setDodge(b) end end })   -- blink L/R when a nearby enemy M1s
    ultSec:Label("Goku M1: it might work, if it dont i will fix it later 😭")
    ultSec:Toggle({ Name = "Hollow Nuke", Callback = function(b) if HollowApi then HollowApi.set(b) end end })

    -- ═══ LOCK TARGET ═══ Click an enemy and EVERY combat feature (BF modes, dashes, auto air, crow)
    -- acts on that one character until you click them again to release. Not a camera lock.
    do
        local lockSub = CombatPage:SubPage({ Name = "Lock Target", Columns = 2 })
        local lkSec = lockSub:Section({ Name = "Lock Target", Side = 1 })
        pcall(function() lkSec:Label("Turn on, then CLICK an enemy. It STAYS locked - in-game clicks never change it. Turn this toggle off to clear. Used by the Black Flash chains + dashes.") end)
        lkSec:Toggle({ Name = "Lock Target (click an enemy)", Default = false, Callback = function(b) if _G.VX_LOCK and _G.VX_LOCK.manual then _G.VX_LOCK.manual(b) end end })
        lkSec:Dropdown({ Name = "Lock Color", Items = { "Red", "Cyan", "Green", "Purple", "Orange", "White", "Yellow", "Pink", "Blue", "Lime", "Black", "Gold", "Teal", "Magenta" }, Default = "Red", Callback = function(c)
            c = (type(c) == "table") and c[1] or c
            local map = { Red = Color3.fromRGB(255, 46, 58), Cyan = Color3.fromRGB(0, 225, 255), Green = Color3.fromRGB(70, 225, 90),
                Purple = Color3.fromRGB(180, 90, 255), Orange = Color3.fromRGB(255, 150, 40), White = Color3.fromRGB(255, 255, 255),
                Yellow = Color3.fromRGB(255, 235, 60), Pink = Color3.fromRGB(255, 120, 200), Blue = Color3.fromRGB(60, 120, 255),
                Lime = Color3.fromRGB(160, 255, 60), Black = Color3.fromRGB(10, 10, 12), Gold = Color3.fromRGB(255, 200, 70),
                Teal = Color3.fromRGB(0, 200, 180), Magenta = Color3.fromRGB(255, 60, 220) }
            if _G.VX_LOCK and _G.VX_LOCK.setColor and map[c] then _G.VX_LOCK.setColor(map[c]) end
        end })
    end
    local defSub = CombatPage:SubPage({ Name = "Defense", Columns = 2 })
    local counterSec = defSub:Section({ Name = "Counter", Side = 1 })
    -- Side/Back Dash Assist now use the reworked VXBF2 engine (Q = side curve, E = back-through). Free gets both.
    if tier("premium") then   -- FREE: no Side/Back Dash Assist (premium only)
        counterSec:Toggle({ Name = "Side Dash Assist (Q)", Callback = function(b) if _G.VXBF2 then _G.VXBF2.setSideAssist(b) end end })
        counterSec:Toggle({ Name = "Back Dash Assist (E)", Callback = function(b) if _G.VXBF2 then _G.VXBF2.setBackAssist(b) end end })
    end
    counterSec:Toggle({ Name = "Anti Counter", Callback = function(b) if AntiCounterApi then AntiCounterApi.set(b) end end })
    if tier("premium") then   -- FREE: no Emote / Jump-On-Head counter reactions (Anti Counter keeps its default)
        counterSec:Dropdown({ Name = "On Counter", Items = { "Jump On Head", "Emote" }, Default = "Jump On Head", Callback = function(v) if AntiCounterApi then AntiCounterApi.setMode(v) end end })
        counterSec:Dropdown({ Name = "Emote #", Items = { "1", "2", "3", "4", "5", "6", "7", "8" }, Default = "1", Callback = function(v) if AntiCounterApi then AntiCounterApi.setEmote(v) end end })
    end
    local antiSec = defSub:Section({ Name = "Anti / Adapt", Side = 2 })
    antiSec:Toggle({ Name = "Anti-Stun", Callback = function(b) if AntiStunApi then AntiStunApi.set(b) end end })
    antiSec:Toggle({ Name = "Anti-Ragdoll", Callback = function(b) if AntiRagdollApi then AntiRagdollApi.set(b) end end })
    antiSec:Toggle({ Name = "Anti-Domain", Callback = function(b) if AntiDomainApi then AntiDomainApi.set(b) end end })
    antiSec:Dropdown({ Name = "Domain React", Items = { "Safe Teleport", "To User + Hit" }, Default = "Safe Teleport", Callback = function(v) if AntiDomainApi then AntiDomainApi.setMode(v) end end })
    antiSec:Toggle({ Name = "Anti Black Hole", Callback = function(b) if AntiBlackHoleApi then AntiBlackHoleApi.set(b) end end })
    antiSec:Toggle({ Name = "Auto Mahito Grab Escape", Callback = function(b) if MahitoGrabApi then MahitoGrabApi.set(b) end end })
    antiSec:Toggle({ Name = "Mahoraga Safe TP", Callback = function(b) if MahoTpApi then MahoTpApi.set(b) end end })

    -- ===================== AUTO (all the automation toggles in one tab) =====================
    local AutoPage = Window:Page({ Name = "Auto", Icon = "bot" })
    local autoSub = AutoPage:SubPage({ Name = "Auto", Columns = 2 })
    local acSec = autoSub:Section({ Name = "Auto Combat", Side = 1 })
    acSec:Toggle({ Name = "Auto Counter", Callback = function(b) if CounterApi then CounterApi.set(b) end end })
    acSec:Toggle({ Name = "Locked Only", Callback = function(b) if CounterApi then CounterApi.setLockedOnly(b) end end })
    if tier("premium") then   -- FREE: no Auto Evasive
        acSec:Toggle({ Name = "Auto Evasive", Callback = function(b) if EvasiveApi then EvasiveApi.set(b) end end })
        acSec:Dropdown({ Name = "Evasive Dir", Items = { "Cycle", "Back", "Left", "Right", "Toward Target" }, Default = "Cycle", Callback = function(v) if EvasiveApi then EvasiveApi.setDir(v) end end })
    end
    acSec:Toggle({ Name = "Auto Yuta Black Flash", Default = false, Callback = function(b) if YutaBFApi then YutaBFApi.setAuto(b) end end })
    acSec:Toggle({ Name = "Auto Ult", Callback = function(b) if AutoUltApi then AutoUltApi.set(b) end end })
    if tier("premium") then
        acSec:Toggle({ Name = "Auto Air", Callback = function(b) if AutoAirApi_set then AutoAirApi_set(b) end end })   -- FREE: Auto Air removed (premium only)
        -- OFF by default: the enemy-presence gate was the reason Auto Air kept doing nothing. Turn it on only if
        -- you find sequences firing when you did not want them to.
        _G.VX_AIR_NEEDENEMY = false
        acSec:Toggle({ Name = "Auto Air: need enemy nearby", Default = false, Callback = function(b) _G.VX_AIR_NEEDENEMY = (b == true) end })
        -- (TEST buttons removed per request - the diagnostics live on in the APIs: M1ComboApi.testUp/testDown/testStatus, AutoAirApi_test("One").)
        -- Pick which characters Auto Air runs for. Each needs the master toggle above ON as well.
        pcall(function() acSec:Label("Auto Air - pick which ones run:") end)
        for _, o in ipairs({
            { "Vessel",    "Vessel (1 -> Cursed Strikes, jump -> 1)" },
            { "Twofold",   "Gojo Twofold Kick (R after 2nd kick)" },
            { "LapseBlue", "Gojo Lapse Blue (1 -> R)" },
            { "LapseRed",  "Gojo Lapse Blue -> Reversal Red" },
            { "Megumi",    "Megumi (2 -> Nue+R, R -> Rabbit+1)" },
            { "Hakari",    "Hakari (3 -> jump + Rough Energy)" },
            { "Choso",     "Choso (2 -> jump + Flowing Red Scale)" },
            { "Locust",    "Locust (3 -> Crushing Jaws, R on fly-up)" },
        }) do
            acSec:Toggle({ Name = o[2], Default = true, Callback = function(b) if AutoAirOptSet then AutoAirOptSet(o[1], b) end end })
        end
    end
    acSec:Dropdown({ Name = "Auto Slam / Uppercut", Items = { "Off", "Down Slam", "Uppercut" }, Default = "Off", Callback = function(m) if M1ComboApi then M1ComboApi.setMode(m) end end })
    -- "Slam / Uppercut on M1 #" dropdown REMOVED - it is automatic now (see the note in onSwing).
    -- (Removed the "Launcher after N hits" slider — the mechanic is now the FIXED real game rule per the wiki:
    -- Uppercut = 4 M1s with Space held, Down Slam = 3 M1s then jump+M1. No slider needed or accurate anymore.)
    pcall(function() acSec:Label("Uppercut soon: Crow, Mangaka, Black Death, Disaster Plants") end)
    if tier("premium") then acSec:Toggle({ Name = "Auto Adapt", Callback = function(b) if AutoAdaptApi then AutoAdaptApi.set(b) end end }) end   -- FREE: no Auto Adapt (Auto Domain Adapt below is kept)
    acSec:Toggle({ Name = "Auto Domain Adapt", Callback = function(b) if AutoDomainAdaptApi then AutoDomainAdaptApi.set(b) end end })
    acSec:Toggle({ Name = "Auto Earthquake", Callback = function(b) if AutoQuakeApi then AutoQuakeApi.set(b) end end })
    if _G.JJS_FREE then pcall(function() acSec:Label("Earthquake: turn on, then press 3 — it is held for you") end) end
    acSec:Slider({ Name = "Quake Hold", Min = 0.3, Max = 3, Default = 2, Decimals = 0.01, Suffix = "s", Callback = function(v) _G.VX_QUAKE_HOLD = tonumber(v) or 2 end })
    acSec:Toggle({ Name = "Quake Debug (print)", Default = false, Callback = function(b) _G.VX_QUAKE_DEBUG = (b == true) end })   -- prints one line per tap so you can confirm the hold + whether the windup was seen
    if not _G.JJS_FREE then acSec:Slider({ Name = "Quake Range", Min = 15, Max = 150, Default = 60, Decimals = 1, Suffix = "st", Callback = function(v) _G.VX_QUAKE_RANGE = tonumber(v) or 60 end }) end
    acSec:Toggle({ Name = "Auto Kill Emote", Callback = function(b) if KillEmoteApi then KillEmoteApi.set(b) end end })
    local keItems = {}   -- slot list with REAL emote names read from PlayerGui.Emotes.Emote.Page1/Page2 (the 'nan' slider is gone)
    for i = 1, 16 do
        local nm
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui"); local em = pg and pg:FindFirstChild("Emotes"); em = em and em:FindFirstChild("Emote")
            for _, page in ipairs({ "Page1", "Page2" }) do
                local p = em and em:FindFirstChild(page); local b = p and p:FindFirstChild(tostring(i)); local t = b and b:FindFirstChild("EmoteName")
                if t and t:IsA("TextLabel") and t.Text ~= "" and t.Text ~= "EmoteName" then nm = t.Text end
            end
        end)
        keItems[i] = nm and (i .. " - " .. nm) or tostring(i)
    end
    acSec:Dropdown({ Name = "Kill-Emote Slot", Items = keItems, Default = keItems[1], Callback = function(v)
        local n = tonumber(tostring(v):match("^%d+")); if KillEmoteApi and n then KillEmoteApi.setSlot(n) end
    end })
    local askSec = autoSub:Section({ Name = "Auto Skills", Side = 2 })
    askSec:Toggle({ Name = "Auto Skills", Callback = function(b) if SkillsApi then SkillsApi.setEnabled(b) end end })
    askSec:Toggle({ Name = "Skill 1", Callback = function(b) if SkillsApi then SkillsApi.setKey(1, b) end end })
    askSec:Toggle({ Name = "Skill 2", Callback = function(b) if SkillsApi then SkillsApi.setKey(2, b) end end })
    askSec:Toggle({ Name = "Skill 3", Callback = function(b) if SkillsApi then SkillsApi.setKey(3, b) end end })
    askSec:Toggle({ Name = "Skill 4", Callback = function(b) if SkillsApi then SkillsApi.setKey(4, b) end end })
    askSec:Toggle({ Name = "Special R", Callback = function(b) if SkillsApi then SkillsApi.setKey(5, b) end end })
    askSec:Toggle({ Name = "Awakening G", Callback = function(b) if SkillsApi then SkillsApi.setKey(6, b) end end })
    local auSec = autoSub:Section({ Name = "Auto Utility", Side = 2 })
    auSec:Toggle({ Name = "Auto Parkour", Callback = function(b) if ParkourApi then ParkourApi.set(b) end end })
    auSec:Toggle({ Name = "Auto QTE Click (Higuruma Final Judgment)", Callback = function(b) if AutoQTEApi then AutoQTEApi.set(b) end end })
    auSec:Dropdown({ Name = "QTE Answer", Items = { "Silence", "Denial", "Confess" }, Default = "Silence", Callback = function(v) if AutoQTEApi then AutoQTEApi.setChoice(v) end end })
    auSec:Slider({ Name = "Click Delay", Min = 0, Max = 100, Default = 0, Decimals = 1, Callback = function(v) if AutoQTEApi then AutoQTEApi.setDelay(v) end end })
    auSec:Slider({ Name = "QTE Speed (presses/sec)", Min = 5, Max = 120, Default = 45, Decimals = 1, Callback = function(v) if AutoQTEApi then AutoQTEApi.setSpeed(v) end end })
    auSec:Slider({ Name = "QTE Click Gap (ms)", Min = 0, Max = 100, Default = 20, Decimals = 1, Callback = function(v) if AutoQTEApi then AutoQTEApi.setTapGap(v) end end })
    auSec:Toggle({ Name = "Anti Final Judgment", Callback = function(b) if AutoQTEApi_setAnti then AutoQTEApi_setAnti(b) end end })
    auSec:Toggle({ Name = "Auto Grab", Callback = function(b) if ItemsApi then ItemsApi.setGrab(b) end end })
    local grabDD = auSec:Dropdown({ Name = "Grab Filter", Items = ((ItemsApi and ItemsApi.names()) or { "Any" }), Default = "Any", Callback = function(v) if ItemsApi then ItemsApi.setFilter(v) end end })
    auSec:Button({ Name = "Refresh Items", Callback = function() if grabDD and ItemsApi then grabDD:Refresh(ItemsApi.names()) end end })
    task.spawn(function()   -- keep the item list current: refresh with the REAL items on the map every 10s
        while true do task.wait(10); pcall(function() if grabDD and ItemsApi then grabDD:Refresh(ItemsApi.names()) end end) end
    end)
    pcall(function() auSec:Label("🏗️ Auto Farm: In fixing + kind of works (teleport)") end)
    auSec:Toggle({ Name = "Auto Farm", Callback = function(b) if FarmApi then FarmApi.set(b) end end })
    auSec:Dropdown({ Name = "Farm Target", Items = playerList(), Default = "Nearest", Callback = function(v) if FarmApi then FarmApi.setTarget((type(v) == "table") and v[1] or v) end end })   -- unwrap: a table here made the farm loop error out and stay dead until re-execute
    auSec:Toggle({ Name = "Auto Train", Callback = function(b) if TrainApi then TrainApi.setAuto(b) end end })

    -- ===================== TARGET (type a username -> act on that player) =====================
    local TargetPage = Window:Page({ Name = "Target", Icon = "crosshair" })
    local tgSub = TargetPage:SubPage({ Name = "Target", Columns = 2 })
    local tSec = tgSub:Section({ Name = "Target", Side = 1 })
    pcall(function() tSec:Label("Teleports (fixed: real speed, no phantom detour, correct body) (teleports)") end)
    -- IN-GUI info panel (user: "show it inside the gui"): one line per stat, all live-updating.
    local nameL, hpL, ultL, killL   -- fwd (textbox callback below refreshes them)
    local function liveInfo()
        if not (TargetApi and nameL) then return end
        local i = TargetApi.info()
        if i and i.found then
            pcall(function() nameL:SetText("Player:  " .. i.name) end)
            pcall(function() hpL:SetText("Health:  " .. i.health .. " / " .. i.maxHealth) end)
            pcall(function() ultL:SetText("Ult:  " .. (i.ult and "USED" or "no")) end)
            pcall(function() killL:SetText("Kills:  " .. tostring(TargetApi.kills() or "?")) end)
        else
            pcall(function() nameL:SetText("Player:  no match yet") end)
            pcall(function() hpL:SetText("Health:  N/A") end)
            pcall(function() ultL:SetText("Ult:  N/A") end)
            pcall(function() killL:SetText("Kills:  N/A") end)
        end
    end
    tSec:Textbox({ Name = "Player Name", Placeholder = "Type a username here", Default = "", Flag = "VX_TargetName", Callback = function(v) if TargetApi then TargetApi.setName(v); liveInfo() end end })
    -- THE TEXTBOX CALLBACK DOESN'T FIRE on this UI lib (it only fires on Enter/focus-lost, not as you type),
    -- so we POLL the live TextBox and push its value every 0.3s = info updates as you type. The active library
    -- (Fluriore) does NOT carry our placeholder onto the real TextBox, so matching by placeholder found nothing
    -- (= "info stays N/A"). Instead: match a box whose placeholder/nearby title says username/player, and if none
    -- match, fall back to the ONLY input box in the menu (the Fluriore build has just this one).
    task.spawn(function()
        local host = (gethui and gethui()) or game:GetService("CoreGui")
        local last = nil
        local function findBox()
            local match, only, count = nil, nil, 0
            for _, g in ipairs(host:GetDescendants()) do
                if g:IsA("TextBox") then
                    count = count + 1; only = g
                    local ph = string.lower(g.PlaceholderText or "")
                    if string.find(ph, "username", 1, true) or string.find(ph, "player name", 1, true) or string.find(ph, "type a name", 1, true) then
                        return g
                    end
                    local par = g.Parent
                    for _ = 1, 3 do
                        if not par then break end
                        for _, s in ipairs(par:GetChildren()) do
                            if s:IsA("TextLabel") then
                                local t = string.lower(s.Text or "")
                                if string.find(t, "player name", 1, true) or string.find(t, "username", 1, true) then match = g end
                            end
                        end
                        par = par.Parent
                    end
                end
            end
            if match then return match end
            if count == 1 then return only end   -- Fluriore build: the ONLY input box is the target one
            return nil
        end
        while true do
            task.wait(0.3)
            pcall(function()
                local box = findBox()
                if box then
                    local v = box.Text
                    if v ~= last then last = v; if TargetApi then TargetApi.setName(v); liveInfo() end end
                end
            end)
        end
    end)
    tSec:Label("Type a name above — their full profile pops up top-right.")
    tSec:Toggle({ Name = "View User (spectate)", Callback = function(b) if TargetApi then TargetApi.setView(b) end end })
    local tActSec = tgSub:Section({ Name = "Actions", Side = 2 })
    tActSec:Button({ Name = "Teleport To User", Callback = function() if TargetApi then TargetApi.tpTo() end end })
    tActSec:Toggle({ Name = "Auto Farm User", Callback = function(b) if TargetApi then TargetApi.setFarm(b) end end })
    local bringFilter = "Any"
    local bringDD = tActSec:Dropdown({ Name = "Item To Bring", Items = ((ItemsApi and ItemsApi.names()) or { "Any" }), Default = "Any", Callback = function(v) bringFilter = (type(v) == "table") and v[1] or v end })
    task.spawn(function() while true do task.wait(10); pcall(function() if bringDD and ItemsApi then bringDD:Refresh(ItemsApi.names()) end end) end end)
    tActSec:Button({ Name = "Bring Item To User", Callback = function() if TargetApi then TargetApi.bringItem(bringFilter) end end })
    tActSec:Button({ Name = "Throw Trash At User", Callback = function() if TargetApi then TargetApi.throwTrash() end end })
    -- keep the readout fresh while the tab's open (live HP/ult; the Check buttons still force a full refresh)
    task.spawn(function() while true do task.wait(0.6); pcall(function() if _G.VX_HUB_READY then liveInfo() end end) end end)

    -- ===================== MOVEMENT =====================
    local MovePage = Window:Page({ Name = "Movement", Icon = "footprints" })
    local mvSub = MovePage:SubPage({ Name = "Movement", Columns = 2 })
    local coreSec = mvSub:Section({ Name = "Core", Side = 1 })
    coreSec:Toggle({ Name = "Remove Trees", Callback = function(b) if RemoveTreesApi then RemoveTreesApi.set(b) end end })
    coreSec:Toggle({ Name = "Infinite Jump", Callback = function(b) if InfJumpApi then InfJumpApi.set(b) end end })
    -- (Dash Forward / Invisible / Desync Freeze removed per request — modules stay in code, no UI)
    if tier("plus") then
        coreSec:Toggle({ Name = "No Dash CD", Callback = function(b) if DashApi then DashApi.setNoCd(b) end end })
    end
    local spdSec = mvSub:Section({ Name = "Speed & Fly", Side = 2 })
    spdSec:Toggle({ Name = "Speed Hack", Callback = function(b) if SpeedApi then SpeedApi.set(b) end end })
    spdSec:Slider({ Name = "Walk Speed", Min = 20, Max = 200, Default = 70, Decimals = 1, Callback = function(v) if SpeedApi then SpeedApi.setSpeed(v) end end })
    spdSec:Toggle({ Name = "Fly", Callback = function(b) if FlyApi then FlyApi.set(b) end end })
    spdSec:Slider({ Name = "Fly Speed", Min = 20, Max = 250, Default = 80, Decimals = 1, Callback = function(v) if FlyApi then FlyApi.setSpeed(v) end end })

    -- ===================== VISUALS =====================
    local VisPage = Window:Page({ Name = "Visuals", Icon = "eye" })
    local visSub = VisPage:SubPage({ Name = "Visuals", Columns = 2 })
    local espSec = visSub:Section({ Name = "Player ESP", Side = 1 })
    espSec:Toggle({ Name = "Enable ESP", Callback = function(b) if PlayerEspApi then PlayerEspApi.setMaster(b) end end })
    espSec:Toggle({ Name = "Chams", Default = true, Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("chams", b) end end })
    espSec:Toggle({ Name = "2D Box", Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("box", b) end end })
    espSec:Toggle({ Name = "Tracers", Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("tracers", b) end end })
    espSec:Slider({ Name = "Tracer Size", Min = 1, Max = 6, Default = 2, Decimals = 1, Callback = function(v) if PlayerEspApi then PlayerEspApi.setThick(v) end end })
    espSec:Dropdown({ Name = "ESP Color", Items = { "Red", "Cyan", "Green", "Purple", "Orange", "White" }, Default = "Red", Callback = function(c)
        local map = { Red = Color3.fromRGB(255, 46, 58), Cyan = Color3.fromRGB(0, 225, 255), Green = Color3.fromRGB(70, 225, 90), Purple = Color3.fromRGB(180, 90, 255), Orange = Color3.fromRGB(255, 150, 40), White = Color3.fromRGB(255, 255, 255) }
        if PlayerEspApi and map[c] then PlayerEspApi.setColor(map[c]) end
    end })
    espSec:Toggle({ Name = "Names", Default = true, Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("name", b) end end })
    espSec:Toggle({ Name = "Health", Default = true, Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("health", b) end end })
    espSec:Toggle({ Name = "Distance", Default = true, Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("distance", b) end end })
    -- ("Character" ESP row removed per request.)
    -- ("Move / Skill" ESP row removed per request.)
    espSec:Toggle({ Name = "Cooldowns", Callback = function(b) if PlayerEspApi then PlayerEspApi.setOpt("cooldowns", b) end end })
    local itemSec = visSub:Section({ Name = "Items", Side = 2 })
    itemSec:Toggle({ Name = "Item ESP", Callback = function(b) if ItemsApi then ItemsApi.setESP(b) end end })
    local worldSec = visSub:Section({ Name = "World", Side = 2 })
    worldSec:Toggle({ Name = "Fullbright", Callback = function(b) if VisualApi then VisualApi.setFullbright(b) end end })
    worldSec:Toggle({ Name = "No Fog", Callback = function(b) if VisualApi then VisualApi.setNoFog(b) end end })
    worldSec:Slider({ Name = "FOV", Min = 40, Max = 120, Default = 70, Decimals = 1, Callback = function(v) if VisualApi then VisualApi.setFov(v) end end })

    -- ===================== TELEPORTS =====================
    local TpPage = Window:Page({ Name = "Teleports", Icon = "navigation" })
    local tpSub = TpPage:SubPage({ Name = "Teleports", Columns = 2 })
    local locSec = tpSub:Section({ Name = "Locations", Side = 1 })
    pcall(function() locSec:Label("Teleports (fixed: real speed, no phantom detour, correct body)") end)
    if TPApi and TPApi.spotNames then for _, n in ipairs(TPApi.spotNames()) do locSec:Button({ Name = n, Callback = function() if TPApi then TPApi.spot(n) end end }) end end
    local quickSec = tpSub:Section({ Name = "Quick", Side = 2 })
    -- These two API functions existed but nothing ever called them, so "Instant" was unreachable and the flight
    -- speed was permanently pinned at 100 studs/s. Now they are wired up.
    quickSec:Dropdown({ Name = "TP Method", Items = { "Instant", "Anchor", "Auto", "Glide" }, Default = "Instant", Callback = function(v) if TPApi then TPApi.setMethod(v) end end })
    quickSec:Slider({ Name = "TP Speed (Glide)", Min = 30, Max = 200, Default = 90, Decimals = 1, Suffix = "st/s", Callback = function(v) _G.VX_TP_VEL = tonumber(v) or 90 end })   -- range matches the clamp; 90 is a believable dash, 260 read as ~16x walk speed and got reverted
    -- Destroying AntiCheatService.RE.Teleport is now the DEFAULT, because that is what made teleport work in
    -- testing. This toggle puts it back only if you ever want the old behaviour.
    quickSec:Toggle({ Name = "Keep AC Teleport remote", Default = false, Callback = function(b)
        _G.VX_KEEP_AC_TP = b and true or nil
        if _G.VX_DESTROY_AC then pcall(_G.VX_DESTROY_AC) end   -- re-run the sweep so the change takes effect now
    end })
    quickSec:Button({ Name = "Print TP Remote", Callback = function()
        local RS = game:GetService("ReplicatedStorage"); local found = 0
        for _, d in ipairs(RS:GetDescendants()) do
            if d:IsA("RemoteEvent") and string.find(string.lower(d.Name), "teleport") then print("[DreamHub TP] remote:", d:GetFullName()); found = found + 1 end
        end
        if found == 0 then print("[DreamHub TP] no 'Teleport' RemoteEvent found in ReplicatedStorage - send me this") end
        local k = RS:FindFirstChild("Knit"); k = k and k:FindFirstChild("Knit"); k = k and k:FindFirstChild("Services"); local s = k and k:FindFirstChild("AntiCheatService"); local re = s and s:FindFirstChild("RE"); re = re and re:FindFirstChild("Teleport")
        print("[DreamHub TP] whitelist path AntiCheatService.RE.Teleport present:", re ~= nil)
    end })
    quickSec:Button({ Name = "Up", Callback = function() if TPApi then TPApi.up() end end })
    quickSec:Button({ Name = "Spawn", Callback = function() if TPApi then TPApi.spawn() end end })
    quickSec:Button({ Name = "Nearest", Callback = function() if TPApi then TPApi.nearest() end end })
    quickSec:Button({ Name = "Save Slot 1", Callback = function() if TPApi then TPApi.save(1) end end })
    quickSec:Button({ Name = "Go Slot 1", Callback = function() if TPApi then TPApi.goto_(1) end end })
    quickSec:Button({ Name = "Save Slot 2", Callback = function() if TPApi then TPApi.save(2) end end })
    quickSec:Button({ Name = "Go Slot 2", Callback = function() if TPApi then TPApi.goto_(2) end end })
    quickSec:Button({ Name = "Save Slot 3", Callback = function() if TPApi then TPApi.save(3) end end })
    quickSec:Button({ Name = "Go Slot 3", Callback = function() if TPApi then TPApi.goto_(3) end end })
    local plySec = tpSub:Section({ Name = "Players", Side = 1 })
    local tpPlyName
    local plyDrop = plySec:Dropdown({ Name = "Player", Items = (TPApi and TPApi.playerNames and TPApi.playerNames()) or {}, Callback = function(v) tpPlyName = (type(v) == "table") and v[1] or v end })   -- unwrap: the UI hands back a table, so this used to store a table and the button did nothing
    plySec:Button({ Name = "Refresh Players", Callback = function() if plyDrop and TPApi then pcall(function() plyDrop:Refresh(TPApi.playerNames()) end) end end })
    plySec:Button({ Name = "Teleport To Player", Callback = function() if TPApi and tpPlyName then TPApi.tpPlayer(tpPlyName) end end })

    -- ===================== PLAYER =====================
    local PlyPage = Window:Page({ Name = "Player", Icon = "user" })   -- clean target/crosshair icon (old one looked AI-slop)
    local plySub = PlyPage:SubPage({ Name = "Player", Columns = 2 })
    local lockSec = plySub:Section({ Name = "Lock On", Side = 1 })
    local lockMode = "Off"
    lockSec:Dropdown({ Name = "Lock Mode", Items = { "Off", "Camera", "Character", "Both" }, Default = "Off", Callback = function(m) lockMode = (type(m) == "table") and m[1] or m; if LockOnApi then LockOnApi.setMode(lockMode) end end })
    lockSec:Toggle({ Name = "Reticle", Default = true, Callback = function(b) if LockOnApi then LockOnApi.setReticle(b) end end })
    lockSec:Slider({ Name = "Smooth", Min = 0.05, Max = 1, Default = 0.4, Decimals = 0.01, Callback = function(v) if LockOnApi then LockOnApi.setSmooth(v) end end })
    -- LOCK-ON KEYBIND: tap the key to flip lock-on off/on without opening the menu. Uses your last non-Off mode.
    local lockKeyName, lockKeyOn, lastLockMode = "T", false, "Camera"
    lockSec:Dropdown({ Name = "Lock-On Key", Items = { "T", "Y", "X", "Z", "V", "B" }, Default = "T", Callback = function(v) lockKeyName = (type(v) == "table") and v[1] or v end })
    task.spawn(function()
        local UIS_L = game:GetService("UserInputService")
        UIS_L.InputBegan:Connect(function(input, _)
            if UIS_L:GetFocusedTextBox() then return end
            if input.KeyCode ~= Enum.KeyCode[lockKeyName] then return end
            if lockMode ~= "Off" then lastLockMode = lockMode end
            lockKeyOn = not lockKeyOn
            local newMode = lockKeyOn and (lastLockMode or "Camera") or "Off"
            lockMode = newMode
            if LockOnApi then LockOnApi.setMode(newMode) end
            if VX_NOTIFY then VX_NOTIFY("Lock-On " .. (lockKeyOn and ("ON (" .. newMode .. ")") or "OFF"), lockKeyOn) end
        end)
    end)
    local jhTarget = "Nearest"
    local jhSec = plySub:Section({ Name = "Jump On Head", Side = 1 })
    jhSec:Dropdown({ Name = "Target", Items = playerList(), Default = "Nearest", Callback = function(v) jhTarget = v end })
    jhSec:Button({ Name = "Jump On Head", Callback = function() if JumpHeadApi then JumpHeadApi.jump(jhTarget) end end })
    local farmSec = plySub:Section({ Name = "Farm & Train", Side = 2 })
    farmSec:Button({ Name = "Spawn Train", Callback = function() if TrainApi then TrainApi.spawn() end end })
    farmSec:Toggle({ Name = "Anti-AFK", Default = true, Callback = function(b) if AntiAfkApi then AntiAfkApi.set(b) end end })
    farmSec:Toggle({ Name = "Drink Low HP", Callback = function(b) if DrinkApi then DrinkApi.set(b) end end })
    farmSec:Slider({ Name = "Drink %", Min = 10, Max = 90, Default = 35, Decimals = 1, Suffix = "%", Callback = function(v) if DrinkApi then DrinkApi.setThreshold(v) end end })
    farmSec:Toggle({ Name = "Walk Into Domains", Callback = function(b) if WalkDomainApi then WalkDomainApi.set(b) end end })
    farmSec:Toggle({ Name = "Spam Dash Noises", Callback = function(b) if DashNoiseApi then DashNoiseApi.set(b) end end })
    local srvSec = plySub:Section({ Name = "Server", Side = 2 })
    srvSec:Button({ Name = "Rejoin Server", Callback = function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end) end })
    srvSec:Button({ Name = "Server Hop", Callback = function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end) end })
    srvSec:Button({ Name = "Copy Discord", Callback = function() if setclipboard then pcall(function() setclipboard("https://discord.gg/fRcGd9bW") end) end if VX_NOTIFY then VX_NOTIFY("Discord copied", true) end end })
    srvSec:Button({ Name = "Force Reset", Callback = function() if ResetApi then ResetApi.reset() end end })
    srvSec:Button({ Name = "Respawn Now", Callback = function() if InstaRespawnApi then InstaRespawnApi.now() end end })   -- button, not a toggle (user: kills+respawns you on demand)
    srvSec:Toggle({ Name = "Show Notifications (off by default)", Default = false, Callback = function(b) _G.VX_SILENT = (b ~= true) end })   -- user asked: NO toasts. Silent unless you opt back in; F9 console prints stay for debugging.
    srvSec:Button({ Name = "Unlock Extra Emote Slot", Callback = function() if EmoteSlotApi then EmoteSlotApi.unlock() end end })

    -- ===================== SETTINGS (keybinds + theme) =====================
    local SettingsPage = Window:Page({ Name = "Settings", Icon = "settings" })
    local setSub = SettingsPage:SubPage({ Name = "Settings", Columns = 2 })
    local kbSec = setSub:Section({ Name = "Keybinds", Side = 1 })
    local kbEnabled = false
    kbSec:Toggle({ Name = "Enable Keybinds", Default = false, Callback = function(b) kbEnabled = (b == true) end })
    kbSec:Label("Y = Auto Lock (toggle)")
    do
        local UISkb = game:GetService("UserInputService")
        local lockOn = false
        UISkb.InputBegan:Connect(function(i, _)
            if not kbEnabled then return end
            if UISkb:GetFocusedTextBox() then return end
            if i.KeyCode == Enum.KeyCode.Y then
                lockOn = not lockOn
                pcall(function() if LockOnApi then LockOnApi.setMode(lockOn and "Both" or "Off") end end)
                if VX_NOTIFY then VX_NOTIFY("Auto Lock " .. (lockOn and "ON" or "OFF")) end
            end
        end)
    end
    local thSec = setSub:Section({ Name = "Theme", Side = 2 })
    do
        local COLORS = { Red = Color3.fromRGB(220,30,40), Blue = Color3.fromRGB(45,120,255), Green = Color3.fromRGB(50,200,110), Purple = Color3.fromRGB(150,70,255), Orange = Color3.fromRGB(255,140,40), Pink = Color3.fromRGB(255,80,170), White = Color3.fromRGB(240,240,245) }
        local curAccent = COLORS.Red
        local function near(a, b) return (math.abs(a.R-b.R) + math.abs(a.G-b.G) + math.abs(a.B-b.B)) < 0.45 end   -- catches both red shades (255,45,45 and 220,30,40)
        local function applyAccent(newC)
            local hosts = {}
            pcall(function() if gethui then hosts[#hosts+1] = gethui() end end)
            pcall(function() hosts[#hosts+1] = game:GetService("CoreGui") end)
            pcall(function() hosts[#hosts+1] = LP:FindFirstChildOfClass("PlayerGui") end)
            local ours = {}
            for _, h in ipairs(hosts) do pcall(function()   -- only OUR ScreenGuis, never the game's UI
                for _, sg in ipairs(h:GetChildren()) do
                    local n = sg.Name
                    if sg:IsA("ScreenGui") and (n == "HirimiGui" or n == "\0" or n:sub(1, 5) == "Dream" or n:sub(1, 3) == "VX_") then ours[#ours+1] = sg end
                end
            end) end
            for _, h in ipairs(ours) do pcall(function()
                for _, d in ipairs(h:GetDescendants()) do pcall(function()
                    if d:IsA("UIStroke") and near(d.Color, curAccent) then d.Color = newC
                    elseif (d:IsA("Frame") or d:IsA("TextButton")) and d.BackgroundTransparency < 1 and near(d.BackgroundColor3, curAccent) then d.BackgroundColor3 = newC
                    elseif d:IsA("TextLabel") and near(d.TextColor3, curAccent) then d.TextColor3 = newC
                    elseif d:IsA("ImageLabel") and near(d.ImageColor3, curAccent) then d.ImageColor3 = newC
                    elseif d:IsA("UIGradient") then local ok = pcall(function() end) end
                end) end
            end) end
            curAccent = newC; _G.VX_ACCENT = newC
        end
        thSec:Dropdown({ Name = "Accent Color", Items = { "Red", "Blue", "Green", "Purple", "Orange", "Pink", "White" }, Default = "Red", Callback = function(v)
            v = (type(v) == "table") and v[1] or v
            applyAccent(COLORS[v] or COLORS.Red)
        end })
        thSec:Label("Changes the red accent across the whole menu.")
    end
    local miscSec = setSub:Section({ Name = "Misc", Side = 1 })
    miscSec:Toggle({ Name = "Show Notifications", Default = false, Callback = function(b) _G.VX_SILENT = (b ~= true) end })
    miscSec:Button({ Name = "Rejoin Server", Callback = function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end) end })
    miscSec:Button({ Name = "Copy Discord", Callback = function() if setclipboard then pcall(setclipboard, "https://discord.gg/fRcGd9bW") end; if VX_NOTIFY then VX_NOTIFY("Discord copied") end end })
    miscSec:Label("Menu: RightShift (or the on-screen button on mobile)")

    -- CUSTOMIZE: background color / background image / font / text color — all live re-paints of the menu.
    do
        local function isOurGui(sg)   -- ONLY the hub's own ScreenGuis — NEVER the game's UI (repainting the game's
            if not sg:IsA("ScreenGui") then return false end   -- top bar was the yellow overlapping text bug)
            local n = sg.Name
            return n == "HirimiGui" or n == "\0" or n:sub(1, 5) == "Dream" or n:sub(1, 3) == "VX_"
        end
        local function eachMenuEl(fn)   -- every element of OUR menu GUIs, pcall-safe
            local hosts = {}
            pcall(function() if gethui then hosts[#hosts+1] = gethui() end end)
            pcall(function() hosts[#hosts+1] = game:GetService("CoreGui") end)
            pcall(function() hosts[#hosts+1] = LP:FindFirstChildOfClass("PlayerGui") end)
            for _, h in ipairs(hosts) do pcall(function()
                for _, sg in ipairs(h:GetChildren()) do
                    if isOurGui(sg) then for _, d in ipairs(sg:GetDescendants()) do pcall(fn, d) end end
                end
            end) end
        end
        -- BACKGROUND COLOR: repaint every dark panel, keeping the light/dark hierarchy (each shade scales
        -- from the chosen base color, so windows stay darker than elements).
        local BG = { Black = Color3.fromRGB(10,10,10), ["Dark Red"] = Color3.fromRGB(28,8,10), ["Dark Blue"] = Color3.fromRGB(8,12,32), ["Dark Green"] = Color3.fromRGB(8,24,14), ["Dark Purple"] = Color3.fromRGB(20,8,32), Grey = Color3.fromRGB(24,24,28) }
        thSec:Dropdown({ Name = "Background Color", Items = { "Black", "Dark Red", "Dark Blue", "Dark Green", "Dark Purple", "Grey" }, Default = "Black", Callback = function(v)
            v = (type(v) == "table") and v[1] or v
            local base = BG[v] or BG.Black
            eachMenuEl(function(d)
                if (d:IsA("Frame") or d:IsA("ScrollingFrame") or d:IsA("TextButton")) and d.BackgroundTransparency < 1 then
                    local c = d.BackgroundColor3
                    local b = math.max(c.R, c.G, c.B)
                    if b <= 0.22 then   -- only the dark panels; accent/colored elements untouched
                        local k = math.clamp(b / 0.0392, 0.8, 2.8)
                        d.BackgroundColor3 = Color3.new(math.min(base.R * k, 1), math.min(base.G * k, 1), math.min(base.B * k, 1))
                    end
                end
            end)
        end })
        -- BACKGROUND IMAGE: paste a Roblox image/decal id -> it loads behind the whole menu window.
        local bgImgs = {}
        thSec:Textbox({ Name = "Background Image ID", Default = "", Callback = function(txt)
            local id = tostring(txt or ""):match("%d+")
            for _, im in ipairs(bgImgs) do pcall(function() im:Destroy() end) end
            bgImgs = {}
            if not id then return end
            local roots = {}
            eachMenuEl(function(d)   -- the big window frames (>300px wide) are the menu roots
                if d:IsA("Frame") and d.Visible and d.AbsoluteSize.X > 300 and d.AbsoluteSize.Y > 200 and d.BackgroundTransparency < 1 then roots[#roots+1] = d end
            end)
            table.sort(roots, function(a, b) return a.AbsoluteSize.X * a.AbsoluteSize.Y > b.AbsoluteSize.X * b.AbsoluteSize.Y end)
            local root = roots[1]
            if not root then if VX_NOTIFY then VX_NOTIFY("Open the menu first, then set the image") end return end
            local im = Instance.new("ImageLabel")
            im.Name = "\0"; im.BackgroundTransparency = 1; im.Size = UDim2.fromScale(1, 1)
            im.Image = "rbxassetid://" .. id; im.ScaleType = Enum.ScaleType.Crop; im.ImageTransparency = 0.45
            im.ZIndex = root.ZIndex; im.Parent = root
            pcall(function() local c = root:FindFirstChildOfClass("UICorner"); if c then Instance.new("UICorner", im).CornerRadius = c.CornerRadius end end)
            bgImgs[#bgImgs+1] = im
            -- decal ids don't render directly in ImageLabels; the thumb endpoint renders both decals and images
            task.delay(1.5, function() pcall(function() if im.Parent and not im.IsLoaded then im.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420" end end) end)
        end })
        -- TEXT: font + color, applied to every label/button in the menu.
        local FONTS = { ["Gotham"] = Enum.Font.Gotham, ["Gotham Bold"] = Enum.Font.GothamBold, ["Code"] = Enum.Font.Code, ["Arial"] = Enum.Font.Arial, ["Ubuntu"] = Enum.Font.Ubuntu, ["SciFi"] = Enum.Font.SciFi, ["Cartoon"] = Enum.Font.Cartoon }
        thSec:Dropdown({ Name = "Text Font", Items = { "Gotham", "Gotham Bold", "Code", "Arial", "Ubuntu", "SciFi", "Cartoon" }, Default = "Gotham", Callback = function(v)
            v = (type(v) == "table") and v[1] or v
            local f = FONTS[v] or Enum.Font.Gotham
            eachMenuEl(function(d) if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then d.Font = f end end)
        end })
        local TXT = { White = Color3.fromRGB(240,240,245), Red = Color3.fromRGB(255,70,80), Blue = Color3.fromRGB(90,160,255), Green = Color3.fromRGB(90,230,140), Yellow = Color3.fromRGB(250,220,90), Pink = Color3.fromRGB(255,120,190), Purple = Color3.fromRGB(180,120,255) }
        local curTxt = nil
        thSec:Dropdown({ Name = "Text Color", Items = { "White", "Red", "Blue", "Green", "Yellow", "Pink", "Purple" }, Default = "White", Callback = function(v)
            v = (type(v) == "table") and v[1] or v
            local c = TXT[v] or TXT.White
            eachMenuEl(function(d)
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    local t = d.TextColor3
                    -- repaint the readable text: whatever is bright/near-white, or whatever we painted last time
                    if math.min(t.R, t.G, t.B) > 0.5 or (curTxt and (math.abs(t.R-curTxt.R)+math.abs(t.G-curTxt.G)+math.abs(t.B-curTxt.B)) < 0.1) then d.TextColor3 = c end
                end
            end)
            curTxt = c
        end })
        -- SOUND: a click/sfx whenever you press anything in the menu. Pick the sound, or paste any Roblox sound id.
        do
            local SS = game:GetService("SoundService")
            -- Each sound = a LIST of candidate ids. On pick we test them in order and keep the first that
            -- actually loads (audio gets deleted/region-blocked all the time; one dead id must not mean silence).
            local SOUNDS = {   -- name -> { ids = {...}, vol, speed, maxSeconds (nil = play out) }
                ["Keyboard (Basic)"] = { ids = { "rbxassetid://7147420522", "rbxassetid://6895079853" }, vol = 0.6, speed = 1 },
                ["Goku Scream"]      = { ids = { "rbxassetid://6157432689", "rbxassetid://4972273967", "rbxassetid://130976109" }, vol = 0.5, speed = 1, cut = 1.6 },
                ["Jesus Rising"]     = { ids = { "rbxassetid://104307285983733", "rbxassetid://271069318" }, vol = 0.5, speed = 1, cut = 1.6 },
                ["67"]               = { ids = { "rbxassetid://117816189937562", "rbxassetid://82773030886915" }, vol = 0.5, speed = 1, cut = 1.6 },
                ["Money"]            = { ids = { "rbxassetid://7112275565", "rbxassetid://131886985" }, vol = 0.6, speed = 1, cut = 1.6 },
            }
            local cur, curName = SOUNDS["Keyboard (Basic)"], "Keyboard (Basic)"
            local snd, playGen = nil, 0
            local function ensureSnd()
                if snd and snd.Parent then return snd end
                snd = Instance.new("Sound"); snd.Name = "\0"; snd.Parent = SS
                return snd
            end
            local function resolveId(entry, name)   -- test the candidates; cache the winner in entry.good
                if entry.good then return entry.good end
                local s = ensureSnd()
                for _, id in ipairs(entry.ids) do
                    local ok = pcall(function() s.SoundId = id end)
                    if ok then
                        local t0 = tick()
                        while tick() - t0 < 1.2 and not s.IsLoaded do task.wait(0.1) end
                        if s.IsLoaded and s.TimeLength > 0 then entry.good = id; return id end
                    end
                end
                if VX_NOTIFY then VX_NOTIFY(name .. " audio ids are all dead - paste one in Custom Sound ID") end
                entry.good = "rbxasset://sounds/electronicpingshort.wav"   -- always make SOME noise
                return entry.good
            end
            local function playClick()
                playGen = playGen + 1; local gen = playGen
                task.spawn(function()
                    local id = resolveId(cur, curName)
                    if gen ~= playGen then return end   -- a newer click superseded this one while we resolved
                    local s = ensureSnd()
                    pcall(function()
                        if s.SoundId ~= id then s.SoundId = id end
                        s.Volume = cur.vol; s.PlaybackSpeed = cur.speed; s.TimePosition = 0; s:Play()
                    end)
                    if cur.cut then   -- SHORT clip: cut the long memes off (a newer click restarts them)
                        task.delay(cur.cut, function() pcall(function() if playGen == gen and s.IsPlaying then s:Stop() end end) end)
                    end
                end)
            end
            local hookedBtn = setmetatable({}, { __mode = "k" })
            local function hookButtons()
                eachMenuEl(function(d)
                    if (d:IsA("TextButton") or d:IsA("ImageButton")) and not hookedBtn[d] then
                        hookedBtn[d] = d.Activated:Connect(function()
                            if not _G.VX_UISOUND then return end
                            playClick()
                        end)
                    end
                end)
            end
            miscSec:Toggle({ Name = "Sound", Default = false, Callback = function(b)
                _G.VX_UISOUND = (b == true)
                if b then task.spawn(function() while _G.VX_UISOUND do pcall(hookButtons); task.wait(2) end end) end
            end })
            miscSec:Dropdown({ Name = "Click Sound", Items = { "Keyboard (Basic)", "Goku Scream", "Jesus Rising", "67", "Money" }, Default = "Keyboard (Basic)", Callback = function(v)
                v = (type(v) == "table") and v[1] or v
                cur = SOUNDS[v] or SOUNDS["Keyboard (Basic)"]; curName = v
                playClick()   -- instant preview (also resolves + reports a dead id right away)
            end })
            miscSec:Textbox({ Name = "Custom Sound ID", Default = "", Callback = function(txt)
                local id = tostring(txt or ""):match("%d+")
                if id then cur = { ids = { "rbxassetid://" .. id }, vol = 0.6, speed = 1, cut = 2 }; curName = "Custom"; playClick() end
            end })
        end
    end

    Window:Category("Config")
    Library:CreateSettingsPage(Window)

    if _G.VX_SILENT == nil then _G.VX_SILENT = true end   -- SILENT BY DEFAULT (user: "remove notifications") — every toast in the hub goes through VX_NOTIFY, so this one flag kills them all; F9 prints are untouched
    VX_NOTIFY = function(t) if _G.VX_SILENT then return end pcall(function() Library:Notification(tostring(t), 4) end) end   -- 'Show Notifications' re-enables; this is the single choke point
    if getgenv then getgenv().Library = Library end

    -- ═══ ADMIN PAGE (whitelisted user only) ═══
    do
        local ADM = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
        local me = Players.LocalPlayer
        if ADM[string.lower(me.Name)] or ADM[string.lower(me.DisplayName or "")] then
            local sel
            local function names() local t={ me.Name.."  (you)" } for _,pl in ipairs(Players:GetPlayers()) do if pl~=me then t[#t+1]=pl.Name end end return t end
            local function targ() if not sel then return nil end local nm=tostring(sel):gsub("%s+%(you%)$",""); return Players:FindFirstChild(nm) end
            local function spectate(pl) local cam=workspace.CurrentCamera; local c=pl.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); if cam and h then cam.CameraSubject=h; return true end local pt=c and c:FindFirstChildWhichIsA("BasePart"); if cam and pt then cam.CameraSubject=pt; return true end return false end
            local function toast(m) if VX_NOTIFY then VX_NOTIFY(m) end end
            local function sendChat(txt) local ok=false
                pcall(function() local TCS=game:GetService("TextChatService"); local order={}; local tc=TCS:FindFirstChild("TextChannels"); if tc then local g=tc:FindFirstChild("RBXGeneral"); if g then order[#order+1]=g end end; for _,d in ipairs(TCS:GetDescendants()) do if d:IsA("TextChannel") and d~=order[1] then order[#order+1]=d end end; for _,ch in ipairs(order) do local sent=pcall(function() ch:SendAsync(txt) end); if sent then ok=true break end end end)
                if not ok then pcall(function() local ev=game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents"); local say=ev and ev:FindFirstChild("SayMessageRequest"); if say then say:FireServer(txt,"All"); ok=true end end) end
                return ok end
            local warnMsg="Follow the rules or you'll be removed."
            local AdminPage = Window:Page({ Name = "Admin", Icon = "user" })
            local aSub = AdminPage:SubPage({ Name = "Admin", Columns = 2 })
            local aSec = aSub:Section({ Name = "Load User", Side = 1 })
            local dd = aSec:Dropdown({ Name = "Load User", Items = names(), Default = "", Callback = function(v) sel = (type(v)=="table" and v[1]) or v end })
            aSec:Button({ Name = "Refresh Players", Callback = function() pcall(function() if dd and dd.SetItems then dd:SetItems(names()) elseif dd and dd.Refresh then dd:Refresh(names()) end end) end })
            pcall(function() aSec:Label("Send Warn pops a standard warning on their screen. Custom message: type  ?warn username your text  in the live chat.") end)
            local aAct = aSub:Section({ Name = "Actions", Side = 2 })
            aAct:Button({ Name = "Send Warn", Callback = function() local p=targ(); if not p then toast("Load a user first.") return end if _G.__DreamWarnSend then _G.__DreamWarnSend(p.Name, warnMsg); toast("Warning sent to "..p.Name.." (popup on their screen if they run Dream Hub).") else toast("Warn relay not ready yet - try again in a few seconds.") end end })
            aAct:Button({ Name = "Teleport To User", Callback = function() local p=targ(); if not p then toast("Load a user first.") return end
                local okg=false; pcall(function() local mc=me.Character; local mr=mc and (mc:FindFirstChild("HumanoidRootPart") or mc.PrimaryPart or mc:FindFirstChildWhichIsA("BasePart")); local tc=p.Character; local tr=tc and (tc:FindFirstChild("HumanoidRootPart") or tc.PrimaryPart or tc:FindFirstChildWhichIsA("BasePart")); if mr and tr then mr.CFrame=tr.CFrame*CFrame.new(0,0,-4); okg=true end end)
                if not okg and TargetApi then pcall(function() TargetApi.setName(p.Name) end); pcall(function() TargetApi.tpTo() end) end
                toast("Teleporting to "..p.Name) end })
            aAct:Button({ Name = "View Player", Callback = function() local p=targ(); if not p then toast("Load a user first.") return end toast(spectate(p) and ("Viewing "..p.Name) or "They aren't loaded in.") end })
            aAct:Button({ Name = "Stop Viewing", Callback = function() local cam=workspace.CurrentCamera; local mc=me.Character; local h=mc and mc:FindFirstChildOfClass("Humanoid"); if cam then pcall(function() cam.CameraSubject=h end) end toast("Camera back on you.") end })
            aAct:Toggle({ Name = "Fly", Callback = function(b) if FlyApi then pcall(function() FlyApi.set(b) end) end end })
            aAct:Button({ Name = "Copy Username", Callback = function() local p=targ(); if not p then toast("Load a user first.") return end pcall(function() setclipboard(p.Name) end) toast("Copied @"..p.Name) end })
            aAct:Button({ Name = "Copy UserId", Callback = function() local p=targ(); if not p then toast("Load a user first.") return end pcall(function() setclipboard(tostring(p.UserId)) end) toast("Copied "..p.UserId) end })
            local reason,proof="",""
            aAct:Textbox({ Name = "Put reason here", Placeholder = "what they did", Default = "", Callback = function(v) reason = v or "" end })
            aAct:Textbox({ Name = "Proof image link", Placeholder = "https://... (imgur/gyazo)", Default = "", Callback = function(v) proof = v or "" end })
            aAct:Button({ Name = "Send Report to Discord", Callback = function()
                local p=targ(); if not p then toast("Load a user first.") return end
                if #tostring(reason):gsub("%s","")<2 then toast("Type a reason first.") return end
                local hook=("https://discord.com/api/webhooks/1527860474488688732/".."ObBmSPJv0jp9nZHbIoJryLOPrsuyQsTr".."tuwVVwdQ0c759WQa6X0g0j-G4n-VCH-CMH7a")
                local req=(typeof(syn)=="table" and syn.request) or http_request or (typeof(fluxus)=="table" and fluxus.request) or request
                if not req then toast("No http on this executor.") return end
                task.spawn(function() local okc=false pcall(function() local emb={title="Player Reported",color=14689068,fields={{name="Target",value=p.DisplayName.." (@"..p.Name..")  ["..tostring(p.UserId).."]",inline=false},{name="Profile",value="https://www.roblox.com/users/"..p.UserId.."/profile",inline=false},{name="Reason",value=string.sub(tostring(reason),1,1500),inline=false},{name="Reported by",value=me.Name,inline=false}}}; local pf=tostring(proof); if #pf:gsub("%s","")>4 then table.insert(emb.fields,{name="Proof",value=string.sub(pf,1,400),inline=false}); if pf:match("^https?://%S+%.png") or pf:match("^https?://%S+%.jpg") or pf:match("^https?://%S+%.jpeg") or pf:match("^https?://%S+%.gif") then emb.image={url=pf} end end local FUNNY={"https://dev.plasmii.vip/folk-images/FyileRBHGM.png","https://dev.plasmii.vip/folk-images/7iHoNdXEZx.png","https://dev.plasmii.vip/folk-images/e7OU2vjjwy.png","https://dev.plasmii.vip/folk-images/zRugC3azOS.png","https://dev.plasmii.vip/folk-images/PdNAVfd1Xs.png","https://dev.plasmii.vip/folk-images/Gooning_folk.png","https://dev.plasmii.vip/folk-images/bvFh6jNwfg.png","https://dev.plasmii.vip/folk-images/3DpT2iqGIf.png","https://dev.plasmii.vip/folk-images/0p4BngFJ14.png","https://dev.plasmii.vip/folk-images/Fa8WC5QRLO.png","https://dev.plasmii.vip/folk-images/Gooner_folk.png","https://dev.plasmii.vip/folk-images/V1Lk4YW2hB.png","https://dev.plasmii.vip/folk-images/5qdmyDpxVm.png","https://dev.plasmii.vip/folk-images/folk.png","https://dev.plasmii.vip/folk-images/BmgbC2AbEY.png","https://dev.plasmii.vip/folk-images/Test.png"} local funpick=FUNNY[math.random(#FUNNY)] if emb.image then emb.thumbnail={url=funpick} else emb.image={url=funpick} end local body=game:GetService("HttpService"):JSONEncode({username="Dream Mod",embeds={emb}}) local res=req({Url=hook,Method="POST",Headers={["Content-Type"]="application/json"},Body=body}); if res and ((res.StatusCode and res.StatusCode>=200 and res.StatusCode<300) or res.Success) then okc=true end if not okc then local res2=req({Url=(hook:gsub("^https://discord%.com","https://webhook.lewisakura.moe")),Method="POST",Headers={["Content-Type"]="application/json"},Body=body}) if res2 and ((res2.StatusCode and res2.StatusCode>=200 and res2.StatusCode<300) or res2.Success) then okc=true end end end) toast(okc and ("Reported "..p.Name..".") or "Send failed.") end)
            end })
        end
    end

    do
        local RulesPage = Window:Page({ Name = "Rules", Icon = "settings" })
        local rSub = RulesPage:SubPage({ Name = "Rules", Columns = 1 })
        local rSec = rSub:Section({ Name = "Community Rules", Side = 1 })
        pcall(function() rSec:Label("Break a rule and the action beside it applies. Staff decisions are final; appeal in the Discord.") end)
        pcall(function() rSec:Label("1.  No harassment, bullying, or targeting other players.   ->   Kick  (repeat = Ban)") end)
        pcall(function() rSec:Label("2.  No slurs, hate speech, racism, or discrimination.   ->   Instant Ban") end)
        pcall(function() rSec:Label("3.  No NSFW, gore, or inappropriate content of any kind.   ->   Instant Ban") end)
        pcall(function() rSec:Label("4.  No threats, doxxing, or sharing anyone's personal info.   ->   Instant Ban") end)
        pcall(function() rSec:Label("5.  No scamming, fake trades, or fake giveaways.   ->   Ban") end)
        pcall(function() rSec:Label("6.  Do not impersonate Dream Hub staff or other users.   ->   Kick") end)
        pcall(function() rSec:Label("7.  No advertising other hubs, servers, scripts, or discords.   ->   Warn -> Kick") end)
        pcall(function() rSec:Label("8.  No leaking, cracking, or reselling paid Dream Hub scripts.   ->   Ban") end)
        pcall(function() rSec:Label("9.  No spamming chat, sounds, tags, or requests.   ->   Warn -> Kick") end)
        pcall(function() rSec:Label("10.  Don't use bugs/glitches to grief or ruin others' games.   ->   Kick") end)
        pcall(function() rSec:Label("11.  No intentionally lagging, freezing, or crashing servers.   ->   Kick -> Ban") end)
        pcall(function() rSec:Label("12.  No evading a punishment with alt accounts.   ->   Ban all alts") end)
        pcall(function() rSec:Label("13.  Don't beg for admin, roles, or free premium.   ->   Warn") end)
        pcall(function() rSec:Label("14.  Respect staff decisions - appeal calmly in the Discord.   ->   Warn") end)
        pcall(function() rSec:Label("15.  Don't abuse the report system with false/joke reports.   ->   Warn -> Kick") end)
    end

    _G.VX_HUB_READY = true   -- tells the loading screen the GUI is built -> it fades out and reveals the hub
pcall(function() if _G.__DreamFinishLoad then _G.__DreamFinishLoad() end end)

    pcall(function() Library:Notification("Dream Hub " .. string.upper(VX_TIER) .. " loaded", 4) end)
    print("[Vaultix v" .. VX_VERSION .. " | samet UI] loaded (" .. VX_TIER .. ") - RightShift toggle")
end

-- ============================================================
-- MODULE: AUTO BLOCK ENGINE  (friend's engine, verbatim; its own GUI removed,
-- the 4 toggles are wired into the Vaultix GUI above via the shared BlockFlags table)
-- ============================================================
do
-- ==========================================
-- ROBLOX SERVICES INITIALIZATION
-- Fetching essential game services required for core mechanics, physics, and UI rendering.
-- ==========================================
local Players = game:GetService("Players") -- Manages all players in the server.
local RunService = game:GetService("RunService") -- Provides frame-by-frame execution (RenderStepped) for zero-latency hitboxes.
local Workspace = game:GetService("Workspace") -- Handles 3D world interactions, Raycasting, and spatial queries.
local Lighting = game:GetService("Lighting") -- Used here to detect global visual changes, such as Domain Expansions.
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Stores client-server communication channels (RemoteEvents).
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- LOCAL PLAYER ENVIRONMENT
-- ==========================================
local LocalPlayer = Players.LocalPlayer -- The client running this script.
local Camera = Workspace.CurrentCamera -- The local viewport, manipulated for the 'Camera Follow' feature.

-- ==========================================
-- MAIN CONFIGURATION MODULE
-- Controls the script's behavior, timings, and remote event pathways.
-- ==========================================
local Config = {
    -- The grace period (in seconds) to hold the block after a threat passes.
    -- 0.34: hold the shield THROUGH fast M1 strings AND dash-cancel mixups (0.26 still dropped between some
    -- strings and the re-raise came back a frame late = you ate the next M1).
    ComboDelay = 0.46,   -- HOLD LONGER. 0.34 dropped the shield between hits of a combo string, so the 2nd/3rd M1 of a rush landed clean. 0.46 rides the whole string and still releases fast enough to act between engagements.
    
    -- Feature toggles linked to the Vaultix Hub UI checkboxes.
    Blocks = BlockFlags,
    
    -- Specific network pathways to the game's server for movement and combat.
    Remotes = {
        BlockActivate = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("BlockService"):WaitForChild("RE"):WaitForChild("Activated"),
        BlockDeactivate = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("BlockService"):WaitForChild("RE"):WaitForChild("Deactivated"),
        Dash = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MovementService"):WaitForChild("RE"):WaitForChild("Dash")
    }
}

-- ==========================================
-- COMBAT STATE VARIABLES
-- These variables track the real-time defensive status of the local player.
-- ==========================================
local isBlocking = false -- Boolean flag determining if the server has been told to raise the shield.
local comboDropTime = 0 -- The exact tick() timestamp when the shield should be lowered.
local currentThreatInstance = nil -- Stores the specific enemy Character model triggering the defense.
local lastBlockedInstance = nil -- Remembers the last targeted enemy to prevent spamming redundant RemoteEvents.
local lastBlockedThreatName = "" -- Stores the string name of the attack for debugging purposes.

-- ==========================================
-- MEMORY CACHE & ENEMY TRACKING TABLES
-- Utilized to maintain high FPS by preventing redundant Workspace scans.
-- ==========================================
local ActiveThreatTracks = {} -- Stores currently playing animations from enemies that pose a threat.
local CharacterConnections = {} -- Maps a character to their active RBXScriptConnections (used to prevent memory leaks).
local MonitoredEnemies = {} -- Keeps track of which enemies currently have hooks attached to them.
local NearbyEnemies = {} -- An optimized list of enemies within a 150-stud radius, updated every 0.2 seconds.

local CachedProjectiles = {} -- Stores active projectiles/effects in the workspace (Zero-Lag lookup).
local CachedDomains = {} -- Stores active Domain Expansions.

-- ==========================================
-- SPECIFIC SKILL LOCKS & TIMERS
-- Custom logic variables to handle specific, rule-breaking attacks.
-- ==========================================
local reverseBallLock = false -- Hard lock for Hakari's Reverse Balls.
local reverseBallLockTime = 0 -- Timestamp to forcibly drop the Reverse Ball lock if the projectile fails to spawn.
local spikeWrathLock = nil -- Holds the Mahito character instance while Spike Wrath is casting continuously.
local rabbitCaster = nil -- Remembers which Megumi casted Rabbit Escape to track the summoner instead of the rabbit part.
local myDomainEndTime = 0 -- Timestamp predicting when the LocalPlayer's Domain Expansion ends (grants immunity).
local myCasts = {} -- Stores the LocalPlayer's own attacks to prevent the script from blocking its own projectiles.
local naoyaDecisiveCount = {} -- Tracks how many times Naoya has teleported during 'Decisive Strike'.
local mechaCannonTimers = {} -- Timestamp tracking the charge-up phase of Granite Blast / Ultracannon.

-- A helper function to check if the script should perform any threat analysis.
local function IsAnyBlockActive()
    return Config.Blocks.Dash or Config.Blocks.M1 or Config.Blocks.Abilities
end

-- ==========================================
-- EFFECTS CACHE MANAGER (ZERO LAG OPTIMIZATION)
-- Instead of iterating through thousands of parts per frame, this system 
-- simply "listens" for specific parts entering/leaving the game and catalogs them.
-- ==========================================
local PartToSkillMap = {
    ["Doors"] = "Shutter Doors", ["Reverse"] = "Reverse Balls", ["RedExplode"] = "Reversal Red", 
    ["LapseBlue"] = "Lapse Blue", ["RoughEnergy"] = "Rough Energy", ["Nue"] = "Nue", 
    ["TongueGrab"] = "Toad", ["Rabbit"] = "Rabbit Escape", ["Totality"] = "Divine Dog",
    ["PebbleProjectile"] = "Pebble Throw", ["GavelThrow"] = "Gavel Throw",
    ["Ball"] = "Garuda Rebound", ["ArmProjectile"] = "Detach", ["Swarm"] = "Roach Swarm",
    ["ToadNue"] = "Toad/ToadNue", ["NueToad"] = "Toad/ToadNue"
}

-- Checks if an incoming 3D Object matches any known deadly projectiles.
local function IsTrackableProjectile(name)
    if PartToSkillMap[name] then return true end
    if name == "Rika" or name == "Crow" or name == "Bullet" or name == "Supernova" then return true end
    if string.find(name, "Rabbit") then return true end
    return false
end

-- Fires whenever a new effect spawns in the Workspace.
local function OnProjectileAdded(child)
    if IsTrackableProjectile(child.Name) then
        CachedProjectiles[child] = true -- Add to high-speed lookup cache
    end
end

-- Fires whenever an effect is destroyed, cleaning up memory.
local function OnProjectileRemoved(child)
    CachedProjectiles[child] = nil
end

-- Establish event listeners for projectile folders
local EffectsFolder = Workspace:WaitForChild("Effects")
EffectsFolder.ChildAdded:Connect(OnProjectileAdded)
EffectsFolder.ChildRemoved:Connect(OnProjectileRemoved)
for _, child in ipairs(EffectsFolder:GetChildren()) do OnProjectileAdded(child) end

local BulletsFolder = Workspace:FindFirstChild("Bullets")
if BulletsFolder then
    BulletsFolder.ChildAdded:Connect(OnProjectileAdded)
    BulletsFolder.ChildRemoved:Connect(OnProjectileRemoved)
    for _, child in ipairs(BulletsFolder:GetChildren()) do OnProjectileAdded(child) end
end

-- Establish event listeners for Domain Expansions
local DomainsFolder = Workspace:WaitForChild("Domains")
local CharactersFolder = Workspace:WaitForChild("Characters")
DomainsFolder.ChildAdded:Connect(function(child)
    if child.Name == "Domain" and child:IsA("MeshPart") then CachedDomains[child] = true end
end)
DomainsFolder.ChildRemoved:Connect(function(child) CachedDomains[child] = nil end)
for _, child in ipairs(DomainsFolder:GetChildren()) do
    if child.Name == "Domain" and child:IsA("MeshPart") then CachedDomains[child] = true end
end

-- ==========================================
-- ENEMY TRACKING & MEMORY MANAGEMENT
-- ==========================================

-- Removes all event listeners tied to an enemy when they die or leave the 150-stud radius.
-- Essential for avoiding memory leaks and frame drops in long gaming sessions.
local function CleanupEnemy(char)
    if CharacterConnections[char] then
        for _, conn in ipairs(CharacterConnections[char]) do conn:Disconnect() end
        CharacterConnections[char] = nil
    end
    naoyaDecisiveCount[char] = nil
    mechaCannonTimers[char] = nil
    MonitoredEnemies[char] = nil
end

-- Hooks into an enemy's core components to monitor their actions globally.
local function SetupEnemy(char)
    if char == LocalPlayer.Character then return end
    if MonitoredEnemies[char] then return end
    
    MonitoredEnemies[char] = true
    CharacterConnections[char] = {}

    -- Track changes in the enemy's Moveset StringValue (crucial for adaptive defenses)
    local info = char:WaitForChild("Info", 5)
    if info then
        local moveset = info:FindFirstChild("Moveset")
        if moveset then
            char:SetAttribute("CachedMoveset", moveset.Value)
            local conn = moveset:GetPropertyChangedSignal("Value"):Connect(function()
                char:SetAttribute("CachedMoveset", moveset.Value)
            end)
            table.insert(CharacterConnections[char], conn)
        end
    end

    -- Hook into the enemy's Animation Controller to detect attacks frame 1
    local humanoid = char:WaitForChild("Humanoid", 5)
    local animator = humanoid and humanoid:WaitForChild("Animator", 5)
    if animator then
        local conn = animator.AnimationPlayed:Connect(function(track)
            if _G.OnAnimationPlayed then _G.OnAnimationPlayed(char, track) end
        end)
        table.insert(CharacterConnections[char], conn)
    end
    
    -- HOOK: Choso's Convergence (Dynamic Unblockable Piercing Blood logic)
    task.spawn(function()
        local setAssets = char:WaitForChild("SetAssets", 5)
        if setAssets and CharacterConnections[char] then
            local function hookConvergence(conv)
                if conv.Name == "Convergence" then
                    -- Detects when Choso consumes a Blood attachment
                    local conn = conv.ChildRemoved:Connect(function(child)
                        if string.match(child.Name, "Blood") then
                            -- Flags the enemy as firing an unblockable beam
                            char:SetAttribute("PiercingUnblockable", true)
                            
                            -- Instantly wipe the active Piercing Blood threat from memory to force the shield down
                            local i = #ActiveThreatTracks
                            while i >= 1 do
                                if ActiveThreatTracks[i].Char == char and ActiveThreatTracks[i].Data.Name == "Piercing Blood" then
                                    table.remove(ActiveThreatTracks, i)
                                end
                                i = i - 1
                            end
                            
                            -- Wait exactly 8 seconds to safely reset the unblockable status
                            task.delay(8, function()
                                if char then char:SetAttribute("PiercingUnblockable", false) end
                            end)
                        end
                    end)
                    table.insert(CharacterConnections[char], conn)
                end
            end
            
            for _, child in ipairs(setAssets:GetChildren()) do hookConvergence(child) end
            local connAsset = setAssets.ChildAdded:Connect(hookConvergence)
            table.insert(CharacterConnections[char], connAsset)
        end
    end)
end

-- Optimized Global Scan Routine (Strictly Lua 5.1 Compatible / No "continue" syntax)
-- Scans the map every 0.2s and caches enemies within 150 studs. 
task.spawn(function()
    while true do
        -- ═══ LAG ═══ This was `while task.wait(0.05)`, i.e. it woke 20 times a second FOREVER just to test a
        -- boolean, even with every block toggle off. Now it idles at 0.5s when off and scans at 0.12s when on -
        -- still comfortably ahead of a rushing enemy's first M1, at a quarter of the wakeups.
        if not IsAnyBlockActive() then task.wait(0.5) else task.wait(0.12) end
        local selfChar = CharactersFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character  -- JJS live body is under workspace.Characters (LP.Character can lag)
        if IsAnyBlockActive() and selfChar then
            local myHRP = selfChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local tempCache = {}
                for _, char in ipairs(CharactersFolder:GetChildren()) do
                    if char ~= selfChar and char ~= LocalPlayer.Character and char.Name ~= LocalPlayer.Name then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            -- Spatial filtering: Only track enemies that are close enough to be a threat
                            if dist <= 150 then
                                table.insert(tempCache, char)
                                if not MonitoredEnemies[char] then task.spawn(SetupEnemy, char) end  -- non-blocking: a rig missing Info/Humanoid must not stall the whole scan thread (WaitForChild 5s x2)
                            else
                                -- Garbage collection: Enemy left the area, unhook them to save CPU cycles
                                if MonitoredEnemies[char] then CleanupEnemy(char) end
                            end
                        end
                    end
                end
                NearbyEnemies = tempCache -- Update the fast-read table used by RenderStepped
            end
        end
    end
end)

CharactersFolder.ChildRemoved:Connect(CleanupEnemy)

-- ==========================================
-- ANIMATION DICTIONARY (THE THREAT DATABASE)
-- Maps specific Animation IDs to logic templates (Required Distance, Angle, Category).
-- ==========================================
local AnimDict = {
    -- NEW GLOBAL MELEES
    ["95981277479213"]  = {Name = "Global Melee 1", Category = "Melee", ReqDot = 0.50},
    ["134438232117051"] = {Name = "Global Melee 2", Category = "Melee", ReqDot = 0.50},
    ["83712266760883"]  = {Name = "Global Melee 3", Category = "Melee", ReqDot = 0.50},
    ["117871121041895"] = {Name = "Global Melee 4", Category = "Melee", ReqDot = 0.50},
    -- NEW GLOBAL DASHES
    ["86430725083594"]  = {Name = "Global Dash New", Category = "DashRule"},
    -- HAKARI
    ["94588892125071"]  = {Name = "Hakari M1 1", Category = "Melee", ReqDot = 0.50},
    ["97868312130612"]  = {Name = "Hakari M1 2", Category = "Melee", ReqDot = 0.50},
    ["140588454098230"] = {Name = "Hakari M1 3", Category = "Melee", ReqDot = 0.50},
    ["138826758216894"] = {Name = "Hakari M1 4", Category = "Melee", ReqDot = 0.50},
    ["82541714192027"]  = {Name = "Reverse Balls", Category = "ReverseRule", ReqDot = 0.90, ReqDist = 65.0},
    ["72063002791216"]  = {Name = "Shutter Doors", Category = "Skill", ReqDot = 0.85, ReqDist = 11.0},
    ["72467492674240"]  = {Name = "Rough Energy", Category = "Skill", GroundIsUnblockable = true, ReqDot = 0.80, ReqDist = 14.8},
    ["108123475959041"] = {Name = "Fever Breaker", Category = "Skill", ReqDot = 0.85, ReqDist = 13.0},  
    ["95901746347992"]  = {Name = "Lucky Volley", Category = "Melee", ReqDot = 0.70},
    -- GOJO
    ["137865634124104"] = {Name = "Lapse Blue", Category = "Target", ReqDot = 0.85, ReqDist = 36.6},
    ["137654778575373"] = {Name = "Reversal Red", Category = "Target", ReqDot = 0.85, ReqDist = 45.0},
    ["95421145178968"]  = {Name = "Rapid Punches", Category = "Unblockable"},
    ["104749346956269"] = {Name = "Twofold Kick", Category = "Skill", ReqDot = 0.85, ReqDist = 10.0},
    ["127851700400958"] = {Name = "Gojo/MahitoArmor/Todo M1/M4", Category = "Melee", ReqDot = 0.50},
    ["72548435296350"]  = {Name = "Gojo Melee 2", Category = "Melee", ReqDot = 0.50},
    ["84547415708554"]  = {Name = "Gojo Melee 3", Category = "Melee", ReqDot = 0.50},
    -- ITADORI
    ["77200218033775"]  = {Name = "Cursed Strike", Category = "Rush", AirIsUnblockable = true, ReqDot = 0.80, ReqDist = 30.0},
    ["124901309160375"] = {Name = "Crushing Blow", Category = "Rush", GroundIsUnblockable = true, ReqDot = 0.85, ReqDist = 30.0},
    ["131506102901134"] = {Name = "Dismantle", Category = "Target", ReqDot = 0.70, ReqDist = 27.0},
    ["100962226150441"] = {Name = "Divergent Fist", Category = "Rush", ReqDot = 0.85, ReqDist = 19.0},
    ["121984128639453"] = {Name = "Malevolent Shrine", Category = "DomainCast"},
    ["95295463826732"]  = {Name = "Itadori M1 1", Category = "Melee", ReqDot = 0.50},
    ["105077924973072"] = {Name = "Ita/Ryu/Cho M1 2", Category = "Melee", ReqDot = 0.50},
    ["124862357369335"] = {Name = "Itadori M1 3", Category = "Melee", ReqDot = 0.50},
    ["81630213087988"]  = {Name = "Itadori M1 4", Category = "Melee", ReqDot = 0.55},
    ["110146909061402"] = {Name = "Itadori Ult M1 1", Category = "Melee", ReqDot = 0.60, ReqDist = 20.0},
    ["123414935051274"] = {Name = "Itadori Ult M1 2", Category = "Melee", ReqDot = 0.60, ReqDist = 20.0},
    ["108636011034323"] = {Name = "Itadori Ult M1 3", Category = "Melee", ReqDot = 0.60, ReqDist = 20.0},
    ["105376952884290"] = {Name = "Itadori Ult M1 4", Category = "Melee", ReqDot = 0.60, ReqDist = 20.0},
    -- MEGUMI / MAHORAGA / TOTALITY
    ["132653290201368"] = {Name = "Rabbit Escape", Category = "Target", ReqDot = 0.90, ReqDist = 36.6},
    ["116432619539029"] = {Name = "Toad/ToadNue", Category = "Target", ReqDot = 0.90, ReqDist = 36.6},
    ["81112033595734"]  = {Name = "Divine Dog", Category = "Target", ReqDot = 0.85, ReqDist = 10.0},
    ["85024950165903"]  = {Name = "Earthquake", Category = "Target", ReqDot = 0.35, ReqDist = 12.0},
    ["109718372214725"] = {Name = "Megumi/Maho M1 1", Category = "Melee", ReqDot = 0.55},
    ["121800365664070"] = {Name = "Megumi/Maho M1 2", Category = "Melee", ReqDot = 0.55},
    ["96513213736303"]  = {Name = "Megumi/Maho M1 3", Category = "Melee", ReqDot = 0.55},
    ["79037514387169"]  = {Name = "Megumi/Maho M1 4", Category = "Melee", ReqDot = 0.55},
    ["75337033003776"]  = {Name = "Megumi/Maho M1 5", Category = "Melee", ReqDot = 0.55},
    ["138489871864252"] = {Name = "Megumi/Maho M1 6", Category = "Melee", ReqDot = 0.55},
    ["96185406489877"]  = {Name = "Megumi/Maho M1 7", Category = "Melee", ReqDot = 0.55},
    ["105287938257399"] = {Name = "Megumi/Maho M1 8", Category = "Melee", ReqDot = 0.55},
    ["81688837573130"]  = {Name = "Totality Attack 1", Category = "Melee", ReqDot = 0.55, ReqDist = 30.0},
    ["95250225969869"]  = {Name = "Totality Attack 2", Category = "Melee", ReqDot = 0.55, ReqDist = 30.0},
    ["130336833420143"] = {Name = "Totality Attack 3", Category = "Melee", ReqDot = 0.55, ReqDist = 30.0},
    -- MAHITO
    ["134461702265323"] = {Name = "Blade Mode", Category = "Rush", ReqDot = 0.90, ReqDist = 42.09},
    ["103493656287292"] = {Name = "Stockpile", Category = "Target", ReqDist = 18.0},
    ["89092734635186"]  = {Name = "Soulfire", Category = "Target", ReqDot = 0.90, ReqDist = 120.0},
    ["72475960800126"]  = {Name = "Focus Strike", Category = "Rush", ReqDot = 0.85, ReqDist = 30.0},
    ["127727754867974"] = {Name = "Spike Wrath", Category = "SpikeWrath", ReqDot = -1.0, ReqDist = 75.0},
    ["126277739156443"] = {Name = "Mahito Base M1 1", Category = "Melee", ReqDot = 0.55},
    ["99710481887795"]  = {Name = "Mahito Base M1 2", Category = "Melee", ReqDot = 0.55},
    ["121322029260156"] = {Name = "Mahito Base/Ryu M1 3", Category = "Melee", ReqDot = 0.55},
    ["122655618588472"] = {Name = "Mahito Base M1 4", Category = "Melee", ReqDot = 0.55},
    ["71784337627181"]  = {Name = "Mahito Armor M1 1", Category = "Melee", ReqDot = 0.50},
    ["125120382787311"] = {Name = "Mahito Armor M1 2", Category = "Melee", ReqDot = 0.50},
    ["119042572747325"] = {Name = "Mahito Armor/Choso M3", Category = "Melee", ReqDot = 0.50},
    ["98365018553171"]  = {Name = "Mahito Club M1 1", Category = "Melee", ReqDot = 0.50},
    ["80150988150906"]  = {Name = "Mahito Club M1 2", Category = "Melee", ReqDot = 0.50},
    ["86918383671100"]  = {Name = "Mahito Club M1 3", Category = "Melee", ReqDot = 0.50},
    ["85887300265206"]  = {Name = "Mahito Club M1 4", Category = "Melee", ReqDot = 0.50},
    ["79568627671998"]  = {Name = "Mahito Sword M1 1", Category = "Melee", ReqDot = 0.50},
    ["105870773841535"] = {Name = "Mahito Sword M1 2", Category = "Melee", ReqDot = 0.50},
    ["130659585624615"] = {Name = "Mahito Sword M1 3", Category = "Melee", ReqDot = 0.50},
    ["138626478088332"] = {Name = "Mahito Sword M1 4", Category = "Melee", ReqDot = 0.50},
    -- CHOSO
    ["96185406489877"]  = {Name = "Choso M1 1", Category = "Melee", ReqDot = 0.55},
    ["105077924973072"] = {Name = "Choso M1 2", Category = "Melee", ReqDot = 0.55},
    ["119042572747325"] = {Name = "Choso M1 3", Category = "Melee", ReqDot = 0.55},
    ["105287938257399"] = {Name = "Choso M1 4", Category = "Melee", ReqDot = 0.55},
    ["127171275866632"] = {Name = "Piercing Blood", Category = "PiercingBlood", ReqDot = 0.85, ReqDist = 30.0},
    ["84039122607068"]  = {Name = "Flowing Red Scale", Category = "Rush", ReqDot = 0.75, ReqDist = 19.0},
    ["100446064103831"] = {Name = "Blood Edge", Category = "Rush", ReqDot = 0.85, ReqDist = 10.0},
    ["95097480425566"]  = {Name = "Wing King", Category = "Rush", ReqDot = 0.80, ReqDist = 10.0},
    ["117371289990421"] = {Name = "Blood Rain", Category = "BloodRain", ReqDist = 35.5},
    -- TODO
    ["96327114254575"]  = {Name = "Todo M1 1", Category = "Melee", ReqDot = 0.50},
    ["107029561762376"] = {Name = "Todo M1 2", Category = "Melee", ReqDot = 0.50},
    ["117831239064143"] = {Name = "Todo M1 3 / Hiromi M2 4", Category = "Melee", ReqDot = 0.50},
    ["131358603583212"] = {Name = "Clap 1", Category = "Skill", ReqDot = 0.85, ReqDist = 60.0},
    ["91074768993486"]  = {Name = "Clap 2", Category = "Skill", ReqDot = 0.85, ReqDist = 60.0},
    ["116040503139675"] = {Name = "Clap 3", Category = "Skill", ReqDot = 0.85, ReqDist = 60.0},
    ["94720627091769"]  = {Name = "Swift Kick", Category = "Rush", ReqDot = 0.85, ReqDist = 30.0},
    ["111720035828971"] = {Name = "Pebble Throw", Category = "Target", ReqDot = 0.85, ReqDist = 50.0},
    -- HIROMI
    ["133936641185614"] = {Name = "Hiromi M1 1", Category = "Melee", ReqDot = 0.50},
    ["122573730331631"] = {Name = "Hiromi M1 2", Category = "Melee", ReqDot = 0.70},
    ["82400997593751"]  = {Name = "Hiromi M1 3", Category = "Melee", ReqDot = 0.70},
    ["118634493886688"] = {Name = "Hiromi M1 4", Category = "Melee", ReqDot = 0.70},
    ["139280948741186"] = {Name = "Hiromi M2 1", Category = "Melee", ReqDot = 0.70},
    ["109340494549365"] = {Name = "Hiromi M2 2", Category = "Melee", ReqDot = 0.70},
    ["98577624776161"]  = {Name = "Hiromi M2 3", Category = "Melee", ReqDot = 0.70},
    ["117831239064143"] = {Name = "Hiromi M2 3", Category = "Melee", ReqDot = 0.55},
    ["86362077638309"]  = {Name = "Gavel Throw", Category = "Target", ReqDot = 0.90, ReqDist = 50.0},
    ["89652378115594"]  = {Name = "Extend Swing", Category = "Rush", ReqDot = 0.80, ReqDist = 35.0},
    ["133869529005453"] = {Name = "Judgements Reach", Category = "Target", ReqDot = 0.90, ReqDist = 30.0},
    ["71186534081075"]  = {Name = "Grapple", Category = "Rush", ReqDot = 0.80, ReqDist = 70.0},
    ["135411487367370"] = {Name = "Pressing Charges", Category = "Rush", ReqDot = 0.85, ReqDist = 4.0},
    ["132754851925571"] = {Name = "Veredict", Category = "Skill", ReqDot = 0.85, ReqDist = 15.5},
    ["124243904748268"] = {Name = "Triple Sentence", Category = "Rush", ReqDist = 100.0},
    -- YUTA
    ["133240987753043"] = {Name = "Yuta M1 1", Category = "Melee", ReqDot = 0.50},
    ["130806585141471"] = {Name = "Yuta M1 2", Category = "Melee", ReqDot = 0.50},
    ["131967150738931"] = {Name = "Yuta M1 3", Category = "Melee", ReqDot = 0.50},
    ["84442064935420"]  = {Name = "Yuta M1 4", Category = "Melee", ReqDot = 0.50},
    ["109432265703187"] = {Name = "Yuta Ult M1 1", Category = "Melee", ReqDot = 0.50},
    ["137919635923292"] = {Name = "Yuta Ult M1 2", Category = "Melee", ReqDot = 0.50},
    ["135256592475167"] = {Name = "Yuta Ult M1 3", Category = "Melee", ReqDot = 0.50},
    ["121403322067812"] = {Name = "Yuta Ult M1 4", Category = "Melee", ReqDot = 0.50},
    ["104824728032437"] = {Name = "Severing Path", Category = "Rush", ReqDot = 0.85, ReqDist = 15.0},
    ["125904281673524"] = {Name = "Severing Path2", Category = "Rush", ReqDot = 0.85, ReqDist = 15.0},
    ["130834106305514"] = {Name = "Severing Path3", Category = "Rush", ReqDot = 0.85, ReqDist = 15.0},
    ["117178057848472"] = {Name = "Veilstep", Category = "Area", ReqDist = 8.5},
    ["95077220586856"]  = {Name = "Outburst", Category = "Skill", ReqDot = 0.80, ReqDist = 28.0},
    ["108418554887656"] = {Name = "Second Wind", Category = "Rush", ReqDot = 0.85, ReqDist = 35.0},
    ["88005970155216"]  = {Name = "Copy", Category = "Skill", ReqDist = 35.0, ReqDot = 0.0},
    -- MECHAMARU
    ["98783064085844"]  = {Name = "Mechamaru M1 1", Category = "Melee", ReqDot = 0.70},
    ["85148168523745"]  = {Name = "Mechamaru M1 2", Category = "Melee", ReqDot = 0.70},
    ["108686045412945"] = {Name = "Mechamaru M1 3", Category = "Melee", ReqDot = 0.70},
    ["79718433989469"]  = {Name = "Mechamaru M1 4", Category = "Melee", ReqDot = 0.70},
    ["80504019426174"]  = {Name = "Mechamaru M2 1", Category = "Melee", ReqDot = 0.70},
    ["100835844904897"] = {Name = "Mechamaru M2 2", Category = "Melee", ReqDot = 0.70},
    ["120136894011461"] = {Name = "Ultraspin", Category = "Rush", ReqDot = 0.80, ReqDist = 38.5},
    ["93901924492394"]  = {Name = "Ultracannon", Category = "Ultracannon", ReqDot = 0.85, ReqDist = 75.0},
    ["114277419400774"] = {Name = "Heat Emission", Category = "Rush", ReqDot = 0.80, ReqDist = 40.5},
    -- BOTS MECHAMARU
    ["139105275342427"] = {Name = "Bot User", Category = "Melee", ReqDot = 0.50},
    ["73522808400163"]  = {Name = "Bot Grab", Category = "Melee", ReqDot = 0.50},
    ["130123540243667"] = {Name = "Bot Kick", Category = "Melee", ReqDot = 0.50},
    -- NAOYA
    ["101283990868172"] = {Name = "Naoya M1 1", Category = "Melee", ReqDot = 0.50},
    ["108708446862011"] = {Name = "Naoya M1 2", Category = "Melee", ReqDot = 0.50},
    ["77583711129628"]  = {Name = "Naoya M1 3", Category = "Melee", ReqDot = 0.50},
    ["77284264481284"]  = {Name = "Naoya M2 1", Category = "Melee", ReqDot = 0.50},
    ["108376755316792"] = {Name = "Naoya M2 2", Category = "Melee", ReqDot = 0.50},
    ["74580112757879"]  = {Name = "Naoya M2 3", Category = "Melee", ReqDot = 0.50},
    ["101107501526373"] = {Name = "Naoya M2 4", Category = "Melee", ReqDot = 0.50},
    ["105121164520635"] = {Name = "Projection Breaker", Category = "Rush", ReqDot = 0.75, ReqDist = 16.5},
    ["86045680364061"]  = {Name = "Decisive Strike", Category = "NaoyaThrice", ReqDot = 0.50, ReqDist = 60.0},
    ["129944486689528"] = {Name = "Acceleration", Category = "Area", ReqDist = 16.5},
    -- DASHES (Global)
    ["110978068388232"] = {Name = "Universal Dash", Category = "DashRule"},
    ["132855702748568"] = {Name = "Hiromi Dash", Category = "DashRule"},
    ["130135202362252"] = {Name = "Yuta Dash", Category = "DashRule"},
    ["81708642912019"]  = {Name = "Nanami Dash", Category = "DashRule"},
    ["83782195794718"]  = {Name = "Ryu Dash", Category = "DashRule"},
    ["130284226842903"] = {Name = "Locust/Yuki Dash", Category = "DashRule"},
    ["140597320237985"] = {Name = "Charles Dash", Category = "DashRule"},
    ["134917827147266"] = {Name = "Haruta Dash 1", Category = "DashRule"},
    ["122074769949629"] = {Name = "Haruta Dash 2", Category = "DashRule"},
    ["128267680345523"] = {Name = "MeiMei Dash", Category = "DashRule"},
    ["105571879949076"] = {Name = "Kuro Dash", Category = "DashRule"},
    -- NANAMI
    ["84359513001979"]  = {Name = "Nanami M1 1", Category = "Melee", ReqDot = 0.50},
    ["79436586236026"]  = {Name = "Nanami M1 2", Category = "Melee", ReqDot = 0.50},
    ["102285403332509"] = {Name = "Nanami M1 3", Category = "Melee", ReqDot = 0.50},
    ["104137631480391"] = {Name = "Nanami M1 4", Category = "Melee", ReqDot = 0.50},
    ["114913455544468"] = {Name = "Nanami M2 1", Category = "Melee", ReqDot = 0.50},
    ["84602523265622"]  = {Name = "Nanami M2 2", Category = "Melee", ReqDot = 0.50},
    ["102085681670810"] = {Name = "Nanami M2 3", Category = "Melee", ReqDot = 0.50},
    ["115446267797335"] = {Name = "Nanami M2 4", Category = "Melee", ReqDot = 0.50},
    ["81210313723714"]  = {Name = "Cleaving Whirlwind", Category = "NanamiRatio", ReqDot = 0.85, ReqDist = 41.0},
    ["130957217409359"] = {Name = "Severance Kick", Category = "Rush", ReqDot = 0.85, ReqDist = 10.5},
    ["100811576955331"] = {Name = "Blunt Cut", Category = "NanamiRatio", ReqDot = 0.85, ReqDist = 36.5},
    ["113359849246757"] = {Name = "Stabilize", Category = "NanamiRatio", ReqDot = 0.85, ReqDist = 10.0},
    -- RYU
    ["92698956945928"]  = {Name = "Ryu M1 3_2", Category = "Melee", ReqDot = 0.50, ReqDist = 25.0},
    ["73243807139765"]  = {Name = "Granite Blast", Category = "Granite", ReqDot = 0.60, ReqDist = 78.5},
    ["114822879878184"] = {Name = "Unsatisfied", Category = "Rush", ReqDot = 0.80, ReqDist = 30.0},
    ["70394890117813"]  = {Name = "Appetizer", Category = "Rush", ReqDot = 0.80, ReqDist = 80.0},   
    -- HANAMI
    ["138169151223960"] = {Name = "Disaster Root", Category = "Target", ReqDot = 0.70, ReqDist = 60.0},
    ["111083699259354"] = {Name = "Hanami M1 1", Category = "Melee", ReqDot = 0.50},
    ["88849926869776"]  = {Name = "Hanami M1 2", Category = "Melee", ReqDot = 0.50},
    ["89537672683114"]  = {Name = "Hanami M1 3", Category = "Melee", ReqDot = 0.50},
    ["92595499555055"]  = {Name = "Surging Thorns", Category = "Area", ReqDist = 35.0}, 
    ["96466374346823"]  = {Name = "Bud Shot", Category = "Target", ReqDot = 0.84, ReqDist = 70.0},
    -- LOCUST
    ["85068785050521"]  = {Name = "Locust M1 1", Category = "Melee", ReqDot = 0.50},
    ["79086910454958"]  = {Name = "Locust M1 2", Category = "Melee", ReqDot = 0.50},
    ["108027796023968"] = {Name = "Locust M1 3", Category = "Melee", ReqDot = 0.50},
    ["99205259396653"]  = {Name = "Locust M1 4", Category = "Melee", ReqDot = 0.50},
    ["129678103897608"] = {Name = "Clever", Category = "Rush", ReqDot = 0.60, ReqDist = 35.6},
    ["134777193523837"] = {Name = "Crushing Jaws", Category = "Rush", ReqDot = 0.85, ReqDist = 30.0},
    ["121550561336691"] = {Name = "Wing Throw", Category = "Rush", ReqDot = 0.80, ReqDist = 12.0},
    -- YUKI
    ["131909724908049"] = {Name = "Yuki M1 1", Category = "Melee", ReqDot = 0.50},
    ["72575786212990"]  = {Name = "Yuki M1 2", Category = "Melee", ReqDot = 0.50},
    ["119248903710146"] = {Name = "Yuki M1 3", Category = "Melee", ReqDot = 0.50},
    ["123168328205349"] = {Name = "Yuki M1 4", Category = "Melee", ReqDot = 0.50},
    ["115097960689033"] = {Name = "Garuda Rebound", Category = "Rush", ReqDot = 0.85, ReqDist = 100.0}, 
    ["94347210073500"]  = {Name = "Rising Star", Category = "Rush", ReqDot = 0.55, ReqDist = 17.5},
    -- CHARLES
    ["125689391910002"] = {Name = "Charles M1 1", Category = "Melee", ReqDot = 0.50},
    ["84080901810314"]  = {Name = "Charles M1 2", Category = "Melee", ReqDot = 0.50},
    ["139833047658617"] = {Name = "Charles M1 3", Category = "Melee", ReqDot = 0.50},
    ["79271374075726"]  = {Name = "Charles M1 4", Category = "Melee", ReqDot = 0.50},
    ["103013818601982"] = {Name = "Dispair", Category = "CharlesDispair", ReqDist = 12.0},
    ["79860101129549"]  = {Name = "Shut Up!", Category = "CharlesShutUp", ReqDot = -0.80, ReqDist = 8.0},
    -- HARUTA
    ["133447840605824"] = {Name = "Haruta M1 1", Category = "Melee", ReqDot = 0.50},
    ["113963875117859"] = {Name = "Haruta M1 2", Category = "Melee", ReqDot = 0.50},
    ["106282708121342"] = {Name = "Haruta M1 3", Category = "Melee", ReqDot = 0.50},
    ["101681158700275"] = {Name = "Haruta M1 4", Category = "Melee", ReqDot = 0.50},
    ["120914276661831"] = {Name = "Ambush", Category = "HarutaAmbush", ReqDot = 0.50, ReqDist = 15.0},
    ["95494223368246"]  = {Name = "Stinger", Category = "Rush", ReqDot = 0.78, ReqDist = 5.0},
    ["103960582499076"] = {Name = "Ankle Cutter", Category = "HarutaNPC"},
    ["93028763593631"]  = {Name = "High Time", Category = "Skill", ReqDot = 0.85, ReqDist = 20.0},
    ["102053631728986"] = {Name = "Trip", Category = "Rush", ReqDot = 0.50, ReqDist = 15.0},
    ["76957377224584"]  = {Name = "Cheap Shot", Category = "Target", ReqDot = 0.85, ReqDist = 60.0},
    ["124759375124281"] = {Name = "Dirt Play", Category = "Target", ReqDot = 0.85, ReqDist = 60.0},
    -- MEIMEI
    ["114985590391235"] = {Name = "MeiMei M1 1", Category = "Melee", ReqDot = 0.50},
    ["108449614447004"] = {Name = "MeiMei M1 2", Category = "Melee", ReqDot = 0.50},
    ["122170399962557"] = {Name = "MeiMei M1 3", Category = "Melee", ReqDot = 0.50},
    ["117638619792450"] = {Name = "MeiMei M1 4", Category = "Melee", ReqDot = 0.50},
    ["126362899488198"] = {Name = "Impetus Updraft", Category = "Rush", ReqDot = 0.60, ReqDist = 9.0},
    ["92081142332466"]  = {Name = "Impetus New", Category = "Rush", ReqDot = 0.80, ReqDist = 5.0},
    ["90781290293652"]  = {Name = "Circling", Category = "Circling"},
    ["81007905598407"]  = {Name = "Murmurate", Category = "Area", ReqDist = 35.0},
    -- KUROURUSHI
    ["105961366724096"] = {Name = "Kuro M1 1", Category = "Melee", ReqDot = 0.30},
    ["86519781516542"]  = {Name = "Kuro M1 2", Category = "Melee", ReqDot = 0.30},
    ["123591522021548"] = {Name = "Kuro M1 3", Category = "Melee", ReqDot = 0.30},
    ["124726819047447"] = {Name = "Kuro M1 4", Category = "Melee", ReqDot = 0.30},
    ["97901397284754"]  = {Name = "Kuro M2 1", Category = "Melee", ReqDot = 0.30},
    ["135686778593679"] = {Name = "Kuro M2 2", Category = "Melee", ReqDot = 0.30},
    ["92796867394473"]  = {Name = "Kuro M2 3", Category = "Melee", ReqDot = 0.30},
    ["81426568444338"]  = {Name = "Kuro M2 4", Category = "Melee", ReqDot = 0.30},
    ["83430571986421"]  = {Name = "Festering Strikes", Category = "Rush", ReqDot = 0.80, ReqDist = 22.0},
    ["78636717376287"]  = {Name = "Detach", Category = "Target", ReqDot = 0.85, ReqDist = 120.0},
    ["104082985552315"] = {Name = "Reattach", Category = "Target", ReqDot = 0.85, ReqDist = 120.0},
    ["85938446097801"]  = {Name = "Chokehold", Category = "Rush", ReqDot = 0.35, ReqDist = 10.5}, 
    ["116119661056362"] = {Name = "Roach Swarm", Category = "Rush", GroundIsUnblockable = true, ReqDist = 32.5}
}

-- ==========================================
-- SCRIPT UTILITIES & HELPERS
-- ==========================================

-- Parses URL strings to grab the raw Asset ID number.
local function ExtractID(url)
    if not url then return nil end
    return string.match(url, "%d+")
end

-- Checks if the provided enemy is Naoya (whose dash is harmless).
local function IsNaoya(enemyMoveset)
    if enemyMoveset and string.find(enemyMoveset, "Naoya") then return true end
    return false
end

-- Checks whether an incoming attack bypasses normal defenses (e.g., enemy is in mid-air).
local function IsUnblockableMove(animData, enemyHumanoid, enemyChar)
    if not animData then return false end
    if animData.Category == "Unblockable" then return true end
    
    local isAir = (enemyHumanoid.FloorMaterial == Enum.Material.Air or enemyHumanoid:GetState() == Enum.HumanoidStateType.Freefall or enemyHumanoid:GetState() == Enum.HumanoidStateType.Jumping)
    
    -- Ground or Air unblockable states overriding normal block rules
    if animData.GroundIsUnblockable and not isAir then return true end
    if animData.AirIsUnblockable and isAir then return true end

    -- Dynamic check for Choso's Piercing Blood if blood has been consumed.
    if animData.Category == "PiercingBlood" and enemyChar then
        if enemyChar:GetAttribute("PiercingUnblockable") == true then
            return true 
        end
    end
    
    return false
end

-- Specific function handling Nanami's perfect ratio timing blocks.
local function CheckNanamiRatio()
    if not LocalPlayer.Character then return false end
    local info = LocalPlayer.Character:FindFirstChild("Info")
    if info and info:FindFirstChild("Ratio") and info:GetAttribute("CurrentTiming") then
        return true
    end
    return false
end

-- Instantly forces the local player to look directly at the target.
-- Also swings the camera if the 'CameraFollow' option is enabled in the UI.
local function FaceTarget(targetPosition)
    local myChar = CharactersFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character  -- same live-body resolution as detection: block is DIRECTIONAL, must rotate the REAL body
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    local direction = targetPosition - myHRP.Position
    if direction.Magnitude > 0.1 then 
        -- Instant character rotation (bypasses any slow tweening)
        myHRP.CFrame = CFrame.lookAt(myHRP.Position, Vector3.new(targetPosition.X, myHRP.Position.Y, targetPosition.Z))
        -- Smoothly tracks the camera behind the character if toggled on
        if Config.Blocks.CameraFollow then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPosition), 0.4)
        end
    end
end

-- Calculates predictive hitbox extensions based on the enemy's velocity.
local BLOCK_RANGE_MULT = 1.6   -- GLOBAL reaction-range boost. Raising this is the single biggest 'react faster' lever: the shield goes up while the attacker is still closing, instead of once they are already on top of you. 1.6 = the block registers well before contact even at dash speed.
local function GetDynamicRequiredDist(animData, myHRP, enemyHRP)
    -- Static attacks ignore dynamic physics
    if animData.ReqDist then return animData.ReqDist * BLOCK_RANGE_MULT end

    if animData.Category == "Melee" then
        local vel = enemyHRP.AssemblyLinearVelocity
        local flatVel = Vector3.new(vel.X, 0, vel.Z)
        local speed = flatVel.Magnitude
        local baseDist = 11.5  -- raise the shield earlier still; a lunging M1 covers the last few studs faster than the block can register from 9.5

        -- If the enemy is lunging at high speeds, extend the danger zone to compensate for server ping
        if speed > 3.0 then
            local toMeDir = (myHRP.Position - enemyHRP.Position)
            if toMeDir.Magnitude > 0.1 then
                toMeDir = toMeDir.Unit
                local approachDot = flatVel.Unit:Dot(toMeDir)

                -- Only expand the hitbox if they are actively moving *towards* you
                if approachDot > 0.30 then
                    return baseDist + (speed * approachDot * 0.32)  -- was 0.25: bigger lead vs fast lunges
                end
            end
        end
        return baseDist
    end
    
    return 10.0 
end

-- Initializes event listeners for the local player's character.
local function SetupLocalPlayer(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    local animator = humanoid and humanoid:WaitForChild("Animator", 5)
    if animator then
        animator.AnimationPlayed:Connect(function(track)
            if not track.Animation then return end
            local id = ExtractID(track.Animation.AnimationId)
            -- If casting Malevolent Shrine, grant immunity timer
            if id == "121984128639453" then
                myDomainEndTime = tick() + 25 
            end
            local animData = AnimDict[id]
            -- Log local attacks to prevent self-blocking
            if animData then
                myCasts[animData.Name] = tick() + 10
            end
        end)
    end
end

if LocalPlayer.Character then SetupLocalPlayer(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SetupLocalPlayer)
_G.VX_ANIMDICT = AnimDict  -- expose the attack-animation-id map so Auto Counter can block the instant a known enemy attack plays

-- ==========================================
-- ANIMATION EVENT HANDLER
-- Evaluates incoming animation data on frame 1 to preemptively raise defenses.
-- ==========================================
_G.OnAnimationPlayed = function(enemyChar, track)
    if not IsAnyBlockActive() then return end

    local myChar = CharactersFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character  -- JJS live body (LP.Character lag = missed instant reactions)
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart") or enemyChar.PrimaryPart
    local enemyInfo = enemyChar:FindFirstChild("Info")
    local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid") or enemyChar:FindFirstChildOfClass("AnimationController")
    
    if not (myHRP and enemyHRP and enemyHumanoid and track.Animation) then return end
    
    local trackID = ExtractID(track.Animation.AnimationId)
    local animData = AnimDict[trackID]
    
    if animData then
        local cat = animData.Category
        local isMelee = (cat == "Melee" or cat == "MechaBotMelee")
        local isDash = (cat == "DashRule")
        local isAbil = not isMelee and not isDash
        local isValid = true

        -- Module Filtering: Stop processing if the user disabled this specific defense type
        if isMelee and not Config.Blocks.M1 then isValid = false end
        if isDash and not Config.Blocks.Dash then isValid = false end
        if isAbil and not Config.Blocks.Abilities then isValid = false end

        if isValid then
            -- Clean out old duplicates of the same threat to keep memory light
            local i = #ActiveThreatTracks
            while i >= 1 do
                if ActiveThreatTracks[i].Char == enemyChar then
                    table.remove(ActiveThreatTracks, i)
                end
                i = i - 1
            end
            
            table.insert(ActiveThreatTracks, {
                Track = track,
                Char = enemyChar,
                Data = animData,
                StartTime = tick()
            })
            
            if animData.Name == "Rabbit Escape" then rabbitCaster = enemyChar end
            
            if animData.Category ~= "DomainCast" then
                if animData.Category == "TodoClap" then
                    local clapTarget = enemyInfo and enemyInfo:FindFirstChild("ClapTarget")
                    if clapTarget and clapTarget.Value == myChar.Name then
                        local dist = (enemyHRP.Position - myHRP.Position).Magnitude
                        -- Only blocks clap teleportation if within valid range
                        if dist > 26.0 and dist <= 60.0 then
                            FaceTarget(enemyHRP.Position)
                            currentThreatInstance = enemyChar
                            lastBlockedThreatName = animData.Name
                            comboDropTime = tick() + Config.ComboDelay
                            if not isBlocking then
                                isBlocking = true
                                Config.Remotes.BlockActivate:FireServer(enemyChar)
                            end
                        end
                    end
                elseif animData.Category == "NaoyaThrice" then
                    local count = naoyaDecisiveCount[enemyChar] or 0
                    if count < 2 then 
                        naoyaDecisiveCount[enemyChar] = count + 1
                        task.delay(1.5, function() naoyaDecisiveCount[enemyChar] = 0 end)
                    end
                elseif animData.Category == "NanamiRatio" then
                    if CheckNanamiRatio() then
                        -- Check valid, doing nothing explicit here allows normal block fallback
                    end
                end
            end
        end
    end
end

-- ==========================================
-- MAIN RENDER STEPPED (PREDICTIVE HITBOX ENGINE)
-- The absolute core of the script. Runs 60 times a second.
-- ==========================================
RunService.RenderStepped:Connect(function()
    -- If all modules are turned off, drop the shield immediately and return
    if not IsAnyBlockActive() then 
        if isBlocking then
            Config.Remotes.BlockDeactivate:FireServer()
            isBlocking = false
        end
        return 
    end
    
    local myChar = CharactersFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character  -- JJS live body (LP.Character lag made blocking miss/late)
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local isThreatCurrentlyActive = false
    local facePosition = nil
    -- Read the server clock ONCE per frame. It used to be called inside the per-enemy loop below, so a lobby
    -- with 15 people nearby made 15 engine calls every frame for a value that cannot change within one frame.
    local frameServerTime = workspace:GetServerTimeNow()

    -- 1. DATA READER: M1 COMBO SUSTAIN WITH PREDICTIVE HITBOX
    -- Handles smooth defensive chains when an enemy is mashing M1
    if Config.Blocks.M1 then
        for _, enemyChar in ipairs(NearbyEnemies) do
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            if enemyHRP then
                local currentM1 = enemyChar:GetAttribute("CurrentM1") or 0
                local lastM1 = enemyChar:GetAttribute("LastM1") or 0
                local serverTime = frameServerTime   -- hoisted: this was one engine call PER ENEMY PER FRAME
                
                -- Check if they are actively in an M1 combo string
                if currentM1 > 0 and (serverTime - lastM1) < 1.05 then   -- 0.80 missed the tail of slower combo strings, so the last hit went unblocked
                    local distance = (enemyHRP.Position - myHRP.Position).Magnitude
                    local toMeDir = (myHRP.Position - enemyHRP.Position)
                    
                    if toMeDir.Magnitude > 0.1 then
                        toMeDir = toMeDir.Unit
                        local dot = enemyHRP.CFrame.LookVector:Dot(toMeDir)
                        
                        -- Gather physics data to predict where the enemy will be next frame
                        local vel = enemyHRP.AssemblyLinearVelocity
                        local flatVel = Vector3.new(vel.X, 0, vel.Z)
                        local speed = flatVel.Magnitude
                        local requiredDist = 12.5  -- 'if a player punches you it should automatically block the M1': they start the swing from further out than 9.5, and the shield has to already be up when it lands

                        if speed > 3.0 then
                            local approachDot = flatVel.Unit:Dot(toMeDir)
                            if approachDot > 0.30 then
                                requiredDist = 9.5 + (speed * approachDot * 0.32)  -- bigger lead vs fast lunges
                            end
                        end

                        local requiredDot = 0.22   -- 0.50 required them to be almost perfectly facing you, so a punch thrown while strafing or mid-turn was never blocked
                        if distance <= 7.5 then    -- widened: inside this range block regardless of facing (360 defence)
                            -- 360-Degree Defense against ping-based teleports behind the local player
                            requiredDot = -1.0 
                        elseif distance < 10.0 then
                            -- Low angle threshold for shoulder-to-shoulder hitboxes
                            requiredDot = 0.100
                        end
                        
                        -- If the enemy breaches the required parameters, lock defense
                        if distance <= requiredDist and dot >= requiredDot then 
                            isThreatCurrentlyActive = true
                            currentThreatInstance = enemyChar
                            facePosition = enemyHRP.Position
                            lastBlockedThreatName = "Combo M1 (" .. currentM1 .. ")"
                            comboDropTime = tick() + Config.ComboDelay
                            break
                        end
                    end
                end
            end
        end
    end

    -- 2. ACTIVE ANIMATION CHECKS (FULLY NESTED LOGIC, ZERO 'CONTINUE' COMMANDS)
    if not isThreatCurrentlyActive then
        local i = #ActiveThreatTracks
        while i >= 1 do
            local threat = ActiveThreatTracks[i]
            local track = threat.Track
            local enemyChar = threat.Char
            local animData = threat.Data
            
            if not track.IsPlaying or not enemyChar.Parent then
                table.remove(ActiveThreatTracks, i)
            else
                local cat = animData.Category
                local isMelee = (cat == "Melee" or cat == "MechaBotMelee")
                local isDash = (cat == "DashRule")
                local isAbil = not isMelee and not isDash
                local isValid = true

                if isMelee and not Config.Blocks.M1 then isValid = false end
                if isDash and not Config.Blocks.Dash then isValid = false end
                if isAbil and not Config.Blocks.Abilities then isValid = false end
                if animData.Category == "DomainCast" then isValid = false end

                if isValid then
                    local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart") or enemyChar.PrimaryPart
                    local enemyInfo = enemyChar:FindFirstChild("Info")
                    local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid") or enemyChar:FindFirstChildOfClass("AnimationController")
                    local enemyMoveset = enemyChar:GetAttribute("CachedMoveset") or (enemyChar.Name == "Naoya" and "Naoya" or "")
                    
                    if enemyHRP and enemyHumanoid then
                        local distance = (enemyHRP.Position - myHRP.Position).Magnitude
                        local toMeDir = (myHRP.Position - enemyHRP.Position).Unit
                        local dot = enemyHRP.CFrame.LookVector:Dot(toMeDir)
                        local moveProcessed = false
                        
                        -- SPATIAL LOGIC: Area (Pure Radius Detection ignoring camera angle)
                        if animData.Category == "Area" then
                            if distance <= animData.ReqDist then
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = animData.Name
                                comboDropTime = tick() + Config.ComboDelay
                            end
                            moveProcessed = true
                        end

                        -- 360-DEGREE SPATIAL LOGIC: Spike Wrath Lock (Mahito)
                        if not moveProcessed and animData.Category == "SpikeWrath" then
                            if distance <= animData.ReqDist then 
                                spikeWrathLock = enemyChar
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = "Spike Wrath (Cast)"
                                comboDropTime = tick() + Config.ComboDelay
                            end
                            moveProcessed = true
                        end

                        -- CHARLES LOGIC: Dispair (Continuous Rotation Checking)
                        if not moveProcessed and animData.Category == "CharlesDispair" then
                            if distance <= animData.ReqDist and dot >= 0.45 then
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = animData.Name
                                comboDropTime = tick() + Config.ComboDelay
                            end
                            moveProcessed = true
                        end

                        -- CHARLES LOGIC: Shut Up (Sustained Block until animation finishes)
                        if not moveProcessed and animData.Category == "CharlesShutUp" then
                            if distance <= animData.ReqDist and dot <= animData.ReqDot then
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = animData.Name
                                comboDropTime = tick() + Config.ComboDelay
                            end
                            moveProcessed = true
                        end
                        
                        -- HARUTA LOGIC: Perfect Block on Ambush (0.2s explicit delay)
                        if not moveProcessed and animData.Category == "HarutaAmbush" then
                            local elapsed = tick() - threat.StartTime
                            if elapsed >= 0.20 then
                                if distance <= animData.ReqDist and dot >= animData.ReqDot then
                                    isThreatCurrentlyActive = true
                                    currentThreatInstance = enemyChar
                                    facePosition = enemyHRP.Position
                                    lastBlockedThreatName = "Ambush (Perfect Block)"
                                    comboDropTime = tick() + Config.ComboDelay
                                end
                            end
                            moveProcessed = true
                        end
                        
                        -- RYU LOGIC: Granite Blast (Initial Block + Drops if skill charge is canceled)
                        if not moveProcessed and animData.Category == "Granite" then
                            local elapsed = tick() - threat.StartTime
                            local inSkill = enemyInfo and enemyInfo:FindFirstChild("InSkill")
                            
                            if elapsed <= 0.5 then
                                if distance <= animData.ReqDist and dot >= animData.ReqDot then
                                    isThreatCurrentlyActive = true
                                    currentThreatInstance = enemyChar
                                    facePosition = enemyHRP.Position
                                    lastBlockedThreatName = "Granite Blast (Cast Initial)"
                                    comboDropTime = tick() + Config.ComboDelay
                                end
                            else
                                if not inSkill and elapsed < 1.1 then
                                    if distance <= animData.ReqDist and dot >= animData.ReqDot then
                                        isThreatCurrentlyActive = true
                                        currentThreatInstance = enemyChar
                                        facePosition = enemyHRP.Position
                                        lastBlockedThreatName = "Granite Blast (Main Blast)"
                                        comboDropTime = tick() + Config.ComboDelay
                                    end
                                end
                            end
                            moveProcessed = true
                        end

                        -- REVISED CIRCLING: Hard blocks for exactly 1.1 seconds (Range: 18, Dot: 0.30)
                        if not moveProcessed and animData.Category == "Circling" then
                            local elapsed = tick() - threat.StartTime
                            if elapsed <= 1.1 then
                                if distance <= 18.0 and dot >= 0.30 then
                                    isThreatCurrentlyActive = true
                                    currentThreatInstance = enemyChar
                                    facePosition = enemyHRP.Position
                                    lastBlockedThreatName = "Circling"
                                    comboDropTime = tick() + Config.ComboDelay
                                end
                            end
                            moveProcessed = true
                        end

                        -- DASH RULE: Ignores Naoya since his dash lacks direct damage
                        if not moveProcessed and animData.Category == "DashRule" then
                            if not IsNaoya(enemyMoveset) then
                                if distance <= 15.0 and dot >= 0.50 then
                                    isThreatCurrentlyActive = true
                                    currentThreatInstance = enemyChar
                                    facePosition = enemyHRP.Position
                                    lastBlockedThreatName = "Dash Anim (" .. animData.Name .. ")"
                                    comboDropTime = tick() + Config.ComboDelay
                                end
                            end
                            moveProcessed = true
                        end
                        
                        -- MECHAMARU LOGIC: Ultracannon vulnerability window mapping
                        if not moveProcessed and animData.Category == "Ultracannon" then
                            local elapsed = tick() - threat.StartTime
                            if elapsed > 1.3 then
                                table.remove(ActiveThreatTracks, i)
                            else
                                if distance <= animData.ReqDist and dot >= animData.ReqDot then
                                    isThreatCurrentlyActive = true
                                    currentThreatInstance = enemyChar
                                    facePosition = enemyHRP.Position
                                    lastBlockedThreatName = "Ultracannon"
                                    comboDropTime = tick() + Config.ComboDelay
                                end
                            end
                            moveProcessed = true
                        end
                        
                        -- YUTA LOGIC: Fast Outburst reaction limit
                        if not moveProcessed and animData.Category == "Outburst" then
                            local outBurstCharge = enemyInfo and enemyInfo:FindFirstChild("OutburstCharge")
                            if not outBurstCharge and tick() - threat.StartTime < 0.4 and distance <= 15 then
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = "Outburst"
                                comboDropTime = tick() + Config.ComboDelay
                            end
                            moveProcessed = true
                        end
                        
                        -- DEFAULT MELEE / RUSH LOGIC EVALUATION
                        if not moveProcessed then
                            local requiredDot = animData.ReqDot or 0.85
                            
                            if animData.Category == "Melee" then
                                if distance <= 7.0 then
                                    requiredDot = -1.0 -- All close-quarters melee at <= 7 studs ignores DOT (360-degree block)
                                elseif distance < 9.0 then
                                    requiredDot = 0.100
                                end
                            end
                            
                            local requiredDist = GetDynamicRequiredDist(animData, myHRP, enemyHRP)
                            local unblockable = false
                            
                            if enemyHumanoid:IsA("Humanoid") then
                                unblockable = IsUnblockableMove(animData, enemyHumanoid, enemyChar)
                            end
                            
                            -- Ultimate verification gateway
                            if distance <= requiredDist and dot >= requiredDot and not unblockable then
                                if animData.Category == "ReverseRule" then
                                    reverseBallLock = true
                                    reverseBallLockTime = tick()
                                end
                                
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = animData.Name
                                
                                if animData.Name == "Ultraspin" and enemyChar.Name == "MechamaruBot" then
                                    comboDropTime = tick() + 0.1
                                else
                                    comboDropTime = tick() + Config.ComboDelay
                                end
                            end
                        end
                        
                        if isThreatCurrentlyActive then break end -- Threat found, break out of the while loop safely
                    end
                end
            end
            i = i - 1
        end
    end

    -- 3. MECHAMARU BOTS (Module: Abilities)
    if not isThreatCurrentlyActive and Config.Blocks.Abilities then
        for _, char in ipairs(CharactersFolder:GetChildren()) do
            if char.Name == "MechamaruBot" then
                local owner = char:FindFirstChild("Owner")
                if owner and owner.Value ~= myChar then
                    local info = char:FindFirstChild("Info")
                    local botHRP = char:FindFirstChild("HumanoidRootPart")
                    
                    if info and botHRP then
                        local inSkill = info:FindFirstChild("InSkill")
                        local knockback = info:FindFirstChild("Knockback")
                        
                        local dist = (botHRP.Position - myHRP.Position).Magnitude
                        local toMeDir = (myHRP.Position - botHRP.Position).Unit
                        local dot = botHRP.CFrame.LookVector:Dot(toMeDir)
                        
                        if inSkill and dist <= 38.5 and dot >= 0.50 then
                            isThreatCurrentlyActive = true
                            currentThreatInstance = owner.Value
                            facePosition = botHRP.Position
                            lastBlockedThreatName = "MechamaruBot (Attack/Spin)"
                            comboDropTime = tick() + Config.ComboDelay
                            break
                        elseif knockback and dist <= 30.0 then
                            isThreatCurrentlyActive = true
                            currentThreatInstance = owner.Value
                            facePosition = botHRP.Position
                            lastBlockedThreatName = "MechamaruBot (Explosion)"
                            comboDropTime = tick() + Config.ComboDelay
                            break
                        end
                    end
                end
            end
        end
    end

    -- 4. SPIKE WRATH SUSTAIN LOCK (Module: Abilities)
    if not isThreatCurrentlyActive and spikeWrathLock and spikeWrathLock.Parent and Config.Blocks.Abilities then
        local lockHRP = spikeWrathLock:FindFirstChild("HumanoidRootPart")
        local lockInfo = spikeWrathLock:FindFirstChild("Info")
        if lockHRP and lockInfo then
            local inSkill = lockInfo:FindFirstChild("InSkill")
            if inSkill and inSkill.Value == true then
                local dist = (lockHRP.Position - myHRP.Position).Magnitude
                if dist <= 75.0 then
                    isThreatCurrentlyActive = true
                    currentThreatInstance = spikeWrathLock
                    facePosition = lockHRP.Position
                    lastBlockedThreatName = "Spike Wrath (Sustained)"
                    comboDropTime = tick() + Config.ComboDelay
                else
                    spikeWrathLock = nil 
                end
            else
                spikeWrathLock = nil 
            end
        else
            spikeWrathLock = nil
        end
    end

    -- 5. RAW PHYSICAL DASH (Module: Dash)
    if not isThreatCurrentlyActive and Config.Blocks.Dash then
        for _, enemyChar in ipairs(NearbyEnemies) do
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyInfo = enemyChar:FindFirstChild("Info")
            local enemyMoveset = enemyChar:GetAttribute("CachedMoveset") or ""
            
            if enemyHRP and enemyInfo and not enemyInfo:FindFirstChild("Stun") and not enemyInfo:FindFirstChild("Knockback") then
                -- Bypass Naoya since his dash is for repositioning, not damage
                if not IsNaoya(enemyMoveset) then
                    local distance = (enemyHRP.Position - myHRP.Position).Magnitude
                    local isDashing = enemyInfo:FindFirstChild("Dash")
                    
                    local toMeDir = (myHRP.Position - enemyHRP.Position)
                    if toMeDir.Magnitude > 0.1 then
                        toMeDir = toMeDir.Unit
                        local dot = enemyHRP.CFrame.LookVector:Dot(toMeDir)

                        -- Primary Collision Block (widened 15->20 studs, looser angle: react to less-direct dashes too)
                        if isDashing and distance <= 20.0 and dot >= 0.40 then
                            isThreatCurrentlyActive = true
                            currentThreatInstance = enemyChar
                            facePosition = enemyHRP.Position
                            lastBlockedThreatName = "Collision Dash (Physical 20 Studs)"
                            comboDropTime = tick() + Config.ComboDelay
                            break
                        -- Secondary Aggressive Approach Block (widened 25->34 studs)
                        elseif (isDashing or enemyInfo:FindFirstChild("Chase")) then
                            if dot >= 0.45 and distance <= 34 and enemyHRP.Velocity.Unit:Dot(toMeDir) >= 0.55 then
                                isThreatCurrentlyActive = true
                                currentThreatInstance = enemyChar
                                facePosition = enemyHRP.Position
                                lastBlockedThreatName = "Aggressive Dash"
                                comboDropTime = tick() + Config.ComboDelay
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- 6. GLOBAL EFFECTS & NPCS DETECTION (Module: Abilities - Fast Cache Read)
    if not isThreatCurrentlyActive and Config.Blocks.Abilities then
        -- First, check enemies in the region for unmapped spatial effects
        for _, enemyChar in ipairs(NearbyEnemies) do
            local setAssets = enemyChar:FindFirstChild("SetAssets")
            if setAssets then
                local supernova = setAssets:FindFirstChild("Supernova")
                if supernova and supernova:IsA("BasePart") then
                    local dist = (supernova.Position - myHRP.Position).Magnitude
                    if dist <= 10.5 then
                        isThreatCurrentlyActive = true
                        currentThreatInstance = enemyChar
                        facePosition = supernova.Position
                        lastBlockedThreatName = "Supernova Explosion"
                        comboDropTime = tick() + Config.ComboDelay
                        break
                    end
                end
            end
            
            if not isThreatCurrentlyActive then
                local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
                local info = enemyChar:FindFirstChild("Info")
                if enemyHRP and info then
                    local rainHold = info:FindFirstChild("RainHold")
                    if rainHold then
                        local dist = (enemyHRP.Position - myHRP.Position).Magnitude
                        if dist <= 35.5 then
                            isThreatCurrentlyActive = true
                            currentThreatInstance = enemyChar
                            facePosition = enemyHRP.Position
                            lastBlockedThreatName = "Blood Rain (Sustained)"
                            comboDropTime = tick() + Config.ComboDelay
                            break
                        end
                    end
                end
                
                if not isThreatCurrentlyActive then
                    local isNPC = enemyChar.Name == "HarutaSwordNPC"
                    if isNPC then
                        local owner = enemyChar:FindFirstChild("Owner")
                        if owner and owner.Value ~= myChar then
                            local hrp = enemyChar:FindFirstChild("HumanoidRootPart")
                            if hrp and info then
                                local dist = (hrp.Position - myHRP.Position).Magnitude
                                if info:FindFirstChild("InSkill") and dist <= 5.0 then
                                    local tgt = info:FindFirstChild("Sword") and info.Sword:FindFirstChild("Target")
                                    if not tgt or tgt.Value == myChar.Name then
                                        isThreatCurrentlyActive = true
                                        currentThreatInstance = owner.Value
                                        facePosition = hrp.Position
                                        lastBlockedThreatName = "NPC Attack (" .. enemyChar.Name .. ")"
                                        comboDropTime = tick() + Config.ComboDelay
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if isThreatCurrentlyActive then break end
        end

        -- Domain Cache Evaluation
        if not isThreatCurrentlyActive then
            local domainCC = Lighting:FindFirstChild("DomainCC")
            local inDomainArea = false
            for domainPart, _ in pairs(CachedDomains) do
                if domainPart.Parent then
                    if tick() > myDomainEndTime then 
                        local radius = (domainPart.Size.X / 2) + 15
                        local dist = (domainPart.Position - myHRP.Position).Magnitude
                        if dist <= radius then
                            inDomainArea = true
                            facePosition = domainPart.Position
                            break
                        end
                    end
                else
                    CachedDomains[domainPart] = nil
                end
            end
            if (inDomainArea or domainCC) and tick() > myDomainEndTime then
                isThreatCurrentlyActive = true
                lastBlockedThreatName = "Domain Expansion"
                comboDropTime = tick() + Config.ComboDelay
            end
        end

        -- Fast Cache Projectile Evaluation (Zero-Lag Array mapping)
        if not isThreatCurrentlyActive then
            for part, _ in pairs(CachedProjectiles) do
                if part.Parent then
                    local mappedSkill = PartToSkillMap[part.Name]
                    local skipProjectile = false
                    if mappedSkill and myCasts[mappedSkill] and tick() < myCasts[mappedSkill] then 
                        skipProjectile = true 
                    end

                    if not skipProjectile then
                        local partOwner = part:FindFirstChild("Owner") or part:FindFirstChild("Creator")
                        if partOwner and (partOwner.Value == myChar or partOwner.Value == LocalPlayer) then 
                            skipProjectile = true 
                        end
                        
                        if not skipProjectile then
                            if part.Name == "Crow" and part:IsA("Model") then
                                local crowHRP = part:FindFirstChild("HumanoidRootPart")
                                if crowHRP then
                                    local dist = (crowHRP.Position - myHRP.Position).Magnitude
                                    local toMeDir = (myHRP.Position - crowHRP.Position).Unit
                                    local vel = crowHRP.AssemblyLinearVelocity
                                    
                                    local isApproaching = false
                                    if vel.Magnitude > 3.0 then
                                        if vel.Unit:Dot(toMeDir) > 0.0 then isApproaching = true end
                                    else
                                        isApproaching = true
                                    end

                                    if dist <= 20.0 and isApproaching then
                                        isThreatCurrentlyActive = true
                                        currentThreatInstance = partOwner and partOwner.Value or nil
                                        facePosition = crowHRP.Position
                                        lastBlockedThreatName = "Crow (Mei Mei)"
                                        comboDropTime = tick() + Config.ComboDelay
                                        break
                                    end
                                end
                            elseif part.Name == "Rika" then
                                local aim = part:FindFirstChild("Aim")
                                local info = part:FindFirstChild("Info")
                                if aim and info then
                                    local inSkill = info:FindFirstChild("InSkill")
                                    local dist = (part.Position - myHRP.Position).Magnitude
                                    if inSkill and dist <= 20.0 then
                                        isThreatCurrentlyActive = true
                                        currentThreatInstance = partOwner and partOwner.Value or nil
                                        facePosition = part.Position
                                        lastBlockedThreatName = "Rika (Sustained InSkill)"
                                        comboDropTime = tick() + 1
                                        break
                                    end
                                end
                            elseif part.Name == "Rabbit" or string.find(part.Name, "Rabbit") then
                                local dist = (part.Position - myHRP.Position).Magnitude
                                if dist <= 36.6 then
                                    isThreatCurrentlyActive = true
                                    lastBlockedThreatName = "Active Rabbits"
                                    if rabbitCaster and rabbitCaster:FindFirstChild("HumanoidRootPart") then
                                        facePosition = rabbitCaster.HumanoidRootPart.Position
                                        currentThreatInstance = rabbitCaster
                                    else
                                        facePosition = part.Position
                                    end
                                    comboDropTime = tick() + Config.ComboDelay
                                    break
                                end
                            elseif part.Name == "Bullet" then
                                local speed = part.Velocity.Magnitude
                                local dist = (part.Position - myHRP.Position).Magnitude
                                if dist <= 120.0 and speed >= 15 then
                                    local toMeDir = (myHRP.Position - part.Position).Unit
                                    if part.Velocity.Unit:Dot(toMeDir) > 0.85 and (dist / speed) < 0.4 then
                                        isThreatCurrentlyActive = true
                                        lastBlockedThreatName = "Soulfire (Bullet)"
                                        facePosition = part.Position
                                        comboDropTime = tick() + Config.ComboDelay
                                        break
                                    end
                                end
                            elseif part.Name == "TongueGrab" then
                                local dist = (part.Position - myHRP.Position).Magnitude
                                if dist <= 36.6 then
                                    isThreatCurrentlyActive = true
                                    lastBlockedThreatName = "Toad (Tongue)"
                                    facePosition = part.Position
                                    comboDropTime = tick() + Config.ComboDelay
                                    break
                                end
                            elseif part.Name == "Totality" then
                                local tgt = part:FindFirstChild("Target")
                                if tgt then
                                    local isTargetMe = (tgt.Value == myChar) or (tostring(tgt.Value) == myChar.Name)
                                    if isTargetMe then
                                        isThreatCurrentlyActive = true
                                        lastBlockedThreatName = "Divine Dog (Sustained Fallback)"
                                        facePosition = part.PrimaryPart and part.PrimaryPart.Position or part.Position
                                        comboDropTime = tick() + Config.ComboDelay
                                        break
                                    end
                                end
                            elseif part.Name == "Reverse" and (part:IsA("BasePart") or part:IsA("Model")) then
                                local corePart = part:IsA("Model") and part.PrimaryPart or part
                                if corePart then
                                    local dist = (corePart.Position - myHRP.Position).Magnitude
                                    if dist <= 65.0 then
                                        isThreatCurrentlyActive = true
                                        lastBlockedThreatName = "Reverse Balls"
                                        facePosition = corePart.Position
                                        reverseBallLockTime = tick()
                                        reverseBallLock = true
                                        comboDropTime = tick() + Config.ComboDelay
                                        break
                                    end
                                end
                            elseif part.Name == "RedExplode" and part:IsA("BasePart") then
                                local dist = (part.Position - myHRP.Position).Magnitude
                                if dist <= 35 then
                                    isThreatCurrentlyActive = true
                                    lastBlockedThreatName = "Reversal Red Explosion"
                                    facePosition = part.Position
                                    comboDropTime = tick() + Config.ComboDelay + 0.50
                                    break
                                end
                            elseif part.Name == "LapseBlue" or part.Name == "Doors" or part.Name == "RoughEnergy" or part.Name == "Nue" or part.Name == "HammerL" or part.Name == "HammerR" or part.Name == "PebbleProjectile" or part.Name == "GavelThrow" or part.Name == "Ball" or part.Name == "ArmProjectile" or part.Name == "Swarm" or part.Name == "Barrage" or part.Name == "PiercingBlood" or part.Name == "ToadNue" or part.Name == "NueToad" then
                                local corePart = part:IsA("Model") and part.PrimaryPart or part
                                if corePart and corePart:IsA("BasePart") then
                                    local dist = (corePart.Position - myHRP.Position).Magnitude
                                    if dist <= (part.Name == "LapseBlue" and 36.6 or (part.Name == "Barrage" and 12 or 15)) then
                                        isThreatCurrentlyActive = true
                                        lastBlockedThreatName = "Dangerous Object (" .. part.Name .. ")"
                                        facePosition = corePart.Position
                                        comboDropTime = tick() + Config.ComboDelay
                                        break
                                    end
                                end
                            end
                        end
                    end
                else
                    CachedProjectiles[part] = nil
                end
            end
        end
    end

    -- 7. REVERSE BALLS ETERNAL LOCK BRIDGE
    -- Holds the block open while waiting for the projectile instance to spawn
    if not isThreatCurrentlyActive and reverseBallLock and Config.Blocks.Abilities then
        if tick() - reverseBallLockTime < 1.5 then
            isThreatCurrentlyActive = true
            lastBlockedThreatName = "Reverse Balls (Awaiting Part)"
            comboDropTime = tick() + Config.ComboDelay
        else
            reverseBallLock = false
        end
    end

    -- ==========================================
    -- FINAL EXECUTION: THE STEEL GATE
    -- Commands the server to actually raise or lower the shield based on logic above.
    -- ==========================================
    if isThreatCurrentlyActive or tick() <= comboDropTime then
        if facePosition then FaceTarget(facePosition) end
        
        if not isBlocking then
            isBlocking = true
            lastBlockedInstance = currentThreatInstance
            Config.Remotes.BlockActivate:FireServer(currentThreatInstance)
        end
    else
        if isBlocking then
            isBlocking = false
            currentThreatInstance = nil
            Config.Remotes.BlockDeactivate:FireServer()
        end
    end
end)
end

-- ON-SCREEN DEBUG HUD (opt-in via "Debug On Screen"): a tiny corner readout so you can confirm BF + Quake
-- fired without opening the F9 console. Shows the last flash + last quake with how long ago they happened.
task.spawn(function()
	local sg, lbl
	local function ensure()
		if sg and sg.Parent then return end
		sg = Instance.new("ScreenGui"); sg.Name = "\0"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 9600
		pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
		if not sg.Parent then sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
		local f = Instance.new("Frame"); f.Size = UDim2.fromOffset(250, 56); f.Position = UDim2.new(0, 12, 0.5, -28)
		f.BackgroundColor3 = Color3.fromRGB(18,18,18); f.BackgroundTransparency = 0.25; f.BorderSizePixel = 0; f.Parent = sg
		local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0,8); uc.Parent = f
		local us = Instance.new("UIStroke"); us.Color = Color3.fromRGB(226,46,58); us.Thickness = 1.2; us.Parent = f
		lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-12,1,-8); lbl.Position = UDim2.fromOffset(6,4)
		lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(240,240,240); lbl.Font = Enum.Font.Code
		lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.RichText = true; lbl.Parent = f
	end
	local function ago(t) if not t then return "never" end local d = tick()-t; if d < 1 then return "just now" end return string.format("%.0fs ago", d) end
	while true do
		if _G.VX_DEBUG_HUD then
			ensure()
			if lbl then
				local bf = _G.VX_BF_LAST_FIRE and (ago(_G.VX_BF_LAST_FIRE).." — ".._G.VX_BF_LASTMSG) or "no flash yet — M1 to test"
				local qk = _G.VX_QUAKE_LAST and (ago(_G.VX_QUAKE_LAST).." — ".._G.VX_QUAKE_LASTMSG) or "no quake yet — tap 3 to test"
				lbl.Text = "<b>BF:</b> "..bf.."\n<b>Quake:</b> "..qk
			end
			if sg then sg.Enabled = true end
			task.wait(0.2)
		else
			if sg then sg.Enabled = false end
			task.wait(0.4)
		end
	end
end)
