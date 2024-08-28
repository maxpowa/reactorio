local createElement = require("__react__.lib.core").createElement

-- static vars
local MODE_TEXT = 0
local MODE_OPEN_TAG = 1
local MODE_CLOSE_TAG = 2

local function assert(condition, msg)
    if not condition then
        error(msg)
    end
end

--- Parse a string of LSX into a virtual node tree
--- 
--- @param s string the LSX string to parse
--- @param values table|nil the values to interpolate into the LSX string
---
--- @return table vdom the virtual dom tree
local function lsx(s, values)
    values = values or {}
    -- Stack of nested tags. Start with a fake top node. The actual top virtual
    -- node would become the first child of this node. We know this element is
    -- going to be invalid, so we ignore the param type mismatch.
    ---@diagnostic disable-next-line: param-type-mismatch
    local stack = { createElement(nil) }

    -- current parsing mode
    local mode = MODE_TEXT

    --- Read and return the next word from the string, starting at position i. If
    --- the string is empty - return the corresponding placeholder field.
    --- 
    --- @param str string the string to read from
    --- @param pattern string the pattern to match
    --- 
    --- @return string, string|unknown
    local function readToken(str, pattern)
        if #str == 0 then
            return str, nil
        end
        local _, stop, capture = str:find(pattern)
        if type(capture) == "string" then
            if capture:sub(1,1) == "$" then
                -- interpolate the whole value to the provided table value
                local key = capture:find("($%b{})")
                if key then
                    capture = values[capture:sub(3, -2)]
                end
            else
                -- interpolate just the segment of string to the provide table value
                capture = capture:gsub("($%b{})", function(key)
                    return values[key:sub(3, -2)] or key
                end)
            end
        end
        return str:sub(stop + 1), capture
    end

    while #s > 0 do
        local val
        s = s:gsub("^%s+", "")
        if mode == MODE_TEXT then
            if s:sub(1,1) == "<" then
                if s:sub(2,2) == "/" then
                    s = readToken(s:sub(3), "(%w+)")
                    mode = MODE_CLOSE_TAG
                else
                    s, val = readToken(s:sub(2), "(%w+)")
                    assert(val ~= nil, "Invalid tag name")
                    stack[#stack + 1] = createElement(val, {})
                    mode = MODE_OPEN_TAG
                end
            else
                s, val = readToken(s:sub(1), "([^<]+)")
                table.insert(stack[#stack].children, val)
            end
        elseif mode == MODE_OPEN_TAG then
            if s:sub(1,1) == "/" and s:sub(2,2) == ">" then
                table.insert(stack[#stack - 1].children, table.remove(stack))
                mode = MODE_TEXT
                s = s:sub(3)
            elseif s:sub(1,1) == ">" then
                mode = MODE_TEXT
                s = s:sub(2)
            else
                s, val = readToken(s:sub(1), "([%w_-]+)=")
                assert(val ~= nil, "Invalid param name")
                local propName = val
                s, val = readToken(s:sub(1), '"([^"]*)"')
                stack[#stack].props[propName] = val
            end
        elseif mode == MODE_CLOSE_TAG then
            table.insert(stack[#stack - 1].children, table.remove(stack))
            s = s:sub(2)
            mode = MODE_TEXT
        end
    end
    if mode == MODE_TEXT then
        table.insert(stack[#stack].children, s)
    end
    return stack[1].children[1]
end


return {
    lsx = lsx
}
