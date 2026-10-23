local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Http = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Config = require(Storage:WaitForChild("L3Config", 10))
local remote = Storage:WaitForChild("L3Play", 10)
local snapshot = Storage:WaitForChild("L3QueueState", 10)
assert(remote and remote:IsA("RemoteEvent"), "L3 menu requires the Play remote")
assert(snapshot and snapshot:IsA("StringValue"), "L3 queue requires the server roster snapshot")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
assert(playerGui, "L3 presentation requires PlayerGui")
local world = workspace:WaitForChild("L3Lobby", 10)
local boardPart = world and world:WaitForChild("QueueBoard", 10)
assert(boardPart and boardPart:IsA("BasePart"), "L3 queue requires its physical board")
local Client = {}
local connections = {}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "L3HUD", false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = playerGui
local function text(parent, name, size, position, message, fontSize)
	local item = Instance.new("TextLabel")
	item.Name, item.Size, item.Position, item.Text = name, size, position, message
	item.BackgroundTransparency, item.BorderSizePixel = 1, 0
	item.TextColor3, item.Font, item.TextSize = Color3.new(1, 1, 1), Enum.Font.GothamMedium, fontSize
	item.TextWrapped, item.Parent = true, parent
	return item
end
local menu = Instance.new("Frame")
menu.Name, menu.Size = "Menu", UDim2.fromScale(1, 1)
menu.BackgroundColor3, menu.BackgroundTransparency = Color3.fromRGB(11, 16, 26), 0.4
menu.BorderSizePixel, menu.Parent = 0, gui
text(menu, "Title", UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.22), "KNOCKOUT NIGHT", 48)
local play = Instance.new("TextButton")
play.Name, play.Text, play.Size, play.Position = "Play", "Play", UDim2.fromOffset(240, 64), UDim2.fromScale(0.5, 0.55)
play.AnchorPoint = Vector2.new(0.5, 0.5)
play.Font, play.TextSize, play.TextColor3 = Enum.Font.GothamBold, 28, Color3.new(1, 1, 1)
play.BackgroundColor3, play.BorderSizePixel, play.Parent = Color3.fromRGB(31, 119, 139), 0, menu
local corner = Instance.new("UICorner")
corner.CornerRadius, corner.Parent = UDim.new(0, 12), play
local hint = text(menu, "Hint", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.66), "", 18)
local status = text(gui, "QueuePosition", UDim2.new(0.8, 0, 0, 64), UDim2.new(0.1, 0, 1, -80), "", 18)
status.BackgroundColor3, status.BackgroundTransparency = Color3.fromRGB(11, 16, 26), 0.15
local blur = Instance.new("BlurEffect")
blur.Name, blur.Size, blur.Parent = "L3MenuBlur", 18, Lighting

local board = Instance.new("SurfaceGui")
board.Name, board.Adornee, board.Face = "L3QueueBoard", boardPart, Enum.NormalId.Back
board.SizingMode, board.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(680, 520)
board.Active, board.ResetOnSpawn, board.Parent = true, false, playerGui
text(board, "Title", UDim2.new(1, 0, 0, 54), UDim2.new(), "1v1 QUEUE", 34)
local nextPair = text(board, "NextPair", UDim2.new(1, -24, 0, 106), UDim2.fromOffset(12, 54), "", 24)
nextPair.TextColor3 = Color3.fromRGB(119, 233, 245)
text(
	board,
	"Instructions",
	UDim2.new(1, -24, 0, 66),
	UDim2.fromOffset(12, 160),
	"Step onto the blue pad to join.\nStep off to leave. Scroll below for waiting order.",
	20
)
local list = Instance.new("ScrollingFrame")
list.Name, list.Size, list.Position = "WaitingOrder", UDim2.new(1, -24, 1, -242), UDim2.fromOffset(12, 230)
list.BackgroundTransparency, list.BorderSizePixel = 1, 0
list.ScrollBarThickness, list.CanvasSize, list.AutomaticCanvasSize = 10, UDim2.new(), Enum.AutomaticSize.Y
list.ScrollingDirection, list.Parent = Enum.ScrollingDirection.Y, board
local layout = Instance.new("UIListLayout")
layout.SortOrder, layout.Parent = Enum.SortOrder.LayoutOrder, list

local function updateQueue()
	local roster = Http:JSONDecode(snapshot.Value)
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local ownPosition
	for index, member in roster do
		local row =
			text(list, "Position" .. index, UDim2.new(1, -18, 0, 42), UDim2.new(), index .. ". @" .. member.name, 24)
		row.LayoutOrder, row.TextXAlignment = index, Enum.TextXAlignment.Left
		if index <= 2 then
			row.TextColor3 = Color3.fromRGB(119, 233, 245)
		end
		if member.id == player.UserId then
			ownPosition = index
		end
	end
	nextPair.Text = if #roster >= 2
		then "Next pair ready\n@" .. roster[1].name .. "  vs  @" .. roster[2].name
		elseif #roster == 1 then "Waiting for an opponent\nNext: @" .. roster[1].name
		else "Waiting for players\nNext pair: —"
	local state = player:GetAttribute("L3State")
	status.Visible = state == "lobby" or state == "respawning"
	status.Text = if state == "respawning"
		then "Returning to lobby…"
		elseif ownPosition then "1v1 queue · Position " .. ownPosition .. " of " .. #roster .. " · Step off to leave"
		else "Walk onto the blue pad to queue for 1v1 · Hold right mouse to look"
end

local function updateState()
	local state = player:GetAttribute("L3State")
	menu.Visible = state == nil or state == "menu" or state == "loading" or state == "spawn-error"
	blur.Enabled = menu.Visible
	play.Active = state == "menu" or state == "spawn-error"
	play.Text = if state == "spawn-error" then "Retry Play" elseif play.Active then "Play" else "Loading…"
	hint.Text = if state == "spawn-error" then "Could not spawn. Please try again." else ""
	if not menu.Visible and GuiService.SelectedObject == play then
		GuiService.SelectedObject = nil
	end
	updateQueue()
end
table.insert(
	connections,
	play.Activated:Connect(function()
		if play.Active then
			remote:FireServer()
		end
	end)
)
table.insert(connections, snapshot.Changed:Connect(updateQueue))
table.insert(connections, player:GetAttributeChangedSignal("L3State"):Connect(updateState))
updateState()

function Client.menuCamera()
	if menu.Visible then
		return CFrame.lookAt(Config.Origin + Config.CameraOffset, Config.Origin + Config.CameraFocus)
	end
	return nil
end

function Client.stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	if GuiService.SelectedObject == play then
		GuiService.SelectedObject = nil
	end
	gui:Destroy()
	board:Destroy()
	blur:Destroy()
end

return Client
