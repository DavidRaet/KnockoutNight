local Storage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local fixture = Storage:WaitForChild("F2CombatTest", 10)
if not fixture then
	return
end
local clientInstance = player.PlayerScripts:WaitForChild("F2Client", 10)
assert(clientInstance, "F2 combat client fixture requires F2Client")
local Client = require(clientInstance)
fixture.OnClientEvent:Connect(function(kind, data)
	if kind == "ping" then
		fixture:FireServer("pong", data)
	elseif kind == "press" then
		Client.press(player.Character, data)
		fixture:FireServer("pressed", workspace:GetServerTimeNow())
	elseif kind == "snapshot" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local h = character and character:FindFirstChildOfClass("Humanoid")
		fixture:FireServer("snapshot", {
			motor = h and h.EvaluateStateMachine,
			state = h and h:GetState().Name,
			displaced = root and root:GetAttribute("F2Displaced"),
			visuals = workspace:FindFirstChild("F2Presentation") ~= nil,
			predictionMismatchMs = player:GetAttribute("F2PredictionMismatchMs"),
			acceptanceAgeMs = player:GetAttribute("F2AcceptanceAgeMs"),
			impactDelayMs = player:GetAttribute("F2ImpactDelayMs"),
		})
	end
end)
fixture:FireServer("ready")
