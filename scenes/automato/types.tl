require "mtschemes"

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
    wantdivide: boolean
end

global type CellSetup = record
    pos: Pos
    code: {string}
end

global type Cells = {Cell}
global type Grid = {{Cell}}
global type GetGridFunction = function(): Grid
global type InitCellFunction = function(any): Cell

global type CellActionsInit = record
    threadNum: number
    getGrid: GetGridFunction
    gridSize: number
    initCell: InitCellFunction
    schema: MtSchema
end

global type Statistic = record
    allEated: number
    maxEnergy: number
    minEnergy: number
    midEnergy: number
    iterAverage: number
end

global type DrawNode = record
    x: number
    y: number
    food: boolean
end

global type CommonSetup = record
    gridSize: number
    cellsNum: number
    initialEnergy: {number, number}
    codeLen: number
    threadCount: number
end


