local inspect = require "inspect"
-- массив всех клеток
local cells = {}
-- массив массивов [x][y] с клетками по индексам
local grid = {}
local gridSize = 100
local codeLen = 320
local cellsNum = 2000
local initialEnergy = {500, 1000}
local iter = 0
local statistic = {}

local genomStore = {}
function genomStore:init()
end
local function initGenom()
    local self = {}
    return setmetatable(self, genomStore)
end

local ffi = require("ffi")
pcall(ffi.cdef, [[
typedef struct ImageData_Pixel
{
    uint8_t r, g, b, a;
} ImageData_Pixel;
typedef struct Grid_Data
{
    /*
    state bits [0, 1, 2, 3, 4, 5, 6, 7, 8]
    0 - food
    1 - cell
    */
    uint8_t state;
} Grid_Data;
]])
local gridptr = ffi.typeof("Grid_Data*")
local Grid = {}
function grid:new()
end
function grid:fillZero()
end
function grid:isFood(i, j)
end
function grid:setFood(i, j)
end

function newGrid()
    return setmetatable({}, Grid)
end

local codeValues = {
    "left",
    "right",
    "up",
    "down",
    "eat8move",
    "eat8",
    "checkAndEat",
    "cross",
}

local meal = {}
local actionsModule = require "cell-actions"
local actions
local removed = {}
local experimentCoro

function genCode()
    local code = {}
    local len = #codeValues
    for i = 1, codeLen do
        table.insert(code, codeValues[math.random(1, len)])
    end
    return code
end

-- t.pos, t.code
function initCell(t)
    t = t or {}
    local self = {}
    self.pos = {}
    if t.pos and t.pos.x then
        self.pos.x = t.pos.x
    else
        self.pos.x = math.random(1, gridSize)
    end
    if t.pos and t.pos.y then
        self.pos.y = t.pos.y
    else
        self.pos.y = math.random(1, gridSize)
    end
    if t.code then
        self.code = copy(t.code)
    else
        self.code = genCode()
    end
    self.ip = 1
    self.energy = math.random(initialEnergy[1], initialEnergy[2])
    self.mem = {}
    self.died = coroutine.create(function()
        for i = 1, 100 do
            print("died")
            return coroutine.yield()
        end
    end)
    table.insert(cells, self)
    return self
end

-- возвращает [boolean], [cell table]
-- isalive, cell
function updateCell(cell)
    if cell.ip > #cell.code then
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

function emitFoodInRandomPoint()
    local x = math.random(1, gridSize)
    local y = math.random(1, gridSize)
    local t = grid[x][y]
    -- если клетка пустая
    if not t.energy then
        local self = {}
        self.food = true
        self.pos = {}
        self.pos.x, self.pos.y = x, y
        table.insert(meal, self)
        grid[x][y] = self
        return true, grid[x][y]
    else
        return false, grid[x][y]
    end
end

function emit()
    for i = 1, 3 do
        local emited, gridcell = emitFoodInRandomPoint()
        if not emited then
            print("not emited gridcell", inspect(gridcell))
        end
    end
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
            while coroutine.resume(c.died) do
            end
            table.insert(removed, c)
        end
    end
    return alive
end

function initialEmit()
    --for i = 1, cellsNum do
    for i = 1, cellsNum do
        print("i", i)
        coroutine.yield()
        initCell()
    end
end

function experiment()
    --initialEmit()
    local initialEmit = coroutine.create(initialEmit)
    while coroutine.resume(initialEmit) do end
    grid = getFalseGrid()
    updateGrid()
    statistic = gatherStatistic()

    coroutine.yield()

    while #cells > 0 do
        --if mode == "bystep" and stepPressed == true or mode == "continuos" then
        do
            -- создать сколько-то еды
            emit()

            -- проход по ячейкам и вызов их программ
            cells = updateCells()

            -- сброс решетки после уничтожения некоторых клеток
            grid = getFalseGrid()

            -- обновление решетки по списку живых клеток и списку еды
            updateGrid()

            statistic = gatherStatistic()
            iter = iter + 1

            --if stepPressed == true then
                --stepPressed = false
            --end
        end
        coroutine.yield()
    end

    saveDeadCellsLog(removed)
end

function step()
    local err, errmsg = coroutine.resume(experimentCoro)
    if not err then
        print(string.format("coroutine error %s", errmsg))
    end
end

function create()
    experimentCoro = coroutine.create(function()
        local ok, errmsg = pcall(experiment)
        if not ok then
            print(string.format("Error %s", errmsg))
        end
    end)
    coroutine.resume(experimentCoro)
    actionsModule.init(grid, gridSize, { initCell_fn = initCell })
    actions = actionsModule.actions
end

return {
    create = create,
    getGrid = function()
        return grid
    end,
    step = step,
    statistic = statistic,
    getIter = function()
        return iter
    end,
    getGridSize = function()
        return gridSize
    end,
}
