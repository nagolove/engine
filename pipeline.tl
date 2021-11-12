local colorize = require 'ansicolors2'.ansicolors
local lt = love.thread
local tl = require "tl"
local ecodes = require "errorcodes"
local format = string.format

local DEBUG_RENDER = true

local type LoadFunction = function(...:any): any...

--local event_channel = lt.getChannel("event_channel")
local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local enum State
    'open'
    'closed'
    'undefined'
end

global type Pipeline = record
    new: function(): Pipeline

    -- Вход в секцию отправки
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
    ready: function(Pipeline): boolean

    pushCode: function(Pipeline, name: string, code: string)
    pullRenderCode: function(Pipeline)
    render: function(Pipeline)

    printAvaibleFunctions: function(Pipeline)

    --in_section: boolean
    section_state: State
    renderFunctions: {string:LoadFunction}
    last_section_name: string
end

local Pipeline_mt: metatable<Pipeline> = {
    __index = Pipeline,
}

function Pipeline.new(): Pipeline
    local self: Pipeline = setmetatable({} as Pipeline, Pipeline_mt)
    self.section_state = 'closed'
    self.renderFunctions = {}
    return self
end

function Pipeline:open(func_name: string)
    print('self.section_state', self.section_state)
    if self.section_state ~= 'closed' then
        local msg = '%{red}Double opened section'
        print(colorize(msg))
        print(colorize('%{cyan}' .. debug.traceback()))
        os.exit(ecodes.ERROR_NO_SECTION)
    end
    self.section_state = 'open'

    assert(type(func_name) == 'string')
    if DEBUG_RENDER then
        print('func_name', func_name)
    end
    graphic_command_channel:push(func_name)
end

function Pipeline:close()
    self.section_state = 'closed'
end

function Pipeline:pushName(_: string)
    --self.section_state = 'undefined'
end

function Pipeline:push(arg: any)
    if self.section_state ~= 'open' then
        local color_block = '%{red}'
        local msg = 'Attempt to push in pipeline with "%s" section state'
        print(colorize(color_block .. format(msg, self.section_state)))
        os.exit(ecodes.ERROR_NO_SECTION)
    end
    graphic_command_channel:push(arg)
end

function Pipeline:ready(): boolean
    local is_ready: string = draw_ready_channel:peek() as string
    if is_ready then
        if type(is_ready) ~= 'string' then
            print("Type error in is_ready flag")
            os.exit(ecodes.ERROR_IS_READY_TYPE)
        end
        if is_ready ~= "ready" then
            local msg = tostring(is_ready) or ""
            print("Bad message in draw_ready_channel: " .. msg)
            os.exit(ecodes.ERROR_NO_READY)
        end
        draw_ready_channel:pop()
        return true
    end
    return false
end

-- Не лучше-ли передавать число в качестве идентификатора объекта рисовки?
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

    local preload = [[
    local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
    ]]
    code = preload .. code

    graphic_code_channel:push(code)
    graphic_code_channel:push(name)
end

function Pipeline:render()

    if self.section_state ~= 'closed' then
        local color_block = '%{red}'
        local msg = 'Section not closed, but "%s"'
        print(colorize(color_block .. format(msg, self.section_state)))
        print(colorize('%{magenta}' .. debug.traceback()))
        os.exit(ecodes.ERROR_NO_SECTION)
    end

    print('graphic_command_channel:getCount() before',
        graphic_command_channel:getCount())

    ---------------------------------- 
    -- Не лучше-ли использовать graphic_command_channel:pop()
    -- что-бы избежать блокировки?
    local cmd_name = graphic_command_channel:demand() as string
    ---------------------------------- 

    print('graphic_command_channel:getCount() after',
        graphic_command_channel:getCount())

    print('cmd_name', cmd_name)

    if type(cmd_name) ~= 'string' then
        print(colorize('%{yellow}' .. debug.traceback()))
        print(colorize('%{red}Pipeline:render()'))
        print(colorize('%{red}type(cmd_name) = ' .. type(cmd_name)))
        print(colorize('%{green}cmd_name = ' .. cmd_name))
        print(colorize('%{magenta}' .. debug.traceback()))
        os.exit(ecodes.ERROR_NO_COMMAND)
    end

    -- Добавить пропуск кадров.
    -- Выкидывать старые функции если слишком произошда слишком большая
    -- задержка.

    local f = self.renderFunctions[cmd_name]
    if f then
        f()

        print('graphic_command_channel:getCount() after f()',
            graphic_command_channel:getCount())
    else
        local func_name = cmd_name or "nil"
        local msg = 'Render function "%s" not found in table.'
        print(colorize('%{red}' .. format(msg, func_name)))

        if DEBUG_RENDER then
            self:printAvaibleFunctions()
        end
    
        print(colorize('%{cyan}' .. debug.traceback()))
        os.exit(ecodes.ERROR_NO_RENDER_FUNCTION)
    end
end

function Pipeline:printAvaibleFunctions()
    local color = 'magenta'
    --local color = 'cyan'
    local color_block = "%{" .. color .. "}"
    print(colorize(color_block .. "--- Avaible render functions: ---"))
    for k, _ in pairs(self.renderFunctions) do
        print(colorize(color_block .. k))
    end
    print(colorize(color_block .. "---------------------------------"))
end

-- Стягивает из канала кода все сообщения и обновляет 
-- словарь функций рисования.
function Pipeline:pullRenderCode()
    local rendercode: string

    repeat
        --print('pullRenderCode iteration')
        rendercode = graphic_code_channel:pop() as string

        if rendercode then
            local func, errmsg = tl.load(rendercode)

            print('func, errmsg', func, errmsg)
            print('rendercode', colorize('%{green}' .. rendercode))

            if not func then
                --error("%{red}Something wrong in render code: %{cyan}" .. errmsg)
                local msg = "%{red}Something wrong in render code: %{cyan}" 
                print(colorize(msg .. errmsg))
                os.exit(ecodes.ERROR_INTERNAL_LOAD)
            else
                local name = graphic_code_channel:pop() as string
                if not name then
                    error('No name for drawing function.')
                end

                -- Нужно-ли добавлять все функции подряд в таблицу?
                self.renderFunctions[name] = func
            end
        end
    until not rendercode

    --print('return form pullRenderCode()')
end


function Pipeline:openAndClose(func_name: string)
    self:open(func_name)
    self:close()
end
