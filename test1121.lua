-- =============================================
-- 🚀 MOON TELEPORTER — Đọc Firebase → Teleport
-- Giữ nguyên cấu trúc cũ, chỉ thay nguồn đọc dữ liệu
-- =============================================

-- ★ CONFIG — Link Firebase của Vũ ★
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"

local HttpService    = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer    = game.Players.LocalPlayer
local req = http_request or request or syn.request or fluxus_request

-- =============================================
-- [ ĐỌC DỮ LIỆU TỪ FIREBASE ]
-- =============================================
print("[MoonTP] 🔍 Đọc Firebase database...")

local ok, resp = pcall(function()
    return req({
        Url = FIREBASE_URL,
        Method = "GET"
    })
end)

if not ok or not resp or not resp.Body or resp.Body == "null" then
    warn("[MoonTP] ❌ Không kết nối được Firebase hoặc Database trống!")
    return
end

-- =============================================
-- [ KIỂM TRA SERVER FULL MOON MỚI NHẤT ]
-- =============================================
print("[MoonTP] 📋 Đã lấy dữ liệu. Đang scan...")

local bestServer = nil
local parseOk, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)

if parseOk and data and data.jobId then
    local age = data.time and (os.time() - tonumber(data.time)) or 9999
    local moon = data.moon or data.Trạng_thái or "?"

    print(string.format("  → %s | Moon: %s | Sea: %s | %dm ago | %s",
        "Firebase",
        moon,
        data.sea or "?",
        math.floor(age / 60),
        data.jobId:sub(1, 16) .. "..."
    ))

    -- Ưu tiên: chưa quá 10 phút và không phải server hiện tại đang đứng
    if age < 600 and data.jobId ~= game.JobId then
        bestServer = data
        bestServer.age = age
        bestServer.player = "Firebase"
    elseif data.jobId == game.JobId then
        warn("[MoonTP] ❌ Server này bạn đang ở rồi!")
    end
end

-- =============================================
-- [ TELEPORT ]
-- =============================================
if not bestServer then
    warn("[MoonTP] ❌ Không tìm thấy server Full Moon nào!")
    warn("[MoonTP] Kiểm tra: Account scanner đã chạy MoonScanner_Sender chưa?")
    return
end

print("")
print("[MoonTP] ✅ ĐÃ TÌM THẤY SERVER!")
print("  Player:  " .. (bestServer.player or "?"))
print("  Moon:    " .. (bestServer.moon or "?"))
print("  Sea:     " .. (bestServer.sea or "?"))
print("  JobId:   " .. bestServer.jobId)
print("  Age:     " .. math.floor((bestServer.age or 0) / 60) .. "m " .. ((bestServer.age or 0) % 60) .. "s ago")
print("")

if bestServer.age and bestServer.age > 300 then
    warn("[MoonTP] ⚠ Data cũ hơn 5 phút — server có thể đã đổi moon!")
end

print("[MoonTP] 🚀 Đang teleport...")

TeleportService:TeleportToPlaceInstance(
    tonumber(bestServer.placeId)
