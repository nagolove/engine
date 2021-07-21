require "love"
require "log"
require "common"

-- возвращает таблицу вида {scene, name} со сцена из указанного каталога
function loadScenes(path: string): {SceneMap}, {string}
    local scenes: {SceneMap} = {}
    local scenesNames: {string} = {}
    local files = love.filesystem.getDirectoryItems(path)
    for _, v in ipairs(files) do
        local info = love.filesystem.getInfo(path .. "/" .. v)
        local scene, fname, name: Scene, string, string
        if info.type == "directory" then
            fname = string.format("%s/%s%s", path, v, "/init.lua")
            name = v
        elseif info.type == "file" then
            fname = path .. "/" .. v
            name = string.match(v, "(.+)%.lua")
        end
        logf("loading scene %s", fname)
        local chunk, errmsg = love.filesystem.load(fname)
        if chunk then
            local ok, chunkerrmsg: boolean, string = pcall(function()
                --XXX Dynamic typing without checks in runtime, resetting
                -- compile-time checking
                scene = chunk() as Scene
            end)
            if ok and scene then
                table.insert(scenes, { 
                    scene = scene, 
                    name = name,
                    inited = false,
                })
                table.insert(scenesNames, name)
            else
                if chunkerrmsg then
                    logferror("Error: %s", errmsg)
                else
                    logferror("No file for loading: %s", fname)
                end
            end
        else
            logferror("Could'not load %s", fname, errmsg)
        end
    end
    return scenes, scenesNames
end

local scenes, scenesNames = loadScenes("scenes")
--local scenes, scenesNames: {SceneMap}, {string} = {}, {}
local currentScene: Scene = nil

local function getScenes(): {SceneMap}
    return scenes
end

local function initInternal(v: SceneMap)
    if not v.inited and v.scene.init then
        local ok, errmsg: boolean, string = pcall(function()
            v.scene.init()
        end)
        if not ok then
            --logferror("Could'not init scene %s: %s", v.name, errmsg)
            --v.maybebreaked = true
            error(string.format("Could'not init scene %s: %s", v.name, errmsg))
        end
        v.inited = true
    end
end

local function setCurrentScene(sceneName: string)
    for _, v in ipairs(scenes) do
        if sceneName == v.name then
            initInternal(v)
            currentScene = v.scene
        end
    end
end

local function initLoaded()
    for _, v in ipairs(scenes) do
        initInternal(v)
    end
end

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

local function initOne(name: string)
    -- TODO поддержка вложенных каталогов
    local path = "scenes/" .. name .. "/init.lua"
    print(string.format("initOne '%s'", path))
    local chunk, errmsg = love.filesystem.load(path)
    local node: SceneMap = {}
    if not chunk then
        error(string.format("Could not load '%s': %s", path, errmsg))
    end
    node.scene = chunk() as Scene
    if node.scene.init then
        print("------------ ↓↓↓↓↓↓↓↓↓↓ init ↓↓↓↓↓↓↓↓↓↓ ------------")
        node.scene.init()
        print("------------ ↑↑↑↑↑↑↑↑↑↑ init ↑↑↑↑↑↑↑↑↑↑ ------------")
    end
    node.name = name
    node.inited = true
    table.insert(scenes, node)
    currentScene = scenes[#scenes].scene
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

function getSceneNames(): {string}
    return scenesNames
end

return {
    getScenes = getScenes,
    getCurrentScene = getCurrentScene,
    getSceneNames = getSceneNames,
    setCurrentScene = setCurrentScene,
    --loadScenes = loadScenes,
    initLoaded = initLoaded,
    initOne = initOne,
    update = update,
    draw = draw,
    drawui = drawui,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousemoved = mousemoved,
    mousereleased = mousereleased,
    mousepressed = mousepressed,
    wheelmoved = wheelmoved,
    resize = resize,
    quit = quit,
}


