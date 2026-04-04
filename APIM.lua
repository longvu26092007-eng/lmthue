--[[
    Script: Moon Status Notifier (FIXED v2)
    Fix: Bỏ điều kiện isNight → gửi ngay khi detect 8/8, 7/8, Blue Moon
]]
local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"

-- ★ Đợi game load
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(5)

local Lighting    = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ★ Request function
local req = http_request or request or (syn and syn.request) or (http and http.request) or fluxus_request
if not req then
    warn("[MoonScan] ❌ Không tìm được HTTP request function!")
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
            if sky and sky.MoonTextureId and sky.MoonTextureId ~= "" then
                tex = sky.MoonTextureId
            end
            if tex == "" then
                local spaceSky = Lighting:FindFirstChild("Space_Skybox")
                if spaceSky and spaceSky.MoonTextureId and spaceSky.MoonTextureId ~= "" then
                    tex = spaceSky.MoonTextureId
                end
            end
        elseif sea == 2 then
            local fantasySky = Lighting:FindFirstChild("FantasySky")
            if fantasySky and fantasySky.MoonTextureId and fantasySky.MoonTextureId ~= "" then
                tex = fantasySky.MoonTextureId
            end
        end
    end)
    -- Fallback: scan tất cả Sky trong Lighting
    if tex == "" then
        pcall(function()
            for _, child in pairs(Lighting:GetChildren()) do
                if child:IsA("Sky") then
                    local mt = child.MoonTextureId
                    if mt and type(mt) == "string" and mt ~= "" then
                        tex = mt
                        break
                    end
                end
            end
        end)
    end
    if tex == "" then
        return "Normal Moon"
    end
    tex = tostring(tex):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    local moonTable = {
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
        ["http://www.roblox.com/asset/?id=9709149431"]  = "Full Moon (8/8)",
        ["http://www.roblox.com/asset/?id=9709149052"]  = "Near Full (7/8)",
    }
    return moonTable[tex] or "Normal Moon"
end

-- ====================== MOON TIMER ======================
local function mmbs(inp, c2)
    local ps = inp - c2
    if ps > 1 then
        return math.floor(ps) .. " Minutes"
    else
        return math.floor(math.max(0, ps * 60)) .. " Seconds"
    end
end

local function GetMoonTimer()
    local c2 = Lighting.ClockTime
    local moon = GetMoonStatus()

    if moon == "Full Moon (8/8)" then
        if c2 <= 5 then
            return "🌕 8/8 ACTIVE — End in " .. mmbs(5, c2)
        elseif c2 > 5 and c2 < 12 then
            return "🌕 8/8 Fake (daytime) — Real in " .. mmbs(18, c2)
        elseif c2 >= 12 and c2 < 18 then
            return "🌕 8/8 Waiting night — Full in " .. mmbs(18, c2)
        else
            return "🌕 8/8 ACTIVE — End in " .. mmbs(30, c2)
        end
    elseif moon == "Near Full (7/8)" then
        if c2 < 18 then
            return "🌖 7/8 — Night in " .. mmbs(18, c2)
        else
            return "🌖 7/8 — Night NOW"
        end
    elseif moon == "Blue Moon" then
        if c2 >= 18 or c2 < 5 then
            return "🔵 Blue Moon ACTIVE"
        else
            return "🔵 Blue Moon — Night in " .. mmbs(18, c2)
        end
    end
    return "❌ Normal Moon"
end

local function GetFullTimerDisplay()
    local c2 = Lighting.ClockTime
    local moon = GetMoonStatus()
    local lines = {}
    table.insert(lines, "Moon: " .. moon .. " | Clock: " .. string.format("%.1f", c2))
    if c2 >= 5 and c2 < 18 then
        table.insert(lines, "🌙 Night in " .. mmbs(18, c2))
    else
        table.insert(lines, "🌙 Night NOW — End in " .. (c2 < 5 and mmbs(5, c2) or mmbs(30, c2)))
    end
    table.insert(lines, GetMoonTimer())
    local isNight = (c2 >= 18 or c2 < 5)
    local isFullMoon = (moon == "Full Moon (8/8)" or moon == "Blue Moon")
    if isFullMoon and isNight then
        table.insert(lines, "🎸 SOUL GUITAR: ✅ GO NOW!")
    elseif isFullMoon and not isNight then
        table.insert(lines, "🎸 SOUL GUITAR: ⏳ Wait for night...")
    elseif moon == "Near Full (7/8)" then
        table.insert(lines, "🎸 SOUL GUITAR: 🟡 Almost — need 8/8")
    else
        table.insert(lines, "🎸 SOUL GUITAR: ❌ Need Full Moon")
    end
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

    -- JSON data để MoonTeleporter_Reader parse
    local jsonData = {
        player  = LocalPlayer.Name,
        jobId   = game.JobId,
        placeId = tostring(game.PlaceId),
        sea     = tostring(GetCurrentSea()),
        moon    = moonName,
        clock   = string.format("%.1f", Lighting.ClockTime),
        ready   = (moonName == "Full Moon (8/8)" or moonName == "Blue Moon") and (Lighting.ClockTime >= 18 or Lighting.ClockTime < 5),
        timer   = GetMoonTimer(),
        players = tostring(#Players:GetPlayers()),
        time    = tostring(os.time()),
    }

    local data = {
        content = "```json\n" .. HttpService:JSONEncode(jsonData) .. "\n```",
        username = LocalPlayer.Name,
        embeds = {{
            title = "🌙 MOON STATUS UPDATE",
            description = "Tự động báo cáo mặt trăng + thời gian",
            color = 0x00ffff,
            fields = {
                {name = "Trạng thái",  value = "```" .. moonName .. "```",            inline = true},
                {name = "Sea",         value = "```Sea " .. GetCurrentSea() .. "```", inline = true},
                {name = "Place ID",    value = "```" .. game.PlaceId .. "```",        inline = true},
                {name = "Người chơi",  value = "```" .. GetPlayerCount() .. "```",    inline = true},
                {name = "Moon Timer",  value = "```" .. GetMoonTimer() .. "```",      inline = false},
                {name = "JobID",       value = "```" .. game.JobId .. "```"},
                {name = "Mã Teleport", value = "```lua\n" .. teleportCode .. "\n```"}
            },
            footer = {text = "Nhai System • " .. os.date("%X")}
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
        print("[Sender] ✅ Discord:", moonName, "|", GetMoonTimer())
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
        local c2 = Lighting.ClockTime
        local isGoodMoon = false

        -- ★ FIX: Bỏ "and isNight" → gửi ngay khi detect moon tốt
        -- Clock 15.8 + Full Moon (8/8) → GỬI LUÔN (trước đây bị skip)
        if moonStatus == "Full Moon (8/8)" then
            isGoodMoon = true
        elseif moonStatus == "Near Full (7/8)" then
            isGoodMoon = true
        elseif moonStatus == "Blue Moon" then
            isGoodMoon = true
        end

        -- Hiện đầy đủ trạng thái
        print("───────────────────────────────────────────")
        print("[" .. os.date("%H:%M:%S") .. "]")
        print(GetFullTimerDisplay())

        if isGoodMoon then
            print("📤 GỬI Discord + Firebase!")
            SendToDiscord(moonStatus)
            SendToFirebase(moonStatus)
        else
            print("❌ Normal Moon — Không gửi")
        end
        print("───────────────────────────────────────────")

        task.wait(60)
    end
end)

print("[Nhai System] ✅ Script đã fix — Gửi ngay khi detect 8/8, 7/8, Blue Moon!")
