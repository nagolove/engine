require "love"
require "camera"

global type Scene = record
    init: function()
    quit: function()
    update: function(number|nil)
    draw: function()
    drawui: function()
    mousemoved: function(number, number, number, number)
    mousepressed: function(number, number, number)
    mousereleased: function(number, number, number)
    textinput: function(text: string)
    resize: function(neww: integer, newh: integer)
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

function colprint(str: string)
    if type(str) ~= 'string' then
        error(string.format('Runtime type mismatch. %s instead of string', type(str)))
    end
    local ansicolors = require "ansicolors2".ansicolors
    print(ansicolors("%{blue cyanbg}" .. string.rep('>', 10) .. str))
end

--local inspect = require "inspect"
function separateByZeros(arr: {string}): string, integer
    local tmp = ""
    for _, v in ipairs(arr) do
        tmp = tmp .. v .. "\0"
    end
    return tmp, #arr
end

function shallowCopy<T>(t: T): T
    if type(t) == "table" then 
        local copy = {}
        for k, v in pairs(t as {any:any}) do
            copy[k] = v
        end
        return copy as T
    elseif type(t) == "string" then
        return t
    elseif type(t) == "number" then
        return t
    elseif type(t) == "boolean" then
        return t
    elseif type(t) == "function" then
        return t
    end
end

-- source http://lua-users.org/wiki/CopyTable 
function deepCopy<T>(orig: T): T
    local orig_type = type(orig)
    if orig_type == 'table' then
        local copy = {}
        copy = {}
        for orig_key, orig_value in pairs(orig as {any:any}) do
            copy[deepCopy(orig_key as T)] = deepCopy(orig_value as T)
        end
        --setmetatable(copy as T, deepCopy(getmetatable(orig) as T))
        setmetatable(copy as T, deepCopy(getmetatable(orig) as T) as metatable<T>)
        return copy as T
    else 
        return orig
    end
end


local type anyFunc = function(any): any
function my_setfenv(f: anyFunc, env: {any: any}): anyFunc, string
    return load(string.dump(f), nil, nil, env)
end

function pointInRect(px: number, py: number, x: number, y: number, w: number, h: number): boolean
    return px > x and py > y and px < x + w and py < y + h
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
    local total = 0.0

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
