local type Function = function(any): any
local type Serpent = record
    dump: function(a: any, opts: any)
    line: function(a: any, opts: any)
    block: function(a: any, opts: any)
    load: function(string): Function
end
return Serpent
