local flag = false

function testDraw()
    if flag then
        for i = 1, 1000 do
            local w, h = love.graphics.getDimensions()
            x, y = math.random(1, w), math.random(1, h)
            a = math.deg(i)
            local qw, qh = 64, 64
            love.graphics.rectangle("fill", x, y, qw, qh)
        end
    end
end

--local profi = require "profi"
--[[
local t = {}
for i = 1, 100000 do
    table.insert(t, i)
end
--]]

local jit = require "jit"
--_G['print'] = function() end
--jit.on()
-- :setlocal foldmethod=manual
--require "mobdebug".start()
package.package = package.path .. ";./?/init.lua"
--package.cpath = package.cpath .. ";?.so"
print("package.path", package.path)

--PROF_CAPTURE = true

print('1 getCRequirePath() = ', love.filesystem.getCRequirePath())
--love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";./lib/?.dll")
love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
print('2 getCRequirePath() = ', love.filesystem.getCRequirePath())

--local prof = require "jprof"
--local imgui_nil = require "imgui_nil"
local imgui = require "imgui"
--local imgui = require "love-imgui"
local inspect = require "inspect"
local scenes = require "scenes"
local imgui = require "imgui"

--local tools = require "tools"

local showHelp = false
local gr = love.graphics
local imguiFontSize = 22

require "log"
require "keyconfig"

local argparse = require "argparse"
local parser = argparse()

love.filesystem.write("syslog.txt", "identity = " .. love.filesystem.getIdentity())

--__FREEZE_PHYSICS__ = true

local function bindKeys()
    KeyConfig.bind(
        "keypressed",
        { key = "f1" }, 
        function(sc)
            print("tools toggle")
            showHelp = not showHelp
            return false, sc
        end, 
        "show hotkeys and documentation",
        "help"
    )

    KeyConfig.bind(
        "isdown",
        { key = "f2" }, 
        function(sc)
            print("keybind example")
            return false, sc
        end, 
        "keybind example",
        "nope"
    )
end

function printGraphicsInfo()
    local name, version, vendor, device = love.graphics.getRendererInfo( )
    print(name, version, vendor, device)
    local stats = love.graphics.getStats( )
    print("stats", inspect(stats))
    local features = love.graphics.getSupported( )
    print("features", inspect(features))
    local limits = love.graphics.getSystemLimits( )
    print("limits", inspect(limits))
    local texturetypes = love.graphics.getTextureTypes( )
    print("texturetypes", inspect(texturetypes))
    --local pointsize = love.graphics.getMaxPointSize( )
    --print("pointsize", inspect(features))
    local imageformats = love.graphics.getImageFormats( ) 
    print("imageformats", inspect(imageformats))
    local canvasformats = love.graphics.getCanvasFormats( )
    print("canvasformats", inspect(canvasformats))
end

function love.load(arg)
    imgui.Init()
    printGraphicsInfo()
    bindKeys()

    --scenes.loadScenes("scenes")
    --scenes.initLoaded()

    --scenes.initOne("selector")
    --scenes.setCurrentScene("selector")
   
    if love.system.getOS() == "Android" then
        scenes.initOne("automato")
    else
        --TODO : добавить загрузку произвольной сцены по пути.
        -- К примеру `./run ./some/local/path/to/directory/with/init.tl`
        -- Где `init.tl` представляет собой основной модуль сцены, 
        -- экспортирующий соответствующий интерфейс.
        -- Вопрос: какой интерфейс? Выделить `Module`
        scenes.initOne(arg[1] or "empty")
    end
    --]]

    --scenes.initOne("nback2")
    --scenes.initOne("hexfield")
    --scenes.initOne("automato")
    --scenes.initOne("fractaltree")
    --scenes.initOne("hst_reader")

    --initTools(currentScene)
    KeyConfig.printBinds()
    --imgui.SetGlobalFontFromFileTTF("fonts/DroidSansMono.ttf", imguiFontSize)
    imgui.SetGlobalFontFromArchiveTTF("fonts/DroidSansMono.ttf", imguiFontSize)
end

local lastGCTime = love.timer.getTime()
local GCPeriod = 1 * 60 * 5 -- 5 mins

-- сборка мусора по таймеру
local function collectGarbage()
    local now = love.timer.getTime()
    if now - lastGCTime > GCPeriod then
        collectgarbage()
        lastGCTime = now
    end
end

function love.update(dt)
    --prof.push("frame")
    --tools.update()
    
    if showHelp then
        KeyConfig.updateList(dt)
    end
    KeyConfig.update()
    collectGarbage()

    --]]

    --prof.push("zone1")
    scenes.update(dt)
    --prof.pop("zone1")

end

function love.draw()
    --gr.print(string.format("%d fps", love.timer.getFPS()))
    --testDraw()

    --prof.push("scenes")
    gr.setColor{1, 1, 1}
    scenes.draw()
    gr.setColor{1, 1, 1}
    --prof.pop("scenes")

    --prof.push("imgui")
    imgui.NewFrame()
    scenes.drawui()
    --love.graphics.setColor{1, 1, 1}
    imgui.Render();
    --prof.pop("imgui")

    if showHelp then
        KeyConfig.draw()
    end

    --prof.pop("frame")
    ----]]
end

function love.quit()
    scenes.quit()
    imgui.ShutDown();
    --print("1")
    --prof.write("prof.mpack")
    --print("2")
    --profi:writeReport("automato.txt")
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
    if key == "q" then
        flag = not flag
    end

    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        KeyConfig.keypressed(key)
        scenes.keypressed(key)
        --tools.keypressed(key)
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
    --tools.mousemoved(x, y, dx, dy)
    scenes.mousemoved(x, y, dx, dy)
  end
end

function love.mousepressed(x, y, button)
  imgui.MousePressed(button)
  if not imgui.GetWantCaptureMouse() then
    --tools.mousepressed(x, y, button)
    scenes.mousepressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  imgui.MouseReleased(button)
  if not imgui.GetWantCaptureMouse() then
    --tools.mousereleased(x, y, button)
    scenes.mousereleased(x, y, button)
  end
end

function love.wheelmoved(x, y)
  imgui.WheelMoved(y)
  if not imgui.GetWantCaptureMouse() then
    scenes.wheelmoved(x, y)
  end
end
