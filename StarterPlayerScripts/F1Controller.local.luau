--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Actions = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local configInstance = ReplicatedStorage:WaitForChild("F1Config", 10)
local movementInstance = ReplicatedStorage:WaitForChild("F1Movement", 10)
assert(configInstance and configInstance:IsA("ModuleScript"), "F1Config is missing")
assert(movementInstance and movementInstance:IsA("ModuleScript"), "F1Movement is missing")
local Config = require(configInstance)
local Movement = require(movementInstance)
local playerScripts = player:WaitForChild("PlayerScripts", 10)
assert(playerScripts, "PlayerScripts is missing")
local playerModule = playerScripts:WaitForChild("PlayerModule", 10)
assert(playerModule and playerModule:IsA("ModuleScript"), "Default PlayerModule is missing")
-- Scriptable movement alone does not stop every default jump controller.
local defaultControls = require(playerModule).controls
defaultControls:Disable()

local character: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local held: { [Enum.KeyCode]: boolean } = {}
local jumpHeld = false
local jumpRequested = false
local focused = true
local wasEnabled = false
local yaw = 0
local pitch = Config.CameraPitch
local distance = Config.CameraDistance
local connections: { RBXScriptConnection } = {}

local function connect(signal: RBXScriptSignal, callback)
	table.insert(connections, signal:Connect(callback))
end

local function clearInput()
	table.clear(held)
	jumpHeld = false
	jumpRequested = false
end

local function controlsEnabled(): boolean
	return focused and not GuiService.MenuIsOpen and Input:GetFocusedTextBox() == nil
		and player:GetAttribute("F1ControlsEnabled") ~= false
		and humanoid ~= nil and humanoid.Health > 0
end

local function attachCharacter(model: Model)
	character = model
	humanoid = nil
	root = nil
	clearInput()
	local nextHumanoid = model:WaitForChild("Humanoid", 10)
	local nextRoot = model:WaitForChild("HumanoidRootPart", 10)
	if character ~= model or not nextHumanoid or not nextRoot then
		return
	end
	assert(nextHumanoid:IsA("Humanoid") and nextRoot:IsA("BasePart"), "Character parts have unexpected types")
	humanoid = nextHumanoid
	root = nextRoot
	nextHumanoid.AutoRotate = false
	nextHumanoid.AutoJumpEnabled = false
	nextHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	nextHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	local _, initialYaw = nextRoot.CFrame:ToOrientation()
	yaw = initialYaw
	pitch = Config.CameraPitch
end

connect(player.CharacterAdded, attachCharacter)
connect(player.CharacterRemoving, function(model: Model)
	if character == model then
		character = nil
		humanoid = nil
		root = nil
		clearInput()
	end
end)
if player.Character then
	task.spawn(attachCharacter, player.Character)
end

connect(Input.WindowFocusReleased, function()
	focused = false
	clearInput()
end)
connect(Input.WindowFocused, function()
	focused = true
end)
connect(GuiService.MenuOpened, clearInput)
connect(Input.TextBoxFocused, clearInput)
connect(player:GetAttributeChangedSignal("F1ControlsEnabled"), clearInput)

Actions:BindActionAtPriority("F1Movement", function(_, state, input)
	if state == Enum.UserInputState.End then
		held[input.KeyCode] = nil
	elseif state == Enum.UserInputState.Cancel then
		clearInput()
	elseif state == Enum.UserInputState.Begin and controlsEnabled() then
		held[input.KeyCode] = true
	end
	return if controlsEnabled() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)

Actions:BindActionAtPriority("F1Jump", function(_, state)
	if state == Enum.UserInputState.Cancel or state == Enum.UserInputState.End then
		jumpHeld = false
	elseif state == Enum.UserInputState.Begin and controlsEnabled() then
		local current = humanoid
		local grounded = current ~= nil and current.FloorMaterial ~= Enum.Material.Air
		jumpRequested = Movement.pressJump(jumpHeld, true, grounded)
		jumpHeld = true
	end
	return if controlsEnabled() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)

connect(Input.InputChanged, function(input, processed)
	if not processed and controlsEnabled() and input.UserInputType == Enum.UserInputType.MouseWheel then
		distance = math.clamp(distance - input.Position.Z * Config.CameraZoomStep, Config.CameraMinDistance, Config.CameraMaxDistance)
	end
end)

connect(RunService.PreSimulation, function()
	local currentHumanoid, currentRoot = humanoid, root
	if not currentHumanoid or not currentRoot then
		return
	end
	if not controlsEnabled() then
		clearInput()
		currentHumanoid:Move(Vector3.zero, false)
		currentHumanoid.Jump = false
		return
	end
	local x = (if held[Enum.KeyCode.D] then 1 else 0) - (if held[Enum.KeyCode.A] then 1 else 0)
	local z = (if held[Enum.KeyCode.S] then 1 else 0) - (if held[Enum.KeyCode.W] then 1 else 0)
	local direction = Movement.direction(x, z, yaw)
	local grounded = currentHumanoid.FloorMaterial ~= Enum.Material.Air
	currentRoot.CFrame = CFrame.new(currentRoot.Position) * CFrame.Angles(0, yaw, 0)
	-- shortcut: ordinary Humanoid air control only; add knockback ownership in F2.
	currentHumanoid:Move(direction * (if grounded then 1 else Config.AirControl), false)
	currentHumanoid.Jump = jumpRequested and grounded
	jumpRequested = false
end)

local raycastParams = RaycastParams.new()
raycastParams.IgnoreWater = true
raycastParams.RespectCanCollide = true
RunService:BindToRenderStep("F1Camera", Enum.RenderPriority.Camera.Value + 1, function()
	local enabled = controlsEnabled()
	Input.MouseBehavior = if enabled then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	Input.MouseIconEnabled = not enabled
	if not enabled or not wasEnabled then
		clearInput()
	end
	wasEnabled = enabled
	local currentRoot = root
	local camera = workspace.CurrentCamera
	if not camera or not currentRoot then
		return
	end
	if enabled then
		local delta = Input:GetMouseDelta()
		yaw = (yaw - delta.X * Config.CameraSensitivity) % (math.pi * 2)
		pitch = math.clamp(pitch - delta.Y * Config.CameraSensitivity, Config.CameraMinPitch, Config.CameraMaxPitch)
	end
	local excluded: { Instance } = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(excluded, other.Character)
		end
	end
	raycastParams.FilterDescendantsInstances = excluded
	local focus = currentRoot.Position + Vector3.new(0, Config.CameraFocusHeight, 0)
	local rotation = CFrame.fromOrientation(pitch, yaw, 0)
	local offset = -rotation.LookVector * distance
	local hit = workspace:Spherecast(focus, Config.CameraRadius, offset, raycastParams)
	if hit then
		offset = offset.Unit * math.max(0.05, hit.Distance - Config.CameraWallPadding)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(focus + offset, focus)
	camera.Focus = CFrame.new(focus)
end)

script.Destroying:Connect(function()
	for _, connection in connections do
		connection:Disconnect()
	end
	Actions:UnbindAction("F1Movement")
	Actions:UnbindAction("F1Jump")
	RunService:UnbindFromRenderStep("F1Camera")
	defaultControls:Enable()
	Input.MouseBehavior = Enum.MouseBehavior.Default
	Input.MouseIconEnabled = true
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end)
