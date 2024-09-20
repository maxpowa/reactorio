local EMPTY_OBJ = {}

-- a function component that just renders its children directly
local function Fragment(props)
    return props.children
end

return {
    EMPTY_OBJ = EMPTY_OBJ,
    Fragment = Fragment,
}