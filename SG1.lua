getgenv().Settings = {
    ["Max Chests"] = 30; -- if you collected 50 chests, hop server
    ["Reset After Collect Chests"] = 10; -- if you collected 10 chests, it will reset for safe (anti kick)
}

repeat task.wait(0.5) until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
getgenv().WARCLOADER = true task.delay(10, (function() getgenv().WARCLOADER = nil end))

getgenv().cloneref = cloneref or clonereference or function(x) return x end
getgenv().isnetworkowner = isnetworkowner or isNetworkOwner or function() return true end
workspace = cloneref(workspace) or cloneref(Workspace) or (getrenv and (getrenv().workspace or getrenv().Workspace)) or cloneref(game:GetService("Workspace"))
PlaceId, JobId = game.PlaceId, game.JobId
getfenv = getfenv or _G or _ENV or shared or function() return {} end
IsOnMobile = false
Services = setmetatable({}, {__index = function(self, name)
    local s, c = pcall(function() return cloneref(game:GetService(name)) end)
    if s then rawset(self, name, c) return c
    else error("Invalid Roblox Service: " .. tostring(name))
    end
end})
COREGUI = Services.CoreGui
RunService = Services.RunService
VirtualUser = Services.VirtualUser
TweenService = Services.TweenService
HttpService = Services.HttpService
Players = Services.Players
ReplicatedStorage = Services.ReplicatedStorage
Lighting = Services.Lighting
CollectionService = Services.CollectionService
UserInputService = Services.UserInputService
VirtualInputManager = Services.VirtualInputManager
ReplicatedFirst = Services.ReplicatedFirst
StarterGui = Services.StarterGui
GuiService = Services.GuiService
TeleportService = Services.TeleportService
COMMF_ = ReplicatedStorage:WaitForChild("Remotes") and ReplicatedStorage.Remotes:WaitForChild("CommF_")
LocalPlayer = Players.LocalPlayer
LocalPlayer.CharacterAdded:Connect(function(v)
    Character = v Humanoid = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)
if LocalPlayer.Character then
    Character = LocalPlayer.Character
    Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart")
end

StarterGui:SetCore("SendNotification", {Title = "Executed", Text = "Loading... Please wait", Duration = 5})
if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    local WFGTL = COREGUI:FindFirstChild("WFGTL") or Instance.new("Hint", COREGUI)
    WFGTL.Text = "Just a moment... Waiting while the game loads - This won't take long!"
    task.wait(10 - workspace.DistributedGameTime)
    WFGTL:Destroy()
end
if not COMMF_ then repeat task.wait(1) until COMMF_ end
task.spawn(function()
    xpcall(function()
        if not LocalPlayer.Team then
            if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
                repeat task.wait(1) until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
            end
            xpcall(function() COMMF_:InvokeServer("SetTeam", "Pirates")
            end, function() firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container.Pirates) end)
            task.wait(2)
        end
    end, function(err) warn("????", err) end)
end)
repeat task.wait(2) until Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChildWhichIsA("Humanoid") and Character:IsDescendantOf(workspace.Characters)
pcall(function() LocalPlayer.PlayerGui:FindFirstChild("Blank"):Destroy() end)
local BlankScreen = LocalPlayer.PlayerGui:FindFirstChild("Blank") or Instance.new("ScreenGui", LocalPlayer.PlayerGui)
BlankScreen.Name = "Blank" BlankScreen.ResetOnSpawn = false BlankScreen.DisplayOrder = -math.huge BlankScreen.IgnoreGuiInset = true
local label = Instance.new("TextLabel", BlankScreen)
label.Name = "CenteredLabel"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.new(0.5, 0, 0.5, 0)
label.Size = UDim2.new(0.6, 0, 0.15, 0)
label.Text = string.rep("Nil ", 20)
label.TextScaled = true
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamSemibold
label.TextSize = 48
label.TextColor3 = Color3.fromRGB(255, 255, 255)
local function SetText(newText) label.Text = newText end
function CheckSea(v: number) return v == tonumber(workspace:GetAttribute("MAP"):match("%d+")) end
local remoteAttack, idremote
local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
task.spawn((function() for _, v in next, ({ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX}) do
    for _, n in next, v:GetChildren() do if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
    end v.ChildAdded:Connect(function(n) if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id")
    end end) end
end))

CheckLocation = (function(v)return LocalPlayer:GetAttribute("CurrentLocation") == v end)
CheckMap = (function(v) return workspace.Map:FindFirstChild(v) or false end)
CheckTool = (function(v)
    for _, x in next, {LocalPlayer.Backpack, Character} do
    for _, v2 in next, x:GetChildren() do if v2:IsA("Tool") and (v2.Name == v or v2.Name:find(v)) then return true end
    end end return false
end)
CheckMaterial = (function(x)
    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do if v.Type == "Material" then if v.Name == x then return v.Count end end
    end return 0
end)
CheckInventory = (function(...)
    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
    for _, n in next, {...} do if v.Name == n then return true end end
    end return false
end)
KillAura = (function(vName)
    pcall(function() setscriptable(LocalPlayer, "SimulationRadius", true) end)
    pcall(function() sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge) end)
    for _, v in next, workspace.Enemies:GetChildren() do
        pcall(function()
            local hrp = v:FindFirstChild("HumanoidRootPart") or false
            if hrp and HumanoidRootPart and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 1250 then
                local cond = (vName and v.Name == vName) or not vName
                if cond then
                    v:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
                end
            end
        end)
    end
end)
CheckMoon = (function()
    local tex =
        (CheckSea(1) or CheckSea(3)) and ((game.Lighting:FindFirstChild("Sky") and game.Lighting.Sky.MoonTextureId)
        or (game.Lighting:FindFirstChild("Space_Skybox") and game.Lighting.Space_Skybox.MoonTextureId))
        or (CheckSea(2) and game.Lighting:FindFirstChild("FantasySky") and game.Lighting.FantasySky.MoonTextureId)
        or ""
    tex = tex:gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    return ({
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon";
        ["http://www.roblox.com/asset/?id=9709149431"] = "8/8";
        ["http://www.roblox.com/asset/?id=9709149052"] = "7/8";
        ["http://www.roblox.com/asset/?id=9709143733"] = "6/8";
        ["http://www.roblox.com/asset/?id=9709150401"] = "5/8";
        ["http://www.roblox.com/asset/?id=9709135895"] = "4/8";
        ["http://www.roblox.com/asset/?id=9709150086"] = "2/8";
        ["http://www.roblox.com/asset/?id=9709139597"] = "1/8";
        ["http://www.roblox.com/asset/?id=9709149680"] = "0/8";
})[tex] or "nil"
end)
CheckMonster = (function(...) local args = {...}
    local v2 = {workspace.Enemies, ReplicatedStorage}
    for i = 1, #args do local n = args[i]
        local m = workspace.Enemies:FindFirstChild(n) or ReplicatedStorage:FindFirstChild(n)
        if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
            local h = m:FindFirstChild("Humanoid") local r = m:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then return m end
        end
    end
    for c = 1, #v2 do local container = v2[c] local ms = container:GetChildren()
        for m = 1, #ms do local m = ms[m] local h = m:FindFirstChild("Humanoid")
            local r = m:FindFirstChild("HumanoidRootPart")
            if m:IsA("Model") and h and r and h.Health > 0 and m.Name ~= "Blank Buddy" then
                for i = 1, #args do local n = args[i]
                    if m.Name == n or m.Name:lower():find(n:lower()) then
                        return m
                    end
                end
            end
        end
    end
    return false
end)

EquipWeapon = (function(v)
    if not Character then return end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if tool and (tool.ToolTip and tool.ToolTip == v) then return end
    for _, x in next, LocalPlayer.Backpack:GetChildren() do
        if x:IsA("Tool") and x.ToolTip == v then
            Humanoid:EquipTool(x)
            return
        end
    end
end)

local lastCallFA = tick()
FastAttack = (function(x)
    if not HumanoidRootPart or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
    local FAD = 0.01
    if FAD ~= 0 and tick() - lastCallFA <= FAD then return end
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid") local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then t[#t + 1] = e end
    end
    local n = ReplicatedStorage.Modules.Net
    local h = {[2] = {}}
    local last
    for i = 1, #t do local v = t[i]
        local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
        if not h[1] then h[1] = part end
        h[2][#h[2] + 1] = {v, part} last = v
    end
    n:FindFirstChild("RE/RegisterAttack"):FireServer()
    n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".",function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
    end), bit32.bxor(idremote+909090, seed*2), unpack(h))
    lastCallFA = tick()
end)

function IfTableHaveIndex(j)
    for _ in j do
        return true
    end
end
local LastServersDataPulled, CachedServers
function GetServers()
    if LastServersDataPulled then
        if os.time() - LastServersDataPulled < 60 then
            return CachedServers
        end
    end
    for i = 1, 100, 1 do
        local data = game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer(i)
        if IfTableHaveIndex(data) then
            LastServersDataPulled = os.time()
            CachedServers = data
            return data
        end
    end
end
HopServer = function(Reason, MaxPlayers, ForcedRegion)
    local Servers = GetServers()
    local ArrayServers = {}
    for i, v in Servers do
        table.insert(ArrayServers, {
            JobId = i,
            Players = v.Count,
            LastUpdate = v.__LastUpdate,
            Region = v.Region
        })
    end
    print(#ArrayServers, 'servers received')
    local ServerData
    for i = 1, #ArrayServers do
        while task.wait() do
            local Index = math.random(1, #ArrayServers)
            ServerData = ArrayServers[Index]
            if ServerData then
                if not MaxPlayers or ServerData.Players < 5 then
                    if not ForcedRegion or ServerData.Region == ForcedRegion then
                        print("Found Server:", ServerData.JobId, 'Player Count:', ServerData.Players, "Region:", ServerData.Region)
                        break
                    end
                end
            end
        end
        print('Teleporting to', ServerData.JobId, '...')
        ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer('teleport', ServerData.JobId)
    end
end
CheckLocation = (function(v) return LocalPlayer:GetAttribute("CurrentLocation") == v end)
local function getCFrame(v)
    if not v then return nil end
    if typeof(v) == "CFrame" then return v end
    if typeof(v) == "Vector3" then return CFrameNew(v) end
    if typeof(v) ~= "Instance" then return end
    if v:IsA("BasePart") then return v.CFrame end
    if v:IsA("Model") then
        if v.GetPivot then return v:GetPivot() end
        local root = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart")
        if root then return root.CFrame end
    end
    if v:IsA("CFrameValue") then return v.Value end
    if v:IsA("Vector3Value") then return CFrameNew(v.Value) end
end
local connection, tween, pathPart, isTweening = nil, nil, nil, false
function Tween(targetCFrame: CFrame | boolean, target: CFrame)
    if targetCFrame == false then
        if tween then pcall(function() tween:Cancel() end) tween = nil end
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        isTweening = false
        return
    end
    targetCFrame = getCFrame(targetCFrame)
    if isTweening or not targetCFrame then return end
    isTweening = true
    local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
    if not char then isTweening = false return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then isTweening = false return end
    humanoid.Sit = false
    target = target or root
    local distance = (targetCFrame.Position - target.Position).Magnitude
    if target == root then
        if distance < 200 then
            target.CFrame = targetCFrame
            isTweening = false
            return
        end
    end
    pathPart = Instance.new("Part")
    pathPart.Name = "TweenGhost"
    pathPart.Transparency = 1
    pathPart.Anchored = true
    pathPart.CanCollide = false
    pathPart.CFrame = target.CFrame
    pathPart.Size = Vector3.new(50, 50, 50)
    pathPart.Parent = workspace
    tween = game:GetService("TweenService"):Create(pathPart, TweenInfo.new(distance / 275, Enum.EasingStyle.Linear), {CFrame = targetCFrame * (function()
        if target ~= root then
            return CFrame.new(0, 30, 0)
        end
        return CFrame.new(0, 5, 0)
    end)()})
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if target and pathPart then
            target.CFrame = pathPart.CFrame * (function()
                if target ~= root then
                    return CFrame.new(0, 30, 0)
                end
                return CFrame.new(0, 5, 0)
            end)()
        end
    end)
    tween.Completed:Connect(function()
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        tween = nil
        isTweening = false
    end)
    tween:Play()
end

local lastGhost = tick()
BringMonster = (function(name, count) count = count or 3
    if count < 2 then return end
    pcall(function() setscriptable(LocalPlayer, "SimulationRadius", true) end)
    pcall(function() sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge) end)
    xpcall((function()
        local mob, t = {}, nil
        for _, v in next, workspace.Enemies:GetChildren() do
            local h = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 and (not name or v.Name == name)
                and (HumanoidRootPart.Position - hrp.Position).Magnitude <= ((count or 3) * 250) then
                if not table.find(mob, function(chosen)
                    local chrp = chosen:FindFirstChild("HumanoidRootPart")
                    return chrp and (hrp.Position - chrp.Position).Magnitude <= 5
                end) then mob[#mob+1], t = v, t or hrp.CFrame
                end
                if #mob >= (count or 3) then break end
            end
        end
        if not t then return end
        for i = 1, #mob do
            local hrp = mob[i]:FindFirstChild("HumanoidRootPart")
            local h = mob[i]:FindFirstChild("Humanoid")
            if hrp and (not isnetworkowner or isnetworkowner(hrp)) then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = t * CFrame.new((i-1) * 2, 0, 0)
            end
        end
    end), (function(r) warn("Modules Error [BM]: ".. r) end))
end)

TableQuests = setmetatable({}, {__index = function(_, k)
    local p, d, m, raw = HumanoidRootPart.Position
    for _, x in next, require(ReplicatedStorage.GuideModule).Data.NPCList do
        if x.InternalQuestName == k then
            local pos = x.Position
            if typeof(pos) == "Vector3" then
                local dist = (pos - p).Magnitude
                if not d or dist < d then d = dist m = pos raw = x.NPCName end
            elseif typeof(pos) == "table" then
                for _, v in next, pos do
                    if typeof(v) == "Vector3" then
                        local dist = (v - p).Magnitude
                        if not d or dist < d then d = dist m = v raw = x.NPCName end
                    end
                end
            end
        end
    end
    return m and {Position = m, Meters = d, RawNPCName = raw} or nil
end})

local lastKenCall=tick()
KillMonster=(function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _,v in next,workspace.Enemies:GetChildren() do
                local vh=v:FindFirstChild("Humanoid") local vhrp=v:FindFirstChild("HumanoidRootPart")
                if vh and vhrp and v.Name==x then
                    local dx,dy,dz=HumanoidRootPart.Position.X-vhrp.Position.X, HumanoidRootPart.Position.Y-vhrp.Position.Y, HumanoidRootPart.Position.Z-vhrp.Position.Z
                    local sqrMag=dx*dx+dy*dy+dz*dz
                    if sqrMag<=4900 then
                        BringMonster(x, 3)
                        FastAttack(x)
                        if tick()-lastKenCall>=10 then lastKenCall=tick() ReplicatedStorage.Remotes.CommE:FireServer("Ken",true) end
                        Tween(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                        EquipWeapon("Melee")
                        return
                    end
                    Tween(vhrp.CFrame) return
                end
            end
        end
        for _,v in next,ReplicatedStorage:GetChildren() do
            local vhrp=v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name==x then Tween(vhrp.CFrame) return end
        end
    end,function(e) warn("Modules ERROR:",e) end)
end)

-- ==========================================
-- [ FIREBASE MOON JOIN ]
-- Mỗi lần thử gọi lại Firebase để lấy JobID MỚI
-- 3 lần fail → fallback HopServer
-- ==========================================
local FIREBASE_URL = "https://apimoon-vunguyenlong-default-rtdb.firebaseio.com/moon.json"
local _firebaseReq = (syn and syn.request) or (http and http.request) or http_request or request

function TPServer(JobIdorstring)
    if string.find(JobIdorstring, "TeleportService") then
        local ok, err = pcall(function()
            loadstring(JobIdorstring)()
        end)
        return ok and "Success | Teleporting..." or err
    else
        game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", tostring(JobIdorstring))
        return "Trying to teleport..."
    end
end

local function GetPlayerCountNum(str)
    if not str then return 999 end
    return tonumber(str:match("(%d+)/")) or 999
end

-- Fetch Firebase 1 lần, trả về jobId hợp lệ hoặc nil + lý do
local function FetchFirebaseMoonJobId(triedJobIds)
    local ok, resp = pcall(function()
        return _firebaseReq({
            Url = FIREBASE_URL,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json"}
        })
    end)
    if not ok or not resp or not resp.Body or resp.Body == "null" then
        return nil, "Không có dữ liệu"
    end

    local data = HttpService:JSONDecode(resp.Body)
    if not data or not data.jobId then return nil, "Không có jobId" end

    local age = data.time and (os.time() - tonumber(data.time)) or 9999
    local playerNum = GetPlayerCountNum(data.playerCount)

    if age >= 600 then return nil, "Tín hiệu cũ (" .. math.floor(age/60) .. " phút)" end
    if data.placeId and tonumber(data.placeId) ~= game.PlaceId then return nil, "Khác PlaceId (Sea khác)" end
    if data.jobId == game.JobId then return nil, "Đang ở server này rồi" end
    if playerNum > 10 then return nil, "Server đông (" .. playerNum .. " người)" end
    if triedJobIds[data.jobId] then return nil, "JobId đã thử: " .. data.jobId:sub(1,8) .. "..." end

    return data.jobId, data.moon or "Moon", playerNum
end

-- 3 lần thử, mỗi lần fetch Firebase lấy JobID mới
local function TryFirebaseMoonHop()
    if not _firebaseReq then
        warn("[FirebaseMoon] Executor không hỗ trợ HTTP!")
        return false
    end

    local triedJobIds = {} -- Nhớ JobID đã thử để không lặp lại

    for attempt = 1, 3 do
        -- Check moon trước mỗi lần thử — nếu đã tốt thì không cần join nữa
        local currentMoon = CheckMoon()
        if (currentMoon == "8/8" or currentMoon == "Blue Moon")
            and (Lighting.ClockTime >= 12 or Lighting.ClockTime < 6) then
            print("[FirebaseMoon] Moon hiện tại ĐÃ TỐT (" .. currentMoon .. ") → Bỏ qua, chuyển sang Pray!")
            SetText("🌕 Moon đã tốt: " .. currentMoon .. " → Pray...")
            return true -- true = không cần HopServer, vòng lặp chính sẽ vào nhánh Pray
        end

        SetText(string.format("🌕 Firebase Moon | Lần %d/3 — Đang lấy JobID...", attempt))

        -- Delay 3 giây giữa các lần (trừ lần đầu)
        if attempt > 1 then
            for countdown = 3, 1, -1 do
                SetText(string.format("🌕 Firebase Moon | Lần %d/3 — Chờ %ds lấy JobID mới...", attempt, countdown))
                task.wait(1)
            end
        end

        local jobId, infoOrReason, playerNum = FetchFirebaseMoonJobId(triedJobIds)

        if jobId then
            triedJobIds[jobId] = true
            SetText(string.format("🌕 Firebase Moon | Lần %d/3\n%s | %d người | Joining...",
                attempt, infoOrReason, playerNum))
            print(string.format("[FirebaseMoon] Lần %d/3 → JobId: %s | %s | %d người",
                attempt, jobId:sub(1,12), infoOrReason, playerNum))

            task.wait(1)
            local result = TPServer(jobId)
            print(string.format("[FirebaseMoon] Lần %d/3 → TPServer: %s", attempt, tostring(result)))

            -- Đợi 3 giây xem teleport thành công chưa
            task.wait(3)
            -- Nếu vẫn ở đây → chưa join được → tiếp lần sau
        else
            print(string.format("[FirebaseMoon] Lần %d/3 → Bỏ qua: %s", attempt, tostring(infoOrReason)))
            SetText(string.format("🌕 Firebase Moon | Lần %d/3 — %s", attempt, tostring(infoOrReason)))
            task.wait(2)
        end
    end

    print("[FirebaseMoon] 3 lần đều fail → Fallback HopServer")
    return false
end
-- ==========================================

if LocalPlayer.Data.Level.Value < 2300 then LocalPlayer:Kick("Please Farm Level For Get Soul Guitar") end
local all, done = 0, false
local livingZombieTimer = 0

spawn(function()
    while task.wait(0.2) do
        xpcall(function() local c = 0
            if done or CheckInventory("Skull Guitar") then SetText("DONE SOUL GUITAR") done = true
            elseif not CheckInventory("Dark Fragment") or CheckMaterial("Dark Fragment") < 1 then
                if CheckSea(2) then
                    if CheckMonster("Darkbeard") then for _, v2 in next, {workspace.Enemies, ReplicatedStorage} do for _, v in next, v2:GetChildren() do if v.Name == "Darkbeard" then repeat task.wait() SetText("Killing Darkbeard\nHealth: ".. math.floor(v.Humanoid.Health / v.Humanoid.MaxHealth * 100).."%") KillMonster(v.Name) until not v or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0 Tween(false) end end end
                    elseif CheckTool("Fist of Darkness") then local Detection = workspace.Map.DarkbeardArena.Summoner.Detection
                        Tween(false) SetText("Spawn Darkbeard\nTweening") Tween(Detection.CFrame)
                        if (HumanoidRootPart.Position - Detection.Position).Magnitude <= 200 then
                            firetouchinterest(Detection, HumanoidRootPart, 0) task.wait(0.2)
                            firetouchinterest(Detection, HumanoidRootPart, 1)
                        end
                    else local chests = {}
                        if all < getgenv().Settings["Max Chests"] and not CheckTool("Fist of Darkness") then
                            for _, v in next, CollectionService:GetTagged("_ChestTagged") do if v and v.CanTouch then local dist = (v.Position - HumanoidRootPart.Position).Magnitude table.insert(chests, {obj = v, dist = dist}) end end
                            table.sort(chests, function(a, b) return a.dist < b.dist end)
                            if not CheckTool("Fist of Darkness") then
                                for i, t in next, chests do local v = t.obj
                                    if v:IsA("BasePart") and v.Name:find("Chest") then
                                        if v.CanTouch then SetText("Collect Chests")
                                            repeat task.wait()
                                                SetText("Collect Chests | Collected: " .. c.."/"..all .. "/"..getgenv().Settings["Max Chests"].." Chests")
                                                if Character.Humanoid and Character.Humanoid.Health > 0 then Character:SetPrimaryPartCFrame(v.CFrame) task.delay(2, function() v.CanTouch = false end) end
                                                pcall(function() if (Character.Humanoid.FloorMaterial ~= Enum.Material.Air or not table.find({Enum.HumanoidStateType.Jumping, Enum.HumanoidStateType.Dead}, Character.Humanoid:GetState())) then Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end end)
                                            until not v.CanTouch or CheckTool("Fist of Darkness") c += 1 all += 1
                                            if all >= getgenv().Settings["Max Chests"] or CheckTool("Fist of Darkness") then SetText("Stopped") break end
                                            if c >= getgenv().Settings["Reset After Collect Chests"] and not CheckTool("Fist of Darkness") then Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead) SetText("Collect Chests | Reset: Collected: "..getgenv().Settings["Reset After Collect Chest"] .." Chests") c = 0 task.wait(1) end
                                        end
                                        if i % 250 == 0 then task.wait(0.01) end
                                    end
                                end
                            else Tween(false) SetText("Stopped: Found Special Item")
                            end
                            if not CheckTool("Fist of Darkness") then HopServer() end
                        end
                    end
                else COMMF_:InvokeServer("TravelDressrosa") task.wait(5)
                end
            elseif CheckMaterial("Bones") < 500 then
                if CheckSea(3) then
                    if CheckLocation("Haunted Castle") then
                        for i, v in next, workspace.Enemies:GetChildren() do
                            if v:IsA("Model") and table.find({"Reborn Skeleton", "Demonic Soul", "Living Zombie", "Posessed Mummy"}, v.Name) then
                                if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then Tween(false)
                                    repeat task.wait() KillMonster(v.Name) SetText("Farming Bone")
                                    until not v or v.Humanoid.Health <= 0 Tween(false)
                                end
                            end if i % 2 == 0 then task.wait(0.1) end
                        end
                        if not CheckLocation("Cursed Ship") then COMMF_:InvokeServer("requestEntrance", Vector3.new(920, 125, 32850)) end
                    else SetText("Tween To Haunted Castle to Farm Bone")
                        Tween(workspace._WorldOrigin.Locations["Haunted Castle"].CFrame * CFrame.new(0, 325, 350))
                    end
                else COMMF_:InvokeServer("TravelZou") task.wait(5)
                end
            elseif CheckMaterial("Ectoplasm") < 250 then
                if CheckSea(2) then
                    if CheckLocation("Cursed Ship") then
                        for i, v in next, workspace.Enemies:GetChildren() do
                            if v:IsA("Model") and table.find({"Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer"}, v.Name) then
                                if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then Tween(false)
                                    repeat task.wait() KillMonster(v.Name) SetText("Farming Ectoplasm")
                                    until not v or v.Humanoid.Health <= 0 Tween(false)
                                end
                            end if i % 2 == 0 then task.wait(0.1) end
                        end
                    else SetText("Tween to Cursed Ship to Farm Ectoplasm")
                        COMMF_:InvokeServer("requestEntrance", Vector3.new(920, 125, 32850))
                        Tween(false) Tween(workspace._WorldOrigin.Locations["Cursed Ship"].CFrame)
                    end
                else COMMF_:InvokeServer("TravelDressrosa") task.wait(5)
                end
            elseif LocalPlayer.Data.Fragments.Value < 5000 then
                if CheckSea(3) then
                    if CheckMonster("rip_indra") or CheckMonster("Dough King") or CheckMonster("Cake Prince") then
                        for _, v2 in next, ({workspace.Enemies, ReplicatedStorage}) do
                            for _, v in next, v2:GetChildren() do
                                if v.Name:find("indra") or v.Name == "Dough King" or v.Name == "Cake Prince" then
                                    if v:FindFirstChildWhichIsA("Humanoid") and v.Humanoid.Health > 0 and v.HumanoidRootPart then
                                        repeat task.wait() KillMonster(v.Name)
                                        SetText("Killing : ".. v.Name.. "\nHealth: ".. math.floor(v.Humanoid.Health / v.Humanoid.MaxHealth * 100).. "%\nDistance: ".. math.floor((v.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude).. " stubs")
                                        until not v or not v:FindFirstChildWhichIsA("Humanoid") or v.Humanoid.Health <= 0 or not v.HumanoidRootPart
                                    end
                                end
                            end
                        end
                    else
                        if LocalPlayer.Data.Level.Value >= 2200 and (LocalPlayer.PlayerGui.Main.Quest.Visible and (function(q)
                            for _, n in next, {"Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker"} do
                                if q:find(n) then return true end
                            end
                        end)(LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text)) or LocalPlayer.Data.Level.Value < 2200 then local currentProgress = tonumber(COMMF_:InvokeServer("CakePrinceSpawner"):match("%d+") or 500)
                            xpcall(function()
                                Tween(workspace.Map.CakeLoaf.RespawnPart.CFrame)
                            end, function()
                                Tween(CFrame.new(-2100, 70, -12130))
                            end)
                            for _, v in next, workspace.Enemies:GetChildren() do
                                if table.find({"Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker"}, v.Name) then
                                    if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                        repeat task.wait()
                                            SetText("Killing 500 monsters| Killing: ".. v.Name.. "\nCurrent progress: ".. currentProgress.. "/500")
                                            KillMonster(v.Name)
                                        until (LocalPlayer.Data.Level.Value >= 2200 and not LocalPlayer.PlayerGui.Main.Quest.Visible) or not v or not v:FindFirstChildWhichIsA("Humanoid") or v.Humanoid.Health <= 0
                                    end
                                end
                            end
                        else
                            pcall(function()
                                if (TableQuests["CakeQuest2"].Position - Character.HumanoidRootPart.Position).Magnitude > 30 then
                                    task.defer(function()
                                        SetText("Tweening To Katakuri Island | Get Quest: Cake Quest Giver")
                                        Tween(false)
                                        Tween(CFrame.new(TableQuests["CakeQuest2"].Position))
                                    end)
                                else
                                    SetText("Get Quest Cake Prince: " .. TableQuests["CakeQuest2"].RawNPCName) task.wait(0.5)
                                    COMMF_:InvokeServer("StartQuest", LocalPlayer.Data.Level.Value >= 2275 and "CakeQuest2" or tostring(GetQuest().NameQuest), LocalPlayer.Data.Level.Value >= 2275 and 2 or GetQuest().ID)
                                end
                            end)
                        end
                    end
                else COMMF_:InvokeServer("TravelZou") task.wait(5)
                end
            else
                if CheckSea(3) then local Soul = COMMF_:InvokeServer("GuitarPuzzleProgress", "Check")
                    if Soul and Soul.Pipes then
                        SetText("Buy Soul Guitar") COMMF_:InvokeServer("soulGuitarBuy")
                    else
                        SetText("Doing Soul Guitar")
                        if Soul == nil then
                            if (CheckMoon() == "8/8" or CheckMoon() == "Blue Moon") and (Lighting.ClockTime >= 12 or Lighting.ClockTime < 6) then
                                if Lighting.ClockTime >= 12 or Lighting.ClockTime < 6 then
                                    SetText("Soul Guitar Puzzle | Pray") local g = workspace.NPCs:FindFirstChild("Gravestone") or ReplicatedStorage.NPCs:FindFirstChild("Gravestone")
                                    if g and g:FindFirstChild("HumanoidRootPart") then if (g.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude < 10 then COMMF_:InvokeServer("gravestoneEvent", 2, true)
                                    else Tween(g.HumanoidRootPart.CFrame) end
                                    end
                                else SetText("Waiting for Full Moon")
                                end
                            else
                                -- ============================================================
                                -- [MỚI] Firebase Moon Join — 3 lần fetch JobID mới từ Firebase
                                -- Mỗi lần gọi lại Firebase để lấy JobID khác
                                -- 3 lần fail hết → fallback HopServer Full Moon
                                -- ============================================================
                                SetText("🌕 Firebase Moon | Đang tìm server Full Moon...")
                                local firebaseOk = TryFirebaseMoonHop()
                                if not firebaseOk then
                                    SetText("🌕 Firebase fail → Hop Server Full Moon...")
                                    HopServer()
                                end
                            end
                        else if CheckLocation("Haunted Castle") then require(ReplicatedStorage.DialogueController):Close()
                            if not Soul.Swamp then
                                -- ================================================================
                                -- [Living Zombie Section with 3 Minute Hop Server Logic]
                                -- ================================================================
                                if livingZombieTimer == 0 then livingZombieTimer = tick() end
                                
                                if tick() - livingZombieTimer >= 180 then
                                    SetText("Living Zombie Timeout! Hopping Server...")
                                    livingZombieTimer = 0
                                    HopServer()
                                    return
                                end

                                SetText("Soul Guitar Puzzle | Living Zombie")
                                local ZOMBIE_CENTER = CFrame.new(-10138.3974609375, 138.6524658203125, 5902.89208984375)
                                local _killingZombies = true
                                
                                task.spawn(function()
                                    while _killingZombies do
                                        pcall(function()
                                            for _, zv in next, workspace.Enemies:GetChildren() do
                                                if zv.Name == "Living Zombie" and zv:FindFirstChild("Humanoid") and zv.Humanoid.Health > 0 and zv:FindFirstChild("HumanoidRootPart") then
                                                    zv.HumanoidRootPart.CFrame = ZOMBIE_CENTER
                                                    if zv:FindFirstChild("Head") then zv.Head.CanCollide = false end
                                                    zv.Humanoid.Sit = false
                                                    zv.HumanoidRootPart.CanCollide = false
                                                    zv.Humanoid.JumpPower = 0
                                                    zv.Humanoid.WalkSpeed = 0
                                                    if zv.Humanoid:FindFirstChild("Animator") then zv.Humanoid.Animator:Destroy() end
                                                end
                                            end
                                        end)
                                        task.wait()
                                    end
                                end)
                                
                                Tween(CFrame.new(-10160, 170, 5930))
                                task.wait(1)
                                
                                repeat task.wait(0.1)
                                    local timeLeft = math.floor(180 - (tick() - livingZombieTimer))
                                    SetText("Soul Guitar Puzzle | Killing All Living Zombies\nTime before Hop: " .. timeLeft .. "s")
                                    if HumanoidRootPart then
                                        HumanoidRootPart.CFrame = ZOMBIE_CENTER * CFrame.new(0, 30, 0)
                                    end
                                    FastAttack()
                                    EquipWeapon("Melee")
                                    BringMonster("Living Zombie", 6)
                                    
                                    if tick() - livingZombieTimer >= 180 then break end
                                until workspace.Map["Haunted Castle"].Swamp.SwampWater.BrickColor ~= BrickColor.new("Maroon")
                                
                                _killingZombies = false
                                Tween(false)
                                
                                if workspace.Map["Haunted Castle"].Swamp.SwampWater.BrickColor ~= BrickColor.new("Maroon") then
                                    livingZombieTimer = 0
                                end
                                -- ================================================================
                            elseif not Soul.Gravestones then SetText("Soul Guitar Puzzle | Gravestones") for i, v in ipairs({2, 2, 1, 2, 1, 1, 1}) do fireclickdetector(CheckMap("Haunted Castle")["Placard" .. i][v == 1 and "Left" or "Right"].ClickDetector) end
                            elseif not Soul.Ghost then SetText("Soul Guitar Puzzle | Ghost") COMMF_:InvokeServer("GuitarPuzzleProgress", "Ghost")
                            elseif not Soul.Trophies then SetText("Soul Guitar Puzzle | Trophies")
                                pcall(function() local m, t = workspace.Map["Haunted Castle"].Tablet, workspace.Map["Haunted Castle"].Trophies.Quest
                                    for i, v in ipairs({1, 3, 4, 7, 10}) do local sm = m:FindFirstChild("Segment"..v) local tp = t:FindFirstChild("Trophy"..i)
                                        local targetZ = tp.Handle.Rotation.Y == 0 and -90 or tp.Handle.Rotation.Y == 90 and 180 or nil
                                        if targetZ then repeat task.wait() if sm.Line.Rotation.Z ~= targetZ then fireclickdetector(sm:FindFirstChild("ClickDetector"))
                                        end until sm.Line.Rotation.Z == targetZ
                                    end end for _, v in ipairs(m:GetChildren()) do local id = tonumber(v.Name:match("%d+"))
                                    if id and not table.find({1, 3, 4, 7, 10}, id) and v:FindFirstChild("Line") then if v.Line.Rotation.Z ~= 0 then
                                        repeat task.wait() fireclickdetector(v:FindFirstChild("ClickDetector"))
                                        until v.Line.Rotation.Z == 0
                                    end end end
                                end)
                            elseif not Soul.Pipes then SetText("Soul Guitar Puzzle | Pipes") for i = 1, 10 do
                                for _ = 1, (({1, 1, 2, 4, 1, 3, 1, 2, 1, 4})[i] - ({["Really black"] = 1; ["Dusty Rose"] = 2; ["Parsley green"] = 3; ["Storm blue"] = 4})[tostring(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model["Part"..i].BrickColor)] or 1) % 4 do
                                    fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model["Part"..i]:FindFirstChildWhichIsA("ClickDetector"))
                                end
                            end end
                        else Tween(workspace._WorldOrigin.Locations["Haunted Castle"].CFrame * CFrame.new(0, 325, 350))
                        end end
                    end
                else COMMF_:InvokeServer("TravelZou") task.wait(5)
                end
            end
        end, function(err) warn("Main Error ".. err) StarterGui:SetCore("SendNotification", {Title = "Script ERROR", Text = err, Duration = 5}) end)
    end
end)

task.spawn(function()
    while task.wait(4) do
        xpcall(function()
            if not Character:FindFirstChild("HasBuso") then COMMF_:InvokeServer("Buso") end
            for _, v in next, {"Buso", "Geppo", "Soru"} do
                if not CollectionService:HasTag(Character, v) then
                    if LocalPlayer.Data.Beli.Value >= ((function(t)
                        return t == "Geppo" and 1e4 or t == "Buso" and 2.5e4 or t == "Soru" and 1e5 or 0
                    end)(v)) then SetText("Buy Abilies: ".. v) COMMF_:InvokeServer("BuyHaki", v)
                    end
                end
            end
        end, function(err) warn("LL: ".. err) end)
    end
end)

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, message)
    if teleportResult == Enum.TeleportResult.GameFull then inHopPP = false
    elseif teleportResult == Enum.TeleportResult.IsTeleporting and (message:find("previous teleport")) then
        StarterGui:SetCore("SendNotification", {Title = "Death Hop Found", Text = message, Duration = 8})
        task.delay(10, function() game:Shutdown() end)
    end
end)

GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) task.wait(5) end
    end
end))

local plr = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function TweenObject(Object, Pos, Speed)
    Speed = Speed or 300
    if not Object or not Pos then return end
    local Distance = (Pos.Position - Object.Position).Magnitude
    local info = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    TweenService:Create(Object, info, {CFrame = Pos}):Play()
end

local function GetMobPosition(name)
    local pos = Vector3.zero
    local count = 0
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == name and v:FindFirstChild("HumanoidRootPart") then
            pos += v.HumanoidRootPart.Position
            count += 1
        end
    end
    if count == 0 then return nil end
    return pos / count
end

local function BringMob()
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrpChar = char.HumanoidRootPart
    local enemies = workspace.Enemies:GetChildren()
    if #enemies == 0 then return end
    local totalpos = {}
    for _, v in pairs(enemies) do
        if not totalpos[v.Name] then
            totalpos[v.Name] = GetMobPosition(v.Name)
        end
    end
    for _, v in pairs(enemies) do
        local hum = v:FindFirstChild("Humanoid")
        local hrp = v:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            local distChar = (hrp.Position - hrpChar.Position).Magnitude
            if distChar <= 1500 then
                local mobPos = totalpos[v.Name]
                if mobPos then
                    local target = CFrame.new(mobPos)
                    local dist = (hrp.Position - target.Position).Magnitude
                    if dist > 3 and dist <= 1500 then
                        TweenObject(hrp, target)
                        hrp.CanCollide = false
                        if hum:FindFirstChild("Animator") then
                            hum.Animator:Destroy()
                        end
                        pcall(function()
                            sethiddenproperty(plr, "SimulationRadius", math.huge)
                        end)
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(BringMob)
