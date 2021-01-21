local _tl_compat53 = ((tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3) and require('compat53.module'); local ipairs = _tl_compat53 and _tl_compat53.ipairs or ipairs; local math = _tl_compat53 and _tl_compat53.math or math; local package = _tl_compat53 and _tl_compat53.package or package; local pcall = _tl_compat53 and _tl_compat53.pcall or pcall; local string = _tl_compat53 and _tl_compat53.string or string; local table = _tl_compat53 and _tl_compat53.table or table; local inspect = require("inspect")
local serpent = require("serpent")


package.path = "./scenes/automato/?.lua;" .. package.path
print("package.path", package.path)

require("love")
require("external")
require("log")

require("types")
require("mtschemes")



local threads = {}
local gridSize
local mtschema


local threadCount = -1


local mode = "stop"

local statistic = {}

local function getDrawLists()
   local list = {}
   for k, _ in ipairs(threads) do
      local sublist = love.thread.getChannel("data" .. k):demand()
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


   threadCount = commonSetup.threadCount
   print("threadCount", threadCount)

   gridSize = commonSetup.gridSize

   mtschema = require("mtschemes")[threadCount]


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

            print("Thread %s", errmsg)
         end
      end)
      if not ok then
         logferror("Error in creating thread %s", errmsg)
      end
   end

   pushSync()


   print("threads", inspect(threads))
   for _, v in ipairs(threads) do
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


local function getIter()







   return 0
end


local function findThreadByPos(x, y)
   local ix, iy = math.floor(x / gridSize), math.floor(y / gridSize)
   local rx, ry = x % gridSize, y % gridSize





   return nil
end




local function getObject(x, y)
   local threadNum = findThreadByPos(x, y)

   local chan = love.thread.getChannel("msg")
   chan:push("getobject")
   chan:push(x)
   chan:push(y)

   local sobject = love.thread.getChannel("request" .. threadNum):demand()


   local objectfun, err = serpent.load(sobject)

   if err then
      logferror("Could'not deserialize cell object %s", err)
      return nil
   end

   return objectfun()
end

local function setMode(m)

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

local function getSchema()
   return mtschema
end

 Simulator = {}













local function getGridSize()
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
   getSchema = getSchema,
}
