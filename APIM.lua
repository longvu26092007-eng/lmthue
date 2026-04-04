local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonChecker"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainText = Instance.new("TextLabel")
MainText.Parent = ScreenGui
MainText.Size = UDim2.new(0, 400, 0, 100)
MainText.Position = UDim2.new(0, 20, 0, 20)
MainText.BackgroundTransparency = 1
MainText.TextColor3 = Color3.fromRGB(255,255,255)
MainText.TextStrokeTransparency = 0
MainText.TextScaled = true
MainText.Font = Enum.Font.SourceSansBold
MainText.Text = "Loading..."

function function7()
    local GameTime = "Error"
    local c2 = Lighting.ClockTime
    if c2 >= 18 or c2 < 5 then
        GameTime = "Night"
    else
        GameTime = "Day"
    end
    return GameTime
end

function function6()
    return math.floor(Lighting.ClockTime)
end

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

-- ====================== SỬA CHECK MOON ======================
function CheckMoon()
    local moon5 = "http://www.roblox.com/asset/?id=9709149431"  -- Full Moon 8/8
    local moon4 = "http://www.roblox.com/asset/?id=9709149052"  -- Near Full 7/8
    local moonreal = MoonTextureId()
    local c2 = Lighting.ClockTime
    local isNight = (c2 >= 18 or c2 < 5)

    if moonreal == moon5 then
        if isNight then
            return "Full Moon"      -- Full Moon thật (đêm)
        else
            return "Next Night"     -- Ban ngày → coi như sắp Full Moon (7/8)
        end
    elseif moonreal == moon4 then
        return "Next Night"
    end
    return "Bad Moon"
end

function mmbs(inp, c2)
    local ps = inp - c2
    if ps > 1 then
        return math.floor(ps) .. " Minutes"
    else
        return math.floor(ps * 60) .. " Seconds"
    end
end

function function8()
    local c2 = Lighting.ClockTime
    local moon = CheckMoon()

    if moon == "Full Moon" then
        if c2 <= 5 then
            return tostring(function6()).." (End in "..mmbs(5,c2)..")"
        elseif c2 > 5 and c2 < 12 then
            return tostring(function6()).." (Fake Moon)"
        elseif c2 > 12 and c2 < 18 then
            return tostring(function6()).." (Full in "..mmbs(18,c2)..")"
        elseif c2 > 18 then
            return tostring(function6()).." (End in "..mmbs(30,c2)..")"
        end
    elseif moon == "Next Night" then
        if c2 < 18 then
            return tostring(function6()).." (Full in "..mmbs(18,c2)..")"
        else
            return tostring(function6()).." (Full in "..mmbs(18+24,c2)..")"
        end
    end
    return tostring(function6())
end

task.spawn(function()
    while true do
        local h, s = getServerTime()
        local moon = CheckMoon()
        local status = function8()

        MainText.Text =
            "Time: "..h..":"..string.format("%02d", s)..
            "\nMoon: "..moon..
            "\nStatus: "..status

        if moon == "Full Moon" then
            MainText.TextColor3 = Color3.fromRGB(0,255,127)
        elseif moon == "Next Night" then
            MainText.TextColor3 = Color3.fromRGB(255,170,0)
        else
            MainText.TextColor3 = Color3.fromRGB(255,80,80)
        end

        task.wait(1)
    end
end)
