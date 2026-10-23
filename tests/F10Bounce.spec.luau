return function(Bounce)
	local checks = 0
	local function check(value, message)
		assert(value, "F10 Bounce: " .. message)
		checks += 1
	end
	check(Bounce.Cooldown == 10, "cooldown is ten seconds")
	check(Bounce.PrimaryDelay == 0.15, "primary delay is 0.15 seconds")
	local x, y, z = Bounce.components(0, 0)
	check(x == 0 and y == 90 and z == 0, "no input launches straight up")
	for _, direction in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 0.5, -0.5 } } do
		x, y, z = Bounce.components(direction[1], direction[2])
		check(math.abs(math.sqrt(x * x + z * z) - 48) < 1e-9, "all nonzero directions normalize to 48")
		check(y == 90, "horizontal direction never changes upward launch")
		check(x * direction[1] + z * direction[2] > 0, "launch follows movement direction")
	end
	return { passed = true, checks = checks }
end
