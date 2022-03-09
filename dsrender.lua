local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine

local yield = coroutine.yield
local gr = love.graphics
local serpent = require('serpent')
local color = require('height_map').color

local map = {}
local square_width = 32
local mapSize = 0

local function new(data)
   local ok, t = serpent.load(data)
   if not ok then
      error('Could not load data to dsrender')
   end
   mapSize = #map
   return t
end

local function render()
   local x, y = 0, 0
   for i = 1, mapSize do
      for j = 1, mapSize do
         local c = map[i] and map[i][j] or nil
         if c then
            gr.setColor(color(c ^ 2))
            gr.rectangle("fill",
            x + square_width * i, y + square_width * j,
            square_width, square_width)









         end
      end
   end
end

while true do
   local cmd





   repeat
      cmd = graphic_command_channel:demand()

      if cmd == "new" then
         map = new(graphic_command_channel:demand())
      elseif cmd == "render" then
         render()
      else
         error('dsrender unkonwn command: ' .. cmd)
      end
   until not cmd

   yield()
end
