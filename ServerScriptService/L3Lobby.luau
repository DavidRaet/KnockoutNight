local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Config = require(Storage.L3Config)
local Queue = require(script.Parent.L3Queue)
local Dispatch = require(script.Parent.L4Dispatch)
local Flow = require(script.Parent.L5Flow)
local Lobby = {}
local queue, records, connections = {}, {}, {}
local world, pad, snapshot, playRemote, createCharacter
local running = false
local dispatch = Dispatch.new()
local dispatchSnapshot, returnRemote
local finishSession
local loadArena, lives, match, requestRemote

local function privateState(player, session)
	local flow = session.flow
	if requestRemote and flow and player.Parent == Players then
		local choice = flow.choices[player]
		requestRemote:FireClient(player, {
			session = session.id,
			vote = flow.votes[player],
			weapon = choice.weapon,
			ability = choice.ability,
			ready = choice.ready,
			defaultWeapon = choice.defaultWeapon,
			defaultAbility = choice.defaultAbility,
			noticeUntil = if flow.lockedAt then flow.lockedAt + 3 else nil,
		})
	end
end

local function publish()
	local roster = {}
	for index, player in queue do
		roster[index] = { id = player.UserId, name = player.Name }
	end
	snapshot.Value = Http:JSONEncode(roster)
end

local function publishDispatch()
	local data = { session = dispatch.serial, deadline = dispatch.deadline, busy = dispatch.active ~= nil }
	if dispatch.active then
		local flow = dispatch.active.flow
		if flow then
			data.phase, data.phaseDeadline, data.map = flow.phase, flow.deadline, flow.map
			data.votes = Flow.counts(flow)
			data.ready = 0
			for _, choice in flow.choices do
				data.ready += if choice.ready then 1 else 0
			end
		end
		data.roster = {}
		for _, player in dispatch.active.roster do
			table.insert(data.roster, player.UserId)
		end
	end
	local payload = Http:JSONEncode(data)
	if dispatchSnapshot.Value ~= payload then
		dispatchSnapshot.Value = payload
	end
end

local function leave(player)
	if Queue.update(queue, player, false) then
		if dispatch.pair and table.find(dispatch.pair, player) then
			dispatch.pair, dispatch.deadline = nil, nil
		end
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
	if not running or records[player] ~= record or player.Parent ~= Players then
		if ok and character then
			character:Destroy()
		end
		return
	end
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
		if record.session then
			finishSession(record.session, "Match cancelled: a player reset or lost their character.")
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

finishSession = function(id, message)
	local session = dispatch.active
	if not session or session.id ~= id then
		return
	end
	-- Keep allocation occupied until every connected participant has returned.
	if lives then
		for _, player in session.roster do
			lives.remove(player)
		end
		match.clearLocal()
	end
	for _, player in session.roster do
		local record = records[player]
		if record and record.session then
			clearCharacter(record)
			record.session, record.spawning = nil, true
			player:SetAttribute("L4Message", message)
			player:SetAttribute("L3State", "respawning")
			player:SetAttribute("F2Weapon", nil)
			player:SetAttribute("F10Ability", nil)
		end
	end
	for _, player in session.roster do
		local record = records[player]
		if record and record.spawning and player.Parent == Players then
			spawn(player, record)
		end
	end
	Dispatch.release(dispatch, id)
	publishDispatch()
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
			and not record.session
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
	local session = Dispatch.step(dispatch, queue, workspace:GetServerTimeNow(), Config.DispatchCountdown)
	if session then
		if loadArena then
			session.flow = Flow.new(session.id, session.roster, workspace:GetServerTimeNow())
		end
		for index, player in session.roster do
			local record = records[player]
			record.session = session.id
			player:SetAttribute("L4Message", nil)
			player:SetAttribute("L3State", "intermission")
			local position = Config.IntermissionOrigin + Vector3.new((index * 2 - 3) * 6, 5, 0)
			record.character:PivotTo(CFrame.lookAt(position, position - Vector3.zAxis))
			local root = record.character:FindFirstChild("HumanoidRootPart")
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		end
		publish()
	end
	if dispatch.active then
		local active = dispatch.active
		local inMatch = active.flow and active.flow.phase == "match"
		for _, player in active.roster do
			local record = records[player]
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if
				(not inMatch or match.phase() == "countdown")
				and (
					player.Parent ~= Players
					or not record
					or (not inMatch and character ~= record.character)
					or not root
					or not humanoid
					or humanoid.Health <= 0
					or (not inMatch and active.flow == nil and root.Position.Y < Config.IntermissionOrigin.Y - 12)
					or (
						active.flow
						and active.flow.phase == "vote"
						and root
						and root.Position.Y < Config.IntermissionOrigin.Y - 12
					)
				)
			then
				finishSession(dispatch.active.id, "Match cancelled: a player left intermission.")
				break
			end
		end
		if dispatch.active == active and active.flow then
			local action = Flow.step(active.flow, workspace:GetServerTimeNow(), math.random)
			if action then
				local ok, failure = pcall(function()
					if action == "load" then
						active.frames = loadArena(active.flow.map)
						for index, player in active.roster do
							local character = player.Character
							character:PivotTo(active.frames[index])
							local root = character:FindFirstChild("HumanoidRootPart")
							root.Anchored = true
							root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
							player:SetAttribute("L3State", "selection")
						end
						Flow.select(active.flow, workspace:GetServerTimeNow())
					else
						for index, player in active.roster do
							clearCharacter(records[player])
							local choice = active.flow.choices[player]
							player:SetAttribute("F2Weapon", choice.weapon)
							player:SetAttribute("F10Ability", choice.ability)
							player:SetAttribute("L3State", "match")
							lives.add(
								player,
								active.frames[index],
								if active.flow.map ~= "ThePlatform" then index else nil
							)
						end
						assert(
							match.begin(active.roster),
							"L6 opening countdown requires exactly the assigned pair with valid waiting lives"
						)
					end
				end)
				if not ok then
					warn("L5/L6 session setup failed:", failure)
					finishSession(active.id, "Match cancelled: the arena could not start. Please queue again.")
				else
					for _, player in active.roster do
						privateState(player, active)
					end
				end
			end
			if dispatch.active == active and inMatch and match.phase() == "staging" then
				finishSession(active.id, "Match finished. Step onto the pad to play again.")
			end
		end
	end
	publishDispatch()
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
	local offset = Config.IntermissionOrigin - Config.Origin
	part("IntermissionFloor", Vector3.new(40, 2, 32), offset, dark)
	for _, sign in { -1, 1 } do
		part("IntermissionSide" .. sign, Vector3.new(2, 8, 32), offset + Vector3.new(sign * 20, 5, 0), dark)
		part("IntermissionEnd" .. sign, Vector3.new(40, 8, 2), offset + Vector3.new(0, 5, sign * 16), dark)
	end
	world.Parent = workspace
end

function Lobby.start(spawnCharacter, prepareArena)
	assert(not running, "L3 lobby must start only once")
	running, createCharacter = true, spawnCharacter
	loadArena = prepareArena
	if loadArena then
		lives, match = require(script.Parent.F3Lives), require(script.Parent.F4Match)
		match.bindOpeningLoss(function()
			if dispatch.active then
				finishSession(dispatch.active.id, "Match cancelled: a player left before GO.")
			end
		end)
		match.bindLocalReturn(function(player)
			local record = records[player]
			if record and record.session then
				lives.remove(player)
				clearCharacter(record)
				record.session, record.spawning = nil, true
				player:SetAttribute("F2Weapon", nil)
				player:SetAttribute("F10Ability", nil)
				spawn(player, record)
			end
		end)
	end
	build()
	snapshot = Instance.new("StringValue")
	snapshot.Name, snapshot.Value, snapshot.Parent = "L3QueueState", "[]", Storage
	dispatch = Dispatch.new()
	dispatchSnapshot = Instance.new("StringValue")
	dispatchSnapshot.Name, dispatchSnapshot.Parent = "L4State", Storage
	publishDispatch()
	if loadArena then
		requestRemote = Instance.new("RemoteEvent")
		requestRemote.Name, requestRemote.Parent = "L5Request", Storage
		table.insert(
			connections,
			requestRemote.OnServerEvent:Connect(function(player, id, command, value)
				local active = dispatch.active
				if
					active
					and active.flow
					and Flow.request(active.flow, player, id, command, value, workspace:GetServerTimeNow())
				then
					privateState(player, active)
					publishDispatch()
				end
			end)
		)
	end
	returnRemote = Instance.new("RemoteEvent")
	returnRemote.Name = "L4Return"
	table.insert(
		connections,
		returnRemote.OnServerEvent:Connect(function(player, id)
			local record = records[player]
			if
				record
				and record.session == id
				and type(id) == "number"
				and (not dispatch.active.flow or dispatch.active.flow.phase ~= "match")
			then
				finishSession(id, "Match cancelled: a player returned to the lobby.")
			end
		end)
	)
	returnRemote.Parent = Storage
	playRemote = Instance.new("RemoteEvent")
	playRemote.Name = "L3Play"
	table.insert(connections, playRemote.OnServerEvent:Connect(play))
	table.insert(connections, Players.PlayerAdded:Connect(add))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local session = records[player] and records[player].session
			leave(player)
			local record = records[player]
			if record then
				clearCharacter(record)
				records[player] = nil
			end
			if
				session
				and (not dispatch.active.flow or dispatch.active.flow.phase ~= "match" or match.phase() == "countdown")
			then
				finishSession(session, "Match cancelled: a player disconnected.")
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
	dispatchSnapshot:Destroy()
	returnRemote:Destroy()
	if requestRemote then
		requestRemote:Destroy()
		requestRemote = nil
	end
	if match then
		match.bindLocalReturn(nil)
		match.bindOpeningLoss(nil)
	end
end

return Lobby
