-- Фильтр для отладочного вывода

require('mobdebug').listen()

--[[ Сбор требований:

    замена print на 
        debug
        dprint

    фильтр работает во время исполнения программы
    использование цифровых клавиш от 0 до 9

    признаки фильтрации?

    debug(1, 'avaible ', num)
    debug(2, 'hats ', num)

    каждая группа отдельно
    debug_setup({ 1 = {1}, 2 = {2})

    группы объединены
    debug_setup({ 1 = {1, 2}})

    где располагать вызов debug_setup() ??

    номер группы ничего не говорит о ней. Решение - строковый индетификатор.
    debug('joy', 'avaible ', num)
    debug('render', 'hats ', num)

    debug_setup({ 1 = {'joy'}, 2 = {render}})
    debug_setup({ 1 = {'joy', 'render'}, 2 = {'sfx'}})

    производительность?
    максимальное отключение лога - автоматическая модификация всех запускаемых 
    файлов по шаблону.
    --debug_setup({ 1 = {'joy', 'render'}, 2 = {'sfx'}})

    использование стека для включения и отключения отладочного вывода

    применение:
    require dprint = require 'debug'.dprint
    require debug_print = require 'debug'.debug_print
    require debugPrint = require 'debug'.debugPrint
--]]

local function debug_print(id: string, ...: any)
    print(id, ...)
end

local function set_filter(setup: {number: {string}})

end

local type PrintCallback = function(string)

local printCallback = function(s: string)
    print(s)
end

local function set_callback(cb: PrintCallback)
    assert(cb)
    printCallback = cb
end

return {
    debug_print = debug_print,
    set_filter = set_filter,
    set_callback = set_callback,
}
