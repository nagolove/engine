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

    x = math.floor(x / automatoScene.getPixSize())
    y = math.floor(y / automatoScene.getPixSize())
    print("mousemoved x, y", x, y)
    underCursor = {x = x, y = y}
end

local function getCellPositon(pos)
    --return nil
    local grid = sim.getGrid()
    print("pos", inspect(pos))
    local x, y = pos.x, pos.y
    if x >= 1 and x <= sim.getGridSize() and
        y >= 1 and y <= sim.getGridSize() then
        return grid[x][y]
    end

    print(pos.x, pos.y)
    return nil
end

local function drawCellInfo(cell)
    local msg
    imgui.Text(inspect(cell))
    if cell then
        if cell.pos and cell.pos.x and cell.pos.y then
            msg = string.format("%d, %d", cell.pos.x, cell.pos.y)
            imgui.LabelText("position", msg)
        end

        if cell.ip then
            msg = string.format("%d", cell.ip)
            imgui.LabelText("ip", msg)
        end

        if cell.code then
            msg = string.format("%d", #cell.code)
            imgui.LabelText("code length", msg)
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

    if underCursor then
        drawCellInfo(getCellPositon(underCursor))
    end

    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

function keypressed(key)
    if key == "p" then
        if __FREEZE_PHYSICS__ then
            __FREEZE_PHYSICS__ = not __FREEZE_PHYSICS__
        else
            __FREEZE_PHYSICS__ = true
        end
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
