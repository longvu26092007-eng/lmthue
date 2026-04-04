-- =============================================
-- MOON RECEIVER — CHECK MOON LOCAL + CHỈ JOIN SERVER ≤10 NGƯỜI + RETRY 3 LẦN
-- =============================================
repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local req = (syn and syn.request) or (http and http.request) or http_request or request

if not req then
    warn("[MoonReceiver] ❌ Executor không hỗ trợ HTTP!")
    return
end

-- ==================== HÀM CHECK MOON TỪ SENDER ====================
function GetCurrentSea()
    local mapAttr = workspace:GetAttribute("MAP")
    if mapAttr then
        return tonumber(mapAttr:match("%d+")) or 0
    end
    local placeId = game.PlaceId
    if placeId == 2753915549 or placeId == 4442272183 then return 1
    elseif placeId == 7449423635 then return 3
    else return 0 end
end

function GetMoonStatus()
    local sea = GetCurrentSea()
    local tex = ""
    pcall(function()
        if sea == 1 or sea == 3 then
            tex = (Lighting:FindFirstChild("Sky") and Lighting.Sky.MoonTextureId)
               or (Lighting:FindFirstChild("Space_Skybox") and Lighting.Space_Skybox.MoonTextureId)
        elseif sea == 2 then
            tex = (Lighting:FindFirstChild("FantasySky") and Lighting.FantasySky.MoonTextureId)
        end
    end)
    tex = tostring(tex or ""):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    local moonTable = {
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
        ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon (8/8)",
        ["http://www.roblox.com/asset/?id=9709149052"] = "Near Full (7/8)",
    }
    return moonTable[tex] or "Normal Moon"
end

-- ==================== FUNCTION TPSERVER (GIỮ NGUYÊN) ====================
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

-- ==================== BIẾN THEO YÊU CẦU ====================
local lastTeleportTime = 0
local teleportCooldown = 25
local lastJobId = ""
local currentTargetJobId = ""
local attemptCount = 0
local maxAttempts = 3
local retryDelay = 7

print("[MoonReceiver] 🔍 Đang lắng nghe Firebase (check Moon local + chỉ join ≤10 người + retry 3 lần)...")

local function GetPlayerCountNum(str)
    if not str then return 999 end
    local num = tonumber(str:match("(%d+)/"))
    return num or 999
end

task.spawn(function()
    while task.wait(5) do
        xpcall(function()
            -- ====================== CHECK MOON LOCAL TRƯỚC ======================
            local localMoon = GetMoonStatus()
            local isGoodMoon = (localMoon == "Full Moon (8/8)" or 
                               localMoon == "Blue Moon" or 
                               localMoon == "Near Full (7/8)")

            if isGoodMoon then
                print("[MoonReceiver] 🌕 Moon hiện tại ĐÃ TỐT (" .. localMoon .. ") → Không cần hop JobID khác!")
                return  -- Bỏ qua phần hop, tiếp tục check ở vòng sau
            end

            -- ====================== MOON XẤU → MỚI CHECK FIREBASE ======================
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
            local playerNum = GetPlayerCountNum(data.playerCount)

            if age < 600 and data.jobId ~= game.JobId then
                if playerNum > 10 then
                    print("[MoonReceiver] ❌ Server có " .. playerNum .. " người (>10) → Bỏ qua")
                    return
                end

                if data.jobId ~= currentTargetJobId then
                    currentTargetJobId = data.jobId
                    attemptCount = 0
                    print(string.format("[MoonReceiver] ✅ Tín hiệu Moon mới! | %s | %dm ago | %d người", 
                          data.moon or "Unknown", math.floor(age / 60), playerNum))
                end

                if attemptCount < maxAttempts and tick() - lastTeleportTime >= teleportCooldown then
                    lastTeleportTime = tick()
                    attemptCount = attemptCount + 1

                    print(string.format("[MoonReceiver] 🚀 Lần %d/3 → Dùng TPServer teleport sang JobID: %s (%d người)", 
                          attemptCount, data.jobId, playerNum))

                    task.wait(2.5)
                    local result = TPServer(data.jobId)
                    print("[MoonReceiver] TPServer trả về:", result)

                    if attemptCount < maxAttempts then
                        task.wait(retryDelay)
                    end
                end

                if attemptCount >= maxAttempts then
                    print("[MoonReceiver] ⚠️ Đã thử 3 lần JobID " .. data.jobId .. " mà không join được → Bỏ và chờ JobID mới")
                    currentTargetJobId = ""
                    attemptCount = 0
                    lastJobId = data.jobId
                end
            elseif data.jobId == game.JobId then
                warn("[MoonReceiver] ❌ Đang ở server có trăng rồi!")
            end
        end, function(err) end)
    end
end)

print("[MoonReceiver] Đã khởi động thành công - Check Moon local liên tục!")
