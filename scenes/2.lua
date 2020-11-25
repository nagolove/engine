local cam = require "camera".new()
local inspect = require "inspect"
local gr = love.graphics
local mouseCapture
local viewState = "sim"
local graphCanvas = gr.newCanvas(gr.getWidth() * 4, gr.getHeight())
local MAX_ENERGY_COLOR = {1, 0.5, 0.7, 1}
local MID_ENERGY_COLOR = {0.8, 0.3, 0.7, 1}
local MIN_ENERGY_COLOR = {0.6, 0.1, 1, 1}
local lastGraphicPoint
-- continuos, bystep
local mode = "continuos"
local stepPressed = false
local sim = require "simulator"
local pixSize = 10

function drawCells()
    for ik, i in pairs(sim.getGrid()) do
        for jk, j in pairs(i) do
            --print("j", inspect(j))
            --print(type(j.died))
            if j.died and type(j.died) == "boolean" and __SELECTED_COLOR__ then
                --print("__SELECTED_COLOR__", inspect(__SELECTED_COLOR__))
                gr.setColor(__SELECTED_COLOR__)
                gr.rectangle("fill", (ik - 1)* pixSize, (jk - 1) * pixSize, pixSize, pixSize)
            elseif j.food then
                gr.setColor(0, 1, 0)
                gr.rectangle("fill", (ik - 1)* pixSize, (jk - 1) * pixSize, pixSize, pixSize)
            elseif j.energy then
                gr.setColor(0.5, 0.5, 0.5)
                gr.rectangle("fill", (ik - 1)* pixSize, (jk - 1) * pixSize, pixSize, pixSize)
            end
        end
    end
end

function drawGrid()
    gr.setColor(0.5, 0.5, 0.5)
    local gridSize = sim.getGridSize()
    for i = 0, sim.getGridSize() do
        -- vert
        gr.line(i * pixSize, 0, i * pixSize, gridSize * pixSize)
        -- hor
        gr.line(0, i * pixSize, gridSize * pixSize, i * pixSize)
    end
end

function drawStatistic()
    local y0 = 0
    gr.setColor(1, 0, 0)
    gr.print(string.format("iteration %d", sim.getIter()), 0, y0)
    y0 = y0 + gr.getFont():getHeight()
    local statistic = sim.statistic
    if statistic then
        if statistic.maxEnergy then
            gr.setColor(1, 0, 0)
            gr.print(string.format("max energy in cell %d", statistic.maxEnergy), 0, y0)
            y0 = y0 + gr.getFont():getHeight()
        end
        if statistic.minEnergy then
            gr.setColor(1, 0, 0)
            gr.print(string.format("min energy in cell %d", statistic.minEnergy), 0, y0)
            y0 = y0 + gr.getFont():getHeight()
        end
        if statistic.midEnergy then
            gr.setColor(1, 0, 0)
            gr.print(string.format("mid energy in cell %d", statistic.midEnergy), 0, y0)
            y0 = y0 + gr.getFont():getHeight()
        end
    end
end

function drawAxises()
    gr.setColor(0, 1, 0)
    local w, h = gr.getDimensions()
    gr.setLineWidth(3)
    gr.line(0, h, 0, 0)
    gr.line(0, h, w, h)
    gr.setLineWidth(1)
end

function drawLegends()
    local y0 = 0

    gr.setColor(MAX_ENERGY_COLOR)
    gr.print("max energy", 0, y0)
    y0 = y0 + gr.getFont():getHeight()

    gr.setColor(MID_ENERGY_COLOR)
    gr.print("mid energy", 0, y0)
    y0 = y0 + gr.getFont():getHeight()

    gr.setColor(MIN_ENERGY_COLOR)
    gr.print("min energy", 0, y0)
    y0 = y0 + gr.getFont():getHeight()

end

function drawGraphs()
    drawAxises()
    drawLegends()
    gr.draw(graphCanvas)
end

local function draw()
    if viewState == "sim" then
        --gr.push()
        --if mouseCapture then
            --gr.translate(-mouseCapture.dx, -mouseCapture.dy)
        --end

        drawGrid()
        drawCells()
        drawStatistic()

        --gr.pop()
    elseif viewState == "graph" then
        drawGraphs()
    end
end

function checkMouse()
    if love.mouse.isDown(1) then
        if not mouseCapture then
            mouseCapture = { 
                x = love.mouse.getX(),
                y = love.mouse.getY(),
                dx = 0,
                dy = 0,
            }
        else
            mouseCapture.dx = mouseCapture.x - love.mouse.getX()
            mouseCapture.dy = mouseCapture.y - love.mouse.getY()
        end
    else
        mouseCapture = nil
    end
end

function updateGraphic()

    if not lastGraphicPoint then
        local statistic = sim.statistic
        if statistic then
            lastGraphicPoint = {
                max = statistic.maxEnergy,
                mid = statistic.midEnergy,
                min = statistic.minEnergy,
            }
        end
    end

    gr.setCanvas(graphCanvas)
    local w, h = graphCanvas:getDimensions()

    if lastGraphicPoint.max then
        gr.setColor(MAX_ENERGY_COLOR)
        gr.line(sim.getIter() - 1, h - lastGraphicPoint.max, 
        getIter(), h - statistic.maxEnergy)
    end

    if lastGraphicPoint.mid then
        gr.setColor(MID_ENERGY_COLOR)
        gr.line(sim.getIter() - 1, h - lastGraphicPoint.mid, 
        getIter(), h - statistic.midEnergy)
    end

    if lastGraphicPoint.min then
        gr.setColor(MIN_ENERGY_COLOR)
        gr.line(sim.getIter() - 1, h - lastGraphicPoint.min, 
        getIter(), h - statistic.minEnergy)
    end

    gr.setCanvas()

    local statistic = sim.statistic
    if statistic.maxEnergy and statistic.midEnergy and statistic.minEnergy then
        lastGraphicPoint = {
            max = statistic.maxEnergy,
            mid = statistic.midEnergy,
            min = statistic.minEnergy,
        }
    end
end

function drawFinishedExperiment()
    local y0 = 0
    gr.print(string.format("Finished"), 0, y0, 100, "center")
end

function nextMode(m)
    local r = ""
    if m == "continuos" then
        r = "bystep"
    elseif m == "bystep" then
        r = "continuos"
    end
    return r
end

local function update()
    stepPressed = love.keyboard.isDown("s")

    --if mode == "bystep" and stepPressed == true or mode == "continuos" then
        sim.step()
    --end
    --if err then
        --drawFinishedExperiment()
    --end
    updateGraphic()
    checkMouse()
end

function setViewState(stateName)
    viewState = stateName
end

love.keypressed = function(_, key)
    if key == "1" then
        setViewState("sim")
    elseif key == "2" then
        setViewState("graph")
    end
    if key == "p" then
        mode = nextMode(mode)
        print("new mode", mode)
    end
end

local function init(lvldata)
    if lvldata and lvldata.cam then
        cam.x, cam.y = lvldata.cam.x, lvldata.cam.y
        cam.scale = lvldata.cam.scale
        cam.rotate = lvldata.cam.rotate
    end
    math.randomseed(love.timer.getTime())
    sim.create()
end

local function quit()
end

return {
    cam = cam, 
    pworld = pworld,

    PIX2M = PIX2M,
    M2PIX = M2PIX,

    init = init,
    quit = quit,
    draw = draw,
    update = update,
    keypressed = keypressed,
}
