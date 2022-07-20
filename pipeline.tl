-- vim: set colorcolumn=85
-- vim: fdm=marker

require 'common'
local colorize = require 'ansicolors2'.ansicolors
local lt = love.thread
local tl = require "tl"
local ecodes = require "errorcodes"
local format = string.format
local smatch = string.match
local inspect = require 'inspect'
local resume = coroutine.resume
local floor = math.floor

--local dprint = require 'debug_print'
--local debug_print = dprint.debug_print
-- XXX monkey patch
local debug_print = print

-- для синхронизации
local draw_ready_channel = lt.getChannel("draw_ready_channel")
-- для команд и данных команд
--local command_channel = lt.getChannel("graphic_command_channel")
-- для кода процедур рисования
local code_channel = lt.getChannel("graphic_code_channel")
-- для статистики переданных данных
local graphic_received_in_sec_channel = lt.getChannel('graphic_received_in_sec')
-- для запросов к рендеру
local graphic_query_channel = lt.getChannel('graphic_query_channel')
-- для ответов на запросы рендера
local graphic_query_res_channel = lt.getChannel('graphic_query_res_channel')

local enum State
    'open'
    'closed'
    'undefined'
end

-- Сколько секунд писать в консоль содержимое стека после падения.
local reading_timeout = 0.05

--[[
Не удалять все объекты из очереди?

Какие инструменты отладки можно предложить?
]]
local type Pipeline = record
    -- Флаг игнорирования ошибок. Попытка работать с игнорированием.
    forced: boolean 

    new: function(scene_prefix: string): Pipeline

    -- Вход в секцию отправки
    -- Добавить возбуждение ошибки если ready() возвращает ложь
    open: function(Pipeline, name: string)
    -- Затолкать данные в канал
    push: function(Pipeline, ...:any)
    -- Завершение секции отправки
    close: function(Pipeline)

    -- отправить команду без параметров
    openAndClose: function(Pipeline, func_name: string)

    -- отправить команду с параметрами
    openPushAndClose: function(Pipeline, func_name: string, ...:any)

    -- Отправить имя функции для рисования.
    --pushName: function(Pipeline, name: string)

    -- Начать отправку данных. 
    -- Блокирующий вызов(синхронизация с потоком рисования.
    sync: function(Pipeline)

    waitForReady: function(Pipeline): boolean

    pushCode: function(Pipeline, name: string, code: string)
    pushCodeFromFile: function(Pipeline, name: string, fname: string)
    -- загрузить код без префикс-каталога сцены
    pushCodeFromFileRoot: function(name: string, fname: string)
    pullRenderCode: function(Pipeline)
    render: function(Pipeline)

    printAvaibleFunctions: function(Pipeline)
    -- возвращает количество байт переданных за секунду через канал команд
    get_received_in_sec: function(Pipeline): integer

    getDimensions: function(Pipeline): integer, integer

    ------------------------------------ PRIVATE PRIVATE PRIVATE ...

    -- Каналы с командами
    cmd_channels: {lt.Channel}
    -- Номер активного канала с командами
    cmd_channel_idx: integer
    -- Количество каналов команд
    cmd_channel_idx_max: integer
    -- Ссылка на активный канал команд
    command_channel: lt.Channel

    -- служебная
    render_internal: function(Pipeline)

    section_state: State
    preload: string
    scene_prefix: string

    -- команда рисования и код ее корутины
    renderFunctions: {string:thread}

    -- количество команд рисования отправленных за кадр
    counter: integer
    -- сколько команд рисования получить из канала
    cmd_num: integer

    current_func: string

    inc_linum: integer

    received_bytes: integer
    received_in_sec: integer
    last_render: number

    graphic_info_channel: love.thread.Channel
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

--require love.graphics

function Pipeline.new(scene_prefix: string): Pipeline
    local self: Pipeline = setmetatable({} as Pipeline, Pipeline_mt)
    self.section_state = 'closed'
    self.scene_prefix = scene_prefix or ""

    self.cmd_channel_idx = 1
    self.cmd_channel_idx_max = 3
    self.cmd_channels = {}
    for i = 1, self.cmd_channel_idx_max do
        local ch = lt.getChannel("graphic_command_channel" .. tostring(i))
        table.insert(self.cmd_channels, ch)
    end
    self.command_channel = self.cmd_channels[self.cmd_channel_idx]
    print('self.command_channel', self.command_channel)

    self.preload = [[
    local _args = {...}
    local _channel_index: integer = _args[1] as integer
    assert(type(_channel_index) == "number")
    local lt = love.thread
    local _cmd_channel_max = _MAX_CHANNELS_SUBSTITUTION_
    local _channels: {lt.Channel} = {}

    for i = 1, _cmd_channel_max do
        local ch = lt.getChannel("graphic_command_channel" .. tostring(i))
        table.insert(_channels, ch)
    end

    local graphic_command_channel: lt.Channel = _channels[_channel_index]

    local default_yield = coroutine.yield
    coroutine.yield = function()
        error("Please use yield_ch() instead of coroutine.yield()")
    end

    local function yield_ch(): lt.Channel
        _channel_index = default_yield() as integer
        assert(type(_channel_index) == 'number')
        graphic_command_channel = _channels[_channel_index]
    end

    --local graphic_command_channel = lt.getChannel(
        --"graphic_command_channel" .. _channel_index
    --)

    --local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
    ]]
    self.preload = string.gsub(
        self.preload, 
        "_MAX_CHANNELS_SUBSTITUTION_", 
        tostring(self.cmd_channel_idx_max)
    )

    if self.scene_prefix then
        local var = format('local SCENE_PREFIX = "%s"\n', self.scene_prefix)
        self.preload = self.preload .. var 
    end

    -- две строчки добавляются к нумерации
    self.inc_linum = 2

    self.renderFunctions = {}
    self.counter = 0
    self.cmd_num = 0
    self.last_render = love.timer.getTime()
    self.received_bytes = 0
    self.received_in_sec = 0
    self.current_func = ''
    self.forced = false

    -- Для Pipeline:getDimensions()
    if love.graphics then
        self.graphic_info_channel = love.thread.getChannel("graphic_info_channel")
        self.graphic_info_channel:push({love.graphics.getDimensions()})
    end

    --local func, errmsg = load([[
    --local inspect = require 'inspect'
    --print('love', inspect(love))
    --require love
    --local gr = require love.graphics

    --local graphic_info_channel = love.thread.getChannel("graphic_info_channel")
    --graphic_info_channel:push({gr.getDimensions()})
    --love.thread.getChannel("graphic_info_channel"):push({love.graphics.getDimensions()})
    --]]) as (function, string)
    --print('errmsg', errmsg)
    --func()
    --]]

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

    -- Кромени имени функции добавить номер канала
    self.command_channel:push(func_name)

    self.current_func = func_name
    self.counter = self.counter + 1
    if use_stamp then
        error("This option was disabled by developer.")
        --command_channel:push(love.timer.getTime())
    end
end

function Pipeline:close()
    self.section_state = 'closed'
end

-- Добавить проверку количества и типов параметров в отладочном режиме.
function Pipeline:push(...: any)
    if self.section_state ~= 'open' then
        local color_block = '%{red}'
        local msg = 'Attempt to push in pipeline with "%s" section state'
        local fmt_msg = format(msg, self.section_state)
        local col_msg = colorize(color_block .. fmt_msg)
        --local col_msg = colorize(color_block .. format(msg, self.section_state))
        debug_print("graphics", col_msg)

        color_block = '%{blue}'
        msg = 'Current function name is "%s"'
        fmt_msg = format(msg, self.current_func)
        col_msg = colorize(color_block .. fmt_msg)
        debug_print("graphics", col_msg)

        os.exit(ecodes.ERROR_NO_SECTION)
    end
    
    for i = 1, select('#', ...) do
        local argument = select(i, ...)
        self.counter = self.counter + 1
        self.command_channel:push(argument)
    end
end

-- uses it other thread
-- calls at the end of the frame
function Pipeline:sync()
    --local timeout = 1. -- in seconds
    --draw_ready_channel:clear()
    --draw_ready_channel:supply("ready " .. self.counter)

    --draw_ready_channel:supply(self.counter, self.cmd_channel_idx)
    draw_ready_channel:push(self.counter)
    draw_ready_channel:supply(self.cmd_channel_idx)

    -- XXX Добавить здесь проверку на доступность предыдущего канала?
    self.cmd_channel_idx = 
        (self.cmd_channel_idx + 1) % self.cmd_channel_idx_max + 1

    --draw_ready_channel:push(self.counter)

    --draw_ready_channel:push("ready " .. self.counter)--, timeout)
    self.counter = 0
end

function Pipeline:waitForReady(): boolean
    local timeout = 0.5
    local cmd_num: integer = draw_ready_channel:demand(timeout) as integer
    local channel_idx: integer = draw_ready_channel:demand(timeout) as integer

    if cmd_num then
        --[[
        if type(is_ready) ~= "number" then

            local msg = 
                '%{red} draw_ready_channel:demand() got "' .. 
                type(is_ready) .. 
                '"'

            debug_print("graphics", colorize(msg))
            os.exit(ecodes.ERROR_BAD_TYPE)
        end
        --]]
        assert(type(cmd_num) == "number")
        assert(type(channel_idx) == "number")

        --print('is_ready', is_ready)
        --local ready_s, cmd_name_s: string, string

        --ready_s, cmd_name_s = smatch(is_ready, "(%l+)%s(%d+)")
        --print('ready_s', ready_s)
        self.cmd_num = floor(cmd_num)
        self.cmd_channel_idx = floor(channel_idx)
        self.command_channel = self.cmd_channels[self.cmd_channel_idx]

        if not self.cmd_num then
            error("cmd_num is nil")
        end

        return true
    else
        local msg = '%{red} draw_ready_channel:demand() is not respond'
        debug_print("graphics", colorize(msg))
        --os.exit(ecodes.ERROR_NO_READY_DEMAND)
        --return 'timeout'
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

    code_channel:push(code)
    code_channel:push(name)
end

function Pipeline:pushCodeFromFileRoot(name: string, fname: string)
    local content = love.filesystem.read(fname)
    if not content then
        error('Could not load: ' .. fname)
    else
        print(name, 'loaded from', fname)
    end
    self:pushCode(name, content)
end

function Pipeline:pushCodeFromFile(name: string, fname: string)
    local path = self.scene_prefix .. '/' .. fname
    local content = love.filesystem.read(path)
    if not content then
        error('Could not load: ' .. path)
    else
        print(name, 'loaded from', path)
    end
    self:pushCode(name, content)
end

-- обработка разных запросов(ширина и высота вывода) к рендеру и выдача ответов
-- XXX Где лучше разместить этот цикл обработки?
local function process_queries()
    local query: string
    repeat
        query = graphic_query_channel:pop() as string
        if query then
            if query == 'getDimensions' then
                local w, h = love.graphics.getDimensions()
                graphic_query_res_channel:push(w)
                graphic_query_res_channel:push(h)
            else
                error('Unkown query in process_queries()')
            end
        end
    until not query
end

--[[
local function print_commands_stack()
    local value: any
    local time_start = love.timer.getTime()
    print('command stack:')
    repeat
        value = command_channel:pop()
        if value then
            print(colorize("%{yellow}" .. inspect(value)))
        end
        local now = love.timer.getTime()
        if now - time_start >= reading_timeout then
            local timeout = reading_timeout
            local msg = "%{red} stack reading timeout " .. timeout .. ' sec.'
            print(colorize(msg))
            break
        end
    until not value
end
--]]

function Pipeline:render_internal()
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
    local cmd_name: string
    local received_bytes: integer = 0

    local stamp: number
    if use_stamp then
        error("This option was disabled by developer.")
        --stamp = command_channel:pop() as number
    end

    for _ = 1, cmd_num do
        --print("self.cmd_channel_idx", self.cmd_channel_idx)
        cmd_name = self.command_channel:pop() as string

        --assert(cmd_name == "string", type(cmd_name) .. " " .. cmd_name)
        assert(cmd_name ~= "string")

        if cmd_name then
            if type(cmd_name) ~= 'string' then
                custom_print('%{yellow}' .. debug.traceback())
                custom_print('%{red}Pipeline:render()')
                custom_print('%{red}type(cmd_name) = ' .. type(cmd_name))

                if type(cmd_name) == 'table' then
                    local msg = inspect(cmd_name)
                    custom_print('%{green}cmd_name = ' .. msg or 'nil')
                else
                    custom_print('%{green}cmd_name = ' .. cmd_name or 'nil')
                end

                custom_print('%{magenta}' .. debug.traceback())
                os.exit(ecodes.ERROR_NO_COMMAND)
            end

            -- Добавить пропуск кадров.

            local coro = self.renderFunctions[cmd_name]

            --print('graphics', 'stamp, cmd_name', stamp, cmd_name)

            if coro then
                local ok, errmsg: boolean, string

                received_bytes = received_bytes + #cmd_name
                ok, errmsg = resume(coro, self.cmd_channel_idx) as (boolean, string)

                if not self.forced and not ok then
                    custom_print('%{blue} resume render coroutine error.')
                    custom_print('%{yellow}' .. 'cmd_name: ' .. cmd_name)
                    custom_print('%{cyan}' .. debug.traceback())
                    custom_print('%{red}' .. errmsg)
                    os.exit(ecodes.ERROR_DIED_CORO)
                end
            else
                local func_name = cmd_name or "nil"
                local msg = 'Render function "%s" not found in table.'
                custom_print('%{red}' .. format(msg, func_name))

                msg = 'Current func = "%s"'
                custom_print('%{blue}' .. format(msg, self.current_func))

                msg = 'Command number = %d'
                custom_print('%{blue}' .. format(msg, self.cmd_num))

                self:printAvaibleFunctions()

                --print_commands_stack()
                print(colorize("%{yellow} Sorry, callstack is not avaible yet."))

                custom_print('%{cyan}' .. debug.traceback())
                os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
            end

            if use_stamp then
                error("This option was disabled by developer.")
                --stamp = command_channel:pop() as number
                --if type(stamp) ~= "number" then
                    --error('stamp is not a number: ' .. stamp)
                --end
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

--[[
Обрати внимание на мигание при рисовке.
Откуда они беруться?
--]]
function Pipeline:render()
    if self:waitForReady() then
        if self.forced then
            pcall(function()
                self:render_internal()
            end)
        else
            self:render_internal()
        end
    end
    process_queries()
end

function Pipeline:getDimensions(): integer, integer
    graphic_query_channel:supply("getDimensions")
    local x: integer = floor(graphic_query_res_channel:demand() as number)
    local y: integer = floor(graphic_query_res_channel:demand() as number)
    --local x: integer = floor(graphic_query_res_channel:pop() as number)
    --local y: integer = floor(graphic_query_res_channel:pop() as number)
    --[[
    local dims = self.graphic_info_channel:peek() as {integer}
    return dims[1], dims[2]
    --]]
    return x, y
end

function Pipeline:get_received_in_sec(): integer
    local bytes = graphic_received_in_sec_channel:peek()
    if bytes then
        return floor(tonumber(bytes))
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
        local name: string
        rendercode = code_channel:pop() as string

        if rendercode then
            name = code_channel:pop() as string
            if not name then
                error('No name for drawing function.')
            end
            local func, errmsg = tl.load(rendercode, name)
            -- XXX Проверка типов при использовании модуля love
            --local func, errmsg = tl.load(rendercode, name, 'ct')
            
            if not func then
                local msg = "%{red}Something wrong in render code: %{cyan}" 
                local numerated = linum(rendercode, self.inc_linum)
                local code = colorize('%{green}' .. '\n' .. numerated)
                debug_print("graphics", 'rendercode', code)
                debug_print("graphics", colorize(msg .. errmsg))
                os.exit(ecodes.ERROR_INTERNAL_LOAD)
            else
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

function Pipeline:openPushAndClose(func_name: string, ...:any)
    self:open(func_name)
    self:push(...)

    --for i = 1, select('#', ...) do
        --local argument = select(i, ...)
        --self.counter = self.counter + 1
        --graphic_command_channel:push(argument)
    --end

    self:close()
end

function Pipeline:openAndClose(func_name: string)
    self:open(func_name)
    self:close()
end

return Pipeline
