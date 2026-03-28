-- Infinite Stamina + Unlimited Tactical Sprint (Persists Through Death)
local player = game.Players.LocalPlayer

-- Function to apply infinite stamina to a character
local function applyInfiniteStamina(character)
    if not character then return end
    
    local clientScript = character:FindFirstChild("Client")
    if not clientScript then return end
    
    -- Safely require modules (pcall to handle errors)
    local success, state = pcall(require, clientScript.State)
    if not success then return end
    
    local success2, movementController = pcall(require, clientScript.MovementController)
    
    print("✅ Applying infinite stamina to: " .. character.Name)
    
    -- === INFINITE STAMINA ===
    if state.stamina then
        state.stamina.current = 999999
        state.stamina.max = 999999
        state.stamina.regenDelay = 0
        state.stamina.fullRegen = false
    end
    
    -- Hook stamina to prevent reduction
    local stamina = state.stamina
    local staminaMT = {}
    
    staminaMT.__index = function(t, k)
        if k == "current" then
            return 999999
        end
        return rawget(t, k)
    end
    
    staminaMT.__newindex = function(t, k, v)
        if k == "current" then
            if v < rawget(t, k) then
                return -- Prevent stamina reduction
            end
        end
        rawset(t, k, v)
    end
    
    setmetatable(stamina, staminaMT)
    
    -- Set infinite stamina attribute
    character:SetAttribute("infiniteStamina", true)
    
    -- === REMOVE TACTICAL SPRINT LIMIT ===
    if state.tacticalSprint then
        state.tacticalSprint.cooldown = 0
        state.tacticalSprint.tick = math.huge
    end
    
    -- Hook the update function if movement controller exists
    if movementController and movementController.update then
        -- Store original if not already hooked
        if not movementController.__originalUpdate then
            movementController.__originalUpdate = movementController.update
        end
        
        movementController.update = function(self, dt)
            -- Keep tactical sprint active if it was activated
            if state.tacticalSprint and state.tacticalSprint.active then
                state.tacticalSprint.tick = tick() + 999999
            end
            
            -- Keep stamina max
            if state.stamina then
                state.stamina.current = 999999
                state.stamina.fullRegen = false
            end
            
            -- Call original update
            local result = movementController.__originalUpdate(self, dt)
            
            -- Ensure tactical sprint stays active
            if state.tacticalSprint and state.tacticalSprint.active then
                state.tacticalSprint.tick = tick() + 999999
                if state.speed then
                    state.speed.current = state.tacticalSprint.speed or 23
                end
            end
            
            return result
        end
    end
    
    -- Set walkspeed
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 23
    end
end

-- Function to handle new characters
local function onCharacterAdded(character)
    -- Wait a moment for scripts to load
    task.wait(0.5)
    applyInfiniteStamina(character)
end

-- Start a persistent loop to continuously apply stamina (catches any missed cases)
spawn(function()
    while true do
        task.wait(1) -- Check every second
        local character = workspace.Characters:FindFirstChild(player.Name)
        if character then
            local clientScript = character:FindFirstChild("Client")
            if clientScript then
                local success, state = pcall(require, clientScript.State)
                if success and state and state.stamina then
                    -- Keep stamina max at all times
                    if state.stamina.current < 999999 then
                        state.stamina.current = 999999
                        state.stamina.max = 999999
                        state.stamina.regenDelay = 0
                        state.stamina.fullRegen = false
                    end
                    
                    -- Keep tactical sprint ready
                    if state.tacticalSprint then
                        state.tacticalSprint.cooldown = 0
                        if state.tacticalSprint.active then
                            state.tacticalSprint.tick = tick() + 999999
                        end
                    end
                    
                    -- Keep walkspeed
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.WalkSpeed ~= 23 then
                        humanoid.WalkSpeed = 23
                    end
                    
                    -- Keep attribute set
                    if character:GetAttribute("infiniteStamina") ~= true then
                        character:SetAttribute("infiniteStamina", true)
                    end
                end
            end
        end
        task.wait()
    end
end)

-- Connect to character added event
player.CharacterAdded:Connect(onCharacterAdded)

-- Apply to current character if it exists
local currentCharacter = workspace.Characters:FindFirstChild(player.Name)
if currentCharacter then
    onCharacterAdded(currentCharacter)
else
    -- Wait for character to spawn
    workspace.Characters.ChildAdded:Connect(function(char)
        if char.Name == player.Name then
            onCharacterAdded(char)
        end
    end)
end

print("✅ Infinite Stamina + Unlimited Tactical Sprint Activated!")
print("   - Works through death and respawn")
print("   - Double tap shift for permanent tactical sprint")
print("   - Auto-reapplies stamina every second to ensure it stays active")
