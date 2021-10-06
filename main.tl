require "jitoptions".on()

require "love"

--local package = require "package"
--package.package = package.path .. ";./?/init.lua"
print("package.path", package.path)

if love.system.getOS() == 'Windows' then
    print('1 getCRequirePath() = ', love.filesystem.getCRequirePath())
    love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
    print('2 getCRequirePath() = ', love.filesystem.getCRequirePath())
end

require 'imgui'
local IMGUI_USE_STUB = false

local inspect = require "inspect"
local scenes = require "scenes"

require "common"
require "log"
require "keyconfig"

local showHelp = false
local gr = love.graphics
local imguiFontSize = 22

love.filesystem.write("syslog.txt", "identity = " .. love.filesystem.getIdentity())

local Shortcut = KeyConfig.Shortcut

local function bindKeys()
    KeyConfig.bind(
        "keypressed",
        { key = "f1" }, 
        function(sc: Shortcut): boolean, Shortcut
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
        function(sc: Shortcut): boolean, Shortcut
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
local function searchArg(arg: {string}, paramName: string): boolean
    if type(paramName) ~= 'string' then
        error(string.format('searchArg() paramName =  "%s"', paramName or ""))
    end
    print("searchArg", paramName)

    for _, v in ipairs(arg) do
        if v == paramName then
            return true
        end
    end

    return false
end

-- поиск команды на запуск сцены. Возвращает строку команды или nil.
local function findCommand(arg: {string}): string
    local commands = {}
    for i = 1, #arg do
        local s = arg[i]
        local ok, errmsg: boolean, string = pcall(function()
            if string.sub(s, 1, 1) ~= '-' and string.sub(s, 2, 2) ~= '-' then
                table.insert(commands, s)
            end
        end)
        if not ok then
            error('something strange in findCommand: ' .. errmsg)
        end
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

--local function printAvaibleScenes()
    --local list = scenes.getScenes()
    --local tmp = {}
    --for _, v in ipairs(list) do
        --print('-------', v.name)
        --table.insert(tmp, v.name)
    --end
    --print(inspect(tmp))
    --print(inspect(table.concat(tmp, ',')))
    --print("AVAIBLE SCENES: " .. table.concat(tmp, ','))
    --colprint("AVAIBLE SCENES: " .. table.concat(tmp, ','))
--end

function love.load(arg: {string})
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
--local fpsAccum = 0

function love.update(dt: number)
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

function love.resize(w: integer, h: integer)
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

function love.quit(): boolean
    scenes.quit()
    if not IMGUI_USE_STUB then
        imgui.ShutDown();
    end
end

function love.textinput(t: string)
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

function love.keyreleased(key: love.keyboard.KeyConstant, _: love.keyboard.Scancode)
--function love.keyreleased(_, key)
    if not IMGUI_USE_STUB then
        imgui.KeyReleased(key)
        if not imgui.GetWantCaptureKeyboard() then
            scenes.keyreleased(key)
        end
    end
end

function love.keypressed(_: string, key: string)
    if not IMGUI_USE_STUB then
        imgui.KeyPressed(key)
        if not imgui.GetWantCaptureKeyboard() then
            KeyConfig.keypressed(key)
            scenes.keypressed(key)
            --tools.keypressed(key)
        end
    end
end

function love.mousemoved(x: number, y: number, dx: number, dy: number)
    if not IMGUI_USE_STUB then
        imgui.MouseMoved(x, y)
        if not imgui.GetWantCaptureMouse() then
            --tools.mousemoved(x, y, dx, dy)
            scenes.mousemoved(x, y, dx, dy)
        end
    end
end

function love.mousepressed(x: number, y: number, button: number)
    if not IMGUI_USE_STUB then
        imgui.MousePressed(button)
        if not imgui.GetWantCaptureMouse() then
            --tools.mousepressed(x, y, button)
            scenes.mousepressed(x, y, button)
        end
    end
end

function love.mousereleased(x: number, y: number, button: number)
    if not IMGUI_USE_STUB then
        imgui.MouseReleased(button)
        if not imgui.GetWantCaptureMouse() then
            --tools.mousereleased(x, y, button)
            scenes.mousereleased(x, y, button)
        end
    end
end

function love.wheelmoved(x: number, y: number)
    if not IMGUI_USE_STUB then
        imgui.WheelMoved(y)
        if not imgui.GetWantCaptureMouse() then
            scenes.wheelmoved(x, y)
        end
    end
end

function love.run(): function(): string|number
    --headerUpdateTime = love.timer.getTime()
    local tmp = require 'parse_args'
    --if love.load then love.load(tmp.parseGameArguments(arg), arg) end
    if love.load then love.load(tmp.parseGameArguments(arg)) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0.

	-- Main loop time.
	return function(): string|number
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
                --print('n, a, b, c, d, e, f', n, a, b, c, d, e, f)
				if name == "quit" then
					if not love.quit or not love.quit() then
						--return a or 0
                        -- XXX нет проверки возвращаемого значения
						return (a or 0) as string
					end
				end
                tmp.callHandler(name, a, b, c, d, e, f)
				--love.handlers[name](a,b,c,d,e,f)
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

function threaderror(thread: love.thread.Thread, errorstr: string)
    local fmt = "Something wrong in thread %s with %s"
    error(string.format(fmt , tostring(thread), errorstr))
end

--[[ Добавить что-нибудь из списка?
conf: function(t: Configuration)
directorydropped: function(path: string)
displayrotated: function(index: number, orientation: window.DisplayOrientation)
draw: function()
errorhandler: function(msg: string)
filedropped: function(file: filesystem.DroppedFile)
focus: function(focus: boolean)
gamepadaxis: function(joystick: joystick.Joystick, axis: joystick.GamepadAxis, value: number)
gamepadpressed: function(joystick: joystick.Joystick, button: joystick.GamepadButton)
gamepadreleased: function(joystick: joystick.Joystick, button: joystick.GamepadButton)
joystickadded: function(joystick: joystick.Joystick)
joystickaxis: function(joystick: joystick.Joystick, axis: number, value: number)
joystickhat: function(joystick: joystick.Joystick, hat: number, direction: joystick.JoystickHat)
joystickpressed: function(joystick: joystick.Joystick, button: number)
joystickreleased: function(joystick: joystick.Joystick, button: number)
joystickremoved: function(joystick: joystick.Joystick)
keyreleased: function(key: keyboard.KeyConstant, scancode: keyboard.Scancode)
load: function(arg: {string}, unfilteredArg: {string})
lowmemory: function()
mousefocus: function(focus: boolean)
mousemoved: function(x: number, y: number, dx: number, dy: number, istouch: boolean)
mousepressed: function(x: number, y: number, button: number, istouch: boolean, presses: number)
resize: function(w: number, h: number)
run: function(): function(): string|number
textedited: function(text: string, start: number, length: number)
textinput: function(text: string)
touchmoved: function(id: any, x: number, y: number, dx: number, dy: number, pressure: number)
touchpressed: function(id: any, x: number, y: number, dx: number, dy: number, pressure: number)
touchreleased: function(id: any, x: number, y: number, dx: number, dy: number, pressure: number)
update: function(dt: number)
visible: function(visible: boolean)
wheelmoved: function(x: number, y: number)
--]]