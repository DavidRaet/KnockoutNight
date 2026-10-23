local Test = game:GetService("StudioTestService")
local ok, args = pcall(function()
	return Test:GetTestArgs()
end)
if not ok or type(args) ~= "table" or args.test ~= "F8Combat" then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Combat = require(game.ServerScriptService.F2Combat)
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local Contact = require(game.ServerScriptService.F2Contact)
local fixture = Instance.new("RemoteEvent")
fixture.Name, fixture.Parent = "F8CombatTest", Storage
local ready, snapshots, checks, errors, launches = {}, {}, {}, {}, {}
local originalStep = Combat.step
Combat.step = function(dt)
	originalStep(dt)
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and root.AssemblyLinearVelocity == Vector3.new(35, 6, 0) then
			table.insert(launches, { owned = root:GetNetworkOwner() == nil, player = p.Name })
		end
	end
end
local log = game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		table.insert(errors, message)
	end
end)
local connection = fixture.OnServerEvent:Connect(function(p, kind, data)
	if kind == "ready" then
		ready[p] = true
	elseif kind == "snapshot" then
		snapshots[p.Name] = data
	end
end)
local timeout = task.delay(110, function()
	Test:EndTest({ passed = false, error = "F8 fixture timeout" })
end)
local passed, failure = pcall(function()
	local function check(value, message)
		assert(value, "F8 combat: " .. message)
		table.insert(checks, message)
	end
	local function waitFor(predicate, seconds, message)
		local untilAt = os.clock() + seconds
		while not predicate() and os.clock() < untilAt do
			task.wait()
		end
		check(predicate(), message)
	end
	waitFor(function()
		local r = Lives.roster()
		return #r == 2 and ready[r[1]] and ready[r[2]]
	end, 25, "two clients ready")
	local list = Lives.roster()
	local a, b = list[1], list[2]
	check(not Combat.request(a, "gust", 0, 1, Vector3.xAxis), "staging Gust rejected")
	check(not a:GetAttribute("F8ReadyAt"), "staging rejection spends nothing")
	check(Match.chooseWeapon(b, "WreckingHammer"), "Hammer target selected")
	check(Match.begin(), "match begins")
	waitFor(function()
		return Match.allowed(workspace:GetServerTimeNow())
	end, 7, "GO")
	for _, p in list do
		p:SetAttribute("F1ControlsEnabled", false)
	end
	local origin = Vector3.new(-3, 45, 0)
	local seq = 10000
	local function reset(p, position, shield)
		if not shield then
			Lives.endProtection(p)
		end
		Lives.freeze(p, false)
		local c = p.Character
		c:SetAttribute("F2Equipped", false)
		c:SetAttribute("F2Equipped", true)
		local r = c.HumanoidRootPart
		r:SetNetworkOwner(nil)
		r.CFrame = CFrame.lookAt(position, position + Vector3.xAxis)
		r.AssemblyLinearVelocity, r.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		c.Humanoid:Move(Vector3.zero, false)
		Combat.resetMovement(p)
		return r
	end
	local function request(p, kind, aim, gen)
		seq += 1
		return Combat.request(p, kind, gen or p.Character:GetAttribute("F2Generation"), seq, aim or Vector3.xAxis)
	end
	local ar, br = reset(a, origin), reset(b, origin + Vector3.xAxis * 18)
	check(not request(a, "gust", Vector3.new(1, 1, 0)), "nonhorizontal aim rejected")
	check(not request(a, "gust", nil, -1), "stale generation rejected")
	check(not a:GetAttribute("F8ReadyAt"), "invalid requests spend nothing")
	check(request(b, "press"), "weapon accepted")
	task.wait(0.06)
	check(not request(b, "gust"), "weapon overlap rejected")
	check(not b:GetAttribute("F8ReadyAt"), "busy rejection spends nothing")
	task.wait(0.5)
	fixture:FireClient(a, "gust", Vector3.xAxis)
	waitFor(function()
		return a:GetAttribute("F8ReadyAt") ~= nil
	end, 2, "real client Gust accepted")
	local deadline = a:GetAttribute("F8ReadyAt")
	check(deadline - workspace:GetServerTimeNow() > 14.7, "fifteen-second cooldown starts at acceptance")
	task.wait(0.06)
	check(not request(a, "press"), "weapon cannot overlap Gust")
	task.wait(0.35)
	check(not ar:GetAttribute("F2ActionUntil"), "miss completes and cleans action")
	check(a:GetAttribute("F8ReadyAt") == deadline, "miss spends cooldown")
	check(not request(a, "gust"), "cooldown rejects reactivation")
	check(a:GetAttribute("F8ReadyAt") == deadline, "rejection does not extend cooldown")
	-- Geometry uses actual R15 body parts, with independent per-target walls.
	local rig = a.Character:Clone()
	if not rig then
		a.Character.Archivable = true
		rig = a.Character:Clone()
	end
	assert(rig, "F8 geometry needs a cloned R15 rig")
	rig.Parent = workspace
	for _, p in rig:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide = true, false
			p.CFrame = CFrame.new(500, 500, 500)
		end
	end
	local hand = rig.RightHand
	hand.Size = Vector3.one
	local victim = { character = rig, root = rig.HumanoidRootPart }
	local geometryOrigin = Vector3.new(0, 200, 0)
	local function geometry(offset, height)
		victim.root.CFrame = CFrame.new(geometryOrigin + offset)
		hand.CFrame = CFrame.new(geometryOrigin + offset + Vector3.yAxis * (height or 0))
		return Contact.gust(geometryOrigin, Vector3.xAxis, victim, { rig, a.Character, b.Character })
	end
	check(geometry(Vector3.new(12, 0, 0)) ~= nil, "inclusive twelve-stud geometry")
	check(geometry(Vector3.new(12.01, 0, 0)) == nil, "outside range excluded")
	check(geometry(Vector3.new(-2, 0, 0)) == nil, "behind excluded")
	check(geometry(Vector3.new(6, 0, 2)) ~= nil, "inside cone exposed")
	check(geometry(Vector3.new(6, 0, 4)) == nil, "outside cone excluded")
	check(geometry(Vector3.new(6, 0, 0), 2.99) ~= nil, "partial body vertical overlap")
	check(geometry(Vector3.new(6, 0, 0), 3.01) == nil, "no vertical overlap excluded")
	local wall = Instance.new("Part")
	wall.Anchored, wall.Size, wall.CFrame, wall.Parent =
		true, Vector3.new(0.5, 12, 2), CFrame.new(geometryOrigin + Vector3.xAxis * 3), workspace
	check(geometry(Vector3.new(6, 0, 0)) == nil, "solid target obstruction excludes contact")
	check(geometry(Vector3.new(6, 0, 3.2)) ~= nil, "other cone target remains exposed")
	wall.CanCollide = false
	check(geometry(Vector3.new(6, 0, 0)) ~= nil, "nonsolid scenery does not obstruct")
	wall:Destroy()
	rig:Destroy()
	-- Revised Gust interrupts weapon startup and extends action lock to 0.25 seconds.
	waitFor(function()
		return workspace:GetServerTimeNow() >= deadline
	end, 16, "cooldown expires")
	ar, br = reset(a, origin), reset(b, origin + Vector3.xAxis * 11)
	check(request(b, "press", -Vector3.xAxis), "target Hammer starts")
	task.wait(0.06)
	check(request(a, "gust"), "Gust accepted against target startup")
	deadline = a:GetAttribute("F8ReadyAt")
	check(ar:GetAttribute("F2ActionAim") == Vector3.xAxis, "aim committed on acceptance")
	check(Combat.request(a, "aim", a.Character:GetAttribute("F2Generation"), 0, Vector3.zAxis), "camera aim can change")
	check(ar:GetAttribute("F2ActionAim") == Vector3.xAxis, "camera cannot redirect action")
	task.wait(0.2)
	check(#launches > 0 and launches[#launches].owned, "exact 35/6 server-owned launch observed")
	check(not br:GetAttribute("F2ActionUntil"), "Gust interrupts target Hammer startup from eleven studs")
	local protection = br:GetAttribute("F2ProtectionUntil")
	check(protection and protection > workspace:GetServerTimeNow(), "Gust grants shared protection")
	check(
		math.abs((br:GetAttribute("F2ProtectionUntil") - br:GetAttribute("F2ReactionUntil")) - 0.10) < 0.001,
		"Gust stun is 0.25 seconds under unchanged 0.35 protection"
	)
	task.wait(0.12)
	check(
		not request(b, "gust", -Vector3.xAxis),
		"Gust counter rejected after old reaction ends but before new stun ends"
	)
	check(not b:GetAttribute("F8ReadyAt"), "stunned rejection spends no cooldown")
	task.wait(0.12)
	check(request(b, "gust", -Vector3.xAxis), "counter ability available after quarter-second stun")
	task.wait(0.6)
	-- Startup interrupted by a weapon; spent cooldown survives character/equip cleanup.
	waitFor(function()
		return workspace:GetServerTimeNow() >= deadline
	end, 16, "second cooldown expires")
	b:SetAttribute("F2Weapon", "SpringFist")
	ar, br = reset(a, origin), reset(b, origin + Vector3.xAxis * 3)
	check(request(b, "press", -Vector3.xAxis), "Fist windup begins")
	task.wait(0.02)
	check(request(a, "gust"), "Gust starts before incoming Fist active")
	deadline = a:GetAttribute("F8ReadyAt")
	task.wait(0.12)
	check(not ar:GetAttribute("F2ActionUntil"), "weapon interrupts Gust startup")
	check(a:GetAttribute("F8ReadyAt") == deadline, "interrupted cooldown not refunded")
	check(not request(a, "gust"), "hit recovery rejects Gust")
	task.wait(1.6)
	reset(a, origin)
	check(a:GetAttribute("F8ReadyAt") == deadline, "equip cleanup cannot reset cooldown")
	local old = a.Character
	check(Lives.eliminate(a, a:GetAttribute("F3Life"), "F8-cleanup"), "Gust owner eliminated")
	waitFor(function()
		return a.Character ~= old and a:GetAttribute("F3Status") == "alive"
	end, 8, "fresh character respawns")
	check(a:GetAttribute("F8ReadyAt") == deadline, "cooldown survives death and respawn")
	ar = reset(a, origin, true)
	br = reset(b, origin + Vector3.xAxis * 6)
	local spawnDeadline = Lives.protectionUntil(a)
	check(spawnDeadline > workspace:GetServerTimeNow(), "respawn shield active")
	check(request(b, "gust", -Vector3.xAxis), "Gust accepted against spawn shield")
	task.wait(0.2)
	check(not ar:GetAttribute("F2Displaced"), "protected Gust causes no displacement")
	check(ar:GetAttribute("F2ReactionUntil") == 0, "protected Gust causes no reaction")
	check(Lives.protectionUntil(a) == spawnDeadline, "protected contact does not extend shield")
	Lives.resetRound(list)
	check(not a:GetAttribute("F8ReadyAt"), "fresh round reset clears cooldown")
	waitFor(function()
		return a:GetAttribute("F3Status") == "alive" and b:GetAttribute("F3Status") == "alive"
	end, 8, "fresh round characters ready")
	ar = reset(a, Vector3.new(0, 65, 0))
	reset(b, Vector3.new(18, 65, 0))
	ar.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
	check(request(a, "gust"), "airborne Gust accepted")
	check(ar.AssemblyLinearVelocity == Vector3.new(0, -10, 0), "activation adds no lift or hover")
	task.wait(0.15)
	check(ar.AssemblyLinearVelocity.Y < -10, "airborne startup does not suspend gravity")
	task.wait(0.25)
	check(not ar:GetAttribute("F2ActionUntil"), "airborne Gust completes cleanup")
	check(not request(a, "gust"), "post-round Gust still spends cooldown")
	for _, p in list do
		fixture:FireClient(p, "snapshot")
	end
	waitFor(function()
		return snapshots[a.Name] and snapshots[b.Name]
	end, 4, "both client snapshots")
	for name, s in snapshots do
		check(#s.errors == 0, "no project client errors: " .. name)
		check(s.accepted > 0 and s.bursts > 0 and s.sawBurst and s.sawCue, "accepted cue and burst render: " .. name)
		check(s.sawHud, "Gust HUD visible: " .. name)
		check(s.accepted == s.bursts + 1, "interrupted activation emits no burst: " .. name)
	end
	check(#errors == 0, "no server errors")
end)
task.cancel(timeout)
connection:Disconnect()
log:Disconnect()
Combat.step = originalStep
fixture:Destroy()
Test:EndTest({
	passed = passed,
	error = if passed then nil else tostring(failure),
	checks = checks,
	snapshots = snapshots,
	launches = launches,
	errors = errors,
})
