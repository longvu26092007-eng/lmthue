--[[
    Script: Moon Status Notifier v2 (Fixed Fake Moon)
    Author: Grok + Nhai (Vũ) — Refactored
    Fix: Phân biệt Fake Moon, chuẩn timer, chỉ gửi Real Full Moon / Blue Moon ở Sea 3
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"

-- ★ Đợi game load
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(5)

local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local req = http_request or request or (syn and syn.request) or (http and http.request) or fluxus_request
if not req then
    warn("[MoonScan] ❌ Executor không hỗ trợ HTTP request!")
    return
end

-- ====================== SEA CHECK ======================
local SEA_3_IDS = {
    ["7449423635"] = true,
    ["100117331123089"] = true
}

function IsSea3()
    return SEA_3_IDS[tostring(game.PlaceId)] == true
end

function GetCurrentSea()
    local placeId = game.PlaceId
    local sea1 = {[2753915549] = true, [85211729168715] = true}
    local sea2 = {[4442272183] = true, [79091703265657] = true}
    local sea3 = {[7449423635] = true, [100117331123089] = true}

    if sea1[placeId] then return 1
    elseif sea2[placeId] then return 2
    elseif sea3[placeId] then return 3
    else return 0 end
end

function GetPlayerCount()
    return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
end

-- ====================== MOON TEXTURE CHECK ======================
-- Lấy MoonTextureId từ Skybox tùy theo Sea
function GetMoonTextureId()
    local tex = ""
    local sea = GetCurrentSea()
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
    return tex
end

-- ====================== MOON CLASSIFICATION ======================
--[[
    Bảng phân loại Moon dựa trên texture + ClockTime:

    ┌──────────────────┬───────────────┬─────────────────────────────────────┐
    │ Texture          │ ClockTime     │ Kết quả                            │
    ├──────────────────┼───────────────┼─────────────────────────────────────┤
    │ 9709149431 (8/8) │ 18–24 hoặc 0–5│ ✅ Real Full Moon (đêm, moon thật) │
    │ 9709149431 (8/8) │ 5–12          │ ❌ Fake Moon (sáng, moon giả)      │
    │ 9709149431 (8/8) │ 12–18         │ ⏳ Full Moon Coming (chiều, sắp tối)│
    │ 9709149052 (7/8) │ bất kỳ        │ 🔶 Next Night (đêm sau sẽ full)   │
    │ 15493317929      │ bất kỳ        │ 🔵 Blue Moon                      │
    │ khác / rỗng      │ bất kỳ        │ ⚪ Normal Moon                     │
    └──────────────────┴───────────────┴─────────────────────────────────────┘

    CHỈ GỬI WEBHOOK + FIREBASE KHI:
    - Real Full Moon (texture 8/8 + đêm thật: ClockTime >= 18 hoặc < 5)
    - Blue Moon (bất kỳ lúc nào)
    - Next Night 7/8 (gửi kèm timer đến Full Moon để chuẩn bị)
]]

local MOON_TEXTURES = {
    FULL_8 = "http://www.roblox.com/asset/?id=9709149431",      -- Full Moon 8/8
    NEAR_7 = "http://www.roblox.com/asset/?id=9709149052",      -- Near Full 7/8
    BLUE   = "http://www.roblox.com/asset/?id=15493317929",      -- Blue Moon
}

function ClassifyMoon()
    local tex = GetMoonTextureId()
    local c2 = Lighting.ClockTime

    -- Chuẩn hóa texture (rbxassetid → http format)
    tex = tostring(tex):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")

    -- Blue Moon — luôn là thật, không phụ thuộc ClockTime
    if tex == MOON_TEXTURES.BLUE then
        return {
            type = "Blue Moon",
            real = true,          -- Gửi webhook
            emoji = "🔵",
            color = 0x00BFFF,
        }
    end

    -- Full Moon 8/8 — cần kiểm tra Fake
    if tex == MOON_TEXTURES.FULL_8 then
        -- Đêm thật: 18h → 24h → 0h → 5h
        if c2 >= 18 or c2 < 5 then
            return {
                type = "Real Full Moon (8/8)",
                real = true,      -- ✅ Gửi webhook
                emoji = "🌕",
                color = 0x00FF7F,
            }
        end

        -- Sáng: 5h → 12h — FAKE MOON
        if c2 >= 5 and c2 < 12 then
            return {
                type = "Fake Moon (8/8)",
                real = false,     -- ❌ Không gửi
                emoji = "🚫",
                color = 0xFF5555,
            }
        end

        -- Chiều: 12h → 18h — Moon sắp full (đêm nay sẽ full)
        if c2 >= 12 and c2 < 18 then
            return {
                type = "Full Moon Coming (8/8)",
                real = false,     -- ❌ Chưa gửi, đợi tối
                emoji = "⏳",
                color = 0xFFAA00,
            }
        end
    end

    -- Near Full 7/8 — đêm sau sẽ full, GỬI để chuẩn bị
    if tex == MOON_TEXTURES.NEAR_7 then
        -- Tính thời gian còn lại đến Full Moon (dựa theo checktimemoon.txt)
        local timeLeft
        if c2 < 12 then
            -- Sáng sớm: Full Moon tối nay lúc 18h
            timeLeft = math.floor(18 - c2) .. " Minutes"
        else
            -- Chiều/tối: Full Moon tối MAI lúc 18h (18 + 24 = 42)
            timeLeft = math.floor(42 - c2) .. " Minutes"
        end

        return {
            type = "Next Night (7/8)",
            real = true,          -- ✅ GỬI webhook để chuẩn bị
            emoji = "🌖",
            color = 0xFFAA00,
            timeToFull = timeLeft,
        }
    end

    -- Không khớp texture nào → Normal
    return {
        type = "Normal Moon",
        real = false,
        emoji = "⚪",
        color = 0x888888,
    }
end

-- ====================== TIME FUNCTIONS ======================
-- Lấy giờ:phút trong game (format đẹp)
function GetServerTime()
    local c2 = Lighting.ClockTime
    local hour = math.floor(c2)
    local minute = math.floor((c2 - hour) * 60)
    return hour, minute
end

-- Ngày hay đêm
function GetDayNight()
    local c2 = Lighting.ClockTime
    if c2 >= 18 or c2 < 5 then
        return "🌙 Night"
    else
        return "☀️ Day"
    end
end

-- Tính thời gian còn lại (phút hoặc giây)
function FormatTimeLeft(target, current)
    local diff = target - current
    if diff < 0 then diff = diff + 24 end  -- wrap qua ngày mới
    if diff > 1 then
        return math.floor(diff) .. " Minutes"
    else
        return math.floor(diff * 60) .. " Seconds"
    end
end

-- ====================== MOON TIMER (CHI TIẾT) ======================
function GetMoonTimer()
    local c2 = Lighting.ClockTime
    local moon = ClassifyMoon()

    -- Blue Moon: không có timer cụ thể
    if moon.type == "Blue Moon" then
        return "🔵 Blue Moon — Active!"
    end

    -- Real Full Moon (đêm, 18h–5h)
    if moon.type == "Real Full Moon (8/8)" then
        if c2 >= 18 then
            -- 18h → 24h: tính đến khi hết đêm (5h sáng = 29h tính từ 0)
            return "🌕 Full Moon — End in " .. FormatTimeLeft(29, c2)
        else
            -- 0h → 5h: tính đến 5h
            return "🌕 Full Moon — End in " .. FormatTimeLeft(5, c2)
        end
    end

    -- Fake Moon (sáng, 5h–12h)
    if moon.type == "Fake Moon (8/8)" then
        return "🚫 Fake Moon — Ignore (Day time)"
    end

    -- Full Moon Coming (chiều, 12h–18h)
    if moon.type == "Full Moon Coming (8/8)" then
        return "⏳ Full Moon in " .. FormatTimeLeft(18, c2)
    end

    -- Next Night 7/8 — gửi kèm timer đến Full Moon
    if moon.type == "Next Night (7/8)" then
        -- Logic từ checktimemoon.txt:
        -- c2 < 12  → Full Moon tối nay lúc 18h  → mmbs(18, c2)
        -- c2 >= 12 → Full Moon tối mai lúc 18h  → mmbs(42, c2)
        if c2 < 12 then
            return "🌖 Next Night — Full Moon in " .. FormatTimeLeft(18, c2) .. " (tonight)"
        else
            local diff = 42 - c2
            local mins = math.floor(diff)
            return "🌖 Next Night — Full Moon in " .. mins .. " Minutes (tomorrow night)"
        end
    end

    -- Normal Moon
    return "⚪ Normal Moon"
end

-- ====================== FULL DISPLAY ======================
function GetFullTimerDisplay()
    local h, m = GetServerTime()
    local moon = ClassifyMoon()
    local daynight = GetDayNight()

    local lines = {
        moon.emoji .. " Moon: " .. moon.type,
        "🕐 Time: " .. string.format("%02d:%02d", h, m) .. " (" .. daynight .. ")",
        "📊 " .. GetMoonTimer(),
        "🌊 Sea: " .. GetCurrentSea() .. " | 👥 " .. GetPlayerCount(),
    }

    if moon.real then
        table.insert(lines, "✅ SẼ GỬI WEBHOOK (Moon thật)")
    else
        table.insert(lines, "❌ KHÔNG GỬI (Moon giả / thường)")
    end

    return table.concat(lines, "\n")
end

-- ====================== SEND FUNCTIONS ======================
function SendToFirebase(moonData)
    local dbData = {
        jobId = game.JobId,
        placeId = game.PlaceId,
        moon = moonData.type,
        sea = GetCurrentSea(),
        time = os.time(),
        playerCount = GetPlayerCount(),
        moonTimer = GetMoonTimer(),
        isRealMoon = true,
        timeToFull = moonData.timeToFull or nil,  -- Thời gian đến Full Moon (nếu 7/8)
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
        print("[Sender] ✅ Firebase:", moonData.type)
    else
        warn("[Sender] ❌ Firebase error:", err)
    end
end

function SendToDiscord(moonData)
    local teleportCode = string.format(
        "game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)",
        game.PlaceId, game.JobId
    )

    local fields = {
        {["name"] = "Trạng thái",    ["value"] = "```" .. moonData.type .. "```",        ["inline"] = true},
        {["name"] = "Sea",            ["value"] = "```Sea " .. GetCurrentSea() .. "```", ["inline"] = true},
        {["name"] = "Người chơi",     ["value"] = "```" .. GetPlayerCount() .. "```",    ["inline"] = true},
        {["name"] = "Moon Timer",     ["value"] = "```" .. GetMoonTimer() .. "```",      ["inline"] = false},
    }

    -- Thêm field "Thời gian đến Full Moon" nếu là 7/8
    if moonData.timeToFull then
        table.insert(fields, {
            ["name"] = "⏰ Full Moon sau",
            ["value"] = "```" .. moonData.timeToFull .. "```",
            ["inline"] = true,
        })
    end

    table.insert(fields, {["name"] = "Game Time",   ["value"] = "```" .. string.format("%02d:%02d", GetServerTime()) .. " (" .. GetDayNight() .. ")" .. "```", ["inline"] = true})
    table.insert(fields, {["name"] = "Place ID",    ["value"] = "```" .. game.PlaceId .. "```",        ["inline"] = true})
    table.insert(fields, {["name"] = "Job ID",      ["value"] = "```" .. game.JobId .. "```",          ["inline"] = false})
    table.insert(fields, {["name"] = "Mã Teleport", ["value"] = "```lua\n" .. teleportCode .. "\n```",  ["inline"] = false})

    local data = {
        ["embeds"] = {{
            ["title"] = moonData.emoji .. " MOON DETECTED — " .. moonData.type,
            ["description"] = moonData.timeToFull
                and ("⏰ Full Moon trong **" .. moonData.timeToFull .. "** — chuẩn bị sẵn!")
                or "Tự động phát hiện mặt trăng thật + thời gian chính xác",
            ["color"] = moonData.color,
            ["fields"] = fields,
            ["footer"] = {["text"] = "Nhai System v2 • " .. os.date("%X") .. " • Fake Moon Filter ON"}
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
        print("[Sender] ✅ Discord:", moonData.type)
    else
        warn("[Sender] ❌ Discord error:", err)
    end
end

-- ====================== MAIN LOOP ======================
print("═══════════════════════════════════════════")
print("[MoonScan v2] 🌕 Script STARTED!")
print("[MoonScan v2] Fake Moon Filter: ON")
print("───────────────────────────────────────────")
print(GetFullTimerDisplay())
print("═══════════════════════════════════════════")

task.spawn(function()
    while true do
        local moonData = ClassifyMoon()
        local isSea3 = IsSea3()
        local h, m = GetServerTime()

        -- Log mỗi lần scan
        print(string.format(
            "[%s] Scan | %s %s | Time: %02d:%02d | Sea3: %s | Send: %s",
            os.date("%H:%M:%S"),
            moonData.emoji,
            moonData.type,
            h, m,
            tostring(isSea3),
            tostring(moonData.real and isSea3)
        ))

        -- ★ CHỈ GỬI KHI:
        --   1. Moon thật (Real Full Moon hoặc Blue Moon)  → moonData.real == true
        --   2. Đang ở Sea 3                                → isSea3 == true
        --   → Fake Moon, Full Moon Coming, 7/8, Normal    → KHÔNG GỬI
        if moonData.real and isSea3 then
            print("📤 GỬI Discord + Firebase! (" .. moonData.type .. " tại Sea 3)")
            SendToDiscord(moonData)
            SendToFirebase(moonData)
        end

        task.wait(60)
    end
end)

print("[Nhai System v2] ✅ Script chạy ổn định — Fake Moon sẽ bị bỏ qua!")
