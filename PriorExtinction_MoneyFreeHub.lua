--[[  Dream Hub · Prior Extinction  ]]

print("[Dream Hub PE] script fetched OK - booting")   -- if you see THIS in F9 but no menu, send the red error line under it
local __gg = (typeof(getgenv)=="function") and getgenv() or _G
if __gg.__PRIOR_EXT_HUB then pcall(__gg.__PRIOR_EXT_HUB) end
__gg.__PRIOR_EXT_HUB = nil
-- EARLY visible proof-of-life (for console-less mobile executors): if you see this toast the script
-- IS running -> press RightShift for the menu. If you DON'T see it, the executor failed to FETCH the
-- script (blocked/cached HttpGet) -> use the retry loader.
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
	Fly=false, FlySpeed=80, SpeedHack=false, SpeedVal=70, RunSpeed=15, StamDrive=true, DeathFix=true, Noclip=false, Invis=false,
	InfJump=false, BypassTP=true,
	InfFood=false, InfWater=false, InfStam=false, InfOxygen=false,
	AntiDrown=true, AntiDrownRise=14, AntiFracture=true, AntiBleed=true, WalkWater=false, AutoClean=false, HeadDmgReduce=90,
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
	UIKey="RightShift", AccentIndex=1, Keybinds={}, UIScale=1, DebugPanel=false, LogRemotes=false,
	AntiAFK=true, UnlockFOV=false, FOV=70, InfZoom=false, SafeTP=true,
	AutoClick=false, AutoClickCPS=12, AntiFall=true, WaterClear=false,
	AntiBreakHead=true, AntiBreakNeck=true, AntiBreakLeg=true, AntiBreakTail=true, AntiBreakTorso=true, NoClouds=false, Float=false,
	GodMode=false, AutoFarmGem=false, GemRange=1000000,
	FarmReach=200, FarmTeleport=true, FarmSpeed=55, TpBiome="(scan)",
	InfStamRun=true, AutoEatFood=true, FoodEatRange=120, FoodEatSpeed=3,
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
		for k,v in pairs(data) do CFG[k]=v end
	end)
end
loadCfg()
-- MIGRATE + CLAMP the INF-Stam run speed on load: 16 was STILL above what the server tolerates ("16 speed makes
-- u snap back"), so the safe band is 12-15. Default is 15: Speed-Finder testing measured ~15.7 sustained (21.9
-- bursts) with ZERO snapbacks now that the drive reports through the game's own move remote — the band top is
-- simply the best speed. Any saved value outside 12-15 (old 16-90 configs included) is reset to 15.
do local rs = tonumber(CFG.RunSpeed) or 15; CFG.RunSpeed = (rs >= 10 and rs <= 15) and rs or 15 end
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
	if typeof(id)=="number" and not seenSet[id] then seenSet[id]=true; seenIds[#seenIds+1]=id end
	myReplicaId = id
end
-- Injury-report gate (defined ONCE at module level, not per-namecall — a closure alloc on every FireServer was
-- churning GC and dropping FPS). True when THIS SetProperty/SetAction is an injury your active protectors block.
local function injHit(lp)
	local anyPhys = CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso
	if (CFG.AntiFracture or CFG.BoneProtect) and (lp:find("fractur",1,true) or lp:find("concuss",1,true)) then return true end
	if CFG.AntiBleed and (lp:find("bleed",1,true) or lp:find("hemorrhage",1,true) or lp:find("wound",1,true)) then return true end
	if anyPhys and (lp:find("brok",1,true) or lp:find("break",1,true) or lp:find("sever",1,true) or lp:find("dislocat",1,true) or lp:find("limp",1,true) or lp:find("fractur",1,true) or lp:find("crush",1,true) or lp:find("blunt",1,true) or lp:find("trauma",1,true)) then return true end
	if CFG.AntiBreakHead and (lp:find("head",1,true) or lp:find("skull",1,true) or lp:find("crani",1,true) or lp:find("jaw",1,true) or lp:find("concuss",1,true)) then return true end
	if CFG.AntiBreakNeck and (lp:find("neck",1,true) or lp:find("spine",1,true) or lp:find("cervic",1,true)) then return true end
	if CFG.AntiBreakLeg  and (lp:find("leg",1,true) or lp:find("foot",1,true) or lp:find("limb",1,true) or lp:find("knee",1,true)) then return true end
	if CFG.AntiBreakTail and lp:find("tail",1,true) then return true end
	if CFG.AntiBreakTorso and (lp:find("torso",1,true) or lp:find("rib",1,true) or lp:find("chest",1,true) or lp:find("hip",1,true)) then return true end
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
				elseif self.Name=="ReplicaSignal" and not checkcaller() then
				local a = table.pack(...)
				local id, action = a[1], a[2]
				-- Capture OUR dino id ONLY from SELF actions (HeadAngles/Fall/Attack/etc.). Sip/Bite/Eat fire with a
				-- SOURCE id (e.g. water 3028) — recording those as myReplicaId would break Attack. Source ids → seenIds only.
				if typeof(id)=="number" then
					if action=="Sip" or action=="Bite" or action=="Eat" or action=="Consume" then
						if not seenSet[id] then seenSet[id]=true; seenIds[#seenIds+1]=id end if action=="Bite" and a.n>=3 then __gg.MH_eat={id=id,buf=a[3]}; __gg.MH_foodIds=__gg.MH_foodIds or {}; if id~=myReplicaId then __gg.MH_foodIds[id]=true; __gg.MH_eatBuf=a[3] end end   -- collect EVERY food id you bite (multi-id) so INF Food replays them all
						-- BITE-ONLY CAPTURE (for the INF Food spam loop): record the ENTIRE Bite call verbatim — the exact
						-- id + "Bite" + every argument the game sent when YOU bit food — so we can replay it byte-for-byte,
						-- fast, forever. We keep a LIST of the last several DIFFERENT bites, so the more different things you
						-- eat, the more Bite calls the spam loop fires per pass = faster growth. Bite is the one that fills the bar.
						if action=="Bite" then
							local snap={n=a.n} for i=1,a.n do snap[i]=a[i] end
							__gg.MH_lastEatCall=snap; __gg.MH_lastEatT=tick()
							__gg.MH_biteCalls = __gg.MH_biteCalls or {}
							local key=tostring(id).."|"..tostring(a[3])   -- dedupe by source id + buffer so we keep DIFFERENT foods
							local dup=false; for _,c in ipairs(__gg.MH_biteCalls) do if c.key==key then dup=true; break end end
							if not dup then snap.key=key; table.insert(__gg.MH_biteCalls, snap); if #__gg.MH_biteCalls>16 then table.remove(__gg.MH_biteCalls,1) end end
						end
					else
						noteReplicaId(id)  -- self action = our dino id
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
						if action=="Fall" and CFG.AntiFall and typeof(a[3])=="number" then
							a[3]=0.1; if a[5]~=nil then a[5]=a[4] end
							return oldNC(self, table.unpack(a, 1, a.n))
						end
						-- Anti-Drown: the client REPORTS being underwater via the DrownY action; swallow it so
						-- the server never applies drowning damage. No value to rewrite — just don't report it.
						if action=="DrownY" and CFG.AntiDrown then return end
						-- (REMOVED: this used to swallow the Secondary/right-click RegisterAttack while INF Stam was on,
						--  which meant your dino's SECOND ATTACK dealt NO DAMAGE. INF Stam already refills the bar, so
						--  there is no reason to block the attack — M2 now passes through and hits normally.)
						-- ═══ INF STAM — Run/Sprint PASS THROUGH; never let the bar hit 0 (from the wiki) ═══ PE has
						-- Walk/Trot/Run(Shift, slow drain)/Sprint(Tab, FAST drain), and you are ONLY forced to slow
						-- WHEN STAMINA REACHES 0. So the fix is NOT to swallow the action (that dropped you to walk
						-- speed = "makes me slow") — Run AND Sprint pass through so you get the game's real running
						-- speed, and we keep the bar pinned to max (below + the refill loop) so it never reaches 0
						-- and the game never forces you down. The WalkSpeed keeper restores speed if it ever cuts it.
						if CFG.InfStam and action=="SetAction" and (a[3]=="Run" or a[3]=="Sprint" or a[3]=="Trot") and a[4]==true then
							__gg.MH_wantRun = tick()
							pcall(function() local h=hum(); if h and h.WalkSpeed and h.WalkSpeed>0 then __gg.MH_runSpeed=math.max(__gg.MH_runSpeed or 0, h.WalkSpeed) end end)
							-- no swallow: the action replicates so you keep real run/sprint speed; the pins hold the bar
						end
						-- (stamina DRAIN report is blocked below so it never drops while you sprint.)
						-- REWRITE stamina SetProperty to max so the server always sees a full bar.
						-- Previously this swallowed the call entirely, which also blocked our own
						-- refill fires at line ~1615 → server never got told stam was full = no drain fix.
						if CFG.InfStam and action=="SetProperty" and typeof(a[3])=="string" then local lp=a[3]:lower()
								if lp:find("stam",1,true) or lp=="energy" or lp=="sp" or lp=="endurance" or lp:find("endur",1,true) or lp:find("vigor",1,true) or lp:find("fatigue",1,true) or lp:find("exertion",1,true) then
								if typeof(a[4])=="number" then
									-- track the highest seen value per property name (= the real max when bar is full)
									__gg.MH_max = __gg.MH_max or {}
									local pk = a[3]
										if not __gg.MH_max[pk] then __gg.MH_max[pk] = 100 end
									if a[4] > 0 and (not __gg.MH_max[pk] or a[4] > __gg.MH_max[pk]) then __gg.MH_max[pk] = a[4] end
									a[4] = __gg.MH_max[pk] or 100   -- rewrite the drop to the tracked max
										local snap={n=a.n} for i=1,a.n do snap[i]=a[i] end; snap[4]=__gg.MH_max[pk] or 100; __gg.MH_stamCall=snap   -- capture the exact full-stamina call to replay verbatim
								end
								return oldNC(self, table.unpack(a, 1, a.n))   -- fire with max value (not swallowed)
							end
						end
						-- Some stamina drains do NOT come through SetProperty — the client reports them with their own
						-- action name (StaminaDrain / Exhaust / FatigueTick). Swallow those outright while INF Stam is on.
						if CFG.InfStam and (action=="StaminaDrain" or action=="Exhaust" or action=="FatigueTick") then return end
						-- TIRED-FLAG REPORTS (the Shift/run "Tr…" family): if the client tries to TELL the server you're
						-- tired/exhausted (SetAction/SetProperty "Tired"/"Exhausted"/"Fatigued" = true), swallow it — the
						-- server never hears you got tired, so it never applies the slow. (Only TRUE reports are swallowed;
						-- "no longer tired" passes through so you can never get stuck flagged.)
						if CFG.InfStam and (action=="SetAction" or action=="SetProperty") and typeof(a[3])=="string" then
							local tl=a[3]:lower()
							if (tl:find("tired",1,true) or tl:find("exhaust",1,true) or tl:find("fatigu",1,true)) and (a[4]==true or (typeof(a[4])=="number" and a[4]>0)) then return end
						end
						-- ANTI-INJURY (report-block): injuries replicate the same way stamina does — the CLIENT reports
						-- them to the server. While your antis are on, we SWALLOW any report that would tell the server
						-- you fractured / bled / broke a bone — the injury never lands server-side. THIS is what makes
						-- Anti Fractured + Bone Protection actually stick (the local sweep alone only hid it client-side).
						-- Broadened region keywords so a HEAD/skull break (SkullFracture/HeadTrauma/Concussion/JawBreak) is
						-- caught by Anti Break Head too, not only Anti Fractured. Same for neck/leg/tail/torso protectors.
						if action=="SetProperty" and typeof(a[3])=="string" then local lp=a[3]:lower()
							if injHit(lp) then local v=a[4]; if v==true or (typeof(v)=="number" and v~=0) or typeof(v)=="table" then return end end
						end
						if action=="SetAction" and typeof(a[3])=="string" and a[4]==true then local lp=a[3]:lower()
							if injHit(lp) then return end
						end
						do local la=action:lower()
							if (CFG.AntiFracture or CFG.AntiBleed or CFG.BoneProtect) and (la:find("fractur",1,true) or la:find("bleed",1,true) or la:find("injur",1,true)) then return end
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
		return { marker=inner[1], bytes=bytes, tag=x[2], data={Species=data.Species, Variant=data.Variant, Skin=data.Skin, Gender=data.Gender, Stage=data.GrowthStage or data.Stage} }
	else
		if type(x)~="table" or not x.bytes then return nil end
		local bid=""; for _,b in ipairs(x.bytes) do bid=bid..string.char(b) end
		return { { x.marker or "\001", bid, { { Species=x.data.Species, Variant=x.data.Variant, Skin=x.data.Skin, Gender=x.data.Gender } } }, x.tag or "H" }
	end
end
-- Per-ACCOUNT file naming: every save file is tagged with the player's UserId, so different people using the same
-- executor/PC can NEVER mix slots — each account only sees its own saves.
local function slotFile(n) return "MH_PE_"..tostring(LP.UserId).."_Slot_"..tostring(n)..".json" end
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
	local b = getBridge(); if not b then notify("Progress Restore","Progress loading…"); return false end
	local pp = __gg.MH_restore
	if type(pp)~="table" then notify("Progress Restore","Progress loading…"); return false end
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
					pcall(function() local sp=WS:FindFirstChildWhichIsA("SpawnLocation", true); if sp then dest=sp.Position+Vector3.new(0,8,0) end end)
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
conn(LP.CharacterAdded:Connect(function() task.wait(1); if __gg.MH_spawnRescue then __gg.MH_spawnRescue() end end))
task.spawn(function() task.wait(2); if __gg.MH_spawnRescue then __gg.MH_spawnRescue() end end)   -- also guard THIS spawn (you may already be falling)
local CharacterState
pcall(function() local cm=RS:FindFirstChild("Common"); local cs=cm and cm:FindFirstChild("CharacterState"); if cs then CharacterState=require(cs) end end)
local function csReplica() return CharacterState and CharacterState.Replica end
local function csStats() local r=csReplica(); if r and r.Data then return r.Data.Stats, r.Data.MaxStats end end
-- REPLICA ID FALLBACK (no-hook executors): the namecall hook normally sets myReplicaId from self-actions like the
-- constantly-fired HeadAngles. If the executor lacks hookmetamethod, read our dino id from CharacterState.Replica
-- as a fallback. Only sets it when not already captured (the hook value is the authoritative ReplicaSignal id).
task.spawn(function() while RUNNING do task.wait(1)
	if not myReplicaId then pcall(function()
		local r=csReplica()
		local id = r and (r.Id or (rawget and rawget(r,"Id")) or (r.Data and (r.Data.Id or r.Data.ReplicaId)))
		if typeof(id)~="number" and CharacterState then id = CharacterState.Id or CharacterState.ReplicaId end
		if typeof(id)=="number" then noteReplicaId(id) end
	end) end
end end)
-- SELF action: fire ReplicaSignal as the player's own replica (id = myReplicaId, e.g. 57542).
local function replicaFire(...)
	local a=table.pack(...)
	local rs=getReplicaSignal(); if not rs then return false end
	local id = myReplicaId or seenIds[1]
	if id then return (pcall(function() rs:FireServer(id, table.unpack(a,1,a.n)) end)) end
	local f=false; for _,sid in ipairs(seenIds) do pcall(function() rs:FireServer(sid, table.unpack(a,1,a.n)) end); f=true end
	return f
end
-- BROADCAST: fire with EVERY captured replica id (for source-targeted actions like "Sip"/"Eat",
-- whose id is the water/food object, not the player — e.g. {3028,"Sip"}).
local function replicaActionAll(...)
	local a=table.pack(...)
	local rs=getReplicaSignal(); if not rs then return false end
	local f=false
	if myReplicaId then pcall(function() rs:FireServer(myReplicaId, table.unpack(a,1,a.n)) end); f=true end
	for _,id in ipairs(seenIds) do if id~=myReplicaId then pcall(function() rs:FireServer(id, table.unpack(a,1,a.n)) end); f=true end end
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
	replicaActionAll("Sip")                       -- + any captured source ids as a fallback
	replicaActionAll("SetAction","Drinking",true)
	replicaActionAll("SetAction","Drinking",false)
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
	-- ID-FREE: fire the eat Bite to MANY source ids so the right one always lands, no matter the land:
	--   (1) the LIVE-captured eat (real source id + real buffer the game last sent), (2) every per-land water/source
	--   id, (3) every replica id the hook has seen. The captured buffer is preferred; falls back to the known buffer.
	local cap = __gg.MH_eat
	local buf = (type(cap)=="table" and cap.buf~=nil) and cap.buf or __gg.MH_eatBuf or EAT_BUFFER
	if type(buf)=="string" and buffer and buffer.fromstring then pcall(function() buf = buffer.fromstring(buf) end) end
	-- VERBATIM REPLAY (strongest): if we captured your exact eat call, replay it byte-for-byte a few times. This is
	-- the "capture the remote when you eat, then spam it" path — it always lands because it IS the game's own call.
	local ec = __gg.MH_lastEatCall
	if type(ec)=="table" and ec.n and ec.n>=2 then
		for _=1,3 do pcall(function() rs:FireServer(table.unpack(ec,1,ec.n)) end) end
	end
	if type(cap)=="table" and cap.id then pcall(function() rs:FireServer(cap.id, "Bite", cap.buf or buf) end) end
	-- MULTI-ID REPLAY (eat once -> it does the rest): re-fire Bite to EVERY food id you've bitten this session,
	-- FoodEatSpeed times each, so a single plant keeps the bar topped up across the whole map. Capped so it never bursts.
	local foodIds = __gg.MH_foodIds
	if type(foodIds)=="table" and next(foodIds) then
		local fired=0; local speed=math.clamp(tonumber(CFG.FoodEatSpeed) or 3, 1, 10)
		for foodId in pairs(foodIds) do
			for _=1,speed do pcall(function() rs:FireServer(foodId, "Bite", buf) end); fired+=1; task.wait(0.03); if fired>=12 then break end end
			if fired>=12 then break end
		end
	end
	for _,id in pairs(WATER_IDS) do pcall(function() rs:FireServer(id, "Bite", buf) end) end  -- every land's source id
	replicaActionAll("Bite", buf)                          -- + every captured source id (use-many-ids)
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
		for _,d in ipairs(root:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Bone")) then
				local dn=d.Name:lower()
				if dn==want then return d end
				if not best and dn:sub(1,#want)==want then best=d end
			end
		end
		return nil
	end
	local hb=model:FindFirstChild("Hitbox") or model:FindFirstChild("HitBox")
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
local function fireAttack(targetModel, skipSound, clickedPart)
	if not targetModel then return false end
	-- Degrade gracefully like replicaFire does: if the hook didn't capture our id, use any seen id (no-hook executors).
	local myId = myReplicaId or seenIds[1]
	if not myId then return false end
	local rs=getReplicaSignal(); if not rs then return false end
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
	local list = (want and want~="" and want~="Auto" and ATK_GROUPS[want]) or ATK_GROUPS.Auto
	if not targetPos then for _,b in ipairs(list) do
		local bn=_findIn(targetModel, b.n); local p=_bonePos(bn)
		-- report the FOUND part's REAL name: fuzzy find of "Spine" can return "Spine.002", and the server checks
		-- that the NAME matches the POSITION on the target's rig — a canonical name with the real part's position
		-- is a mismatch it rejects. Real name + real position = the hit registers every time.
		if p then group, boneName, targetPos = b.g, bn.Name, p; break end
	end end
	-- KEYWORD FALLBACK — makes "Always hit part = Leg/Head/…" work on EVERY dino: if the exact bone names above didn't
	-- resolve on THIS dino's rig, search its parts/bones for ANY name in the selected region, reporting that real name
	-- so the server accepts it (bone naming varies per dino — this is why "aim a body part" missed on some of them).
	if not targetPos and want and want~="" and want~="Auto" then
		local KW=({Head={"head","skull","jaw","crani","maxill","mandib","frontal"},Neck={"neck"},Spine={"spine","body","torso","chest"},Body={"spine","body","torso","chest","hip","ilium"},Leg={"leg","femur","tibia","thigh","foot","shin","toe"},Tail={"tail"},Hip={"hip","ilium","pelvis"},Arm={"arm","hand","claw","humer","wing","finger"}})[want]
		if KW then local scanned=0
			for _,d in ipairs(targetModel:GetDescendants()) do scanned+=1; if scanned>600 then break end
				if d:IsA("BasePart") or d:IsA("Bone") then local dn=d.Name:lower()
					for _,kw in ipairs(KW) do if dn:find(kw,1,true) then local p=_bonePos(d); if p then group=(ATK_GROUPS[want] and ATK_GROUPS[want][1] and ATK_GROUPS[want][1].g) or "Body"; boneName=d.Name; targetPos=p; break end end end
				end
				if targetPos then break end
			end
		end
	end
	if not targetPos and list~=ATK_GROUPS.Auto then
		for _,b in ipairs(ATK_GROUPS.Auto) do local bn=_findIn(targetModel,b.n); local p=_bonePos(bn); if p then group,boneName,targetPos=b.g,bn.Name,p; break end end
	end
	if not targetPos then
		local hb=targetModel:FindFirstChild("Hitbox") or targetModel:FindFirstChild("HitBox")
		if hb then
			local part = (hb:IsA("BasePart") and hb) or hb:FindFirstChildWhichIsA("BasePart", true)   -- descend the container (Hitbox.Head.Head)
			if part then group, boneName, targetPos = boneGroupFor(part.Name), part.Name, part.Position end
		end
	end
	if not targetPos then return false end
	-- ALWAYS HIT the chosen part: report the GROUP as the selected region so "Always Damage = Neck" registers as a Neck
	-- hit — but KEEP the REAL bone name we resolved above (forcing a canonical name like "Skull" on a dino whose bone is
	-- "Head" made the server REJECT the hit = no damage). Skip when you clicked a specific bone (the click wins).
	if not clickedAim and want and want~="" and want~="Auto" then
		group = want
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
	-- FIRE THE PRIMARY ATTACK FIRST (SoundRemote) — this initiates the swing the server validates, THEN report the
	-- hit via ReplicaSignal "Attack". Positions MUST be native vectors (vector.create) to match the capture exactly.
	-- arg[5] = OUR bite bone (capture shows Group="Head", Name="Head"); arg[6] = the TARGET group.
	if not skipSound then local sr=getSoundRemote(); if sr then pcall(function() sr:FireServer("PVP","Attacks/Primary",false,nil,1) end) end end
	local args = { [1]=myId, [2]="Attack",
		[4]={Group=group, Name=boneName, Position=vec(targetPos)},
		[5]={Group="Head", Name="Head", Position=vec(jawPos)},
		[6]=group }
	return pcall(function() rs:FireServer(table.unpack(args, 1, 6)) end)
end
_G.MH_attack = fireAttack   -- exposed so the Auto Play Bot's PvP combat can land real bone-targeted bites

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
	for _,n in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do
		local hb=model:FindFirstChild(n)
		if hb then
			if hb:IsA("BasePart") then return hb end
			-- container: prefer a Head part, else the first BasePart anywhere inside
			local head=hb:FindFirstChild("Head", true); if head and head:IsA("BasePart") then return head end
			local any=hb:FindFirstChildWhichIsA("BasePart", true); if any then return any end
		end
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
			__gg.MH_hbMade = __gg.MH_hbMade or setmetatable({}, {__mode="k"})
			if not __gg.MH_hbMade[model] then
				__gg.MH_hbMade[model] = true
				__gg.MH_mkHB(model)
				local hb=model:FindFirstChild("Hitbox")
				if hb then
					local any=(hb:IsA("BasePart") and hb) or hb:FindFirstChildWhichIsA("BasePart", true)
					if any then return end   -- found next call via the loop above; fall through this pass
				end
			end
		end
	end)
	do local hb=model:FindFirstChild("Hitbox")
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
	local out={}
	local function add(f) if f then for _,m in ipairs(f:GetChildren()) do if m:IsA("Model") then out[#out+1]=m end end end end
	add(WS:FindFirstChild("Characters"))
	local ci=WS:FindFirstChild("CharacterIgnore")
	if ci then add(ci:FindFirstChild("LeftCharacters")); add(ci) end
	for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters"}) do add(WS:FindFirstChild(nm)) end
	return out
end
_G.MH_charModels = charModels
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
		-- search the Hitbox CONTAINER first (real BaseParts: Head, Neck.001, Spine…), then any descendant bone.
		local hb=model:FindFirstChild("Hitbox")
		for _,bn in ipairs(AIM_BONES[want] or {want}) do
			if hb then local p=hb:FindFirstChild(bn); if p and (p:IsA("BasePart") or p:IsA("Bone")) then return p end end
			local found = model:FindFirstChild(bn, true)
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
-- Targets scan ONLY workspace.Characters (every entity, incl. players, lives there) + getHitbox — NOT
-- WS:GetDescendants() (that full-workspace walk every call was the Silent Aim / aim lag).
local function nearestTarget(range, anyCreature)
	local me = hrp(); if not me then return nil end
	local mine = getMyModel()
	local best, bestRoot, bd = nil, nil, range or 1e9
	local chars = WS:FindFirstChild("Characters")
	if chars then
		for _,m in ipairs(chars:GetChildren()) do
			if m:IsA("Model") and m~=mine then
				local h = m:FindFirstChildOfClass("Humanoid")
				if (not h) or h.Health>0 then
					local r = getHitbox(m) or rootOf(m)
					if r then local d = dist(me.Position, r.Position); if d<bd then best,bestRoot,bd = m, r, d end end
				end
			end
		end
	end
	-- fallback to Players if Characters didn't yield (some maps parent elsewhere)
	if not best then
		for _,pl in ipairs(Players:GetPlayers()) do
			if pl~=LP and pl.Character then
				local r = getHitbox(pl.Character) or rootOf(pl.Character)
				local h = pl.Character:FindFirstChildOfClass("Humanoid")
				if r and ((not h) or h.Health>0) then local d = dist(me.Position, r.Position); if d<bd then best,bestRoot,bd = pl.Character, r, d end end
			end
		end
	end
	-- SANDBOX fallback: in Sandbox/test places dinos aren't under workspace.Characters — they sit in other folders
	-- or are nil-parented. Scan extra containers, then getnilinstances() for Models with a Hitbox. (Only runs when
	-- nothing was found above, so normal play never pays for the nil-instance walk.)
	if not best then
		local function consider(m)
			if not (m and m:IsA("Model") and m~=mine) then return end
			local h = m:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return end
			local r = getHitbox(m) or rootOf(m)
			if r then local d=dist(me.Position, r.Position); if d<bd then best,bestRoot,bd = m, r, d end end
		end
		for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters","CharacterIgnore"}) do
			local f=WS:FindFirstChild(nm); if f then for _,m in ipairs(f:GetChildren()) do consider(m) end end
		end
		if not best and typeof(getnilinstances)=="function" then
			pcall(function() local c=0; for _,v in next, getnilinstances() do c+=1; if c>4000 then break end
				if typeof(v)=="Instance" and v:IsA("Model") and (v:FindFirstChild("Hitbox") or v:FindFirstChild("HitBox") or v:FindFirstChild("MeshModel")) then consider(v) end
			end end)
		end
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
		CFG[key]=not CFG[key]
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
	{cfg="InfFood",   keys={"food","hunger","nutrition","fullness","satiation"}},   -- SEVEN STRONG: pin food to full
	{cfg="InfWater",  keys={"water","thirst","hydrat","drink","liquid"}},
	{cfg="InfStam",   keys={"stamina","stam","energy","endur"}},
	{cfg="InfOxygen", keys={"oxygen","air","breath","o2","lung"}},
}
-- Drain meters that go UP as you suffer — when their feature is on, force them to ZERO, never max.
STAT_ZERO = {
	{cfg="InfStam",   keys={"exhaust","fatigue","tired"}},
	{cfg="InfFood",   keys={"starv","hungry"}},
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
-- HUD stat pin: force MainHUD.StatsFrame bars + their values full (the path you gave).
local function pinHud()
	local pg = LP:FindFirstChild("PlayerGui"); if not pg then return end
	local hud = pg:FindFirstChild("MainHUD"); if not hud then return end
	local sf = hud:FindFirstChild("StatsFrame"); if not sf then return end
	local function pinOne(on, names)
		if not on then return end
		for _,nm in ipairs(names) do
			local el = sf:FindFirstChild(nm)
			if el then
				pcall(function() for k,v in pairs(el:GetAttributes()) do if type(v)=="number" then local lk=k:lower(); if lk:find("percent") or lk:find("fill") or lk:find("alpha") or lk:find("ratio") then el:SetAttribute(k,1) elseif lk:find("val") or lk:find("amount") or lk:find("current") or lk:find("cur") then el:SetAttribute(k,100) end end end end)
				for _,dd in ipairs(el:GetDescendants()) do
					if dd:IsA("NumberValue") or dd:IsA("IntValue") then pcall(function() dd.Value=100 end)
					elseif dd:IsA("GuiObject") then local ln=dd.Name:lower(); if ln:find("fill") or ln:find("bar") or ln:find("amount") or ln:find("progress") then pcall(function() dd.Size=UDim2.new(1,0,dd.Size.Y.Scale,dd.Size.Y.Offset) end) end end
				end
			end
		end
	end
	-- (food HUD not force-filled — it reflects the real bar so the eat prompt logic stays consistent)
	pinOne(CFG.InfWater,  {"Water","Thirst"})
	pinOne(CFG.InfStam,   {"Stamina","Stam","Energy"})
	pinOne(CFG.InfOxygen, {"Oxygen","Air","Breath"})
end
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
	local ICONS = {Combat="swords", PvP="target", Movement="footprints", Survival="heart-pulse", Growth="sprout", ["Auto Farm"]="pickaxe", Teleport="map-pin", Visuals="eye", Skins="palette", Misc="wrench", Settings="settings", Info="info"}
	mkTab = function(name) local tb=FWindow:AddTab({Title=name, Icon=ICONS[name] or ""}); Pages[name]=tb; return tb end
	mkSec = function(par, title) pcall(function() par:AddParagraph({Title=title, Content=""}) end); return par, par end
	mkToggle = function(par, txt, key) pcall(function() local t=par:AddToggle(key,{Title=txt, Default=CFG[key] and true or false}); t:OnChanged(function() CFG[key]=Options[key].Value; saveCfg() end) end) end
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
	CFG[key] = val and true or false
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
mkTab("Combat",1); mkTab("PvP",2); mkTab("Movement",3); mkTab("Survival",4); mkTab("Growth",5); mkTab("Auto Farm",6); mkTab("Teleport",7)
mkTab("Target",7.5)   -- Target tab always loads (the PE_PLUS gate made it vanish whenever the tier flag wasn't set)
mkTab("Visuals",8); mkTab("Skins",9); mkTab("Misc",10); mkTab("Settings",11); mkTab("Info",12)

do local p=Pages["Combat"]
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
	-- INF Stamina keeps the bar full and NEVER touches your movement (no WalkSpeed writes, no velocity writes) —
	-- the server never learns your stamina hit 0, so it never slows you, and there is nothing for its movement
	-- anti-cheat to snap back. The old Run Speed Drive + slider are gone; want extra speed? Use Speed Hack.
	mkLabel(f,"Keeps the bar full. Never touches movement = no snapbacks. Use Speed Hack for extra speed.",2)
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
	mkSlider(pr,"Damage Reduce %","HeadDmgReduce",0,95,4,5)
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
		for n=1,40 do if isfile and isfile(slotFile(n)) then local sp,st="Dino",nil; pcall(function() local r=HttpService:JSONDecode(readfile(slotFile(n))); if r and r.data then sp=r.data.Species or "Dino"; st=r.data.Stage end end); out[#out+1]=n..": "..sp..(st and (" - "..tostring(st)) or "") end end
		if #out==0 then out[1]="(none)" end
		return out
	end, function() return CFG.ProgSlotSel or "(none)" end, function(opt) CFG.ProgSlotSel=opt; saveCfg() end, 2)
	mkBtn(pg,"Save Progress",function()
		local pp=__gg.MH_restore
		if type(pp)~="table" then notify("Progress","Spawn in as the dino you want first, THEN save."); return end
		local r=progSerde("rec",pp); if not r then notify("Progress","Couldn't save that."); return end
		-- label with the current growth stage if we can detect it
		pcall(function() local rr=csReplica(); if rr and rr.Data then r.data.Stage = rr.Data.GrowthStage or rr.Data.Stage or (rr.Data.Growth and rr.Data.Growth.Stage) end if not r.data.Stage then local mm=getMyModel(); if mm then r.data.Stage = mm:GetAttribute("Stage") or mm:GetAttribute("GrowthStage") end end end)
		local n=1; while isfile and isfile(slotFile(n)) do n=n+1 end
		pcall(function() if writefile then writefile(slotFile(n), HttpService:JSONEncode(r)) end end)
		if slotsDD and slotsDD.refresh then slotsDD.refresh() end
		notify("Progress","Saved slot "..n.." — "..((r.data and r.data.Species) or "dino")..(r.data.Stage and (" "..tostring(r.data.Stage)) or ""))
	end,3)
	mkBtn(pg,"Restore Selected",function()
		local n=tonumber(tostring(CFG.ProgSlotSel or ""):match("^(%d+)"))
		if not (n and isfile and isfile(slotFile(n))) then notify("Progress","Pick a saved slot first."); return end
		local rec; pcall(function() rec=HttpService:JSONDecode(readfile(slotFile(n))) end)
		local pld=progSerde("pay",rec); if pld then __gg.MH_restore=pld; progressRestore() else notify("Progress","That slot is corrupted.") end
	end,4)
	mkBtn(pg,"Delete Selected",function()
		local n=tonumber(tostring(CFG.ProgSlotSel or ""):match("^(%d+)"))
		if not (n and isfile and isfile(slotFile(n))) then notify("Progress","Pick a saved slot first."); return end
		local f=slotFile(n)
		if delfile then pcall(function() delfile(f) end) elseif writefile then pcall(function() writefile(f,"") end) end
		CFG.ProgSlotSel="(none)"
		if slotsDD and slotsDD.refresh then slotsDD.refresh() end
		notify("Progress","Deleted slot "..n..".")
	end,5)
end
do local p=Pages["Growth"]
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
			local cc=getMyModel(); local goal=CFrame.new(best.Position+Vector3.new(0,3,0))
			pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) else me.CFrame=goal end end)
			pcall(function() local r=hrp(); if r then r.AssemblyLinearVelocity=Vector3.zero end end)
			notify("Teleport","At the nearest gemstone ("..math.floor(bd).."m away).")
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
		-- MICRO-STEP LEGIT MOVE (no send-back): one giant jump reads as impossible speed and the server rejects it.
		-- The hop-mover walks the server there in 20-stud believable hops on the game's OWN move remote (3x per hop,
		-- since the unreliable channel drops packets), moving you locally in step. ~400 studs/sec, sticks on arrival.
		if __gg.MH_hopMove then __gg.MH_hopMove(target)
		else local cc=char(); pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(CFrame.new(target)) else local r=hrp(); if r then r.CFrame=CFrame.new(target) end end end) end
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
	mkBtn(d,"Teleport to My Spawn / Origin", function() local r=hrp(); if r then tpTo(r.Position) end end, 3)
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
	mkBtn(s,"Rejoin Server",function() pcall(function() TeleportSvc:Teleport(game.PlaceId,LP) end) end,1)
	mkBtn(s,"Server Hop",function() pcall(function() TeleportSvc:Teleport(game.PlaceId,LP) end) end,2)
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
	if CFG.InfFood or CFG.InfWater or CFG.InfStam or CFG.InfOxygen or CFG.GodMode then
		local stats, maxs = csStats()
		if stats then
			pcall(function()
				-- Pin to the REAL max only (never inflate past it — writing 1000 to a 50-max stat made the server
				-- fight every write = the snapback/slowness). If max is unknown, leave it (the deep-walk handles it).
				if CFG.InfStam   and stats.Stamina ~= nil and maxs and maxs.Stamina then stats.Stamina = maxs.Stamina end
				-- INF Food does NOT pin the food bar (that pins it to max -> the game hides the eat prompt -> you
				-- can't hold E to eat). Auto-eat below keeps you fed by replaying bites, so food stays high but the
				-- prompt is always available. (Original herb method.)
				if CFG.InfWater  and stats.Water   ~= nil and maxs and maxs.Water   then stats.Water   = maxs.Water   end
				if CFG.InfOxygen and stats.Oxygen  ~= nil and maxs and maxs.Oxygen  then stats.Oxygen  = maxs.Oxygen  end
				if CFG.GodMode   and stats.Health  ~= nil and maxs and maxs.Health  then stats.Health  = maxs.Health  end
				if CFG.GodMode   and stats.Temperature ~= nil and maxs and maxs.Temperature then stats.Temperature = maxs.Temperature end
			end)
		end
		-- Deep walk so unknown key names are still caught.
		if (CFG.InfFood or CFG.InfWater or CFG.InfStam or CFG.InfOxygen) and (tick()-FARM.lastDeepPin>0.12) then FARM.lastDeepPin=tick()
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
				topPin(CFG.InfStam, {"Stamina","Stam","Energy","Endurance"}, {"MaxStamina","MaxStam","MaxEnergy"})
				-- (food intentionally NOT pinned — see the note above; auto-eat keeps it up without hiding the eat prompt)
				topPin(CFG.InfWater, {"Water","Thirst","Hydration"}, {"MaxWater","MaxThirst","MaxHydration"})
			end) end
		end
		pcall(pinHud)
	end
end))

-- FAST STAT PIN — EVERY render frame (the 0.15s deep-pin lagged behind the drain). Known keys only, so it's
-- cheap. NOTE: PE stats are SERVER-authoritative; this is the strongest client attempt + the Sip/eat actions
-- and the "run without Shift" below do the rest. Stamina only drains from sprint or 0 food/water; oxygen from
-- being underwater (we force the on-land state); food/water need the real actions to truly refill server-side.
conn(RunService.RenderStepped:Connect(function()
	if not (CFG.InfStam or CFG.InfOxygen or CFG.InfFood or CFG.InfWater or CFG.AntiFracture or CFG.AntiBleed or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso) then return end
	if not alive() then return end
	pcall(function()
		local stats, maxs = csStats()
		-- Pin to the REAL max — from MaxStats if present, else the HIGHEST value we've ever seen for that key (so it
		-- works even when MaxStats is missing). NEVER inflate past the real max (that made the server fight = snapback).
		local function pin(keys) for _,k in ipairs(keys) do
			if stats[k]~=nil then
				local cur=tonumber(stats[k])
				if cur then __gg.MH_max=__gg.MH_max or {}; if not __gg.MH_max[k] or cur>__gg.MH_max[k] then __gg.MH_max[k]=cur end end
				local target=(maxs and maxs[k]) or (__gg.MH_max and __gg.MH_max[k])
				if target then stats[k]=target end
			end
		end end
		local function zero(keys) for _,k in ipairs(keys) do if stats[k]~=nil then if type(stats[k])=="boolean" then stats[k]=false else stats[k]=0 end end end end
		if stats then
			if CFG.InfStam   then pin({"Stamina","Stam","Energy","Endurance"}); zero({"Exhaustion","Fatigue","Tired","Exhausted"}) end
			-- FOOD = 20% FLOOR ("can't eat / E blocked" fix): forcing the bar high made the game think you were
			-- full, which hides the eat prompt and blocks the E key. A 20% floor means you can never starve, but
			-- the bar stays LOW enough that manual eating up to 100% always works. Growth comes from the Bite
			-- spam, not the bar level. Raise-only, and hands-off while you hold E (+3s after).
			local eNow=false; pcall(function() eNow=UIS:IsKeyDown(Enum.KeyCode.E) end)
			if eNow then __gg.MH_lastE=tick() end
			-- 3s GRACE after you let go of E: your manual eat's result stays on screen / registers server-side
			-- before any forcing resumes — this is the "E sometimes works" fix (we were overwriting it instantly).
			if CFG.InfFood and not eNow and tick()-(__gg.MH_lastE or 0)>5 then for _,k in ipairs({"Food","Hunger","Nutrition","Fullness","Satiation"}) do
				if stats[k]~=nil then
					local cur=tonumber(stats[k])
					if cur then __gg.MH_max=__gg.MH_max or {}; if not __gg.MH_max[k] or cur>__gg.MH_max[k] then __gg.MH_max[k]=cur end end
					local target=(maxs and maxs[k]) or (__gg.MH_max and __gg.MH_max[k])
					if target and cur and cur < target*0.2 then stats[k]=target*0.2 end   -- only pin to 20% so you can still eat manually
				end
			end end
			if CFG.InfOxygen then pin({"Oxygen","Air","Breath","O2","Lung"}) end
			-- BONE PROTECTORS = HEALTH KEEP: the injury REPORT is swallowed in the hook, but the raw HP damage (your
			-- 1k head hit) is dealt server-side and can't be refused — so while any bone protector is on we also PIN
			-- your health + the Humanoid back to max, so a big bite is instantly refilled instead of dropping you.
			if CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso then
				pin({"Health","HP","Hitpoints"})
				pcall(function() local h=hum(); if h and h.MaxHealth>0 then h.Health=h.MaxHealth end end)
			end
			-- (food IS pinned above now — you asked for max growth over the E prompt; the Bite spam feeds real growth.)
			if CFG.InfWater  then pin({"Water","Thirst","Hydration"}) end
			-- (Anti bleed/fracture/break handled by the dedicated PATH-AWARE antiInjurySweep loop below — more thorough.)
		end
		if CharacterState then
			if CFG.InfOxygen then for _,k in ipairs({"IsInWater","Submerged","InWater","Underwater","Swimming","Drowning"}) do pcall(function() if CharacterState[k]~=nil then CharacterState[k]=false end end) end end
			-- Pin CharacterState stamina to the HIGHEST value we've seen (the real max) — NOT 1000. Inflating it past
			-- the real max made the server fight every frame = the "slow"/"not working" feel. Track the peak per key.
			if CFG.InfStam then for _,k in ipairs({"Stamina","Energy","Stam","Endurance"}) do pcall(function()
				if type(CharacterState[k])=="number" then
					__gg.MH_csmax=__gg.MH_csmax or {}; local cur=CharacterState[k]
					if not __gg.MH_csmax[k] or cur>__gg.MH_csmax[k] then __gg.MH_csmax[k]=cur end
					CharacterState[k]=__gg.MH_csmax[k]
				end
			end) end end
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

-- INF STAM (server-side refill — THE FIX): PE reports stamina to the server through the SAME ReplicaSignal
-- (ReplicatedStorage.RemoteEvents.ReplicaSignal, id = your replica id) that fires SetAction "Run" true/false.
-- Because it is client-reported, we just keep telling the server "stamina = full" faster than it can drain, so
-- the bar never reaches the exhaust threshold and the game never forces you down to walk speed. Run PASSES
-- THROUGH untouched, so you keep the game's real sprint speed — this is fully DECOUPLED from Speed Hack (no
-- BodyVelocity, no boosted speed). Refill is fast (0.12s) so a fast drain never accumulates.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════
-- INF STAM — THE REAL FIX (data-only, wellbeing-driven, no movement writes at all)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════
-- What actually makes you "slow": PE decides your run speed from your STAMINA VALUE. When it reads 0 it forces you
-- to walk. It reads that value from the client's own replica data. So the whole game is won on the DATA side — we
-- never touch WalkSpeed or velocity (that's what caused the snap-backs), we just make sure nothing can ever read
-- your stamina as low:
--   (A) Every frame, write stamina = its real max into EVERY place the client keeps it (Data.Stats, top-level
--       CharacterState, and a deep scan of the replica) so the client's own speed math never sees a low number.
--   (B) Report "stamina = full" to the server through the GAME'S OWN method (Replica:FireServer("SetProperty",...),
--       exactly how the game reports "Cave") on every stamina key, fast, so the server agrees.
--   (C) Kill the DRAIN AT THE SOURCE via WELLBEING: the decompiled WellbeingData says stamina drains SLOWER the
--       higher your Activity / Comfort / nutrition are, and buffered stats don't drain at all. We max those on the
--       real Wellbeing replica and keep their buffer timers open, so the drain multiplier bottoms out — the bar
--       stops falling in the first place, which is why exhaustion never triggers.
local STAM_KEYS = {"Stamina","Stam","Energy","Endurance","Vigor","SP","Fatigue","Exertion"}
task.spawn(function() while RUNNING do
	if CFG.InfStam and alive() then
		pcall(function()
			-- (A) LOCAL DATA PIN — every place the client might read stamina from
			local stats, maxs = csStats()
			local function pinLocal(tbl, mtbl)
				if type(tbl)~="table" then return end
				for _,k in ipairs(STAM_KEYS) do
					if type(tbl[k])=="number" then
						local cur=tbl[k]
						__gg.MH_max=__gg.MH_max or {}
						if cur>0 and (not __gg.MH_max[k] or cur>__gg.MH_max[k]) then __gg.MH_max[k]=cur end
						local target=(mtbl and mtbl[k]) or (__gg.MH_max and __gg.MH_max[k])
						if target then tbl[k]=target end
					end
				end
			end
			pinLocal(stats, maxs)
			local r=csReplica()
			if r and r.Data then
				pinLocal(r.Data.Stats, r.Data.MaxStats or r.Data.Max)
				pinLocal(r.Data.SavableStats and r.Data.SavableStats.Stats, nil)
			end
			if CharacterState then pinLocal(CharacterState, CharacterState) end
			-- (B) SERVER REPORT — through the game's OWN Replica method, then the raw path as backup
			for _,k in ipairs(STAM_KEYS) do
				local v = (__gg.MH_max and __gg.MH_max[k]) or (maxs and (maxs[k])) or 100
				pcall(function() csFireProp(k, v) end)
			end
			local sc=__gg.MH_stamCall
			if type(sc)=="table" and sc.n and sc.n>=2 then
				local rs=getReplicaSignal(); if rs then pcall(function() rs:FireServer(table.unpack(sc,1,sc.n)) end) end
			end
		end)
		task.wait(0.1)
	else task.wait(0.4) end
end end)

-- ═══ INF STAM — DIRECT Stats.Stamina PIN (your exact path) ═══ EVERY render frame (60/s, not 10/s), hold the
-- real object and slam Stamina to its max: CharacterState.Replica.Data.Stats.Stamina. The 0.1s loop above left a
-- gap the drain slipped through between frames — this closes it. The reference is re-fetched if it goes stale
-- (respawn / dino change). Pure data write, no movement.
conn(RunService.RenderStepped:Connect(function()
	if not (CFG.InfStam and alive()) then return end
	pcall(function()
		local Data = CharacterState and CharacterState.Replica and CharacterState.Replica.Data
		local Stats = Data and Data.Stats
		if type(Stats)~="table" then return end
		if type(Stats.Stamina)=="number" then
			-- learn the real max (highest ever seen or MaxStats), never inflate past it (that made the server fight)
			local mx = (Data.MaxStats and Data.MaxStats.Stamina)
			if Stats.Stamina>0 then __gg.MH_stamMax = math.max(__gg.MH_stamMax or 0, Stats.Stamina, mx or 0) end
			local target = mx or __gg.MH_stamMax
			if target and Stats.Stamina < target then Stats.Stamina = target end
		end
	end)
end))
-- INF STAM — WALKSPEED KEEPER (back by request: "it STILL makes me slow"). Data pin alone wasn't enough — the
-- client still cut your WalkSpeed when it thought you were exhausted. This restores it. It writes ONLY WalkSpeed
-- (never velocity/CFrame), so it does NOT cause the position snap-back — that only ever came from velocity writes,
-- which stay removed. Learns your dino's real sprint (highest WalkSpeed seen) and puts it back the instant it's
-- cut. Resets per dino. If a specific server still fights it, use Speed Hack for a hard bypass.
conn(RunService.Heartbeat:Connect(function()
	if not (CFG.InfStam and alive()) or CFG.SpeedHack or CFG.Fly then return end
	pcall(function()
		local m=(WS:FindFirstChild("Characters") and WS.Characters:FindFirstChild(LP.Name)) or char()
		if __gg.MH_runSpeedM~=m then __gg.MH_runSpeedM=m; __gg.MH_runSpeed=0 end
		local h=m and m:FindFirstChildOfClass("Humanoid")
		if h and h.WalkSpeed and h.WalkSpeed>0 then
			if h.WalkSpeed > (__gg.MH_runSpeed or 0) then __gg.MH_runSpeed=h.WalkSpeed end
			if __gg.MH_runSpeed and __gg.MH_runSpeed>0 and h.WalkSpeed < __gg.MH_runSpeed - 0.1 then h.WalkSpeed=__gg.MH_runSpeed end
		end
	end)
end))
-- Also pin stamina on Stepped + Heartbeat (not just RenderStepped) so whichever loop the game reads stamina on,
-- it sees full — closes the last timing gap that let the slow flicker in.
local function stamPinNow()
	if not (CFG.InfStam and alive()) then return end
	pcall(function()
		local Data = CharacterState and CharacterState.Replica and CharacterState.Replica.Data
		local Stats = Data and Data.Stats
		if type(Stats)=="table" and type(Stats.Stamina)=="number" then
			local mx = (Data.MaxStats and Data.MaxStats.Stamina)
			if Stats.Stamina>0 then __gg.MH_stamMax = math.max(__gg.MH_stamMax or 0, Stats.Stamina, mx or 0) end
			local target = mx or __gg.MH_stamMax
			if target and Stats.Stamina < target then Stats.Stamina = target end
		end
	end)
end
conn(RunService.Stepped:Connect(stamPinNow))
conn(RunService.Heartbeat:Connect(stamPinNow))

-- INF FOOD — FLOOR KEEPER (keep the bar UP whether you eat or not, WITHOUT hiding the eat prompt): the food bar
-- is only topped up when it falls BELOW ~60% of max, and only raised to ~80% — never to 100%. So:
--   · you never starve / go low (the bar always stays high), and
--   · because it is never pinned to full, the eat ProximityPrompt keeps showing, so you can still hold E to eat
--     for growth. Eating pushes you toward 100%; this keeper never pulls you back down (it only fires when low).
-- Reports through the SAME ReplicaSignal SetProperty the game uses, plus a client write so the HUD matches.
-- ═══ INF FOOD — SEVEN STRONG (20% floor + Bite spam) ═══ Keeps the food bar off the floor and re-fires your captured
-- Bite remotes so the server keeps registering you eating (= growth). Backs off only while YOU hold E, so a manual
-- hold-to-eat still works. Bite fires are capped per pass so this stays strong WITHOUT re-introducing the lag.
task.spawn(function() while RUNNING do
	if CFG.InfFood and alive() then
		local eHeld=false; pcall(function() eHeld=UIS:IsKeyDown(Enum.KeyCode.E) end)
		if eHeld then __gg.MH_lastE=tick() end
		if not eHeld and tick()-(__gg.MH_lastE or 0)>5 then   -- 5s grace after E so a manual eat is never overwritten

			pcall(function()
				local stats, maxs = csStats()
				local foodKey, mx, cur
				if stats then
					for _,k in ipairs({"Food","Hunger","Nutrition","Fullness","Satiation"}) do
						if type(stats[k])=="number" then foodKey=k; cur=stats[k]; break end
					end
					if foodKey then
						mx = (maxs and (maxs[foodKey] or maxs.Food)) or (__gg.MH_maxFood) or 100
						if cur and cur > 0 then __gg.MH_maxFood = math.max(__gg.MH_maxFood or 0, cur, mx); mx = __gg.MH_maxFood end
						if cur and cur < mx*0.2 then   -- FORCE TO 20% so you can still eat manually (high forcing hid the prompt + blocked E)
							pcall(function() replicaFire("SetProperty", foodKey, mx*0.2) end)
							pcall(function() stats[foodKey] = mx*0.2 end)
						end
					end
				end
			end)
			-- Bite spam (growth) — STRONGER: fires each captured Bite remote FoodEatSpeed times per pass (your
			-- "INF Food grow speed" slider finally drives this, 1-10x), capped at 30 fires per pass so it can't lag.
			if __gg.MH_lastEatCall then
				local rs=getReplicaSignal()
				if rs then
					local list=__gg.MH_biteCalls; if type(list)~="table" or #list==0 then list={__gg.MH_lastEatCall} end
					local spamCount=math.clamp(tonumber(CFG.FoodEatSpeed) or 5, 1, 10)
					local fired=0
					for _,ec in ipairs(list) do
						if type(ec)=="table" and ec.n and ec.n>=2 then
							for _=1,spamCount do pcall(function() rs:FireServer(table.unpack(ec,1,ec.n)) end); fired=fired+1; if fired>=30 then break end end
						end
						if fired>=30 then break end
					end
				end
			end
		end
		task.wait(0.1)
	else task.wait(0.4) end
end end)

-- ═══ E EAT ASSIST — the definitive "E doesn't work" fix ═══ When you PRESS E, the hub makes the eat land for
-- you: it finds the nearest eat/consume ProximityPrompt within reach (meat chunks, corpses, plants — the game's
-- MeatController tags meat with HintType="Corpse"), removes its line-of-sight requirement, and FIRES it directly.
-- So even when the game's own prompt logic refuses (bar too high, prompt hidden, LOS blocked), your E still eats.
-- All hub food-writes also freeze for 5s after E so nothing overwrites what you just ate.
conn(UIS.InputBegan:Connect(function(input, gp)
	if input.KeyCode ~= Enum.KeyCode.E then return end
	__gg.MH_lastE = tick()   -- freeze the food forcers (checked with a 5s grace below/above)
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
			pcall(function() best.RequiresLineOfSight = false end)
			if fireprox then
				local oh=best.HoldDuration
				pcall(function() best.HoldDuration=0 end)
				pcall(function() fireprox(best) end)
				pcall(function() best.HoldDuration=oh end)
			end
		end
	end) end)
end))

-- BITE-REMOTE WATCHER ("make sure INF Food is catching the Bite REMOTE, not the animation"): growth comes ONLY
-- from replaying the game's real Bite RemoteEvent call, captured the first time a bite fires. This watcher tells
-- you plainly which state you're in: still waiting for a capture (and how to force one — eat anything once), or
-- captured and remote-driven. No animation is ever involved — animations don't grow you and we never play one.
task.spawn(function()
	local told=false
	local waitedT=nil
	while RUNNING do
		if CFG.InfFood and alive() then
			-- (VAGUE on purpose — the toasts never say HOW it works, so nothing here can get the method patched.)
			if __gg.MH_lastEatCall then
				if not told then told=true; pcall(function() notify("INF Food","Active.") end) end
				waitedT=nil
			else
				waitedT = waitedT or tick()
				if tick()-waitedT > 20 then
					waitedT = tick()
					pcall(function() notify("INF Food","Eat any food once (hold E) to activate.") end)
				end
			end
		else waitedT=nil end
		task.wait(1)
	end
end)
-- WELLBEING PIN (the "INF Stam breaks with INF Food" fix): PE hides a stamina-drain MULTIPLIER behind the
-- Wellbeing stats — WellbeingData says "High activity makes your stamina drain less" and "Comfort goes down… eating
-- bad food". When those drop (e.g. from eating the wrong diet) stamina drains faster than any pin can refill, so
-- INF Stam looks broken. These stats live in Replica.Data.SavableStats.Stats (not Data.Stats). We hard-pin Comfort,
-- Activity, nutrition and immunity to full and zero Toxins, so the drain penalty is removed and INF Stam holds even
-- with INF Food on. Runs whenever INF Stam / INF Food / God Mode is on.
do
	local WB_MAX = {"Comfort","Activity","Cleanliness","Immunity","Proteins","Fats","Calcium","Fiber","Carbohydrates","Nutrition","Wellbeing"}
	local WB_ZERO = {"Toxins","Toxin","Toxicity"}
	-- THE REAL WELLBEING REPLICA (from the decompiled Wellbeing class): these stats do NOT live on the
	-- CharacterState replica — the game creates a SEPARATE replica with the token "Wellbeing"
	-- (Replica.Client.OnNew("Wellbeing", ...)) holding Data.SavableStats.Stats + Data.SavableStats.BufferTimers.
	-- The old pin wrote to CharacterState.Replica.Data.SavableStats, which usually doesn't exist = the pin did
	-- NOTHING. We now grab the actual Wellbeing replica through the game's own Replica package and pin THAT.
	task.spawn(function()
		pcall(function()
			local pk = RS:WaitForChild("Packages", 20); pk = pk and pk:WaitForChild("Replica", 10)
			local Client = pk and require(pk).Client
			if Client and Client.OnNew then Client.OnNew("Wellbeing", function(rep) __gg.MH_wellbeing = rep end) end
		end)
	end)
	task.spawn(function() while RUNNING do
		if (CFG.InfStam or CFG.InfFood or CFG.GodMode) and alive() then
			pcall(function()
				-- 1) the REAL Wellbeing replica (decompile-verified home of these stats)
				local rep = __gg.MH_wellbeing
				local ss = rep and rep.Data and rep.Data.SavableStats and rep.Data.SavableStats.Stats
				if ss then
					for _,k in ipairs(WB_MAX)  do if type(ss[k])=="number" then ss[k]=100 end end
					for _,k in ipairs(WB_ZERO) do if type(ss[k])=="number" then ss[k]=0   end end
				end
				-- BUFFER TIMERS: while a stat's buffer timer is up it doesn't drain — keep them all topped up,
				-- so wellbeing (and through it the stamina-drain multiplier) never decays in the first place.
				local bt = rep and rep.Data and rep.Data.SavableStats and rep.Data.SavableStats.BufferTimers
				if bt then for k,v in pairs(bt) do if type(v)=="number" and v<30 then bt[k]=60 end end end
				-- 2) report the pins to the server through the replica's own channel (same client-reported
				-- SetProperty pattern the game itself uses, e.g. for "Cave"); unknown shapes are ignored = harmless
				if rep and rep.FireServer then
					for _,k in ipairs({"Comfort","Activity"}) do
						pcall(function() rep:FireServer("SetProperty", k, 100) end)
						pcall(function() rep:FireServer("SetProperty", "Stats", k, 100) end)
					end
				end
				-- 3) legacy fallbacks (older builds mirrored these under CharacterState) — keep, they're cheap
				local r=csReplica()
				local ss2 = r and r.Data and r.Data.SavableStats and r.Data.SavableStats.Stats
				if ss2 then
					for _,k in ipairs(WB_MAX)  do if type(ss2[k])=="number" then ss2[k]=100 end end
					for _,k in ipairs(WB_ZERO) do if type(ss2[k])=="number" then ss2[k]=0   end end
				end
				local stats=csStats()
				if stats then for _,k in ipairs({"Comfort","Activity"}) do if type(stats[k])=="number" then stats[k]=100 end end end
			end)
			pcall(function() replicaFire("SetProperty","Comfort",100) end)
			pcall(function() replicaFire("SetProperty","Activity",100) end)
			task.wait(0.4)
		else task.wait(0.6) end
	end end)
end

-- ═══ AUTO HEAL BLOOD (no sleep needed) — in PE "blood damage" only recovers by sleeping/waiting. This keeps the
-- blood + health pool topped and clears the bleed/wound accumulators (the things that force the sleep), through the
-- SAME replica-stats path GodMode/INF-Food already use, plus the Humanoid + model attributes as a fallback.
task.spawn(function() while RUNNING do
	if CFG.AutoHealBlood and alive() then
		pcall(function()
			local stats, maxs = csStats()
			if stats then
				-- clear the bleed / wound / blood-loss accumulators that gate recovery
				for _,k in ipairs({"Bleed","Bleeding","BleedDamage","Bloodloss","BloodLoss","Wound","Wounds","Hemorrhage","Injury"}) do
					if stats[k]~=nil then if type(stats[k])=="boolean" then stats[k]=false else stats[k]=0 end end
				end
				-- refill the blood / health pool (what sleeping slowly restores) to its real max
				for _,k in ipairs({"Blood","BloodLevel","BloodVolume","Health","HP","Vitality"}) do
					if stats[k]~=nil and maxs and maxs[k] then stats[k]=maxs[k] end
				end
				-- clear tiredness so the game doesn't insist you sleep
				for _,k in ipairs({"Tiredness","Tired","Sleep","Sleepiness","Rest","Exhaustion","Fatigue"}) do
					if stats[k]~=nil then if type(stats[k])=="boolean" then stats[k]=false else stats[k]=0 end end
				end
			end
		end)
		pcall(function() local h=hum(); if h and h.MaxHealth>0 and h.Health<h.MaxHealth then h.Health=h.MaxHealth end end)
		pcall(function() local m=getMyModel(); if m then for _,a in ipairs({"Bleed","Bleeding","BleedDamage","Bloodloss","Wound","Wounds","Blood"}) do
			local v=m:GetAttribute(a); if type(v)=="number" then m:SetAttribute(a, (a=="Blood") and math.max(v,100) or 0) elseif type(v)=="boolean" then m:SetAttribute(a,false) end
		end end end)
		task.wait(0.5)
	else task.wait(0.5) end
end end)

-- ═══ ANTI-INJURY (path-aware): we don't know the exact bleed/break field names, so walk the WHOLE replica tree
-- (Replica.Data + CharacterState, depth 5) and clear anything that looks like an injury — matching the PATH, not
-- just the leaf key, so nested fields like Bones.Leg.Broken / Wounds.Bleeding are caught. Each toggle scopes which
-- injuries get cleared; a generic "Broken"/"Bleeding" with no body part in the path clears if ANY break anti is on.
local function antiInjurySweep(tb, path, depth)
	if type(tb)~="table" or depth>5 then return end
	for k,v in pairs(tb) do
		local kp = path..tostring(k):lower().."."
		local tv = type(v)
		if tv=="boolean" or tv=="number" then
			local clear=false
			if CFG.AntiBleed and (kp:find("bleed",1,true) or kp:find("hemorrhage",1,true) or kp:find("bloodloss",1,true)) then clear=true end
			if CFG.AntiFracture and (kp:find("fractur",1,true) or kp:find("concuss",1,true)) then clear=true end
			-- ANTI HEAD now clears EVERY break (incl. the LEG break that slows Trike/Anky/Deino — the "Broke Leg" you
			-- saw) so slow/tanky dinos stay un-slowed, not just un-head-fractured.
			if (kp:find("brok",1,true) or kp:find("break",1,true) or kp:find("sever",1,true) or kp:find("dislocat",1,true) or kp:find("snap",1,true) or kp:find("crippl",1,true)) then
				local anyBreak = CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso
				-- Anti Head (AntiFracture) clears the break on ANY part; the specific AntiBreak* toggles still work too.
				local part
				if kp:find("head",1,true) or kp:find("jaw",1,true) or kp:find("skull",1,true) then part=CFG.AntiFracture or CFG.AntiBreakHead
				elseif kp:find("neck",1,true) then part=CFG.AntiFracture or CFG.AntiBreakNeck
				elseif kp:find("leg",1,true) or kp:find("foot",1,true) or kp:find("limb",1,true) or kp:find("femur",1,true) or kp:find("tibia",1,true) or kp:find("thigh",1,true) or kp:find("pubis",1,true) then part=CFG.AntiFracture or CFG.AntiBreakLeg
				elseif kp:find("tail",1,true) then part=CFG.AntiFracture or CFG.AntiBreakTail
				elseif kp:find("torso",1,true) or kp:find("spine",1,true) or kp:find("rib",1,true) or kp:find("body",1,true) then part=CFG.AntiFracture or CFG.AntiBreakTorso
				else part=anyBreak end
				if part then clear=true end
				-- BONE PROTECTION: clear the break/fracture for the chosen bone (status-based, NOT hitbox-shrink).
				if not clear and CFG.BoneProtect then
					local sel=CFG.ProtectBone or "All"
					if sel=="All" then clear=true
					elseif sel=="Head" and (kp:find("head",1,true) or kp:find("jaw",1,true) or kp:find("skull",1,true)) then clear=true
					elseif sel=="Neck" and kp:find("neck",1,true) then clear=true
					elseif sel=="Arm" and (kp:find("arm",1,true) or kp:find("hand",1,true) or kp:find("claw",1,true) or kp:find("humerus",1,true)) then clear=true
					elseif sel=="Leg" and (kp:find("leg",1,true) or kp:find("foot",1,true) or kp:find("femur",1,true) or kp:find("tibia",1,true) or kp:find("thigh",1,true)) then clear=true
					elseif sel=="Body" and (kp:find("spine",1,true) or kp:find("body",1,true) or kp:find("hip",1,true) or kp:find("torso",1,true) or kp:find("rib",1,true) or kp:find("tail",1,true)) then clear=true end
				end
			end
			if CFG.BoneProtect and (kp:find("fractur",1,true) or kp:find("concuss",1,true)) then clear=true end  -- anti-fractured-head etc.
			-- IMPROVED PROTECTION: when ANY protection anti is on, also wipe the disable states that bypass it — stun,
			-- daze, stagger, downed, ragdoll, knockout, grabbed/pinned — so you can't be locked/killed through it.
			if not clear then
				local anyProt = CFG.AntiBleed or CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso
				if anyProt and (kp:find("stun",1,true) or kp:find("daze",1,true) or kp:find("stagger",1,true) or kp:find("downed",1,true) or kp:find("ragdoll",1,true) or kp:find("knockout",1,true) or kp:find("grabbed",1,true) or kp:find("pinned",1,true) or kp:find("frozen",1,true)) then clear=true end
			end
			if clear then
				if tv=="boolean" then if v then pcall(function() tb[k]=false end) end
				else if v~=0 then pcall(function() tb[k]=0 end) end end
			end
		elseif tv=="table" and getmetatable(v)==nil then
			antiInjurySweep(v, kp, depth+1)
		end
	end
end
-- ═══ ANTI HEAD / BONE PROTECTION — DAMAGE HEAL-BACK (the real "I still get damage" fix) ═══ PE damage is server-
-- side and report-based, so we can't change the hit number — but we can HEAL BACK part of every hit the instant it
-- lands. Each Heartbeat we read your HP; if it dropped, we restore HeadDmgReduce% of that drop (default 90%), so a
-- 1k head hit nets ~100. This is what actually stops you dying to head hits / bleed / breaks (not just the blur).
-- Tied to Anti Head (AntiFracture) OR Bone Protection so either toggle gives real damage reduction.
conn(RunService.Heartbeat:Connect(function()
	if not ((CFG.AntiFracture or CFG.BoneProtect) and alive()) then __gg.MH_lastHP=nil; return end
	pcall(function()
		local h=hum(); local stats,maxs=csStats()
		-- READ HP FROM EVERY SOURCE (so it works on EVERY dino — the tanky/slow ones like Trike/Anky/Deino store HP
		-- differently, so a single-source read silently did nothing = "anti head doesn't work on slower dinos").
		local hp, mx
		if stats then for _,k in ipairs({"Health","HP","Hp","health","hp","Hitpoints","HitPoints"}) do if tonumber(stats[k]) then hp=tonumber(stats[k]); break end end end
		if maxs then for _,k in ipairs({"Health","HP","MaxHealth","Hp","Hitpoints"}) do if tonumber(maxs[k]) then mx=tonumber(maxs[k]); break end end end
		if not hp and h then hp=h.Health end
		if not mx and h then mx=h.MaxHealth end
		if not hp and CharacterState then pcall(function() hp=tonumber(CharacterState.Health) end) end
		if not mx and CharacterState then pcall(function() mx=tonumber(CharacterState.MaxHealth) end) end
		if (not hp or not mx) then local m=getMyModel(); if m then
			if not hp then local v=m:GetAttribute("Health") or m:GetAttribute("HP"); if tonumber(v) then hp=tonumber(v) end end
			if not mx then local v=m:GetAttribute("MaxHealth") or m:GetAttribute("MaxHP"); if tonumber(v) then mx=tonumber(v) end end
		end end
		if not hp or not mx or mx<=0 or mx>=1e7 then return end
		local last = __gg.MH_lastHP or hp
		if hp < last-0.05 then   -- ANY drop (incl. small bleed DoT ticks)
			local frac = math.clamp((tonumber(CFG.HeadDmgReduce) or 90)/100, 0, 0.95)
			local newHP = math.min(mx, hp + (last-hp)*frac)   -- heal back `frac` of the damage = take only (1-frac)
			if stats then for _,k in ipairs({"Health","HP","Hp","health","hp","Hitpoints","HitPoints"}) do if stats[k]~=nil then stats[k]=newHP end end end
			if h then pcall(function() h.Health=newHP; h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end) end
			if CharacterState then for _,k in ipairs({"Health","HP"}) do if type(CharacterState[k])=="number" then CharacterState[k]=newHP end end end
			pcall(function() local m=getMyModel(); if m then for _,k in ipairs({"Health","HP"}) do if m:GetAttribute(k)~=nil then m:SetAttribute(k,newHP) end end end end)
			pcall(function() setReplicaProp("Health", newHP) end)
			__gg.MH_lastHP = newHP
		else __gg.MH_lastHP = math.min(hp, mx) end
	end)
end))
-- (REMOVED — the head-hitbox shrink: it made YOUR OWN attacks deal no damage. PE uses your own hitbox parts as
-- the bite ORIGIN, so CanQuery=false / shrinking them broke outgoing hits ("I can't hit / no damage"). Anti Head
-- protection = the report-swallow in the hook + the HP-restore below, which never touch your hitbox.)
-- ═══ ANTI HEAD / BONE PROTECTION — AGGRESSIVE DAMAGE BLOCK (ANTI 1K DAMAGE) ═══
-- Incoming damage is dealt SERVER-side (the attacker's client reports the bite; the server drops your HP), so we
-- can't refuse it. Instead: the instant HP drops, heal straight back to max, block the Dead state, and report full.
conn(RunService.Heartbeat:Connect(function()
	if not ((CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso) and alive()) then __gg.MH_lastHP=nil; return end
	pcall(function()
		local h=hum(); local stats,maxs=csStats()
		local hp, mx
		if stats then for _,k in ipairs({"Health","HP","Hp","Hitpoints","HitPoints"}) do if tonumber(stats[k]) then hp=tonumber(stats[k]); break end end end
		if maxs then for _,k in ipairs({"Health","HP","MaxHealth","Hitpoints"}) do if tonumber(maxs[k]) then mx=tonumber(maxs[k]); break end end end
		if not hp and h then hp=h.Health end
		if not mx and h then mx=h.MaxHealth end
		if not hp and CharacterState then pcall(function() hp=tonumber(CharacterState.Health) end) end
		if not mx and CharacterState then pcall(function() mx=tonumber(CharacterState.MaxHealth) end) end
		if not hp or not mx or mx<=0 then return end
		local last = __gg.MH_lastHP or hp
		if hp < last - 5 then   -- took real damage (even a 1k headshot) → heal it straight back + block death
			local newHP = mx
			if stats then for _,k in ipairs({"Health","HP","Hp","Hitpoints","HitPoints"}) do if stats[k]~=nil then stats[k]=newHP end end end
			if h then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end); pcall(function() h.Health=newHP end) end
			if CharacterState then for _,k in ipairs({"Health","HP"}) do if type(CharacterState[k])=="number" then CharacterState[k]=newHP end end end
			pcall(function() local m=getMyModel(); if m then for _,k in ipairs({"Health","HP"}) do if m:GetAttribute(k)~=nil then m:SetAttribute(k,newHP) end end end end)
			pcall(function() setReplicaProp("Health", newHP) end)
			__gg.MH_lastHP = newHP
		else __gg.MH_lastHP = math.min(hp, mx) end
		if CharacterState and type(CharacterState.Fractures)=="table" then for k in pairs(CharacterState.Fractures) do CharacterState.Fractures[k]=false end end
	end)
end))
-- AGGRESSIVE BONE PROTECTION every FRAME: clear fractures + un-ragdoll/un-stun so a break never slows/stuns you.
conn(RunService.RenderStepped:Connect(function()
	if not ((CFG.BoneProtect or CFG.AntiFracture or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso) and alive()) then return end
	pcall(function()
		if CharacterState and type(CharacterState.Fractures)=="table" then for k in pairs(CharacterState.Fractures) do CharacterState.Fractures[k]=false end end
		local h=hum()
		if h then
			if h.PlatformStand then h.PlatformStand=false end
			local st=h:GetState()
			if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown or st==Enum.HumanoidStateType.PlatformStanding then
				pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
			end
		end
	end)
end))
-- Instant revive if the server ever forces the Dead state while a protector is on.
conn(LP.CharacterAdded:Connect(function(char)
	local h = char:WaitForChild("Humanoid", 5)
	if h then h.StateChanged:Connect(function(_, new)
		if new==Enum.HumanoidStateType.Dead and (CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead) then
			pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp); h.Health=h.MaxHealth end)
		end
	end) end
end))
task.spawn(function() while RUNNING do
	if (CFG.AntiBleed or CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso) and alive() then
		pcall(function() local r=csReplica(); if r and r.Data then antiInjurySweep(r.Data, "", 0) end end)
		pcall(function() if CharacterState then for _,s in ipairs({"Stats","State","Data","Wounds","Bones","BodyParts","Status"}) do local t=CharacterState[s]; if type(t)=="table" then antiInjurySweep(t, s:lower()..".", 0) end end end end)
		-- CharacterState.Fractures — the decompiled game gates running on `Run and not Fractures.Leg`, so a broken leg =
		-- no run = the SLOW on Trike/Anky/Deino. Clear the whole table (+ the known head/leg keys) so Anti Head keeps
		-- slow dinos un-slowed. Tied to Anti Head / Bone Protection.
		if CFG.AntiFracture or CFG.BoneProtect then pcall(function() if CharacterState and type(CharacterState.Fractures)=="table" then
			for k in pairs(CharacterState.Fractures) do CharacterState.Fractures[k]=false end
			for _,fk in ipairs({"Head","Skull","Neck","Leg","Foot","Limb","Tail","Torso","Spine","Body"}) do CharacterState.Fractures[fk]=false end
		end end) end
		-- un-ragdoll: a knockdown must never stick while protection is on (dinos that DO have a Humanoid)
		pcall(function() local h=hum(); if h then if h.PlatformStand then h.PlatformStand=false end
			local st=h:GetState(); if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end end)
		task.wait(0.08)
	else task.wait(0.3) end
end end)
-- ═══ BONE PROTECTION — SHRINK THE PROTECTED BONE'S HITBOX (your idea) ═══ PE resolves a bite by querying which of
-- YOUR Hitbox parts the attacker overlapped. So for the bone you pick (Protect Bone), we shrink YOUR OWN Hitbox.<bone>
-- part to near-zero + CanQuery/CanTouch = false → the attacker's hit-check finds NOTHING there → the hit resolves off
-- that bone (or misses) = no head/leg crit. Massless=true so shrinking it NEVER changes your body mass = you still MOVE
-- normally. Only touches the defensive Hitbox container parts, NEVER your steer body / RootPart, so your M1 is fine.
-- Everything is restored the instant Bone Protection is turned off.
do local bpSaved={}
	local function protMatch(nm)
		local sel=CFG.ProtectBone or "All"; local n=tostring(nm):lower()
		if sel=="All" then return true end
		if sel=="Head" then return n:find("head",1,true) or n:find("jaw",1,true) or n:find("skull",1,true) or n:find("neck",1,true) end
		if sel=="Neck" then return n:find("neck",1,true) end
		if sel=="Arm"  then return n:find("arm",1,true) or n:find("hand",1,true) or n:find("claw",1,true) or n:find("humerus",1,true) end
		if sel=="Leg"  then return n:find("leg",1,true) or n:find("foot",1,true) or n:find("femur",1,true) or n:find("tibia",1,true) or n:find("thigh",1,true) end
		if sel=="Body" then return n:find("spine",1,true) or n:find("body",1,true) or n:find("hip",1,true) or n:find("torso",1,true) or n:find("tail",1,true) end
		return false
	end
	task.spawn(function() while RUNNING do task.wait(0.15)
		local m=getMyModel()
		if CFG.BoneProtect and alive() and m then
			for _,cn in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do local hb=m:FindFirstChild(cn)
				if hb then local parts = hb:IsA("BasePart") and {hb} or hb:GetDescendants()
					for _,d in ipairs(parts) do if d:IsA("BasePart") and protMatch(d.Name) then
						if bpSaved[d]==nil then bpSaved[d]={d.Size,d.CanQuery,d.CanTouch,d.Massless} end
						pcall(function() d.Massless=true; if d.Size.X>0.06 then d.Size=Vector3.new(0.05,0.05,0.05) end; d.CanQuery=false; d.CanTouch=false end)
					elseif d:IsA("BasePart") and bpSaved[d] and not protMatch(d.Name) then   -- bone switched away → restore
						local v=bpSaved[d]; pcall(function() if d.Parent then d.Size=v[1]; d.CanQuery=v[2]; d.CanTouch=v[3]; d.Massless=v[4] end end); bpSaved[d]=nil
					end end
				end
			end
		elseif next(bpSaved) then
			for d,v in pairs(bpSaved) do pcall(function() if d and d.Parent then d.Size=v[1]; d.CanQuery=v[2]; d.CanTouch=v[3]; d.Massless=v[4] end end); bpSaved[d]=nil end
		end
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
-- SPEED HACK ONLY drives the body by velocity. INF Stam does NOT touch your movement anymore — driving velocity
-- made the server snap you back AND counted as sprinting (which drained stamina, then exhausted = slow when you
-- toggled off). INF Stam now just suppresses the drain (hook + stat pin), so you move at NORMAL speed, stam full.
conn(RunService.Heartbeat:Connect(function() if CFG.SpeedHack and alive() and not CFG.Fly then local r=hrp(); if r then local spd=CFG.SpeedVal; local dir=Vector3.zero; local cf=workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new() if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end if dir.Magnitude<=0 then local hh=hum(); local md=hh and hh.MoveDirection; if md and md.Magnitude>0 then dir=md end end if dir.Magnitude>0 then dir=Vector3.new(dir.X,0,dir.Z).Unit*spd; r.AssemblyLinearVelocity=Vector3.new(dir.X,r.AssemblyLinearVelocity.Y,dir.Z) end end end end))
-- INF STAM IS PURE NOW (per client request): infinite stamina is DECOUPLED from any speed boost. We do NOT
-- swallow the "Run" report anymore, so the server keeps sprinting you at your real sprint speed on its own —
-- the old BodyVelocity speed-keeper is therefore unnecessary AND was the thing that glitched movement / "prevented
-- progress" when combined with the speed-up. INF Stam now only holds the bar full + suppresses the drain (the hook
-- + the HARD STAMINA PIN below). This loop just makes sure any leftover keeper velocity is removed so nothing
-- ever drives your movement. If you want extra speed, use the separate Speed Hack toggle.
conn(RunService.Heartbeat:Connect(function()
	if __gg.MH_stamBV then pcall(function() __gg.MH_stamBV:Destroy() end); __gg.MH_stamBV=nil end
end))
-- HARD STAMINA PIN (the reference's fix for NOT swallowing Run): slam the stamina value back to its REAL max in ALL
-- THREE frame phases — RenderStepped (start), Stepped (after physics), Heartbeat (after replication). If the server
-- replicates a drained value mid-frame, the Heartbeat write lands AFTER it, so our full value always wins = the bar
-- never visibly drops even though Run replicates. Pins every known stamina key + clears exhaustion.
do local STAM_PIN_KEYS = {"Stamina","Stam","Energy","Endurance","Vigor","Wellbeing"}
	local function pinStamNow()
		if not (CFG.InfStam and alive()) then return end
		pcall(function() local s,m=csStats(); if s then for _,k in ipairs(STAM_PIN_KEYS) do if s[k]~=nil then s[k]=(m and m[k]) or math.max(tonumber(s[k]) or 0,100) end end
			for _,k in ipairs({"Exhaustion","Fatigue","Tired","Exhausted"}) do if s[k]~=nil then if type(s[k])=="boolean" then s[k]=false else s[k]=0 end end end end end)
		pcall(function() if CharacterState then for _,k in ipairs(STAM_PIN_KEYS) do local v=CharacterState[k]; if type(v)=="number" then CharacterState[k]=math.max(v,100) end end end end)
	end
	conn(RunService.Stepped:Connect(function() pinStamNow() end))
	conn(RunService.Heartbeat:Connect(function() pinStamNow() end))
end
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
	if CFG.InfStam then pinStat({"stam","energy","endur","wellbeing"},{"Stamina","Energy","Endurance","Wellbeing"},100); clearStatus({},{"exhaust","tired","fatigue"}) end
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
	if tick()-FARM.food.t < 3 then return FARM.food.list end  -- 3s cache (was 1.5) — lighter
	local me=hrp(); local out={}; local seen={}
	if me then
		local cnt=0
		-- edible-plant / herb name list (this game's flora) so INF Food eats ANY plant type around you, not just corpses
		local PLKW={"plant","sapling","tree","fern","berry","berries","pine","needle","leaf","leaves","frond","conifer","cycad","mushroom","fungus","grass","moss","bush","shrub","flower","seed","cone","horsetail","redwood","ginkgo","sequoia","equisetum","woodwardia","blechn","gleichenia","osmunda","zingiber","dicksonia","williamsonia","dryophyll","sabalit","marmarthia","coniopteris","wielandiella","hermanophyton","anthill","herb","foliage","trunk","paleoaster","palaeoaster","araucaria","agathis","athrotaxite","brachyphyllum","elatide","platanites","cycadeoidea"}
		local function isPlantN(n) for _,k in ipairs(PLKW) do if n:find(k,1,true) then return true end end return false end
		-- 1) prompts: corpses (investigate/eat/consume) AND plants (graze/forage/feed/pick/harvest/eat). Fire ANY of them.
		for _,d in ipairs(WS:GetDescendants()) do
			cnt+=1; if cnt>6000 then break end
			if d:IsA("ProximityPrompt") then
				local at=(d.ActionText or ""):lower(); local nm=(d.Name or ""):lower(); local ot=(d.ObjectText or ""):lower()
				if at:find("investigate") or at:find("eat") or at:find("consume") or at:find("graze") or at:find("forage")
				 or at:find("feed") or at:find("pick") or at:find("harvest") or at:find("herb") or at:find("plant")
				 or nm:find("investigate") or nm:find("eat") or nm:find("food") or isPlantN(ot) then
					local p=d.Parent
					local part=(p and p:IsA("BasePart") and p) or (p and p:FindFirstChildWhichIsA("BasePart"))
					local m=(p and p:IsA("Model")) and p or (part and part:FindFirstAncestorWhichIsA("Model")) or p
					if m and part and not seen[m] then local dd=dist(me.Position,part.Position); if dd<=range then seen[m]=true; out[#out+1]={m,part,dd, prompt=d} end end
				end
			elseif d:IsA("Model") and d~=getMyModel() and not Players:GetPlayerFromCharacter(d) and not seen[d] then
				local n=d.Name:lower()
				if isFoodName(n) or n:find("corpse") or n:find("carcass") or n:find("remains") or isPlantN(n) then
					-- a plant model only counts as food if it actually has an eat prompt (skip decorative scenery)
					local pr=d:FindFirstChildWhichIsA("ProximityPrompt",true)
					local r=rootOf(d); if r and (pr or isFoodName(n) or n:find("corpse")) then local dd=dist(me.Position,r.Position); if dd<=range then seen[d]=true; out[#out+1]={d,r,dd, prompt=pr} end end
				end
			end
		end
		table.sort(out,function(a,b) return a[3]<b[3] end)
	end
	FARM.food={t=tick(), list=out}
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
			local dead=false; pcall(function() dead=(mdl:GetAttribute("DinoType") or mdl:GetAttribute("HintType") or mdl:GetAttribute("CreatedAt"))~=nil or isMeatName(mdl.Name) end)
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
	local marked=false; pcall(function() marked=(m:GetAttribute("DinoType") or m:GetAttribute("HintType") or m:GetAttribute("CreatedAt"))~=nil end)
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
-- teleport onto a corpse part (noclip + hold so it can't rubber-band; eat prompt fired)
-- MICRO-STEP LEGIT MOVE: the server validates position DELTAS -- one giant CFrame jump reads as impossible
-- speed and gets rejected (that is the rubberband). So we walk the server there in 20-stud hops: every hop is
-- a believable move, fired on the game's OWN unreliable move remote 3x per hop (that channel DROPS packets --
-- the repeats make sure one lands), with the local write alongside so your screen keeps up. localWrite=false
-- sends the server path only (used by the corpse TP, which snaps you locally first and holds).
local function MH_hopFire(goalCF)
	pcall(function()
		local re=RS:FindFirstChild("RemoteEvents"); re=re and re:FindFirstChild("ReplicaSignalUnreliable")
		local id=myReplicaId or (seenIds and seenIds[1])
		if re and id then for _=1,3 do re:FireServer(id, "CFrame", goalCF) end end
	end)
end
__gg.MH_hopFire=MH_hopFire   -- shared: the INF-Stam speed drive reports its position through this so the server never snaps you back
-- INSTANT TP (the fossil farm asked for teleport, NOT glide): snap there NOW, then beat the rubber-band by
-- (a) feeding the server the goal on its own move remote for ~1.2s and (b) re-asserting the goal locally only
-- if the server shoves you more than 6 studs (so it never freezes you when you're already there).
__gg.MH_snapTo=function(targetPos)
	__gg.MH_rescueMute = tick()+12   -- teleporting on purpose — the spawn rescue stays out of it
	local goal=CFrame.new(targetPos)
	local cc=getMyModel()
	pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) else local r=hrp(); if r then r.CFrame=goal end end end)
	local r=hrp(); if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero end) end
	task.spawn(function()
		local t0=tick()
		while tick()-t0<1.2 do
			MH_hopFire(goal)
			local rr=hrp()
			if rr and (rr.Position-targetPos).Magnitude>6 then pcall(function() rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero end) end
			task.wait(0.06)
		end
	end)
end
__gg.MH_hopMove=function(targetPos, localWrite)
	__gg.MH_rescueMute = tick()+12   -- teleporting on purpose — the spawn rescue stays out of it
	task.spawn(function()
		local r=hrp(); if not r then return end
		local from=r.Position
		local dist=(targetPos-from).Magnitude
		local hops=math.clamp(math.ceil(dist/20),1,400)
		for i=1,hops do
			local cf=CFrame.new(from:Lerp(targetPos, i/hops))
			MH_hopFire(cf)
			if localWrite~=false then
				local cc=getMyModel()
				pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(cf) else local rr=hrp(); if rr then rr.CFrame=cf end end end)
				local rr=hrp(); if rr then pcall(function() rr.AssemblyLinearVelocity=Vector3.zero end) end
			end
			task.wait(0.05)
		end
		for _=1,6 do MH_hopFire(CFrame.new(targetPos)); task.wait(0.08) end   -- settle: keep re-telling the server the final spot
	end)
end
local function tpToCorpse(part)
	if not (part and part.Parent) or carnBusy then return end
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
		local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances={
			getMyModel(), part, part.Parent,
			WS:FindFirstChild("Characters"), WS:FindFirstChild("DinosaurRagdolls"),
			WS:FindFirstChild("Bonepiles"), WS:FindFirstChild("Food"),
			ci and ci:FindFirstChild("CorpseSpawns"), ci and ci:FindFirstChild("LeftCharacters"),
		}
		rp.RespectCanCollide=true; rp.IgnoreWater=false
		local res=WS:Raycast(np+Vector3.new(0,60,0), Vector3.new(0,-6000,0), rp)
		if res then landY=res.Position.Y+3; foundGround=true end
	end)
	-- OUT-OF-MAP GUARD: only skip a corpse if it's an OBVIOUS void marker (parked way below the map). A missed
	-- ground ray alone must NOT skip it — that rejected EVERY corpse on this map ("next says none when it's 1/37").
	-- When the ray misses but the corpse is at a normal height, we just teleport to the corpse's own Y.
	if not foundGround and np.Y < -400 then carnBusy=false; return false end
	local cc=getMyModel(); local goal=CFrame.new(np.X, landY, np.Z)
		-- LEGIT MOVE: send the server a believable 20-stud-hop path to the corpse (remote-only -- you snap there
		-- locally below and the hold keeps you put while the server's copy walks over and accepts the position).
		if __gg.MH_hopMove then __gg.MH_hopMove(goal.Position, false) end
	local noclip={}; if cc then pcall(function() for _,dd in ipairs(cc:GetDescendants()) do if dd:IsA("BasePart") and dd.CanCollide then dd.CanCollide=false; noclip[#noclip+1]=dd end end end) end
	pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) else local r=hrp(); if r then r.CFrame=goal end end end)
	local r=hrp(); if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero end) end
	local bp; pcall(function() if r then bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(9e9,9e9,9e9); bp.P=3e4; bp.D=3000; bp.Position=Vector3.new(np.X,landY,np.Z); bp.Parent=r end end)
	-- ANTI-SNAPBACK (fix "teleport keeps sending me back"): the server rubber-bands you for a while after a hard set,
	-- so we HOLD you at the goal with BOTH a BodyPosition force AND a per-frame CFrame re-assert for ~2s. Long enough
	-- that the server accepts the new position instead of snapping you back, then it releases and you move freely.
	if __gg.MH_corpseHoldGoal ~= nil then end
	__gg.MH_corpseHoldGoal = goal   -- newest teleport wins if another fires mid-hold
	task.spawn(function()
		local t0=tick()
		while tick()-t0<2.0 and carnBusy and __gg.MH_corpseHoldGoal==goal do   -- ~2s hold beats the rubber-band
			local rr=hrp()
			if rr then pcall(function() rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero; rr.AssemblyAngularVelocity=Vector3.zero end) end
			if bp and bp.Parent~=r then pcall(function() local nr=hrp(); if nr then bp.Parent=nr end end) end
			RunService.Heartbeat:Wait()
		end
	end)
	pcall(function() local m=part:FindFirstAncestorWhichIsA("Model"); local prompt=(m and m:FindFirstChildWhichIsA("ProximityPrompt",true)) or part:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt then local od=prompt.MaxActivationDistance; prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.max(od or 8, 30); prompt.Enabled=true
			if fireprox then local oh=prompt.HoldDuration; prompt.HoldDuration=0; fireprox(prompt); prompt.HoldDuration=oh end
			pcall(function() prompt.MaxActivationDistance=od end)   -- restore native range so your hold-to-eat still works
		end end)
	-- (removed the holdKey(E) — pressing/holding E every teleport is what "kept clicking" and locked your controls)
	task.delay(2.1, function() for _,dd in ipairs(noclip) do pcall(function() dd.CanCollide=true end) end; pcall(function() if bp then bp:Destroy() end end); carnBusy=false end)
	return true
end
-- go to the NEXT corpse in the list, wrapping, SKIPPING void/out-of-map spots (tpToCorpse returns false for those)
-- until one actually lands you in the map; then ask YES/NO.
local function doNextCorpse()
	-- CLEAR THE HOLD LOCK FIRST (the premature-"no corpse" fix): the previous TP keeps carnBusy=true for ~2s,
	-- so a fast No-press made every tpToCorpse below bail instantly and the loop wrongly reported "none found".
	-- A deliberate next-corpse press cancels the old hold and always gets a fresh try.
	carnBusy=false; __gg.MH_corpseHoldGoal=nil
	corpseList=collectCorpses()   -- LIVE: re-scan the folder every press so the count is always current
	if #corpseList==0 then pcall(function() carnGui.Enabled=false end); notify("Corpse TP","No corpse / meat / bone found on the map right now."); return end
	if not carnOrigin then local r=hrp(); if r then carnOrigin=r.Position end end   -- remember where you were (for Teleport Back)
	local tries=0; local ok=false
	repeat
		corpseIdx = corpseIdx % #corpseList + 1; tries=tries+1
		local part=corpseList[corpseIdx]
		if part and part.Parent then ok = (tpToCorpse(part)==true) end   -- false = void/out-of-map → try the next one
		if not ok then carnBusy=false end   -- a failed try must not leave the lock set for the next corpse in the loop
	until ok or tries>#corpseList
	-- Only after EVERY corpse number has been tried and none landed do we say so.
	if not ok then corpseList={}; pcall(function() carnGui.Enabled=false end); notify("Corpse TP","Tried all "..tostring(tries).." corpse spots — none are in the map right now. Rescanning next press."); return end
	pcall(function() carnLabel.Text="Teleported to corpse "..corpseIdx.." / "..#corpseList.." - did it work?"; carnGui.Enabled=true end)
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
noBtn.MouseButton1Click:Connect(function() task.spawn(doNextCorpse) end)                        -- try a different one
__gg.MH_corpseBack = function()   -- "Teleport Back" button -> return to where you were
	local o=carnOrigin; if not o then notify("Corpse TP","No saved spot yet - use Carnivore Meat TP first."); return end
	-- KILL the corpse-TP hold first: tpToCorpse pins you at the corpse for ~2s via MH_corpseHoldGoal. If it's still
	-- running when you hit Teleport Back, it yanks you straight back to the corpse ("teleport back doesn't work").
	__gg.MH_corpseHoldGoal = nil
	carnBusy = false
	local cc=getMyModel(); local r=hrp()
	if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
	local goal=CFrame.new(o)
	local noclip={}; if cc then pcall(function() for _,dd in ipairs(cc:GetDescendants()) do if dd:IsA("BasePart") and dd.CanCollide then dd.CanCollide=false; noclip[#noclip+1]=dd end end end) end
	pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) elseif r then r.CFrame=goal end end)
	if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero end) end
	-- ANTI-SNAPBACK on the way home too: hold the origin with a BodyPosition + per-frame CFrame re-assert for ~1.6s so
	-- the server accepts the return instead of rubber-banding you back to the corpse.
	local bp; pcall(function() if r then bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(9e9,9e9,9e9); bp.P=3e4; bp.D=3000; bp.Position=o; bp.Parent=r end end)
	task.spawn(function()
		local t0=tick()
		while tick()-t0<1.6 do
			local rr=hrp()
			if rr then pcall(function() rr.CFrame=goal; rr.AssemblyLinearVelocity=Vector3.zero; rr.AssemblyAngularVelocity=Vector3.zero end) end
			RunService.Heartbeat:Wait()
		end
		pcall(function() if bp then bp:Destroy() end end)
	end)
	task.delay(1.7, function() for _,dd in ipairs(noclip) do pcall(function() dd.CanCollide=true end) end end)
	pcall(function() carnGui.Enabled=false end)
	notify("Corpse TP","Teleported back to where you were.")
end
-- TRIGGER: turning Carnivore Meat TP ON starts the cycle (teleport to a corpse + ask). Turning it OFF hides the popup.
task.spawn(function() local was=false while RUNNING do
	if CFG.CarnMeatTP and alive() and tick()-carnSpawnT>5 and tick()>=(__gg.MH_spawnGrace or 0) then   -- also wait out the spawn grace so it can't TP you into the void on load
		if not was then was=true; carnOrigin=nil; corpseList=collectCorpses(); corpseIdx=0; task.spawn(doNextCorpse) end
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
		if prompt then pcall(function() local od,oh=prompt.MaxActivationDistance,prompt.HoldDuration; prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.max(od or 8,30); prompt.HoldDuration=0; if fireprox then fireprox(prompt) end; prompt.MaxActivationDistance=od; prompt.HoldDuration=oh end) end   -- restore so YOUR hold-to-eat still works
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
		if prompt then pcall(function() local od,oh=prompt.MaxActivationDistance,prompt.HoldDuration; prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.max(od or 8,40); prompt.HoldDuration=0; if fireprox then fireprox(prompt) end; prompt.MaxActivationDistance=od; prompt.HoldDuration=oh end) end   -- restore so YOUR hold-to-eat still works
		pcall(fakeEat)   -- captured Bite remotes — fills the bar without pressing E
	end
	-- FULL → walk in a CIRCLE. REWORKED (was: W+D key holds — those only walked you diagonally in a straight line,
	-- and the fake key-holds could STICK after you turned Pro Food off, so you kept "circling" forever): now the
	-- circle is a rotating-heading velocity drive (the same proven write INF Stam / Speed Hack use) at a slow walk
	-- speed, reported to the server on its own move remote so it never snaps. Stopping is now a hard stop —
	-- stopCircle() zeroes the drive, releases any legacy keys, and runs the moment Pro Food turns off or you eat.
	local PWK = {W=Enum.KeyCode.W, A=Enum.KeyCode.A, S=Enum.KeyCode.S, D=Enum.KeyCode.D}
	PRO.held = PRO.held or {}
	local function releaseWASD()   -- unconditional key-ups: never trust the held-table to know a key stuck
		for k,kc in pairs(PWK) do PRO.held[k]=false; pcall(function() VIM:SendKeyEvent(false, kc, false, game) end) end
	end
	local function stopCircle()
		if not PRO.circling then return end
		PRO.circling=false
		releaseWASD()
		local r=hrp(); if r then pcall(function() r.AssemblyLinearVelocity=Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end) end
	end
	local function circle()   -- one STEP of the circle walk; call it repeatedly while food is full
		if not PRO.circling then PRO.circling=true; releaseWASD() end
		pcall(function() replicaAction("SetAction","Run",false) end); pcall(function() replicaAction("SetAction","Trot",false) end)
		local r=hrp(); if not r then return end
		local now=tick(); local dt=math.clamp(now-(PRO.stepT or now), 0, 0.6); PRO.stepT=now
		PRO.ang=((PRO.ang or 0) + dt*0.8) % (2*math.pi)   -- ~8s per lap; walk speed 8 → ≈10-stud circle
		local dir=Vector3.new(math.cos(PRO.ang), 0, math.sin(PRO.ang))
		pcall(function() r.AssemblyLinearVelocity=Vector3.new(dir.X*8, r.AssemblyLinearVelocity.Y, dir.Z*8) end)
		if __gg.MH_hopFire and now-(PRO.cfT or 0)>0.12 then PRO.cfT=now; __gg.MH_hopFire(r.CFrame) end   -- server follows = no snap
	end
	task.spawn(function() while RUNNING do
		if CFG.ProFood and alive() and tick()>=(__gg.MH_spawnGrace or 0) then
			if reachedAge() then stopCircle(); CFG.ProFood=false; if __gg.MH_setToggle then __gg.MH_setToggle("ProFood",false) end; pcall(function() notify("Pro Food","Reached "..tostring(CFG.ProFoodStopAge).." — growth stopped.") end)
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
						if r and (fd[2].Position - r.Position).Magnitude > 14 and __gg.MH_tpToCorpse then pcall(function() __gg.MH_tpToCorpse(fd[2]) end); task.wait(0.9) end
						eatAt(fd[2]); task.wait(0.4)
					else circle(); task.wait(0.1) end   -- nothing to eat anywhere → keep circling (still grows)
				end
			end
		else PRO.cur=nil; stopCircle(); task.wait(0.2) end   -- Pro Food OFF → hard-stop the circle NOW (keys + velocity)
	end end)
end
task.spawn(function() while RUNNING do
	-- ONLY runs UNTIL you have bitten once. After that, __gg.MH_lastEatCall is set and the pure Bite-spam loop
	-- below takes over — so INF Food stops firing prompts entirely, which is what was interfering with your manual
	-- E-hold. This block exists only to get that FIRST real bite (to capture the Bite remote) if you never eat yourself.
	if CFG.InfFood and alive() and not __gg.MH_lastEatCall then
		-- Get the first correct-diet bite so we can capture the Bite remote (herbivore→plants, carnivore→meat).
		local eHeld = false; pcall(function() eHeld = UIS:IsKeyDown(Enum.KeyCode.E) end)
		if not eHeld then
			fakeEat()   -- replay your last captured bite (fills bar); harmless, presses no keys
			local me=hrp(); local list=nearbyFood(1e9)   -- whole-map scan = eat from anywhere
			local edible = _G.MH_edible                  -- diet gate (set once the diet helpers load); nil-safe
			if me then for _,fd in ipairs(list) do
				local m,r,prompt=fd[1],fd[2],fd.prompt
				if not prompt and m then prompt=m:FindFirstChildWhichIsA("ProximityPrompt",true) end
				-- DIET FILTER: skip anything your dino should not eat (this is what keeps Comfort — and INF Stam — healthy)
				local dietOk = true
				if edible and m then local okc,res=pcall(function() return edible(m, prompt) end); if okc then dietOk=(res==true) end end
				if dietOk and prompt and r and r.Parent then
					-- nearest DIET-CORRECT food: eat it, then stop for this pass. NO "eat once then remember the id"
					-- cooldown (removed per request) — it just fires the correct food every pass so the bar keeps
					-- topping up. RE-CHECK the hold RIGHT before firing (fakeEat above yields ~0.36s); honor a rebound key.
					local stillHold=false
					pcall(function() stillHold = UIS:IsKeyDown(Enum.KeyCode.E)
						or (prompt.KeyboardKeyCode and prompt.KeyboardKeyCode~=Enum.KeyCode.Unknown and UIS:IsKeyDown(prompt.KeyboardKeyCode)) end)
					if not stillHold then
						local oh=prompt.HoldDuration; local od=prompt.MaxActivationDistance; local ol=prompt.RequiresLineOfSight
						pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.huge; prompt.HoldDuration=0 end)
						if fireprox then pcall(function() fireprox(prompt) end) end   -- remote eat: fire from anywhere, no key press
						pcall(function() prompt.HoldDuration=oh; prompt.MaxActivationDistance=od; prompt.RequiresLineOfSight=ol end)   -- restore so your hold-to-eat still works
					end
					break  -- one diet-correct eat per pass (no lag / no anti-cheat spam)
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
		local rs=getReplicaSignal()
		if rs then
			-- Fire EVERY different Bite you have eaten this session ONCE per pass. More foods eaten = more Bite calls =
			-- faster growth. (Was firing the whole list x3 per pass = ~200 remotes/sec = network lag / FPS drop.)
			local list=__gg.MH_biteCalls
			if type(list)=="table" and #list>0 then
				for _,ec in ipairs(list) do if type(ec)=="table" and ec.n and ec.n>=2 then pcall(function() rs:FireServer(table.unpack(ec,1,ec.n)) end) end end
			else
				local ec=__gg.MH_lastEatCall
				if type(ec)=="table" and ec.n and ec.n>=2 then pcall(function() rs:FireServer(table.unpack(ec,1,ec.n)) end) end
			end
		end
		task.wait(0.3)
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
	if CFG.AntiFracture then clearStatus({"fracture","fractured","headinjury","concussion","hairfracture","skull"},{"fracture","fractured","headinjury","concussion","brokenhead","hairfracture","skull"}); for _,e in ipairs(Lighting:GetDescendants()) do if e:IsA("BlurEffect") then pcall(function() e.Enabled=false; e.Size=0 end) end end pcall(function() local cam=WS.CurrentCamera; if cam then for _,e in ipairs(cam:GetDescendants()) do if e:IsA("BlurEffect") then e.Enabled=false; e.Size=0 end end end end); local pg=LP:FindFirstChild("PlayerGui"); if pg then for _,gg in ipairs(pg:GetDescendants()) do if (gg:IsA("Frame") or gg:IsA("ImageLabel") or gg:IsA("CanvasGroup")) then local n=gg.Name:lower(); if n:find("blur") or n:find("fracture") or n:find("concus") or n:find("daze") or n:find("vision") or n:find("injur") then pcall(function() gg.Visible=false end) end end end end end
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
			-- swing once (click + SoundRemote), wait a frame for the server's attack window, then fire the hit reports.
			local mine=getMyModel(); local targs={}; local seen={}
			local function consider(m)
				if #targs>=8 or not (m and m:IsA("Model") and m~=mine) or seen[m] then return end
				seen[m]=true
				local h=m:FindFirstChildOfClass("Humanoid"); if h and h.Health<=0 then return end
				local hb=getHitbox(m); if hb and dist(me.Position,hb.Position)<=CFG.DamageRange then targs[#targs+1]=m end
			end
			local chars=WS:FindFirstChild("Characters"); if chars then for _,m in ipairs(chars:GetChildren()) do consider(m) end end
			for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters"}) do
				if #targs>=8 then break end local f=WS:FindFirstChild(nm); if f then for _,m in ipairs(f:GetChildren()) do consider(m) end end
			end
			if #targs==0 and typeof(getnilinstances)=="function" then
				pcall(function() local c=0; for _,v in next, getnilinstances() do c+=1; if c>4000 or #targs>=8 then break end
					if typeof(v)=="Instance" and v:IsA("Model") and (v:FindFirstChild("Hitbox") or v:FindFirstChild("HitBox")) then consider(v) end
				end end)
			end
			-- ONLY swing + fire when there's actually something in range (this is the "stop attacking nothing" fix)
			if #targs>0 then
				pcall(clickMouse)
				local sr=getSoundRemote(); if sr then pcall(function() sr:FireServer("PVP","Attacks/Primary",false,nil,1) end) end
				RunService.Heartbeat:Wait()
				for _,m in ipairs(targs) do fireAttack(m, true) end
			end
		end
		task.wait(1/math.max(1,CFG.DamageRate))
	else task.wait(0.15) end
end end)
-- CLICK TO DAMAGE (fix: "can't click/damage" with Hitbox on) — PE damage fires through the captured Attack remote +
-- SoundRemote, which were ONLY wired to the Always-Damage auto-loop. So a plain click never fired them = no damage.
-- Now, while HITBOX is on, a real M1 click (not on the menu) fires the SAME proven swing→window→hit sequence at every
-- enemy inside the expanded reach, so clicking actually deals damage. Debounced so a click can't spam-report.
do local lastClickDmg=0; local mouse=LP:GetMouse()
conn(UIS.InputBegan:Connect(function(input, gp)
	if gp then return end                                            -- click landed on the GUI = ignore (don't attack)
	if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
	if not (CFG.HitboxExpand and alive()) then return end            -- only when Hitbox is on
	if tick()-lastClickDmg < 0.12 then return end; lastClickDmg=tick()
	local me=hrp(); if not me then return end
	local rng=math.max(tonumber(CFG.DamageRange) or 120, tonumber(CFG.HitboxSize) or 50)
	-- THE BONE YOU CLICKED: mouse.Target is the CanQuery Hitbox bone part under the cursor (the expander sets those
	-- CanQuery=true). We hit that enemy on that exact bone first, then AoE the rest at their auto bone.
	local clicked=mouse.Target
	local clickedModel=clicked and clicked:FindFirstAncestorWhichIsA("Model")
	task.spawn(function()
		local sr=getSoundRemote(); if sr then pcall(function() sr:FireServer("PVP","Attacks/Primary",false,nil,1) end) end
		RunService.Heartbeat:Wait()                                  -- let the attack window open before the hit reports
		local mine=getMyModel(); local n=0; local seen={}
		-- clicked enemy FIRST, aiming the exact bone you clicked
		if clickedModel and clickedModel:IsA("Model") and clickedModel~=mine and getHitbox(clickedModel) then
			seen[clickedModel]=true; fireAttack(clickedModel, true, clicked); n+=1
		end
		local function hit(m)
			if n>=8 or not (m and m:IsA("Model") and m~=mine) or seen[m] then return end
			local hb=getHitbox(m); if hb and dist(me.Position,hb.Position)<=rng then seen[m]=true; fireAttack(m, true); n+=1 end
		end
		for _,m in ipairs(charModels()) do if n>=8 then break end hit(m) end   -- includes CharacterIgnore.LeftCharacters
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
		-- KEEP-ALIVE while lifted: the death was fall damage + the meters draining while you hang up high. Turn on
		-- the anti-death set so nothing can kill you AFK: Anti-Fall (no fall damage), and INF Food/Water/Stam/Oxygen
		-- + Auto-Heal so every meter stays full. We also zero fall reports and pin health each frame.
		CFG.InfFood=true; CFG.InfWater=true; CFG.InfStam=true; CFG.InfOxygen=true
		CFG.AntiFall=true; CFG.AutoHealBlood=true
		local r=hrp(); if not r then return end
		if not afkAnchor then afkAnchor = r.Position + Vector3.new(0, 300, 0) end   -- lift once (gentler 300 studs)
		pcall(function() r.CFrame = CFrame.new(afkAnchor); r.AssemblyLinearVelocity = Vector3.new(0,0,0); r.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
		-- hard health pin + fall-immunity flag so the server never applies the drop damage
		pcall(function()
			local h=hum(); if h then h.Health=h.MaxHealth end
			local stats,maxs=csStats(); if stats and maxs then for _,k in ipairs({"Health","HP"}) do if stats[k]~=nil and maxs[k] then stats[k]=maxs[k] end end end
			if CharacterState then CharacterState.FallDamageImmunity=true end
		end)
	end))
end

-- HITBOX EXPANDER (enemy creatures + players ONLY — same targeting as the proven standalone test build:
-- workspace.Characters children, skip YOUR model, both "HitBox"/"Hitbox" spellings, same property set)
hbTouched={}
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
	if not hbTouched[p] then hbTouched[p]={p.Size,p.Transparency,p.CanCollide,p.Material,p.Massless,p.CanTouch,p.CanQuery,p.Color} end
	pcall(function()
		p.Massless   = true
		p.CanCollide = false
		p.CanQuery   = true     -- raycast / M1 hit checks read it
		p.CanTouch   = false    -- the working build uses FALSE (this is what made it land)
		if p.Size.X ~= CFG.HitboxSize then p.Size = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize) end
		if CFG.HitboxVisible then p.Transparency=math.clamp(1-((tonumber(CFG.HitboxOpacity) or 40)/100),0,1); p.Material=Enum.Material.ForceField; local c=CFG.HitboxColor or {}; p.Color=Color3.fromRGB(c.r or 255,c.g or 50,c.b or 50)   -- Opacity slider drives how much you see (0=invisible, 100=solid)
		else p.Transparency=1 end
	end)
end
local function restorePart(p) local o=hbTouched[p]; if o and p and p.Parent then pcall(function() p.Size=o[1]; p.Transparency=o[2]; p.CanCollide=o[3]; p.Material=o[4]; p.Massless=o[5]; if o[6]~=nil then p.CanTouch=o[6] end if o[7]~=nil then p.CanQuery=o[7] end if o[8]~=nil then p.Color=o[8] end end) end hbTouched[p]=nil end
-- Expand every BasePart inside the enemy's Hitbox/HitBox container (the container part itself + all per-bone parts),
-- filtered by the selected bone. ENEMIES ONLY (never our own model — that would block our own clicks/movement).
local function expandModel(m)
	if not m then return end
	local grewAny=false
	for _,n in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do
		local inst=m:FindFirstChild(n)
		if inst then
			if inst:IsA("BasePart") then
				if boneMatch(inst.Name) or CFG.HitboxBone=="All" or CFG.HitboxBone=="Body" then expandPart(inst); grewAny=true
				elseif hbTouched[inst] then restorePart(inst) end  -- bone switched away → restore it (no double boxes)
			else
				for _,d in ipairs(inst:GetDescendants()) do
					if d:IsA("BasePart") then
						if boneMatch(d.Name) then expandPart(d); grewAny=true
						elseif hbTouched[d] then restorePart(d) end  -- restore parts that no longer match the selected bone
					end
				end
			end
		end
	end
	-- FALLBACK — WORKS ON EVERY DINO: some dinos have no "Hitbox" container (or an oddly-named one), so nothing grew
	-- above. Grow the model's OWN parts too — the MeshModel bones' render parts, the HumanoidRootPart, and any direct
	-- BasePart — filtered by the selected bone. This is why "hitbox didn't work on some dinos": they had no Hitbox box.
	if not grewAny then
		local hrp2=m:FindFirstChild("HumanoidRootPart"); if hrp2 and hrp2:IsA("BasePart") and (CFG.HitboxBone=="All" or CFG.HitboxBone=="Body") then expandPart(hrp2) end
		local cnt=0
		for _,d in ipairs(m:GetDescendants()) do
			cnt+=1; if cnt>400 then break end
			if d:IsA("BasePart") and d~=hrp2 and boneMatch(d.Name) then expandPart(d)
			elseif d:IsA("BasePart") and hbTouched[d] and not boneMatch(d.Name) then restorePart(d) end
		end
	end
end
-- (Bone Protection NO LONGER shrinks your hitbox — that broke your M1. It now clears the chosen bone's break/
-- fracture STATUS via the antiInjurySweep loop above. The expander below only touches ENEMY hitboxes.)
-- Re-apply enemy hitbox expansion every 0.1s so the server can't revert. ENEMIES ONLY — the own-model check is
-- now BULLETPROOF ("I still see my hitbox" fix): name match (the test build's check), LP.Character, the Player
-- object, AND the model your own body part actually lives in (covers sandbox dinos that aren't named after you).
-- On top of that, any of YOUR parts that ever got touched are restored on the spot, every tick.
task.spawn(function() local cleared=true while RUNNING do
	if CFG.HitboxExpand and alive() then
		cleared=false
		local mine=getMyModel()
		local myR=hrp()
		local function isMine(m)
			if m==mine or m.Name==LP.Name then return true end
			if LP.Character and (m==LP.Character or m:IsDescendantOf(LP.Character) or LP.Character:IsDescendantOf(m)) then return true end
			if Players:GetPlayerFromCharacter(m)==LP then return true end
			if myR and myR:IsDescendantOf(m) then return true end
			return false
		end
		-- CAP + NEARBY-ONLY (crash fix for weaker executors like Wave): expanding EVERY model incl the whole SpawnedAI
		-- fish/AI folder into big visible ForceField boxes every tick overloaded the renderer = crash. Now: at most 24
		-- NEARBY enemies, and the giant AI folder is skipped.
		local me=hrp(); local ecount=0; local MAXM=24
		local reach=math.max(tonumber(CFG.DamageRange) or 120, tonumber(CFG.HitboxSize) or 50, 140)
		local function doFolder(folder) if folder and me then for _,m in ipairs(folder:GetChildren()) do
			if ecount>=MAXM then break end
			if m:IsA("Model") and not isMine(m) then
				local r=getHitbox(m) or rootOf(m)
				if r and dist(me.Position, r.Position)<=reach then expandModel(m); ecount+=1 end
			end
		end end end
		doFolder(WS:FindFirstChild("Characters"))
		for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs"}) do if ecount<MAXM then doFolder(WS:FindFirstChild(nm)) end end
		-- NEVER your own hitbox: if any of OUR parts ever made it into the touched table, restore them right now.
		for p in pairs(hbTouched) do
			if p and p.Parent and ((mine and p:IsDescendantOf(mine)) or (LP.Character and p:IsDescendantOf(LP.Character)) or p:FindFirstAncestor(LP.Name)) then restorePart(p) end
		end
		task.wait(0.1)
	else
		if not cleared then for p in pairs(hbTouched) do restorePart(p) end cleared=true end
		task.wait(0.25)
	end
end end)

-- AIMBOT + SILENT AIM + LOCK ON (camera assist only — NO metamethod hook; targets the BODY)
local aimTarget, aimRoot, aimPart
task.spawn(function()
	while RUNNING do
		task.wait(0.15)
		if (CFG.Aimbot or CFG.SilentAim or CFG.LockOn) and alive() then
			local me=hrp(); local mine=getMyModel(); local rng=CFG.FarmPlayerRange*3
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
			if aimTarget and (not aimPart or not aimPart.Parent) then aimPart=getAimPart(aimTarget) end
		else aimTarget, aimRoot, aimPart = nil, nil, nil end
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
task.spawn(function() while RUNNING do if CFG.SilentAim and alive() then local t=aimTarget or nearestTarget(CFG.FarmPlayerRange*3, true); if t then local sr=getSoundRemote(); if sr then pcall(function() sr:FireServer("PVP","Attacks/Primary",false,nil,1) end) end; fireAttack(t, true) end; task.wait(1/math.max(1,CFG.DamageRate)) else task.wait(0.15) end end end)
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
-- AUTO FARM — TELEPORT MODE (default, you asked for it back): saves your ORIGIN when you toggle it ON, TPs onto
-- the nearest un-collected node, fires its prompt (the executor simulates the FULL hold), waits for the node to
-- vanish, then moves to the next — ONE node at a time = no lag. Toggle OFF and you TP straight back to your
-- origin. Fall immunity is forced the whole time. Heads up: CFrame teleports CAN trip the anti-cheat (267) — if
-- you get kicked, turn "Teleport Farm" OFF to use the stand-still mode (fires prompts remotely, zero movement).
-- LAG FIXES in both modes: the dig-remote search runs ONCE ever (re-walking ReplicatedStorage every pass when the
-- remote doesn't exist was the big farm lag), node list cached 2s, hard scan caps.
local function runFarm(enabledKey, kind, rangeKey)
	task.spawn(function()
		local pending={}
		local origin, wasOn = nil, false
		while RUNNING do
			if CFG[enabledKey] and alive() then
				if not wasOn then wasOn=true; local r0=hrp(); origin=r0 and r0.CFrame end
				for part,holder in pairs(pending) do if not (part and part.Parent) then FARM.count[kind]=(FARM.count[kind] or 0)+1; pending[part]=nil end end
				if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
				-- dig remote: search ONCE (negative-cached) — this was the lag.
				if not FARM.digSearched then FARM.digSearched=true; FARM.dig=findRemote({"collectfossil","collectgem","startcollection","excavat","harvest"}) end
				local list=getNodes(kind, 1e9)
				if CFG.FarmTeleport then
					-- pick the nearest un-tried node, TP to it, collect it, wait for it to vanish
					local nd
					for _,cand in ipairs(list) do
						local holder,part=cand[1],cand[2]
						if part and part.Parent then local t=FARM.tried[part]; if not t or tick()-t>15 then nd=cand; break end end
					end
					if nd then
						local holder,part=nd[1],nd[2]
						FARM.tried[part]=tick()
						do
							-- FOSSILS = INSTANT TELEPORT (you asked: "it needs to teleport, not glide"). MH_snapTo snaps you
							-- straight onto the node and beats the rubber-band by feeding the server the goal on its own move
							-- remote + re-asserting only if you get shoved — no slow walk between fossils. GEMS keep the glide
							-- (their 12s channel doesn't care about a slower approach, and it's proven to stick).
							local goalPos=part.Position+Vector3.new(0,1.5,0)
							if kind=="fossil" and __gg.MH_snapTo then
								__gg.MH_snapTo(goalPos)
								task.wait(0.1)
							elseif __gg.MH_hopMove then
								__gg.MH_hopMove(goalPos, true)
								local t0=tick()
								while tick()-t0<2.2 do local r=hrp(); if r and (r.Position-goalPos).Magnitude<8 then break end; task.wait(0.05) end
							else
								pcall(function() local cc=getMyModel(); if cc and cc.PrimaryPart then cc:PivotTo(CFrame.new(goalPos)) else local r=hrp(); if r then r.CFrame=CFrame.new(goalPos) end end end)
							end
						end
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
						while CFG[enabledKey] and tick()-t0<hold+2 and holder.Parent and part.Parent and not done do task.wait(0.15) end
						if not eManual then pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end
						if tconn then pcall(function() tconn:Disconnect() end) end
						if prompt and fireprox then pcall(function() fireprox(prompt) end) end   -- backup: complete it now
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
						if not CFG[enabledKey] then break end
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
					wasOn=false
					-- TP back to where you were when you turned the farm on
					if origin then pcall(function() local cc=getMyModel(); if cc and cc.PrimaryPart then cc:PivotTo(origin) else local r=hrp(); if r then r.CFrame=origin end end end); origin=nil
						local r0=hrp(); if r0 then pcall(function() r0.AssemblyLinearVelocity=Vector3.zero end) end
					end
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
				if lc:find("meat",1,true) or lc:find("organ",1,true) or lc:find("fish",1,true) or lc:find("bone",1,true) or lc:find("egg",1,true) or lc:find("insect",1,true) then carn=true else herb=true end
			end
			out=(carn and herb and "Omnivore") or (carn and "Carnivore") or (herb and "Herbivore") or nil
		end
	end)
	_spDietCache[species]=out or false
	return out
end
-- OUR OWN diet (cached): the game's GetDiet module first, our species' Diet.Categories second, Omnivore last.
local _myDietCache
local function myDiet()
	if _myDietCache then return _myDietCache end
	local species
	pcall(function()
		if CharacterState and CharacterState.Replica and CharacterState.Replica.Tags then species=CharacterState.Replica.Tags.Character end
		if not species then local cc=getMyModel(); species=cc and (cc:GetAttribute("Type") or cc:GetAttribute("Character")) end
	end)
	pcall(function()
		local gd=require(RS.Modules.Diet.GetDiet)
		if gd and species then local d=gd(species)
			if type(d)=="string" then local lc=d:lower()
				if lc:find("herb",1,true) then _myDietCache="Herbivore" elseif lc:find("carn",1,true) then _myDietCache="Carnivore" elseif lc:find("omni",1,true) then _myDietCache="Omnivore" end
			end
		end
	end)
	if not _myDietCache and species then _myDietCache=speciesDiet(tostring(species)) end
	return _myDietCache or "Omnivore"
end
-- classify a food item: corpse/meat vs plant (name + PE's corpse markers + the prompt's "Investigate" action)
local function isCorpseFood(m, prompt)
	local nm=tostring(m and m.Name or ""):lower()
	if nm:find("corpse") or nm:find("carcass") or nm:find("remains") or nm:find("carrion") or nm:find("dead") or nm:find("meat") then return true end
	if m and m.GetAttribute then local ok,a=pcall(function() return m:GetAttribute("DinoType") or m:GetAttribute("HintType") or m:GetAttribute("CreatedAt") end); if ok and a then return true end end
	if prompt then local at=(prompt.ActionText or ""):lower(); if at:find("investigate") or at:find("examine") then return true end end
	return false
end
-- diet gate: Herbivore eats ONLY plants, Carnivore ONLY corpses/meat, Omnivore both
local function edibleFor(diet, corpse)
	if diet=="Herbivore" then return not corpse
	elseif diet=="Carnivore" then return corpse and true or false
	else return true end
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
				BOT.prevF,BOT.prevW,BOT.prevS = CFG.InfFood,CFG.InfWater,CFG.InfStam
				CFG.InfFood=true; CFG.InfWater=true; CFG.InfStam=true   -- meter insurance while the bot plays
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
			-- bot off / dead → clean shutdown: wake up, stop moving, restore the user's own INF toggles
			if BOT.prevF~=nil then
				CFG.InfFood,CFG.InfWater,CFG.InfStam = BOT.prevF,BOT.prevW,BOT.prevS
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
-- Teleport to the current target. Resolves position LIVE from any part — never needs a pre-loaded profile.
-- HARD TELEPORT = THE EXACT FOSSIL-FARM METHOD (MH_snapTo): PivotTo the goal, zero velocity, then for ~1.2s feed
-- the server the goal on its OWN move remote and re-assert locally only if it shoves you >6 studs. This is the
-- teleport that already works for Auto Farm Fossil — so Target uses it verbatim now, and it "sticks" the same way.
local function hardTeleportTo(pos, holdSecs)
	if not pos then return false end
	if __gg.MH_snapTo then __gg.MH_snapTo(pos)
	else
		-- fallback if the fossil snapper isn't loaded yet
		if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
		local cc=getMyModel(); local root = cc and (cc.PrimaryPart or cc:FindFirstChild("HumanoidRootPart")) or hrp()
		if root then pcall(function() root.CFrame=CFrame.new(pos); root.AssemblyLinearVelocity=Vector3.zero end) end
	end
	if holdSecs then task.wait(holdSecs) end
	return true
end
__gg.MH_hardTeleportTo = hardTeleportTo

local function targetTeleport(holdSecs)
	local T = __gg.MH_Target; if not T.plr then return false end
	local r, model = targetLivePart(T.plr)
	if model then T.model = model end
	if not r then return false end
	return hardTeleportTo(r.Position + Vector3.new(0, 6, 0), holdSecs)
end
__gg.MH_targetTeleport = targetTeleport

-- ATTACK ONCE + RETURN: DIRECT pivots (NOT MH_snapTo — its 1.2s settle loop would fight the return trip). Save
-- your spot, pivot onto them, land the captured attack, pivot back.
local function targetAttackAndReturn()
	local T = __gg.MH_Target; if not T.plr then return false, "no target" end
	local r, model = targetLivePart(T.plr)
	if model then T.model = model end
	if not (r and model and model.Parent) then return false, "not loaded" end
	if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
	__gg.MH_rescueMute = tick()+3
	local function pivotTo(pos)
		local cc=getMyModel(); local root=cc and (cc.PrimaryPart or cc:FindFirstChild("HumanoidRootPart")) or hrp()
		if root then pcall(function() root.CFrame=CFrame.new(pos); root.AssemblyLinearVelocity=Vector3.zero end) end
	end
	local myBack
	do local cc=getMyModel(); local root=cc and (cc.PrimaryPart or cc:FindFirstChild("HumanoidRootPart")) or hrp(); if root then myBack=root.Position end end
	pivotTo(r.Position + Vector3.new(0, 5, 0))   -- onto them
	task.wait(0.06)
	if _G.MH_attack then pcall(function() _G.MH_attack(model) end) end
	task.wait(0.1)
	if myBack then pivotTo(myBack) end            -- back to your spot
	return true
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
			if root then pcall(function() root.CFrame = r.CFrame * CFrame.new(0, 4, 6); root.AssemblyLinearVelocity=Vector3.zero end) end
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
	lines[#lines+1]="MyID: "..tostring(myReplicaId or seenIds[1] or "nil (move/look around)")
	lines[#lines+1]="Sound: "..(getSoundRemote() and "found" or "MISSING")
	local tg=nearestTarget(300,true); lines[#lines+1]="Target: "..(tg and tg.Name or "none")
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
		local ok=pcall(function()
			local res=game:HttpGetAsync("https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?sortOrder=Asc&limit=100")
			local data=HttpService:JSONDecode(res)
			for _,srv in ipairs(data.data or {}) do if srv.id~=game.JobId and (tonumber(srv.playing) or 0)<(tonumber(srv.maxPlayers) or 100) then TeleportSvc:TeleportToPlaceInstance(game.PlaceId, srv.id, LP); return true end end
			error("no server")
		end)
		if not ok then pcall(function() TeleportSvc:Teleport(game.PlaceId, LP) end) end
	end
	local function warnStaff(name, tag)
		if STF.stayed or STF.shown then return end; STF.shown=true
		local t=tostring(tag):gsub("^%l",string.upper)
		pcall(function() ttl.Text=tostring(name).." ("..t..") is in this server.\nServer hop, rejoin, or stay?"; sg.Enabled=true end)
		pcall(function() notify("Staff Detected", tostring(name).." ("..t..") is in the server.") end)
	end
	bHop.MouseButton1Click:Connect(function() sg.Enabled=false; hop() end)
	bJoin.MouseButton1Click:Connect(function() sg.Enabled=false; pcall(function() TeleportSvc:Teleport(game.PlaceId, LP) end) end)
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
local function toggleKey(key) CFG[key]=not CFG[key]; local ref=toggleRefs[key]; if ref then tw(ref[1],{BackgroundColor3=CFG[key] and T.On or T.Off}); tw(ref[2],{Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)}) end saveCfg() end
conn(UIS.InputBegan:Connect(function(input, gp)
	if capturing then return end
	if tick()-bindGuard < 0.25 then return end
	if input.UserInputType~=Enum.UserInputType.Keyboard then return end
	local kn = input.KeyCode.Name
	local uiKey = CFG.Keybinds["UIKey"] or CFG.UIKey or "RightShift"
	if kn==uiKey then SG.Enabled=not SG.Enabled; if SG.Enabled and not USE_FLUENT then task.defer(clampWindow) end; return end  -- SG.Enabled mirrors menu-open for the aim/autoclick guards (Fluent handles its own RightShift minimize)
	if gp then return end
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
	task.spawn(function() task.wait(1.5); for _=1,10 do if not RUNNING then break end if CFG.InfFood and alive() then fakeEat() end if CFG.InfWater and alive() then fakeDrink() end task.wait(0.18) end end)
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
notify("Dream Hub", "Prior Extinction loaded (everything OFF) — RightShift to toggle.")
print("[Dream Hub · Prior Extinction v6.1] Loaded — enemy-only hitbox (never yours), fixed restore camera+controls, BodyVelocity walk-on-water/anti-drown, server-side INF stam, food ESP highlights corpses, teleport farm, anti-injury report-block")
