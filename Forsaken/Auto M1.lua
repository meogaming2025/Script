local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local function safePath(root, ...)
    local current = root
    local path = {...}
    for _, name in ipairs(path) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local Sprinting = safePath(ReplicatedStorage, "Systems", "Character", "Game", "Sprinting")
local NetworkRemoteEvent = safePath(ReplicatedStorage, "Modules", "Network", "Network", "RemoteEvent")

local abilityNames = {
    "Slash",
    "Stab",
    "Tag",
    "CarvingSlash",
    "Lacerate",
    "Perforating"
}

local function createSlashBuffer()
    local bytes = { 3, 5, 0, 0, 0, 83, 108, 97, 115, 104 }
    local b = buffer.create(#bytes)
    for i = 1, #bytes do
        buffer.writeu8(b, i - 1, bytes[i])
    end
    return b
end

local function createStabBuffer()
    local bytes = { 3, 4, 0, 0, 0, 83, 116, 97, 98 }
    local b = buffer.create(#bytes)
    for i = 1, #bytes do
        buffer.writeu8(b, i - 1, bytes[i])
    end
    return b
end

local function createTagBuffer()
    local bytes = { 3, 3, 0, 0, 0, 84, 97, 103 }
    local b = buffer.create(#bytes)
    for i = 1, #bytes do
        buffer.writeu8(b, i - 1, bytes[i])
    end
    return b
end

local function createCarvingSlashBuffer()
    local bytes = { 3, 13, 0, 0, 0, 67, 97, 114, 118, 105, 110, 103, 32, 83, 108, 97, 115, 104 }
    local b = buffer.create(#bytes)
    for i = 1, #bytes do
        buffer.writeu8(b, i - 1, bytes[i])
    end
    return b
end

local extremeClickEnabled = false

local function triggerSlash(useAllAbilities)
    local clickCount = extremeClickEnabled and 5 or 1 
    
    if useAllAbilities then
        for _, abilityName in ipairs(abilityNames) do
            local success = false
            
            if NetworkRemoteEvent then
                pcall(function()
                    if abilityName == "Slash" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createSlashBuffer() })
                    elseif abilityName == "Stab" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createStabBuffer() })
                    elseif abilityName == "Tag" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createTagBuffer() })
                    elseif abilityName == "CarvingSlash" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createCarvingSlashBuffer() })
                    else
                        NetworkRemoteEvent:FireServer("UseActorAbility", abilityName)
                    end
                    success = true
                end)
            end

            if not success or extremeClickEnabled then
                local abilityBtn = safePath(playerGui, "MainUI", "AbilityContainer", abilityName)
                if abilityBtn then
                    local targetButton = abilityBtn:IsA("GuiButton") and abilityBtn or abilityBtn:FindFirstChildWhichIsA("GuiButton", true)
                    if targetButton and targetButton.Visible and targetButton.AbsoluteSize.X > 0 then
                        pcall(function()
                            local pos = targetButton.AbsolutePosition + (targetButton.AbsoluteSize / 2)
                            for i = 1, clickCount do
                                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                                task.wait(0.01)
                                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                                if clickCount > 1 then task.wait(0.01) end
                            end
                        end)
                    end
                end
            end
        end
    else
        if NetworkRemoteEvent then
            for _, abilityName in ipairs(abilityNames) do
                pcall(function()
                    if abilityName == "Slash" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createSlashBuffer() })
                    elseif abilityName == "Stab" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createStabBuffer() })
                    elseif abilityName == "Tag" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createTagBuffer() })
                    elseif abilityName == "CarvingSlash" then
                        NetworkRemoteEvent:FireServer("UseActorAbility", { createCarvingSlashBuffer() })
                    else
                        NetworkRemoteEvent:FireServer("UseActorAbility", abilityName)
                    end
                end)
            end
        end
    end
end

local MAX_STAMINA = 110
local STAMINA_LOSS = 9.5
local GAIN_STAMINA = 21
local SPRINT_SPEED = 28
local autoApplyEnabled = false

local RANGE_RADIUS = 9
local RANGE_OPACITY = 1.0
local RANGE_SEGMENTS = 40

local FACING_SIZE_X = 9
local FACING_SIZE_Y = 10
local FACING_SIZE_Z = 9
local FACING_OPACITY = 1.0

local GUEST_DELAY = 0.2 
local M1_DELAY = 0 

local facingCheckEnabled = false 

local function applyStaminaSettings()
    if not Sprinting then return end
    local success, StaminaModule = pcall(require, Sprinting)
    if not success or not StaminaModule then return end
    StaminaModule.MaxStamina = MAX_STAMINA
    StaminaModule.StaminaGain = GAIN_STAMINA
    StaminaModule.StaminaLoss = STAMINA_LOSS
    StaminaModule.SprintSpeed = SPRINT_SPEED
end

task.spawn(function()
    while true do
        task.wait(1.6)
        if autoApplyEnabled then
            applyStaminaSettings()
        end
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MyScreenUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 560, 0, 360)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 10)
titleBarCorner.Parent = titleBar

local titleBarFix = Instance.new("Frame")
titleBarFix.Size = UDim2.new(1, 0, 0, 10)
titleBarFix.Position = UDim2.new(0, 0, 1, -10)
titleBarFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBarFix.BorderSizePixel = 0
titleBarFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MENU 2.0"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 55, 0, 24)
closeButton.Position = UDim2.new(1, -62, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "HIDE"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextScaled = true
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(0, 420, 1, -48)
contentFrame.Position = UDim2.new(0, 10, 0, 44)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Horizontal
contentLayout.Padding = UDim.new(0, 15)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentFrame

local leftColumn = Instance.new("Frame")
leftColumn.Name = "LeftColumn"
leftColumn.Size = UDim2.new(0, 125, 1, 0)
leftColumn.BackgroundTransparency = 1
leftColumn.LayoutOrder = 1
leftColumn.Parent = contentFrame

local leftLayout = Instance.new("UIListLayout")
leftLayout.FillDirection = Enum.FillDirection.Vertical
leftLayout.Padding = UDim.new(0, 8)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Parent = leftColumn

local autoM1Button = Instance.new("TextButton")
autoM1Button.Name = "AutoM1Button"
autoM1Button.Size = UDim2.new(0, 125, 0, 36)
autoM1Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
autoM1Button.Text = "AUTO M1: OFF"
autoM1Button.TextColor3 = Color3.fromRGB(255, 255, 255)
autoM1Button.Font = Enum.Font.GothamBold
autoM1Button.TextScaled = true
autoM1Button.LayoutOrder = 1
autoM1Button.Parent = leftColumn

local autoM1Corner = Instance.new("UICorner")
autoM1Corner.CornerRadius = UDim.new(0, 6)
autoM1Corner.Parent = autoM1Button

local autoM1Enabled = false
local autoM1Connection = nil
local isAttacking = false

local function updateAutoM1Visual()
    if autoM1Enabled then
        autoM1Button.Text = "AUTO M1: ON"
        autoM1Button.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        autoM1Button.Text = "AUTO M1: OFF"
        autoM1Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

local function isGuest1337(survivor)
    local cleanName = survivor.Name:gsub("%s+", ""):lower()
    return cleanName == "guest1337"
end

local function isSurvivorInZone(survivor, myRoot)
    local theirRoot = survivor:FindFirstChild("HumanoidRootPart")
    if not theirRoot then return false end

    if facingCheckEnabled then
        local boxCFrame = myRoot.CFrame * CFrame.new(0, 0, -FACING_SIZE_Z / 2)
        local relative = boxCFrame:PointToObjectSpace(theirRoot.Position)
        
        return math.abs(relative.X) <= FACING_SIZE_X / 2
            and math.abs(relative.Y) <= FACING_SIZE_Y / 2
            and math.abs(relative.Z) <= FACING_SIZE_Z / 2
    else
        local dx = theirRoot.Position.X - myRoot.Position.X
        local dz = theirRoot.Position.Z - myRoot.Position.Z
        local horizontalDist = math.sqrt(dx * dx + dz * dz)
        
        if horizontalDist <= RANGE_RADIUS then return true end
    end

    return false
end

local function startAutoM1()
    if autoM1Connection then return end
    
    autoM1Connection = RunService.Heartbeat:Connect(function()
        if not autoM1Enabled or isAttacking then return end

        local character = player.Character
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local playersFolder = workspace:FindFirstChild("Players")
        local survivorsFolder = playersFolder and playersFolder:FindFirstChild("Survivors")
        if not survivorsFolder then return end

        local targetFound = false
        local isGuestTarget = false

        for _, survivor in ipairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") and isSurvivorInZone(survivor, myRoot) then
                targetFound = true
                if isGuest1337(survivor) then
                    isGuestTarget = true
                end
                break
            end
        end

        if targetFound then
            isAttacking = true
            task.spawn(function()
                local totalDelay = M1_DELAY
                if isGuestTarget and GUEST_DELAY > 0 then
                    totalDelay = totalDelay + GUEST_DELAY
                end

                if totalDelay > 0 then
                    task.wait(totalDelay)
                end
                
                if autoM1Enabled then
                    triggerSlash(isGuestTarget)
                end
                
                task.wait(0.5)
                isAttacking = false
            end)
        end
    end)
end

local function stopAutoM1()
    if autoM1Connection then
        autoM1Connection:Disconnect()
        autoM1Connection = nil
    end
    isAttacking = false
end

autoM1Button.MouseButton1Click:Connect(function()
    autoM1Enabled = not autoM1Enabled
    updateAutoM1Visual()
    if autoM1Enabled then
        startAutoM1()
    else
        stopAutoM1()
    end
end)

local rangeVisualButton = Instance.new("TextButton")
rangeVisualButton.Name = "RangeVisualButton"
rangeVisualButton.Size = UDim2.new(0, 125, 0, 36)
rangeVisualButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
rangeVisualButton.Text = "RANGE VISUAL: OFF"
rangeVisualButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rangeVisualButton.Font = Enum.Font.GothamBold
rangeVisualButton.TextScaled = true
rangeVisualButton.LayoutOrder = 2
rangeVisualButton.Parent = leftColumn

local rangeVisualCorner = Instance.new("UICorner")
rangeVisualCorner.CornerRadius = UDim.new(0, 6)
rangeVisualCorner.Parent = rangeVisualButton

local rangeVisualEnabled = false
local rangeRingParts = {}

local function destroyRangeRing()
    for _, obj in ipairs(rangeRingParts) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    rangeRingParts = {}
end

local function createRangeRing()
    destroyRangeRing()
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local attachments = {}
    for i = 1, RANGE_SEGMENTS do
        local angle = (i / RANGE_SEGMENTS) * math.pi * 2
        local x = math.cos(angle) * RANGE_RADIUS
        local z = math.sin(angle) * RANGE_RADIUS
        local attachment = Instance.new("Attachment")
        attachment.Name = "RangeRingPoint"
        attachment.Position = Vector3.new(x, -(hrp.Size.Y / 2) + 0.2, z)
        attachment.Parent = hrp
        table.insert(attachments, attachment)
        table.insert(rangeRingParts, attachment)
    end

    for i = 1, RANGE_SEGMENTS do
        local nextIndex = (i % RANGE_SEGMENTS) + 1
        local beam = Instance.new("Beam")
        beam.Attachment0 = attachments[i]
        beam.Attachment1 = attachments[nextIndex]
        beam.Width0 = 0.3
        beam.Width1 = 0.3
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
        beam.Transparency = NumberSequence.new(1 - RANGE_OPACITY)
        beam.FaceCamera = false
        beam.Parent = hrp
        table.insert(rangeRingParts, beam)
    end
end

local function updateRangeVisualUI()
    if rangeVisualEnabled then
        rangeVisualButton.Text = "RANGE VISUAL: ON"
        rangeVisualButton.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        rangeVisualButton.Text = "RANGE VISUAL: OFF"
        rangeVisualButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

rangeVisualButton.MouseButton1Click:Connect(function()
    rangeVisualEnabled = not rangeVisualEnabled
    updateRangeVisualUI()
    if rangeVisualEnabled then
        createRangeRing()
    else
        destroyRangeRing()
    end
end)

local radiusContainer = Instance.new("Frame")
radiusContainer.Name = "RadiusContainer"
radiusContainer.Size = UDim2.new(0, 125, 0, 50)
radiusContainer.BackgroundTransparency = 1
radiusContainer.LayoutOrder = 3
radiusContainer.Parent = leftColumn

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Name = "RadiusLabel"
radiusLabel.Size = UDim2.new(1, 0, 0, 16)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Range"
radiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextScaled = true
radiusLabel.Parent = radiusContainer

local rangeRadiusBox = Instance.new("TextBox")
rangeRadiusBox.Name = "RangeRadiusBox"
rangeRadiusBox.Size = UDim2.new(1, 0, 0, 32)
rangeRadiusBox.Position = UDim2.new(0, 0, 0, 16)
rangeRadiusBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
rangeRadiusBox.Text = tostring(RANGE_RADIUS)
rangeRadiusBox.PlaceholderText = "Range"
rangeRadiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
rangeRadiusBox.Font = Enum.Font.GothamBold
rangeRadiusBox.TextScaled = true
rangeRadiusBox.ClearTextOnFocus = false
rangeRadiusBox.Parent = radiusContainer

local rangeRadiusBoxCorner = Instance.new("UICorner")
rangeRadiusBoxCorner.CornerRadius = UDim.new(0, 6)
rangeRadiusBoxCorner.Parent = rangeRadiusBox

rangeRadiusBox.FocusLost:Connect(function()
    local newValue = tonumber(rangeRadiusBox.Text)
    if newValue and newValue > 0 then
        RANGE_RADIUS = newValue
        if rangeVisualEnabled then createRangeRing() end
    else
        rangeRadiusBox.Text = tostring(RANGE_RADIUS)
    end
end)

local opacityContainer = Instance.new("Frame")
opacityContainer.Name = "OpacityContainer"
opacityContainer.Size = UDim2.new(0, 125, 0, 50)
opacityContainer.BackgroundTransparency = 1
opacityContainer.LayoutOrder = 4
opacityContainer.Parent = leftColumn

local opacityLabel = Instance.new("TextLabel")
opacityLabel.Name = "OpacityLabel"
opacityLabel.Size = UDim2.new(1, 0, 0, 16)
opacityLabel.BackgroundTransparency = 1
opacityLabel.Text = "Opacity (0.0-1.0)"
opacityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
opacityLabel.Font = Enum.Font.Gotham
opacityLabel.TextScaled = true
opacityLabel.Parent = opacityContainer

local rangeOpacityBox = Instance.new("TextBox")
rangeOpacityBox.Name = "RangeOpacityBox"
rangeOpacityBox.Size = UDim2.new(1, 0, 0, 32)
rangeOpacityBox.Position = UDim2.new(0, 0, 0, 16)
rangeOpacityBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
rangeOpacityBox.Text = tostring(RANGE_OPACITY)
rangeOpacityBox.PlaceholderText = "Opacity"
rangeOpacityBox.TextColor3 = Color3.fromRGB(255, 255, 255)
rangeOpacityBox.Font = Enum.Font.GothamBold
rangeOpacityBox.TextScaled = true
rangeOpacityBox.ClearTextOnFocus = false
rangeOpacityBox.Parent = opacityContainer

local rangeOpacityBoxCorner = Instance.new("UICorner")
rangeOpacityBoxCorner.CornerRadius = UDim.new(0, 6)
rangeOpacityBoxCorner.Parent = rangeOpacityBox

rangeOpacityBox.FocusLost:Connect(function()
    local newValue = tonumber(rangeOpacityBox.Text)
    if newValue and newValue >= 0 and newValue <= 1 then
        RANGE_OPACITY = newValue
        if rangeVisualEnabled then createRangeRing() end
    else
        rangeOpacityBox.Text = tostring(RANGE_OPACITY)
    end
end)

local middleColumn = Instance.new("Frame")
middleColumn.Name = "MiddleColumn"
middleColumn.Size = UDim2.new(0, 125, 1, 0)
middleColumn.BackgroundTransparency = 1
middleColumn.LayoutOrder = 2
middleColumn.Parent = contentFrame

local middleLayout = Instance.new("UIListLayout")
middleLayout.FillDirection = Enum.FillDirection.Vertical
middleLayout.Padding = UDim.new(0, 8)
middleLayout.SortOrder = Enum.SortOrder.LayoutOrder
middleLayout.Parent = middleColumn

local facingCheckButton = Instance.new("TextButton")
facingCheckButton.Name = "FacingCheckButton"
facingCheckButton.Size = UDim2.new(0, 125, 0, 36)
facingCheckButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
facingCheckButton.Text = "FACING CHECK: OFF"
facingCheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
facingCheckButton.Font = Enum.Font.GothamBold
facingCheckButton.TextScaled = true
facingCheckButton.LayoutOrder = 1
facingCheckButton.Parent = middleColumn

local facingCheckCorner = Instance.new("UICorner")
facingCheckCorner.CornerRadius = UDim.new(0, 6)
facingCheckCorner.Parent = facingCheckButton

local function updateFacingCheckVisual()
    if facingCheckEnabled then
        facingCheckButton.Text = "FACING CHECK: ON"
        facingCheckButton.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        facingCheckButton.Text = "FACING CHECK: OFF"
        facingCheckButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

facingCheckButton.MouseButton1Click:Connect(function()
    facingCheckEnabled = not facingCheckEnabled
    updateFacingCheckVisual()
end)

local facingVisualButton = Instance.new("TextButton")
facingVisualButton.Name = "FacingVisualButton"
facingVisualButton.Size = UDim2.new(0, 125, 0, 36)
facingVisualButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
facingVisualButton.Text = "FACING VISUAL: OFF"
facingVisualButton.TextColor3 = Color3.fromRGB(255, 255, 255)
facingVisualButton.Font = Enum.Font.GothamBold
facingVisualButton.TextScaled = true
facingVisualButton.LayoutOrder = 2
facingVisualButton.Parent = middleColumn

local facingVisualCorner = Instance.new("UICorner")
facingVisualCorner.CornerRadius = UDim.new(0, 6)
facingVisualCorner.Parent = facingVisualButton

local facingVisualEnabled = false
local facingBox = nil
local facingSelectionBox = nil
local facingConnection = nil

local function destroyFacingBox()
    if facingConnection then
        facingConnection:Disconnect()
        facingConnection = nil
    end
    if facingBox then
        facingBox:Destroy()
        facingBox = nil
        facingSelectionBox = nil
    end
end

local function createFacingBox()
    destroyFacingBox()
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    facingBox = Instance.new("Part")
    facingBox.Name = "FacingCheckBox"
    facingBox.Anchored = true
    facingBox.CanCollide = false
    facingBox.CanQuery = false
    facingBox.Transparency = 1
    facingBox.Size = Vector3.new(FACING_SIZE_X, FACING_SIZE_Y, FACING_SIZE_Z)
    facingBox.Parent = workspace

    facingSelectionBox = Instance.new("SelectionBox")
    facingSelectionBox.Adornee = facingBox
    facingSelectionBox.Color3 = Color3.fromRGB(255, 255, 0)
    facingSelectionBox.LineThickness = 0.05
    facingSelectionBox.SurfaceTransparency = 1
    facingSelectionBox.Transparency = 1 - FACING_OPACITY
    facingSelectionBox.Parent = facingBox

    facingConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root or not facingBox then return end
        facingBox.CFrame = root.CFrame * CFrame.new(0, 0, -FACING_SIZE_Z / 2)
    end)
end

local function updateFacingVisualUI()
    if facingVisualEnabled then
        facingVisualButton.Text = "FACING VISUAL: ON"
        facingVisualButton.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        facingVisualButton.Text = "FACING VISUAL: OFF"
        facingVisualButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

facingVisualButton.MouseButton1Click:Connect(function()
    facingVisualEnabled = not facingVisualEnabled
    updateFacingVisualUI()
    if facingVisualEnabled then
        createFacingBox()
    else
        destroyFacingBox()
    end
end)

local function createFacingSizeBox(labelText, layoutOrder, defaultValue, onChanged)
    local container = Instance.new("Frame")
    container.Name = labelText .. "Container"
    container.Size = UDim2.new(0, 125, 0, 50)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container.Parent = middleColumn

    local label = Instance.new("TextLabel")
    label.Name = labelText .. "Label"
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Name = labelText .. "Box"
    box.Size = UDim2.new(1, 0, 0, 32)
    box.Position = UDim2.new(0, 0, 0, 16)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.Text = tostring(defaultValue)
    box.PlaceholderText = labelText
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextScaled = true
    box.ClearTextOnFocus = false
    box.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box

    box.FocusLost:Connect(function()
        local newValue = tonumber(box.Text)
        onChanged(newValue, box)
    end)

    return box
end

createFacingSizeBox("X", 3, FACING_SIZE_X, function(newValue, box)
    if newValue and newValue > 0 then
        FACING_SIZE_X = newValue
        if facingVisualEnabled then createFacingBox() end
    else
        box.Text = tostring(FACING_SIZE_X)
    end
end)

createFacingSizeBox("Y", 4, FACING_SIZE_Y, function(newValue, box)
    if newValue and newValue > 0 then
        FACING_SIZE_Y = newValue
        if facingVisualEnabled then createFacingBox() end
    else
        box.Text = tostring(FACING_SIZE_Y)
    end
end)

createFacingSizeBox("Z", 5, FACING_SIZE_Z, function(newValue, box)
    if newValue and newValue > 0 then
        FACING_SIZE_Z = newValue
        if facingVisualEnabled then createFacingBox() end
    else
        box.Text = tostring(FACING_SIZE_Z)
    end
end)

local rightColumn = Instance.new("Frame")
rightColumn.Name = "RightColumn"
rightColumn.Size = UDim2.new(0, 125, 1, 0)
rightColumn.BackgroundTransparency = 1
rightColumn.LayoutOrder = 3
rightColumn.Parent = contentFrame

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Vertical
rightLayout.Padding = UDim.new(0, 8)
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Parent = rightColumn

local espButton = Instance.new("TextButton")
espButton.Name = "ESPButton"
espButton.Size = UDim2.new(0, 125, 0, 36)
espButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espButton.Text = "ESP SURVIVORS: OFF"
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.Font = Enum.Font.GothamBold
espButton.TextScaled = true
espButton.LayoutOrder = 1
espButton.Parent = rightColumn

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 6)
espCorner.Parent = espButton

local espEnabled = false
local espHighlights = {}
local espConnections = {}

local function addESPHighlight(survivor)
    if not survivor:IsA("Model") or espHighlights[survivor] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = survivor

    espHighlights[survivor] = highlight
end

local function removeESPHighlights()
    for _, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then highlight:Destroy() end
    end
    espHighlights = {}

    for _, conn in ipairs(espConnections) do conn:Disconnect() end
    espConnections = {}
end

local function createESP()
    removeESPHighlights()

    local playersFolder = workspace:FindFirstChild("Players")
    local survivorsFolder = playersFolder and playersFolder:FindFirstChild("Survivors")
    if not survivorsFolder then return end

    for _, survivor in ipairs(survivorsFolder:GetChildren()) do
        addESPHighlight(survivor)
    end

    table.insert(espConnections, survivorsFolder.ChildAdded:Connect(addESPHighlight))
    table.insert(espConnections, survivorsFolder.ChildRemoved:Connect(function(child)
        if espHighlights[child] then
            espHighlights[child]:Destroy()
            espHighlights[child] = nil
        end
    end))
end

local function updateESPVisual()
    if espEnabled then
        espButton.Text = "ESP SURVIVORS: ON"
        espButton.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        espButton.Text = "ESP SURVIVORS: OFF"
        espButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    updateESPVisual()
    if espEnabled then createESP() else removeESPHighlights() end
end)

local extremeClickButton = Instance.new("TextButton")
extremeClickButton.Name = "ExtremeClickButton"
extremeClickButton.Size = UDim2.new(0, 125, 0, 36)
extremeClickButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
extremeClickButton.Text = "EXTREME CLICK: OFF"
extremeClickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
extremeClickButton.Font = Enum.Font.GothamBold
extremeClickButton.TextScaled = true
extremeClickButton.LayoutOrder = 2
extremeClickButton.Parent = rightColumn

local extremeClickCorner = Instance.new("UICorner")
extremeClickCorner.CornerRadius = UDim.new(0, 6)
extremeClickCorner.Parent = extremeClickButton

local function updateExtremeClickVisual()
    if extremeClickEnabled then
        extremeClickButton.Text = "EXTREME CLICK: ON"
        extremeClickButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    else
        extremeClickButton.Text = "EXTREME CLICK: OFF"
        extremeClickButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

extremeClickButton.MouseButton1Click:Connect(function()
    extremeClickEnabled = not extremeClickEnabled
    updateExtremeClickVisual()
end)

local guestDelayContainer = Instance.new("Frame")
guestDelayContainer.Name = "GuestDelayContainer"
guestDelayContainer.Size = UDim2.new(0, 125, 0, 50)
guestDelayContainer.BackgroundTransparency = 1
guestDelayContainer.LayoutOrder = 3
guestDelayContainer.Parent = rightColumn

local guestDelayLabel = Instance.new("TextLabel")
guestDelayLabel.Name = "GuestDelayLabel"
guestDelayLabel.Size = UDim2.new(1, 0, 0, 16)
guestDelayLabel.BackgroundTransparency = 1
guestDelayLabel.Text = "Guest 1337 delay"
guestDelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
guestDelayLabel.Font = Enum.Font.Gotham
guestDelayLabel.TextScaled = true
guestDelayLabel.Parent = guestDelayContainer

local guestDelayBox = Instance.new("TextBox")
guestDelayBox.Name = "GuestDelayBox"
guestDelayBox.Size = UDim2.new(1, 0, 0, 32)
guestDelayBox.Position = UDim2.new(0, 0, 0, 16)
guestDelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
guestDelayBox.Text = tostring(GUEST_DELAY)
guestDelayBox.PlaceholderText = "Delay (s)"
guestDelayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
guestDelayBox.Font = Enum.Font.GothamBold
guestDelayBox.TextScaled = true
guestDelayBox.ClearTextOnFocus = false
guestDelayBox.Parent = guestDelayContainer

local guestDelayCorner = Instance.new("UICorner")
guestDelayCorner.CornerRadius = UDim.new(0, 6)
guestDelayCorner.Parent = guestDelayBox

guestDelayBox.FocusLost:Connect(function()
    local newValue = tonumber(guestDelayBox.Text)
    if newValue and newValue >= 0 then
        GUEST_DELAY = newValue
    else
        guestDelayBox.Text = tostring(GUEST_DELAY)
    end
end)

local m1DelayContainer = Instance.new("Frame")
m1DelayContainer.Name = "M1DelayContainer"
m1DelayContainer.Size = UDim2.new(0, 125, 0, 50)
m1DelayContainer.BackgroundTransparency = 1
m1DelayContainer.LayoutOrder = 4
m1DelayContainer.Parent = rightColumn

local m1DelayLabel = Instance.new("TextLabel")
m1DelayLabel.Name = "M1DelayLabel"
m1DelayLabel.Size = UDim2.new(1, 0, 0, 16)
m1DelayLabel.BackgroundTransparency = 1
m1DelayLabel.Text = "M1 delay"
m1DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
m1DelayLabel.Font = Enum.Font.Gotham
m1DelayLabel.TextScaled = true
m1DelayLabel.Parent = m1DelayContainer

local m1DelayBox = Instance.new("TextBox")
m1DelayBox.Name = "M1DelayBox"
m1DelayBox.Size = UDim2.new(1, 0, 0, 32)
m1DelayBox.Position = UDim2.new(0, 0, 0, 16)
m1DelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
m1DelayBox.Text = tostring(M1_DELAY)
m1DelayBox.PlaceholderText = "Delay (s)"
m1DelayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
m1DelayBox.Font = Enum.Font.GothamBold
m1DelayBox.TextScaled = true
m1DelayBox.ClearTextOnFocus = false
m1DelayBox.Parent = m1DelayContainer

local m1DelayCorner = Instance.new("UICorner")
m1DelayCorner.CornerRadius = UDim.new(0, 6)
m1DelayCorner.Parent = m1DelayBox

m1DelayBox.FocusLost:Connect(function()
    local newValue = tonumber(m1DelayBox.Text)
    if newValue and newValue >= 0 then
        M1_DELAY = newValue
    else
        m1DelayBox.Text = tostring(M1_DELAY)
    end
end)

local pageSwitchColumn = Instance.new("Frame")
pageSwitchColumn.Name = "PageSwitchColumn"
pageSwitchColumn.Size = UDim2.new(0, 110, 0, 300)
pageSwitchColumn.Position = UDim2.new(0, 440, 0, 44)
pageSwitchColumn.BackgroundTransparency = 1
pageSwitchColumn.Parent = mainFrame

local pageSwitchContainer = Instance.new("Frame")
pageSwitchContainer.Name = "PageSwitchContainer"
pageSwitchContainer.Size = UDim2.new(1, 0, 0, 36)
pageSwitchContainer.AnchorPoint = Vector2.new(0.5, 0.5)
pageSwitchContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
pageSwitchContainer.BackgroundTransparency = 1
pageSwitchContainer.Parent = pageSwitchColumn

local pageUpButton = Instance.new("TextButton")
pageUpButton.Name = "PageUpButton"
pageUpButton.Size = UDim2.new(1, 0, 1, 0)
pageUpButton.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
pageUpButton.Text = "▲ UP"
pageUpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
pageUpButton.Font = Enum.Font.GothamBold
pageUpButton.TextScaled = true
pageUpButton.Parent = pageSwitchContainer

local pageUpCorner = Instance.new("UICorner")
pageUpCorner.CornerRadius = UDim.new(0, 6)
pageUpCorner.Parent = pageUpButton

local pageDownButton = Instance.new("TextButton")
pageDownButton.Name = "PageDownButton"
pageDownButton.Size = UDim2.new(1, 0, 1, 0)
pageDownButton.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
pageDownButton.Text = "▼ DOWN"
pageDownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
pageDownButton.Font = Enum.Font.GothamBold
pageDownButton.TextScaled = true
pageDownButton.Visible = false
pageDownButton.Parent = pageSwitchContainer

local pageDownCorner = Instance.new("UICorner")
pageDownCorner.CornerRadius = UDim.new(0, 6)
pageDownCorner.Parent = pageDownButton

local page2Frame = Instance.new("Frame")
page2Frame.Name = "Page2Frame"
page2Frame.Size = UDim2.new(0, 420, 1, -48)
page2Frame.Position = UDim2.new(0, 10, 0, 44)
page2Frame.BackgroundTransparency = 1
page2Frame.Visible = false
page2Frame.Parent = mainFrame

local page2Layout = Instance.new("UIListLayout")
page2Layout.FillDirection = Enum.FillDirection.Horizontal
page2Layout.Padding = UDim.new(0, 15)
page2Layout.SortOrder = Enum.SortOrder.LayoutOrder
page2Layout.Parent = page2Frame

local function createLabeledTextBox(parentColumn, labelText, layoutOrder, defaultValue, onChanged)
    local container = Instance.new("Frame")
    container.Name = labelText:gsub("%s+", "") .. "Container"
    container.Size = UDim2.new(0, 125, 0, 50)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container.Parent = parentColumn

    local label = Instance.new("TextLabel")
    label.Name = labelText:gsub("%s+", "") .. "Label"
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Name = labelText:gsub("%s+", "") .. "Box"
    box.Size = UDim2.new(1, 0, 0, 32)
    box.Position = UDim2.new(0, 0, 0, 16)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.Text = tostring(defaultValue)
    box.PlaceholderText = labelText
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextScaled = true
    box.ClearTextOnFocus = false
    box.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box

    box.FocusLost:Connect(function()
        local newValue = tonumber(box.Text)
        onChanged(newValue, box)
    end)

    return box
end

local page2Column1 = Instance.new("Frame")
page2Column1.Name = "Page2Column1"
page2Column1.Size = UDim2.new(0, 125, 1, 0)
page2Column1.BackgroundTransparency = 1
page2Column1.LayoutOrder = 1
page2Column1.Parent = page2Frame

local page2Column1Layout = Instance.new("UIListLayout")
page2Column1Layout.FillDirection = Enum.FillDirection.Vertical
page2Column1Layout.Padding = UDim.new(0, 8)
page2Column1Layout.SortOrder = Enum.SortOrder.LayoutOrder
page2Column1Layout.Parent = page2Column1

local applySettingsButton = Instance.new("TextButton")
applySettingsButton.Name = "ApplySettingsButton"
applySettingsButton.Size = UDim2.new(0, 125, 0, 36)
applySettingsButton.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
applySettingsButton.Text = "APPLY SETTINGS"
applySettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
applySettingsButton.Font = Enum.Font.GothamBold
applySettingsButton.TextScaled = true
applySettingsButton.LayoutOrder = 1
applySettingsButton.Parent = page2Column1

local applySettingsCorner = Instance.new("UICorner")
applySettingsCorner.CornerRadius = UDim.new(0, 6)
applySettingsCorner.Parent = applySettingsButton

applySettingsButton.MouseButton1Click:Connect(applyStaminaSettings)

local killerStaminaButton = Instance.new("TextButton")
killerStaminaButton.Name = "KillerStaminaButton"
killerStaminaButton.Size = UDim2.new(0, 125, 0, 36)
killerStaminaButton.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
killerStaminaButton.Text = "KILLER STAMINA"
killerStaminaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
killerStaminaButton.Font = Enum.Font.GothamBold
killerStaminaButton.TextScaled = true
killerStaminaButton.LayoutOrder = 2
killerStaminaButton.Parent = page2Column1

local killerStaminaCorner = Instance.new("UICorner")
killerStaminaCorner.CornerRadius = UDim.new(0, 6)
killerStaminaCorner.Parent = killerStaminaButton

local maxStaminaBox = createLabeledTextBox(page2Column1, "Max Stamina", 3, MAX_STAMINA, function(newValue, box)
    if newValue and newValue > 0 then
        MAX_STAMINA = newValue
        if autoApplyEnabled then applyStaminaSettings() end
    else
        box.Text = tostring(MAX_STAMINA)
    end
end)

local staminaLossBox = createLabeledTextBox(page2Column1, "Stamina Loss", 4, STAMINA_LOSS, function(newValue, box)
    if newValue and newValue >= 0 then
        STAMINA_LOSS = newValue
        if autoApplyEnabled then applyStaminaSettings() end
    else
        box.Text = tostring(STAMINA_LOSS)
    end
end)

local page2Column2 = Instance.new("Frame")
page2Column2.Name = "Page2Column2"
page2Column2.Size = UDim2.new(0, 125, 1, 0)
page2Column2.BackgroundTransparency = 1
page2Column2.LayoutOrder = 2
page2Column2.Parent = page2Frame

local page2Column2Layout = Instance.new("UIListLayout")
page2Column2Layout.FillDirection = Enum.FillDirection.Vertical
page2Column2Layout.Padding = UDim.new(0, 8)
page2Column2Layout.SortOrder = Enum.SortOrder.LayoutOrder
page2Column2Layout.Parent = page2Column2

local autoApplyButton = Instance.new("TextButton")
autoApplyButton.Name = "AutoApplyButton"
autoApplyButton.Size = UDim2.new(0, 125, 0, 36)
autoApplyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
autoApplyButton.Text = "AUTO APPLY SETTINGS: OFF"
autoApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoApplyButton.Font = Enum.Font.GothamBold
autoApplyButton.TextScaled = true
autoApplyButton.LayoutOrder = 1
autoApplyButton.Parent = page2Column2

local autoApplyCorner = Instance.new("UICorner")
autoApplyCorner.CornerRadius = UDim.new(0, 6)
autoApplyCorner.Parent = autoApplyButton

local function updateAutoApplyVisual()
    if autoApplyEnabled then
        autoApplyButton.Text = "AUTO APPLY SETTINGS: ON"
        autoApplyButton.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        autoApplyButton.Text = "AUTO APPLY SETTINGS: OFF"
        autoApplyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

autoApplyButton.MouseButton1Click:Connect(function()
    autoApplyEnabled = not autoApplyEnabled
    updateAutoApplyVisual()
    if autoApplyEnabled then applyStaminaSettings() end
end)

local survivorStaminaButton = Instance.new("TextButton")
survivorStaminaButton.Name = "SurvivorStaminaButton"
survivorStaminaButton.Size = UDim2.new(0, 125, 0, 36)
survivorStaminaButton.BackgroundColor3 = Color3.fromRGB(60, 130, 160)
survivorStaminaButton.Text = "SURVIVOR STAMINA"
survivorStaminaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
survivorStaminaButton.Font = Enum.Font.GothamBold
survivorStaminaButton.TextScaled = true
survivorStaminaButton.LayoutOrder = 2
survivorStaminaButton.Parent = page2Column2

local survivorStaminaCorner = Instance.new("UICorner")
survivorStaminaCorner.CornerRadius = UDim.new(0, 6)
survivorStaminaCorner.Parent = survivorStaminaButton

local gainStaminaBox = createLabeledTextBox(page2Column2, "Gain Stamina", 3, GAIN_STAMINA, function(newValue, box)
    if newValue and newValue >= 0 then
        GAIN_STAMINA = newValue
        if autoApplyEnabled then applyStaminaSettings() end
    else
        box.Text = tostring(GAIN_STAMINA)
    end
end)

local sprintSpeedBox = createLabeledTextBox(page2Column2, "Sprint Speed", 4, SPRINT_SPEED, function(newValue, box)
    if newValue and newValue > 0 then
        SPRINT_SPEED = newValue
        if autoApplyEnabled then applyStaminaSettings() end
    else
        box.Text = tostring(SPRINT_SPEED)
    end
end)

local function applyStaminaPreset(maxStamina, gainStamina, staminaLoss, sprintSpeed)
    MAX_STAMINA = maxStamina
    GAIN_STAMINA = gainStamina
    STAMINA_LOSS = staminaLoss
    SPRINT_SPEED = sprintSpeed

    maxStaminaBox.Text = tostring(MAX_STAMINA)
    staminaLossBox.Text = tostring(STAMINA_LOSS)
    gainStaminaBox.Text = tostring(GAIN_STAMINA)
    sprintSpeedBox.Text = tostring(SPRINT_SPEED)

    if autoApplyEnabled then applyStaminaSettings() end
end

killerStaminaButton.MouseButton1Click:Connect(function()
    applyStaminaPreset(110, 21, 9.5, 28)
end)

survivorStaminaButton.MouseButton1Click:Connect(function()
    applyStaminaPreset(100, 20, 10, 26)
end)

local currentPage = 1

local function updatePageButtons()
    pageUpButton.Visible = (currentPage == 1)
    pageDownButton.Visible = (currentPage == 2)
end

pageUpButton.MouseButton1Click:Connect(function()
    if currentPage == 2 then return end
    currentPage = 2
    contentFrame.Visible = false
    page2Frame.Visible = true
    updatePageButtons()
end)

pageDownButton.MouseButton1Click:Connect(function()
    if currentPage == 1 then return end
    currentPage = 1
    page2Frame.Visible = false
    contentFrame.Visible = true
    updatePageButtons()
end)

updatePageButtons()

player.CharacterAdded:Connect(function()
    task.wait(1)
    if rangeVisualEnabled then createRangeRing() end
    if facingVisualEnabled then createFacingBox() end
end)

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 75, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
toggleButton.Text = "UNHIDE"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextScaled = true
toggleButton.Visible = false
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

local openSize = mainFrame.Size
local closedSize = UDim2.new(0, 560, 0, 0)
local isOpen = true

local function closeUI()
    isOpen = false
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = closedSize
    })
    tween:Play()
    tween.Completed:Connect(function()
        if not isOpen then
            mainFrame.Visible = false
            toggleButton.Visible = true
        end
    end)
end

local function openUI()
    isOpen = true
    toggleButton.Visible = false
    mainFrame.Visible = true
    mainFrame.Size = closedSize
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = openSize
    })
    tween:Play()
end

local function makeDraggable(inputObject, targetObject, onClick)
    local dragging = false
    local dragInput, dragStart, startPos
    local didDrag = false

    local function update(input)
        local delta = input.Position - dragStart
        if delta.Magnitude > 3 then didDrag = true end
        targetObject.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    inputObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            didDrag = false
            dragStart = input.Position
            startPos = targetObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not didDrag and onClick then onClick() end
                end
            end)
        end
    end)

    inputObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

makeDraggable(titleBar, mainFrame, nil)
makeDraggable(toggleButton, toggleButton, openUI)

closeButton.MouseButton1Click:Connect(closeUI)
