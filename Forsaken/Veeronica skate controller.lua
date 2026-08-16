local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local shiftlockEnabled = false
local connection

local function setShiftlock(state)
    shiftlockEnabled = state

    if connection then
        connection:Disconnect()
        connection = nil
    end

    if shiftlockEnabled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        connection = RunService.RenderStepped:Connect(function()
            local character = lp.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                local camCF = camera.CFrame
                root.CFrame = CFrame.new(root.Position, Vector3.new(
                    camCF.LookVector.X + root.Position.X,
                    root.Position.Y,
                    camCF.LookVector.Z + root.Position.Z
                ))
            end
        end)
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

local chargeAnimIds = {
    "117058860640843"
}

-- Override speed (same as your noli script)
local ORIGINAL_DASH_SPEED = 60

-- Toggle / runtime state
local controlChargeEnabled = true
local controlChargeActive = false
local overrideConnection = nil
local detectorChargeIds = (type(chargeAnimIds) == "table" and chargeAnimIds) or {}

-- Save/restore for humanoid original values
local savedHumanoidState = {}

local function getHumanoid()
    if not lp or not lp.Character then return nil end
    return lp.Character:FindFirstChildOfClass("Humanoid")
end

local function saveHumState(hum)
    if not hum then return end
    if savedHumanoidState[hum] then return end
    local s = {}
    pcall(function()
        s.WalkSpeed = hum.WalkSpeed
        -- support either JumpPower or JumpHeight
        local ok, _ = pcall(function() s.JumpPower = hum.JumpPower end)
        if not ok then
            pcall(function() s.JumpPower = hum.JumpHeight end)
        end
        -- AutoRotate might not exist on all Humanoids; try to capture if possible
        local ok2, ar = pcall(function() return hum.AutoRotate end)
        if ok2 then s.AutoRotate = ar end
        s.PlatformStand = hum.PlatformStand
    end)
    savedHumanoidState[hum] = s
end

local function restoreHumState(hum)
    if not hum then return end
    local s = savedHumanoidState[hum]
    if not s then return end
    pcall(function()
        if s.WalkSpeed ~= nil then hum.WalkSpeed = s.WalkSpeed end
        if s.JumpPower ~= nil then
            local ok, _ = pcall(function() hum.JumpPower = s.JumpPower end)
            if not ok then pcall(function() hum.JumpHeight = s.JumpPower end) end
        end
        if s.AutoRotate ~= nil then pcall(function() hum.AutoRotate = s.AutoRotate end) end
        if s.PlatformStand ~= nil then hum.PlatformStand = s.PlatformStand end
    end)
    savedHumanoidState[hum] = nil
end

-- Start the override (forces dash movement similar to noli void rush)
local function startOverride()
    if controlChargeActive then return end
    local hum = getHumanoid()
    if not hum then return end

    controlChargeActive = true
    saveHumState(hum)

    -- Make sure humanoid is set to dash state
    pcall(function()
        hum.WalkSpeed = ORIGINAL_DASH_SPEED
        hum.AutoRotate = false
    end)
    
    setShiftlock(true)
    
    -- RenderStepped connection to force forward movement every frame (like your noli function)
    overrideConnection = RunService.RenderStepped:Connect(function()
        local humanoid = getHumanoid()
        local rootPart = humanoid and humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end

        -- ensure speed + autorotate each frame (helps if some other code fights it)
        pcall(function()
            humanoid.WalkSpeed = ORIGINAL_DASH_SPEED
            humanoid.AutoRotate = false
        end)

        local direction = rootPart.CFrame.LookVector
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        if horizontal.Magnitude > 0 then
            humanoid:Move(horizontal.Unit)
        else
            humanoid:Move(Vector3.new(0,0,0))
        end
    end)
end

-- Stop the override and restore humanoid state
local function stopOverride()
    if not controlChargeActive then return end
    controlChargeActive = false

    -- disconnect override loop
    if overrideConnection then
        pcall(function() overrideConnection:Disconnect() end)
        overrideConnection = nil
    end

    setShiftlock(false)

    -- restore humanoid fields
    local hum = getHumanoid()
    if hum then
        pcall(function()
            -- restore saved values if present
            restoreHumState(hum)
            -- ensure we stop movement
            hum:Move(Vector3.new(0,0,0))
        end)
    end
end

-- Internal detection: look for playing anim tracks that match charge IDs or custom ID
local function detectChargeAnimation()
    local hum = getHumanoid()
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function()
            return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
        end)
        if ok and animId and animId ~= "" then
            if detectorChargeIds and table.find(detectorChargeIds, animId) then
                return true
            end
        end
    end
    return false
end

-- Public toggle control
local function ControlCharge_SetEnabled(val)
    controlChargeEnabled = val and true or false
    if not controlChargeEnabled and controlChargeActive then
        stopOverride()
    end
end

-- Main loop: check detection each RenderStepped (uses same cadence as noli script)
RunService.RenderStepped:Connect(function()
    if not controlChargeEnabled then
        if controlChargeActive then stopOverride() end
        return
    end

    -- If humanoid dies or character resets, ensure override cleared
    local hum = getHumanoid()
    if not hum then
        if controlChargeActive then stopOverride() end
        return
    end

    local isCharging = detectChargeAnimation()

    if isCharging then
        if not controlChargeActive then
            startOverride()
        end
    else
        if controlChargeActive then
            stopOverride()
        end
    end
end)

-- Keep humanoid state fresh on CharacterAdded
lp.CharacterAdded:Connect(function(char)
    -- small wait to let Humanoid exist
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 2)
        if hum then
            -- optionally prime saved state (not necessary)
        end
    end)
end)

lp.CharacterAdded:Connect(function()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end)
