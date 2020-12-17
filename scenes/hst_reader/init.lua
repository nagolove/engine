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
local selectedBar

--package.path = package.path .. ";scenes/hst_reader/?.lua"
local threadPath = "scenes/hst_reader/file-thread.lua"

local function init()
    -- проблема со временем запуска этого кода на выполнение
    thread = love.thread.newThread(threadPath)
    love.thread.getChannel("fname"):push(histPath)
    thread:start(1)
    -- задержка что-бы успели загрузиться фреймы на ширину экрана
    love.timer.sleep(0.3)
end

-- стартовые позиции для рисования
local sx, sy = 0, 0

local WHITE = {1, 1, 1, 1}
local BAR_DOWN = {0.9, 0, 0}
local BAR_UP = {0, 0.9, 0}
local BAR_EQUAL = {0.5, 0.5, 0.5}
local BAR_SELECTED = {0, 0.1, 1}
local barWidth = 5
--local barHeight = 25
local barHeightFactor = 100000
local barMode = "fill"

local ylowFactor = 5
local barStep = math.floor(barWidth * 1.5)

local barX, barY = sx, sy
local visibleFrames = {}

local function drawBar(x, record)
    local barColor
    local ylow, yhigh

    if record.close > record.open then
        barColor = BAR_DOWN
    elseif record.close < record.open then
        barColor = BAR_UP
    else
        barColor = BAR_EQUAL
    end

    ylow = math.min(record.open, record.close)
    yhigh = math.max(record.open, record.close)

    if selectedBar and selectedBar == x then
        barColor = BAR_SELECTED
    end

    gr.setColor(barColor)
    local barHeight = yhigh - ylow
    barX, barY = sx + x * barStep, sy + math.exp(ylow * ylowFactor) * 1
    local w, h = barWidth, barHeight * barHeightFactor
    local screenW, screenH = gr.getDimensions()

    if barY > screenH then
        sy = sy - 1
    end

    gr.rectangle(barMode, barX, barY, w, h)
    table.insert(visibleFrames, { barX, barY, w, h, absIndex = x})

    if selectedBar and selectedBar == x then
        gr.setColor(WHITE)
        local mx, my = love.mouse.getPosition()
        local str = string.format("%s\nopen %f\n close %f", 
            os.date("%Y, %m, %d %H:%M:%S", record.ctm),
            record.open, record.close)
        gr.print(str, mx, my)
    end
end

local msgChannel = love.thread.getChannel("msg")

package.path = package.path .. ";scenes/hst_reader/?.lua"
local w, h = gr.getDimensions()
local maxHorizontalBars = math.floor(w / barStep)
print("maxHorizontalBars", maxHorizontalBars)
local drawingRange = require "drawingrange".newDrawingRange(1, maxHorizontalBars)

print("drawingRange", inspect(drawingRange))

local function draw()
    cam:attach()
    --msgChannel:clear()
   
    visibleFrames = {}
    local min, max = 10000, -10000
    for i = drawingRange.from, drawingRange.to do
        msgChannel:push("get")
        msgChannel:push(i)
        local rec = love.thread.getChannel("data"):demand(0.01)
        if rec then 
            if rec.open < min then
                min = rec.open
            end
            if rec.close < min then
                min = rec.close
            end
            if rec.open > max then
                max = rec.open
            end
            if rec.close > max then
                max = rec.close
            end
            drawBar(i, rec)
        end
    end

    kons:pushi("min %f", min)
    kons:pushi("max %f", max)

    cam:detach()
    kons:pushi("ylowFactor %f", ylowFactor)
    kons:draw()
end

local function drawui()
end

local isDown = love.keyboard.isDown
local horizontalSpeed = 5

-- проследи индексы - с 0 или с 1??
local rangeShift = 5
local function moveLeft()
    local before = drawingRange.from
    drawingRange.from = drawingRange.from - rangeShift
    if drawingRange.from ~= before then
        cam:move(-barStep * rangeShift, 0)
    end
end

local function moveRight()
    drawingRange.from = drawingRange.from + rangeShift
    cam:move(barStep * rangeShift, 0)
end

local function correctExpVisibility()
    -- полоса хорошей видимости по вертикали - от и до пикселей, когда подгонка
    -- по высоте смещением не включается
    local factor = 0.3
    local verticalRange = { math.floor(w * factor), w - math.floor(w * factor)}

    --print("barY", barY)
    --[[
       [if barY > h / 2 then
       [    sy = sy - math.abs(h - barY)
       [    print("correction", math.abs(h - barY))
       [end
       [if barY < 0 then
       [    sy = sy + math.abs(0 - barY)
       [end
       ]]
end

local function update(dt)
    kons:update(dt)
    controlCamera(cam)

    correctExpVisibility()

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

    if not isDown("lshift") then
        if isDown("left")then
            moveLeft()
        elseif isDown("right") then
            moveRight()
        elseif isDown("up") then
            cam:move(0, cameraSettings.dy / cam.scale)
        elseif isDown("down") then
            cam:move(0, -cameraSettings.dy / cam.scale)
        end
    end

    msgChannel:push("len")
    --local len = love.thread.getChannel("data"):demand(0.01)
    local len = love.thread.getChannel("len"):pop()
    drawingRange:setBorders(1, len)

    kons:pushi("frames count %d", len or 0)
end

local function keypressed(key)
    if key == "escape" then
        love.quit()
    end
end

local zoomFactor = 0.1

local function wheelmoved(x, y)
    if y == 1 then
        cam:zoom(1.0 + zoomFactor)
    elseif y == -1 then
        cam:zoom(1.0 - zoomFactor)
    end
end

local function inRect(xp, yp, x, y, w, h)
    if xp >= x and xp <= x + w and yp >= y and yp <= y + h then
        return true
    else
        return false
    end
end

local function mousemoved(x, y, dx, dy)
    local found = false
    for k, v in pairs(visibleFrames) do
        if inRect(x, y, v[1], v[2], v[3], v[4]) then
            --print("cam", inspect(cam))
            selectedBar = v.absIndex
            found = true
            print("selected", v.absIndex)
            break
        end
    end
    if not found then
        selectedBar = nil
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
    mousemoved = mousemoved,
    keypressed = keypressed,
    wheelmoved = wheelmoved,
}
