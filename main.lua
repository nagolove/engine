local ok, errmsg = pcall(function()
    require("mobdebug").start()
  end)
if not ok then
  print("Mobdebug start error", errmsg)
end

-- :setlocal foldmethod=manual
require "imgui"
require "tools"
require "log"

local inspect = require "inspect"
local scenes = require "scenes"
local gr = love.graphics

__FREEZE_PHYSICS__ = true

function processTLFiles(path)
  local files = love.filesystem.getDirectoryItems(path)
  for k, v in pairs(files) do
    local info = love.filesystem.getInfo(path .. "/" .. v)
    local scene, fname, name
    if info.type == "directory" then
      fname = string.format("%s/%s%s", path, v, "/init.lua")
      name = v
    elseif info.type == "file" then
      fname = path .. "/" .. v
      name = string.match(v, "(.+)%.tl")
    end
    logf("loading scene %s", fname)
    io.popen("lua5.3.exe tl check" .. fname)
  end
end

function love.load(arg)
  processTLFiles("")
  --scenes.loadScenes("scenes")
  --scenes.initLoaded()

  --scenes.initOne("selector")
  --scenes.setCurrentScene("selector")

  scenes.initOne("automato")
  scenes.setCurrentScene("automato")

  --scenes.initOne("hst_reader")
  --scenes.setCurrentScene("hst_reader")

  initTools(currentScene)
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

function updateScene(dt)
  collectGarbage()
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
  imgui.NewFrame()
  scenes.drawui()
  love.graphics.setColor{1, 1, 1}
  imgui.Render();
  --drawTools()
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

local toolsHotkeys = {"`", "f1"}

function checkToolsHotkey(key)
  for k, v in pairs(toolsHotkeys) do
    if key == v then
      return true
    end
  end
  return false
end

function love.keypressed(_, key)
  imgui.KeyPressed(key)
  if not imgui.GetWantCaptureKeyboard() then
    if checkToolsHotkey(key) then
      --toggleTools()
    end
    scenes.keypressed(key)
    keypressedTools(key)
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
    mousemovedTools(x, y, dx, dy)
    scenes.mousemoved(x, y, dx, dy)
  end
end

function love.mousepressed(x, y, button)
  imgui.MousePressed(button)
  if not imgui.GetWantCaptureMouse() then
    mousepressedTools(x, y, button)
    scenes.mousepressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  imgui.MouseReleased(button)
  if not imgui.GetWantCaptureMouse() then
    mousereleasedTools(x, y, button)
    scenes.mousereleased(x, y, button)
  end
end

function love.wheelmoved(x, y)
  imgui.WheelMoved(y)
  if not imgui.GetWantCaptureMouse() then
    scenes.wheelmoved(x, y)
  end
end

