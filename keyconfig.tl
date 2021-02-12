-- lk.isDown()
require "love"
local lk = love.keyboard
local lg = love.graphics

local record Shortcut
    combo: {string}
    action: function
    description: string
    enabled: boolean
end

global type KeyConfig = record
    send: function(stringID: string)
    bindKeyDown: function(stringID: string, keyCombination: {string}, action: function, description: string)
    bindKeyPressed: function(stringID: string, keyCombination: {string}, action: function, description: string)
    checkDownKeys: function()
    checkPressedKeys: function(key: string)
    drawList: function()
    drawShortcutsList: function(x0: number, y0: number)
    prepareDrawing: function()
    updateList: function(dt: number)
end

-- love.keyboard.isDown()
local shortcutsDown: {string: Shortcut} = {}

-- love.keypressed()
local shortcutsPressed: {string: Shortcut} = {}

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
    for k, v in pairs(shortcutsDown) do
        shortcutsList:add(v.description .. " " .. combo2str(v.combo), k)
    end
    for k, v in pairs(shortcutsPressed) do
        shortcutsList:add(v.description .. " " .. combo2str(v.combo), k)
    end
    table.sort(shortcutsList.items, function(a: List.Item, b: List.Item): boolean
        return a.id < b.id
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

    --drawList(list1) 
    --drawList(list2)
    lg.setFont(tmpFont)
end

-- usage example:
-- bindKey({"q"}, quit)
-- bindKey({"lshift", "x"}, changeCameraMode)
-- use scancode
function KeyConfig.bindKeyDown(stringID: string, keyCombination: {string}, action: function, description: string)
  assert(action, "action == nil in bindKey()")
  assert(stringID, "stringID should'not be empty")
  assert(action, "action == nil in bindKeyDown()")

  --[[здесь добавить проверки в таблице keyCombination на допустимость 
  закодированных в них сочетаний. Если сочетание клавиш используется, то 
  вызывать исключение, которое в идеале может обработать вызывающая 
  функция.
  --]]

--  assert(shortcuts[stringID]) -- слот должен быть пустой
--  assert(description, "description == nil in bindKey()")
  -- извлечь из keyCombination значения
  -- проверить на дубликаты
  description = description and description or ""
  shortcutsDown[stringID] = {combo = keyCombination, action = action, 
    description = description, enabled = true}
end

function KeyConfig.bindKeyPressed(stringID: string, keyCombination: {string}, action: function, description: string)
  assert(action, "action == nil in bindKeyPressed()")
  assert(description, "description == nil in bindKeyPressed()")
  shortcutsPressed[stringID] = {combo = keyCombination, action = action, 
    description = description, enabled = true}
end

-- очень неподходящее название
-- TODO: работает странно, если определить несколько горячих клавиш, к примеру f1 и f1+lshift
function KeyConfig.checkPressedKeys(key: string)
    for _, v in pairs(shortcutsPressed) do
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
                v.action()
            end
        end
    end
end

-- проверка ввода. Используются значения, заранее
-- установленные при помощи bindKey(). Проверка выполняется через lk.isDown()
function KeyConfig.checkDownKeys()
-- а в чем хранить значения keyCombination? как назвать глобальную переменную?
    for _, v in pairs(shortcutsDown) do
        if v.enabled then
            local pressed = true
            for _, keyValue in ipairs(v.combo) do
                pressed = pressed and lk.isScancodeDown(keyValue as love.keyboard.KeyConstant)
                if not pressed then break end -- если хоть одна клавиша в комбинации не нажата, то сбрасываю комбинацию.      
            end
            if pressed and v.action then 
                shortcutsList = nil
                v.action() 
            end -- может какие дополнительные параметры передавать в функцию action()?
        end
    end
end

function KeyConfig.send(stringID: string)
    local t = shortcutsDown[stringID]
    if t and t.enabled and t.action then
        t.action()
    else
        t = shortcutsPressed[stringID]
        if t and t.enabled and t.action then 
            t.action() 
        end
    end
end

return KeyConfig
