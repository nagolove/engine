require("love")
require("common")

local gr = love.graphics

 Button = {}




















local Button_mt = {
   __index = Button,
}

function Button.new(title, x, y, w, h)
   local o = setmetatable({}, Button_mt)
   o.title = title
   o.x = x
   o.y = y
   o.w = w
   o.h = h
   o.bgColor = { 0.5, 0.1, 0. }
   return o
end

function Button:draw()
   local prevColor = { gr.getColor() }
   local prevFont = gr.getFont()
   love.graphics.setColor(self.bgColor)
   love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
   if self.font then
      gr.setFont(self.font)
   end
   gr.setColor(prevColor)
   gr.setFont(prevFont)
end

function Button:update(_)
   local mx, my = love.mouse.getPosition()

   if pointInRect(mx, my, self.x, self.y, self.w, self.h) then
      print("hovered")
   end
end


function Button:mouseReleased(_, _, _tn)
   if self.onMouseReleased then
      self:onMouseReleased()
   end
end

return Button
