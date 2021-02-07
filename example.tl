--[[
function blah(): number|string
end
local n: number = blah()
--]]

-------------------------------------------------------

--local type Class = record
    --new: function(): Class
    --do1: function(Class)
--end

--function Class.new(): Class
    --print("constructor")
    --return {} as Class
--end

--function Class:do1()
    --print("hi")
--end

--local a: Class = Class.new()
--a:do1()

-------------------------------------------------------

    --[[
local type Class = record
    new: function(): Class
    do1: function(Class)

    --type __index = Class
end

--Class.__index = {}
local Class_mt: metatable<Class> = {
    __index = Class
}

function Class.new(): Class
    print("constructor")
    --re
    turn setmetatable({} as Class, Class as metatable<Class>)
    return setmetatable({} as Class, Class_mt)
end

function Class:do1()
    print("hi")
end

local a: Class = Class.new()
a:do1()

local b: Class = {}

function b:do1()
    print("hi2")
end

    --]]

--[[
function log(...: any)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local arg: any = args[i]
        if str == "" then
            str = tostring(arg)
        else
            str = str ..  "\t" .. tostring(arg)
        end
    end
    print(str)
end
--]]

--[[
local record kons 
    color: {number}
    show: boolean

    new: function(): kons
    draw: function(kons, x0: number, y0: number)

    --__call: function(kons): kons
end

local kons_mt: metatable<kons> = {
    __index = kons
}

function kons_mt.__call(self: kons): kons
    return self.new()
end

function kons.new(): kons
    --local self: kons = {
    --local inst: kons = {
    local inst: kons = {
        color = {1, 1, 1},
        show = true,
    }
    return setmetatable(inst, kons_mt)
end

function kons:draw()
    local inspect = require "inspect"
    print("draw", inspect(self))
end

local k: kons = kons.new()
k:draw()

--local function foo(a: number, b?: number)
    --print(a, b)
--end

--]]

--[[
local record kons 
    any_identifier other_sequence_ fe
    hmm fe
    --_d: d: d
end
local did: kons = {}
print(did)
--]]
