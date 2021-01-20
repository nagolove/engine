local type Struct = record
    pack: function(string, ...: any): string
    unpack: function(string, string, number | nil): any
end
return Struct
