require "love"
require "common"

local lk = love.keyboard
local inspect = require "inspect"
--local gr = love.graphics

global type KeyConfig = record

    type BindAccord = record
        -- список модификаторов
        mod: {string}
        -- клавиша
        key: string
        -- клавиша мыши
        mousekey: string
    end

    type Shortcut = record
        -- сочетание клавиш. Сперва идут модификаторы, потом основные кнопки
        combo: BindAccord
        -- вызывается при нажатии
        action: ActionFunc
        -- строковое описание что делает сочетание клавиш и в каком состоянии 
        -- вызывается
        description: string
        -- флаг временного отключения
        enabled: boolean
    end

    type ActionFunc = function(Shortcut): boolean, Shortcut

    type BindType = enum
        "keypressed"
        "isdown"
    end

    -- послать нажатие по идентификатору
    send: function(id: string)

    bind: function(BindType, combo: BindAccord, ActionFunc, string, string|nil)

    --bindKeyDown: function(stringID: string, keyCombination: {string}, action: ActionFunc, description: string)
    --bindKeyPressed: function(stringID: string, keyCombination: {string}, action: ActionFunc, description: string)
    printBinds: function()

    update: function()
    keypressed: function(key: string)

    draw: function()
    --drawShortcutsList: function(x0: number, y0: number)
    prepareDrawing: function()

    -- вызывать только если активна отрисовка
    updateList: function(dt: number)

    checkExistHotkey: function(BindAccord): boolean
    getHotkeyString: function(combo: KeyConfig.BindAccord): string

    test: function(shortcuts: {Shortcut}, isPressed: IsPressed)
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

function KeyConfig.checkExistHokey(
    list: {Shortcut}, 
    combo: KeyConfig.BindAccord): boolean
    if 
end

function KeyConfig.getHotkeyString(combo: KeyConfig.BindAccord): string
    return "[" .. combo.mod .. "] + " .. combo.key
end

function KeyConfig.bind(
    btype: KeyConfig.BindType,
    combo: KeyConfig.BindAccord,
    action: ActionFunc, 
    description: string, 
    id: string|nil)

    description = description or ""
    local map = {
        ["keypressed"] = shortcutsPressed,
        ["isdown"] = shortcutsDown,
    }
    local list: {Shortcut} = map[btype]
    -- добавить assert проверку на существование хоткея в коллекции
    if checkExistHokey(list) then
        assert('hotkey ' .. getHotkeyString(combo))
    end
    table.insert(list, {
        combo = shallowCopy(combo),
        action = action, 
        description = description,
        enabled = true
    })
    if id then
        ids[id] = list[#list]
    end
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
                        pressed = pressed and lk.isScancodeDown(str as love.keyboard.KeyConstant)
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
    test(
        shortcutsPressed, 
        function(str: string): boolean
            return key == str
        end
    )
end

-- Проверка выполняется через lk.isDown()
function KeyConfig.update()
    test(
        shortcutsDown, 
        function(str: string): boolean
            return lk.isScancodeDown(combo.key as love.keyboard.KeyConstant)
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
