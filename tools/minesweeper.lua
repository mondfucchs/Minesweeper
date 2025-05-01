-- File where the core functions and logic are contained.
local love = require("love")
local minesweeper = {}

--#region Spots
local function newFreespot()
    return {
        type="freespot",
        state="hidden",
        surrounded=0
    }
end
local function newMinespot()
    return {
        type="minespot",
        state="hidden", -- hidden visible
    }
end
local function surroundingMinespots(w, h, spot, minefield)
    for dw = -1, 1 do
        for dh = -1, 1 do
            if not (dw == 0 and dh == 0) then
                local nw, nh = w + dw, h + dh
                if minefield[nw] and minefield[nw][nh] and minefield[nw][nh].type == "minespot" then
                    minefield[w][h].surrounded = minefield[w][h].surrounded + 1
                end
            end
        end
    end
end
local function freeZeroFreespots(w, h, minefield)
    for dw = -1, 1 do
        for dh = -1, 1 do
            if not (dw == 0 and dh == 0) then
                local nw, nh = w + dw, h + dh
                if minefield[nw] and minefield[nw][nh] and minefield[nw][nh].state == "hidden" then
                    minefield[nw][nh].state = "visible"
                    if minefield[nw][nh].surrounded == 0 then
                    freeZeroFreespots(nw, nh, minefield)
                    end
                end
            end
        end
    end
end
--#endregion

-- Return a new minefield ```width```x```height``` with ```minecount``` mines.
minesweeper.createMinefield = function(width, height, minedensity)
    local _minecount = math.floor(minedensity * width * height)
    local minefield = {}
    local minefield_size = width*height

    -- Create a chained table with minespots and freepots
    local minefield_distribution = {}
    for _=1, _minecount do
        table.insert(minefield_distribution, newMinespot)
    end
    for _=1, minefield_size - _minecount do
        table.insert(minefield_distribution, newFreespot)
    end

    -- Populate minefield
    for w = 1, width do
        minefield[w] = {}
        for h = 1, height do
            local random_index = math.random(#minefield_distribution)
            minefield[w][h] = minefield_distribution[random_index]()
            table.remove(minefield_distribution, random_index)
        end
    end

    -- Complete freespots's data
    for w = 1, width do
        for h = 1, height do
            if minefield[w][h].type == "freespot" then surroundingMinespots(w, h, minefield[w][h], minefield) end
        end
    end

    return minefield
end
minesweeper.freeZeroFreespots = freeZeroFreespots

return minesweeper