local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local io = _tl_compat and _tl_compat.io or io; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string





























require('love')

local Pipeline = require('pipeline')
local format = string.format
local inspect = require("inspect")

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
   local uncompressed = serpent.dump(self.map)
   local compress = love.data.compress
   local compressed = compress('string', 'gzip', uncompressed, 9)
   print('#compressed', #compressed)

   self.pipeline:openPushAndClose(
   self.renderobj_name,
   'map', self.mapSize, compressed)

   self.pipeline:openPushAndClose(
   self.renderobj_name,
   'set_rez', self.rez)


end

function DiamonAndSquare:setRez(rez)
   self.rez = rez
   self.pipeline:openPushAndClose(
   self.renderobj_name,
   'set_rez', self.rez)

end

function DiamonAndSquare:load(fname)
   local data, size = love.filesystem.read(fname)
   if data then
      local func
      local ok, errmsg = pcall(function()
         func = load(data)()
      end)
      if not ok then
         local msg_part = fname .. ': ' .. errmsg
         print('Could not load DiamonAndSquare from ' .. msg_part)
      end
      self.mapSize = func.mapSize
      self.map = func.map
   else
      local msg_part = fname .. ': ' .. tostring(size)
      error('Could not load DiamonAndSquare from ' .. msg_part)
   end
end











function DiamonAndSquare:save(_)





end

function DiamonAndSquare:newCoroutine()
   return coroutine.create(function()
      local stop = false
      repeat
         self:square()

         coroutine.yield()
         stop = self:diamond()
         coroutine.yield()

      until stop

   end)







end


function DiamonAndSquare:eval()

   local filenum = 0
   print('------------------------------------------------------------')
   self:printMap2File(filenum)
   filenum = filenum + 1
   print('------------------------------------------------------------')

   local coro = coroutine.create(function()
      local stop = false
      repeat
         self:square()


         self:printMap2File(filenum)
         filenum = filenum + 1



         coroutine.yield()
         stop = self:diamond()









         self:printMap2File(filenum)
         filenum = filenum + 1


      until stop
      self:normalizeInplace()


      self:printMap2File(filenum)
      filenum = filenum + 1


   end)

   local ok
   ok = coroutine.resume(coro)
   while ok do
      ok = coroutine.resume(coro)
   end


   return self
end

function DiamonAndSquare:normalizeInplace()
   for i = 1, self.mapSize do
      for j = 1, self.mapSize do
         local c = self.map[i] and self.map[i][j] or nil
         if c then
            if c > 1 then
               self.map[i][j] = 1
            elseif c < 0 then
               self.map[i][j] = 0
            end
         end
      end
   end
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

   self.renderobj_name = "diamondsquare" .. renderobj_counter
   renderobj_counter = renderobj_counter + 1
   self.pipeline:pushCodeFromFileRoot(

   self.renderobj_name, 'rdr_diamondsquare.lua')


   self.rng = rng
   self.mapn = mapn
   self:reset()
   self.rez = 8

   return self
end

function DiamonAndSquare:reset()
   self.map = {}
   self.mapSize = math.ceil(2 ^ self.mapn) + 1

   self.chunkSize = self.mapSize - 1


   local corners = {
      {
         i = 1,
         j = 1,
      },
      {
         i = self.mapSize,
         j = 1,
      },
      {
         i = self.mapSize,
         j = self.mapSize,
      },
      {
         i = 1,
         j = self.mapSize,
      },
   }

   for _, corner in ipairs(corners) do
      local i, j = corner.i, corner.j

      local value = self.rng()

      value = 0.5 - 0.5 * math.cos(value * math.pi)
      self.map[i] = self.map[i] or {}
      self.map[i][j] = value
   end
end


local floor = math.floor

function DiamonAndSquare:value(i, j)


   if (i - floor(i) > 0.) then

   end
   if (j - floor(j) > 0.) then

   end
   if self.map[floor(i)] and self.map[floor(i)][floor(j)] then
      return self.map[floor(i)][floor(j)]
   else

      print(format("value is NULL for [%d, %d]", i, j));
   end
end

function DiamonAndSquare:random(min, max)















   return min + self.rng() * (max - min)
end

function DiamonAndSquare:squareValue(i, j)
   local min, max


   local corners = {
      { i = i, j = j },
      { i = i + self.chunkSize, j = j },
      { i = i, j = j + self.chunkSize },
      { i = i + self.chunkSize, j = j + self.chunkSize },
   }

   for _, corner in ipairs(corners) do
      local v = self:value(corner.i, corner.j)
      if v then



         min = min and math.min(min, v) or v
         max = max and math.max(max, v) or v
      end
   end
   return min, max
end


function DiamonAndSquare:square()
   print('square')
   local half = math.floor(self.chunkSize / 2)
   for i = 1, self.mapSize - 1, self.chunkSize do
      for j = 1, self.mapSize - 1, self.chunkSize do
         local min, max = self:squareValue(i, j)
         self.map[i + half] = self.map[i + half] or {}
         self.map[i + half][j + half] = self:random(min, max)
      end
   end
end

function DiamonAndSquare:diamondValue(i, j, half)
   local min, max = 1000., -1000.


   local corners = {
      { i = i, j = j - half },
      { i = i + half, j = j },
      { i = i, j = j + half },
      { i = i - half, j = j },
   }


   for _, corner in ipairs(corners) do
      local v = self:value(corner.i, corner.j)
      if v then


         min = math.min(min, v)
         max = math.max(max, v)
      end
   end
   return min, max
end

function DiamonAndSquare:diamond()
   print('--------------------- diamond ---------------------')
   local half = self.chunkSize / 2
   print('half', half)
   local ceil = math.ceil

   for i = 1, self.mapSize, half do
      for j = (i + half) % self.chunkSize, self.mapSize, self.chunkSize do


         local min, max = self:diamondValue(i, j, half)

         self.map[ceil(i)] = self.map[ceil(i)] or {}
         self.map[ceil(i)][ceil(j)] = self:random(min, max)

      end
   end

   self.chunkSize = ceil(self.chunkSize / 2)

   return self.chunkSize <= 1
end

function DiamonAndSquare:getFieldSize()
   return self.rez * self.mapSize
end

function DiamonAndSquare:printMap2File(filenum)
   assert(type(filenum) == 'number' and filenum >= 0)

   local file = io.open(string.format('map.lua.%d.txt', filenum), "w+")

   for _, v in ipairs(self.map) do


      local str = inspect(v)
      file:write(str .. '\n')
   end
   file:close()
end













return DiamonAndSquare
