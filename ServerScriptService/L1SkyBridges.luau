local Config = require(game.ReplicatedStorage.F1Config)
local LifeConfig = require(game.ReplicatedStorage.F3Config)
local SkyBridges = {}

function SkyBridges.build()
	local arena = Instance.new("Model")
	arena.Name = "SkyBridges"
	local origin = Config.PlatformCenter
	local thickness, width = 4, 12
	local sideX = 27.5
	local sideZ = math.sqrt(65 * 65 - sideX * sideX)
	local centers = { origin, origin + Vector3.new(-sideX, 0, sideZ), origin + Vector3.new(sideX, 0, sideZ) }
	local radii = { 25, 15, 15 }
	local stone = Color3.fromRGB(171, 175, 164)
	local function part(name, size, frame, playable, color, shape)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, frame
		p.Shape = shape or Enum.PartType.Block
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, playable, playable, false
		p.CastShadow = playable
		p.Material, p.Color = Enum.Material.Slate, color or stone
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if playable then
			p:SetAttribute("F11Playable", true)
		end
		p.Parent = arena
		return p
	end
	for i, center in centers do
		local radius = radii[i]
		part(
			"Island" .. i,
			Vector3.new(thickness, radius * 2, radius * 2),
			CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2),
			true,
			stone,
			Enum.PartType.Cylinder
		)
		part(
			"Rock" .. i,
			Vector3.new(12, radius * 1.65, radius * 1.65),
			CFrame.new(center - Vector3.yAxis * 8) * CFrame.Angles(0, 0, math.pi / 2),
			false,
			Color3.fromRGB(99, 108, 103),
			Enum.PartType.Cylinder
		)
	end
	for i, pair in { { 1, 2 }, { 1, 3 }, { 2, 3 } } do
		local a, b = pair[1], pair[2]
		local direction = (centers[b] - centers[a]).Unit
		-- Overlap the curved shores across the full bridge width, including both corners.
		local insetA = math.sqrt(radii[a] ^ 2 - (width / 2) ^ 2) - 0.25
		local insetB = math.sqrt(radii[b] ^ 2 - (width / 2) ^ 2) - 0.25
		local start, finish = centers[a] + direction * insetA, centers[b] - direction * insetB
		part(
			"Bridge" .. i,
			Vector3.new(width, thickness, (finish - start).Magnitude),
			CFrame.lookAt((start + finish) / 2, finish),
			true,
			Color3.fromRGB(187, 179, 156)
		)
	end

	local frames, points = {}, {}
	local function marker(name, position, home)
		local target = Vector3.new(origin.X, position.Y, origin.Z)
		local frame = if (target - position).Magnitude > 0
			then CFrame.lookAt(position, target)
			else CFrame.new(position)
		local p = part(name, Vector3.one, frame, false)
		p.Transparency = 1
		p:SetAttribute("F3Home", home)
		return p
	end
	for home = 1, 2 do
		local center = centers[home + 1] + Vector3.yAxis * (thickness / 2 + 4)
		local initial = marker("Spawn" .. home, center, home)
		frames[home] = initial.CFrame
		table.insert(points, initial)
		for i, offset in { Vector3.new(-6, 0, 0), Vector3.new(6, 0, 0), Vector3.new(0, 0, -6), Vector3.new(0, 0, 6) } do
			table.insert(points, marker("Respawn" .. home .. "_" .. i, center + offset, home))
		end
	end
	local fallback = marker("EmergencySpawn", origin + Vector3.new(0, thickness / 2 + 4, 0), nil)

	-- Scenery never catches falls, blocks attacks, or shortens the player camera.
	for i, center in centers do
		local outward = if i == 1 then -Vector3.zAxis else Vector3.new(if i == 2 then -1 else 1, 0, 1).Unit
		local ruin = center + outward * (radii[i] + 3)
		part("Ruin" .. i, Vector3.new(3, 9, 3), CFrame.new(ruin + Vector3.yAxis * 4), false)
		part("RuinCap" .. i, Vector3.new(6, 2, 4), CFrame.new(ruin + Vector3.yAxis * 8), false)
		for puff = -1, 1 do
			local cloud = part(
				"Cloud" .. i .. "_" .. puff,
				Vector3.new(35, 10, 26),
				CFrame.new(center + Vector3.new(puff * 20, -40, 0)),
				false,
				Color3.fromRGB(231, 239, 244),
				Enum.PartType.Ball
			)
			cloud.Material, cloud.Transparency = Enum.Material.SmoothPlastic, 0.25
		end
	end
	arena:SetAttribute("F3BoundsCenter", origin)
	arena:SetAttribute("F3LowerY", origin.Y + thickness / 2 - LifeConfig.LowerOffset)
	arena:SetAttribute("F3OuterRadius", 80 + LifeConfig.OuterMargin)
	return arena, frames, points, fallback
end

return SkyBridges
