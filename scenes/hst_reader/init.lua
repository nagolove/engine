require "external"
local struct = require "struct"
--local histPath = "c:/users/dekar/AppData/Roaming/MetaQuotes/Terminal/287469DEA9630EA94D0715D755974F1B/history/Alpari-Demo/EURUSD999.hst"
local histPath = [[C:/Users/dekar/Desktop/tick history/EURUSD999.hst]]
local imgui = require "imgui"
local cam = require "camera".new()
local inspect = require "inspect"
local gr = love.graphics
local kons = require "kons".new()
local thread

--package.path = package.path .. ";scenes/hst_reader/?.lua"
local threadPath = "scenes/hst_reader/file-thread.lua"

local function init()
    -- проблема со временем запуска этого кода на выполнение
    thread = love.thread.newThread(threadPath)
    love.thread.getChannel("fname"):push(histPath)
    thread:start(1)
    love.timer.sleep(0.3)
end

-- стартовые позиции для рисования
local sx, sy = 0, 0

local BAR_DOWN = {0.9, 0, 0}
local BAR_UP = {0, 0.9, 0}
local BAR_EQUAL = {0.5, 0.5, 0.5}
local barWidth = 5
--local barHeight = 25
local barHeightFactor = 100000
local barMode = "fill"

local __I__ = 0
local ylowFactor = 100

local function drawBar(x, record)
    local barColor
    local ylow, yhigh

    --print("record", inspect(record))
    if record.close > record.open then
        barColor = BAR_DOWN
        ylow = record.open
        yhigh = record.close
    elseif record.close < record.open then
        barColor = BAR_UP
        ylow = record.close
        yhigh = record.open
    else
        barColor = BAR_EQUAL
        ylow = record.open
        yhigh = record.close
    end

    gr.setColor(barColor)
    local barHeight = yhigh - ylow
    --print("barHeight", barHeight)
    --local x, y = sx + x * math.floor(barWidth * 2), sy + ylow * ylowFactor
    local x, y = sx + x * math.floor(barWidth * 2), sy + math.exp(ylow * 5) * 1
    local w, h = barWidth, barHeight * barHeightFactor

    if __I__ < 100 then
        --print("y", y)
        __I__ = __I__ + 1
    end

    gr.rectangle(barMode, x, y, w, h)
end

local msgChannel = love.thread.getChannel("msg")

package.path = package.path .. ";scenes/hst_reader/?.lua"
local drawingRange = require "drawingrange".newDrawingRange(1, 100)

print("drawingRange", inspect(drawingRange))

local function draw()
    cam:attach()
    --msgChannel:clear()
    for i = drawingRange.from, drawingRange.to do
        msgChannel:push("get")
        msgChannel:push(i)
        local rec = love.thread.getChannel("data"):demand(0.01)
        if rec then 
            drawBar(i, rec)
        end
    end
    cam:detach()
    kons:pushi("ylowFactor %f", ylowFactor)
    kons:draw()
end

local function drawui()
end

local isDown = love.keyboard.isDown
local horizontalSpeed = 5

-- проследи индексы - с 0 или с 1??
local function moveLeft()
    --if drawingRange.from - horizontalSpeed > 1 then
    --end
    drawingRange.from = drawingRange.from - 1
end

local function moveRight()
    drawingRange.from = drawingRange.from + 1
end

local function update(dt)
    kons:update(dt)
    controlCamera(cam)

    if isDown("z") then
        --if ylowFactor > 0 then
            ylowFactor = ylowFactor * 1.001
            --ylowFactor = math.log(ylowFactor * 1.001)
        --end
    elseif isDown("x") then
        --if ylowFactor > 0 then
            ylowFactor = ylowFactor * 0.999
            --ylowFactor = math.log(ylowFactor / 1.001)
        --end
    end

    if isDown("left") then
        moveLeft()
    elseif isDown("right") then
        moveRight()
    end

    msgChannel:push("len")
    --local len = love.thread.getChannel("data"):demand(0.01)
    local len = love.thread.getChannel("len"):pop()
    drawingRange:setBorders(1, len)
end

local function keypressed(key)
end

local zoomFactor = 0.1

local function wheelmoved(x, y)
    if y == 1 then
        cam:zoom(1.0 + zoomFactor)
    elseif y == -1 then
        cam:zoom(1.0 - zoomFactor)
    end
end

local function quit()
    msgChannel:push("stop")
    love.timer.wait(0.01)
end

return {
    cam = cam, 

    PIX2M = PIX2M,
    M2PIX = M2PIX,

    init = init,
    quit = quit,
    draw = draw,
    drawui = drawui,
    update = update,
    keypressed = keypressed,
    wheelmoved = wheelmoved,
}
