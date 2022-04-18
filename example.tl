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

function get_foos():{integer}
   return {}
end


--local foos:{integer} = get_foos()
local foos:{integer} = get_foos()
print(foos)

--[[
local record Some
    func1: function();
    func2: function();
end
--]]

