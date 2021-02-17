local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; require("love")
require("camera")



function shallowCopy(t)
   local copy = {}
   for k, v in pairs(t) do
      copy[k] = v
   end
   return copy
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

 Scene = {}














 SceneMap = {}





 Tool = {}









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
   local total = 0

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
