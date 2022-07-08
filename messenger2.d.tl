local record Messenger
    MAX_STR_LEN: integer
    QUEUE_SIZE: integer
    MAX_NAME_LEN: integer
    MAX_CHANNELS_NUM: integer

    record Channel end

    push: function(Channel, value: any)
    pop: function(Channel): any

    -- Создание нового или поиск и возврат существующего канала по имени.
    new: function(name: string): Channel
    free: function(ch: Channel)

    record State end

    -- Инициализация общего состояния для всех копий библиотеки
    -- (для всех потоков).
    init_messenger: function(State): State
    free_messenger: function()

    channel_print_strings: function(Channel)
    channel_print_numbers: function(Channel)
end

return Messenger
