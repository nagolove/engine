local colors = {
   { 24 / 255, 81 / 255, 129 / 255 },
   { 32 / 255, 97 / 255, 157 / 255 },
   { 35 / 255, 113 / 255, 179 / 255 },
   { 40 / 255, 128 / 255, 206 / 255 },
   { 60 / 255, 130 / 255, 70 / 255 },
   { 72 / 255, 149 / 255, 81 / 255 },
   { 88 / 255, 164 / 255, 97 / 255 },
   { 110 / 255, 176 / 255, 120 / 255 },
   { 84 / 255, 69 / 255, 52 / 255 },
   { 102 / 255, 85 / 255, 66 / 255 },
   { 120 / 255, 100 / 255, 73 / 255 },
   { 140 / 255, 117 / 255, 86 / 255 },
   { 207 / 255, 207 / 255, 207 / 255 },
   { 223 / 255, 223 / 255, 223 / 255 },
   { 239 / 255, 239 / 255, 239 / 255 },
   { 255 / 255, 255 / 255, 255 / 255 },
}

local function interpolate_color(a, b, t)
   local c = {}
   for i = 1, #a do
      c[i] = a[i] + t * (b[i] - a[i])
   end
   return c
end


local function color(value)

   local n = #colors + 2

   if value <= 1 / n then
      return colors[1]
   end

   for i = 2, #colors do
      if value <= i / n then

         local t = (value - ((i - 1) / n)) / (1 / n)
         return interpolate_color(colors[i - 1], colors[i], t)
      end
   end


   return colors[#colors]
end

return {
   color = color,
}
