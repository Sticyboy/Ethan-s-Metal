-- Aggressive Entity ESP - Finds EVERYTHING
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local espObjects = {}
local processedEntities = {}

-- Function to find ALL models with Humanoids recursively
local function findAllEntities(folder)
    local entities = {}
    
    local function search(container)
        for _, obj in pairs(container:GetChildren()) do
            -- Check if this object is a model with a Humanoid
            if obj:IsA("Model") and obj ~= localPlayer.Character then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 and not processedEntities[obj] then
                    table.insert(entities, obj)
                end
            end
            
            -- Search inside folders AND models (some games use models as containers)
            if obj:IsA("Folder") or (obj:IsA("Model") and obj:GetChildren()) then
                search(obj)
            end
        end
    end
    
    search(folder)
    return entities
end

local function addESP(entity)
    if espObjects[entity] then return end
    
    local rootPart = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("UpperTorso") or entity:FindFirstChild("Head")
    if not rootPart then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.Adornee = entity
    highlight.Parent = entity
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = rootPart
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 0, 0)
    text.TextStrokeTransparency = 0.2
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Text = entity.Name
    text.Parent = billboard
    
    espObjects[entity] = {Highlight = highlight, Billboard = billboard}
    print("ESP added for:", entity.Name)
end

local function removeESP(entity)
    local esp = espObjects[entity]
    if esp then
        if esp.Highlight then esp.Highlight:Destroy() end
        if esp.Billboard then esp.Billboard:Destroy() end
        espObjects[entity] = nil
    end
end

-- Main loop
spawn(function()
    while true do
        wait(0.3) -- Check more frequently
        
        local entitiesFolder = workspace:FindFirstChild("Entities")
        if entitiesFolder then
            -- Clear processed entities each cycle
            processedEntities = {}
            
            -- Find all entities
            local allEntities = findAllEntities(entitiesFolder)
            
            -- Mark processed entities
            for _, entity in pairs(allEntities) do
                processedEntities[entity] = true
                if not espObjects[entity] then
                    addESP(entity)
                end
            end
            
            -- Remove ESP for entities not found
            for entity, _ in pairs(espObjects) do
                if not processedEntities[entity] then
                    removeESP(entity)
                end
            end
        else
            -- Clear all ESP if no Entities folder
            for entity, _ in pairs(espObjects) do
                removeESP(entity)
            end
        end
    end
end)

print("ESP Active - Will find ALL enemies in ALL subfolders")