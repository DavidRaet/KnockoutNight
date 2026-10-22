local Rules = {}

function Rules.new(id, roster, now, config)
	assert(#roster == 2 and roster[1] ~= roster[2], "F4 requires two distinct 1v1 participants")
	return {
		id = id,
		roster = table.clone(roster),
		connected = { [roster[1]] = true, [roster[2]] = true },
		scores = { 0, 0 },
		phase = "countdown",
		goAt = now + config.OpeningCountdown,
		pending = {},
		processed = {},
	}
end

function Rules.allowed(state, now)
	return (state.phase == "regulation" and now < state.deadline)
		or (state.phase == "sudden-death" and (not state.firstLoss or now <= state.firstLoss.closesAt))
end

-- The runtime calls this only after the map and both fresh lives have reset.
function Rules.readySuddenDeath(state, now, lives, config)
	assert(state.phase == "sudden-death-pending", "F5 countdown requires a pending complete round reset")
	state.lives = table.clone(lives)
	state.firstLoss, state.mutual = nil, nil
	state.phase, state.goAt = "sudden-death-countdown", now + config.OpeningCountdown
	state.deadline = nil
end

function Rules.commit(state, session, player, life, at, event)
	if session ~= state.id or not Rules.allowed(state, at) or not state.connected[player] then
		return false
	end
	local side = table.find(state.roster, player)
	local key = tostring(side) .. ":" .. tostring(life)
	if not side or state.processed[key] then
		return false
	end
	if state.phase == "sudden-death" then
		if state.lives[side] ~= life or state.mutual then
			return false
		end
		state.processed[key] = true
		if state.firstLoss then
			if side == state.firstLoss.side then
				return false
			end
			state.mutual = true
		else
			state.firstLoss = { side = side, at = at, closesAt = at + 0.2, event = event }
		end
		return true
	end
	state.processed[key] = true
	table.insert(state.pending, { side = side, event = event })
	return true
end

function Rules.finish(state, outcome, winner, now, config)
	if state.result then
		return false
	end
	state.phase = "results"
	state.result = table.freeze({
		session = state.id,
		outcome = outcome,
		winner = winner,
		scores = table.freeze(table.clone(state.scores)),
		returnAt = now + config.ResultsDuration,
	})
	table.clear(state.pending)
	return true
end

-- Called once at the end of an update: departures precede GO and pending scoring.
function Rules.step(state, now, departures, config)
	local events = {}
	if state.result then
		return events
	end
	local departed = false
	for player in departures do
		if state.connected[player] then
			state.connected[player] = nil
			departed = true
		end
	end
	if departed then
		local a, b = state.connected[state.roster[1]], state.connected[state.roster[2]]
		if state.phase == "countdown" then
			Rules.finish(state, "cancelled", nil, now, config)
		else
			Rules.finish(
				state,
				if not a and not b then "abandoned" else "forfeit",
				if a then 1 elseif b then 2 else nil,
				now,
				config
			)
		end
		return events
	end
	if state.phase == "sudden-death" then
		if state.mutual then
			table.insert(events, { session = state.id, system = "DOUBLE KO — sudden death resets.", at = now })
			state.phase = "sudden-death-pending"
		elseif state.firstLoss and now >= state.firstLoss.closesAt then
			table.insert(events, state.firstLoss.event)
			Rules.finish(state, "sudden-death", 3 - state.firstLoss.side, now, config)
		end
		return events
	end
	for _, commit in state.pending do
		state.scores[3 - commit.side] += 1
		table.insert(events, commit.event)
	end
	table.clear(state.pending)
	if state.phase == "countdown" and now >= state.goAt then
		state.phase, state.startedAt, state.deadline = "regulation", now, now + config.RegulationDuration
	elseif state.phase == "sudden-death-countdown" and now >= state.goAt then
		state.phase, state.startedAt = "sudden-death", now
	elseif state.phase == "regulation" and now >= state.deadline then
		if state.scores[1] == state.scores[2] then
			state.phase = "sudden-death-pending"
		else
			Rules.finish(state, "normal", if state.scores[1] > state.scores[2] then 1 else 2, now, config)
		end
	end
	return events
end

return table.freeze(Rules)
