-- ══════════════════════════════════════════
-- DEBUG RACE DATA - Chạy script này để xem
-- Data.Race được lưu như thế nào
-- ══════════════════════════════════════════
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
repeat task.wait(0.5) until game.Players.LocalPlayer:FindFirstChild("Data")

local plr = game.Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")

local function Inspect(obj, indent)
    indent = indent or ""
    if not obj then return end
    local className = obj.ClassName or "?"
    local val = ""
    pcall(function()
        val = " = " .. tostring(obj.Value)
    end)
    print(indent .. "[" .. className .. "] " .. obj.Name .. val)
    for _, child in ipairs(obj:GetChildren()) do
        Inspect(child, indent .. "  ")
    end
end

print("══ Data.Race structure ══")
Inspect(plr.Data.Race)

print("\n══ Race Attributes ══")
pcall(function()
    for k, v in pairs(plr:GetAttributes()) do
        if tostring(k):lower():find("race") then
            print("plr attr:", k, "=", v)
        end
    end
end)

pcall(function()
    local char = plr.Character
    if char then
        for k, v in pairs(char:GetAttributes()) do
            if tostring(k):lower():find("race") then
                print("char attr:", k, "=", v)
            end
        end
    end
end)

print("\n══ CollectionService tags on char ══")
pcall(function()
    local char = plr.Character
    if char then
        local tags = CollectionService:GetTags(char)
        print("char tags:", table.concat(tags, ", "))
    end
end)

pcall(function()
    local tags = CollectionService:GetTags(plr)
    print("plr tags:", table.concat(tags, ", "))
end)

print("\n══ Character children (Race-related) ══")
pcall(function()
    local char = plr.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if tostring(v.Name):lower():find("race")
            or tostring(v.Name):lower():find("evolved")
            or tostring(v.Name):lower():find("transform")
            then
                print("char child:", v.ClassName, v.Name)
            end
        end
    end
end)

print("══ DEBUG DONE ══")
