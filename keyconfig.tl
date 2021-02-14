-- lk.isDown()
require "love"
require "common"
local lk = love.keyboard
--local gr = love.graphics

global type ActionFunc = function(Shortcut): boolean, Shortcut

global type Shortcut = record
    -- сочетание клавиш. Сперва идут модификаторы, потом основные кнопки
    combo: {string}
    -- вызывается при нажатии
    action: ActionFunc
    -- строковое описание что делает сочетание клавиш и в каком состоянии 
    -- вызывается
    description: string
    -- флаг временного отключения
    enabled: boolean
end

global type BindType = enum
    "keypressed"
    "isdown"
end

global type KeyConfig = record
    -- послать нажатие по идентификатору
    send: function(stringID: string)

    bind: function(BindType, combo: {string}, ActionFunc, string, string|nil)

    bindKeyDown: function(stringID: string, keyCombination: {string}, action: ActionFunc, description: string)
    bindKeyPressed: function(stringID: string, keyCombination: {string}, action: ActionFunc, description: string)

    update: function()
    keypressed: function(key: string)

    drawList: function()
    drawShortcutsList: function(x0: number, y0: number)
    prepareDrawing: function()
    updateList: function(dt: number)
end

-- love.keyboard.isDown()
local shortcutsDown: {Shortcut} = {}

-- love.keypressed()
local shortcutsPressed: {Shortcut} = {}

local List = require "list"
local shortcutsList: List = nil

local function combo2str(comboTbl: {any: any}): string
    local res = "["
    for k, v in pairs(comboTbl) do
        res = res .. v as string
        if (k as number) < #comboTbl then
            res = res .. "+"
        end
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

function KeyConfig.bind(btype: BindType, combo: {string}, action: ActionFunc, description: string, id: string|nil)
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

-- очень неподходящее название
-- TODO: работает странно, если определить несколько горячих клавиш, к примеру f1 и f1+lshift
function KeyConfig.keypressed(key: string)
    for _, v in ipairs(shortcutsPressed) do
        if v.enabled then
            -- обрати внимание на магию - первый элемент проверяется на love.keypressed(),
            -- а последущие - как дополнительные модификаторы на lk.isDown()
            local pressed = key == v.combo[1]
            --    print("checkKeyboardInput2", key, v.combo[1])
            --    print("#shortcuts2", #shortcuts2, inspect(shortcuts2))
            for i = 2, #v.combo do
                --        print("checkKeyboardInput2", k, v.combo[i])
                pressed = pressed and lk.isDown(v.combo[i] as love.keyboard.KeyConstant) -- эта строчка что делает? Добавляет проверку модификатора при нажатии клавиш.
                if not pressed then break end
            end
            if pressed and v.action then
                --        print("call action on shortcuts2", inspect(v.combo))
                shortcutsList = nil
                local rebuildlist, newShortcut: boolean, Shortcut = v.action(v)
                if rebuildlist then
                    -- XXX переписывается ли указатель на таблицу v?
                    v = shallowCopy(newShortcut)
                end
            end
        end
    end
end

-- проверка ввода. Используются значения, заранее
-- установленные при помощи bindKey(). Проверка выполняется через lk.isDown()
function KeyConfig.update()
-- а в чем хранить значения keyCombination? как назвать глобальную переменную?
    for _, v in ipairs(shortcutsDown) do
        if v.enabled then
            local pressed = true
            for _, keyValue in ipairs(v.combo) do
                pressed = pressed and lk.isScancodeDown(keyValue as love.keyboard.KeyConstant)
                if not pressed then break end -- если хоть одна клавиша в комбинации не нажата, то сбрасываю комбинацию.      
            end
            if pressed and v.action then 
                shortcutsList = nil
                -- параметры передачи:

                v.action() 
            end -- может какие дополнительные параметры передавать в функцию action()?
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
