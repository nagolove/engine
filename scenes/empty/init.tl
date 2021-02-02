require "love"
love.filesystem.setRequirePath("?.lua;scenes/empty/?.lua")

--require "external"
--require "common"

--package.path = package.path .. ";scenes/automato/?.lua"

--local cam = require "camera".new()
local gr = love.graphics
--local imgui = require "imgui"
--local inspect = require "inspect"
--local keyconfig = require "keyconfig"
--local mtschemes = require "mtschemes"
--local next = next
--local sim = require "simulator"
--local timer = require "Timer"

local function drawui()
end

local function draw()
    gr.clear(0.5, 0.5, 0.5)
    gr.setColor{0, 0, 0}
    gr.print("TestTest")
end

local function update(dt: number)
end

local function keypressed(key: string)
    if key == "escape" then
        love.event.quit()
    end
end

local function init()
end

local function quit()
end

local function mousemoved(x: number, y: number, _: number, _: number)
end

local function wheelmoved(x: number, y: number)
end

return {
    init = init,
    quit = quit,
    draw = draw,
    drawui = drawui,
    update = update,
    keypressed = keypressed,
    mousemoved = mousemoved,
    wheelmoved = wheelmoved
}


