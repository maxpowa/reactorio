local React = require("__react__.react")

local function Test(props)
    local player = props.player

    local count, setCount = React.useState(1)

    React.useEffect(function()
        player.print(player.name .. " has clicked " .. count .. " times.", { game_state = false })
    end, { count })

    local on_gui_click = React.useCallback(function()
        setCount(count + 1)
    end, { count})

    return React.createElement("flow", { direction = "vertical" },
        React.createElement("button", { on_gui_click = on_gui_click, caption = "Click me!"}),
        React.createElement("label", { caption = "Count: " .. count })
    )
end

return Test