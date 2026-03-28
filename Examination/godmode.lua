-- Infinite Health Script (Always On)
local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Get or create the tester event
local testerEvent = replicatedStorage:FindFirstChild("TesterCommandsEvent")
if not testerEvent then
    testerEvent = Instance.new("RemoteEvent")
    testerEvent.Name = "TesterCommandsEvent"
    testerEvent.Parent = replicatedStorage
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

-- Apply to current character
local character = player.Character
if character then
    enableInfiniteHealth(character)
end

-- Apply on every respawn
player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5) -- Wait for character to fully load
    enableInfiniteHealth(newChar)
end)

print("✅ Infinite Health Activated!")
print("   You now have infinite health permanently.")
print("   Stays active through death and respawn.")
