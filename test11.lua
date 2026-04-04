-- =============================================
-- MOON RECEIVER — FIX LỖI 773 (Check PlaceId + Debug chi tiết)
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
local teleportCooldown = 35   -- Tăng lên 35 giây để tránh restrict
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (Anti-773 Mode)...")

-- Bắt sự kiện teleport fail để debug
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        warn("[MoonReceiver] ❌ TeleportInitFailed | Error: " .. errorMessage .. " | Code: " .. tostring(teleportResult))
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

            -- CHECK PLACEID RẤT RÕ
            if targetPlaceId ~= currentPlaceId then
                warn("[MoonReceiver] ❌ PlaceId KHÔNG KHỚP! Bỏ qua teleport (khác Sea)")
                return
            end

            if age < 600 and data.jobId ~= game.JobId then
                if tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    lastJobId = data.jobId

                    print(string.format("[MoonReceiver] ✅ Tín hiệu Moon OK! | %s | PlaceId khớp | %dm ago", data.moon or "Unknown", math.floor(age / 60)))
                    print("[MoonReceiver] 🚀 Đang teleport → JobID: " .. data.jobId)

                    task.wait(4) -- Tăng delay lên 4 giây (rất quan trọng)

                    local success, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(targetPlaceId, data.jobId, LocalPlayer)
                    end)

                    if not success then
                        warn("[MoonReceiver] ❌ Teleport pcall error: " .. tostring(err))
                    end
                else
                    print("[MoonReceiver] ⏳ Đang cooldown... còn " .. math.floor(teleportCooldown - (tick() - lastTeleportTime)) .. " giây")
                end
            elseif data.jobId == game.JobId then
                warn("[MoonReceiver] ❌ Đang ở server Moon rồi!")
            end
        end, function(err) warn("[MoonReceiver] Error loop: " .. err) end)
    end
end)

print("[MoonReceiver] Đã fix xong - Anti 773 tối đa!")
