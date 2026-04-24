-- ==========================================================================
-- AUTO TRAVEL TO SEA 2 + TP CHAIR UI
-- Flow:
--   1. Đợi game load
--   2. Load team (Pirates)
--   3. Check sea (MAP attribute + PlaceId fallback)
--   4. Sea 1 hoặc Sea 3 → Travel về Sea 2
--   5. Sea 2 → Next phase
-- UI: TP Chair (Table 1, Table 2 - mỗi table 2 ghế)
-- ==========================================================================

-- [1] ĐỢI GAME LOAD
repeat task.wait(0.5)
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

-- [2] SETUP SERVICES
getgenv().cloneref = cloneref or clonereference or function(x) return x end

local Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function() return cloneref(game:GetService(name)) end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name))
    end
end})

local CoreGui            = Services.CoreGui
local ReplicatedStorage  = Services.ReplicatedStorage
local Players            = Services.Players
local StarterGui         = Services.StarterGui
local UserInputService   = Services.UserInputService
local TweenService       = Services.TweenService

workspace = cloneref(workspace) or workspace
local LocalPlayer = Players.LocalPlayer
local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- [3] PLACE IDs CHO TỪNG SEA
local SEA_1 = {["2753915549"]  = true, ["85211729168715"]  = true}
local SEA_2 = {["4442272183"]  = true, ["79091703265657"]  = true}
local SEA_3 = {["7449423635"]  = true, ["100117331123089"] = true}

-- [4] CHARACTER SETUP
local Character, Humanoid, HumanoidRootPart

local function SetupCharacter(char)
    Character        = char
    Humanoid         = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then SetupCharacter(LocalPlayer.Character) end

-- ==========================================================================
-- [TP CHAIR DATA] - Tọa độ ghế từ ảnh
-- ==========================================================================
local CHAIR_DATA = {
    {
        section = "Table 1",
        chairs = {
            {name = "Chair 1", pos = Vector3.new(-463.414, 71.62,  271.042), yaw = 180},
            {name = "Chair 2", pos = Vector3.new(-463.414, 71.619, 282.296), yaw = 0},
        }
    },
    {
        section = "Table 2",
        chairs = {
            {name = "Chair 1", pos = Vector3.new(-297.654, 71.62,  271.042), yaw = 180},
            {name = "Chair 2", pos = Vector3.new(-297.654, 71.619, 282.296), yaw = 0},
        }
    },
}

local function TPToChair(chair)
    if not Character or not HumanoidRootPart then
        StarterGui:SetCore("SendNotification", {
            Title = "TP Chair", Text = "Character chưa sẵn sàng!", Duration = 2
        })
        return
    end
    if Humanoid then Humanoid.Sit = false end
    task.wait(0.05)
    -- TP đến vị trí ghế (lên cao 3 stud để auto-sit khi rơi xuống)
    local cf = CFrame.new(chair.pos) * CFrame.Angles(0, math.rad(chair.yaw), 0)
    HumanoidRootPart.CFrame = cf + Vector3.new(0, 3, 0)
end

-- ==========================================================================
-- [5] STATUS UI
-- ==========================================================================
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("AutoSea2Status")
    if old then old:Destroy() end
end)

local StatusGui = Instance.new("ScreenGui")
StatusGui.Name           = "AutoSea2Status"
StatusGui.ResetOnSpawn   = false
StatusGui.IgnoreGuiInset = true
StatusGui.DisplayOrder   = 999
StatusGui.Parent         = LocalPlayer.PlayerGui

local StatusLabel = Instance.new("TextLabel")
StatusLabel.AnchorPoint            = Vector2.new(0.5, 0)
StatusLabel.Position               = UDim2.new(0.5, 0, 0.04, 0)
StatusLabel.Size                   = UDim2.new(0.5, 0, 0.07, 0)
StatusLabel.BackgroundTransparency = 0.35
StatusLabel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
StatusLabel.BorderSizePixel        = 0
StatusLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
StatusLabel.TextStrokeTransparency = 0.5
StatusLabel.TextScaled             = true
StatusLabel.Font                   = Enum.Font.GothamSemibold
StatusLabel.Text                   = "Đang khởi động..."
StatusLabel.Parent                 = StatusGui

local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 8)
sCorner.Parent       = StatusLabel

local function SetStatus(text)
    StatusLabel.Text = text
    print("[AutoSea2] " .. text)
end

-- ==========================================================================
-- [6] TP CHAIR UI - Panel có 2 categories Table 1 & Table 2
-- ==========================================================================
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("TPChairUI")
    if old then old:Destroy() end
end)

local TPGui = Instance.new("ScreenGui")
TPGui.Name           = "TPChairUI"
TPGui.ResetOnSpawn   = false
TPGui.IgnoreGuiInset = false
TPGui.DisplayOrder   = 1000
TPGui.Parent         = LocalPlayer.PlayerGui

-- ====== Toggle button (icon nhỏ luôn hiện) ======
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size                   = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position               = UDim2.new(1, -65, 0.35, 0)
ToggleBtn.BackgroundColor3       = Color3.fromRGB(45, 50, 70)
ToggleBtn.BorderSizePixel        = 0
ToggleBtn.Text                   = "🪑"
ToggleBtn.TextScaled             = true
ToggleBtn.Font                   = Enum.Font.GothamBold
ToggleBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
ToggleBtn.AutoButtonColor        = true
ToggleBtn.Parent                 = TPGui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 12)
tCorner.Parent       = ToggleBtn

local tStroke = Instance.new("UIStroke")
tStroke.Color     = Color3.fromRGB(80, 120, 200)
tStroke.Thickness = 2
tStroke.Parent    = ToggleBtn

-- ====== Main panel ======
local MainFrame = Instance.new("Frame")
MainFrame.Size              = UDim2.new(0, 240, 0, 320)
MainFrame.Position          = UDim2.new(1, -260, 0.5, -160)
MainFrame.BackgroundColor3  = Color3.fromRGB(28, 30, 38)
MainFrame.BorderSizePixel   = 0
MainFrame.Active            = true
MainFrame.Draggable         = true   -- Cho phép kéo
MainFrame.Visible           = true
MainFrame.Parent            = TPGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 10)
mCorner.Parent       = MainFrame

local mStroke = Instance.new("UIStroke")
mStroke.Color     = Color3.fromRGB(80, 120, 200)
mStroke.Thickness = 1.5
mStroke.Parent    = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size               = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3   = Color3.fromRGB(40, 45, 60)
Header.BorderSizePixel    = 0
Header.Parent             = MainFrame

local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 10)
hCorner.Parent       = Header

local Title = Instance.new("TextLabel")
Title.Size               = UDim2.new(1, -40, 1, 0)
Title.Position           = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text               = "🪑  TP CHAIR"
Title.TextColor3         = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment     = Enum.TextXAlignment.Left
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 15
Title.Parent             = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size              = UDim2.new(0, 28, 0, 28)
CloseBtn.Position          = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundColor3  = Color3.fromRGB(200, 60, 60)
CloseBtn.BorderSizePixel   = 0
CloseBtn.Text              = "✕"
CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 14
CloseBtn.Parent            = Header

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 6)
cCorner.Parent       = CloseBtn

-- Content scrolling area
local Content = Instance.new("ScrollingFrame")
Content.Position             = UDim2.new(0, 8, 0, 44)
Content.Size                 = UDim2.new(1, -16, 1, -52)
Content.BackgroundTransparency = 1
Content.BorderSizePixel      = 0
Content.ScrollBarThickness   = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 200)
Content.CanvasSize           = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
Content.Parent               = MainFrame

local layout = Instance.new("UIListLayout")
layout.SortOrder    = Enum.SortOrder.LayoutOrder
layout.Padding      = UDim.new(0, 6)
layout.Parent       = Content

-- Helper: Tạo section header
local function CreateSectionHeader(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.LayoutOrder            = order
    lbl.Size                   = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundColor3       = Color3.fromRGB(50, 55, 75)
    lbl.BorderSizePixel        = 0
    lbl.Text                   = "▸ " .. text
    lbl.TextColor3             = Color3.fromRGB(180, 200, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Font                   = Enum.Font.GothamSemibold
    lbl.TextSize               = 13
    lbl.Parent                 = Content

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent      = lbl

    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, 6)
    cor.Parent       = lbl
    return lbl
end

-- Helper: Tạo nút TP
local function CreateChairButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder            = order
    btn.Size                   = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3       = Color3.fromRGB(55, 60, 80)
    btn.BorderSizePixel        = 0
    btn.Text                   = "  🎯  " .. text
    btn.TextColor3             = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment         = Enum.TextXAlignment.Left
    btn.Font                   = Enum.Font.Gotham
    btn.TextSize               = 13
    btn.AutoButtonColor        = true
    btn.Parent                 = Content

    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, 6)
    cor.Parent       = btn

    local stk = Instance.new("UIStroke")
    stk.Color        = Color3.fromRGB(80, 120, 200)
    stk.Thickness    = 1
    stk.Transparency = 0.6
    stk.Parent       = btn

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15),
            {BackgroundColor3 = Color3.fromRGB(75, 90, 130)}):Play()
        stk.Transparency = 0.2
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15),
            {BackgroundColor3 = Color3.fromRGB(55, 60, 80)}):Play()
        stk.Transparency = 0.6
    end)

    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then warn("[TP Chair] " .. tostring(err)) end
    end)
    return btn
end

-- Build UI sections
local order = 0
for _, tableData in ipairs(CHAIR_DATA) do
    order = order + 1
    CreateSectionHeader(tableData.section, order)
    for _, chair in ipairs(tableData.chairs) do
        order = order + 1
        local label = tableData.section .. " - " .. chair.name
        CreateChairButton(label, order, function()
            TPToChair(chair)
            StarterGui:SetCore("SendNotification", {
                Title    = "TP Chair",
                Text     = "Đã TP đến " .. label,
                Duration = 2
            })
        end)
    end
end

-- Toggle show/hide
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==========================================================================
-- [7] THÔNG BÁO + ĐỢI GAME FULLY LOADED
-- ==========================================================================
StarterGui:SetCore("SendNotification", {
    Title    = "Executed",
    Text     = "Script loaded - Đang setup...",
    Duration = 5
})

if workspace.DistributedGameTime <= 10 then
    local wait_ = math.floor(10 - workspace.DistributedGameTime)
    SetStatus("Đang chờ game load... (" .. wait_ .. "s)")
    task.wait(wait_)
end

if not COMMF_ then
    SetStatus("Đợi Remote CommF_...")
    repeat task.wait(1) until COMMF_
end

-- ==========================================================================
-- [8] LOAD TEAM (PIRATES)
-- ==========================================================================
SetStatus("Đang chọn team Pirates...")

local function LoadTeam()
    xpcall(function()
        if LocalPlayer.Team then return end
        if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
            repeat task.wait(1)
            until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
        end
        xpcall(function()
            COMMF_:InvokeServer("SetTeam", "Pirates")
        end, function()
            pcall(function()
                firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container.Pirates)
            end)
        end)
        task.wait(2)
    end, function(err) warn("[Team Error]:", err) end)
end

LoadTeam()

SetStatus("Đợi Character spawn...")
repeat task.wait(1)
until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

local teamRetry = 0
while not LocalPlayer.Team and teamRetry < 5 do
    teamRetry = teamRetry + 1
    SetStatus("Retry chọn team... (" .. teamRetry .. "/5)")
    LoadTeam()
    task.wait(2)
end

if not LocalPlayer.Team then
    SetStatus("⚠️ Không chọn được team, tiếp tục...")
else
    SetStatus("✅ Team: " .. tostring(LocalPlayer.Team.Name))
end
task.wait(1)

-- ==========================================================================
-- [9] CHECK SEA - DUAL METHOD
-- ==========================================================================
local function CheckSeaByMap(v)
    local mapAttr = workspace:GetAttribute("MAP")
    if mapAttr then
        return tonumber(mapAttr:match("%d+")) == v
    end
    return false
end

local function CheckSeaByPlaceId(seaTable)
    return seaTable[tostring(game.PlaceId)] == true
end

local function CheckSea(v)
    if CheckSeaByMap(v) then return true end
    if v == 1 then return CheckSeaByPlaceId(SEA_1)
    elseif v == 2 then return CheckSeaByPlaceId(SEA_2)
    elseif v == 3 then return CheckSeaByPlaceId(SEA_3)
    end
    return false
end

local function GetCurrentSea()
    if CheckSea(1) then return 1
    elseif CheckSea(2) then return 2
    elseif CheckSea(3) then return 3
    end
    return 0
end

-- ==========================================================================
-- [10] TRAVEL TO SEA 2
-- ==========================================================================
local function TravelToSea2()
    local maxAttempts = 5
    for attempt = 1, maxAttempts do
        if CheckSea(2) then return true end

        local currentSea = GetCurrentSea()
        SetStatus(string.format("Travel Sea %d → Sea 2 | Lần %d/%d...",
            currentSea, attempt, maxAttempts))

        xpcall(function()
            COMMF_:InvokeServer("TravelDressrosa")
        end, function(err)
            warn("[Travel Error]:", err)
        end)

        task.wait(8)

        local charWait = 0
        while (not Character or not Character:FindFirstChild("HumanoidRootPart")) and charWait < 10 do
            task.wait(1)
            charWait = charWait + 1
        end

        if CheckSea(2) then
            SetStatus("✅ Travel thành công!")
            return true
        end
    end
    return CheckSea(2)
end

-- ==========================================================================
-- [11] MAIN FLOW
-- ==========================================================================
task.wait(2)
SetStatus("Kiểm tra Sea hiện tại...")

local currentSea = GetCurrentSea()
print(string.format("[Sea Check] PlaceId=%s | MAP=%s | Sea=%d",
    tostring(game.PlaceId),
    tostring(workspace:GetAttribute("MAP")),
    currentSea))

if currentSea == 0 then
    SetStatus("⚠️ Không xác định được Sea! (PlaceId không khớp)")
    StarterGui:SetCore("SendNotification", {
        Title = "Sea Check Failed", Text = "PlaceId: " .. tostring(game.PlaceId), Duration = 5
    })
    return
end

if currentSea == 2 then
    SetStatus("✅ Đang ở Sea 2 → Vào phase tiếp theo...")
    task.wait(2)
elseif currentSea == 1 or currentSea == 3 then
    SetStatus(string.format("📍 Sea %d phát hiện → Travel về Sea 2...", currentSea))
    task.wait(2)

    local success = TravelToSea2()
    if not success then
        SetStatus("❌ Travel về Sea 2 thất bại!")
        StarterGui:SetCore("SendNotification", {
            Title = "Travel Failed", Text = "Không travel được về Sea 2", Duration = 5
        })
        return
    end

    repeat task.wait(1)
    until Character
        and Character:FindFirstChild("HumanoidRootPart")
        and CheckSea(2)

    SetStatus("✅ Đã về Sea 2 thành công!")
    task.wait(2)
end

-- ==========================================================================
-- [12] NEXT PHASE - PLACEHOLDER
-- ==========================================================================
SetStatus("🚀 Sẵn sàng | Dùng panel TP Chair bên phải")
StarterGui:SetCore("SendNotification", {
    Title = "Ready", Text = "Setup hoàn tất - Mở panel TP Chair bên phải", Duration = 5
})

print("[AutoSea2] ======================================")
print("[AutoSea2] Setup hoàn tất!")
print("[AutoSea2] Sea hiện tại: 2 | Team: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "None"))
print("[AutoSea2] ======================================")

-- ==========================================================================
-- TODO: CODE PHASE TIẾP THEO CHÈN VÀO ĐÂY
-- ==========================================================================
