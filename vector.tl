--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local assert = assert
local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

global type vector = record
    x: number
    y: number
    --metamethod __tostring: function(vector): string
    metamethod __div: function(a: vector,b: number): vector
    metamethod __mul: function(a: vector|number,b: vector|number): vector|number
    -- XXX any hack
    metamethod __add: function(a: vector,b: any): vector
    metamethod __sub: function(a: vector,b: any): vector
    metamethod __call : function(_: vector, x:number, y:number): vector

    isvector: function(vector): boolean
    clone: function(): vector
    unpack: function(): number, number
    --metamethod __tostring: function(): string
    metamethod __unm: function(a: vector): vector
    metamethod __eq: function(a: vector,b: vector): boolean
    metamethod __lt: function(a: vector,b: vector): boolean
    metamethod __le: function(a: vector,b: vector): boolean
    permul: function(a: vector,b: vector): vector
    len2: function(): number
    len: function(): number
    toPolar: function(): number, number
    dist: function(a: vector, b: vector): number
    dist2: function(a: vector, b: vector): number
    normalizeInplace: function(): vector
    normalized: function(): vector
    rotateInplace: function(phi: number): vector
    rotated: function(phi: number): vector
    perpendicular: function(): vector
    projectOn: function(v: vector): vector
    mirrorOn: function(v: vector): vector
    cross: function(v: vector): number
    trimInplace: function(maxLen: number): vector
    angleTo: function(other: vector): number
    trimmed: function(maxLen: number): vector
    __index: metatable<vector>
end

local function new(x: number,y: number): vector
    vector.__index = vector as metatable<vector>
    return setmetatable({x = x or 0, y = y or 0} as vector, vector as metatable<vector>)
end
local zero = new(0,0)

function vector:len(): number
    return sqrt(self.x * self.x + self.y * self.y)
end

function vector:toPolar(): number, number
    return atan2(self.x, self.y), self:len()
end

local function fromPolar(angle: number, radius: number): vector
    radius = radius or 1
    return new(cos(angle) * radius, sin(angle) * radius)
end

local function randomDirection(len_min: number, len_max: number): vector
    len_min = len_min or 1
    len_max = len_max or len_min

    assert(len_max > 0, "len_max must be greater than zero")
    assert(len_max >= len_min, "len_max must be greater than or equal to len_min")
    
    return fromPolar(math.random() * 2*math.pi,
                     math.random() * (len_max-len_min) + len_min)
end

local function isvector(v: vector): boolean
    return type(v) == 'table' and type(v.x) == 'number' and type(v.y) == 'number'
end

function vector.isvector(v: vector): boolean
    return type(v) == 'table' and type(v.x) == 'number' and type(v.y) == 'number'
end

function vector:clone(): vector
    return new(self.x, self.y)
end

function vector:unpack(): number, number
    return self.x, self.y
end

function vector:__tostring(): string
    return "("..tonumber(self.x)..","..tonumber(self.y)..")"
end

function vector.__call(_: vector, x:number, y:number): vector
    return new(x, y)
end

function vector.__unm(a: vector): vector
    return new(-a.x, -a.y)
end

function vector.__add(a: vector,b: any): vector
    local c = b as vector
    assert(isvector(a) and isvector(c), "Add: wrong argument types (<vector> expected)")
    return new(a.x+c.x, a.y+c.y)
end

function vector.__sub(a: vector,b: any): vector
    local c = b as vector
    assert(isvector(a) and isvector(c), "Sub: wrong argument types (<vector> expected)")
    return new(a.x-c.x, a.y-c.y)
end

function vector.__mul(a: vector|number,b: vector|number): vector|number
    if type(a) == "number" then
        return new(a as number *(b as vector).x, a as number *(b as vector).y)
    elseif type(b) == "number" then
        return new(b as number * (a as vector).x, b as number *(a as vector).y)
    else
        assert(isvector(a as vector) and isvector(b as vector), "Mul: wrong argument types (<vector> or <number> expected)")
        return (a as vector).x*(b as vector).x + (a as vector).y*(b as vector).y
    end
end

function vector.__div(a: vector,b: number): vector
    assert(isvector(a) and type(b) == "number", "wrong argument types (expected <vector> / <number>)")
    return new(a.x / b, a.y / b)
end

function vector.__eq(a: vector,b: vector): boolean
    return a.x == b.x and a.y == b.y
end

function vector.__lt(a: vector,b: vector): boolean
    return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vector.__le(a: vector,b: vector): boolean
    return a.x <= b.x and a.y <= b.y
end

function vector.permul(a: vector,b: vector): vector
    assert(isvector(a) and isvector(b), "permul: wrong argument types (<vector> expected)")
    return new(a.x*b.x, a.y*b.y)
end

function vector:len2(): number
    return self.x * self.x + self.y * self.y
end

function vector.dist(a: vector, b: vector): number
    assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
    local dx = a.x - b.x
    local dy = a.y - b.y
    return sqrt(dx * dx + dy * dy)
end

function vector.dist2(a: vector, b: vector): number
    assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
    local dx = a.x - b.x
    local dy = a.y - b.y
    return (dx * dx + dy * dy)
end

function vector:normalizeInplace(): vector
    local l = self:len()
    if l > 0 then
        self.x, self.y = self.x / l, self.y / l
    end
    return self
end

function vector:normalized(): vector
    return self:clone():normalizeInplace()
end

function vector:rotateInplace(phi: number): vector
    local c, s = cos(phi), sin(phi)
    self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
    return self
end

function vector:rotated(phi: number): vector
    local c, s = cos(phi), sin(phi)
    return new(c * self.x - s * self.y, s * self.x + c * self.y)
end

function vector:perpendicular(): vector
    return new(-self.y, self.x)
end

function vector:projectOn(v: vector): vector
    assert(isvector(v), "invalid argument: cannot project vector on " .. type(v))
    -- (self * v) * v / v:len2()
    local s = (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
    return new(s * v.x, s * v.y)
end

function vector:mirrorOn(v: vector): vector
    assert(isvector(v), "invalid argument: cannot mirror vector on " .. type(v))
    -- 2 * self:projectOn(v) - self
    local s = 2 * (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
    return new(s * v.x - self.x, s * v.y - self.y)
end

function vector:cross(v: vector): number
    assert(isvector(v), "cross: wrong argument types (<vector> expected)")
    return self.x * v.y - self.y * v.x
end

-- ref.: http://blog.signalsondisplay.com/?p=336
function vector:trimInplace(maxLen: number): vector
    local s = maxLen * maxLen / self:len2()
    s = (s > 1 and 1) or math.sqrt(s)
    self.x, self.y = self.x * s, self.y * s
    return self
end

function vector:angleTo(other: vector): number
    if other then
        return atan2(self.y, self.x) - atan2(other.y, other.x)
    end
    return atan2(self.y, self.x)
end

function vector:trimmed(maxLen: number): vector
    return self:clone():trimInplace(maxLen)
end

global record VecModule
    new  : function(number, number): vector
    fromPolar       : function(number, number): vector
    randomDirection : function(number, number): vector
    isvector        : function(vector): boolean
    zero            : function(): vector
    metamethod __call : function(_: VecModule, x:number, y:number): vector
end

local Module_mt: metatable<VecModule>

Module_mt = {
    __call = function(_: VecModule, x:number, y:number): vector
    --__call = function(x:number): vector
        return new(x, y)
    end
}

global type Vec = record

end

-- the module
return setmetatable({
    new             = new,
    fromPolar       = fromPolar,
    randomDirection = randomDirection,
    isvector        = isvector,
    zero            = zero
} as VecModule, Module_mt)
