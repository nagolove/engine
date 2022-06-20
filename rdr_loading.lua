local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math




local gr = love.graphics
local yield = coroutine.yield
local colorize = require('ansicolors2').ansicolors

local fontName = "/DejaVuSansMono.ttf"

local fontSize = 110

local font = gr.newFont(SCENE_PREFIX .. fontName, fontSize)
if not font then
   error("Could not load font '" .. fontName .. "'")
end

local color = { 0.9, 0, 0, 1 }
local message = "Карта создается"
local barLength = 20
local bar = ""

local Command = {}




local commands = {}


function commands.progress()
   local v = graphic_command_channel:demand()
   if v > 1. or v < 0. then
      error('Progress value should ve in 0..1 range.')
   end
   bar = makeProgressBar(barLength, v)
end

function commands.flush()
   local x, y = 0., 0.
   local prevFont = gr.getFont()
   local prevColor = { gr.getColor() }

   gr.setFont(font)
   gr.setColor(color)



   local list = boxifyTextParagraph(
   {
      message,
      bar,
   },
   'center')








   local scrW, scrH = gr.getDimensions()
   y = math.ceil((scrH - #list * font:getHeight()) / 2)

   for k, line in ipairs(list) do
      gr.print(line, x, y)
      y = y + gr.getFont():getHeight()
   end

   gr.setFont(prevFont)
   gr.setColor(prevColor)
   return false
end

while true do
   local cmd


   local oldfont = gr.getFont()
   repeat
      cmd = graphic_command_channel:demand()

      local fun = commands[cmd]
      if not fun then
         error('lines_buf unkonwn command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd
   gr.setFont(oldfont)

   yield()
end
