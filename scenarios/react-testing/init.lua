local React = require("__react__.react")

local UnitTesting = require("ut");

-- Require the actual test files (they're loaded into the UnitTesting module)
require("tests.01-core")
require("tests.02-hooks")
require("tests.03-lsx")
require("tests.99-all-elements")

local TestHarness = require("harness")

function run_tests(player)
    player.print("Factorio React Testing Apparatus loaded")
    local root = React.createRoot(player.gui.screen, { auto_center = true, visible = true })

    -- Dogfood the tests :)
    global.hook_storage = {}
    React.render(React.createElement(TestHarness, { player = player }), root, global.hook_storage)
end

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    -- Don't autosave the unit testing environment...
    game.autosave_enabled = false
    -- remove player character to prevent them from moving around
    player.character.destroy()
end)

-- Run the tests when the the resolution changes, so that we can fullscreen the test UI
script.on_event(defines.events.on_player_display_resolution_changed, function(event)
    local player = game.players[event.player_index]
    run_tests(player)
end)
