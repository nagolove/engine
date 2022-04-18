-- vim: fdm=marker
-- vim: set colorcolumn=85

--local record Vector1
    --x: number
--end

--local record Vector2
    ----embed Vector1
    --y: number
--end

--[[
local type Pipeline = record
    new: function(): Pipeline
    -- Вход в секцию отправки
    enter: function(Pipeline)
    -- Затолкать данные в канал
    push: function(Pipeline, any)
    -- Завершение секции отправки
    leave: function(Pipeline)
end
--]]

-- Не ловится ошибка, что отсутствует реализация Pipeline.new()
-- Компиляция успешная, падение происходит во время выполнения.
--local pipeline = Pipeline.new()

--[[
function get_foos<T>():{T}
   return {}
end
--]]

--[[
function get_foos():{integer}
   return {}
end


--local foos:{integer} = get_foos()
local foos:{integer} = get_foos()
print(foos)
--]]

--[[
local record Some
    func1: function();
    func2: function();
end
--]]

------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- Идеи по лучшему сообщению об ошибке такого рода.

local enum Command
    "circle"
    "line"
    "rect"
end

local commands = {}

function commands.circle(_: number)
end

function commands.line(_: number)
end

function commands.rect(_: integer)
end

local cmd: Command = 'circle'
commands[cmd]()

--1 error:
--example.tl:71:10: cannot index, not all enum values map to record fields of the same type

------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------

