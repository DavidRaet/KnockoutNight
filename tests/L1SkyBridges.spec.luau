return function()
	local Build = require(game.ServerScriptService.L1SkyBridges)
	local Rules = require(game.ReplicatedStorage.F3Rules)
	local Config = require(game.ReplicatedStorage.F1Config)
	local Contact = require(game.ServerScriptService.F2Contact)
	local arena, frames, points, fallback = Build.build()
	local checks = {}
	local function check(value, message)
		assert(value, "L1 Sky Bridges: " .. message)
		table.insert(checks, message)
	end
	arena.Parent = workspace
	local victim = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name, root.Size, root.Anchored, root.CanCollide = "HumanoidRootPart", Vector3.new(2, 2, 1), true, false
	root.Parent = victim
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight, humanoid.Parent = 2, victim
	victim.Parent = workspace
	local ray = RaycastParams.new()
	ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide =
		Enum.RaycastFilterType.Include, { arena }, true
	local top = Config.PlatformCenter.Y + 2
	local function support(position)
		return workspace:Raycast(Vector3.new(position.X, top + 5, position.Z), -Vector3.yAxis * 10, ray)
	end
	local passed, failure = pcall(function()
		local surfaces, scenery = 0, 0
		for _, p in arena:GetChildren() do
			check(p:IsA("BasePart") and p.Anchored, p.Name .. " is an anchored part")
			if p:GetAttribute("F11Playable") then
				surfaces += 1
				check(p.CanCollide and p.CanQuery, p.Name .. " supports physics and combat queries")
			else
				scenery += 1
				check(
					not p.CanCollide and not p.CanQuery and not p.CanTouch,
					p.Name .. " cannot block or catch players"
				)
			end
		end
		check(surfaces == 6 and scenery > 0, "exactly three islands and three bridges are playable")
		check(
			arena.Island1.Size.Y == 50 and arena.Island2.Size.Y == 30 and arena.Island3.Size.Y == 30,
			"approved island diameters"
		)
		check(
			math.abs(frames[1].X + frames[2].X) < 0.001 and frames[1].Z == frames[2].Z,
			"opening spawns mirror each other"
		)
		check(#points == 10, "five respawn candidates per home island")
		for _, marker in points do
			local home = marker:GetAttribute("F3Home")
			check(home == 1 or home == 2, marker.Name .. " has a home island")
			for _, offset in
				{
					Vector3.zero,
					Vector3.new(-2.5, 0, -2.5),
					Vector3.new(2.5, 0, -2.5),
					Vector3.new(-2.5, 0, 2.5),
					Vector3.new(2.5, 0, 2.5),
				}
			do
				local hit = support(marker.Position + offset)
				check(
					hit and hit.Instance == arena["Island" .. (home + 1)],
					marker.Name .. " has full home-island support"
				)
			end
		end
		check(support(fallback.Position).Instance == arena.Island1, "emergency fallback has permanent central support")
		for i, pair in { { 1, 2 }, { 1, 3 }, { 2, 3 } } do
			local a, b = arena["Island" .. pair[1]], arena["Island" .. pair[2]]
			local direction = (b.Position - a.Position).Unit
			local right = direction:Cross(Vector3.yAxis)
			local count = math.ceil((b.Position - a.Position).Magnitude / 0.5)
			local continuous = true
			for step = 0, count do
				for _, side in { -5.9, 0, 5.9 } do
					local hit = support(a.Position:Lerp(b.Position, step / count) + right * side)
					continuous = continuous and hit ~= nil and math.abs(hit.Position.Y - top) < 0.001
				end
			end
			check(
				continuous and arena["Bridge" .. i].Size.X == 12,
				"route " .. i .. " is level and supported across its full width"
			)
			local join = arena["Bridge" .. i].Position - direction * arena["Bridge" .. i].Size.Z / 2
			local origin = join - direction * 2 + Vector3.yAxis * 2
			root.Position = join + direction * 2 + Vector3.yAxis * 5
			check(
				Contact.slamTarget(origin, { root = root, humanoid = humanoid }, { victim }),
				"slam crosses route " .. i .. " island/bridge seam"
			)
			if i <= 2 then
				local gapOrigin = a.Position + direction * 22 + right * 10 + Vector3.yAxis * 2
				root.Position = a.Position + direction * 27 + right * 5.5 + Vector3.yAxis * 5
				check(support(gapOrigin) and support(root.Position), "gap probe endpoints both have floor support")
				check(
					not Contact.slamTarget(gapOrigin, { root = root, humanoid = humanoid }, { victim }),
					"slam cannot cut across route " .. i .. " concave shoreline void"
				)
			end
		end
		local center = arena:GetAttribute("F3BoundsCenter")
		local lower = arena:GetAttribute("F3LowerY")
		local radius = arena:GetAttribute("F3OuterRadius")
		for _, marker in points do
			check(
				not Rules.outside(marker.Position, center, lower, radius),
				marker.Name .. " lies inside elimination bounds"
			)
		end
		check(not support(Config.PlatformCenter + Vector3.new(0, 0, 40)), "triangle interior remains open void")
		check(
			Rules.outside(Vector3.new(0, lower, 40), center, lower, radius),
			"falling through an interior gap crosses lower elimination plane"
		)
		check(Rules.outside(center + Vector3.xAxis * radius, center, lower, radius), "outer boundary remains finite")
	end)
	victim:Destroy()
	arena:Destroy()
	return { passed = passed, error = if passed then nil else tostring(failure), checks = checks }
end
