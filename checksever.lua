--[[
    ╔══════════════════════════════════════════════╗
    ║       SERVER AGE CHECKER                      ║
    ║  Hiện thời gian server đã được tạo ra         ║
    ╚══════════════════════════════════════════════╝
]]

-- Đợi game load
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(3)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ====================== TÍNH TOÁN ======================
local function GetServerInfo()
    local uptime = workspace.DistributedGameTime  -- giây server đã chạy
    local createdTimestamp = os.time() - math.floor(uptime)  -- thời điểm tạo server

    -- Tách uptime ra ngày / giờ / phút / giây
    local days = math.floor(uptime / 86400)
    local hours = math.floor((uptime % 86400) / 3600)
    local minutes = math.floor((uptime % 3600) / 60)
    local seconds = math.floor(uptime % 60)

    -- Format uptime đẹp
    local uptimeStr = ""
    if days > 0 then uptimeStr = uptimeStr .. days .. " ngày " end
    if hours > 0 then uptimeStr = uptimeStr .. hours .. " giờ " end
    if minutes > 0 then uptimeStr = uptimeStr .. minutes .. " phút " end
    uptimeStr = uptimeStr .. seconds .. " giây"

    -- Thời điểm tạo server (giờ local)
    local createdStr = os.date("%d/%m/%Y %H:%M:%S", createdTimestamp)

    -- Server ID
    local jobId = game.JobId
    local shortJobId = string.sub(jobId, 1, 20) .. "..."

    -- Số player
    local playerCount = #Players:GetPlayers() .. "/" .. Players.MaxPlayers

    return {
        uptime = uptime,
        uptimeStr = uptimeStr,
        createdStr = createdStr,
        createdTimestamp = createdTimestamp,
        jobId = shortJobId,
        playerCount = playerCount,
        days = days,
        hours = hours,
        minutes = minutes,
        seconds = seconds,
    }
end

-- ====================== UI ======================
pcall(function()
    local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("ServerAgeUI")
    if old then old:Destroy() end
end)

local UIParent = (gethui and gethui()) or game:GetService("CoreGui")
local SG = Instance.new("ScreenGui")
SG.Name = "ServerAgeUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = UIParent

-- Main Frame
local MF = Instance.new("Frame")
MF.Name = "Main"
MF.Size = UDim2.new(0, 280, 0, 165)
MF.Position = UDim2.new(0, 20, 1, -185)
MF.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MF.BorderSizePixel = 0
MF.Parent = SG
MF.Active = true
MF.Draggable = true
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 10)
local stk = Instance.new("UIStroke", MF)
stk.Color = Color3.fromRGB(0, 170, 255)
stk.Thickness = 2

-- Title Bar
local TB = Instance.new("Frame", MF)
TB.Size = UDim2.new(1, 0, 0, 28)
TB.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
TB.BorderSizePixel = 0
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)
local TBF = Instance.new("Frame", TB)
TBF.Size = UDim2.new(1, 0, 0, 10)
TBF.Position = UDim2.new(0, 0, 1, -10)
TBF.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
TBF.BorderSizePixel = 0

local TL = Instance.new("TextLabel", TB)
TL.Size = UDim2.new(1, -10, 1, 0)
TL.Position = UDim2.new(0, 10, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "🖥️ SERVER AGE"
TL.TextColor3 = Color3.new(1, 1, 1)
TL.TextSize = 13
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

-- Content Frame
local CF = Instance.new("Frame", MF)
CF.Name = "Content"
CF.Size = UDim2.new(1, -12, 1, -34)
CF.Position = UDim2.new(0, 6, 0, 32)
CF.BackgroundTransparency = 1

-- Labels
local _labels = {}
local _lY = 0

local function MakeLabel(id, text)
    local l = Instance.new("TextLabel", CF)
    l.Name = id
    l.Size = UDim2.new(1, 0, 0, 18)
    l.Position = UDim2.new(0, 0, 0, _lY)
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = Color3.fromRGB(220, 220, 240)
    l.TextSize = 12
    l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    _lY = _lY + 20
    _labels[id] = l
    return l
end

local function UpdateLabel(id, text)
    if _labels[id] then _labels[id].Text = text end
end

local function SetColor(id, color)
    if _labels[id] then _labels[id].TextColor3 = color end
end

MakeLabel("uptime",  "⏱️ Uptime: ...")
MakeLabel("created", "📅 Tạo lúc: ...")
MakeLabel("age",     "📊 Tuổi: ...")
MakeLabel("players", "👥 Players: ...")
MakeLabel("server",  "🖥️ Server: ...")

-- ====================== UPDATE LOOP ======================
task.spawn(function()
    while true do
        local info = GetServerInfo()

        -- Uptime
        UpdateLabel("uptime", "⏱️ Uptime: " .. info.uptimeStr)

        -- Thời điểm tạo
        UpdateLabel("created", "📅 Tạo lúc: " .. info.createdStr)

        -- Tuổi server (màu theo độ cũ)
        local ageText = ""
        if info.days > 0 then
            ageText = info.days .. " ngày " .. info.hours .. " giờ trước"
        elseif info.hours > 0 then
            ageText = info.hours .. " giờ " .. info.minutes .. " phút trước"
        else
            ageText = info.minutes .. " phút " .. info.seconds .. " giây trước"
        end
        UpdateLabel("age", "📊 Tuổi: " .. ageText)

        -- Đổi màu theo tuổi
        if info.days >= 1 then
            SetColor("age", Color3.fromRGB(255, 80, 80))       -- Đỏ: > 1 ngày (server cũ)
        elseif info.hours >= 6 then
            SetColor("age", Color3.fromRGB(255, 170, 0))       -- Cam: 6+ giờ
        elseif info.hours >= 1 then
            SetColor("age", Color3.fromRGB(255, 255, 80))      -- Vàng: 1-6 giờ
        else
            SetColor("age", Color3.fromRGB(80, 255, 80))       -- Xanh: < 1 giờ (server mới)
        end

        -- Players
        UpdateLabel("players", "👥 Players: " .. info.playerCount)

        -- Server ID
        UpdateLabel("server", "🖥️ Server: " .. info.jobId)

        task.wait(1)  -- Cập nhật mỗi giây
    end
end)

-- Print ra console
local info = GetServerInfo()
print("═══════════════════════════════════════════")
print("[ServerAge] 🖥️ SERVER INFO")
print("[ServerAge] ⏱️ Uptime: " .. info.uptimeStr)
print("[ServerAge] 📅 Tạo lúc: " .. info.createdStr)
print("[ServerAge] 👥 Players: " .. info.playerCount)
print("[ServerAge] 🖥️ JobId: " .. game.JobId)
print("═══════════════════════════════════════════")
