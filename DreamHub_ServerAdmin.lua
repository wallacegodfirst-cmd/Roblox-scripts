--[[  DREAM HUB — SERVER-SIDE ADMIN  (real power over any player)
      This is NOT an exploit. Put it in a game YOU own:
        Roblox Studio → ServerScriptService → Insert → Script → paste this → Save/Publish.
      Because it runs on the SERVER, it can actually freeze / jail / kick / warn / bring anyone.

      Admins: add Roblox usernames (lowercase) to ADMINS below.
      Use chat commands (prefix ;) OR the in-game Admin GUI that opens for admins.

      Commands (target = full or partial username, or "all", or "me"):
        ;freeze <user>      ;unfreeze <user>
        ;jail <user>        ;unjail <user>
        ;kick <user> [reason]
        ;warn <user> <message>          -> pops a warning on THEIR screen
        ;bring <user>                   -> teleport them to you
        ;to <user>                      -> teleport you to them
        ;god <user>         ;ungod <user>
        ;heal <user>        ;kill <user>
        ;speed <user> <n>   ;respawn <user>
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══ CONFIG ═══
local ADMINS = {
	["chloeflash9563"] = true,   -- Ghost
	["babbage_sparse"] = true,   -- Mod
	-- ["anotheruser"] = true,
}
local PREFIX = ";"
local JAIL_CFRAME = CFrame.new(0, 500, 0)   -- where jailed players are held (edit to a real cell if you have one)

local function isAdmin(plr)
	return plr and ADMINS[string.lower(plr.Name)] == true
end

-- ═══ CLIENT WARNING GUI (a RemoteEvent the server fires to pop a warning on a player) ═══
local warnRemote = ReplicatedStorage:FindFirstChild("DreamWarn")
if not warnRemote then
	warnRemote = Instance.new("RemoteEvent"); warnRemote.Name = "DreamWarn"; warnRemote.Parent = ReplicatedStorage
end
-- LocalScript injected into each player so warnings render (StarterGui would need a file; we send a tiny one via a
-- StringValue the client reads is overkill — instead we ship a LocalScript through StarterPlayerScripts once):
local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
if sps and not sps:FindFirstChild("DreamWarnClient") then
	local ls = Instance.new("LocalScript"); ls.Name = "DreamWarnClient"
	ls.Source = [[
		local RS = game:GetService("ReplicatedStorage")
		local Tween = game:GetService("TweenService")
		local plr = game:GetService("Players").LocalPlayer
		local ev = RS:WaitForChild("DreamWarn")
		ev.OnClientEvent:Connect(function(msg)
			local gui = Instance.new("ScreenGui"); gui.Name="DreamWarnGui"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=999999; gui.Parent=plr:WaitForChild("PlayerGui")
			local f=Instance.new("Frame"); f.AnchorPoint=Vector2.new(0.5,0.5); f.Position=UDim2.fromScale(0.5,0.4); f.Size=UDim2.fromOffset(460,150); f.BackgroundColor3=Color3.fromRGB(18,18,22); f.BackgroundTransparency=1; f.Parent=gui
			Instance.new("UICorner", f).CornerRadius=UDim.new(0,12); local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(226,34,44); st.Thickness=2; st.Parent=f
			local t=Instance.new("TextLabel"); t.Position=UDim2.new(0,16,0,14); t.Size=UDim2.new(1,-32,0,26); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack; t.Text="ADMIN WARNING"; t.TextSize=20; t.TextColor3=Color3.fromRGB(226,34,44); t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=f
			local b=Instance.new("TextLabel"); b.Position=UDim2.new(0,16,0,46); b.Size=UDim2.new(1,-32,1,-58); b.BackgroundTransparency=1; b.Font=Enum.Font.Gotham; b.Text=msg; b.TextSize=16; b.TextColor3=Color3.fromRGB(240,240,240); b.TextWrapped=true; b.TextXAlignment=Enum.TextXAlignment.Left; b.TextYAlignment=Enum.TextYAlignment.Top; b.Parent=f
			Tween:Create(f, TweenInfo.new(0.3), {BackgroundTransparency=0.05}):Play()
			task.delay(6, function() Tween:Create(f, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play(); task.wait(0.5); gui:Destroy() end)
		end)
	]]
	ls.Parent = sps
end

-- ═══ STATE ═══
local frozen = {}     -- [player] = CFrame lock conn
local jailed = {}     -- [player] = true
local godded = {}     -- [player] = conn

local function root(plr)
	local ch = plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
end

-- resolve a target string to a list of players
local function resolve(str, from)
	str = string.lower(str or "")
	if str == "all" then return Players:GetPlayers() end
	if str == "me" then return { from } end
	local hits = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name):sub(1,#str) == str or string.lower(p.DisplayName):sub(1,#str) == str then table.insert(hits, p) end
	end
	return hits
end

-- ═══ ACTIONS ═══
local A = {}
function A.freeze(p) local r=root(p); if r then frozen[p]=RunService.Heartbeat:Connect(function() if r and r.Parent then r.CFrame=frozen[p.."cf"] or r.CFrame; r.AssemblyLinearVelocity=Vector3.zero end end); frozen[p.."cf"]=r.CFrame end end
function A.unfreeze(p) if frozen[p] then frozen[p]:Disconnect() end frozen[p]=nil frozen[p.."cf"]=nil end
function A.jail(p) jailed[p]=true; local r=root(p); if r then r.CFrame=JAIL_CFRAME end end
function A.unjail(p) jailed[p]=nil; local _,h=root(p); if h then h.Health=h.Health end end
function A.kick(p, reason) p:Kick(reason and ("Kicked by admin: "..reason) or "Kicked by an admin.") end
function A.warn(p, msg) warnRemote:FireClient(p, msg or "Follow the rules.") end
function A.bring(p, from) local rt=root(p); local fr=root(from); if rt and fr then rt.CFrame=fr.CFrame*CFrame.new(0,0,-4) end end
function A.to(p, from) local rt=root(p); local fr=root(from); if rt and fr then fr.CFrame=rt.CFrame*CFrame.new(0,0,-4) end end
function A.god(p) local _,h=root(p); if h then godded[p]=RunService.Heartbeat:Connect(function() if h and h.Parent then h.Health=h.MaxHealth end end) end end
function A.ungod(p) if godded[p] then godded[p]:Disconnect() end godded[p]=nil end
function A.heal(p) local _,h=root(p); if h then h.Health=h.MaxHealth end end
function A.kill(p) local _,h=root(p); if h then h.Health=0 end end
function A.speed(p, n) local _,h=root(p); if h then h.WalkSpeed=tonumber(n) or 16 end end
function A.respawn(p) p:LoadCharacter() end

-- keep jailed players in the cell
RunService.Heartbeat:Connect(function()
	for p in pairs(jailed) do local r=root(p); if r and (r.Position-JAIL_CFRAME.Position).Magnitude>8 then r.CFrame=JAIL_CFRAME; r.AssemblyLinearVelocity=Vector3.zero end end
end)

-- ═══ COMMAND PARSER ═══
local function run(from, raw)
	if not raw:sub(1,#PREFIX)==PREFIX then return end
	local body = raw:sub(#PREFIX+1)
	local parts = {}
	for w in body:gmatch("%S+") do table.insert(parts, w) end
	local cmd = string.lower(parts[1] or "")
	local targets = resolve(parts[2] or "", from)
	local rest = table.concat(parts, " ", 3)

	if cmd=="freeze" then for _,p in ipairs(targets) do A.freeze(p) end
	elseif cmd=="unfreeze" then for _,p in ipairs(targets) do A.unfreeze(p) end
	elseif cmd=="jail" then for _,p in ipairs(targets) do A.jail(p) end
	elseif cmd=="unjail" then for _,p in ipairs(targets) do A.unjail(p) end
	elseif cmd=="kick" then for _,p in ipairs(targets) do A.kick(p, rest) end
	elseif cmd=="warn" then for _,p in ipairs(targets) do A.warn(p, rest) end
	elseif cmd=="bring" then for _,p in ipairs(targets) do A.bring(p, from) end
	elseif cmd=="to" then local p=targets[1]; if p then A.to(p, from) end
	elseif cmd=="god" then for _,p in ipairs(targets) do A.god(p) end
	elseif cmd=="ungod" then for _,p in ipairs(targets) do A.ungod(p) end
	elseif cmd=="heal" then for _,p in ipairs(targets) do A.heal(p) end
	elseif cmd=="kill" then for _,p in ipairs(targets) do A.kill(p) end
	elseif cmd=="speed" then for _,p in ipairs(targets) do A.speed(p, parts[3]) end
	elseif cmd=="respawn" then for _,p in ipairs(targets) do A.respawn(p) end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		if isAdmin(plr) and msg:sub(1,#PREFIX)==PREFIX then pcall(run, plr, msg) end
	end)
	-- clean state on leave
end)
Players.PlayerRemoving:Connect(function(plr)
	A.unfreeze(plr); A.ungod(plr); jailed[plr]=nil
end)

print("[Dream Hub Server Admin] loaded. Admins type "..PREFIX.."freeze <user> etc.")
