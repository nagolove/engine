local ansicolor = require "ansicolors"

local delim = "       "
print("#delim", #delim)

function log(...)
    local function spaces(strlen, arg)
        return string.rep(" ",1+  math.fmod(strlen, #delim))
    end

    local args = {...}
    local str = ""
    for i = 1, #args do
        local arg = args[i]
        --print("arg", arg)
        if str == "" then
            str = tostring(arg) --.. spaces(arg)
        else
            str = str ..  spaces(#str, arg) .. tostring(arg)
        end
    end
    print(str)
    print(...)
end

function logf(...)
    print(string.format(...))
end

log("bla", 1, 2)
log("blahh", "1fefe", 2)
log("blahh", "1fefeaaaab", 2)
log("blahhhh", 1, 2)
log("blahhhhfef", 1, 2)

os.exit()
