--:setlocal foldmethod=manual
require "imgui"
require "tools"
local inspect = require "inspect"

local gr = love.graphics

__FREEZE_PHYSICS__ = true

function searchScenes(path)
    local scenes = {}
    local files = love.filesystem.getDirectoryItems(path)
    for k, v in pairs(files) do
        local info = love.filesystem.getInfo(path .. "/" .. v)
        print("info", inspect(info))
        local scene
        local ok, errmsg
        if info.filetype == "directory" then
            ok, errmsg = pcall(function()
                scene = love.filesystem.load(string.format("%s/%s%s", path, v, "/init.lua"))
            end)
        elseif info.filetype == "file" then
            ok, errmsg = pcall(function()
                scene = love.filesystem.load(path .. "/" .. v)
            end)
        end
        if ok and scene then
            table.insert(scenes, { scene = scene, name = v })
        else
            print(string.format("Error: %s", errmsg))
        end
    end
    return scenes
end

local scenes = searchScenes("scenes")
print("scenes", inspect(scenes))
--scenes[1] = love.filesystem.load("scenes/1.lua")()
--scenes[2] = love.filesystem.load("scenes/2.lua")()
function setCurrentScene(sceneName)
    for k, v in pairs(scenes) do
        if sceneName == v.name then
            currentScene = v.scene
        end
    end
end

currentScene = nil

function initScenes()
    for k, v in pairs(scenes) do
        if v.init then
            v.init()
        end
    end
end

function love.load(arg)
    initScenes()
    --currentScene = scenes[2]
    setCurrentScene("2")
    initTools(currentScene)
end

function updateScene(dt)
    if currentScene and currentScene.update then
        currentScene.update(dt)
    end
end

function love.update(dt)
    updateScene(dt)
    updateTools()
end

function drawScene()
    if currentScene and currentScene.draw then
        currentScene.draw()
    end
end

function love.draw()
   gr.setColor{1, 1, 1}
   drawScene()
   gr.setColor{1, 1, 1}
   drawTools()
end

function love.quit()
   imgui.ShutDown();
end

function love.textinput(t)
   imgui.TextInput(t)
   if not imgui.GetWantCaptureKeyboard() then
       -- Pass event to the game
   end
end

function keypressedScene(key)
    if currentScene and currentScene.keypressed then
        currentScene.keypressed(key)
    end
end

local toolsHotkes = {"`", "f1"}

function checkToolsHotkey(key)
    for k, v in pairs(toolsHotkes) do
        if key == v then
            return true
        end
    end
    return false
end

function love.keypressed(_, key)
   imgui.KeyPressed(key)
   if not imgui.GetWantCaptureKeyboard() then
       --if key == "`" then
       if checkToolsHotkey(key) then
           toggleTools()
       end
       keypressedScene(key)
       keypressedTools(key)
   end
end

function love.keyreleased(_, key)
   imgui.KeyReleased(key)
   if not imgui.GetWantCaptureKeyboard() then
       -- Pass event to the game
   end
end

function love.mousemoved(x, y, dx, dy)
   imgui.MouseMoved(x, y)
   if not imgui.GetWantCaptureMouse() then
       mousemovedTools(x, y, dx, dy)
   end
end

function love.mousepressed(x, y, button)
   imgui.MousePressed(button)
   if not imgui.GetWantCaptureMouse() then
       mousepressedTools(x, y, button)
   end
end

function love.mousereleased(x, y, button)
   imgui.MouseReleased(button)
   if not imgui.GetWantCaptureMouse() then
       mousereleasedTools(x, y, button)
   end
end

function love.wheelmoved(x, y)
   imgui.WheelMoved(y)
   if not imgui.GetWantCaptureMouse() then
       -- Pass event to the game
   end
end

