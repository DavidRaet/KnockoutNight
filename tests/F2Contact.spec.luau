-- Engine geometry checks, run in Edit after offline checks and source readback.
return function()
	local Storage = game:GetService("ReplicatedStorage")
	local Config = require(Storage.F2Config)
	local Contact = require(game.ServerScriptService.F2Contact)
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	local fixture = Instance.new("Folder")
	fixture.Name = "F2GeometryChecks"
	fixture.Parent = workspace
	rig.Parent = fixture
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CFrame = CFrame.new(500, 500, 500)
		end
	end
	local hand = rig.RightHand
	hand.Size = Vector3.new(1, 1, 1)
	local probe = Instance.new("Part")
	probe.Size = Config.Size
	probe.Anchored = true
	probe.CanCollide = false
	probe.CanQuery = false
	probe.Transparency = 1
	probe.Parent = fixture
	local wall = Instance.new("Part")
	wall.Size = Vector3.new(10, 10, 0.1)
	wall.Anchored = true
	wall.CFrame = CFrame.new(500, 500, 500)
	wall.Parent = fixture
	local count = 0
	local ok, failure = pcall(function()
		local origin = Vector3.new(0, 200, 0)
		local victim = { character = rig }
		local function sweep(position, first, last, from, to, action)
			hand.CFrame = CFrame.new(position)
			action = action or { started = 0, aim = -Vector3.zAxis, encountered = {} }
			local hits = Contact.sweep(
				probe,
				action,
				from or origin,
				to or origin,
				first or 0.08,
				last or 0.18,
				{ rig, probe },
				{ victim }
			)
			return #hits, action, hits
		end
		local function check(value, message)
			assert(value, "F2 geometry: " .. message)
			count += 1
		end
		check(#Contact.body(rig) == 15, "only actual R15 body parts are candidates")
		check(sweep(origin + Vector3.new(0, 0.2, -0.4)) == 1, "point blank and initial overlap")
		check(sweep(origin + Vector3.new(0, 0.2, -5.49)) == 1, "partial limb at forward boundary")
		check(sweep(origin + Vector3.new(0, 0.2, -5.51)) == 0, "beyond five-stud far edge")
		check(sweep(origin + Vector3.new(2.49, 0.2, -3)) == 1, "limb-only side overlap")
		check(sweep(origin + Vector3.new(2.51, 0.2, -3)) == 0, "outside side boundary")
		check(sweep(origin + Vector3.new(0, 3.19, -3)) == 1, "partial vertical overlap")
		check(sweep(origin + Vector3.new(0, 3.21, -3)) == 0, "outside vertical boundary")
		check(sweep(origin + Vector3.new(0, 0.2, -3.5)) == 1, "fast full-window sweep cannot skip a limb")
		check(sweep(origin + Vector3.new(0, 0.2, -0.4), 0.15, 0.17) == 0, "previously traversed space is harmless")
		check(
			sweep(origin + Vector3.new(0, 4.2, -3), 0.08, 0.18, origin + Vector3.yAxis * 4, origin + Vector3.yAxis * 4)
				== 1,
			"airborne attacker carries volume vertically"
		)
		wall.CFrame = CFrame.new(origin + Vector3.new(0, 0, -2.5))
		local hits, action = sweep(origin + Vector3.new(0, 0.2, -4))
		check(hits == 0 and action.wallStopped, "thin wall blocks and stops extension")
		wall.CFrame = CFrame.new(500, 500, 500)
		local stopped = action.stoppedReach
		sweep(
			origin + Vector3.new(0, 0.2, -4),
			0.13,
			0.18,
			origin + Vector3.xAxis * 6,
			origin + Vector3.xAxis * 6,
			action
		)
		check(action.wallStopped and action.stoppedReach == stopped, "moving past wall never restarts extension")
		wall.Size = Vector3.new(0.1, 10, 0.1)
		wall.CFrame = CFrame.new(origin + Vector3.new(1.9, 0, -2.5))
		hits, action = sweep(origin + Vector3.new(0, 0.2, -4))
		check(hits == 0 and action.wallStopped, "volume edge meets obstruction before center")
		wall.CFrame = CFrame.new(500, 500, 500)
		wall.Size = Vector3.new(0.4, 10, 0.1)
		wall.CFrame = CFrame.new(origin + Vector3.new(0, 0, -1.2))
		check(
			sweep(origin + Vector3.new(0.9, 0.2, -1.8), 0.08, 0.09) == 1,
			"exposed body region counts beside an initial corner obstruction"
		)
		wall.Size = Vector3.new(10, 10, 0.1)
		check(
			sweep(origin + Vector3.new(0, 0.2, -1.8), 0.08, 0.09) == 0,
			"covered overlapping region cannot hit through a wall"
		)
		wall.CFrame = CFrame.new(500, 500, 500)
		check(
			sweep(origin + Vector3.new(3, 0.2, -3), 0.08, 0.18, origin, origin + Vector3.xAxis * 6) == 1,
			"sampled attacker movement carries swept volume"
		)
		check(
			sweep(origin + Vector3.new(0, 0.2, -3)) == 1 and sweep(origin + Vector3.new(10, 0.2, -3)) == 0,
			"moving target uses its current server pose without rewind"
		)
		local accessory = Instance.new("Accessory")
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(4, 4, 4)
		handle.Anchored = true
		handle.CanCollide = false
		handle.CFrame = CFrame.new(origin + Vector3.new(0, 0.2, -3))
		handle.Parent = accessory
		accessory.Parent = rig
		check(sweep(Vector3.new(500, 500, 500)) == 0, "accessories never count as body contacts")
	end)
	fixture:Destroy()
	assert(ok, "F2 geometry checks failed: " .. tostring(failure))
	return { passed = true, checks = count }
end
