local file = io.popen("uname -a")
local is_windows = false
local is_linux = false
if file then
    if file:read("*a"):match("Linux.*") then
        is_linux = true
        is_window = false
    else
        is_linux = false
        is_windows = false
    end
else
    error("No file opened.")
end
print("is_linux", is_linux)
print("is_windows", is_windows)

function getAutomatoFiles()
    local files = {
        "asm.tl",           -- движок ассемблера для клеток
        "cell-actions.tl",  -- обработка команд клетки
        "cell.tl",          -- класс клетки
        "ex.tl",            -- экспериментальная функциональность
        "graph-render.tl",      -- рисование 3д-графиков
        "graphics-render.tl",   -- рисование 2д-анимации
        "init.tl",              -- заглавная сцена загрузки 
        "simulator-render.tl",  -- 
        "simulator-thread.tl", 
        "simulator.tl", 
        "types.tl", 
    }
    for k, v in pairs(files) do
        if is_windows then
            --files[k] = "scenes/automato/" .. v
            files[k] = "scenes\\automato\\" .. v
        else
            files[k] = "scenes/automato/" .. v
        end
    end
    return files
end

print("is_linux", is_linux)

local files = nil
if is_windows then
    files = getAutomatoFiles()
end

print("files", files)

return {
    --skip_compat53 = true,
    --gen_target = "5.1",
    global_env_def = "love",
    --source_dir = "src",
    --build_dir = "app",
    include_dir = {
        --"assets",
        "lib",
        "src",
        "include",
        "scenes/automato/",
        --"",

        "scenes/nback3/",
        "scenes/button_test/",
        "scenes/nback2/libs/",

        "scenes/bezier-shader/",
        "scenes/fractaltree/",
        "scenes/hexfield/",
        "scenes/imgui-bindings/",
        "scenes/lsystem/",
        "scenes/pink1/",
        "scenes/slog-example/",
        "scenes/timers_animations_tl/",
        "scenes/wavegrid/",
    },
    include = {
        "scenes/fractaltree/*.tl",
        "scenes/automato/*.tl",
        --"scenes/empty/*.tl",
        "src/*.tl",
        "*.tl",

        "scenes/bezier-shader/*.tl",
        "scenes/button_test/*.tl",
        "scenes/fractaltree/*.tl",
        "scenes/lsystem/*.tl",
        "scenes/nback3/*.tl",
        "scenes/pink1/*.tl",
        "scenes/timers_animations_tl/*.tl",
        "scenes/wavegrid/*.tl",
        --"scenes/hst_reader/*.tl",
        --"scenes/imgui-bindings/*.tl",
        --"scenes/hst_reader/*.tl",
        --"scenes/hexfield/*.tl",
        --"scenes/slog-example/*.tl",
        --"scenes/code_shader/*.tl",
        --"../../*.tl",
    },
    --files = files,
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"tools.tl",
        --"scenes/automato/*.tl",
        --"scenes/nback2/*.tl",
        --"main.tl",
        --"crash*.tl",
    }
}
