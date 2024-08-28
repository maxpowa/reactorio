local React = require("__react__.react")

local createElement, lsx = React.createElement, React.lsx

local UnitTesting = require("ut");
local describe, it, assert = UnitTesting.describe, UnitTesting.it, UnitTesting.assert

describe('render (all elements)', function()
    it('should render an element for button', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("button", { caption = "Button" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for sprite-button', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("sprite-button", { caption = "Sprite Button", sprite = "item/iron-plate" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for checkbox', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("checkbox", { caption = "Checkbox", state = true });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for flow', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("flow", { caption = "Flow" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for frame', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("frame", { caption = "Frame" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for label', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("label", { caption = "Label" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for line', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("line", { caption = "Line" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for progressbar', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("progressbar", { caption = "Progressbar" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for table', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("table", { caption = "Table", column_count = 2 });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for textfield', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("textfield", { caption = "Textfield" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for radiobutton', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("radiobutton", { caption = "Radiobutton", state = false });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for sprite', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("sprite", { caption = "Sprite", sprite = "item/iron-plate" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for scroll-pane', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("scroll-pane", { caption = "Scroll Pane" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for drop-down', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("drop-down", { caption = "Drop Down", items = { "A", "B", "C" } });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for list-box', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("list-box", { caption = "List Box", items = { "A", "B", "C" } });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for camera', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("camera", { caption = "Camera", position = testProps.player.position, surface_index = testProps.player.surface.index });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for choose-elem-button', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("choose-elem-button", { caption = "Choose Elem Button", elem_type = "item" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for text-box', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("text-box", { caption = "Text Box", text = "Hello, " .. testProps.player.name .. "!" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for slider', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("slider", { caption = "Slider", value = 5 });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for minimap', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("minimap", { caption = "Minimap", position = testProps.player.position, surface_index = testProps.player.surface.index });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for entity-preview', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("entity-preview", { caption = "Entity Preview", entity = testProps.player.get_associated_characters()[1] });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for empty-widget', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("empty-widget", { caption = "Empty Widget" });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)

    it('should render an element for tabbed-pane', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("tabbed-pane", { caption = "Tabbed Pane" },
            createElement("tab", { caption = "Tab A", badge_text = 3 }),
            createElement("tab", { caption = "Tab B", badge_text = 2 }),
            createElement("tab", { caption = "Tab C", badge_text = 1 })
        );

        assert(type(vnode) == "table", "createElement did not return a vnode")
        assert(#vnode.children == 3, "Tabbed pane should have 3 tabs")

        return React.render(vnode, host)
    end)

    it('should render an element for switch', function(testProps)
        local host = testProps.hostElement
        local vnode = createElement("switch", { caption = "Switch", switch_state = "none", allow_none_state = true });

        assert(type(vnode) == "table", "createElement did not return a vnode")

        return React.render(vnode, host)
    end)
end)