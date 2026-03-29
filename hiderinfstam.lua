-- Stamina Bar Freeze + WalkSpeed Set + Sprint Animation Script
local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Settings
local sprintSpeed = 21.25
local sprintAnimationId = 86054903975369
local isSprinting = false
local isMoving = false
local isHider = false

-- Variables
local staminaBar = nil
local humanoid = nil
local character = nil
local wsLoop = nil
local wsCA = nil
local sprintAnimTrack = nil
local animator = nil

-- Function to check if player is on hider team
local function checkHiderTeam()
    local team = player.Team
    if team and team.Name:lower() == "hider" then
        isHider = true
        print("You are on hider team - infinite stamina active")
        return true
    else
        isHider = false
        print("You are not on hider team - infinite stamina disabled")
        return false
    end
end

-- Function to check if character is moving
local function checkMoving()
    if not humanoid then return false end
    local moveDirection = humanoid.MoveDirection
    return moveDirection.Magnitude > 0.1
end

-- Function to play sprint animation
local function playSprintAnimation()
    if not animator then return end
    
    if not sprintAnimTrack then
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. sprintAnimationId
        sprintAnimTrack = animator:LoadAnimation(anim)
    end
    
    if not sprintAnimTrack.IsPlaying then
        sprintAnimTrack:Play()
    end
end

-- Function to stop sprint animation
local function stopSprintAnimation()
    if sprintAnimTrack and sprintAnimTrack.IsPlaying then
        sprintAnimTrack:Stop()
    end
end

-- Function to handle sprint state based on shift and movement
local function updateSprintState()
    local shouldSprint = isSprinting and isMoving and isHider
    
    if shouldSprint then
        -- Set walkspeed
        if humanoid and humanoid.WalkSpeed ~= sprintSpeed then
            humanoid.WalkSpeed = sprintSpeed
        end
        -- Play animation
        playSprintAnimation()
    else
        -- Let game handle normal walkspeed
        -- Stop animation
        stopSprintAnimation()
    end
end

-- Function to set walkspeed
local function setWalkSpeed(speed)
    if not character or not humanoid or not isHider then return end
    if humanoid.WalkSpeed ~= speed then
        humanoid.WalkSpeed = speed
    end
end

-- Function to handle walkspeed changes
local function setupWalkSpeedControl()
    if not humanoid then return end
    
    if wsLoop then
        wsLoop:Disconnect()
        wsLoop = nil
    end
    if wsCA then
        wsCA:Disconnect()
        wsCA = nil
    end
    
    local function applyWalkSpeed()
        if isSprinting and isMoving and isHider then
            if humanoid.WalkSpeed ~= sprintSpeed then
                humanoid.WalkSpeed = sprintSpeed
            end
        end
    end
    
    wsLoop = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(applyWalkSpeed)
    
    wsCA = player.CharacterAdded:Connect(function(nChar)
        character = nChar
        humanoid = nChar:WaitForChild("Humanoid")
        animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        sprintAnimTrack = nil
        task.wait(0.1)
        applyWalkSpeed()
        
        if wsLoop then wsLoop:Disconnect() end
        wsLoop = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(applyWalkSpeed)
    end)
    
    applyWalkSpeed()
end

-- Function to setup stamina bar freeze
local function setupStaminaBar()
    local statsGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("StatsGui")
    if not statsGui then return end
    
    local stamina = statsGui:FindFirstChild("Stamina")
    if not stamina then return end
    
    staminaBar = stamina:FindFirstChild("bar")
    if not staminaBar then return end
    
    local maxSize = UDim2.new(0.959999979, 0, 0.829999983, 0)
    
    staminaBar.Size = maxSize
    
    staminaBar:GetPropertyChangedSignal("Size"):Connect(function()
        if isHider and staminaBar.Size.X.Scale < maxSize.X.Scale then
            staminaBar.Size = maxSize
        end
    end)
    
    spawn(function()
        while true do
            task.wait(0.1)
            if isHider and staminaBar and staminaBar.Size and staminaBar.Size.X.Scale < maxSize.X.Scale then
                staminaBar.Size = maxSize
            end
        end
    end)
    
    print("Stamina bar frozen at max")
end

-- Function to setup character
local function setupCharacter(char)
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        setupWalkSpeedControl()
    end
end

-- Handle input for left shift
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = true
        updateSprintState()
    end
end)

userInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = false
        updateSprintState()
    end
end)

-- Monitor movement state
spawn(function()
    while true do
        task.wait(0.1)
        local moving = checkMoving()
        if moving ~= isMoving then
            isMoving = moving
            updateSprintState()
        end
    end
end)

-- Handle character added
local function onCharacterAdded(newChar)
    task.wait(0.5)
    setupCharacter(newChar)
    isMoving = false
    isSprinting = false
end

-- Handle team change
player:GetPropertyChangedSignal("Team"):Connect(function()
    checkHiderTeam()
    if not isHider then
        stopSprintAnimation()
    end
    updateSprintState()
end)

-- Setup initial
checkHiderTeam()

spawn(function()
    while not staminaBar do
        task.wait(0.5)
        setupStaminaBar()
    end
end)

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Constant loop
spawn(function()
    while true do
        task.wait(0.05)
        
        if isHider then
            if staminaBar and staminaBar.Parent then
                local maxSize = UDim2.new(0.959999979, 0, 0.829999983, 0)
                if staminaBar.Size.X.Scale < maxSize.X.Scale then
                    staminaBar.Size = maxSize
                end
            end
        end
    end
end)

print("Script loaded!")
print("Only works when you are on hider team")
print("Hold Left Shift to sprint at " .. sprintSpeed .. " speed")
print("Sprint animation plays only when holding shift AND moving")
print("Stamina bar will always show full")
