local threadNum = ...
print("thread", threadNum, "is running")

require "love.timer"
math.randomseed(love.timer.getTime())
require "external"

local inspect = require "inspect"
local serpent = require "serpent"
-- массив всех клеток
local cells = {}
-- массив массивов [x][y] с клетками по индексам
local grid = {}
local gridSize
local codeLen
local cellsNum
local initialEnergy = {}
local iter = 0
local statistic = {}
local IdCounter = 0
local meal = {}
local stop = false
local schema
local drawCoefficients

local function doSetup()
    local setupName = "setup" .. threadNum
    local initialSetup = love.thread.getChannel(setupName):pop()

    gridSize = initialSetup.gridSize
    codeLen = initialSetup.codeLen
    cellsNum = initialSetup.cellsNum
    initialEnergy[1], initialEnergy[2] = initialSetup.initialEnergy[1], initialSetup.initialEnergy[2]

    local sschema = love.thread.getChannel(setupName):pop()
    local schemafun, err = loadstring(sschema)
    if err then
        error("Could'not get schema for thread")
    end
    local schemaRestored = schemafun()
    schema = flatCopy(schemaRestored)
    drawCoefficients = flatCopy(schemaRestored.draw)

    print("schema", inspect(schema))
    print("drawCoefficients", inspect(drawCoefficients))
end

local chan = love.thread.getChannel("msg" .. threadNum)
local data = love.thread.getChannel("data" .. threadNum)
local log = love.thread.getChannel("log")
local request = love.thread.getChannel("request" .. threadNum)
local newcells = love.thread.getChannel("newcells" .. threadNum)

local actionsModule = require "cell-actions"

local function getCodeValues()
    local codeValues = {}
    for k, v in pairs(actionsModule.actions) do
        table.insert(codeValues, k)
    end
    return codeValues
end

local codeValues = getCodeValues()

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

local function getId()
    IdCounter = IdCounter + 1
    return IdCounter
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
    self.id = getId()
    self.ip = 1
    self.energy = math.random(initialEnergy[1], initialEnergy[2])
    self.mem = {}
    self.diedCoro = coroutine.create(function()
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
    if cell.ip >= #cell.code then
        cell.ip = 1
    end
    if cell.energy > 0 then
        actions[cell.code[cell.ip]](cell)
        cell.ip = cell.ip + 1
        --cell.energy = cell.energy - 1
        return true, cell
    else
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
    --print("getAllEated()", actionsModule.getAllEated())
    return { 
        maxEnergy = maxEnergy,
        minEnergy = minEnergy,
        midEnergy = sumEnergy / #cells,
        allEated = actionsModule.getAllEated(),
    }
end


function emitFoodInRandomPoint()
    local x = math.random(1, gridSize)
    local y = math.random(1, gridSize)
    local t = grid[x][y]
    -- если клетка пустая
    if not t.energy then
        local self = {
            food = true,
            pos = {x = x, y = y}
        }
        table.insert(meal, self)
        grid[x][y] = self
        return true, grid[x][y]
    else
        return false, grid[x][y]
    end
end


function emitFood(iter)
    --print(math.log(iter) / 1)
    for i = 1, math.log(iter) * 10 do
        --local emited, gridcell = emitFoodInRandomPoint()
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

local function initCellOneCommandCode(command, steps)
    local cell = initCell()
    cell.code = {}
    for i = 1, steps do
        table.insert(cell.code, command)
    end
end

local function cloneCell(cell, newx, newy)
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
    if threadNum == 1 then
        for i = 1, cellsNum do
            --coroutine.yield(initCell())
        end
    --elseif threadNum == 2 then
    else
        for i = 1, cellsNum / 100 do
            coroutine.yield(initCell())
        end
    end

    if threadNum == 1 then
        for i = 1, 2 do
            local steps = 5
            --local c = initCell()
            --cloneCell(c, 10, 10)
            initCellOneCommandCode("right", steps)
            initCellOneCommandCode("left", steps)
            initCellOneCommandCode("up", steps)
            initCellOneCommandCode("down", steps)
        end
    end
end

function postinitialEmit(iter)
    local bound = math.log(iter) / 1000
    for i = 1, bound do
        print("i", i)
        coroutine.yield()
        initCell()
    end
end

local function updateMeal(meal)
    local alive = {}
    for k, dish in pairs(meal) do
        if dish.food == true then
            table.insert(alive, dish)
        end
    end
    return alive
end

function experiment()
    local initialEmitCoro = coroutine.create(initialEmit)
    while coroutine.resume(initialEmitCoro) do end

    grid = getFalseGrid()

    updateGrid()
    statistic = gatherStatistic()

    coroutine.yield()

    local postinitialEmitCoro = coroutine.create(postinitialEmit)

    while #cells > 0 do
        -- дополнительное создание клеток в зависимости от iter
        if coroutine.resume(postinitialEmitCoro) then
        end

        --coroutine.resume(initialEmit, iter)

        -- создать сколько-то еды
        emitFood(iter)

        -- проход по списку клеток и вызов их программ.
        cells = updateCells(cells)
        
        -- проход по списку еды и проверка на съеденность
        meal = updateMeal(meal)

        -- сброс решетки после уничтожения некоторых клеток
        grid = getFalseGrid()

        -- обновление решетки по списку живых клеток и списку еды
        updateGrid()

        statistic = gatherStatistic()
        iter = iter + 1

        coroutine.yield()
    end

    saveDeadCellsLog(removed)
end

local experimentErrorPrinted = false

local function logfwarn(...)
    love.thread.getChannel("log"):push({threadNum, string.format(...)})
end

local function step()
    local err, errmsg = coroutine.resume(experimentCoro)
    if not err and not experimentErrorPrinted then
        experimentErrorPrinted = true
        logfwarn("coroutine error %s", errmsg)
    end
end

local function getGrid()
    return grid
end

local function create()
    experimentCoro = coroutine.create(function()
        local ok, errmsg = pcall(experiment)
        if not ok then
            logferror("Error %s", errmsg)
        end
    end)
    coroutine.resume(experimentCoro)
    --actionsModule.init(getGrid, gridSize, schema, threadNum, { initCell_fn = initCell })
    actionsModule.init({
        getGridFunc = getGrid,
        gridSize = gridSize,
        schema = schema,
        threadNum = threadNum,
        initCell_fn = initCell,
    })
    actions = actionsModule.actions
end

local function pushDrawList()
    local drawlist = {}
    for k, v in pairs(cells) do
        table.insert(drawlist, { 
            x = v.pos.x + gridSize * drawCoefficients[1],
            y = v.pos.y + gridSize * drawCoefficients[2],
        })
    end
    for k, v in pairs(meal) do
        table.insert(drawlist, { 
            x = v.pos.x + gridSize * drawCoefficients[1],
            y = v.pos.y + gridSize * drawCoefficients[2], 
            food = true
        })
    end
    if data:getCount() < 5 then
        data:push(drawlist)
    end
end

local doStep = false
local checkStep = false

local commands = {}

function commands.stop()
    stop = true
end

function commands.getobject()
    local x, y = chan:pop(), chan:pop()
    local ok, errmsg = pcall(function()
        if grid then
            local cell = grid[x][y]
            if cell then
                request:push(serpent.dump(cell))
            end
        end
    end)
    if not ok then
        print("Error in getobject operation", errmsg)
    end
end

function commands.step()
    checkStep = true
    doStep = true
end

function commands.continuos()
    checkStep = false
end

function commands.isalive()
    local x, y = chan:pop(), chan:pop()
    local ok, errmsg = pcall(function()
        if x >= 1 and x <= gridSize and y >= 1 and y <= gridSize then
            local cell = grid[x][y]
            local state = cell.energy and cell.energy > 0
            request:push(state)
        end
    end)
    if not ok then
        error(errmsg)
    end
end

function commands.insertcell()
    local newcellfun, err = loadstring(chan:pop())
    if err then
        error(err)
    end
    local newcell = newcellfun()
    table.insert(cells, newcell)
end

local function popCommand()
    local cmd = chan:pop()
    if cmd then
        local command = commands[cmd]
        if command then
            command()
        else
            print("Unknown command", cmd)
        end
    end
end

local syncChan = love.thread.getChannel("sync")

doSetup()
create()

while not stop do
    popCommand()

    if checkStep then
        if doStep then
            step()
        end
        love.timer.sleep(0.02)
    else
        step()
    end
    pushDrawList()

    local syncMsg = syncChan:demand(0.001)
    --local syncMsg = syncChan:demand()
    --local syncMsg = syncChan:pop()
    --print(threadNum, syncMsg)

    doStep = false

    --[[
       [local iterChan = love.thread.getChannel("iter")
       [if iterChan:getCount() < 5 then
       [    iterChan:push(iter)
       [end
       ]]
end
