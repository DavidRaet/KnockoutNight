return function(Harness)
	local checks, events = 0, {}
	local function check(value, message)
		assert(value, "L4 lobby: " .. message)
		checks += 1
	end
	local function signal()
		local callbacks = {}
		local event = { Event = {} }
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
	local added, removed, play, returnEvent, heartbeat = signal(), signal(), signal(), signal(), signal()
	local players = {
		PlayerAdded = added.Event,
		PlayerRemoving = removed.Event,
		Play = play,
		Return = returnEvent,
		RunService = { Heartbeat = heartbeat.Event },
		Now = 0,
		list = {},
	}
	function players:GetPlayers()
		return table.clone(self.list)
	end
	for id = 1, 4 do
		local attrs = {}
		local player = { Name = "L4Tester" .. id, UserId = id, Parent = players, CharacterRemoving = signal().Event }
		function player:SetAttribute(key, value)
			attrs[key] = value
		end
		function player:GetAttribute(key)
			return attrs[key]
		end
		table.insert(players.list, player)
	end
	local lobby = Harness(players)
	local function createCharacter(player, frame)
		local died = signal()
		events[player] = died
		local root = { Position = frame.Position }
		local humanoid = { Health = 100, Died = died.Event }
		local character = {}
		function character:SetAttribute() end
		function character:FindFirstChild()
			return root
		end
		function character:FindFirstChildOfClass()
			return humanoid
		end
		function character:PivotTo(nextFrame)
			root.Position = nextFrame.Position
		end
		player.Character = character
		return character
	end
	local ok, failure = pcall(function()
		lobby.start(createCharacter)
		local first, second, third, fourth = table.unpack(players.list)
		local pad = workspace.L4FixtureLobby.Queue1v1
		local function data()
			return game.HttpService:JSONDecode(game.ReplicatedStorage.L4FixtureState.Value)
		end
		local function queue()
			return game.HttpService:JSONDecode(game.ReplicatedStorage.L4FixtureQueue.Value)
		end
		for _, player in players.list do
			play:Fire(player)
			player.Character:FindFirstChild().Position = pad.Position + Vector3.new(0, 3, 0)
		end
		lobby.step()
		check(data().deadline == 3 and #queue() == 4, "full FIFO starts three-second countdown")
		players.Now = 3
		first.Character:FindFirstChild().Position += Vector3.new(20, 0, 0)
		lobby.step()
		check(
			not data().busy and data().deadline == 6 and queue()[1].id == 2,
			"expiry departure cancels and preserves order"
		)
		players.Now = 6
		lobby.step()
		local id = data().session
		check(
			data().busy
				and second:GetAttribute("L3State") == "intermission"
				and third:GetAttribute("L3State") == "intermission",
			"pair enters intermission"
		)
		check(#queue() == 1 and queue()[1].id == 4, "extra entrant waits")
		check(second:GetAttribute("F3Status") == "lobby", "intermission never enters arena lives")
		lobby.step()
		check(data().session == id and #queue() == 1, "no duplicate assignment")
		returnEvent:Fire(fourth, id)
		returnEvent:Fire(second, id - 1)
		check(data().busy, "nonparticipant and stale return rejected")
		returnEvent:Fire(second, id)
		check(
			not data().busy and second:GetAttribute("L3State") == "lobby" and third:GetAttribute("L3State") == "lobby",
			"return restores both without result"
		)
		lobby.step()
		check(#queue() == 1 and queue()[1].id == 4, "returned participants do not automatically requeue")
		second.Character:FindFirstChild().Position = pad.Position + Vector3.new(0, 3, 0)
		lobby.step()
		players.Now = 9
		lobby.step()
		check(data().busy and data().session == id + 1, "allocation reuses with new identity")
		returnEvent:Fire(second, id)
		check(data().busy, "previous session return cannot cancel reused session")
		events[second]:Fire()
		check(
			not data().busy and fourth:GetAttribute("L3State") == "lobby",
			"pre-GO death cancels and returns survivor"
		)
		for _, player in { second, third } do
			player.Character:FindFirstChild().Position = pad.Position + Vector3.new(0, 3, 0)
		end
		lobby.step()
		players.Now = 12
		lobby.step()
		removed:Fire(second)
		second.Parent = nil
		check(not data().busy and third:GetAttribute("L3State") == "lobby", "disconnect cancels and restores survivor")
	end)
	lobby.stop()
	check(
		not workspace:FindFirstChild("L4FixtureLobby") and not game.ReplicatedStorage:FindFirstChild("L4FixtureState"),
		"shutdown removes session resources"
	)
	assert(ok, "L4 lobby fixture failed: " .. tostring(failure))
	return { passed = true, checks = checks }
end
