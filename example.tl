local inter = require "inter"
--inter.foo()

--local tabular = require("tabular")
--print("tabular", tabular(inter))
--local inter = require "inter" as Inter

local var: Inter
local var2: Inter2

local inspect = require "inspect"

local type Map = {string: boolean}
local type Seq = {number}

local a: Seq = {1, 2, 3}
local b: Map = {
    hi = -1 or false,
    lo = 1 or true,
}

function printMap(m: Map)
    for k, v in pairs(m) do
        print(k, v)
    end
end

function printSeq(arr: Seq)
    for k, v in ipairs(arr) do
        print(k, v)
    end
end

printSeq(a)
printMap(b)


local ok, errmsg: boolean, boolean = pcall(function()
    print("from pcall")
end)

--local errmsg = false
print(ok, errmsg)
