local histPath = [[C:/Users/dekar/Desktop/tick history/EURUSD999.hst]]
local thread
local selectedBar
local threadPath = "scenes/hst_reader/file-thread.lua"
local sx, sy = 0, 0
local WHITE = {1, 1, 1, 1}
local BAR_DOWN = {0.9, 0, 0}
local BAR_UP = {0, 0.9, 0}
local BAR_EQUAL = {0.5, 0.5, 0.5}
local BAR_SELECTED = {0, 0.1, 1}
local barWidth = 5
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

    gr.rectangle(barMode, barX, barY, w, h)
    table.insert(visibleFrames, { barX + cam.x, barY + cam.y, w, h, absIndex = x})
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

