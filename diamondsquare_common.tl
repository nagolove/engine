local Pipeline = require 'pipeline'

global renderobj_counter = 0

local record DiamonAndSquare_common

    record State
        map: {{number}}
        mapSize: integer
    end

    pipeline: Pipeline
    scale: number
    maxcanvassize: integer
    --rez: integer
    map: {{number}}

    -- в пикселях
    --width: integer
    -- в пикселях
    --height: integer

    mapSize: integer
    chunkSize: integer
    roughness: integer
    mapn: integer

    type RandomCallback = function(): number

    -- PUBLIC
    new: function(
        mapn: integer, 
        rng: RandomCallback
    ): DiamonAndSquare_common

    --Порядок использования:
        --eval() send2render() render()
    --или
        --eval() save() send2render() render()
    --или
        --load() send2render() render()

    type DiamonAndSquare_cmn = DiamonAndSquare_common

    -- основная функция - сознать карту высот
    eval: function(DiamonAndSquare_cmn): DiamonAndSquare_cmn
    -- сохранить в файл
    save: function(DiamonAndSquare_cmn, fname: string)
    -- загрузить из файла
    load: function(DiamonAndSquare_cmn, fname: string)
    -- отправить на рисование
    send2render: function(DiamonAndSquare_cmn)
    -- рисовать
    render: function(DiamonAndSquare_cmn)

    -- PRIVATE
    random: function(DiamonAndSquare_cmn, min: number, max: number): number
    reset: function(DiamonAndSquare_cmn)
    -- нормализовать значения высот к диапазону 0..1
    normalizeInplace: function(DiamonAndSquare_cmn)
    -- шаг алмаза
    diamond: function(DiamonAndSquare_cmn): boolean
    diamondValue: function(DiamonAndSquare_cmn, i: number, j: number, half: number): number, number, number
    -- шаг квадрат(?)
    square: function(DiamonAndSquare_cmn)
    squareValue: function(DiamonAndSquare_cmn, number, number, number): number, number, number
    value: function(DiamonAndSquare_cmn, number, number): number
end

--[[

local DiamonAndSquare_mt: metatable<DiamonAndSquare> = {
    __index = DiamonAndSquare,
}

local serpent = require 'serpent'

function DiamonAndSquare:getCompressedMap(): string
    local uncompressed = serpent.dump(self.map)
    local compress = love.data.compress
    local compressed = compress('string', 'gzip', uncompressed, 9) as string
    --print('#compressed', #compressed)
    return compressed
end

function DiamonAndSquare_common:newCoroutine(): thread
    local coro = coroutine.create(function()
        local stop = false
        repeat
            self:square()
            -- Здесь отправлять данные на рисование промежуточного результата.
            coroutine.yield()
            stop = self:diamond()
            -- Здесь отправлять данные на рисование промежуточного результата.
        until stop
        self:normalizeInplace()
    end)
end

-- добавить анимацию процесса разбиения
function DiamonAndSquare:eval(): DiamonAndSquare
    ---------
    local ok: boolean
    ok = coroutine.resume(coro)
    while ok do
        ok = coroutine.resume(coro)
    end
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
    rng: DiamonAndSquare_common.RandomCallback
    pl: Pipeline
): DiamonAndSquare

    if type(mapn) ~= 'number' then
        error('No mapn parameter in constructor.')
    end
    local self: DiamonAndSquare
    self = setmetatable({} as DiamonAndSquare, DiamonAndSquare_mt)

    assert(pl, "pipeline is nil")
    self.pipeline = pl

    self.pipeline:pushCodeFromFileRoot(
        --'diamondsquare', 'diamondsquare-render.lua'
        'diamondsquare', 'rdr_diamondsquare.lua'
    )

    self.rng = rng
    self.mapn = mapn
    self:reset()

    return self
end

function DiamonAndSquare:reset()
    self.map = {}
    self.mapSize = math.ceil(2 ^ self.mapn) + 1 -- 1025

    self.chunkSize = self.mapSize - 1
    self.roughness = 2
    
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

        local value = self.rng:random()

        value = 0.5 - 0.5 * math.cos(value * math.pi)
        self.map[i] = self.map[i] or {}
        self.map[i][j] = value
    end
end

local floor = math.floor

function DiamonAndSquare:value(i: number, j: number): number
    if self.map[floor(i)] and self.map[floor(i)][floor(j)] then
        return self.map[floor(i)][floor(j)]
    end
end

function DiamonAndSquare:random(min: number, max: number): number
    --local r = 4*(math.random ()-0.5)^3 + 0.5
    local r = 4*(self.rng:random()-0.5)^3 + 0.5
--	https://www.desmos.com/calculator/toxjtsovev
    local result = min + r*(max-min)
    --print('DiamonAndSquare:random()', min, max, result)
    return result
end

function DiamonAndSquare:squareValue(i: number, j: number, _: number): number, number, number
    local value = 0.
    local n = 0
    local min, max: number, number
    
    local corners = {
        {i = i, j = j}, 
        {i = i + self.chunkSize, j = j}, 
        {i = i, j = j + self.chunkSize}, 
        {i = i + self.chunkSize, j = j + self.chunkSize}
    }

    --for _, corner in ipairs ({
        --{i=i, j=j}, 
        --{i=i+self.chunkSize, j=j}, 
        --{i=i, j=j+self.chunkSize}, 
        --{i=i+self.chunkSize, j=j+self.chunkSize}}
    --) do

    for _, corner in ipairs(corners) do
        local v = self:value(corner.i, corner.j)
        if v then
            --if min and (math.min(min, v) or v) then
            --min = min and (math.min(min, v) or v)
            --end
            min = min and math.min(min, v) or v
            max = max and math.max(max, v) or v
            value = value + v
            n = n + 1
        end
    end
    return value / n, min, max
end


function DiamonAndSquare:square()
    local half = math.floor(self.chunkSize / 2)
    for i = 1, self.mapSize - 1, self.chunkSize do
        for j = 1, self.mapSize - 1, self.chunkSize do
            local _, min, max = self:squareValue (i, j, half)
            self.map[i+half] = self.map[i+half] or {}
            self.map[i+half][j+half] = self:random(min, max)
        end
    end
end

function DiamonAndSquare:diamondValue(i: number, j: number, half: number): number, number, number
    local value = 0.
    local n = 0
    local min, max: number, number
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
            min = min and math.min (min, v) or v
            max = max and math.max (max, v) or v
            value = value + v
            n = n + 1
        end
    end
    return value / n, min, max
end

function DiamonAndSquare:diamond(): boolean
    local half = self.chunkSize/2
    local ceil = math.ceil

    for i = 1, self.mapSize, half do
--		for j = 1, map_size-1, chunk_size do
        for j = (i+half)%self.chunkSize, self.mapSize, self.chunkSize do
--			print ('i: '..i .. ' j:'.. j)
--			if (i + j)%half == 0 then
                local _, min, max = self:diamondValue(i, j, half)
                self.map[ceil(i)] = self.map[ceil(i)] or {}
                self.map[ceil(i)][ceil(j)] = self:random (min, max)
--			end
        end
    end
    
    self.chunkSize = ceil(self.chunkSize/2)
    self.roughness = ceil(self.roughness/2)
    return self.chunkSize <= 1
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

return DiamonAndSquare_common
