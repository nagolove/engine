local record Messenger
    record Object end
    type AddrString = string
    init: function(): Object, AddrString
    deinit: function(obj: Object)

    connect: function(addr_string: AddrString): boolean
    pop: function(): any
    push: function(value: any)
end

return Messenger
