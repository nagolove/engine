-- vim: set colorcolumn=85
-- vim: fdm=marker

require 'love'

require 'camera_common'

local cam_common = require 'camera_common'
--local inspect = require 'inspect'
local Pipeline = require 'pipeline'
--local lj = love.joystick
--local Joystick = lj.Joystick
local sformat = string.format

-- TODO Диалог для настройки клавиш геймпада

--local joy_conf = require 'joy_conf'

-- TODO добавить инерцию к камере
local record Camera
    -- {{{
    --Локальная система координат - отображаемое окно, координаты курсора мыши.
    --Глобальная система координат - все игровое поле. Имеет свою точку (0, 0).

    new: function(pipeline: Pipeline, _screenW: number, _screenH: number): Camera

    -- Проверка ввода с геймпада.
    -- Обновить состояние.
    update: function(
        Camera,
        dt: number,         -- что за аргумент?
        dx: number,         -- что за аргумент?
        dy: number,         -- что за аргумент?
        dscale: number,     -- что за аргумент?
        px: number,         -- ??
        py: number          -- ??
    )

    reset: function(Camera)
    attach: function(Camera)
    detach: function(Camera)
    draw_bbox: function(Camera)

    -- Из оконных координаты в абсолютные.
    fromLocal: function(Camera, x: number, y: number): number, number
    fromLocal2: function(Camera, x: number, y: number): number, number
    -- Из абсолютных в оконные. 
    -- Что возвращать если точка лежит за пределами окна?
    --fromGlobal: function(Camera)

    -- Проверить, не выехал ли игрок за круг в локальной системе координат.
    -- Если выехал, то вернуть его обратно.
    checkIsPlayerInCircle: function(Camera)

    -- Передвинуть к текущему игроку.
    moveToPlayer: function(Camera, px: number, py: number)

    -- Сбросить смещение в начальное положение.
    setToOrigin: function(Camera)

    -- Разместить строку информациии в текстовом буфере lines_buf
    -- Секция должна быть октрыта.
    push2lines_buf: function(Camera)

    -- нарисовать оси координат, проходящие через центр экрана
    draw_axises: function(Camera)

    -- PRIVATE
    checkMovement: function(Camera, dx: number, dy: number)
    checkScale: function(Camera, dscale: number)

    free: boolean
    screenW: number
    screenH: number
    pipeline: Pipeline
    x: number
    y: number
    scale: number
    dt: number
    bbox_pix: BBox_pix
    bbox_rel: BBox_relative
    -- }}}
end

local Camera_mt: metatable<Camera> = {
    __index = Camera,
}

local cam_bbox = {
    w = 0.8,
    h = 0.8
}

function Camera.new(
    pipeline: Pipeline,
    _screenW: number,
    _screenH: number
): Camera

    local self: Camera = setmetatable({} as Camera, Camera_mt)
    self.screenW = _screenW
    self.screenH = _screenH
    self.x, self.y = 0, 0
    self.scale = 1.
    self.dt = 0
    self.pipeline = pipeline
    self.bbox_pix = cam_common.calc_bbox_pix(
        cam_bbox,
        self.screenW,
        self.screenH,
        self.x,
        self.y
    )
    self.free = false
    self.pipeline:pushCodeFromFileRoot('camera', "rdr_camera.lua")

    -- {{{
    self.pipeline:pushCode("camera_axises", [[
    local yield = coroutine.yield
    local linew = 1.
    local color = {0, 0, 0, 1}
    while true do
        local oldlw = love.graphics.getLineWidth()
        local w, h = love.graphics.getDimensions()
        love.graphics.setLineWidth(linew)
        love.graphics.setColor(color)
        love.graphics.line(w / 2, 0, w / 2, h)
        love.graphics.line(0, h / 2, w, h / 2)
        love.graphics.setLineWidth(oldlw)
        yield()
    end
    ]])
    -- }}}

    return self
end

function Camera:setTransform()
    --[[
    -- {{{
    self.pipeline:open('set_transform')
    self.pipeline:push(self.transform)
    self.pipeline:close()
    -- }}}
    --]]
end

function Camera:setOrigin()
    --self.pipeline:openAndClose('origin_transform')
end

function Camera:draw_axises()
    self.pipeline:openAndClose("camera_axises")
end

function Camera:push2lines_buf()
    -- {{{
    local msg = sformat(
        "camera: (%.3f, %.3f, %.4f)",
        self.x, self.y, self.scale
    )
    self.pipeline:push("add", "camera", msg)
    --local mat = {self.transform:getMatrix()}
    --local fmt1 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f,"
    --local fmt2 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f"
    --[[
    msg = sformat(
        "camera mat: (" .. fmt1 .. fmt2 .. ")",
        mat[1], mat[2], mat[3], mat[4], mat[5], mat[6], mat[7], mat[8],
        mat[9], mat[10], mat[11], mat[12], mat[13], mat[14], mat[15], mat[16]
    )
    --]]
    self.pipeline:push("add", "camera_mat", msg)
    -- }}}
end

function Camera:update(
    dt: number, 
    dx: number,         -- ось геймпада, перемещение камера
    dy: number,         -- ось геймпада, перемещение камеры
    dscale: number,     -- ось геймпада, масшраб камеры
    px: number,         -- положение игрока
    py: number
)

    -- {{{
    self:checkMovement(dx, dy)
    self:checkScale(dscale)

    self.dt = dt
    local cam_dx, cam_dy = 0., 0.
    local move = false

    if not self.free then
        if px < self.bbox_pix.x then
            cam_dx = self.bbox_pix.x - px
            move = true
        end
        local right = self.bbox_pix.x + self.bbox_pix.w
        if px > right then
            cam_dx = px - right
            move = true
        end

        if py < self.bbox_pix.y then
            cam_dy = self.bbox_pix.y - py
            move = true
        end
        local bottom = self.bbox_pix.y + self.bbox_pix.h
        if py > bottom then
            cam_dy = py - bottom
            move = true
        end
    end

    --print('px, py', px, py)

    --self.x = self.x + px
    --self.y = self.y + py
    if move then
        --self.x = self.x + px
        --self.y = self.y + py
        self.x = px
        self.y = py
    end
    --]]

    -- }}}
end

function Camera:reset()
    self.x, self.y, self.scale = 0., 0., 1.
end

function Camera:attach()
    self.pipeline:openPushAndClose(
        'camera', 'attach', self.x, self.y, self.scale
    )
end

function Camera:fromLocal2(x: number, y: number): number, number
    --local w, h = 1920, 1080
    --x, y = (x - w / 2) / self.scale, (y - h / 2) / self.scale
    --return self.x + x, self.y + y
	--local c,s = cos(self.rot), sin(self.rot)
    --local w, h = 1920, 1020
    local w, h = self.screenW, self.screenH
	x,y = x - self.x, y - self.y
	x,y = x - y, x + y
    local ox, oy = 0, 0
	return x*self.scale + w/2 + ox, y*self.scale + h/2 + oy
end

function Camera:fromLocal(x: number, y: number): number, number
    --local w, h = 1920, 1080
    local w, h = self.screenW, self.screenH
    x, y = (x - w / 2) / self.scale, (y - h / 2) / self.scale
    return self.x + x, self.y + y
end

function Camera:detach()
    --self.pipeline:openAndClose('origin_transform')
    self.pipeline:openPushAndClose('camera', 'detach')
end

function Camera:draw_bbox()
    self.pipeline:openPushAndClose('camera', 'draw_bbox')
end

function Camera:checkMovement(dx: number, dy: number)
    -- количество пикселей на которые передвигается камера
    local amount_x, amount_y = 1000 * self.dt, 1000 * self.dt
    local tx, ty = 0., 0.
    local changed = false

    -- проверка наклона стика геймпада
    if dx > 0 then
        changed = true
        tx = -amount_x
    elseif dx < 0 then
        changed = true
        tx = amount_x
    end

    -- проверка наклона стика геймпада
    if dy > 0 then
        changed = true
        ty = -amount_y
    elseif dy < 0 then
        changed = true
        ty = amount_y
    end

    if changed then
        self.x = self.x - tx
        self.y = self.y - ty
    end
end

-- как лучше учитывать положение джойстика что-бы не было рывков?
function Camera:checkScale(dscale: number)
    local factor = 1 * self.dt
    --local px, py = self.screenW * factor / 2, self.screenH * factor / 2

    --print("factor", factor)
    --print("self.scale", self.scale)

    if dscale == -1 then
        -- TODO добавить смещение по осям что-бы приближение и удаление 
        -- приходилось на центр экрана
        self.scale = 1 + factor
        --self.transform:scale(1 + factor, 1 + factor)
        --self.transform:scale(self.scale, self.scale)
        --self.transform:translate(-px, -py)
    elseif dscale == 1 then
        self.scale = 1 - factor
        --self.transform:scale(1 - factor, 1 - factor)
        --self.transform:scale(self.scale, self.scale)
        --self.transform:translate(px, py)
    end
    --]]
end

-- Проверяет, находится-ли центр танка игрока в пределах окружности 
-- определенного радиуса. Если танк выезжает за пределы, то камера сдвигается.
-- * Обеспечить плавность движения камеры.
-- * Камера должна сохранять какие-то абсолютные координаты?
function Camera:checkIsPlayerInCircle()
    --local rad = 300
end

-- камера перемещается на танк игрока
function Camera:moveTo(px: number, py: number)
    print("moveTo x, y", px, py)
    print("camera x, y, scale", self.x, self.y, self.scale)
    self.x, self.y = px, py
    --self.scale = 1.
    --[[
    local dx = self.x - px + self.screenW / 2
    local dy = self.y - py + self.screenH / 2
    self.x, self.y = self.x + dx, self.y + dy
    if self.x ~= dx or self.y ~= dy then
        --self.x, self.y = 0, 0
        self.transform:reset()
        self.transform:scale(self.scale)
        --self.transform:translate(-x, -y)
        self.transform:translate(dx, dy)
    end
    --]]
end

function Camera:setToOrigin()
    --[[
    self.x, self.y = 0, 0
    self.scale = 1,
    self.transform:translate(self.x, self.y)
    self.transform:reset()
    self.transform:scale(self.scale, self.scale)
    --]]
end

return Camera
