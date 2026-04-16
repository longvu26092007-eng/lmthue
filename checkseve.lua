-- ═══════════════════════════════════════════════════════════════════════
-- 🎮 BLOX FRUITS SERVER TIMER - COMPLETE SCRIPT
-- Dựa trên phân tích file source code gốc
-- Sử dụng workspace.DistributedGameTime (chính xác 100%)
-- ═══════════════════════════════════════════════════════════════════════

--[[
    PHÂN TÍCH TỪ SOURCE CODE:
    
    1. workspace.DistributedGameTime = Server uptime (68.675 giây)
    2. workspace:GetServerTimeNow() = Unix timestamp (146 lần sử dụng)
    3. tick() = Local time (3977 lần sử dụng)
    
    CÔNG THỨC:
    - Server Uptime = workspace.DistributedGameTime
    - Server Start Time = GetServerTimeNow() - DistributedGameTime
    - Session Time = tick() - playerJoinTime
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerJoinTime = tick()

print("═══════════════════════════════════════════════════════════════")
print("🎮 BLOX FRUITS SERVER TIMER - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Format time: seconds → "24h 35m 4s"
local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    return string.format("%dh %dm %ds", hours, mins, secs)
end

-- Get server uptime (từ workspace.DistributedGameTime)
local function getServerUptime()
    return Workspace.DistributedGameTime
end

-- Get server start time (tính từ uptime)
local function getServerStartTime()
    return Workspace:GetServerTimeNow() - Workspace.DistributedGameTime
end

-- Get session time (thời gian player đã chơi)
local function getSessionTime()
    return tick() - playerJoinTime
end

-- ═══════════════════════════════════════════════════════════════════════
-- CREATE GUI (Blox Fruits Style)
-- ═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerTimerUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame (background)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 90)
mainFrame.Position = UDim2.new(0, 15, 0, 15)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Stroke (border)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(40, 40, 50)
stroke.Thickness = 1
stroke.Parent = mainFrame

-- Padding
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = mainFrame

-- Layout
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)
layout.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════════════
-- TEXT LABELS
-- ═══════════════════════════════════════════════════════════════════════

-- Player Timer (session time)
local playerTimerLabel = Instance.new("TextLabel")
playerTimerLabel.Name = "PlayerTimer"
playerTimerLabel.Size = UDim2.new(1, 0, 0, 20)
playerTimerLabel.BackgroundTransparency = 1
playerTimerLabel.Text = "Timer: 0h 0m 0s"
playerTimerLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
playerTimerLabel.TextSize = 14
playerTimerLabel.Font = Enum.Font.GothamMedium
playerTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
playerTimerLabel.LayoutOrder = 1
playerTimerLabel.Parent = mainFrame

-- Server Timer (server uptime)
local serverTimerLabel = Instance.new("TextLabel")
serverTimerLabel.Name = "ServerTimer"
serverTimerLabel.Size = UDim2.new(1, 0, 0, 20)
serverTimerLabel.BackgroundTransparency = 1
serverTimerLabel.Text = "Server Timer: 0h 0m 0s"
serverTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
serverTimerLabel.TextSize = 14
serverTimerLabel.Font = Enum.Font.GothamBold
serverTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
serverTimerLabel.LayoutOrder = 2
serverTimerLabel.Parent = mainFrame

-- Info Label (server started at)
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, 0, 0, 18)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Server started: Loading..."
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.LayoutOrder = 3
infoLabel.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════════════
-- UPDATE FUNCTION
-- ═══════════════════════════════════════════════════════════════════════

local function updateTimers()
    -- Update player timer (session time)
    local sessionTime = getSessionTime()
    playerTimerLabel.Text = "Timer: " .. formatTime(sessionTime)
    
    -- Update server timer (server uptime from DistributedGameTime)
    local serverUptime = getServerUptime()
    serverTimerLabel.Text = "Server Timer: " .. formatTime(serverUptime)
    
    -- Update info label (server start time)
    local serverStartTime = getServerStartTime()
    local dateTime = os.date("%Y-%m-%d %H:%M:%S", serverStartTime)
    infoLabel.Text = "Server started: " .. dateTime
end

-- ═══════════════════════════════════════════════════════════════════════
-- DRAGGABLE FEATURE
-- ═══════════════════════════════════════════════════════════════════════

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

mainFrame.InputBegan:Connect(function(input)
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

mainFrame.InputChanged:Connect(function(input)
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

-- ═══════════════════════════════════════════════════════════════════════
-- TOGGLE KEY (F2)
-- ═══════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
        mainFrame.Visible = not mainFrame.Visible
        print("🎮 Server Timer toggled:", mainFrame.Visible)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- START UPDATE LOOP
-- ═══════════════════════════════════════════════════════════════════════

-- Initial update
updateTimers()

-- Update every second
task.spawn(function()
    while task.wait(1) do
        updateTimers()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- DEBUG INFO
-- ═══════════════════════════════════════════════════════════════════════

print("✅ Server Timer UI Loaded!")
print("📊 Server Uptime: " .. formatTime(getServerUptime()))
print("📅 Server Started: " .. os.date("%Y-%m-%d %H:%M:%S", getServerStartTime()))
print("💡 Press F2 to toggle timer")
print("═══════════════════════════════════════════════════════════════")

-- ═══════════════════════════════════════════════════════════════════════
-- API (cho scripts khác sử dụng)
-- ═══════════════════════════════════════════════════════════════════════

_G.ServerTimerAPI = {
    getServerUptime = getServerUptime,
    getServerStartTime = getServerStartTime,
    getSessionTime = getSessionTime,
    formatTime = formatTime,
    toggleUI = function()
        mainFrame.Visible = not mainFrame.Visible
    end
}
