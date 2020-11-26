--:setlocal foldmethod=manual
require "imgui"
require "tools"
require "log"
local inspect = require "inspect"
local scenes = require "scenes"
local gr = love.graphics

__FREEZE_PHYSICS__ = true


function love.load(arg)
    scenes.loadScenes("scenes")
    scenes.initLoaded()

    --scenes.setCurrentScene("wavegrid")
    scenes.setCurrentScene("1")

    initTools(currentScene)
end

function updateScene(dt)
    scenes.update()
end

function love.update(dt)
    updateScene(dt)
    updateTools()
end

function love.draw()
   gr.setColor{1, 1, 1}
   scenes.draw()
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
       --if checkToolsHotkey(key) then
       if key == "f1" then
           toggleTools()
       end
       scenes.keypressed(key)
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

