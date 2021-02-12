--[[
Название скрипта пока не точное.

Скачивает в каталог scenes/discord/ love-проект командой git clone
Если есть файл main.lua, то заменяет в нем love.function на функции движка.
Добавляет возвращаемую таблицу обработчиков в конец файла.

Обработка нескольких уровней вложенности. Пример - подкаталог examples в корне
проекта.

Добавить новую строчку в загрузчик сцен(загрузчик проектов).
Listbox для выбора проекта(сцены)

--]]


--[[
Найти:

love.displayrotated
love.draw
love.errhand
love.errorhandler
love.load
love.lowmemory
love.quit
love.run
love.threaderror
love.update

Window

love.directorydropped
love.filedropped
love.focus
love.mousefocus
love.resize
love.visible

Keyboard

love.keypressed
love.keyreleased
love.textedited
love.textinput

Mouse

love.mousemoved
love.mousepressed
love.mousereleased
love.wheelmoved

Joystick

love.gamepadaxis
love.gamepadpressed
love.gamepadreleased
love.joystickadded
love.joystickaxis
love.joystickhat
love.joystickpressed
love.joystickreleased
love.joystickremoved

Touch

love.touchmoved
love.touchpressed
love.touchreleased

Заменить на соответствующие обработчики без префикса love. Возможен конфликт 
имен. Пример замены:

function love.draw()
local function draw()

love.draw = function(arg1, arg2)
local draw = function(arg1, arg2)

Переименовать файл из main.lua в init.lua
Хотя можно обойтись и без переименования?
]]
