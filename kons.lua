local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table







































require("love")
require("common")

local g = love.graphics


colorMap = {
   ["black"] = { 0, 0, 0, 1 },
   ["red"] = { 1, 0, 0, 1 },
   ["green"] = { 0, 1, 0, 1 },
   ["blue"] = { 0, 0, 1, 1 },
   ["white"] = { 1, 1, 1, 1 },
   ["default"] = { 1, 1, 1, 1 },
}

local kons = {Text = {}, Item = {}, }











































function kons.Text.new(unprocessed, ...)

   local Text_mt = {
      __index = kons.Text,
   }
   if not unprocessed then
      error("kons.Text.new() unprocessed should not be nil")
   end

   if type(unprocessed) ~= "string" and type(unprocessed) ~= 'table' then
      error("kons.Text.new() unprocessed type is " .. type(unprocessed))
   end
   local self = setmetatable({}, Text_mt)
   local tmp
   if type(unprocessed) == 'table' then

      self.linesnum = #(unprocessed)
      self.unprocessed = table.concat(unprocessed, "\n")
      tmp = string.gsub(
      self.unprocessed,
      "(%%{(.-)})",
      function(_)
         return ""
      end)

   elseif type(unprocessed) == 'string' then

      self.linesnum = 1
      self.unprocessed = unprocessed
      tmp = string.gsub(

      self.unprocessed,
      "(%%{(.-)})",
      function(_)
         return ""
      end)

   else
      error('Unsupported type: ' .. type(unprocessed))
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
      stringsi = {},
      textobj = love.graphics.newText(font),
   }
   return setmetatable(inst, kons_mt)

end

function kons:clear()

   self.stringsi = {}
   self.strings = {}
   self.textobj:clear()

end

function kons:push(lifetime, text, ...)

   if type(lifetime) ~= "number" then
      error("First argument - cardinal value of text lifetime.")
   end
   assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
   self.strings[#self.strings + 1] = {
      text = kons.Text.new(text, ...),
      lifetime = lifetime,
      timestamp = love.timer.getTime(),
   }

   return self

end

function kons:pushiColored(text, ...)



   local processed = string.gsub(text, "(%%{(.-)})",
   function(_)

      return ""
   end)


   self.stringsi[#self.stringsi + 1] = kons.Text.new(processed, ...)
   return self

end

function kons:pushi(text, ...)

   if type(text) == 'string' then
      self.stringsi[#self.stringsi + 1] = kons.Text.new(text, ...)
   elseif type(text) == 'table' then
      self.stringsi[#self.stringsi + 1] = kons.Text.new(text, ...)
   else
      error('Unsupported type ' .. type(text))
   end
   return self

end

function kons:draw(x0, y0)

   self.textobj:clear()

   x0 = x0 or 0
   y0 = y0 or 0

   if not self.show then return end

   local curColor = { g.getColor() }
   g.setColor(self.color)

   local oldFont = love.graphics.getFont()



   local y = y0

   local fontHeight = self.textobj:getFont():getHeight()

   for _, v in ipairs(self.strings) do


      self.textobj:add({ v.text.processed }, x0, y)

      y = y + fontHeight
   end





   for _, v in ripairs(self.stringsi) do
      local coloredtext = {}














      local istart, iend = 0, 0
      local init = 1


      istart, iend = string.find(v.unprocessed, "(%%{(.-)})", init)
      local leading
      if istart and istart >= 1 then
         leading = string.sub(v.unprocessed, 1, istart - 1)
         print('s0', leading)
      end

      table.insert(coloredtext, colorMap['default'])
      table.insert(coloredtext, v.processed)







































      self.textobj:add(coloredtext, x0, y)

      y = y + fontHeight * v.linesnum

   end

   love.graphics.draw(self.textobj, x0, y0)

   love.graphics.setFont(oldFont)
   g.setColor(curColor)

   self.height = math.abs(y - y0)
   self.stringsi = {}

end

function kons:update()

   for k, v in ipairs(self.strings) do
      local time = love.timer.getTime()
      if v then
         v.lifetime = v.lifetime - (time - v.timestamp)
         if v.lifetime <= 0 then
            self.strings[k] = self.strings[#self.strings]
            self.strings[#self.strings] = nil
         else
            v.timestamp = time
         end
      end
   end

end





return kons
