local inspect = require "inspect"
-- массив всех клеток
local cells = {}
-- массив массивов [x][y] с клетками по индексам
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
local experimentCoro
local actionsModule = require "cell-actions"
local actions
local meal = {}
-- continuos, bystep
local mode = "continuos"
local stepPressed = false

function genCode()
    local code = {}
    local len = #codeValues
    for i = 1, 32 do
        table.insert(code, codeValues[math.random(1, len)])
    end
    return code
end

-- обнаружена проблема между соотношением положения клетки в initCell()
-- и emit(). Нужно выработать интерфейс создания клетки который не будет
-- нарушать структуры grid
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
            if j.food then
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

-- заполнить решетку пустыми значениями. В качестве значений используются
-- пустые таблицы {}
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
    for _, v in pairs(cells) do
        grid[v.pos.x][v.pos.y] = v
    end
    for _, v in pairs(meal) do
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
    --print("num, midEnergy", num, sumEnergy)
    return { 
        maxEnergy = maxEnergy,
        minEnergy = minEnergy,
        midEnergy = sumEnergy / #cells,
    }
end

-- записывает в решетку grid значение еды
function initFood()
    local self = {}
    self.food = true
    table.insert(meal, self)
    return self
end

-- возвращает true если получилось создать еду на случайной позиции
function emitFoodInRandomPoint()
    local x = math.random(1, gridSize)
    local y = math.random(1, gridSize)
    local t = grid[x][y]
    if not t.energy then
        local food = initFood()
        food.pos = {}
        food.pos.x, food.pos.y = x, y
        grid[x][y] = food
    end
end

function emit()
    for i = 1, 3 do
        emitFoodInRandomPoint()
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
        --print("lastGraphicPoint")
        lastGraphicPoint = {
            max = statistic.maxEnergy,
            mid = statistic.midEnergy,
            min = statistic.minEnergy,
        }
        --print("lastGraphicPoint", inspect(lastGraphicPoint))
        --print("statistic", inspect(statistic))
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

function saveDeadCellsLog(cells)
    local file = io.open("removed-cells.txt", "w")
    for _, cell in pairs(cells) do
        file:write(string.format("pos %d, %d\n", cell.pos.x, cell.pos.y))
        file:write(string.format("energy %d\n", cell.energy))
        file:write(string.format("ip %d\n", cell.ip))
        file:write(string.format("code:\n"))
        for _, codeline in pairs(cell.code) do
            file:write(string.format("  %s\n", codeline))
        end
        file:write("\n")
    end
    file:close()
end

function updateCells()
    local alive = {}
    for k, cell in pairs(cells) do
        local isalive, c = updateCell(cell)
        if isalive then
            table.insert(alive, c)
        else
            table.insert(removed, c)
        end
    end
    return alive
end

function experiment()
    math.randomseed(love.timer.getTime())
    initialEmit()
    grid = getFalseGrid()
    updateGrid()
    statistic = gatherStatistic()

    coroutine.yield()

    while #cells > 0 do
        if mode == "bystep" and stepPressed == true or mode == "continuos" then
            -- проход по ячейкам и вызов их программ
            cells = updateCells()

            -- сброс решетки после уничтожения некоторых клеток
            grid = getFalseGrid()

            -- создать сколько-то еды
            emit()

            -- обновление решетки по списку живых клеток
            updateGrid()

            statistic = gatherStatistic()
            iter = iter + 1

            if stepPressed == true then
                stepPressed = false
            end
        end
        coroutine.yield()
    end

    saveDeadCellsLog(removed)
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

love.update = function()
    stepPressed = love.keyboard.isDown("s")

    local err = coroutine.resume(experimentCoro)
    --if err then
        --drawFinishedExperiment()
    --end
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
    experimentCoro = coroutine.create(function()
        local ok, errmsg = pcall(experiment)
        if not ok then
            print(string.format("Error %s", errmsg))
        end
    end)
    coroutine.resume(experimentCoro)
    actionsModule.init(grid, gridSize)
    actions = actionsModule.actions
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
