local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

local SCRIPT_VERSION = "v1.5.0"
local TARGET_USER_ID = 9172634
local TARGET_USERNAME = "shteppiii"
local TARGET_DISPLAYNAME = "brokie"
local UPDATE_INTERVAL = 0.3
local MIN_DISTANCE = 8

local isEnabled = true
local connection
local currentHighlight = nil

-- Instance tracking for proper cleanup
local trackedInstances = {}
local function trackInstance(instance)
    table.insert(trackedInstances, instance)
    return instance
end

local function cleanupTrackedInstances()
    for i = #trackedInstances, 1, -1 do
        local instance = trackedInstances[i]
        if instance and instance.Parent then
            instance:Destroy()
        end
        table.remove(trackedInstances, i)
    end
end

-- Mobile detection function
local function isMobileDevice()
    local userInputService = game:GetService("UserInputService")
    return userInputService.TouchEnabled and not userInputService.MouseEnabled
end

-- Get responsive sizing based on device
local function getResponsiveSize()
    local isMobile = isMobileDevice()
    return {
        frameWidth = isMobile and 320 or 280,
        frameHeight = isMobile and 200 or 180,
        buttonWidth = isMobile and 280 or 250,
        buttonHeight = isMobile and 40 or 35,
        titleSize = isMobile and 18 or 16,
        textSize = isMobile and 12 or 11
    }
end

print("=== FOLLOW SCRIPT INITIALIZING ===")
print("[Follow Script] Version: " .. SCRIPT_VERSION)
print("[Follow Script] Target User ID: " .. TARGET_USER_ID)
print("[Follow Script] Target Username: " .. TARGET_USERNAME)
print("[Follow Script] Target Display Name: " .. TARGET_DISPLAYNAME)

-- Wait for character
local function waitForCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

print("[Follow Script] Creating UI...")

-- Get responsive sizing
local sizes = getResponsiveSize()
local isMobile = isMobileDevice()

-- Create UI
local screenGui = trackInstance(Instance.new("ScreenGui"))
screenGui.Name = "FollowScriptUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Mobile-specific ScreenGui properties
if isMobile then
    screenGui.IgnoreGuiInset = true
    screenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
end

-- Main Frame
local mainFrame = trackInstance(Instance.new("Frame"))
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, sizes.frameWidth, 0, sizes.frameHeight)
mainFrame.Position = UDim2.new(0.5, -sizes.frameWidth/2, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = not isMobile -- Disable default dragging on mobile

-- Add touch-based dragging for mobile
if isMobile then
    local dragStart, startPos
    local function onTouchStart(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end

    local function onTouchMove(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragStart then
            local delta = input.Position - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y

            -- Keep frame within screen bounds
            local screenSize = workspace.CurrentCamera.ViewportSize
            newX = math.clamp(newX, -sizes.frameWidth/2, screenSize.X - sizes.frameWidth/2)
            newY = math.clamp(newY, 0, screenSize.Y - sizes.frameHeight)

            mainFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end

    local function onTouchEnd()
        dragStart = nil
    end

    mainFrame.InputBegan:Connect(onTouchStart)
    mainFrame.InputChanged:Connect(onTouchMove)
    mainFrame.InputEnded:Connect(onTouchEnd)
end

mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title
local title = trackInstance(Instance.new("TextLabel"))
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, isMobile and 40 or 35)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.BorderSizePixel = 0
title.Text = "Follow Script " .. SCRIPT_VERSION
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = sizes.titleSize
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local titleCorner = trackInstance(Instance.new("UICorner"))
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Status Label
local statusLabel = trackInstance(Instance.new("TextLabel"))
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, isMobile and 55 or 50)
statusLabel.Position = UDim2.new(0, 10, 0, isMobile and 47 or 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Initializing..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = sizes.textSize
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

-- Toggle Button
local toggleButton = trackInstance(Instance.new("TextButton"))
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, sizes.buttonWidth, 0, sizes.buttonHeight)
toggleButton.Position = UDim2.new(0.5, -sizes.buttonWidth/2, 0, isMobile and 110 or 100)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Enabled"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = isMobile and 16 or 14
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame

local toggleCorner = trackInstance(Instance.new("UICorner"))
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- Destroy Button
local destroyButton = trackInstance(Instance.new("TextButton"))
destroyButton.Name = "DestroyButton"
destroyButton.Size = UDim2.new(0, sizes.buttonWidth, 0, sizes.buttonHeight)
destroyButton.Position = UDim2.new(0.5, -sizes.buttonWidth/2, 0, isMobile and 155 or 142)
destroyButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
destroyButton.BorderSizePixel = 0
destroyButton.Text = "Destroy Script"
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.TextSize = isMobile and 16 or 14
destroyButton.Font = Enum.Font.GothamSemibold
destroyButton.AutoButtonColor = false
destroyButton.Parent = mainFrame

local destroyCorner = trackInstance(Instance.new("UICorner"))
destroyCorner.CornerRadius = UDim.new(0, 6)
destroyCorner.Parent = destroyButton

screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

print("[Follow Script] UI Created!")

-- Function to find target player with error handling
local function findTargetPlayer()
    local success, result = pcall(function()
        print("[Follow Script] Searching for target player...")
        print("[Follow Script] Total players in server: " .. #Players:GetPlayers())

        for _, player in pairs(Players:GetPlayers()) do
            print("[Follow Script] Checking player: " .. player.Name .. " (ID: " .. player.UserId .. ", Display: " .. player.DisplayName .. ")")

            -- Check by User ID
            if player.UserId == TARGET_USER_ID then
                print("[Follow Script] ✓ FOUND by User ID!")
                return player
            end
            -- Check by Username (case insensitive)
            if player.Name:lower() == TARGET_USERNAME:lower() then
                print("[Follow Script] ✓ FOUND by Username!")
                return player
            end
            -- Check by Display Name (case insensitive)
            if player.DisplayName:lower() == TARGET_DISPLAYNAME:lower() then
                print("[Follow Script] ✓ FOUND by Display Name!")
                return player
            end
        end

        print("[Follow Script] ✗ Target not found in server")
        return nil
    end)

    if not success then
        print("[Follow Script] ERROR in findTargetPlayer: " .. result)
        return nil
    end

    return result
end

-- Function to create/update highlight with instance tracking
local function updateHighlight(targetCharacter)
    local success, errorMsg = pcall(function()
        print("[Follow Script] Updating highlight...")

        -- Remove old highlight if it exists and track for cleanup
        if currentHighlight then
            if currentHighlight.Parent then
                currentHighlight:Destroy()
            end
            currentHighlight = nil
        end

        if not targetCharacter then
            print("[Follow Script] No target character for highlight")
            return
        end

        -- Try multiple ESP methods for compatibility
        local highlightSuccess, highlightErr = pcall(function()
            -- Method 1: Try Highlight instance (newer Roblox feature)
            local highlight = trackInstance(Instance.new("Highlight"))
            highlight.Name = "FollowScriptHighlight"
            highlight.Adornee = targetCharacter
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = targetCharacter

            currentHighlight = highlight
            print("[Follow Script] Highlight (Method 1) created successfully!")
        end)

        if not highlightSuccess then
            print("[Follow Script] Highlight failed, trying BoxHandleAdornment...")

            -- Method 2: Fallback to BoxHandleAdornment (older method, more compatible)
            pcall(function()
                -- Get target root part
                local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Torso")

                if rootPart then
                    local box = trackInstance(Instance.new("BoxHandleAdornment"))
                    box.Name = "FollowScriptESP"
                    box.Size = Vector3.new(4, 5, 1)
                    box.Color3 = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.5
                    box.AlwaysOnTop = true
                    box.ZIndex = 10
                    box.Adornee = rootPart
                    box.Parent = rootPart

                    currentHighlight = box
                    print("[Follow Script] BoxHandleAdornment (Method 2) created successfully!")
                end
            end)
        end

        -- Method 3: Apply BillboardGui name tag above head
        pcall(function()
            local head = targetCharacter:FindFirstChild("Head")
            if head then
                -- Remove old billboard and track for cleanup
                local oldBillboard = head:FindFirstChild("FollowScriptTag")
                if oldBillboard then
                    oldBillboard:Destroy()
                end

                local billboard = trackInstance(Instance.new("BillboardGui"))
                billboard.Name = "FollowScriptTag"
                billboard.Size = UDim2.new(0, isMobile and 250 or 200, 0, isMobile and 60 or 50)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = head

                local frame = trackInstance(Instance.new("Frame"))
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                frame.BackgroundTransparency = 0.3
                frame.BorderSizePixel = 2
                frame.BorderColor3 = Color3.fromRGB(255, 255, 0)
                frame.Parent = billboard

                local corner = trackInstance(Instance.new("UICorner"))
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = frame

                local label = trackInstance(Instance.new("TextLabel"))
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = "🎯 TARGET 🎯"
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextSize = isMobile and 20 or 18
                label.Font = Enum.Font.GothamBold
                label.TextStrokeTransparency = 0.5
                label.Parent = frame

                print("[Follow Script] Billboard tag (Method 3) created successfully!")
            end
        end)
    end)

    if not success then
        print("[Follow Script] ERROR in updateHighlight: " .. errorMsg)
    end
end

-- Function to remove highlight with error handling
local function removeHighlight()
    local success, errorMsg = pcall(function()
        if currentHighlight and currentHighlight.Parent then
            currentHighlight:Destroy()
            currentHighlight = nil
            print("[Follow Script] Highlight removed")
        end
    end)

    if not success then
        print("[Follow Script] ERROR in removeHighlight: " .. errorMsg)
    end
end

-- Function to get valid humanoid and root part with error handling
local function getCharacterParts(character)
    local success, humanoid, rootPart = pcall(function()
        if not character then return nil, nil end

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

        return humanoid, rootPart
    end)

    if not success then
        print("[Follow Script] ERROR in getCharacterParts: " .. humanoid)
        return nil, nil
    end

    return humanoid, rootPart
end

-- Function to follow target with error handling
local function followTarget(targetPosition)
    local success, errorMsg = pcall(function()
        local character = LocalPlayer.Character
        if not character then
            statusLabel.Text = "Status: No character\nWaiting..."
            print("[Follow Script] No local character")
            return
        end

        local humanoid, rootPart = getCharacterParts(character)

        if not humanoid or not rootPart then
            statusLabel.Text = "Status: Character parts missing\nRetrying..."
            print("[Follow Script] Missing character parts")
            return
        end

        if humanoid.Health <= 0 then
            statusLabel.Text = "Status: You are dead\nRespawn to continue"
            print("[Follow Script] Local character is dead")
            return
        end

        local distance = (targetPosition - rootPart.Position).Magnitude
        statusLabel.Text = string.format("Status: FOLLOWING\nDistance: %.1f studs\nMoving to target...", distance)

        print(string.format("[Follow Script] Following target (%.1f studs away)", distance))

        if distance > MIN_DISTANCE then
            -- Create path
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                WaypointSpacing = 3
            })

            local pathSuccess, pathError = pcall(function()
                path:ComputeAsync(rootPart.Position, targetPosition)
            end)

            if pathSuccess and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()

                print("[Follow Script] Path computed - " .. #waypoints .. " waypoints")

                if #waypoints >= 2 then
                    local nextWaypoint = waypoints[2]

                    if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoid.Jump = true
                        print("[Follow Script] Jumping!")
                    end

                    humanoid:MoveTo(nextWaypoint.Position)
                    print("[Follow Script] Moving to waypoint")
                else
                    -- Fallback to direct movement
                    humanoid:MoveTo(targetPosition)
                    print("[Follow Script] Direct movement (no waypoints)")
                end
            else
                -- Pathfinding failed, move directly
                humanoid:MoveTo(targetPosition)
                print("[Follow Script] Pathfinding failed, using direct movement")
            end
        else
            -- Within range, stop moving
            humanoid:MoveTo(rootPart.Position)
            statusLabel.Text = string.format("Status: IN RANGE\nDistance: %.1f studs\nStopped", distance)
            print("[Follow Script] In range, stopped")
        end
    end)

    if not success then
        print("[Follow Script] ERROR in followTarget: " .. errorMsg)
        statusLabel.Text = "Status: Movement error\nCheck console for details"
    end
end

-- Main loop with error handling and distance-based optimization
local lastUpdate = 0
local loopCount = 0
local lastDistance = 0
local dynamicUpdateInterval = UPDATE_INTERVAL

print("[Follow Script] Starting main loop...")

connection = RunService.Heartbeat:Connect(function()
    local success, errorMsg = pcall(function()
        if not isEnabled then return end

        local currentTime = tick()

        -- Distance-based update frequency optimization
        local character = LocalPlayer.Character
        local currentDistance = 0
        if character then
            local _, rootPart = getCharacterParts(character)
            if rootPart then
                local targetPlayer = findTargetPlayer()
                if targetPlayer and targetPlayer.Character then
                    local _, targetRoot = getCharacterParts(targetPlayer.Character)
                    if targetRoot then
                        currentDistance = (targetRoot.Position - rootPart.Position).Magnitude
                        -- Reduce update frequency when far away or close to target
                        if currentDistance > 50 then
                            dynamicUpdateInterval = UPDATE_INTERVAL * 2 -- Slower updates when far
                        elseif currentDistance < MIN_DISTANCE * 0.5 then
                            dynamicUpdateInterval = UPDATE_INTERVAL * 0.5 -- Faster updates when very close
                        else
                            dynamicUpdateInterval = UPDATE_INTERVAL -- Normal frequency
                        end
                    end
                end
            end
        end

        if currentTime - lastUpdate < dynamicUpdateInterval then
            return
        end
        lastUpdate = currentTime
        lastDistance = currentDistance
        loopCount = loopCount + 1

        print(string.format("[Follow Script] Loop #%d (Distance: %.1f, Interval: %.2f)",
              loopCount, currentDistance, dynamicUpdateInterval))

        -- Find target player
        local targetPlayer = findTargetPlayer()

        if not targetPlayer then
            statusLabel.Text = "Status: Target not found\nPlayer not in server"
            removeHighlight()
            return
        end

        if not targetPlayer.Character then
            statusLabel.Text = "Status: Target found\nCharacter loading..."
            print("[Follow Script] Target character not loaded yet")
            removeHighlight()
            return
        end

        local targetHumanoid, targetRoot = getCharacterParts(targetPlayer.Character)

        if not targetRoot then
            statusLabel.Text = "Status: Target invalid\nCharacter missing parts"
            print("[Follow Script] Target character invalid")
            removeHighlight()
            return
        end

        if not targetHumanoid or targetHumanoid.Health <= 0 then
            statusLabel.Text = "Status: Target is dead\nWaiting for respawn..."
            print("[Follow Script] Target is dead")
            removeHighlight()
            return
        end

        print("[Follow Script] Target valid, following...")

        -- Update highlight on target
        updateHighlight(targetPlayer.Character)

        -- Follow the target
        followTarget(targetRoot.Position)
    end)

    if not success then
        print("[Follow Script] ERROR in main loop: " .. errorMsg)
        statusLabel.Text = "Status: Script error\nCheck console for details"

        -- Implement exponential backoff for error recovery
        if not lastErrorTime then lastErrorTime = tick() end
        if tick() - lastErrorTime > 5 then -- Only show error after 5 seconds of stability
            warn("[Follow Script] Main loop error: " .. errorMsg)
            lastErrorTime = tick()
        end
    end
end)

print("[Follow Script] ✓ Script fully initialized and running!")
print("[Follow Script] Check the UI for status updates")

-- Try to find target immediately
task.wait(0.5)
local initialTarget = findTargetPlayer()
if initialTarget then
    print("[Follow Script] ✓✓✓ Initial scan: Target found!")
else
    print("[Follow Script] Initial scan: Target not in server")
end

-- Combined mouse/touch event handler for toggle button
local function handleToggleClick()
    local success, errorMsg = pcall(function()
        isEnabled = not isEnabled

        print("[Follow Script] Toggle clicked! New state: " .. tostring(isEnabled))

        if isEnabled then
            toggleButton.Text = "Enabled"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            statusLabel.Text = "Status: ENABLED\nSearching for target..."
            print("[Follow Script] ✓ Script ENABLED")
        else
            toggleButton.Text = "Disabled"
            toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            statusLabel.Text = "Status: DISABLED\nScript paused"

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

            print("[Follow Script] ✗ Script DISABLED")
        end
    end)

    if not success then
        print("[Follow Script] ERROR in toggle handler: " .. errorMsg)
    end
end

toggleButton.MouseButton1Click:Connect(handleToggleClick)
if isMobile then
    toggleButton.TouchTap:Connect(handleToggleClick)
end

-- Combined mouse/touch event handler for destroy button
local function handleDestroyClick()
    local success, errorMsg = pcall(function()
        print("[Follow Script] ✗✗✗ DESTROY BUTTON CLICKED ✗✗✗")

        if connection then
            connection:Disconnect()
            print("[Follow Script] Main loop disconnected")
        end

        -- Remove highlight
        removeHighlight()

        -- Stop movement
        local character = LocalPlayer.Character
        if character then
            local humanoid, rootPart = getCharacterParts(character)
            if humanoid and rootPart then
                humanoid:MoveTo(rootPart.Position)
                print("[Follow Script] Character movement stopped")
            end
        end

        -- Cleanup all tracked instances
        cleanupTrackedInstances()

        print("[Follow Script] ✓ Script fully destroyed")
        print("=== FOLLOW SCRIPT TERMINATED ===")
    end)

    if not success then
        print("[Follow Script] ERROR in destroy handler: " .. errorMsg)
    end
end

destroyButton.MouseButton1Click:Connect(handleDestroyClick)
if isMobile then
    destroyButton.TouchTap:Connect(handleDestroyClick)
end

-- Enhanced character respawn handling with cleanup
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    local success, errorMsg = pcall(function()
        print("[Follow Script] Character respawned! Cleaning up...")

        -- Remove highlight on respawn
        removeHighlight()

        -- Stop any existing movement
        local humanoid = newCharacter:WaitForChild("Humanoid")
        local rootPart = newCharacter:WaitForChild("HumanoidRootPart")
        humanoid:MoveTo(rootPart.Position)

        -- Clear any existing pathfinding computations
        if PathfindingService then
            -- Note: PathfindingService doesn't have explicit cleanup methods
            -- but we can wait a frame to ensure any pending operations complete
            task.wait()
        end

        print("[Follow Script] Character respawn cleanup completed!")
    end)

    if not success then
        print("[Follow Script] ERROR in CharacterAdded handler: " .. errorMsg)
    end
end)

-- Handle character removal for additional cleanup
LocalPlayer.CharacterRemoving:Connect(function(oldCharacter)
    local success, errorMsg = pcall(function()
        print("[Follow Script] Character being removed, cleaning up...")

        -- Remove highlight when character is being removed
        removeHighlight()

        -- Stop movement if possible
        local humanoid = oldCharacter:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid:MoveTo(oldCharacter.PrimaryPart and oldCharacter.PrimaryPart.Position or Vector3.zero)
        end

        print("[Follow Script] Character removal cleanup completed!")
    end)

    if not success then
        print("[Follow Script] ERROR in CharacterRemoving handler: " .. errorMsg)
    end
end)

print("=== FOLLOW SCRIPT READY ===")
print("[Follow Script] If you see this, the script loaded successfully!")
print("[Follow Script] Watch the console for updates every " .. UPDATE_INTERVAL .. " seconds")
