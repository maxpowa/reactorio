-- https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/aa61fe5e3782ed0b8914caa1ac9986f985000fb0/doc/debugapi.md#detecting-debugging
if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-- Load the test suite
-- require("init")
local React = require("__react__.react")

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]

    -- Create the root element we are going to put our GUI into (props can be customized)
    local root = React.createRoot(player.gui.center, { style = "outer_frame" })

    -- Build our virtual dom tree
    local vdom = React.lsx[[
        <frame caption="React for Factorio">
            Hello, world!
            <button caption="Click Me!" />
        </frame>
    ]]

    -- Render!
    React.render(vdom, root)
end)