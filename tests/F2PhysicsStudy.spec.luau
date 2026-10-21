-- Run in Studio Edit context after the study module syncs.
local Study = require(game:GetService("ReplicatedStorage").F2PhysicsStudy)
assert(not Study.vector(Vector3.new(0 / 0, 0, 0)), "Study must reject NaN vectors")
assert(not Study.vector(Vector3.new(math.huge, 0, 0)), "Study must reject infinite vectors")
assert(not Study.vector("client"), "Study must reject non-vector telemetry")
assert(Study.steer(Study.Launch, -Vector3.xAxis, 0.1).X > 49, "Minimal steering must not reverse a launch")
assert(Study.steer(Study.Launch, Vector3.yAxis, 0.1).Y == 12, "Steering must not add lift")
assert(not Study.recovered(0.05, Vector3.zero, true), "Initial floor overlap must not end a launch")
assert(Study.recovered(0.2, Study.Launch, true), "Landing must end knockback control")
assert(Study.recovered(0.4, Vector3.new(10, 0, 0), false), "Slow motion must release knockback control")
assert(not Study.recovered(0.4, Study.Launch, false), "Protection time must not release a fast launch")
local credit = 16 * Study.BurstSeconds + Study.PositionSlack
for _ = 1, 100 do
	local rejected
	credit, rejected = Study.budget(credit, 1.6, 0.1, 16)
	assert(not rejected, "Ordinary sustained walking must stay within the budget")
end
local _, teleported = Study.budget(credit, 100, 0.1, 16)
assert(teleported, "A horizontal teleport must exceed the movement budget")
local rejected = false
for _ = 1, 10 do
	credit, rejected = Study.budget(credit, 3.2, 0.1, 16)
	if rejected then break end
end
assert(rejected, "Sustained double-speed movement must exhaust the budget")
assert(Study.request("client", 2), "A spaced valid client-mode request must be accepted")
assert(Study.request("server", 2), "A spaced valid server-mode request must be accepted")
assert(not Study.request({}, 2), "Malformed launch requests must be rejected")
assert(not Study.request("server", 1), "Launch requests must be rate limited")
return "PASS: F2 study validation, steering, recovery, and request checks"
