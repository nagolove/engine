local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local debug = _tl_compat and _tl_compat.debug or debug; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string


local colorize = require('ansicolors2').ansicolors
local lt = love.thread
local tl = require("tl")
local ecodes = require("errorcodes")
local format = string.format



local resume = coroutine.resume

local dprint = require('debug_print')
local debug_print = dprint.debug_print




local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local State = {}











 Pipeline = {}

































local Pipeline_mt = {
   __index = Pipeline,
}

local function timestamp(msg)
   local prepared = format("%.4f : %s", love.timer.getTime(), msg)




   print(colorize('%{blue}' .. prepared))
end

function Pipeline.new(scene_prefix)
   local self = setmetatable({}, Pipeline_mt)
   self.section_state = 'closed'
   self.scene_prefix = scene_prefix or ""
   self.preload = [[
    local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
    ]]
   if self.scene_prefix then
      local var = format('local SCENE_PREFIX = "%s"\n', self.scene_prefix)
      self.preload = self.preload .. var
   end
   self.renderFunctions = {}
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

   graphic_command_channel:push(func_name)
end

function Pipeline:close()
   self.section_state = 'closed'
end

function Pipeline:pushName(_)

end

function Pipeline:push(argument)
   if self.section_state ~= 'open' then
      local color_block = '%{red}'
      local msg = 'Attempt to push in pipeline with "%s" section state'
      debug_print("graphics", colorize(color_block .. format(msg, self.section_state)))
      os.exit(ecodes.ERROR_NO_SECTION)
   end
   graphic_command_channel:push(argument)
end

function Pipeline:ready()
   local is_ready = draw_ready_channel:peek()




   if is_ready then
      if type(is_ready) ~= 'string' then

         print("graphics", "Type error in is_ready flag")
         os.exit(ecodes.ERROR_IS_READY_TYPE)
      end
      if is_ready ~= "ready" then
         local msg = tostring(is_ready) or ""

         print("graphics", "Bad message in draw_ready_channel: " .. msg)
         os.exit(ecodes.ERROR_NO_READY)
      end
      draw_ready_channel:pop()
      return true
   end
   return false
end

function Pipeline:waitForReady()
   local timeout = 0.1
   local result = draw_ready_channel:supply("ready", timeout)

   if not result then
      debug_print("graphics", colorize('%{red} draw_ready_channel:supply() is not respond'))
   end

   return result
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

   graphic_code_channel:push(code)
   graphic_code_channel:push(name)
end





function Pipeline:render()
   local custom_print = print

   if self.section_state ~= 'closed' then
      local color_block = '%{red}'
      local msg = 'Section not closed, but "%s"'
      custom_print("graphics", colorize(color_block .. format(msg, self.section_state)))
      custom_print("graphics", colorize('%{magenta}' .. debug.traceback()))
      os.exit(ecodes.ERROR_NO_SECTION)
   end




   local cmd_name = graphic_command_channel:demand()





   while cmd_name do

      if type(cmd_name) ~= 'string' then
         custom_print("graphics", colorize('%{yellow}' .. debug.traceback()))
         custom_print("graphics", colorize('%{red}Pipeline:render()'))
         custom_print("graphics", colorize('%{red}type(cmd_name) = ' .. type(cmd_name)))
         custom_print("graphics", colorize('%{green}cmd_name = ' .. cmd_name))
         custom_print("graphics", colorize('%{magenta}' .. debug.traceback()))
         os.exit(ecodes.ERROR_NO_COMMAND)
      end





      local coro = self.renderFunctions[cmd_name]
      if coro then



         local ok, errmsg = resume(coro)
         if not ok then
            custom_print("graphics", colorize('%{yellow}' .. 'cmd_name: ' .. cmd_name))
            custom_print("graphics", colorize('%{cyan}' .. debug.traceback()))
            custom_print("graphics", colorize('%{red}' .. errmsg))
            os.exit(ecodes.ERROR_DIED_CORO)
         end
      else
         local func_name = cmd_name or "nil"
         local msg = 'Render function "%s" not found in table.'
         custom_print("graphics", colorize('%{red}' .. format(msg, func_name)))


         self:printAvaibleFunctions()


         custom_print("graphics", colorize('%{cyan}' .. debug.traceback()))
         os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
      end


      cmd_name = graphic_command_channel:pop()
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
      rendercode = graphic_code_channel:pop()

      if rendercode then
         local func, errmsg = tl.load(rendercode)

         if not func then
            local msg = "%{red}Something wrong in render code: %{cyan}"
            debug_print("graphics", colorize(msg .. errmsg))
            os.exit(ecodes.ERROR_INTERNAL_LOAD)
         else
            local name = graphic_code_channel:pop()
            if not name then
               error('No name for drawing function.')
            end


            local coro = coroutine.create(func)
            self.renderFunctions[name] = coro

            name = colorize('%{yellow}' .. name)
            debug_print("graphics", 'name, func, errmsg', name, func, errmsg)
            debug_print("graphics", 'rendercode', colorize('%{green}' .. '\n' .. rendercode))
         end

      end
   until not rendercode

end


function Pipeline:openAndClose(func_name)
   self:open(func_name)
   self:close()
end
