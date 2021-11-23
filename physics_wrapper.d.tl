--local Chipmunk = require 'chipmunk'
local Cm = require 'chipmunk'
require 'pipeline'

global record PhysicsWrapper
    init: function(pipeline: Pipeline)
    free: function()
    update: function(dt: number)
    render: function()

    newVect: function(): Cm.cpVect
end

return PhysicsWrapper
