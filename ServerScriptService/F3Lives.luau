local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Config = require(Storage.F3Config)
local World = require(Storage.F1Config)
local Rules = require(Storage.F3Rules)
local Combat = require(script.Parent.F2Combat)
local Lives = {}
local records, connections = {}, {}
local spawnCharacter, arena, candidates, fallback, remote
local stopped = false
local matchOwner
local resetSafePhase = function() end
local lowerY = World.PlatformCenter.Y + World.PlatformThickness / 2 - Config.LowerOffset
local outerRadius = World.PlatformDiameter / 2 + Config.OuterMargin

local function publish(player, state)
	player:SetAttribute("F3Life", state.life)
	player:SetAttribute("F3Score", state.score)
	player:SetAttribute("F3EliminatedAt", state.eliminatedAt)
	player:SetAttribute("F3RespawnAt", state.respawnAt)
	player:SetAttribute("F3Status", state.status)
end

function Lives.endProtection(player)
	local state = records[player]
	if not state then
		return
	end
	state.protectionUntil = 0
	if state.shield then
		state.shield:Destroy()
		state.shield = nil
	end
	if state.character then
		state.character:SetAttribute("F3ProtectionUntil", 0)
	end
end

function Lives.protectionUntil(player)
	local state = records[player]
	return if state then state.protectionUntil else 0
end

function Lives.alive(player)
	local state = records[player]
	local character = state and state.character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return not stopped
		and state ~= nil
		and state.status == "alive"
		and player.Parent == Players
		and player.Character == character
		and character.Parent ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and root ~= nil
		and not Rules.outside(root.Position, World.PlatformCenter, lowerY, outerRadius)
end

function Lives.hit(victim, attacker, at)
	local state = records[victim]
	if state and state.status == "alive" then
		state.lastHit = { name = attacker.DisplayName, at = at }
	end
end

local function halt(message)
	if stopped then
		return
	end
	stopped = true
	if matchOwner then
		matchOwner.fail()
	end
	workspace:SetAttribute("F3SessionError", message)
	warn("F3 session stopped: " .. message)
	for player, state in records do
		state.status = "stopped"
		Lives.endProtection(player)
		Combat.retire(player, "session-stopped")
		if state.character then
			state.character:SetAttribute("F3Alive", false)
			local root = state.character:FindFirstChild("HumanoidRootPart")
			if root then
				root.Anchored = true
			end
		end
		publish(player, state)
	end
end

function Lives.eliminate(player, life, reason, session)
	local state = records[player]
	local now = workspace:GetServerTimeNow()
	if
		stopped
		or player.Parent ~= Players
		or not state
		or state.life ~= life
		or state.status ~= "alive"
		or (session ~= nil and session ~= state.session)
	then
		return false
	end
	local credit = state.lastHit
	local event = {
		session = state.session,
		victim = player.DisplayName,
		attacker = if credit and now - credit.at <= Config.AttributionWindow then credit.name else nil,
		weapon = "Spring Fist",
		reason = reason,
		at = now,
	}
	if not matchOwner or not matchOwner.commit(player, life, state.session, now, event) then
		return false
	end
	Rules.eliminate(state, life, now, Config.RespawnDelay)
	if not matchOwner.respawns() then
		state.respawnAt = nil
	end
	Lives.endProtection(player)
	Combat.retire(player, "eliminated")
	local character = state.character
	character:SetAttribute("F3Alive", false)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide, part.CanTouch = false, false
		end
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:CanSetNetworkOwnership() then
		root:SetNetworkOwner(nil)
	end
	publish(player, state)
	return true
end

function Lives.notify(event)
	remote:FireAllClients(event)
end

function Lives.setScore(player, score)
	local state = records[player]
	if state and state.score ~= score then
		state.score = score
		publish(player, state)
	end
end

local function safe(player, marker)
	if not marker.Parent or marker:GetAttribute("F3SpawnAvailable") == false then
		return false
	end
	local frame = marker.CFrame
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = { arena }
	ray.RespectCanCollide = true
	for _, offset in
		{
			Vector3.zero,
			Vector3.new(-2.5, 0, -2.5),
			Vector3.new(2.5, 0, -2.5),
			Vector3.new(-2.5, 0, 2.5),
			Vector3.new(2.5, 0, 2.5),
		}
	do
		local hit = workspace:Raycast(frame.Position + offset, -Vector3.yAxis * 8, ray)
		if not hit or hit.Normal.Y < 0.9 or hit.Instance:GetAttribute("F3SpawnAvailable") == false then
			return false
		end
	end
	local excluded = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		if character then
			table.insert(excluded, character)
			local root = character:FindFirstChild("HumanoidRootPart")
			if other ~= player and root and character:GetAttribute("F3Alive") ~= false then
				local delta = root.Position - frame.Position
				if math.abs(delta.X) < 5 and math.abs(delta.Z) < 5 and math.abs(delta.Y) < 7 then
					return false
				end
			end
		end
	end
	local overlap = OverlapParams.new()
	overlap.FilterDescendantsInstances = excluded
	overlap.RespectCanCollide = true
	return #workspace:GetPartBoundsInBox(frame + Vector3.yAxis * 0.25, Vector3.new(5, 7, 5), overlap) == 0
end

local function choose(player, state)
	local distances = {}
	for index, marker in candidates do
		local nearest = -math.huge
		if safe(player, marker) then
			nearest = math.huge
			for opponent, other in records do
				if opponent ~= player and Lives.alive(opponent) then
					local delta = other.character.HumanoidRootPart.Position - marker.Position
					nearest = math.min(nearest, delta.X * delta.X + delta.Z * delta.Z)
				end
			end
		end
		distances[index] = nearest
	end
	return Rules.choose(distances, state.previousSpawn)
end

local function spawn(player, state, frame, protected)
	local ok, character = pcall(spawnCharacter, player, frame)
	if not ok or not character then
		halt("Character creation failed. Restart the local session.")
		warn("F3 character creation failure", character)
		return
	end
	for _, connection in state.connections do
		connection:Disconnect()
	end
	state.life += 1
	state.character, state.status = character, "alive"
	state.lastHit, state.eliminatedAt, state.respawnAt = nil, nil, nil
	state.protectionUntil = if protected then workspace:GetServerTimeNow() + Config.SpawnProtection else 0
	character:SetAttribute("F3Alive", true)
	character:SetAttribute("F3Life", state.life)
	character:SetAttribute("F3ProtectionUntil", state.protectionUntil)
	if protected then
		state.shield = Instance.new("ForceField")
		state.shield.Name, state.shield.Visible = "F3SpawnShield", true
		state.shield.Parent = character
	end
	local life, session = state.life, state.session
	state.connections = {
		character.Humanoid.Died:Connect(function()
			-- Defer removal/death callbacks so PlayerRemoving can discard a departure first.
			task.defer(Lives.eliminate, player, life, "death", session)
		end),
		player.CharacterRemoving:Connect(function(removed)
			if removed == character then
				task.defer(Lives.eliminate, player, life, "character-removed", session)
			end
		end),
	}
	publish(player, state)
end

function Lives.add(player, initialFrame)
	if records[player] or player.Parent ~= Players then
		return
	end
	if matchOwner and not matchOwner.canJoin() then
		player:SetAttribute("F3Status", "waiting")
		return
	end
	local state = {
		life = 0,
		session = 0,
		initialFrame = initialFrame,
		status = "waiting",
		score = 0,
		previousSpawn = 0,
		protectionUntil = 0,
		connections = {},
	}
	records[player] = state
	if stopped then
		state.status = "stopped"
		publish(player, state)
		return
	end
	spawn(player, state, initialFrame, false)
	Lives.stage(player)
end

function Lives.bindMatch(owner)
	matchOwner = owner
end

function Lives.roster()
	local roster = {}
	for player in records do
		if player.Parent == Players then
			table.insert(roster, player)
		end
	end
	table.sort(roster, function(a, b)
		return a.UserId < b.UserId
	end)
	return roster
end

function Lives.freeze(player, frozen, retire)
	local state = records[player]
	if not state then
		return
	end
	if retire then
		Lives.endProtection(player)
		Combat.retire(player, "match-frozen")
	end
	local character = state.character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root then
		root.Anchored = frozen
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	end
	if humanoid then
		humanoid.WalkSpeed = if frozen then 0 else World.WalkSpeed
		humanoid.JumpHeight = if frozen then 0 else World.JumpHeight
		humanoid.Jump = false
	end
end

function Lives.stage(player)
	local state = records[player]
	if state then
		Lives.freeze(player, true, true)
		state.status, state.respawnAt = "waiting", nil
		publish(player, state)
	end
end

function Lives.reset(player, preserveScore)
	local state = records[player]
	assert(state, "F4 fresh match requires an admitted player life record")
	Lives.endProtection(player)
	Combat.retire(player, "fresh-match")
	state.session, state.score, state.previousSpawn = matchOwner.session(), if preserveScore then state.score else 0, 0
	stopped = false
	workspace:SetAttribute("F3SessionError", nil)
	spawn(player, state, state.initialFrame, false)
	Lives.freeze(player, true, false)
end

function Lives.resetRound(roster)
	-- Arena-owned hook restores safe hazards before any fresh spawn/countdown.
	resetSafePhase()
	local lives = {}
	for side, player in roster do
		if player.Parent == Players then
			Lives.reset(player, true)
			lives[side] = records[player].life
		end
	end
	return lives
end

function Lives.remove(player)
	local state = records[player]
	if state then
		Lives.endProtection(player)
		records[player] = nil
		for _, connection in state.connections do
			connection:Disconnect()
		end
	end
end

function Lives.step()
	if not remote or stopped or not matchOwner or not matchOwner.allowed(workspace:GetServerTimeNow()) then
		return
	end
	local now = workspace:GetServerTimeNow()
	local players = Players:GetPlayers()
	table.sort(players, function(a, b)
		return a.UserId < b.UserId
	end)
	-- Commit every eliminated life before choosing a spawn or resolving any combat.
	for _, player in players do
		local state = records[player]
		if state and state.status == "alive" and not Lives.alive(player) then
			Lives.eliminate(player, state.life, "fall-or-death")
		end
	end
	for _, player in players do
		local state = records[player]
		if not state then
			continue
		end
		if state.shield and now >= state.protectionUntil then
			state.shield:Destroy()
			state.shield = nil
		end
		if state.status == "eliminated" and matchOwner.respawns() then
			state.candidate = choose(player, state)
			if now >= state.respawnAt then
				local marker = if state.candidate then candidates[state.candidate] else fallback
				-- Revalidate at the deadline; old countdown samples never authorize an unsafe placement.
				if not safe(player, marker) then
					halt("No safe respawn surface is available. Restart the local session.")
					return
				end
				state.previousSpawn = state.candidate or state.previousSpawn
				spawn(player, state, marker.CFrame, true)
			end
		end
	end
end

function Lives.start(createCharacter, world, points, emergency, resetHazards)
	assert(not remote, "F3 lives must be started only once per local session")
	spawnCharacter, arena, candidates, fallback = createCharacter, world, points, emergency
	resetSafePhase = resetHazards or function() end
	remote = Instance.new("RemoteEvent")
	remote.Name, remote.Parent = "F3Knockouts", Storage
	workspace:SetAttribute("F3SessionError", nil)
	table.insert(connections, Players.PlayerRemoving:Connect(Lives.remove))
end

function Lives.stop()
	stopped = true
	for player in records do
		Lives.remove(player)
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if remote then
		remote:Destroy()
		remote = nil
	end
end

return Lives
