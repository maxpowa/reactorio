local createElement = require("__react__.lib.core").createElement

-- static vars
local MODE_TEXT = 0
local MODE_OPEN_TAG = 1
local MODE_CLOSE_TAG = 2

local function assert(condition, msg)
    if not condition then
        log(msg)
    end
end

local function lsx(s, fields)
    -- Stack of nested tags. Start with a fake top node. The actual top virtual
    -- node would become the first child of this node. We know this element is
    -- going to be invalid, so we ignore the param type mismatch.
    ---@diagnostic disable-next-line: param-type-mismatch
    local stack = { createElement(nil) }

    -- current parsing mode
    local mode = MODE_TEXT

    -- Read and return the next word from the string, starting at position i. If
    -- the string is empty - return the corresponding placeholder field.
    local function readToken(str, i, pattern, field)
        str = str:sub(i)
        if #str == 0 then
            return str, field
        end
        local _, stop, capture = str:find(pattern)
        return str:sub(stop + 1), capture
    end

    while #s > 0 do
        local val
        s = s:gsub("^%s+", "")
        if mode == MODE_TEXT then
            if s:sub(1,1) == "<" then
                if s:sub(2,2) == "/" then
                    s = readToken(s, 3, "(%w+)", fields)
                    mode = MODE_CLOSE_TAG
                else
                    s, val = readToken(s, 2, "(%w+)", fields)
                    stack[#stack + 1] = createElement(val, {})
                    mode = MODE_OPEN_TAG
                end
            else
                s, val = readToken(s, 1, "([^<]+)", "")
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
                s, val = readToken(s, 1, "([%w_-]+)=", "")
                assert(val ~= nil, "Invalid tag name")
                local propName = val
                s, val = readToken(s, 1, '"([^"]*)"', fields)
                stack[#stack].props[propName] = val
            end
        elseif mode == MODE_CLOSE_TAG then
            table.insert(stack[#stack - 1].children, table.remove(stack))
            s = s:sub(2)
            mode = MODE_TEXT
        end
    end
    if mode == MODE_TEXT then
        table.insert(stack[#stack].children, fields)
    end
    return stack[1].children[1]
end


return {
    lsx = lsx
}
