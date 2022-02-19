global record ffi
    new: function(string, number): any
    cdef: function(string)
    cast: function(string, any): any
    load: function(string): any
    string: function(ptr: any, len: integer): string
end

return ffi
