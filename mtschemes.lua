return {
    -- при работе в одном потоке не используется обмен через каналы
    [1] = nil, 

    --[[
    -- | 1 | 2 |
    --]]
    [2] = {
        {"l" = 2, "r" = 2}, 
        {"l" = 1, "r" = 1}
    },

    --[[
    -- | 1 | 2 | 3 |
    --]]
    [3] = {
        {"l" = 3, "r" = 2}, 
        {"l" = 1, "r" = 3},
        {"l" = 2, "r" = 1},
    },

    --[[
    -- | 1 | 2 |
    -- | 3 | 4 |
    --]]
    [4] = {
        {"l" = 2, "r" = 2, "u" = 3, "d" = 3}, 
        {"l" = 1, "r" = 1, "u" = 4, "d" = 4},
        {"l" = 4, "r" = 4, "u" = 1, "d" = 1},
        {"l" = 3, "r" = 4, "u" = 2, "d" = 2},
    },

    --[[
    -- | 1 | 2 | 3 |
    -- | 4 | 5 | 6 |
    --]]
    [6] = {
        {"l" = 3, "r" = 2}, 
        {"l" = 1, "r" = 3},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
    },

    --[[
    -- | 1 | 2 | 3 |
    -- | 4 | 5 | 6 |
    -- | 7 | 8 | 9 |
    --]]
    [9] = {
        {"l" = 3, "r" = 2}, 
        {"l" = 1, "r" = 3},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
        {"l" = 2, "r" = 1},
    }
}