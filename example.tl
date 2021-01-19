local inter = require "inter"
--inter.foo()

--local tabular = require("tabular")
--print("tabular", tabular(inter))

local type Inter = record
    foo: function()
    bar: function()
end
--local inter = require "inter" as Inter

local inspect = require "inspect"

global type actions = enum
    "moveleft"
    "moveright"
    "moveup"
    "movedown"
end

global type Tool = record
    init: function()
    draw: function()
    update: function()
end

function initModule(tool: Tool)
    print("initModule", inspect(tool))
end

initModule({
    init = function()
    end,
    draw = function()
    end,
    --update = function()
    --end
})

--local inter2 = Inter


initModule({})
--initModule("hi")
--initModule(1)

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
