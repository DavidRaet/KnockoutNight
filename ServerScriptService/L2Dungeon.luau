local Config = require(game.ReplicatedStorage.F1Config)
local LifeConfig = require(game.ReplicatedStorage.F3Config)
local Dungeon = {}

function Dungeon.build()
	local arena = Instance.new("Model")
	arena.Name = "Dungeon"
	local origin = Config.PlatformCenter
	local width, thickness = 80, 4
	local top = origin.Y + thickness / 2
	local function part(name, size, position, playable)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = name, size, position
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, playable, playable, false
		p.Material, p.Color = Enum.Material.Slate, Color3.fromRGB(116, 111, 105)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if playable then
			p:SetAttribute("F11Playable", true)
		end
		p.Parent = arena
		return p
	end
	part("Surface", Vector3.new(width, thickness, width), origin, true)
	local ball = part("MockWreckingBall", Vector3.one * 10, Vector3.new(origin.X, top + 13, origin.Z), false)
	ball.Shape, ball.Material, ball.Color = Enum.PartType.Ball, Enum.Material.Metal, Color3.fromRGB(65, 68, 73)
	for i = 1, 8 do
		local link = part("ChainLink" .. i, Vector3.new(0.8, 1.5, 0.8), ball.Position + Vector3.yAxis * (5 + i), false)
		link.Material, link.Color = ball.Material, ball.Color
		link.CFrame *= CFrame.Angles(0, if i % 2 == 0 then math.pi / 2 else 0, 0)
		link.Size = Vector3.new(0.4, 1.5, 1)
	end
	for i, sign in { -1, 1 } do
		local post = part("SupportPost" .. i, Vector3.new(2, 28, 2), origin + Vector3.new(sign * 38, 16, 0), false)
		post.Material, post.Color = ball.Material, ball.Color
	end
	local beam = part("SupportBeam", Vector3.new(78, 2, 2), origin + Vector3.yAxis * 29, false)
	beam.Material, beam.Color = ball.Material, ball.Color
	local frames, points = {}, {}
	local function marker(name, position, home)
		local p = part(name, Vector3.one, position, false)
		local target = Vector3.new(origin.X, position.Y, origin.Z)
		p.CFrame = if (target - position).Magnitude > 0 then CFrame.lookAt(position, target) else CFrame.new(position)
		p.Transparency = 1
		p:SetAttribute("F3Home", home)
		return p
	end
	for home, sign in { -1, 1 } do
		local center = origin + Vector3.new(sign * 20, thickness / 2 + 4, 0)
		local initial = marker("Spawn" .. home, center, home)
		frames[home] = initial.CFrame
		table.insert(points, initial)
		for i, offset in { Vector3.new(-6, 0, 0), Vector3.new(6, 0, 0), Vector3.new(0, 0, -6), Vector3.new(0, 0, 6) } do
			table.insert(points, marker("Respawn" .. home .. "_" .. i, center + offset, home))
		end
	end
	local fallback = marker("EmergencySpawn", origin + Vector3.new(0, thickness / 2 + 4, 0), nil)
	arena:SetAttribute("F3BoundsCenter", origin)
	arena:SetAttribute("F3LowerY", top - LifeConfig.LowerOffset)
	arena:SetAttribute("F3OuterRadius", width / math.sqrt(2) + LifeConfig.OuterMargin)
	return arena, frames, points, fallback
end

return Dungeon
