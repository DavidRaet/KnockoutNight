local Config = require(game.ReplicatedStorage.F1Config)
local Arenas = {}

function Arenas.build(name)
	local arena, spawnFrames, spawnPoints, fallback
	if name == "SkyBridges" then
		arena, spawnFrames, spawnPoints, fallback = require(script.Parent.L1SkyBridges).build()
	elseif name == "Dungeon" then
		arena, spawnFrames, spawnPoints, fallback = require(script.Parent.L2Dungeon).build()
	else
		assert(name == "ThePlatform", "F1 launch requires a supported arena: ThePlatform, SkyBridges, or Dungeon")
		arena = Instance.new("Model")
		arena.Name = "F1Platform"
		local platform = Instance.new("Part")
		platform.Name = "Surface"
		platform.Shape = Enum.PartType.Cylinder
		platform.Size = Vector3.new(Config.PlatformThickness, Config.PlatformDiameter, Config.PlatformDiameter)
		platform.CFrame = CFrame.new(Config.PlatformCenter) * CFrame.Angles(0, 0, math.pi / 2)
		platform.Anchored = true
		platform.CanCollide = true
		platform:SetAttribute("F11Playable", true)
		platform.Material = Enum.Material.Concrete
		platform.Color = Color3.fromRGB(155, 160, 168)
		platform.TopSurface = Enum.SurfaceType.Smooth
		platform.BottomSurface = Enum.SurfaceType.Smooth
		platform.Parent = arena

		spawnFrames = {}
		spawnPoints = {}
		for index, sign in { -1, 1 } do
			local position = Config.PlatformCenter
				+ Vector3.new(sign * Config.SpawnOffset, Config.PlatformThickness / 2 + 4, 0)
			local facing =
				CFrame.lookAt(position, Vector3.new(Config.PlatformCenter.X, position.Y, Config.PlatformCenter.Z))
			spawnFrames[index] = facing
			local marker = Instance.new("Part")
			marker.Name = "Spawn" .. index
			marker.Size = Vector3.one
			marker.CFrame = facing
			marker.Anchored = true
			marker.CanCollide = false
			marker.CanTouch = false
			marker.CanQuery = false
			marker.Transparency = 1
			marker.Parent = arena
			table.insert(spawnPoints, marker)
		end
		for index = 1, 6 do
			local angle = math.pi / 4 * (if index <= 3 then index else index + 1)
			local position = Config.PlatformCenter
				+ Vector3.new(
					math.cos(angle) * Config.SpawnOffset,
					Config.PlatformThickness / 2 + 4,
					math.sin(angle) * Config.SpawnOffset
				)
			local marker = spawnPoints[1]:Clone()
			marker.Name = "Respawn" .. index
			marker.CFrame =
				CFrame.lookAt(position, Vector3.new(Config.PlatformCenter.X, position.Y, Config.PlatformCenter.Z))
			marker.Parent = arena
			table.insert(spawnPoints, marker)
		end
		fallback = spawnPoints[1]:Clone()
		fallback.Name = "EmergencySpawn"
		fallback.CFrame = CFrame.new(Config.PlatformCenter + Vector3.new(0, Config.PlatformThickness / 2 + 4, 0))
		fallback.Parent = arena
	end

	return arena, spawnFrames, spawnPoints, fallback
end

return Arenas
