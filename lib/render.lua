-- Reactorio (React for Factorio) core logic

if ... ~= "__react__.lib.core" then
    return require("__react__.lib.core")
end

-- Explicit imports here prevent scope pollution
local diff = require("__react__.lib.diff")
local createElement = require("__react__.lib.create").createElement
local Fragment = require("__react__.lib.constants").Fragment
local EMPTY_OBJ = require("__react__.lib.constants").EMPTY_OBJ

--- Renders a virtual element tree to a parent element
---
--- @param vnode ComponentChild list of virtual elements, created by React.createElement
--- @param parentDom LuaGuiElement element to render to
--- @param isHydrating? boolean element to replace
---
--- @see createElement
local function render(vnode, parentDom, isHydrating)
	-- To be able to support calling `render()` multiple times on the same
	-- DOM node, we need to obtain a reference to the previous tree. We do
	-- this by assigning a new `_children` property to DOM nodes which points
	-- to the last rendered tree. By default this property is not present, which
	-- means that we are mounting a new tree for the first time.
	local oldVNode = nil

    vnode = createElement(Fragment, nil, { vnode });
    if not isHydrating then
		oldVNode = parentDom.tags._children;
        parentDom.tags._children = vnode
    else
        parentDom.tags._children = vnode
    end

    local excessDomChildren = nil
    local oldDom = nil

    if not isHydrating then
        if oldVNode then
            oldDom = oldVNode.tags._dom
        else
            -- TODO: this is kind of weird, there's no check to see if this would be non-nil but I guess its fine if this is nil
            oldDom = parentDom.children[1]
            if #parentDom.children > 0 then
                -- TODO: should this be deepcopied? I think it should be fine if we don't mutate excessDomChildren
                excessDomChildren = parentDom.children
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
	render(vnode, parentDom, true);
end

return {
    render = render,
    hydrate = hydrate,
}
