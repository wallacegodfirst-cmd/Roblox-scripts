--[[  Dream Hub · Prior Extinction  ]]

print("[Dream Hub PE] script fetched OK - booting")   -- if you see THIS in F9 but no menu, send the red error line under it
local __gg = (typeof(getgenv)=="function") and getgenv() or _G
if __gg.__PRIOR_EXT_HUB then pcall(__gg.__PRIOR_EXT_HUB) end
__gg.__PRIOR_EXT_HUB = nil

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
	Fly=false, FlySpeed=80, SpeedHack=false, SpeedVal=70, RunSpeed=30, Noclip=false, Invis=false,
	InfJump=false, BypassTP=true,
	InfFood=false, InfWater=false, InfStam=false, InfOxygen=false,
	AntiDrown=true, AntiFracture=true, AntiBleed=true, WalkWater=false, AutoClean=false,
	SaveDino=false, SaveHP=30, NoSleep=true,
	AutoFarmPlayer=false, FarmPlayerRange=120, AutoFarmFossil=false, FarmFossilRange=1000000,
	ESPPlayers=false, ESPCorpses=false, FoodESP=false, FishESP=false, GemESP=false, ESPRange=900, ESPColor="Default",
	AlertEnabled=false, AlertDino="", AlertRange=350, CarnMeatTP=false,
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

local FILE = "PriorExtinction_Config.json"
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
	"ESPPlayers","ESPCorpses","FoodESP","FishESP","GemESP","AlertEnabled","CarnMeatTP","FullBright","NightVision","NoDarkWater","WaterClear","NoClouds","AlwaysDamage","NoGrabLimit",
	"Float","GodMode","InfLight","UnlockFOV","InfZoom","AntiDrown","WalkWater","AutoClean","AntiFracture","AntiBleed","AntiFall","Invis",
	"AntiBreakHead","AntiBreakNeck","AntiBreakLeg","AntiBreakTail","AntiBreakTorso","NoSleep","AntiAFK","UnlockMouse","__SpyOn",
	"AutoClick","AutoEatFood","DebugPanel","LogRemotes","BypassTP","SafeTP",
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
local FOOD_KEYWORDS = {
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
local FISH_KEYWORDS = { "lepisosteus","onchopristis","acipenser","concavotectum","bawitius","mawsonia","gar","sturgeon","coelacanth","sawfish","bichir" }
local function isFishName(n)
	n = n:lower()
	for _,k in ipairs(FISH_KEYWORDS) do if n:find(k,1,true) then return true end end
	return false
end

-- ═══ SKIN DATABASE (fallback name list; live list comes from Shared.SkinData) ═══
local SKINS = {
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
local DINO_NAMES = {}
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
local myReplicaId = nil
local seenIds = {}
local seenSet = {}
local function noteReplicaId(id)
	if typeof(id)=="number" and not seenSet[id] then seenSet[id]=true; seenIds[#seenIds+1]=id end
	myReplicaId = id
end
local hookInstalled=false
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
						-- INF Stam: drop the secondary-attack / right-click registration that drains stamina.
						if CFG.InfStam and action=="RegisterAttack" and typeof(a[3])=="string" and string.find(a[3],"Secondary",1,true) then
							return
						end
						-- INF Stam: DO NOT swallow the Sprint action (that STOPPED you sprinting = the "slow" bug). Let sprint
						-- run normally; we just block the stamina DRAIN report below so it never drops while you sprint.
						-- REWRITE stamina SetProperty to max so the server always sees a full bar.
						-- Previously this swallowed the call entirely, which also blocked our own
						-- refill fires at line ~1615 → server never got told stam was full = no drain fix.
						if CFG.InfStam and action=="SetProperty" and typeof(a[3])=="string" then local lp=a[3]:lower()
							if lp:find("stam",1,true) or lp=="energy" or lp=="endurance" or lp:find("endur",1,true) then
								if typeof(a[4])=="number" then
									-- track the highest seen value per property name (= the real max when bar is full)
									__gg.MH_max = __gg.MH_max or {}
									local pk = a[3]
									if a[4] > 0 and (not __gg.MH_max[pk] or a[4] > __gg.MH_max[pk]) then __gg.MH_max[pk] = a[4] end
									a[4] = __gg.MH_max[pk] or 100   -- rewrite the drop to the tracked max
								end
								return oldNC(self, table.unpack(a, 1, a.n))   -- fire with max value (not swallowed)
							end
						end
						-- ANTI-INJURY (report-block): injuries replicate the same way stamina does — the CLIENT reports
						-- them to the server. While your antis are on, we SWALLOW any report that would tell the server
						-- you fractured / bled / broke a bone — the injury never lands server-side. THIS is what makes
						-- Anti Fractured + Bone Protection actually stick (the local sweep alone only hid it client-side).
						if action=="SetProperty" and typeof(a[3])=="string" then local lp=a[3]:lower()
							local blockInj=false
							if (CFG.AntiFracture or CFG.BoneProtect) and (lp:find("fractur",1,true) or lp:find("concuss",1,true)) then blockInj=true end
							if CFG.AntiBleed and (lp:find("bleed",1,true) or lp:find("hemorrhage",1,true) or lp:find("wound",1,true)) then blockInj=true end
							if (CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso)
							and (lp:find("brok",1,true) or lp:find("break",1,true) or lp:find("sever",1,true) or lp:find("dislocat",1,true)) then blockInj=true end
							if blockInj then local v=a[4]; if v==true or (typeof(v)=="number" and v~=0) or typeof(v)=="table" then return end end
						end
						if action=="SetAction" and typeof(a[3])=="string" and a[4]==true then local lp=a[3]:lower()
							if (CFG.AntiBleed and lp:find("bleed",1,true))
							or ((CFG.AntiFracture or CFG.BoneProtect) and (lp:find("fractur",1,true) or lp:find("concuss",1,true)))
							or ((CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso) and (lp:find("brok",1,true) or lp:find("limp",1,true))) then return end
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
local SPAWN_BRIDGE_ID = "w+\179/\215s@\135\149\210;\129\019\145lV"
local RCACHE = {}  -- consolidated remote-instance cache (bridge / sig / sound) — one local instead of three
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
	local ok = pcall(function() b:FireServer(pp) end)
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
setHeadAngles = function(pitch, yaw) return replicaFire("SetProperty", "HeadAngles", {pitch, yaw}) end
local function setReplicaProp(prop, value) return replicaFire("SetProperty", prop, value) end
local function replicaAction(...) return replicaFire(...) end
-- WATER: per-MAP water-source IDs the user captured (each land's Sip uses a fixed id). We fire Sip to ALL of
-- them every tick — the current map's id always lands, so INF Water now works on EVERY land, anywhere (no
-- need to stand at water / capture an id first). Cretaceous Lowland 3028 / Archipelago 3251 / Jurassic 2910 /
-- Cretaceous Upland 2195. The current land is auto-detected (see currentLand) for the debug panel.
local WATER_IDS = { ["Cretaceous Lowland"]=3028, ["Cretaceous Archipelago"]=3251, ["Jurassic"]=2910, ["Cretaceous Upland"]=2195 }
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
local EAT_BUFFER = "\027\206\000\000\001"
local function fakeEat()
	local rs=getReplicaSignal(); if not rs then return end
	replicaFire("SetAction","Consuming",true)              -- dino: start eating
	-- ID-FREE: fire the eat Bite to MANY source ids so the right one always lands, no matter the land:
	--   (1) the LIVE-captured eat (real source id + real buffer the game last sent), (2) every per-land water/source
	--   id, (3) every replica id the hook has seen. The captured buffer is preferred; falls back to the known buffer.
	local cap = __gg.MH_eat
	local buf = (type(cap)=="table" and cap.buf~=nil) and cap.buf or __gg.MH_eatBuf or EAT_BUFFER
	if type(buf)=="string" and buffer and buffer.fromstring then pcall(function() buf = buffer.fromstring(buf) end) end
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
local ATK_GROUPS = {
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
	local hb=model:FindFirstChild("Hitbox"); if hb then local p=hb:FindFirstChild(name); if p then return p end end
	local mm=model:FindFirstChild("MeshModel"); if mm then local b=mm:FindFirstChild(name, true); if b then return b end end
	return model:FindFirstChild(name, true)
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
local getMyModel  -- FORWARD-DECLARED: fireAttack (below) calls it, but the definition is further down. Without this
                  -- forward decl it bound to a nil global and fireAttack THREW before sending the Attack remote.
local function fireAttack(targetModel, skipSound)
	if not targetModel then return false end
	-- Degrade gracefully like replicaFire does: if the hook didn't capture our id, use any seen id (no-hook executors).
	local myId = myReplicaId or seenIds[1]
	if not myId then return false end
	local rs=getReplicaSignal(); if not rs then return false end
	-- pick a TARGET bone. If you picked a specific "Expand Bone" (Hitbox), AIM THAT SAME BONE; else use Always-hit part.
	local group, boneName, targetPos
	local want = (CFG.HitboxBone and CFG.HitboxBone~="All" and CFG.HitboxBone~="") and CFG.HitboxBone or CFG.DamagePart
	local list = (want and want~="" and want~="Auto" and ATK_GROUPS[want]) or ATK_GROUPS.Auto
	for _,b in ipairs(list) do
		local bn=_findIn(targetModel, b.n); local p=_bonePos(bn)
		if p then group, boneName, targetPos = b.g, b.n, p; break end
	end
	if not targetPos and list~=ATK_GROUPS.Auto then
		for _,b in ipairs(ATK_GROUPS.Auto) do local bn=_findIn(targetModel,b.n); local p=_bonePos(bn); if p then group,boneName,targetPos=b.g,b.n,p; break end end
	end
	if not targetPos then
		local hb=targetModel:FindFirstChild("Hitbox") or targetModel:FindFirstChild("HitBox")
		if hb and hb:IsA("BasePart") then group, boneName, targetPos = "Body","Hitbox",hb.Position end
	end
	if not targetPos then return false end
	-- ALWAYS HIT the chosen part: even if we resolved the position from another bone (fallback), REPORT the hit as the
	-- selected group/name. So "Always Damage = Neck" registers as a Neck hit no matter which bone we found.
	if want and want~="" and want~="Auto" then
		group = want
		boneName = (ATK_GROUPS[want] and ATK_GROUPS[want][1] and ATK_GROUPS[want][1].n) or want
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

-- ═══ SKIN CHANGER (working standalone — SurfaceAppearance swap on MeshModel) ═══
local STAGE_SK = {"Hatchling","Juvenile","Teen","Adolescent","SubAdult","Sub-Adult","Adult","Elder","Monster"}
local SKN = { skinData=nil, skinFolder=nil, saBack={}, busy=false }
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
local remoteCache = {}
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
local FARM = {tried={}, nodeCache={}, food={t=0,list={}}, dig=nil, digSearched=false, lastDeepPin=0, count={fossil=0,gem=0}}
-- The REAL targetable/hittable part the game uses is Characters[name].HitBox (user-confirmed). Prefer it
-- for aim / hitbox-expand / ESP / farm; fall back to the steer body. Name can vary, so try a few.
local function getHitbox(model)
	model = model or getMyModel()
	if not model then return nil end
	-- Priority the user confirmed: Hitbox (lowercase b) FIRST, then HitBox (capital B) — they're DIFFERENT
	-- parts in the model (FindFirstChild is case-sensitive) — then TurningAnimation.Body, PrimaryPart, any part.
	for _,n in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do
		local hb=model:FindFirstChild(n); if hb and hb:IsA("BasePart") then return hb end
	end
	local ta=model:FindFirstChild("TurningAnimation"); if ta then local b=ta:FindFirstChild("Body"); if b and b:IsA("BasePart") then return b end end
	if model.PrimaryPart then return model.PrimaryPart end
	return rootOf(model)
end
-- "Always hit the Spine/Head": if CFG.AimPart names a bone (Head/Spine/Neck/...), aim at that bone (found in
-- the dino's MeshModel bone hierarchy); else aim at the Hitbox. Returns an Instance (BasePart/Bone/Attachment).
-- Spine/Head/etc. are BONE rigs under MeshModel>RootPart (Spine.002, Spine.001, ...), not BaseParts — search
-- a priority list of real bone names so "Always hit Spine" actually finds a bone, else fall back to the Hitbox.
-- Real hit-PART names inside model.Hitbox (per the screenshots).
local AIM_BONES = {
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
local ACCENTS = {
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

-- Built-in window starts HIDDEN so it never flashes before Fluent loads; shown only if Fluent fails (fallback).
SG = C("ScreenGui",{Name="MoneyHubPE", Enabled=false, ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true})
safeParentGui(SG)
local Shd = C("Frame",{Parent=SG, Size=UDim2.fromOffset(664,454), Position=UDim2.new(0.5,-332,0.5,-227), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.45, BorderSizePixel=0}); corner(Shd,4)
local MF = C("Frame",{Parent=SG, Size=UDim2.fromOffset(650,440), Position=UDim2.new(0.5,-325,0.5,-220), BackgroundColor3=T.Main, BorderSizePixel=0, ClipsDescendants=true}); corner(MF,3); stroke(MF,T.Stroke,1)
C("UIScale",{Parent=MF, Scale=tonumber(CFG.UIScale) or 1})  -- scale up for crisp HiDPI / 4K (Settings > UI Scale)
local TB = C("Frame",{Parent=MF, Size=UDim2.new(1,0,0,46), BackgroundColor3=T.Top, BorderSizePixel=0})
local accentBar = C("Frame",{Parent=TB, Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2), BackgroundColor3=T.Accent, BorderSizePixel=0})
C("TextLabel",{Parent=TB, Position=UDim2.fromOffset(16,0), Size=UDim2.new(0,170,1,0), BackgroundTransparency=1, Text="Dream Hub", TextColor3=T.Text, TextSize=14, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
C("TextLabel",{Parent=TB, Position=UDim2.fromOffset(160,0), Size=UDim2.new(0,170,1,0), BackgroundTransparency=1, Text="| Prior Extinction", TextColor3=T.Accent, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
local chf = C("Frame",{Parent=TB, Size=UDim2.fromOffset(64,28), Position=UDim2.new(1,-74,0.5,-14), BackgroundTransparency=1}); lay(chf,4,Enum.FillDirection.Horizontal)
local minBtn = C("TextButton",{Parent=chf, Size=UDim2.fromOffset(28,28), BackgroundColor3=T.Panel2, Text="-", TextColor3=T.Sub, TextSize=16, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=1}); corner(minBtn,3); stroke(minBtn,T.Stroke,1)
local closeBtn = C("TextButton",{Parent=chf, Size=UDim2.fromOffset(28,28), BackgroundColor3=T.Panel2, Text="X", TextColor3=T.Accent, TextSize=12, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=2}); corner(closeBtn,3); stroke(closeBtn,T.Stroke,1)
closeBtn.MouseButton1Click:Connect(function() SG.Enabled=false end)
local Ftr = C("Frame",{Parent=MF, Position=UDim2.new(0,0,1,-20), Size=UDim2.new(1,0,0,20), BackgroundColor3=T.Top, BorderSizePixel=0})
C("Frame",{Parent=Ftr, Size=UDim2.new(1,0,0,1), BackgroundColor3=T.DarkRed, BorderSizePixel=0})
C("TextLabel",{Parent=Ftr, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Dream Hub · Prior Extinction · RightShift to toggle", TextColor3=T.Muted, TextSize=10, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Center})
local Bod = C("Frame",{Parent=MF, Position=UDim2.fromOffset(0,46), Size=UDim2.new(1,0,1,-66), BackgroundTransparency=1})
local Side = C("Frame",{Parent=Bod, Size=UDim2.new(0,158,1,0), BackgroundColor3=T.Top, BorderSizePixel=0})
C("Frame",{Parent=Bod, Size=UDim2.new(0,1,1,0), Position=UDim2.fromOffset(158,0), BackgroundColor3=T.DarkRed, BorderSizePixel=0})
local SideList = C("ScrollingFrame",{Parent=Side, Size=UDim2.new(1,0,1,-46), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=T.Accent}); pad(SideList,8,6,8,4); lay(SideList,3)
local PB = C("Frame",{Parent=Side, Size=UDim2.new(1,0,0,46), Position=UDim2.new(0,0,1,-46), BackgroundColor3=T.Top, BorderSizePixel=0})
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
local minimized=false
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
local toggleRefs = {}
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
local capturing=nil
local bindGuard=0
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
local STAT_GROUPS = {
	{cfg="InfFood",   keys={"food","hunger","nutri","fullness","satiat","satiet"}},
	{cfg="InfWater",  keys={"water","thirst","hydrat","drink","liquid"}},
	{cfg="InfStam",   keys={"stamina","stam","energy","endur"}},
	{cfg="InfOxygen", keys={"oxygen","air","breath","o2","lung"}},
}
-- Drain meters that go UP as you suffer — when their feature is on, force them to ZERO, never max.
local STAT_ZERO = {
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
	pinOne(CFG.InfFood,   {"Food","Hunger"})
	pinOne(CFG.InfWater,  {"Water","Thirst"})
	pinOne(CFG.InfStam,   {"Stamina","Stam","Energy"})
	pinOne(CFG.InfOxygen, {"Oxygen","Air","Breath"})
end
-- (Instant Elder + stat dump removed per request.)

-- ═══ FLUENT UI (primary) — clean library; auto-falls-back to the built-in window if it can't load ═══
local Fluent, FWindow, USE_FLUENT = nil, nil, false
pcall(function()
	Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
	FWindow = Fluent:CreateWindow({ Title="Dream Hub", SubTitle="Prior Extinction", TabWidth=150, Size=UDim2.fromOffset(580,460), Acrylic=true, Theme="Light", MinimizeKey=Enum.KeyCode.RightShift })
end)
if FWindow then
	USE_FLUENT = true
	local Options = Fluent.Options
	-- Hide the built-in window (MF/Shd invisible) but KEEP SG.Enabled as the "menu open" SIGNAL the aim/autoclick/
	-- farm-player guards read — true = Fluent menu open (pause aim so you can click tabs). Toggled with RightShift.
	pcall(function() SG.Enabled=true; MF.Visible=false; Shd.Visible=false end)
	for k in pairs(Pages) do Pages[k]=nil end
	local ICONS = {Combat="swords", PvP="target", Movement="footprints", Survival="heart-pulse", ["Auto Farm"]="pickaxe", Teleport="map-pin", Visuals="eye", Skins="palette", Misc="wrench", Settings="settings", Info="info"}
	mkTab = function(name) local tb=FWindow:AddTab({Title=name, Icon=ICONS[name] or ""}); Pages[name]=tb; return tb end
	mkSec = function(par, title) pcall(function() par:AddParagraph({Title=title, Content=""}) end); return par, par end
	mkToggle = function(par, txt, key) pcall(function() local t=par:AddToggle(key,{Title=txt, Default=CFG[key] and true or false}); t:OnChanged(function() CFG[key]=Options[key].Value; saveCfg() end) end) end
	mkSlider = function(par, txt, key, mn, mx, _o, step) pcall(function() par:AddSlider(key,{Title=txt, Default=tonumber(CFG[key]) or mn, Min=mn, Max=mx, Rounding=((step and step>=1) and 0 or 2), Callback=function(v) CFG[key]=v; saveCfg() end}) end) end
	mkBtn = function(par, txt, cb) pcall(function() par:AddButton({Title=txt, Callback=function() pcall(cb) end}) end) end
	mkTextbox = function(par, lbl, key, _o, numeric) pcall(function() par:AddInput(key,{Title=lbl, Default=tostring(CFG[key] or ""), Numeric=numeric and true or false, Finished=true, Callback=function(v) if numeric then CFG[key]=tonumber(v) or CFG[key] else CFG[key]=v end saveCfg() end}) end) end
	mkStatus = function() return nil end
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

-- ═══ TABS / PAGES ═══
mkTab("Combat",1); mkTab("PvP",2); mkTab("Movement",3); mkTab("Survival",4); mkTab("Auto Farm",5); mkTab("Teleport",6)
mkTab("Visuals",7); mkTab("Skins",8); mkTab("Misc",9); mkTab("Settings",10); mkTab("Info",11)

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
	mkToggle(m,"Float (hover up — Space/Ctrl to rise/lower)","Float",1)
	mkToggle(m,"Speed Hack","SpeedHack",4)
	mkSlider(m,"Speed","SpeedVal",20,250,5,5)
	local _,n=mkSec(p,"Clip & Jump",2)
	mkToggle(n,"Noclip","Noclip",1)
	mkToggle(n,"Anti-Snapback Teleports","BypassTP",3)
end
do local p=Pages["Survival"]
	local _,f=mkSec(p,"Food / Water / Stamina",1)
	mkToggle(f,"INF Food","InfFood",1)
	mkLabel(f,"HERB ONLY: turn INF Food ON, then EAT ONE plant (walk up + press E). It captures that food id + scans the whole map and keeps replaying it to hold your bar. If you're a CARNIVORE, use Carnivore Meat TP below instead.")
	mkSlider(f,"INF Food grow speed (bites/cycle)","FoodEatSpeed",1,10,3,1)
	mkToggle(f,"Carnivore Meat TP (TP to nearest meat/corpse)","CarnMeatTP",4)
	mkToggle(f,"INF Water","InfWater",5)
	mkToggle(f,"INF Stamina","InfStam",6)
	local _,pr=mkSec(p,"Protection",2)
	mkToggle(pr,"Anti Drown","AntiDrown",1)
	mkToggle(pr,"Walk on Water","WalkWater",2)
	mkToggle(pr,"Auto Clean","AutoClean",3)
	mkToggle(pr,"Anti Fractured Head","AntiFracture",4)
	mkToggle(pr,"Anti Bleed","AntiBleed",5)
	mkToggle(pr,"Anti Fall","AntiFall",6)
	mkToggle(pr,"No Sleep Screen","NoSleep",7)
	mkToggle(pr,"Bone Protection (anti break)","BoneProtect",8)
	mkDropdown(pr,"Protect Bone", function() return {"All","Head","Neck","Arm","Leg","Body"} end, function() return CFG.ProtectBone~="" and CFG.ProtectBone or "All" end, function(opt) CFG.ProtectBone=opt; saveCfg() end, 9)
	local _,sv=mkSec(p,"Auto Heal",4)
	mkToggle(sv,"Save Dino","SaveDino",1)
	mkSlider(sv,"Save at HP %","SaveHP",5,90,2,5)
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
do local p=Pages["Auto Farm"]
	local _,f=mkSec(p,"Fossils & Gems",1)
	mkToggle(f,"Auto Farm Fossil","AutoFarmFossil",1)
	mkToggle(f,"Auto Farm Gemstone","AutoFarmGem",2)
	mkToggle(f,"Teleport Farm (TP to each node, TP back when off)","FarmTeleport",3)
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
	local _,b=mkSec(p,"Auto Play Bot (full survival AI)",2)
	mkToggle(b,"Auto Play Bot — plays the game for you","AutoPlayBot",1)
	mkLabel(b,"The bot SURVIVES on its own: eats (diet-aware), drinks, flees predators, sleeps to heal, roams around its home spot, un-sticks itself, and keeps growing. Turn it on and walk away.")
	mkToggle(b,"Flee from predators","BotFlee",2)
	mkSlider(b,"Flee detect range","BotFleeRange",80,600,3,20)
	mkToggle(b,"Roam / wander (looks human)","BotRoam",4)
	mkSlider(b,"Roam radius (from home)","BotRoamRadius",50,1200,5,50)
	mkSlider(b,"Eat when food below %","BotEatAt",30,95,6,5)
	mkSlider(b,"Drink when water below %","BotDrinkAt",30,95,7,5)
	mkToggle(b,"Sleep to heal when hurt + safe","BotSleepHeal",8)
	mkSlider(b,"Bot walk speed","BotSpeed",14,24,9,1)
	mkToggle(b,"Announce what the bot is doing","BotAnnounce",10)
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
		local cc=char(); local goal=CFrame.new(pos+Vector3.new(0,6,0))
		pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) else local r=hrp(); if r then r.CFrame=goal end end end)
		local r0=hrp(); if r0 then pcall(function() r0.AssemblyLinearVelocity=Vector3.zero end) end
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
	local _,e=mkSec(p,"ESP (name / dist / dino / stage / HP)",1)
	mkToggle(e,"ESP Creatures + Players","ESPPlayers",1)
	mkToggle(e,"ESP Corpses","ESPCorpses",2)
	mkToggle(e,"Food ESP (highlights corpses + food)","FoodESP",3)
	mkToggle(e,"Fish ESP","FishESP",4)
	mkToggle(e,"Gem + Fossil ESP","GemESP",5)
	mkSlider(e,"ESP Range","ESPRange",100,3000,6,50)
	mkDropdown(e,"ESP Color", function() return {"Default","Rainbow","Red","Green","Blue","Yellow","Purple","Cyan","Orange","Pink","White"} end, function() return CFG.ESPColor~="" and CFG.ESPColor or "Default" end, function(opt) CFG.ESPColor=opt; saveCfg() end, 6)
	local _,l=mkSec(p,"World",2)
	mkToggle(l,"Full Bright","FullBright",1)
	mkToggle(l,"No Night (force daytime)","NightVision",2)
	mkToggle(l,"No Darkness Underwater","NoDarkWater",3)
	mkToggle(l,"Water Transparency","WaterClear",4)
	mkToggle(l,"No Clouds","NoClouds",5)
	mkToggle(l,"INF Light (expand your light)","InfLight",6)
	local _,al=mkSec(p,"Danger Alert (pick a dino - warns when it's near)",3)
	mkToggle(al,"Enable Alert","AlertEnabled",1)
	mkDropdown(al,"Alert Dino", function() return DINO_NAMES end, function() return CFG.AlertDino~="" and CFG.AlertDino or "(pick a dino)" end, function(opt) CFG.AlertDino=opt; saveCfg() end, 2)
	mkSlider(al,"Alert Range","AlertRange",100,2000,3,50)
end
local skinDropdownRef, dinoLabel
do local p=Pages["Skins"]
	local _,s=mkSec(p,"Skin Changer (auto-detects your dino)",1)
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
	mkToggle(a,"INF Zoom (bypasses reset)","InfZoom",4)
	mkToggle(a,"Unlock Mouse + Camera","UnlockMouse",5)
	mkToggle(a,"Safe Teleport (anti-267)","SafeTP",7)
	local _,s=mkSec(p,"Server",2)
	mkBtn(s,"Rejoin Server",function() pcall(function() TeleportSvc:Teleport(game.PlaceId,LP) end) end,1)
	mkBtn(s,"Server Hop",function() pcall(function() TeleportSvc:Teleport(game.PlaceId,LP) end) end,2)
end
do local p=Pages["Settings"]
	local _,t=mkSec(p,"Theme & Quality",1)
	mkBtn(t,"Cycle Accent Color",function() CFG.AccentIndex=(CFG.AccentIndex % #ACCENTS)+1; T.Accent=ACCENTS[CFG.AccentIndex]; T.On=T.Accent; if accentBar then accentBar.BackgroundColor3=T.Accent end for key,ref in pairs(toggleRefs) do if CFG[key] and ref[1] then ref[1].BackgroundColor3=T.On end end showPage(currentPage); saveCfg() end,1)
	mkSlider(t,"UI Scale (bigger = crisp on 4K)","UIScale",1,3,2,0.1)
	local _,k=mkSec(p,"Keybinds (click then press a key)",2)
	local binds = { {"Open/Close UI","UIKey"},{"Aim Lock","AimKey"},{"Aimbot","Aimbot"},{"Silent Aim","SilentAim"},{"Lock On","LockOn"},{"Turn Hack","TurnHack"},{"Hitbox","HitboxExpand"},{"Auto Click","AutoClick"},{"Float","Float"},{"Fly","Fly"},{"Speed Hack","SpeedHack"},{"Noclip","Noclip"},{"Inf Jump","InfJump"},{"INF Food","InfFood"},{"INF Water","InfWater"},{"INF Stam","InfStam"},{"Anti Drown","AntiDrown"},{"Walk on Water","WalkWater"},{"Anti Fall","AntiFall"},{"Save Dino","SaveDino"},{"Auto Farm Player","AutoFarmPlayer"},{"Auto Farm Fossil","AutoFarmFossil"},{"Auto Farm Gem","AutoFarmGem"},{"ESP","ESPPlayers"},{"Food ESP","FoodESP"},{"Fish ESP","FishESP"},{"Full Bright","FullBright"},{"No Night","NightVision"},{"INF Light","InfLight"},{"INF Zoom","InfZoom"} }
	for i,kb in ipairs(binds) do mkKeybind(k, kb[1], kb[2], i) end
end
local HUD={}  -- debug-panel status refs (one table instead of 4 locals — Luau 200-local-cap mgmt)
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
				if CFG.InfFood   and stats.Food    ~= nil and maxs and maxs.Food    then stats.Food    = maxs.Food    end
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
				topPin(CFG.InfFood, {"Food","Hunger","Nutrition"}, {"MaxFood","MaxHunger","MaxNutrition"})
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
			if CFG.InfOxygen then pin({"Oxygen","Air","Breath","O2","Lung"}) end
			if CFG.InfFood   then pin({"Food","Hunger","Nutrition","Fullness"}) end
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

-- INF STAM (server-side refill — THE FIX): the game reports its stamina to the server via ReplicaSignal
-- SetProperty — the hook above swallows the DROP reports, and THIS loop reports it FULL the exact same way the
-- game itself does, so the server-side value refills and never drains. Real max only (inflated values made the
-- server fight back = the old snapback). This is what makes INF Stamina actually hold while you sprint/M2.
task.spawn(function() while RUNNING do
	if CFG.InfStam and alive() then
		local mx
		pcall(function() local _,maxs=csStats(); if maxs then mx=maxs.Stamina or maxs.Stam or maxs.Energy end end)
		mx = mx or (__gg.MH_max and (__gg.MH_max.Stamina or __gg.MH_max.Stam or __gg.MH_max.Energy)) or 100
		-- Fire every known stamina key so we hit whichever property name the server actually tracks.
		-- The hook rewrites any incoming SetProperty-stam to tracked-max before firing through, so
		-- these calls also get rewritten — meaning the server always hears "stamina = full" on each key.
		for _,k in ipairs({"Stamina","Stam","Energy","Endurance"}) do
			local v = (__gg.MH_max and __gg.MH_max[k]) or mx
			pcall(function() replicaFire("SetProperty", k, v) end)
		end
		task.wait(0.35)
	else task.wait(0.4) end
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
			if (kp:find("brok",1,true) or kp:find("break",1,true) or kp:find("sever",1,true) or kp:find("dislocat",1,true) or kp:find("snap",1,true) or kp:find("crippl",1,true)) then
				local anyBreak = CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso
				local part
				if kp:find("head",1,true) or kp:find("jaw",1,true) or kp:find("skull",1,true) then part=CFG.AntiBreakHead
				elseif kp:find("neck",1,true) then part=CFG.AntiBreakNeck
				elseif kp:find("leg",1,true) or kp:find("foot",1,true) or kp:find("limb",1,true) or kp:find("femur",1,true) or kp:find("tibia",1,true) or kp:find("thigh",1,true) or kp:find("pubis",1,true) then part=CFG.AntiBreakLeg
				elseif kp:find("tail",1,true) then part=CFG.AntiBreakTail
				elseif kp:find("torso",1,true) or kp:find("spine",1,true) or kp:find("rib",1,true) or kp:find("body",1,true) then part=CFG.AntiBreakTorso
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
			if clear then
				if tv=="boolean" then if v then pcall(function() tb[k]=false end) end
				else if v~=0 then pcall(function() tb[k]=0 end) end end
			end
		elseif tv=="table" and getmetatable(v)==nil then
			antiInjurySweep(v, kp, depth+1)
		end
	end
end
task.spawn(function() while RUNNING do
	if (CFG.AntiBleed or CFG.AntiFracture or CFG.BoneProtect or CFG.AntiBreakHead or CFG.AntiBreakNeck or CFG.AntiBreakLeg or CFG.AntiBreakTail or CFG.AntiBreakTorso) and alive() then
		pcall(function() local r=csReplica(); if r and r.Data then antiInjurySweep(r.Data, "", 0) end end)
		pcall(function() if CharacterState then for _,s in ipairs({"Stats","State","Data","Wounds","Bones","BodyParts","Status"}) do local t=CharacterState[s]; if type(t)=="table" then antiInjurySweep(t, s:lower()..".", 0) end end end end)
		task.wait(0.08)
	else task.wait(0.3) end
end end)
local FLY={}  -- bv/bg/conn (one table instead of 3 locals — Luau 200-local-cap mgmt)
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
		local cf=Cam.CFrame; local dir=Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end
		FLY.bv.Velocity=(dir.Magnitude>0 and dir.Unit or Vector3.zero)*CFG.FlySpeed; FLY.bg.CFrame=cf
		local hh=hum(); if hh then pcall(function() hh:ChangeState(Enum.HumanoidStateType.Physics) end) end
	end)
end
-- SPEED HACK ONLY drives the body by velocity. INF Stam does NOT touch your movement anymore — driving velocity
-- made the server snap you back AND counted as sprinting (which drained stamina, then exhausted = slow when you
-- toggled off). INF Stam now just suppresses the drain (hook + stat pin), so you move at NORMAL speed, stam full.
conn(RunService.Heartbeat:Connect(function() if CFG.SpeedHack and alive() and not CFG.Fly then local r=hrp(); if r then local spd=CFG.SpeedVal; local dir=Vector3.zero; local cf=Cam.CFrame if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end if dir.Magnitude>0 then dir=Vector3.new(dir.X,0,dir.Z).Unit*spd; r.AssemblyLinearVelocity=Vector3.new(dir.X,r.AssemblyLinearVelocity.Y,dir.Z) end end end end))
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
				if tick()-wT > 3 then wParts={}; wT=tick(); local c=0
					for _,d in ipairs(WS:GetDescendants()) do c+=1; if c>9000 then break end
						if d:IsA("BasePart") then local n=d.Name:lower()
							if (n:find("water") or n:find("lake") or n:find("wave") or n:find("ocean") or n:find("pond") or n:find("lagoon") or n:find("sea") or n:find("swamp")) and (d.Size.X*d.Size.Z)>200 then wParts[#wParts+1]=d end
						end
					end
				end
				local band = CFG.WalkWater and 4 or 1   -- wider detect band while standing ON the water (no bobbing)
				for _,p in ipairs(wParts) do if p.Parent then
					local rel=p.CFrame:PointToObjectSpace(r.Position)
					if math.abs(rel.X)<=p.Size.X/2 and math.abs(rel.Z)<=p.Size.Z/2 then
						local top=p.Position.Y+p.Size.Y/2
						if r.Position.Y < top+band and (not surf or top>surf) then surf=top end
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
				pcall(function() setReplicaProp("State","Land") end)
				pcall(function() replicaAction("SetAction","Drowning",false) end)
				pcall(function() replicaAction("Mode","Walk") end)
				if CharacterState then for _,k in ipairs({"IsInWater","Submerged","Underwater","Swimming","Drowning"}) do pcall(function() if CharacterState[k]~=nil then CharacterState[k]=false end end) end end
				local stats,maxs=csStats(); if stats then for _,k in ipairs({"Oxygen","Air","Breath","O2"}) do if stats[k]~=nil then stats[k]=(maxs and maxs[k]) or math.max(tonumber(stats[k]) or 0,100) end end end
				-- Y-only BodyVelocity HOLD (the fix): eases to the target height and STAYS there. X/Z untouched = walk freely.
				if not (wbv and wbv.Parent==r) then pcall(function() if wbv then wbv:Destroy() end end); wbv=Instance.new("BodyVelocity"); wbv.Name="MH_Water"; wbv.MaxForce=Vector3.new(0,9e9,0); wbv.P=9e4; wbv.Velocity=Vector3.zero; wbv.Parent=r end
				local target = CFG.WalkWater and (surf+2.6) or (surf+0.8)
				local vy = math.clamp((target - r.Position.Y)*5, -6, 14)
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
	if CFG.InfFood then pinStat({"hunger","food","fullness","nutri","satiet"},{"Hunger","Food","Nutrition","Fullness"},100) end
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
		-- 1) Investigate prompts = real PE corpses (red ESP + E to consume). This is the authoritative carnivore food.
		for _,d in ipairs(WS:GetDescendants()) do
			cnt+=1; if cnt>3500 then break end
			if d:IsA("ProximityPrompt") then
				local at=(d.ActionText or ""):lower(); local nm=(d.Name or ""):lower()
				if at:find("investigate") or at:find("eat") or at:find("consume") or nm:find("investigate") then
					local p=d.Parent
					local part=(p and p:IsA("BasePart") and p) or (p and p:FindFirstChildWhichIsA("BasePart"))
					local m=(p and p:IsA("Model")) and p or (part and part:FindFirstAncestorWhichIsA("Model")) or p
					if m and part and not seen[m] then local dd=dist(me.Position,part.Position); if dd<=range then seen[m]=true; out[#out+1]={m,part,dd, prompt=d} end end
				end
			elseif d:IsA("Model") and d~=getMyModel() and not Players:GetPlayerFromCharacter(d) and not seen[d] then
				local n=d.Name:lower()
				if isFoodName(n) or n:find("corpse") or n:find("carcass") or n:find("remains") then
					local r=rootOf(d); if r then local dd=dist(me.Position,r.Position); if dd<=range then seen[d]=true; out[#out+1]={d,r,dd} end end
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
local MEAT_KW = {"corpse","carcass","carrion","meat","chunk","rotten","flesh","remains","dead","fish","gar","sturgeon","bichir","coelacanth","mawsonia","sawfish","egg","grub","larva","insect","ant"}
local function isMeatName(n) n=(n or ""):lower(); for _,k in ipairs(MEAT_KW) do if n:find(k,1,true) then return true end end return false end
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
local function nearestMeat(range)
	local me=hrp(); if not me then return nil end
	local best,bpart,bd=nil,nil,range
	local cnt=0
	for _,d in ipairs(WS:GetDescendants()) do
		cnt+=1; if cnt>4000 then break end
		local m,part
		if d:IsA("ProximityPrompt") then
			local at=((d.ActionText or "").." "..(d.Name or "")):lower()
			if at:find("investigate") or at:find("eat") or at:find("consume") then
				local p=d.Parent; part=(p and p:IsA("BasePart") and p) or (p and p:FindFirstChildWhichIsA("BasePart")); m=(p and p:IsA("Model")) and p or (part and part:FindFirstAncestorWhichIsA("Model")) or p
			end
		elseif d:IsA("Model") and d~=getMyModel() and not Players:GetPlayerFromCharacter(d) then
			-- a corpse either NAME-matches meat OR carries PE's corpse markers (DinoType/HintType/CreatedAt)
			local isCorpse=isMeatName(d.Name)
			if not isCorpse then pcall(function() isCorpse=(d:GetAttribute("DinoType") or d:GetAttribute("HintType") or d:GetAttribute("CreatedAt"))~=nil end) end
			if isCorpse then m=d; part=rootOf(d) end
		elseif d:IsA("BasePart") and isRedMeshMeat(d) then
			-- the RED MESHY chunk itself (screenshot look) — teleportable meat even with no prompt/name/marker
			part=d; m=d:FindFirstAncestorWhichIsA("Model") or d
		end
		if m and part and part:IsA("BasePart") then local dd=dist(me.Position,part.Position); if dd<bd then best,bpart,bd=m,part,dd end end
	end
	return best,bpart,bd
end
__gg.MH_nearestMeat = nearestMeat   -- expose so the Auto Play Bot (separate do-block) can reuse it without a 2nd top-level local
local carnMeatCd=0
task.spawn(function() while RUNNING do
	if CFG.CarnMeatTP and CFG.InfFood and alive() then
		-- only travel when actually hungry (don't yank you around at full bar)
		local hungry=true; pcall(function() local s,m=csStats(); if s and m then local h=tonumber(s.Food or s.Hunger); local mh=tonumber(m.Food or m.Hunger or m.MaxFood); if h and mh then hungry = h < mh*0.9 end end end)
		if hungry and tick()-carnMeatCd>3 then
			local m,part=nearestMeat(4000)
			if part then
				carnMeatCd=tick()
				if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
				local np=part.Position; local landY=np.Y+2; pcall(function() if __gg.MH_landY then landY=__gg.MH_landY(np, m) end end)
				local cc=getMyModel(); local goal=CFrame.new(np.X, landY, np.Z)
				-- stepped/whitelisted-style move: noclip through, snap, then hold with a BodyPosition so it can't rubber-band
				local noclip={}; if cc then pcall(function() for _,dd in ipairs(cc:GetDescendants()) do if dd:IsA("BasePart") and dd.CanCollide then dd.CanCollide=false; noclip[#noclip+1]=dd end end end) end
				pcall(function() if cc and cc.PrimaryPart then cc:PivotTo(goal) else local r=hrp(); if r then r.CFrame=goal end end end)
				local r=hrp(); if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero end) end
				local bp; pcall(function() if r then bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(9e9,9e9,9e9); bp.P=2e4; bp.D=2500; bp.Position=Vector3.new(np.X,landY,np.Z); bp.Parent=r end end)
				-- EAT IT NOW: fire the corpse's own Eat/Investigate prompt directly (instant hold) + a real E hold as
				-- backup, so the meat is consumed on THIS visit instead of waiting for the food loop's next pass.
				pcall(function()
					local prompt
					if m and m.FindFirstChildWhichIsA then prompt=m:FindFirstChildWhichIsA("ProximityPrompt", true) end
					if not prompt and part then prompt=part:FindFirstChildWhichIsA("ProximityPrompt") end
					if prompt then
						local oh=prompt.HoldDuration
						prompt.RequiresLineOfSight=false; prompt.HoldDuration=0
						if fireprox then fireprox(prompt) end
						prompt.HoldDuration=oh
					end
				end)
				holdKey(Enum.KeyCode.E, 0.6)
				task.wait(0.7)   -- sit on the meat so INF Food's eat consumes it
				for _,dd in ipairs(noclip) do pcall(function() dd.CanCollide=true end) end
				pcall(function() if bp then bp:Destroy() end end)
			end
		end
		task.wait(0.4)
	else task.wait(0.5) end
end end)
end   -- end of the scoped meat-helpers + Carnivore Meat TP block
task.spawn(function() while RUNNING do
	if CFG.InfFood and alive() then
		fakeEat()
		if CFG.AutoEatFood then
			-- Eat the NEAREST food/corpse: fire its prompt ONCE (per-corpse 3s cooldown = "click E once", not a spam).
			-- Only acts when genuinely close (≤40 studs — the server rejects a far prompt anyway). One corpse per pass.
			local me=hrp(); local list=nearbyFood(CFG.FoodEatRange)
			if me then for _,fd in ipairs(list) do
				local m,r,prompt=fd[1],fd[2],fd.prompt
				if not prompt and m then for _,d in ipairs(m:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d; break end end end
				if prompt and r and r.Parent and dist(me.Position,r.Position)<=math.min(CFG.FoodEatRange,40) then
					local kk="food_"..tostring(prompt); local last=FARM.tried[kk]
					if not last or tick()-last>3 then
						FARM.tried[kk]=tick()
						pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.huge end)
						if fireprox then pcall(function() fireprox(prompt) end) end  -- runs the full hold = one clean eat
					end
					break  -- nearest only
				end
			end end
		end
		task.wait(0.4)
	else task.wait(0.4) end
end end)
task.spawn(function() while RUNNING do
	if CFG.InfWater and alive() then
		fakeDrink()                       -- the captured "Sip" action (works at a water source)
		holdKey(Enum.KeyCode.E, 0.3)      -- drinking is also hold-E at water; harmless elsewhere
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
local SAVED = {light=nil, fbCC=nil, zoom=nil, water=nil}  -- consolidated saved-state (was 4 separate locals)
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
conn(RunService.RenderStepped:Connect(function() if CFG.UnlockFOV and Cam then pcall(function() Cam.FieldOfView=CFG.FOV end) end if CFG.InfZoom then if not SAVED.zoom then SAVED.zoom={LP.CameraMaxZoomDistance,LP.CameraMinZoomDistance} end pcall(function() LP.CameraMaxZoomDistance=100000; LP.CameraMinZoomDistance=0.5 end) elseif SAVED.zoom then pcall(function() LP.CameraMaxZoomDistance=SAVED.zoom[1]; LP.CameraMinZoomDistance=SAVED.zoom[2] end); SAVED.zoom=nil end end))
-- Always Damage (PvP): auto-fire the captured Attack remote at EVERY nearby character within DamageRange.
-- Works in normal play AND Sandbox (scans workspace.Characters + sandbox folders + nil-parented dino models).
task.spawn(function() while RUNNING do
	if CFG.AlwaysDamage and alive() then
		local me=hrp()
		if me then
			-- ONE real swing per cycle (mouse click + SoundRemote) so the bite ANIMATION/STATE is active when the
			-- server gets our Attack reports. Wait ONE frame after the swing so the server opens the attack window
			-- BEFORE the hit reports land (matches the real sequence: swing → window opens → hit), then fire Attacks.
			pcall(clickMouse)
			local sr=getSoundRemote(); if sr then pcall(function() sr:FireServer("PVP","Attacks/Primary",false,nil,1) end) end
			RunService.Heartbeat:Wait()
			local mine=getMyModel(); local n=0; local seen={}
			local function hit(m)
				if n>=8 or not (m and m:IsA("Model") and m~=mine) or seen[m] then return end
				local hb=getHitbox(m); if hb and dist(me.Position,hb.Position)<=CFG.DamageRange then seen[m]=true; fireAttack(m, true); n+=1 end
			end
			local chars=WS:FindFirstChild("Characters"); if chars then for _,m in ipairs(chars:GetChildren()) do hit(m) end end
			-- Sandbox: other containers + nil-parented models
			for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters"}) do
				if n>=8 then break end local f=WS:FindFirstChild(nm); if f then for _,m in ipairs(f:GetChildren()) do hit(m) end end
			end
			if n==0 and typeof(getnilinstances)=="function" then
				pcall(function() local c=0; for _,v in next, getnilinstances() do c+=1; if c>4000 or n>=8 then break end
					if typeof(v)=="Instance" and v:IsA("Model") and (v:FindFirstChild("Hitbox") or v:FindFirstChild("HitBox")) then hit(v) end
				end end)
			end
		end
		task.wait(1/math.max(1,CFG.DamageRate))
	else task.wait(0.15) end
end end)
task.spawn(function() while RUNNING do task.wait(0.5); local terrain=WS:FindFirstChildOfClass("Terrain"); if CFG.WaterClear and terrain then if not SAVED.water then SAVED.water={terrain.WaterTransparency,terrain.WaterReflectance,terrain.WaterWaveSize} end pcall(function() terrain.WaterTransparency=0.92; terrain.WaterReflectance=0; terrain.WaterWaveSize=0 end) elseif SAVED.water and terrain then pcall(function() terrain.WaterTransparency=SAVED.water[1]; terrain.WaterReflectance=SAVED.water[2]; terrain.WaterWaveSize=SAVED.water[3] end); SAVED.water=nil end end end)
task.spawn(function() while RUNNING do task.wait(1) if CFG.NoClouds then pcall(function() local t=WS:FindFirstChildOfClass("Terrain"); local cl=t and t:FindFirstChildOfClass("Clouds"); if cl then cl.Cover=0; cl.Density=0; cl.Enabled=false end end) for _,e in ipairs(Lighting:GetDescendants()) do if e.ClassName=="Clouds" then pcall(function() e.Enabled=false end) end end end end end)
local saving=false
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

-- HITBOX EXPANDER (enemy creatures + players ONLY — same targeting as the proven standalone test build:
-- workspace.Characters children, skip YOUR model, both "HitBox"/"Hitbox" spellings, same property set)
local hbTouched={}
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
	for _,n in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do
		local inst=m:FindFirstChild(n)
		if inst then
			if inst:IsA("BasePart") then
				if boneMatch(inst.Name) or CFG.HitboxBone=="All" or CFG.HitboxBone=="Body" then expandPart(inst)
				elseif hbTouched[inst] then restorePart(inst) end  -- bone switched away → restore it (no double boxes)
			else
				for _,d in ipairs(inst:GetDescendants()) do
					if d:IsA("BasePart") then
						if boneMatch(d.Name) then expandPart(d)
						elseif hbTouched[d] then restorePart(d) end  -- restore parts that no longer match the selected bone
					end
				end
			end
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
		local function doFolder(folder) if folder then for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") and not isMine(m) then expandModel(m) end end end end
		doFolder(WS:FindFirstChild("Characters"))
		local ci=WS:FindFirstChild("CharacterIgnore"); if ci then doFolder(ci:FindFirstChild("SpawnedAI")) end
		for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters"}) do doFolder(WS:FindFirstChild(nm)) end
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
				local chars=WS:FindFirstChild("Characters"); if chars then for _,m in ipairs(chars:GetChildren()) do consider(m) end end
				if not best then for _,nm in ipairs({"Sandbox","Dinos","Creatures","NPCs","Entities","Mobs","Animals","DynamicCharacters"}) do local f=WS:FindFirstChild(nm); if f then for _,m in ipairs(f:GetChildren()) do consider(m) end end end end
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
	if CFG.UnlockMouse then pcall(function() UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true end); task.wait(0.1)
	else task.wait(0.4) end
end end)
-- (Auto Farm Player removed per request.)

-- AUTO FARM FOSSIL + GEMSTONE
-- Real in-game layout (from screenshot): <Container> > Spawned > <ResourceModel e.g. Topaz_151> >
--   MineralBase (BasePart) + GemstonePrompt (ProximityPrompt). Fossils similar (SpawnedFossils > ... > FossilS).
local function farmContainers(kind)
	local cs={}
	local function add(inst) if inst and not table.find(cs,inst) then cs[#cs+1]=inst end end
	local names = (kind=="fossil") and {"SpawnedFossils","FossilSpawns","Fossils"}
	                                 or {"GemstoneSpawns","SpawnedGemstones","SpawnedGems","Gemstones"}
	-- O(1) top-level lookups ONLY (the containers are direct children of WS / CharacterIgnore). NO recursive
	-- FindFirstChild(nm,true) — that's a full-workspace descendant walk per missing name = the farm lag.
	for _,root in ipairs({WS, WS:FindFirstChild("CharacterIgnore")}) do
		if root then
			for _,nm in ipairs(names) do
				local f=root:FindFirstChild(nm)
				if f then add(f); local sp=f:FindFirstChild("Spawned"); if sp then add(sp) end end
			end
		end
	end
	return cs
end
-- A node = {model, part, dist}. Detected via ProximityPrompt (preferred — covers GemstonePrompt) or a
-- resource-named BasePart (covers FossilS / MineralBase). Empty spawn markers have neither, so they're ignored.
local function gatherNodes(kind, range)
	local me=hrp(); if not me then return {} end
	local out={}
	-- Each numbered holder has MineralBase (gems) / FossilS (fossils) as a DIRECT child — grab it with
	-- FindFirstChild (O(1)), no deep GetDescendants over the whole container (that was the farm lag).
	local function fromHolder(h)
		local part = h:FindFirstChild("MineralBase") or h:FindFirstChild("FossilS")
		if not part then for _,d in ipairs(h:GetChildren()) do if d:IsA("BasePart") then part=d; break end end end
		part = part or rootOf(h)
		if part and part:IsA("BasePart") then local d=dist(me.Position, part.Position); if d<=range then out[#out+1]={h, part, d} end end
	end
	-- HARD bound on TOTAL holders scanned (not just in-range matches) so a map with hundreds of nodes can't
	-- cause a hitch when you toggle the farm on/off.
	local scanned=0
	for _,folder in ipairs(farmContainers(kind)) do
		for _,child in ipairs(folder:GetChildren()) do
			if #out>=150 or scanned>=1500 then break end
			if child.Name=="Spawned" then
				for _,sub in ipairs(child:GetChildren()) do scanned+=1; if #out>=150 or scanned>=1500 then break end if sub:IsA("Folder") or sub:IsA("Model") then fromHolder(sub) end end
			elseif child:IsA("Folder") or child:IsA("Model") then scanned+=1; fromHolder(child)
			elseif child:IsA("BasePart") then scanned+=1; local d=dist(me.Position, child.Position); if d<=range then out[#out+1]={child, child, d} end end
		end
		if #out>=150 or scanned>=1500 then break end
	end
	-- FALLBACK: if the named-folder scan found nothing, walk workspace descendants for ProximityPrompts
	-- whose ActionText/Name/parent-chain suggests the right resource kind. Handles non-standard folder
	-- layouts without scanning the whole workspace on every successful pass (early-exit when #out>0).
	if #out == 0 then
		local kw = (kind=="fossil") and {"fossil","excavat","bone","dig"}
		                             or {"gem","mineral","crystal","topaz","quartz","ruby","emerald","amethyst","harvest","collect"}
		local function hasKW(s) if not s then return false end; s=s:lower(); for _,k in ipairs(kw) do if s:find(k,1,true) then return true end end; return false end
		local sc2=0
		for _,d in ipairs(WS:GetDescendants()) do
			sc2+=1; if sc2>3000 or #out>=150 then break end
			if d:IsA("ProximityPrompt") then
				local hit=hasKW(d.ActionText) or hasKW(d.Name)
				if not hit then
					local p=d.Parent
					for _=1,3 do if p then if hasKW(p.Name) then hit=true; break end; p=p.Parent end end
				end
				if hit then
					local part=d.Parent
					if part and part:IsA("BasePart") then
						local holder=part.Parent or part
						local dd=dist(me.Position,part.Position)
						if dd<=range then out[#out+1]={holder,part,dd} end
					end
				end
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
				for holder,part in pairs(pending) do if not (part and part.Parent and holder and holder.Parent) then FARM.count[kind]=(FARM.count[kind] or 0)+1; pending[holder]=nil end end
				if CharacterState then pcall(function() CharacterState.FallDamageImmunity=true end) end
				-- dig remote: search ONCE (negative-cached) — this was the lag.
				if not FARM.digSearched then FARM.digSearched=true; FARM.dig=findRemote({"collectfossil","collectgem","startcollection","excavat","harvest"}) end
				local list=getNodes(kind, 1e9)
				if CFG.FarmTeleport then
					-- pick the nearest un-tried node, TP to it, collect it, wait for it to vanish
					local nd
					for _,cand in ipairs(list) do
						local holder,part=cand[1],cand[2]
						if part and part.Parent then local t=FARM.tried[holder]; if not t or tick()-t>15 then nd=cand; break end end
					end
					if nd then
						local holder,part=nd[1],nd[2]
						FARM.tried[holder]=tick()
						pcall(function()
							local cc=getMyModel(); local goal=CFrame.new(part.Position+Vector3.new(0,1.5,0))   -- SAFER: land right ON the node (was +4 = a visible high pop between every dig)
							if cc and cc.PrimaryPart then cc:PivotTo(goal) else local r=hrp(); if r then r.CFrame=goal end end
						end)
						local r0=hrp(); if r0 then pcall(function() r0.AssemblyLinearVelocity=Vector3.zero; r0.AssemblyAngularVelocity=Vector3.zero end) end
						task.wait(0.2)
						local prompt=part:FindFirstChildWhichIsA("ProximityPrompt")
						if not prompt then for _,d in ipairs(holder:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d; break end end end
						pending[holder]=part
						-- HOLD for the node's REAL duration (gems channel ~12s, fossils ~3s). The old 2.5s cap gave up
						-- before a gem finished = "auto farm doesn't collect". Keep planted with a BodyPosition (no fall),
						-- fire the prompt ONCE (it auto-holds), AND hold the real E key + listen for Triggered = done.
						local hold = (kind=="gem") and 12 or 3
						local done=false
						local tconn; if prompt then pcall(function() tconn=prompt.Triggered:Connect(function() done=true end) end) end
						local me=hrp(); local bp; pcall(function() if me then bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(9e9,9e9,9e9); bp.P=2e4; bp.D=2500; bp.Position=me.Position; bp.Parent=me end end)
						if prompt then pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=1e9; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.Enabled=true end) end
						if prompt and fireprox then pcall(function() fireprox(prompt) end) end
						pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)   -- hold E the whole channel (backup for no-fireprox)
						if FARM.dig and FARM.dig.Parent then pcall(function() fireRemoteMulti(FARM.dig, holder) end) end
						local t0=tick()
						while CFG[enabledKey] and tick()-t0<hold+2 and holder.Parent and part.Parent and not done do task.wait(0.15) end
						pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
						if tconn then pcall(function() tconn:Disconnect() end) end
						if prompt and fireprox then pcall(function() fireprox(prompt) end) end   -- backup: complete it now
						pcall(function() if bp then bp:Destroy() end end)
						if done or not (part and part.Parent) then FARM.count[kind]=(FARM.count[kind] or 0)+1; FARM.tried[holder]=nil end
						task.wait(0.2)
					else task.wait(0.6) end
				else
					-- STAND-STILL mode (zero movement = the anti-cheat never sees you move): fire prompts remotely, 6/pass.
					local n=0
					for _,nd in ipairs(list) do
						if not CFG[enabledKey] then break end
						local holder,part=nd[1],nd[2]
						if part and part.Parent then
							local t=FARM.tried[holder]
							if not t or tick()-t>12 then
								FARM.tried[holder]=tick()
								local prompt=part:FindFirstChildWhichIsA("ProximityPrompt")
								if not prompt then for _,d in ipairs(holder:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d; break end end end
								if prompt and fireprox then
									local od,ol,oh=prompt.MaxActivationDistance,prompt.RequiresLineOfSight,prompt.HoldDuration
									pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=1e9; prompt.HoldDuration=0 end)
									pcall(function() fireprox(prompt) end)
									pcall(function() prompt.MaxActivationDistance=od; prompt.RequiresLineOfSight=ol; prompt.HoldDuration=oh end)
									pending[holder]=part
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
local BOT = {
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
local _spDietCache = {}
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
-- find the nearest PREDATOR: another PLAYER's dino inside BotFleeRange whose species eats meat (or is unknown —
-- assume the worst). Wild/AI dinos count too if they're carnivores. Returns model, root, distance.
local function botNearestThreat()
	if not CFG.BotFlee then return nil end
	local me=hrp(); if not me then return nil end
	local mine=getMyModel()
	local best,broot,bd=nil,nil,tonumber(CFG.BotFleeRange) or 240
	local chars=WS:FindFirstChild("Characters")
	if chars then for _,m in ipairs(chars:GetChildren()) do
		if m:IsA("Model") and m~=mine then
			local r=getHitbox(m) or rootOf(m)
			if r then
				local d=dist(me.Position,r.Position)
				if d<bd then
					local sp=detectDinoModel(m) or m:GetAttribute("Type") or m:GetAttribute("Character")
					local diet=speciesDiet(sp and tostring(sp))
					if diet~="Herbivore" then   -- carnivore/omnivore/UNKNOWN = treat as a predator
						local h=m:FindFirstChildOfClass("Humanoid")
						if (not h) or h.Health>0 then best,broot,bd=m,r,d end
					end
				end
			end
		end
	end end
	return best,broot,bd
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
-- MOVEMENT DRIVE: velocity-walk toward BOT.goal at the bot speed (server-safe — no CFrame writes), steering the
-- body with angular velocity so the dino visibly TURNS toward where it walks (looks like a real player).
conn(RunService.Heartbeat:Connect(function()
	if not (CFG.AutoPlayBot and alive()) then return end
	if CFG.Fly or CFG.SpeedHack then return end          -- user-controlled movement wins
	local r=hrp(); if not r then return end
	local goal=BOT.goal
	if BOT.sleeping or not goal then return end          -- resting / no destination = stand still
	local to=goal-r.Position; local flat=Vector3.new(to.X,0,to.Z)
	if flat.Magnitude<4 then return end                  -- arrived (state loop decides what's next)
	local spd=math.clamp(tonumber(CFG.BotSpeed) or 18, 14, 24)
	if tick()<BOT.unstuckUntil then
		-- UNSTICK: hop + angled strafe for a moment to clear the rock/tree we're wedged on
		local side=flat.Unit:Cross(Vector3.yAxis)
		local v=(flat.Unit*0.5+side*0.85).Unit*spd
		pcall(function() r.AssemblyLinearVelocity=Vector3.new(v.X, math.max(r.AssemblyLinearVelocity.Y, 24), v.Z) end)
	else
		local dir=flat.Unit*spd
		pcall(function() r.AssemblyLinearVelocity=Vector3.new(dir.X, r.AssemblyLinearVelocity.Y, dir.Z) end)
	end
	-- steer the body to face the walk direction (same mechanism as Turn Hack — angular velocity, no CFrame)
	pcall(function()
		local cur=r.CFrame.LookVector; local curFlat=Vector3.new(cur.X,0,cur.Z)
		if curFlat.Magnitude>0.05 then
			curFlat=curFlat.Unit; local des=flat.Unit
			local cross=curFlat:Cross(des).Y; local dot=math.clamp(curFlat:Dot(des),-1,1)
			local ang=math.acos(dot)*((cross<0) and -1 or 1)
			local v=r.AssemblyAngularVelocity
			r.AssemblyAngularVelocity=Vector3.new(v.X, math.clamp(ang*4,-6,6), v.Z)
		end
	end)
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
				-- ── 2. DRINK ─────────────────────────────────────────────────────────────
				elseif waterF and waterF<drinkAt then
					BOT.sleeping=false; BOT.state="drink"
					fakeDrink()                                   -- the captured Sip ids work map-wide
					if botNearWater() then
						BOT.goal=nil                              -- at water: stand + sip
						BOT.waterPos=me.Position                  -- remember this watering hole
						holdKey(Enum.KeyCode.E, 0.3)
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
							holdKey(Enum.KeyCode.E, 0.6)
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
local function addESP(model, color, label, hpFrac)
	if ESP.objs[model] then return end
	local r=getHitbox(model) or rootOf(model); if not r then return end
	color = espColor(color)
	-- Highlight MUST be parented into the workspace/model to render — inside a ScreenGui it shows NOTHING (that was the bug).
	local h = Instance.new("Highlight"); h.FillColor=color; h.OutlineColor=Color3.new(1,1,1); h.FillTransparency=0.6; h.OutlineTransparency=0; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Adornee=model; h.Parent=model
	local lines=1; for _ in label:gmatch("\n") do lines=lines+1 end
	local barH = hpFrac and 7 or 0   -- room for the HEALTH BAR under the text
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
	ESP.objs[model]={h,bb,tl,fill}
end
-- RAINBOW animation: re-colour every active ESP highlight + label each frame while Rainbow is selected.
task.spawn(function() while RUNNING do
	if CFG.ESPColor=="Rainbow" then local col=Color3.fromHSV((tick()*0.15)%1,1,1); for _,o in pairs(ESP.objs) do pcall(function() if o[1] then o[1].FillColor=col end if o[3] then o[3].TextColor3=col end end) end; task.wait(0.05)
	else task.wait(0.3) end
end end)
local function readDinoInfo(model)
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
	for _,a in ipairs({"Stamina","Stam","Energy"}) do local v=model:GetAttribute(a); if v then stam=tostring(math.floor(tonumber(v) or 0)); break end end
	for _,a in ipairs({"Bleed","Bleeding","BleedDamage","Wound","Wounds","Bloodloss","Bleed_Damage"}) do local v=model:GetAttribute(a); if v then bleed=math.floor(tonumber(v) or 0); break end end
	-- FALLBACK ("i don't see their stam"): other dinos rarely carry attributes — their stats live as Number/IntValues
	-- inside the model (or on the MeshModel). Scan a bounded slice of descendants for health/stam/bleed value objects.
	if (not stam) or (not hpFrac) or (not bleed) then
		local scanned=0
		for _,v in ipairs(model:GetDescendants()) do
			scanned+=1; if scanned>400 then break end
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				local n=v.Name:lower()
				if not stam and (n:find("stam",1,true) or n=="energy" or n:find("endur",1,true)) then stam=tostring(math.floor(tonumber(v.Value) or 0))
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
	return species,growth,health,stam,bleed,hpFrac
end
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
							local sp,gr,hp,st,bl,hpf = readDinoInfo(m)
							local pl = Players:GetPlayerFromCharacter(m)
							-- always show the DINO SPECIES; for a player-controlled dino show their name on top + species under
							local label
							if pl and sp then label = pl.Name.."\n"..sp else label = (pl and pl.Name) or sp or m.Name end
							label = label.."\n["..math.floor(d).."m]"
							if gr then label=label.."\nStage: "..gr end
							if hp then label=label.."\nHP: "..hp end
							if st then label=label.."\nStam: "..st end
							if bl and bl>0 then label=label.."\nBlood: "..bl end
							addESP(m, pl and Color3.fromRGB(90,170,255) or Color3.fromRGB(120,220,120), label, hpf); count+=1
						end
					end
				end
			end
		end
	end
	-- CORPSES: models named "Corpse_..." (authoritative), PLUS any "Investigate" ProximityPrompt as a fallback.
	-- FOOD ESP runs this too — corpses ARE carnivore food, so Food ESP now highlights Corpse + food together.
	if CFG.ESPCorpses or CFG.FoodESP then
		local scanned=0
		for _,d in ipairs(WS:GetDescendants()) do
			if count>=MAX then break end
			scanned+=1; if scanned>5000 then break end
			local model
			if (d:IsA("Model") or d:IsA("Folder")) and d.Name:lower():find("corpse",1,true) then model=d
			elseif d:IsA("ProximityPrompt") then local at=(d.ActionText or ""):lower(); local nm=(d.Name or ""):lower()
				if at:find("investigate") or nm:find("investigate") or nm:find("corpse") then local p=d.Parent; model=(p and p:IsA("Model")) and p or (p and p:FindFirstAncestorWhichIsA("Model")) or p end
			end
			if model then
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
				elseif CFG.FoodESP and isFoodName(n) then local meat=(n:find("meat") or n:find("corpse") or n:find("carcass") or n:find("carrion") or n:find("chunk") or n:find("rotten") or n:find("flesh") or n:find("remains") or isFishName(n)); hit=true; color=meat and Color3.fromRGB(235,70,70) or Color3.fromRGB(120,235,90); tag=(meat and "Carnivore food: " or "Plant: ")..m.Name end
				if hit then local r=rootOf(m); if r then local d=dist(me.Position,r.Position); if d<=CFG.ESPRange then addESP(m,color,tag.." ["..math.floor(d).."m]"); count+=1 end end end
			end
		end
	end
end) end end)

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
task.spawn(function() local last=false; while RUNNING do task.wait(0.1); if CFG.Fly~=last then last=CFG.Fly; if CFG.Fly then startFly() else stopFly() end end end end)
conn(LP.CharacterAdded:Connect(function() task.wait(1); saving=false; SKN.saBack={}; pcall(function() CharacterState=CharacterState or (require(RS:WaitForChild("Common",5):WaitForChild("CharacterState",5))) end); if CFG.Fly then startFly() end pcall(function() local r=hrp(); if r then r.Anchored=false end end)
	-- ON SPAWN: fill food + water right away (fire the real eat/Sip sequences in a burst so you spawn topped up).
	task.spawn(function() task.wait(1.5); for _=1,10 do if not RUNNING then break end if CFG.InfFood and alive() then fakeEat() end if CFG.InfWater and alive() then fakeDrink() end task.wait(0.18) end end)
end))
local lastSkinDino=nil
task.spawn(function() while RUNNING do task.wait(2)
	local ok,dt,st = pcall(skGetCharInfo)
	if ok and dt and dt~=lastSkinDino then lastSkinDino=dt; if dinoLabel then dinoLabel.Text="Dino: "..tostring(dt).." | Stage: "..tostring(st) end if skinDropdownRef then skinDropdownRef.refresh() end end
end end)

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
notify("Dream Hub", "Prior Extinction loaded (everything OFF) — RightShift to toggle.")
print("[Dream Hub · Prior Extinction v6.1] Loaded — enemy-only hitbox (never yours), fixed restore camera+controls, BodyVelocity walk-on-water/anti-drown, server-side INF stam, food ESP highlights corpses, teleport farm, anti-injury report-block")
