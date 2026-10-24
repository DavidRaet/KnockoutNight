local Dispatch = {}

function Dispatch.new()
	return { serial = 0 }
end

function Dispatch.step(state, queue, now, duration)
	if state.active then
		return nil
	end
	local first, second = queue[1], queue[2]
	if not second then
		state.pair, state.deadline = nil, nil
		return nil
	end
	if not state.pair or state.pair[1] ~= first or state.pair[2] ~= second then
		state.pair, state.deadline = { first, second }, now + duration
	end
	if now < state.deadline then
		return nil
	end
	state.serial += 1
	state.active = { id = state.serial, roster = state.pair }
	state.pair, state.deadline = nil, nil
	table.remove(queue, 1)
	table.remove(queue, 1)
	return state.active
end

function Dispatch.release(state, id)
	if not state.active or state.active.id ~= id then
		return false
	end
	state.active = nil
	return true
end

return Dispatch
