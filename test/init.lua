local React = require("__react__.react")
local TestHarness = require("harness")
local tests = {
    require("tests.01-basic"),
    require("tests.02-typical"),
    require("tests.03-basic-with-hooks"),
    require("tests.04-useRef"),
    require("tests.99-all-elements"),
}

function run_tests(player)
    if player.gui.screen["react_root"] then
        player.gui.screen["react_root"].destroy()
    end
    player.gui.screen.add({ type = "frame", name = "react_root", caption = "React Testing Apparatus", direction = "vertical" })

    -- Dogfood the tests :)
    global.hook_storage = {}
    React.render(React.createElement(TestHarness, { tests = tests, player = player }), player.gui.screen["react_root"], global.hook_storage)
end

--- Function to handle commands
--- @param event CustomCommandData event
function command_handler(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    if event.parameter == "test" then
        run_tests(player)
    end
end

commands.add_command("react", nil, command_handler)