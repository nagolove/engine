require 'love'

local names: {string: number} = {}

-- записывает на диск изображения полотен, не более чем maxFilesNum 
-- экземпляров.
-- TODO Добавить ротацию картинок
local function writeCanvas2Disk(
    cnv: love.graphics.Canvas,
    name: string, 
    maxFilesNum: number)

    assert(string.find(name, '%%d') ~= nil)
    if not names[name] then
        names[name] = 0
    end

    if names[name] < maxFilesNum then
        names[name] = names[name] + 1
        cnv:newImageData():encode('png', string.format(name, names[name]))
    end
end

return {
    writeCanvas2Disk = writeCanvas2Disk,
}
