local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; require("love")

local colorize = require('ansicolors2').ansicolors
local joystick = love.joystick

 JoyState = {}















local JoyState_mt = {
   __index = JoyState,
}

function JoyState.new(joy)
   assert(joy, "joy should not be a nil")
   local self = setmetatable({}, JoyState_mt)
   self.joy = joy
   self.msg_prev = {}
   self.msg = {}
   self.pressed_prev = {}
   self.pressed = {}
   self.hat_prev = "c"
   self.hat = "c"
   return self
end

function JoyState:update()




   local axes = { self.joy:getAxes() }
   local chunks = {}
   self.msg_prev = self.msg
   self.msg = axes

   local msg = ""
   local colored_once = false
   for k, v in ipairs(self.msg) do
      if v == self.msg_prev[k] then
         msg = msg .. colorize('%{white}' .. tostring(v) .. ' ')
      else
         colored_once = true
         msg = msg .. colorize('%{red}' .. tostring(v) .. ' ')
      end
   end
   if colored_once then
      table.insert(chunks, msg .. '\n')
   end

   local buttons_num = self.joy:getButtonCount()
   local pressed = {}
   for i = 1, buttons_num do
      pressed[i] = self.joy:isDown(i)
   end

   self.pressed_prev = self.pressed
   self.pressed = pressed

   msg = ""
   colored_once = false
   for k, v in ipairs(self.pressed) do
      if v == self.pressed_prev[k] then
         msg = msg .. colorize('%{white}' .. tostring(v) .. ' ')
      else
         colored_once = true
         msg = msg .. colorize('%{red}' .. tostring(v) .. ' ')
      end
   end
   if colored_once then
      table.insert(chunks, 'pressed: ' .. msg .. '\n')
   end


   local hat_num = 1
   self.hat_prev = self.hat
   self.hat = self.joy:getHat(hat_num)

   colored_once = false
   msg = ''
   if self.hat_prev == self.hat then
      msg = msg .. colorize('%{white}' .. self.hat)
   else
      colored_once = true
      msg = msg .. colorize('%{red}' .. self.hat)
   end
   if colored_once then
      table.insert(chunks, 'hat direction: ' .. msg)
   end

   self.state = table.concat(chunks)
end

return JoyState
