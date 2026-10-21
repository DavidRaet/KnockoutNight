-- Run in Studio Edit context; the module is synced, this test is not.
local Movement = require(game:GetService("ReplicatedStorage").F1Movement)

assert(Movement.direction(0, 0, 0) == Vector3.zero, "Idle input must remain zero")
assert(math.abs(Movement.direction(1, -1, 0).Magnitude - 1) < 1e-6, "Diagonal movement must be normalized")
assert((Movement.direction(0, -1, math.pi / 2) - Vector3.new(-1, 0, 0)).Magnitude < 1e-6, "Movement must follow camera yaw")
assert(Movement.direction(1, 1, 2).Y == 0, "Movement cannot add vertical lift")
assert(Movement.pressJump(false, true, true), "Fresh grounded press must jump")
assert(not Movement.pressJump(true, true, true), "Holding through landing cannot jump again")
assert(not Movement.pressJump(false, true, false), "Airborne press cannot jump")
assert(not Movement.pressJump(true, false, true), "Release cannot jump")
assert(Movement.pressJump(false, true, true), "Release then press must rearm jumping")
return "PASS: 9 F1 movement/jump assertions"
