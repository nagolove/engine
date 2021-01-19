local inter = require "inter"
--inter.foo()

local tabular = require("tabular")
print("tabular", tabular(inter))

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
