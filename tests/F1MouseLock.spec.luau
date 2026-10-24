return function(Movement)
	local checks = 0
	local function check(value, message)
		assert(value, "Mouse lock: " .. message)
		checks += 1
	end
	check(Movement.captureMouse(true, true, false), "default lock rotates without holding right mouse")
	check(not Movement.captureMouse(true, false, false), "opt-out releases cursor")
	check(Movement.captureMouse(true, false, true), "optional right drag still works after opt-out")
	for _, locked in { true, false } do
		for _, rightMouse in { true, false } do
			check(
				not Movement.captureMouse(false, locked, rightMouse),
				"menus, selection and disabled controls always release cursor"
			)
		end
	end
	check(Movement.captureMouse(true, true, false), "closing menu restores chosen lock mode")
	check(not Movement.captureMouse(true, false, false), "closing menu preserves opt-out")
	local speed = math.rad(120)
	check(
		math.abs(Movement.turn(0, true, false, 0.5, speed) - math.rad(60)) < 1e-8,
		"left arrow turns left at configured speed"
	)
	check(
		math.abs(Movement.turn(0, false, true, 0.5, speed) - math.rad(300)) < 1e-8,
		"right arrow turns right with yaw wrap"
	)
	check(Movement.turn(1, true, true, 1, speed) == 1, "opposing arrows cancel")
	check(Movement.turn(1, false, false, 1, speed) == 1, "released arrows stop rotation")
	local yaw = 0
	for _ = 1, 60 do
		yaw = Movement.turn(yaw, true, false, 1 / 60, speed)
	end
	check(math.abs(yaw - Movement.turn(0, true, false, 1, speed)) < 1e-8, "turning speed is frame-rate independent")
	return { passed = true, checks = checks }
end
