local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local os = _tl_compat and _tl_compat.os or os; local table = _tl_compat and _tl_compat.table or table; local _tl_table_unpack = unpack or table.unpack


























































































































































function foo(n)
   local t = {}
   for i = 1, n do
      table.insert(t, 0)
   end
   return _tl_table_unpack(t)
end

local Date = {}











local d = os.date("*t")
print(d)


local Rec = {}





local rec_mt
rec_mt = {
   __call = function(self, s, n)
      return tostring(self.x * n) .. s
   end,
   __add = function(a, b)
      local res = setmetatable({}, rec_mt)
      res.x = a.x + b.x
      return res
   end,
}
