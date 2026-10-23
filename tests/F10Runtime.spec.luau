-- Engine integration fixture. The generated harness embeds the checked combat source,
-- substituting roster/remote/clock dependencies and server ownership for synthetic players.
return function(makeCombat)
	local RunService = game:GetService("RunService")
	local actualPlayers = game:GetService("Players")
	local events, roster, shields, checks, observations = {}, {}, {}, {}, {}
	local alive = true
	local owned = {}
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "F10EngineFixture", workspace
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
			return alive
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
			Name = "F10Actor" .. id,
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
		assert(value, "F10 engine: " .. message)
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
		a:SetAttribute("F10Ability", "Bounce")
		b:SetAttribute("F10Ability", "Magnet")
		a:SetAttribute("F2Weapon", "SpringFist")
		b:SetAttribute("F2Weapon", weapon or "SpringFist")
		alive = true
		local ar = equip(a, Vector3.new(0, 104, 0))
		local br = equip(b, Vector3.new(distance, 104, 0))
		task.wait(0.1)
		table.clear(events)
		return ar, br
	end

	local passed, failure = pcall(function()
		local ar = reset(25)
		check(not request(a, "bounce", Vector3.zero), "staging rejects Bounce")
		check(not a:GetAttribute("F10ReadyAt"), "staging spends nothing")
		allowed = true
		for _, bad in { Vector3.new(0 / 0, 0, 0), Vector3.new(math.huge, 0, 0), Vector3.yAxis, Vector3.xAxis * 2 } do
			check(not request(a, "bounce", bad), "invalid movement vector rejected")
		end
		check(not request(a, "bounce", Vector3.zero, -1), "stale generation rejected")
		check(not request(a, "magnet"), "unequipped Magnet rejected")
		check(not a:GetAttribute("F9ReadyAt"), "unequipped rejection spends nothing")
		task.wait(0.06)
		shields[a] = world:GetServerTimeNow() + 3
		ar.AssemblyLinearVelocity = Vector3.new(99, -40, 10)
		Combat.resetMovement(a)
		check(request(a, "bounce", Vector3.zero), "grounded straight-up Bounce accepted")
		check(ar.AssemblyLinearVelocity == Vector3.new(0, 180, 0), "launch replaces falling and horizontal velocity")
		local deadline = a:GetAttribute("F10ReadyAt")
		check(math.abs(deadline - world:GetServerTimeNow() - 10) < 0.05, "ten-second cooldown starts at acceptance")
		check(shields[a] == 0, "Bounce ends spawn protection")
		check(ar:GetAttribute("F2ProtectionUntil") == 0, "Bounce grants no protection")
		check(#observations == 0, "self launch creates no knockout attribution")
		check(
			ar:GetNetworkOwner() == nil and not a.Character.Humanoid.EvaluateStateMachine,
			"launch is initially server-owned"
		)
		task.wait(0.06)
		check(
			not ar:GetAttribute("F2Displaced") and a.Character.Humanoid.EvaluateStateMachine,
			"launch restores ordinary airborne motor"
		)
		check(not request(a, "press"), "attack during primary delay rejected")
		task.wait(0.12)
		check(not ar:GetAttribute("F2ActionUntil"), "rejected early primary never buffers")
		check(request(a, "press"), "ordinary airborne attack after primary delay accepted")
		task.wait(0.55)
		check(not request(a, "bounce", Vector3.zero), "repeat during cooldown rejected")
		check(a:GetAttribute("F10ReadyAt") == deadline, "rejection preserves deadline")
		offset += 10
		task.wait(0.06)
		check(request(a, "bounce", Vector3.zero), "cooldown expiry permits another activation")
		deadline = a:GetAttribute("F10ReadyAt")
		Combat.retire(a, "death")
		equip(a, Vector3.new(0, 104, 0))
		check(a:GetAttribute("F10ReadyAt") == deadline, "death and replacement preserve cooldown")
		check(not request(a, "bounce", Vector3.zero), "respawn cannot bypass cooldown")
		Combat.retire(a, "fresh-match")
		equip(a, Vector3.new(0, 104, 0))
		check(not a:GetAttribute("F10ReadyAt"), "fresh match and sudden death reset cooldown")
		check(request(a, "bounce", Vector3.new(1, 0, 1).Unit), "diagonal Bounce accepted")
		ar = a.Character.HumanoidRootPart
		check(
			math.abs(Vector3.new(ar.AssemblyLinearVelocity.X, 0, ar.AssemblyLinearVelocity.Z).Magnitude - 96) < 0.001,
			"diagonal horizontal speed is exactly 96"
		)
		check(ar.AssemblyLinearVelocity.Y == 180, "diagonal retains upward speed")
		task.wait(0.2)
		for _, weapon in { "SpringFist", "WreckingHammer", "PaddlePops" } do
			ar = reset(25, weapon)
			a:SetAttribute("F2Weapon", weapon)
			task.wait(0.06)
			check(request(a, "press"), weapon .. " starts")
			task.wait(0.06)
			check(not request(a, "bounce", Vector3.zero), weapon .. " cannot self-cancel startup")
			check(not a:GetAttribute("F10ReadyAt"), "busy rejection spends nothing")
			ar = reset(25, weapon)
			check(request(a, "bounce", Vector3.zero), weapon .. " accepts Bounce")
			task.wait(0.18)
			check(request(a, "press"), weapon .. " ordinary aerial attack works")
		end
		ar = reset(3)
		check(request(a, "press"), "victim begins interruptible attack")
		check(request(b, "press", -Vector3.xAxis), "opponent weapon begins")
		-- Reset victim startup later so the earlier opponent contact interrupts it.
		task.wait(0.04)
		a.Character:SetAttribute("F2Equipped", false)
		a.Character:SetAttribute("F2Equipped", true)
		task.wait()
		check(request(a, "press"), "victim starts later attack")
		task.wait(0.06)
		check(ar:GetAttribute("F2ReactionUntil") > world:GetServerTimeNow(), "weapon hit reaction active")
		local protection = ar:GetAttribute("F2ProtectionUntil")
		local credit = #observations
		check(request(a, "bounce", -Vector3.xAxis), "Bounce escapes ordinary hit reaction after interruption")
		check(ar.AssemblyLinearVelocity == Vector3.new(-96, 180, 0), "Bounce reverses knockback")
		check(ar:GetAttribute("F2ProtectionUntil") == protection, "existing hit protection retained")
		check(#observations == credit, "Bounce preserves enemy attribution without adding credit")
		ar = reset(6)
		b:SetAttribute("F10Ability", "Gust")
		check(request(b, "gust", -Vector3.xAxis), "Gust stun fixture begins")
		task.wait(0.15)
		check(ar:GetAttribute("F2ReactionUntil") > world:GetServerTimeNow(), "Gust stun active")
		check(not request(a, "bounce", Vector3.zero), "Gust stun blocks Bounce")
		check(not a:GetAttribute("F10ReadyAt"), "stun rejection spends nothing")
		task.wait(0.25)
		check(request(a, "bounce", -Vector3.xAxis), "Bounce allowed after Gust stun")
		ar = reset(9)
		check(request(b, "magnet", -Vector3.xAxis), "Magnet pull begins")
		task.wait(0.15)
		check(ar:GetAttribute("F9Pulling"), "victim is being pulled")
		check(request(a, "bounce", -Vector3.xAxis), "Bounce escapes Magnet")
		check(
			not ar:GetAttribute("F9Pulling") and ar.AssemblyLinearVelocity == Vector3.new(-96, 180, 0),
			"pull ends and full launch replaces it"
		)
		task.wait(0.12)
		check(not ar:GetAttribute("F9Pulling"), "old Magnet cannot resume pull")
		ar = reset(25)
		alive = false
		check(not request(a, "bounce", Vector3.zero), "elimination cutoff rejects Bounce")
		check(not a:GetAttribute("F10ReadyAt"), "eliminated rejection spends nothing")
		ar = reset(25)
		ar.CFrame += Vector3.yAxis * 12
		ar.AssemblyLinearVelocity = Vector3.new(20, -50, 0)
		Combat.resetMovement(a)
		check(request(a, "bounce", -Vector3.xAxis), "airborne falling activation accepted")
		check(ar.AssemblyLinearVelocity == Vector3.new(-96, 180, 0), "falling velocity fully replaced")
		task.wait(0.15)
		check(ar.AssemblyLinearVelocity.Y < 180, "gravity continues without hover")
		ar = reset(25)
		local ceiling = Instance.new("Part")
		ceiling.Anchored, ceiling.Size, ceiling.Position, ceiling.Parent =
			true, Vector3.new(15, 1, 15), ar.Position + Vector3.yAxis * 5, folder
		local underside = ceiling.Position.Y - 0.5
		check(request(a, "bounce", Vector3.zero), "Bounce under ceiling accepted")
		task.wait(0.15)
		check(ar.Position.Y < underside and ar.AssemblyLinearVelocity.Y < 20, "platform underside blocks launch")
		ceiling:Destroy()
		ar = reset(25)
		local wall = Instance.new("Part")
		wall.Anchored, wall.Size, wall.Position, wall.Parent =
			true, Vector3.new(1, 30, 15), ar.Position + Vector3.new(4, 7, 0), folder
		check(request(a, "bounce", Vector3.xAxis), "Bounce toward wall accepted")
		task.wait(0.18)
		check(ar.Position.X < wall.Position.X - 0.5, "wall blocks physical launch")
		wall:Destroy()
		ar = reset(25)
		check(request(a, "bounce", Vector3.zero), "cleanup launch accepted")
		a.Character.Humanoid.Health = 0
		task.wait(0.05)
		check(not ar:GetAttribute("F2Displaced") and not ar:GetAttribute("F10PrimaryAt"), "death clears launch state")
		check(a:GetAttribute("F10ReadyAt"), "death keeps cooldown ledger")
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
