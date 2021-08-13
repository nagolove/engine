local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table







































require("love")
require("common")

local g = love.graphics

local kons = {Text = {}, Item = {}, }














































function kons.Text.new(unprocessed, ...)

   local Text_mt = {
      __index = kons.Text,
   }
   if not unprocessed then
      error("kons.Text.new() unprocessed should not be nil")
   end
   print(type(unprocessed))

   if type(unprocessed) ~= "string" and type(unprocessed) ~= 'table' then
      error("kons.Text.new() unprocessed type is " .. type(unprocessed))
   end
   local self = setmetatable({}, Text_mt)
   local tmp
   if type(unprocessed) == 'table' then
      self.linesnum = #(unprocessed)
      tmp = string.gsub(
      table.concat(unprocessed, "\n"),
      "(%%{(.-)})",
      function(str) return str end)

   else
      self.linesnum = 1
      tmp = string.gsub(

      tostring(unprocessed),
      "(%%{(.-)})",
      function(str) return str end)

   end




   self.processed = string.format(tmp, ...)
   return self

end

function kons.new(fname, fsize)

   local kons_mt = {
      __index = kons,
      __call = function(self)
         return self.new()
      end,
   }

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



























function kons:push(lifetime, text, ...)

   if type(lifetime) ~= "number" then
      error("First argument - cardinal value of text lifetime.")
   end
   assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
   self.strings[self.strings_num + 1] = {
      text = kons.Text.new(text, ...),
      lifetime = lifetime,
      timestamp = love.timer.getTime(),
   }
   self.strings_num = self.strings_num + 1
   return self

end

function kons:pushiColored(text, ...)



   local processed = string.gsub(text, "(%%{(.-)})",
   function(_)

      return ""
   end)


   self.strings_i[self.strings_i_num + 1] = kons.Text.new(processed, ...)
   self.strings_i_num = self.strings_i_num + 1
   return self

end

function kons:pushi(text, ...)

   if type(text) == 'string' then
      self.strings_i[self.strings_i_num + 1] = kons.Text.new(text, ...)
      self.strings_i_num = self.strings_i_num + 1
   else
      self.strings_i[self.strings_i_num + 1] = kons.Text.new(text, ...)
      self.strings_i_num = self.strings_i_num + 1
   end
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

   for _, v in ipairs(self.strings) do
      g.print(v.text.processed, x0, y)
      y = y + g.getFont():getHeight()
   end


   for k, v in ripairs(self.strings_i) do









      g.print(v.processed, x0, y)
      y = y + g.getFont():getHeight() * v.linesnum
      self.strings_i[k] = nil
   end
   self.strings_i_num = 0

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
