local React = require("__react__.react")

local RUN_ALL_TESTS_DELAY = 60 * 3 -- 3 seconds

local timeoutHandlers = {}
script.on_event(defines.events.on_tick, function()
    for i, handler in pairs(timeoutHandlers) do
        if game.tick % handler.delay == 0 then
            handler.cb()
            timeoutHandlers[i] = nil
        end
    end
end)
local function setTimeout(cb, delay)
    local index = #timeoutHandlers + 1
    -- If we don't have this, when the delay is 60 and the current tick is 30, the delay time will only be 30 ticks.
    -- Using this offset value ensures we will always wait exactly the delay time.
    local offset = game.tick % delay
    local handler = {
        cb = cb,
        delay = delay + offset
    }
    timeoutHandlers[index] = handler
    return index
end
local function clearTimeout(index)
    timeoutHandlers[index] = nil
end

local function TestHarness(props)
    local tests = props.tests
    local player = props.player

    local current_test_index, setState = React.useState(1)
    local autoRun, setAutoRun = React.useState(false)

    local current_test = tests[current_test_index]
    local on_gui_click = function()
        setState(current_test_index + 1)
        setAutoRun(false)
    end
    local on_gui_click_reset = function()
        setState(1)
        setAutoRun(false)
    end
    local on_gui_click_run = function()
        setAutoRun(not autoRun)
    end

    React.useEffect(function()
        local timeoutId = nil
        if autoRun and current_test_index < #tests then
            timeoutId = setTimeout(function()
                setState(current_test_index + 1)
            end, RUN_ALL_TESTS_DELAY)
        end
        return function()
            if timeoutId then
                clearTimeout(timeoutId)
            end
        end
    end, { current_test_index, autoRun })

    return React.createElement("frame", { direction = "vertical", style = "inside_shallow_frame_with_padding" },
        React.createElement("frame", { direction = "horizontal" },
            React.createElement("label", { caption = "Test " .. current_test_index .. "/" .. #tests }),
            React.createElement("button", { on_gui_click = on_gui_click, enabled = current_test_index < #tests, caption = "Next test" }),
            React.createElement("button", { on_gui_click = on_gui_click_reset, caption = "Reset" }),
            React.createElement("button",
                { on_gui_click = on_gui_click_run, caption = autoRun and "Pause tests" or "Run tests" }
            )
        ),
        React.createElement("frame", { caption = "Test" },
            React.createElement(current_test, { player = player })
        )
    )
end

return TestHarness
