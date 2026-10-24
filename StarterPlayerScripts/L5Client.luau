local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local remote = Storage:WaitForChild("L5Request", 10)
local snapshot = Storage:WaitForChild("L4State", 10)
assert(remote and remote:IsA("RemoteEvent"), "Map voting and private loadouts require L5Request")
assert(snapshot and snapshot:IsA("StringValue"), "Map voting requires the local session snapshot")
local Client, connections = {}, {}
local state, own = Http:JSONDecode(snapshot.Value), {}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "L5HUD", false, 2
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui", 10)
local panel = Instance.new("Frame")
panel.Name, panel.Size, panel.Position = "Selection", UDim2.new(0.86, 0, 0, 360), UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint, panel.BackgroundColor3 = Vector2.new(0.5, 0.5), Color3.fromRGB(21, 25, 34)
panel.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize, limit.Parent = Vector2.new(820, 360), panel
local function label(name, position, size, fontSize)
	local item = Instance.new("TextLabel")
	item.Name, item.Position, item.Size = name, position, size
	item.BackgroundTransparency, item.TextColor3 = 1, Color3.new(1, 1, 1)
	item.TextWrapped, item.Font, item.TextSize = true, Enum.Font.GothamMedium, fontSize
	item.Parent = panel
	return item
end
local title = label("Title", UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 50), 24)
local note = label("Notice", UDim2.new(0, 12, 1, -88), UDim2.new(1, -24, 0, 78), 16)
local function button(name, caption, position, size, command, value)
	local item = Instance.new("TextButton")
	item.Name, item.Text, item.Position, item.Size = name, caption, position, size
	item.Font, item.TextSize, item.TextWrapped = Enum.Font.GothamMedium, 18, true
	item.TextColor3, item.BackgroundColor3, item.BorderSizePixel = Color3.new(1, 1, 1), Color3.fromRGB(45, 65, 85), 0
	item.Parent = panel
	table.insert(
		connections,
		item.Activated:Connect(function()
			remote:FireServer(state.session, command, value)
		end)
	)
	return { item = item, caption = caption, value = value }
end
local maps, weapons, abilities = {}, {}, {}
for index, map in { { "ThePlatform", "The Platform" }, { "SkyBridges", "Sky Bridges" }, { "Dungeon", "Dungeon" } } do
	table.insert(
		maps,
		button(
			map[1],
			map[2],
			UDim2.new(0.04 + (index - 1) * 0.32, 0, 0, 100),
			UDim2.new(0.28, 0, 0, 100),
			"vote",
			map[1]
		)
	)
end
for index, weapon in
	{ { "SpringFist", "Spring Fist" }, { "WreckingHammer", "Wrecking Hammer" }, { "PaddlePops", "Paddle Pops" } }
do
	table.insert(
		weapons,
		button(
			weapon[1],
			weapon[2],
			UDim2.new(0.04, 0, 0, 72 + (index - 1) * 51),
			UDim2.new(0.44, 0, 0, 44),
			"weapon",
			weapon[1]
		)
	)
end
for index, ability in { "Gust", "Magnet", "Bounce" } do
	table.insert(
		abilities,
		button(
			ability,
			ability,
			UDim2.new(0.52, 0, 0, 72 + (index - 1) * 51),
			UDim2.new(0.44, 0, 0, 44),
			"ability",
			ability
		)
	)
end
local ready = button("Ready", "Ready", UDim2.new(0.3, 0, 0, 230), UDim2.new(0.4, 0, 0, 40), "ready").item
local defaults = label("Defaults", UDim2.new(0.1, 0, 0, -95), UDim2.new(0.8, 0, 0, 76), 18)
defaults.Parent, defaults.Position = gui, UDim2.new(0.1, 0, 0, 82)
local function update()
	local participant = state.roster and table.find(state.roster, player.UserId) ~= nil
	local voting, selecting = state.phase == "vote", state.phase == "selection"
	panel.Visible = participant and (voting or selecting) or false
	defaults.Visible = participant
			and state.phase == "match"
			and player:GetAttribute("L3State") == "match"
			and own.defaultWeapon ~= nil
			and workspace:GetServerTimeNow() < (own.noticeUntil or 0)
		or false
	if defaults.Visible then
		defaults.Text = "Loadout locked: "
			.. tostring(own.weapon)
			.. " + "
			.. tostring(own.ability)
			.. (
				if own.defaultWeapon or own.defaultAbility
					then "\nMissing choices assigned: "
						.. (if own.defaultWeapon then "Spring Fist " else "")
						.. (if own.defaultAbility then "Gust" else "")
					else ""
			)
	end
	if not panel.Visible then
		return
	end
	local seconds = math.ceil(math.max(0, (state.phaseDeadline or 0) - workspace:GetServerTimeNow()))
	title.Text = (if voting then "VOTE FOR A MAP · " else "CHOOSE YOUR LOADOUT · ") .. seconds .. "s"
	for _, entry in maps do
		entry.item.Visible = voting
		entry.item.Text = (if own.vote == entry.value then "Your vote: " else "")
			.. entry.caption
			.. "\n"
			.. tostring((state.votes or {})[entry.value] or 0)
			.. " votes"
	end
	for _, group in { { weapons, own.weapon }, { abilities, own.ability } } do
		for _, entry in group[1] do
			entry.item.Visible = selecting
			entry.item.Text = (if group[2] == entry.value then "Selected: " else "") .. entry.caption
		end
	end
	ready.Visible = selecting
	ready.Text = if own.ready then "Ready ✓ · edits undo ready" else "Ready"
	note.Text = if voting
		then "You can change your vote until the timer ends. Ties are resolved randomly."
		else "Private until countdown. Missing choices become Spring Fist / Gust.\n"
			.. tostring(state.ready or 0)
			.. "/2 ready · Ready accepts defaults."
end
table.insert(
	connections,
	remote.OnClientEvent:Connect(function(data)
		if data.session == state.session then
			own = data
			update()
		end
	end)
)
table.insert(
	connections,
	snapshot.Changed:Connect(function(value)
		local nextState = Http:JSONDecode(value)
		if nextState.session ~= state.session then
			own = {}
		end
		state = nextState
		update()
	end)
)
local elapsed = 0
table.insert(
	connections,
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.1 then
			elapsed = 0
			update()
		end
	end)
)
remote:FireServer(state.session, "sync")
update()
function Client.stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	gui:Destroy()
end
return Client
