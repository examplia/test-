local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

local SCRIPT_VERSION = "v1.4.0"
local TARGET_USER_ID = 9172634
local TARGET_USERNAME = "shteppiii"
local TARGET_DISPLAYNAME = "brokie"
local UPDATE_INTERVAL = 0.3
local MIN_DISTANCE = 8

local isEnabled = true
local connection
local currentHighlight = nil

-- Wait for character
local function waitForCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

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
statusLabel.Text = "Initializing..."
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
toggleButton.AutoButtonColor = false
destroyButton.AutoButtonColor = false
destroyButton.Parent = mainFrame

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 6)
destroyCorner.Parent = destroyButton

screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Function to find target player
local function findTargetPlayer()
    for _, player in pairs(Players:GetPlayers()) do
        -- Check by User ID
        if player.UserId == TARGET_USER_ID then
            print("[Follow Script] Found target by User ID: " .. player.Name)
            return player
        end
        -- Check by Username (case insensitive)
        if player.Name:lower() == TARGET_USERNAME:lower() then
            print("[Follow Script] Found target by Username: " .. player.Name)
            return player
        end
        -- Check by Display Name (case insensitive)
        if player.DisplayName:lower() == TARGET_DISPLAYNAME:lower() then
            print("[Follow Script] Found target by Display Name: " .. player.DisplayName)
            return player
        end
    end
    return nil
end

-- Function to create/update highlight
local function updateHighlight(targetCharacter)
    -- Remove old highlight if it exists
    if currentHighlight and currentHighlight.Parent then
        currentHighlight:Destroy()
    end
    
    if not targetCharacter then return end
    
    -- Create new Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "FollowScriptHighlight"
    highlight.Adornee = targetCharacter
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = targetCharacter
    
    currentHighlight = highlight
end

-- Function to remove highlight
local function removeHighlight()
    if currentHighlight and currentHighlight.Parent then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

-- Function to get valid humanoid and root part
local function getCharacterParts(character)
    if not character then return nil, nil end
    
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    
    return humanoid, rootPart
end

-- Function to follow target
local function followTarget(targetPosition)
    local character = LocalPlayer.Character
    if not character then 
        statusLabel.Text = "No character loaded"
        return 
    end
    
    local humanoid, rootPart = getCharacterParts(character)
    
    if not humanoid or not rootPart then 
        statusLabel.Text = "Character parts missing"
        return 
    end
    
    if humanoid.Health <= 0 then
        statusLabel.Text = "Character is dead"
        return
    end
    
    local distance = (targetPosition - rootPart.Position).Magnitude
    statusLabel.Text = string.format("Following (%.1f studs away)", distance)
    
    if distance > MIN_DISTANCE then
        -- Create path
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 3
        })
        
        local success, errorMsg = pcall(function()
            path:ComputeAsync(rootPart.Position, targetPosition)
        end)
        
        if success and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            
            if #waypoints >= 2 then
                local nextWaypoint = waypoints[2]
                
                if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end
                
                humanoid:MoveTo(nextWaypoint.Position)
            else
                -- Fallback to direct movement
                humanoid:MoveTo(targetPosition)
            end
        else
            -- Pathfinding failed, move directly
            humanoid:MoveTo(targetPosition)
        end
    else
        -- Within range, stop moving
        humanoid:MoveTo(rootPart.Position)
        statusLabel.Text = "In range (stopped)"
    end
end

-- Main loop
local lastUpdate = 0

print("[Follow Script] Starting script...")
print("[Follow Script] Target User ID: " .. TARGET_USER_ID)
print("[Follow Script] Target Username: " .. TARGET_USERNAME)
print("[Follow Script] Target Display Name: " .. TARGET_DISPLAYNAME)
print("[Follow Script] Searching for player...")

-- Try to find target immediately
local initialTarget = findTargetPlayer()
if initialTarget then
    print("[Follow Script] Target found: " .. initialTarget.Name .. " (@" .. initialTarget.DisplayName .. ")")
else
    print("[Follow Script] Target not found in server yet")
end

connection = RunService.Heartbeat:Connect(function()
    if not isEnabled then return end
    
    local currentTime = tick()
    
    if currentTime - lastUpdate < UPDATE_INTERVAL then
        return
    end
    lastUpdate = currentTime
    
    -- Find target player
    local targetPlayer = findTargetPlayer()
    
    if not targetPlayer then
        statusLabel.Text = "Target not in server"
        removeHighlight()
        return
    end
    
    if not targetPlayer.Character then
        statusLabel.Text = "Target character loading..."
        removeHighlight()
        return
    end
    
    local targetHumanoid, targetRoot = getCharacterParts(targetPlayer.Character)
    
    if not targetRoot then
        statusLabel.Text = "Target character invalid"
        removeHighlight()
        return
    end
    
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        statusLabel.Text = "Target is dead"
        removeHighlight()
        return
    end
    
    -- Update highlight on target
    updateHighlight(targetPlayer.Character)
    
    -- Follow the target
    followTarget(targetRoot.Position)
end)

print("[Follow Script] Script running! Check UI for status.")

-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    
    if isEnabled then
        toggleButton.Text = "Enabled"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Script enabled"
        print("[Follow Script] Enabled")
    else
        toggleButton.Text = "Disabled"
        toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "Script disabled"
        
        -- Remove highlight
        removeHighlight()
        
        -- Stop movement
        local character = LocalPlayer.Character
        if character then
            local humanoid, rootPart = getCharacterParts(character)
            if humanoid and rootPart then
                humanoid:MoveTo(rootPart.Position)
            end
        end
        
        print("[Follow Script] Disabled")
    end
end)

-- Destroy button functionality
destroyButton.MouseButton1Click:Connect(function()
    print("[Follow Script] Destroying script...")
    
    if connection then
        connection:Disconnect()
    end
    
    -- Remove highlight
    removeHighlight()
    
    -- Stop movement
    local character = LocalPlayer.Character
    if character then
        local humanoid, rootPart = getCharacterParts(character)
        if humanoid and rootPart then
            humanoid:MoveTo(rootPart.Position)
        end
    end
    
    screenGui:Destroy()
    print("[Follow Script] Script destroyed successfully")
end)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    print("[Follow Script] Character respawned, continuing...")
end)
