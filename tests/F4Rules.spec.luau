return function(Rules)
	local checks = 0
	local config = { OpeningCountdown = 3, RegulationDuration = 10, ResultsDuration = 8 }
	local function check(condition, message)
		assert(condition, "F4 rules: " .. message)
		checks += 1
	end
	local function fresh(id)
		return Rules.new(id or 1, { "a", "b" }, 100, config)
	end
	local function active(id)
		local state = fresh(id)
		Rules.step(state, 103, {}, config)
		return state
	end
	local s = fresh()
	check(not Rules.allowed(s, 102.99), "countdown rejects combat")
	check(not Rules.commit(s, 1, "a", 1, 102, "early"), "countdown rejects eliminations")
	Rules.step(s, 102.99, {}, config)
	check(s.phase == "countdown" and not s.deadline, "timer has not started before GO")
	Rules.step(s, 104, {}, config)
	check(
		s.phase == "regulation" and s.startedAt == 104 and s.deadline == 114,
		"late update enables GO and full regulation together"
	)
	check(Rules.allowed(s, 113.999), "combat permitted before deadline")
	check(not Rules.allowed(s, 114) and not Rules.allowed(s, 115), "deadline equality and late requests rejected")
	check(Rules.commit(s, 1, "a", 1, 113.999, "fall"), "pre-deadline life committed")
	check(not Rules.commit(s, 1, "a", 1, 113.999, "duplicate"), "duplicate callback rejected")
	check(not Rules.commit(s, 1, "b", 1, 114, "equal"), "deadline wins equal commit timestamp")
	check(not Rules.commit(s, 1, "b", 1, 114.1, "late"), "pending post-deadline falls rejected")
	local events = Rules.step(s, 116, {}, config)
	check(#events == 1 and events[1] == "fall", "committed callback drains even after deadline")
	check(
		s.scores[2] == 1 and s.result.winner == 2 and s.result.outcome == "normal",
		"late callback counted before result resolution"
	)
	check(s.result.returnAt == 124, "results retain configurable duration")
	local result = s.result
	Rules.step(s, 117, { a = true, b = true }, config)
	check(s.result == result and s.result.scores[2] == 1, "departures cannot mutate finalized results")
	check(not Rules.finish(s, "forfeit", 1, 118, config), "duplicate finalization rejected")
	check(not Rules.commit(s, 1, "b", 2, 113, "late-delivery"), "uncommitted backdated callback cannot rewrite results")
	check(not pcall(function()
		s.result.scores[2] = 9
	end), "final scores are immutable")
	for _, departures in { { a = true }, { b = true }, { a = true, b = true } } do
		local countdown = fresh()
		Rules.step(countdown, 103, departures, config)
		check(
			countdown.result.outcome == "cancelled" and not countdown.result.winner and not countdown.deadline,
			"departure before same-update GO cancels without result"
		)
	end
	for _, leaver in { "a", "b" } do
		local match = active()
		Rules.commit(match, 1, if leaver == "a" then "b" else "a", 1, 104, "pending-fall")
		local delivered = Rules.step(match, 104, { [leaver] = true }, config)
		check(
			match.result.outcome == "forfeit" and match.result.winner == (if leaver == "a" then 2 else 1),
			"remaining participant wins active 1v1"
		)
		check(
			match.scores[1] == 0 and match.scores[2] == 0 and #delivered == 0,
			"same-update departure discards pending ring-out point and feed"
		)
	end
	s = active()
	Rules.step(s, 104, { a = true, b = true }, config)
	check(s.result.outcome == "abandoned" and not s.result.winner, "both sides empty means no winner")
	s = active()
	Rules.commit(s, 1, "a", 1, 104, "a")
	Rules.commit(s, 1, "b", 1, 104, "b")
	Rules.step(s, 113, {}, config)
	check(
		s.phase == "sudden-death-pending" and not s.result and s.scores[1] == 1 and s.scores[2] == 1,
		"tie preserves score for F5 handoff without a result"
	)
	check(
		not Rules.allowed(s, 114) and not Rules.commit(s, 1, "a", 2, 114, "overtime"),
		"F4 tie handoff freezes combat and scoring"
	)
	Rules.step(s, 114, { b = true }, config)
	check(s.result.outcome == "forfeit" and s.result.winner == 1, "departure during F5 handoff uses active rules")
	for id = 2, 20 do
		local match = active(id)
		check(not Rules.commit(match, id - 1, "a", 1, 104, "stale"), "prior-session callback rejected")
		check(not Rules.commit(match, id, "outsider", 1, 104, "outsider"), "non-roster callback rejected")
		check(match.scores[1] == 0 and match.scores[2] == 0, "fresh sessions start without score leakage")
		check(Rules.commit(match, id, "a", 1, 104, "fresh"), "same life number valid in fresh session")
		Rules.step(match, 104, {}, config)
		check(not Rules.commit(match, id, "a", 1, 105, "duplicate"), "drained callback remains deduplicated")
		check(Rules.commit(match, id, "a", 2, 105, "next-life"), "new life scores independently")
	end
	s = active()
	Rules.finish(s, "interrupted", nil, 105, config)
	check(not s.result.winner and s.result.outcome == "interrupted", "shutdown abandons unfinished match")
	return { passed = true, checks = checks }
end
