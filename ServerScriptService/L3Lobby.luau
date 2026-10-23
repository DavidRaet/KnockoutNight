local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Config = require(Storage.L3Config)
local Queue = require(script.Parent.L3Queue)
local Lobby = {}
local queue, records, connections = {}, {}, {}
local world, pad, snapshot, playRemote, createCharacter
local running = false

local function publish()
	local roster = {}
	for index, player in queue do
		roster[index] = { id = player.UserId, name = player.Name }
	end
	snapshot.Value = Http:JSONEncode(roster)
end

local function leave(player)
	if Queue.update(queue, player, false) then
		publish()
	end
end

local function clearCharacter(record)
	for _, connection in record.connections do
		connection:Disconnect()
	end
	table.clear(record.connections)
end

local function spawn(player, record)
	if not running or records[player] ~= record or player.Parent ~= Players then
		return
	end
	clearCharacter(record)
	local position = Config.Origin + Config.SpawnOffset
	local ok, character = pcall(createCharacter, player, CFrame.lookAt(position, position - Vector3.zAxis), true)
	if not ok or not character then
		record.spawning = false
		player:SetAttribute("L3State", "spawn-error")
		warn("L3 lobby character creation failed:", character)
		return
	end
	character:SetAttribute("F3Alive", false)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "L3 lobby spawn requires a Humanoid")
	record.character, record.spawning = character, false
	player:SetAttribute("F3Status", "lobby")
	player:SetAttribute("L3State", "lobby")
	local function lostCharacter()
		if not running or records[player] ~= record or record.spawning or record.character ~= character then
			return
		end
		record.spawning = true
		leave(player)
		player:SetAttribute("L3State", "respawning")
		clearCharacter(record)
		task.delay(1, spawn, player, record)
	end
	record.connections = {
		humanoid.Died:Connect(lostCharacter),
		player.CharacterRemoving:Connect(function(removed)
			if removed == character then
				lostCharacter()
			end
		end),
	}
end

local function add(player)
	if records[player] then
		return
	end
	records[player] = { connections = {}, spawning = false, character = nil, lastPlay = -math.huge }
	player:SetAttribute("L3State", "menu")
end

local function play(player)
	local record = records[player]
	if not running or not record or record.spawning or player.Parent ~= Players then
		return
	end
	local state = player:GetAttribute("L3State")
	if state ~= "menu" and state ~= "spawn-error" then
		return
	end
	local now = workspace:GetServerTimeNow()
	if now - record.lastPlay < 1 then
		return
	end
	record.lastPlay, record.spawning = now, true
	player:SetAttribute("L3State", "loading")
	spawn(player, record)
end

function Lobby.step()
	if not running then
		return
	end
	local changed = false
	for _, player in Players:GetPlayers() do
		local record = records[player]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local inside = false
		if
			record
			and not record.spawning
			and character == record.character
			and root
			and humanoid
			and humanoid.Health > 0
		then
			local point = pad.CFrame:PointToObjectSpace(root.Position)
			inside = Queue.contains(point.X, point.Y, point.Z, pad.Size.X / 2, pad.Size.Z / 2)
			if root.Position.Y < Config.Origin.Y - 12 then
				humanoid.Health = 0
				inside = false
			end
		end
		changed = Queue.update(queue, player, inside) or changed
	end
	if changed then
		publish()
	end
end

local function build()
	world = Instance.new("Model")
	world.Name = "L3Lobby"
	local function part(name, size, offset, color)
		local item = Instance.new("Part")
		item.Name, item.Size, item.Position = name, size, Config.Origin + offset
		item.Anchored, item.CanCollide, item.CanTouch = true, true, false
		item.Material, item.Color = Enum.Material.SmoothPlastic, color
		item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		item.Parent = world
		return item
	end
	local dark = Color3.fromRGB(35, 43, 57)
	part("Floor", Vector3.new(72, 2, 64), Vector3.zero, dark)
	part("BackWall", Vector3.new(72, 8, 2), Vector3.new(0, 5, -31), dark)
	part("FrontWall", Vector3.new(72, 8, 2), Vector3.new(0, 5, 31), dark)
	for _, sign in { -1, 1 } do
		part("SideWall" .. sign, Vector3.new(2, 8, 60), Vector3.new(sign * 35, 5, 0), dark)
	end
	pad = part("Queue1v1", Config.QueueSize, Config.QueueOffset, Color3.fromRGB(53, 168, 187))
	part("QueueBoard", Vector3.new(17, 13, 1), Vector3.new(0, 9, -24), dark)
	world.Parent = workspace
end

function Lobby.start(spawnCharacter)
	assert(not running, "L3 lobby must start only once")
	running, createCharacter = true, spawnCharacter
	build()
	snapshot = Instance.new("StringValue")
	snapshot.Name, snapshot.Value, snapshot.Parent = "L3QueueState", "[]", Storage
	playRemote = Instance.new("RemoteEvent")
	playRemote.Name = "L3Play"
	table.insert(connections, playRemote.OnServerEvent:Connect(play))
	table.insert(connections, Players.PlayerAdded:Connect(add))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			leave(player)
			local record = records[player]
			if record then
				clearCharacter(record)
				records[player] = nil
			end
		end)
	)
	for _, player in Players:GetPlayers() do
		add(player)
	end
	playRemote.Parent = Storage
	local elapsed = 0
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed >= 0.1 then
				elapsed = 0
				Lobby.step()
			end
		end)
	)
end

function Lobby.stop()
	if not running then
		return
	end
	running = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, record in records do
		clearCharacter(record)
	end
	table.clear(records)
	table.clear(queue)
	world:Destroy()
	snapshot:Destroy()
	playRemote:Destroy()
end

return Lobby
