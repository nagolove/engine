local arg = ...
require "love.timer"
require "external"
local ffi = require "ffi"
local inspect = require "inspect"
local serpent = require "serpent"
local struct = require "struct"

print(arg, inspect(arg))

-- FFI array of Frame structs
local array
local arrayLen
local arrayLast = 0

-- main loop cycle flag
local stop = false

local function addFrame(ctm, open, close)
    if arrayLast + 1 >= arrayLen then
        error(string.format("Array overflow with %d records", arrayLast))
    end
    array[arrayLast].ctm = ctm
    array[arrayLast].open = open
    array[arrayLast].close = close
    arrayLast = arrayLast + 1
end

local ok, errmsg = pcall(ffi.cdef, [[
typedef struct Frame {
    unsigned long ctm;
    double open, close;
} Frame;
]])
if not ok then
    error(errmsg)
end

local fname = love.thread.getChannel("fname"):pop()

local raw = {}
local READ_LEN = 60

local textOut = io.open("candells.txt", "w")

local counter = 0
local function readRecord(f)
    counter = counter + 1
    local data = f:read(READ_LEN)
    local fmt = "<LddddLIL"
    if data then
        if #data ~= READ_LEN then
            print(string.format("Read %s bytes.", #data))
            return nil
        end
        local ctm, open, low, high, close, vol, spread, rvol = struct.unpack(fmt, data)
        
        --[[
           [table.insert(raw, {
           [    ctm = ctm,
           [    open = open,
           [    close = close,
           [})
           ]]

        local record = {
            ctm = ctm, 
            open = open, 
            close = close
        }

        addFrame(ctm, open, close)

        --[[
           [local info = copy(raw[#raw])
           [info.ctm = os.date("*t", ctm)
           [textOut:write(inspect(info))
           ]]

        --print("ctm", ctm)
        --print("ctm", inspect(os.date("*t", ctm)))
        local date = os.date("*t", ctm)
        --print("date", inspect(date))
        if date then
            --print(string.format("%d.%d %d:%d:%d", date.day, date.month, date.hour,
                --date.min, date.sec))
        end

        if counter < 100 then
            --print("open", string.format("%.8f", open))
            --print("close", string.format("%.8f", close))
        end

        return record
    else
        return nil
    end
end

--[[
-- Полностью загружает файл в память
--]]
local function firstRead(file)
    local version = struct.unpack("<i", file:read(4))
    print("version", version)
    local copyright = file:read(64)
    print("copyright", copyright)
    local symbol = file:read(12)
    print("symbol", symbol)

    -- Таймфрейм, число знаков, время создания, время синхронизации.
    local period, digits, timesign, last_sync = struct.unpack("<iiii", file:read(16))
    print("timeframe", period)
    print("digits", digits)
    print("timesign", inspect(os.date("*t", timesign)))
    print("last_sync", inspect(os.date("*t", last_sync)))

    _ = file:read(52) -- unused
end

local function secondRead()
end

local messageHandler = {}

function messageHandler.len()
    love.thread.getChannel("len"):push(arrayLast)
end

function messageHandler.stop()
    stop = true
end

-- доступ к фрейму по индексу. Отсчет с 1
function messageHandler.get()
    local idx = tonumber(love.thread.getChannel("msg"):demand())
    if not idx then
        print("Error in 'get' message, no index for data")
    else
        if idx >= 1 and idx <= arrayLast then
            local rec = array[idx - 1]
            love.thread.getChannel("data"):push({
                ctm = rec.ctm,
                open = rec.open,
                close = rec.close,
            })
        else
            error(string.format("Incorrect index %d", idx))
        end
    end
end

-- получить таблицу с фреймами от индекс1 до индекс2 вида 
-- {ctm, open, close, ctm, open, close, ...}
function messageHandler.getRange()
    local idxFrom = tonumber(love.thread.getChannel("msg"):demand())
    local idxTo = tonumber(love.thread.getChannel("msg"):demand())
    if (not idxFrom) or (not idxTo) then
        print("Error in 'get' message, no indices for data")
    else
        if idxFrom >= 1 and idxFrom <= arrayLast and idxTo >= 1 and idxTo <= arrayLast then
            local t = {}
            for i = idxFrom, idxTo do
                local rec = array[i - 1]
                table.insert(t, rec.ctm)
                table.insert(t, rec.open)
                table.insert(t, rec.close)
            end
            love.thread.getChannel("data"):push(t)
        else
            error(string.format("Incorrect indices %d - %d, arrayLast %d", 
                idxFrom, idxTo, arrayLast))
        end
    end
end

function checkFileSize()
    local file = io.open(fname, "rb")
    local size, errmsg = file:seek("end")
    if errmsg then
        print("Error", errmsg)
    end
    file:close()
    return size
end

local function processMessages()
    local message = love.thread.getChannel("msg"):pop()
    if messageHandler[message] then
        messageHandler[message]()
    end
end

local function initArray(num)
    num = math.floor(num)
    array = ffi.new("Frame[?]", num)
    arrayLen = num
    print("init array of len", num)
end

local sz = checkFileSize()
local approxRecordsNum = math.floor(sz / READ_LEN)
print("file size", sz, "bytes")
print("approximately", approxRecordsNum, "records")

initArray(approxRecordsNum * 1.2)

local file = io.open(fname, "rb")
if not file then
    error(string.format("Could'not open %s file", fname))
end

firstRead(file)

local time1 = love.timer.getTime()
local i = 0

while not stop do
    processMessages()
    local record = readRecord(file)
    if record then
        i = i + 1
    else
        break
    end
end

file:close()
local time2 = love.timer.getTime()
print(string.format("%d records loaded for %f secs", i, time2 - time1))

while not stop do
    processMessages()
end
