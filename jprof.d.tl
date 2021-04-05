local type jprof = record
    push: function(zonestack: any, name: string)
    pop: function(name: string)
    write: function(name: string)
end
return jprof
