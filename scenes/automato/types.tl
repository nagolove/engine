global type Pos = record
    x: number
    y: number
end

global type Cell = record
    pos: Pos
    ip: number
    energy: number
    code: {string}
    moves: {number} -- массив предыдущих положений клетки
    eated: number   -- сколько клетка съела других клеток
    food: boolean   -- является ли клетка едой
end

global type Cells = {Cell}
global type Grid = {{Cell}}
global type GetGridFunction = function(): Grid
global type InitCellFunction = function(any): Cell

