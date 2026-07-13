--[[  Dream Hub · JJS — Link Gate  (black / red Dream Hub theme, small)
      Copy the link, open it in your browser and complete it, then press the red button to load the hub.
      Load: loadstring(game:HttpGet("<this url>"))()  ]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local LINK = "https://rekonise.com/jjs-free-script-jpqps"
local SCRIPT_URL = "https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/DreamHub_JJS_Free.lua"

local RED   = Color3.fromRGB(220, 30, 40)
local RED_D = Color3.fromRGB(150, 18, 26)
local BG    = Color3.fromRGB(14, 14, 16)
local PANEL = Color3.fromRGB(22, 22, 26)

-- ── host (works across executors) ────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "JJSGate"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local function corner(p, r) local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c end

-- ── window ───────────────────────────────────────────────────────────────────
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 210)
main.Position = UDim2.new(0.5, -150, 0.5, -105)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true; main.Draggable = true
main.Parent = gui
corner(main, 12)
-- soft red glow / shadow behind the window
local glow = Instance.new("ImageLabel")
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://5028857084"; glow.ImageColor3 = RED; glow.ImageTransparency = 0.55
glow.ScaleType = Enum.ScaleType.Slice; glow.SliceCenter = Rect.new(24, 24, 276, 276)
glow.Size = UDim2.new(1, 40, 1, 40); glow.Position = UDim2.fromOffset(-20, -20)
glow.ZIndex = 0
glow.Parent = main
local stroke = Instance.new("UIStroke", main); stroke.Color = RED; stroke.Thickness = 1.5; stroke.Transparency = 0.15
-- subtle vertical gradient on the body
local bgGrad = Instance.new("UIGradient", main)
bgGrad.Rotation = 90
bgGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,24)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,12)) })

-- ── header ───────────────────────────────────────────────────────────────────
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
header.BorderSizePixel = 0
header.Parent = main
corner(header, 12)
local hFix = Instance.new("Frame")   -- square off the bottom of the header
hFix.Size = UDim2.new(1, 0, 0, 12); hFix.Position = UDim2.new(0, 0, 1, -12)
hFix.BackgroundColor3 = Color3.fromRGB(18, 18, 20); hFix.BorderSizePixel = 0; hFix.Parent = header
local hGrad = Instance.new("UIGradient", header)
hGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28,20,21)), ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,20)) })
-- red accent bar under the header
local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, -20, 0, 2); accent.Position = UDim2.new(0, 10, 1, -1)
accent.BackgroundColor3 = RED; accent.BorderSizePixel = 0; accent.Parent = header
corner(accent, 2)
-- little red dot logo
local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(10, 10); dot.Position = UDim2.fromOffset(14, 15)
dot.BackgroundColor3 = RED; dot.BorderSizePixel = 0; dot.Parent = header
corner(dot, 5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0); title.Position = UDim2.fromOffset(32, 0)
title.BackgroundTransparency = 1
title.Text = "DREAM HUB  ·  GET JJS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold; title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- ── body ─────────────────────────────────────────────────────────────────────
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 32); info.Position = UDim2.fromOffset(12, 48)
info.BackgroundTransparency = 1
info.Text = "Open the link below in your browser and complete it, then press the red button."
info.TextColor3 = Color3.fromRGB(185, 185, 190)
info.Font = Enum.Font.Gotham; info.TextSize = 12; info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left; info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = main

local linkBox = Instance.new("TextBox")
linkBox.Size = UDim2.new(1, -24, 0, 30); linkBox.Position = UDim2.fromOffset(12, 86)
linkBox.BackgroundColor3 = PANEL
linkBox.Text = LINK
linkBox.TextColor3 = Color3.fromRGB(120, 200, 255)
linkBox.Font = Enum.Font.Code; linkBox.TextSize = 11
linkBox.ClearTextOnFocus = false; linkBox.TextEditable = false
linkBox.TextXAlignment = Enum.TextXAlignment.Left; linkBox.TextTruncate = Enum.TextTruncate.AtEnd
linkBox.Parent = main
corner(linkBox, 6)
local lStroke = Instance.new("UIStroke", linkBox); lStroke.Color = Color3.fromRGB(45,45,52); lStroke.Thickness = 1
local lpad = Instance.new("UIPadding", linkBox); lpad.PaddingLeft = UDim.new(0, 8); lpad.PaddingRight = UDim.new(0, 8)

local function mkBtn(text, y, base, accented)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -24, 0, 32); b.Position = UDim2.fromOffset(12, y)
	b.BackgroundColor3 = base
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamMedium; b.TextSize = 13
	b.Text = text; b.AutoButtonColor = false
	b.Parent = main
	corner(b, 6)
	if accented then
		local g = Instance.new("UIGradient", b)
		g.Rotation = 90
		g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, RED), ColorSequenceKeypoint.new(1, RED_D) })
	else
		local st = Instance.new("UIStroke", b); st.Color = Color3.fromRGB(50,50,58); st.Thickness = 1
	end
	-- hover feedback
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = accented and Color3.fromRGB(235,45,55) or Color3.fromRGB(40,40,48)}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = base}):Play() end)
	return b
end

local copyBtn = mkBtn("Copy Link", 126, Color3.fromRGB(30, 30, 36), false)
local goBtn   = mkBtn("I Did It  —  Get Script", 164, RED, true)

copyBtn.MouseButton1Click:Connect(function()
	local ok = false
	pcall(function() if setclipboard then setclipboard(LINK); ok = true elseif toclipboard then toclipboard(LINK); ok = true end end)
	pcall(function() linkBox:CaptureFocus() end)
	copyBtn.Text = ok and "Copied!  Open it in your browser" or "Select the link above and Ctrl+C"
	task.delay(2.5, function() if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy Link" end end)
end)

goBtn.MouseButton1Click:Connect(function()
	goBtn.Text = "Loading JJS..."
	task.spawn(function()
		local src
		for _ = 1, 4 do
			pcall(function() src = game:HttpGet(SCRIPT_URL .. "?cb=" .. tostring(math.floor(os.clock() * 100000))) end)
			if type(src) == "string" and #src > 100000 then break end
			task.wait(1)
		end
		if type(src) == "string" and #src > 100000 then
			local fn = loadstring(src)
			if type(fn) == "function" then
				gui:Destroy()
				local ok, err = pcall(fn)
				if not ok then warn("[JJS Gate] script error: " .. tostring(err)) end
				return
			end
		end
		goBtn.Text = "Fetch failed — try again"
		task.delay(2, function() if goBtn and goBtn.Parent then goBtn.Text = "I Did It  —  Get Script" end end)
	end)
end)

-- gentle pop-in
main.Size = UDim2.fromOffset(0, 0)
TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(300, 210)}):Play()
