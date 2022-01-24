local colors = {
    {24/255, 81/255, 129/255}, -- very deep sea
    {32/255, 97/255, 157/255}, -- deep sea
    {35/255, 113/255, 179/255}, -- sea
    {40/255, 128/255, 206/255}, -- shallow sea
    {60/255, 130/255, 70/255}, -- very dark green
    {72/255, 149/255, 81/255}, -- dark green
    {88/255, 164/255, 97/255}, -- green
    {110/255, 176/255, 120/255}, -- light green
    {84/255, 69/255, 52/255}, -- very dark brown
    {102/255, 85/255, 66/255}, -- dark brown
    {120/255, 100/255, 73/255}, -- brown
    {140/255, 117/255, 86/255}, -- light brown
    {207/255, 207/255, 207/255}, -- very dark white
    {223/255, 223/255, 223/255}, -- dark white
    {239/255, 239/255, 239/255}, -- white
    {255/255, 255/255, 255/255}, -- light white
}

local function interpolate_color(a: {number}, b: {number}, t: number): {number}
    local c = {}
    for i = 1, #a do
        c[i] = a[i] + t*(b[i]-a[i])
    end
    return c
end

local function color(value: number): {number}
    --print('color', value)
    local n = #colors + 2
    
    if value <= 1/n then
        return colors[1]
    end

    for i = 2, #colors do
        if value <= i/n then
            --print('i', i)
            local t = (value-((i-1)/n))/(1/n)
            return interpolate_color (colors[i-1], colors[i], t)
        end
    end

    -- more than last
    return colors[#colors]
end

return {
    color = color,
}
