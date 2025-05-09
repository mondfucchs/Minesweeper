-- General helper functions (not related to the game own logic)
local utils = {}

utils.boolToValue = function(condition, falsevalue, truevalue)
    return condition and truevalue or falsevalue
end

-- Rounds 'm' to the nearest 'n' multiple
utils.roundTo = function(m, n)
    return math.floor(m / n) * n
end

-- Unpacks a table 't', starting at '_i'
utils.unpackLove = function(t, _i)
    local i = _i or 1
    local n = #t
    if i > n then
        return nil
    end
    return t[i], utils.unpackLove(t, i + 1)
end

-- Returns a function that returns true only once
utils.onlyOnce = function()
    local used = false
    return function()
        if used == false then used = true; return true else return false end
    end
end

return utils