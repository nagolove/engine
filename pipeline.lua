local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local os = _tl_compat and _tl_compat.os or os; local colorize = require('ansicolors2').ansicolors
local ecodes = require("errorcodes")
local lt = love.thread


local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

 Pipeline = {}




















local Pipeline_mt = {
   __index = Pipeline,
}

function Pipeline.new()
   local self = setmetatable({}, Pipeline_mt)
   self.in_section = false
   return self
end

function Pipeline:enter(_)
   self.in_section = true
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

         os.exit(250)
      end
      if is_ready ~= "ready" then
         local msg = tostring(is_ready) or ""
         print("Bad message in draw_ready_channel: " .. msg)

         os.exit(249)
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
