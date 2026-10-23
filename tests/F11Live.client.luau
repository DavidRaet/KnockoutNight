local Storage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local remote = Storage:WaitForChild("F2Combat", 10)
assert(remote, "F11 client probe requires combat remote")
local events, samples = {}, {}
local active, impactCount = false, 0
remote.OnClientEvent:Connect(function(kind, data)
	if data.character ~= player.Character then
		return
	end
	if kind == "accepted" and data.ability == "GroundSlam" then
		active = true
		table.insert(events, { kind = kind, at = workspace:GetServerTimeNow(), started = data.started })
	elseif kind == "slam-impact" then
		active = false
		impactCount += 1
		table.insert(events, { kind = kind, at = workspace:GetServerTimeNow(), origin = tostring(data.origin) })
		script:SetAttribute("Result", Http:JSONEncode({ events = events, samples = samples, impacts = impactCount }))
	end
end)
game:GetService("RunService").RenderStepped:Connect(function()
	if not active or not player.Character then
		return
	end
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local proxy = workspace:FindFirstChild("F2Presentation")
	local highest = -math.huge
	if proxy then
		for _, part in proxy:GetDescendants() do
			if part:IsA("BasePart") and part.Name == "WreckingHammerHead" then
				highest = math.max(highest, part.Position.Y - root.Position.Y)
			end
		end
	end
	table.insert(
		samples,
		{ at = workspace:GetServerTimeNow(), headHeight = if highest > -math.huge then highest else nil }
	)
end)
