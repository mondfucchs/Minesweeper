local love = require("love")
local mswe = require("tools.minesweeper")
local utls = require("tools.utils")
local cloc = require("tools.clock")

math.randomseed(os.clock()*717171, os.time()*414141)

-- Assets
local imgs = {
    minespot = love.graphics.newImage("assets/img/minespot.png"),
    flagIndicator= love.graphics.newImage("assets/img/flagIndicator.png")
}
Sounds = {
    dig_spot = love.audio.newSource("assets/sound/dig_spot.wav", "static"),
    big_dig = love.audio.newSource("assets/sound/big_dig.wav", "static"),
    explosion = love.audio.newSource("assets/sound/explosion.wav", "static")
}
local fonts = {
    bigfont = love.graphics.newFont("assets/fonts/Mousetrap.ttf", 80),
    lilfont = love.graphics.newFont("assets/fonts/Mousetrap.ttf", 20)
}

-- Helpers
local function drawSpot(spot, x, y)
    if spot.state == "visible" then
        if spot.type ~= "minespot" then
            local color = utls.boolToValue(((y - 1)+(x - 1))%2 == 0, {215/255,184/255,153/255}, {229/255,194/255,159/255})
            love.graphics.setColor(utls.unpackLove(color))
            love.graphics.rectangle("fill", Configs.x+(x-1)*64, Configs.y+(y-1)*64, 64, 64)
            love.graphics.setColor(0, 0, 0)
            local text = ""
            if spot.surrounded and spot.surrounded > 0 then text = spot.surrounded end
            love.graphics.print(text, Configs.x+(x-1)*64+20, Configs.y+(y-1)*64-32)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(imgs.minespot, Configs.x+(x-1)*64, Configs.y+(y-1)*64)
        end
    else
        local color = utls.boolToValue(((y - 1)+(x - 1))%2 == 0, {162/255, 209/255, 73/255}, {170/255,215/255,81/255})
        love.graphics.setColor(utls.unpackLove(color))
        love.graphics.rectangle("fill",Configs.x+(x-1)*64, Configs.y+(y-1)*64, 64, 64)
        love.graphics.setColor(1, 1, 1)
        if spot and spot.state == "flaged" then
            love.graphics.draw(imgs.flagIndicator, Configs.x+(x-1)*64, Configs.y+(y-1)*64)
        end
    end
end
local function drawField(minefield)
    love.graphics.setColor(utls.unpackLove{Configs.board_border_color})
    love.graphics.rectangle("fill", Configs.x-8, Configs.y-8,#minefield*64+16, #minefield[1]*64+16)
    love.graphics.setFont(fonts.bigfont)

    for x, a in pairs(minefield) do
        for y, spot in pairs(a) do
            drawSpot(spot, x, y)
        end
    end
end
local function newGame()
    Data.numGames = Data.numGames+1
    Data.flagcount = 0
    Data.mouseactive = true
    local minefield = mswe.createBlankMinefield(Configs.boardx, Configs.boardy)
    return minefield
end
local function winGame()
    cloc.addTimer(Mainclock, 2.6, function() Minefield = newGame() Configs.y = 64 end, "atEnd", "waitrestart")
    local yvel, time = 0, 0
    local inity = Configs.y - 32
    cloc.addTimer(Mainclock, 0.5, function()
        cloc.addTimer(Mainclock, 2, function()
        time = time+1
        yvel = ((time-12)^2+144)*0.1
        Configs.y = inity+yvel
        end, "untilEnd", "ANIMATtakeboardout") end, "atEnd", "waitANIMATtakeboardout"
    )
end
local function loseGame()
    Data.mouseactive = false
    local xvel, time = 0, 0
    local initx = Configs.x - 32
    local animation_time = 0

    for x, a in pairs(Minefield) do
        for y, spot in pairs(a) do
            if spot.state == "hidden" or (spot.state == "flaged" and spot.type == "freespot") then
                animation_time = animation_time+1
                cloc.addTimer(Mainclock, (animation_time)/16, function() spot.state = "visible"; love.audio.play(Sounds.dig_spot) end, "atEnd", "ANIMATvisibleboard" .. x .. y)                
            end
        end
    end

    cloc.addTimer(Mainclock, animation_time/16+5.1, function() Minefield = newGame(); Configs.x = 64 end, "atEnd", "waitrestart")
    cloc.addTimer(Mainclock, animation_time/16+1, function()
        cloc.addTimer(Mainclock, 4, function()
        time = time+1
        xvel = ((time-12)^2+144)*0.1
        Configs.x = initx+xvel
    end, "untilEnd", "ANIMATtakeboardout") end, "atEnd", "waitANIMATtakeboardout"
    )
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
        board_density = 0.2,
        x = 64,
        y = 64,
        board_border_color = {25/255, 25/255, 25/255}
    }
    Data = {
        flagcount = 0,
        numGames = 0,
        mouseactive = true,
    }
    Minefield = newGame()
    Mainclock = cloc.newClock()
end
function love.update(dt)
    cloc.runClock(Mainclock, dt)
end
function love.draw()
    love.graphics.setColor(0,0,0)
    love.graphics.setFont(fonts.lilfont)
    love.graphics.printf(math.floor(Configs.board_density*Configs.boardx*Configs.boardy)-Data.flagcount, 64, 12, #Minefield*64, "center")
    love.graphics.setColor(1,1,1)
    drawField(Minefield)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(#Mainclock)
end
function love.mousepressed(x, y, button)
    if Data.mouseactive then
        local win = true
        local notPopulated = {bool=false, x=1, y=1}
        for xpos, a in pairs(Minefield) do
            for ypos, spot in pairs(a) do
                if  spot.state ~= "visible" and
                    x > Configs.x+(xpos-1)*64 and
                    x < Configs.x+(xpos-1)*64+64 and
                    y > Configs.y+(ypos-1)*64 and
                    y < Configs.y+(ypos-1)*64+64 then

                    if button == 2 then
                        if spot.state == "hidden" then
                            spot.state = "flaged"
                            Data.flagcount = Data.flagcount + 1
                        else
                            spot.state = "hidden"
                            Data.flagcount = Data.flagcount - 1
                        end
                    end

                    if spot.type == "blankspot" and button==1 then notPopulated = {bool=true, x=xpos, y=ypos} break end

                    if button == 1 and spot.state == "hidden" then
                        love.audio.play(Sounds.dig_spot)
                        spot.state = "visible"
                        if spot.type == "minespot" then
                            win = false
                            love.audio.play(Sounds.explosion)
                            loseGame()
                        end
                        if spot.surrounded == 0 then
                            mswe.freeZeroFreespots(xpos, ypos, Minefield)
                            love.audio.play(Sounds.big_dig)
                        end
                    end
                end
                if spot.state == "hidden" then win = false end
            end
            if notPopulated.bool then love.audio.play(Sounds.dig_spot); break end
        end
        if notPopulated.bool then
            Minefield = mswe.populateMinefield(Minefield, Configs.board_density, notPopulated.x, notPopulated.y)
            if Minefield[notPopulated.x][notPopulated.y].surrounded == 0 then mswe.freeZeroFreespots(notPopulated.x, notPopulated.y, Minefield) end
        end
        if win == true and not notPopulated.bool then
            winGame()
        end 
    end
end
function love.keypressed(k)
    do -- debug
        if k == "n" then
            Minefield = newGame()
        end
    end
end