local inspect = require "inspect"
local lg = love.graphics

local Object = require "object"
local HSlider = {}
HSlider.__index = setmetatable(HSlider, { __index = Object })

local defaultColor = {0.3, 0.5, 0.1}
local hoveredColor = {0.6, 0.5, 0.1}
local captionColor = {0, 0, 0}
local quadColor = {0.6, 0.8, 0.2}
local hoveredQuadColor = {0.8, 0.1, 0.2}

function HSlider:new(x, y, w, h)
    local o = {
        x = x,
        y = y,
        w = w,
        h = h,
        onAndroid = love.system.getOS() == "Android",
        hovered = false,
        color = defaultColor,
        hoveredColor = hoveredColor,
        captionColor = captionColor,
        quadColor = quadColor,
        hoveredQuadColor = hoveredQuadColor,
        caption = nil,
        font = lg.getFont(),
        minValue = 0,
        maxValue = 1,
        value = 0,
    }
    setmetatable(o, HSlider)
    return o
end

function HSlider:mousemoved(x, y, dx, dy, istouch)
    if not self.onAndroid then
        self.hovered = self:inside(x, y, self.x, self.y, self.w, self.h)
        self.inquad = self:inside(x, y, self.x + self.w * self.value, self.y, 
            self.h, self.h)
        --print("showTip", inspect(self.showTip))
    end
end

function HSlider:mousepressed(x, y, button, istouch, presses)
    if not self.onAndroid and self.onpress and 
        self:inside(x, y, self.x + self.w * self.value, self.y, self.w, self.h) then
        self:onpress()
    end
end

function HSlider:touchpressed(id, x, y, dx, dy, pressure)
    self.hovered = self:inside(x, y, self.x, self.y, self.w, self.h)
end

function HSlider:touchreleased(id, x, y, dx, dy, pressure)
    if self.onpress and self:inside(x, y, self.x, self.y, self.w, self.h) then
        self:onpress()
    end
end

function HSlider:touchmoved(id, x, y, dx, dy, pressure)
    self.hovered = self:inside(x, y, self.x, self.y, self.w, self.h)
end

function HSlider:update(dt)
end

function HSlider:draw()
    self:preDraw()

    lg.setColor(self.hovered and self.hoveredColor or self.color)
    lg.rectangle("fill", self.x, self.y, self.w, self.h, 4, 4)
    lg.setColor(self.captionColor)
    --[[
       [if self.caption then
       [    local y = self.y - self.font:getHeight() + self.w / 2
       [    lg.printf(self.caption, self.font, self.x, y, self.w, "center")
       [end
       ]]
    lg.setColor(self.inquad and self.hoveredQuadColor or self.quadColor)
    local x = self.x + self.w * self.value
    lg.rectangle("fill", x, self.y, self.h, self.h)
    --[[
       [if self.inquad then
       [    lg.setColor(self.captionColor)
       [    print("ok", self.showTip.x, self.showTip.y)
       [    lg.print(tostring(value), self.showTip.x, self.showTip.y)
       [    --lg.circle("fill", self.showTip.x, self.showTip.y, 10)
       [    lg.print(tostring(self.value), 0, 0)
       [end
       ]]
    self:postDraw()
end

return HSlider
