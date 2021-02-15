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

    update: function()
    keypressed: function(key: string)

    drawList: function()
    drawShortcutsList: function(x0: number, y0: number)
    prepareDrawing: function()
    updateList: function(dt: number)
end

local Shortcut = KeyConfig.Shortcut
local ActionFunc = KeyConfig.ActionFunc

-- love.keyboard.isDown()
local shortcutsDown: {Shortcut} = {}

-- love.keypressed()
local shortcutsPressed: {Shortcut} = {}

local List = require "list"
local shortcutsList: List = nil

local function combo2str(stroke: KeyConfig.BindAccord): string
    local res = "["
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
    return res .. "]"
end

function KeyConfig.prepareDrawing()
    shortcutsList = List.new(5, 5)
    for _, v in ipairs(shortcutsDown) do
        local message: string = v.description .. " " .. combo2str(v.combo)
        shortcutsList:add(message)
    end
    for _, v in ipairs(shortcutsPressed) do
        local message: string = v.description .. " " .. combo2str(v.combo)
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

function KeyConfig.drawList()
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

--[[
-- рисовать список шорткатов, расположенный в определенных координатах
function KeyConfig.drawShortcutsList(x0: number, y0: number)
    x0 = x0 and x0 or 0
    y0 = y0 and y0 or 0
    local x, y = x0, y0

    local maxStringWidth = 0 -- сюда складывается максимальная длина строки символов, которая будет выводиться.
    local delimiter = "+"

    -- формирует и возвращает таблицу со списком комбинаций клавиш и описания их действия
    function makeTextList(list: {string: Shortcut}): {any}
        local textList: {any} = {}      
        for _, v in pairs(list) do
            local keyCombination = ""
            for k, keyValue in ipairs(v.combo) do
                if k < #v.combo then
                    keyCombination = keyValue  .. delimiter .. keyCombination
                else
                    keyCombination = keyCombination .. keyValue 
                end
            end
            local common: {any} = {}
            common[#common + 1] = {1, 0, 0}                       -- index  1
            common[#common + 1] = "\"" .. keyCombination .. "\""  --        2
            common[#common + 1] = {0, 1, 0}                       --        3
            common[#common + 1] = ": " .. v.description           --        4
            table.insert(textList, common) -- строка с цветами и строками для рисовки через lg.print()
            local textLen = string.len(common[2] as string) + string.len(common[4] as string)
            maxStringWidth = textLen > maxStringWidth and textLen or maxStringWidth -- определение самой длинной текстовой строки для вывода цветного фонового прямоугольника
        end
        return textList
    end

    -- для списка list расчитывает высоту рисуемого поля текущим шрифтом
    function calcHeight(list: {string: Shortcut}): number
        local h = 0
        for _, _ in pairs(list) do
            h = h + lg.getFont():getHeight()
        end
        return h
    end

    local tmpFont = lg.getFont()
    -- FIXME
    --lg.setFont(keyBindingsFont) 

    local list1, list2 = makeTextList(shortcutsPressed), makeTextList(shortcutsDown)

    -- XXX: здесь применен частный случай(workaround) - считается длина строки, 
    -- потом считается ширина строки 'zzzzzzzzzzzzzzzzzz' такой длины.
    local str = ""
    for i = 1, maxStringWidth do 
        str = str .. "z" 
    end

    -- расчет размера выводимого прямоугольника подложки
    local rectW, rectH = lg.getFont():getWidth(str), (calcHeight(shortcutsDown) + calcHeight(shortcutsPressed))

    lg.rectangle("fill", x0, y0, rectW, rectH)
    local oldWidth = lg.getLineWidth()
    local delta = 1
    lg.setLineWidth(3)
    lg.setColor{1, 0, 1}
    lg.rectangle("line", x0 - delta, y0 - delta, rectW + delta, rectH + delta)
    lg.setLineWidth(oldWidth)
    lg.setColor{1, 1, 1}

    local function drawList(list: {any})
        for _, v in ipairs(list) do
            lg.print(v as string, x, y) -- выводится цветной текст
            y = y + lg.getFont():getHeight()
        end
    end

    drawList(list1) 
    drawList(list2)
    lg.setFont(tmpFont)
end
--]]

local ids: {string: Shortcut} = {}

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

-- TODO: работает странно, если определить несколько горячих клавиш, 
-- к примеру f1 и f1+lshift
function KeyConfig.keypressed(key: string)
    for i, stroke in ipairs(shortcutsPressed) do
        if stroke.enabled then
            local combo = stroke.combo
            local pressed = key == combo.key
            if not pressed then 
                break 
            end
            print("keypressed stroke", inspect(stroke))
            if combo.mod then
                for _, mod in ipairs(combo.mod) do
                    pressed = pressed and lk.isDown(mod as love.keyboard.KeyConstant)
                    if not pressed then 
                        break 
                    end
                end
            end
            if pressed and stroke.action then
                local rebuildlist, newShortcut: boolean, Shortcut = stroke.action(stroke)
                if rebuildlist then
                    shortcutsList = nil
                    shortcutsPressed[i] = shallowCopy(newShortcut)
                end
            end
        end
    end
end

-- Проверка выполняется через lk.isDown()
function KeyConfig.update()
    for i, stroke in ipairs(shortcutsDown) do
        if stroke.enabled then
            print("stroke", inspect(stroke))
            local combo = stroke.combo
            local pressed = lk.isScancodeDown(combo.key as love.keyboard.KeyConstant)
            if not pressed then 
                break 
            end 
            if combo.mod then
                for _, keyValue in ipairs(combo.mod) do
                    pressed = pressed and lk.isScancodeDown(keyValue as love.keyboard.KeyConstant)
                    if not pressed then 
                        break 
                    end 
                end
            end
            if pressed and stroke.action then 
                shortcutsList = nil
                local rebuildlist, newShortcut: boolean, Shortcut = stroke.action(stroke)
                if rebuildlist then
                    shortcutsDown[i] = shallowCopy(newShortcut)
                end
            end
        end
    end
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
