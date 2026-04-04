-- =============================================
-- 🚀 MOON TELEPORTER — RECEIVER (Đọc Firebase)
-- Fix lỗi: "previous teleport is in processing"
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

local lastJobId = ""
local isTeleporting = false -- CỜ TRẠNG THÁI CHỐNG SPAM
print("[MoonReceiver] 🔍 Đang lắng nghe tín hiệu từ Firebase...")

task.spawn(function()
    while task.wait(10) do
        if isTeleporting then continue end -- Đang bay rồi thì bỏ qua không quét nữa
        
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
                
                if age < 600 and data.jobId ~= lastJobId and data.jobId ~= game.JobId then
                    print(string.format("[MoonReceiver] ✅ Tín hiệu mới! Moon: %s | Sea: %s | %dm ago", 
                        data.moon or "?", 
                        data.sea or "?", 
                        math.floor(age / 60)
                    ))
                    
                    lastJobId = data.jobId
                    isTeleporting = true -- Bật cờ khóa dịch chuyển
                    print("[MoonReceiver] 🚀 Đang teleport...")
                    
                    TeleportService:TeleportToPlaceInstance(
                        tonumber(data.placeId) or game.PlaceId, 
                        data.jobId, 
                        LocalPlayer
                    )
                    
                    -- Nếu sau 20 giây mà dịch chuyển thất bại (Roblox lỗi), mở khóa cờ để nó quét lại
                    task.delay(20, function()
                        isTeleporting = false
                    end)
                    
                elseif data.jobId == game.JobId and data.jobId ~= lastJobId then
                    lastJobId = data.jobId
                    warn("[MoonReceiver] ❌ Bạn đang ở sẵn server này rồi!")
                end
            end
        end, function(err)
            -- Im lặng bỏ qua lỗi vặt giống Source SG
        end)
    end
end)
