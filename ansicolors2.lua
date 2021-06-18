local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local os = _tl_compat and _tl_compat.os or os; local package = _tl_compat and _tl_compat.package or package; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
























local function isWindows()
   return type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1, 1) == '\\'
end

local supported = not isWindows()
if isWindows() then supported = os.getenv("ANSICON") end

local keys = {

   ["reset"] = 0,


   ["bright"] = 1,
   ["dim"] = 2,
   ["underline"] = 4,
   ["blink"] = 5,
   ["reverse"] = 7,
   ["hidden"] = 8,


   ["black"] = 30,
   ["red"] = 31,
   ["green"] = 32,
   ["yellow"] = 33,
   ["blue"] = 34,
   ["magenta"] = 35,
   ["cyan"] = 36,
   ["white"] = 37,


   ["blackbg"] = 40,
   ["redbg"] = 41,
   ["greenbg"] = 42,
   ["yellowbg"] = 43,
   ["bluebg"] = 44,
   ["magentabg"] = 45,
   ["cyanbg"] = 46,
   ["whitebg"] = 47,
}

local escapeString = string.char(27) .. '[%dm'
local function escapeNumber(num)
   return escapeString:format(num)
end

local function escapeKeys(str)
   if not supported then return "" end

   local buffer = {}
   local num
   for word in str:gmatch("%w+") do
      num = keys[word]
      assert(num, "Unknown key: " .. word)
      table.insert(buffer, escapeNumber(num))
   end

   return table.concat(buffer)
end

local function replaceCodes(str)
   str = string.gsub(str, "(%%{(.-)})",
   function(_, str)
      return escapeKeys(str)
   end)

   return str
end



local function ansicolors(str)
   str = tostring(str or '')
   return replaceCodes('%{reset}' .. str .. '%{reset}')
end














return {
   ansicolors = ansicolors,
}
