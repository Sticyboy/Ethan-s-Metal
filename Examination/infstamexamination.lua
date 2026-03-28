-- Infinite Stamina + Unlimited Tactical Sprint
local player = game.Players.LocalPlayer
local character = workspace.Characters:FindFirstChild(player.Name)
local clientScript = character and character:FindFirstChild("Client")

if clientScript then
    -- Get the State and MovementController modules
    local state = require(clientScript.State)
    local movementController = require(clientScript.MovementController)
    
    -- === INFINITE STAMINA ===
    -- Set stamina to infinite values
    state.stamina.current = 999999
    state.stamina.max = 999999
    state.stamina.regenDelay = 0
    state.stamina.fullRegen = false
    
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
    
    -- Set infinite stamina attribute for sliding check
    character:SetAttribute("infiniteStamina", true)
    
    -- === REMOVE TACTICAL SPRINT LIMIT ===
    -- Override tactical sprint to last forever
    if state.tacticalSprint then
        -- Remove cooldown and set infinite duration
        state.tacticalSprint.cooldown = 0
        state.tacticalSprint.tick = math.huge
    end
    
    -- Hook into the tactical sprint activation to prevent timer expiration
    local oldUpdate = movementController.update
    movementController.update = function(self, dt)
        -- Keep tactical sprint active if it was activated
        if state.tacticalSprint and state.tacticalSprint.active then
            -- Reset timer to keep it active forever
            state.tacticalSprint.tick = tick() + 999999
        end
        
        -- Keep stamina max
        if state.stamina then
            state.stamina.current = 999999
            state.stamina.fullRegen = false
        end
        
        -- Call original update
        local result = oldUpdate(self, dt)
        
        -- Ensure tactical sprint stays active after update
        if state.tacticalSprint and state.tacticalSprint.active then
            state.tacticalSprint.tick = tick() + 999999
            -- Keep speed at tactical sprint speed
            state.speed.current = state.tacticalSprint.speed or 23
        end
        
        return result
    end
    
    -- Keep tactical sprint active in a loop (backup method)
    spawn(function()
        while true do
            task.wait(0.5)
            if state.tacticalSprint and state.tacticalSprint.active then
                -- Reset the timer to keep it active
                state.tacticalSprint.tick = tick() + 999999
                -- Ensure speed stays at tactical sprint speed
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid.WalkSpeed = state.tacticalSprint.speed or 23
                end
            end
            -- Keep stamina max
            if state.stamina then
                state.stamina.current = 999999
            end
        end
    end)
    
    -- Set walkspeed to tactical sprint speed
    if character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = 23
    end
    
    print("✅ Infinite Stamina + Unlimited Tactical Sprint Activated!")
    print("   - Double tap shift to activate tactical sprint (it will never expire)")
    print("   - Normal sprint also has infinite stamina")
    print("   - No cooldown on tactical sprint")
    
else
    print("❌ Character or client script not found. Waiting for character...")
    
    -- Wait for character to load
    workspace.Characters.ChildAdded:Connect(function(char)
        if char.Name == player.Name then
            task.wait(1)
            local newClientScript = char:FindFirstChild("Client")
            if newClientScript then
                local state = require(newClientScript.State)
                local movementController = require(newClientScript.MovementController)
                
                -- Apply all the same changes
                state.stamina.current = 999999
                state.stamina.max = 999999
                state.stamina.regenDelay = 0
                state.stamina.fullRegen = false
                char:SetAttribute("infiniteStamina", true)
                
                if state.tacticalSprint then
                    state.tacticalSprint.cooldown = 0
                    state.tacticalSprint.tick = math.huge
                end
                
                if char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = 23
                end
                
                print("✅ Infinite Stamina + Unlimited Tactical Sprint Activated!")
            end
        end
    end)
end