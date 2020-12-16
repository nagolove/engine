local inspect = require "inspect"

--[[
--interface:
-- from,
-- to,
-- width
--]]
local function newDrawingRange(from, to)
    local DrawingRange_mt = {}
    local store = {
        from = from,
        to = to,
        width = to - from
    }
    local methods = {}
    function methods:setBorders(firstFrameIndex, lastFrameIndex)
        print("firstFrameIndex", firstFrameIndex, "lastFrameIndex", lastFrameIndex)
    end
    function DrawingRange_mt.__index(table, key)
        return rawget(store, key) or methods[key]
        --print("v", inspect(v))
        --return v
    end
    function DrawingRange_mt.__newindex(table, key, value)
        print("newindex key", key, "value", value)

        local from = store.from
        local to = store.to
        local width = store.width

        --print("t", inspect(table))
        --print("key", key)

        if key == "from" then
            if value >= 1 then
                --rawset(table, key, value)
                --rawset(table, "to", value + width)
                store.from = value
                store.to = value + width
            end
        elseif key == "to" then
            --return store.to
        elseif key == "width" then
            --return store.width
        else
            error(string.format("Unknown key %s", key))
        end

    end
    return setmetatable({}, DrawingRange_mt)
end

local r = newDrawingRange(100, 300)
print("r", inspect(r))
for i = 1, 3 do
    r.from = r.from + 1
end
print("r", inspect(r))
--for i = 300, -100, -1 do
    --r.from = r.from - 1
--end
print("r", inspect(r))

print(r.x)

print("r", inspect(r))

return {
    newDrawingRange = newDrawingRange,
}
