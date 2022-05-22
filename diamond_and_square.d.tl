local record DiamondAndSquare
    -- 0..1 random
    type RandomCallback = function(): number

    record Generator
        internal_free: function()
        eval: function()
        -- индексация с 0 по get_mapsize() - 1
        get: function(i: integer, j: integer): number
        get_mapsize: function(): integer
    end

    new: function(size: integer, rc: RandomCallback): Generator

end

return DiamondAndSquare
