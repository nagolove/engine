require "external"
local inspect = require "inspect"
local grid
local gridSize
local actions = {}
local ENERGY = 10
local initCell

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

local around = {
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1, 0},
    {-1,  1}, {0, -1}, {1, 1},
}

-- проверяет на съедобность одну случайную клетку вокруг. Съедает ее
-- если находит съедобную. На место съеденной не перемещается.
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
            print("eat at", newt.x, newt.y)
            dish.energy = 0
            cell.energy = cell.energy + ENERGY
            return
        end
    end
end

-- Аналогично checkAndEat, но проверяет на съедобность все клетки 
-- вокруг себя.
function actions.eat8(cell)
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
                print("eat at", newt.x, newt.y)
                dish.energy = 0
                cell.energy = cell.energy + ENERGY
                return
            end
        end
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
                print("eat at", newt.x, newt.y)
                dish.energy = 0
                cell.energy = cell.energy + ENERGY
                cell.pos.x = newt.x
                cell.pos.y = newt.y
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

-- если достаточно энергии(>0), то клетка
function actions.cross(cell)
    cell.wantdivide = true
    listNeighbours(cell.pos.x, cell.pos.y, function(x, y, value)
        if value.wantdivide then
        end
    end)
end

function init(externalGrid, externalGridSize, functions)
    grid = externalGrid
    gridSize = externalGridSize
    initCell = functions.initCell_fn
end

return {
    actions = actions,
    init = init,
}
