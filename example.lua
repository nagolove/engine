local _tl_compat53 = ((tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3) and require('compat53.module'); local ipairs = _tl_compat53 and _tl_compat53.ipairs or ipairs; local pairs = _tl_compat53 and _tl_compat53.pairs or pairs; local inter = require("inter")






require("example2")

function compareTypes()
   local Type1 = {}
   local Type2 = {}
   local Type3 = {}
   local v1 = { 1, 2, 3 }
   local v2 = { 0, 0 }


end

local var
local var2

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


local zh = {}
print(zh[1][2])

local x = { 1 }
local y = { 2 }
y = x

local z = { 1, 2 }

function foo()

end





function copy(t)

   local result = {}
   for k, v in pairs(t) do
      result[k] = v
   end
   return result


end





















local Commands = {}





local Cmds = {}





local commands = {}

commands["do3"] = function()
   print("do3")
end

function commands.do1()    print("do1") end
function commands.do2()    print("do2") end

function process(cmd)
   if cmd then
      local command = commands[cmd]
      if command then
         command()
      end
   end
end
