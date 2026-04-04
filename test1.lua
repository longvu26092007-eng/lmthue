--[[
    Script: Moon Status Notifier (Lặp lại mỗi 1 phút - Không chống trùng)
    Author: Nhai (Vũ) - FPT University
    Description: Tự động check và gửi báo cáo mỗi 60s nếu đủ điều kiện Moon.
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Function lấy Sea
function GetCurrentSea()
    local mapAttr = workspace:GetAttribute("MAP")
    return mapAttr and tonumber(mapAttr:match("%d+")) or 0
end

-- Function lấy số lượng người chơi
function GetPlayerCount()
    return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
end

-- Function kiểm tra mặt trăng
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
    
    tex = tostring(tex):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    
    local moonTable = {
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
        ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon (8/8)",
        ["http://www.roblox.com/asset/?id=9709149052"] = "Near Full (7/8)",
    }
    
    return moonTable[tex] or "Normal Moon"
end

-- Function gửi Webhook
function SendToDiscord(moonName)
    local teleportCode = string.format(
        "game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)",
        game.PlaceId, game.JobId
    )

    local data = {
        ["embeds"] = {{
            ["title"] = "🌙 **MOON STATUS UPDATE**",
            ["description"] = "Cập nhật trạng thái mặt trăng hiện tại!",
            ["color"] = 0x00ffff, -- Màu xanh cyan
            ["fields"] = {
                {["name"] = "Trạng thái", ["value"] = "```" .. moonName .. "```", ["inline"] = true},
                {["name"] = "Sea", ["value"] = "```" .. GetCurrentSea() .. "```", ["inline"] = true},
                {["name"] = "Người chơi", ["value"] = "```" .. GetPlayerCount() .. "```", ["inline"] = true},
                {["name"] = "JobID", ["value"] = "```" .. game.JobId .. "```"},
                {["name"] = "Mã Teleport nhanh", ["value"] = "```lua\n" .. teleportCode .. "\n```"}
            },
            ["footer"] = {["text"] = "Nhai System - Auto Report • " .. os.date("%X")}
        }}
    }

    local requestFunc = (syn and syn.request or http_request or request or HttpService.request)
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
    end
end

-- Vòng lặp tự động báo mỗi 60 giây (Bỏ qua trùng lặp)
task.spawn(function()
    warn("[Nhai System] Bắt đầu tự động báo Moon mỗi 1 phút (Spam mode)...")
    
    while true do
        local moonStatus = GetMoonStatus()
        
        -- Điều kiện gửi: Chỉ gửi khi trăng tốt (Full, Blue, 7/8)
        local isGoodMoon = (moonStatus == "Full Moon (8/8)" or moonStatus == "Blue Moon" or moonStatus == "Near Full (7/8)")

        if isGoodMoon then
            SendToDiscord(moonStatus)
            print("[Nhai System] Đã gửi báo cáo định kỳ cho server này.")
        else
            print("[Nhai System] Moon hiện tại: " .. moonStatus .. " (Không báo cáo)")
        end
        
        task.wait(60) -- Đúng 1 phút báo 1 lần
    end
end)
