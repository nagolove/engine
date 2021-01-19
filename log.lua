local colors = require "ansicolors"

return {
log = function (...)
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

logwarn = function (...)
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

logerror = function (...)
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

logf = function (...)
    print(colors(string.format(...)))
end

logfwarn = function (...)
    print(colors('%{yellow}' .. string.format(...) .. '%{reset}'))
end

logferror = function (...)
    print(colors('%{red}' .. string.format(...) .. '%{reset}'))
end
}
