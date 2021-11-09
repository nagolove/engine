local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local debug = _tl_compat and _tl_compat.debug or debug; local os = _tl_compat and _tl_compat.os or os; local colorize = require('ansicolors2').ansicolors
local lt = love.thread
local tl = require("tl")
local ecodes = require("errorcodes")

local LoadFunction = {}


local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local State = {}





 Pipeline = {}

























local Pipeline_mt = {
   __index = Pipeline,
}

function Pipeline.new()
   local self = setmetatable({}, Pipeline_mt)
   self.in_section = false
   self.renderFunctions = {}
   return self
end

function Pipeline:enter(section_name)
   print('self.in_section', self.in_section)
   if self.in_section then
      local msg = '%{red}Double opened section'
      print(colorize(msg))
      os.exit(ecodes.ERROR_NO_SECTION)
   end
   self.in_section = true



   assert(type(section_name) == 'string')
   print('section_name', section_name)
   graphic_command_channel:push(section_name)
end

function Pipeline:leave()

   self.in_section = false
end

function Pipeline:pushName(_)

end

function Pipeline:push(arg)
   if not self.in_section then
      local msg = '%{red}Attempt to pipeline push outside section '
      print(colorize(msg))
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


function Pipeline:pushCode(name, code)
   if not name then
      error("No name for pushCode()")
   end
   if not code then
      error("No code for pushCode()")
   end

   graphic_code_channel:push(code)
   graphic_code_channel:push(name)
end

function Pipeline:render()


   if self.in_section then
      local msg = '%{red}Section not closed'
      print(colorize(msg))
      os.exit(ecodes.ERROR_NO_SECTION)
   end

   local cmd_name = graphic_command_channel:demand()
   print('cmd_name', cmd_name)
   if type(cmd_name) ~= 'string' then
      print(colorize('%{yellow}' .. debug.traceback()))
      print(colorize('%{red}Pipeline:render()'))
      print(colorize('%{red}type(cmd_name) = ' .. type(cmd_name)))
      print(colorize('%{green}cmd_name = ' .. cmd_name))
      os.exit(ecodes.ERROR_NO_COMMAND)
   end
   local f = self.renderFunctions[cmd_name]
   if f then
      f()
   else
      local msg = '%{red}Render function not found in table.'
      print(colorize(msg))
      os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
   end
end



function Pipeline:pullRenderCode()
   local rendercode

   repeat

      rendercode = graphic_code_channel:pop()

      if rendercode then
         local func, errmsg = tl.load(rendercode)

         print('func, errmsg', func, errmsg)
         print('rendercode', colorize('%{green}' .. rendercode))

         if not func then

            local msg = "%{red}Something wrong in render code: %{cyan}"
            print(colorize(msg .. errmsg))
            os.exit(ecodes.ERROR_INTERNAL_LOAD)
         else
            local name = graphic_code_channel:pop()
            if not name then
               error('No name for drawing function.')
            end


            self.renderFunctions[name] = func
         end
      end
   until not rendercode


end
