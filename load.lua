-- Roblox Player Tracking Script
-- Continuously teleports below target player (username: "shteppiii") and faces their direction

local TARGET_USERNAME = "shteppiii"
local TELEPORT_OFFSET = Vector3.new(0, -8, 0) -- 8 studs below target
local UPDATE_INTERVAL = 0.5 -- Update every 0.5 seconds to avoid detection

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Function to find target player by username
local function findTargetPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == TARGET_USERNAME then
            return player
        end
    end
    return nil
end

-- Function to teleport below target and face their direction
local function teleportBelowTarget()
    local targetPlayer = findTargetPlayer()

    if not targetPlayer or not targetPlayer.Character then
        return false -- Target not found or no character
    end

    local targetCharacter = targetPlayer.Character
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")

    if not targetRootPart then
        return false -- No HumanoidRootPart found
    end

    -- Get target's position and facing direction
    local targetPosition = targetRootPart.Position
    local targetCFrame = targetRootPart.CFrame

    -- Calculate position below target
    local teleportPosition = targetPosition + TELEPORT_OFFSET

    -- Get local player's character and root part
    if not LocalPlayer.Character then
        return false -- Local player has no character
    end

    local localRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRootPart then
        return false -- No HumanoidRootPart found
    end

    -- Create new CFrame with position below target but same rotation as target
    local newCFrame = CFrame.new(teleportPosition) * targetCFrame.Rotation

    -- Teleport local player
    localRootPart.CFrame = newCFrame

    return true -- Successfully teleported
end

-- Function to handle errors gracefully
local function safeTeleport()
    local success, result = pcall(teleportBelowTarget)
    if not success then
        warn("Teleport error: " .. result)
        return false
    end
    return result
end

-- Main loop
local function startTracking()
    print("Starting player tracking script for username: " .. TARGET_USERNAME)

    while true do
        local success = safeTeleport()

        if success then
            -- Successfully teleported, brief pause before next update
            wait(UPDATE_INTERVAL)
        else
            -- Target not found or error occurred, wait longer before retrying
            print("Target player not found or error occurred, retrying in 2 seconds...")
            wait(2)
        end
    end
end

-- Handle player leaving (cleanup if needed)
LocalPlayer.CharacterRemoving:Connect(function()
    print("Local player character removing - tracking will continue when character respawns")
end)

-- Start the tracking script
startTracking()
