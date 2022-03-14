local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall
local yield = coroutine.yield
local gr = love.graphics
local inspect = require("inspect")
local get_color = require('height_map').color
local map = {}

local mapSize = 0

local rez = 32

local function sub_draw(i1, i2, j1, j2)
   local x = 0
   local y = 0










   local abs_i, abs_j = i1, j1

   for i = i1, i2 do
      abs_j = j1
      for j = j1, j2 do
         local c = map[i] and map[i][j] or nil
         if c then
            local color = get_color(c ^ 2)


            gr.setColor(color)

            gr.rectangle("fill", x + rez * abs_i, y + rez * abs_j, rez, rez)










         end
         abs_j = abs_j + 1
      end
      abs_i = abs_i + 1
   end
end

local function flush()


   local ceil = math.ceil

   local r = math.random()
   if r < 1 / 4 then
      sub_draw(1, ceil(mapSize / 2), 1, ceil(mapSize / 2))
   elseif r > 1 / 4 and r < 1 / 4 * 2 then
      sub_draw(1, ceil(mapSize / 2), ceil(mapSize / 2), mapSize)
   elseif r > 1 / 4 * 2 and r < 1 / 4 * 3 then
      sub_draw(ceil(mapSize / 2), mapSize, ceil(mapSize / 2), mapSize)
   else
      sub_draw(ceil(mapSize / 2), mapSize, 1, ceil(mapSize / 2))
   end



end

local function read_map()
   mapSize = graphic_command_channel:demand()
   if type(mapSize) ~= 'number' then
      error('diamondsquare: mapSize should be an integer value.')
   end

   local compressed = graphic_command_channel:demand()
   if type(compressed) ~= 'string' then
      error('diamondsquare: map data should be a string value.')
   end

   local decompress = love.data.decompress

   local uncompressed = decompress("string", 'gzip', compressed)


   local ok, errmsg = pcall(function()
      map = load(uncompressed)()

   end)
   if not ok then
      error('diamondsquare: Could not load map data.')
   end
end

while true do
   local cmd

   repeat
      cmd = graphic_command_channel:demand()


      if cmd == "map" then
         read_map()
         break

      elseif cmd == 'flush' then
         flush()
         break
      else
         error('diamondsquare unkonwn command: ' .. cmd)
      end

   until not cmd

   yield()
end
