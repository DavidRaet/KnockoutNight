local Gust = {
	Cooldown = 15,
	Range = 12,
	Cone = 60,
	Height = 5,
	Startup = 0.12,
	Active = 0,
	Recovery = 0.20,
	Duration = 0.32,
	MoveScale = 1,
	LaunchSpeed = 35,
	LaunchUp = 6,
	Reaction = 0.25,
}

function Gust.contains(x, z, aimX, aimZ)
	local distance = math.sqrt(x * x + z * z)
	return distance <= Gust.Range
		and (distance < 0.00001 or (x * aimX + z * aimZ) / distance >= math.cos(math.rad(Gust.Cone / 2)))
end

return table.freeze(Gust)
