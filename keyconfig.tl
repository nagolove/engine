-- vim: fdm=marker
-- vim: set colorcolumn=85

require "love"
require "common"

--local gr = love.graphics
local inspect = require "inspect"
local lk = love.keyboard
local type IsPressed = function(str: string): boolean

global type KeyConfig = record

    type BindAccord = record
        -- {{{
        -- список модификаторов
        mod: {string}
        -- клавиша
        key: string
        -- клавиша мыши
        mousekey: string
        -- }}}
    end

    type Shortcut = record
        -- {{{
        -- сочетание клавиш. Сперва идут модификаторы, потом основные кнопки
        combo: BindAccord
        -- вызывается при нажатии
        action: ActionFunc
        -- строковое описание что делает сочетание клавиш и в каком состоянии 
        -- вызывается
        description: string
        -- флаг временного отключения
        enabled: boolean
        -- }}}
    end

    type ActionFunc = function(Shortcut): boolean, Shortcut

    type BindType = enum
        "keypressed"
        "isdown"
    end

    -- EXTERNAL INTERFACE --

    -- послать нажатие по идентификатору
    send: function(id: string)
    -- зарегистрировать комбинацию клавиш 
    bind: function( btype: BindType, 
                    combo: BindAccord, 
                    action: ActionFunc, 
                    description: string, 
                    id: string|nil)
    unbind: function(id: string)
    -- распечатать в консоль все зарегистрированные хоткеи
    printBinds: function()
    -- вызывать для обновления внутренниего состояния "isdown"
    update: function()
    -- вызывать для обновления внутренниего состояния "keypressed"
    keypressed: function(key: string)

    -- рисовать красивый список с навигацией и подробной справкой
    draw: function()

    -- вызывать только если активна отрисовка
    updateList: function(dt: number)

    -- INTERNAL ↓↓ -- INTERNAL -- ↓↓ INTERNAL --

    prepareDrawing: function()
    checkExistHotkey: function(list: {Shortcut}, combo: KeyConfig.BindAccord): boolean
    getHotkeyString: function(combo: KeyConfig.BindAccord): string
    -- сравнить два массива клавиш-модификаторов
    compareMod: function(mod1: {string}, mod2: {string}): boolean
    test: function(shortcuts: {Shortcut}, isPressed: IsPressed)

    -- INTERNAL -- ↑↑ INTERNAL ↑↑ -- INTERNAL --
end

local Shortcut = KeyConfig.Shortcut
local ActionFunc = KeyConfig.ActionFunc

-- love.keyboard.isDown()
local shortcutsDown: {Shortcut} = {}

-- love.keypressed()
local shortcutsPressed: {Shortcut} = {}

local List = require "list"
--local imgui = require 'imgui'
local shortcutsList: List = nil

local function combo2str(stroke: KeyConfig.BindAccord): string
    local res = ""
    if stroke.mod then
        for k, key in ipairs(stroke.mod) do
            res = res .. key
            if k < #stroke.mod then
                res = res .. " + "
            end
        end
        res = res .. " + " .. stroke.key
    else
        res = stroke.key
    end
    return '[' .. res .. ']'
end

function KeyConfig.prepareDrawing()
    shortcutsList = List.new(5, 5)
    for _, v in ipairs(shortcutsDown) do
        local message: string = v.description .. " " .. combo2str(v.combo)
        --local message: string = "hhhh"
        print("message", message)
        shortcutsList:add(message)
    end
    for _, v in ipairs(shortcutsPressed) do
        local message: string = v.description .. " " .. combo2str(v.combo)
        --local message: string = "uuuuuuuu"
        print("message", message)
        shortcutsList:add(message)
    end
    -- XXX Почему сортировка идет по id? сортировать разными способами по 
    -- сочетаниям клавиш к примеру
    table.sort(shortcutsList.items, function(a: List.Item, b: List.Item): boolean
        --return a.id < b.id
        return a.message > b.message
    end)
    shortcutsList:done()
end

function KeyConfig.draw()
    if not shortcutsList then
        KeyConfig.prepareDrawing()
    end
    shortcutsList:draw()
end

function KeyConfig.updateList(dt: number)
    if shortcutsList then
        shortcutsList:update(dt)
    end
end

local ids: {string: Shortcut} = {}

function KeyConfig.compareMod(mod1: {string}, mod2: {string}): boolean
    if mod1 and mod2 then
        if #mod1 ~= #mod2 then
            return false
        else
            for i = 1, #mod1 do
                if mod1[i] ~= mod2[i] then
                    return false
                end
            end
        end
        return true
    end
end

function KeyConfig.checkExistHotkey(list: {Shortcut}, combo: KeyConfig.BindAccord): boolean
    for _, shortcut in ipairs(list) do
        print("shortcut.combo.mod, combo.mod)", shortcut.combo.mod, combo.mod)
        if KeyConfig.compareMod(shortcut.combo.mod, combo.mod) and shortcut.combo.key == combo.key then
            return true
        end
    end
    return false
end

function KeyConfig.getHotkeyString(combo: KeyConfig.BindAccord): string
    local mod_str = ""
    for _, v in ipairs(combo.mod) do
        mod_str = mod_str .. v
    end
    return "[" .. mod_str .. "] + " .. combo.key
end

function KeyConfig.bind(
    btype: KeyConfig.BindType,
    combo: KeyConfig.BindAccord,
    action: ActionFunc, 
    description: string, 
    id: string|nil)

    local map = {
        ["keypressed"] = shortcutsPressed,
        ["isdown"] = shortcutsDown,
    }
    local list: {Shortcut} = map[btype]
    if KeyConfig.checkExistHotkey(list, combo) then
        assert('hotkey ' .. KeyConfig.getHotkeyString(combo))
    end
    description = description or ""
    table.insert(list, {
        combo = shallowCopy(combo),
        action = action, 
        description = description,
        enabled = true
    })
    if id then
        ids[id] = list[#list]
    end
    -- обновить визуальный список
    -- XXX частый вызов может замедлить программу
    KeyConfig.prepareDrawing()
end

function KeyConfig.unbind(id: string)
    -- FIXME
    print("TO DO unbind FUNCTION")
end

function KeyConfig.printBinds()
    print("keypressed:")
    for _, stroke in ipairs(shortcutsPressed) do
        print("stroke", inspect(stroke))
    end
    print("end keypressed:")
    print("isdown:")
    for _, stroke in ipairs(shortcutsDown) do
        print("stroke", inspect(stroke))
    end
    print("end isdown:")
end

function KeyConfig.test(shortcuts: {Shortcut}, isPressed: IsPressed)
    for i, stroke in ipairs(shortcuts) do
        if stroke.enabled then
            local combo = stroke.combo
            local pressed = isPressed(combo.key)
            if pressed then 
                --print("keypressed stroke", inspect(stroke))
                if combo.mod then
                    for _, mod in ipairs(combo.mod) do
                        pressed = pressed and lk.isScancodeDown(mod as love.keyboard.KeyConstant)
                        if not pressed then 
                            break 
                        end
                    end
                end
                if pressed and stroke.action then
                    local rebuildlist, newShortcut: boolean, Shortcut = stroke.action(stroke)
                    if rebuildlist then
                        shortcutsList = nil
                        shortcuts[i] = shallowCopy(newShortcut)
                    end
                end
            end
        end
    end
end

-- TODO: работает странно, если определить несколько горячих клавиш, 
-- к примеру f1 и f1+lshift
function KeyConfig.keypressed(key: string)
    KeyConfig.test(
        shortcutsPressed, 
        function(str: string): boolean
            return key == str
        end
    )
end

-- Проверка выполняется через lk.isDown()
function KeyConfig.update()
    KeyConfig.test(
        shortcutsDown, 
        function(str: string): boolean
            return lk.isScancodeDown(str as love.keyboard.KeyConstant)
        end
    )
end

function KeyConfig.send(id: string)
    local sc: Shortcut = ids[id]
    if sc and sc.enabled and sc.action then
        local rebuildlist, newsc = sc.action()
        if rebuildlist then
            ids[id] = shallowCopy(newsc)
        end
    end
end

return KeyConfig
