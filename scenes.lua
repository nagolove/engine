local imgui = require "imgui"

-- возвращает таблицу вида {scene, name} со сцена из указанного каталога
function loadScenes(path)
    local scenes = {}
    local scenesNames = {}
    local files = love.filesystem.getDirectoryItems(path)
    for k, v in pairs(files) do
        local info = love.filesystem.getInfo(path .. "/" .. v)
        local scene, fname, name
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
            local ok, errmsg = pcall(function()
                scene = chunk()
            end)
            if ok and scene then
                table.insert(scenes, { 
                    scene = scene, 
                    name = name,
                    inited = false,
                })
                table.insert(scenesNames, name)
            else
                if errmsg then
                    logferror("Error: %s", errmsg)
                else
                    logferror("No file for loading: %s", fname)
                end
            end
        else
            logferror("Could'not load %s", fname)
        end
    end
    return scenes, scenesNames
end

local scenes, scenesNames = loadScenes("scenes")

local function getScenes()
    return scenes
end

local function initInternal(v)
    if not v.inited and v.scene.init then
        local ok, errmsg = pcall(function()
            v.scene.init()
        end)
        if not ok then
            logferror("Could'not init scene %s: %s", v.name, errmsg)
            v.maybebreaked = true
        end
        v.inited = true
    end
end

local function setCurrentScene(sceneName)
    for k, v in pairs(scenes) do
        if sceneName == v.name then
            initInternal(v)
            currentScene = v.scene
        end
    end
end

currentScene = nil

local function initLoaded()
    for k, v in pairs(scenes) do
        initInternal(v)
    end
end

local function update()
    if currentScene and currentScene.update then
        currentScene.update(dt)
    end
end

local function draw()
    if currentScene and currentScene.draw then
        currentScene.draw()
    end
end

local function keypressed(key)
    if currentScene and currentScene.keypressed then
        currentScene.keypressed(key)
    end
end

local function initOne(name)
    for k, v in pairs(getScenes()) do
        if v.name == name then
            initOne(v)
            break
        end
    end
end

return {
    getCurrentScene = function()
        return currentScene
    end,
    getScenes = getScenes,
    setCurrentScene = setCurrentScene,
    loadScenes = loadScenes,
    initLoaded = initLoaded,
    initOne = initOne,
    update = update,
    draw = draw,
    keypressed = keypressed,
}

