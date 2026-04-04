local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonChecker"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainText = Instance.new("TextLabel")
MainText.Parent = ScreenGui
MainText.Size = UDim2.new(0, 420, 0, 120)
MainText.Position = UDim2.new(0, 20, 0, 20)
MainText.BackgroundTransparency = 1
MainText.TextColor3 = Color3.fromRGB(255,255,255)
MainText.TextStrokeTransparency = 0
MainText.TextScaled = true
MainText.Font = Enum.Font.SourceSansBold
MainText.Text = "Loading Moon Checker..."

-- ====================== FUNCTIONS ======================
function getServerTime()
    local c2 = Lighting.ClockTime
    local minute = math.floor(c2)
    local second = math.floor((c2 - minute) * 60)
    return minute, second
end

function MoonTextureId()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky and sky.MoonTextureId then
        return sky.MoonTextureId
    end
    return ""
end

-- ====================== CHECK MOON (CHỈ FULL + BLUE) ======================
function CheckMoon()
    local tex = MoonTextureId()
    local moon5 = "http://www.roblox.com/asset/?id=9709149431"  -- Full Moon 8/8
    local moonBlue = "http://www.roblox.com/asset/?id=15493317929" -- Blue Moon

    if tex == moon5 then
        return "Full Moon"
    elseif tex == moonBlue then
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

-- ====================== STATUS (CHỈ FULL IN + END IN) ======================
function GetMoonStatus()
    local c2 = Lighting.ClockTime
    local moon = CheckMoon()

    if moon == "Full Moon" then
        if c2 <= 5 then
            return tostring(math.floor(c2)) .. " (End in " .. mmbs(5, c2) .. ")"
        elseif c2 > 5 and c2 < 12 then
            return tostring(math.floor(c2)) .. " (Fake Moon)"
        elseif c2 >= 12 and c2 < 18 then
            return tostring(math.floor(c2)) .. " (Full in " .. mmbs(18, c2) .. ")"
        else
            return tostring(math.floor(c2)) .. " (End in " .. mmbs(30, c2) .. ")"
        end
    elseif moon == "Blue Moon" then
        return "🔵 Blue Moon Active"
    end
    return "❌ Normal Moon"
end

-- ====================== MAIN LOOP ======================
task.spawn(function()
    while true do
        local h, s = getServerTime()
        local moon = CheckMoon()
        local status = GetMoonStatus()

        -- GUI Text
        MainText.Text = 
            "🕒 Time: " .. h .. ":" .. string.format("%02d", s) .. "\n" ..
            "🌙 Moon: " .. moon .. "\n" ..
            "📌 Status: " .. status

        -- Màu sắc
        if moon == "Full Moon" then
            MainText.TextColor3 = Color3.fromRGB(0, 255, 127)
        elseif moon == "Blue Moon" then
            MainText.TextColor3 = Color3.fromRGB(0, 170, 255)
        else
            MainText.TextColor3 = Color3.fromRGB(255, 80, 80)
        end

        -- Console print đẹp (dễ nhìn)
        print("══════════════════════════════════════")
        print("🕒 Time : " .. h .. ":" .. string.format("%02d", s))
        print("🌙 Moon : " .. moon)
        print("📌 Status: " .. status)
        print("══════════════════════════════════════")

        task.wait(1)
    end
end)

print("[MoonChecker] GUI đã khởi động - Chỉ hiển thị Full Moon + Blue Moon")
