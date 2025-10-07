local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

local TARGET_USER_ID = 9172634
local UPDATE_INTERVAL = 0.5
local MIN_DISTANCE = 8
local USE_PATHFINDING = true

local isEnabled = true
local connection
local pathConnection
local currentPath = nil
local nextWaypointIndex = 0

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FollowScriptUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

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

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Searching for target..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 220, 0, 30)
toggleButton.Position = UDim2.new(0.5, -110, 0, 70)
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
destroyButton.Position = UDim2.new(0.5, -110, 0, 107)
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

-- Function to compute path
local function computePath(start, finish)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {}
    })
    
    local success, errorMsg = pcall(function()
        path:ComputeAsync(start, finish)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path
    end
    return nil
end

-- Function to walk to waypoint
local function walkToWaypoint(humanoid, waypoint)
    if waypoint.Action == Enum.PathWaypointAction.Jump then
        humanoid.Jump = true
    end
    humanoid:MoveTo(waypoint.Position)
end

-- Function to follow using pathfinding
local function followWithPathfinding(targetPosition)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return false end
    
    local distance = (targetPosition - rootPart.Position).Magnitude
    
    if distance <= MIN_DISTANCE then
        humanoid:MoveTo(rootPart.Position)
        return true
    end
    
    -- Compute new path
    local path = computePath(rootPart.Position, targetPosition)
    
    if path then
        local waypoints = path:GetWaypoints()
        
        if #waypoints > 0 then
            -- Start from second waypoint (first is current position)
            local nextWaypoint = waypoints[2] or waypoints[1]
            walkToWaypoint(humanoid, nextWaypoint)
            
            -- Look at target
            local lookVector = (targetPosition - rootPart.Position).Unit
            rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
            
            return true
        end
    end
    
    return false
end

-- Function to follow directly (no pathfinding)
local function followDirect(targetPosition)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return false end
    
    local distance = (targetPosition - rootPart.Position).Magnitude
    
    if distance <= MIN_DISTANCE then
        humanoid:MoveTo(rootPart.Position)
        return true
    end
    
    -- Move directly
    humanoid:MoveTo(targetPosition)
    
    -- Look at target
    local lookVector = (targetPosition - rootPart.Position).Unit
    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
    
    return true
end

-- Main loop
local lastUpdate = 0
local targetFound = false

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
            targetFound = true
            local distance = 0
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                distance = (targetRoot.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end
            
            statusLabel.Text = string.format("Following (%.1f studs)", distance)
            
            -- Try pathfinding first, fallback to direct
            local success = false
            if USE_PATHFINDING then
                success = followWithPathfinding(targetRoot.Position)
            end
            
            if not success then
                followDirect(targetRoot.Position)
            end
        else
            statusLabel.Text = "Target character not loaded"
        end
    else
        if targetFound then
            statusLabel.Text = "Target left the game"
        else
            statusLabel.Text = "Target not in this server"
        end
        targetFound = false
    end
end)

-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    
    if isEnabled then
        toggleButton.Text = "Enabled"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Searching for target..."
    else
        toggleButton.Text = "Disabled"
        toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "Script disabled"
        
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
    if pathConnection then
        pathConnection:Disconnect()
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and character:FindFirstChild("HumanoidRootPart") then
            humanoid:MoveTo(character.HumanoidRootPart.Position)
        end
    end
    
    screenGui:Destroy()
    print("Follow script destroyed")
end)

print("Follow script started - Following user ID: " .. TARGET_USER_ID)
print("Use the UI to toggle or destroy the script")
