local inspect = require "inspect"
local cells = {}
local grid = {}
local gridSize = 100
local pixSize = 10
local gr = love.graphics
local codeLen = 32

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

local actions = {}

function actions.left(cell)
    pos = cell.pos
    --if pos.x > 1 and 
end

function actions.right(cell)
end

function actions.up(cell)
end

function actions.down(cell)
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

function drawCells()
    for k, cell in pairs(cells) do
        if cell.state then
            if cell.state == "alive" then
                gr.setColor(0, 0, 1)
            else
                gr.setColor(0, 0, 0)
            end
        end
        if cell.pos and cell.pos.x and cell.pos.y then
            gr.rectangle("fill", (cell.pos.x - 1)* pixSize, (cell.pos.y - 1) * pixSize, pixSize, pixSize)
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

love.update = function()
    local alive = {}
    for k, cell in pairs(cells) do
        table.insert(alive, updateCell(cell))
    end
    cells = alive
end

local cellsNum = 100

function love.load()
    math.randomseed(love.timer.getTime())
    for i = 1, cellsNum do
        local c = initCell()
        table.insert(cells, c)
    end
    inspect(cells)
end
