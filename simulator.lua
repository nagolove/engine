local inspect = require "inspect"

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

local meal = {}
local actionsModule = require "cell-actions"
local actions
local removed = {}
local experimentCoro

local threads = {}

local function getGrid()
    return grid
end

local gridSize = 100

local function create()
    local processorCount = love.system.getProcessorCount()
    --local threadCount = processorCount - 2
    local threadCount = 1
    print("threadCount", threadCount)

    love.thread.getChannel("setup"):push({
        gridSize = 100,
        cellsNum = 2000,
        initialEnergy = {500, 1000},
        codeLen = 32,
    })

    for i = 1, threadCount do
        local ok, errmsg = pcall(function()
            local th = love.thread.newThread("simulator-thread.lua")
            table.insert(threads, th)
            local errmsg = th:getError()
            th:start()
            if errmsg then
                logfwarn("Thread %s", errmsg)
            end
        end)
        if not ok then
            logferror("Error in creating thread %s", errmsg)
        end
    end

    love.timer.sleep(0.5)

    for k, v in pairs(threads) do
        print(v:getError())
    end

    local printerChannel = love.thread.getChannel("printer")
    if printerChannel then
        local msg = printerChannel:pop()
        while msg do
            print(">>" .. msg)
            msg = printerChannel:pop()
        end
    else
        logfwarn("No printer channel found.")
    end

    print("processorCount", processorCount)

    experimentCoro = coroutine.create(function()
        local ok, errmsg = pcall(experiment)
        if not ok then
            logferror("Error %s", errmsg)
        end
    end)
    coroutine.resume(experimentCoro)
    actions = actionsModule.actions
end

local function step()
end

return {
    create = create,
    getGrid = getGrid,
    step = step,
    getStatistic = function()
        return statistic
    end,
    getIter = function()
        return iter
    end,
    getGridSize = function()
        return gridSize
    end,
}
