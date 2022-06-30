local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local math = _tl_compat and _tl_compat.math or math





require('love')
require("common")

local im = require('imgui')
local yield = coroutine.yield
local serpent = require('serpent')

local inspect = require("inspect")
local ceil = math.ceil

local channel = love.thread.getChannel("mapgen_ui")

local Settings = {}



local settings = {
   mapSize = 5,
}
channel:clear()
channel:push(serpent.dump(settings))

local Command = {}



local commands = {}

function commands.flush()

   im.NewFrame()
   local ok
   local mapSize
   mapSize, ok = im.SliderInt('map size', mapSize, 0, 12)
   im.Render()
   print('mapSize, ok', mapSize, ok)
   settings.mapSize = ceil(mapSize)

   channel:clear()
   channel:push(serpent.dump(settings))

   return false
end

while true do
   local cmd

   repeat
      cmd = graphic_command_channel:demand()

      local fun = commands[cmd]
      if not fun then

         error('mapgen_ui unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd

   yield()
end
