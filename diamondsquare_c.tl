-- vim: fdm=marker
-- vim: set colorcolumn=85

-- Based on darkfrei code(https://github.com/darkfrei/love2d-lua-tests/blob/main/diamond-square/main.lua)
-- License CC0 (Creative Commons license) (c) darkfrei, 2021
-- https://www.youtube.com/watch?v=4GuAV1PnurU

require 'love'
local Pipeline = require 'pipeline'

local inspect = require "inspect"
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
    --map: {{number}}

    -- в пикселях
    --width: integer
    -- в пикселях
    --height: integer

    rez: integer
    mapSize: integer
    --[[
    chunkSize: integer
    roughness: integer
    --]]
    mapn: integer

    type RandomCallback = function(): number

    -- PUBLIC
    new: function(
        mapn: integer, 
        rng: RandomCallback,
        pl: Pipeline
    ): DiamonAndSquare

    --[[
    Порядок использования:
        eval() send2render() render()
    или
        eval() save() send2render() render()
    или
        load() send2render() render()
    --]]

    -- основная функция - сознать карту высот
    eval: function(DiamonAndSquare): DiamonAndSquare
    -- сохранить в файл
    save: function(DiamonAndSquare, fname: string)
    -- загрузить из файла
    load: function(DiamonAndSquare, fname: string)
    -- отправить на рисование
    send2render: function(DiamonAndSquare)
    -- рисовать
    render: function(DiamonAndSquare)
    setPosition: function(DiamonAndSquare)
    getFieldSize: function(): integer
    setRez: function(rez: integer)
end

local DiamonAndSquare_mt: metatable<DiamonAndSquare> = {
    __index = DiamonAndSquare,
}

local serpent = require 'serpent'

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
    --local tabular_t = require("tabular").show2
    --local tabular_t = require("tabular").show

    --[[
    print('------------------- map ------------------- ')
    for i = 1, #map do
        print("i = ", i, inspect(map[i]))
        print()
    end
    print('------------------- map ------------------- ')
    --print(tabular_t(map))
    --]]


    local uncompressed = serpent.dump(map)
    local compress = love.data.compress
    local compressed = compress('string', 'gzip', uncompressed, 9) as string
    print('#compressed', #compressed)
    self.pipeline:openPushAndClose(
        self.renderobj_name, 'map', self.generator:get_mapsize(), compressed
    )
end

-- добавить анимацию процесса разбиения
function DiamonAndSquare:eval(): DiamonAndSquare
    print('self.generator', self.generator, type(self.generator))
    self.generator:eval()
    return self
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
    self.mapn = 0
    print('renderobj_counter', renderobj_counter)
    renderobj_counter = renderobj_counter + 1
    self.renderobj_name = "diamondsquare" .. renderobj_counter
    self.mapSize = math.ceil(2 ^ self.mapn) + 1 -- 1025
    self.rez = 8

    self.pipeline:pushCodeFromFileRoot(
        --'diamondsquare', 'diamondsquare-render.lua'
        self.renderobj_name, 'rdr_diamondsquare.lua'
    )

    self.generator = das.new(mapn, rng)

    --[[
    self.rng = rng
    self.mapn = mapn
    self:reset()
    --]]

    return self
end

function DiamonAndSquare:reset()
    -- заглушка
end

function DiamonAndSquare:getFieldSize(): integer
    return self.rez * self.mapSize
end

function DiamonAndSquare:setRez(rez: integer)
    self.pipeline:openPushAndClose(
        self.renderobj_name,
        'set_rez', self.rez
    )
end

return DiamonAndSquare
