require "external"
local inspect = require "inspect"
local grid
local gridSize
local actions = {}
local ENERGY = 1000
local initCell
local allEated = 0

function isAlive(x, y)
    local t = grid[x][y]
    return t.energy and t.energy > 0
end

function actions.left(cell)
    pos = cell.pos
    if pos.x > 1 and not isAlive(pos.x - 1, pos.y) then
        pos.x = pos.x - 1
    elseif pos.x <= 1 and not isAlive(gridSize, pos.y) then
        pos.x = gridSize
    end
end

function actions.right(cell)
    pos = cell.pos
    if pos.x < gridSize and not isAlive(pos.x + 1, pos.y) then
        pos.x = pos.x + 1
    elseif pos.x >= gridSize and not isAlive(1, pos.y) then
        pos.x = 1
    end
end

function actions.up(cell)
    pos = cell.pos
    if pos.y > 1 and not isAlive(pos.x, pos.y - 1) then
        pos.y = pos.y - 1
    elseif pos.y <= 1 and not isAlive(pos.x, gridSize) then
        pos.y = gridSize
    end
end

function actions.down(cell)
    pos = cell.pos
    if pos.y < gridSize and not isAlive(pos.x, pos.y + 1) then
        pos.y = pos.y + 1
    elseif pos.y >= gridSize and not isAlive(pos.x, 1) then
        pos.y = 1
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

local around = {
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1, 0},
    {-1,  1}, {0,  1}, {1, 1},
}

local function incEat(cell)
    if not cell.eated then
        cell.eated = 0
    end
    cell.eated = cell.eated + 1
    allEated = allEated + 1
end

-- проверяет на съедобность одну случайную клетку вокруг. 
-- Съедает ее если находит съедобную. На место съеденной 
-- не перемещается.
function actions.checkAndEat(cell)
    pos = cell.pos
    local newt = copy(pos)
    -- выбор случайной клетки из всех возможных окружающих
    local displacement = around[math.random(1, #around)]
    newt.x = newt.x + displacement[1]
    newt.y = newt.y + displacement[2]

    -- проверка на выход за границы поля
    if newt.x >= 1 and newt.x < gridSize and
        newt.y >= 1 and newt.y < gridSize then
        local dish = grid[newt.x][newt.y]
        -- проверка на нахождение еды в определенной клетке и поедание
        --print(inspect(dish))
        if dish.food then
            --print("checkAndEat at", newt.x, newt.y)
            dish.food = nil
            dish.energy = 0
            cell.energy = cell.energy + ENERGY
            incEat(cell)
            return
        end
    end
end

-- Аналогично checkAndEat, но проверяет на съедобность все клетки 
-- вокруг себя.
function actions.eat8(cell)
    local nx, ny = cell.pos.x, cell.pos.y
    for k, displacement in pairs(around) do
        --print("displacement", inspect(displacement))
        nx = nx + displacement[1]
        ny = ny + displacement[2]

        -- проверка на выход за границы поля
        --if newt.x >= 1 and newt.x <= gridSize and
            --newt.y >= 1 and newt.y <= gridSize then
            local dish
            --local dish = grid[newt.x][newt.y]
            pcall(function()
            dish = grid[nx][ny]
        end)
            --print("dish", inspect(dish))
            -- проверка на нахождение еды в определенной клетке и поедание
            --print(inspect(dish))
            if dish then
                --print("dish", inspect(dish))
               if dish.food then
                --print("eat8 at", newt.x, newt.y)
                grid[nx][ny].food = nil
                dish.energy = 0
                cell.energy = cell.energy + ENERGY
                print("mmm", inspect(cell))
                incEat(cell)
                return
            end
        end
        --end
    end
end

-- аналогично eat8, но перемещается на место съеденной клетки.
function actions.eat8move(cell)
    pos = cell.pos
    local newt = copy(pos)
    for k, displacement in pairs(around) do
        newt.x = newt.x + displacement[1]
        newt.y = newt.y + displacement[2]

        -- проверка на выход за границы поля
        if newt.x >= 1 and newt.x < gridSize and
            newt.y >= 1 and newt.y < gridSize then
            local dish = grid[newt.x][newt.y]
            -- проверка на нахождение еды в определенной клетке и поедание
            --print(inspect(dish))
            if dish.food then
                --print("eat8move at", newt.x, newt.y)
                dish.food = nil
                dish.energy = 0
                cell.energy = cell.energy + ENERGY
                cell.pos.x = newt.x
                cell.pos.y = newt.y
                incEat(cell)
                return
            end
        end
    end
end

-- вызывает коллбэк вида function(x, y, value) для всех доступных соседей
-- клетки. x, y - целочисленные координаты клетки в решетке. value - значение
-- решетки по текущим координатам.
-- Если коллбэк функция возвращает false, то дальнейшие вызовы прерываются, 
-- управление возвращается.
-- FIXME поиск должен рандоминизировать начальное положение что-бы 
-- исключить влияние порядка обхода клеток.
function listNeighbours(x, y, cb)
    for k, displacement in pairs(around) do
        local nx, ny = x + displacement[1], y + displacement[2]
        if nx >= 1 and nx < gridSize and ny >= 1 and ny < gridSize then
            if not cb(nx, ny, grid[nx][ny]) then
                break
            end
        end
    end
end

-- return code, not cell
function mixCode(cell1, cell2)
    local rnd = math.random()
    local first, second
    if rnd > 0.5 then
        first, second = cell1, cell2 
    else
        first, second = cell2, cell1
    end
    local newcode = {}
    local i = 1
    local pushed

    repeat
        pushed = false
        if i <= #cell1.code then
            table.insert(newcode, first.code[i])
            pushed = true
        end
        if i <= #cell2.code then
            table.insert(newcode, second.code[i])
            pushed = true
        end
        i = i + 1
    until not pushed

    return newcode
end

function test_mixCode()
    math.randomseed(love.timer.getTime())
    print("mixCode", inspect(mixCode({code={"left", "right", "up"}},
    {code={"eat", "eat", "eat"}})))

    print("mixCode", inspect(mixCode({code={"left", "right", "up"}},
    {code={"eat", "eat"}})))

    print("mixCode", inspect(mixCode({code={"left", "right", "up"}},
    {code={"eat", "eat", "down", "down", "down"}})))
end
--test_mixCode()

-- возвращает true если найдена пустая клетка, {x, y} координаты.
-- иначе false
function findFreePos(x, y)
    local found
    local pos = {}
    listNeighbours(x, y, function(xp, yp, value)
        if (not value.energy) and (not value.dish) then
            pos.x = xp
            pos.y = yp
            return true, pos
        end
    end)
    return false
end

-- если достаточно энергии(>0), то клетка
function actions.cross(cell)
    if cell.energy > 0 then
        cell.wantdivide = true
        listNeighbours(cell.pos.x, cell.pos.y, function(x, y, value)
            if value.wantdivide then
                local found, pos = findFreePos(cell.pos.x, cell.pos.y)
                if found then
                    local t = {
                        pos = {x = pos.x, y = pos.y},
                        code = mixCode(cell, grid[x][y])
                    }
                    print("new cell!")
                    initCell(t)
                end
            end
        end)
    end
end

function init(externalGrid, externalGridSize, functions)
    grid = externalGrid
    gridSize = externalGridSize
    initCell = functions.initCell_fn
    allEated = 0
end

return {
    actions = actions,
    init = init,
    getAllEated = function()
        return allEated
    end,
}
