-- =============================================
-- 🚀 MOON TELEPORTER — Đọc Discord → Teleport (ĐÃ SỬA LỖI)
-- Tự đọc channel, tìm server Full Moon, teleport vào
-- =============================================

local BOT_TOKEN = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game.Players.LocalPlayer
local req = http_request or request or syn.request or fluxus_request

if not req then
    warn("[MoonTP] ❌ Executor của bạn không hỗ trợ HTTP Request!")
    return
end

-- =============================================
-- [ ĐỌC MESSAGES TỪ DISCORD ]
-- =============================================
print("[MoonTP] 🔍 Đọc Discord channel...")

local ok, resp = pcall(function()
    return req({
        Url = "https://discord.com/api/v10/channels/" .. CHANNEL_ID .. "/messages?limit=20",
        Method = "GET",
        Headers = {["Authorization"] = "Bot " .. BOT_TOKEN}
    })
end)

if not ok or not resp then
    warn("[MoonTP] ❌ Không kết nối được Discord!")
    return
end

local s, messages = pcall(function() return HttpService:JSONDecode(resp.Body) end)

if not s or not messages or #messages == 0 then
    warn("[MoonTP] ❌ Channel trống hoặc lỗi dữ liệu!")
    return
end

-- =============================================
-- [ TÌM SERVER FULL MOON MỚI NHẤT ]
-- =============================================
print("[MoonTP] 📋 Tìm thấy " .. #messages .. " messages. Đang scan...")

local bestServer = nil

for _, msg in ipairs(messages) do
    -- ⚠️ TRÁNH LỖI: kiểm tra msg.content có tồn tại không
    if msg.content and type(msg.content) == "string" then
        -- Parse JSON trong code block
        local jsonStr = msg.content:match("```json%s*(.-)%s*```")
        if jsonStr then
            local parseOk, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
            if parseOk and data and data.jobId then
                local age = data.time and (os.time() - tonumber(data.time)) or 9999
                local moon = data.moon or data.Trạng_thái or "?"

                print(string.format("  → %s | Moon: %s | Sea: %s | %dm ago | %s",
                    data.player or "?",
                    moon,
                    data.sea or "?",
                    math.floor(age / 60),
                    data.jobId:sub(1, 16) .. "..."
                ))

                -- Ưu tiên: Full Moon + mới nhất + chưa quá 10 phút
                if not bestServer and age < 600 then
                    bestServer = data
                    bestServer.age = age
                end
            end
        end
    end

    -- Cũng check embed nếu có (cho script cũ dùng embed)
    if msg.embeds and #msg.embeds > 0 then
        for _, embed in ipairs(msg.embeds) do
            if embed.fields then
                local jobId, placeId, moon
                for _, field in ipairs(embed.fields) do
                    if field.name and field.name:find("JobID") then
                        jobId = field.value and field.value:match("[%w%-]+") or nil
                    end
                    if field.name and field.name:find("Teleport") then
                        placeId = field.value and field.value:match("TeleportToPlaceInstance%((%d+)") or nil
                        jobId = jobId or (field.value and field.value:match("'([%w%-]+)'") or nil)
                    end
                    if field.name and (field.name:find("Tr%a+ng th%a+i") or field.name:find("Moon")) then
                        moon = field.value and field.value:gsub("`", "") or "?"
                    end
                end
                if jobId and not bestServer then
                    bestServer = {
                        jobId = jobId,
                        placeId = placeId or tostring(game.PlaceId),
                        moon = moon or "?",
                        player = msg.author and msg.author.username or "?",
                        age = 0,
                    }
                end
            end
        end
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
    warn("[MoonTP] ⚠️ Data cũ hơn 5 phút — server có thể đã đổi moon!")
end

print("[MoonTP] 🚀 Đang teleport...")
local targetPlaceId = tonumber(bestServer.placeId) or game.PlaceId
TeleportService:TeleportToPlaceInstance(targetPlaceId, bestServer.jobId, LocalPlayer)
