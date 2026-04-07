--[[
    ╔══════════════════════════════════════════════╗
    ║       SERVER AGE CHECKER v2                   ║
    ║  Hiện tuổi server + thời gian bạn join        ║
    ╚══════════════════════════════════════════════╝
]]

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(5) -- Đợi DistributedGameTime sync chính xác

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ====================== GHI NHẬN LÚC JOIN ======================
-- Lấy ngay lúc script chạy để tính
local JoinRealTime = os.time()                              -- Thời gian thực lúc bạn join
local ServerUptimeAtJoin = math.floor(workspace.DistributedGameTime)  -- Server đã chạy bao lâu TRƯỚC khi bạn join
local ServerCreatedTimestamp = JoinRealTime - ServerUptimeAtJoin      -- Thời điểm server được TẠO

print("[ServerAge] DistributedGameTime lúc join:", ServerUptimeAtJoin, "giây")
print("[ServerAge] Server tạo lúc timestamp:", ServerCreatedTimestamp)
print("[ServerAge] Server tạo lúc:", os.date("%d/%m/%Y %H:%M:%S", ServerCreatedTimestamp))

-- ====================== FORMAT FUNCTIONS ======================
local function FormatDuration(totalSeconds)
    totalSeconds = math.floor(totalSeconds)
    if totalSeconds < 0 then totalSeconds = 0 end
    
    local days = math.floor(totalSeconds / 86400)
    local hours = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    
    local parts = {}
    if days > 0 then table.insert(parts, days .. " ngày") end
    if hours > 0 then table.insert(parts, hours .. " giờ") end
    if minutes > 0 then table.insert(parts, minutes .. " phút") end
    if seconds > 0 or #parts == 0 then table.insert(parts, seconds .. " giây") end
    
    return table.concat(parts, " "), days, hours, minutes, seconds
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

local MF = Instance.new("Frame")
MF.Name = "Main"
MF.Size = UDim2.new(0, 320, 0, 210)
MF.Position = UDim2.new(0, 20, 1, -230)
MF.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
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
TL.Text = "🖥️ SERVER AGE CHECKER"
TL.TextColor3 = Color3.new(1, 1, 1)
TL.TextSize = 13
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local MinBtn = Instance.new("TextButton", TB)
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -28, 0, 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CF = Instance.new("Frame", MF)
CF.Name = "Content"
CF.Size = UDim2.new(1, -12, 1, -34)
CF.Position = UDim2.new(0, 6, 0, 32)
CF.BackgroundTransparency = 1

local _min = false
MinBtn.MouseButton1Click:Connect(function()
    _min = not _min
    CF.Visible = not _min
    MF.Size = _min and UDim2.new(0, 320, 0, 28) or UDim2.new(0, 320, 0, 210)
    MinBtn.Text = _min and "+" or "−"
end)

-- Labels
local _labels = {}
local _lY = 0
local function ML(id, text, color)
    local l = Instance.new("TextLabel", CF)
    l.Name = id
    l.Size = UDim2.new(1, 0, 0, 18)
    l.Position = UDim2.new(0, 0, 0, _lY)
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or Color3.fromRGB(220, 220, 240)
    l.TextSize = 12
    l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    _lY = _lY + 20
    _labels[id] = l
    return l
end
local function MS()
    local s = Instance.new("Frame", CF)
    s.Size = UDim2.new(1, 0, 0, 1)
    s.Position = UDim2.new(0, 0, 0, _lY)
    s.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    s.BorderSizePixel = 0
    _lY = _lY + 4
end
local function UL(id, text) if _labels[id] then _labels[id].Text = text end end
local function SLC(id, c) if _labels[id] then _labels[id].TextColor3 = c end end

ML("h1", "═══ SERVER ═══", Color3.fromRGB(0, 170, 255)); MS()
ML("created",  "📅 Server tạo lúc: ...")
ML("age",      "⏱️ Tuổi server: ...")
ML("uptime",   "🔄 Đang chạy: ...")
MS()
ML("h2", "═══ BẠN ═══", Color3.fromRGB(0, 170, 255)); MS()
ML("joined",   "🚪 Bạn join lúc: ...")
ML("session",  "🕐 Phiên của bạn: ...")
MS()
ML("players",  "👥 Players: ...")
ML("server",   "🖥️ JobId: " .. string.sub(game.JobId, 1, 24) .. "...")

-- ====================== UPDATE LOOP ======================
task.spawn(function()
    while true do
        -- 1. TUỔI SERVER (tính từ lúc server được tạo ra lần đầu)
        local currentUptime = math.floor(workspace.DistributedGameTime)
        local serverCreated = os.time() - currentUptime
        
        -- Thời điểm server tạo
        UL("created", "📅 Server tạo lúc: " .. os.date("%d/%m/%Y %H:%M:%S", serverCreated))
        
        -- Tuổi server (bao lâu từ lúc tạo đến giờ)
        local ageStr, days, hours, mins, secs = FormatDuration(currentUptime)
        UL("age", "⏱️ Tuổi server: " .. ageStr)
        
        -- Màu theo tuổi
        if days >= 1 then
            SLC("age", Color3.fromRGB(255, 50, 50))        -- 🔴 > 1 ngày
            SLC("created", Color3.fromRGB(255, 50, 50))
        elseif hours >= 12 then
            SLC("age", Color3.fromRGB(255, 120, 0))        -- 🟠 > 12 giờ
            SLC("created", Color3.fromRGB(255, 120, 0))
        elseif hours >= 6 then
            SLC("age", Color3.fromRGB(255, 200, 50))       -- 🟡 > 6 giờ
            SLC("created", Color3.fromRGB(255, 200, 50))
        elseif hours >= 1 then
            SLC("age", Color3.fromRGB(180, 255, 80))       -- 🟢 1-6 giờ
            SLC("created", Color3.fromRGB(180, 255, 80))
        else
            SLC("age", Color3.fromRGB(80, 255, 80))        -- 🟢 < 1 giờ (mới)
            SLC("created", Color3.fromRGB(80, 255, 80))
        end
        
        -- Uptime realtime (đếm lên mỗi giây)
        UL("uptime", "🔄 Đang chạy: " .. FormatDuration(currentUptime))
        
        -- 2. PHIÊN CỦA BẠN (từ lúc bạn join đến giờ)
        local sessionTime = os.time() - JoinRealTime
        UL("joined", "🚪 Bạn join lúc: " .. os.date("%d/%m/%Y %H:%M:%S", JoinRealTime))
        UL("session", "🕐 Phiên của bạn: " .. FormatDuration(sessionTime))
        
        -- 3. PLAYERS
        UL("players", "👥 Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        
        task.wait(1)
    end
end)

-- ====================== CONSOLE LOG ======================
local ageStr = FormatDuration(ServerUptimeAtJoin)
print("═══════════════════════════════════════════")
print("[ServerAge] 🖥️ SERVER AGE CHECKER v2")
print("───────────────────────────────────────────")
print("[ServerAge] 📅 Server tạo lúc : " .. os.date("%d/%m/%Y %H:%M:%S", ServerCreatedTimestamp))
print("[ServerAge] ⏱️ Tuổi server    : " .. ageStr)
print("[ServerAge] 🚪 Bạn join lúc   : " .. os.date("%d/%m/%Y %H:%M:%S", JoinRealTime))
print("[ServerAge] 👥 Players        : " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
print("[ServerAge] 🖥️ JobId          : " .. game.JobId)
print("═══════════════════════════════════════════")
