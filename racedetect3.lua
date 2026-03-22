repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local COMMF_ = game:GetService("ReplicatedStorage").Remotes.CommF_

print("══ TEST COMMF_ AROWE ══")

-- Thử tất cả kiểu gọi có thể với arowe
local tests = {
    {"NPCTalk",  "arowe"},
    {"Talk",     "arowe"},
    {"Interact", "arowe"},
    {"NPC",      "arowe"},
    {"Quest",    "arowe"},
    {"GetQuest", "arowe"},
    {"arowe",    nil},
    {"arowe",    "Talk"},
    {"arowe",    "Quest"},
    {"arowe",    "Check"},
    {"arowe",    "Race"},
    {"arowe",    "RaceV3"},
}

for _, t in ipairs(tests) do
    local cmd, arg = t[1], t[2]
    local ok, res
    if arg then
        ok, res = pcall(function() return COMMF_:InvokeServer(cmd, arg) end)
    else
        ok, res = pcall(function() return COMMF_:InvokeServer(cmd) end)
    end

    if ok then
        print(string.format("✅ ('%s','%s') → [%s] %s", cmd, tostring(arg), type(res), tostring(res)))
        if type(res) == "table" then
            for k,v in pairs(res) do print("   ", k, "=", tostring(v)) end
        end
    else
        print(string.format("❌ ('%s','%s') err: %s", cmd, tostring(arg), tostring(res):sub(1,60)))
    end
    task.wait(0.1)
end

print("══ DONE ══")
