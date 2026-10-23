local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "L1Match" then
	return
end
local Storage = game:GetService("ReplicatedStorage")
local Lives = require(game.ServerScriptService.F3Lives)
local Match = require(game.ServerScriptService.F4Match)
local Combat = require(game.ServerScriptService.F2Combat)
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "L1MatchFixture", Storage
local ready, snapshots, checks = {}, {}, {}
local connection = remote.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "snapshot" then
		snapshots[player] = data
	end
end)
local timeout = task.delay(60, function()
	Test:EndTest({ passed = false, error = "L1 match fixture timed out" })
end)
local function check(value, message)
	assert(value, "L1 match: " .. message)
	table.insert(checks, message)
end
local function waitFor(predicate, seconds, message)
	local deadline = os.clock() + seconds
	repeat
		if predicate() then
			return
		end
		task.wait()
	until os.clock() >= deadline
	assert(predicate(), "L1 match timeout: " .. message)
end
local passed, failure = pcall(function()
	waitFor(function()
		local roster = Lives.roster()
		return #roster == 2
			and ready[roster[1]]
			and ready[roster[2]]
			and roster[1]:GetAttribute("F3Status") == "waiting"
			and roster[2]:GetAttribute("F3Status") == "waiting"
	end, 30, "two staged clients")
	local roster = Lives.roster()
	local arena = workspace.SkyBridges
	local homes = {}
	for _, player in roster do
		local position = player.Character.HumanoidRootPart.Position
		homes[player] = if position.X < 0 then 1 else 2
		check(
			(position - arena["Spawn" .. homes[player]].Position).Magnitude < 1,
			player.Name .. " starts at a side-island center"
		)
	end
	check(homes[roster[1]] ~= homes[roster[2]], "players occupy opposing home islands")
	check(
		Match.chooseWeapon(roster[1], "WreckingHammer") and Match.chooseAbility(roster[1], "Bounce"),
		"first loadout selected"
	)
	check(
		Match.chooseWeapon(roster[2], "PaddlePops") and Match.chooseAbility(roster[2], "Magnet"),
		"second loadout selected"
	)
	check(Match.begin(), "normal two-player match begins")
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 6, "GO")
	for _, player in roster do
		check(
			Lives.alive(player) and not player.Character.HumanoidRootPart.Anchored,
			player.Name .. " unlocks alive at GO"
		)
	end
	for index, player in roster do
		local opponent = roster[3 - index]
		local life, score = player:GetAttribute("F3Life"), opponent:GetAttribute("F3Score")
		local position = if index == 1
			then Vector3.new(0, 16, 40)
			else Vector3.new(arena.Bridge3.Position.X, 16, arena.Bridge3.Position.Z)
		player.Character.HumanoidRootPart.CFrame = CFrame.new(position)
		Combat.resetMovement(player)
		Lives.step()
		Match.step()
		check(
			player:GetAttribute("F3Status") == "eliminated" and opponent:GetAttribute("F3Score") == score + 1,
			"void fall " .. index .. " awards exactly one opposing point"
		)
		check(not Lives.eliminate(player, life, "duplicate"), "void fall " .. index .. " cannot score twice")
		waitFor(function()
			return player:GetAttribute("F3Status") == "alive" and player:GetAttribute("F3Life") == life + 1
		end, 5, "home respawn")
		local delta = player.Character.HumanoidRootPart.Position - arena["Spawn" .. homes[player]].Position
		check(Vector3.new(delta.X, 0, delta.Z).Magnitude < 6.2, "player " .. index .. " returns to its own home island")
		check(
			player.Character:FindFirstChild("F3SpawnShield") ~= nil,
			"player " .. index .. " receives respawn protection"
		)
	end
	for _, player in roster do
		remote:FireClient(player, "snapshot")
	end
	waitFor(function()
		return snapshots[roster[1]] and snapshots[roster[2]]
	end, 4, "both client snapshots")
	local expected = Storage.F4State.Value
	for _, player in roster do
		check(snapshots[player].state == expected, player.Name .. " receives matching authoritative match state")
		check(#snapshots[player].errors == 0, player.Name .. " reports no script errors")
		check(
			snapshots[player].arena and math.abs(snapshots[player].cameraDistance - 16) < 0.1,
			player.Name .. " receives arena and retains default camera distance"
		)
	end
end)
task.cancel(timeout)
connection:Disconnect()
local clients = {}
for player, data in snapshots do
	clients[player.Name] = data
end
Test:EndTest({ passed = passed, error = if passed then nil else tostring(failure), checks = checks, clients = clients })
