-- vim: fdm=marker
-- vim: set colorcolumn=85

-- Based on darkfrei code(https://github.com/darkfrei/love2d-lua-tests/blob/main/diamond-square/main.lua)
-- License CC0 (Creative Commons license) (c) darkfrei, 2021
-- https://www.youtube.com/watch?v=4GuAV1PnurU

require 'love'
local Pipeline = require 'pipeline'

--local format = string.format
--local inspect = require "inspect"
local das = require "diamond_and_square"

--[[
XXX Ошибки разработки.
-- {{{
Класс DiamonAndSquare плох с точки зрения проектирования и архитектуры
программного обеспечения. 

Как класс можно использовать для создания карт ландшафта без фреймворка love 
и модулей xcaustic(в частности зависимость от класса Pipeline)?

Если я хочу вынести генератор карт в отдельную консольную программу или скрипт,
то не смогу этого сделать быстро и удобно.

Более практичной кажется разделения модуля на несколько частей:

diamondsquare.tl
Для использования внутри движка, высокая связность.

diamondsquare_common.tl
Для использования во внешних программах, низкая связность. Пользовательский
интерфейс модуля может быть заменен C реализацией.
-- }}}
--]]

require 'diamondsquare_common'

local record DiamonAndSquare

    record State
        map: {{number}}
        mapSize: integer
    end

    generator: das.Generator
    renderobj_name: string
    pipeline: Pipeline

    rez: integer
    mapSize: integer
    mapn: integer
    done: boolean
    thread: love.thread

    type RandomCallback = function(): number

    -- PUBLIC
    new: function(
        mapn: integer, 
        rng: RandomCallback,
        pl: Pipeline
    ): DiamonAndSquare

    --[[ {{{ Порядок использования:
        eval() send2render() render() или
        eval() save() send2render() render() или
        load() send2render() render()
    -- }}}
    --]]

    -- Основная функция - сознать карту высот
    eval: function(DiamonAndSquare)

    -- Основная функция - сознать карту высот. 
    -- Выполняется в отдельном потоке. Сразу возвращает управление.
    evalAsync: function(DiamonAndSquare)

    -- Возвращает истину когда карта создана
    doneAsync: function(DiamonAndSquare): boolean

    -- Отправить на рисование
    send2render: function(DiamonAndSquare)
    -- Рисовать
    render: function(DiamonAndSquare)

    --[[
    -- Сохранить в файл
    save: function(DiamonAndSquare, fname: string)
    -- Загрузить из файла
    load: function(DiamonAndSquare, fname: string)
    --]]

    -- Установить координаты рисования карты
    setPosition: function(DiamonAndSquare, x: number, y: number)

    -- Возвращает размер поля в пикселях
    getFieldSize: function(DiamonAndSquare): integer

    -- Устанавливает размер одного квадратика карты в пикселях. 
    -- Вызывается до send2render()
    setRez: function(DiamonAndSquare, rez: integer)
end

local DiamonAndSquare_mt: metatable<DiamonAndSquare> = {
    __index = DiamonAndSquare,
}

local serpent = require 'serpent'

function DiamonAndSquare:doneAsync(): boolean
    --[[
    Проверить, что поток создан и запущен. Иначе ошибка.
    Проверить канал сообщений. Если есть сообщение с именем карты и 
    положительным результатом запуска(boolean), то вернуть истину.
    --]]
    return self.done
end

function DiamonAndSquare:setPosition(x: number, y: number)
    self.pipeline:openPushAndClose(self.renderobj_name, 'set_position', x, y)
end

function DiamonAndSquare:render()
    self.pipeline:openPushAndClose(self.renderobj_name, 'flush')
end

function DiamonAndSquare:send2render()
    local map: {{number}} = {}
    for i = 1, self.generator:get_mapsize() do
        map[#map + 1] = {}
        for j = 1, self.generator:get_mapsize() do
            map[#map][j] = self.generator:get(i - 1, j - 1)
        end
    end

    local fname = "map.data." .. randomFilenameStr() .. ".txt"

    local compress = love.data.compress
    local struct = require 'struct'
    local packed_mapsize = struct.pack("L", self.generator:get_mapsize())

    love.filesystem.write(fname, "", 0)
    love.filesystem.append(fname, packed_mapsize, #packed_mapsize)

    print('map', #map)
    print('mapSize', self.mapSize)
    local packed_mapsize = struct.pack("L", self.generator:get_mapsize())

    for i = 1, #map do
        local row = map[i]
        local uncompressed = serpent.dump(row)
        local compressed = compress('string', 'gzip', uncompressed, 9) as string

        --print(format('row[%d]', i))
        --print('#uncompressed', size2human(#uncompressed))
        --print('#compressed', size2human(#compressed))

        local packed_rowlen = struct.pack("L", #compressed)
        love.filesystem.append(fname, packed_rowlen, #packed_rowlen)
        love.filesystem.append(fname, compressed, #compressed)
    end
    --]]

    -- Вызов "метода" в другом потоке
    self.pipeline:openPushAndClose(
        self.renderobj_name, 'map', fname
    )

end

function DiamonAndSquare:evalAsync()
    print('self.generator', self.generator, type(self.generator))

    self.thread = love.thread.newThread("generator_thread.lua")
    self.thread:start()

    --[[
    local tstart = love.timer.getTime()
    self.generator:eval()
    local tfinish = love.timer.getTime()
    print('map generated for', (tfinish - tstart) * 1000., "sec.")
    --]]
end

-- добавить анимацию процесса разбиения
function DiamonAndSquare:eval()
    print('self.generator', self.generator, type(self.generator))
    local tstart = love.timer.getTime()
    self.generator:eval()
    local tfinish = love.timer.getTime()
    print('map generated for', (tfinish - tstart) * 1000., "sec.")
end

function DiamonAndSquare.new(
    mapn: integer, 
    rng: DiamonAndSquare.RandomCallback,
    pl: Pipeline
): DiamonAndSquare

    if type(mapn) ~= 'number' then
        error('No mapn parameter in constructor.')
    end
    local self: DiamonAndSquare
    self = setmetatable({} as DiamonAndSquare, DiamonAndSquare_mt)

    assert(pl, "pipeline is nil")
    self.pipeline = pl
    --self.mapn = 0
    print('renderobj_counter', renderobj_counter)
    renderobj_counter = renderobj_counter + 1
    self.renderobj_name = "diamondsquare" .. renderobj_counter
    --self.mapSize = math.ceil(2 ^ self.mapn) + 1 -- 1025
    self.rez = 8

    self.pipeline:pushCodeFromFileRoot(
        --'diamondsquare', 'diamondsquare-render.lua'
        self.renderobj_name, 'rdr_diamondsquare.lua'
    )

    self.done = true
    self.generator = das.new(mapn, rng)
    self.mapSize = self.generator:get_mapsize()

    --[[
    self.rng = rng
    self.mapn = mapn
    self:reset()
    --]]

    return self
end

function DiamonAndSquare:reset()
    -- Заглушка
    -- Что делать с этой функцией? Удалить или оставить?
end

function DiamonAndSquare:getFieldSize(): integer
    return self.rez * self.mapSize
end

function DiamonAndSquare:setRez(rez: integer)
    self.rez = rez
    self.pipeline:openPushAndClose(
        self.renderobj_name,
        'set_rez', self.rez
    )
end

return DiamonAndSquare
