-- ══════════════════════════════════════════
-- TEST NPC AROWE - In kết quả ra console
-- ══════════════════════════════════════════
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- ── In thông tin NPC Arowe ──
local ok, arowe = pcall(function()
    return game:GetService("Workspace").NPCs.arowe
end)

if ok and arowe then
    print("✅ Tìm thấy NPC: " .. arowe.Name)
    print("── Children của arowe ──")
    for _, v in ipairs(arowe:GetDescendants()) do
        print("  [" .. v.ClassName .. "] " .. v:GetFullName())
    end
else
    warn("❌ Không tìm thấy NPC arowe:", arowe)
end

-- ── Thử gửi các lệnh CommF_ đến arowe ──
local commands = {
    "GetRaceV3",
    "RaceV3",
    "CheckRaceV3",
    "UpgradeRaceV3",
    "GhoulV3",
    "RaceUpgrade",
    "GetRace",
    "CheckRace",
    "Arowe",
    "arowe",
    "NPCTalk",
    "Talk",
    "Interact",
    "Quest",
    "GetQuest",
}

print("\n── Thử InvokeServer từng lệnh ──")
for _, cmd in ipairs(commands) do
    local s, r = pcall(function()
        return COMMF_:InvokeServer(cmd)
    end)
    if s then
        print("✅ [" .. cmd .. "] → " .. tostring(r))
    else
        print("❌ [" .. cmd .. "] → " .. tostring(r))
    end
    task.wait(0.1)
end

-- ── Thử với tên NPC làm tham số ──
print("\n── Thử InvokeServer với 'arowe' làm tham số ──")
local cmds2 = {"NPCTalk", "Talk", "Interact", "Quest", "GetQuest", "NpcInteract"}
for _, cmd in ipairs(cmds2) do
    local s, r = pcall(function()
        return COMMF_:InvokeServer(cmd, "arowe")
    end)
    if s then
        print("✅ [" .. cmd .. ", arowe] → " .. tostring(r))
    else
        print("❌ [" .. cmd .. ", arowe] → " .. tostring(r))
    end
    task.wait(0.1)
end

print("\n══ DONE ══")
