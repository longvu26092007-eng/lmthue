-- ServerScriptService/ServerOnlinePanel.server.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("═══════════════════════════════════════════════════════════════")
print("🟢 SERVER ONLINE PANEL - STARTING...")
print("═══════════════════════════════════════════════════════════════")

if Workspace:GetAttribute("ServerStartTime") == nil then
	Workspace:SetAttribute("ServerStartTime", Workspace:GetServerTimeNow())
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if days > 0 then
		return string.format("%d ngày %02d:%02d:%02d", days, hours, mins, secs)
	else
		return string.format("%02d:%02d:%02d", hours, mins, secs)
	end
end

local function getServerUptime()
	local startTime = Workspace:GetAttribute("ServerStartTime")
	if not startTime then
		return nil
	end
	return Workspace:GetServerTimeNow() - startTime
end

local function createGuiForPlayer(player)
	local playerGui = player:WaitForChild("PlayerGui", 15)
	if not playerGui then
		warn("PlayerGui not found for " .. player.Name)
		return
	end

	local old = playerGui:FindFirstChild("ServerOnlineGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ServerOnlineGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainPanel"
	frame.Size = UDim2.new(0, 280, 0, 96)
	frame.Position = UDim2.new(0, 20, 0, 20)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.Transparency = 0.2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 26)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "SERVER STATUS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local uptimeLabel = Instance.new("TextLabel")
	uptimeLabel.Name = "Uptime"
	uptimeLabel.Size = UDim2.new(1, -20, 0, 30)
	uptimeLabel.Position = UDim2.new(0, 10, 0, 40)
	uptimeLabel.BackgroundTransparency = 1
	uptimeLabel.Text = "Server online: 00:00:00"
	uptimeLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
	uptimeLabel.TextSize = 20
	uptimeLabel.Font = Enum.Font.GothamBold
	uptimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	uptimeLabel.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Name = "SubText"
	sub.Size = UDim2.new(1, -20, 0, 18)
	sub.Position = UDim2.new(0, 10, 0, 70)
	sub.BackgroundTransparency = 1
	sub.Text = "Đang theo dõi uptime server..."
	sub.TextColor3 = Color3.fromRGB(180, 180, 180)
	sub.TextSize = 12
	sub.Font = Enum.Font.Gotham
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = frame

	task.spawn(function()
		while player.Parent and gui.Parent do
			local uptime = getServerUptime()
			if uptime then
				uptimeLabel.Text = "Server online: " .. formatTime(uptime)
			else
				uptimeLabel.Text = "Server online: loading..."
			end
			task.wait(1)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	task.defer(createGuiForPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(createGuiForPlayer, player)
end

task.spawn(function()
	while task.wait(10) do
		local uptime = getServerUptime()
		if uptime then
			print("[SERVER] Uptime: " .. formatTime(uptime))
		end
	end
end)

print("✅ SERVER ONLINE PANEL READY")
