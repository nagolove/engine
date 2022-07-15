local Msg = require "messenger2"

local type ChannelProxy = record
    ch: Msg.Channel

    new: function(name: string): ChannelProxy

    clear: function(self: ChannelProxy)
    demand: function(self: ChannelProxy, timeout: number): any
    getCount: function(self: ChannelProxy): number
    hasRead: function(self: ChannelProxy, id: number): boolean
    peek: function(self: ChannelProxy): any
    pop: function(self: ChannelProxy): any
    push: function(self: ChannelProxy, value: any): number
    supply: function(self: ChannelProxy, value: any): boolean
    supply: function(self: ChannelProxy, value: any, timeout: number): boolean
end

function ChannelProxy:clear()
    Msg.clear(self.ch)
end

function ChannelProxy:demand(timeout: number): any
    return Msg.demand(self.ch, timeout)
end

function ChannelProxy:getCount(): number
    return Msg.get_count(self.ch)
end

function ChannelProxy:hasRead(id: number): boolean
    return Msg.has_read(self.ch, id as Msg.ID)
end

function ChannelProxy:peek(): any
    return Msg.peek(self.ch)
end

function ChannelProxy:pop(): any
    return Msg.pop(self.ch)
end

function ChannelProxy:push(value: any): number
    Msg.push(self.ch, value)
end

function ChannelProxy:supply(value: any, timeout: number): boolean
    return Msg.supply(self.ch, value)
end

local ChannelProxy_mt: metatable<ChannelProxy> = {
    __index = ChannelProxy,
}

function ChannelProxy.new(name: string): ChannelProxy
    local self = setmetatable({} as ChannelProxy, ChannelProxy_mt)
    self.ch = Msg.new(name)
    return self
end

return ChannelProxy
