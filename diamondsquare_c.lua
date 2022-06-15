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














   local fname = "map.data." .. randomFilenameStr() .. ".txt"
   local uncompressed = serpent.dump(map)
   print('#uncompressed', size2human(#uncompressed))
   local compress = love.data.compress
   local compressed = compress('string', 'gzip', uncompressed, 9)
   print('#compressed', size2human(#compressed))

   local struct = require('struct')
   local packed = struct.pack("L", self.generator:get_mapsize())
   love.filesystem.write(fname, "", 0)
   love.filesystem.append(fname, packed, #packed)
   love.filesystem.append(fname, compressed, #compressed)







   self.pipeline:openPushAndClose(
   self.renderobj_name, 'map', fname)


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
