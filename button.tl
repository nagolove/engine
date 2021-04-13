--[[
Сделать простой графический интерфейс. Пока нужны только кнопки с 
событиями.
--]]

--[[
    gooi.components = {}
    gooi.setStyle({ font = self.font,
        showBorder = true,
        bgColor = {0.208, 0.220, 0.222},
    })
    if #self.data == 0 then
        self.backButton = gooi.newButton({ text = i18n("backToMainMenu"),
            x = self.layout.nodata.top.x,
            y = self.layout.nodata.top.y,
            w = self.layout.nodata.top.w,
            h = self.layout.nodata.top.h
        }):onRelease(function()
            menu:goBack()
        end)
    else
        self.backButton = gooi.newButton({ text = i18n("backToMainMenu"),
            x = self.layout.top.x,
            y = self.layout.top.y,
            w = self.layout.top.w,
            h = self.layout.top.h
        }):onRelease(function()
            menu:goBack()
        end)
    end


    gooi.draw()
    gooi.pressed()
    gooi.released()
    gooi.update(dt)
    gooi.keypressed(nil, key, isrepeat)
    gooi.keyreleased(nil, key)
    gooi.pressed() -- in mousepressed
    gooi.released() -- in mouse released

    mainMenuBtn: gooi.Component

    if self.buttons then
        gooi.setStyle({ font = require "fonts".drawstat.gooi,
            showBorder = true,
            bgColor = {0.208, 0.220, 0.222},
        })

        local mainMenuBtnLayout: Layout = (self.layout as {any:any}).mainMenuBtn as Layout
        self.mainMenuBtn = gooi.newButton({ 
            text = i18n("backToMainMenu"),
            x = mainMenuBtnLayout.x, y = mainMenuBtnLayout.y, 
            w = mainMenuBtnLayout.w, h = mainMenuBtnLayout.h
        }):onRelease(function()
            --linesbuf:push(1, "return to main!")
            error("global variable confusion")
            -- XXX fixme
            --menu:goBack()
        end)
    end

    gooi: Gooi

    gooi.setStyle({ font = fonts.help.gooi,
        showBorder = true,
        bgColor = {0.208, 0.220, 0.222},
    })

    self:buildButtons()
    self.gooi = storeGooi() as Gooi

    self.mainMenuBtn = gooi.newButton({ 
        text = i18n("help.backButton"),
        x = mainMenuBtnLayout.x, y = mainMenuBtnLayout.y, 
        w = mainMenuBtnLayout.w, h = mainMenuBtnLayout.h
    }):onRelease(function()
        --linesbuf:push(1, "return to main!")
        menu:goBack()
    end)


function storeGooi(): Gooi
    --local g = { components = deepcopy(gooi.components) }
    --print("gooi.components", inspect(gooi.components))
    --local g = { components = table.deepcopy(gooi.components) }
    local g = { components = gooi.components }
    gooi.components = {}
    return g
end
--]]

local type Button = record
    type Callback = function(Button)

    new: function(title: string, x: number, y: number, w: number, h: number): Button
    draw: function()
    update: function(dt: number)

    title: string
    x: number
    y: number
    w: number
    h: number
    color: {number}

    onRelease: function(f: Callback)
end

local Button_mt: metatable<Button> = {
    __index = Button,
}

function Button.new(title: string, x: number, y: number, w: number, h: number): Button
    local o = setmetatable({} as Button, Button_mt)
    o.title = title
    o.x = x
    o.y = y
    o.w = w
    o.h = h
    o.color = {0.5, 0.1, 0.}
    return o
end

function Button:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Button:update(dt: number)
    
end

return Button
