--[[
    Script: Moon Status Notifier (Fixed Version + Moon Timer)
    Author: Grok + Nhai (Vũ)
    Status: Đã fix + Thêm Place ID + Time to Full Moon / Time until Moon Ends
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

-- ====================== MOON TIMER FUNCTIONS (từ script checker) ======================
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
    
    if moon == "Full Moon (8/8)" and c2 <= 5 then
        return tostring(math.floor(c2)) .. " (End in " .. mmbs(5, c2) .. ")"
    elseif moon == "Full Moon (8/8)" and (c2 > 5 and c2 < 12) then
        return tostring(math.floor(c2)) .. " (Fake Moon)"
    elseif moon == "Full Moon (8/8)" and (c2 > 12 and c2 < 18) then
        return tostring(math.floor(c2)) .. " (Full in " .. mmbs(18, c2) .. ")"
    elseif moon == "Full Moon (8/8)" and (c2 > 18 and c2 <= 24) then
        return tostring(math.floor(c2)) .. " (End in " .. mmbs(30, c2) .. ")"
    end
    
    if moon == "Near Full (7/8)" and c2 < 12 then
        return tostring(math.floor(c2)) .. " (Full in " .. mmbs(18, c2) .. ")"
    elseif moon == "Near Full (7/8)" and c2 > 12 then
        return tostring(math.floor(c2)) .. " (Full in " .. mmbs(18 + 24, c2) .. ")"
    end
    
    return tostring(math.floor(c2))
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
        moonTimer = GetMoonTimer()          -- ← THÊM TIME TO FULL MOON / TIME UNTIL END
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
                {["name"] = "Moon Timer", ["value"] = "```" .. GetMoonTimer() .. "```", ["inline"] = false},  -- ← THÊM TIME TO NIGHT Ở ĐÂY
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
    warn("[Nhai System] Moon Notifier đã khởi động - Báo mỗi 60 giây (có Moon Timer)")
    while true do
        local moonStatus = GetMoonStatus()
        local isGoodMoon = (moonStatus == "Full Moon (8/8)" or
                           moonStatus == "Blue Moon" or
                           moonStatus == "Near Full (7/8)")
        if isGoodMoon then
            print("[Nhai System] 🌙 Moon tốt phát hiện:", moonStatus, "| Timer:", GetMoonTimer())
            SendToDiscord(moonStatus)
            SendToFirebase(moonStatus)
        else
            print("[Nhai System] Moon hiện tại:", moonStatus, "(Không gửi) | Timer:", GetMoonTimer())
        end
        task.wait(60)
    end
end)

print("[Nhai System] Script Sender đã được fix + thêm Moon Timer và chạy ổn định!")
