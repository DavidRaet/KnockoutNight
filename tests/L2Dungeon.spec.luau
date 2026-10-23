return function()
	local arena, frames, points, fallback = require(game.ServerScriptService.L2Dungeon).build()
	local Config = require(game.ReplicatedStorage.F1Config)
	local Rules = require(game.ReplicatedStorage.F3Rules)
	local checks = {}
	local function check(value, message)
		assert(value, "L2 Dungeon: " .. message)
		table.insert(checks, message)
	end
	arena.Parent = workspace
	local passed, failure = pcall(function()
		local floor, ball = arena.Surface, arena.MockWreckingBall
		local origin = Config.PlatformCenter
		local top = floor.Position.Y + floor.Size.Y / 2
		check(
			floor.Size == Vector3.new(80, 4, 80) and floor.Position == origin,
			"approved square dimensions and origin"
		)
		check(ball.Shape == Enum.PartType.Ball and ball.Size == Vector3.one * 10, "10-stud mock sphere")
		check(ball.Position == origin + Vector3.yAxis * 15, "ball centered with bottom eight studs above floor")
		local beam = arena.SupportBeam
		local chainTop = arena.ChainLink8.Position.Y + arena.ChainLink8.Size.Y / 2
		check(
			beam.Position.Y - beam.Size.Y / 2 <= chainTop and beam.Position.Y + beam.Size.Y / 2 >= chainTop,
			"chain meets overhead beam"
		)
		for _, post in { arena.SupportPost1, arena.SupportPost2 } do
			check(
				post.Position.Y - post.Size.Y / 2 == top
					and post.Position.Y + post.Size.Y / 2 == beam.Position.Y + beam.Size.Y / 2,
				post.Name .. " connects floor to beam"
			)
			check(
				math.abs(post.Position.X - beam.Position.X) + post.Size.X / 2 <= beam.Size.X / 2,
				post.Name .. " supports beam end"
			)
		end
		local surfaces, links = 0, 0
		for _, p in arena:GetChildren() do
			check(p:IsA("BasePart") and p.Anchored, p.Name .. " anchored")
			if p:GetAttribute("F11Playable") then
				surfaces += 1
				check(p == floor and p.CanCollide and p.CanQuery, "only floor supports physics and combat")
			else
				check(not p.CanCollide and not p.CanQuery and not p.CanTouch, p.Name .. " noninteractive")
			end
			if string.match(p.Name, "^ChainLink") then
				links += 1
				check(p.Position.X == origin.X and p.Position.Z == origin.Z, "chain remains vertical")
			end
		end
		check(surfaces == 1 and links == 8, "single permanent surface and simple chain")
		check(#points == 10, "five respawn candidates per home")
		local ray = RaycastParams.new()
		ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { arena }
		local function support(position)
			return workspace:Raycast(Vector3.new(position.X, top + 35, position.Z), -Vector3.yAxis * 40, ray)
		end
		for home, sign in { -1, 1 } do
			check(
				frames[home].Position == origin + Vector3.new(sign * 20, 6, 0),
				"home " .. home .. " opening position"
			)
			check(frames[home].LookVector:Dot(-Vector3.xAxis * sign) > 0.999, "home " .. home .. " faces inward")
		end
		for _, marker in points do
			local home = marker:GetAttribute("F3Home")
			check(home == 1 or home == 2, marker.Name .. " has a home")
			for _, offset in
				{
					Vector3.zero,
					Vector3.new(-2.5, 0, -2.5),
					Vector3.new(2.5, 0, 2.5),
					Vector3.new(-2.5, 0, 2.5),
					Vector3.new(2.5, 0, -2.5),
				}
			do
				local hit = support(marker.Position + offset)
				check(hit and hit.Instance == floor, marker.Name .. " fully supported")
			end
		end
		check(support(fallback.Position).Instance == floor, "mock does not obstruct central fallback support query")
		for _, direction in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			check(
				support(origin + direction * 39.9) ~= nil and support(origin + direction * 40.1) == nil,
				"open ring-out edge"
			)
		end
		for _, x in { -39, 39 } do
			for _, z in { -39, 39 } do
				check(
					not Rules.outside(
						origin + Vector3.new(x, 2, z),
						origin,
						arena:GetAttribute("F3LowerY"),
						arena:GetAttribute("F3OuterRadius")
					),
					"corner inside elimination bounds"
				)
			end
		end
		check(
			Rules.outside(
				Vector3.new(origin.X, arena:GetAttribute("F3LowerY"), origin.Z),
				origin,
				arena:GetAttribute("F3LowerY"),
				arena:GetAttribute("F3OuterRadius")
			),
			"lower plane eliminates"
		)
	end)
	arena:Destroy()
	return { passed = passed, error = if passed then nil else tostring(failure), checks = checks }
end
