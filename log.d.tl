local type Log = record
    log: function(...: any)
    logwarn: function(...: any)
    logerror: function(...: any)
    logferror: function(...: any)
end
return Log
