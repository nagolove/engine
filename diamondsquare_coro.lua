local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall






require('love')
local Pipeline = require('pipeline')
























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
   self.renderobj_name, 'map', self.mapSize, compressed)

end

function DiamonAndSquare:load(fname)
   local data, size = love.filesystem.read(fname)
   if data then
      local f
      local ok, errmsg = pcall(function()
         f = load(data)()
      end)
      if not ok then
         local msg_part = fname .. ': ' .. errmsg
         print('Could not load DiamonAndSquare from ' .. msg_part)
      end
      self.mapSize = f.mapSize
      self.map = f.map
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


         self:send2render()
         coroutine.yield()
         stop = self:diamond()
         coroutine.yield()

      until stop
      self:normalizeInplace()
   end)







end


function DiamonAndSquare:eval()



















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
      print('i', i)
   end
   if (j - floor(j) > 0.) then
      print('j', j)
   end
   if self.map[floor(i)] and self.map[floor(i)][floor(j)] then
      return self.map[floor(i)][floor(j)]
   else

   end
end

function DiamonAndSquare:random(min, max)

   local r = 4 * (self.rng() - 0.5) ^ 3 + 0.5

   local result = min + r * (max - min)


   if love.keyboard.isDown('l') then
      return result
   else
      return min + self.rng() * (max - min)
   end
end

function DiamonAndSquare:squareValue(i, j, _)
   local value = 0.
   local n = 0
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
         value = value + v
         n = n + 1
      end
   end
   return value / n, min, max
end


function DiamonAndSquare:square()
   print('square')
   local half = math.floor(self.chunkSize / 2)
   for i = 1, self.mapSize - 1, self.chunkSize do
      for j = 1, self.mapSize - 1, self.chunkSize do
         local _, min, max = self:squareValue(i, j, half)
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
         print('i: ' .. i .. ' j:' .. j)

         local min, max = self:diamondValue(i, j, half)
         print('min, max', min, max)
         self.map[ceil(i)] = self.map[ceil(i)] or {}
         self.map[ceil(i)][ceil(j)] = self:random(min, max)

      end
   end

   self.chunkSize = ceil(self.chunkSize / 2)

   return self.chunkSize <= 1
end













return DiamonAndSquare
