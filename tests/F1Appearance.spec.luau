return function(runBootstrap)
	local checks = 0
	local function check(value, message)
		assert(value, "Player appearance: " .. message)
		checks += 1
	end
	local function signal()
		local callbacks, event = {}, {}
		function event:Connect(callback)
			table.insert(callbacks, callback)
			return { Disconnect = function() end }
		end
		function event:Fire(...)
			for _, callback in callbacks do
				callback(...)
			end
		end
		return event
	end
	local players = { PlayerAdded = signal(), PlayerRemoving = signal(), lookups = 0, models = {} }
	function players:GetPlayers()
		return {}
	end
	function players:GetHumanoidDescriptionFromUserIdAsync(id)
		self.lookups += 1
		if id == 43 then
			error("intentional appearance lookup failure")
		end
		if id == 44 then
			self.departing.Parent = nil
		end
		return { Identity = id, Shirt = 123, Destroy = function() end }
	end
	local function model(identity)
		local humanoid = { RigType = "R15", SetStateEnabled = function() end }
		local item = { Identity = identity, DescendantAdded = signal() }
		function item:Clone()
			return model(self.Identity)
		end
		function item:FindFirstChildOfClass()
			return humanoid
		end
		function item:SetAttribute() end
		function item:GetDescendants()
			return {}
		end
		function item:PivotTo() end
		function item:Destroy()
			self.destroyed = true
		end
		table.insert(players.models, item)
		return item
	end
	function players:CreateHumanoidModelFromDescriptionAsync(description)
		if description.Identity then
			check(
				description.Shirt == 123
					and description.Head == 0
					and description.HeightScale == 1
					and description.WalkAnimation == 0,
				"compatible clothing remains while body dimensions and animations are standardized"
			)
		end
		return model(description.Identity)
	end
	local spawn = runBootstrap(players)
	local player = { Parent = players, UserId = 42, Name = "AppearanceTester" }
	local first = spawn(player, {}, true)
	check(first and first.Identity == 42, "normal lobby must use the player's appearance, not the blank test template")
	local second = spawn(player, {}, true)
	local arena = spawn(player, {}, false)
	check(second.Identity == 42 and arena.Identity == 42, "appearance survives lobby respawn and arena handoff")
	check(players.lookups == 1, "appearance fetched once per player visit")
	players.PlayerRemoving:Fire(player)
	check(first.destroyed and second.destroyed, "replaced characters are cleaned up")
	local failure = { Parent = players, UserId = 43, Name = "FallbackTester" }
	check(spawn(failure, {}, true) ~= nil, "lookup failure retains a usable R15 fallback")
	local departing = { Parent = players, UserId = 44, Name = "DepartingTester" }
	players.departing = departing
	check(
		spawn(departing, {}, true) == nil and departing.Character == nil,
		"departure during lookup cannot create a late character"
	)
	return { passed = true, checks = checks }
end
