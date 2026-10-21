-- Temporarily sync as a LocalScript in StarterPlayerScripts. Never runs outside Studio.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("F2Study", 20)
if not remote then
	return
end
local trial = nil
local manualMode = "client"
local lastSteer = 0

remote.OnClientEvent:Connect(function(command, data)
	if command == "ping" then
		remote:FireServer("pong", data)
	elseif command == "begin" then
		trial = {
			id = data.id,
			character = data.character,
			started = os.clock(),
			samples = {},
			lastSample = -1,
			probe = data.probe,
			subject = data.character == player.Character,
			applied = false,
		}
	elseif command == "launch" then
		if data.character ~= player.Character then
			return
		end
		local root = data.character:FindFirstChild("HumanoidRootPart")
		local humanoid = data.character:FindFirstChildOfClass("Humanoid")
		if root and humanoid then
			root.AssemblyLinearVelocity = data.velocity
			remote:FireServer("applied", data.id)
			if trial and trial.id == data.id then
				trial.applied = true
				trial.initial =
					{ root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z }
			end
		end
	elseif command == "invalid-requests" then
		remote:FireServer("request", {})
		remote:FireServer("request", "unknown")
		remote:FireServer("request", "client")
	elseif command == "finish" and trial and trial.id == data then
		local humanoid = trial.character:FindFirstChildOfClass("Humanoid")
		remote:FireServer("report", {
			id = trial.id,
			samples = trial.samples,
			initial = trial.initial,
			motorEnabled = humanoid and humanoid.EvaluateStateMachine,
			humanoidState = humanoid and humanoid:GetState().Name,
		})
		trial = nil
	end
end)

RunService.PreSimulation:Connect(function()
	if not trial or not trial.subject then
		return
	end
	local root = trial.character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local elapsed = os.clock() - trial.started
	if trial.probe == "resist" and elapsed > 0.02 then
		root.AssemblyLinearVelocity = Vector3.zero
	elseif trial.probe == "teleport" and elapsed > 0.25 and not trial.probed then
		root.CFrame += Vector3.new(100, 0, 0)
		trial.probed = true
	elseif trial.probe == "speed" and elapsed > 0.25 then
		root.AssemblyLinearVelocity = Vector3.new(64, root.AssemblyLinearVelocity.Y, 0)
	end
end)

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and root:GetAttribute("F2StudyMode") == "server" and os.clock() - lastSteer >= 0.1 then
		lastSteer = os.clock()
		remote:FireServer("steer", humanoid.MoveDirection)
	end
	if not trial or #trial.samples >= 40 then
		return
	end
	local trialRoot = trial.character:FindFirstChild("HumanoidRootPart")
	local elapsed = os.clock() - trial.started
	if trialRoot and elapsed - trial.lastSample >= 0.05 then
		trial.lastSample = elapsed
		local p, v = trialRoot.Position, trialRoot.AssemblyLinearVelocity
		local trialHumanoid = trial.character:FindFirstChildOfClass("Humanoid")
		local mode = trialRoot:GetAttribute("F2StudyMode")
		table.insert(trial.samples, {
			elapsed,
			p.X,
			p.Y,
			p.Z,
			v.X,
			v.Y,
			v.Z,
			workspace:GetServerTimeNow(),
			if trialHumanoid and trialHumanoid.EvaluateStateMachine then 1 else 0,
			if mode == "client" then 1 elseif mode == "server" then 2 else 0,
		})
	end
end)

Input.InputBegan:Connect(function(input, processed)
	if processed or Input:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.K then
		manualMode = if manualMode == "client" then "server" else "client"
		print("F2 study ownership:", manualMode)
	elseif input.KeyCode == Enum.KeyCode.L then
		remote:FireServer("request", manualMode)
	end
end)
remote:FireServer("ready")
