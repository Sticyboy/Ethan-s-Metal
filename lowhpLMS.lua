-- OST Replace Script with Low HP Conditions
-- Only replaces the specific LMS theme (rbxassetid://71057332615441)
-- Ignores other LMS themes from skins or different tracks

local themes = workspace.Themes
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TargetAssetId = "rbxassetid://71057332615441"  -- ONLY this specific theme gets replaced
local FileName = "LowHp.mp3"
local FilePath = "workspace/" .. FileName
local AudioURL = "https://raw.githubusercontent.com/Sticyboy/Ethan-s-Metal/main/lowhp.mp3"

-- === STATE VARIABLES ===
local customAssetId = nil
local isLowHpActive = false
local lastSurvivorSound = nil
local lowHpTriggered = false
local hasCheckedLMS = false
local themePlaying = false
local roundActive = false

-- === DOWNLOAD FUNCTION ===
local function downloadAudio()
    if isfile and isfile(FilePath) then
        print("[OST REPLACE] File already exists!")
        return true
    end
    
    print("[OST REPLACE] Downloading audio from GitHub...")
    local success, audioData = pcall(function()
        return game:HttpGet(AudioURL)
    end)
    
    if not success then
        warn("[OST REPLACE] Download failed!")
        return false
    end
    
    if writefile then
        writefile(FilePath, audioData)
        print("[OST REPLACE] Downloaded! Size:", #audioData, "bytes")
        return true
    end
    
    return false
end

-- === GET CUSTOM ASSET ===
local function getCustomAsset()
    if customAssetId then
        return customAssetId
    end
    
    if getcustomasset then
        local success, result = pcall(function()
            return getcustomasset(FilePath)
        end)
        if success and result then
            customAssetId = result
            return customAssetId
        end
    end
    
    if syn and syn.crypt and syn.crypt.custom_asset then
        local success, audioData = pcall(function()
            return readfile(FilePath)
        end)
        if success and audioData then
            customAssetId = syn.crypt.custom_asset(audioData)
            return customAssetId
        end
    end
    
    return nil
end

-- === GET SURVIVORS FROM WORKSPACE.PLAYERS.SURVIVORS ===
local function getSurvivors()
    local survivors = {}
    
    -- Find the Survivors folder
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then
        return survivors
    end
    
    local survivorsFolder = playersFolder:FindFirstChild("Survivors")
    if not survivorsFolder then
        return survivors
    end
    
    -- Loop through all children in the Survivors folder
    for _, child in pairs(survivorsFolder:GetChildren()) do
        if child:IsA("Model") then
            local humanoid = child:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(survivors, {
                    Name = child.Name,
                    Character = child,
                    Humanoid = humanoid,
                    Health = humanoid.Health,
                    MaxHealth = humanoid.MaxHealth
                })
            end
        end
    end
    
    return survivors
end

-- === CHECK SURVIVOR HP ===
local function checkSurvivorHealth(character)
    if not character then
        return nil
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil
    end
    
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local percent = (health / maxHealth) * 100
    
    return {
        Health = health,
        MaxHealth = maxHealth,
        Percent = percent,
        IsLow = percent < 50
    }
end

-- === REPLACE THEME FUNCTION ===
local function replaceTheme(sound, assetId)
    if not sound or not assetId then
        print("[OST REPLACE] ❌ Cannot replace - sound or asset missing!")
        return false
    end
    
    -- Check if the sound is valid and has a SoundId
    if not sound:IsA("Sound") then
        print("[OST REPLACE] ❌ Not a sound object!")
        return false
    end
    
    -- === IMPORTANT: ONLY replace if it's the TARGET audio ===
    local currentId = sound.SoundId
    if currentId ~= TargetAssetId then
        print("[OST REPLACE] ⏭️ Skipping - not the target audio (current: " .. currentId .. ")")
        return false
    end
    
    print("[OST REPLACE] 🎯 Target audio detected! Replacing...")
    
    -- Wait for the sound to be fully loaded/ready
    local maxAttempts = 10
    local attempts = 0
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Check if SoundId still matches the target
        if sound.SoundId == TargetAssetId then
            -- Sound is ready, replace it
            sound.SoundId = assetId
            print("[OST REPLACE] ✅ Replaced with Low HP theme! (attempt " .. attempts .. ")")
            isLowHpActive = true
            
            if sound.IsPlaying then
                sound:Stop()
                sound:Play()
            end
            return true
        end
        
        -- Wait a bit before trying again
        task.wait(0.1)
    end
    
    print("[OST REPLACE] ❌ Failed to replace theme after " .. maxAttempts .. " attempts!")
    return false
end

-- === RESET TO NORMAL THEME ===
local function resetToNormalTheme()
    if lastSurvivorSound and isLowHpActive then
        -- Only reset if the sound is currently using our custom asset
        if lastSurvivorSound.SoundId == customAssetId then
            print("[OST REPLACE] 🔄 Resetting to normal theme...")
            lastSurvivorSound.SoundId = TargetAssetId
            isLowHpActive = false
            
            if lastSurvivorSound.IsPlaying then
                lastSurvivorSound:Stop()
                lastSurvivorSound:Play()
            end
        end
    end
end

-- === FULL RESET FOR NEW ROUND ===
local function fullReset()
    print("[OST REPLACE] ========== NEW ROUND ==========")
    print("[OST REPLACE] 🔄 Performing full reset...")
    
    -- Reset all state variables
    lowHpTriggered = false
    hasCheckedLMS = false
    themePlaying = false
    roundActive = false
    isLowHpActive = false
    
    -- Reset the sound back to normal if it exists and is our custom asset
    if lastSurvivorSound then
        pcall(function()
            if lastSurvivorSound.SoundId == customAssetId then
                lastSurvivorSound.SoundId = TargetAssetId
                if lastSurvivorSound.IsPlaying then
                    lastSurvivorSound:Stop()
                    lastSurvivorSound:Play()
                end
            end
        end)
    end
    
    -- Clear the sound reference so it gets re-detected
    lastSurvivorSound = nil
    
    print("[OST REPLACE] ✅ Reset complete! Ready for next round.")
    print("[OST REPLACE] ==================================")
end

-- === CHECK LMS CONDITIONS ===
local function checkLMSConditions()
    -- Don't check twice per round
    if hasCheckedLMS or lowHpTriggered then
        return
    end
    
    -- Make sure we have the custom asset ready
    if not customAssetId then
        print("[OST REPLACE] ❌ Custom asset not ready yet!")
        return
    end
    
    -- Make sure we have the LastSurvivor sound
    if not lastSurvivorSound then
        print("[OST REPLACE] ❌ LastSurvivor sound not ready yet!")
        return
    end
    
    -- === ONLY proceed if the sound is the target audio ===
    if lastSurvivorSound.SoundId ~= TargetAssetId then
        print("[OST REPLACE] ⏭️ Sound is not the target theme (current: " .. lastSurvivorSound.SoundId .. ")")
        return
    end
    
    local survivors = getSurvivors()
    local survivorCount = #survivors
    
    print("[OST REPLACE] LMS Check - Survivors alive:", survivorCount)
    
    -- Should only be 1 survivor in LMS
    if survivorCount ~= 1 then
        print("[OST REPLACE] Not LMS yet (" .. survivorCount .. " survivors alive)")
        return
    end
    
    local lastSurvivor = survivors[1]
    print("[OST REPLACE] 🎯 LMS detected! Last survivor:", lastSurvivor.Name)
    
    -- Check the survivor's HP
    local healthData = checkSurvivorHealth(lastSurvivor.Character)
    
    if healthData then
        print("[OST REPLACE] HP:", math.floor(healthData.Health) .. "/" .. math.floor(healthData.MaxHealth) .. " (" .. math.floor(healthData.Percent) .. "%)")
        
        if healthData.IsLow then
            print("[OST REPLACE] ⚠️ Low HP detected! (" .. math.floor(healthData.Percent) .. "%)")
            print("[OST REPLACE] 🎵 Attempting to play Low HP theme...")
            
            -- Try to replace the theme with retries
            local success = replaceTheme(lastSurvivorSound, customAssetId)
            if success then
                lowHpTriggered = true
                print("[OST REPLACE] ✅ Low HP theme activated!")
            else
                print("[OST REPLACE] ❌ Failed to activate Low HP theme!")
            end
        else
            print("[OST REPLACE] ✅ HP is above 50%. Keeping normal theme.")
        end
    end
    
    hasCheckedLMS = true
end

-- === SETUP MONITORING ===
local function setupMonitoring()
    if _G.Connection then
        _G.Connection:Disconnect()
        _G.Connection = nil
        if _G.HeartbeatConnection then
            _G.HeartbeatConnection:Disconnect()
            _G.HeartbeatConnection = nil
        end
        print("[OST REPLACE] Stopped!")
        return
    end
    
    print("[OST REPLACE | Info] Downloading audio from GitHub...")
    
    -- Download the audio
    if not downloadAudio() then
        print("[OST REPLACE] ❌ Download failed! Check the URL.")
        return
    end
    
    -- Get custom asset
    customAssetId = getCustomAsset()
    if not customAssetId then
        print("[OST REPLACE] ❌ Could not create custom asset!")
        return
    end
    
    print("[OST REPLACE] Custom asset created:", customAssetId)
    print("[OST REPLACE] Target audio ID:", TargetAssetId)
    print("[OST REPLACE] ⚠️ ONLY the target audio will be replaced!")
    
    -- Get the Themes folder
    local themesFolder = workspace:FindFirstChild("Themes")
    if not themesFolder then
        print("[OST REPLACE] ⚠️ Themes folder not found!")
        return
    end
    
    -- === FIND LASTSURVIVOR SOUND ===
    local function findLastSurvivorSound()
        -- Check if it already exists
        local sound = themesFolder:FindFirstChild("LastSurvivor")
        if sound and sound:IsA("Sound") then
            return sound
        end
        return nil
    end
    
    -- === HANDLE LMS START ===
    local function onLMSStart(sound)
        -- === ONLY process if it's the target audio ===
        if sound.SoundId ~= TargetAssetId then
            print("[OST REPLACE] ⏭️ Ignoring non-target LMS theme: " .. sound.SoundId)
            return
        end
        
        print("[OST REPLACE] ✅ Target LastSurvivor sound found!")
        lastSurvivorSound = sound
        roundActive = true
        
        -- Wait for the sound to be fully loaded before checking
        task.wait(1.0)
        
        -- Listen for when it starts playing
        sound.Played:Connect(function()
            -- === ONLY process if it's still the target audio ===
            if sound.SoundId ~= TargetAssetId then
                print("[OST REPLACE] ⏭️ Sound changed, ignoring...")
                return
            end
            
            print("[OST REPLACE] 🎵 Target LastSurvivor theme started playing!")
            themePlaying = true
            
            -- Wait a moment for the sound to fully load before checking
            task.wait(0.5)
            
            -- Check conditions when it plays
            if not hasCheckedLMS and not lowHpTriggered then
                checkLMSConditions()
            end
        end)
        
        -- Also check immediately if the sound is already playing
        if sound.IsPlaying and sound.SoundId == TargetAssetId then
            print("[OST REPLACE] 🎵 Target LastSurvivor theme is already playing!")
            themePlaying = true
            
            task.wait(0.5)
            if not hasCheckedLMS and not lowHpTriggered then
                checkLMSConditions()
            end
        end
        
        -- Listen for when it stops (round ended)
        sound.Stopped:Connect(function()
            print("[OST REPLACE] LastSurvivor theme stopped!")
            themePlaying = false
            
            -- Reset for next round after a delay
            task.wait(2)
            if not sound.IsPlaying then
                fullReset()
            end
        end)
    end
    
    -- Check if LastSurvivor already exists
    local existingSound = findLastSurvivorSound()
    if existingSound then
        onLMSStart(existingSound)
    end
    
    -- Listen for new sounds added to Themes
    _G.Connection = themesFolder.ChildAdded:Connect(function(child)
        if child:IsA("Sound") and child.Name == "LastSurvivor" then
            onLMSStart(child)
        end
    end)
    
    -- === MONITOR SURVIVOR FOLDER FOR CHANGES ===
    local function monitorSurvivorFolder()
        local playersFolder = workspace:FindFirstChild("Players")
        if not playersFolder then
            return
        end
        
        local survivorsFolder = playersFolder:FindFirstChild("Survivors")
        if not survivorsFolder then
            return
        end
        
        -- When a survivor is removed (died), check LMS conditions
        survivorsFolder.ChildRemoved:Connect(function(child)
            if child:IsA("Model") then
                print("[OST REPLACE] Survivor removed:", child.Name)
                task.wait(0.8)
                
                -- Check if we're in LMS state
                if not hasCheckedLMS and not lowHpTriggered then
                    local survivors = getSurvivors()
                    if #survivors == 1 then
                        print("[OST REPLACE] Survivor died, checking LMS state...")
                        task.wait(0.5)
                        checkLMSConditions()
                    elseif #survivors == 0 then
                        -- No survivors left = round ended
                        print("[OST REPLACE] No survivors left! Round ended.")
                        fullReset()
                    end
                end
            end
        end)
        
        -- Also check periodically for round end (no survivors)
        local function checkRoundEnd()
            if roundActive then
                local survivors = getSurvivors()
                if #survivors == 0 then
                    print("[OST REPLACE] No survivors detected! Round ended.")
                    fullReset()
                end
            end
        end
        
        -- Check every 5 seconds
        task.spawn(function()
            while true do
                task.wait(5)
                checkRoundEnd()
            end
        end)
    end
    
    -- Start monitoring survivors
    monitorSurvivorFolder()
    
    -- === HEARTBEAT CHECK (FALLBACK) ===
    _G.HeartbeatConnection = RunService.Heartbeat:Connect(function()
        -- Check periodically if LMS is active but we haven't checked yet
        if not hasCheckedLMS and not lowHpTriggered and roundActive then
            -- Only check every 2 seconds to save performance
            if tick() % 2 < 0.1 then
                local survivors = getSurvivors()
                if #survivors == 1 then
                    -- Make sure we have the sound and asset ready
                    if lastSurvivorSound and customAssetId then
                        -- === ONLY check if it's the target audio ===
                        if lastSurvivorSound.SoundId == TargetAssetId then
                            checkLMSConditions()
                        end
                    end
                elseif #survivors == 0 and roundActive then
                    fullReset()
                end
            end
        end
    end)
    
    print("[OST REPLACE | Status] Running! Waiting for LMS to start...")
    print("[OST REPLACE] 🎯 Target ID:", TargetAssetId)
    print("[OST REPLACE] ⚠️ Other LMS themes will be ignored!")
    print("[OST REPLACE] To stop the script, run it again.")
end

-- === MAIN EXECUTION ===
setupMonitoring()
