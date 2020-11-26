
local inspect = require "inspect"
local lg = love.graphics

local Object = require "object"
local Button = {}
Button.__index = setmetatable(Button, { __index = Object })

local defaultColor = {0.3, 0.5, 0.1}
local hoveredColor = {0.6, 0.5, 0.1}
local captionColor = {0, 0, 0}

function Button:new(x, y, w, h)
    local o = {
        x = x,
        y = y,
        w = w,
        h = h,
        hovered = false,
        color = defaultColor,
        hoveredColor = hoveredColor,
        captionColor = captionColor,
        caption = nil,
        font = lg.getFont(),
        onAndroid = love.system.getOS() == "Android",
    }
    setmetatable(o, Button)
    return o
end

function Button:mousemoved(x, y, dx, dy, istouch)
    if not self.onAndroid then
        self.hovered = self:inside(x, y, self.x, self.y, self.w, self.h)
    end
end

function Button:mousepressed(x, y, button, istouch, presses)
    if not self.onAndroid and self.onpress and 
        self:inside(x, y, self.x, self.y, self.w, self.h) then
        self:onpress()
    end
end

function Button:touchpressed(id, x, y, dx, dy, pressure)
    log:print("touchpressed", x, y)
    self.hovered = self:inside(x, y, self.x, self.y, self.w, self.h)
end

function Button:touchreleased(id, x, y, dx, dy, pressure)
    log:print("touchreleased", x, y)
    if self.onpress and self:inside(x, y, self.x, self.y, self.w, self.h) then
        self:onpress()
    end
end

function Button:touchmoved(id, x, y, dx, dy, pressure)
    log:print("touchmoved", x, y)
    self.hovered = self:inside(x, y, self.x, self.y, self.w, self.h)
end

function Button:update(dt)
end

function Button:draw()
    self:preDraw()

    lg.setColor(self.hovered and self.hoveredColor or self.color)
    lg.rectangle("fill", self.x, self.y, self.w, self.h, 4, 4)
    lg.setColor(self.captionColor)
    if self.caption then
        local y = self.y - self.font:getHeight() + self.w / 2
        lg.printf(self.caption, self.font, self.x, y, self.w, "center")
    end

    self:postDraw()
end

return Button
