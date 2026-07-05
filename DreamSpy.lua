-- ============================================================
-- Dream Spy  -  standalone recorder for someone else's script
-- Captures, while RECORDING:
--   * REMOTES  - every RemoteEvent/RemoteFunction :FireServer/:InvokeServer with its args (the "coding")
--   * ANIMS    - every animation your character plays (id + priority)  -> do ONLY the dash to grab the dash anim
--   * IMAGES   - every NEW GUI image that appears (the LOCK-ON ICON, indicators, etc.)
-- Record -> do the thing in-game (their dash / lock-on) -> Stop -> Copy.
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local LP                 = Players.LocalPlayer

local recording   = false
local remoteLines = {}
local animLines   = {}
local imageLines  = {}
local seenImg     = {}
local hookOK      = false

local function myChar() local chs = workspace:FindFirstChild("Characters"); return (chs and chs:FindFirstChild(LP.Name)) or LP.Character end
local function animatorOf() local c = myChar(); local h = c and c:FindFirstChildOfClass("Humanoid"); return h and h:FindFirstChildOfClass("Animator") end

-- ---------- value -> short string (for remote args) ----------
local function short(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "Instance" then return v.ClassName .. "(" .. v.Name .. ")"
	elseif t == "Vector3" then return string.format("Vector3(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
	elseif t == "CFrame" then local p = v.Position; return string.format("CFrame(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
	elseif t == "table" then
		if depth > 1 then return "{...}" end
		local parts = {}
		for k, val in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. short(val, depth + 1); if #parts >= 8 then parts[#parts + 1] = "..."; break end end
		return "{" .. table.concat(parts, ", ") .. "}"
	elseif t == "string" then return '"' .. v .. '"'
	else return tostring(v) end
end

-- ---------- GUI ----------
local sg = Instance.new("ScreenGui")
sg.Name = "DreamSpy"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.DisplayOrder = 9900
pcall(function() sg.Parent = (gethui and gethui()) or CoreGui end)
if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(360, 360); frame.Position = UDim2.new(0, 30, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 19); frame.BorderSizePixel = 0
frame.Active = true; frame.Draggable = true; frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(120, 80, 255); st.Thickness = 1.5; st.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 28); title.Position = UDim2.fromOffset(12, 6); title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold; title.Text = "Dream Spy  -  Recorder"; title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = frame

local hookLbl = Instance.new("TextLabel")
hookLbl.Size = UDim2.new(1, -16, 0, 14); hookLbl.Position = UDim2.fromOffset(12, 30); hookLbl.BackgroundTransparency = 1
hookLbl.Font = Enum.Font.Gotham; hookLbl.TextSize = 10; hookLbl.TextXAlignment = Enum.TextXAlignment.Left; hookLbl.Parent = frame

local function mkBtn(text, x, w, color, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 26); b.Position = UDim2.fromOffset(x, y or 48)
	b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamSemibold; b.TextSize = 12; b.AutoButtonColor = true; b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end
local recBtn   = mkBtn("Record", 12, 78, Color3.fromRGB(60, 170, 90))
local copyBtn  = mkBtn("Copy All", 96, 78, Color3.fromRGB(80, 90, 200))
local copyAnim = mkBtn("Copy Anims", 180, 82, Color3.fromRGB(70, 130, 200))
local clearBtn = mkBtn("Clear", 268, 78, Color3.fromRGB(150, 60, 60))

-- category filter
local filterMode = "All"
local filtBtn = mkBtn("Filter: All", 12, 110, Color3.fromRGB(45, 48, 60), 80)

local box = Instance.new("ScrollingFrame")
box.Size = UDim2.new(1, -20, 1, -118); box.Position = UDim2.fromOffset(10, 112)
box.BackgroundColor3 = Color3.fromRGB(9, 9, 12); box.BorderSizePixel = 0; box.ScrollBarThickness = 4
box.CanvasSize = UDim2.new(0, 0, 0, 0); box.AutomaticCanvasSize = Enum.AutomaticSize.Y; box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 1); layout.Parent = box
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 6); pad.PaddingTop = UDim.new(0, 4); pad.Parent = box

local function addRow(text, color)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -8, 0, 15); l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code; l.Text = text; l.TextColor3 = color or Color3.fromRGB(210, 210, 220)
	l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = false
	l.AutomaticSize = Enum.AutomaticSize.Y; l.Parent = box
	box.CanvasPosition = Vector2.new(0, math.huge)
end

-- ---------- capture: REMOTES (namecall hook) ----------
local inHook = false
local function logRemote(remote, method, args)
	if not recording or inHook then return end
	inHook = true
	local ok, path = pcall(function() return remote:GetFullName() end)
	inHook = false
	local argStr = {}
	for i = 1, #args do argStr[i] = short(args[i]) end
	local line = string.format("%s:%s(%s)", (ok and path) or remote.Name, method, table.concat(argStr, ", "))
	remoteLines[#remoteLines + 1] = line
	if filterMode == "All" or filterMode == "Remotes" then addRow("[REMOTE] " .. line, Color3.fromRGB(120, 220, 130)) end
end

do
	local ok = pcall(function()
		if not (hookmetamethod and getnamecallmethod) then error("no hook") end
		local original
		original = hookmetamethod(game, "__namecall", function(self, ...)
			if not inHook and recording then
				local ok2, method = pcall(getnamecallmethod)
				if ok2 and (method == "FireServer" or method == "InvokeServer") then
					local cls = rawget and nil or nil
					local okc, c = pcall(function() return self.ClassName end)
					if okc and (c == "RemoteEvent" or c == "RemoteFunction" or c == "UnreliableRemoteEvent") then
						pcall(logRemote, self, method, { ... })
					end
				end
			end
			return original(self, ...)
		end)
	end)
	hookOK = ok
	hookLbl.Text = ok and "Remote hook: ON (captures the coding)" or "Remote hook: NOT available on this executor (anims + images still work)"
	hookLbl.TextColor3 = ok and Color3.fromRGB(120, 220, 130) or Color3.fromRGB(230, 160, 80)
end

-- ---------- capture: ANIMATIONS ----------
local hookedAnim = setmetatable({}, { __mode = "k" })
local function hookAnims()
	local a = animatorOf(); if not a or hookedAnim[a] then return end
	hookedAnim[a] = a.AnimationPlayed:Connect(function(track)
		if not recording then return end
		local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+"); if not id then return end
		local line = string.format("rbxassetid://%s   [%s]", id, tostring(track.Animation and track.Animation.Name or "?"))
		animLines[#animLines + 1] = line
		if filterMode == "All" or filterMode == "Anims" then addRow("[ANIM]   " .. line, Color3.fromRGB(150, 190, 255)) end
	end)
end
task.spawn(function() while true do pcall(hookAnims) task.wait(0.5) end end)

-- ---------- capture: NEW GUI IMAGES (lock-on icon etc.) ----------
task.spawn(function()
	while true do
		task.wait(0.3)
		if recording then
			for _, root in ipairs({ sg.Parent, LP:FindFirstChild("PlayerGui"), workspace:FindFirstChild("Effects") }) do
				if root then
					for _, d in ipairs(root:GetDescendants()) do
						if d ~= frame and (d:IsA("ImageLabel") or d:IsA("ImageButton") or d:IsA("Decal")) then
							local img = d.Image or d.Texture
							if img and img ~= "" and not seenImg[img] then
								seenImg[img] = true
								local id = tostring(img):match("%d+")
								local line = (id and ("rbxassetid://" .. id) or img) .. "   (" .. d.Name .. ")"
								imageLines[#imageLines + 1] = line
								if filterMode == "All" or filterMode == "Images" then addRow("[IMAGE]  " .. line, Color3.fromRGB(255, 200, 90)) end
							end
						end
					end
				end
			end
		end
	end
end)

-- ---------- buttons ----------
local function fullText()
	local t = { "===== REMOTES =====" }
	for _, l in ipairs(remoteLines) do t[#t + 1] = l end
	t[#t + 1] = ""; t[#t + 1] = "===== ANIMATIONS ====="
	for _, l in ipairs(animLines) do t[#t + 1] = l end
	t[#t + 1] = ""; t[#t + 1] = "===== IMAGES ====="
	for _, l in ipairs(imageLines) do t[#t + 1] = l end
	return table.concat(t, "\n")
end
local function copyOut(text, btn)
	local ok = false
	pcall(function() if setclipboard then setclipboard(text); ok = true end end)
	if not ok then print("===== Dream Spy =====\n" .. text) end
	local old = btn.Text; btn.Text = ok and "Copied!" or "-> F9"
	task.delay(1.2, function() btn.Text = old end)
end

recBtn.MouseButton1Click:Connect(function()
	recording = not recording
	recBtn.Text = recording and "Stop" or "Record"
	recBtn.BackgroundColor3 = recording and Color3.fromRGB(200, 70, 70) or Color3.fromRGB(60, 170, 90)
	if recording then hookAnims() end
end)
copyBtn.MouseButton1Click:Connect(function() copyOut(fullText(), copyBtn) end)
copyAnim.MouseButton1Click:Connect(function() copyOut(table.concat(animLines, "\n"), copyAnim) end)
clearBtn.MouseButton1Click:Connect(function()
	remoteLines, animLines, imageLines, seenImg = {}, {}, {}, {}
	for _, c in ipairs(box:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
end)
filtBtn.MouseButton1Click:Connect(function()
	local order = { "All", "Remotes", "Anims", "Images" }
	local i = table.find(order, filterMode) or 1
	filterMode = order[(i % #order) + 1]
	filtBtn.Text = "Filter: " .. filterMode
	-- re-render current filter
	for _, c in ipairs(box:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	if filterMode == "All" or filterMode == "Remotes" then for _, l in ipairs(remoteLines) do addRow("[REMOTE] " .. l, Color3.fromRGB(120, 220, 130)) end end
	if filterMode == "All" or filterMode == "Anims"   then for _, l in ipairs(animLines)   do addRow("[ANIM]   " .. l, Color3.fromRGB(150, 190, 255)) end end
	if filterMode == "All" or filterMode == "Images"  then for _, l in ipairs(imageLines)  do addRow("[IMAGE]  " .. l, Color3.fromRGB(255, 200, 90)) end end
end)

print("[Dream Spy] loaded. Record -> do the dash / lock-on -> Stop -> Copy. Draggable window.")
