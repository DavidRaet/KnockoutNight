-- Pure checks: pass actual shared modules from Studio or the standalone runner.
return function(Fist, Config)
	local count = 0
	local function check(value, message)
		assert(value, "Spring Fist: " .. message)
		count += 1
	end
	check(Fist.phase(0, Config) == "startup", "startup begins immediately")
	check(Fist.phase(0.079999, Config) == "startup", "startup lasts 0.08 seconds")
	check(Fist.phase(0.08, Config) == "active", "active begins at 0.08")
	check(Fist.phase(Config.Startup + Config.Active, Config) == "recovery", "active end is exclusive")
	check(Fist.phase(0.5, Config) == nil, "action ends at 0.50")
	check(Fist.phase(-1, Config) == nil, "future actions are not active")
	local first, last = Fist.segment(0, 0, 1, Config)
	check(
		first == Config.Startup and last == Config.Startup + Config.Active,
		"slow update processes only the elapsed active window"
	)
	check(Fist.segment(0, 0, 0.079, Config) == nil, "startup cannot contact")
	check(Fist.segment(0, Config.Startup + Config.Active, 1, Config) == nil, "old volume cannot trail damage")
	check(Fist.reach(0.08, Config) == 1 and Fist.reach(1, Config) == 4, "extension clamps to approved reach")
	check(not Fist.canBuffer(0.379999, false, false, Config), "early buffer rejected")
	check(Fist.canBuffer(0.38, false, false, Config), "buffer begins inclusively at 0.38")
	check(not Fist.canBuffer(0.5, false, false, Config), "buffer ends exclusively at 0.50")
	check(not Fist.canBuffer(0.4, true, false, Config), "extra press cannot replace buffer")
	check(not Fist.canBuffer(0.4, false, true, Config), "hit recovery cannot buffer")
	check(Fist.aim({}) == nil and Fist.aim(0) == nil, "malformed aim rejected")
	local function actor(id, started, actionId)
		return {
			player = { UserId = id },
			protectionUntil = 0,
			action = {
				id = actionId or id,
				started = started or 0,
				encountered = {},
			},
		}
	end
	local function contact(attacker, victim, time)
		return { attacker = attacker, victim = victim, action = attacker.action, time = time }
	end
	local a, b = actor(1), actor(2)
	local hits, canceled = Fist.resolve({ contact(a, b, 0.1), contact(b, a, 0.1) }, Config)
	check(#hits == 2 and next(canceled) == nil, "mutual active hits trade")
	a, b = actor(1), actor(2, 0.05)
	hits, canceled = Fist.resolve({ contact(b, a, 0.15), contact(a, b, 0.1) }, Config)
	check(
		#hits == 1 and canceled[b.action],
		"startup interruption prevents a later active contact in the same slow update"
	)
	a, b = actor(1), actor(2)
	local c = actor(3)
	hits = Fist.resolve({ contact(c, b, 0.11), contact(a, b, 0.1) }, Config)
	check(#hits == 1 and hits[1].attacker == a, "earliest reconstructed incoming contact wins")
	check(c.action.encountered[b], "new protection consumes later opportunities")
	a, b, c = actor(1, 0, 20), actor(2), actor(3, 0, 10)
	hits = Fist.resolve({ contact(a, b, 0.1), contact(c, b, 0.1) }, Config)
	check(#hits == 1 and hits[1].attacker == c, "action ID breaks exact contact ties")
	a, b = actor(1), actor(2)
	b.protectionUntil = 0.35
	hits = Fist.resolve({ contact(a, b, 0.2) }, Config)
	check(
		#hits == 0 and b.protectionUntil == 0.35 and a.action.encountered[b],
		"protected contact consumes opportunity without extending timers"
	)
	hits = Fist.resolve({ contact(a, b, 0.4) }, Config)
	check(#hits == 0, "consumed target cannot be hit again after protection expires")
	a, b, c = actor(1), actor(2), actor(3)
	hits = Fist.resolve({ contact(a, b, 0.1), contact(a, c, 0.11) }, Config)
	check(#hits == 2, "one action may hit multiple enemies")
	hits = Fist.resolve({ contact(a, b, 0.12) }, Config)
	check(#hits == 0, "one action hits each target once")
	return { passed = true, checks = count }
end
