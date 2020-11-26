local lt = love.thread
local inspect = require "inspect"

local Log = {}
Log.__index = Log

local modname = ...

function Log.new(host, port)
    local self = {
        -- поток логирования выполняет только одну задачу - передает
        -- содержимое через метод write по сети на сервер для вывода.
        logThread = lt.newThread("logthread.lua"),
        logchan = lt.getChannel("log"),
    }
    setmetatable(self, Log)

    print("Log.new()", host, port)

    self.logchan:push(host) self.logchan:push(port)
    self.logThread:start()

    return self
end

function Log:print(...)
    local str = ""
    local n = select("#", ...)
    for i = 1, n do
        str = str .. tostring(select(i, ...))
        if i < n then
            str = str .. " "
        end
    end
    print("client:print()", str)
    self.logchan:push(str .. "\n")
end

function Log:close()
    local logchan = lt.getChannel("log")
    if logchan then logchan:push("$closethread$") end
end

function Log:mountAndRun(archivename)
    --local path = "archives/" .. archivename
    --print("path", path)
    --local succ = love.filesystem.mount(path, "/", false)
    --print("succ", succ)
    --if succ then
        ----print("package.loaded", inspect(package.loaded.main))
        --package.loaded.main = nil
        --package.loaded.conf = nil
        --require "main"
        --local updfunc = love.update
        --local quitfunc = love.quit
        --love.init()
        --love.update = function(dt)
            --if client then
                --client:update()
            --end
            --if updafunc then updfunc(dt) end
        --end
        --love.quit = function()
            --if client then
                --client:close()
            --end
            --if quitfunc then
                --quitfunc()
            --end
        --end
        --if love.load then
            --love.load(arg)
        --end
    --end
end

-- вызывается в основном цикле love.update(). При получении команды setarchive
-- устанавливает новый исполнямый архив.
function Log:update()
    --local cmdchan = lt.getChannel("cmd")
    --local msg = cmdchan:peek()
    --if type(msg) == "table" and msg[1] == "mount_please" then
        --cmdchan:pop()
        --self:mountAndRun(msg[2])
    --end
end
---------------- dummy interface ------------------
local DummyLog = {}
DummyLog.__index = DummyLog

function DummyLog:update() end
function DummyLog:print(...) end
function DummyLog:quit() end

function DummyLog.new()
    return setmetatable({}, DummyLog)
end
---------------- dummy interface ------------------

return { 
    newLog = Log.new,
    newDummyLog = DummyLog.new,
}
