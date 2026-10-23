local Magnet = {
	Cooldown = 12,
	Range = 20,
	Cone = 60,
	Height = 5,
	Startup = 0.12,
	Active = 0,
	Recovery = 0.20,
	Duration = 0.32,
	MoveScale = 1,
	CanJump = true,
	PullSpeed = 28,
	PullDuration = 0.55,
	StopDistance = 3,
	Protection = 0.35,
	ControlledPull = true,
}

function Magnet.contains(x, z, aimX, aimZ)
	local distance = math.sqrt(x * x + z * z)
	return distance <= Magnet.Range
		and (distance < 0.00001 or (x * aimX + z * aimZ) / distance >= math.cos(math.rad(Magnet.Cone / 2)) - 1e-7)
end

-- Candidates contain only server-derived geometry/eligibility and stable player IDs.
function Magnet.select(candidates)
	local best
	for _, candidate in candidates do
		if
			candidate.eligible
			and (
				not best
				or candidate.alignment > best.alignment
				or (candidate.alignment == best.alignment and candidate.distance < best.distance)
				or (
					candidate.alignment == best.alignment
					and candidate.distance == best.distance
					and candidate.id < best.id
				)
			)
		then
			best = candidate
		end
	end
	return best
end

function Magnet.speed(distance, dt, remaining)
	local duration = math.min(dt, remaining)
	if duration <= 0 then
		return 0
	end
	return math.min(Magnet.PullSpeed * duration, math.max(0, distance - Magnet.StopDistance)) / dt
end

return table.freeze(Magnet)
