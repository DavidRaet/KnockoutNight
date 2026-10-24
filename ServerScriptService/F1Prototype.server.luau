--!strict

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local configInstance = ReplicatedStorage:WaitForChild("F1Config", 10)
assert(configInstance and configInstance:IsA("ModuleScript"), "F1Config is missing")
local Config = require(configInstance)
local Lives = require(script.Parent.F3Lives)
local Match = require(script.Parent.F4Match)

Players.CharacterAutoLoads = false
StarterPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable
StarterPlayer.EnableMouseLockOption = false

if not PhysicsService:IsCollisionGroupRegistered("F1Characters") then
	PhysicsService:RegisterCollisionGroup("F1Characters")
end
PhysicsService:CollisionGroupSetCollidable("F1Characters", "F1Characters", false)

local Arenas = require(script.Parent.L5Arenas)
local arena, spawnFrames, spawnPoints, fallback = Arenas.build(Config.Arena)
arena.Parent = workspace

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.CanCollide = false
	baseplate.CanQuery = false
	baseplate.Transparency = 1
end

local templateDescription = Instance.new("HumanoidDescription")
templateDescription.BodyTypeScale = 0
templateDescription.ProportionScale = 0
local template = Players:CreateHumanoidModelFromDescriptionAsync(templateDescription, Enum.HumanoidRigType.R15)
templateDescription:Destroy()
local slots: { [Player]: number } = {}
local templates: { [Player]: Model } = {}

local function appearance(player: Player): Model?
	if player.Parent ~= Players then
		return nil
	end
	if templates[player] then
		return templates[player]
	end
	if player.UserId > 0 then
		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		end)
		if player.Parent ~= Players then
			if ok then
				description:Destroy()
			end
			return
		end
		if ok then
			-- Body packages/scales and custom animations must not change the combat rig.
			description.Head = 0
			description.Torso = 0
			description.LeftArm = 0
			description.RightArm = 0
			description.LeftLeg = 0
			description.RightLeg = 0
			description.IdleAnimation = 0
			description.WalkAnimation = 0
			description.RunAnimation = 0
			description.JumpAnimation = 0
			description.FallAnimation = 0
			description.ClimbAnimation = 0
			description.SwimAnimation = 0
			description.HeightScale = 1
			description.WidthScale = 1
			description.DepthScale = 1
			description.HeadScale = 1
			description.BodyTypeScale = 0
			description.ProportionScale = 0
			local created, model = pcall(function()
				return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
			end)
			description:Destroy()
			if created then
				if player.Parent ~= Players then
					model:Destroy()
					return
				end
				templates[player] = model
			else
				warn("F1 appearance unavailable; using standard R15:", model)
			end
		else
			warn("F1 avatar lookup failed; using standard R15:", description)
		end
	end
	if player.Parent ~= Players then
		return nil
	end
	templates[player] = templates[player] or template:Clone()
	return templates[player]
end

local function spawnCharacter(player: Player, frame: CFrame, lobbyCharacter: boolean?)
	if player.Parent ~= Players then
		return
	end
	local source = appearance(player)
	if not source then
		return nil
	end
	local character = source:Clone()
	character:SetAttribute("L3LobbyCharacter", lobbyCharacter == true)
	character.Name = player.Name
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid and humanoid.RigType == Enum.HumanoidRigType.R15, "F1 requires R15")
	humanoid.WalkSpeed = Config.WalkSpeed
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = Config.JumpHeight
	humanoid.AutoRotate = false
	humanoid.AutoJumpEnabled = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	local function configurePart(instance: Instance)
		if instance:IsA("BasePart") then
			instance.CollisionGroup = "F1Characters"
			if instance:FindFirstAncestorOfClass("Accessory") then
				instance.CanCollide = false
				instance.Massless = true
			end
		end
	end
	for _, instance in character:GetDescendants() do
		configurePart(instance)
	end
	character.DescendantAdded:Connect(configurePart)
	character:PivotTo(frame)
	local previous = player.Character
	player.Character = character
	character.Parent = workspace
	if previous then
		previous:Destroy()
	end
	return character
end

local function addPlayer(player: Player)
	if not Config.DeveloperArenaMode then
		return
	end
	if slots[player] then
		return
	end
	player.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable
	local firstOccupied = false
	local occupied = 0
	for _, slot in slots do
		firstOccupied = firstOccupied or slot == 1
		occupied += 1
	end
	if occupied >= 2 or not Match.canJoin() then
		player:SetAttribute("F3Status", "waiting")
		return
	end
	-- Developer arena staging deliberately bypasses the player-facing lobby and queue.
	slots[player] = if firstOccupied then 2 else 1
	appearance(player)
	local slot = slots[player]
	if slot and player.Parent == Players then
		Lives.add(player, spawnFrames[slot], if Config.Arena ~= "ThePlatform" then slot else nil)
	end
end

Lives.start(spawnCharacter, arena, spawnPoints, fallback)
local lobby = if not Config.DeveloperArenaMode then require(script.Parent.L3Lobby) else nil
if lobby then
	lobby.start(spawnCharacter, function(name)
		local nextArena, frames, points, emergency = Arenas.build(name)
		nextArena.Parent = workspace
		Lives.setArena(nextArena, points, emergency)
		arena:Destroy()
		arena = nextArena
		return frames
	end)
	script.Destroying:Connect(lobby.stop)
	game:BindToClose(lobby.stop)
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	slots[player] = nil
	local cached = templates[player]
	if cached then
		cached:Destroy()
		templates[player] = nil
	end
end)
for _, player in Players:GetPlayers() do
	task.spawn(addPlayer, player)
end
