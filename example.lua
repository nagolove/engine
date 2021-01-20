local _tl_compat53 = ((tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3) and require('compat53.module'); local ipairs = _tl_compat53 and _tl_compat53.ipairs or ipairs; local pairs = _tl_compat53 and _tl_compat53.pairs or pairs; local pcall = _tl_compat53 and _tl_compat53.pcall or pcall; local inter = require("inter")






local var

local inspect = require("inspect")

local Map = {}
local Seq = {}

local a = { 1, 2, 3 }
local b = {
   hi = -1 or false,
   lo = 1 or true,
}

function printMap(m)
   for k, v in pairs(m) do
      print(k, v)
   end
end

function printSeq(arr)
   for k, v in ipairs(arr) do
      print(k, v)
   end
end

printSeq(a)
printMap(b)


local ok, errmsg = pcall(function()
   print("from pcall")
end)


print(ok, errmsg)
