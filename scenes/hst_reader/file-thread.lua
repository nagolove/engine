local arg = ...
require "love.timer"
require "external"
local inspect = require "inspect"
local serpent = require "serpent"

print(arg, inspect(arg))

local fname = love.thread.getChannel("fname"):pop()

--[[
-- Полностью загружает файл в память
--]]
local function firstRead()
end

local function secondRead()
end

firstRead()

while true do
    love.timer.sleep(0.1)
end
