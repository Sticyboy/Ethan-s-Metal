-- Hook into the input service to detect F key press
local uis = game:GetService("UserInputService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("ViralFistsKeyPressEvent")

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        remote:FireServer("F")
    end
end)

print("Script loaded - Press F to fire the remote")