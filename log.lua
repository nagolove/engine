local colors = require "ansicolors"

function log(...)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local arg = args[i]
        if str == "" then
            str = tostring(arg)
        else
            str = str ..  "\t" .. tostring(arg)
        end
    end
    print(colors(str))
end

function logwarn(...)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local arg = args[i]
        if str == "" then
            str = tostring(arg)
        else
            str = str ..  "\t" .. tostring(arg)
        end
    end
    print(colors('%{yellow}str%{reset}'))
end

function logerror(...)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local arg = args[i]
        if str == "" then
            str = tostring(arg)
        else
            str = str ..  "\t" .. tostring(arg)
        end
    end
    print(colors('%{red}str%{reset}'))
end

function logf(...)
    print(colors(string.format(...)))
end

function logfwarn(...)
    print(colors('%{yellow}' .. string.format(...) .. '%{reset}'))
end

function logferror(...)
    print(colors('%{red}' .. string.format(...) .. '%{reset}'))
end
