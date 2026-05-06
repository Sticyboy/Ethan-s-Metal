-- Infinite Stamina Script (Require-compatible executor)
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

-- Get the required modules
local statusHandler = require(replicatedStorage.Shared.Classes.StatusEffectHandler)
local sharedCharacter = require(replicatedStorage.Shared.Classes.SharedCharacter)

-- Method 1: Override the StaminaDrain module directly
local staminaDrainModule = replicatedStorage.Shared.Classes.StatusEffectHandler:FindFirstChild("StaminaDrain")
if staminaDrainModule then
    local staminaDrain = require(staminaDrainModule)
    
    -- Override the Step function to remove stamina drain
    local originalStep = staminaDrain.Step
    staminaDrain.Step = function(self, deltaTime)
        -- Call SetStaminaActivity but skip DepleteStamina
        self.SharedCharacter:SetStaminaActivity(1)
        -- DepleteStamina is NOT called here
        -- Call base Step but without the drain
        local base = require(staminaDrainModule.Parent.Base)
        if base.Step then
            base.Step(self, deltaTime)
        end
    end
    print("StaminaDrain module overridden!")
end

-- Method 2: Override SharedCharacter stamina methods
local originalGetObject = sharedCharacter.getObject
sharedCharacter.getObject = function(character)
    local obj = originalGetObject(character)
    if obj then
        -- Override stamina methods
        obj.DepleteStamina = function() end
        obj.SetStaminaActivity = function() end
        
        -- Set max stamina values
        obj.MaxStamina = 999999
        obj.CurrentStamina = 999999
    end
    return obj
end

-- Method 3: Keep stamina attribute maxed on the character
local function keepStaminaMaxed()
    local character = localPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:SetAttribute("Stamina", 999999)
        humanoid:SetAttribute("MaxStamina", 999999)
        
        -- Get the SharedCharacter instance and force values
        local obj = sharedCharacter.getObject(character)
        if obj then
            obj.CurrentStamina = 999999
            obj.MaxStamina = 999999
        end
    end
end

-- Run when character spawns
localPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    keepStaminaMaxed()
    
    -- Continuously keep stamina maxed
    game:GetService("RunService").Heartbeat:Connect(function()
        if character and character.Parent then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:SetAttribute("Stamina", 999999)
                
                local obj = sharedCharacter.getObject(character)
                if obj then
                    obj.CurrentStamina = 999999
                end
            end
        end
    end)
end)

-- Initial run
if localPlayer.Character then
    task.wait(0.5)
    keepStaminaMaxed()
end

print("Infinite stamina activated! Stamina will no longer drain.")