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

function Movement.captureMouse(enabled: boolean, shiftLocked: boolean, rightMouse: boolean): boolean
	return enabled and (shiftLocked or rightMouse)
end

function Movement.turn(yaw: number, left: boolean, right: boolean, dt: number, speed: number): number
	return (yaw + ((if left then 1 else 0) - (if right then 1 else 0)) * speed * dt) % (math.pi * 2)
end

return table.freeze(Movement)
