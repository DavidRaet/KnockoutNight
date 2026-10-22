local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F4Match" then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local Combat = require(game.ServerScriptService.F2Combat)
local fixture = Instance.new("RemoteEvent")
fixture.Name, fixture.Parent = "F4MatchTest", Storage
local ready, snapshots, checks = {}, {}, {}
local timeout = task.delay(90, function()
	Test:EndTest({ passed = false, error = "F4 fixture timed out" })
end)
local connection = fixture.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "snapshot" then
		snapshots[player] = data
	end
end)
local passed, failure = pcall(function()
	local function check(condition, message)
		assert(condition, "F4 match: " .. message)
		table.insert(checks, message)
	end
	local function waitFor(condition, seconds, message)
		local deadline = os.clock() + seconds
		repeat
			if condition() then
				return
			end
			task.wait()
		until os.clock() >= deadline
		assert(condition(), "F4 timeout: " .. message)
	end
	local function state()
		return Http:JSONDecode(Storage.F4State.Value)
	end
	waitFor(function()
		local list = Lives.roster()
		return #list == 2
			and ready[list[1]]
			and ready[list[2]]
			and list[1]:GetAttribute("F3Status") == "waiting"
			and list[2]:GetAttribute("F3Status") == "waiting"
	end, 25, "two clients ready")
	local list = Lives.roster()
	local a, b = list[1], list[2]
	check(Match.begin(), "developer starts from two admitted staged players")
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
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
				if player.Parent == Players and (not snapshots[player] or snapshots[player].tag ~= tag) then
					return false
				end
			end
			return true
		end, 4, "replicated snapshot")
		for _, player in list do
			if player.Parent == Players then
				check(
					snapshots[player].snapshot == expected
						and #snapshots[player].errors == 0
						and not snapshots[player].hudOverlap,
					"client agrees on complete snapshot without script errors: " .. player.Name .. " / " .. tag
				)
			end
		end
	end
	if args.scenario == "cancel" then
		check(state().phase == "countdown", "departure fixture begins before GO")
		b:Kick("F4 pre-GO cancellation")
		waitFor(function()
			return state().phase == "results"
		end, 3, "cancelled countdown")
		check(
			state().result.outcome == "cancelled" and not state().result.winner and not state().deadline,
			"real pre-GO disconnect cancels with no winner"
		)
		agree("cancelled")
		return
	end
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 6, "GO")
	check(
		not a.Character.HumanoidRootPart.Anchored and a.Character.Humanoid.WalkSpeed == 16,
		"GO releases server movement"
	)
	Lives.add(a, CFrame.new())
	check(a:GetAttribute("F3Status") == "alive", "duplicate admission cannot reset an active player")
	check(
		state().deadline - state().startedAt == require(Storage.F4Config).RegulationDuration,
		"GO starts full configured regulation timer"
	)
	if args.scenario == "forfeit" or args.scenario == "empty" then
		local before = state()
		b:Kick("F4 active departure")
		if args.scenario == "empty" then
			a:Kick("F4 same-update second departure")
		end
		waitFor(function()
			return state().result ~= nil
		end, 3, "departure result")
		local result = state().result
		check(
			result.outcome == (if args.scenario == "empty" then "abandoned" else "forfeit"),
			"real departure produces expected terminal outcome"
		)
		check(
			result.winner == (if args.scenario == "empty" then nil else 1),
			"real departure chooses remaining side or no winner"
		)
		check(
			result.scores[1] == before.roster[1].score and result.scores[2] == before.roster[2].score,
			"disconnect does not generate a fall point"
		)
		if args.scenario ~= "empty" then
			agree("forfeit")
		end
		return
	end
	local oldSession, oldLife, oldGeneration
	for round = 1, 2 do
		local current = state()
		oldSession, oldLife, oldGeneration =
			current.session, a:GetAttribute("F3Life"), a.Character:GetAttribute("F2Generation")
		check(Lives.eliminate(a, oldLife, "fixture", oldSession), "current regulation life commits")
		check(not Lives.eliminate(a, oldLife, "duplicate", oldSession), "duplicate life callback rejected")
		waitFor(function()
			return state().roster[2].score == 1
		end, 2, "committed score")
		agree("score-" .. round)
		waitFor(function()
			return state().phase == "results"
		end, 15, "regulation expiry")
		current = state()
		check(
			current.result.winner == 2 and current.result.outcome == "normal" and current.result.scores[2] == 1,
			"regulation resolves authoritative winner and score"
		)
		check(
			a.Character.HumanoidRootPart.Anchored and b.Character.HumanoidRootPart.Anchored,
			"expiry freezes both characters"
		)
		check(
			not Combat.request(b, "press", b.Character:GetAttribute("F2Generation"), 999, Vector3.xAxis),
			"server rejects request received after deadline"
		)
		check(
			not Lives.eliminate(b, b:GetAttribute("F3Life"), "too-late", oldSession),
			"late elimination cannot change result"
		)
		agree("results-" .. round)
		check(
			snapshots[a].resultsVisible and snapshots[b].resultsVisible and snapshots[a].results == snapshots[b].results,
			"both clients render the same result"
		)
		check(
			not snapshots[a].respawnVisible and not snapshots[b].respawnVisible,
			"terminal result hides ordinary respawn promises"
		)
		if round == 1 then
			check(not Match.returnToStaging(a, oldSession - 1), "stale return request rejected")
			check(Match.returnToStaging(a, oldSession), "immediate return accepted")
			check(not Match.returnToStaging(a, oldSession), "duplicate return is harmless")
		end
		waitFor(function()
			return state().phase == "staging"
		end, 10, "automatic return")
		check(
			a:GetAttribute("F3Status") == "waiting" and b:GetAttribute("F3Status") == "waiting",
			"results return to local staging"
		)
		check(Match.begin(), "developer starts a fresh repeated session")
		check(
			not Lives.eliminate(a, oldLife, "stale-session", oldSession),
			"old session callback cannot eliminate fresh character"
		)
		check(
			not Combat.request(a, "press", oldGeneration, 1000, Vector3.xAxis),
			"old character request rejected in next countdown"
		)
		check(state().roster[1].score == 0 and state().roster[2].score == 0, "repeated session clears scores")
		check(
			a.Character.HumanoidRootPart.Anchored
				and not Combat.request(a, "press", a.Character:GetAttribute("F2Generation"), 1001, Vector3.xAxis),
			"countdown locks movement and combat"
		)
		waitFor(function()
			return Match.allowed(workspace:GetServerTimeNow())
		end, 6, "repeated GO")
		check(
			not Combat.request(a, "press", oldGeneration, 1002, Vector3.xAxis),
			"stale generation stays rejected after GO"
		)
	end
	waitFor(function()
		return state().phase == "sudden-death-countdown"
	end, 15, "tied regulation reset countdown")
	check(
		not state().result and state().roster[1].score == 0 and state().roster[2].score == 0,
		"tie resets for F5 without inventing result"
	)
	check(
		a.Character.HumanoidRootPart.Anchored and not Match.allowed(workspace:GetServerTimeNow()),
		"F5 reset countdown is frozen"
	)
	agree("tie")
	check(string.find(snapshots[a].timer, "SUDDEN DEATH", 1, true) ~= nil, "client explains sudden-death handoff")
end)
task.cancel(timeout)
connection:Disconnect()
local observed = {}
for player, data in snapshots do
	observed[player.Name] = data
end
Test:EndTest({
	passed = passed,
	error = if passed then nil else tostring(failure),
	checks = checks,
	snapshots = observed,
	version = "F4",
	scenario = args.scenario or "regulation",
})
