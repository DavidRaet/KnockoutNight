-- Engine integration fixture. The generated harness embeds the checked combat source,
-- substituting roster/remote/clock dependencies and server ownership for synthetic players.
return function(makeCombat)
	local Contact = require(game.ServerScriptService.F2Contact)
	local actualPlayers = game:GetService("Players")
	local events, roster, shields, checks, observations = {}, {}, {}, {}, {}
	local alive = true
	local owned = {}
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "F11EngineFixture", workspace
	local floor = Instance.new("Part")
	floor:SetAttribute("F11Playable", true)
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
		assert(value, "F11 engine: " .. message)
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
		a:SetAttribute("F2Weapon", "WreckingHammer")
		b:SetAttribute("F2Weapon", weapon or "WreckingHammer")
		alive = true
		local ar = equip(a, Vector3.new(0, 104, 0))
		local br = equip(b, Vector3.new(distance, 104, 0))
		task.wait(0.1)
		table.clear(events)
		return ar, br
	end
	local function advance(seconds)
		offset += seconds
		Combat.step(seconds)
	end
	local function place(p, position, velocity)
		local root = p.Character.HumanoidRootPart
		root.CFrame = CFrame.new(position)
		root.AssemblyLinearVelocity = velocity or Vector3.zero
		Combat.resetMovement(p)
		return root
	end
	local function count(kind, character)
		local n, last = 0, nil
		for _, event in events do
			if event.kind == kind and (not character or event.data.character == character) then
				n += 1
				last = event.data
			end
		end
		return n, last
	end
	local function flight()
		local ar, br = reset(5)
		allowed = true
		check(request(a, "bounce", Vector3.zero), "Q Bounce starts opportunity")
		place(a, Vector3.new(0, 120, 0), Vector3.new(20, 40, 0))
		advance(0.16)
		return ar, br
	end
	local function startSlam()
		local ar, br = flight()
		check(request(a, "press"), "first eligible primary accepted")
		local _, accepted = count("accepted", a.Character)
		check(accepted.ability == "GroundSlam", "Hammer primary selects slam")
		return ar, br
	end
	local passed, failure = pcall(function()
		local ar = reset(25)
		allowed = true
		place(a, Vector3.new(0, 120, 0), -Vector3.yAxis * 20)
		check(request(a, "press"), "ordinary falling primary accepted")
		local _, ordinary = count("accepted", a.Character)
		check(ordinary.ability == nil, "jump/ledge without Bounce does not unlock slam")
		ar = reset(25)
		check(request(a, "bounce", Vector3.zero), "ground-level replication setup launches Bounce")
		advance(0.16)
		check(request(a, "press"), "ascending Bounce primary accepted before replicated height arrives")
		local _, ascending = count("accepted", a.Character)
		check(ascending.ability == "GroundSlam", "ascending supported sample is not mistaken for landing")
		ar = reset(25)
		check(request(a, "bounce", Vector3.zero), "early-click launch")
		advance(0.05)
		check(not request(a, "press"), "primary delay rejects early click")
		place(a, Vector3.new(0, 120, 0))
		advance(0.12)
		check(count("accepted") == 0, "early click does not buffer")
		check(request(a, "press"), "fresh click after delay starts slam")
		local cooldown = a:GetAttribute("F10ReadyAt")
		advance(0.1)
		check(not request(a, "press"), "consumed slam cannot repeat")
		check(a:GetAttribute("F10ReadyAt") == cooldown, "slam does not refresh/spend Bounce")
		ar = startSlam()
		local horizontal = Vector3.new(ar.AssemblyLinearVelocity.X, 0, ar.AssemblyLinearVelocity.Z)
		advance(0.24)
		check(ar.AssemblyLinearVelocity.Y > -90, "no accelerated descent before 0.25")
		advance(0.011)
		check(ar.AssemblyLinearVelocity.Y <= -90, "descent begins after telegraph")
		check(
			Vector3.new(ar.AssemblyLinearVelocity.X, 0, ar.AssemblyLinearVelocity.Z) == horizontal,
			"descent retains horizontal momentum"
		)
		check(request(a, "steer", Vector3.zAxis), "descent accepts steering")
		advance(0.05)
		check(math.abs(ar.AssemblyLinearVelocity.Z) <= 0.401, "steering limited to eight studs/s squared")
		check(
			ar:GetNetworkOwner() == nil and not a.Character.Humanoid.EvaluateStateMachine,
			"descent remains server owned with motor disabled"
		)
		local feet = a.Character.Humanoid.HipHeight + ar.Size.Y / 2
		place(a, Vector3.new(0, 100.5 + feet, 0), -Vector3.yAxis * 90)
		place(b, Vector3.new(5, 100.5 + feet, 0))
		advance(0.01)
		local impacts, impact = count("slam-impact", a.Character)
		check(impacts == 1, "valid landing produces one shockwave")
		check(count("hit", b.Character) == 1, "enemy affected once")
		local br = b.Character.HumanoidRootPart
		check(
			(br.AssemblyLinearVelocity - Vector3.new(55, 13, 0)).Magnitude < 0.001,
			"shockwave applies 55/13 replacement launch"
		)
		check(
			not ar:GetAttribute("F2Displaced") and a.Character.Humanoid.EvaluateStateMachine,
			"landing restores motor/displacement"
		)
		check(
			math.abs(ar.Position.Y - 100.5 - feet) < 0.001 and ar.AssemblyLinearVelocity.Y == 0,
			"landing settles feet and clears downward velocity before handoff"
		)
		check(math.abs(impact.endsAt - world:GetServerTimeNow() - 0.65) < 0.01, "landing recovery is 0.65 seconds")
		advance(0.6)
		check(not request(a, "press"), "recovery rejects attacks")
		check(
			count("slam-impact") == 1 and count("hit", b.Character) == 1,
			"no repeated impact or direct Hammer stacking"
		)
		advance(0.06)
		check(request(a, "press"), "attack restored after recovery")
		local _, after = count("accepted", a.Character)
		check(after.ability == nil, "opportunity consumed after landing")
		ar = startSlam()
		ar.CFrame += Vector3.yAxis * 8
		ar.AssemblyLinearVelocity = Vector3.zero
		advance(0.01)
		check(count("corrected", a.Character) == 0, "bounded Bounce replication burst survives slam ownership handoff")
		ar.CFrame += Vector3.yAxis * 30
		advance(0.01)
		check(count("corrected", a.Character) == 1, "handoff allowance still rejects excessive vertical teleport")

		-- Actual weapon contact must cancel eligibility before activation, but not the armored action.
		for _, activated in { false, true } do
			ar = flight()
			if activated then
				check(request(a, "press"), "armored setup")
			end
			place(a, Vector3.new(0, 120, 0))
			place(b, Vector3.new(4, 120, 0))
			check(request(b, "press", -Vector3.xAxis), "incoming Hammer begins")
			advance(0.5)
			check(count("hit", a.Character) == 1, "incoming weapon redirects attacker")
			check(
				ar.AssemblyLinearVelocity.X < -100 and ar.AssemblyLinearVelocity.Y == 16,
				"incoming Hammer replacement trajectory"
			)
			if activated then
				check(count("cancel", a.Character) == 0, "armor prevents startup cancellation")
				advance(0.1)
				check(ar.AssemblyLinearVelocity.Y == 16, "brief reaction precedes resumed descent")
				advance(0.06)
				check(
					ar.AssemblyLinearVelocity.Y <= -90 and ar.AssemblyLinearVelocity.X < -100,
					"descent resumes redirected trajectory without windup"
				)
				check(count("accepted", a.Character) == 1, "redirect does not restart slam")
			else
				-- Recover displacement naturally, then confirm the expired opportunity stays gone.
				advance(3)
				ar.AssemblyLinearVelocity = Vector3.zero
				advance(0.1)
				check(request(a, "press"), "post-hit primary restored")
				local _, accepted = count("accepted", a.Character)
				check(accepted.ability == nil, "incoming weapon expires unused opportunity")
			end
		end
		ar = flight()
		local feetY = 100.5 + a.Character.Humanoid.HipHeight + ar.Size.Y / 2
		place(a, Vector3.new(0, feetY, 0))
		advance(0.02)
		check(request(a, "press"), "landed primary restored")
		local _, landed = count("accepted", a.Character)
		check(landed.ability == nil, "landing expires unused opportunity")

		ar = startSlam()
		place(a, Vector3.new(0, feetY, 0), -Vector3.yAxis * 90)
		floor:SetAttribute("F11Playable", nil)
		advance(0.3)
		check(count("slam-impact") == 0, "untagged surface cannot impact")
		floor:SetAttribute("F11Playable", true)
		floor.Parent = nil
		advance(0.02)
		check(
			count("slam-impact") == 0 and ar.AssemblyLinearVelocity.Y <= -90,
			"disappearing surface continues falling"
		)
		floor.Parent = folder

		-- Geometry checks use the same production landing/target functions.
		place(a, Vector3.new(0, feetY, 0))
		place(b, Vector3.new(5, feetY, 0))
		local excluded = { a.Character, b.Character }
		local origin = Vector3.new(0, 100.5, 0)
		check(
			Contact.slamLanding({ root = ar, humanoid = a.Character.Humanoid }, ar.Position, excluded),
			"playable top is valid"
		)
		check(
			Contact.slamTarget(
				origin,
				{ root = b.Character.HumanoidRootPart, humanoid = b.Character.Humanoid },
				excluded,
				floor
			),
			"same-surface enemy in radius"
		)
		place(b, Vector3.new(8.5, feetY, 0))
		check(
			Contact.slamTarget(
				origin,
				{ root = b.Character.HumanoidRootPart, humanoid = b.Character.Humanoid },
				excluded,
				floor
			),
			"expanded radius includes enemy at 8.5 studs"
		)
		for _, position in { Vector3.new(10, feetY, 0), Vector3.new(5, feetY + 6, 0), Vector3.new(45, feetY, 0) } do
			place(b, position)
			check(
				not Contact.slamTarget(
					origin,
					{ root = b.Character.HumanoidRootPart, humanoid = b.Character.Humanoid },
					excluded,
					floor
				),
				"range/elevation/void rejects target"
			)
		end
		place(b, Vector3.new(5, feetY, 0))
		local wall = Instance.new("Part")
		wall.Anchored, wall.Size, wall.Position, wall.Parent =
			true, Vector3.new(1, 10, 10), Vector3.new(2.5, 105, 0), folder
		check(
			not Contact.slamTarget(
				origin,
				{ root = b.Character.HumanoidRootPart, humanoid = b.Character.Humanoid },
				excluded,
				floor
			),
			"wall occludes target"
		)
		wall:Destroy()
		local upper = floor:Clone()
		upper.Position, upper.Parent = Vector3.new(0, 106, 0), folder
		place(b, Vector3.new(5, feetY + 6, 0))
		check(
			not Contact.slamTarget(
				origin,
				{ root = b.Character.HumanoidRootPart, humanoid = b.Character.Humanoid },
				excluded,
				floor
			),
			"upper playable floor cannot be hit through floor"
		)
		upper:Destroy()
		place(b, Vector3.new(5, feetY, 0))
		floor.Parent = nil
		place(a, Vector3.new(5, feetY + 3, 0))
		check(
			not Contact.slamLanding({ root = ar, humanoid = a.Character.Humanoid }, ar.Position, excluded),
			"character top cannot create impact"
		)
		floor.Parent = folder
		place(a, Vector3.new(0, 98, 0))
		check(
			not Contact.slamLanding({ root = ar, humanoid = a.Character.Humanoid }, ar.Position, excluded),
			"underside cannot land"
		)
		place(a, Vector3.new(42, 100, 0))
		check(
			not Contact.slamLanding({ root = ar, humanoid = a.Character.Humanoid }, ar.Position, excluded),
			"side/void cannot land"
		)
		-- A narrow gap remains invalid even when both endpoints are supported.
		floor.Size, floor.Position = Vector3.new(2, 1, 10), Vector3.new(0, 100, 0)
		local island = floor:Clone()
		island.Position, island.Parent = Vector3.new(5, 100, 0), folder
		check(
			not Contact.slamTarget(
				origin,
				{ root = b.Character.HumanoidRootPart, humanoid = b.Character.Humanoid },
				excluded,
				floor
			),
			"separate island gap blocks shockwave"
		)
		island:Destroy()
		floor.Size, floor.Position = Vector3.new(80, 1, 80), Vector3.new(0, 100, 0)
		for _, friendly in { true, false } do
			ar = startSlam()
			a.Neutral, b.Neutral, a.Team, b.Team = not friendly, not friendly, "same", "same"
			place(a, Vector3.new(0, feetY, 0), -Vector3.yAxis * 90)
			place(b, Vector3.new(0, feetY, 0))
			advance(0.3)
			check(
				count("hit", b.Character) == (if friendly then 0 else 1),
				"friendly fire exclusion / exact center contact"
			)
			if not friendly then
				check(
					(b.Character.HumanoidRootPart.AssemblyLinearVelocity - Vector3.new(55, 13, 0)).Magnitude < 0.001,
					"exact center launches along committed facing"
				)
			end
		end
		for _, ability in { "Gust", "Magnet" } do
			ar = startSlam()
			b:SetAttribute("F10Ability", ability)
			place(a, Vector3.new(0, 120, 0))
			place(b, Vector3.new(6, 120, 0))
			check(request(b, string.lower(ability), -Vector3.xAxis), ability .. " targets slam")
			advance(0.3)
			check(count("cancel", a.Character) == 0, ability .. " cannot cancel armor")
			if ability == "Magnet" then
				check(
					ar:GetAttribute("F9Pulling") and ar.AssemblyLinearVelocity.X > 0,
					"Magnet redirects slam toward source"
				)
				advance(0.6)
			else
				check(
					ar.AssemblyLinearVelocity.X == -35 and ar.AssemblyLinearVelocity.Y == 6,
					"Gust displaces armored slam"
				)
				advance(0.3)
			end
			check(
				ar.AssemblyLinearVelocity.Y <= -90 and not ar:GetAttribute("F9Pulling"),
				ability .. " releases into resumed descent"
			)
			check(count("accepted", a.Character) == 1, ability .. " does not replay telegraph")
		end
		ar = startSlam()
		shields[b] = world:GetServerTimeNow() + 5
		place(a, Vector3.new(0, feetY, 0), -Vector3.yAxis * 90)
		place(b, Vector3.new(5, feetY, 0))
		advance(0.3)
		check(count("slam-impact") == 1 and count("hit", b.Character) == 0, "shockwave respects spawn protection")
		check(not b.Character.HumanoidRootPart:GetAttribute("F2Displaced"), "protected target receives no launch")
		ar = startSlam()
		b:SetAttribute("F2Weapon", "PaddlePops")
		place(a, Vector3.new(0, 120, 0))
		place(b, Vector3.new(3, 120, 0))
		check(request(b, "press", -Vector3.xAxis), "Paddle attacks slam telegraph")
		advance(0.11)
		check(
			count("hit", a.Character) == 1 and count("cancel", a.Character) == 0,
			"armor resists actual hit during 0.25 telegraph"
		)
		for _, reason in { "fresh-match", "sudden-death-round", "departure" } do
			ar = startSlam()
			Combat.retire(a, reason)
			advance(0.4)
			check(
				not ar:GetAttribute("F2ActionUntil") and not ar:GetAttribute("F2Displaced"),
				reason .. " clears slam and drive"
			)
			check(count("slam-impact") == 0, reason .. " prevents stale impact")
		end
		ar = startSlam()
		a.Character.Humanoid.Health = 0
		task.wait()
		advance(0.4)
		check(
			not ar:GetAttribute("F2Displaced") and not ar:GetAttribute("F2ActionUntil"),
			"elimination cleans armored descent"
		)
		check(count("slam-impact") == 0, "elimination cannot impact")
		check(not request(a, "press"), "eliminated primary rejected")
	end)
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
