-- JJS Black Flash Chain module (recovered)
local BlackFlashChain = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local AnimationTriggers = {
    ["rbxassetid://100962226150441"] = 0.19,
    ["rbxassetid://95852624447551"]  = 0.19,
    ["rbxassetid://74145636023952"]  = 0.19,
    ["rbxassetid://72475960800126"]  = 0.20,
}

local StraightAnimations = {
    ["rbxassetid://123171106092050"] = true,
}

BlackFlashChain.Settings = {
    Duration      = 0.25,
    Radius        = 3,
    Range         = 25,
    CurveStrength = 14,
    CamOffset     = 4,
    Keybind       = Enum.KeyCode.E,
}

local autoBlackFlashChainActive = true
local curveGlideConn = nil
local recentBfAnimId = nil
local recentBfAnimAt = 0
local currentAnimatorConnection = nil
local inputConnection = nil

local function pressKey_BF(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function getHRP_BF(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
end

local function getNearestPlayer(maxRange)
    local myHRP = getHRP_BF(player.Character)
    if not myHRP then return nil end
    
    local nearest, nearestDist = nil, maxRange
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character and pl.Character:FindFirstChild("Humanoid") and pl.Character.Humanoid.Health > 0 then
            local tHRP = getHRP_BF(pl.Character)
            if tHRP then
                local dist = (myHRP.Position - tHRP.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = pl
                end
            end
        end
    end
    return nearest
end

local function isEnemyRagdolled(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    local hrp = getHRP_BF(targetPlayer.Character)
    if hum and hrp then
        return hum:GetState() == Enum.HumanoidStateType.Physics or math.abs(hrp.CFrame.UpVector.Y) < 0.7
    end
    return false
end

local function getActiveAnimId()
    local chr = player.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local id = track.Animation.AnimationId
            if AnimationTriggers[id] or StraightAnimations[id] then 
                return id 
            end
        end
    end
    return nil
end

local function startCurveGlide()
    if not autoBlackFlashChainActive then return end

    if curveGlideConn then
        curveGlideConn:Disconnect()
        curveGlideConn = nil
    end

    local target = getNearestPlayer(BlackFlashChain.Settings.Range)
    local myChar = player.Character
    local myHRP  = getHRP_BF(myChar)
    local hum    = myChar and myChar:FindFirstChildOfClass("Humanoid")

    local activeAnimId = getActiveAnimId()
    if not activeAnimId and (tick() - recentBfAnimAt) <= 0.9 then
        activeAnimId = recentBfAnimId
    end

    if target and isEnemyRagdolled(target) then return end
    if not (target and myHRP and hum) then return end

    local tHRP = getHRP_BF(target.Character)
    if not tHRP or not tHRP.Parent then return end

    local goStraight = activeAnimId and StraightAnimations[activeAnimId] == true
    local startTime  = tick()
    local startPos   = Vector3.new(myHRP.Position.X, 0, myHRP.Position.Z)
    local targetPos  = Vector3.new(tHRP.Position.X,  0, tHRP.Position.Z)
    local behindDir  = Vector3.new(tHRP.CFrame.LookVector.X, 0, tHRP.CFrame.LookVector.Z).Unit
    local endPos     = targetPos - behindDir * BlackFlashChain.Settings.Radius

    local controlPt
    if not goStraight then
        local mid      = (startPos + endPos) / 2
        local toTarget = targetPos - startPos
        local flatDist = toTarget.Magnitude
        local dirNorm  = flatDist > 0.1 and (toTarget / flatDist) or Vector3.new(1, 0, 0)
        local perp     = Vector3.new(-dirNorm.Z, 0, dirNorm.X)
        controlPt      = mid + perp * math.max(BlackFlashChain.Settings.CurveStrength, flatDist * 0.6, 8)
    end

    hum.AutoRotate = false
    local prevCam  = Camera.CameraType
    Camera.CameraType = Enum.CameraType.Custom

    curveGlideConn = RunService.Heartbeat:Connect(function()
        if not autoBlackFlashChainActive then
            if curveGlideConn then curveGlideConn:Disconnect() end
            curveGlideConn = nil
            if hum then hum.AutoRotate = true end
            Camera.CameraType = prevCam
            return
        end
        
        local alpha = math.clamp((tick() - startTime) / BlackFlashChain.Settings.Duration, 0, 1)
        if alpha >= 1 or not tHRP.Parent then
            if curveGlideConn then curveGlideConn:Disconnect() end
            curveGlideConn = nil
            if hum then hum.AutoRotate = true end
            Camera.CameraType = prevCam
            return
        end
        
        local t  = 1 - (1 - alpha)^2
        local t1 = 1 - t
        local movePos
        
        if goStraight then
            movePos = Vector3.new(startPos.X+(endPos.X-startPos.X)*t, myHRP.Position.Y, startPos.Z+(endPos.Z-startPos.Z)*t)
        else
            movePos = Vector3.new((t1*t1)*startPos.X+(2*t1*t)*controlPt.X+(t*t)*endPos.X, myHRP.Position.Y, (t1*t1)*startPos.Z+(2*t1*t)*controlPt.Z+(t*t)*endPos.Z)
        end
        
        myHRP.CFrame  = CFrame.new(movePos, Vector3.new(tHRP.Position.X, movePos.Y, tHRP.Position.Z))
        Camera.CFrame = CFrame.new(myHRP.Position + Vector3.new(0, BlackFlashChain.Settings.CamOffset, 0), tHRP.Position)
    end)
end

local function setupBlackFlashOnCharacter(character)
    if not character then return end
    
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    local animator = nil
    local attempts = 0
    while not animator and attempts < 30 do
        animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            attempts += 1
            task.wait(0.1)
        end
    end
    
    if not animator then return end
    
    if currentAnimatorConnection then
        pcall(function() currentAnimatorConnection:Disconnect() end)
        currentAnimatorConnection = nil
    end
    
    currentAnimatorConnection = animator.AnimationPlayed:Connect(function(track)
        local animId = track.Animation.AnimationId
        local delayTime = AnimationTriggers[animId]
        if not delayTime and StraightAnimations[animId] then 
            delayTime = 0.19 
        end
        
        if delayTime then
            recentBfAnimId = animId
            recentBfAnimAt = tick()
            
            task.delay(delayTime, function()
                if autoBlackFlashChainActive then
                    pressKey_BF(Enum.KeyCode.Three)
                end
            end)
        end
    end)
end

function BlackFlashChain:Execute()
    if not autoBlackFlashChainActive then return end
    
    task.spawn(function()
        pressKey_BF(Enum.KeyCode.Three)
        task.wait(0.2)
        startCurveGlide()
    end)
end

function BlackFlashChain:SetEnabled(enabled)
    autoBlackFlashChainActive = enabled
    if not enabled then
        if curveGlideConn then
            curveGlideConn:Disconnect()
            curveGlideConn = nil
        end
    end
end

function BlackFlashChain:IsEnabled()
    return autoBlackFlashChainActive
end

function BlackFlashChain:SetKeybind(key)
    if typeof(key) == "EnumItem" then
        BlackFlashChain.Settings.Keybind = key
    elseif type(key) == "string" then
        BlackFlashChain.Settings.Keybind = Enum.KeyCode[key] or Enum.KeyCode.E
    end
end

function BlackFlashChain:Cleanup()
    if currentAnimatorConnection then
        pcall(function() currentAnimatorConnection:Disconnect() end)
        currentAnimatorConnection = nil
    end
    if curveGlideConn then
        pcall(function() curveGlideConn:Disconnect() end)
        curveGlideConn = nil
    end
    if inputConnection then
        pcall(function() inputConnection:Disconnect() end)
        inputConnection = nil
    end
end

local function initialize()

    if player.Character then
        setupBlackFlashOnCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        BlackFlashChain:Cleanup()
        task.wait(0.2)
        setupBlackFlashOnCharacter(character)
    end)
    
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == BlackFlashChain.Settings.Keybind then
            BlackFlashChain:Execute()
        end
    end)
    
    print("✅ Auto Black Flash Chain iniciado (ATIVADO)")
    print("🎮 Pressione '" .. tostring(BlackFlashChain.Settings.Keybind):gsub("Enum.KeyCode.", "") .. "' para usar")
end

initialize()

return BlackFlashChain