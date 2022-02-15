-- vim: fdm=marker
-- vim: set colorcolumn=85

require 'love'

local RandomGenerator = love.math.RandomGenerator
local color = require 'height_map'.color

-- DSRender == DiamonAndSquareRender
global record DSRender

    scale: number
    maxcanvassize: integer
    square_width: integer
    mapn: integer
    map: {{number}}
    -- в пикселях
    width: integer
    -- в пикселях
    height: integer
    mapSize: integer
    --chunkSize: integer
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

--local serpent = require 'serpent'

function DSRender.new(square_width: integer): DSRender
    local self: DSRender
    self = setmetatable({} as DSRender, DSRender_mt)

	self.map = {}
    self.square_width = square_width

	--self.mapSize = math.ceil(2^mapn) + 1 -- 1025
    self.width = self.mapSize * self.square_width
    self.height = self.mapSize * self.square_width

    --local maxsize = love.graphics.getSystemLimits()['texturesize'] as number
    --print(inspect(love.

    self.maxcanvassize = defaultcanvasSize
    self.canvas = love.graphics.newCanvas(self.maxcanvassize, self.maxcanvassize)

    return self
end

function DSRender:draw2canvas()
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
function DSRender:present()
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

function DSRender:draw(x: integer, y: integer)
    x = x or 0
    y = y or 0

    --[[
	for i = 1, self.mapSize do
		for j = 1, self.mapSize do
			local c = self.map[i] and self.map[i][j] or nil
			if c then
				love.graphics.setColor(color(c^2))
                love.graphics.rectangle("fill", 
                    x + self.square_width * i, y + self.square_width * j, 
                    self.square_width, self.square_width
                )
				--if map_n < 5 then
					--if c < 0.75 then
						--love.graphics.setColor(1,1,1)
					--else
						--love.graphics.setColor(0,0,0)
					--end
					--love.graphics.print(tostring(math.floor(c*100)), rez*i, rez*j)
				--end
			end
		end
	end
    --]]
end

return DSRender
