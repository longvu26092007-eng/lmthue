-- =============================================
-- MOON RECEIVER — TELEPORTSERVICE + LOCALPLAYER BÌNH THƯỜNG
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
local teleportCooldown = 45   -- Tăng để tránh lỗi token
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (LocalPlayer bình thường)...")

-- Bắt lỗi teleport
TeleportService.TeleportInitFailed:Connect(function(player, result, message)
    if player == LocalPlayer then
        warn("[MoonReceiver] ❌ Teleport Failed | " .. message)
    end
end)

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

            print("[MoonReceiver] 📍 Current PlaceId: " .. currentPlaceId .. " | Firebase PlaceId: " .. targetPlaceId)

            -- Check PlaceId trước
            if targetPlaceId ~= currentPlaceId then
                warn("[MoonReceiver] ❌ PlaceId không khớp! Bỏ qua teleport")
                return
            end

            if age < 600 and data.jobId ~= game.JobId then
                if tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    lastJobId = data.jobId

                    print(string.format("[MoonReceiver] ✅ Moon OK! | %s | %dm ago", data.moon or "Unknown", math.floor(age / 60)))
                    print("[MoonReceiver] 🚀 Đang teleport sang JobID: " .. data.jobId)

                    task.wait(6)   -- Delay lớn

                    local success, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(targetPlaceId, data.jobId, LocalPlayer)
                    end)

                    if not success then
                        warn("[MoonReceiver] ❌ Teleport error: " .. tostring(err))
                    end
                else
                    print("[MoonReceiver] ⏳ Còn cooldown: " .. math.floor(teleportCooldown - (tick() - lastTeleportTime)) .. " giây")
                end
            elseif data.jobId == game.JobId then
                warn("[MoonReceiver] ❌ Bạn đang ở server Moon rồi!")
            end
        end, function(err) end)
    end
end)

print("[MoonReceiver] Đã load xong - Chỉ dùng LocalPlayer + TeleportService!")
