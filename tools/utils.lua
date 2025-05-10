-- General helper functions (not related to the game own logic)
local utils = {}

utils.boolToValue = function(condition, falsevalue, truevalue)
    return condition and truevalue or falsevalue
end

-- Adds 'm' to 'n' without 'n' getting bigger than 'max' or smaller than 'min':
utils.addInInterval = function(n, m, min, max)
    local sum = n + m
    if max and min then
        if     sum > max then return max
        elseif sum < min then return min
        else   return sum end
    elseif max and not min then
        if     sum > max then return max
        else return sum end
    elseif min and not max then
        if     sum < min then return min
        else return sum end
    end
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