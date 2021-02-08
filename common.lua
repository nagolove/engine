local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local load = _tl_compat and _tl_compat.load or load; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; require("love")
require("camera")

function shallowCopy(t)
   local copy = {}
   for k, v in pairs(t) do
      copy[k] = v
   end
   return copy
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
