-- vim: fdm=marker
-- vim: set colorcolumn=85

-- Based on darkfrei code.
-- License CC0 (Creative Commons license) (c) darkfrei, 2021
-- https://www.youtube.com/watch?v=4GuAV1PnurU

require 'love'

global record DiamonAndSquare

    scale: number
    maxcanvassize: integer
    rez: integer
    mapn: integer
    map: {{number}}
    width: integer
    height: integer
    mapSize: integer
    chunkSize: integer
    roughness: integer
    canvas: love.graphics.Canvas
    rng: love.math.RandomGenerator

    new: function(mapn: integer, rez: integer, rng: love.math.RandomGenerator): DiamonAndSquare

    random: function(DiamonAndSquare, min: number, max: number): number

    -- сохранить в файл
    save: function(DiamonAndSquare, fname: string)
    -- загрузить из файла
    load: function(DiamonAndSquare, fname: string)
    -- генерировать карту высот
    eval: function(DiamonAndSquare): DiamonAndSquare
    -- рисовать карту высот. Медленно
    draw: function(DiamonAndSquare, integer, integer)
    draw2canvas: function(DiamonAndSquare)
    -- рисовать карту высот в холст
    present: function(DiamonAndSquare)
    -- нормализовать значения высот к диапазону 0..1
    normalize: function(DiamonAndSquare)
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

local defaultcanvasSize = 4096

local serpent = require 'serpent'

function DiamonAndSquare:load(_: string)

end

function DiamonAndSquare:save(fname: string)
    local data = serpent.dump(self)
    love.filesystem.write(fname, data)
end

function DiamonAndSquare:eval(): DiamonAndSquare
    local coro = coroutine.create(function()
        local stop = false
        repeat
            self:square()
            coroutine.yield()
            stop = self:diamond()
        until stop
        self:normalize()
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

function DiamonAndSquare:normalize()
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

function DiamonAndSquare.new(mapn: integer, rez: integer, rng: love.math.RandomGenerator): DiamonAndSquare
    if type(mapn) ~= 'number' then
        error('No mapn parameter in constructor.')
    end
    local self: DiamonAndSquare
    self = setmetatable({} as DiamonAndSquare, DiamonAndSquare_mt)

	self.map = {}
    self.rez = rez
	self.mapSize = math.ceil(2^mapn) + 1 -- 1025
    self.width = self.mapSize * self.rez
    self.height = self.mapSize * self.rez
    --local maxsize = love.graphics.getSystemLimits()['texturesize'] as number
    --print(inspect(love.
    self.maxcanvassize = defaultcanvasSize
    self.canvas = love.graphics.newCanvas(self.maxcanvassize, self.maxcanvassize)
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

		--local value = math.random()
		local value = self.rng:random()

		value = 0.5-0.5*math.cos(value*math.pi)
		self.map[i] = self.map[i] or {}
		self.map[i][j] = value
	end
	
    return self
end

local colors = {
    {24/255, 81/255, 129/255}, -- very deep sea
    {32/255, 97/255, 157/255}, -- deep sea
    {35/255, 113/255, 179/255}, -- sea
    {40/255, 128/255, 206/255}, -- shallow sea
    {60/255, 130/255, 70/255}, -- very dark green
    {72/255, 149/255, 81/255}, -- dark green
    {88/255, 164/255, 97/255}, -- green
    {110/255, 176/255, 120/255}, -- light green
    {84/255, 69/255, 52/255}, -- very dark brown
    {102/255, 85/255, 66/255}, -- dark brown
    {120/255, 100/255, 73/255}, -- brown
    {140/255, 117/255, 86/255}, -- light brown
    {207/255, 207/255, 207/255}, -- very dark white
    {223/255, 223/255, 223/255}, -- dark white
    {239/255, 239/255, 239/255}, -- white
    {255/255, 255/255, 255/255}, -- light white
}

local function interpolate_color(a: {number}, b: {number}, t: number): {number}
    local c = {}
    for i = 1, #a do
        c[i] = a[i] + t*(b[i]-a[i])
    end
    return c
end

local function color(value: number): {number}
    local n = #colors + 2
    
    if value <= 1/n then
        return colors[1]
    end

    for i = 2, #colors do
        if value <= i/n then
            local t = (value-((i-1)/n))/(1/n)
            return interpolate_color (colors[i-1], colors[i], t)
        end
    end

    -- more than last
    return colors[#colors]
end

function DiamonAndSquare:value(i: number, j: number): number
    local floor = math.floor
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
	for _, corner in ipairs ({{i=i, j=j}, {i=i+self.chunkSize, j=j}, {i=i, j=j+self.chunkSize}, {i=i+self.chunkSize, j=j+self.chunkSize}}) do
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
	return value/n, min, max
end


function DiamonAndSquare:square()
	local half = math.floor(self.chunkSize/2)
	for i = 1, self.mapSize-1, self.chunkSize do
		for j = 1, self.mapSize-1, self.chunkSize do
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
	for _, corner in ipairs({{i=i, j=j-half}, {i=i+half, j=j}, {i=i, j=j+half}, {i=i-half, j=j}}) do
		local v = self:value (corner.i, corner.j)
		if v then
			min = min and math.min (min, v) or v
			max = max and math.max (max, v) or v
			value = value + v
			n = n + 1
		end
	end
	return value/n, min, max
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
local buffer: number
local function update(dt: number)
	if not pause then
		buffer = buffer or 0
		if buffer > 0.1 then
			buffer = buffer - 0.1
		else
			buffer = buffer + dt
			return
		end
		--update[state]()
	end
end
--]]

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

function DiamonAndSquare:draw2canvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.push()
    -- как установить масштаб что-бы весь ландшафт умещался на холсте?
    local sx = self.maxcanvassize / self.width
    --print('sx', sx)
    love.graphics.scale(sx, sx)
    self.scale = sx
    self:draw(0, 0)
    love.graphics.pop()
    love.graphics.setCanvas()
end

-- рисовать на внутренний канвас
function DiamonAndSquare:present()
    love.graphics.setColor{1, 1, 1, 1}
    --local dx, dy = - self.width / 2, - self.height / 2
    --local w, h = self.canvas:getDimensions()
    local dx, dy = - self.width / 2, - self.height / 2
    --print('diamondSquare.width, diamondSquare.height', diamondSquare.width, diamondSquare.height)
    local Canvas = love.graphics.Drawable 
    --print('self.scale', self.scale)
    local scale = 1 / self.scale
    love.graphics.draw(self.canvas as Canvas, dx, dy, 0., scale, scale)
end

function DiamonAndSquare:draw(x: integer, y: integer)
    x = x or 0
    y = y or 0

	for i = 1, self.mapSize do
		for j = 1, self.mapSize do
			local c = self.map[i] and self.map[i][j] or nil
			if c then
				love.graphics.setColor(color(c^2))
                love.graphics.rectangle("fill", x + self.rez*i, y + self.rez*j, self.rez, self.rez)
                --[[
				if map_n < 5 then
					if c < 0.75 then
						love.graphics.setColor(1,1,1)
					else
						love.graphics.setColor(0,0,0)
					end
					love.graphics.print(tostring(math.floor(c*100)), rez*i, rez*j)
				end
                --]]

			end
		end
	end
end

return DiamonAndSquare
