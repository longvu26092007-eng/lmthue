-- ══════════════════════════════════════════
-- WAIT GAME LOAD (Kaitun Boss style)
-- ══════════════════════════════════════════
if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    task.wait(math.max(0, 10 - workspace.DistributedGameTime))
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local plr    = Players.LocalPlayer

-- Đợi Data sẵn sàng
repeat task.wait(0.5) until
    plr.Character and
    plr.Character:FindFirstChild("HumanoidRootPart") and
    plr:FindFirstChild("Data") and
    plr.Data:FindFirstChild("Race") and
    plr.Data:FindFirstChild("Fragments")

-- ══════════════════════════════════════════
-- JOIN TEAM (Kaitun Boss style)
-- ══════════════════════════════════════════
task.spawn(function()
    xpcall(function()
        if not plr.Team then
            if plr.PlayerGui:FindFirstChild("LoadingScreen") then
                repeat task.wait(1) until not plr.PlayerGui:FindFirstChild("LoadingScreen")
            end
            xpcall(function()
                COMMF_:InvokeServer("SetTeam", "Pirates")
            end, function()
                pcall(function()
                    firesignal(plr.PlayerGui["Main (minimal)"].ChooseTeam.Container.Pirates)
                end)
            end)
        end
    end, function(err) warn("Team:", err) end)
end)

-- ══════════════════════════════════════════
-- STATUS HIỆN TẠI (bước đang làm)
-- ══════════════════════════════════════════
local CurrentStatus = "Đang khởi động..."

local function SetStatus(txt)
    CurrentStatus = txt
end

-- ══════════════════════════════════════════
-- HÀM LẤY THÔNG TIN PLAYER
-- ══════════════════════════════════════════

-- Lấy Race
local function GetRace()
    local ok, race = pcall(function()
        return tostring(plr.Data.Race.Value)
    end)
    if ok and race and race ~= "" then return race end
    return "Unknown"
end

-- Lấy Race Version (V1/V2/V3/V4)
local function GetRaceVersion()
    local char = plr.Character
    if not char then return "V1" end

    -- V4 check
    if pcall(function()
        return plr.Data.Race:FindFirstChild("V4") or char:FindFirstChild("RaceV4")
    end) then
        local ok, v4 = pcall(function()
            return plr.Data.Race:FindFirstChild("V4")
        end)
        if ok and v4 then return "V4" end
    end

    -- V3 check
    local ok3, v3 = pcall(function()
        return plr.Data.Race:FindFirstChild("V3") or char:FindFirstChild("RaceTransformed")
    end)
    if ok3 and v3 then return "V3" end

    -- V2 check (Evolved)
    local ok2, v2 = pcall(function()
        return plr.Data.Race:FindFirstChild("Evolved")
    end)
    if ok2 and v2 then return "V2" end

    return "V1"
end

-- Lấy Fragment
local function GetFragment()
    local ok, val = pcall(function()
        return plr.Data.Fragments.Value
    end)
    if ok then return tostring(val) end
    return "0"
end

-- Lấy Pull Status (Đã gạt cần hay chưa)
local function GetPullStatus()
    local ok, result = pcall(function()
        return COMMF_:InvokeServer("templedoorcheck")
    end)
    if ok and result then
        return "✅ Đã Gạt"
    end
    return "❌ Chưa Gạt"
end

-- ══════════════════════════════════════════
-- TẠO GUI
-- ══════════════════════════════════════════
-- Xóa UI cũ nếu tồn tại
local oldGui = plr.PlayerGui:FindFirstChild("__SUI__")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name       = "__SUI__"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = plr.PlayerGui

-- Main Frame
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 210, 0, 185)
Main.Position         = UDim2.new(0, 18, 0.5, -92)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = ScreenGui

-- Bo góc
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 7)
Corner.Parent = Main

-- Viền vàng
local Stroke = Instance.new("UIStroke")
Stroke.Color     = Color3.fromRGB(200, 160, 30)
Stroke.Thickness = 1.8
Stroke.Parent    = Main

-- Accent bar vàng trên đầu
local TopBar = Instance.new("Frame")
TopBar.Name             = "TopBar"
TopBar.Size             = UDim2.new(1, 0, 0, 3)
TopBar.Position         = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
TopBar.BorderSizePixel  = 0
TopBar.Parent           = Main

local TopGrad = Instance.new("UIGradient")
TopGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 210, 60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 155, 20)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 210, 60)),
})
TopGrad.Parent = TopBar

-- ─── STATUS TEXT ───
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name            = "StatusLabel"
StatusLabel.Size            = UDim2.new(1, -14, 0, 20)
StatusLabel.Position        = UDim2.new(0, 7, 0, 6)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font            = Enum.Font.GothamBold
StatusLabel.TextSize        = 11
StatusLabel.TextColor3      = Color3.fromRGB(200, 160, 30)
StatusLabel.TextXAlignment  = Enum.TextXAlignment.Left
StatusLabel.TextTruncate    = Enum.TextTruncate.AtEnd
StatusLabel.Text            = "◈  " .. CurrentStatus
StatusLabel.Parent          = Main

-- ─── DIVIDER ───
local Divider = Instance.new("Frame")
Divider.Name             = "Divider"
Divider.Size             = UDim2.new(1, -14, 0, 1)
Divider.Position         = UDim2.new(0, 7, 0, 30)
Divider.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
Divider.BackgroundTransparency = 0.5
Divider.BorderSizePixel  = 0
Divider.Parent           = Main

local DivGrad = Instance.new("UIGradient")
DivGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(200, 160, 30)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 160, 30)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
})
DivGrad.Parent = Divider

-- ─── HÀM TẠO ROW ───
local function MakeRow(parent, yPos, key, value)
    local row = Instance.new("Frame")
    row.Name                    = "Row_" .. key
    row.Size                    = UDim2.new(1, -14, 0, 26)
    row.Position                = UDim2.new(0, 7, 0, yPos)
    row.BackgroundColor3        = Color3.fromRGB(18, 18, 18)
    row.BackgroundTransparency  = 0.3
    row.BorderSizePixel         = 0
    row.Parent                  = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 4)
    rowCorner.Parent = row

    -- Key (bên trái)
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name               = "Key"
    keyLabel.Size               = UDim2.new(0.45, 0, 1, 0)
    keyLabel.Position           = UDim2.new(0, 7, 0, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Font               = Enum.Font.Gotham
    keyLabel.TextSize           = 11
    keyLabel.TextColor3         = Color3.fromRGB(170, 170, 170)
    keyLabel.TextXAlignment     = Enum.TextXAlignment.Left
    keyLabel.Text               = key
    keyLabel.Parent             = row

    -- Value (bên phải)
    local valLabel = Instance.new("TextLabel")
    valLabel.Name               = "Val"
    valLabel.Size               = UDim2.new(0.55, -7, 1, 0)
    valLabel.Position           = UDim2.new(0.45, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Font               = Enum.Font.GothamBold
    valLabel.TextSize           = 11
    valLabel.TextColor3         = Color3.fromRGB(230, 185, 50)
    valLabel.TextXAlignment     = Enum.TextXAlignment.Right
    valLabel.Text               = value
    valLabel.Parent             = row

    return valLabel -- trả về để update sau
end

-- Tạo 4 rows: Race, Race V, Fragment, Pull
local startY = 37
local gap    = 32

local ValRace     = MakeRow(Main, startY + gap * 0, "Race :",     "...")
local ValRaceV    = MakeRow(Main, startY + gap * 1, "Race V :",   "...")
local ValFragment = MakeRow(Main, startY + gap * 2, "Fragment :", "...")
local ValPull     = MakeRow(Main, startY + gap * 3, "Pull :",     "...")

-- ══════════════════════════════════════════
-- TOGGLE BẰNG ALT
-- ══════════════════════════════════════════
local isVisible = true

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        isVisible = not isVisible
        local targetSize  = isVisible and UDim2.new(0, 210, 0, 185) or UDim2.new(0, 210, 0, 3)
        local targetTrans = isVisible and 0.08 or 1

        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Size = targetSize,
            BackgroundTransparency = targetTrans,
        }):Play()

        -- Ẩn/hiện con
        for _, child in ipairs(Main:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("Frame") then
                if child.Name ~= "TopBar" then
                    TweenService:Create(child, TweenInfo.new(0.2), {
                        BackgroundTransparency = isVisible and
                            (child:IsA("Frame") and 0.3 or 1) or 1,
                    }):Play()
                    if child:IsA("TextLabel") then
                        child.Visible = isVisible
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- UPDATE LOOP
-- ══════════════════════════════════════════
local lastPullCheck = 0

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            -- Race
            ValRace.Text = GetRace()

            -- Race V
            ValRaceV.Text = GetRaceVersion()

            -- Fragment
            ValFragment.Text = GetFragment()

            -- Pull (check mỗi 5 giây để tránh spam remote)
            if tick() - lastPullCheck >= 5 then
                lastPullCheck = tick()
                task.spawn(function()
                    pcall(function()
                        ValPull.Text = GetPullStatus()
                    end)
                end)
            end

            -- Cập nhật status label
            StatusLabel.Text = "◈  " .. CurrentStatus
        end)
    end
end)

-- ══════════════════════════════════════════
-- GỌI SetStatus từ bên ngoài để cập nhật
-- ══════════════════════════════════════════
-- Ví dụ: SetStatus("Đang farm level...")
--        SetStatus("Đang gạt cần...")
--        SetStatus("Chờ boss spawn...")

SetStatus("Sẵn sàng")
print("[UI] Status UI loaded - ALT để ẩn/hiện")
