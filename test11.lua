-- =============================================
-- 🚀 MOON TELEPORTER — BẢN KHẮC CHẾ DELTA EXECUTOR
-- Tối ưu bởi Nhai (Vũ) - Fix lỗi "pairs" nội bộ
-- =============================================

local BOT_TOKEN  = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"

local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer

local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not req then warn("[MoonTP] Executor không hỗ trợ HTTP") return end

print("[MoonTP] Đang kết nối tới Discord...")

-- FIX LỖI DELTA: Bơm sẵn Cookies = {} để Delta không bị crash khi gọi pairs()
local options = {
    Url = "https://roproxy.com/api/v10/channels/" .. CHANNEL_ID .. "/messages?limit=20",
    Method = "GET",
    Headers = {
        ["Authorization"] = "Bot " .. BOT_TOKEN,
        ["Content-Type"] = "application/json"
    },
    Cookies = {} -- <-- Lớp khiên chống lỗi "invalid argument #1 to pairs"
}

local ok, resp = pcall(function() return req(options) end)
if not ok then warn("[MoonTP] Lỗi gọi Request: " .. tostring(resp)) return end
if not resp or not resp.Body then warn("[MoonTP] Không có dữ liệu trả về.") return end

-- FIX LỖI PARSE: Kiểm tra xem Delta đã tự động giải mã JSON giùm chưa
local messages = resp.Body
if type(messages) == "string" then
    -- Nếu proxy trả về lỗi (không phải [ hay {), dừng ngay
    if messages:sub(1,1) ~= "[" and messages:sub(1,1) ~= "{" then
        warn("[MoonTP] Proxy lỗi: " .. messages:sub(1, 50) .. "...")
        return
    end
    
    local s, res = pcall(function() return HttpService:JSONDecode(messages) end)
    if not s then warn("[MoonTP] Lỗi định dạng JSON") return end
    messages = res
end

if type(messages) ~= "table" or #messages == 0 then
    warn("[MoonTP] Channel trống hoặc không thể lấy tin nhắn!")
    return
end

-- =============================================
-- [ TÌM SERVER MOON MỚI NHẤT ]
-- =============================================
local targetId = nil

for i = 1, #messages do
    local msg = messages[i]
    
    -- 1. Lấy từ khối JSON (Code block)
    if msg.content and msg.content:match("```json") then
        local jsonStr = msg.content:match("```json%s*(.-)%s*```")
        if jsonStr then
            local s, d = pcall(function() return HttpService:JSONDecode(jsonStr) end)
            if s and d and d.jobId then 
                targetId = d.jobId 
                break 
            end
        end
    end
    
    -- 2. Lấy từ Embed (Tin nhắn cũ)
    if not targetId and msg.embeds and msg.embeds[1] and msg.embeds[1].fields then
        local fields = msg.embeds[1].fields
        for f = 1, #fields do
            local field = fields[f]
            if field.name:find("JobID") then 
                targetId = field.value:match("[%w%-]+") 
            end
            if field.name:find("Teleport") then 
                targetId = targetId or field.value:match("'([%w%-]+)'") 
            end
        end
    end
    
    if targetId then break end
end

-- =============================================
-- [ THỰC HIỆN TELEPORT ]
-- =============================================
if targetId then
    print("[MoonTP] ✅ Tìm thấy JobID: " .. targetId)
    print("[MoonTP] 🚀 Đang nhảy server...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetId, LocalPlayer)
    end)
else
    warn("[MoonTP] ❌ Không tìm thấy JobID hợp lệ trong 20 tin nhắn gần nhất!")
end
