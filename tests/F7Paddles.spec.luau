return function(Fist, Paddles, Config)
	local count = 0
	local function check(value, message)
		assert(value, "F7 Paddle Pops: " .. message)
		count += 1
	end
	check(Fist.phase(0, Paddles) == "startup", "activation begins startup")
	check(Fist.phase(0.09999, Paddles) == "startup", "startup lasts 0.10 seconds")
	check(Fist.phase(0.10, Paddles) == "active", "contact begins at 0.10 seconds")
	check(Fist.phase(Paddles.Startup + Paddles.Active, Paddles) == "recovery", "active end is exclusive")
	check(Fist.phase(0.33999, Paddles) == "recovery", "recovery lasts until 0.34 seconds")
	check(Fist.phase(0.34, Paddles) == nil, "action expires without automatic repetition")
	local first, last = Fist.segment(0, 0, 1, Paddles)
	check(first == 0.10 and math.abs(last - 0.18) < 1e-8, "slow update preserves active opportunity")
	check(Fist.segment(0, 0, 0.09, Paddles) == nil, "startup cannot hit")
	check(Fist.segment(0, 0.18, 1, Paddles) == nil, "recovery cannot hit")
	check(Paddles.LaunchSpeed == 30 and Paddles.LaunchUp == 8, "low launch is 30/8")
	check(Paddles.MoveScale == 0.85, "attack movement is 85 percent")
	check(Paddles.Size.X == 3 and Paddles.Size.Y == 4 and Paddles.Size.Z == 4, "compact 3 by 4 by 4 volume")
	check(Paddles.other("Right") == "Left" and Paddles.other("Left") == "Right", "hands alternate symmetrically")
	check(not Fist.canBuffer(0.21999, false, false, Paddles), "early buffering rejected")
	check(Fist.canBuffer(0.22, false, false, Paddles), "buffer opens in final 0.12 seconds")
	check(not Fist.canBuffer(0.34, false, false, Paddles), "expired action cannot buffer")
	check(not Fist.canBuffer(0.23, true, false, Paddles), "only one queued attack")
	check(not Fist.canBuffer(0.23, false, true, Paddles), "restricted actors cannot buffer")
	local function actor(id, config, started)
		return {
			player = { UserId = id },
			protectionUntil = 0,
			action = { id = id, config = config, started = started or 0, encountered = {} },
		}
	end
	local function contact(a, b, time)
		return { attacker = a, victim = b, action = a.action, time = time }
	end
	local a, b = actor(1, Paddles), actor(2, Config)
	local hits, canceled = Fist.resolve({ contact(a, b, 0.10), contact(b, a, 0.13) }, Config)
	check(#hits == 2 and next(canceled) == nil, "already active Fist and Paddles trade")
	a, b = actor(1, Paddles), actor(2, Config, 0.05)
	hits, canceled = Fist.resolve({ contact(a, b, 0.10), contact(b, a, 0.14) }, Config)
	check(#hits == 1 and canceled[b.action], "Paddles interrupt enemy startup")
	a, b = actor(1, Paddles), actor(2, Config)
	hits, canceled = Fist.resolve({ contact(b, a, 0.08), contact(a, b, 0.10) }, Config)
	check(#hits == 1 and canceled[a.action], "Fist interrupts unarmored Paddle startup")
	a, b = actor(1, Paddles), actor(2, Config)
	b.protectionUntil = 0.45
	local blocked
	hits, canceled, blocked = Fist.resolve({ contact(a, b, 0.44) }, Config)
	check(
		#hits == 0 and #blocked == 1 and next(canceled) == nil,
		"protected contact produces feedback without interruption"
	)
	check(b.protectionUntil == 0.45, "blocked contact cannot extend protection")
	check(
		#Fist.resolve({ contact(a, b, 0.46) }, Config) == 0,
		"blocked activation cannot retry after protection expires"
	)
	a = actor(3, Paddles, 0.68)
	check(#Fist.resolve({ contact(a, b, 0.78) }, Config) == 1, "later activation hits after protection expires")
	a = actor(4, Paddles)
	check(#Fist.resolve({ contact(a, b, 0.45) }, Config) == 1, "protection deadline is inclusive for fresh contact")
	a, b = actor(1, Paddles), actor(2, Config)
	b.spawnProtectionUntil = 2
	check(#Fist.resolve({ contact(a, b, 0.10) }, Config) == 0, "spawn protection blocks Paddle effects")
	a, b = actor(1, Paddles), actor(2, Config)
	local c = actor(3, Config)
	check(
		#Fist.resolve({ contact(a, b, 0.10), contact(a, c, 0.10) }, Config) == 2,
		"one slap hits multiple eligible enemies"
	)
	check(#Fist.resolve({ contact(a, b, 0.12) }, Config) == 0, "one hit per victim per activation")
	return { passed = true, checks = count }
end
