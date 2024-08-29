-- Reactorio event handling logic

if ... ~= "__react__.lib.events" then
    return require("__react__.lib.events")
end

-- TODO: This may change across versions... not very future-proof
local supported_scoped_events = {
    [defines.events.on_gui_click] = {"button", "sprite-button"},
    [defines.events.on_gui_checked_state_changed] = {"checkbox"},
    [defines.events.on_gui_confirmed] = {"textfield"},
    [defines.events.on_gui_elem_changed] = {"choose-elem-button"},
    [defines.events.on_gui_selection_state_changed] = {"drop-down", "list-box"},
    [defines.events.on_gui_text_changed] = {"textfield", "text-box"},
    [defines.events.on_gui_value_changed] = {"slider"},
    [defines.events.on_gui_selected_tab_changed] = {"tabbed-pane"},
    [defines.events.on_gui_switch_state_changed] = {"switch"},
}

local function contains(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local eventHandlers = {}
local function on_event_handler(event)
    local eventId = event.name
    handlers = eventHandlers[eventId]
    for _, eventHandler in pairs(handlers or {}) do
        eventHandler(event)
    end
end

-- Factorio requires this funky approach to event handling because the event handlers are global, instead of per-element
local function addScopedHandler(eventId, element, fn, index)
    if not contains(supported_scoped_events[eventId], element.type) then
        error("Unsupported event for element type: " .. eventId .. " " .. element.type)
    elseif type(fn) ~= "function" then
        error("Event handler must be a function")
    end

    if eventHandlers[eventId][index] then
        eventHandlers[eventId][index] = nil
    end

    eventHandlers[eventId][index] = function(event)
        if (not element.valid) then
            -- cleanup this handler if the element is no longer valid (this should never happen, since this implies the element was destroyed before the event was handled)
            eventHandlers[eventId][index] = nil
        elseif (event.element == element) then
            fn(event)
        end
    end

    -- return a cleanup function we can use in core to remove the handler
    return function()
        eventHandlers[eventId][index] = nil
    end
end

--- Create an event handler for the given event type
--- 
--- @param eventId integer the event id to handle
--- @param fn function the function to call when the event is triggered
--- @param options { index?: number, custom?: boolean } custom allows for custom events
--- 
--- @return function cleanup a cleanup function that will remove the handler
--- 
local function addGlobalHandler(eventId, fn, options)
    options = options or {}
    if type(fn) ~= "function" then
        error("Event handler must be a function")
    elseif not options.custom and type(eventId) ~= "number" then
        error("Unsupported event: " .. eventId)
    elseif options.custom and not eventHandlers[eventId] then
        eventHandlers[eventId] = {}
        script.on_event(eventId, on_event_handler)
    end

    local index = options.index or #eventHandlers[eventId] + 1
    eventHandlers[eventId][index] = fn
    return function()
        eventHandlers[eventId][index] = nil
    end
end

-- Register our supported events with the game's event emitter
for k, _ in pairs(defines.events) do
    -- initialize the event handler table with this event type
    eventHandlers[defines.events[k]] = {}
    script.on_event(defines.events[k], on_event_handler)
end



return {
    addScopedHandler = addScopedHandler,
    addGlobalHandler = addGlobalHandler,
}