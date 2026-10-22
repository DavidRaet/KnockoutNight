return function(Rules)
	local checks = 0
	local config = { OpeningCountdown = 3, RegulationDuration = 10, ResultsDuration = 8 }
	local function check(value, message)
		assert(value, "F5 rules: " .. message)
		checks += 1
	end
	local function fresh()
		local state = Rules.new(1, { "a", "b" }, 0, config)
		Rules.step(state, 3, {}, config)
		Rules.commit(state, 1, "a", 1, 4, "regulation-a")
		Rules.commit(state, 1, "b", 1, 4, "regulation-b")
		Rules.step(state, 13, {}, config)
		check(state.phase == "sudden-death-pending", "F4 hands off tied regulation")
		Rules.readySuddenDeath(state, 13, { 2, 2 }, config)
		check(not Rules.allowed(state, 15.999), "reset countdown rejects combat")
		check(not Rules.commit(state, 1, "a", 2, 15, {}), "reset countdown rejects eliminations")
		Rules.step(state, 16, {}, config)
		check(state.phase == "sudden-death" and not state.deadline, "GO starts untimed sudden death")
		check(state.scores[1] == 1 and state.scores[2] == 1, "regulation score survives reset")
		return state
	end
	for _, first in { "a", "b" } do
		local second = if first == "a" then "b" else "a"
		for _, offset in { 0, 0.199999, 0.2, 0.200001 } do
			local s = fresh()
			local event = { victim = first }
			check(not Rules.commit(s, 1, first, 1, 17, {}), "old regulation life rejected after GO")
			check(not Rules.commit(s, 0, first, 2, 17, {}), "stale session rejected")
			check(Rules.commit(s, 1, first, 2, 17, event), "first loss accepted in either event order")
			check(not Rules.commit(s, 1, first, 2, 17, {}), "duplicate first loss rejected")
			check(#Rules.step(s, 17.1, {}, config) == 0 and not s.result, "hold attribution until window resolves")
			local accepted = Rules.commit(s, 1, second, 2, 17 + offset, {})
			check(accepted == (offset <= 0.2), "inclusive boundary; late opposing commitment rejected")
			local events = Rules.step(s, 20, {}, config)
			check(s.scores[1] == 1 and s.scores[2] == 1, "no overtime points")
			if offset <= 0.2 then
				check(not s.result and s.phase == "sudden-death-pending", "mutual loss requests complete reset")
				check(#events == 1 and events[1].system ~= nil, "one neutral feed event replaces both losses")
			else
				check(s.result.outcome == "sudden-death", "delayed scheduling cannot admit late mutual loss")
				check(s.result.winner == (if first == "a" then 2 else 1), "first loss opponent wins")
				check(#events == 1 and events[1] == event, "decisive loss retains original attribution")
			end
			check(#Rules.step(s, 21, {}, config) == 0, "duplicate updates cannot duplicate feed/reset")
		end
	end
	local s = fresh()
	for round = 1, 12 do
		local now, life = 20 + round * 4, round + 1
		if round > 1 then
			Rules.readySuddenDeath(s, now - 3, { life, life }, config)
			check(
				not s.firstLoss and not s.mutual and not s.deadline,
				"reset clears prior decision and overtime deadline"
			)
			Rules.step(s, now, {}, config)
		end
		check(not Rules.commit(s, 1, "a", life - 1, now, {}), "old round callback rejected")
		check(Rules.commit(s, 1, "a", life, now, {}), "fresh round life accepted")
		check(Rules.commit(s, 1, "b", life, now + 0.2, {}), "repeated exact-boundary mutual accepted")
		check(not Rules.commit(s, 1, "b", life, now + 0.2, {}), "duplicate mutual callback rejected")
		local events = Rules.step(s, now + 1, {}, config)
		check(s.phase == "sudden-death-pending" and not s.result and #events == 1, "no round cap")
	end
	for _, phase in { "sudden-death-countdown", "sudden-death" } do
		for _, leaver in { "a", "b" } do
			local d = fresh()
			if phase == "sudden-death-countdown" then
				d.phase = "sudden-death-pending"
				Rules.readySuddenDeath(d, 17, { 3, 3 }, config)
			else
				check(
					Rules.commit(d, 1, if leaver == "a" then "b" else "a", 2, 17, {}),
					"remaining player already eliminated"
				)
			end
			local events = Rules.step(d, 17.2, { [leaver] = true }, config)
			check(d.result.outcome == "forfeit", "departure overrides countdown or pending outcome")
			check(d.result.winner == (if leaver == "a" then 2 else 1), "connected eliminated player wins by forfeit")
			check(
				#events == 0 and d.result.scores[1] == 1 and d.result.scores[2] == 1,
				"forfeit preserves score and discards pending feed"
			)
		end
	end
	s = fresh()
	Rules.commit(s, 1, "a", 2, 17, {})
	Rules.step(s, 17.199999, {}, config)
	check(not s.result and Rules.allowed(s, 17.2), "window remains open through equality")
	Rules.step(s, 17.2, {}, config)
	check(s.result and s.result.winner == 2, "single loss resolves at window close")
	check(not Rules.commit(s, 1, "b", 2, 17.2, {}), "final result cannot be rewritten")
	local result = s.result
	Rules.step(s, 18, { b = true }, config)
	check(s.result == result, "departures after finalization do not rewrite result")
	s = fresh()
	Rules.step(s, 1000000, {}, config)
	check(s.phase == "sudden-death" and Rules.allowed(s, 1000000), "no overtime timeout")
	Rules.commit(s, 1, "a", 2, 1000001, {})
	Rules.commit(s, 1, "b", 2, 1000001.1, {})
	local events = Rules.step(s, 1000001.1, { b = true }, config)
	check(
		s.result.outcome == "forfeit" and s.result.winner == 1 and #events == 0,
		"departure overrides pending mutual reset"
	)
	s = fresh()
	Rules.commit(s, 1, "a", 2, 17, {})
	Rules.step(s, 17.1, { a = true, b = true }, config)
	check(s.result.outcome == "abandoned" and not s.result.winner, "both players departing produces no winner")
	return { passed = true, checks = checks }
end
