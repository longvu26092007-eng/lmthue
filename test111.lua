-- =============================================
-- 🚀 MOON RECEIVER — CÔNG NGHỆ COOLDOWN TICK()
-- Chống kẹt Teleport theo chuẩn UI Hub
-- =============================================

repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function() return game:GetService(name) end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name))
    end
end})

local HttpService = Services.HttpService
local TeleportService = Services.TeleportService
local Players = Services.Players
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

if not req then 
    warn("[MoonReceiver] ❌ Executor không hỗ trợ HTTP Request!")
    return 
end

local lastTeleportTime = 0
local teleportCooldown = 15 -- CHỜ 15 GIÂY GIỮA CÁC LẦN GỌI TELEPORT (Chống lỗi đỏ)
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe tín hiệu Firebase...")

task.spawn(function()
    while task.wait(5) do
        xpcall(function()
            local ok, resp = pcall(function()
                return req({
                    Url = FIREBASE_URL,
                    Method = "GET",
                    Headers = {["Content-Type"] = "application/json"},
                    Cookies = {}
                })
            end)

            if not ok or not resp or not resp.Body or resp.Body == "null" then return end

            local body = resp.Body
            if type(body) == "string" and body:sub(1,1) ~= "{" then return end

            local parseOk, data = pcall(function() return HttpService:JSONDecode(body) end)
            if not parseOk or type(data) ~= "table" then return end

            if data.jobId then
                local age = data.time and (os.time() - tonumber(data.time)) or 9999
                
                -- Điều kiện: Trăng mới, JobId khác hiện tại
                if age < 600 and data.jobId ~= game.JobId then
                    
                    -- KIỂM TRA COOLDOWN BẰNG TICK() GIỐNG SCRIPT KIA
                    if tick() - lastTeleportTime >= teleportCooldown then
                        lastTeleportTime = tick() -- Đặt lại thời gian
                        lastJobId = data.jobId
                        
                        print(string.format("[MoonReceiver] ✅ Tín hiệu mới! Moon: %s | %dm ago", data.moon or "?", math.floor(age / 60)))
                        print("[MoonReceiver] 🚀 Đang teleport tới: " .. data.jobId)
                        
                        -- Dùng pcall bọc lệnh Teleport lại y hệt script mẫu
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(
                                tonumber(data.placeId) or game.PlaceId, 
                                data.jobId, 
                                LocalPlayer
                            )
                        end)
                    else
                        -- Đang trong thời gian chờ (15s), giữ im lặng để không bị spam lỗi
                    end

                elseif data.jobId == game.JobId and data.jobId ~= lastJobId then
                    lastJobId = data.jobId
                    warn("[MoonReceiver] ❌ Bạn đang ở sẵn server có trăng này rồi!")
                end
            end
        end, function(err) end)
    end
end)
