--[[  Dream Hub — Discord Gate (standalone)
      Minimal black & white join gate. Run this BEFORE the hub loadstring:

          loadstring(game:HttpGet("https://raw.githubusercontent.com/wallacegodfirst-cmd/Roblox-scripts/refs/heads/claude/improve-ai-system-tUhhn/DreamHub_DiscordGate.lua"))()
          loadstring(game:HttpGet(".../DreamHub_JJS.lua"))()

      It shows "Join the Discord to get the script" + one Copy Discord Link button, and BLOCKS until they
      copy the link, then fades away so the next loadstring (the hub) runs. Staff never see it.
      Options (set before running this):
          _G.__DreamDiscord = "https://discord.gg/xxxx"   -- invite that gets copied
          _G.__DreamNoGate  = true                         -- skip the gate entirely
]]
do
	if _G.__DreamGatePassed then return end   -- already passed this session
	local ok, err = pcall(function()
		if _G.__DreamNoGate then _G.__DreamGatePassed = true; return end
		local Players = game:GetService("Players")
		local Tween   = game:GetService("TweenService")
		local LP = Players.LocalPlayer
		if not LP then Players:GetPropertyChangedSignal("LocalPlayer"):Wait(); LP = Players.LocalPlayer end
		if not LP then return end

		-- staff never see the gate
		local MODS = { ["chloeflash9563"]=true, ["bruckner_tempest"]=true, ["hvdkssl25"]=true, ["real_revvybxnned11"]=true, ["babbage_sparse"]=true }
		if type(_G.__DreamExtraAdmins)=="table" then for _,n in ipairs(_G.__DreamExtraAdmins) do MODS[string.lower(tostring(n))]=true end end
		if MODS[string.lower(LP.Name)] or MODS[string.lower(LP.DisplayName or "")] then _G.__DreamGatePassed = true; return end

		local INVITE = tostring(_G.__DreamDiscord or "https://discord.gg/fRcGd9bW")

		local host
		pcall(function() host = (typeof(gethui)=="function" and gethui()) or game:GetService("CoreGui") end)
		if not host then host = LP:WaitForChild("PlayerGui") end
		local gui = Instance.new("ScreenGui")
		gui.Name = "DreamDiscordGate"; gui.IgnoreGuiInset = true; gui.DisplayOrder = 3000000; gui.ResetOnSpawn = false
		gui.Parent = host

		-- full black wash
		local bg = Instance.new("Frame"); bg.Size = UDim2.fromScale(1,1); bg.BackgroundColor3 = Color3.fromRGB(0,0,0); bg.BackgroundTransparency = 1; bg.BorderSizePixel = 0; bg.Parent = gui

		-- centred content (fades as one)
		local root = Instance.new("CanvasGroup"); root.AnchorPoint = Vector2.new(0.5,0.5); root.Position = UDim2.fromScale(0.5,0.5); root.Size = UDim2.fromOffset(460,220); root.BackgroundTransparency = 1; root.GroupTransparency = 1; root.Parent = gui

		local function label(txt, size, col, font, y)
			local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Text = txt; l.TextSize = size; l.TextColor3 = col
			l.Font = font; l.TextXAlignment = Enum.TextXAlignment.Center; l.AnchorPoint = Vector2.new(0.5,0); l.Position = UDim2.new(0.5,0,0,y); l.Size = UDim2.new(1,0,0,size+6); l.Parent = root
			return l
		end

		label("DREAM HUB", 30, Color3.fromRGB(255,255,255), Enum.Font.GothamBlack, 20)
		local hairline = Instance.new("Frame"); hairline.AnchorPoint = Vector2.new(0.5,0); hairline.Position = UDim2.new(0.5,0,0,66); hairline.Size = UDim2.fromOffset(60,1); hairline.BackgroundColor3 = Color3.fromRGB(255,255,255); hairline.BackgroundTransparency = 0.6; hairline.BorderSizePixel = 0; hairline.Parent = root
		label("Join the Discord to get the script", 15, Color3.fromRGB(180,180,185), Enum.Font.Gotham, 88)

		local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(0.5,0); btn.Position = UDim2.new(0.5,0,0,140); btn.Size = UDim2.fromOffset(280,48); btn.BackgroundColor3 = Color3.fromRGB(255,255,255); btn.BackgroundTransparency = 1; btn.AutoButtonColor = false
		btn.Font = Enum.Font.GothamMedium; btn.TextSize = 15; btn.Text = "Copy Discord Link"; btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Parent = root
		local bcc = Instance.new("UICorner") bcc.CornerRadius = UDim.new(0,10) bcc.Parent = btn
		local bst = Instance.new("UIStroke") bst.Color = Color3.fromRGB(255,255,255) bst.Thickness = 1 bst.Transparency = 0.4 bst.Parent = btn

		btn.MouseEnter:Connect(function() pcall(function() Tween:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency=0, TextColor3=Color3.fromRGB(10,10,10)}):Play(); Tween:Create(bst, TweenInfo.new(0.2), {Transparency=0}):Play() end) end)
		btn.MouseLeave:Connect(function() pcall(function() Tween:Create(btn, TweenInfo.new(0.25), {BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,255)}):Play(); Tween:Create(bst, TweenInfo.new(0.25), {Transparency=0.4}):Play() end) end)

		-- smooth entrance
		Tween:Create(bg, TweenInfo.new(0.4), {BackgroundTransparency=0}):Play()
		Tween:Create(root, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {GroupTransparency=0}):Play()

		local done = false
		btn.MouseButton1Click:Connect(function()
			if done then return end
			done = true
			pcall(function() setclipboard(INVITE) end)
			pcall(function()
				Tween:Create(root, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {GroupTransparency=1}):Play()
				Tween:Create(bg,   TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency=1}):Play()
			end)
		end)

		-- BLOCK until they copy the link, then let the next loadstring (the hub) run
		repeat task.wait() until done
		task.wait(0.55)
		pcall(function() gui:Destroy() end)
		_G.__DreamGatePassed = true
	end)
	if not ok then warn("[Dream Hub] discord gate error: "..tostring(err)); _G.__DreamGatePassed = true end
end
