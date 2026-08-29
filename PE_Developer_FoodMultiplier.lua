--[[
    Dream Hub · Prior Extinction · Developer Food Multiplier
    Separate from PE Plus. Enter 1, any finite multiplier, or INF.
    The multiplier starts only after the game accepts a genuine Bite packet.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local ENV = (typeof(getgenv)=="function" and getgenv()) or _G

-- Mirrors the PE developer/admin list. This is a client-side convenience gate, not server-side licensing.
local DEVELOPERS = {
	chloeflash9563=true,
	bruckner_tempest=true,
	hvdkssl25=true,
	real_revvybxnned11=true,
	babbage_sparse=true,
	wallacegodfirst=true,
	wallacegodfirstcmd=true,
}

if not DEVELOPERS[string.lower(tostring(LP and LP.Name or ""))] then
	warn("[Dream Hub Dev Multiplier] This GUI is restricted to the PE developer allowlist.")
	return
end

if ENV.__PE_DEV_FOOD_MULT and ENV.__PE_DEV_FOOD_MULT.unload then
	pcall(ENV.__PE_DEV_FOOD_MULT.unload)
end

local state = {enabled=false, sending=false, burst=false, generation=0, sent=0, amount=1000}
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

label("PE Developer · Food Multiplier",12,24,17,Color3.fromRGB(93,235,145))
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

local hookmeta=hookmetamethod
local getnamecall=getnamecallmethod
local check=checkcaller or function() return false end
if typeof(hookmeta)~="function" or typeof(getnamecall)~="function" then
	status.Text="Executor does not support hooks"
	toggle.Active=false
	return
end

local oldNamecall
oldNamecall=hookmeta(game,"__namecall",function(self,...)
	local method=getnamecall()
	if method=="FireServer" and not check() and not state.sending and state.enabled and (self.Name=="ReplicaSignal" or self.Name=="ReplicaSignalUnreliable") then
		local args=table.pack(...)
		if args[2]=="Bite" and args.n>=3 and not state.burst then
			local result=oldNamecall(self,...)
			state.generation+=1
			local generation=state.generation
			local character=LP.Character
			local amount=state.amount
			state.burst=true
			status.Text="Bite accepted · sending "..(amount==math.huge and "INF" or tostring(math.max(amount-1,0)))
			task.defer(function()
				local sent=0
				while state.enabled and state.generation==generation and self.Parent and LP.Character==character and (amount==math.huge or sent<amount-1) do
					state.sending=true
					local ok=pcall(function() self:FireServer(table.unpack(args,1,args.n)) end)
					state.sending=false
					if ok then sent+=1; state.sent+=1 end
					if sent%3==0 then task.wait(0.025) end
				end
				state.sending=false
				if state.generation==generation then state.burst=false; status.Text=state.enabled and ("Finished · +"..tostring(sent)) or "Stopped" end
			end)
			return result
		end
	end
	return oldNamecall(self,...)
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
