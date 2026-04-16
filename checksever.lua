-- ═══════════════════════════════════════════════════════════════════════
-- 📺 CLIENT SCRIPT - Hiển thị Server Uptime
-- Script này chạy trên CLIENT (LocalScript) để hiển thị GUI
-- Đặt trong: StarterPlayer > StarterPlayerScripts
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
    
    -- Server uptime = Thời gian hiện tại - Thời gian server khởi động
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

print("📌 Waiting for ServerStartTime...")

-- Cập nhật ngay khi server gửi ServerStartTime
Workspace:GetAttributeChangedSignal("ServerStartTime"):Connect(function()
    updateDisplay()
    print("✅ ServerStartTime received: " .. tostring(Workspace:GetAttribute("ServerStartTime")))
end)

-- Hiển thị ngay (nếu ServerStartTime đã có sẵn)
updateDisplay()

-- Cập nhật liên tục mỗi giây
task.spawn(function()
    while task.wait(1) do
        updateDisplay()
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- API CÔNG KHAI - Để script khác có thể dùng
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

-- Export ra global để script khác dùng
_G.ServerUptimeAPI = ServerUptimeAPI

print("✅ SERVER ONLINE DETECTOR READY")
print("═══════════════════════════════════════════════════════════════")

-- ─────────────────────────────────────────────────────────────────────
-- LOG DEBUG MỖI 10 GIÂY
-- ─────────────────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(5) -- Chờ 5 giây đầu
    while task.wait(10) do
        local uptime = getServerUptime()
        if uptime then
            print("🟢 Server đã online: " .. formatTime(uptime))
        else
            warn("⚠️ Chưa nhận được ServerStartTime từ server!")
        end
    end
end)
