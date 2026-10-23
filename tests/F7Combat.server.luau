local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F7Combat" then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Combat = require(game.ServerScriptService.F2Combat)
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local fixture = Instance.new("RemoteEvent")
fixture.Name, fixture.Parent = "F7CombatTest", Storage
local ready, snapshots, checks, launches, errors = {}, {}, {}, {}, {}
local originalStep = Combat.step
Combat.step = function(dt)
	originalStep(dt)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:GetAttribute("F2Displaced") then
			local v = root.AssemblyLinearVelocity
			if v.X == 30 and v.Y == 8 then
				table.insert(launches, { x = v.X, y = v.Y, z = v.Z, serverOwned = root:GetNetworkOwner() == nil })
			end
		end
	end
end
local errorConnection = game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		table.insert(errors, message)
	end
end)
local connection = fixture.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "snapshot" then
		snapshots[player.Name] = data
	end
end)
local timeout = task.delay(100, function()
	Test:EndTest({ passed = false, error = "F7 two-client fixture timed out" })
end)
local passed, failure = pcall(function()
	for _, name in { "F7ContactSpec", "F6ContactSpec", "F2ContactSpec" } do
		local result = require(game.ServerScriptService[name])()
		assert(result.passed, "F7 fixture requires passing geometry: " .. name)
		table.insert(checks, name .. ": " .. result.checks .. " geometry checks passed")
	end
	local function waitFor(predicate, seconds, message)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and not predicate() do
			task.wait()
		end
		assert(predicate(), "F7 wait: " .. message)
	end
	local function check(value, message)
		assert(value, "F7 combat: " .. message)
		table.insert(checks, message)
	end
	waitFor(function()
		local list = Lives.roster()
		return #list == 2 and ready[list[1]] and ready[list[2]]
	end, 25, "two ready staged players")
	local list = Lives.roster()
	local a, b = list[1], list[2]
	check(not Match.chooseWeapon(a, {}) and not Match.chooseWeapon(a, "UnknownWeapon"), "invalid choices rejected")
	fixture:FireClient(a, "choose-weapon", "PaddlePops")
	waitFor(function()
		return a:GetAttribute("F2Weapon") == "PaddlePops"
	end, 4, "real selection remote accepts Paddle Pops")
	check(Match.chooseWeapon(b, "WreckingHammer"), "opponent selects Hammer")
	for _, player in list do
		fixture:FireClient(player, "snapshot")
	end
	waitFor(function()
		return snapshots[a.Name] and snapshots[b.Name]
	end, 4, "staging picker snapshots")
	for _, player in list do
		check(
			snapshots[player.Name].pickerVisible and snapshots[player.Name].hasPaddles,
			"three-choice picker visible: " .. player.Name
		)
	end
	check(snapshots[a.Name].selected == "Selected: Paddle Pops", "picker confirms authoritative choice")
	check(Match.begin(), "Platform match starts")
	check(not Match.chooseWeapon(a, "SpringFist"), "countdown locks weapon selection")
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 7, "regulation GO")
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
	end
	local seq, origin = 20000, Vector3.new(-3, 45, 0)
	local function reset(player, position, shield)
		local c = player.Character
		if not shield then
			Lives.endProtection(player)
		end
		c:SetAttribute("F2Equipped", false)
		c:SetAttribute("F2Equipped", true)
		local root = c.HumanoidRootPart
		root:SetNetworkOwner(nil)
		root.CFrame = CFrame.lookAt(position, position + (if player == a then Vector3.xAxis else -Vector3.xAxis))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		c.Humanoid:Move(Vector3.zero, false)
		Combat.resetMovement(player)
		return root
	end
	local function pair(distance)
		task.wait(1.6)
		return reset(a, origin), reset(b, origin + Vector3.xAxis * distance)
	end
	local function press(player)
		seq += 1
		return Combat.request(
			player,
			"press",
			player.Character:GetAttribute("F2Generation"),
			seq,
			if player == a then Vector3.xAxis else -Vector3.xAxis
		)
	end
	local ar, br = pair(18)
	check(
		a.Character:GetAttribute("F2Weapon") == "PaddlePops" and a.Character:GetAttribute("F7NextHand") == "Right",
		"fresh match preserves weapon and starts right"
	)
	check(a.Character.Humanoid.WalkSpeed == 16, "Paddles retain ordinary base speed")
	check(press(a), "first Paddle activation accepted")
	check(a.Character:GetAttribute("F7NextHand") == "Left", "accepted right slap advances hand")
	check(
		math.abs(a.Character.Humanoid.WalkSpeed - 13.6) < 0.001 and a.Character.Humanoid.JumpHeight == 0,
		"85 percent attack movement and no jump"
	)
	check(not press(a) and a.Character:GetAttribute("F7NextHand") == "Left", "rejected input does not advance hand")
	task.wait(0.38)
	check(
		not ar:GetAttribute("F2ActionUntil") and a.Character:GetAttribute("F7NextHand") == "Left",
		"miss completes once and preserves next hand"
	)
	check(press(a) and a.Character:GetAttribute("F7NextHand") == "Right", "second activation uses left")
	task.wait(0.38)
	check(press(a), "third activation begins")
	task.wait(0.24)
	check(press(a) and a.Character:GetAttribute("F7NextHand") == "Left", "buffer queues without consuming hand")
	waitFor(function()
		return a.Character:GetAttribute("F7NextHand") == "Right"
	end, 0.3, "buffered left slap starts")
	task.wait(0.4)
	check(not ar:GetAttribute("F2ActionUntil"), "buffer produces exactly one extra slap")
	check(press(a), "weapon cleanup scenario starts")
	local oldGen = a.Character:GetAttribute("F2Generation")
	a:SetAttribute("F2Weapon", "SpringFist")
	task.wait()
	check(not ar:GetAttribute("F2ActionUntil"), "weapon change clears Paddle action")
	check(not Combat.request(a, "press", oldGen, seq + 1, Vector3.xAxis), "stale generation rejected")
	a:SetAttribute("F2Weapon", "PaddlePops")
	task.wait(0.2)
	check(a.Character:GetAttribute("F7NextHand") == "Right", "weapon re-equip resets right")
	ar, br = pair(18)
	fixture:FireClient(a, "press", Vector3.xAxis)
	waitFor(function()
		return a.Character:GetAttribute("F7NextHand") == "Left"
	end, 2, "real client input starts right slap")
	ar, br = pair(3)
	check(press(b) and press(a), "Paddles versus Hammer startup begins")
	waitFor(function()
		return br:GetAttribute("F2Displaced") ~= nil
	end, 0.5, "short-range Paddle contact")
	check(#launches > 0 and launches[#launches].serverOwned, "server-owned replacement launch is exactly 30/8")
	check(not br:GetAttribute("F2ActionUntil"), "Paddle hit interrupts unarmored Hammer startup")
	check(not press(b), "victim cannot attack during hit reaction")
	waitFor(function()
		return not br:GetAttribute("F2Displaced")
			and workspace:GetServerTimeNow() >= (br:GetAttribute("F2ReactionUntil") or 0)
	end, 0.32, "defender recovers before displacement protection expires")
	check(
		workspace:GetServerTimeNow() < br:GetAttribute("F2ProtectionUntil") and press(b),
		"defender can start a response while displacement protection is still active"
	)
	task.wait(1.6)
	check(
		not br:GetAttribute("F2Displaced") and b.Character.Humanoid.EvaluateStateMachine,
		"low launch restores motor and ends displacement"
	)
	check(br:GetNetworkOwner() == b, "low launch returns network ownership")
	check(press(b), "defender can respond after launch recovery")
	local old = b.Character
	check(Lives.eliminate(b, b:GetAttribute("F3Life"), "F7-attribution"), "Paddle ring-out credit commits")
	waitFor(function()
		return b.Character ~= old and b:GetAttribute("F3Status") == "alive"
	end, 8, "regulation respawn")
	ar, br = reset(a, origin), reset(b, origin + Vector3.xAxis * 3, true)
	local untilAt = Lives.protectionUntil(b)
	check(untilAt > workspace:GetServerTimeNow(), "fresh victim has spawn shield")
	check(press(a), "Paddle contact against shield begins")
	task.wait(0.25)
	check(
		not br:GetAttribute("F2Displaced") and Lives.protectionUntil(b) == untilAt,
		"protected contact causes no displacement or protection extension"
	)
	check(a.Character:GetAttribute("F7NextHand") == "Left", "protected slap still consumes right hand")
	ar, br = pair(3)
	a:SetAttribute("F2Weapon", "PaddlePops")
	b:SetAttribute("F2Weapon", "SpringFist")
	task.wait(0.2)
	check(press(a) and press(b), "mixed fast startup begins")
	waitFor(function()
		return ar:GetAttribute("F2Displaced") ~= nil
	end, 0.5, "Fist interrupts Paddles")
	check(not ar:GetAttribute("F2ActionUntil"), "Paddles have no startup armor")
	check(a.Character:GetAttribute("F7NextHand") == "Left", "interrupted startup still consumes hand")
	ar, br = pair(18)
	check(press(a), "elimination cleanup starts with Paddle action")
	old = a.Character
	check(Lives.eliminate(a, a:GetAttribute("F3Life"), "F7-cleanup"), "Paddle owner elimination commits")
	check(
		not ar:GetAttribute("F2ActionUntil") and old:GetAttribute("F7NextHand") == nil,
		"elimination retires Paddle transient state"
	)
	waitFor(function()
		return a.Character ~= old and a:GetAttribute("F3Status") == "alive"
	end, 8, "Paddle owner respawns")
	check(
		a.Character:GetAttribute("F2Weapon") == "PaddlePops" and a.Character:GetAttribute("F7NextHand") == "Right",
		"respawn preserves weapon and resets right"
	)
	snapshots = {}
	for _, player in list do
		fixture:FireClient(player, "snapshot")
	end
	waitFor(function()
		return snapshots[a.Name] and snapshots[b.Name]
	end, 4, "final client snapshots")
	for name, snapshot in snapshots do
		check(#snapshot.errors == 0, "no project client errors: " .. name)
		check(not snapshot.pickerVisible, "picker hides during match: " .. name)
		check(snapshot.hands.Right and snapshot.hands.Left, "client observes both authoritative hands: " .. name)
		check(snapshot.visualHands.Left and snapshot.visualHands.Right, "client renders both foam paddles: " .. name)
		check(
			snapshot.shields > 0 and snapshot.shieldVisual,
			"protected contact cue reaches and renders on client: " .. name
		)
		local credited = false
		for _, event in snapshot.eliminations do
			credited = credited or event.weapon == "Paddle Pops"
		end
		check(credited, "feed credits Paddle Pops: " .. name)
	end
	check(#errors == 0, "no server script errors")
end)
task.cancel(timeout)
connection:Disconnect()
errorConnection:Disconnect()
Combat.step = originalStep
fixture:Destroy()
Test:EndTest({
	passed = passed,
	error = if passed then nil else tostring(failure),
	checks = checks,
	snapshots = snapshots,
	launches = launches,
	errors = errors,
})
