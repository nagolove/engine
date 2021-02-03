local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local table = _tl_compat and _tl_compat.table or table; local Rec = {}




local r = {}

function foo(init)
   for k, v in pairs(init) do

   end
end















function zoo()
   return "blah", -1
end

function goo(s)
   print(s)
end

goo(zoo)


local t = {
   "hi",
   "0",
   "num",
}

print(table.concat(t))
