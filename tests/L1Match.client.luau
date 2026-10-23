local Storage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local remote = Storage:WaitForChild("L1MatchFixture", 40)
if not remote then
	return
end
local errors = {}
game:GetService("ScriptContext").Error:Connect(function(message)
	table.insert(errors, message)
end)
remote.OnClientEvent:Connect(function(kind)
	if kind == "snapshot" then
		local camera = workspace.CurrentCamera
		remote:FireServer("snapshot", {
			state = Storage.F4State.Value,
			errors = errors,
			arena = workspace:FindFirstChild("SkyBridges") ~= nil,
			cameraDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude,
			viewport = tostring(camera.ViewportSize),
			position = tostring(Players.LocalPlayer.Character.HumanoidRootPart.Position),
		})
	end
end)
remote:FireServer("ready")
