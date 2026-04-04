-- =============================================
-- MOON RECEIVER — CHECK PLACEID TRƯỚC RỒI MỚI HOP
-- =============================================
repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer

local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local req = (syn and syn.request) or (http and http.request) or http_request or request

if not req then
    warn("[MoonReceiver] ❌ Executor không hỗ trợ HTTP!")
    return
end

local lastTeleportTime = 0
local teleportCooldown = 25
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (Đã thêm Check PlaceId)...")

task.spawn(function()
    while task.wait(5) do
        xpcall(function()
            local ok, resp = pcall(function()
                return req({
                    Url = FIREBASE_URL,
                    Method = "GET",
                    Headers = {["Content-Type"] = "application/json"}
                })
            end)

            if not ok or not resp or not resp.Body or resp.Body == "null" then return end

            local data = HttpService:JSONDecode(resp.Body)
            if not data or not data.jobId or not data.placeId then return end

            local currentPlaceId = game.PlaceId
            local targetPlaceId  = tonumber(data.placeId)
            local age            = data.time and (os.time() - tonumber(data.time)) or 9999

            -- ==================== CHECK PLACEID TRƯỚC ====================
            if targetPlaceId ~= currentPlaceId then
                warn("[MoonReceiver] ❌ PlaceId không khớp! (Hiện tại: " .. currentPlaceId .. " | Firebase: " .. targetPlaceId .. ")")
                warn("→ Bỏ qua teleport (khác Sea)")
                return
            end

            -- Chỉ hop khi PlaceId khớp
            if age < 600 and data.jobId ~= game.JobId then
                if tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    lastJobId = data.jobId

                    print(string.format("[MoonReceiver] ✅ Tín hiệu Moon mới! | %s | PlaceId OK (%s) | %dm ago", 
                        data.moon or "Unknown", targetPlaceId, math.floor(age / 60)))

                    print("[MoonReceiver] 🚀 Teleport sang JobID: " .. data.jobId)

                    task.wait(2.5) -- Delay chống lỗi token

                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(
                            targetPlaceId,
                            data.jobId,
                            LocalPlayer
                        )
                    end)
                end
            elseif data.jobId == game.JobId then
                warn("[MoonReceiver] ❌ Bạn đang ở server có trăng rồi!")
            end
        end, function(err) end)
    end
end)

print("[MoonReceiver] Đã fix xong - Check PlaceId trước khi hop!")
