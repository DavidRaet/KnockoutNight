local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F6Combat" then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Combat = require(game.ServerScriptService.F2Combat)
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local fixture = Instance.new("RemoteEvent")
fixture.Name, fixture.Parent = "F6CombatTest", Storage
local ready, snapshots, checks, launches, events, errors = {}, {}, {}, {}, {}, {}
local pickerSnapshots = {}
local errorConnection = game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		table.insert(errors, message)
	end
end)
local originalStep = Combat.step
Combat.step = function(dt)
	originalStep(dt)
	for _, player in Players:GetPlayers() do
		local c = player.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root then
			local token = root:GetAttribute("F2Displaced")
			local key = tostring(player.UserId)
				.. ":"
				.. tostring(c:GetAttribute("F2Generation"))
				.. ":"
				.. tostring(token)
			if token and not launches[key] then
				local v = root.AssemblyLinearVelocity
				launches[key] =
					{ player = player.Name, x = v.X, y = v.Y, z = v.Z, serverOwned = root:GetNetworkOwner() == nil }
			end
		end
	end
end
local connection = fixture.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "snapshot" then
		snapshots[player.Name] = data
	elseif kind == "picker-snapshot" then
		pickerSnapshots[player] = data
	end
end)
local timeout = task.delay(100, function()
	Test:EndTest({ passed = false, error = "F6 two-client fixture timed out" })
end)
local passed, failure = pcall(function()
	local function waitFor(predicate, seconds, message)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and not predicate() do
			task.wait()
		end
		assert(predicate(), "F6 wait: " .. message)
	end
	local function check(value, message)
		assert(value, "F6 combat: " .. message)
		table.insert(checks, message)
	end
	waitFor(function()
		local list = Players:GetPlayers()
		return #list == 2
			and ready[list[1]]
			and ready[list[2]]
			and list[1]:GetAttribute("F3Status") == "waiting"
			and list[2]:GetAttribute("F3Status") == "waiting"
	end, 25, "two ready staged players")
	local list = Players:GetPlayers()
	local a, b = list[1], list[2]
	check(
		not Match.chooseWeapon(a, {}) and not Match.chooseWeapon(a, "PaddlePops"),
		"invalid and unavailable weapon choices rejected"
	)
	fixture:FireClient(a, "choose-weapon", "WreckingHammer")
	waitFor(function()
		return a:GetAttribute("F2Weapon") == "WreckingHammer"
	end, 4, "client selects Hammer through real selection remote")
	task.wait(0.2)
	for _, player in list do
		fixture:FireClient(player, "picker-snapshot")
	end
	waitFor(function()
		return pickerSnapshots[a] and pickerSnapshots[b]
	end, 4, "both centered staging pickers")
	for _, player in list do
		check(
			pickerSnapshots[player].visible and pickerSnapshots[player].centered,
			"picker is visible and centered for " .. player.Name
		)
	end
	check(pickerSnapshots[a].selected == "Selected: Wrecking Hammer", "picker confirms authoritative Hammer choice")
	check(Match.begin(), "real Platform match begins")
	check(not Match.chooseWeapon(a, "SpringFist"), "countdown locks weapon changes")
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 6, "regulation GO")
	task.wait(1.5)
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
	end
	local seq = 20000
	local origin = Vector3.new(-3, 45, 0)
	local function reset(player, position)
		local c = player.Character
		Lives.endProtection(player)
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
	local function pair(offset)
		task.wait(1.6)
		local ar = reset(a, origin)
		local br = reset(b, origin + offset)
		return ar, br
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
	local ar, br = pair(Vector3.xAxis * 5)
	check(
		a.Character:GetAttribute("F2Weapon") == "WreckingHammer",
		"server choice survives match fresh-character reset"
	)
	check(press(a), "Hammer press accepted")
	check(
		math.abs(a.Character.Humanoid.WalkSpeed - 6.4) < 0.001 and a.Character.Humanoid.JumpHeight == 0,
		"40 percent movement and no jumping"
	)
	task.wait(0.3)
	check(not br:GetAttribute("F2Displaced"), "readable windup does not launch early")
	waitFor(function()
		return br:GetAttribute("F2Displaced") ~= nil
	end, 0.5, "heavy contact")
	local heavy = false
	for _, launch in launches do
		if launch.player == b.Name and launch.x == 118 and launch.y == 16 and launch.serverOwned then
			heavy = true
		end
	end
	check(heavy, "authoritative replacement launch is exactly 118 horizontal / 16 upward before physics")
	check(not press(b), "defender cannot attack during hit recovery")
	task.wait(1.7)
	check(not ar:GetAttribute("F2ActionUntil"), "Hammer action expires without auto-repeat")
	check(
		not br:GetAttribute("F2Displaced") and b.Character.Humanoid.EvaluateStateMachine,
		"displacement restores motor"
	)
	check(br:GetNetworkOwner() == b, "displacement returns client ownership")
	local oldVictim = b.Character
	check(Lives.eliminate(b, b:GetAttribute("F3Life"), "F6-attribution"), "Hammer ring-out attribution commits")
	waitFor(function()
		return b.Character ~= oldVictim and b:GetAttribute("F3Status") == "alive"
	end, 8, "victim respawn after Hammer credit")
	ar, br = pair(Vector3.xAxis * 3.5)
	check(press(a) and press(b), "mixed attacks start together")
	task.wait(0.22)
	check(not ar:GetAttribute("F2ActionUntil"), "fast Fist interrupts unarmored Hammer windup")
	task.wait(0.6)
	check(not br:GetAttribute("F2Displaced"), "interrupted Hammer never reaches its later active window")
	ar, br = pair(Vector3.xAxis * 5)
	check(press(a), "dodge scenario starts windup")
	task.wait(0.22)
	reset(b, origin - Vector3.xAxis * 3.5)
	task.wait(0.5)
	check(not br:GetAttribute("F2Displaced"), "defender leaving front during windup dodges sweep")
	reset(b, origin - Vector3.xAxis * 3.5)
	seq += 1
	check(
		Combat.request(b, "press", b.Character:GetAttribute("F2Generation"), seq, Vector3.xAxis),
		"defender punishes during Hammer recovery"
	)
	task.wait(0.16)
	check(ar:GetAttribute("F2Displaced") ~= nil, "missed Hammer is vulnerable to recovery punish")
	table.insert(events, "Server-controlled reposition demonstrates dodge/punish timing; player feel remains manual.")
	ar, br = pair(Vector3.zAxis * 15)
	fixture:FireClient(a, "press", Vector3.xAxis)
	task.wait(1.5)
	check(not ar:GetAttribute("F2ActionUntil"), "real client input remote completes Hammer action")
	ar, br = pair(Vector3.zAxis * 15)
	check(press(a), "buffer scenario starts")
	task.wait(1.21)
	check(press(a), "final 0.12-second buffer accepted")
	task.wait(0.18)
	check(ar:GetAttribute("F2ActionUntil") ~= nil, "buffer starts exactly one next Hammer action")
	local oldGen = a.Character:GetAttribute("F2Generation")
	a:SetAttribute("F2Weapon", "SpringFist")
	task.wait()
	check(not ar:GetAttribute("F2ActionUntil"), "weapon change cancels action and buffer")
	check(
		not Combat.request(a, "press", oldGen, seq + 1, Vector3.xAxis),
		"weapon change rejects stale input generation"
	)
	a:SetAttribute("F2Weapon", "WreckingHammer")
	task.wait(0.2)
	ar, br = pair(Vector3.zAxis * 15)
	check(press(a), "elimination cleanup begins with live action")
	local oldCharacter = a.Character
	local oldLife = a:GetAttribute("F3Life")
	check(Lives.eliminate(a, oldLife, "F6-test"), "elimination commits through real life owner")
	check(
		not ar:GetAttribute("F2ActionUntil") and oldCharacter:GetAttribute("F2Generation") == nil,
		"elimination retires Hammer transient state immediately"
	)
	waitFor(function()
		return a.Character ~= oldCharacter and a:GetAttribute("F3Status") == "alive"
	end, 8, "regulation respawn")
	check(a.Character:GetAttribute("F2Weapon") == "WreckingHammer", "regulation respawn preserves server weapon choice")
	for _, player in list do
		fixture:FireClient(player, "snapshot")
	end
	waitFor(function()
		return snapshots[a.Name] and snapshots[b.Name]
	end, 4, "both client snapshots")
	for name, snapshot in snapshots do
		check(not snapshot.pickerVisible, "picker stays hidden during combat for " .. name)
		check(
			#snapshot.errors == 0,
			"no project script errors (Roblox ChatScript errors reported separately): " .. name
		)
		local hammerFeed = false
		for _, event in snapshot.eliminations do
			if event.attacker == a.DisplayName and event.weapon == "Wrecking Hammer" then
				hammerFeed = true
			end
		end
		check(hammerFeed, "knockout feed credits Wrecking Hammer on " .. name)
		for _, phase in { "startup", "active", "recovery" } do
			check(
				snapshot.phases[phase] and snapshot.phases[phase].samples > 0,
				"client renders Hammer " .. phase .. ": " .. name
			)
		end
		check(snapshot.hits > 0, "client receives authoritative hit presentation: " .. name)
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
	events = events,
	errors = errors,
})
