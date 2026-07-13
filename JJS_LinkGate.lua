--[[  Dream Hub · JJS — Link Gate
      A small black window. To get the JJS script you copy the link, open it in your browser and complete it,
      then press "I Did It — Get Script" to load the hub. Load: loadstring(game:HttpGet("<this url>"))()  ]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local LINK = "https://rekonise.com/best-ability-arena-script-buy-right-now-8dr9r"
local SCRIPT_URL = "https://raw.githubusercontent.com/wallacegodfirst-cmd/roblox-scripts/claude/improve-ai-system-tUhhn/DreamHub_JJS_Free.lua"

-- ── host (works across executors) ────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "JJSGate"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

-- ── window ───────────────────────────────────────────────────────────────────
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 190)
main.Position = UDim2.new(0.5, -150, 0.5, -95)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
main.BorderSizePixel = 0
main.Active = true; main.Draggable = true   -- drag it anywhere
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(200, 25, 35); stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
title.Text = "Dream Hub · Get JJS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold; title.TextSize = 15
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 34)
info.Position = UDim2.fromOffset(10, 40)
info.BackgroundTransparency = 1
info.Text = "Open this link in your browser and complete it, then come back and press the button."
info.TextColor3 = Color3.fromRGB(190, 190, 190)
info.Font = Enum.Font.Gotham; info.TextSize = 12; info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = main

-- the link itself, in a selectable TextBox so it can be copied by hand too
local linkBox = Instance.new("TextBox")
linkBox.Size = UDim2.new(1, -20, 0, 30)
linkBox.Position = UDim2.fromOffset(10, 80)
linkBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
linkBox.Text = LINK
linkBox.TextColor3 = Color3.fromRGB(120, 200, 255)
linkBox.Font = Enum.Font.Code; linkBox.TextSize = 11
linkBox.ClearTextOnFocus = false; linkBox.TextEditable = false   -- selectable but not editable
linkBox.TextXAlignment = Enum.TextXAlignment.Left; linkBox.TextTruncate = Enum.TextTruncate.AtEnd
linkBox.Parent = main
Instance.new("UICorner", linkBox).CornerRadius = UDim.new(0, 6)
local lpad = Instance.new("UIPadding", linkBox); lpad.PaddingLeft = UDim.new(0, 8); lpad.PaddingRight = UDim.new(0, 8)

local function mkBtn(text, y, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -20, 0, 30)
	b.Position = UDim2.fromOffset(10, y)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamMedium; b.TextSize = 13
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = main
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local copyBtn = mkBtn("Copy Link", 118, Color3.fromRGB(35, 35, 40))
local goBtn   = mkBtn("I Did It — Get Script", 152, Color3.fromRGB(200, 25, 35))

-- Copy Link: put the link on the clipboard (executor setclipboard) + select it in the box as a fallback
copyBtn.MouseButton1Click:Connect(function()
	local ok = false
	pcall(function() if setclipboard then setclipboard(LINK); ok = true elseif toclipboard then toclipboard(LINK); ok = true end end)
	pcall(function() linkBox:CaptureFocus() end)   -- selects the text so you can Ctrl+C by hand too
	copyBtn.Text = ok and "Copied! Open it in your browser" or "Select the link above and Ctrl+C"
	task.delay(2.5, function() if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy Link" end end)
end)

-- Get Script: load the JJS Free hub, then close this gate
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
		task.delay(2, function() if goBtn and goBtn.Parent then goBtn.Text = "I Did It — Get Script" end end)
	end)
end)
