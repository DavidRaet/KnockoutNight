return function()
	local Paddles = require(game.ReplicatedStorage.F7Paddles)
	local Contact = require(game.ServerScriptService.F2Contact)
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	local fixture = Instance.new("Folder")
	fixture.Name, fixture.Parent = "F7GeometryChecks", workspace
	rig.Parent = fixture
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide = true, false
			part.CFrame = CFrame.new(500, 500, 500)
		end
	end
	local body = rig.RightHand
	body.Size = Vector3.one
	local probe = Instance.new("Part")
	probe.Anchored, probe.CanCollide, probe.CanQuery, probe.Transparency = true, false, false, 1
	probe.Parent = fixture
	local wall = Instance.new("Part")
	wall.Anchored, wall.Size, wall.CFrame, wall.Parent =
		true, Vector3.new(30, 12, 0.3), CFrame.new(500, 500, 500), fixture
	local count = 0
	local ok, failure = pcall(function()
		local origin = Vector3.new(0, 200, 0)
		local victim = { character = rig }
		local function check(value, message)
			assert(value, "F7 geometry: " .. message)
			count += 1
		end
		local function sweep(hand, offset, finish, consumed, aim, first, last)
			body.CFrame = CFrame.new(origin + offset)
			return Contact.sweep(probe, {
				started = 0,
				aim = aim or -Vector3.zAxis,
				encountered = if consumed then { [victim] = true } else {},
				config = Paddles,
				hand = hand,
			}, origin, finish or origin, first or 0.10, last or 0.17999, { rig, probe }, { victim })
		end
		for _, hand in { "Left", "Right" } do
			local side = if hand == "Left" then -1 else 1
			local frame = Paddles.frame(origin, -Vector3.zAxis, hand)
			check(
				(frame.Position - origin - Vector3.new(side * 0.5, 0, -3.25)).Magnitude < 1e-6,
				hand .. " exact mirrored center"
			)
			check(#sweep(hand, Vector3.new(0, 0, -2)) == 1, hand .. " reaches centered opponent")
			check(#sweep(hand, Vector3.new(side * 2.49, 0, -2)) == 1, hand .. " partial outside-body overlap counts")
			check(#sweep(hand, Vector3.new(side * 2.51, 0, -2)) == 0, hand .. " outside lateral edge misses")
			check(#sweep(hand, Vector3.new(-side * 1.51, 0, -2)) == 0, hand .. " opposite-side edge is shorter")
			check(#sweep(hand, Vector3.new(0, 0, -6.49)) == 1, hand .. " limb overlapping front edge hits")
			check(#sweep(hand, Vector3.new(0, 0, -6.51)) == 0, hand .. " limb beyond front edge misses")
			check(#sweep(hand, Vector3.new(0, 2.49, -2)) == 1, hand .. " vertical partial overlap hits")
			check(#sweep(hand, Vector3.new(0, 2.51, -2)) == 0, hand .. " above volume misses")
			check(#sweep(hand, Vector3.new(0, -2.51, -2)) == 0, hand .. " below volume misses")
			check(#sweep(hand, Vector3.new(0, 0, 1)) == 0, hand .. " behind attacker misses")
			check(#sweep(hand, Vector3.new(0, 0, -2), nil, true) == 0, hand .. " encountered target cannot repeat")
			check(
				#sweep(hand, Vector3.new(4, 0, -2), origin + Vector3.xAxis * 3) == 1,
				hand .. " samples attacker movement"
			)
			check(
				#sweep(hand, Vector3.new(2, 0, 0), nil, false, Vector3.xAxis) == 1,
				hand .. " committed aim rotates box"
			)
			check(
				#sweep(hand, Vector3.new(0, 0, -2), nil, false, nil, 0.18, 0.20) == 0,
				hand .. " exclusive active end"
			)
			wall.CFrame = CFrame.new(origin + Vector3.new(0, 0, -1))
			check(#sweep(hand, Vector3.new(0, 0, -2)) == 0, hand .. " solid wall blocks contact")
			wall.CFrame = CFrame.new(500, 500, 500)
		end
	end)
	fixture:Destroy()
	assert(ok, "F7 geometry checks failed: " .. tostring(failure))
	return { passed = true, checks = count }
end
