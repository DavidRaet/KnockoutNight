local Slam = {
	Startup = 0.25,
	Active = math.huge,
	Duration = math.huge,
	BufferStart = math.huge,
	Recovery = 0.65,
	MoveScale = 0,
	Armored = true,
	DownSpeed = 90,
	SteeringAcceleration = 8,
	Radius = 9,
	Elevation = 2,
	LaunchSpeed = 55,
	LaunchUp = 13,
}

function Slam.direction(x, z, facingX, facingZ)
	local length = math.sqrt(x * x + z * z)
	if length < 0.00001 then
		return facingX, facingZ
	end
	return x / length, z / length
end

return table.freeze(Slam)
