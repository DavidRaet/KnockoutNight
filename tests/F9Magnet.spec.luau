return function(Magnet, Fist, Config)
	local count = 0
	local function check(value, message)
		assert(value, "F9 Magnet: " .. message)
		count += 1
	end
	check(
		Magnet.Cooldown == 12 and Magnet.PullSpeed == 28 and Magnet.PullDuration == 0.55,
		"approved pull and cooldown"
	)
	check(Magnet.Startup == 0.12 and Magnet.Duration == 0.32 and Magnet.CanJump, "timing and user jump")
	check(Magnet.Height == 5 and Magnet.StopDistance == 3 and Magnet.Protection == 0.35, "band, stop and shield")
	check(Magnet.contains(20, 0, 1, 0), "inclusive range")
	check(not Magnet.contains(20.001, 0, 1, 0), "outside range")
	check(Magnet.contains(0, 0, 1, 0), "coincident roots")
	check(
		20 - Magnet.PullSpeed * Magnet.PullDuration <= 6,
		"maximum-range stationary target finishes within six-stud Paddle reach"
	)
	for _, angle in { -30, -29, 0, 29, 30, 31, -31, 90, 180 } do
		check(
			Magnet.contains(8 * math.cos(math.rad(angle)), 8 * math.sin(math.rad(angle)), 1, 0)
				== (math.abs(angle) <= 30),
			"cone boundary " .. angle
		)
	end
	local function candidate(id, alignment, distance, eligible)
		return { id = id, alignment = alignment, distance = distance, eligible = eligible ~= false }
	end
	local a, b, c = candidate(4, 1, 9), candidate(3, 0.9, 4), candidate(2, 1, 9)
	check(Magnet.select({ a, b }) == a, "alignment before distance")
	check(Magnet.select({ a, candidate(1, 1, 8) }).id == 1, "distance before ID")
	check(Magnet.select({ a, c }) == c and Magnet.select({ c, a }) == c, "exact tie stable ID in both orders")
	a.eligible = false
	check(Magnet.select({ a, b }) == b, "protected or obstructed best candidate excluded")
	check(Magnet.select({ a }) == nil and Magnet.select({}) == nil, "no eligible target misses")
	check(Magnet.speed(10, 1 / 60, 0.25) == 28, "full pull speed")
	check(math.abs(Magnet.speed(10, 0.02, 0.01) - 14) < 1e-8, "final partial frame respects duration budget")
	check(math.abs(Magnet.speed(3.1, 0.1, 0.25) - 1) < 1e-8, "stop distance clamps velocity")
	check(Magnet.speed(2, 0.1, 0.25) == 0 and Magnet.speed(10, 0.1, 0) == 0, "inside stop and expired pull")
	local function actor(id, profile, started)
		return {
			player = { UserId = id },
			protectionUntil = 0,
			action = { id = id, config = profile, started = started or 0, encountered = {} },
		}
	end
	local function contact(source, target, at)
		return { attacker = source, victim = target, action = source.action, time = at }
	end
	a, b = actor(1, Magnet), actor(2, Config, 0.1)
	local hits, canceled = Fist.resolve({ contact(a, b, 0.12) }, Config)
	check(#hits == 1 and next(canceled) == nil, "pull preserves target startup")
	a, b = actor(1, Magnet), actor(2, Config)
	hits, canceled = Fist.resolve({ contact(a, b, 0.12), contact(b, a, 0.10) }, Config)
	check(#hits == 1 and canceled[a.action], "earlier weapon cancels pending pull")
	a, b = actor(1, Magnet), actor(2, Config)
	hits, canceled = Fist.resolve({ contact(a, b, 0.12), contact(b, a, 0.13) }, Config)
	check(#hits == 2 and not canceled[a.action], "later hit cannot cancel begun pull; user gets no shield")
	a, b, c = actor(1, Magnet), actor(2, Config), actor(3, Config)
	hits, canceled = Fist.resolve({ contact(a, b, 0.12), contact(c, b, 0.13) }, Config)
	check(#hits == 1 and next(canceled) == nil, "pull protection blocks later displacement and interruption")
	a, b = actor(1, Magnet), actor(2, Config)
	b.protectionUntil = 1
	hits, canceled = Fist.resolve({ contact(a, b, 0.12) }, Config)
	check(#hits == 0 and next(canceled) == nil and b.protectionUntil == 1, "protected pull no effect or extension")
	return { passed = true, checks = count }
end
