--[[
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
--]]

package.package = package.path .. ";./?/init.lua"
print("package.path", package.path)

--PROF_CAPTURE = true

if love.system.getOS() == 'Windows' then
    print('1 getCRequirePath() = ', love.filesystem.getCRequirePath())
    love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
    print('2 getCRequirePath() = ', love.filesystem.getCRequirePath())
end

--local argparse = require "argparse"
--local imgui = require "love-imgui"
--local imgui_nil = require "imgui_nil"
--local parser = argparse()
--local prof = require "jprof"
--local tools = require "tools"
local imgui = require "imgui"
local inspect = require "inspect"
local scenes = require "scenes"

require "common"
require "log"
require "keyconfig"

local showHelp = false
local gr = love.graphics
local imguiFontSize = 22

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

-- поиск аргумента командой строки. Возвращает истину или ложь.
local function searchArg(arg, paramName)
    if type(paramName) ~= 'string' then
        error(string.format('searchArg() paramName =  "%s"', paramName or ""))
    end
    print(inspect(arg))
    print(inspect(paramName))

    for _, v in pairs(arg) do
        if v == paramName then
            return true
        end
    end

    return false
end

-- поиск команды на запуск сцены. Возвращает строку команды или nilю
local function findCommand(arg)
    local commands = {}
    for i = 1, #arg do
        local s = arg[i]
        local ok, errmsg = pcall(function()
            if string.sub(s, 1, 1) ~= '-' and string.sub(s, 2, 2) ~= '-' then
                table.insert(commands, s)
            end
        end)
    end

    --print('commands', inspect(commands))
    if #commands > 1 then
        colprint('More then one command, sorry.')
        return nil
    end

    local list = scenes.getScenes()
    for _, v in pairs(list) do
        if v.name == commands[1] then
            return commands[1]
        end
    end

    return nil
end

function love.load(arg)
    imgui.Init()
    printGraphicsInfo()
    bindKeys()

    if searchArg(arg, '--debug') then
        require "mobdebug".start()
    end

    local sceneName = findCommand(arg) 

    --TODO : добавить загрузку произвольной сцены по пути.
    -- К примеру `./run ./some/local/path/to/directory/with/init.tl`
    -- Где `init.tl` представляет собой основной модуль сцены, 
    -- экспортирующий соответствующий интерфейс.
    -- Вопрос: какой интерфейс? Выделить `Module`
    if sceneName then
        scenes.initOne(sceneName)
    else
        scenes.initOne("empty")
    end

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
    if showHelp then
        KeyConfig.updateList(dt)
    end
    KeyConfig.update()
    collectGarbage()

    scenes.update(dt)
end

function love.draw()
    gr.setColor{1, 1, 1}
    scenes.draw()
    gr.setColor{1, 1, 1}

    imgui.NewFrame()
    scenes.drawui()
    imgui.Render();

    if showHelp then
        KeyConfig.draw()
    end
end

function love.quit()
    scenes.quit()
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
