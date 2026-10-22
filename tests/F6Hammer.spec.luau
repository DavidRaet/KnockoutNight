return function(Fist, Hammer, Config)
	local count = 0
	local function check(value, message)
		assert(value, "F6 Hammer: " .. message)
		count += 1
	end
	check(Fist.phase(0, Hammer) == "startup", "startup begins at activation")
	check(Fist.phase(0.479999, Hammer) == "startup", "windup lasts 0.48 seconds")
	check(Fist.phase(0.48, Hammer) == "active", "active begins at 0.48 seconds")
	check(Fist.phase(Hammer.Startup + Hammer.Active, Hammer) == "recovery", "active end is exclusive")
	check(Fist.phase(1.309999, Hammer) == "recovery", "recovery remains punishable to 1.31 seconds")
	check(Fist.phase(1.31, Hammer) == nil, "action cleans up at 1.31 seconds")
	local first, last = Fist.segment(0, 0, 3, Hammer)
	check(first == 0.48 and math.abs(last - 0.66) < 1e-8, "slow update covers only active interval")
	check(Fist.segment(0, 0, 0.479, Hammer) == nil, "startup never damages")
	check(Fist.segment(0, Hammer.Startup + Hammer.Active, 3, Hammer) == nil, "recovery never damages")
	check(math.abs(Hammer.angle(0.48) - math.rad(50)) < 1e-8, "sweep begins 50 degrees to one side")
	check(math.abs(Hammer.angle(0.57)) < 1e-8, "sweep crosses committed forward aim")
	check(math.abs(Hammer.angle(0.66) + math.rad(50)) < 1e-8, "sweep ends 50 degrees to other side")
	check(Hammer.EndReach == 7 and Hammer.Size.Z == 7, "radial blade reaches seven studs")
	check(Hammer.LaunchSpeed == 118 and Hammer.LaunchUp == 16, "heavy replacement launch targets 118/16")
	check(Hammer.MoveScale == 0.4, "attack movement is 40 percent throughout")
	check(not Fist.canBuffer(1.189999, false, false, Hammer), "buffer rejects early recovery")
	check(Fist.canBuffer(1.19, false, false, Hammer), "one late buffer starts in final 0.12 seconds")
	check(not Fist.canBuffer(1.31, false, false, Hammer), "buffer ends with action")
	check(not Fist.canBuffer(1.2, true, false, Hammer), "buffer cannot be replaced")
	check(not Fist.canBuffer(1.2, false, true, Hammer), "hit recovery cannot buffer")
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
	local a, b = actor(1, Config), actor(2, Hammer)
	local hits, canceled = Fist.resolve({ contact(b, a, 0.5), contact(a, b, 0.1) }, Config)
	check(#hits == 1 and canceled[b.action], "Fist interrupts unarmored Hammer startup even in slow update")
	a, b = actor(1, Hammer), actor(2, Config, 0.45)
	hits, canceled = Fist.resolve({ contact(b, a, 0.54), contact(a, b, 0.5) }, Config)
	check(#hits == 1 and canceled[b.action], "Hammer interrupts Fist using Fist startup duration")
	a, b = actor(1, Hammer), actor(2, Config, 0.4)
	hits, canceled = Fist.resolve({ contact(a, b, 0.5), contact(b, a, 0.5) }, Config)
	check(#hits == 2 and next(canceled) == nil, "mixed active attacks trade")
	a, b = actor(1, Hammer), actor(2, Hammer)
	hits, canceled = Fist.resolve({ contact(a, b, 0.5), contact(b, a, 0.5) }, Config)
	check(#hits == 2 and next(canceled) == nil, "Hammer active attacks trade without ordinary armor")
	check(#Fist.resolve({ contact(a, b, 0.6) }, Config) == 0, "same activation hits a target only once")
	a, b = actor(1, Hammer), actor(2, Hammer)
	b.protectionUntil = 0.55
	hits, canceled = Fist.resolve({ contact(a, b, 0.5) }, Config)
	check(#hits == 0 and next(canceled) == nil, "protected Hammer startup is not interrupted")
	check(b.protectionUntil == 0.55, "blocked contacts never extend protection")
	check(#Fist.resolve({ contact(a, b, 0.6) }, Config) == 0, "protected contact consumes this activation")
	a, b = actor(1, Hammer), actor(2, Config)
	b.spawnProtectionUntil = 2
	check(#Fist.resolve({ contact(a, b, 0.5) }, Config) == 0, "spawn shield blocks Hammer displacement")
	return { passed = true, checks = count }
end
