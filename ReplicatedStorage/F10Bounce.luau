local Bounce = {
	Cooldown = 10,
	LaunchSpeed = 48,
	LaunchUp = 90,
	PrimaryDelay = 0.15,
}

function Bounce.components(x, z)
	local magnitude = math.sqrt(x * x + z * z)
	if magnitude <= 0.00001 then
		return 0, Bounce.LaunchUp, 0
	end
	return x / magnitude * Bounce.LaunchSpeed, Bounce.LaunchUp, z / magnitude * Bounce.LaunchSpeed
end

return table.freeze(Bounce)
