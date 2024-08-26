-- Reactorio (React for Factorio) core logic

if ... ~= "__react__.lib.core" then
    return require("__react__.lib.core")
end

-- TODO: Support Fragments, to allow returning multiple elements from a function component

-- Explicit imports here prevent scope pollution
local createScopedHandler = require "__react__.lib.events".createScopedHandler
local enableHookContext = require "__react__.lib.hooks".enableHookContext
local disableHookContext = require "__react__.lib.hooks".disableHookContext

-- Helper functions since I'm a filthy typescript user and I can't live without certain niceties
local function merge(tbl1, tbl2)
    local result = {}
    for k, v in pairs(tbl1) do
        result[k] = v
    end
    for k, v in pairs(tbl2) do
        result[k] = v
    end
    return result
end
local function is_array(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function addElementToParent(v, parent, index)
    if (v.type ~= nil) then
        local props = {}

        -- omit event handlers from props
        for k, _ in pairs(v.props or {}) do
            if (k:find("on_gui_") ~= 1 and k ~= "ref") then
                props[k] = v.props[k]
            end
        end

        return parent.add(merge(props, { type = v.type, index = index }))
    elseif (type(v) == "string") then
        return parent.add({ type = "label", caption = v, index = index })
    else
        error("Invalid element: " .. serpent.line(v))
    end
end

local function compareNodeProp(node, k, v)
    -- Wube, WHY?!
    if (node.type == "slider" and k == "value") then
        return node.slider_value ~= v
    end
    return node[k] ~= v
end

--- Renders a virtual element tree to a parent element
---
--- @param vlist table list of virtual elements, created by React.createElement
--- @param parent LuaGuiElement element to render to
--- @param storage? table hook storage (required if rendering element tree from different sources, e.g. in both on_gui_opened and on_gui_closed)
---
--- @see createElement
local function render(vlist, parent, storage)
    if not is_array(vlist) then
        vlist = { vlist }
    end

    -- initialize storage if not present
    if not storage then
        storage = { hooks = {}, event_handlers = {} }
    end
    -- capture current hook storage
    local hs = storage.hooks or {}
    -- clear hook storage global
    storage.hooks = {}

    local ids = {}
    for i, vnode in ipairs(vlist) do
        local forceUpdate = function() return render(vlist, parent, storage) end

        while (type(vnode.type) == "function") do
            local k = vnode.props and vnode.props.key
            if not k then
                ids[vnode.type] = (ids[vnode.type] or 0) + 1
                k = '' .. ids[vnode.type]
            end

            local index = 1
            enableHookContext(hs[k] or {}, index, forceUpdate)
            vnode = vnode.type(vnode.props, vnode.children, forceUpdate)
            storage.hooks[k] = disableHookContext()
        end

        local node = parent.children[i]
        local createdNewNode = false
        if (not node) or ((node and node.type) ~= vnode.type) then
            node = addElementToParent(vnode, parent, i)
            createdNewNode = true
            if not node then
                error("Failed to add element to GUI: " .. serpent.line(vnode))
            end
        end

        for k, v in pairs(vnode.props) do
            if (k:find("on_gui_") == 1 and type(v) == "function") then
                -- add event handler cleanup functions to the storage table
                createScopedHandler(defines.events[k], node, v, node.index)
            elseif (k == "ref") then
                v.current = node
            elseif ((not createdNewNode) and compareNodeProp(node, k, v)) then
                -- If we created a new node, we don't need to update it
                node[k] = v
            end
        end

        -- setup children storage and render (needed even if there are no children, since we can't put arbitrary data on the element itself)
        storage.children = storage.children or {}
        storage.children[node.index] = storage.children[node.index] or {}
        render(vnode.children, node, storage.children[node.index])
    end

    -- Reconciliation
    -- run new useEffect callbacks and store cleanup functions
    for _, componentHooks in pairs(storage.hooks) do
        for _, hook in pairs(componentHooks) do
            if (hook.cb) then
                local oldCleanup = hook.cleanup
                -- run new effect
                hook.cleanup = hook.cb()
                -- run cleanup for existing effect (deps changed)
                if oldCleanup and (type(oldCleanup) == "function") then oldCleanup() end
                hook.cb = nil
            end
        end
    end

    -- run cleanup functions for removed hooks
    for key, _ in pairs(hs) do
        if not storage.hooks[key] then
            for _, h in pairs(hs[key]) do
                if (h.cleanup) then
                    h.cleanup()
                end
                hs[key] = nil
            end
        end
    end

    -- remove extra elements
    while true do
        child = parent.children[#vlist + 1]
        if child then
            child.destroy()
            render({}, parent, storage)
        else
            break
        end
    end
end

--- A function that creates a virtual element for rendering. Alternatively, you can use the shorthand `h` function, or JSX.
---
--- @param type GuiElementType|function the type of element to create
--- @param props? table a table of properties to set on the element
--- @param ... table|string children - may be strings or other `createElement` results
--- @return table vlist virtual element node(s) (vnodes are implementation details and should not be accessed directly)
---
--- @see https://react.dev/reference/react/createElement
local function createElement(type, props, ...)
    local children = { ... }
    return { type = type, props = props or {}, children = children }
end

return {
    createElement = createElement,
    render = render,
}
