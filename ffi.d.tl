global record ffi
    new: function(string, number): any
    cdef: function(string)
    cast: function(string, any): any
    load: function(string): any
end

return ffi
