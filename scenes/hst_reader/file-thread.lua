local arg = ...
require "love.timer"
require "external"
local inspect = require "inspect"
local serpent = require "serpent"
local struct = require "struct"

print(arg, inspect(arg))

local fname = love.thread.getChannel("fname"):pop()

local raw = {}
local READ_LEN = 60

local textOut = io.open("candells.txt", "w")

local function readRecord(f)
    local data = f:read(READ_LEN)
    local fmt = "<LddddLIL"
    if data then
        if #data ~= READ_LEN then
            print(string.format("Read %s bytes.", #data))
            return nil
        end
        local ctm, open, low, high, close, vol, spread, rvol = struct.unpack(fmt, data)
        table.insert(raw, {
            ctm = ctm,
            open = open,
            low = low,
            high = high,
            close = close,
            vol = vol,
            spread = spread,
            rvol = rvol
        })

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
        return raw[#raw]
        --print("open", open)
        --print("low", low)
        --print("high", high)
        --print("close", close)
        --print("volume", vol)
        --print("spread", spread)
        --print("real volume", rvol)

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
    love.thread.getChannel("data"):push(#raw)
end

function messageHandler.get()
    local idx = tonumber(love.thread.getChannel("msg"):pop())
    if not idx then
        print("Error in 'get' message, no index for data")
    else
        if idx >= 1 and idx <= #raw then
            --print("data pushing")
            love.thread.getChannel("data"):push(raw[idx])
        else
            print(string.format("Incorrect index %d", idx))
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

--local sz = checkFileSize()

local file = io.open(fname, "rb")
if not file then
    error(string.format("Could'not open %s file", fname))
end
firstRead(file)
local time1 = love.timer.getTime()
local i = 0

while true do
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

while true do
    processMessages()
    love.thread.sleep(0.002)
end
