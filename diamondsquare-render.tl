-- vim: fdm=marker
-- vim: set colorcolumn=85

require 'love'

local RandomGenerator = love.math.RandomGenerator
local color = require 'height_map'.color

-- DSRender == DiamonAndSquareRender
global record DSRender

    scale: number
    maxcanvassize: integer
    rez: integer
    mapn: integer
    map: {{number}}
    -- в пикселях
    width: integer
    -- в пикселях
    height: integer
    mapSize: integer
    chunkSize: integer
    canvas: love.graphics.Canvas

    new: function(mapn: integer, rez: integer, rng: RandomGenerator): DSRender

    -- рисовать карту высот. Медленно
    draw: function(DSRender, integer, integer)
    draw2canvas: function(DSRender)
    -- рисовать карту высот в холст
    present: function(DSRender)
end

local DSRender_mt: metatable<DSRender> = {
    __index = DSRender,
}

--local defaultcanvasSize = 4096
local defaultcanvasSize = 4096 * 2

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

		local value = self.rng:random()

		value = 0.5-0.5*math.cos(value*math.pi)
		self.map[i] = self.map[i] or {}
		self.map[i][j] = value
	end
	
    return self
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
    --love.graphics.setLineWidth(4)
    --love.graphics.setColor{0, 0.5, 0, 1}
    --love.graphics.line(0, 0, 4096, 4096)
    --love.graphics.setLineWidth(4)
    --love.graphics.setColor{1, 0.0, 0, 1}
    --love.graphics.line(0, 0, -4096, 4096)
    --love.graphics.setColor{1, 1, 1, 1}

    --local dx, dy = - self.width / 2, - self.height / 2
    --local w, h = self.canvas:getDimensions()
    --local dx, dy = - self.width / 2, - self.height / 2
    local dx, dy = 0, 0
    --print('diamondSquare.width, diamondSquare.height', diamondSquare.width, diamondSquare.height)
    local Canvas = love.graphics.Drawable 
    --print('self.scale', self.scale)
    local scale = 1 / self.scale
    --print('scale', scale)
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

			end
		end
	end
end

return DiamonAndSquare

--]]
