local colorize = require 'ansicolors2'.ansicolors
local ecodes = require "errorcodes"
local lt = love.thread

--local event_channel = lt.getChannel("event_channel")
local draw_ready_channel = lt.getChannel("draw_ready_channel")
local graphic_command_channel = lt.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

global type Pipeline = record
    new: function(): Pipeline
    -- Вход в секцию отправки
    enter: function(Pipeline, name: string)
    -- Затолкать данные в канал
    push: function(Pipeline, any)
    -- Завершение секции отправки
    leave: function(Pipeline)

    -- Отправить имя функции для рисования.
    pushName: function(Pipeline, name: string)

    -- Начать отправку данных. 
    -- Блокирующий вызов(синхронизация с потоком рисования.
    ready: function(Pipeline): boolean

    pushCode: function(Pipeline, name: string, code: string)

    in_section: boolean
end

local Pipeline_mt: metatable<Pipeline> = {
    __index = Pipeline,
}

function Pipeline.new(): Pipeline
    local self: Pipeline = setmetatable({} as Pipeline, Pipeline_mt)
    self.in_section = false
    return self
end

function Pipeline:enter(_: string)
    self.in_section = true
end

function Pipeline:leave()
    self.in_section = false
end

function Pipeline:pushName(_: string)

end

function Pipeline:push(arg: any)
    if not self.in_section then
        local msg = '%{red}Attempt to pipeline push outside section '
        print(colorize(msg))
        os.exit(ecodes.ERROR_NO_SECTION)
    end
    graphic_command_channel:push(arg)
end

function Pipeline:ready(): boolean
    local is_ready: string = draw_ready_channel:peek() as string
    if is_ready then
        if type(is_ready) ~= 'string' then
            print("Type error in is_ready flag")
            -- Переписать коды возврата в константы.
            os.exit(250)
        end
        if is_ready ~= "ready" then
            local msg = tostring(is_ready) or ""
            print("Bad message in draw_ready_channel: " .. msg)
            -- Переписать коды возврата в константы.
            os.exit(249)
        end
        draw_ready_channel:pop()
        return true
    end
    return false
end

-- Не лучше-ли передавать число?
function pushCode(name: string, code: string)
    if not name then
        error("No name for pushCode()")
    end
    if not code then
        error("No code for pushCode()")
    end

    graphic_code_channel:push(name)
    graphic_code_channel:push(code)
end
