local React = require("__react__.react")

local RUN_ALL_TESTS_DELAY = 60 * 3 -- 3 seconds

local timeoutHandlers = {}
-- This isn't perfect - in editor mode game.tick is not updated, but it's good enough for testing.
-- In editor mode you can manually advance the tick by pressing the "Advance tick" button.
script.on_event(defines.events.on_tick, function()
    for i, handler in pairs(timeoutHandlers) do
        if (game.tick - handler.start > 0) and ((game.tick - handler.start) % handler.delay == 0) then
            handler.cb()
            timeoutHandlers[i] = nil
        end
    end
end)
local function setTimeout(cb, delay)
    local index = #timeoutHandlers + 1
    local handler = {
        start = game.tick,
        cb = cb,
        delay = delay
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
        if current_test_index ~= 1 then
            setState(1)
        end
        setAutoRun(not autoRun)
    end

    -- TODO: For some reason, when this useEffect is being run, tests 03 and 99 do not render...
    React.useEffect(function()
        local timeoutId = nil
        if autoRun then
            setTimeout(function()
                if current_test_index < #tests then
                    setState(current_test_index + 1)
                else
                    setAutoRun(false)
                end
            end, RUN_ALL_TESTS_DELAY)
        end

        return function()
            if timeoutId then
                clearTimeout(timeoutId)
            end
        end
    end, { autoRun, current_test_index })

    return React.createElement("frame", { direction = "vertical", style = "inside_shallow_frame_with_padding" },
        React.createElement("frame", { direction = "horizontal" },
            React.createElement("label", { caption = "Test " .. current_test_index .. "/" .. #tests }),
            React.createElement("button",
                { on_gui_click = on_gui_click, enabled = current_test_index < #tests, caption = "Next test" }),
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
