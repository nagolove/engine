function copy(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

function flatCopy(src)
    local dst = {}
    for k, v in pairs(src) do
        if type(v) ~= "table" and type(v) ~= "function" and type(v) ~= "thread" then
            dst[k] = v
        end
    end
    return dst
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
