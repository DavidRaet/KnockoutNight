--!strict

-- Experimental values, not approved combat tuning. Used only by the Studio fixture.
local Study = {
	Launch = Vector3.new(50, 12, 0),
	SteeringAcceleration = 3,
	RecoverySpeed = 18,
	MinimumFlight = 0.12,
	BurstSeconds = 0.2,
	PositionSlack = 3,
}

function Study.finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

function Study.vector(value: unknown): boolean
	return typeof(value) == "Vector3" and Study.finite(value.X) and Study.finite(value.Y) and Study.finite(value.Z)
end

function Study.horizontal(value: Vector3): Vector3
	return Vector3.new(value.X, 0, value.Z)
end

function Study.steer(velocity: Vector3, direction: Vector3, dt: number): Vector3
	local input = Study.horizontal(direction)
	if input.Magnitude > 1 then
		input = input.Unit
	end
	return velocity + input * Study.SteeringAcceleration * dt
end

function Study.recovered(elapsed: number, velocity: Vector3, grounded: boolean): boolean
	return elapsed >= Study.MinimumFlight and (grounded or
		(Study.horizontal(velocity).Magnitude <= Study.RecoverySpeed and math.abs(velocity.Y) <= 8))
end

-- Horizontal token budget tolerates replication bursts without permitting sustained excess speed.
function Study.budget(credit: number, distance: number, dt: number, speed: number): (number, boolean)
	local maximum = speed * Study.BurstSeconds + Study.PositionSlack
	local nextCredit = math.min(maximum, credit + speed * dt) - distance
	return nextCredit, nextCredit < 0
end

function Study.request(mode: unknown, elapsed: number): boolean
	return (mode == "client" or mode == "server") and elapsed >= 2
end

return table.freeze(Study)
