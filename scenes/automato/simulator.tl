local inspect = require "inspect"
local serpent = require "serpent"

--local tabular = require "tabular"
package.path = "./scenes/automato/?.lua;" .. package.path
print("package.path", package.path)

require "love"
require "external"
require "log"
require "types"
require "mtschemes"

local threads: {love.thread.Thread} = {}
local gridSize: number
local mtschema: {MtSchema}

-- количество потоков
local threadCount: number = -1

-- режим работы - протяженный, пошаговый или стоп
local mode = "stop" -- "step"

local statistic: Statistic = {}

local function getDrawLists(): {DrawNode}
    local list = {}
    for k, _ in ipairs(threads) do
        local sublist: {DrawNode} = love.thread.getChannel("data" .. k):demand() as {DrawNode}
        for _, v1 in ipairs(sublist) do
            table.insert(list, v1)
        end
    end
    return list
end

local function pushSync()
    local syncChan = love.thread.getChannel("sync")
    local i = 1
    while i < threadCount do
        i = i + 1
        syncChan:push("sync")
    end
    --for i = 1, threadCount do
        --syncChan:push("sync")
    --end
end

local function pushMsg2Threads(t: any)
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

function love.threaderror(thread: love.thread.Thread, errstr: string)
    print("Some thread failed with " .. errstr)    
end

local function create(commonSetup: CommonSetup)
    print("--------------------------------------------")
    print("commonSetup", inspect(commonSetup))

    sendStopClearChannels()

    threadCount = commonSetup.threadCount
    print("threadCount", threadCount)

    gridSize = commonSetup.gridSize

    mtschema = require "mtschemes"[threadCount] as {MtSchema}
    print("mtschema", inspect(mtschema))

    if not mtschema then
        error(string.format("Unsupported scheme for %d threads.", threadCount))
    end

    for i = 1, threadCount do
        local ok, errmsg: boolean, string = pcall(function()
            local setupName = "setup" .. i
            love.thread.getChannel(setupName):push(commonSetup)
            love.thread.getChannel(setupName):push(serpent.dump(mtschema[i]))

            local th: love.thread.Thread = love.thread.newThread("scenes/automato/simulator-thread.lua")
            table.insert(threads, th)
            th:start(i)
            local errmsg = th:getError()
            if errmsg then
                --logfwarn("Thread %s", errmsg)
                print("Thread %s", errmsg)
            end
        end)
        if not ok then
            logferror("Error in creating thread %s", errmsg)
        end
    end

    pushSync()
    --love.timer.sleep(0.5)

    print("threads", inspect(threads))
    print("thread errors")
    for _, v in ipairs(threads) do
        print(v:getError())
    end
    print("end thread errors")

    local processorCount = love.system.getProcessorCount()
    print("processorCount", processorCount)
end


local function getThreadsLog()
    local logChan = love.thread.getChannel("log")
    local msg: {any} = logChan:pop() as {any}
    while msg do
        print(msg[1], msg[2])
        msg = logChan:pop() as {any}
    end
end

local function step()
    if mode == "stop" then
        return
    end

    --local iterSum: number = 0
    --local iterChan: love.thread.Channel = love.thread.getChannel("iter")
    --local value = iterChan:pop() as number
    --while value do
        --iterSum = iterSum + value
        --value = iterChan:pop() as number
    --end
    --statistic.iterAverage = iterSum / threadCount
    --pushSync()
end

-- FIXME Как починить счетчик итераций при работе в несколько нитей?
local function getIter(): number
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
local function findThreadByPos(x: number, y: number): number
    local ix, iy = math.floor(x / gridSize), math.floor(y / gridSize)
    local rx, ry = x % gridSize, y % gridSize
    --[[
    Тут должен быть поиск по массиву mtschema для нахождения нити.
    --]]
    --for k, v in pairs(mtschema) do
    --end
    return nil
end

-- здеcь нужно определять в какой из потоков отправить запрос используя каналы
-- msg1, msg2, ...
-- функция - запрос для визуального отладчика
local function getObject(x: number, y: number): any
    local threadNum = findThreadByPos(x, y)

    local chan = love.thread.getChannel("msg")
    chan:push("getobject")
    chan:push(x)
    chan:push(y)

    local sobject = love.thread.getChannel("request" .. threadNum):demand() as string
    --local objectfun, err: function, boolean = loadstring(sobject) as {function, boolean}
    --local objectfun, err: function, boolean = load(sobject) as {Function, boolean}
    local objectfun, err: function, boolean = serpent.load(sobject)

    if err then
        logferror("Could'not deserialize cell object %s", err)
        return nil
    end

    return objectfun()
end

local function setMode(m: SimulatorMode)
    --assert(m == "step" or m == "continuos")
    mode = m
    print("push", mode)
    pushMsg2Threads(mode)
end

local function getMode(): SimulatorMode
    return mode
end

local function doStep()
    pushMsg2Threads("step")
end

local function getStatistic(): Statistic
    return statistic
end

local function getSchema(): {MtSchema}
    return mtschema
end

global type Simulator = record
    create : function()
    setMode : function(m: SimulatorMode)
    getMode : function(): SimulatorMode
    getDrawLists : function()
    getObject : function(number, number): any
    step : function()
    doStep : function()
    getStatistic : function(): Statistic
    getIter : function(): number
    getGridSize : function(): number
    getSchema : function()
end

local function getGridSize(): number
    return gridSize
end

return {
    create = create,
    setMode = setMode,
    getMode = getMode,
    getDrawLists = getDrawLists,
    getObject = getObject,
    step = step,
    doStep = doStep,
    getStatistic = getStatistic,
    getIter = getIter,
    getGridSize = getGridSize,
    getSchema = getSchema
}
