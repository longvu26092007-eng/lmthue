--[[
    Script: Moon Status Notifier (Auto-check 1 min + Player Count)
    Author: Nhai (Vũ) - FPT University
    Description: Tự động check Moon mỗi 60s, báo số lượng player, không gửi trùng server cũ.
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1489793523061493971/aJXQs_TwLw1e9WIHqhb-XGbI8EY2zxPUrjV64cOKNgTKMYYqniuJWBRz0Fsk9QitcRXj"
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Khởi tạo bảng lưu trữ các JobId đã gửi để chống trùng lặp
if not getgenv().SentJobs then
    getgenv().SentJobs = {}
end

-- Function lấy Sea
function GetCurrentSea()
    local mapAttr = workspace:GetAttribute("MAP")
    return mapAttr and tonumber(mapAttr:match("%d+")) or 0
end

-- Function lấy số lượng người chơi (Hiển thị dạng Hiện tại/Tối đa)
function GetPlayerCount()
    return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
end

-- Function kiểm tra mặt trăng (Logic chuẩn từ source của bạn)
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
            ["title"] = "🌙 **MOON STATUS ALERT**",
            ["description"] = "Hệ thống đã phát hiện server có trăng tốt!",
            ["color"] = 0x00ff00, -- Màu xanh lá
            ["fields"] = {
                {["name"] = "Trạng thái", ["value"] = "```" .. moonName .. "```", ["inline"] = true},
                {["name"] = "Sea", ["value"] = "```" .. GetCurrentSea() .. "```", ["inline"] = true},
                {["name"] = "Người chơi", ["value"] = "```" .. GetPlayerCount() .. "```", ["inline"] = true},
                {["name"] = "JobID", ["value"] = "```" .. game.JobId .. "```"},
                {["name"] = "Mã Teleport nhanh (Copy vào Executor)", ["value"] = "```lua\n" .. teleportCode .. "\n```"}
            },
            ["footer"] = {["text"] = "Nhai System Monitoring • " .. os.date("%X")}
        }}
    }

    local requestFunc = (syn and syn.request or http_request or request or HttpService.request)
    if requestFunc then
        local success, err = pcall(function()
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if success then
            getgenv().SentJobs[game.JobId] = true
            warn("[Nhai System] Đã gửi dữ liệu server " .. game.JobId .. " lên Discord!")
        else
            warn("[Nhai System] Lỗi khi gửi Webhook: " .. tostring(err))
        end
    end
end

-- Vòng lặp tự động check mỗi 60 giây
task.spawn(function()
    warn("[Nhai System] Bắt đầu tự động kiểm tra Mặt trăng mỗi 1 phút...")
    
    while true do
        local moonStatus = GetMoonStatus()
        
        -- Điều kiện gửi: 
        -- 1. Trăng là Full, Blue hoặc 7/8
        -- 2. Server này (JobId) chưa được gửi trong phiên làm việc này
        local isGoodMoon = (moonStatus == "Full Moon (8/8)" or moonStatus == "Blue Moon" or moonStatus == "Near Full (7/8)")
        local isAlreadySent = getgenv().SentJobs[game.JobId]

        if isGoodMoon then
            if not isAlreadySent then
                SendToDiscord(moonStatus)
            else
                print("[Nhai System] Server này đã gửi thông báo rồi, đang chờ trăng lặn hoặc đổi server.")
            end
        else
            print("[Nhai System] Moon hiện tại: " .. moonStatus .. " (Chưa đạt yêu cầu gửi)")
        end
        
        task.wait(60) -- Chờ đúng 1 phút để check lại
    end
end)
