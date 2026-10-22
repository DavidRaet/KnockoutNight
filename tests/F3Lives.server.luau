local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F3Lives" then
	return
end
local Players = game:GetService("Players")
local Combat = require(game.ServerScriptService.F2Combat)
local Lives = require(game.ServerScriptService.F3Lives)
local Match = require(game.ServerScriptService.F4Match)
local Config = require(game.ReplicatedStorage.F3Config)
local fixture = Instance.new("RemoteEvent")
fixture.Name, fixture.Parent = "F3LivesTest", game.ReplicatedStorage
local ready, snapshots, checks = {}, {}, {}
local timeout = task.delay(85, function()
	Test:EndTest({ passed = false, error = "F3 fixture timed out" })
end)
local connection = fixture.OnServerEvent:Connect(function(player, kind, data)
	if kind == "ready" then
		ready[player] = true
	elseif kind == "snapshot" then
		snapshots[player] = data
	end
end)
local passed, failure = pcall(function()
	local function waitFor(condition, seconds, message)
		local deadline = os.clock() + seconds
		repeat
			if condition() then
				return
			end
			task.wait()
		until os.clock() >= deadline
		assert(condition(), "F3 timeout: " .. message)
	end
	local function check(condition, message)
		assert(condition, "F3 lives: " .. message)
		table.insert(checks, message)
	end
	waitFor(function()
		local list = Players:GetPlayers()
		local roster = Lives.roster()
		return #list == 2
			and #roster == 2
			and ready[list[1]]
			and ready[list[2]]
			and list[1].Character
			and list[2].Character
			and list[1]:GetAttribute("F3Status") == "waiting"
			and list[2]:GetAttribute("F3Status") == "waiting"
	end, 25, "two ready clients")
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	local a, b = list[1], list[2]
	check(Match.begin(), "F3 verification starts the staged two-player match")
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 6, "match GO")
	task.wait(1.5)
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
	end
	local function pose(player, position, aim)
		local character = player.Character
		local root = character.HumanoidRootPart
		root:SetNetworkOwner(nil)
		root.CFrame = CFrame.lookAt(position, position + (aim or Vector3.xAxis))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		Combat.resetMovement(player)
		return root
	end
	local function snapshot(player, tag)
		fixture:FireClient(player, "snapshot", { tag = tag, status = player:GetAttribute("F3Status") })
		waitFor(function()
			return snapshots[player] and snapshots[player].tag == tag
		end, 3, "client snapshot " .. tag)
		return snapshots[player]
	end
	local function waitRespawn(player, old, knownDeadline)
		local deadline = knownDeadline or player:GetAttribute("F3RespawnAt")
		waitFor(function()
			return player.Character ~= old and Lives.alive(player)
		end, 4.5, "fresh safe respawn")
		check(workspace:GetServerTimeNow() >= deadline, "respawn never precedes its deadline")
		return player.Character
	end
	local first = a.Character
	local life, generation = a:GetAttribute("F3Life"), first:GetAttribute("F2Generation")
	local root = pose(a, Vector3.new(36, 18, 0))
	Lives.step()
	Match.step()
	check(Lives.alive(a), "horizontal edge remains recoverable above lower plane")
	root.CFrame = CFrame.new(36, 16.99, 0)
	Lives.step()
	Match.step()
	check(
		a:GetAttribute("F3Status") == "eliminated" and b:GetAttribute("F3Score") == 1,
		"lower plane commits one opponent point"
	)
	local deadline = a:GetAttribute("F3RespawnAt")
	check(not Lives.eliminate(a, life, "duplicate"), "duplicate callback cannot score twice")
	first.Humanoid.Health = 0
	check(not Combat.request(a, "press", generation, 50000, Vector3.xAxis), "eliminated life cannot attack")
	local early = snapshot(a, "fall")
	check(early.countdownVisible and early.spectating == nil, "fall view and countdown appear before spectator switch")
	task.wait(Config.FallCameraTime)
	local spec = snapshot(a, "spectator")
	check(spec.spectating == b.UserId and spec.countdownVisible, "camera follows surviving opponent during countdown")
	check(spec.feedEntries > 0 and spec.scores[b.Name] == 1, "knockout feed and score reach eliminated client")
	check(snapshot(b, "score").scores[b.Name] == 1, "both clients agree on score")
	check(
		b:GetAttribute("F3Score") == 1 and a:GetAttribute("F3RespawnAt") == deadline,
		"later death callback cannot duplicate score or extend timer"
	)
	pose(b, Vector3.new(18, 45, 0))
	local character = waitRespawn(a, first)
	check(character.HumanoidRootPart.Position.X < -17, "safe respawn chooses farthest point from opponent")
	check(
		character:FindFirstChild("F3SpawnShield") ~= nil and a:GetAttribute("F3Life") == life + 1,
		"fresh R15 life receives visible protection"
	)
	check(not Lives.eliminate(a, life, "stale"), "old-life callback cannot eliminate replacement")
	check(
		not Combat.request(a, "press", generation, 50001, Vector3.xAxis),
		"old-generation request rejected after respawn"
	)
	pose(a, Vector3.new(0, 45, 0))
	pose(b, Vector3.new(-4, 45, 0), Vector3.xAxis)
	local protectionUntil = Lives.protectionUntil(a)
	fixture:FireClient(b, "attack", Vector3.xAxis)
	task.wait(0.6)
	check(
		not character.HumanoidRootPart:GetAttribute("F2Displaced") and Lives.protectionUntil(a) == protectionUntil,
		"protected contact neither launches nor extends shield"
	)
	fixture:FireClient(a, "attack", -Vector3.xAxis)
	waitFor(function()
		return not character:FindFirstChild("F3SpawnShield")
	end, 1, "action ends shield")
	check(Lives.protectionUntil(a) == 0, "accepted client attack ends protection before resolving")
	pose(b, Vector3.new(18, 45, 0))
	pose(a, Vector3.new(96, 45, 0))
	Lives.step()
	Match.step()
	check(
		a:GetAttribute("F3Status") == "eliminated" and b:GetAttribute("F3Score") == 2,
		"outer bounds commit independently of health"
	)
	local second = waitRespawn(a, character)
	task.wait(Config.SpawnProtection + 0.1)
	check(not second:FindFirstChild("F3SpawnShield"), "unused shield expires naturally")
	second.Humanoid.Health = 0
	waitFor(function()
		return a:GetAttribute("F3Status") == "eliminated" and b:GetAttribute("F3Score") == 3
	end, 1, "reset/death commits")
	check(b:GetAttribute("F3Score") == 3, "unexpected death scores exactly once")
	local world = workspace.F1Platform
	local points = {}
	for _, marker in world:GetChildren() do
		if marker:IsA("BasePart") and (marker.Name:match("^Spawn") or marker.Name:match("^Respawn")) then
			table.insert(points, marker)
			marker:SetAttribute("F3SpawnAvailable", false)
		end
	end
	pose(b, Vector3.new(18, 45, 0))
	local third = waitRespawn(a, second)
	local position = third.HumanoidRootPart.Position
	check(
		math.abs(position.X) < 0.1 and math.abs(position.Z) < 0.1,
		"all unavailable candidates use permanent-center fallback"
	)
	for _, marker in points do
		marker:SetAttribute("F3SpawnAvailable", true)
	end
	pose(a, Vector3.new(36, 16, 0))
	Lives.step()
	Match.step()
	check(a:GetAttribute("F3Status") == "eliminated", "spawn shield does not prevent falling")
	waitRespawn(a, third)
	fixture:FireClient(a, "attack", Vector3.xAxis)
	task.wait(0.6)
	pose(b, Vector3.new(29, 45, 0))
	pose(a, Vector3.new(34.5, 45, 0))
	local beforeLaunch, launchVictim = b:GetAttribute("F3Score"), a.Character
	fixture:FireClient(b, "attack", Vector3.xAxis)
	waitFor(function()
		return a:GetAttribute("F3Status") == "eliminated" and b:GetAttribute("F3Score") == beforeLaunch + 1
	end, 3, "real Spring Fist ring-out")
	check(b:GetAttribute("F3Score") == beforeLaunch + 1, "real client attack launches into a scored fall")
	local attributed = snapshot(a, "attributed-fall")
	local foundCredit = false
	for _, text in attributed.feedText do
		foundCredit = foundCredit or text == b.DisplayName .. " → Spring Fist → " .. a.DisplayName
	end
	check(foundCredit, "successful displacement receives feed credit independently of score")
	waitRespawn(a, launchVictim)
	local bothA, bothB = a.Character, b.Character
	local aScore, bScore = a:GetAttribute("F3Score"), b:GetAttribute("F3Score")
	pose(a, Vector3.new(40, 16, 0))
	pose(b, Vector3.new(-40, 16, 0))
	Lives.step()
	Match.step()
	local aDeadline, bDeadline = a:GetAttribute("F3RespawnAt"), b:GetAttribute("F3RespawnAt")
	check(
		a:GetAttribute("F3Score") == aScore + 1 and b:GetAttribute("F3Score") == bScore + 1,
		"simultaneous falls award one point to each opponent"
	)
	task.wait(Config.FallCameraTime + 0.1)
	local empty = snapshot(a, "no-survivor")
	check(
		empty.spectating == nil and math.abs(empty.focus[1]) < 0.1 and math.abs(empty.focus[3]) < 0.1,
		"no-survivor camera uses fixed arena view"
	)
	waitRespawn(a, bothA, aDeadline)
	waitRespawn(b, bothB, bDeadline)
	check(
		(a.Character.HumanoidRootPart.Position - b.Character.HumanoidRootPart.Position).Magnitude > 5,
		"simultaneous respawns do not overlap"
	)
	local final = a.Character
	for _, marker in points do
		marker:SetAttribute("F3SpawnAvailable", false)
	end
	world.Surface.CanCollide = false
	Lives.eliminate(a, a:GetAttribute("F3Life"), "failure-path")
	waitFor(function()
		return workspace:GetAttribute("F3SessionError") ~= nil
	end, 4, "bounded spawn failure")
	check(
		a:GetAttribute("F3Status") == "stopped" and a.Character == final,
		"missing fallback stops session without indefinite respawn"
	)
	check(snapshot(a, "failure").countdownVisible, "terminal failure remains visible to client")
end)
task.cancel(timeout)
connection:Disconnect()
local observed = {}
for player, data in snapshots do
	observed[player.Name] = data
end
Test:EndTest({
	passed = passed,
	checks = checks,
	error = if passed then nil else tostring(failure),
	snapshots = observed,
	version = "F3",
})
