local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; require("camera")

function shallowCopy(t)
   local copy = {}
   for k, v in pairs(t) do
      copy[k] = v
   end
   return copy
end

 Scene = {}














 SceneMap = {}





 Tool = {}
