require "love"

local joystick = love.joystick

local record DummyJoyState
    new: function(joystick.Joystick): DummyJoyState
    update: function(DummyJoyState)

    -- получить инфу о состоянии клавиш
    state: string
end

local DummyJoyState_mt: metatable<DummyJoyState> = {
    __index = DummyJoyState,
}

function DummyJoyState.new(_: joystick.Joystick): DummyJoyState
    local self = setmetatable({} as DummyJoyState, DummyJoyState_mt)
    self.state = ""
    return self
end

function DummyJoyState:update()
end

return DummyJoyState
