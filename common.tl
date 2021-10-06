-- vim: fdm=marker
-- vim: set colorcolumn=85

require "love"
require "camera"

-- Однопоточная или мультипоточная схема. 
-- По-умолчанию используется однопоточная схема.
global enum SceneType
    "single"
    "multi"
end

global type Scene = record
    -- {{{
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
    getSceneType: function(): SceneType
    -- }}}
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

-- Обрезать пробелы с друх сторон строки.
-- from http://lua-users.org/wiki/StringTrim
function trim(s: string): string
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Напечатать строку выделенным цветом в консоль.
function colprint(str: string)
    if type(str) ~= 'string' then
        error(string.format('Runtime type mismatch. %s instead of string', type(str)))
    end
    local ansicolors = require "ansicolors2".ansicolors
    print(ansicolors("%{blue cyanbg}" .. string.rep('>', 10) .. str))
end

-- Вспомогательная функция для imgui списков. Из массива строк делает строку
-- разделенную нулевыми байтами.
function separateByZeros(arr: {string}): string, integer
    local tmp = ""
    for _, v in ipairs(arr) do
        tmp = tmp .. v .. "\0"
    end
    return tmp, #arr
end

-- Вернуть копию по значению. Копируется только один уровень таблицы.
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
-- Вернуть копию по значению. Рекурсивно копируются подтаблицы.
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
-- Установить среду для функции?
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

-- Что делает эта функция?
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

-- Находится-ли точка внутри выпуклого полигона. Полигон задается массивом
-- вершин { x1, y1, x2, y2 ... }
function pointInPolygon(pgon: {number}, tx: number, ty: number): boolean
    -- {{{
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
    -- }}}
end

local u8 = require "utf8"

-- Добавляет в текстовый объект цветной текст линейно интерполируя цвета от 
-- fromcolor до tocolor для каждого символа.
-- Возвращает индекс для textobj:getWidth() или textobj:getHeight()

--[[
function makeDescentColorText(
    textobj: love.graphics.Text,
    textstr: string,
    fromcolor: {number}, tocolor: {number},
    ...: any
): number
--]]
function makeDescentColorText(
    textobj: love.graphics.Text,
    textstr: string,
    fromcolor: {number}, tocolor: {number},
    x: number, y: number, angle: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky: number
): number

    assert(textobj, "textobj should not be nil")
    assert(type(textstr) == "string", "textstr should be a string, not " .. type(textstr))
    assert(type(fromcolor) == "table", "fromcolor should be a table, not " .. type(fromcolor))
    assert(type(tocolor) == "table", "tocolor should be a table, not " .. type(tocolor))
    assert(#fromcolor == 4, "fromcolor should have 4 components")
    assert(#tocolor == 4, "tocolor should have 4 components")

    --[[
    print("textobj", textobj)
    print("textstr", textstr)
    print("fromcolor", inspect(fromcolor))
    print("tocolor", inspect(tocolor))
    --]]

    local slen = u8.len(textstr)
    print("slen", slen)

    local r, g, b, a = fromcolor[1], fromcolor[2], fromcolor[3], fromcolor[4]

    -- Приращение цвета
    local d_r = (tocolor[1] - fromcolor[1]) / slen
    local d_g = (tocolor[2] - fromcolor[2]) / slen
    local d_b = (tocolor[3] - fromcolor[3]) / slen
    local d_a = (tocolor[4] - fromcolor[4]) / slen

    print("d_r", d_r)
    print("d_g", d_g)
    print("d_b", d_b)
    print("d_a", d_a)

    --[[
    Рассчитать цвет для приращения к начальному исходя из разницы цветов и 
    количества символов в стрке
    --]]

    local coloredtext = {}
    for _, codepoint in u8.codes(textstr) do
        local char = u8.char(codepoint as integer)
        --print("p, c, char", p, c, u8.char(c))
        table.insert(coloredtext, { r, g, b, a})
        table.insert(coloredtext, char as {number})
        r = r + d_r
        g = g + d_g
        b = b + d_b
        a = a + d_a
    end
    return textobj:add(coloredtext, x, y, angle, sx, sy, ox, oy, kx, ky)
    --return textobj:add(coloredtext, unpack(args))
end

local function mesh2str(mesh: love.graphics.Mesh, i: integer): string
     local x, y, u, v, r, g, b, a = mesh:getVertex(i)
     return 
        "[" .. tostring(i) .. "] " ..  
        x .. " " .. y .. " " .. 
        u .. " " .. v .. " " ..  
        r .. " " .. g .. " " ..  
        b .. " " .. a .. "\n"
end

function printMesh(mesh: love.graphics.Mesh)
    if mesh then
        for i = 1, mesh:getVertexCount() do
            --local x, y, u, v, r, g, b, a = mesh:getVertex(i)
            --print("[" .. tostring(i) .. "] x, y, u, v, r, g, b, a", x, y, u, v, r, g, b, a)
            print(mesh2str(mesh, math.ceil(i)))
        end
    end
end

function printMesh2file(mesh: love.graphics.Mesh, fname: string)
    if mesh then
        for i = 1, mesh:getVertexCount() do
            --local x, y, u, v, r, g, b, a = mesh:getVertex(i)
            --local s = "[" .. tostring(i) .. "] " .. 
                --x .. " " .. y .. " " .. 
                --u .. " " .. v .. " " .. 
                --r .. " " .. g .. " " ..
                --b .. " " .. a .. "\n"
            love.filesystem.append(fname, mesh2str(mesh, math.ceil(i)))
        end
    end
end

local function reversedipairsiter<T>(t: {T}, i: integer): integer, T
    i = i - 1
    if i ~= 0 then
        return i, t[i]
    end
end

local type Iter = function<T>(t: {T}, integer): integer, T

function ripairs<T>(t: {T}): Iter<T>, {T}, integer
    --return reversedipairsiter, t, #t + 1
    return reversedipairsiter, t, #t + 1
end

function testflag(set: number, flag: number): boolean
  return set % (2*flag) >= flag
end

function setflag(set: number, flag: number): number
  if set % (2*flag) >= flag then
    return set
  end
  return set + flag
end

function clear(set: number, flag: number): number
  if set % (2*flag) >= flag then
    return set - flag
  end
  return set
end

function tobitstr(num: number, bits: number): string
    -- returns a table of bits, most significant first.
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {} -- will contain the bits        
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[math.ceil(b)]) / 2)
    end
    return table.concat(t as {string})
end

function tobits(num: number, bits: number): {number}
    -- returns a table of bits, most significant first.
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {} -- will contain the bits        
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[math.ceil(b)]) / 2)
    end
    return t
end

