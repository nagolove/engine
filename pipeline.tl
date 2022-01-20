-- vim: set colorcolumn=85
-- vim: fdm=marker

require 'common'
local colorize = require 'ansicolors2'.ansicolors
local lt = love.thread
local tl = require "tl"
local ecodes = require "errorcodes"
local format = string.format
local smatch = string.match

--local DEBUG_RENDER = true

local resume = coroutine.resume

local dprint = require 'debug_print'
--local debug_print = dprint.debug_print
-- XXX monkey patch
local debug_print = print

--local type LoadFunction = function(...:any): any...

--local event_channel = lt.getChannel("event_channel")
local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = lt.getChannel("graphic_code_channel")
local graphic_received_in_sec_channel = lt.getChannel('graphic_received_in_sec')

local enum State
    'open'
    'closed'
    'undefined'
end

--[[
Сделать объект рисования с конструктором.
Как загружать картинки?
Не удалять все объекты из очереди.
Корутины?
]]
global type Pipeline = record
    new: function(scene_prefix: string): Pipeline

    -- Вход в секцию отправки
    -- Добавить возбуждение ошибки если ready() возвращает ложь
    open: function(Pipeline, name: string)
    -- Затолкать данные в канал
    push: function(Pipeline, any)
    -- Завершение секции отправки
    close: function(Pipeline)
    openAndClose: function(Pipeline, func_name: string)

    -- Отправить имя функции для рисования.
    --pushName: function(Pipeline, name: string)

    -- Начать отправку данных. 
    -- Блокирующий вызов(синхронизация с потоком рисования.
    sync: function(Pipeline)

    --waitForReady: function(Pipeline): boolean
    waitForReady: function(Pipeline): boolean

    pushCode: function(Pipeline, name: string, code: string)
    pullRenderCode: function(Pipeline)
    render: function(Pipeline)

    printAvaibleFunctions: function(Pipeline)
    get_received_in_sec: function(Pipeline): integer

    section_state: State
    preload: string
    scene_prefix: string

    -- команда рисования и код ее корутины
    renderFunctions: {string:thread}

    -- множество существущих команд рисования
    -- добавить возможность переопределения или удаления
    render_set: {string: boolean}

    -- количество команд рисования отправленных за кадр
    counter: integer
    -- сколько команд рисования получить из канала
    cmd_num: integer

    received_bytes: integer
    received_in_sec: integer
    last_render: number
end

local Pipeline_mt: metatable<Pipeline> = {
    __index = Pipeline,
}

-- Опция не работает
--local use_stamp = true
local use_stamp = false

--[[
local function timestamp(msg: string)
    local prepared = format("%.4f : %s", love.timer.getTime(), msg)
    -- Почини debug_print()
    --debug_print("graphics", colorize('%{blue}' .. prepared))
    print(colorize('%{blue}' .. prepared))
end
--]]

function Pipeline.new(scene_prefix: string): Pipeline
    local self: Pipeline = setmetatable({} as Pipeline, Pipeline_mt)
    self.section_state = 'closed'
    self.scene_prefix = scene_prefix or ""
    self.preload = [[
    local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
    ]]
    if self.scene_prefix then
        local var = format('local SCENE_PREFIX = "%s"\n', self.scene_prefix)
        self.preload = self.preload .. var 
    end
    self.renderFunctions = {}
    self.render_set = {}
    self.counter = 0
    self.cmd_num = 0
    self.last_render = love.timer.getTime()
    self.received_bytes = 0
    self.received_in_sec = 0
    return self
end

function Pipeline:open(func_name: string)
    if self.section_state ~= 'closed' then
        local msg = '%{red}Double opened section'
        debug_print("graphics", colorize(msg))
        debug_print("graphics", colorize('%{cyan}' .. debug.traceback()))
        os.exit(ecodes.ERROR_NO_SECTION)
    end
    self.section_state = 'open'

    assert(type(func_name) == 'string')

    graphic_command_channel:push(func_name)
    self.counter = self.counter + 1
    if use_stamp then
        graphic_command_channel:push(love.timer.getTime())
    end
end

function Pipeline:close()
    self.section_state = 'closed'
end

function Pipeline:push(argument: any)
    if self.section_state ~= 'open' then
        local color_block = '%{red}'
        local msg = 'Attempt to push in pipeline with "%s" section state'
        debug_print("graphics", colorize(color_block .. format(msg, self.section_state)))
        os.exit(ecodes.ERROR_NO_SECTION)
    end
    graphic_command_channel:push(argument)
end

-- uses it other thread
-- calls at the end of the frame
function Pipeline:sync()
    local timeout = 1. -- in seconds
    --draw_ready_channel:clear()
    --draw_ready_channel:supply("ready " .. self.counter, timeout)
    draw_ready_channel:push("ready " .. self.counter)--, timeout)
    self.counter = 0
end

-- used in main(render) thread
function Pipeline:waitForReady(): boolean
    local timeout = 0.5
    local is_ready: string = draw_ready_channel:demand(timeout) as string

    if is_ready then
        --print('is_ready', is_ready)
        local ready_s, cmd_name_s: string, string

        ready_s, cmd_name_s = smatch(is_ready, "(%l+)%s(%d+)")
        self.cmd_num = math.floor(tonumber(cmd_name_s))

        if not self.cmd_num then
            error("cmd_num is nil")
        end

        return true
    else
        local msg = '%{red} draw_ready_channel:demand() is not respond'
        debug_print("graphics", colorize(msg))
        os.exit(ecodes.ERROR_NO_READY_DEMAND)
    end

    return false
end

-- Добавить проверку количества и типов аргументов функции с возможностью
-- отключения проверки для повыщения скороти вывода.
function Pipeline:pushCode(name: string, code: string)
    if self.section_state == 'open' then
        self.section_state = 'undefined'
        -- Нужно-ли здесь делать возврат из функции?
        return
    end
    
    if not name then
        error("No name for pushCode()")
    end
    if not code then
        error("No code for pushCode()")
    end

    code = self.preload .. code

    graphic_code_channel:push(code)
    graphic_code_channel:push(name)
end

--[[
Обрати внимание на мигание при рисовке.
Откуда они беруться?
--]]
function Pipeline:render()
    if self:waitForReady() then

        local custom_print = function(s: string)
            print(colorize(s))
        end

        if self.section_state ~= 'closed' then
            local color_block = '%{red}'
            local msg = 'Section not closed, but "%s"'
            custom_print(color_block .. format(msg, self.section_state))
            custom_print('%{magenta}' .. debug.traceback())
            os.exit(ecodes.ERROR_NO_SECTION)
        end

        local cmd_num = self.cmd_num

        ---------------------------------- 
        -- Не лучше-ли использовать graphic_command_channel:pop()
        -- что-бы избежать блокировки?
        --local cmd_name = graphic_command_channel:demand() as string
        local cmd_name: string
        local received_bytes: integer = 0
        ---------------------------------- 

        local stamp: number
        if use_stamp then
            stamp = graphic_command_channel:pop() as number
        end

        --timestamp('render begin')


        --repeat
        for _ = 1, cmd_num do
            cmd_name = graphic_command_channel:pop() as string

            if cmd_name then
                if type(cmd_name) ~= 'string' then
                    custom_print('%{yellow}' .. debug.traceback())
                    custom_print('%{red}Pipeline:render()')
                    custom_print('%{red}type(cmd_name) = ' .. type(cmd_name))
                    custom_print('%{green}cmd_name = ' .. cmd_name or 'nil')
                    custom_print('%{magenta}' .. debug.traceback())
                    os.exit(ecodes.ERROR_NO_COMMAND)
                end

                -- Добавить пропуск кадров.

                local coro = self.renderFunctions[cmd_name]

                --print('graphics', 'stamp, cmd_name', stamp, cmd_name)

                if coro then
                    local ok, errmsg: boolean, string

                    received_bytes = received_bytes + #cmd_name
                    ok, errmsg = resume(coro) as (boolean, string)

                    if not ok then
                        custom_print('%{yellow}' .. 'cmd_name: ' .. cmd_name)
                        custom_print('%{cyan}' .. debug.traceback())
                        custom_print('%{red}' .. errmsg)
                        os.exit(ecodes.ERROR_DIED_CORO)
                    end
                else
                    local func_name = cmd_name or "nil"
                    local msg = 'Render function "%s" not found in table.'
                    custom_print('%{red}' .. format(msg, func_name))

                    self:printAvaibleFunctions()

                    custom_print('%{cyan}' .. debug.traceback())
                    os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
                end

                if use_stamp then
                    stamp = graphic_command_channel:pop() as number
                    if type(stamp) ~= "number" then
                        error('stamp is not a number: ' .. stamp)
                    end
                end
            end
        end
        --until not cmd_name

        -- Обрати внимание, что здесь может идти накопление команд рисования
        -- в межпроцессном канале
        --if graphic_command_channel:getCount() ~= 0 then
            --error("graphic_command_channel:getCount() = " ..
                --tostring(graphic_command_channel:getCount()))
        --end

        --print('-----------------------------------------------------------------')

        local new_last_render = love.timer.getTime()
        local delay = 1 -- в секундах
        local diff = new_last_render - self.last_render 
        self.received_bytes = self.received_bytes + received_bytes
        if diff > delay then
            self.last_render = new_last_render
            self.received_in_sec = self.received_bytes
            graphic_received_in_sec_channel:clear()
            graphic_received_in_sec_channel:push(self.received_in_sec)
            self.received_bytes = 0
        end

        --timestamp('render end')
    end
end

function Pipeline:get_received_in_sec(): integer
    local bytes = graphic_received_in_sec_channel:peek()
    if bytes then
        return math.floor(tonumber(bytes))
    else
        return 0
    end
end

function Pipeline:printAvaibleFunctions()
    local color = 'magenta'
    --local color = 'cyan'
    local color_block = "%{" .. color .. "}"
    debug_print("graphics", colorize(color_block .. "--- Avaible render functions: ---"))
    for k, _ in pairs(self.renderFunctions) do
        debug_print("graphics", colorize(color_block .. k))
    end
    debug_print("graphics", colorize(color_block .. "---------------------------------"))
end

-- Стягивает из канала кода все сообщения и обновляет 
-- словарь функций рисования.
function Pipeline:pullRenderCode()
    -- {{{
    local rendercode: string
    repeat
        rendercode = graphic_code_channel:pop() as string

        if rendercode then
            local func, errmsg = tl.load(rendercode)

            if not func then
                local msg = "%{red}Something wrong in render code: %{cyan}" 
                local code = colorize('%{green}' .. '\n' .. linum(rendercode))
                debug_print("graphics", 'rendercode', code)
                debug_print("graphics", colorize(msg .. errmsg))
                os.exit(ecodes.ERROR_INTERNAL_LOAD)
            else
                local name = graphic_code_channel:pop() as string
                if not name then
                    error('No name for drawing function.')
                end

                -- Нужно-ли добавлять все функции подряд в таблицу?
                local coro = coroutine.create(func)
                self.renderFunctions[name] = coro

                name = colorize('%{yellow}' .. name)
                debug_print("graphics", 'name, func, errmsg', name, func, errmsg)
                --debug_print("graphics", 'rendercode', colorize('%{green}' .. '\n' .. rendercode))
            end

        end
    until not rendercode
    -- }}}
end


function Pipeline:openAndClose(func_name: string)
    self:open(func_name)
    self:close()
end
