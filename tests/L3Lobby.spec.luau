-- Engine fixture with synthetic players; real input/replication still needs multiplayer verification.
return function(Harness)
	local checks, signals = 0, {}
	local function check(value, message)
		assert(value, "L3 lobby lifecycle: " .. message)
		checks += 1
	end
	local function signal()
		local callbacks = {}
		local event = { Event = {} }
		function event.Event:Connect(callback)
			local connection = { Connected = true, callback = callback }
			function connection.Disconnect()
				connection.Connected = false
			end
			table.insert(callbacks, connection)
			return connection
		end
		function event:Fire(...)
			for _, connection in table.clone(callbacks) do
				if connection.Connected then
					connection.callback(...)
				end
			end
		end
		function event:Destroy()
			table.clear(callbacks)
		end
		table.insert(signals, event)
		return event
	end
	local added, removing, play = signal(), signal(), signal()
	local players = { PlayerAdded = added.Event, PlayerRemoving = removing.Event, Play = play, list = {} }
	function players:GetPlayers()
		return table.clone(self.list)
	end
	local function player(id)
		local attrs = {}
		local p = { Name = "L3Tester" .. id, UserId = id, Parent = players, CharacterRemoving = signal().Event }
		function p:SetAttribute(key, value)
			attrs[key] = value
		end
		function p:GetAttribute(key)
			return attrs[key]
		end
		table.insert(players.list, p)
		return p
	end
	local first, second, third, fourth = player(1), player(2), player(3), player(4)
	local lobby = Harness(players)
	local spawns, failNext = {}, false
	local function createCharacter(p, frame, isLobby)
		check(isLobby == true, "spawner marks lobby characters before assignment")
		if failNext then
			failNext = false
			error("L3 intentional fixture spawn failure")
		end
		spawns[p] = (spawns[p] or 0) + 1
		local root = { Position = frame.Position }
		local humanoid = { Health = 100, Died = signal().Event }
		local character = { root = root, humanoid = humanoid }
		function character:SetAttribute() end
		function character:FindFirstChild(name)
			return if name == "HumanoidRootPart" then root else nil
		end
		function character:FindFirstChildOfClass(name)
			return if name == "Humanoid" then humanoid else nil
		end
		p.Character = character
		return character
	end
	local function request(p)
		play:Fire(p)
		task.wait()
	end
	local snapshot
	local function roster()
		return game:GetService("HttpService"):JSONDecode(snapshot.Value)
	end
	local ok, failure = pcall(function()
		lobby.start(createCharacter)
		snapshot = game.ReplicatedStorage.L3FixtureQueueState
		check(first:GetAttribute("L3State") == "menu" and not first.Character, "join starts unspawned in menu")
		request(first)
		local original = first.Character
		for _ = 1, 20 do
			play:Fire(first)
		end
		task.wait()
		check(spawns[first] == 1 and first.Character == original, "repeated Play creates one character")
		check(
			first:GetAttribute("L3State") == "lobby" and first:GetAttribute("F3Status") == "lobby",
			"Play enters lobby state"
		)
		local pad = workspace.L3FixtureLobby.Queue1v1
		first.Character.root.Position = pad.Position + Vector3.new(0, 3, 0)
		lobby.step()
		check(#roster() == 1, "one entrant waits indefinitely")
		for _, p in { second, third, fourth } do
			request(p)
			p.Character.root.Position = pad.Position + Vector3.new(0, 3, 0)
		end
		lobby.step()
		local q = roster()
		check(
			#q == 4 and q[1].id == 1 and q[2].id == 2 and q[4].id == 4,
			"full pair and extras retain FIFO without dispatch"
		)
		first.Character.root.Position = pad.Position + Vector3.new(0, 10, 0)
		lobby.step()
		check(#roster() == 4 and roster()[1].id == 1, "jump stays in queue")
		first.Character.root.Position = pad.Position + Vector3.new(10, 3, 0)
		lobby.step()
		check(#roster() == 3 and roster()[1].id == 2, "boundary exit promotes remaining roster")
		first.Character.root.Position = pad.Position + Vector3.new(0, 3, 0)
		lobby.step()
		check(roster()[4].id == 1, "return joins at back")
		first.Character.humanoid.Health = 0
		-- The signal is synthetic so death timing is explicit rather than dependent on a client.
		for _, event in signals do
			if event.Event == first.Character.humanoid.Died then
				event:Fire()
			end
		end
		task.wait()
		check(
			first:GetAttribute("L3State") == "respawning" and #roster() == 3,
			"death immediately releases queue membership"
		)
		task.wait(1.1)
		check(spawns[first] == 2 and first:GetAttribute("L3State") == "lobby", "death returns to lobby without menu")
		lobby.step()
		check(#roster() == 3, "respawn is outside queue")
		removing:Fire(second)
		second.Parent = nil
		table.remove(players.list, 2)
		task.wait()
		check(#roster() == 2 and roster()[1].id == 3, "disconnect releases membership and preserves order")
		local retry = player(5)
		added:Fire(retry)
		task.wait()
		failNext = true
		request(retry)
		check(
			retry:GetAttribute("L3State") == "spawn-error" and not retry.Character,
			"failed spawn leaves retryable menu"
		)
		task.wait(1.1)
		request(retry)
		check(
			retry:GetAttribute("L3State") == "lobby" and spawns[retry] == 1,
			"retry creates exactly one successful spawn"
		)
		local departing = first.Character.humanoid.Died
		first.Character.humanoid.Health = 0
		for _, event in signals do
			if event.Event == departing then
				event:Fire()
			end
		end
		task.wait()
		lobby.stop()
		task.wait(1.1)
		check(spawns[first] == 2, "pending respawn cannot run after shutdown")
		check(
			not workspace:FindFirstChild("L3FixtureLobby")
				and not game.ReplicatedStorage:FindFirstChild("L3FixturePlay"),
			"shutdown removes owned geometry and remotes"
		)
	end)
	lobby.stop()
	for _, event in signals do
		event:Destroy()
	end
	assert(ok, "L3 lobby fixture failed: " .. tostring(failure))
	return { passed = true, checks = checks }
end
