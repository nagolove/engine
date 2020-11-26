local serpent = require "serpent"
local gr = love.graphics
local vec2 = require "vector"
local inspect = require "inspect"
local pworld, cam
local scene

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local scalePoint2CameraWorldCoords = scale.point2CameraWorldCoords
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local lines = {}
local currentLine

local levels = {}
local selectedLevel
local drawTextured

local mesh
local newCam
local state = "drawing"

local function computeMesh(lines)
    if #lines == 0 then
        return
    end

    local mesh = gr.newMesh((#lines / 4) * 6, "triangles", "dynamic")

    local j = 1
    local i = 1
    --print("mesh:getVertexCount()", mesh:getVertexCount())
    while i <= #lines do
        --print("i", i)
        --print("j", j)

        addLine2Mesh(mesh, j, lines[i], lines[i + 1], lines[i + 2], lines[i + 3])

        i = i + 4
        j = j + 6
    end

    return mesh
end


local function findLevels()
    local res = {}
    local files = love.filesystem.getDirectoryItems("terrains/")
    for k, v in pairs(files) do
        if v:match(".+%.lua") then
            table.insert(res, v)
        end
    end
    return res
end

local function init(currentScene)
    --print("terraintool.init", inspect(currentScene))
    if currentScene then
        pworld = currentScene.pworld
        cam = currentScene.cam
    else
        cam = require "camera".new()
    end
    levels = findLevels()
end

local function drawLine(line)
    gr.setColor{1, 1, 1}
    if not line[3] and not line[4] then
        local mx, my = cam:worldCoords(love.mouse.getPosition())
        gr.line(line[1], line[2], mx, my)
    end
end

local function drawLines()
    if not lines then
        return
    end

    if #lines < 4 then
        return
    end

    local i = 1
    while i + 3 <= #lines do
        local l = lines
        gr.line(l[i], l[i + 1], l[i + 2], l[i + 3])
        i = i + 4
    end
end

local function drawAxes()
    local mx, my = love.mouse.getPosition()
    gr.setColor{0.5, 0.5, 0.5}
    local len = 700
    gr.line(mx, my, mx + len, my)
    gr.line(mx, my, mx - len, my)
    gr.line(mx, my, mx, my - len)
    gr.line(mx, my, mx, my + len)
end

local function loadLevel(path)
    print("loadLevel", path)
    local data, _ = love.filesystem.read(path)
    local ok, newlines = serpent.load(data)
    if not ok then
        error("Could'not load level")
    end
    print("lines", newlines)

    currentScene = love.filesystem.load("scenes/1.lua")()
    currentScene.init(loadstring(data)())
    --print("currentScene", inspect(currentScene))
    initTools(currentScene)

    lines = newlines
end

function dumpMesh(mesh)
    local verts = {}
    for i = 1, mesh:getVertexCount() do
        table.insert(verts, {mesh:getVertex(i)})
    end
    return verts
end

local function buildLevel()
    mesh = computeMesh(lines)
    if not mesh then
        return
    end

    return serpent.dump({
        mesh = dumpMesh(mesh),
        lines = lines,
        cam = newCam,
    })
end

local function saveLevel()
    local saveName = levels[#levels]
    if not saveName then
        saveName = "1.lua"
    else
        saveName = saveName:gsub("%d+", function(s)
            return tonumber(s) + 1
        end)
    end

    local lvlData = buildLevel()

    if lvlData then

        love.filesystem.createDirectory("terrains")
        love.filesystem.write("terrains/" .. saveName, lvlData)

        print("saveName", saveName)
        levels = findLevels()
    end
end

local function drawState()
    if state == "drawing" then
        imgui.TextColored(1, 1, 0, 1, "drawing")
    elseif state == "camera setup" then
        imgui.TextColored(1, 1, 0.1, 1, "drawing")
    end
end

local function drawTerrainToolBox()
    imgui.Begin("terrain", true, "ImGuiWindowFlags_AlwaysAutoResize")

    if imgui.Button("new level") then
        mesh = nil
        lines = nil
        cam.scale = 1.
        currentLine = nil
        currentScene = love.filesystem.load("scenes/1.lua")()
        currentScene.init()
    end

    imgui.SameLine()

    if imgui.Button("save level") then
        saveLevel()
    end

    imgui.SameLine()
    if imgui.Button("load level") and selectedLevel then
        loadLevel("terrains/" .. levels[selectedLevel])
    end
    imgui.SameLine()

    if imgui.Button("load selected 'in-game'") then
        local lvl = buildLevel()
        if lvl then
            currentScene = love.filesystem.load("scenes/1.lua")()
            currentScene.init(loadstring(lvl)())
            --print("currentScene", inspect(currentScene))
            initTools(currentScene)
        end
    end
    
    if imgui.Button("setup level camera") then
        newCam = shallowCopy(cam)
    end

    if imgui.Button("draw textured") then
        drawTextured = not drawTextured
        mesh = computeMesh(lines)
    end

    drawState()

    selectedLevel = selectedLevel or 1
    local num, selected = imgui.ListBox("levels", selectedLevel, levels, #levels, 5)
    if selected then
        selectedLevel = num
    end

    imgui.End()

    cam:attach()

    if mesh then
        gr.draw(mesh)
    end

    if currentLine then
        drawLine(currentLine)
    end
    drawLines()

    cam:detach()

    drawAxes()
end

local function mousereleased(x, y, btn)
    --print("mousereleased", x, y, btn)
end

local function mousepressed(x, y, btn)
    print("mousepressed", x, y, btn)

    local isDown = love.keyboard.isDown

    x, y = cam:worldCoords(x, y)

    if not currentLine then
        currentLine = {}
        local nx, ny = x, y
        table.insert(currentLine, nx)
        table.insert(currentLine, ny)
    else
        local nx, ny = x, y
        table.insert(currentLine, nx)
        table.insert(currentLine, ny)
        if not lines then
            lines = {}
        end
        for k, v in pairs(currentLine) do
            table.insert(lines, v)
        end
        currentLine = {nx, ny}
    end
end

local function undo()
    print("undo")
end

local function keypressed(key)
    local isDown = love.keyboard.isDown
    if isDown("lctrl") and key == "z" then
        undo()
    end
end

return {
    init = init,
    draw = drawTerrainToolBox,
    update = update,
    mousemoved = mousemoved,
    keypressed = keypressed,
    mousepressed = mousepressed,
    mousereleased = mousereleased,
}


