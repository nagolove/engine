-- vim: fdm=marker
-- vim: set colorcolumn=85

require "love"
require "log"
require "common"

local inspect = require "inspect"

local currentScene: Scene = nil

local function update(dt: number)
    if currentScene and currentScene.update then
        currentScene.update(dt)
    end
end

local function resize(neww: integer, newh: integer)
    if currentScene and currentScene.resize then
        currentScene.resize(neww, newh)
    end
end

local function draw()
    if currentScene and currentScene.draw then
        currentScene.draw()
    end
end

local function drawui()
    if currentScene and currentScene.drawui then
        currentScene.drawui()
    end
end

local function keypressed(key: string)
    if currentScene and currentScene.keypressed then
        currentScene.keypressed(key)
    end
end

-- Загружает без проверок
local function initOneMulti(name: string): love.thread.Thread
    --local errmsg: string
    --local ok = false
    -- TODO поддержка вложенных каталогов
    local path = "scenes/" .. name .. "/init.lua"
    print(string.format("initOneMulti '%s'", path))

    --local chunk: any
    --chunk, errmsg = love.filesystem.load(path)
    local thread = love.thread.newThread(path)
    --local node: SceneMap = {}
    --if not chunk then
        --error(string.format("Could not load '%s': %s", path, errmsg))
    --end

    --ok, errmsg = pcall(function()
    --node.scene = chunk() as Scene
    --end)
    --local ok2, errmsg2: boolean, string = pcall(function()
        --node.scene = (chunk as function())() as Scene
    --end)

    --if not ok2 then
        --error('Something wrong in chunk:' .. errmsg2)
    --end


    --local isMulti: boolean = false
    --local ok4, errmsg4: boolean, string = pcall(function()
        --print("node.scene", inspect(node.scene))
        --isMulti = node.scene.getSceneType() == 'multi'
    --end)

    --if not ok4 then
        --print("use single thread mode", errmsg4)
    --else
        --print("use multi thread mode")

        ---- Здесь как-то нужно создать поток?
    --end

    --local ok3, errmsg3: boolean, string = pcall(function()
        --if node.scene.init then
            --print("------------ ↓↓↓↓↓↓↓↓↓↓ init ↓↓↓↓↓↓↓↓↓↓ ------------")
            ----[[
            --В каком месте создавать новый поток?
            ----]]
            --node.scene.init()
            --print("------------ ↑↑↑↑↑↑↑↑↑↑ init ↑↑↑↑↑↑↑↑↑↑ ------------")
        --end
    --end)

    --if not ok3 then
        --error('Something wrong in chunk:' .. errmsg3)
    --end

    --node.scene.isMulti = isMulti
    --node.name = name
    --node.inited = true
    --currentScene = node.scene
    return thread
end

local function initOne(name: string)
    local errmsg: string
    --local ok = false
    -- TODO поддержка вложенных каталогов
    local path = "scenes/" .. name .. "/init.lua"
    print(string.format("initOne '%s'", path))
    local chunk: any
    chunk, errmsg = love.filesystem.load(path)
    local node: SceneMap = {}
    if not chunk then
        error(string.format("Could not load '%s': %s", path, errmsg))
    end

    --ok, errmsg = pcall(function()
    --node.scene = chunk() as Scene
    --end)
    local ok2, errmsg2: boolean, string = pcall(function()
        node.scene = (chunk as function())() as Scene
    end)

    if not ok2 then
        error('Something wrong in chunk:' .. errmsg2)
    end


    local isMulti: boolean = false
    local ok4, errmsg4: boolean, string = pcall(function()
        print("node.scene", inspect(node.scene))
        isMulti = node.scene.getSceneType() == 'multi'
    end)

    if not ok4 then
        print("use single thread mode", errmsg4)
    else
        print("use multi thread mode")

        -- Здесь как-то нужно создать поток?
    end

    local ok3, errmsg3: boolean, string = pcall(function()
        if node.scene.init then
            print("------------ ↓↓↓↓↓↓↓↓↓↓ init ↓↓↓↓↓↓↓↓↓↓ ------------")
            --[[
            В каком месте создавать новый поток?
            --]]
            node.scene.init()
            print("------------ ↑↑↑↑↑↑↑↑↑↑ init ↑↑↑↑↑↑↑↑↑↑ ------------")
        end
    end)

    if not ok3 then
        error('Something wrong in chunk:' .. errmsg3)
    end

    node.scene.isMulti = isMulti
    node.name = name
    node.inited = true
    currentScene = node.scene
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    if currentScene and currentScene.mousemoved then
        currentScene.mousemoved(x, y, dx, dy)
    end
end

local function mousereleased(x: number, y: number, btn: number)
    if currentScene and currentScene.mousereleased then
        currentScene.mousereleased(x, y, btn)
    end
end

local function mousepressed(x: number, y: number, btn: number)
    if currentScene and currentScene.mousepressed then
        currentScene.mousepressed(x, y, btn)
    end
end

local function keyreleased(_: string, key: string)
    if currentScene and currentScene.keyreleased then
        currentScene.keyreleased(key)
    end
end

local function wheelmoved(x: number, y: number)
    if currentScene and currentScene.wheelmoved then
        currentScene.wheelmoved(x, y)
    end
end

local function quit()
    if currentScene and currentScene.quit then
        currentScene.quit()
    end
end

local function getCurrentScene(): Scene
    return currentScene
end

local function textinput(text: string)
    if currentScene and currentScene.textinput then
        currentScene.textinput(text)
    end
end

return {
    --[[
    Переписать интерфейс менеджера сцен.
    --]]

    getCurrentScene = getCurrentScene,

    initOne = initOne,
    initOneMulti = initOneMulti,

    update = update,
    draw = draw,
    drawui = drawui,
    textinput = textinput,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousemoved = mousemoved,
    mousereleased = mousereleased,
    mousepressed = mousepressed,
    wheelmoved = wheelmoved,
    resize = resize,
    quit = quit,
}


