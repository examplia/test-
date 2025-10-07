local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local TARGET_USER_ID = 9172634
local UPDATE_INTERVAL = 0.1
local MIN_DISTANCE = 5

local isEnabled = true
local connection

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FollowScriptUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 120)
mainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.BorderSizePixel = 0
title.Text = "Follow Script"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 220, 0, 30)
toggleButton.Position = UDim2.new(0.5, -110, 0, 45)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Enabled"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- Destroy Button
local destroyButton = Instance.new("TextButton")
destroyButton.Name = "DestroyButton"
destroyButton.Size = UDim2.new(0, 220, 0, 30)
destroyButton.Position = UDim2.new(0.5, -110, 0, 82)
destroyButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
destroyButton.BorderSizePixel = 0
destroyButton.Text = "Destroy Script"
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.TextSize = 14
destroyButton.Font = Enum.Font.GothamSemibold
destroyButton.Parent = mainFrame

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 6)
destroyCorner.Parent = destroyButton

-- Parent to PlayerGui
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Function to find target player
local function findTargetPlayer()
    for _, player in pairs(Players:GetPlayers()) do
        if player.UserId == TARGET_USER_ID then
            return player
        end
    end
    return nil
end

-- Function to move character towards target
local function moveTowardsTarget(targetPosition)
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart then
        local distance = (targetPosition - rootPart.Position).Magnitude
        
        if distance > MIN_DISTANCE then
            humanoid:MoveTo(targetPosition)
        end
    end
end

-- Main loop
local lastUpdate = 0

connection = RunService.Heartbeat:Connect(function()
    if not isEnabled then return end
    
    local currentTime = tick()
    
    if currentTime - lastUpdate < UPDATE_INTERVAL then
        return
    end
    lastUpdate = currentTime
    
    local targetPlayer = findTargetPlayer()
    
    if targetPlayer and targetPlayer.Character then
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if targetRoot then
            moveTowardsTarget(targetRoot.Position)
            
            local character = LocalPlayer.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local lookVector = (targetRoot.Position - rootPart.Position).Unit
                    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
                end
            end
        end
    end
end)

-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    
    if isEnabled then
        toggleButton.Text = "Enabled"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleButton.Text = "Disabled"
        toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        
        -- Stop character movement
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:MoveTo(character.HumanoidRootPart.Position)
            end
        end
    end
end)

-- Destroy button functionality
destroyButton.MouseButton1Click:Connect(function()
    if connection then
        connection:Disconnect()
    end
    
    -- Stop character movement
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:MoveTo(character.HumanoidRootPart.Position)
        end
    end
    
    screenGui:Destroy()
    print("Follow script destroyed")
end)

print("Follow script started - Following user ID: " .. TARGET_USER_ID)
print("Use the UI to toggle or destroy the script")
