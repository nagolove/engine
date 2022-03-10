-- vim: fdm=marker
-- vim: set colorcolumn=85

-- Based on darkfrei code(https://github.com/darkfrei/love2d-lua-tests/blob/main/diamond-square/main.lua)
-- License CC0 (Creative Commons license) (c) darkfrei, 2021
-- https://www.youtube.com/watch?v=4GuAV1PnurU

require 'love'
local Pipeline = require 'pipeline'

local record DiamonAndSquare

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
    rng: love.math.RandomGenerator

    -- PUBLIC
    new: function(
        mapn: integer, 
        rng: love.math.RandomGenerator,
        pl: Pipeline
    ): DiamonAndSquare

    -- основная функция - сознать карту высот
    eval: function(DiamonAndSquare): DiamonAndSquare
    -- сохранить в строку
    serialize: function(DiamonAndSquare): string
    -- сохранить в файл
    save: function(DiamonAndSquare, fname: string)
    -- загрузить из файла
    load: function(DiamonAndSquare, fname: string)

    -- PRIVATE
    random: function(DiamonAndSquare, min: number, max: number): number

    -- нормализовать значения высот к диапазону 0..1
    normalizeInplace: function(DiamonAndSquare)
    -- шаг алмаза
    diamond: function(DiamonAndSquare): boolean
    diamondValue: function(DiamonAndSquare, i: number, j: number, half: number): number, number, number
    -- шаг квадрат(?)
    square: function(DiamonAndSquare)
    squareValue: function(DiamonAndSquare, number, number, number): number, number, number
    value: function(DiamonAndSquare, number, number): number
end

local DiamonAndSquare_mt: metatable<DiamonAndSquare> = {
    __index = DiamonAndSquare,
}

local serpent = require 'serpent'

function DiamonAndSquare:load(fname: string)
    local data, size = love.filesystem.read(fname)
    if data then
        local f: DiamonAndSquare.State
        local ok, errmsg = pcall(function()
            f = load(data)() as DiamonAndSquare.State
        end) as (boolean, string)
        if not ok then
            local msg_part = fname .. ': ' .. errmsg
            print('Could not load DiamonAndSquare from ' .. msg_part)
        end
        self.mapSize = f.mapSize
        self.map = f.map
    else
        local msg_part = fname .. ': ' .. tostring(size)
        error('Could not load DiamonAndSquare from ' .. msg_part)
    end
end

function DiamonAndSquare:serialize(): string
    local state: DiamonAndSquare.State = {
        mapSize = self.mapSize,
        map = self.map,
    }
    return serpent.dump(state)
end

function DiamonAndSquare:save(fname: string)
    local succ, msg = love.filesystem.write(fname, self:serialize())
    if not succ then
        error('Could not save DiamonAndSquare to ' .. fname .. ': ' .. msg)
    end
end

-- добавить анимацию процесса разбиения
function DiamonAndSquare:eval(): DiamonAndSquare
    local coro = coroutine.create(function()
        local stop = false
        repeat
            self:square()
            coroutine.yield()
            stop = self:diamond()
        until stop
        self:normalizeInplace()
    end)
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
    rng: love.math.RandomGenerator,
    pl: Pipeline
): DiamonAndSquare

    if type(mapn) ~= 'number' then
        error('No mapn parameter in constructor.')
    end
    local self: DiamonAndSquare
    self = setmetatable({} as DiamonAndSquare, DiamonAndSquare_mt)

    assert(pl, "pipeline is nil")
    self.pipeline = pl
	self.map = {}
	self.mapSize = math.ceil(2 ^ mapn) + 1 -- 1025

	self.chunkSize = self.mapSize - 1
	self.roughness = 2
    self.rng = rng
	
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

		value = 0.5-0.5*math.cos(value*math.pi)
		self.map[i] = self.map[i] or {}
		self.map[i][j] = value
	end
	
    return self
end
--]]

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

return DiamonAndSquare
