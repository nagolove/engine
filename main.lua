--require("mobdebug").start()

-- :setlocal foldmethod=manual
local imgui = require "imgui"
local tools = require "tools"
local keyconfig = require "keyconfig"
require "log"
--require "menu"

local inspect = require "inspect"
local scenes = require "scenes"
local gr = love.graphics

__FREEZE_PHYSICS__ = true

local showHelp = false

local function bindKeys()
    keyconfig.bindKeyPressed("help", {"f1"}, function()
        print("tools toggle")
        showHelp = not showHelp
    end, "show hotkeys")
    keyconfig.bindKeyPressed("nope", {"f2"}, function()
        print("keybind example")
    end, "keybind example")
end

function love.load(arg)
    bindKeys()
    --scenes.loadScenes("scenes")
    --scenes.initLoaded()

    --scenes.initOne("selector")
    --scenes.setCurrentScene("selector")

    scenes.initOne("automato")
    --scenes.setCurrentScene("automato")

    --scenes.initOne("fractaltree")
    --scenes.setCurrentScene("fractaltree")

    --scenes.initOne("hst_reader")
    --scenes.setCurrentScene("hst_reader")

    --initTools(currentScene)
end

local lastGCTime = love.timer.getTime()
local GCPeriod = 1 * 60 * 5 -- 5 mins

local function collectGarbage()
  local now = love.timer.getTime()
  if now - lastGCTime > GCPeriod then
    collectgarbage()
    lastGCTime = now
  end
end

function love.update(dt)
  --tools.update()
  keyconfig.updateList(dt)
  keyconfig.checkDownKeys()
  collectGarbage()
  scenes.update(dt)
end

function love.draw()
  gr.setColor{1, 1, 1}
  scenes.draw()
  gr.setColor{1, 1, 1}

  imgui.NewFrame()
  scenes.drawui()
  love.graphics.setColor{1, 1, 1}
  imgui.Render();

  if showHelp then
      keyconfig.drawList()
  end
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

--[[
-- Иерархия вызовов?
-- keyconfig ?
-- scenes.keypressed ?
--]]
function love.keypressed(_, key)
  imgui.KeyPressed(key)
  if not imgui.GetWantCaptureKeyboard() then

    --if checkToolsHotkey(key) then
      --tools.toggle()
    --end

    keyconfig.checkPressedKeys(key)
    scenes.keypressed(key)
    tools.keypressed(key)
  end
end

function love.keyreleased(_, key)
  imgui.KeyReleased(key)
  if not imgui.GetWantCaptureKeyboard() then
    scenes.keyreleased(key)
  end
end

function love.mousemoved(x, y, dx, dy)
  imgui.MouseMoved(x, y)
  if not imgui.GetWantCaptureMouse() then
    tools.mousemoved(x, y, dx, dy)
    scenes.mousemoved(x, y, dx, dy)
  end
end

function love.mousepressed(x, y, button)
  imgui.MousePressed(button)
  if not imgui.GetWantCaptureMouse() then
    tools.mousepressed(x, y, button)
    scenes.mousepressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  imgui.MouseReleased(button)
  if not imgui.GetWantCaptureMouse() then
    tools.mousereleased(x, y, button)
    scenes.mousereleased(x, y, button)
  end
end

function love.wheelmoved(x, y)
  imgui.WheelMoved(y)
  if not imgui.GetWantCaptureMouse() then
    scenes.wheelmoved(x, y)
  end
end

