--local gr = love.graphics
--local timer = require "Timer".new()
--local font = gr.newFont("DejaVuSansMono.ttf", 80)

--love.window.setMode(1920, 1080)

--local tobject = gr.newText(font)

require 'utf8'
local u8 = require "utf8"
local inspect = require "inspect"

--function love.draw()
    --gr.draw(tobject as love.graphics.Drawable)
--end

-- Добавляет в текстовый объект цветной текст линейно интерполируя цвета от 
-- fromcolor до tocolor для каждого символа.
-- Возвращает индекс для textobj:getWidth() или textobj:getHeight()

local function makeDescentColorText(
    textobj: love.graphics.Text, 
    textstr: string, 
    fromcolor: {number}, 
    tocolor: {number}, 
    ...:number
): number

    assert(textobj, "textobj should not be nil")
    assert(type(textstr) == "string", "textstr should be a string, not " .. type(textstr))
    assert(type(fromcolor) == "table", "fromcolor should be a table, not " .. type(fromcolor))
    assert(type(tocolor) == "table", "tocolor should be a table, not " .. type(tocolor))
    assert(#fromcolor == 4, "fromcolor should have 4 components")
    assert(#tocolor == 4, "tocolor should have 4 components")

    print("textobj", textobj)
    print("textstr", textstr)
    print("fromcolor", inspect(fromcolor))
    print("tocolor", inspect(tocolor))

    local slen = u8.len(textstr)
    print("slen", slen)

    local r, g, b, a = fromcolor[1], fromcolor[2], fromcolor[3], fromcolor[4]

    -- Приращение цвета
    local d_r = (tocolor[1] - fromcolor[1]) / slen
    local d_g = (tocolor[2] - fromcolor[2]) / slen
    local d_b = (tocolor[3] - fromcolor[3]) / slen
    local d_a = (tocolor[4] - fromcolor[4]) / slen

    print("d_r", d_r)
    print("d_g", d_g)
    print("d_b", d_b)
    print("d_a", d_a)

    --[[
    Рассчитать цвет для приращения к начальному исходя из разницы цветов и 
    количества символов в стрке
    --]]

    local coloredtext: {any} = {}
    for p, c in u8.codes(textstr) do
        --local char = u8.char(c as number)

        --- XXX
        local char = u8.char(c as number)
        print("p, c, char", p, c, u8.char(c as number))

        table.insert(coloredtext, { r, g, b, a})
        table.insert(coloredtext, char)
        r = r + d_r
        g = g + d_g
        b = b + d_b
        a = a + d_a
    end

    --return textobj:add(coloredtext, ...)
    --return textobj:add(coloredtext as {string|table}, ...)
    return textobj:add(coloredtext as {string}, ...)
end

--function love.update(dt)
    --timer:update(dt)
--end

--[[
function love.load()
    local x, y = 0, 0
    local index = 0
    index = makeDescentColorText(tobject, "hippopotamus", {1, 0, 0, 1}, {0.5, 0, 0, 1}, x, y)
    y = y + tobject:getHeight(index)
    index = makeDescentColorText(tobject, "бегемот", {1, 0, 0, 1}, {0.5, 0.7, 0, 1}, x, y)
    y = y + tobject:getHeight(index)
    index = makeDescentColorText(tobject, "крокодил", {0, 0, 0.5, 1}, {0.5, 0.7, 0.9, 1}, x, y)
end
--]]

--[[
function love.keypressed(_, key)
    if key == "space" then
        makeDescentColorText(
                tobject, "hippopotamus",
                {1, 0, 0, 1}, {0.5, 0, 0, 1}
            )
    end

    local ok, errmsg = pcall(function()
        if key == "1" then
            makeDescentColorText(
                tobject, "hippopotamus",
                {1, 0, 0, 1}, 12
            )
        elseif key == "2" then
            makeDescentColorText(
                tobject, "hippopotamus",
                0, {0.5, 0, 0, 1}
            )
        elseif key == "3" then
            makeDescentColorText(
                nil, "hippopotamus",
                {1, 0, 0, 1}, {0.5, 0, 0, 1}
            )
        elseif key == "4" then
            makeDescentColorText(
                tobject, function() end,
                {1, 0, 0, 1}, {0.5, 0, 0, 1}
            )
        elseif key == "5" then
            makeDescentColorText(
                tobject, "hippopotamus",
                {1, 0, 0, 1}, {0, 0, 1}
            )
        elseif key == "6" then
            makeDescentColorText(
                tobject, "hippopotamus",
                {1, 0, 1}, {0.5, 0, 0, 1}
            )
        end
    end)
    if not ok then
        print("errmsg", errmsg)
    end

end
--]]

return {
    makeDescentColorText = makeDescentColorText,
}
