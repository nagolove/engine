function copy(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

function copy1(t)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = {}
            local newt = result[k]
            for k1, v1 in pairs(v) do
                newt[k1] = v1
            end
        else
            result[k] = v
        end
    end
    return result
end
