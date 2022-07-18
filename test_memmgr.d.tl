local record test_memmgr
    record Channel end
    record ID end

    -- Создание нового или поиск и возврат существующего канала по имени.
    new: function(name: string): Channel
    free: function(ch: Channel)

    record State end

    -- Инициализация общего состояния для всех копий библиотеки
    -- (для всех потоков).
    init_messenger: function(State): State
    free_messenger: function()

    string_from_state: function(State): string
    state_from_string: function(string): State
end

return test_memmgr
