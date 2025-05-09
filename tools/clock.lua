local clock = {}

-- Silly as hell, returns an empty table
clock.newClock = function()
    return {}
end
-- Runs and deal with every clock in 'forClock'
clock.runClock = function(forClock, deltaTime)
    for name, timer in pairs(forClock) do
        if timer.type == "constevent" then
            timer.time = timer.time - deltaTime

            if timer.time <= 0 then
                timer.callback()
                timer.time = timer.fulltime
            end
        else
           timer.time = timer.time - deltaTime

            if timer.type == "untilEnd" then
                if timer.callback then
                    timer.callback()
                end
            end

            if timer.time <= 0 then
                if timer.callback and timer.type == "atEnd" then
                    timer.callback()
                end

                forClock[name] = nil
            end
        end
    end
end
-- Adds a new timer to 'toClock': types: "atEnd", "untilEnd", "constantEvent"
clock.addTimer = function(toClock, seconds, callback, type, name)
    local t = type or "atEnd"
    toClock[name] = {time=seconds, callback=callback, type=t}
end
-- Adds a constant event that will call ```callback``` every ```delay``` seconds.
clock.addConstevent = function(toClock, callback, delay, name)
    toClock[name] = {time=delay, fulltime=delay, callback=callback, type="constevent"}
end
-- Takes ```name``` instance out of ```fromClock```
clock.stopInstance = function(fromClock, name)
    fromClock[name] = nil
end

return clock