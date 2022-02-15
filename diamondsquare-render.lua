


require('love')

local RandomGenerator = love.math.RandomGenerator
local color = require('height_map').color


 DSRender = {}























local DSRender_mt = {
   __index = DSRender,
}


local defaultcanvasSize = 4096 * 2



function DSRender.new(square_width)
   local self
   self = setmetatable({}, DSRender_mt)

   self.map = {}
   self.square_width = square_width


   self.width = self.mapSize * self.square_width
   self.height = self.mapSize * self.square_width




   self.maxcanvassize = defaultcanvasSize
   self.canvas = love.graphics.newCanvas(self.maxcanvassize, self.maxcanvassize)

   return self
end

function DSRender:draw2canvas()
   love.graphics.setCanvas(self.canvas)
   love.graphics.push()

   local sx = self.maxcanvassize / self.width

   love.graphics.scale(sx, sx)
   self.scale = sx
   self:draw(0, 0)
   love.graphics.pop()
   love.graphics.setCanvas()
end


function DSRender:present()











   local dx, dy = 0, 0

   local Canvas = love.graphics.Drawable

   local scale = 1 / self.scale

   love.graphics.draw(self.canvas, dx, dy, 0., scale, scale)
end

function DSRender:draw(x, y)
   x = x or 0
   y = y or 0























end

return DSRender
