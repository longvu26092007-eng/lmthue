-- ==========================================================================
-- AUTO TRAVEL TO SEA 2 - OPTIMIZED
-- Flow:
--   1. Đợi game load
--   2. Load team (Pirates)
--   3. Check sea (MAP attribute + PlaceId fallback)
--   4. Sea 1 hoặc Sea 3 → Travel về Sea 2
--   5. Sea 2 → Next phase
-- ==========================================================================

-- [1] ĐỢI GAME LOAD
repeat task.wait(0.5)
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

-- [2] SETUP SERVICES (dùng cloneref giống script gốc để an toàn)
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
local RunService         = Services.RunService

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

-- [5] UI STATUS LABEL
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("AutoSea2Status")
    if old then old:Destroy() end
end)

local StatusGui = Instance.new("ScreenGui")
StatusGui.Name          = "AutoSea2Status"
StatusGui.ResetOnSpawn  = false
StatusGui.IgnoreGuiInset = true
StatusGui.DisplayOrder  = 999
StatusGui.Parent        = LocalPlayer.PlayerGui

local StatusLabel = Instance.new("TextLabel")
StatusLabel.AnchorPoint        = Vector2.new(0.5, 0)
StatusLabel.Position           = UDim2.new(0.5, 0, 0.04, 0)
StatusLabel.Size               = UDim2.new(0.5, 0, 0.07, 0)
StatusLabel.BackgroundTransparency = 0.35
StatusLabel.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
StatusLabel.BorderSizePixel    = 0
StatusLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
StatusLabel.TextStrokeTransparency = 0.5
StatusLabel.TextScaled         = true
StatusLabel.Font               = Enum.Font.GothamSemibold
StatusLabel.Text               = "Đang khởi động..."
StatusLabel.Parent             = StatusGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent       = StatusLabel

local function SetStatus(text)
    StatusLabel.Text = text
    print("[AutoSea2] " .. text)
end

StarterGui:SetCore("SendNotification", {
    Title    = "Executed",
    Text     = "Script loaded - Đang setup...",
    Duration = 5
})

-- [6] ĐỢI GAME FULLY LOADED (giống script gốc)
if workspace.DistributedGameTime <= 10 then
    local wait_ = math.floor(10 - workspace.DistributedGameTime)
    SetStatus("Đang chờ game load... (" .. wait_ .. "s)")
    task.wait(wait_)
end

if not COMMF_ then
    SetStatus("Đợi Remote CommF_...")
    repeat task.wait(1) until COMMF_
end

-- [7] LOAD TEAM (PIRATES)
SetStatus("Đang chọn team Pirates...")

local function LoadTeam()
    xpcall(function()
        if LocalPlayer.Team then return end

        -- Đợi loading screen tắt
        if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
            repeat task.wait(1)
            until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
        end

        -- Cách 1: Gọi remote trực tiếp (primary)
        -- Cách 2: Firesignal vào button UI (fallback)
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

-- Đợi character spawn
SetStatus("Đợi Character spawn...")
repeat task.wait(1)
until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

-- Re-check team (nếu lần đầu fail)
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

-- [8] CHECK SEA - DUAL METHOD
-- Cách 1: MAP attribute (giống script gốc, chính xác nhất)
local function CheckSeaByMap(v)
    local mapAttr = workspace:GetAttribute("MAP")
    if mapAttr then
        local num = tonumber(mapAttr:match("%d+"))
        return num == v
    end
    return false
end

-- Cách 2: PlaceId (fallback)
local function CheckSeaByPlaceId(seaTable)
    return seaTable[tostring(game.PlaceId)] == true
end

local function CheckSea(v)
    -- Ưu tiên MAP attribute
    if CheckSeaByMap(v) then return true end
    -- Fallback PlaceId
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

-- [9] TRAVEL TO SEA 2
-- COMMF_:InvokeServer("TravelDressrosa") hoạt động từ cả Sea 1 và Sea 3 về Sea 2
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

        -- Đợi teleport + character load lại
        task.wait(8)

        -- Đợi character sẵn sàng sau khi travel
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

-- [10] MAIN FLOW
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
        Title    = "Sea Check Failed",
        Text     = "PlaceId: " .. tostring(game.PlaceId),
        Duration = 5
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
            Title    = "Travel Failed",
            Text     = "Không travel được về Sea 2",
            Duration = 5
        })
        return
    end

    -- Đợi character và sea stable
    repeat task.wait(1)
    until Character
        and Character:FindFirstChild("HumanoidRootPart")
        and CheckSea(2)

    SetStatus("✅ Đã về Sea 2 thành công!")
    task.wait(2)
end

-- [11] NEXT PHASE - PLACEHOLDER
SetStatus("🚀 Bắt đầu Phase tiếp theo...")
StarterGui:SetCore("SendNotification", {
    Title    = "Ready",
    Text     = "Setup hoàn tất - Sẵn sàng cho phase tiếp theo",
    Duration = 5
})

print("[AutoSea2] ======================================")
print("[AutoSea2] Setup hoàn tất!")
print("[AutoSea2] Sea hiện tại: 2")
print("[AutoSea2] Team: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "None"))
print("[AutoSea2] ======================================")

-- ==========================================================================
-- TODO: CODE PHASE TIẾP THEO CHÈN VÀO ĐÂY
-- ==========================================================================
