local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local debug = _tl_compat and _tl_compat.debug or debug; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



require('common')
require("love_inc").require_pls_nographic()
local ecodes = require("errorcodes")
local colorize = require('ansicolors2').ansicolors

local serpent = require("serpent")


























local inspect = require('inspect')
local format = string.format
local Filter = {}
local PrintCallback = {}
local Loader = {}





local channel_filter = love.thread.getChannel("debug_filter")


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

   local ok, errmsg = checkNumbers(setup)
   if not ok then
      error("Error in filter setup: " .. errmsg)
   end

   filter = deepCopy(setup)




   local filter_ser = serpent.dump(filter)
   print('filter_ser', inspect(filter_ser))


   if channel_filter:getCount() > 0 then
      channel_filter:pop()
   end

   channel_filter:push(filter_ser)
end

local function peek_shared_filter()
   local shared_filter
   local filter_ser = channel_filter:peek()

   if filter_ser then
      local chunk = load(filter_ser)

      if not chunk then
         error("Could not load(filter_ser)")
      end

      shared_filter = chunk()
   end






   return shared_filter
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

   local shared_filter = peek_shared_filter()







   if checkNum(num) then
      enabled[num] = not enabled[num]
      local ids_list = shared_filter[num]
      if ids_list then
         for _, v in ipairs(ids_list) do
            shouldPrint[v] = enabled[num]
         end
      end
   end

   print("shouldPrint", inspect(shouldPrint))

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

   local shared_filter = peek_shared_filter()
   ids = parse_ids(shared_filter)




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

local function build_str()
   local s = {}

   local shared_filter = peek_shared_filter()



   for k, ids_arr in pairs(shared_filter) do
      local state = "(" .. tostring(k)
      if enabled[k] then
         state = state .. "+"
      else
         state = state .. "-"
      end
      state = state .. "): "

      local count = #ids_arr
      for i, id in ipairs(ids_arr) do
         local appendix = i ~= count and "," or " "
         state = state .. id .. appendix
      end

      table.insert(s, state)
   end

   return table.concat(s)
end

local font_size = 32

local font
local ok, errmsg = pcall(function()
   font = love.graphics.newFont(font_size)
end), string

if not ok then
   print("Could not create new default font:", errmsg)
end

local function render(x0, y0)
   local s = build_str()



   assert(x0)
   assert(y0)

   local width, _ = love.graphics.getDimensions()
   local old_font = love.graphics.getFont()
   love.graphics.setFont(font)
   love.graphics.printf(s, x0, y0, width)





   love.graphics.setFont(old_font)
end

return {
   render = render,
   debug_print = debug_print,
   set_filter = set_filter,
   set_callback = set_callback,
   keypressed = keypressed,
}
