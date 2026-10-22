local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F6Knockback" then
	return
end
local Combat = require(game.ServerScriptService.F2Combat)
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local samples, errors = {}, {}
local originalStep = Combat.step
local subject, trial
local errorConnection = game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		table.insert(errors, message)
	end
end)
Combat.step = function(dt)
	originalStep(dt)
	if subject and trial then
		local root = subject.Character.HumanoidRootPart
		if not trial.at and root:GetAttribute("F2Displaced") then
			trial.at, trial.origin = workspace:GetServerTimeNow(), root.Position
			trial.launch =
				{ root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z }
		end
		if trial.origin then
			local delta = root.Position - trial.origin
			trial.distance = math.max(trial.distance or 0, Vector3.new(delta.X, 0, delta.Z).Magnitude)
		end
	end
end
local timeout = task.delay(50, function()
	Test:EndTest({ passed = false, error = "Hammer travel fixture timed out" })
end)
local passed, failure = pcall(function()
	local function waitFor(predicate, seconds, message)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and not predicate() do
			task.wait()
		end
		assert(predicate(), "Hammer travel: " .. message)
	end
	waitFor(function()
		local list = Lives.roster()
		return #list == 2
			and list[1]:GetAttribute("F3Status") == "waiting"
			and list[2]:GetAttribute("F3Status") == "waiting"
	end, 20, "two staged clients")
	local list = Lives.roster()
	local attacker, victim = list[1], list[2]
	attacker:SetAttribute("F2Weapon", "WreckingHammer")
	for _, player in list do
		player:SetAttribute("F1ControlsEnabled", false)
	end
	assert(Match.begin(), "Hammer travel requires a real Platform match")
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 6, "GO")
	task.wait(1.5)
	for index = 1, 3 do
		for side, player in list do
			local c = player.Character
			Lives.endProtection(player)
			c:SetAttribute("F2Equipped", false)
			c:SetAttribute("F2Equipped", true)
			local root = c.HumanoidRootPart
			local pos = Vector3.new(-15 + (side - 1) * 5, 45, 0)
			root:SetNetworkOwner(nil)
			root.CFrame = CFrame.lookAt(pos, pos + Vector3.xAxis)
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			c.Humanoid:Move(Vector3.zero, false)
			Combat.resetMovement(player)
		end
		task.wait(0.3)
		trial, subject = {}, victim
		assert(
			Combat.request(attacker, "press", attacker.Character:GetAttribute("F2Generation"), index, Vector3.xAxis),
			"Hammer travel activation must be accepted"
		)
		waitFor(function()
			return trial.at ~= nil
		end, 1, "Hammer contact")
		task.wait(1.8)
		assert(
			not victim.Character.HumanoidRootPart:GetAttribute("F2Displaced"),
			"Hammer travel must release displacement control"
		)
		local sample = { distance = trial.distance, launch = trial.launch }
		table.insert(samples, sample)
		trial, subject = nil, nil
		if args.expected then
			assert(
				math.abs(sample.distance - args.expected) <= (args.tolerance or 1),
				"Hammer grounded idle travel must be within target tolerance: " .. tostring(sample.distance)
			)
		end
	end
	assert(#errors == 0, "Hammer travel must not raise server script errors")
end)
task.cancel(timeout)
Combat.step = originalStep
errorConnection:Disconnect()
Test:EndTest({ passed = passed, error = if passed then nil else tostring(failure), samples = samples, errors = errors })
