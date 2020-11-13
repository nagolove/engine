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
    "eat",
    "check",
}
local mouseCapture

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

function actions.eat(cell)
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

function actions.check(cell)
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

function updateCell(cell)
    if cell.ip > codeLen then
        cell.ip = 1
    end
    if cell.energy > 0 then
        actions[cell.code[cell.ip]](cell)
        cell.ip = cell.ip + 1
        cell.energy = cell.energy - 1
        return cell
    else
        return nil
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

love.draw = function()
    if mouseCapture then
        gr.translate(-mouseCapture.dx, -mouseCapture.dy)
    end

    drawGrid()
    drawCells()
    drawStatistic()
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
    return { 
        maxEnergy = maxEnergy,
        minEnergy = minEnergy,
        midEnergy = sumEnergy / #cells,
    }
end

function emit()
end

function dist(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

love.update = function()
    local alive = {}
    for k, cell in pairs(cells) do
        table.insert(alive, updateCell(cell))
    end
    cells = alive

    grid = getFalseGrid()
    updateGrid()
    statistic = gatherStatistic()
    iter = iter + 1

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
