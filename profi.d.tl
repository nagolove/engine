global type Profi = record
    start: function(p: Profi, param: string)
    stop: function(p: Profi)
    writeReport: function(p: Profi, string)
    checkMemory: function(p: Profi, interval: number, note: string)
    reset: function(p: Profi)
    setSortMethod: function(Profi, string)
end

return Profi
