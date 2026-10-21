--!strict

local Movement = {}

function Movement.direction(x: number, z: number, yaw: number): Vector3
	local input = Vector3.new(x, 0, z)
	if input.Magnitude > 1 then
		input = input.Unit
	end
	return CFrame.Angles(0, yaw, 0):VectorToWorldSpace(input)
end

function Movement.pressJump(wasHeld: boolean, isHeld: boolean, grounded: boolean): boolean
	return isHeld and not wasHeld and grounded
end

return table.freeze(Movement)
