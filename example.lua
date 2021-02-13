local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs
























































local ChannelsTypes = {
   "cellrequest",
   "data",
   "msg",
   "object",
   "ready",
   "request",
   "state",
}

for i, v in ipairs(ChannelsTypes) do
   print(i, v)
end
