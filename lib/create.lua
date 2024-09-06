---@class VNode
local VNode = {
    type = type,
    props = {},
    key = "",
    ref = {},
    _children = nil,
    _parent = nil,
    _depth = 0,
    _dom = nil,
    _nextDom = nil,
    ---@type Component|nil
    _component = nil,
    _original = nil,
    _index = -1,
    _hydrating = false,
}

local vnodeId = 0
function VNode:create(type, props, key, ref, original)
    if not original then
        vnodeId = vnodeId + 1
        original = vnodeId
    end
    local o = {
        type = type,
        props = props,
        key = key,
        ref = ref,
		_original = original,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- A function that creates a virtual element for rendering. Alternatively, you can use the shorthand `h` function, or JSX.
---
--- @param type GuiElementType|function the type of element to create
--- @param props? table a table of properties to set on the element
--- @param ... table|string children - may be strings or other `createElement` results
--- @return VNode VNode virtual element node(s) (vnodes are implementation details and should not be accessed directly)
---
--- @see https://react.dev/reference/react/createElement
local function createElement(type, props, ...)
    local normalizedProps, key, ref = {}, nil, nil
    for k, v in pairs(props) do
        if k == "key" then
            key = v
        elseif k == "ref" then
            ref = v
        else
            normalizedProps[k] = v
        end
    end
    
    if #... > 0 then
        normalizedProps.children = ...
    end

    return VNode:create(type, normalizedProps, key, ref, nil)
end

local function createRef()
    return { current = nil }
end

-- a function component that just renders its children directly
local function Fragment(props)
    return props.children
end

--- A function that creates a "react_root" element. This is used as a container for the element tree in `render`.
---
--- @param parent LuaGuiElement the parent element to add the root to (e.g. `player.gui.screen`)
--- @param props? table a table of properties to set on the root element (you should not need to)
---
--- @return LuaGuiElement root the root element
local function createRoot(parent, props)
    if parent["react_root"] then
        parent["react_root"].destroy()
    end
    return parent.add(merge(props or {}, { type = "flow", name = "react_root", }))
end

return {
    createRoot = createRoot,
    createElement = createElement,
    createRef = createRef,
    Fragment = Fragment
}