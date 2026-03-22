-- ══════════════════════════════════════════
-- KEY CONFIG (Có thể set từ bên ngoài)
-- Dùng ngoài executor: getgenv().Key = "yourkey"
-- rồi loadstring(...)()
-- ══════════════════════════════════════════
if not getgenv().Key then
    getgenv().Key = "" -- Mặc định rỗng, set từ ngoài
end

-- ══════════════════════════════════════════
-- WAIT GAME LOAD (Kaitun Boss style)
-- ══════════════════════════════════════════
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local plr    = Players.LocalPlayer

if workspace.DistributedGameTime <= 10 then
    task.wait(math.max(0, 10 - workspace.DistributedGameTime))
end
if not COMMF_ then repeat task.wait(1) until COMMF_ end

-- Đợi LoadingScreen biến mất
if plr.PlayerGui:FindFirstChild("LoadingScreen") then
    repeat task.wait(1) until not plr.PlayerGui:FindFirstChild("LoadingScreen")
end

-- Đợi Character + Data
repeat task.wait(0.5) until
    plr.Character and
    plr.Character:FindFirstChild("HumanoidRootPart") and
    plr:FindFirstChild("Data") and
    plr.Data:FindFirstChild("Race") and
    plr.Data:FindFirstChild("Fragments")

-- ══════════════════════════════════════════
-- JOIN TEAM (Kaitun Boss style - chuẩn)
-- ══════════════════════════════════════════
task.spawn(function()
    xpcall(function()
        if not plr.Team then
            xpcall(function()
                COMMF_:InvokeServer("SetTeam", "Pirates")
            end, function()
                pcall(function()
                    firesignal(
                        plr.PlayerGui["Main (minimal)"].ChooseTeam.Container.Pirates
                    )
                end)
            end)
            task.wait(2)
        end
    end, function(err) warn("Team:", err) end)
end)

-- ══════════════════════════════════════════
-- HÀM LẤY THÔNG TIN PLAYER
-- ══════════════════════════════════════════
local function GetRace()
    local ok, race = pcall(function() return tostring(plr.Data.Race.Value) end)
    if ok and race and race ~= "" then return race end
    return "Unknown"
end

local function GetRaceVersion()
    local char = plr.Character
    if not char then return "V1" end

    local ok4, v4 = pcall(function() return plr.Data.Race:FindFirstChild("V4") end)
    if ok4 and v4 then return "V4" end

    local ok3, v3 = pcall(function()
        return plr.Data.Race:FindFirstChild("V3") or char:FindFirstChild("RaceTransformed")
    end)
    if ok3 and v3 then return "V3" end

    local ok2, v2 = pcall(function() return plr.Data.Race:FindFirstChild("Evolved") end)
    if ok2 and v2 then return "V2" end

    return "V1"
end

local function GetFragment()
    local ok, val = pcall(function() return plr.Data.Fragments.Value end)
    if ok then return tostring(val) end
    return "0"
end

local function GetPullStatus()
    local ok, result = pcall(function()
        return COMMF_:InvokeServer("templedoorcheck")
    end)
    if ok and result then return "✅ Đã Gạt" end
    return "❌ Chưa Gạt"
end

-- ══════════════════════════════════════════
-- STATUS
-- ══════════════════════════════════════════
local CurrentStatus = "Đang khởi động..."
local function SetStatus(txt) CurrentStatus = txt end

-- ══════════════════════════════════════════
-- TẠO GUI
-- ══════════════════════════════════════════
local oldGui = plr.PlayerGui:FindFirstChild("__SUI__")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "__SUI__"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = plr.PlayerGui

-- Main Frame
local Main = Instance.new("Frame")
Main.Name                   = "Main"
Main.Size                   = UDim2.new(0, 215, 0, 192)
Main.Position               = UDim2.new(0, 18, 0.5, -96)
Main.BackgroundColor3       = Color3.fromRGB(8, 8, 8)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel        = 0
Main.ClipsDescendants       = true
Main.Active                 = true  -- cần để kéo được
Main.Parent                 = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 7)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color     = Color3.fromRGB(200, 160, 30)
Stroke.Thickness = 1.8

-- TopBar (kéo UI)
local TopBar = Instance.new("Frame", Main)
TopBar.Name             = "TopBar"
TopBar.Size             = UDim2.new(1, 0, 0, 26)
TopBar.Position         = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TopBar.BackgroundTransparency = 0
TopBar.BorderSizePixel  = 0
TopBar.Active           = true
TopBar.ZIndex           = 5

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 7)

-- Gradient accent line dưới TopBar
local AccentLine = Instance.new("Frame", Main)
AccentLine.Name             = "AccentLine"
AccentLine.Size             = UDim2.new(1, 0, 0, 2)
AccentLine.Position         = UDim2.new(0, 0, 0, 26)
AccentLine.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
AccentLine.BorderSizePixel  = 0

local AccGrad = Instance.new("UIGradient", AccentLine)
AccGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 210, 60)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 210, 60)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
})

-- Chấm trang trí topbar
local Dots = Instance.new("TextLabel", TopBar)
Dots.Size                   = UDim2.new(0, 40, 1, 0)
Dots.Position               = UDim2.new(1, -44, 0, 0)
Dots.BackgroundTransparency = 1
Dots.Font                   = Enum.Font.GothamBold
Dots.TextSize               = 12
Dots.TextColor3             = Color3.fromRGB(200, 160, 30)
Dots.Text                   = "• • •"
Dots.ZIndex                 = 6

-- Status Label (trong topbar)
local StatusLabel = Instance.new("TextLabel", TopBar)
StatusLabel.Name            = "StatusLabel"
StatusLabel.Size            = UDim2.new(1, -50, 1, 0)
StatusLabel.Position        = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font            = Enum.Font.GothamBold
StatusLabel.TextSize        = 11
StatusLabel.TextColor3      = Color3.fromRGB(200, 160, 30)
StatusLabel.TextXAlignment  = Enum.TextXAlignment.Left
StatusLabel.TextTruncate    = Enum.TextTruncate.AtEnd
StatusLabel.Text            = "◈  " .. CurrentStatus
StatusLabel.ZIndex          = 6

-- Divider dưới topbar
local Divider = Instance.new("Frame", Main)
Divider.Name             = "Divider"
Divider.Size             = UDim2.new(1, -14, 0, 1)
Divider.Position         = UDim2.new(0, 7, 0, 32)
Divider.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
Divider.BackgroundTransparency = 0.55
Divider.BorderSizePixel  = 0

local DivGrad = Instance.new("UIGradient", Divider)
DivGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(200, 160, 30)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 160, 30)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
})

-- ─── HÀM TẠO ROW ───
local function MakeRow(yPos, key, value)
    local row = Instance.new("Frame", Main)
    row.Name                   = "Row_" .. key
    row.Size                   = UDim2.new(1, -14, 0, 27)
    row.Position               = UDim2.new(0, 7, 0, yPos)
    row.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel        = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local kL = Instance.new("TextLabel", row)
    kL.Size               = UDim2.new(0.48, 0, 1, 0)
    kL.Position           = UDim2.new(0, 8, 0, 0)
    kL.BackgroundTransparency = 1
    kL.Font               = Enum.Font.Gotham
    kL.TextSize           = 11
    kL.TextColor3         = Color3.fromRGB(160, 160, 160)
    kL.TextXAlignment     = Enum.TextXAlignment.Left
    kL.Text               = key

    local vL = Instance.new("TextLabel", row)
    vL.Size               = UDim2.new(0.52, -8, 1, 0)
    vL.Position           = UDim2.new(0.48, 0, 0, 0)
    vL.BackgroundTransparency = 1
    vL.Font               = Enum.Font.GothamBold
    vL.TextSize           = 11
    vL.TextColor3         = Color3.fromRGB(230, 185, 50)
    vL.TextXAlignment     = Enum.TextXAlignment.Right
    vL.Text               = value

    return vL
end

local startY = 38
local gap    = 34

local ValRace     = MakeRow(startY + gap * 0, "Race :",     "...")
local ValRaceV    = MakeRow(startY + gap * 1, "Race V :",   "...")
local ValFragment = MakeRow(startY + gap * 2, "Fragment :", "...")
local ValPull     = MakeRow(startY + gap * 3, "Pull :",     "...")

-- ══════════════════════════════════════════
-- KÉO UI (Drag)
-- ══════════════════════════════════════════
do
    local dragging, dragStart, startPos = false, nil, nil

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
        end
    end)

    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════
-- TOGGLE BẰNG ALT
-- ══════════════════════════════════════════
local isVisible = true
local FULL_SIZE = UDim2.new(0, 215, 0, 192)
local HIDE_SIZE = UDim2.new(0, 215, 0, 26)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt
    or input.KeyCode == Enum.KeyCode.RightAlt then
        isVisible = not isVisible

        TweenService:Create(Main,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = isVisible and FULL_SIZE or HIDE_SIZE }
        ):Play()

        -- Ẩn/hiện nội dung bên dưới topbar
        for _, child in ipairs(Main:GetChildren()) do
            if child.Name ~= "TopBar"
            and child.Name ~= "AccentLine" then
                child.Visible = isVisible
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
            ValRace.Text     = GetRace()
            ValRaceV.Text    = GetRaceVersion()
            ValFragment.Text = GetFragment()

            if tick() - lastPullCheck >= 5 then
                lastPullCheck = tick()
                task.spawn(function()
                    pcall(function() ValPull.Text = GetPullStatus() end)
                end)
            end

            StatusLabel.Text = "◈  " .. CurrentStatus
        end)
    end
end)

-- ══════════════════════════════════════════
-- PHẦN A: AUTO CHECK RACE GHOUL
-- ══════════════════════════════════════════
task.spawn(function()
    task.wait(2) -- Đợi UI ổn định

    local race = GetRace()

    if race ~= "Ghoul" then
        -- Không phải Ghoul → chạy script lấy Ghoul
        SetStatus("Race chưa phải Ghoul, đang lấy...")

        -- Ghép key từ bên ngoài vào Config
        getgenv().Config = getgenv().Config or {}
        getgenv().Config["Auto Get Ghoul"]      = true
        getgenv().Config["Hop Server Get Ghoul"] = true

        -- Key được giữ từ getgenv().Key (set từ ngoài)
        -- getgenv().Key đã được set ở đầu file

        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"
            ))()
        end)

    else
        -- Đã là Ghoul → bỏ qua, vào phần B
        SetStatus("Race: Ghoul ✅ - Sẵn sàng")
        -- TODO: Phần B sẽ được thêm vào đây
    end
end)

print("[UI] Loaded | ALT = ẩn/hiện | Key =", getgenv().Key ~= "" and getgenv().Key or "(chưa set)")
