local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local table = _tl_compat and _tl_compat.table or table;  Easing = {}

 Tween_ = {}









local tween = {
   _VERSION = 'tween 2.0.0',
   _DESCRIPTION = 'tweening for lua',
   _URL = 'https://github.com/kikito/tween.lua',
   _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2014 Enrique García Cota, Yuichi Tateno, Emmanuel Oga

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]],
}










local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin


local function linear(t, b, c, d)
   return c * t / d + b
end


local function inQuad(t, b, c, d)
   return c * pow(t / d, 2) + b
end

local function outQuad(t, b, c, d)
   t = t / d
   return -c * t * (t - 2) + b
end

local function inOutQuad(t, b, c, d)
   t = t / d * 2
   if t < 1 then return c / 2 * pow(t, 2) + b end
   return -c / 2 * ((t - 1) * (t - 3) - 1) + b
end

local function outInQuad(t, b, c, d)
   if t < d / 2 then return outQuad(t * 2, b, c / 2, d) end
   return inQuad((t * 2) - d, b + c / 2, c / 2, d)
end


local function inCubic(t, b, c, d)
   return c * pow(t / d, 3) + b
end

local function outCubic(t, b, c, d)
   return c * (pow(t / d - 1, 3) + 1) + b
end

local function inOutCubic(t, b, c, d)
   t = t / d * 2
   if t < 1 then return c / 2 * t * t * t + b end
   t = t - 2
   return c / 2 * (t * t * t + 2) + b
end

local function outInCubic(t, b, c, d)
   if t < d / 2 then return outCubic(t * 2, b, c / 2, d) end
   return inCubic((t * 2) - d, b + c / 2, c / 2, d)
end


local function inQuart(t, b, c, d)
   return c * pow(t / d, 4) + b
end

local function outQuart(t, b, c, d)
   return -c * (pow(t / d - 1, 4) - 1) + b
end

local function inOutQuart(t, b, c, d)
   t = t / d * 2
   if t < 1 then return c / 2 * pow(t, 4) + b end
   return -c / 2 * (pow(t - 2, 4) - 2) + b
end

local function outInQuart(t, b, c, d)
   if t < d / 2 then return outQuart(t * 2, b, c / 2, d) end
   return inQuart((t * 2) - d, b + c / 2, c / 2, d)
end


local function inQuint(t, b, c, d)
   return c * pow(t / d, 5) + b
end

local function outQuint(t, b, c, d)
   return c * (pow(t / d - 1, 5) + 1) + b
end

local function inOutQuint(t, b, c, d)
   t = t / d * 2
   if t < 1 then return c / 2 * pow(t, 5) + b end
   return c / 2 * (pow(t - 2, 5) + 2) + b
end
local function outInQuint(t, b, c, d)
   if t < d / 2 then return outQuint(t * 2, b, c / 2, d) end
   return inQuint((t * 2) - d, b + c / 2, c / 2, d)
end


local function inSine(t, b, c, d)
   return -c * cos(t / d * (pi / 2)) + c + b
end

local function outSine(t, b, c, d)
   return c * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, c, d)
   return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outInSine(t, b, c, d)
   if t < d / 2 then return outSine(t * 2, b, c / 2, d) end
   return inSine((t * 2) - d, b + c / 2, c / 2, d)
end


local function inExpo(t, b, c, d)
   if t == 0 then return b end
   return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end
local function outExpo(t, b, c, d)
   if t == d then return b + c end
   return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end
local function inOutExpo(t, b, c, d)
   if t == 0 then return b end
   if t == d then return b + c end
   t = t / d * 2
   if t < 1 then return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005 end
   return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end
local function outInExpo(t, b, c, d)
   if t < d / 2 then
      return outExpo(t * 2, b, c / 2, d)
   end
   return inExpo((t * 2) - d, b + c / 2, c / 2, d)
end


local function inCirc(t, b, c, d)
   return (-c * (sqrt(1 - pow(t / d, 2)) - 1) + b)
end

local function outCirc(t, b, c, d)
   return (c * sqrt(1 - pow(t / d - 1, 2)) + b)
end

local function inOutCirc(t, b, c, d)
   t = t / d * 2
   if t < 1 then return -c / 2 * (sqrt(1 - t * t) - 1) + b end
   t = t - 2
   return c / 2 * (sqrt(1 - t * t) + 1) + b
end

local function outInCirc(t, b, c, d)
   if t < d / 2 then return outCirc(t * 2, b, c / 2, d) end
   return inCirc((t * 2) - d, b + c / 2, c / 2, d)
end


local function calculatePAS(p, a, c, d)
   p, a = p or d * 0.3, a or 0
   if a < abs(c) then
      return p, c, p / 4
   end
   return p, a, p / (2 * pi) * asin(c / a)
end

local function inElastic(t, b, c, d, a, p)
   local s
   if t == 0 then return b end
   t = t / d
   if t == 1 then return b + c end
   p, a, s = calculatePAS(p, a, c, d)
   t = t - 1
   return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

local function outElastic(t, b, c, d, a, p)
   local s
   if t == 0 then return b end
   t = t / d
   if t == 1 then return b + c end
   p, a, s = calculatePAS(p, a, c, d)
   return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

local function inOutElastic(t, b, c, d, a, p)
   local s
   if t == 0 then return b end
   t = t / d * 2
   if t == 2 then return b + c end
   p, a, s = calculatePAS(p, a, c, d)
   t = t - 1
   if t < 0 then return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b end
   return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) * 0.5 + c + b
end

local function outInElastic(t, b, c, d, a, p)
   if t < d / 2 then return outElastic(t * 2, b, c / 2, d, a, p) end
   return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
end


local function inBack(t, b, c, d, s)
   s = s or 1.70158
   t = t / d
   return c * t * t * ((s + 1) * t - s) + b
end

local function outBack(t, b, c, d, s)
   s = s or 1.70158
   t = t / d - 1
   return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutBack(t, b, c, d, s)
   s = (s or 1.70158) * 1.525
   t = t / d * 2
   if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
   t = t - 2
   return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
end

local function outInBack(t, b, c, d, s)
   if t < d / 2 then return outBack(t * 2, b, c / 2, d, s) end
   return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
end


local function outBounce(t, b, c, d)
   t = t / d
   if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
   if t < 2 / 2.75 then
      t = t - (1.5 / 2.75)
      return c * (7.5625 * t * t + 0.75) + b
   elseif t < 2.5 / 2.75 then
      t = t - (2.25 / 2.75)
      return c * (7.5625 * t * t + 0.9375) + b
   end
   t = t - (2.625 / 2.75)
   return c * (7.5625 * t * t + 0.984375) + b
end
local function inBounce(t, b, c, d)
   return c - outBounce(d - t, 0, c, d) + b
end

local function inOutBounce(t, b, c, d)
   if t < d / 2 then return inBounce(t * 2, 0, c, d) * 0.5 + b end
   return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
end

local function outInBounce(t, b, c, d)
   if t < d / 2 then return outBounce(t * 2, b, c / 2, d) end
   return inBounce((t * 2) - d, b + c / 2, c / 2, d)
end

tween.easing = {
   linear = linear,
   inQuad = inQuad, outQuad = outQuad, inOutQuad = inOutQuad, outInQuad = outInQuad,
   inCubic = inCubic, outCubic = outCubic, inOutCubic = inOutCubic, outInCubic = outInCubic,
   inQuart = inQuart, outQuart = outQuart, inOutQuart = inOutQuart, outInQuart = outInQuart,
   inQuint = inQuint, outQuint = outQuint, inOutQuint = inOutQuint, outInQuint = outInQuint,
   inSine = inSine, outSine = outSine, inOutSine = inOutSine, outInSine = outInSine,
   inExpo = inExpo, outExpo = outExpo, inOutExpo = inOutExpo, outInExpo = outInExpo,
   inCirc = inCirc, outCirc = outCirc, inOutCirc = inOutCirc, outInCirc = outInCirc,
   inElastic = inElastic,
   outElastic = outElastic,
   inOutElastic = inOutElastic,
   outInElastic = outInElastic,
   inBack = inBack,
   outBack = outBack,
   inOutBack = inOutBack,
   outInBack = outInBack,
   inBounce = inBounce, outBounce = outBounce, inOutBounce = inOutBounce, outInBounce = outInBounce,
}





local function copyTables(destination, keysTable, valuesTable)
   valuesTable = valuesTable or keysTable
   local mt = getmetatable(keysTable)
   if mt and getmetatable(destination) == nil then
      setmetatable(destination, mt)
   end
   for k, v in pairs(keysTable) do
      if type(v) == 'table' then
         (destination)[k] = copyTables({}, v, (valuesTable)[k])
      else
         (destination)[k] = (valuesTable)[k]
      end
   end
   return destination
end

local function checkSubjectAndTargetRecursively(subject, target, path)
   path = path or {}
   local targetType
   local newPath
   for k, targetValue in pairs(target) do
      targetType, newPath = type(targetValue), copyTables({}, path)
      table.insert(newPath, tostring(k))
      if targetType == 'number' then
         assert(type(subject[k]) == 'number', "Parameter '" .. table.concat(newPath, '/') .. "' is missing from subject or isn't a number")
      elseif targetType == 'table' then
         checkSubjectAndTargetRecursively((subject)[k], targetValue, newPath)
      else
         assert(targetType == 'number', "Parameter '" .. table.concat(newPath, '/') .. "' must be a number or table of numbers")
      end
   end
end

local function checkNewParams(duration, subject, target, easing)
   assert(type(duration) == 'number' and duration > 0, "duration must be a positive number. Was " .. tostring(duration))
   local tsubject = type(subject)
   assert(tsubject == 'table' or tsubject == 'userdata', "subject must be a table or userdata. Was " .. tostring(subject))
   assert(type(target) == 'table', "target must be a table. Was " .. tostring(target))
   assert(type(easing) == 'function', "easing must be a function. Was " .. tostring(easing))
   checkSubjectAndTargetRecursively(subject, target)
end

local function getEasingFunction(easing)
   local result
   easing = easing or "linear"
   if type(easing) == 'string' then
      local name = easing
      result = tween.easing[name]
      if type(easing) ~= 'function' then
         error("The easing function name '" .. name .. "' is invalid")
      end
   end
   return result
end

local function performEasingOnSubject(subject, target, initial, clock, duration, easing)
   local t, b, c, d
   for k, v in pairs(target) do
      if type(v) == 'table' then
         performEasingOnSubject((subject)[k], v, (initial)[k], clock, duration, easing)
      else
         t, b, c, d = clock, (initial)[k], v - ((initial)[k]), duration
         subject[k] = easing(t, b, c, d)
      end
   end
end



local TweenClass = {}











local Tween = {}
local Tween_mt = {
   __index = Tween,
}

function TweenClass:set(clock)
   assert(type(clock) == 'number', "clock must be a positive number or 0")

   self.clock = clock

   if self.clock <= 0 then

      self.clock = 0
      copyTables(self.subject, self.initial)

   elseif self.clock >= self.duration then

      self.clock = self.duration
      copyTables(self.subject, self.target)

   else

      performEasingOnSubject(
      self.subject,
      self.target,
      self.initial, self.clock, self.duration, self.easing)

   end

   return self.clock >= self.duration
end

function TweenClass:reset()
   return self:set(0)
end

function TweenClass:update(dt)
   assert(type(dt) == 'number', "dt must be a number")
   return self:set(self.clock + dt)
end




tween.new = function(duration, subject, target, easing)
   local easing_fun = getEasingFunction(easing)
   checkNewParams(duration, subject, target, easing)
   return setmetatable({
      duration = duration,
      subject = subject,
      target = target,
      easing = easing_fun,

      initial = copyTables({}, target, subject),
      clock = 0,
   }, Tween_mt)
end

return tween
