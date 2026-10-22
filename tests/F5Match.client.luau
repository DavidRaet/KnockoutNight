local Storage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local errors = {}
local eliminations = {}
Storage:WaitForChild("F3Knockouts", 10).OnClientEvent:Connect(function(event)
	table.insert(eliminations, event)
end)
game:GetService("LogService").MessageOut:Connect(function(message, kind)
	if kind == Enum.MessageType.MessageError and not string.find(message, "Unable to load plugin icon:", 1, true) then
		table.insert(errors, message)
	end
end)
local fixture = Storage:WaitForChild("F5MatchTest", 10)
if not fixture then
	return
end
local hud = player:WaitForChild("PlayerGui", 10):WaitForChild("F3HUD", 10)
assert(hud, "F5 client fixture requires the real HUD")
fixture.OnClientEvent:Connect(function(tag, expected)
	local deadline = os.clock() + 3
	while Storage.F4State.Value ~= expected and os.clock() < deadline do
		task.wait()
	end
	game:GetService("RunService").RenderStepped:Wait()
	task.wait(0.05)
	local function overlaps(a, b)
		return a.AbsolutePosition.X < b.AbsolutePosition.X + b.AbsoluteSize.X
			and b.AbsolutePosition.X < a.AbsolutePosition.X + a.AbsoluteSize.X
			and a.AbsolutePosition.Y < b.AbsolutePosition.Y + b.AbsoluteSize.Y
			and b.AbsolutePosition.Y < a.AbsolutePosition.Y + a.AbsoluteSize.Y
	end
	fixture:FireServer("snapshot", {
		tag = tag,
		snapshot = Storage.F4State.Value,
		timer = hud.Timer.Text,
		results = hud.Results.Text,
		resultsVisible = hud.Results.Visible,
		respawnVisible = hud.Respawn.Visible,
		hudOverlap = overlaps(hud.Timer, hud.Score) or overlaps(hud.Timer, hud.Knockouts),
		feed = (function()
			local items = {}
			for _, child in hud.Knockouts:GetChildren() do
				if child:IsA("TextLabel") then
					table.insert(items, child.Text)
				end
			end
			return items
		end)(),
		viewport = { workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y },
		eliminations = eliminations,
		errors = errors,
	})
end)
fixture:FireServer("ready")
