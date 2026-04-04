--[[
    Script check Moon Status & Discord Webhook 
    Thiết lập bởi Nhai (Vũ) - FPT University Student
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

-- Function check Sea (dựa theo source cũ của bạn)
function CheckSea()
    local mapAttr = workspace:GetAttribute("MAP")
    return mapAttr and tonumber(mapAttr:match("%d+")) or 0
end

-- Function lấy trạng thái mặt trăng (Logic từ source Soul Guitar của bạn)
function GetMoonStatus()
    local sea = CheckSea()
    local tex = ""
    
    pcall(function()
        if sea == 1 or sea == 3 then
            tex = (Lighting:FindFirstChild("Sky") and Lighting.Sky.MoonTextureId) 
                  or (Lighting:FindFirstChild("Space_Skybox") and Lighting.Space_Skybox.MoonTextureId)
        elseif sea == 2 then
            tex = (Lighting:FindFirstChild("FantasySky") and Lighting.FantasySky.MoonTextureId)
        end
    end)
    
    tex = tostring(tex):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    
    local moonTable = {
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
        ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon (8/8)",
        ["http://www.roblox.com/asset/?id=9709149052"] = "Near Full (7/8)",
        ["http://www.roblox.com/asset/?id=9709143733"] = "6/8",
        ["http://www.roblox.com/asset/?id=9709150401"] = "5/8"
    }
    
    return moonTable[tex] or "Unknown"
end

-- Tạo đoạn mã Teleport nhanh để copy
local teleportCode = string.format(
    "game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)",
    game.PlaceId, game.JobId
)

local currentMoon = GetMoonStatus()

-- CHỈ GỬI NẾU: Full Moon, Blue Moon hoặc 7/8 (Sắp Full)
if currentMoon == "Full Moon (8/8)" or currentMoon == "Blue Moon" or currentMoon == "Near Full (7/8)" then
    
    local data = {
        ["embeds"] = {{
            ["title"] = "🌙 **MOON STATUS DETECTED**",
            ["description"] = "Đã tìm thấy server có điều kiện làm Soul Guitar!",
            ["color"] = 65280, -- Màu xanh lá
            ["fields"] = {
                {["name"] = "Trạng thái", ["value"] = "```" .. currentMoon .. "```", ["inline"] = true},
                {["name"] = "Sea", ["value"] = "```" .. CheckSea() .. "```", ["inline"] = true},
                {["name"] = "JobID", ["value"] = "```" .. game.JobId .. "```"},
                {["name"] = "Mã Teleport (Copy & Paste vào Executor)", ["value"] = "```lua\n" .. teleportCode .. "\n```"}
            },
            ["footer"] = {["text"] = "Check bởi Nhai System • " .. os.date("%X")}
        }}
    }

    -- Gửi lên Discord
    local response = (syn and syn.request or http_request or request or HttpService.request) {
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    }
    
    print("Đã gửi thông tin Moon sang Discord!")
else
    print("Mặt trăng hiện tại: " .. currentMoon .. " (Không đủ điều kiện gửi)")
end
