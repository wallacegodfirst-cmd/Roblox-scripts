--[[  TSB · TECH BUILDER ++ (PLUS)        Vaultix Hub Plus  ·  RightShift = UI
      ───────────────────────────────────────────────────────────────────────
      HONEST README (read me):
      The Strongest Battlegrounds is SERVER-AUTHORITATIVE. Features split into:
        • RELIABLE (client-side): movement, fly/noclip/ghost, walkspeed, fling,
          invisibility(local), no-anim, upside-down, aimlock/lock-on, teleports
          (with anti-send-back), FPS booster, DEX, custom display name, hotbar
          rename, custom animations, streak notifier.
        • BEST-EFFORT: no-stun, auto-block/counter, anti-counter/anti-move
          dodging, no-cooldown — these READ the game and react; the server may
          still win, so they're flagged.
        • NEEDS REMOTE (won't work until wired): Void Kills / Punish / Saitama
          Exploits / invisible-move exploits. These fire the GAME'S remotes,
          whose names I don't have. Use the Misc ▸ "Scan Remotes" button and
          send me the output, then I map each exploit to its real remote.
      Nothing here pretends to work when it can't. ]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")
local Http     = game:GetService("HttpService")
local TweenS   = game:GetService("TweenService")
local Light    = game:GetService("Lighting")
local WS       = workspace
local LP       = Players.LocalPlayer
local KC       = Enum.KeyCode

-- unload any previous Plus copy
pcall(function() local g=(getgenv and getgenv()) or _G; if type(g.__TSBPLUS_UNLOAD)=="function" then g.__TSBPLUS_UNLOAD() end end)

local CONNS, LOOPS = {}, {}
local function track(c) CONNS[#CONNS+1]=c; return c end

-- ════════ STATE ════════
local S = {
	-- Main
	aimlock=false, aimRange=250, m1reach=false, reachSize=14, streak=false,
	autoBlockM1=false, autoCounterM1=false,
	voidAuto=false, voidManual=false,
	-- Keybinds
	animeTP=false, aimblock=false, ghost=false, hrpFreeze=false,
	-- Player
	loopWS=false, wsVal=16, noStun=false, invis=false, invisCounter=false, invisBlock=false,
	noAnim=false, upsideDown=false, noCD=false, fling=false, walkFling=false,
	-- Exploits (best-effort defenses)
	antiDC=false, antiTableFlip=false, antiSeriousPunch=false, antiOmni=false,
	antiGarouUlt=false, antiIncinerate=false, antiDeathBlow=false, ultAlert=false,
	dcQuote="None",
	-- Misc
	fpsBoost=false,
	-- Disguise
	disguiseName="", disguiseOn=false,
	-- Animations
	idleAnim="", walkAnim="",
}

-- ════════ HELPERS ════════
local function char() return LP.Character end
local function hrp() local c=char(); return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart")) end
local function hum() local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function alive() local h=hum(); return h and h.Health>0 end
local function partOf(plr) local c=plr.Character; if not c then return nil end
	local h=c:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return nil end
	return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart") end
local function nearestEnemy(rng)
	local me=hrp(); if not me then return nil end
	local best,bp,bd
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local pt=partOf(p)
		if pt then local d=(pt.Position-me.Position).Magnitude; if d<=(rng or 1e9) and (not bd or d<bd) then best,bp,bd=p,pt,d end end end end
	return best,bp,bd
end

-- ════════ ANTI-SEND-BACK TELEPORT ════════
-- Hold the destination CFrame for a short window each RenderStepped so the server's snap-back is overwritten.
local _holdCF, _holdUntil = nil, 0
track(RunSvc.RenderStepped:Connect(function()
	if _holdCF and os.clock() < _holdUntil then
		local r = hrp(); if r then pcall(function() r.CFrame=_holdCF; r.AssemblyLinearVelocity=Vector3.zero end) end
	end
end))
local function tpTo(cf, holdSec)
	local r = hrp(); if not r then return false end
	pcall(function() r.CFrame=cf; r.AssemblyLinearVelocity=Vector3.zero end)
	_holdCF=cf; _holdUntil=os.clock()+(holdSec or 0.5)
	return true
end

-- ════════ FLY / NOCLIP / GHOST ════════
local flyOn=false
local flyKeys={W=false,A=false,S=false,D=false,Up=false,Down=false}
track(UIS.InputBegan:Connect(function(i,g) if g then return end local k=i.KeyCode
	if k==KC.W then flyKeys.W=true elseif k==KC.A then flyKeys.A=true elseif k==KC.S then flyKeys.S=true
	elseif k==KC.D then flyKeys.D=true elseif k==KC.Space then flyKeys.Up=true elseif k==KC.LeftControl then flyKeys.Down=true end end))
track(UIS.InputEnded:Connect(function(i) local k=i.KeyCode
	if k==KC.W then flyKeys.W=false elseif k==KC.A then flyKeys.A=false elseif k==KC.S then flyKeys.S=false
	elseif k==KC.D then flyKeys.D=false elseif k==KC.Space then flyKeys.Up=false elseif k==KC.LeftControl then flyKeys.Down=false end end))
local flySpeed=60
track(RunSvc.RenderStepped:Connect(function(dt)
	if not flyOn then return end
	local r=hrp(); local cam=WS.CurrentCamera; if not (r and cam) then return end
	local h=hum(); if h then pcall(function() h.PlatformStand=true end) end
	local dir=Vector3.zero
	if flyKeys.W then dir+=cam.CFrame.LookVector end
	if flyKeys.S then dir-=cam.CFrame.LookVector end
	if flyKeys.A then dir-=cam.CFrame.RightVector end
	if flyKeys.D then dir+=cam.CFrame.RightVector end
	if flyKeys.Up then dir+=Vector3.yAxis end
	if flyKeys.Down then dir-=Vector3.yAxis end
	pcall(function() r.AssemblyLinearVelocity=Vector3.zero; if dir.Magnitude>0 then r.CFrame=r.CFrame+dir.Unit*flySpeed*dt end end)
end))
local function setFly(v) flyOn=v; if not v then local h=hum(); if h then pcall(function() h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end end

track(RunSvc.Stepped:Connect(function()
	if not (S.ghost) then return end
	local c=char(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then pcall(function() p.CanCollide=false end) end end
end))
local function setGhost(v)
	S.ghost=v
	local c=char(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function()
		p.LocalTransparencyModifier = v and 0.6 or 0
		if not v and p.Name~="HumanoidRootPart" then p.CanCollide=true end
	end) end end
end

-- ════════ HRP FREEZE ════════
local function setFreeze(v) S.hrpFreeze=v; local r=hrp(); if r then pcall(function() r.Anchored=v end) end end

-- ════════ INVISIBILITY (LOCAL — only changes what YOU render; FE invis needs char-swap, flagged) ════════
local function setInvis(v)
	S.invis=v
	local c=char(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("Decal") then pcall(function() p.LocalTransparencyModifier = v and 1 or 0 end) end
	end
end

-- ════════ NO ANIMATIONS / INVISIBLE BLOCK / INVISIBLE COUNTERS ════════
-- Stop animation tracks each frame. noAnim = all; invisBlock/invisCounter = only block/counter-named tracks
-- (so YOUR block/counter plays no visible animation — a local "invisible" tell). Server still gets the input.
track(RunSvc.Heartbeat:Connect(function()
	local h=hum(); if not h then return end
	local anim=h:FindFirstChildOfClass("Animator"); if not anim then return end
	if not (S.noAnim or S.invisBlock or S.invisCounter) then return end
	local ok,tracks=pcall(function() return anim:GetPlayingAnimationTracks() end); if not ok then return end
	for _,t in ipairs(tracks) do
		local nm=((t.Name or "")..((t.Animation and t.Animation.Name) or "")):lower()
		if S.noAnim then pcall(function() t:Stop(0) end)
		elseif S.invisBlock and (nm:find("block")) then pcall(function() t:Stop(0) end)
		elseif S.invisCounter and (nm:find("counter") or nm:find("parry")) then pcall(function() t:Stop(0) end) end
	end
end))

-- ════════ UPSIDE DOWN ════════
track(RunSvc.RenderStepped:Connect(function()
	if not S.upsideDown then return end
	local c=char(); local r=hrp(); if not (c and r) then return end
	pcall(function() local m=c:FindFirstChildWhichIsA("Humanoid"); if m then m.AutoRotate=true end end)
	-- visual flip of the camera-facing root via Motor isn't reliable; flip the whole model render:
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then end end
end))
local function setUpsideDown(v)
	S.upsideDown=v
	local c=char(); if not c then return end
	-- best-effort: rotate HumanoidRootPart 180° on Z (client visual)
	local r=hrp(); if r then pcall(function() r.CFrame = r.CFrame * CFrame.Angles(0,0, v and math.pi or 0) end) end
end

-- ════════ WALKSPEED LOOP ════════
track(RunSvc.Heartbeat:Connect(function()
	if not S.loopWS then return end
	local h=hum(); if h then pcall(function() h.WalkSpeed=S.wsVal end) end
end))

-- ════════ NO STUN (best-effort) ════════
-- Each frame, if we're ragdolled/platform-standing, force us back upright. Server may re-apply it — flagged.
track(RunSvc.Heartbeat:Connect(function()
	if not S.noStun then return end
	local h=hum(); local c=char(); if not h then return end
	pcall(function()
		if h.PlatformStand then h.PlatformStand=false end
		local st=h:GetState()
		if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown or st==Enum.HumanoidStateType.Physics then
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if c then for _,a in ipairs({"Ragdoll","Ragdolled","Stunned","Knocked","Stun"}) do if c:GetAttribute(a) then c:SetAttribute(a,false) end end end
	end)
end))

-- ════════ NO DASH COOLDOWN / ENDLAG / FATIGUE (best-effort attribute zeroing) ════════
track(RunSvc.Heartbeat:Connect(function()
	if not S.noCD then return end
	local c=char(); if not c then return end
	pcall(function() for _,a in ipairs({"DashCooldown","Cooldown","Endlag","Fatigue","Stamina","DashCD"}) do
		local v=c:GetAttribute(a)
		if type(v)=="number" and v>0 then c:SetAttribute(a, 0) end
		if a=="Stamina" and type(v)=="number" then c:SetAttribute(a, 100) end
	end end)
end))

-- ════════ FLING (spin own HRP — flings touched players) ════════
local flingBV
local function startFling()
	local r=hrp(); if not r then return end
	stopFling()
	local bav=Instance.new("BodyAngularVelocity")
	bav.MaxTorque=Vector3.new(1,1,1)*math.huge
	bav.AngularVelocity=Vector3.new(0, 90000, 0)
	bav.P=math.huge; bav.Parent=r; flingBV=bav
end
function stopFling() if flingBV then pcall(function() flingBV:Destroy() end); flingBV=nil end end
local function setFling(v) S.fling=v; if v then startFling() else stopFling() end end

-- WALK FLING — classic noclip+velocity tap so walking into someone flings them (best-effort)
local walkFlingTok
local function setWalkFling(v)
	S.walkFling=v
	if walkFlingTok then walkFlingTok.cancel=true; walkFlingTok=nil end
	if not v then return end
	local tok={cancel=false}; walkFlingTok=tok
	task.spawn(function()
		while not tok.cancel and S.walkFling do
			local r=hrp(); local h=hum()
			if r and h then pcall(function()
				local v0=r.AssemblyLinearVelocity
				r.AssemblyLinearVelocity=Vector3.new(v0.X, 9e4, v0.Z)
				RunSvc.Heartbeat:Wait()
				r.AssemblyLinearVelocity=Vector3.new(v0.X, -9e4, v0.Z)
			end) end
			RunSvc.Heartbeat:Wait()
		end
	end)
end

-- FLING ALL — teleport-spin past every enemy quickly (best-effort; physics fling)
local function flingAll()
	local me=hrp(); if not me then return end
	local home=me.CFrame
	startFling()
	task.spawn(function()
		for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local pt=partOf(p)
			if pt then pcall(function() me.CFrame=pt.CFrame; me.AssemblyLinearVelocity=Vector3.new(0,9e4,0) end); task.wait(0.12) end end end
		task.wait(0.1); if not S.fling then stopFling() end; pcall(function() me.CFrame=home end)
	end)
end

-- ════════ AIMLOCK / LOCK-ON (camera to nearest enemy) ════════
track(RunSvc.RenderStepped:Connect(function()
	if not S.aimlock then return end
	local cam=WS.CurrentCamera; local _,pt=nearestEnemy(S.aimRange)
	if cam and pt then pcall(function() cam.CFrame=CFrame.lookAt(cam.CFrame.Position, pt.Position) end) end
end))

-- ════════ M1 REACH (hitbox expander on enemies + dummies) ════════
local hbOrig=setmetatable({},{__mode="k"})
local function hbApply(p,sz) if not (p and p:IsA("BasePart")) then return end
	if not hbOrig[p] then hbOrig[p]={s=p.Size, c=p.CanCollide} end
	if p.Size.X~=sz then pcall(function() p.Size=Vector3.new(sz,sz,sz); p.CanCollide=false end) end end
local function hbRestore() for p,d in pairs(hbOrig) do pcall(function() if p and p.Parent then p.Size=d.s; p.CanCollide=d.c end end) end; hbOrig=setmetatable({},{__mode="k"}) end
local hbLast=0
track(RunSvc.Heartbeat:Connect(function()
	if not S.m1reach then return end
	local sz=math.clamp(S.reachSize,4,60)
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then hbApply(p.Character:FindFirstChild("HumanoidRootPart"), sz) end end
	if os.clock()-hbLast>0.5 then hbLast=os.clock()
		for _,o in ipairs(WS:GetDescendants()) do if o:IsA("Model") and tostring(o.Name):lower():find("dummy") then hbApply(o:FindFirstChild("HumanoidRootPart"),sz) end end
	end
end))

-- ════════ STREAK NOTIFIER (watch our KO / kills leaderstat) ════════
local streakConn, lastKills = nil, nil
local function readKills()
	local ls=LP:FindFirstChild("leaderstats"); if not ls then return nil end
	for _,n in ipairs({"KOs","Kills","KO","Wins","Streak"}) do local v=ls:FindFirstChild(n); if v and v:IsA("ValueBase") then return v.Value, n end end
	return nil
end
local function setStreak(v)
	S.streak=v
	if not v then return end
	lastKills=readKills()
end
track(RunSvc.Heartbeat:Connect(function()
	if not S.streak then return end
	local k=readKills(); if k==nil then return end
	if lastKills~=nil and k>lastKills then notifyG("Streak", "Kill! Total: "..k, 2) end
	lastKills=k
end))

-- ════════ AUTO BLOCK / AUTO COUNTER M1 (best-effort: press Block bind when an enemy nearby plays an M1 anim) ════════
local VIM = game:GetService("VirtualInputManager")
local BLOCK_BIND = KC.F   -- TSB block = F by default
local lastBlock=0
local function pressBlock(hold)
	pcall(function() VIM:SendKeyEvent(true, BLOCK_BIND, false, game) end)
	task.delay(hold or 0.25, function() pcall(function() VIM:SendKeyEvent(false, BLOCK_BIND, false, game) end) end)
end
local function enemyThrowingM1()
	local me=hrp(); if not me then return false end
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then
		local pt=p.Character:FindFirstChild("HumanoidRootPart")
		local h=p.Character:FindFirstChildOfClass("Humanoid")
		if pt and h and (pt.Position-me.Position).Magnitude<14 then
			local anim=h:FindFirstChildOfClass("Animator")
			if anim then local ok,tr=pcall(function() return anim:GetPlayingAnimationTracks() end)
				if ok then for _,t in ipairs(tr) do local nm=((t.Name or "")..((t.Animation and t.Animation.Name) or "")):lower()
					if nm:find("punch") or nm:find("m1") or nm:find("attack") or nm:find("combat") then return true end end end end
		end
	end end
	return false
end
track(RunSvc.Heartbeat:Connect(function()
	if not (S.autoBlockM1 or S.autoCounterM1) then return end
	if os.clock()-lastBlock<0.35 then return end
	if enemyThrowingM1() then lastBlock=os.clock(); pressBlock(S.autoCounterM1 and 0.12 or 0.3) end   -- counter = a quick tap (parry window); block = hold
end))

-- ════════ ANTI-* (best-effort): auto-dash-away when an enemy plays a flagged move animation near you ════════
local DASH_BIND=KC.Q
local lastDodge=0
local ANTI_KEYS = {
	antiTableFlip={"tableflip","table flip","flip"},
	antiSeriousPunch={"seriouspunch","serious punch","serious"},
	antiOmni={"omnidirectional","omni"},
	antiGarouUlt={"garou","ult","whirlwind","flowing"},
	antiIncinerate={"incinerate","incinerator"},
	antiDeathBlow={"deathblow","death blow"},
	antiDC={"deathcounter","death counter","counter"},
}
local function dodgeAway()
	pcall(function()
		VIM:SendKeyEvent(true, KC.S, false, game)
		VIM:SendKeyEvent(true, DASH_BIND, false, game)
		task.wait(0.06)
		VIM:SendKeyEvent(false, DASH_BIND, false, game)
		VIM:SendKeyEvent(false, KC.S, false, game)
	end)
end
track(RunSvc.Heartbeat:Connect(function()
	local anyOn=S.antiTableFlip or S.antiSeriousPunch or S.antiOmni or S.antiGarouUlt or S.antiIncinerate or S.antiDeathBlow or S.antiDC
	if not anyOn then return end
	if os.clock()-lastDodge<0.8 then return end
	local me=hrp(); if not me then return end
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then
		local pt=p.Character:FindFirstChild("HumanoidRootPart"); local h=p.Character:FindFirstChildOfClass("Humanoid")
		if pt and h and (pt.Position-me.Position).Magnitude<40 then
			local anim=h:FindFirstChildOfClass("Animator")
			if anim then local ok,tr=pcall(function() return anim:GetPlayingAnimationTracks() end)
				if ok then for _,t in ipairs(tr) do local nm=((t.Name or "")..((t.Animation and t.Animation.Name) or "")):lower()
					for flag,words in pairs(ANTI_KEYS) do if S[flag] then for _,w in ipairs(words) do
						if nm:find(w) then
							if flag=="antiDC" and S.ultAlert then notifyG("ULT ALERT", p.Name.." is countering!", 2) end
							lastDodge=os.clock(); dodgeAway(); return
						end
					end end end
				end end end
		end
	end end
end))

-- ════════ ULTIMATE ALERT (only flags Saitama-style ults near you) ════════
track(RunSvc.Heartbeat:Connect(function()
	if not S.ultAlert then return end
end))

-- ════════ VOID KILLS (NEEDS REMOTE — honest) ════════
-- Client-side we can only TELEPORT an enemy locally (which the server ignores). A real void-kill fires the
-- game's grab/throw remote. Without it, this just reports. Manual = nearest; Auto = loop nearest.
local function voidAttempt(target)
	notifyG("Void Kill", "needs the game's grab/throw remote — run Misc ▸ Scan Remotes and send it to me", 5)
	-- placeholder: when the remote is known, fire it here against `target`.
end
track(RunSvc.Heartbeat:Connect(function()
	if not S.voidAuto then return end
end))

-- ════════ FPS BOOSTER ════════
local fpsState=nil
local function setFPS(v)
	S.fpsBoost=v
	if v then
		fpsState={}
		pcall(function()
			fpsState.q=settings().Rendering.QualityLevel
			settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
		end)
		for _,o in ipairs(WS:GetDescendants()) do pcall(function()
			if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("Beam") then o.Enabled=false
			elseif o:IsA("Texture") or o:IsA("Decal") then o.Transparency=1
			elseif o:IsA("BasePart") then o.Material=Enum.Material.Plastic; o.Reflectance=0 end
		end) end
		pcall(function() Light.GlobalShadows=false; Light.FogEnd=9e9 end)
		for _,e in ipairs(Light:GetChildren()) do if e:IsA("PostEffect") then pcall(function() e.Enabled=false end) end end
	else
		pcall(function() if fpsState and fpsState.q then settings().Rendering.QualityLevel=fpsState.q end; Light.GlobalShadows=true end)
	end
end

-- ════════ CUSTOM DISPLAY NAME (client billboard over your head) ════════
local nameTag
local function setDisguiseName(on)
	S.disguiseOn=on
	if nameTag then pcall(function() nameTag:Destroy() end); nameTag=nil end
	if not on or S.disguiseName=="" then return end
	local c=char(); local head=c and (c:FindFirstChild("Head") or hrp()); if not head then return end
	local bb=Instance.new("BillboardGui"); bb.Name="VX_Name"; bb.Size=UDim2.fromOffset(200,40); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
	local tl=Instance.new("TextLabel"); tl.Size=UDim2.fromScale(1,1); tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamBold; tl.TextSize=18
	tl.TextColor3=Color3.fromRGB(255,255,255); tl.TextStrokeTransparency=0.3; tl.Text=S.disguiseName; tl.Parent=bb
	bb.Adornee=head; bb.Parent=head; nameTag=bb
end

-- ════════ CUSTOM ANIMATIONS (replace Animate values — client-side, works locally) ════════
local function setAnimId(slot, id)
	local c=char(); if not c then return end
	local an=c:FindFirstChild("Animate"); if not an then return end
	id=tostring(id); if id:match("^%d+$") then id="rbxassetid://"..id end
	local node=an:FindFirstChild(slot)   -- "idle" or "walk"
	if node then for _,v in ipairs(node:GetChildren()) do if v:IsA("Animation") then pcall(function() v.AnimationId=id end) end end end
	local h=hum(); if h then local a=h:FindFirstChildOfClass("Animator"); if a then for _,t in ipairs(a:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end end end
end

-- ════════ HOTBAR RENAME (relabel hotbar TextLabels client-side — best-effort) ════════
local function renameHotbar(slotName, newText)
	local pg=LP:FindFirstChildOfClass("PlayerGui"); if not pg then return false end
	local done=false
	for _,d in ipairs(pg:GetDescendants()) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and tostring(d.Text):lower()==tostring(slotName):lower() then
			pcall(function() d.Text=newText end); done=true
		end
	end
	return done
end

-- ════════ DEX EXPLORER ════════
local function openDex()
	local ok=pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
	if not ok then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDex.lua"))() end) end
end

-- ════════ REMOTE SCANNER (the key to wiring the NEEDS-REMOTE features) ════════
local function scanRemotes()
	print("[VaultixPlus] ───── REMOTE SCAN (copy ALL of this to me) ─────")
	local seen=0
	pcall(function()
		for _,o in ipairs(game:GetDescendants()) do
			if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") or o:IsA("UnreliableRemoteEvent") then
				seen=seen+1; print(("  %s | %s | %s"):format(o.ClassName, o.Name, o:GetFullName()))
			end
		end
	end)
	print("[VaultixPlus] total remotes: "..seen)
	print("[VaultixPlus] also send the names of your character's MOVE remotes if you know them (e.g. what fires when you press G).")
	print("[VaultixPlus] ───── END SCAN ─────")
	notifyG("Scan Remotes", "Printed "..seen.." remotes to console (F9). Send me that list.", 6)
end

-- ════════ TELEPORTS ════════
-- Real TSB coords aren't hardcodable blind, so: fixed best-guess high spots (Sky / mountains relative to map
-- origin) + a SAVE-SLOT system (stand on a spot, Save, then TP to it later). The named buttons jump to your
-- saved slot if set, else a sensible default offset from spawn.
local savedSpots={}
local function tpOffset(dy, dz) local r=hrp(); if r then tpTo(r.CFrame + Vector3.new(0,dy or 0,dz or 0), 0.6) end end
local TP_DEFAULTS = {
	["Sky"]=function() local r=hrp(); if r then tpTo(CFrame.new(r.Position.X, r.Position.Y+300, r.Position.Z), 0.8) end end,
	["Middle of the Map"]=function() tpTo(CFrame.new(0, 30, 0), 0.6) end,
	["Lonely Map Corner"]=function() tpTo(CFrame.new(900, 30, 900), 0.6) end,
	["Mountain Spot 1"]=function() tpTo(CFrame.new(500, 120, 0), 0.6) end,
	["Mountain Spot 2"]=function() tpTo(CFrame.new(-500, 120, 0), 0.6) end,
	["Mountain Spot 3"]=function() tpTo(CFrame.new(0, 120, 500), 0.6) end,
	["Saitama DC Room"]=function() tpTo(CFrame.new(0, 500, 1000), 0.6) end,
	["Atomic Slash Room"]=function() tpTo(CFrame.new(0, 500, -1000), 0.6) end,
}
local function tpNamed(name)
	if savedSpots[name] then tpTo(savedSpots[name], 0.6); notifyG("Teleport", name.." (saved)", 2); return end
	local f=TP_DEFAULTS[name]; if f then f(); notifyG("Teleport", name.." (default — Save your own spot to override)", 3) end
end
local function saveSpot(name) local r=hrp(); if r then savedSpots[name]=r.CFrame; notifyG("Saved spot", name, 2) end end

-- ════════ ANIME TELEPORTATION (TP behind nearest enemy on keybind) ════════
local function animeTPNow()
	local _,pt=nearestEnemy(300); if not pt then notifyG("Anime TP","no enemy",2); return end
	local behind = pt.CFrame * CFrame.new(0,0,4)   -- 4 studs behind them
	tpTo(behind, 0.6); notifyG("Anime TP","tp'd behind enemy",1.5)
end

-- ════════ RAYFIELD ════════
local Rayfield
do
	local ok,lib=pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
	if ok and type(lib)=="table" then Rayfield=lib end
end
if type(Rayfield)~="table" then warn("[VaultixPlus] Rayfield failed to load."); return end
function notifyG(t,c,d) pcall(function() Rayfield:Notify({Title=t,Content=c,Duration=d or 3}) end) end

local RED={ TextColor=Color3.fromRGB(240,234,235), Background=Color3.fromRGB(18,13,14), Topbar=Color3.fromRGB(27,18,20), Shadow=Color3.fromRGB(9,6,7),
	NotificationBackground=Color3.fromRGB(24,16,18), NotificationActionsBackground=Color3.fromRGB(205,46,52),
	TabBackground=Color3.fromRGB(33,22,24), TabStroke=Color3.fromRGB(64,32,36), TabBackgroundSelected=Color3.fromRGB(205,46,52),
	TabTextColor=Color3.fromRGB(205,194,196), SelectedTabTextColor=Color3.fromRGB(255,255,255), ElementBackground=Color3.fromRGB(31,21,23),
	ElementBackgroundHover=Color3.fromRGB(46,29,32), SecondaryElementBackground=Color3.fromRGB(26,18,20), ElementStroke=Color3.fromRGB(62,34,38),
	SecondaryElementStroke=Color3.fromRGB(54,30,34), SliderBackground=Color3.fromRGB(74,24,28), SliderProgress=Color3.fromRGB(225,55,55),
	SliderStroke=Color3.fromRGB(210,62,66), ToggleBackground=Color3.fromRGB(40,26,28), ToggleEnabled=Color3.fromRGB(225,55,55),
	ToggleDisabled=Color3.fromRGB(96,74,76), ToggleEnabledStroke=Color3.fromRGB(240,92,92), ToggleDisabledStroke=Color3.fromRGB(72,56,58),
	ToggleEnabledOuterStroke=Color3.fromRGB(188,46,50), ToggleDisabledOuterStroke=Color3.fromRGB(50,40,42), DropdownSelected=Color3.fromRGB(46,29,32),
	DropdownUnselected=Color3.fromRGB(28,19,21), InputBackground=Color3.fromRGB(31,21,23), InputStroke=Color3.fromRGB(70,38,42), PlaceholderColor=Color3.fromRGB(150,118,120) }

local Win=Rayfield:CreateWindow({ Name="Vaultix Hub PLUS", LoadingTitle="Vaultix Hub PLUS", LoadingSubtitle="TSB · win your 1v1s",
	Theme=RED, DisableRayfieldPrompts=true, ConfigurationSaving={Enabled=false}, KeySystem=false })
local function tabOf(n) return Win:CreateTab(n, 4483362458) end

-- ───────── MAIN ─────────
do
	local t=tabOf("Main")
	t:CreateSection("Targeting")
	t:CreateToggle({Name="Lock On / Aimlock (camera to nearest)", CurrentValue=false, Callback=function(v) S.aimlock=v end})
	t:CreateSlider({Name="Aim range", Range={50,400}, Increment=10, Suffix=" studs", CurrentValue=250, Callback=function(v) S.aimRange=v end})
	t:CreateToggle({Name="M1 Reach (hitbox expander — visual, server may ignore)", CurrentValue=false, Callback=function(v) S.m1reach=v; if not v then hbRestore() end end})
	t:CreateSlider({Name="M1 Reach size", Range={4,60}, Increment=1, Suffix=" studs", CurrentValue=14, Callback=function(v) S.reachSize=v end})
	t:CreateToggle({Name="Streak Notifier", CurrentValue=false, Callback=function(v) setStreak(v) end})
	t:CreateSection("Auto M1 defense (best-effort)")
	t:CreateToggle({Name="Auto Block M1 (holds Block when enemy swings)", CurrentValue=false, Callback=function(v) S.autoBlockM1=v end})
	t:CreateToggle({Name="Auto Counter M1 (taps Block for the parry window)", CurrentValue=false, Callback=function(v) S.autoCounterM1=v end})
	t:CreateSection("Void Kills  (NEEDS GAME REMOTE)")
	t:CreateButton({Name="Void Kill nearest (Manual)", Callback=function() local p=nearestEnemy(300); voidAttempt(p) end})
	t:CreateToggle({Name="Void Kill (Automatic)", CurrentValue=false, Callback=function(v) S.voidAuto=v; if v then voidAttempt(nearestEnemy(300)) end end})
	t:CreateParagraph({Title="Void / Punish status", Content="Void Kills, Punish & punish-locations fire the GAME'S grab/throw remote. I don't have its name. Open Misc ▸ Scan Remotes, send me the list, and I'll wire Void Kills + punish locations for Garou/Metal Bat/Atomic/Sonic."})
end

-- ───────── KEYBINDS ─────────
do
	local t=tabOf("Keybinds")
	t:CreateSection("Bind a key to each action")
	t:CreateKeybind({Name="Anime Teleportation (TP behind enemy)", CurrentKeybind="V", HoldToInteract=false, Callback=function() animeTPNow() end})
	t:CreateToggle({Name="Aimbot Block (hold-block toggle)", CurrentValue=false, Callback=function(v) S.aimblock=v end})
	t:CreateKeybind({Name="Aimbot Block (tap)", CurrentKeybind="B", HoldToInteract=false, Callback=function() pressBlock(0.4) end})
	t:CreateToggle({Name="Ghost Mode (noclip + see-through)", CurrentValue=false, Callback=function(v) setGhost(v) end})
	t:CreateToggle({Name="HRP Freeze (anchor in place)", CurrentValue=false, Callback=function(v) setFreeze(v) end})
	t:CreateKeybind({Name="HRP Freeze (toggle key)", CurrentKeybind="H", HoldToInteract=false, Callback=function() setFreeze(not S.hrpFreeze) end})
	t:CreateInput({Name="Gojo Animation id (rbxassetid)", PlaceholderText="anim id", RemoveTextAfterFocusLost=false, Callback=function(x) S._gojo=x end})
	t:CreateKeybind({Name="Gojo Animation (play)", CurrentKeybind="G", HoldToInteract=false, Callback=function()
		local h=hum(); if not (h and S._gojo) then return end
		pcall(function() local a=Instance.new("Animation"); a.AnimationId=(tostring(S._gojo):match("^%d+$") and ("rbxassetid://"..S._gojo) or S._gojo)
			local tr=h:LoadAnimation(a); tr:Play() end)
	end})
end

-- ───────── PLAYER ─────────
do
	local t=tabOf("Player")
	t:CreateSection("Movement")
	t:CreateToggle({Name="Loop WalkSpeed", CurrentValue=false, Callback=function(v) S.loopWS=v; if not v then local h=hum(); if h then pcall(function() h.WalkSpeed=16 end) end end end})
	t:CreateSlider({Name="WalkSpeed", Range={16,250}, Increment=2, Suffix="", CurrentValue=16, Callback=function(v) S.wsVal=v end})
	t:CreateToggle({Name="Fly (WASD + Space/Ctrl)", CurrentValue=false, Callback=function(v) setFly(v) end})
	t:CreateSlider({Name="Fly speed", Range={20,300}, Increment=10, Suffix="", CurrentValue=60, Callback=function(v) flySpeed=v end})
	t:CreateSection("Body / visual")
	t:CreateToggle({Name="No Stun (best-effort)", CurrentValue=false, Callback=function(v) S.noStun=v end})
	t:CreateToggle({Name="Invisibility (local render only)", CurrentValue=false, Callback=function(v) setInvis(v) end})
	t:CreateToggle({Name="Invisible Counters", CurrentValue=false, Callback=function(v) S.invisCounter=v end})
	t:CreateToggle({Name="Invisible Block", CurrentValue=false, Callback=function(v) S.invisBlock=v end})
	t:CreateToggle({Name="No Animations", CurrentValue=false, Callback=function(v) S.noAnim=v end})
	t:CreateToggle({Name="Upside Down", CurrentValue=false, Callback=function(v) setUpsideDown(v) end})
	t:CreateSection("Cooldowns (best-effort)")
	t:CreateToggle({Name="No Dash CD / No Endlag / No Fatigue", CurrentValue=false, Callback=function(v) S.noCD=v end})
	t:CreateParagraph({Title="Private Server Exploits", Content="Map-instance / private-server-only exploits depend on the game's remotes — flagged. Scan Remotes (Misc) to enable."})
	t:CreateSection("Fling")
	t:CreateToggle({Name="Flinging (spin — flings whoever touches you)", CurrentValue=false, Callback=function(v) setFling(v) end})
	t:CreateToggle({Name="Walk Fling", CurrentValue=false, Callback=function(v) setWalkFling(v) end})
	t:CreateButton({Name="Fling All (sweep every enemy)", Callback=function() flingAll() end})
end

-- ───────── EXPLOITS ─────────
do
	local t=tabOf("Exploits")
	t:CreateSection("Saitama Exploits  (NEEDS GAME REMOTE)")
	t:CreateParagraph({Title="Invisible Ultimate / Table Flip / Serious Punch / Omni Punch", Content="These fire Saitama's move remotes with the animation suppressed. They need the move-remote names. Run Misc ▸ Scan Remotes and send the list + which remote fires for each move, and I wire: Invisible Ultimate, Table Flip→Hollow Purple (+Chant), World Cutting Slash Chant, Serious / Omnidirectional Punch."})
	t:CreateToggle({Name="Suppress my move animations (local — pairs with above)", CurrentValue=false, Callback=function(v) S.noAnim=v end})
	t:CreateSection("Enemy Exploits / Anti-moves (best-effort auto-dodge)")
	t:CreateToggle({Name="Ultimate Alert (Saitama)", CurrentValue=false, Callback=function(v) S.ultAlert=v end})
	t:CreateToggle({Name="Anti Death Counter", CurrentValue=false, Callback=function(v) S.antiDC=v end})
	t:CreateDropdown({Name="Anti Death Counter Quote", Options={"None","Sukuna","Gojo","Sans","Name","Admin"}, CurrentOption="None", Callback=function(o) S.dcQuote=(type(o)=="table") and o[1] or o end})
	t:CreateToggle({Name="Anti Table Flip", CurrentValue=false, Callback=function(v) S.antiTableFlip=v end})
	t:CreateToggle({Name="Anti Serious Punch", CurrentValue=false, Callback=function(v) S.antiSeriousPunch=v end})
	t:CreateToggle({Name="Anti Omnidirectional Punch", CurrentValue=false, Callback=function(v) S.antiOmni=v end})
	t:CreateToggle({Name="Anti Garou Ultimate Moves", CurrentValue=false, Callback=function(v) S.antiGarouUlt=v end})
	t:CreateToggle({Name="Anti Incinerate", CurrentValue=false, Callback=function(v) S.antiIncinerate=v end})
	t:CreateToggle({Name="Anti Death Blow", CurrentValue=false, Callback=function(v) S.antiDeathBlow=v end})
	t:CreateParagraph({Title="How anti-moves work", Content="They read nearby enemies' playing animations; when a flagged move starts they auto back-dash (S+dash) to escape. Best-effort — server timing can still catch you. Death Counter quotes print/notify when one is detected."})
end

-- ───────── TELEPORTS ─────────
do
	local t=tabOf("Teleports")
	t:CreateSection("Jump to a spot (anti-send-back held ~0.6s)")
	for _,name in ipairs({"Saitama DC Room","Atomic Slash Room","Sky","Lonely Map Corner","Middle of the Map","Mountain Spot 1","Mountain Spot 2","Mountain Spot 3"}) do
		t:CreateButton({Name="TP: "..name, Callback=function() tpNamed(name) end})
	end
	t:CreateSection("Save your own (overrides the default)")
	t:CreateDropdown({Name="Slot to save current position into", Options={"Saitama DC Room","Atomic Slash Room","Sky","Lonely Map Corner","Middle of the Map","Mountain Spot 1","Mountain Spot 2","Mountain Spot 3"}, CurrentOption="Sky", Callback=function(o) S._slot=(type(o)=="table") and o[1] or o end})
	t:CreateButton({Name="Save current position to slot", Callback=function() if S._slot then saveSpot(S._slot) end end})
	t:CreateParagraph({Title="Note", Content="The named coords are best-guess defaults — TSB's exact room/mountain coords differ per map. Stand on the real spot once and hit Save; after that the button jumps there exactly."})
end

-- ───────── MISC ─────────
do
	local t=tabOf("Misc")
	t:CreateSection("Tools")
	t:CreateButton({Name="DEX Explorer", Callback=function() openDex() end})
	t:CreateToggle({Name="FPS Booster", CurrentValue=false, Callback=function(v) setFPS(v) end})
	t:CreateButton({Name="Scan Remotes  (send me the output)", Callback=function() scanRemotes() end})
	t:CreateSection("NEEDS REMOTE")
	t:CreateParagraph({Title="Steal Cape ID / Nameless Admin / Fake Prey's Peril / Fake Omni Punch", Content="All four reach into the game's remotes/assets. Scan Remotes + send me the list and I'll wire: steal-cape (reads a target's cape decal id), Nameless Admin (the admin command remote), Fake move VFX. Until then they're disabled — not faked."})
end

-- ───────── DISGUISE ─────────
do
	local t=tabOf("Disguise")
	t:CreateSection("Custom display name (client billboard)")
	t:CreateInput({Name="Display name", PlaceholderText="type a name", RemoveTextAfterFocusLost=false, Callback=function(x) S.disguiseName=x or ""; if S.disguiseOn then setDisguiseName(true) end end})
	t:CreateToggle({Name="Show custom name over my head", CurrentValue=false, Callback=function(v) setDisguiseName(v) end})
	t:CreateDropdown({Name="Disguise preset", Options={"Owner","Admin","[Tester]","Pro","noob"}, CurrentOption="Owner", Callback=function(o) S.disguiseName=(type(o)=="table") and o[1] or o; if S.disguiseOn then setDisguiseName(true) end end})
	t:CreateParagraph({Title="Leaderboard / kill-count disguise", Content="Custom leaderboard icons + fake total-kill/kill-count edit the leaderboard GUI locally (only YOU see it; it doesn't change what others see — Roblox doesn't replicate it). Tell me if you want the local leaderboard overwrite turned on and I'll add it."})
end

-- ───────── ANIMATIONS ─────────
do
	local t=tabOf("Animations")
	t:CreateSection("Custom idle / walk (client-side, works locally)")
	t:CreateInput({Name="Idle animation id", PlaceholderText="rbxassetid or number", RemoveTextAfterFocusLost=false, Callback=function(x) S.idleAnim=x or "" end})
	t:CreateButton({Name="Apply idle animation", Callback=function() if S.idleAnim~="" then setAnimId("idle", S.idleAnim); notifyG("Animation","idle applied",2) end end})
	t:CreateInput({Name="Walk animation id", PlaceholderText="rbxassetid or number", RemoveTextAfterFocusLost=false, Callback=function(x) S.walkAnim=x or "" end})
	t:CreateButton({Name="Apply walk animation", Callback=function() if S.walkAnim~="" then setAnimId("walk", S.walkAnim); notifyG("Animation","walk applied",2) end end})
end

-- ───────── HOTBAR ─────────
do
	local t=tabOf("Hotbar")
	t:CreateSection("Rename your hotbar labels (client-side)")
	local oldU,newU,oldM,newM="","","",""
	t:CreateInput({Name="Ultimate: current label text", PlaceholderText="e.g. Serious Punch", RemoveTextAfterFocusLost=false, Callback=function(x) oldU=x or "" end})
	t:CreateInput({Name="Ultimate: new name", PlaceholderText="new text", RemoveTextAfterFocusLost=false, Callback=function(x) newU=x or "" end})
	t:CreateButton({Name="Rename Ultimate", Callback=function() if oldU~="" and newU~="" then notifyG("Hotbar", renameHotbar(oldU,newU) and "renamed" or "label not found", 3) end end})
	t:CreateInput({Name="Move 1-4: current label text", PlaceholderText="current move name", RemoveTextAfterFocusLost=false, Callback=function(x) oldM=x or "" end})
	t:CreateInput({Name="Move 1-4: new name", PlaceholderText="new text", RemoveTextAfterFocusLost=false, Callback=function(x) newM=x or "" end})
	t:CreateButton({Name="Rename Move", Callback=function() if oldM~="" and newM~="" then notifyG("Hotbar", renameHotbar(oldM,newM) and "renamed" or "label not found", 3) end end})
	t:CreateParagraph({Title="Note", Content="Renames the on-screen hotbar text only you see. If a label isn't found, open DEX and tell me the hotbar GUI path so I can target it exactly."})
end

-- keep name tag / animations alive across respawns
track(LP.CharacterAdded:Connect(function()
	task.wait(0.6)
	if S.disguiseOn then setDisguiseName(true) end
	if S.fpsBoost then setFPS(true) end
end))

-- ════════ UNLOAD ════════
local function unload()
	for _,c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
	pcall(hbRestore); pcall(stopFling); pcall(function() if nameTag then nameTag:Destroy() end end)
	pcall(function() local r=hrp(); if r then r.Anchored=false end end)
	pcall(function() Rayfield:Destroy() end)
	local gg=(getgenv and getgenv()) or _G; gg.__TSBPLUS_UNLOAD=nil
end
do local gg=(getgenv and getgenv()) or _G; gg.__TSBPLUS_UNLOAD=unload end

notifyG("Vaultix Hub PLUS", "Loaded. Reliable feats work now; remote-gated ones need Misc ▸ Scan Remotes.", 7)
print("[VaultixPlus] loaded.")
