-- Controlled client phase snapshots exercise the live controller; they do not prove multiplayer timing.
return function()
	local player = game.Players.LocalPlayer
	local snapshot = game.ReplicatedStorage.F4State
	local previous =
		{ snapshot = snapshot.Value, state = player:GetAttribute("L3State"), status = player:GetAttribute("F3Status") }
	local checks = 0
	local function capture(expected, message)
		task.wait(0.15)
		assert(game.UserInputService.MouseBehavior == expected, "Player camera phase: " .. message)
		checks += 1
	end
	local passed, failure = pcall(function()
		assert(
			player:GetAttribute("F1ShiftLock") == true,
			"Camera phase fixture requires the default shift-lock preference"
		)
		player:SetAttribute("L3State", "lobby")
		player:SetAttribute("F3Status", "lobby")
		capture(Enum.MouseBehavior.LockCenter, "lobby defaults to hands-free look")
		player:SetAttribute("L3State", "intermission")
		capture(Enum.MouseBehavior.LockCenter, "intermission retains hands-free look")
		snapshot.Value = game.HttpService:JSONEncode({
			session = 5151,
			phase = "regulation",
			startedAt = workspace:GetServerTimeNow(),
			deadline = workspace:GetServerTimeNow() + 100,
			roster = {
				{ id = player.UserId, name = player.DisplayName, score = 0 },
				{ id = -999, name = "FixtureOpponent", score = 0 },
			},
		})
		player:SetAttribute("L3State", "match")
		player:SetAttribute("F3Status", "alive")
		capture(Enum.MouseBehavior.LockCenter, "combat retains initial locked configuration")
		player:SetAttribute("L3State", "selection")
		capture(Enum.MouseBehavior.Default, "selection releases cursor even with stale active-combat snapshot")
		player:SetAttribute("L3State", "menu")
		capture(Enum.MouseBehavior.Default, "menu releases cursor even with stale active-combat snapshot")
		player:SetAttribute("L3State", "match")
		local state = game.HttpService:JSONDecode(snapshot.Value)
		state.phase = "countdown"
		state.goAt = workspace:GetServerTimeNow() + 3
		snapshot.Value = game.HttpService:JSONEncode(state)
		capture(Enum.MouseBehavior.Default, "opening countdown releases cursor")
		state.phase = "results"
		snapshot.Value = game.HttpService:JSONEncode(state)
		capture(Enum.MouseBehavior.Default, "results release cursor")
	end)
	snapshot.Value = previous.snapshot
	player:SetAttribute("L3State", previous.state)
	player:SetAttribute("F3Status", previous.status)
	assert(passed, "Player camera phase fixture failed: " .. tostring(failure))
	return { passed = true, checks = checks }
end
