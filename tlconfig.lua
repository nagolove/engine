return {
    include_dir = {
        "scenes/automato/",
    },
    include = {
        "*.tl",
        "scenes/automato/*.tl",
    },
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"scenes/automato/*.tl",
    }
}
