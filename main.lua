local love = require("love")
local mswe = require("tools.minesweeper")
local utls = require("tools.utils")

math.randomseed(os.clock()*717171, os.time()*414141)

-- Assets
local imgs = {
    minespot = love.graphics.newImage("assets/img/minespot.png"),
    flagIndicator= love.graphics.newImage("assets/img/flagIndicator.png")
}
local fonts = {
    bigfont = love.graphics.newFont("assets/fonts/Mousetrap.ttf", 80),
    lilfont = love.graphics.newFont("assets/fonts/Mousetrap.ttf", 20)
}

-- Helpers
local function drawSpot(spot, x, y)
    if spot.state == "visible" then
        local color = utls.boolToInteger(((y - 1)+(x - 1))%2 == 0, {215/255,184/255,153/255}, {229/255,194/255,159/255})
        love.graphics.setColor(utls.unpackLove(color))
        love.graphics.rectangle("fill", Configs.bordermargin+(x-1)*64, Configs.bordermargin+(y-1)*64, 64, 64)
        love.graphics.setColor(0, 0, 0)
        local text = ""
        if spot.surrounded and spot.surrounded > 0 then text = spot.surrounded end
        love.graphics.print(text, Configs.bordermargin+(x-1)*64+20, Configs.bordermargin+(y-1)*64-32)
    else
        local color = utls.boolToInteger(((y - 1)+(x - 1))%2 == 0, {162/255, 209/255, 73/255}, {170/255,215/255,81/255})
        love.graphics.setColor(utls.unpackLove(color))
        love.graphics.rectangle("fill",Configs.bordermargin+(x-1)*64, Configs.bordermargin+(y-1)*64, 64, 64)
        love.graphics.setColor(1, 1, 1)
        if spot.state == "flaged" then
            love.graphics.draw(imgs.flagIndicator, Configs.bordermargin+(x-1)*64, Configs.bordermargin+(y-1)*64)
        end
    end
end
local function drawField(minefield)
    love.graphics.setColor(utls.unpackLove{Configs.boardBorderColor})
    love.graphics.rectangle("fill", Configs.bordermargin-8, Configs.bordermargin-8,#minefield*64+16, #minefield[1]*64+16)
    love.graphics.setFont(fonts.bigfont)

    for x, a in pairs(minefield) do
        for y, spot in pairs(a) do
            drawSpot(spot, x, y)
        end
    end
end
local function newGame()
    Minefield = mswe.createBlankMinefield(Configs.boardx, Configs.boardy)
    for key, _ in pairs(Data.flags) do
        Data.flags[key] = Data.initialFlags[key]()
    end
end

-- Löve callbacks
function love.load()
    -- Graphics Configurations
    love.graphics.setBackgroundColor(1, 1, 1)
    love.graphics.setFont(fonts.bigfont)

    -- Structures
    Configs = {
        boardx = 9,
        boardy = 9,
        boarddensity = 1,
        bordermargin = 64,
        boardBorderColor = {25/255, 25/255, 25/255}
    }
    Data = {
        initialFlags = {
            firstClick = utls.onlyOnce
        },
        flags = {
            firstClick = utls.onlyOnce()
        },
        numGames = 0
    }
    Minefield = newGame()
end

function love.update()

end

function love.draw()
    love.graphics.setColor(0,0,0)
    love.graphics.setFont(fonts.lilfont)
    love.graphics.print(Data.numGames, 0, 0)
    love.graphics.setColor(1,1,1)
    drawField(Minefield)
end

function love.mousepressed(x, y, button)
    local win = true
    for xpos, a in pairs(Minefield) do
        for ypos, spot in pairs(a) do
            if  not spot.state or spot.state ~= "visible" and
                x > Configs.bordermargin+(xpos-1)*64 and
                x < Configs.bordermargin+(xpos-1)*64+64 and
                y > Configs.bordermargin+(ypos-1)*64 and
                y < Configs.bordermargin+(ypos-1)*64+64 then

                if button == 1 and spot.state == "hidden" then
                    spot.state = "visible"
                    if Data.flags.firstClick() then
                        spot.type = "freespot"
                    end
                    if spot.type == "minespot" then
                        newGame()
                    end
                    if spot.surrounded == 0 then
                        mswe.freeZeroFreespots(xpos, ypos, Minefield)
                    end
                elseif button == 2 then
                    if spot.state == "hidden" then
                        spot.state = "flaged"
                    else
                        spot.state = "hidden"
                    end
                end
            end
            if spot.state == "hidden" then win = false end
        end
    end
    if win == true then
        newGame()
    end
end

function love.keypressed(k)
    do -- debug
        if k == "n" then
            newGame()
        end
    end
end