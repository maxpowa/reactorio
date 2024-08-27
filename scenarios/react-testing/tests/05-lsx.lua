local React = require("__react__.react")

local function Test(props)
    local player = props.player

    return React.lsx([[<frame>
            <label caption="This was rendered by LSX" />
            <label caption="Hello, ${name}!" />
        </frame>]], { name = player.name })
end

return Test