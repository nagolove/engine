local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local math = _tl_compat and _tl_compat.math or math






require('love')
local Pipeline = require('pipeline')

local inspect = require("inspect")
local das = require("diamond_and_square")
























require('diamondsquare_common')

local DiamonAndSquare = {State = {}, }

























































local DiamonAndSquare_mt = {
   __index = DiamonAndSquare,
}

local serpent = require('serpent')

function DiamonAndSquare:setPosition(x, y)
   self.pipeline:openPushAndClose(self.renderobj_name, 'set_position', x, y)
end

function DiamonAndSquare:render()
   self.pipeline:openPushAndClose(self.renderobj_name, 'flush')
end

function DiamonAndSquare:send2render()
   local map = {}
   for i = 1, self.generator:get_mapsize() do
      map[#map + 1] = {}
      for j = 1, self.generator:get_mapsize() do
         map[#map][j] = self.generator:get(i - 1, j - 1)
      end
   end


   print('------------------- map ------------------- ')
   for i = 1, #map do
      print("i = ", i, inspect(map[i]))
      print()
   end
   print('------------------- map ------------------- ')


   local uncompressed = serpent.dump(map)
   local compress = love.data.compress
   local compressed = compress('string', 'gzip', uncompressed, 9)
   print('#compressed', #compressed)
   self.pipeline:openPushAndClose(
   self.renderobj_name, 'map', self.generator:get_mapsize(), compressed)

end


function DiamonAndSquare:eval()
   print('self.generator', self.generator, type(self.generator))
   self.generator:eval()
   return self
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
   self.mapn = 0
   print('renderobj_counter', renderobj_counter)
   renderobj_counter = renderobj_counter + 1
   self.renderobj_name = "diamondsquare" .. renderobj_counter
   self.mapSize = math.ceil(2 ^ self.mapn) + 1
   self.rez = 8

   self.pipeline:pushCodeFromFileRoot(

   self.renderobj_name, 'rdr_diamondsquare.lua')


   self.generator = das.new(mapn, rng)







   return self
end

function DiamonAndSquare:reset()

end

function DiamonAndSquare:getFieldSize()
   return self.rez * self.mapSize
end

function DiamonAndSquare:setRez(rez)
   self.pipeline:openPushAndClose(
   self.renderobj_name,
   'set_rez', self.rez)

end

return DiamonAndSquare
