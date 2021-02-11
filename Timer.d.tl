global type DuringFunc = function(dt: number, time: number, delay: number)

global type Timer = record
    new: function(): Timer
    update: function(Timer, number)
    after: function(self: Timer, delay: number, action: function(number), tag:string)
    every: function(self: Timer, delay: number, action: function(number), count: number, after: function, tag:string)
    during: function(self: Timer, delay: number, action: DuringFunc, after: function, tag:string)
    script: function(self: Timer)
    tween: function(self: Timer, delay: number, subject: any, target: any, method: string, after: function, tag: string, ...:any)
    metamethod __call: function(self: Timer): Timer
    destroy: function
end

return Timer
