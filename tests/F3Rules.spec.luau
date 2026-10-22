return function(Rules)
	local checks = 0
	local function check(condition, message)
		assert(condition, "F3 rules: " .. message)
		checks += 1
	end
	local center = { X = 0, Y = 40, Z = 0 }
	check(not Rules.outside({ X = 36, Y = 18, Z = 0 }, center, 17, 95), "horizontal edge remains recoverable")
	check(not Rules.outside({ X = 94.99, Y = 17.01, Z = 0 }, center, 17, 95), "inside both limits remains recoverable")
	check(Rules.outside({ X = 0, Y = 17, Z = 0 }, center, 17, 95), "lower plane commits inclusively")
	check(Rules.outside({ X = 95, Y = 45, Z = 0 }, center, 17, 95), "outer bound commits inclusively")
	check(Rules.outside({ X = -68, Y = 45, Z = -68 }, center, 17, 95), "diagonal outer bounds are radial")
	check(Rules.choose({ 10, 30, 20 }, 0) == 2, "farthest eligible point wins")
	check(Rules.choose({ -math.huge, 30, 20 }, 2) == 2, "invalid points are excluded")
	check(Rules.choose({ -math.huge, -math.huge }, 0) == nil, "all unavailable requests fallback")
	check(Rules.choose({ 20, 20, 20 }, 0) == 1, "first equal choice is deterministic")
	check(Rules.choose({ 20, 20, 20 }, 1) == 2, "equal choices rotate")
	check(Rules.choose({ math.huge, math.huge }, 2) == 1, "no-enemy ties wrap")
	local state = { life = 7, status = "alive", score = 9 }
	check(Rules.eliminate(state, 7, 100, 3), "current alive life commits")
	check(state.respawnAt == 103 and state.eliminatedAt == 100, "countdown starts at commitment")
	check(not Rules.eliminate(state, 7, 101, 3), "duplicate callbacks cannot recommit")
	check(state.respawnAt == 103 and state.score == 9, "duplicate callbacks cannot extend delay or reset score")
	state.life, state.status = 8, "alive"
	check(not Rules.eliminate(state, 7, 104, 3), "old callbacks cannot kill a new life")
	check(Rules.eliminate(state, 8, 105, 3), "next life commits independently")
	return { passed = true, checks = checks }
end
