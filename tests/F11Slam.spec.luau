return function(Slam, Fist, Config)
	local checks = 0
	local function check(value, message)
		assert(value, "F11: " .. message)
		checks += 1
	end
	check(Slam.Startup == 0.25 and Slam.DownSpeed >= 90, "telegraph and minimum descent")
	check(Slam.Radius == 9 and Slam.Recovery == 0.65, "radius and punish window")
	check(Slam.LaunchSpeed == 55 and Slam.LaunchUp == 13, "weaker replacement launch")
	check(Slam.MoveScale == 0 and Slam.Armored, "committed armored action")
	check(not Fist.canBuffer(100, false, false, Slam), "no slam repeat buffer")
	local x, z = Slam.direction(0, 0, -1, 0)
	check(x == -1 and z == 0, "exact center uses facing")
	x, z = Slam.direction(3, 4, -1, 0)
	check(x == 0.6 and z == 0.8, "radial normalized direction")
	for _, landed in { false, true } do
		local outgoing = { started = 0, config = Slam, landed = if landed then 1 else nil }
		local attacker = { player = { UserId = 1 } }
		local victim = { action = outgoing, protectionUntil = 0 }
		local action = { id = 1, config = Config, encountered = {} }
		local winners, canceled =
			Fist.resolve({ { action = action, attacker = attacker, victim = victim, time = 0.1 } }, Config)
		check(#winners == 1, "armor permits incoming launch")
		check((canceled[outgoing] == true) == landed, "only airborne slam resists interruption")
	end
	return { passed = true, checks = checks }
end
