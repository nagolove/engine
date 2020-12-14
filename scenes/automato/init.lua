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

local commonSetup = {
    gridSize = 100,
    cellsNum = 2000,
    initialEnergy = {500, 1000},
    codeLen = 32,
    threadCount = 4,
}


local function getMode()
    return mode
end

function drawCells()
    --local drawlist = sim.getDrawList()
    local drawlist = sim.getDrawLists()
    if drawlist then
        for k, v in pairs(drawlist) do
            if v.food then
                gr.setColor(0, 1, 0)
                gr.rectangle("fill", (v.x - 1)* pixSize, (v.y - 1) * pixSize, pixSize, pixSize)
            else
                gr.setColor(0.5, 0.5, 0.5)
                gr.rectangle("fill", (v.x - 1)* pixSize, (v.y - 1) * pixSize, pixSize, pixSize)
            end
        end
    end
end

function drawGrid()
    gr.setColor(0.5, 0.5, 0.5)
    local gridSize = sim.getGridSize()
    local schema = sim.getSchema()
    if schema then
        for _, v in pairs(sim.getSchema()) do
            local dx, dy = v.draw[1] * pixSize * gridSize, v.draw[2] * pixSize * gridSize
            for i = 0, sim.getGridSize() do
                -- vert
                gr.line(dx + i * pixSize, dy + 0, dx + i * pixSize, dy + gridSize * pixSize)
                -- hor
                gr.line(dx + 0, dy + i * pixSize, dx + gridSize * pixSize, dy + i * pixSize)
            end
        end
    else
        local dx, dy = 0, 0
        for i = 0, sim.getGridSize() do
            -- vert
            gr.line(dx + i * pixSize, dy + 0, dx + i * pixSize, dy + gridSize * pixSize)
            -- hor
            gr.line(dx + 0, dy + i * pixSize, dx + gridSize * pixSize, dy + i * pixSize)
        end
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

local function drawui()
    imgui.Begin("sim", false, "ImGuiWindowFlags_AlwaysAutoResize")

    imgui.Text(string.format("mode %s", getMode()))

    if imgui.Button("change mode", getMode()) then
        nextMode()
    end

    if imgui.Button("reset silumation") then
        sim.create(commonSetup)
    end

    imgui.End()
end

local function draw()
    if viewState == "sim" then
        if mouseCapture then
            --cam:move(-mouseCapture.dx, -mouseCapture.dy)
        end

        cam:attach()
        drawGrid()
        drawCells()
        drawStatistic()
        cam:detach()
    elseif viewState == "graph" then
        drawGraphs()
    end
end

local function checkMouse()
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

local function updateGraphic()
    local statistic = sim.getStatistic()
    if not lastGraphicPoint then
        if statistic then
            lastGraphicPoint = {
                max = statistic.maxEnergy,
                mid = statistic.midEnergy,
                min = statistic.minEnergy,
            }
        end
    end
    local getIter = sim.getIter

    gr.setCanvas(graphCanvas)
    local w, h = graphCanvas:getDimensions()

    if lastGraphicPoint then
        if lastGraphicPoint.max then
            gr.setColor(MAX_ENERGY_COLOR)
            gr.line(getIter() - 1, h - lastGraphicPoint.max, 
            getIter(), h - statistic.maxEnergy)
        end

        if lastGraphicPoint.mid then
            gr.setColor(MID_ENERGY_COLOR)
            gr.line(getIter() - 1, h - lastGraphicPoint.mid, 
            getIter(), h - statistic.midEnergy)
        end

        if lastGraphicPoint.min then
            gr.setColor(MIN_ENERGY_COLOR)
            gr.line(getIter() - 1, h - lastGraphicPoint.min, 
            getIter(), h - statistic.minEnergy)
        end
    end

    gr.setCanvas()

    if statistic and statistic.maxEnergy and statistic.midEnergy and statistic.minEnergy then
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

local function nextMode()
    if mode == "continuos" then
        mode = "step"
    elseif mode == "step" then
        mode = "continuos"
    end
    sim.setMode(mode)
end

local function update()
    local dx, dy = 20, 20
    local isDown = love.keyboard.isDown
    if isDown("lshift") then
        if isDown("left") then
            cam:move(-dx, 0)
        elseif isDown("right") then
            cam:move(dx, 0)
        elseif isDown("up") then
            cam:move(0, -dy)
        elseif isDown("down") then
            cam:move(0, dy)
        end
    end
    --stepPressed = love.keyboard.isDown("s")

    sim.step()
    
    updateGraphic()
    checkMouse()
end

function setViewState(stateName)
    viewState = stateName
end

local function keypressed(key)
    if key == "1" then
        setViewState("sim")
    elseif key == "2" then
        setViewState("graph")
    end
    if key == "p" then
        nextMode()
    elseif key == "s" then
        sim.doStep()
    end
end

local function init(lvldata)
    if lvldata and lvldata.cam then
        cam.x, cam.y = lvldata.cam.x, lvldata.cam.y
        cam.scale = lvldata.cam.scale
        cam.rotate = lvldata.cam.rotate
    end
    math.randomseed(love.timer.getTime())

    sim.create(commonSetup)
    nextMode()
end

local function quit()
end

return {
    getPixSize = function()
        return pixSize
    end,
    getMode = getMode,
    nextMode = nextMode,
    cam = cam, 
    pworld = pworld,

    PIX2M = PIX2M,
    M2PIX = M2PIX,

    init = init,
    quit = quit,
    draw = draw,
    drawui = drawui,
    update = update,
    keypressed = keypressed,
}
