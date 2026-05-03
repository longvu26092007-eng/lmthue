-- ==========================================================================
-- AUTO TRAVEL TO SEA 2 + LUXURY TP CHAIR UI + AUTO TWEEN MANAGER
-- Flow:
--   1. Game load → Team Pirates → Check Sea
--   2. Sea 1/3 → Travel Sea 2
--   3. Sea 2 → Auto Tween đến Manager NPC (-384, 72, 332)
-- UI: Single luxury panel với RGB animated border, status tích hợp
-- ==========================================================================

repeat task.wait(0.5)
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

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
local RunService         = Services.RunService

workspace = cloneref(workspace) or workspace
local LocalPlayer = Players.LocalPlayer
local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local SEA_1 = {["2753915549"]  = true, ["85211729168715"]  = true}
local SEA_2 = {["4442272183"]  = true, ["79091703265657"]  = true}
local SEA_3 = {["7449423635"]  = true, ["100117331123089"] = true}

-- ===== TỌA ĐỘ MANAGER NPC =====
local MANAGER_POSITION = Vector3.new(-384.014, 72.458, 332.468)

local Character, Humanoid, HumanoidRootPart

local function SetupCharacter(char)
    Character        = char
    Humanoid         = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then SetupCharacter(LocalPlayer.Character) end

-- ==========================================================================
-- TWEEN SYSTEM (rút gọn từ autoleviathan.lua)
-- ==========================================================================
local activeTween, activeConn, ghostPart = nil, nil, nil
local isTweening = false

local function CancelTween()
    if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
    if activeConn then activeConn:Disconnect() activeConn = nil end
    if ghostPart then ghostPart:Destroy() ghostPart = nil end
    isTweening = false
end

-- Tween HumanoidRootPart đến targetCFrame với speed (studs/s)
-- Dùng ghost part + heartbeat để né anti-cheat (giống logic autoleviathan)
local function TweenTo(targetCFrame, speed, onComplete)
    speed = speed or 275
    if typeof(targetCFrame) == "Vector3" then
        targetCFrame = CFrame.new(targetCFrame)
    end

    CancelTween()
    if not Character or not HumanoidRootPart then
        if onComplete then onComplete(false) end
        return
    end
    if Humanoid then Humanoid.Sit = false end

    local startCF  = HumanoidRootPart.CFrame
    local distance = (targetCFrame.Position - startCF.Position).Magnitude

    -- Quá gần → TP luôn
    if distance < 50 then
        HumanoidRootPart.CFrame = targetCFrame
        if onComplete then onComplete(true) end
        return
    end

    isTweening = true
    ghostPart = Instance.new("Part")
    ghostPart.Name         = "TweenGhost"
    ghostPart.Size         = Vector3.new(2, 2, 2)
    ghostPart.Transparency = 1
    ghostPart.Anchored     = true
    ghostPart.CanCollide   = false
    ghostPart.CFrame       = startCF
    ghostPart.Parent       = workspace

    local duration = math.max(distance / speed, 0.3)
    activeTween = TweenService:Create(
        ghostPart,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame + Vector3.new(0, 5, 0)}
    )

    activeConn = RunService.Heartbeat:Connect(function()
        if HumanoidRootPart and ghostPart then
            HumanoidRootPart.CFrame = ghostPart.CFrame
        end
    end)

    activeTween.Completed:Connect(function()
        CancelTween()
        if onComplete then onComplete(true) end
    end)

    activeTween:Play()
end

-- ==========================================================================
-- CHAIR DATA
-- ==========================================================================
local CHAIR_DATA = {
    {
        section = "TABLE 1",
        chairs = {
            {name = "Chair 1", pos = Vector3.new(-463.414, 71.62,  271.042), yaw = 180},
            {name = "Chair 2", pos = Vector3.new(-463.414, 71.619, 282.296), yaw = 0},
        }
    },
    {
        section = "TABLE 2",
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
    CancelTween()  -- Hủy tween đang chạy nếu có
    if Humanoid then Humanoid.Sit = false end
    task.wait(0.05)
    local cf = CFrame.new(chair.pos) * CFrame.Angles(0, math.rad(chair.yaw), 0)
    HumanoidRootPart.CFrame = cf + Vector3.new(0, 3, 0)
end

-- ==========================================================================
-- RGB ANIMATION REGISTRY
-- ==========================================================================
local RGBObjects = {}
local RGB_SPEED  = 0.18

local function RegisterRGB(stroke, hueOffset, sat, val)
    table.insert(RGBObjects, {
        obj    = stroke,
        offset = hueOffset or 0,
        sat    = sat or 0.85,
        val    = val or 1
    })
end

local rgbStartTime = tick()
RunService.RenderStepped:Connect(function()
    local elapsed = tick() - rgbStartTime
    for i = #RGBObjects, 1, -1 do
        local r = RGBObjects[i]
        if r.obj and r.obj.Parent then
            local hue = (elapsed * RGB_SPEED + r.offset) % 1
            r.obj.Color = Color3.fromHSV(hue, r.sat, r.val)
        else
            table.remove(RGBObjects, i)
        end
    end
end)

-- ==========================================================================
-- LUXURY UI
-- ==========================================================================
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("LuxuryTPGui")
    if old then old:Destroy() end
    local oldStatus = LocalPlayer.PlayerGui:FindFirstChild("AutoSea2Status")
    if oldStatus then oldStatus:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "LuxuryTPGui"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder   = 1000
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = LocalPlayer.PlayerGui

-- Toggle button
local Toggle = Instance.new("TextButton")
Toggle.Size                   = UDim2.new(0, 54, 0, 54)
Toggle.Position               = UDim2.new(1, -70, 0.32, 0)
Toggle.BackgroundColor3       = Color3.fromRGB(18, 20, 28)
Toggle.BorderSizePixel        = 0
Toggle.Text                   = "🪑"
Toggle.TextSize               = 26
Toggle.Font                   = Enum.Font.GothamBold
Toggle.TextColor3             = Color3.fromRGB(255, 255, 255)
Toggle.TextStrokeTransparency = 0.4
Toggle.AutoButtonColor        = false
Toggle.Parent                 = Gui

local toggleCorner = Instance.new("UICorner", Toggle)
toggleCorner.CornerRadius = UDim.new(0, 14)

local toggleGrad = Instance.new("UIGradient", Toggle)
toggleGrad.Rotation = 90
toggleGrad.Color    = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(35, 38, 55)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(15, 17, 25)),
}

local toggleStroke = Instance.new("UIStroke", Toggle)
toggleStroke.Thickness        = 2.5
toggleStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
RegisterRGB(toggleStroke, 0)

Toggle.MouseEnter:Connect(function()
    TweenService:Create(Toggle, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
end)
Toggle.MouseLeave:Connect(function()
    TweenService:Create(Toggle, TweenInfo.new(0.2), {Size = UDim2.new(0, 54, 0, 54)}):Play()
end)

-- Main panel
local Panel = Instance.new("Frame")
Panel.Size               = UDim2.new(0, 280, 0, 440)
Panel.Position           = UDim2.new(1, -300, 0.5, -220)
Panel.BackgroundColor3   = Color3.fromRGB(12, 14, 22)
Panel.BorderSizePixel    = 0
Panel.Active             = true
Panel.Draggable          = true
Panel.Visible            = true
Panel.Parent             = Gui

local panelCorner = Instance.new("UICorner", Panel)
panelCorner.CornerRadius = UDim.new(0, 16)

local panelGrad = Instance.new("UIGradient", Panel)
panelGrad.Rotation = 135
panelGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(22, 25, 38)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 16, 24)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 11, 18)),
}

local panelStroke = Instance.new("UIStroke", Panel)
panelStroke.Thickness        = 2.5
panelStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
RegisterRGB(panelStroke, 0, 0.9, 1)

local shadow = Instance.new("Frame")
shadow.Size                   = UDim2.new(1, 16, 1, 16)
shadow.Position               = UDim2.new(0, -8, 0, -8)
shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel        = 0
shadow.ZIndex                 = 0
shadow.Parent                 = Panel
local shCorner = Instance.new("UICorner", shadow)
shCorner.CornerRadius = UDim.new(0, 22)

-- Header
local Header = Instance.new("Frame")
Header.Size              = UDim2.new(1, -20, 0, 44)
Header.Position          = UDim2.new(0, 10, 0, 10)
Header.BackgroundColor3  = Color3.fromRGB(20, 23, 35)
Header.BorderSizePixel   = 0
Header.Parent            = Panel

local hCorner = Instance.new("UICorner", Header)
hCorner.CornerRadius = UDim.new(0, 10)

local hGrad = Instance.new("UIGradient", Header)
hGrad.Rotation = 0
hGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(28, 32, 48)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(18, 20, 30)),
}

local Title = Instance.new("TextLabel")
Title.Size                       = UDim2.new(1, -50, 1, 0)
Title.Position                   = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency     = 1
Title.Text                       = "✨ LUXURY TP"
Title.TextColor3                 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment             = Enum.TextXAlignment.Left
Title.Font                       = Enum.Font.GothamBold
Title.TextSize                   = 16
Title.TextStrokeTransparency     = 0.6
Title.Parent                     = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size              = UDim2.new(0, 30, 0, 30)
CloseBtn.Position          = UDim2.new(1, -36, 0.5, -15)
CloseBtn.BackgroundColor3  = Color3.fromRGB(180, 50, 50)
CloseBtn.BorderSizePixel   = 0
CloseBtn.Text              = "✕"
CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 15
CloseBtn.AutoButtonColor   = false
CloseBtn.Parent            = Header
local cCorner = Instance.new("UICorner", CloseBtn)
cCorner.CornerRadius = UDim.new(0, 8)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15),
        {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15),
        {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()
end)

-- Status section
local StatusFrame = Instance.new("Frame")
StatusFrame.Size              = UDim2.new(1, -20, 0, 70)
StatusFrame.Position          = UDim2.new(0, 10, 0, 64)
StatusFrame.BackgroundColor3  = Color3.fromRGB(16, 18, 28)
StatusFrame.BorderSizePixel   = 0
StatusFrame.Parent            = Panel

local stCorner = Instance.new("UICorner", StatusFrame)
stCorner.CornerRadius = UDim.new(0, 10)

local stGrad = Instance.new("UIGradient", StatusFrame)
stGrad.Rotation = 90
stGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 22, 34)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 14, 22)),
}

local statusStroke = Instance.new("UIStroke", StatusFrame)
statusStroke.Thickness        = 1.8
statusStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
RegisterRGB(statusStroke, 0.33, 0.85, 1)

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size               = UDim2.new(1, -16, 0, 16)
StatusTitle.Position           = UDim2.new(0, 12, 0, 6)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text               = "● STATUS"
StatusTitle.TextColor3         = Color3.fromRGB(140, 200, 255)
StatusTitle.TextXAlignment     = Enum.TextXAlignment.Left
StatusTitle.Font               = Enum.Font.GothamBold
StatusTitle.TextSize           = 11
StatusTitle.Parent             = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size                       = UDim2.new(1, -20, 1, -28)
StatusLabel.Position                   = UDim2.new(0, 10, 0, 24)
StatusLabel.BackgroundTransparency     = 1
StatusLabel.Text                       = "Đang khởi động..."
StatusLabel.TextColor3                 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextXAlignment             = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment             = Enum.TextYAlignment.Center
StatusLabel.Font                       = Enum.Font.GothamBold
StatusLabel.TextSize                   = 13
StatusLabel.TextStrokeTransparency     = 0.7
StatusLabel.TextStrokeColor3           = Color3.fromRGB(0, 0, 0)
StatusLabel.TextWrapped                = true
StatusLabel.RichText                   = true
StatusLabel.Parent                     = StatusFrame

local function SetStatus(text)
    StatusLabel.Text = text
    print("[AutoSea2] " .. text)
end

-- Content scroll
local Content = Instance.new("ScrollingFrame")
Content.Position             = UDim2.new(0, 10, 0, 144)
Content.Size                 = UDim2.new(1, -20, 1, -154)
Content.BackgroundTransparency = 1
Content.BorderSizePixel      = 0
Content.ScrollBarThickness   = 5
Content.ScrollBarImageColor3 = Color3.fromRGB(120, 160, 240)
Content.CanvasSize           = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
Content.Parent               = Panel

local layout = Instance.new("UIListLayout", Content)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding   = UDim.new(0, 8)

local contentPad = Instance.new("UIPadding", Content)
contentPad.PaddingTop    = UDim.new(0, 4)
contentPad.PaddingBottom = UDim.new(0, 4)

local function CreateSectionHeader(text, order, hueOffset)
    local frame = Instance.new("Frame")
    frame.LayoutOrder           = order
    frame.Size                  = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3      = Color3.fromRGB(22, 25, 38)
    frame.BorderSizePixel       = 0
    frame.Parent                = Content

    local cor = Instance.new("UICorner", frame)
    cor.CornerRadius = UDim.new(0, 8)

    local g = Instance.new("UIGradient", frame)
    g.Rotation = 0
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(30, 35, 55)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(18, 20, 32)),
    }

    local s = Instance.new("UIStroke", frame)
    s.Thickness        = 1.2
    s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    RegisterRGB(s, hueOffset or 0.5, 0.8, 1)

    local dot = Instance.new("Frame")
    dot.Size               = UDim2.new(0, 6, 0, 6)
    dot.Position           = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel    = 0
    dot.Parent             = frame
    local dCor = Instance.new("UICorner", dot)
    dCor.CornerRadius = UDim.new(1, 0)
    local dStroke = Instance.new("UIStroke", dot)
    dStroke.Thickness = 1
    RegisterRGB(dStroke, hueOffset or 0.5, 1, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size                       = UDim2.new(1, -28, 1, 0)
    lbl.Position                   = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency     = 1
    lbl.Text                       = text
    lbl.TextColor3                 = Color3.fromRGB(220, 230, 255)
    lbl.TextXAlignment             = Enum.TextXAlignment.Left
    lbl.Font                       = Enum.Font.GothamBold
    lbl.TextSize                   = 13
    lbl.TextStrokeTransparency     = 0.7
    lbl.Parent                     = frame
    return frame
end

local function CreateChairButton(text, order, hueOffset, callback)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder            = order
    btn.Size                   = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3       = Color3.fromRGB(22, 25, 38)
    btn.BorderSizePixel        = 0
    btn.Text                   = ""
    btn.AutoButtonColor        = false
    btn.Parent                 = Content

    local cor = Instance.new("UICorner", btn)
    cor.CornerRadius = UDim.new(0, 10)

    local grad = Instance.new("UIGradient", btn)
    grad.Rotation = 90
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(38, 42, 60)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(22, 25, 38)),
    }

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness        = 1.5
    stroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    RegisterRGB(stroke, hueOffset, 0.85, 1)

    local icon = Instance.new("TextLabel")
    icon.Size               = UDim2.new(0, 30, 1, 0)
    icon.Position           = UDim2.new(0, 8, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text               = "🎯"
    icon.TextColor3         = Color3.fromRGB(255, 255, 255)
    icon.Font               = Enum.Font.GothamBold
    icon.TextSize           = 18
    icon.Parent             = btn

    local label = Instance.new("TextLabel")
    label.Size                       = UDim2.new(1, -50, 1, 0)
    label.Position                   = UDim2.new(0, 42, 0, 0)
    label.BackgroundTransparency     = 1
    label.Text                       = text
    label.TextColor3                 = Color3.fromRGB(245, 250, 255)
    label.TextXAlignment             = Enum.TextXAlignment.Left
    label.Font                       = Enum.Font.GothamBold
    label.TextSize                   = 13
    label.TextStrokeTransparency     = 0.75
    label.TextStrokeColor3           = Color3.fromRGB(0, 0, 0)
    label.Parent                     = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size               = UDim2.new(0, 24, 1, 0)
    arrow.Position           = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text               = "›"
    arrow.TextColor3         = Color3.fromRGB(180, 200, 255)
    arrow.TextTransparency   = 0.5
    arrow.Font               = Enum.Font.GothamBold
    arrow.TextSize           = 22
    arrow.Parent             = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18),
            {Size = UDim2.new(1, 0, 0, 46)}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.18),
            {TextTransparency = 0, Position = UDim2.new(1, -24, 0, 0)}):Play()
        stroke.Thickness = 2.2
        grad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(55, 62, 88)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(30, 34, 50)),
        }
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18),
            {Size = UDim2.new(1, 0, 0, 42)}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.18),
            {TextTransparency = 0.5, Position = UDim2.new(1, -28, 0, 0)}):Play()
        stroke.Thickness = 1.5
        grad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(38, 42, 60)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(22, 25, 38)),
        }
    end)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08),
            {Size = UDim2.new(1, 0, 0, 38)}):Play()
        task.delay(0.08, function()
            TweenService:Create(btn, TweenInfo.new(0.12),
                {Size = UDim2.new(1, 0, 0, 46)}):Play()
        end)
        local ok, err = pcall(callback)
        if not ok then warn("[TP Chair] " .. tostring(err)) end
    end)

    return btn
end

local order = 0
local hueStep = 0.15
for tIdx, tableData in ipairs(CHAIR_DATA) do
    order = order + 1
    CreateSectionHeader(tableData.section, order, (tIdx - 1) * 0.5)
    for cIdx, chair in ipairs(tableData.chairs) do
        order = order + 1
        local label = tableData.section .. " - " .. chair.name
        local hueOff = ((tIdx - 1) * 0.5) + ((cIdx - 1) * hueStep)
        CreateChairButton(label, order, hueOff, function()
            TPToChair(chair)
            StarterGui:SetCore("SendNotification", {
                Title    = "TP Chair",
                Text     = "Đã TP đến " .. label,
                Duration = 2
            })
        end)
    end
end

CloseBtn.MouseButton1Click:Connect(function() Panel.Visible = false end)
Toggle.MouseButton1Click:Connect(function() Panel.Visible = not Panel.Visible end)

-- ==========================================================================
-- LOGIC FLOW
-- ==========================================================================
StarterGui:SetCore("SendNotification", {
    Title = "Executed", Text = "Luxury TP Loaded ✨", Duration = 5
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

-- LOAD TEAM
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
    SetStatus("⚠️ Không chọn được team")
else
    SetStatus("✅ Team: " .. tostring(LocalPlayer.Team.Name))
end
task.wait(1)

-- CHECK SEA
local function CheckSeaByMap(v)
    local mapAttr = workspace:GetAttribute("MAP")
    if mapAttr then return tonumber(mapAttr:match("%d+")) == v end
    return false
end
local function CheckSeaByPlaceId(seaTable)
    return seaTable[tostring(game.PlaceId)] == true
end
local function CheckSea(v)
    if CheckSeaByMap(v) then return true end
    if v == 1 then return CheckSeaByPlaceId(SEA_1)
    elseif v == 2 then return CheckSeaByPlaceId(SEA_2)
    elseif v == 3 then return CheckSeaByPlaceId(SEA_3) end
    return false
end
local function GetCurrentSea()
    if CheckSea(1) then return 1
    elseif CheckSea(2) then return 2
    elseif CheckSea(3) then return 3 end
    return 0
end

local function TravelToSea2()
    for attempt = 1, 5 do
        if CheckSea(2) then return true end
        local cs = GetCurrentSea()
        SetStatus(string.format("Travel Sea %d → Sea 2 | Lần %d/5...", cs, attempt))
        xpcall(function() COMMF_:InvokeServer("TravelDressrosa") end,
            function(err) warn("[Travel Error]:", err) end)
        task.wait(8)
        local cw = 0
        while (not Character or not Character:FindFirstChild("HumanoidRootPart")) and cw < 10 do
            task.wait(1) cw = cw + 1
        end
        if CheckSea(2) then SetStatus("✅ Travel thành công!") return true end
    end
    return CheckSea(2)
end

-- ==========================================================================
-- MAIN FLOW
-- ==========================================================================
task.wait(2)
SetStatus("Kiểm tra Sea hiện tại...")
local cs = GetCurrentSea()
print(string.format("[Sea Check] PlaceId=%s | MAP=%s | Sea=%d",
    tostring(game.PlaceId), tostring(workspace:GetAttribute("MAP")), cs))

if cs == 0 then
    SetStatus("⚠️ Không xác định được Sea!")
    return
end

if cs == 2 then
    SetStatus("✅ Đang ở Sea 2!")
    task.wait(1.5)
elseif cs == 1 or cs == 3 then
    SetStatus(string.format("📍 Sea %d → Travel Sea 2...", cs))
    task.wait(2)
    local ok = TravelToSea2()
    if not ok then
        SetStatus("❌ Travel thất bại!")
        return
    end
    repeat task.wait(1)
    until Character and Character:FindFirstChild("HumanoidRootPart") and CheckSea(2)
    SetStatus("✅ Đã về Sea 2!")
    task.wait(1.5)
end

-- ==========================================================================
-- AUTO TWEEN ĐẾN MANAGER NPC (sau khi vào Sea 2 thành công)
-- ==========================================================================
SetStatus("🎯 Tween đến Manager NPC...")
task.wait(0.5)

-- Đảm bảo character thật sự sẵn sàng
local readyWait = 0
while (not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0) and readyWait < 15 do
    task.wait(1)
    readyWait = readyWait + 1
end

if not HumanoidRootPart then
    SetStatus("❌ Character không sẵn sàng để tween")
    return
end

-- Tween đến Manager với retry tối đa 3 lần (phòng tween bị gián đoạn)
local tweenDone = false
for tweenAttempt = 1, 3 do
    if tweenDone then break end
    SetStatus(string.format("🎯 Tween đến Manager | Lần %d/3", tweenAttempt))

    local distance = (HumanoidRootPart.Position - MANAGER_POSITION).Magnitude
    SetStatus(string.format("🎯 Tween đến Manager | Khoảng cách: %d studs", math.floor(distance)))

    local completed = false
    TweenTo(CFrame.new(MANAGER_POSITION), 275, function(success)
        completed = success
    end)

    -- Đợi tween hoàn tất (timeout 30s)
    local waited = 0
    while not completed and isTweening and waited < 30 do
        task.wait(0.2)
        waited = waited + 0.2
        local curDist = (HumanoidRootPart.Position - MANAGER_POSITION).Magnitude
        SetStatus(string.format("🎯 Tween Manager... %d studs còn lại", math.floor(curDist)))
    end

    -- Kiểm tra đã đến nơi chưa
    task.wait(0.5)
    local finalDist = (HumanoidRootPart.Position - MANAGER_POSITION).Magnitude
    if finalDist < 15 then
        tweenDone = true
        SetStatus("✅ Đã đến Manager!")
    else
        SetStatus(string.format("⚠️ Lệch %d studs, retry...", math.floor(finalDist)))
        task.wait(1)
    end
end

if not tweenDone then
    SetStatus("⚠️ Tween không chính xác, TP trực tiếp")
    HumanoidRootPart.CFrame = CFrame.new(MANAGER_POSITION) + Vector3.new(0, 3, 0)
    task.wait(0.5)
end

-- ==========================================================================
-- DONE
-- ==========================================================================
SetStatus("🚀 Sẵn sàng tại Manager | TP Chair có thể dùng")
StarterGui:SetCore("SendNotification", {
    Title = "Ready", Text = "Đã đến Manager NPC ✅", Duration = 4
})

print("[AutoSea2] ✅ Setup hoàn tất | Sea 2 | Manager NPC | Team: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "None"))

-- ==========================================================================
-- TODO: PHASE TIẾP THEO (tương tác Manager NPC...)
-- ==========================================================================

if getgenv().change == true then
    pcall(function()
        if writefile and LocalPlayer then
            local playerName = LocalPlayer.Name
            writefile(playerName .. ".txt", "Completed-sea2")
        end
    end)
    SetStatus("✅ Đã tạo file " .. (LocalPlayer and LocalPlayer.Name or "Player") .. ".txt và dừng hoạt động.")
end
```</Tên_Người_Chơi>
