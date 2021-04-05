function printLog(...:any)
    --local args = {table.unpack(...)} as {any}
    --local strbuf = ""
    --for _, v in ipairs(args) do
        --strbuf = strbuf .. tostring(v)
    --end

    --print(...)
end

local colors = require "ansicolors" as function(a: any): any

function log(...: any)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local curarg: any = args[i]
        if str == "" then
            str = tostring(curarg)
        else
            str = str ..  "\t" .. tostring(curarg)
        end
    end
    print(colors(str))
end

function logwarn(...: any)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local curarg: any = args[i]
        if str == "" then
            str = tostring(curarg)
        else
            str = str ..  "\t" .. tostring(curarg)
        end
    end
    print(colors('%{yellow}str%{reset}'))
end

function logerror(...: any)
    local args = {...}
    local str = ""
    for i = 1, #args do
        local curarg = args[i]
        if str == "" then
            str = tostring(curarg)
        else
            str = str ..  "\t" .. tostring(curarg)
        end
    end
    print(colors('%{red}str%{reset}'))
end

function logf(...: any)
    print(colors(string.format(... as string)))
end

function logfwarn(...: any)
    print(colors('%{yellow}' .. string.format(... as string) .. '%{reset}'))
end

function logferror(...: any)
    print(colors('%{red}' .. string.format(... as string) .. '%{reset}'))
end

--return {
    --printLog = printLog
--}
