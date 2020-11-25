
local gr = love.graphics
local inspect = require "inspect"
local pworld, cam
local scene

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

function init(currentScene)
    if currentScene and currentScene.pworld then
        pworld = currentScene.pworld
        scene = currentScene
        cam = currentScene.cam
        scene = scene
    end
end

function drawHotkeysInfo()
    imgui.Begin("dev hotkeys", true, "ImGuiWindowFlags_AlwaysAutoResize")
    imgui.Text("zoom out - 'x'")
    imgui.Text("zoom in - 'z'")
    imgui.Text("camera move - 'shift + arrows'")
    imgui.Text("freeze physics - 'p'")
    imgui.Text("--------------")
    --imgui.Text("undo drawing line - 'ctrl + z'")
    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

return {
    init = init,
    draw = drawHotkeysInfo,
    update = update,
}


