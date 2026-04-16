-- ═══════════════════════════════════════════════════════════════════════
-- 🔥 SERVER UPTIME DETECTOR - ALL IN ONE + UI PANEL
-- Script này gộp cả SERVER và CLIENT logic + UI Panel chi tiết
-- Đặt trong: ServerScriptService
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("═══════════════════════════════════════════════════════════════")
print("🔥 SERVER UPTIME DETECTOR - ALL IN ONE - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ═════════════════════════════════════════════════════════════════════
-- PHẦN 1: SERVER - Ghi nhận thời điểm server khởi động
-- ═════════════════════════════════════════════════════════════════════
local serverStartTime = Workspace:GetServerTimeNow()
Workspace:SetAttribute("ServerStartTime", serverStartTime)

print("✅ Server start time set: " .. tostring(serverStartTime))
print("📌 Server officially started at: " .. os.date("%Y-%m-%d %H:%M:%S UTC"))

-- Log server uptime mỗi 60 giây
task.spawn(function()
    while task.wait(60) do
        local currentTime = Workspace:GetServerTimeNow()
        local uptime = currentTime - serverStartTime
        local hours = math.floor(uptime / 3600)
        local mins = math.floor((uptime % 3600) / 60)
        local secs = math.floor(uptime % 60)
        
        print(string.format("[SERVER] Uptime: %02d:%02d:%02d", hours, mins, secs))
    end
end)

-- ═════════════════════════════════════════════════════════════════════
-- PHẦN 2: CLIENT - Tạo GUI cho mỗi player
-- ═════════════════════════════════════════════════════════════════════

local clientScriptSource = [[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerJoinTime = tick()

print("═══════════════════════════════════════════════════════════════")
print("🟢 SERVER UPTIME UI PANEL - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ─────────────────────────────────────────────────────────────────────
-- FORMAT TIME
-- ─────────────────────────────────────────────────────────────────────
local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if days > 0 then
        return string.format("%dd %02d:%02d:%02d", days, hours, mins, secs)
    else
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    end
end

local function formatDateTime(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- ─────────────────────────────────────────────────────────────────────
-- TÍNH SERVER UPTIME
-- ─────────────────────────────────────────────────────────────────────
local function getServerUptime()
    local startTime = Workspace:GetAttribute("ServerStartTime")
    if not startTime then
        return nil
    end
    return Workspace:GetServerTimeNow() - startTime
end

local function getServerStartTime()
    return Workspace:GetAttribute("ServerStartTime")
end

-- ─────────────────────────────────────────────────────────────────────
-- CREATE GUI
-- ─────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "ServerUptimePanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Main Frame (có thể drag)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel"
mainFrame.Size = UDim2.new(0, 400, 0, 280)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = 0
shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Fix bottom corners
local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0, 12)
headerBottom.Position = UDim2.new(0, 0, 1, -12)
headerBottom.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🟢 SERVER INFO"
title.TextColor3 = Color3.fromRGB(0, 255, 128)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeButton"
minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
minimizeBtn.Position = UDim2.new(1, -90, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 20
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Parent = header

local minimizeBtnCorner = Instance.new("UICorner")
minimizeBtnCorner.CornerRadius = UDim.new(0, 8)
minimizeBtnCorner.Parent = minimizeBtn

-- Content Area
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -30, 1, -65)
content.Position = UDim2.new(0, 15, 0, 55)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Info Labels
local function createInfoRow(name, labelText, yPos)
    local row = Instance.new("Frame")
    row.Name = name .. "Row"
    row.Size = UDim2.new(1, 0, 0, 35)
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = content
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ":"
    label.TextColor3 = Color3.fromRGB(150, 150, 160)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(0.55, 0, 1, 0)
    value.Position = UDim2.new(0.45, 0, 0, 0)
    value.BackgroundTransparency = 1
    value.Text = "Loading..."
    value.TextColor3 = Color3.fromRGB(255, 255, 255)
    value.TextSize = 14
    value.Font = Enum.Font.GothamBold
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Parent = row
    
    return value
end

local serverUptimeValue = createInfoRow("ServerUptime", "Server Uptime", 0)
local serverStartValue = createInfoRow("ServerStart", "Server Started", 40)
local playerJoinValue = createInfoRow("PlayerJoin", "You Joined", 80)
local sessionTimeValue = createInfoRow("SessionTime", "Session Time", 120)
local playersOnlineValue = createInfoRow("PlayersOnline", "Players Online", 160)

-- ─────────────────────────────────────────────────────────────────────
-- UPDATE DISPLAY
-- ─────────────────────────────────────────────────────────────────────
local function updateDisplay()
    local uptime = getServerUptime()
    local startTime = getServerStartTime()
    
    if uptime then
        serverUptimeValue.Text = formatTime(uptime)
        serverUptimeValue.TextColor3 = Color3.fromRGB(0, 255, 128)
    else
        serverUptimeValue.Text = "Loading..."
        serverUptimeValue.TextColor3 = Color3.fromRGB(255, 255, 0)
    end
    
    if startTime then
        serverStartValue.Text = formatDateTime(startTime)
    end
    
    -- Session time
    local sessionTime = tick() - playerJoinTime
    sessionTimeValue.Text = formatTime(sessionTime)
    
    -- Players online
    playersOnlineValue.Text = tostring(#Players:GetPlayers())
end

-- ─────────────────────────────────────────────────────────────────────
-- DRAGGABLE
-- ─────────────────────────────────────────────────────────────────────
local dragging = false
local dragInput, mousePos, framePos

local function updateInput(input)
    local delta = input.Position - mousePos
    mainFrame.Position = UDim2.new(
        framePos.X.Scale,
        framePos.X.Offset + delta.X,
        framePos.Y.Scale,
        framePos.Y.Offset + delta.Y
    )
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- BUTTONS
-- ─────────────────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    if isMinimized then
        mainFrame:TweenSize(
            UDim2.new(0, 400, 0, 50),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
        content.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame:TweenSize(
            UDim2.new(0, 400, 0, 280),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
        content.Visible = true
        minimizeBtn.Text = "−"
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- AUTO UPDATE
-- ─────────────────────────────────────────────────────────────────────
Workspace:GetAttributeChangedSignal("ServerStartTime"):Connect(updateDisplay)
updateDisplay()

task.spawn(function()
    while task.wait(1) do
        updateDisplay()
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- TOGGLE KEY (F2)
-- ─────────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- ─────────────────────────────────────────────────────────────────────
-- API
-- ─────────────────────────────────────────────────────────────────────
local ServerUptimeAPI = {}

function ServerUptimeAPI.getTotalUptime()
    local uptime = getServerUptime()
    return uptime or 0
end

function ServerUptimeAPI.getFormattedUptime()
    return formatTime(ServerUptimeAPI.getTotalUptime())
end

function ServerUptimeAPI.formatTime(seconds)
    return formatTime(seconds)
end

function ServerUptimeAPI.togglePanel()
    mainFrame.Visible = not mainFrame.Visible
end

_G.ServerUptimeAPI = ServerUptimeAPI

print("✅ SERVER UPTIME UI PANEL READY")
print("💡 Press F2 to toggle panel")
print("═══════════════════════════════════════════════════════════════")
]]

-- ─────────────────────────────────────────────────────────────────────
-- Tạo LocalScript cho mỗi player
-- ─────────────────────────────────────────────────────────────────────
local function setupPlayerGui(player)
    print("🔌 Setting up GUI for player: " .. player.Name)
    
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then
        warn("❌ PlayerGui not found for " .. player.Name)
        return
    end
    
    local localScript = Instance.new("LocalScript")
    localScript.Name = "ServerUptimeClient"
    localScript.Source = clientScriptSource
    localScript.Parent = playerGui
    
    print("✅ GUI created for player: " .. player.Name)
end

-- Setup cho players hiện có
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        setupPlayerGui(player)
    end)
end

-- Setup cho players join sau
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        setupPlayerGui(player)
    end)
end)

print("═══════════════════════════════════════════════════════════════")
print("✅ SERVER UPTIME DETECTOR - ALL IN ONE - READY")
print("═══════════════════════════════════════════════════════════════")
