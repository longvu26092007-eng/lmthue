-- ═══════════════════════════════════════════════════════════════════════
-- 🔍 SERVER UPTIME DETECTOR - FIXED VERSION
-- Sử dụng workspace:GetServerTimeNow() để tính ĐÚNG server uptime
-- Dựa theo phân tích source code Blox Fruits
-- ═══════════════════════════════════════════════════════════════════════

print("═══════════════════════════════════════════════════════════════")
print("🟢 SERVER UPTIME DETECTOR - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ─────────────────────────────────────────────────────────────────────
-- LƯU THỜI ĐIỂM PLAYER VÀO SERVER
-- ─────────────────────────────────────────────────────────────────────
-- workspace:GetServerTimeNow() trả về ABSOLUTE TIMESTAMP
-- Giá trị này > 1000000 và tính từ lúc server khởi động
local playerJoinServerTime = workspace:GetServerTimeNow()

print("📌 Player joined at server time: " .. string.format("%.3f", playerJoinServerTime) .. " seconds")
print("")

-- ─────────────────────────────────────────────────────────────────────
-- HÀM TÍNH TOÁN VÀ HIỂN THỊ
-- ─────────────────────────────────────────────────────────────────────

local function formatTime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if days > 0 then
        return string.format("%d ngày %d giờ %d phút %d giây", days, hours, mins, secs)
    elseif hours > 0 then
        return string.format("%d giờ %d phút %d giây", hours, mins, secs)
    elseif mins > 0 then
        return string.format("%d phút %d giây", mins, secs)
    else
        return string.format("%d giây", secs)
    end
end

local function displayServerInfo()
    -- Lấy thời gian server hiện tại
    local currentServerTime = workspace:GetServerTimeNow()
    
    -- Server đã chạy TRƯỚC KHI player join
    local serverUptimeBeforeJoin = playerJoinServerTime
    
    -- Server uptime HIỆN TẠI (tổng cộng từ lúc khởi động)
    local totalServerUptime = currentServerTime
    
    -- Thời gian player đã ở trong server
    local playerTimeInServer = currentServerTime - playerJoinServerTime
    
    -- Hiển thị
    print("═══════════════════════════════════════════════════════════════")
    print("⏱️  THÔNG TIN SERVER UPTIME")
    print("───────────────────────────────────────────────────────────────")
    print("🔵 Server đã chạy TRƯỚC KHI bạn vào:")
    print("   → " .. formatTime(serverUptimeBeforeJoin))
    print("   → " .. string.format("%.3f", serverUptimeBeforeJoin) .. " giây")
    print("")
    print("🟢 Server đã chạy TỔNG CỘNG (hiện tại):")
    print("   → " .. formatTime(totalServerUptime))
    print("   → " .. string.format("%.3f", totalServerUptime) .. " giây")
    print("")
    print("🟡 Bạn đã ở trong server được:")
    print("   → " .. formatTime(playerTimeInServer))
    print("   → " .. string.format("%.3f", playerTimeInServer) .. " giây")
    print("═══════════════════════════════════════════════════════════════")
    print("")
end

-- ─────────────────────────────────────────────────────────────────────
-- HIỂN THỊ NGAY KHI VÀO
-- ─────────────────────────────────────────────────────────────────────
task.wait(1) -- Chờ 1 giây để đảm bảo mọi thứ đã load
displayServerInfo()

-- ─────────────────────────────────────────────────────────────────────
-- CẬP NHẬT MỖI 10 GIÂY
-- ─────────────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(10) do
        displayServerInfo()
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- API CÔNG KHAI - Sử dụng trong script khác
-- ─────────────────────────────────────────────────────────────────────
local ServerUptimeAPI = {}

-- Lấy server uptime hiện tại (tổng cộng từ lúc khởi động)
function ServerUptimeAPI.getTotalUptime()
    return workspace:GetServerTimeNow()
end

-- Lấy server uptime TRƯỚC KHI player join
function ServerUptimeAPI.getUptimeBeforeJoin()
    return playerJoinServerTime
end

-- Lấy thời gian player đã ở trong server
function ServerUptimeAPI.getPlayerTimeInServer()
    return workspace:GetServerTimeNow() - playerJoinServerTime
end

-- Lấy thời gian server khởi động (ước tính UTC timestamp)
-- Lưu ý: Cần biết current UTC time để tính chính xác
function ServerUptimeAPI.estimateServerStartTime()
    local currentUTC = os.time() -- UTC time hiện tại
    local serverUptime = workspace:GetServerTimeNow()
    return currentUTC - serverUptime
end

-- Format thời gian đẹp
function ServerUptimeAPI.formatTime(seconds)
    return formatTime(seconds)
end

return ServerUptimeAPI
