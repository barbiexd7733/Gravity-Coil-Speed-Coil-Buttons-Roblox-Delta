-- Delta Compatible LocalScript - Both Coils with "Equip Alone" Auto-Equip Buttons
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Assets
local MESH_ID = "rbxassetid://16606212"
local GRAVITY_MESH_TEXTURE = "rbxassetid://16606141"
local GRAVITY_ICON = "rbxassetid://16619617"
local GRAVITY_SOUND = "rbxassetid://16619553"

local SPEED_MESH_TEXTURE = "rbxassetid://99170547"
local SPEED_ICON = "rbxassetid://99170415"
local SPEED_SOUND = "rbxassetid://99173388"
local SPEED_COIL_SPEED = 32

-- Clean up any existing GUI
if playerGui:FindFirstChild("CoilsGui") then
	playerGui.CoilsGui:Destroy()
end

-- ===================== GUI CONTAINER =====================

local gui = Instance.new("ScreenGui")
gui.Name = "CoilsGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Helper function to make buttons draggable
local function makeDraggable(btn)
	local dragging = false
	local dragStart, startPos

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = btn.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				local delta = input.Position - dragStart
				btn.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end)
end

-- Helper function to put away currently held tools so the new tool equips alone
local function unequipCurrentTool()
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")
	if character and backpack then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				item.Parent = backpack
			end
		end
	end
end

-- ===================== GC BUTTON (GRAVITY COIL) =====================

local gcButton = Instance.new("TextButton")
gcButton.Name = "GCButton"
gcButton.Size = UDim2.fromOffset(50, 50)
gcButton.Position = UDim2.new(0.85, 0, 0.5, 0) -- Middle-right
gcButton.BackgroundColor3 = Color3.fromRGB(135, 206, 235) -- Sky Blue
gcButton.BackgroundTransparency = 0.25 -- 75% Opacity
gcButton.BorderSizePixel = 0
gcButton.Text = "GC"
gcButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gcButton.TextSize = 18
gcButton.Font = Enum.Font.GothamBold
gcButton.Active = true
gcButton.Parent = gui

local gcCorner = Instance.new("UICorner")
gcCorner.CornerRadius = UDim.new(1, 0)
gcCorner.Parent = gcButton

local gcStroke = Instance.new("UIStroke")
gcStroke.Color = Color3.fromRGB(255, 255, 255)
gcStroke.Transparency = 0.5
gcStroke.Thickness = 1.5
gcStroke.Parent = gcButton

makeDraggable(gcButton)

-- ===================== SC BUTTON (SPEED COIL) =====================

local scButton = Instance.new("TextButton")
scButton.Name = "SCButton"
scButton.Size = UDim2.fromOffset(50, 50)
scButton.Position = UDim2.new(0.85, 0, 0.4, 0) -- Above GC button
scButton.BackgroundColor3 = Color3.fromRGB(255, 69, 58) -- Red
scButton.BackgroundTransparency = 0.25 -- 75% Opacity
scButton.BorderSizePixel = 0
scButton.Text = "SC"
scButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scButton.TextSize = 18
scButton.Font = Enum.Font.GothamBold
scButton.Active = true
scButton.Parent = gui

local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(1, 0)
scCorner.Parent = scButton

local scStroke = Instance.new("UIStroke")
scStroke.Color = Color3.fromRGB(255, 255, 255)
scStroke.Transparency = 0.5
scStroke.Thickness = 1.5
scStroke.Parent = scButton

makeDraggable(scButton)

-- ===================== GRAVITY COIL LOGIC =====================

local function getOrCreateGravityCoil()
	local character = player.Character or player.CharacterAdded:Wait()
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 2)
	if not character or not backpack then return end

	unequipCurrentTool()

	local existingTool = character:FindFirstChild("Gravity Coil") or backpack:FindFirstChild("Gravity Coil")
	if existingTool then
		existingTool.Parent = character
		return existingTool
	end

	local tool = Instance.new("Tool")
	tool.Name = "Gravity Coil"
	tool.ToolTip = "Jump higher!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.TextureId = GRAVITY_ICON

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1.2, 2)
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = MESH_ID
	mesh.TextureId = GRAVITY_MESH_TEXTURE
	mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
	mesh.Parent = handle

	local sound = Instance.new("Sound")
	sound.Name = "CoilSound"
	sound.SoundId = GRAVITY_SOUND
	sound.Volume = 1
	sound.Parent = handle

	local bodyForce = nil

	tool.Equipped:Connect(function()
		sound:Play()
		local char = player.Character
		if not char then return end

		local root = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = 90
		end

		if root and not root:FindFirstChild("GCoilForce") then
			bodyForce = Instance.new("BodyForce")
			bodyForce.Name = "GCoilForce"
			bodyForce.Force = Vector3.new(0, root.AssemblyMass * Workspace.Gravity * 0.5, 0)
			bodyForce.Parent = root
		end
	end)

	tool.Unequipped:Connect(function()
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")

			if humanoid then
				humanoid.JumpPower = 50
			end

			if root and root:FindFirstChild("GCoilForce") then
				root.GCoilForce:Destroy()
			end
		end
		if bodyForce then
			bodyForce:Destroy()
			bodyForce = nil
		end
	end)

	tool.Parent = character
	return tool
end

-- ===================== SPEED COIL LOGIC =====================

local function getOrCreateSpeedCoil()
	local character = player.Character or player.CharacterAdded:Wait()
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 2)
	if not character or not backpack then return end

	unequipCurrentTool()

	local existingTool = character:FindFirstChild("Speed Coil") or backpack:FindFirstChild("Speed Coil")
	if existingTool then
		existingTool.Parent = character
		return existingTool
	end

	local tool = Instance.new("Tool")
	tool.Name = "Speed Coil"
	tool.ToolTip = "Speed Up!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.TextureId = SPEED_ICON

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1.2, 2)
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = MESH_ID
	mesh.TextureId = SPEED_MESH_TEXTURE
	mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
	mesh.Parent = handle

	local sound = Instance.new("Sound")
	sound.Name = "CoilSound"
	sound.SoundId = SPEED_SOUND
	sound.Volume = 1
	sound.Parent = handle

	local speedConnection = nil

	tool.Equipped:Connect(function()
		sound:Play()
		local char = player.Character
		if not char then return end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = SPEED_COIL_SPEED
		end

		if speedConnection then speedConnection:Disconnect() end
		speedConnection = RunService.Heartbeat:Connect(function()
			if tool.Parent ~= char then
				if speedConnection then speedConnection:Disconnect() end
				return
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.WalkSpeed ~= SPEED_COIL_SPEED then
				hum.WalkSpeed = SPEED_COIL_SPEED
			end
		end)
	end)

	tool.Unequipped:Connect(function()
		if speedConnection then speedConnection:Disconnect() end
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
			end
		end
	end)

	tool.Parent = character
	return tool
end

-- ===================== BUTTON EVENTS =====================

gcButton.MouseButton1Click:Connect(function()
	getOrCreateGravityCoil()
end)

scButton.MouseButton1Click:Connect(function()
	getOrCreateSpeedCoil()
end)

print("Coil Buttons Loaded Successfully with Equip-Alone Logic!")
