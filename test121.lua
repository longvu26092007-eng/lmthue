repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function() return game:GetService(name) end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name))
    end
end})

HttpService = Services.HttpService
TeleportService = Services.TeleportService
Players = Services.Players
LocalPlayer = Players.LocalPlayer

local BOT_TOKEN = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"
local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

if not req then return end

local options = {Url = "https://roproxy.com/api/v10/channels/"..CHANNEL_ID.."/messages?limit=20", Method = "GET", Headers = {["Authorization"] = "Bot "..BOT_TOKEN, ["Content-Type"] = "application/json"}}

task.spawn(function()
    while task.wait(10) do
        xpcall(function()
            local ok, resp = pcall(function() return req(options) end)
            if not ok or not resp or not resp.Body then return end
            
            local body = resp.Body
            if type(body) == "string" and body:sub(1,1) ~= "[" and body:sub(1,1) ~= "{" then return end
            
            local s, messages = pcall(function() return HttpService:JSONDecode(body) end)
            if not s or type(messages) ~= "table" or #messages == 0 then return end
            
            local bestServer = nil
            for i = 1, #messages do
                local msg = messages[i]
                local jsonStr = msg.content and msg.content:match("```json%s*(.-)%s*```")
                
                if jsonStr then
                    local s2, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
                    if s2 and data and data.jobId then bestServer = data break end
                end
                
                if not bestServer and msg.embeds and msg.embeds[1] and msg.embeds[1].fields then
                    local fields = msg.embeds[1].fields
                    local jId = nil
                    for f = 1, #fields do
                        local field = fields[f]
                        if field.name:find("JobID") then jId = field.value:match("[%w%-]+")
                        elseif field.name:find("Teleport") then jId = jId or field.value:match("'([%w%-]+)'") end
                    end
                    if jId then bestServer = {jobId = jId, placeId = game.PlaceId} break end
                end
            end
            
            if bestServer and bestServer.jobId and bestServer.jobId ~= game.JobId then
                pcall(function() TeleportService:TeleportToPlaceInstance(tonumber(bestServer.placeId) or game.PlaceId, bestServer.jobId, LocalPlayer) end)
            end
        end, function(err) 
            -- Bỏ qua in lỗi ra màn hình giống script SG
        end)
    end
end)
