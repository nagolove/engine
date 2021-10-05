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

local imgui = nil
IMGUI_USE_STUB = false
local ok, errmsg = pcall(function()
    imgui = require 'imgui'
end)
if not ok then
    print('error:', errmsg)
    IMGUI_USE_STUB = true
end

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
    print("searchArg", paramName)

    for _, v in pairs(arg) do
        if v == paramName then
            return true
        end
    end

    return false
end

-- поиск команды на запуск сцены. Возвращает строку команды или nil.
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

    --[[
    local list = scenes.getScenes()
    for _, v in pairs(list) do
        if v.name == commands[1] then
            return commands[1]
        end
    end
    --]]

    return commands[1]
end

local function printAvaibleScenes()
    local list = scenes.getScenes()
    local tmp = {}
    for _, v in ipairs(list) do
        print('-------', v.name)
        table.insert(tmp, v.name)
    end
    print(inspect(tmp))
    print(inspect(table.concat(tmp, ',')))
    print("AVAIBLE SCENES: " .. table.concat(tmp, ','))
    colprint("AVAIBLE SCENES: " .. table.concat(tmp, ','))
end

function love.load(arg)
    if not IMGUI_USE_STUB then
        imgui.Init()
        imgui.SetGlobalFontFromArchiveTTF("fonts/DroidSansMono.ttf", imguiFontSize)
    end
    printGraphicsInfo()
    bindKeys()

    if searchArg(arg, '--debug') then
        require "mobdebug".start()
    end

    if searchArg(arg, '--silent') then
        require "mobdebug".start()
    end

    --[[
    if searchArg(arg, '--dev') then
        local fhd_width  = 1920
        local fhd_height = 1080
        local space = 20 -- in pixels.
        love.window.setPosition(fhd_width + space, space)
    end
    --]]

    print("love.load() arg", inspect(arg))

    local sceneName = findCommand(arg)

    --printAvaibleScenes()

    --TODO : добавить загрузку произвольной сцены по пути.
    -- К примеру `./run ./some/local/path/to/directory/with/init.tl`
    -- Где `init.tl` представляет собой основной модуль сцены, 
    -- экспортирующий соответствующий интерфейс.
    -- Вопрос: какой интерфейс? Выделить `Module`
    print("sceneName", sceneName)
    if sceneName then
        scenes.initOne(sceneName)
    else
        colprint("Empty scene will be runned.")
        scenes.initOne("empty")
    end

    --KeyConfig.printBinds()
    --imgui.SetGlobalFontFromFileTTF("fonts/DroidSansMono.ttf", imguiFontSize)
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

local lastWindowHeaderUpdateTime = love.timer.getTime()
local quant = 1 -- shoud be in s seconds. Real unit measure is unknown.
local titlePrefix = "caustic engine "
local fpsAccum = 0

function love.update(dt)
    local now = love.timer.getTime()
    if now - lastWindowHeaderUpdateTime > quant then
        love.window.setTitle(titlePrefix .. love.timer.getFPS())
    end

    if showHelp then
        KeyConfig.updateList(dt)
    end
    KeyConfig.update()
    collectGarbage()

    scenes.update(dt)
end

function love.resize(w, h)
    scenes.resize(w, h)
end

function love.draw()
    gr.setColor{1, 1, 1}
    scenes.draw()
    gr.setColor{1, 1, 1}

    if not IMGUI_USE_STUB then
        imgui.NewFrame()
        scenes.drawui()
        imgui.Render();
    end

    if showHelp then
        KeyConfig.draw()
    end
end

function love.quit()
    scenes.quit()
    if not IMGUI_USE_STUB then
        imgui.ShutDown();
    end
end

function love.textinput(t)
    if not IMGUI_USE_STUB then
        imgui.TextInput(t)
        if not imgui.GetWantCaptureKeyboard() then
            -- Pass event to the game
            scenes.textinput(t)
        end
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

    if not IMGUI_USE_STUB then
        imgui.KeyPressed(key)
        if not imgui.GetWantCaptureKeyboard() then
            KeyConfig.keypressed(key)
            scenes.keypressed(key)
            --tools.keypressed(key)
        end
    end
end

function love.keyreleased(_, key)
    if not IMGUI_USE_STUB then
        imgui.KeyReleased(key)
        if not imgui.GetWantCaptureKeyboard() then
            scenes.keyreleased(key)
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if not IMGUI_USE_STUB then
        imgui.MouseMoved(x, y)
        if not imgui.GetWantCaptureMouse() then
            --tools.mousemoved(x, y, dx, dy)
            scenes.mousemoved(x, y, dx, dy)
        end
    end
end

function love.mousepressed(x, y, button)
    if not IMGUI_USE_STUB then
        imgui.MousePressed(button)
        if not imgui.GetWantCaptureMouse() then
            --tools.mousepressed(x, y, button)
            scenes.mousepressed(x, y, button)
        end
    end
end

function love.mousereleased(x, y, button)
    if not IMGUI_USE_STUB then
        imgui.MouseReleased(button)
        if not imgui.GetWantCaptureMouse() then
            --tools.mousereleased(x, y, button)
            scenes.mousereleased(x, y, button)
        end
    end
end

function love.wheelmoved(x, y)
    if not IMGUI_USE_STUB then
        imgui.WheelMoved(y)
        if not imgui.GetWantCaptureMouse() then
            scenes.wheelmoved(x, y)
        end
    end
end

-- Где должен лежать этот код?
-- Локальный для каждой сцены. Код сцены.
local game_thread_code = [[
    require("love.timer")

    local event_channel = love.thread.getChannel("event_channel")
    local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
    local graphic_command_channel = love.thread.getChannel("graphic_command_channel")

    local accum = 0
    
    local mx, my = 0, 0
    
    local time = love.timer.getTime()
    local dt = 0
    
    while true do
        local events = event_channel:pop()
        if events then
            for _,e in ipairs(events) do
                if e[1] == "mousemoved" then
                    mx = e[2]
                    my = e[3]
                end
            end
        end
        
        local nt = love.timer.getTime()
        dt = nt - time
        time = nt

        if draw_ready_channel:peek() then
            -- Как передавать данные?
            graphic_command_channel:push({ mx, my })
            graphic_command_channel:push(tostring( math.floor( 1 / dt ) ) )
            draw_ready_channel:pop()
        end
        love.timer.sleep(0.001)
    end
]]

function love.run()
    local game_thread = love.thread.newThread( game_thread_code )

    headerUpdateTime = love.timer.getTime()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
                --print('n, a, b, c, d, e, f', n, a, b, c, d, e, f)
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

        --print('dt', dt)

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end
