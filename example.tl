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

local v:any = {}
table.insert(v, { 1, a = 0})
for k, v in pairs(v) do
    print(v[1])
end
--]]
