local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Config = require(Storage.F2Config)
local Gust = require(Storage.F8Gust)
local Magnet = require(Storage.F9Magnet)
local Bounce = require(Storage.F10Bounce)
local Slam = require(Storage.F11Slam)
local cooldowns, magnetCooldowns, bounceCooldowns = {}, {}, {}
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
local ground

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
	if displacement.pull then
		state.protectionUntil = math.max(displacement.started + Magnet.Protection, workspace:GetServerTimeNow())
		local velocity = state.root.AssemblyLinearVelocity
		state.root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
		state.root:SetAttribute("F9Pulling", nil)
	end
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
	state.humanoid.JumpHeight = if restricted or (action and not action.config.CanJump) then 0 else F1.JumpHeight
	state.root:SetAttribute("F2ReactionUntil", state.reactionUntil)
	state.root:SetAttribute("F2ProtectionUntil", state.protectionUntil)
	state.root:SetAttribute(
		"F2ActionUntil",
		if action then action.endsAt or action.started + action.config.Duration else nil
	)
	state.root:SetAttribute("F2ActionAim", if action then action.aim else nil)
	state.root:SetAttribute("F2ActionCanJump", if action then action.config.CanJump == true else nil)
	if restricted or (action and not action.config.CanJump) then
		state.humanoid.Jump = false
	end
end

local function clearAction(state, reason)
	state.slamOpportunity = nil
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
	for _, other in states do
		if other.displacement and other.displacement.source == state then
			release(other, "magnet-source-removed")
		end
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
		{
			"F2ActionCanJump",
			"F9Pulling",
			"F10PrimaryAt",
			"F2Generation",
			"F2ActionUntil",
			"F2ActionAim",
			"F2ReactionUntil",
			"F2ProtectionUntil",
			"F2Restart",
		}
	do
		state.root:SetAttribute(name, nil)
	end
	state.character:SetAttribute("F2Generation", nil)
	state.character:SetAttribute("F2Equipped", nil)
	state.character:SetAttribute("F2Weapon", nil)
	state.character:SetAttribute("F7NextHand", nil)
end

function Combat.retire(player, reason)
	if reason == "fresh-match" then
		cooldowns[player], magnetCooldowns[player], bounceCooldowns[player] = nil, nil, nil
		player:SetAttribute("F8ReadyAt", nil)
		player:SetAttribute("F9ReadyAt", nil)
		player:SetAttribute("F10ReadyAt", nil)
	end
	remove(player, reason)
end

local function bounce(state, sequence, now, direction)
	if not own(state, nil) then
		return false
	end
	-- Finish a pull/knockback before replacing velocity; keep its attribution and remaining protection.
	release(state, "bounce")
	own(state, nil)
	if lifeOwner then
		lifeOwner.endProtection(state.player)
		state.spawnProtectionUntil = 0
	end
	state.reactionUntil = 0
	state.primaryAt = now + Bounce.PrimaryDelay
	state.slamOpportunity = { airborne = false }
	state.buffer = nil
	bounceCooldowns[state.player] = now + Bounce.Cooldown
	state.player:SetAttribute("F10ReadyAt", bounceCooldowns[state.player])
	state.root:SetAttribute("F10PrimaryAt", state.primaryAt)
	state.displacementId += 1
	state.displacement = {
		id = state.displacementId,
		motor = state.humanoid.EvaluateStateMachine,
		started = now,
		bounce = true,
	}
	state.humanoid.EvaluateStateMachine = false
	state.root:SetAttribute("F2MotorEnabled", state.displacement.motor)
	state.root:SetAttribute("F2Displaced", state.displacementId)
	state.root.AssemblyLinearVelocity = Vector3.new(Bounce.components(direction.X, direction.Z))
	state.previousVerticalSpeed = Bounce.LaunchUp
	state.residualSpeed = Bounce.LaunchSpeed
	state.credit = Bounce.LaunchSpeed * Physics.BurstSeconds + Physics.PositionSlack
	emit("bounce", state, {
		sequence = sequence,
		displacement = state.displacementId,
		primaryAt = state.primaryAt,
	})
	permissions(state, now)
	return true
end

local function slamDrive(state, now)
	if not state.displacement then
		-- Ownership transfer can deliver a burst of the already-authorized Bounce trajectory.
		state.slamHandoffUntil = now + Physics.BurstSeconds
		state.slamVerticalCredit = Bounce.LaunchUp * Physics.BurstSeconds
	end
	local motor = if state.displacement then state.displacement.motor else state.humanoid.EvaluateStateMachine
	release(state, "slam-descent")
	own(state, nil)
	state.displacementId += 1
	state.displacement = { id = state.displacementId, motor = motor, started = now, slam = true }
	state.humanoid.EvaluateStateMachine = false
	state.root:SetAttribute("F2MotorEnabled", motor)
	state.root:SetAttribute("F2Displaced", state.displacementId)
end

local function startAction(state, sequence, now, ability)
	if lifeOwner then
		lifeOwner.endProtection(state.player)
		state.spawnProtectionUntil = 0
	end
	actionId += 1
	local config = if ability == "GroundSlam"
		then Slam
		elseif ability == "Magnet" then Magnet
		elseif ability then Gust
		else Weapons[state.weapon]
	if config == Slam then
		state.slamOpportunity = nil
		slamDrive(state, now)
	elseif ability then
		local ledger = if config == Magnet then magnetCooldowns else cooldowns
		ledger[state.player] = now + config.Cooldown
		state.player:SetAttribute(if config == Magnet then "F9ReadyAt" else "F8ReadyAt", ledger[state.player])
	end
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
		ability = ability,
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
	local aim
	if kind == "bounce" then
		if not Physics.vector(intendedAim) or intendedAim.Y ~= 0 or intendedAim.Magnitude > 1.001 then
			return false
		end
		aim = state.aim
	else
		aim = Fist.aim(intendedAim)
	end
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
		(kind ~= "press" and kind ~= "gust" and kind ~= "magnet" and kind ~= "bounce")
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
		remote:FireClient(player, "rejected", {
			character = state.character,
			generation = gen,
			sequence = sequence,
			reason = reason,
			ability = if kind == "bounce"
				then "Bounce"
				elseif kind == "magnet" then "Magnet"
				elseif kind == "gust" then "Gust"
				else nil,
		})
		return false
	end
	if now - state.lastPress < Config.InputInterval then
		return reject("rate")
	end
	state.lastPress = now
	state.aim = aim
	local pulling = state.displacement and state.displacement.pull
	local selected = player:GetAttribute("F10Ability") or "Bounce"
	if kind ~= "press" and string.lower(selected) ~= kind then
		return reject("unequipped")
	end
	local restricted = (now < state.reactionUntil and (kind ~= "bounce" or now < state.stunUntil))
		or (state.displacement ~= nil and not pulling and kind == "press")
	if restricted then
		return reject("hit-recovery")
	end
	if kind == "bounce" then
		if state.action then
			return reject("busy")
		end
		if now < (bounceCooldowns[player] or 0) then
			return reject("cooldown")
		end
		if not bounce(state, sequence, now, intendedAim) then
			return reject("ownership")
		end
		return true
	end
	if kind == "press" and now < state.primaryAt then
		return reject("bounce-delay")
	end
	if
		state.slamOpportunity
		and state.root.AssemblyLinearVelocity.Y <= 0
		and ground(state, { state.character, probe })
	then
		state.slamOpportunity = nil
	end
	if kind == "gust" or kind == "magnet" then
		if state.action then
			return reject("busy")
		end
		local ledger = if kind == "magnet" then magnetCooldowns else cooldowns
		if now < (ledger[player] or 0) then
			return reject("cooldown")
		end
		startAction(state, sequence, now, if kind == "magnet" then "Magnet" else "Gust")
		return true
	end
	if state.action then
		if
			state.action.config ~= Gust
			and state.action.config ~= Slam
			and state.action.config ~= Magnet
			and Fist.canBuffer(now - state.action.started, state.buffer ~= nil, restricted, state.action.config)
		then
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
	startAction(
		state,
		sequence,
		now,
		if state.slamOpportunity and state.weapon == "WreckingHammer" then "GroundSlam" else nil
	)
	return true
end

ground = function(state, excluded)
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

local function beginPull(contact, now)
	local state, source = contact.victim, contact.attacker
	if not valid(state) or not valid(source) or not own(state, nil) then
		return
	end
	local previous = state.displacement
	state.displacementId += 1
	state.displacement = {
		id = state.displacementId,
		motor = if previous then previous.motor else state.humanoid.EvaluateStateMachine,
		started = now,
		pull = true,
		source = source,
		sourceGeneration = source.generation,
		position = state.root.Position,
	}
	state.humanoid.EvaluateStateMachine = false
	state.root:SetAttribute("F2MotorEnabled", state.displacement.motor)
	state.root:SetAttribute("F2Displaced", state.displacementId)
	state.root:SetAttribute("F9Pulling", true)
	state.protectionUntil = math.max(now + Magnet.Protection, now + Magnet.PullDuration)
	state.residualSpeed = Magnet.PullSpeed
	state.credit = Magnet.PullSpeed * Physics.BurstSeconds + Physics.PositionSlack
	if lifeOwner then
		lifeOwner.hit(state.player, source.player, now, "Magnet")
	end
	emit("pull", state, { displacement = state.displacementId })
	emit("magnet-pull", source, { target = state.character, id = contact.action.id })
end

local function updatePull(state, displacement, now, dt, excluded)
	local root, source = state.root, displacement.source
	local remaining = Magnet.PullDuration - (now - displacement.started)
	if not equipped(source) or source.generation ~= displacement.sourceGeneration or remaining <= 0 then
		release(state, "magnet-complete")
		return
	end
	local delta = Physics.horizontal(source.root.Position - root.Position)
	local speed = Magnet.speed(delta.Magnitude, dt, remaining)
	if
		speed <= 0
		or (displacement.moving and Physics.horizontal(root.Position - displacement.position).Magnitude < 0.01)
	then
		release(state, "magnet-stopped")
		return
	end
	local direction = delta.Unit * speed * dt
	local ray = RaycastParams.new()
	ray.FilterDescendantsInstances, ray.RespectCanCollide = excluded, true
	-- Sweep the root and physical body parts; velocity-driven motion also retains solver collisions.
	local bodies = Contact.body(state.character)
	table.insert(bodies, root)
	for _, body in bodies do
		if body.CanCollide and workspace:Blockcast(body.CFrame, body.Size, direction, ray) then
			release(state, "magnet-obstacle")
			return
		end
	end
	displacement.position, displacement.moving = root.Position, true
	state.humanoid.EvaluateStateMachine = false
	root.AssemblyLinearVelocity = delta.Unit * speed + Vector3.yAxis * root.AssemblyLinearVelocity.Y
end

local function launch(contact, now, excluded)
	local state, action = contact.victim, contact.action
	local config = action.config
	if config ~= Gust then
		state.slamOpportunity = nil
	end
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
	state.root.AssemblyLinearVelocity = (contact.aim or action.aim) * config.LaunchSpeed
		+ Vector3.yAxis * config.LaunchUp
	state.reactionUntil, state.protectionUntil =
		contact.time + (config.Reaction or Config.Reaction), contact.time + Config.Protection
	state.stunUntil = if config == Gust then contact.time + Gust.Reaction else 0
	state.buffer = nil
	if lifeOwner then
		lifeOwner.hit(
			state.player,
			contact.attacker.player,
			contact.time,
			if config == Gust then "Gust" else contact.attacker.weapon
		)
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
		stunUntil = 0,
		primaryAt = 0,
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
		if state.slamOpportunity then
			local supported = ground(state, excluded)
			if not supported then
				state.slamOpportunity.airborne = true
			elseif state.slamOpportunity.airborne and root.AssemblyLinearVelocity.Y <= 0 then
				state.slamOpportunity = nil
			end
		end
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
		local verticalExcess = if invalid
			then math.huge
			else math.max(
				0,
				math.abs(root.Position.Y - state.previousPosition.Y)
					- math.max(math.abs(velocity.Y), state.previousVerticalSpeed or 0) * dt
					- Physics.PositionSlack
			)
		local handoffCredit = if now <= (state.slamHandoffUntil or 0) then state.slamVerticalCredit or 0 else 0
		local verticalReset = not invalid and verticalExcess > handoffCredit
		state.slamVerticalCredit = math.max(0, handoffCredit - verticalExcess)
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
		if displacement and displacement.bounce then
			-- Keep the launch server-owned for one physics interval, then use ordinary airborne controls.
			if now > displacement.started then
				release(state, "bounce-flight")
			end
		elseif displacement and displacement.pull then
			updatePull(state, displacement, now, dt, excluded)
		elseif displacement and not displacement.slam then
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
				state.residualSpeed
					+ (
							if state.action and state.action.config == Slam
								then Slam.SteeringAcceleration
								else Physics.SteeringAcceleration
						)
						* dt,
				Physics.horizontal(root.AssemblyLinearVelocity).Magnitude
			)
		)
		local action = state.action
		if action then
			local first, last = Fist.segment(action.started, state.previousTime, now, action.config)
			if action.config == Slam then
				first, last = nil, nil
				if not action.landed and now >= action.started + Slam.Startup then
					local hit = Contact.slamLanding(state, state.previousPosition, excluded)
					if hit and root.AssemblyLinearVelocity.Y <= 0 then
						action.landed, action.endsAt = now, now + Slam.Recovery
						local feet = state.humanoid.HipHeight + root.Size.Y / 2
						root.CFrame += Vector3.yAxis * (hit.Position.Y + feet - root.Position.Y)
						root.AssemblyLinearVelocity = Physics.horizontal(root.AssemblyLinearVelocity)
						release(state, "slam-landed")
						emit("slam-impact", state, { id = action.id, origin = hit.Position, endsAt = action.endsAt })
						for _, other in states do
							if
								other ~= state
								and valid(other)
								and (player.Neutral or other.player.Neutral or player.Team ~= other.player.Team)
							then
								local point = Contact.slamTarget(hit.Position, other, excluded, hit.Instance)
								if point then
									local delta = other.root.Position - hit.Position
									local x, z = Slam.direction(delta.X, delta.Z, action.aim.X, action.aim.Z)
									table.insert(contacts, {
										attacker = state,
										action = action,
										victim = other,
										point = point,
										time = now,
										aim = Vector3.new(x, 0, z),
									})
								end
							end
						end
					elseif now >= state.reactionUntil and not (state.displacement and state.displacement.pull) then
						if not state.displacement or not state.displacement.slam then
							slamDrive(state, now)
						end
						local steering = if now - state.lastSteer <= Config.InputExpiry
							then state.steer
							else Vector3.zero
						local horizontal = Physics.horizontal(root.AssemblyLinearVelocity)
							+ steering * Slam.SteeringAcceleration * dt
						root.AssemblyLinearVelocity = horizontal
							+ Vector3.yAxis * math.min(root.AssemblyLinearVelocity.Y, -Slam.DownSpeed)
					end
				end
			elseif action.config == Magnet then
				first, last = nil, nil
				if not action.applied and now >= action.started + Magnet.Startup then
					action.applied = true
					action.magnetBurst = true
					local candidates = {}
					local at = action.started + Magnet.Startup
					for _, other in states do
						if
							other ~= state
							and valid(other)
							and (player.Neutral or other.player.Neutral or player.Team ~= other.player.Team)
							and at >= other.protectionUntil
							and at >= (if lifeOwner then lifeOwner.protectionUntil(other.player) else 0)
						then
							local point = Contact.gust(root.Position, action.aim, other, excluded, Magnet)
							local delta = Physics.horizontal(other.root.Position - root.Position)
							table.insert(candidates, {
								eligible = point ~= nil,
								point = point,
								state = other,
								id = other.player.UserId,
								distance = delta.Magnitude,
								alignment = if delta.Magnitude < 0.00001 then 1 else action.aim:Dot(delta.Unit),
							})
						end
					end
					local target = Magnet.select(candidates)
					if target then
						table.insert(contacts, {
							attacker = state,
							action = action,
							victim = target.state,
							point = target.point,
							time = at,
						})
					end
				end
			elseif action.config == Gust then
				first, last = nil, nil
				if not action.applied and now >= action.started + Gust.Startup then
					action.applied = true
					action.burstOrigin = root.Position
					for _, other in states do
						if
							other ~= state
							and valid(other)
							and (player.Neutral or other.player.Neutral or player.Team ~= other.player.Team)
						then
							local point = Contact.gust(root.Position, action.aim, other, excluded)
							if point then
								table.insert(contacts, {
									attacker = state,
									action = action,
									victim = other,
									point = point,
									time = action.started + Gust.Startup,
								})
							end
						end
					end
				end
			end
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
		if contact.action.config == Magnet then
			beginPull(contact, now)
			if victim.displacement and victim.displacement.pull then
				updatePull(victim, victim.displacement, now, dt, excluded)
			end
		else
			launch(contact, now, excluded)
		end
	end
	for _, state in states do
		local action = state.action
		if action and action.magnetBurst then
			emit("magnet-burst", state, { id = action.id, aim = action.aim, origin = state.root.Position })
			action.magnetBurst = nil
		end
		if action and action.burstOrigin then
			emit("gust-burst", state, { id = action.id, aim = action.aim, origin = action.burstOrigin })
			action.burstOrigin = nil
		end
		if action and now >= (action.endsAt or action.started + action.config.Duration) then
			state.action = nil
			local buffered = state.buffer
			state.buffer = nil
			if
				buffered
				and equipped(state)
				and (not state.displacement or state.displacement.pull)
				and now >= state.reactionUntil
			then
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
			cooldowns[player], magnetCooldowns[player], bounceCooldowns[player] = nil, nil, nil
			player:SetAttribute("F8ReadyAt", nil)
			player:SetAttribute("F9ReadyAt", nil)
			player:SetAttribute("F10ReadyAt", nil)
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
	for player in cooldowns do
		player:SetAttribute("F8ReadyAt", nil)
	end
	table.clear(cooldowns)
	for player in magnetCooldowns do
		player:SetAttribute("F9ReadyAt", nil)
	end
	table.clear(magnetCooldowns)
	for player in bounceCooldowns do
		player:SetAttribute("F10ReadyAt", nil)
	end
	table.clear(bounceCooldowns)
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
