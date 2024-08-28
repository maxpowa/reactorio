local React = require("__react__.react")
local createElement, lsx = React.createElement, React.lsx

local UnitTesting = require("ut");
local describe, it, assert = UnitTesting.describe, UnitTesting.it, UnitTesting.assert

describe('createElement(lsx)', function()
    it('should return a vnode', function()
        local vnode = createElement("flow", { hello = "world" }, {});
        assert(type(vnode) == "table", "createElement did not return a vnode")
        assert(vnode.type == "flow", "vnode type is not 'flow'")
        assert(vnode.props.hello == "world", "vnode props do not match")
    end)

    it('should set a vnode:type property', function()
        local vnode = lsx('<flow hello="world" />');
        assert(vnode.type == "flow", "vnode type is not 'flow'")
        assert(vnode.props.hello == "world", "vnode props do not match")
    end)

end)