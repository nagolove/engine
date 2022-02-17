global record DDD
    type Pumper = function(number, number, any, number)
    type Pumper_noarg = function(number)
    type Pumper_1arg = function()

    init: function()
    hello: function(string)
    get_table: function(): {any}

    add: function(number, number): number
    pump_iron: function(Pumper, Pumper)
    pump_iron_noargs: function(Pumper_noarg)
    pump_iron_1arg: function(Pumper_1arg)
end

return DDD
