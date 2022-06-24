local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table








require('love')
require("common")

local colorize = require('ansicolors2').ansicolors
local yield = coroutine.yield
local gr = love.graphics
local inspect = require("inspect")
local ceil = math.ceil
local get_color = require('height_map').color

local dirname = ""
local mapn
local rng_state


local x_pos, y_pos = 0., 0.


local map = {}
local mapSize = 0
local mapWidthPix



local rez = 64

local canvasSize = 256


assert(canvasSize % rez == 0, "canvasSize % rez == 0")

local font = gr.newFont(64 * 2)
local format = string.format
local Drawer = {}
local drawlist = {}



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

            gr.rectangle(
            "fill",
            x + rez * abs_i,
            y + rez * abs_j,
            rez, rez)

         end
         abs_j = abs_j + 1
      end
      abs_i = abs_i + 1
   end

end

local Node = {}




local canvas_nodes = {}
local loaded_order = {}

local max_loaded_num = 10

local function new_texture(i, j)
   if not canvas_nodes[i][j] then
      if #loaded_order >= max_loaded_num then

         local node = loaded_order[1]
         assert(node.i == i and node.j == node.j, "indexes are equal")
         local obj = canvas_nodes[node.i][node.j]
         obj:release()
         canvas_nodes[node.i][node.j] = nil
         table.remove(loaded_order, 1)
      end
      local path = format(
      "%s/%s_%s.png",
      dirname,
      zerofyNum(i), zerofyNum(j))

      canvas_nodes[i][j] = gr.newImage(path)
      table.insert(loaded_order, { i = i, j = j })
   end
end

local function bake_and_save_canvas(
   i1, i2, j1, j2,
   name)

   gr.setColor({ 1, 1, 1, 1 })
   local canvas = gr.newCanvas(canvasSize, canvasSize)
   gr.setCanvas(canvas)


   sub_draw(i1, i2, j1, j2, -rez, -rez)

   local prevfont = gr.getFont()
   gr.setColor({ 1, 0, 0, 1 })
   gr.setFont(font)

   local ij_str = format("(%d-%d,%d-%d)", i1, i2, j1, j2)

   local x, y = rez, rez
   gr.print(ij_str, x, y)
   y = y + ceil(gr.getFont():getHeight())
   gr.print(name, x, y)
   gr.setFont(prevfont)

   gr.setCanvas()
   local fname = dirname .. "/" .. name .. ".png"
   canvas:newImageData():encode('png', fname)
   local object = canvas
   object:release()
end

local Command = {}






local cmd_circle_buf = {}











local function print_stack()
   print(colorize(
   "%{blue}cmd stack: " ..
   inspect(cmd_circle_buf) ..
   "%{reset}"))

end

local i_poses = {}
local j_poses = {}

local function bake_canvases()
   mapWidthPix = mapSize * rez
   print('mapWidthPix', mapWidthPix)
   local canvasNum = ceil(mapWidthPix / canvasSize)
   print('canvasNum', canvasNum)
   local canvas_w, canvas_h = canvasSize, canvasSize
   local i, j = 1, 1

   print('step_1', ceil(#map / canvasNum))
   local step = ceil(canvasSize / rez)
   print('step', step)




   print('#map', #map)
   print('step', step)
   local num = 0

   for y = 0, canvasNum - 1 do
      j = 1
      for x = 0, canvasNum - 1 do
         num = num + 1

         print("y, x", y, x)
         print('i, j', i, j)


         local uniq_color = { 1, math.random(), math.random(), 1 }
         table.insert(drawlist, function(camx, camy)




            local i_pos = i * rez
            local j_pos = j * rez
            local scrw, scrh = gr.getDimensions()

            local i_visible = i_pos >= camx and i_pos <= camx + scrw
            local j_visible = j_pos >= camy and j_pos <= camy + scrh

            gr.setColor(uniq_color)

            local prevFont = gr.getFont()
            gr.setFont(font)

            if not i_poses[i_pos] then
               i_poses[i_pos] = true
               print('i_pos', i_pos)
            end
            if not j_poses[j_pos] then
               j_poses[j_pos] = true
               print('j_pos', j_pos)
            end

            gr.rectangle(
            'fill',
            i_pos, j_pos,
            canvas_w, canvas_h)


            if i_visible and j_visible then
               gr.setColor({ 0, 0, 0, 1 })
               local str = format("(%d, %d)", i, j)

               gr.print(str, i, j)

               gr.setColor({ 0, 1, 0, 1 })
               gr.circle("fill", 0, 0, 200)

            end

            gr.setFont(prevFont)

         end)



         bake_and_save_canvas(
         i, i + step,
         j, j + step,
         zerofyNum(y + 1) .. "_" .. zerofyNum(x + 1))

         j = j + step
      end
      i = i + step
   end
end

local commands = {}

function commands.set_rez()
   rez = graphic_command_channel:demand()
   return false
end


function commands.map()
   mapn = graphic_command_channel:demand()
   if type(mapn) ~= 'number' then
      error('mapn should be a number, not a ' .. type(mapn))
   end

   rng_state = graphic_command_channel:demand()
   if type(rng_state) ~= 'string' then
      error('rng_state should be a string, not a ' .. type(rng_state))
   end

   dirname = zerofyNum(mapn) .. "_" .. rng_state
   local fname = dirname .. "/map.data.bin"

   print('commands.map: fname', fname)
   local mapFile = love.filesystem.newFile(fname, 'r')
   if mapFile == nil then
      error('mapFile equal nil')
   end

   local struct = require('struct')
   local decompress = love.data.decompress
   local ulong_size = 8
   local content = mapFile:read(ulong_size)

   mapSize = ceil(struct.unpack('L', content))

   map = {}
   for _ = 1, mapSize do
      local row_len_s = mapFile:read(ulong_size)
      local row_len = struct.unpack('L', row_len_s)
      local compressed = mapFile:read(row_len)
      local uncompressed = decompress("string", 'gzip', compressed)

      local ok, errmsg = pcall(function()
         map[#map + 1] = load(uncompressed)()
      end)
      if not ok then
         error('diamondsquare: Could not load map data:' .. errmsg)
      end
   end

   mapFile:close()

   bake_canvases()

   return false
end

function commands.set_position()
   local x = graphic_command_channel:demand()
   local y = graphic_command_channel:demand()
   x_pos, y_pos = x, y
   return false
end


function commands.flush()


   local camx = ceil(graphic_command_channel:demand())
   local camy = ceil(graphic_command_channel:demand())



   local index_i = ceil(camx / canvasSize)
   local index_j = ceil(camy / canvasSize)
   print('index_i, index_j', index_i, index_j)


   local w, h = gr.getDimensions()
   gr.setScissor(0, 0, w, h)

   gr.setColor({ 1, 1, 1, 1 })

   local inrange_i = index_i > 1 and index_i < #map
   local inrange_j = index_j > 1 and index_j < #map

   if inrange_i and inrange_j then















      gr.setColor({ 1, 0, 0, 1 })
      gr.rectangle('line', 0, 0, mapSize * rez, mapSize * rez)
   end






   local msg = format('index_i, index_j: %d, %d', index_i, index_j)
   gr.print(msg, w / 2, h / 2)
   gr.print(msg, camx - w / 2 + w / 2, camy - h / 2 + h / 2)











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
