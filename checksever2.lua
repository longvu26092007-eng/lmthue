-- ============================================================
--  SERVER UPTIME DETECTOR
--  Dựa trên workspace.DistributedGameTime
--  Đây là thời gian SERVER đã chạy từ lúc mở, KHÔNG phải
--  thời gian bạn vào server.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ─────────────────────────────────────────────────────────────
-- HÀM CHUYỂN GIÂY → CHUỖI DỄ ĐỌC
-- ─────────────────────────────────────────────────────────────
local function formatTime(seconds)
    local s = math.floor(seconds)
    local ms = math.floor((seconds - s) * 1000)

    local days    = math.floor(s / 86400)
    local hours   = math.floor((s % 86400) / 3600)
    local minutes = math.floor((s % 3600) / 60)
    local secs    = s % 60

    local parts = {}
    if days > 0    then table.insert(parts, days    .. " ngày") end
    if hours > 0   then table.insert(parts, hours   .. " giờ") end
    if minutes > 0 then table.insert(parts, minutes .. " phút") end
    table.insert(parts, secs .. "." .. string.format("%03d", ms) .. " giây")

    return table.concat(parts, " ")
end

-- ─────────────────────────────────────────────────────────────
-- LẤY THỜI GIAN SERVER ĐÃ CHẠY
-- workspace.DistributedGameTime bắt đầu tính từ khi SERVER
-- được khởi động, KHÔNG phải khi player vào.
-- ─────────────────────────────────────────────────────────────
local function getServerUptime()
    return workspace.DistributedGameTime
end

-- ─────────────────────────────────────────────────────────────
-- TÍNH THỜI ĐIỂM SERVER MỞ (UTC timestamp xấp xỉ)
-- os.time() = thời gian thực hiện tại (UTC)
-- DistributedGameTime = server đã chạy bao lâu rồi
-- → server mở lúc = os.time() - DistributedGameTime
-- ─────────────────────────────────────────────────────────────
local function getServerOpenTime()
    local nowUnix     = os.time()           -- giây UTC hiện tại
    local uptime      = getServerUptime()   -- server đã chạy bao lâu
    local openUnix    = nowUnix - uptime    -- lúc server mở (UTC unix)

    -- Chuyển unix timestamp → bảng ngày/giờ UTC
    local t = os.date("!*t", math.floor(openUnix))
    return string.format(
        "%02d/%02d/%04d %02d:%02d:%02d UTC",
        t.day, t.month, t.year,
        t.hour, t.min, t.sec
    ), openUnix
end

-- ─────────────────────────────────────────────────────────────
-- THỜI ĐIỂM PLAYER VÀO SERVER (để so sánh)
-- ─────────────────────────────────────────────────────────────
local playerJoinTime = tick()  -- tick() = giây kể từ epoch (local)
local serverUptimeAtJoin = getServerUptime()

-- ─────────────────────────────────────────────────────────────
-- IN THÔNG TIN LẦN ĐẦU
-- ─────────────────────────────────────────────────────────────
local openTimeStr, openUnix = getServerOpenTime()

print("╔══════════════════════════════════════════╗")
print("║        SERVER UPTIME DETECTOR            ║")
print("╠══════════════════════════════════════════╣")
print("║ Server mở lúc (UTC) : " .. openTimeStr)
print("║ Server đã online    : " .. formatTime(serverUptimeAtJoin))
print("║ (trước khi bạn vào) : " .. formatTime(serverUptimeAtJoin))
print("╚══════════════════════════════════════════╝")

-- ─────────────────────────────────────────────────────────────
-- HIỂN THỊ LIÊN TỤC MỖI 10 GIÂY
-- ─────────────────────────────────────────────────────────────
local UPDATE_INTERVAL = 10 -- giây

task.spawn(function()
    while true do
        task.wait(UPDATE_INTERVAL)

        local currentUptime    = getServerUptime()
        local timeSinceJoin    = tick() - playerJoinTime
        local openStr, _       = getServerOpenTime()

        print("─────────────────────────────────────────")
        print("[SERVER UPTIME]")
        print("  Server đã chạy tổng cộng : " .. formatTime(currentUptime))
        print("  Server mở lúc (UTC)      : " .. openStr)
        print("  Bạn đã vào server được   : " .. formatTime(timeSinceJoin))
        print("  Server chạy trước khi    ")
        print("  bạn vào (giây)           : " .. string.format("%.3f", serverUptimeAtJoin))
        print("─────────────────────────────────────────")
    end
end)

-- ─────────────────────────────────────────────────────────────
-- API CÔNG KHAI – dùng trong script khác nếu cần
-- ─────────────────────────────────────────────────────────────
-- Ví dụ:
--   local uptime = ServerUptime.getUptime()
--   local openAt = ServerUptime.getOpenTimeString()

local ServerUptime = {}

function ServerUptime.getUptime()
    return getServerUptime()
end

function ServerUptime.getOpenTimeString()
    return (getServerOpenTime())
end

function ServerUptime.getUptimeBeforeJoin()
    return serverUptimeAtJoin
end

function ServerUptime.getTimeSinceJoin()
    return tick() - playerJoinTime
end

return ServerUptime
