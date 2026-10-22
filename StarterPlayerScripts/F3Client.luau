local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Config = require(Storage:WaitForChild("F3Config", 10))
local World = require(Storage:WaitForChild("F1Config", 10))
local remote = Storage:WaitForChild("F3Knockouts", 10)
assert(remote and remote:IsA("RemoteEvent"), "F3 presentation requires the knockout remote")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
assert(playerGui, "F3 HUD requires PlayerGui")
local Client = {}
local snapshot = Storage:WaitForChild("F4State", 10)
local returnRemote = Storage:WaitForChild("F4Return", 10)
local adminRemote = Storage:WaitForChild("F4Admin", 10)
local weaponRemote = Storage:WaitForChild("F6WeaponChoice", 10)
assert(weaponRemote and weaponRemote:IsA("RemoteEvent"), "Weapon picker requires the server selection remote")
assert(snapshot and snapshot:IsA("StringValue"), "F4 HUD requires an authoritative match snapshot")
assert(returnRemote and returnRemote:IsA("RemoteEvent"), "F4 results require the return remote")
assert(adminRemote and adminRemote:IsA("RemoteEvent"), "F4 admin console requires its command remote")
local match = game:GetService("HttpService"):JSONDecode(snapshot.Value)
local playerListEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
local connections, entries, panels = {}, {}, {}
local spectator
local lastPosition = World.PlatformCenter
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "F3HUD", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function label(parent, name, size, position, textSize)
	local text = Instance.new("TextLabel")
	text.Name, text.Size, text.Position = name, size, position
	text.BackgroundColor3 = Color3.fromRGB(21, 25, 34)
	text.BackgroundTransparency = 0.15
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font, text.TextSize = Enum.Font.GothamMedium, textSize
	text.TextWrapped = true
	text.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = text
	text.Parent = parent
	return text
end

local score = label(gui, "Score", UDim2.fromOffset(260, 120), UDim2.new(1, -276, 0, 12), 18)
local weaponPicker = label(gui, "WeaponPicker", UDim2.fromOffset(360, 180), UDim2.fromScale(0.5, 0.5), 22)
weaponPicker.AnchorPoint = Vector2.new(0.5, 0.5)
weaponPicker.Text, weaponPicker.TextYAlignment = "Choose your weapon", Enum.TextYAlignment.Top
local pickerPadding = Instance.new("UIPadding")
pickerPadding.PaddingTop, pickerPadding.Parent = UDim.new(0, 12), weaponPicker
local weaponButtons = {}
for index, choice in { { "SpringFist", "Spring Fist" }, { "WreckingHammer", "Wrecking Hammer" } } do
	local button = Instance.new("TextButton")
	button.Name, button.Text = choice[1], choice[2]
	button.Size, button.Position = UDim2.new(1, -32, 0, 46), UDim2.fromOffset(16, 32 + (index - 1) * 56)
	button.Font, button.TextSize = Enum.Font.GothamMedium, 18
	button.TextColor3, button.BorderSizePixel = Color3.new(1, 1, 1), 0
	button.Parent = weaponPicker
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 8), button
	weaponButtons[choice[1]] = { button = button, title = choice[2] }
	table.insert(
		connections,
		button.Activated:Connect(function()
			weaponRemote:FireServer(choice[1])
		end)
	)
end
local function updateWeaponPicker()
	weaponPicker.Visible = match.phase == "staging" and player:GetAttribute("F3Status") == "waiting"
	local selected = player:GetAttribute("F2Weapon") or "SpringFist"
	for name, choice in weaponButtons do
		choice.button.Text = (if name == selected then "Selected: " else "") .. choice.title
		choice.button.BackgroundColor3 = if name == selected
			then Color3.fromRGB(45, 125, 95)
			else Color3.fromRGB(55, 65, 85)
	end
end
table.insert(connections, player:GetAttributeChangedSignal("F2Weapon"):Connect(updateWeaponPicker))
table.insert(connections, player:GetAttributeChangedSignal("F3Status"):Connect(updateWeaponPicker))
updateWeaponPicker()
score.Text, score.TextYAlignment = "Score", Enum.TextYAlignment.Top
local countdown = label(gui, "Respawn", UDim2.new(0.6, 0, 0, 70), UDim2.fromScale(0.2, 0.72), 20)
countdown.Visible = false
local timer = label(gui, "Timer", UDim2.fromOffset(240, 56), UDim2.new(0.5, -120, 0, 12), 24)
local results = label(gui, "Results", UDim2.new(0.6, 0, 0, 220), UDim2.fromScale(0.2, 0.28), 24)
results.Visible = false
results.TextYAlignment = Enum.TextYAlignment.Top
local returnButton = Instance.new("TextButton")
returnButton.Name, returnButton.Text = "Return", "Return to Lobby"
returnButton.Size, returnButton.Position = UDim2.new(0.8, 0, 0, 48), UDim2.fromScale(0.1, 0.72)
returnButton.TextSize, returnButton.Font = 20, Enum.Font.GothamMedium
returnButton.Parent = results
table.insert(
	connections,
	returnButton.Activated:Connect(function()
		returnRemote:FireServer(match.session)
	end)
)
local feed = Instance.new("Frame")
feed.Name, feed.Size, feed.Position = "Knockouts", UDim2.new(0.42, 0, 0, 132), UDim2.fromOffset(16, 76)
feed.BackgroundTransparency = 1
feed.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding, layout.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
layout.Parent = feed

local adminToggle = Instance.new("TextButton")
adminToggle.Name, adminToggle.Text = "Developer Console", "DEV CONSOLE (F4)"
adminToggle.Size, adminToggle.Position = UDim2.fromOffset(164, 42), UDim2.fromOffset(16, 12)
adminToggle.BackgroundColor3, adminToggle.BackgroundTransparency = Color3.fromRGB(21, 25, 34), 0.1
adminToggle.TextColor3, adminToggle.TextSize = Color3.new(1, 1, 1), 15
adminToggle.Font, adminToggle.BorderSizePixel = Enum.Font.GothamMedium, 0
adminToggle.Parent = gui
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius, toggleCorner.Parent = UDim.new(0, 10), adminToggle
adminToggle.Visible = player:GetAttribute("F4AdminAuthorized") == true

local console = Instance.new("Frame")
console.Name, console.Size, console.Position = "DeveloperConsole", UDim2.fromOffset(330, 500), UDim2.fromOffset(16, 62)
console.BackgroundColor3, console.BackgroundTransparency = Color3.fromRGB(21, 25, 34), 0.05
console.BorderSizePixel, console.Visible, console.Parent = 0, false, gui
local consoleCorner = Instance.new("UICorner")
consoleCorner.CornerRadius, consoleCorner.Parent = UDim.new(0, 12), console
local function consoleLabel(name, text, y, height, size)
	local item = Instance.new("TextLabel")
	item.Name, item.Text = name, text
	item.Size, item.Position = UDim2.new(1, -24, 0, height), UDim2.fromOffset(12, y)
	item.BackgroundTransparency, item.TextColor3 = 1, Color3.new(1, 1, 1)
	item.Font, item.TextSize, item.TextXAlignment = Enum.Font.GothamMedium, size, Enum.TextXAlignment.Left
	item.TextWrapped, item.Parent = true, console
	return item
end
consoleLabel("Title", "Developer Console", 10, 30, 19)
local close = Instance.new("TextButton")
close.Name, close.Text, close.Size, close.Position = "Close", "×", UDim2.fromOffset(34, 30), UDim2.new(1, -44, 0, 8)
close.BackgroundTransparency, close.TextColor3, close.TextSize = 1, Color3.new(1, 1, 1), 24
close.Parent = console
local consoleStatus = consoleLabel("Status", "Waiting for match state", 46, 52, 14)
local feedback = consoleLabel("Feedback", "Settings apply to the next match.", 462, 30, 12)
local function textBox(name, placeholder, y)
	local box = Instance.new("TextBox")
	box.Name, box.PlaceholderText, box.ClearTextOnFocus = name, placeholder, false
	box.Size, box.Position = UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, y)
	box.BackgroundColor3, box.TextColor3 = Color3.fromRGB(42, 48, 62), Color3.new(1, 1, 1)
	box.PlaceholderColor3, box.Font, box.TextSize = Color3.fromRGB(190, 196, 208), Enum.Font.Gotham, 14
	box.Parent = console
	return box
end
local openingInput = textBox("OpeningCountdown", "Opening countdown (0–10 seconds)", 106)
local regulationInput = textBox("RegulationDuration", "Regulation length (1–1800 seconds)", 148)
local function commandButton(name, text, y, callback)
	local button = Instance.new("TextButton")
	button.Name, button.Text = name, text
	button.Size, button.Position = UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, y)
	button.BackgroundColor3, button.TextColor3 = Color3.fromRGB(55, 83, 125), Color3.new(1, 1, 1)
	button.Font, button.TextSize, button.Parent = Enum.Font.GothamMedium, 14, console
	button.Activated:Connect(callback)
	return button
end
commandButton("ApplySettings", "Apply Next Match Settings", 190, function()
	adminRemote:FireServer("configure", tonumber(openingInput.Text), tonumber(regulationInput.Text))
end)
local remainingInput = textBox("RemainingSeconds", "Active time remaining (0–1800 seconds)", 236)
commandButton("SetRemaining", "Set Active Remaining Time", 278, function()
	adminRemote:FireServer("remaining", tonumber(remainingInput.Text))
end)
commandButton("StartMatch", "Start Match (2 staged players)", 324, function()
	adminRemote:FireServer("start")
end)
commandButton("EndRegulation", "End Regulation Now", 370, function()
	adminRemote:FireServer("end-now")
end)
commandButton("CancelMatch", "Cancel Match (no winner)", 416, function()
	adminRemote:FireServer("cancel")
end)
console.Size = UDim2.fromOffset(330, 500)
table.insert(
	connections,
	adminToggle.Activated:Connect(function()
		console.Visible = not console.Visible
	end)
)
table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F4 and adminToggle.Visible then
			console.Visible = not console.Visible
		end
	end)
)
table.insert(
	connections,
	close.Activated:Connect(function()
		console.Visible = false
	end)
)
table.insert(
	connections,
	player:GetAttributeChangedSignal("F4AdminAuthorized"):Connect(function()
		adminToggle.Visible = player:GetAttribute("F4AdminAuthorized") == true
		if not adminToggle.Visible then
			console.Visible = false
		end
	end)
)
local function updateConsole()
	if not adminToggle.Visible then
		return
	end
	local roster = match.roster or {}
	local first, second = roster[1], roster[2]
	local scoreText = if first and second
		then first.name .. " " .. first.score .. " — " .. second.score .. " " .. second.name
		else "Players staged: " .. #roster .. "/2"
	local remaining = if match.deadline
		then math.max(0, math.ceil(match.deadline - workspace:GetServerTimeNow()))
		else nil
	consoleStatus.Text = "Phase: "
		.. tostring(match.phase)
		.. "\n"
		.. scoreText
		.. (if remaining then "\nTime remaining: " .. remaining .. "s" else "")
	local settings = match.nextConfig
	if settings then
		local key = tostring(settings.OpeningCountdown) .. ":" .. tostring(settings.RegulationDuration)
		if key ~= openingInput:GetAttribute("SettingsKey") then
			openingInput.Text, regulationInput.Text =
				tostring(settings.OpeningCountdown), tostring(settings.RegulationDuration)
			openingInput:SetAttribute("SettingsKey", key)
		end
	end
end
updateConsole()
table.insert(
	connections,
	adminRemote.OnClientEvent:Connect(function(kind, ok, message)
		if kind == "result" and adminToggle.Visible then
			feedback.Text = message
			feedback.TextColor3 = if ok then Color3.fromRGB(145, 235, 165) else Color3.fromRGB(255, 165, 145)
		end
	end)
)

table.insert(
	connections,
	snapshot.Changed:Connect(function(value)
		local nextMatch = game:GetService("HttpService"):JSONDecode(value)
		if nextMatch.session ~= match.session then
			for _, entry in entries do
				entry.label:Destroy()
			end
			table.clear(entries)
		end
		match = nextMatch
		updateWeaponPicker()
		updateConsole()
	end)
)

function Client.matchActive()
	return (match.phase == "regulation" and workspace:GetServerTimeNow() < match.deadline)
		or match.phase == "sudden-death"
end

function Client.adminConsoleOpen()
	return console.Visible
end

local function addPanel(other)
	if panels[other] then
		return
	end
	local panel = label(score, other.Name, UDim2.fromOffset(120, 90), UDim2.fromOffset(8, 25), 14)
	panel.BackgroundTransparency = 1
	panel.TextYAlignment = Enum.TextYAlignment.Bottom
	local portrait = Instance.new("ImageLabel")
	portrait.Name, portrait.Size, portrait.Position = "Portrait", UDim2.fromOffset(42, 42), UDim2.fromOffset(39, 0)
	portrait.BackgroundTransparency = 1
	portrait.Parent = panel
	panels[other] = panel
	if other.UserId > 0 then
		task.spawn(function()
			local ok, content = pcall(
				Players.GetUserThumbnailAsync,
				Players,
				other.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
			if ok and panel.Parent then
				portrait.Image = content
			end
		end)
	end
end

table.insert(
	connections,
	remote.OnClientEvent:Connect(function(data)
		if data.session ~= match.session then
			return
		end
		local text = label(feed, "Knockout", UDim2.new(1, 0, 0, 38), UDim2.new(), 16)
		text.Text = if data.system
			then data.system
			elseif data.attacker then data.attacker .. " → " .. data.weapon .. " → " .. data.victim
			else data.victim .. " fell out"
		text.LayoutOrder = math.floor(data.at * 1000) % 1000000000
		table.insert(entries, { label = text, expires = workspace:GetServerTimeNow() + Config.FeedDuration })
		while #entries > Config.FeedLimit do
			table.remove(entries, 1).label:Destroy()
		end
	end)
)

function Client.cameraPosition(ownRoot)
	local now = workspace:GetServerTimeNow()
	local status = player:GetAttribute("F3Status")
	local at = player:GetAttribute("F3EliminatedAt")
	if status == "alive" or (status == "eliminated" and at and now - at < Config.FallCameraTime) then
		spectator = nil
		if ownRoot and ownRoot.Parent then
			lastPosition = ownRoot.Position
		end
	else
		local function survivor(other)
			local character = other and other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return other
				and other:GetAttribute("F3Status") == "alive"
				and root
				and humanoid
				and humanoid.Health > 0
				and root
		end
		local target = survivor(spectator)
		if not target then
			spectator = nil
			local list = Players:GetPlayers()
			table.sort(list, function(a, b)
				return a.UserId < b.UserId
			end)
			for _, other in list do
				if other ~= player and survivor(other) then
					spectator = other
					target = survivor(other)
					break
				end
			end
		end
		lastPosition = if target then target.Position else World.PlatformCenter + Vector3.yAxis * 4
	end
	player:SetAttribute("F3Spectating", if spectator then spectator.UserId else nil)
	return lastPosition
end

table.insert(
	connections,
	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		if console.Visible then
			updateConsole()
		end
		local phase = match.phase
		if phase == "countdown" then
			timer.Text = tostring(math.max(1, math.ceil(match.goAt - now)))
		elseif phase == "regulation" then
			local seconds = math.ceil(math.max(0, match.deadline - now))
			timer.Text = (if now - match.startedAt < 0.75 then "GO  " else "◷  ")
				.. string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
			timer.TextSize = if seconds <= 10 then 32 else 24
			timer.TextColor3 = if seconds <= 30 then Color3.fromRGB(255, 207, 100) else Color3.new(1, 1, 1)
		elseif phase == "sudden-death-countdown" then
			timer.Text = "SUDDEN DEATH  " .. tostring(math.max(1, math.ceil(match.goAt - now)))
		elseif phase == "sudden-death-pending" or phase == "sudden-death" then
			timer.Text = "SUDDEN DEATH"
				.. (if phase == "sudden-death" and now - match.startedAt < 0.75 then "  GO" else "")
		else
			timer.Text = if phase == "results" then "MATCH ENDED" else "LOCAL STAGING"
		end
		local result = match.result
		results.Visible = phase == "results" and player:GetAttribute("F3Status") ~= "waiting"
		if results.Visible and result then
			local winner = result.winner and match.roster[result.winner]
			local title = if winner then winner.name .. " wins" else "No result"
			local outcome = if result.outcome == "normal" then "Regulation" else result.outcome
			results.Text = title
				.. "\n"
				.. outcome
				.. "\n"
				.. match.roster[1].name
				.. "  "
				.. result.scores[1]
				.. " — "
				.. result.scores[2]
				.. "  "
				.. match.roster[2].name
			returnButton.Text = "Return to Lobby (" .. math.ceil(math.max(0, result.returnAt - now)) .. ")"
		end
		local roster = {}
		for _, other in Players:GetPlayers() do
			if other:GetAttribute("F3Score") ~= nil then
				table.insert(roster, other)
			end
		end
		table.sort(roster, function(a, b)
			return a.UserId < b.UserId
		end)
		for index, other in roster do
			addPanel(other)
			panels[other].Position = UDim2.fromOffset(8 + (index - 1) * 124, 25)
			local tally = 0
			for _, member in match.roster do
				if member.id == other.UserId then
					tally = member.score
				end
			end
			panels[other].Text = other.DisplayName .. "\n" .. tostring(tally)
		end
		for other, panel in panels do
			if other.Parent ~= Players then
				panel:Destroy()
				panels[other] = nil
			end
		end
		while entries[1] and now >= entries[1].expires do
			table.remove(entries, 1).label:Destroy()
		end
		local status = player:GetAttribute("F3Status")
		local deadline = player:GetAttribute("F3RespawnAt")
		local message = workspace:GetAttribute("F3SessionError")
		countdown.Visible = message ~= nil or (phase == "regulation" and status == "eliminated") or status == "waiting"
		if message then
			countdown.Text = message
		elseif status == "eliminated" and deadline then
			countdown.Text = "KNOCKED OUT\nRespawn in " .. math.ceil(math.max(0, deadline - now))
		elseif status == "waiting" then
			countdown.Text = "Local staging — two players required. Developer starts the next session."
		end
	end)
)

function Client.stop()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, playerListEnabled)
	for _, connection in connections do
		connection:Disconnect()
	end
	gui:Destroy()
	player:SetAttribute("F3Spectating", nil)
end

return Client
