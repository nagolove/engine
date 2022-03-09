local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert


require('love')
require('diamondsquare')
require('pipeline')

local serpent = require('serpent')
local RandomGenerator = love.math.RandomGenerator
local color = require('height_map').color


 DSRender = {}


























local DSRender_mt = {
   __index = DSRender,
}


local defaultcanvasSize = 4096 * 2



function DSRender.new(square_width, ds, pl)
   local self
   self = setmetatable({}, DSRender_mt)


   self.square_width = square_width
   self.pipeline = pl

   assert(pl, "Invalid pipeline object")











   self.pipeline:pushCodeFromFileRoot("dsrender", 'dsrender.lua')

   return self
end

function DSRender:draw2canvas()










end


function DSRender:present()


















end

function DSRender:draw(x, y)
   x = x or 0
   y = y or 0
   self.pipeline:openPushAndClose('dsrender', 'render')
end

return DSRender
