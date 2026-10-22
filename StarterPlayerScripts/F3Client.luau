local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Config = require(Storage:WaitForChild("F3Config", 10))
local World = require(Storage:WaitForChild("F1Config", 10))
local remote = Storage:WaitForChild("F3Knockouts", 10)
assert(remote and remote:IsA("RemoteEvent"), "F3 presentation requires the knockout remote")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
assert(playerGui, "F3 HUD requires PlayerGui")
local Client = {}
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
score.Text, score.TextYAlignment = "Score", Enum.TextYAlignment.Top
local countdown = label(gui, "Respawn", UDim2.new(0.6, 0, 0, 70), UDim2.fromScale(0.2, 0.72), 20)
countdown.Visible = false
local feed = Instance.new("Frame")
feed.Name, feed.Size, feed.Position = "Knockouts", UDim2.new(0.42, 0, 0, 132), UDim2.fromOffset(16, 12)
feed.BackgroundTransparency = 1
feed.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding, layout.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
layout.Parent = feed

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
		local text = label(feed, "Knockout", UDim2.new(1, 0, 0, 38), UDim2.new(), 16)
		text.Text = if data.attacker
			then data.attacker .. " → " .. data.weapon .. " → " .. data.victim
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
			panels[other].Text = other.DisplayName .. "\n" .. tostring(other:GetAttribute("F3Score") or 0)
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
		countdown.Visible = message ~= nil or status == "eliminated" or status == "waiting"
		if message then
			countdown.Text = message
		elseif status == "eliminated" and deadline then
			countdown.Text = "KNOCKED OUT\nRespawn in " .. math.ceil(math.max(0, deadline - now))
		elseif status == "waiting" then
			countdown.Text = "Waiting — this local prototype supports two players."
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
