local record Messenger
    record Channel
        push: function(Channel, value: any)
        pop: function(Channel): any
    end
    new: function(): Channel
end

return Messenger
