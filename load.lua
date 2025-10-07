-- Roblox Auto-Walk Forward Script for Mobile/Executor
-- Compatible with Synapse X and similar executors
-- Designed for mobile devices and touch controls

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Function to make character walk forward
local function walkForward()
    -- Check if LocalPlayer exists
    if not LocalPlayer then
        warn("LocalPlayer not found")
        return false
    end

    -- Check if character exists and is loaded
    local Character = LocalPlayer.Character
    if not Character then
        warn("Character not found")
        return false
    end

    -- Check if Humanoid exists
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        warn("Humanoid not found")
        return false
    end

    -- Check if Humanoid is alive
    if Humanoid.Health <= 0 then
        warn("Humanoid is dead")
        return false
    end

    -- Move character forward using MoveTo with calculated position
    -- This works with mobile touch controls and avoids read-only property error
    local currentPos = Character.PrimaryPart.Position
    local forwardDirection = Character.PrimaryPart.CFrame.LookVector
    local moveDistance = Humanoid.WalkSpeed * 0.1 -- Move forward by 0.1 seconds worth of distance

    local targetPos = currentPos + (forwardDirection * moveDistance)
    Humanoid:MoveTo(targetPos)

    return true
end

-- Main loop function
local function mainLoop()
    while true do
        -- Use pcall for error handling
        local success, result = pcall(walkForward)

        if not success then
            warn("Error in walkForward:", result)
        elseif not result then
            -- If walkForward returns false, wait a bit before trying again
            wait(1)
        end

        -- Small delay to prevent excessive CPU usage
        RunService.Heartbeat:Wait()
    end
end

-- Start the script
print("Starting auto-walk script...")
mainLoop()
