--[[
    Script: Moon Status Notifier (Fixed Version + Moon Timer)
    Author: Grok + Nhai (Vũ)
    Status: Bỏ Fake Moon + Chỉ báo Near Full (7/8) & Full Moon thật (8/8) & Blue Moon
]]
local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ====================== FIX FUNCTIONS ======================
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

function GetPlayerCount()
    return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
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

-- ====================== MOON TIMER ======================
local function mmbs(inp, c2)
    local ps = inp - c2
    if ps > 1 then
        return math.floor(ps) .. " Minutes"
    else
        return math.floor(ps * 60) .. " Seconds"
    end
end

local function GetMoonTimer()
    local c2 = Lighting.ClockTime
    local moon = GetMoonStatus()
   
    if moon == "Full Moon (8/8)" then
        if c2 <= 5 then
            return "Full Moon (8/8) - End in " .. mmbs(5, c2)
        elseif c2 > 5 and c2 < 12 then
            return "Full Moon (8/8) - Fake Moon"   -- vẫn giữ để hiển thị timer, nhưng không gửi
        elseif c2 >= 12 and c2 < 18 then
            return "Full Moon (8/8) - Full in " .. mmbs(18, c2)
        else
            return "Full Moon (8/8) - End in " .. mmbs(30, c2)
        end
    elseif moon == "Near Full (7/8)" then
        if c2 < 18 then
            return "Near Full (7/8) - Full in " .. mmbs(18, c2)
        else
            return "Near Full (7/8) - Full in " .. mmbs(42, c2)
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
        local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
        if requestFunc then
            requestFunc({
                Url = FIREBASE_URL,
                Method = "PATCH",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(dbData)
            })
        end
    end)
    if success then
        print("[Sender] ✅ Đã gửi lên Firebase:", moonName, "| Timer:", GetMoonTimer())
    else
        warn("[Sender] ❌ Lỗi gửi Firebase:", err)
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
        local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
        if requestFunc then
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
    if success then
        print("[Sender] ✅ Đã gửi Discord:", moonName, "| Timer:", GetMoonTimer())
    else
        warn("[Sender] ❌ Lỗi gửi Discord:", err)
    end
end

-- ====================== MAIN LOOP ======================
task.spawn(function()
    warn("[Nhai System] Moon Notifier đã khởi động - Chỉ báo Near Full (7/8), Full Moon thật (8/8), Blue Moon")
    while true do
        local moonStatus = GetMoonStatus()
        local c2 = Lighting.ClockTime
        local isNight = (c2 >= 18 or c2 < 5)
        local isGoodMoon = false

        if moonStatus == "Full Moon (8/8)" and isNight then
            isGoodMoon = true
        elseif moonStatus == "Near Full (7/8)" then
            isGoodMoon = true
        elseif moonStatus == "Blue Moon" then
            isGoodMoon = true
        end

        if isGoodMoon then
            print("[Nhai System] 🌙 Moon tốt phát hiện:", moonStatus, "| Timer:", GetMoonTimer())
            SendToDiscord(moonStatus)
            SendToFirebase(moonStatus)
        else
            print("[Nhai System] Moon hiện tại:", moonStatus, "(Không gửi - Fake Moon hoặc không phải moon tốt)")
        end
        task.wait(60)
    end
end)

print("[Nhai System] Script Sender đã được fix + Không báo Fake Moon và chạy ổn định!")
