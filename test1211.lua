-- =============================================
-- 🚀 MOON TELEPORTER — Phiên bản chống lỗi tuyệt đối
-- =============================================

local BOT_TOKEN = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game.Players.LocalPlayer

-- Tìm request function an toàn
local req
local requestFunctions = {http_request, request, syn.request, fluxus_request}
for _, func in ipairs(requestFunctions) do
    if type(func) == "function" then
        req = func
        break
    end
end

if not req then
    warn("[MoonTP] ❌ Không tìm thấy HTTP request function!")
    return
end

-- =============================================
-- [HÀM ĐỌC DISCORD AN TOÀN]
-- =============================================
print("[MoonTP] 🔍 Đang kết nối Discord...")

local resp = nil
local requestSuccess, requestError = pcall(function()
    resp = req({
        Url = "https://discord.com/api/v10/channels/" .. CHANNEL_ID .. "/messages?limit=20",
        Method = "GET",
        Headers = {["Authorization"] = "Bot " .. BOT_TOKEN}
    })
end)

if not requestSuccess or not resp then
    warn("[MoonTP] ❌ Lỗi kết nối: " .. tostring(requestError))
    return
end

-- Kiểm tra resp.Body có tồn tại không
if not resp.Body or type(resp.Body) ~= "string" then
    warn("[MoonTP] ❌ Response body không hợp lệ!")
    return
end

-- Parse JSON
local success, messages = pcall(function()
    return HttpService:JSONDecode(resp.Body)
end)

if not success or type(messages) ~= "table" then
    warn("[MoonTP] ❌ Lỗi parse JSON: " .. tostring(success))
    return
end

if #messages == 0 then
    warn("[MoonTP] ❌ Channel không có tin nhắn nào!")
    return
end

print("[MoonTP] 📋 Tìm thấy " .. #messages .. " tin nhắn. Đang quét...")

-- =============================================
-- [TÌM SERVER]
-- =============================================
local bestServer = nil

for idx, msg in ipairs(messages) do
    if type(msg) == "table" then
        -- Xử lý content nếu có
        if msg.content and type(msg.content) == "string" then
            local jsonStr = msg.content:match("```json%s*(.-)%s*```")
            if jsonStr then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
                if parseOk and type(data) == "table" and data.jobId then
                    local age = 9999
                    if data.time and tonumber(data.time) then
                        age = os.time() - tonumber(data.time)
                    end
                    local moon = data.moon or data.Trạng_thái or "?"
                    
                    print(string.format("  → %s | Moon: %s | Sea: %s | %dm ago",
                        tostring(data.player or "?"),
                        tostring(moon),
                        tostring(data.sea or "?"),
                        math.floor(age / 60)
                    ))
                    
                    if not bestServer and age < 600 then
                        bestServer = data
                        bestServer.age = age
                    end
                end
            end
        end
        
        -- Xử lý embed nếu chưa tìm thấy
        if not bestServer and msg.embeds and type(msg.embeds) == "table" then
            for _, embed in ipairs(msg.embeds) do
                if embed.fields and type(embed.fields) == "table" then
                    local jobId, placeId, moon
                    for _, field in ipairs(embed.fields) do
                        if field.name and type(field.name) == "string" then
                            if field.name:find("JobID") then
                                if field.value and type(field.value) == "string" then
                                    jobId = field.value:match("[%w%-]+")
                                end
                            elseif field.name:find("Teleport") then
                                if field.value and type(field.value) == "string" then
                                    placeId = field.value:match("TeleportToPlaceInstance%((%d+)")
                                    if not jobId then
                                        jobId = field.value:match("'([%w%-]+)'")
                                    end
                                end
                            elseif field.name:find("Moon") or field.name:find("Trạng") then
                                if field.value and type(field.value) == "string" then
                                    moon = field.value:gsub("`", "")
                                end
                            end
                        end
                    end
                    if jobId then
                        bestServer = {
                            jobId = jobId,
                            placeId = placeId or tostring(game.PlaceId),
                            moon = moon or "?",
                            player = (msg.author and msg.author.username) or "?",
                            age = 0,
                        }
                        break
                    end
                end
            end
        end
    end
end

-- =============================================
-- [TELEPORT]
-- =============================================
if not bestServer or not bestServer.jobId then
    warn("[MoonTP] ❌ Không tìm thấy server Full Moon hợp lệ!")
    warn("[MoonTP] Gợi ý: Kiểm tra lại BOT_TOKEN và quyền đọc tin nhắn.")
    return
end

print("")
print("[MoonTP] ✅ ĐÃ TÌM THẤY SERVER!")
print("  Player:  " .. tostring(bestServer.player))
print("  Moon:    " .. tostring(bestServer.moon))
print("  Sea:     " .. tostring(bestServer.sea))
print("  JobId:   " .. tostring(bestServer.jobId))
print("  Age:     " .. math.floor((bestServer.age or 0) / 60) .. "m " .. ((bestServer.age or 0) % 60) .. "s")
print("")

local placeIdNum = tonumber(bestServer.placeId) or game.PlaceId
print("[MoonTP] 🚀 Teleport đến placeId:", placeIdNum, "jobId:", bestServer.jobId)

pcall(function()
    TeleportService:TeleportToPlaceInstance(placeIdNum, bestServer.jobId, LocalPlayer)
end)
