local love = require("love")
local mswe = require("tools.minesweeper")
local utls = require("tools.utils")
local cloc = require("tools.clock")

-- Assets
local imgs = {
    minespot = love.graphics.newImage("assets/img/minespot.png"),
    flagIndicator = love.graphics.newImage("assets/img/flagIndicator.png"),
    configs = love.graphics.newImage("assets/img/configs.png"),
}
Sounds = {
    dig_spot = love.audio.newSource("assets/sound/dig_spot.wav", "static"),
    big_dig = love.audio.newSource("assets/sound/big_dig.wav", "static"),
    put_flag = love.audio.newSource("assets/sound/put_flag.wav", "static"),
    explosion = love.audio.newSource("assets/sound/explosion.wav", "static"),
    win = love.audio.newSource("assets/sound/win.wav", "static"),
    blip = love.audio.newSource("assets/sound/blip.wav", "static")
}
local fonts = {
    bigfont = love.graphics.newFont("assets/fonts/Mousetrap.ttf", 80),
    midfont = love.graphics.newFont("assets/fonts/Mousetrap.ttf", 40),
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
    love.graphics.rectangle("fill", Configs.x-8, Configs.y-8, #minefield*64+16, #minefield[1]*64+16)
    love.graphics.setFont(fonts.bigfont)

    for x, a in pairs(minefield) do
        for y, spot in pairs(a) do
            drawSpot(spot, x, y)
        end
    end
end
local function newGame()
    math.randomseed(tonumber(Data.options[3].value) or os.clock()*717171)
    Mainclock = cloc.newClock()

    Configs.x = love.graphics.getWidth()/2 - (Data.options[1].value*64)/2
    Configs.y = love.graphics.getHeight()/2 - (Data.options[2].value*64)/2

    Data.numGames = Data.numGames+1
    Data.flagcount = 0
    Data.mouseactive = true

    return mswe.createBlankMinefield(Data.options[1].value, Data.options[2].value)
end
local function checkWin(minefield)
    for xpos, a in pairs(minefield) do
        for ypos, spot in pairs(a) do
            if (spot.state == "hidden" and spot.type == "freespot") or (spot.state == "flaged" and spot.state == "freespot") or spot.type == "blankspot" then
                return false
            end
        end
    end
    return true
end
local function winGame()
    Data.mouseactive = false
    cloc.addTimer(Mainclock, 2.6, function() Minefield = newGame() end, "atEnd", "waitrestart")
    if Data.options[6].value == 1 then
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
end
local function loseGame()
    Data.mouseactive = false
    local xvel, time = 0, 0
    local initx = Configs.x - 32
    local animation_time = 0

    if Data.options[6].value == 1 then
        for x, a in pairs(Minefield) do
            for y, spot in pairs(a) do
                if spot.state == "hidden" or (spot.state == "flaged" and spot.type == "freespot") then
                    animation_time = animation_time+1
                    cloc.addTimer(Mainclock, (animation_time)/16, function() spot.state = "visible"; love.audio.play(Sounds.dig_spot) end, "atEnd", "ANIMATvisibleboard" .. x .. y)                
                end
            end
        end

        cloc.addTimer(Mainclock, animation_time/16+1, function()
            cloc.addTimer(Mainclock, 4, function()
            time = time+1
            xvel = ((time-12)^2+144)*0.1
            Configs.x = initx+xvel
        end, "untilEnd", "ANIMATtakeboardout") end, "atEnd", "waitANIMATtakeboardout"
        )
    else
        for x, a in pairs(Minefield) do
            for y, spot in pairs(a) do
                if spot.state == "hidden" or (spot.state == "flaged" and spot.type == "freespot") then
                    spot.state = "visible"
                end
            end
        end
    end
    cloc.addTimer(Mainclock, animation_time/16+5.1, function() Minefield = newGame() end, "atEnd", "waitrestart")
end

-- Löve callbacks
function love.load()
    -- Graphics Configurations
    love.graphics.setBackgroundColor(1, 1, 1)
    love.graphics.setFont(fonts.bigfont)

    -- Structures
    do -- data
        Data = {
            flagcount = 0,
            numGames = 0,
            mouseactive = true,
            gamestate = "play",
            selected_option = 1,
            options = {},
        }
        table.insert(Data.options, {name="Board width", value=9, max=9, min=1, reset=true})
        table.insert(Data.options, {name="Board height", value=9, max=9, min=1, reset=true})
        table.insert(Data.options, {name="Seed", value="", reset=true})
        table.insert(Data.options, {name="Mine density (0 to 100)", value="20", reset=true})
        table.insert(Data.options, {name="Volume", value=6, max=10, min=0, reset=false})
        table.insert(Data.options, {name="Animations", value=1, max=1, min=0, reset=false})
    end
    Configs = {
        x = 64,
        y = 64,
        board_border_color = {25/255, 25/255, 25/255}
    }
    Minefield = newGame()
    Mainclock = cloc.newClock()
end
function love.update(dt)
    if Data.gamestate == "play" then
        cloc.runClock(Mainclock, dt)        
    end
end
function love.draw()
    if Data.gamestate == "play" then
        love.graphics.setColor(0,0,0)
        love.graphics.setFont(fonts.lilfont)
        love.graphics.printf(math.floor(tonumber(Data.options[4].value)/100*Data.options[1].value*Data.options[2].value)-Data.flagcount, 0, Configs.y-52, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,1,1)
        drawField(Minefield)
        love.graphics.setFont(fonts.lilfont)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("(E) to access options - (N) to start a new game", 0, love.graphics.getWidth()-48, love.graphics.getWidth(), "center")

    else
        love.graphics.setFont(fonts.bigfont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("OPTIONS", 0, 64, love.graphics.getWidth(), "center")

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(imgs.configs, (love.graphics.getWidth())/2-12, 196)
        love.graphics.setColor(0, 0, 0)

        love.graphics.setFont(fonts.midfont)
        for i, option in pairs(Data.options) do
            if i == Data.selected_option then
                love.graphics.setColor(50/255, 120/255, 160/255)
            end
            love.graphics.print(option.name, 64, 256+(i-1)*58)
            love.graphics.print(option.value, love.graphics.getWidth()-64-fonts.midfont:getWidth(option.value), 256+(i-1)*58)
            love.graphics.setColor(0, 0, 0)
        end

        love.graphics.setFont(fonts.lilfont)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("made with LÖVE and LOVE by mondfuchs", 0, love.graphics.getWidth()-48, love.graphics.getWidth(), "center")
    end
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

                    -- premature win, miserable little darning exceptions
                    if math.floor(tonumber(Data.options[4].value/100) * Data.options[1].value * Data.options[2].value) == 0 then
                        cloc.addTimer(Mainclock, 0.3, function() love.audio.play(Sounds.win) end, "atEnd", "waitwin")
                        winGame()
                    end

                    if button == 2 then
                        love.audio.play(Sounds.put_flag)
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
            end
            if notPopulated.bool then love.audio.play(Sounds.dig_spot); break end
        end
        if notPopulated.bool then
            Minefield = mswe.populateMinefield(Minefield, tonumber(Data.options[4].value)/100, notPopulated.x, notPopulated.y)
            if Minefield[notPopulated.x][notPopulated.y].surrounded == 0 then mswe.freeZeroFreespots(notPopulated.x, notPopulated.y, Minefield) end
        end
        if checkWin(Minefield) == true then
            love.audio.play(Sounds.win)
            winGame()
        end
    end
end
function love.keypressed(k)
    if Data.gamestate == "options" then
        if k == "e" then
            Data.gamestate = "play"
            Data.mouseactive = true
            for _, sound in pairs(Sounds) do
                sound:setVolume(Data.options[5].value/10)
            end
            if not tonumber(Data.options[4].value) then Data.options[4].value = "20" end
        end
        if k == "s" or k == "down" then
            Data.selected_option = utls.addInInterval(Data.selected_option, 1, 1, #Data.options)
        elseif k == "w" or k == "up" then
            Data.selected_option = utls.addInInterval(Data.selected_option, -1, 1, #Data.options)
        end
        if Data.selected_option == 3 then
            if tonumber(k) and #Data.options[3].value <= 20 then
                Data.options[3].value = Data.options[3].value .. k
                Minefield = newGame()
            elseif k == "backspace" then
                Data.options[3].value = string.sub(Data.options[3].value, 1, #Data.options[3].value-1)
                Minefield = newGame()
            end
        elseif Data.selected_option == 4 then
            if tonumber(k) and tonumber(Data.options[4].value .. k) <= 100 and #Data.options[4].value+1 <= 3 then
                Data.options[4].value = Data.options[4].value .. k
                Minefield = newGame()
            elseif k == "backspace" then
                Data.options[4].value = string.sub(Data.options[4].value, 1, #Data.options[4].value-1)
                Minefield = newGame()
            end
        else
            if k == "d" or k == "right" then
                love.audio.play(Sounds.blip)
                Data.options[Data.selected_option].value = utls.addInInterval(Data.options[Data.selected_option].value, 1, Data.options[Data.selected_option].min, Data.options[Data.selected_option].max)
                if Data.options[Data.selected_option].reset then Minefield = newGame() end
            elseif k == "a" or k == "left" then
                love.audio.play(Sounds.blip)
                Data.options[Data.selected_option].value = utls.addInInterval(Data.options[Data.selected_option].value, -1, Data.options[Data.selected_option].min, Data.options[Data.selected_option].max)
                if Data.options[Data.selected_option].reset then Minefield = newGame() end
            end
        end
    elseif Data.gamestate == "play" then
        if k == "e" then
            Data.gamestate = "options"
            Data.mouseactive = false
        elseif k == "n" then
            love.audio.play(Sounds.blip)
            Minefield = newGame()
        end
    end
end