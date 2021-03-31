local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs
























































local ChannelsTypes = {
   "cellrequest",
   "data",
   "msg",
   "object",
   "ready",
   "request",
   "state",
}

for i, v in ipairs(ChannelsTypes) do
   print(i, v)
end



local Car = {}






local Car_mt = {
   __index = Car,
}

function Car.new()
   local self = {}
   return setmetatable(self, Car_mt)
end

function Car:draw()

   self.w = 0
end



local c1, c2 = Car.new(), Car.new()
c1:draw()
c2:draw()
