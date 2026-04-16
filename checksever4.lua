-- ═══════════════════════════════════════════════════════════════════════
-- SERVER ONLINE DETECTOR
-- Hiển thị: Server online: xx:xx:xx
-- Dùng workspace:GetServerTimeNow() + ServerStartTime của server
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("═══════════════════════════════════════════════════════════════")
print("🟢 SERVER ONLINE DETECTOR - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ─────────────────────────────────────────────────────────────────────
-- FORMAT TIME
-- ─────────────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────────────
-- GUI
-- ─────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "ServerOnlineGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "ServerOnlineLabel"
label.Size = UDim2.new(0, 320, 0, 40)
label.Position = UDim2.new(0.5, -160, 0, 20)
label.BackgroundTransparency = 0.25
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BorderSizePixel = 0
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.RobotoBold
label.Text = "Server online: 00:00:00"
label.Parent = gui

-- ─────────────────────────────────────────────────────────────────────
-- TÍNH SERVER UPTIME
-- ─────────────────────────────────────────────────────────────────────
local function getServerUptime()
	local startTime = Workspace:GetAttribute("ServerStartTime")
	if not startTime then
		return nil
	end

	return Workspace:GetServerTimeNow() - startTime
end

local function updateDisplay()
	local uptime = getServerUptime()

	if uptime == nil then
		label.Text = "Server online: loading..."
		return
	end

	label.Text = "Server online: " .. formatTime(uptime)
end

print("📌 Waiting for ServerStartTime...")

-- Cập nhật ngay khi có giá trị
Workspace:GetAttributeChangedSignal("ServerStartTime"):Connect(function()
	updateDisplay()
	print("✅ ServerStartTime received")
end)

-- Hiển thị ngay
updateDisplay()

-- Cập nhật liên tục
task.spawn(function()
	while task.wait(1) do
		updateDisplay()
	end
end)

-- ─────────────────────────────────────────────────────────────────────
-- API nhỏ để script khác dùng
-- ─────────────────────────────────────────────────────────────────────
local ServerUptimeAPI = {}

function ServerUptimeAPI.getTotalUptime()
	local uptime = getServerUptime()
	return uptime or 0
end

function ServerUptimeAPI.getFormattedUptime()
	return formatTime(ServerUptimeAPI.getTotalUptime())
end

function ServerUptimeAPI.formatTime(seconds)
	return formatTime(seconds)
end

_G.ServerUptimeAPI = ServerUptimeAPI

print("✅ SERVER ONLINE DETECTOR READY")
