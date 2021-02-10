local record R
    h: function()
end

local self: R = {
    --function foo()
        --print("j")
    --end

    --"foo" = function()
        --print('hi')
    --end
}

local enum Enum
    "h"
end

self.h()
self["h"]()
--(self as {string:any})["wf"]()
local k = "ef"
--(self as {string:function})[k]()
self[k as Enum]()
