local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local os = _tl_compat and _tl_compat.os or os






require('love')
local Pipeline = require('pipeline')



local das = require("diamond_and_square")
























require('diamondsquare_common')

local DiamonAndSquare = {State = {}, }


































































local DiamonAndSquare_mt = {
   __index = DiamonAndSquare,
}



function DiamonAndSquare:doneAsync()
   local gen_status_channel = love.thread.getChannel("gen_status_channel")
   local fname = gen_status_channel:pop()
   if fname then
      self.fname = fname
      print('self.fname', self.fname)
   end
   return self.fname ~= nil
end

function DiamonAndSquare:setPosition(x, y)
   self.pipeline:openPushAndClose(self.renderobj_name, 'set_position', x, y)
end

function DiamonAndSquare:render()
   self.pipeline:openPushAndClose(self.renderobj_name, 'flush')
end

function DiamonAndSquare:send2render()



































   if self.fname then

      self.pipeline:openPushAndClose(
      self.renderobj_name, 'map', self.fname)

   end

end

function DiamonAndSquare:evalAsync()
   assert(self.rngState)

   self.fname = nil
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
   print('self.generator', self.generator, type(self.generator))
   local tstart = love.timer.getTime()
   self.generator:eval()
   local tfinish = love.timer.getTime()
   print('map generated for', (tfinish - tstart) * 1000., "sec.")
end

function DiamonAndSquare.new(
   mapn,
   rng,
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


   self.mapn = mapn
   self.generator = das.new(mapn, rng)
   self.mapSize = self.generator:get_mapsize()

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

return DiamonAndSquare
