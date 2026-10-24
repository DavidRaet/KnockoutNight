return function(makeLobby, makeLives, makeMatch)
	local checks = 0
	local function check(value, message)
		assert(value, "L5/L6 journey: " .. message)
		checks += 1
	end
	local function signal()
		local callbacks, event = {}, { Event = {} }
		function event.Event:Connect(callback)
			local connection = { Connected = true }
			function connection.Disconnect()
				connection.Connected = false
			end
			table.insert(callbacks, { connection, callback })
			return connection
		end
		function event:Fire(...)
			for _, entry in table.clone(callbacks) do
				if entry[1].Connected then
					entry[2](...)
				end
			end
		end
		return event
	end
	local added, removed, heartbeat = signal(), signal(), signal()
	local players = {
		PlayerAdded = added.Event,
		PlayerRemoving = removed.Event,
		RunService = { Heartbeat = heartbeat.Event },
		Play = signal(),
		Return = signal(),
		Request = signal(),
		Now = 0,
		list = {},
		private = {},
	}
	function players:GetPlayers()
		return table.clone(self.list)
	end
	function players:Private(player, data)
		self.private[player] = data
	end
	for id = 1, 3 do
		local attrs, removing = {}, signal()
		local p = {
			Name = "Journey" .. id,
			DisplayName = "Journey" .. id,
			UserId = -1000 - id,
			Parent = players,
			CharacterRemoving = removing.Event,
			Removing = removing,
		}
		function p:SetAttribute(key, value)
			attrs[key] = value
		end
		function p:GetAttribute(key)
			return attrs[key]
		end
		table.insert(players.list, p)
	end
	local combat = { retire = function() end, resetMovement = function() end, bindMatch = function() end }
	local lives = makeLives(players, combat)
	local match = makeMatch(players, lives, combat)
	players.Lives, players.Match = lives, match
	local lobby, arena = makeLobby(players), nil
	local failLoad = false
	local offset = Vector3.new(400, 0, 0)
	local function prepare(name)
		local nextArena, frames, points, fallback = require(game.ServerScriptService.L5Arenas).build(name)
		nextArena:PivotTo(nextArena:GetPivot() + offset)
		local center = nextArena:GetAttribute("F3BoundsCenter")
			or require(game.ReplicatedStorage.F1Config).PlatformCenter
		nextArena:SetAttribute("F3BoundsCenter", center + offset)
		for index, frame in frames do
			frames[index] = frame + offset
		end
		nextArena.Parent = workspace
		if arena then
			arena:Destroy()
		end
		arena = nextArena
		return frames, points, fallback
	end
	local function create(player, frame, isLobby)
		local character = Instance.new("Model")
		local root, humanoid = Instance.new("Part"), Instance.new("Humanoid")
		root.Name, root.Size, root.Anchored, root.CFrame = "HumanoidRootPart", Vector3.new(2, 2, 1), true, frame
		root.Parent, humanoid.Parent = character, character
		character.PrimaryPart = root
		character:SetAttribute("L3LobbyCharacter", isLobby == true)
		local old = player.Character
		if old then
			player.Removing:Fire(old)
			old:Destroy()
		end
		player.Character, character.Parent = character, workspace
		return character
	end
	local _, points, fallback = prepare("ThePlatform")
	lives.start(create, arena, points, fallback)
	match.start()
	lobby.start(create, function(name)
		if failLoad then
			error("L6 intentional fixture arena-load failure")
		end
		local nextFrames, nextPoints, nextFallback = prepare(name)
		lives.setArena(arena, nextPoints, nextFallback)
		return nextFrames
	end)
	local a, b, waiting = table.unpack(players.list)
	local function data()
		return game.HttpService:JSONDecode(game.ReplicatedStorage.L6FixtureState.Value)
	end
	local function request(p, command, value)
		players.Now += 0.2
		players.Request:Fire(p, data().session, command, value)
	end
	local function queue(p)
		p.Character:PivotTo(workspace.L6FixtureLobby.Queue1v1.CFrame + Vector3.new(0, 3, 0))
	end
	local passed, failure = pcall(function()
		for _, p in players.list do
			players.Play:Fire(p)
			queue(p)
		end
		lobby.step()
		players.Now = 3
		lobby.step()
		check(data().phase == "vote" and data().phaseDeadline == 13, "dispatch starts full ten-second vote")
		request(a, "vote", "SkyBridges")
		request(b, "vote", "SkyBridges")
		players.Now = 12.99
		lobby.step()
		check(data().phase == "vote", "unanimity does not shorten vote")
		local oldArena = arena
		players.Now = 13
		lobby.step()
		check(
			data().phase == "selection" and data().map == "SkyBridges" and data().phaseDeadline == 28,
			"voted map loads then starts fifteen seconds"
		)
		check(oldArena.Parent == nil and arena.Parent == workspace, "old geometry removed")
		check(
			a.Character.HumanoidRootPart.Anchored and b.Character.HumanoidRootPart.Anchored,
			"both arena spawns frozen"
		)
		check(
			#lives.roster() == 0 and a:GetAttribute("F2Weapon") == nil,
			"selection does not enter combat or reveal equipment"
		)
		request(a, "weapon", "WreckingHammer")
		request(a, "ability", "Bounce")
		check(
			players.private[a].weapon == "WreckingHammer" and players.private[a].ability == "Bounce",
			"own choices acknowledged privately"
		)
		check(
			players.private[b].weapon == nil and not game.ReplicatedStorage.L6FixtureState.Value:find("WreckingHammer"),
			"opponent and shared snapshot contain no choice"
		)
		request(a, "ready")
		request(a, "ability", "Magnet")
		check(not players.private[a].ready, "editing clears ready acknowledgement")
		request(a, "ready")
		request(b, "ready")
		lobby.step()
		check(match.phase() == "countdown" and data().phase == "match", "both ready starts real match countdown")
		check(
			a:GetAttribute("F2Weapon") == "WreckingHammer" and a:GetAttribute("F10Ability") == "Magnet",
			"chosen equipment applied at lock"
		)
		check(
			b:GetAttribute("F2Weapon") == "SpringFist" and b:GetAttribute("F10Ability") == "Gust",
			"missing fields default at lock"
		)
		check(players.private[b].defaultWeapon and players.private[b].defaultAbility, "default assignment explained")
		check(waiting:GetAttribute("L3State") == "lobby" and #lives.roster() == 2, "only assigned pair admitted")
		request(a, "weapon", "PaddlePops")
		check(a:GetAttribute("F2Weapon") == "WreckingHammer", "late change cannot alter locked equipment")
		players.Now += 2.7
		match.step()
		check(match.phase() == "countdown", "full opening countdown honored")
		players.Now += 0.4
		match.step()
		check(
			match.phase() == "regulation" and match.allowed(players.Now) and not a.Character.HumanoidRootPart.Anchored,
			"GO enables combat and movement"
		)
		match.fail()
		check(match.phase() == "results", "existing terminal results usable")
		check(match.returnToStaging(a, match.session()), "immediate result return accepted")
		check(a:GetAttribute("L3State") == "lobby" and data().busy, "one return does not release busy allocation")
		players.Now += 8
		match.step()
		lobby.step()
		check(
			not data().busy and b:GetAttribute("L3State") == "lobby" and #lives.roster() == 0,
			"automatic return releases allocation after cleanup"
		)
		for _, map in { "Dungeon", "ThePlatform" } do
			queue(a)
			queue(b)
			lobby.step()
			players.Now += 3
			lobby.step()
			request(a, "vote", map)
			request(b, "vote", map)
			players.Now = data().phaseDeadline
			lobby.step()
			check(data().map == map and data().phase == "selection", "reused session loads " .. map)
			players.Now = data().phaseDeadline
			lobby.step()
			check(match.phase() == "countdown", "no-input timeout starts match on " .. map)
			a.Removing:Fire(a.Character)
			check(
				not data().busy and match.phase() == "staging" and #lives.roster() == 0,
				"pre-GO reset cancels without official result on " .. map
			)
		end
		queue(a)
		queue(b)
		lobby.step()
		players.Now += 3
		lobby.step()
		players.Now = data().phaseDeadline
		failLoad = true
		lobby.step()
		check(not data().busy and #lives.roster() == 0, "arena-load failure cancels and releases allocation")
		failLoad = false
		queue(a)
		queue(b)
		lobby.step()
		players.Now += 3
		lobby.step()
		players.Now = data().phaseDeadline
		lobby.step()
		local participant
		for _, p in players.list do
			if p.UserId == data().roster[1] then
				participant = p
			end
		end
		participant.Removing:Fire(participant.Character)
		check(not data().busy and match.phase() == "staging", "selection reset cancels before life admission")
	end)
	lobby.stop()
	match.stop()
	lives.stop()
	for _, p in players.list do
		if p.Character then
			p.Character:Destroy()
		end
	end
	if arena then
		arena:Destroy()
	end
	assert(passed, "L5/L6 journey fixture failed: " .. tostring(failure))
	return { passed = true, checks = checks }
end
