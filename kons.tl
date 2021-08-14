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

local record kons 

    -- {{{ Types
    type Text = record
        -- строка с шаблонами
        processed: string
        -- только текст, шаблоны удалены
        unprocessed: string
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
    push2: function(kons, number, string, ...:any): kons

    pushi: function(kons, string|{string}, ...: any): kons
    pushiColored: function(kons, text: string, ...: any): kons

    draw: function(kons, x0: number, y0: number)
    update: function(kons)

    -- {{{ Private variables.
    font: love.graphics.Font
    color: {number}
    show: boolean

    --strings: {Item}
    --strings_i: {string}
    strings: {Item}
    strings_i: {Text}
    strings_num: integer
    strings_i_num: integer
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
    -- XXX След строка проверяет оба типа или только один?
    if type(unprocessed) ~= "string" and type(unprocessed) ~= 'table' then
        error("kons.Text.new() unprocessed type is " .. type(unprocessed))
    end
    local self: kons.Text = setmetatable({} as kons.Text, Text_mt)
    local tmp: string
    if type(unprocessed) == 'table' then
        self.linesnum = #(unprocessed as {string})
        tmp = string.gsub(
            table.concat(unprocessed as {string}, "\n"),
            "(%%{(.-)})", 
            function(str: string): string return str end
        )
    else
        self.linesnum = 1
        tmp = string.gsub(
            --unprocessed as string,
            tostring(unprocessed),
            "(%%{(.-)})", 
            function(str: string): string return str end
        )
    end
    --local inspect = require "inspect"
    --print("tmp", inspect(tmp))
    --print("...", inspect({...}))
    --self.processed = "<><><><>"
    self.processed = string.format(tmp, ...)
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
    local inst = {
        font = font,
        color = {1, 1, 1},
        show = true,
        strings = {},
        strings_i = {},
        strings_num = 0,
        strings_i_num = 0,
    }
    return setmetatable(inst as kons, kons_mt) 
    -- }}}
end

function kons:clear()
    -- {{{
    self.strings_i = {}
    self.strings_i_num = 0
    self.strings = {}
    self.strings_num = 0
    -- }}}
end

--[[
function kons:push2(lifetime: number, text: string, ...: any): kons
    -- {{{
    if type(lifetime) ~= "number" then
        error("First argument - cardinal value of text lifetime.")
    end

    local processed = string.gsub(text,"(%%{(.-)})", 
    function(str: string): string
            print("processing", str)
            return str
    end)
    print("processed", processed)

    assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
    self.strings[self.strings_num + 1] = { 
        text = string.format(text, ...),
        lifetime = lifetime,
        timestamp = love.timer.getTime()
    }
    self.strings_num = self.strings_num + 1
    return self
end
-- }}}
--]]

function kons:push(lifetime: number, text: string, ...: any): kons
    -- {{{
    if type(lifetime) ~= "number" then
        error("First argument - cardinal value of text lifetime.")
    end
    assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
    self.strings[self.strings_num + 1] = { 
        text = kons.Text.new(text, ...),
        lifetime = lifetime,
        timestamp = love.timer.getTime()
    }
    self.strings_num = self.strings_num + 1
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

    self.strings_i[self.strings_i_num + 1] = kons.Text.new(processed, ...)
    self.strings_i_num = self.strings_i_num + 1
    return self
    -- }}}
end

function kons:pushi(text: string|{string}, ...: any): kons
    -- {{{
    if type(text) == 'string' then
        self.strings_i[self.strings_i_num + 1] = kons.Text.new(text as string, ...)
        self.strings_i_num = self.strings_i_num + 1
    else
        self.strings_i[self.strings_i_num + 1] = kons.Text.new(text, ...)
        self.strings_i_num = self.strings_i_num + 1
    end
    return self
    -- }}}
end

function kons:draw(x0: number, y0: number)
    -- {{{
    x0 = x0 or 0
    y0 = y0 or 0

    if not self.show then return end

    local curColor = {g.getColor()}
    g.setColor(self.color)

    local oldFont = love.graphics.getFont()
    love.graphics.setFont(self.font)

    --print("processed", processed)
    local y = y0

    for _, v in ipairs(self.strings) do
        g.print(v.text.processed, x0, y)
        y = y + g.getFont():getHeight()
    end

    --for k, v in ipairs(self.strings_i) do
    for k, v in ripairs(self.strings_i) do

        --[[
    local _ = string.gsub(text,"(%%{(.-)})", 
    function(str: string): string
            print("str", str)
            --g.setColor
            return ""
    end)
    --]]
        g.print(v.processed, x0, y)
        y = y + g.getFont():getHeight() * v.linesnum
        self.strings_i[k] = nil
    end
    self.strings_i_num = 0

    love.graphics.setFont(oldFont)
    g.setColor(curColor)

    self.height = math.abs(y - y0)
    -- }}}
end

function kons:update()
    -- {{{
    for k, v in ipairs(self.strings) do
        local time = love.timer.getTime()
        if v then
            v.lifetime = v.lifetime  - (time - v.timestamp)
            if v.lifetime <= 0 then
                self.strings[k] = self.strings[self.strings_num]
                self.strings[self.strings_num] = nil
                self.strings_num = self.strings_num - 1
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
