--[[
    Script: Moon Status Notifier (FINAL FIXED)
    Author: Grok + Nhai (Vũ)
    Status: Chỉ báo Full Moon (8/8) và Blue Moon + Full In / End In chuẩn
]]
local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"

-- ★ Đợi game load
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(5)

local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local req = http_request or request or (syn and syn.request) or (http and http.request) or fluxus_request
if not req then
    warn("[MoonScan] ❌ Executor không hỗ trợ HTTP request!")
    return
end

-- ====================== FUNCTIONS (từ GUI mày gửi) ======================
function getServerTime()
    local RealTime = tostring(Lighting.ClockTime)
    local RealTimeTable = RealTime:split(".")
    local Minute = RealTimeTable[1] or "0"
    local decimalPart = tonumber(RealTimeTable[2]) or 0
    local Second = tonumber(decimalPart / 100) * 60
    return Minute, math.floor(Second)
end

function MoonTextureId()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky and sky.MoonTextureId then
        return sky.MoonTextureId
    end
    return ""
end

function CheckMoon()
    local moon5 = "http://www.roblox.com/asset/?id=9709149431"   -- Full Moon 8/8
    local moonBlue = "http://www.roblox.com/asset/?id=15493317929" -- Blue Moon
    local moonreal = MoonTextureId()
    
    if moonreal == moon5 then
        return "Full Moon"
    elseif moonreal == moonBlue then
        return "Blue Moon"
    end
    return "Normal Moon"
end

function mmbs(inp, c2)
    local ps = inp - c2
    if ps > 1 then
        return math.floor(ps) .. " Minutes"
    else
        return math.floor(ps * 60) .. " Seconds"
    end
end

-- ====================== MOON TIMER (CHỈ FULL IN + END IN) ======================
function GetMoonTimer()
    local c2 = Lighting.ClockTime
    local moon = CheckMoon()
    
    if moon == "Full Moon" then
        if c2 <= 5 then
            return "Full Moon (8/8) - End in " .. mmbs(5, c2)
        elseif c2 >= 12 and c2 < 18 then
            return "Full Moon (8/8) - Full in " .. mmbs(18, c2)
        else
            return "Full Moon (8/8) - End in " .. mmbs(30, c2)
        end
    elseif moon == "Blue Moon" then
        return "Blue Moon - Active"
    end
    return tostring(math.floor(c2)) .. " (Normal Moon)"
end

-- ====================== SEND FUNCTIONS ======================
local function SendToFirebase(moonName)
    local dbData = {
        jobId = game.JobId,
        placeId = game.PlaceId,
        moon = moonName,
        sea = GetCurrentSea(),
        time = os.time(),
        playerCount = GetPlayerCount(),
        moonTimer = GetMoonTimer()
    }
    local success, err = pcall(function()
        req({
            Url = FIREBASE_URL,
            Method = "PATCH",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(dbData)
        })
    end)
    if success then
        print("[Sender] ✅ Firebase:", moonName)
    else
        warn("[Sender] ❌ Firebase error:", err)
    end
end

local function SendToDiscord(moonName)
    local teleportCode = string.format(
        "game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)",
        game.PlaceId, game.JobId
    )
    local data = {
        ["embeds"] = {{
            ["title"] = "🌙 MOON STATUS UPDATE",
            ["description"] = "Tự động báo cáo mặt trăng + thời gian",
            ["color"] = 0x00ffff,
            ["fields"] = {
                {["name"] = "Trạng thái", ["value"] = "```" .. moonName .. "```", ["inline"] = true},
                {["name"] = "Sea", ["value"] = "```Sea " .. GetCurrentSea() .. "```", ["inline"] = true},
                {["name"] = "Place ID", ["value"] = "```" .. game.PlaceId .. "```", ["inline"] = true},
                {["name"] = "Người chơi", ["value"] = "```" .. GetPlayerCount() .. "```", ["inline"] = true},
                {["name"] = "Moon Timer", ["value"] = "```" .. GetMoonTimer() .. "```", ["inline"] = false},
                {["name"] = "JobID", ["value"] = "```" .. game.JobId .. "```"},
                {["name"] = "Mã Teleport", ["value"] = "```lua\n" .. teleportCode .. "\n```"}
            },
            ["footer"] = {["text"] = "Nhai System • " .. os.date("%X")}
        }}
    }
    local success, err = pcall(function()
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    if success then
        print("[Sender] ✅ Discord:", moonName)
    else
        warn("[Sender] ❌ Discord error:", err)
    end
end

-- ====================== MAIN LOOP ======================
print("═══════════════════════════════════════════")
print("[MoonScan] 🌕 Script STARTED!")
print("[MoonScan] Sea: " .. GetCurrentSea())
print("───────────────────────────────────────────")
print("Moon: " .. GetMoonStatus() .. " | Timer: " .. GetMoonTimer())
print("═══════════════════════════════════════════")

task.spawn(function()
    while true do
        local moonStatus = GetMoonStatus()
        local isGoodMoon = (moonStatus == "Full Moon" or moonStatus == "Blue Moon")

        print("[" .. os.date("%H:%M:%S") .. "] Scan | Moon: " .. moonStatus .. " | Timer: " .. GetMoonTimer())

        if isGoodMoon then
            print("📤 GỬI Discord + Firebase ngay!")
            SendToDiscord(moonStatus)
            SendToFirebase(moonStatus)
        else
            print("❌ Không gửi")
        end
        task.wait(60)
    end
end)

print("[Nhai System] Script Sender đã được fix và chạy ổn định!")
