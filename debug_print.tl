-- vim: fdm=marker
-- vim: set colorcolumn=85
-- Фильтр для отладочного вывода

require 'common'
local ecodes = require "errorcodes"
local colorize = require 'ansicolors2'.ansicolors
local sload = serpent.load
local serpent = require "serpent"

--[[ {{{ 
    Применение:

    local dprint = require 'debug_print'
    local debug_print = dprint.debug_print

    dprint.set_filter({ 1 = {'joy'}, 2 = {render}})
    dprint.set_filter({ 1 = {'joy', 'render'}, 2 = {'sfx'}})

    debug_print('joy', 'avaible ', num)
    debug_print('render', 'hats ', num)

    love.keypressed = debug_print.keypressed

    Что еще можно сделать:
     * использование стека для включения и отключения отладочного вывода
     * рисование списка фильтров(через холст)
     * клиент-серверная архитектура(один модуль на много рабочих потоков)
       Применить каналы для реализации 
       Нужно знать общее количество потоков используемых логером
       Зная общее количество потоков можно понять когда делать 
       debugChannel:pop() - когда все потоки прочитают новое состояние
    }}}
--]]

--local inspect = require 'inspect'
local format = string.format
local type Filter = {number: {string}}
local type PrintCallback = function(...:any)

-- Как синхронизировать?
-- Когда нужно считывать события из каналов?
-- Когда записывать новые значения в каналы?
local channel_filter = love.thread.getChannel("debug_filter")
local channel_enabled = love.thread.getChannel("debug_enabled")
local channel_ids = love.thread.getChannel("debug_ids")
local channel_should_print = love.thread.getChannel("debug_should_print")

-- Значения фильтров
--local filter: Filter = {}

-- Какие фильтры включены по клавишам
--[[
local enabled: {number: boolean} = {
        [0] = false, 
        [1] = false, 
        [2] = false, 
        [3] = false, 
        [4] = false, 
        [5] = false,
        [6] = false,
        [7] = false,
        [8] = false,
        [9] = false,
}
--]]

-- Какие фильтры включены по идентификаторам
--local shouldPrint: {string: boolean} = {}

-- Карта существующих идентификаторов?
--local ids: {string: boolean} = {}

-- Как тестировать отдельные функции?
local function checkNum(n: number): boolean
    local m: {number: boolean} = {
        [0] = true, 
        [1] = true, 
        [2] = true, 
        [3] = true, 
        [4] = true, 
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
    }
    return m[n] or false
end

-- Проверка на корректность введеных цифры 0-9
local function checkNumbers(filt: Filter): boolean, string
    for k, _ in pairs(filt) do
        local num = tonumber(k)
        -- Какие здесь дополнительные проверки нужны?
        if not (num and checkNum(num)) then
            return false, "Incorrect number(not in 0..9 range): " .. num
        end
    end
    return true
end

local function parse_ids(setup: Filter): {string: boolean}
    local ret_ids = {}
    for _, row in pairs(setup) do
        for _, id in ipairs(row) do
            ret_ids[id] = true
        end
    end
    return ret_ids
end

local function set_filter(setup: Filter)
    assert(setup)
    --filter = deepCopy(setup)
    local filter = serpent.dump(setup)
    local ids = serpent.dump(parse_ids(setup))

    --channel_filter:push(setup)
    --channel_ids:push(ids)

    local ok, errmsg = checkNumbers(setup)
    if not ok then
        error("Error in filter setup: " .. errmsg)
    end

    channel_filter:push(filter)
    channel_ids:push(ids)
end

local printCallback = function(...: any)
    print(...)
end

local function set_callback(cb: PrintCallback)
    assert(cb)
    printCallback = cb
end

local function keypressed(key: string, key2: string)
    --print('key2', key2)
    assert(key2 == nil, "Use only scancode. Second param always unused.")

    --[[
    Нужно-ли было комментировать print() в данной функции?
    ]]

    local num = tonumber(key)

    local enabled = channel_enabled:pop() as {number: boolean}
    if not enabled then
        enabled = {
            [0] = false, 
            [1] = false, 
            [2] = false, 
            [3] = false, 
            [4] = false, 
            [5] = false,
            [6] = false,
            [7] = false,
            [8] = false,
            [9] = false,
        }
        --error("Could not pop enabled")
    end

    local filter: Filter

    filter = channel_filter:pop() as Filter
    if not filter then
        filter = {
        }
    end

    local shouldPrint: {string: boolean}

    shouldPrint = serpent.load(channel_should_print:pop() as string) as {string: boolean}
    if not shouldPrint then
        -- XXX как это будет работать?
        shouldPrint = {}
    end

    --print('num', num)
    if checkNum(num) then
        enabled[num] = not enabled[num]
        local isEnabled = enabled[num]
        --print('filter', inspect(filter))
        --print('filter[num]', inspect(filter[num]))
        local ids_list = filter[num]
        if ids_list then
            for _, v in ipairs(ids_list) do
                shouldPrint[v] = isEnabled
                --print("shouldPrint[v]", shouldPrint[v])
            end
        end
        --debugChannel:push(shouldPrint)
    end

    channel_enabled:push(enabled)
    channel_should_print:push(serpent.dump(shouldPrint))
end

local function print_ids()
    local msg = ""

    local ids: {string: boolean}
    ids = serpent.load(channel_ids:peek() as string) as {string: boolean}

    for k, _ in pairs(ids) do
        msg = msg .. k .. " "
    end
    print("Avaible ids are: ", colorize("%{yellow}" .. msg))
end

local function debug_print(id: string, ...: any)

    --print('shouldPrint', inspect(shouldPrint))
    --print('id', id)
    --print('ids[id]', ids[id])

    assert(type(id) == 'string')

    local ids: {string: boolean}
    ids = serpent.load(channel_ids:peek() as string) as {string: boolean}

    local shouldPrint: {string: boolean}
    --shouldPrint = sload(channel_should_print:peek() as string) as {string: boolean}
    shouldPrint = sload(channel_should_print:peek())

    if not ids[id] then
        local msg = format("id = '%s' not found in filter", tostring(id))
        print(msg)
        print_ids()
        print(debug.traceback())
        os.exit(ecodes.ERROR_NO_SUCH_DEBUG_ID)
    end

    if shouldPrint[id] then
        printCallback(...)
    end
end

local function render(x0: number, y0: number)
    local s = ""

    local filter: Filter
    filter = sload(channel_filter:peek())

    local enabled: {number: boolean}

    for k, ids in pairs(filter) do
        local t = ""
        local is_enabled = enabled[k]
        if is_enabled then
            s = "*"
        else
            s = "-"
        end
        for _, id in ipairs(ids) do
            t = t .. " " .. id
        end
    end

    print('render', s)
    assert(x0)
    assert(y0)

    local width = 300
    love.graphics.printf(s, x0, y0, width)
end

return {
    render = render,
    debug_print = debug_print,
    set_filter = set_filter,
    set_callback = set_callback,
    keypressed = keypressed,
}
