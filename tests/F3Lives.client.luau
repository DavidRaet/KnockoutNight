local Players = game:GetService("Players")
local player = Players.LocalPlayer
local errors = {}
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and #errors < 10 then
		table.insert(errors, message)
	end
end)
local fixture = game.ReplicatedStorage:WaitForChild("F3LivesTest", 10)
if not fixture then
	return
end
local combat = require(player.PlayerScripts:WaitForChild("F2Client", 10))
local hud = player:WaitForChild("PlayerGui", 10):WaitForChild("F3HUD", 10)
assert(hud, "F3 fixture requires the real HUD")
fixture.OnClientEvent:Connect(function(kind, data)
	if kind == "attack" then
		combat.press(player.Character, data)
	elseif kind == "snapshot" then
		local untilTime = os.clock() + 1
		while data.status and player:GetAttribute("F3Status") ~= data.status and os.clock() < untilTime do
			task.wait()
		end
		game:GetService("RunService").RenderStepped:Wait()
		task.wait(0.05)
		local scores = {}
		local feedText = {}
		for _, entry in hud.Knockouts:GetChildren() do
			if entry:IsA("TextLabel") then
				table.insert(feedText, entry.Text)
			end
		end
		for _, other in Players:GetPlayers() do
			scores[other.Name] = other:GetAttribute("F3Score")
		end
		fixture:FireServer("snapshot", {
			tag = data.tag,
			status = player:GetAttribute("F3Status"),
			scores = scores,
			spectating = player:GetAttribute("F3Spectating"),
			countdownVisible = hud.Respawn.Visible,
			countdown = hud.Respawn.Text,
			errors = errors,
			feedText = feedText,
			feedEntries = #hud.Knockouts:GetChildren() - 1,
			focus = {
				workspace.CurrentCamera.Focus.Position.X,
				workspace.CurrentCamera.Focus.Position.Y,
				workspace.CurrentCamera.Focus.Position.Z,
			},
		})
	end
end)
fixture:FireServer("ready")
