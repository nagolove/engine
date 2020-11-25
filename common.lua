function shallowCopy(t)
    local res = {}
    for k, v in pairs(t) do
        res[k] = v
    end
    return res
end


