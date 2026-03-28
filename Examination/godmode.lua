-- Toggleable Infinite Health Script with Notifications
local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")

-- Settings
local toggleKey = Enum.KeyCode.F5 -- Press F5 to toggle
local infiniteHealthEnabled = false

-- Get or create the tester event
local testerEvent = replicatedStorage:FindFirstChild("TesterCommandsEvent")
if not testerEvent then
    testerEvent = Instance.new("RemoteEvent")
    testerEvent.Name = "TesterCommandsEvent"
    testerEvent.Parent = replicatedStorage
end

-- Function to send Roblox-style notification
local function sendNotification(title, text, duration)
    duration = duration or 3
    pcall(function()
        starterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Icon = "",
            Duration = duration
        })
    end)
end

-- Function to enable infinite health
local function enableInfiniteHealth(character)
    -- Send the infhp command to the server
    testerEvent:FireServer("infhp", true)
    
    -- Set attribute on character (game checks this)
    if character then
        character:SetAttribute("INFHP", true)
    end
end

-- Function to disable infinite health
local function disableInfiniteHealth(character)
    -- Send the infhp command to the server to disable
    testerEvent:FireServer("infhp", false)
    
    -- Remove attribute on character
    if character then
        character:SetAttribute("INFHP", false)
    end
end

-- Function to toggle infinite health
local function toggleInfiniteHealth()
    infiniteHealthEnabled = not infiniteHealthEnabled
    
    local character = player.Character
    if character then
        if infiniteHealthEnabled then
            enableInfiniteHealth(character)
            sendNotification("🛡️ INFINITE HEALTH", "ACTIVATED!\nYou are now invincible.", 2)
        else
            disableInfiniteHealth(character)
            sendNotification("⚔️ INFINITE HEALTH", "DEACTIVATED!\nYou can now take damage.", 2)
        end
    end
end

-- Apply on respawn (maintain toggle state)
player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5) -- Wait for character to fully load
    
    if infiniteHealthEnabled then
        enableInfiniteHealth(newChar)
        -- Optional: notify that it persisted
        sendNotification("🛡️ INFINITE HEALTH", "Persisted through death!", 1.5)
    end
end)

-- Input handler for toggle
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == toggleKey then
        toggleInfiniteHealth()
    end
end)

-- Send initial notification
sendNotification("Hey Dummy 👋", "Press F5 to toggle Infinite Health\nCurrently: OFF", 4)
