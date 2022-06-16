local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert






require('love')
local Pipeline = require('pipeline')



local das = require("diamond_and_square")
























require('diamondsquare_common')

local DiamonAndSquare = {State = {}, }
































































local DiamonAndSquare_mt = {
   __index = DiamonAndSquare,
}

local serpent = require('serpent')

function DiamonAndSquare:doneAsync()
   return self.done
end

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

   local compress = love.data.compress
   local struct = require('struct')
   local packed_mapsize = struct.pack("L", self.generator:get_mapsize())

   love.filesystem.write(fname, "", 0)
   love.filesystem.append(fname, packed_mapsize, #packed_mapsize)

   print('map', #map)
   print('mapSize', self.mapSize)
   local packed_mapsize = struct.pack("L", self.generator:get_mapsize())

   for i = 1, #map do
      local row = map[i]
      local uncompressed = serpent.dump(row)
      local compressed = compress('string', 'gzip', uncompressed, 9)





      local packed_rowlen = struct.pack("L", #compressed)
      love.filesystem.append(fname, packed_rowlen, #packed_rowlen)
      love.filesystem.append(fname, compressed, #compressed)
   end



   self.pipeline:openPushAndClose(
   self.renderobj_name, 'map', fname)


end

function DiamonAndSquare:evalAsync()
   print('self.generator', self.generator, type(self.generator))
   self.done = false
   self.generator:eval()
end


function DiamonAndSquare:eval()
   print('self.generator', self.generator, type(self.generator))
   self.generator:eval()
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


   self.done = true
   self.generator = das.new(mapn, rng)
   self.mapSize = self.generator:get_mapsize()







   return self
end

function DiamonAndSquare:reset()


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
