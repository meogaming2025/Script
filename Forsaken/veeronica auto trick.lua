local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local device = "Mobile"

-- Biến quản lý trạng thái chung (Toàn cục)
local enabled = true
local activeMonitors = {}
local descendantAddedConn = nil
local behaviorFolder = nil

-- BIẾN LƯU VỊ TRÍ UI (Mặc định ban đầu nếu chưa kéo)
local lastUiPosition = UDim2.new(0, 30, 0, 120)

-- Khai báo trước các hàm logic để UI có thể gọi trực tiếp
local startManager, stopManager

-- ==========================================
-- HÀM TẠO GIAO DIỆN (MODERN TOGGLE UI)
-- ==========================================
local function createToggleGui()
    local pg = player:WaitForChild("PlayerGui", 15)
    if not pg then return end
    
    if pg:FindFirstChild("AutoSprintToggleGui") then 
        pg.AutoSprintToggleGui:Destroy() 
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoSprintToggleGui"
    screenGui.ResetOnSpawn = false -- Ngăn Roblox tự xóa UI khi chết
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = pg

    -- Khung chính (Main Frame)
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 180, 0, 45)
    frame.Position = lastUiPosition -- Sử dụng vị trí đã lưu giữ trước đó
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Thickness = 1.5
    frameStroke.Color = Color3.fromRGB(60, 60, 60)
    frameStroke.Parent = frame

    -- Chữ hiển thị
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 110, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Auto Trick"
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    -- Nền nút gạt (Toggle Switch Background)
    local toggleBg = Instance.new("TextButton")
    toggleBg.Name = "ToggleBg"
    toggleBg.Size = UDim2.new(0, 42, 0, 22)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBg.BackgroundColor3 = enabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(120, 120, 120)
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = toggleBg

    -- Nút tròn di chuyển bên trong
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    -- Xử lý sự kiện Click Bật / Tắt mượt mà bằng Tween
    toggleBg.MouseButton1Click:Connect(function()
        enabled = not enabled -- Đảo trạng thái biến gốc
        
        if enabled then
            if startManager then startManager() end
        else
            if stopManager then stopManager() end
        end
        
        -- Hiệu ứng trượt và đổi màu UI
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local targetColor = enabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(120, 120, 120)
        local targetPos = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        
        TweenService:Create(toggleBg, tweenInfo, {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(circle, tweenInfo, {Position = targetPos}):Play()
    end)

    -- Hệ thống Kéo thả mượt mà (Smooth Draggable) có chức năng ghi nhớ tọa độ
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- Ghi lại vị trí cuối cùng khi người chơi thả tay ra khỏi UI
                    lastUiPosition = frame.Position 
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local nextPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            
            TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = nextPosition
            }):Play()
        end
    end)

    return screenGui
end

-- Khởi chạy UI ngay lập tức
task.spawn(createToggleGui)


-- ==========================================
-- LOGIC XỬ LÝ CHỨC NĂNG GAME (BACKGROUND)
-- ==========================================
local function getSprintingButton()
    return player:WaitForChild("PlayerGui"):WaitForChild("MainUI"):WaitForChild("SprintingButton")
end

local function safeConnectPropertyChanged(instance, prop, fn)
    local ok, signal = pcall(function() return instance:GetPropertyChangedSignal(prop) end)
    if ok and signal then return signal:Connect(fn) end
    return nil
end

local function monitorHighlight(h)
    if not h or activeMonitors[h] then return end
    local connections = {}
    local prevState = false
    
    local function cleanup()
        for _, conn in ipairs(connections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        activeMonitors[h] = nil
    end
    
    local function adorneeIsPlayerCharacter(h)
        if not h then return false end
        local adornee = h.Adornee
        local char = player.Character
        if not adornee or not char then return false end
        if adornee == char or adornee:IsDescendantOf(char) then return true end
        return false
    end
    
    local function onChanged()
        if not enabled then return end
        if not h or not h.Parent then cleanup() return end
        
        local currState = adorneeIsPlayerCharacter(h)
        if prevState ~= currState then
            if currState and device == "Mobile" then
                local ok, btn = pcall(getSprintingButton)
                if ok and btn then
                    for _, v in pairs(getconnections(btn.MouseButton1Down)) do
                        pcall(function() v:Fire() end)
                        pcall(function() if v.Function then v:Function() end end)
                    end
                end
            end
        end
        prevState = currState
    end
    
    local c = safeConnectPropertyChanged(h, "Adornee", onChanged)
    if c then table.insert(connections, c) end
    table.insert(connections, h.AncestryChanged:Connect(function(_, p) if not p then cleanup() else onChanged() end end))
    table.insert(connections, player.CharacterAdded:Connect(onChanged))
    table.insert(connections, player.CharacterRemoving:Connect(onChanged))
    
    activeMonitors[h] = cleanup
    task.spawn(onChanged)
end

startManager = function()
    if descendantAddedConn or not behaviorFolder then return end
    for _, desc in ipairs(behaviorFolder:GetDescendants()) do
        if desc:IsA("Highlight") then monitorHighlight(desc) end
    end
    descendantAddedConn = behaviorFolder.DescendantAdded:Connect(function(child)
        if child:IsA("Highlight") then monitorHighlight(child) end
    end)
end

stopManager = function()
    if descendantAddedConn and descendantAddedConn.Connected then 
        descendantAddedConn:Disconnect() 
    end
    descendantAddedConn = nil
    
    local cleans = {}
    for h, cleanup in pairs(activeMonitors) do table.insert(cleans, cleanup) end
    for _, fn in ipairs(cleans) do pcall(fn) end
    activeMonitors = {}
end

-- Chạy quét folder bất đồng bộ
task.spawn(function()
    local assets = ReplicatedStorage:WaitForChild("Assets", 10)
    local survivors = assets and assets:WaitForChild("Survivors", 5)
    local veeronica = survivors and survivors:WaitForChild("Veeronica", 5)
    behaviorFolder = veeronica and veeronica:WaitForChild("Behavior", 5)
    
    if behaviorFolder and enabled then
        startManager()
    end
end)

-- Tạo lại UI khi hồi sinh nhưng truyền lại vị trí & trạng thái On/Off cũ
player.CharacterAdded:Connect(function()
    task.wait(0.5) -- Chờ Core UI ổn định
    createToggleGui()
    
    -- Nếu người chơi chết khi đang bật ON, tự động kích hoạt lại quét sau khi hồi sinh
    if enabled and behaviorFolder then
        stopManager()
        startManager()
    end
end)
