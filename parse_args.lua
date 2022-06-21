function parseGameArguments(arg)
    return love.arg.parseGameArguments(arg)
end

--function callHandler(name, a, b, c, d, e, f)
    --love.handlers[name](a,b,c,d,e,f)
--end

return {
    parseGameArguments = parseGameArguments,
    --callHandler = callHandler,
}
