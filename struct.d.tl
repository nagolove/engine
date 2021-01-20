local type Struct = record
    pack: function(string, ...: any)
    unpack: function(string, string, number | nil)
end
return Struct
