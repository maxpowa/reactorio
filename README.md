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

 - Function components with hook support
    - `useState`
    - `useReducer`
    - `useEffect`
    - `useMemo`
    - `useCallback`
    - `useRef`
 - Plain text components (generated via `label`)
 - Simple event API
    - No need to register a separate event listener, just add a prop

### Coming Soon™

 - Component shorthand similar to JSX (most likely going to adapt https://github.com/hishamhm/f-strings)
 - Save/load event handler restoration
 - Context API support (`createContext`/`useContext`)

### Examples


### Credits

The core render loop/virtual dom is heavily inspired by [O!](https://github.com/zserge/o), with other hook implementations referenced from [Preact](https://github.com/preactjs/preact).
