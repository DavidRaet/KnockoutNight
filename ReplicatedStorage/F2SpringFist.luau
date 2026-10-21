local Fist = {}

function Fist.phase(age, config)
	if age < 0 or age >= config.Duration then
		return nil
	end
	if age < config.Startup then
		return "startup"
	end
	if age < config.Startup + config.Active then
		return "active"
	end
	return "recovery"
end

function Fist.segment(started: number, previous: number, now: number, config: { Startup: number, Active: number })
	local first = math.max(previous, started + config.Startup)
	local last = math.min(now, started + config.Startup + config.Active)
	if first > last or now < started + config.Startup or previous >= started + config.Startup + config.Active then
		return nil
	end
	return first, last
end

function Fist.reach(age, config)
	return config.StartReach
		+ (config.EndReach - config.StartReach) * math.clamp((age - config.Startup) / config.Active, 0, 1)
end

function Fist.canBuffer(age, occupied, restricted, config)
	return not occupied and not restricted and age >= config.BufferStart and age < config.Duration
end

function Fist.aim(value)
	if typeof(value) ~= "Vector3" then
		return nil
	end
	for _, n in { value.X, value.Y, value.Z } do
		if n ~= n or math.abs(n) == math.huge then
			return nil
		end
	end
	if value.Y ~= 0 or value.Magnitude < 0.001 or value.Magnitude > 1e6 then
		return nil
	end
	return value.Unit
end

function Fist.before(a, b)
	if a.time ~= b.time then
		return a.time < b.time
	end
	if a.action.id ~= b.action.id then
		return a.action.id < b.action.id
	end
	return a.attacker.player.UserId < b.attacker.player.UserId
end

-- Collect before resolving: an incoming active hit cannot erase a mutual trade.
function Fist.resolve(contacts, config)
	table.sort(contacts, Fist.before)
	local winners, canceled, protected = {}, {}, {}
	for _, contact in contacts do
		local action, victim = contact.action, contact.victim
		if not canceled[action] and not action.encountered[victim] then
			action.encountered[victim] = true
			if contact.time >= (protected[victim] or victim.protectionUntil) then
				protected[victim] = contact.time + config.Protection
				table.insert(winners, contact)
				local outgoing = victim.action
				if outgoing and contact.time < outgoing.started + config.Startup then
					canceled[outgoing] = true
				end
			end
		end
	end
	return winners, canceled
end

return table.freeze(Fist)
