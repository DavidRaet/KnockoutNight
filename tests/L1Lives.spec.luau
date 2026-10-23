return function(makeLives)
	local checks, roster, retired = {}, {}, {}
	local removing = Instance.new("BindableEvent")
	local players = {
		PlayerRemoving = removing.Event,
		GetPlayers = function()
			return roster
		end,
	}
	local combat = {
		retire = function(player, reason)
			retired[player] = reason
		end,
	}
	local Lives = makeLives(players, combat)
	local arena, frames, points, fallback = require(game.ServerScriptService.L1SkyBridges).build()
	arena.Parent = workspace
	local events = {}
	local function check(value, message)
		assert(value, "L1 lives: " .. message)
		table.insert(checks, message)
	end
	local owner = {
		canJoin = function()
			return true
		end,
		allowed = function()
			return true
		end,
		respawns = function()
			return true
		end,
		session = function()
			return 1
		end,
		commit = function()
			return true
		end,
		fail = function() end,
	}
	local function create(player, frame)
		local character = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name, root.Anchored, root.Size = "HumanoidRootPart", true, Vector3.new(2, 2, 1)
		root.CFrame, root.Parent = frame, character
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = character
		character.Parent = workspace
		if player.Character then
			player.Character:Destroy()
		end
		player.Character = character
		return character
	end
	for home = 1, 2 do
		local attributes = {}
		local event = Instance.new("BindableEvent")
		table.insert(events, event)
		local p = { Parent = players, UserId = home, DisplayName = "L1Actor" .. home, CharacterRemoving = event.Event }
		function p:SetAttribute(name, value)
			attributes[name] = value
		end
		function p:GetAttribute(name)
			return attributes[name]
		end
		table.insert(roster, p)
	end
	local passed, failure = pcall(function()
		Lives.bindMatch(owner)
		Lives.start(create, arena, points, fallback)
		for home, player in roster do
			Lives.add(player, frames[home], home)
			Lives.reset(player)
			Lives.freeze(player, false, false)
			check(Lives.alive(player), "home " .. home .. " starts alive beyond old Platform bounds")
		end
		local function respawn(player)
			local before = player:GetAttribute("F3Life")
			check(Lives.eliminate(player, before, "L1-test"), "elimination commits once")
			check(not Lives.eliminate(player, before, "duplicate"), "duplicate elimination is rejected")
			task.wait(require(game.ReplicatedStorage.F3Config).RespawnDelay + 0.05)
			Lives.step()
			return player:GetAttribute("F3Life") == before + 1
		end
		for home, player in roster do
			check(respawn(player), "home " .. home .. " respawns")
			local delta = player.Character.HumanoidRootPart.Position - frames[home].Position
			check(Vector3.new(delta.X, 0, delta.Z).Magnitude <= 6.1, "respawn remains on home " .. home)
			check(player.Character:FindFirstChild("F3SpawnShield") ~= nil, "respawn retains protection")
		end
		for _, marker in points do
			if marker:GetAttribute("F3Home") == 1 then
				marker:SetAttribute("F3SpawnAvailable", false)
			end
		end
		check(respawn(roster[1]), "unavailable home pool uses existing fallback")
		check(
			(roster[1].Character.HumanoidRootPart.Position - fallback.Position).Magnitude < 0.01,
			"fallback uses center rather than opponent home"
		)
		roster[1].Character.HumanoidRootPart.Position = Vector3.new(0, arena:GetAttribute("F3LowerY"), 40)
		Lives.step()
		check(roster[1]:GetAttribute("F3Status") == "eliminated", "interior void eliminates through arena lower plane")
		Lives.resetRound(roster)
		for home, player in roster do
			check(
				(player.Character.HumanoidRootPart.Position - frames[home].Position).Magnitude < 0.01,
				"round reset restores opening home " .. home
			)
		end
		fallback:SetAttribute("F3SpawnAvailable", false)
		check(
			Lives.eliminate(roster[1], roster[1]:GetAttribute("F3Life"), "unsafe-fallback"),
			"failure-path elimination accepted"
		)
		task.wait(require(game.ReplicatedStorage.F3Config).RespawnDelay + 0.05)
		Lives.step()
		check(roster[1]:GetAttribute("F3Status") == "stopped", "unsafe home and fallback stop session visibly")
	end)
	Lives.stop()
	workspace:SetAttribute("F3SessionError", nil)
	for _, player in roster do
		if player.Character then
			player.Character:Destroy()
		end
	end
	for _, event in events do
		event:Destroy()
	end
	removing:Destroy()
	arena:Destroy()
	return { passed = passed, error = if passed then nil else tostring(failure), checks = checks }
end
