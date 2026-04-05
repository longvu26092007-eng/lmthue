--[[
    Script: Moon Status Notifier (FINAL FIXED)
    Author: Grok + Nhai (Vũ)
    Status: Fix workspace nil + Chỉ báo Full Moon (8/8) và Blue Moon (bất kể ngày đêm)
]]
local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"

-- ★ Đợi game load
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(5)

local workspace = game:GetService("Workspace")   -- ← ĐÃ THÊM DÒNG NÀY ĐỂ FIX LỖI NIL
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local req = http_request or request or (syn and syn.request) or (http and http.request) or fluxus_request
if not req then
    warn("[MoonScan] ❌ Executor không hỗ trợ HTTP request!")
    return
end

-- ====================== FUNCTIONS ======================
function GetCurrentSea()
    local mapAttr = workspace:GetAttribute("MAP")
    if mapAttr then
        return tonumber(tostring(mapAttr):match("%d+")) or 0
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
            local sky = Lighting:FindFirstChild("Sky")
            if sky and sky.MoonTextureId and sky.MoonTextureId ~= "" then tex = sky.MoonTextureId end
            if tex == "" then
                local spaceSky = Lighting:FindFirstChild("Space_Skybox")
                if spaceSky and spaceSky.MoonTextureId and spaceSky.MoonTextureId ~= "" then tex = spaceSky.MoonTextureId end
            end
        elseif sea == 2 then
            local fantasySky = Lighting:FindFirstChild("FantasySky")
            if fantasySky and fantasySky.MoonTextureId and fantasySky.MoonTextureId ~= "" then tex = fantasySky.MoonTextureId end
        end
    end)
    if tex == "" then return "Normal Moon" end
    tex = tostring(tex):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
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

local function GetFullTimerDisplay()
    local c2 = Lighting.ClockTime
    local moon = GetMoonStatus()
    local lines = {}
    table.insert(lines, "Moon: " .. moon .. " | Clock: " .. string.format("%.1f", c2))
    if c2 >= 5 and c2 < 18 then
        table.insert(lines, "🌙 Night in " .. mmbs(18, c2))
    else
        table.insert(lines, "🌙 Night NOW")
    end
    table.insert(lines, GetMoonTimer())
    return table.concat(lines, "\n")
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
        req({ Url = FIREBASE_URL, Method = "PATCH", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(dbData) })
    end)
    if success then
        print("[Sender] ✅ Firebase:", moonName)
    else
        warn("[Sender] ❌ Firebase error:", err)
    end
end

local function SendToDiscord(moonName)
    local teleportCode = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)", game.PlaceId, game.JobId)
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
        req({ Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data) })
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
print(GetFullTimerDisplay())
print("═══════════════════════════════════════════")

task.spawn(function()
    while true do
        local moonStatus = GetMoonStatus()
        local isGoodMoon = (moonStatus == "Full Moon (8/8)" or moonStatus == "Blue Moon")

        print("[" .. os.date("%H:%M:%S") .. "] Scan | Moon: " .. moonStatus .. " | Timer: " .. GetMoonTimer())

        if isGoodMoon then
            print("📤 GỬI Discord + Firebase ngay!")
            SendToDiscord(moonStatus)
            SendToFirebase(moonStatus)
        else
            print("❌ Không gửi (không phải Full Moon hoặc Blue Moon)")
        end
        task.wait(60)
    end
end)

print("[Nhai System] Script Sender đã được fix và chạy ổn định!")
