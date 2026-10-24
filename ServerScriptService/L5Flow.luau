local Flow = {}
Flow.Maps = { "ThePlatform", "SkyBridges", "Dungeon" }
Flow.Weapons = { "SpringFist", "WreckingHammer", "PaddlePops" }
Flow.Abilities = { "Gust", "Magnet", "Bounce" }

function Flow.new(id, roster, now)
	local state =
		{ id = id, roster = roster, phase = "vote", deadline = now + 10, votes = {}, choices = {}, lastRequest = {} }
	for _, player in roster do
		state.choices[player] = { ready = false }
	end
	return state
end

function Flow.request(state, player, id, command, value, now)
	if id ~= state.id or not state.choices[player] or type(command) ~= "string" then
		return false
	end
	if now - (state.lastRequest[player] or -math.huge) < 0.1 then
		return false
	end
	state.lastRequest[player] = now
	if command == "sync" then
		return true
	end
	if now >= state.deadline then
		return false
	end
	if command == "vote" and state.phase == "vote" and table.find(Flow.Maps, value) then
		state.votes[player] = value
		return true
	end
	local choice = state.choices[player]
	if state.phase ~= "selection" then
		return false
	end
	if command == "weapon" and table.find(Flow.Weapons, value) then
		choice.weapon, choice.ready = value, false
	elseif command == "ability" and table.find(Flow.Abilities, value) then
		choice.ability, choice.ready = value, false
	elseif command == "ready" then
		choice.ready = true
	else
		return false
	end
	return true
end

function Flow.counts(state)
	local counts = { ThePlatform = 0, SkyBridges = 0, Dungeon = 0 }
	for _, map in state.votes do
		counts[map] += 1
	end
	return counts
end

function Flow.step(state, now, random)
	if state.phase == "vote" and now >= state.deadline then
		local counts, leaders, most = Flow.counts(state), {}, -1
		for _, map in Flow.Maps do
			if counts[map] > most then
				leaders, most = { map }, counts[map]
			elseif counts[map] == most then
				table.insert(leaders, map)
			end
		end
		state.map, state.phase = leaders[random(1, #leaders)], "loading"
		return "load"
	elseif state.phase == "selection" then
		local ready = true
		for _, choice in state.choices do
			ready = ready and choice.ready
		end
		if ready or now >= state.deadline then
			for _, choice in state.choices do
				choice.defaultWeapon, choice.defaultAbility = choice.weapon == nil, choice.ability == nil
				choice.weapon, choice.ability = choice.weapon or "SpringFist", choice.ability or "Gust"
			end
			state.phase, state.lockedAt = "match", now
			return "start"
		end
	end
	return nil
end

function Flow.select(state, now)
	assert(state.phase == "loading", "L5 loadout selection requires a completed map vote and arena load")
	state.phase, state.deadline = "selection", now + 15
end

return Flow
