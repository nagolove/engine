return {
    require_pls = function()
        require 'love.math'
        require 'love.keyboard'
        require "love.timer"
        require 'love.joystick'
        require 'love.mouse'
        require "love.event"
        require "love.thread"
        require "love.window"
        require "love.graphics"
        require "love.font"
    end,
    require_pls_nographic = function()
        require 'love.math'
        require 'love.keyboard'
        require "love.timer"
        require 'love.joystick'
        require 'love.mouse'
        require "love.event"
        require "love.thread"
        require "love.window"
        --require "love.graphics"
        require "love.font"
    end
}
