-- Reactorio (React for Factorio) core logic

if ... ~= "__react__.lib.core" then
    return require("__react__.lib.core")
end

-- Explicit imports here prevent scope pollution
local addScopedHandler = require "__react__.lib.events".addScopedHandler
local enableHooks = require "__react__.lib.hooks".enableHooks
local disableHooks = require "__react__.lib.hooks".disableHooks

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
            if (k:find("on_gui_") == 1 or k == "ref") then
                -- do nothing
            elseif (k == "style") then
                if type(v.props.style) == "string" then
                    -- factorio only allows style at `.add` if its a string, otherwise it errors
                    props.style = v.props.style
                elseif (v.props.style.name) then
                    -- we can initialize the style prop with the name value if it exists
                    props.style = v.props.style.name
                end
            else
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
    if (node.type == "slider") then
        if (k == "value") then
            return node.slider_value ~= v
        elseif (k == "minimum_value") then
            return node.get_slider_minimum() ~= v
        elseif (k == "maximum_value") then
            return node.get_slider_maximum() ~= v
        elseif (k == "value_step") then
            return node.get_slider_value_step() ~= v
        elseif (k == "discrete_slider") then
            return node.get_slider_discrete_slider() ~= v
        elseif (k == "discrete_values") then
            return node.get_slider_discrete_values() ~= v
        end
    end
    return node[k] ~= v
end

local function updateNodeProp(node, k, v)
    -- Wube, this is infuriating... The game is practically unplayable now that I know about this.
    if (node.type == "slider") then
        if (k == "value") then
            node.slider_value = v
            return
        elseif (k == "minimum_value") then
            node.set_slider_minimum_maximum(v, node.get_slider_maximum())
            return
        elseif (k == "maximum_value") then
            node.set_slider_minimum_maximum(node.get_slider_minimum(), v)
            return
        elseif (k == "value_step") then
            node.set_slider_value_step(v)
            return
        elseif (k == "discrete_slider") then
            node.set_slider_discrete_slider(v)
            return
        elseif (k == "discrete_values") then
            node.set_slider_discrete_values(v)
            return
        end
    end
    node[k] = v
end

-- immediate mode rendering
local function renderImmediate(vnode, index, parent, storage, recurse)
    local node = parent.children[index]
    local createdNewNode = false
    if (not node) or ((node and node.type) ~= vnode.type) then
        node = addElementToParent(vnode, parent, index)
        createdNewNode = true
        if not node then
            error("Failed to add element to GUI: " .. serpent.line(vnode))
        end
    end

    for k, v in pairs(vnode.props) do
        if (k:find("on_gui_") == 1 and type(v) == "function") then
            -- TODO: only add new handlers if they changed
            addScopedHandler(defines.events[k], node, v, node.index)
        elseif (k == "ref") then
            v.current = node
        elseif (k == "style") then
            -- set style updates directly on the element
            if type(v) ~= "string" then
                for styleKey, styleValue in pairs(v) do
                    if (node.style[styleKey] ~= styleValue) then
                        node.style[styleKey] = styleValue
                    end
                end
            end
        elseif ((not createdNewNode) and compareNodeProp(node, k, v)) then
            -- If we created a new node, we don't need to update it
            updateNodeProp(node, k, v)
        end
    end

    -- TODO: only rerender children if they changed (will need to store the previous children in storage I think...)
    -- setup children storage and render (needed even if there are no children, since we can't put arbitrary data on the element itself)
    storage.children = storage.children or {}
    storage.children[node.index] = storage.children[node.index] or {}
    recurse(vnode.children, node, storage.children[node.index])
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
        storage = { hooks = {} }
    end
    -- capture current hook storage
    local hs = storage.hooks or {}
    -- clear hook storage global
    storage.hooks = {}

    -- render the virtual element list
    local ids = {}
    local extraNodeCount = 0
    for i, vnode in ipairs(vlist) do
        -- TODO: defer and batch forceUpdate requests
        local forceUpdate = function() return render(vlist, parent, storage) end

        -- special handling for string vnodes
        if type(vnode) == "string" then
            vnode = { type = "label", props = { caption = vnode } }
        end

        while (type(vnode.type) == "function") do
            local k = vnode.props and vnode.props.key
            if not k then
                ids[vnode.type] = (ids[vnode.type] or 0) + 1
                k = '' .. ids[vnode.type]
            end

            enableHooks(hs[k] or {}, forceUpdate)
            vnode = vnode.type(vnode.props, vnode.children, forceUpdate)
            storage.hooks[k] = disableHooks()
        end

        if is_array(vnode) then
            for _, v in ipairs(vnode) do
                -- we need to keep the index consistent, so we add extra nodes to the count
                extraNodeCount = extraNodeCount + 1
                renderImmediate(v, i + extraNodeCount, parent, storage, render)
            end
        elseif type(vnode) ~= nil then
            renderImmediate(vnode, i + extraNodeCount, parent, storage, render)
        end
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
    while not parent.tags.__react_ignored do
        -- only remove elements that are not part of the virtual element list (including extra nodes added for fragments)
        child = parent.children[#vlist + extraNodeCount + 1]
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
    createElement = createElement,
    createRoot = createRoot,
    render = render,
}
