local record Messenger
    record Channel
        push: function(Channel, value: any)
        pop: function(Channel): any
    end
    -- Создание нового или возврат существующего канала.
    new: function(name: string): Channel
    record State end
    init: function(State): State
end

return Messenger
