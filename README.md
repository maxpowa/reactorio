# Reactorio

React, but for Factorio. Packaged as a mod for easy consumption.

```lua
local React = require("__react__.react")

script.on_event(defines.events.on_gui_opened, function(event)
    if not event.player then return end

    local element = React.createElement(
        "frame",
        { caption = "Reactorio" },
        "Hello, world!"
    )
    React.render(element, event.player.gui.screen)
end)
```

### Features

 - Function components
    - `useState`
    - `useReducer`
    - `useEffect`
 - Plain text components (generated via `label`)
 - Simple event API
    - No need to register a separate event listener, just add a prop
    - Supported events listed below
        - `on_gui_checked_state_changed`
        - `on_gui_click`
        - `on_gui_confirmed`
        - `on_gui_elem_changed`
        - `on_gui_selection_state_changed`
        - `on_gui_text_changed`
        - `on_gui_value_changed`

### Coming Soon™

 - Component shorthand similar to JSX

### Examples

// TODO




