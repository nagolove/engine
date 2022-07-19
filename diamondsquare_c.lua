local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os






require('love')
local Pipeline = require('pipeline')



local das = require("diamond_and_square")
























require('diamondsquare_common')

DiamonAndSquare_draw_tiles = 1
DiamonAndSquare_invert_tiles_draw_order = 2





local DiamonAndSquare = {State = {}, }











































































local DiamonAndSquare_mt = {
   __index = DiamonAndSquare,
}



function DiamonAndSquare:doneAsync()
   local gen_status_channel = love.thread.getChannel("gen_status_channel")
   local finished = gen_status_channel:pop()

   if self.thread and self.thread:getError() then
      print('generator_thread.tl crashed with', self.thread:getError())
   end

   if finished then
      if type(finished) ~= 'boolean' then
         error('"finished" shoul be a boolean, not a ' .. type(finished))
      end

      print('self.finished', self.finished)
      self.finished = true
      self:send2render()
   end
   return self.finished ~= nil
end

function DiamonAndSquare:setPosition(x, y)
   self.pipeline:openPushAndClose(self.renderobj_name, 'set_position', x, y)
end

function DiamonAndSquare:render(x, y)
   self.pipeline:openPushAndClose(
   self.renderobj_name,
   'flush',
   x, y,
   self.bitmask)

end

function DiamonAndSquare:send2render()
   print('DiamonAndSquare:send2render()')
   print('self.mapn, self.rngState', self.mapn, self.rngState)

   self.pipeline:openPushAndClose(

   self.renderobj_name, 'map', self.mapn, self.rngState)

end

function DiamonAndSquare:evalAsync()
   assert(self.rngState)

   self.thread = love.thread.newThread("generator_thread.lua")

   local rngState = self.rngState
   if not rngState then
      print('Using default(random) rngState')
      local rng = love.math.newRandomGenerator(os.time())
      rngState = rng:getState()
   end

   self.thread:start(self.mapn, rngState)
end


function DiamonAndSquare:eval()





end

function DiamonAndSquare.new(
   mapn,

   pl)


   if type(mapn) ~= 'number' then
      error('No mapn parameter in constructor.')
   end
   local self
   self = setmetatable({}, DiamonAndSquare_mt)

   assert(pl, "pipeline is nil")
   self.pipeline = pl
   print('renderobj_counter', renderobj_counter)
   renderobj_counter = renderobj_counter + 1
   self.renderobj_name = "diamondsquare" .. renderobj_counter
   self.rez = 8

   self.pipeline:pushCodeFromFileRoot(
   self.renderobj_name, 'rdr_diamondsquare.lua')


   self.bitmask = 0
   self.mapn = mapn


   self.mapSize = math.ceil(math.pow(2, mapn) + 1)

   return self
end

function DiamonAndSquare:getFieldSize()
   return self.rez * self.mapSize
end

function DiamonAndSquare:setRez(rez)
   self.rez = rez
   self.pipeline:openPushAndClose(
   self.renderobj_name,
   'set_rez', self.rez)

end

function DiamonAndSquare:setViewport(   x, y, w, h)

   self.pipeline:openPushAndClose(
   self.renderobj_name, 'set_view_port', x, y, w, h)

end

return DiamonAndSquare
