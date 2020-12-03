require "log"
local sim = require "simulator"
local gr = love.graphics
local inspect = require "inspect"
local cam
local scene

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local scalePoint2CameraWorldCoords = scale.point2CameraWorldCoords
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local automatoScene = require "scenes/automato/init"
local underCursor = {}

local shapePoint

local function init(currentScene)
    log("Init cell tool.")
    if currentScene and currentScene.pworld then
        pworld = currentScene.pworld
        scene = currentScene
        cam = scene.cam
        scene = scene
    end
    local mx, my = love.mouse.getPosition()
    underCursor = {x = mx, y = my}
end

local function drawBodyVectors(body)
    local masscx, masscy, _, _ = body:getMassData()
    masscx, masscy = body:getWorldPoints(masscx, masscy)
    masscx, masscy = M2PIX * masscx, M2PIX * masscy

    gr.setColor{1, 0, 0}
    gr.circle("fill", masscx, masscy, 3)

    local vx, vy = body:getLinearVelocity()

    gr.setColor(0.7, 0, 0)
    gr.line(masscx, masscy, masscx + vx, masscy + vy)
end

local function mousemoved(x, y, dx, dy)
    local w, h = gr.getDimensions()
    local tlx, tly, brx, bry = 0, 0, w, h

    if cam then
        tlx, tly = cam:worldCoords(tlx, tly)
        brx, bry = cam:worldCoords(brx, bry)
    end

    underCursor = {
        x = math.floor(x / automatoScene.getPixSize()),
        y = math.floor(y / automatoScene.getPixSize())
    }
end

local function getCellPositon(pos)
    local grid = sim.getGrid()
    local x, y = pos.x, pos.y
    if x + 1 >= 1 and x + 1 <= sim.getGridSize() and
        y + 1 >= 1 and y + 1 <= sim.getGridSize() then
        return grid[x + 1][y + 1]
    end

    print(pos.x, pos.y)
    return nil
end

local function replaceCaret(str)
    return string.gsub(str, "\n", "")
end

local function drawCellInfo(cell)
    if not cell then
        return
    end

    local msg
    for k, v in pairs(cell) do
        if k ~= "code" then
            local fmt 
            local functor = function(a) return a end
            local tp = type(v)
            if tp == "number" then
                fmt = "%d"
            elseif tp == "table" then
                fmt = "%s"
                functor = function(a)
                    return replaceCaret(inspect(a))
                end
            else
                fmt = "%s"
                functor = tostring
            end
            msg = string.format(fmt, functor(v))
            imgui.LabelText(k, msg)
        end
    end
end

local function draw()
    imgui.Begin("cell", false, "ImGuiWindowFlags_AlwaysAutoResize")

    imgui.Text(string.format("mode %s", automatoScene.getMode()))

    if imgui.Button("change mode", automatoScene.getMode()) then
        automatoScene.nextMode()
    end

    if imgui.Button("reset silumation") then
        sim.create()
    end

    if sim.statistic and sim.statistic.allEated then
        print("statistic", inspect(sim.statistic))
        imgui.LabelText(sim.statistic.allEated, "all eated")
    end

    if underCursor then
        drawCellInfo(getCellPositon(underCursor))
    end

    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

function keypressed(key)
    if key == "p" then
    end
end

function update()
    local isDown = love.keyboard.isDown
    if isDown("z") then
        cam:zoom(1.01)
    elseif isDown("x") then
        cam:zoom(0.99)
    end
end

return {
    init = init,
    draw = draw,
    update = update,
    mousemoved = mousemoved,
    keypressed = keypressed,
}
