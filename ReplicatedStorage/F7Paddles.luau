local Paddles = {
	Startup = 0.10,
	Active = 0.08,
	Recovery = 0.16,
	Duration = 0.34,
	BufferStart = 0.22,
	Size = Vector3.new(3, 4, 4),
	MoveScale = 0.85,
	LaunchSpeed = 30,
	LaunchUp = 8,
}

function Paddles.other(hand)
	return if hand == "Right" then "Left" else "Right"
end

function Paddles.frame(position, aim, hand)
	local facing = CFrame.lookAt(position, position + aim)
	return facing * CFrame.new(if hand == "Left" then -0.5 else 0.5, 0, -2.5)
end

return table.freeze(Paddles)
