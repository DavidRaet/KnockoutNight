return function(Gust, Fist, Config)
	local checks = 0
	local function check(value, message)
		assert(value, "F8 Gust: " .. message)
		checks += 1
	end
	check(Gust.Cooldown == 15 and Gust.Range == 12 and Gust.Cone == 60, "approved cooldown and cone")
	check(Gust.LaunchSpeed == 35 and Gust.LaunchUp == 6, "approved replacement launch")
	check(Gust.Startup == 0.12 and Gust.Recovery == 0.20 and Gust.Duration == 0.32, "approved action timing")
	check(Gust.contains(0, -12, 0, -1), "inclusive range boundary")
	check(not Gust.contains(0, -12.001, 0, -1), "outside range misses")
	check(not Gust.contains(0, 1, 0, -1), "behind misses")
	check(Gust.contains(0, 0, 0, -1), "coincident roots are in cone")
	for _, angle in { -30, -29, 0, 29, 30 } do
		check(
			Gust.contains(math.sin(math.rad(angle)) * 8, -math.cos(math.rad(angle)) * 8, 0, -1),
			"inside cone " .. angle
		)
	end
	for _, angle in { -31, 31, 90, 180 } do
		check(
			not Gust.contains(math.sin(math.rad(angle)) * 8, -math.cos(math.rad(angle)) * 8, 0, -1),
			"outside cone " .. angle
		)
	end
	check(Gust.contains(12, 0, 1, 0) and not Gust.contains(0, -8, 1, 0), "rotated committed aim")
	local function actor(id, config, started)
		return {
			player = { UserId = id },
			protectionUntil = 0,
			action = { id = id, config = config, started = started or 0, encountered = {} },
		}
	end
	local function contact(a, b, at)
		return { attacker = a, victim = b, action = a.action, time = at }
	end
	local a, b, c = actor(1, Gust), actor(2, Config, 0.10), actor(3, Config)
	local hits, canceled = Fist.resolve({ contact(a, b, 0.12), contact(a, c, 0.12) }, Config)
	check(
		#hits == 2 and canceled[b.action] and not canceled[c.action],
		"multi-target Gust interrupts startup and preserves active attacks"
	)
	check(#Fist.resolve({ contact(a, b, 0.5) }, Config) == 0, "each activation consumes target once")
	a, b = actor(1, Gust), actor(2, Config)
	b.protectionUntil = 1
	hits, canceled = Fist.resolve({ contact(a, b, 0.12) }, Config)
	check(
		#hits == 0 and next(canceled) == nil and b.protectionUntil == 1,
		"protection blocks without extension or interruption"
	)
	a, b = actor(1, Gust), actor(2, Config)
	hits, canceled = Fist.resolve({ contact(a, b, 0.12), contact(b, a, 0.10) }, Config)
	check(#hits == 1 and canceled[a.action], "weapon startup hit cancels queued Gust effect")
	a, b = actor(1, Gust), actor(2, Config)
	hits, canceled = Fist.resolve({ contact(a, b, 0.12), contact(b, a, 0.13) }, Config)
	check(#hits == 2 and not canceled[a.action], "already applied Gust is not undone")
	check(Gust.Reaction == 0.25 and Config.Reaction == 0.15, "Gust stun is quarter-second; weapon reaction unchanged")
	a, b = actor(1, Gust), actor(2, Config, 0.10)
	b.protectionUntil = 1
	hits, canceled = Fist.resolve({ contact(a, b, 0.12) }, Config)
	check(#hits == 0 and next(canceled) == nil, "protected startup is not interrupted")
	a, b = actor(1, Gust), actor(2, Config, 0.04)
	hits, canceled = Fist.resolve({ contact(a, b, 0.12) }, Config)
	check(#hits == 1 and not canceled[b.action], "active boundary preserves target attack")
	return { passed = true, checks = checks }
end
