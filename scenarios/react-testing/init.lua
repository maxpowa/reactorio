local React = require("__react__.react")
local tests = {
    require("tests.01-basic"),
    require("tests.02-typical"),
    require("tests.03-basic-with-hooks"),
    require("tests.04-useRef"),
    require("tests.05-lsx"),
    require("tests.99-all-elements"),
}

local RUN_ALL_TESTS_DELAY = 60 * 2 -- 3 seconds

local timeoutHandlers = {}
-- This isn't perfect - in editor mode game.tick is not updated, but it's good enough for testing.
-- The tests should always be run in game mode anyway.
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

-- Test harness component, provides the ability for the user to navigate through the tests
local function TestHarness(props)
    local player = props.player

    local current_test_index, setState = React.useState(1)
    local autoRun, setAutoRun = React.useState(true)

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

function run_tests(player)
    player.print("Factorio React Testing Apparatus loaded")

    if player.gui.screen["react_root"] then
        player.gui.screen["react_root"].destroy()
    end
    local root = player.gui.screen.add({ type = "frame", name = "react_root", caption = "React Testing Apparatus", direction = "vertical" })
    root.auto_center = true

    -- Dogfood the tests :)
    global.hook_storage = {}
    React.render(React.createElement(TestHarness, { player = player }), root, global.hook_storage)
end

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    player.character.destroy() -- remove player character to prevent them from moving around
    run_tests(player)
end)