return {
    include_dir = {
        "scenes/automato/",
    },
    include = {
        "*.tl",
        "scenes/automato/*.tl",
        "scenes/hst_reader/*.tl",
        --"../../*.tl",
    },
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"scenes/automato/*.tl",
        "crash*.tl",
    }
}
