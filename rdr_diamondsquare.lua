local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local table = _tl_compat and _tl_compat.table or table


require('love')

local colorize = require('ansicolors2').ansicolors
local yield = coroutine.yield
local gr = love.graphics
local inspect = require("inspect")
local ceil = math.ceil
local get_color = require('height_map').color




local map = {}

local mapSize = 0



local rez = 32

local x_pos, y_pos = 0., 0.



local function sub_draw(
   i1, i2, j1, j2,
   dx,
   dy)

   local x = dx or 0
   local y = dy or 0

   local abs_i_init, abs_j_init = 1, 1



   local abs_i, abs_j = abs_i_init, abs_j_init

   for i = i1, i2 do
      abs_j = abs_j_init
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

local function crazy_test()
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

local CanvasNode = {}








local canvas_nodes = {}

local function newCanvasNode(i1, i2, j1, j2)
   local w, h = rez * ceil(mapSize / 2), rez * ceil(mapSize / 2)
   table.insert(canvas_nodes, {
      canvas = gr.newCanvas(w, h),
      i1 = i1,
      i2 = i2,
      j1 = j1,
      j2 = j2,
   })
end

local function bake()
   gr.setColor({ 1, 1, 1, 1 })
   for _, node in ipairs(canvas_nodes) do
      gr.setCanvas(node.canvas)
      sub_draw(node.i1, node.i2, node.j1, node.j2, -rez, -rez)
      gr.setCanvas()
   end
end

local function draw_bakes()
   gr.setColor({ 1, 1, 1, 1 })
   for _, node in ipairs(canvas_nodes) do
      local x, y = x_pos + node.i1 * rez, y_pos + node.j1 * rez
      gr.draw(node.canvas, x, y)
   end
end




local function save_bakes()
   for k, node in ipairs(canvas_nodes) do
      node.canvas:newImageData():encode('png', "map" .. tostring(k) .. ".png")
   end
end

local Command = {}






local cmd_circle_buf = {}
local cmd_circle_buf_maxnum = 16 * 2

local function push_cbuf(cmd)
   if #cmd_circle_buf >= cmd_circle_buf_maxnum then
      table.remove(cmd_circle_buf, 1)
   end
   table.insert(cmd_circle_buf, cmd)
end

local function print_stack()
   print(colorize(
   "%{blue}cmd stack: " ..
   inspect(cmd_circle_buf) ..
   "%{reset}"))

end

local commands = {}

function commands.set_rez()
   rez = graphic_command_channel:demand()
   return false
end


function commands.map()
   canvas_nodes = {}

   local fname = graphic_command_channel:demand()
   print('commands.map: fname', fname)
   local mapFile = love.filesystem.newFile(fname, 'r')
   print('mapFile', mapFile)
   local struct = require('struct')

   local decompress = love.data.decompress
   local ulong_size = 8
   local content = mapFile:read(ulong_size)
   print('content', content)
   print('#content', #content)
   mapSize = math.ceil(struct.unpack('L', content))
   print('mapSize', mapSize)

   map = {}
   for i = 1, mapSize do
      local row_len_s = mapFile:read(ulong_size)
      local row_len = struct.unpack('L', row_len_s)
      local compressed = mapFile:read(row_len)
      local uncompressed = decompress("string", 'gzip', compressed)

      local ok, errmsg = pcall(function()
         map[#map + 1] = load(uncompressed)()
      end)
      if not ok then
         error('diamondsquare: Could not load map data.')
      end
   end

   mapFile:close()







   local maxCanvasSize = 1024
   local mapWidth = mapSize * rez
   local canvasNum = math.ceil(mapWidth / maxCanvasSize)

   newCanvasNode(1, ceil(mapSize / 2), 1, ceil(mapSize / 2))
   newCanvasNode(1, ceil(mapSize / 2), ceil(mapSize / 2), mapSize)
   newCanvasNode(ceil(mapSize / 2), mapSize, ceil(mapSize / 2), mapSize)
   newCanvasNode(ceil(mapSize / 2), mapSize, 1, ceil(mapSize / 2))



   bake()
   save_bakes()
   return false
end

function commands.set_position()
   local x = graphic_command_channel:demand()
   local y = graphic_command_channel:demand()
   x_pos, y_pos = x, y
   return false
end


function commands.flush()





   draw_bakes()

   gr.setColor({ 1, 0, 0, 1 })
   gr.rectangle('line', 0, 0, mapSize * rez, mapSize * rez)
   return false
end


local cmd_num = 0

while true do
   local cmd

   repeat
      cmd = graphic_command_channel:demand()


      local fun = commands[cmd]
      if not fun then
         print_stack()
         error('diamonandsquare unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

      cmd_num = cmd_num + 1
   until not cmd

   yield()
end
