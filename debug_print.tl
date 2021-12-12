-- vim: fdm=marker
-- vim: set colorcolumn=85
-- Фильтр для отладочного вывода

--require('mobdebug').listen()
require 'common'

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
    }}}
--]]

local type Filter = {number: {string}}
local type PrintCallback = function(...:any)

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
local shouldPrint: {string: boolean}

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
local function checkNumbers(filter: Filter): boolean, string
    for k, _ in pairs(filter) do
        local num = tonumber(k)
        -- Какие здесь дополнительные проверки нужны?
        if not (num and checkNum(num)) then
            return false, "Incorrect number(not in 0..9 range): " .. num
        end
    end
    return true
end

local function set_filter(setup: Filter)
    assert(setup)
    filter = deepCopy(setup)
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
    assert(key2, "Use only scancode. Second param unused.")
    local num = tonumber(key)
    if checkNum(num) then
        enabled[num] = not enabled[num]
        local isEnabled = enabled[num]
        local ids = filter[num]
        for _, v in ipairs(ids) do
            shouldPrint[v] = isEnabled
        end
    end
end

local function debug_print(id: string, ...: any)
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
