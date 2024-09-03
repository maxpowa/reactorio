-- Reactorio (React for Factorio) core logic

if ... ~= "__react__.lib.core" then
    return require("__react__.lib.core")
end

-- Explicit imports here prevent scope pollution
local diff = require("__react__.lib.diff")

-- Helper functions since I'm a filthy typescript user and I can't live without certain niceties
local function merge(tbl1, tbl2)
    local result = {}
    for k, v in pairs(tbl1) do
        result[k] = v
    end
    for k, v in pairs(tbl2) do
        result[k] = v
    end
    return result
end
local function is_array(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function addElementToParent(v, parent, index)
    if (v.type ~= nil) then
        local props = {}

        -- omit event handlers from props
        for k, _ in pairs(v.props or {}) do
            if (k:find("on_gui_") == 1 or k == "ref") then
                -- do nothing
            elseif (k == "style") then
                if type(v.props.style) == "string" then
                    -- factorio only allows style at `.add` if its a string, otherwise it errors
                    props.style = v.props.style
                elseif (v.props.style.name) then
                    -- we can initialize the style prop with the name value if it exists
                    props.style = v.props.style.name
                end
            else
                props[k] = v.props[k]
            end
        end

        return parent.add(merge(props, { type = v.type, index = index }))
    elseif (type(v) == "string") then
        return parent.add({ type = "label", caption = v, index = index })
    else
        error("Invalid element: " .. serpent.line(v))
    end
end

local function compareNodeProp(node, k, v)
    -- Wube, WHY?!
    if (node.type == "slider") then
        if (k == "value") then
            return node.slider_value ~= v
        elseif (k == "minimum_value") then
            return node.get_slider_minimum() ~= v
        elseif (k == "maximum_value") then
            return node.get_slider_maximum() ~= v
        elseif (k == "value_step") then
            return node.get_slider_value_step() ~= v
        elseif (k == "discrete_slider") then
            return node.get_slider_discrete_slider() ~= v
        elseif (k == "discrete_values") then
            return node.get_slider_discrete_values() ~= v
        end
    end
    return node[k] ~= v
end

local function updateNodeProp(node, k, v)
    -- Wube, this is infuriating... The game is practically unplayable now that I know about this.
    if (node.type == "slider") then
        if (k == "value") then
            node.slider_value = v
            return
        elseif (k == "minimum_value") then
            node.set_slider_minimum_maximum(v, node.get_slider_maximum())
            return
        elseif (k == "maximum_value") then
            node.set_slider_minimum_maximum(node.get_slider_minimum(), v)
            return
        elseif (k == "value_step") then
            node.set_slider_value_step(v)
            return
        elseif (k == "discrete_slider") then
            node.set_slider_discrete_slider(v)
            return
        elseif (k == "discrete_values") then
            node.set_slider_discrete_values(v)
            return
        end
    end
    node[k] = v
end

-- TODO: investigate deferred rendering
--   should be able to defer rendering until next on_tick event, but that could easily cause problems in editor mode
-- immediate mode rendering
local function renderImmediate(vnode, index, parent, storage, recurse)
    local node = parent.children[index]
    local createdNewNode = false
    if (not node) or ((node and node.type) ~= vnode.type) then
        node = addElementToParent(vnode, parent, index)
        createdNewNode = true
        if not node then
            error("Failed to add element to GUI: " .. serpent.line(vnode))
        end
    end

    for k, v in pairs(vnode.props) do
        if (k:find("on_gui_") == 1 and type(v) == "function") then
            -- TODO: only add new handlers if they changed
            addScopedHandler(defines.events[k], node, v, node.index)
        elseif (k == "ref") then
            v.current = node
        elseif (k == "style") then
            -- set style updates directly on the element
            if type(v) ~= "string" then
                for styleKey, styleValue in pairs(v) do
                    if (node.style[styleKey] ~= styleValue) then
                        node.style[styleKey] = styleValue
                    end
                end
            end
        elseif ((not createdNewNode) and compareNodeProp(node, k, v)) then
            -- If we created a new node, we don't need to update it
            updateNodeProp(node, k, v)
        end
    end

    -- TODO: only rerender children if they changed (will need to store the previous children in storage I think...)
    -- setup children storage and render (needed even if there are no children, since we can't put arbitrary data on the element itself)
    storage.children = storage.children or {}
    storage.children[node.index] = storage.children[node.index] or {}
    recurse(vnode.children, node, storage.children[node.index])
end

--- A function that creates a virtual element for rendering. Alternatively, you can use the shorthand `h` function, or JSX.
---
--- @param type GuiElementType|function the type of element to create
--- @param props? table a table of properties to set on the element
--- @param ... table|string children - may be strings or other `createElement` results
--- @return table vlist virtual element node(s) (vnodes are implementation details and should not be accessed directly)
---
--- @see https://react.dev/reference/react/createElement
local function createElement(type, props, ...)
    local children = { ... }
    return { type = type, props = props or {}, children = children }
end

local function Fragment(props)
    return props.children
end

local EMPTY_OBJ = {}

--- Renders a virtual element tree to a parent element
---
--- @param vnode ComponentChild list of virtual elements, created by React.createElement
--- @param parentDom LuaGuiElement element to render to
--- @param replaceNode? LuaGuiElement|function element to replace
---
--- @see createElement
local function render(vnode, parentDom, replaceNode)
    -- We abuse the `replaceNode` parameter in `hydrate()` to signal if we are in
	-- hydration mode or not by passing the `hydrate` function instead of a DOM
	-- element..
	local isHydrating = type(replaceNode) == 'function'

	-- To be able to support calling `render()` multiple times on the same
	-- DOM node, we need to obtain a reference to the previous tree. We do
	-- this by assigning a new `_children` property to DOM nodes which points
	-- to the last rendered tree. By default this property is not present, which
	-- means that we are mounting a new tree for the first time.
	local oldVNode = nil

    vnode = createElement(Fragment, nil, { vnode });
    if not isHydrating then
		oldVNode = (replaceNode or parentDom).tags._children;
        (replaceNode or parentDom).tags._children = vnode
    else
        parentDom.tags._children = vnode
    end

    local excessDomChildren = nil
    local oldDom = nil

    if (not isHydrating) and replaceNode then
        oldDom = replaceNode
        excessDomChildren = { replaceNode }
    else
        if oldVNode then
            oldDom = oldVNode.tags._dom
        else
            -- TODO: this is kind of weird, there's no check to see if this would be non-nil but I guess its fine if this is nil
            oldDom = parentDom.children[1]
            if #parentDom.children > 0 then
                excessDomChildren = util.deepcopy(parentDom.children)
            end
        end
    end


	-- List of effects that need to be called after diffing.
	local commitQueue, refQueue = {}, {}
	diff.applyDiff(
		parentDom,
		-- Determine the new vnode tree and store it on the DOM element on
		-- our custom `_children` property.
		vnode,
		oldVNode or EMPTY_OBJ,
		EMPTY_OBJ,
		excessDomChildren,
		commitQueue,
		oldDom,
		isHydrating,
		refQueue
	)

	-- Flush all queued effects
	diff.commitRoot(commitQueue, vnode, refQueue);
end

--- Update an existing DOM element with data from a Preact virtual node
--- @param vnode ComponentChild The virtual node to render
--- @param parentDom LuaGuiElement The DOM element to update
local function hydrate(vnode, parentDom)
	render(vnode, parentDom, hydrate);
end

--- A function that creates a "react_root" element. This is used as a container for the element tree in `render`.
---
--- @param parent LuaGuiElement the parent element to add the root to (e.g. `player.gui.screen`)
--- @param props? table a table of properties to set on the root element (you should not need to)
---
--- @return LuaGuiElement root the root element
local function createRoot(parent, props)
    if parent["react_root"] then
        parent["react_root"].destroy()
    end
    return parent.add(merge(props or {}, { type = "flow", name = "react_root", }))
end

return {
    createRoot = createRoot,
    createElement = createElement,
    Fragment = Fragment,
    render = render,
    hydrate = hydrate,
}
