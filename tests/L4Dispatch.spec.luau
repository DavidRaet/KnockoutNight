return function(Dispatch)
	local checks = 0
	local function check(value, message)
		assert(value, "L4 dispatch: " .. message)
		checks += 1
	end
	local state, queue = Dispatch.new(), { "a" }
	check(not Dispatch.step(state, queue, 0, 3) and not state.deadline, "incomplete queue waits")
	table.insert(queue, "b")
	check(not Dispatch.step(state, queue, 1, 3) and state.deadline == 4, "full pair starts countdown")
	table.insert(queue, "c")
	table.insert(queue, "d")
	check(not Dispatch.step(state, queue, 3.99, 3) and state.deadline == 4, "extras do not restart countdown")
	table.remove(queue, 1)
	check(
		not Dispatch.step(state, queue, 4, 3) and state.deadline == 7,
		"expiry rechecks pair and restarts after departure"
	)
	local session = Dispatch.step(state, queue, 7, 3)
	check(session and session.id == 1 and session.roster[1] == "b" and session.roster[2] == "c", "one FIFO assignment")
	check(#queue == 1 and queue[1] == "d", "only assigned pair removed")
	table.insert(queue, "e")
	for now = 8, 108 do
		check(not Dispatch.step(state, queue, now, 3) and #queue == 2, "occupied session blocks duplicate dispatch")
	end
	check(not Dispatch.release(state, 0) and state.active == session, "stale release cannot free allocation")
	check(Dispatch.release(state, 1) and not Dispatch.release(state, 1), "release is exactly once")
	check(
		not Dispatch.step(state, queue, 109, 3) and state.deadline == 112,
		"waiting pair gets fresh countdown after release"
	)
	check(Dispatch.step(state, queue, 112, 3).id == 2, "new assignment gets fresh identity")
	Dispatch.release(state, 2)
	table.insert(queue, "f")
	table.insert(queue, "g")
	Dispatch.step(state, queue, 113, 3)
	table.remove(queue, 2)
	check(not Dispatch.step(state, queue, 116, 3) and not state.deadline, "incomplete pair cancels deadline")
	return { passed = true, checks = checks }
end
