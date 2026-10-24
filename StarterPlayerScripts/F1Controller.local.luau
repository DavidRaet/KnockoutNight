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
local combatInstance = script.Parent:WaitForChild("F2Client", 10)
assert(combatInstance and combatInstance:IsA("ModuleScript"), "F2Client is missing from the Spring Fist prototype")
local Combat = require(combatInstance)
local livesInstance = script.Parent:WaitForChild("F3Client", 10)
assert(livesInstance and livesInstance:IsA("ModuleScript"), "F3Client is missing from the lives prototype")
local Lives = require(livesInstance)
local lobbyInstance = if not Config.DeveloperArenaMode then script.Parent:WaitForChild("L3Client", 10) else nil
assert(Config.DeveloperArenaMode or lobbyInstance, "L3 lobby requires its client presentation module")
local Lobby = if lobbyInstance then require(lobbyInstance) else nil
local studyInstance = if RunService:IsStudio() then ReplicatedStorage:WaitForChild("F2PhysicsStudy", 10) else nil
assert(
	not RunService:IsStudio() or (studyInstance and studyInstance:IsA("ModuleScript")),
	"F2PhysicsStudy module is missing from the Studio prototype"
)
local PhysicsStudy = if studyInstance then require(studyInstance) else nil
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
local shiftLocked = true
local controlsGui = Instance.new("ScreenGui")
controlsGui.Name, controlsGui.ResetOnSpawn = "F1Controls", false
controlsGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
controlsGui.Parent = player:WaitForChild("PlayerGui", 10)
local lockButton = Instance.new("TextButton")
lockButton.Name, lockButton.Size, lockButton.Position =
	"ShiftLock", UDim2.fromOffset(240, 42), UDim2.new(0, 16, 1, -130)
lockButton.BackgroundColor3, lockButton.TextColor3 = Color3.fromRGB(21, 25, 34), Color3.new(1, 1, 1)
lockButton.Font, lockButton.TextSize = Enum.Font.GothamMedium, 18
lockButton.Parent = controlsGui

local function connect(signal: RBXScriptSignal, callback)
	table.insert(connections, signal:Connect(callback))
end

local studyMotor: Humanoid? = nil
local studyMotorEnabled = true

local function restoreStudyMotor()
	if studyMotor then
		studyMotor.EvaluateStateMachine = studyMotorEnabled
		if studyMotorEnabled and studyMotor.Health > 0 then
			studyMotor:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		studyMotor = nil
	end
end

local function clearInput()
	table.clear(held)
	jumpHeld = false
	jumpRequested = false
end

local function controlsEnabled(): boolean
	return focused
		and not GuiService.MenuIsOpen
		and Input:GetFocusedTextBox() == nil
		and GuiService.SelectedObject == nil
		and not Lives.adminConsoleOpen()
		and player:GetAttribute("F1ControlsEnabled") ~= false
		and (player:GetAttribute("L3State") == "lobby" or player:GetAttribute("L3State") == "intermission" or ((not Lobby or player:GetAttribute(
			"L3State"
		) == "match") and player:GetAttribute("F3Status") == "alive" and Lives.matchActive()))
		and humanoid ~= nil
		and humanoid.Health > 0
end

local function toggleLock()
	shiftLocked = not shiftLocked
	clearInput()
	player:SetAttribute("F1ShiftLock", shiftLocked)
	lockButton.Text = "Shift lock: " .. (if shiftLocked then "ON" else "OFF") .. " (Shift)"
end
lockButton.Text = "Shift lock: ON (Shift)"
player:SetAttribute("F1ShiftLock", true)
connect(lockButton.Activated, toggleLock)
connect(Input.InputBegan, function(input, processed)
	if
		not processed
		and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift)
		and controlsEnabled()
	then
		toggleLock()
	end
end)

local function attachCharacter(model: Model)
	restoreStudyMotor()
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
		restoreStudyMotor()
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

Actions:BindActionAtPriority("F2Attack", function(_, state)
	if
		state == Enum.UserInputState.Begin
		and controlsEnabled()
		and Lives.matchActive()
		and player:GetAttribute("F3Status") == "alive"
		and character
		and root
	then
		local now = workspace:GetServerTimeNow()
		if
			(not root:GetAttribute("F2Displaced") or root:GetAttribute("F9Pulling"))
			and now >= (root:GetAttribute("F2ReactionUntil") or 0)
		then
			Combat.press(character, CFrame.Angles(0, yaw, 0).LookVector)
		end
	end
	return if controlsEnabled() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.UserInputType.MouseButton1)

Actions:BindActionAtPriority("F10Ability", function(_, state)
	if
		state == Enum.UserInputState.Begin
		and controlsEnabled()
		and Lives.matchActive()
		and player:GetAttribute("F3Status") == "alive"
		and character
	then
		local x = (if held[Enum.KeyCode.D] then 1 else 0) - (if held[Enum.KeyCode.A] then 1 else 0)
		local z = (if held[Enum.KeyCode.S] then 1 else 0) - (if held[Enum.KeyCode.W] then 1 else 0)
		Combat.ability(character, CFrame.Angles(0, yaw, 0).LookVector, Movement.direction(x, z, yaw))
	end
	return if controlsEnabled() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Q)

Actions:BindActionAtPriority(
	"F1Movement",
	function(_, state, input)
		if state == Enum.UserInputState.End then
			held[input.KeyCode] = nil
		elseif state == Enum.UserInputState.Cancel then
			clearInput()
		elseif state == Enum.UserInputState.Begin and controlsEnabled() then
			held[input.KeyCode] = true
		end
		return if controlsEnabled() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
	end,
	false,
	Enum.ContextActionPriority.High.Value,
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right
)

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
		distance = math.clamp(
			distance - input.Position.Z * Config.CameraZoomStep,
			Config.CameraMinDistance,
			Config.CameraMaxDistance
		)
	end
end)

connect(RunService.PreSimulation, function(dt)
	local currentHumanoid, currentRoot = humanoid, root
	if not currentHumanoid or not currentRoot then
		Combat.update(nil)
		return
	end
	local studyMode = if PhysicsStudy then currentRoot:GetAttribute("F2StudyMode") else nil
	local studyInput = if PhysicsStudy then currentRoot:GetAttribute("F2StudyInput") else nil
	if studyMode ~= "client" and studyMode ~= "server" then
		restoreStudyMotor()
	end
	if not controlsEnabled() and studyMode == nil and typeof(studyInput) ~= "Vector3" then
		Combat.update(character, CFrame.Angles(0, yaw, 0).LookVector, Vector3.zero, false)
		clearInput()
		currentHumanoid:Move(Vector3.zero, false)
		currentHumanoid.Jump = false
		return
	end
	local x = (if held[Enum.KeyCode.D] then 1 else 0) - (if held[Enum.KeyCode.A] then 1 else 0)
	local z = (if held[Enum.KeyCode.S] then 1 else 0) - (if held[Enum.KeyCode.W] then 1 else 0)
	local direction = Movement.direction(x, z, yaw)
	if typeof(studyInput) == "Vector3" then
		direction = studyInput
	elseif not controlsEnabled() then
		direction = Vector3.zero
	end
	local intendedAim = CFrame.Angles(0, yaw, 0).LookVector
	player:SetAttribute("F2IntendedAim", intendedAim)
	Combat.update(character, intendedAim, direction, controlsEnabled() and player:GetAttribute("F3Status") == "alive")
	local now = workspace:GetServerTimeNow()
	local displaced = currentRoot:GetAttribute("F2Displaced") ~= nil
	local reaction = now < (currentRoot:GetAttribute("F2ReactionUntil") or 0)
	if displaced or reaction then
		currentHumanoid:Move(Vector3.zero, false)
		currentHumanoid.Jump = false
		jumpRequested = false
		return
	end
	if PhysicsStudy and (studyMode == "client" or studyMode == "server") then
		if studyMotor ~= currentHumanoid then
			local motorEnabled = currentRoot:GetAttribute("F2StudyMotorEnabled")
			if typeof(motorEnabled) ~= "boolean" then
				return
			end
			restoreStudyMotor()
			studyMotorEnabled = motorEnabled
			studyMotor = currentHumanoid
		end
		currentHumanoid.EvaluateStateMachine = false
		currentHumanoid:Move(direction, false)
		currentHumanoid.Jump = false
		jumpRequested = false
		if studyMode == "client" then
			currentRoot.AssemblyLinearVelocity = PhysicsStudy.steer(currentRoot.AssemblyLinearVelocity, direction, dt)
		end
		return
	end
	local grounded = currentHumanoid.FloorMaterial ~= Enum.Material.Air
	local moveScale, canJump, committedAim = Combat.permissions(character)
	local serverAim = currentRoot:GetAttribute("F2ActionAim")
	if now < (currentRoot:GetAttribute("F2ActionUntil") or 0) and typeof(serverAim) == "Vector3" then
		moveScale, canJump = Combat.permissions(character)
		canJump = currentRoot:GetAttribute("F2ActionCanJump") == true
		committedAim = serverAim
	end
	currentHumanoid.WalkSpeed = Config.WalkSpeed * moveScale
	currentHumanoid.JumpHeight = if canJump then Config.JumpHeight else 0
	currentRoot.CFrame = if committedAim
		then CFrame.lookAt(currentRoot.Position, currentRoot.Position + committedAim)
		else CFrame.new(currentRoot.Position) * CFrame.Angles(0, yaw, 0)
	currentHumanoid:Move(direction * (if grounded then 1 else Config.AirControl), false)
	currentHumanoid.Jump = canJump
		and (jumpRequested or (PhysicsStudy ~= nil and currentRoot:GetAttribute("F2StudyJump") == true))
		and grounded
	jumpRequested = false
end)

local raycastParams = RaycastParams.new()
raycastParams.IgnoreWater = true
raycastParams.RespectCanCollide = true
RunService:BindToRenderStep("F1Camera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local enabled = controlsEnabled()
	local looking =
		Movement.captureMouse(enabled, shiftLocked, Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
	lockButton.Visible = enabled
	Input.MouseBehavior = if looking then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	Input.MouseIconEnabled = not looking
	if not enabled or not wasEnabled then
		clearInput()
	end
	wasEnabled = enabled
	local currentRoot = root
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local menuCamera = Lobby and Lobby.menuCamera()
	if menuCamera then
		camera.CameraType, camera.CFrame, camera.Focus = Enum.CameraType.Scriptable, menuCamera, menuCamera
		return
	end
	if looking then
		local delta = Input:GetMouseDelta()
		yaw = (yaw - delta.X * Config.CameraSensitivity) % (math.pi * 2)
		pitch = math.clamp(pitch - delta.Y * Config.CameraSensitivity, Config.CameraMinPitch, Config.CameraMaxPitch)
	end
	if enabled then
		yaw = Movement.turn(
			yaw,
			held[Enum.KeyCode.Left] == true,
			held[Enum.KeyCode.Right] == true,
			dt,
			Config.CameraKeyboardTurnSpeed
		)
	end
	local excluded: { Instance } = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(excluded, other.Character)
		end
	end
	raycastParams.FilterDescendantsInstances = excluded
	local focus = (
		if Lobby
				and currentRoot
				and player:GetAttribute("L3State") ~= "match"
			then currentRoot.Position
			else Lives.cameraPosition(currentRoot)
	) + Vector3.new(0, Config.CameraFocusHeight, 0)
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
	Combat.stop()
	Lives.stop()
	if Lobby then
		Lobby.stop()
	end
	restoreStudyMotor()
	for _, connection in connections do
		connection:Disconnect()
	end
	Actions:UnbindAction("F1Movement")
	Actions:UnbindAction("F1Jump")
	Actions:UnbindAction("F2Attack")
	Actions:UnbindAction("F10Ability")
	controlsGui:Destroy()
	player:SetAttribute("F1ShiftLock", nil)
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
