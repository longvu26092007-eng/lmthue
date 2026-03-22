-- ══════════════════════════════════════════
-- REMOTE DEBUGGER - Hook tất cả remote
-- Nhấn vào NPC xem nó gửi lệnh gì
-- ══════════════════════════════════════════
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local RS = game:GetService("ReplicatedStorage")
local logs = {}

local function serialize(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = type(v)
    if t == "string" then return '"' .. v .. '"' end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "nil" then return "nil" end
    if typeof(v) == "Instance" then return "[Instance:" .. v.ClassName .. " " .. v.Name .. "]" end
    if typeof(v) == "Vector3" then return tostring(v) end
    if typeof(v) == "CFrame" then return "[CFrame]" end
    if t == "table" then
        local parts = {}
        for k, val in pairs(v) do
            table.insert(parts, tostring(k) .. "=" .. serialize(val, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local function log(tag, remote, args, ret)
    local argStr = {}
    for _, a in ipairs(args) do
        table.insert(argStr, serialize(a))
    end
    local retStr = ret ~= nil and (" → " .. serialize(ret)) or ""
    local msg = string.format("[%s] %s(%s)%s", tag, remote.Name, table.concat(argStr, ", "), retStr)
    print(msg)
    table.insert(logs, msg)
end

-- ══════════════════════════════════════════
-- HOOK TẤT CẢ REMOTE FUNCTION (InvokeServer)
-- ══════════════════════════════════════════
local function hookAllRemotes(parent)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteFunction") then
            local oldInvoke = obj.InvokeServer
            obj.InvokeServer = newcclosure(function(self, ...)
                local args = {...}
                local ok, ret = pcall(oldInvoke, self, ...)
                if ok then
                    log("RF", obj, args, ret)
                    return ret
                else
                    log("RF❌", obj, args, ret)
                end
            end)
        end

        if obj:IsA("RemoteEvent") then
            local oldFire = obj.FireServer
            obj.FireServer = newcclosure(function(self, ...)
                local args = {...}
                log("RE", obj, args, nil)
                return oldFire(self, ...)
            end)
        end
    end
end

-- Hook RS.Remotes
pcall(function() hookAllRemotes(RS.Remotes) end)
-- Hook RS.Modules.Net nếu có
pcall(function() hookAllRemotes(RS.Modules) end)
-- Hook toàn bộ RS
pcall(function() hookAllRemotes(RS) end)

print("✅ Remote Debugger đã bật!")
print("👉 Bây giờ hãy nhấn vào NPC arowe")
print("══════════════════════════════")

-- Tự động in lại log mỗi 5 giây nếu có gì mới
local lastCount = 0
task.spawn(function()
    while true do
        task.wait(5)
        if #logs > lastCount then
            print(string.format("── %d remotes logged ──", #logs))
            lastCount = #logs
        end
    end
end)
