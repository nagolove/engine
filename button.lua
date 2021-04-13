



























































































local Button = {}
















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
   o.color = { 0.5, 0.1, 0. }
   return o
end

function Button:draw()
   love.graphics.setColor(self.color)
   love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Button:update(dt)

end

return Button
