-- Engine integration fixture. The generated harness embeds the checked combat source,
-- substituting roster/remote/clock dependencies and server ownership for synthetic players.
return function(makeCombat)
	local RunService = game:GetService("RunService")
	local actualPlayers = game:GetService("Players")
	local events, roster, shields, checks, observations = {}, {}, {}, {}, {}
	local owned = {}
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "F9EngineFixture", workspace
	local floor = Instance.new("Part")
	floor.Anchored, floor.Size, floor.Position, floor.Parent =
		true, Vector3.new(80, 1, 80), Vector3.new(0, 100, 0), folder
	local description = Instance.new("HumanoidDescription")
	local template = actualPlayers:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	local function signal()
		local event = Instance.new("BindableEvent")
		table.insert(owned, event)
		return event.Event
	end
	local players = {
		PlayerAdded = signal(),
		PlayerRemoving = signal(),
		GetPlayers = function()
			return roster
		end,
	}
	local remote = { OnServerEvent = signal(), Destroy = function() end }
	function remote:FireAllClients(kind, data)
		if kind == "release" and string.sub(data.reason, 1, 7) == "magnet-" then
			for _, p in roster do
				if p.Character and p.Character ~= data.character then
					local delta = p.Character.HumanoidRootPart.Position - data.frame.Position
					data.gap = Vector3.new(delta.X, 0, delta.Z).Magnitude
				end
			end
		end
		table.insert(events, { kind = kind, data = data })
	end
	function remote:FireClient(_, kind, data)
		table.insert(events, { kind = kind, data = data })
	end
	local instances = {
		new = function(class)
			return if class == "RemoteEvent" then remote else Instance.new(class)
		end,
	}
	local offset = 0
	local world = setmetatable({
		GetServerTimeNow = function()
			return workspace:GetServerTimeNow() + offset
		end,
	}, {
		__index = function(_, key)
			return function(_, ...)
				return workspace[key](workspace, ...)
			end
		end,
	})
	local Combat = makeCombat(players, instances, world)
	local allowed = false
	Combat.bindMatch({
		allowed = function()
			return allowed
		end,
	})
	local lives = {
		endProtection = function(p)
			shields[p] = 0
		end,
		alive = function()
			return true
		end,
		protectionUntil = function(p)
			return shields[p] or 0
		end,
		hit = function(_, _, _, weapon)
			table.insert(observations, weapon)
		end,
	}
	for id = 1, 2 do
		local attributes, changed = {}, {}
		local added, removing = Instance.new("BindableEvent"), Instance.new("BindableEvent")
		table.insert(owned, added)
		table.insert(owned, removing)
		local character
		local p = {
			Name = "F9Actor" .. id,
			UserId = id,
			Neutral = true,
			CharacterAdded = added.Event,
			CharacterRemoving = removing.Event,
		}
		function p:GetAttribute(name)
			return attributes[name]
		end
		function p:SetAttribute(name, value)
			if attributes[name] ~= value then
				attributes[name] = value
				if changed[name] then
					changed[name]:Fire()
				end
			end
		end
		function p:GetAttributeChangedSignal(name)
			if not changed[name] then
				changed[name] = Instance.new("BindableEvent")
				table.insert(owned, changed[name])
			end
			return changed[name].Event
		end
		function p:Destroy()
			if character then
				character:Destroy()
			end
		end
		setmetatable(p, {
			__index = function(_, key)
				return if key == "Character" then character else nil
			end,
			__newindex = function(self, key, value)
				if key == "Character" then
					if character then
						removing:Fire(character)
					end
					character = value
					if value then
						added:Fire(value)
					end
				else
					rawset(self, key, value)
				end
			end,
		})
		table.insert(roster, p)
	end
	Combat.start(lives)
	local a, b = roster[1], roster[2]
	local stepConnection = RunService.PreSimulation:Connect(function(dt)
		Combat.step(dt)
		for _, p in roster do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root and root:GetAttribute("F9Pulling") then
				table.insert(observations, {
					speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude,
					owned = root:GetNetworkOwner() == nil,
					at = world:GetServerTimeNow(),
				})
			end
		end
	end)
	local seq = 1000
	local function request(p, kind, aim, generation)
		seq += 1
		return Combat.request(
			p,
			kind,
			generation or p.Character:GetAttribute("F2Generation"),
			seq,
			aim or Vector3.xAxis
		)
	end
	local function check(value, message)
		assert(value, "F9 engine: " .. message)
		table.insert(checks, message)
	end
	local function equip(p, position)
		local old = p.Character
		p.Character = nil
		if old then
			old:Destroy()
		end
		local rig = template:Clone()
		rig.Name, rig.Parent = p.Name, folder
		for _, part in rig:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = "F1Characters"
			end
		end
		rig:PivotTo(CFrame.new(position))
		p.Character = rig
		task.wait(0.05)
		local root = rig.HumanoidRootPart
		root:SetNetworkOwner(nil)
		root.AssemblyLinearVelocity = Vector3.zero
		Combat.resetMovement(p)
		return root
	end
	local function reset(distance, weapon)
		for _, p in roster do
			Combat.retire(p, "fresh-match")
			shields[p] = 0
		end
		a:SetAttribute("F2Weapon", "SpringFist")
		b:SetAttribute("F2Weapon", weapon or "SpringFist")
		local ar = equip(a, Vector3.new(0, 104, 0))
		local br = equip(b, Vector3.new(distance, 104, 0))
		task.wait(0.1)
		table.clear(events)
		return ar, br
	end
	local passed, failure = pcall(function()
		local ar, br = reset(24)
		check(not request(a, "magnet"), "staging rejected")
		check(not a:GetAttribute("F9ReadyAt"), "staging spends nothing")
		allowed = true
		check(not request(a, "magnet", Vector3.new(1, 1, 0)), "bad aim rejected")
		check(not request(a, "magnet", nil, -1), "stale generation rejected")
		check(request(a, "magnet"), "miss accepted")
		local deadline = a:GetAttribute("F9ReadyAt")
		check(math.abs(deadline - world:GetServerTimeNow() - 12) < 0.05, "twelve-second cooldown")
		check(
			a.Character.Humanoid.JumpHeight > 0 and a.Character.Humanoid.WalkSpeed > 0,
			"user keeps movement and jump"
		)
		task.wait(0.06)
		check(not request(a, "press"), "weapon overlap rejected")
		task.wait(0.35)
		check(
			not ar:GetAttribute("F2ActionUntil") and not br:GetAttribute("F9Pulling"),
			"miss cleans action without pull"
		)
		check(
			not request(a, "magnet") and a:GetAttribute("F9ReadyAt") == deadline,
			"cooldown rejection cannot extend deadline"
		)
		local bursts = 0
		for _, event in events do
			if event.kind == "magnet-burst" then
				bursts += 1
			end
		end
		check(bursts == 1, "miss still emits burst")
		ar, br = reset(9, "WreckingHammer")
		check(request(b, "press", -Vector3.xAxis), "target starts Hammer")
		task.wait(0.06)
		check(request(a, "magnet"), "pull accepted")
		local started = world:GetServerTimeNow()
		task.wait(0.15)
		check(br:GetAttribute("F9Pulling") and br:GetNetworkOwner() == nil, "pull is server owned")
		check(
			br:GetAttribute("F2ReactionUntil") == 0 and br:GetAttribute("F2ActionUntil"),
			"pull adds no stun and preserves target startup"
		)
		check(
			b.Character.Humanoid.WalkSpeed == 0 and b.Character.Humanoid.JumpHeight == 0,
			"target movement and jumping locked"
		)
		local shield = br:GetAttribute("F2ProtectionUntil")
		check(shield >= started + 0.12 + 0.35 - 0.02, "protection begins at pull start")
		task.wait(0.25)
		check(
			not br:GetAttribute("F9Pulling") and b.Character.Humanoid.EvaluateStateMachine,
			"pull motor and attributes restore"
		)
		local gap
		for _, event in events do
			if event.kind == "release" and event.data.character == b.Character then
				gap = event.data.gap
			end
		end
		check(gap and math.abs(gap - 3) < 0.15, "pull stops near three studs: " .. tostring(gap))
		check(
			br:GetAttribute("F2ProtectionUntil") < shield
				and br:GetAttribute("F2ProtectionUntil") >= started + 0.12 + 0.35 - 0.02,
			"early completion retains minimum protection without full-duration extension"
		)
		local saw28 = false
		for _, observation in observations do
			if type(observation) == "table" and math.abs(observation.speed - 28) < 0.001 and observation.owned then
				saw28 = true
			end
		end
		check(saw28, "exact 28 studs per second observed")
		ar, br = reset(19.8)
		a:SetAttribute("F2Weapon", "PaddlePops")
		task.wait(0.06)
		check(request(a, "magnet"), "near-maximum-range Magnet accepted")
		task.wait(0.72)
		local distantGap = math.abs(br.Position.X - ar.Position.X)
		check(
			not br:GetAttribute("F9Pulling") and distantGap >= 3 and distantGap < 6,
			"distant target finishes inside Paddle reach: " .. tostring(distantGap)
		)
		check(
			world:GetServerTimeNow() >= br:GetAttribute("F2ProtectionUntil"),
			"long-pull protection expires at completion"
		)
		check(request(a, "press"), "Paddle follow-up accepted after pull")
		task.wait(0.14)
		check(
			br:GetAttribute("F2ReactionUntil") > world:GetServerTimeNow(),
			"six-stud Paddle follow-up hits distant pulled target"
		)
		ar, br = reset(8)
		check(request(a, "magnet"), "response fixture accepted")
		task.wait(0.15)
		check(request(b, "press", -Vector3.xAxis), "target can start weapon during pull")
		task.wait(0.2)
		check(ar:GetAttribute("F2Displaced") ~= nil, "responding weapon can hit unprotected user")
		task.wait(0.3)
		ar, br = reset(8)
		check(request(a, "magnet"), "ability response fixture accepted")
		task.wait(0.15)
		check(request(b, "gust", -Vector3.xAxis), "target can use valid ability during pull")
		task.wait(0.4)
		ar, br = reset(3)
		check(request(b, "press", -Vector3.xAxis), "interrupting weapon begins")
		task.wait(0.02)
		check(request(a, "magnet"), "interruptible startup accepted")
		deadline = a:GetAttribute("F9ReadyAt")
		task.wait(0.15)
		check(
			not ar:GetAttribute("F2ActionUntil") and not br:GetAttribute("F9Pulling"),
			"weapon cancels startup without pull"
		)
		check(a:GetAttribute("F9ReadyAt") == deadline, "interruption spends cooldown")
		check(not request(a, "magnet"), "hit reaction rejects activation")
		task.wait(0.25)
		offset += 12
		check(request(a, "magnet"), "ordinary knockback after reaction permits Magnet")
		task.wait(0.4)
		ar, br = reset(8)
		shields[b] = world:GetServerTimeNow() + 5
		check(request(a, "magnet"), "protected target activation accepted")
		task.wait(0.2)
		check(
			not br:GetAttribute("F9Pulling") and br:GetAttribute("F2ReactionUntil") == 0,
			"spawn-protected target excluded"
		)
		ar, br = reset(8)
		check(request(a, "magnet"), "cleanup fixture starts")
		task.wait(0.15)
		deadline = a:GetAttribute("F9ReadyAt")
		Combat.retire(a, "death")
		check(not br:GetAttribute("F9Pulling"), "source removal releases target immediately")
		check(a:GetAttribute("F9ReadyAt") == deadline, "death retains deadline")
		equip(a, Vector3.new(0, 104, 0))
		check(a:GetAttribute("F9ReadyAt") == deadline, "respawn retains deadline")
		Combat.retire(a, "fresh-match")
		check(not a:GetAttribute("F9ReadyAt"), "fresh match and sudden-death shared reset clears deadline")
		ar, br = reset(8)
		check(request(a, "magnet"), "obstacle fixture starts")
		task.wait(0.15)
		local wall = Instance.new("Part")
		wall.Anchored, wall.Size, wall.Position, wall.Parent =
			true, Vector3.new(0.3, 10, 10), Vector3.new(br.Position.X - 1.4, 104, 0), folder
		local wallX = wall.Position.X
		task.wait(0.1)
		check(not br:GetAttribute("F9Pulling"), "new obstacle stops pull early")
		check(br.Position.X > wallX, "target does not cross solid wall")
		wall:Destroy()
		ar, br = reset(8)
		ar.CFrame += Vector3.yAxis * 20
		br.CFrame += Vector3.yAxis * 20
		ar.AssemblyLinearVelocity, br.AssemblyLinearVelocity = Vector3.new(0, 18, 0), Vector3.new(0, 18, 0)
		Combat.resetMovement(a)
		Combat.resetMovement(b)
		check(request(a, "magnet"), "airborne activation accepted")
		task.wait(0.14)
		check(
			br:GetAttribute("F9Pulling") and br.AssemblyLinearVelocity.Y < 18,
			"airborne pull preserves gravity rather than hovering"
		)
		b.Character.Humanoid.Health = 0
		task.wait(0.05)
		check(not br:GetAttribute("F9Pulling"), "target death cleans pull")
	end)
	stepConnection:Disconnect()
	Combat.stop()
	for _, p in roster do
		p:Destroy()
	end
	for _, event in owned do
		event:Destroy()
	end
	template:Destroy()
	folder:Destroy()
	return {
		passed = passed,
		error = if passed then nil else tostring(failure),
		checks = checks,
		observations = observations,
	}
end
