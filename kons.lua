local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string







































require("love")
local g = love.graphics

local kons = {Item = {}, }

























local kons_mt = {}


kons_mt.__index = kons

function kons_mt.__call(self)
   return self.new()
end

function kons.new(fname, fsize)
   local font
   local size = fsize or 20
   if fname then
      font = love.graphics.newFont(fname, size)
   else
      font = love.graphics.newFont(size)
   end
   local inst = {
      font = font,
      color = { 1, 1, 1 },
      show = true,
      strings = {},
      strings_i = {},
      strings_num = 0,
      strings_i_num = 0,
   }
   return setmetatable(inst, kons_mt)
end

function kons:clear()
   self.strings_i = {}
   self.strings_i_num = 0
   self.strings = {}
   self.strings_num = 0
end

function kons:push2(lifetime, text, ...)
   if type(lifetime) ~= "number" then
      error("First argument - cardinal value of text lifetime.")
   end

   local processed = string.gsub(text, "(%%{(.-)})",
   function(str)
      print("processing", str)
      return str
   end)
   print("processed", processed)

   assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
   self.strings[self.strings_num + 1] = {
      text = string.format(text, ...),
      lifetime = lifetime,
      timestamp = love.timer.getTime(),
   }
   self.strings_num = self.strings_num + 1
   return self
end

function kons:push(lifetime, text, ...)
   if type(lifetime) ~= "number" then
      error("First argument - cardinal value of text lifetime.")
   end
   assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
   self.strings[self.strings_num + 1] = {
      text = string.format(text, ...),
      lifetime = lifetime,
      timestamp = love.timer.getTime(),
   }
   self.strings_num = self.strings_num + 1
   return self
end

function kons:pushi(text, ...)
   self.strings_i[self.strings_i_num + 1] = string.format(text, ...)
   self.strings_i_num = self.strings_i_num + 1
   return self
end

function kons:draw(x0, y0)
   x0 = x0 or 0
   y0 = y0 or 0

   if not self.show then return end

   local curColor = { g.getColor() }
   g.setColor(self.color)

   local oldFont = love.graphics.getFont()
   love.graphics.setFont(self.font)

   local y = y0
   for k, v in ipairs(self.strings_i) do
      g.print(v, x0, y)
      y = y + g.getFont():getHeight()
      self.strings_i[k] = nil
   end
   self.strings_i_num = 0

   for _, v in ipairs(self.strings) do
      g.print(v.text, x0, y)
      y = y + g.getFont():getHeight()
   end

   love.graphics.setFont(oldFont)
   g.setColor(curColor)

   self.height = math.abs(y - y0)
end

function kons:update()
   for k, v in ipairs(self.strings) do
      local time = love.timer.getTime()
      if v then
         v.lifetime = v.lifetime - (time - v.timestamp)
         if v.lifetime <= 0 then
            self.strings[k] = self.strings[self.strings_num]
            self.strings[self.strings_num] = nil
            self.strings_num = self.strings_num - 1
         else
            v.timestamp = time
         end
      end
   end
end





return kons
