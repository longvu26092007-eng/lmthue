-- =============================================
-- 🚀 MOON RECEIVER — DÙNG JOIN JOBID (KIỂU BANANA)
-- =============================================
repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer

local Services = setmetatable({}, {__index = function(self, name)
    return game:GetService(name)
end})

local HttpService = Services.HttpService
local ReplicatedStorage = Services.ReplicatedStorage
local Players = Services.Players
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local req = (syn and syn.request) or (http and http.request) or http_request or request

if not req then
    warn("[MoonReceiver] ❌ Executor không hỗ trợ HTTP!")
    return
end

local lastTeleportTime = 0
local teleportCooldown = 20   -- 20 giây là ổn nhất hiện tại
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (Join JobID kiểu Banana)...")

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

            -- Chỉ teleport khi có JobID mới + trăng còn tươi (< 10 phút)
            if age < 600 and data.jobId ~= game.JobId then

                if tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    lastJobId = data.jobId

                    print(string.format("[MoonReceiver] ✅ Tín hiệu Moon mới! | %dm ago", math.floor(age / 60)))
                    print("[MoonReceiver] 🚀 Đang Join JobID: " .. data.jobId)

                    -- ========== CÁCH JOIN JOBID KIỂU BANANA ==========
                    task.wait(1.2)
                    pcall(function()
                        ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer("teleport", data.jobId)
                    end)

                end
            elseif data.jobId == game.JobId then
                warn("[MoonReceiver] ❌ Bạn đang ở server có trăng rồi!")
            end
        end, function(err) end)
    end
end)

print("[MoonReceiver] Đã chuyển sang Join JobID kiểu Banana - Ổn định hơn!")
