require "external"
local struct = require "struct"
--local histPath = "c:/users/dekar/AppData/Roaming/MetaQuotes/Terminal/287469DEA9630EA94D0715D755974F1B/history/Alpari-Demo/EURUSD999.hst"
local histPath = [[C:/Users/dekar/Desktop/tick history/EURUSD999.hst]]
local imgui = require "imgui"
local cam = require "camera".new()
local inspect = require "inspect"
local gr = love.graphics
local thread

--package.path = package.path .. ";scenes/hst_reader/?.lua"
local threadPath = "scenes/hst_reader/file-thread.lua"

local function init()
    -- проблема со временем запуска этого кода на выполнение
    thread = love.thread.newThread(threadPath)
    love.thread.getChannel("fname"):push(histPath)
    thread:start(1)

    love.timer.sleep(1.3)
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
    local x, y = sx + x * math.floor(barWidth * 2), sy + ylow * ylowFactor
    local w, h = barWidth, barHeight * barHeightFactor

    if __I__ < 100 then
        --print(h)
        __I__ = __I__ + 1
    end

    gr.rectangle(barMode, x, y, w, h)
end

local msgChannel = love.thread.getChannel("msg")

local function draw()
    cam:attach()
    msgChannel:clear()
    for i = 1, 100 do
        msgChannel:push("get")
        msgChannel:push(i)
        local rec = love.thread.getChannel("data"):demand(0.01)
        if rec then 
            drawBar(i, rec)
        end
    end
    cam:detach()
end

local function drawui()
end

local isDown = love.keyboard.isDown

local function update(dt)
    controlCamera(cam)

    if isDown("z") then
        ylowFactor = ylowFactor * math.log(ylowFactor)
    elseif isDown("x") then
        ylowFactor = ylowFactor / math.log(ylowFactor)
    end
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
