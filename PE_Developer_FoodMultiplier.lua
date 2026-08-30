--[[
    Dream Hub · Prior Extinction · Developer Food Multiplier
    Separate from PE Plus. Enter 1, any finite multiplier, or INF.
    The multiplier starts only after the game accepts a genuine Bite packet.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local ENV = (typeof(getgenv)=="function" and getgenv()) or _G

-- Mirrors the PE developer/admin list for an on-screen owner marker only. This file is intentionally separate from
-- the public PE Plus loader, but a username gate cannot safely identify every account/alias the owner tests with.
-- Do not return before constructing the GUI: that was the reason the explicit developer loader appeared to do
-- nothing on an unlisted test account.
local DEVELOPERS = {
	chloeflash9563=true,
	bruckner_tempest=true,
	hvdkssl25=true,
	real_revvybxnned11=true,
	babbage_sparse=true,
	wallacegodfirst=true,
	wallacegodfirstcmd=true,
}
local recognizedDeveloper = DEVELOPERS[string.lower(tostring(LP and LP.Name or ""))]

if ENV.__PE_DEV_FOOD_MULT and ENV.__PE_DEV_FOOD_MULT.unload then
	pcall(ENV.__PE_DEV_FOOD_MULT.unload)
end

local state = {enabled=false, sending=false, burst=false, generation=0, sent=0, amount=1000, lastCapture=nil}
local connections = {}
ENV.__PE_DEV_FOOD_MULT = state

local gui = Instance.new("ScreenGui")
gui.Name = "PE_Developer_FoodMultiplier"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10020
pcall(function() gui.Parent = (typeof(gethui)=="function" and gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(350,190)
frame.Position = UDim2.new(0.5,-175,0.5,-95)
frame.BackgroundColor3 = Color3.fromRGB(20,23,29)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(67,211,124)
stroke.Thickness = 1.5
stroke.Parent = frame

local function label(text,y,height,size,color)
	local item=Instance.new("TextLabel")
	item.BackgroundTransparency=1
	item.Position=UDim2.fromOffset(16,y)
	item.Size=UDim2.new(1,-32,0,height)
	item.Font=Enum.Font.GothamMedium
	item.TextSize=size or 14
	item.TextColor3=color or Color3.fromRGB(225,230,238)
	item.TextXAlignment=Enum.TextXAlignment.Left
	item.Text=text
	item.Parent=frame
	return item
end

label("PE Developer · Food Multiplier"..(recognizedDeveloper and "" or " · private loader"),12,24,17,Color3.fromRGB(93,235,145))
label("Enter 1, any number, or INF",40,20,12,Color3.fromRGB(153,162,177))

local amountBox=Instance.new("TextBox")
amountBox.Position=UDim2.fromOffset(16,68)
amountBox.Size=UDim2.new(1,-32,0,38)
amountBox.BackgroundColor3=Color3.fromRGB(31,35,43)
amountBox.BorderSizePixel=0
amountBox.Font=Enum.Font.GothamBold
amountBox.TextSize=16
amountBox.TextColor3=Color3.fromRGB(240,243,248)
amountBox.PlaceholderText="1 - INF"
amountBox.Text="1000"
amountBox.ClearTextOnFocus=false
amountBox.Parent=frame
Instance.new("UICorner",amountBox).CornerRadius=UDim.new(0,8)

local toggle=Instance.new("TextButton")
toggle.Position=UDim2.fromOffset(16,116)
toggle.Size=UDim2.new(1,-32,0,34)
toggle.BackgroundColor3=Color3.fromRGB(49,55,66)
toggle.BorderSizePixel=0
toggle.Font=Enum.Font.GothamBold
toggle.TextSize=14
toggle.TextColor3=Color3.fromRGB(240,243,248)
toggle.Text="OFF"
toggle.Parent=frame
Instance.new("UICorner",toggle).CornerRadius=UDim.new(0,8)

local status=label("Waiting",158,20,12,Color3.fromRGB(153,162,177))
local function parseAmount()
	local raw=string.lower(amountBox.Text:gsub("%s+",""))
	if raw=="inf" or raw=="infinity" or raw=="infinite" or raw=="∞" then return math.huge,"INF" end
	local value=math.floor(tonumber(raw) or 1)
	value=math.clamp(value,1,1000000)
	return value,tostring(value)
end

local function setEnabled(on)
	state.generation+=1
	state.enabled=on
	state.burst=false
	state.sending=false
	state.amount=parseAmount()
	toggle.Text=on and "ON · bite once normally" or "OFF"
	toggle.BackgroundColor3=on and Color3.fromRGB(40,181,98) or Color3.fromRGB(49,55,66)
	status.Text=on and "Waiting for a genuine Bite" or "Stopped"
end

toggle.MouseButton1Click:Connect(function() setEnabled(not state.enabled) end)
amountBox.FocusLost:Connect(function()
	local value,display=parseAmount(); state.amount=value; amountBox.Text=display
	if state.enabled then state.generation+=1; state.burst=false; status.Text="New amount saved; bite normally" end
end)

local function copyPacket(source)
	local out={n=source.n or #source}; for i=1,out.n do out[i]=source[i] end; return out
end
local function remoteFor(packet)
	local events=ReplicatedStorage:FindFirstChild("RemoteEvents")
	return events and events:FindFirstChild(packet.remote or "ReplicaSignal")
end
local function beginBurst(remote,args,captureKey)
	if not (state.enabled and not state.burst and remote and remote.Parent and args and args[2]=="Bite" and (args.n or #args)>=3) then return false end
	state.lastCapture=captureKey or tostring(args[1])..":"..tostring(args[3])
	state.generation+=1
	local generation=state.generation
	local identity=ENV.MH_identityKey
	local character=LP.Character
	local amount=state.amount
	local bonus=amount==math.huge and math.huge or math.max(amount-1,0)
	state.burst=true
	status.Text="Bite captured · sending "..(bonus==math.huge and "INF" or tostring(bonus))
	task.defer(function()
		local sent=0
		while state.enabled and state.generation==generation and remote.Parent and (not identity or ENV.MH_identityKey==identity) and (identity or LP.Character==character) and (bonus==math.huge or sent<bonus) do
			state.sending=true
			local ok=pcall(function() remote:FireServer(table.unpack(args,1,args.n)) end)
			state.sending=false
			if ok then sent+=1; state.sent+=1 end
			if sent%3==0 then task.wait(0.025) end
		end
		state.sending=false
		if state.generation==generation then
			state.burst=false
			status.Text=state.enabled and (bonus==math.huge and ("INF stopped · "..tostring(sent).." sent") or ("Finished · +"..tostring(sent))) or "Stopped"
		end
	end)
	return true
end

-- Primary capture. Do not depend on checkcaller(): Volt and several mobile executors report genuine game-originated
-- namecalls as caller-owned, which made the old hook ignore every real Bite. Our own replays are explicitly guarded
-- by state.sending, and state.burst prevents another script's replay from starting a second burst.
local hookmeta=hookmetamethod
local getnamecall=getnamecallmethod
if typeof(hookmeta)=="function" and typeof(getnamecall)=="function" then
	local oldNamecall
	oldNamecall=hookmeta(game,"__namecall",function(self,...)
		local method=getnamecall()
		if method=="FireServer" and not state.sending and state.enabled and not state.burst and (self.Name=="ReplicaSignal" or self.Name=="ReplicaSignalUnreliable") then
			local args=table.pack(...)
			if args[2]=="Bite" and args.n>=3 then
				local result=oldNamecall(self,...)
				beginBurst(self,args,"hook:"..tostring(args[1])..":"..tostring(args[3]))
				return result
			end
		end
		return oldNamecall(self,...)
	end)
else
	status.Text="Hook unavailable · PE Plus capture fallback ready"
end

-- PE Plus independently records the exact genuine Bite in getgenv(). Polling that packet is a second capture route:
-- the developer multiplier still works when this executor misses chained hooks or reports caller ownership wrong.
task.spawn(function()
	while gui.Parent do
		if state.enabled and not state.burst then
			local captured=ENV.MH_lastEatCall
			if type(captured)=="table" and captured[2]=="Bite" and (captured.n or #captured)>=3 and (captured.identity==nil or captured.identity==ENV.MH_identityKey) then
				local key="plus:"..tostring(captured.identity)..":"..tostring(captured.capturedAt)..":"..tostring(captured[1])
				if key~=state.lastCapture then beginBurst(remoteFor(captured),copyPacket(captured),key) end
			end
		end
		task.wait(0.08)
	end
end)

local function cancelForDinosaurChange()
	state.generation+=1; state.burst=false; state.sending=false
	if state.enabled then status.Text="Dinosaur changed · bite normally" end
end
connections[#connections+1]=LP.CharacterAdded:Connect(cancelForDinosaurChange)
connections[#connections+1]=LP.CharacterRemoving:Connect(cancelForDinosaurChange)
local characters=workspace:FindFirstChild("Characters")
if characters then
	connections[#connections+1]=characters.ChildAdded:Connect(function(child) if child.Name==LP.Name then cancelForDinosaurChange() end end)
	connections[#connections+1]=characters.ChildRemoved:Connect(function(child) if child.Name==LP.Name then cancelForDinosaurChange() end end)
end

function state.unload()
	state.enabled=false
	state.generation+=1
	state.burst=false
	state.sending=false
	for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
	pcall(function() gui:Destroy() end)
end

print("[Dream Hub] PE Developer Food Multiplier loaded for "..LP.Name)
