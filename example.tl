local type Rec = record
    n: number
    fun: function(number, number)
end

local r: Rec = {}

function foo(init: Rec)
    for k, v in pairs(init as {any:any}) do
        --r[k] = v
    end
end

--local record Node
    --{Node}
    --w: number
    --n: string
--end

--local z: Node = {}
--z[1] = {w = 1, n = "s"}
--z.n = "a"

--local file: FILE
--file = io.open("test.txt", "w")
--file:write("great")
