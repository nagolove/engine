local Msg = require("messenger2")

local ChannelProxy = {}















function ChannelProxy:clear()
   Msg.clear(self.ch)
end

function ChannelProxy:demand(timeout)
   return Msg.demand(self.ch, timeout)
end

function ChannelProxy:getCount()
   return Msg.get_count(self.ch)
end

function ChannelProxy:hasRead(id)
   return Msg.has_read(self.ch, id)
end

function ChannelProxy:peek()
   return Msg.peek(self.ch)
end

function ChannelProxy:pop()
   return Msg.pop(self.ch)
end

function ChannelProxy:push(value)
   Msg.push(self.ch, value)
end

function ChannelProxy:supply(value, timeout)
   return Msg.supply(self.ch, value)
end

local ChannelProxy_mt = {
   __index = ChannelProxy,
}

function ChannelProxy.new(name)
   local self = setmetatable({}, ChannelProxy_mt)
   self.ch = Msg.new(name)
   return self
end

return ChannelProxy
