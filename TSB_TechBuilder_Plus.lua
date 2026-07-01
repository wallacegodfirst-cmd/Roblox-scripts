--[[  TSB · TECH BUILDER          RightShift = open/close UI  ·  T = run  ·  C = lock-on  ]]

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")
local Http     = game:GetService("HttpService")
local VIM      = game:GetService("VirtualInputManager")
local WS       = workspace
local LP       = Players.LocalPlayer
local KC       = Enum.KeyCode

-- ════════ UNLOAD A PREVIOUS COPY (so connections never stack across re-runs) ════════
pcall(function()
	local g = (getgenv and getgenv()) or _G
	if type(g.__TSB_UNLOAD)=="function" then g.__TSB_UNLOAD() end
end)

-- ════════ RELEASE A STUCK CLICK FROM "EXECUTE" ════════
-- The executor's Execute press can leave the LEFT mouse button held down → the game auto-M1s on load.
-- Force a mouse-button-UP a few times over the first second so nothing punches until YOU press Run/T.
do
	local function _relMouse() pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end) end
	_relMouse()
	for _,t in ipairs({0.2, 0.5, 1.0}) do task.delay(t, _relMouse) end
end

-- ════════ FILE IO SHIMS ════════
local f_write = writefile or function() end
local f_read  = readfile  or function() return nil end
local f_is    = isfile    or function() return false end
local f_list  = listfiles or function() return {} end
local f_del   = delfile
local HAS_IO  = (writefile~=nil and readfile~=nil and isfile~=nil)   -- real file access? (Save/Load need it)
local CFG_FILE = "TSB_TechBuilder_config.json"
local PREFIX   = "TSB_Tech_"
local STEP_VERSION = 3   -- bump when the step format changes; migration handles older files

-- ════════ CONFIG ════════
local DEFAULT_BINDS = { M1="MouseButton1", Dash="Q", Block="F", Jump="Space", Run="W",
                        Ultimate="G", Skill1="One", Skill2="Two", Skill3="Three", Skill4="Four" }
function cloneTbl(t) local o={}; for k,v in pairs(t) do o[k]=v end; return o end
local CFG = {
	version = STEP_VERSION,
	comboSpeed = 0.8,      -- scales ALL timings (gaps AND holds). 1=normal, lower=faster, higher=slower.
	loop = false, loopDelay = 350,
	lockOn = false, lockRange = 180, smoothLock = 0.0, retarget = false, lockDist = 12, lockHeight = 4.5,  -- console lock-on: camera distance behind you + height
	aimMove = true,          -- face the target right before a dash/move so left/right is TARGET-RELATIVE (strafe around enemy)
	hitbox = false, hitboxSize = 12, approach = false,   -- hitbox expander (enemy hit-part size) + auto-approach the target on run
	autoCombo = false, smartCD = true, skillCD = 8, fightStopDist = 35, smartEngage = true,   -- auto-chain + skill-CD M1-sub + far-stop + dash-in re-engage (never whiff into empty air)
	smartCombat = true, meleeRange = 16, autoEvade = false, antiCounter = false, evadeDir = "Right", lockImage = "", dashToTarget = true, sweat = false,   -- dashToTarget = every combo dash goes INTO the enemy; sweat = shift-lock flick + side-dash during M1s (Sweaty+ combos)
	chase = true, chaseSecs = 1.2,   -- REWORK: default ON but BOUNDED (~1.2s) so combos actually CLOSE on the enemy and land, without the old endless noob-running
	autoBlock = false, autoBlockRange = 14,   -- tap Block when a nearby enemy is mid-attack and we're NOT comboing (defensive layer for 1v1s)
	stopOnDeath = true, debug = false,
	runMode = "Toggle",    -- "Toggle" or "Hold" the run key
	mobileBar = false,     -- floating always-visible Run/Stop/Lock/Test bar (for touch / no keyboard)
	favs = {},             -- favourite presets
	m1Profile = "Normal",    -- M1 ping timing profile: Safe(420) / Normal(360) / Fast(300) / HighPing(450)
	uiScale = 1.0, accentIndex = 1,
	runKey = "T", uiKey = "RightShift", lockKey = "C",
	binds = cloneTbl(DEFAULT_BINDS),
}
local function saveCfg() pcall(function() f_write(CFG_FILE, Http:JSONEncode(CFG)) end) end
local function loadCfg()
	pcall(function() if f_is(CFG_FILE) then local t=Http:JSONDecode(f_read(CFG_FILE)); if type(t)=="table" then
		local SKIP={binds=true, lockOn=true, autoCombo=true, hitbox=true, sweat=true, chase=true}   -- NEVER auto-restore camera-hijack / auto-run / placebo states on load (they must start OFF so the script never grabs control uninvited)
		for k,v in pairs(t) do if not SKIP[k] then CFG[k]=v end end
		if type(t.binds)=="table" then for k,v in pairs(t.binds) do CFG.binds[k]=v end end
	end end end)
	CFG.version = STEP_VERSION
end
loadCfg()

-- ════════ THEME ════════
local ACCENTS = { Color3.fromRGB(225,55,55), Color3.fromRGB(236,72,120), Color3.fromRGB(64,184,255),
                  Color3.fromRGB(72,210,140), Color3.fromRGB(255,170,60), Color3.fromRGB(255,86,86) }
local T = {
	Accent = ACCENTS[CFG.accentIndex] or ACCENTS[1],
	BG = Color3.fromRGB(14,14,18), Panel = Color3.fromRGB(23,23,29),
	Panel2 = Color3.fromRGB(33,33,41), Panel3 = Color3.fromRGB(47,47,57),
	Text = Color3.fromRGB(239,239,245), Dim = Color3.fromRGB(140,140,152),
	Stroke = Color3.fromRGB(44,44,54), Good = Color3.fromRGB(86,206,128),
	Bad = Color3.fromRGB(224,72,78),
}

-- ════════ CONNECTION TRACKING (for clean unload — no stacking) ════════
local CONNS = {}
local function track(conn) CONNS[#CONNS+1]=conn; return conn end

-- ════════ INPUT PRIMITIVES (replay engine) ════════
-- HELD tracks every key/mouse-button currently pressed down so a Stop can release
-- ALL of them instantly (no key left stuck down).  keys: HELD[keycode]=true ; mouse: HELD["M1"/"M2"]=Vector2(pos)
local HELD = {}
local win  -- the builder window (assigned when the GUI is built) — used so replayed M1 clicks land in the GAME, not the UI
local OVERLAYS = {}  -- popups/overlays (step editor, dropdowns, mobile bar) M1 must ALSO avoid, not just the main window
function regOverlay(f)   if f then OVERLAYS[f]=true end end
function overRect(mp, inst)
	if not inst or not inst.Parent or not inst.Visible then return false end
	local p,sz = inst.AbsolutePosition, inst.AbsoluteSize
	return mp.X>=p.X-6 and mp.X<=p.X+sz.X+6 and mp.Y>=p.Y-6 and mp.Y<=p.Y+sz.Y+6
end
-- isPointerOverBuilderUI: cursor over the window OR any open popup/overlay → a replayed M1 must be redirected into the game
function isPointerOverBuilderUI()
	local mp = UIS:GetMouseLocation()
	if win and win.Visible and overRect(mp, win) then return true end
	for f in pairs(OVERLAYS) do if overRect(mp, f) then return true end end
	return false
end
local REPLAYING = false   -- true while a tech/test replays → M1 ALWAYS clicks the game centre, never a UI button (works with ANY UI lib)
local lockTarget, lockPart   -- lock-on target (declared here so gameClickPos can aim replayed M1 clicks at the enemy)
function gameClickPos()
	if REPLAYING or isPointerOverBuilderUI() then
		local cam = WS.CurrentCamera
		if cam and lockPart and lockPart.Parent then                          -- click ON the locked enemy's on-screen position (not blind centre)
			local sp = cam:WorldToViewportPoint(lockPart.Position)
			if sp.Z > 0 then return Vector2.new(sp.X, sp.Y) end               -- Z>0 = in front of the camera / on screen
		end
		local vp = (cam and cam.ViewportSize) or Vector2.new(1280,720)
		return Vector2.new(vp.X*0.5, vp.Y*0.5)                                -- fallback: screen centre (still hits the game, not the UI)
	end
	return UIS:GetMouseLocation()
end
local function kDown(kc) if not kc then return end HELD[kc]=true;  pcall(function() VIM:SendKeyEvent(true,  kc, false, game) end) end
local function kUp(kc)   if not kc then return end HELD[kc]=nil;   pcall(function() VIM:SendKeyEvent(false, kc, false, game) end) end
local function mDown(btn) local p=gameClickPos(); HELD[btn==0 and "M1" or "M2"]=p; pcall(function() VIM:SendMouseButtonEvent(p.X,p.Y,btn,true, game,0) end) end
local function mUp(btn)   local key=btn==0 and "M1" or "M2"; local p=HELD[key] or gameClickPos(); HELD[key]=nil; pcall(function() VIM:SendMouseButtonEvent(p.X,p.Y,btn,false,game,0) end) end
function releaseAll()   -- release everything currently held (instant Stop safety)
	for k,v in pairs(HELD) do
		if k=="M1" then pcall(function() VIM:SendMouseButtonEvent(v.X,v.Y,0,false,game,0) end)
		elseif k=="M2" then pcall(function() VIM:SendMouseButtonEvent(v.X,v.Y,1,false,game,0) end)
		else pcall(function() VIM:SendKeyEvent(false,k,false,game) end) end
	end
	HELD = {}
end
-- releaseMovement: HARD-release every movement key (W/A/S/D/Space/Shift + the Run bind) right now.
-- This is the fix for "the character keeps running like a noob" — after any step/stop we make 100% sure
-- no directional key is left held down, even if a wait got cancelled mid-press.
function releaseMovement()
	for _,kc in ipairs({KC.W, KC.A, KC.S, KC.D, KC.Space, KC.LeftShift}) do
		HELD[kc]=nil; pcall(function() VIM:SendKeyEvent(false, kc, false, game) end)
	end
	local rk = CFG.binds and CFG.binds.Run
	if rk and KC[rk] then HELD[KC[rk]]=nil; pcall(function() VIM:SendKeyEvent(false, KC[rk], false, game) end) end
end

-- ════════ CANCELLABLE TIMING ENGINE ════════
-- waitFor: yields in small steps and bails the instant token.cancel flips → Stop is immediate.
local function waitFor(secs, token)
	if secs<=0 then return not (token and token.cancel) end
	local t0 = os.clock()
	while os.clock()-t0 < secs do
		if token and token.cancel then return false end
		RunSvc.Heartbeat:Wait()
	end
	return not (token and token.cancel)
end
-- Combo Speed scales EVERYTHING. gapWait = delays/gaps; holdWait = key/click holds (floored 25ms so a press always registers).
local function gapWait(ms, token)  return waitFor((ms or 0)/1000  * (CFG.comboSpeed or 1), token) end
function holdWait(ms, token) return waitFor(math.max((ms or 35)/1000 * (CFG.comboSpeed or 1), 0.025), token) end
-- gapWaitFloored: a gap that scales with Combo Speed but never drops below floorMs (so M1 reps can't merge even when sped up)
function gapWaitFloored(ms, floorMs, token) return waitFor(math.max((ms or 0)/1000 * (CFG.comboSpeed or 1), (floorMs or 0)/1000), token) end

-- ════════ CHARACTER / TARGET HELPERS ════════
local function myChar() return LP.Character end
local function myHRP() local c=myChar(); return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart")) end
local function myHum() local c=myChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function alive() local h=myHum(); return h and h.Health>0 end
local function partOf(plr)
	local c=plr.Character; if not c then return nil end
	local h=c:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return nil end
	return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart")
end
function nearestEnemy()   -- nearest living enemy player within lockRange
	local me=myHRP(); if not me then return nil end
	local best, bestPart, bd
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP then
			local p=partOf(plr)
			if p then local d=(p.Position-me.Position).Magnitude; if d<=CFG.lockRange and (not bd or d<bd) then best,bestPart,bd=plr,p,d end end
		end
	end
	return best, bestPart, bd
end

-- ════════ SHARED STATE + FORWARD DECLS ════════
local seq = {}
local STATE, curToken = "idle", nil     -- state machine: idle | running | recording | stopped
local runHeld, lastRunStart, lastTrig = false, 0, 0  -- run-key: Hold-mode flag, run-start time, trigger debounce
local nearestDummyPart  -- fwd: lock-on reuses it so it also locks training dummies (lobby practice)
local rebuildSteps, onLockChanged, onRunDone  -- fwd (assigned by GUI)
local statusSet, reportSet, setRunRow, logSet  -- fwd (assigned by GUI); logSet = Debug input-log render
local lastReport = {}                    -- per-step results of the most recent run (row/label/status/reason)
local lastStatusByRow = {}               -- row index -> "ok"/"fail"/"err" so step rows tint after a run
local inputLog = {}                       -- detailed per-step input log for the Debug tab
function setStatus(t,c) if statusSet then statusSet(t,c) end end
function setState(st)
	STATE = st
	if st=="running" then setStatus("RUNNING", T.Good)
	elseif st=="recording" then setStatus("REC", T.Bad)
	elseif st=="stopped" then setStatus("stopped", T.Dim)
	else setStatus("idle", T.Dim) end
end

-- ════════ LOCK-ON  (0 = instant, higher = smoother/slower) ════════
function refreshLock()    -- nearest enemy PLAYER, else nearest training DUMMY (so lock-on works in the lobby too)
	local plr,p = nearestEnemy()
	if p then lockTarget, lockPart = plr, p
	else lockTarget, lockPart = nil, (nearestDummyPart and nearestDummyPart() or nil) end
end
-- on-screen LOCK RETICLE: TSB-style clean WHITE targeting reticle (thin ring + 4 cardinal ticks + center dot)
local lockGui
function buildLockIcon()
	local sg=Instance.new("BillboardGui"); sg.Name="TSB_Lock"; sg.Size=UDim2.fromOffset(64,64); sg.AlwaysOnTop=true; sg.LightInfluence=0; sg.MaxDistance=2200; sg.Enabled=false
	pcall(function() sg.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)
	if not sg.Parent then pcall(function() sg.Parent=LP:FindFirstChildOfClass("PlayerGui") end) end
	if CFG.lockImage and CFG.lockImage~="" then   -- EXACT image option: paste a TSB lock-on asset id in Settings to use it verbatim
		local id=tostring(CFG.lockImage); if id:match("^%d+$") then id="rbxassetid://"..id end
		local img=Instance.new("ImageLabel"); img.Size=UDim2.fromScale(1,1); img.BackgroundTransparency=1; img.Image=id; img.Parent=sg
		return sg
	end
	local WHT=Color3.fromRGB(255,255,255)
	-- CONSOLE LOCK-ON look: a thin white DIAMOND (rotated square outline) + a small center dot — the recognizable controller target marker
	local dia=Instance.new("Frame"); dia.Size=UDim2.fromScale(0.62,0.62); dia.Position=UDim2.fromScale(0.5,0.5); dia.AnchorPoint=Vector2.new(0.5,0.5); dia.Rotation=45; dia.BackgroundTransparency=1; dia.Parent=sg
	local dstroke=Instance.new("UIStroke"); dstroke.Color=WHT; dstroke.Thickness=2.5; dstroke.Transparency=0.05; dstroke.Parent=dia
	local dot=Instance.new("Frame"); dot.BackgroundColor3=WHT; dot.BorderSizePixel=0; dot.Size=UDim2.fromOffset(4,4); dot.AnchorPoint=Vector2.new(0.5,0.5); dot.Position=UDim2.fromScale(0.5,0.5); dot.Parent=sg
	local dc=Instance.new("UICorner"); dc.CornerRadius=UDim.new(1,0); dc.Parent=dot
	return sg
end
RunSvc:BindToRenderStep("TSB_Lock", Enum.RenderPriority.Camera.Value+1, function()
	if not CFG.lockOn then if lockGui then lockGui.Enabled=false end lockTarget,lockPart=nil,nil return end   -- lock OFF: drop the target so dashes/aim never use a stale lock (fixes "two different targets")
	local me = myHRP()
	if not me or not alive() then lockTarget,lockPart=nil,nil; return end          -- I died → reset
	if lockTarget then
		local p = partOf(lockTarget)
		if not p then lockTarget,lockPart=nil,nil                                   -- target gone/dead → reset
		elseif (p.Position-me.Position).Magnitude > CFG.lockRange then lockTarget,lockPart=nil,nil  -- too far → reset
		else lockPart=p end
	end
	-- (Re)acquire. When NOT mid-combo (or Retarget is on) we re-pick the NEAREST enemy every frame, so
	-- lock-on follows whoever you walk up to instead of sticking to an old/previous player. During a
	-- running combo we keep the locked target so the tech doesn't swap mid-string (unless it died/left).
	if lockPart and not lockPart.Parent then lockPart,lockTarget=nil,nil end         -- target destroyed: drop it
	if (not lockPart) or (CFG.retarget and not REPLAYING) then refreshLock() end     -- STICKY: ONE locked target; re-pick only if none, or Retarget on while NOT mid-combo (so it never swaps to a 2nd target during a tech)
	if not lockPart then if lockGui then lockGui.Enabled=false end return end
	local cam = WS.CurrentCamera
	if cam and lockPart then
		-- CONSOLE LOCK-ON: park the camera BEHIND your character and look AT the enemy, so the enemy stays
		-- centered and your character is in frame (TSB's controller lock). Movement/dashes then go toward them.
		local pPos = me.Position
		local flat = lockPart.Position - pPos; flat = Vector3.new(flat.X, 0, flat.Z)
		if flat.Magnitude > 0.1 then
			local dir = flat.Unit
			local camPos = pPos - dir*(CFG.lockDist or 12) + Vector3.new(0, CFG.lockHeight or 4.5, 0)
			local goal = CFrame.lookAt(camPos, lockPart.Position)
			local s = CFG.smoothLock or 0
			local a = (s<=0) and 0.45 or math.clamp(1/(1+s*12), 0.04, 1)   -- always EASE the camera (no hard per-frame snap = no jitter / mouse-fight)
			if not (UIS.TouchEnabled and not UIS.KeyboardEnabled) then cam.CFrame = cam.CFrame:Lerp(goal, a) end   -- DON'T seize the camera on TOUCH (it fights mobile jump/dash); reticle + targeting still work
		end
	end
	if not lockGui then lockGui = buildLockIcon() end                               -- show the reticle on the locked target
	if lockGui then lockGui.Adornee = lockPart; lockGui.Enabled = true end
end)

-- ════════ TARGET-RELATIVE MOVEMENT ════════
-- TSB movement is CAMERA-relative. Snapping the camera to face the target right before a directional dash/move
-- makes "left/right" strafe AROUND the enemy and "forward" go INTO them — that's what makes a tech actually land.
local dummyCache, dummyCacheT = nil, 0
nearestDummyPart = function()   -- cached ~1s so we don't scan the map every dash (also used by lock-on)
	if dummyCache and dummyCache.Parent and (os.clock()-dummyCacheT)<1 then return dummyCache end
	for _,o in ipairs(WS:GetDescendants()) do
		if o:IsA("Model") and tostring(o.Name):lower():find("dummy") then
			local p=o:FindFirstChild("HumanoidRootPart") or o:FindFirstChildWhichIsA("BasePart")
			if p then dummyCache=p; dummyCacheT=os.clock(); return p end
		end
	end
	dummyCache=nil; return nil
end
function currentTargetPart()  -- lock target → nearest enemy player → nearest training dummy
	if CFG.lockOn and lockPart and lockPart.Parent then return lockPart end          -- LOCKED: every dash/aim uses the ONE locked target (no second target)
	if lockTarget then local p=partOf(lockTarget); if p then return p end end
	local _,p = nearestEnemy(); if p then return p end
	return nearestDummyPart()
end
function faceTarget()         -- snap the camera to look at the target (one-shot); returns true if it aimed
	local cam=WS.CurrentCamera; local part=currentTargetPart()
	if not cam or not part then return false end
	local camPos=cam.CFrame.Position
	if (part.Position-camPos).Magnitude < 0.05 then return false end
	pcall(function() cam.CFrame = CFrame.lookAt(camPos, part.Position) end)
	return true
end

-- ════════ HITBOX EXPANDER (resize enemy/dummy hit parts so attacks connect more easily) ════════
-- NOTE: parts are resized LOCALLY; whether the SERVER counts the bigger box depends on TSB's hit detection.
local hbOrig = setmetatable({}, {__mode="k"})   -- weak so collected parts don't leak
local hbConn, hbLast = nil, 0
local function hbApply(p, s)
	if not p or not p:IsA("BasePart") then return end
	if not hbOrig[p] then hbOrig[p] = {size=p.Size, cc=p.CanCollide} end
	if p.Size.X ~= s then pcall(function() p.Size = Vector3.new(s, s, s); p.CanCollide = false end) end
end
function hbRestore()
	for p,d in pairs(hbOrig) do pcall(function() if p and p.Parent then p.Size=d.size; p.CanCollide=d.cc end end) end
	hbOrig = setmetatable({}, {__mode="k"})
end
function setHitbox(on)
	CFG.hitbox = on and true or false; pcall(saveCfg)
	if not CFG.hitbox then hbRestore(); return end
	if hbConn then return end
	hbConn = track(RunSvc.Heartbeat:Connect(function()
		if not CFG.hitbox then return end
		local s = math.clamp(CFG.hitboxSize or 12, 4, 60)
		for _,plr in ipairs(Players:GetPlayers()) do
			if plr~=LP and plr.Character then hbApply(plr.Character:FindFirstChild("HumanoidRootPart"), s) end
		end
		if os.clock()-hbLast > 0.5 then hbLast = os.clock()                       -- dummies: rescan occasionally (cheaper than every frame)
			for _,o in ipairs(WS:GetDescendants()) do
				if o:IsA("Model") and tostring(o.Name):lower():find("dummy") then hbApply(o:FindFirstChild("HumanoidRootPart"), s) end
			end
		end
	end))
end
if CFG.hitbox then pcall(function() setHitbox(true) end) end   -- resume if it was left on

-- ════════ ACTION EXECUTION ════════
-- bindKC: resolve a CFG.binds[name] to "M1"/"M2"/<KeyCode>, or nil if the bind is INVALID (validation).
local function bindKC(name)
	local b = CFG.binds[name]
	if b=="MouseButton1" then return "M1" end
	if b=="MouseButton2" then return "M2" end
	if b and KC[b] then return KC[b] end
	return nil
end
local function badBind(name) setStatus("bad bind: "..tostring(name), T.Bad); if CFG.debug then warn("[TSB] invalid bind for "..tostring(name)) end return false end
-- one timed press of a resolved input (mouse or key); held for holdMs (scaled, floored)
function pressResolved(res, holdMs, token)
	if res=="M1" then mDown(0); holdWait(holdMs, token); mUp(0)
	elseif res=="M2" then mDown(1); holdWait(holdMs, token); mUp(1)
	elseif res then kDown(res); holdWait(holdMs, token); kUp(res)
	else return false end
	return not (token and token.cancel)   -- a press cut by Stop reports FAILED, not "sent"
end
-- skill cooldown tracking: if a skill slot was pressed within ~skillCD seconds it's likely still on CD,
-- so throw an M1 instead of wasting the press — smarter combos that don't whiff a dead skill.
local skillUsed = {}
local lastFwd, lastSide = 0, 0   -- TSB dash cooldowns (fwd ~5s, side/back ~2s) so we never spam an ignored dash
local function doSkill(slot, bindName, s, token)
	local r = bindKC(bindName); if not r then return badBind(bindName) end
	if CFG.smartCD and skillUsed[slot] and (os.clock()-skillUsed[slot] < (CFG.skillCD or 8)) then
		local m = bindKC("M1"); if m then return pressResolved(m, 50, token) end   -- on cooldown -> M1 instead
		return true
	end
	skillUsed[slot] = os.clock()
	return pressResolved(r, s.hold or 35, token)
end
-- tapKey: a clean PRESS+RELEASE of a key (never a hold). Used for jump so the character actually leaves the
-- ground for uppercut/downslam instead of "holding space" (which in TSB just buffers, it doesn't launch you).
local function tapKey(kc, holdMs, token)
	if not kc then return false end
	kDown(kc); holdWait(holdMs or 35, token); kUp(kc)
	return not (token and token.cancel)
end
-- doAction: run ONE instance of a step's action (the rep loop in runStep calls this). Returns true on success.
function doAction(s, token)
	local a=s.act
	if a=="m1"   then local r=bindKC("M1");   if not r then return badBind("M1")   end return pressResolved(r, s.hold or 35, token)
	elseif a=="m1hold" then  -- HOLD M1 = TSB auto-chains the punch combo; the game paces the hits so none get dropped (most reliable multi-M1)
		local r=bindKC("M1"); if not r then return badBind("M1") end
		if r=="M1" then mDown(0); local ok=gapWait(s.dur or 700, token); mUp(0); if not ok then return false end
		elseif r=="M2" then mDown(1); local ok=gapWait(s.dur or 700, token); mUp(1); if not ok then return false end
		else kDown(r); local ok=gapWait(s.dur or 700, token); kUp(r); if not ok then return false end end
		return true
	elseif a=="skill1" then return doSkill(1,"Skill1",s,token)
	elseif a=="skill2" then return doSkill(2,"Skill2",s,token)
	elseif a=="skill3" then return doSkill(3,"Skill3",s,token)
	elseif a=="skill4" then return doSkill(4,"Skill4",s,token)
	elseif a=="jump" then local r=bindKC("Jump"); if not r then return badBind("Jump") end return tapKey(r, s.hold or 35, token)
	elseif a=="doublejump" then local r=bindKC("Jump"); if not r then return badBind("Jump") end
		tapKey(r, s.hold or 35, token); if token.cancel then return false end; gapWait(140, token); if token.cancel then return false end; tapKey(r, s.hold or 35, token); return true
	elseif a=="relock" then if not CFG.lockOn then CFG.lockOn=true end; lockTarget=nil; refreshLock(); return true   -- re-acquire nearest target mid-combo
	elseif a=="lookback" then local cam=WS.CurrentCamera; if cam then pcall(function() cam.CFrame=cam.CFrame*CFrame.Angles(0,math.pi,0) end) end; return true   -- spin camera 180° (hit behind)
	elseif a=="ultimate" then local r=bindKC("Ultimate"); if not r then return badBind("Ultimate") end return pressResolved(r, s.hold or 35, token)
	elseif a=="block" then local r=bindKC("Block"); if not r then return badBind("Block") end return pressResolved(r, s.dur or 450, token)
	elseif a=="dash" then
		local dk=bindKC("Dash"); if not dk then return badBind("Dash") end
		local tgt = currentTargetPart()
		local dirName = s.dirName
		if CFG.dashToTarget and tgt then dirName = "W" end                      -- DASH INTO TARGET: override the combo's literal direction so every dash CLOSES onto the enemy (no whiffing off to the side)
		if tgt and not CFG.lockOn and (CFG.aimMove or CFG.dashToTarget) then faceTarget(); gapWait(60, token) end   -- face the target so "forward" goes INTO them (lock-on render loop already faces)
		local fwd = (dirName=="W" or not dirName)
		if fwd then
			-- FORWARD DASH = aim with a quick W tap, fire the dash, then RELEASE W THE MOMENT it fires.
			-- (Holding W through the dash is what made the character keep RUNNING forward = "it holds, not presses".)
			if tgt and (os.clock()-lastFwd) < 4.8 then                          -- dash on cooldown: a SHORT walk-in so it still closes the gap
				kDown(KC.W); gapWait(120, token); kUp(KC.W); return true
			end
			kDown(KC.W); gapWait(s.dirLead or 55, token)                        -- hold W only long enough to aim the dash forward
			pressResolved(dk, s.hold or 45, token)                              -- dash (Q) while W is held = dash FORWARD / into the target
			kUp(KC.W); lastFwd = os.clock()                                     -- release W IMMEDIATELY -> a clean DASH, not a run
			return true
		end
		-- SIDE / BACK dash: hold the direction THROUGH the dash so it actually goes that way, then release it.
		local dir = KC[dirName]
		if dir then kDown(dir) end                                              -- hold direction
		if token.cancel then if dir then kUp(dir) end return false end
		gapWait(s.dirLead or 60, token)
		if token.cancel then if dir then kUp(dir) end return false end
		pressResolved(dk, s.hold or 45, token)                                  -- press dash
		lastSide = os.clock()
		if dir then gapWait(s.releaseDelay or 40, token); kUp(dir) end          -- release direction (releaseDelay) — runs even on cancel so a side key never sticks
		return true
	elseif a=="move" then
		local dir=s.dirName and KC[s.dirName]; if not dir then return false end
		if CFG.aimMove and not CFG.lockOn then faceTarget() end                                    -- aim at enemy → move is target-relative
		kDown(dir); gapWait(s.dur or 250, token); kUp(dir); return true         -- hold a direction = travel a DISTANCE (kUp runs even on cancel)
	elseif a=="sprint" then
		local rk=bindKC("Run"); if not rk or rk=="M1" or rk=="M2" then return badBind("Run") end
		if CFG.aimMove and not CFG.lockOn then faceTarget() end                                    -- aim → sprint goes toward the enemy
		kDown(rk); holdWait(40, token); kUp(rk)                                 -- double-tap...
		if token.cancel then return false end
		gapWait(40, token); if token.cancel then return false end
		kDown(rk); gapWait(s.dur or 450, token); kUp(rk); return true           -- ...then hold = sprint a distance
	elseif a=="run" then
		local rk=bindKC("Run"); if not rk or rk=="M1" or rk=="M2" then return badBind("Run") end
		kDown(rk); holdWait(40, token); kUp(rk)
		if token.cancel then return false end
		gapWait(50, token); if token.cancel then return false end
		kDown(rk); holdWait(40, token); kUp(rk); return true                    -- double-tap to sprint
	elseif a=="uppercut" then
		-- UPPERCUT (researched, TSB wiki): HOLD Space and click M1 while STILL GROUNDED — the M1 becomes an
		-- uppercut. Pressing space too early = a jump instead, so M1 fires almost immediately after space-down.
		local jk=bindKC("Jump"); local mk=bindKC("M1")
		if not mk then return badBind("M1") end
		local jumping = jk and jk~="M1" and jk~="M2"
		if jumping then kDown(jk) end                                           -- HOLD space (do NOT tap/leave the ground yet)
		gapWait(s.jumpLead or 20, token)                                        -- tiny lead so space registers first
		pressResolved(mk, s.m1Hold or 45, token)                                -- M1 while space is held + grounded = uppercut
		if jumping then kUp(jk) end                                             -- release space
		gapWait(s.jumpReleaseDelay or 40, token)
		return true
	elseif a=="downslam" then
		-- DOWNSLAM (researched): HOLD Space to rise into the air, then M1 WHILE AIRBORNE = downslam.
		local jk=bindKC("Jump"); local mk=bindKC("M1")
		if not mk then return badBind("M1") end
		local jumping = jk and jk~="M1" and jk~="M2"
		if jumping then kDown(jk) end                                                    -- HOLD space to go up
		if not gapWait(s.airDelay or 260, token) then if jumping then kUp(jk) end return false end   -- rise airborne
		if jumping then kUp(jk) end                                                      -- release space
		pressResolved(mk, s.m1Hold or 45, token); return true                            -- M1 in the air = downslam
	elseif a=="key" then
		if s.keyName and KC[s.keyName] then return pressResolved(KC[s.keyName], s.hold or 35, token) end
		return badBind(s.keyName or "key")
	end
	return false
end

-- ════════ STEP MODEL ════════
-- ACTS = the single source of truth for every action: label, category, whether it repeats, direction need
-- (false / "opt" / "req"), which keybind it presses, whether that bind must be a keyboard key, and per-field
-- SAFE MINIMUMS. The palette, editor, validator, runner, and debug all read from this so they can never disagree.
local ACTS = {
	m1       = {label="M1",       cat="attack",   reps=true,  dir=false, bind="M1",       min={hold=20, repeatGap=140}},
	m1hold   = {label="M1 Hold",  cat="attack",   reps=true,  dir=false, bind="M1",       min={dur=200}},
	skill1   = {label="Skill 1",  cat="skill",    reps=true,  dir=false, bind="Skill1",   min={hold=20, postDelay=120}},
	skill2   = {label="Skill 2",  cat="skill",    reps=true,  dir=false, bind="Skill2",   min={hold=20, postDelay=120}},
	skill3   = {label="Skill 3",  cat="skill",    reps=true,  dir=false, bind="Skill3",   min={hold=20, postDelay=120}},
	skill4   = {label="Skill 4",  cat="skill",    reps=true,  dir=false, bind="Skill4",   min={hold=20, postDelay=120}},
	jump     = {label="Jump",     cat="movement", reps=true,  dir=false, bind="Jump",     min={hold=20}},
	doublejump = {label="Double Jump", cat="movement", reps=true, dir=false, bind="Jump", min={hold=20}},
	relock   = {label="Re-Lock",  cat="skill",    reps=true,  dir=false, min={}},
	lookback = {label="Look Behind", cat="movement", reps=true, dir=false, min={}},
	ultimate = {label="Ultimate", cat="skill",    reps=true,  dir=false, bind="Ultimate", min={hold=20, postDelay=150}},
	block    = {label="Block",    cat="defense",  reps=true,  dir=false, bind="Block",    min={dur=50}},
	dash     = {label="Dash",     cat="movement", reps=true,  dir="opt", bind="Dash",     min={hold=30, dirLead=20, releaseDelay=20}},
	move     = {label="Move",     cat="movement", reps=true,  dir="req", bind=nil,        min={dur=40}},
	sprint   = {label="Sprint",   cat="movement", reps=true,  dir=false, bind="Run", kbOnly=true, min={dur=60}},
	run      = {label="Run",      cat="movement", reps=true,  dir=false, bind="Run", kbOnly=true, min={}},
	uppercut = {label="Uppercut", cat="attack",   reps=true,  dir=false, bind="M1",       min={jumpLead=40, m1Hold=20, jumpReleaseDelay=40}, role="Launcher", desc="Jump then M1 = launch the enemy up. Works best after 3 M1s."},
	downslam = {label="Downslam", cat="attack",   reps=true,  dir=false, bind="M1",       min={airDelay=60, m1Hold=20}, role="Slam", desc="Jump, wait to be airborne, then M1 = slam the enemy down. Pairs with a dash re-catch."},
	key      = {label="Key",      cat="skill",    reps=true,  dir=false, custom=true,     min={hold=20}},
	wait     = {label="Wait",     cat="wait",     reps=false, dir=false, min={}},
}
local actName = {}; for k,v in pairs(ACTS) do actName[k]=v.label end
function validKCName(v) return v=="MouseButton1" or v=="MouseButton2" or (type(v)=="string" and KC[v]~=nil) end
-- clampMins: raise any timing field that's below its action's safe minimum (stops M1 merge / unregistered presses)
function clampMins(s)
	local A=ACTS[s.act]; if A and A.min then for f,mn in pairs(A.min) do if type(s[f])=="number" and s[f]<mn then s[f]=mn end end end
	return s
end
function copyStep(s) local t={}; for k,v in pairs(s) do t[k]=v end; return t end
-- migrateStep: bring any step (old or new) up to the v3 format. Returns nil for an invalid step (it gets skipped).
function migrateStep(s)
	if type(s)~="table" or type(s.act)~="string" then return nil end
	-- OLD format used `delay` = the gap AFTER the step. Convert → postDelay, and seed repeatGap from it.
	if s.preDelay==nil and s.postDelay==nil and s.delay~=nil then
		s.postDelay = tonumber(s.delay)
		s.repeatGap = s.repeatGap or tonumber(s.delay)
	end
	s.delay = nil
	s.preDelay  = tonumber(s.preDelay)  or 0
	s.postDelay = tonumber(s.postDelay) or 70
	s.repeatGap = tonumber(s.repeatGap) or 90
	s.reps      = math.max(1, math.floor(tonumber(s.reps) or 1))
	if s.act=="dash" then s.dirLead=s.dirLead or 90; s.hold=s.hold or 55; s.releaseDelay=s.releaseDelay or 45   -- snappy directional dash
	elseif s.act=="uppercut" then s.jumpLead=s.jumpLead or 80; s.m1Hold=s.m1Hold or 50; s.jumpReleaseDelay=s.jumpReleaseDelay or 40
	elseif s.act=="downslam" then s.airDelay=s.airDelay or 280; s.m1Hold=s.m1Hold or 45; s.hold=s.hold or 35
	elseif s.act=="block" then s.dur=s.dur or 320
	elseif s.act=="move" then s.dur=s.dur or 250
	elseif s.act=="sprint" then s.dur=s.dur or 450
	elseif s.act=="m1hold" then s.dur=s.dur or 700
	elseif s.act=="m1" then s.hold=s.hold or 48; s.repeatGap=s.repeatGap or 250   -- M1 gap; lower can merge hits (TSB paces punches)
	elseif s.act~="wait" and s.act~="run" then s.hold=s.hold or 35 end
	return clampMins(s)   -- enforce per-action safe minimums on load
end

-- validateSeq: scan every step BEFORE running and return a list of {row, msg, status}. Run is blocked if any exist.
function validateSeq()
	local errs = {}
	for i,s in ipairs(seq) do
		local function err(m) errs[#errs+1]={row=i, text=m, status="err"} end
		if type(s)~="table" or type(s.act)~="string" then err("missing/!invalid action")
		else
			local A = ACTS[s.act]
			if not A then err("unknown action '"..tostring(s.act).."'")
			else
				if A.reps then
					local r = tonumber(s.reps)
					if r and r~=math.floor(r) then err(A.label..": reps must be a whole number") end
					if r and r>50 then err(A.label..": reps too high (max 50)") end
				end
				if A.dir=="req" and not (type(s.dirName)=="string" and KC[s.dirName]) then err(A.label.." needs a direction (W/A/S/D)") end
				if s.act=="dash" and s.dirName~=nil and not KC[s.dirName] then err("Dash has an invalid direction") end
				if A.bind then
					local b = CFG.binds[A.bind]
					if not validKCName(b) then err(A.label.." bind ("..tostring(A.bind)..") is invalid — set it in Keybinds")
					elseif A.kbOnly and (b=="MouseButton1" or b=="MouseButton2") then err(A.label.." needs a KEYBOARD key (its bind is a mouse button)") end
				end
				if A.custom and not (type(s.keyName)=="string" and KC[s.keyName]) then err("Custom key is invalid") end
				if A.min then for f,mn in pairs(A.min) do local v=tonumber(s[f]); if v and v<mn then err(A.label.." "..f.." "..v.."ms is below safe min "..mn.."ms") end end end
			end
		end
	end
	-- soft WARNING (doesn't block the run): M1 should be a mouse button in TSB
	if CFG.binds.M1~="MouseButton1" and CFG.binds.M1~="MouseButton2" then
		local usesM1=false; for _,s in ipairs(seq) do local A=ACTS[s.act]; if A and A.bind=="M1" then usesM1=true; break end end
		if usesM1 then errs[#errs+1]={row=0, status="warn", text="M1 is a keyboard key — TSB M1 is a mouse click; rebind M1 to Mouse in Keybinds"} end
	end
	-- ============ SMART COMBO ANALYSIS (context-aware, non-blocking warnings) ============
	-- the "brain": understands the combo - M1-chain cap, launcher-before-downslam, skill/dash cooldown spacing, juggle gaps, gap-closer
	local function stepMs(s)
		local d=(s.preDelay or 0)+(s.postDelay or 0); local reps=math.max(1, tonumber(s.reps) or 1)
		if s.act=="m1" then d=d+reps*((s.hold or 48)+(s.repeatGap or 250))
		elseif s.act=="uppercut" then d=d+(s.jumpLead or 80)+(s.m1Hold or 50)+(s.jumpReleaseDelay or 40)
		elseif s.act=="downslam" then d=d+(s.hold or 35)+(s.airDelay or 280)+(s.m1Hold or 45)
		elseif s.act=="dash" then d=d+(s.dirLead or 60)+(s.hold or 45)+(s.releaseDelay or 40)
		elseif s.act=="block" then d=d+(s.dur or 320)
		elseif s.act=="move" or s.act=="sprint" then d=d+(s.dur or 250)
		else d=d+(s.hold or s.dur or 0)+(((reps>1) and reps*(s.repeatGap or 0)) or 0) end
		return d*(CFG.comboSpeed or 1)
	end
	local function nm(s) return actName[s.act] or (ACTS[s.act] and ACTS[s.act].label) or tostring(s.act) end
	local accum, m1run, lastFwdAt, lastSkillAt = 0, 0, nil, {}
	for i,s in ipairs(seq) do
		if s.act=="m1" then
			m1run = m1run + (tonumber(s.reps) or 1)
			if m1run>4 then errs[#errs+1]={row=i, status="warn", text="M1 chain totals "..m1run.." - TSB resets the punch chain after 4; extra M1s won't combo. Break it with a launcher / skill / dash."} end
		elseif s.act~="wait" then m1run=0 end
		if s.act=="downslam" then
			local launched=false
			for k=i-1,1,-1 do local pa=seq[k].act
				if pa=="uppercut" or pa=="jump" or pa=="doublejump" then launched=true; break
				elseif pa=="m1" or pa=="ultimate" or pa=="block" or (type(pa)=="string" and pa:match("^skill")) then break end
			end
			if not launched then errs[#errs+1]={row=i, status="warn", text="Downslam has no launcher before it - add an Uppercut or Jump so it slams an AIRBORNE enemy (a grounded downslam whiffs)."} end
		end
		if s.act=="wait" then local prev=seq[i-1]
			if prev and (prev.act=="uppercut" or prev.act=="downslam") and (s.postDelay or 0)>250 then
				errs[#errs+1]={row=i, status="warn", text="Long wait ("..(s.postDelay or 0).."ms) right after "..nm(prev).." - the enemy falls; keep the juggle gap under ~200ms."}
			end
		end
		if type(s.act)=="string" and s.act:match("^skill") then
			local last=lastSkillAt[s.act]
			if last and (accum-last) < (CFG.skillCD or 8)*1000 then
				errs[#errs+1]={row=i, status="warn", text=nm(s).." reused ~"..math.floor((accum-last)/1000).."s apart but its CD is "..(CFG.skillCD or 8).."s - it fires as an M1 instead. Space it out."}
			end
			lastSkillAt[s.act]=accum
		end
		if s.act=="dash" then
			local isFwd = (s.dirName=="W") or (CFG.dashToTarget==true)
			if isFwd then
				if lastFwdAt and (accum-lastFwdAt) < 4800 then
					errs[#errs+1]={row=i, status="warn", text="Forward dash ~"..math.floor((accum-lastFwdAt)/1000).."s after the last - fwd dash CD is ~5s; this one gets ignored (it walks in instead). Add a wait."}
				end
				lastFwdAt=accum
			end
		end
		if (s.act=="skill1" or s.act=="skill2" or s.act=="skill3" or s.act=="skill4") and (s.postDelay or 100)<180 then
			errs[#errs+1]={row=i, status="warn", text=nm(s)..": post-delay "..(s.postDelay or 100).."ms is short - the next move may cancel it (200ms+ is safer)."}
		end
		if s.act=="m1" and (s.repeatGap or 360)<280 then
			errs[#errs+1]={row=i, status="warn", text="M1 gap "..(s.repeatGap or 360).."ms is low - punches may merge (280ms+ is safe)."}
		end
		if (s.act=="uppercut" or s.act=="downslam") and (s.postDelay or 100)<120 then
			errs[#errs+1]={row=i, status="warn", text=nm(s)..": add a small wait after it (post-delay "..(s.postDelay or 100).."ms is short) so the follow-up connects."}
		end
		accum = accum + stepMs(s)
	end
	if not CFG.smartCombat then
		for i,s in ipairs(seq) do
			local A=ACTS[s.act]
			if A and (A.cat=="attack" or A.cat=="skill") then
				local hasCloser=false
				for k=1,i-1 do local pk=seq[k].act; if pk=="dash" or pk=="sprint" or pk=="run" then hasCloser=true; break end end
				if not hasCloser then errs[#errs+1]={row=i, status="warn", text="Combo opens on "..nm(s).." with no Dash Forward to close in - it may whiff from range (or turn on Smart Combat)."} end
				break
			end
		end
	end
	return errs
end

-- ════════ DEBUG + RUN ENGINE ════════
local function dbg(num,total,s,rep,reps,ok)
	if not CFG.debug then return end
	local h = s.hold or s.m1Hold or s.dur or "-"
	print(("[TSB] step %d/%d  %-9s  rep %d/%d  hold %sms  gap %sms  -> %s")
		:format(num, total, s.act, rep, reps, tostring(h), tostring(s.repeatGap or "-"), ok and "OK" or "FAIL"))
end
-- ════════ SMART COMBAT — never swing/dash into empty air ════════
-- A move only lands if the target is actually in reach & in front. These let the run loop close the gap on a
-- far target, catch a ragdolled one on its get-up, and (when locked) skip a swing when there is genuinely no one.
function targetHumanoid()
	local p = lockPart or currentTargetPart()
	if p and p.Parent then return p.Parent:FindFirstChildOfClass("Humanoid"), p end
	return nil
end
function targetDown()   -- is the locked target ragdolled / knocked down / getting up?
	local hum = targetHumanoid(); if not hum then return false end
	local ok, st = pcall(function() return hum:GetState() end); if not ok then return false end
	return st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.FallingDown
		or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.GettingUp
end
function distToTarget(p)
	local me = myHRP(); if not (me and p and p.Parent) then return math.huge end
	return (me.Position - p.Position).Magnitude
end
function dashCatch(token)   -- face + front-dash toward the target, OR walk in if the dash is on cooldown (no spam)
	faceTarget(); local dk = bindKC("Dash"); local w = KC.W
	if not w then return end
	if dk and (os.clock()-lastFwd >= 4.8) then kDown(w); waitFor(0.05, token); pressResolved(dk, 55, token); lastFwd=os.clock(); waitFor(0.04, token); kUp(w)
	else kDown(w); waitFor(0.20, token); kUp(w) end   -- dash on cooldown -> walk forward instead of firing an ignored dash
end
-- reachTarget: PAUSE the combo and dash/walk IN until the target is within melee range, THEN let the rest run.
-- returns true = in range now (finish the rest), false = target GONE or unreachable (stop the combo, don't swing at air).
-- Bounded by CFG.chaseSecs so it can't run off across the map like a noob.
function reachTarget(token)
	if not CFG.chase then return false end   -- chase OFF: never walk after a far target (combo runs in place)
	local t0 = os.clock()
	local window = math.max(0.4, CFG.chaseSecs or 1.4)
	while not token.cancel do
		local p = currentTargetPart()
		if not p then return false end                                      -- target not there -> stop
		if distToTarget(p) <= (CFG.meleeRange or 16) then return true end   -- close enough -> do the rest
		if os.clock()-t0 > window then return false end                     -- couldn't reach in the chase window -> stop (don't run forever)
		dashCatch(token); waitFor(0.06, token)                              -- dash in (or walk if dash on CD), then re-check
	end
	return false
end

-- SWEAT TECH (researched): flick shift-lock (LeftShift toggle) so M1s auto-face the target, and side-dash
-- (A/D + Q TOGETHER, bypassing dashToTarget) BETWEEN M1s to orbit the enemy. Gated to Sweaty+ combos (CFG.sweat).
local shiftLockState = false
function flickShiftLock(on)
	if on==shiftLockState then return end
	local sk = KC.LeftShift
	if sk then kDown(sk); holdWait(35, {cancel=false}); kUp(sk); shiftLockState = on end   -- LeftShift toggles shift-lock in TSB
end
local sweatLeft = false
function sweatSideDash(token)
	if (os.clock()-lastSide) < 2.0 then return end                 -- respect the ~2s side-dash CD (never fire a dead dash)
	local dk = bindKC("Dash"); if not dk then return end
	sweatLeft = not sweatLeft
	local dir = sweatLeft and KC.A or KC.D                          -- alternate dash LEFT / RIGHT to orbit the target
	flickShiftLock(false)                                          -- shift-lock CANCEL: free the facing so the dash curves
	kDown(dir); waitFor(0.02, token); pressResolved(dk, 40, token); lastSide=os.clock(); waitFor(0.02, token); kUp(dir)   -- direction+Q TOGETHER = a real side dash
	flickShiftLock(true); pcall(faceTarget)                        -- re-aim onto the target before the next M1
end

-- ANTI-COUNTER (researched): TSB counters all live on slot 4 (Death Counter, Prey's Peril, Death Blow,
-- Spiraling Storm, Split Second). They freeze the user in a stance + grant i-frames. Detect via (a) a ForceField
-- / invuln on the enemy and (b) their playing animation matching a counter-stance keyword. Plain F-blocks are
-- intentionally NOT matched (blocking is safe to pressure; only the counter STANCE must stop us).
function targetCountering()
	local hum = targetHumanoid(); if not hum then return false end
	local char = hum.Parent
	if char and char:FindFirstChildOfClass("ForceField") then return true end                       -- i-frames / hyperarmor window
	if char and (char:GetAttribute("Countering") or char:GetAttribute("Parry") or char:GetAttribute("Counter")) then return true end
	local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return false end
	local ok, tracks = pcall(function() return anim:GetPlayingAnimationTracks() end); if not ok or not tracks then return false end
	for _,t in ipairs(tracks) do
		local n = ((t.Name or "")..((t.Animation and t.Animation.Name) or "")):lower()
		if n:find("counter") or n:find("parry") or n:find("reversal") or n:find("stance")
		or n:find("prey") or n:find("deathblow") or n:find("spiral") or n:find("splitsecond") then return true end
	end
	return false
end

-- AUTO-EVADE: side-dash the instant YOU RECOVER from any knockdown / ragdoll / stun, to escape the enemy's combo.
-- Robust: a recovery is detected from a Heartbeat watcher that covers ALL the ways a TSB-style game ragdolls you
-- (Humanoid PlatformStand, the Physics/FallingDown/Ragdoll/GettingUp Humanoid states, OR a Ragdoll/Stunned attribute).
local EVADE_KEY = {Left=KC.A, Right=KC.D, Forward=KC.W, Back=KC.S}
local evadeToken = nil   -- module-level so STOP/unload can abort an in-flight evade dash
function evadeDash()
	local dk = bindKC("Dash"); if not dk then if CFG.debug then setStatus("auto-evade: no Dash bind", T.Bad) end return end
	local mode = CFG.evadeDir or "Right"
	if mode=="ToTarget" then pcall(faceTarget) end                          -- angle the dash AT the locked target...
	local dir = (mode=="ToTarget") and KC.W or (EVADE_KEY[mode] or KC.D)     -- ...by facing it then dashing FORWARD into it
	local now=os.clock(); local fwd=(dir==KC.W)
	if (fwd and now-lastFwd<4.8) or ((not fwd) and now-lastSide<2.0) then return end   -- dash on COOLDOWN: don't fire an ignored dash (wastes the escape)
	task.spawn(function() local tk={cancel=false}; evadeToken=tk; kDown(dir); waitFor(0.05,tk); pressResolved(dk,55,tk); waitFor(0.05,tk); kUp(dir); if fwd then lastFwd=os.clock() else lastSide=os.clock() end end)
end
function isIncapacitated(hum, char)
	if not hum then return false end
	if hum.PlatformStand then return true end
	local ok, st = pcall(function() return hum:GetState() end)
	if ok and (st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.FallingDown or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.GettingUp) then return true end
	if char and (char:GetAttribute("Ragdoll") or char:GetAttribute("Ragdolled") or char:GetAttribute("Stunned") or char:GetAttribute("Knocked")) then return true end
	return false
end
local lastEvade, wasDown = 0, false
track(RunSvc.Heartbeat:Connect(function()
	if not CFG.autoEvade then wasDown=false; return end
	local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local down = isIncapacitated(hum, char)
	if wasDown and not down and (os.clock()-lastEvade) > 0.7 then lastEvade=os.clock(); pcall(evadeDash) end   -- transitioned DOWN -> RECOVERED: dash out now
	wasDown = down
end))

-- ════════ AUTO-BLOCK (defensive layer): tap the Block bind when a nearby enemy is mid-attack and we are NOT
-- comboing. Reads enemy attack animations within autoBlockRange. Best-effort (server decides if the block holds).
local lastAutoBlock = 0
track(RunSvc.Heartbeat:Connect(function()
	if not CFG.autoBlock then return end
	if STATE=="running" then return end                       -- don't block during our own combo (would cancel it)
	if os.clock()-lastAutoBlock < 0.4 then return end
	local me = myHRP(); if not me then return end
	local bk = bindKC("Block"); if not bk or bk=="M1" or bk=="M2" then return end
	for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP and plr.Character then
		local pt=plr.Character:FindFirstChild("HumanoidRootPart"); local h=plr.Character:FindFirstChildOfClass("Humanoid")
		if pt and h and (pt.Position-me.Position).Magnitude <= (CFG.autoBlockRange or 14) then
			local anim=h:FindFirstChildOfClass("Animator")
			if anim then local ok,tr=pcall(function() return anim:GetPlayingAnimationTracks() end)
				if ok then for _,t in ipairs(tr) do local nm=((t.Name or "")..((t.Animation and t.Animation.Name) or "")):lower()
					if nm:find("punch") or nm:find("m1") or nm:find("attack") or nm:find("combat") or nm:find("hit") then
						lastAutoBlock=os.clock(); kDown(bk); task.delay(0.28, function() kUp(bk) end); return
					end end end end
		end
	end end
end))

-- runStep: preDelay -> (do action, repeatGap) x reps -> postDelay. Every wait is cancellable.
local function runStep(s, token, num, total)
	if token.cancel then return false end
	local t0 = os.clock()
	if not gapWait(s.preDelay or 0, token) then return false end          -- preDelay
	local reps = math.max(1, math.floor(s.reps or 1))
	local anyFail = false
	for i=1,reps do
		if token.cancel then return false end
		local ok = true
		if s.act~="wait" then ok = doAction(s, token); if not ok then anyFail=true end end  -- the press itself (holds inside)
		dbg(num, total, s, i, reps, ok)
		if i<reps then
			local okGap
			if s.act=="m1" then okGap = gapWaitFloored(s.repeatGap or 250, 280, token)  -- M1 reps never merge (TSB ~300ms punch cadence)
			else okGap = gapWait(s.repeatGap or 90, token) end
			if not okGap then return false end
		end
	end
	local pd=s.postDelay or 100; if s.act=="m1" then pd=math.max(pd,280) end   -- adjacent M1 STEPS must not merge either
	if not gapWait(pd, token) then return false end                      -- postDelay (gap to next move)
	return true, anyFail, math.floor((os.clock()-t0)*1000)               -- real elapsed ms for the Debug log
end
local function stopSeq()
	if curToken then curToken.cancel = true end
	curToken = nil
	if evadeToken then evadeToken.cancel = true end             -- abort any in-flight auto-evade dash too
	runHeld = false; REPLAYING = false; CFG.autoCombo = false   -- OFF means OFF: kill loop-hold, click-redirect, AND the auto-combo chain
	releaseAll()              -- INSTANT: drop any held key/click right now
	releaseMovement()         -- and HARD-release every movement key so the character never keeps running
	setState("idle")
end
local function runSeq()
	if STATE=="running" or STATE=="recording" then return end            -- never double-run
	if #seq==0 then setStatus("empty — add steps", T.Bad); if reportSet then reportSet({{row=0,text="add some steps first",status="err"}}) end return end
	local errs = validateSeq()                                            -- PRE-RUN VALIDATOR: don't start with bad steps
	local hard=0; for _,e in ipairs(errs) do if e.status~="warn" then hard=hard+1 end end
	if hard>0 then                                                        -- block only on real errors; warnings are allowed
		local first; for _,e in ipairs(errs) do if e.status~="warn" then first=e; break end end
		setStatus("step "..(first and first.row or "?")..": "..(first and first.text or "invalid"), T.Bad)
		if reportSet then reportSet(errs) end
		if CFG.debug then for _,e in ipairs(errs) do warn("[TSB] row "..e.row..": "..e.text) end end
		return
	end
	local token = { cancel=false }
	curToken = token
	setState("running"); lastRunStart = os.clock()
	if CFG.lockOn then if CFG.retarget then lockTarget=nil end; refreshLock() end
	task.spawn(function()
		REPLAYING = true
		if CFG.sweat then pcall(flickShiftLock, true) end                        -- SWEAT: shift-lock ON so M1s auto-face the target through the combo
		if CFG.lockOn or CFG.aimMove then pcall(faceTarget) end                  -- aim at the enemy before the first move so the tech heads at them
		if CFG.approach and CFG.chase then pcall(function()                      -- close the gap so the combo actually reaches the target (only if chase is allowed)
			local me=myHRP(); local part=currentTargetPart()
			if me and part and (part.Position-me.Position).Magnitude>14 then
				faceTarget(); local dk=bindKC("Dash")
				if dk then kDown(KC.W); pcall(function() waitFor(0.06, token); pressResolved(dk, 55, token); waitFor(0.05, token) end); kUp(KC.W) end  -- kUp ALWAYS runs (W never sticks)
			end
		end) end
		-- The ENTIRE run is wrapped: even if something throws, the cleanup below ALWAYS runs, so the builder
		-- can never get stuck on "running" (which looked like "it stops / crashes / won't run again").
		local hadTarget = false   -- stop the combo ONLY if a target was present then went gone (never breaks a no-target run)
		local ranOk, runErr = pcall(function()
			repeat
				lastReport = {}; lastStatusByRow = {}; inputLog = {}      -- fresh report + input log each pass
				for i,s in ipairs(seq) do
					if token.cancel then break end
					if CFG.stopOnDeath then local h=myHum(); if h and h.Health<=0 then token.cancel=true; break end end
					if CFG.lockOn or CFG.aimMove then                     -- SMART: track a moving target each step; stop if the target is gone while locked on
						local part = currentTargetPart()
						if part then hadTarget = true elseif hadTarget then setStatus("target gone, stopped", T.Bad); inputLog[#inputLog+1]="-- stopped: target gone"; lastReport[#lastReport+1]={row=0,status="warn",text="stopped: target gone"}; token.cancel=true; break end   -- STOP only if a target WAS there and is now GONE
						-- (far-stop removed; smartCombat dashes IN to the target instead of stopping)
						if CFG.chase and CFG.smartEngage and CFG.lockOn and part and (s.act=="m1" or s.act=="dash" or (type(s.act)=="string" and s.act:sub(1,5)=="skill")) then local me3=myHRP(); if me3 then local d=(part.Position-me3.Position).Magnitude; if d>13 and d<=(CFG.fightStopDist or 35) then faceTarget(); local dk=bindKC("Dash"); if dk then kDown(KC.W); pcall(function() waitFor(0.05,token); pressResolved(dk,55,token); waitFor(0.04,token) end); kUp(KC.W) end end end end   -- SMART RE-ENGAGE: target drifted out of melee reach -> dash IN (only when chase is on)
						if part and not CFG.lockOn then pcall(faceTarget) end   -- (lock-on already tracks via the render loop)
						-- WHIFF-PREVENTION: before an offensive move, if the target is out of reach (or ragdolled), dash IN so it doesn't hit air
						if CFG.smartCombat and part then
							local off = s.act=="m1" or s.act=="uppercut" or s.act=="downslam" or (type(s.act)=="string" and s.act:match("^skill"))
								local launcher = (s.act=="uppercut" or s.act=="downslam")
							if off then
								if CFG.antiCounter and targetCountering() then setStatus("anti-counter: holding the hit", T.Bad); inputLog[#inputLog+1]="-- anti-counter: held the hit"; waitFor(0.45, token); if token.cancel then break end end   -- don't feed a counter
								if CFG.chase and distToTarget(part) > (CFG.meleeRange or 16) then
										setStatus("waiting to reach target...", T.Dim)
										local got = reachTarget(token)                   -- PAUSE: dash in + WAIT until close, THEN finish the rest
										if token.cancel then break end
										if not got then setStatus("target gone, stopped", T.Bad); inputLog[#inputLog+1]="-- stopped: couldn't reach target"; token.cancel=true; break end
										if launcher then waitFor(0.08, token) end        -- settle after the dash so the launcher doesn't whiff
								elseif targetDown() and CFG.chase then pcall(dashCatch, token) end   -- on the floor: dash in to catch the get-up
							end
						end
					end
					if setRunRow then pcall(setRunRow, i) end             -- live highlight (protected)
					setStatus(("RUN %d/%d  %s"):format(i, #seq, s.label or s.act or "?"), T.Good)   -- live combo progress on the status pill
					local pok, completed, anyFail, ms = pcall(runStep, s, token, i, #seq)
					if not pok then pcall(releaseAll) end                 -- a throw mid-step could leave a key held -> release everything NOW
					local st = (not pok) and "err" or (anyFail and "fail" or "ok")
					lastStatusByRow[i] = st
					lastReport[#lastReport+1] = {row=i, status=st,
						text=(actName[s.act] or s.act)..((not pok) and (" — error: "..tostring(completed)) or (anyFail and " — input rejected (check its bind/direction in Keybinds)" or ""))}
					local A=ACTS[s.act]
					inputLog[#inputLog+1] = ("#%d  %-9s  in:%s  hold:%sms  gap:%dms  dt:%dms  -> %s"):format(
						i, tostring(s.act), tostring(A and (A.bind or (A.custom and (s.keyName or "?")) or "-") or "-"),
						tostring(s.hold or s.m1Hold or s.dur or "-"), (s.postDelay or 100), (ms or 0),
						(not pok) and "ERROR" or (anyFail and "REJECTED" or "sent"))
					if logSet then pcall(logSet, inputLog) end             -- render the input log LIVE during the run, not only at the end
					if not pok and CFG.debug then warn("[TSB] step "..i.." error: "..tostring(completed)) end
						if CFG.sweat and s.act=="m1" and i<#seq and not token.cancel and currentTargetPart() then pcall(sweatSideDash, token) end   -- SWEAT: strafe (side-dash + shift-lock cancel) BETWEEN M1 steps to orbit the target
					-- run EVERY step start → finish; a failed step is only flagged red, it never aborts the rest
				end
				-- ONE TAP = ONE FULL PASS. Only loop again if Loop is on AND (Hold mode) the key is still held.
				local keepLooping = CFG.loop and not token.cancel and not CFG.autoCombo and not (CFG.runMode=="Hold" and not runHeld)
				if keepLooping then gapWait(CFG.loopDelay, token) end
			until token.cancel or (not CFG.loop) or CFG.autoCombo or (CFG.runMode=="Hold" and not runHeld)
		end)
		-- GUARANTEED cleanup — runs no matter what happened above
		REPLAYING = false
		pcall(flickShiftLock, false)                                          -- SWEAT: restore shift-lock OFF when the run ends
		pcall(releaseAll)
		pcall(releaseMovement)                                                -- and make 100% sure no movement key is left held (no noob-running)
		if setRunRow then pcall(setRunRow, nil) end
		if curToken==token then curToken=nil; setState("idle") end          -- reset to idle (guard: don't clobber a newer run after Stop+rerun)
		if onRunDone then pcall(function() onRunDone(not token.cancel) end) end   -- run ended; true = natural finish (auto-combo chaining)
			if reportSet then pcall(reportSet, lastReport) end
		if logSet then pcall(logSet, inputLog) end
		if rebuildSteps then pcall(rebuildSteps) end
		if not ranOk and CFG.debug then warn("[TSB] run error (recovered): "..tostring(runErr)) end
	end)
end
-- run-key trigger/release factored out so it works for a keyboard OR a mouse-bound run key (Hold mode resets either way)
function triggerRun()
	if STATE=="recording" then return end
	if os.clock()-lastTrig < 0.12 then return end          -- debounce: one tap = one action
	lastTrig = os.clock()
	if STATE=="running" then                               -- RUNNING → press = STOP EVERYTHING (any run mode)
		runHeld=false; stopSeq()                           -- stop the tech + release keys; lock-on STAYS ON (toggle it with C / the Lock-On switch)
	else
		runHeld=true; runSeq()                             -- IDLE → press = run
	end
end

-- ════════ MOBILE BUTTON BAR ════════
-- Keyboard-less / touch players get on-screen Run/Stop/Lock + Jump/Dash buttons (built independently of Rayfield so
-- it works even if the menu fails). HONEST: VirtualInputManager may not drive a phone character on every touch
-- executor, so Jump/Dash are best-effort; Run/Stop/Lock control the script reliably.
local mobileSG
function buildMobileBar()
	pcall(function() local g=(gethui and gethui()) or game:GetService("CoreGui"); local old=g:FindFirstChild("Vaultix_Mobile"); if old then old:Destroy() end end)
	local sg=Instance.new("ScreenGui"); sg.Name="Vaultix_Mobile"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	pcall(function() sg.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)
	if not sg.Parent then pcall(function() sg.Parent=LP:FindFirstChildOfClass("PlayerGui") end) end
	local bar=Instance.new("Frame"); bar.Size=UDim2.fromOffset(338,44); bar.Position=UDim2.new(0.5,0,0,8); bar.AnchorPoint=Vector2.new(0.5,0); bar.BackgroundColor3=Color3.fromRGB(20,14,16); bar.BackgroundTransparency=0.1; bar.BorderSizePixel=0; bar.ZIndex=50; bar.Parent=sg
	local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,10); bc.Parent=bar
	local lay=Instance.new("UIListLayout"); lay.FillDirection=Enum.FillDirection.Horizontal; lay.HorizontalAlignment=Enum.HorizontalAlignment.Center; lay.VerticalAlignment=Enum.VerticalAlignment.Center; lay.Padding=UDim.new(0,5); lay.Parent=bar
	local pdg=Instance.new("UIPadding"); pdg.PaddingLeft=UDim.new(0,5); pdg.PaddingRight=UDim.new(0,5); pdg.Parent=bar
	local function btn(txt,w,cb)
		local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(w,34); b.BackgroundColor3=Color3.fromRGB(205,46,52); b.BorderSizePixel=0; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255); b.Font=Enum.Font.GothamBold; b.TextSize=12; b.ZIndex=51; b.Parent=bar
		local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,7); cc.Parent=b
		b.MouseButton1Click:Connect(function() pcall(cb) end)
	end
	btn("RUN/STOP",80,function() triggerRun() end)
	btn("STOP",48,function() stopSeq() end)
	btn("LOCK",48,function() CFG.lockOn=not CFG.lockOn; if not CFG.lockOn then lockTarget=nil end; if CFG.lockOn then refreshLock() end; if onLockChanged then pcall(onLockChanged, CFG.lockOn) end end)
	btn("JUMP",48,function() local j=bindKC("Jump"); if j then kDown(j); task.wait(0.04); kUp(j) end end)
	btn("DASH",48,function() local d=bindKC("Dash"); if d then kDown(KC.W); task.wait(0.03); kDown(d); task.wait(0.04); kUp(d); kUp(KC.W) end end)
	if regOverlay then pcall(regOverlay, bar) end   -- replayed M1 clicks avoid the bar
	mobileSG = sg; return sg
end
if (UIS.TouchEnabled and not UIS.KeyboardEnabled) or CFG.mobileBar then pcall(buildMobileBar) end

-- ════════ DIAGNOSTIC — prove inputs actually reach the game ════════
-- The ONE thing that can't be verified outside Roblox: whether VirtualInputManager drives THIS game on THIS executor.
-- This fires a tiny scripted burst after a 3s countdown so you can tab in and watch your character + read the console.
function runDiagnostic()
	if STATE=="running" then return end
	task.spawn(function()
		for i=3,1,-1 do setStatus("TEST in "..i.."… (tab into game)", T.Accent); print("[TSB TEST] starting in "..i.." — switch to the Roblox window now"); task.wait(1) end
		setStatus("TESTING — watch your character", T.Good)
		REPLAYING = true
		local tok={cancel=false}
		print("[TSB TEST] VIM present:", VIM~=nil, "| M1 bind:", CFG.binds.M1, "| Dash bind:", CFG.binds.Dash)
		print("[TSB TEST] -> M1");           doAction({act="m1",hold=60}, tok); gapWait(380,tok)
		print("[TSB TEST] -> M1 again (should be a 2nd punch)"); doAction({act="m1",hold=60}, tok); gapWait(380,tok)
		print("[TSB TEST] -> Dash forward");  doAction({act="dash",dirName="W",dirLead=70,hold=55,releaseDelay=55}, tok); gapWait(350,tok)
		print("[TSB TEST] -> hold W 0.6s");   doAction({act="move",dirName="W",dur=600}, tok)
		releaseAll(); releaseMovement(); REPLAYING = false
		setStatus("test done — open console (F9)", T.Accent)
		print("[TSB TEST] DONE. If your character punched/dashed/walked → the builder works on your setup; tune timings in the ✎ editor. If NOTHING moved → VirtualInputManager isn't driving this game here (usually the Roblox window must be FOCUSED while a tech runs, or this executor needs a different input method). Note which one happened.")
	end)
end

-- ════════ PRESETS — honest practice techs, each with metadata {cat,char,diff,purpose,steps} ════════
local function M1(reps,gap)  return {act="m1",   reps=reps or 1, hold=48, repeatGap=gap or 250, preDelay=0, postDelay=(reps and reps>1) and 70 or 50, label="M1"..((reps or 1)>1 and " x"..reps or "")} end
local function SK(n,post)    return {act="skill"..n, hold=30, preDelay=0, postDelay=post or 140, label="Skill "..n} end
local function DASH(dir)     return {act="dash", dirName=dir, dirLead=90, hold=55, releaseDelay=45, preDelay=0, postDelay=70, label="Dash "..(({W="Fwd",S="Back",A="Left",D="Right"})[dir] or "")} end
local function UPC()         return {act="uppercut", jumpLead=80, m1Hold=50, jumpReleaseDelay=40, preDelay=0, postDelay=110, label="Uppercut"} end
local function DS()          return {act="downslam", airDelay=280, m1Hold=45, hold=35, preDelay=0, postDelay=140, label="Downslam"} end
local function M1H(ms)       return {act="m1hold", dur=ms or 1100, preDelay=0, postDelay=80, label="M1 Hold"} end
local function WAIT(ms)      return {act="wait", preDelay=0, postDelay=ms or 120, label="Wait "..(ms or 120).."ms"} end
local function RLK()         return {act="relock", preDelay=0, postDelay=60, label="Re-Lock"} end
local function BLK(ms)       return {act="block", dur=ms or 320, preDelay=0, postDelay=70, label="Block "..(ms or 320).."ms"} end
local function P(cat,diff,purpose,steps,extra)   -- extra = {ping,wall,dashRisk,notes}
	local p={cat=cat, char="Generic", diff=diff, purpose=purpose, steps=steps, ping="Normal", wall=false, dashRisk="low", notes=""}
	if extra then for k,v in pairs(extra) do p[k]=v end end
	return p
end
local PRESETS = {
	-- BASIC
	["Basic 4 M1"]              = P("Basic","Beginner","Basic M1 chain timing.", { M1(4) }),
	["3 M1 Uppercut"]           = P("Basic","Beginner","Basic launcher.", { M1(3), UPC() }),
	["3 M1 Downslam"]           = P("Basic","Beginner","Slam starter.", { M1(3), DS() }),
	["M1 Hold Chain"]           = P("Basic","Beginner","Reliable punch-chain test.", { M1H(1100) }),
	-- WALL COMBO (wall required)
	["Wall Combo from 4th M1"]  = P("Wall Combo","Normal","Wall combo off the 4th M1.", { M1(4), WAIT(200), DASH("W") }, {wall=true, dashRisk="med", notes="Requires a wall / tree / trash can. Wall combo has ~5s cooldown."}),
	["Wall Combo from Downslam"]= P("Wall Combo","Hard","Wall combo off a downslam.", { M1(3), DS(), WAIT(200), DASH("W") }, {wall=true, dashRisk="med", notes="Requires a wall. Downslam timing is strict."}),
	["Wall Combo from Uppercut"]= P("Wall Combo","Hard","Wall combo off an uppercut.", { M1(3), UPC(), WAIT(200), DASH("W") }, {wall=true, dashRisk="med", notes="Requires a wall."}),
	-- AIR TECH
	["Uppercut Dash Left"]      = P("Air Tech","Normal","Side-dash catch after a launcher.", { M1(3), UPC(), DASH("A"), M1(2) }, {dashRisk="med"}),
	["Uppercut Dash Right"]     = P("Air Tech","Normal","Side-dash catch after a launcher.", { M1(3), UPC(), DASH("D"), M1(2) }, {dashRisk="med"}),
	["Uppercut Re-Lock Skill"]  = P("Air Tech","Hard","Aim before the skill follow-up.", { M1(3), UPC(), RLK(), SK(2) }),
	-- DOWNSLAM
	["Downslam Recatch"]        = P("Downslam","Hard","Re-catch after the slam.", { M1(3), DS(), WAIT(200), DASH("W"), M1(2) }, {dashRisk="med"}),
	["Downslam Side Catch"]     = P("Downslam","Hard","Side-dash re-catch.", { M1(3), DS(), WAIT(180), DASH("A"), M1(2) }, {dashRisk="med"}),
	["Double Downslam Practice"]= P("Downslam","Hard","Timing practice — NOT guaranteed.", { M1(3), DS(), WAIT(220), SK(1), DS() }, {notes="Placeholder skill — swap for your character's move. Not a guaranteed combo."}),
	-- MOVEMENT
	["Side Dash Pressure Left"] = P("Movement","Normal","Pressure + repositioning.", { M1(2), DASH("A"), M1(2) }, {dashRisk="med"}),
	["Side Dash Pressure Right"]= P("Movement","Normal","Pressure + repositioning.", { M1(2), DASH("D"), M1(2) }, {dashRisk="med"}),
	["Back Dash Reset"]         = P("Movement","Normal","Spacing reset, then re-lock.", { DASH("S"), WAIT(300), RLK() }, {dashRisk="high", notes="Back dash cooldown ~5s."}),
	-- SKILL EXTENDER
	["Skill Starter"]           = P("Skill Extender","Beginner","Test skill into M1.", { SK(1), WAIT(220), M1(3) }),
	["Skill Extender"]          = P("Skill Extender","Normal","Extend after an M1 string.", { M1(3), SK(2), WAIT(250), M1(2) }),
	-- FINISHER
	["Skill Finisher"]          = P("Finisher","Normal","Finish after a launcher.", { M1(3), UPC(), SK(3) }),
	-- UTILITY (generic move techs — swap the placeholder skill for your character's move / Custom Key)
	["Move Tech After 4th M1"]  = P("Utility","Normal","Practice 4th-M1 into side-dash skill timing.", { M1(4), DASH("A"), SK(1) }, {notes="Swap Skill 1 for your character's move-tech skill or a Custom Key."}),
	["Uppercut Side Dash Skill"]= P("Utility","Hard","Tactical-yeet-style timing practice.", { M1(3), UPC(), DASH("A"), SK(1) }, {notes="Swap Skill 1 for your character's skill / Custom Key."}),
	-- DEBUG / TEST
	["Full Skill Bind Test"]    = P("Debug/Test","Testing","Tests skill binds only — NOT a real combo.", { SK(1), WAIT(300), SK(2), WAIT(300), SK(3), WAIT(300), SK(4) }),
	-- 🔥 SWEAT TECHS — advanced, flashy, hard-timing practice techs (still NOT guaranteed; server can break them)
	["Ankle Breaker"]            = P("Mix-Up","Hard","Juke left↔right, then punish.", { DASH("A"), DASH("D"), M1(2) }, {dashRisk="high", notes="Side dash CD ~2s — don't spam it."}),
	["Dash-Cancel Pressure"]     = P("Cancels","Hard","Dash-cancel M1 strings to keep pressure.", { M1(2), DASH("W"), M1(2), DASH("W"), M1(2) }, {dashRisk="high"}),
	["Micro-Dash Chain"]         = P("Cancels","Hard","Cancel every M1 into a dash.", { M1(1), DASH("W"), M1(1), DASH("W"), M1(1), DASH("W"), M1(1) }, {dashRisk="high", notes="Fwd dash CD 5s — later dashes may not fire."}),
	["Uppercut Dash-Cancel Loop"]= P("Air Tech","Insane","Launch, dash-cancel, re-launch.", { M1(3), UPC(), DASH("W"), M1(3), UPC() }, {dashRisk="high"}),
	["Downslam Recatch x2"]      = P("Downslam","Insane","Slam, re-catch, slam again.", { M1(3), DS(), WAIT(200), DASH("W"), M1(2), DS() }, {dashRisk="med", notes="Strict timing — practice only."}),
	["Mix-Up Strafe"]            = P("Mix-Up","Hard","Strafe L/R then launch.", { M1(2), DASH("A"), M1(2), DASH("D"), UPC() }, {dashRisk="high"}),
	["Back-Dash Bait"]           = P("Mix-Up","Normal","Bait a whiff, then punish.", { DASH("S"), WAIT(250), DASH("W"), M1(3) }, {dashRisk="high"}),
	["Wall Carry Bring-Down"]    = P("Wall Combo","Insane","Carry to wall → launch → slam.", { M1(4), DASH("W"), M1(3), UPC(), DS() }, {wall=true, dashRisk="med", notes="Wall required. Sweaty timing."}),
	["Re-Lock Skill Burst"]      = P("Air Tech","Insane","Launch, re-aim, dump skills.", { M1(3), UPC(), RLK(), SK(1,220), SK(2,260) }),
	["Full Sweat Combo"]         = P("Sweat","Insane","Engage → string → launch → carry → slam → skill.", { DASH("W"), M1(4), UPC(), DASH("W"), M1(3), DS(), WAIT(200), SK(1) }, {dashRisk="high", notes="Long flashy PRACTICE chain — the server can break it anywhere."}),
	-- 🎭 CHARACTER tech templates (researched structures) — map YOUR character's skills to Skill 1-4 in order
	["Saitama: Serious Combo"]    = P("Character","Insane","The Strongest Hero string (practice).", { DASH("W"), M1(3), UPC(), DASH("A"), M1(3), SK(1), SK(2) }, {dashRisk="high", notes="Skills = Consecutive Punches, Normal Punch → Skill 1-2. Practice timing, not guaranteed."}),
	["Garou: Flowing Water Chain"]= P("Character","Insane","Hero Hunter chain (practice).", { DASH("W"), M1(3), SK(1), DASH("A"), SK(2), DASH("W"), M1(3), SK(3) }, {dashRisk="high", notes="Flowing Water / Hunters Grasp / Lethal Stream → Skill 1-3."}),
	["Genos: Machine Gun Rush"]   = P("Character","Hard","Destructive Cyborg pressure (practice).", { DASH("W"), M1(3), SK(1), SK(2), SK(3), UPC() }, {dashRisk="med", notes="Machine Gun Blows / Ignition Burst / Jet Dive → Skill 1-3; Blitz Shot = jump+skill."}),
	["Atomic: Slash Rush"]        = P("Character","Insane","Blade Master slash string (practice).", { DASH("W"), M1(3), SK(1), M1(3), SK(2), M1(3), DS() }, {dashRisk="high", notes="Quick Slice / Pinpoint Cut → Skill 1-2, end on Downslam."}),
	-- MORE TECHS (researched practice techs; still NOT guaranteed — the server can break any of them)
	["Dash-In 4 M1"]             = P("Basic","Beginner","Close distance, then a full M1 string.", { DASH("W"), M1(4) }, {dashRisk="low"}),
	["4 M1 Uppercut"]            = P("Basic","Normal","Full string into a launcher.", { M1(4), UPC() }),
	["4 M1 Downslam"]            = P("Basic","Normal","Full string into a slam.", { M1(4), DS() }),
	["Block then Punish"]        = P("Defense","Normal","Block to bait, then punish.", { BLK(500), M1(3) }, {notes="Server decides if the block holds; practice the read."}),
	["Uppercut Air Skill"]       = P("Air Tech","Hard","Launch, then an air skill.", { M1(3), UPC(), SK(1) }, {notes="Swap Skill 1 for your character's air move."}),
	["Downslam Skill Finish"]    = P("Downslam","Hard","Slam into a skill finisher.", { M1(3), DS(), SK(2) }, {notes="Swap Skill 2 for your character's move."}),
	["Strafe Right Launch"]      = P("Mix-Up","Hard","Strafe right, string, launch.", { M1(2), DASH("D"), M1(2), UPC() }, {dashRisk="high"}),
	["Double Side-Dash String"]  = P("Mix-Up","Hard","Juke both ways into a string.", { DASH("A"), DASH("D"), M1(3) }, {dashRisk="high", notes="Side dash CD ~2s; don't spam."}),
	["Engage Skill Burst"]       = P("Skill Extender","Hard","Dash in, dump two skills, M1.", { DASH("W"), SK(1), SK(2), M1(3) }, {notes="Swap Skill 1-2 for your character's moves."}),
	["Sonic: Sound-Speed Rush"]  = P("Character","Insane","Speed-o-Sound style mix (practice).", { DASH("W"), M1(3), SK(1), DASH("A"), SK(2), M1(2) }, {dashRisk="high", notes="Map Sonic's skills to Skill 1-2."}),
	["Tank-Top: Power String"]   = P("Character","Hard","Heavy power string (practice).", { DASH("W"), M1(4), SK(1), UPC(), SK(2) }, {dashRisk="med", notes="Map skills to Skill 1-2."}),
	["Metal Bat: Fighting Spirit"]= P("Character","Insane","Relentless spirit chain (practice).", { M1(4), SK(1), SK(2), SK(3), DS() }, {notes="Map Metal Bat's skills to Skill 1-3."}),
}
local PRESET_ORDER = {
	"Basic 4 M1","3 M1 Uppercut","3 M1 Downslam","M1 Hold Chain",
	"Side Dash Pressure Left","Side Dash Pressure Right","Back Dash Reset",
	"Dash-Cancel Pressure","Micro-Dash Chain","Ankle Breaker","Mix-Up Strafe","Back-Dash Bait",
	"Uppercut Dash Left","Uppercut Dash Right","Uppercut Re-Lock Skill","Uppercut Dash-Cancel Loop","Re-Lock Skill Burst",
	"Downslam Recatch","Downslam Side Catch","Double Downslam Practice","Downslam Recatch x2",
	"Wall Combo from 4th M1","Wall Combo from Downslam","Wall Combo from Uppercut","Wall Carry Bring-Down",
	"Saitama: Serious Combo","Garou: Flowing Water Chain","Genos: Machine Gun Rush","Atomic: Slash Rush",
	"Skill Starter","Skill Extender","Skill Finisher",
	"Move Tech After 4th M1","Uppercut Side Dash Skill",
	"Dash-In 4 M1","4 M1 Uppercut","4 M1 Downslam","Block then Punish",
	"Uppercut Air Skill","Downslam Skill Finish","Strafe Right Launch","Double Side-Dash String","Engage Skill Burst",
	"Sonic: Sound-Speed Rush","Tank-Top: Power String","Metal Bat: Fighting Spirit",
	"Full Sweat Combo","Full Skill Bind Test"}

-- ════════ SAVE / LOAD  (versioned + migration) ════════
local function loadSeq(steps)
	seq = {}
	local skipped = {}
	for i,s in ipairs(steps) do
		local m = migrateStep(copyStep(s))
		if m then seq[#seq+1]=m else skipped[#skipped+1]=i end
	end
	if #skipped>0 then setStatus("loaded · skipped "..#skipped.." bad step(s)", T.Bad); if CFG.debug then warn("[TSB] skipped invalid step(s) at index: "..table.concat(skipped,", ")) end end
	if rebuildSteps then rebuildSteps() end
end
function sanitizeName(nm)   -- strip anything that could break a file path; cap length
	nm = tostring(nm or ""):gsub("[^%w _%-]",""):gsub("^%s+",""):gsub("%s+$","")
	return nm:sub(1,40)
end
function saveTech(name)     -- returns true on success so the UI can report failures
	if not name or name=="" then return false end
	if not HAS_IO then return false end   -- no real file access on this executor → report failure (don't pretend it saved)
	return (pcall(function() f_write(PREFIX..name..".json", Http:JSONEncode({version=STEP_VERSION, steps=seq})) end))
end
function loadTechFile(name)        -- returns true ONLY if a valid save was actually loaded (so the UI can't say "Loaded" on a corrupt/missing file)
	if not HAS_IO then return false end
	if not f_is(PREFIX..name..".json") then return false end
	local ok, t = pcall(function() return Http:JSONDecode(f_read(PREFIX..name..".json")) end)
	if not ok or type(t)~="table" then return false end
	local steps = (type(t.steps)=="table") and t.steps or t   -- versioned wrapper OR old bare array
	if type(steps)~="table" then return false end
	loadSeq(steps); return true
end
function deleteTech(name) pcall(function() if f_del and f_is(PREFIX..name..".json") then f_del(PREFIX..name..".json") elseif f_is(PREFIX..name..".json") then f_write(PREFIX..name..".json","[]") end end) end
function listTechs()
	local out={}
	pcall(function() for _,p in ipairs(f_list()) do local fn=tostring(p):match("([^/\\]+)%.json$"); if fn and fn:sub(1,#PREFIX)==PREFIX then out[#out+1]=fn:sub(#PREFIX+1) end end end)
	return out
end

-- ════════ RECORD MODE  (InputBegan + InputEnded → real hold durations) ════════
local recBeganConn, recEndedConn, recLast = nil, nil, 0
local recPress = {}     -- [key] = {t=down tick, pre=gap-since-last-action ms}
local recHeldDir = {}   -- which of W/A/S/D are currently held (so Dash can become DIRECTIONAL)
local recConsumed = {}  -- a direction "used up" by a dash → its release must NOT also add a separate Move step
local recSyncUI         -- fwd: keeps the Record button text/colour in sync with the real STATE (no desync)
local DIRSET  = {W=true, A=true, S=true, D=true}
local DIRNAME = {W="Fwd", S="Back", A="Left", D="Right"}
function stopRecord()
	if recBeganConn then recBeganConn:Disconnect(); recBeganConn=nil end
	if recEndedConn then recEndedConn:Disconnect(); recEndedConn=nil end
	recPress = {}; recHeldDir = {}; recConsumed = {}
	if STATE=="recording" then setState("idle") end
	if recSyncUI then recSyncUI() end
end
function mapRecord(key, hold, pre)   -- non-dash keys → a v3 step (dash is handled specially below)
	if key=="M1" then return {act="m1", hold=math.clamp(hold,40,200), repeatGap=360, preDelay=pre, postDelay=90, label="M1"} end
	local matched; for act,bk in pairs(CFG.binds) do if bk==key then matched=act break end end
	if matched=="Block" then return {act="block", dur=hold, preDelay=pre, postDelay=40, label="Block "..hold.."ms"} end
	if matched=="Jump" then return {act="jump", hold=math.clamp(hold,20,150), preDelay=pre, postDelay=80, label="Jump"} end
	if matched=="Ultimate" then return {act="ultimate", hold=35, preDelay=pre, postDelay=200, label="Ultimate"} end
	if matched and matched:match("^Skill%d") then local n=matched:sub(6); return {act="skill"..n, hold=35, preDelay=pre, postDelay=220, label="Skill "..n} end
	if DIRSET[key] then return {act="move", dirName=key, dur=math.clamp(hold,40,4000), preDelay=pre, postDelay=40, label="Move "..key.." "..hold.."ms"} end
	return {act="key", keyName=key, hold=math.clamp(hold,20,200), preDelay=pre, postDelay=100, label="Key "..key}
end
function startRecord()
	if STATE=="running" then stopSeq() end
	setState("recording"); recLast=tick(); recPress={}; recHeldDir={}; recConsumed={}
	if recSyncUI then recSyncUI() end
	local function gapBefore() local now=tick(); local d=math.floor((now-recLast)*1000); recLast=now; return math.clamp(d,0,4000) end
	local function keyOf(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then return "M1"
		elseif input.UserInputType==Enum.UserInputType.Keyboard then return input.KeyCode.Name end
		return nil
	end
	local function addStep(step) if step then seq[#seq+1]=migrateStep(step); if rebuildSteps then rebuildSteps() end end end
	recBeganConn = UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		local k=keyOf(input); if not k then return end
		if DIRSET[k] then recHeldDir[k]=true end
		recPress[k] = { t=tick(), pre=gapBefore() }
	end)
	recEndedConn = UIS.InputEnded:Connect(function(input)
		local k=keyOf(input); if not k then return end
		if DIRSET[k] then recHeldDir[k]=nil end
		local rec=recPress[k]; if not rec then return end
		recPress[k]=nil
		local hold=math.clamp(math.floor((tick()-rec.t)*1000), 20, 6000)
		if DIRSET[k] and recConsumed[k] then recConsumed[k]=nil; return end   -- this hold was already turned into a directional dash
		if CFG.binds.Dash==k then                                            -- DASH key: attach a held direction if there is one
			local d=nil; for _,dd in ipairs({"W","S","A","D"}) do if recHeldDir[dd] then d=dd; break end end
			if d then recConsumed[d]=true
				addStep({act="dash", dirName=d, dirLead=60, hold=45, releaseDelay=40, preDelay=rec.pre, postDelay=120, label="Dash "..(DIRNAME[d] or d)})
			else addStep({act="dash", dirLead=60, hold=45, releaseDelay=40, preDelay=rec.pre, postDelay=120, label="Dash"}) end
			return
		end
		addStep(mapRecord(k, hold, rec.pre))
	end)
end

-- ════════ GUI — RAYFIELD  (Vaultix Hub) ════════
-- Roster reworked from Bert's full tech guide. Combos stored as TOKEN strings → mkSteps() → engine steps.
-- Notation: M1xN, DASH_F/B/L/R, JUMP, UPPERCUT(=mini-uppercut/MU), DOWNSLAM(=DS), WAIT, S1-S4 (the char's 4 keyed moves).

local LP_ = game:GetService("Players").LocalPlayer
local M1GAP = {Safe=290, Normal=240, Fast=190, HighPing=340}

local function addStep(s)
	if s then
		if s.act=="m1" then s.repeatGap = M1GAP[CFG.m1Profile] or s.repeatGap or 250 end
		seq[#seq+1]=migrateStep(s); if rebuildSteps then rebuildSteps() end
	end
end
function clearSeq() while #seq>0 do table.remove(seq) end if rebuildSteps then rebuildSteps() end end
local function JUMP() return {act="jump", hold=60, preDelay=0, postDelay=90, label="Jump"} end
local function ULT()  return {act="ultimate", hold=35, preDelay=0, postDelay=200, label="Ultimate"} end
local function BLK(ms) return {act="block", dur=ms or 320, preDelay=0, postDelay=70, label="Block"} end

statusSet = function(t,_) print("[Vaultix] "..tostring(t)) end
logSet    = function(lg) if lg and #lg>0 then print("[Vaultix log] "..tostring(lg[#lg])) end end                                   -- live per-step input log -> F9
reportSet = function(r) for _,e in ipairs(r or {}) do print("[Vaultix report] "..((e.row and e.row>0 and ("#"..e.row.." ") or "")..tostring(e.status or "").." "..tostring(e.text))) end end   -- per-step results + terminal reasons

function printCombo()
	if #seq==0 then print("[Vaultix] combo is empty"); return end
	local t={}; for i,s in ipairs(seq) do t[#t+1]=i..". "..(s.label or s.act or "?") end
	print("[Vaultix] combo ("..#seq.." steps):\n"..table.concat(t,"\n"))
end

-- ───────── token → engine-step translator ─────────
local DASHMAP = {DASH_F="W", DASH_B="S", DASH_L="A", DASH_R="D"}
local function mkSteps(str)
	local toks={}; for w in tostring(str):gmatch("%S+") do toks[#toks+1]=w end
	local out, i, n = {}, 1, #toks
	while i<=n do
		local k = toks[i]
		local m = k:match("^M1x(%d+)$"); if not m and k=="M1" then m="1" end   -- accept a bare "M1" token as M1x1 (and multi-digit counts)
		if m then
			local mx = tonumber(m); local j = i+1
			while j<=n do local mm = toks[j]:match("^M1x(%d+)$"); if not mm and toks[j]=="M1" then mm="1" end; if mm then mx=mx + tonumber(mm); j=j+1 else break end end   -- SUM adjacent M1 tokens (M1x3 M1x4 = 7), don't drop them
			out[#out+1]=M1(mx); i=j
		elseif DASHMAP[k] then out[#out+1]=DASH(DASHMAP[k]); i=i+1
		elseif k=="JUMP" then out[#out+1]=JUMP(); i=i+1
		elseif k=="UPPERCUT" then out[#out+1]=UPC(); i=i+1
		elseif k=="DOWNSLAM" then out[#out+1]=DS(); i=i+1
		elseif k=="WAIT" then out[#out+1]=WAIT(100); i=i+1
		elseif k=="BLOCK" then out[#out+1]=BLK(120); i=i+1   -- REAL block tap (presses the Block bind), not a silent wait
		elseif k=="S1" then out[#out+1]=SK(1); i=i+1
		elseif k=="S2" then out[#out+1]=SK(2); i=i+1
		elseif k=="S3" then out[#out+1]=SK(3); i=i+1
		elseif k=="S4" then out[#out+1]=SK(4); i=i+1
		else i=i+1 end
	end
	return out
end

-- ───────── ROSTER (slot order + combos from Bert's tech guide) ─────────
-- ROSTER auto-generated from verified web research (10 chars, real sourced combos). Tokens -> mkSteps() -> engine steps.
local CHARS_ORDER = {
	"The Strongest Hero","Hero Hunter","Destructive Cyborg","Deadly Ninja","Brutal Demon","Blade Master","Wild Psychic","Martial Artist","Tech Prodigy","Undying Hero","Generic / Other"
}
local CHARS = {
	["The Strongest Hero"] = { slots="1=Normal Punch  2=Consecutive Punches  3=Shove  4=Uppercut", combos={
		{n="Bread & Butter (beginner) · Easy", t="M1x4 S2 M1x2"},
		{n="Quick downslam finisher · Easy", t="M1x3 UPPERCUT DOWNSLAM"},
		{n="Shove reposition combo · Easy", t="M1x3 S3 DASH_F M1x3 S1"},
		{n="Consecutive into Normal-Punch finisher · Easy", t="M1x4 S2 S1"},
		{n="now.gg / TheGamer basic route · Sweaty", t="M1x3 S3 DASH_F M1x3 DOWNSLAM S2 UPPERCUT DASH_L M1x3 S1"},
		{n="TheGamer advanced route · Sweaty", t="M1x3 DOWNSLAM UPPERCUT DASH_L M1x3 S2 S3 DASH_F M1x3 S1"},
		{n="Hold-space uppercut loop (now.gg combo 4) · Sweaty", t="M1x3 S2 UPPERCUT S3 DASH_F M1x4 S1"},
		{n="Wall pin (Ragdoll Shove tech) · Sweaty", t="DASH_F M1x3 S2 S3 DASH_L UPPERCUT M1x3 S1"},
		{n="Downslam relaunch extension · Pro", t="M1x3 DOWNSLAM S2 DOWNSLAM UPPERCUT M1x3 S3 DASH_L M1x3 S1"},
		{n="Inescapable one-shot (skilled) · Insane", t="M1x3 DOWNSLAM S2 DOWNSLAM UPPERCUT UPPERCUT M1x3 UPPERCUT S3 DASH_L M1x3 UPPERCUT S1"},
		{n="Ground-slam pressure string · Pro", t="DASH_F DOWNSLAM UPPERCUT DASH_F DOWNSLAM S2 DOWNSLAM S3 DASH_F UPPERCUT S1"},
		{n="Serious-Mode setup (awakening) · Insane", t="M1x4 S2 M1x4 UPPERCUT DOWNSLAM"},
	}},
	["Hero Hunter"] = { slots="1=Flowing Water  2=Hunter's Grasp  3=Lethal Whirlwind Stream  4=Prey's Peril", combos={
		{n="Bread & Butter Launcher · Easy", t="M1x3 UPPERCUT S1"},
		{n="Whirlwind Air Slam Starter · Easy", t="M1x3 UPPERCUT S3"},
		{n="Launch into Downslam · Easy", t="M1x3 UPPERCUT S3 JUMP M1"},
		{n="M1 Chain into Flowing Water then Whirlwind · Easy", t="M1x3 S1 DASH_F S3"},
		{n="Two-Special Rotation · Sweaty", t="DASH_F M1x3 UPPERCUT S1 DASH_L S3 M1x3 DOWNSLAM"},
		{n="Grasp Slam Extension · Sweaty", t="DASH_F M1x3 UPPERCUT S1 DASH_L S3 M1x3 DOWNSLAM S2 DASH_L M1x3 UPPERCUT"},
		{n="4-Hit Knockback Reset · Sweaty", t="M1x4 DASH_L S3 DASH_F S1 DOWNSLAM S2 DASH_L M1x4 DASH_F"},
		{n="Grasp-First Pressure Route · Sweaty", t="M1x4 DASH_F DASH_L S2 DASH_F M1x3 UPPERCUT S3 M1x3 UPPERCUT S1"},
		{n="Flowing Water Carry Loop · Pro", t="DASH_F M1x3 S1 DASH_F S2 DASH_F M1x3 UPPERCUT S3 S1"},
		{n="Whirlwind-First High Damage · Pro", t="DASH_F M1x3 UPPERCUT S3 S1 S2 DASH_L M1x4"},
		{n="Wall Bounce Continuation · Pro", t="M1x4 S1 DASH_F M1x3 UPPERCUT S3 M1x3 DOWNSLAM"},
		{n="Wall Pin Rotation · Pro", t="DASH_F M1x3 UPPERCUT S3 M1x3 DOWNSLAM S2 M1x3 UPPERCUT S1"},
		{n="One-Shot Sweat Carry · Insane", t="DASH_F M1x3 DOWNSLAM S2 DASH_L M1x3 UPPERCUT S3 UPPERCUT DASH_F DASH_L M1x3 UPPERCUT S1"},
		{n="Full Sweat Carry · Insane", t="DASH_F M1x3 UPPERCUT S1 DASH_L S3 M1x3 DOWNSLAM S2 DASH_L M1x3 UPPERCUT S3 M1x3 DOWNSLAM"},
		{n="Rampage Finisher (Monster Form) · Insane", t="M1x3 S1 S2 S3 S4"},
	}},
	["Destructive Cyborg"] = { slots="1=Machine Gun Blows  2=Ignition Burst  3=Blitz Shot  4=Jet Dive", combos={
		{n="Bread & Butter (beginner) · Easy", t="M1x3 S1 S2 DASH_F M1x3 S4"},
		{n="Now.gg Standard into Blitz Mode · Easy", t="M1x3 S1 S2 DASH_F M1x3 DOWNSLAM JUMP S4"},
		{n="Blitz-Open Ground Combo · Easy", t="M1x3 S3 S2 DASH_F M1x3 S1 DASH_L S4"},
		{n="Mini-Uppercut 360 Starter · Sweaty", t="M1x4 UPPERCUT S2 DASH_F M1x3 S1"},
		{n="Turn-Away Blitz Extension · Sweaty", t="M1x4 UPPERCUT S2 DASH_F M1x3 S1 BLOCK S3 S4"},
		{n="Downslam Jet-Dive Loop · Sweaty", t="M1x3 S1 M1x3 DOWNSLAM DASH_L S4 S1"},
		{n="Jet-Dive Opener Variant · Sweaty", t="M1x4 S4 JUMP S2 DASH_F M1x3 S1"},
		{n="Double Jet-Dive Extension · Pro", t="M1x3 S1 M1x3 DOWNSLAM DASH_L S4 S1 S2 S4"},
		{n="PIGGY.EXE Wall Combo · Pro", t="M1x3 S1 M1x4 S2 DASH_F M1x4 S4 S3 M1x4 DASH_R M1x3 S1"},
		{n="Wall-Pin Blitz Bnb · Pro", t="M1x4 UPPERCUT DASH_F M1x4 S3 M1x4 DASH_F M1x3 S1 S4"},
		{n="One-Shot / Zero-to-Death (full kit) · Insane", t="M1x4 UPPERCUT S2 DASH_F M1x3 S1 S3 DASH_F M1x3 S4 JUMP S2"},
		{n="Awakened Death Combo (Maximum Energy Output) · Insane", t="M1x3 DOWNSLAM S2 S1 S3"},
		{n="Awakened Now.gg Chain (Maximum Energy Output) · Insane", t="M1x3 DOWNSLAM S1 S2 S3"},
	}},
	["Deadly Ninja"] = { slots="1=Flash Strike  2=Whirlwind Kick  3=Scatter  4=Explosive Shuriken   [slots ~est]", combos={
		{n="Beginner shuriken loop (now.gg / progameguides bread-and-butter) · Easy", t="M1x4 JUMP S4 M1x3 S3 M1x3 DOWNSLAM"},
		{n="now.gg full ground route · Sweaty", t="M1x4 JUMP S4 M1x3 S3 M1x3 DOWNSLAM S2 S1"},
		{n="progameguides extended route · Sweaty", t="M1x4 JUMP S4 M1x3 S3 M1x3 DOWNSLAM S2 S1 M1x3 DOWNSLAM"},
		{n="Bread-and-butter uppercut starter · Easy", t="M1x4 UPPERCUT S4 M1x3 S2"},
		{n="Uppercut shuriken extend (wiki tech) · Sweaty", t="M1x3 UPPERCUT S4 S3 M1x3 S2"},
		{n="Downslam-into-Whirlwind reset (wiki/noping tech) · Sweaty", t="M1x3 DOWNSLAM S2 M1x3 S4"},
		{n="Dash-around mixup (wiki advanced route) · Pro", t="DASH_F M1x3 DASH_R S3 M1x3 UPPERCUT S4 S1 DASH_F M1x3 S2 M1x3 DOWNSLAM"},
		{n="YouTube reverse route · Sweaty", t="M1x3 UPPERCUT S4 DASH_F M1x3 S3 DOWNSLAM S2 DOWNSLAM S1"},
		{n="Double-downslam carry · Pro", t="M1x4 UPPERCUT S4 M1x3 DOWNSLAM S2 M1x3 DOWNSLAM S3"},
		{n="Scatter aerial flashy · Pro", t="M1x4 UPPERCUT S3 S4 M1x3 S2 DASH_F S1"},
		{n="Wall splat extender · Pro", t="M1x4 UPPERCUT S4 M1x3 S2 M1x4 S3"},
		{n="Wall pin shuriken loop · Insane", t="M1x4 UPPERCUT S4 M1x4 DOWNSLAM S4 M1x3 S2 S1"},
		{n="Block-break opener (vs blockers) · Sweaty", t="S4 M1x3 UPPERCUT S3 M1x3 S2"},
		{n="Poke into punish · Easy", t="DASH_F S4 DASH_F M1x4 UPPERCUT S3 M1x3 S2"},
		{n="Awakening burst (reference) · Sweaty", t="M1x4 UPPERCUT S4 M1x3 S2"},
	}},
	["Brutal Demon"] = { slots="1=Homerun  2=Beatdown  3=Grand Slam  4=Foul Ball", combos={
		{n="Bread-and-butter launcher starter · Easy", t="M1x3 UPPERCUT S3"},
		{n="Starter into Homerun send · Easy", t="M1x3 UPPERCUT S1"},
		{n="Beatdown gap-closer opener · Easy", t="DASH_F M1x4 S2"},
		{n="JustTalon main combo · Easy", t="M1x3 UPPERCUT S3 S1 S2 S4"},
		{n="Fortnitebot1099 Metal Bat combo · Sweaty", t="M1x3 UPPERCUT S3 M1x3 UPPERCUT S2 M1x3 DOWNSLAM S1 S4"},
		{n="Valleyer Metal Bat combo · Sweaty", t="M1x3 UPPERCUT S3 M1x3 DASH_F S2 S4 M1x3 S1"},
		{n="now.gg / ProGameGuides bread-and-butter · Sweaty", t="DASH_F M1x3 UPPERCUT S1 S2 S4 DASH_F M1x3 UPPERCUT S3 M1x4"},
		{n="now.gg / ProGameGuides downslam variant · Sweaty", t="DASH_F M1x3 UPPERCUT S3 M1x3 S2 S4 DASH_F M1x3 DOWNSLAM S1"},
		{n="Foul Ball rebound mid-combo reset · Sweaty", t="DASH_F M1x4 DASH_R S4 DASH_L M1x3 UPPERCUT S3"},
		{n="idontlikeforcedcaps Foul Play tech route · Pro", t="DASH_F M1x4 DASH_R S4 DASH_L S2 M1x3 UPPERCUT S3 M1x3 S1"},
		{n="DxviNights ~100% combo · Pro", t="DASH_F M1x3 UPPERCUT S3 M1x4 S4 DASH_F M1x4 S1 S2"},
		{n="StormyRae15 full-ladder 100% combo · Insane", t="DASH_F M1x4 DASH_R S4 DASH_R DASH_F M1x3 UPPERCUT S3 S2 M1x4 S1"},
		{n="Wall carry combo · Pro", t="M1x3 UPPERCUT DASH_F M1x4 S2 M1x4 S3"},
		{n="Wall pin Beatdown loop · Sweaty", t="DASH_F M1x4 S2 M1x4 S1"},
		{n="Downslam reset extension · Sweaty", t="M1x3 UPPERCUT S1 DASH_F JUMP DOWNSLAM M1x3 S2"},
		{n="Awakened Death Blow finisher setup · Pro", t="M1x3 UPPERCUT S3 M1x4 S2"},
	}},
	["Blade Master"] = { slots="1=Quick Slice  2=Atmos Cleave  3=Pinpoint Cut  4=Split Second Counter", combos={
		{n="Bread-and-butter starter · Easy", t="DASH_F M1x3 DOWNSLAM S2 S1 DASH_F M1x4"},
		{n="Half-health quick combo · Easy", t="M1x3 DOWNSLAM S2 WAIT S1"},
		{n="Knockback reset dash · Easy", t="M1x4 DASH_F M1x4 S2"},
		{n="Uppercut side-dash route · Sweaty", t="M1x3 UPPERCUT DASH_L S1 M1x3 DOWNSLAM S2 DASH_L M1x4"},
		{n="Downslam loop into Pinpoint · Sweaty", t="M1x3 DOWNSLAM S3 DASH_L M1x2 DASH_L M1x1 S1 M1x3 DOWNSLAM S2"},
		{n="Counter punish opener · Sweaty", t="S4 M1x3 DOWNSLAM S2 S1"},
		{n="Gap-close Pinpoint start · Sweaty", t="S3 M1x3 DOWNSLAM S2 WAIT S1"},
		{n="Double-downslam extension · Pro", t="M1x3 DOWNSLAM S2 DOWNSLAM S3 DASH_F M1x3 S1 M1x3 DOWNSLAM"},
		{n="Mini-uppercut loop-dash 95% · Insane", t="M1x3 UPPERCUT DASH_L S3 M1x2 DASH_L M1x1 S1 M1x3 DOWNSLAM S2 M1x3 DOWNSLAM"},
		{n="Wall carry slam · Pro", t="DASH_F M1x3 S2 M1x3 DOWNSLAM S1"},
		{n="Aerial Pinpoint block-break · Pro", t="JUMP S3 M1x3 DOWNSLAM S2 S1"},
		{n="Ignite finisher pressure · Sweaty", t="M1x3 DOWNSLAM S2 S1 M1x2"},
		{n="Counter into Pinpoint mixup · Pro", t="S4 M1x2 S3 DASH_L M1x2 S1 M1x3 DOWNSLAM S2"},
		{n="Pinpoint stop-and-go route · Sweaty", t="M1x4 S3 DASH_F M1x3 DOWNSLAM S2 S1 M1x4"},
	}},
	["Wild Psychic"] = { slots="1=Crushing Pull  2=Windstorm Fury  3=Stone Coffin  4=Expulsive Push   [slots ~est]", combos={
		{n="Bread-and-Butter (published Easy) · Easy", t="M1x4 S2 S1 DOWNSLAM"},
		{n="Tornado Extend · Easy", t="M1x3 S2 M1x4 S1 DOWNSLAM"},
		{n="Pull Starter · Easy", t="S1 M1x4 S2 M1x2 DOWNSLAM"},
		{n="Air Lift Route · Sweaty", t="M1x3 UPPERCUT S1 DOWNSLAM S2 M1x3 DOWNSLAM"},
		{n="Beginner One-Shot · Sweaty", t="DASH_F M1x3 DASH_B S3 WAIT M1x3 DOWNSLAM S2 WAIT M1x3 DOWNSLAM"},
		{n="Published Medium Route · Sweaty", t="M1x3 DASH_L DASH_F M1x4 S4 M1x3 DASH_R DASH_F M1x3 DOWNSLAM S2 M1x4 S1"},
		{n="Stone Coffin Wall Carry · Sweaty", t="M1x4 S1 M1x3 S3 M1x4 DOWNSLAM"},
		{n="Published Hard Route · Pro", t="M1x3 DOWNSLAM S2 M1x3 DOWNSLAM S3 M1x3 UPPERCUT DASH_F M1x3 S1 S4"},
		{n="Uppercut Loop Tech · Pro", t="M1x3 UPPERCUT DASH_F M1x3 UPPERCUT DASH_F M1x3 S2 M1x4 DOWNSLAM"},
		{n="Windstorm Quick-Uppercut Tech · Pro", t="M1x4 S2 WAIT UPPERCUT DASH_F M1x3 S1 DOWNSLAM"},
		{n="Wall Pin Double-Coffin Loop · Pro", t="S1 M1x4 S3 M1x4 DOWNSLAM S2 M1x3 DOWNSLAM"},
		{n="Expulsive Reset Route · Sweaty", t="M1x3 S4 DASH_F M1x4 S2 M1x3 S1 DOWNSLAM"},
		{n="Full Kit Dump (one-shot attempt) · Insane", t="S1 M1x4 S3 M1x3 DOWNSLAM S2 M1x4 UPPERCUT DASH_F M1x3 S4 DOWNSLAM"},
		{n="Block-Punish Starter · Easy", t="BLOCK S1 M1x4 S2 M1x3 DOWNSLAM"},
	}},
	["Martial Artist"] = { slots="1=Bullet Barrage  2=Vanishing Kick  3=Whirlwind Drop  4=Head First   [slots ~est]", combos={
		{n="BnB ground starter · Easy", t="M1x3 S1 S2 S3"},
		{n="Downslam BnB (~80%) · Easy", t="M1x3 DOWNSLAM S1 S2 S2 DOWNSLAM S3"},
		{n="Dash-in Downslam BnB · Easy", t="DASH_F M1x3 DOWNSLAM S1 S2 S2 DOWNSLAM S3"},
		{n="Whirlwind reset string · Sweaty", t="M1x3 S1 S3 S2 DASH_F M1x4 S2"},
		{n="Uppercut three-special route (~95) · Sweaty", t="M1x3 UPPERCUT S2 DASH_F M1x3 UPPERCUT S1 DOWNSLAM DASH_L S4 DASH_F M1x4"},
		{n="Vanishing Kick gap-close into BnB · Easy", t="S2 M1x3 S1 S2 S3"},
		{n="Safe ground-to-air transition · Easy", t="S2 M1x3 S3 S2"},
		{n="Head First opener · Sweaty", t="DASH_F M1x3 S4 M1x3 S1 S2 S3"},
		{n="100% wall combo · Pro", t="DASH_F M1x3 UPPERCUT S4 M1x3 DOWNSLAM S1 S3 M1x4 DASH_F S2 S2"},
		{n="Double-downslam wall extender · Pro", t="M1x3 UPPERCUT DOWNSLAM S1 DOWNSLAM S4 M1x3 S3"},
		{n="Dash-cancel pressure loop · Sweaty", t="M1x4 DASH_F M1x3 S1 S2 DASH_F M1x4"},
		{n="Counter punish · Sweaty", t="BLOCK S2 M1x3 S1 S2 DOWNSLAM S3"},
		{n="Air-to-ground catch · Pro", t="M1x3 UPPERCUT DASH_F M1x2 S1 DOWNSLAM S4 S3"},
		{n="Quick poke ender · Easy", t="M1x2 S2 S1 S3"},
		{n="Full optimal max-damage · Insane", t="DASH_F M1x3 UPPERCUT S2 DASH_F M1x3 UPPERCUT S1 DOWNSLAM S4 M1x4 DASH_F S2 S2 S3"},
	}},
	["Tech Prodigy"] = { slots="1=Weboom  2=Plasma Cannon  3=Trinity Tear  4=Twin Burst   [slots ~est]", combos={
		{n="Bread-and-butter uppercut downslam · Easy", t="M1x3 UPPERCUT JUMP DOWNSLAM"},
		{n="Trinity Tear opener · Easy", t="M1x3 UPPERCUT DASH_F M1x2 S3"},
		{n="Twin Burst into aerial Trinity Tear · Easy", t="M1x3 S4 S3"},
		{n="Plasma Cannon finisher route · Sweaty", t="M1x3 UPPERCUT DASH_F M1x2 S4 S3 S2"},
		{n="Weboom setup mid-combo · Sweaty", t="M1x3 UPPERCUT S1 DASH_F M1x3 S3"},
		{n="One-shot / instant-death route (NamuWiki) · Pro", t="M1x4 S3 S4 M1x4 S2 DASH_F M1x4 S1"},
		{n="True-combo extender (multi-special chain) · Pro", t="M1x3 UPPERCUT S4 DASH_F M1x3 UPPERCUT S1 JUMP DOWNSLAM DASH_L S3 DASH_F M1x4"},
		{n="Pincer Barrage wall combo (basic) · Sweaty", t="DASH_F M1x3 M1x4"},
		{n="Wall carry into Pincer · Pro", t="M1x3 UPPERCUT DASH_F M1x2 S3 M1x4"},
		{n="Full wall sweat route · Insane", t="M1x3 S4 S3 M1x3 M1x4 S2"},
		{n="Weboom zoning trap into punish · Sweaty", t="S1 WAIT DASH_F M1x3 UPPERCUT JUMP DOWNSLAM"},
		{n="Block-punish starter · Sweaty", t="BLOCK M1x3 UPPERCUT DASH_F M1x2 S4 S3"},
		{n="Dash-cancel pressure reset · Pro", t="M1x2 DASH_F M1x3 UPPERCUT S3 DASH_B S2"},
		{n="Max-damage cooldown dump · Insane", t="M1x3 UPPERCUT S4 S3 DASH_F M1x3 S1 S2 JUMP DOWNSLAM"},
	}},
	["Undying Hero"] = { slots="1=Grave Maker  2=Point Blank  3=Blast Breaker  4=Crossfire", combos={
		{n="Bread-and-butter starter · Easy", t="M1x3 UPPERCUT S1 DOWNSLAM"},
		{n="Point Blank punish · Easy", t="M1x3 UPPERCUT S2 DOWNSLAM"},
		{n="Point Blank true-extend · Easy", t="M1x3 S2 DASH_F M1x3 UPPERCUT S1 DOWNSLAM"},
		{n="Grave Maker dash-cancel pressure · Easy", t="S1 DASH_F M1x3 UPPERCUT S2 DOWNSLAM"},
		{n="Verified guide medium combo (~95 dmg) · Sweaty", t="M1x3 UPPERCUT S2 DASH_F M1x3 UPPERCUT S1 DOWNSLAM DASH_L S3 DASH_F M1x4"},
		{n="Airborne Blast Breaker route · Sweaty", t="M1x3 UPPERCUT S3 DASH_F M1x3 UPPERCUT S1 DOWNSLAM"},
		{n="Double-launch extender · Sweaty", t="M1x3 UPPERCUT S1 DASH_F M1x3 UPPERCUT S2 DOWNSLAM"},
		{n="Crossfire opener into juggle · Sweaty", t="S4 M1x3 UPPERCUT S1 DOWNSLAM"},
		{n="Full meter dump · Pro", t="M1x3 UPPERCUT S2 DASH_F M1x3 UPPERCUT S1 DOWNSLAM DASH_L S3 DASH_F M1x3 UPPERCUT S4"},
		{n="Wall carry corner lock · Pro", t="M1x3 UPPERCUT S1 M1x2 S2 DOWNSLAM"},
		{n="Wall Blast Breaker stack · Pro", t="M1x3 UPPERCUT S3 S1 DOWNSLAM DASH_F M1x2 S2"},
		{n="No-meter punish · Easy", t="M1x3 UPPERCUT S1 DOWNSLAM DASH_F M1x4"},
		{n="Block-bait into unblockable · Sweaty", t="BLOCK WAIT M1x2 UPPERCUT S1 S2 DOWNSLAM"},
		{n="Max-damage sweat route · Insane", t="S1 DASH_F M1x3 UPPERCUT S2 DASH_F M1x3 UPPERCUT S3 DASH_F M1x3 UPPERCUT S1 DOWNSLAM"},
		{n="Wall infinite-style loop attempt · Insane", t="M1x3 UPPERCUT S1 M1x2 S1 M1x2 S2 DOWNSLAM"},
	}},
	["Generic / Other"] = { slots="Universal: M1/dash/uppercut/downslam + Skill 1-4", combos={
		{n="Basic launcher · Easy", t="M1x3 UPPERCUT WAIT DASH_L M1x3"},
		{n="Downslam string · Easy", t="M1x4 DOWNSLAM WAIT S1"},
		{n="Juggle · Pro", t="M1x3 UPPERCUT WAIT DASH_R M1x3 DOWNSLAM WAIT S1 S2"},
	}},
}
local DETECT_TOKENS = {
	["The Strongest Hero"]={"strongest hero","saitama","caped","bald"},
	["Hero Hunter"]={"hero hunter","garou"},
	["Destructive Cyborg"]={"destructive cyborg","genos","cyborg"},
	["Deadly Ninja"]={"deadly ninja","sonic","speed-o"},
	["Brutal Demon"]={"brutal demon","metal bat","metalbat","adrenaline"},
	["Blade Master"]={"blade master","atomic","samurai"},
	["Wild Psychic"]={"wild psychic","tatsumaki","fubuki","tornado"},
	["Martial Artist"]={"martial artist","suiryu"},
	["Tech Prodigy"]={"tech prodigy","child emperor","prodigy"},
	["Undying Hero"]={"undying hero","zombieman","undying"},
}
function detectCharacter()
	local hit
	local function test(s)
		if hit or s==nil then return end
		s=tostring(s):lower()
		for char,toks in pairs(DETECT_TOKENS) do for _,t in ipairs(toks) do if s:find(t,1,true) then hit=char; return end end end
	end
	pcall(function()
		local c = LP_.Character
		if c then test(c.Name); for k,v in pairs(c:GetAttributes()) do test(k); test(v) end
			for _,d in ipairs(c:GetDescendants()) do test(d.Name); if d:IsA("StringValue") then test(d.Value) end end end
		for _,d in ipairs(LP_:GetChildren()) do test(d.Name); if d:IsA("StringValue") then test(d.Value) end end
	end)
	return hit
end
function scanCharacter()
	print("[Vaultix] ───── character scan (send me this) ─────")
	pcall(function()
		local c = LP_.Character
		print("Character model name:", c and c.Name)
		if c then for k,v in pairs(c:GetAttributes()) do print("  attr:", k, "=", v) end
			for _,d in ipairs(c:GetChildren()) do print("  child:", d.ClassName, "|", d.Name, d:IsA("StringValue") and ("= "..tostring(d.Value)) or "") end end
		for _,d in ipairs(LP_:GetChildren()) do print("  player:", d.ClassName, "|", d.Name) end
	end)
	print("[Vaultix] ───── end scan ─────")
end

-- ───────── load Rayfield (ROBUST: retry so the menu shows on the FIRST execution, not the 3rd) ─────────
local Rayfield
do
	local URLS = {"https://sirius.menu/rayfield", "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"}
	local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
	local function fetch(u)
		local ok, src = pcall(function() return game:HttpGet(u, true) end)
		if ok and type(src)=="string" and #src>2000 then return src end
		ok, src = pcall(function() return game:HttpGetAsync(u, true) end)
		if ok and type(src)=="string" and #src>2000 then return src end
		if req then local ok2, r = pcall(function() return req({Url=u, Method="GET"}) end); if ok2 and type(r)=="table" and type(r.Body)=="string" and #r.Body>2000 then return r.Body end end
		return nil
	end
	if getgenv and type(getgenv().__VAULTIX_RF_SRC)=="string" then                         -- reuse a cached source from a prior run = instant menu
		local ok, lib = pcall(function() return loadstring(getgenv().__VAULTIX_RF_SRC)() end)
		if ok and type(lib)=="table" then Rayfield = lib end
	end
	for _=1,6 do
		if Rayfield then break end
		for _,u in ipairs(URLS) do
			local src = fetch(u)
			if src then
				local ok, lib = pcall(function() return loadstring(src)() end)
				if ok and type(lib)=="table" then Rayfield = lib; if getgenv then getgenv().__VAULTIX_RF_SRC = src end; break end
			end
		end
		if not Rayfield then task.wait(0.4) end                                            -- brief wait, then retry (same execution)
	end
end
if type(Rayfield)~="table" then
	warn("[Vaultix] Rayfield UI failed to load after retries - check internet/executor HttpGet, then re-execute.")
	if CFG then CFG.lockOn=false; if onLockChanged then pcall(onLockChanged, false) end end  -- don't leave the camera hijacked with no menu to stop it
	do return end                                                                          -- abort the GUI build cleanly (engine already loaded)
end
local function notify(title, content, dur) pcall(function() Rayfield:Notify({Title=title, Content=content, Duration=dur or 3}) end) end

local RED = {
	TextColor = Color3.fromRGB(240,234,235), Background = Color3.fromRGB(18,13,14),
	Topbar = Color3.fromRGB(27,18,20), Shadow = Color3.fromRGB(9,6,7),
	NotificationBackground = Color3.fromRGB(24,16,18), NotificationActionsBackground = Color3.fromRGB(205,46,52),
	TabBackground = Color3.fromRGB(33,22,24), TabStroke = Color3.fromRGB(64,32,36),
	TabBackgroundSelected = Color3.fromRGB(205,46,52), TabTextColor = Color3.fromRGB(205,194,196),
	SelectedTabTextColor = Color3.fromRGB(255,255,255), ElementBackground = Color3.fromRGB(31,21,23),
	ElementBackgroundHover = Color3.fromRGB(46,29,32), SecondaryElementBackground = Color3.fromRGB(26,18,20),
	ElementStroke = Color3.fromRGB(62,34,38), SecondaryElementStroke = Color3.fromRGB(54,30,34),
	SliderBackground = Color3.fromRGB(74,24,28), SliderProgress = Color3.fromRGB(225,55,55), SliderStroke = Color3.fromRGB(210,62,66),
	ToggleBackground = Color3.fromRGB(40,26,28), ToggleEnabled = Color3.fromRGB(225,55,55), ToggleDisabled = Color3.fromRGB(96,74,76),
	ToggleEnabledStroke = Color3.fromRGB(240,92,92), ToggleDisabledStroke = Color3.fromRGB(72,56,58),
	ToggleEnabledOuterStroke = Color3.fromRGB(188,46,50), ToggleDisabledOuterStroke = Color3.fromRGB(50,40,42),
	DropdownSelected = Color3.fromRGB(46,29,32), DropdownUnselected = Color3.fromRGB(28,19,21),
	InputBackground = Color3.fromRGB(31,21,23), InputStroke = Color3.fromRGB(70,38,42), PlaceholderColor = Color3.fromRGB(150,118,120),
}
local Window = Rayfield:CreateWindow({
	Name = "Vaultix Hub PLUS", LoadingTitle = "Vaultix Hub PLUS", LoadingSubtitle = "TSB Tech Builder v3.0 + extras",
	Theme = RED, DisableRayfieldPrompts = true, ConfigurationSaving = { Enabled = false }, KeySystem = false,
})

local comboBtn, lockToggle, selChar
onLockChanged = function(v) if lockToggle then pcall(function() lockToggle:Set(v) end) end end
function comboText()
	if #seq==0 then return "Combo is empty — add moves below" end
	local parts={}; for _,s in ipairs(seq) do parts[#parts+1]=(s.label or s.act or "?") end
	return "["..#seq.."]  "..table.concat(parts, "  >  ")
end
function refreshCombo() if comboBtn then pcall(function() comboBtn:Set(comboText()) end) end end
rebuildSteps = refreshCombo
function loadPreset(name, alsoRun)
	local p = name and PRESETS[name]
	if not (p and p.steps) then notify("No combo", tostring(name), 3); return end
	loadSeq(p.steps); if alsoRun then task.wait(0.15); runSeq() else notify("Loaded", name, 3) end
end
-- AUTO-COMBO: after a tech finishes, load + run a RANDOM combo for the selected character
function autoNext()
	local c = CHARS[selChar or "Generic / Other"]
	if not (c and c.combos and #c.combos>0) then return end
	local cb = c.combos[math.random(1, #c.combos)]
	loadSeq(mkSteps(cb.t)); notify("Auto-combo", cb.n, 2); task.wait(0.15); runSeq()
end
onRunDone = function(natural)
	if natural and CFG.autoCombo then task.delay(0.5, function() if CFG.autoCombo and STATE=="idle" then autoNext() end end) end
end

-- ───────── FIGHT tab (reworked: the one-click "just win the 1v1" page) ─────────
do
	local tab = Window:CreateTab("Fight", 4483362458)
	tab:CreateSection("One-click fight")
	tab:CreateButton({ Name = "LOCK + RUN COMBO  (nearest enemy)", Callback = function()
		CFG.lockOn = true; if lockToggle then pcall(function() lockToggle:Set(true) end) end
		lockTarget = nil; refreshLock()
		local ch = (selChar and selChar~="Generic / Other" and selChar) or detectCharacter() or "Generic / Other"
		local c = CHARS[ch]; local cb = c and c.combos and c.combos[1]
		if not (cb and currentTargetPart()) and not cb then notify("Fight","no combo found for "..ch,3); return end
		if not currentTargetPart() then notify("Fight","no enemy in lock range — get closer",3); return end
		loadSeq(mkSteps(cb.t)); notify("Fight", ch.." · "..cb.n, 3); task.wait(0.12); runSeq()
	end })
	tab:CreateButton({ Name = "STOP", Callback = function() stopSeq(); notify("Stopped","fight off · lock-on stays on",2) end })
	tab:CreateToggle({ Name = "Auto-repeat: keep running the combo on the nearest enemy", CurrentValue = CFG.autoCombo and true or false, Callback = function(v)
		CFG.autoCombo = v; saveCfg()
		if v then
			CFG.lockOn = true; if lockToggle then pcall(function() lockToggle:Set(true) end) end
			lockTarget=nil; refreshLock()
			if STATE=="idle" and currentTargetPart() then autoNext() end
		end
	end })
	tab:CreateSection("Make hits land")
	tab:CreateToggle({ Name = "Chase: close the gap so the combo reaches (bounded, no noob-running)", CurrentValue = CFG.chase and true or false, Callback = function(v) CFG.chase = v; notify("Chase", v and "ON" or "OFF (runs in place)", 2) end })
	tab:CreateToggle({ Name = "M1 Reach (hitbox expander — visual, server may ignore)", CurrentValue = CFG.hitbox and true or false, Callback = function(v) setHitbox(v); notify("M1 Reach", v and "ON" or "OFF", 2) end })
	tab:CreateSlider({ Name = "M1 Reach size", Range = {4,60}, Increment = 1, Suffix = " studs", CurrentValue = CFG.hitboxSize or 12, Callback = function(v) CFG.hitboxSize = v; saveCfg() end })
	tab:CreateSlider({ Name = "Combo speed (lower = faster)", Range = {10,200}, Increment = 5, Suffix = "%", CurrentValue = math.floor((CFG.comboSpeed or 1)*100), Callback = function(v) CFG.comboSpeed = v/100; saveCfg() end })
	tab:CreateSection("Defense")
	tab:CreateToggle({ Name = "Auto-evade (dash out the moment you recover from a knockdown)", CurrentValue = CFG.autoEvade and true or false, Callback = function(v) CFG.autoEvade = v; saveCfg(); notify("Auto-evade", v and "ON" or "OFF", 2) end })
	tab:CreateSection("Aim")
	lockToggle = tab:CreateToggle({ Name = "Lock-On (console-style: enemy centered)", CurrentValue = CFG.lockOn and true or false, Callback = function(v) CFG.lockOn = v; if not v then lockTarget=nil end; saveCfg() end })
	tab:CreateKeybind({ Name = "Run / STOP", CurrentKeybind = CFG.runKey or "T", HoldToInteract = false, Callback = function() triggerRun() end })
	tab:CreateKeybind({ Name = "Toggle lock-on", CurrentKeybind = CFG.lockKey or "C", HoldToInteract = false, Callback = function()
		CFG.lockOn = not CFG.lockOn; if not CFG.lockOn then lockTarget=nil end; saveCfg()
		if lockToggle then pcall(function() lockToggle:Set(CFG.lockOn) end) end
		notify("Lock-on", CFG.lockOn and "ON" or "OFF", 2)
	end })
end

-- ───────── BUILDER tab ─────────
do
	local tab = Window:CreateTab("Builder", 4483362458)
	tab:CreateSection("Your combo")
	comboBtn = tab:CreateButton({ Name = comboText(), Callback = printCombo })
	tab:CreateSection("Strikes")
	tab:CreateButton({ Name = "M1",    Callback = function() addStep(M1(1)) end })
	tab:CreateButton({ Name = "M1 x2", Callback = function() addStep(M1(2)) end })
	tab:CreateButton({ Name = "M1 x3", Callback = function() addStep(M1(3)) end })
	tab:CreateButton({ Name = "M1 Hold", Callback = function() addStep(M1H()) end })
	tab:CreateSection("Dashes (target-relative)")
	tab:CreateButton({ Name = "Dash Forward", Callback = function() addStep(DASH("W")) end })
	tab:CreateButton({ Name = "Dash Back",    Callback = function() addStep(DASH("S")) end })
	tab:CreateButton({ Name = "Dash Left",  Callback = function() addStep(DASH("A")) end })
	tab:CreateButton({ Name = "Dash Right", Callback = function() addStep(DASH("D")) end })
	tab:CreateSection("Specials")
	tab:CreateButton({ Name = "Uppercut", Callback = function() addStep(UPC()) end })
	tab:CreateButton({ Name = "Downslam", Callback = function() addStep(DS()) end })
	tab:CreateButton({ Name = "Jump",     Callback = function() addStep(JUMP()) end })
	tab:CreateButton({ Name = "Re-Lock",  Callback = function() addStep(RLK()) end })
	tab:CreateButton({ Name = "Wait 150 ms", Callback = function() addStep(WAIT(150)) end })
	tab:CreateButton({ Name = "Wait 300 ms", Callback = function() addStep(WAIT(300)) end })
	tab:CreateSection("Skills (keys 1-4)")
	tab:CreateButton({ Name = "Skill 1", Callback = function() addStep(SK(1)) end })
	tab:CreateButton({ Name = "Skill 2", Callback = function() addStep(SK(2)) end })
	tab:CreateButton({ Name = "Skill 3", Callback = function() addStep(SK(3)) end })
	tab:CreateButton({ Name = "Skill 4", Callback = function() addStep(SK(4)) end })
	tab:CreateButton({ Name = "Ultimate", Callback = function() addStep(ULT()) end })
	tab:CreateSection("Run / Edit")
	tab:CreateButton({ Name = "RUN TECH", Callback = function() notify("Running tech","watch your character",2); runSeq() end })
	tab:CreateButton({ Name = "STOP", Callback = function() stopSeq(); notify("Stopped","tech off · lock-on stays on",2) end })
	tab:CreateButton({ Name = "Remove last step", Callback = function() if #seq>0 then table.remove(seq); refreshCombo() end end })
	tab:CreateButton({ Name = "Clear all", Callback = function() clearSeq(); notify("Cleared","",2) end })
	tab:CreateButton({ Name = "Print combo (F9)", Callback = printCombo })
	tab:CreateButton({ Name = "Check my combo (smart analysis)", Callback = function()
		local e = validateSeq(); local hard,warn = 0,0
		for _,x in ipairs(e) do if x.status=="warn" then warn=warn+1 else hard=hard+1 end end
		if #e==0 then notify("Combo looks clean","no issues found",4)
		else notify(hard.." errors, "..warn.." warnings","see F9 (Print) for details",5) end
		print("[Vaultix] combo check: "..hard.." errors / "..warn.." warnings")
		for _,x in ipairs(e) do print("  "..(x.status=="warn" and "[warn]" or "[ERR] ").." "..((x.row and x.row>0) and ("#"..x.row.." ") or "")..tostring(x.text)) end
	end })
	tab:CreateKeybind({ Name = "Run / STOP hotkey", CurrentKeybind = CFG.runKey or "T", HoldToInteract = false, Callback = function() triggerRun() end })
end

-- ───────── CHARACTER tab ─────────
do
	local tab = Window:CreateTab("Character", 4483362458)
	local auto = detectCharacter()
	selChar = auto or "Generic / Other"
	local selN = 1
	local comboDrop
	local function comboNames(charName)
		local c = CHARS[charName]; local out = {}
		if c and c.combos then for i,cb in ipairs(c.combos) do out[i] = i..". "..cb.n end end
		if #out==0 then out[1] = "(no combos)" end
		return out
	end
	if auto then notify("Detected character", auto, 4) end
	local function loadCharCombo(n, run)
		local c = CHARS[selChar]; local cb = c and c.combos and c.combos[n]
		if not cb then notify("No combo #"..tostring(n), "pick a lower # for "..tostring(selChar), 3); return end
		local ok = pcall(function()
			local steps = mkSteps(cb.t)
			loadSeq(steps)
			CFG.sweat = (cb.n:find("Sweaty") or cb.n:find("Pro") or cb.n:find("Insane")) and true or false   -- auto-enable SWEAT tech (shift-lock + side-dash) for Sweaty+ combos
			print("[Vaultix] LOADED '"..cb.n.."' = "..cb.t.."  ("..#steps.." steps"..(CFG.sweat and ", SWEAT on" or "")..").")
			if run then notify("Running: "..cb.n, "watch your character", 2); task.wait(0.2); runSeq()
			else notify("Loaded: "..cb.n, #steps.." steps -> press RUN or T", 4) end
		end)
		if not ok then notify("Load failed", "see F9 console", 3); warn("[Vaultix] loadCharCombo error for "..tostring(selChar).." #"..tostring(n)) end
	end
	tab:CreateSection("Pick your character + combo")
	tab:CreateDropdown({ Name = "Character", Options = CHARS_ORDER, CurrentOption = selChar, Callback = function(o)
		selChar = (type(o)=="table") and o[1] or o; selN = 1
		if comboDrop then pcall(function() comboDrop:Refresh(comboNames(selChar), false) end) end
		notify("Character: "..selChar, "combo list updated", 2)
	end })
	comboDrop = tab:CreateDropdown({ Name = "Combo (pick one)", Options = comboNames(selChar), CurrentOption = comboNames(selChar)[1], Callback = function(o)
		local txt = (type(o)=="table") and o[1] or o
		local n = tonumber(tostring(txt):match("^(%d+)")); if n then selN = n end
	end })
	tab:CreateButton({ Name = "Load combo", Callback = function() loadCharCombo(selN) end })
	tab:CreateButton({ Name = "Load combo + RUN", Callback = function() loadCharCombo(selN, true) end })
	tab:CreateToggle({ Name = "Auto-combo: chain RANDOM combos for this character", CurrentValue = CFG.autoCombo and true or false, Callback = function(v) CFG.autoCombo = v; saveCfg(); if v and STATE=="idle" then autoNext() end end })
	tab:CreateButton({ Name = "Show this character's combos + moves (console)", Callback = function()
		local c = CHARS[selChar]; if not c then return end
		print("[Vaultix] "..selChar.."  | move slots: "..(c.slots or "?"))
		for i,cb in ipairs(c.combos) do print("  #"..i.."  "..cb.n) end
	end })
	tab:CreateButton({ Name = "Scan my character (console) — send me this", Callback = scanCharacter })
end

-- ───────── PRESETS tab ─────────
do
	local tab = Window:CreateTab("Presets", 4483362458)
	tab:CreateSection("Universal ready-made techs")
	local chosen = PRESET_ORDER[1]
	tab:CreateDropdown({ Name = "Preset", Options = PRESET_ORDER, CurrentOption = PRESET_ORDER[1], Callback = function(o) chosen = (type(o)=="table") and o[1] or o end })
	tab:CreateButton({ Name = "Load selected", Callback = function() loadPreset(chosen) end })
	tab:CreateButton({ Name = "Load + Run", Callback = function() loadPreset(chosen, true) end })
end

-- ───────── SAVED tab ─────────
do
	local tab = Window:CreateTab("Saved", 4483362458)
	tab:CreateSection("Save / load your own techs")
	local nm = ""
	tab:CreateInput({ Name = "Tech name", PlaceholderText = "my_combo", RemoveTextAfterFocusLost = false, Callback = function(t) nm = sanitizeName(t or "") end })   -- sanitize so the path matches the engine's
	tab:CreateButton({ Name = "Save current combo", Callback = function()
		if nm=="" then notify("Name needed","type a name first",3); return end
		if #seq==0 then notify("Empty","build a combo first",3); return end
		local ok = saveTech(nm); notify(ok and "Saved" or "Save failed", ok and ("'"..nm.."'") or "no file access on this executor", 3)
	end })
	tab:CreateButton({ Name = "Load by name", Callback = function()
		if nm=="" then notify("Name needed","type a name first",3); return end
		if loadTechFile(nm) then notify("Loaded","'"..nm.."' -> press RUN",3) else notify("Load failed","missing, corrupt, or empty save",3) end   -- only says Loaded if it really loaded
	end })
	tab:CreateButton({ Name = "Delete by name", Callback = function() if nm~="" then deleteTech(nm); notify("Deleted","'"..nm.."'",3) end end })
	tab:CreateButton({ Name = "List saved (console)", Callback = function()
		local l = listTechs() or {}; print("[Vaultix] saved ("..#l.."):"); for _,n in ipairs(l) do print(" - "..n) end
	end })
end

-- ───────── SETTINGS tab ─────────
do
	local tab = Window:CreateTab("Settings", 4483362458)
	tab:CreateSection("Timing")
	tab:CreateSlider({ Name = "Combo speed (lower = faster)", Range = {10,200}, Increment = 5, Suffix = "%", CurrentValue = math.floor((CFG.comboSpeed or 1)*100), Callback = function(v) CFG.comboSpeed = v/100; saveCfg() end })
	tab:CreateSlider({ Name = "Loop delay", Range = {0,2000}, Increment = 50, Suffix = "ms", CurrentValue = CFG.loopDelay or 350, Callback = function(v) CFG.loopDelay = v; saveCfg() end })
	tab:CreateDropdown({ Name = "M1 ping profile", Options = {"Safe","Normal","Fast","HighPing"}, CurrentOption = CFG.m1Profile or "Normal", Callback = function(o)
		CFG.m1Profile = (type(o)=="table") and o[1] or o
		local g = M1GAP[CFG.m1Profile] or 250
		for _,s in ipairs(seq) do if s.act=="m1" then s.repeatGap = g end end
		refreshCombo(); saveCfg()
	end })
	tab:CreateDropdown({ Name = "Run mode", Options = {"Toggle","Hold"}, CurrentOption = CFG.runMode or "Toggle", Callback = function(o) CFG.runMode = (type(o)=="table") and o[1] or o; saveCfg() end })
	tab:CreateSection("Targeting")
	tab:CreateSlider({ Name = "Lock range", Range = {20,300}, Increment = 10, Suffix = " studs", CurrentValue = CFG.lockRange or 180, Callback = function(v) CFG.lockRange = v; saveCfg() end })
	tab:CreateSlider({ Name = "Lock cam distance (behind you)", Range = {6,24}, Increment = 1, Suffix = " studs", CurrentValue = CFG.lockDist or 12, Callback = function(v) CFG.lockDist = v; saveCfg() end })
	lockToggle = tab:CreateToggle({ Name = "Lock-On (console-style: enemy centered)", CurrentValue = CFG.lockOn and true or false, Callback = function(v) CFG.lockOn = v; if not v then lockTarget=nil end; saveCfg() end })
	tab:CreateToggle({ Name = "Switch target freely when idle", CurrentValue = CFG.retarget and true or false, Callback = function(v) CFG.retarget = v; saveCfg() end })
	tab:CreateToggle({ Name = "Target-relative dash/move", CurrentValue = CFG.aimMove and true or false, Callback = function(v) CFG.aimMove = v; saveCfg() end })
	tab:CreateSection("Options")
	tab:CreateToggle({ Name = "Loop the tech", CurrentValue = CFG.loop and true or false, Callback = function(v) CFG.loop = v; saveCfg() end })
	tab:CreateToggle({ Name = "Stop if I die", CurrentValue = CFG.stopOnDeath and true or false, Callback = function(v) CFG.stopOnDeath = v; saveCfg() end })
	tab:CreateToggle({ Name = "Debug logging (F9)", CurrentValue = CFG.debug and true or false, Callback = function(v) CFG.debug = v; saveCfg() end })
	tab:CreateSection("Smart")
	tab:CreateToggle({ Name = "Chase: walk/dash toward a far target (OFF = run in place, no noob-running)", CurrentValue = CFG.chase and true or false, Callback = function(v) CFG.chase = v; notify("Chase target", v and "ON (will close distance)" or "OFF (runs in place)", 3) end })
	tab:CreateSlider({ Name = "Max chase time", Range = {4,40}, Increment = 1, Suffix = " (x0.1s)", CurrentValue = math.floor((CFG.chaseSecs or 1.4)*10), Callback = function(v) CFG.chaseSecs = v/10; saveCfg() end })
	tab:CreateToggle({ Name = "Smart combat (dash IN so moves never whiff — needs Chase ON)", CurrentValue = CFG.smartCombat and true or false, Callback = function(v) CFG.smartCombat = v; saveCfg() end })
	tab:CreateToggle({ Name = "Dash INTO target (every combo dash closes onto the enemy)", CurrentValue = CFG.dashToTarget and true or false, Callback = function(v) CFG.dashToTarget = v; saveCfg(); notify("Dash into target", v and "ON" or "OFF", 2) end })
	tab:CreateToggle({ Name = "Sweat tech (shift-lock flick + side-dash during M1s)", CurrentValue = CFG.sweat and true or false, Callback = function(v) CFG.sweat = v; notify("Sweat tech", v and "ON" or "OFF", 2) end })
	tab:CreateToggle({ Name = "Mobile button bar (touch Run/Stop/Lock/Jump/Dash)", CurrentValue = CFG.mobileBar and true or false, Callback = function(v) CFG.mobileBar = v; saveCfg(); if v then pcall(buildMobileBar) elseif mobileSG then pcall(function() mobileSG:Destroy() end) end; notify("Mobile bar", v and "ON" or "OFF", 2) end })
	tab:CreateSlider({ Name = "Melee reach (close gap within)", Range = {8,30}, Increment = 1, Suffix = " studs", CurrentValue = CFG.meleeRange or 16, Callback = function(v) CFG.meleeRange = v; saveCfg() end })
	tab:CreateToggle({ Name = "Skill-cooldown smart (M1 if a skill is on CD)", CurrentValue = CFG.smartCD and true or false, Callback = function(v) CFG.smartCD = v; saveCfg() end })
	tab:CreateToggle({ Name = "Smart re-engage (dash IN if target drifts out of reach)", CurrentValue = CFG.smartEngage and true or false, Callback = function(v) CFG.smartEngage = v; saveCfg() end })
	tab:CreateSlider({ Name = "Skill cooldown estimate", Range = {2,30}, Increment = 1, Suffix = "s", CurrentValue = CFG.skillCD or 8, Callback = function(v) CFG.skillCD = v; saveCfg() end })
	tab:CreateSlider({ Name = "Stop tech if target farther than", Range = {15,80}, Increment = 5, Suffix = " studs", CurrentValue = CFG.fightStopDist or 35, Callback = function(v) CFG.fightStopDist = v; saveCfg() end })
end

-- ───────── COMBAT tab ─────────
do
	local tab = Window:CreateTab("Combat", 4483362458)
	tab:CreateSection("Stop")
	tab:CreateButton({ Name = "STOP (tech)", Callback = function() stopSeq(); notify("Stopped","tech off · lock-on stays on",2) end })
	tab:CreateSection("Targeting tools")
	tab:CreateButton({ Name = "Face nearest enemy now", Callback = function() local ok=faceTarget(); notify("Face target", ok and "aimed" or "no target in range", 2) end })
	tab:CreateButton({ Name = "Re-lock to nearest now", Callback = function() lockTarget=nil; refreshLock(); notify("Re-lock", lockPart and "locked nearest" or "no target", 2) end })
	tab:CreateInput({ Name = "Lock-on icon image id (blank = default reticle)", PlaceholderText = "rbxassetid://... or a number", RemoveTextAfterFocusLost = false, Callback = function(t) CFG.lockImage = t or ""; saveCfg(); pcall(function() if lockGui then lockGui:Destroy() end end); lockGui=nil; notify("Lock icon", (CFG.lockImage~="" and "custom image set" or "default reticle"), 3) end })
	tab:CreateSection("Auto-defense (sweat)")
	tab:CreateToggle({ Name = "Auto-evade (best-effort: dashes on knockdown recovery)", CurrentValue = CFG.autoEvade and true or false, Callback = function(v) CFG.autoEvade = v; saveCfg(); notify("Auto-evade", v and "ON" or "OFF", 2) end })
	tab:CreateDropdown({ Name = "Auto-evade dash direction", Options = {"Left","Right","Forward","Back","ToTarget"}, CurrentOption = CFG.evadeDir or "Right", Callback = function(o) CFG.evadeDir = (type(o)=="table") and o[1] or o; saveCfg(); notify("Evade dir", CFG.evadeDir, 2) end })
	tab:CreateToggle({ Name = "Anti-counter (best-effort guess; reads the enemy's stance, may misfire)", CurrentValue = CFG.antiCounter and true or false, Callback = function(v) CFG.antiCounter = v; saveCfg(); notify("Anti-counter", v and "ON" or "OFF", 2) end })
	tab:CreateSection("Hitbox + approach")
	tab:CreateToggle({ Name = "Hitbox Expander (VISUAL ONLY - server ignores it)", CurrentValue = CFG.hitbox and true or false, Callback = function(v) setHitbox(v); notify("Hitbox Expander", v and "ON (visual only)" or "OFF", 3) end })
	tab:CreateSlider({ Name = "Hitbox size", Range = {4,60}, Increment = 1, Suffix = " studs", CurrentValue = CFG.hitboxSize or 12, Callback = function(v) CFG.hitboxSize = v; saveCfg() end })
	tab:CreateToggle({ Name = "Auto-approach target on RUN (needs Chase ON)", CurrentValue = CFG.approach and true or false, Callback = function(v) CFG.approach = v; saveCfg() end })
	tab:CreateSection("Hotkeys")
	tab:CreateKeybind({ Name = "Run / STOP", CurrentKeybind = CFG.runKey or "T", HoldToInteract = false, Callback = function() triggerRun() end })
	tab:CreateKeybind({ Name = "Toggle lock-on", CurrentKeybind = CFG.lockKey or "C", HoldToInteract = false, Callback = function()
		CFG.lockOn = not CFG.lockOn; if not CFG.lockOn then lockTarget=nil end; saveCfg()
		if lockToggle then pcall(function() lockToggle:Set(CFG.lockOn) end) end
		notify("Lock-on", CFG.lockOn and "ON" or "OFF", 2)
	end })
	tab:CreateSection("Diagnostics")
	tab:CreateButton({ Name = "Test M1 / Dash / Walk (3s)", Callback = function() notify("Input test","tab into the game NOW",4); runDiagnostic() end })
	tab:CreateButton({ Name = "Unload script", Callback = function() if getgenv and type(getgenv().__TSB_UNLOAD)=="function" then getgenv().__TSB_UNLOAD() end end })
end

-- ───────── RECORD tab ─────────
do
	local tab = Window:CreateTab("Record", 4483362458)
	tab:CreateSection("Record gameplay into a tech")
	tab:CreateButton({ Name = "Start recording", Callback = function() startRecord(); notify("Recording","play your combo in-game",3) end })
	tab:CreateButton({ Name = "Stop recording", Callback = function() stopRecord(); refreshCombo(); printCombo() end })
	tab:CreateButton({ Name = "Print recorded combo (F9)", Callback = printCombo })
end


-- ════════════════════════════════════════════════════════════════════════════
-- ════════ PLUS FEATURE MODULES (everything the base has, PLUS these tabs) ════
-- Reliable client-side feats. Remote-gated ones (Void Kills / Saitama exploits)
-- are flagged honestly — use Utility ▸ Scan Remotes and send me the output.
-- ════════════════════════════════════════════════════════════════════════════
local TweenS = game:GetService("TweenService")
local Light  = game:GetService("Lighting")
local PX = { wsOn=false, ws=16, fly=false, flySpd=60, noclip=false, invis=false, ghost=false,
	freeze=false, fling=false, walkFling=false, noAnim=false, upside=false, noCD=false,
	infJump=false, jumpPow=50, antiRagdoll=false, antiVoid=false, lastSafe=nil,
	autoUpper=false, autoDownslam=false, aura=false, auraName="Fire", auraRainbow=false,
	aimlock=false, aimRange=250, streak=false, lastKills=nil, lastStreak=nil,
	antiTableFlip=false, antiSerious=false, antiOmni=false, antiGarou=false, antiIncin=false, antiDeath=false, antiDC=false, ultAlert=false,
	jumpOnCounter=false, counterLockOnly=false,
	gojoSel="Repulse", disgName="", disgOn=false, idleId="", walkId="", fps=false, fpsSaved=nil, spots={}, flingBV=nil, nameTag=nil }

-- ── anti-send-back teleport ──
local pxHoldCF, pxHoldUntil = nil, 0
track(RunSvc.RenderStepped:Connect(function()
	if pxHoldCF and os.clock() < pxHoldUntil then local r=myHRP(); if r then pcall(function() r.CFrame=pxHoldCF; r.AssemblyLinearVelocity=Vector3.zero end) end end
end))
function pxTP(cf, hold) local r=myHRP(); if not r then return end pcall(function() r.CFrame=cf; r.AssemblyLinearVelocity=Vector3.zero end); pxHoldCF=cf; pxHoldUntil=os.clock()+(hold or 0.6) end

-- ── walkspeed loop ──
track(RunSvc.Heartbeat:Connect(function() if PX.wsOn then local h=myHum(); if h then pcall(function() h.WalkSpeed=PX.ws end) end end end))

-- ── fly ──
local pxFK={W=false,A=false,S=false,D=false,U=false,Dn=false}
track(UIS.InputBegan:Connect(function(i,g) if g then return end local k=i.KeyCode
	if k==KC.W then pxFK.W=true elseif k==KC.A then pxFK.A=true elseif k==KC.S then pxFK.S=true elseif k==KC.D then pxFK.D=true
	elseif k==KC.Space then pxFK.U=true elseif k==KC.LeftControl then pxFK.Dn=true end end))
track(UIS.InputEnded:Connect(function(i) local k=i.KeyCode
	if k==KC.W then pxFK.W=false elseif k==KC.A then pxFK.A=false elseif k==KC.S then pxFK.S=false elseif k==KC.D then pxFK.D=false
	elseif k==KC.Space then pxFK.U=false elseif k==KC.LeftControl then pxFK.Dn=false end end))
track(RunSvc.RenderStepped:Connect(function(dt)
	if not PX.fly then return end
	local r=myHRP(); local cam=WS.CurrentCamera; if not (r and cam) then return end
	local h=myHum(); if h then pcall(function() h.PlatformStand=true end) end
	local d=Vector3.zero
	if pxFK.W then d+=cam.CFrame.LookVector end
	if pxFK.S then d-=cam.CFrame.LookVector end
	if pxFK.A then d-=cam.CFrame.RightVector end
	if pxFK.D then d+=cam.CFrame.RightVector end
	if pxFK.U then d+=Vector3.yAxis end
	if pxFK.Dn then d-=Vector3.yAxis end
	pcall(function() r.AssemblyLinearVelocity=Vector3.zero; if d.Magnitude>0 then r.CFrame=r.CFrame+d.Unit*PX.flySpd*dt end end)
end))
function pxSetFly(v) PX.fly=v; if not v then local h=myHum(); if h then pcall(function() h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end end

-- ── noclip / ghost ──
track(RunSvc.Stepped:Connect(function()
	if not (PX.noclip or PX.ghost) then return end
	local c=myChar(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then pcall(function() p.CanCollide=false end) end end
end))
function pxSetGhost(v) PX.ghost=v; local c=myChar(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.LocalTransparencyModifier = v and 0.6 or 0; if not v and p.Name~="HumanoidRootPart" then p.CanCollide=true end end) end end end
function pxSetNoclip(v) PX.noclip=v; if not v then local c=myChar(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then pcall(function() p.CanCollide=true end) end end end end end

-- ── hrp freeze ──
function pxSetFreeze(v) PX.freeze=v; local r=myHRP(); if r then pcall(function() r.Anchored=v end) end end

-- ── invisibility (local render) ──
function pxSetInvis(v) PX.invis=v; local c=myChar(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then pcall(function() p.LocalTransparencyModifier = v and 1 or 0 end) end end end

-- ── no animations ──
track(RunSvc.Heartbeat:Connect(function()
	if not PX.noAnim then return end
	local h=myHum(); if not h then return end
	local a=h:FindFirstChildOfClass("Animator"); if not a then return end
	local ok,tr=pcall(function() return a:GetPlayingAnimationTracks() end); if not ok then return end
	for _,t in ipairs(tr) do pcall(function() t:Stop(0) end) end
end))

-- ── upside down (FIXED: reapply the flip EVERY frame, else the humanoid re-levels you instantly) ──
function pxSetUpside(v) PX.upside=v; if not v then local h=myHum(); if h then pcall(function() h.AutoRotate=true end) end end end
track(RunSvc.RenderStepped:Connect(function()
	if not PX.upside then return end
	local r=myHRP(); local h=myHum(); if not r then return end
	if h then pcall(function() h.AutoRotate=false end) end                      -- stop the humanoid fighting the flip
	local look = r.CFrame.LookVector; local pos = r.Position
	local flat = Vector3.new(look.X, 0, look.Z); if flat.Magnitude<0.01 then flat=Vector3.new(0,0,-1) end
	pcall(function() r.CFrame = CFrame.lookAt(pos, pos+flat) * CFrame.Angles(0,0,math.pi) end)   -- flipped 180° on roll, every frame
end))

-- ── infinite jump + jump power (client-side, reliable) ──
track(UIS.JumpRequest:Connect(function()
	if not PX.infJump then return end
	local h=myHum(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end))
track(RunSvc.Heartbeat:Connect(function()
	if PX.jumpPow and PX.jumpPow~=50 then local h=myHum(); if h then pcall(function() h.UseJumpPower=true; h.JumpPower=PX.jumpPow end) end end
end))

-- ── ANTI-RAGDOLL / AUTO GET-UP (researched: recover from stuns/knockdowns instantly) ──
-- TSB is server-validated so this won't make you immortal, but forcing PlatformStand off + GettingUp
-- the moment you're ragdolled gets you up far faster than vanilla (a real, working defensive trick).
track(RunSvc.Heartbeat:Connect(function()
	if not PX.antiRagdoll then return end
	local c=myChar(); local h=c and c:FindFirstChildOfClass("Humanoid"); if not h then return end
	pcall(function()
		if h.PlatformStand then h.PlatformStand=false end
		local st=h:GetState()
		if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown or st==Enum.HumanoidStateType.Physics then
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		for _,a in ipairs({"Ragdoll","Ragdolled","Stunned","Knocked","Stun"}) do if c:GetAttribute(a) then c:SetAttribute(a,false) end end
	end)
end))

-- ── ANTI-VOID (researched: stop ring-outs — TP back to your last grounded spot if you fall off the map) ──
track(RunSvc.Heartbeat:Connect(function()
	local r=myHRP(); local h=myHum(); if not (r and h) then return end
	if h.FloorMaterial~=Enum.Material.Air then PX.lastSafe=r.CFrame end          -- remember the last spot you stood on solid ground
	if not PX.antiVoid then return end
	if r.Position.Y < -120 and PX.lastSafe then pxTP(PX.lastSafe + Vector3.new(0,3,0), 0.4) end   -- fell into the void -> yank back up
end))

-- ── no dash CD / endlag / fatigue (attribute zeroing — best-effort) ──
track(RunSvc.Heartbeat:Connect(function()
	if not PX.noCD then return end
	local c=myChar(); if not c then return end
	pcall(function() for _,a in ipairs({"DashCooldown","Cooldown","Endlag","Fatigue","DashCD"}) do local v=c:GetAttribute(a); if type(v)=="number" and v>0 then c:SetAttribute(a,0) end end
		local st=c:GetAttribute("Stamina"); if type(st)=="number" then c:SetAttribute("Stamina",100) end end)
end))

-- ── TRASH CAN THROW — grab EVERY trash can in Map.Trash and hurl them at a picked player (or All) ──
local function allTrashParts()
	local out={}
	local root=WS:FindFirstChild("Map"); root=(root and root:FindFirstChild("Trash")) or WS
	for _,o in ipairs(root:GetDescendants()) do
		if o:IsA("BasePart") and string.lower(o.Name):find("trash") then out[#out+1]=o end
	end
	return out
end
function pxTrashTargets()   -- dropdown options: All + every enemy
	local o={"All"}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then o[#o+1]=p.Name end end
	return o
end
-- REAL trash mechanic (TSB wiki): walk to a can + M1 = PICK IT UP; then M1 while aiming = THROW it (20% dmg).
-- Physics velocity does nothing (server-owned), so we drive the game's own grab/throw via M1 clicks.
local function faceAt(pos) local cam=WS.CurrentCamera; if cam then pcall(function() cam.CFrame=CFrame.lookAt(cam.CFrame.Position, pos) end) end end
local function clickGame(hold)
	local cam=WS.CurrentCamera; local vp=(cam and cam.ViewportSize) or Vector2.new(1280,720)
	local x,y=vp.X*0.5, vp.Y*0.5
	pcall(function() VIM:SendMouseButtonEvent(x,y,0,true,game,0) end); task.wait(hold or 0.06); pcall(function() VIM:SendMouseButtonEvent(x,y,0,false,game,0) end)
end
local function grabAndThrow(part, targetPlr)
	local me=myHRP(); if not (me and part and part.Parent) then return end
	pxTP(part.CFrame*CFrame.new(0,0,3.5), 0.4); RunSvc.Heartbeat:Wait()                -- walk up to the can
	faceAt(part.Position); task.wait(0.12)
	REPLAYING=true; clickGame(0.06); REPLAYING=false                                    -- M1 = pick it up
	task.wait(0.28)
	local pt=partOf(targetPlr)
	if pt then
		pxTP(pt.CFrame*CFrame.new(0,0,12), 0.4); RunSvc.Heartbeat:Wait()                -- run to the target
		faceAt(pt.Position); task.wait(0.12)
		REPLAYING=true; clickGame(0.06); REPLAYING=false                                -- M1 = throw it at them
	end
	task.wait(0.2)
end
function pxThrowAllTrash(targetName)
	local me=myHRP(); if not me then return end
	local cans=allTrashParts()
	if #cans==0 then notify("Trash","no trash cans in Map.Trash",3); return end
	local targets={}
	if targetName=="All" then for _,p in ipairs(Players:GetPlayers()) do if p~=LP then targets[#targets+1]=p end end
	else local p=Players:FindFirstChild(targetName); if p then targets[1]=p end end
	if #targets==0 then notify("Trash","no target players",2); return end
	task.spawn(function()
		local ti=1
		for _,part in ipairs(cans) do
			if part and part.Parent then
				local tp=targets[ti]; ti=ti%#targets+1
				if tp and tp.Character then grabAndThrow(part, tp) end
			end
		end
		notify("Trash","picked up + threw "..#cans.." cans",3)
	end)
end

-- ── aimlock ──
local function pxNearest(rng) local me=myHRP(); if not me then return nil end local bp,bd
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local pt=partOf(p) if pt then local d=(pt.Position-me.Position).Magnitude; if d<=(rng or 1e9) and (not bd or d<bd) then bp,bd=pt,d end end end end
	return bp end
track(RunSvc.RenderStepped:Connect(function()
	if not PX.aimlock then return end
	local cam=WS.CurrentCamera; local pt=pxNearest(PX.aimRange)
	if cam and pt then pcall(function() cam.CFrame=CFrame.lookAt(cam.CFrame.Position, pt.Position) end) end
end))

-- ── streak notifier ──
-- ── STREAK NOTIFIER (reads workspace.Cutscenes.Billboard.Killstreak) ──
local function pxStreakText()
	local cs=WS:FindFirstChild("Cutscenes"); local bb=cs and cs:FindFirstChild("Billboard"); local ks=bb and bb:FindFirstChild("Killstreak")
	if not ks then return nil end
	if ks:IsA("ValueBase") then return tostring(ks.Value) end
	for _,d in ipairs(ks:GetDescendants()) do if d:IsA("TextLabel") and tostring(d.Text)~="" then return d.Text end end
	return ks.Name
end
track(RunSvc.Heartbeat:Connect(function()
	if not PX.streak then return end
	local s=pxStreakText(); if not s then return end
	if PX.lastStreak~=nil and s~=PX.lastStreak then notify("Killstreak", s, 3) end
	PX.lastStreak=s
end))

-- ── ANTI-MOVES + COUNTERS matched by ANIMATION ID (accurate, from real TSB anim ids) ──
local ANIM = {
	tableflip = {"11365563255"},
	serious   = {"12983333733"},
	omni      = {"13927612951"},
	garouUlt  = {"12460977270","12463072679","14057231976","13630786846"},
	incin     = {"13146710762"},
	deathCtr  = {"11343318134"},                                   -- Death Counter (the counter move)
}
-- COUNTER stances (used by Anti-Counter dodge + Jump-On-Head)
local ANIM_COUNTER = { garou="12351854556", deathblow="15128849047", split="15311685628" }
-- ranged/beam moves (Incinerate, Garou ults) can't be out-dashed -> tp=true = big sideways TELEPORT dodge.
local PX_ANTI = {   -- toggle flag -> which id-set it dodges (tp = ranged, teleport away instead of back-dash)
	{f="antiTableFlip", ids=ANIM.tableflip},
	{f="antiSerious",   ids=ANIM.serious},
	{f="antiOmni",      ids=ANIM.omni},
	{f="antiGarou",     ids=ANIM.garouUlt, tp=true},
	{f="antiIncin",     ids=ANIM.incin,    tp=true},
	{f="antiDeath",     ids={ANIM_COUNTER.deathblow}},              -- Anti Death Blow
	{f="antiDC",        ids=ANIM.deathCtr},                         -- Anti Death Counter
}
local function trackMatches(track, ids)
	local aid = track and track.Animation and track.Animation.AnimationId; if not aid then return false end
	aid = tostring(aid)
	for _,id in ipairs(ids) do if aid:find(id, 1, true) then return true end end
	return false
end
local pxLastDodge, pxLastHead = 0, 0
local function pxBackDash()
	pcall(function()
		VIM:SendKeyEvent(true,KC.S,false,game)
		local dk=bindKC("Dash"); if dk and dk~="M1" and dk~="M2" then VIM:SendKeyEvent(true,dk,false,game); task.wait(0.06); VIM:SendKeyEvent(false,dk,false,game) end
		VIM:SendKeyEvent(false,KC.S,false,game)
	end)
end
-- teleport dodge: jump ~55 studs PERPENDICULAR to the beam (out of a straight-line ranged attack)
local function pxDodgeTP(enemyPos)
	local me=myHRP(); if not me then return end
	local dir=me.Position-enemyPos; dir=Vector3.new(dir.X,0,dir.Z); if dir.Magnitude<0.1 then dir=me.CFrame.LookVector end
	local perp=Vector3.new(-dir.Z,0,dir.X).Unit
	pxTP(CFrame.new(me.Position + perp*55 + Vector3.new(0,3,0)), 0.5)
end
-- send a chat message (works on both the new TextChatService and the legacy chat system)
local function pxChat(msg)
	pcall(function()
		local TCS=game:GetService("TextChatService")
		if TCS.ChatVersion==Enum.ChatVersion.TextChatService then
			local ch=TCS:FindFirstChild("TextChannels") and (TCS.TextChannels:FindFirstChild("RBXGeneral") or TCS.TextChannels:FindFirstChildWhichIsA("TextChannel"))
			if ch then ch:SendAsync(msg); return end
		end
		local ev=game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
		local say=ev and ev:FindFirstChild("SayMessageRequest")
		if say then say:FireServer(msg,"All") end
	end)
end
-- SMOOTH jump-on-head: glide to the enemy over ~0.35s (anti-send-back held), land on their head, jump, chat.
local function pxJumpOnHead(plr, pt)
	local me=myHRP(); if not (me and pt) then return end
	local head=plr.Character:FindFirstChild("Head") or pt
	task.spawn(function()
		local t0=os.clock(); local from=me.CFrame
		while os.clock()-t0 < 0.35 do
			local r=myHRP(); local h2=plr.Character:FindFirstChild("Head"); if not (r and h2) then break end
			local a=(os.clock()-t0)/0.35
			local goal=CFrame.new(h2.Position + Vector3.new(0, 3.6, 0))
			pcall(function() r.CFrame=from:Lerp(goal, a); r.AssemblyLinearVelocity=Vector3.zero end)
			RunSvc.Heartbeat:Wait()
		end
		local r=myHRP(); local h2=plr.Character:FindFirstChild("Head") or pt
		if r and h2 then pcall(function() r.CFrame=CFrame.new(h2.Position + Vector3.new(0,3.6,0)) end) end
		local hum=myHum(); if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end   -- hop on their head
		pxChat("EZ BOY")
	end)
end
track(RunSvc.Heartbeat:Connect(function()
	local anyDodge=false; for _,e in ipairs(PX_ANTI) do if PX[e.f] then anyDodge=true break end end
	local wantCounter = PX.jumpOnCounter or PX.ultAlert
	if not (anyDodge or wantCounter) then return end
	local me=myHRP(); if not me then return end
	for _,plr in ipairs(Players:GetPlayers()) do if plr~=LP and plr.Character then
		-- LOCK-ON ONLY: when set, only react to the player you're locked onto
		local lockOK = (not PX.counterLockOnly) or (lockTarget and plr==lockTarget)
		local pt=plr.Character:FindFirstChild("HumanoidRootPart"); local h=plr.Character:FindFirstChildOfClass("Humanoid")
		if pt and h and (pt.Position-me.Position).Magnitude<160 then                          -- 160: ranged moves (incinerate/beams) hit from far
			local a=h:FindFirstChildOfClass("Animator")
			if a then local ok,tr=pcall(function() return a:GetPlayingAnimationTracks() end)
				if ok and tr then
					-- 1) counter stance? -> alert / smooth jump-on-head + "EZ BOY"
					if wantCounter and lockOK then
						for _,t in ipairs(tr) do
							if trackMatches(t,{ANIM_COUNTER.garou}) or trackMatches(t,{ANIM_COUNTER.deathblow}) or trackMatches(t,{ANIM_COUNTER.split}) then
								if PX.ultAlert then notify("COUNTER", plr.Name.." is countering!", 2) end
								if PX.jumpOnCounter and os.clock()-pxLastHead>1.0 then
									pxLastHead=os.clock(); pxJumpOnHead(plr, pt)
								end
								break
							end
						end
					end
					-- 2) flagged offensive move? -> ranged = TELEPORT dodge, melee = back-dash (respects lock-on-only)
					if anyDodge and lockOK and os.clock()-pxLastDodge>0.8 then
						for _,t in ipairs(tr) do
							for _,e in ipairs(PX_ANTI) do if PX[e.f] and trackMatches(t, e.ids) then
								pxLastDodge=os.clock()
								if e.tp then pxDodgeTP(pt.Position) else pxBackDash() end
								return
							end end
						end
					end
				end
			end
		end
	end end
end))

-- ── anime teleportation (TP behind nearest enemy) ──
function pxAnimeTP() local pt=pxNearest(300); if not pt then notify("Anime TP","no enemy",2); return end pxTP(pt.CFrame*CFrame.new(0,0,4),0.6); notify("Anime TP","behind enemy",1.5) end

-- ── GOJO animation (Repulse / Erase / Attract — real ids) ──
local GOJO = { Repulse="13073745835", Erase="13071982935", Attract="15121659862" }
function pxGojo()
	local h=myHum(); if not h then return end
	local id=GOJO[PX.gojoSel or "Repulse"]; if not id then return end
	pcall(function() local a=Instance.new("Animation"); a.AnimationId="rbxassetid://"..id; h:LoadAnimation(a):Play() end)
end

-- ── custom display name ──
function pxSetName(on) PX.disgOn=on
	if PX.nameTag then pcall(function() PX.nameTag:Destroy() end); PX.nameTag=nil end
	if not on or PX.disgName=="" then return end
	local c=myChar(); local head=c and (c:FindFirstChild("Head") or myHRP()); if not head then return end
	local bb=Instance.new("BillboardGui"); bb.Name="VX_Name"; bb.Size=UDim2.fromOffset(220,40); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
	local tl=Instance.new("TextLabel"); tl.Size=UDim2.fromScale(1,1); tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamBold; tl.TextSize=18; tl.TextColor3=Color3.fromRGB(255,255,255); tl.TextStrokeTransparency=0.3; tl.Text=PX.disgName; tl.Parent=bb
	bb.Adornee=head; bb.Parent=head; PX.nameTag=bb end

-- ── custom idle/walk anims ──
function pxSetAnim(slot, id) local c=myChar(); if not c then return end local an=c:FindFirstChild("Animate"); if not an then return end
	id=tostring(id); if id:match("^%d+$") then id="rbxassetid://"..id end
	local node=an:FindFirstChild(slot); if node then for _,v in ipairs(node:GetChildren()) do if v:IsA("Animation") then pcall(function() v.AnimationId=id end) end end end
	local h=myHum(); if h then local a=h:FindFirstChildOfClass("Animator"); if a then for _,t in ipairs(a:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end end end end

-- ── HOTBAR rename (targets PlayerGui.Hotbar — the real path from the explorer screenshot) ──
-- Each move sits in its own slot frame that holds a NUMBER label (1-4) and a NAME label. We find the
-- slot by its number and rename the OTHER (name) label. Ultimate = the standalone non-numbered label.
local function pxHotbarRoot()
	local pg=LP:FindFirstChildOfClass("PlayerGui"); if not pg then return nil end
	local hb=pg:FindFirstChild("Hotbar"); if hb then return hb:FindFirstChild("Hotbar") or hb end   -- ScreenGui "Hotbar" > Frame "Hotbar"
	return pg
end
local function pxTextNodes(root) local out={}; for _,d in ipairs(root:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") then out[#out+1]=d end end return out end
function pxRenameSlot(slot, new)        -- slot = "1".."4"; renames that move's NAME label
	local root=pxHotbarRoot(); if not root then return false end
	for _,n in ipairs(pxTextNodes(root)) do
		if tostring(n.Text):match("^%s*"..slot.."%s*$") then                  -- found the number label for this slot
			local container=n.Parent
			for _,sib in ipairs(container:GetDescendants()) do                -- rename the sibling text that ISN'T the number
				if (sib:IsA("TextLabel") or sib:IsA("TextButton")) and sib~=n and not tostring(sib.Text):match("^%s*%d%s*$") and tostring(sib.Text)~="" then
					pcall(function() sib.Text=new end); return true
				end
			end
		end
	end
	return false
end
function pxRenameByText(old, new)       -- fallback: rename any label whose text matches `old`
	local root=pxHotbarRoot(); if not root then return false end local done=false
	for _,n in ipairs(pxTextNodes(root)) do if tostring(n.Text):lower()==tostring(old):lower() then pcall(function() n.Text=new end); done=true end end
	return done end
function pxRenameUlt(new)                -- ultimate = the biggest standalone label that isn't a digit/short
	local root=pxHotbarRoot(); if not root then return false end
	local best
	for _,n in ipairs(pxTextNodes(root)) do
		local t=tostring(n.Text)
		if #t>=4 and not t:match("^%s*%d%s*$") then
			if not best or n.AbsoluteSize.X>best.AbsoluteSize.X then best=n end
		end
	end
	if best then pcall(function() best.Text=new end); return true end
	return false end

-- ── DEX / FPS / scan remotes ──
function pxDex() local ok=pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
	if not ok then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDex.lua"))() end) end end
function pxSetFPS(v) PX.fps=v
	if v then pcall(function() PX.fpsSaved=settings().Rendering.QualityLevel; settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
		for _,o in ipairs(WS:GetDescendants()) do pcall(function()
			if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("Beam") then o.Enabled=false
			elseif o:IsA("Texture") or o:IsA("Decal") then o.Transparency=1
			elseif o:IsA("BasePart") then o.Material=Enum.Material.Plastic; o.Reflectance=0 end end) end
		pcall(function() Light.GlobalShadows=false; Light.FogEnd=9e9 end)
	else pcall(function() if PX.fpsSaved then settings().Rendering.QualityLevel=PX.fpsSaved end; Light.GlobalShadows=true end) end end
function pxScanRemotes() print("[VaultixPlus] ── REMOTE SCAN (copy ALL to me) ──"); local n=0
	pcall(function() for _,o in ipairs(game:GetDescendants()) do if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") or o:IsA("UnreliableRemoteEvent") then n=n+1; print(("  %s | %s | %s"):format(o.ClassName,o.Name,o:GetFullName())) end end end)
	print("[VaultixPlus] total: "..n.." ── END ──"); notify("Scan Remotes","Printed "..n.." remotes to F9. Send me the list.",6) end

-- ── teleports (best-guess defaults; Save overrides) ──
local PX_TPDEF={
	["Sky"]=function() local r=myHRP(); if r then pxTP(CFrame.new(r.Position.X,r.Position.Y+300,r.Position.Z),0.8) end end,
	["Middle of the Map"]=function() pxTP(CFrame.new(0,30,0),0.6) end,
	["Lonely Map Corner"]=function() pxTP(CFrame.new(900,30,900),0.6) end,
	["Mountain Spot 1"]=function() pxTP(CFrame.new(500,120,0),0.6) end,
	["Mountain Spot 2"]=function() pxTP(CFrame.new(-500,120,0),0.6) end,
	["Mountain Spot 3"]=function() pxTP(CFrame.new(0,120,500),0.6) end,
	["Saitama DC Room"]=function() pxTP(CFrame.new(0,500,1000),0.6) end,
	["Atomic Slash Room"]=function() pxTP(CFrame.new(0,500,-1000),0.6) end,
}
function pxTPNamed(nm) if PX.spots[nm] then pxTP(PX.spots[nm],0.6); notify("Teleport",nm.." (saved)",2); return end
	local f=PX_TPDEF[nm]; if f then f(); notify("Teleport",nm.." (default — Save your own to override)",3) end end
function pxSaveSpot(nm) local r=myHRP(); if r then PX.spots[nm]=r.CFrame; notify("Saved spot",nm,2) end end

-- MAP-INDEPENDENT teleports (the reliable ones — TSB maps ROTATE so fixed coords drift; these always work)
function pxPlayerNames() local o={}; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then o[#o+1]=p.Name end end if #o==0 then o[1]="(no players)" end return o end
function pxTPToPlayer(name) local me=myHRP(); local p=Players:FindFirstChild(name); local pt=p and partOf(p)
	if me and pt then pxTP(pt.CFrame*CFrame.new(0,0,4),0.6); notify("Teleport","to "..name,2) else notify("Teleport","player not found / dead",2) end end
function pxTPNearest() local me=myHRP(); if not me then return end local bp,bd
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local pt=partOf(p) if pt then local d=(pt.Position-me.Position).Magnitude; if not bd or d<bd then bp,bd=pt,d end end end end
	if bp then pxTP(bp.CFrame*CFrame.new(0,0,4),0.6); notify("Teleport","to nearest player",2) else notify("Teleport","no players",2) end end
function pxTPSky() local r=myHRP(); if r then pxTP(CFrame.new(r.Position.X,r.Position.Y+300,r.Position.Z),0.9) end end
function pxTPSpawn() local sp=WS:FindFirstChildWhichIsA("SpawnLocation",true); if sp then pxTP(sp.CFrame*CFrame.new(0,4,0),0.6); notify("Teleport","spawn",2) else notify("Teleport","no SpawnLocation found",2) end end

-- ── AUTO UPPERCUT / DOWNSLAM — routed through the BASE engine's doAction (same reliable input path the
--    tech builder uses: REPLAYING flag redirects the M1 click into the game, faces the target, tap-jump). ──
local pxAutoTok
function pxSetAutoMoves()
	if pxAutoTok then pxAutoTok.c=true; pxAutoTok=nil end
	if not (PX.autoUpper or PX.autoDownslam) then return end
	local tok={c=false}; pxAutoTok=tok
	task.spawn(function()
		local rtok={cancel=false}
		while not tok.c and (PX.autoUpper or PX.autoDownslam) do
			local pt=pxNearest(18)
			if pt then
				pcall(faceTarget)                                        -- base camera-aim onto the target
				REPLAYING=true                                           -- send M1 into the GAME, not the UI
				-- throw M1s first (the launcher only connects during an M1 combo), then the finisher
				local m1s = PX.autoDownslam and 3 or 2
				for i=1,m1s do if tok.c then break end pcall(doAction, {act="m1", hold=45}, rtok); task.wait(0.14) end
				if not tok.c then
					if PX.autoUpper then pcall(doAction, {act="uppercut", jumpLead=20, m1Hold=45, jumpReleaseDelay=40}, rtok)
					elseif PX.autoDownslam then pcall(doAction, {act="downslam", airDelay=260, m1Hold=45}, rtok) end
				end
				REPLAYING=false
				task.wait(0.45)
			else task.wait(0.2) end
		end
		REPLAYING=false
	end)
end

-- ── CLIENT AURAS (ported straight from Ability Arena's VFX: core shape + particles + light +
--    spinning neon ring-discs + orbiting pillars + trail, with a rainbow hue cycle) ──
local VFX_TEX = { Sparkles="rbxasset://textures/particles/sparkles_main.dds", Fire="rbxasset://textures/particles/fire_main.dds", Smoke="rbxasset://textures/particles/smoke_main.dds", Square="" }
local AURA = {
	Fire      = {Shape="Ball",Color=Color3.fromRGB(255,90,0),Color2=Color3.fromRGB(255,210,0),Texture="Fire",Rate=140,Speed=11,Spread=45,Light=true,Brightness=7,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.5},
	Ice       = {Shape="Ball",Color=Color3.fromRGB(120,220,255),Color2=Color3.fromRGB(225,250,255),Texture="Sparkles",Rate=90,Speed=4,Spread=160,Light=true,Brightness=4,Rings=true,RingCount=2,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.5},
	Lightning = {Shape="Ball",Color=Color3.fromRGB(120,180,255),Color2=Color3.fromRGB(255,255,255),Texture="Sparkles",Rate=170,Speed=16,Spread=180,Light=true,Brightness=9,Rings=false,Beams=true,Trail=false,Rainbow=false,ShapeOn=false,Size=4,Transp=0.5},
	Galaxy    = {Shape="Ball",Color=Color3.fromRGB(150,60,255),Color2=Color3.fromRGB(60,160,255),Texture="Sparkles",Rate=110,Speed=3,Spread=200,Light=true,Brightness=5,Rings=true,RingCount=3,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.6},
	Shadow    = {Shape="Ball",Color=Color3.fromRGB(70,0,100),Color2=Color3.fromRGB(20,20,30),Texture="Smoke",Rate=90,Speed=3,Spread=180,Light=true,Brightness=3,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=6,Transp=0.5},
	Holy      = {Shape="Ball",Color=Color3.fromRGB(255,240,150),Color2=Color3.fromRGB(255,255,255),Texture="Sparkles",Rate=120,Speed=5,Spread=160,Light=true,Brightness=9,Rings=true,RingCount=2,Beams=true,Trail=false,Rainbow=false,ShapeOn=true,Size=5,Transp=0.6},
	Toxic     = {Shape="Ball",Color=Color3.fromRGB(120,255,40),Color2=Color3.fromRGB(40,160,0),Texture="Smoke",Rate=90,Speed=4,Spread=170,Light=true,Brightness=4,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.5},
	Rainbow   = {Shape="Ball",Texture="Sparkles",Rate=140,Speed=6,Spread=180,Light=true,Brightness=6,Rings=true,RingCount=3,Beams=false,Trail=true,Rainbow=true,ShapeOn=true,Size=5,Transp=0.4},
	Void      = {Shape="Ball",Color=Color3.fromRGB(25,0,35),Color2=Color3.fromRGB(150,0,210),Texture="Smoke",Rate=110,Speed=2,Spread=200,Light=true,Brightness=4,Rings=true,RingCount=2,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=7,Transp=0.4},
	Sakura    = {Shape="Ball",Color=Color3.fromRGB(255,150,200),Color2=Color3.fromRGB(255,215,235),Texture="Sparkles",Rate=80,Speed=3,Spread=200,Light=true,Brightness=3,Rings=false,Beams=false,Trail=true,Rainbow=false,ShapeOn=true,Size=5,Transp=0.6},
	Nuke      = {Shape="Ball",Color=Color3.fromRGB(255,150,0),Color2=Color3.fromRGB(255,40,0),Texture="Fire",Rate=110,Speed=14,Spread=200,Light=true,Brightness=10,Rings=true,RingCount=2,Beams=true,Trail=false,Rainbow=false,ShapeOn=true,Size=8,Transp=0.3},
}
local AURA_ORDER = {"Fire","Ice","Lightning","Galaxy","Shadow","Holy","Toxic","Rainbow","Void","Sakura","Nuke"}
local vfxObjs, vfxRings, vfxChar = {}, {}, nil
local function auraMount() local c=myChar(); if not c then return nil end
	return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart") or myHRP() end
local function clearAura() for _,o in ipairs(vfxObjs) do pcall(function() o:Destroy() end) end vfxObjs, vfxRings = {}, {} end
local function auraColorSeq(t, rainbow)
	if (not rainbow) and t.Color2 then return ColorSequence.new({ColorSequenceKeypoint.new(0,t.Color or Color3.new(1,1,1)), ColorSequenceKeypoint.new(1,t.Color2)}) end
	return ColorSequence.new(t.Color or Color3.new(1,1,1))
end
local function applyAura()
	clearAura()
	local mount=auraMount(); if not mount then return end
	vfxChar=myChar()
	local t=AURA[PX.auraName] or AURA.Fire
	local col=t.Color or Color3.fromRGB(255,255,255)
	local size=t.Size or 5
	local rb = PX.auraRainbow or t.Rainbow
	if t.ShapeOn~=false then                                                     -- core glowing shape
		local part=Instance.new("Part"); part.Shape=(t.Shape=="Cylinder" and Enum.PartType.Cylinder) or Enum.PartType.Ball
		part.Size=Vector3.new(size,size,size); part.Color=col; part.Material=Enum.Material.Neon; part.Transparency=t.Transp or 0.5
		part.CanCollide=false; part.CanQuery=false; part.Massless=true; part.Anchored=false; pcall(function() part.CFrame=mount.CFrame end); part.Parent=mount
		local w=Instance.new("WeldConstraint"); w.Part0=mount; w.Part1=part; w.Parent=part; vfxObjs[#vfxObjs+1]=part
	end
	local att=Instance.new("Attachment",mount); vfxObjs[#vfxObjs+1]=att                           -- particles
	local pe=Instance.new("ParticleEmitter",att)
	pe.Texture=VFX_TEX[t.Texture] or VFX_TEX.Sparkles; pe.Color=auraColorSeq(t, rb)
	pe.Rate=t.Rate or 120; pe.Lifetime=NumberRange.new(0.5, math.max(0.6, size/3))
	pe.Speed=NumberRange.new((t.Speed or 6)*0.4, t.Speed or 6); pe.SpreadAngle=Vector2.new(t.Spread or 180, t.Spread or 180)
	pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*0.5), NumberSequenceKeypoint.new(1,0)})
	pe.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15), NumberSequenceKeypoint.new(1,1)})
	pe.LightEmission=0.9; pe.LightInfluence=0; pe.Rotation=NumberRange.new(0,360); pe.RotSpeed=NumberRange.new(-120,120)
	vfxObjs[#vfxObjs+1]=pe
	if t.Light~=false then                                                        -- light
		local lp=Instance.new("PointLight",mount); lp.Color=col; lp.Brightness=t.Brightness or 5; lp.Range=math.max(8,size*2); vfxObjs[#vfxObjs+1]=lp
	end
	if t.Rings then                                                              -- spinning ring discs
		for i=1,math.max(1,t.RingCount or 2) do
			local ring=Instance.new("Part"); ring.Shape=Enum.PartType.Cylinder; ring.Size=Vector3.new(0.25,size*1.7,size*1.7)
			ring.Color=(t.Color2 and i%2==0) and t.Color2 or col; ring.Material=Enum.Material.Neon; ring.Transparency=0.35
			ring.CanCollide=false; ring.CanQuery=false; ring.Massless=true; ring.Anchored=true; ring.Parent=WS
			vfxObjs[#vfxObjs+1]=ring; vfxRings[#vfxRings+1]={part=ring, phase=(i/(t.RingCount or 2))*math.pi*2, tilt=i*35}
		end
	end
	if t.Beams then                                                             -- orbiting pillars
		for i=1,6 do
			local b=Instance.new("Part"); b.Shape=Enum.PartType.Cylinder; b.Size=Vector3.new(size*1.6,0.35,0.35)
			b.Color=(t.Color2 and i%2==0) and t.Color2 or col; b.Material=Enum.Material.Neon; b.Transparency=0.35
			b.CanCollide=false; b.CanQuery=false; b.Massless=true; b.Anchored=true; b.Parent=WS
			vfxObjs[#vfxObjs+1]=b; vfxRings[#vfxRings+1]={part=b, phase=(i/6)*math.pi*2, beam=true}
		end
	end
	if t.Trail then                                                             -- trail
		local a0=Instance.new("Attachment",mount); a0.Position=Vector3.new(0,-1.6,0)
		local a1=Instance.new("Attachment",mount); a1.Position=Vector3.new(0,1.6,0)
		local tr=Instance.new("Trail",mount); tr.Attachment0=a0; tr.Attachment1=a1; tr.Lifetime=0.6; tr.LightEmission=0.85
		tr.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}); tr.Color=auraColorSeq(t, rb)
		vfxObjs[#vfxObjs+1]=a0; vfxObjs[#vfxObjs+1]=a1; vfxObjs[#vfxObjs+1]=tr
	end
end
function pxSetAura(v) PX.aura=v; if v then applyAura() else clearAura() end end
track(RunSvc.RenderStepped:Connect(function()
	if not PX.aura then return end
	local t=AURA[PX.auraName]
	local rb = PX.auraRainbow or (t and t.Rainbow)
	if rb then
		local col=Color3.fromHSV((tick()*0.2)%1, 1, 1)
		for _,o in ipairs(vfxObjs) do
			if o:IsA("ParticleEmitter") or o:IsA("Trail") then o.Color=ColorSequence.new(col)
			elseif o:IsA("PointLight") then o.Color=col
			elseif o:IsA("BasePart") then o.Color=col end
		end
	end
	local mount=auraMount()
	if mount and #vfxRings>0 then
		local sz=(t and t.Size) or 5; local tt=tick()*2
		for _,r in ipairs(vfxRings) do if r.part and r.part.Parent then
			if r.beam then
				local ang=r.phase+tt; local off=Vector3.new(math.cos(ang)*sz,0,math.sin(ang)*sz)
				r.part.CFrame=mount.CFrame*CFrame.new(off)*CFrame.Angles(0,0,math.rad(90))
			else
				r.part.CFrame=mount.CFrame*CFrame.Angles(math.rad(r.tilt), r.phase+tt, 0)*CFrame.Angles(0,0,math.rad(90))
			end
		end end
	end
end))
track(LP.CharacterAdded:Connect(function() task.wait(0.7); if PX.aura then applyAura() end end))
task.spawn(function() while task.wait(0.5) do if PX.aura and (myChar()~=vfxChar or not (vfxObjs[1] and vfxObjs[1].Parent)) then pcall(applyAura) end end end)

function pxCleanup() pcall(clearAura); pcall(function() if PX.nameTag then PX.nameTag:Destroy() end end); pcall(function() local r=myHRP(); if r then r.Anchored=false end end); pcall(function() if PX.fps then pxSetFPS(false) end end) end
track(LP.CharacterAdded:Connect(function() task.wait(0.6); if PX.disgOn then pxSetName(true) end; if PX.fps then pxSetFPS(true) end end))

-- ════════ PLUS TABS ════════
do
	local tab = Window:CreateTab("Player", 4483362458)
	tab:CreateSection("Movement")
	tab:CreateToggle({ Name="Loop WalkSpeed", CurrentValue=false, Callback=function(v) PX.wsOn=v; if not v then local h=myHum(); if h then pcall(function() h.WalkSpeed=16 end) end end end })
	tab:CreateSlider({ Name="WalkSpeed", Range={16,250}, Increment=2, Suffix="", CurrentValue=16, Callback=function(v) PX.ws=v end })
	tab:CreateToggle({ Name="Fly", CurrentValue=false, Callback=function(v) pxSetFly(v) end })
	tab:CreateSlider({ Name="Fly Speed", Range={20,300}, Increment=10, Suffix="", CurrentValue=60, Callback=function(v) PX.flySpd=v end })
	tab:CreateToggle({ Name="Noclip", CurrentValue=false, Callback=function(v) pxSetNoclip(v) end })
	tab:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Callback=function(v) PX.infJump=v end })
	tab:CreateSlider({ Name="Jump Power", Range={50,300}, Increment=5, Suffix="", CurrentValue=50, Callback=function(v) PX.jumpPow=v end })
	tab:CreateSection("Combat")
	tab:CreateToggle({ Name="Auto Uppercut", CurrentValue=false, Callback=function(v) PX.autoUpper=v; if v then PX.autoDownslam=false end; pxSetAutoMoves() end })
	tab:CreateToggle({ Name="Auto Downslam", CurrentValue=false, Callback=function(v) PX.autoDownslam=v; if v then PX.autoUpper=false end; pxSetAutoMoves() end })
	tab:CreateSection("Survival")
	tab:CreateToggle({ Name="Anti-Ragdoll", CurrentValue=false, Callback=function(v) PX.antiRagdoll=v end })
	tab:CreateToggle({ Name="Anti-Void", CurrentValue=false, Callback=function(v) PX.antiVoid=v end })
	tab:CreateSection("Body")
	tab:CreateToggle({ Name="Invisibility", CurrentValue=false, Callback=function(v) pxSetInvis(v) end })
	tab:CreateToggle({ Name="No Animations", CurrentValue=false, Callback=function(v) PX.noAnim=v end })
	tab:CreateToggle({ Name="Upside Down", CurrentValue=false, Callback=function(v) pxSetUpside(v) end })
	tab:CreateToggle({ Name="No Cooldowns", CurrentValue=false, Callback=function(v) PX.noCD=v end })
	tab:CreateSection("Trash Can")
	local trashTgt="All"
	local ttdrop = tab:CreateDropdown({ Name="Target", Options=pxTrashTargets(), CurrentOption="All", Callback=function(o) trashTgt=(type(o)=="table") and o[1] or o end })
	tab:CreateButton({ Name="Refresh Targets", Callback=function() pcall(function() ttdrop:Refresh(pxTrashTargets(), false) end) end })
	tab:CreateButton({ Name="Throw ALL Trash", Callback=function() pxThrowAllTrash(trashTgt) end })
	tab:CreateSection("Aim")
	tab:CreateToggle({ Name="Aimlock", CurrentValue=false, Callback=function(v) PX.aimlock=v end })
	tab:CreateSlider({ Name="Aimlock Range", Range={50,400}, Increment=10, Suffix="", CurrentValue=250, Callback=function(v) PX.aimRange=v end })
	tab:CreateToggle({ Name="Streak Notifier", CurrentValue=false, Callback=function(v) PX.streak=v; if v then PX.lastStreak=pxStreakText() end end })
end

do
	local tab = Window:CreateTab("Auras", 4483362458)
	tab:CreateSection("Client Aura")
	tab:CreateToggle({ Name="Enable Aura", CurrentValue=false, Callback=function(v) pxSetAura(v) end })
	tab:CreateDropdown({ Name="Aura", Options=AURA_ORDER, CurrentOption="Fire", Callback=function(o) PX.auraName=(type(o)=="table") and o[1] or o; if PX.aura then applyAura() end end })
	tab:CreateToggle({ Name="Rainbow", CurrentValue=false, Callback=function(v) PX.auraRainbow=v end })
end

do
	local tab = Window:CreateTab("Keybinds", 4483362458)
	tab:CreateSection("Keybinds")
	tab:CreateKeybind({ Name="Anime Teleport", CurrentKeybind="V", HoldToInteract=false, Callback=function() pxAnimeTP() end })
	tab:CreateToggle({ Name="Ghost Mode", CurrentValue=false, Callback=function(v) pxSetGhost(v) end })
	tab:CreateToggle({ Name="HRP Freeze", CurrentValue=false, Callback=function(v) pxSetFreeze(v) end })
	tab:CreateKeybind({ Name="HRP Freeze Key", CurrentKeybind="H", HoldToInteract=false, Callback=function() pxSetFreeze(not PX.freeze) end })
	tab:CreateSection("Gojo")
	tab:CreateDropdown({ Name="Move", Options={"Repulse","Erase","Attract"}, CurrentOption="Repulse", Callback=function(o) PX.gojoSel=(type(o)=="table") and o[1] or o end })
	tab:CreateKeybind({ Name="Play", CurrentKeybind="G", HoldToInteract=false, Callback=function() pxGojo() end })
end

do
	local tab = Window:CreateTab("Teleports", 4483362458)
	tab:CreateSection("Teleport")
	tab:CreateButton({ Name="Nearest Player", Callback=function() pxTPNearest() end })
	local who="(no players)"
	local pdrop = tab:CreateDropdown({ Name="Player", Options=pxPlayerNames(), CurrentOption=pxPlayerNames()[1], Callback=function(o) who=(type(o)=="table") and o[1] or o end })
	tab:CreateButton({ Name="Refresh", Callback=function() pcall(function() pdrop:Refresh(pxPlayerNames(), false) end) end })
	tab:CreateButton({ Name="To Player", Callback=function() pxTPToPlayer(who) end })
	tab:CreateButton({ Name="Sky", Callback=function() pxTPSky() end })
	tab:CreateButton({ Name="Spawn", Callback=function() pxTPSpawn() end })
	tab:CreateSection("Saved Spots")
	local slot="Spot 1"
	tab:CreateDropdown({ Name="Slot", Options={"Spot 1","Spot 2","Spot 3","Spot 4","Spot 5","Spot 6"}, CurrentOption="Spot 1", Callback=function(o) slot=(type(o)=="table") and o[1] or o end })
	tab:CreateButton({ Name="Save", Callback=function() pxSaveSpot(slot) end })
	tab:CreateButton({ Name="Go", Callback=function() if PX.spots[slot] then pxTP(PX.spots[slot],0.6); notify("Teleport",slot,2) else notify("Teleport","empty",2) end end })
end

do
	local tab = Window:CreateTab("Exploits", 4483362458)
	tab:CreateSection("Combat")
	tab:CreateToggle({ Name="Auto Uppercut", CurrentValue=false, Callback=function(v) PX.autoUpper=v; if v then PX.autoDownslam=false end; pxSetAutoMoves() end })
	tab:CreateToggle({ Name="Auto Downslam", CurrentValue=false, Callback=function(v) PX.autoDownslam=v; if v then PX.autoUpper=false end; pxSetAutoMoves() end })
	tab:CreateSection("Defense")
	tab:CreateToggle({ Name="Anti-Ragdoll", CurrentValue=false, Callback=function(v) PX.antiRagdoll=v end })
	tab:CreateToggle({ Name="Anti-Void", CurrentValue=false, Callback=function(v) PX.antiVoid=v end })
	tab:CreateSection("Anti-Move")
	tab:CreateToggle({ Name="Anti Table Flip", CurrentValue=false, Callback=function(v) PX.antiTableFlip=v end })
	tab:CreateToggle({ Name="Anti Serious Punch", CurrentValue=false, Callback=function(v) PX.antiSerious=v end })
	tab:CreateToggle({ Name="Anti Omni Punch", CurrentValue=false, Callback=function(v) PX.antiOmni=v end })
	tab:CreateToggle({ Name="Anti Garou Ult", CurrentValue=false, Callback=function(v) PX.antiGarou=v end })
	tab:CreateToggle({ Name="Anti Incinerate", CurrentValue=false, Callback=function(v) PX.antiIncin=v end })
	tab:CreateToggle({ Name="Anti Death Blow", CurrentValue=false, Callback=function(v) PX.antiDeath=v end })
	tab:CreateToggle({ Name="Anti Death Counter", CurrentValue=false, Callback=function(v) PX.antiDC=v end })
	tab:CreateSection("Counter")
	tab:CreateToggle({ Name="Lock-On Target Only", CurrentValue=false, Callback=function(v) PX.counterLockOnly=v end })
	tab:CreateToggle({ Name="Ultimate Alert", CurrentValue=false, Callback=function(v) PX.ultAlert=v end })
	tab:CreateToggle({ Name="Jump On Counter (walk on head + 'EZ BOY')", CurrentValue=false, Callback=function(v) PX.jumpOnCounter=v end })
end

do
	local tab = Window:CreateTab("Utility", 4483362458)
	tab:CreateSection("Tools")
	tab:CreateButton({ Name="DEX Explorer", Callback=function() pxDex() end })
	tab:CreateToggle({ Name="FPS Booster", CurrentValue=false, Callback=function(v) pxSetFPS(v) end })
	tab:CreateButton({ Name="Scan Remotes", Callback=function() pxScanRemotes() end })
	tab:CreateSection("Disguise")
	tab:CreateInput({ Name="Display Name", PlaceholderText="name", RemoveTextAfterFocusLost=false, Callback=function(x) PX.disgName=x or ""; if PX.disgOn then pxSetName(true) end end })
	tab:CreateToggle({ Name="Show Name", CurrentValue=false, Callback=function(v) pxSetName(v) end })
	tab:CreateSection("Animations")
	tab:CreateInput({ Name="Idle Id", PlaceholderText="id", RemoveTextAfterFocusLost=false, Callback=function(x) PX.idleId=x or "" end })
	tab:CreateButton({ Name="Apply Idle", Callback=function() if PX.idleId~="" then pxSetAnim("idle",PX.idleId); notify("Animation","idle",2) end end })
	tab:CreateInput({ Name="Walk Id", PlaceholderText="id", RemoveTextAfterFocusLost=false, Callback=function(x) PX.walkId=x or "" end })
	tab:CreateButton({ Name="Apply Walk", Callback=function() if PX.walkId~="" then pxSetAnim("walk",PX.walkId); notify("Animation","walk",2) end end })
	tab:CreateSection("Hotbar")
	local mvSlot, mvName = "1", ""
	tab:CreateDropdown({ Name="Slot", Options={"1","2","3","4"}, CurrentOption="1", Callback=function(o) mvSlot=(type(o)=="table") and o[1] or o end })
	tab:CreateInput({ Name="New Name", PlaceholderText="name", RemoveTextAfterFocusLost=false, Callback=function(x) mvName=x or "" end })
	tab:CreateButton({ Name="Rename Move", Callback=function()
		if mvName=="" then return end
		notify("Hotbar", pxRenameSlot(mvSlot, mvName) and "done" or "not found", 3)
	end })
	local oh,nh="",""
	tab:CreateInput({ Name="Old Text", PlaceholderText="current", RemoveTextAfterFocusLost=false, Callback=function(x) oh=x or "" end })
	tab:CreateInput({ Name="New Text", PlaceholderText="new", RemoveTextAfterFocusLost=false, Callback=function(x) nh=x or "" end })
	tab:CreateButton({ Name="Rename By Text", Callback=function() if oh~="" and nh~="" then notify("Hotbar", pxRenameByText(oh,nh) and "done" or "not found",3) end end })
end


-- ───────── unload ─────────
local function unload()
	pcall(function() RunSvc:UnbindFromRenderStep("TSB_Lock") end)
	pcall(stopSeq)
	pcall(function() if releaseAll then releaseAll() end end)
	pcall(function() if releaseMovement then releaseMovement() end end)
	pcall(function() hbRestore() end)
	pcall(function() if lockGui then lockGui:Destroy() end end)
	pcall(function() if mobileSG then mobileSG:Destroy() end end)
	pcall(pxCleanup)
	for _,cn in ipairs(CONNS) do pcall(function() cn:Disconnect() end) end
	pcall(function() Rayfield:Destroy() end)
	local gg=(getgenv and getgenv()) or _G; gg.__TSB_UNLOAD=nil
end
do local gg=(getgenv and getgenv()) or _G; gg.__TSB_UNLOAD=unload end

notify("Vaultix Hub PLUS", "Loaded.", 4)
print("[Vaultix] loaded.")
