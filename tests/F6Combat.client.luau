local Storage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local fixture = Storage:WaitForChild("F6CombatTest", 15)
if not fixture then
	return
end
local Client = require(player.PlayerScripts:WaitForChild("F2Client", 10))
local errors, engineErrors, phases, eliminations, hits = {}, {}, {}, {}, 0
Storage:WaitForChild("F3Knockouts", 10).OnClientEvent:Connect(function(event)
	table.insert(eliminations, event)
end)
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		if string.match(message, "^Players%.[^.]+%.PlayerScripts%.ChatScript:") then
			table.insert(engineErrors, message)
		else
			table.insert(errors, message)
		end
	end
end)
Storage:WaitForChild("F2Combat", 10).OnClientEvent:Connect(function(kind)
	if kind == "hit" then
		hits += 1
	end
end)
game:GetService("RunService").RenderStepped:Connect(function()
	local folder = workspace:FindFirstChild("F2Presentation")
	if not folder then
		return
	end
	for _, head in folder:GetChildren() do
		if head.Name == "WreckingHammerHead" then
			local color = head.Color
			local phase = if color == Color3.fromRGB(255, 190, 40)
				then "startup"
				elseif color == Color3.fromRGB(255, 75, 65) then "active"
				elseif color == Color3.fromRGB(95, 140, 190) then "recovery"
				else nil
			if phase then
				phases[phase] = phases[phase]
					or { samples = 0, first = { head.Position.X, head.Position.Y, head.Position.Z } }
				local sample = phases[phase]
				sample.samples += 1
				sample.last = { head.Position.X, head.Position.Y, head.Position.Z }
			end
		end
	end
end)
fixture.OnClientEvent:Connect(function(kind, data)
	if kind == "choose-weapon" then
		Storage.F6WeaponChoice:FireServer(data)
	elseif kind == "picker-snapshot" then
		local picker = player.PlayerGui:WaitForChild("F3HUD", 10):WaitForChild("WeaponPicker", 10)
		fixture:FireServer("picker-snapshot", {
			visible = picker.Visible,
			centered = picker.AnchorPoint == Vector2.new(0.5, 0.5) and picker.Position == UDim2.fromScale(0.5, 0.5),
			selected = picker.WreckingHammer.Text,
		})
	elseif kind == "press" then
		Client.press(player.Character, data)
	elseif kind == "snapshot" then
		fixture:FireServer("snapshot", {
			phases = phases,
			errors = errors,
			engineErrors = engineErrors,
			eliminations = eliminations,
			hits = hits,
			pickerVisible = player.PlayerGui.F3HUD.WeaponPicker.Visible,
		})
	elseif kind == "ping" then
		fixture:FireServer("pong")
	end
end)
fixture:FireServer("ready")
