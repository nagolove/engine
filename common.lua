local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


require("love")
require("camera")



 SceneType = {}




 Scene = {}



















 SceneMap = {}





 Tool = {}











function trim(s)
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

function dist(x1, y1, x2, y2)
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













function makeDescentColorText(
   textobj,
   textstr,
   fromcolor, tocolor,
   x, y, angle, sx, sy, ox, oy, kx, ky)


   assert(textobj, "textobj should not be nil")
   assert(type(textstr) == "string", "textstr should be a string, not " .. type(textstr))
   assert(type(fromcolor) == "table", "fromcolor should be a table, not " .. type(fromcolor))
   assert(type(tocolor) == "table", "tocolor should be a table, not " .. type(tocolor))
   assert(#fromcolor == 4, "fromcolor should have 4 components")
   assert(#tocolor == 4, "tocolor should have 4 components")








   local slen = u8.len(textstr)
   print("slen", slen)

   local r, g, b, a = fromcolor[1], fromcolor[2], fromcolor[3], fromcolor[4]


   local d_r = (tocolor[1] - fromcolor[1]) / slen
   local d_g = (tocolor[2] - fromcolor[2]) / slen
   local d_b = (tocolor[3] - fromcolor[3]) / slen
   local d_a = (tocolor[4] - fromcolor[4]) / slen

   print("d_r", d_r)
   print("d_g", d_g)
   print("d_b", d_b)
   print("d_a", d_a)






   local coloredtext = {}
   for _, codepoint in u8.codes(textstr) do
      local char = u8.char(codepoint)

      table.insert(coloredtext, { r, g, b, a })
      table.insert(coloredtext, char)
      r = r + d_r
      g = g + d_g
      b = b + d_b
      a = a + d_a
   end
   return textobj:add(coloredtext, x, y, angle, sx, sy, ox, oy, kx, ky)

end

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
