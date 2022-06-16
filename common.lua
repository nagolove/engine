local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


require("love")
local TCamera = require("camera")



 SceneType = {}




 Scene = {}






















 SceneMap = {}





 Tool = {}











function trim_str(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end


function colprint(str)
   if type(str) ~= 'string' then
      error(string.format('Runtime type mismatch. %s instead of string', type(str)))
   end
   local ansicolors = require("ansicolors2").ansicolors
   print(ansicolors("%{blue cyanbg}" .. string.rep('>', 10) .. str))
end



function separateByZeros(arr)
   local tmp = ""
   for _, v in ipairs(arr) do
      tmp = tmp .. v .. "\0"
   end
   return tmp, #arr
end


function shallowCopy(t)
   if type(t) == "table" then
      local copy = {}
      for k, v in pairs(t) do
         copy[k] = v
      end
      return copy
   elseif type(t) == "string" then
      return t
   elseif type(t) == "number" then
      return t
   elseif type(t) == "boolean" then
      return t
   elseif type(t) == "function" then
      return t
   end
end



function deepCopy(orig)
   local orig_type = type(orig)
   if orig_type == 'table' then
      local copy = {}
      copy = {}
      for orig_key, orig_value in pairs(orig) do
         copy[deepCopy(orig_key)] = deepCopy(orig_value)
      end

      setmetatable(copy, deepCopy(getmetatable(orig)))
      return copy
   else
      return orig
   end
end

local anyFunc = {}

function my_setfenv(f, env)
   return load(string.dump(f), nil, nil, env)
end

function pointInRect(px, py, x, y, w, h)
   return px > x and py > y and px < x + w and py < y + h
end

function safeSend(shader, name, ...)
   if shader:hasUniform(name) then
      shader:send(name, (...))
   end
end

function distance(x1, y1, x2, y2)
   return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end


function getQuad(axis_x, axis_y, vert_x, vert_y)
   if vert_x < axis_x then
      if vert_y < axis_y then
         return 1
      else
         return 4
      end
   else
      if vert_y < axis_y then
         return 2
      else
         return 3
      end
   end
end



function pointInPolygon(pgon, tx, ty)

   if (#pgon < 6) then
      return false
   end

   local x1 = pgon[#pgon - 1]
   local y1 = pgon[#pgon]
   local cur_quad = getQuad(tx, ty, x1, y1)
   local next_quad
   local total = 0.0

   for i = 1, #pgon, 2 do
      local x2 = pgon[i]
      local y2 = pgon[i + 1]
      next_quad = getQuad(tx, ty, x2, y2)
      local diff = next_quad - cur_quad

      if (diff == 2) or (diff == -2) then
         if (x2 - (((y2 - ty) * (x1 - x2)) / (y1 - y2))) < tx then
            diff = -diff
         end
      elseif diff == 3 then
         diff = -1
      elseif diff == -3 then
         diff = 1
      end

      total = total + diff
      cur_quad = next_quad
      x1 = x2
      y1 = y2
   end

   return (math.abs(total) == 4)

end

local u8 = require("utf8")





































































local function mesh2str(mesh, i)
   local x, y, u, v, r, g, b, a = mesh:getVertex(i)
   return
"[" .. tostring(i) .. "] " ..
   x .. " " .. y .. " " ..
   u .. " " .. v .. " " ..
   r .. " " .. g .. " " ..
   b .. " " .. a .. "\n"
end


function printMesh(mesh)
   if mesh then
      for i = 1, mesh:getVertexCount() do


         print(mesh2str(mesh, math.ceil(i)))
      end
   end
end


function printMesh2file(mesh, fname)
   if mesh then
      for i = 1, mesh:getVertexCount() do






         love.filesystem.append(fname, mesh2str(mesh, math.ceil(i)))
      end
   end
end

local function reversedipairsiter(t, i)
   i = i - 1
   if i ~= 0 then
      return i, t[i]
   end
end

local Iter = {}


function ripairs(t)

   return reversedipairsiter, t, #t + 1
end


function testflag(set, flag)
   return set % (2 * flag) >= flag
end


function setflag(set, flag)
   if set % (2 * flag) >= flag then
      return set
   end
   return set + flag
end


function clear(set, flag)
   if set % (2 * flag) >= flag then
      return set - flag
   end
   return set
end

function tobitstr(num, bits)

   bits = bits or math.max(1, select(2, math.frexp(num)))
   local t = {}
   for b = bits, 1, -1 do
      t[b] = math.fmod(num, 2)
      num = math.floor((num - t[math.ceil(b)]) / 2)
   end
   return table.concat(t)
end

function tobits(num, bits)

   bits = bits or math.max(1, select(2, math.frexp(num)))
   local t = {}
   for b = bits, 1, -1 do
      t[b] = math.fmod(num, 2)
      num = math.floor((num - t[math.ceil(b)]) / 2)
   end
   return t
end

local sqrt = math.sqrt

function vec_len(x, y)
   return sqrt(x * x + y * y)
end


function linum(code, inc)

   inc = inc or 0
   local i = 1 + inc
   local t = {}
   local buf = code
   if string.sub(buf, #buf, #buf) ~= "\n" then
      buf = buf .. '\n'
   end

   for line in string.gmatch(buf, '(.-)[\n]') do

      table.insert(t, i .. " " .. line .. '\n')
      i = i + 1
   end
   return table.concat(t)
end

function is_rgba(color)
   return
type(color) == 'table' and
   type(color[1]) == 'number' and
   type(color[2]) == 'number' and
   type(color[3]) == 'number' and
   type(color[4]) == 'number' and
   color[1] >= 0. and color[1] <= 1. and
   color[2] >= 0. and color[1] <= 1. and
   color[3] >= 0. and color[1] <= 1. and
   color[4] >= 0. and color[1] <= 1.
end

function size2human(n)
   local kilo = n / 1024

   return string.format("%d Kb", kilo)
end

function randomFilenameStr(len)
   local s = ""
   len = len or 5
   for i = 1, len do
      s = s .. tostring(math.ceil(math.random() * 10))
   end
   return s
end

local Justfify = {}




local Input = {}



function boxifyTextParagraph(input, j)
   j = j or "none"
   local list = {}
   local maxlen = 0
   local rep = string.rep
   local ceil = math.ceil
   local floor = math.floor


   local lines = {}

   if type(input) == 'string' then
      for line in string.gmatch(input, '(.-)[\n]') do
         table.insert(lines, line)
      end
   elseif type(input) == 'table' then
      lines = input
   else
      error('Unsupported data type: ' .. type(input))
   end

   for _, line in ipairs(lines) do
      local len = u8.len(line)
      if len > maxlen then
         maxlen = len
      end
   end

   if j == 'none' then
      for _, line in ipairs(lines) do
         local num = maxlen - u8.len(line)
         table.insert(list, '│' .. line .. rep(' ', num) .. '│')
      end
   elseif j == 'center' then
      print('maxlen', maxlen)
      for _, line in ipairs(lines) do
         local len = u8.len(line)
         local num = maxlen - len
         local num1 = ceil(num / 2.)
         local num2 = floor(num / 2.)


         local str = '│' .. rep(' ', num1) .. line .. rep(' ', num2) .. '│'
         table.insert(list, str)
      end
   end

   table.insert(list, 1, '┌' .. rep("─", maxlen) .. '┐')
   table.insert(list, #list + 1, '└' .. rep("─", maxlen) .. '┘')

   return list
end



function makeProgressBar(symbols_len, ratio)
   local ch_clean = "░"
   local ch_filled = "▓"

   if ratio < 0 then
      ratio = 0.
   end
   if ratio > 1 then
      ratio = 1.
   end

   local rep = string.rep
   local clean_num = math.ceil((1. - ratio) * symbols_len)
   local filled_num = math.floor(ratio * symbols_len)
   local res = rep(ch_filled, filled_num) .. rep(ch_clean, clean_num)


   if u8.len(res) > symbols_len then
      return string.sub(res, 1, #res - 2)
   else
      return res
   end
end


function test_makeProgressBar()
   local len = 20
   local stepsnum = 100
   for i = 1, stepsnum do
      print(makeProgressBar(len, i / stepsnum))
   end
end









function test_boxifyTextParagraph()

   local message = [[

- Да. Например, в одном из последних Ваших рассказов он у
Вас срывает все планы  вражеского  шпиона,  который  собирался
выкрасть  чертежи  атомной  бомбы.  Насколько  я  помню,   ему
удается-таки завлечь шпиона в западню, схватить его и  вернуть
украденные документы. 
        А  затем,  м-р  Мейсон,  Вы  раскрываете
содержание документов, заставив Вашего  героя  читать  их,  и,
таким образом, даете возможность и  читателям  узнать,  о  чем
идет речь. Документы излагаются очень подробно. Вы,  например,
подчеркиваете, что для создания критической  массы  необходимо
22,7 фунта урана-235, называете материалы, из которых  сделана
оболочка  бомбы,  подробно  излагаете  конструкцию   взрывного
устройства, а затем сообщаете  о  ее  разрушительной  силе  на
определенном участке.

- Да. Например, в одном из последних Ваших рассказов он у
Вас срывает все планы  вражеского  шпиона,  который  собирался
выкрасть  чертежи  атомной  бомбы.  Насколько  я  помню,   ему
удается-таки завлечь шпиона в западню, схватить его и  вернуть
    украденные документы. 
    А  затем,  м-р  Мейсон,  Вы  раскрываете
содержание документов, заставив Вашего  героя  читать  их,  и,
таким образом, даете возможность и  читателям  узнать,  о  чем
идет речь. Документы излагаются очень подробно. Вы,  например,
подчеркиваете, что для создания критической  массы  необходимо
22,7 фунта урана-235, называете материалы, из которых  сделана
оболочка  бомбы,  подробно  излагаете  конструкцию   взрывного
устройства, а затем сообщаете  о  ее  разрушительной  силе  на
определенном участке.

]]


   local lines

   lines = boxifyTextParagraph(message, 'none')
   for k, v in ipairs(lines) do
      print(v)
   end

   lines = boxifyTextParagraph(message, 'center')
   for k, v in ipairs(lines) do
      print(v)
   end

   lines = boxifyTextParagraph(
   {
      "BBB",
      "Карта создается",
      "оооооооофффффф",
   },
   'center')

   for k, v in ipairs(lines) do
      print(v)
   end

end
