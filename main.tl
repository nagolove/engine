-- vim: set colorcolumn=85
-- vim: fdm=marker

require "jitoptions".on()

require "love"
require "common"
require "log"
require 'pipeline'
require "keyconfig"

--local verts_batch = require 'verts_batch'
--verts_batch.init()

local IMGUI_USE_STUB = false
local im_ok, im_errmsg = pcall(function()
    require 'imgui'
end) as boolean, string
if not im_ok then
    print("Could not load imgui.dll", im_errmsg)
    IMGUI_USE_STUB = true
end

if love.system.getOS() == 'Windows' then
    --love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
end
print("package.path", package.path)

local inspect = require "inspect"
local scenes = require "scenes"

local showHelp = false
local imguiFontSize = 22

local lt = love.thread
local threads: {string: lt.Thread} = {}

-- Канал для получения различных команд основным потоком от игровых потоков.
local main_channel = love.thread.getChannel("main_channel")
local event_channel = lt.getChannel("event_channel")

local Shortcut = KeyConfig.Shortcut
local colorize = require 'ansicolors2'.ansicolors
local ecodes = require "errorcodes"
local format = string.format
local pipeline = Pipeline.new()

local dprint = require 'debug_print'
--local debug_print = dprint.debug_print

dprint.set_filter({
    [1] = {'graphics'},
})

function love.threaderror(thread: love.thread.Thread, errorstr: string)
    print(colorize('${greeb}threaderror'))
    local fmt = "Something wrong in thread %s with %s"
    print(colorize("${red}" .. format(fmt , tostring(thread), errorstr)))
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
end

function printGraphicsInfo()
    local custom_print = print
    local name, version, vendor, device = love.graphics.getRendererInfo( )
    custom_print("graphics",name, version, vendor, device)
    local stats = love.graphics.getStats( )
    custom_print("graphics","stats", inspect(stats))
    local features = love.graphics.getSupported( )
    custom_print("graphics","features", inspect(features))
    local limits = love.graphics.getSystemLimits( )
    custom_print("graphics","limits", inspect(limits))
    local texturetypes = love.graphics.getTextureTypes( )
    custom_print("graphics","texturetypes", inspect(texturetypes))
    --local pointsize = love.graphics.getMaxPointSize( )
    --print("graphics","pointsize", inspect(features))
    local imageformats = love.graphics.getImageFormats( ) 
    custom_print("graphics","imageformats", inspect(imageformats))
    local canvasformats = love.graphics.getCanvasFormats( )
    custom_print("graphics","canvasformats", inspect(canvasformats))
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

    if #commands > 1 then
        colprint('More then one command, sorry.')
        return nil
    end

    return commands[1]
end

local function newThread(name: string): love.thread.Thread
    local path = "scenes/" .. name .. "/init.lua"
    print(colorize('%{yellow}' .. format('newThread("%s")', path)))
    local thread = love.thread.newThread(path)
    if not thread then
        error('No thread created.')
    end
    threads[path] = thread
    return thread
end

function love.load(arg: {string})
    if not IMGUI_USE_STUB then
        imgui.Init()
        imgui.SetGlobalFontFromArchiveTTF("fonts/DroidSansMono.ttf", imguiFontSize)
    end

    --printGraphicsInfo()
    bindKeys()

    if searchArg(arg, '--debug') or searchArg(arg, '--silent') then
        require "mobdebug".start()
        print(colorize("%{red}mobdebug started"))
    end

    print("love.load(arg)", inspect(arg))

    local sceneName = findCommand(arg)

    print("sceneName", sceneName)

    local thread = newThread(sceneName)
    thread:start()

    -- Подождать загрузки остальных потоков
    local waitfor = 0.1
    love.timer.sleep(waitfor)

    pipeline:pullRenderCode()

    print('threads', colorize('%{magenta}' .. inspect(threads)))
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

function pullMainChannel()
    local cmd = main_channel:pop() as string
    if cmd and type(cmd) == 'string' then
        if cmd == 'quit' then
            print(colorize('%{cyan}quit event'))
            love.event.quit()
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

	return function(): string|number

		if love.event then
			love.event.pump()
            local events = {}
			for name, p1, p2, p3, p4, p5, p6 in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						--return a or 0
                        -- XXX нет проверки возвращаемого значения
						return (p1 or 0) as string
					end
				end
                table.insert(events, {name, p1, p2, p3, p4, p5, p6})
			end
            event_channel:push(events)
		end

        local nt = love.timer.getTime()
        dt = nt - time
        time = nt                

        -- Возможно стоит запускать реже, по таймеру?
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
        pullMainChannel()

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
            --love.graphics.clear(love.graphics.getBackgroundColor())

            love.graphics.clear()

            pipeline:render()

            --[[
            if love.keyboard.isDown('q') then
                verts_batch.render_mesh()
            elseif love.keyboard.isDown('w') then
                verts_batch.render_poly()
            end
            --]]

			love.graphics.present()
		end

        -- Подобрать константы задержки для игрового потока и основного потока.
        --local sleep_time = 0.01
        local sleep_time = 0.001
		if love.timer then 
            love.timer.sleep(sleep_time) 
        end

	end
end

--[[ Добавить что-нибудь из списка?
-- {{{
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
-- }}}}
--]]
