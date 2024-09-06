local diff = require("__react__.lib.diff")

local function updateParentDomPointers(vnode)
    if vnode._parent then
        vnode = vnode._parent
        if vnode._component then
            vnode._component.base = nil
            vnode._dom = nil
            for _, child in ipairs(vnode._children) do
                if child and child._dom then
                    vnode._component.base = child._dom
                    vnode._dom = child._dom
                    break
                end
            end

            return updateParentDomPointers(vnode)
        end
    end
end

local function getDomSibling(vnode, childIndex)
    if not childIndex then
        if vnode._parent then
            return getDomSibling(vnode._parent, vnode._index + 1)
        end
        return nil
    end

    for _, sibling in ipairs(vnode.children) do
        if sibling and sibling._dom then
            return sibling._dom
        end
    end

    if type(vnode.type) == "function" then
        return getDomSibling(vnode)
    end
    return nil
end

local function renderComponent(component)
    local oldVNode, commitQueue, refQueue = component._vnode, {}, {}
    local oldDom = oldVNode._dom

    if component._parentDom then
        local newVNode = util.table.deepcopy(oldVNode)
        newVNode._original = oldVNode._original + 1

        local dom = nil
        if oldVNode._hydrating then
            dom = { oldDom }
        end

        diff.applyDiff(
            component._parentDom,
            newVNode,
            oldVNode,
            component._globalContext,
            dom,
            commitQueue,
            oldDom or getDomSibling(oldVNode),
            oldVNode._hydrating,
            refQueue
        )

        newVNode._original = oldVNode._original
        newVNode._parent._children[newVNode._index] = newVNode
        diff.commitRoot(commitQueue, newVNode, refQueue)

        if newVNode._dom ~= oldDom then
            updateParentDomPointers(newVNode)
        end
    end
end

local rerenderQueue = {}
local rerenderCount = 0

local function depthSort(a, b)
    return a._vnode._depth < b._vnode._depth
end

local function process() 
    -- sort render queue by depth
    table.sort(rerenderQueue, depthSort)
    while #rerenderQueue > 0 do
        -- pop the top component off the stack
        local c = rerenderQueue[#rerenderQueue]
        rerenderQueue[#rerenderQueue] = nil
        if c._dirty then
            local queueSize = #rerenderQueue
            renderComponent(c)
            if #rerenderQueue > queueSize then
                -- if rerendering caused more items to be added to the queue, sort by depth so we can handle them in the correct order
                table.sort(rerenderQueue, depthSort)
            end
        end
    end
    rerenderCount = 0
end

local function enqueueRender(c)
    if not c._dirty then
        c._dirty = true
        table.insert(rerenderQueue, c)
        rerenderCount = rerenderCount + 1
    end
    process()
end

---@class Component
local Component = {
    _dirty = true,
    state = {},
    _force = false,
    _nextState = {},
    _renderCallbacks = {},
    _hooks = nil,
    _renderFunc = nil,
    _vnode = nil,
    ---@type LuaGuiElement|nil
    base = nil
}

function Component:new(input)
    local instance = input or {}
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function Component:render(props, state, context)
    if self._renderFunc then
        return self._renderFunc(props, state, context)
    end
    return nil
end

function Component:forceUpdate(callback)
    if self._vnode then
        self._force = true
        if callback then
            table.insert(self._renderCallbacks, callback)
        end
        enqueueRender(self._vnode)
    end
end

return {
    Component = Component,
    enqueueRender = enqueueRender,
}