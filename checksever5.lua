-- ═══════════════════════════════════════════════════════════════════════
-- 🔥 SERVER UPTIME DETECTOR - FIXED VERSION  
-- Tạo LocalScript trong StarterPlayerScripts thay vì inject
-- Đặt trong: ServerScriptService
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("═══════════════════════════════════════════════════════════════")
print("🔥 SERVER UPTIME DETECTOR - STARTING...")
print("═══════════════════════════════════════════════════════════════")

-- ═════════════════════════════════════════════════════════════════════
-- PHẦN 1: SERVER - Set ServerStartTime
-- ═════════════════════════════════════════════════════════════════════
local serverStartTime = Workspace:GetServerTimeNow()
Workspace:SetAttribute("ServerStartTime", serverStartTime)

print("✅ Server start time set: " .. tostring(serverStartTime))
print("📌 Server officially started at: " .. os.date("%Y-%m-%d %H:%M:%S UTC"))

-- ═════════════════════════════════════════════════════════════════════
-- PHẦN 2: Tạo LocalScript trong StarterPlayerScripts
-- ═════════════════════════════════════════════════════════════════════

local starterPlayer = game:GetService("StarterPlayer")
local starterPlayerScripts = starterPlayer:WaitForChild("StarterPlayerScripts")

-- Xóa LocalScript cũ nếu có
local existingScript = starterPlayerScripts:FindFirstChild("ServerUptimeClient")
if existingScript then
    existingScript:Destroy()
    print("🗑️ Removed old ServerUptimeClient")
end

-- Tạo LocalScript mới
local localScript = Instance.new("LocalScript")
localScript.Name = "ServerUptimeClient"

print("📝 Creating LocalScript source code...")

-- IMPORTANT: Viết source code dưới dạng string
localScript.Source = [[local Players=game:GetService("Players")local Workspace=game:GetService("Workspace")local UserInputService=game:GetService("UserInputService")local a=Players.LocalPlayer;local b=a:WaitForChild("PlayerGui")local c=tick()print("═══════════════════════════════════════════════════════════════")print("🟢 SERVER UPTIME UI PANEL - STARTING...")print("═══════════════════════════════════════════════════════════════")local function d(e)e=math.max(0,math.floor(e))local f=math.floor(e/86400)local g=math.floor(e%86400/3600)local h=math.floor(e%3600/60)local i=math.floor(e%60)if f>0 then return string.format("%dd %02d:%02d:%02d",f,g,h,i)else return string.format("%02d:%02d:%02d",g,h,i)end end;local function j(k)return os.date("%Y-%m-%d %H:%M:%S",k)end;local function l()local m=Workspace:GetAttribute("ServerStartTime")if not m then return nil end;return Workspace:GetServerTimeNow()-m end;local function n()return Workspace:GetAttribute("ServerStartTime")end;local o=Instance.new("ScreenGui")o.Name="ServerUptimePanel"o.ResetOnSpawn=false;o.IgnoreGuiInset=true;o.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;o.Parent=b;local p=Instance.new("Frame")p.Name="MainPanel"p.Size=UDim2.new(0,400,0,280)p.Position=UDim2.new(0.5,-200,0.5,-140)p.BackgroundColor3=Color3.fromRGB(25,25,30)p.BorderSizePixel=0;p.Parent=o;local q=Instance.new("UICorner")q.CornerRadius=UDim.new(0,12)q.Parent=p;local r=Instance.new("Frame")r.Name="Header"r.Size=UDim2.new(1,0,0,50)r.BackgroundColor3=Color3.fromRGB(35,35,40)r.BorderSizePixel=0;r.Parent=p;local s=Instance.new("UICorner")s.CornerRadius=UDim.new(0,12)s.Parent=r;local t=Instance.new("Frame")t.Size=UDim2.new(1,0,0,12)t.Position=UDim2.new(0,0,1,-12)t.BackgroundColor3=Color3.fromRGB(35,35,40)t.BorderSizePixel=0;t.Parent=r;local u=Instance.new("TextLabel")u.Name="Title"u.Size=UDim2.new(1,-100,1,0)u.Position=UDim2.new(0,15,0,0)u.BackgroundTransparency=1;u.Text="🟢 SERVER INFO"u.TextColor3=Color3.fromRGB(0,255,128)u.TextSize=20;u.Font=Enum.Font.GothamBold;u.TextXAlignment=Enum.TextXAlignment.Left;u.Parent=r;local v=Instance.new("TextButton")v.Name="CloseButton"v.Size=UDim2.new(0,40,0,40)v.Position=UDim2.new(1,-45,0,5)v.BackgroundColor3=Color3.fromRGB(255,60,60)v.BorderSizePixel=0;v.Text="✕"v.TextColor3=Color3.fromRGB(255,255,255)v.TextSize=20;v.Font=Enum.Font.GothamBold;v.Parent=r;local w=Instance.new("UICorner")w.CornerRadius=UDim.new(0,8)w.Parent=v;local x=Instance.new("TextButton")x.Name="MinimizeButton"x.Size=UDim2.new(0,40,0,40)x.Position=UDim2.new(1,-90,0,5)x.BackgroundColor3=Color3.fromRGB(255,180,0)x.BorderSizePixel=0;x.Text="−"x.TextColor3=Color3.fromRGB(255,255,255)x.TextSize=20;x.Font=Enum.Font.GothamBold;x.Parent=r;local y=Instance.new("UICorner")y.CornerRadius=UDim.new(0,8)y.Parent=x;local z=Instance.new("Frame")z.Name="Content"z.Size=UDim2.new(1,-30,1,-65)z.Position=UDim2.new(0,15,0,55)z.BackgroundTransparency=1;z.Parent=p;local function A(B,C,D)local E=Instance.new("Frame")E.Name=B.."Row"E.Size=UDim2.new(1,0,0,35)E.Position=UDim2.new(0,0,0,D)E.BackgroundTransparency=1;E.Parent=z;local F=Instance.new("TextLabel")F.Name="Label"F.Size=UDim2.new(0.45,0,1,0)F.BackgroundTransparency=1;F.Text=C..":"F.TextColor3=Color3.fromRGB(150,150,160)F.TextSize=14;F.Font=Enum.Font.Gotham;F.TextXAlignment=Enum.TextXAlignment.Left;F.Parent=E;local G=Instance.new("TextLabel")G.Name="Value"G.Size=UDim2.new(0.55,0,1,0)G.Position=UDim2.new(0.45,0,0,0)G.BackgroundTransparency=1;G.Text="Loading..."G.TextColor3=Color3.fromRGB(255,255,255)G.TextSize=14;G.Font=Enum.Font.GothamBold;G.TextXAlignment=Enum.TextXAlignment.Right;G.Parent=E;return G end;local H=A("ServerUptime","Server Uptime",0)local I=A("ServerStart","Server Started",40)local J=A("PlayerJoin","You Joined",80)local K=A("SessionTime","Session Time",120)local L=A("PlayersOnline","Players Online",160)local function M()local N=l()local O=n()if N then H.Text=d(N)H.TextColor3=Color3.fromRGB(0,255,128)else H.Text="Loading..."H.TextColor3=Color3.fromRGB(255,255,0)end;if O then I.Text=j(O)end;local P=tick()-c;K.Text=d(P)L.Text=tostring(#Players:GetPlayers())end;local Q=false;local R,S,T;local function U(V)local W=V.Position-S;p.Position=UDim2.new(T.X.Scale,T.X.Offset+W.X,T.Y.Scale,T.Y.Offset+W.Y)end;r.InputBegan:Connect(function(V)if V.UserInputType==Enum.UserInputType.MouseButton1 or V.UserInputType==Enum.UserInputType.Touch then Q=true;S=V.Position;T=p.Position;V.Changed:Connect(function()if V.UserInputState==Enum.UserInputState.End then Q=false end end)end end)r.InputChanged:Connect(function(V)if V.UserInputType==Enum.UserInputType.MouseMovement or V.UserInputType==Enum.UserInputType.Touch then R=V end end)UserInputService.InputChanged:Connect(function(V)if V==R and Q then U(V)end end)v.MouseButton1Click:Connect(function()o:Destroy()end)local X=false;x.MouseButton1Click:Connect(function()X=not X;if X then p:TweenSize(UDim2.new(0,400,0,50),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)z.Visible=false;x.Text="+"else p:TweenSize(UDim2.new(0,400,0,280),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)z.Visible=true;x.Text="−"end end)Workspace:GetAttributeChangedSignal("ServerStartTime"):Connect(M)M()task.spawn(function()while task.wait(1)do M()end end)UserInputService.InputBegan:Connect(function(V,Y)if not Y and V.KeyCode==Enum.KeyCode.F2 then p.Visible=not p.Visible end end)local Z={}function Z.getTotalUptime()local N=l()return N or 0 end;function Z.getFormattedUptime()return d(Z.getTotalUptime())end;function Z.formatTime(e)return d(e)end;function Z.togglePanel()p.Visible=not p.Visible end;_G.ServerUptimeAPI=Z;print("✅ SERVER UPTIME UI PANEL READY")print("💡 Press F2 to toggle panel")print("═══════════════════════════════════════════════════════════════")]]

-- Đặt vào StarterPlayerScripts
localScript.Parent = starterPlayerScripts

print("✅ LocalScript created in StarterPlayerScripts")
print("📌 Script will auto-run for all players")

-- Log server uptime mỗi 60 giây
task.spawn(function()
    while task.wait(60) do
        local currentTime = Workspace:GetServerTimeNow()
        local uptime = currentTime - serverStartTime
        local hours = math.floor(uptime / 3600)
        local mins = math.floor((uptime % 3600) / 60)
        local secs = math.floor(uptime % 60)
        
        print(string.format("[SERVER] Uptime: %02d:%02d:%02d", hours, mins, secs))
    end
end)

print("═══════════════════════════════════════════════════════════════")
print("✅ SERVER UPTIME DETECTOR - READY")
print("═══════════════════════════════════════════════════════════════")
