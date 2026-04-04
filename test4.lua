-- =============================================
-- 🚀 MOON TELEPORTER — FIX LỖI NGOẶC (LINE 52)
-- Tối ưu bởi Nhai (Vũ) - FPT University
-- =============================================

local BOT_TOKEN  = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"

local HttpService    = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer

-- Xác định hàm request của Executor
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

if not request then
    warn("[MoonTP] Trình thực thi không hỗ trợ HTTP Request!")
    return
end

print("[MoonTP] 🔍 Đang kết nối Discord qua Proxy...")

local url = "https://roproxy.com/api/v10/channels/" .. CHANNEL_ID .. "/messages?limit=20"

local ok, resp = pcall(function()
    return request({
        Url = url,
        Method = "GET",
        Headers = {
            ["Authorization"] = "Bot " .. BOT_TOKEN,
            ["Content-Type"] = "application/json"
        }
    })
end)

if not ok or not resp or not resp.Body then
    warn("[MoonTP] ❌ Lỗi kết nối API!")
    return
end

local messages = HttpService:JSONDecode(resp.Body)
if not messages or #messages == 0 then
    warn("[MoonTP] ❌ Không có tin nhắn nào!")
    return
end

-- =============================================
-- [ TÌM SERVER ]
-- =============================================
local bestServer = nil

for _, msg in ipairs(messages) do
    -- Cách parse JSON an toàn hơn để tránh lỗi line 52
    local jsonStr = msg.content and msg.content:match("```json%s*(.-)%s*```")
    if jsonStr then
        local success, data = pcall(function() 
            return HttpService:JSONDecode(jsonStr) 
        end)
        
        if success and data and data.jobId then
            local age = data.time and (os.time() - tonumber(data.time)) or 0
            -- Lấy server mới nhất (dưới 10 phút)
            if age < 600 then
                bestServer = data
                bestServer.age = age
                break
            end
        end
    end

    -- Nếu không có JSON code block, tìm trong Fields của Embed
    if not bestServer and msg.embeds and msg.embeds[1] and msg.embeds[1].fields then
        local jId = nil
        for _, field in ipairs(msg.embeds[1].fields) do
            if field.name:find("JobID") then
                jId = field.value:match("[%w%-]+")
            elseif field.name:find("Teleport") then
                jId = jId or field.value:match("'([%w%-]+)'")
            end
        end
        if jId then
            bestServer = { jobId = jId, placeId = game.PlaceId, age = 0 }
            break
        end
    end
end

-- =============================================
-- [ TELEPORT ]
-- =============================================
if bestServer and bestServer.jobId then
    print("[MoonTP] ✅ Tìm thấy: " .. bestServer.jobId)
    TeleportService:TeleportToPlaceInstance(
        tonumber(bestServer.placeId) or game.PlaceId,
        bestServer.jobId,
        LocalPlayer
    )
else
    warn("[MoonTP] ❌ Không tìm thấy server Full Moon hợp lệ.")
end
