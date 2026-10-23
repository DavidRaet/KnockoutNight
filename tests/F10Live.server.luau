-- Temporary single-client technical probe; install explicitly with this attribute.
if script:GetAttribute("F10Verification") ~= true then
	return
end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Match = require(game.ServerScriptService.F4Match)
local Lives = require(game.ServerScriptService.F3Lives)
local Combat = require(game.ServerScriptService.F2Combat)
local player = Players:GetPlayers()[1]
assert(player, "F10 live probe requires a connected player in staging")
local checks = {}
local function check(value, message)
	assert(value, "F10 live probe: " .. message)
	table.insert(checks, message)
end
local originalAllowed, originalCanJoin = Match.allowed, Match.canJoin
local originalSnapshot = Storage.F4State.Value
local connection
local passed, failure = pcall(function()
	for _, ability in { "Gust", "Magnet", "Bounce" } do
		check(Match.chooseAbility(player, ability), "staging accepts " .. ability)
		check(player:GetAttribute("F10Ability") == ability, "server stores " .. ability)
		check(not Match.chooseAbility(player, ability), "selection rate limited")
		task.wait(0.16)
	end
	check(not Match.chooseAbility(player, "GroundSlam"), "invalid ability rejected")
	Match.canJoin = function()
		return false
	end
	check(not Match.chooseAbility(player, "Gust"), "closed staging gate locks ability")
	check(not Match.chooseWeapon(player, "PaddlePops"), "same closed gate locks weapon")
	Match.canJoin = originalCanJoin
	Match.allowed = function()
		return true
	end
	Lives.reset(player)
	Lives.freeze(player, false, false)
	local root = player.Character.HumanoidRootPart
	root.CFrame = CFrame.new(0, 45, 0)
	Combat.resetMovement(player)
	Storage.F4State.Value = Http:JSONEncode({
		session = 0,
		phase = "regulation",
		startedAt = workspace:GetServerTimeNow(),
		deadline = workspace:GetServerTimeNow() + 60,
		roster = {},
	})
	local initialY, highestY, readyAt = root.Position.Y, root.Position.Y, nil
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		highestY = math.max(highestY, root.Position.Y)
		readyAt = readyAt or player:GetAttribute("F10ReadyAt")
	end)
	script:SetAttribute("Ready", true)
	local deadline = os.clock() + 45
	while not readyAt and os.clock() < deadline do
		task.wait()
	end
	check(readyAt ~= nil, "actual client Q accepted through combat remote")
	task.wait(0.2)
	check(root:GetNetworkOwner() == player, "Bounce returns network ownership to live client")
	check(player.Character.Humanoid.EvaluateStateMachine, "live client motor restored")
	task.wait(0.8)
	check(highestY - initialY > 5, "live character visibly leaves the ground")
	check(not root:GetAttribute("F2Displaced"), "live launch state cleaned")
	script:SetAttribute("HeightGain", highestY - initialY)
end)
if connection then
	connection:Disconnect()
end
Match.allowed, Match.canJoin = originalAllowed, originalCanJoin
Storage.F4State.Value = originalSnapshot
Lives.stage(player)
script:SetAttribute(
	"Result",
	Http:JSONEncode({ passed = passed, error = if passed then nil else tostring(failure), checks = checks })
)
