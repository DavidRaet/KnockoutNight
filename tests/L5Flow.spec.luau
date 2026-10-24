return function(Flow)
	local checks = 0
	local function check(value, message)
		assert(value, "L5/L6 flow: " .. message)
		checks += 1
	end
	local a, b, stranger = {}, {}, {}
	local state = Flow.new(1, { a, b }, 0)
	check(state.deadline == 10 and state.choices[a].weapon == nil, "vote starts with private blank selections")
	check(not Flow.request(state, stranger, 1, "vote", "Dungeon", 0), "nonparticipant rejected")
	check(not Flow.request(state, a, 0, "vote", "Dungeon", 0), "stale session rejected")
	check(not Flow.request(state, a, 1, "vote", "Unknown", 0), "invalid map rejected")
	check(Flow.request(state, a, 1, "vote", "Dungeon", 1), "vote accepted")
	check(not Flow.request(state, a, 1, "vote", "ThePlatform", 1.01), "requests throttled")
	check(Flow.request(state, a, 1, "vote", "SkyBridges", 2), "vote editable")
	check(Flow.counts(state).Dungeon == 0 and Flow.counts(state).SkyBridges == 1, "one current vote per participant")
	check(not Flow.step(state, 9.99, math.random), "full vote window never ends early")
	check(not Flow.request(state, b, 1, "vote", "Dungeon", 10), "deadline vote rejected")
	check(Flow.step(state, 10, math.random) == "load" and state.map == "SkyBridges", "unique vote leader wins")
	check(not Flow.step(state, 11, math.random), "arena load emitted once")
	Flow.select(state, 12)
	check(state.deadline == 27, "fifteen seconds begin after arena arrival")
	check(Flow.request(state, a, 1, "weapon", "WreckingHammer", 12), "private valid weapon accepted")
	check(Flow.request(state, a, 1, "ready", nil, 13), "ready accepts missing ability default")
	check(not Flow.step(state, 13, math.random), "one ready waits for opponent")
	check(Flow.request(state, a, 1, "ability", "Bounce", 14) and not state.choices[a].ready, "edit clears Ready")
	check(not Flow.request(state, b, 1, "ability", "Unknown", 15), "unavailable ability rejected")
	check(not Flow.request(state, b, 1, "weapon", {}, 16), "malformed choice rejected")
	check(Flow.request(state, a, 1, "ready", nil, 17), "reconfirm accepted")
	check(Flow.request(state, b, 1, "ready", nil, 17), "blank ready accepted")
	check(Flow.step(state, 17, math.random) == "start", "both ready ends selection early")
	check(
		state.choices[a].weapon == "WreckingHammer" and state.choices[a].ability == "Bounce",
		"valid choices retained"
	)
	check(
		state.choices[b].weapon == "SpringFist" and state.choices[b].ability == "Gust",
		"blank choices independently default"
	)
	check(not state.choices[a].defaultWeapon and state.choices[b].defaultAbility, "default explanation flags correct")
	check(not Flow.request(state, a, 1, "weapon", "PaddlePops", 18), "locked choices immutable")
	check(not Flow.step(state, 30, math.random), "start emitted once")
	for index, map in Flow.Maps do
		local empty = Flow.new(index, { a, b }, 0)
		Flow.step(empty, 10, function(first, last)
			check(first == 1 and last == 3, "no votes includes all maps")
			return index
		end)
		check(empty.map == map, "empty vote random can select each map")
	end
	local tied = Flow.new(2, { a, b }, 0)
	Flow.request(tied, a, 2, "vote", "ThePlatform", 0)
	Flow.request(tied, b, 2, "vote", "Dungeon", 0)
	Flow.step(tied, 10, function(_, last)
		check(last == 2, "tie includes leaders only")
		return last
	end)
	check(tied.map == "Dungeon", "tie random chooses among leaders")
	for _, weapon in Flow.Weapons do
		for _, ability in Flow.Abilities do
			local loadout = Flow.new(3, { a, b }, 0)
			Flow.step(loadout, 10, function()
				return 1
			end)
			Flow.select(loadout, 10)
			Flow.request(loadout, a, 3, "weapon", weapon, 11)
			Flow.request(loadout, a, 3, "ability", ability, 12)
			check(not Flow.request(loadout, a, 3, "weapon", "SpringFist", 25), "choice at selection deadline rejected")
			check(Flow.step(loadout, 25, math.random) == "start", "deadline locks without Ready")
			check(
				loadout.choices[a].weapon == weapon and loadout.choices[a].ability == ability,
				"all nine loadouts retained"
			)
		end
	end
	local partial = Flow.new(4, { a, b }, 0)
	Flow.step(partial, 10, function()
		return 1
	end)
	Flow.select(partial, 10)
	Flow.request(partial, a, 4, "ability", "Magnet", 11)
	Flow.request(partial, b, 4, "weapon", "PaddlePops", 11)
	Flow.step(partial, 25, math.random)
	check(
		partial.choices[a].weapon == "SpringFist" and partial.choices[a].ability == "Magnet",
		"missing weapon does not replace valid ability"
	)
	check(
		partial.choices[b].weapon == "PaddlePops" and partial.choices[b].ability == "Gust",
		"missing ability does not replace valid weapon"
	)
	return { passed = true, checks = checks }
end
