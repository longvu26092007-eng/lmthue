getgenv().modechange = {
    ['CDK'] = true,
    ['Pull Lever'] = true,
    ['MM'] = true,
    ['Key'] = 'VuNguyenCanTeam',
    ['Boost FPS'] = true,
    ['Black Screen'] = true,
    ['FPS'] = 60
}
PirateRaidSenque = -1

function CheckKick(v)
    if v.Name == 'ErrorPrompt' then
        task.wait(2)
        warn(v.TitleFrame.ErrorTitle.Text)
        if v.TitleFrame.ErrorTitle.Text == 'Teleport Failed' then
            if string.find(v.MessageArea.ErrorFrame.ErrorMessage, 'Unable to join game') then  -- FIX 1: String.find → string.find
                while true do end 
            end
        end
    else 
        game:GetService('TeleportService'):Teleport(game.PlaceId)
        v:Destroy()
    end
end

game:GetService('CoreGui').RobloxPromptGui.promptOverlay.ChildAdded:Connect(CheckKick)

Hop = function(Reason, PlayerLimit) 
    local servers = {}
    local req = game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true')
    local body = game:GetService('HttpService'):JSONDecode(req)

    if body and body.data then
        for i, v in next, body.data do
            if type(v) == 'table' and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
                table.insert(servers, 1, v.id)
            end
        end
    end

    if #servers > 0 then
        game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], game.Players.LocalPlayer)
    else
        return alert('Serverhop', 'Couldnt find a server.')
    end    
end 

placeId = game.PlaceId
if placeId == 2753915549 then
    Sea = 'Main'
    SeaIndex = 1
elseif placeId == 4442272183 then
    Sea = 'Dressrosa'
    SeaIndex = 2
elseif placeId == 7449423635 then
    Sea = 'Zou'
    SeaIndex = 3
end


FastAttack = loadstring([[
local Modules = game.ReplicatedStorage.Modules
local Net = Modules.Net
local Register_Hit, Register_Attack = Net:WaitForChild('RE/RegisterHit'), Net:WaitForChild('RE/RegisterAttack')
local Funcs = {}
function GetAllBladeHits()
    bladehits = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 
        and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
            table.insert(bladehits, v)
        end
    end
    return bladehits
end
function Getplayerhit()
    bladehits = {}
    for _, v in pairs(workspace.Characters:GetChildren()) do
        if v.Name ~= game.Players.LocalPlayer.Name and v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 
        and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
            table.insert(bladehits, v)
        end
    end
    return bladehits
end

local Net = (game.ReplicatedStorage.Modules.Net)  -- FIX 2: Services → game (Services chưa tồn tại trong loadstring scope)

local RegisterAttack = require(Net):RemoteEvent('RegisterAttack', true)
local RegisterHit = require(Net):RemoteEvent('RegisterHit', true)

function Funcs:Attack()
    
    
    local bladehits = {}
    for r,v in pairs(GetAllBladeHits()) do
        table.insert(bladehits, v)
   
    end
    for r,v in pairs(Getplayerhit()) do
        table.insert(bladehits, v)
    end
    
    if #bladehits == 0 then
        
        return
    end
    
    local args = {
        [1] = nil;
        [2] = {},
        [4] = '078da341'
    }
    for r, v in pairs(bladehits) do
        
        
        RegisterAttack:FireServer(0)
        if not args[1] then
            args[1] = v.Head
        end
        table.insert(args[2], {
            [1] = v,
            [2] = v.HumanoidRootPart
        })
        table.insert(args[2], v)
    end
    
    
    RegisterHit:FireServer(unpack(args))
end

task.spawn(function() 
    while task.wait(.05) do 
        if _G.FastAttack == os.time() then 
            pcall(function() 
                Funcs:Attack() 
            end)
        end 
    end
end)

getgenv().Attack = function(MonResult) 
    pcall(function() 
        _G.FastAttack = os.time()
    end)
end 
]])
if not LPH_OBFUSCATED then 
    LPH_ENCSTR = LPH_ENCSTR or function(...) return ... end 
    LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(...) return ... end 
end 

if not modechange then return end 
if modechange.Key ~= LPH_ENCSTR('VuNguyenCanTeam') then return end  -- FIX 3: Key khớp với config

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer:FindFirstChild('DataLoaded')

game.ReplicatedStorage.Remotes.CommF_:InvokeServer('SetTeam', 'Marines')
repeat wait() until game.Players.LocalPlayer.Character
spawn(function()
    pcall(function()  -- FIX 4: Wrap trong pcall phòng trường hợp script không tồn tại
        game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild('NewIslandLOD', 9999):Destroy() 
    end)
    pcall(function()
        game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild('IslandLOD', 9999):Destroy()  -- FIX 5: Thêm dấu . trước LocalPlayer
    end)
end)

Players = game.Players
LocalPlayer = Players.LocalPlayer
Character = LocalPlayer.Character

Humanoid = Character:WaitForChild('Humanoid')
HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')

PlayerGui = LocalPlayer:WaitForChild('PlayerGui', 10)
Lighting = game:GetService('Lighting')


ConChoChisiti36 = {
    PlayerData = {}, 
    Enemies = {}, 
    Tools = {}, 
    NPCs = {},
    Backpack = {},  -- FIX 6: Tools bị khai báo 2 lần, thêm Backpack
} 

Services = {}

setmetatable(Services, {
    __index = function(_, Index)
        return game:GetService(Index)
    end
});

setmetatable(ConChoChisiti36.Enemies, {
    __index = function(_, Index)
        return Services.Workspace.Enemies:FindFirstChild(Index) or Services.ReplicatedStorage:FindFirstChild(Index)
    end
})

setmetatable(ConChoChisiti36.Tools, {
    __index = function(Self, Index)
        return LocalPlayer.Character:FindFirstChild(Index) or LocalPlayer.Backpack:FindFirstChild(Index)
    end
})

setmetatable(ConChoChisiti36.NPCs, {
    __index = function(_, Index)
        return workspace.NPCs:FindFirstChild(Index) or game.ReplicatedStorage.NPCs:FindFirstChild(Index)
    end
})


Remotes = {}
setmetatable(Remotes, {
    __index = function(Self, Key)
        if Key ~= 'CommF_' then
            warn('captured unregistered signal', Key)  -- FIX 7: key → Key (viết hoa đúng tham số)
            return Services.ReplicatedStorage.Remotes[Key]
        end
        local tbl = {
            InvokeServer = function(Self, ...)
                warn('remote fired', ...)
                return Services.ReplicatedStorage.Remotes.CommF_:InvokeServer(...)
            end
        }
        return tbl
    end
})

Storage = {
    WRITE_DELAY = 5, 
    Data = {}, 
} 

LocalPlayer = game.Players.LocalPlayer

local StoragePath = '.storage_u_' .. tostring(LocalPlayer) 

function Decode(Content) 
    return Services.HttpService:JSONDecode(Content) 
end 

function Encode(Content) 
    return Services.HttpService:JSONEncode(Content)  
end 

function Storage.Set(Self, Key, Value) 
    Self.Data[Key] = Value
    Self:Save()
end 

function Storage.Get(Self, Key) 
    return Self.Data[Key] 
end 

function Storage.Save(Self) 
    writefile(StoragePath, Encode(Self.Data)) 
end 

if not isfile(StoragePath) then 
    writefile(StoragePath, '{}')
    task.wait(1)
end 

Storage.Data = Decode(readfile(StoragePath) or '{}')  

spawn(function() 
    while task.wait(Storage.WRITE_DELAY) do 
        Storage:Save() 
    end 
end)

function RefreshPlayerData()
    for _, ChildInstance in LocalPlayer.Data:GetChildren() do
        pcall(function()
            ConChoChisiti36.PlayerData[ChildInstance.Name] = ChildInstance.Value
        end)
    end
end
RefreshPlayerData() 

function RefreshInventory()
    ConChoChisiti36.Backpack2 = {}
    for _, Value in Remotes.CommF_:InvokeServer('getInventory') do
        ConChoChisiti36.Backpack2[Value.Name] = Value
    end
    
    ConChoChisiti36.Backpack = ConChoChisiti36.Backpack2
end

RefreshInventory()
Remotes.CommE.OnClientEvent:Connect(function(...)
    local data = {...}
    if string.find(data[1], 'Item') then
        RefreshInventory()
    end
end)

FastAttack()

function AsynclyPullServerDatas(Category) 
    local Url = LPH_ENCSTR('https://api-bf.yummydata.click/data-private?type=') .. Category  
    local Success, Result = pcall(function() 
        local Raw = request{
            Url = Url, 
            Method = 'GET'
        }
        
        assert(Raw.Success == true) 
        return Services.HttpService:JSONDecode(Raw.Body)
    end) 
    
    if not Success then 
        print('Failed to serialize datas', Result)
        return {} 
    end 
    
    return Result.data 
end 

function WrapToServer (Category, Filter) 
    if LastestWrapRequest and os.time() - LastestWrapRequest < 10 then return end 
    LastestWrapRequest = os.time() 
    print('Search for rare boss: ', Category)
    local ServerLists = AsynclyPullServerDatas(Category) 
    if #ServerLists == 0 then 
        return false 
    end 
    
    for Attempts = 1, #ServerLists, 1 do 
        local Server = ServerLists[math.random(1, #ServerLists)] 
        print ('HIT', Attempts, '/', 10)
        if not Storage:Get(Server.JobId) and Server.Players ~= '12/12' then 
            print('Player passed')
            if not Filter or Filter(Server) then 
                print('Attempt to join', Server.JobId, 'Players:', Server.Players)
                Storage:Set(Server.JobId, true)
                game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, Server.JobId, game.Players.LocalPlayer)  -- FIX 8: game.placeId → game.PlaceId
                task.wait(5) 
            end 
        end 
    end
    Hop()
end 

Hooks = {
    Listeners = {}
}

NotificationCallBack = (function(Content)
    for ListenerContent, Callback in Hooks.Listeners do
        if string.find(string.lower(Content), string.lower(ListenerContent)) then 
            Callback(Content)
        end 
    end 
end) 

function Hooks:RegisterNotifyListener(Senque, Callback)
    Hooks.Listeners[Senque] = Callback
end 

Hooks:RegisterNotifyListener('been spotted approaching', function() 
    PirateRaidSenque = os.time()
end) 

Hooks:RegisterNotifyListener('job', function() 
    PirateRaidSenque = 0
end) 

Hooks:RegisterNotifyListener('torch', function() 
    TorchEnabledTime = os.time()
end) 

Hooks:RegisterNotifyListener('scroll reacts', function() 
    DoneCDKTick = os.time()
end) 
TorchEnabledTime = 0
DoneCDKTick = 0
Hooks:RegisterNotifyListener('elite', function() 
    EliteCount = Remotes.CommF_:InvokeServer('EliteHunter', 'Progress')
end) 

local old
old = hookfunction(
    require(game.ReplicatedStorage.Notification).new,
    function(a, b)
        
        v21 = tostring(tostring(a or '') .. tostring(b or '')) or ''
        
        NotificationCallBack(v21)
        
        return old(a, b)
    end
) 

-- Tween 
function ConvertTo (Type, Data) 
    return Type.new(Data.x, Data.y, Data.z)
end 

function CaculateDistance (Origin, Destination) 
    if not Destination then 
        Destination = LocalPlayer.Character:GetPrimaryPartCFrame() 
    end 
    
    local Origin, Destination = ConvertTo(Vector3, Origin), ConvertTo(Vector3, Destination) 
    
    return (Origin - Destination).Magnitude 
end 

function TweenTo (Position)
    
    if not Position then return end 
    local Position = typeof(Position) ~= 'CFrame' and ConvertTo(CFrame, Position) or Position
    
    if TweenInstance then 
        pcall(function() 
            TweenInstance:Cancel() 
        end)
    end
    
    for _, Part in LocalPlayer.Character:GetDescendants() do
        if Part:IsA('BasePart') then
            Part.CanCollide = false
        end
    end
    
    local Head = game.Players.LocalPlayer.Character:WaitForChild('Head')
    if not Head:FindFirstChild('cho nam gg') then
        local BodyVelocity = Instance.new('BodyVelocity')
        BodyVelocity.Name = 'cho nam gg'
        BodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.Parent = Head
    end
   
    Position = CFrame.new(Position.Position)
    
    local Dist = CaculateDistance(LocalPlayer.Character.HumanoidRootPart.CFrame, Position)
    TweenInstance = Services.TweenService:Create(
            LocalPlayer.Character.HumanoidRootPart,
            TweenInfo.new(Dist / (Dist < 18 and 25 or 330) , Enum.EasingStyle.Linear),
            {CFrame = Position}
        ) 
    TweenInstance:Play()
end

-- Combat 

function LockMob (Mob) 
    
    if Mob:GetAttribute('_Locked') then 
        return 
    end 
    Mob:SetAttribute('_Locked', 1) 
    
    Mob.HumanoidRootPart.CanCollide = false 
    if not Mob.HumanoidRootPart:FindFirstChild('seen cai cc bo m tu ai r') then 
        local BodyVelocity = Instance.new('BodyVelocity', Mob.HumanoidRootPart) 
        BodyVelocity.Name = 'seen cai cc bo m tu ai r' 
        BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        BodyVelocity.Velocity = Vector3.zero
    end
    table.foreach(Mob:GetDescendants(), function(_, Ins)
        if Ins:IsA('BasePart') or Ins:IsA('Part') then
            Ins.CanCollide = false
        end 
    end)
end 

function GrabMobs (MobName) 
    GrabDebounce = os.time() 
    pcall(sethiddenproperty, game.Players.LocalPlayer, 'SimulationRadius', math.huge) 
    GrabPosition = nil
    local MobVectors, EntriesCount, Entries = Vector3.zero, 0, {} 
    
    for _, Mob in workspace.Enemies:GetChildren() do
        if tostring(Mob) == MobName then 
            local MobHumanoid = Mob:FindFirstChild('Humanoid') 
            
            if MobHumanoid and MobHumanoid.Health > 0 then 
                local MobPrimaryPart = Mob:FindFirstChild('HumanoidRootPart')
                
                if MobPrimaryPart and isnetworkowner(MobPrimaryPart) then 
                    
                    if not GrabPosition or CaculateDistance(GrabPosition, MobPrimaryPart.Position) < 250 then 
                        
                        EntriesCount = EntriesCount + 1 
                        MobVectors = MobVectors + MobPrimaryPart.Position 
                        GrabPosition = GrabPosition or MobPrimaryPart.Position 
                        Mob:SetAttribute('_OriginalPosition', Mob:GetAttribute('_OriginalPosition') or MobPrimaryPart.Position) 
                        table.insert(Entries, Mob)
                    end 
                end 
            end 
        end
    end 
    
    if EntriesCount == 0 then return end  -- FIX 9: Tránh chia cho 0
    
    local MidPoint = MobVectors / EntriesCount 
    if CaculateDistance(MidPoint, GrabPosition) > 400 then 
        return print('wtf wtf')
    end 
    table.foreach(Entries, function(_, Entry) 
        Entry.HumanoidRootPart.CFrame = CFrame.new(MidPoint) 
        pcall(LockMob, Entry)
    end)
end 


function GetMobAsSortedRange () 
    local Result = {}
    
    table.foreach(Services.Workspace.Enemies:GetChildren(), function(_, Mob) 
        if Mob and Mob:FindFirstChild('Humanoid') and Mob:FindFirstChild('HumanoidRootPart') and Mob.Humanoid.Health > 0 then 
            table.insert(Result, Mob)
        end 
    end)
    
    table.foreach(game.ReplicatedStorage:GetChildren(), function(_, Mob) 
        if Mob and Mob:FindFirstChild('Humanoid') and Mob:FindFirstChild('HumanoidRootPart') and Mob.Humanoid.Health > 0 then 
            table.insert(Result, Mob)
        end
    end)
    
    table.sort(Result, function(C1, C2) return CaculateDistance(C1.HumanoidRootPart.CFrame) < CaculateDistance(C2.HumanoidRootPart.CFrame) end) 
    
    return Result
end

ConChoChisiti36.MobRegions = {} 
for _, Region in game:GetService("ReplicatedStorage").FortBuilderReplicatedSpawnPositionsFolder:GetChildren() do 
    ConChoChisiti36.MobRegions[tostring(Region)] = ConChoChisiti36.MobRegions[tostring(Region)] or {} 
    table.insert(ConChoChisiti36.MobRegions[tostring(Region)], Region.CFrame)
end 

MobIndexUwU = 1  -- FIX 10: Khởi tạo MobIndexUwU tránh nil

function PlayerAdded() 
    task.spawn(function()
        task.wait(6)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HasBuso") then  -- FIX 11: Check Character tồn tại
            return
        end
        Remotes.CommF_:InvokeServer("Buso")
    end)
end 

game.Players.PlayerAdded:Connect(PlayerAdded) 
PlayerAdded()

function Sort1(N) 
    return N and N:FindFirstChild("HumanoidRootPart") and math.floor(CaculateDistance(N.HumanoidRootPart.CFrame))
end 


function SearchMobs (MobTable) 
    local Lists = {}
    local Found = false
    
    for _, ChildInstance in GetMobAsSortedRange() do
        if table.find(MobTable, ChildInstance.Name) and ChildInstance:FindFirstChild('Humanoid') and ChildInstance.Humanoid.Health > 0 then 
            if (ChildInstance:GetAttribute('FailureCount') or 0) < 3 then 
                Found = true
                table.insert(Lists, ChildInstance) 
            end 
        end
    end
    
    table.sort(Lists, function(a, b) 
        return (Sort1(a) or 9999) < (Sort1(b) or 9999)  -- FIX 12: Sort1 có thể trả về nil
    end)
    
    if Found then 
        local Mob1 = Lists[1] 
        return Mob1
    end
    
    for _, ChildName in MobTable do 
        local Mobs2 = game.ReplicatedStorage:FindFirstChild(ChildName) 
        if Mobs2 then 
            return Mobs2
        end 
    end 
end 


function RoundVector3Down(vec)
    return Vector3.new(
        math.floor(vec.X / 10) * 10,
        math.floor(vec.Y / 10) * 10,
        math.floor(vec.Z / 10) * 10
    )
end

local Angle = 30
lastChange = tick() 
CaculateCircreDirection = LPH_NO_VIRTUALIZE(function(Position)
    if Angle > 50000 then 
        Angle = 60
    end 
    
    Angle = Angle + ((tick() - lastChange) > .4 and 80 or 0) 

    
    if tick() - lastChange > .4 then 
        lastChange = tick()
    end
    
    local sum = Position + Vector3.new(math.cos(math.rad(Angle)) * 40, 0, math.sin(math.rad(Angle)) * 40)
    return CFrame.new(RoundVector3Down(sum.p))
end)

function EquipTool(Tool) 
    for _, Item in LocalPlayer.Backpack:GetChildren() do 
        if 
        Item:IsA('Tool') and Item.Name ~= 'Tool'
        and (
            Item.Name == tostring(Tool)
            or Item.ToolTip == Tool
            )
        then 
            LocalPlayer.Character:WaitForChild'Humanoid':EquipTool(Item)
        end 
    end 
end

LastFound = os.time()

function AttackMob (MobTable) 
    MobTable = type(MobTable) == 'string' and {MobTable} or MobTable 
    
    for _, Child in (MobTable) do
        local ChildName = tostring(Child)
        if (ChildName == "Deandre" or ChildName == "Urban" or ChildName == "Diablo") and (os.time() - (LastFire12 or 0)) > 180 then  -- FIX 13: Thêm ngoặc cho OR
            LastFire12 = os.time()
            Remotes.CommF_:InvokeServer("EliteHunter")
        end 
            
        local Mobs = SearchMobs(MobTable)
        
        
        if Mobs then
            
            LastFound = os.time()
            local Count, Debounce = 0, os.time()
            local Count2 = 0  -- FIX 14: Debounce bị khai báo 2 lần
            while task.wait() do
                if _G.Stop then return end
                
                
                if ConChoChisiti36.Tools['Sweet Chalice'] and getsenv(game.ReplicatedStorage.GuideModule)['_G']['InCombat'] then 
                    TweenTo(Vector3.new(0,0,0)) 
                    return wait(5)
                end 
                
                
                local MobHumanoid = Mobs:FindFirstChild('Humanoid')
                local MobHumanoidRootPart = Mobs:FindFirstChild('HumanoidRootPart')
                
                if not MobHumanoid or MobHumanoid.Health <= 0 then 
                    break
                end 
                
                TweenTo(CaculateCircreDirection(MobHumanoidRootPart.CFrame) + Vector3.new(0,35,0))
                
                    
                
                if CaculateDistance(MobHumanoidRootPart.Position + Vector3.new(0,35,0)) < 150 then
                    _ = Callback and Callback()
                    GrabMobs(Mobs.Name or '')
                    if Mobs.Name ~= 'Core' then 
                        if ConChoChisiti36.PlayerData.Level > 100 and Count2 >= 120 and MobHumanoid.Health - MobHumanoid.MaxHealth == 0 then 
                            _G.Stop = true
                            LocalPlayer:Kick('Mob Health Stuck')
                        end
                        
                        if ( Mobs:GetAttribute('FailureCount') or 0 ) > 5 then 
                            LocalPlayer:Kick('Failed to attack')
                        end
                        
                        if Count >= 360 and MobHumanoid.Health - MobHumanoid.MaxHealth == 0 then 
                            Count = 0 
                            
                            local OldPosition = Mobs:GetAttribute('OldPosition') 
                            
                            if OldPosition then
                                Mobs:SetPrimaryPartCFrame(CFrame.new(OldPosition))
                                Mobs:SetAttribute('IgnoreGrab', true)
                                Mobs:SetAttribute('FailureCount', (Mobs:GetAttribute('FailureCount') or 0) + 1)
                                while CaculateDistance(Mobs.HumanoidRootPart.CFrame,OldPosition) > 6 and task.wait() do 
                                    Mobs.HumanoidRootPart.CFrame = (CFrame.new(OldPosition)) 
                                end 
                                
                                task.wait()
                                
                                return 
                            end 
                        end
                    end
                    
                    EquipTool('Sword')  -- FIX 15: 'Sword' or 'Melee' luôn = 'Sword', bỏ or vô nghĩa
                    
                    Attack()
                    if os.time() ~= Debounce then 
                        Debounce = os.time()
                        Count = Count + 1
                        Count2 = Count2 + 1
                    end 
                    
                    if Count > 30 and Mobs.Name ~= 'Core' then
                        break
                    end
                else 
                    return
                end  
            end
        else
            if (os.time() - LastFound) > 200 then 
                Hop("Attack time is bigger than 180, hop")
                return
            end 
            
            local Region = ConChoChisiti36.MobRegions[Child] 
            
            if not Region then 
                local Inst = Services.Workspace.Enemies:FindFirstChild(Child) or game.ReplicatedStorage:FindFirstChild(Child) 
                
                Region = Inst and {Inst:GetPrimaryPartCFrame().p} 
            end 
            
            if not Region then 
                Hop("[ Game data error ] Mob with name ".. tostring(Child) .. " have no spawn region datas")
                return 
            end
            
            local CurrentPosition
            
            if not Region[MobIndexUwU] then 
                MobIndexUwU = 1
                
            end 
            
            CurrentPosition = Region[MobIndexUwU] 
            
            local Count2 = os.time()
                
            TweenTo(CurrentPosition+Vector3.new(0,35,35))
            task.wait()
            if CaculateDistance(CurrentPosition + Vector3.new(0,35,35)) < 15 then
                    MobIndexUwU = MobIndexUwU + 1
            end
            task.wait()
        end
    end 
end 
-- yama
EliteCount = Remotes.CommF_:InvokeServer('EliteHunter', 'Progress')

function GetCurrentEliteBoss () 
    for _, EliteName in {'Diablo', 'Urban', 'Deandre'} do local Boss = ConChoChisiti36.Enemies[EliteName] 
        if Boss then 
            return Boss 
        end 
    end 
end 

function GetIsland (Island) 
    local InitalizedIsland = workspace.Map:FindFirstChild(Island) 
    if InitalizedIsland then 
        return InitalizedIsland, true 
    end 
    return workspace:FindFirstChild(Island), false
end 

function CheckAndGetYama () 
    if ConChoChisiti36.Backpack.Yama then return end 
    if EliteCount < 30 then 
        local Boss = GetCurrentEliteBoss() 
        if Boss then 
            AttackMob(tostring(Boss)) 
            return true
        end 
        WrapToServer('Elite')
    end 
    
    local WaterfallIsland, IslandInitalzied = GetIsland('Waterfall') 
    
    if not WaterfallIsland then 
        LocalPlayer:Kick('Dung ma em oi :<') 
        return true
    end 
    
    while task.wait() and not WaterfallIsland:FindFirstChild('SealedKatana') do 
        TweenTo(WaterfallIsland:GetModelCFrame()) 
    end 
    
    fireclickdetector(workspace.Map.Waterfall.SealedKatana.Hitbox.ClickDetector)
end 

function CheckAndGetTushita () 
    
    if ConChoChisiti36.Backpack.Tushita then return end 
    
    TushitaProgress = TushitaProgress or Remotes.CommF_:InvokeServer('TushitaProgress')
    
    if ConChoChisiti36.Tools['Holy Torch'] then
        local TurtleMap = workspace.Map.Turtle.QuestTorches
        EquipTool('Holy Torch')
        for TorchIndex = 1, 5, 1 do
            if TurtleMap:FindFirstChild('Torch' .. TorchIndex) then
                repeat
                    task.wait()
                    TweenTo(TurtleMap:FindFirstChild('Torch' .. TorchIndex).CFrame)
                until TurtleMap:FindFirstChild('Torch' .. TorchIndex).Particles.Main.Enabled
            end
        end
        return true
    end 
    
    if not TushitaProgress.OpenedDoor then 
        if ConChoChisiti36.Enemies['rip_indra True Form'] then 
            TweenTo(CFrame.new(5714, math.random(19,21), 256))
        else 
            WrapToServer('Rare Boss', function(Child)
                print('Server hit', Child['Rare Boss']) 
                return Child['Rare Boss'] == 'rip_indra True Form'
            end)
        end 
        TushitaProgress = nil 
    else 
        local Longma = ConChoChisiti36.Enemies['Longma'] 
        if Longma then 
            AttackMob(tostring(Longma)) 
            return true
        else 
            Hop()
        end 
    end
end 

function GetCursedDualKatanaProgress () 
    if ConChoChisiti36.PlayerData.Level < 2200 then return end 
    local Backpack = ConChoChisiti36.Backpack
    
    if false  
        or Backpack['Cursed Dual Katana']
        
        or not Backpack.Yama 
        or Backpack.Yama.Mastery < 350 
        
        or not Backpack.Tushita 
        or Backpack.Tushita.Mastery < 350 
        
        or SeaIndex ~= 3 
    then 
        return 
    end 
    
    local CDKProgess = CDKProgess or Remotes.CommF_:InvokeServer('CDKQuest', 'Progress') or 'uwu'
    
    if not CDKProgess or CDKProgess == 'uwu' then return end 
    if not workspace.Map:FindFirstChild('Turtle') or not workspace.Map.Turtle:FindFirstChild'Cursed' then 
        TweenTo(workspace.Turtle:GetModelCFrame())
        return true
    end 
    
    if workspace.Map.Turtle.Cursed:FindFirstChild('Breakable') then
        return { 'break' }
    end
    
    local ScrollSides = {
        Good = 'Tushita', 
        Evil = 'Yama'
    }
    
    if CDKProgess.Good == 4 and CDKProgess.Evil == 4 then
        return { 'burn 2' } 
    end 
    
    if CDKProgess.Good == 3 or CDKProgess.Evil == 3 then 
        return { 'burn' } 
    end 
    
    if CDKProgess.Opened then 
        for Index, Value in CDKProgess do
            if Index ~= 'Opened' and Index ~= 'Finished' and Value < 3 then 
                
                ConChoChisiti36.CDKCache = {
                    Index, 
                    Value + 1
                }
                
                if not ConChoChisiti36.Tools[ScrollSides[Index]] then 
                    Remotes.CommF_:InvokeServer('LoadItem', ScrollSides[Index])
                end 
                
                Remotes.CommF_:InvokeServer('CDKQuest', 'StartTrial', Index)
                return false 
            end 
        end
    end 
    
    local CachedValue = ConChoChisiti36.CDKCache 
    
    if not CachedValue then return end 
    
    local Name, Level = CachedValue[1], CachedValue[2] 
    
    if Name == 'Evil' and Level == 3 then 
        if not ConChoChisiti36.Enemies['Soul Reaper'] then 
            WrapToServer('Rare Boss', function(Child) return Child['Rare Boss'] == 'Soul Reaper' end)
            return
        end 
    elseif Name == 'Good' then 
        if Level == 3 and not ConChoChisiti36.Enemies['Cake Queen'] then 
            Hop('Cake Queen Find')
            return 
        end 
    end
    return CachedValue
end 

function GetHazedMobs () 
    local Positions = {} 
    for _, Inst in LocalPlayer.QuestHaze:GetChildren() do 
        if Inst.Value > 0 then 
            table.insert(Positions, Inst) 
        end 
    end 
    table.sort(Positions, function(C1, C2) return CaculateDistance(C1:GetAttribute('Position')) < CaculateDistance(C2:GetAttribute('Position')) end) 
    return tostring(Positions[1])
end 

function CompleteDimension (DimensionName)  
    local DimensionId = string.gsub(DimensionName, ' ', '') 
    
    local VaiCaNgu1234 = os.time()
    repeat task.wait()
        TweenTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
        if os.time() - VaiCaNgu1234 > 60 then 
            return 
        end 
    until os.time() - TorchEnabledTime < 10 
    
    local PortalBrick = nil  -- FIX 16: Khởi tạo PortalBrick local tránh nil global
    repeat task.wait() 
        local OriginalIsland = workspace.Map:WaitForChild(DimensionId, 10)
        if OriginalIsland then 
            for _, Torch in OriginalIsland:GetChildren() do 
                if Torch and string.find(Torch.Name, 'Torch') and Torch:FindFirstChild('ProximityPrompt') and Torch.ProximityPrompt.Enabled then 
                    LocalPlayer.Character.HumanoidRootPart.CFrame = Torch.CFrame 
                    
                    Torch.ProximityPrompt.HoldDuration = 0
                    task.wait(1)
                    local vim = game:GetService('VirtualInputManager')
                    vim:SendKeyEvent(true, 'E', 0, game)
                    vim:SendKeyEvent(false, 'E', 0, game)
                    fireproximityprompt(workspace.Map:WaitForChild(DimensionId, 10):FindFirstChild(tostring(Torch)).ProximityPrompt) 
                
                end 
                for _, Mon in workspace.Enemies:GetChildren() do 
                    local MonHumanoidRootPart = Mon:FindFirstChild('HumanoidRootPart') 
                    local MonHumanoid = Mon:FindFirstChild('Humanoid') 
                    
                    if MonHumanoidRootPart and MonHumanoid and CaculateDistance(MonHumanoidRootPart.CFrame) < 1000 then 
                        AttackMob(Mon.Name)
                    end 
                end
            end 
            ExitDoor = OriginalIsland:FindFirstChild('Exit') 
            if ExitDoor then 
                PortalBrick = tostring(ExitDoor.BrickColor)
            end 
        end
    until PortalBrick == 'Olivine' or PortalBrick == 'Cloudy grey' 
    
    while os.time() - DoneCDKTick > 15 do 
        TweenTo(ExitDoor.CFrame + Vector3.new(0, math.random(1,5), 0)) 
        task.wait(1) 
    end 
    
    Hop('Rejoin')
end 
SeaCastlePosition = Vector3.new(-5543.5327148438, 313.80062866211, -2964.2585449219)

function DoCDKTasks (CachedData) 
    if type(CachedData) ~= 'table' then return end 
    
    if not workspace.Map:FindFirstChild('Turtle') or not workspace.Map.Turtle:FindFirstChild('Cursed') then return end
    local CursedTemple = workspace.Map.Turtle.Cursed
    if CachedData[1] == 'break' then 
        TweenTo(workspace.Map.Turtle.Cursed.Breakable.CFrame)
        Remotes.CommF_:InvokeServer('CDKQuest', 'OpenDoor')
        Remotes.CommF_:InvokeServer('CDKQuest', 'OpenDoor', true)
        workspace.Map.Turtle.Cursed.Breakable:Destroy()
        CDKProgess = nil  
        return true
    end 
    if CachedData[1] == 'burn 2' then
        if workspace.Map.Turtle.Cursed.Pedestal3.ProximityPrompt.Enabled then 
            fireproximityprompt(workspace.Map.Turtle.Cursed.Pedestal3.ProximityPrompt)
            task.wait(1) 
            pcall(function() 
                LocalPlayer.Character.Humanoid.Health = 0
            end)
            task.wait(10)
        else
            CDKAttempts = ( CDKAttempts or 0 ) + 1
            TweenTo(CFrame.new(-12341.66796875, 603.3455810546875, -6550.6064453125)) 
            task.wait(5) 
            
            pcall(function() 
                LocalPlayer.Character.Humanoid.Health = 0
            end)
            task.wait(5)
            if CDKAttempts > 5 then 
                Hop('CDK Stuck')
            end
            
            CDKProgess = nil  
        end
    elseif CachedData[1] == 'burn' then 
        for Index = 1, 3, 1 do
            local Pedestal = workspace.Map.Turtle.Cursed:FindFirstChild('Pedestal' .. Index) 
            
            if Pedestal and Pedestal.ProximityPrompt.Enabled then  -- FIX 17: Dùng biến Pedestal đã khai báo
                repeat task.wait() 
                    TweenTo(Pedestal.CFrame) 
                until CaculateDistance(Pedestal.CFrame) < 5
                
                fireproximityprompt(Pedestal.ProximityPrompt)
                task.wait(3) 
                pcall(function() 
                    LocalPlayer.Character.Humanoid.Health = 0
                end) 
            end 
            CDKProgess = nil  
        end 
        
    elseif CachedData[1] == 'Evil' then 
        if CachedData[2] == 1 then 
            local Mob = ConChoChisiti36.Enemies['Forest Pirate'] 
            
            TweenTo((Mob and Mob.HumanoidRootPart.CFrame) or CFrame.new(-13345, 332, -7630))
            CDKProgess = nil  
        elseif CachedData[2] == 2 then 
            local Hazed = (GetHazedMobs())
            
            AttackMob(tostring(Hazed))
            CDKProgess = nil  
        elseif CachedData[2] == 3 then 
            print('found CDK yama 3')
            while not ( os.time() - TorchEnabledTime < 100 or not ConChoChisiti36.Enemies['Soul Reaper'] )  do
                print('tweening to soul reaper ')
                task.wait()
                TweenTo(ConChoChisiti36.Enemies['Soul Reaper']:GetModelCFrame())
                EquipTool('Melee')
                VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end
            if not ConChoChisiti36.Enemies['Soul Reaper'] then return end
            CompleteDimension'Hell Dimension'
            CDKProgess = nil  
        end 
    else
        if CachedData[2] == 1 then 
            for _, NPC in game.ReplicatedStorage.NPCs:GetChildren() do 
                if NPC.Name == 'Luxury Boat Dealer' then 
                    repeat task.wait() 
                         if os.time() - DoneCDKTick < 15 then return end
                        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = (NPC:GetModelCFrame()) 
                        RealNPC = nil
                        for _, npc in workspace.NPCs:GetChildren() do 
                            if CaculateDistance(npc:GetModelCFrame(), NPC:GetModelCFrame()) < 20 then 
                                RealNPC = npc 
                                break
                            end 
                        end 
                    until CaculateDistance(NPC:GetModelCFrame()) < 5 and RealNPC 
                    
                    Remotes.CommF_:InvokeServer('CDKQuest', 'BoatQuest', RealNPC) 
                end
            end
            CDKProgess = nil  
        elseif CachedData[2] == 2 then 
            if CaculateDistance(SeaCastlePosition) > 100 then 
                TweenTo(SeaCastlePosition) 
                return 
            end 
            
            PirateRaidQueryTime = PirateRaidQueryTime or os.time() 
            local NearestMob = GetMobAsSortedRange()[1] 
            if NearestMob and CaculateDistance(NearestMob:GetModelCFrame(), SeaCastlePosition) < 800 then 
                FoundCastle = true 
                AttackMob(NearestMob.Name)
            end 
            if os.time() - PirateRaidQueryTime > (FoundCastle and 120 or 30) and os.time() - PirateRaidSenque > 300 then WrapToServer('Castle')
            end 
        elseif CachedData[2] == 3 then 
            repeat task.wait() 
                print('attacking cake queen')
                AttackMob('Cake Queen')
            until os.time() - TorchEnabledTime < 10 or not ConChoChisiti36.Enemies['Cake Queen']
            
            TweenTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
            CompleteDimension('Heavenly Dimension')
            CDKProgess = nil  
        end 
    end
end


function SwitchWeapon() 
    local Inventory = ConChoChisiti36.Backpack
    if Inventory.Yama and Inventory.Yama.Mastery < 350 then 
        if ConChoChisiti36.Tools.Yama then return end 
        Remotes.CommF_:InvokeServer('LoadItem', 'Yama')
    end 
    
    if Inventory.Tushita and Inventory.Tushita.Mastery < 350 then 
        if ConChoChisiti36.Tools.Tushita then return end 
        Remotes.CommF_:InvokeServer('LoadItem', 'Tushita')
    end 
end 

while task.wait() do 
    (function()
        SwitchWeapon() 
        if modechange.CDK then 
            if CheckAndGetYama() then return end
            if CheckAndGetTushita() then return end
            local _CDKProgess = GetCursedDualKatanaProgress() 
            if _CDKProgess then 
                DoCDKTasks(_CDKProgess) 
                return 
            end 
        end 
        AttackMob({
            'Reborn Skeleton',
            'Living Zombie',
            'Demonic Soul',
            'Posessed Mummy'
        })
    end)()
end
