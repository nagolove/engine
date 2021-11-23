--local Chipmunk = require 'chipmunk'
require 'chipmunk'
require 'pipeline'

global record PhysicsWrapper
    init: function(pipeline: Pipeline)
    free: function()
    update: function(dt: number)
    render: function()

    newVect: function(): cpVect
end

return PhysicsWrapper
