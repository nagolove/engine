local inspect = require "inspect"
local cells = {}
local grid = {}
local gridSize = 100
local pixSize = 10
local gr = love.graphics
local codeLen = 32
local cellsNum = 2000
local actions = {}
local initialEnergy = {500, 1000}
local statistic = {}
local iter = 0
local codeValues = {
    "left",
    "right",
    "up",
    "down",
    "checkAndEat",
}
local mouseCapture
local viewState = "sim"
local graphCanvas = gr.newCanvas(gr.getWidth() * 4, gr.getHeight())
local MAX_ENERGY_COLOR = {1, 0.5, 0.7, 1}
local MID_ENERGY_COLOR = {0.8, 0.3, 0.7, 1}
local MIN_ENERGY_COLOR = {0.6, 0.1, 1, 1}
local lastGraphicPoint
local removed = {}

function genCode()
    local code = {}
    local len = #codeValues
    for i = 1, 32 do
        table.insert(code, codeValues[math.random(1, len)])
    end
    return code
end

function initCell()
    local self = {}
    self.pos = {}
    self.pos.x = math.random(1, gridSize)
    self.pos.y = math.random(1, gridSize)
    self.code = genCode()
    self.ip = 1
    self.energy = math.random(initialEnergy[1], initialEnergy[2])
    self.mem = {}
    return self
end

function isAlive(x, y)
    local t = grid[x][y]
    return t.energy and t.energy > 0
end

function actions.left(cell)
    pos = cell.pos
    --print("left", grid[pos.x - 1][pos.y])
    if pos.x > 1 and not isAlive(pos.x - 1, pos.y) then
        pos.x = pos.x - 1
    end
end

function actions.right(cell)
    pos = cell.pos
    --print("right", grid[pos.x + 1][pos.y])
    if pos.x < gridSize and not isAlive(pos.x + 1, pos.y) then
        pos.x = pos.x + 1
    end
end

function actions.up(cell)
    pos = cell.pos
    --print("up", grid[pos.x][pos.y - 1])
    if pos.y > 1 and not isAlive(pos.x, pos.y - 1) then
        pos.y = pos.y - 1
    end
end

function actions.down(cell)
    pos = cell.pos
    --print("down", grid[pos.x][pos.y + 1])
    if pos.y < gridSize and not isAlive(pos.x, pos.y + 1) then
        pos.y = pos.y + 1
    end
end

-- непонятно куда выкладывать значения из стека.
-- либо другие функции должны напрямую работать со стеком или
-- должны быть регистры в виде переменных внутри клетки.
function actions.popmem_pos(cell)
end

function actions.pushmem_pos(cell)
    table.insert(cell.mem, cell.pos.x)
    table.insert(cell.mem, cell.pos.y)
end

function copy(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

local around = {
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1, 0},
    {-1,  1}, {0, -1}, {1, 1},
}

-- функция питания
function actions.checkAndEat(cell)
    pos = cell.pos
    for k, v in pairs(around) do
        local newt = copy(pos)
        local displacement = around[math.random(1, #around)]
        newt.x = newt.x + displacement[1]
        newt.y = newt.y + displacement[2]

        if newt.x >= 1 and newt.x < gridSize and
            newt.y >= 1 and newt.y < gridSize then
            local dish = grid[newt.x][newt.y]
            if dish.enery and dish.energy > 0 then
                dish.energy = 0
                cell.energy = cell.energy + 10
                return
            end
        end
    end
end

-- возвращает [boolean], [cell table]
-- isalive, cell
function updateCell(cell)
    if cell.ip > codeLen then
        cell.ip = 1
    end
    if cell.energy > 0 then
        actions[cell.code[cell.ip]](cell)
        cell.ip = cell.ip + 1
        cell.energy = cell.energy - 1
        return true, cell
    else
        return false, cell
    end
end

function drawCells()
    for ik, i in pairs(grid) do
        for jk, j in pairs(i) do
            if j.energy then
                gr.rectangle("fill", (ik - 1)* pixSize, (jk - 1) * pixSize, pixSize, pixSize)
            end
        end
    end
end

function drawGrid()
    gr.setColor(0.5, 0.5, 0.5)
    for i = 0, gridSize do
        -- vert
        gr.line(i * pixSize, 0, i * pixSize, gridSize * pixSize)
        -- hor
        gr.line(0, i * pixSize, gridSize * pixSize, i * pixSize)
    end
end

function drawStatistic()
    local y0 = 0
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

love.draw = function()
    if mouseCapture then
        gr.translate(-mouseCapture.dx, -mouseCapture.dy)
    end

    if viewState == "sim" then
        drawGrid()
        drawCells()
        drawStatistic()
    elseif viewState == "graph" then
        drawGraphs()
    end
end

function getFalseGrid()
    local res = {}
    for i = 1, gridSize do
        local t = {}
        for j = 1, gridSize do
            t[#t + 1] = {}
        end
        res[#res + 1] = t
    end
    return res
end

function updateGrid()
    for k, v in pairs(cells) do
        grid[v.pos.x][v.pos.y] = v
    end
end

function gatherStatistic()
    local maxEnergy = 0
    local minEnergy = initialEnergy[2]
    local sumEnergy = 0
    for _, v in pairs(cells) do
        if v.energy > maxEnergy then
            maxEnergy = v.energy
        end
        if v.energy < minEnergy then
            minEnergy = v.energy
        end
        sumEnergy = sumEnergy + v.energy
    end
    local num = #cells > 0 and #cells or 1
    if sumEnergy == 0 then
        sumEnergy = 1
    end
    print("num, midEnergy", num, sumEnergy)
    return { 
        maxEnergy = maxEnergy,
        minEnergy = minEnergy,
        midEnergy = sumEnergy / #cells,
    }
end

local secondEmit = false

function emitCellInRandomPoint()
    local x = math.random(1, gridSize)
    local y = math.random(1, gridSize)
    local t = grid[x][y]
    if not t.energy then
        --print("put cell at", x, y)
        grid[x][y] = initCell()
    end
end

function emit()
    --if #cells < cellsNum / 3 then
        --if not secondEmit then
            --secondEmit = true
            --for i = 1, cellsNum do
                --local x = math.random(1, gridSize)
                --local y = math.random(1, gridSize)
                --local t = grid[x][y]
                --if not t.energy then
                    --print("put cell at", x, y)
                    --grid[x][y] = initCell()
                --end
            --end
            --print("pasted")
        --end
    --end
    
    --for i = 1, 100 do
        --emitCellInRandomPoint()
    --end
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
        lastGraphicPoint = {
            max = statistic.maxEnergy,
            mid = statistic.midEnergy,
            min = statistic.minEnergy,
        }
    end

    gr.setCanvas(graphCanvas)
    local w, h = graphCanvas:getDimensions()

    gr.setColor(MAX_ENERGY_COLOR)
    gr.line(iter - 1, h - lastGraphicPoint.max, iter, h - statistic.maxEnergy)

    gr.setColor(MID_ENERGY_COLOR)
    gr.line(iter - 1, h - lastGraphicPoint.mid, iter, h - statistic.midEnergy)

    gr.setColor(MIN_ENERGY_COLOR)
    gr.line(iter - 1, h - lastGraphicPoint.min, iter, h - statistic.minEnergy)

    gr.setCanvas()

    lastGraphicPoint = {
        max = statistic.maxEnergy,
        mid = statistic.midEnergy,
        min = statistic.minEnergy,
    }
end

function saveRemovedLog()
    local file = io.open("removed-cell.txt", "w")
    for _, cell in pairs(removed) do
        file.write(string.format("pos %d, %d", cell.pos.x, cell.pos.y))
        file.write(string.format("energy %d", cell.energy))
        file.write(string.format("ip %d", cell.ip))
        file.write(string.format("code:"))
        for _, codeline in pairs(cell.code) do
            file.write(string.format("  %s", codeline))
        end
    end
    file.close()
end

love.update = function()
    local alive = {}
    for k, cell in pairs(cells) do
        local isalive, c = updateCell(cell)
        if isalive then
            table.insert(alive, c)
        else
            table.insert(removed, c)
        end
    end
    cells = alive

    grid = getFalseGrid()
    emit()
    updateGrid()
    statistic = gatherStatistic()
    iter = iter + 1

    updateGraphic()

    checkMouse()
end

function initialEmit()
    for i = 1, cellsNum do
        local c = initCell()
        table.insert(cells, c)
    end
end

function love.load()
    math.randomseed(love.timer.getTime())
    initialEmit()
    grid = getFalseGrid()
    updateGrid()
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
end
