-- vim: fdm=marker
-- vim: set colorcolumn=85

-- Based on darkfrei code(https://github.com/darkfrei/love2d-lua-tests/blob/main/diamond-square/main.lua)
-- License CC0 (Creative Commons license) (c) darkfrei, 2021
-- https://www.youtube.com/watch?v=4GuAV1PnurU

--[[
XXX Ошибки разработки.
-- {{{
Класс DiamonAndSquare плох с точки зрения проектирования и архитектуры
программного обеспечения. 

Как класс можно использовать для создания карт ландшафта без фреймворка love 
и модулей xcaustic(в частности зависимость от класса Pipeline)?

Я хочу вынести генератор карт в отдельную консольную программу или скрипт,
то не могу этого сделать быстро и удобно.

Более практичной кажется разделения модуля на несколько частей:

diamondsquare.tl
Для использования внутри движка, высокая связность.

diamondsquare_common.tl
Для использования во внешних программах, низкая связность. Пользовательский
интерфейс модуля может быть заменен C реализацией.
-- }}}
--]]

require 'love'

local Pipeline = require 'pipeline'
local format = string.format
local inspect = require "inspect"

require 'diamondsquare_common'

local record DiamonAndSquare

    record State
        map: {{number}}
        mapSize: integer
    end

    renderobj_name: string
    pipeline: Pipeline
    scale: number
    maxcanvassize: integer
    rez: integer
    map: {{number}}

    -- в пикселях
    --width: integer
    -- в пикселях
    --height: integer

    mapSize: integer
    chunkSize: integer
    --roughness: integer
    rng: RandomCallback
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

    printMap2File: function(DiamonAndSquare, filenum: integer)

    -- PRIVATE
    random: function(DiamonAndSquare, min: number, max: number): number
    reset: function(DiamonAndSquare)
    -- нормализовать значения высот к диапазону 0..1
    normalizeInplace: function(DiamonAndSquare)
    -- шаг алмаза
    diamond: function(DiamonAndSquare): boolean
    diamondValue: function(DiamonAndSquare, i: number, j: number, half: number): number, number, number
    -- шаг квадрат(?)
    square: function(DiamonAndSquare)
    squareValue: function(DiamonAndSquare, number, number, number): number, number
    value: function(DiamonAndSquare, number, number): number
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
    local uncompressed = serpent.dump(self.map)
    local compress = love.data.compress
    local compressed = compress('string', 'gzip', uncompressed, 9) as string
    print('#compressed', #compressed)

    self.pipeline:openPushAndClose(
        self.renderobj_name, 
        'map', self.mapSize, compressed
    )
    self.pipeline:openPushAndClose(
        self.renderobj_name,
        'set_rez', self.rez
    )

end

function DiamonAndSquare:setRez(rez: integer)
    self.rez = rez
    self.pipeline:openPushAndClose(
        self.renderobj_name,
        'set_rez', self.rez
    )
end

function DiamonAndSquare:load(fname: string)
    local data, size = love.filesystem.read(fname)
    if data then
        local func: DiamonAndSquare.State
        local ok, errmsg = pcall(function()
            func = load(data)() as DiamonAndSquare.State
        end) as (boolean, string)
        if not ok then
            local msg_part = fname .. ': ' .. errmsg
            print('Could not load DiamonAndSquare from ' .. msg_part)
        end
        self.mapSize = func.mapSize
        self.map = func.map
    else
        local msg_part = fname .. ': ' .. tostring(size)
        error('Could not load DiamonAndSquare from ' .. msg_part)
    end
end

--[[
function DiamonAndSquare:serialize(): string
    local state: DiamonAndSquare.State = {
        mapSize = self.mapSize,
        map = self.map,
    }
    return serpent.dump(state)
end
--]]

function DiamonAndSquare:save(_: string)
--function DiamonAndSquare:save(fname: string)
    --local succ, msg = love.filesystem.write(fname, self:serialize())
    --if not succ then
        --error('Could not save DiamonAndSquare to ' .. fname .. ': ' .. msg)
    --end
end

function DiamonAndSquare:newCoroutine(): thread
    return coroutine.create(function()
        local stop = false
        repeat
            self:square()
            -- Здесь отправлять данные на рисование промежуточного результата.
            coroutine.yield()
            stop = self:diamond()
            coroutine.yield()
            -- Здесь отправлять данные на рисование промежуточного результата.
        until stop
        --self:normalizeInplace()
    end)
    --[[
    local ok: boolean
    ok = coroutine.resume(coro)
    while ok do
        ok = coroutine.resume(coro)
    end
    --]]
end

-- добавить анимацию процесса разбиения
function DiamonAndSquare:eval(): DiamonAndSquare

    local filenum = 0
    print('------------------------------------------------------------')
    self:printMap2File(filenum)
    filenum = filenum + 1
    print('------------------------------------------------------------')

    local coro = coroutine.create(function()
        local stop = false
        repeat
            self:square()

            ----------------------------------------
            self:printMap2File(filenum)
            filenum = filenum + 1
            ----------------------------------------

            -- Здесь отправлять данные на рисование промежуточного результата.
            coroutine.yield()
            stop = self:diamond()

            --[[ 
            Здесь отправлять данные на рисование промежуточного результата.
            Данные будут не отправляться, а всегда присутствовать в map.
            На каждом шаге корутина обновляет состояние map.
            Как экономно передавать состояние map? Только измененное состояние?
            --]]

            ----------------------------------------
            self:printMap2File(filenum)
            filenum = filenum + 1
            ----------------------------------------

        until stop
        self:normalizeInplace()

        ----------------------------------------
        self:printMap2File(filenum)
        filenum = filenum + 1
        ----------------------------------------

    end)
    ---------
    local ok: boolean
    ok = coroutine.resume(coro)
    while ok do
        ok = coroutine.resume(coro)
    end
    --]]
    ---------
    return self
end

function DiamonAndSquare:normalizeInplace()
    for i = 1, self.mapSize do
        for j = 1, self.mapSize do
            local c = self.map[i] and self.map[i][j] or nil
            if c then
                if c > 1 then 
                    self.map[i][j] = 1
                elseif c < 0 then
                    self.map[i][j] = 0
                end
            end
        end
    end
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

    self.renderobj_name = "diamondsquare" .. renderobj_counter
    renderobj_counter = renderobj_counter + 1
    self.pipeline:pushCodeFromFileRoot(
        --'diamondsquare', 'diamondsquare-render.lua'
        self.renderobj_name, 'rdr_diamondsquare.lua'
    )

    self.rng = rng
    self.mapn = mapn
    self:reset()
    self.rez = 8

    return self
end

function DiamonAndSquare:reset()
	self.map = {}
	self.mapSize = math.ceil(2 ^ self.mapn) + 1 -- 1025

	self.chunkSize = self.mapSize - 1
	--self.roughness = 2
	
	local corners = {
        {
            i = 1,
            j = 1
        }, 
        { 
            i = self.mapSize,
            j = 1
        }, 
        {
            i = self.mapSize, 
            j = self.mapSize 
        }, 
        {
            i = 1,
            j = self.mapSize
        }
    }
	
	for _, corner in ipairs(corners) do
		local i, j = corner.i, corner.j

		local value = self.rng()

		value = 0.5 - 0.5 * math.cos(value * math.pi)
		self.map[i] = self.map[i] or {}
		self.map[i][j] = value
	end
end
--]]

local floor = math.floor

function DiamonAndSquare:value(i: number, j: number): number
    --print(i - floor(i))
    --print(j - floor(j))
    if (i - floor(i) > 0.) then
        --print('i', i)
    end
    if (j - floor(j) > 0.) then
        --print('j', j)
    end
	if self.map[floor(i)] and self.map[floor(i)][floor(j)] then
		return self.map[floor(i)][floor(j)]
    else
        --print('no such cell, i, j', i, j)
        print(format("value is NULL for [%d, %d]", i, j));
	end
end

function DiamonAndSquare:random(min: number, max: number): number
	--local r = 4*(math.random ()-0.5)^3 + 0.5
	--local r = 4*(self.rng()-0.5)^3 + 0.5
--	https://www.desmos.com/calculator/toxjtsovev
    --local result = min + r*(max-min)
    --print('DiamonAndSquare:random()', min, max, result)

    -- XXX
    --[[
    if love.keyboard.isDown('l') then
        return result
    else
        return min + self.rng()*(max-min)
    end
    --]]

    return min + self.rng()*(max-min)
end

function DiamonAndSquare:squareValue(i: number, j: number): number, number
	local min, max: number, number
   
    -- Увеличение индексов
    local corners = {
        {i = i, j = j}, 
        {i = i + self.chunkSize, j = j}, 
        {i = i, j = j + self.chunkSize}, 
        {i = i + self.chunkSize, j = j + self.chunkSize}
    }

    for _, corner in ipairs(corners) do
        local v = self:value(corner.i, corner.j)
        if v then
            --if min and (math.min(min, v) or v) then
            --min = min and (math.min(min, v) or v)
            --end
            min = min and math.min(min, v) or v
            max = max and math.max(max, v) or v
        end
    end
    return min, max
end


function DiamonAndSquare:square()
    print('square')
	local half = math.floor(self.chunkSize / 2)
	for i = 1, self.mapSize - 1, self.chunkSize do
		for j = 1, self.mapSize - 1, self.chunkSize do
			local min, max = self:squareValue (i, j)
            self.map[i+half] = self.map[i+half] or {}
			self.map[i+half][j+half] = self:random(min, max)
		end
	end
end

function DiamonAndSquare:diamondValue(i: number, j: number, half: number): number, number, number
	local min, max: number, number = 1000., -1000.

    -- Уменьшение индексов
    local corners = {
        {i = i, j = j - half}, 
        {i = i  +  half, j = j}, 
        {i = i, j = j  +  half}, 
        {i = i - half, j = j},
    }

	--for _, corner in ipairs({{i=i, j=j-half}, {i=i+half, j=j}, {i=i, j=j+half}, {i=i-half, j=j}}) do
    for _, corner in ipairs(corners) do
		local v = self:value (corner.i, corner.j)
		if v then
			--min = min and math.min (min, v) or v
			--max = max and math.max (max, v) or v
			min = math.min (min, v)
			max = math.max (max, v)
		end
	end
	return min, max
end

function DiamonAndSquare:diamond(): boolean
    print('--------------------- diamond ---------------------')
	local half = self.chunkSize/2
    print('half', half)
    local ceil = math.ceil

	for i = 1, self.mapSize, half do
		for j = (i+half)%self.chunkSize, self.mapSize, self.chunkSize do
            --print ('i: '..i .. ' j:'.. j)
--			if (i + j)%half == 0 then
				local min, max = self:diamondValue(i, j, half)
                --print('min, max', min, max)
				self.map[ceil(i)] = self.map[ceil(i)] or {}
				self.map[ceil(i)][ceil(j)] = self:random (min, max)
--			end
		end
	end
	
	self.chunkSize = ceil(self.chunkSize/2)
	--self.roughness = ceil(self.roughness/2)
	return self.chunkSize <= 1
end

function DiamonAndSquare:getFieldSize(): integer
    return self.rez * self.mapSize
end

function DiamonAndSquare:printMap2File(filenum: integer)
    assert(type(filenum) == 'number' and filenum >= 0)

    local file = io.open(string.format('map.lua.%d.txt', filenum), "w+")
	--for i = 1, #self.map do
    for _, v in ipairs(self.map) do
        --print(inspect(self.map[i]))
        --local str = inspect(self.map[i])
        local str = inspect(v)
        file:write(str .. '\n')
	end
    file:close()
end

--[[
-- что делает эта функция?
local function power(value: number): number
	local n = -1
		while value > 1 do
			n=n+1
			value = value/2
		end
	return n
end
--]]

return DiamonAndSquare
