-- vim: fdm=marker
-- vim: set colorcolumn=85
-- Фильтр для отладочного вывода

require 'common'
require "love_inc".require_pls_nographic()
local ecodes = require "errorcodes"
local colorize = require 'ansicolors2'.ansicolors
--local sload = serpent.load
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
local type PrintCallback = function(...:any)
local type Filter = {number: {string}}
local type LoaderFilter = function(): Filter
local type Enabled = {number: boolean}
local type LoaderEnabled = function(): Enabled

local channel_filter = love.thread.getChannel("debug_filter")
local channel_enabled = love.thread.getChannel("debug_enabled")

--local channel_ids = love.thread.getChannel("debug_ids")
--local channel_should_print = love.thread.getChannel("debug_should_print")

-- Значения фильтров
local filter: Filter = {}

-- Какие фильтры включены по клавишам
local enabled: Enabled = {
        [0] = false, [1] = false, [2] = false, [3] = false, [4] = false, 
        [5] = false, [6] = false, [7] = false, [8] = false, [9] = false,
}
--]]

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

local function push_shared_enabled(state: Enabled)
    local enabled_ser = serpent.dump(state)

    --print(colorize('%{cyan}enabled_ser:' .. inspect(enabled_ser)))
    --print(colorize("%{cyan}" .. debug.traceback()))

    channel_enabled:clear()
    channel_enabled:push(enabled_ser)
end

local function push_shared_filter(state: Filter)
    local filter_ser = serpent.dump(state)
    channel_filter:clear()
    channel_filter:push(filter_ser)
end

local function set_filter(setup: Filter)
    assert(setup)

    local ok, errmsg = checkNumbers(setup)
    if not ok then
        error("Error in filter setup: " .. errmsg)
    end

    filter = deepCopy(setup)
    push_shared_filter(filter)
    push_shared_enabled(enabled)

end

local function peek_shared_enabled(): Enabled
    local shared_enabled: Enabled
    local enabled_ser = channel_enabled:peek() as string

    --print('enabled_ser', inspect(enabled_ser))

    if enabled_ser then
        local chunk = load(enabled_ser) as LoaderEnabled

        if not chunk then
            error("Could not load(enabled_ser)")
        end

        shared_enabled = chunk()
    end

    --print("filter_ser", filter_ser)
    --print(colorize("%{red}filter_ser:" .. inspect(filter_ser)))
    --print(colorize("%{red}shared_filter:" .. inspect(shared_filter)))
    --print(colorize("%{red}getCount" .. channel_filter:getCount()))

    return shared_enabled
end

local function peek_shared_filter(): Filter
    local shared_filter: Filter
    local filter_ser = channel_filter:peek() as string

    if filter_ser then
        local chunk = load(filter_ser) as LoaderFilter

        if not chunk then
            error("Could not load(filter_ser)")
        end

        shared_filter = chunk()
    end

    --print("filter_ser", filter_ser)
    --print(colorize("%{red}filter_ser:" .. inspect(filter_ser)))
    --print(colorize("%{red}shared_filter:" .. inspect(shared_filter)))
    --print(colorize("%{red}getCount" .. channel_filter:getCount()))

    return shared_filter
end

local printCallback = function(...: any)
    print(...)
end

local function set_callback(cb: PrintCallback)
    assert(cb)
    printCallback = cb
end

local function keypressed(key: string, key2: string)
    assert(key2 == nil, "Use only scancode. Second param always unused.")

    local num = tonumber(key)

    local shared_filter = peek_shared_filter()

    if checkNum(num) then
        enabled[num] = not enabled[num]
        local ids_list = shared_filter[num]
        if ids_list then
            for _, v in ipairs(ids_list) do
                shouldPrint[v] = enabled[num]
            end
        end
    end

    push_shared_enabled(enabled)
end

local function print_ids()
    local msg = ""
    for k, _ in pairs(ids) do
        msg = msg .. k .. " "
    end
    print("Avaible ids are: ", colorize("%{yellow}" .. msg))
end

local function debug_print(id: string, ...: any)

    assert(type(id) == 'string')

    local shared_filter = peek_shared_filter()
    ids = parse_ids(shared_filter)

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

local function build_str(): string
    local shared_filter = peek_shared_filter()
    local shared_enabled = peek_shared_enabled() or enabled
    local s: {string} = {}

    for k, ids_arr in pairs(shared_filter) do
        local state = "(" .. tostring(k)

        if shared_enabled[k] then
            state = state .. "+"
        else
            state = state .. "-"
        end

        state = state .. "): "

        local count = #ids_arr
        for i, id in ipairs(ids_arr) do
            local appendix = i ~= count and "," or " "
            state = state .. id .. appendix
        end

        table.insert(s, state)
    end

    return table.concat(s)
end

local font_size = 32

local font: love.graphics.Font
local ok, errmsg = pcall(function()
    font = love.graphics.newFont(font_size)
end) as boolean, string

if not ok then 
    print("Could not create new default font:", errmsg) 
end

local function render(x0: number, y0: number)
    local s = build_str()

    assert(x0)
    assert(y0)

    local width, _ = love.graphics.getDimensions()
    local old_font = love.graphics.getFont()
    love.graphics.setFont(font)
    love.graphics.printf(s, x0, y0, width)

    love.graphics.setFont(old_font)
end

return {
    render = render,
    debug_print = debug_print,
    set_filter = set_filter,
    set_callback = set_callback,
    keypressed = keypressed,
}
