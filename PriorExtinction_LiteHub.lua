--[[  Prior Extinction — Lite Hub  ·  INF Food · Alert Dino · Auto Play Bot
      Extracted (verbatim logic) from Dream Hub · Prior Extinction.
      Load with: loadstring(game:HttpGet("<url>"))()  ]]

print("[PE Lite] booting")   -- ASCII diagnostic: if you see this in F9 but no menu, send the red error line under it
local __gg = (typeof(getgenv)=="function") and getgenv() or _G
if __gg.__PE_LITE_HUB then pcall(__gg.__PE_LITE_HUB) end
__gg.__PE_LITE_HUB = nil

-- ═══ SERVICES ═══
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local RS           = game:GetService("ReplicatedStorage")
local WS           = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local LP           = Players.LocalPlayer
local Cam          = WS.CurrentCamera

-- ═══ EXECUTOR COMPAT ═══
local writefile   = writefile
local readfile    = readfile
local isfile      = isfile
local fireprox    = fireproximityprompt
local hookmeta    = hookmetamethod
local getnamecall = getnamecallmethod
local checkcaller = checkcaller or function() return false end
local function safeParentGui(gui)
	pcall(function()
		if typeof(gethui)=="function" then gui.Parent = gethui()
		elseif typeof(syn)=="table" and syn.protect_gui then syn.protect_gui(gui); gui.Parent = CoreGui
		else gui.Parent = CoreGui end
	end)
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
end

-- ═══ CONFIG ═══ (trimmed to only the keys these three features read; all features START OFF)
local CFG = {
	AutoPlayBot=false,
	BotFlee=true, BotFleeRange=240, BotRoam=true, BotRoamRadius=350, BotEatAt=80, BotDrinkAt=80, BotSleepHeal=true, BotSpeed=18, BotAnnounce=true,
	InfFood=false, InfWater=false, InfStam=false,
	AutoEatFood=true, FoodEatRange=120, FoodEatSpeed=3,
	AlertEnabled=false, AlertDino="", AlertRange=350,
	Fly=false, SpeedHack=false,
	AccentIndex=1, UIScale=1,
}
local FILE = "PriorExtinction_LiteConfig.json"
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
-- EVERYTHING OFF ON EXECUTION = clean start, zero lag (no loop runs until YOU enable a feature).
for _,key in ipairs({"AutoPlayBot","InfFood","AlertEnabled"}) do CFG[key]=false end

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
	local c=char(); if not c then return hrp()~=nil end  -- PE dinos: LP.Character is often nil but the body lives at workspace.Characters[name]
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
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=title or "PE Lite", Text=text or "", Duration=3}) end)
end
local function holdKey(kc, dur)
	pcall(function() VIM:SendKeyEvent(true, kc, false, game); task.wait(dur or 0.08); VIM:SendKeyEvent(false, kc, false, game) end)
end

-- ═══ FOOD DATABASE ═══
local FOOD_KEYWORDS = {
	"corpse","carcass","rotten","meat","chunk","fish","egg","ant","food","fruit","berry","berries","plant","sapling","tree","fern",
	"lepisosteus","gar","acipenser","onchopristis","alligator gar","anthill","termite","meganeura",
	"blechnace","blechnaceae","gleichenia","osmunda","horsetail","dawn redwood","redwood","zingiberopsis","ditaxocladus",
	"gingko","ginkgo","sequoia","woodwardia","sabalite","marmarthia","equisetum","coniopteris","paleoaster","dryophyllum",
	"elatides","dicksonia","williamsonia","wielandiella","weichselia","ptilophyllum","pachypteris","matonidium","hermanophyton","cycadeoidea",
	"pine","needle","needles","leaf","leaves","frond","conifer","cycad","araucaria","podocarp","bennettit","fungus","mushroom",
	"shoot","sprout","grass","moss","bush","shrub","flower","seed","cone","insect","grub","larva","carrion","sturgeon","bichir","coelacanth","mawsonia",
}
local function isFoodName(n)
	n = n:lower()
	for _,k in ipairs(FOOD_KEYWORDS) do if n:find(k,1,true) then return true end end
	return false
end

-- ═══ DINO NAME DATABASE (drives Alert Dino picker + species detection) ═══
local SKINS = {
	["Acrocanthosaurus"]=true,["Allosaurus"]=true,["Arbovenator"]=true,["Austroraptor"]=true,["Bistahieversor"]=true,
	["Carcharodontosaurus"]=true,["Carnotaurus"]=true,["Ceratosaurus"]=true,["Concavenator"]=true,["Dearc"]=true,
	["Deinonychus"]=true,["Deinosuchus"]=true,["Dilophosaurus"]=true,["Dynamotitan"]=true,["Guanlong"]=true,
	["Ichthyovenator"]=true,["Machimosaurus"]=true,["Mahajangasuchus"]=true,["Sarcosuchus"]=true,["Saurophaganax"]=true,
	["Spinosaurus Aegyptiacus"]=true,["Spinosaurus Maroccanus"]=true,["Suchomimus"]=true,["Tarbosaurus"]=true,["Therodontosaurus"]=true,
	["Torvosaurus"]=true,["Tyrannosaurus Rex"]=true,["Tyrannosaurus Alaskaensis"]=true,["Utahraptor"]=true,["Yangchuanosaurus"]=true,
	["Acanthocaudia"]=true,["Amphiceratops"]=true,["Ankylosaurus"]=true,["Apatosaurus"]=true,["Brachiosaurus"]=true,
	["Camptosaurus"]=true,["Dacentrurus"]=true,["Diabloceratops"]=true,["Diplodocus"]=true,["Dreadnoughtus"]=true,
	["Edmontosaurus"]=true,["Iguanodon"]=true,["Kentrosaurus"]=true,["Ouranosaurus"]=true,["Pachycephalosaurus"]=true,
	["Pachyrhinosaurus"]=true,["Parasaurolophus"]=true,["Protoceratops"]=true,["Sauropelta"]=true,["Sauroposeidon"]=true,
	["Scelidosaurus"]=true,["Senticephale"]=true,["Stegosaurus"]=true,["Styracosaurus"]=true,["Tenontosaurus"]=true,
	["Tethyshadros"]=true,["Therizinosaurus"]=true,["Triceratops"]=true,["Tsintaosaurus"]=true,["Yunnanosaurus"]=true,
	["Beipiaosaurus"]=true,["Citipati"]=true,["Deinocheirus"]=true,["Gallimimus"]=true,["Gigantoraptor"]=true,
	["Jianchangosaurus"]=true,["Pteranodon"]=true,["Quetzalcoatlus"]=true,["Tupandactylus"]=true,
}
local DINO_NAMES = {}
for k in pairs(SKINS) do DINO_NAMES[#DINO_NAMES+1]=k end
table.sort(DINO_NAMES)
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

-- ═══ REPLICA ID CAPTURE (lightweight namecall hook — food-id capture only) ═══
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
			-- HOT PATH: getnamecall() first, bail for the 99% of namecalls that aren't FireServer.
			local m = getnamecall and getnamecall()
			if m=="FireServer" and self.Name=="ReplicaSignal" and not checkcaller() then
				local a = table.pack(...)
				local id, action = a[1], a[2]
				-- Capture OUR dino id ONLY from SELF actions. Sip/Bite/Eat fire with a SOURCE id → seenIds only.
				if typeof(id)=="number" then
					if action=="Sip" or action=="Bite" or action=="Eat" or action=="Consume" then
						if not seenSet[id] then seenSet[id]=true; seenIds[#seenIds+1]=id end
						if action=="Bite" and a.n>=3 then __gg.MH_eat={id=id,buf=a[3]}; __gg.MH_foodIds=__gg.MH_foodIds or {}; if id~=myReplicaId then __gg.MH_foodIds[id]=true; __gg.MH_eatBuf=a[3] end end   -- collect EVERY food id you bite so INF Food replays them all
					else
						noteReplicaId(id)  -- self action = our dino id
					end
				end
			end
			return oldNC(self, ...)
		end)
	end)
end
pcall(installHook)

-- ═══ REAL GAME REMOTES ═══
local RCACHE = {}
local CharacterState
pcall(function() local cm=RS:FindFirstChild("Common"); local cs=cm and cm:FindFirstChild("CharacterState"); if cs then CharacterState=require(cs) end end)
local function csReplica() return CharacterState and CharacterState.Replica end
local function csStats() local r=csReplica(); if r and r.Data then return r.Data.Stats, r.Data.MaxStats end end
-- REPLICA ID FALLBACK (no-hook executors): read our dino id from CharacterState.Replica when the hook didn't capture it.
task.spawn(function() while RUNNING do task.wait(1)
	if not myReplicaId then pcall(function()
		local r=csReplica()
		local id = r and (r.Id or (rawget and rawget(r,"Id")) or (r.Data and (r.Data.Id or r.Data.ReplicaId)))
		if typeof(id)~="number" and CharacterState then id = CharacterState.Id or CharacterState.ReplicaId end
		if typeof(id)=="number" then noteReplicaId(id) end
	end) end
end end)
local function getReplicaSignal()
	if RCACHE.sig and RCACHE.sig.Parent then return RCACHE.sig end
	local re = RS:FindFirstChild("RemoteEvents")
	if re then RCACHE.sig = re:FindFirstChild("ReplicaSignal") end
	return RCACHE.sig
end
-- SELF action: fire ReplicaSignal as the player's own replica (id = myReplicaId).
local function replicaFire(...)
	local a=table.pack(...)
	local rs=getReplicaSignal(); if not rs then return false end
	local id = myReplicaId or seenIds[1]
	if id then return (pcall(function() rs:FireServer(id, table.unpack(a,1,a.n)) end)) end
	local f=false; for _,sid in ipairs(seenIds) do pcall(function() rs:FireServer(sid, table.unpack(a,1,a.n)) end); f=true end
	return f
end
-- BROADCAST: fire with EVERY captured replica id (for source-targeted actions like "Sip"/"Bite").
local function replicaActionAll(...)
	local a=table.pack(...)
	local rs=getReplicaSignal(); if not rs then return false end
	local f=false
	if myReplicaId then pcall(function() rs:FireServer(myReplicaId, table.unpack(a,1,a.n)) end); f=true end
	for _,id in ipairs(seenIds) do if id~=myReplicaId then pcall(function() rs:FireServer(id, table.unpack(a,1,a.n)) end); f=true end end
	return f
end
local function replicaAction(...) return replicaFire(...) end
-- WATER/FOOD source ids per land: fire to all so the current map's id always lands (map-wide INF Food/Water).
local WATER_IDS = { ["Cretaceous Lowland"]=3028, ["Cretaceous Archipelago"]=3251, ["Jurassic"]=2910, ["Cretaceous Upland"]=2195 }
local function fakeDrink()
	local rs=getReplicaSignal(); if not rs then return end
	for _,id in pairs(WATER_IDS) do pcall(function() rs:FireServer(id, "Sip") end) end
	replicaActionAll("Sip")
	replicaActionAll("SetAction","Drinking",true)
	replicaActionAll("SetAction","Drinking",false)
end
-- FOOD: the FULL captured eat sequence:
--   (dinoId,"SetAction","Consuming",true) → (sourceId,"Bite",buffer) → (dinoId,"SetAction","Consuming",false)
--   → (dinoId,"AnimationEnded","Eat"). Buffer captured = "\027\206\000\000\001".
local EAT_BUFFER = "\027\206\000\000\001"
local function fakeEat()
	local rs=getReplicaSignal(); if not rs then return end
	replicaFire("SetAction","Consuming",true)              -- dino: start eating
	local cap = __gg.MH_eat
	local buf = (type(cap)=="table" and cap.buf~=nil) and cap.buf or __gg.MH_eatBuf or EAT_BUFFER
	if type(buf)=="string" and buffer and buffer.fromstring then pcall(function() buf = buffer.fromstring(buf) end) end
	if type(cap)=="table" and cap.id then pcall(function() rs:FireServer(cap.id, "Bite", cap.buf or buf) end) end
	-- MULTI-ID REPLAY: re-fire Bite to EVERY food id you've bitten this session, FoodEatSpeed times each. Capped.
	local foodIds = __gg.MH_foodIds
	if type(foodIds)=="table" and next(foodIds) then
		local fired=0; local speed=math.clamp(tonumber(CFG.FoodEatSpeed) or 3, 1, 10)
		for foodId in pairs(foodIds) do
			for _=1,speed do pcall(function() rs:FireServer(foodId, "Bite", buf) end); fired+=1; task.wait(0.03); if fired>=12 then break end end
			if fired>=12 then break end
		end
	end
	for _,id in pairs(WATER_IDS) do pcall(function() rs:FireServer(id, "Bite", buf) end) end  -- every land's source id
	replicaActionAll("Bite", buf)                          -- + every captured source id
	replicaFire("SetAction","Consuming",false)             -- dino: stop consuming
	replicaFire("AnimationEnded","Eat")                    -- dino: finish (food gained)
end

-- ═══ CHARACTER / HITBOX HELPERS ═══
local function getMyModel()
	if LP.Character and LP.Character.Parent then return LP.Character end
	local ch = WS:FindFirstChild("Characters")
	if ch then local m = ch:FindFirstChild(LP.Name); if m then return m end end
	return nil
end
local function getHitbox(model)
	model = model or getMyModel()
	if not model then return nil end
	for _,n in ipairs({"Hitbox","HitBox","HitboxPart","Hit"}) do
		local hb=model:FindFirstChild(n); if hb and hb:IsA("BasePart") then return hb end
	end
	local ta=model:FindFirstChild("TurningAnimation"); if ta then local b=ta:FindFirstChild("Body"); if b and b:IsA("BasePart") then return b end end
	if model.PrimaryPart then return model.PrimaryPart end
	return rootOf(model)
end

-- ═══ NEARBY FOOD SCANNER ═══
local FARM = {tried={}, food={t=0,list={}}}
local function nearbyFood(range)
	if tick()-FARM.food.t < 3 then return FARM.food.list end  -- 3s cache — lighter
	local me=hrp(); local out={}; local seen={}
	if me then
		local cnt=0
		-- 1) Investigate prompts = real PE corpses (E to consume). Authoritative carnivore food.
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

-- ═══ GUI FRAMEWORK (small self-contained window) ═══
local UIFONT = Enum.Font.GothamMedium
local ACCENTS = {
	Color3.fromRGB(46,196,110), Color3.fromRGB(40,170,230), Color3.fromRGB(120,200,60),
	Color3.fromRGB(235,185,40), Color3.fromRGB(140,110,240), Color3.fromRGB(240,110,90),
}
local T = {
	Main=Color3.fromRGB(243,244,247), Panel=Color3.fromRGB(255,255,255), Panel2=Color3.fromRGB(248,249,251), Panel3=Color3.fromRGB(237,239,243),
	Top=Color3.fromRGB(255,255,255), Stroke=Color3.fromRGB(225,228,234), Text=Color3.fromRGB(36,40,50), Sub=Color3.fromRGB(118,126,140), Muted=Color3.fromRGB(158,166,178),
	Accent=ACCENTS[CFG.AccentIndex] or ACCENTS[1], On=ACCENTS[CFG.AccentIndex] or ACCENTS[1], Off=Color3.fromRGB(205,210,218), DarkRed=Color3.fromRGB(225,228,234),
}
local function C(cls, props) local o = Instance.new(cls); for k,v in pairs(props or {}) do if k~="Parent" then o[k]=v end end if props and props.Parent then o.Parent=props.Parent end return o end
local function corner(o,r) C("UICorner",{Parent=o, CornerRadius=UDim.new(0,r or 6)}) end
local function stroke(o,col,th) C("UIStroke",{Parent=o, Color=col or T.Stroke, Thickness=th or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function pad(o,l,r,t,b) C("UIPadding",{Parent=o, PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0), PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0)}) end
local function lay(o,padpx,dir) return C("UIListLayout",{Parent=o, Padding=UDim.new(0,padpx or 6), SortOrder=Enum.SortOrder.LayoutOrder, FillDirection=dir or Enum.FillDirection.Vertical}) end
local function tw(o,goal,t) pcall(function() TweenService:Create(o, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad), goal):Play() end) end

local SG = C("ScreenGui",{Name="PriorExtLite", Enabled=true, ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true})
safeParentGui(SG)
local MF = C("Frame",{Parent=SG, Size=UDim2.fromOffset(320,0), Position=UDim2.new(0.5,-160,0.5,-180), BackgroundColor3=T.Main, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y}); corner(MF,6); stroke(MF,T.Stroke,1)
C("UIScale",{Parent=MF, Scale=math.clamp(tonumber(CFG.UIScale) or 1,0.5,3)})
local TB = C("Frame",{Parent=MF, Size=UDim2.new(1,0,0,42), BackgroundColor3=T.Top, BorderSizePixel=0}); corner(TB,6)
C("Frame",{Parent=TB, Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2), BackgroundColor3=T.Accent, BorderSizePixel=0})
C("TextLabel",{Parent=TB, Position=UDim2.fromOffset(14,0), Size=UDim2.new(1,-56,1,0), BackgroundTransparency=1, Text="Prior Extinction — Lite", TextColor3=T.Text, TextSize=14, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
local closeBtn = C("TextButton",{Parent=TB, Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-34,0.5,-13), BackgroundColor3=T.Panel2, Text="X", TextColor3=T.Accent, TextSize=12, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0}); corner(closeBtn,4); stroke(closeBtn,T.Stroke,1)
closeBtn.MouseButton1Click:Connect(function() SG.Enabled=false end)
local Body = C("Frame",{Parent=MF, Position=UDim2.fromOffset(0,42), Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y})
local Content = C("Frame",{Parent=Body, Size=UDim2.new(1,-20,0,0), Position=UDim2.fromOffset(10,8), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}); lay(Content,6); pad(Content,0,0,0,10)
C("TextLabel",{Parent=MF, Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, Text=""})  -- spacer anchor
-- draggable
do
	local dragging, dragStart, startPos
	TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=MF.Position end end)
	TB.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
	conn(UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			local d=i.Position-dragStart
			MF.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
		end
	end))
end
-- widgets
local toggleRefs = {}
local function mkToggle(par, txt, key, ord)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,28), BackgroundColor3=T.Panel, BorderSizePixel=0, LayoutOrder=ord or 0}); corner(row,4); stroke(row,T.Stroke,1)
	C("TextLabel",{Parent=row, Position=UDim2.fromOffset(10,0), Size=UDim2.new(1,-56,1,0), BackgroundTransparency=1, Text=txt, TextColor3=T.Text, TextSize=12, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	local tr = C("TextButton",{Parent=row, Size=UDim2.fromOffset(34,18), Position=UDim2.new(1,-42,0.5,-9), BackgroundColor3=CFG[key] and T.On or T.Off, AutoButtonColor=false, Text="", BorderSizePixel=0}); corner(tr,9)
	local kn = C("Frame",{Parent=tr, Size=UDim2.fromOffset(14,14), Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}); corner(kn,999)
	toggleRefs[key]={tr,kn}
	tr.MouseButton1Click:Connect(function()
		CFG[key]=not CFG[key]
		tw(tr,{BackgroundColor3=CFG[key] and T.On or T.Off}); tw(kn,{Position=CFG[key] and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)})
		saveCfg(); notify("PE Lite", txt..": "..(CFG[key] and "ON" or "OFF"))
	end)
	return row
end
local function mkSlider(par, txt, key, mn, mx, ord, step)
	local row = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,38), BackgroundColor3=T.Panel, BorderSizePixel=0, LayoutOrder=ord or 0}); corner(row,4); stroke(row,T.Stroke,1)
	local lbl = C("TextLabel",{Parent=row, Position=UDim2.fromOffset(10,4), Size=UDim2.new(1,-20,0,14), BackgroundTransparency=1, Text=txt..": "..tostring(CFG[key]), TextColor3=T.Text, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left})
	local bar = C("Frame",{Parent=row, Size=UDim2.new(1,-20,0,8), Position=UDim2.fromOffset(10,22), BackgroundColor3=T.Panel3, BorderSizePixel=0}); corner(bar,3); stroke(bar,T.Stroke,1)
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
local function mkDropdown(par, label, getOptions, getSelected, onSelect, ord)
	local wrap = C("Frame",{Parent=par, Size=UDim2.new(1,0,0,46), BackgroundColor3=T.Panel, BorderSizePixel=0, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=ord or 0}); corner(wrap,4); stroke(wrap,T.Stroke,1)
	local inWrap = C("Frame",{Parent=wrap, Size=UDim2.new(1,-16,0,0), Position=UDim2.fromOffset(8,6), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y}); lay(inWrap,4); pad(inWrap,0,0,0,6)
	C("TextLabel",{Parent=inWrap, Size=UDim2.new(1,0,0,14), BackgroundTransparency=1, Text=label, TextColor3=T.Sub, TextSize=11, Font=UIFONT, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0})
	local head = C("TextButton",{Parent=inWrap, Size=UDim2.new(1,0,0,24), BackgroundColor3=T.Panel3, Text=(getSelected() or "-").."   v", TextColor3=T.Text, TextSize=12, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=1}); corner(head,4); stroke(head,T.Stroke,1)
	local listBox = C("Frame",{Parent=inWrap, Size=UDim2.new(1,0,0,0), BackgroundColor3=T.Panel, BorderSizePixel=0, Visible=false, AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=2}); corner(listBox,4); stroke(listBox,T.Stroke,1)
	local inner = C("ScrollingFrame",{Parent=listBox, Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=T.Accent})
	pad(inner,4,4,4,4); lay(inner,3)
	local open=false
	local function rebuild()
		for _,c in ipairs(inner:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local opts = getOptions() or {}
		inner.Size = UDim2.new(1,0,0,math.min(#opts*22+8, 150))
		for i,opt in ipairs(opts) do
			local ob = C("TextButton",{Parent=inner, Size=UDim2.new(1,0,0,20), BackgroundColor3=T.Panel2, Text=opt, TextColor3=T.Text, TextSize=11, Font=UIFONT, AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=i}); corner(ob,4)
			ob.MouseButton1Click:Connect(function() onSelect(opt); head.Text=(getSelected() or "-").."   v"; open=false; listBox.Visible=false end)
		end
	end
	head.MouseButton1Click:Connect(function() open=not open; listBox.Visible=open; if open then rebuild() end end)
end

-- ═══ BUILD THE MENU ═══
mkToggle(Content,"INF Food","InfFood",1)
mkToggle(Content,"Alert Dino","AlertEnabled",2)
mkDropdown(Content,"Alert Dino (pick species)", function() return DINO_NAMES end, function() return CFG.AlertDino~="" and CFG.AlertDino or "(pick a dino)" end, function(opt) CFG.AlertDino=opt; saveCfg() end, 3)
mkSlider(Content,"Alert Range","AlertRange",100,2000,4,50)
mkToggle(Content,"Auto Play Bot","AutoPlayBot",5)
mkSlider(Content,"Bot walk speed","BotSpeed",14,24,6,1)
mkSlider(Content,"Eat below %","BotEatAt",30,95,7,5)
mkSlider(Content,"Drink below %","BotDrinkAt",30,95,8,5)
C("TextLabel",{Parent=Content, Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text="RightShift to toggle menu", TextColor3=T.Muted, TextSize=10, Font=UIFONT, LayoutOrder=20})

-- ═══ INF FOOD LOOP (fakeEat + AutoEatFood prompt firing) ═══
task.spawn(function() while RUNNING do
	if CFG.InfFood and alive() then
		fakeEat()
		if CFG.AutoEatFood then
			-- Eat the NEAREST food/corpse: fire its prompt ONCE (per-corpse 3s cooldown). One corpse per pass.
			local me=hrp(); local list=nearbyFood(CFG.FoodEatRange)
			if me then for _,fd in ipairs(list) do
				local m,r,prompt=fd[1],fd[2],fd.prompt
				if not prompt and m then for _,d in ipairs(m:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d; break end end end
				if prompt and r and r.Parent and dist(me.Position,r.Position)<=math.min(CFG.FoodEatRange,40) then
					local kk="food_"..tostring(prompt); local last=FARM.tried[kk]
					if not last or tick()-last>3 then
						FARM.tried[kk]=tick()
						pcall(function() prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=math.huge end)
						if fireprox then pcall(function() fireprox(prompt) end) end
					end
					break
				end
			end end
		end
		task.wait(0.4)
	else task.wait(0.4) end
end end)

-- ═══ DANGER ALERT: pick a dino; flash a red hazard warning when that species is near ═══
do
	local A = {}
	A.gui = C("ScreenGui",{Name="PriorExtLite_Alert", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=9999}); safeParentGui(A.gui)
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

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════
-- AUTO PLAY BOT v2 — a full survival AI that PLAYS THE GAME for you (priority-driven state machine).
--   1 FLEE · 2 DRINK · 3 EAT · 4 REST/HEAL · 5 ROAM. Movement HOLDS real WASD toward the goal.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════
do   -- scoped block: the bot's locals live only here (keeps the chunk under Luau's 200-local register cap)
local BOT = {
	state="idle", home=nil, goal=nil, goalWhy="", target=nil, threat=nil,
	lastAnnounce=0, lastState="", stuckPos=nil, stuckT=0, unstuckUntil=0, roamWait=0,
	sleeping=false, waterPos=nil, dietSaid=false, prevF=nil, prevW=nil, prevS=nil,
}
local function botSay(msg)
	if not CFG.BotAnnounce then return end
	if tick()-BOT.lastAnnounce<1.5 then return end
	BOT.lastAnnounce=tick()
	pcall(function() notify("Auto Play Bot", msg) end)
end
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
local _botDataCtrl
local function dinoDataController()   -- Knit DataController -> DinosaursData (species stats incl. Diet.Categories)
	if _botDataCtrl then return _botDataCtrl end
	pcall(function()
		local pkg=RS:FindFirstChild("Packages"); local km=pkg and pkg:FindFirstChild("Knit")
		if km then local K=require(km); if K and K.GetController then _botDataCtrl=K.GetController("DataController") end end
	end)
	return _botDataCtrl
end
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
local function isCorpseFood(m, prompt)
	local nm=tostring(m and m.Name or ""):lower()
	if nm:find("corpse") or nm:find("carcass") or nm:find("remains") or nm:find("carrion") or nm:find("dead") or nm:find("meat") then return true end
	if m and m.GetAttribute then local ok,a=pcall(function() return m:GetAttribute("DinoType") or m:GetAttribute("HintType") or m:GetAttribute("CreatedAt") end); if ok and a then return true end end
	if prompt then local at=(prompt.ActionText or ""):lower(); if at:find("investigate") or at:find("examine") then return true end end
	return false
end
local function edibleFor(diet, corpse)
	if diet=="Herbivore" then return not corpse
	elseif diet=="Carnivore" then return corpse and true or false
	else return true end
end
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
	if not best and (diet=="Carnivore" or diet=="Omnivore") and __gg.MH_nearestMeat then
		local m,part,d=__gg.MH_nearestMeat(900)
		if part then best,bpart,bprompt,bd=m,part,nil,d end
	end
	return best,bpart,bprompt,bd
end
local function botNearWater()
	local nearW=false
	if CharacterState then pcall(function() nearW = CharacterState.FoundWater==true or typeof(CharacterState.WaterLevel)=="number" end) end
	return nearW
end
-- MOVEMENT DRIVE — HOLD W/A/S/D toward the goal (fields on BOT, not new locals, to respect the 200-local cap).
BOT.kc = {W=Enum.KeyCode.W, A=Enum.KeyCode.A, S=Enum.KeyCode.S, D=Enum.KeyCode.D}
BOT.held = BOT.held or {}
function BOT.setKey(name, down)
	if BOT.held[name]==down then return end
	BOT.held[name]=down
	pcall(function() VIM:SendKeyEvent(down, BOT.kc[name], false, game) end)
end
function BOT.releaseKeys() for n in pairs(BOT.kc) do BOT.setKey(n,false) end end
__gg.MH_botReleaseKeys = BOT.releaseKeys
function BOT.driveToward(desFlat)
	if not desFlat or desFlat.Magnitude<0.05 then BOT.releaseKeys(); return end
	local des=Vector3.new(desFlat.X,0,desFlat.Z); if des.Magnitude<0.05 then BOT.releaseKeys(); return end; des=des.Unit
	local cf=Cam.CFrame
	local look=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z); if look.Magnitude<0.05 then BOT.releaseKeys(); return end; look=look.Unit
	local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
	local fwd=des:Dot(look); local rgt=des:Dot(right)
	BOT.setKey("W", fwd> 0.35); BOT.setKey("S", fwd< -0.35)
	BOT.setKey("D", rgt> 0.35); BOT.setKey("A", rgt< -0.35)
end
conn(RunService.Heartbeat:Connect(function()
	if not (CFG.AutoPlayBot and alive()) then if next(BOT.held) then BOT.releaseKeys() end return end
	if CFG.Fly or CFG.SpeedHack then BOT.releaseKeys(); return end
	local r=hrp(); if not r then BOT.releaseKeys(); return end
	local goal=BOT.goal
	if BOT.sleeping or not goal then BOT.releaseKeys(); return end
	local to=goal-r.Position; local flat=Vector3.new(to.X,0,to.Z)
	if flat.Magnitude<4 then BOT.releaseKeys(); return end
	if tick()<BOT.unstuckUntil then
		local side=flat.Unit:Cross(Vector3.yAxis)
		BOT.driveToward((flat.Unit*0.5+side*0.85))
		pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game); VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
	else
		BOT.driveToward(flat)
	end
end))
-- STUCK WATCHDOG: barely moved for ~3s → unstick hop + re-path.
task.spawn(function() while RUNNING do task.wait(1)
	if CFG.AutoPlayBot and alive() and BOT.goal and not BOT.sleeping then
		local r=hrp()
		if r then
			if BOT.stuckPos and tick()-BOT.stuckT>=3 then
				if (r.Position-BOT.stuckPos).Magnitude<3 then
					BOT.unstuckUntil=tick()+1.2
					if BOT.state=="roam" then BOT.goal=nil end
					botSay("Stuck — hopping around the obstacle.")
				end
				BOT.stuckPos=r.Position; BOT.stuckT=tick()
			elseif not BOT.stuckPos then BOT.stuckPos=r.Position; BOT.stuckT=tick() end
		end
	else BOT.stuckPos=nil end
end end)
-- SLEEP CONTROL: hold Sleep while resting (server heals you), release the instant we stop.
task.spawn(function() local was=false while RUNNING do task.wait(0.4)
	local want=CFG.AutoPlayBot and alive() and BOT.sleeping or false
	if want and not was then was=true
		pcall(function() local r=hrp(); if r then r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0) end end)
		pcall(function() replicaAction("SetAction","Sleep",true) end)
	elseif want then
		pcall(function() replicaAction("SetAction","Sleep",true) end)
	elseif was then was=false
		pcall(function() replicaAction("SetAction","Sleep",false) end)
	end
end end)
-- THE BRAIN: priority evaluation ~3x/sec.
task.spawn(function()
	while RUNNING do
		if CFG.AutoPlayBot and alive() then
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
				-- ── 1. FLEE ──
				if threat and throot then
					BOT.sleeping=false
					BOT.state="flee"; BOT.threat=threat
					local away=(me.Position-throot.Position); away=Vector3.new(away.X,0,away.Z)
					if away.Magnitude<1 then away=Vector3.new(1,0,0) end
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
				-- ── 2. DRINK ──
				elseif waterF and waterF<drinkAt then
					BOT.sleeping=false; BOT.state="drink"
					fakeDrink()
					if botNearWater() then
						BOT.goal=nil
						BOT.waterPos=me.Position
						holdKey(Enum.KeyCode.E, 0.3)
					elseif BOT.waterPos then
						BOT.goal=BOT.waterPos
					else
						BOT.goal=nil
					end
					if BOT.lastState~="drink" then BOT.lastState="drink"; botSay("Thirsty ("..math.floor(waterF*100).."%) — drinking.") end
				-- ── 3. EAT ──
				elseif foodF and foodF<eatAt then
					BOT.sleeping=false; BOT.state="eat"
					fakeEat()
					local fm,fpart,fprompt,fd=botNearestFood()
					if fpart then
						if fd<=14 then
							BOT.goal=nil
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
						if not BOT.goal or BOT.state~="eat" then
							local a=math.random()*math.pi*2
							BOT.goal=me.Position+Vector3.new(math.cos(a),0,math.sin(a))*150
						end
						if BOT.lastState~="eat" then BOT.lastState="eat"; botSay("Hungry — searching for food…") end
					end
				-- ── 4. REST / HEAL ──
				elseif CFG.BotSleepHeal and hpF and hpF<0.6 then
					BOT.state="rest"; BOT.goal=nil; BOT.sleeping=true
					if BOT.lastState~="rest" then BOT.lastState="rest"; botSay("Hurt ("..math.floor(hpF*100).."% HP) — sleeping it off.") end
				-- ── 5. ROAM ──
				elseif CFG.BotRoam then
					BOT.sleeping=false; BOT.state="roam"
					local arrived = (not BOT.goal) or (Vector3.new(BOT.goal.X-me.Position.X,0,BOT.goal.Z-me.Position.Z).Magnitude<8)
					if arrived then
						if tick()>BOT.roamWait then
							if BOT.goal then BOT.roamWait=tick()+2+math.random()*5; BOT.goal=nil
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
			-- bot off / dead → clean shutdown: restore the user's own INF toggles
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

-- ═══ INPUT: RightShift toggles the menu ═══
conn(UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType~=Enum.UserInputType.Keyboard then return end
	if input.KeyCode==Enum.KeyCode.RightShift then SG.Enabled=not SG.Enabled end
end))
-- ON SPAWN: fill food + water right away (burst the real eat/Sip sequences so you spawn topped up).
conn(LP.CharacterAdded:Connect(function() task.wait(1)
	pcall(function() CharacterState=CharacterState or (require(RS:WaitForChild("Common",5):WaitForChild("CharacterState",5))) end)
	task.spawn(function() task.wait(1.5); for _=1,10 do if not RUNNING then break end if CFG.InfFood and alive() then fakeEat() end if CFG.InfWater and alive() then fakeDrink() end task.wait(0.18) end end)
end))

notify("Prior Extinction — Lite", "Loaded · RightShift for menu")
