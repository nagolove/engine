local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall






require('love')

 DiamonAndSquare = {State = {}, }













































local DiamonAndSquare_mt = {
   __index = DiamonAndSquare,
}

local serpent = require('serpent')

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

function DiamonAndSquare:serialize()
   local state = {
      mapSize = self.mapSize,
      map = self.map,
   }
   return serpent.dump(state)
end

function DiamonAndSquare:save(fname)
   local succ, msg = love.filesystem.write(fname, self:serialize())
   if not succ then
      error('Could not save DiamonAndSquare to ' .. fname .. ': ' .. msg)
   end
end


function DiamonAndSquare:eval()
   local coro = coroutine.create(function()
      local stop = false
      repeat
         self:square()
         coroutine.yield()
         stop = self:diamond()
      until stop
      self:normalizeInplace()
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

function DiamonAndSquare.new(mapn, rng)
   if type(mapn) ~= 'number' then
      error('No mapn parameter in constructor.')
   end
   local self
   self = setmetatable({}, DiamonAndSquare_mt)

   self.map = {}
   self.mapSize = math.ceil(2 ^ mapn) + 1

   self.chunkSize = self.mapSize - 1
   self.roughness = 2
   self.rng = rng

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

      local value = self.rng:random()

      value = 0.5 - 0.5 * math.cos(value * math.pi)
      self.map[i] = self.map[i] or {}
      self.map[i][j] = value
   end

   return self
end

local floor = math.floor

function DiamonAndSquare:value(i, j)
   if self.map[floor(i)] and self.map[floor(i)][floor(j)] then
      return self.map[floor(i)][floor(j)]
   end
end

function DiamonAndSquare:random(min, max)

   local r = 4 * (self.rng:random() - 0.5) ^ 3 + 0.5

   local result = min + r * (max - min)

   return result
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
   local value = 0.
   local n = 0
   local min, max
   local corners = {
      { i = i, j = j - half },
      { i = i + half, j = j },
      { i = i, j = j + half },
      { i = i - half, j = j },
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

function DiamonAndSquare:diamond()
   local half = self.chunkSize / 2
   local ceil = math.ceil

   for i = 1, self.mapSize, half do

      for j = (i + half) % self.chunkSize, self.mapSize, self.chunkSize do


         local _, min, max = self:diamondValue(i, j, half)
         self.map[ceil(i)] = self.map[ceil(i)] or {}
         self.map[ceil(i)][ceil(j)] = self:random(min, max)

      end
   end

   self.chunkSize = ceil(self.chunkSize / 2)
   self.roughness = ceil(self.roughness / 2)
   return self.chunkSize <= 1
end













return DiamonAndSquare
