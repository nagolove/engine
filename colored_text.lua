local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local table = _tl_compat and _tl_compat.table or table







require('utf8')
local u8 = require("utf8")
local inspect = require("inspect")









local function makeDescentColorText(
   textobj,
   textstr,
   fromcolor,
   tocolor,
   ...)


   assert(textobj, "textobj should not be nil")
   assert(type(textstr) == "string", "textstr should be a string, not " .. type(textstr))
   assert(type(fromcolor) == "table", "fromcolor should be a table, not " .. type(fromcolor))
   assert(type(tocolor) == "table", "tocolor should be a table, not " .. type(tocolor))
   assert(#fromcolor == 4, "fromcolor should have 4 components")
   assert(#tocolor == 4, "tocolor should have 4 components")

   print("textobj", textobj)
   print("textstr", textstr)
   print("fromcolor", inspect(fromcolor))
   print("tocolor", inspect(tocolor))

   local slen = u8.len(textstr)
   print("slen", slen)

   local r, g, b, a = fromcolor[1], fromcolor[2], fromcolor[3], fromcolor[4]


   local d_r = (tocolor[1] - fromcolor[1]) / slen
   local d_g = (tocolor[2] - fromcolor[2]) / slen
   local d_b = (tocolor[3] - fromcolor[3]) / slen
   local d_a = (tocolor[4] - fromcolor[4]) / slen

   print("d_r", d_r)
   print("d_g", d_g)
   print("d_b", d_b)
   print("d_a", d_a)






   local coloredtext = {}
   for p, c in u8.codes(textstr) do



      local char = u8.char(c)
      print("p, c, char", p, c, u8.char(c))

      table.insert(coloredtext, { r, g, b, a })
      table.insert(coloredtext, char)
      r = r + d_r
      g = g + d_g
      b = b + d_b
      a = a + d_a
   end



   return textobj:add(coloredtext, ...)
end


































































return {
   makeDescentColorText = makeDescentColorText,
}
