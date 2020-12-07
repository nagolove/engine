local inspect = require "inspect"
require "external"

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

local threads = {}
local dataChan = love.thread.getChannel("data")
local msgChan = love.thread.getChannel("msg")

local lastDrawList

local function getDrawList()
    if not lastDrawList then
        lastDrawList = dataChan:peek()
    end
    return dataChan:demand() or lastDrawList
end

local gridSize = 100

local function create()
    local processorCount = love.system.getProcessorCount()
    --local threadCount = processorCount - 2
    local threadCount = 1
    print("threadCount", threadCount)

    local commonSetup = {
        gridSize = gridSize,
        cellsNum = 2000,
        initialEnergy = {500, 1000},
        codeLen = 32,
    }

    for i = 1, threadCount do
        local ok, errmsg = pcall(function()
            local setup = copy1(commonSetup)
            love.thread.getChannel("setup"):push(setup)
            local th = love.thread.newThread("simulator-thread.lua")
            table.insert(threads, th)
            local errmsg = th:getError()
            th:start(i)
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

    print("processorCount", processorCount)
end

local function printThreadsLog()
    local logChan = love.thread.getChannel("log")
    local msg = logChan:pop()
    while msg do
        print(msg[1], msg[2])
        msg = logChan:pop()
    end
end

local function step()
    printThreadsLog()
end

local iter = 0

local function getIter()
    local newIter = love.thread.getChannel("iter")
    if newIter then
        iter = newIter:pop() or iter
    end
    return iter
end

local function getObject(x, y)
    local chan = love.thread.getChannel("msg")
    chan:push("getobject")
    chan:push(x)
    chan:push(y)
    local sobject = love.thread.getChannel("request"):demand()
    local objectfun, err = loadstring(sobject)
    if err then
        logferror("Could'not deserialize cell object %s", err)
        return nil
    end
    return objectfun()
end

local mode = "continuos" -- "step"

local function setMode(m)
    --assert(m == "step" or m == "continuos")
    mode = m
    print("push", mode)
    msgChan:push(mode)
end

local function doStep()
    msgChan:push("step")
end

return {
    create = create,
    setMode = setMode,
    getDrawList = getDrawList,
    getObject = getObject,
    step = step,
    doStep = doStep,
    getStatistic = function()
        return statistic
    end,
    getIter = getIter,
    getGridSize = function()
        return gridSize
    end,
}
