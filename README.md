# Reactorio

React, but for Factorio. Packaged as a mod for easy consumption.

```lua
local Reactorio = require("__reactorio__.react")

script.on_event(defines.events.on_gui_opened, function(event)
    if not event.player then return end

    local element = Reactorio.createElement(
        "frame",
        { caption = "Reactorio" },
        "Hello, world!"
    )
    Reactorio.render(element, event.player.gui.screen)
end)
```

### Features

 - Function components
    - `useState`
    - `useReducer`
    - `useEffect`
 - Plain text components (generated via `label`)
 - Props-based event API
    - No need for a separate event listener!
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




