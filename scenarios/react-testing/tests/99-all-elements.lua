local React = require("__react__.react")

local function renderElement(props, ...)
    local element_type = props.type
    return React.createElement("frame", { direction = "horizontal" },
        React.createElement("label", { caption = element_type }),
        React.createElement(element_type, props, ...)
    )
end

local function Test(props)
    local player = props.player

    return React.createElement("scroll-pane", {},
        renderElement({ type = "button", caption = "Button" }),
        renderElement({ type = "sprite-button", caption = "Sprite Button", sprite = "item/iron-plate" }),
        renderElement({ type = "checkbox", caption = "Checkbox", state = true }),
        renderElement({ type = "flow", caption = "Flow" }),
        renderElement({ type = "frame", caption = "Frame" }),
        renderElement({ type = "label", caption = "Label" }),
        renderElement({ type = "line", caption = "Line" }),
        renderElement({ type = "progressbar", caption = "Progressbar" }),
        renderElement({ type = "table", caption = "Table", column_count = 2 }),
        renderElement({ type = "textfield", caption = "Textfield" }),
        renderElement({ type = "radiobutton", caption = "Radiobutton", state = false }),
        renderElement({ type = "sprite", caption = "Sprite", sprite = "item/iron-plate" }),
        renderElement({ type = "scroll-pane", caption = "Scroll Pane" }),
        renderElement({ type = "drop-down", caption = "Drop Down", items = { "A", "B", "C" } }),
        renderElement({ type = "list-box", caption = "List Box", items = { "A", "B", "C" } }),
        renderElement({ type = "camera", caption = "Camera", position = player.position, surface_index = player.surface.index }),
        renderElement({ type = "choose-elem-button", caption = "Choose Elem Button", elem_type = "item" }),
        renderElement({ type = "text-box", caption = "Text Box", text = "Hello, " .. player.name .. "!" }),
        renderElement({ type = "slider", caption = "Slider", value = 5 }),
        renderElement({ type = "minimap", caption = "Minimap", position = player.position, surface_index = player
        .surface.index }),
        renderElement({ type = "entity-preview", caption = "Entity Preview", entity = player.get_associated_characters()
        [1] }),
        renderElement({ type = "empty-widget", caption = "Empty Widget" }),
        renderElement({ type = "tabbed-pane", caption = "Tabbed Pane" },
            renderElement({ type = "tab", caption = "Tab A", badge_text = 3 }),
            renderElement({ type = "tab", caption = "Tab B", badge_text = 2 }),
            renderElement({ type = "tab", caption = "Tab C", badge_text = 1 })
        ),
        renderElement({ type = "switch", caption = "Switch", switch_state = "none", allow_none_state = true })
    )
end

return Test
