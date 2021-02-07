--[[
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
--]]

require "love"
local g = love.graphics

local record kons 
    type Item = record
        text: string
        lifetime: number
        timestamp: number
    end
    color: {number}
    show: boolean
    strings: {Item}
    strings_i: {string}
    strings_num: number
    strings_i_num: number
    height: number

    new: function(): kons
    clear: function(kons)
    push: function(kons, number, string, ...:any): kons
    pushi: function(kons, string, ...: any): kons
    draw: function(kons, x0: number, y0: number)
    update: function(kons)

    --__call: function(kons): kons
end

local kons_mt: metatable<kons> = {
    --__call: function(kons): kons
}

kons_mt.__index = kons

function kons_mt.__call(self: kons): kons
    return self.new()
end

function kons.new(): kons
    local inst = {
        color = {1, 1, 1},
        show = true,
        strings = {},
        strings_i = {},
        strings_num = 0,
        strings_i_num = 0,
    }
    return setmetatable(inst as kons, kons_mt) 
end

function kons:clear()
    self.strings_i = {}
    self.strings_i_num = 0
    self.strings = {}
    self.strings_num = 0
end

function kons:push(lifetime: number, text: string, ...: any): kons
    if type(lifetime) ~= "number" then
        error("First argument - cardinal value of text lifetime.")
    end
    assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
    self.strings[self.strings_num + 1] = { 
        text = string.format(text, ...),
        lifetime = lifetime,
        timestamp = love.timer.getTime()
    }
    self.strings_num = self.strings_num + 1
    return self
end

function kons:pushi(text: string, ...: any): kons
    self.strings_i[self.strings_i_num + 1] = string.format(text, ...)
    self.strings_i_num = self.strings_i_num + 1
    return self
end

function kons:draw(x0: number, y0: number)
    x0 = x0 or 0
    y0 = y0 or 0

    if not self.show then return end

    local curColor = {g.getColor()}
    g.setColor(self.color)

    local y = y0
    for k, v in ipairs(self.strings_i) do
        g.print(v, x0, y)
        y = y + g.getFont():getHeight()
        self.strings_i[k] = nil -- XXX
    end
    self.strings_i_num = 0

    for _, v in ipairs(self.strings) do
        --print("v.text " .. v.text)
        g.print(v.text, x0, y)
        y = y + g.getFont():getHeight()
    end

    g.setColor(curColor)

    self.height = math.abs(y - y0)
end

function kons:update()
    for k, v in ipairs(self.strings) do
        local time = love.timer.getTime()
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

--return setmetatable(kons, { __call = function(cls, ...)
    --return cls.new(...)
--end})

return kons
