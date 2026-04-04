local BOT_TOKEN = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not request then warn("Executor không hỗ trợ HTTP") return end

print("[MoonTP] Đang đọc dữ liệu từ Discord...")

local options = {Url = "https://roproxy.com/api/v10/channels/"..CHANNEL_ID.."/messages?limit=20", Method = "GET", Headers = {["Authorization"] = "Bot "..BOT_TOKEN, ["Content-Type"] = "application/json"}}

local ok, resp = pcall(function() return request(options) end)

-- KIỂM TRA LỖI LINE 19 (Parse JSON)
if ok and resp and resp.Body then
    local dataString = resp.Body
    -- Kiểm tra nếu Body rỗng hoặc không phải JSON (bắt đầu bằng { hoặc [)
    if dataString:sub(1,1) ~= "[" and dataString:sub(1,1) ~= "{" then
        warn("[MoonTP] Proxy trả về dữ liệu lỗi (không phải JSON). Có thể RoProxy đang bảo trì.")
        return
    end

    local s, messages = pcall(function() return HttpService:JSONDecode(dataString) end)
    if not s or not messages then warn("[MoonTP] Lỗi định dạng JSON tin nhắn.") return end

    local bestServer = nil
    for i = 1, #messages do
        local msg = messages[i]
        local jsonStr = msg.content and msg.content:match("```json%s*(.-)%s*```")
        if jsonStr then
            local s2, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
            if s2 and data and data.jobId then
                bestServer = data
                break
            end
        end
        if not bestServer and msg.embeds and msg.embeds[1] and msg.embeds[1].fields then
            local fields = msg.embeds[1].fields
            local jId = nil
            for f = 1, #fields do
                local field = fields[f]
                if field.name:find("JobID") then jId = field.value:match("[%w%-]+")
                elseif field.name:find("Teleport") then jId = jId or field.value:match("'([%w%-]+)'") end
            end
            if jId then bestServer = {jobId = jId, placeId = game.PlaceId} break end
        end
    end

    if bestServer and bestServer.jobId then
        print("[MoonTP] Target found: "..bestServer.jobId)
        TeleportService:TeleportToPlaceInstance(tonumber(bestServer.placeId) or game.PlaceId, bestServer.jobId, LocalPlayer)
    else
        warn("[MoonTP] Không tìm thấy server Moon nào trong 20 tin nhắn gần nhất.")
    end
else
    warn("[MoonTP] Thất bại khi kết nối tới Proxy.")
end
