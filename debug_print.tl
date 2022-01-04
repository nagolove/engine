-- vim: fdm=marker
-- vim: set colorcolumn=85
-- Фильтр для отладочного вывода

require 'common'
local ecodes = require "errorcodes"
local colorize = require 'ansicolors2'.ansicolors

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
local filter: Filter = {}

-- Какие фильтры включены по клавишам
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

-- Какие фильтры включены по идентификаторам
local shouldPrint: {string: boolean} = {}

-- Карта существующих идентификаторов?
local ids: {string: boolean} = {}

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
    filter = deepCopy(setup)
    ids = parse_ids(setup)

    local ok, errmsg = checkNumbers(filter)
    if not ok then
        print("Error in filter setup: ", errmsg)
    end
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
end

local function print_ids()
    local msg = ""
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

return {
    debug_print = debug_print,
    set_filter = set_filter,
    set_callback = set_callback,
    keypressed = keypressed,
}
