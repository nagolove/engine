return {
    include_dir = {
        "scenes/automato/",
        --"scenes/automato_test/",
    },
    include = {
        "*.tl",
        "scenes/automato/*.tl",
        --"scenes/automato_test/*.tl",
        "scenes/hst_reader/*.tl",
        --"../../*.tl",
    },
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"tools.tl",
        --"scenes/automato/*.tl",
        "scenes/hst_reader/*.tl",
        "crash*.tl",
    }
}
