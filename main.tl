require "jitoptions".on()
require "love"
require "common"
require "log"
require "keyconfig"
require 'imgui'
require 'pipeline'

if love.system.getOS() == 'Windows' then
    love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
end
print("package.path", package.path)

local IMGUI_USE_STUB = false

local inspect = require "inspect"
local scenes = require "scenes"

local showHelp = false
local imguiFontSize = 22

local lt = love.thread
local threads: {string: lt.Thread} = {}

local event_channel = lt.getChannel("event_channel")
local draw_ready_channel = lt.getChannel("draw_ready_channel")
--local graphic_command_channel = lt.getChannel("graphic_command_channel")
--local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

--love.filesystem.write("syslog.txt", "identity = " .. love.filesystem.getIdentity())

local Shortcut = KeyConfig.Shortcut
local colorize = require 'ansicolors2'.ansicolors
local ecodes = require "errorcodes"
local format = string.format
local pipeline = Pipeline.new()

function threaderror(thread: love.thread.Thread, errorstr: string)
    print('threaderror')
    local fmt = "Something wrong in thread %s with %s"
    print(format(fmt , tostring(thread), errorstr))
    os.exit(ecodes.ERROR_THREAD)
end

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

local function newThread(name: string): love.thread.Thread
    local path = "scenes/" .. name .. "/init.lua"
    --print(string.format("initOneMulti '%s'", path))
    print(colorize('%{yellow}' .. format('newThread("%s")', path)))
    local thread = love.thread.newThread(path)
    if not thread then
        error('No thread created.')
    end
    --table.insert(threads, thread)
    threads[path] = thread
    return thread
end

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

    print("love.load() arg", inspect(arg))

    local sceneName = findCommand(arg)

    --TODO : добавить загрузку произвольной сцены по пути.
    -- К примеру `./run ./some/local/path/to/directory/with/init.tl`
    -- Где `init.tl` представляет собой основной модуль сцены, 
    -- экспортирующий соответствующий интерфейс.
    -- Вопрос: какой интерфейс? Выделить `Module`
    print("sceneName", sceneName)
    --[[
    if sceneName then
        --scenes.initOne(sceneName)
    else
        colprint("Empty scene will be runned.")
        --scenes.initOne("empty")
    end
    --]]

    local thread = newThread(sceneName)
    thread:start()

    --local timeout = 0.1
    --pullRenderCode(timeout)

    -- Подождать загрузки остальных потоков
    local waitfor = 0.1
    love.timer.sleep(waitfor)

    pipeline:pullRenderCode()

    print('threads', colorize('%{magenta}' .. inspect(threads)))

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
    --print 'love.update'
    local now = love.timer.getTime()
    if now - lastWindowHeaderUpdateTime > quant then
        love.window.setTitle(titlePrefix .. love.timer.getFPS())
    end

    if showHelp then
        KeyConfig.updateList(dt)
    end
    KeyConfig.update()
    collectGarbage()

    --scenes.update(dt)
end

function love.resize(_: integer, _: integer)
    --scenes.resize(w, h)
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
    local tmp = require 'parse_args'
    if love.load then love.load(tmp.parseGameArguments(arg)) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0.
    local time = love.timer.getTime()

	-- Main loop time.
	return function(): string|number

		-- Process events.
		if love.event then
			love.event.pump()
            local events = {}
			for name, a,b,c,d,e,f in love.event.poll() do
                --print('n, a, b, c, d, e, f', n, a, b, c, d, e, f)
				if name == "quit" then
					if not love.quit or not love.quit() then
						--return a or 0
                        -- XXX нет проверки возвращаемого значения
						return (a or 0) as string
					end
				end
                table.insert(events, {name, a, b, c, d, e, f})
                --tmp.callHandler(name, a, b, c, d, e, f)
				--love.handlers[name](a,b,c,d,e,f)
			end
            event_channel:push(events)
		end

        local nt = love.timer.getTime()
        dt = nt - time
        time = nt                

        -- Возможно стоит запускать реже, по таймеру?
        --for _, t in ipairs(threads) do
        for _, t in pairs(threads) do
            local errmsg = t:getError()
            if errmsg then
                errmsg = colorize("%{cyan}" .. errmsg .. "%{reset}")
                print(colorize('%{red}Error in thread'), errmsg)
                os.exit(ecodes.ERROR_THREAD)
            end
        end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        pipeline:pullRenderCode()

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
            --love.graphics.clear(love.graphics.getBackgroundColor())
            --love.graphics.clear()

            pipeline:waitForReady()
            pipeline:render()

			love.graphics.present()
		end

        -- Подобрать константы задержки для игрового потока и основного потока.
        local sleep_time = 0.001
		if love.timer then 
            love.timer.sleep(sleep_time) 
        end

	end
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
