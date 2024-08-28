local React = require("__react__.react")
local createElement = React.createElement

local UnitTesting = require("ut");

-- Test harness component, provides the ability for the user to navigate through the tests
local function TestHarness(props)
    --- @type LuaPlayer
    local player = props.player

    -- this is the element that will host the actual tests
    local hostElement = React.useRef({ current = nil })
    local results, setResults = React.useState()

    local on_click_run = function()
        setResults(nil)
        -- TODO: Figure out how to do this either as a coroutine or just update the UI as each test runs
        local runResults = UnitTesting.run({ hostElement = hostElement.current, player = player })
        setResults(runResults)
    end

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
                            name= "player_input_horizontal_flow",
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
                    createElement("button", {
                        on_gui_click = on_click_run,
                        caption = "Run tests",
                        style = "confirm_button"
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
