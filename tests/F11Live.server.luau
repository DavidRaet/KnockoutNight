-- Temporary, explicitly gated one-client production remote/physics probe.
if script:GetAttribute("F11Verification") ~= true then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local Combat = require(game.ServerScriptService.F2Combat)
local player
repeat
	player = Players:GetPlayers()[1]
	task.wait()
until player and player:GetAttribute("F3Status") == "waiting"
local checks, samples = {}, {}
local function check(value, message)
	assert(value, "F11 live: " .. message)
	table.insert(checks, message)
end
local function waitFor(predicate, seconds, message)
	local deadline = os.clock() + seconds
	repeat
		if predicate() then
			return
		end
		task.wait()
	until os.clock() >= deadline
	error("F11 live timeout: " .. message)
end
local originalAllowed, originalSnapshot = Match.allowed, Storage.F4State.Value
local connection
local passed, failure = pcall(function()
	check(Match.chooseWeapon(player, "WreckingHammer"), "Hammer selected")
	check(Match.chooseAbility(player, "Bounce"), "Bounce selected")
	Match.allowed = function()
		return true
	end
	Lives.reset(player)
	Lives.freeze(player, false, false)
	local root = player.Character.HumanoidRootPart
	root.CFrame = CFrame.new(0, 46, 0)
	Combat.resetMovement(player)
	local activeSnapshot = Http:JSONEncode({
		session = 0,
		phase = "regulation",
		startedAt = workspace:GetServerTimeNow(),
		deadline = workspace:GetServerTimeNow() + 60,
		roster = {},
	})
	Storage.F4State.Value = activeSnapshot
	local initialY, highestY = root.Position.Y, root.Position.Y
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		Storage.F4State.Value = activeSnapshot
		highestY = math.max(highestY, root.Position.Y)
		table.insert(samples, {
			at = workspace:GetServerTimeNow(),
			y = root.Position.Y,
			vy = root.AssemblyLinearVelocity.Y,
			actionUntil = root:GetAttribute("F2ActionUntil"),
			displaced = root:GetAttribute("F2Displaced"),
			serverOwned = root:GetNetworkOwner() == nil,
		})
	end)
	script:SetAttribute("Ready", true)
	waitFor(function()
		return player:GetAttribute("F10ReadyAt") ~= nil
	end, 45, "client Q")
	check(true, "actual Q accepted through production remote")
	script:SetAttribute("BounceSeen", true)
	waitFor(function()
		return root:GetAttribute("F2ActionUntil") == math.huge
	end, 15, "client slam primary")
	check(highestY > initialY + 2, "Bounce leaves Platform")
	local started = workspace:GetServerTimeNow()
	check(root:GetNetworkOwner() == nil, "slam takes server ownership")
	check(not player.Character.Humanoid.EvaluateStateMachine, "slam disables motor")
	local cooldown = player:GetAttribute("F10ReadyAt")
	waitFor(function()
		local deadline = root:GetAttribute("F2ActionUntil")
		return deadline and deadline < math.huge
	end, 5, "valid landing")
	local recoveryAt = root:GetAttribute("F2ActionUntil")
	check(math.abs(recoveryAt - workspace:GetServerTimeNow() - 0.65) < 0.08, "actual landing starts 0.65 recovery")
	check(workspace:GetServerTimeNow() >= started + 0.24, "impact follows telegraph")
	local descended = false
	for _, sample in samples do
		if sample.vy <= -89 and sample.serverOwned then
			descended = true
		end
	end
	check(descended, "actual physics reaches at least 90 downward")
	check(
		root:GetNetworkOwner() == player and player.Character.Humanoid.EvaluateStateMachine,
		"landing returns ownership and motor"
	)
	check(player:GetAttribute("F10ReadyAt") == cooldown, "slam preserves Bounce cooldown")
	waitFor(function()
		return root:GetAttribute("F2ActionUntil") == nil
	end, 2, "recovery cleanup")
	check(not root:GetAttribute("F2Displaced"), "live drive cleared")
end)
if connection then
	connection:Disconnect()
end
Match.allowed = originalAllowed
Storage.F4State.Value = originalSnapshot
Lives.stage(player)
script:SetAttribute(
	"Result",
	Http:JSONEncode({
		passed = passed,
		error = if passed then nil else tostring(failure),
		checks = checks,
		samples = samples,
	})
)
