local React = require("__react__.react")

local function Test(props)
    local textbox = React.useRef(nil)

    local on_press = React.useCallback(function()
        if textbox.current then
            textbox.current.focus()
            textbox.current.select_all()
        end
    end, { textbox })

    return React.createElement("flow", { direction = "vertical" },
        React.createElement("text-box", { ref = textbox, text = "Hello, world!" }),
        React.createElement("button", { on_gui_click = on_press, caption = "Select all"})
    )
end

return Test