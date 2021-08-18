-- vim: fdm=marker
-- vim: set colorcolumn=85

--[[
{{{ API & usage

Object-oriented module for drawing multiline text.

-- import table
local kons = require "kons"

-- create an object
local buf = kons.new()

-- other object creation style.
local linesbuffer = kons() -- initial coordinates of drawing.

Usage:
* linesbuffer:draw() - draw first lines pushed by push_text_i(). After it 
drawing lines pushed by push()

* linesbuffer:push(1, "hello", ...) - push text to screeen for 1 second

* linesbuffer:pushi("fps %d", fps) -- push text to screen for one frame

* linesbuffer:clear() - full clear of console content

* linesbuffer:show() - show or hide text output by changing internal flag 

* linesbuffer:update() - internal mechanics computation. Paste to love.update()

Internal variables:
* linesbuffer:height - height in pixels of drawed text. Updated by :draw() call.

Calls of push() and pushi() can be chained:
  linesbuf:pushi("dd"):pushi("bbb")

}}}
--]]

require "love"
require "common"

local g = love.graphics

-- Если нужны новые цвета для консоли, то добавляй их в эту табличку.
global colorMap = {
    ["black"] = {0, 0, 0, 1},
    ["red"] = {1, 0, 0, 1},
    ["green"] = {0, 1, 0, 1},
    ["blue"] = {0, 0, 1, 1},
    ["white"] = {1, 1, 1, 1},
    ["default"] = {1, 1, 1, 1},
}

local record kons 

    -- {{{ Types
    type Text = record
        -- только текст, шаблоны удалены
        processed: string
        -- строка с шаблонами
        unprocessed: string
        -- сколько переводов строки в тексте
        linesnum: integer

        new: function(unprocessed: string|{string}, ...: any): Text
    end

    type Item = record
        text: Text
        lifetime: number
        timestamp: number
    end
    -- }}}

    new: function(fname: string, fsize: integer): kons
    clear: function(kons)

    push: function(kons, number, string, ...:any): kons

    pushi: function(kons, string|{string}, ...: any): kons
    pushiColored: function(kons, text: string, ...: any): kons

    draw: function(kons, x0: number, y0: number)
    update: function(kons)

    -- {{{ Private variables.
    font: love.graphics.Font
    textobj: love.graphics.Text
    color: {number}
    show: boolean

    strings: {Item}
    stringsi: {Text}
    height: number
    -- }}}
end

function kons.Text.new(unprocessed: string|{string}, ...: any): kons.Text
    -- {{{
    local Text_mt: metatable<kons.Text> = {
        __index = kons.Text,
    }
    if not unprocessed then
        error("kons.Text.new() unprocessed should not be nil")
    end
    --print(type(unprocessed))
    if type(unprocessed) ~= "string" and type(unprocessed) ~= 'table' then
        error("kons.Text.new() unprocessed type is " .. type(unprocessed))
    end
    local self: kons.Text = setmetatable({} as kons.Text, Text_mt)
    local tmp: string
    if type(unprocessed) == 'table' then
        print('branch1')
        self.linesnum = #(unprocessed as {string})
        self.unprocessed = table.concat(unprocessed as {string}, "\n")
        tmp = string.gsub(
            self.unprocessed,
            "(%%{(.-)})", 
            function(_: string): string 
                return ""
            end
        )
    elseif type(unprocessed) == 'string' then
        print('branch2')
        self.linesnum = 1
        self.unprocessed = unprocessed as string
        tmp = string.gsub(
            --unprocessed as string,
            self.unprocessed,
            "(%%{(.-)})", 
            function(_: string): string 
                return ""
            end
        )
    else
        error('Unsupported type: ' .. type(unprocessed))
    end

    -- FIXME
    -- падает если в tmp есть символ %
    -- как обойти падение?
    self.processed = string.format(tmp, ...)

    print('self.processed', self.processed)
    print('self.unprocessed', self.unprocessed)

    return self
    -- }}}
end

function kons.new(fname: string, fsize: integer): kons
    -- {{{
    local kons_mt: metatable<kons> = {
        __index = kons,
        __call = function(self: kons): kons
            return self.new()
        end
    }

    local font: love.graphics.Font
    local size = fsize or 20
    if fname then
        font = love.graphics.newFont(fname, size)
    else
        font = love.graphics.newFont(size)
    end
    local inst: kons = {
        font = font,
        color = {1, 1, 1},
        show = true,
        strings = {},
        stringsi = {},
        textobj = love.graphics.newText(font),
    }
    return setmetatable(inst , kons_mt) 
    -- }}}
end

function kons:clear()
    -- {{{
    self.stringsi = {}
    self.strings = {}
    self.textobj:clear()
    -- }}}
end

function kons:push(lifetime: number, text: string, ...: any): kons
    -- {{{
    if type(lifetime) ~= "number" then
        error("First argument - cardinal value of text lifetime.")
    end
    assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
    self.strings[#self.strings + 1] = { 
        text = kons.Text.new(text, ...),
        lifetime = lifetime,
        timestamp = love.timer.getTime()
    }
    --self.strings_num = self.strings_num + 1
    return self
    -- }}}
end

function kons:pushiColored(text: string, ...: any): kons
    -- {{{
    --print("pushiColored")

    local processed = string.gsub(text,"(%%{(.-)})", 
    function(_: string): string
            --print("processing", str)
            return ""
    end)
    --print("processed", processed)

    self.stringsi[#self.stringsi + 1] = kons.Text.new(processed, ...)
    return self
    -- }}}
end

function kons:pushi(text: string|{string}, ...: any): kons
    -- {{{
    if type(text) == 'string' then
        self.stringsi[#self.stringsi + 1] = kons.Text.new(text as string, ...)
    elseif type(text) == 'table' then
        self.stringsi[#self.stringsi + 1] = kons.Text.new(text, ...)
    else
        error('Unsupported type ' .. type(text))
    end
    return self
    -- }}}
end

function kons:draw(x0: number, y0: number)
    -- {{{
    self.textobj:clear()

    x0 = x0 or 0
    y0 = y0 or 0

    if not self.show then return end

    local curColor = {g.getColor()}
    g.setColor(self.color)

    local oldFont = love.graphics.getFont()
    --love.graphics.setFont(self.font)

    --print("processed", processed)
    local y = y0
    --local coloredtext = {}
    local fontHeight = self.textobj:getFont():getHeight()

    for _, v in ipairs(self.strings) do
        --g.print(v.text.processed, x0, y)
        --self.textobj:add(coloredtext, x0, y)
        self.textobj:add({v.text.processed}, x0, y)
        --y = y + g.getFont():getHeight()
        y = y + fontHeight
    end

    --for k, v in ipairs(self.strings_i) do
    --local inspect = require "inspect"
    --print('self.stringsi', inspect(self.stringsi))

    for _, v in ripairs(self.stringsi) do
        local coloredtext: {{number}|string} = {}

        --[[
        local _ = string.gsub(v.unprocessed,"(%%{(.-)})", 
        function(str: string): string
            print("processing", str)
            -- выдрать название цвета из строчки вида '%{black}'
            local colorname = string.sub(str, 3, #str - 1)
            --local colorname = string.match(str, "{(.*)}")
            --g.setColor
            return ""
        end)
        --]]

        --for k, v in string.gmatch(v.unprocessed,"(%%{(.-)})") do
        local istart, iend = 0, 0
        local init = 1
        local lastiend = 0

        istart, iend = string.find(v.unprocessed,"(%%{(.-)})", init)
        local leading: string
        if istart and istart >= 1 then
            leading = string.sub(v.unprocessed, 1, istart - 1)
            print('s0', leading)
        end
        if leading then
            table.insert(coloredtext, colorMap['default'])
            table.insert(coloredtext, leading)
        end

        print('#v.unprocessed', #v.unprocessed)

        repeat
            --if iend ~= 0 then
                lastiend = iend
            --end
            istart, iend = string.find(v.unprocessed,"(%%{(.-)})", init)

            if istart ~= 0 then
                --print('s', string.sub(v.unprocessed, 1, istart))
            end

            if istart then
                init = iend
            end
            print('istart, iend', istart, iend)
            if istart and iend then
                print('sub1', string.sub(v.unprocessed, istart, iend))
                --print('sub2', string.sub(v.unprocessed, lastiend + 1, istart - 1))
                print('sub2', string.sub(v.unprocessed, lastiend + 1, istart - 1))
            else
                print('sub3', string.sub(v.unprocessed, lastiend + 1, #v.unprocessed))
            end
        until not istart
            --print("gmatch", k, v)
        --end

        --g.print(v.processed, x0, y)
        table.insert(coloredtext, v.processed)

        --self.textobj:add({v.processed}, x0, y)
        self.textobj:add(coloredtext, x0, y)
        --self.textobj:add(coloredtext, x0, y)
        y = y + fontHeight * v.linesnum
        --self.stringsi[k] = nil
    end

    love.graphics.draw(self.textobj as love.graphics.Drawable, x0, y0)

    love.graphics.setFont(oldFont)
    g.setColor(curColor)

    self.height = math.abs(y - y0)
    self.stringsi = {}
    -- }}}
end

function kons:update()
    -- {{{
    for k, v in ipairs(self.strings) do
        local time = love.timer.getTime()
        if v then
            v.lifetime = v.lifetime  - (time - v.timestamp)
            if v.lifetime <= 0 then
                self.strings[k] = self.strings[#self.strings]
                self.strings[#self.strings] = nil
            else
                v.timestamp = time
            end
        end
    end
    -- }}}
end

--return setmetatable(kons, { __call = function(cls, ...)
    --return cls.new(...)
--end})

return kons
