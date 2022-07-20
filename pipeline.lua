local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local debug = _tl_compat and _tl_compat.debug or debug; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


require('common')
local colorize = require('ansicolors2').ansicolors
local lt = love.thread
local tl = require("tl")
local ecodes = require("errorcodes")
local format = string.format
local smatch = string.match
local inspect = require('inspect')
local resume = coroutine.resume
local floor = math.floor




local debug_print = print


local draw_ready_channel = lt.getChannel("draw_ready_channel")



local code_channel = lt.getChannel("graphic_code_channel")

local graphic_received_in_sec_channel = lt.getChannel('graphic_received_in_sec')

local graphic_query_channel = lt.getChannel('graphic_query_channel')

local graphic_query_res_channel = lt.getChannel('graphic_query_res_channel')

local State = {}






local reading_timeout = 0.05






local Pipeline = {}














































































local Pipeline_mt = {
   __index = Pipeline,
}



local use_stamp = false












function Pipeline.new(scene_prefix)
   local self = setmetatable({}, Pipeline_mt)
   self.section_state = 'closed'
   self.scene_prefix = scene_prefix or ""

   self.cmd_channel_idx = 1
   self.cmd_channel_idx_max = 3
   self.cmd_channels = {}
   for i = 1, self.cmd_channel_idx_max do
      local ch = lt.getChannel("graphic_command_channel" .. tostring(i))
      table.insert(self.cmd_channels, ch)
   end
   self.command_channel = self.cmd_channels[self.cmd_channel_idx]
   print('self.command_channel', self.command_channel)

   self.preload = [[
    local _args = {...}
    local _channel_index: integer = _args[1] as integer
    assert(type(_channel_index) == "number")
    local lt = love.thread
    local _cmd_channel_max = _MAX_CHANNELS_SUBSTITUTION_
    local _channels: {lt.Channel} = {}

    for i = 1, _cmd_channel_max do
        local ch = lt.getChannel("graphic_command_channel" .. tostring(i))
        table.insert(_channels, ch)
    end

    local graphic_command_channel: lt.Channel = _channels[_channel_index]

    local default_yield = coroutine.yield
    coroutine.yield = function()
        error("Please use yield_ch() instead of coroutine.yield()")
    end

    local function yield_ch(): lt.Channel
        _channel_index = default_yield() as integer
        assert(type(_channel_index) == 'number')
        graphic_command_channel = _channels[_channel_index]
    end

    --local graphic_command_channel = lt.getChannel(
        --"graphic_command_channel" .. _channel_index
    --)

    --local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
    ]]
   self.preload = string.gsub(
   self.preload,
   "_MAX_CHANNELS_SUBSTITUTION_",
   tostring(self.cmd_channel_idx_max))


   if self.scene_prefix then
      local var = format('local SCENE_PREFIX = "%s"\n', self.scene_prefix)
      self.preload = self.preload .. var
   end


   self.inc_linum = 2

   self.renderFunctions = {}
   self.counter = 0
   self.cmd_num = 0
   self.last_render = love.timer.getTime()
   self.received_bytes = 0
   self.received_in_sec = 0
   self.current_func = ''
   self.forced = false


   if love.graphics then
      self.graphic_info_channel = love.thread.getChannel("graphic_info_channel")
      self.graphic_info_channel:push({ love.graphics.getDimensions() })
   end















   return self
end

function Pipeline:open(func_name)
   if self.section_state ~= 'closed' then
      local msg = '%{red}Double opened section'
      debug_print("graphics", colorize(msg))
      debug_print("graphics", colorize('%{cyan}' .. debug.traceback()))
      os.exit(ecodes.ERROR_NO_SECTION)
   end
   self.section_state = 'open'

   assert(type(func_name) == 'string')


   self.command_channel:push(func_name)

   self.current_func = func_name
   self.counter = self.counter + 1
   if use_stamp then
      error("This option was disabled by developer.")

   end
end

function Pipeline:close()
   self.section_state = 'closed'
end


function Pipeline:push(...)
   if self.section_state ~= 'open' then
      local color_block = '%{red}'
      local msg = 'Attempt to push in pipeline with "%s" section state'
      local fmt_msg = format(msg, self.section_state)
      local col_msg = colorize(color_block .. fmt_msg)

      debug_print("graphics", col_msg)

      color_block = '%{blue}'
      msg = 'Current function name is "%s"'
      fmt_msg = format(msg, self.current_func)
      col_msg = colorize(color_block .. fmt_msg)
      debug_print("graphics", col_msg)

      os.exit(ecodes.ERROR_NO_SECTION)
   end

   for i = 1, select('#', ...) do
      local argument = select(i, ...)
      self.counter = self.counter + 1
      self.command_channel:push(argument)
   end
end



function Pipeline:sync()





   draw_ready_channel:push(self.counter)
   draw_ready_channel:supply(self.cmd_channel_idx)


   self.cmd_channel_idx = 
   (self.cmd_channel_idx + 1) % self.cmd_channel_idx_max + 1




   self.counter = 0
end

function Pipeline:waitForReady()
   local timeout = 0.5
   local cmd_num = draw_ready_channel:demand(timeout)
   local channel_idx = draw_ready_channel:demand(timeout)

   if cmd_num then












      assert(type(cmd_num) == "number")
      assert(type(channel_idx) == "number")






      self.cmd_num = floor(cmd_num)
      self.cmd_channel_idx = floor(channel_idx)
      self.command_channel = self.cmd_channels[self.cmd_channel_idx]

      if not self.cmd_num then
         error("cmd_num is nil")
      end

      return true
   else
      local msg = '%{red} draw_ready_channel:demand() is not respond'
      debug_print("graphics", colorize(msg))


   end

   return false
end



function Pipeline:pushCode(name, code)
   if self.section_state == 'open' then
      self.section_state = 'undefined'

      return
   end

   if not name then
      error("No name for pushCode()")
   end
   if not code then
      error("No code for pushCode()")
   end

   code = self.preload .. code

   code_channel:push(code)
   code_channel:push(name)
end

function Pipeline:pushCodeFromFileRoot(name, fname)
   local content = love.filesystem.read(fname)
   if not content then
      error('Could not load: ' .. fname)
   else
      print(name, 'loaded from', fname)
   end
   self:pushCode(name, content)
end

function Pipeline:pushCodeFromFile(name, fname)
   local path = self.scene_prefix .. '/' .. fname
   local content = love.filesystem.read(path)
   if not content then
      error('Could not load: ' .. path)
   else
      print(name, 'loaded from', path)
   end
   self:pushCode(name, content)
end



local function process_queries()
   local query
   repeat
      query = graphic_query_channel:pop()
      if query then
         if query == 'getDimensions' then
            local w, h = love.graphics.getDimensions()
            graphic_query_res_channel:push(w)
            graphic_query_res_channel:push(h)
         else
            error('Unkown query in process_queries()')
         end
      end
   until not query
end






















function Pipeline:render_internal()
   local custom_print = function(s)
      print(colorize(s))
   end

   if self.section_state ~= 'closed' then
      local color_block = '%{red}'
      local msg = 'Section not closed, but "%s"'
      custom_print(color_block .. format(msg, self.section_state))
      custom_print('%{magenta}' .. debug.traceback())
      os.exit(ecodes.ERROR_NO_SECTION)
   end

   local cmd_num = self.cmd_num
   local cmd_name
   local received_bytes = 0

   local stamp
   if use_stamp then
      error("This option was disabled by developer.")

   end

   for _ = 1, cmd_num do

      cmd_name = self.command_channel:pop()


      assert(cmd_name ~= "string")

      if cmd_name then
         if type(cmd_name) ~= 'string' then
            custom_print('%{yellow}' .. debug.traceback())
            custom_print('%{red}Pipeline:render()')
            custom_print('%{red}type(cmd_name) = ' .. type(cmd_name))

            if type(cmd_name) == 'table' then
               local msg = inspect(cmd_name)
               custom_print('%{green}cmd_name = ' .. msg or 'nil')
            else
               custom_print('%{green}cmd_name = ' .. cmd_name or 'nil')
            end

            custom_print('%{magenta}' .. debug.traceback())
            os.exit(ecodes.ERROR_NO_COMMAND)
         end



         local coro = self.renderFunctions[cmd_name]



         if coro then
            local ok, errmsg

            received_bytes = received_bytes + #cmd_name
            ok, errmsg = resume(coro, self.cmd_channel_idx)

            if not self.forced and not ok then
               custom_print('%{blue} resume render coroutine error.')
               custom_print('%{yellow}' .. 'cmd_name: ' .. cmd_name)
               custom_print('%{cyan}' .. debug.traceback())
               custom_print('%{red}' .. errmsg)
               os.exit(ecodes.ERROR_DIED_CORO)
            end
         else
            local func_name = cmd_name or "nil"
            local msg = 'Render function "%s" not found in table.'
            custom_print('%{red}' .. format(msg, func_name))

            msg = 'Current func = "%s"'
            custom_print('%{blue}' .. format(msg, self.current_func))

            msg = 'Command number = %d'
            custom_print('%{blue}' .. format(msg, self.cmd_num))

            self:printAvaibleFunctions()


            print(colorize("%{yellow} Sorry, callstack is not avaible yet."))

            custom_print('%{cyan}' .. debug.traceback())
            os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
         end

         if use_stamp then
            error("This option was disabled by developer.")




         end
      end
   end











   local new_last_render = love.timer.getTime()
   local delay = 1
   local diff = new_last_render - self.last_render
   self.received_bytes = self.received_bytes + received_bytes
   if diff > delay then
      self.last_render = new_last_render
      self.received_in_sec = self.received_bytes
      graphic_received_in_sec_channel:clear()
      graphic_received_in_sec_channel:push(self.received_in_sec)
      self.received_bytes = 0
   end


end





function Pipeline:render()
   if self:waitForReady() then
      if self.forced then
         pcall(function()
            self:render_internal()
         end)
      else
         self:render_internal()
      end
   end
   process_queries()
end

function Pipeline:getDimensions()
   graphic_query_channel:supply("getDimensions")
   local x = floor(graphic_query_res_channel:demand())
   local y = floor(graphic_query_res_channel:demand())






   return x, y
end

function Pipeline:get_received_in_sec()
   local bytes = graphic_received_in_sec_channel:peek()
   if bytes then
      return floor(tonumber(bytes))
   else
      return 0
   end
end

function Pipeline:printAvaibleFunctions()
   local color = 'magenta'

   local color_block = "%{" .. color .. "}"
   debug_print("graphics", colorize(color_block .. "--- Avaible render functions: ---"))
   for k, _ in pairs(self.renderFunctions) do
      debug_print("graphics", colorize(color_block .. k))
   end
   debug_print("graphics", colorize(color_block .. "---------------------------------"))
end



function Pipeline:pullRenderCode()

   local rendercode
   repeat
      local name
      rendercode = code_channel:pop()

      if rendercode then
         name = code_channel:pop()
         if not name then
            error('No name for drawing function.')
         end
         local func, errmsg = tl.load(rendercode, name)



         if not func then
            local msg = "%{red}Something wrong in render code: %{cyan}"
            local numerated = linum(rendercode, self.inc_linum)
            local code = colorize('%{green}' .. '\n' .. numerated)
            debug_print("graphics", 'rendercode', code)
            debug_print("graphics", colorize(msg .. errmsg))
            os.exit(ecodes.ERROR_INTERNAL_LOAD)
         else

            local coro = coroutine.create(func)
            self.renderFunctions[name] = coro

            name = colorize('%{yellow}' .. name)
            debug_print("graphics", 'name, func, errmsg', name, func, errmsg)

         end

      end
   until not rendercode

end

function Pipeline:openPushAndClose(func_name, ...)
   self:open(func_name)
   self:push(...)







   self:close()
end

function Pipeline:openAndClose(func_name)
   self:open(func_name)
   self:close()
end

return Pipeline
