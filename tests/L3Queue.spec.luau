return function(Queue)
	local checks = 0
	local function check(value, message)
		assert(value, "L3 queue: " .. message)
		checks += 1
	end
	local queue = {}
	local a, b, c, d = {}, {}, {}, {}
	check(Queue.update(queue, a, true), "first entry joins")
	for _ = 1, 100 do
		check(not Queue.update(queue, a, true), "repeated contacts never duplicate a player")
	end
	check(#queue == 1 and queue[1] == a, "incomplete pair remains queued")
	Queue.update(queue, b, true)
	Queue.update(queue, c, true)
	Queue.update(queue, d, true)
	check(#queue == 4 and queue[1] == a and queue[2] == b, "extra entrants wait behind the next pair")
	Queue.update(queue, a, false)
	check(#queue == 3 and queue[1] == b and queue[2] == c, "departure promotes the oldest remaining players")
	Queue.update(queue, a, true)
	check(queue[4] == a, "re-entry joins the back")
	check(not Queue.update(queue, {}, false), "unknown departure is harmless")
	Queue.update(queue, c, false)
	check(queue[1] == b and queue[2] == d and queue[3] == a, "middle departure preserves order")
	for _, point in { { 0, 3, 0 }, { 9, 3, 8 }, { -9, 3, -8 }, { 0, 10, 0 }, { 0, 15, 0 } } do
		check(Queue.contains(point[1], point[2], point[3], 9, 8), "root and jump positions inside zone are accepted")
	end
	for _, point in
		{
			{ 9.01, 3, 0 },
			{ -9.01, 3, 0 },
			{ 0, 3, 8.01 },
			{ 0, 3, -8.01 },
			{ 0, -0.01, 0 },
			{ 0, 15.01, 0 },
			{ 0 / 0, 3, 0 },
		}
	do
		check(not Queue.contains(point[1], point[2], point[3], 9, 8), "outside and invalid roots cannot join")
	end
	for _, player in { b, d, a } do
		Queue.update(queue, player, false)
	end
	check(#queue == 0, "all departures leave a reusable empty queue")
	return { passed = true, checks = checks }
end
