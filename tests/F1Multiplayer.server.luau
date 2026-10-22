-- Temporarily sync this into ServerScriptService to run a two-client Studio test.
local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F1" then
	return
end

task.delay(25, function()
	Test:EndTest({ passed = false, error = "F1 verification timed out" })
end)

local passed, result = pcall(function()
	local Players = game:GetService("Players")
	local Match = require(game.ServerScriptService.F4Match)
	local deadline = os.clock() + 20
	while os.clock() < deadline do
		local players = Players:GetPlayers()
		if
			#players == 2
			and players[1].Character
			and players[2].Character
			and players[1]:GetAttribute("F3Status") == "waiting"
			and players[2]:GetAttribute("F3Status") == "waiting"
		then
			break
		end
		task.wait(0.1)
	end
	local players = Players:GetPlayers()
	assert(#players == 2, "Expected two clients")
	assert(Match.begin(), "F1 verification starts the staged two-player match")
	local goDeadline = os.clock() + 6
	while os.clock() < goDeadline and not Match.allowed(workspace:GetServerTimeNow()) do
		task.wait(0.1)
	end
	assert(Match.allowed(workspace:GetServerTimeNow()), "F1 verification reaches GO")
	task.wait(1)
	local a, b = players[1].Character, players[2].Character
	assert(a and b, "Both clients need characters")
	assert(
		a.Humanoid.RigType == Enum.HumanoidRigType.R15 and b.Humanoid.RigType == Enum.HumanoidRigType.R15,
		"Both characters must use R15 rigs"
	)
	for _, character in { a, b } do
		local description = character.Humanoid:GetAppliedDescription()
		assert(description.BodyTypeScale == 0 and description.ProportionScale == 0, "Rig scales are not standardized")
	end
	local first, second = a:GetPivot(), b:GetPivot()
	assert(math.abs(first.Position.X + second.Position.X) < 0.1, "Starting positions are not symmetric")
	assert(math.abs(first.Position.X - second.Position.X) > 35, "Starting positions overlap")
	local parts = 0
	for _, part in a:GetChildren() do
		if part:IsA("BasePart") then
			local other = b:FindFirstChild(part.Name)
			assert(other and other:IsA("BasePart"), "Missing matching R15 part")
			assert((part.Size - other.Size).Magnitude < 0.001, "R15 dimensions differ")
			assert(
				part.CollisionGroup == "F1Characters" and other.CollisionGroup == "F1Characters",
				"Matching R15 parts must use the F1Characters collision group"
			)
			parts += 1
		end
	end
	assert(
		not game:GetService("PhysicsService"):CollisionGroupsAreCollidable("F1Characters", "F1Characters"),
		"F1 character collision group must not collide with itself"
	)
	a:PivotTo(CFrame.new(0, 45, 0))
	b:PivotTo(CFrame.new(0, 45, 0))
	local combatModule = game.ServerScriptService:FindFirstChild("F2Combat")
	if combatModule then
		local combat = require(combatModule)
		combat.resetMovement(players[1])
		combat.resetMovement(players[2])
	end
	task.wait(0.5)
	local separation = a.HumanoidRootPart.Position - b.HumanoidRootPart.Position
	assert(Vector3.new(separation.X, 0, separation.Z).Magnitude < 0.5, "Overlapping characters push each other")
	return { players = #players, matchingBodyParts = parts, symmetricSpawns = true, noBodyBlocking = true }
end)

Test:EndTest({ passed = passed, result = if passed then result else tostring(result) })
