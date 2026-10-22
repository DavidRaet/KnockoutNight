local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Config = require(Storage.F4Config)
local Rules = require(Storage.F4Rules)
local Lives = require(script.Parent.F3Lives)
local Combat = require(script.Parent.F2Combat)
local Match = {}
local state, snapshot, remote
local connections, departures, returned = {}, {}, {}
local serial, revision = 0, 0
local lastPayload
local running = false

local function publish()
	local data = { session = serial, phase = "staging", roster = {} }
	if state then
		data.phase, data.goAt, data.startedAt, data.deadline = state.phase, state.goAt, state.startedAt, state.deadline
		data.result = state.result
		for side, player in state.roster do
			data.roster[side] = { id = player.UserId, name = player.DisplayName, score = state.scores[side] }
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

function Match.commit(player, life, session, at, event)
	return state ~= nil and Match.allowed(at) and Rules.commit(state, session, player, life, at, event)
end

-- Developer-controlled launch only; player-facing queues belong to L2/L3.
function Match.begin()
	if not running or not snapshot or not Match.canJoin() then
		return false
	end
	local roster = Lives.roster()
	if #roster ~= 2 then
		return false
	end
	serial += 1
	table.clear(departures)
	table.clear(returned)
	state = Rules.new(serial, roster, workspace:GetServerTimeNow(), Config)
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

function Match.step()
	if not running or not snapshot then
		return
	end
	if not state then
		Match.begin()
		return
	end
	local now = workspace:GetServerTimeNow()
	for _, player in state.roster do
		if player.Parent ~= Players then
			departures[player] = true
		end
	end
	local previous = state.phase
	local events = Rules.step(state, now, departures, Config)
	table.clear(departures)
	for side, player in state.roster do
		Lives.setScore(player, state.scores[side])
	end
	for _, event in events do
		Lives.notify(event)
	end
	if previous ~= state.phase then
		local active = state.phase == "regulation"
		for _, player in state.roster do
			Lives.freeze(player, not active, not active)
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
	if state and Rules.finish(state, "cancelled", nil, workspace:GetServerTimeNow(), Config) then
		publish()
	end
end

function Match.start()
	assert(not snapshot, "F4 match coordinator must start once")
	running = true
	snapshot = Instance.new("StringValue")
	snapshot.Name = "F4State"
	remote = Instance.new("RemoteEvent")
	remote.Name = "F4Return"
	Lives.bindMatch(Match)
	Combat.bindMatch(Match)
	publish()
	snapshot.Parent, remote.Parent = Storage, Storage
	table.insert(connections, remote.OnServerEvent:Connect(Match.returnToStaging))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			departures[player] = true
		end)
	)
end

function Match.stop()
	running = false
	if state and not state.result then
		Rules.finish(state, "interrupted", nil, workspace:GetServerTimeNow(), Config)
		for _, player in state.roster do
			Lives.freeze(player, true, true)
		end
		publish()
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if remote then
		remote:Destroy()
		remote = nil
	end
	-- Keep the last snapshot available while shutdown is visible to clients.
end

return Match
