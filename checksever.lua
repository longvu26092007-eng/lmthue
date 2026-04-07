-- =============================================
-- BLOX FRUITS SERVER INFO - PHIÊN BẢN TỐI ƯU (2026)
-- Dùng GetServerTimeNow() + DistributedGameTime
-- =============================================

local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local function formatUptime(seconds)
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

-- Lấy uptime chính thức của server
local uptimeSeconds = Workspace.DistributedGameTime

-- Lấy thời gian server hiện tại (đã sync từ server)
local serverNow = Workspace:GetServerTimeNow()

-- Tính thời gian server được tạo (Unix timestamp)
local serverCreatedUnix = serverNow - uptimeSeconds

-- Format thời gian tạo
local createdTime = os.date("%H:%M:%S %d/%m/%Y", math.floor(serverCreatedUnix))

print("=== 🌊 BLOX FRUITS SERVER INFO (TỐI ƯU) ===")
print("⏳ Server đã tồn tại: " .. formatUptime(uptimeSeconds))
print("📅 Server được tạo lúc: " .. createdTime)
print("⏱ Uptime (giây): " .. math.floor(uptimeSeconds))
print("🕒 Server time now: " .. string.format("%.2f", serverNow))
print("🔢 JobId: " .. tostring(game.JobId))
print("=====================================")

StarterGui:SetCore("SendNotification", {
    Title = "💎 SERVER INFO - Blox Fruits",
    Text = "⏳ Tồn tại: " .. formatUptime(uptimeSeconds) .. "\n📅 Tạo lúc: " .. createdTime,
    Duration = 15
})
