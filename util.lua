arr = {}
tbl = {}
function tbl.merge(tbl1, tbl2)
    local result = {}
    for k, v in pairs(tbl1) do
        result[k] = v
    end
    for k, v in pairs(tbl2) do
        result[k] = v
    end
    return result
end

-- Array utility functions
function arr.map(tbl, func)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = func(v, i)
    end
    return result
end

function arr.filter(tbl, func)
    local result = {}
    for i, v in ipairs(tbl) do
        if func(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

function arr.some(tbl, func)
    for i, v in ipairs(tbl) do
        if func(v, i) then
            return true
        end
    end
    return false
end

function arr.is_array(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

-- predicate functions to be used with filter
function isEvent(prev, next)
    return function(key)
        return key:find("on_") == 1
    end
end

function isNew(prev, next)
    return function(key)
        return prev[key] ~= next[key]
    end
end

function isGone(prev, next)
    return function(key)
        return not next[key]
    end
end