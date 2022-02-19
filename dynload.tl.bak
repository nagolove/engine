--[[
print('package.cpath before', package.cpath)
package.cpath = package.cpath .. ';ddd/target/lib?.so'
print('package.cpath after', package.cpath)
local ddd = require "ddd/target/debug/ddd"
local inspect = require "inspect"
print('ddd', inspect(ddd))
--]]

local C = require 'ffi'
C.cdef [[
int32_t add(int32_t a, int32_t b);

typedef void(*Callback)(int32_t a, int32_t b, void* ptr, int64_t f);
typedef void(*Callback_noargs)();
typedef void(*Callback_1arg)(int32_t a);

void pump_iron(Callback a, Callback b);
void pump_iron_noargs(Callback_noargs a);
void pump_iron_1arg(Callback_1arg a);
]]

require 'ddd'

local ddd_C = C.load 'ddd' as DDD
local a, b = 200, 1
--print('add', ddd_C.add(a, b))

local function test_external_add()
    local random = math.random
    local format = string.format
    for i = 1, 1000000 do
        local a, b = random(1, 100000), random(1, 100000)
        --print('a, b', a, b)
        local should_be = a + b
        local res = ddd_C.add(a, b)
        if should_be ~= res then
            error(format("%d + %d ~= %d, res = %d", a, b, should_be, res))
        end
    end
end

local function pumper1(a: number, b: number, ptr: any, f: number)
    assert(a + 1 == b)
    print('pumper3')
    print('a', a)
    print('b', b)
    print('ptr', ptr)
    print('f', f)
end

local function pumper2(a: number, b: number, ptr: any, f: number)
    assert(a - 1 == b)
    print('pumper2')
    print('a', a)
    print('b', b)
    print('ptr', ptr)
    print('f', f)
end

local function pumper_noargs()
    print('pumper_noargs')
end

local function pump_iron_1arg(a: number)
    print('pump_iron_1arg', a)
end

local function test_pump_iron()
    local random = math.random
    local format = string.format
    local cb1 = C.cast('Callback', pumper1) as DDD.Pumper
    local cb2 = C.cast('Callback', pumper2) as DDD.Pumper

    local cb_noargs = C.cast('Callback_noargs', pumper_noargs) as DDD.Pumper_noarg
    local cb_1arg = C.cast('Callback_1arg', pump_iron_1arg) as DDD.Pumper_1arg

    --for i = 1, 2 do
    for i = 1, 10000 do
        ddd_C.pump_iron(cb1, cb2)
    end
    ddd_C.pump_iron_noargs(cb_noargs)
    ddd_C.pump_iron_1arg(cb_1arg)
end

test_external_add()
test_pump_iron()
