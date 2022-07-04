local record Messenger
    record Channel
        push: function(Channel, value: any)
        pop: function(Channel): any
    end
    -- Создание нового или возврат существующего канала.
    new: function(name: string): Channel
end

return Messenger
