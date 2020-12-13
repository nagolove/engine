local inspect = require "inspect"
local serpent = require "serpent"
require "external"

local threads = {}
local gridSize
local mtschema
local threadCount
local iter = 0

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

local function getDrawLists()
    local list = {}
    for k, v in pairs(threads) do
        local sublist = love.thread.getChannel("data" .. k):demand()
        for k1, v1 in pairs(sublist) do
            table.insert(list, v1)
        end
    end
    return list
end

local function create(commonSetup)
    threadCount = commonSetup.threadCount
    print("threadCount", threadCount)

    gridSize = commonSetup.gridSize
    mtschema = require "mtschemes"[threadCount]
    if not mtschema then
        error(string.format("Unsupported scheme for %d threads.", threadCount))
    end

    for i = 1, threadCount do
        local ok, errmsg = pcall(function()
            local setupName = "setup" .. i
            love.thread.getChannel(setupName):push(commonSetup)
            love.thread.getChannel(setupName):push(serpent.dump(mtschema[i]))
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

    pushSync()
    --love.timer.sleep(0.5)

    for k, v in pairs(threads) do
        print(v:getError())
    end

    local processorCount = love.system.getProcessorCount()
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

local function pushSync()
    local syncChan = love.thread.getChannel("sync")
    for i = 1, threadCount do
        syncChan:push("sync")
    end
end

local function step()
    pushSync()
end

local function getIter()
    local newIter = love.thread.getChannel("iter")
    if newIter then
        iter = newIter:pop() or iter
    end
    return iter
end

-- здеcь нужно определять в какой из потоков отправить запрос используя каналы
-- msg1, msg2, ...
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

local function pushMsg2Threads(t)
    for i = 1, threadCount do
        love.thread.getChannel("msg" .. i):push(t)
    end
end

local function setMode(m)
    --assert(m == "step" or m == "continuos")
    mode = m
    print("push", mode)
    pushMsg2Threads(mode)
end

local function doStep()
    pushMsg2Threads("step")
end

return {
    create = create,
    setMode = setMode,
    getDrawList = getDrawList,
    getDrawLists = getDrawLists,
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
    getSchema = function()
        return mtschema
    end,
}
