local React = require("__react__.react")
local createElement = React.createElement

local UnitTesting = require("ut");

-- Test harness component, provides the ability for the user to navigate through the tests
local function TestHarness(props)
    --- @type LuaPlayer
    local player = props.player

    -- this is the element that will host the actual tests
    local hostElement = React.useRef()
    local testRunner = React.useRef()
    local results, setResults = React.useState()
    local autoRun, setAutoRun = React.useState(false)
    local testInterval, setTestInterval = React.useState(5)

    local run_next_test = React.useCallback(function()
        if hostElement.current then hostElement.current.clear() end
        if (testRunner.current) then
            local status, err = testRunner.current.runNext({ hostElement = hostElement.current, player = player })
            if status ~= nil then
                setResults({
                    total = (results and results.total + 1) or 1,
                    passing = (results and results.passing or 0) + (status and 1 or 0),
                    failing = (results and results.failing or 0) + (status and 0 or 1)
                })
            else
                testRunner.current = nil
            end
        end
    end, { testRunner, hostElement, })

    React.useEvent(defines.events.on_tick, function(event)
        if (testRunner.current and (event.tick % testInterval == 0) and autoRun) then
            run_next_test()
            if (testRunner.current == nil) then
                setAutoRun(false)
            end
        end
    end, {}, { testRunner, hostElement, testInterval, autoRun })

    local on_click_run = React.useCallback(function()
        setResults(nil);
        testRunner.current = UnitTesting.getRunner();
        setAutoRun(true);
    end, { testRunner, })

    local on_click_exit = function()
        game.set_game_state {
            game_finished = true,
            player_won = not (results and results.failing ~= 0),
            can_continue = false
        }
    end

    local results_info_string = results and
        string.format("Tests run: %d, passing: %d, failing: %d", results.total, results.passing, results.failing) or
        "No tests run";

    return createElement("frame", {
            caption = "React Test App",
            direction = "horizontal",
            style = {
                natural_width = player.display_resolution.width,
                natural_height = player.display_resolution.height
            }
        },
        createElement("flow", {
                direction = "vertical",
                style = "vertical_flow",
            },
            createElement("frame", {
                    style = "neutral_message_frame",
                },
                createElement("flow", {
                        style = {
                            name = "player_input_horizontal_flow",
                            top_margin = 4,
                        },
                        direction = "horizontal"
                    },
                    createElement("label", { style = "achievement_percent_label", caption = results_info_string }),
                    createElement("empty-widget", {
                        style = {
                            horizontally_stretchable = true,
                        }
                    }),
                    createElement("label", {
                        caption = "Ticks per test:",
                        style = { name = "heading_3_label" }
                    }),
                    createElement("textfield", {
                        text = testInterval .. "",
                        style = "short_number_textfield",
                        on_gui_text_changed = function(event)
                            local value = tonumber(event.element.text);
                            if (type(value) == "number") then
                                setTestInterval(value)
                            end
                        end
                    }),
                    createElement("slider", {
                        value = testInterval,
                        minimum_value = 1,
                        maximum_value = 300,
                        style = "notched_slider",
                        on_gui_value_changed = function(event)
                            setTestInterval(event.element.slider_value)
                        end,

                    }),
                    createElement("button", {
                        on_gui_click = on_click_run,
                        caption = "Run tests",
                        style = "confirm_double_arrow_button"
                    })
                )
            ),
            createElement("label", {
                caption = "Test Host Frame",
                style = { name = "heading_2_label", top_margin = 8 }
            }),
            createElement("frame", {
                style = {
                    name = "inside_shallow_frame_with_padding",
                    vertically_stretchable = true,
                    top_margin = 8,
                    bottom_margin = 8
                },
                tags = {
                    ["__react_ignored"] = true,
                },
                ref = hostElement
            }
            ),
            createElement("button", {
                on_gui_click = on_click_exit,
                caption = "Exit",
                style = "red_back_button"
            })
        )
    )
end

return TestHarness
