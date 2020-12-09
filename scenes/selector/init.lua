local cam = require "camera".new()
local inspect = require "inspect"
local gr = love.graphics
local imgui = require "imgui"

print(package.path, package.path)
package.path = package.path .. ";../?.lua"

--local scenes = require "scenes"

--[[
   [local locScenes = {}
   [local gathered = false
   [local function gatherScenes()
   [    for k, v in pairs(scenes.getScenes()) do
   [        print(k, v)
   [        table.insert(locScenes, v)
   [    end
   [end
   ]]

local function draw()
    if not gathered then
        --gatherScenes()
    end
    --local num, selected = imgui.ListBox("scenes", selectedLevel, levels, #levels, 5)
end

local function update()
end

local function keypressed(key)
end

local function init(lvldata)
    if lvldata and lvldata.cam then
        cam.x, cam.y = lvldata.cam.x, lvldata.cam.y
        cam.scale = lvldata.cam.scale
        cam.rotate = lvldata.cam.rotate
    end
    math.randomseed(love.timer.getTime())
end

local function quit()
end

return {
    cam = cam, 

    PIX2M = PIX2M,
    M2PIX = M2PIX,

    init = init,
    quit = quit,
    draw = draw,
    update = update,
    keypressed = keypressed,
}
