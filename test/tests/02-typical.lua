local React = require("__react__.react")

local function Test(props)
    local player = props.player

    return React.createElement("label", { caption = "Hello !!!111, " .. player.name .. "!" })
end

return Test