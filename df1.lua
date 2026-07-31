--[[
    DARK FRAGMENT FARM - OPTIMIZED | SERVERBROWSER 200 FIX

    Main flow:
      1) Select team / travel to Sea 2
      2) Read materials through ItemReplicationService (no getInventory spam)
      3) Collect chests until Fist of Darkness or Darkbeard is found
      4) Summon and farm Darkbeard
      5) Server hop and repeat until target Dark Fragments is reached
      6) Share Fist/Darkbeard servers through the local Node.js WebSocket server
      7) Hop only through __ServerBrowser (parallel scan, no public server API)

    Example configuration:

    getgenv().ChangeDF = 1 -- 1 Dark Fragment -> write PlayerName.txt = Completed-fragment

    getgenv().DarkFragConfig = {
        Team = "Marines",
        TargetFragments = 10,
        ChangeDF = getgenv().ChangeDF,
        TweenSpeed = 275,
        MaxChestsBeforeHop = 25,
        EmptyScansBeforeHop = 3,

        -- Exact Cyborg 4h + 2h chest window logic:
        -- <4h hop | 4h-6h keep | >6h-8h hop | 8h-10h keep | repeat.
        RequireChestTimeWindow = true,
        ChestServerPeriod = 4 * 60 * 60,
        ChestServerGrace = 2 * 60 * 60,

        -- Fast __ServerBrowser scanner (public Roblox server API is not used).
        HopMaxPages = 200,
        HopPagesPerBatch = 200,
        HopScanConcurrency = 70,
        HopBatchTimeout = 18,
        HopMaxPlayers = 9,

        WSUrl = "ws://127.0.0.1:9876",
        EnableWebSocket = true,
    }

    loadstring(game:HttpGet("YOUR_RAW_URL"))()
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
repeat task.wait() until Player

-- Stop an older copy before starting a new one.
if getgenv().DarkFragController and type(getgenv().DarkFragController.Stop) == "function" then
    pcall(getgenv().DarkFragController.Stop, "reloaded")
end

local UserConfig = getgenv().DarkFragConfig or {}
local Config = {
    Team = UserConfig.Team or getgenv().Team or "Marines",
    TargetFragments = math.max(0, tonumber(UserConfig.TargetFragments or getgenv().Lock) or 10),
    ChangeDF = math.max(0, tonumber(UserConfig.ChangeDF or getgenv().ChangeDF) or 0),
    TweenSpeed = tonumber(UserConfig.TweenSpeed) or 275,
    CollectRadius = tonumber(UserConfig.CollectRadius) or 15,
    MaxDistance = tonumber(UserConfig.MaxDistance) or 20000,
    CollectConfirmTimeout = tonumber(UserConfig.CollectConfirmTimeout) or 1.6,
    RescanDelay = tonumber(UserConfig.RescanDelay) or 2,
    MaxChestsBeforeHop = tonumber(UserConfig.MaxChestsBeforeHop) or 25,
    EmptyScansBeforeHop = tonumber(UserConfig.EmptyScansBeforeHop) or 3,
    InventoryRefresh = tonumber(UserConfig.InventoryRefresh) or 0.6,
    BossScanInterval = tonumber(UserConfig.BossScanInterval) or 0.5,
    AttackInterval = tonumber(UserConfig.AttackInterval) or 0.08,
    AttackRange = tonumber(UserConfig.AttackRange) or 65,
    BossHeight = tonumber(UserConfig.BossHeight) or 55,
    WSUrl = UserConfig.WSUrl or "ws://127.0.0.1:9876",
    EnableWebSocket = UserConfig.EnableWebSocket ~= false,
    SignalJoinCooldown = tonumber(UserConfig.SignalJoinCooldown) or 12,
    ServerBlacklistSeconds = tonumber(UserConfig.ServerBlacklistSeconds) or 600,
    HopWaitSeconds = tonumber(UserConfig.HopWaitSeconds) or 12,

    -- Fast __ServerBrowser-only scanner. No games.roblox.com public server API.
    HopMaxPages = math.max(
        1,
        math.floor(tonumber(UserConfig.HopMaxPages or UserConfig["Hop Max Pages"]) or 200)
    ),
    HopPagesPerBatch = math.max(
        1,
        math.floor(tonumber(UserConfig.HopPagesPerBatch or UserConfig["Hop Pages Per Batch"]) or 200)
    ),
    HopScanConcurrency = math.max(
        1,
        math.floor(tonumber(UserConfig.HopScanConcurrency or UserConfig["Hop Scan Concurrency"]) or 70)
    ),
    HopBatchTimeout = math.max(
        3,
        tonumber(UserConfig.HopBatchTimeout or UserConfig["Hop Batch Timeout"]) or 18
    ),
    HopMaxPlayers = math.max(
        1,
        math.floor(tonumber(UserConfig.HopMaxPlayers or UserConfig["Hop Max Players"]) or 9)
    ),

    -- Boss cleanup protection. ReplicatedStorage can keep a reset Darkbeard template
    -- after the real workspace boss dies; never let that stale model lock the farm.
    BossDeathConfirmDelay = math.max(0.5, tonumber(UserConfig.BossDeathConfirmDelay) or 1.5),
    ReplicatedBossLocateTimeout = math.max(2, tonumber(UserConfig.ReplicatedBossLocateTimeout) or 8),
    ReplicatedBossIgnoreSeconds = math.max(5, tonumber(UserConfig.ReplicatedBossIgnoreSeconds) or 30),

    -- Same 4h + 2h server-time rules used by the Cyborg script.
    RequireChestTimeWindow = UserConfig.RequireChestTimeWindow ~= false,
    ChestServerPeriod = math.max(
        1,
        tonumber(UserConfig.ChestServerPeriod or UserConfig["Chest Server Period"])
            or (4 * 60 * 60)
    ),
    ChestServerGrace = math.max(
        0,
        tonumber(UserConfig.ChestServerGrace or UserConfig["Chest Server Grace"])
            or (2 * 60 * 60)
    ),
    TimeInRetryDelay = math.max(1, tonumber(UserConfig.TimeInRetryDelay) or 3),
    Debug = UserConfig.Debug == true,
}

Config.HopPagesPerBatch = math.min(Config.HopPagesPerBatch, Config.HopMaxPages)
Config.HopScanConcurrency = math.min(Config.HopScanConcurrency, Config.HopPagesPerBatch)

Config.CompletionTarget = Config.ChangeDF > 0
    and Config.ChangeDF
    or Config.TargetFragments

getgenv().DarkFragConfig = Config
getgenv().ChangeDF = Config.ChangeDF
getgenv().Lock = Config.CompletionTarget -- backwards compatibility
getgenv().DarkFragRunning = true

local State = {
    Running = true,
    Phase = "INIT",
    Status = "Starting...",
    Extra = "Target: --",
    ChestCount = 0,
    KillCount = 0,
    ConfirmedChestKeys = {},
    FailedChestKeys = {},
    IsMoving = false,
    MoveTarget = nil,
    MoveToken = 0,
    Darkbeard = nil,
    HasFist = false,
    MaterialReady = false,
    MaterialCounts = {},
    MaterialNamesById = {},
    CategoriesById = {},
    WS = nil,
    WSConnected = false,
    Hopping = false,
    LastSignalJoinAt = 0,
    VisitedServers = {},
    Connections = {},
    CharacterParts = {},
    CharacterDescendantConnection = nil,
    LastAttackAt = 0,
    LastSignalKey = nil,
    LastSignalAt = 0,
    IgnoreReplicatedDarkbeardUntil = 0,
    HopNextPage = 1,
    HopScan = {
        Status = "Idle",
        RequestedPages = 0,
        CompletedPages = 0,
        FailedPages = 0,
        Candidates = 0,
        TimedOut = false,
    },
    CompletionFileWritten = false,
    CompletionFileError = nil,
}

-- ============================================================
-- REAL SERVER UPTIME + EXACT CYBORG 4H PERIOD / 2H ACTIVE WINDOW
-- Uses:
-- workspace:GetServerTimeNow() - Workspace._WorldOrigin.Locations.<Location>.@TimeIn
--
-- Exact rule:
--   below 4h      -> HOP
--   4h00-6h00     -> KEEP / collect chests
--   above 6h-8h   -> HOP
--   8h00-10h00    -> KEEP / collect chests
--   above 10h-12h -> HOP, then repeat every 4 hours.
-- Boundaries 6h00, 10h00, ... remain valid; only values above them hop.
-- ============================================================
local ServerTimeRuntime = {
    StartTime = nil,
    SourcePath = nil,
    MatchedLocations = 0,
    LastError = nil,
}

local function DetectServerStartTimeFromTimeIn()
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
    if not locations then
        return nil, nil, "Workspace._WorldOrigin.Locations not found"
    end

    local groups = {}

    for _, location in ipairs(locations:GetChildren()) do
        local value = location:GetAttribute("TimeIn")

        if type(value) == "number" and value > 1000000000 then
            local rounded = math.floor(value + 0.5)
            groups[rounded] = groups[rounded] or {
                Count = 0,
                Total = 0,
                Names = {},
            }

            local group = groups[rounded]
            group.Count = group.Count + 1
            group.Total = group.Total + value
            group.Names[#group.Names + 1] = location.Name
        end
    end

    local bestRounded
    local bestGroup

    for rounded, group in pairs(groups) do
        if not bestGroup
            or group.Count > bestGroup.Count
            or (group.Count == bestGroup.Count and rounded < bestRounded) then
            bestRounded = rounded
            bestGroup = group
        end
    end

    if not bestGroup then
        return nil, nil, "No valid TimeIn attribute found"
    end

    local averageTimeIn = bestGroup.Total / bestGroup.Count
    local exampleName = bestGroup.Names[1] or "Unknown"

    return averageTimeIn, {
        Count = bestGroup.Count,
        Path = "Workspace._WorldOrigin.Locations."
            .. exampleName
            .. ".@TimeIn",
    }
end

local function GetRealServerUptime()
    if not ServerTimeRuntime.StartTime then
        local detected, info, err = DetectServerStartTimeFromTimeIn()

        if not detected then
            ServerTimeRuntime.LastError = err
            return nil, err
        end

        ServerTimeRuntime.StartTime = detected
        ServerTimeRuntime.SourcePath = info.Path
        ServerTimeRuntime.MatchedLocations = info.Count
        ServerTimeRuntime.LastError = nil
    end

    local ok, serverNow = pcall(function()
        return workspace:GetServerTimeNow()
    end)

    if not ok or type(serverNow) ~= "number" then
        ServerTimeRuntime.LastError = "Workspace:GetServerTimeNow() failed"
        return nil, ServerTimeRuntime.LastError
    end

    local uptime = serverNow - ServerTimeRuntime.StartTime

    if uptime < 0 or uptime >= 31536000 then
        ServerTimeRuntime.LastError = "TimeIn is invalid"
        return nil, ServerTimeRuntime.LastError
    end

    local source = string.format(
        "%s | matched %d Locations",
        tostring(ServerTimeRuntime.SourcePath),
        tonumber(ServerTimeRuntime.MatchedLocations) or 0
    )

    return uptime, source
end

local function FormatUptime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function CheckChestTimeWindow()
    local uptime, source = GetRealServerUptime()
    if not uptime then
        return false, nil, source, nil
    end

    if not Config.RequireChestTimeWindow then
        return true, uptime, source, {
            Phase = "DISABLED",
            Offset = uptime,
            CycleStart = 0,
            CycleEnd = math.huge,
            NextBoundary = math.huge,
            Remaining = math.huge,
        }
    end

    local period = math.max(1, tonumber(Config.ChestServerPeriod) or (4 * 60 * 60))
    local grace = math.max(0, tonumber(Config.ChestServerGrace) or (2 * 60 * 60))
    local firstWindowStart = period

    if uptime < firstWindowStart then
        return false, uptime, source, {
            Phase = "BEFORE_FIRST_WINDOW",
            Offset = uptime,
            CycleStart = firstWindowStart,
            CycleEnd = firstWindowStart + grace,
            NextBoundary = firstWindowStart,
            Remaining = firstWindowStart - uptime,
        }
    end

    local windowIndex = math.floor((uptime - firstWindowStart) / period)
    local cycleStart = firstWindowStart + (windowIndex * period)
    local cycleEnd = cycleStart + grace
    local offset = uptime - cycleStart

    -- Exactly like the Cyborg script: 6h00 / 10h00 / ... are still kept.
    local inWindow = uptime <= cycleEnd
    local nextBoundary = inWindow and cycleEnd or (cycleStart + period)

    return inWindow, uptime, source, {
        Phase = inWindow and "ACTIVE" or "OUTSIDE",
        Offset = offset,
        CycleStart = cycleStart,
        CycleEnd = cycleEnd,
        NextBoundary = nextBoundary,
        Remaining = math.max(0, nextBoundary - uptime),
    }
end

local function buildWindowStatus(inWindow, uptime, timeInfo)
    if not uptime or not timeInfo then
        return "TimeIn unavailable"
    end

    if timeInfo.Phase == "DISABLED" then
        return "DISABLED"
    end

    if inWindow then
        return "ACTIVE "
            .. FormatUptime(timeInfo.CycleStart)
            .. " -> "
            .. FormatUptime(timeInfo.CycleEnd)
    end

    return "HOP | next "
        .. FormatUptime(timeInfo.NextBoundary)
        .. " | remaining "
        .. FormatUptime(timeInfo.Remaining)
end

local function debugPrint(...)
    if Config.Debug then
        print("[DarkFrag]", ...)
    end
end

local function bindConnection(connection)
    State.Connections[#State.Connections + 1] = connection
    return connection
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function setStatus(status, phase, extra)
    if status then State.Status = status end
    if phase then State.Phase = phase end
    if extra then State.Extra = extra end
end

local function stopScript(reason)
    if not State.Running then return end

    State.Running = false
    getgenv().DarkFragRunning = false
    State.IsMoving = false
    State.MoveTarget = nil
    State.MoveToken = State.MoveToken + 1

    if State.WS then
        pcall(function()
            State.WS:Close()
        end)
    end
    State.WS = nil
    State.WSConnected = false

    if State.CharacterDescendantConnection then
        safeDisconnect(State.CharacterDescendantConnection)
        State.CharacterDescendantConnection = nil
    end

    for _, connection in ipairs(State.Connections) do
        safeDisconnect(connection)
    end
    table.clear(State.Connections)

    debugPrint("Stopped:", reason or "unknown")
end

getgenv().DarkFragController = {
    Stop = stopScript,
    State = State,
    Config = Config,
}

-- Roblox objects/remotes.
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local ServerBrowser = ReplicatedStorage:WaitForChild("__ServerBrowser")

local SEA_2_PLACE_IDS = {
    [4442272183] = true,
    [79091703265657] = true,
}

local CHEST_NAMES = {
    Chest1 = true,
    Chest2 = true,
    Chest3 = true,
    Chest4 = true,
    Chest5 = true,
}

local function ensureTeamSelected()
    if Player.Team then return true end

    setStatus("Selecting team...", "TEAM")
    local ok = pcall(function()
        CommF_:InvokeServer("SetTeam", Config.Team)
    end)

    if not ok then return false end

    local deadline = os.clock() + 15
    repeat
        task.wait(0.25)
    until Player.Team or os.clock() >= deadline or not State.Running

    return Player.Team ~= nil
end

if not ensureTeamSelected() then
    setStatus("Unable to select team", "ERROR")
    stopScript("team_select_failed")
    return
end

if not SEA_2_PLACE_IDS[game.PlaceId] then
    setStatus("Travelling to Sea 2...", "TRAVEL")
    pcall(function()
        CommF_:InvokeServer("TravelDressrosa")
    end)
    return
end

-- Item replication/material tracker.
local Inventory = require(ReplicatedStorage.Controllers.UI.Inventory)
local ItemConfig = require(ReplicatedStorage.ItemConfig)
local ItemService = require(ReplicatedStorage.ItemReplicationService)
local KEYS = require(ReplicatedStorage.ItemReplicationService.KEYS)

local function inventoryInitialized()
    local ok, ready = pcall(function()
        return Inventory:GetIfInitialized()
    end)
    return ok and ready and ItemService.IsInitialized == true
end

local inventoryDeadline = os.clock() + 30
repeat
    task.wait(0.2)
until inventoryInitialized() or os.clock() >= inventoryDeadline or not State.Running

if not inventoryInitialized() then
    setStatus("Item service not initialized", "ERROR")
    stopScript("item_service_timeout")
    return
end

local function normalizeName(value)
    return string.lower(tostring(value or ""))
end

local function resolveItemInfo(itemId)
    if itemId == nil then return nil, nil end

    if State.MaterialNamesById[itemId] then
        return State.MaterialNamesById[itemId], State.CategoriesById[itemId]
    end

    local ok, config = pcall(function()
        return ItemConfig.match(itemId):unwrap()
    end)

    if not ok or not config then
        return nil, nil
    end

    local display = config.Display or {}
    local index = config.Index or {}
    local name = display.Name or index.StorageKey or tostring(itemId)
    local category = display.Category

    State.MaterialNamesById[itemId] = name
    State.CategoriesById[itemId] = category
    return name, category
end

local function seedItemMetadata()
    local ok, tiles = pcall(function()
        return Inventory:GetTiles() or {}
    end)
    if not ok then return end

    for _, tile in pairs(tiles) do
        if tile and tile.ItemId ~= nil then
            resolveItemInfo(tile.ItemId)
        end
    end
end

local function refreshMaterialCounts()
    local totals = {}
    local ok, items = pcall(function()
        return ItemService:GetItems(KEYS.QUANTITY) or {}
    end)

    if not ok then return false end

    for _, item in pairs(items) do
        if type(item) == "table" and item.ItemId ~= nil then
            local name, category = resolveItemInfo(item.ItemId)
            local amount = tonumber(item.Value) or 0

            if name and (category == "Material" or normalizeName(name) == "dark fragment") then
                local key = normalizeName(name)
                totals[key] = (totals[key] or 0) + amount
            end
        end
    end

    State.MaterialCounts = totals
    State.MaterialReady = true
    return true
end

local function getMaterialCount(materialName)
    return tonumber(State.MaterialCounts[normalizeName(materialName)]) or 0
end

local CompletionFile = Player.Name .. ".txt"

local function writeCompletedFragmentFile()
    if Config.ChangeDF <= 0 then
        return true
    end

    if State.CompletionFileWritten then
        return true
    end

    if type(writefile) ~= "function" then
        State.CompletionFileError = "writefile is unavailable"
        return false
    end

    local lastError = "unknown"
    for _ = 1, 3 do
        local ok, err = pcall(function()
            writefile(CompletionFile, "Completed-fragment")
        end)

        if ok then
            State.CompletionFileWritten = true
            State.CompletionFileError = nil
            return true
        end

        lastError = tostring(err)
        task.wait(0.2)
    end

    State.CompletionFileError = lastError
    return false
end

seedItemMetadata()
refreshMaterialCounts()

task.spawn(function()
    while State.Running do
        refreshMaterialCounts()
        task.wait(Config.InventoryRefresh)
    end
end)

-- Character helpers and optimized noclip cache.
local function getCharacterParts()
    local character = Player.Character
    if not character then return nil, nil, nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return nil, nil, nil
    end

    return character, root, humanoid
end

local function registerCharacterPart(instance)
    if instance:IsA("BasePart") then
        State.CharacterParts[instance] = true
        instance.CanCollide = false
    end
end

local function bindCharacter(character)
    State.CharacterParts = {}

    if State.CharacterDescendantConnection then
        safeDisconnect(State.CharacterDescendantConnection)
        State.CharacterDescendantConnection = nil
    end

    if not character then return end

    for _, descendant in ipairs(character:GetDescendants()) do
        registerCharacterPart(descendant)
    end

    State.CharacterDescendantConnection = character.DescendantAdded:Connect(registerCharacterPart)
end

bindCharacter(Player.Character)

bindConnection(Player.CharacterAdded:Connect(function(character)
    State.IsMoving = false
    State.MoveTarget = nil
    State.MoveToken = State.MoveToken + 1
    bindCharacter(character)
    task.wait(2)
end))

bindConnection(RunService.Stepped:Connect(function()
    if not State.Running then return end

    for part in pairs(State.CharacterParts) do
        if part and part.Parent then
            part.CanCollide = false
        else
            State.CharacterParts[part] = nil
        end
    end
end))

local function waitForAliveCharacter()
    while State.Running do
        local character, root, humanoid = getCharacterParts()
        if character then return character, root, humanoid end
        task.wait(0.5)
    end
    return nil, nil, nil
end

local function cancelMovement()
    State.IsMoving = false
    State.MoveTarget = nil
    State.MoveToken = State.MoveToken + 1
end

local function startMovement(targetPosition)
    local _, root = getCharacterParts()
    if not root or typeof(targetPosition) ~= "Vector3" then return false end

    if (root.Position - targetPosition).Magnitude <= Config.CollectRadius then
        root.CFrame = CFrame.new(targetPosition)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        cancelMovement()
        return true
    end

    State.MoveToken = State.MoveToken + 1
    State.MoveTarget = targetPosition
    State.IsMoving = true
    return true
end

bindConnection(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.Running or not State.IsMoving or not State.MoveTarget then return end

    local _, root, humanoid = getCharacterParts()
    if not root or not humanoid then
        cancelMovement()
        return
    end

    if humanoid:GetState() == Enum.HumanoidStateType.Seated then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    local difference = State.MoveTarget - root.Position
    local remaining = difference.Magnitude

    if remaining <= 3 then
        root.CFrame = CFrame.new(State.MoveTarget)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        cancelMovement()
        return
    end

    local amount = math.min(Config.TweenSpeed * deltaTime, remaining)
    root.CFrame = CFrame.new(root.Position + difference.Unit * amount)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end))

local function waitMovement(timeout)
    local deadline = os.clock() + (timeout or 60)
    while State.Running and State.IsMoving and os.clock() < deadline do
        task.wait(0.1)
    end
    return not State.IsMoving
end

-- Fist and boss detection.
local function findTool(toolName)
    local character = Player.Character
    local backpack = Player:FindFirstChild("Backpack")

    if character then
        local tool = character:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end

    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end

    return nil
end

local function hasFistOfDarkness()
    return findTool("Fist of Darkness") ~= nil
        or getMaterialCount("Fist of Darkness") > 0
end

local function isAlive(model)
    if not model or not model.Parent then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and root ~= nil and humanoid.Health > 0
end

local function findDarkbeard()
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        local boss = enemies:FindFirstChild("Darkbeard")
        if boss and isAlive(boss) then
            return boss, "workspace"
        end
    end

    local workspaceBoss = workspace:FindFirstChild("Darkbeard")
    if workspaceBoss and isAlive(workspaceBoss) then
        return workspaceBoss, "workspace"
    end

    -- ReplicatedStorage can contain either:
    --   1) a real streamed-out boss, or
    --   2) a reset/template model left after the workspace boss was killed.
    -- The ignore deadline prevents case (2) from locking several accounts forever.
    if os.clock() >= (State.IgnoreReplicatedDarkbeardUntil or 0) then
        local replicatedBoss = ReplicatedStorage:FindFirstChild("Darkbeard")
        if replicatedBoss and isAlive(replicatedBoss) then
            return replicatedBoss, "replicated"
        end
    end

    return nil, nil
end

task.spawn(function()
    while State.Running do
        State.Darkbeard = findDarkbeard()
        State.HasFist = hasFistOfDarkness()
        task.wait(Config.BossScanInterval)
    end
end)

-- Chest scanning/collection.
local function getInstancePosition(instance)
    if not instance or not instance.Parent then return nil end

    if instance:IsA("BasePart") then
        return instance.Position
    end

    if instance:IsA("Model") then
        local ok, cframe = pcall(function()
            return instance:GetBoundingBox()
        end)
        if ok and cframe then return cframe.Position end

        if instance.PrimaryPart then
            return instance.PrimaryPart.Position
        end

        local part = instance:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end

    return nil
end

local function findTouchPart(instance)
    if not instance or not instance.Parent then return nil end

    if instance:IsA("BasePart") and instance:FindFirstChild("TouchInterest") then
        return instance
    end

    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:FindFirstChild("TouchInterest") then
            return descendant
        end
    end

    return nil
end

local function hasTouch(instance)
    return findTouchPart(instance) ~= nil
end

local function positionKey(position)
    return table.concat({
        math.floor(position.X / 4),
        math.floor(position.Y / 4),
        math.floor(position.Z / 4),
    }, ",")
end

local function scanChestContainer(container, playerPosition, resultByKey)
    if not container then return end

    local ok, descendants = pcall(function()
        return container:GetDescendants()
    end)
    if not ok then return end

    for _, object in ipairs(descendants) do
        if CHEST_NAMES[object.Name] and object.Parent then
            local touchPart = findTouchPart(object)
            local position = touchPart and touchPart.Position or getInstancePosition(object)

            if touchPart and position then
                local distance = (playerPosition - position).Magnitude
                if distance <= Config.MaxDistance then
                    local key = object.Name .. ":" .. positionKey(position)
                    local existing = resultByKey[key]
                    local candidate = {
                        Instance = object,
                        TouchPart = touchPart,
                        Position = position,
                        Name = object.Name,
                        Distance = distance,
                        Key = key,
                    }

                    if not existing or candidate.Distance < existing.Distance then
                        resultByKey[key] = candidate
                    end
                end
            end
        end
    end
end

local function scanChests()
    local _, root = getCharacterParts()
    if not root then return {} end

    local resultByKey = {}
    scanChestContainer(workspace:FindFirstChild("Map"), root.Position, resultByKey)
    scanChestContainer(ReplicatedStorage:FindFirstChild("Unloaded"), root.Position, resultByKey)

    local result = {}
    for key, chest in pairs(resultByKey) do
        if not State.ConfirmedChestKeys[key] and not State.FailedChestKeys[key] then
            result[#result + 1] = chest
        end
    end

    table.sort(result, function(a, b)
        return a.Distance < b.Distance
    end)

    return result
end

local function forceTouch(root, touchPart)
    if not root or not touchPart then return end

    local fireTouch = rawget(getgenv(), "firetouchinterest") or firetouchinterest
    if type(fireTouch) == "function" then
        pcall(function()
            fireTouch(root, touchPart, 0)
            task.wait()
            fireTouch(root, touchPart, 1)
        end)
    end
end

local function chestWasCollected(chest)
    if not chest.Instance or not chest.Instance.Parent then return true end
    if not hasTouch(chest.Instance) then return true end

    local newPosition = getInstancePosition(chest.Instance)
    if not newPosition then return true end

    -- If the same instance was moved far away after touching, treat it as collected/unloaded.
    if (newPosition - chest.Position).Magnitude > 100 then return true end
    return false
end

local function collectChest(chest)
    if not chest or not chest.Instance or not chest.Instance.Parent then
        return false
    end

    local deadline = os.clock() + math.max(20, (chest.Distance / math.max(Config.TweenSpeed, 1)) + 10)
    startMovement(chest.Position)

    while State.Running and os.clock() < deadline do
        if State.Darkbeard or State.HasFist then
            cancelMovement()
            return "priority_found"
        end

        local _, root = getCharacterParts()
        if not root then
            cancelMovement()
            return false
        end

        if chestWasCollected(chest) then
            cancelMovement()
            State.ConfirmedChestKeys[chest.Key] = true
            State.ChestCount = State.ChestCount + 1
            return true
        end

        local touchPart = findTouchPart(chest.Instance)
        local position = touchPart and touchPart.Position or getInstancePosition(chest.Instance)
        if not position then
            cancelMovement()
            State.ConfirmedChestKeys[chest.Key] = true
            State.ChestCount = State.ChestCount + 1
            return true
        end

        chest.Position = position
        local distance = (root.Position - position).Magnitude

        if distance <= Config.CollectRadius then
            cancelMovement()
            root.CFrame = CFrame.new(position)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            forceTouch(root, touchPart)

            local confirmDeadline = os.clock() + Config.CollectConfirmTimeout
            while State.Running and os.clock() < confirmDeadline do
                if chestWasCollected(chest) then
                    State.ConfirmedChestKeys[chest.Key] = true
                    State.ChestCount = State.ChestCount + 1
                    return true
                end
                task.wait(0.1)
            end

            -- One final contact retry. Do not falsely increase the chest counter.
            root.CFrame = CFrame.new(position)
            forceTouch(root, findTouchPart(chest.Instance))
            task.wait(0.35)

            if chestWasCollected(chest) then
                State.ConfirmedChestKeys[chest.Key] = true
                State.ChestCount = State.ChestCount + 1
                return true
            end

            State.FailedChestKeys[chest.Key] = true
            return false
        end

        if not State.IsMoving or not State.MoveTarget
            or (State.MoveTarget - position).Magnitude > 8 then
            startMovement(position)
        end

        task.wait(0.1)
    end

    cancelMovement()
    State.FailedChestKeys[chest.Key] = true
    return false
end

-- Combat helpers.
local CombatUtil = require(ReplicatedStorage.Modules.CombatUtil)
function CombatUtil.IsGunReloading()
    return false
end
function CombatUtil:CanAttack()
    return true
end

local successFlags, combatRemoteThread = pcall(function()
    return require(Modules.Flags).COMBAT_REMOTE_THREAD or false
end)

local successHitFunction, hitFunction = pcall(function()
    return (getmenv or getsenv)(Net)._G.SendHitsToServer
end)

local function sendAttack(cooldown, hitPart, targets)
    RegisterAttack:FireServer(cooldown)

    if successFlags and combatRemoteThread and successHitFunction and hitFunction then
        hitFunction(hitPart, targets)
    else
        RegisterHit:FireServer(hitPart, targets)
    end
end

local function equipToolByName(toolName)
    local character, _, humanoid = getCharacterParts()
    if not character or not humanoid then return nil end

    local equipped = character:FindFirstChild(toolName)
    if equipped and equipped:IsA("Tool") then return equipped end

    local backpack = Player:FindFirstChild("Backpack")
    local tool = backpack and backpack:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then
        humanoid:EquipTool(tool)
        return tool
    end

    return nil
end

local function equipMelee()
    local character, _, humanoid = getCharacterParts()
    if not character or not humanoid then return nil end

    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped and equipped.ToolTip == "Melee" then
        return equipped
    end

    local backpack = Player:FindFirstChild("Backpack")
    if not backpack then return nil end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            humanoid:EquipTool(tool)
            return tool
        end
    end

    return nil
end

local function attackBoss(boss)
    if not isAlive(boss) then return end

    local character, root = getCharacterParts()
    if not character or not root then return end

    local weapon = character:FindFirstChildOfClass("Tool")
    if not weapon or weapon.ToolTip ~= "Melee" then return end

    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return end
    if (root.Position - bossRoot.Position).Magnitude > Config.AttackRange then return end

    local now = os.clock()
    if now - State.LastAttackAt < Config.AttackInterval then return end
    State.LastAttackAt = now

    local hitPart = boss:FindFirstChild("Head") or bossRoot
    pcall(function()
        sendAttack(Config.AttackInterval, hitPart, {{boss, hitPart}})
    end)
end

local function getSummoner()
    local map = workspace:FindFirstChild("Map")
    local arena = map and map:FindFirstChild("DarkbeardArena")
    return arena and arena:FindFirstChild("Summoner")
end

local function getSummonerPosition(summoner)
    if not summoner then return nil end
    if summoner:IsA("BasePart") then return summoner.Position end
    return getInstancePosition(summoner)
end

local function summonDarkbeard()
    local fist = equipToolByName("Fist of Darkness") or findTool("Fist of Darkness")
    if not fist then return false end

    local summoner = getSummoner()
    local position = getSummonerPosition(summoner)
    if not summoner or not position then
        setStatus("Summoner not found", "SUMMONING")
        return false
    end

    cancelMovement()
    startMovement(position)
    waitMovement(120)

    local _, root = getCharacterParts()
    if not root then return false end

    root.CFrame = CFrame.new(position)
    local touchPart = findTouchPart(summoner)
    forceTouch(root, touchPart)

    local deadline = os.clock() + 12
    while State.Running and os.clock() < deadline do
        local boss, source = findDarkbeard()
        -- Confirm only the real workspace boss. A replicated-only model may be
        -- the stale reset/template instance from a previous Darkbeard kill.
        if boss and source == "workspace" then
            State.Darkbeard = boss
            return true
        end
        task.wait(0.25)
    end

    return false
end

-- UI.
if CoreGui:FindFirstChild("DarkFragUI") then
    CoreGui.DarkFragUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkFragUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 190)
MainFrame.Position = UDim2.new(0, 15, 0.5, -95)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0.12
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(180, 50, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
TitleBar.BackgroundTransparency = 0.25
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -12, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Dark Fragment Farm - 4H+2H | SB200 FIX"
Title.TextColor3 = Color3.fromRGB(190, 100, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -38)
Content.Position = UDim2.new(0, 10, 0, 35)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local function createLabel(y, text, color, size, font)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 17)
    label.Position = UDim2.new(0, 0, 0, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextSize = size or 11
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
    return label
end

local StatusLabel = createLabel(0, "Status: Starting...", Color3.fromRGB(100, 255, 150), 11, Enum.Font.GothamSemibold)
local CountLabel = createLabel(19, "Chests: 0 | Kills: 0", Color3.fromRGB(255, 215, 80), 11, Enum.Font.GothamSemibold)
local FragmentLabel = createLabel(38, "Fragments: 0/" .. Config.CompletionTarget, Color3.fromRGB(210, 120, 255), 11, Enum.Font.GothamSemibold)
local PhaseLabel = createLabel(57, "Phase: INIT", Color3.fromRGB(150, 140, 255), 11)
local WSLabel = createLabel(76, "WebSocket: connecting", Color3.fromRGB(130, 190, 255), 10)
local ServerTimeLabel = createLabel(95, "Server Time (TimeIn): waiting...", Color3.fromRGB(255, 232, 133), 10, Enum.Font.GothamSemibold)
local WindowLabel = createLabel(114, "4h + 2h Window: waiting...", Color3.fromRGB(183, 207, 232), 10, Enum.Font.GothamSemibold)
local ExtraLabel = createLabel(133, "Target: --", Color3.fromRGB(170, 170, 190), 10)

local dragging = false
local dragStart
local startPosition

bindConnection(TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = MainFrame.Position
    end
end))

bindConnection(TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

bindConnection(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

task.spawn(function()
    while State.Running do
        local fragments = getMaterialCount("Dark Fragment")
        StatusLabel.Text = "Status: " .. State.Status
        CountLabel.Text = "Chests: " .. State.ChestCount .. " | Kills: " .. State.KillCount
        FragmentLabel.Text = "Fragments: " .. fragments .. "/" .. Config.CompletionTarget
        PhaseLabel.Text = "Phase: " .. State.Phase
        WSLabel.Text = "WebSocket: " .. (State.WSConnected and "connected" or "offline")

        local inWindow, uptime, source, timeInfo = CheckChestTimeWindow()
        if uptime then
            ServerTimeLabel.Text = "Server Time (TimeIn): " .. FormatUptime(uptime)
            WindowLabel.Text = "4h + 2h Window: " .. buildWindowStatus(inWindow, uptime, timeInfo)
            WindowLabel.TextColor3 = inWindow
                and Color3.fromRGB(109, 222, 161)
                or Color3.fromRGB(246, 197, 88)
        else
            ServerTimeLabel.Text = "Server Time (TimeIn): waiting..."
            WindowLabel.Text = "4h + 2h Window: cannot evaluate"
            WindowLabel.TextColor3 = Color3.fromRGB(239, 104, 104)
            if State.Phase == "TIME_CHECK" then
                State.Extra = tostring(source or ServerTimeRuntime.LastError or "unknown")
            end
        end

        ExtraLabel.Text = State.Extra
        task.wait(0.35)
    end
end)

-- WebSocket client.
local function getWebSocketConnector()
    local env = getgenv()

    if type(env.WebSocket) == "table" and type(env.WebSocket.connect) == "function" then
        return env.WebSocket.connect
    end
    if type(env.websocket) == "table" and type(env.websocket.connect) == "function" then
        return env.websocket.connect
    end
    if type(env.syn) == "table" and type(env.syn.websocket) == "table"
        and type(env.syn.websocket.connect) == "function" then
        return env.syn.websocket.connect
    end
    if type(WebSocket) == "table" and type(WebSocket.connect) == "function" then
        return WebSocket.connect
    end

    return nil
end

local function wsSend(payload)
    local socket = State.WS
    if not socket then return false end

    local ok = pcall(function()
        socket:Send(HttpService:JSONEncode(payload))
    end)
    return ok
end

local function sendHello()
    return wsSend({
        type = "hello",
        version = 2,
        player = Player.Name,
        userId = Player.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        playerCount = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
    })
end

local function sendSignal(action)
    local key = action .. ":" .. game.JobId
    local now = os.clock()
    if State.LastSignalKey == key and now - State.LastSignalAt < 5 then
        return false
    end

    State.LastSignalKey = key
    State.LastSignalAt = now

    return wsSend({
        type = "signal",
        action = action,
        player = Player.Name,
        userId = Player.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        playerCount = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
        sentAt = os.time(),
    })
end

local function teleportToJob(jobId)
    if type(jobId) ~= "string" or jobId == "" or jobId == game.JobId then
        return false
    end

    State.VisitedServers[jobId] = os.clock() + Config.ServerBlacklistSeconds
    local ok = pcall(function()
        ServerBrowser:InvokeServer("teleport", jobId)
    end)
    return ok
end

local function handleWebSocketMessage(message)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(message)
    end)
    if not ok or type(data) ~= "table" then return end

    if data.type == "ping" then
        wsSend({type = "pong", time = os.time()})
        return
    end

    if data.type ~= "signal" then return end
    if data.placeId and tonumber(data.placeId) ~= game.PlaceId then return end
    if type(data.jobId) ~= "string" or data.jobId == game.JobId then return end

    local playerCount = tonumber(data.playerCount) or 99
    local maxPlayers = tonumber(data.maxPlayers) or 12
    if playerCount >= maxPlayers then return end

    local now = os.clock()
    if now - State.LastSignalJoinAt < Config.SignalJoinCooldown then return end
    if State.Hopping then return end

    local expiresAt = tonumber(data.expiresAt)
    if expiresAt and os.time() > expiresAt then return end

    State.LastSignalJoinAt = now
    setStatus(
        "Joining " .. tostring(data.action or "signal") .. " server...",
        "JOINING",
        "JobId: " .. string.sub(data.jobId, 1, 8)
    )
    teleportToJob(data.jobId)
end

local function connectWebSocket()
    if not Config.EnableWebSocket then return false end

    local connector = getWebSocketConnector()
    if not connector then
        debugPrint("Executor does not expose a WebSocket connector")
        return false
    end

    local ok, socket = pcall(connector, Config.WSUrl)
    if not ok or not socket then
        return false
    end

    State.WS = socket
    State.WSConnected = true

    if socket.OnMessage then
        socket.OnMessage:Connect(handleWebSocketMessage)
    end

    if socket.OnClose then
        socket.OnClose:Connect(function()
            if State.WS == socket then
                State.WS = nil
                State.WSConnected = false
            end
        end)
    end

    sendHello()
    return true
end

task.spawn(function()
    while State.Running and Config.EnableWebSocket do
        if not State.WSConnected or not State.WS then
            State.WS = nil
            State.WSConnected = false
            connectWebSocket()
        else
            sendHello()
        end
        task.wait(State.WSConnected and 20 or 3)
    end
end)

-- Server hopping.
local teleportFailedFor = nil
bindConnection(TeleportService.TeleportInitFailed:Connect(function(_, result, message, placeId, options)
    teleportFailedFor = options and options.ServerInstanceId or "unknown"
    debugPrint("Teleport failed:", tostring(result), tostring(message), tostring(placeId))
end))

local function serverBlocked(jobId)
    if jobId == game.JobId then return true end

    local expires = State.VisitedServers[jobId]
    if not expires then return false end
    if expires <= os.clock() then
        State.VisitedServers[jobId] = nil
        return false
    end
    return true
end

local function getServersFromBrowser()
    local pages = {}
    local startPage = tonumber(State.HopNextPage) or 1
    if startPage < 1 or startPage > Config.HopMaxPages then
        startPage = 1
    end

    for offset = 0, Config.HopPagesPerBatch - 1 do
        pages[#pages + 1] = ((startPage - 1 + offset) % Config.HopMaxPages) + 1
    end

    local servers = {}
    local seenJobs = {}
    local cursor = 0
    local completed = 0
    local failed = 0
    local workersDone = 0
    local active = true
    local workerCount = math.min(Config.HopScanConcurrency, #pages)
    local startedAt = os.clock()

    State.HopScan.Status = "Scanning"
    State.HopScan.RequestedPages = #pages
    State.HopScan.CompletedPages = 0
    State.HopScan.FailedPages = 0
    State.HopScan.Candidates = 0
    State.HopScan.TimedOut = false

    local function processPage(data)
        if type(data) ~= "table" then return end

        for jobId, info in pairs(data) do
            local id = tostring(jobId)
            local count = type(info) == "table" and tonumber(info.Count) or nil

            if id ~= tostring(game.JobId)
                and not seenJobs[id]
                and count
                and count >= 1
                and count <= Config.HopMaxPlayers
                and not serverBlocked(id) then
                seenJobs[id] = true
                servers[#servers + 1] = {
                    id = id,
                    playing = count,
                    lastUpdate = tonumber(info.__LastUpdate) or 0,
                    region = info.Region or info.Regoin or "Unknown",
                }
            end
        end
    end

    local function worker()
        while active do
            cursor = cursor + 1
            local index = cursor
            local page = pages[index]
            if not page then break end

            local ok, data = pcall(function()
                return ServerBrowser:InvokeServer(page)
            end)

            if not active then break end

            if ok and type(data) == "table" then
                processPage(data)
            else
                failed = failed + 1
            end

            completed = completed + 1
            State.HopScan.CompletedPages = completed
            State.HopScan.FailedPages = failed
            State.HopScan.Candidates = #servers

            if completed == #pages or completed % 10 == 0 then
                setStatus(
                    "ServerBrowser scan " .. completed .. "/" .. #pages,
                    "HOPPING",
                    "Workers: " .. workerCount
                        .. " | Candidates: " .. #servers
                        .. " | Failed: " .. failed
                )
            end
        end

        workersDone = workersDone + 1
    end

    for _ = 1, workerCount do
        task.spawn(worker)
    end

    repeat
        task.wait(0.05)
    until workersDone >= workerCount
        or (os.clock() - startedAt) >= Config.HopBatchTimeout

    if workersDone < workerCount then
        active = false
        State.HopScan.TimedOut = true
        State.HopScan.Status = "Timeout"
    else
        State.HopScan.Status = "Complete"
    end

    local lastPage = pages[#pages] or startPage
    State.HopNextPage = (lastPage % Config.HopMaxPages) + 1

    table.sort(servers, function(a, b)
        if a.playing ~= b.playing then
            return a.playing < b.playing
        end
        if a.lastUpdate ~= b.lastUpdate then
            return a.lastUpdate > b.lastUpdate
        end
        return a.id < b.id
    end)

    State.HopScan.Candidates = #servers
    return servers
end

local function hopServer(reason)
    if State.Hopping then return end
    State.Hopping = true
    cancelMovement()
    State.VisitedServers[game.JobId] = math.huge

    while State.Running do
        setStatus(
            reason or "Finding server...",
            "HOPPING",
            "ServerBrowser only | parallel scan up to "
                .. Config.HopPagesPerBatch
                .. "/"
                .. Config.HopMaxPages
                .. " pages"
        )

        -- Public games.roblox.com server API was intentionally removed.
        local servers = getServersFromBrowser()

        if #servers == 0 then
            setStatus(
                "No eligible ServerBrowser result; retrying...",
                "HOPPING",
                "Completed: " .. State.HopScan.CompletedPages
                    .. "/" .. State.HopScan.RequestedPages
                    .. " | Failed: " .. State.HopScan.FailedPages
            )
            task.wait(2)
            continue
        end

        -- Same choice policy as the Cyborg scanner: lowest player count first.
        local selected = servers[1]
        State.VisitedServers[selected.id] = os.clock() + Config.ServerBlacklistSeconds
        teleportFailedFor = nil

        setStatus(
            "Joining best ServerBrowser server (" .. selected.playing .. " players)...",
            "HOPPING",
            "JobId: " .. string.sub(selected.id, 1, 8)
                .. " | Region: " .. tostring(selected.region)
        )

        local ok = pcall(function()
            ServerBrowser:InvokeServer("teleport", selected.id)
        end)

        if not ok then
            teleportFailedFor = selected.id
        end

        local deadline = os.clock() + Config.HopWaitSeconds
        while State.Running and os.clock() < deadline do
            if teleportFailedFor then break end
            task.wait(0.35)
        end
    end

    State.Hopping = false
end

-- Anti-idle.
bindConnection(Player.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end))

local function targetReached()
    return getMaterialCount("Dark Fragment") >= Config.CompletionTarget
end

local function finishIfComplete()
    local amount = getMaterialCount("Dark Fragment")
    if amount < Config.CompletionTarget then return false end

    if not writeCompletedFragmentFile() then
        setStatus(
            "Target reached but completion file failed",
            "ERROR",
            CompletionFile .. " | " .. tostring(State.CompletionFileError)
        )
        task.wait(2)
        return false
    end

    local completionExtra = Config.ChangeDF > 0
        and ("Saved: " .. CompletionFile .. " = Completed-fragment")
        or "Farm stopped"

    setStatus("DONE! " .. amount .. " Dark Fragments", "COMPLETE", completionExtra)
    cancelMovement()

    if State.WS then
        pcall(function()
            State.WS:Close()
        end)
    end
    State.WS = nil
    State.WSConnected = false
    State.Running = false
    getgenv().DarkFragRunning = false
    return true
end

local function farmDarkbeard()
    local initialBoss, initialSource = findDarkbeard()
    if not initialBoss then
        return false
    end

    if initialSource == "workspace" then
        sendSignal("darkbeard_found")
        setStatus("Darkbeard found", "FARMING", "Target: live Darkbeard")
    else
        setStatus(
            "Darkbeard replicated; locating live boss...",
            "FARMING",
            "Waiting for workspace spawn"
        )
    end

    local sawLiveBoss = false
    local liveMissingSince = nil
    local replicatedOnlySince = initialSource == "replicated" and os.clock() or nil

    while State.Running do
        if finishIfComplete() then return true end

        local boss, source = findDarkbeard()
        State.Darkbeard = boss

        -- Critical fix:
        -- Once a real workspace boss has been observed, a Darkbeard model that
        -- reappears only in ReplicatedStorage is treated as the reset template.
        -- It must not reset the death timer or keep the account on
        -- "Darkbeard found" forever.
        if source == "workspace" and boss and isAlive(boss) then
            if not sawLiveBoss then
                sawLiveBoss = true
                sendSignal("darkbeard_found")
                setStatus("Darkbeard found", "FARMING", "Target: live Darkbeard")
            end
            liveMissingSince = nil
            replicatedOnlySince = nil
        elseif sawLiveBoss then
            liveMissingSince = liveMissingSince or os.clock()

            if os.clock() - liveMissingSince >= Config.BossDeathConfirmDelay then
                State.KillCount = State.KillCount + 1
                State.Darkbeard = nil
                State.IgnoreReplicatedDarkbeardUntil = os.clock()
                    + Config.ReplicatedBossIgnoreSeconds
                cancelMovement()
                setStatus(
                    "Darkbeard defeated",
                    "BOSS_DONE",
                    "Confirmed workspace boss disappeared"
                )
                task.wait(2)
                refreshMaterialCounts()
                return true
            end

            task.wait(0.15)
            continue
        elseif source == "replicated" then
            replicatedOnlySince = replicatedOnlySince or os.clock()

            if os.clock() - replicatedOnlySince >= Config.ReplicatedBossLocateTimeout then
                State.Darkbeard = nil
                State.IgnoreReplicatedDarkbeardUntil = os.clock()
                    + Config.ReplicatedBossIgnoreSeconds
                cancelMovement()
                setStatus(
                    "Ignored stale replicated Darkbeard",
                    "BOSS_STALE",
                    "No live workspace boss appeared"
                )
                return false
            end
        else
            liveMissingSince = liveMissingSince or os.clock()

            if not sawLiveBoss
                and os.clock() - liveMissingSince >= Config.ReplicatedBossLocateTimeout then
                cancelMovement()
                return false
            end

            task.wait(0.2)
            continue
        end

        local character, root = getCharacterParts()
        if not character or not root then
            cancelMovement()
            setStatus("Character dead; waiting...", "DEAD")
            waitForAliveCharacter()
            task.wait(1)
            continue
        end

        equipMelee()

        local bossRoot = boss and boss:FindFirstChild("HumanoidRootPart")
        if bossRoot then
            local targetCFrame = bossRoot.CFrame * CFrame.new(0, Config.BossHeight, 0)
            local distance = (root.Position - bossRoot.Position).Magnitude

            if distance > 72 then
                if not State.MoveTarget
                    or (State.MoveTarget - targetCFrame.Position).Magnitude > 12 then
                    startMovement(targetCFrame.Position)
                end
            else
                cancelMovement()
                root.CFrame = targetCFrame
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end

        -- Never attack the ReplicatedStorage template. It is only used as a
        -- temporary location hint while waiting for the real workspace model.
        if source == "workspace" then
            attackBoss(boss)
        end

        task.wait(Config.AttackInterval)
    end

    return false
end

-- Main state machine.
task.spawn(function()
    while State.Running and not State.MaterialReady do
        setStatus("Waiting for material replication...", "INIT")
        task.wait(0.2)
    end

    while State.Running do
        if finishIfComplete() then return end

        local boss = findDarkbeard()
        State.Darkbeard = boss
        State.HasFist = hasFistOfDarkness()

        if boss then
            local killed = farmDarkbeard()
            if killed and State.Running then
                hopServer("Darkbeard finished; finding next server...")
            end
            task.wait(0.5)
            continue
        end

        if State.HasFist then
            sendSignal("fist_found")
            setStatus("Fist of Darkness found", "SUMMONING", "Moving to Summoner")

            local summoned = summonDarkbeard()
            if summoned then
                local killed = farmDarkbeard()
                if killed and State.Running then
                    hopServer("Darkbeard finished; finding next server...")
                end
            else
                setStatus("Summon not confirmed; retrying...", "SUMMONING")
                task.wait(2)
            end
            continue
        end

        -- Chest farming is allowed only inside the exact Cyborg 4h + 2h windows.
        -- Boss/Fist checks above always have priority, even outside the window.
        if Config.RequireChestTimeWindow then
            local inWindow, uptime, uptimeSource, timeInfo = CheckChestTimeWindow()

            if not uptime then
                setStatus(
                    "Cannot read server uptime",
                    "TIME_CHECK",
                    tostring(uptimeSource or ServerTimeRuntime.LastError or "unknown")
                )
                task.wait(Config.TimeInRetryDelay)
                continue
            elseif not inWindow then
                setStatus(
                    "Outside valid 4h + 2h window",
                    "TIME_HOP",
                    "Uptime: "
                        .. FormatUptime(uptime)
                        .. " | Next valid: "
                        .. FormatUptime(timeInfo.NextBoundary)
                )
                task.wait(1)
                hopServer("Outside 4h + 2h chest window; hopping...")
                continue
            end
        end

        State.Phase = "CHESTING"
        State.ChestCount = 0
        State.ConfirmedChestKeys = {}
        State.FailedChestKeys = {}
        local emptyScans = 0
        local timeWindowHop = false
        local timeWindowUnavailable = false
        setStatus("Scanning chests...", "CHESTING", "Target: nearest chest")

        while State.Running and State.ChestCount < Config.MaxChestsBeforeHop do
            if finishIfComplete() then return end

            State.Darkbeard = findDarkbeard()
            State.HasFist = hasFistOfDarkness()
            if State.Darkbeard or State.HasFist then break end

            -- Re-check during chesting so crossing 6h/10h/... immediately stops chest farm.
            if Config.RequireChestTimeWindow then
                local inWindow, uptime, uptimeSource, timeInfo = CheckChestTimeWindow()

                if not uptime then
                    timeWindowUnavailable = true
                    setStatus(
                        "Cannot read server uptime",
                        "TIME_CHECK",
                        tostring(uptimeSource or ServerTimeRuntime.LastError or "unknown")
                    )
                    break
                elseif not inWindow then
                    timeWindowHop = true
                    setStatus(
                        "4h + 2h window closed",
                        "TIME_HOP",
                        "Uptime: "
                            .. FormatUptime(uptime)
                            .. " | Next valid: "
                            .. FormatUptime(timeInfo.NextBoundary)
                    )
                    break
                end
            end

            local _, root = getCharacterParts()
            if not root then
                cancelMovement()
                setStatus("Character dead; waiting...", "DEAD")
                waitForAliveCharacter()
                task.wait(1)
                continue
            end

            local chests = scanChests()
            if #chests == 0 then
                emptyScans = emptyScans + 1
                setStatus(
                    "No usable chest found",
                    "CHESTING",
                    "Empty scan " .. emptyScans .. "/" .. Config.EmptyScansBeforeHop
                )

                if emptyScans >= Config.EmptyScansBeforeHop then
                    break
                end

                task.wait(Config.RescanDelay)
                continue
            end

            emptyScans = 0

            for index, chest in ipairs(chests) do
                if not State.Running or State.ChestCount >= Config.MaxChestsBeforeHop then break end
                if findDarkbeard() or hasFistOfDarkness() then break end

                -- Re-check before every chest as well, preserving the exact close boundary.
                if Config.RequireChestTimeWindow then
                    local inWindow, uptime, uptimeSource, timeInfo = CheckChestTimeWindow()

                    if not uptime then
                        timeWindowUnavailable = true
                        setStatus(
                            "Cannot read server uptime",
                            "TIME_CHECK",
                            tostring(uptimeSource or ServerTimeRuntime.LastError or "unknown")
                        )
                        break
                    elseif not inWindow then
                        timeWindowHop = true
                        setStatus(
                            "4h + 2h window closed",
                            "TIME_HOP",
                            "Uptime: "
                                .. FormatUptime(uptime)
                                .. " | Next valid: "
                                .. FormatUptime(timeInfo.NextBoundary)
                        )
                        break
                    end
                end

                local _, currentRoot = getCharacterParts()
                if not currentRoot then break end

                local freshPosition = getInstancePosition(chest.Instance)
                if freshPosition then
                    chest.Position = freshPosition
                    chest.Distance = (currentRoot.Position - freshPosition).Magnitude
                end

                setStatus(
                    "Moving to chest",
                    "CHESTING",
                    "Target: " .. chest.Name .. " #" .. index
                )

                local result = collectChest(chest)
                if result == "priority_found" then break end

                if result then
                    setStatus(
                        "Chest collected",
                        "CHESTING",
                        "Confirmed chests: " .. State.ChestCount
                    )
                else
                    setStatus("Chest not confirmed; skipped", "CHESTING")
                end
            end

            task.wait(0.25)
        end

        if not State.Running then return end

        if timeWindowUnavailable then
            task.wait(Config.TimeInRetryDelay)
            continue
        end

        if timeWindowHop then
            task.wait(1)
            hopServer("4h + 2h chest window closed; hopping...")
            continue
        end

        State.Darkbeard = findDarkbeard()
        State.HasFist = hasFistOfDarkness()
        if State.Darkbeard or State.HasFist then
            continue
        end

        hopServer(
            "No Fist after " .. State.ChestCount .. " confirmed chests; hopping..."
        )
    end
end)
