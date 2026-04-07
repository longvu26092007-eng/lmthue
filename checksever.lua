--[[
    ╔══════════════════════════════════════════════╗
    ║       SERVER AGE CHECKER v3                   ║
    ║  Dùng GetServerTimeNow() từ source BF         ║
    ╚══════════════════════════════════════════════╝
    
    Từ source Blox Fruits tìm được 2 cách lấy thời gian server:
    1. workspace:GetServerTimeNow()  → timestamp server-synced (chính xác nhất)
    2. workspace.DistributedGameTime → số giây server đã chạy
    3. os.time() - tick()            → offset giữa real time và local tick
    
    Kết hợp cả 3 để tính chính xác nhất.
]]

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(1) until game.Players.LocalPlayer
repeat task.wait(1) until game.Players.LocalPlayer.Character
task.wait(5)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ====================== TÍNH TUỔI SERVER ======================
-- Cách 1: GetServerTimeNow (từ source BF, chính xác nhất, server-synced)
local ServerTimeNow = nil
pcall(function()
    ServerTimeNow = workspace:GetServerTimeNow()
end)

-- Cách 2: DistributedGameTime (Roblox built-in, số giây server đã chạy)  
local ServerUptime = workspace.DistributedGameTime

-- Cách 3: os.time() - tick() offset (từ source BF: GetWaterHeightAtLocation)
local TimeOffset = os.time() - tick()

-- Tính thời điểm server được tạo
local ServerCreatedTimestamp
if ServerTimeNow and ServerTimeNow > 0 then
    -- Dùng GetServerTimeNow - DistributedGameTime = thời điểm tạo (chính xác nhất)
    ServerCreatedTimestamp = math.floor(ServerTimeNow - ServerUptime)
else
    -- Fallback: os.time() - uptime
    ServerCreatedTimestamp = math.floor(os.time() - ServerUptime)
end

-- Thời điểm bạn join
local JoinTimestamp = os.time()
local UptimeAtJoin = math.floor(ServerUptime)

-- ====================== FORMAT ======================
local function FormatDuration(totalSeconds)
    totalSeconds = math.max(0, math.floor(totalSeconds))
    local days = math.floor(totalSeconds / 86400)
    local hours = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    
    local parts = {}
    if days > 0 then table.insert(parts, days .. "d") end
    if hours > 0 then table.insert(parts, hours .. "h") end
    if minutes > 0 then table.insert(parts, minutes .. "m") end
    table.insert(parts, seconds .. "s")
    
    return table.concat(parts, " ")
end

local function FormatDurationVN(totalSeconds)
    totalSeconds = math.max(0, math.floor(totalSeconds))
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
MF.Size = UDim2.new(0, 310, 0, 230)
MF.Position = UDim2.new(0, 20, 1, -250)
MF.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MF.BorderSizePixel = 0
MF.Parent = SG
MF.Active = true
MF.Draggable = true
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 10)
local stk = Instance.new("UIStroke", MF)
stk.Color = Color3.fromRGB(0, 170, 255)
stk.Thickness = 2

-- Title
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
TL.Size = UDim2.new(1, -40, 1, 0)
TL.Position = UDim2.new(0, 10, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "🖥️ SERVER AGE v3"
TL.TextColor3 = Color3.new(1, 1, 1)
TL.TextSize = 13
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize
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
    MF.Size = _min and UDim2.new(0, 310, 0, 28) or UDim2.new(0, 310, 0, 230)
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
ML("created", "📅 Tạo lúc: ...")
ML("age",     "⏱️ Tuổi: ...")
ML("live",    "🔴 LIVE: ...")
MS()
ML("h2", "═══ BẠN ═══", Color3.fromRGB(0, 170, 255)); MS()
ML("joined",  "🚪 Join lúc: ...")
ML("session", "🕐 Phiên: ...")
MS()
ML("players", "👥 Players: ...")
ML("jobid",   "🖥️ JobId: ...")

-- ====================== MAIN LOOP ======================
task.spawn(function()
    while true do
        -- === SERVER ===
        -- Lấy uptime realtime (cập nhật mỗi giây)
        local currentUptime = workspace.DistributedGameTime
        
        -- Tính lại server created dùng GetServerTimeNow (chính xác hơn os.time)
        local serverCreated = ServerCreatedTimestamp
        pcall(function()
            local stn = workspace:GetServerTimeNow()
            if stn and stn > 0 then
                serverCreated = math.floor(stn - currentUptime)
            end
        end)
        
        -- Thời điểm server tạo
        UL("created", "📅 Tạo lúc: " .. os.date("%d/%m/%Y  %H:%M:%S", serverCreated))
        
        -- Tuổi server
        local ageStr, days, hours = FormatDurationVN(currentUptime)
        UL("age", "⏱️ Tuổi: " .. ageStr)
        
        -- LIVE counter (compact)
        UL("live", "🔴 LIVE: " .. FormatDuration(currentUptime))
        SLC("live", Color3.fromRGB(255, 80, 80))
        
        -- Màu theo tuổi
        if days >= 1 then
            SLC("age", Color3.fromRGB(255, 50, 50))
            SLC("created", Color3.fromRGB(255, 50, 50))
        elseif hours >= 12 then
            SLC("age", Color3.fromRGB(255, 120, 0))
            SLC("created", Color3.fromRGB(255, 120, 0))
        elseif hours >= 6 then
            SLC("age", Color3.fromRGB(255, 200, 50))
            SLC("created", Color3.fromRGB(255, 200, 50))
        elseif hours >= 1 then
            SLC("age", Color3.fromRGB(180, 255, 80))
            SLC("created", Color3.fromRGB(180, 255, 80))
        else
            SLC("age", Color3.fromRGB(80, 255, 80))
            SLC("created", Color3.fromRGB(80, 255, 80))
        end
        
        -- === BẠN ===
        local sessionTime = os.time() - JoinTimestamp
        UL("joined", "🚪 Join lúc: " .. os.date("%d/%m/%Y  %H:%M:%S", JoinTimestamp))
        UL("session", "🕐 Phiên: " .. FormatDurationVN(sessionTime))
        
        -- === INFO ===
        UL("players", "👥 Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        UL("jobid", "🖥️ JobId: " .. string.sub(game.JobId, 1, 24) .. "...")
        
        task.wait(1)
    end
end)

-- ====================== CONSOLE ======================
print("═══════════════════════════════════════════")
print("[ServerAge v3] 🖥️ SERVER AGE CHECKER")
print("───────────────────────────────────────────")
print("[ServerAge] 📅 Server tạo lúc  : " .. os.date("%d/%m/%Y %H:%M:%S", ServerCreatedTimestamp))
print("[ServerAge] ⏱️ Tuổi server     : " .. FormatDurationVN(UptimeAtJoin))
print("[ServerAge] 🚪 Bạn join lúc    : " .. os.date("%d/%m/%Y %H:%M:%S", JoinTimestamp))
print("[ServerAge] 👥 Players         : " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
print("[ServerAge] 🖥️ JobId           : " .. game.JobId)
if ServerTimeNow then
    print("[ServerAge] 🔧 Method          : GetServerTimeNow() ✅")
else
    print("[ServerAge] 🔧 Method          : os.time() fallback ⚠️")
end
print("═══════════════════════════════════════════")
