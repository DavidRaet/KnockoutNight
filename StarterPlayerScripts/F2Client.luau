local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(Storage:WaitForChild("F2Config", 10))
local Fist = require(Storage:WaitForChild("F2SpringFist", 10))
local Weapons = require(Storage:WaitForChild("F2Weapons", 10))
local Gust = require(Storage:WaitForChild("F8Gust", 10))
local Magnet = require(Storage:WaitForChild("F9Magnet", 10))
local Debris = game:GetService("Debris")
local Hammer = Weapons.WreckingHammer
local Slam = require(Storage.F11Slam)
local Paddles = Weapons.PaddlePops
local remote = Storage:WaitForChild("F2Combat", 10)
assert(remote and remote:IsA("RemoteEvent"), "F2 client requires the combat remote")
local player = Players.LocalPlayer
local Client = {}
local records, connections = {}, {}
local sequence, lastSend = 0, -math.huge
local motor, motorEnabled, restart = nil, true, nil
local folder = Instance.new("Folder")
folder.Name = "F2Presentation"
folder.Parent = workspace

local function restoreMotor()
	if motor then
		motor.EvaluateStateMachine = motorEnabled
		if motorEnabled and motor.Health > 0 then
			motor:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		motor = nil
	end
end

local function part(name, size)
	local p = Instance.new("Part")
	p.Name, p.Size = name, size
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Parent = folder
	return p
end

local function clear(character)
	local record = records[character]
	if not record then
		return
	end
	for _, p in record.parts do
		p:Destroy()
	end
	records[character] = nil
end

local function recordFor(character)
	local gen = character:GetAttribute("F2Generation")
	if not gen or character:GetAttribute("F2Equipped") ~= true then
		return nil
	end
	local record = records[character]
	if record and record.generation ~= gen then
		clear(character)
		record = nil
	end
	if not record then
		record = {
			generation = gen,
			nextHand = character:GetAttribute("F7NextHand") or "Right",
			config = Weapons[character:GetAttribute("F2Weapon")] or Config,
			parts = {
				glove = part("SpringFistGlove", Vector3.new(1.6, 1.6, 1.6)),
				extension = part("SpringFistExtension", Vector3.new(0.35, 0.35, 1)),
				box = part("SpringFistVolume", Config.Size),
			},
		}
		if record.config == Paddles then
			for _, hand in { "Left", "Right" } do
				record.parts[hand] = part(hand .. "FoamPaddle", Vector3.new(1.3, 1.8, 0.3))
				record.parts[hand .. "Handle"] = part(hand .. "PaddleHandle", Vector3.new(0.25, 0.7, 0.25))
				record.parts[hand].Material = Enum.Material.SmoothPlastic
			end
		end
		records[character] = record
	end
	return record
end

local hud = Instance.new("ScreenGui")
hud.Name, hud.ResetOnSpawn, hud.Parent = "F8HUD", false, player:WaitForChild("PlayerGui")
local status = Instance.new("TextLabel")
status.Name, status.Size, status.Position = "GustStatus", UDim2.fromOffset(260, 32), UDim2.new(0.5, -130, 1, -60)
status.BackgroundTransparency, status.TextSize, status.TextColor3 = 0.35, 18, Color3.new(1, 1, 1)
status.Parent = hud
status.Name = "AbilityStatus"
local rejectionUntil, rejection = 0, ""

local function gustCue(record, origin, aim, burst)
	local base = CFrame.lookAt(origin, origin + aim)
	for i = -2, 2 do
		local p = part(if burst then "GustBurst" else "GustAccepted", Vector3.new(0.10, 0.10, if burst then 2 else 0.5))
		p.Color, p.Transparency = Color3.fromRGB(170, 240, 255), 0.3
		local direction = (base * CFrame.Angles(0, math.rad(i * Gust.Cone / 4), 0)).LookVector
		local start = origin - aim * (if burst then 1 else 0.5)
		p.CFrame = CFrame.lookAt(start, start + direction)
		record.parts["gust" .. i] = p
		game:GetService("TweenService")
			:Create(p, TweenInfo.new(0.18), {
				CFrame = CFrame.lookAt(origin + direction * Gust.Range, origin + direction * (Gust.Range + 1)),
				Transparency = 1,
			})
			:Play()
		Debris:AddItem(p, 0.22)
	end
	if burst then
		local sound = Instance.new("Sound")
		sound.SoundId, sound.Volume, sound.PlaybackSpeed = "rbxasset://sounds/action_falling.ogg", 0.3, 1.3
		sound.Parent = record.parts.gust0
		sound:Play()
	end
end

local function magnetCue(record, origin, aim, burst)
	for i = -1, 1, 2 do
		local p = part("MagnetCue", Vector3.new(0.35, 0.35, 1.2))
		p.Color = if i < 0 then Color3.fromRGB(255, 90, 110) else Color3.fromRGB(90, 140, 255)
		local side = Vector3.new(-aim.Z, 0, aim.X) * i * 0.8
		p.CFrame = CFrame.lookAt(origin + side + aim * (if burst then Magnet.Range else 1), origin + side)
		record.parts["magnet" .. i] = p
		game:GetService("TweenService")
			:Create(p, TweenInfo.new(0.25), {
				CFrame = CFrame.lookAt(origin + side + aim, origin + side),
				Transparency = 1,
			})
			:Play()
		Debris:AddItem(p, 0.3)
	end
	local sound = Instance.new("Sound")
	sound.SoundId, sound.Volume, sound.PlaybackSpeed = "rbxasset://sounds/electronicpingshort.wav", 0.25, 0.8
	sound.Parent = record.parts["magnet1"]
	sound:Play()
end

local function bounceCue(record, origin)
	local ring = part("BounceLaunch", Vector3.new(3, 0.15, 3))
	ring.CFrame = CFrame.new(origin - Vector3.yAxis * 2)
	ring.Color = Color3.fromRGB(150, 255, 150)
	record.parts.bounce = ring
	game:GetService("TweenService")
		:Create(ring, TweenInfo.new(0.3), {
			Size = Vector3.new(5, 0.1, 5),
			Transparency = 1,
		})
		:Play()
	local sound = Instance.new("Sound")
	sound.SoundId, sound.Volume, sound.PlaybackSpeed = "rbxasset://sounds/electronicpingshort.wav", 0.25, 1.5
	sound.Parent = ring
	sound:Play()
	Debris:AddItem(ring, 0.35)
end

function Client.ability(character, aim, direction)
	local record = recordFor(character)
	if not record then
		return
	end
	local ability = player:GetAttribute("F10Ability") or "Bounce"
	sequence += 1
	remote:FireServer(
		string.lower(ability),
		record.generation,
		sequence,
		if ability == "Bounce" then direction else aim
	)
end

function Client.magnet(character, aim)
	local record = recordFor(character)
	if record then
		sequence += 1
		remote:FireServer("magnet", record.generation, sequence, aim)
	end
end

function Client.gust(character, aim)
	local record = recordFor(character)
	if record then
		sequence += 1
		remote:FireServer("gust", record.generation, sequence, aim)
	end
end

function Client.press(character, aim)
	local record = recordFor(character)
	if
		not record
		or workspace:GetServerTimeNow()
			< (character.HumanoidRootPart:GetAttribute("F10PrimaryAt") or record.primaryAt or 0)
	then
		return
	end
	sequence += 1
	remote:FireServer("press", record.generation, sequence, aim)
	local now = workspace:GetServerTimeNow()
	local config = record.config
	if not record.action then
		record.action = { sequence = sequence, started = now, aim = aim, predicted = true, hand = record.nextHand }
	elseif
		record.action.config ~= Gust
		and record.action.config ~= Slam
		and record.action.config ~= Magnet
		and Fist.canBuffer(now - record.action.started, record.buffer ~= nil, false, config)
	then
		record.buffer = { sequence = sequence, startsAt = record.action.started + config.Duration }
	end
end

function Client.permissions(character)
	local record = records[character]
	local action = record and record.action
	local now = workspace:GetServerTimeNow()
	if action and now < (action.endsAt or action.started + (action.config or record.config).Duration) then
		return (action.config or record.config).MoveScale, (action.config or record.config).CanJump == true, action.aim
	end
	return 1, true, nil
end

function Client.update(character, aim, direction, enabled)
	if not character then
		restoreMotor()
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	local displaced = root:GetAttribute("F2Displaced")
	if displaced then
		if motor ~= humanoid then
			restoreMotor()
			local saved = root:GetAttribute("F2MotorEnabled")
			if typeof(saved) ~= "boolean" then
				return
			end
			motor, motorEnabled = humanoid, saved
		end
		humanoid.EvaluateStateMachine = false
	else
		restoreMotor()
		local token = root:GetAttribute("F2Restart")
		if token ~= restart then
			restart = token
			if humanoid.EvaluateStateMachine and humanoid.Health > 0 then
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end
	end
	local now = workspace:GetServerTimeNow()
	if now - lastSend >= Config.InputInterval + 0.005 then
		lastSend = now
		local record = recordFor(character)
		if record then
			if enabled then
				remote:FireServer("aim", record.generation, 0, aim)
			end
			if displaced then
				remote:FireServer("steer", record.generation, 0, if enabled then direction else Vector3.zero)
			end
		end
	end
end

table.insert(
	connections,
	remote.OnClientEvent:Connect(function(kind, data)
		if type(data) ~= "table" or typeof(data.character) ~= "Instance" or not data.character:IsA("Model") then
			return
		end
		local character = data.character
		if character:GetAttribute("F2Generation") ~= data.generation then
			return
		end
		if kind == "clear" then
			clear(character)
			return
		end
		local record = recordFor(character)
		if not record then
			return
		end
		if kind == "accepted" then
			record.config = Weapons[data.weapon] or record.config
			if character == player.Character and record.action and record.action.sequence == data.sequence then
				player:SetAttribute("F2PredictionMismatchMs", (data.started - record.action.started) * 1000)
				player:SetAttribute("F2AcceptanceAgeMs", (workspace:GetServerTimeNow() - data.started) * 1000)
			end
			record.action = {
				id = data.id,
				sequence = data.sequence,
				started = data.started,
				aim = data.aim,
				hand = data.hand,
				config = if data.ability == "GroundSlam"
					then Slam
					elseif data.ability == "Magnet" then Magnet
					elseif data.ability == "Gust" then Gust
					else record.config,
			}
			if data.ability == "Magnet" then
				magnetCue(record, character.HumanoidRootPart.Position, data.aim, false)
			elseif data.ability == "Gust" then
				gustCue(record, character.HumanoidRootPart.Position, data.aim, false)
			end
			if data.hand then
				record.nextHand = Paddles.other(data.hand)
			end
			if record.buffer and record.buffer.sequence == data.sequence then
				record.buffer = nil
			end
		elseif kind == "slam-impact" then
			if record.action and record.action.id == data.id then
				record.action.landed, record.action.endsAt = workspace:GetServerTimeNow(), data.endsAt
			end
			local wave = part("SlamShockwave", Vector3.new(0.15, Slam.Radius * 2, Slam.Radius * 2))
			wave.Shape = Enum.PartType.Cylinder
			wave.CFrame = CFrame.new(data.origin + Vector3.yAxis * 0.1) * CFrame.Angles(0, 0, math.pi / 2)
			wave.Color, wave.Transparency = Color3.fromRGB(255, 190, 40), 0.65
			record.parts.slamWave = wave
			Debris:AddItem(wave, 0.2)
		elseif kind == "buffered" then
			record.buffer = { sequence = data.sequence, startsAt = data.startsAt }
		elseif kind == "bounce" then
			record.displacement, record.primaryAt = data.displacement, data.primaryAt
			record.buffer = nil
			bounceCue(record, character.HumanoidRootPart.Position)
		elseif kind == "pull" then
			record.displacement = data.displacement
		elseif kind == "magnet-pull" then
			if data.target and data.target.Parent then
				local sourceRoot, targetRoot =
					character:FindFirstChild("HumanoidRootPart"), data.target:FindFirstChild("HumanoidRootPart")
				if sourceRoot and targetRoot then
					local length = (targetRoot.Position - sourceRoot.Position).Magnitude
					local p = part("MagnetLink", Vector3.new(0.12, 0.12, math.max(0.01, length)))
					p.CFrame = CFrame.lookAt((sourceRoot.Position + targetRoot.Position) / 2, targetRoot.Position)
					record.parts.magnetLink = p
					Debris:AddItem(p, Magnet.PullDuration)
				end
			end
		elseif kind == "magnet-burst" then
			magnetCue(record, data.origin, data.aim, true)
		elseif kind == "gust-burst" then
			gustCue(record, data.origin, data.aim, true)
		elseif kind == "rejected" then
			if data.ability then
				rejection, rejectionUntil = data.ability .. ": " .. data.reason, workspace:GetServerTimeNow() + 0.8
			end
			if record.action and record.action.sequence == data.sequence then
				record.action = nil
			end
			if record.buffer and record.buffer.sequence == data.sequence then
				record.buffer = nil
			end
		elseif kind == "cancel" then
			if record.action and record.action.id == data.id then
				record.action = nil
			end
			record.buffer = nil
		elseif kind == "wall" and record.action and record.action.id == data.id then
			record.action.wallReach = data.reach
		elseif kind == "shield" then
			record.shieldUntil = workspace:GetServerTimeNow() + 0.12
			if not record.parts.shield then
				local shield = part("PaddleShieldContact", Vector3.one * 2)
				shield.Shape = Enum.PartType.Ball
				record.parts.shield = shield
			end
			record.parts.shield.CFrame = CFrame.new(data.point)
		elseif kind == "hit" then
			record.displacement = data.displacement
			if character == player.Character then
				player:SetAttribute("F2ImpactDelayMs", (workspace:GetServerTimeNow() - data.at) * 1000)
			end
			record.impactUntil = workspace:GetServerTimeNow() + 0.1
			record.buffer = nil
		elseif kind == "release" and record.displacement == data.displacement then
			local root = character:FindFirstChild("HumanoidRootPart")
			if
				character == player.Character
				and root
				and (root:GetAttribute("F2Displaced") or 0) <= data.displacement
			then
				-- Ownership can arrive before the last server pose; resume from the authoritative release snapshot.
				root.CFrame = data.frame
				root.AssemblyLinearVelocity = data.velocity
			end
			record.displacement = nil
		elseif kind == "corrected" then
			record.buffer = nil
		end
	end)
)

table.insert(
	connections,
	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		local ability = player:GetAttribute("F10Ability") or "Bounce"
		local attribute = if ability == "Gust"
			then "F8ReadyAt"
			elseif ability == "Magnet" then "F9ReadyAt"
			else "F10ReadyAt"
		local remaining = math.max(0, (player:GetAttribute(attribute) or 0) - now)
		status.Text = if now < rejectionUntil
			then rejection
			elseif remaining > 0 then string.format("Q %s: %.1fs", ability, remaining)
			else "Q " .. ability .. ": Ready"
		hud.Enabled = player:GetAttribute("F3Status") == "alive"
		for _, other in Players:GetPlayers() do
			if other.Character then
				recordFor(other.Character)
			end
		end
		for character, record in records do
			local root = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if
				not character.Parent
				or not root
				or not humanoid
				or humanoid.Health <= 0
				or character:GetAttribute("F2Generation") ~= record.generation
				or character:GetAttribute("F2Equipped") ~= true
			then
				clear(character)
				continue
			end
			local config = record.config
			local action = record.action
			if action and now >= (action.endsAt or action.started + (action.config or config).Duration) then
				record.action = nil
				action = nil
			end
			if record.buffer and now >= record.buffer.startsAt then
				local buffer = record.buffer
				record.buffer = nil
				if
					character == player.Character
					and (not root:GetAttribute("F2Displaced") or root:GetAttribute("F9Pulling"))
					and now >= (root:GetAttribute("F2ReactionUntil") or 0)
				then
					local aim = player:GetAttribute("F2IntendedAim")
					if Fist.aim(aim) then
						action = {
							sequence = buffer.sequence,
							started = now,
							aim = aim,
							predicted = true,
							hand = record.nextHand,
						}
						record.action = action
					end
				end
			end
			local age = if action then now - action.started else 0
			local phase = if action and action.config == Slam
				then (if action.landed then "recovery" elseif age < Slam.Startup then "startup" else "active")
				elseif action and action.config ~= Gust and action.config ~= Magnet then Fist.phase(age, config)
				else nil
			local reach = 0.6
			if phase == "active" then
				reach = Fist.reach(age, Config)
			elseif phase == "recovery" then
				reach = Config.EndReach * (1 - (age - Config.Startup - Config.Active) / Config.Recovery)
			end
			if action and action.wallReach then
				reach = math.min(reach, action.wallReach)
			end
			local aim = if action then action.aim else root.CFrame.LookVector
			local origin = root.Position + Vector3.yAxis * Config.StrikeHeight
			local center = origin + aim * reach
			local frame = CFrame.lookAt(center, center + aim)
			local color = if phase == "startup"
				then Color3.fromRGB(255, 190, 40)
				elseif phase == "active" then Color3.fromRGB(255, 75, 65)
				elseif phase == "recovery" then Color3.fromRGB(95, 140, 190)
				else Color3.fromRGB(170, 175, 185)
			if (record.impactUntil or 0) > now then
				color = Color3.new(1, 1, 1)
			elseif (root:GetAttribute("F2ProtectionUntil") or 0) > now then
				color = Color3.fromRGB(80, 230, 255)
			end
			for key, p in record.parts do
				if not p.Parent then
					record.parts[key] = nil
					continue
				end
				if string.sub(key, 1, 6) ~= "magnet" and key ~= "bounce" then
					p.Color = color
				end
			end
			if record.parts.shield then
				record.parts.shield.Color = Color3.fromRGB(80, 230, 255)
				record.parts.shield.Transparency = if (record.shieldUntil or 0) > now then 0.45 else 1
			end
			record.parts.glove.CFrame = frame
			record.parts.glove.Size = if phase == "active" then Config.Size else Vector3.new(1.6, 1.6, 1.6)
			record.parts.extension.Size = Vector3.new(0.35, 0.35, math.max(0.05, reach))
			record.parts.extension.CFrame = CFrame.lookAt(origin + aim * reach / 2, center + aim)
			record.parts.box.CFrame = frame
			if action and action.config == Slam then
				local lift = if action.landed
					then -1
					elseif age < Slam.Startup then 1 + 3 * math.clamp(age / Slam.Startup, 0, 1)
					else 4
				local grip = root.Position + aim * 1.5
				local head = grip + Vector3.yAxis * lift
				record.parts.glove.Size = Vector3.new(2.4, 1.8, 2)
				record.parts.glove.CFrame = CFrame.lookAt(head, head + aim)
				record.parts.extension.Size = Vector3.new(0.35, math.abs(lift), 0.35)
				record.parts.extension.CFrame = CFrame.new((grip + head) / 2)
				record.parts.box.Transparency = 1
			elseif config == Hammer then
				-- A raised windup, 100-degree active swing, then a low follow-through returning to guard.
				local poseAge = Hammer.Startup
				local lift, radius = 0, 6
				if phase == "startup" then
					local progress = math.clamp(age / Hammer.Startup, 0, 1)
					lift, radius = 1.5 * progress, 2.5 + 3.5 * progress
				elseif phase == "recovery" then
					poseAge = Hammer.Startup + Hammer.Active
					local progress = (age - Hammer.Startup - Hammer.Active) / Hammer.Recovery
					poseAge = Hammer.Startup + Hammer.Active * (1 - progress)
					radius = 6 - 3.5 * progress
				elseif phase == "active" then
					poseAge = age
					lift = 1.5 * (1 - (age - Hammer.Startup) / Hammer.Active)
				else
					radius, lift = 2.5, 0.5
				end
				local blade = Hammer.frame(root.Position, aim, poseAge)
				local swingAim = blade.LookVector
				local grip = origin + Vector3.yAxis * lift
				local head = grip + swingAim * radius
				record.parts.glove.Name = "WreckingHammerHead"
				record.parts.glove.Size = Vector3.new(2.4, 1.8, 2)
				record.parts.glove.CFrame = CFrame.lookAt(head, head + swingAim)
				record.parts.extension.Name = "WreckingHammerHandle"
				record.parts.extension.Size = Vector3.new(0.35, 0.35, radius)
				record.parts.extension.CFrame = CFrame.lookAt(grip + swingAim * radius / 2, head)
				record.parts.box.Size, record.parts.box.CFrame = Hammer.Size, blade
			elseif config == Paddles then
				record.parts.glove.Transparency, record.parts.extension.Transparency = 1, 1
				local facing = CFrame.lookAt(root.Position, root.Position + aim)
				for _, hand in { "Left", "Right" } do
					local side = if hand == "Left" then -1 else 1
					local distance, offset = 0.6, side * 1.2
					if action and action.hand == hand then
						if phase == "startup" then
							distance = 0.6 - 0.5 * math.clamp(age / Paddles.Startup, 0, 1)
						elseif phase == "active" then
							distance = 4.5 + 0.7 * math.clamp((age - Paddles.Startup) / Paddles.Active, 0, 1)
							offset = side * 0.5
						elseif phase == "recovery" then
							local progress =
								math.clamp((age - Paddles.Startup - Paddles.Active) / Paddles.Recovery, 0, 1)
							distance, offset = 5.2 - 4.6 * progress, side * (0.5 + 0.7 * progress)
						end
					else
						record.parts[hand].Color = Color3.fromRGB(70, 185, 160)
					end
					local paddleFrame = facing * CFrame.new(offset, 0, -distance)
					record.parts[hand].CFrame = paddleFrame
					record.parts[hand .. "Handle"].CFrame = paddleFrame * CFrame.new(0, -1.1, 0)
				end
				record.parts.box.Size = Paddles.Size
				record.parts.box.CFrame =
					Paddles.frame(root.Position, aim, if action then action.hand else record.nextHand)
			end
			record.parts.box.Transparency = if workspace:GetAttribute("F2DebugVolumes") == true
					and phase == "active"
					and not (action and action.config == Slam)
				then 0.75
				else 1
		end
	end)
)

function Client.stop()
	restoreMotor()
	for _, connection in connections do
		connection:Disconnect()
	end
	for character in records do
		clear(character)
	end
	folder:Destroy()
	hud:Destroy()
	player:SetAttribute("F2IntendedAim", nil)
	for _, name in { "F2PredictionMismatchMs", "F2AcceptanceAgeMs", "F2ImpactDelayMs" } do
		player:SetAttribute(name, nil)
	end
end

return Client
