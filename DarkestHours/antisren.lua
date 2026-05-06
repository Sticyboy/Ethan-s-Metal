-- Disable ALL Siren effects
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatusEffectHandler = require(ReplicatedStorage.Shared.Classes.StatusEffectHandler)

-- List of Siren effects to block
local sirenEffects = {
    "Stunned",
    "DisableInputs", 
    "DisableDefaultMovement"
}

-- Block AddEffect for all siren effects
local originalAddEffect = StatusEffectHandler.AddEffect
StatusEffectHandler.AddEffect = function(self, effectName, ...)
    for _, effect in ipairs(sirenEffects) do
        if effectName == effect then
            print("[Anti-Siren] Blocked effect:", effect)
            return nil
        end
    end
    return originalAddEffect(self, effectName, ...)
end

-- Also block by index
local originalAddByIndex = StatusEffectHandler.AddEffectByIndex
StatusEffectHandler.AddEffectByIndex = function(self, effectIndex, ...)
    local effectName = self.effectReverseLookup[effectIndex]
    for _, effect in ipairs(sirenEffects) do
        if effectName == effect then
            print("[Anti-Siren] Blocked effect by index:", effect)
            return nil
        end
    end
    return originalAddByIndex(self, effectIndex, ...)
end

print("[Anti-Siren] Complete immunity activated!")