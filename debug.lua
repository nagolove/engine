local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert

require('mobdebug').listen()











































local function debug_print(id, ...)
   print(id, ...)
end

local function set_filter(setup)

end

local PrintCallback = {}

local printCallback = function(s)
   print(s)
end

local function set_callback(cb)
   assert(cb)
   printCallback = cb
end

return {
   debug_print = debug_print,
   set_filter = set_filter,
   set_callback = set_callback,
}
