return function()
	local Storage = game:GetService("ReplicatedStorage")
	local Hammer = require(Storage.F6Hammer)
	local Contact = require(game.ServerScriptService.F2Contact)
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	local fixture = Instance.new("Folder")
	fixture.Name, fixture.Parent = "F6GeometryChecks", workspace
	rig.Parent = fixture
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide = true, false
			part.CFrame = CFrame.new(500, 500, 500)
		end
	end
	local hand = rig.RightHand
	hand.Size = Vector3.one
	local probe = Instance.new("Part")
	probe.Anchored, probe.CanCollide, probe.CanQuery, probe.Transparency = true, false, false, 1
	probe.Parent = fixture
	local wall = Instance.new("Part")
	wall.Size, wall.Anchored = Vector3.new(30, 12, 0.3), true
	wall.CFrame, wall.Parent = CFrame.new(500, 500, 500), fixture
	local count = 0
	local ok, failure = pcall(function()
		local origin = Vector3.new(0, 200, 0)
		local victim = { character = rig }
		local function check(value, message)
			assert(value, "F6 geometry: " .. message)
			count += 1
		end
		local function sweep(position, first, last, action, finish)
			hand.CFrame = CFrame.new(position)
			action = action or { started = 0, aim = -Vector3.zAxis, encountered = {}, config = Hammer }
			return Contact.sweep(
				probe,
				action,
				origin,
				finish or origin,
				first or 0.48,
				last or 0.659999,
				{ rig, probe },
				{ victim }
			)
		end
		for _, angle in { -40, -20, 0, 20, 40 } do
			local offset = CFrame.Angles(0, math.rad(angle), 0).LookVector * 6
			local hits = sweep(origin + offset)
			check(#hits == 1, "broad frontal coverage at " .. angle .. " degrees")
			check(hits[1].time >= 0.48 and hits[1].time < 0.66, "contact timestamp belongs to active interval")
		end
		for _, angle in { -90, -70, 70, 90, 180 } do
			check(
				#sweep(origin + CFrame.Angles(0, math.rad(angle), 0).LookVector * 6) == 0,
				"outside frontal sweep at " .. angle .. " degrees"
			)
		end
		check(#sweep(origin + Vector3.new(0, 0, -6.9)) == 1, "body overlapping seven-stud reach hits")
		check(#sweep(origin + Vector3.new(0, 0, -8)) == 0, "beyond reach misses")
		check(#sweep(origin + Vector3.new(0, 4, -4)) == 0, "body above vertical volume misses")
		check(#sweep(origin + Vector3.new(0, -4, -4)) == 0, "body below vertical volume misses")
		check(#sweep(origin + Vector3.new(0, 2, -4)) == 1, "partial suitable vertical overlap hits")
		check(#sweep(origin + Vector3.new(0, 0, -1)) == 1, "close body beside shaft hits")
		check(
			#sweep(origin + Vector3.new(0, 0, -5), 0.48, 0.50) == 0,
			"forward target waits for visible swing to cross it"
		)
		check(
			#sweep(origin + Vector3.new(0, 0, -5), 0.55, 0.59) == 1,
			"forward target contacts at middle of visible swing"
		)
		wall.CFrame = CFrame.new(origin + Vector3.new(0, 0, -2))
		check(#sweep(origin + Vector3.new(0, 0, -5)) == 0, "solid obstruction prevents through-wall contact")
		wall.Size = Vector3.new(1, 12, 0.3)
		check(#sweep(origin + Vector3.new(3, 0, -4)) == 1, "clear path beside narrow obstruction still hits")
		wall.CFrame = CFrame.new(500, 500, 500)
		local action = { started = 0, aim = -Vector3.zAxis, encountered = { [victim] = true }, config = Hammer }
		check(#sweep(origin + Vector3.new(0, 0, -4), nil, nil, action) == 0, "encountered target never contacts twice")
		check(
			#sweep(origin + Vector3.new(5, 0, -5), 0.48, 0.659999, nil, origin + Vector3.xAxis * 4) == 1,
			"sampled attacker movement carries radial blade"
		)
	end)
	fixture:Destroy()
	assert(ok, "F6 geometry checks failed: " .. tostring(failure))
	return { passed = true, checks = count }
end
