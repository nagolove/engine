--local record Node
    --{Node}
    --w: number
    --n: string
--end

--local z: Node = {}
--z[1] = {w = 1, n = "s"}
--z.n = "a"

--[[ XXX Compiler bug.
local function inRect(x: number)
end

local v = {}
--local v:any = {}
table.insert(v, { 1, a = 0})
for k, v in pairs(v) do
    print(v[1])
end
--]]

local record Tool
    foo: function()
end

local tools :{Tool} = {}

--local type Load = function(name: string): function(...: any): any..., string
function myload(name: string): function(...: any): any..., string
    print(name)
end

--local chunk, errmsg: any, string = myload("bee")
--(chunk as function)()

local a, b: string, string = "1", "2"
print(a < b)
