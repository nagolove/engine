local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local debug = _tl_compat and _tl_compat.debug or debug; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string



require('common')
local ecodes = require("errorcodes")
local colorize = require('ansicolors2').ansicolors



























local format = string.format
local Filter = {}
local PrintCallback = {}




local channel_filter = love.thread.getChannel("debug_filter")
local channel_enabled = love.thread.getChannel("debug_enabled")
local channel_ids = love.thread.getChannel("debug_ids")
local channel_should_print = love.thread.getChannel("debug_should_print")


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


local ids = {}


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

local function parse_ids(setup)
   local ret_ids = {}
   for _, row in pairs(setup) do
      for _, id in ipairs(row) do
         ret_ids[id] = true
      end
   end
   return ret_ids
end

local function set_filter(setup)
   assert(setup)
   filter = deepCopy(setup)
   ids = parse_ids(setup)

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

local function print_ids()
   local msg = ""
   for k, _ in pairs(ids) do
      msg = msg .. k .. " "
   end
   print("Avaible ids are: ", colorize("%{yellow}" .. msg))
end

local function debug_print(id, ...)





   assert(type(id) == 'string')
   if not ids[id] then
      local msg = format("id = '%s' not found in filter", tostring(id))
      print(msg)
      print_ids()
      print(debug.traceback())
      os.exit(ecodes.ERROR_NO_SUCH_DEBUG_ID)
   end

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
