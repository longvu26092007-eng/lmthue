-- ═══════════════════════════════════════════════════════════════════════
-- 🔥 SERVER UPTIME DETECTOR - ALL IN ONE
-- Script này gộp cả SERVER và CLIENT logic
-- Đặt trong: ServerScriptService
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("═══════════════════════════════════════════════════════════════")
print("🔥 SERVER UPTIME DETECTOR - ALL IN ONE - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ═════════════════════════════════════════════════════════════════════
-- PHẦN 1: SERVER - Ghi nhận thời điểm server khởi động
-- ═════════════════════════════════════════════════════════════════════
local serverStartTime = Workspace:GetServerTimeNow()
Workspace:SetAttribute("ServerStartTime", serverStartTime)

print("✅ Server start time set: " .. tostring(serverStartTime))
print("📌 Server officially started at: " .. os.date("%Y-%m-%d %H:%M:%S UTC"))

-- Log server uptime mỗi 60 giây (optional, để debug)
task.spawn(function()
    while task.wait(60) do
        local currentTime = Workspace:GetServerTimeNow()
        local uptime = currentTime - serverStartTime
        local hours = math.floor(uptime / 3600)
        local mins = math.floor((uptime % 3600) / 60)
        local secs = math.floor(uptime % 60)
        
        print(string.format("[SERVER] Uptime: %02d:%02d:%02d", hours, mins, secs))
    end
end)

-- ═════════════════════════════════════════════════════════════════════
-- PHẦN 2: CLIENT - Tạo GUI cho mỗi player khi join
-- ═════════════════════════════════════════════════════════════════════

-- Source code của LocalScript (sẽ được inject vào player)
local clientScriptSource = [[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("═══════════════════════════════════════════════════════════════")
print("🟢 SERVER ONLINE DETECTOR (CLIENT) - STARTING...")
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
label.Position = UDim2.new(0.5, -160, 0, 20) -- Top center
label.BackgroundTransparency = 0.25
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.BorderSizePixel = 0
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.RobotoBold
label.Text = "Server online: 00:00:00"
label.Parent = gui

-- Bo tròn góc
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

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
        label.TextColor3 = Color3.fromRGB(255, 255, 0) -- Màu vàng
        return
    end
    
    label.Text = "Server online: " .. formatTime(uptime)
    label.TextColor3 = Color3.fromRGB(0, 255, 128) -- Màu xanh lá
end

-- Cập nhật khi server gửi ServerStartTime
Workspace:GetAttributeChangedSignal("ServerStartTime"):Connect(function()
    updateDisplay()
    print("✅ ServerStartTime received: " .. tostring(Workspace:GetAttribute("ServerStartTime")))
end)

-- Hiển thị ngay
updateDisplay()

-- Cập nhật liên tục mỗi giây
task.spawn(function()
    while task.wait(1) do
        updateDisplay()
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- API CÔNG KHAI
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

print("✅ SERVER ONLINE DETECTOR (CLIENT) READY")
print("═══════════════════════════════════════════════════════════════")

-- LOG DEBUG mỗi 10 giây
task.spawn(function()
    task.wait(5)
    while task.wait(10) do
        local uptime = getServerUptime()
        if uptime then
            print("🟢 Server đã online: " .. formatTime(uptime))
        else
            warn("⚠️ Chưa nhận được ServerStartTime từ server!")
        end
    end
end)
]]

-- ─────────────────────────────────────────────────────────────────────
-- Tạo LocalScript cho mỗi player khi join
-- ─────────────────────────────────────────────────────────────────────
local function setupPlayerGui(player)
    print("🔌 Setting up GUI for player: " .. player.Name)
    
    -- Đợi PlayerGui load
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then
        warn("❌ PlayerGui not found for " .. player.Name)
        return
    end
    
    -- Tạo LocalScript
    local localScript = Instance.new("LocalScript")
    localScript.Name = "ServerUptimeClient"
    localScript.Source = clientScriptSource
    localScript.Parent = playerGui
    
    print("✅ GUI created for player: " .. player.Name)
end

-- Setup cho players hiện có
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        setupPlayerGui(player)
    end)
end

-- Setup cho players join sau
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        setupPlayerGui(player)
    end)
end)

print("═══════════════════════════════════════════════════════════════")
print("✅ SERVER UPTIME DETECTOR - ALL IN ONE - READY")
print("═══════════════════════════════════════════════════════════════")
