local inspect = require "inspect"
local cells = {}
local grid = {}
local gridSize = 100
local pixSize = 10
local gr = love.graphics
local codeLen = 32
local cellsNum = 100
local actions = {}

local codeValues = {
    "left",
    "right",
    "up",
    "down",
    "eat",
    "check",
}

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
    self.state = "alive"
    self.code = genCode()
    self.ip = 1
    self.energy = 100
    return self
end

function actions.left(cell)
    pos = cell.pos
    --print("left", grid[pos.x - 1][pos.y])
    if pos.x > 1 and not grid[pos.x - 1][pos.y] then
        pos.x = pos.x - 1
    end
end

function actions.right(cell)
    pos = cell.pos
    --print("right", grid[pos.x + 1][pos.y])
    if pos.x < gridSize and not grid[pos.x + 1][pos.y] then
        pos.x = pos.x + 1
    end
end

function actions.up(cell)
    pos = cell.pos
    --print("up", grid[pos.x][pos.y - 1])
    if pos.y > 1 and not grid[pos.x][pos.y - 1] then
        pos.y = pos.y - 1
    end
end

function actions.down(cell)
    pos = cell.pos
    --print("down", grid[pos.x][pos.y + 1])
    if pos.y < gridSize and not grid[pos.x][pos.y + 1] then
        pos.y = pos.y + 1
    end
end

function actions.eat(cell)
end

function actions.check(cell)
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
    -- grid[xvalue][yvalue] = true
    for ik, i in pairs(grid) do
        for jk, j in pairs(i) do
            if j == true then
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

love.draw = function()
    drawGrid()
    drawCells()
end

function getFalseGrid()
    local res = {}
    for i = 1, gridSize do
        local t = {}
        for j = 1, gridSize do
            t[#t + 1] = false
        end
        res[#res + 1] = t
    end
    return res
end

function updateGrid()
    for k, v in pairs(cells) do
        grid[v.pos.x][v.pos.y] = true
    end
end

love.update = function()
    local alive = {}
    for k, cell in pairs(cells) do
        table.insert(alive, updateCell(cell))
    end
    cells = alive

    grid = getFalseGrid()
    updateGrid()
end

function love.load()
    math.randomseed(love.timer.getTime())
    for i = 1, cellsNum do
        local c = initCell()
        table.insert(cells, c)
    end
    --inspect(cells)
    grid = getFalseGrid()
    updateGrid()
end
