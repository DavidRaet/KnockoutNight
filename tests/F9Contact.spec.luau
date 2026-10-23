return function()
	local Contact = require(game.ServerScriptService.F2Contact)
	local Magnet = require(game.ReplicatedStorage.F9Magnet)
	local description = Instance.new("HumanoidDescription")
	local rig = game.Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "F9GeometryChecks", workspace
	rig.Parent = folder
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide = true, false
			part.CFrame = CFrame.new(500, 500, 500)
		end
	end
	local hand = rig.RightHand
	hand.Size = Vector3.one
	local victim = { character = rig, root = rig.HumanoidRootPart }
	local origin = Vector3.new(0, 200, 0)
	local checks = {}
	local function check(value, message)
		assert(value, "F9 geometry: " .. message)
		table.insert(checks, message)
	end
	local function geometry(offset, height)
		victim.root.CFrame = CFrame.new(origin + offset)
		hand.CFrame = CFrame.new(origin + offset + Vector3.yAxis * (height or 0))
		return Contact.gust(origin, Vector3.xAxis, victim, { rig }, Magnet)
	end
	local ok, failure = pcall(function()
		check(geometry(Vector3.new(20, 0, 0)) ~= nil, "inclusive twenty-stud range")
		check(geometry(Vector3.new(20.001, 0, 0)) == nil, "outside range excluded")
		check(geometry(Vector3.new(-2, 0, 0)) == nil, "behind excluded")
		for _, angle in { -30, 30, -30.01, 30.01 } do
			local inside = math.abs(angle) <= 30
			local hit = geometry(Vector3.new(8 * math.cos(math.rad(angle)), 0, 8 * math.sin(math.rad(angle))))
			check((hit ~= nil) == inside, "cone boundary " .. angle)
		end
		check(geometry(Vector3.new(6, 0, 0), 3) ~= nil, "inclusive upper vertical band")
		check(geometry(Vector3.new(6, 0, 0), -3) ~= nil, "inclusive lower vertical band")
		check(geometry(Vector3.new(6, 0, 0), 3.01) == nil, "above vertical band")
		check(geometry(Vector3.new(6, 0, 0), -3.01) == nil, "below vertical band")
		local wall = Instance.new("Part")
		wall.Anchored, wall.Size, wall.CFrame, wall.Parent =
			true, Vector3.new(0.5, 12, 2), CFrame.new(origin + Vector3.xAxis * 3), folder
		check(geometry(Vector3.new(6, 0, 0)) == nil, "solid obstruction excludes target")
		check(geometry(Vector3.new(6, 0, 3.2)) ~= nil, "unobstructed second candidate remains eligible")
		wall.CanCollide = false
		check(geometry(Vector3.new(6, 0, 0)) ~= nil, "nonsolid scenery ignored")
		local accessory = Instance.new("Part")
		accessory.Name, accessory.Anchored, accessory.CFrame, accessory.Parent =
			"FakeBody", true, CFrame.new(origin + Vector3.xAxis * 6), rig
		check(geometry(Vector3.new(6, 0, 0), 4) == nil, "non-body parts do not satisfy band")
	end)
	folder:Destroy()
	return { passed = ok, error = if ok then nil else tostring(failure), checks = checks }
end
