-- Shared pose used by both the server sweep and the temporary client proxy.
local Hammer = {
	Startup = 0.48,
	Active = 0.18,
	Recovery = 0.65,
	Duration = 1.31,
	BufferStart = 1.19,
	EndReach = 7,
	Sweep = math.rad(100),
	Size = Vector3.new(2.4, 5, 7),
	StrikeHeight = 0.2,
	MoveScale = 0.4,
	LaunchSpeed = 118, -- Calibrated toward 20 studs of grounded idle travel on The Platform.
	LaunchUp = 16,
}

function Hammer.angle(age)
	return Hammer.Sweep / 2 - Hammer.Sweep * math.clamp((age - Hammer.Startup) / Hammer.Active, 0, 1)
end

function Hammer.frame(position, aim, age)
	local origin = position + Vector3.yAxis * Hammer.StrikeHeight
	local facing = CFrame.lookAt(origin, origin + aim) * CFrame.Angles(0, Hammer.angle(age), 0)
	return facing * CFrame.new(0, 0, -Hammer.EndReach / 2)
end

return table.freeze(Hammer)
