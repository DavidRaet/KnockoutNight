local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F2Combat" then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Combat = require(game.ServerScriptService.F2Combat)
local fixture = Instance.new("RemoteEvent")
fixture.Name = "F2CombatTest"
fixture.Parent = Storage
local ready, pings, snapshots = {}, {}, {}
local rtt = {}
local rttSamples = {}
local networkRestored = {}
local checks = {}
local launchSamples = {}
local observed = {}
local sampleConnection = game:GetService("RunService").PreSimulation:Connect(function()
	if #launchSamples >= 30 then
		return
	end
	for _, player in Players:GetPlayers() do
		local c = player.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root and (root:GetAttribute("F2Displaced") or observed[player]) then
			observed[player] = true
			local v = root.AssemblyLinearVelocity
			table.insert(launchSamples, {
				player = player.Name,
				position = { root.Position.X, root.Position.Y, root.Position.Z },
				velocity = { v.X, v.Y, v.Z },
				motor = c.Humanoid.EvaluateStateMachine,
				owner = if root:GetNetworkOwner() then root:GetNetworkOwner().Name else "server",
				displaced = root:GetAttribute("F2Displaced"),
			})
		end
	end
end)
local timeout = task.delay(90, function()
	Test:EndTest({ passed = false, error = "F2 combat timeout" })
end)
local connection = fixture.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "pong" and pings[player] and pings[player].id == data then
		rtt[player.Name] = (os.clock() - pings[player].sent) * 1000
		rttSamples[player.Name] = rttSamples[player.Name] or {}
		table.insert(rttSamples[player.Name], rtt[player.Name])
	elseif kind == "snapshot" then
		snapshots[player.Name] = data
	elseif kind == "network-restored" then
		networkRestored[player.Name] = data
	end
end)
local passed, failure = pcall(function()
	local deadline = os.clock() + 20
	while os.clock() < deadline do
		local list = Players:GetPlayers()
		if
			#list == 2
			and ready[list[1]]
			and ready[list[2]]
			and list[1].Character
			and list[2].Character
			and list[1].Character:GetAttribute("F2Generation")
			and list[2].Character:GetAttribute("F2Generation")
			and list[1]:GetAttribute("F3Status") == "waiting"
			and list[2]:GetAttribute("F3Status") == "waiting"
		then
			break
		end
		task.wait(0.1)
	end
	local list = Players:GetPlayers()
	assert(#list == 2 and ready[list[1]] and ready[list[2]], "F2 combat requires two ready clients")
	local Match = require(game.ServerScriptService.F4Match)
	assert(Match.begin(), "F2 verification starts the staged two-player match")
	if args.waitNetwork then
		workspace:SetAttribute("F2CombatWaitingForNetwork", true)
		local networkDeadline = os.clock() + 55
		while os.clock() < networkDeadline and workspace:GetAttribute("F2CombatNetworkReady") ~= true do
			task.wait(0.1)
		end
		assert(workspace:GetAttribute("F2CombatNetworkReady") == true, "F2 combat network barrier timed out")
	end
	local goDeadline = os.clock() + 6
	while os.clock() < goDeadline and not Match.allowed(workspace:GetServerTimeNow()) do
		task.wait(0.1)
	end
	assert(Match.allowed(workspace:GetServerTimeNow()), "F2 verification reaches GO")
	task.wait(1.5)
	local a, b = list[1], list[2]
	local function check(value, message)
		assert(value, "F2 combat: " .. message)
		table.insert(checks, message)
	end
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
		pings[player] = { id = 1, sent = os.clock() }
		fixture:FireClient(player, "ping", 1)
	end
	task.wait(0.3)
	local function reset(player, position, aim)
		local c = player.Character
		c:SetAttribute("F2Equipped", false)
		c:SetAttribute("F2Equipped", true)
		local root = c.HumanoidRootPart
		root:SetNetworkOwner(nil)
		root.CFrame = CFrame.lookAt(position, position + aim)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		c.Humanoid:Move(Vector3.zero, false)
		Combat.resetMovement(player)
		return root, c:GetAttribute("F2Generation")
	end
	local origin = Vector3.new(-3, 45, 0)
	local seq = 10000
	local function press(player, aim)
		seq += 1
		return Combat.request(player, "press", player.Character:GetAttribute("F2Generation"), seq, aim)
	end
	local ar, gen = reset(a, origin, Vector3.xAxis)
	local br = reset(b, origin + Vector3.xAxis * 3.5, -Vector3.xAxis)
	check(not Combat.request(a, "press", gen - 1, seq, Vector3.xAxis), "stale generation rejected")
	check(not Combat.request(a, "press", gen, seq, Vector3.new(0 / 0, 0, 0)), "nonfinite aim rejected")
	check(not Combat.request(a, "press", gen, seq, Vector3.zero), "zero aim rejected")
	check(not Combat.request(a, "press", gen, seq, Vector3.yAxis), "vertical aim rejected")
	check(press(a, Vector3.xAxis), "valid press accepted")
	check(not Combat.request(a, "press", gen, seq, Vector3.xAxis), "duplicate sequence rejected")
	check(
		math.abs(a.Character.Humanoid.WalkSpeed - 11.2) < 0.001 and a.Character.Humanoid.JumpHeight == 0,
		"attack movement and jump restrictions"
	)
	local deadlineHit = os.clock() + 0.35
	while os.clock() < deadlineHit and not br:GetAttribute("F2Displaced") do
		task.wait()
	end
	check(br:GetAttribute("F2Displaced") ~= nil, "authoritative body contact launches victim")
	check(br:GetNetworkOwner() == nil, "server owns victim before launch")
	check(
		launchSamples[1] and launchSamples[1].velocity[1] == 50 and launchSamples[1].velocity[2] == 12,
		"replacement launch follows committed aim before physical collision response"
	)
	check(
		(br:GetAttribute("F2ProtectionUntil") or 0) > (br:GetAttribute("F2ReactionUntil") or 0),
		"protection and reaction have independent deadlines"
	)
	check(not press(b, -Vector3.xAxis), "hit recovery rejects attacks")
	task.wait(0.7)
	check(br.Position.X > origin.X + 5.5, "launch produces observed horizontal displacement: " .. tostring(br.Position))
	check(
		not br:GetAttribute("F2Displaced") and b.Character.Humanoid.EvaluateStateMachine,
		"natural recovery restores motor"
	)
	check(br:GetNetworkOwner() == b, "natural recovery returns player ownership")
	check(not ar:GetAttribute("F2ActionUntil"), "holding without a new press does not repeat")
	ar, gen = reset(a, origin, Vector3.xAxis)
	br = reset(b, origin + Vector3.xAxis * 3.5, -Vector3.xAxis)
	check(press(a, Vector3.xAxis) and press(b, -Vector3.xAxis), "both active requests accepted")
	task.wait(0.2)
	check(
		ar:GetAttribute("F2ProtectionUntil") > workspace:GetServerTimeNow()
			and br:GetAttribute("F2ProtectionUntil") > workspace:GetServerTimeNow(),
		"integrated mutual active hits trade"
	)
	task.wait(0.6)
	ar = reset(a, origin, Vector3.xAxis)
	br = reset(b, origin + Vector3.zAxis * 15, -Vector3.xAxis)
	check(press(a, Vector3.xAxis), "miss starts an ordinary action")
	task.wait(0.39)
	check(press(a, Vector3.xAxis), "late recovery buffer accepted")
	task.wait(0.055)
	check(not press(a, -Vector3.xAxis), "extra buffered click rejected")
	check(
		Combat.request(a, "aim", a.Character:GetAttribute("F2Generation"), 0, Vector3.zAxis),
		"latest buffered aim accepted"
	)
	task.wait(0.09)
	check(ar:GetAttribute("F2ActionAim") == Vector3.zAxis, "buffer captures current aim at next startup")
	task.wait(0.55)
	ar = reset(a, origin, Vector3.xAxis)
	br = reset(b, origin + Vector3.xAxis * 3.5, -Vector3.xAxis)
	fixture:FireClient(a, "press", Vector3.xAxis)
	task.wait(0.3)
	check(
		br:GetAttribute("F2ProtectionUntil") > workspace:GetServerTimeNow(),
		"client prediction and real attack remote reach server combat"
	)
	for _, player in list do
		fixture:FireClient(player, "snapshot")
	end
	task.wait(0.2)
	for _, player in list do
		check(
			snapshots[player.Name] and snapshots[player.Name].visuals,
			"client presentation exists for " .. player.Name
		)
	end
	task.wait(0.5)
	local oldGen = a.Character:GetAttribute("F2Generation")
	a.Character:SetAttribute("F2Equipped", false)
	check(
		not ar:GetAttribute("F2ActionUntil") and not ar:GetAttribute("F2Displaced"),
		"unequip clears action and displacement"
	)
	a.Character:SetAttribute("F2Equipped", true)
	check(not Combat.request(a, "press", oldGen, seq + 1, Vector3.xAxis), "old equip cannot attack current generation")
	for id = 2, 4 do
		for _, player in list do
			pings[player] = { id = id, sent = os.clock() }
			fixture:FireClient(player, "ping", id)
		end
		task.wait(0.25)
	end
end)
task.cancel(timeout)
workspace:SetAttribute("F2CombatDone", true)
task.wait(1)
connection:Disconnect()
sampleConnection:Disconnect()
fixture:Destroy()
for _, player in Players:GetPlayers() do
	player:SetAttribute("F1ControlsEnabled", nil)
end
Test:EndTest({
	passed = passed,
	error = if passed then nil else tostring(failure),
	checks = checks,
	rttMs = rtt,
	rttSamplesMs = rttSamples,
	networkRestored = networkRestored,
	snapshots = snapshots,
	launchSamples = launchSamples,
})
