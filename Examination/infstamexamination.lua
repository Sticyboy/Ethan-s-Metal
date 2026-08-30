-- Infinite Stamina Only (No Drain)
local player = game.Players.LocalPlayer

-- Function to apply infinite stamina to a character
local function applyInfiniteStamina(character)
    if not character then return end
    
    local clientHandler = character:FindFirstChild("ClientHandler")
    if not clientHandler then 
        print("❌ ClientHandler not found!")
        return 
    end
    
    -- Safely require State module
    local success, state = pcall(require, clientHandler.State)
    if not success then
        print("❌ Failed to load State module:", success)
        return
    end
    
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
    if stamina then
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
    end
    
    -- Set attribute
    character:SetAttribute("infiniteStamina", true)
    print("✅ Stamina will not drain!")
end

-- Function to handle new characters
local function onCharacterAdded(character)
    task.wait(0.5)
    applyInfiniteStamina(character)
end

-- Persistent loop to keep stamina max
spawn(function()
    while true do
        task.wait(1)
        local charactersFolder = workspace:FindFirstChild("Characters")
        if charactersFolder then
            local character = charactersFolder:FindFirstChild(player.Name)
            if character then
                local clientHandler = character:FindFirstChild("ClientHandler")
                if clientHandler then
                    local success, state = pcall(require, clientHandler.State)
                    if success and state and state.stamina then
                        -- Keep stamina max at all times
                        if state.stamina.current < 999999 then
                            state.stamina.current = 999999
                            state.stamina.max = 999999
                            state.stamina.regenDelay = 0
                            state.stamina.fullRegen = false
                        end
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
local charactersFolder = workspace:FindFirstChild("Characters")
if charactersFolder then
    local currentCharacter = charactersFolder:FindFirstChild(player.Name)
    if currentCharacter then
        onCharacterAdded(currentCharacter)
    else
        charactersFolder.ChildAdded:Connect(function(char)
            if char.Name == player.Name then
                onCharacterAdded(char)
            end
        end)
    end
end

print("✅ Infinite Stamina Activated!")
print("   - Your stamina will never drain")
print("   - Works through death and respawn")
