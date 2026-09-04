local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = lp.Character or lp.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")

local TARGET_ANIMATION_ID_1 = "106527725058030"
local TARGET_ANIMATION_ID_2 = "111918351126361"

local crystalPitchAimEnabled = false
local hatchetAimEnabled = false
local aimDuration = 1

local aimConnection = nil
local activeTrack = nil
local stopHatchetTimer = nil

local function getClosestKiller()
	if not killersFolder then
		killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
	end
	if not killersFolder then return nil end

	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local closestKiller = nil
	local shortestDistance = math.huge

	for _, obj in ipairs(killersFolder:GetChildren()) do
		local targetPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or (obj:IsA("BasePart") and obj)
		if targetPart then
			local distance = (myRoot.Position - targetPart.Position).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				closestKiller = targetPart
			end
		end
	end

	return closestKiller
end

local function stopAiming()
	if aimConnection then
		aimConnection:Disconnect()
		aimConnection = nil
	end
	if stopHatchetTimer then
		task.cancel(stopHatchetTimer)
		stopHatchetTimer = nil
	end
	activeTrack = nil
end

local function startCameraAiming(track)
	stopAiming()
	activeTrack = track

	aimConnection = RunService.RenderStepped:Connect(function()
		if not crystalPitchAimEnabled or not activeTrack or not activeTrack.IsPlaying then
			stopAiming()
			return
		end

		local targetPart = getClosestKiller()
		if targetPart then
			camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
		end
	end)
end

local function startCharacterAiming(track)
	stopAiming()
	activeTrack = track

	aimConnection = RunService.RenderStepped:Connect(function()
		if not hatchetAimEnabled then
			stopAiming()
			return
		end

		local myRoot = character:FindFirstChild("HumanoidRootPart")
		local targetPart = getClosestKiller()

		if myRoot and targetPart then
			local targetPos = Vector3.new(targetPart.Position.X, myRoot.Position.Y, targetPart.Position.Z)
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, targetPos)
		end
	end)

	stopHatchetTimer = task.delay(aimDuration, function()
		stopAiming()
	end)
end

local function setupAnimationListener(targetAnimator)
	targetAnimator.AnimationPlayed:Connect(function(animationTrack)
		local animId = animationTrack.Animation and animationTrack.Animation.AnimationId
		if animId then
			local idOnly = string.match(animId, "%d+")
			
			if idOnly == TARGET_ANIMATION_ID_1 and crystalPitchAimEnabled then
				startCameraAiming(animationTrack)
			elseif idOnly == TARGET_ANIMATION_ID_2 and hatchetAimEnabled then
				startCharacterAiming(animationTrack)
			else
				stopAiming()
			end
		end
	end)
end

setupAnimationListener(animator)

lp.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	stopAiming()
	setupAnimationListener(animator)
end)

local function makeDraggable(guiObject)
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local playerGui = lp:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 360)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -20, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MENU"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = contentFrame

local hideButton = Instance.new("TextButton")
hideButton.Name = "HideButton"
hideButton.Size = UDim2.new(0, 80, 0, 35)
hideButton.Position = UDim2.new(0, 20, 0, 20)
hideButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hideButton.Text = "ON"
hideButton.Font = Enum.Font.SourceSansBold
hideButton.TextSize = 16
hideButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = hideButton

local crystalPitchAimToggle = Instance.new("TextButton")
crystalPitchAimToggle.Name = "CrystalPitchAimToggle"
crystalPitchAimToggle.Size = UDim2.new(1, 0, 0, 40)
crystalPitchAimToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
crystalPitchAimToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
crystalPitchAimToggle.Text = "Crystal Pitch Aim: OFF"
crystalPitchAimToggle.Font = Enum.Font.SourceSansBold
crystalPitchAimToggle.TextSize = 16
crystalPitchAimToggle.Parent = contentFrame

local crystalCorner = Instance.new("UICorner")
crystalCorner.CornerRadius = UDim.new(0, 6)
crystalCorner.Parent = crystalPitchAimToggle

crystalPitchAimToggle.MouseButton1Click:Connect(function()
	crystalPitchAimEnabled = not crystalPitchAimEnabled
	if crystalPitchAimEnabled then
		crystalPitchAimToggle.Text = "Crystal Pitch Aim: ON"
		crystalPitchAimToggle.BackgroundColor3 = Color3.fromRGB(40, 130, 60)
	else
		crystalPitchAimToggle.Text = "Crystal Pitch Aim: OFF"
		crystalPitchAimToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		stopAiming()
	end
end)

local hatchetAimToggle = Instance.new("TextButton")
hatchetAimToggle.Name = "HatchetAimToggle"
hatchetAimToggle.Size = UDim2.new(1, 0, 0, 40)
hatchetAimToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
hatchetAimToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
hatchetAimToggle.Text = "Hatchet Aim: OFF"
hatchetAimToggle.Font = Enum.Font.SourceSansBold
hatchetAimToggle.TextSize = 16
hatchetAimToggle.Parent = contentFrame

local hatchetCorner = Instance.new("UICorner")
hatchetCorner.CornerRadius = UDim.new(0, 6)
hatchetCorner.Parent = hatchetAimToggle

hatchetAimToggle.MouseButton1Click:Connect(function()
	hatchetAimEnabled = not hatchetAimEnabled
	if hatchetAimEnabled then
		hatchetAimToggle.Text = "Hatchet Aim: ON"
		hatchetAimToggle.BackgroundColor3 = Color3.fromRGB(40, 130, 60)
	else
		hatchetAimToggle.Text = "Hatchet Aim: OFF"
		hatchetAimToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		stopAiming()
	end
end)

local durationLabel = Instance.new("TextLabel")
durationLabel.Name = "DurationLabel"
durationLabel.Size = UDim2.new(1, 0, 0, 20)
durationLabel.BackgroundTransparency = 1
durationLabel.Text = "Hatchet Aim Duration (seconds):"
durationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
durationLabel.Font = Enum.Font.SourceSans
durationLabel.TextSize = 14
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = contentFrame

local durationBox = Instance.new("TextBox")
durationBox.Name = "AimDurationBox"
durationBox.Size = UDim2.new(1, 0, 0, 35)
durationBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
durationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
durationBox.Text = "1"
durationBox.PlaceholderText = "Enter seconds..."
durationBox.Font = Enum.Font.SourceSansBold
durationBox.TextSize = 16
durationBox.Parent = contentFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = durationBox

durationBox.FocusLost:Connect(function()
	local newVal = tonumber(durationBox.Text)
	if newVal and newVal > 0 then
		aimDuration = newVal
	else
		durationBox.Text = tostring(aimDuration)
	end
end)

makeDraggable(mainFrame)
makeDraggable(hideButton)

hideButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	hideButton.Text = mainFrame.Visible and "ON" or "OFF"
end)
