function copy(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end


