-- ══════════════════════════════════════════
-- KEY CONFIG
-- Dùng ngoài executor:
--   getgenv().Key            = "yourkey"
--   getgenv().fragmentcount  = "12000"
--   getgenv().fragment       = true   -- false = tắt farm fragment
--   loadstring(game:HttpGet("link"))()
-- ══════════════════════════════════════════
if not getgenv().Key           then getgenv().Key           = ""       end
if not getgenv().fragmentcount then getgenv().fragmentcount = "12000"  end
if getgenv().fragment == nil   then getgenv().fragment      = true     end
getgenv().Team = getgenv().Team or "Pirates"

-- ══════════════════════════════════════════
-- WAIT GAME LOAD
-- ══════════════════════════════════════════
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")

-- ══════════════════════════════════════════
-- JOIN TEAM (VFAndSA style)
-- ══════════════════════════════════════════
if game.Players.LocalPlayer.Team == nil then
    repeat task.wait()
        for _, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                pcall(function()
                    v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.Size     = UDim2.new(0, 10000, 0, 10000)
                    v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.Position = UDim2.new(-4, 0, -5, 0)
                    v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.BackgroundTransparency = 1
                end)
                task.wait(0.5)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1)
                task.wait(0.05)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService   = game:GetService("CollectionService")

local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local plr    = Players.LocalPlayer

if workspace.DistributedGameTime <= 10 then
    task.wait(math.max(0, 10 - workspace.DistributedGameTime))
end
if not COMMF_ then repeat task.wait(1) until COMMF_ end

repeat task.wait(0.5) until
    plr.Character and
    plr.Character:FindFirstChild("HumanoidRootPart") and
    plr:FindFirstChild("Data") and
    plr.Data:FindFirstChild("Race") and
    plr.Data:FindFirstChild("Fragments")

-- ══════════════════════════════════════════
-- HÀM LẤY THÔNG TIN
-- ══════════════════════════════════════════
local function GetRace()
    local ok, v = pcall(function() return tostring(plr.Data.Race.Value) end)
    if ok and v and v ~= "" then return v end
    return "Unknown"
end

local function GetSea()
    local ok, v = pcall(function()
        return tonumber(tostring(workspace:GetAttribute("MAP")):match("%d+"))
    end)
    if ok and v then return v end
    return 1
end

local function GetRaceVersion()
    -- V4: check node V4 trong Data.Race
    local ok4, v4 = pcall(function()
        return plr.Data.Race:FindFirstChild("V4") ~= nil
    end)
    if ok4 and v4 then return "V4" end

    -- V2/V3 đều dùng node "Evolved" trong Data.Race (theo Banana source)
    -- Nếu có "Evolved" = đã lên V2 tối thiểu
    local hasEvolved = false
    local ok2, v2 = pcall(function()
        return plr.Data.Race:FindFirstChild("Evolved") ~= nil
    end)
    if ok2 and v2 then hasEvolved = true end

    if hasEvolved then
        -- V3 = có Evolved + đang ở Sea 3
        -- (Banana dùng World3 để check, tức MAP attribute chứa "3")
        if GetSea() == 3 then
            return "V3"
        end
        return "V2"
    end

    return "V1"
end

local function GetFragmentNum()
    local ok, v = pcall(function() return plr.Data.Fragments.Value end)
    if ok then return tonumber(v) or 0 end
    return 0
end

local function GetFragment()
    return tostring(GetFragmentNum())
end

local function IsPulled()
    local ok, r = pcall(function() return COMMF_:InvokeServer("templedoorcheck") end)
    return ok and r == true
end

local function GetPullStatus()
    if IsPulled() then return "✅ Đã Gạt" end
    return "❌ Chưa Gạt"
end

local function TravelToSea3()
    pcall(function() COMMF_:InvokeServer("TravelZou") end)
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
ScreenGui.Name           = "__SUI__"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = plr.PlayerGui

local Main = Instance.new("Frame")
Main.Name                   = "Main"
Main.Size                   = UDim2.new(0, 215, 0, 195)
Main.Position               = UDim2.new(0, 18, 0.5, -97)
Main.BackgroundColor3       = Color3.fromRGB(8, 8, 8)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel        = 0
Main.ClipsDescendants       = true
Main.Active                 = true
Main.Parent                 = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 7)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(200, 160, 30)
Stroke.Thickness = 1.8

-- TopBar
local TopBar = Instance.new("Frame", Main)
TopBar.Name = "TopBar"; TopBar.Size = UDim2.new(1, 0, 0, 26)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TopBar.BackgroundTransparency = 0; TopBar.BorderSizePixel = 0
TopBar.Active = true; TopBar.ZIndex = 5
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 7)

-- Accent line
local AccLine = Instance.new("Frame", Main)
AccLine.Name = "AccLine"; AccLine.Size = UDim2.new(1, 0, 0, 2)
AccLine.Position = UDim2.new(0, 0, 0, 25)
AccLine.BackgroundColor3 = Color3.fromRGB(200, 160, 30); AccLine.BorderSizePixel = 0
do
    local g = Instance.new("UIGradient", AccLine)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 210, 60)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 210, 60)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
    })
end

-- Dots + StatusLabel
local Dots = Instance.new("TextLabel", TopBar)
Dots.Size = UDim2.new(0, 44, 1, 0); Dots.Position = UDim2.new(1, -46, 0, 0)
Dots.BackgroundTransparency = 1; Dots.Font = Enum.Font.GothamBold
Dots.TextSize = 12; Dots.TextColor3 = Color3.fromRGB(200, 160, 30)
Dots.Text = "• • •"; Dots.ZIndex = 6

local StatusLabel = Instance.new("TextLabel", TopBar)
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -52, 1, 0); StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1; StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11; StatusLabel.TextColor3 = Color3.fromRGB(200, 160, 30)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Text = "◈  " .. CurrentStatus; StatusLabel.ZIndex = 6

-- Divider
local Divider = Instance.new("Frame", Main)
Divider.Name = "Divider"; Divider.Size = UDim2.new(1, -14, 0, 1)
Divider.Position = UDim2.new(0, 7, 0, 32)
Divider.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
Divider.BackgroundTransparency = 0.5; Divider.BorderSizePixel = 0
do
    local g = Instance.new("UIGradient", Divider)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(200, 160, 30)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 160, 30)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
    })
end

-- Tạo row
local function MakeRow(yPos, key, value)
    local row = Instance.new("Frame", Main)
    row.Name = "Row_"..key; row.Size = UDim2.new(1, -14, 0, 27)
    row.Position = UDim2.new(0, 7, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BackgroundTransparency = 0.25; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local kL = Instance.new("TextLabel", row)
    kL.Size = UDim2.new(0.48, 0, 1, 0); kL.Position = UDim2.new(0, 8, 0, 0)
    kL.BackgroundTransparency = 1; kL.Font = Enum.Font.Gotham
    kL.TextSize = 11; kL.TextColor3 = Color3.fromRGB(160, 160, 160)
    kL.TextXAlignment = Enum.TextXAlignment.Left; kL.Text = key

    local vL = Instance.new("TextLabel", row)
    vL.Size = UDim2.new(0.52, -8, 1, 0); vL.Position = UDim2.new(0.48, 0, 0, 0)
    vL.BackgroundTransparency = 1; vL.Font = Enum.Font.GothamBold
    vL.TextSize = 11; vL.TextColor3 = Color3.fromRGB(230, 185, 50)
    vL.TextXAlignment = Enum.TextXAlignment.Right; vL.Text = value

    return vL
end

local startY = 38; local gap = 34
local ValRace     = MakeRow(startY + gap * 0, "Race :",     "...")
local ValRaceV    = MakeRow(startY + gap * 1, "Race V :",   "...")
local ValFragment = MakeRow(startY + gap * 2, "Fragment :", "...")
local ValPull     = MakeRow(startY + gap * 3, "Pull :",     "...")

-- ══════════════════════════════════════════
-- KÉO UI
-- ══════════════════════════════════════════
do
    local dragging, dragStart, startPos = false, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = Main.Position
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
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════
-- TOGGLE ALT
-- ══════════════════════════════════════════
local isVisible = true
local FULL_SIZE = UDim2.new(0, 215, 0, 195)
local HIDE_SIZE = UDim2.new(0, 215, 0, 26)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt
    or input.KeyCode == Enum.KeyCode.RightAlt then
        isVisible = not isVisible
        TweenService:Create(Main,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = isVisible and FULL_SIZE or HIDE_SIZE }
        ):Play()
        for _, child in ipairs(Main:GetChildren()) do
            if child.Name ~= "TopBar" and child.Name ~= "AccLine" then
                child.Visible = isVisible
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- UPDATE LOOP
-- ══════════════════════════════════════════
local lastPullTick = 0
local fragTarget   = tonumber(getgenv().fragmentcount) or 12000

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            fragTarget       = tonumber(getgenv().fragmentcount) or 12000
            ValRace.Text     = GetRace()
            ValRaceV.Text    = GetRaceVersion()
            ValFragment.Text = GetFragment() .. "/" .. tostring(fragTarget)
            if tick() - lastPullTick >= 5 then
                lastPullTick = tick()
                task.spawn(function()
                    pcall(function() ValPull.Text = GetPullStatus() end)
                end)
            end
            StatusLabel.Text = "◈  " .. CurrentStatus
        end)
    end
end)

-- ══════════════════════════════════════════
-- LOGIC CHÍNH
-- ══════════════════════════════════════════
local PlaceId = game.PlaceId
local JobId   = game.JobId

local function KickRejoin(reason)
    SetStatus(reason .. " → Rejoin...")
    task.wait(3)
    TeleportService.TeleportInitFailed:Connect(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, plr)
    end)
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, plr)
end

local BANANA_URL = "https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"

-- ════════════════════════════════
-- PHẦN E: CHECK + GHI FILE (fragment = false)
-- ════════════════════════════════
local function StartCompletionCheck()
    task.spawn(function()
        while true do
            task.wait(15)
            pcall(function()
                if GetRace() == "Ghoul"
                and (GetRaceVersion() == "V3" or GetRaceVersion() == "V4")
                and IsPulled() then
                    SetStatus("[E] ✅ Đủ điều kiện! Ghi file...")
                    pcall(function()
                        writefile(plr.Name .. ".txt", "Completed-racev3andpull")
                    end)
                    warn("[E] Ghi: " .. plr.Name .. ".txt → Completed-racev3andpull")
                    SetStatus("[E] ✅ Completed!")
                    return -- break loop
                end
            end)
        end
    end)
end

-- ════════════════════════════════
-- PHẦN D: FRAGMENT
-- ════════════════════════════════
local PartD
local PartC

PartD = function()
    fragTarget = tonumber(getgenv().fragmentcount) or 12000

    if not getgenv().fragment then
        SetStatus("[D] Fragment OFF → Chờ điều kiện...")
        StartCompletionCheck()
        return
    end

    local frag = GetFragmentNum()
    SetStatus("[D] Fragment: " .. frag .. "/" .. fragTarget)

    if frag >= fragTarget then
        SetStatus("[D] ✅ Đủ " .. fragTarget .. " Frag! Ghi file...")
        pcall(function() writefile(plr.Name .. ".txt", "Completed-racev3andpull") end)
        warn("[D] Ghi: " .. plr.Name .. ".txt → Completed-racev3andpull")
        SetStatus("[D] ✅ Completed!")
        return
    end

    SetStatus("[D] Farm Fragment " .. frag .. "/" .. fragTarget .. "...")
    getgenv().Config = getgenv().Config or {}
    getgenv().Config["Select Method Farm"] = "Farm Katakuri"
    getgenv().Config["Hop Find Katakuri"]  = true
    getgenv().Config["Start Farm"]         = true
    getgenv().NewUI = true

    task.spawn(function()
        pcall(function() loadstring(game:HttpGet(BANANA_URL))() end)
    end)

    task.spawn(function()
        while true do
            task.wait(10)
            fragTarget = tonumber(getgenv().fragmentcount) or 12000
            local f = GetFragmentNum()
            SetStatus("[D] Farming... " .. f .. "/" .. fragTarget)
            if f >= fragTarget then
                SetStatus("[D] ✅ Đủ " .. fragTarget .. " Frag! Ghi file...")
                pcall(function() writefile(plr.Name .. ".txt", "Completed-racev3andpull") end)
                warn("[D] Ghi: " .. plr.Name .. ".txt → Completed-racev3andpull")
                SetStatus("[D] ✅ Completed!")
                break
            end
        end
    end)
end

-- ════════════════════════════════
-- PHẦN C: AUTO PULL LEVER
-- ════════════════════════════════
PartC = function()
    SetStatus("[C] Check Pull Lever...")

    if IsPulled() then
        SetStatus("[C] Đã Gạt ✅ → Phần D...")
        task.wait(1)
        PartD()
        return
    end

    SetStatus("[C] Chưa gạt → Đang Pull...")
    getgenv().Config = getgenv().Config or {}
    getgenv().Config["Auto Pull Lever"]                  = true
    getgenv().Config["Hop Server [Trial Or Pull Lever]"] = true

    task.spawn(function()
        pcall(function() loadstring(game:HttpGet(BANANA_URL))() end)
    end)

    task.spawn(function()
        while true do
            task.wait(10)
            local pulled = IsPulled()
            SetStatus("[C] Đợi Pull... " .. (pulled and "✅" or "❌"))
            if pulled then
                SetStatus("[C] Đã Gạt ✅ → Rejoin...")
                task.wait(3)
                KickRejoin("[C] Pull Done")
                break
            end
        end
    end)
end

-- ════════════════════════════════
-- PHẦN B: AUTO UPGRADE V2/V3
-- ════════════════════════════════
local v2Thread = nil

local function StopV2Click()
    if v2Thread then
        task.cancel(v2Thread)
        v2Thread = nil
    end
end

local function StartV2Click()
    StopV2Click()
    v2Thread = task.spawn(function()
        while true do
            if GetRaceVersion() ~= "V2" then break end
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
            task.wait(0.75)
        end
        v2Thread = nil
    end)
end

local function PartB()
    local ver = GetRaceVersion()
    SetStatus("[B] Ghoul " .. ver)

    if ver == "V3" or ver == "V4" then
        SetStatus("[B] V3 ✅ → Phần C...")
        task.wait(1)
        PartC()
        return
    end

    SetStatus("[B] Upgrade " .. ver .. " → V3...")
    getgenv().Config = getgenv().Config or {}
    getgenv().Config["Auto Upgrade Race V2-V3"] = true

    task.spawn(function()
        pcall(function() loadstring(game:HttpGet(BANANA_URL))() end)
    end)

    if ver == "V2" then
        SetStatus("[B] V2 → Spam Click + Upgrade...")
        StartV2Click()
    end

    task.spawn(function()
        while true do
            task.wait(5)
            local cur = GetRaceVersion()

            if cur == "V2" and not v2Thread then
                SetStatus("[B] Lên V2! Spam Click...")
                StartV2Click()
            end

            SetStatus("[B] Upgrade... " .. cur .. (cur == "V2" and " 🖱️" or ""))

            if cur == "V3" or cur == "V4" then
                StopV2Click()
                SetStatus("[B] V3 ✅ → Sea 3...")
                task.wait(2)
                TravelToSea3()
                task.wait(3)
                KickRejoin("[B] V3 Done")
                break
            end
        end
    end)
end

-- ════════════════════════════════
-- PHẦN A: AUTO CHECK RACE GHOUL
-- ════════════════════════════════
local function PartA()
    local race = GetRace()
    SetStatus("[A] Race: " .. race)

    if race ~= "Ghoul" then
        SetStatus("[A] Chưa Ghoul → Đang lấy...")
        getgenv().Config = getgenv().Config or {}
        getgenv().Config["Auto Get Ghoul"]       = true
        getgenv().Config["Hop Server Get Ghoul"] = true

        task.spawn(function()
            pcall(function() loadstring(game:HttpGet(BANANA_URL))() end)
        end)

        task.spawn(function()
            while true do
                task.wait(10)
                local r = GetRace()
                SetStatus("[A] Đang lấy Ghoul... (" .. r .. ")")
                if r == "Ghoul" then
                    SetStatus("[A] Ghoul ✅ → Rejoin...")
                    task.wait(3)
                    KickRejoin("[A] Ghoul Done")
                    break
                end
            end
        end)
    else
        SetStatus("[A] Ghoul ✅ → Phần B...")
        task.wait(1)
        PartB()
    end
end

-- ══════════════════════════════════════════
-- KHỞI CHẠY
-- ══════════════════════════════════════════
task.spawn(function()
    task.wait(2)
    PartA()
end)

print("[UI] Loaded | ALT ẩn/hiện")
print("[UI] Key:", getgenv().Key ~= "" and getgenv().Key or "(chưa set)")
print("[UI] Fragment target:", getgenv().fragmentcount)
print("[UI] Farm Fragment:", tostring(getgenv().fragment))
