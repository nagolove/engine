local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine



local gr = love.graphics
local yield = coroutine.yield
local serpent = require('serpent')

local Command = {}




local Label = {}





local labels = {}

local commands = {}

function commands.flush()
   return false
end

function commands.get_values()
   return false
end

while true do
   local cmd

   local oldfont = gr.getFont()
   repeat
      cmd = graphic_command_channel:demand()

      local fun = commands[cmd]
      if not fun then
         error('labels unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd
   gr.setFont(oldfont)

   yield()
end
