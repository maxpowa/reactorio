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

### Running Tests

Run Factorio and launch the "React for Factorio/Unit Testing" scenario. This can be automated by adding a launch argument to your Factorio configuration. As of 1.1.109, the argument is `--load-scenario react/react-testing`. 

If you're using FMTK/VSCode, the below launch configuration should work.
```json
        {
            "type": "factoriomod",
            "request": "launch",
            "name": "Factorio Unit Test (React)",
            "factorioArgs": [
                "--load-scenario",
                "react/react-testing"
            ]
        },
```

### Credits

The core render loop/virtual dom is heavily inspired by [O!](https://github.com/zserge/o), with other hook implementations referenced from [Preact](https://github.com/preactjs/preact).
