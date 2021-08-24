local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math






require('love')

 DiamonAndSquare = {}






















local DiamonAndSquare_mt = {
   __index = DiamonAndSquare,
}

function DiamonAndSquare:eval()
   local coro = coroutine.create(function()
      local stop = false
      repeat
         self:square()
         coroutine.yield()
         stop = self:diamond()
      until stop
   end)

   local ok
   ok = coroutine.resume(coro)
   while ok do
      ok = coroutine.resume(coro)
   end

end

function DiamonAndSquare.new(map_n)
   local self
   self = setmetatable({}, DiamonAndSquare_mt)

   self.map = {}

   self.mapSize = math.ceil(2 ^ map_n) + 1
   self.chunkSize = self.mapSize - 1
   self.roughness = 2

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

      local value = math.random()

      value = 0.5 - 0.5 * math.cos(value * math.pi)
      self.map[i] = self.map[i] or {}
      self.map[i][j] = value
   end

   return self
end

local colors = {
   { 24 / 255, 81 / 255, 129 / 255 },
   { 32 / 255, 97 / 255, 157 / 255 },
   { 35 / 255, 113 / 255, 179 / 255 },
   { 40 / 255, 128 / 255, 206 / 255 },
   { 60 / 255, 130 / 255, 70 / 255 },
   { 72 / 255, 149 / 255, 81 / 255 },
   { 88 / 255, 164 / 255, 97 / 255 },
   { 110 / 255, 176 / 255, 120 / 255 },
   { 84 / 255, 69 / 255, 52 / 255 },
   { 102 / 255, 85 / 255, 66 / 255 },
   { 120 / 255, 100 / 255, 73 / 255 },
   { 140 / 255, 117 / 255, 86 / 255 },
   { 207 / 255, 207 / 255, 207 / 255 },
   { 223 / 255, 223 / 255, 223 / 255 },
   { 239 / 255, 239 / 255, 239 / 255 },
   { 255 / 255, 255 / 255, 255 / 255 },
}

local function interpolate_color(a, b, t)
   local c = {}
   for i = 1, #a do
      c[i] = a[i] + t * (b[i] - a[i])
   end
   return c
end

local function get_color(value)
   local n = #colors + 2

   if value <= 1 / n then
      return colors[1]
   end
   for i = 2, #colors do
      if value <= i / n then
         local t = (value - ((i - 1) / n)) / (1 / n)
         return interpolate_color(colors[i - 1], colors[i], t)
      end
   end

   return colors[#colors]
end









function DiamonAndSquare:value(i, j)
   local floor = math.floor
   if self.map[floor(i)] and self.map[floor(i)][floor(j)] then
      return self.map[floor(i)][floor(j)]
   end
end

function DiamonAndSquare:random(min, max)
   local r = 4 * (math.random() - 0.5) ^ 3 + 0.5

   return min + r * (max - min)
end

function DiamonAndSquare:squareValue(i, j, _)
   local value = 0.
   local n = 0
   local min, max
   for _, corner in ipairs({ { i = i, j = j }, { i = i + self.chunkSize, j = j }, { i = i, j = j + self.chunkSize }, { i = i + self.chunkSize, j = j + self.chunkSize } }) do
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
   for _, corner in ipairs({ { i = i, j = j - half }, { i = i + half, j = j }, { i = i, j = j + half }, { i = i - half, j = j } }) do
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


















local function power(value)
   local n = -1
   while value > 1 do
      n = n + 1
      value = value / 2
   end
   return n
end

local map_n = 4

function DiamonAndSquare:draw()
   love.graphics.setColor(1, 1, 1)
   love.graphics.print(tostring(self.chunkSize), 0, 0)
   love.graphics.print(tostring(self.mapn), 0, 20)

   local height = love.graphics.getHeight()
   local rez = height / (self.mapSize + 2)

   rez = 2 ^ power(rez)
   if rez < 1 then rez = 1 end

   for i = 1, self.mapSize do
      for j = 1, self.mapSize do
         local c = self.map[i] and self.map[i][j] or nil
         if c then

            if c > 1 then
               c = 1
            elseif c < 0 then
               c = 0
            end

            love.graphics.setColor(get_color(c ^ 2))

            if rez > 1 then
               love.graphics.rectangle("fill", rez * i, rez * j, rez, rez)
            else
               love.graphics.points(i, j)
            end


            if map_n < 5 then
               if c < 0.75 then
                  love.graphics.setColor(1, 1, 1)
               else
                  love.graphics.setColor(0, 0, 0)
               end
               love.graphics.print(tostring(math.floor(c * 100)), rez * i, rez * j)
            end
         end
      end
   end
end

return DiamonAndSquare
