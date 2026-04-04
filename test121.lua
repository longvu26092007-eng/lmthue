-- =============================================
-- MOON RECEIVER — TELEPORTSERVICE + PLACEID TỪ FIREBASE
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
local teleportCooldown = 25   -- 25 giây cooldown (tránh lỗi token)
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (TeleportService + PlaceId)...")

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
            if not data or not data.jobId then return end

            local age = data.time and (os.time() - tonumber(data.time)) or 9999

            -- LẤY PLACEID TỪ FIREBASE (như mày nói)
            local targetPlaceId = tonumber(data.placeId) or game.PlaceId

            if age < 600 and data.jobId ~= game.JobId then
                if tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    lastJobId = data.jobId

                    print(string.format("[MoonReceiver] ✅ Tín hiệu Moon mới! | %s | PlaceId: %s | %dm ago", 
                        data.moon or "Unknown", targetPlaceId, math.floor(age / 60)))

                    print("[MoonReceiver] 🚀 Teleport sang JobID: " .. data.jobId .. " | PlaceId: " .. targetPlaceId)

                    task.wait(2.5) -- Delay quan trọng tránh lỗi token

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

print("[MoonReceiver] Đã fix xong - Dùng TeleportService + PlaceId từ Firebase!")
