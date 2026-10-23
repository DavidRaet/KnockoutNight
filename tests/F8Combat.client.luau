local Storage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local fixture = Storage:WaitForChild("F8CombatTest", 15)
if not fixture then
	return
end
local Client = require(player.PlayerScripts:WaitForChild("F2Client", 10))
local errors, engineErrors, accepted, bursts = {}, {}, 0, 0
local sawBurst, sawCue, sawHud = false, false, false
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError then
		if
			string.match(message, "^Players%.[^.]+%.PlayerScripts%.ChatScript:")
			or string.find(message, "Unable to load plugin icon:", 1, true)
		then
			table.insert(engineErrors, message)
		else
			table.insert(errors, message)
		end
	end
end)
Storage:WaitForChild("F2Combat", 10).OnClientEvent:Connect(function(kind, data)
	if kind == "accepted" and data.ability == "Gust" then
		accepted += 1
	end
	if kind == "gust-burst" then
		bursts += 1
	end
end)
game:GetService("RunService").RenderStepped:Connect(function()
	local folder = workspace:FindFirstChild("F2Presentation")
	if folder then
		for _, p in folder:GetChildren() do
			sawBurst = sawBurst or p.Name == "GustBurst"
			sawCue = sawCue or p.Name == "GustAccepted"
		end
	end
	local hud = player.PlayerGui:FindFirstChild("F8HUD")
	sawHud = sawHud or (hud ~= nil and hud.Enabled)
end)
fixture.OnClientEvent:Connect(function(kind, data)
	if kind == "gust" then
		Client.gust(player.Character, data)
	elseif kind == "snapshot" then
		fixture:FireServer("snapshot", {
			errors = errors,
			engineErrors = engineErrors,
			accepted = accepted,
			bursts = bursts,
			sawBurst = sawBurst,
			sawCue = sawCue,
			sawHud = sawHud,
		})
	end
end)
fixture:FireServer("ready")
