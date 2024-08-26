-- Reactorio event handling logic

if ... ~= "__react__.lib.events" then
    return require("__react__.lib.events")
end

-- TODO: This may change across versions... not very future-proof
local supported_events = {
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
        if (type(eventHandler) == "function") then
            eventHandler(event)
        end
    end
end

-- Factorio requires this funky approach to event handling because the event handlers are global, instead of per-element
local function createScopedHandler(eventId, element, fn, index)
    -- TODO: throw an error if the event does not make sense for the element
    if (eventHandlers[eventId] == nil) then
        error("Unsupported event: " .. eventId)
    end

    if not contains(supported_events[eventId], element.type) then
        error("Unsupported event for element type: " .. eventId .. " " .. element.type)
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
        game.print("Cleaning up event handler for " .. eventId .. " for element " .. element.index .. " of type " .. element.type)
        eventHandlers[eventId][index] = nil
    end
end

-- Register our supported events with the game's event emitter
for k, _ in pairs(supported_events) do
    -- initialize the event handler table with this event type
    eventHandlers[k] = {}
    script.on_event(k, on_event_handler)
end

return {
    createScopedHandler = createScopedHandler
}