local BOT_TOKEN = "MTQ4OTc5MTQyMzQ5Nzc2OTA0MA.Gw4RBd.7Y_gg5_VIg8zzLwgBB0G0Ochnp4n7Pn8p97-Hg"
local CHANNEL_ID = "1489793153333727342"
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not request then warn("Executor non-support HTTP") return end

print("[MoonTP] Connecting via RoProxy...")

-- VIẾT PHẲNG TOÀN BỘ TABLE ĐỂ TRÁNH LỖI LINE 41
local options = {Url = "https://roproxy.com/api/v10/channels/"..CHANNEL_ID.."/messages?limit=20", Method = "GET", Headers = {["Authorization"] = "Bot "..BOT_TOKEN, ["Content-Type"] = "application/json"}}

local ok, resp = pcall(function() return request(options) end)
if not ok or not resp or not resp.Body then warn("API Error") return end

local messages = HttpService:JSONDecode(resp.Body)
if not messages or #messages == 0 then warn("No Data") return end

local bestServer = nil
for i = 1, #messages do
    local msg = messages[i]
    local jsonStr = msg.content and msg.content:match("```json%s*(.-)%s*```")
    if jsonStr then
        local s, data = pcall(function() return HttpService:JSONDecode(jsonStr) end)
        if s and data and data.jobId then
            bestServer = data
            break
        end
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

if bestServer and bestServer.jobId then
    print("[MoonTP] Jumping to: "..bestServer.jobId)
    TeleportService:TeleportToPlaceInstance(tonumber(bestServer.placeId) or game.PlaceId, bestServer.jobId, LocalPlayer)
else
    warn("Server Not Found")
end
