local function newDrawingRange(from, to)
    local DrawingRange_mt = {}
    function DrawingRange_mt.__index(table, key)
        print("index", key)
        return rawget(table, key)
    end
    function DrawingRange_mt.__newindex(table, key, value)
        print("newindex key", key, "value", value)

        local from = rawget(table, "from")
        local to = rawget(table, "to")
        local width = rawget(table, "width")

        print("t", inspect(table))

        if key == "from" then
            if value + width < to then
                rawset(table, key, value)
                rawset(table, "to", value + width)
            end
        elseif key == "to" then
        elseif key == "width" then
        end
    end
    return setmetatable({
        from = from,
        to = to,
        width = to - from
    }, DrawingRange_mt)
end

return {
    newDrawingRange = newDrawingRange,
}
