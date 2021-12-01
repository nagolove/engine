--local Chipmunk = require 'chipmunk'
local Cm = require 'chipmunk'
require 'pipeline'

local record PhysicsWrapper
    record Body
        body: Cm.cpBody
        --shape: Cm.cpShape
        applyImpulse: function(Body, impx: number, impy: number)
        getInfoStr: function(Body): string
    end

    -- Добавлять-ли сразу возможность работы с несколькими пространствами?

    init: function(pipeline: Pipeline)
    free: function()
    update: function(dt: number)
    render: function()

    newVect: function(): Cm.cpVect
    newBoxBody: function(w: number, h: number): Body

    getBodies: function(): {Body}

    --type EachCallback = function(Body)
    type EachCallback = function(Cm.cpBody)

    record EachBodyIter end
    record EachShapeIter end

    newEachBodyIter: function(cb: EachCallback): EachBodyIter
    newEachShapeIter: function()

    cpBody2Body: function(Cm.cpBody): Body

    --eachBody1: function(cb: EachCallback)
    eachBody: function(iter: EachBodyIter)
    eachShape: function(iter: EachShapeIter)
end

return PhysicsWrapper
