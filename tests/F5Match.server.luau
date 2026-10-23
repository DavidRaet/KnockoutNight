local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F5Match" then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local Combat = require(game.ServerScriptService.F2Combat)
local fixture = Instance.new("RemoteEvent")
fixture.Name, fixture.Parent = "F5MatchTest", Storage
local ready, snapshots, checks = {}, {}, {}
local timeout = task.delay(70, function()
	Test:EndTest({ passed = false, error = "F5 fixture timed out" })
end)
fixture.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "snapshot" then
		snapshots[player.Name] = data
	end
end)
local passed, failure = pcall(function()
	local function check(value, message)
		assert(value, "F5 engine: " .. message)
		table.insert(checks, message)
	end
	local function waitFor(condition, seconds, message)
		local untilAt = os.clock() + seconds
		repeat
			if condition() then
				return
			end
			task.wait()
		until os.clock() >= untilAt
		assert(condition(), "F5 timeout: " .. message)
	end
	local function state()
		return game:GetService("HttpService"):JSONDecode(Storage.F4State.Value)
	end
	waitFor(function()
		local list = Lives.roster()
		return #list == 2 and ready[list[1]] and ready[list[2]]
	end, 25, "two clients")
	local list = Lives.roster()
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
	end
	if args.weapon == "WreckingHammer" or args.weapon == "PaddlePops" then
		for _, player in list do
			player:SetAttribute("F2Weapon", args.weapon)
		end
	end
	check(Match.begin(), "start regulation")
	local function phase(name)
		waitFor(function()
			return state().phase == name
		end, 8, name)
	end
	local function agree(tag)
		local expected = Storage.F4State.Value
		for _, player in list do
			if player.Parent == Players then
				fixture:FireClient(player, tag, expected)
			end
		end
		waitFor(function()
			for _, player in list do
				if player.Parent == Players and (not snapshots[player.Name] or snapshots[player.Name].tag ~= tag) then
					return false
				end
			end
			return true
		end, 4, "client snapshot")
		for _, player in list do
			if player.Parent == Players then
				local data = snapshots[player.Name]
				check(
					data.snapshot == expected and #data.errors == 0 and not data.hudOverlap,
					"client agrees without project errors / " .. tag .. " / " .. player.Name
				)
			end
		end
	end
	local frames, lives, generations = {}, {}, {}
	for side, player in list do
		frames[side] = player.Character.HumanoidRootPart.CFrame
		lives[side] = player:GetAttribute("F3Life")
		generations[side] = player.Character:GetAttribute("F2Generation")
	end
	phase("regulation")
	for side, player in list do
		check(Lives.eliminate(player, lives[side], "fixture"), "pending regulation respawn / " .. side)
	end
	phase("sudden-death-countdown")
	for round = 1, 3 do
		for side, player in list do
			local char, root = player.Character, player.Character.HumanoidRootPart
			check(player:GetAttribute("F3Life") > lives[side], "fresh life identity / " .. round .. "/" .. side)
			check(
				root.Anchored and (root.Position - frames[side].Position).Magnitude < 0.1,
				"mirrored initial spawn frozen / " .. round .. "/" .. side
			)
			check(
				root.AssemblyLinearVelocity.Magnitude < 0.01 and root.AssemblyAngularVelocity.Magnitude < 0.01,
				"old motion cleared"
			)
			check(
				player:GetAttribute("F3RespawnAt") == nil
					and char:GetAttribute("F3ProtectionUntil") == 0
					and not char:FindFirstChild("F3SpawnShield"),
				"old timer/protection cleared"
			)
			check(
				not root:GetAttribute("F2ActionUntil") and not root:GetAttribute("F2Displaced"),
				"old action/effects cleared"
			)
			if args.weapon then
				check(char:GetAttribute("F2Weapon") == args.weapon, "sudden death preserves chosen weapon")
				if args.weapon == "PaddlePops" then
					check(char:GetAttribute("F7NextHand") == "Right", "sudden death resets Paddle starting hand")
				end
			end
			check(
				not Combat.request(player, "press", generations[side], 999, Vector3.xAxis),
				"old request rejected during countdown"
			)
			check(not Lives.eliminate(player, lives[side], "stale"), "old life callback rejected")
			check(
				not Combat.request(player, "press", char:GetAttribute("F2Generation"), 998, Vector3.xAxis),
				"fresh request also blocked during countdown"
			)
		end
		check(state().roster[1].score == 1 and state().roster[2].score == 1, "tied score preserved")
		agree("countdown-" .. round)
		for _, player in list do
			local data = snapshots[player.Name]
			check(#data.eliminations == round + 1, "each mutual emits exactly one event on each client")
			if round > 1 then
				check(data.eliminations[#data.eliminations].system ~= nil, "mutual feed is a neutral system entry")
			end
		end
		if args.scenario == "countdown-departure" then
			list[2]:Kick("F5 countdown forfeit")
			phase("results")
			check(
				state().result.outcome == "forfeit" and state().result.winner == 1,
				"countdown disconnect awards forfeit"
			)
			return agree("forfeit-countdown")
		end
		phase("sudden-death")
		for side, player in list do
			lives[side], generations[side] =
				player:GetAttribute("F3Life"), player.Character:GetAttribute("F2Generation")
			check(
				not player.Character.HumanoidRootPart.Anchored and player.Character.Humanoid.WalkSpeed == 16,
				"GO unlocks movement"
			)
			check(
				Combat.request(player, "press", generations[side], round, Vector3.xAxis),
				"fresh combat ready after GO"
			)
		end
		local first = if round % 2 == 1 then 1 else 2
		check(Lives.eliminate(list[first], lives[first], "fixture"), "first sudden death commitment")
		check(
			not Combat.request(list[first], "press", generations[first], 100, Vector3.xAxis),
			"committed attacker cannot attack"
		)
		check(not Lives.eliminate(list[first], lives[first], "duplicate"), "duplicate commitment rejected")
		if args.scenario == "window-departure" then
			-- Kick delivery is asynchronous and can exceed the entire decision window.
			list[3 - first]:Destroy()
			phase("results")
			check(
				state().result.outcome == "forfeit" and state().result.winner == first,
				"already eliminated connected player wins by forfeit"
			)
			return agree("forfeit-window")
		end
		if round < 3 then
			check(Lives.eliminate(list[3 - first], lives[3 - first], "fixture"), "opposing same-update commitment")
			phase("sudden-death-countdown")
		else
			phase("results")
			local result = state().result
			check(
				result.outcome == "sudden-death"
					and result.winner == 3 - first
					and result.scores[1] == 1
					and result.scores[2] == 1,
				"decisive result preserves regulation tie"
			)
			agree("decisive")
			for _, player in list do
				local data = snapshots[player.Name]
				check(
					#data.eliminations == 5 and not data.eliminations[5].system and not data.respawnVisible,
					"one attributed decisive feed; no ordinary respawn promise"
				)
			end
		end
	end
end)
task.cancel(timeout)
Test:EndTest({
	passed = passed,
	error = if passed then nil else tostring(failure),
	checks = checks,
	snapshots = snapshots,
	version = "F5",
	scenario = args.scenario or "rounds",
})
