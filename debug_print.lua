local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string



require('common')


























local inspect = require('inspect')
local format = string.format
local Filter = {}
local PrintCallback = {}



local filter = {}


local enabled = {
   [0] = false,
   [1] = false,
   [2] = false,
   [3] = false,
   [4] = false,
   [5] = false,
   [6] = false,
   [7] = false,
   [8] = false,
   [9] = false,
}


local shouldPrint = {}


local function checkNum(n)
   local m = {
      [0] = true,
      [1] = true,
      [2] = true,
      [3] = true,
      [4] = true,
      [5] = true,
      [6] = true,
      [7] = true,
      [8] = true,
      [9] = true,
   }
   return m[n] or false
end


local function checkNumbers(filt)
   for k, _ in pairs(filt) do
      local num = tonumber(k)

      if not (num and checkNum(num)) then
         return false, "Incorrect number(not in 0..9 range): " .. num
      end
   end
   return true
end

local ids = {}

local function parse_ids(setup)
   ids = {}
   for _, row in pairs(setup) do
      for _, id in ipairs(row) do
         ids[id] = true
      end
   end
end

local function set_filter(setup)
   assert(setup)
   filter = deepCopy(setup)
   parse_ids(setup)
   local ok, errmsg = checkNumbers(filter)
   if not ok then
      print("Error in filter setup: ", errmsg)
   end
end

local printCallback = function(...)
   print(...)
end

local function set_callback(cb)
   assert(cb)
   printCallback = cb
end

local function keypressed(key, key2)

   assert(key2 == nil, "Use only scancode. Second param always unused.")





   local num = tonumber(key)

   if checkNum(num) then
      enabled[num] = not enabled[num]
      local isEnabled = enabled[num]


      local ids_list = filter[num]
      if ids_list then
         for _, v in ipairs(ids_list) do
            shouldPrint[v] = isEnabled

         end
      end

   end
end

local function debug_print(id, ...)

   assert(type(id) == 'string')


   local msg = format("id = '%s' not found in filter", tostring(id))
   assert(ids[id] == true, msg)
   if shouldPrint[id] then
      printCallback(...)
   end
end

return {
   debug_print = debug_print,
   set_filter = set_filter,
   set_callback = set_callback,
   keypressed = keypressed,
}
