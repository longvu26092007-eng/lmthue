-- TEST REMOTE NPC AROWE
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local RS = game:GetService("ReplicatedStorage")
local COMMF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")

print("══ TEST REMOTE AROWE ══")

-- Thử các lệnh phổ biến với NPC trong Blox Fruits
local tests = {
    -- Dạng (lệnh, tên NPC)
    function() return COMMF_:InvokeServer("NPCTalk", "arowe") end,
    function() return COMMF_:InvokeServer("Talk", "arowe") end,
    function() return COMMF_:InvokeServer("Interact", "arowe") end,
    function() return COMMF_:InvokeServer("NPC", "arowe") end,
    function() return COMMF_:InvokeServer("GetNPC", "arowe") end,
    function() return COMMF_:InvokeServer("QuestNPC", "arowe") end,
    -- Dạng FireServer (CommE)
}

local COMME_ = RS.Remotes:WaitForChild("CommE")

-- Thử FireServer CommE
local fireTests = {
    function() COMME_:FireServer("NPCTalk", "arowe") end,
    function() COMME_:FireServer("Talk", "arowe") end,
    function() COMME_:FireServer("Interact", "arowe") end,
    function() COMME_:FireServer("NPC", "arowe") end,
}

-- InvokeServer tests
for i, fn in ipairs(tests) do
    local ok, res = pcall(fn)
    if ok then
        print(string.format("[InvokeServer test %d] ✅ → type:%s | val:%s", i, type(res), tostring(res)))
        if type(res) == "table" then
            for k,v in pairs(res) do
                print("  key:", k, "=", tostring(v))
            end
        end
    else
        print(string.format("[InvokeServer test %d] ❌ err: %s", i, tostring(res)))
    end
    task.wait(0.15)
end

-- FireServer tests
print("\n── CommE FireServer tests ──")
for i, fn in ipairs(fireTests) do
    local ok, err = pcall(fn)
    if ok then
        print(string.format("[FireServer test %d] ✅ fired", i))
    else
        print(string.format("[FireServer test %d] ❌ err: %s", i, tostring(err)))
    end
    task.wait(0.15)
end

-- Thử firetouchinterest trực tiếp với NPC
print("\n── FireTouchInterest với arowe ──")
pcall(function()
    local arowe = workspace.NPCs.arowe
    local hrp = arowe:FindFirstChild("HumanoidRootPart") or arowe.PrimaryPart
    local plrHRP = game.Players.LocalPlayer.Character.HumanoidRootPart
    if hrp and plrHRP then
        firetouchinterest(hrp, plrHRP, 0)
        task.wait(0.1)
        firetouchinterest(hrp, plrHRP, 1)
        print("✅ firetouchinterest fired")
    end
end)

-- Print toàn bộ RemoteEvents trong Remotes để tìm cái liên quan
print("\n── Tất cả RemoteFunction trong RS.Remotes ──")
for _, v in ipairs(RS.Remotes:GetChildren()) do
    if v:IsA("RemoteFunction") then
        print("RemoteFunction:", v.Name)
    end
end

print("══ DONE ══")
