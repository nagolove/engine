local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local table = _tl_compat and _tl_compat.table or table





require("vector")

local lt = love.timer
local lg = love.graphics
local inspect = require("inspect")
local linesbuf = require("kons").new()


local blks = nil

local Block = {}






























local Callback = {}

local Block_mt = {
   __index = Block,
}









function randomRange(min, max)
   return min + (max - min) * math.random()
end


function Block.new(x, y)
   local self = setmetatable({
      x = x,
      y = y,
      angle = 0,
      color = { randomRange(0.6, 1), randomRange(0.6, 1),
randomRange(0.6, 1), 1, },
      exposition = randomRange(300, 1000),
   }, Block_mt)




   self.actions = {
      self.processEliminate,
      self.setupEliminate,
      self.processToCorner,
      self.setupCorner,
      self.processRotation,
      self.setupAngle,
      self.processToCenter,
   }
   self.action = self.actions[#self.actions]

   if not blks then
      blks = self
      self.prev = nil
      self.next = nil
   else

      local n = blks
      while n.next do
         n = n.next
      end
      self.next = nil
      self.prev = n
      n.next = self
   end

   linesbuf:push(2, "Block:new(%d, %d)", x, y)
   return self
end

function Block:setupAngle(_)

   local rotationVelocity = randomRange(0.6, 1)
   self.zeroAngle = self.angle
   self.angleDelta = math.random() and rotationVelocity or -rotationVelocity


   return false
end

function Block:processRotation(dt)
   local ret = false




   if math.abs(self.angle - self.zeroAngle) < math.pi * 2 then
      self.angle = self.angle + self.angleDelta * dt
      ret = true

   end
   return ret
end


function Block:processToCenter(dt)





   local ret = false
   local w, h = lg.getDimensions()
   local range = 50
   w, h = w + randomRange(-range, range), h + randomRange(-range, range)

   local speed = 50

   local pos = vector.new(self.x, self.y)

   local to = vector.new(w / 2, h / 2)

   local dir = (to - pos):normalizeInplace()

   if (to - pos):len() > 1 then
      pos = pos + dir * (dt * speed)
      self.x, self.y = pos:unpack()
      ret = true
   end

   return ret
end

function Block:setupCorner(_)
   local w, h = lg.getDimensions()
   local x, y = randomRange(0, w), randomRange(0, h)

   if math.random() > 0.5 then
      x = 0
   else
      y = 0
   end
   self.toCorner = vector.new(x, y)
   return false
end

function Block:processToCorner(dt)
   local ret = false
   local speed = 70
   local pos = vector.new(self.x, self.y)
   local to = self.toCorner
   local dir = (to - pos):normalizeInplace()
   if (to - pos):len() > 1 then
      pos = pos + dir * (dt * speed)
      self.x, self.y = pos:unpack()
      ret = true
   end
   return ret
end

function Block:setupEliminate(_)
   self.timestamp = love.timer.getTime()
   self.alphaDelta = self.color[4] / self.exposition
   return false
end

function Block:processEliminate(_)
   local ret = false
   local time = lt.getTime()
   if time - self.timestamp < self.exposition then
      self.color[4] = self.color[4] - self.alphaDelta
      ret = true
   end

   return ret
end

function Block:draw()
   local w, h = lg.getDimensions()
   local rw = 32
   local halfrw = rw / 2

   lg.setColor({ 1, 1, 1 })
   lg.line(0, h / 2, w, h / 2)
   lg.line(w / 2, 0, w / 2, h)

   lg.push("transform")

   lg.translate(self.x, self.y)
   lg.rotate(self.angle)
   lg.translate(-self.x, -self.y)

   lg.setColor(self.color)
   lg.rectangle("fill", self.x - halfrw, self.y - halfrw, rw, rw)

   lg.setColor({ 0, 0, 1 })
   lg.circle("fill", self.x - halfrw, self.y - halfrw, 3)

   lg.pop()

   lg.setColor({ 0, 0.9, 0 })
   lg.circle("fill", self.x, self.y, 3)
end

function Block:processActions(dt)
   if self.action and not self:action(dt) then


      if #self.actions >= 1 then
         table.remove(self.actions)
         self.action = self.actions[#self.actions]
         print("remove")

      else



         print("remove me!")
         if not self.next and self.prev then
            local prev = self.prev
            prev.next = nil
            self = nil
         elseif not self.prev then
            blks = nil
            self = nil
         else
            local prev2 = self.prev
            local next2 = self.next
            prev2.next = self.next
            next2.prev = self.prev
            self = nil
            print("removed self from center")
         end
      end
   end
end

function Block:update(dt)
   self:processActions(dt)
end

local function init()
   math.randomseed(os.clock())
end

local function draw()
   if blks then
      local n = blks
      while n.next do
         n:draw()
         n = n.next
      end
   end
   linesbuf:pushi("FPS %d", love.timer.getFPS())
   linesbuf:draw()
end

local function update(dt)
   if blks then
      local n = blks
      while n.next do
         n:update(dt)
         n = n.next
      end
   end
   if love.mouse.isDown(1) then

   end
   linesbuf:update()
end

local function mousemoved(x, y)


   linesbuf:push(2, "mousepressed(%d, %d)", x, y)
   if love.mouse.isDown(1) then
      Block.new(love.mouse.getPosition())
   end
end

return {
   init = init,
   draw = draw,
   update = update,
   mousemoved = mousemoved,
}
