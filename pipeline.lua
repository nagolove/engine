local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local debug = _tl_compat and _tl_compat.debug or debug; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local colorize = require('ansicolors2').ansicolors
local lt = love.thread
local tl = require("tl")
local ecodes = require("errorcodes")
local format = string.format

local DEBUG_RENDER = true

local resume = coroutine.resume



local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local State = {}











 Pipeline = {}

































local Pipeline_mt = {
   __index = Pipeline,
}

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
      print(colorize(msg))
      print(colorize('%{cyan}' .. debug.traceback()))
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

function Pipeline:push(arg)
   if self.section_state ~= 'open' then
      local color_block = '%{red}'
      local msg = 'Attempt to push in pipeline with "%s" section state'
      print(colorize(color_block .. format(msg, self.section_state)))
      os.exit(ecodes.ERROR_NO_SECTION)
   end
   graphic_command_channel:push(arg)
end

function Pipeline:ready()
   local is_ready = draw_ready_channel:peek()
   if is_ready then
      if type(is_ready) ~= 'string' then
         print("Type error in is_ready flag")
         os.exit(ecodes.ERROR_IS_READY_TYPE)
      end
      if is_ready ~= "ready" then
         local msg = tostring(is_ready) or ""
         print("Bad message in draw_ready_channel: " .. msg)
         os.exit(ecodes.ERROR_NO_READY)
      end
      draw_ready_channel:pop()
      return true
   end
   return false
end

function Pipeline:waitForReady()
   draw_ready_channel:supply("ready")
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

   if self.section_state ~= 'closed' then
      local color_block = '%{red}'
      local msg = 'Section not closed, but "%s"'
      print(colorize(color_block .. format(msg, self.section_state)))
      print(colorize('%{magenta}' .. debug.traceback()))
      os.exit(ecodes.ERROR_NO_SECTION)
   end





   local cmd_name = graphic_command_channel:pop()


   while cmd_name do

      if type(cmd_name) ~= 'string' then
         print(colorize('%{yellow}' .. debug.traceback()))
         print(colorize('%{red}Pipeline:render()'))
         print(colorize('%{red}type(cmd_name) = ' .. type(cmd_name)))
         print(colorize('%{green}cmd_name = ' .. cmd_name))
         print(colorize('%{magenta}' .. debug.traceback()))
         os.exit(ecodes.ERROR_NO_COMMAND)
      end





      local coro = self.renderFunctions[cmd_name]
      if coro then
         local ok, errmsg = resume(coro)
         if not ok then
            print(colorize('%{yellow}' .. 'cmd_name: ' .. cmd_name))
            print(colorize('%{cyan}' .. debug.traceback()))
            print(colorize('%{red}' .. errmsg))
            os.exit(ecodes.ERROR_DIED_CORO)
         end
      else
         local func_name = cmd_name or "nil"
         local msg = 'Render function "%s" not found in table.'
         print(colorize('%{red}' .. format(msg, func_name)))

         if DEBUG_RENDER then
            self:printAvaibleFunctions()
         end

         print(colorize('%{cyan}' .. debug.traceback()))
         os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
      end


      cmd_name = graphic_command_channel:pop()
   end
end

function Pipeline:printAvaibleFunctions()
   local color = 'magenta'

   local color_block = "%{" .. color .. "}"
   print(colorize(color_block .. "--- Avaible render functions: ---"))
   for k, _ in pairs(self.renderFunctions) do
      print(colorize(color_block .. k))
   end
   print(colorize(color_block .. "---------------------------------"))
end



function Pipeline:pullRenderCode()
   local rendercode
   repeat
      rendercode = graphic_code_channel:pop()

      if rendercode then
         local func, errmsg = tl.load(rendercode)

         if not func then
            local msg = "%{red}Something wrong in render code: %{cyan}"
            print(colorize(msg .. errmsg))
            os.exit(ecodes.ERROR_INTERNAL_LOAD)
         else
            local name = graphic_code_channel:pop()
            if not name then
               error('No name for drawing function.')
            end


            local coro = coroutine.create(func)
            self.renderFunctions[name] = coro

            name = colorize('%{yellow}' .. name)
            print('name, func, errmsg', name, func, errmsg)
            print('rendercode', colorize('%{green}' .. '\n' .. rendercode))
         end

      end
   until not rendercode
end


function Pipeline:openAndClose(func_name)
   self:open(func_name)
   self:close()
end
