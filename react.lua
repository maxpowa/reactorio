-- Reactorio (React for Factorio)
--!strict

-- require guard
if ... ~= "__react__.react" then
    return require("__react__.react")
end

-- TODO: prevent util from polluting scope
require "__react__.util"

--- A function that creates a virtual element for rendering. Alternatively, you can use the shorthand `h` function, or JSX.
--- 
--- @param type GuiElementType the type of element to create
--- @param props table a table of properties to set on the element
--- @param ... table|string children - may be strings or other `createElement` results
--- @return table vlist virtual element node(s) (vnodes are implementation details and should not be accessed directly)
--- 
--- @see https://react.dev/reference/react/createElement
function createElement(type, props, ...)
    local children = { ... }
    return { type = type, props = props or {}, children = children }
end

local hooks;
local index = nil;
local forceUpdate;
local function getHook(value)
    if not index then error("Hooks can only be called inside components") end
    index = index + 1
    local hook = hooks[index]
    if not hook then
        hook = { value = value }
        hooks[index] = hook
    end
    return hook
end

--- A hook that lets you manage local component state with a reducer
--- 
--- @param reducer function a function that takes the current state and an action and returns the new state
--- @param initialState any initial state value
--- @return any state, function dispatch the current state value and a function to update it
--- 
--- @see https://react.dev/reference/react/useReducer
function useReducer(reducer, initialState)
    local hook = getHook(initialState)
    local update = forceUpdate
    local function dispatch(action)
        hook.value = reducer(hook.value, action)
        update()
    end
    return hook.value, dispatch
end

--- A hook that lets you add state to your component
--- 
--- @param initialState any initial state value
--- @return any state, function setState the current state value and a function to update it
--- 
--- @see https://react.dev/reference/react/useState
function useState(initialState)
    return useReducer(function(_, v) return v end, initialState)
end

local function changed(a, b)
    return not a or arr.some(b, function(arg, i) return arg ~= a[i + 1] end)
end

--- A hook that lets you synchronize a component with other systems
--- 
--- @param cb function callback to run when dependencies changed
--- @param deps table list of dependencies
--- 
--- Note: Dependencies table must be a flat table of the actual values, not the variable names used in the component
--- 
--- @see https://react.dev/reference/react/useEffect
function useEffect(cb, deps)
    local dependencies = deps or {}
    local hook = getHook()
    if changed(hook.deps, dependencies) then
        hook.deps = dependencies
        hook.cb = cb
    end
end

--- A hook that lets you memoize expensive calculations
--- 
--- @param factory function a function that returns the value to memoize
--- @param deps table list of dependencies
--- @return any any memoized value
--- 
--- Note: Dependencies table must be a flat table of the actual values, not the variable names used in the component
--- 
--- @see https://react.dev/reference/react/useMemo
function useMemo(factory, deps)
    local dependencies = deps or {}
    local hook = getHook()
    if changed(hook.deps, dependencies) then
        hook.value = factory()
        hook.deps = dependencies
        hook.factory = factory
    end
    return hook.value
end

--- A hook that lets you memoize functions, useful for event handlers
--- 
--- @param cb function a function to memoize
--- @param deps table list of dependencies
--- @return function any memoized function
--- 
--- Note: Dependencies table must be a flat table of the actual values, not the variable names used in the component
--- 
--- @see https://react.dev/reference/react/useCallback
function useCallback(cb, deps)
    return useMemo(function() return cb end, deps)
end

-- Event handling logic
local eventHandlers = {
    [defines.events.on_gui_checked_state_changed] = {},
    [defines.events.on_gui_click] = {},
    [defines.events.on_gui_confirmed] = {},
    [defines.events.on_gui_elem_changed] = {},
    [defines.events.on_gui_selection_state_changed] = {},
    [defines.events.on_gui_text_changed] = {},
    [defines.events.on_gui_value_changed] = {},
}
local function on_event_handler(event)
    local eventName = event.name
    handlers = eventHandlers[eventName]
    for _, eventHandler in pairs(handlers or {}) do
        if (type(eventHandler) == "function") then
            eventHandler(event)
        end
    end
end
script.on_event(defines.events.on_gui_checked_state_changed, on_event_handler)
script.on_event(defines.events.on_gui_click, on_event_handler)
script.on_event(defines.events.on_gui_confirmed, on_event_handler)
script.on_event(defines.events.on_gui_elem_changed, on_event_handler)
script.on_event(defines.events.on_gui_selection_state_changed, on_event_handler)
script.on_event(defines.events.on_gui_text_changed, on_event_handler)
script.on_event(defines.events.on_gui_value_changed, on_event_handler)

local function createScopedHandler(eventId, element, fn, index)
    return function(event)
        if (not element.valid) then
            -- TODO: perform this cleanup when the element is destroyed
            eventHandlers[eventId][index] = nil
        elseif (event.element == element) then
            fn(event)
        end
    end
end

local function addElementToParent(v, parent)
    if (v.type ~= nil) then
        local props = {}

        -- omit event handlers from props
        for k, _ in pairs(v.props or {}) do
            if (k:find("on_gui_") ~= 1) then
                props[k] = v.props[k]
            end
        end

        local mergedProps = tbl.merge(props, { type = v.type });
        return parent.add(mergedProps)
    elseif (type(v) == "string") then
        return parent.add({ type = "label", caption = v })
    else
        error("Invalid element: " .. serpent.line(v))
    end
end

--- Renders a virtual element tree to a parent element
--- 
--- @param vlist table list of virtual elements, created by React.createElement 
--- @param parent LuaGuiElement element to render to
--- @param storage table hook storage (required if rendering element tree from different sources, e.g. in both on_gui_opened and on_gui_closed)
--- 
--- @see createElement
function render(vlist, parent, storage)
    if not arr.is_array(vlist) then
        vlist = { vlist }
    end

    -- initialize storage if not present
    if not storage then
        storage = {}
    end
    -- capture current hook storage
    local hs = storage.hooks or {}
    -- clear hook storage global
    storage.hooks = {}

    local ids = {}
    for i, vnode in ipairs(vlist) do
        forceUpdate = function() return render(vlist, parent, storage) end

        while (type(vnode.type) == "function") do
            local k = vnode.props and vnode.props.key
            if not k then
                ids[vnode.type] = (ids[vnode.type] or 0) + 1
                k = '' .. ids[vnode.type]
            end

            hooks = hs[k] or {}
            index = 1
            vnode = vnode.type(vnode.props, vnode.children, forceUpdate)
            -- reset index to nil to prevent hooks from being called outside of components
            -- index = nil
            storage.hooks[k] = hooks
        end

        local node = parent.children[i]
        local oldNodeIndex = node and node.index
        if (not node) or (vnode.type and node.type ~= vnode.type) then
            node = addElementToParent(vnode, parent)
        end

        if (node and (node.type == vnode.type)) then
            for k, v in pairs(vnode.props) do
                if (k:find("on_gui_") == 1 and type(v) == "function") then
                    local index = node.index
                    local eventId = defines.events[k]
                    eventHandlers[eventId][index] = createScopedHandler(eventId, node, v, index)
                elseif (node[k] ~= v) then
                    node[k] = v
                end
            end

            -- setup children storage and render (needed even if there are no children, since we can't put arbitrary data on the element itself)
            storage.children = storage.children or {}
            storage.children[node.index] = storage.children[node.index] or {}
            render(vnode.children, node, storage.children[node.index]);
        end

        -- Reconciliation

        -- run new useEffect callbacks and store cleanup functions
        for _, componentHooks in pairs(storage.hooks) do
            for _, h in pairs(componentHooks) do
                if (h.cb) then
                    h.cleanup = h.cb()
                    h.cb = nil
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

        -- since we can't directly insert elements at a specific index, we have to swap them around after adding
        if (node and oldNodeIndex and (oldNodeIndex ~= node.index)) then
            parent.swap_children(oldNodeIndex, node.index)
        end

        -- remove extra elements
        while true do
            child = parent.children[#vlist + 1]
            if child then
                storage.children[child.index] = nil
                child.destroy()
                render({}, parent, storage)
            else
                break
            end
        end
    end
end

return {
    createElement = createElement,
    h = createElement,
    useReducer = useReducer,
    useState = useState,
    useEffect = useEffect,
    useMemo = useMemo,
    useCallback = useCallback,
    render = render,
}
