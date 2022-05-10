require("love")

local joystick = love.joystick

local DummyJoyState = {}







local DummyJoyState_mt = {
   __index = DummyJoyState,
}

function DummyJoyState.new(_)
   local self = setmetatable({}, DummyJoyState_mt)
   self.state = ""
   return self
end

function DummyJoyState:update()
end

return DummyJoyState
