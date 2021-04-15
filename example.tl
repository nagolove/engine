
--[[
global type Statistic = record

    enum Types
        'allEated'
        'maxEnergy'
        'minEnergy'
        'midEnergy'
        "cells"
        "iterations"
        "meals"
        "born"
        "died"
        'percentAreaFilled'
        'stepsPerSecond'
    end

end

global formatMods: {Statistic.Types:string} = {
    ['allEated'] = '%d',
    ['maxEnergy'] = '%d',
    ['minEnergy'] = '%d',
    ['midEnergy'] = '%d',
    ['cells'] = '%d',
    ['iterations'] = '%d',
    ['meals'] = '%d',
    ['born'] = '%d',
    ['died'] = '%d',
    ['percentAreaFilled'] = '%f',
    ['stepsPerSecond'] = '%d',
}
--]]


local type Layout = record
    x: number
    -- some constructor
    new: function(): Layout
end

function Layout.new(): Layout
    return {}
end

local l: Layout = Layout.new()
-- dynamically add field for record instance
--(l as {any:any}).z = Layout.new()

--((l as {any:any}).z as Layout) = Layout.new()
--print((((l as {any:any}).z) as Layout).x )
--((l as {any:any}).z as Layout).x = 0
--((l as {any:any}).z as Layout).x = 1

