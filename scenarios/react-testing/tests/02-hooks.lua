local React = require("__react__.react")
local createElement = React.createElement

local UnitTesting = require("ut");
local describe, it  = UnitTesting.describe, UnitTesting.it

describe('React useState hook', function()
    it('should not break render', function(testProps)
        local hostElement = testProps.hostElement

        local function Component()        
            local count, setCount = React.useState(1)
        
            local on_gui_click = React.useCallback(function()
                setCount(count + 1)
            end, { count})
        
            return createElement("flow", { direction = "vertical" },
                createElement("button", { on_gui_click = on_gui_click, caption = "Click me!"}),
                createElement("label", { caption = "Count: " .. count })
            )
        end

        return React.render(createElement(Component), hostElement)
    end)
end)

describe('React useRef hook', function()
    it('should not break render', function(testProps)
        local hostElement = testProps.hostElement
        
        local function Component()
            local textbox = React.useRef(nil)

            local on_press = React.useCallback(function()
                if textbox.current then
                    textbox.current.focus()
                    textbox.current.select_all()
                end
            end, { textbox })

            return createElement("flow", { direction = "vertical" },
                createElement("text-box", { ref = textbox, text = "Hello, world!" }),
                createElement("button", { on_gui_click = on_press, caption = "Select all"})
            )
        end
        
        return React.render(createElement(Component), hostElement)
    end)
end)