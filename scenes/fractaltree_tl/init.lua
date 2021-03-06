local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; require("love")

local g, angle = love.graphics, 26 * math.pi / 180
local wid, hei = g.getWidth(), g.getHeight()

function rotate(x, y, a)
   local s, c = math.sin(a), math.cos(a)
   local a_, b_ = x * c - y * s, x * s + y * c
   return a_, b_
end

function branches(a, b, len, ang, dir)
   len = len * .76

   if len < 10 then return end

   g.setColor(len * 16, 255 - 2 * len, 0)
   if dir > 0 then ang = ang - angle
   else ang = ang + angle
   end
   local vx, vy = rotate(0, len, ang)
   vx = a + vx; vy = b - vy
   g.line(a, b, vx, vy)

   branches(vx, vy, len, ang, 1)
   branches(vx, vy, len, ang, 0)
end

function createTree()
   local lineLen = 127
   local a, b = wid / 2, hei - lineLen
   g.setColor(160, 40, 0)
   g.line(wid / 2, hei, a, b)
   branches(a, b, lineLen, 0, 1)
   branches(a, b, lineLen, 0, 0)
end

local canvas

local function init()
   canvas = g.newCanvas(wid, hei)
   g.setCanvas(canvas)
   createTree()
   g.setCanvas()
end

local function draw()
   g.draw(canvas)
end

local function update()
   if love.keyboard.isDown("escape") then
      love.event.quit()
   end
end

return {
   init = init,
   draw = draw,
   update = update,
}
