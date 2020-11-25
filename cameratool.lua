local gr = love.graphics
local inspect = require "inspect"
local cam

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

function init(currentScene)
    --print("cam", currentScene.cam)
    --print("pworld", pworld)
    --print("currentScene", inspect(currentScene))
    if currentScene then
        cam = currentScene.cam
    end
end

function drawCameraInfo()
    imgui.Begin("camera", true, "ImGuiWindowFlags_AlwaysAutoResize")
    if cam then
        imgui.LabelText("x, y", string.format("%f, %f", cam.x, cam.y))
        imgui.LabelText("rot", string.format("%f", cam.rot))
        imgui.LabelText("scale", string.format("%f", cam.scale))
    end

    if imgui.Button("reset scale") and cam then
        cam.scale = 1
    end

    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

local function update()
    local isDown = love.keyboard.isDown
    if cam then
        local camSpeed = 25 / cam.scale

        if isDown("lshift") then
            if isDown("left") then
                cam:move(-camSpeed, 0)
            elseif isDown("up") then
                cam:move(0, -camSpeed)
            elseif isDown("right") then
                cam:move(camSpeed, 0)
            elseif isDown("down") then
                cam:move(0, camSpeed)
            end
        end

        if isDown("z") then
            cam:zoom(1.01)
        elseif isDown("x") then
            cam:zoom(0.99)
        end
    end
end

return {
    init = init,
    draw = drawCameraInfo,
    update = update,
    mousemoved = mousemoved,
}


