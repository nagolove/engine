require "log"
require "love"
require "camera"
require "common"

love.filesystem.setRequirePath("scenes/automato/?.lua")

local imgui = require "imgui"
local sim: Simulator = require "scenes/automato/simulator"
local gr = love.graphics
local inspect = require "inspect"
local cam: Camera
local scene: Scene

local automatoScene = require "scenes/automato/init"
local underCursor = {}

local function init(currentScene: Scene)
    log("Init cell tool.")
    if currentScene then
        scene = currentScene
        cam = scene.getCamera()
        scene = scene
    end
    local mx, my = love.mouse.getPosition()
    underCursor = {x = mx, y = my}
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    local w, h = gr.getDimensions()
    local tlx, tly, brx, bry = 0, 0, w, h

    if cam then
        tlx, tly = cam:worldCoords(tlx, tly)
        brx, bry = cam:worldCoords(brx, bry)
    end

    underCursor = {
        x = math.floor(x / automatoScene.getPixSize()),
        y = math.floor(y / automatoScene.getPixSize())
    }
end

local function getCell(pos: Pos): Cell
    if not pos or not pos.x or not pos.y then
        return nil
    end
    --print("pos", inspect(pos))
    print("sim.getGridSize()", sim.getGridSize())
    local size = sim.getGridSize()
    if size then
        local x, y = pos.x, pos.y
        if x + 1 >= 1 and x + 1 <= size and
            y + 1 >= 1 and y + 1 <= size then
                local cell = sim.getObject(x + 1, y + 1)
                return cell
            end
        end
    return nil
end

local function replaceCaret(str: string): string
    return string.gsub(str, "\n", "") as string
end

local function drawCellInfo(cell: Cell)
    if not cell then
        return
    end

    local msg: string
    for k, v in pairs(cell as {any: any}) do
        if k ~= "code" then
            local fmt: string
            --local functor: function<T>(T): T = nil

            --local function functor(a: number): number return a end
            local a: any
            local tp = type(v)
            if tp == "number" then
                fmt = "%d"
                a = tonumber(a)
            elseif tp == "table" then
                fmt = "%s"
                a = replaceCaret(inspect(a))
            else
                fmt = "%s"
                a = tostring(a)
            end
            msg = string.format(fmt, a)
            imgui.LabelText(k as string, msg)
        end
    end
end

local function drawCellPath(cell: Cell)
    if cell and cell.moves and #cell.moves >= 4 then
        local pixSize = automatoScene.getPixSize()
        local half = pixSize / 2
        local prevx, prevy = cell.moves[1], cell.moves[2]
        local i = 3
        while i <= #cell.moves do
            gr.setColor(1, 0, 0)
            gr.line(prevx * pixSize + half, 
                prevy * pixSize + half, 
                cell.moves[i] * pixSize + half, 
                cell.moves[i + 1] * pixSize + half)
            prevx, prevy = cell.moves[i], cell.moves[i + 1]
            i = i + 2
        end
    end
end

local function draw()
    imgui.Begin("cell", false, "ImGuiWindowFlags_AlwaysAutoResize")

    imgui.Text(string.format("mode %s", automatoScene.getMode()))

    if imgui.Button("change mode", automatoScene.getMode()) then
        automatoScene.nextMode()
    end

    if imgui.Button("reset silumation") then
        sim.create()
    end

    if sim.getStatistic() and sim.getStatistic().allEated then
        imgui.LabelText(sim.getStatistic().allEated, "all eated")
    end

    if underCursor then
        local cell = getCell(underCursor)
        drawCellInfo(cell)
        drawCellPath(cell)
    end

    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

function keypressed(key: string)
    if key == "p" then
    end
end

function update()
    local isDown = love.keyboard.isDown
    if isDown("z") then
        cam:zoom(1.01)
    elseif isDown("x") then
        cam:zoom(0.99)
    end
end

return {
    init = init,
    draw = draw,
    update = update,
    mousemoved = mousemoved,
    keypressed = keypressed,
}

