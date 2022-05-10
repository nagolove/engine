require "love"

local colorize = require 'ansicolors2'.ansicolors
local joystick = love.joystick

local record JoyState
    new: function(joystick.Joystick): JoyState
    update: function(JoyState)

    -- получить инфу о состоянии клавиш
    state: string

    joy: joystick.Joystick
    msg_prev: {number}
    msg: {number}
    pressed_prev: {boolean}
    pressed: {boolean}
    hat_prev: joystick.JoystickHat
    hat: joystick.JoystickHat
end

local JoyState_mt: metatable<JoyState> = {
    __index = JoyState,
}

function JoyState.new(joy: joystick.Joystick): JoyState
    assert(joy, "joy should not be a nil")
    local self = setmetatable({} as JoyState, JoyState_mt)
    self.joy = joy
    self.msg_prev = {}
    self.msg = {}
    self.pressed_prev = {}
    self.pressed = {}
    self.hat_prev = "c"
    self.hat = "c"
    return self
end

function JoyState:update()
    --if not self.joy then
        --return
    --end

    local axes = {self.joy:getAxes()}
    local chunks = {}
    self.msg_prev = self.msg
    self.msg = axes

    local msg = ""
    local colored_once = false
    for k, v in ipairs(self.msg) do
        if v == self.msg_prev[k] then
            msg = msg .. colorize('%{white}' .. tostring(v) .. ' ')
        else
            colored_once = true
            msg = msg .. colorize('%{red}' ..tostring(v) .. ' ')
        end
    end
    if colored_once then
        table.insert(chunks, msg .. '\n')
    end

    local buttons_num = self.joy:getButtonCount()
    local pressed = {}
    for i = 1, buttons_num do
        pressed[i] = self.joy:isDown(i)
    end

    self.pressed_prev = self.pressed
    self.pressed = pressed

    msg = ""
    colored_once = false
    for k, v in ipairs(self.pressed) do
        if v == self.pressed_prev[k] then
            msg = msg .. colorize('%{white}' ..tostring(v) .. ' ')
        else
            colored_once = true
            msg = msg .. colorize('%{red}' ..tostring(v) .. ' ')
        end
    end
    if colored_once then
        table.insert(chunks, 'pressed: ' .. msg .. '\n')
    end

    -- Здесь подсветка кажется не работает как нужно
    local hat_num = 1
    self.hat_prev = self.hat
    self.hat = self.joy:getHat(hat_num)

    colored_once = false
    msg = ''
    if self.hat_prev == self.hat then
        msg = msg .. colorize('%{white}' .. self.hat)
    else
        colored_once = true
        msg = msg .. colorize('%{red}' .. self.hat)
    end
    if colored_once then
        table.insert(chunks, 'hat direction: ' .. msg)
    end

    self.state = table.concat(chunks)
end

return JoyState
