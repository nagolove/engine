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

global DiamonAndSquare_draw_tiles = 1
global DiamonAndSquare_invert_tiles_draw_order = 2
-- XXX Выбрать более короткий вариант именования?
--global DASquare_invert_tiles_draw_order = 2
--global DiamonAndSquare_inv_draw_order = 2
--global DASquare_inv_draw_order = 2

local record DiamonAndSquare

    record State
        map: {{number}}
        mapSize: integer
    end

    --generator: das.Generator
    renderobj_name: string
    pipeline: Pipeline

    bitmask: number
    rez: integer
    mapSize: integer
    mapn: integer
    thread: love.thread.Thread
    --fname: string
    rngState: string
    finished: boolean

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
    render: function(DiamonAndSquare, x: number, y: number)

    renderWithParam: function(x: number, y: number, param: number)

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

    -- Указать размеры окна вывода. По умолчанию равны размеру экрана.
    setViewport: function(
        DiamonAndSquare, x: number, y: number, w: number, h: number
    )
end

local DiamonAndSquare_mt: metatable<DiamonAndSquare> = {
    __index = DiamonAndSquare,
}

--local serpent = require 'serpent'

function DiamonAndSquare:doneAsync(): boolean
    local gen_status_channel = love.thread.getChannel("gen_status_channel")
    local finished = gen_status_channel:pop() as boolean -- Срабатывает один раз

    if self.thread and self.thread:getError() then
        print('generator_thread.tl crashed with', self.thread:getError())
    end

    if finished then
        if type(finished) ~= 'boolean' then
            error('"finished" shoul be a boolean, not a ' .. type(finished))
        end

        print('self.finished', self.finished)
        self.finished = true
        self:send2render()
    end
    return self.finished ~= nil
end

function DiamonAndSquare:setPosition(x: number, y: number)
    self.pipeline:openPushAndClose(self.renderobj_name, 'set_position', x, y)
end

function DiamonAndSquare:render(x: number, y: number)
    self.pipeline:openPushAndClose(
        self.renderobj_name, 
        'flush', 
        x, y, 
        self.bitmask
    )
end

function DiamonAndSquare:send2render()
    print('DiamonAndSquare:send2render()')
    print('self.mapn, self.rngState', self.mapn, self.rngState)
    -- Вызов "метода" в другом потоке
    self.pipeline:openPushAndClose(
        --self.renderobj_name, 'map', self.fname
        self.renderobj_name, 'map', self.mapn, self.rngState
    )
end

function DiamonAndSquare:evalAsync()
    assert(self.rngState)

    self.thread = love.thread.newThread("generator_thread.lua")

    local rngState = self.rngState
    if not rngState then
        print('Using default(random) rngState')
        local rng = love.math.newRandomGenerator(os.time())
        rngState = rng:getState()
    end

    self.thread:start(self.mapn, rngState)
end

-- добавить анимацию процесса разбиения
function DiamonAndSquare:eval()
    --print('self.generator', self.generator, type(self.generator))
    --local tstart = love.timer.getTime()
    --self.generator:eval()
    --local tfinish = love.timer.getTime()
    --print('map generated for', (tfinish - tstart) * 1000., "sec.")
end

function DiamonAndSquare.new(
    mapn: integer, 
    --rng: DiamonAndSquare.RandomCallback,
    pl: Pipeline
): DiamonAndSquare

    if type(mapn) ~= 'number' then
        error('No mapn parameter in constructor.')
    end
    local self: DiamonAndSquare
    self = setmetatable({} as DiamonAndSquare, DiamonAndSquare_mt)

    assert(pl, "pipeline is nil")
    self.pipeline = pl
    print('renderobj_counter', renderobj_counter)
    renderobj_counter = renderobj_counter + 1
    self.renderobj_name = "diamondsquare" .. renderobj_counter
    self.rez = 8

    self.pipeline:pushCodeFromFileRoot(
        self.renderobj_name, 'rdr_diamondsquare.lua'
    )

    self.bitmask = 0
    self.mapn = mapn
    --self.generator = das.new(mapn, rng)
    --self.mapSize = self.generator:get_mapsize()
    self.mapSize = math.ceil(math.pow(2, mapn) + 1)

    return self
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

function DiamonAndSquare:setViewport(
    x: number, y: number, w: number, h: number
)
    self.pipeline:openPushAndClose(
        self.renderobj_name, 'set_view_port', x, y, w, h
    )
end

return DiamonAndSquare
