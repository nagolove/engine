local inspect = require "inspect"
local serpent = require "serpent"
require "external"

local threads = {}
local gridSize: number
local mtschema: {number}

-- количество потоков
local threadCount: number = -1

-- режим работы - протяженный, пошаговый или стоп
local mode = "stop" -- "step"

local statistic = {}

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

local function pushSync()
    local syncChan = love.thread.getChannel("sync")
    for i = 1, threadCount do
        syncChan:push("sync")
    end
end

local function pushMsg2Threads(t)
    for i = 1, threadCount do
        love.thread.getChannel("msg" .. i):push(t)
    end
end

local function sendStopClearChannels()
    if #threads ~= 0 then
        pushMsg2Threads("stop")
        love.timer.sleep(0.05)
        for i = 1, threadCount do
            love.thread.getChannel("msg" .. i):clear()
            love.thread.getChannel("data" .. i):clear()
            love.thread.getChannel("setup" .. i):clear()
            love.thread.getChannel("request" .. i):clear()
        end
    end
end

local function create(commonSetup)
    sendStopClearChannels()
    --mode = "continuos"

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

            local th = love.thread.newThread("scenes/automato/simulator-thread.lua")
            table.insert(threads, th)
            th:start(i)
            local errmsg = th:getError()
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


local function getThreadsLog()
    local logChan = love.thread.getChannel("log")
    local msg = logChan:pop()
    while msg do
        print(msg[1], msg[2])
        msg = logChan:pop()
    end
end

local function step()
    if mode == "stop" then
        return
    end

    local iterSum = 0
    local iterChan = love.thread.getChannel("iter")
    local value = iterChan:pop()
    while value do
        iterSum = iterSum + value
        value = iterChan:pop()
    end
    statistic.iterAverage = iterSum / threadCount
    pushSync()
end

-- FIXME Как починить счетчик итераций при работе в несколько нитей?
local function getIter()
    --[[
       [local newIter = love.thread.getChannel("iter")
       [if newIter then
       [    iter = newIter:pop() or iter
       [end
       [return iter
       ]]
       return 0
end

-- возвращает номер нити многопоточной схемы по координатам 
local function findThreadByPos(x, y)
    local ix, iy = math.floor(x / gridSize), math.floor(y / gridSize)
    local rx, ry = x % gridSize, y % gridSize
    for k, v in pairs(mtschema) do
    end
    return nil
end

-- здеcь нужно определять в какой из потоков отправить запрос используя каналы
-- msg1, msg2, ...
-- функция - запрос для визуального отладчика
local function getObject(x, y)
    local threadNum = findThreadByPos(x, y)

    local chan = love.thread.getChannel("msg")
    chan:push("getobject")
    chan:push(x)
    chan:push(y)

    local sobject = love.thread.getChannel("request" .. threadNum):demand()
    local objectfun, err = loadstring(sobject)

    if err then
        logferror("Could'not deserialize cell object %s", err)
        return nil
    end

    return objectfun()
end

local function setMode(m)
    --assert(m == "step" or m == "continuos")
    mode = m
    print("push", mode)
    pushMsg2Threads(mode)
end

local function getMode()
    return mode
end

local function doStep()
    pushMsg2Threads("step")
end

local function getStatistic()
    return statistic
end

return {
    create = create,
    setMode = setMode,
    getMode = getMode,
    getDrawList = getDrawList,
    getDrawLists = getDrawLists,
    getObject = getObject,
    step = step,
    doStep = doStep,
    getStatistic = getStatistic,
    getIter = getIter,
    getGridSize = function()
        return gridSize
    end,
    getSchema = function()
        return mtschema
    end,
}
