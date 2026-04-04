-- =============================================
-- 🚀 MOON TELEPORTER — Đọc Discord → Teleport
-- Tối ưu bởi Nhai (Vũ) - Fix lỗi Line 1 Nil & Proxy
-- =============================================

local BOT_TOKEN  = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"

local HttpService    = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer     = game.Players.LocalPlayer
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

if not req then
    warn("[MoonTP] Executor không hỗ trợ Request!")
    return
end

-- =============================================
-- [ ĐỌC MESSAGES TỪ DISCORD ]
-- =============================================
print("[MoonTP] 🔍 Đang quét Discord channel qua Proxy...")

-- Sử dụng RoProxy để tránh bị Roblox chặn domain discord.com
local DISCORD_URL = "https://roproxy.com/api/v10/channels/" .. CHANNEL_ID .. "/messages?limit=20"

local ok, resp = pcall(function()
    return req({
        Url = DISCORD_URL,
        Method = "GET",
        Headers = {
            ["Authorization"] = "Bot " .. BOT_TOKEN,
            ["Content-Type"] = "application/json"
        }
    })
end)

if not ok or not resp or not resp.Body then
    warn("[MoonTP] ❌ Không thể kết nối tới Discord API!")
    return
end

local messages = HttpService:JSONDecode(resp.Body)

if not messages or #messages == 0 then
    warn("[MoonTP] ❌ Channel trống hoặc Proxy bị lỗi!")
    return
end

-- =============================================
-- [ TÌM SERVER FULL MOON MỚI NHẤT ]
-- =============================================
print("[MoonTP] 📋 Tìm thấy " .. #messages .. " tin nhắn. Đang lọc server...")

local bestServer = nil

for _, msg in ipairs(messages) do
    -- 1. Parse JSON trong code block
    local jsonStr = msg.content and msg.content:match("```json%s*(.-)%s*```")
    if jsonStr then
        local parseOk, data = pcall(HttpService.JSONDecode, HttpService, jsonStr)
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

            -- Ưu tiên: mới nhất + chưa quá 10 phút
            if not bestServer and age < 600 then
                bestServer = data
                bestServer.age = age
            end
        end
    end

    -- 2. Check Embed (Giữ nguyên func cũ của bạn)
    if not bestServer and msg.embeds and #msg.embeds > 0 then
        for _, embed in ipairs(msg.embeds) do
            if embed.fields then
                local jobId, placeId, moon
                for _, field in ipairs(embed.fields) do
                    if field.name and field.name:find("JobID") then
                        jobId = field.value:match("[%w%-]+")
                    end
                    if field.name and field.name:find("Teleport") then
                        placeId = field.value:match("TeleportToPlaceInstance%((%d+)")
                        jobId = jobId or field.value:match("'([%w%-]+)'")
                    end
                    if (field.name and field.name:find("Moon")) or (field.name and field.name:find("Trạng thái")) then
                        moon = field.value:gsub("`", "")
                    end
                end
                if jobId then
                    bestServer = {
                        jobId = jobId,
                        placeId = placeId or tostring(game.PlaceId),
                        moon = moon or "?",
                        player = msg.author and msg.author.username or "Bot",
                        age = 0,
                    }
                end
            end
        end
    end
end

-- =============================================
-- [ THỰC HIỆN TELEPORT ]
-- =============================================
if not bestServer then
    warn("[MoonTP] ❌ Không tìm thấy server Full Moon nào khả dụng!")
    return
end

print("")
print("[MoonTP] ✅ ĐÃ TÌM THẤY SERVER!")
print("  Player:   " .. (bestServer.player or "?"))
print("  Moon:     " .. (bestServer.moon or "?"))
print("  JobId:    " .. bestServer.jobId)
print("  Time:     " .. math.floor((bestServer.age or 0) / 60) .. "m ago")
print("")

if bestServer.age and bestServer.age > 300 then
    warn("[MoonTP] ⚠️ Server này đã báo từ 5 phút trước, trăng có thể đã lặn!")
end

print("[MoonTP] 🚀 Đang nhảy server...")

TeleportService:TeleportToPlaceInstance(
    tonumber(bestServer.placeId) or game.PlaceId,
    bestServer.jobId,
    LocalPlayer
)
