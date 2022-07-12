local record Messenger
    MAX_STR_LEN: integer
    QUEUE_SIZE: integer
    MAX_NAME_LEN: integer
    MAX_CHANNELS_NUM: integer

    record Channel end
    record ID end

    -- Положить 
    push: function(Channel, value: any): ID
    -- Положить и ждать пока не будет снято
    supply: function(Channel, value: any)
    -- Снять
    pop: function(Channel): any
    -- Заглянуть
    peek: function(Channel): any
    -- Снять или ждать пока не появится
    demand: function(Channel, timeout: number): any
    -- Очистить
    clear: function(Channel)
    -- Было-ли считано
    has_read: function(Channel, id: ID): boolean
    get_count: function(Channel): integer

    -- Создание нового или поиск и возврат существующего канала по имени.
    new: function(name: string): Channel
    free: function(ch: Channel)

    record State end

    -- Инициализация общего состояния для всех копий библиотеки
    -- (для всех потоков).
    init_messenger: function(State): State
    free_messenger: function()

    print_strings: function(Channel)
    print_numbers: function(Channel)
    print: function(Channel)
end

return Messenger
