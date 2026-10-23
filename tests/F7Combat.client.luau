local Storage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local fixture = Storage:WaitForChild("F7CombatTest", 15)
if not fixture then
	return
end
local Client = require(player.PlayerScripts:WaitForChild("F2Client", 10))
local errors, engineErrors, hands, visualHands, eliminations = {}, {}, {}, {}, {}
local shields, shieldVisual = 0, false
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		if string.match(message, "^Players%.[^.]+%.PlayerScripts%.ChatScript:") then
			table.insert(engineErrors, message)
		else
			table.insert(errors, message)
		end
	end
end)
Storage:WaitForChild("F2Combat", 10).OnClientEvent:Connect(function(kind, data)
	if kind == "accepted" and data.weapon == "PaddlePops" then
		hands[data.hand] = true
	elseif kind == "shield" then
		shields += 1
	end
end)
Storage:WaitForChild("F3Knockouts", 10).OnClientEvent:Connect(function(event)
	table.insert(eliminations, event)
end)
game:GetService("RunService").RenderStepped:Connect(function()
	local folder = workspace:FindFirstChild("F2Presentation")
	if folder then
		for _, part in folder:GetChildren() do
			for _, hand in { "Left", "Right" } do
				if part.Name == hand .. "FoamPaddle" and part.Transparency == 0 then
					visualHands[hand] = true
				end
			end
			if part.Name == "PaddleShieldContact" and part.Transparency < 1 then
				shieldVisual = true
			end
		end
	end
end)
fixture.OnClientEvent:Connect(function(kind, data)
	if kind == "choose-weapon" then
		Storage.F6WeaponChoice:FireServer(data)
	elseif kind == "press" then
		Client.press(player.Character, data)
	elseif kind == "snapshot" then
		local picker = player.PlayerGui:WaitForChild("F3HUD", 10):WaitForChild("WeaponPicker", 10)
		fixture:FireServer("snapshot", {
			errors = errors,
			engineErrors = engineErrors,
			hands = hands,
			visualHands = visualHands,
			shields = shields,
			shieldVisual = shieldVisual,
			eliminations = eliminations,
			pickerVisible = picker.Visible,
			hasPaddles = picker:FindFirstChild("PaddlePops") ~= nil,
			selected = picker.PaddlePops.Text,
		})
	end
end)
fixture:FireServer("ready")
