-- Temporarily sync into ServerScriptService. Module/controller remain inert without this fixture.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end
local Test = game:GetService("StudioTestService")
local _, args = pcall(function()
	return Test:GetTestArgs()
end)
local automated = type(args) == "table" and args.test == "F2Physics"
if not automated and workspace:GetAttribute("F2PhysicsStudy") ~= true then
	return
end

local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Study = require(Storage:WaitForChild("F2PhysicsStudy", 10))
local Config = require(Storage.F1Config)
local remote = Instance.new("RemoteEvent")
remote.Name = "F2Study"
remote.Parent = Storage
local ready, pings, lastRequest, lastReport = {}, {}, {}, {}
local active = {}
local reports = {}
local results = {}
local nextId = 0
local rejectedRequests = 0
local wall = nil
local connection

local function finishState(player, reason)
	local state = active[player]
	if not state then
		return
	end
	active[player] = nil
	if state.root.Parent then
		state.root:SetAttribute("F2StudyMode", nil)
		state.root:SetAttribute("F2StudyMotorEnabled", nil)
		state.root:SetAttribute("F2StudyInput", nil)
		state.root:SetAttribute("F2StudyJump", nil)
		state.humanoid.EvaluateStateMachine = state.motorEnabled
		if not state.root.Anchored then
			state.root:SetNetworkOwnershipAuto()
		end
	end
	state.result.release = reason
	state.result.releaseTime = os.clock() - state.started
end

local function beginState(player, mode, probe, launch)
	finishState(player, "replaced")
	local character = player.Character
	assert(character, "F2 launch requires a current character")
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(root and humanoid and humanoid.Health > 0, "F2 launch requires a living character and root")
	local canOwn, why = root:CanSetNetworkOwnership()
	assert(canOwn, "F2 cannot change character ownership: " .. tostring(why))
	nextId += 1
	local result = {
		id = nextId,
		player = player.Name,
		mode = mode,
		probe = probe,
		server = {},
		corrections = 0,
		resistance = false,
		owners = {},
		rttMs = pings[player] and pings[player].rtt or -1,
		startedAt = workspace:GetServerTimeNow(),
		origin = { root.Position.X, root.Position.Y, root.Position.Z },
		minimumFlight = if automated then args.minimumFlight or Study.MinimumFlight else Study.MinimumFlight,
	}
	local state = {
		character = character,
		root = root,
		humanoid = humanoid,
		mode = mode,
		result = result,
		started = os.clock(),
		sampled = -1,
		origin = root.Position,
		lastPosition = root.Position,
		safe = root.CFrame,
		credit = 50 * Study.BurstSeconds + Study.PositionSlack,
		motorEnabled = humanoid.EvaluateStateMachine,
		launch = launch,
		probe = probe,
		displaced = launch ~= nil,
	}
	state.appliedAt = if mode == "server" then state.started else nil
	active[player] = state
	root:SetAttribute("F2StudyMotorEnabled", state.motorEnabled)
	root:SetAttribute(
		"F2StudyInput",
		if probe == "manual"
			then nil
			elseif probe == "reverse" then -Vector3.xAxis
			elseif probe == "walk" then Vector3.xAxis
			else Vector3.zero
	)
	root:SetAttribute("F2StudyMode", if launch then mode else nil)
	root:SetNetworkOwner(if launch and mode == "server" then nil else player)
	remote:FireAllClients("begin", { id = nextId, character = character, probe = probe })
	if launch then
		humanoid.EvaluateStateMachine = false
		root.AssemblyLinearVelocity = launch
		result.initial = { root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z }
		if mode == "client" then
			remote:FireClient(player, "launch", { id = nextId, character = character, velocity = launch })
		end
	end
	return result
end

local function sequence(value, count)
	if type(value) ~= "table" then
		return false
	end
	local seen = 0
	for key in value do
		seen += 1
		if seen > count or type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
			return false
		end
	end
	return seen == count
end

local function validReport(data)
	if
		type(data) ~= "table"
		or type(data.id) ~= "number"
		or not Study.finite(data.id)
		or type(data.samples) ~= "table"
		or #data.samples == 0
		or #data.samples > 40
		or not sequence(data.samples, #data.samples)
	then
		return false
	end
	for _, sample in data.samples do
		if not sequence(sample, 10) then
			return false
		end
		for _, value in sample do
			if type(value) ~= "number" or not Study.finite(value) then
				return false
			end
		end
	end
	if data.initial ~= nil then
		if not sequence(data.initial, 3) then
			return false
		end
		for _, value in data.initial do
			if type(value) ~= "number" or not Study.finite(value) then
				return false
			end
		end
	end
	return true
end

remote.OnServerEvent:Connect(function(player, command, data)
	if command == "ready" then
		ready[player] = true
	elseif command == "pong" then
		local ping = pings[player]
		if ping and data == ping.id and not ping.rtt then
			ping.rtt = (os.clock() - ping.sent) * 1000
		end
	elseif command == "applied" then
		local state = active[player]
		if state and state.mode == "client" and data == state.result.id and not state.appliedAt then
			state.appliedAt = os.clock()
			state.result.launchAckSeconds = state.appliedAt - state.started
		end
	elseif command == "steer" then
		local state = active[player]
		if
			not automated
			and state
			and state.mode == "server"
			and os.clock() - (state.lastSteer or 0) >= 0.05
			and Study.vector(data)
			and data.Y == 0
			and data.Magnitude <= 1.001
		then
			state.input, state.lastSteer = data, os.clock()
		end
	elseif command == "report" then
		if type(data) ~= "table" or not reports[data.id] or lastReport[player] == data.id or not validReport(data) then
			return
		end
		lastReport[player] = data.id
		reports[data.id][player.Name] = {
			samples = data.samples,
			initial = data.initial,
			motorEnabled = data.motorEnabled == true,
			humanoidState = if type(data.humanoidState) == "string" then data.humanoidState:sub(1, 32) else nil,
		}
	elseif command == "request" then
		local now = os.clock()
		if automated or not Study.request(data, now - (lastRequest[player] or -math.huge)) then
			rejectedRequests += 1
			return
		end
		lastRequest[player] = now
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or active[player] then
			return
		end
		local direction = Study.horizontal(root.CFrame.LookVector)
		if not Study.vector(direction) or direction.Magnitude < 0.9 then
			return
		end
		local result = beginState(player, data, "manual", -direction.Unit * 50 + Vector3.new(0, 12, 0))
		reports[result.id] = {}
		task.delay(1.5, function()
			if active[player] and active[player].result == result then
				finishState(player, "fixture-timeout")
			end
			remote:FireAllClients("finish", result.id)
			print("F2 manual result", game:GetService("HttpService"):JSONEncode(result))
			reports[result.id] = nil
		end)
	end
end)

connection = RunService.PreSimulation:Connect(function(dt)
	for player, state in active do
		local root, humanoid = state.root, state.humanoid
		if player.Character ~= state.character or not root.Parent or humanoid.Health <= 0 then
			finishState(player, "character-replaced")
			continue
		end
		local elapsed = os.clock() - state.started
		local position, velocity = root.Position, root.AssemblyLinearVelocity
		local speed = if state.launch then 50 + Study.SteeringAcceleration * elapsed else Config.WalkSpeed
		local invalid = not Study.vector(position) or not Study.vector(velocity)
		local distance = if invalid then math.huge else Study.horizontal(position - state.lastPosition).Magnitude
		local exceeded
		state.credit, exceeded = Study.budget(state.credit, distance, dt, speed)
		state.result.minimumCredit = math.min(state.result.minimumCredit or math.huge, state.credit)
		if invalid or exceeded then
			state.result.corrections += 1
			root:SetNetworkOwner(nil)
			root.CFrame = state.safe
			root.AssemblyLinearVelocity = Vector3.zero
			position, velocity = root.Position, root.AssemblyLinearVelocity
			state.credit = speed * Study.BurstSeconds + Study.PositionSlack
			warn(
				"F2 movement corrected",
				player.Name,
				state.result.id,
				if invalid then "nonfinite" else "horizontal-budget"
			)
		else
			state.safe = root.CFrame
		end
		state.lastPosition = root.Position
		-- shortcut: resistance is diagnostic only; collisions can also stop launches, so never punish it automatically.
		if state.probe == "resist" and elapsed >= 0.2 and Study.horizontal(position - state.origin).Magnitude < 2 then
			state.result.resistance = true
		end
		if elapsed - state.sampled >= 0.05 then
			state.sampled = elapsed
			local owner = root:GetNetworkOwner()
			local name = if owner then owner.Name else "server"
			if state.result.owners[#state.result.owners] ~= name then
				table.insert(state.result.owners, name)
			end
			table.insert(
				state.result.server,
				{ elapsed, position.X, position.Y, position.Z, velocity.X, velocity.Y, velocity.Z }
			)
		end
		if state.displaced then
			if state.appliedAt and Study.horizontal(position - state.origin).Magnitude >= 0.5 then
				state.motionObserved = true
				state.result.motionObservedAt = state.result.motionObservedAt or elapsed
			end
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { state.character }
			params.RespectCanCollide = true
			local ground = workspace:Raycast(
				root.Position,
				Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + 0.3), 0),
				params
			)
			local grounded = ground ~= nil and velocity.Y <= 0
			if
				state.motionObserved
				and os.clock() - state.appliedAt >= state.result.minimumFlight
				and Study.recovered(os.clock() - state.appliedAt, velocity, grounded)
			then
				state.result.recovery = {
					at = workspace:GetServerTimeNow(),
					position = { position.X, position.Y, position.Z },
					velocity = { velocity.X, velocity.Y, velocity.Z },
					groundDistance = if ground then ground.Distance else nil,
					rayLength = humanoid.HipHeight + root.Size.Y / 2 + 0.3,
				}
				state.displaced = false
				root:SetAttribute("F2StudyMode", nil)
				humanoid.EvaluateStateMachine = state.motorEnabled
				root:SetNetworkOwner(player)
				state.result.recoveredAt = elapsed
			elseif state.mode == "server" then
				humanoid.EvaluateStateMachine = false
				local direction = state.input or root:GetAttribute("F2StudyInput")
				root.AssemblyLinearVelocity = Study.steer(
					root.AssemblyLinearVelocity,
					if Study.vector(direction) then direction else Vector3.zero,
					dt
				)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	finishState(player, "departed")
	ready[player], pings[player], lastRequest[player], lastReport[player] = nil, nil, nil, nil
end)

if not automated then
	print("F2 physics fixture: K switches ownership; L launches yourself backward. No combat is enabled.")
	return
end

local timeout = task.delay(180, function()
	Test:EndTest({ passed = false, error = "F2 study timed out" })
end)
local passed, failure = pcall(function()
	local deadline = os.clock() + 25
	local players
	repeat
		players = Players:GetPlayers()
		local count = 0
		for _, player in players do
			if ready[player] and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				count += 1
			end
		end
		if #players == 2 and count == 2 then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(#players == 2 and ready[players[1]] and ready[players[2]], "F2 needs two ready clients with controllers")
	table.sort(players, function(a, b)
		return a.Name < b.Name
	end)
	if args.awaitNetwork then
		workspace:SetAttribute("F2StudyWaitingNetwork", true)
		local networkDeadline = os.clock() + 45
		repeat
			task.wait(0.1)
		until workspace:GetAttribute("F2StudyNetworkReady") == true or os.clock() > networkDeadline
		assert(
			workspace:GetAttribute("F2StudyNetworkReady") == true,
			"F2 network profile must be configured in the test process before trials"
		)
	end
	task.wait(2)
	for _, player in players do
		pings[player] = { id = player.UserId, sent = os.clock() }
		remote:FireClient(player, "ping", player.UserId)
	end
	task.wait(1)
	for _, player in players do
		remote:FireClient(player, "invalid-requests")
	end
	task.wait(0.3)
	assert(rejectedRequests == 6, "F2 automated mode must reject all untrusted launch requests")
	local probes = args.probes
		or {
			"idle",
			"walk",
			"jump",
			"reverse",
			"airborne",
			"wall",
			"resist",
			"teleport",
			"speed",
			"relaunch",
			"replacement",
		}
	for _, player in players do
		for _, mode in { "client", "server" } do
			for _, probe in probes do
				for _ = 1, (args.repeats or 1) do
					local root = player.Character.HumanoidRootPart
					root:SetNetworkOwner(nil)
					root.Anchored = true
					player.Character:PivotTo(CFrame.new(-12, if probe == "airborne" then 85 else 45, 0))
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					if probe == "wall" then
						wall = Instance.new("Part")
						wall.Name, wall.Size, wall.CFrame, wall.Anchored =
							"F2StudyWall", Vector3.new(1, 20, 20), CFrame.new(-4, 48, 0), true
						wall.Parent = workspace
					end
					-- Let the anchored reset replicate before changing ownership again.
					task.wait(0.2)
					root.Anchored = false
					root:SetNetworkOwner(player)
					pings[player] = { id = nextId + 1, sent = os.clock() }
					remote:FireClient(player, "ping", nextId + 1)
					task.wait(0.5)
					local launch = if probe == "teleport"
							or probe == "speed"
							or probe == "jump"
							or probe == "walk"
						then nil
						else Study.Launch
					local result = beginState(player, mode, probe, launch)
					active[player].origin = root.Position
					root:SetAttribute("F2StudyJump", probe == "jump")
					reports[result.id] = {}
					task.wait(0.12)
					root:SetAttribute("F2StudyJump", nil)
					if probe == "relaunch" then
						local first = result
						result = beginState(player, mode, probe, -Vector3.xAxis * 50 + Vector3.yAxis * 12)
						assert(first.release == "replaced", "A replacement launch must clean up the prior displacement")
						reports[first.id] = nil
						reports[result.id] = {}
						result.previousLaunch = first.initial
					elseif probe == "replacement" then
						local previous = player.Character
						previous.Humanoid.Health = 0
						task.wait(0.1)
						assert(
							active[player] == nil and previous.Humanoid.EvaluateStateMachine,
							"Character death must restore the motor and release study state"
						)
						local untilRespawn = os.clock() + Players.RespawnTime + 5
						repeat
							task.wait(0.1)
						until player.Character ~= previous or os.clock() > untilRespawn
						assert(player.Character ~= previous, "F1 must replace the dead study character")
					end
					task.wait(1.08)
					finishState(player, "trial-end")
					task.wait(0.2)
					remote:FireAllClients("finish", result.id)
					task.wait(0.3)
					result.clients = reports[result.id]
					reports[result.id] = nil
					table.insert(results, result)
					if wall then
						wall:Destroy()
						wall = nil
					end
					assert(#result.server > 0, "F2 trial must record server samples")
					assert(
						result.clients[players[1].Name] and result.clients[players[2].Name],
						"F2 trial must record subject and observer samples"
					)
					result.checks = {}
					if probe ~= "replacement" then
						result.checks.motorRestored = result.clients[player.Name].motorEnabled
					end
					if probe == "teleport" or probe == "speed" then
						result.checks.detected = result.corrections > 0
					else
						result.checks.noFalseCorrection = result.corrections == 0
					end
					local first = result.server[1]
					local travel, rise = 0, 0
					for _, sample in result.server do
						travel = math.max(travel, math.abs(sample[2] - first[2]))
						rise = math.max(rise, sample[3] - first[3])
					end
					result.maxTravel, result.maxRise = travel, rise
					if probe == "jump" then
						result.checks.jumped = rise > 3
					end
					if probe == "walk" then
						result.checks.walked = travel > 8
					end
					if probe == "airborne" then
						local standingHeight = Config.PlatformCenter.Y
							+ Config.PlatformThickness / 2
							+ player.Character.Humanoid.HipHeight
							+ root.Size.Y / 2
						result.checks.airborne = result.clients[player.Name].samples[1][3] > standingHeight + 1
					end
					if probe == "idle" or probe == "reverse" or probe == "airborne" then
						result.checks.launched = travel > 2
					end
				end
			end
		end
	end
end)
task.cancel(timeout)
for player in active do
	finishState(player, "cleanup")
end
connection:Disconnect()
if wall then
	wall:Destroy()
end
remote:Destroy()
local checksPassed = true
for _, result in results do
	for _, check in result.checks or {} do
		checksPassed = checksPassed and check
	end
end
Test:EndTest({
	passed = passed,
	error = if passed then nil else tostring(failure),
	trials = results,
	rejectedRequests = rejectedRequests,
	behaviorChecksPassed = checksPassed,
	architectureApproved = false,
})
