local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local load = _tl_compat and _tl_compat.load or load; local pcall = _tl_compat and _tl_compat.pcall or pcall
local yield = coroutine.yield
local gr = love.graphics
local inspect = require("inspect")
local color = require('height_map').color
local map = {}

local mapSize = 0

local rez = 32

local function draw()
   local x = 0
   local y = 0

   print('diamondsquare')
   print('draw')
   print('mapSize', mapSize)
   print('#map, #map[1]', #map, #map[1])

   for i = 1, mapSize do
      for j = 1, mapSize do
         local c = map[i] and map[i][j] or nil
         if c then
            gr.setColor(color(c ^ 2))
            gr.rectangle("fill", x + rez * i, y + rez * j, rez, rez)










         end
      end
   end
end

local function flush()
   draw()
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
   local s = 'wefefwe'

   local uncompressed = decompress("string", 'gzip', s)
   if not uncompressed then
      error('diamondsquare: could not decompress map data.')
   end

   local ok, errmsg = pcall(function()

      map = load(uncompressed)
      print('map', inspect(map))
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
