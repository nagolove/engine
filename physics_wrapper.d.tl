require 'pipeline'

global record PhysicsWrapper
    init: function(pipeline: Pipeline)
    free: function()
    -- Шаг движка
    update: function(dt: number)
    render: function()
end

return PhysicsWrapper
