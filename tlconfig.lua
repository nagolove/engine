-- vim: set colorcolumn=85
-- vim: fdm=marker

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

--[[
-- Написать функцию-сборщик файлов движка.
function getAutomatoFiles()
    -- {{{
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
    -- }}}
end
--]]

print("is_linux", is_linux)

local files = nil
if is_windows then
    --files = getAutomatoFiles()
end
--print("files", files)

local default_include = {
    --"scenes/empty/*.tl",
    --"scenes/empty_mt/*.tl",
    "scenes/messenger/*.tl",
    --"scenes/mt_coro/*.tl",
    --"scenes/chipmunk_mt/*.tl",
    --"scenes/lua_capi/*.tl",
    --"src/*.tl",
    "*.tl",
    --"scenes/sri/*.tl",
    "scenes/t80/*.tl",
    "scenes/t80_tanks_bench/*.tl",
    "scenes/t80_circle_moving/*.tl",
    --"scenes/diamond_square/*.tl",
    --'scenes/colored_text_transform_mt/*.tl',
    --'scenes/textured_quad/*.tl',
    --'scenes/debug_print_mt/*.tl',
    --'scenes/dynlib/*.tl',
}

local include_fname = "tl_include.txt"
local current_include
local ok, errmsg = pcall(function()
    local file = io.open(include_fname, "r")
    current_include = {}
    for line in file:lines() do
        table.insert(current_include, line)
    end
    file:close()
end)

if not ok then
    print(string.format("Error in opening % with %s", include_fname, errmsg))
end

if not current_include then 
    current_include = default_include
end

return {
    --skip_compat53 = true,
    --gen_target = "5.1",
    global_env_def = "love",
    --source_dir = "src",
    --build_dir = "app",
    include_dir = {
        "include",

        --"scenes/t80/",
        --"scenes/t80_tanks_bench/",
        "scenes/t80_circle_moving/",

        --"scenes/lua_capi/",
        --"scenes/sri/",
    },
    include = current_include,
    --files = files,
    exclude = {
    }
}
