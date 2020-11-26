-- возвращает таблицу вида {scene, name} со сцена из указанного каталога
function loadScenes(path)
    local scenes = {}
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
                table.insert(scenes, { scene = scene, name = name })
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
    return scenes
end

local scenes = loadScenes("scenes")

function setCurrentScene(sceneName)
    for k, v in pairs(scenes) do
        if sceneName == v.name then
            currentScene = v.scene
        end
    end
end

currentScene = nil

function initLoaded()
    for k, v in pairs(scenes) do
        local scene = v.scene
        local ok, errmsg = pcall(function()
            if scene.init then
                scene.init()
            end
        end)
        if not ok then
            logferror("Error in scene init %s", v.name)
        end
    end
end

function update()
    if currentScene and currentScene.update then
        currentScene.update(dt)
    end
end

function draw()
    if currentScene and currentScene.draw then
        currentScene.draw()
    end
end

function keypressed(key)
    if currentScene and currentScene.keypressed then
        currentScene.keypressed(key)
    end
end

return {
    getCurrentScene = function()
        return currentScene
    end,
    setCurrentScene = setCurrentScene,
    loadScenes = loadScenes,
    initLoaded = initLoaded,
    update = update,
    draw = draw,
    keypressed = keypressed,
}

