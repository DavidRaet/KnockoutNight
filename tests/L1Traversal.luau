-- One live client, ordinary Humanoid walking through the existing Studio study-input hook.
return function()
	local player = game.Players:GetPlayers()[1]
	assert(player and player.Character, "L1 traversal requires a live client with a character")
	local Match = require(game.ServerScriptService.F4Match)
	local Lives = require(game.ServerScriptService.F3Lives)
	local Combat = require(game.ServerScriptService.F2Combat)
	local originalAllowed = Match.allowed
	local checks, samples = {}, {}
	local root
	local function check(value, message)
		assert(value, "L1 traversal: " .. message)
		table.insert(checks, message)
	end
	local passed, failure = pcall(function()
		Match.allowed = function()
			return true
		end
		Lives.reset(player)
		Lives.freeze(player, false, false)
		root = player.Character.HumanoidRootPart
		local humanoid = player.Character.Humanoid
		local arena = workspace.SkyBridges
		for i, pair in { { 1, 2 }, { 2, 3 }, { 3, 1 } } do
			local start = arena["Island" .. pair[1]].Position + Vector3.yAxis * 5
			local finish = arena["Island" .. pair[2]].Position + Vector3.yAxis * 5
			local direction = (finish - start).Unit
			root:SetAttribute("F2StudyInput", Vector3.zero)
			root.CFrame, root.AssemblyLinearVelocity = CFrame.lookAt(start, finish), Vector3.zero
			Combat.resetMovement(player)
			task.wait(0.5)
			root:SetAttribute("F2StudyInput", direction)
			local deadline, minY, maxY, jumped = os.clock() + 8, math.huge, -math.huge, false
			repeat
				task.wait(0.03)
				minY, maxY = math.min(minY, root.Position.Y), math.max(maxY, root.Position.Y)
				jumped = jumped or humanoid:GetState() == Enum.HumanoidStateType.Jumping
			until (root.Position - start):Dot(direction) >= (finish - start).Magnitude - 2 or os.clock() >= deadline
			root:SetAttribute("F2StudyInput", Vector3.zero)
			local delta = root.Position - finish
			local gap = Vector3.new(delta.X, 0, delta.Z).Magnitude
			table.insert(samples, { route = i, gap = gap, minY = minY, maxY = maxY, jumped = jumped })
			check(gap < 3, "route " .. i .. " reaches destination using walking")
			check(
				minY > start.Y - 3 and maxY < start.Y + 1 and not jumped,
				"route " .. i .. " crosses both seams without falling or jumping"
			)
			check(
				Lives.alive(player) and player:GetAttribute("F10ReadyAt") == nil,
				"route " .. i .. " stays alive without Bounce"
			)
		end
	end)
	if root and root.Parent then
		root:SetAttribute("F2StudyInput", nil)
	end
	Match.allowed = originalAllowed
	Lives.reset(player)
	Lives.stage(player)
	return { passed = passed, error = if passed then nil else tostring(failure), checks = checks, samples = samples }
end
