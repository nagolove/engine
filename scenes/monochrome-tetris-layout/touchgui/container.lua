local Container = {}

function Container:new()
    local o = {
        objects = {},
    }
    setmetatable(o, self)
    self.__index = self

    return o
end

function Container:add(obj)
    table.insert(self.objects, obj)
end

function Container:draw()
    for _, v in pairs(self.objects) do
        if v.draw then v:draw() end
    end
end

function Container:update()
    for _, v in pairs(self.objects) do
        if v.update then v:update(dt) end
    end
end

function Container:mousemoved(x, y, dx, dy, istouch)
    for _, v in pairs(self.objects) do
        if v.mousemoved then v:mousemoved(x, y, dx, dy, istouch) end
    end
end

function Container:mousepressed(x, y, button, istouch, presses)
    for _, v in pairs(self.objects) do
        if v.mousepressed then 
            v:mousepressed(x, y, button, istouch, presses)
        end
    end
end

function Container:touchpressed(id, x, y, dx, dy, pressure)
    for _, v in pairs(self.objects) do
        if v.touchpressed then
            v:touchpressed(id, x, y, dx, dy, pressure)
        end
    end
end

function Container:touchreleased(id, x, y, dx, dy, pressure)
    for _, v in pairs(self.objects) do
        if v.touchreleased then
            v:touchreleased(id, x, y, dx, dy, pressure)
        end
    end
end

function Container:touchmoved(id, x, y, dx, dy, pressure)
    for _, v in pairs(self.objects) do
        if v.touchmoved then
            v:touchmoved(id, x, y, dx, dy, pressure)
        end
    end
end

return Container
