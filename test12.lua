-- =============================================
-- MOON RECEIVER — DÙNG TPSERVER CHUẨN (Join JobID)
-- =============================================
repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local req = (syn and syn.request) or (http and http.request) or http_request or request

if not req then
    warn("[MoonReceiver] ❌ Executor không hỗ trợ HTTP!")
    return
end

-- ==================== FUNCTION TPSERVER MÀY GỬI ====================
function TPServer(JobIdorstring)
    if string.find(JobIdorstring, "TeleportService") then
        local deptrai, tao = pcall(function()
            loadstring(JobIdorstring)()
        end)
        if deptrai then
            return "Success | Teleporting..."
        else
            return tao
        end
    else
        game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", tostring(JobIdorstring))
        return "Trying to teleport..."
    end
end

local lastTeleportTime = 0
local teleportCooldown = 25
local lastJobId = ""

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (dùng TPServer)...")

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

            if age < 600 and data.jobId ~= game.JobId then
                if tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    lastJobId = data.jobId

                    print(string.format("[MoonReceiver] ✅ Tín hiệu Moon mới! | %s | %dm ago", data.moon or "Unknown", math.floor(age / 60)))
                    print("[MoonReceiver] 🚀 Đang dùng TPServer teleport sang JobID:", data.jobId)

                    task.wait(2.5) -- delay an toàn trước khi tele

                    local result = TPServer(data.jobId)  -- <-- ÁP DỤNG TPSERVER Ở ĐÂY
                    print("[MoonReceiver] TPServer trả về:", result)
                end
            elseif data.jobId == game.JobId then
                warn("[MoonReceiver] ❌ Đang ở server có trăng rồi!")
            end
        end, function(err) end)
    end
end)

print("[MoonReceiver] Đã khởi động thành công - Sử dụng TPServer chuẩn!")
