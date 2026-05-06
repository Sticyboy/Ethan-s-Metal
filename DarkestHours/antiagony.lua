-- Block AgonySlowness effect entirely
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatusEffectHandler = require(ReplicatedStorage.Shared.Classes.StatusEffectHandler)

-- Hook AddEffect to block AgonySlowness
local originalAddEffect = StatusEffectHandler.AddEffect
StatusEffectHandler.AddEffect = function(self, effectName, ...)
    if effectName == "AgonySlowness" then
        print("Blocked AgonySlowness effect!")
        return nil
    end
    return originalAddEffect(self, effectName, ...)
end

-- Also block by index
local originalAddByIndex = StatusEffectHandler.AddEffectByIndex
StatusEffectHandler.AddEffectByIndex = function(self, effectIndex, ...)
    local effectName = self.effectReverseLookup[effectIndex]
    if effectName == "AgonySlowness" then
        print("Blocked AgonySlowness by index!")
        return nil
    end
    return originalAddByIndex(self, effectIndex, ...)
end

print("AgonySlowness blocked!")