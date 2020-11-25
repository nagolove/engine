local gr = love.graphics
local inspect = require "inspect"
local pworld, cam
local scene

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local engine = require "engine"

function init(currentScene)
    if currentScene and currentScene.pworld then
        pworld = currentScene.pworld
        scene = currentScene
        cam = currentScene.cam
        scene = scene
    end
end

local spread = 1

function drawParticleEditor()
    imgui.Begin("particles", true, "ImGuiWindowFlags_AlwaysAutoResize")
    local newspread, stat = imgui.SliderFloat("spread", spread, 0, 10, "%.3f", 8)
    spread = newspread
    --print("r1, r2", r1, r2)

    imgui.LabelText("emmision rate", engine.getEmissionRate())

    local value, ok = imgui.SliderFloat("scale", engine.getScale(), 0, 2)
    if ok then
        engine.setScale(value)
    end

    local value, ok = imgui.SliderFloat("x", engine.getX(), -100, 100)
    if ok then
        engine.setX(value)
    end

    local value, ok = imgui.SliderFloat("y", engine.getY(), -100, 100)
    if ok then
        engine.setY(value)
    end

    local value, ok = imgui.SliderFloat("image scale", engine.getImgScale(), 0, 2)
    if ok then
        engine.setImgScale(value)
    end


    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

return {
    init = init,
    draw = drawParticleEditor,
    update = update,
}


