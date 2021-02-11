return {
    include_dir = {
        "scenes/automato/",
        "scenes/nback2/",
        "scenes/nback2/libs/",
        "scenes/hex-field/"
        --"scenes/automato_test/",
    },
    include = {
        "*.tl",
        "scenes/automato/*.tl",
        "scenes/empty/*.tl",
        --"scenes/nback2/*.tl",
        --"scenes/automato_test/*.tl",
        "scenes/hst_reader/*.tl",
        "scenes/hex-field/*.tl"
        --"../../*.tl",
    },
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"tools.tl",
        --"scenes/automato/*.tl",
        --"scenes/nback2/*.tl",
        "scenes/hst_reader/*.tl",
        "main.tl",
        "crash*.tl",
    }
}
