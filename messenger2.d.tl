local record Messenger
    --[[
    record Channel
        push: function(Channel, value: any)
        pop: function(Channel): any
    end
    -- Создание нового или возврат существующего канала.
    new: function(name: string): Channel
    record State end
    init: function(State): State
    --]]
    record Channel end
    push: function(Channel, value: any)
    pop: function(Channel): any

    -- Создание нового или поиск и возврат существующего канала по имени.
    new: function(name: string): Channel
    free: function(ch: Channel)

    record State end
    -- Инициализация общего состояния для всех копий библиотеки
    -- (для всех потоков).
    init: function(State): State
    --]]
end

return Messenger
