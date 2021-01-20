local inter = require "inter"
--inter.foo()

--local tabular = require("tabular")
--print("tabular", tabular(inter))
--local inter = require "inter" as Inter

require "example2"

function compareTypes()
    local type Type1 = {number}
    local type Type2 = {{number, number}}
    local type Type3 = {number}
    local v1: Type1 = {1, 2, 3}
    local v2: Type3 = {0, 0}
    --v1 = v2 as Type1
    --v1 = v2
end

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


local zh: {{number}} = {}
print(zh[1][2])

local x: {number} = {1}
local y: {number} = {2}
y = x

local z: {number, number} = {1, 2}

function foo(): {number, number}
    --return (12, 12) as {number, number}
end

--function foo(): {number, number}
    --return 12, 12) as {number, number}
--end

function copy<T>(t:T):T
    if t is table then 
        local result = {}
        for k, v in pairs(t) do
            result[k] = v
        end
        return result as T
    end
    return t
end

