local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local string = _tl_compat and _tl_compat.string or string; require('love')

local names = {}




local function writeCanvas2Disk(
   cnv,
   name,
   maxFilesNum)

   assert(string.find(name, '%%d') ~= nil)
   if not names[name] then
      names[name] = 0
   end

   if names[name] < maxFilesNum then
      names[name] = names[name] + 1
      cnv:newImageData():encode('png', string.format(name, names[name]))
   end
end

return {
   writeCanvas2Disk = writeCanvas2Disk,
}
