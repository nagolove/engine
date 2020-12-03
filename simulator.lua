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

-- вместилище команд "up", "left"  и прочего алфавита
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
function Grid:new()
end
function Grid:fillZero()
end
function Grid:isFood(i, j)
end
function Grid:setFood(i, j)
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
    self.diedCoro = coroutine.create(function()
        print("died")
        for i = 1, 2 do
            return coroutine.yield()
        end
        self.died = true
    end)
    self.died = false
    table.insert(cells, self)
    return self
end

-- возвращает [boolean], [cell table]
-- isalive, cell
function updateCell(cell)
    --print("cell ip", cell.ip)
    if cell.ip >= #cell.code then
        cell.ip = 1
    end
    if cell.energy > 0 then
        actions[cell.code[cell.ip]](cell)
        cell.ip = cell.ip + 1
        cell.energy = cell.energy - 1
        return true, cell
    else
        print("not energy")
        return false, cell
    end
end

-- заполнить решетку пустыми значениями. В качестве значений используются
-- пустые таблицы {}
function getFalseGrid(oldGrid)
    local res = {}
    for i = 1, gridSize do
        local t = {}
        for j = 1, gridSize do
            if oldGrid then
                t[#t + 1] = copy(oldGrid[i][j])
            else
                t[#t + 1] = {}
            end
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

function emitFood(iter)
    --for i = 1, math.log(iter) / 10 do
    for i = 1, 3 do
    --for i = 1, 0 do
        local emited, gridcell = emitFoodInRandomPoint()
        if not emited then
            -- здесь исследовать причины смерти яцейки
            --print("not emited gridcell", inspect(gridcell))
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
            local ok = true
            local diedCell
            while ok do
                ok, diedCell = coroutine.resume(c.diedCoro)
            end

            if diedCell.pos then
                print("copyed")
                grid[diedCell.pos.x][diedCell.pos.y].died = true
            end

            table.insert(removed, c)
        end
    end
    return alive
end

function initCellOneCommandCode(command, steps)
    local cell = initCell()
    cell.code = {}
    for i = 1, steps do
        table.insert(cell.code, command)
    end
end

function cloneCell(cell, newx, newy)
    if not isAlive(newx, newy) then
        local new = {}
        for k, v in pairs(cell) do
            if type(v) ~= "table" then
                new[k] = v
            else
                new[k] = {}
                for k1, v1 in pairs(v) do
                    new[k][k1] = v1
                end
            end
        end
        new.pos.x, new.pos.y = newx, newy
        print("cloned cell")
        table.insert(cells, new)
        return new
    else
        print("nothing in clone")
        return nil
    end
end

function initialEmit()
    --[[
       [for i = 1, cellsNum do
       [    --coroutine.yield(initCell())
       [    print("i", i)
       [    coroutine.yield()
       [    initCell()
       [end
       ]]
    initCell()

    --[[
       [local steps = 5
       [local c = initCell()
       [cloneCell(c, 10, 10)
       [initCellOneCommandCode("right", steps)
       [initCellOneCommandCode("left", steps)
       [initCellOneCommandCode("up", steps)
       [initCellOneCommandCode("down", steps)
       ]]
end

function postinitialEmit(iter)
    local bound = math.log(iter) / 1000
    for i = 1, bound do
        print("i", i)
        coroutine.yield()
        initCell()
    end
end

function experiment()
    local initialEmitCoro = coroutine.create(initialEmit)
    while coroutine.resume(initialEmitCoro) do end

    grid = getFalseGrid(oldGrid)

    updateGrid()
    statistic = gatherStatistic()

    coroutine.yield()

    local postinitialEmitCoro = coroutine.create(postinitialEmit)

    while #cells > 0 do
        -- дополнительное создание клеток в зависимости от iter
        if coroutine.resume(postinitialEmitCoro) then
        end

        --if mode == "bystep" and stepPressed == true or mode == "continuos" then
        do
            --coroutine.resume(initialEmit, iter)

            -- создать сколько-то еды
            emitFood(iter)

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

local experimentErrorPrinted = false

function step()
    local err, errmsg = coroutine.resume(experimentCoro)
    if not err and not experimentErrorPrinted then
        experimentErrorPrinted = true
        logfwarn("coroutine error %s", errmsg)
    end
end

local threads = {}

local function create()
    local processorCount = love.system.getProcessorCount()
    for i = 1, processorCount - 2 do
        --tables.insert(threads, love.newThread("simulator-thread.lua"))
    end
    print("processorCount", processorCount)

    experimentCoro = coroutine.create(function()
        local ok, errmsg = pcall(experiment)
        if not ok then
            logferror("Error %s", errmsg)
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
