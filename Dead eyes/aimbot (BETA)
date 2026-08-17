local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local oldLangGui = PlayerGui:FindFirstChild("LanguageSelectGui")
if oldLangGui then oldLangGui:Destroy() end

local langGui = Instance.new("ScreenGui")
langGui.Name = "LanguageSelectGui"
langGui.ResetOnSpawn = false
langGui.Parent = PlayerGui

local langFrame = Instance.new("Frame")
langFrame.Size = UDim2.new(0, 260, 0, 150)
langFrame.Position = UDim2.new(0.5, -130, 0.5, -75)
langFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
langFrame.Parent = langGui
Instance.new("UICorner", langFrame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Select language"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = langFrame

local viBtn = Instance.new("TextButton")
viBtn.Size = UDim2.new(0, 105, 0, 45)
viBtn.Position = UDim2.new(0, 15, 0, 75)
viBtn.Text = "Vietnamese"
viBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
viBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
viBtn.TextSize = 14
viBtn.Font = Enum.Font.SourceSansBold
viBtn.Parent = langFrame
Instance.new("UICorner", viBtn).CornerRadius = UDim.new(0, 6)

local enBtn = Instance.new("TextButton")
enBtn.Size = UDim2.new(0, 105, 0, 45)
enBtn.Position = UDim2.new(0, 140, 0, 75)
enBtn.Text = "English"
enBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
enBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
enBtn.TextSize = 14
enBtn.Font = Enum.Font.SourceSansBold
enBtn.Parent = langFrame
Instance.new("UICorner", enBtn).CornerRadius = UDim.new(0, 6)

local function startMainScript(selectedLang)
    langGui:Destroy()

    local AimEnabled = false
    local ESPEnabled = false
    local FOV = 300
    local WallCheck = true
    local AimSpeed = 1
    local LockQuickAim = false

    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 100
    FOVCircle.Radius = FOV
    FOVCircle.Filled = false
    FOVCircle.Color = Color3.fromRGB(255, 0, 0)

    local function updateESPForCharacter(character)
        if not character then return end
        local highlight = character:FindFirstChild("ESPHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "ESPHighlight"
            highlight.Adornee = character
            highlight.FillTransparency = 1
            highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineTransparency = 0
            highlight.Parent = character
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        highlight.Enabled = ESPEnabled and humanoid and humanoid.Health > 0
    end

    task.spawn(function()
        while true do
            if ESPEnabled then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        updateESPForCharacter(player.Character)
                    end
                end
            end
            task.wait(0.05)
        end
    end)

    RunService.RenderStepped:Connect(function()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = center
        FOVCircle.Radius = FOV
        FOVCircle.Visible = AimEnabled
        
        if AimEnabled then
            local closestTarget = nil
            local shortestDist = FOV

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    
                    if head and humanoid and humanoid.Health > 0 then
                        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude

                        if onScreen and dist < shortestDist then
                            if WallCheck then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, player.Character}
                                
                                local result = workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, rayParams)
                                if result then 
                                    continue 
                                end
                            end
                            
                            closestTarget = head
                            shortestDist = dist
                        end
                    end
                end
            end

            if closestTarget then
                local targetPos = closestTarget.Position
                local lookAt = CFrame.new(Camera.CFrame.Position, targetPos)
                if AimSpeed >= 1 then
                    Camera.CFrame = lookAt
                else
                    Camera.CFrame = Camera.CFrame:Lerp(lookAt, AimSpeed)
                end
            end
        end
    end)

    local oldGui = PlayerGui:FindFirstChild("CheatMenuGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CheatMenuGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 420)
    frame.Position = UDim2.new(0.5, -100, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Visible = true
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local draggingMain, dragStartMain, startPosMain
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = true
            dragStartMain = input.Position
            startPosMain = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartMain
            frame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = false
        end
    end)

    local toggleGuiBtn = Instance.new("TextButton")
    toggleGuiBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleGuiBtn.Position = UDim2.new(0, 10, 0, 10)
    toggleGuiBtn.Text = "MENU"
    toggleGuiBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleGuiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleGuiBtn.Parent = screenGui
    Instance.new("UICorner", toggleGuiBtn).CornerRadius = UDim.new(0, 8)

    local quickAimBtn = Instance.new("TextButton")
    quickAimBtn.Size = UDim2.new(0, 110, 0, 40)
    quickAimBtn.Position = UDim2.new(0, 70, 0, 10)
    if selectedLang == "English" then
        quickAimBtn.Text = "Quick Aim: OFF"
    else
        quickAimBtn.Text = "Ngắm Nhanh: TẮT"
    end
    quickAimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    quickAimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickAimBtn.Parent = screenGui
    Instance.new("UICorner", quickAimBtn).CornerRadius = UDim.new(0, 8)

    local draggingQuick, dragStartQuick, startPosQuick
    quickAimBtn.InputBegan:Connect(function(input)
        if not LockQuickAim and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            draggingQuick = true
            dragStartQuick = input.Position
            startPosQuick = quickAimBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not LockQuickAim and draggingQuick and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartQuick
            quickAimBtn.Position = UDim2.new(startPosQuick.X.Scale, startPosQuick.X.Offset + delta.X, startPosQuick.Y.Scale, startPosQuick.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingQuick = false
        end
    end)

    local aimBtn = Instance.new("TextButton", frame)
    aimBtn.Size = UDim2.new(0, 180, 0, 35)
    aimBtn.Position = UDim2.new(0, 10, 0, 10)
    if selectedLang == "English" then
        aimBtn.Text = "Aim Lock: OFF"
    else
        aimBtn.Text = "Khóa Tầm Nhìn: TẮT"
    end
    aimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(0, 6)

    local espBtn = Instance.new("TextButton", frame)
    espBtn.Size = UDim2.new(0, 180, 0, 35)
    espBtn.Position = UDim2.new(0, 10, 0, 55)
    if selectedLang == "English" then
        espBtn.Text = "ESP: OFF"
    else
        espBtn.Text = "ESP: TẮT"
    end
    espBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)

    local fovBox = Instance.new("TextBox", frame)
    fovBox.Size = UDim2.new(0, 180, 0, 35)
    fovBox.Position = UDim2.new(0, 10, 0, 100)
    fovBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    fovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    if selectedLang == "English" then
        fovBox.PlaceholderText = "Enter FOV size"
    else
        fovBox.PlaceholderText = "Nhập kích thước FOV"
    end
    fovBox.Text = tostring(FOV)
    fovBox.TextSize = 13
    fovBox.ClearTextOnFocus = false
    Instance.new("UICorner", fovBox).CornerRadius = UDim.new(0, 6)

    fovBox.FocusLost:Connect(function()
        local num = tonumber(fovBox.Text)
        if num then
            FOV = num
        else
            fovBox.Text = tostring(FOV)
        end
    end)

    local lockQuickAimBtn = Instance.new("TextButton", frame)
    lockQuickAimBtn.Size = UDim2.new(0, 180, 0, 35)
    lockQuickAimBtn.Position = UDim2.new(0, 10, 0, 145)
    if selectedLang == "English" then
        lockQuickAimBtn.Text = "Lock Quick Aim: OFF"
    else
        lockQuickAimBtn.Text = "Khóa Nút Ngắm: TẮT"
    end
    lockQuickAimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    lockQuickAimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", lockQuickAimBtn).CornerRadius = UDim.new(0, 6)

    lockQuickAimBtn.MouseButton1Click:Connect(function()
        LockQuickAim = not LockQuickAim
        if LockQuickAim then
            if selectedLang == "English" then
                lockQuickAimBtn.Text = "Lock Quick Aim: ON"
            else
                lockQuickAimBtn.Text = "Khóa Nút Ngắm: BẬT"
            end
            lockQuickAimBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            draggingQuick = false
        else
            if selectedLang == "English" then
                lockQuickAimBtn.Text = "Lock Quick Aim: OFF"
            else
                lockQuickAimBtn.Text = "Khóa Nút Ngắm: TẮT"
            end
            lockQuickAimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    end)

    local toggleBtn3 = Instance.new("TextButton", frame)
    toggleBtn3.Size = UDim2.new(0, 180, 0, 35)
    toggleBtn3.Position = UDim2.new(0, 10, 0, 190)
    if selectedLang == "English" then
        toggleBtn3.Text = "Toggle Quick Aim"
    else
        toggleBtn3.Text = "Ẩn/Hiện Nút Ngắm"
    end
    toggleBtn3.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    toggleBtn3.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", toggleBtn3).CornerRadius = UDim.new(0, 6)

    local langInfoLabel = Instance.new("TextLabel", frame)
    langInfoLabel.Size = UDim2.new(0, 180, 0, 35)
    langInfoLabel.Position = UDim2.new(0, 10, 0, 235)
    langInfoLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    langInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    langInfoLabel.TextSize = 13
    langInfoLabel.Font = Enum.Font.SourceSansBold
    langInfoLabel.Text = "Lang: " .. selectedLang
    Instance.new("UICorner", langInfoLabel).CornerRadius = UDim.new(0, 6)

    local versionLabel = Instance.new("TextLabel", frame)
    versionLabel.Size = UDim2.new(0, 180, 0, 30)
    versionLabel.Position = UDim2.new(0, 10, 0, 280)
    versionLabel.BackgroundTransparency = 1
    versionLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    versionLabel.TextSize = 13
    versionLabel.Font = Enum.Font.SourceSansBold
    versionLabel.Text = "version: BETA"

    local function updateAimState(state)
        AimEnabled = state
        if state then
            if selectedLang == "English" then
                aimBtn.Text = "Aim Lock: ON"
                quickAimBtn.Text = "Quick Aim: ON"
            else
                aimBtn.Text = "Khóa Tầm Nhìn: BẬT"
                quickAimBtn.Text = "Ngắm Nhanh: BẬT"
            end
            aimBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            quickAimBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        else
            if selectedLang == "English" then
                aimBtn.Text = "Aim Lock: OFF"
                quickAimBtn.Text = "Quick Aim: OFF"
            else
                aimBtn.Text = "Khóa Tầm Nhìn: TẮT"
                quickAimBtn.Text = "Ngắm Nhanh: TẮT"
            end
            aimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            quickAimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    end

    toggleGuiBtn.MouseButton1Click:Connect(function()
        frame.Visible = not frame.Visible
    end)
    aimBtn.MouseButton1Click:Connect(function()
        updateAimState(not AimEnabled)
    end)
    quickAimBtn.MouseButton1Click:Connect(function()
        updateAimState(not AimEnabled)
    end)

    espBtn.MouseButton1Click:Connect(function() 
        ESPEnabled = not ESPEnabled
        if ESPEnabled then
            if selectedLang == "English" then
                espBtn.Text = "ESP: ON"
            else
                espBtn.Text = "ESP: BẬT"
            end
            espBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        else
            if selectedLang == "English" then
                espBtn.Text = "ESP: OFF"
            else
                espBtn.Text = "ESP: TẮT"
            end
            espBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    end)

    toggleBtn3.MouseButton1Click:Connect(function()
        quickAimBtn.Visible = not quickAimBtn.Visible
    end)
end

viBtn.MouseButton1Click:Connect(function()
    startMainScript("Vietnamese")
end)

enBtn.MouseButton1Click:Connect(function()
    startMainScript("English")
end)
