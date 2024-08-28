local React = require("__react__.react")
local createElement, lsx = React.createElement, React.lsx

local UnitTesting = require("ut");
local describe, it, assert = UnitTesting.describe, UnitTesting.it, UnitTesting.assert

describe('React lsx', function()
    it('should not break', function(testProps)
        local player = testProps.player
        local hostElement = testProps.hostElement

        local vnode = lsx([[<frame>
            <label caption="This was rendered by LSX" />
            <label caption="Hello, ${name}!" />
        </frame>]], { name = player.name });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, hostElement)
    end)
end)