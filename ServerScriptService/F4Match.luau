local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Config = require(Storage.F4Config)
local Rules = require(Storage.F4Rules)
local Lives = require(script.Parent.F3Lives)
local Combat = require(script.Parent.F2Combat)
local Admins = require(script.Parent.F4Admins)
local Match = {}
local state, snapshot, remote, adminRemote, weaponRemote
local lastWeaponRequest = {}
local connections, departures, returned, lastAdminRequest = {}, {}, {}, {}
local serial, revision = 0, 0
local lastPayload
local running = false
local nextConfig = { OpeningCountdown = Config.OpeningCountdown, RegulationDuration = Config.RegulationDuration }

local function publish()
	local data = { session = serial, phase = "staging", roster = {}, nextConfig = table.clone(nextConfig) }
	if state and state.phase ~= "staging" then
		data.phase, data.goAt, data.startedAt, data.deadline = state.phase, state.goAt, state.startedAt, state.deadline
		data.result = state.result
		for side, player in state.roster do
			data.roster[side] = { id = player.UserId, name = player.DisplayName, score = state.scores[side] }
		end
	else
		for side, player in Lives.roster() do
			data.roster[side] = {
				id = player.UserId,
				name = player.DisplayName,
				score = player:GetAttribute("F3Score") or 0,
			}
		end
	end
	local payload = Http:JSONEncode(data)
	if payload ~= lastPayload then
		lastPayload = payload
		revision += 1
		data.revision = revision
		snapshot.Value = Http:JSONEncode(data)
	end
end

function Match.canJoin()
	return state == nil or state.phase == "staging"
end

function Match.chooseWeapon(player, weapon)
	if
		not running
		or player.Parent ~= Players
		or not Match.canJoin()
		or player:GetAttribute("F3Status") ~= "waiting"
		or (weapon ~= "SpringFist" and weapon ~= "WreckingHammer")
	then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now - (lastWeaponRequest[player] or -math.huge) < 0.15 then
		return false
	end
	lastWeaponRequest[player] = now
	player:SetAttribute("F2Weapon", weapon)
	return true
end

function Match.allowed(now)
	if not running or not state or not Rules.allowed(state, now) then
		return false
	end
	for _, player in state.roster do
		if departures[player] or player.Parent ~= Players then
			return false
		end
	end
	return true
end

function Match.session()
	return serial
end

function Match.respawns()
	return state ~= nil and state.phase == "regulation"
end

function Match.commit(player, life, session, at, event)
	return state ~= nil and Match.allowed(at) and Rules.commit(state, session, player, life, at, event)
end

-- Developer-controlled launch only; player-facing queues belong to L2/L3.
function Match.begin()
	if not running or not snapshot or not Match.canJoin() then
		return false
	end
	local roster = Lives.roster()
	if
		#roster ~= 2
		or roster[1]:GetAttribute("F3Status") ~= "waiting"
		or roster[2]:GetAttribute("F3Status") ~= "waiting"
	then
		return false
	end
	serial += 1
	table.clear(departures)
	table.clear(returned)
	local matchConfig = {
		OpeningCountdown = nextConfig.OpeningCountdown,
		RegulationDuration = nextConfig.RegulationDuration,
		ResultsDuration = Config.ResultsDuration,
	}
	state = Rules.new(serial, roster, workspace:GetServerTimeNow(), matchConfig)
	state.config = matchConfig
	for _, player in roster do
		Lives.reset(player)
	end
	publish()
	return true
end

function Match.returnToStaging(player, session)
	if
		not state
		or session ~= state.id
		or not state.result
		or not table.find(state.roster, player)
		or returned[player]
	then
		return false
	end
	returned[player] = true
	Lives.stage(player)
	return true
end

local function integerInRange(value, minimum, maximum)
	return type(value) == "number"
		and value == value
		and math.abs(value) ~= math.huge
		and value % 1 == 0
		and value >= minimum
		and value <= maximum
end

local function respond(player, ok, message)
	adminRemote:FireClient(player, "result", ok, message)
	publish()
end

local function adminRequest(player, command, first, second)
	if not Admins[player.UserId] then
		return
	end
	local now = workspace:GetServerTimeNow()
	if now - (lastAdminRequest[player] or -math.huge) < 0.15 then
		return
	end
	lastAdminRequest[player] = now
	if command == "configure" then
		if not integerInRange(first, 0, 10) or not integerInRange(second, 1, 1800) then
			return respond(player, false, "Countdown must be 0–10 seconds; regulation must be 1–1800 seconds.")
		end
		nextConfig = { OpeningCountdown = first, RegulationDuration = second }
		return respond(player, true, "Next match settings saved for this server.")
	elseif command == "remaining" then
		if not integerInRange(first, 0, 1800) or not state or state.phase ~= "regulation" then
			return respond(player, false, "Remaining time can be changed only during regulation (0–1800 seconds).")
		end
		state.deadline = now + first
		return respond(player, true, "Active regulation time updated.")
	elseif command == "end-now" then
		if not state or state.phase ~= "regulation" then
			return respond(player, false, "There is no active regulation to end.")
		end
		state.deadline = now
		return respond(player, true, "Regulation will resolve using the current score.")
	elseif command == "cancel" then
		if not state or state.phase == "staging" or state.result then
			return respond(player, false, "There is no unfinished match to cancel.")
		end
		if Rules.finish(state, "cancelled", nil, now, state.config) then
			for _, participant in state.roster do
				Lives.freeze(participant, true, true)
			end
			return respond(player, true, "Match cancelled with no winner.")
		end
	elseif command == "start" then
		if not Match.begin() then
			return respond(player, false, "Start requires exactly two admitted players in local staging.")
		end
		return respond(player, true, "Match countdown started.")
	end
	respond(player, false, "Unknown or invalid developer command.")
end

function Match.step()
	if not running or not snapshot then
		return
	end
	if not state then
		publish()
		return
	end
	local now = workspace:GetServerTimeNow()
	for _, player in state.roster do
		if player.Parent ~= Players then
			departures[player] = true
		end
	end
	local previous = state.phase
	local events = Rules.step(state, now, departures, state.config)
	table.clear(departures)
	for side, player in state.roster do
		Lives.setScore(player, state.scores[side])
	end
	for _, event in events do
		Lives.notify(event)
	end
	if state.phase == "sudden-death-pending" then
		local lives = Lives.resetRound(state.roster)
		if not state.result then
			Rules.readySuddenDeath(state, workspace:GetServerTimeNow(), lives, Config)
		end
	end
	if previous ~= state.phase then
		local active = state.phase == "regulation" or state.phase == "sudden-death"
		for _, player in state.roster do
			Lives.freeze(player, not active, not active and state.phase ~= "sudden-death-countdown")
			if active then
				Combat.resetMovement(player)
			end
		end
	end
	if state.result then
		local allReturned = true
		for _, player in state.roster do
			if player.Parent == Players then
				if now >= state.result.returnAt then
					Match.returnToStaging(player, state.id)
				end
				allReturned = allReturned and returned[player] == true
			end
		end
		if allReturned then
			state.phase = "staging"
		end
	end
	publish()
end

function Match.fail()
	if state and Rules.finish(state, "cancelled", nil, workspace:GetServerTimeNow(), state.config) then
		publish()
	end
end

function Match.start()
	assert(not snapshot, "F4 match coordinator must start once")
	running = true
	for _, player in Players:GetPlayers() do
		player:SetAttribute("F4AdminAuthorized", Admins[player.UserId] == true)
	end
	snapshot = Instance.new("StringValue")
	snapshot.Name = "F4State"
	remote = Instance.new("RemoteEvent")
	remote.Name = "F4Return"
	adminRemote = Instance.new("RemoteEvent")
	adminRemote.Name = "F4Admin"
	weaponRemote = Instance.new("RemoteEvent")
	weaponRemote.Name, weaponRemote.Parent = "F6WeaponChoice", Storage
	Lives.bindMatch(Match)
	Combat.bindMatch(Match)
	publish()
	snapshot.Parent, remote.Parent, adminRemote.Parent = Storage, Storage, Storage
	table.insert(connections, remote.OnServerEvent:Connect(Match.returnToStaging))
	table.insert(connections, adminRemote.OnServerEvent:Connect(adminRequest))
	table.insert(connections, weaponRemote.OnServerEvent:Connect(Match.chooseWeapon))
	table.insert(
		connections,
		Players.PlayerAdded:Connect(function(player)
			player:SetAttribute("F4AdminAuthorized", Admins[player.UserId] == true)
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			departures[player] = true
			lastAdminRequest[player] = nil
			lastWeaponRequest[player] = nil
		end)
	)
end

function Match.stop()
	running = false
	if state and not state.result then
		Rules.finish(state, "interrupted", nil, workspace:GetServerTimeNow(), state.config)
		for _, player in state.roster do
			Lives.freeze(player, true, true)
		end
		publish()
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(lastWeaponRequest)
	for _, instance in { remote, adminRemote, weaponRemote } do
		if instance then
			instance:Destroy()
		end
	end
	remote, adminRemote, weaponRemote = nil, nil, nil
	-- Keep the last snapshot available while shutdown is visible to clients.
end

return Match
