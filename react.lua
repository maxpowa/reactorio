-- Reactorio (React for Factorio)

-- require guard
if ... ~= "__react__.react" then
    return require("__react__.react")
end

-- TODO: prevent util from polluting scope
require "__react__.util"

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

function useReducer(reducer, initialState)
    local hook = getHook(initialState)
    local update = forceUpdate
    local function dispatch(action)
        hook.value = reducer(hook.value, action)
        update()
    end
    return hook.value, dispatch
end

function useState(initialState)
    return useReducer(function(_, v) return v end, initialState)
end

local function changed(a, b)
    return not a or arr.some(b, function(arg, i) return arg ~= a[i + 1] end)
end
function useEffect(cb, deps)
    local dependencies = deps or {}
    local hook = getHook()
    if changed(hook.deps, dependencies) then
        hook.deps = dependencies
        hook.cb = cb
    end
end

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
-- internal handler for any gui related event
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

function render(vlist, root_element, hookStorage)
    if not arr.is_array(vlist) then
        vlist = { vlist }
    end
    local ids = {}
    local hs = hookStorage or {}
    hookStorage = {}
    for i, vnode in ipairs(vlist) do
        forceUpdate = function() return render(vlist, root_element, hookStorage) end

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
            index = nil
            hookStorage[k] = hooks
        end

        local node = root_element.children[i]
        local oldNodeIndex = node and node.index
        if (not node) or (vnode.type and node.type ~= vnode.type) then
            node = addElementToParent(vnode, root_element)
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
            render(vnode.children, node, hookStorage);
        end

        -- Reconciliation

        -- run new useEffect callbacks and store cleanup functions
        for _, componentHooks in pairs(hookStorage) do
            for _, h in pairs(componentHooks) do
                if (h.cb) then
                    h.cleanup = h.cb()
                    h.cb = nil
                end
            end
        end

        -- run cleanup functions for removed hooks
        for key, _ in pairs(hs) do
            if not hookStorage[key] then
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
            root_element.swap_children(oldNodeIndex, node.index)
        end

        -- remove extra elements
        while true do
            child = root_element.children[#vlist + 1]
            if child then
                child.destroy()
                render({}, root_element, hookStorage)
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
    render = render,
}
