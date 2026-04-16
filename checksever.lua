--[[
    ╔══════════════════════════════════════════════════════════╗
    ║         SERVER UPTIME DETECTOR - Blox Fruits             ║
    ║  Phát hiện server đã online được bao lâu & mở từ lúc nào ║
    ║                                                          ║
    ║  Dựa trên: workspace.DistributedGameTime                 ║
    ║  (Thời gian server đã chạy, KHÔNG phải lúc bạn vào)     ║
    ╚══════════════════════════════════════════════════════════╝
]]

--------------------------------------------------------------
-- SERVICES & VARIABLES
--------------------------------------------------------------
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local LocalPlayer    = Players.LocalPlayer

--------------------------------------------------------------
-- HÀM CHUYỂN GIÂY -> NGÀY/GIỜ/PHÚT/GIÂY
--------------------------------------------------------------
local function formatTime(totalSeconds)
    totalSeconds = math.floor(totalSeconds)
    
    local days    = math.floor(totalSeconds / 86400)
    local hours   = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60

    local parts = {}

    if days > 0 then
        table.insert(parts, days .. " ngày")
    end
    if hours > 0 then
        table.insert(parts, hours .. " giờ")
    end
    if minutes > 0 then
        table.insert(parts, minutes .. " phút")
    end
    table.insert(parts, seconds .. " giây")

    return table.concat(parts, " ")
end

--------------------------------------------------------------
-- HÀM CHUYỂN GIÂY -> ĐỊNH DẠNG NGẮN (00:00:00)
--------------------------------------------------------------
local function formatTimeShort(totalSeconds)
    totalSeconds = math.floor(totalSeconds)
    
    local days    = math.floor(totalSeconds / 86400)
    local hours   = math.floor((totalSeconds % 86400) / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60

    if days > 0 then
        return string.format("%dd %02d:%02d:%02d", days, hours, minutes, seconds)
    else
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
end

--------------------------------------------------------------
-- HÀM TÍNH THỜI GIAN SERVER BẮT ĐẦU (UTC)
--------------------------------------------------------------
local function getServerStartTime()
    local serverUptime = workspace.DistributedGameTime
    local currentTime  = os.time()  -- thời gian hiện tại (epoch)
    local startEpoch   = currentTime - serverUptime
    return startEpoch
end

--------------------------------------------------------------
-- HÀM PHÂN LOẠI SERVER (MỚI / CŨ / RẤT CŨ)
--------------------------------------------------------------
local function classifyServer(uptimeSeconds)
    if uptimeSeconds < 120 then
        return "MỚI TINH", Color3.fromRGB(0, 255, 100)        -- < 2 phút
    elseif uptimeSeconds < 600 then
        return "MỚI", Color3.fromRGB(100, 255, 100)            -- < 10 phút
    elseif uptimeSeconds < 1800 then
        return "BÌNH THƯỜNG", Color3.fromRGB(255, 255, 100)    -- < 30 phút
    elseif uptimeSeconds < 3600 then
        return "ĐÃ LÂU", Color3.fromRGB(255, 165, 0)          -- < 1 giờ
    elseif uptimeSeconds < 7200 then
        return "RẤT LÂU", Color3.fromRGB(255, 100, 50)         -- < 2 giờ
    else
        return "CỰC KỲ LÂU", Color3.fromRGB(255, 50, 50)      -- 2 giờ+
    end
end

--------------------------------------------------------------
-- TẠO GUI HIỂN THỊ
--------------------------------------------------------------
local function createUptimeGUI()
    -- Xóa GUI cũ nếu có
    local oldGui = LocalPlayer.PlayerGui:FindFirstChild("ServerUptimeGui")
    if oldGui then oldGui:Destroy() end

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ServerUptimeGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Main Frame (có thể kéo thả)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 180)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -90)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 120, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    titleBar.BackgroundTransparency = 0.1
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⏱ SERVER UPTIME DETECTOR"
    titleLabel.TextColor3 = Color3.fromRGB(80, 160, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Server Uptime Label (real-time)
    local uptimeLabel = Instance.new("TextLabel")
    uptimeLabel.Name = "UptimeLabel"
    uptimeLabel.Size = UDim2.new(1, -20, 0, 22)
    uptimeLabel.Position = UDim2.new(0, 10, 0, 40)
    uptimeLabel.BackgroundTransparency = 1
    uptimeLabel.Text = "Server Online: Đang tính..."
    uptimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    uptimeLabel.TextSize = 15
    uptimeLabel.Font = Enum.Font.GothamSemibold
    uptimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    uptimeLabel.Parent = mainFrame

    -- Server Start Time Label
    local startTimeLabel = Instance.new("TextLabel")
    startTimeLabel.Name = "StartTimeLabel"
    startTimeLabel.Size = UDim2.new(1, -20, 0, 20)
    startTimeLabel.Position = UDim2.new(0, 10, 0, 66)
    startTimeLabel.BackgroundTransparency = 1
    startTimeLabel.Text = "Mở từ: Đang tính..."
    startTimeLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    startTimeLabel.TextSize = 13
    startTimeLabel.Font = Enum.Font.Gotham
    startTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    startTimeLabel.Parent = mainFrame

    -- Classification Label
    local classLabel = Instance.new("TextLabel")
    classLabel.Name = "ClassLabel"
    classLabel.Size = UDim2.new(1, -20, 0, 22)
    classLabel.Position = UDim2.new(0, 10, 0, 90)
    classLabel.BackgroundTransparency = 1
    classLabel.Text = "Phân loại: ..."
    classLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    classLabel.TextSize = 14
    classLabel.Font = Enum.Font.GothamBold
    classLabel.TextXAlignment = Enum.TextXAlignment.Left
    classLabel.Parent = mainFrame

    -- Player Join Time vs Server Time
    local joinInfoLabel = Instance.new("TextLabel")
    joinInfoLabel.Name = "JoinInfoLabel"
    joinInfoLabel.Size = UDim2.new(1, -20, 0, 20)
    joinInfoLabel.Position = UDim2.new(0, 10, 0, 116)
    joinInfoLabel.BackgroundTransparency = 1
    joinInfoLabel.Text = "Server đã chạy trước khi bạn vào: ..."
    joinInfoLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    joinInfoLabel.TextSize = 12
    joinInfoLabel.Font = Enum.Font.Gotham
    joinInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    joinInfoLabel.Parent = mainFrame

    -- Số người chơi
    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Name = "PlayerCountLabel"
    playerCountLabel.Size = UDim2.new(1, -20, 0, 20)
    playerCountLabel.Position = UDim2.new(0, 10, 0, 140)
    playerCountLabel.BackgroundTransparency = 1
    playerCountLabel.Text = "Người chơi: ..."
    playerCountLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    playerCountLabel.TextSize = 12
    playerCountLabel.Font = Enum.Font.Gotham
    playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerCountLabel.Parent = mainFrame

    -- Nút đóng/mở
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0, 24, 0, 24)
    toggleBtn.Position = UDim2.new(1, -28, 0, 4)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    toggleBtn.BackgroundTransparency = 0.3
    toggleBtn.Text = "×"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 18
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = titleBar

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn

    local isMinimized = false
    toggleBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            mainFrame.Size = UDim2.new(0, 320, 0, 32)
            toggleBtn.Text = "+"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        else
            mainFrame.Size = UDim2.new(0, 320, 0, 180)
            toggleBtn.Text = "×"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        end
    end)

    return {
        UptimeLabel    = uptimeLabel,
        StartTimeLabel = startTimeLabel,
        ClassLabel     = classLabel,
        JoinInfoLabel  = joinInfoLabel,
        PlayerCountLabel = playerCountLabel,
    }
end

--------------------------------------------------------------
-- MAIN: CHẠY DETECTOR
--------------------------------------------------------------
local gui = createUptimeGUI()

-- Ghi nhận DistributedGameTime lúc mình vào server
local uptimeWhenJoined = workspace.DistributedGameTime

-- In ra console
print("══════════════════════════════════════════")
print("  SERVER UPTIME DETECTOR - Blox Fruits")
print("══════════════════════════════════════════")
print(string.format("  Server đã chạy trước khi bạn vào: %s", formatTime(uptimeWhenJoined)))
print(string.format("  Server bắt đầu lúc (UTC): %s", os.date("!%d/%m/%Y %H:%M:%S", getServerStartTime())))
print(string.format("  Server bắt đầu lúc (Local): %s", os.date("%d/%m/%Y %H:%M:%S", getServerStartTime())))
print("══════════════════════════════════════════")

-- Cập nhật GUI liên tục mỗi giây
RunService.Heartbeat:Connect(function()
    local serverUptime = workspace.DistributedGameTime
    local className, classColor = classifyServer(serverUptime)
    local startEpoch = getServerStartTime()
    local playerCount = #Players:GetPlayers()

    -- Cập nhật các label
    gui.UptimeLabel.Text = "⏱ Server Online: " .. formatTimeShort(serverUptime)
    gui.StartTimeLabel.Text = "📅 Mở từ: " .. os.date("%d/%m/%Y %H:%M:%S", startEpoch)
    gui.ClassLabel.Text = "📊 Phân loại: " .. className
    gui.ClassLabel.TextColor3 = classColor
    gui.JoinInfoLabel.Text = "⏳ Chạy trước khi bạn vào: " .. formatTime(uptimeWhenJoined)
    gui.PlayerCountLabel.Text = "👥 Người chơi: " .. playerCount .. "/" .. Players.MaxPlayers
end)

--------------------------------------------------------------
-- THÔNG BÁO KHI SERVER SẮP ĐÓNG (tùy chọn)
-- Roblox server thường tồn tại tối đa ~20-24 giờ
--------------------------------------------------------------
spawn(function()
    while true do
        local uptime = workspace.DistributedGameTime
        -- Cảnh báo khi server đã chạy hơn 18 giờ (có thể sắp restart)
        if uptime > 64800 then -- 18 giờ
            warn("[SERVER UPTIME] ⚠️ Server đã chạy hơn 18 giờ! Có thể sắp được restart.")
        end
        wait(30)
    end
end)

print("[SERVER UPTIME DETECTOR] ✅ Đã khởi động thành công!")
print("[SERVER UPTIME DETECTOR] 💡 Kéo thả GUI để di chuyển | Nhấn × để thu nhỏ")
