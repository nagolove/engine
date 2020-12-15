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

local function quit()
end

local BAR_DOWN = {0.9, 0, 0}
local BAR_UP = {0, 0.9, 0}
local barWidth = 5
local barHeight = 25
local barHeightFactor = 1.0
local barMode = "fill"

local function drawBar(x, record)
    local barColor
    local ylow, yhigh

    print("record", inspect(record))
    if record.close > record.open then
        barColor = BAR_DOWN
        ylow = record.open
        yhigh = record.close
    else
        barColor = BAR_UP
        ylow = record.close
        yhigh = record.open
    end

    gr.setColor(barColor)
    gr.rectangle(barMode, sx + x, sy + ylow, barWidth, barHeight * barHeightFactor)
end

local __ONCE__ = false

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
            if not __ONCE__ then
                print("rec", inspect(rec))
                __ONCE__ = true
            end
        end
    end
    cam:detach()
end

local function drawui()
end

local function update(dt)
    controlCamera(cam)
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
