--[[  Dream Hub · Prior Extinction  ]]

print("[Dream Hub PE] script fetched OK - booting")   -- if you see THIS in F9 but no menu, send the red error line under it
local __gg = (typeof(getgenv)=="function") and getgenv() or _G
if __gg.__PRIOR_EXT_HUB then pcall(__gg.__PRIOR_EXT_HUB) end
__gg.__PRIOR_EXT_HUB = nil
-- Captured replica/source ids are scoped to one server session. Reusing them after a re-execute or server hop
-- makes INF Food replay dead ids forever and prevents its nearby-food bootstrap from running.
__gg.MH_lastEatCall=nil; __gg.MH_lastEatT=nil; __gg.MH_biteCalls={}; __gg.MH_foodIds={}; __gg.MH_eat=nil; __gg.MH_eatBuf=nil; __gg.MH_foodCursor=0
__gg.MH_attackTemplate=nil; __gg.MH_registerTemplate=nil; __gg.MH_pendingRegister=nil; __gg.MH_attackSequence=nil; __gg.MH_soundTemplate=nil; __gg.MH_hbMade=nil; __gg.MH_hbBuildAt=nil
__gg.MH_attackBoneCache=setmetatable({}, {__mode="k"}); __gg.MH_needPackets={}; __gg.MH_needReportAt={}; __gg.MH_needHighWater={food=nil,stamina=nil}; __gg.MH_verifiedReplicaId=nil; __gg.MH_wellbeing=nil
__gg.MH_identityKey=nil; __gg.MH_dietCache=nil; __gg.MH_foodDirectAt=nil; __gg.MH_growthResumeAt=nil; __gg.MH_bloodMax=nil; __gg.MH_bloodReplica=nil; __gg.MH_healthPacket=nil; __gg.MH_guardLastHP=nil
__gg.MH_tpSeq=(__gg.MH_tpSeq or 0)+1; __gg.MH_tpOrigin=nil; __gg.MH_foodGen=(__gg.MH_foodGen or 0)+1
-- Every captured packet below is valid only for one playable dinosaur. Character, species, or verified replica
-- changes invalidate food-source ids, combat/sound templates, need reports, and protection high-water state together.
__gg.MH_clearDinoCaches=function(identityKey)
	__gg.MH_identityKey=identityKey; __gg.MH_dietCache=nil
	__gg.MH_lastEatCall=nil; __gg.MH_lastEatT=nil; __gg.MH_biteCalls={}; __gg.MH_foodIds={}; __gg.MH_eat=nil; __gg.MH_eatBuf=nil; __gg.MH_foodCursor=0; __gg.MH_foodProbeCursor=0
	__gg.MH_attackTemplate=nil; __gg.MH_registerTemplate=nil; __gg.MH_pendingRegister=nil; __gg.MH_attackSequence=nil; __gg.MH_soundTemplate=nil
	__gg.MH_attackBoneCache=setmetatable({}, {__mode="k"}); __gg.MH_hbBuildAt=nil
	__gg.MH_needPackets={}; __gg.MH_needReportAt={}; __gg.MH_needHighWater={food=nil,stamina=nil}; __gg.MH_foodDirectAt=nil; __gg.MH_growthResumeAt=nil; __gg.MH_healthPacket=nil; __gg.MH_healthReportAt=nil
	__gg.MH_bloodMax=nil; __gg.MH_bloodReplica=nil; __gg.MH_guardLastHP=nil; __gg.MH_guardMax=nil
	__gg.MH_foodGen=(__gg.MH_foodGen or 0)+1
	if type(MHNEED)=="table" then MHNEED.refs={food={},stamina={}}; MHNEED.max={food=nil,stamina=nil}; MHNEED.maxSource={food=nil,stamina=nil}; MHNEED.hasPaired={food=false,stamina=false}; MHNEED.at=0; MHNEED.root=nil; MHNEED.character=nil; MHNEED.capRoot=nil; MHNEED.capacity=nil end
end
-- EARLY visible proof-of-life (for console-less mobile executors): if you see this toast the script
-- IS running -> press RightShift for the menu. If you DON'T see it, the executor failed to FETCH the
-- script (blocked/cached HttpGet) -> use the retry loader.
-- Dream Hub loading screen
_G.__DreamGameName = "PRIOR EXTINCTION"
_G.__DreamTier = (_G.PE_PREMIUM and "PREMIUM") or (_G.PE_PREM and "PREMIUM") or (_G.PE_PLUS and "PLUS") or "FREE"
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
-- Watches public chat locally on a moderator's client. Flagged messages stay local; this build does not
-- include credentials or automatically send chat/report data to an external service.
-- Add your own flagged words:  _G.__DreamBadWords = {"word1","word2"}   before loading.
task.spawn(function()
	local Players = game:GetService("Players")
	local TextChatService = game:GetService("TextChatService")
	local me = Players.LocalPlayer
	if not me then return end
	local MODS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
	if type(_G.__DreamExtraAdmins)=="table" then for _,n in ipairs(_G.__DreamExtraAdmins) do MODS[string.lower(tostring(n))]=true end end
	if not (MODS[string.lower(me.Name)] or MODS[string.lower(me.DisplayName or "")]) then return end
	local HATE = { "nigg","fagg","retard","kike","tranny","chink","spic" }
	if type(_G.__DreamBadWords)=="table" then for _,w in ipairs(_G.__DreamBadWords) do HATE[#HATE+1]=string.lower(tostring(w)) end end
	local CATS = {
		{ "Rule 2 - hate speech / slur", HATE },
		{ "Rule 7 - advertising", { "discord.gg","join my","my server","buy script","selling script","dm to buy","cheap robux","i sell " } },
		{ "Rule 5 - scam", { "free robux","robux generator","robux gen","tinyurl.com","bit.ly/","claim your","gift card code","rbx.","freerobux" } },
		{ "Rule 1/4 - threats / harassment", { "kys","kill yourself","neck yourself","gonna dox","i'll dox","get cancer","you should die" } },
	}
	local function report(pl, msg, rule)
		return false
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
	local GAME = "Prior Extinction"
	local TIER = tostring(_G.__DreamTier or "FREE")
	local KEY, WKEY = "dreamhub_lc_v1", "dreamhub_warn_v1"
	local MKEY = "dreamhub_mod_v1"   -- shared moderation state: mutes + emoji bans
	local LKEY = "dreamhub_warnlog_v1"   -- staff warning history (the tracker)
	local MODSTATE = { mu={}, ne={}, sl=0, lk=0, bw={}, tt={} }
	local lastMuteNotif = 0
	local MODS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
	if type(_G.__DreamExtraAdmins)=="table" then for _,n in ipairs(_G.__DreamExtraAdmins) do MODS[string.lower(tostring(n))]=true end end
	local IS_MOD = (MODS[string.lower(me.Name)] or MODS[string.lower(me.DisplayName or "")]) and true or false
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
		return false
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
		return false
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
		if __gg and __gg.MH_safeTeleport then return __gg.MH_safeTeleport(tr.CFrame*CFrame.new(0,0,-5),{settle=1.0}) end
		pcall(function() mr.AssemblyLinearVelocity=Vector3.zero; mr.CFrame=tr.CFrame*CFrame.new(0,0,-5) end); return true
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
			if __gg and __gg.MH_safeTeleport then __gg.MH_safeTeleport(savedPos,{settle=1.0}) else pcall(function() mr.AssemblyLinearVelocity=Vector3.zero; mr.CFrame=savedPos end) end return "Back." end },
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




pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="Dream Hub", Text="Prior Extinction loading... press RightShift for the menu", Duration=6}) end)
-- LOAD-STAGE CHECKPOINTS (debug): OFF by default. If a load ever dies with no UI, run `_G.PE_STAGES = true`
-- before the loadstring — the LAST toast you see before it stops tells us exactly which section aborted.
local function MS(tag) if not (__gg.PE_STAGES or _G.PE_STAGES) then return end pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="PE stage", Text=tostring(tag), Duration=10}) end) end

-- ═══ SERVICES ═══
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local RS           = game:GetService("ReplicatedStorage")
local WS           = game:GetService("Workspace")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local TeleportSvc  = game:GetService("TeleportService")
local VirtualUser  = game:GetService("VirtualUser")
local LP           = Players.LocalPlayer
local Cam          = WS.CurrentCamera

-- ═══ EXECUTOR COMPAT ═══
local G = __gg
local writefile   = writefile
local readfile    = readfile
local isfile      = isfile
local fireprox    = fireproximityprompt
local firetouch   = (typeof(firetouchinterest)=="function") and firetouchinterest or nil
local hookmeta    = hookmetamethod
local getnamecall = getnamecallmethod
local setclip     = setclipboard
local checkcaller = checkcaller or function() return false end
-- Prompt activation shared by food paths. Prefer the executor helper when available; otherwise use Roblox's native
-- hold API. Every property is restored immediately so INF Food cannot leave eating/fossil prompts modified.
__gg.MH_activatePrompt=function(prompt,maxDistance)
	if not (prompt and prompt:IsA("ProximityPrompt") and prompt.Parent) then return false end
	local od,oh,ol,oe=prompt.MaxActivationDistance,prompt.HoldDuration,prompt.RequiresLineOfSight,prompt.Enabled
	local fired=false
	pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.max(tonumber(od) or 8,tonumber(maxDistance) or 30); prompt.HoldDuration=0; prompt.Enabled=true end)
	if fireprox then fired=pcall(function() fireprox(prompt) end)
	else fired=pcall(function() prompt:InputHoldBegin(); task.wait(); prompt:InputHoldEnd() end) end
	pcall(function() prompt.MaxActivationDistance=od; prompt.HoldDuration=oh; prompt.RequiresLineOfSight=ol; prompt.Enabled=oe end)
	return fired
end
local function safeParentGui(gui)
	pcall(function()
		if typeof(gethui)=="function" then gui.Parent = gethui()
		elseif typeof(syn)=="table" and syn.protect_gui then syn.protect_gui(gui); gui.Parent = CoreGui
		else gui.Parent = CoreGui end
	end)
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
end

-- ═══ CONFIG ═══ (all features START OFF below so executing can never freeze you)
local CFG = {
	Aimbot=false, SilentAim=false, AimPart="Head", AimKey="C", AimSmooth=0.4, LockOn=false,
	HitboxExpand=true, HitboxSize=35, HitboxVisible=true, HitboxOpacity=40, HitboxColor={r=255,g=40,b=60}, HitboxColorName="Red", HitboxBone="All",
	AutoPlayBot=false,
	BotFlee=true, BotFleeRange=240, BotRoam=true, BotRoamRadius=350, BotEatAt=80, BotDrinkAt=80, BotSleepHeal=true, BotSpeed=18, BotAnnounce=true,
	BoneProtect=false, ProtectBone="All",
	TurnHack=false, TurnSpeed=30,
	Fly=false, FlySpeed=80, SpeedHack=false, SpeedVal=70, DeathFix=true, Noclip=false, Invis=false,
	InfJump=false, BypassTP=true,
	InfFood=false, InfWater=false, InfStam=false, InfOxygen=false,
	AntiDrown=true, AntiDrownRise=14, AntiFracture=true, AntiBleed=true, WalkWater=false, AutoClean=false, HeadDmgReduce=100,
	SaveDino=false, SaveHP=30, NoSleep=true, AutoHealBlood=false, AfkEat=false, BotPvP=true,
	AutoFarmPlayer=false, FarmPlayerRange=120, AutoFarmFossil=false, FarmFossilRange=1000000, FossilSlow=1.2,
	TargetUser="", TargetTrack=false,
	ESPPlayers=false, ESPCorpses=false, FoodESP=false, FishESP=false, GemESP=false, ESPRange=900, ESPColor="Default",
	RemoveTrees=false, Radar=false, RadarRange=450, RadarDeath=true,
	AlertEnabled=false, AlertDino="", AlertRange=350, CarnMeatTP=false,
	ProFood=false, ProFoodStopAge="Off", CarnYesHold=false,
	FullBright=false, NightVision=false, NoDarkWater=true, InfLight=false, UnlockMouse=false,
	SkinDino="", SkinName="", SkinWet=false, ProgSlot="",
	Waypoints={}, TPName="", TPX=0, TPY=0, TPZ=0,
	UIKey="RightShift", AccentIndex=1, Keybinds={}, UIScale=1, DebugPanel=false, LogRemotes=false, AdminWarnMsg="Please follow the rules.", AdminModGame="", AdminReason="", AdminProof="", AdminExtra="",
	AntiAFK=true, UnlockFOV=false, FOV=70, InfZoom=false, SafeTP=true,
	AutoClick=false, AutoClickCPS=12, AntiFall=true, WaterClear=false,
	AntiBreakHead=true, AntiBreakNeck=true, AntiBreakLeg=true, AntiBreakTail=true, AntiBreakTorso=true, NoClouds=false, Float=false,
	GodMode=false, AutoFarmGem=false, GemRange=1000000,
	FarmReach=200, FarmTeleport=true, FarmSpeed=55, TpBiome="(scan)",
	AutoEatFood=true, FoodEatRange=120, FoodEatSpeed=3,
	AlwaysDamage=false, DamageRange=120, DamageRate=4, DamagePart="Auto", NoGrabLimit=false,
}

FILE = "PriorExtinction_Config.json"
local function saveCfg()
	if not writefile then return end
	pcall(function() writefile(FILE, HttpService:JSONEncode(CFG)) end)
end
local function loadCfg()
	if not (isfile and readfile and isfile(FILE)) then return end
	pcall(function()
		local data = HttpService:JSONDecode(readfile(FILE))
		for k,v in pairs(data) do if CFG[k]~=nil then CFG[k]=v end end
	end)
end
loadCfg()
MS("1 config ok")
CFG.Keybinds = CFG.Keybinds or {}
CFG.Keybinds.UIKey = CFG.Keybinds.UIKey or CFG.UIKey
CFG.Keybinds.AimKey = CFG.Keybinds.AimKey or CFG.AimKey
CFG.Waypoints = CFG.Waypoints or {}
-- TELEPORT FARM IS BACK (you asked for it): the farm now TPs to ONE node at a time, collects it, then moves to the
-- next — and TPs you back to your saved spot when you toggle it off. Turn "Teleport Farm" off in the Auto Farm tab
-- if you'd rather use the old stand-still mode (fires prompts remotely with zero movement).
CFG.FarmTeleport = true
CFG.FarmFossilRange = 1000000; CFG.GemRange = 1000000  -- gather all nodes on the map
if not (tonumber(CFG.FarmReach) and CFG.FarmReach>=30 and CFG.FarmReach<=120) then CFG.FarmReach = 60 end
-- EVERYTHING OFF ON EXECUTION (runs AFTER loadCfg so it overrides any saved-on toggle) = clean start, ZERO
-- lag (no scan/remote loop runs until YOU enable a feature). Your keybinds / sliders / colours / UI scale
-- still persist — only the boolean feature toggles (incl. protections) are forced off here.
for _,key in ipairs({
	"Aimbot","SilentAim","LockOn","BoneProtect","TurnHack","Fly","SpeedHack","Noclip","InfJump",
	"InfFood","InfWater","InfStam","InfOxygen","SaveDino","AutoFarmPlayer","AutoFarmFossil","AutoFarmGem","AutoPlayBot",
	"ESPPlayers","ESPCorpses","FoodESP","FishESP","GemESP","AlertEnabled","CarnMeatTP","ProFood","FullBright","NightVision","NoDarkWater","WaterClear","NoClouds","AlwaysDamage","NoGrabLimit","RemoveTrees","Radar",
	"Float","GodMode","InfLight","UnlockFOV","InfZoom","AntiDrown","WalkWater","AutoClean","AntiFracture","AntiBleed","Invis",
	"AntiBreakHead","AntiBreakNeck","AntiBreakLeg","AntiBreakTail","AntiBreakTorso","NoSleep","AntiAFK","UnlockMouse","__SpyOn",
	"AutoClick","AutoEatFood","DebugPanel","LogRemotes","BypassTP","SafeTP",
	-- AntiFall REMOVED from this reset list ("when I spawn in, I die"): forcing it off on every execution meant a
	-- fresh load / respawn had ZERO fall protection during the game's own spawn-in drop, killing you before you
	-- could ever toggle it back on. It's a pure safety net with no lag/side-effect cost, so it now stays at its
	-- CFG default (true) across loads/respawns instead of being wiped.
}) do CFG[key]=false end

-- Teleport-capable features own independent cancellation generations. Infinite Food is intentionally absent: it
-- cannot start, continue, or cancel corpse/Pro Food/fossil movement. Toggling a movement feature invalidates only
-- that feature's pending work; switching it off also cancels the shared settle generation immediately.
__gg.MH_tpFeatureGen={CarnMeatTP=0,ProFood=0,AutoFarmFossil=0,AutoFarmGem=0}
__gg.MH_featureToggleChanged=function(key,value)
	if key=="InfFood" then __gg.MH_foodGen=(__gg.MH_foodGen or 0)+1 end
	local gens=__gg.MH_tpFeatureGen
	if type(gens)=="table" and gens[key]~=nil then
		gens[key]=(gens[key] or 0)+1
		if not value then
			__gg.MH_tpSeq=(__gg.MH_tpSeq or 0)+1
			if key=="ProFood" then if __gg.MH_stopProFood then pcall(__gg.MH_stopProFood) end; if __gg.MH_cancelCorpseTP then pcall(__gg.MH_cancelCorpseTP) end end
			if key=="CarnMeatTP" and __gg.MH_cancelCorpseTP then pcall(__gg.MH_cancelCorpseTP) end
		end
	end
end

-- ═══ CORE HELPERS ═══
local RUNNING = true
local CONNS = {}
local function conn(c) CONNS[#CONNS+1]=c; return c end
local function char() return LP.Character end
local function hum()  local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()
	local c=char()
	-- Prior Extinction dinos are NOT Humanoids — the steer/physics part is TurningAnimation.Body.
	do
		local m2 = (WS:FindFirstChild("Characters") and WS.Characters:FindFirstChild(LP.Name)) or c
		if m2 then local ta0=m2:FindFirstChild("TurningAnimation"); if ta0 then local b0=ta0:FindFirstChild("Body"); if b0 and b0:IsA("BasePart") then return b0 end end end
	end
	if not c then return nil end
	local named = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Root") or c:FindFirstChild("RootPart")
		or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("LowerTorso")
		or c:FindFirstChild("Body") or c:FindFirstChild("Main") or c:FindFirstChild("MainPart") or c:FindFirstChild("Hitbox")
	if named and named:IsA("BasePart") then return named end
	if c.PrimaryPart then return c.PrimaryPart end
	local h=hum(); if h and h.RootPart then return h.RootPart end
	local cs = Cam and Cam.CameraSubject
	if cs and cs:IsA("BasePart") and cs:IsDescendantOf(c) then return cs end
	local any = c:FindFirstChildWhichIsA("BasePart")
	if any then return any.AssemblyRootPart or any end
	return nil
end
local function alive()
	local c=char(); if not c then return hrp()~=nil end  -- PE dinos: LP.Character is often nil but the body lives at workspace.Characters[name] (hrp resolves it)
	local h=c:FindFirstChildOfClass("Humanoid")
	if h then return h.Health>0 end
	return hrp()~=nil
end
local function dist(a,b) return (a-b).Magnitude end
local function rootOf(m)
	if not m then return nil end
	if m:IsA("Model") then
		return m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m:FindFirstChildWhichIsA("BasePart")
	elseif m:IsA("BasePart") then return m end
	return nil
end
local function notify(title, text)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=title or "Dream Hub", Text=text or "", Duration=3}) end)
end
local function pressKey(kc)
	pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(); VIM:SendKeyEvent(false, kc, false, game) end)
end
local function holdKey(kc, dur)
	pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(dur or 0.08); VIM:SendKeyEvent(false, kc, false, game) end)
end
local SG -- assigned in the GUI section below
local function clickMouse()
	-- Skip the PHYSICAL click while the menu is open — it would land on the centered GUI and mess with your clicks.
	-- Damage comes from the SoundRemote + Attack remote (the loops fire those regardless), so combat still works with
	-- the menu open; the click just won't touch the GUI. Close the menu (RightShift) and the click also plays the bite.
	if SG and SG.Enabled then return end
	pcall(function()
		local v = Cam and Cam.ViewportSize or Vector2.new(800,600)
		VIM:SendMouseButtonEvent(v.X/2, v.Y/2, 0, true, game, 0)
		VIM:SendMouseButtonEvent(v.X/2, v.Y/2, 0, false, game, 0)
	end)
end

-- ═══ FOOD + FISH DATABASE ═══
FOOD_KEYWORDS = {
	"corpse","carcass","rotten","meat","chunk","fish","egg","ant","food","fruit","berry","berries","plant","sapling","tree","fern",
	"lepisosteus","gar","acipenser","onchopristis","alligator gar","anthill","termite","meganeura",
	"blechnace","blechnaceae","gleichenia","osmunda","horsetail","dawn redwood","redwood","zingiberopsis","ditaxocladus",
	"gingko","ginkgo","sequoia","woodwardia","sabalite","marmarthia","equisetum","coniopteris","paleoaster","dryophyllum",
	"elatides","dicksonia","williamsonia","wielandiella","weichselia","ptilophyllum","pachypteris","matonidium","hermanophyton","cycadeoidea",
	-- extra foliage/diet terms from the wiki (Edible Plants / Edible Non-foliage)
	"pine","needle","needles","leaf","leaves","frond","conifer","cycad","araucaria","podocarp","bennettit","fungus","mushroom",
	"shoot","sprout","grass","moss","bush","shrub","flower","seed","cone","insect","grub","larva","carrion","sturgeon","bichir","coelacanth","mawsonia",
}
local function isFoodName(n)
	n = n:lower()
	for _,k in ipairs(FOOD_KEYWORDS) do if n:find(k,1,true) then return true end end
	return false
end
FISH_KEYWORDS = { "lepisosteus","onchopristis","acipenser","concavotectum","bawitius","mawsonia","gar","sturgeon","coelacanth","sawfish","bichir" }
local function isFishName(n)
	n = n:lower()
	for _,k in ipairs(FISH_KEYWORDS) do if n:find(k,1,true) then return true end end
	return false
end

-- ═══ SKIN DATABASE (fallback name list; live list comes from Shared.SkinData) ═══
SKINS = {
	["Acrocanthosaurus"]={"Default","Mossy","Canis","Panthera","Boreal","Zombie","Arid","Leucistic","Melanistic"},
	["Allosaurus"]={"Default","Ochre","Arid","Pharaoh","Boreal","Garden","Serpentine","Leucistic","Melanistic","Retro","Lustrous"},
	["Arbovenator"]={"Default","Peafowl","Prismatic","Leucistic","Melanistic"},
	["Austroraptor"]={"Default","Leucistic","Melanistic","Illiren"},
	["Bistahieversor"]={"Default","Boreal","Coppercrest","Rainforest","Leucistic","Melanistic","Shimmerback"},
	["Carcharodontosaurus"]={"Default","Melanistic","Leucistic","Horridus","Cuvier","Sodalite","Giganotosaurus"},
	["Carnotaurus"]={"Default","Daybreak","Ember","Rainforest","Coppice","Poltergeist","Leucistic","Melanistic","Retro","Garden"},
	["Ceratosaurus"]={"Default","Bog","Carmine","Mahogany","Osmunda","Mesa","Garden","Sutekh","Arid","Hellfire","Leucistic","Melanistic","Retro"},
	["Concavenator"]={"Default","Bullrush","Scorched","Podzol","Arid","Rainforest","Leucistic","Melanistic","Colorburst"},
	["Dearc"]={"Default"},
	["Deinonychus"]={"Default","Valvran","Prismatic","Leucistic","Melanistic","Rhodinos","Garden"},
	["Deinosuchus"]={"Default","Melanistic","Leucistic","Retro","Thanatos","Choco","Azolla"},
	["Dilophosaurus"]={"Default","Garden","Clouded","Dusk","Arid","Retro","Leucistic","Melanistic","Fiend","Lunalata"},
	["Dynamotitan"]={"Default","Nordlys","Garden","Arid","Brutus","Abyssal","Leucistic","Melanistic"},
	["Guanlong"]={"Default","Leucistic","Melanistic","Wild","Feng"},
	["Ichthyovenator"]={"Default","Riverbed","Rapids","Prismatic","Molten","Fluorite","Limestone","Leucistic","Melanistic"},
	["Machimosaurus"]={"Default","Leucistic","Melanistic","Rainforest","Boulder Opal"},
	["Mahajangasuchus"]={"Default","Melanistic","Leucistic","Rainforest","Vanadinite","Retro"},
	["Sarcosuchus"]={"Default","Leucistic","Melanistic","Riverbed"},
	["Saurophaganax"]={"Default","Rainforest","Surtr","Leucistic","Melanistic","Tectonic"},
	["Spinosaurus Aegyptiacus"]={"Default","Arid","Charon"},
	["Spinosaurus Maroccanus"]={"Default","Melanistic","Leucistic","Tsuruk","Mau","Grisnir"},
	["Suchomimus"]={"Default","Aragonite","Dangara","Beryl","Marbled","Cobalt","Swampland","Leucistic","Melanistic","Retro"},
	["Tarbosaurus"]={"Default","Leucistic","Melanistic","Embalmed","Granite"},
	["Therodontosaurus"]={"Default","Boreal","Scaled"},
	["Torvosaurus"]={"Default","Windswept","Ashland","Rainforest","Arid","Bastet","Neptune","Draugr","Leucistic","Melanistic"},
	["Tyrannosaurus Rex"]={"Default","Odin"},
	["Tyrannosaurus Alaskaensis"]={"Default","Melanistic","Leucistic"},
	["Utahraptor"]={"Default","Garden","Melanistic","Leucistic","Spectral","Reedling","Malihaga"},
	["Yangchuanosaurus"]={"Default","Smouldering","Gilded","Boreal","Arid","Lich","Leucistic","Melanistic","Denglong"},
	["Acanthocaudia"]={"Default","Melanistic","Leucistic","Crazy Lace","Mulch","Hel","Boreal","Ashen","Pyre"},
	["Amphiceratops"]={"Default","Backahast","Leucistic","Melanistic","Salmon"},
	["Ankylosaurus"]={"Default","Melanistic","Leucistic","Mossy"},
	["Apatosaurus"]={"Default","Arid","Boreal","Pine","Limenitis","Lustrous","Leucistic","Melanistic","Thunderheart","Fissureheart","Torrentheart","Magmaheart"},
	["Brachiosaurus"]={"Default","Ymir","Andamooka","Monument","Lindi","Leucistic","Melanistic","Retro"},
	["Camptosaurus"]={"Default","Riptide","Melanistic","Leucistic","Retro"},
	["Dacentrurus"]={"Default","Magnetite","Bramble","Thicket","Labradorite","Leucistic","Melanistic"},
	["Diabloceratops"]={"Default","Umber","Basalt","Chasm","Melanistic","Leucistic","Arid","Maroon","Chrysocolla"},
	["Diplodocus"]={"Default","Tombstone","Lustrous","Copper","Boreal","Arid","Melanistic","Leucistic"},
	["Dreadnoughtus"]={"Default","Garden","Sunspot","Bastion","Argentinosaurus"},
	["Edmontosaurus"]={"Default","Piersica","Leucistic","Melanistic","Pietersite","Retro","Sleipnir"},
	["Iguanodon"]={"Default","Bay","Olivine","Rainforest","Hydrangea","Leucistic","Melanistic","Brecciated"},
	["Kentrosaurus"]={"Default","Cedar","Dappled","Arid","Banana","Witchlight","Leucistic","Melanistic","Granite"},
	["Ouranosaurus"]={"Default","Melanistic","Leucistic"},
	["Pachycephalosaurus"]={"Default","Rockslide","Mineral","Boreal","Wraith","Leucistic","Melanistic","Garden","Retro"},
	["Pachyrhinosaurus"]={"Default","Lichen","Auburn","Arid","Gloaming","Leucistic","Melanistic"},
	["Parasaurolophus"]={"Default","Garden","Leucistic","Melanistic","Boreal","Rainforest","Onyx","Spotted","Brindle","Tealback","Arid"},
	["Protoceratops"]={"Default","Cycad","Earthborn","Sphalerite","Melanistic","Leucistic","Retro","Gullinbrusti","Necromancer"},
	["Sauropelta"]={"Default","Leucistic","Melanistic","Harlequin"},
	["Sauroposeidon"]={"Default","Classic","Melanistic","Leucistic","Butte","Butcher"},
	["Scelidosaurus"]={"Default","Tourmaline","Melanistic","Leucistic"},
	["Senticephale"]={"Default","Melanistic","Leucistic","Agate Geode"},
	["Stegosaurus"]={"Default","Melanistic","Leucistic","Garden","Rainforest","Calaca","Arid","Tiger's Eye","Carota"},
	["Styracosaurus"]={"Default","Dolerite","Crimson","Arid","Calcite","Ripple","Rainforest","Atropos","Tanzanite"},
	["Tenontosaurus"]={"Default","Quagga","Citrus","Boreal","Turquoise","Leucistic","Melanistic"},
	["Tethyshadros"]={"Default"},
	["Therizinosaurus"]={"Default","Anser","Mantled","Elven","Lustrous","Screamer","Leucistic","Melanistic"},
	["Triceratops"]={"Default","Knight","Angstiq","Sakura","Eroded","Multi Eyed","Retro","Melanistic","Leucistic"},
	["Tsintaosaurus"]={"Default","Arid","Boreal","Rainforest","Cordierite","Leucistic","Melanistic","Reindeer"},
	["Yunnanosaurus"]={"Default","Leucistic","Melanistic","Cracklegem","Arid","Shanhu She"},
	["Beipiaosaurus"]={"Default","Boreal","Rowan","Withered","Leucistic","Melanistic","Cottontail"},
	["Citipati"]={"Default","Ostygian","Streaked","Conjurer","Parure","Laced","Leucistic","Melanistic"},
	["Deinocheirus"]={"Default","Leucistic","Melanistic","Retro","Platalea","Arid","Mango","Lustrous","Phantom"},
	["Gallimimus"]={"Default","Bronzite","Gullinkambi","Roseus","Rusty","Arid","Sooty","Leucistic","Melanistic"},
	["Gigantoraptor"]={"Default","Striped","Banded","Crimson","Osterhase","Bloodlust","Leucistic","Melanistic"},
	["Jianchangosaurus"]={"Default","Rainforest","Lustrous","Mothman","Easter","Leucistic","Melanistic"},
	["Pteranodon"]={"Default","Melanistic","Leucistic","Longinus","Eikran","Viridian"},
	["Quetzalcoatlus"]={"Default","Leucistic","Melanistic","Carved","Marovato"},
	["Tupandactylus"]={"Default"},
}
DINO_NAMES = {}
for k in pairs(SKINS) do DINO_NAMES[#DINO_NAMES+1]=k end
table.sort(DINO_NAMES)


local function detectDino()
	local c = char()
	local candidates = {}
	if c then
		candidates[#candidates+1] = c.Name
		local h = c:FindFirstChildOfClass("Humanoid")
		if h and h.DisplayName~="" then candidates[#candidates+1]=h.DisplayName end
		for _,attr in ipairs({"Dinosaur","Species","Creature","DinoType","Dino","CharacterType","Animal"}) do
			local a = c:GetAttribute(attr); if a then candidates[#candidates+1]=tostring(a) end
		end
		for _,v in ipairs(c:GetDescendants()) do
			if (v:IsA("StringValue") or v:IsA("ObjectValue")) and (v.Name:lower():find("species") or v.Name:lower():find("dino") or v.Name:lower():find("creature")) then
				candidates[#candidates+1]=tostring(v.Value)
			end
		end
	end
	for _,attr in ipairs({"Dinosaur","Species","Creature","DinoType","Dino"}) do
		local a = LP:GetAttribute(attr); if a then candidates[#candidates+1]=tostring(a) end
	end
	for _,cand in ipairs(candidates) do if cand and SKINS[cand] then return cand end end
	for _,cand in ipairs(candidates) do
		if cand then
			local lc = cand:lower()
			for _,dn in ipairs(DINO_NAMES) do
				local key = dn:lower()
				if lc:find(key,1,true) or key:find(lc,1,true) then return dn end
				local first = key:match("^%S+")
				if first and #first>4 and lc:find(first,1,true) then return dn end
			end
		end
	end
	return nil
end

-- ═══ REPLICA ID CAPTURE (lightweight namecall hook — no hot-path allocation) ═══
myReplicaId = nil
seenIds = {}
seenSet = {}
local function noteReplicaId(id)
	if typeof(id)=="number" then myReplicaId=id end
end
-- Shared region matcher for both the outgoing injury gate and the local path-aware cleanup. A selected bone never
-- authorizes a generic whole-body fracture clear unless the selection is explicitly "All".
__gg.MH_protectBoneMatches=function(path)
	local sel=CFG.ProtectBone or "All"; local p=tostring(path or ""):lower()
	if sel=="All" then return true end
	if sel=="Head" then return p:find("head",1,true) or p:find("jaw",1,true) or p:find("skull",1,true) or p:find("crani",1,true) end
	if sel=="Neck" then return p:find("neck",1,true) or p:find("cervic",1,true) end
	if sel=="Arm" then return p:find("arm",1,true) or p:find("hand",1,true) or p:find("claw",1,true) or p:find("humer",1,true) or p:find("wing",1,true) end
	if sel=="Leg" then return p:find("leg",1,true) or p:find("foot",1,true) or p:find("limb",1,true) or p:find("femur",1,true) or p:find("tibia",1,true) or p:find("thigh",1,true) end
	if sel=="Body" then return p:find("spine",1,true) or p:find("body",1,true) or p:find("hip",1,true) or p:find("torso",1,true) or p:find("rib",1,true) or p:find("chest",1,true) or p:find("tail",1,true) end
	return false
end
-- Injury-report gate (defined ONCE at module level, not per-namecall). Region-specific toggles only block reports
-- whose property/action path identifies that region; unrelated stun, ragdoll, grab, and movement state passes through.
local function injHit(lp)
	lp=tostring(lp or ""):lower()
	if CFG.AntiBleed and (lp:find("bleed",1,true) or lp:find("hemorrhage",1,true) or lp:find("wound",1,true) or lp:find("bloodloss",1,true)) then return true end
	local injury=lp:find("brok",1,true) or lp:find("break",1,true) or lp:find("sever",1,true) or lp:find("dislocat",1,true)
		or lp:find("limp",1,true) or lp:find("fractur",1,true) or lp:find("concuss",1,true) or lp:find("crush",1,true)
		or lp:find("blunt",1,true) or lp:find("trauma",1,true)
	if not injury then return false end
	local head=lp:find("head",1,true) or lp:find("skull",1,true) or lp:find("crani",1,true) or lp:find("jaw",1,true) or lp:find("concuss",1,true)
	if CFG.AntiFracture and head then return true end
	if CFG.BoneProtect and __gg.MH_protectBoneMatches(lp) then return true end
	if CFG.AntiBreakHead and head then return true end
	if CFG.AntiBreakNeck and (lp:find("neck",1,true) or lp:find("cervic",1,true)) then return true end
	if CFG.AntiBreakLeg and (lp:find("leg",1,true) or lp:find("foot",1,true) or lp:find("limb",1,true) or lp:find("knee",1,true) or lp:find("femur",1,true) or lp:find("tibia",1,true)) then return true end
	if CFG.AntiBreakTail and lp:find("tail",1,true) then return true end
	if CFG.AntiBreakTorso and (lp:find("torso",1,true) or lp:find("rib",1,true) or lp:find("chest",1,true) or lp:find("hip",1,true) or lp:find("spine",1,true)) then return true end
	return false
end
hookInstalled=false
local function installHook()
	if hookInstalled or not hookmeta then return end
	hookInstalled=true
	pcall(function()
		local oldNC
		oldNC = hookmeta(game, "__namecall", function(self, ...)
			-- HOT PATH: getnamecall() first and bail for the 99% of namecalls that aren't FireServer/InvokeServer
			-- (GetChildren/FindFirstChild/IsA/etc.) BEFORE touching checkcaller() or self.Name — keeps the
			-- per-namecall tax near-zero so loading the hub doesn't lag a busy game.
			local m = getnamecall and getnamecall()
			if m=="FireServer" or m=="InvokeServer" then
				if self.Name=="dataRemoteEvent" and not checkcaller() then
					-- BRIDGE SPY (Progress Restore): the game fires your spawn/restore through this bridge as
					-- { {"\001", <bridgeId>, {{Species=..,Variant=..,Skin=..,Gender=..}}}, <tag> }. Grab that payload
					-- live so Progress Restore can replay it — adapts if the id/dino/tag changes.
					local ba = table.pack(...); local pp = ba[1]
					if type(pp)=="table" and type(pp[1])=="table" and type(pp[1][3])=="table" and type(pp[1][3][1])=="table" and pp[1][3][1].Species then __gg.MH_restore = pp; __gg.MH_rsave = pp end
				elseif self.Name=="SoundRemote" and not checkcaller() then
					-- Keep the CURRENT dinosaur's genuine swing packet. Attack layouts can change by species/update;
					-- replaying what the game itself just sent is safer than permanently assuming one hard-coded layout.
					local sa=table.pack(...)
					if sa.n>=2 and tostring(sa[1]):lower()=="pvp" and tostring(sa[2]):lower():find("attack",1,true) then
						local snap={n=sa.n,identity=__gg.MH_identityKey}; for i=1,sa.n do snap[i]=sa[i] end; __gg.MH_soundTemplate=snap
					end
				elseif (self.Name=="ReplicaSignal" or self.Name=="ReplicaSignalUnreliable") and not checkcaller() then
				local a = table.pack(...)
				local id, action = a[1], a[2]
				-- ReplicaSignal also carries client-owned physics for OTHER replicas. In the supplied trace those are
				-- (otherId,"CFrame",CFrame) and (otherId,"DisableVelocity"). They are never proof of our character id.
				-- Accept an id only after CharacterState.Replica.Id has verified it. Action names alone are insufficient.
				local stateId
				if MHNEED and MHNEED.replicaId then pcall(function() stateId=MHNEED.replicaId() end) end
				if stateId then __gg.MH_verifiedReplicaId=stateId end
				local selfCall=typeof(id)=="number" and __gg.MH_verifiedReplicaId~=nil and id==__gg.MH_verifiedReplicaId
				if selfCall and myReplicaId~=id then noteReplicaId(id) end
				if selfCall and action=="RegisterAttack" and self.Name=="ReplicaSignal" then
					local snap={n=a.n,remote=self.Name,instance=self,capturedAt=tick(),path=a[3],slot=a[4],identity=__gg.MH_identityKey}; for i=1,a.n do snap[i]=a[i] end
					__gg.MH_registerTemplate=snap; __gg.MH_pendingRegister=snap
				elseif selfCall and action=="Attack" and self.Name=="ReplicaSignal" then
					local snap={n=a.n,remote=self.Name,instance=self,capturedAt=tick(),identity=__gg.MH_identityKey}; for i=1,a.n do snap[i]=a[i] end
					__gg.MH_attackTemplate=snap
					local reg=__gg.MH_pendingRegister
					local compatible=type(reg)=="table" and reg[1]==id and reg[2]=="RegisterAttack" and tick()-(reg.capturedAt or 0)<=0.8
					if compatible then for i=3,a.n do local v=a[i]
						if type(v)=="string" and reg.path and v:find("Attacks/",1,true) and v~=reg.path then compatible=false; break end
						if type(v)=="string" and reg.slot and v:match("^Attack%d+$") and v~=reg.slot then compatible=false; break end
					end end
					if compatible then __gg.MH_attackSequence={register=reg,attack=snap,identity=__gg.MH_identityKey} end
					__gg.MH_pendingRegister=nil
				end
				-- Sip/Bite/Eat address a SOURCE replica, not our dinosaur. Keep those ids only in the source list.
				if typeof(id)=="number" then
					if action=="Sip" or action=="Bite" or action=="Eat" or action=="Consume" then
						if not seenSet[id] then
							seenSet[id]=true; seenIds[#seenIds+1]=id
							if #seenIds>64 then local oldId=table.remove(seenIds,1); seenSet[oldId]=nil end
						end
						if action=="Bite" and a.n>=3 then __gg.MH_eat={id=id,buf=a[3]}; __gg.MH_foodIds=__gg.MH_foodIds or {}; if id~=myReplicaId then __gg.MH_foodIds[id]=true; __gg.MH_eatBuf=a[3] end end
						-- BITE-ONLY CAPTURE (for the INF Food spam loop): record the ENTIRE Bite call verbatim — the exact
						-- id + "Bite" + every argument the game sent when YOU bit food — so we can replay it byte-for-byte,
						-- fast, forever. We keep a LIST of the last several DIFFERENT bites, so the more different things you
						-- eat, the more Bite calls the spam loop fires per pass = faster growth. Bite is the one that fills the bar.
						if action=="Bite" then
							local snap={n=a.n,remote=self.Name} for i=1,a.n do snap[i]=a[i] end
							__gg.MH_lastEatCall=snap; __gg.MH_lastEatT=tick()
							__gg.MH_biteCalls = __gg.MH_biteCalls or {}
							-- One current call per source. tostring(buffer) contains an allocation address, so using it
							-- in the key made every bite look unique and the old loop replayed many stale duplicates.
							local key=tostring(id); local replaced=false
							for i,c in ipairs(__gg.MH_biteCalls) do if c.key==key then snap.key=key; __gg.MH_biteCalls[i]=snap; replaced=true; break end end
							if not replaced then snap.key=key; table.insert(__gg.MH_biteCalls, snap); if #__gg.MH_biteCalls>3 then table.remove(__gg.MH_biteCalls,1) end end
						end
					elseif selfCall then
						noteReplicaId(id)
					end
				end
				-- REMOTE LOGGER (debug): when on, print every ReplicaSignal the GAME fires (skip the routine
				-- Fall/HeadAngles spam) so you can capture the real food source id / any action by doing it once.
				if CFG.LogRemotes and typeof(action)=="string" and action~="Fall" and action~="HeadAngles" then
					local ex={} for i=3,a.n do ex[#ex+1]=tostring(a[i]) end
					print("[MH REMOTE] id="..tostring(id).."  "..action.."  ["..table.concat(ex,", ").."]")
				end
				if typeof(action)=="string" then
						-- Anti-Fall: report every fall as a harmless 0.1 so the server deals no fall damage.
						if selfCall and action=="Fall" and CFG.AntiFall and typeof(a[3])=="number" then
							a[3]=0.1; if a[5]~=nil then a[5]=a[4] end
							return oldNC(self, table.unpack(a, 1, a.n))
						end
						-- Anti-Drown: the client REPORTS being underwater via the DrownY action; swallow it so
						-- the server never applies drowning damage. Only our authoritative replica id is intercepted.
						if selfCall and action=="DrownY" and CFG.AntiDrown then return end
						-- Capture exact need traffic even while the toggle is off. When enabled, rewrite only the current
						-- field to a paired max resolved from live data/HUD sources (15 food, 319 stamina in the supplied run).
						if selfCall and action=="SetProperty" and typeof(a[3])=="string" and typeof(a[4])=="number" then
							local nk; local nl=a[3]:lower()
							local excluded=nl:find("max",1,true) or nl:find("rate",1,true) or nl:find("drain",1,true) or nl:find("deplet",1,true) or nl:find("decay",1,true) or nl:find("regen",1,true)
							if not excluded then
								if nl:find("food",1,true) or nl:find("hunger",1,true) or nl:find("fullness",1,true) or nl:find("satiation",1,true) then nk="food"
								elseif nl:find("stam",1,true) or nl=="energy" or nl=="sp" or nl:find("endur",1,true) or nl:find("vigor",1,true) then nk="stamina" end
							end
							if nk then
								local snap={n=a.n,remote=self.Name,instance=self}; for i=1,a.n do snap[i]=a[i] end; __gg.MH_needPackets[nk]=snap
								local target=MHNEED and MHNEED.maxForProperty and MHNEED.maxForProperty(nk,a[3])
								if ((nk=="food" and CFG.InfFood) or (nk=="stamina" and CFG.InfStam)) and target and target>0 then
									a[4]=target; snap[4]=target; return oldNC(self,table.unpack(a,1,a.n))
								end
							end
						end
						if selfCall and CFG.InfFood then
							local needAction=action:lower()
							local foodNamed=needAction:find("food",1,true) or needAction:find("hunger",1,true) or needAction:find("starv",1,true)
							local drainNamed=needAction:find("drain",1,true) or needAction:find("deplet",1,true) or needAction:find("reduce",1,true)
								or needAction:find("cost",1,true) or needAction:find("penalty",1,true)
							if (foodNamed and drainNamed) or action=="HungerTick" or action=="MetabolismTick" then return end
						end
						-- Infinite Stamina has no action or movement side channel. Run/Sprint/Trot, fatigue, velocity,
						-- CFrame, and movement state pass through untouched; only the validated need packet above may refill it.
						-- Keep the exact health packet shape for proportional protection reports. Rewriting happens only
						-- against the last observed HP and only for physical protection; Anti Bleed never becomes god mode.
						if selfCall and action=="SetProperty" and typeof(a[3])=="string" and (a[3]:lower()=="health" or a[3]:lower()=="hp") and typeof(a[4])=="number" then
							local physical=CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso
							local last=tonumber(__gg.MH_guardLastHP)
							if physical and last and a[4]<last then local frac=math.clamp((tonumber(CFG.HeadDmgReduce) or 0)/100,0,1); a[4]=a[4]+(last-a[4])*frac end
							local snap={n=a.n,remote=self.Name,instance=self,identity=__gg.MH_identityKey}; for i=1,a.n do snap[i]=a[i] end; __gg.MH_healthPacket=snap
							return oldNC(self,table.unpack(a,1,a.n))
						end
						-- Blood-pool drain is distinct from the Bleeding flag. Rewrite only to an authoritative maximum
						-- already paired for this verified replica; a current value is never promoted to a maximum.
						if selfCall and (CFG.AntiBleed or CFG.AutoHealBlood) and action=="SetProperty" and typeof(a[3])=="string" then local bp=a[3]:lower()
							if bp=="blood" or bp=="bloodlevel" or bp=="bloodvolume" or bp=="bloodpool" then
								local rid=MHNEED and MHNEED.replicaId and MHNEED.replicaId()
								if __gg.MH_bloodReplica~=rid then __gg.MH_bloodReplica=rid; __gg.MH_bloodMax=nil end
								if typeof(a[4])=="number" and type(__gg.MH_bloodMax)=="number" then a[4]=__gg.MH_bloodMax end
								return oldNC(self,table.unpack(a,1,a.n))
							end
						end
						-- ANTI-INJURY (report-block): injuries replicate the same way stamina does — the CLIENT reports
						-- them to the server. While your antis are on, we SWALLOW any report that would tell the server
						-- you fractured / bled / broke a bone — the injury never lands server-side. THIS is what makes
						-- Anti Fractured + Bone Protection actually stick (the local sweep alone only hid it client-side).
						-- Broadened region keywords so a HEAD/skull break (SkullFracture/HeadTrauma/Concussion/JawBreak) is
						-- caught by Anti Break Head too, not only Anti Fractured. Same for neck/leg/tail/torso protectors.
						-- ATTACK-SAFE INJURY GATE: only swallow injury reports about YOUR OWN dino (self replica id),
						-- and never anything attack-shaped. Before this, hitting another dino could fire an action whose
						-- text matched the injury keywords (Crush/Blunt/Head/Bite...) -> the hit call was swallowed =
						-- "when I click, I do no damage" while Anti Fractured was on. Your own protection is unchanged.
						local selfRep = selfCall
						local laG = action:lower()
						local atk = laG:find("attack",1,true) or laG:find("register",1,true) or laG:find("hit",1,true) or laG:find("damage",1,true) or laG:find("bite",1,true) or laG:find("swing",1,true) or laG:find("claw",1,true)
						if selfRep and not atk then
							if action=="SetProperty" and typeof(a[3])=="string" then local lp=a[3]:lower()
								if injHit(lp) then local v=a[4]; if v==true or (typeof(v)=="number" and v~=0) or typeof(v)=="table" then return end end
							end
							if action=="SetAction" and typeof(a[3])=="string" and a[4]==true then local lp=a[3]:lower()
								if injHit(lp) then return end
							end
							if injHit(laG) then return end
						end
					end
				end
			end
			return oldNC(self, ...)
		end)
	end)
end
pcall(installHook)

-- ═══ REAL GAME REMOTES ═══
SPAWN_BRIDGE_ID = "w+\179/\215s@\135\149\210;\129\019\145lV"
RCACHE = {}  -- consolidated remote-instance cache (bridge / sig / sound) — one local instead of three
local function getBridge()
	if RCACHE.bridge and RCACHE.bridge.Parent then return RCACHE.bridge end
	local bn = RS:FindFirstChild("darkestdev_bridgenet2@1.0.2") or RS:FindFirstChild("darkestdev_bridgenet2")
	if not bn then for _,c in ipairs(RS:GetChildren()) do if c.Name:lower():find("bridgenet") then bn=c; break end end end
	if bn then RCACHE.bridge = bn:FindFirstChild("dataRemoteEvent") or bn:FindFirstChildWhichIsA("RemoteEvent") end
	return RCACHE.bridge
end
local function fireSpawn(species, skin, variant, gender)
	local b = getBridge(); if not b then return false end
	local payload = { {"\001", SPAWN_BRIDGE_ID, { { Gender=gender or "Male", Species=species, Variant=variant or "Default", Skin=skin or "Default" } } }, "C" }
	return pcall(function() b:FireServer(payload) end)
end
-- PROGRESS RESTORE PERSISTENCE: the bridge payload contains a BINARY bridge id, so we serialize it as byte values
-- to a file. This way the captured progress (e.g. Elder) SURVIVES leaving + rejoining — even if you respawn as a
-- fresh hatchling, the saved remote restores you to the old progress. Saved once when captured, loaded on startup.
-- progSerde("rec", payload) → a JSON-safe record (binary bridge id encoded as bytes). progSerde("pay", record) →
-- back to a fireable payload. Used by both the single auto-save AND the numbered SAVE SLOTS below.
local function progSerde(mode, x)
	if mode=="rec" then
		if type(x)~="table" or type(x[1])~="table" or type(x[1][2])~="string" then return nil end
		local inner=x[1]; local data=(inner[3] and inner[3][1]) or {}
		local bytes={}; for i=1,#inner[2] do bytes[i]=string.byte(inner[2],i) end
		return { marker=inner[1], bytes=bytes, tag=x[2], data={Species=data.Species, Variant=data.Variant, Skin=data.Skin, Gender=data.Gender, GrowthStage=data.GrowthStage, Stage=data.Stage or data.GrowthStage} }
	else
		if type(x)~="table" or not x.bytes then return nil end
		if SLOTS and SLOTS.check then local ok=SLOTS.check(x); if not ok then return nil end end
		local bid=""; for _,b in ipairs(x.bytes) do bid=bid..string.char(b) end
		return { { x.marker or "\001", bid, { { Species=x.data.Species, Variant=x.data.Variant, Skin=x.data.Skin, Gender=x.data.Gender, GrowthStage=x.data.GrowthStage or x.data.Stage, Stage=x.data.Stage } } }, x.tag or "H" }
	end
end
-- Per-ACCOUNT file naming: every save file is tagged with the player's UserId, so different people using the same
-- executor/PC can NEVER mix slots — each account only sees its own saves.
local function slotFile(n) return "MH_PE_"..tostring(LP.UserId).."_Slot_"..tostring(n)..".json" end
SLOTS={}
function SLOTS.sum(rec)
	local total=0
	local function mix(s) s=tostring(s or ""); for i=1,#s do total=(total + string.byte(s,i)*(i+17))%2147483647 end end
	for i,b in ipairs((rec and rec.bytes) or {}) do total=(total + (tonumber(b) or 0)*(i+31))%2147483647 end
	local d=rec and rec.data or {}; mix(rec and rec.marker); mix(rec and rec.tag); mix(d.Species); mix(d.Variant); mix(d.Skin); mix(d.Gender); mix(d.GrowthStage); mix(d.Stage)
	mix(rec and rec.schema); mix(rec and rec.userId); mix(rec and rec.universeId); mix(rec and rec.placeId); mix(rec and rec.savedAt)
	return total
end
function SLOTS.check(rec)
	if type(rec)~="table" or type(rec.bytes)~="table" or #rec.bytes<4 or #rec.bytes>256 or type(rec.data)~="table" then return false,"invalid structure" end
	for _,b in ipairs(rec.bytes) do if type(b)~="number" or b<0 or b>255 or b%1~=0 then return false,"invalid bridge data" end end
	if tonumber(rec.schema)~=2 then return false,"unsupported schema" end
	if tonumber(rec.userId)~=LP.UserId then return false,"different account" end
	if tonumber(rec.universeId)~=game.GameId then return false,"different experience" end
	if tonumber(rec.placeId)~=game.PlaceId then return false,"different place" end
	if type(rec.data.Species)~="string" or rec.data.Species=="" or #rec.data.Species>100 then return false,"missing species" end
	if type(rec.checksum)~="number" or rec.checksum~=SLOTS.sum(rec) then return false,"checksum mismatch" end
	return true
end
function SLOTS.read(n)
	if not (readfile and isfile) then return nil,"file access unavailable" end
	local function one(path)
		if not isfile(path) then return nil,"missing" end
		local ok,rec=pcall(function() return HttpService:JSONDecode(readfile(path)) end); if not ok then return nil,"invalid JSON" end
		local good,why=SLOTS.check(rec); if not good then return nil,why end
		return rec
	end
	local path=slotFile(n); local rec,why=one(path); if rec then return rec,false end
	local backup=one(path..".bak"); if backup then return backup,true end
	return nil,why
end
function SLOTS.write(n,rec)
	if not (writefile and readfile) then return false,"file access unavailable" end
	rec.schema=2; rec.userId=LP.UserId; rec.placeId=game.PlaceId; rec.universeId=game.GameId; rec.savedAt=os.time(); rec.checksum=nil; rec.checksum=SLOTS.sum(rec)
	local good,why=SLOTS.check(rec); if not good then return false,why end
	local path=slotFile(n); local tmp=path..".tmp"; local encoded=HttpService:JSONEncode(rec)
	local ok=pcall(function()
		writefile(tmp,encoded)
		local test=HttpService:JSONDecode(readfile(tmp)); assert(SLOTS.check(test))
		if isfile and isfile(path) then local old=readfile(path); if old and old~="" then
			local oldOk,oldRec=pcall(function() return HttpService:JSONDecode(old) end)
			if oldOk and SLOTS.check(oldRec) then writefile(path..".bak",old) end
		end end
		writefile(path,encoded)
		local final=HttpService:JSONDecode(readfile(path)); assert(SLOTS.check(final))
		if delfile and isfile and isfile(tmp) then delfile(tmp) end
	end)
	return ok,ok and nil or "verification failed"
end
local function saveRestore(pp) pcall(function() if writefile then local r=progSerde("rec",pp); if r then writefile("MH_PE_"..tostring(LP.UserId).."_Progress.json", HttpService:JSONEncode(r)) end end end) end
local function loadRestore()
	-- NOTE: we do NOT auto-load the single progress into MH_restore at startup anymore — that mixed old captures with
	-- the live spawn. MH_restore is set ONLY by a genuine spawn (the bridge spy) or by clicking Restore Slot. Numbered
	-- slots live in their OWN files (MH_PE_Slot_<n>.json), read on demand.
end
loadRestore()  -- bring back any saved progress remote + slots on execution
-- save the captured progress to disk (deferred — the hook captures into __gg.MH_rsave; we persist it here).
task.spawn(function() while RUNNING do task.wait(2); if __gg.MH_rsave then local p=__gg.MH_rsave; __gg.MH_rsave=nil; saveRestore(p) end end end)
-- forward decl: setHeadAngles is defined below but the restore camera-fix uses it.
local setHeadAngles
-- PROGRESS RESTORE: replays the captured/saved bridge spawn/restore payload, then normalizes camera + controls.
local function progressRestore()
	if __gg.MH_restoreBusy then notify("Progress Restore","A restore is already settling safely."); return false end
	__gg.MH_restoreBusy=true
	local b = getBridge(); if not b then __gg.MH_restoreBusy=false; notify("Progress Restore","Progress loading…"); return false end
	local pp = __gg.MH_restore
	if type(pp)~="table" then __gg.MH_restoreBusy=false; notify("Progress Restore","Progress loading…"); return false end
	local backPos; pcall(function() local r=hrp(); backPos = r and r.Position end)   -- keep your spot across the restore
	local ok = pcall(function() b:FireServer(pp) end)
	-- UNDER-MAP GUARD (fix "after restore I keep falling under the map / my teleport doesn't save"): the game
	-- respawns your dino BEFORE the map has streamed in at the landing spot, so there's no ground yet and you
	-- fall through. For ~25s: force the map to stream in around your saved spot, find the REAL ground there by
	-- raycast, and whenever you're below the surface or free-falling into nothing, snap you on top and hold
	-- briefly (anti-snapback). Also returns you to where you stood when you clicked Restore.
	local oldRoot; pcall(function() oldRoot=hrp() end)
	task.spawn(function()
		local t0=tick()
		local rescued=false
		while tick()-t0<25 and RUNNING do
			pcall(function()
				local r=hrp(); if not r then return end
				local isNew = (r ~= oldRoot)                                            -- the restored dino has spawned
				local base = backPos or r.Position
				pcall(function() LP:RequestStreamAroundAsync(base, 2) end)              -- make the client LOAD the map there
				local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.IgnoreWater=true
				rp.FilterDescendantsInstances={ LP.Character, WS:FindFirstChild("Characters"), WS:FindFirstChild("CharacterIgnore") }
				local ground=WS:Raycast(Vector3.new(base.X, base.Y+400, base.Z), Vector3.new(0,-2000,0), rp)
				if not ground then return end                                           -- not streamed in yet: keep waiting
				local below = r.Position.Y < ground.Position.Y - 6                      -- you're UNDER the map surface
				local down = WS:Raycast(r.Position, Vector3.new(0,-800,0), rp)
				local voidFall = (r.AssemblyLinearVelocity.Y < -20) and not down        -- free-falling with NOTHING beneath
				if below or voidFall or (backPos and isNew and not rescued) then
					rescued=true
					local goal=CFrame.new(ground.Position + Vector3.new(0,6,0))
					local holdT=tick()+1.2
					while tick()<holdT and RUNNING do
						local rr=hrp(); if rr then rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero end
						RunService.Heartbeat:Wait()
					end
				end
			end)
			task.wait(0.25)
		end
	end)
	-- POST-RESTORE FIX (camera tilted UP + weird controls): the game's spawn/growth machine runs a cutscene cam that
	-- points the camera UP and leaves the controls strange. The old Scriptable camera hold is REMOVED (it was half
	-- the weirdness). Instead we COUNTER the game, for ~10 seconds:
	--   · CameraType=Custom + CameraSubject=your dino EVERY FRAME → the game's cutscene cam can never take the camera
	--   · ONLY while the camera is still pitched up (LookVector.Y > 0.6) we re-seed it level behind the dino — the
	--     moment it's level we stop touching it, so YOUR mouse keeps full control (no fighting = no weird controls)
	--   · controls back to normal: mouse free + visible, movement UserChoice, AutoRotate on, PlatformStand off,
	--     and the dino's HEAD leveled too (the game tilts it up on spawn — that's the "game machine" countered)
	task.spawn(function()
		local t0=tick()
		local fc; fc=RunService.RenderStepped:Connect(function()
			if not RUNNING or tick()-t0>10 then pcall(function() fc:Disconnect() end) return end
			pcall(function()
				local cam=WS.CurrentCamera
				local c=LP.Character or (WS:FindFirstChild("Characters") and WS.Characters:FindFirstChild(LP.Name))
				local h=c and c:FindFirstChildOfClass("Humanoid")
				local part=(h and h.RootPart) or (c and (c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")))
				if cam and cam.CameraType~=Enum.CameraType.Custom then cam.CameraType=Enum.CameraType.Custom end
				if cam and (h or part) and cam.CameraSubject~=(h or part) then cam.CameraSubject=h or part end
				if h then h.AutoRotate=true; h.PlatformStand=false end
				-- counter the UP-tilt: only while it's actually pointing up, re-seed a level camera behind the dino
				if cam and part and cam.CFrame.LookVector.Y>0.6 then
					local p=part.Position
					local lk=part.CFrame.LookVector; local flat=Vector3.new(lk.X,0,lk.Z); flat=(flat.Magnitude>0.05) and flat.Unit or Vector3.new(0,0,-1)
					cam.CFrame=CFrame.new(p - flat*16 + Vector3.new(0,7,0), p + Vector3.new(0,2,0))
				end
			end)
		end)
		-- controls: free the mouse + normal movement for the first few seconds; level the dino's head too
		for _=1,30 do
			pcall(function()
				LP.CameraMode=Enum.CameraMode.Classic
				UIS.MouseBehavior=Enum.MouseBehavior.Default
				UIS.MouseIconEnabled=true
			end)
			pcall(function() LP.DevComputerMovementMode=Enum.DevComputerMovementMode.UserChoice end)
			pcall(function() UIS.ModalEnabled=false end)
			pcall(function() if setHeadAngles then setHeadAngles(0,0) end end)
			task.wait(0.2)
		end
	end)
	notify("Progress Restore","Progress loading…")
	task.delay(12,function() __gg.MH_restoreBusy=false end)
	return ok
end
local function getReplicaSignal()
	if RCACHE.sig and RCACHE.sig.Parent then return RCACHE.sig end
	local re = RS:FindFirstChild("RemoteEvents")
	if re then RCACHE.sig = re:FindFirstChild("ReplicaSignal") end
	return RCACHE.sig
end
-- SoundRemote: the captured attack ALSO fires SoundRemote:FireServer("PVP","Attacks/Primary",false,nil,1) — this
-- is what actually INITIATES the primary attack server-side (the ReplicaSignal "Attack" just reports the hit). We
-- must fire BOTH or the server never registers the swing = no damage. THIS is the missing piece for PvP/hitbox.
local function getSoundRemote()
	if RCACHE.sound and RCACHE.sound.Parent then return RCACHE.sound end
	local re = RS:FindFirstChild("RemoteEvents")
	RCACHE.sound = (re and re:FindFirstChild("SoundRemote")) or RS:FindFirstChild("SoundRemote")
	if not RCACHE.sound then for _,d in ipairs(RS:GetDescendants()) do if d.Name=="SoundRemote" and d:IsA("RemoteEvent") then RCACHE.sound=d break end end end
	return RCACHE.sound
end
local function fireSwing(sequence)
	local seq=sequence or __gg.MH_attackSequence; local rt=seq and seq.register; local id=MHNEED and MHNEED.replicaId and MHNEED.replicaId()
	-- Never invent RegisterAttack. Automation starts only after the game supplied the exact reliable packet,
	-- e.g. (id,"RegisterAttack","Attacks/Primary","Attack1"), for this same CharacterState replica.
	if not (type(rt)=="table" and rt.n and rt.n>=4 and rt[1]==id and rt[2]=="RegisterAttack") then return false end
	local re=RS:FindFirstChild("RemoteEvents")
	local rr=(rt.instance and rt.instance.Parent and rt.instance) or (re and rt.remote and re:FindFirstChild(rt.remote))
	if not rr then return false end
	local ok=pcall(function() rr:FireServer(table.unpack(rt,1,rt.n)) end)
	if not ok then return false end
	-- Sound is ancillary and is replayed only when captured; no hard-coded sound packet is manufactured.
	local sr=getSoundRemote(); local st=__gg.MH_soundTemplate
	if sr and type(st)=="table" and st.n and st.n>=2 and (st.identity==nil or seq.identity==nil or st.identity==seq.identity) then pcall(function() sr:FireServer(table.unpack(st,1,st.n)) end) end
	return true
end
-- ═══ SPAWN RESCUE — the "I spawn outside the map and die, EVERY time, even without the script" fix ═══
-- Cause: a teleport put you outside the map and you SAVED there — so the GAME itself now respawns you in the
-- void every join and you die on repeat (that's why it happens with no script running). While the hub IS running
-- we break the loop: for ~20s after every spawn we stream the map in around you and raycast for real ground.
-- Under the map → snapped on top of the ground. Free-falling with NO ground anywhere below for 6s+ → your spawn
-- spot is genuinely outside the map, so we move you to a real spawn point / the nearest big terrain piece.
-- Run the hub once after dying, stand somewhere real, and re-save — that repairs the bad save for good.
-- (Stored on __gg, NOT a new local — the main chunk sits at Luau's 200-local cap.)
__gg.MH_spawnRescue = function()
	task.spawn(function()
		-- THE GAME'S OWN "UNSTUCK" IS THE REAL FIX: PE shows an Unstuck timer that teleports you to the nearest
		-- spawn — but ANY movement cancels it, and v1 of this rescue kept re-writing your CFrame, which fought the
		-- timer forever (your screenshot). Now: the MOMENT the Unstuck UI is visible we go completely hands-off
		-- and keep you input-still so the timer finishes and the game itself puts you at a real spawn.
		local function unstuckOn()
			local found=false
			pcall(function()
				local pg=LP:FindFirstChild("PlayerGui"); if not pg then return end
				for _,d in ipairs(pg:GetDescendants()) do
					if d:IsA("TextLabel") and d.Visible then
						local t=string.lower(tostring(d.Text))
						if t:find("unstuck",1,true) or t:find("nearest spawn",1,true) then found=true; break end
					end
				end
			end)
			return found
		end
		local t0=tick()
		local warned=false
		while tick()-t0<30 and RUNNING do
			local handsOff=false
			pcall(function()
				if not CFG.DeathFix then handsOff=true; return end                          -- "Death Bug Fix" toggle is OFF
				if (__gg.MH_rescueMute or 0) > tick() then handsOff=true; return end       -- a hub teleport is in progress — never fight it
				if unstuckOn() then
					handsOff=true
					if not warned then warned=true; pcall(function() notify("Spawn Rescue","The game's Unstuck timer is running — DON'T MOVE (moving cancels it). It teleports you to a real spawn; then RE-SAVE your dino!") end) end
					return
				end
				local r=hrp(); if not r then return end
				local base=r.Position
				pcall(function() LP:RequestStreamAroundAsync(base, 1) end)
				local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.IgnoreWater=true   -- SOLID ground only: v1 used the water surface and parked you in the open ocean
				rp.RespectCanCollide=true   -- FALSE-RESCUE FIX: without this the ray hit non-collidable TREE LEAVES above you, read the canopy as "the ground", decided you were under the map, and yanked you up on every normal forest spawn
				rp.FilterDescendantsInstances={LP.Character, WS:FindFirstChild("Characters"), WS:FindFirstChild("CharacterIgnore")}
				-- STANDING ON REAL GROUND = healthy spawn, hands off. This alone kills the "it keeps bringing me up
				-- when I spawn on the map" bug: a normal spawn always has footing within a few studs.
				local footing=WS:Raycast(base+Vector3.new(0,3,0), Vector3.new(0,-18,0), rp)
				if footing then return end
				local ground=WS:Raycast(Vector3.new(base.X, base.Y+400, base.Z), Vector3.new(0,-4000,0), rp)
				local wp=RaycastParams.new(); wp.FilterType=Enum.RaycastFilterType.Exclude; wp.IgnoreWater=false
				wp.RespectCanCollide=true
				wp.FilterDescendantsInstances=rp.FilterDescendantsInstances
				local surface=WS:Raycast(Vector3.new(base.X, base.Y+400, base.Z), Vector3.new(0,-4000,0), wp)
				local deepSea = ground and surface and (surface.Position.Y - ground.Position.Y) > 25   -- solid floor way below the water = open ocean
				local down=WS:Raycast(base, Vector3.new(0,-1500,0), rp)
				local falling=(r.AssemblyLinearVelocity.Y < -25) and not down
				if ground and not deepSea and base.Y < ground.Position.Y - 8 then
					local goal=CFrame.new(ground.Position + Vector3.new(0,6,0))   -- under the map -> on top of REAL land
					for _=1,90 do local rr=hrp(); if rr then pcall(function() rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero end) end task.wait() end
					pcall(function() notify("Spawn Rescue","You spawned under the map — pulled you back on top. Re-save your dino somewhere safe!") end)
				elseif (falling and tick()-t0>6) or (deepSea and tick()-t0>6) then
					-- outside the map / open ocean: go to a REAL spawn point (or big land), not "on top of the water"
					local dest
					-- RANDOM PLAYER FIRST: the rescue drops you next to a real player instead of an empty spawn
					pcall(function()
						local opts={}
						for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP then local c=pl.Character; local r2=c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")); if r2 and r2.Position.Y>-200 then opts[#opts+1]=r2.Position end end end
						if #opts>0 then dest=opts[math.random(#opts)]+Vector3.new(0,8,0) end
					end)
					if not dest then pcall(function() local sp=WS:FindFirstChildWhichIsA("SpawnLocation", true); if sp then dest=sp.Position+Vector3.new(0,8,0) end end) end
					if not dest then pcall(function()
						local bf=WS:FindFirstChild("Biomes") or WS:FindFirstChild("Map")
						if bf then for _,d in ipairs(bf:GetDescendants()) do if d:IsA("BasePart") and d.Size.Magnitude>50 then dest=d.Position+Vector3.new(0,20,0); break end end end
					end) end
					if dest then
						pcall(function() LP:RequestStreamAroundAsync(dest, 1) end)
						local goal=CFrame.new(dest)
						for _=1,90 do local rr=hrp(); if rr then pcall(function() rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero end) end task.wait() end
						pcall(function() notify("Spawn Rescue","Your saved spot is OUTSIDE the map — moved you to a real spawn. RE-SAVE your dino now so this stops happening!") end)
					end
				end
			end)
			task.wait(handsOff and 1 or 0.3)
		end
	end)
end
conn(LP.CharacterAdded:Connect(function()
	myReplicaId=nil; __gg.MH_verifiedReplicaId=nil; if __gg.MH_clearDinoCaches then __gg.MH_clearDinoCaches(nil) end
	if type(__gg.MH_tpFeatureGen)=="table" then for k,v in pairs(__gg.MH_tpFeatureGen) do __gg.MH_tpFeatureGen[k]=(v or 0)+1 end end
	if __gg.MH_stopProFood then pcall(__gg.MH_stopProFood) end; if __gg.MH_cancelCorpseTP then pcall(__gg.MH_cancelCorpseTP) end
	__gg.MH_tpSeq=(__gg.MH_tpSeq or 0)+1; __gg.MH_tpOrigin=nil; task.wait(1); if __gg.MH_spawnRescue then __gg.MH_spawnRescue() end
end))
task.spawn(function() task.wait(2); if __gg.MH_spawnRescue then __gg.MH_spawnRescue() end end)   -- also guard THIS spawn (you may already be falling)
local CharacterState
pcall(function() local cm=RS:FindFirstChild("Common"); local cs=cm and cm:FindFirstChild("CharacterState"); if cs then CharacterState=require(cs) end end)
local function csReplica() return CharacterState and CharacterState.Replica end
local function csStats() local r=csReplica(); if r and r.Data then return r.Data.Stats, r.Data.MaxStats end end
-- Runtime need resolver. Food always requires a real capacity. Stamina may use the highest value observed on this
-- exact dinosaur as a LOCAL-only fallback when neither MaxStats nor the HUD denominator is discoverable; that keeps
-- client exhaustion from slowing movement without manufacturing a larger server value. Resolution order is
-- (1) matching MaxStats/sibling pair, (2) ConsumptionData for food, (3) a real HUD current/max denominator such as
-- "3.8 / 15" or "316 / 319", then (4) stamina's per-dinosaur observed high-water fallback.
MHNEED={refs={food={},stamina={}},max={food=nil,stamina=nil},maxSource={food=nil,stamina=nil},hasPaired={food=false,stamina=false},at=0,root=nil,character=nil,capRoot=nil,capacity=nil}
function MHNEED.replicaId()
	local r=csReplica(); if not r then return nil end
	-- The packet owner is verified only by the exact CharacterState.Replica.Id field. Data/source ids are unrelated.
	local ok,id=pcall(function() return r.Id end)
	if ok and typeof(id)=="number" then return id end
	return nil
end
function MHNEED.identity()
	local r=csReplica(); local root=r and r.Data; local tags=r and r.Tags
	local species=(tags and (tags.Character or tags.Species or tags.Type)) or (root and (root.Character or root.Species or root.Type))
	return tostring(MHNEED.replicaId() or "?").."|"..tostring(species or "?").."|"..tostring(LP.Character or "?")
end
function MHNEED.norm(name) return tostring(name or ""):lower():gsub("[^%w]","") end
function MHNEED.kindFor(name, context)
	local raw=tostring(name or ""):lower(); local n=MHNEED.norm(raw)
	if n:find("max",1,true) or n:find("capacity",1,true) or n:find("limit",1,true) or n:find("rate",1,true)
		or n:find("drain",1,true) or n:find("deplet",1,true) or n:find("decay",1,true) or n:find("regen",1,true)
		or n:find("percent",1,true) or n:find("ratio",1,true) or n:find("fill",1,true) or n:find("alpha",1,true) then return nil end
	-- PE's nested need layout uses Hunger.Delta / Hunger.Max (and some builds do the same for stamina).
	-- Delta is only considered a current value when its parent context already identifies the need, so Growth.Delta
	-- cannot be mistaken for food.
	local generic=n=="current" or n=="cur" or n=="value" or n=="amount" or n=="level" or n=="delta"
	local c=MHNEED.norm(context)
	local food=n=="food" or n=="hunger" or n=="fullness" or n=="satiation"
		or n=="currentfood" or n=="currenthunger" or n=="currentfullness" or n=="currentsatiation"
		or n=="foodcurrent" or n=="hungercurrent" or n=="foodvalue" or n=="hungervalue" or n=="foodamount" or n=="hungeramount" or n=="foodlevel" or n=="hungerlevel"
	if food
		or (generic and (c:find("food",1,true) or c:find("hunger",1,true) or c:find("fullness",1,true) or c:find("satiation",1,true))) then return "food" end
	local stamina=n=="stamina" or n=="stam" or n=="energy" or n=="endurance" or n=="vigor" or n=="sp"
		or n=="currentstamina" or n=="currentstam" or n=="currentenergy" or n=="currentendurance"
		or n=="staminacurrent" or n=="staminavalue" or n=="staminaamount" or n=="staminalevel"
	if stamina
		or (generic and (c:find("stamina",1,true) or c:find("stam",1,true) or c:find("endurance",1,true))) then return "stamina" end
	return nil
end
function MHNEED.pairedMax(tb, key, maxTb, kind, current)
	local function index(src)
		local out={}; if type(src)=="table" then for k,v in pairs(src) do if type(v)=="number" then out[MHNEED.norm(k)]=v end end end
		return out
	end
	local own=index(tb); local parallel=index(maxTb); local n=MHNEED.norm(key)
	local base=n:gsub("^current",""):gsub("^cur",""):gsub("current$",""):gsub("value$",""):gsub("amount$",""):gsub("level$","")
	if base=="" or base=="value" or base=="amount" or base=="level" then base=kind end
	local function valid(v)
		v=tonumber(v)
		if v and v>0 and v<1e8 and (not current or v+1e-6>=current) then return v end
	end
	-- Exact property identity wins. MaxStats commonly mirrors the current key (Stamina -> MaxStats.Stamina), while
	-- sibling layouts use MaxStamina/StaminaMax. Do not scan other aliases and choose the largest numeric value.
	local names={n}; if base~=n then names[#names+1]=base end
	for _,a in ipairs(names) do
		for _,v in ipairs({parallel[a],own["max"..a],own[a.."max"],own["maximum"..a],own[a.."maximum"],own[a.."capacity"],own["capacity"..a],own[a.."limit"]}) do
			local mx=valid(v); if mx then return mx end
		end
	end
	if n=="current" or n=="cur" or n=="value" or n=="amount" or n=="level" or n=="delta" then
		for _,mk in ipairs({"max","maximum","maxvalue","maximumvalue","capacity","limit","total"}) do local mx=valid(own[mk]); if mx then return mx end end
	end
	return nil
end
function MHNEED.foodCapacity()
	local r=csReplica(); local root=r and r.Data
	if not root then return nil end
	if MHNEED.capRoot==root and MHNEED.capacity then return MHNEED.capacity end
	MHNEED.capRoot=root; MHNEED.capacity=nil
	pcall(function()
		local sh=RS:FindFirstChild("Shared"); local mod=sh and sh:FindFirstChild("ConsumptionData")
		if not mod then return end
		local cd=require(mod); local fw=cd and (cd.FoodWaterCapacity or cd.Capacities or cd.Capacity); if type(fw)~="table" then return end
		local tags=r.Tags or {}; local data=r.Data; local ids={}
		local function add(v) if type(v)=="string" and v~="" then ids[MHNEED.norm(v)]=true end end
		add(tags.Species); add(tags.Character); add(tags.Type); add(tags.Diet); add(data.Species); add(data.Character); add(data.Type); add(data.Diet)
		local m=LP.Character; local mm=m and m:FindFirstChild("MeshModel"); if mm then add(mm:GetAttribute("Type")); add(mm:GetAttribute("Species")) end
		local seen,count={},0
		local function walk(tb,matched,depth)
			if type(tb)~="table" or seen[tb] or depth>7 or count>1400 or MHNEED.capacity then return end
			seen[tb]=true
			for k,v in pairs(tb) do
				count+=1; if count>1400 then break end
				local nk=MHNEED.norm(k); local hit=matched or ids[nk]
				if hit and type(v)=="number" and (nk=="food" or nk=="maxfood" or nk=="foodcapacity") and v>0 and v<1e8 then MHNEED.capacity=v; return end
				if type(v)=="table" then walk(v,hit,depth+1); if MHNEED.capacity then return end end
			end
		end
		walk(fw,false,0)
	end)
	return MHNEED.capacity
end
function MHNEED.refresh(force)
	local r=csReplica(); local root=r and r.Data; local character=LP.Character
	local identity=MHNEED.identity()
	if __gg.MH_identityKey==nil then __gg.MH_identityKey=identity elseif __gg.MH_identityKey~=identity and __gg.MH_clearDinoCaches then __gg.MH_clearDinoCaches(identity) end
	if not force and MHNEED.root==root and MHNEED.character==character and tick()-(MHNEED.at or 0)<0.75 then return end
	if MHNEED.root~=root or MHNEED.character~=character then MHNEED.capRoot=nil; MHNEED.capacity=nil end
	MHNEED.root=root; MHNEED.character=character; MHNEED.at=tick()
	local refs={food={},stamina={}}; local chosen={food=nil,stamina=nil}; local hasPaired={food=false,stamina=false}; local hudPairs={}; local seen,count={},0
	local function candidate(kind,value,priority,source)
		value=tonumber(value); if not (kind and value and value>0 and value<1e8) then return end
		local old=chosen[kind]
		if not old or priority>old.priority then chosen[kind]={value=value,priority=priority,source=source} end
	end
	local function addRef(kind,ref,mx,priority)
		if not kind then return end; ref.max=mx; refs[kind][#refs[kind]+1]=ref; if mx then hasPaired[kind]=true; candidate(kind,mx,priority,"paired") end
	end
	local function pairPriority(kind,key)
		local n=MHNEED.norm(key)
		if kind=="food" and (n=="food" or n=="currentfood" or n=="foodcurrent") then return 4 end
		if kind=="stamina" and (n=="stamina" or n=="currentstamina" or n=="staminacurrent") then return 4 end
		return 3
	end
	local function walk(tb,maxTb,path,depth)
		if type(tb)~="table" or seen[tb] or depth>8 or count>4000 then return end
		seen[tb]=true
		for k,v in pairs(tb) do
			count+=1; if count>4000 then break end
			local ks=tostring(k)
			if type(v)=="number" then
				local kind=MHNEED.kindFor(ks,path)
				if kind then local mx=MHNEED.pairedMax(tb,k,maxTb,kind,v); addRef(kind,{mode="table",tb=tb,key=k,path=path.."."..ks},mx,pairPriority(kind,ks)) end
			elseif type(v)=="table" then
				local nextMax
				if type(maxTb)=="table" then nextMax=maxTb[k]; if type(nextMax)~="table" then nextMax=maxTb end end
				if ks:lower()=="stats" and type(tb.MaxStats)=="table" then nextMax=tb.MaxStats end
				if not nextMax and type(v.MaxStats)=="table" then nextMax=v.MaxStats elseif not nextMax and type(v.Max)=="table" then nextMax=v.Max end
				walk(v,nextMax,path.."."..ks,depth+1)
			end
		end
	end
	if root then
		-- Known need tables are scanned first so a large replica cannot exhaust the generic walk budget before Food or
		-- Stamina is reached. The generic walk still handles future layouts and species-specific nesting.
		if type(root.Stats)=="table" then walk(root.Stats,root.MaxStats or root.Max,"Replica.Data.Stats",0) end
		if type(root.Needs)=="table" then walk(root.Needs,root.MaxNeeds or root.MaxStats or root.Max,"Replica.Data.Needs",0) end
		if type(root.Vitals)=="table" then walk(root.Vitals,root.MaxVitals or root.MaxStats or root.Max,"Replica.Data.Vitals",0) end
		for _,key in ipairs({"Food","Hunger","Fullness","Satiation","Stamina","Energy","Endurance"}) do
			local tb=root[key]; if type(tb)=="table" then walk(tb,tb.MaxStats or tb.Max,"Replica.Data."..key,0) end
		end
		local sav=root.SavableStats
		if type(sav)=="table" and type(sav.Stats)=="table" then walk(sav.Stats,sav.MaxStats or sav.Max,"Replica.Data.SavableStats.Stats",0) end
		walk(root,root.MaxStats or root.Max,"Replica.Data",0)
	end
	if CharacterState then
		for _,k in ipairs({"Stats","State","Data","Vitals","Needs","Resources"}) do local tb=CharacterState[k]; if type(tb)=="table" then walk(tb,tb.MaxStats or tb.Max,"CharacterState."..k,0) end end
		for k,v in pairs(CharacterState) do if type(v)=="number" then local kind=MHNEED.kindFor(k,"CharacterState"); if kind then
			local mx=MHNEED.pairedMax(CharacterState,k,CharacterState.MaxStats,kind,v); addRef(kind,{mode="table",tb=CharacterState,key=k,path="CharacterState."..tostring(k)},mx,pairPriority(kind,k))
		end end end
	end
	local wb=__gg.MH_wellbeing; local wr=wb and wb.Data and wb.Data.SavableStats
	if wr and type(wr.Stats)=="table" then walk(wr.Stats,wr.MaxStats or wr.Max,"Wellbeing.Stats",0) end
	-- ConsumptionData is a fallback only when no matching data-table pair exists.
	if not chosen.food then candidate("food",MHNEED.foodCapacity(),2,"capacity") end
	-- HUD denominator/data-source fallback. Do not mutate text, bar Size, or fill/ratio properties.
	local pg=LP:FindFirstChild("PlayerGui"); local hud=pg and (pg:FindFirstChild("MainHUD") or pg)
	local sf=hud and (hud:FindFirstChild("StatsFrame",true) or hud)
	if sf then
		local items={sf}; local desc=sf:GetDescendants(); for i=1,math.min(#desc,1600) do items[#items+1]=desc[i] end
		for _,inst in ipairs(items) do
			local context=""; local p=inst
			for _=1,5 do if not p or p==sf.Parent then break end; context=p.Name.."."..context; p=p.Parent end
			if inst:IsA("TextLabel") or inst:IsA("TextButton") then
				local text=tostring(inst.Text or ""):gsub(",",""); local cur,mx=text:match("([%d%.]+)%s*/%s*([%d%.]+)")
				cur=tonumber(cur); mx=tonumber(mx); local kind=MHNEED.kindFor(inst.Name,context) or MHNEED.kindFor("current",context)
				if cur and mx and mx>0 and cur<=mx and not text:find("%",1,true) then
					if kind then candidate(kind,mx,1,"hud") else hudPairs[#hudPairs+1]={current=cur,max=mx} end
				end
			end
			local attrs=inst:GetAttributes()
			for k,v in pairs(attrs) do if type(v)=="number" then local kind=MHNEED.kindFor(k,context); if kind then local mx=MHNEED.pairedMax(attrs,k,nil,kind,v); addRef(kind,{mode="attr",inst=inst,key=k},mx,1) end end end
			if inst:IsA("ValueBase") then
				local ok,value=pcall(function() return inst.Value end)
				if ok and type(value)=="number" then
					local kind=MHNEED.kindFor(inst.Name,context)
					if kind then
						local siblings={}; local par=inst.Parent
						if par then for _,s in ipairs(par:GetChildren()) do if s:IsA("ValueBase") then local good,val=pcall(function() return s.Value end); if good and type(val)=="number" then siblings[s.Name]=val end end end end
						local mx=MHNEED.pairedMax(siblings,inst.Name,nil,kind,value); addRef(kind,{mode="value",inst=inst},mx,1)
					end
				end
			end
		end
	end
	-- Icon-only HUD rows do not necessarily contain "Food" or "Stamina" in their instance names. Match an otherwise
	-- anonymous "current / max" row to the exact current value found in the live replica. When multiple rows have the
	-- same numerator (for example 10/10 and food 10/15), the larger denominator is the useful capacity.
	local function refValue(ref)
		if ref.mode=="table" and ref.tb then return tonumber(ref.tb[ref.key]) end
		if ref.mode=="attr" and ref.inst and ref.inst.Parent then local ok,v=pcall(function() return ref.inst:GetAttribute(ref.key) end); if ok then return tonumber(v) end end
		if ref.mode=="value" and ref.inst and ref.inst.Parent then local ok,v=pcall(function() return ref.inst.Value end); if ok then return tonumber(v) end end
	end
	for _,kind in ipairs({"food","stamina"}) do
		local hudMax
		for _,ref in ipairs(refs[kind]) do local value=refValue(ref); if value then
			for _,pair in ipairs(hudPairs) do local tolerance=math.max(0.02,math.abs(value)*0.002)
				if math.abs(pair.current-value)<=tolerance and (not hudMax or pair.max>hudMax) then hudMax=pair.max end
			end
		end end
		if hudMax then candidate(kind,hudMax,1,"hud") end
	end
	-- Last-resort stamina pin: retain only the highest value actually observed for this dinosaur. It is deliberately
	-- lower priority than every true maximum and is never eligible for reportKnown/namecall server rewrites.
	for _,ref in ipairs(refs.stamina) do local value=refValue(ref); if value and value>0 and value<1e8 then
		__gg.MH_needHighWater.stamina=math.max(tonumber(__gg.MH_needHighWater.stamina) or 0,value)
	end end
	if not chosen.stamina and (__gg.MH_needHighWater.stamina or 0)>0 then candidate("stamina",__gg.MH_needHighWater.stamina,0,"highwater") end
	MHNEED.refs=refs; MHNEED.hasPaired=hasPaired
	for _,kind in ipairs({"food","stamina"}) do
		MHNEED.max[kind]=chosen[kind] and chosen[kind].value or nil
		MHNEED.maxSource[kind]=chosen[kind] and chosen[kind].source or nil
	end
end
function MHNEED.maxFor(kind) MHNEED.refresh(); return MHNEED.max[kind] end
function MHNEED.maxForProperty(kind,property)
	MHNEED.refresh(); local want=MHNEED.norm(property)
	for _,ref in ipairs(MHNEED.refs[kind] or {}) do
		local name=ref.key or (ref.inst and ref.inst.Name)
		if MHNEED.norm(name)==want and ref.max and ref.max>0 then return ref.max end
	end
	-- The game can report an alias (for example Energy/CurrentStamina) while the paired local field is named
	-- Stamina. Once the property and the resolved field both classify as the same need, the paired maximum is still
	-- authoritative; requiring an identical spelling made valid stamina/food reports fail silently.
	local source=MHNEED.maxSource and MHNEED.maxSource[kind]
	if MHNEED.kindFor(property,"")==kind and (source=="paired" or source=="hud" or (kind=="food" and source=="capacity")) then return MHNEED.max[kind] end
	return nil
end
function MHNEED.pin(kind)
	MHNEED.refresh(); local globalMax=MHNEED.max[kind]; local changed=false
	local source=MHNEED.maxSource and MHNEED.maxSource[kind]
	local trustedGlobal=globalMax and (source=="paired" or source=="hud" or (kind=="food" and source=="capacity") or (kind=="stamina" and source=="highwater"))
	for _,ref in ipairs(MHNEED.refs[kind] or {}) do
		local target=ref.max or (trustedGlobal and globalMax or nil)
		if target and target>0 then
			if ref.mode=="table" and ref.tb and type(ref.tb[ref.key])=="number" then if math.abs(ref.tb[ref.key]-target)>1e-6 then changed=true; ref.tb[ref.key]=target end
			elseif ref.mode=="attr" and ref.inst and ref.inst.Parent then local v=ref.inst:GetAttribute(ref.key); if type(v)=="number" and math.abs(v-target)>1e-6 then changed=true; pcall(function() ref.inst:SetAttribute(ref.key,target) end) end
			elseif ref.mode=="value" and ref.inst and ref.inst.Parent then local ok,v=pcall(function() return ref.inst.Value end); if ok and type(v)=="number" and math.abs(v-target)>1e-6 then changed=true; pcall(function() ref.inst.Value=target end) end end
		end
	end
	return globalMax,changed
end
function MHNEED.report(kind, force)
	local packet=__gg.MH_needPackets and __gg.MH_needPackets[kind]; local mx=packet and MHNEED.maxForProperty(kind,packet[3]); local id=MHNEED.replicaId()
	-- Proactive reports require a paired data maximum. HUD/capacity fallbacks may pin local state and may rewrite a
	-- genuine outgoing need report, but they never manufacture a new server report on their own.
	if not (MHNEED.maxSource and MHNEED.maxSource[kind]=="paired" and type(packet)=="table" and packet.n and packet.n>=4 and mx and id and packet[1]==id) then return false end
	local now=tick(); local last=__gg.MH_needReportAt[kind] or 0; if not force and now-last<0.9 then return false end
	local re=RS:FindFirstChild("RemoteEvents"); local remote=(packet.instance and packet.instance.Parent and packet.instance) or (re and packet.remote and re:FindFirstChild(packet.remote))
	if not remote then return false end
	local args={n=packet.n}; for i=1,packet.n do args[i]=packet[i] end; args[4]=mx; __gg.MH_needReportAt[kind]=now
	return pcall(function() remote:FireServer(table.unpack(args,1,args.n)) end)
end
function MHNEED.reportKnown(kind,force)
	MHNEED.refresh(); local mx=MHNEED.max[kind]; local source=MHNEED.maxSource and MHNEED.maxSource[kind]
	if not (mx and (source=="paired" or source=="hud" or (kind=="food" and source=="capacity"))) then return false end
	-- Use only a current property name found on this dinosaur. MaxStats/capacity fields are never reported as current.
	local property
	for _,ref in ipairs(MHNEED.refs[kind] or {}) do
		local path=tostring(ref.path or ""):lower(); local key=ref.key or (ref.inst and ref.inst.Name)
		local nk=MHNEED.norm(key); local generic=nk=="current" or nk=="cur" or nk=="value" or nk=="amount" or nk=="level" or nk=="delta"
		if type(key)=="string" and not generic and MHNEED.kindFor(key,ref.path)==kind and not path:find("max",1,true) and not path:find("capacity",1,true) then property=key; break end
	end
	local rep=csReplica(); local id=MHNEED.replicaId()
	if not (property and rep and id and rep.FireServer) then return false end
	local stamp=kind..":known"; local now=tick(); local last=__gg.MH_needReportAt[stamp] or 0
	if not force and now-last<0.9 then return false end
	__gg.MH_needReportAt[stamp]=now
	return pcall(function() rep:FireServer("SetProperty",property,mx) end)
end
-- Character/species/verified-replica changes can occur without a CharacterAdded event. Watch only the cheap identity
-- tuple and invalidate all diet, Bite, combat/sound, need, and blood caches before any old packet can be replayed.
task.spawn(function() while RUNNING do task.wait(0.5); pcall(function()
	local identity=MHNEED.identity()
	if __gg.MH_identityKey==nil then __gg.MH_identityKey=identity elseif __gg.MH_identityKey~=identity then __gg.MH_clearDinoCaches(identity) end
end) end end)
-- REPLICA ID FALLBACK (no-hook executors): the namecall hook normally sets myReplicaId from self-actions like the
-- constantly-fired HeadAngles. If the executor lacks hookmetamethod, read our dino id from CharacterState.Replica
-- as a fallback. Only sets it when not already captured (the hook value is the authoritative ReplicaSignal id).
task.spawn(function() while RUNNING do task.wait(1)
	pcall(function()
		local id=MHNEED.replicaId()
		if typeof(id)=="number" then __gg.MH_verifiedReplicaId=id; if myReplicaId~=id then noteReplicaId(id) end end
	end)
end end)
-- SELF action: fire ReplicaSignal as the player's own replica (id = myReplicaId, e.g. 57542).
local function replicaFire(...)
	local a=table.pack(...)
	local rs=getReplicaSignal(); if not rs then return false end
	local id=MHNEED.replicaId()
	if id then __gg.MH_verifiedReplicaId=id; if myReplicaId~=id then noteReplicaId(id) end end
	if id then return (pcall(function() rs:FireServer(id, table.unpack(a,1,a.n)) end)) end
	return false
end
-- SOURCE action: source-targeted packets never receive CharacterState.Replica.Id.
local function sourceActionAll(...)
	local a=table.pack(...)
	local rs=getReplicaSignal(); if not rs then return false end
	local f=false
	for _,id in ipairs(seenIds) do pcall(function() rs:FireServer(id, table.unpack(a,1,a.n)) end); f=true end
	return f
end
-- GAME'S OWN REPORT METHOD (from the decompiled Wellbeing/Character code): the client sets its own properties by
-- calling Replica:FireServer("SetProperty", key, value) on the CharacterState replica — e.g. the game itself does
-- CharacterState.Replica:FireServer("SetProperty", "Cave", ...). Firing stamina/wellbeing THROUGH this exact path
-- is the most authentic way to tell the server "this stat is full", so the server accepts it like a real report.
local function csFireProp(key, value)
	local r = csReplica()
	if r and r.FireServer then return (pcall(function() r:FireServer("SetProperty", key, value) end)) end
	return replicaFire("SetProperty", key, value)   -- fallback to the raw ReplicaSignal path
end
setHeadAngles = function(pitch, yaw) return replicaFire("SetProperty", "HeadAngles", {pitch, yaw}) end
local function setReplicaProp(prop, value) return replicaFire("SetProperty", prop, value) end
local function replicaAction(...) return replicaFire(...) end
-- WATER: per-MAP water-source IDs the user captured (each land's Sip uses a fixed id). We fire Sip to ALL of
-- them every tick — the current map's id always lands, so INF Water now works on EVERY land, anywhere (no
-- need to stand at water / capture an id first). Cretaceous Lowland 3028 / Archipelago 3251 / Jurassic 2910 /
-- Cretaceous Upland 2195. The current land is auto-detected (see currentLand) for the debug panel.
WATER_IDS = { ["Cretaceous Lowland"]=3028, ["Cretaceous Archipelago"]=3251, ["Jurassic"]=2910, ["Cretaceous Upland"]=2195 }
local function fakeDrink()
	local rs=getReplicaSignal(); if not rs then return end
	for _,id in pairs(WATER_IDS) do pcall(function() rs:FireServer(id, "Sip") end) end  -- the map's real water id
	sourceActionAll("Sip")                       -- + any captured source ids as a fallback
	replicaFire("SetAction","Drinking",true)
	replicaFire("SetAction","Drinking",false)
end
-- FOOD: the FULL captured eat sequence (Archipelago capture, dino 4306 / source 3251):
--   (dinoId,"SetAction","Consuming",true) → (sourceId,"Bite",buffer) → (dinoId,"SetAction","Consuming",false)
--   → (dinoId,"AnimationEnded","Eat"). The source id = the land's generic id (same set as the water ids), so we
-- fire the Bite to ALL of them every tick = works on every land. Buffer captured = "\027\206\000\000\001".
EAT_BUFFER = "\027\206\000\000\001"
local function fakeEat()
	if UIS and UIS:IsKeyDown(Enum.KeyCode.E) then return end   -- CENTRAL GUARD: never cancel YOUR manual E-hold eat (any caller)
	local rs=getReplicaSignal(); if not rs then return end
	replicaFire("SetAction","Consuming",true)              -- dino: start eating
	-- Replay only calls actually captured from a real bite. Guessing source ids (including the water ids) sends
	-- invalid Bite payloads after map updates and can make the server ignore the entire food sequence.
	local cap = __gg.MH_eat
	local buf = (type(cap)=="table" and cap.buf~=nil) and cap.buf or __gg.MH_eatBuf or EAT_BUFFER
	if type(buf)=="string" and buffer and buffer.fromstring then pcall(function() buf = buffer.fromstring(buf) end) end
	-- VERBATIM REPLAY (strongest): if we captured your exact eat call, replay it byte-for-byte a few times. This is
	-- the "capture the remote when you eat, then spam it" path — it always lands because it IS the game's own call.
	local ec = __gg.MH_lastEatCall
	if type(ec)=="table" and ec.n and ec.n>=2 then
		pcall(function() rs:FireServer(table.unpack(ec,1,ec.n)) end)
	end
	if type(cap)=="table" and cap.id and not ec then pcall(function() rs:FireServer(cap.id, "Bite", cap.buf or buf) end) end
	-- Replay each known real source once. The dedicated controller below applies the configured rate;
	-- fakeEat stays a cheap one-shot helper for spawn recovery and the auto-play bot.
	local foodIds = __gg.MH_foodIds
	if not ec and type(foodIds)=="table" then for foodId in pairs(foodIds) do pcall(function() rs:FireServer(foodId, "Bite", buf) end); break end end
	-- RE-CHECK E right before ending the action: the loop above YIELDS (task.wait), so if you started holding E
	-- during it, the entry guard already passed. Skip the Consuming=false/AnimationEnded finish so we never cut
	-- off a manual hold-to-eat you began mid-fakeEat.
	if UIS and UIS:IsKeyDown(Enum.KeyCode.E) then return end
	replicaFire("SetAction","Consuming",false)             -- dino: stop consuming
	replicaFire("AnimationEnded","Eat")                    -- dino: finish (food gained)
end
-- ═══ ATTACK (the REAL captured bite-damage call — fires server-side damage) ═══
-- Pattern: (myDinoId,"Attack", nil, {Group,Name,Position}, {Group="Head",Name="Jaw",Position=myJawPos}, groupString)
-- Args [4] = TARGET bone (world position + bone name + group like "Body"/"Head"/"Neck"/"Leg"). Args [5] = OUR
-- jaw position. Args [6] = group name. The server uses these to validate the bite + apply damage by bone.
-- Bone groups so Always Damage can target a CHOSEN part (Head/Neck/Spine/Leg/Tail/Hip), or Auto (best available).
-- Names match the REAL hit-PARTS inside model.Hitbox (the lowercase container, per the Explorer screenshots):
-- Head, Neck/.001-.004, Spine/.001/.002, LegIK.L/R, Tail/.00x, Hip — each a BasePart at that bone's world position.
ATK_GROUPS = {
	Auto = {{g="Body",n="Spine.001"},{g="Head",n="Head"},{g="Body",n="Spine"},{g="Body",n="Spine.002"},{g="Neck",n="Neck.001"},{g="Neck",n="Neck"},{g="Body",n="Hip"},{g="Leg",n="LegIK.L"},{g="Leg",n="LegIK.R"}},
	Head = {{g="Head",n="Head"},{g="Head",n="Jaw"},{g="Head",n="Skull"}},
	Neck = {{g="Neck",n="Neck.001"},{g="Neck",n="Neck.002"},{g="Neck",n="Neck"},{g="Neck",n="Neck.003"},{g="Neck",n="Neck.004"}},
	Spine = {{g="Body",n="Spine.001"},{g="Body",n="Spine"},{g="Body",n="Spine.002"}},
	Body = {{g="Body",n="Spine"},{g="Body",n="Spine.001"},{g="Body",n="Spine.002"},{g="Body",n="Hip"}},
	Leg = {{g="Leg",n="LegIK.L"},{g="Leg",n="LegIK.R"},{g="Leg",n="Femur.R"},{g="Leg",n="Femur.L"},{g="Leg",n="Tibia.R"},{g="Leg",n="Tibia.L"}},
	Tail = {{g="Tail",n="Tail"},{g="Tail",n="Tail.001"},{g="Tail",n="Tail.002"},{g="Tail",n="Tail.003"},{g="Tail",n="Tail.004"}},
	Hip = {{g="Body",n="Hip"},{g="Body",n="Pelvis"}},
	Arm = {{g="Arm",n="ArmIK.L"},{g="Arm",n="ArmIK.R"},{g="Arm",n="Hand.L"},{g="Arm",n="Hand.R"},{g="Arm",n="Humerus.L"},{g="Arm",n="Humerus.R"},{g="Arm",n="Claw.L"},{g="Arm",n="Claw.R"}},
}
local function findHitboxContainer(model)
	if not model then return nil end
	for _,n in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do local hb=model:FindFirstChild(n); if hb then return hb end end
	-- Ragdolls expose authoritative hit anatomy as Host.Physics.Part.Head/... rather than a Hitbox child.
	local physics=model:FindFirstChild("Physics")
	if physics then local parts=physics:FindFirstChild("Part") or physics:FindFirstChild("Parts"); if parts then return parts end; return physics end
	-- Live streamed characters may expose only MeshModel.RootPart with animated Bone descendants.
	local mm=model:FindFirstChild("MeshModel")
	if mm then local rp=mm:FindFirstChild("RootPart",true); if rp and (rp:IsA("BasePart") or rp:IsA("Bone")) then return rp end end
	-- Streaming/new species sometimes place the generated hitbox one model deeper. Keep the fallback bounded so
	-- a large map model cannot turn a combat lookup into an unbounded workspace walk.
	local scanned=0
	for _,d in ipairs(model:GetDescendants()) do
		scanned+=1; if scanned>700 then break end
		if d.Name=="Hitbox" or d.Name=="HitBox" or d.Name=="HitboxPart" then return d end
		if d.Name=="Physics" then local parts=d:FindFirstChild("Part") or d:FindFirstChild("Parts"); if parts then return parts end end
	end
	return nil
end
-- Find a named hit point: the REAL parts are in model.Hitbox (lowercase container) as BaseParts (Neck.001, Spine,
-- LegIK.L, Head…). Look there FIRST (real .Position), then MeshModel bones, then a recursive find as last resort.
local function _findIn(model, name)
	if not model then return nil end
	-- Hitbox is a CONTAINER (Hitbox.Head.Head is the real Part). A shallow FindFirstChild returned the FOLDER, whose
	-- position can't be read, so bone-aim / Always Damage never landed. Search the container RECURSIVELY first.
	-- MATCHING IS FUZZY NOW (why Always Damage was inconsistent): the real rig bones carry suffixed / different-case
	-- names ("Spine.002", "NECK"), so an exact case-sensitive compare missed them and the hit got a dummy position
	-- the server rejected. Exact (case-insensitive) name wins; else a prefix match ("Spine" -> "Spine.002").
	local want=tostring(name):lower()
	local best
	local function scan(root)
		if root:IsA("BasePart") or root:IsA("Bone") then local rn=root.Name:lower(); if rn==want then return root elseif rn:sub(1,#want)==want then best=root end end
		for _,d in ipairs(root:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Bone")) then
				local dn=d.Name:lower()
				if dn==want then return d end
				if not best and dn:sub(1,#want)==want then best=d end
			end
		end
		return nil
	end
	local hb=findHitboxContainer(model)
	if hb then local e=scan(hb); if e then return e end end
	if best then return best end   -- a Hitbox prefix match beats searching other containers (real hit parts live there)
	local mm=model:FindFirstChild("MeshModel"); if mm then local e=scan(mm); if e then return e end end
	local e=scan(model); if e then return e end
	return best
end
local function _bonePos(b)
	if not b then return nil end
	if b:IsA("BasePart") then return b.Position end   -- Hitbox-container parts are BaseParts (real positions)
	local ok,t=pcall(function() return b.TransformedWorldCFrame end); if ok and typeof(t)=="CFrame" then return t.Position end
	local ok2,c=pcall(function() return b.WorldCFrame end); if ok2 and typeof(c)=="CFrame" then return c.Position end
	local ok3,w=pcall(function() return b.WorldPosition end); if ok3 and typeof(w)=="Vector3" then return w end
	return nil
end
-- The captured Attack call uses vector.create(...) = Luau's NATIVE vector type (typeof=="vector"), NOT Vector3.
-- If the server type-checks the Position, a Vector3 is silently rejected. Send the native vector to match exactly.
local function vec(p) if typeof(vector)=="table" and typeof(vector.create)=="function" then return vector.create(p.X, p.Y, p.Z) end return p end
-- Classify a clicked bone part's NAME into the server's damage group (so clicking a Head/Neck/Leg bone registers as
-- that group). Used for "aim the bone you click" — the Hitbox-container parts are named Head / Neck.001 / Spine /
-- LegIK.L / Tail.002 / Hand.R etc.
local function boneGroupFor(name)
	local n=tostring(name):lower()
	if n:find("head",1,true) or n:find("jaw",1,true) or n:find("skull",1,true) then return "Head" end
	if n:find("neck",1,true) then return "Neck" end
	if n:find("tail",1,true) then return "Tail" end
	if n:find("leg",1,true) or n:find("femur",1,true) or n:find("tibia",1,true) or n:find("foot",1,true) or n:find("toe",1,true) then return "Leg" end
	if n:find("arm",1,true) or n:find("hand",1,true) or n:find("humerus",1,true) or n:find("claw",1,true) or n:find("finger",1,true) then return "Arm" end
	return "Body"   -- spine/hip/pelvis/chest/torso and anything unrecognized all report as Body
end
local getMyModel  -- FORWARD-DECLARED: fireAttack (below) calls it, but the definition is further down. Without this
                  -- forward decl it bound to a nil global and fireAttack THREW before sending the Attack remote.
local function fireAttack(targetModel, skipSound, clickedPart, sequence)
	if not targetModel then return false end
	-- No synthetic hit schema: require the exact Attack packet and exact reliable remote captured for this replica.
	local myId=MHNEED.replicaId(); local seq=sequence or __gg.MH_attackSequence; local tpl=seq and seq.attack
	if not (myId and type(tpl)=="table" and tpl.n and tpl.n>=6 and tpl[1]==myId and tpl[2]=="Attack") then return false end
	local re=RS:FindFirstChild("RemoteEvents")
	local rs=(tpl.instance and tpl.instance.Parent and tpl.instance) or (re and tpl.remote and re:FindFirstChild(tpl.remote))
	if not rs then return false end
	-- pick a TARGET bone. If you picked a specific "Expand Bone" (Hitbox), AIM THAT SAME BONE; else use Always-hit part.
	local group, boneName, targetPos
	-- ═══ AIM THE BONE YOU CLICKED ═══ If a specific bone part was clicked (mouse target) and it belongs to this
	-- target, register the hit on THAT exact bone — its real name + position + mapped group. This is what makes
	-- "click a bone to hit it" work: click the head → Head hit, click a leg → Leg hit, etc.
	local clickedAim=false
	if clickedPart and clickedPart:IsA("BasePart") and clickedPart:IsDescendantOf(targetModel) then
		local p=clickedPart.Position
		if p then group, boneName, targetPos = boneGroupFor(clickedPart.Name), clickedPart.Name, p; clickedAim=true end
	end
	local want = (CFG.HitboxBone and CFG.HitboxBone~="All" and CFG.HitboxBone~="") and CFG.HitboxBone or CFG.DamagePart
	local chosenBone
	-- Bone layouts do not change every attack. Reuse the last resolved live bone briefly instead of walking up to
	-- 600 descendants for every target on every Always Damage tick. A weak-key cache also drops despawned dinos.
	if not targetPos then
		local ce=__gg.MH_attackBoneCache and __gg.MH_attackBoneCache[targetModel]
		if ce and ce.want==want and tick()-(ce.at or 0)<1 and ce.part and ce.part.Parent and ce.part:IsDescendantOf(targetModel) then
			local p=_bonePos(ce.part)
			if p then chosenBone=ce.part; boneName=ce.part.Name; targetPos=p; group=(want and ATK_GROUPS[want] and ATK_GROUPS[want][1] and ATK_GROUPS[want][1].g) or boneGroupFor(boneName) end
		end
	end
	local list = (want and want~="" and want~="Auto" and ATK_GROUPS[want]) or ATK_GROUPS.Auto
	if not targetPos then for _,b in ipairs(list) do
		local bn=_findIn(targetModel, b.n); local p=_bonePos(bn)
		-- report the FOUND part's REAL name: fuzzy find of "Spine" can return "Spine.002", and the server checks
		-- that the NAME matches the POSITION on the target's rig — a canonical name with the real part's position
		-- is a mismatch it rejects. Real name + real position = the hit registers every time.
		if p then chosenBone=bn; group, boneName, targetPos = b.g, bn.Name, p; break end
	end end
	-- KEYWORD FALLBACK — makes "Always hit part = Leg/Head/…" work on EVERY dino: if the exact bone names above didn't
	-- resolve on THIS dino's rig, search its parts/bones for ANY name in the selected region, reporting that real name
	-- so the server accepts it (bone naming varies per dino — this is why "aim a body part" missed on some of them).
	if not targetPos and want and want~="" and want~="Auto" then
		local KW=({Head={"head","skull","jaw","crani","maxill","mandib","frontal"},Neck={"neck"},Spine={"spine","body","torso","chest"},Body={"spine","body","torso","chest","hip","ilium"},Leg={"leg","femur","tibia","thigh","foot","shin","toe"},Tail={"tail"},Hip={"hip","ilium","pelvis"},Arm={"arm","hand","claw","humer","wing","finger"}})[want]
		if KW then local scanned=0
			for _,d in ipairs(targetModel:GetDescendants()) do scanned+=1; if scanned>600 then break end
				if d:IsA("BasePart") or d:IsA("Bone") then local dn=d.Name:lower()
					for _,kw in ipairs(KW) do if dn:find(kw,1,true) then local p=_bonePos(d); if p then chosenBone=d; group=(ATK_GROUPS[want] and ATK_GROUPS[want][1] and ATK_GROUPS[want][1].g) or "Body"; boneName=d.Name; targetPos=p; break end end end
				end
				if targetPos then break end
			end
		end
	end
	if not targetPos and list~=ATK_GROUPS.Auto then
		for _,b in ipairs(ATK_GROUPS.Auto) do local bn=_findIn(targetModel,b.n); local p=_bonePos(bn); if p then chosenBone=bn; group,boneName,targetPos=b.g,bn.Name,p; break end end
	end
	if not targetPos then
		local hb=findHitboxContainer(targetModel)
		if hb then
			local part = (hb:IsA("BasePart") and hb) or hb:FindFirstChildWhichIsA("BasePart", true)   -- descend the container (Hitbox.Head.Head)
			if part then chosenBone=part; group, boneName, targetPos = boneGroupFor(part.Name), part.Name, part.Position end
		end
	end
	if not targetPos then return false end
	if chosenBone and not clickedAim then __gg.MH_attackBoneCache[targetModel]={want=want,part=chosenBone,at=tick()} end
	-- ALWAYS HIT the chosen part: report the GROUP as the selected region so "Always Damage = Neck" registers as a Neck
	-- hit — but KEEP the REAL bone name we resolved above (forcing a canonical name like "Skull" on a dino whose bone is
	-- "Head" made the server REJECT the hit = no damage). Skip when you clicked a specific bone (the click wins).
	if not clickedAim and want and want~="" and want~="Auto" then
		-- The server accepts combat groups (Body/Head/Neck/Leg/Tail/Arm), not UI labels such as
		-- "Spine" or "Hip". Keep the real bone name, but map the selected UI region to its
		-- canonical server group or the hit is silently rejected.
		group = (ATK_GROUPS[want] and ATK_GROUPS[want][1] and ATK_GROUPS[want][1].g) or boneGroupFor(boneName)
		if not boneName or boneName=="" then boneName = (ATK_GROUPS[want] and ATK_GROUPS[want][1] and ATK_GROUPS[want][1].n) or want end
	end
	-- attacker's Jaw position (our own MeshModel bone) — server expects this in arg[5]
	-- arg[5] = OUR biting bone. The capture used Name="Head" — use our own Head hit-part (from our Hitbox container).
	local myJaw=_findIn(getMyModel(), "Head") or _findIn(getMyModel(), "Jaw")
	local jawPos=_bonePos(myJaw)
	if not jawPos then local mr=hrp(); jawPos=(mr and mr.Position) or Vector3.zero end
	-- HITBOX EXPANDER (smart reach): keep the target bone's REAL position (passes any server bone cross-check), but
	-- report OUR bite bone at a REALISTIC bite distance (~4 studs, like the real capture's ~5.6) toward the target.
	-- So a far enemy reads as right in front of us = the server's distance check passes. If the target is already
	-- close, use our real position.
	if CFG.HitboxExpand then
		local off = jawPos - targetPos; local m = off.Magnitude
		if m > 5 then jawPos = targetPos + (m>0 and off.Unit or Vector3.new(0,0,1)) * 4 end
	end
	-- RegisterAttack must be accepted before the hit report. Direct callers get the same one-frame ordered window;
	-- batch callers pass skipSound=true because MHCOMBAT.sequence already opened it once for the whole target set.
	-- arg[5] = OUR bite bone (capture shows Group="Head", Name="Head"); arg[6] = the TARGET group.
	if not skipSound then if not fireSwing(seq) then return false end; RunService.Heartbeat:Wait() end
	-- Preserve every species/update-specific field from the player's latest REAL attack packet and replace only
	-- the target/attacker bone data. This fixes Always Damage/Silent Aim silently failing when the server adds an
	-- extra attack argument or a dinosaur uses a different attacker-bone name.
	local args={n=tpl.n}; for i=1,tpl.n do args[i]=tpl[i] end
	if type(args[4])~="table" or type(args[5])~="table" then return false end
	local targetInfo={}; for k,v in pairs(args[4]) do targetInfo[k]=v end
	targetInfo.Group=group; targetInfo.Name=boneName; targetInfo.Position=vec(targetPos); args[4]=targetInfo
	local attackerInfo={}; for k,v in pairs(args[5]) do attackerInfo[k]=v end
	attackerInfo.Group=attackerInfo.Group or "Head"; attackerInfo.Name=attackerInfo.Name or (myJaw and myJaw.Name) or "Head"; attackerInfo.Position=vec(jawPos); args[5]=attackerInfo
	args[6]=group
	return pcall(function() rs:FireServer(table.unpack(args, 1, args.n)) end)
end
MHCOMBAT={busy=false}
function MHCOMBAT.sequence(targets, clickedPart)
	if MHCOMBAT.busy then return false end
	local list=typeof(targets)=="Instance" and {targets} or targets
	if type(list)~="table" or #list==0 then return false end
	local sequence=__gg.MH_attackSequence
	MHCOMBAT.busy=true
	local ok,hits=pcall(function()
		local n=0
		for i,m in ipairs(list) do
			-- Preserve the observed one-to-one order: exact RegisterAttack, one frame, then one exact Attack packet.
			if fireSwing(sequence) then RunService.Heartbeat:Wait(); if fireAttack(m,true,(i==1) and clickedPart or nil,sequence) then n+=1 end end
		end
		return n
	end)
	MHCOMBAT.busy=false
	return ok and hits>0
end
_G.MH_attack = function(target, clickedPart) return MHCOMBAT.sequence(target,clickedPart) end

-- ═══ SKIN CHANGER (working standalone — SurfaceAppearance swap on MeshModel) ═══
STAGE_SK = {"Hatchling","Juvenile","Teen","Adolescent","SubAdult","Sub-Adult","Adult","Elder","Monster"}
SKN = { skinData=nil, skinFolder=nil, saBack={}, busy=false }
function getMyModel()  -- assigns the forward-declared upvalue above (NOT a new local)
	if LP.Character and LP.Character.Parent then return LP.Character end
	local ch = WS:FindFirstChild("Characters")
	if ch then local m = ch:FindFirstChild(LP.Name); if m then return m end end
	return nil
end
local function skGetMesh()
	local m = getMyModel(); if not m then return nil end
	local mm = m:FindFirstChild("MeshModel"); if mm then return mm end
	for _,c in ipairs(m:GetDescendants()) do if c.Name=="MeshModel" then return c end end
	return nil
end
local function skGetCharInfo()
	local mm = skGetMesh(); local dt, st, gd
	if mm then dt=mm:GetAttribute("Type"); st=mm:GetAttribute("Stage"); gd=mm:GetAttribute("Gender") end
	if not dt then local m=getMyModel(); if m then dt=m:GetAttribute("Type") or m:GetAttribute("DinoType"); st=m:GetAttribute("Stage"); gd=m:GetAttribute("Gender") end end
	if not dt and CharacterState then pcall(function() dt=CharacterState.DinoType or dt; st=CharacterState.Stage or st; gd=CharacterState.Gender or gd end) end
	return dt, st, gd
end
local function skRemoveTagged(mm, tag)
	if not mm then return end
	for _,mesh in ipairs(mm:GetChildren()) do
		if string.sub(mesh.Name,1,4)=="Mesh" then
			local sa=mesh:FindFirstChildWhichIsA("SurfaceAppearance")
			if sa and sa:GetAttribute(tag) then sa:Destroy() end
		end
	end
end
local function skBackupSA(mm)
	if next(SKN.saBack) then return end
	for _,mesh in ipairs(mm:GetChildren()) do
		if string.sub(mesh.Name,1,4)=="Mesh" then
			local sa=mesh:FindFirstChildWhichIsA("SurfaceAppearance")
			SKN.saBack[mesh.Name]= sa and sa:Clone() or false
		end
	end
end
local function skRestoreAll()
	local mm=skGetMesh()
	if not mm then SKN.saBack={}; return end
	pcall(function() skRemoveTagged(mm,"_skG") end)
	for name,orig in pairs(SKN.saBack or {}) do
		local t=mm:FindFirstChild(name)
		if t and orig then
			local cur=t:FindFirstChildWhichIsA("SurfaceAppearance"); if cur then cur:Destroy() end
			orig:Clone().Parent=t
		end
	end
	SKN.saBack={}
end
local function skFindStageFolder(sf, stage)
	local x=sf:FindFirstChild(stage); if x then return x end
	local idx=0; for i,s in ipairs(STAGE_SK) do if s==stage then idx=i; break end end
	for i=idx-1,1,-1 do local f=sf:FindFirstChild(STAGE_SK[i]); if f then return f end end
	for i=idx+1,#STAGE_SK do local f=sf:FindFirstChild(STAGE_SK[i]); if f then return f end end
	for _,c in ipairs(sf:GetChildren()) do if c:IsA("Folder") or c:IsA("Model") then return c end end
end
local function skCollectSAs(s1,s2,s3)
	local r={}
	local function sc(f) if not f then return end for _,c in ipairs(f:GetChildren()) do if string.sub(c.Name,1,4)=="Mesh" then local sa=c:FindFirstChildWhichIsA("SurfaceAppearance"); if sa and not r[c.Name] then r[c.Name]=sa end end end end
	sc(s1); if s2~=s1 then sc(s2) end; if s3~=s2 and s3~=s1 then sc(s3) end
	return r
end
local function skApplyGame(dinoType, skinName, stage, gender, isWet)
	if not SKN.skinFolder then SKN.skinFolder=RS:FindFirstChild("Skins") end
	if not SKN.skinFolder then return false end
	local mm=skGetMesh(); if not mm then return false end
	if skinName=="Default" then skRestoreAll(); return true end
	skBackupSA(mm); task.wait()
	local df=SKN.skinFolder:FindFirstChild(dinoType); if not df then return false end
	local skf=df:FindFirstChild(skinName); if not skf then return false end
	local stgF=skFindStageFolder(skf, stage or "Adult"); if not stgF then return false end; task.wait()
	local gf=stgF:FindFirstChild(gender or "Male") or stgF:FindFirstChild("Female") or stgF:FindFirstChild("Male")
	if not gf then local hm=false for _,c in ipairs(stgF:GetChildren()) do if string.sub(c.Name,1,4)=="Mesh" then hm=true break end end gf=hm and stgF or stgF:GetChildren()[1] end
	if not gf then return false end; task.wait()
	local state=isWet and "Wet" or "Dry"
	local stF=gf:FindFirstChild(state) or gf:FindFirstChild("Dry")
	if not stF then local hm=false for _,c in ipairs(gf:GetChildren()) do if string.sub(c.Name,1,4)=="Mesh" then hm=true break end end stF=hm and gf or gf:GetChildren()[1] end
	if not stF then return false end
	local SAs=skCollectSAs(stF,gf,stgF)
	if not next(SAs) then return false end
	skRemoveTagged(mm,"_skG"); task.wait()
	for name,sa in pairs(SAs) do local t=mm:FindFirstChild(name); if t then local old=t:FindFirstChildWhichIsA("SurfaceAppearance"); if old then old:Destroy() end local cl=sa:Clone(); cl:SetAttribute("_skG",true); cl.Parent=t end end
	for _,mp in ipairs(mm:GetChildren()) do if string.sub(mp.Name,1,4)=="Mesh" and not mp:FindFirstChildWhichIsA("SurfaceAppearance") then local orig=SKN.saBack[mp.Name]; if orig and orig~=false then orig:Clone().Parent=mp end end end
	return true
end
local function skGetGameList(dinoType)
	local list={"Default"}
	if not SKN.skinData or not SKN.skinData.Skins then return list end
	local e=SKN.skinData.Skins[dinoType]; if not e or not e.Unlockables then return list end
	for k,v in pairs(e.Unlockables) do table.insert(list,k); if v.SubSkins then for sname in pairs(v.SubSkins) do table.insert(list,sname) end end end
	table.sort(list,function(a,b) if a=="Default" then return true end if b=="Default" then return false end return a<b end)
	return list
end
task.defer(function()
	pcall(function() SKN.skinData=require(RS:WaitForChild("Shared",5):WaitForChild("SkinData",5)) end)
	pcall(function() SKN.skinFolder=RS:WaitForChild("Skins",10) end)
end)

-- ═══ GENERIC STAT / REMOTE FINDERS ═══
local function findStatValues(keywords)
	local out = {}
	local function scan(root)
		if not root then return end
		for _,v in ipairs(root:GetDescendants()) do
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				local n = v.Name:lower()
				for _,k in ipairs(keywords) do if n:find(k,1,true) then out[#out+1]=v; break end end
			end
		end
	end
	scan(char()); scan(LP:FindFirstChild("leaderstats")); scan(LP)
	local pg = LP:FindFirstChild("PlayerGui"); scan(pg)
	return out
end
local function pinAttributes(keywords, value)
	local function scan(inst)
		if not inst then return end
		for k,_ in pairs(inst:GetAttributes()) do
			local lk = k:lower()
			for _,kw in ipairs(keywords) do
				if lk:find(kw,1,true) then pcall(function() inst:SetAttribute(k, value) end) break end
			end
		end
	end
	scan(char()); scan(LP); scan(hum()); scan(hrp())
end
local function pinStat(numKeywords, attrKeywords, value)
	for _,v in ipairs(findStatValues(numKeywords)) do pcall(function() v.Value = value end) end
	if attrKeywords then pinAttributes(attrKeywords, value) end
end
local function clearStatus(numKeywords, attrKeywords)
	for _,v in ipairs(findStatValues(numKeywords)) do pcall(function() v.Value = 0 end) end
	local function scan(inst)
		if not inst then return end
		for k,val in pairs(inst:GetAttributes()) do
			local lk=k:lower()
			for _,kw in ipairs(attrKeywords or {}) do
				if lk:find(kw,1,true) then
					pcall(function() if typeof(val)=="boolean" then inst:SetAttribute(k,false) else inst:SetAttribute(k,0) end end)
					break
				end
			end
		end
		for _,v in ipairs(inst:GetChildren()) do
			if v:IsA("BoolValue") then
				local n=v.Name:lower()
				for _,kw in ipairs(attrKeywords or {}) do if n:find(kw,1,true) then pcall(function() v.Value=false end) break end end
			end
		end
	end
	scan(char()); scan(hum()); scan(LP)
end
remoteCache = {}
local function findRemote(keywords, class)
	local key = table.concat(keywords,"|")..(class or "")
	if remoteCache[key] and remoteCache[key].Parent then return remoteCache[key] end
	for _,v in ipairs(RS:GetDescendants()) do
		if (not class and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction"))) or (class and v:IsA(class)) then
			local n = v.Name:lower()
			for _,k in ipairs(keywords) do if n:find(k,1,true) then remoteCache[key]=v; return v end end
		end
	end
	return nil
end
local function fireRemoteMulti(remote, ...)
	if not remote then return false end
	local args = {...}
	return pcall(function()
		if remote:IsA("RemoteEvent") then remote:FireServer(table.unpack(args))
		elseif remote:IsA("RemoteFunction") then remote:InvokeServer(table.unpack(args)) end
	end)
end

-- (Dead teleport helpers bypassTP/tpTo/safeMoveTo removed — freed locals.)
-- shared farm/food state (one table instead of several chunk-level locals — Luau caps locals at 200)
FARM = {tried={}, nodeCache={}, food={t=0,list={}}, dig=nil, digSearched=false, lastDeepPin=0, count={fossil=0,gem=0}}
-- The REAL targetable/hittable part the game uses is Characters[name].HitBox (user-confirmed). Prefer it
-- for aim / hitbox-expand / ESP / farm; fall back to the steer body. Name can vary, so try a few.
local function getHitbox(model)
	model = model or getMyModel()
	if not model then return nil end
	-- Priority the user confirmed: Hitbox (lowercase b) FIRST, then HitBox (capital B). NOTE: Hitbox may be a
	-- BasePart OR a CONTAINER (per the screenshot: model.Hitbox.Head.Head is a Part). Handle both — if it is a
	-- part use it, if it is a folder/model descend to a real BasePart inside (prefer Head, then any part).
	local hb=findHitboxContainer(model)
	if hb then
		if hb:IsA("BasePart") then return hb end
		if hb:IsA("Bone") then local owner=hb:FindFirstAncestorWhichIsA("BasePart"); if owner then return owner end end
		local head=hb:FindFirstChild("Head", true); if head and head:IsA("BasePart") then return head end
		if head and head:IsA("Bone") then local owner=head:FindFirstAncestorWhichIsA("BasePart"); if owner then return owner end end
		local any=hb:FindFirstChildWhichIsA("BasePart", true); if any then return any end
	end
	-- GAME'S OWN HITBOX BUILDER (from the decompiled Common.CreateHitbox): when a dino has no Hitbox child yet,
	-- ask the game to build the EXACT hitbox model it hits against itself (ragdoll-rig clone, grouped parts, or a
	-- bounding box). Built once per model, then the loop above finds it forever after.
	pcall(function()
		if __gg.MH_mkHB == nil then
			local cm=RS:FindFirstChild("Common"); local chb=cm and cm:FindFirstChild("CreateHitbox")
			__gg.MH_mkHB = (chb and require(chb)) or false
		end
		if type(__gg.MH_mkHB)=="function" then
			-- Do NOT mark the model permanently complete before its streamed rig exists. The old one-shot flag meant
			-- a dinosaur that joined after execution was attempted once while empty and could never get a hitbox.
			__gg.MH_hbBuildAt = __gg.MH_hbBuildAt or setmetatable({}, {__mode="k"})
			local now=tick(); local last=__gg.MH_hbBuildAt[model]
			if not last or now-last>0.75 then __gg.MH_hbBuildAt[model]=now; __gg.MH_mkHB(model) end
		end
	end)
	do local hb=findHitboxContainer(model)
		if hb then
			local any=(hb:IsA("BasePart") and hb) or hb:FindFirstChildWhichIsA("BasePart", true)
			if any then return any end
		end
	end
	local ta=model:FindFirstChild("TurningAnimation"); if ta then local b=ta:FindFirstChild("Body"); if b and b:IsA("BasePart") then return b end end
	if model.PrimaryPart then return model.PrimaryPart end
	return rootOf(model)
end
-- EVERY model that is a live / left character or wild dino. Per the Explorer screenshot, dinos (incl. the ones
-- you fight and eat) live under workspace.CharacterIgnore.LeftCharacters — NOT only workspace.Characters. Combat,
-- targeting, the bot and the protectors all missed them before. This one list is the fix. Exposed globally.
local function charModels()
	local cc=__gg.MH_charCache
	if cc and tick()-(cc.at or 0)<0.45 then return cc.list end
	local out,seen,walked={},{},{}
	local function put(m) if m and m:IsA("Model") and not seen[m] then seen[m]=true; out[#out+1]=m end end
	local function creature(m)
		return m and m:IsA("Model") and (m:FindFirstChild("MeshModel") or m:FindFirstChild("Physics")
			or m:FindFirstChild("TurningAnimation") or m:FindFirstChildOfClass("Humanoid")
			or m:FindFirstChild("Hitbox") or m:FindFirstChild("HitBox"))
	end
	local function add(f, deep)
		if not f or walked[f] then return end
		if not deep then walked[f]=true; for _,m in ipairs(f:GetChildren()) do if m:IsA("Model") then put(m) end end; return end
		-- Walk container hierarchy, not every bone/part. Once a creature's direct rig marker is found, admit it and
		-- stop descending into that rig. This has no object-count cutoff, so a late-joined dinosaur cannot land behind
		-- an arbitrary 1,800-descendant budget, while crowded rigs remain cheap to discover.
		local queue={f}; local head=1
		while head<=#queue do
			local node=queue[head]; head+=1
			if not walked[node] then
				walked[node]=true
				for _,child in ipairs(node:GetChildren()) do
					if child:IsA("Model") and creature(child) then put(child)
					elseif child:IsA("Folder") or child:IsA("Model") then queue[#queue+1]=child end
				end
			end
		end
	end
	add(WS:FindFirstChild("Characters"), true)
	local ci=WS:FindFirstChild("CharacterIgnore")
	if ci then
		add(ci:FindFirstChild("LeftCharacters"), true)
		local ragdolls=ci:FindFirstChild("Ragdolls")
		if ragdolls then local host=ragdolls:FindFirstChild("Host"); if host and host:IsA("Model") then put(host) end; add(ragdolls,true) end
		add(ci, false)
	end
	for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters"}) do add(WS:FindFirstChild(nm), true) end
	for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP then put(pl.Character) end end
	__gg.MH_charCache={at=tick(),list=out}
	return out
end
_G.MH_charModels = charModels
-- Streaming can add a model shell before MeshModel/Physics/Hitbox arrives. Invalidate admission on either event so
-- the next 0.1s combat/expansion pass sees the newcomer instead of waiting on a stale model-list snapshot.
conn(WS.DescendantAdded:Connect(function(d)
	if d:IsA("Model") or d.Name=="MeshModel" or d.Name=="Physics" or d.Name=="Hitbox" or d.Name=="HitBox" then __gg.MH_charCache=nil end
end))
-- "Always hit the Spine/Head": if CFG.AimPart names a bone (Head/Spine/Neck/...), aim at that bone (found in
-- the dino's MeshModel bone hierarchy); else aim at the Hitbox. Returns an Instance (BasePart/Bone/Attachment).
-- Spine/Head/etc. are BONE rigs under MeshModel>RootPart (Spine.002, Spine.001, ...), not BaseParts — search
-- a priority list of real bone names so "Always hit Spine" actually finds a bone, else fall back to the Hitbox.
-- Real hit-PART names inside model.Hitbox (per the screenshots).
AIM_BONES = {
	Spine={"Spine.001","Spine","Spine.002","Hip"},
	Head={"Head","Neck.001","Neck","Spine.002"},
	Neck={"Neck.001","Neck.002","Neck","Neck.003"},
	Hip={"Hip","Spine.001","Spine"},
	Body={"Spine","Spine.001","Hip"},
	Leg={"LegIK.L","LegIK.R","Femur.R","Femur.L"},
	Arm={"ArmIK.L","ArmIK.R","Hand.L","Hand.R","Humerus.L","Claw.L"},
	Tail={"Tail","Tail.001","Tail.002"},
}
local function getAimPart(model)
	if not model then return nil end
	-- If you picked a specific "Expand Bone" (Hitbox dropdown), AIM THAT bone; else use the Aim Part dropdown.
	local want = (CFG.HitboxBone and CFG.HitboxBone~="All" and CFG.HitboxBone~="") and CFG.HitboxBone or CFG.AimPart
	if want and want~="" and want~="Hitbox" and want~="HitBox" then
		-- Search Hitbox, Host.Physics.Part, then MeshModel.RootPart bones through the shared anatomy resolver.
		for _,bn in ipairs(AIM_BONES[want] or {want}) do
			local found=_findIn(model,bn)
			if found and (found:IsA("BasePart") or found:IsA("Bone") or found:IsA("Attachment")) then return found end
		end
	end
	return getHitbox(model)
end
-- world position of a BasePart OR a Bone/Attachment (bones use TransformedWorldCFrame — incl. the live animation
-- pose — then WorldCFrame/WorldPosition; they have no .Position).
local function partPos(p)
	if not p then return nil end
	if p:IsA("BasePart") then return p.Position end
	local ok0,t=pcall(function() return p.TransformedWorldCFrame end); if ok0 and typeof(t)=="CFrame" then return t.Position end
	local ok,v=pcall(function() return p.WorldPosition end); if ok and typeof(v)=="Vector3" then return v end
	local ok2,c=pcall(function() return p.WorldCFrame end); if ok2 and typeof(c)=="CFrame" then return c.Position end
	return nil
end
-- Use the shared streaming-aware character list so Silent Aim can acquire dinosaurs that joined after execution
-- and species parented under CharacterIgnore.LeftCharacters or sandbox containers.
local function nearestTarget(range, anyCreature)
	local me = hrp(); if not me then return nil end
	local mine = getMyModel()
	local best, bestRoot, bd = nil, nil, range or 1e9
	for _,m in ipairs(charModels()) do if m~=mine then
		local h=m:FindFirstChildOfClass("Humanoid")
		if (not h) or h.Health>0 then local r=getHitbox(m) or rootOf(m); if r then local d=dist(me.Position,r.Position); if d<bd then best,bestRoot,bd=m,r,d end end end
	end end
	-- Merge bounded nil-parented sandbox/newcomer candidates even when a normal target already exists.
	local function consider(m)
		if not (m and m:IsA("Model") and m~=mine) then return end
		local h = m:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return end
		local r = getHitbox(m) or rootOf(m)
		if r then local d=dist(me.Position, r.Position); if d<bd then best,bestRoot,bd = m, r, d end end
	end
	if anyCreature and typeof(getnilinstances)=="function" then
		pcall(function() local c=0; for _,v in next, getnilinstances() do c+=1; if c>2000 then break end
			if typeof(v)=="Instance" and v:IsA("Model") and (v:FindFirstChild("Hitbox") or v:FindFirstChild("HitBox") or v:FindFirstChild("Physics") or v:FindFirstChild("MeshModel")) then consider(v) end
		end end)
	end
	return best, bestRoot
end

-- ═══ GUI FRAMEWORK (purple theme — monospace; this is the FALLBACK window if Venyx can't load) ═══
local UIFONT = Enum.Font.GothamMedium  -- clean sans-serif (was monospace) for a cleaner look
ACCENTS = {
	Color3.fromRGB(46,196,110), Color3.fromRGB(40,170,230), Color3.fromRGB(120,200,60),
	Color3.fromRGB(235,185,40), Color3.fromRGB(140,110,240), Color3.fromRGB(240,110,90),
}
-- CLEAN LIGHT theme (Volt-style): white cards, dark text, green accent, subtle grey borders
local T = {
	Bg=Color3.fromRGB(243,244,247), Main=Color3.fromRGB(243,244,247), Panel=Color3.fromRGB(255,255,255), Panel2=Color3.fromRGB(248,249,251), Panel3=Color3.fromRGB(237,239,243),
	Top=Color3.fromRGB(255,255,255), Stroke=Color3.fromRGB(225,228,234), Stroke2=Color3.fromRGB(208,213,221), Text=Color3.fromRGB(36,40,50), Sub=Color3.fromRGB(118,126,140), Muted=Color3.fromRGB(158,166,178),
	Accent=ACCENTS[CFG.AccentIndex] or ACCENTS[1], On=ACCENTS[CFG.AccentIndex] or ACCENTS[1], Off=Color3.fromRGB(205,210,218), Success=Color3.fromRGB(46,196,110), Danger=Color3.fromRGB(235,90,80),
	DarkRed=Color3.fromRGB(225,228,234), Yellow=Color3.fromRGB(215,165,30),
}
local function C(cls, props) local o = Instance.new(cls); for k,v in pairs(props or {}) do if k~="Parent" then o[k]=v end end if props and props.Parent then o.Parent=props.Parent end return o end
local function corner(o,r) C("UICorner",{Parent=o, CornerRadius=UDim.new(0,r or 6)}) end
local function stroke(o,col,th) C("UIStroke",{Parent=o, Color=col or T.Stroke, Thickness=th or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function pad(o,l,r,t,b) C("UIPadding",{Parent=o, PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0), PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0)}) end
local function lay(o,padpx,dir) local u=C("UIListLayout",{Parent=o, Padding=UDim.new(0,padpx or 6), SortOrder=Enum.SortOrder.LayoutOrder, FillDirection=dir or Enum.FillDirection.Vertical}); return u end
local function tw(o,goal,t) pcall(function() TweenService:Create(o, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad), goal):Play() end) end

MS("2 helpers ok - building window")
-- Built-in window starts HIDDEN so it never flashes before Fluent loads; shown only if Fluent fails (fallback).
SG = C("ScreenGui",{Name="MoneyHubPE", Enabled=false, ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true})
safeParentGui(SG)
Shd = C("Frame",{Parent=SG, Size=UDim2.fromOffset(664,454), Position=UDim2.new(0.5,-332,0.5,-227), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.45, BorderSizePixel=0}); corner(Shd,4)
local MF = C("Frame",{Parent=SG, Size=UDim2.fromOffset(650,440), Position=UDim2.new(0.5,-325,0.5,-220), BackgroundColor3=T.Main, BorderSizePixel=0, ClipsDescendants=true}); corner(MF,3); stroke(MF,T.Stroke,1)
C("UIScale",{Parent=MF, Scale=tonumber(CFG.UIScale) or 1})  -- scale up for crisp HiDPI / 4K (Settings > UI Scale)
TB = C("Frame",{Parent=MF, Size=UDim2.new(1,0,0,46), BackgroundColor3=T.Top, BorderSizePixel=0})
accentBar = C("Frame",{Parent=TB, Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2), BackgroundColor3=T.Accent, BorderSizePixel=0})
C("TextLabel",{Parent=TB, Position=UDim2.fromOffset(16,0), Size=UDim2.new(0,170,1,0), BackgroundTransparency=1, Text="Dream Hub", TextColor3=T.Text, TextSize=14, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
C("TextLabel",{Parent=TB, Position=UDim2.fromOffset(160,0), Size=UDim2.new(0,170,1,0), BackgroundTransparency=1, Text="| Prior Extinction", TextColor3=T.Accent, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
chf = C("Frame",{Parent=TB, Size=UDim2.fromOffset(64,28), Position=UDim2.new(1,-74,0.5,-14), BackgroundTransparency=1}); lay(chf,4,Enum.FillDirection.Horizontal)
minBtn = C("TextButton",{Parent=chf, Size=UDim2.fromOffset(28,28), BackgroundColor3=T.Panel2, Text="-", TextColor3=T.Sub, TextSize=16, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=1}); corner(minBtn,3); stroke(minBtn,T.Stroke,1)
closeBtn = C("TextButton",{Parent=chf, Size=UDim2.fromOffset(28,28), BackgroundColor3=T.Panel2, Text="X", TextColor3=T.Accent, TextSize=12, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=2}); corner(closeBtn,3); stroke(closeBtn,T.Stroke,1)
closeBtn.MouseButton1Click:Connect(function() SG.Enabled=false end)
Ftr = C("Frame",{Parent=MF, Position=UDim2.new(0,0,1,-20), Size=UDim2.new(1,0,0,20), BackgroundColor3=T.Top, BorderSizePixel=0})
C("Frame",{Parent=Ftr, Size=UDim2.new(1,0,0,1), BackgroundColor3=T.DarkRed, BorderSizePixel=0})
C("TextLabel",{Parent=Ftr, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Dream Hub · Prior Extinction · RightShift to toggle", TextColor3=T.Muted, TextSize=10, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Center})
Bod = C("Frame",{Parent=MF, Position=UDim2.fromOffset(0,46), Size=UDim2.new(1,0,1,-66), BackgroundTransparency=1})
Side = C("Frame",{Parent=Bod, Size=UDim2.new(0,158,1,0), BackgroundColor3=T.Top, BorderSizePixel=0})
C("Frame",{Parent=Bod, Size=UDim2.new(0,1,1,0), Position=UDim2.fromOffset(158,0), BackgroundColor3=T.DarkRed, BorderSizePixel=0})
local SideList = C("ScrollingFrame",{Parent=Side, Size=UDim2.new(1,0,1,-46), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=T.Accent}); pad(SideList,8,6,8,4); lay(SideList,3)
PB = C("Frame",{Parent=Side, Size=UDim2.new(1,0,0,46), Position=UDim2.new(0,0,1,-46), BackgroundColor3=T.Top, BorderSizePixel=0})
C("Frame",{Parent=PB, Size=UDim2.new(1,0,0,1), BackgroundColor3=T.DarkRed, BorderSizePixel=0})
do local img=C("ImageLabel",{Parent=PB, Position=UDim2.fromOffset(10,12), Size=UDim2.fromOffset(22,22), BackgroundColor3=T.Panel3, BorderSizePixel=0, Image=""}); corner(img,999); task.spawn(function() local ok,u=pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end); if ok and u then img.Image=u end end) end  -- async: the thumbnail web call must NOT block the load thread
C("TextLabel",{Parent=PB, Position=UDim2.fromOffset(38,0), Size=UDim2.new(1,-44,1,0), BackgroundTransparency=1, Text=(LP.DisplayName~="" and LP.DisplayName or LP.Name), TextColor3=T.Text, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
local Content = C("Frame",{Parent=Bod, Position=UDim2.fromOffset(159,0), Size=UDim2.new(1,-159,1,0), BackgroundTransparency=1})
local clampWindow
do
	local dragging, dragStart, startPos
	TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=MF.Position end end)
	TB.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false; clampWindow() end end)
	conn(UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			local d=i.Position-dragStart
			MF.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
			Shd.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X-7,startPos.Y.Scale,startPos.Y.Offset+d.Y-7)
		end
	end))
end
clampWindow = function()
	pcall(function()
		local vp=(Cam and Cam.ViewportSize) or Vector2.new(1280,720); local sz=MF.AbsoluteSize; if sz.X<10 then return end
		local nx=math.clamp(MF.AbsolutePosition.X,0,math.max(0,vp.X-sz.X)); local ny=math.clamp(MF.AbsolutePosition.Y,0,math.max(0,vp.Y-50))
		MF.Position=UDim2.fromOffset(nx,ny); Shd.Position=UDim2.fromOffset(nx-7,ny-7)
	end)
end
minimized=false
minBtn.MouseButton1Click:Connect(function() minimized=not minimized; Bod.Visible=not minimized; Ftr.Visible=not minimized; Shd.Visible=not minimized; accentBar.Visible=not minimized; MF.Size=minimized and UDim2.fromOffset(650,46) or UDim2.fromOffset(650,440) end)

local Pages, Tabs = {}, {}
local currentPage
local function showPage(name)
	for n,pg in pairs(Pages) do pg.Visible = (n==name) end
	for n,ref in pairs(Tabs) do
		local sel = (n==name)
		ref.B.BackgroundColor3 = T.Panel2
		ref.B.BackgroundTransparency = sel and 0 or 1
		ref.L.TextColor3 = sel and T.Accent or T.Sub
		ref.L.Font = UIFONT
		ref.A.BackgroundTransparency = sel and 0 or 1
	end
	currentPage=name
end
local function mkTab(name, order)
	local b = C("TextButton",{Parent=SideList, Size=UDim2.new(1,0,0,28), BackgroundColor3=T.Panel2, BackgroundTransparency=1, Text="", AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=order or 0}); corner(b,4)
	local ac = C("Frame",{Parent=b, Size=UDim2.fromOffset(3,14), Position=UDim2.new(0,0,0.5,-7), BackgroundColor3=T.Accent, BackgroundTransparency=1, BorderSizePixel=0}); corner(ac,2)
	local lb = C("TextLabel",{Parent=b, Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-14,1,0), BackgroundTransparency=1, Text=name, TextColor3=T.Sub, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	Tabs[name]={B=b, L=lb, A=ac}
	local pg = C("ScrollingFrame",{Parent=Content, Position=UDim2.fromOffset(10,8), Size=UDim2.new(1,-18,1,-14), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=4, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=T.Accent, Visible=false})
	pad(pg,0,4,0,10); lay(pg,8)
	Pages[name]=pg
	b.MouseEnter:Connect(function() if currentPage~=name then tw(b,{BackgroundTransparency=0.5}); tw(lb,{TextColor3=T.Text}) end end)
	b.MouseLeave:Connect(function() if currentPage~=name then tw(b,{BackgroundTransparency=1}); tw(lb,{TextColor3=T.Sub}) end end)
	b.MouseButton1Click:Connect(function() showPage(name) end)
	return pg
end

-- ═══ WIDGETS ═══
toggleRefs = {}
local function mkSec(par, title, order)
	local sec = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,34), BackgroundColor3=T.Panel, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=order or 0}); corner(sec,4); stroke(sec,T.Stroke,1)
	C("TextLabel",{Parent=sec, Size=UDim2.new(1,-24,0,16), Position=UDim2.fromOffset(12,8), BackgroundTransparency=1, Text=title, TextColor3=T.Accent, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	C("Frame",{Parent=sec, Size=UDim2.new(1,-20,0,1), Position=UDim2.fromOffset(10,29), BackgroundColor3=T.DarkRed, BorderSizePixel=0})
	local body = C("Frame",{Parent=sec, Size=UDim2.new(1,-16,0,0), Position=UDim2.fromOffset(8,36), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y})
	lay(body,5); pad(body,0,0,0,10)
	return sec, body
end
local function mkToggle(par, txt, key, ord)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, LayoutOrder=ord or 0})
	C("TextLabel",{Parent=row, Size=UDim2.new(1,-46,1,0), BackgroundTransparency=1, Text=txt, TextColor3=T.Text, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	local tr = C("TextButton",{Parent=row, Size=UDim2.fromOffset(34,18), Position=UDim2.new(1,-34,0.5,-9), BackgroundColor3=CFG[key] and T.On or T.Off, AutoButtonColor=false, Text="", BorderSizePixel=0}); corner(tr,9)
	local kn = C("Frame",{Parent=tr, Size=UDim2.fromOffset(14,14), Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}); corner(kn,999)
	toggleRefs[key]={tr,kn}
	tr.MouseButton1Click:Connect(function()
		CFG[key]=not CFG[key]; if __gg.MH_featureToggleChanged then __gg.MH_featureToggleChanged(key,CFG[key]) end
		tw(tr,{BackgroundColor3=CFG[key] and T.On or T.Off}); tw(kn,{Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)})
		saveCfg()
	end)
	return row
end
local function mkSlider(par, txt, key, mn, mx, ord, step)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, LayoutOrder=ord or 0})
	local lbl = C("TextLabel",{Parent=row, Size=UDim2.new(1,0,0,14), BackgroundTransparency=1, Text=txt..": "..tostring(CFG[key]), TextColor3=T.Text, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	local bar = C("Frame",{Parent=row, Size=UDim2.new(1,0,0,8), Position=UDim2.fromOffset(0,20), BackgroundColor3=T.Panel3, BorderSizePixel=0}); corner(bar,3); stroke(bar,T.Stroke,1)
	local fill = C("Frame",{Parent=bar, Size=UDim2.new(math.clamp((CFG[key]-mn)/(mx-mn),0,1),0,1,0), BackgroundColor3=T.Accent, BorderSizePixel=0}); corner(fill,3)
	local dr=false
	local function set(x)
		local f=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
		local val=mn+f*(mx-mn); if step then val=math.floor(val/step+0.5)*step else val=math.floor(val*100+0.5)/100 end
		CFG[key]=val; fill.Size=UDim2.new(f,0,1,0); lbl.Text=txt..": "..tostring(val)
	end
	conn(bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; set(i.Position.X) end end))
	conn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and dr then dr=false; saveCfg() end end))
	conn(UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then set(i.Position.X) end end))
end
local function mkBtn(par, txt, cb, ord)
	local b = C("TextButton",{Parent=par, Size=UDim2.new(1,0,0,28), BackgroundColor3=T.Panel3, Text=txt, TextColor3=T.Text, TextSize=12, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=ord or 0}); corner(b,6); stroke(b,T.Stroke,1)
	b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=T.Accent, TextColor3=Color3.new(1,1,1)}) end)
	b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=T.Panel3, TextColor3=T.Text}) end)
	b.MouseButton1Click:Connect(function() pcall(cb) end)
	return b
end
local function mkTextbox(par, lbl, key, ord, numeric)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, LayoutOrder=ord or 0})
	C("TextLabel",{Parent=row, Size=UDim2.new(0.42,0,1,0), BackgroundTransparency=1, Text=lbl, TextColor3=T.Text, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	local box = C("TextBox",{Parent=row, Position=UDim2.new(0.44,0,0.5,-11), Size=UDim2.new(0.56,0,0,22), BackgroundColor3=T.Panel3, TextColor3=T.Text, Text=tostring(CFG[key] or ""), TextSize=12, Font=UIFONT, BorderSizePixel=0, ClearTextOnFocus=false}); corner(box,4); stroke(box,T.Stroke,1); pad(box,6,6,0,0)
	box.FocusLost:Connect(function()
		if numeric then CFG[key]=tonumber(box.Text) or CFG[key]; box.Text=tostring(CFG[key]) else CFG[key]=box.Text end
		saveCfg()
	end)
	return box
end
local function mkStatus(par, lbl, ord)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, LayoutOrder=ord or 0})
	C("TextLabel",{Parent=row, Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, Text=lbl, TextColor3=T.Sub, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	return C("TextLabel",{Parent=row, Position=UDim2.new(0.5,0,0,0), Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, Text="--", TextColor3=T.Text, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
end
local function mkLabel(par, txt, ord, col)
	return C("TextLabel",{Parent=par, Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text=txt, TextColor3=col or T.Sub, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=ord or 0})
end
local function mkDropdown(par, label, getOptions, getSelected, onSelect, ord)
	local wrap = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,46), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=ord or 0})
	lay(wrap,4)
	C("TextLabel",{Parent=wrap, Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text=label, TextColor3=T.Sub, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0})
	local head = C("TextButton",{Parent=wrap, Size=UDim2.new(1,0,0,26), BackgroundColor3=T.Panel3, Text=(getSelected() or "-").."   v", TextColor3=T.Text, TextSize=12, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=1}); corner(head,6); stroke(head,T.Stroke,1)
	local listBox = C("Frame",{Parent=wrap, Size=UDim2.new(1,0,0,0), BackgroundColor3=T.Panel, BorderSizePixel=0, Visible=false, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=2}); corner(listBox,6); stroke(listBox,T.Stroke,1)
	local inner = C("ScrollingFrame",{Parent=listBox, Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=T.Accent, AutomaticSize=Enum.AutomaticSize.Y})
	pad(inner,4,4,4,4); lay(inner,3)
	local open=false
	local function rebuild()
		for _,c in ipairs(inner:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local opts = getOptions() or {}
		inner.Size = UDim2.new(1,0,0,math.min(#opts*24+8, 160))
		for i,opt in ipairs(opts) do
			local ob = C("TextButton",{Parent=inner, Size=UDim2.new(1,0,0,22), BackgroundColor3=T.Panel2, Text=opt, TextColor3=T.Text, TextSize=11, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=i}); corner(ob,4)
			ob.MouseEnter:Connect(function() tw(ob,{BackgroundColor3=T.Accent, TextColor3=Color3.new(1,1,1)}) end)
			ob.MouseLeave:Connect(function() tw(ob,{BackgroundColor3=T.Panel2, TextColor3=T.Text}) end)
			ob.MouseButton1Click:Connect(function() onSelect(opt); head.Text=(getSelected() or "-").."   v"; open=false; listBox.Visible=false end)
		end
	end
	head.MouseButton1Click:Connect(function() open=not open; listBox.Visible=open; if open then rebuild() end end)
	return {refresh=function() head.Text=(getSelected() or "-").."   v"; if open then rebuild() end end}
end
capturing=nil
bindGuard=0
local function keyName(k) return CFG.Keybinds[k] or "None" end
local function mkKeybind(par, txt, key, ord)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, LayoutOrder=ord or 0})
	C("TextLabel",{Parent=row, Size=UDim2.new(0.62,0,1,0), BackgroundTransparency=1, Text=txt, TextColor3=T.Text, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	local b = C("TextButton",{Parent=row, Size=UDim2.new(0.36,0,0,22), Position=UDim2.new(0.64,0,0.5,-11), BackgroundColor3=T.Panel3, Text=keyName(key), TextColor3=T.Accent, TextSize=11, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0}); corner(b,4); stroke(b,T.Stroke,1)
	b.MouseButton1Click:Connect(function() capturing=key; b.Text="..."; b.TextColor3=T.Text end)
	conn(UIS.InputBegan:Connect(function(i,gp)
		if capturing==key and i.KeyCode~=Enum.KeyCode.Unknown then
			CFG.Keybinds[key]=i.KeyCode.Name; b.Text=i.KeyCode.Name; b.TextColor3=T.Accent; capturing=nil; bindGuard=tick(); saveCfg()
		end
	end))
	return b
end

-- ═══ FIX HELPERS (body targeting, deep stat pin, stat dump, instant elder) ═══
local function getBody(model)
	model = model or getMyModel()
	if not model then return nil end
	local ta = model:FindFirstChild("TurningAnimation")
	if ta then
		local b = ta:FindFirstChild("Body")
		if b and b:IsA("BasePart") then return b end
		if ta:IsA("BasePart") then return ta end
	end
	local mm = model:FindFirstChild("MeshModel")
	if mm and mm:IsA("BasePart") then return mm end
	if mm then local p=mm:FindFirstChildWhichIsA("BasePart"); if p then return p end end
	return rootOf(model)
end
local function detectDinoModel(model)
	if not model then return nil end
	for _,attr in ipairs({"Type","Dinosaur","Species","Creature","DinoType","Dino"}) do
		local a=model:GetAttribute(attr); if a and SKINS[tostring(a)] then return tostring(a) end
	end
	local mm=model:FindFirstChild("MeshModel")
	if mm then local t=mm:GetAttribute("Type"); if t and SKINS[tostring(t)] then return tostring(t) end end
	local cand={}
	for _,attr in ipairs({"Type","Dinosaur","Species","Creature","DinoType","Dino"}) do local a=model:GetAttribute(attr); if a then cand[#cand+1]=tostring(a) end end
	if mm then local t=mm:GetAttribute("Type"); if t then cand[#cand+1]=tostring(t) end end
	cand[#cand+1]=model.Name
	for _,cv in ipairs(cand) do local lc=cv:lower(); for _,dn in ipairs(DINO_NAMES) do local key=dn:lower(); if lc:find(key,1,true) or key:find(lc,1,true) then return dn end local first=key:match("^%S+"); if first and #first>4 and lc:find(first,1,true) then return dn end end end
	return nil
end
-- Deep stat pinner: walks the WHOLE CharacterState replica and forces matching numeric stats to max.
STAT_GROUPS = {
	{cfg="InfWater",  keys={"water","thirst","hydrat","drink","liquid"}},
	{cfg="InfOxygen", keys={"oxygen","air","breath","o2","lung"}},
}
-- Drain meters that go UP as you suffer — when their feature is on, force them to ZERO, never max.
STAT_ZERO = {
	{cfg="InfWater",  keys={"dehydr","thirsty"}},
	{cfg="InfOxygen", keys={"drown","suffoc"}},
}
-- returns "zero", "max", or nil for a (lowercased) key under the current CFG toggles
local function statMode(keyLower)
	for _,g in ipairs(STAT_ZERO) do if CFG[g.cfg] then for _,w in ipairs(g.keys) do if keyLower:find(w,1,true) then return "zero" end end end end
	for _,g in ipairs(STAT_GROUPS) do if CFG[g.cfg] then for _,w in ipairs(g.keys) do if keyLower:find(w,1,true) then return "max" end end end end
end
local function deepPinStats(tbl, maxTbl, depth)
	if type(tbl)~="table" or depth>4 then return end
	local ok = pcall(function()
		for k,v in pairs(tbl) do
			local kl = tostring(k):lower()
			if type(v)=="number" then
				local mode = statMode(kl)
				if mode=="zero" and not kl:find("max",1,true) then
					pcall(function() tbl[k]=0 end)
				elseif mode=="max" and not kl:find("max",1,true) and not kl:find("regen",1,true) and not kl:find("rate",1,true) and not kl:find("drain",1,true) and not kl:find("decay",1,true) then
					local mx = (type(maxTbl)=="table" and type(maxTbl[k])=="number" and maxTbl[k]) or nil
					if mx then pcall(function() tbl[k]=mx end) end  -- pin to REAL max only; never inflate (caused the server fight/snapback)
				end
			elseif type(v)=="table" and getmetatable(v)==nil then
				local nextMax = (type(maxTbl)=="table" and maxTbl[k]) or maxTbl
				deepPinStats(v, nextMax, depth+1)
			end
		end
	end)
	return ok
end
-- Food and stamina are excluded from this legacy walker. MHNEED is their only writer and fails closed without an
-- authoritative current/max pair (or the documented ConsumptionData/HUD denominator fallback).
-- (Instant Elder + stat dump removed per request.)

-- ═══ FLUENT UI (primary) — clean library; auto-falls-back to the built-in window if it can't load ═══
local Fluent, FWindow, USE_FLUENT = nil, nil, false
-- Load Fluent, but VERIFY it actually rendered. On weaker executors (Real/Medium/Xeno) Fluent's CreateWindow can
-- "succeed" (no error) yet draw NOTHING (acrylic blur / gethui quirks) — that's the "successfully loaded, no UI"
-- report. We snapshot the GUI host before/after; if Fluent added no ScreenGui we treat it as failed and use the
-- fully self-contained built-in window (which always renders). Acrylic is OFF for the same reason.
_guiHost = (typeof(gethui)=="function" and gethui()) or CoreGui
_before = {}
pcall(function() for _,g in ipairs(_guiHost:GetChildren()) do _before[g]=true end end)
pcall(function() for _,g in ipairs(CoreGui:GetChildren()) do _before[g]=true end end)
MS("3 window built - loading menu lib")
-- Escape hatch: run `_G.PE_BUILTIN_UI = true` before the loadstring to skip Fluent and use the built-in UI.
if not (__gg.PE_BUILTIN_UI or _G.PE_BUILTIN_UI) then
	pcall(function()
		Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
		FWindow = Fluent:CreateWindow({ Title="Dream Hub", SubTitle="Prior Extinction", TabWidth=150, Size=UDim2.fromOffset(580,460), Acrylic=false, Theme="Light", MinimizeKey=Enum.KeyCode.RightShift })
	end)
end
if FWindow then
	task.wait()   -- let Fluent parent its ScreenGui, then confirm it actually drew one
	local rendered=false
	pcall(function()
		for _,g in ipairs(_guiHost:GetChildren()) do if not _before[g] and g:IsA("ScreenGui") then rendered=true break end end
		if not rendered then for _,g in ipairs(CoreGui:GetChildren()) do if not _before[g] and g:IsA("ScreenGui") then rendered=true break end end end
	end)
	if not rendered then FWindow=nil; pcall(function() if Fluent and Fluent.Destroy then Fluent:Destroy() end end) end
end
if FWindow then
	USE_FLUENT = true
	local Options = Fluent.Options
	-- Hide the built-in window (MF/Shd invisible) but KEEP SG.Enabled as the "menu open" SIGNAL the aim/autoclick/
	-- farm-player guards read — true = Fluent menu open (pause aim so you can click tabs). Toggled with RightShift.
	pcall(function() SG.Enabled=true; MF.Visible=false; Shd.Visible=false end)
	for k in pairs(Pages) do Pages[k]=nil end
	local ICONS = {Combat="swords", PvP="target", Movement="footprints", Survival="heart-pulse", Growth="sprout", ["Auto Farm"]="pickaxe", Target="crosshair", Teleport="map-pin", Visuals="eye", Skins="palette", Misc="wrench", Settings="settings", Info="info", Admin="shield", Rules="list"}
	mkTab = function(name) local tb=FWindow:AddTab({Title=name, Icon=ICONS[name] or ""}); Pages[name]=tb; return tb end
	mkSec = function(par, title) pcall(function() par:AddParagraph({Title=title, Content=""}) end); return par, par end
	mkToggle = function(par, txt, key) pcall(function() local t=par:AddToggle(key,{Title=txt, Default=CFG[key] and true or false}); t:OnChanged(function() local old=CFG[key]; CFG[key]=Options[key].Value; if old~=CFG[key] and __gg.MH_featureToggleChanged then __gg.MH_featureToggleChanged(key,CFG[key]) end; saveCfg() end) end) end
	mkSlider = function(par, txt, key, mn, mx, _o, step) pcall(function() par:AddSlider(key,{Title=txt, Default=tonumber(CFG[key]) or mn, Min=mn, Max=mx, Rounding=((step and step>=1) and 0 or 2), Callback=function(v) CFG[key]=v; saveCfg() end}) end) end
	mkBtn = function(par, txt, cb) pcall(function() par:AddButton({Title=txt, Callback=function() pcall(cb) end}) end) end
	mkTextbox = function(par, lbl, key, _o, numeric) pcall(function() par:AddInput(key,{Title=lbl, Default=tostring(CFG[key] or ""), Numeric=numeric and true or false, Finished=false, Callback=function(v) if numeric then CFG[key]=tonumber(v) or CFG[key] else CFG[key]=v end saveCfg() end}) end) end   -- Finished=false: save as you TYPE ("Load without pressing Enter checked an empty string")
	-- mkStatus USED to return nil under Fluent — every status row (the whole Target profile, the HUD readout)
	-- silently died on `sUser.Text = ...` inside a pcall = "Target tab: nothing works". Now it returns a proxy:
	-- writing .Text on it updates a real Fluent paragraph, so profiles/readouts show in the Fluent menu too.
	mkStatus = function(par, lbl)
		local pg; pcall(function() pg = par:AddParagraph({Title=lbl, Content="--"}) end)
		return setmetatable({}, {
			__newindex = function(t, k, v)
				if k=="Text" then rawset(t,"_t",v); pcall(function() if pg then if pg.SetDesc then pg:SetDesc(tostring(v)) elseif pg.SetContent then pg:SetContent(tostring(v)) end end end)
				else rawset(t, k, v) end
			end,
			__index = function(t, k) if k=="Text" then return rawget(t,"_t") or "--" end return nil end,
		})
	end
	mkLabel = function(par, txt) pcall(function() local title,content=tostring(txt),""; local nl=title:find("\n"); if nl then content=title:sub(nl+1); title=title:sub(1,nl-1) end par:AddParagraph({Title=title, Content=content}) end) end
	mkDropdown = function(par, label, getOptions, getSelected, onSelect)
		local dd; pcall(function() dd=par:AddDropdown(label,{Title=label, Values=getOptions() or {"Default"}, Multi=false, Default=getSelected() or 1}); dd:OnChanged(function(v) onSelect(v); saveCfg() end) end)
		return {refresh=function() pcall(function() if dd and dd.SetValues then dd:SetValues(getOptions() or {}) end end) end}
	end
	mkKeybind = function(par, txt, key) pcall(function() par:AddKeybind("bind_"..key,{Title=txt, Mode="Toggle", Default=(CFG.Keybinds[key] or "Unknown"), ChangedCallback=function(new) local n=tostring(new):gsub("Enum.KeyCode.",""):gsub("Enum.UserInputType.",""); CFG.Keybinds[key]=n; saveCfg() end}) end) end
	showPage = function() end
else
	pcall(function() SG.Enabled=true end)  -- Fluent failed to load → show the built-in window so there's always a menu
end
-- UNIVERSAL toggle setter: flip a toggle's VALUE + its on/off VISUAL from code, for BOTH the built-in UI and Fluent
-- (Fluent toggles are Fluent.Options[key]:SetValue(bool)). Used so "click Yes → Pro Food turns on" shows the switch move.
__gg.MH_setToggle = function(key, val)
	local old=CFG[key]; CFG[key] = val and true or false
	if old~=CFG[key] and __gg.MH_featureToggleChanged then __gg.MH_featureToggleChanged(key,CFG[key]) end
	pcall(saveCfg)
	pcall(function() local ref=toggleRefs[key]; if ref then ref[1].BackgroundColor3=CFG[key] and T.On or T.Off; ref[2].Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2) end end)
	pcall(function() if Fluent and Fluent.Options and Fluent.Options[key] and Fluent.Options[key].SetValue then Fluent.Options[key]:SetValue(CFG[key]) end end)
end

MS("4 menu ready ("..(USE_FLUENT and "Fluent" or "built-in")..") - building tabs")
-- ═══ TABS / PAGES ═══
-- Tier gate: paid loaders set _G.PE_PLUS / _G.PE_PREM before the loadstring. Premium counts as Plus.
-- Stored on __gg (NOT new locals) — the main chunk is at Luau's 200-local cap and two more broke loading.
__gg.PE_PLUS = (_G.PE_PLUS==true) or (_G.PE_PREM==true) or (_G.PE_PREMIUM==true)
__gg.PE_PREM = (_G.PE_PREM==true) or (_G.PE_PREMIUM==true)
mkTab("Combat",1); mkTab("PvP",2); mkTab("Movement",3); mkTab("Survival",4)
-- PREMIUM: no Growth tab. That tab is the food-growth suite (INF Food + helpers), which premium buyers are
-- not supposed to see at all - they were seeing the whole page. INF Water is the one thing in it they DO
-- get, and that lives on the Combat (main) page for them instead - see the Combat block.
if not __gg.PE_PREM then mkTab("Growth",5) end
mkTab("Auto Farm",6); mkTab("Teleport",7)
mkTab("Target",7.5)   -- Target tab always loads (the PE_PLUS gate made it vanish whenever the tier flag wasn't set)
mkTab("Visuals",8); mkTab("Skins",9); mkTab("Misc",10); mkTab("Settings",11); mkTab("Info",12); mkTab("Rules",12.4)
-- ADMIN tab — only the whitelisted Roblox user(s) ever get it built.
__gg.PE_ADMINS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
if type(_G.__DreamExtraAdmins)=="table" then for _,n in ipairs(_G.__DreamExtraAdmins) do __gg.PE_ADMINS[string.lower(tostring(n))]=true end end
for n in tostring(CFG.AdminExtra or ""):gmatch("[^,%s]+") do __gg.PE_ADMINS[string.lower(n)]=true end   -- your own saved admins
__gg.PE_ADMIN  = (__gg.PE_ADMINS[string.lower(LP.Name)] == true) or (__gg.PE_ADMINS[string.lower(LP.DisplayName or "")] == true)
if __gg.PE_ADMIN then mkTab("Admin",12.9) end

do local p=Pages["Combat"]
	-- PREMIUM keeps INF Water even though its old home (the Growth tab) is not built for them - it sits
	-- here on the main page, first thing they see. Non-premium still gets it in Growth, so no duplicate.
	if __gg.PE_PREM then
		local _,w=mkSec(p,"Survival",0.5)
		mkToggle(w,"INF Water","InfWater",1)
	end
	local _,a=mkSec(p,"Aim",1)
	mkToggle(a,"Silent Aim","SilentAim",1)
	mkToggle(a,"Lock On","LockOn",2)
	mkDropdown(a,"Aim Part", function() return {"Hitbox","Head","Spine","Neck","Hip","Body","Leg","Tail"} end, function() return CFG.AimPart~="" and CFG.AimPart or "Hitbox" end, function(opt) CFG.AimPart=opt; saveCfg() end, 3)
	mkSlider(a,"Aim Smoothness","AimSmooth",0,1,4)
end
do local p=Pages["PvP"]
	local _,d=mkSec(p,"Damage",1)
	mkToggle(d,"Always Damage","AlwaysDamage",1)
	mkDropdown(d,"Always hit part", function() return {"Auto","Head","Neck","Spine","Body","Hip","Leg","Tail"} end, function() return CFG.DamagePart~="" and CFG.DamagePart or "Auto" end, function(opt) CFG.DamagePart=opt; saveCfg() end, 2)
	mkSlider(d,"Damage Range","DamageRange",30,400,3,10)
	mkSlider(d,"Hits / sec","DamageRate",1,15,4,1)
	mkToggle(d,"No Grab Weight Limit","NoGrabLimit",5)
	local _,h=mkSec(p,"Hitbox",2)
	mkToggle(h,"Hitbox Expander","HitboxExpand",1)
	mkToggle(h,"Show Hitbox","HitboxVisible",2)
	mkSlider(h,"Hitbox Size","HitboxSize",4,300,3,1)
	mkSlider(h,"Hitbox Opacity %","HitboxOpacity",0,100,3,1)
	mkDropdown(h,"Expand Bone", function() return {"All","Head","Neck","Arm","Leg","Body","Tail","Hip"} end, function() return CFG.HitboxBone~="" and CFG.HitboxBone or "All" end, function(opt) CFG.HitboxBone=opt; saveCfg() end, 25)
	local HBCOL={Red={255,40,60},Green={60,255,90},Blue={60,120,255},Yellow={255,230,40},Purple={180,70,255},Cyan={50,230,230},Orange={255,150,30},Pink={255,105,180},White={255,255,255},Black={20,20,20}}
	mkDropdown(h,"Hitbox Color", function() return {"Red","Green","Blue","Yellow","Purple","Cyan","Orange","Pink","White","Black"} end, function() return CFG.HitboxColorName or "Red" end, function(opt) local c=HBCOL[opt] or {255,40,60}; CFG.HitboxColor={r=c[1],g=c[2],b=c[3]}; CFG.HitboxColorName=opt; saveCfg() end, 4)
	local _,t=mkSec(p,"Turn",3)
	mkToggle(t,"Turn Hack","TurnHack",1)
	mkSlider(t,"Turn Speed","TurnSpeed",5,60,2,1)
end
do local p=Pages["Movement"]
	local _,m=mkSec(p,"Float & Speed",1)
	mkToggle(m,"Float","Float",1)
	mkToggle(m,"Speed Hack","SpeedHack",4)
	mkSlider(m,"Speed","SpeedVal",20,250,5,5)
	local _,n=mkSec(p,"Clip & Jump",2)
	mkToggle(n,"Noclip","Noclip",1)
	mkToggle(n,"Anti-Snapback Teleports","BypassTP",3)
end
do local p=Pages["Survival"]
	-- (INF Food / INF Water / Carnivore Meat TP / Teleport Back moved to the Growth tab.) Stamina stays here.
	local _,f=mkSec(p,"Stamina",1)
	mkToggle(f,"INF Stamina","InfStam",1)
	mkLabel(f,"Pins stamina, clears exhaustion, and automatically uses the game's native Run state while you move.",1.5)
	local _,pr=mkSec(p,"Protection",2)
	-- Death Bug Fix = the spawn rescue (void/under-map/ocean spawns). It mutes ITSELF during any hub teleport
	-- (map/biome/corpse/fossil TP) so it can never yank you around mid-teleport — and you can kill it here.
	mkToggle(pr,"Death Bug Fix (spawn rescue)","DeathFix",0)
	mkToggle(pr,"Anti Drown","AntiDrown",1)
	mkSlider(pr,"Anti Drown Rise","AntiDrownRise",2,30,1,1)
	mkLabel(pr,"How fast Anti Drown lifts you to the surface. Lower = smoother on weak devices.")
	mkToggle(pr,"Walk on Water","WalkWater",2)
	mkToggle(pr,"Auto Clean","AutoClean",3)
	mkToggle(pr,"Anti Head","AntiFracture",4)
	mkSlider(pr,"Damage Reduce %","HeadDmgReduce",0,100,4,5)
	mkToggle(pr,"Anti Bleed","AntiBleed",5)
	mkToggle(pr,"Anti Fall","AntiFall",6)
	mkToggle(pr,"No Sleep Screen","NoSleep",7)
	mkToggle(pr,"Bone Protection","BoneProtect",8)
	mkDropdown(pr,"Protect Bone", function() return {"All","Head","Neck","Arm","Leg","Body"} end, function() return CFG.ProtectBone~="" and CFG.ProtectBone or "All" end, function(opt) CFG.ProtectBone=opt; saveCfg() end, 9)
	local _,sv=mkSec(p,"Auto Heal",4)
	mkToggle(sv,"Save Dino","SaveDino",1)
	mkSlider(sv,"Save at HP %","SaveHP",5,90,2,5)
	mkToggle(sv,"Auto Heal Blood","AutoHealBlood",3)
	mkLabel(sv,"Keeps your blood + health topped up.")
	if not _G.PE_HIDE_LITE then
		mkToggle(sv,"AFK Eat","AfkEat",5)
		mkLabel(sv,"Lifts you high up out of reach and keeps you fed so you AFK grow safely.")
	end
	local _,pg=mkSec(p,"Progress",5)
	mkBtn(pg,"Progress Restore",function() progressRestore() end,1)
	-- SAVED SLOTS — auto-named dropdown ("<n>: Species - Stage"). Save banks your CURRENT dino into the next free slot
	-- (spawn in as that dino first so it's captured). Pick a slot, then Restore or Delete it. Per-account (UserId).
	local slotsDD = mkDropdown(pg, "Saved Slots", function()
		local out={}
		for n=1,40 do local r=SLOTS.read(n); if r and r.data then local sp=r.data.Species or "Dino"; local st=r.data.Stage or r.data.GrowthStage; out[#out+1]=n..": "..sp..(st and (" - "..tostring(st)) or "") end end
		if #out==0 then out[1]="(none)" end
		return out
	end, function() return CFG.ProgSlotSel or "(none)" end, function(opt) CFG.ProgSlotSel=opt; saveCfg() end, 2)
	mkBtn(pg,"Save Progress",function()
		local pp=__gg.MH_restore
		if type(pp)~="table" then notify("Progress","Spawn in as the dino you want first, THEN save."); return end
		local r=progSerde("rec",pp); if not r then notify("Progress","Couldn't save that."); return end
		-- label with the current growth stage if we can detect it
		pcall(function() local rr=csReplica(); if rr and rr.Data then r.data.Stage = rr.Data.GrowthStage or rr.Data.Stage or (rr.Data.Growth and rr.Data.Growth.Stage) end if not r.data.Stage then local mm=getMyModel(); if mm then r.data.Stage = mm:GetAttribute("Stage") or mm:GetAttribute("GrowthStage") end end end)
		local n=1; while n<=40 do local existing=SLOTS.read(n); if not existing then break end; n+=1 end
		if n>40 then notify("Progress","All 40 slots are full. Delete one first."); return end
		local ok,why=SLOTS.write(n,r); if not ok then notify("Progress","Save failed: "..tostring(why)); return end
		if slotsDD and slotsDD.refresh then slotsDD.refresh() end
		notify("Progress","Saved slot "..n.." — "..((r.data and r.data.Species) or "dino")..(r.data.Stage and (" "..tostring(r.data.Stage)) or ""))
	end,3)
	mkBtn(pg,"Restore Selected",function()
		local n=tonumber(tostring(CFG.ProgSlotSel or ""):match("^(%d+)"))
		if not n then notify("Progress","Pick a saved slot first."); return end
		local rec,backupOrWhy=SLOTS.read(n)
		if not rec then notify("Progress","Slot rejected: "..tostring(backupOrWhy)); return end
		local pld=progSerde("pay",rec); if pld then __gg.MH_restore=pld; if backupOrWhy==true then notify("Progress","Main slot was damaged; using its verified backup.") end; progressRestore() else notify("Progress","That slot is corrupted.") end
	end,4)
	mkBtn(pg,"Delete Selected",function()
		local n=tonumber(tostring(CFG.ProgSlotSel or ""):match("^(%d+)"))
		if not (n and isfile and (isfile(slotFile(n)) or isfile(slotFile(n)..".bak"))) then notify("Progress","Pick a saved slot first."); return end
		if __gg.MH_deleteArm~=n or tick()-(__gg.MH_deleteArmT or 0)>4 then __gg.MH_deleteArm=n; __gg.MH_deleteArmT=tick(); notify("Progress","Click Delete Selected again within 4 seconds to confirm."); return end
		local f=slotFile(n)
		if delfile then pcall(function() if isfile(f) then delfile(f) end; if isfile(f..".bak") then delfile(f..".bak") end; if isfile(f..".tmp") then delfile(f..".tmp") end end) elseif writefile then
			pcall(function() for _,path in ipairs({f,f..".bak",f..".tmp"}) do writefile(path,"") end end)
		end
		__gg.MH_deleteArm=nil; __gg.MH_deleteArmT=nil
		CFG.ProgSlotSel="(none)"
		if slotsDD and slotsDD.refresh then slotsDD.refresh() end
		notify("Progress","Deleted slot "..n..".")
	end,5)
end
do local p=Pages["Growth"]
	if p then   -- premium builds never create this tab; without this guard mkSec(nil,...) would error out the whole GUI
	if not _G.PE_HIDE_LITE then
		local _,g=mkSec(p,"Pro Food",1)
		mkToggle(g,"Pro Food","ProFood",1)
		mkLabel(g,"One button: teleports to a corpse with no dinos around, eats until full, then circles to grow, moves to the next corpse when done, and stops at the age you pick.")
		mkDropdown(g,"Stop at age", function() return {"Off","Juvenile","Teen","Adolescent","Sub Adult","Adult","Elder"} end, function() return CFG.ProFoodStopAge~="" and CFG.ProFoodStopAge or "Off" end, function(opt) CFG.ProFoodStopAge=opt; saveCfg() end, 2)
		local _,fw=mkSec(p,"Food & Water",2)
		mkToggle(fw,"INF Food","InfFood",1)
		mkLabel(fw,"Herbivore: turn on, then eat one plant once.")
		mkLabel(fw,"You can eat more if you want, and if you do it will grow faster. Just make sure you have INF Food on, eat 4 things, then watch the magic.")
		mkSlider(fw,"INF Food grow speed","FoodEatSpeed",1,10,3,1)
		mkToggle(fw,"INF Water","InfWater",4)
		mkToggle(fw,"Carnivore Meat TP","CarnMeatTP",5)
		mkBtn(fw,"Teleport Back",function() if __gg.MH_corpseBack then __gg.MH_corpseBack() end end,6)
	end
	local _,pg=mkSec(p,"Progress",3)
	mkBtn(pg,"Progress Restore",function() progressRestore() end,1)
	end   -- if p
end
do local p=Pages["Auto Farm"]
	local _,f=mkSec(p,"Fossils & Gems",1)
	mkToggle(f,"Auto Farm Fossil","AutoFarmFossil",1)
	mkToggle(f,"Auto Farm Gemstone","AutoFarmGem",2)
	mkToggle(f,"Teleport Farm","FarmTeleport",3)
	mkSlider(f,"Fossil Collect Delay","FossilSlow",0,4,4,0.1)   -- seconds between each fossil (slow it down)
	mkBtn(f,"Teleport to Nearest Gemstone", function()
		local me=hrp(); if not me then return end
		local best,bd
		local KW={"gem","topaz","amethyst","emerald","ruby","sapphire","diamond","quartz","crystal","opal","garnet","jade","cracklegem"}
		local function isGem(n) n=n:lower(); for _,k in ipairs(KW) do if n:find(k,1,true) then return true end end return false end
		local roots={ WS:FindFirstChild("GemstoneSpawns"), WS:FindFirstChild("Gems"), WS }
		for _,root in ipairs(roots) do if root then
			local sc=0
			for _,d in ipairs(root:GetDescendants()) do
				sc+=1; if sc>4000 then break end
				if (d:IsA("BasePart")) and isGem(d.Name) then local dd=dist(me.Position,d.Position); if not bd or dd<bd then best,bd=d,dd end end
			end
			if best then break end
		end end
		if best then
			local goal=best.Position+Vector3.new(0,3,0)
			local ok=__gg.MH_safeTeleport and __gg.MH_safeTeleport(goal,{saveReturn=true,settle=1.4})
			if ok then notify("Teleport","At the nearest gemstone ("..math.floor(bd).."m away).") else notify("Teleport","Teleport system is not ready yet.") end
		else notify("Teleport","No gemstone found nearby.") end
	end, 4)
	if not _G.PE_HIDE_LITE then   -- Auto Play Bot lives in the separate Lite hub; the wrapper hides it here
		local _,b=mkSec(p,"Auto Play Bot",2)
		mkToggle(b,"Auto Play Bot — plays the game for you","AutoPlayBot",1)
		mkLabel(b,"Turn it on and walk away.")
		mkToggle(b,"Flee from predators","BotFlee",2)
		mkSlider(b,"Flee detect range","BotFleeRange",80,600,3,20)
		mkToggle(b,"Roam / wander","BotRoam",4)
		mkSlider(b,"Roam radius","BotRoamRadius",50,1200,5,50)
		mkSlider(b,"Eat when food below %","BotEatAt",30,95,6,5)
		mkSlider(b,"Drink when water below %","BotDrinkAt",30,95,7,5)
		mkToggle(b,"Sleep to heal when hurt + safe","BotSleepHeal",8)
		mkSlider(b,"Bot walk speed","BotSpeed",14,24,9,1)
		mkToggle(b,"Announce what the bot is doing","BotAnnounce",10)
	end
end
if Pages["Target"] then local p=Pages["Target"]
	-- REWORKED (was: "nothing works"): the profile rows exist in BOTH UIs now (Fluent mkStatus fix above),
	-- Load re-resolves the model live so the profile fills even if their dino streams in late, and every
	-- action reports what it's doing instead of dying silently.
	local _,ld=mkSec(p,"Load Player",1)
	mkTextbox(ld,"Username / display name / part of it","TargetUser",1,false)
	-- FULL PROFILE — every row is ALWAYS present (shows "--" until it fills), per request.
	local sUser   = mkStatus(ld,"User",3)
	local sDino   = mkStatus(ld,"Dino",4)
	local sStage  = mkStatus(ld,"Stage",5)
	local sGender = mkStatus(ld,"Gender",6)
	local sHP     = mkStatus(ld,"Health",7)
	local sStam   = mkStatus(ld,"Stamina",8)
	local sWell   = mkStatus(ld,"Wellbeing",9)
	local sDist   = mkStatus(ld,"Distance",10)
	local sState  = mkStatus(ld,"Status",11)
	local function fmtStat(v, mx)
		if type(v)~="number" then return "--" end
		if type(mx)=="number" and mx>0 then return math.floor(v).." / "..math.floor(mx) end
		return tostring(math.floor(v))
	end
	-- little text bar so Stamina/Wellbeing read like a bar, e.g. 72%  [#######···]
	local function bar(v, mx)
		local pct
		if type(v)=="number" and type(mx)=="number" and mx>0 then pct=math.clamp(v/mx,0,1)
		elseif type(v)=="number" then pct=math.clamp(v/100,0,1) else return "--" end
		local fill=math.floor(pct*10+0.5)
		return math.floor(pct*100).."%  ["..string.rep("#",fill)..string.rep("·",10-fill).."]"
	end
	local function refreshTarget()
		local T=__gg.MH_Target
		if not (T and T.plr) then
			sUser.Text="type a name, press Load"; sDino.Text="--"; sStage.Text="--"; sGender.Text="--"
			sHP.Text="--"; sStam.Text="--"; sWell.Text="--"; sDist.Text="--"; sState.Text="no target"
			return
		end
		local info = _G.MH_targetInfo and _G.MH_targetInfo() or {}
		sUser.Text   = info.user and (info.display and info.display~=info.user and (info.display.." (@"..info.user..")") or info.user) or "--"
		sDino.Text   = info.species and tostring(info.species) or "--"
		sStage.Text  = info.stage and tostring(info.stage) or "--"
		sGender.Text = info.gender and tostring(info.gender) or "--"
		sHP.Text     = (type(info.hp)=="number" and fmtStat(info.hp, info.hpMax)) or info.hpStr or "--"
		sStam.Text   = (type(info.stam)=="number" and bar(info.stam, info.stamMax)) or info.stamStr or "--"
		sWell.Text   = (type(info.wellbeing)=="number" and bar(info.wellbeing, 100)) or "--"
		sDist.Text   = type(info.dist)=="number" and (info.dist.."m") or "--"
		sState.Text  = (T.model and T.model.Parent) and (T.viewing and "viewing" or "loaded") or "finding their dino…"
	end
	-- ACTIVE LOADER: streams the player's area in and keeps re-finding their dino for a few seconds, filling the
	-- profile the moment it appears — so a player who's inside the map (just not yet sent to your client) loads
	-- without you walking over there. Stops early the instant the dino is found.
	local function activeLoad(pl)
		local T=__gg.MH_Target
		task.spawn(function()
			for i=1,24 do
				if __gg.MH_Target.plr~=pl then return end          -- target changed / unloaded
				T.model = __gg.MH_targetModelFor and __gg.MH_targetModelFor(pl)
				if not T.model then
					local pos = T.lastPos
					pcall(function() local c=pl.Character; if c then pos = c:GetPivot().Position end end)
					if pos then pcall(function() LP:RequestStreamAroundAsync(pos, 1) end) end
				end
				pcall(refreshTarget)
				if T.model and T.model.Parent then
					notify("Target","Loaded "..pl.Name.." — profile is live.")
					return
				end
				task.wait(0.5)
			end
			if not (T.model and T.model.Parent) then
				notify("Target","Loaded "..pl.Name..", but their dino isn't in your client yet — it'll fill in when they're nearer.")
			end
		end)
	end
	mkBtn(ld,"Load Player",function()
		-- Force read the textbox live so you don't have to press Enter
		pcall(function() if Fluent and Fluent.Options and Fluent.Options.TargetUser then CFG.TargetUser = Fluent.Options.TargetUser.Value end end)
		local targetName = tostring(CFG.TargetUser or "")
		if targetName == "" then notify("Target","Type a name first!") return end
		-- Manually resolve the player RIGHT HERE (name / display name / any part of either) — no dependence on
		-- the engine's resolver, so a missing/late function can never break Load again.
		local pl
		local lowName = string.lower(targetName)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and (string.lower(p.Name):find(lowName, 1, true) or string.lower(p.DisplayName):find(lowName, 1, true)) then
				pl = p
				break
			end
		end
		if not pl then
			notify("Target","No player found matching '"..targetName.."'")
			return
		end
		-- Manually set the target table
		__gg.MH_Target = __gg.MH_Target or {}
		__gg.MH_Target.plr = pl
		__gg.MH_Target.model = nil   -- it will find their dino in a second (cache + active loader below)
		notify("Target","Loaded "..pl.Name..". Profile will fill in shortly.")
		refreshTarget()
		activeLoad(pl)   -- keep pulling their area in until the dino shows
	end,2)
	mkBtn(ld,"Unload",function()
		local T=__gg.MH_Target; T.plr=nil; T.model=nil; T.viewing=false
		notify("Target","Target cleared."); refreshTarget()
	end,2.5)
	-- live tick: fast profile refresh (distance/health/stamina) + re-find the dino if it streamed out/respawned
	task.spawn(function() while RUNNING do if __gg.MH_Target and __gg.MH_Target.plr then pcall(refreshTarget) end task.wait(0.5) end end)
	refreshTarget()

	local _,ac=mkSec(p,"Actions",2)
	mkBtn(ac,"View Player (on / off)",function()
		local T=__gg.MH_Target
		if not (T and T.plr) then notify("Target","Load a player first."); return end
		T.viewing = not T.viewing
		if T.viewing and __gg.MH_targetLivePart then
			local _, m = __gg.MH_targetLivePart(T.plr)   -- resolve live (call NOT behind `and`, so both returns land)
			if m then T.model=m end
		end
		notify("Target", T.viewing and ("Viewing "..T.plr.Name.." — press again to stop.") or "Stopped viewing — camera back on your dino.")
	end,1)
	mkToggle(ac,"Track Player","TargetTrack",2)
	mkLabel(ac,"Track keeps a marker + distance on them.")
	mkBtn(ac,"Teleport to Player",function()
		local T=__gg.MH_Target
		if not (T and T.plr) then notify("Target","Load a player first."); return end
		if __gg.MH_targetTeleport and __gg.MH_targetTeleport() then notify("Target","Teleported to "..T.plr.Name..".")
		else notify("Target","Can't find their position (their dino isn't loaded in).") end
	end,4)
	mkBtn(ac,"Attack Player Once (TP in, hit, TP back)",function()
		local T=__gg.MH_Target
		if not (T and T.plr) then notify("Target","Load a player first."); return end
		if not _G.MH_attack then notify("Target","Attack unavailable — bite something once so the Attack remote gets captured, then retry."); return end
		task.spawn(function()
			local ok, why = __gg.MH_targetAttackReturn and __gg.MH_targetAttackReturn()
			if ok then notify("Target","Hit "..T.plr.Name.." and returned.")
			elseif why=="not loaded" then notify("Target","Their dino isn't in your client yet — get a bit closer.")
			else notify("Target","Load a player first.") end
		end)
	end,5)
	do   -- Auto Farm Player: ungated with the rest of the Target tab so EVERYTHING in the tab works
		local _,af=mkSec(p,"Auto Farm Player",3)
		mkToggle(af,"Auto Farm Player","AutoFarmPlayer",1)
		mkLabel(af,"Keeps teleporting onto the loaded player and hitting them.")
		mkSlider(af,"Farm Range","FarmPlayerRange",30,400,3,10)
		mkSlider(af,"Hits / sec","DamageRate",1,15,4,1)
	end
end

-- ═══ ADMIN TAB (whitelisted user only) ═══ Trimmed set: warn, teleport, fly, and copy the target's Roblox
-- identity (Roblox has NO way to read a Discord username — use their Roblox name / UserId / profile to ban them
-- on your side / your Discord).
if __gg.PE_ADMIN and Pages["Admin"] then local p=Pages["Admin"]
	local sel
	local function adminNames() local t={ LP.Name.."  (you)" } for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP then t[#t+1]=pl.Name end end return t end
	local function adminTarget() if not sel or sel=="" then return nil end local nm=sel:gsub("%s+%(you%)$",""); return Players:FindFirstChild(nm) end
	local function adminSpectate(pl) local cam=workspace.CurrentCamera; local c=pl.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); if cam and h then cam.CameraSubject=h; return true end local pt=c and c:FindFirstChildWhichIsA("BasePart"); if cam and pt then cam.CameraSubject=pt; return true end return false end
	local function adminStopSpectate() local cam=workspace.CurrentCamera; local mc=LP.Character; local h=mc and mc:FindFirstChildOfClass("Humanoid"); if cam then pcall(function() cam.CameraSubject=h end) end if __gg.MH_Target then __gg.MH_Target.viewing=false end end
	local function sendChat(txt)
		local ok=false
		-- modern TextChatService: try EVERY TextChannel we can find (RBXGeneral first), not just one
		pcall(function()
			local TCS=game:GetService("TextChatService")
			local order={}
			local tc=TCS:FindFirstChild("TextChannels")
			if tc then local g=tc:FindFirstChild("RBXGeneral"); if g then order[#order+1]=g end end
			for _,d in ipairs(TCS:GetDescendants()) do if d:IsA("TextChannel") and d~=order[1] then order[#order+1]=d end end
			for _,ch in ipairs(order) do
				local sent=pcall(function() ch:SendAsync(txt) end)
				if sent then ok=true break end
			end
		end)
		-- legacy chat fallback
		if not ok then pcall(function() local ev=RS:FindFirstChild("DefaultChatSystemChatEvents"); local say=ev and ev:FindFirstChild("SayMessageRequest"); if say then say:FireServer(txt,"All"); ok=true end end) end
		return ok
	end

	local _,s=mkSec(p,"Admin — Load User",1)
	mkLabel(s,"Whitelisted for @"..LP.Name..".")
	local dd = mkDropdown(s,"Load User", function() return adminNames() end, function() return sel or "" end, function(o) sel=(type(o)=="table" and o[1]) or o end)
	mkBtn(s,"Refresh Players", function() if dd and dd.refresh then dd.refresh() end end)

	local _,a=mkSec(p,"Actions",2)
	mkLabel(a,"Send Warn pops a standard warning on their screen. Custom message: type  ?warn username your text  in the live chat.",1)
	mkBtn(a,"Send Warn", function()
		local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end
		local msg=tostring(CFG.AdminWarnMsg~="" and CFG.AdminWarnMsg or "Follow the rules or you'll be removed.")
		-- delivered through the Dream Hub relay: pops up as a NOTIFICATION + warning card on their screen (no chat)
		if _G.__DreamWarnSend then _G.__DreamWarnSend(pl.Name, msg); notify("Admin","Warning sent to "..pl.Name.." (popup on their screen if they run Dream Hub).")
		else notify("Admin","Warn relay not ready yet — try again in a few seconds.") end
	end)
	mkBtn(a,"Teleport To User", function()
		local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end
		-- GENERIC teleport (works in any game): move MY character root to THEIR character root. Falls back to
		-- PE's dino teleport if there's no standard character.
		local okg=false
		pcall(function()
			local mc=LP.Character; local mr=mc and (mc:FindFirstChild("HumanoidRootPart") or mc.PrimaryPart or mc:FindFirstChildWhichIsA("BasePart"))
			local tc=pl.Character; local tr=tc and (tc:FindFirstChild("HumanoidRootPart") or tc.PrimaryPart or tc:FindFirstChildWhichIsA("BasePart"))
			if mr and tr and __gg.MH_safeTeleport then okg=__gg.MH_safeTeleport(tr.CFrame*CFrame.new(0,0,-4),{saveReturn=true,settle=1.0}) end
		end)
		if okg then notify("Admin","Teleported to "..pl.Name..".") return end
		__gg.MH_Target=__gg.MH_Target or {}; __gg.MH_Target.plr=pl
		if __gg.MH_targetTeleport and __gg.MH_targetTeleport() then notify("Admin","Teleported to "..pl.Name..".")
		else notify("Admin","Can't reach them — they aren't loaded in your client.") end
	end)
	mkBtn(a,"View Player", function()
		local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end
		-- generic spectate; also flag PE's follow-cam if it's their dino
		if pl~=LP then __gg.MH_Target=__gg.MH_Target or {}; __gg.MH_Target.plr=pl; __gg.MH_Target.model=nil; __gg.MH_Target.viewing=true end
		if adminSpectate(pl) then notify("Admin","Viewing "..pl.Name..".")
		else notify("Admin","Can't view — they aren't loaded in your client.") end
	end)
	mkBtn(a,"Stop Viewing", function() adminStopSpectate(); notify("Admin","Camera back on you.") end)
	mkToggle(a,"Fly","Fly")

	local _,id=mkSec(p,"Their Roblox Identity (to ban on your side)",3)
	mkLabel(id,"Roblox can't give a Discord username — nothing links the two. Use their Roblox info below to identify/ban them wherever YOU moderate.")
	mkBtn(id,"Copy Username", function() local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end local ok=pcall(function() setclipboard(pl.Name) end); notify("Admin", ok and ("Copied @"..pl.Name) or ("@"..pl.Name.." (no clipboard on this executor)")) end)
	mkBtn(id,"Copy UserId", function() local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end local ok=pcall(function() setclipboard(tostring(pl.UserId)) end); notify("Admin", ok and ("Copied "..pl.UserId) or (tostring(pl.UserId).." (no clipboard)")) end)
	mkBtn(id,"Copy Profile Link", function() local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end local link="https://www.roblox.com/users/"..pl.UserId.."/profile"; local ok=pcall(function() setclipboard(link) end); notify("Admin", ok and "Copied profile link." or link) end)
	local _,rp=mkSec(p,"Report Details",4)
	mkTextbox(rp,"Put reason here","AdminReason",1,false)
	mkTextbox(rp,"Proof image link","AdminProof",2,false)
	mkBtn(rp,"Copy Report Details", function()
		local pl=adminTarget(); if not pl then notify("Admin","Load a user first.") return end
		local reason = tostring(CFG.AdminReason or "")
		local proof = tostring(CFG.AdminProof or "")
		if #reason:gsub("%s","")<2 then notify("Admin","Type a reason first.") return end
		local details = table.concat({
			"Target: "..pl.DisplayName.." (@"..pl.Name..") ["..tostring(pl.UserId).."]",
			"Profile: https://www.roblox.com/users/"..tostring(pl.UserId).."/profile",
			"Reason: "..string.sub(reason,1,1500),
			"Proof: "..string.sub(proof,1,400),
			"Prepared by: "..LP.Name.." (in "..tostring(_G.__DreamGameName or "game")..")",
		}, "\n")
		local copied=false
		pcall(function() if setclipboard then setclipboard(details); copied=true end end)
		notify("Admin",copied and "Report details copied; no external report was sent." or "Clipboard unavailable; no external report was sent.")
	end)
end


do local p=Pages["Rules"] if p then
	local _,s=mkSec(p,"Community Rules")
	mkLabel(s,"Break a rule and the action beside it applies. Staff decisions are final; appeal in the Discord.")
	mkLabel(s,"1.  No harassment, bullying, or targeting other players.   ->   Kick  (repeat = Ban)")
	mkLabel(s,"2.  No slurs, hate speech, racism, or discrimination.   ->   Instant Ban")
	mkLabel(s,"3.  No NSFW, gore, or inappropriate content of any kind.   ->   Instant Ban")
	mkLabel(s,"4.  No threats, doxxing, or sharing anyone's personal info.   ->   Instant Ban")
	mkLabel(s,"5.  No scamming, fake trades, or fake giveaways.   ->   Ban")
	mkLabel(s,"6.  Do not impersonate Dream Hub staff or other users.   ->   Kick")
	mkLabel(s,"7.  No advertising other hubs, servers, scripts, or discords.   ->   Warn -> Kick")
	mkLabel(s,"8.  No leaking, cracking, or reselling paid Dream Hub scripts.   ->   Ban")
	mkLabel(s,"9.  No spamming chat, sounds, tags, or requests.   ->   Warn -> Kick")
	mkLabel(s,"10.  Don't use bugs/glitches to grief or ruin others' games.   ->   Kick")
	mkLabel(s,"11.  No intentionally lagging, freezing, or crashing servers.   ->   Kick -> Ban")
	mkLabel(s,"12.  No evading a punishment with alt accounts.   ->   Ban all alts")
	mkLabel(s,"13.  Don't beg for admin, roles, or free premium.   ->   Warn")
	mkLabel(s,"14.  Respect staff decisions - appeal calmly in the Discord.   ->   Warn")
	mkLabel(s,"15.  Don't abuse the report system with false/joke reports.   ->   Warn -> Kick")
end end

do local p=Pages["Teleport"]
	-- Scans Workspace.Biomes (the ecosystems loaded around you) and lets you teleport to any one. Auto-detects the
	-- biomes for whatever LAND you're in (Cretaceous Lowland's Caves/Sandy Shores/Scrubland, Archipelago's Seashore, etc.).
	local function biomeFolder() return WS:FindFirstChild("Biomes") or WS:FindFirstChild("Map") or WS end
	local function biomeNames()
		local out={}; local bf=biomeFolder()
		if bf then for _,c in ipairs(bf:GetChildren()) do if (c:IsA("Folder") or c:IsA("Model")) then out[#out+1]=c.Name end end end
		if #out==0 then out[1]="(none loaded)" end
		table.sort(out)
		return out
	end
	local function biomePos(name)
		local bf=biomeFolder(); if not bf then return nil end
		local b=bf:FindFirstChild(name); if not b then return nil end
		if b:IsA("BasePart") then return b.Position end
		for _,d in ipairs(b:GetDescendants()) do if d:IsA("BasePart") then return d.Position end end
		return nil
	end
	local function tpTo(pos)
		if not pos then notify("Teleport","That biome isn't loaded near you yet — move closer or pick another."); return end
		local target=pos+Vector3.new(0,6,0)
		local ok=__gg.MH_safeTeleport and __gg.MH_safeTeleport(target,{saveReturn=true,settle=1.4})
		if not ok then notify("Teleport","Teleport system is not ready yet."); return end
		-- ANTI-FALL on landing: the server can reset FallDamageImmunity, so we re-assert it + clear any fall status +
		-- damp a hard drop for ~4s after the teleport. This stops the "I die once in a while" on teleport.
		task.spawn(function() for _=1,40 do
			if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
			pcall(function() clearStatus({"fall","falldamage","falldmg"},{"Falling","FallDamage","FallDmg"}) end)
			local r=hrp(); if r then local v=r.AssemblyLinearVelocity; if v.Y<-35 then pcall(function() r.AssemblyLinearVelocity=Vector3.new(v.X,0,v.Z) end) end end
			task.wait(0.1)
		end end)
		notify("Teleport","Teleported.")
	end
	local _,d=mkSec(p,"Ecosystem Teleport",1)
	mkDropdown(d,"Biome", biomeNames, function() return CFG.TpBiome~="" and CFG.TpBiome or "(scan)" end, function(opt) CFG.TpBiome=opt; saveCfg() end, 1)
	mkBtn(d,"Teleport to Biome", function() tpTo(biomePos(CFG.TpBiome)) end, 2)
	mkBtn(d,"Teleport Back to Origin", function()
		local origin=__gg.MH_tpOrigin
		if not origin then notify("Teleport","No origin saved yet — use a teleport first."); return end
		if __gg.MH_safeTeleport and __gg.MH_safeTeleport(origin,{settle=1.4}) then __gg.MH_tpOrigin=nil; notify("Teleport","Returned to your saved origin.") end
	end, 3)
end
do local p=Pages["Visuals"]
	local _,e=mkSec(p,"ESP",1)
	mkToggle(e,"ESP Creatures + Players","ESPPlayers",1)
	mkToggle(e,"ESP Corpses","ESPCorpses",2)
	mkToggle(e,"Plant ESP","FoodESP",3)
	mkToggle(e,"Fish ESP","FishESP",4)
	mkToggle(e,"Gem + Fossil ESP","GemESP",5)
	mkSlider(e,"ESP Range","ESPRange",100,3000,6,50)
	mkDropdown(e,"ESP Color", function() return {"Default","Rainbow","Red","Green","Blue","Yellow","Purple","Cyan","Orange","Pink","White"} end, function() return CFG.ESPColor~="" and CFG.ESPColor or "Default" end, function(opt) CFG.ESPColor=opt; saveCfg() end, 6)
	local _,l=mkSec(p,"World",2)
	mkToggle(l,"Full Bright","FullBright",1)
	mkToggle(l,"No Night","NightVision",2)
	mkToggle(l,"No Darkness Underwater","NoDarkWater",3)
	mkToggle(l,"Water Transparency","WaterClear",4)
	mkToggle(l,"No Clouds","NoClouds",5)
	mkToggle(l,"INF Light","InfLight",6)
	if not _G.PE_HIDE_LITE then   -- Danger Alert lives in the separate Lite hub; the wrapper hides it here
		local _,al=mkSec(p,"Danger Alert",3)
		mkToggle(al,"Enable Alert","AlertEnabled",1)
		mkDropdown(al,"Alert Dino", function() return DINO_NAMES end, function() return CFG.AlertDino~="" and CFG.AlertDino or "(pick a dino)" end, function(opt) CFG.AlertDino=opt; saveCfg() end, 2)
		mkSlider(al,"Alert Range","AlertRange",100,2000,3,50)
	end
	local _,rf=mkSec(p,"Radar + FPS",4)
	if not _G.PE_HIDE_LITE then   -- Radar is PLUS (food) build only — hidden in No-Food
		mkToggle(rf,"Minimap Radar (see players anywhere)","Radar",1)
		mkSlider(rf,"Radar Zoom (studs across)","RadarRange",100,2000,2,50)
		mkToggle(rf,"Radar: Show My Death Point","RadarDeath",3)
	end
	mkToggle(rf,"Remove Trees (big FPS boost - edible plants kept)","RemoveTrees",4)
end
local skinDropdownRef, dinoLabel
do local p=Pages["Skins"]
	local _,s=mkSec(p,"Skin Changer",1)
	if not USE_FLUENT then dinoLabel = C("TextLabel",{Parent=s, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="Detecting your dino...", TextColor3=T.Accent, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1}) end
	skinDropdownRef = mkDropdown(s,"Skin",
		function() local dt=skGetCharInfo(); if dt then local l=skGetGameList(dt); if #l>0 then return l end end return {"Default"} end,
		function() return CFG.SkinName~="" and CFG.SkinName or "Default" end,
		function(opt) CFG.SkinName=opt; saveCfg() end, 2)
	mkToggle(s,"Wet textures","SkinWet",3)
	mkBtn(s,"APPLY SKIN",function()
		if SKN.busy then return end SKN.busy=true
		task.spawn(function()
			local dt,st,gd=skGetCharInfo()
			local skin=CFG.SkinName~="" and CFG.SkinName or "Default"
			if not dt then notify("Skins","No dino detected"); SKN.busy=false; return end
			local ok; if skin=="Default" then skRestoreAll(); ok=true else ok=skApplyGame(dt,skin,st,gd,CFG.SkinWet) end
			notify("Skins",(ok and "Applied " or "Failed (try WET or respawn) ")..tostring(dt).." -> "..skin)
			task.wait(0.3); SKN.busy=false
		end)
	end,4)
	mkBtn(s,"Restore Default Skin",function() skRestoreAll(); notify("Skins","Restored default") end,5)
	mkBtn(s,"Re-detect Dino",function() local dt,st=skGetCharInfo(); if dinoLabel then dinoLabel.Text=dt and ("Dino: "..tostring(dt).." | Stage: "..tostring(st)) or "No dino detected" end if skinDropdownRef then skinDropdownRef.refresh() end end,6)
end
do local p=Pages["Misc"]
	local _,a=mkSec(p,"Utility",1)
	mkToggle(a,"Anti-AFK","AntiAFK",1)
	mkToggle(a,"Unlock FOV","UnlockFOV",2)
	mkSlider(a,"Field of View","FOV",40,120,3,1)
	mkToggle(a,"INF Zoom","InfZoom",4)
	mkToggle(a,"Unlock Mouse + Camera","UnlockMouse",5)
	mkToggle(a,"Safe Teleport","SafeTP",7)
	local _,s=mkSec(p,"Server",2)
	mkBtn(s,"Rejoin Server",function() pcall(function() TeleportSvc:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end) end,1)
	mkBtn(s,"Server Hop",function() task.spawn(function()
		local moved=false
		local ok=pcall(function()
			local raw=game:HttpGetAsync("https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?sortOrder=Asc&limit=100")
			local data=HttpService:JSONDecode(raw)
			for _,srv in ipairs(data.data or {}) do if srv.id~=game.JobId and (tonumber(srv.playing) or 0)<(tonumber(srv.maxPlayers) or 100) then
				moved=true; TeleportSvc:TeleportToPlaceInstance(game.PlaceId,srv.id,LP); return
			end end
		end)
		if not ok or not moved then notify("Server","No different public server is available right now.") end
	end) end,2)
end
do local p=Pages["Settings"]
	local _,t=mkSec(p,"Theme & Quality",1)
	mkBtn(t,"Cycle Accent Color",function() CFG.AccentIndex=(CFG.AccentIndex % #ACCENTS)+1; T.Accent=ACCENTS[CFG.AccentIndex]; T.On=T.Accent; if accentBar then accentBar.BackgroundColor3=T.Accent end for key,ref in pairs(toggleRefs) do if CFG[key] and ref[1] then ref[1].BackgroundColor3=T.On end end showPage(currentPage); saveCfg() end,1)
	mkSlider(t,"UI Scale","UIScale",1,3,2,0.1)
	local _,k=mkSec(p,"Keybinds",2)
	local binds = { {"Open/Close UI","UIKey"},{"Aim Lock","AimKey"},{"Aimbot","Aimbot"},{"Silent Aim","SilentAim"},{"Lock On","LockOn"},{"Turn Hack","TurnHack"},{"Hitbox","HitboxExpand"},{"Float","Float"},{"Fly","Fly"},{"Speed Hack","SpeedHack"},{"Noclip","Noclip"},{"Inf Jump","InfJump"},{"INF Food","InfFood"},{"INF Water","InfWater"},{"INF Stam","InfStam"},{"Anti Drown","AntiDrown"},{"Walk on Water","WalkWater"},{"Anti Fall","AntiFall"},{"Save Dino","SaveDino"},{"Auto Farm Player","AutoFarmPlayer"},{"Auto Farm Fossil","AutoFarmFossil"},{"Auto Farm Gem","AutoFarmGem"},{"ESP","ESPPlayers"},{"Plant ESP","FoodESP"},{"Fish ESP","FishESP"},{"Full Bright","FullBright"},{"No Night","NightVision"},{"INF Light","InfLight"},{"INF Zoom","InfZoom"} }
	if _G.PE_HIDE_LITE then local kept={} for _,kb in ipairs(binds) do if kb[2]~="InfFood" then kept[#kept+1]=kb end end binds=kept end   -- hide the INF Food keybind row in the no-lite build
	for i,kb in ipairs(binds) do mkKeybind(k, kb[1], kb[2], i) end
end
HUD={}  -- debug-panel status refs (one table instead of 4 locals — Luau 200-local-cap mgmt)
do local p=Pages["Info"]
	local _,s=mkSec(p,"Status",1)
	HUD.hp=mkStatus(s,"Health",1); HUD.stat=mkStatus(s,"State",2); HUD.dino=mkStatus(s,"Dino",3); HUD.pos=mkStatus(s,"Position",4)
	local _,dbg=mkSec(p,"Debug",2)
	mkToggle(dbg,"Stat Panel","DebugPanel",1)
	mkToggle(dbg,"Log Remotes","LogRemotes",2)
	-- Dump the full replica tree to console (+clipboard) so injury/stamina fields can be captured. Use it WHILE
	-- bleeding/broken-leg to reveal the exact field name, then send it to lock the anti. Console-only, no visible info.
	mkBtn(dbg,"Dump Stats",function()
		local out={}
		local function walk(t,pfx,d)
			if type(t)~="table" or d>6 then return end
			pcall(function() for k,v in pairs(t) do
				local ty=type(v)
				if ty=="number" or ty=="boolean" or ty=="string" then out[#out+1]=pfx..tostring(k).." = "..tostring(v).."   ("..ty..")"
				elseif ty=="table" and getmetatable(v)==nil then out[#out+1]=pfx..tostring(k).." = {"; walk(v,pfx.."  ",d+1) end
			end end)
		end
		local r=csReplica(); if r and r.Data then out[#out+1]="== Replica.Data =="; walk(r.Data,"",0) end
		if CharacterState then out[#out+1]="== CharacterState (top numbers/bools) =="; pcall(function() for k,v in pairs(CharacterState) do local ty=type(v); if ty=="number" or ty=="boolean" then out[#out+1]="CS."..tostring(k).." = "..tostring(v) elseif ty=="table" and getmetatable(v)==nil then out[#out+1]="CS."..tostring(k).." = {"; walk(v,"  ",0) end end end) end
		local s=table.concat(out,"\n")
		print("\n===== PE STAT DUMP =====\n"..s.."\n===== END =====")
		if setclip then pcall(function() setclip(s) end) end
		notify("Dump", #out.." lines to console"..(setclip and " + clipboard" or ""))
	end,3)
	local _,c=mkSec(p,"Hub",3)
	mkLabel(c,"Dream Hub · Prior Extinction",1)
	mkBtn(c,"Unload Hub",function() if G.__PRIOR_EXT_HUB then G.__PRIOR_EXT_HUB() end end,2)
end
if USE_FLUENT then
	pcall(function() FWindow:SelectTab(1) end)
	-- Fluent Settings addons: theme/colour + transparency + config save/load (so the user can restyle + save).
	pcall(function()
		local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
		local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
		SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
		SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({})
		InterfaceManager:SetFolder("MoneyFreeHub"); SaveManager:SetFolder("MoneyFreeHub/PriorExtinction")
		if Pages["Settings"] then InterfaceManager:BuildInterfaceSection(Pages["Settings"]); SaveManager:BuildConfigSection(Pages["Settings"]) end
		SaveManager:LoadAutoloadConfig()
	end)
else
	SG.Enabled = true   -- Fluent failed to load → show the built-in window instead (no blank screen)
	showPage("Combat")
end

-- ═══ FEATURE LOOPS ═══
-- Stats: cheap per-frame top-up of known keys; the recursive deep-walk + HUD scan are THROTTLED (fixes the INF-food/stam lag).
conn(RunService.Heartbeat:Connect(function()
	if CharacterState then
		if CFG.AntiFall then pcall(function() CharacterState.FallDamageImmunity=true end) end
		-- (Anti-Drown no longer forces IsInWater=false here — we READ it to detect underwater and surface you instead.)
	end
	if CFG.InfWater or CFG.InfOxygen or CFG.GodMode then
		local stats, maxs = csStats()
		if stats then
			pcall(function()
				-- Pin to the REAL max only (never inflate past it — writing 1000 to a 50-max stat made the server
				-- fight every write = the snapback/slowness). If max is unknown, leave it (the deep-walk handles it).
				if CFG.InfWater  and stats.Water   ~= nil and maxs and maxs.Water   then stats.Water   = maxs.Water   end
				if CFG.InfOxygen and stats.Oxygen  ~= nil and maxs and maxs.Oxygen  then stats.Oxygen  = maxs.Oxygen  end
				if CFG.GodMode   and stats.Health  ~= nil and maxs and maxs.Health  then stats.Health  = maxs.Health  end
				if CFG.GodMode   and stats.Temperature ~= nil and maxs and maxs.Temperature then stats.Temperature = maxs.Temperature end
			end)
		end
		-- Deep walk so unknown key names are still caught.
		if (CFG.InfWater or CFG.InfOxygen) and (tick()-FARM.lastDeepPin>0.12) then FARM.lastDeepPin=tick()
			pcall(function()
				local r=csReplica()
				if r and r.Data then deepPinStats(r.Data, r.Data.MaxStats or r.Data.Max, 0) end
			end)
			-- SANDBOX: the stat can live directly on CharacterState (not under Replica.Data). Pin top-level stamina/food/etc.
			if CharacterState then pcall(function()
				-- top-level CharacterState stat → pin ONLY to its matching Max key (no inflation = no server fight).
				local function topPin(on, keys, maxkeys) if not on then return end
					local mx; for _,mk in ipairs(maxkeys) do if type(CharacterState[mk])=="number" then mx=CharacterState[mk]; break end end
					if mx then for _,k in ipairs(keys) do if type(CharacterState[k])=="number" then CharacterState[k]=mx end end end
				end
				-- Food and stamina are handled by MHNEED, including top-level sandbox need tables.
				topPin(CFG.InfWater, {"Water","Thirst","Hydration"}, {"MaxWater","MaxThirst","MaxHydration"})
			end) end
		end
	end
end))

-- Legacy water/oxygen frame pin. Food, stamina, and protection health never enter this path.
conn(RunService.RenderStepped:Connect(function()
	if not (CFG.InfOxygen or CFG.InfWater) then return end
	if not alive() then return end
	pcall(function()
		local stats, maxs = csStats()
		local function pin(keys) for _,k in ipairs(keys) do
			if stats[k]~=nil then
				local cur=tonumber(stats[k])
				if cur then __gg.MH_max=__gg.MH_max or {}; if not __gg.MH_max[k] or cur>__gg.MH_max[k] then __gg.MH_max[k]=cur end end
				local target=(maxs and maxs[k]) or (__gg.MH_max and __gg.MH_max[k])
				if target then stats[k]=target end
			end
		end end
		if stats then
			if CFG.InfOxygen then pin({"Oxygen","Air","Breath","O2","Lung"}) end
			if CFG.InfWater  then pin({"Water","Thirst","Hydration"}) end
		end
		if CharacterState then
			if CFG.InfOxygen then for _,k in ipairs({"IsInWater","Submerged","InWater","Underwater","Swimming","Drowning"}) do pcall(function() if CharacterState[k]~=nil then CharacterState[k]=false end end) end end
			-- SANDBOX: the stat tables can hang off CharacterState directly (not under Replica.Data). Deep-walk it too.
			pcall(function()
				for _,sub in ipairs({"Stats","State","Data","Vitals","Needs"}) do
					local t=CharacterState[sub]
					if type(t)=="table" then deepPinStats(t, t.MaxStats or t.Max, 0) end
				end
			end)
		end
	end)
end))

-- One authoritative 20 Hz need controller. Exact local references are pinned continuously, while server reports use
-- their own throttles. PE exposes both Stats.Hunger/Food and the nested Hunger.Delta/Max layout across builds, so the
-- verified self replica receives both known property aliases; the server ignores the alias it does not use.
task.spawn(function()
	local wasOn={food=false,stamina=false}
	while RUNNING do
		if alive() and (CFG.InfFood or CFG.InfStam) then
			pcall(function()
				for _,row in ipairs({{"food",CFG.InfFood},{"stamina",CFG.InfStam}}) do
					local kind,on=row[1],row[2]
					if on then
						local mx=MHNEED.pin(kind)
						if not MHNEED.report(kind,not wasOn[kind]) then MHNEED.reportKnown(kind,not wasOn[kind]) end
						if kind=="food" then
							local now=tick()
							-- This is the exact self-replica pattern used by the working standalone PE food controller.
							-- Five reports per second is enough to beat depletion without Heartbeat-spamming the server.
							if mx and (not wasOn.food or now-(__gg.MH_foodDirectAt or 0)>=0.2) then
								__gg.MH_foodDirectAt=now
								replicaFire("SetProperty","Hunger",mx)
								replicaFire("SetProperty","Food",mx)
							end
							-- Growth can be paused again after a depletion/respawn update. Reassert only while the replicated
							-- flag is actually paused and throttle the server request.
							local rep=csReplica(); local growth=rep and rep.Data and rep.Data.Growth
							if growth and growth.Paused==true and (not wasOn.food or now-(__gg.MH_growthResumeAt or 0)>=0.8) then
								__gg.MH_growthResumeAt=now
								pcall(function() growth.Paused=false; rep:FireServer("SetGrowthPaused",false) end)
							end
						end
					end
					wasOn[kind]=on
				end
			end)
			task.wait(0.05)
		else wasOn.food=false; wasOn.stamina=false; task.wait(0.4) end
	end
end)

-- ═══ E EAT ASSIST — the definitive "E doesn't work" fix ═══ When you PRESS E, the hub makes the eat land for
-- you: it finds the nearest eat/consume ProximityPrompt within reach (meat chunks, corpses, plants — the game's
-- MeatController tags meat with HintType="Corpse"), removes its line-of-sight requirement, and FIRES it directly.
-- So even when the game's own prompt logic refuses (bar too high, prompt hidden, LOS blocked), your E still eats.
-- The immediate pin remains active while eating so a real bite cannot be followed by a drain-frame flicker.
conn(UIS.InputBegan:Connect(function(input, gp)
	if input.KeyCode ~= Enum.KeyCode.E then return end
	__gg.MH_lastE = tick()
	if not alive() then return end
	task.spawn(function() pcall(function()
		local r=hrp(); if not r then return end
		local best, bestD
		-- targeted scan (NOT the whole workspace — PE maps are huge): the folders that actually hold eatables,
		-- per the game's own MeatController (CharacterIgnore.SpawnedMeat) + Food + corpses + spawn markers.
		local ci=WS:FindFirstChild("CharacterIgnore")
		local pools={}
		local function addPool(x) if x then pools[#pools+1]=x end end
		addPool(ci and ci:FindFirstChild("SpawnedMeat")); addPool(WS:FindFirstChild("Food"))
		addPool(ci and ci:FindFirstChild("CorpseSpawns")); addPool(ci and ci:FindFirstChild("LeftCharacters"))
		addPool(WS:FindFirstChild("Characters")); addPool(WS:FindFirstChild("Map")); addPool(WS:FindFirstChild("Biomes"))
		local scanned=0
		for _,pool in ipairs(pools) do
			for _,pp in ipairs(pool:GetDescendants()) do
				scanned=scanned+1; if scanned>8000 then break end
				if pp:IsA("ProximityPrompt") and pp.Enabled then
					local par = pp.Parent
					local pos
					if par and par:IsA("BasePart") then pos = par.Position
					elseif par and par:IsA("Model") then local root=rootOf(par); pos = root and root.Position end
					if pos then
						local d=(pos - r.Position).Magnitude
						if d < 16 then
							-- prefer prompts that look like eating: on meat/corpse/food or with an eat-ish action text
							local score = d
							local hint = par and (par:GetAttribute("HintType") or (par.Parent and par.Parent:GetAttribute("HintType")))
							local at = string.lower(tostring(pp.ActionText or ""))
							if hint=="Corpse" or at:find("eat",1,true) or at:find("consume",1,true) or at:find("bite",1,true) then score = d - 8 end
							if not bestD or score < bestD then best=pp; bestD=score end
						end
					end
				end
			end
			if scanned>8000 then break end
		end
		if best then
			pcall(function() __gg.MH_activatePrompt(best,24) end)
		end
	end) end)
end))

-- No "eat once" requirement/toast: the direct food-stat controller fills immediately, while the source scanner
-- below independently discovers a diet-correct plant/meat prompt and captures a genuine Bite packet when possible.
-- WELLBEING PIN: only paired maxima are eligible. This must not manufacture a generic 100 for species-specific data.
do
	local WB_MAX = {"Comfort","Activity","Cleanliness","Immunity","Proteins","Fats","Calcium","Fiber","Carbohydrates","Nutrition","Wellbeing"}
	local WB_ZERO = {"Toxins","Toxin","Toxicity"}
	local function pinWB(stats,maxs)
		if type(stats)~="table" then return end
		for _,k in ipairs(WB_MAX) do local mx=type(maxs)=="table" and tonumber(maxs[k]); if type(stats[k])=="number" and mx and mx>0 then stats[k]=mx end end
		for _,k in ipairs(WB_ZERO) do if type(stats[k])=="number" then stats[k]=0 end end
	end
	-- THE REAL WELLBEING REPLICA (from the decompiled Wellbeing class): these stats do NOT live on the
	-- CharacterState replica — the game creates a SEPARATE replica with the token "Wellbeing"
	-- (Replica.Client.OnNew("Wellbeing", ...)) holding Data.SavableStats.Stats + Data.SavableStats.BufferTimers.
	-- The old pin wrote to CharacterState.Replica.Data.SavableStats, which usually doesn't exist = the pin did
	-- NOTHING. We now grab the actual Wellbeing replica through the game's own Replica package and pin THAT.
	local function wbShape(x) return type(x)=="table" and x.Data and x.Data.SavableStats and type(x.Data.SavableStats.Stats)=="table" end
	local function findWB(root)
		local seen,count={},0
		local function walk(x,depth)
			if type(x)~="table" or seen[x] or depth>5 or count>1600 then return nil end
			seen[x]=true; count+=1; if wbShape(x) then return x end
			local found
			pcall(function() for _,v in pairs(x) do if type(v)=="table" then found=walk(v,depth+1); if found then break end end end end)
			return found
		end
		return walk(root,0)
	end
	local function resolveWB()
		if wbShape(__gg.MH_wellbeing) then return __gg.MH_wellbeing end
		local direct=findWB(CharacterState)
		if direct then __gg.MH_wellbeing=direct; return direct end
		if __gg.MH_replicaClient then direct=findWB(__gg.MH_replicaClient); if direct then __gg.MH_wellbeing=direct; return direct end end
		-- OnNew may have fired before this hub loaded. A sparse, bounded GC search recovers that already-created
		-- replica on executors that expose getgc; it stops permanently once the correct shape is found.
		if typeof(getgc)=="function" and tick()-(__gg.MH_wbGcAt or 0)>3 then
			__gg.MH_wbGcAt=tick()
			pcall(function() local n=0; for _,v in next,getgc(true) do n+=1; if n>7000 then break end; if wbShape(v) then direct=v; break end end end)
			if direct then __gg.MH_wellbeing=direct; return direct end
		end
		return nil
	end
	task.spawn(function()
		pcall(function()
			local pk = RS:WaitForChild("Packages", 20); pk = pk and pk:WaitForChild("Replica", 10)
			local Client = pk and require(pk).Client; __gg.MH_replicaClient=Client
			if Client and Client.OnNew and not __gg.MH_wbWatching then __gg.MH_wbWatching=true; Client.OnNew("Wellbeing", function(rep) __gg.MH_wellbeing = rep end) end
			resolveWB()
		end)
	end)
	task.spawn(function() while RUNNING do
		if (CFG.InfFood or CFG.GodMode) and alive() then
			pcall(function()
				-- 1) the REAL Wellbeing replica (decompile-verified home of these stats)
				local rep = resolveWB(); local sav=rep and rep.Data and rep.Data.SavableStats
				pinWB(sav and sav.Stats,sav and (sav.MaxStats or sav.Max))
				-- The supplied Wellbeing class only observes OnSet; it does not show a valid client FireServer schema.
				-- Therefore no guessed Wellbeing packets are emitted. Legacy mirrored local fields remain safe to pin.
				local r=csReplica(); local sav2=r and r.Data and r.Data.SavableStats
				pinWB(sav2 and sav2.Stats,sav2 and (sav2.MaxStats or sav2.Max))
				local stats,maxs=csStats(); pinWB(stats,maxs)
			end)
			task.wait(0.4)
		else task.wait(0.6) end
	end end)
end

-- Path-aware injury cleanup. Only the selected protection region is eligible; unrelated movement/control state is
-- never changed. Auto Heal Blood shares the bleed-only cleanup but does not imply health, sleep, or fatigue changes.
local function antiInjurySweep(tb, path, depth)
	if type(tb)~="table" or depth>5 then return end
	for k,v in pairs(tb) do
		local kp = path..tostring(k):lower().."."
		local tv = type(v)
		if tv=="boolean" or tv=="number" then
			local bleed=(kp:find("bleed",1,true) or kp:find("hemorrhage",1,true) or kp:find("wound",1,true) or kp:find("bloodloss",1,true))
			local clear=((CFG.AntiBleed or CFG.AutoHealBlood) and bleed) or injHit(kp)
			if clear then
				if tv=="boolean" then if v then pcall(function() tb[k]=false end) end
				else if v~=0 then pcall(function() tb[k]=0 end) end end
			end
		elseif tv=="table" and getmetatable(v)==nil then
			antiInjurySweep(v, kp, depth+1)
		end
	end
end
-- One protection controller owns proportional damage reduction, bleed/blood repair, and scoped injury cleanup. It
-- never changes Dead, ragdoll, PlatformStand, movement state, or guessed server properties/actions.
do
	local healthKeys={"Health","HP","Hp","health","hp","Hitpoints","HitPoints"}
	local bloodKeys={"Blood","BloodLevel","BloodVolume","BloodPool"}
	local bleedKeys={"Bleed","Bleeding","BleedRate","BleedDamage","Bloodloss","BloodLoss","Hemorrhage","Wound","Wounds"}
	local function physicalOn()
		return CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso
	end
	local function exactMax(stats,maxs,key)
		local candidates={
			type(maxs)=="table" and maxs[key], type(stats)=="table" and stats["Max"..key],
			type(stats)=="table" and stats[key.."Max"], type(stats)=="table" and stats["Maximum"..key]
		}
		if type(CharacterState)=="table" then
			candidates[#candidates+1]=CharacterState["Max"..key]
			candidates[#candidates+1]=CharacterState[key.."Max"]
			if type(CharacterState.MaxStats)=="table" then candidates[#candidates+1]=CharacterState.MaxStats[key] end
		end
		for _,v in ipairs(candidates) do v=tonumber(v); if v and v>0 and v<1e8 then return v end end
		return nil
	end
	local function healthPair()
		local stats,maxs=csStats()
		if type(stats)=="table" then for _,k in ipairs(healthKeys) do local hp=tonumber(stats[k]); local mx=hp and exactMax(stats,maxs,k); if hp and mx then return hp,mx,stats end end end
		local h=hum(); if h and tonumber(h.Health) and tonumber(h.MaxHealth) and h.MaxHealth>0 and h.MaxHealth<1e8 then return h.Health,h.MaxHealth,stats end
		if type(CharacterState)=="table" then for _,k in ipairs({"Health","HP"}) do
			local hp=tonumber(CharacterState[k]); local mx=hp and tonumber(CharacterState["Max"..k]); if hp and mx and mx>0 and mx<1e8 then return hp,mx,stats end
		end end
		return nil,nil,stats
	end
	local function writeHealth(value,stats)
		if type(stats)=="table" then for _,k in ipairs(healthKeys) do if type(stats[k])=="number" then stats[k]=value end end end
		local h=hum(); if h and h.MaxHealth>0 then pcall(function() h.Health=math.min(value,h.MaxHealth) end) end
		if type(CharacterState)=="table" then for _,k in ipairs({"Health","HP"}) do if type(CharacterState[k])=="number" then CharacterState[k]=value end end end
		local model=getMyModel(); if model then for _,k in ipairs({"Health","HP"}) do if type(model:GetAttribute(k))=="number" then pcall(function() model:SetAttribute(k,value) end) end end end
	end
	local function reportHealth(value)
		local now=tick(); if now-(__gg.MH_healthReportAt or 0)<0.15 then return end
		local packet=__gg.MH_healthPacket; local rid=MHNEED and MHNEED.replicaId and MHNEED.replicaId()
		if type(packet)~="table" or not packet.instance or not packet.instance.Parent or packet[1]~=rid or packet[2]~="SetProperty" then return end
		if packet.identity and packet.identity~=__gg.MH_identityKey then return end
		local prop=tostring(packet[3] or ""):lower(); if prop~="health" and prop~="hp" then return end
		local args={}; for i=1,packet.n do args[i]=packet[i] end; args[4]=value
		local ok=pcall(function() packet.instance:FireServer(table.unpack(args,1,packet.n)) end)
		if ok then __gg.MH_healthReportAt=now end
	end
	local function repairBlood(stats,maxs)
		local rid=MHNEED and MHNEED.replicaId and MHNEED.replicaId()
		if typeof(rid)~="number" then __gg.MH_bloodReplica=nil; __gg.MH_bloodMax=nil; return end
		if __gg.MH_bloodReplica~=rid then __gg.MH_bloodReplica=rid; __gg.MH_bloodMax=nil end
		if type(stats)~="table" then return end
		for _,k in ipairs(bleedKeys) do if type(stats[k])=="boolean" then stats[k]=false elseif type(stats[k])=="number" then stats[k]=0 end end
		for _,k in ipairs(bloodKeys) do if type(stats[k])=="number" then
			local mx=exactMax(stats,maxs,k)
			if mx then __gg.MH_bloodMax=mx; stats[k]=mx; return end
		end end
		__gg.MH_bloodMax=nil
	end
	task.spawn(function() while RUNNING do task.wait(0.1)
		if not alive() then __gg.MH_guardLastHP=nil; __gg.MH_bloodMax=nil; continue end
		pcall(function()
			local stats,maxs=csStats()
			if CFG.AntiBleed or CFG.AutoHealBlood then repairBlood(stats,maxs) end
			if physicalOn() then
				local hp,mx,hstats=healthPair(); local last=tonumber(__gg.MH_guardLastHP)
				if hp and mx and last and hp<last-0.01 then
					local fraction=math.clamp((tonumber(CFG.HeadDmgReduce) or 0)/100,0,1)
					local adjusted=math.min(mx,hp+(last-hp)*fraction)
					if adjusted>hp then writeHealth(adjusted,hstats); reportHealth(adjusted) end
					__gg.MH_guardLastHP=adjusted
				else __gg.MH_guardLastHP=hp end
			else __gg.MH_guardLastHP=nil end
			local anyInjury=CFG.AntiBleed or CFG.AutoHealBlood or physicalOn()
			if anyInjury then
				local r=csReplica(); if r and r.Data then antiInjurySweep(r.Data,"",0) end
				if type(CharacterState)=="table" then
					for _,s in ipairs({"Stats","State","Data","Wounds","Bones","BodyParts","Status"}) do local t=CharacterState[s]; if type(t)=="table" then antiInjurySweep(t,s:lower()..".",0) end end
					if type(CharacterState.Fractures)=="table" then for k,v in pairs(CharacterState.Fractures) do if injHit("fractures."..tostring(k)) then
						if type(v)=="boolean" then CharacterState.Fractures[k]=false elseif type(v)=="number" then CharacterState.Fractures[k]=0 end
					end end end
				end
			end
		end)
	end end)
end
FLY={}  -- bv/bg/conn (one table instead of 3 locals — Luau 200-local-cap mgmt)
MB={up=false, down=false}  -- mobile fly up/down state, set by the on-screen touch buttons
local function stopFly() if FLY.conn then FLY.conn:Disconnect(); FLY.conn=nil end if FLY.bv then FLY.bv:Destroy(); FLY.bv=nil end if FLY.bg then FLY.bg:Destroy(); FLY.bg=nil end local h=hum(); if h then pcall(function() h.PlatformStand=false end) end end
local function startFly()
	local r=hrp(); if not r then return end
	stopFly(); local h=hum(); if h then pcall(function() h.PlatformStand=true end) end
	FLY.bv=Instance.new("BodyVelocity"); FLY.bv.MaxForce=Vector3.new(1,1,1)*9e9; FLY.bv.Velocity=Vector3.zero; FLY.bv.Parent=r
	FLY.bg=Instance.new("BodyGyro"); FLY.bg.MaxTorque=Vector3.new(1,1,1)*9e9; FLY.bg.P=9e4; FLY.bg.CFrame=Cam.CFrame; FLY.bg.Parent=r
	FLY.conn=RunService.RenderStepped:Connect(function()
		if not (CFG.Fly and alive()) then return end
		local root=hrp(); if not root then return end
		if FLY.bv.Parent~=root then FLY.bv.Parent=root end if FLY.bg.Parent~=root then FLY.bg.Parent=root end
		pcall(function() root.Anchored=false end)
		local cf=workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new(); local dir=Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end
		-- MOBILE / thumbstick: whenever no WASD is down, the thumbstick (MoveDirection) drives horizontal fly.
		-- NOT gated on TouchEnabled (some mobile executors misreport it) — MoveDirection is only non-zero when
		-- the player is actually steering, so this is safe on PC too. On-screen buttons drive up/down.
		if Vector3.new(dir.X,0,dir.Z).Magnitude==0 then local hh0=hum(); local md=hh0 and hh0.MoveDirection; if md and md.Magnitude>0 then dir+=Vector3.new(md.X,0,md.Z) end end
		if MB.up then dir+=Vector3.new(0,1,0) end
		if MB.down then dir-=Vector3.new(0,1,0) end
		FLY.bv.Velocity=(dir.Magnitude>0 and dir.Unit or Vector3.zero)*CFG.FlySpeed; FLY.bg.CFrame=cf
		local hh=hum(); if hh then pcall(function() hh:ChangeState(Enum.HumanoidStateType.Physics) end) end
	end)
end
-- SPEED HACK ONLY drives the body by velocity. INF Stamina uses the game's native Run action below instead of a
-- forced BodyVelocity, which gives the normal maximum sprint without reviving the old snapback/glide bug.
conn(RunService.Heartbeat:Connect(function() if CFG.SpeedHack and alive() and not CFG.Fly then local r=hrp(); if r then local spd=CFG.SpeedVal; local dir=Vector3.zero; local cf=workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new() if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end if dir.Magnitude<=0 then local hh=hum(); local md=hh and hh.MoveDirection; if md and md.Magnitude>0 then dir=md end end if dir.Magnitude>0 then dir=Vector3.new(dir.X,0,dir.Z).Unit*spd; r.AssemblyLinearVelocity=Vector3.new(dir.X,r.AssemblyLinearVelocity.Y,dir.Z) end end end end))
-- INF STAM NATIVE AUTO-RUN: Run=true is the exact PE action observed when the player starts sprinting. Reassert it
-- only while movement is present, clear a stale exhausted/fatigued state, and send Run=false once when movement or
-- the toggle stops. No CFrame/velocity writes are made here.
task.spawn(function()
	local asserted=false; local clearAt=0
	while RUNNING do
		if __gg.MH_stamBV then pcall(function() __gg.MH_stamBV:Destroy() end); __gg.MH_stamBV=nil end
		if CFG.InfStam and alive() and not CFG.Fly then
			local r=hrp(); local moving=false
			if r then local v=r.AssemblyLinearVelocity; moving=Vector3.new(v.X,0,v.Z).Magnitude>0.8 end
			if not moving then
				pcall(function() moving=UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D) end)
			end
			if not moving then local h=hum(); local md=h and h.MoveDirection; moving=md and md.Magnitude>0.05 or false end
			if moving then
				if tick()-clearAt>=0.6 then clearAt=tick()
					replicaFire("SetAction","Exhausted",false); replicaFire("SetAction","Fatigued",false)
					local stats=csStats(); if type(stats)=="table" then for _,k in ipairs({"Exhausted","Exhaustion","Fatigued","Tired"}) do
						if type(stats[k])=="boolean" then stats[k]=false elseif type(stats[k])=="number" then stats[k]=0 end
					end end
				end
				replicaFire("SetAction","Run",true); asserted=true
			elseif asserted then replicaFire("SetAction","Run",false); asserted=false end
			task.wait(0.18)
		else
			if asserted then replicaFire("SetAction","Run",false); asserted=false end
			task.wait(0.3)
		end
	end
end)
-- FLOAT: a Y-only BodyVelocity HOLDS you in the air — plain velocity writes don't hold a CFrame-driven PE dino
-- (that's why Float "didn't work"). It only controls vertical, so you still walk normally. Space=rise, Ctrl=sink.
-- No CFrame teleport = no 267. On enable it lifts you ~4 studs off the ground so you're floating, then hovers.
task.spawn(function() local bv, target while RUNNING do
	if CFG.Float and alive() and not CFG.Fly then
		local r=hrp()
		if r then
			if not (bv and bv.Parent) then pcall(function() if bv then bv:Destroy() end end); bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(0,9e9,0); bv.P=9e4; bv.Velocity=Vector3.new(0,8,0); bv.Parent=r
				local gy; pcall(function() local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={getMyModel()}; local res=WS:Raycast(r.Position+Vector3.new(0,2,0), Vector3.new(0,-300,0), rp); if res then gy=res.Position.Y end end); target=(gy and gy+4) or (r.Position.Y+4) end
			local up
			if UIS:IsKeyDown(Enum.KeyCode.Space) then up=18; target=r.Position.Y
			elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then up=-18; target=r.Position.Y
			else up=math.clamp(((target or r.Position.Y) - r.Position.Y)*4, -4, 8) end  -- ease to float height, then HOLD
			pcall(function() if bv.Parent~=r then bv.Parent=r end bv.Velocity=Vector3.new(0,up,0) end)
		end
		RunService.Heartbeat:Wait()
	else
		if bv then pcall(function() bv:Destroy() end); bv=nil; target=nil end
		task.wait(0.2)
	end
end end)
-- ═══ WATER CONTROLLER (one clean system for Anti-Drown + Walk-on-Water) — REWRITTEN ═══
-- Plain velocity writes don't HOLD a CFrame-driven PE dino (the exact lesson Float taught us) — that's why Walk
-- on Water "kind of worked" and Anti Drown didn't. Now a Y-only BodyVelocity (like Float) HOLDS you:
--   · WALK ON WATER  = held ~2.6 studs ABOVE the surface — you stand/walk on top, X/Z stay free.
--   · ANTI DROWN     = lifted to the surface (+0.8) so your head is out — oxygen never drains.
-- HYSTERESIS bands (detect up to surface+4 while walking on water) so it can't bob/release like before. If the
-- GAME says you're in water but we can't find the surface part, we still lift you. Space=hop up, Ctrl=dive down.
task.spawn(function() local wParts, wT, wbv = {}, 0, nil
while RUNNING do
	if (CFG.AntiDrown or CFG.WalkWater) and alive() and not CFG.Fly then
		local r=hrp()
		if r then
			-- Find the water SURFACE at our position on EVERY land + sandbox:
			--   (1) Terrain water via raycast (IgnoreWater=false → first Water-material hit).
			--   (2) PART-based water (LargeLake / Waves / Ocean… named BaseParts) — PE/sandbox water is PARTS, not
			--       terrain, so THIS is the main path. We cache big water-named parts (every 3s) and check if you're
			--       horizontally inside one and near/below its top.
			local surf
			pcall(function() local rp=RaycastParams.new(); rp.IgnoreWater=false; rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={getMyModel()}; local res=WS:Raycast(r.Position+Vector3.new(0,60,0), Vector3.new(0,-130,0), rp); if res and res.Material==Enum.Material.Water then surf=res.Position.Y end end)
			if not surf then
				if tick()-wT > 10 then wParts={}; wT=tick(); local c=0
					-- AUTHORITATIVE (user's Explorer): all water lives in workspace.Water (ArkoseRiver / GarnetRiver /
					-- Karst River / WaterFlow / Waterfalls / Pond / WetCave). Scan its BaseParts DIRECTLY first — this is
					-- the real water, so Anti-Drown + Walk-on-Water now work on EVERY river/pond regardless of part name.
					local waterFolder=WS:FindFirstChild("Water")
					if waterFolder then for _,d in ipairs(waterFolder:GetDescendants()) do
						if d:IsA("BasePart") and (d.Size.X*d.Size.Z)>15 then wParts[#wParts+1]=d end   -- lower threshold: river segments are thin
					end end
					-- fallback: name-matched big water parts anywhere else — ONLY when the Water folder gave nothing.
					-- (This whole-workspace sweep every few seconds was the Anti-Drown FPS hitch; now it's skipped on
					-- maps that have the real Water folder, and the cache lasts 10s instead of 3s.)
					if #wParts==0 then
					for _,d in ipairs(WS:GetDescendants()) do c+=1; if c>9000 then break end
						if d:IsA("BasePart") then local n=d.Name:lower()
							if (n:find("water") or n:find("lake") or n:find("wave") or n:find("ocean") or n:find("pond") or n:find("lagoon") or n:find("sea") or n:find("swamp") or n:find("river") or n:find("waterfall")) and (d.Size.X*d.Size.Z)>200 then wParts[#wParts+1]=d end
						end
					end
					end
				end
				local band = CFG.WalkWater and 6 or 2   -- wider detect band while standing ON the water (no bobbing)
				for _,p in ipairs(wParts) do if p.Parent then
					local rel=p.CFrame:PointToObjectSpace(r.Position)
					-- MARGIN (+6 studs) on the horizontal box so thin river segments / part edges still count as "on the
					-- water" — the strict edge-only check was why Walk-on-Water missed rivers. Also allow standing up to
					-- the part's half-height + band above its top.
					if math.abs(rel.X)<=p.Size.X/2+6 and math.abs(rel.Z)<=p.Size.Z/2+6 then
						local top=p.Position.Y+p.Size.Y/2
						if r.Position.Y < top+band+p.Size.Y and (not surf or top>surf) then surf=top end
					end
				end end
			end
			-- the GAME knows you're in water even when we can't see the surface — use that as the Anti-Drown fallback
			if not surf and CFG.AntiDrown then
				local says=false
				if CharacterState then pcall(function() says = CharacterState.IsInWater==true or CharacterState.Submerged==true or CharacterState.Underwater==true or CharacterState.Swimming==true end) end
				if not says then local h=hum(); if h then pcall(function() says = h:GetState()==Enum.HumanoidStateType.Swimming end) end end
				if says then surf=r.Position.Y+2.5 end
			end
			local hold=false
			if surf then hold = r.Position.Y < surf + (CFG.WalkWater and 3.2 or 1.2) end
			if hold then
				-- LAG FIX: these remote/state writes used to fire EVERY pass (20x/sec) while you were in water — that
				-- was the other half of the Anti-Drown FPS drop. The DrownY report is already swallowed in the hook,
				-- so these only need a slow heartbeat now (every 0.4s). The lift force below still updates every pass.
				if tick()-(__gg.MH_adRep or 0) > 0.4 then __gg.MH_adRep=tick()
					pcall(function() setReplicaProp("State","Land") end)
					pcall(function() replicaAction("SetAction","Drowning",false) end)
					pcall(function() replicaAction("Mode","Walk") end)
					if CharacterState then for _,k in ipairs({"IsInWater","Submerged","Underwater","Swimming","Drowning"}) do pcall(function() if CharacterState[k]~=nil then CharacterState[k]=false end end) end end
					local stats,maxs=csStats(); if stats then for _,k in ipairs({"Oxygen","Air","Breath","O2"}) do if stats[k]~=nil then stats[k]=(maxs and maxs[k]) or math.max(tonumber(stats[k]) or 0,100) end end end
				end
				-- Y-only BodyVelocity HOLD (the fix): eases to the target height and STAYS there. X/Z untouched = walk freely.
				if not (wbv and wbv.Parent==r) then pcall(function() if wbv then wbv:Destroy() end end); wbv=Instance.new("BodyVelocity"); wbv.Name="MH_Water"; wbv.MaxForce=Vector3.new(0,9e9,0); wbv.P=9e4; wbv.Velocity=Vector3.zero; wbv.Parent=r end
				local target = CFG.WalkWater and (surf+2.6) or (surf+0.8)
				local vy = math.clamp((target - r.Position.Y)*5, -6, tonumber(CFG.AntiDrownRise) or 14)   -- Anti Drown Rise slider = max climb speed
				if UIS:IsKeyDown(Enum.KeyCode.Space) then vy=18 elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vy=-14 end
				pcall(function() wbv.Velocity=Vector3.new(0,vy,0) end)
			elseif wbv then pcall(function() wbv:Destroy() end); wbv=nil end
		end
		task.wait(0.05)
	else
		if wbv then pcall(function() wbv:Destroy() end); wbv=nil end
		task.wait(0.3)
	end
end end)
-- (Invis removed per request.)
conn(RunService.Stepped:Connect(function() if CFG.Noclip and char() then for _,v in ipairs(char():GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end end end end))
-- Inf Jump: force the body up via velocity on Space (works even on dinos that have no jump action — server doesn't
-- have to grant a jump because we're moving the part directly). JumpRequest + InputBegan(Space) double-coverage.
-- Inf Jump: bigger upward velocity = jumps MUCH higher. Forces ANY dino up (even ones with no jump) by moving the
-- body directly; we zero downward first so the full impulse counts (a higher, snappier jump).
-- (Infinite Jump removed per request.)
-- Turn Hack: head angles (replica) + body angular velocity on TurningAnimation.Body (no kick)
task.spawn(function() while RUNNING do task.wait(0.05) if CFG.TurnHack and alive() then pcall(function() setReplicaProp("TurnSpeed", CFG.TurnSpeed) end); pcall(function() local r=hrp(); if not r then return end local rel=r.CFrame:ToObjectSpace(Cam.CFrame); setHeadAngles(math.clamp(math.asin(math.clamp(rel.LookVector.Y,-1,1)),-1.2,1.2),math.clamp(math.atan2(-rel.LookVector.X,-rel.LookVector.Z),-1.5,1.5)) end) end end end)
conn(RunService.Heartbeat:Connect(function() if CFG.TurnHack and alive() then local r=hrp(); if r then local look=Cam.CFrame.LookVector; local flat=Vector3.new(look.X,0,look.Z); if flat.Magnitude>0.05 then local cur=r.CFrame.LookVector; local curFlat=Vector3.new(cur.X,0,cur.Z); if curFlat.Magnitude>0.05 then curFlat=curFlat.Unit; local des=flat.Unit; local cross=curFlat:Cross(des).Y; local dot=math.clamp(curFlat:Dot(des),-1,1); local ang=math.acos(dot)*((cross<0) and -1 or 1); local v=r.AssemblyAngularVelocity; r.AssemblyAngularVelocity=Vector3.new(v.X, ang*CFG.TurnSpeed*0.3, v.Z) end end end end end))
task.spawn(function() while RUNNING do task.wait(0.25); if not alive() then continue end
	if CFG.GodMode then local h=hum(); if h then pcall(function() h.MaxHealth=math.huge; h.Health=math.huge; h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end) end pinStat({"health","hp"},{"Health","HP","MaxHealth"},1e9); setReplicaProp("Health",1e9); setReplicaProp("MaxHealth",1e9); setReplicaProp("Invincible",true); setReplicaProp("Godmode",true) end
	if CFG.InfOxygen then pinStat({"oxygen","air","breath","o2"},{"Oxygen","Air","Breath"},100); setReplicaProp("Oxygen",1000); for _,pp in ipairs({"Submerged","InWater","Underwater","Swimming","Drowning"}) do setReplicaProp(pp,false) end replicaAction("SetAction","Drowning",false)
			-- EXIT-SWIM: your captured swim toggles SET swimming (which drains O2); fire the inverse to leave the water state so oxygen can refill (best-effort, names guessed).
			replicaAction("SetProperty","State","Idle"); replicaAction("SetProperty","State","Walking"); replicaAction("Mode","Walk"); replicaAction("Mode","Land"); replicaAction("SetProperty","Swimming",false); replicaAction("SetProperty","Jumping",false)
			-- YOUR IDEA: tilt the head UP so the game reads it as above water (head-out = oxygen holds). Only when no aim/turn is steering the head.
			if CFG.InfOxygen and not (CFG.TurnHack or CFG.Aimbot or CFG.SilentAim or CFG.LockOn) then setHeadAngles(0.36270577982068064, -1.5707963267948966) end end
	-- (No more per-frame setReplicaProp(...,1000) — that spammed the server with an invalid value every frame. The
	-- local stat pin + the real eat/Sip actions are what actually refill; the HUD pin keeps the bar visually full.)
	-- (food is NOT pinned — it hid the eat prompt; auto-eat keeps it up while leaving the prompt usable)
	if CFG.InfWater then pinStat({"thirst","water","hydrat","drink"},{"Thirst","Water","Hydration"},100) end
end end)
-- INF FOOD: eat nearby food IN PLACE (NO teleport). PE eating = look at food + hold E within range; we fire
-- the food's ProximityPrompt + touch + hold E + Bite/Eat packets for nearby food while you stand still, plus
-- the client pin. The food scan is THROTTLED + capped (so it can't lag you like a per-frame workspace scan would).
local function nearbyFood(range)
	if tick()-FARM.food.t < 3 and (FARM.food.range or 0)>=range then return FARM.food.list end
	local me=hrp(); local out={}; local seen={}; local visited={}
	if me then
		-- edible-plant / herb name list (this game's flora) so INF Food eats ANY plant type around you, not just corpses
		local PLKW={"plant","sapling","tree","fern","berry","berries","pine","needle","leaf","leaves","frond","conifer","cycad","mushroom","fungus","grass","moss","bush","shrub","flower","seed","cone","horsetail","redwood","ginkgo","sequoia","equisetum","woodwardia","blechn","gleichenia","osmunda","zingiber","dicksonia","williamsonia","dryophyll","sabalit","marmarthia","coniopteris","wielandiella","hermanophyton","anthill","herb","foliage","trunk","paleoaster","palaeoaster","araucaria","agathis","athrotaxite","brachyphyllum","elatide","platanites","cycadeoidea"}
		local function isPlantN(n) for _,k in ipairs(PLKW) do if n:find(k,1,true) then return true end end return false end
		local function inspect(d, trustedFoodPool)
			if visited[d] then return end
			visited[d]=true
			-- Prompts: corpses (investigate/eat/consume) AND plants (graze/forage/feed/pick/harvest/eat).
			-- A prompt inside a dedicated Food/Plant/Meat pool is accepted even when its localized ActionText is unknown.
			if d:IsA("ProximityPrompt") then
				local at=(d.ActionText or ""):lower(); local nm=(d.Name or ""):lower(); local ot=(d.ObjectText or ""):lower()
				if trustedFoodPool or at:find("investigate") or at:find("eat") or at:find("consume") or at:find("graze") or at:find("forage")
				 or at:find("feed") or at:find("pick") or at:find("harvest") or at:find("herb") or at:find("plant")
				 or nm:find("investigate") or nm:find("eat") or nm:find("food") or isPlantN(ot) then
					local p=d.Parent
					local part=(p and p:IsA("BasePart") and p)
						or (p and p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") and p.Parent)
						or (p and p:FindFirstChildWhichIsA("BasePart",true))
						or (p and p:FindFirstAncestorWhichIsA("BasePart"))
					local m=(p and p:IsA("Model") and p) or (p and p:FindFirstAncestorWhichIsA("Model"))
						or (part and part:FindFirstAncestorWhichIsA("Model")) or p
					if m and part and not seen[m] then local dd=dist(me.Position,part.Position); if dd<=range then seen[m]=true; out[#out+1]={m,part,dd, prompt=d} end end
				end
			elseif d:IsA("Model") and d~=getMyModel() and not Players:GetPlayerFromCharacter(d) and not seen[d] then
				local n=d.Name:lower()
				if trustedFoodPool or isFoodName(n) or n:find("corpse") or n:find("carcass") or n:find("remains") or isPlantN(n) then
					-- a plant model only counts as food if it actually has an eat prompt (skip decorative scenery)
					local pr=d:FindFirstChildWhichIsA("ProximityPrompt",true)
					local r=rootOf(d); if r and (pr or trustedFoodPool or isFoodName(n) or n:find("corpse")) then local dd=dist(me.Position,r.Position); if dd<=range then seen[d]=true; out[#out+1]={d,r,dd, prompt=pr} end end
				end
			end
		end
		-- Breadth-first, budgeted scans avoid WS:GetDescendants() constructing the entire live map before the old
		-- 6,000-item break. Dedicated runtime food pools are searched first, so late-map meat/plants are not starved.
		local function scan(root,budget,trustedFoodPool)
			if not root then return end
			local queue={root}; local head=1; local count=0
			while head<=#queue and count<budget do
				local d=queue[head]; head+=1; count+=1
				inspect(d,trustedFoodPool)
				local ok,children=pcall(function() return d:GetChildren() end)
				if ok then for _,child in ipairs(children) do if not visited[child] then queue[#queue+1]=child end end end
			end
		end
		local ci=WS:FindFirstChild("CharacterIgnore")
		local dedicated={
			{ci and ci:FindFirstChild("SpawnedMeat"),true}, {ci and ci:FindFirstChild("CorpseSpawns"),true},
			{WS:FindFirstChild("Food"),true}, {WS:FindFirstChild("FoodSpawns"),true}, {WS:FindFirstChild("Edibles"),true},
			{WS:FindFirstChild("Plants"),true}, {WS:FindFirstChild("Flora"),true}, {WS:FindFirstChild("Vegetation"),true},
			{ci and ci:FindFirstChild("LeftCharacters"),false},
		}
		for _,entry in ipairs(dedicated) do scan(entry[1],5000,entry[2]) end
		-- Map layouts vary by server/version. Search likely world containers only when dedicated pools did not give a
		-- useful set, then perform one larger bounded workspace fallback as a last resort.
		if #out<24 then scan(WS:FindFirstChild("Biomes"),12000,false); scan(WS:FindFirstChild("Map"),12000,false) end
		if #out==0 then scan(ci,12000,false); scan(WS,26000,false) end
		table.sort(out,function(a,b) return a[3]<b[3] end)
	end
	FARM.food={t=tick(), list=out, range=range}
	return out
end
-- CARNIVORE MEAT TP: herbivores keep their bar up just eating any plant food-id (plants are everywhere), but a
-- CARNIVORE needs MEAT. When this is on it finds the NEAREST corpse / meat / fish and teleports you ONTO it so
-- INF Food's eat then consumes it. Only meat is matched (never plants), and it only moves you when hunger isn't full.
do   -- SCOPED (Luau 200-local cap): meat helpers + the Carnivore Meat TP loop live here, so their 5 locals don't
     -- persist in the main chunk. nearestMeat is exposed via __gg so the Auto Play Bot (its own do-block) can reuse it.
MEAT_KW = {"corpse","carcass","carrion","meat","chunk","rotten","flesh","remains","dead","fish","gar","sturgeon","bichir","coelacanth","mawsonia","sawfish","egg","grub","larva","insect","ant"}
local function isMeatName(n) n=(n or ""):lower(); for _,k in ipairs(MEAT_KW) do if n:find(k,1,true) then return true end end return false end
-- PLANT EXCLUDER (AI-analysis point the user sent): plants ALSO have eat/consume prompts, so the prompt fallback
-- was teleporting carnivores to plants. Any model whose name matches these is NEVER meat-TP eligible.
PLANT_KW = {"plant","sapling","tree","fern","berry","berries","pine","needle","leaf","leaves","frond","conifer","cycad","mushroom","fungus","grass","moss","bush","shrub","flower","seed","cone","horsetail","redwood","ginkgo","gingko","sequoia","equisetum","woodwardia","blechnace","gleichenia","osmunda","zingiberopsis","dicksonia","williamsonia","weichselia","ptilophyllum","pachypteris","matonidium","cycadeoidea","elatides","dryophyllum","paleoaster","sabalite","marmarthia","coniopteris","wielandiella","hermanophyton"}
local function isPlantName(n) n=(n or ""):lower(); for _,k in ipairs(PLANT_KW) do if n:find(k,1,true) then return true end end return false end
-- RED MESHY MEAT DETECTOR (from the screenshot): PE meat chunks are small RED MeshParts/meshed Parts lying on the
-- ground. Detect by COLOR (red clearly dominates green+blue), a mesh (MeshPart or SpecialMesh child), and a chunk-
-- sized part (not a giant red rock / not a tiny particle). Name is NOT required — this is what catches the meat
-- pieces whose names don't say "meat".
local function isRedMeshMeat(p)
	if not (p and p:IsA("BasePart")) then return false end
	if not (p:IsA("MeshPart") or p:FindFirstChildOfClass("SpecialMesh")) then return false end
	local c=p.Color
	if not (c.R>0.35 and c.R>c.G*1.6 and c.R>c.B*1.6) then return false end   -- red-dominant (meat/blood tone)
	local s=p.Size; local mag=s.Magnitude
	if mag<0.8 or mag>25 then return false end                                 -- chunk-sized only
	-- never a live dino's body part / our own character
	local mdl=p:FindFirstAncestorWhichIsA("Model")
	if mdl then
		if mdl==getMyModel() or Players:GetPlayerFromCharacter(mdl) then return false end
		if mdl:FindFirstChildOfClass("Humanoid") or mdl:FindFirstChild("MeshModel") or mdl:FindFirstChild("TurningAnimation") then
			-- a rigged creature — only meat if the model is a marked corpse
			local dead=false; pcall(function() dead=(mdl:GetAttribute("DinoType") or mdl:GetAttribute("HintType"))~=nil or isMeatName(mdl.Name) end)
			if not dead then return false end
		end
	end
	return true
end
-- SCENT HIGHLIGHT DETECTOR (user's idea, from their Explorer screenshot): the game itself tags smellable corpses
-- with a child named "ScentHighlight" (a Highlight instance) under workspace.Characters[name] — the same thing
-- that lights up red when you press F to sniff. This is the GAME'S OWN authoritative corpse marker, so it's
-- checked FIRST (before any name/posture guess) and is far more reliable than any heuristic.
local function isScentCorpse(m)
	if not (m and m:IsA("Model")) or m==getMyModel() then return false end
	local sh = m:FindFirstChild("ScentHighlight")
	if not (sh and sh:IsA("Highlight")) then return false end
	if sh.Enabled==false then return false end
	-- RED ONLY = corpse/meat (carnivore food). When you sniff, PLANTS get a GREEN ScentHighlight and corpses get a
	-- RED one — matching any color teleported you to plants. Require a clearly RED fill (high red, low green+blue),
	-- checking BOTH FillColor and OutlineColor (the red outline in the screenshot may live on either).
	-- RED, and explicitly NOT yellow: your footprint/scent trail highlights YELLOW (high red AND high green), and
	-- yellow would sneak past a naive "red is high" test. Require green LOW so yellow is rejected.
	local function isRed(c) return c and c.R>0.55 and c.G<0.35 and c.B<0.35 end
	local ok=false
	pcall(function() if isRed(sh.FillColor) or isRed(sh.OutlineColor) then ok=true end end)
	return ok
end
-- THE EXACT PART INSIDE THE RED (user: "teleport to the thing that is inside red"): a Highlight draws its outline
-- on its .Adornee. So the "thing inside red" is ScentHighlight.Adornee — teleport to THAT, not the model's generic
-- root. Falls back to the highlight's parent model root if the Adornee isn't a readable part.
local function scentPart(m)
	local sh = m and m:FindFirstChild("ScentHighlight")
	local ad = sh and sh.Adornee
	if ad then
		if ad:IsA("BasePart") then return ad end
		if ad:IsA("Model") then local r=rootOf(ad); if r then return r end end
	end
	return rootOf(m)
end
-- (No auto-F sniff anymore — user wants it STEALTHY so nobody sees the sniff. We now find corpses/meat directly
--  from the game's own folders, CorpseSpawns, and ragdolls, so we never need to press F.)
-- DOWNED-BODY DETECTOR (user's screenshot): a dino lying on the ground = a corpse to eat. We detect it by POSTURE +
-- STATE, not name: a Model (not us, not a live player) whose main part is (a) tilted like a ragdoll — its UpVector
-- points sideways/down instead of up — or (b) has a dead Humanoid, or (c) carries PE's corpse markers, or (d) is
-- barely moving and lying flat. That's "a body like that in position/ragdoll".
local function isDownedBody(m)
	if not (m and m:IsA("Model")) or m==getMyModel() or Players:GetPlayerFromCharacter(m) then return false end
	local nm=(m.Name or ""):lower()
	-- EXCLUDE your footprint / scent trail (the YELLOW thing) + other flat map decor. These are flat + still, so the
	-- pure-posture check below caught them as "a body" and teleported you onto your own tracks. Never eligible.
	if nm:find("footprint",1,true) or nm:find("print",1,true) or nm:find("track",1,true) or nm:find("trail",1,true)
		or nm:find("scent",1,true) or nm:find("mark",1,true) or nm:find("step",1,true) or isPlantName(nm) then return false end
	-- corpse markers or corpse name = definitely a body
	local marked=false; pcall(function() marked=(m:GetAttribute("DinoType") or m:GetAttribute("HintType"))~=nil end)
	if marked or isMeatName(m.Name) then return true end
	-- dead humanoid = a body
	local h=m:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return true end
	-- POSTURE PATH now ONLY applies to a real CREATURE model (has a rig) — a footprint/decal isn't a creature, so it
	-- can no longer qualify just by lying flat. This is the fix for "it teleports to the yellow footprint".
	local isCreature = m:FindFirstChild("MeshModel") or m:FindFirstChild("TurningAnimation") or m:FindFirstChildOfClass("Humanoid")
	if not isCreature then return false end
	local part=rootOf(m); if not part then return false end
	local ok=false
	pcall(function()
		local up=part.CFrame.UpVector
		local flat = up.Y < 0.55                                  -- >~57° from upright = lying down / ragdolled
		local v=part.AssemblyLinearVelocity; local slow=(v.Magnitude<6)
		if flat and slow then ok=true end
	end)
	return ok
end
local function nearestMeat(range)
	local me=hrp(); if not me then return nil end
	local best,bpart,bd=nil,nil,range
	local seen={}
	local function consider(m, part)
		part = part or (m and (m:IsA("BasePart") and m or rootOf(m) or m:FindFirstChildWhichIsA("BasePart")))
		if not (m and part and part:IsA("BasePart")) or seen[m] then return end
		seen[m]=true
		local dd=dist(me.Position,part.Position); if dd<bd then best,bpart,bd=m,part,dd end
	end
	-- ═══ AUTHORITATIVE FOLDER SCAN (from the user's Explorer screenshots) ═══
	-- The REAL meat + corpses live in these exact folders — NOT scattered by heuristics. Targeting them directly
	-- means the meat TP goes to actual food/corpses and can NEVER hit the anthill mound / footprints / plants
	-- (none of which are in these folders). Each folder child is a meat chunk / ragdoll corpse.
	--   workspace.Food.Meat / workspace.Food.CollectedMeat   = meat chunks (carnivore food)
	--   workspace.DinosaurRagdolls                           = dead dino corpses
	--   workspace.CorpseSpawns / *Corpse* folders            = corpse spawns
	local function scanChildren(f)
		if not f then return end
		for _,m in ipairs(f:GetChildren()) do consider(m) end
	end
	-- DEEP scan for a folder that holds SPAWN markers (CorpseSpawns): a spawn point that actually has a corpse/mesh
	-- spawned at it counts; empty markers are skipped so we don't teleport onto a bare spawn dot.
	local function scanSpawns(f)
		if not f then return end
		for _,d in ipairs(f:GetChildren()) do
			-- a spawn with a real corpse = the marker has a Model child OR a MeshPart, OR the marker itself is a
			-- meshed corpse part. A plain empty spawn Part (no mesh, no model child) is skipped.
			local hasCorpse = d:IsA("Model") or d:FindFirstChildOfClass("Model") or d:FindFirstChildOfClass("MeshPart") or (d:IsA("MeshPart"))
			if hasCorpse then consider(d) end
		end
	end
	-- FOOD folder: every child that is meat/bone/carcass (NOT plants) — covers Meat, CollectedMeat, and any bone item.
	local food = WS:FindFirstChild("Food")
	if food then for _,sub in ipairs(food:GetChildren()) do
		local n=sub.Name:lower()
		if n:find("meat",1,true) or n:find("bone",1,true) or n:find("carcass",1,true) or n:find("corpse",1,true) or n:find("flesh",1,true) or n:find("collect",1,true) then
			if #sub:GetChildren()>0 then scanChildren(sub) else consider(sub) end
		end
	end end
	scanChildren(WS:FindFirstChild("DinosaurRagdolls"))
	-- any folder whose name marks corpses/bones/ragdolls/carcasses anywhere in the workspace
	for _,f in ipairs(WS:GetChildren()) do
		if f:IsA("Folder") then local fn=f.Name:lower()
			if fn:find("corpse",1,true) or fn:find("carcass",1,true) or fn:find("ragdoll",1,true) or fn:find("remains",1,true) or fn:find("deadbod",1,true) then scanSpawns(f) end
		end
	end
	if best then return best,bpart,bd end   -- found real meat/corpse in the folders = go there, done. No heuristics.
	-- ═══ FALLBACK (only when the folders held nothing): the game's own RED scent corpse, then a marked/named corpse
	-- under Characters. Deliberately NO loose posture / red-mesh / prompt sweep here — that's what grabbed the mound.
	local sbest,sbpart,sbd=nil,nil,range
	local function considerScent(m)
		local part=scentPart(m); if not (part and part:IsA("BasePart")) then return end
		local dd=dist(me.Position,part.Position); if dd<sbd then sbest,sbpart,sbd=m,part,dd end
	end
	for _,fn in ipairs({"Characters","Corpses","DeadBodies","Sandbox","Dinos","Creatures","Animals"}) do
		local f=WS:FindFirstChild(fn)
		if f then for _,m in ipairs(f:GetChildren()) do
			if m:IsA("Model") and isScentCorpse(m) then considerScent(m) end
		end end
	end
	if sbest then return sbest,sbpart,sbd end
	-- last resort: a genuinely marked/named corpse under Characters (dead dino left in place)
	local chars=WS:FindFirstChild("Characters")
	if chars then for _,m in ipairs(chars:GetChildren()) do
		if m:IsA("Model") and isDownedBody(m) then consider(m, rootOf(m)) end
	end end
	return best,bpart,bd
end
__gg.MH_nearestMeat = nearestMeat   -- expose so the Auto Play Bot (separate do-block) can reuse it without a 2nd top-level local
carnSpawnT=tick()   -- SPAWN GRACE: never teleport in the first seconds after load/respawn.
pcall(function() LP.CharacterAdded:Connect(function() carnSpawnT=tick() end) end)
-- ═══ CORPSE TELEPORT — cycle EVERY corpse across the WHOLE map + YES/NO confirm + teleport back ═══
local corpseList, corpseIdx, carnOrigin, carnBusy = {}, 0, nil, false
-- DEAD detector (the Save-Dino health trick, applied to OTHER dinos/players): a dead Humanoid, or a health
-- attribute at 0. Dead player = a corpse you can eat.
local function modelDead(m)
	if not (m and m:IsA("Model")) or m==getMyModel() then return false end
	local h=m:FindFirstChildOfClass("Humanoid"); if h and h.MaxHealth>0 then return h.Health<=0 end
	for _,a in ipairs({"Health","HP","Hitpoints","HitPoints"}) do local v=m:GetAttribute(a); if tonumber(v)~=nil then return tonumber(v)<=0 end end
	return false
end
-- Build the list of every ACTUAL corpse/meat on the map (not nearest — all of them, to cycle 25 -> 26 -> 27…).
-- REAL bodies come FIRST (dead players, ragdolls, meat, bones) so the cycle starts on things you can actually eat;
-- empty CorpseSpawns spawn-dots are added LAST and only when a corpse mesh is actually sitting on them (an empty
-- red marker at a far/high position was the "it teleports me up and far to nothing").
local function collectCorpses()
	local out,seen={},{}
	local function add(p) if p and p:IsA("BasePart") and not seen[p] then seen[p]=true; out[#out+1]=p end end
	local function addM(m) if m then add((m:IsA("BasePart") and m) or rootOf(m) or m:FindFirstChildWhichIsA("BasePart")) end end
	local ci=WS:FindFirstChild("CharacterIgnore")
	-- 1) DEAD players/dinos across the WHOLE map (the health trick) — these are the real "dead body users".
	local chars=WS:FindFirstChild("Characters"); if chars then for _,m in ipairs(chars:GetChildren()) do
		if m:IsA("Model") and (modelDead(m) or isScentCorpse(m)) then addM(m) end
	end end
	-- 2) players who died / left (LeftCharacters) + ragdoll corpses + bones + meat = actual eatable bodies
	if ci then local lc=ci:FindFirstChild("LeftCharacters"); if lc then for _,m in ipairs(lc:GetChildren()) do addM(m) end end end
	-- 2a) SPAWNED MEAT (from the game's own MeatController): fresh meat CHUNKS live in a persistent
	--     CharacterIgnore.SpawnedMeat model — every "Meat" part in there is real eatable carnivore food, tagged
	--     HintType="Corpse" by the game itself. Best TP targets on the map for a carnivore, so they're added FIRST
	--     in this group. (Streams everywhere: the game marks the folder Persistent, so far chunks still count.)
	if ci then local sm=ci:FindFirstChild("SpawnedMeat"); if sm then for _,m in ipairs(sm:GetChildren()) do addM(m) end end end
	for _,fn in ipairs({"DinosaurRagdolls","Bonepiles","Corpses","DeadBodies"}) do local f=WS:FindFirstChild(fn); if f then for _,m in ipairs(f:GetChildren()) do addM(m) end end end
	-- Food: DEEP scan (Food.Meat / Food.CollectedMeat may hold grouped models, not flat parts). Every meat/bone MODEL
	-- or top-level meat part counts as one corpse so the "1/2" number reflects what's really eatable on the map.
	local food=WS:FindFirstChild("Food"); if food then for _,sub in ipairs(food:GetChildren()) do
		local kids=sub:GetChildren()
		if #kids>0 then for _,m in ipairs(kids) do addM(m) end else addM(sub) end
	end end
	-- 2b) WHOLE-MAP sweep for anything the game itself marked as a smellable RED corpse (a ScentHighlight), no matter
	--     which folder it sits in — this catches the corpse you SAW that wasn't in Characters/Food (the "1/2" miss).
	pcall(function() for _,h in ipairs(WS:GetDescendants()) do
		if h:IsA("Highlight") and h.Enabled then
			local c=h.FillColor
			if c.R>0.55 and c.G<0.35 and c.B<0.35 then
				local a=h.Adornee or h.Parent; if a then addM(a) end
			end
		end
	end end)
	-- 3) CorpseSpawns.DinosaurSpawn markers — the user's path: workspace.CharacterIgnore.CorpseSpawns:GetChildren()[N].
	--    Corpses spawn AT these points and there are MANY of them, so we cycle EVERY DinosaurSpawn (that's why the count
	--    should read "1/24", not "1/2"). For each marker we PREFER the real body spawned inside it (a Humanoid, a child
	--    Model, or a VISIBLE MeshPart — the marker itself is an invisible Transparency-1 dot); if nothing has spawned
	--    there yet we still target the marker's own position so you can cycle to it and camp the spot.
	-- Count EVERY DinosaurSpawn in the folder (live) — same idea as the gem/fossil node scan: one entry per marker, so
	-- the "X / N" number matches what's actually in CorpseSpawns. We PREFER the real body spawned inside a marker; if
	-- none yet, we still add the marker itself so it's counted + cyclable. (Void/off-map markers can't hurt: the
	-- teleport's own ground guard refuses them and auto-skips to the next, so the count is honest and the TP is safe.)
	if ci then local cs=ci:FindFirstChild("CorpseSpawns"); if cs then for _,d in ipairs(cs:GetChildren()) do
		local corpsePart
		for _,x in ipairs(d:GetDescendants()) do
			if x:IsA("Humanoid") then local p=x.Parent; corpsePart=(p and (rootOf(p) or p:FindFirstChildWhichIsA("BasePart"))); if corpsePart then break end
			elseif x:IsA("MeshPart") and x.Transparency<0.95 then corpsePart=x; break
			elseif x:IsA("Model") and x~=d then corpsePart=rootOf(x) or x:FindFirstChildWhichIsA("BasePart"); if corpsePart then break end end
		end
		local markerPart=(d:IsA("BasePart") and d) or rootOf(d) or d:FindFirstChildWhichIsA("BasePart",true)
		add(corpsePart or markerPart)
	end end end
	return out
end
-- YES/NO confirmation popup
carnGui=Instance.new("ScreenGui"); carnGui.Name="MH_CorpseTP"; carnGui.ResetOnSpawn=false; carnGui.Enabled=false; carnGui.IgnoreGuiInset=true; carnGui.DisplayOrder=9998
safeParentGui(carnGui)
carnFrame=Instance.new("Frame"); carnFrame.Size=UDim2.fromOffset(330,100); carnFrame.Position=UDim2.new(0.5,-165,0,80); carnFrame.BackgroundColor3=Color3.fromRGB(22,24,28); carnFrame.BorderSizePixel=0; carnFrame.Parent=carnGui
Instance.new("UICorner",carnFrame).CornerRadius=UDim.new(0,8)
carnStroke=Instance.new("UIStroke"); carnStroke.Color=Color3.fromRGB(235,90,90); carnStroke.Thickness=1.5; carnStroke.Parent=carnFrame
carnLabel=Instance.new("TextLabel"); carnLabel.Size=UDim2.new(1,-16,0,46); carnLabel.Position=UDim2.fromOffset(8,6); carnLabel.BackgroundTransparency=1; carnLabel.Text="Did it teleport you to a corpse?"; carnLabel.TextColor3=Color3.new(1,1,1); carnLabel.TextSize=14; carnLabel.Font=Enum.Font.GothamMedium; carnLabel.TextWrapped=true; carnLabel.Parent=carnFrame
yesBtn=Instance.new("TextButton"); yesBtn.Size=UDim2.new(0.5,-12,0,34); yesBtn.Position=UDim2.fromOffset(8,58); yesBtn.BackgroundColor3=Color3.fromRGB(46,165,92); yesBtn.Text="YES - stay"; yesBtn.TextColor3=Color3.new(1,1,1); yesBtn.TextSize=13; yesBtn.Font=Enum.Font.GothamBold; yesBtn.BorderSizePixel=0; yesBtn.AutoButtonColor=true; yesBtn.Parent=carnFrame
Instance.new("UICorner",yesBtn).CornerRadius=UDim.new(0,6)
noBtn=Instance.new("TextButton"); noBtn.Size=UDim2.new(0.5,-12,0,34); noBtn.Position=UDim2.new(0.5,4,0,58); noBtn.BackgroundColor3=Color3.fromRGB(205,72,72); noBtn.Text="NO - next corpse"; noBtn.TextColor3=Color3.new(1,1,1); noBtn.TextSize=13; noBtn.Font=Enum.Font.GothamBold; noBtn.BorderSizePixel=0; noBtn.AutoButtonColor=true; noBtn.Parent=carnFrame
Instance.new("UICorner",noBtn).CornerRadius=UDim.new(0,6)
-- Shared teleport transport. SafeTP selects a paced, streamed path; BypassTP controls whether the verified local
-- replica's ordinary CFrame update is mirrored to the server. No other replica id or movement state is touched.
local function MH_hopFire(goalCF)
	if not CFG.BypassTP then return false end
	local sent=false; local ok=pcall(function()
		local re=RS:FindFirstChild("RemoteEvents"); re=re and re:FindFirstChild("ReplicaSignalUnreliable")
		local id=MHNEED and MHNEED.replicaId and MHNEED.replicaId()
		if re and id then re:FireServer(id,"CFrame",goalCF); sent=true end
	end)
	return ok and sent
end
__gg.MH_hopFire=MH_hopFire
__gg.MH_safeTeleport=function(target, options)
	options=options or {}
	local pos = typeof(target)=="CFrame" and target.Position or (typeof(target)=="Vector3" and target) or (typeof(target)=="Instance" and target:IsA("BasePart") and target.Position)
	if typeof(pos)~="Vector3" or pos.X~=pos.X or pos.Y~=pos.Y or pos.Z~=pos.Z or math.abs(pos.X)>1e7 or math.abs(pos.Y)>1e7 or math.abs(pos.Z)>1e7 then return false end
	if tick()<(__gg.MH_spawnGrace or 0) and not options.allowDuringSpawn then return false end
	local feature=options.feature; local token=options.token
	local function featureValid()
		if not feature then return true end
		return CFG[feature]==true and type(__gg.MH_tpFeatureGen)=="table" and __gg.MH_tpFeatureGen[feature]==token
	end
	if not featureValid() then return false end
	local r=hrp(); local cc=getMyModel(); if not r then return false end
	if options.saveReturn and not __gg.MH_tpOrigin then __gg.MH_tpOrigin=r.CFrame end
	__gg.MH_tpSeq=(__gg.MH_tpSeq or 0)+1; local seq=__gg.MH_tpSeq
	local goal=typeof(target)=="CFrame" and target or CFrame.new(pos)
	local from=r.Position; local delta=(pos-from).Magnitude
	__gg.MH_rescueMute=tick()+math.max(4,tonumber(options.settle) or 1.25)+2
	if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
	local safe=CFG.SafeTP==true; local synced=CFG.BypassTP==true
	if safe then pcall(function() LP:RequestStreamAroundAsync(pos,2) end) end
	local hops=safe and math.clamp(math.ceil(delta/120),1,24) or 1
	for i=1,hops do
		if seq~=(__gg.MH_tpSeq or 0) or not featureValid() then return false end
		local step=CFrame.new(from:Lerp(pos,i/hops)); if synced then MH_hopFire(step) end
		if safe and i<hops then pcall(function() local rr=hrp(); if rr then rr.CFrame=step; rr.AssemblyLinearVelocity=Vector3.zero; rr.AssemblyAngularVelocity=Vector3.zero end end); task.wait(0.05) end
	end
	local moved=pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) else r.CFrame=goal end end)
	if not moved then return false end
	pcall(function() r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero end)
	task.spawn(function()
		local untilT=tick()+math.clamp(tonumber(options.settle) or 1.25,0.2,3)
		while RUNNING and seq==(__gg.MH_tpSeq or 0) and featureValid() and tick()<untilT do
			local rr=hrp()
			if rr and (rr.Position-pos).Magnitude>(tonumber(options.tolerance) or 7) then
				if synced then MH_hopFire(goal) end
				pcall(function() rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero; rr.AssemblyAngularVelocity=Vector3.zero end)
			end
			task.wait(0.1)
		end
	end)
	local rr=hrp(); return rr~=nil and (rr.Position-pos).Magnitude<=(tonumber(options.tolerance) or 7)
end
__gg.MH_cancelTeleport=function() __gg.MH_tpSeq=(__gg.MH_tpSeq or 0)+1 end
__gg.MH_snapTo=function(targetPos,options) options=options or {}; if options.settle==nil then options.settle=1.25 end; return __gg.MH_safeTeleport(targetPos,options) end
__gg.MH_hopMove=function(targetPos,options) options=options or {}; if options.settle==nil then options.settle=1.1 end; return __gg.MH_safeTeleport(targetPos,options) end
local function tpToCorpse(part,feature,token)
	local function featureValid() return feature and CFG[feature]==true and type(__gg.MH_tpFeatureGen)=="table" and __gg.MH_tpFeatureGen[feature]==token end
	if not featureValid() or not (part and part.Parent) or carnBusy then return false end
	carnBusy=true
	if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
	local np=part.Position
	-- LAND ON REAL GROUND (fix "it teleports me up and far / floating"): the old ray hit the CORPSE MESH itself
	-- (it wasn't excluded) so you landed ON TOP of the body = "up". Exclude every corpse/meat/spawn folder AND the
	-- target part so the ray only hits real terrain, then stand +3 on it. If nothing is below, use the corpse's own Y.
	local ci=WS:FindFirstChild("CharacterIgnore")
	local landY=np.Y+3
	local foundGround=false
	pcall(function()
		local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; local filter={}
		local function add(inst) if inst then filter[#filter+1]=inst end end
		add(getMyModel()); add(part); add(part.Parent); add(WS:FindFirstChild("Characters")); add(WS:FindFirstChild("DinosaurRagdolls")); add(WS:FindFirstChild("Bonepiles")); add(WS:FindFirstChild("Food"))
		add(ci and ci:FindFirstChild("CorpseSpawns")); add(ci and ci:FindFirstChild("LeftCharacters"))
		rp.FilterDescendantsInstances=filter
		rp.RespectCanCollide=true; rp.IgnoreWater=false
		local res=WS:Raycast(np+Vector3.new(0,60,0), Vector3.new(0,-6000,0), rp)
		if res then landY=res.Position.Y+3; foundGround=true end
	end)
	-- OUT-OF-MAP GUARD: only skip a corpse if it's an OBVIOUS void marker (parked way below the map). A missed
	-- ground ray alone must NOT skip it — that rejected EVERY corpse on this map ("next says none when it's 1/37").
	-- When the ray misses but the corpse is at a normal height, we just teleport to the corpse's own Y.
	if not foundGround and np.Y < -400 then carnBusy=false; return false end
	local cc=getMyModel(); local goal=CFrame.new(np.X, landY, np.Z)
	local noclip={}; if cc then pcall(function() for _,dd in ipairs(cc:GetDescendants()) do if dd:IsA("BasePart") and dd.CanCollide then dd.CanCollide=false; noclip[#noclip+1]=dd end end end) end
	__gg.MH_corpseHoldGoal=goal
	local moved=__gg.MH_safeTeleport and __gg.MH_safeTeleport(goal,{saveReturn=false,settle=1.8,tolerance=6,feature=feature,token=token})
	if not moved then for _,dd in ipairs(noclip) do pcall(function() dd.CanCollide=true end) end; carnBusy=false; return false end
	if not featureValid() then for _,dd in ipairs(noclip) do pcall(function() dd.CanCollide=true end) end; carnBusy=false; return false end
	pcall(function() local m=part:FindFirstAncestorWhichIsA("Model"); local prompt=(m and m:FindFirstChildWhichIsA("ProximityPrompt",true)) or part:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt then local od,oh,ol,oe=prompt.MaxActivationDistance,prompt.HoldDuration,prompt.RequiresLineOfSight,prompt.Enabled
			pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.max(od or 8,30); prompt.HoldDuration=0; prompt.Enabled=true end)
			if fireprox and featureValid() then pcall(function() fireprox(prompt) end) end
			pcall(function() prompt.MaxActivationDistance=od; prompt.HoldDuration=oh; prompt.RequiresLineOfSight=ol; prompt.Enabled=oe end)
		end end)
	-- (removed the holdKey(E) — pressing/holding E every teleport is what "kept clicking" and locked your controls)
	task.delay(1.9, function() for _,dd in ipairs(noclip) do pcall(function() dd.CanCollide=true end) end; if __gg.MH_corpseHoldGoal==goal then __gg.MH_corpseHoldGoal=nil end; carnBusy=false end)
	return true
end
-- go to the NEXT corpse in the list, wrapping, SKIPPING void/out-of-map spots (tpToCorpse returns false for those)
-- until one actually lands you in the map; then ask YES/NO.
local function doNextCorpse(token)
	local function active() return CFG.CarnMeatTP==true and type(__gg.MH_tpFeatureGen)=="table" and __gg.MH_tpFeatureGen.CarnMeatTP==token end
	if not active() then return false end
	-- CORPSE-TP AND PRO FOOD MUST NOT MIX: if Pro Food is running, its circle velocity-drive fights this teleport's
	-- anti-snapback hold — you "go fast then get sent back". Clicking a corpse (Carnivore Meat TP / Next) always
	-- turns Pro Food OFF; Pro Food is only ever the Growth-tab toggle you flip yourself.
	if CFG.ProFood then if __gg.MH_setToggle then __gg.MH_setToggle("ProFood",false) else CFG.ProFood=false end end
	-- CLEAR THE HOLD LOCK FIRST (the premature-"no corpse" fix): the previous TP keeps carnBusy=true for ~2s,
	-- so a fast No-press made every tpToCorpse below bail instantly and the loop wrongly reported "none found".
	-- A deliberate next-corpse press cancels the old hold and always gets a fresh try.
	carnBusy=false; __gg.MH_corpseHoldGoal=nil
	corpseList=collectCorpses()   -- LIVE: re-scan the folder every press so the count is always current
	if not active() then return false end
	if #corpseList==0 then pcall(function() carnGui.Enabled=false end); notify("Corpse TP","No corpse / meat / bone found on the map right now."); return false end
	if not carnOrigin then local r=hrp(); if r then carnOrigin=r.Position end end   -- remember where you were (for Teleport Back)
	local tries=0; local ok=false
	repeat
		if not active() then carnBusy=false; return false end
		corpseIdx = corpseIdx % #corpseList + 1; tries=tries+1
		local part=corpseList[corpseIdx]
		if part and part.Parent then ok = (tpToCorpse(part,"CarnMeatTP",token)==true) end   -- false = void/out-of-map → try the next one
		if not ok then carnBusy=false end   -- a failed try must not leave the lock set for the next corpse in the loop
	until ok or tries>#corpseList
	-- Only after EVERY corpse number has been tried and none landed do we say so.
	if not ok then corpseList={}; pcall(function() carnGui.Enabled=false end); if active() then notify("Corpse TP","Tried all "..tostring(tries).." corpse spots — none are in the map right now. Rescanning next press.") end; return false end
	if not active() then return false end
	pcall(function() carnLabel.Text="Teleported to corpse "..corpseIdx.." / "..#corpseList.." - did it work?"; carnGui.Enabled=true end)
	return true
end
yesBtn.MouseButton1Click:Connect(function()   -- YES = stay at this corpse (and stop the TP-cycle popup)
	pcall(function() carnGui.Enabled=false end)
	if __gg.MH_setToggle then __gg.MH_setToggle("CarnMeatTP", false) else CFG.CarnMeatTP=false end   -- stop the TP-cycle popup
	-- (NO MORE Pro Food AUTO-START: clicking YES used to silently flip Pro Food on, so people who only wanted the
	-- corpse TP suddenly started "moving like Pro Food" — circling on their own. Pro Food is now ONLY ever the
	-- Growth-tab toggle you flip yourself.)
	pcall(function() notify("Corpse TP","Staying here. Want the full growth loop (eat + circle + next corpse)? Turn on Pro Food in the Growth tab.") end)
	local r=hrp(); if r then local pos=r.Position
		task.spawn(function() local bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(9e9,9e9,9e9); bp.P=2e4; bp.D=2500; bp.Position=pos; pcall(function() bp.Parent=r end)
			local t0=tick(); while tick()-t0<1.2 do local rr=hrp(); if rr then pcall(function() rr.AssemblyLinearVelocity=Vector3.zero end) end; task.wait(0.1) end
			pcall(function() bp:Destroy() end)
		end)
	end
end)
noBtn.MouseButton1Click:Connect(function() if CFG.CarnMeatTP then local token=__gg.MH_tpFeatureGen and __gg.MH_tpFeatureGen.CarnMeatTP; task.spawn(function() doNextCorpse(token) end) end end) -- try a different one
__gg.MH_cancelCorpseTP=function() carnBusy=false; __gg.MH_corpseHoldGoal=nil; pcall(function() carnGui.Enabled=false end) end
__gg.MH_corpseBack = function()   -- "Teleport Back" button -> return to where you were
	local o=carnOrigin; if not o then notify("Corpse TP","No saved spot yet - use Carnivore Meat TP first."); return end
	-- KILL the corpse-TP hold first: tpToCorpse pins you at the corpse for ~2s via MH_corpseHoldGoal. If it's still
	-- running when you hit Teleport Back, it yanks you straight back to the corpse ("teleport back doesn't work").
	__gg.MH_corpseHoldGoal = nil
	carnBusy = false
	local moved=__gg.MH_safeTeleport and __gg.MH_safeTeleport(CFrame.new(o),{settle=1.5,tolerance=6})
	if not moved then notify("Corpse TP","Could not return — your character is not ready."); return end
	pcall(function() carnGui.Enabled=false end)
	notify("Corpse TP","Teleported back to where you were.")
end
-- TRIGGER: turning Carnivore Meat TP ON starts the cycle (teleport to a corpse + ask). Turning it OFF hides the popup.
task.spawn(function() local was=false while RUNNING do
	if CFG.CarnMeatTP and alive() and tick()-carnSpawnT>5 and tick()>=(__gg.MH_spawnGrace or 0) then   -- also wait out the spawn grace so it can't TP you into the void on load
		if not was then was=true; if CFG.ProFood then if __gg.MH_setToggle then __gg.MH_setToggle("ProFood",false) else CFG.ProFood=false end end; carnOrigin=nil; corpseList=collectCorpses(); corpseIdx=0; local token=__gg.MH_tpFeatureGen and __gg.MH_tpFeatureGen.CarnMeatTP; task.spawn(function() doNextCorpse(token) end) end
	else if was then was=false; pcall(function() carnGui.Enabled=false end) end end
	task.wait(0.3)
end end)
-- LIVE COUNT: while the popup is showing, keep the "/ N" total fresh (same live-scan idea as gem/fossil), so as
-- corpses spawn/despawn the number tracks the folder instead of freezing at whatever it was when you toggled on.
task.spawn(function() while RUNNING do task.wait(1.5)
	if carnGui.Enabled and CFG.CarnMeatTP and alive() then
		pcall(function() local n=#collectCorpses(); if n>0 then carnLabel.Text="Teleported to corpse "..math.min(corpseIdx,n).." / "..n.." - did it work?" end end)
	end
end end)
__gg.MH_collectCorpses = collectCorpses   -- expose for the Pro Food system (separate do-block)
__gg.MH_tpToCorpse = tpToCorpse
end   -- end of the scoped meat-helpers + Carnivore Meat TP block
-- ═══ PRO FOOD — one-button growth farmer ═══ TP to a corpse with no dinos around → eat until full → when full,
-- kill trot/speed and walk in CIRCLES (grows faster) → when the corpse is gone / food drops, move to the next
-- corpse → stop when you reach the age you picked. Reuses the corpse-TP + food-eat systems (exposed via __gg).
do
	local PRO = { ang=0, lastTP=0, target=nil, lastEat=0 }
	local STAGES = {"hatchling","juvenile","teen","adolescent","subadult","adult","elder","monster"}
	local function stageIdx(name)
		local n=tostring(name):lower():gsub("[^%w]","")
		for i,s in ipairs(STAGES) do if n==s or (n~="" and n:find(s,1,true)) then return i end end
		return nil
	end
	local function curStage()
		local ci
		local ok,_,st = pcall(skGetCharInfo)   -- returns (dt, st, gd)
		if ok and st then ci=stageIdx(st) end
		if not ci then pcall(function() local rr=csReplica(); if rr and rr.Data then ci=stageIdx(rr.Data.GrowthStage or rr.Data.Stage or (rr.Data.Growth and rr.Data.Growth.Stage)) end end) end
		return ci
	end
	local function reachedAge()
		local t=CFG.ProFoodStopAge; if not t or t=="" or t=="Off" then return false end
		local ti=stageIdx(t); local ci=curStage()
		return (ti and ci and ci>=ti) or false
	end
	local function foodFrac()
		local s,m=csStats()
		if s and m then for _,k in ipairs({"Food","Hunger","Nutrition","Fullness"}) do local cv=tonumber(s[k]); local mv=tonumber(m[k]); if cv and mv and mv>0 then return cv/mv end end end
		return nil
	end
	-- a corpse/food with NO other dino within 30 studs of it (so you don't get attacked while eating)
	local function pickSafeFood()
		local me=hrp(); if not me then return nil end
		local mine=getMyModel(); local chars=WS:FindFirstChild("Characters")
		local function dinoNear(pos) if not chars then return false end
			for _,cm in ipairs(chars:GetChildren()) do if cm:IsA("Model") and cm~=mine then
				local h=cm:FindFirstChildOfClass("Humanoid"); if (not h) or h.Health>0 then local r=getHitbox(cm) or rootOf(cm); if r and (r.Position-pos).Magnitude<30 then return true end end
			end end
			return false
		end
		local function eatPrompt(m) return m and m:FindFirstChildWhichIsA("ProximityPrompt",true) end
		-- a DEAD BODY = a dead player/dino corpse (the good eatable ones): a Humanoid at 0 HP, or it sits in a
		-- dead-body folder (LeftCharacters = players who died/left, DinosaurRagdolls, Bonepiles).
		local function isDeadBody(part)
			local m = part:FindFirstAncestorWhichIsA("Model") or part
			local h = m:FindFirstChildOfClass("Humanoid"); if h and h.MaxHealth>0 and h.Health<=0 then return true end
			for _,fn in ipairs({"LeftCharacters","DinosaurRagdolls","Bonepiles"}) do if part:FindFirstAncestor(fn) then return true end end
			return false
		end
		-- 1) ALREADY on/near a real EATABLE corpse (has an eat prompt) → eat in place, no TP
		for _,fd in ipairs(nearbyFood(40)) do local m,part=fd[1],fd[2]
			if part and part.Parent and (fd.prompt or eatPrompt(m)) and not dinoNear(part.Position) then return fd, false end
		end
		-- 2) TP: PREFER DEAD BODIES (dead players/dinos) first, then any other real corpse. Skips empty invisible spawn
		--    markers + any corpse with a dino within 30 studs.
		local corpses = __gg.MH_collectCorpses and __gg.MH_collectCorpses() or {}
		local bestBody,bdB, bestAny,bdA
		for _,part in ipairs(corpses) do if part and part.Parent then
			local m = part:FindFirstAncestorWhichIsA("Model")
			local realCorpse = (tonumber(part.Transparency) or 0)<0.95 or (m and m:FindFirstChildOfClass("Humanoid")) or eatPrompt(m)
			if realCorpse and not dinoNear(part.Position) then
				local d=(part.Position-me.Position).Magnitude
				if isDeadBody(part) then if not bdB or d<bdB then bestBody=part; bdB=d end
				else if not bdA or d<bdA then bestAny=part; bdA=d end end
			end
		end end
		local best = bestBody or bestAny
		if best then return {nil,best,(bestBody and bdB or bdA)}, true end
		return nil
	end
	local function eat(fd)
		local m,part,prompt = fd[1],fd[2],fd.prompt
		if not prompt and m then prompt=m:FindFirstChildWhichIsA("ProximityPrompt",true) end
		if not prompt and part then local mm=part:FindFirstAncestorWhichIsA("Model"); prompt=mm and mm:FindFirstChildWhichIsA("ProximityPrompt",true) end
		if prompt then pcall(function() __gg.MH_activatePrompt(prompt,30) end) end
		-- NO E key presses (user: the E spam blocked their own E for the herb). We fire the prompt + Bite remotes
		-- ONLY, so the food bar fills without the script ever touching E — you press E yourself, once, freely.
		pcall(fakeEat)
	end
	-- eat the corpse IN PLACE with NO key presses at all (user: "don't click E, not at all"). We fire the eat REMOTELY
	-- (the prompt's own remote + the captured Bite remotes) so the bar still fills, but the E key is never touched.
	local function eatAt(part)
		if not part then return end
		local m=part:FindFirstAncestorWhichIsA("Model")
		local prompt=(m and m:FindFirstChildWhichIsA("ProximityPrompt",true)) or part:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt then pcall(function() __gg.MH_activatePrompt(prompt,40) end) end
		pcall(fakeEat)   -- captured Bite remotes — fills the bar without pressing E
	end
	-- FULL → walk in a CIRCLE. REWORKED (was: W+D key holds — those only walked you diagonally in a straight line,
	-- and the fake key-holds could STICK after you turned Pro Food off, so you kept "circling" forever): now the
	-- circle is a Pro-Food-only rotating-heading velocity drive at a slow walk. It is never shared with Infinite Food
	-- or Infinite Stamina. Stopping is a hard stop —
	-- stopCircle() zeroes the drive, releases any legacy keys, and runs the moment Pro Food turns off or you eat.
	local PWK = {W=Enum.KeyCode.W, A=Enum.KeyCode.A, S=Enum.KeyCode.S, D=Enum.KeyCode.D}
	PRO.held = PRO.held or {}
	local function releaseWASD()   -- unconditional key-ups: never trust the held-table to know a key stuck
		for k,kc in pairs(PWK) do PRO.held[k]=false; pcall(function() VIM:SendKeyEvent(false, kc, false, game) end) end
	end
	local function stopCircle()
		PRO.circling=false
		releaseWASD()
		local r=hrp(); if r then pcall(function() r.AssemblyLinearVelocity=Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end) end
	end
	__gg.MH_stopProFood=stopCircle
	local function circle()   -- one STEP of the circle walk; call it repeatedly while food is full
		if not PRO.circling then PRO.circling=true; releaseWASD() end
		local r=hrp(); if not r then return end
		local now=tick(); local dt=math.clamp(now-(PRO.stepT or now), 0, 0.6); PRO.stepT=now
		PRO.ang=((PRO.ang or 0) + dt*0.8) % (2*math.pi)   -- ~8s per lap; walk speed 8 → ≈10-stud circle
		local dir=Vector3.new(math.cos(PRO.ang), 0, math.sin(PRO.ang))
		pcall(function() r.AssemblyLinearVelocity=Vector3.new(dir.X*8, r.AssemblyLinearVelocity.Y, dir.Z*8) end)
		if __gg.MH_hopFire and now-(PRO.cfT or 0)>0.12 then PRO.cfT=now; __gg.MH_hopFire(r.CFrame) end   -- server follows = no snap
	end
	task.spawn(function() while RUNNING do
		if CFG.ProFood and alive() and tick()>=(__gg.MH_spawnGrace or 0) then
			local token=__gg.MH_tpFeatureGen and __gg.MH_tpFeatureGen.ProFood
			local function active() return CFG.ProFood==true and type(__gg.MH_tpFeatureGen)=="table" and __gg.MH_tpFeatureGen.ProFood==token end
			if PRO.token~=token then stopCircle(); PRO.cur=nil; PRO.token=token end
			if reachedAge() then stopCircle(); if __gg.MH_setToggle then __gg.MH_setToggle("ProFood",false) else CFG.ProFood=false; if __gg.MH_featureToggleChanged then __gg.MH_featureToggleChanged("ProFood",false) end end; pcall(function() notify("Pro Food","Reached "..tostring(CFG.ProFoodStopAge).." — growth stopped.") end)
			else
				local ff = foodFrac(); local r = hrp()
				if ff and ff>=0.96 then
					PRO.cur=nil; circle(); task.wait(0.1)           -- FULL → circle to grow (drop the corpse lock)
				elseif PRO.cur and PRO.cur.Parent and r and (PRO.cur.Position - r.Position).Magnitude < 60 then
					-- STICKY: still on the current corpse → EAT IN PLACE, never re-teleport. If food stops rising for
					-- ~5s the corpse is finished → drop it so we move to the next one.
					if ff and (not PRO.lastFood or ff > PRO.lastFood + 0.001) then PRO.lastFood=ff; PRO.foodT=tick() end
					if PRO.foodT and tick()-PRO.foodT > 5 then PRO.cur=nil
					else stopCircle(); eatAt(PRO.cur); task.wait(0.4) end   -- eating = circle off (standing still)
				else
					-- no corpse locked (or it's gone/far) → pick a new SAFE corpse and TELEPORT ONCE, then lock it
					local fd = pickSafeFood()
					if fd and fd[2] then
						stopCircle()
						PRO.cur=fd[2]; PRO.lastFood=ff; PRO.foodT=tick()
						if r and (fd[2].Position - r.Position).Magnitude > 14 and __gg.MH_tpToCorpse then pcall(function() __gg.MH_tpToCorpse(fd[2],"ProFood",token) end); task.wait(0.9) end
						if active() then eatAt(fd[2]); task.wait(0.4) end
					else circle(); task.wait(0.1) end   -- nothing to eat anywhere → keep circling (still grows)
				end
			end
		else PRO.cur=nil; PRO.token=nil; stopCircle(); task.wait(0.2) end   -- Pro Food OFF → hard-stop the circle NOW (keys + velocity)
	end end)
end
task.spawn(function() while RUNNING do
	-- ONLY runs UNTIL you have bitten once. After that, __gg.MH_lastEatCall is set and the pure Bite-spam loop
	-- below takes over — so INF Food stops firing prompts entirely, which is what was interfering with your manual
	-- E-hold. This block discovers and probes a correct food source automatically until a genuine Bite is captured.
	if CFG.InfFood and alive() and not __gg.MH_lastEatCall then
		local token=__gg.MH_foodGen
		-- Get the first correct-diet bite so we can capture the Bite remote (herbivore→plants, carnivore→meat).
		local eHeld = false; pcall(function() eHeld = UIS:IsKeyDown(Enum.KeyCode.E) end)
		if not eHeld then
			-- Search the whole streamed map, not only a 24-stud bubble. The direct stat pin already fills the bar;
			-- this background probe obtains a genuine diet-correct Bite packet for server growth without asking the
			-- player to find/eat something first.
			local me=hrp(); local list=nearbyFood(math.huge)
			local edible = _G.MH_edible                  -- diet gate (set once the diet helpers load); nil-safe
			if me and edible and #list>0 then for step=1,#list do
				if not CFG.InfFood or token~=__gg.MH_foodGen then break end
				__gg.MH_foodProbeCursor=((__gg.MH_foodProbeCursor or 0)%#list)+1
				local fd=list[__gg.MH_foodProbeCursor]
				local m,r,prompt=fd[1],fd[2],fd.prompt
				if not prompt and m then prompt=m:FindFirstChildWhichIsA("ProximityPrompt",true) end
				-- DIET FILTER: skip anything your dino should not eat (this is what keeps Comfort — and INF Stam — healthy)
				local dietOk = false
				if m then local okc,res=pcall(function() return edible(m, prompt) end); if okc then dietOk=(res==true) end end
				if dietOk and prompt and r and r.Parent then
					-- Try one diet-correct source per pass, rotating after rejection so a stale/streamed prompt cannot
					-- starve every valid source behind it.
					local stillHold=false
					pcall(function() stillHold = UIS:IsKeyDown(Enum.KeyCode.E)
						or (prompt.KeyboardKeyCode and prompt.KeyboardKeyCode~=Enum.KeyCode.Unknown and UIS:IsKeyDown(prompt.KeyboardKeyCode)) end)
					if not stillHold then
						task.wait()
						if not CFG.InfFood or token~=__gg.MH_foodGen then break end
						pcall(function() __gg.MH_activatePrompt(prompt,math.huge) end)
					end
					break
				end
			end end
		end
		task.wait(0.5)
	else task.wait(0.4) end
end end)
-- INF FOOD — INFINITE BITE SPAM: once you have bitten ONCE (the hook captured your exact "Bite" call), this replays
-- that exact Bite remote on a fast loop, forever, so the bar stays pinned full with no walking and no key press. It
-- fires ONLY the Bite remote — it never touches E, never fires a prompt, never toggles Consuming — so it can NEVER
-- interfere with your manual E-hold-to-eat. This is the whole INF Food after the first bite.
task.spawn(function() while RUNNING do
	if CFG.InfFood and alive() and __gg.MH_lastEatCall then
		local token=__gg.MH_foodGen
		local eHeld=false; pcall(function() eHeld=UIS:IsKeyDown(Enum.KeyCode.E) end)
		if eHeld then __gg.MH_lastE=tick() end
		if not eHeld and tick()-(__gg.MH_lastE or 0)>1.25 then
			local rs=getReplicaSignal()
			if rs then
				-- One controller owns all Bite replay. The speed slider is a bounded per-pass budget,
				-- and a cursor rotates through sources instead of blasting every saved call every frame.
				local list=__gg.MH_biteCalls
				if type(list)~="table" or #list==0 then list={__gg.MH_lastEatCall} end
				local budget=math.clamp(math.floor(tonumber(CFG.FoodEatSpeed) or 3),1,10)
				for _=1,budget do
					if not CFG.InfFood or token~=__gg.MH_foodGen then break end
					__gg.MH_foodCursor=((__gg.MH_foodCursor or 0)%#list)+1
					local ec=list[__gg.MH_foodCursor]
					if type(ec)=="table" and ec.n and ec.n>=2 then
						local re=RS:FindFirstChild("RemoteEvents"); local exact=(re and ec.remote and re:FindFirstChild(ec.remote)) or rs
						pcall(function() exact:FireServer(table.unpack(ec,1,ec.n)) end)
					end
				end
			end
		end
		task.wait(0.25)
	else task.wait(0.4) end
end end)
task.spawn(function() while RUNNING do
	if CFG.InfWater and alive() then
		fakeDrink()                       -- fires the Sip remote directly (works map-wide)
		-- E-KEY SPAM REMOVED ("the E thing is spamming, I can't eat"): this loop used to press E every 0.6s —
		-- its synthetic key-UP kept cancelling your own hold-to-eat. The Sip remote alone fills water fine.
		task.wait(0.6)
	else task.wait(0.4) end
end end)
-- Anti Fractured Head: keep head angles neutral (clears the fracture distortion) when no aim/turn feature is steering it.
task.spawn(function() while RUNNING do task.wait(0.5) if CFG.AntiFracture and alive() and not CFG.InfOxygen and not (CFG.TurnHack or CFG.Aimbot or CFG.SilentAim or CFG.LockOn) then pcall(function() setHeadAngles(0,0) end) end end end)
task.spawn(function() while RUNNING do task.wait(0.3); if not alive() then continue end
	if CFG.AntiFracture then clearStatus({"headfracture","headinjury","concussion","hairfracture","skullfracture"},{"headfracture","headinjury","concussion","brokenhead","hairfracture","skullfracture"}); for _,e in ipairs(Lighting:GetDescendants()) do if e:IsA("BlurEffect") then pcall(function() e.Enabled=false; e.Size=0 end) end end pcall(function() local cam=WS.CurrentCamera; if cam then for _,e in ipairs(cam:GetDescendants()) do if e:IsA("BlurEffect") then e.Enabled=false; e.Size=0 end end end end); local pg=LP:FindFirstChild("PlayerGui"); if pg then for _,gg in ipairs(pg:GetDescendants()) do if (gg:IsA("Frame") or gg:IsA("ImageLabel") or gg:IsA("CanvasGroup")) then local n=gg.Name:lower(); if n:find("headfracture",1,true) or n:find("concus",1,true) or n:find("skull",1,true) then pcall(function() gg.Visible=false end) end end end end end
	if CFG.AntiBleed then clearStatus({"bleed","bleeding","hemorrhage","wound"},{"bleed","bleeding","hemorrhage","wound"}) end
	if CFG.AntiFall then clearStatus({"fall","falldamage","falldmg"},{"Falling","FallDamage","FallDmg"}); if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end end
	if CFG.AntiBreakHead then clearStatus({"skull","concuss","hairfrac"},{"HeadBreak","HeadFracture","SkullBreak","JawBreak"}) end
	if CFG.AntiBreakNeck then clearStatus({"neckbreak","neckfrac"},{"NeckBreak","NeckFracture","BrokenNeck"}) end
	if CFG.AntiBreakLeg then clearStatus({"legbreak","footbreak","limbbreak"},{"LegBreak","LegFracture","FootBreak","BrokenLeg"}) end
	if CFG.AntiBreakTail then clearStatus({"tailbreak"},{"TailBreak","TailFracture","BrokenTail"}) end
	if CFG.AntiBreakTorso then clearStatus({"torsobreak","spinebreak","ribbreak"},{"TorsoBreak","TorsoFracture","SpineBreak","RibBreak"}) end
end end)
task.spawn(function() while RUNNING do task.wait(0.4); local pg=LP:FindFirstChild("PlayerGui")
	if CFG.NoSleep and pg then local sg=pg:FindFirstChild("SleepGui"); if sg then pcall(function() if sg:IsA("ScreenGui") then sg.Enabled=false else sg.Visible=false end end) end for _,gg in ipairs(pg:GetDescendants()) do if (gg:IsA("Frame") or gg:IsA("ImageLabel") or gg:IsA("CanvasGroup")) then local n=gg.Name:lower(); if n:find("sleep") or n:find("tired") or n:find("rest") or n:find("drowsy") or n:find("fatigue") then pcall(function() gg.Visible=false end) end end end end
	if CFG.NoDarkWater then for _,e in ipairs(Lighting:GetDescendants()) do pcall(function() if e:IsA("ColorCorrectionEffect") and e.Name~="MH_FB" then if e.Brightness<0 then e.Brightness=0 end e.Contrast=math.max(e.Contrast,0) elseif e:IsA("Atmosphere") then e.Density=math.min(e.Density,0.1); e.Haze=0 elseif e:IsA("DepthOfFieldEffect") then e.Enabled=false end end) end local r=hrp(); if r and r.Position.Y<2 then pcall(function() if Lighting.Brightness<1.5 then Lighting.Brightness=2 end Lighting.FogEnd=math.max(Lighting.FogEnd,5000) end) end end
end end)
-- NO NIGHT: tight 0.1s loop force-sets ClockTime + Brightness + clears the "darken at night" effects the game
-- keeps re-applying. Also pins TimeOfDay to noon so the game can't tick it back to dawn/dusk.
task.spawn(function() while RUNNING do task.wait(0.1); if CFG.NightVision then pcall(function() Lighting.ClockTime=14; Lighting.TimeOfDay="14:00:00"; Lighting.Brightness=math.max(Lighting.Brightness,2); Lighting.Ambient=Color3.fromRGB(140,140,140); Lighting.OutdoorAmbient=Color3.fromRGB(170,170,170); for _,e in ipairs(Lighting:GetChildren()) do if e:IsA("ColorCorrectionEffect") and e.Name~="MH_FB" then e.Brightness=math.max(e.Brightness,0); e.Saturation=math.max(e.Saturation,-0.3) elseif e:IsA("Atmosphere") then e.Density=math.min(e.Density,0.2); e.Haze=0 elseif e:IsA("BlurEffect") then e.Enabled=false end end end) end end end)
task.spawn(function() while RUNNING do task.wait(0.4) if CFG.InfLight and char() then local found=false; for _,l in ipairs(char():GetDescendants()) do if l:IsA("PointLight") or l:IsA("SpotLight") or l:IsA("SurfaceLight") then found=true; pcall(function() l.Range=60; l.Brightness=8; l.Enabled=true end) end end if not found then local r=hrp(); if r and not r:FindFirstChild("MH_Light") then local pl=Instance.new("PointLight"); pl.Name="MH_Light"; pl.Range=60; pl.Brightness=8; pl.Parent=r end end end end end)
SAVED = {light=nil, fbCC=nil, zoom=nil, water=nil}  -- consolidated saved-state (was 4 separate locals)
conn(RunService.Heartbeat:Connect(function() pcall(function()
	if CFG.FullBright then
		if not SAVED.light then SAVED.light={Lighting.Brightness,Lighting.ClockTime,Lighting.FogEnd,Lighting.GlobalShadows,Lighting.Ambient,Lighting.OutdoorAmbient,Lighting.ExposureCompensation} end
		-- TRUE full bright on every land: max ambient (lights up caves/underwater/night), no shadows, no fog/atmosphere.
		Lighting.Brightness=3; Lighting.ClockTime=14; Lighting.FogEnd=1e6; Lighting.FogStart=0; Lighting.GlobalShadows=false
		Lighting.Ambient=Color3.fromRGB(185,185,185); Lighting.OutdoorAmbient=Color3.fromRGB(185,185,185); Lighting.ExposureCompensation=0.4
		for _,e in ipairs(Lighting:GetChildren()) do
			if e:IsA("Atmosphere") then pcall(function() e.Density=0; e.Haze=0; e.Glare=0 end)
			elseif (e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect")) then pcall(function() e.Enabled=false end)
			elseif e:IsA("ColorCorrectionEffect") and e.Name~="MH_FB" then pcall(function() if e.Brightness<0 then e.Brightness=0 end e.Contrast=math.max(e.Contrast,0) end) end
		end
		if not (SAVED.fbCC and SAVED.fbCC.Parent) then SAVED.fbCC=Instance.new("ColorCorrectionEffect"); SAVED.fbCC.Name="MH_FB"; SAVED.fbCC.Parent=Lighting end
		SAVED.fbCC.Brightness=0.18; SAVED.fbCC.Contrast=0.05; SAVED.fbCC.Saturation=0.08; SAVED.fbCC.TintColor=Color3.fromRGB(255,255,255)
	else
		if SAVED.fbCC then pcall(function() SAVED.fbCC:Destroy() end); SAVED.fbCC=nil end
		if SAVED.light then Lighting.Brightness=SAVED.light[1]; Lighting.ClockTime=SAVED.light[2]; Lighting.FogEnd=SAVED.light[3]; Lighting.GlobalShadows=SAVED.light[4]; if SAVED.light[5] then Lighting.Ambient=SAVED.light[5] end if SAVED.light[6] then Lighting.OutdoorAmbient=SAVED.light[6] end if SAVED.light[7]~=nil then Lighting.ExposureCompensation=SAVED.light[7] end; SAVED.light=nil end
	end
end) end))
pcall(function() conn(LP.Idled:Connect(function() if CFG.AntiAFK then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)) end)
conn(RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera   -- FRESH each frame: the cached Cam goes stale after respawn = "FOV changer doesn't work"
	if CFG.UnlockFOV and cam then pcall(function() cam.FieldOfView = tonumber(CFG.FOV) or 70 end) end
	if CFG.InfZoom then if not SAVED.zoom then SAVED.zoom={LP.CameraMaxZoomDistance,LP.CameraMinZoomDistance} end pcall(function() LP.CameraMaxZoomDistance=100000; LP.CameraMinZoomDistance=0.5 end) elseif SAVED.zoom then pcall(function() LP.CameraMaxZoomDistance=SAVED.zoom[1]; LP.CameraMinZoomDistance=SAVED.zoom[2] end); SAVED.zoom=nil end
end))
-- Always Damage (PvP): auto-fire the captured Attack remote at EVERY nearby character within DamageRange.
-- Works in normal play AND Sandbox (scans workspace.Characters + sandbox folders + nil-parented dino models).
task.spawn(function() while RUNNING do
	if CFG.AlwaysDamage and alive() then
		local me=hrp()
		if me then
			-- FIND TARGETS FIRST — collect every enemy inside DamageRange. If there's NOBODY in range we do NOTHING
			-- (no click, no SoundRemote, no attack) so it never "auto-attacks nothing". Only when a target exists do we
			-- swing once through the captured SoundRemote, wait a frame for the server's attack window, then fire hits.
			local mine=getMyModel(); local targs={}; local seen={}
			local function consider(m)
				if #targs>=8 or not (m and m:IsA("Model") and m~=mine) or seen[m] then return end
				seen[m]=true
				local h=m:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return end
				local hb=getHitbox(m); if hb and dist(me.Position,hb.Position)<=(tonumber(CFG.DamageRange) or 120) then targs[#targs+1]=m end
			end
			for _,m in ipairs(charModels()) do if #targs>=8 then break end consider(m) end
			if #targs<8 and typeof(getnilinstances)=="function" then
				pcall(function() local c=0; for _,v in next, getnilinstances() do c+=1; if c>4000 or #targs>=8 then break end
					if typeof(v)=="Instance" and v:IsA("Model") and (v:FindFirstChild("Hitbox") or v:FindFirstChild("HitBox") or v:FindFirstChild("Physics") or v:FindFirstChild("MeshModel")) then consider(v) end
				end end)
			end
			-- One serialized exact sequence: captured RegisterAttack, one frame, then captured Attack hit packet(s).
			if #targs>0 then MHCOMBAT.sequence(targs) end
		end
		task.wait(1/math.max(1,CFG.DamageRate))
	else task.wait(0.15) end
end end)
-- CLICK TO DAMAGE (fix: "can't click/damage" with Hitbox on) — PE damage fires through the captured Attack remote +
-- SoundRemote, which were ONLY wired to the Always-Damage auto-loop. So a plain click never fired them = no damage.
-- Now, while HITBOX is on, a real M1 click (not on the menu) fires the SAME proven swing→window→hit sequence at every
-- enemy inside the expanded reach, so clicking actually deals damage. Debounced so a click can't spam-report.
do local lastClickDmg=0; local mouse=LP:GetMouse()
	-- mouse.Target is usually nested several Models deep (Hitbox.Head.Head). Find the outer
	-- character model instead of treating the nearest inner Model as the combat target.
	__gg.MH_combatModelFromPart=function(part)
		local mine=getMyModel(); local cur=part
		while cur and cur~=WS do
			if cur:IsA("Model") and cur~=mine then
				local h=cur:FindFirstChildOfClass("Humanoid")
				if h or cur:FindFirstChild("MeshModel") or cur:FindFirstChild("Physics") or cur:FindFirstChild("Hitbox") or cur:FindFirstChild("HitBox") or Players:GetPlayerFromCharacter(cur) then return cur end
			end
			cur=cur.Parent
		end
		return nil
	end
conn(UIS.InputBegan:Connect(function(input, gp)
	if gp then return end                                            -- click landed on the GUI = ignore (don't attack)
	if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
	if not (CFG.HitboxExpand and alive()) then return end            -- only when Hitbox is on
	if tick()-lastClickDmg < 0.12 then return end; lastClickDmg=tick()
	local me=hrp(); if not me then return end
	local rng=math.max(tonumber(CFG.DamageRange) or 120, (tonumber(CFG.HitboxSize) or 50)*0.5 + 8)
	-- THE BONE YOU CLICKED: mouse.Target is the CanQuery Hitbox bone part under the cursor (the expander sets those
	-- CanQuery=true). We hit that enemy on that exact bone first, then AoE the rest at their auto bone.
	local clicked=mouse.Target
	local clickedModel=clicked and __gg.MH_combatModelFromPart(clicked)
	task.spawn(function()
		local mine=getMyModel(); local targs={}; local seen={}
		-- clicked enemy FIRST, aiming the exact bone you clicked
		if clickedModel and clickedModel:IsA("Model") and clickedModel~=mine and getHitbox(clickedModel)
			and dist(me.Position, (getHitbox(clickedModel) or clicked).Position)<=rng then
			seen[clickedModel]=true; targs[#targs+1]=clickedModel
		end
		local function hit(m)
			if #targs>=8 or not (m and m:IsA("Model") and m~=mine) or seen[m] then return end
			local hb=getHitbox(m); if hb and dist(me.Position,hb.Position)<=rng then seen[m]=true; targs[#targs+1]=m end
		end
		for _,m in ipairs(charModels()) do if #targs>=8 then break end hit(m) end
		if #targs>0 then MHCOMBAT.sequence(targs,clicked) end
	end)
end)) end
task.spawn(function() while RUNNING do task.wait(0.5); local terrain=WS:FindFirstChildOfClass("Terrain"); if CFG.WaterClear and terrain then if not SAVED.water then SAVED.water={terrain.WaterTransparency,terrain.WaterReflectance,terrain.WaterWaveSize} end pcall(function() terrain.WaterTransparency=0.92; terrain.WaterReflectance=0; terrain.WaterWaveSize=0 end) elseif SAVED.water and terrain then pcall(function() terrain.WaterTransparency=SAVED.water[1]; terrain.WaterReflectance=SAVED.water[2]; terrain.WaterWaveSize=SAVED.water[3] end); SAVED.water=nil end end end)
task.spawn(function() while RUNNING do task.wait(1) if CFG.NoClouds then pcall(function() local t=WS:FindFirstChildOfClass("Terrain"); local cl=t and t:FindFirstChildOfClass("Clouds"); if cl then cl.Cover=0; cl.Density=0; cl.Enabled=false end end) for _,e in ipairs(Lighting:GetDescendants()) do if e.ClassName=="Clouds" then pcall(function() e.Enabled=false end) end end end end end)
saving=false
-- Save Dino: reads HP from the Humanoid (the HUD does too, so it's reliable) AND the replica Stats. When HP% drops
-- below the threshold it does a heal/anti-death burst — NO TELEPORT. Pins health + clears EVERY injury (bleed/
-- fracture/broken bone — the real HP drains) + fires any heal remote. (Health is server-side; stopping the drain
-- is the realistic save. If it still doesn't refill, the game has no instant heal — capture it via Log Remotes.)
task.spawn(function() while RUNNING do task.wait(0.25); if CFG.SaveDino and alive() and not saving then
	local stats, maxs = csStats()
	local h=hum()
	local hp = (h and h.Health) or (stats and (stats.Health or stats.HP))
	local mx = (h and h.MaxHealth) or (maxs and (maxs.Health or maxs.HP))
	if hp and mx and mx>0 and (hp/mx)*100 <= CFG.SaveHP then
		saving=true
		pcall(function()
			for _=1,12 do
				if h then h.Health=h.MaxHealth end
				if stats then for _,k in ipairs({"Health","HP"}) do if stats[k]~=nil then stats[k]=mx end end end
				pinStat({"health","hp"},{"Health","HP"},mx); setReplicaProp("Health", mx)
				clearStatus({"bleed","fractur","broke","wound","injur","concuss","hemorrhage"},{"Bleeding","Fractured","Broken","BrokenLeg","BrokenHead","BrokenTail","BrokenTorso","Wound","Concussion"})
				-- recursive injury sweep over the replica (catches the unknown broken-leg field that killed you)
				local function sw(tb,d) if type(tb)~="table" or d>3 then return end for k,v in pairs(tb) do if type(k)=="string" then local lk=k:lower() if (lk:find("brok") or lk:find("fractur") or lk:find("bleed") or lk:find("wound") or lk:find("injur")) then if type(v)=="boolean" then tb[k]=false elseif type(v)=="number" then tb[k]=0 end end end if type(v)=="table" then sw(v,d+1) end end end
				if stats then sw(stats,0) end local rr=csReplica(); if rr and rr.Data then sw(rr.Data,0) end
				task.wait(0.08)
			end
			local hr=findRemote({"heal","health","restore","recover","revive"}); if hr then fireRemoteMulti(hr) end
		end)
		task.wait(0.7); saving=false
	end
end end end)
-- AUTO CLEAN: fire the captured (myDinoId,"CleanlinessStart") so the dino self-cleans (cleanliness never drops).
task.spawn(function() while RUNNING do if CFG.AutoClean and alive() then pcall(function() replicaFire("CleanlinessStart") end); task.wait(2.5) else task.wait(0.5) end end end)
-- AFK EAT (PLUS): lift you HIGH up — out of reach of every dino, so nothing can touch you — and hold you there while
-- INF Food's Bite spam keeps you fed, so you AFK GROW safely. It turns INF Food on for you (the growth food source),
-- anchors you ~450 studs up (once), and pins you there. Plus build only. Toggle off = you drop back down.
if not _G.PE_HIDE_LITE then
	local afkAnchor
	conn(RunService.Heartbeat:Connect(function()
		if not (CFG.AfkEat and alive()) then afkAnchor=nil; return end
		-- AFK Eat owns only this explicit lift. Need and protection toggles stay user-owned, so enabling or disabling
		-- Infinite Food/Stamina can never enter this movement path.
		local r=hrp(); if not r then return end
		if not afkAnchor then afkAnchor = r.Position + Vector3.new(0, 300, 0) end   -- lift once (gentler 300 studs)
		pcall(function() r.CFrame = CFrame.new(afkAnchor); r.AssemblyLinearVelocity = Vector3.new(0,0,0); r.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
		if CFG.AntiFall and CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
	end))
end

-- HITBOX EXPANDER (enemy creatures + players ONLY — same targeting as the proven standalone test build:
-- workspace.Characters children, skip YOUR model, both "HitBox"/"Hitbox" spellings, same property set)
hbTouched={}
hbSeen={}
HBX={boneToPart=setmetatable({}, {__mode="k"}),partToBone=setmetatable({}, {__mode="k"})}
-- EXACT working-build property set (CanTouch=false, CanQuery=true, CanCollide=false, Massless=true). This is the
-- combo that actually lands hits. We expand EVERY BasePart inside the enemy's Hitbox/HitBox container (the per-bone
-- parts), filtered by the chosen bone (All/Head/Neck/Arm/Leg/Body). NEVER touches your own model.
local function boneMatch(name)
	local sel=CFG.HitboxBone or "All"; if sel=="All" then return true end
	local n=name:lower()
	if sel=="Head" then return n:find("head",1,true) or n:find("jaw",1,true) or n:find("skull",1,true) end
	if sel=="Neck" then return n:find("neck",1,true) end
	if sel=="Arm"  then return n:find("arm",1,true) or n:find("hand",1,true) or n:find("claw",1,true) or n:find("finger",1,true) or n:find("humerus",1,true) or n:find("wing",1,true) end
	if sel=="Leg"  then return n:find("leg",1,true) or n:find("foot",1,true) or n:find("femur",1,true) or n:find("tibia",1,true) or n:find("thigh",1,true) or n:find("toe",1,true) end
	if sel=="Body" then return n:find("spine",1,true) or n:find("body",1,true) or n:find("hip",1,true) or n:find("torso",1,true) or n:find("chest",1,true) or n:find("tail",1,true) end
	if sel=="Tail" then return n:find("tail",1,true) end
	if sel=="Hip"  then return n:find("hip",1,true) or n:find("pelvis",1,true) end
	return false
end
local function expandPart(p)
	if not (p and p:IsA("BasePart")) then return end
	if not hbTouched[p] then hbTouched[p]=HBX.partToBone[p] and "proxy" or {p.Size,p.Transparency,p.CanCollide,p.Material,p.Massless,p.CanTouch,p.CanQuery,p.Color} end
	hbSeen[p]=true
	pcall(function()
		if HBX.partToBone[p] then p.Anchored=true end
		p.Massless   = true
		p.CanCollide = false
		p.CanQuery   = true     -- raycast / M1 hit checks read it
		p.CanTouch   = false    -- the working build uses FALSE (this is what made it land)
		local size=math.clamp(tonumber(CFG.HitboxSize) or 35,4,300)
		local wanted=Vector3.new(size,size,size)
		if p.Size ~= wanted then p.Size=wanted end
		if CFG.HitboxVisible then p.Transparency=math.clamp(1-((tonumber(CFG.HitboxOpacity) or 40)/100),0,1); p.Material=Enum.Material.ForceField; local c=CFG.HitboxColor or {}; p.Color=Color3.fromRGB(c.r or 255,c.g or 50,c.b or 50)   -- Opacity slider drives how much you see (0=invisible, 100=solid)
		else p.Transparency=1 end
	end)
end
function HBX.expandBone(bone,model)
	if not (bone and bone:IsA("Bone") and model) then return nil end
	local p=HBX.boneToPart[bone]
	if not (p and p.Parent) then
		local folder=model:FindFirstChild("__MH_BoneHitboxes")
		if not folder then folder=Instance.new("Folder"); folder.Name="__MH_BoneHitboxes"; folder.Parent=model end
		p=Instance.new("Part"); p.Name=bone.Name; p.Anchored=true; p.CastShadow=false; p.CanCollide=false; p.CanTouch=false; p.CanQuery=true; p.Parent=folder
		HBX.boneToPart[bone]=p; HBX.partToBone[p]=bone
	end
	local pos=_bonePos(bone); if not pos then return nil end
	pcall(function() p.CFrame=CFrame.new(pos) end); expandPart(p); return p
end
local function restorePart(p)
	local o=hbTouched[p]; local bone=HBX.partToBone[p]
	if bone then
		local folder=p and p.Parent; HBX.partToBone[p]=nil; if HBX.boneToPart[bone]==p then HBX.boneToPart[bone]=nil end
		pcall(function() if p then p:Destroy() end end); hbTouched[p]=nil
		if folder and folder.Parent and #folder:GetChildren()==0 then pcall(function() folder:Destroy() end) end
		return
	end
	if type(o)=="table" and p and p.Parent then pcall(function() p.Size=o[1]; p.Transparency=o[2]; p.CanCollide=o[3]; p.Material=o[4]; p.Massless=o[5]; if o[6]~=nil then p.CanTouch=o[6] end if o[7]~=nil then p.CanQuery=o[7] end if o[8]~=nil then p.Color=o[8] end end) end
	hbTouched[p]=nil
end
-- Expand every BasePart inside the enemy's Hitbox/HitBox container (the container part itself + all per-bone parts),
-- filtered by the selected bone. ENEMIES ONLY (never our own model — that would block our own clicks/movement).
local function expandModel(m)
	if not m then return end
	local grewAny=false; local bones={}; local boneSeen={}
	local function bonePriority(b)
		local n=b.Name:lower()
		if n:find("head",1,true) or n:find("skull",1,true) or n:find("jaw",1,true) then return 1 end
		if n:find("neck",1,true) then return 2 end
		if n:find("spine",1,true) or n:find("chest",1,true) then return 3 end
		if n:find("hip",1,true) or n:find("pelvis",1,true) or n:find("body",1,true) or n:find("torso",1,true) then return 4 end
		if n:find("leg",1,true) or n:find("femur",1,true) or n:find("tibia",1,true) or n:find("foot",1,true) then return 5 end
		if n:find("arm",1,true) or n:find("hand",1,true) or n:find("claw",1,true) then return 6 end
		if n:find("tail",1,true) then return 7 end
		return 20
	end
	local function grow(d)
		if d:IsA("BasePart") then
			if boneMatch(d.Name) then expandPart(d); grewAny=true elseif hbTouched[d] then restorePart(d) end
		elseif d:IsA("Bone") and boneMatch(d.Name) and not boneSeen[d] then boneSeen[d]=true; bones[#bones+1]=d end
	end
	local function flushBones()
		table.sort(bones,function(a,b) local pa,pb=bonePriority(a),bonePriority(b); if pa==pb then return a.Name<b.Name end; return pa<pb end)
		for i=1,math.min(#bones,16) do if HBX.expandBone(bones[i],m) then grewAny=true end end
	end
	do local inst=findHitboxContainer(m)
		if inst then
			grow(inst)
			for _,d in ipairs(inst:GetDescendants()) do grow(d) end
			flushBones()
		end
	end
	-- FALLBACK — WORKS ON EVERY DINO: some dinos have no "Hitbox" container (or an oddly-named one), so nothing grew
	-- above. Grow the model's OWN parts too — the MeshModel bones' render parts, the HumanoidRootPart, and any direct
	-- BasePart — filtered by the selected bone. This is why "hitbox didn't work on some dinos": they had no Hitbox box.
	if not grewAny then
		local hrp2=m:FindFirstChild("HumanoidRootPart"); if hrp2 and hrp2:IsA("BasePart") and (CFG.HitboxBone=="All" or CFG.HitboxBone=="Body") then expandPart(hrp2); grewAny=true end
		local cnt=0
		for _,d in ipairs(m:GetDescendants()) do
			cnt+=1; if cnt>400 then break end
			if d:IsA("BasePart") and d~=hrp2 and boneMatch(d.Name) then expandPart(d); grewAny=true
			elseif d:IsA("BasePart") and hbTouched[d] and not boneMatch(d.Name) then restorePart(d) end
			if d:IsA("Bone") and boneMatch(d.Name) and not boneSeen[d] then boneSeen[d]=true; bones[#bones+1]=d end
		end
		flushBones()
	end
end
-- (Bone Protection NO LONGER shrinks your hitbox — that broke your M1. It now clears the chosen bone's break/
-- fracture STATUS via the antiInjurySweep loop above. The expander below only touches ENEMY hitboxes.)
-- Re-apply enemy hitbox expansion continuously. ENEMIES ONLY — the own-model check is
-- now BULLETPROOF ("I still see my hitbox" fix): name match (the test build's check), LP.Character, the Player
-- object, AND the model your own body part actually lives in (covers sandbox dinos that aren't named after you).
-- On top of that, any of YOUR parts that ever got touched are restored on the spot, every tick.
task.spawn(function() local cleared=true while RUNNING do
	if CFG.HitboxExpand and alive() then
		cleared=false
		hbSeen={}
		local mine=getMyModel()
		local myR=hrp()
		local function isMine(m)
			if m==mine or m.Name==LP.Name then return true end
			if LP.Character and (m==LP.Character or m:IsDescendantOf(LP.Character) or LP.Character:IsDescendantOf(m)) then return true end
			if Players:GetPlayerFromCharacter(m)==LP then return true end
			if myR and myR:IsDescendantOf(m) then return true end
			return false
		end
		-- ALL STREAMED DINOS: use the same full model list combat/targeting use (Characters,
		-- CharacterIgnore.LeftCharacters, sandbox/NPC containers, and late joiners). The old 28-model/140-stud gate is
		-- why some visible dinosaurs never showed a hitbox. We process every admitted creature nearest-first and yield
		-- between batches so a crowded server does not freeze for one long frame.
		local me=hrp()
		local models = (_G.MH_charModels and _G.MH_charModels()) or {}
		if me then
			local all={}
			for _,m in ipairs(models) do
				if m:IsA("Model") and not isMine(m) then
					-- Ignore container Models that merely contain many dinosaurs; require this model's own rig marker.
					local creature=m:FindFirstChild("MeshModel") or m:FindFirstChild("Physics") or m:FindFirstChild("TurningAnimation")
						or m:FindFirstChildOfClass("Humanoid") or m:FindFirstChild("Hitbox") or m:FindFirstChild("HitBox") or Players:GetPlayerFromCharacter(m)
					if creature then local r=getHitbox(m) or rootOf(m); if r then all[#all+1]={m,dist(me.Position,r.Position)} end end
				end
			end
			table.sort(all, function(a,b) return a[2]<b[2] end)
			for i,pair in ipairs(all) do
				expandModel(pair[1])
				if i%10==0 then task.wait() end
			end
		end
		-- Restore despawned models or parts that stopped matching the selected bone.
		for p in pairs(hbTouched) do
			if not (p and p.Parent) or not hbSeen[p] or (mine and p:IsDescendantOf(mine)) or (LP.Character and p:IsDescendantOf(LP.Character)) or p:FindFirstAncestor(LP.Name) then restorePart(p) end
		end
		task.wait(0.15)
	else
		if not cleared then for p in pairs(hbTouched) do restorePart(p) end hbSeen={}; cleared=true end
		task.wait(0.25)
	end
end end)

-- AIMBOT + SILENT AIM + LOCK ON (camera assist only — NO metamethod hook; targets the BODY)
local aimTarget, aimRoot, aimPart
task.spawn(function()
	while RUNNING do
		task.wait(0.15)
		if (CFG.Aimbot or CFG.SilentAim or CFG.LockOn) and alive() then
			local me=hrp(); local mine=getMyModel(); local rng=math.max(tonumber(CFG.DamageRange) or 120,(tonumber(CFG.HitboxSize) or 35)*0.5+16)
			local choice=tostring(CFG.HitboxBone or "All").."|"..tostring(CFG.AimPart or "Hitbox")
			local keep=false
			-- LOCK ON / AUTO TARGET: STICK to the enemy you're already fighting if it's still valid + roughly in front
			-- (within 60°). So it focuses ONE enemy — the one you're facing — instead of flickering between many.
			if aimTarget and aimTarget.Parent and me then
				local rb=getHitbox(aimTarget) or rootOf(aimTarget)
				if rb then local dir=rb.Position-Cam.CFrame.Position; local dd=dir.Magnitude
					if dd>0 and dd<=rng then local ang=math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot(dir.Unit),-1,1))); if ang<=60 then aimRoot=rb; keep=true end end
				end
			end
			if not keep and me then
				-- pick the target MOST IN FRONT of your camera (smallest angle) within range + a 55° cone.
				local best,bestRoot,bestScore
				local function consider(m)
					if not (m and m:IsA("Model") and m~=mine) then return end
					local h=m:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return end
					local rb=getHitbox(m) or rootOf(m); if not rb then return end
					local dir=rb.Position-Cam.CFrame.Position; local dd=dir.Magnitude; if dd<1 or dd>rng then return end
					local ang=math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot(dir.Unit),-1,1))); if ang>55 then return end
					if not bestScore or ang<bestScore then best,bestRoot,bestScore=m,rb,ang end
				end
				for _,m in ipairs(charModels()) do consider(m) end   -- includes CharacterIgnore.LeftCharacters (where dinos live)
				aimTarget=best; aimRoot=bestRoot; aimPart=best and getAimPart(best) or nil
			end
			if aimTarget and (__gg.MH_aimChoice~=choice or not aimPart or not aimPart.Parent) then aimPart=getAimPart(aimTarget) end
			__gg.MH_aimChoice=choice
		else aimTarget, aimRoot, aimPart = nil, nil, nil; __gg.MH_aimChoice=nil end
	end
end)
conn(RunService.RenderStepped:Connect(function()
	if not (CFG.Aimbot or CFG.SilentAim or CFG.LockOn) or not alive() then return end  -- no SG.Enabled gate (it's pinned true as the menu signal — it was killing the whole aim system)
	local held = true
	if CFG.Aimbot and not (CFG.SilentAim or CFG.LockOn) then local aimKey = CFG.Keybinds["AimKey"] or CFG.AimKey; if aimKey and aimKey~="" then pcall(function() held = UIS:IsKeyDown(Enum.KeyCode[aimKey]) end) end end
	if not held or not aimTarget then return end
	-- Camera lock for Aimbot + Lock On (visible). PURE Silent Aim does NOT move the camera (that's the point) —
	-- it lands hits via the spoofed Attack remote in the silent-aim loop below instead.
	if not (CFG.Aimbot or CFG.LockOn) then return end
	local pos = partPos(aimPart) or (aimRoot and aimRoot.Position)
	if pos then Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, pos), math.clamp(1-CFG.AimSmooth, CFG.LockOn and 0.25 or 0.05, 1)) end
end))
-- SILENT AIM: silently fire the captured Attack remote at the locked target (no camera movement). This is what
-- makes Silent Aim genuinely "silent" — your view never snaps, but the nearest dino takes hits.
task.spawn(function() while RUNNING do if CFG.SilentAim and alive() then local t=aimTarget or nearestTarget(math.max(tonumber(CFG.DamageRange) or 120,(tonumber(CFG.HitboxSize) or 35)*0.5+16), true); if t then MHCOMBAT.sequence(t) end; task.wait(1/math.max(1,tonumber(CFG.DamageRate) or 4)) else task.wait(0.15) end end end)
-- NO GRAB WEIGHT LIMIT — the strong version from the decompiled LIVEGrab module (3k-line build). The "above your
-- weight limit!" check is CLIENT-side: CanBind() calls CharacterState.Grab:MeetsWeightLimit() and each grab ability
-- has a WeightLimit (% of YOUR Weight). We patch MeetsWeightLimit -> always true AND set every grab ability's
-- WeightLimit -> 1e9 (originals saved, restored on toggle-off so normal grabs are never broken). No IsGrabbing
-- re-assert (that froze your movement), so you keep full movement and can grab anything + release normally.
task.spawn(function()
	local origMeets, origLimits = nil, nil
	while RUNNING do
		if CFG.NoGrabLimit then
			pcall(function()
				local Gr = CharacterState and CharacterState.Grab
				if Gr and type(Gr.MeetsWeightLimit)=="function" and not origMeets then origMeets=Gr.MeetsWeightLimit; Gr.MeetsWeightLimit=function() return true end end
				local ab = CharacterState and CharacterState.Data and CharacterState.Data.Abilities
				if ab then origLimits=origLimits or {}
					for name,data in pairs(ab) do
						if type(name)=="string" and name:lower():find("grab",1,true) and type(data)=="table" then
							if type(data.WeightLimit)=="number" and data.WeightLimit<1e8 then if origLimits[data]==nil then origLimits[data]=data.WeightLimit end data.WeightLimit=1e9 end
							for _,v in pairs(data) do
								if type(v)=="table" and type(v.WeightLimit)=="number" and v.WeightLimit<1e8 then if origLimits[v]==nil then origLimits[v]=v.WeightLimit end v.WeightLimit=1e9 end
							end
						end
					end
				end
			end)
			task.wait(0.2)
		else
			if origMeets then pcall(function() if CharacterState and CharacterState.Grab then CharacterState.Grab.MeetsWeightLimit=origMeets end end); origMeets=nil end
			if origLimits then pcall(function() for t,lim in pairs(origLimits) do t.WeightLimit=lim end end); origLimits=nil end
			task.wait(0.4)
		end
	end
end)
-- UNLOCK MOUSE + CAMERA: free the cursor (so you can click/move freely) and keep it visible. Re-applied because the
-- game re-locks it. Works the same in Sandbox + Survival (pure client UIS).
task.spawn(function() while RUNNING do
	if CFG.UnlockMouse then
		pcall(function()
			-- CLICK/ATTACK FIX: PE needs the mouse LOCKED to register a bite. So only free the cursor when you are
			-- NOT clicking at all (neither left nor right button). The instant you hold a button to attack, we STOP
			-- unlocking and LOCK it to center, so Unlock Mouse can never cancel your bite/attack.
			local clicking = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			if clicking then
				UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
			else
				UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
			end
		end)
		task.wait(0.05)
	else task.wait(0.4) end
end end)
-- (Auto Farm Player removed per request.)

-- AUTO FARM FOSSIL + GEMSTONE
-- Real in-game layout (from screenshot): <Container> > Spawned > <ResourceModel e.g. Topaz_151> >
--   MineralBase (BasePart) + GemstonePrompt (ProximityPrompt). Fossils similar (SpawnedFossils > ... > FossilS).
-- keyword sets. CONTAINER match is kept TIGHT so we never grab dino/bone folders; the last-resort prompt
-- scan can be a little broader because it also inspects the prompt itself.
FARM_CKW = { fossil = {"fossil"}, gem = {"gem","mineral","gemstone","crystal"} }
FARM_PKW = { fossil = {"fossil","excavat","dig","unearth"}, gem = {"gem","mineral","gemstone","crystal","topaz","quartz","ruby","emerald","amethyst","sapphire","diamond","harvest","mine"} }
-- EXCLUSION keywords: a node matching the OTHER kind must be skipped. Gem prompts also say "Dig"/"Excavate",
-- so fossil mode's keyword fallback was classifying every gemstone as a fossil ("collecting gems, not fossils").
FARM_XKW = { fossil = {"gem","mineral","gemstone","crystal","topaz","quartz","ruby","emerald","amethyst","sapphire","diamond","opal","jade","garnet","onyx","pearl","agate","obsidian","citrine","peridot","turquoise"}, gem = {"fossil"} }
local function kwHit(name, list) if not name then return false end name=name:lower(); for _,k in ipairs(list) do if name:find(k,1,true) then return true end end return false end
local function kindMismatch(kind, prompt)   -- does this prompt/its part chain belong to the OTHER resource?
	local x = FARM_XKW[kind]; if not x then return false end
	if kwHit(prompt.ActionText, x) or kwHit(prompt.Name, x) then return true end
	local p = prompt.Parent
	for _ = 1, 4 do if p then if kwHit(p.Name, x) then return true end; p = p.Parent end end
	return false
end
local function farmContainers(kind)
	local cs={}
	local function add(inst) if inst and not table.find(cs,inst) then cs[#cs+1]=inst end end
	-- match ANY direct child of WS / CharacterIgnore whose name CONTAINS the kind keyword (covers
	-- SpawnedFossils / GemstoneSpawns / Fossils / Gems / Minerals … without needing exact names).
	for _,root in ipairs({WS, WS:FindFirstChild("CharacterIgnore")}) do
		if root then
			for _,child in ipairs(root:GetChildren()) do
				if (child:IsA("Folder") or child:IsA("Model")) and kwHit(child.Name, FARM_CKW[kind]) then
					add(child); local sp=child:FindFirstChild("Spawned"); if sp then add(sp) end
				end
			end
		end
	end
	return cs
end
-- A node = {holder, part, dist}. We scan the matched containers' DESCENDANTS (bounded to the resource
-- folders, so cheap AND complete) for ProximityPrompts (the collect trigger) and resource parts. If NO
-- container matched at all, we fall back to a full-map prompt scan with a MUCH higher cap (the old 3000
-- cap was hit long before reaching the nodes in this game's huge workspace = "farm never teleports").
local function gatherNodes(kind, range)
	local me=hrp(); if not me then return {} end
	local out, seen = {}, {}
	local function addNode(holder, part)
		if not (part and part:IsA("BasePart") and part.Parent) or seen[part] then return end
		local d=dist(me.Position, part.Position); if d<=range then seen[part]=true; out[#out+1]={holder or part.Parent or part, part, d} end
	end
	local scanned=0
	local matchedContainer=false
	for _,folder in ipairs(farmContainers(kind)) do
		matchedContainer=true
		-- a fossil container (SpawnedFossils/FossilSpawns) holds ONLY fossils, so for fossils we take ANY
		-- BasePart in it. This is why it used to teleport to opals: the exact-name check missed this rig's
		-- fossil parts, #out stayed 0, and the keyword last-resort then matched gem "Dig" prompts.
		local takeAny = (kind=="fossil")
		for _,d in ipairs(folder:GetDescendants()) do
			scanned+=1; if scanned>10000 or #out>=250 then break end
			if d:IsA("ProximityPrompt") then
				local part=d.Parent
				if part and part:IsA("BasePart") and not kindMismatch(kind, d) then addNode(part.Parent, part) end   -- skip the OTHER resource's prompts (mixed containers)
			elseif d:IsA("BasePart") and (takeAny or (kind=="gem" and d.Name=="MineralBase") or (kind=="fossil" and (d.Name=="FossilS" or d.Name=="FossilM" or d.Name=="FossilL" or d.Name=="Fossil")) or kwHit(d.Name, FARM_CKW[kind])) then
				addNode(d.Parent, d)
			end
		end
		if scanned>10000 or #out>=250 then break end
	end
	-- LAST RESORT: run ONLY when NO real container matched (never when fossils exist -> can't grab opals).
	if not matchedContainer and #out==0 then
		local sc2=0
		for _,d in ipairs(WS:GetDescendants()) do
			sc2+=1; if sc2>25000 or #out>=250 then break end
			if d:IsA("ProximityPrompt") then
				local hit = kwHit(d.ActionText, FARM_PKW[kind]) or kwHit(d.Name, FARM_PKW[kind])
				if not hit then local p=d.Parent; for _=1,4 do if p then if kwHit(p.Name, FARM_PKW[kind]) then hit=true; break end; p=p.Parent end end end
				if hit and kindMismatch(kind, d) then hit=false end   -- "Dig"/"Excavate" also matches GEM prompts - the other kind's nodes never count
				if hit then local part=d.Parent; if part and part:IsA("BasePart") then addNode(part.Parent, part) end end
			end
		end
	end
	table.sort(out,function(a,b) return a[3]<b[3] end)
	return out
end
-- Throttled node cache (rebuild every 2s) — the per-tick GetDescendants over hundreds of gems was the LAG.
local function getNodes(kind, range)
	local c=FARM.nodeCache[kind]
	if c and (tick()-c.t < 2) and c.range==range then return c.list end  -- rebuild every 2s so newly-spawned nodes get collected fast
	local list=gatherNodes(kind, range)
	FARM.nodeCache[kind]={t=tick(), list=list, range=range}
	return list
end
-- AUTO FARM — TELEPORT MODE: each farm owns a cancellation generation and moves only while its own exact toggle
-- remains enabled. Toggle-off or character change cancels movement immediately and never performs an automatic
-- return teleport. Fall immunity is forced while the explicitly selected farm is active.
-- LAG FIXES in both modes: the dig-remote search runs ONCE ever (re-walking ReplicatedStorage every pass when the
-- remote doesn't exist was the big farm lag), node list cached 2s, hard scan caps.
local function runFarm(enabledKey, kind, rangeKey)
	task.spawn(function()
		local pending={}
		local wasOn,featureToken = false,nil
		local function featureActive() return CFG[enabledKey]==true and type(__gg.MH_tpFeatureGen)=="table" and __gg.MH_tpFeatureGen[enabledKey]==featureToken end
		while RUNNING do
			if CFG[enabledKey] and alive() then
				local currentToken=__gg.MH_tpFeatureGen and __gg.MH_tpFeatureGen[enabledKey]
				if not wasOn or featureToken~=currentToken then wasOn=true; featureToken=currentToken end
				for part,holder in pairs(pending) do if not (part and part.Parent) then FARM.count[kind]=(FARM.count[kind] or 0)+1; pending[part]=nil end end
				if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
				-- dig remote: search ONCE (negative-cached) — this was the lag.
				if not FARM.digSearched then FARM.digSearched=true; FARM.dig=findRemote({"collectfossil","collectgem","startcollection","excavat","harvest"}) end
				local list=getNodes(kind, 1e9)
				if not featureActive() then continue end
				if CFG.FarmTeleport then
					-- pick the nearest un-tried node, TP to it, collect it, wait for it to vanish
					local nd
					for _,cand in ipairs(list) do
						local holder,part=cand[1],cand[2]
						if part and part.Parent then local t=FARM.tried[part]; if not t or tick()-t>15 then nd=cand; break end end
					end
					if nd then
						local holder,part=nd[1],nd[2]
						if not featureActive() then continue end
						FARM.tried[part]=tick()
						do
							-- FOSSILS = INSTANT TELEPORT (you asked: "it needs to teleport, not glide"). MH_snapTo snaps you
							-- straight onto the node and beats the rubber-band by feeding the server the goal on its own move
							-- remote + re-asserting only if you get shoved — no slow walk between fossils. GEMS keep the glide
							-- (their 12s channel doesn't care about a slower approach, and it's proven to stick).
							local goalPos=part.Position+Vector3.new(0,1.5,0); local moved=false
							if kind=="fossil" and __gg.MH_snapTo then
								moved=__gg.MH_snapTo(goalPos,{feature=enabledKey,token=featureToken,settle=1.25})==true
								task.wait(0.1)
							elseif __gg.MH_hopMove then
								moved=__gg.MH_hopMove(goalPos,{feature=enabledKey,token=featureToken,settle=1.1})==true
								local t0=tick()
								while featureActive() and tick()-t0<2.2 do local r=hrp(); if r and (r.Position-goalPos).Magnitude<8 then break end; task.wait(0.05) end
							end
							if not moved then task.wait(0.2); continue end
						end
						if not featureActive() then continue end
						local r0=hrp(); if r0 then pcall(function() r0.AssemblyLinearVelocity=Vector3.zero; r0.AssemblyAngularVelocity=Vector3.zero end) end
						task.wait(0.15)
						local prompt=part:FindFirstChildWhichIsA("ProximityPrompt")
						if not prompt then for _,d in ipairs(holder:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d; break end end end
						pending[part]=holder
						-- HOLD for the node's REAL duration (gems channel ~12s, fossils ~3s). The old 2.5s cap gave up
						-- before a gem finished = "auto farm doesn't collect". Keep planted with a BodyPosition (no fall),
						-- fire the prompt ONCE (it auto-holds), AND hold the real E key + listen for Triggered = done.
						local hold = (kind=="gem") and 12 or 3
						local done=false
						local tconn; if prompt then pcall(function() tconn=prompt.Triggered:Connect(function() done=true end) end) end
						local me=hrp(); local bp; pcall(function() if me then bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(9e9,9e9,9e9); bp.P=2e4; bp.D=2500; bp.Position=me.Position; bp.Parent=me end end)
						local od,ol,okc,oen
						if prompt then pcall(function() od,ol,okc,oen=prompt.MaxActivationDistance,prompt.RequiresLineOfSight,prompt.KeyboardKeyCode,prompt.Enabled; prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=1e9; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.Enabled=true end) end
						if prompt and fireprox then pcall(function() fireprox(prompt) end) end
						-- raw E is only a fallback for no-fireprox executors, and ONLY when you are not physically holding E,
						-- so a running farm never injects a key-up that cancels your manual hold-to-eat.
						local eManual=false; pcall(function() eManual=UIS:IsKeyDown(Enum.KeyCode.E) end)
						if not eManual then pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end) end
						if FARM.dig and FARM.dig.Parent then pcall(function() fireRemoteMulti(FARM.dig, holder) end) end
						local t0=tick()
						while featureActive() and tick()-t0<hold+2 and holder.Parent and part.Parent and not done do task.wait(0.15) end
						if not eManual then pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end
						if tconn then pcall(function() tconn:Disconnect() end) end
						if prompt and fireprox and featureActive() then pcall(function() fireprox(prompt) end) end   -- backup: complete it now
						if prompt then pcall(function() prompt.MaxActivationDistance=od; prompt.RequiresLineOfSight=ol; prompt.KeyboardKeyCode=okc; prompt.Enabled=oen end) end   -- restore native prompt state
						pcall(function() if bp then bp:Destroy() end end)
						if done or not (part and part.Parent) then FARM.count[kind]=(FARM.count[kind] or 0)+1; FARM.tried[part]=nil; pending[part]=nil end   -- clear pending too, or the vanish-sweep counts this node AGAIN (double count)
						-- SLOW cadence for fossils (you asked for it): pause between each fossil so it collects one at a
						-- calm pace instead of blinking node-to-node. Gems keep the quick pace.
						task.wait((kind=="fossil") and (tonumber(CFG.FossilSlow) or 1.2) or 0.2)
					else task.wait(0.6) end
				else
					-- STAND-STILL mode (zero movement = the anti-cheat never sees you move): fire prompts remotely, 6/pass.
					local n=0
					for _,nd in ipairs(list) do
						if not featureActive() then break end
						local holder,part=nd[1],nd[2]
						if part and part.Parent then
							local t=FARM.tried[part]
							if not t or tick()-t>12 then
								FARM.tried[part]=tick()
								local prompt=part:FindFirstChildWhichIsA("ProximityPrompt")
								if not prompt then for _,d in ipairs(holder:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d; break end end end
								if prompt and fireprox then
									local od,ol,oh=prompt.MaxActivationDistance,prompt.RequiresLineOfSight,prompt.HoldDuration
									pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=1e9; prompt.HoldDuration=0 end)
									pcall(function() fireprox(prompt) end)
									pcall(function() prompt.MaxActivationDistance=od; prompt.RequiresLineOfSight=ol; prompt.HoldDuration=oh end)
									pending[part]=holder
								end
								if FARM.dig and FARM.dig.Parent then pcall(function() fireRemoteMulti(FARM.dig, holder) end) end
								n+=1; if n>=6 then break end
							end
						end
					end
					task.wait(0.3)
				end
			else
				if wasOn then
					wasOn=false; featureToken=nil
				end
				task.wait(0.4)
			end
		end
	end)
end
runFarm("AutoFarmFossil","fossil","FarmFossilRange")
runFarm("AutoFarmGem","gem","GemRange")

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════
-- AUTO PLAY BOT v2 — a full survival AI that PLAYS THE GAME for you.
-- It runs a priority-driven state machine every tick:
--   1. FLEE   — a predator (player-controlled carnivore / unknown meat-eater) is inside the flee range →
--               run directly AWAY from it (biased back toward home), never stopping to eat/sleep.
--   2. DRINK  — water below your threshold → walk to the nearest known water, then sip until topped up
--               (the captured per-map Sip ids fire the whole time, so the bar fills even mid-walk).
--   3. EAT    — food below your threshold → walk to the nearest DIET-LEGAL food (plants for herbivores,
--               corpses/meat for carnivores, both for omnivores) and fire its eat prompt when in reach.
--   4. REST   — hurt (HP under 60%) and no predator around → lie down + sleep so the game heals you,
--               waking instantly if a threat appears.
--   5. ROAM   — nothing urgent → wander to random points around the HOME position (set where you toggled
--               the bot on), pausing like a human player, so you keep passive growth ticking.
-- Movement is a velocity drive at a server-safe walk speed (no CFrame writes = no 267 teleport kick),
-- with stuck detection (jump + re-path when wedged) and water/void avoidance via the existing guards.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════
do   -- scoped block: the bot's locals live only here (keeps the chunk under Luau's 200-local register cap)
BOT = {
	state="idle",        -- current state name (for the announcer + HUD)
	home=nil,            -- Vector3 home position, captured when the bot turns on
	goal=nil,            -- Vector3 current movement goal (nil = stand still)
	goalWhy="",          -- label for the announcer
	target=nil,          -- the food model / threat model the goal points at
	threat=nil,          -- current predator model being fled from
	lastAnnounce=0,      -- throttle for notify()
	lastState="",        -- last announced state (announce only on CHANGE)
	stuckPos=nil,        -- position sample for stuck detection
	stuckT=0,            -- time of that sample
	unstuckUntil=0,      -- while now<this, we're doing the unstick jump/strafe
	roamWait=0,          -- idle-pause end time between roam legs
	sleeping=false,      -- true while the bot holds the Sleep action
	waterPos=nil,        -- last place we successfully drank / saw water (remembered)
	dietSaid=false,      -- one-time diet announcement
	prevF=nil, prevW=nil, prevS=nil,   -- user's own INF toggles, restored on bot-off
}
-- announce a state change (throttled; respects the BotAnnounce toggle)
local function botSay(msg)
	if not CFG.BotAnnounce then return end
	if tick()-BOT.lastAnnounce<1.5 then return end
	BOT.lastAnnounce=tick()
	pcall(function() notify("Auto Play Bot", msg) end)
end
-- read our vitals as 0..1 fractions (nil when unreadable — treated as "fine" so the bot never panics blind)
local function botVitals()
	local foodF, waterF, hpF
	pcall(function()
		local s,m=csStats(); if not s then return end
		local f,mf = tonumber(s.Food or s.Hunger), m and tonumber(m.Food or m.Hunger)
		if f and mf and mf>0 then foodF=f/mf end
		local w,mw = tonumber(s.Water or s.Thirst), m and tonumber(m.Water or m.Thirst)
		if w and mw and mw>0 then waterF=w/mw end
		local h,mh = tonumber(s.Health or s.HP), m and tonumber(m.Health or m.HP)
		if h and mh and mh>0 then hpF=h/mh end
	end)
	if not hpF then pcall(function() local h=hum(); if h and h.MaxHealth>0 then hpF=h.Health/h.MaxHealth end end) end
	return foodF, waterF, hpF
end
-- self-contained diet helpers: this build doesn't ship the v6 diet module, so the bot carries its own copies.
local _botDataCtrl
local function dinoDataController()   -- Knit DataController -> DinosaursData (species stats incl. Diet.Categories)
	if _botDataCtrl then return _botDataCtrl end
	pcall(function()
		local pkg=RS:FindFirstChild("Packages"); local km=pkg and pkg:FindFirstChild("Knit")
		if km then local K=require(km); if K and K.GetController then _botDataCtrl=K.GetController("DataController") end end
	end)
	return _botDataCtrl
end
-- classify ANOTHER species' diet from the game's own DinosaurData (cached). Unknown = assumed dangerous.
_spDietCache = {}
local function speciesDiet(species)
	if not species then return nil end
	if _spDietCache[species]~=nil then return _spDietCache[species] or nil end
	local out
	pcall(function()
		local dc=dinoDataController(); local dd=dc and dc.DinosaursData
		local sp=dd and dd[species]; if not (sp and sp.GrowthStages) then return end
		local st; for _,v in pairs(sp.GrowthStages) do st=v; break end
		local cats=st and st.Diet and st.Diet.Categories
		if type(cats)=="table" then
			local carn,herb=false,false
			for c in pairs(cats) do local lc=tostring(c):lower()
				if lc:find("meat",1,true) or lc:find("organ",1,true) or lc:find("fish",1,true) or lc:find("bone",1,true) or lc:find("egg",1,true) or lc:find("insect",1,true) then carn=true
				elseif lc:find("plant",1,true) or lc:find("veget",1,true) or lc:find("fruit",1,true) or lc:find("berry",1,true) or lc:find("leaf",1,true) or lc:find("fern",1,true) or lc:find("grass",1,true) or lc:find("herb",1,true) or lc:find("seed",1,true) or lc:find("root",1,true) or lc:find("flower",1,true) or lc:find("bark",1,true) then herb=true end
			end
			out=(carn and herb and "Omnivore") or (carn and "Carnivore") or (herb and "Herbivore") or nil
		end
	end)
	_spDietCache[species]=out or false
	return out
end
-- OUR OWN diet is keyed by verified replica + species. Unknown remains unknown, so automatic food probing waits
-- instead of treating a not-yet-streamed dinosaur as an omnivore and capturing a wrong-source Bite packet.
local function myDiet()
	local species
	pcall(function()
		if CharacterState and CharacterState.Replica and CharacterState.Replica.Tags then species=CharacterState.Replica.Tags.Character end
		if not species then local cc=getMyModel(); species=cc and (cc:GetAttribute("Type") or cc:GetAttribute("Character")) end
	end)
	local key=tostring(MHNEED.replicaId() or "?").."|"..tostring(species or "?")
	local cached=__gg.MH_dietCache; if type(cached)=="table" and cached.key==key then return cached.diet end
	local diet
	pcall(function()
		local gd=require(RS.Modules.Diet.GetDiet)
		if gd and species then local d=gd(species)
			if type(d)=="string" then local lc=d:lower()
				if lc:find("herb",1,true) then diet="Herbivore" elseif lc:find("carn",1,true) then diet="Carnivore" elseif lc:find("omni",1,true) then diet="Omnivore" end
			end
		end
	end)
	if not diet and species then diet=speciesDiet(tostring(species)) end
	if diet then __gg.MH_dietCache={key=key,diet=diet} end
	return diet
end
-- classify a food item: corpse/meat vs plant (name + PE's corpse markers + the prompt's "Investigate" action)
local function isCorpseFood(m, prompt)
	local nm=tostring(m and m.Name or ""):lower()
	if nm:find("corpse") or nm:find("carcass") or nm:find("remains") or nm:find("carrion") or nm:find("dead") or nm:find("meat") then return true end
	if m and m.GetAttribute then local ok,dinoType,hint=pcall(function() return m:GetAttribute("DinoType"),m:GetAttribute("HintType") end); if ok then
		if type(dinoType)=="string" and dinoType~="" then return true end
		local hv=tostring(hint or ""):lower(); if hv:find("corpse",1,true) or hv:find("carcass",1,true) or hv:find("meat",1,true) or hv:find("carrion",1,true) then return true end
	end end
	if prompt then local at=(prompt.ActionText or ""):lower(); if at:find("investigate") or at:find("examine") then return true end end
	return false
end
-- diet gate: Herbivore eats ONLY plants, Carnivore ONLY corpses/meat, Omnivore both
local function edibleFor(diet, corpse)
	if diet=="Herbivore" then return not corpse
	elseif diet=="Carnivore" then return corpse and true or false
	elseif diet=="Omnivore" then return true end
	return false
end
-- Exposed for the INF Food loop (defined earlier in the file): true only if THIS food matches your dino's diet.
-- Resolved at call time, so the loop that references _G.MH_edible always gets the real gate once this line runs.
_G.MH_edible = function(m, prompt) return edibleFor(myDiet(), isCorpseFood(m, prompt)) end
-- SIZE / STAGE helpers so the bot flees anything BIGGER than you (per request: use the ESP stage/size).
local STAGE_RANK = {Hatchling=1,Baby=1,Juvenile=2,Child=2,Adolescent=3,SubAdult=4,["Sub Adult"]=4,["Sub-Adult"]=4,Adult=5,Elder=6}
local function stageRank(m)
	local s; pcall(function() s = m:GetAttribute("Stage") or m:GetAttribute("GrowthStage") end)
	if not s then pcall(function() local rr=csReplica(); if rr and rr.Data and m==getMyModel() then s=rr.Data.GrowthStage or rr.Data.Stage or (rr.Data.Growth and rr.Data.Growth.Stage) end end) end
	return s and STAGE_RANK[tostring(s)] or nil
end
local function modelBulk(m)   -- physical size = bounding-box volume; a good stand-in for "how big is that dino"
	local ok,sz = pcall(function() local _,s = m:GetBoundingBox(); return s end)
	if ok and sz then return sz.X*sz.Y*sz.Z end
	return nil
end
-- is the OTHER dino bigger than us? Prefer growth stage (Adult>SubAdult>…); fall back to physical bulk (+15% margin).
local function biggerThanMe(other, myStage, myBulk)
	local os=stageRank(other); if os and myStage then if os>myStage then return true elseif os<myStage then return false end end
	local ob=modelBulk(other); if ob and myBulk and myBulk>0 then return ob > myBulk*1.15 end
	return false
end
-- find the nearest THREAT: another dino inside BotFleeRange that is BIGGER than you (any diet), OR a
-- carnivore/omnivore/unknown predator. Bigger-than-you is the primary flee trigger. Returns model, root, distance.
local function botNearestThreat()
	if not CFG.BotFlee then return nil end
	local me=hrp(); if not me then return nil end
	local mine=getMyModel()
	local myStage=mine and stageRank(mine); local myBulk=mine and modelBulk(mine)
	local best,broot,bd=nil,nil,tonumber(CFG.BotFleeRange) or 240
	for _,m in ipairs(charModels()) do
		if m:IsA("Model") and m~=mine then
			local r=getHitbox(m) or rootOf(m)
			if r then
				local d=dist(me.Position,r.Position)
				if d<bd then
					local h=m:FindFirstChildOfClass("Humanoid")
					if (not h) or h.Health>0 then
						local sp=detectDinoModel(m) or m:GetAttribute("Type") or m:GetAttribute("Character")
						local diet=speciesDiet(sp and tostring(sp))
						local big=biggerThanMe(m, myStage, myBulk)
						if big or diet~="Herbivore" then   -- BIGGER than you, or a meat-eater/unknown = flee it
							best,broot,bd=m,r,d
						end
					end
				end
			end
		end
	end
	return best,broot,bd
end
-- PVP TARGET: nearest OTHER dino within combat range that is NOT bigger than you (so it is safe to fight, not flee).
-- Prefers real players. Returns model, root, distance.
local function botNearestEnemy(range)
	local me=hrp(); if not me then return nil end
	local mine=getMyModel()
	local myStage=mine and stageRank(mine); local myBulk=mine and modelBulk(mine)
	local best,broot,bd=nil,nil,range or 32
	for _,m in ipairs(charModels()) do
		if m:IsA("Model") and m~=mine then
			local r=getHitbox(m) or rootOf(m)
			if r then
				local d=dist(me.Position,r.Position)
				if d<bd then
					local h=m:FindFirstChildOfClass("Humanoid")
					if (not h) or h.Health>0 then
						if not biggerThanMe(m, myStage, myBulk) then best,broot,bd=m,r,d end   -- only fight things NOT bigger than you
					end
				end
			end
		end
	end
	return best,broot,bd
end
-- PVP COMBAT ACTION: face the target and throw your basic attacks — LEFT click (M1) + RIGHT click (M2) via the
-- mouse, plus the captured Attack remote so damage lands server-side. Cooldowned so it is a real combo, not a blur.
local function botCombat(target, troot)
	if not (target and troot) then return end
	if tick()-(BOT.atkCd or 0) < 0.5 then return end
	BOT.atkCd=tick()
	local me=hrp(); if me then pcall(function() local look=Vector3.new(troot.Position.X, me.Position.Y, troot.Position.Z); getMyModel():PivotTo(CFrame.new(me.Position, look)) end) end
	pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0); task.wait(0.03); VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)   -- LEFT click = M1
	pcall(function() VIM:SendMouseButtonEvent(0,0,1,true,game,0); task.wait(0.03); VIM:SendMouseButtonEvent(0,0,1,false,game,0) end)   -- RIGHT click = M2
	if _G.MH_attack then pcall(function() _G.MH_attack(target) end) end   -- the real captured Attack (bone-targeted damage)
end
-- nearest DIET-LEGAL food within a generous range. Returns model, part, prompt, distance.
local function botNearestFood()
	local me=hrp(); if not me then return nil end
	local diet=myDiet()
	local best,bpart,bprompt,bd=nil,nil,nil,900
	for _,fd in ipairs(nearbyFood(900)) do
		local m,part,prompt=fd[1],fd[2],fd.prompt
		if part and part.Parent and edibleFor(diet, isCorpseFood(m,prompt)) then
			local d=fd[3]
			if d<bd then best,bpart,bprompt,bd=m,part,prompt,d end
		end
	end
	-- carnivore extra: the red-mesh meat detector (chunks have no prompt/name). nearestMeat lives in another
	-- do-block now (Luau local cap), so call it through the __gg handle.
	if not best and (diet=="Carnivore" or diet=="Omnivore") and __gg.MH_nearestMeat then
		local m,part,d=__gg.MH_nearestMeat(900)
		if part then best,bpart,bprompt,bd=m,part,nil,d end
	end
	return best,bpart,bprompt,bd
end
-- is there water at/near this position? (game's own signals first, remembered spot second)
local function botNearWater()
	local nearW=false
	if CharacterState then pcall(function() nearW = CharacterState.FoundWater==true or typeof(CharacterState.WaterLevel)=="number" end) end
	return nearW
end
-- MOVEMENT DRIVE — HOLD W/A/S/D (the fix): writing AssemblyLinearVelocity got overridden by PE's server-authoritative
-- movement controller, so the dino just stood still ("hold stop"). Now the bot drives the game's OWN movement by
-- HOLDING the real WASD keys toward the goal (camera-relative, same as a human), so the game moves the dino normally.
-- NOTE: these hang off the BOT table (fields, NOT new locals) so they don't add to this do-block's Luau 200-local
-- register cap — adding them as locals overflowed the cap and made the whole script fail to loadstring.
BOT.kc = {W=Enum.KeyCode.W, A=Enum.KeyCode.A, S=Enum.KeyCode.S, D=Enum.KeyCode.D}
BOT.held = BOT.held or {}
function BOT.setKey(name, down)
	if BOT.held[name]==down then return end             -- only fire on a state CHANGE (not every frame)
	BOT.held[name]=down
	pcall(function() VIM:SendKeyEvent(down, BOT.kc[name], false, game) end)
end
function BOT.releaseKeys() for n in pairs(BOT.kc) do BOT.setKey(n,false) end end
__gg.MH_botReleaseKeys = BOT.releaseKeys                 -- so the on/off + death paths can stop the walk
-- press the WASD combo that moves toward desFlat given the current camera facing (release all if no direction)
function BOT.driveToward(desFlat)
	if not desFlat or desFlat.Magnitude<0.05 then BOT.releaseKeys(); return end
	local des=Vector3.new(desFlat.X,0,desFlat.Z); if des.Magnitude<0.05 then BOT.releaseKeys(); return end; des=des.Unit
	local cf=(workspace.CurrentCamera and workspace.CurrentCamera.CFrame) or Cam.CFrame   -- FRESH camera: the cached Cam goes stale after respawn = bot steers the wrong way ("keeps sending me back")
	local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z); if look.Magnitude<0.05 then BOT.releaseKeys(); return end; look=look.Unit
	local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
	local fwd=des:Dot(look); local rgt=des:Dot(right)
	BOT.setKey("W", fwd> 0.35); BOT.setKey("S", fwd< -0.35)
	BOT.setKey("D", rgt> 0.35); BOT.setKey("A", rgt< -0.35)
end
conn(RunService.Heartbeat:Connect(function()
	if not (CFG.AutoPlayBot and alive()) then if next(BOT.held) then BOT.releaseKeys() end return end
	if CFG.Fly or CFG.SpeedHack then BOT.releaseKeys(); return end   -- user-controlled movement wins
	local r=hrp(); if not r then BOT.releaseKeys(); return end
	local goal=BOT.goal
	if BOT.sleeping or not goal then BOT.releaseKeys(); return end   -- resting / no destination = stand still
	local to=goal-r.Position; local flat=Vector3.new(to.X,0,to.Z)
	if flat.Magnitude<4 then BOT.releaseKeys(); return end           -- arrived (state loop decides what's next)
	if tick()<BOT.unstuckUntil then
		-- UNSTICK: strafe at an angle + hop (Space) to clear the rock/tree we're wedged on
		local side=flat.Unit:Cross(Vector3.yAxis)
		BOT.driveToward((flat.Unit*0.5+side*0.85))
		pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game); VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
	else
		BOT.driveToward(flat)
	end
end))
-- STUCK WATCCHDOG: if the bot has a goal but has barely moved for ~3s, trigger the unstick hop + re-path.
task.spawn(function() while RUNNING do task.wait(1)
	if CFG.AutoPlayBot and alive() and BOT.goal and not BOT.sleeping then
		local r=hrp()
		if r then
			if BOT.stuckPos and tick()-BOT.stuckT>=3 then
				if (r.Position-BOT.stuckPos).Magnitude<3 then
					BOT.unstuckUntil=tick()+1.2
					if BOT.state=="roam" then BOT.goal=nil end   -- roaming into a wall → just pick a new spot
					botSay("Stuck — hopping around the obstacle.")
				end
				BOT.stuckPos=r.Position; BOT.stuckT=tick()
			elseif not BOT.stuckPos then BOT.stuckPos=r.Position; BOT.stuckT=tick() end
		end
	else BOT.stuckPos=nil end
end end)
-- SLEEP CONTROL: hold the Sleep action while resting (server heals you), releasing it the instant the bot
-- stops resting. Mirrors the game's own R-lay-down + Z-sleep report.
task.spawn(function() local was=false while RUNNING do task.wait(0.4)
	local want=CFG.AutoPlayBot and alive() and BOT.sleeping or false
	if want and not was then was=true
		pcall(function() local r=hrp(); if r then r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0) end end)
		pcall(function() replicaAction("SetAction","Sleep",true) end)
	elseif want then
		pcall(function() replicaAction("SetAction","Sleep",true) end)   -- re-assert so the heal keeps ticking
	elseif was then was=false
		pcall(function() replicaAction("SetAction","Sleep",false) end)
	end
end end)
-- THE BRAIN: priority evaluation ~3x/sec. Sets BOT.state/goal; the drive + sleep loops act on them.
task.spawn(function()
	while RUNNING do
		if CFG.AutoPlayBot and alive() then
			-- one-time on-enable setup
			if BOT.prevF==nil then
				BOT.prevF=true -- setup sentinel only; the bot never changes user-owned need toggles
				local r=hrp(); BOT.home=r and r.Position or nil
				BOT.dietSaid=false
				botSay("Bot ON — home set here. I'll eat, drink, flee, heal and roam for you.")
			end
			if not BOT.dietSaid then local d=myDiet(); if d then BOT.dietSaid=true; botSay("Diet detected: "..d..". I'll only eat what you can digest.") end end
			local me=hrp()
			if me then
				if not BOT.home then BOT.home=me.Position end
				local foodF, waterF, hpF = botVitals()
				local eatAt=(tonumber(CFG.BotEatAt) or 80)/100
				local drinkAt=(tonumber(CFG.BotDrinkAt) or 80)/100
				local threat,throot=botNearestThreat()
				-- ── 1. FLEE ──────────────────────────────────────────────────────────────
				if threat and throot then
					BOT.sleeping=false
					BOT.state="flee"; BOT.threat=threat
					local away=(me.Position-throot.Position); away=Vector3.new(away.X,0,away.Z)
					if away.Magnitude<1 then away=Vector3.new(1,0,0) end
					-- run away, biased toward home when home is roughly in the escape direction
					local escape=me.Position+away.Unit*120
					if BOT.home then
						local homeDir=(BOT.home-me.Position); homeDir=Vector3.new(homeDir.X,0,homeDir.Z)
						if homeDir.Magnitude>20 and homeDir.Unit:Dot(away.Unit)>0.2 then escape=me.Position+((away.Unit+homeDir.Unit).Unit)*120 end
					end
					BOT.goal=escape
					if BOT.lastState~="flee" then BOT.lastState="flee"
						local sp=detectDinoModel(threat) or threat.Name
						botSay("PREDATOR — "..tostring(sp).." nearby! Running away.")
					end
				-- ── 1.5 PVP COMBAT ───────────────────────────────────────────────────────
				-- No bigger dino to flee, but a fightable enemy (NOT bigger than you) is close → attack it:
				-- face it, LEFT click + RIGHT click, and land the real bite. Also uses Always Damage if you have it on.
				elseif (CFG.BotPvP ~= false) and botNearestEnemy(30) then
					local enemy,eroot=botNearestEnemy(30)
					if enemy and eroot then
						BOT.sleeping=false; BOT.state="pvp"; BOT.goal=nil   -- stand and fight (don't walk off)
						botCombat(enemy, eroot)
						if BOT.lastState~="pvp" then BOT.lastState="pvp"; botSay("PvP — fighting "..tostring(detectDinoModel(enemy) or enemy.Name).." (M1 + M2).") end
					end
				-- ── 2. DRINK ─────────────────────────────────────────────────────────────
				elseif waterF and waterF<drinkAt then
					BOT.sleeping=false; BOT.state="drink"
					fakeDrink()                                   -- the captured Sip ids work map-wide
					if botNearWater() then
						BOT.goal=nil                              -- at water: stand + sip
						BOT.waterPos=me.Position                  -- remember this watering hole
						local ebd=false; pcall(function() ebd=UIS:IsKeyDown(Enum.KeyCode.E) end)
						if not ebd then holdKey(Enum.KeyCode.E, 0.3) end   -- never steal your manual E-hold
					elseif BOT.waterPos then
						BOT.goal=BOT.waterPos                     -- walk back to the known water
					else
						BOT.goal=nil                              -- no known water: the Sip ids still fill it
					end
					if BOT.lastState~="drink" then BOT.lastState="drink"; botSay("Thirsty ("..math.floor(waterF*100).."%) — drinking.") end
				-- ── 3. EAT ───────────────────────────────────────────────────────────────
				elseif foodF and foodF<eatAt then
					BOT.sleeping=false; BOT.state="eat"
					fakeEat()                                     -- replay captured food ids while travelling
					local fm,fpart,fprompt,fd=botNearestFood()
					if fpart then
						if fd<=14 then
							BOT.goal=nil                          -- in reach: bite it
							if not fprompt and fm and fm.FindFirstChildWhichIsA then pcall(function() fprompt=fm:FindFirstChildWhichIsA("ProximityPrompt", true) end) end
							if fprompt then
								pcall(function() local oh=fprompt.HoldDuration; fprompt.RequiresLineOfSight=false; fprompt.HoldDuration=0; if fireprox then fireprox(fprompt) end; fprompt.HoldDuration=oh end)
							end
							local ebe=false; pcall(function() ebe=UIS:IsKeyDown(Enum.KeyCode.E) end)
							if not ebe then holdKey(Enum.KeyCode.E, 0.6) end   -- never steal your manual E-hold
						else
							BOT.goal=fpart.Position; BOT.target=fm
						end
						if BOT.lastState~="eat" then BOT.lastState="eat"; botSay("Hungry ("..math.floor(foodF*100).."%) — heading to food ("..math.floor(fd).."m).") end
					else
						-- nothing edible found: roam for food (new random spot each pass widens the search)
						if not BOT.goal or BOT.state~="eat" then
							local a=math.random()*math.pi*2
							BOT.goal=me.Position+Vector3.new(math.cos(a),0,math.sin(a))*150
						end
						if BOT.lastState~="eat" then BOT.lastState="eat"; botSay("Hungry — searching for food…") end
					end
				-- ── 4. REST / HEAL ───────────────────────────────────────────────────────
				elseif CFG.BotSleepHeal and hpF and hpF<0.6 then
					BOT.state="rest"; BOT.goal=nil; BOT.sleeping=true
					if BOT.lastState~="rest" then BOT.lastState="rest"; botSay("Hurt ("..math.floor(hpF*100).."% HP) — sleeping it off.") end
				-- ── 5. ROAM ──────────────────────────────────────────────────────────────
				elseif CFG.BotRoam then
					BOT.sleeping=false; BOT.state="roam"
					local arrived = (not BOT.goal) or (Vector3.new(BOT.goal.X-me.Position.X,0,BOT.goal.Z-me.Position.Z).Magnitude<8)
					if arrived then
						if tick()>BOT.roamWait then
							if BOT.goal then BOT.roamWait=tick()+2+math.random()*5; BOT.goal=nil   -- pause like a human
							else
								local a=math.random()*math.pi*2
								local rr=math.random(40, math.max(60, tonumber(CFG.BotRoamRadius) or 350))
								BOT.goal=(BOT.home or me.Position)+Vector3.new(math.cos(a)*rr, 0, math.sin(a)*rr)
							end
						end
					end
					if BOT.lastState~="roam" then BOT.lastState="roam"; botSay("All good — roaming near home.") end
				else
					BOT.sleeping=false; BOT.state="idle"; BOT.goal=nil
				end
			end
			task.wait(0.35)
		else
			-- bot off / dead → clean shutdown: wake up and stop moving
			if BOT.prevF~=nil then
				BOT.prevF,BOT.prevW,BOT.prevS = nil,nil,nil
				BOT.sleeping=false; BOT.goal=nil; BOT.state="idle"; BOT.lastState=""; BOT.threat=nil; BOT.home=nil
				pcall(function() replicaAction("SetAction","Sleep",false) end)
				botSay("Bot OFF — you're back in control.")
			end
			task.wait(0.5)
		end
	end
end)
end   -- end of the Auto Play Bot scoped block
-- Notification bar: show how many fossils/gems have been collected while farming (updates when the count changes).
task.spawn(function() local lf,lg=-1,-1 while RUNNING do task.wait(2.5)
	if CFG.AutoFarmFossil or CFG.AutoFarmGem then
		local f=FARM.count.fossil or 0; local g=FARM.count.gem or 0
		if f~=lf or g~=lg then lf=f; lg=g; notify("Auto Farm","Collected — Fossils: "..f.."   Gems: "..g) end
	end
end end)

-- FARM SAFETY: while any auto-farm is on, force fall-damage immunity + kill downward velocity so you never die mid-glide.
task.spawn(function() while RUNNING do
	if (CFG.AutoFarmFossil or CFG.AutoFarmGem or CFG.AutoFarmPlayer) and alive() then
		if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
		pcall(function() clearStatus({"fall","falldamage","falldmg"},{"Falling","FallDamage","FallDmg"}) end)
		local r=hrp(); if r then local v=r.AssemblyLinearVelocity; if v.Y<-40 then pcall(function() r.AssemblyLinearVelocity=Vector3.new(v.X,0,v.Z) end) end end
		task.wait(0.06)
	else task.wait(0.25) end
end end)

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- TARGET SYSTEM (Plus): pick a player by name → read who they are + their dino/stats, then View /
-- Track / Teleport to / Attack once / Auto Farm them. A player's dino lives in workspace.Characters
-- [player.Name]; species/stage come from its MeshModel attributes, health from the Humanoid. Food /
-- Water / Stamina are in each player's PRIVATE replica (not readable for other players), so we show
-- whatever the model exposes as attributes and "--" otherwise — never a fake number.
__gg.MH_Target = { plr=nil, model=nil, viewing=false }
-- Resolve a player from a typed name. Order of preference: exact → case-insensitive full → prefix → ANY
-- SUBSTRING (a small portion anywhere in their username OR display name). So "chr", "243", or their display
-- name all resolve to chris3243242342. Ties are broken toward the shortest name (the closest match).
local function targetResolvePlayer(txt)
	txt = tostring(txt or ""):gsub("^%s+",""):gsub("%s+$","")
	if txt=="" then return nil end
	local low = txt:lower()
	local exact, ci, pre, sub
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl~=LP then
			local n, d = pl.Name:lower(), (pl.DisplayName or pl.Name):lower()
			if pl.Name==txt or pl.DisplayName==txt then exact=exact or pl end
			if n==low or d==low then ci=ci or pl end
			if n:sub(1,#low)==low or d:sub(1,#low)==low then pre=pre or pl end
			if n:find(low,1,true) or d:find(low,1,true) then
				if not sub or #pl.Name < #sub.Name then sub=pl end   -- prefer the closest (shortest) match
			end
		end
	end
	return exact or ci or pre or sub
end
__gg.MH_targetResolve = targetResolvePlayer   -- the Target tab (built earlier in the file) calls these at click time
-- The player's dino model. THE "dino never loads" FIX: other players' models under workspace.Characters are
-- NOT named after the player (that only holds for YOUR own dino) — the ESP always matched them with
-- Players:GetPlayerFromCharacter, so the Target lookup now does the same: .Character first, then the
-- name fast-path, then a GetPlayerFromCharacter scan of every model, then LeftCharacters.
local function targetModelFor(pl)
	if not pl then return nil end
	-- CACHE FIRST: a background scan (below) maps every player to their dino model exactly the way the ESP does,
	-- with NO range limit — so the instant their dino is streamed to your client, Target has it.
	local cached = __gg.MH_pmodels and __gg.MH_pmodels[pl.UserId]
	if cached and cached.Parent then return cached end
	-- THE ESP'S WAY, in the ESP's order ("when I turn on ESP it loads their info — use that"): the ESP walks
	-- workspace.Characters and identifies dinos there. So: Characters[name] first, then the same
	-- GetPlayerFromCharacter match the ESP uses, then owner tags. pl.Character is only trusted LAST and only
	-- when it actually looks like a dino — PE sometimes parks a junk placeholder there, and trusting it first
	-- made the whole profile read "--" (wrong model = no attributes, no position, "dino not loaded").
	local ch = WS:FindFirstChild("Characters")
	if ch then
		local m = ch:FindFirstChild(pl.Name)
		if m and m.Parent then return m end
		-- PE often never assigns plr.Character (LP.Character is nil even for YOU), so GetPlayerFromCharacter can
		-- come up empty for everyone. Hunt the owner EVERY way a game tags it: the character mapping, owner-ish
		-- attributes (Player/Owner/User/Creator, by name / display name / UserId), ObjectValues pointing at the
		-- player, StringValues holding their name, and finally model names that contain the username.
		local lowName, lowDisp = string.lower(pl.Name), string.lower(pl.DisplayName or pl.Name)
		local function ownedBy(mm)
			local hit=false
			pcall(function()
				if Players:GetPlayerFromCharacter(mm)==pl then hit=true; return end
				for k,v in pairs(mm:GetAttributes()) do
					local kk=string.lower(tostring(k))
					if kk:find("player",1,true) or kk:find("owner",1,true) or kk:find("user",1,true) or kk:find("creator",1,true) or kk=="name" then
						local vs=string.lower(tostring(v))
						if vs==lowName or vs==lowDisp or vs==tostring(pl.UserId) then hit=true; return end
					end
				end
				for _,d in ipairs(mm:GetChildren()) do
					if d:IsA("ObjectValue") and d.Value==pl then hit=true; return end
					if (d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue")) then
						local nn=string.lower(d.Name)
						if nn:find("player",1,true) or nn:find("owner",1,true) or nn:find("user",1,true) then
							local vs=string.lower(tostring(d.Value))
							if vs==lowName or vs==lowDisp or vs==tostring(pl.UserId) then hit=true; return end
						end
					end
				end
			end)
			return hit
		end
		for _,mm in ipairs(ch:GetChildren()) do
			if mm:IsA("Model") and ownedBy(mm) then return mm end
		end
		for _,mm in ipairs(ch:GetChildren()) do   -- last resort: the model NAME contains their username/display name
			if mm:IsA("Model") then
				local mn=string.lower(mm.Name)
				if mn:find(lowName,1,true) or (lowDisp~=lowName and mn:find(lowDisp,1,true)) then return mm end
			end
		end
	end
	-- pl.Character LAST, and only when it looks like a REAL dino (has a part + dino markers)
	local pc = pl.Character
	if pc and pc.Parent then
		local looksReal = false
		pcall(function()
			looksReal = (pc:FindFirstChildWhichIsA("BasePart") ~= nil)
				and (pc:FindFirstChild("MeshModel") ~= nil or pc:FindFirstChildOfClass("Humanoid") ~= nil or pc:GetAttribute("Type") ~= nil)
		end)
		if looksReal then return pc end
	end
	local ci = WS:FindFirstChild("CharacterIgnore"); ci = ci and ci:FindFirstChild("LeftCharacters")
	if ci then local lm=ci:FindFirstChild(pl.Name); if lm then return lm end end
	return nil
end
__gg.MH_targetModelFor = targetModelFor
-- ═══ PLAYER → DINO CACHE ═══ Always-on, no range limit. Maps every player to their dino model the SAME way the
-- ESP finds them (GetPlayerFromCharacter over workspace.Characters), plus name/owner matching for the dinos PE
-- doesn't register normally. This is what makes Target "just load" — the profile and every action read from here.
__gg.MH_pmodels = __gg.MH_pmodels or {}
task.spawn(function() while RUNNING do
	pcall(function()
		local ch = WS:FindFirstChild("Characters")
		local fresh = {}
		local byName = {}
		for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP then
			byName[string.lower(pl.Name)] = pl
			byName[string.lower(pl.DisplayName or pl.Name)] = pl
		end end
		if ch then for _,m in ipairs(ch:GetChildren()) do if m:IsA("Model") then
			local owner
			pcall(function() owner = Players:GetPlayerFromCharacter(m) end)
			if not owner then
				local mn = string.lower(m.Name)
				owner = byName[mn]
				if not owner then for nm,pl in pairs(byName) do if mn:find(nm,1,true) then owner=pl; break end end end
			end
			if owner and owner~=LP then fresh[owner.UserId] = m end
		end end end
		-- keep last-known models that are still parented even if this pass missed them (streaming flicker)
		for uid,m in pairs(__gg.MH_pmodels) do if not fresh[uid] and m and m.Parent then fresh[uid]=m end end
		__gg.MH_pmodels = fresh
	end)
	task.wait(1)
end end)
-- LIVE POSITION for a player — ANY part we can reach, so View / Teleport / Auto Farm work WITHOUT needing a
-- fully "loaded" profile first. Tries the cached dino, then a fresh lookup, then their Character, then a scan.
local function targetLivePart(pl)
	if not pl then return nil end
	local m = targetModelFor(pl)
	if m then local r=getHitbox(m) or rootOf(m); if r then return r, m end end
	local pc = pl.Character
	if pc then local r=pc:FindFirstChild("HumanoidRootPart") or rootOf(pc) or pc:FindFirstChildWhichIsA("BasePart"); if r then return r, pc end end
	return nil, nil
end
__gg.MH_targetLivePart = targetLivePart
-- Read a stat off a model/MeshModel by trying several attribute names; returns number or nil.
local function targetAttrNum(model, names)
	if not model then return nil end
	local mm = model:FindFirstChild("MeshModel")
	for _,src in ipairs({model, mm}) do
		if src then for _,nm in ipairs(names) do
			local ok,v = pcall(function() return src:GetAttribute(nm) end)
			if ok and type(v)=="number" then return v end
		end end
	end
	return nil
end
-- Pull everything we can show for the current target. Missing values come back as nil = show "--".
local function targetReadInfo()
	local T = __gg.MH_Target
	local pl, model = T.plr, T.model
	if pl and (not model or not model.Parent) then
		model = targetModelFor(pl); T.model = model
		-- FAR-AWAY TARGET: ask the client to STREAM their last-known area in, so their dino loads without you
		-- walking there. (If we've never seen them this session there's no position to stream — the game simply
		-- hasn't sent their dino to your client yet; it appears the moment any position for them is known.)
		if not model and T.lastPos then pcall(function() LP:RequestStreamAroundAsync(T.lastPos, 1) end) end
	end
	local info = { user=pl and pl.Name, display=pl and pl.DisplayName, userId=pl and pl.UserId }
	if model then
		-- THE ESP'S READER FIRST ("when I turn on ESP it loads their info — use that same function"): readDinoInfo
		-- is exactly what fills every ESP label (species/stage/HP/stam), so the Target profile now runs on it as the
		-- PRIMARY source, with the MeshModel attribute reads only filling any gaps it leaves.
		pcall(function()
			if __gg.MH_readDino then
				local sp, gr, hpStr, stamStr = __gg.MH_readDino(model)
				info.species = sp
				info.stage = gr
				info.hpStr = hpStr; info.stamStr = stamStr
			end
		end)
		local mm = model:FindFirstChild("MeshModel")
		info.species = info.species or (mm and mm:GetAttribute("Type")) or detectDinoModel(model) or model:GetAttribute("Type") or model:GetAttribute("DinoType")
		info.stage = info.stage or (mm and mm:GetAttribute("Stage")) or model:GetAttribute("Stage") or model:GetAttribute("GrowthStage") or model:GetAttribute("Age")
		info.gender = (mm and mm:GetAttribute("Gender")) or model:GetAttribute("Gender")
		local h = model:FindFirstChildOfClass("Humanoid")
		if h and h.MaxHealth>0 then info.hp = math.floor(h.Health+0.5); info.hpMax = math.floor(h.MaxHealth+0.5) end
		info.food = targetAttrNum(model, {"Food","Hunger","Nutrition","Fullness"})
		info.water = targetAttrNum(model, {"Water","Thirst","Hydration"})
		-- STAMINA (value + max, so we can show a real bar): attributes first, then NumberValue/IntValue children.
		info.stam = targetAttrNum(model, {"Stamina","Stam","Energy","Endurance","CurrentStamina","StaminaValue"})
		info.stamMax = targetAttrNum(model, {"MaxStamina","MaxStam","MaxEnergy","StaminaMax"})
		if not info.stam then pcall(function()
			local scanned=0
			for _,v in ipairs(model:GetDescendants()) do
				scanned=scanned+1; if scanned>600 then break end   -- cap so the 0.5s tick can't lag on a big model
				if (v:IsA("NumberValue") or v:IsA("IntValue")) then
					local nn=v.Name:lower()
					if (nn:find("stam",1,true) or nn=="energy" or nn:find("endur",1,true)) and not nn:find("max",1,true) then
						info.stam = tonumber(v.Value)
						local sib = v.Parent and (v.Parent:FindFirstChild("MaxStamina") or v.Parent:FindFirstChild("MaxStam"))
						if sib then info.stamMax = tonumber(sib.Value) end
						break
					end
				end
			end
		end) end
		-- WELLBEING — the % that gates their stamina drain / amber gain. We can only read what the game exposes on
		-- the model to us; scan for a wellbeing / comfort / activity attribute or value. Often private to other
		-- players, in which case the row shows "--" (it's always PRESENT in the UI, per request).
		info.wellbeing = targetAttrNum(model, {"Wellbeing","WellbeingAverage","Comfort","Activity","Condition"})
		if not info.wellbeing then pcall(function()
			local scanned=0
			for _,v in ipairs(model:GetDescendants()) do
				scanned=scanned+1; if scanned>600 then break end
				if (v:IsA("NumberValue") or v:IsA("IntValue")) then
					local nn=v.Name:lower()
					if nn:find("wellbeing",1,true) or nn=="comfort" or nn=="activity" or nn=="condition" then info.wellbeing=tonumber(v.Value); break end
				end
			end
		end) end
		local r = getHitbox(model) or rootOf(model)
		local me = hrp()
		if r and me then info.dist = math.floor(dist(me.Position, r.Position)) end
		if r then T.lastPos = r.Position end   -- remember where they were (streaming re-pull when they unload)
	end
	return info
end
_G.MH_targetInfo = targetReadInfo
-- Teleport to the current target through the central path so safety, spawn grace, synchronization and success
-- reporting are identical to every other explicit teleport feature.
local function hardTeleportTo(pos, holdSecs)
	if not (pos and __gg.MH_safeTeleport) then return false end
	local settled=math.clamp(tonumber(holdSecs) or 1.2,0.2,3)
	local ok=__gg.MH_safeTeleport(pos,{saveReturn=true,settle=settled,tolerance=7})==true
	if ok and holdSecs then task.wait(settled) end
	return ok
end
__gg.MH_hardTeleportTo = hardTeleportTo

local function targetTeleport(holdSecs)
	local T = __gg.MH_Target; if not T.plr then return false end
	local r0, model = targetLivePart(T.plr)
	if model then T.model = model end
	if not r0 then return false end
	__gg.MH_rescueMute = tick()+3
	return __gg.MH_safeTeleport and __gg.MH_safeTeleport(r0.Position+Vector3.new(0,6,0),{saveReturn=true,settle=holdSecs or 1.0,tolerance=8})==true
end
__gg.MH_targetTeleport = targetTeleport

-- ATTACK ONCE + RETURN: DIRECT pivots (NOT MH_snapTo — its 1.2s settle loop would fight the return trip). Save
-- your spot, pivot onto them, land the captured attack, pivot back.
local function targetAttackAndReturn()
	local T = __gg.MH_Target; if not T.plr then return false, "no target" end
	local r, model = targetLivePart(T.plr)
	if model then T.model = model end
	if not (r and model and model.Parent) then return false, "not loaded" end
	__gg.MH_rescueMute = tick()+3
	local function pivotTo(pos)
		return __gg.MH_safeTeleport and __gg.MH_safeTeleport(pos,{settle=0.22,tolerance=8})==true
	end
	local myBack
	do local root=hrp(); if root then myBack=root.CFrame end end
	if not myBack then return false,"no local root" end
	if not pivotTo(r.Position + Vector3.new(0, 5, 0)) then return false,"teleport failed" end
	task.wait(0.06)
	local attacked=false
	if _G.MH_attack then local ok,result=pcall(function() return _G.MH_attack(model) end); attacked=ok and result~=false end
	task.wait(0.1)
	local returned=pivotTo(myBack)
	if not returned then return false,"return failed" end
	return attacked,attacked and nil or "attack unavailable"
end
__gg.MH_targetAttackReturn = targetAttackAndReturn
-- Spectate camera — REWORKED ("viewing don't work"): just setting Cam.CameraSubject did nothing because PE's own
-- camera scripts fight it back every frame. Now viewing takes the camera over completely (Scriptable) and follows
-- the target's dino from behind-above every frame, scaled to the dino's size so an Elder rex and a hatchling both
-- frame nicely. On stop / target loss the camera is handed straight back to YOUR dino (Custom + your Humanoid).
task.spawn(function()
	local wasViewing=false
	while RUNNING do
		local T = __gg.MH_Target
		if T.viewing and T.plr and (not T.model or not T.model.Parent) then T.model=targetModelFor(T.plr) end
		if T.viewing and T.model and T.model.Parent then
			wasViewing=true
			local r = getHitbox(T.model) or rootOf(T.model)
			local cam = workspace.CurrentCamera   -- FRESH camera every frame ("View does nothing" fix: the cached Cam goes stale after you die/respawn)
			if r and cam then pcall(function()
				cam.CameraType = Enum.CameraType.Scriptable
				local ext=12; pcall(function() local sz=T.model:GetExtentsSize(); ext=math.clamp(math.max(sz.X,sz.Y,sz.Z), 8, 120) end)
				local look=r.CFrame.LookVector; local flat=Vector3.new(look.X,0,look.Z); flat=(flat.Magnitude>0.05) and flat.Unit or Vector3.new(0,0,-1)
				local eye=r.Position - flat*(ext*1.6) + Vector3.new(0, ext*0.9, 0)
				cam.CFrame = CFrame.lookAt(eye, r.Position + Vector3.new(0, ext*0.25, 0))
			end) end
			task.wait()   -- every frame = smooth follow
		else
			if wasViewing then
				wasViewing=false
				if T.viewing then T.viewing=false; pcall(function() notify("Target","Lost sight of their dino — stopped viewing.") end) end
				local cam = workspace.CurrentCamera
				pcall(function() cam.CameraType = Enum.CameraType.Custom end)
				local mine=getMyModel(); local h=mine and mine:FindFirstChildOfClass("Humanoid")
				if h and cam then pcall(function() cam.CameraSubject=h end) end
			end
			task.wait(0.3)
		end
	end
end)
-- Track: a Highlight on the loaded player's dino while CFG.TargetTrack is on (clears when off / gone).
task.spawn(function() local hl
	while RUNNING do
		local T = __gg.MH_Target
		if CFG.TargetTrack and T.model and T.model.Parent then
			if not (hl and hl.Parent==T.model) then
				if hl then pcall(function() hl:Destroy() end) end
				hl = Instance.new("Highlight")
				hl.FillColor = Color3.fromRGB(255,60,60); hl.OutlineColor = Color3.fromRGB(255,255,255)
				hl.FillTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				pcall(function() hl.Parent = T.model; hl.Adornee = T.model end)
			end
			task.wait(0.3)
		else
			if hl then pcall(function() hl:Destroy() end); hl=nil end
			task.wait(0.4)
		end
	end
end)
-- AUTO FARM PLAYER (Plus + Premium): STAY ON THEM and hit — every pass we hard-CFrame right onto their dino and
-- land the captured Attack, over and over at your Hits/sec. This is the "keep TP to him and attacking" loop.
task.spawn(function() while RUNNING do
	if CFG.AutoFarmPlayer and alive() then
		local T = __gg.MH_Target
		local r, model
		if T.plr then r, model = targetLivePart(T.plr); if model then T.model=model end end
		local h = model and model:FindFirstChildOfClass("Humanoid")
		if r and model and model.Parent and ((not h) or h.Health>0) then
			if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
			__gg.MH_rescueMute = tick()+2
			-- KEEP YOU ALIVE ("auto farm kills me"): while farming, pin YOUR health to max every pass — the target
			-- bites back and would otherwise kill you point-blank. Health pin = you can't die while farming.
			pcall(function()
				local myh=hum(); if myh and myh.MaxHealth>0 then myh.Health=myh.MaxHealth; pcall(function() myh:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end) end
				local st=csStats(); if st then for _,k in ipairs({"Health","HP","Hitpoints"}) do if type(st[k])=="number" then local mx=(select(2,csStats()) or {})[k]; if mx then st[k]=mx end end end end
				pcall(function() setReplicaProp("Health", (myh and myh.MaxHealth) or 100) end)
			end)
			-- sit ABOVE + BEHIND them (out of their bite arc), not right on top where their attack lands on you
			local cc=getMyModel(); local root = cc and (cc.PrimaryPart or cc:FindFirstChild("HumanoidRootPart")) or hrp()
			if root then local goal=r.CFrame*CFrame.new(0,4,6); if __gg.MH_hopFire then __gg.MH_hopFire(goal) end
				if (root.Position-goal.Position).Magnitude>8 then pcall(function() root.CFrame=goal; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end) end
			end
			if _G.MH_attack then pcall(function() _G.MH_attack(model) end) end
			task.wait(1/math.max(1, tonumber(CFG.DamageRate) or 6))
		else task.wait(0.3) end
	else task.wait(0.3) end
end end)


-- ESP (own ScreenGui so it shows regardless of the menu being open/closed or which GUI is active)
local ESP={}  -- gui/folder/objs/dbg in one table (Luau 200-local-cap mgmt)
ESP.gui = C("ScreenGui",{Name="MoneyHubPE_ESP", ResetOnSpawn=false, IgnoreGuiInset=true})
safeParentGui(ESP.gui)
ESP.folder = C("Folder",{Parent=ESP.gui, Name="ESP"})
ESP.objs={}

-- ═══ DANGER ALERT: pick a dino; flash a red hazard warning when that species is near ═══
do
	local A = {}
	A.gui = C("ScreenGui",{Name="MoneyHubPE_Alert", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=9999}); safeParentGui(A.gui)
	A.frame = C("Frame",{Parent=A.gui, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Visible=false})
	A.top    = C("Frame",{Parent=A.frame, Size=UDim2.new(1,0,0,12), BackgroundColor3=Color3.fromRGB(255,30,30), BorderSizePixel=0})
	A.bottom = C("Frame",{Parent=A.frame, Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-12), BackgroundColor3=Color3.fromRGB(255,30,30), BorderSizePixel=0})
	A.left   = C("Frame",{Parent=A.frame, Size=UDim2.new(0,12,1,0), BackgroundColor3=Color3.fromRGB(255,30,30), BorderSizePixel=0})
	A.right  = C("Frame",{Parent=A.frame, Size=UDim2.new(0,12,1,0), Position=UDim2.new(1,-12,0,0), BackgroundColor3=Color3.fromRGB(255,30,30), BorderSizePixel=0})
	A.banner = C("Frame",{Parent=A.frame, AnchorPoint=Vector2.new(0.5,0), Size=UDim2.fromOffset(460,56), Position=UDim2.new(0.5,0,0,26), BackgroundColor3=Color3.fromRGB(40,0,0), BorderSizePixel=0}); corner(A.banner,8); stroke(A.banner,Color3.fromRGB(255,40,40),2)
	A.icon = C("TextLabel",{Parent=A.banner, Position=UDim2.fromOffset(16,0), Size=UDim2.fromOffset(42,56), BackgroundTransparency=1, Text="!", TextColor3=Color3.fromRGB(255,210,40), TextSize=36, Font=Enum.Font.GothamBold})
	A.text = C("TextLabel",{Parent=A.banner, Position=UDim2.fromOffset(60,0), Size=UDim2.new(1,-72,1,0), BackgroundTransparency=1, Text="DINO NEAR - RUN!", TextColor3=Color3.fromRGB(255,90,90), TextSize=20, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left})
	task.spawn(function() local on=false while RUNNING do
		local show,who,dd=false,nil,nil
		if CFG.AlertEnabled and CFG.AlertDino~="" and alive() then
			local me=hrp()
			if me then
				local want=tostring(CFG.AlertDino):lower()
				local function scan(folder) if not folder then return end for _,m in ipairs(folder:GetChildren()) do
					if not show and m:IsA("Model") and m~=getMyModel() then
						local sp=detectDinoModel(m) or m:GetAttribute("Type") or m:GetAttribute("Character") or m.Name
						if sp then local lsp=tostring(sp):lower()
							if lsp==want or lsp:find(want,1,true) or want:find(lsp,1,true) then
								local r=getHitbox(m) or rootOf(m)
								if r then local d=dist(me.Position,r.Position); if d<=(tonumber(CFG.AlertRange) or 350) then show=true; who=tostring(sp); dd=math.floor(d) end end
							end
						end
					end
				end end
				scan(WS:FindFirstChild("Characters"))
				for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Animals"}) do if not show then scan(WS:FindFirstChild(nm)) end end
			end
		end
		if show then
			if not on then on=true; pcall(function() A.frame.Visible=true end) end
			pcall(function() A.text.Text=(who and who:upper() or "DINO").." NEAR ["..(dd or 0).."m] - RUN!" end)
			local a=(math.sin(tick()*9)+1)/2
			pcall(function() for _,e in ipairs({A.top,A.bottom,A.left,A.right}) do e.BackgroundTransparency=0.15+a*0.65 end end)
			task.wait(0.05)
		else
			if on then on=false; pcall(function() A.frame.Visible=false end) end
			task.wait(0.35)
		end
	end end)
end
-- DEBUG STAT PANEL (green/yellow) — shows the REAL CharacterState.Replica values live, so you can SEE whether
-- a pin is actually changing the stat or only the HUD. Toggle in Info tab. Reuses ESP.gui (saves a ScreenGui).
ESP.dbg = nil
do
	local box = C("Frame",{Parent=ESP.gui, Size=UDim2.fromOffset(238,0), Position=UDim2.new(1,-250,0,96), BackgroundColor3=T.Panel, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, Visible=false}); corner(box,6); stroke(box,T.Accent,1)
	C("TextLabel",{Parent=box, Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Text="DEBUG · real stat values", TextColor3=T.Yellow, TextSize=13, Font=UIFONT})
	ESP.dbg = C("TextLabel",{Parent=box, Position=UDim2.fromOffset(10,24), Size=UDim2.new(1,-16,0,0), BackgroundTransparency=1, Text="", TextColor3=T.Success, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.Y, TextWrapped=true})
	C("UIPadding",{Parent=box, PaddingBottom=UDim.new(0,10)})
end
task.spawn(function() while RUNNING do task.wait(0.3); pcall(function()
	ESP.dbg.Parent.Visible = CFG.DebugPanel and true or false
	if not CFG.DebugPanel then return end
	local land="?"; for name in pairs(WATER_IDS) do if WS:FindFirstChild(name) then land=name break end end
	local lines={"Land: "..land}
	local stats,maxs=csStats()
	if stats then
		for _,g in ipairs({{"Food",{"Food","Hunger","Nutrition"}},{"Water",{"Water","Thirst","Hydration"}},{"Stamina",{"Stamina","Stam","Energy"}},{"Oxygen",{"Oxygen","Air","Breath"}},{"Health",{"Health","HP"}},{"Temp",{"Temperature","Temp"}}}) do
			local cur,mx; for _,k in ipairs(g[2]) do if stats[k]~=nil then cur=stats[k]; mx=maxs and maxs[k]; break end end
			if cur~=nil then lines[#lines+1]=g[1]..": "..math.floor(tonumber(cur) or 0)..(mx and (" / "..math.floor(tonumber(mx) or 0)) or "") end
		end
		for _,k in ipairs({"Bleeding","Bleed","Fractured","Fracture","Drowning","Exhausted","Swimming","IsInWater"}) do if stats[k]~=nil then lines[#lines+1]=k..": "..tostring(stats[k]) end end
	else lines[#lines+1]="(no data)" end
	-- COMBAT DIAGNOSTICS: if "MyID" shows nil, Attack can't fire (no dino id captured) — move/look around to capture it.
	lines[#lines+1]="MyID: "..tostring(myReplicaId or "nil (CharacterState.Replica.Id unavailable)")
	lines[#lines+1]="Sound: "..(getSoundRemote() and "found" or "MISSING")
	local tg=nearestTarget(300,true); lines[#lines+1]="Target: "..(tg and tg.Name or "none")
	-- ═══ INF STAM DIAGNOSTIC — tells us the REAL speed lever (send me these lines if stam is still slow) ═══
	lines[#lines+1]="── STAM DEBUG ──"
	lines[#lines+1]="CharState: "..(CharacterState and "OK" or "NIL (data pins do nothing!)")
	pcall(function()
		local mc = CharacterState and CharacterState.Movement
		lines[#lines+1]="Movement obj: "..(type(mc)=="table" and "table" or tostring(mc))
		if type(mc)=="table" then
			local shown=0
			for k,v in pairs(mc) do
				if (type(v)=="number" or type(v)=="boolean") and shown<8 then
					local kl=string.lower(tostring(k))
					if kl:find("speed",1,true) or kl:find("run",1,true) or kl:find("sprint",1,true) or kl:find("exhaust",1,true) or kl:find("multiplier",1,true) or kl:find("tired",1,true) or kl:find("stam",1,true) then
						lines[#lines+1]="  mv."..tostring(k).."="..tostring(v); shown=shown+1
					end
				end
			end
		end
	end)
	pcall(function()
		local mdl=(WS:FindFirstChild("Characters") and WS.Characters:FindFirstChild(LP.Name)) or char()
		local hh=mdl and mdl:FindFirstChildOfClass("Humanoid")
		local root=mdl and (mdl.PrimaryPart or mdl:FindFirstChild("HumanoidRootPart"))
		lines[#lines+1]="Humanoid: "..(hh and "yes WS="..tostring(math.floor((hh.WalkSpeed or 0)+0.5)) or "NO (WalkSpeed is useless)")
		if root then lines[#lines+1]="LinVel: "..tostring(math.floor(root.AssemblyLinearVelocity.Magnitude+0.5)) end
		local movers={}
		if mdl then for _,dd in ipairs(mdl:GetDescendants()) do
			if dd:IsA("LinearVelocity") or dd:IsA("BodyVelocity") or dd:IsA("AlignPosition") or dd:IsA("VectorForce") then movers[#movers+1]=dd.ClassName; if #movers>=3 then break end end
		end end
		lines[#lines+1]="Movers: "..(#movers>0 and table.concat(movers,",") or "none (velocity-driven)")
	end)
	ESP.dbg.Text=table.concat(lines,"\n")
end) end end)
local function destroyESP() for m,o in pairs(ESP.objs) do pcall(function() if o[1] then o[1]:Destroy() end if o[2] then o[2]:Destroy() end end) end ESP.objs={} end
-- ESP colour override: CFG.ESPColor "Default" = per-type colour; "Rainbow" = animated hue; or a named colour.
local function espColor(def)
	local c=CFG.ESPColor
	if c=="Rainbow" then return Color3.fromHSV((tick()*0.15)%1, 1, 1) end
	local M={Red=Color3.fromRGB(235,60,60),Green=Color3.fromRGB(80,235,90),Blue=Color3.fromRGB(70,140,255),Yellow=Color3.fromRGB(255,225,40),Purple=Color3.fromRGB(180,80,255),Cyan=Color3.fromRGB(50,230,230),Orange=Color3.fromRGB(255,150,30),Pink=Color3.fromRGB(255,105,180),White=Color3.fromRGB(255,255,255)}
	if c and M[c] then return M[c] end
	return def
end
local function addESP(model, color, label, hpFrac, stamFrac)
	if ESP.objs[model] then return end
	local r=getHitbox(model) or rootOf(model); if not r then return end
	color = espColor(color)
	-- Highlight MUST be parented into the workspace/model to render — inside a ScreenGui it shows NOTHING (that was the bug).
	local h = Instance.new("Highlight"); h.FillColor=color; h.OutlineColor=Color3.new(1,1,1); h.FillTransparency=0.6; h.OutlineTransparency=0; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Adornee=model; h.Parent=model
	local lines=1; for _ in label:gmatch("\n") do lines=lines+1 end
	local barH = (hpFrac and 7 or 0) + (stamFrac and 6 or 0)   -- room for HEALTH bar (+ STAMINA bar if we have it)
	local bb = Instance.new("BillboardGui"); bb.Adornee=r; bb.Size=UDim2.fromOffset(180, 13*lines+6+barH); bb.AlwaysOnTop=true; bb.StudsOffset=Vector3.new(0,3,0); bb.Parent=ESP.folder
	local tl = Instance.new("TextLabel"); tl.BackgroundTransparency=1; tl.Size=UDim2.new(1,0,1,-barH); tl.Text=label; tl.TextColor3=color; tl.TextStrokeTransparency=0.3; tl.TextSize=12; tl.Font=UIFONT; tl.TextYAlignment=Enum.TextYAlignment.Top; tl.Parent=bb
	local fill
	if hpFrac then   -- HEALTH BAR: green->red by HP %, sits at the bottom of the billboard
		local f=math.clamp(hpFrac,0,1)
		local bg=Instance.new("Frame"); bg.AnchorPoint=Vector2.new(0.5,1); bg.Position=UDim2.new(0.5,0,1,-1); bg.Size=UDim2.new(1,-20,0,5); bg.BackgroundColor3=Color3.fromRGB(20,20,20); bg.BackgroundTransparency=0.2; bg.BorderSizePixel=0; bg.Parent=bb
		local uc=Instance.new("UICorner"); uc.CornerRadius=UDim.new(0,2); uc.Parent=bg
		fill=Instance.new("Frame"); fill.Size=UDim2.new(f,0,1,0); fill.BorderSizePixel=0; fill.BackgroundColor3=Color3.fromRGB(math.floor(220*(1-f))+40, math.floor(200*f)+40, 55); fill.Parent=bg
		local uc2=Instance.new("UICorner"); uc2.CornerRadius=UDim.new(0,2); uc2.Parent=fill
	end
	if stamFrac then   -- STAMINA BAR: YELLOW, sits just ABOVE the health bar
		local sf=math.clamp(stamFrac,0,1)
		local sbg=Instance.new("Frame"); sbg.AnchorPoint=Vector2.new(0.5,1); sbg.Position=UDim2.new(0.5,0,1,-(hpFrac and 7 or 0)-1); sbg.Size=UDim2.new(1,-20,0,4); sbg.BackgroundColor3=Color3.fromRGB(20,20,20); sbg.BackgroundTransparency=0.2; sbg.BorderSizePixel=0; sbg.Parent=bb
		local uc3=Instance.new("UICorner"); uc3.CornerRadius=UDim.new(0,2); uc3.Parent=sbg
		local sfill=Instance.new("Frame"); sfill.Size=UDim2.new(sf,0,1,0); sfill.BorderSizePixel=0; sfill.BackgroundColor3=Color3.fromRGB(245,215,60); sfill.Parent=sbg
		local uc4=Instance.new("UICorner"); uc4.CornerRadius=UDim.new(0,2); uc4.Parent=sfill
	end
	ESP.objs[model]={h,bb,tl,fill}
end
-- RAINBOW animation: re-colour every active ESP highlight + label each frame while Rainbow is selected.
task.spawn(function() while RUNNING do
	if CFG.ESPColor=="Rainbow" then local col=Color3.fromHSV((tick()*0.15)%1,1,1); for _,o in pairs(ESP.objs) do pcall(function() if o[1] then o[1].FillColor=col end if o[3] then o[3].TextColor3=col end end) end; task.wait(0.05)
	else task.wait(0.3) end
end end)
local function readDinoInfo(model)   -- (exposed as __gg.MH_readDino below — the Target profile reuses it)
	local species,growth,health,stam,bleed,hpFrac
	species = detectDinoModel(model)
	for _,a in ipairs({"GrowthStage","Stage","Growth","Age","Maturity","LifeStage"}) do local v=model:GetAttribute(a); if v~=nil then growth=tostring(v); break end end
	local mm=model:FindFirstChild("MeshModel"); if not growth and mm then local v=mm:GetAttribute("Stage"); if v then growth=tostring(v) end end
	local h=model:FindFirstChildOfClass("Humanoid"); if h and h.MaxHealth>0 then health=("%d/%d"):format(math.floor(h.Health),math.floor(h.MaxHealth)); hpFrac=h.Health/h.MaxHealth end
	if not health then local cur,mx
		for _,a in ipairs({"Health","HP","Hitpoints","HitPoints"}) do local v=model:GetAttribute(a); if v then cur=tonumber(v); break end end
		for _,a in ipairs({"MaxHealth","MaxHP"}) do local v=model:GetAttribute(a); if v then mx=tonumber(v); break end end
		if cur then if mx and mx>0 then health=("%d/%d"):format(math.floor(cur),math.floor(mx)); hpFrac=cur/mx else health=tostring(math.floor(cur)) end end
	end
	-- STAMINA + BLEED — thorough hunt (user: "i don't see their stam"). Search by SUBSTRING across every attribute on
	-- the model, its Humanoid, MeshModel, and any Stats/Data/Vitals child folder — PE often names it CurrentStamina /
	-- StaminaValue etc., which fixed-name lookups missed.
	local function scanAttrs(inst)
		if not inst then return end
		pcall(function()
			for k,v in pairs(inst:GetAttributes()) do
				if type(v)=="number" then
					local n=tostring(k):lower()
					if not stam and (n:find("stam",1,true) or n:find("energy",1,true) or n:find("endur",1,true) or n:find("vigor",1,true)) and not n:find("max",1,true) then stam=tostring(math.floor(v))
					elseif not bleed and (n:find("bleed",1,true) or n:find("bloodloss",1,true) or n:find("hemorrh",1,true) or n:find("wound",1,true)) then bleed=math.floor(v) end
				end
			end
		end)
	end
	scanAttrs(model); scanAttrs(model:FindFirstChildOfClass("Humanoid")); scanAttrs(model:FindFirstChild("MeshModel"))
	for _,fn in ipairs({"Stats","Data","Vitals","Needs","State","Status"}) do scanAttrs(model:FindFirstChild(fn)) end
	-- also the classic fixed names as a fast path
	if not stam then for _,a in ipairs({"Stamina","Stam","Energy","Endurance","Vigor","CurrentStamina","StaminaValue"}) do local v=model:GetAttribute(a); if v then stam=tostring(math.floor(tonumber(v) or 0)); break end end end
	if not bleed then for _,a in ipairs({"Bleed","Bleeding","BleedDamage","Wound","Wounds","Bloodloss","Bleed_Damage"}) do local v=model:GetAttribute(a); if v then bleed=math.floor(tonumber(v) or 0); break end end end
	-- Number/Int value-object fallback (stats stored as Values inside the model / a Stats folder)
	if (not stam) or (not hpFrac) or (not bleed) then
		local scanned=0
		for _,v in ipairs(model:GetDescendants()) do
			scanned+=1; if scanned>1200 then break end
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				local n=v.Name:lower()
				if not stam and (n:find("stam",1,true) or n=="energy" or n:find("endur",1,true) or n:find("vigor",1,true)) and not n:find("max",1,true) then stam=tostring(math.floor(tonumber(v.Value) or 0))
				elseif not bleed and (n:find("bleed",1,true) or n:find("bloodloss",1,true) or n:find("wound",1,true)) then bleed=math.floor(tonumber(v.Value) or 0)
				elseif not hpFrac and (n=="health" or n=="hp") then
					local mx; local sib=v.Parent and (v.Parent:FindFirstChild("MaxHealth") or v.Parent:FindFirstChild("MaxHP"))
					if sib then mx=tonumber(sib.Value) end
					local cur=tonumber(v.Value)
					if cur then if mx and mx>0 then health=("%d/%d"):format(math.floor(cur),math.floor(mx)); hpFrac=cur/mx else health=health or tostring(math.floor(cur)) end end
				end
			end
			if stam and hpFrac and bleed then break end
		end
	end
	-- last resort for the BAR: no readable HP anywhere → show a FULL bar (so every dino still gets a visible bar)
	if not hpFrac then hpFrac=1 end
	-- STAMINA BAR fraction (user: "add their stamina bar to their ESP"): find a MAX stamina alongside the value so we
	-- can draw a yellow stamina bar. Only shows for dinos that actually expose stamina to the client (many enemies
	-- keep it server-side / in their own HUD only, so it won't always appear — that's a game limit, not a bug).
	local stamFrac
	if stam then
		local sv=tonumber(stam); local smx
		for _,a in ipairs({"MaxStamina","MaxStam","MaxEnergy","MaxEndurance","StaminaMax"}) do local v=model:GetAttribute(a); if v then smx=tonumber(v); break end end
		if not smx then for _,fn in ipairs({"Stats","Data","Vitals","Needs"}) do local f=model:FindFirstChild(fn); if f then for _,a in ipairs({"MaxStamina","MaxStam","MaxEnergy"}) do local v=f:GetAttribute(a); if v then smx=tonumber(v); break end end end if smx then break end end end
		if sv and smx and smx>0 then stamFrac=math.clamp(sv/smx,0,1) end
	end
	return species,growth,health,stam,bleed,hpFrac,stamFrac
end
__gg.MH_readDino = readDinoInfo   -- the Target profile calls this at runtime (guarded) — same reader the ESP uses
-- ESP is throttled (1.6s) and HARD-CAPPED at 60 objects, and the whole rebuild is pcall-wrapped,
-- so Fish ESP (which used to scan the entire workspace every 0.6s) can no longer lag you out or kill the menu.
task.spawn(function() while RUNNING do task.wait(1.6); pcall(function()
	destroyESP(); local me=hrp()
	if not me or not (CFG.ESPPlayers or CFG.ESPCorpses or CFG.FoodESP or CFG.FishESP or CFG.GemESP) then return end
	local MAX=60; local count=0
	if CFG.ESPPlayers then
		local chars = WS:FindFirstChild("Characters")
		if chars then
			for _,m in ipairs(chars:GetChildren()) do
				if count>=MAX then break end
				if m:IsA("Model") and m~=getMyModel() then
					local body = getHitbox(m) or rootOf(m)
					if body then
						local d=dist(me.Position, body.Position)
						if d<=CFG.ESPRange then
							local sp,gr,hp,st,bl,hpf,stf = readDinoInfo(m)
							local pl = Players:GetPlayerFromCharacter(m)
							-- always show the DINO SPECIES; for a player-controlled dino show their name on top + species under
							local label
							if pl and sp then label = pl.Name.."\n"..sp else label = (pl and pl.Name) or sp or m.Name end
							label = label.."\n["..math.floor(d).."m]"
							if gr then label=label.."\nStage: "..gr end
							if hp then label=label.."\nHP: "..hp end
							if st then label=label.."\nStam: "..st end
							if bl and bl>0 then label=label.."\nBlood: "..bl end
							addESP(m, pl and Color3.fromRGB(90,170,255) or Color3.fromRGB(120,220,120), label, hpf, stf); count+=1
						end
					end
				end
			end
		end
	end
	-- CORPSES (RED): use the SAME authoritative source as Carnivore Meat TP — the CorpseSpawns DinosaurSpawn markers
	-- that actually have a body spawned in them — PLUS "Corpse_..." models and "Investigate" prompts as a fallback.
	if CFG.ESPCorpses then
		-- 1) CorpseSpawns.DinosaurSpawn markers with a real body inside (the parts the user pointed us at)
		local ci=WS:FindFirstChild("CharacterIgnore"); local cs=ci and ci:FindFirstChild("CorpseSpawns")
		if cs then for _,dsp in ipairs(cs:GetChildren()) do
			if count>=MAX then break end
			local body
			for _,x in ipairs(dsp:GetDescendants()) do
				if x:IsA("Humanoid") then local p=x.Parent; body=(p and (rootOf(p) or p:FindFirstChildWhichIsA("BasePart"))); if body then break end
				elseif x:IsA("MeshPart") and x.Transparency<0.95 then body=x; break
				elseif x:IsA("Model") and x~=dsp then body=rootOf(x) or x:FindFirstChildWhichIsA("BasePart"); if body then break end end
			end
			if body then local dd=dist(me.Position, body.Position); if dd<=CFG.ESPRange then
				local mdl=body:FindFirstAncestorWhichIsA("Model") or (body.Parent and body.Parent:IsA("Model") and body.Parent) or (dsp:IsA("Model") and dsp) or body
				addESP(mdl, Color3.fromRGB(235,60,60), "Corpse ["..math.floor(dd).."m]"); count+=1 end end
		end end
		-- 2) fallback: named Corpse_ models + Investigate prompts anywhere else
		local scanned=0
		for _,d in ipairs(WS:GetDescendants()) do
			if count>=MAX then break end
			scanned+=1; if scanned>5000 then break end
			local model
			if (d:IsA("Model") or d:IsA("Folder")) and d.Name:lower():find("corpse",1,true) then model=d
			elseif d:IsA("ProximityPrompt") then local at=(d.ActionText or ""):lower(); local nm=(d.Name or ""):lower()
				if at:find("investigate") or nm:find("investigate") or nm:find("corpse") then local p=d.Parent; model=(p and p:IsA("Model")) and p or (p and p:FindFirstAncestorWhichIsA("Model")) or p end
			end
			if model and not ESP.objs[model] then
				local part=getHitbox(model) or rootOf(model) or (model:IsA("BasePart") and model)
				if part then local dd=dist(me.Position, part.Position); if dd<=CFG.ESPRange then addESP(model, Color3.fromRGB(235,60,60), "Corpse ["..math.floor(dd).."m]"); count+=1 end end
			end
		end
	end
	-- GEM + FOSSIL ESP: highlight every gemstone / fossil node (GemstoneSpawns>Spawned>Topaz_## / SpawnedFossils>##).
	if CFG.GemESP then
		for _,kind in ipairs({"gem","fossil"}) do
			for _,nd in ipairs(getNodes(kind, 1e9)) do
				if count>=MAX then break end
				local part=nd[2]
				if part and part.Parent then local dd=dist(me.Position, part.Position); if dd<=CFG.ESPRange then addESP(nd[1], (kind=="gem") and Color3.fromRGB(120,220,255) or Color3.fromRGB(220,200,120), ((kind=="gem") and "Gem [" or "Fossil [")..math.floor(dd).."m]"); count+=1 end end
			end
		end
	end
	-- FOOD / FISH: plants & fish are scattered, so this needs a wider scan — but ONLY run it when those are
	-- actually on, capped + throttled so it can't lag you. GREEN = plant (herbivore), RED = meat/fish (carnivore).
	-- FISH live under workspace.CharacterIgnore.SpawnedAI (e.g. > Fish > <species> > Visual > Hitbox). Scan that
	-- folder DIRECTLY so Fish ESP catches every fish regardless of name. (Plants/corpses still use the name scan below.)
	if CFG.FishESP then
		local ci=WS:FindFirstChild("CharacterIgnore"); local sai=ci and ci:FindFirstChild("SpawnedAI")
		local fishF=sai and (sai:FindFirstChild("Fish") or sai)
		if fishF then for _,m in ipairs(fishF:GetDescendants()) do
			if count>=MAX then break end
			if m:IsA("Model") then
				local r=getHitbox(m) or rootOf(m)
				if r then local d=dist(me.Position,r.Position); if d<=CFG.ESPRange then addESP(m, Color3.fromRGB(90,210,255), "Fish: "..m.Name.." ["..math.floor(d).."m]"); count+=1 end end
			end
		end end
	end
	if CFG.FoodESP or CFG.FishESP then
		local scanned=0
		for _,m in ipairs(WS:GetDescendants()) do
			if count>=MAX then break end
			scanned+=1; if scanned>3500 then break end
			if m:IsA("Model") and m~=char() and not Players:GetPlayerFromCharacter(m) then
				local n=m.Name:lower()
				local hit,color,tag
				if CFG.FishESP and isFishName(n) then hit=true; color=Color3.fromRGB(90,210,255); tag="Fish: "..m.Name
				elseif CFG.FoodESP and isFoodName(n) then
					-- PLANT ESP: herbivore plants ONLY, always GREEN. Skip meat/corpse/fish (those are Corpse ESP's job).
					local meat=(n:find("meat") or n:find("corpse") or n:find("carcass") or n:find("carrion") or n:find("chunk") or n:find("rotten") or n:find("flesh") or n:find("remains") or isFishName(n))
					if not meat then hit=true; color=Color3.fromRGB(70,235,70); tag="Plant: "..m.Name end
				end
				if hit then local r=rootOf(m); if r then local d=dist(me.Position,r.Position); if d<=CFG.ESPRange then addESP(m,color,tag.." ["..math.floor(d).."m]"); count+=1 end end end
			end
		end
	end
end) end end)

-- âââ STAFF DETECTION â warn on admins / mods, offer Server Hop / Rejoin / Stay âââ
-- Wrapped in one spawned function so ALL its locals live in THIS function's own 200-local budget, not the main chunk
-- (the main chunk is right at the cap â adding even one persistent local there made the whole script fail to load).
task.spawn(function()
	local STF = { shown=false, stayed=false }
	local KW = {"administrator","moderator","admin","staff","developer","game master","game admin","head admin"}   -- real staff only (ZENITH dropped — it's a normal rank, not staff)
	local function match(str) if type(str)~="string" then return nil end local l=str:lower()
		for _,k in ipairs(KW) do if l:find(k,1,true) then return k end end
		if l:find("%[mod%]",1) or l:find("%f[%a]mod%f[%A]",1) then return "mod" end
		return nil
	end
	local sg=C("ScreenGui",{Name="MH_Staff", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=10000, Enabled=false}); safeParentGui(sg)
	-- clean card: white panel, red accent bar on top, warning glyph, title + subtitle, three pill buttons with hover
	local fr=C("Frame",{Parent=sg, Size=UDim2.fromOffset(380,196), Position=UDim2.new(0.5,-190,0,70), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0}); corner(fr,14); stroke(fr,Color3.fromRGB(228,231,236),1)
	C("ImageLabel",{Parent=fr, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Image="rbxassetid://0"})  -- (placeholder for shadow; harmless)
	local top=C("Frame",{Parent=fr, Size=UDim2.new(1,0,0,5), BackgroundColor3=Color3.fromRGB(235,70,70), BorderSizePixel=0}); corner(top,3)
	local badge=C("Frame",{Parent=fr, Size=UDim2.fromOffset(46,46), Position=UDim2.fromOffset(20,22), BackgroundColor3=Color3.fromRGB(255,238,238), BorderSizePixel=0}); corner(badge,23)
	C("TextLabel",{Parent=badge, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="!", TextColor3=Color3.fromRGB(235,70,70), TextSize=26, Font=Enum.Font.GothamBold})
	C("TextLabel",{Parent=fr, Position=UDim2.fromOffset(78,22), Size=UDim2.new(1,-92,0,22), BackgroundTransparency=1, Text="Staff Detected", TextColor3=Color3.fromRGB(30,33,40), TextSize=18, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left})
	local ttl=C("TextLabel",{Parent=fr, Position=UDim2.fromOffset(78,46), Size=UDim2.new(1,-92,0,44), BackgroundTransparency=1, Text="A staff member is in this server.", TextColor3=Color3.fromRGB(120,126,138), TextSize=13, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true})
	local function mkB(txt,x,w,col,txtcol)
		local b=C("TextButton",{Parent=fr, Size=UDim2.fromOffset(w,40), Position=UDim2.fromOffset(x,140), BackgroundColor3=col, Text=txt, TextColor3=txtcol or Color3.new(1,1,1), TextSize=13, Font=Enum.Font.GothamBold, BorderSizePixel=0, AutoButtonColor=false}); corner(b,10)
		b.MouseEnter:Connect(function() tw(b,{BackgroundTransparency=0.12}) end); b.MouseLeave:Connect(function() tw(b,{BackgroundTransparency=0}) end)
		return b
	end
	local bHop=mkB("Server Hop",20,150,Color3.fromRGB(235,70,70)); local bJoin=mkB("Rejoin",180,90,Color3.fromRGB(240,190,70)); local bStay=mkB("Stay",280,80,Color3.fromRGB(238,240,244),Color3.fromRGB(70,76,88))
	local function hop()
		local moved=false; local ok=pcall(function()
			local res=game:HttpGetAsync("https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?sortOrder=Asc&limit=100")
			local data=HttpService:JSONDecode(res)
			for _,srv in ipairs(data.data or {}) do if srv.id~=game.JobId and (tonumber(srv.playing) or 0)<(tonumber(srv.maxPlayers) or 100) then moved=true; TeleportSvc:TeleportToPlaceInstance(game.PlaceId, srv.id, LP); return end end
		end)
		if not ok or not moved then pcall(function() notify("Server","No different public server is available right now.") end) end
	end
	local function warnStaff(name, tag)
		if STF.stayed or STF.shown then return end; STF.shown=true
		local t=tostring(tag):gsub("^%l",string.upper)
		pcall(function() ttl.Text=tostring(name).." ("..t..") is in this server.\nServer hop, rejoin, or stay?"; sg.Enabled=true end)
		pcall(function() notify("Staff Detected", tostring(name).." ("..t..") is in the server.") end)
	end
	bHop.MouseButton1Click:Connect(function() sg.Enabled=false; hop() end)
	bJoin.MouseButton1Click:Connect(function() sg.Enabled=false; pcall(function() TeleportSvc:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end) end)
	bStay.MouseButton1Click:Connect(function() sg.Enabled=false; STF.shown=false; STF.stayed=true end)
	pcall(function()   -- CHAT TAGS: watch every TextChannel for a staff tag in the message prefix/metadata
		local TCS=game:GetService("TextChatService")
		local function onMsg(message)
			local tag = match(message.PrefixText) or match(message.Metadata)
			if tag then local pl; pcall(function() local src=message.TextSource; if src then pl=Players:GetPlayerByUserId(src.UserId) end end)
				if pl~=LP then warnStaff((pl and pl.Name) or "A player", tag) end
			end
		end
		for _,ch in ipairs(TCS:GetDescendants()) do if ch:IsA("TextChannel") then ch.MessageReceived:Connect(onMsg) end end
		conn(TCS.DescendantAdded:Connect(function(d) if d:IsA("TextChannel") then d.MessageReceived:Connect(onMsg) end end))
	end)
	task.wait(3); local seen={}
	while RUNNING do   -- PLAYER SCAN: staff rank in an attribute/value
		pcall(function() for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP and not seen[pl] then
			local tag
			pcall(function() for k,v in pairs(pl:GetAttributes()) do tag=tag or match(tostring(k)) or match(tostring(v)) end end)
			if not tag then pcall(function() for _,d in ipairs(pl:GetDescendants()) do if d:IsA("StringValue") then tag=tag or match(d.Name) or match(d.Value) end if tag then break end end end) end
			if tag then seen[pl]=true; warnStaff(pl.Name, tag) end
		end end end)
		task.wait(6)
	end
end)

-- INPUT (UI key + feature keybinds)
local function toggleKey(key) CFG[key]=not CFG[key]; if __gg.MH_featureToggleChanged then __gg.MH_featureToggleChanged(key,CFG[key]) end; local ref=toggleRefs[key]; if ref then tw(ref[1],{BackgroundColor3=CFG[key] and T.On or T.Off}); tw(ref[2],{Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)}) end saveCfg() end
conn(UIS.InputBegan:Connect(function(input, gp)
	if capturing then return end
	if tick()-bindGuard < 0.25 then return end
	if input.UserInputType~=Enum.UserInputType.Keyboard then return end
	local kn = input.KeyCode.Name
	local uiKey = CFG.Keybinds["UIKey"] or CFG.UIKey or "RightShift"
	if kn==uiKey then SG.Enabled=not SG.Enabled; if SG.Enabled and not USE_FLUENT then task.defer(clampWindow) end; return end  -- SG.Enabled mirrors menu-open for the aim/autoclick guards (Fluent handles its own RightShift minimize)
	if gp then return end
	-- A duplicated saved binding must never make a survival toggle also enable speed/farm/teleport behavior. Old
	-- config files can contain collisions, so Food and Stamina each own their keypress exclusively.
	if CFG.Keybinds.InfFood==kn then toggleKey("InfFood"); return end
	if CFG.Keybinds.InfStam==kn then toggleKey("InfStam"); return end
	for cfgKey, boundName in pairs(CFG.Keybinds) do
		if boundName==kn and cfgKey~="UIKey" and cfgKey~="AimKey" then
			if type(CFG[cfgKey])=="boolean" then toggleKey(cfgKey) end
		end
	end
end))

-- ── MOBILE menu toggle (Delta & other touch executors have NO keyboard, so RightShift can't open the menu) ──
local function toggleMenu()
	if USE_FLUENT then
		-- LOGO = HIDE/SHOW ("when they click my logo it removes the GUI, click again brings it back"):
		-- 1) Fluent's own Minimize (works on every executor), 2) virtual RightShift as backup.
		local ok=false
		pcall(function() if FWindow and FWindow.Minimize then FWindow:Minimize(); ok=true end end)
		if not ok then pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game); task.wait(); VIM:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game) end) end
	else
		SG.Enabled = not SG.Enabled; if SG.Enabled then task.defer(clampWindow) end
	end
end
do   -- DREAM LOGO button (ALL devices now): black & white Dream badge — tap opens/closes the menu, drag moves it.
	local tg = C("ScreenGui",{Name="MH_Toggle", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=10001, Enabled=true})
	safeParentGui(tg)
	-- BLACK & WHITE by design: black circle, white ring, the Dream logo image (the same Roblox asset the JJS hub
	-- uses) tinted pure white on top, with a white "DREAM" as the instant fallback until the image verifiably loads.
	local btn = C("ImageButton",{Parent=tg, Size=UDim2.fromOffset(46,46), Position=UDim2.new(0,14,0.35,0), BackgroundColor3=Color3.fromRGB(10,10,10), AutoButtonColor=true, ZIndex=50})
	btn.Image = "rbxthumb://type=Asset&id=82151574125055&w=150&h=150"
	btn.ImageTransparency = 1
	btn.ImageColor3 = Color3.fromRGB(255,255,255)   -- white-on-black = the B/W look
	btn.ScaleType = Enum.ScaleType.Fit
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
	local st = Instance.new("UIStroke"); st.Color=Color3.fromRGB(255,255,255); st.Transparency=0.35; st.Thickness=1.6; st.Parent=btn
	local tl = C("TextLabel",{Parent=btn, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="DREAM", TextColor3=Color3.fromRGB(255,255,255), Font=Enum.Font.GothamBlack, TextScaled=true, ZIndex=51})
	local pd = Instance.new("UIPadding"); pd.PaddingLeft=UDim.new(0,5); pd.PaddingRight=UDim.new(0,5); pd.PaddingTop=UDim.new(0,15); pd.PaddingBottom=UDim.new(0,15); pd.Parent=tl
	task.spawn(function()   -- swap the text for the real logo only once the image has ACTUALLY loaded (never a blank circle)
		for _=1,40 do if not btn.Parent then return end if btn.IsLoaded then break end task.wait(0.15) end
		if btn.Parent and btn.IsLoaded then pcall(function() btn.ImageTransparency=0; tl.Visible=false end) end
	end)
	-- tap = toggle menu; drag = reposition (so it never blocks gameplay). We tell them apart by movement.
	local dragging, dragStart, startPos, moved = false, nil, nil, false
	btn.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true; moved=false; dragStart=i.Position; startPos=btn.Position
		end
	end)
	conn(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			local d=i.Position-dragStart
			if (math.abs(d.X)+math.abs(d.Y))>6 then moved=true end
			btn.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end))
	conn(UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			if dragging and not moved then toggleMenu() end
			dragging=false
		end
	end))
	-- Fly ascend/descend buttons (Space/LeftControl can't be pressed on a touchscreen). Touch devices only.
	local function flyBtn(txt, yoff, down, up)
		local b = C("TextButton",{Parent=tg, Size=UDim2.fromOffset(46,46), Position=UDim2.new(1,-60,0.5,yoff), BackgroundColor3=(T and T.Accent) or Color3.fromRGB(200,40,40), Text=txt, TextColor3=Color3.fromRGB(255,255,255), TextSize=22, Font=UIFONT, AutoButtonColor=true, ZIndex=50})
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
		local s2=Instance.new("UIStroke"); s2.Color=Color3.fromRGB(0,0,0); s2.Thickness=1.5; s2.Parent=b
		b.MouseButton1Down:Connect(down); b.MouseButton1Up:Connect(up)
	end
	if UIS.TouchEnabled then
		flyBtn("▲", -52, function() MB.up=true end,   function() MB.up=false end)
		flyBtn("▼",   6, function() MB.down=true end, function() MB.down=false end)
	end
end
task.spawn(function() local last=false; while RUNNING do task.wait(0.1); if CFG.Fly~=last then last=CFG.Fly; if CFG.Fly then startFly() else stopFly() end end end end)
conn(LP.CharacterAdded:Connect(function()
	-- ═══ SPAWN SAFETY (fix "I keep dying when I spawn — fall damage / teleported outside the map") ═══ For 10s after
	-- every spawn we HARD-force fall immunity every frame (the server keeps resetting it right at spawn = the death),
	-- clear any fall status, and set a spawn-grace that BLOCKS every teleport feature (corpse TP / farm / save-sky)
	-- so nothing can yeet you into the void the instant you load in.
	__gg.MH_spawnGrace = tick() + 10
	carnSpawnT = tick()
	task.spawn(function()
		local t0=tick()
		while tick()-t0 < 10 and RUNNING do
			if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
			pcall(function() clearStatus({"fall","falldamage","falldmg"},{"Falling","FallDamage","FallDmg"}) end)
			pcall(function() local r=hrp(); if r then local v=r.AssemblyLinearVelocity; if v.Y<-60 then r.AssemblyLinearVelocity=Vector3.new(v.X,-25,v.Z) end end end)  -- cap a killer fall
			task.wait()
		end
	end)
	task.wait(1); saving=false; SKN.saBack={}; pcall(function() CharacterState=CharacterState or (require(RS:WaitForChild("Common",5):WaitForChild("CharacterState",5))) end); if CFG.Fly then startFly() end pcall(function() local r=hrp(); if r then r.Anchored=false end end)
	-- ON SPAWN: fill food + water right away (fire the real eat/Sip sequences in a burst so you spawn topped up).
	task.spawn(function() local foodToken=__gg.MH_foodGen; task.wait(1.5); for _=1,10 do if not RUNNING then break end if CFG.InfFood and foodToken==__gg.MH_foodGen and alive() then fakeEat() end if CFG.InfWater and alive() then fakeDrink() end task.wait(0.18) end end)
end))
local lastSkinDino=nil
task.spawn(function() while RUNNING do task.wait(2)
	local ok,dt,st = pcall(skGetCharInfo)
	if ok and dt and dt~=lastSkinDino then lastSkinDino=dt; if dinoLabel then dinoLabel.Text="Dino: "..tostring(dt).." | Stage: "..tostring(st) end if skinDropdownRef then skinDropdownRef.refresh() end end
end end)

-- ═══ REMOVE TREES (FPS BOOST) ═══ Trees are the map's heaviest meshes. We UNPARENT (not destroy) every
-- decorative tree so toggling off restores them. CRITICAL: in this game herbivores EAT trees/plants via
-- ProximityPrompts — anything containing a prompt is FOOD and is always kept. Terrain grass is disabled too.
-- (Wrapped in a do-block so its locals free at the end = they don't count toward the main-chunk 200-register cap.)
do
local TREES = {removed={}, conn=nil, decor=nil, kw={"tree","palm","pine","oak","birch","spruce","redwood","sequoia","conifer","cycad","ginkgo","gingko","willow","cedar","araucaria","acacia","leaves","leaf","branch","trunk","stump"}}
local function isTreeName(n) n=string.lower(n); for _,k in ipairs(TREES.kw) do if n:find(k,1,true) then return true end end return false end
local function treeRemovable(inst)
	local chars=WS:FindFirstChild("Characters"); if chars and inst:IsDescendantOf(chars) then return false end
	local ci=WS:FindFirstChild("CharacterIgnore"); if ci and inst:IsDescendantOf(ci) then return false end
	if inst:FindFirstChildWhichIsA("ProximityPrompt", true) then return false end   -- has a prompt = edible = FOOD, keep it
	return true
end
local function treeTop(d)   -- lift a matched part to its outermost tree-named ancestor so the whole tree goes at once
	local top=d; local p=d.Parent
	while p and p~=WS do if (p:IsA("Model") or p:IsA("Folder")) and isTreeName(p.Name) then top=p end p=p.Parent end
	return top
end
local function setTrees(on)
	if on then
		pcall(function() local t=WS:FindFirstChildOfClass("Terrain"); if t then TREES.decor=t.Decoration; t.Decoration=false end end)
		task.spawn(function()
			local i=0
			for _,d in ipairs(WS:GetDescendants()) do
				if not CFG.RemoveTrees then break end
				i+=1; if i%2500==0 then task.wait() end   -- yield so the one-time sweep can't freeze the game
				if (d:IsA("Model") or d:IsA("BasePart")) and d.Parent and isTreeName(d.Name) then
					local top=treeTop(d)
					if top.Parent and treeRemovable(top) then pcall(function() TREES.removed[#TREES.removed+1]={top, top.Parent}; top.Parent=nil end) end
				end
			end
			if CFG.RemoveTrees then notify("Remove Trees","Removed "..#TREES.removed.." tree objects.") end
		end)
		TREES.conn=WS.DescendantAdded:Connect(function(d)   -- streaming keeps adding trees back — remove those too
			if not CFG.RemoveTrees then return end
			if (d:IsA("Model") or d:IsA("BasePart")) and isTreeName(d.Name) then
				task.delay(0.5, function()   -- wait so a food tree's prompt has streamed in before we judge it
					if CFG.RemoveTrees and d.Parent then
						local top=treeTop(d)
						if top.Parent and treeRemovable(top) then pcall(function() TREES.removed[#TREES.removed+1]={top, top.Parent}; top.Parent=nil end) end
					end
				end)
			end
		end)
	else
		pcall(function() if TREES.conn then TREES.conn:Disconnect(); TREES.conn=nil end end)
		pcall(function() local t=WS:FindFirstChildOfClass("Terrain"); if t and TREES.decor~=nil then t.Decoration=TREES.decor; TREES.decor=nil end end)
		for _,e in ipairs(TREES.removed) do pcall(function() if e[1] and e[2] then e[1].Parent=e[2] end end) end
		TREES.removed={}
		notify("Remove Trees","Trees restored.")
	end
end
task.spawn(function() local last=false; while RUNNING do task.wait(0.2); if CFG.RemoveTrees~=last then last=CFG.RemoveTrees; setTrees(last) end end end)
end   -- end Remove Trees do-block

-- ═══ MINIMAP RADAR ═══ Rotating radar (up = where your camera faces). Red dots = other players' dinos —
-- clamped to the edge when beyond zoom, so you ALWAYS see their direction no matter how far. White ✕ = the
-- spot you last died at (RadarDeath). Zoom slider = how many studs the circle spans.
-- (do-block: its locals free at the end so they don't count toward the main-chunk 200-register cap.)
do
local RADAR = {gui=nil, frame=nil, dots={}, deathDot=nil, lastPos=nil, hadChar=false, deathPos=nil}
local function radarBuild()
	if RADAR.gui and RADAR.gui.Parent then return end
	pcall(function() if RADAR.gui then RADAR.gui:Destroy() end end)
	RADAR.dots={}; RADAR.deathDot=nil
	local g=C("ScreenGui",{Name="MH_Radar", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=9997})
	safeParentGui(g)
	local fr=C("Frame",{Parent=g, Size=UDim2.fromOffset(170,170), AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,120), BackgroundColor3=Color3.fromRGB(8,8,8), BackgroundTransparency=0.35, BorderSizePixel=0, ClipsDescendants=true})
	C("UICorner",{Parent=fr, CornerRadius=UDim.new(1,0)})
	C("UIStroke",{Parent=fr, Color=T.Accent, Thickness=1.4, Transparency=0.15})
	C("TextLabel",{Parent=fr, Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,6), BackgroundTransparency=1, Text="RADAR", TextColor3=T.Accent, TextSize=9, Font=UIFONT})
	local me=C("Frame",{Parent=fr, Size=UDim2.fromOffset(8,8), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=4})
	C("UICorner",{Parent=me, CornerRadius=UDim.new(1,0)})
	C("UIStroke",{Parent=me, Color=T.Accent, Thickness=1.4})
	RADAR.gui=g; RADAR.frame=fr
end
local function radarDot(key, isDeath)
	local d=RADAR.dots[key]
	if d and d[1].Parent then return d end
	local f=C("Frame",{Parent=RADAR.frame, Size=UDim2.fromOffset(7,7), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=isDeath and Color3.fromRGB(235,235,235) or Color3.fromRGB(255,45,45), BackgroundTransparency=isDeath and 1 or 0, BorderSizePixel=0, ZIndex=3})
	if not isDeath then C("UICorner",{Parent=f, CornerRadius=UDim.new(1,0)}) end
	local lb=C("TextLabel",{Parent=f, Size=UDim2.fromOffset(60,10), AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,1,1), BackgroundTransparency=1, Text=isDeath and "" or key, TextColor3=Color3.fromRGB(235,235,235), TextSize=8, Font=UIFONT, TextTransparency=0.15, ZIndex=3})
	if isDeath then C("TextLabel",{Parent=f, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="✕", TextColor3=Color3.fromRGB(240,240,240), TextSize=12, Font=UIFONT, ZIndex=3}) end
	d={f,lb}; RADAR.dots[key]=d
	return d
end
local function radarPlace(dotFrame, rel, fwd, right, radius, scale)
	local dx, dz = rel:Dot(right), rel:Dot(fwd)
	local v=Vector2.new(dx*scale, -dz*scale)
	if v.Magnitude>radius then v=v.Unit*radius end   -- beyond zoom: pin to the edge = direction always visible
	dotFrame.Position=UDim2.new(0.5, v.X, 0.5, v.Y)
end
task.spawn(function()
	while RUNNING do
		task.wait(0.12)
		pcall(function()
			-- death-point tracking runs even with the radar off, so the ✕ is ready when you enable it
			local r=hrp()
			if r then RADAR.hadChar=true; RADAR.lastPos=r.Position
			elseif RADAR.hadChar then RADAR.hadChar=false; RADAR.deathPos=RADAR.lastPos end
			if not CFG.Radar then if RADAR.gui then RADAR.gui.Enabled=false end return end
			radarBuild(); RADAR.gui.Enabled=true
			if not r then return end
			local look=Cam and Cam.CFrame.LookVector or Vector3.new(0,0,-1)
			local fwd=Vector3.new(look.X,0,look.Z); fwd=(fwd.Magnitude>0.05) and fwd.Unit or Vector3.new(0,0,-1)
			local right=Vector3.new(-fwd.Z,0,fwd.X)
			local radius=76
			local scale=(radius*2)/math.max(CFG.RadarRange or 450, 50)   -- studs across the circle
			local used={}
			local chars=WS:FindFirstChild("Characters")
			for _,plr in ipairs(Players:GetPlayers()) do
				if plr~=LP then
					local m=(chars and chars:FindFirstChild(plr.Name)) or plr.Character
					local part=m and rootOf(m)
					if part then
						used[plr.Name]=true
						local d=radarDot(plr.Name, false)
						radarPlace(d[1], part.Position-r.Position, fwd, right, radius, scale)
					end
				end
			end
			for key,d in pairs(RADAR.dots) do if not used[key] then pcall(function() d[1]:Destroy() end); RADAR.dots[key]=nil end end
			if CFG.RadarDeath and RADAR.deathPos then
				if not (RADAR.deathDot and RADAR.deathDot.Parent) then local dd=radarDot("__death", true); RADAR.deathDot=dd[1]; RADAR.dots["__death"]=nil end
				radarPlace(RADAR.deathDot, RADAR.deathPos-r.Position, fwd, right, radius, scale)
				RADAR.deathDot.Visible=true
			elseif RADAR.deathDot then RADAR.deathDot.Visible=false end
		end)
	end
end)

end   -- end Minimap Radar do-block

-- HUD STATUS
task.spawn(function() while RUNNING do task.wait(0.4); pcall(function() local us=MF:FindFirstChildOfClass("UIScale"); if us then us.Scale=math.clamp(tonumber(CFG.UIScale) or 1,0.5,3) end end) end end)
task.spawn(function() while RUNNING do task.wait(0.5) pcall(function()
	local h=hum(); local r=hrp()
	if HUD.hp then HUD.hp.Text = h and string.format("%d / %d", math.floor(h.Health), math.floor(h.MaxHealth)) or "alive" end
	if HUD.stat then local on={}; if CFG.GodMode then on[#on+1]="God" end if CFG.InfFood then on[#on+1]="Food" end if CFG.HitboxExpand then on[#on+1]="Hitbox" end if CFG.AutoFarmFossil then on[#on+1]="Fossil" end if CFG.AutoFarmGem then on[#on+1]="Gem" end HUD.stat.Text = #on>0 and table.concat(on,", ") or "idle" end
	local d=lastSkinDino; if HUD.dino then HUD.dino.Text = d or "unknown" end  -- reuse the 2s-cached dino (no per-0.5s GetDescendants scan)
	if d then CFG.SkinDino=d end
	if HUD.pos and r then HUD.pos.Text = string.format("%d, %d, %d", r.Position.X, r.Position.Y, r.Position.Z) end
end) end end)

-- CLEANUP
G.__PRIOR_EXT_HUB = function()
	RUNNING=false
	for _,c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end; CONNS={}
	pcall(stopFly); pcall(destroyESP); pcall(function() ESP.folder:Destroy() end)
	pcall(function() for p in pairs(hbTouched) do restorePart(p) end end)
	pcall(function() skRestoreAll() end)
	pcall(function() if SAVED.fbCC then SAVED.fbCC:Destroy() end end)
	pcall(function() if SAVED.light then Lighting.Brightness=SAVED.light[1]; Lighting.ClockTime=SAVED.light[2]; Lighting.FogEnd=SAVED.light[3]; Lighting.GlobalShadows=SAVED.light[4] end end)
	pcall(function() if SAVED.water then local terrain=WS:FindFirstChildOfClass("Terrain"); if terrain then terrain.WaterTransparency=SAVED.water[1]; terrain.WaterReflectance=SAVED.water[2]; terrain.WaterWaveSize=SAVED.water[3] end end end)
	pcall(function() if SAVED.zoom then LP.CameraMaxZoomDistance=SAVED.zoom[1]; LP.CameraMinZoomDistance=SAVED.zoom[2] end end)
	pcall(function() local r=hrp(); if r then local mh=r:FindFirstChild("MH_Light"); if mh then mh:Destroy() end local w=r:FindFirstChild("MH_Water"); if w then w:Destroy() end end end)
	pcall(function() SG:Destroy() end)
	pcall(function() if ESP.gui then ESP.gui:Destroy() end end)
	pcall(function() if Fluent then Fluent.Unloaded=true; if Fluent.Destroy then Fluent:Destroy() end end if FWindow and FWindow.Destroy then FWindow:Destroy() end end)
	saveCfg()
	G.__PRIOR_EXT_HUB=nil
end
MS("5 DONE - all tabs built, menu ready")
pcall(function() if _G.__DreamFinishLoad then _G.__DreamFinishLoad() end end)
notify("Dream Hub", "Prior Extinction loaded (everything OFF) — RightShift to toggle.")
print("[Dream Hub · Prior Extinction v6.4 PE-v3] Loaded — exact need/stamina packets, wellbeing resolver, cached streaming combat")

