# Reactorio

React, but for Factorio. Packaged as a mod for easy consumption.

```lua
local React = require("__react__.react")

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]

    -- Create the root element we are going to put our GUI into (props can be customized)
    local root = React.createRoot(player.gui.center, { style = "outer_frame" })

    -- Build our virtual dom tree
    local vdom = React.lsx[[
        <frame caption="React for Factorio">
            Hello, world!
            <button>Click Me!</button>
        </frame>
    ]]

    -- Render!
    React.render(vdom, root)
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
 - LSX, Lua version of JSX
    - `lsx'<label caption="Hello world!" />'` is equivalent to `createElement("label", { caption = "Hello world!" })`


### Coming Soon™

 - Variable support in LSX (via additional param in lsx function)
 - Save/load event handler restoration (maybe this works now?)
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
