require "love"
require "camera"
require "keyconfig"

--local inspect = require "inspect"

function shallowCopy<T>(t: T): T
   local copy = {}
   for k, v in pairs(t as {any:any}) do
      copy[k] = v
   end
   return copy as T
end

local type anyFunc = function(any): any
function my_setfenv(f: anyFunc, env: {any: any}): anyFunc, string
    return load(string.dump(f), nil, nil, env)
end

function pointInRect(px: number, py: number, x: number, y: number, w: number, h: number): boolean
    return px > x and py > y and px < x + w and py < y + h
end

global type Scene = record
    init: function()
    quit: function()
    update: function(number|nil)
    draw: function()
    drawui: function()
    mousemoved: function(number, number, number, number)
    mousepressed: function(number, number, number)
    mousereleased: function(number, number, number)
    keypressed: function(string)
    keyreleased: function(string)
    wheelmoved: function(number, number)
    getCamera: function(): Camera
end

global type SceneMap = record
    scene: Scene
    name: string
    inited: boolean
end

global type Tool = record
    init: function(Scene)
    update: function()
    draw: function()
    keypressed: function(key: string)
    mousemoved: function(number, number, number, number)
    mousereleased: function(number, number, number)
    mousepressed: function(number, number, number)
end

local type CameraSettings = record
    dx: number
    dy: number
    relativedx: number
    relativedy: number
end

local cameraSettings: CameraSettings = {}

cameraSettings = {
    -- знавение в пикселях
    dx = 20,
    dy = 20,

    -- значение в пикселях сглаженное относительно значения scale камеры
    relativedx = 0,
    relativedy = 0,
}

function bindCameraControl(keyconfig: KeyConfig, cam: Camera)

    keyconfig.bindKeyDown("zoomout", {"z"}, function()
        print("zoout")
        cam:zoom(1.01)
    end, "zoom camera out")

    keyconfig.bindKeyDown("zoomin", {"x"}, function()
        cam:zoom(0.99)
    end, "zoom camera in")

    keyconfig.bindKeyDown("camleft", {"left"}, function()
        local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
        cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
        -- когда идет нажатие повлиять на цвет части текста
        cam:move(-reldx, 0)
    end, "move left")

    keyconfig.bindKeyDown("camright", {"right"}, function()
        local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
        cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
        cam:move(reldx, 0)
    end, "move right")

    keyconfig.bindKeyDown("camup", {"up"}, function()
        local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
        cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
        cam:move(0, -reldy)
    end, "move up")
    
    keyconfig.bindKeyDown("camdown", {"down"}, function()
        local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
        cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
        cam:move(0, reldy)
    end, "move down")

end

function safeSend(shader: love.graphics.Shader, name: string, ...: any)
  if shader:hasUniform(name) then
    shader:send(name, (... as table))
  end
end

function dist(x1: number, y1: number, x2: number, y2: number): number
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5 
end

function getQuad(axis_x: number,axis_y: number,vert_x: number,vert_y: number): number
    if vert_x < axis_x then
        if vert_y < axis_y then
            return 1
        else
            return 4
        end
    else
        if vert_y < axis_y then
            return 2
        else
            return 3
        end	
    end
end

function pointInPolygon(pgon: {number}, tx: number, ty: number): boolean
    if (#pgon < 6) then
        return false
    end

    local x1 = pgon[#pgon - 1]
    local y1 = pgon[#pgon]
    local cur_quad = getQuad(tx,ty,x1,y1)
    local next_quad: number
    local total = 0

    for i = 1,#pgon,2 do
        local x2 = pgon[i]
        local y2 = pgon[i+1]
        next_quad = getQuad(tx,ty,x2,y2)
        local diff = next_quad - cur_quad

        if (diff == 2) or (diff == -2) then
            if (x2 - (((y2 - ty) * (x1 - x2)) / (y1 - y2))) < tx then
                diff = -diff
            end
        elseif diff == 3 then
            diff = -1
        elseif diff == -3 then
            diff = 1
        end

        total = total + diff
        cur_quad = next_quad
        x1 = x2
        y1 = y2
    end

    return (math.abs(total)==4)
end
