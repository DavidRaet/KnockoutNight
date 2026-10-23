local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Config = require(Storage.F2Config)
local Weapons = require(Storage.F2Weapons)
local F1 = require(Storage.F1Config)
local Fist = require(Storage.F2SpringFist)
local Physics = require(Storage.F2PhysicsStudy)
local Contact = require(script.Parent.F2Contact)
local Combat = {}
local states, connections, playerConnections = {}, {}, {}
local remote, probe
local lifeOwner
local matchOwner
local generation, actionId = 0, 0

local function emit(kind, state, data)
	data = data or {}
	data.character, data.generation = state.character, state.generation
	remote:FireAllClients(kind, data)
end

local function valid(state)
	return state
		and state.player.Character == state.character
		and state.character.Parent
		and state.humanoid.Health > 0
		and state.root.Parent
		and state.character:GetAttribute("F3Alive") ~= false
end

local function equipped(state)
	return valid(state) and state.character:GetAttribute("F2Equipped") == true
end

local function own(state, owner)
	if state.root.Parent and state.root:CanSetNetworkOwnership() then
		state.root:SetNetworkOwner(owner)
		return true
	end
	return false
end

local function release(state, reason)
	local displacement = state.displacement
	if not displacement then
		return
	end
	state.displacement = nil
	state.humanoid.EvaluateStateMachine = displacement.motor
	if displacement.motor and state.humanoid.Health > 0 then
		state.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	state.root:SetAttribute("F2Displaced", nil)
	state.root:SetAttribute("F2MotorEnabled", nil)
	state.root:SetAttribute("F2Restart", displacement.id)
	if valid(state) and not state.correctionUntil then
		own(state, state.player)
	end
	if reason == "failsafe" then
		warn("F2 displacement failsafe cleanup", state.player.Name, displacement.id)
	end
	emit("release", state, {
		displacement = displacement.id,
		reason = reason,
		frame = state.root.CFrame,
		velocity = state.root.AssemblyLinearVelocity,
	})
end

local function permissions(state, now)
	local restricted = state.displacement ~= nil or now < state.reactionUntil
	local action = state.action
	state.humanoid.WalkSpeed = if restricted then 0 else F1.WalkSpeed * (if action then action.config.MoveScale else 1)
	state.humanoid.JumpHeight = if restricted or action then 0 else F1.JumpHeight
	state.root:SetAttribute("F2ReactionUntil", state.reactionUntil)
	state.root:SetAttribute("F2ProtectionUntil", state.protectionUntil)
	state.root:SetAttribute("F2ActionUntil", if action then action.started + action.config.Duration else nil)
	state.root:SetAttribute("F2ActionAim", if action then action.aim else nil)
	if restricted or action then
		state.humanoid.Jump = false
	end
end

local function clearAction(state, reason)
	if state.action then
		emit("cancel", state, { id = state.action.id, reason = reason })
	end
	state.action, state.buffer = nil, nil
end

local function remove(player, reason)
	local state = states[player]
	if not state then
		return
	end
	clearAction(state, reason)
	release(state, reason)
	emit("clear", state, { reason = reason })
	states[player] = nil
	for _, connection in state.connections do
		connection:Disconnect()
	end
	state.humanoid.WalkSpeed, state.humanoid.JumpHeight = state.walkSpeed, state.jumpHeight
	for _, name in
		{ "F2Generation", "F2ActionUntil", "F2ActionAim", "F2ReactionUntil", "F2ProtectionUntil", "F2Restart" }
	do
		state.root:SetAttribute(name, nil)
	end
	state.character:SetAttribute("F2Generation", nil)
	state.character:SetAttribute("F2Equipped", nil)
	state.character:SetAttribute("F2Weapon", nil)
	state.character:SetAttribute("F7NextHand", nil)
end

function Combat.retire(player, reason)
	remove(player, reason)
end

local function startAction(state, sequence, now)
	if lifeOwner then
		lifeOwner.endProtection(state.player)
		state.spawnProtectionUntil = 0
	end
	actionId += 1
	local config = Weapons[state.weapon]
	state.action =
		{ id = actionId, sequence = sequence, started = now, aim = state.aim, encountered = {}, config = config }
	if config == Weapons.PaddlePops then
		state.action.hand = state.nextHand
		state.nextHand = Weapons.PaddlePops.other(state.nextHand)
		state.character:SetAttribute("F7NextHand", state.nextHand)
	end
	state.buffer = nil
	emit("accepted", state, {
		id = actionId,
		sequence = sequence,
		started = now,
		aim = state.aim,
		weapon = state.weapon,
		hand = state.action.hand,
		activeAt = now + config.Startup,
		recoveryAt = now + config.Startup + config.Active,
		endsAt = now + config.Duration,
	})
	permissions(state, now)
end

function Combat.request(player, kind, gen, sequence, intendedAim)
	local state = states[player]
	local now = workspace:GetServerTimeNow()
	if matchOwner and not matchOwner.allowed(now) then
		return false
	end
	if not equipped(state) or gen ~= state.generation or (lifeOwner and not lifeOwner.alive(player)) then
		return false
	end
	-- Bound all traffic before expensive work or replies; invalid traffic cannot create deferred actions.
	state.tokens = math.min(12, state.tokens + (now - state.tokenAt) * 30)
	state.tokenAt = now
	if state.tokens < 1 then
		return false
	end
	state.tokens -= 1
	if kind == "steer" then
		if
			now - state.lastSteer < Config.InputInterval
			or not Physics.vector(intendedAim)
			or intendedAim.Y ~= 0
			or intendedAim.Magnitude > 1.001
		then
			return false
		end
		state.steer, state.lastSteer = intendedAim, now
		return true
	end
	local aim = Fist.aim(intendedAim)
	if not aim then
		return false
	end
	if kind == "aim" then
		if now - state.lastAim < Config.InputInterval then
			return false
		end
		state.aim, state.lastAim = aim, now
		return true
	end
	if
		kind ~= "press"
		or type(sequence) ~= "number"
		or not Physics.finite(sequence)
		or sequence % 1 ~= 0
		or sequence <= state.sequence
		or sequence > 2 ^ 53
	then
		return false
	end
	state.sequence = sequence
	local function reject(reason)
		remote:FireClient(
			player,
			"rejected",
			{ character = state.character, generation = gen, sequence = sequence, reason = reason }
		)
		return false
	end
	if now - state.lastPress < Config.InputInterval then
		return reject("rate")
	end
	state.lastPress = now
	state.aim = aim
	local restricted = state.displacement ~= nil or now < state.reactionUntil
	if restricted then
		return reject("hit-recovery")
	end
	if state.action then
		if Fist.canBuffer(now - state.action.started, state.buffer ~= nil, restricted, state.action.config) then
			state.buffer = sequence
			remote:FireClient(player, "buffered", {
				character = state.character,
				generation = gen,
				sequence = sequence,
				startsAt = state.action.started + state.action.config.Duration,
			})
			return true
		end
		return reject("busy")
	end
	startAction(state, sequence, now)
	return true
end

local function ground(state, excluded)
	local ray = RaycastParams.new()
	ray.FilterDescendantsInstances = excluded
	ray.RespectCanCollide = true
	local hit = workspace:Raycast(
		state.root.Position,
		-Vector3.yAxis * (state.humanoid.HipHeight + state.root.Size.Y / 2 + 0.3),
		ray
	)
	return hit ~= nil and hit.Normal.Y >= math.cos(math.rad(state.humanoid.MaxSlopeAngle))
end

local function launch(contact, now, excluded)
	local state, action = contact.victim, contact.action
	local config = action.config
	if not valid(contact.attacker) or not valid(state) or not own(state, nil) then
		return
	end
	local previous = state.displacement
	state.displacementId += 1
	state.displacement = {
		id = state.displacementId,
		motor = if previous then previous.motor else state.humanoid.EvaluateStateMachine,
		started = now,
		origin = state.root.Position,
		leftGround = not ground(state, excluded),
		observed = false,
	}
	state.credit = config.LaunchSpeed * Physics.BurstSeconds + Physics.PositionSlack
	state.residualSpeed = config.LaunchSpeed
	state.root:SetAttribute("F2MotorEnabled", state.displacement.motor)
	state.root:SetAttribute("F2Displaced", state.displacementId)
	state.humanoid.EvaluateStateMachine = false
	state.root.AssemblyLinearVelocity = action.aim * config.LaunchSpeed + Vector3.yAxis * config.LaunchUp
	state.reactionUntil, state.protectionUntil = contact.time + Config.Reaction, contact.time + Config.Protection
	state.buffer = nil
	if lifeOwner then
		lifeOwner.hit(state.player, contact.attacker.player, contact.time, contact.attacker.weapon)
	end
	emit("hit", state, {
		attacker = contact.attacker.character,
		actionId = action.id,
		at = contact.time,
		point = contact.point,
		reactionUntil = state.reactionUntil,
		protectionUntil = state.protectionUntil,
		displacement = state.displacementId,
	})
end

local function addCharacter(player, character)
	if player.Character ~= character then
		return
	end
	remove(player, "character-replaced")
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if
		player.Character ~= character
		or not humanoid
		or not root
		or not humanoid:IsA("Humanoid")
		or not root:IsA("BasePart")
		or humanoid.Health <= 0
	then
		return
	end
	generation += 1
	local now = workspace:GetServerTimeNow()
	local state = {
		player = player,
		character = character,
		humanoid = humanoid,
		root = root,
		generation = generation,
		weapon = Weapons.forPlayer(player),
		nextHand = "Right",
		connections = {},
		sequence = 0,
		aim = Vector3.new(0, 0, -1),
		reactionUntil = 0,
		protectionUntil = 0,
		spawnProtectionUntil = 0,
		lastPress = -math.huge,
		lastAim = -math.huge,
		lastSteer = -math.huge,
		tokens = 12,
		tokenAt = now,
		previousTime = now,
		previousPosition = root.Position,
		safe = root.CFrame,
		credit = F1.WalkSpeed * Physics.BurstSeconds + Physics.PositionSlack,
		residualSpeed = 0,
		displacementId = 0,
		walkSpeed = humanoid.WalkSpeed,
		jumpHeight = humanoid.JumpHeight,
	}
	states[player] = state
	character:SetAttribute("F2Weapon", state.weapon)
	character:SetAttribute("F7NextHand", state.nextHand)
	character:SetAttribute("F2Equipped", true)
	character:SetAttribute("F2Generation", generation)
	root:SetAttribute("F2Generation", generation)
	table.insert(
		state.connections,
		humanoid.Died:Connect(function()
			if states[player] == state then
				remove(player, "death")
			end
		end)
	)
	table.insert(
		state.connections,
		character:GetAttributeChangedSignal("F2Equipped"):Connect(function()
			if states[player] ~= state then
				return
			end
			clearAction(state, "equip-changed")
			release(state, "equip-changed")
			generation += 1
			state.generation = generation
			state.sequence = 0
			state.nextHand = "Right"
			character:SetAttribute("F7NextHand", state.nextHand)
			character:SetAttribute("F2Generation", generation)
			root:SetAttribute("F2Generation", generation)
			permissions(state, workspace:GetServerTimeNow())
		end)
	)
	table.insert(
		state.connections,
		player:GetAttributeChangedSignal("F2Weapon"):Connect(function()
			local weapon = Weapons.forPlayer(player)
			if states[player] == state and weapon ~= state.weapon then
				character:SetAttribute("F2Equipped", false)
				state.weapon = weapon
				character:SetAttribute("F2Weapon", weapon)
				character:SetAttribute("F2Equipped", true)
			end
		end)
	)
end

local function addPlayer(player)
	if playerConnections[player] then
		return
	end
	playerConnections[player] = {
		player.CharacterAdded:Connect(function(character)
			addCharacter(player, character)
		end),
		player.CharacterRemoving:Connect(function(character)
			local state = states[player]
			if state and state.character == character then
				remove(player, "character-removing")
			end
		end),
	}
	if player.Character then
		task.spawn(addCharacter, player, player.Character)
	end
end

-- Server teleports must reset the sampled path before the next combat update.
function Combat.resetMovement(player)
	local state = states[player]
	if not valid(state) then
		return
	end
	state.safe, state.previousPosition = state.root.CFrame, state.root.Position
	state.previousTime = workspace:GetServerTimeNow()
	state.previousVerticalSpeed = math.abs(state.root.AssemblyLinearVelocity.Y)
	state.credit = math.max(F1.WalkSpeed, state.residualSpeed) * Physics.BurstSeconds + Physics.PositionSlack
end

function Combat.step(dt)
	local now = workspace:GetServerTimeNow()
	if matchOwner and not matchOwner.allowed(now) then
		return
	end
	local excluded = { probe }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	local contacts = {}
	for player, state in states do
		if not valid(state) then
			remove(player, "invalid-character")
			continue
		end
		local root, displacement = state.root, state.displacement
		state.spawnProtectionUntil = if lifeOwner then lifeOwner.protectionUntil(player) else 0
		local velocity = root.AssemblyLinearVelocity
		local speed = math.max(state.humanoid.WalkSpeed, state.residualSpeed)
		local invalid = not Physics.vector(root.Position)
			or not Physics.vector(velocity)
			or not Physics.vector(root.CFrame.LookVector)
		local distance = if invalid
			then math.huge
			else Physics.horizontal(root.Position - state.previousPosition).Magnitude
		local exceeded
		state.credit, exceeded = Physics.budget(state.credit, distance, dt, speed)
		local verticalReset = not invalid
			and math.abs(root.Position.Y - state.previousPosition.Y)
				> math.max(math.abs(velocity.Y), state.previousVerticalSpeed or 0) * dt + Physics.PositionSlack
		local corrected = invalid or exceeded or verticalReset
		if corrected then
			state.buffer = nil
			own(state, nil)
			root.CFrame, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity =
				state.safe, Vector3.zero, Vector3.zero
			state.correctionUntil = now + Config.CorrectionHold
			state.credit = speed * Physics.BurstSeconds + Physics.PositionSlack
			warn(
				"F2 movement corrected",
				player.Name,
				state.generation,
				if invalid then "nonfinite" elseif verticalReset then "vertical-reset" else "horizontal-budget"
			)
			emit("corrected", state)
		else
			state.safe = root.CFrame
		end
		if state.correctionUntil and now >= state.correctionUntil then
			state.correctionUntil = nil
			if not displacement then
				own(state, player)
			end
		end
		if displacement then
			local elapsed = now - displacement.started
			local supported = ground(state, excluded)
			displacement.leftGround = displacement.leftGround or not supported
			displacement.observed = displacement.observed
				or (root.Position - displacement.origin).Magnitude >= Config.ObservedMotion
			local landed = displacement.leftGround and supported and velocity.Y <= 0
			if displacement.observed and Physics.recovered(elapsed, velocity, landed) then
				release(state, "natural")
			elseif elapsed >= Config.DisplacementFailsafe then
				release(state, "failsafe")
			else
				state.humanoid.EvaluateStateMachine = false
				local steering = if now - state.lastSteer <= Config.InputExpiry then state.steer else Vector3.zero
				root.AssemblyLinearVelocity = Physics.steer(root.AssemblyLinearVelocity, steering, dt)
			end
		end
		-- Residual velocity remains budgeted after handoff; allowance decays only toward observed legitimate motion.
		state.residualSpeed = math.max(
			0,
			math.min(
				state.residualSpeed + Physics.SteeringAcceleration * dt,
				Physics.horizontal(root.AssemblyLinearVelocity).Magnitude
			)
		)
		local action = state.action
		if action then
			local first, last = Fist.segment(action.started, state.previousTime, now, action.config)
			if first then
				local duration = now - state.previousTime
				local function positionAt(t)
					return if corrected or duration <= 0
						then root.Position
						else state.previousPosition:Lerp(
							root.Position,
							math.clamp((t - state.previousTime) / duration, 0, 1)
						)
				end
				local victims = {}
				for _, other in states do
					if
						other ~= state
						and valid(other)
						and (player.Neutral or other.player.Neutral or player.Team ~= other.player.Team)
					then
						table.insert(victims, other)
					end
				end
				for _, contact in
					Contact.sweep(probe, action, positionAt(first), positionAt(last), first, last, excluded, victims)
				do
					contact.attacker, contact.action = state, action
					table.insert(contacts, contact)
				end
				if action.wallStopped then
					emit("wall", state, { id = action.id, reach = action.stoppedReach })
				end
			end
		end
		state.previousPosition, state.previousTime = root.Position, now
		state.previousVerticalSpeed = math.abs(root.AssemblyLinearVelocity.Y)
	end
	local winners, canceled, blocked = Fist.resolve(contacts, Config)
	for _, contact in blocked do
		if contact.action.config == Weapons.PaddlePops then
			emit("shield", contact.victim, { actionId = contact.action.id, point = contact.point })
		end
	end
	for _, contact in winners do
		local victim = contact.victim
		victim.buffer = nil
		if victim.action and canceled[victim.action] then
			clearAction(victim, "startup-interrupted")
		end
		launch(contact, now, excluded)
	end
	for _, state in states do
		local action = state.action
		if action and now >= action.started + action.config.Duration then
			state.action = nil
			local buffered = state.buffer
			state.buffer = nil
			if buffered and equipped(state) and not state.displacement and now >= state.reactionUntil then
				startAction(state, buffered, now)
			elseif buffered then
				emit("rejected", state, { sequence = buffered, reason = "buffer-invalidated" })
			end
		end
		permissions(state, now)
	end
end

function Combat.bindMatch(owner)
	matchOwner = owner
end

function Combat.start(lives)
	if remote then
		return
	end
	lifeOwner = lives
	remote = Instance.new("RemoteEvent")
	remote.Name = "F2Combat"
	remote.Parent = Storage
	probe = Instance.new("Part")
	probe.Name = "F2ContactProbe"
	probe.Size = Config.Size
	probe.Anchored, probe.CanCollide, probe.CanTouch, probe.CanQuery = true, false, false, false
	probe.Transparency = 1
	probe.Parent = workspace
	table.insert(connections, remote.OnServerEvent:Connect(Combat.request))
	table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			remove(player, "departure")
			for _, connection in playerConnections[player] or {} do
				connection:Disconnect()
			end
			playerConnections[player] = nil
		end)
	)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

function Combat.stop()
	for player in states do
		remove(player, "shutdown")
	end
	for _, group in playerConnections do
		for _, connection in group do
			connection:Disconnect()
		end
	end
	table.clear(playerConnections)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if remote then
		remote:Destroy()
		remote = nil
	end
	if probe then
		probe:Destroy()
		probe = nil
	end
end

return Combat
