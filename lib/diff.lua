local options = {}

--- Diff two virtual nodes and apply proper changes to the DOM
--- @param parentDom LuaGuiElement The parent of the DOM element
--- @param newVNode VNode The new virtual node
--- @param oldVNode VNode The old virtual node
--- @param globalContext table The current context object. Modified by
--- getChildContext
--- @param excessDomChildren LuaGuiElement[]
--- @param commitQueue LuaGuiElement[] List of components which have callbacks
--- to invoke in commitRoot
--- @param oldDom PreactElement The current attached DOM element any new dom
--- elements should be placed around. Likely `null` on first render (except when
--- hydrating). Can be a sibling DOM element when diffing Fragments that have
--- siblings. In most cases, it starts out as `oldChildren[0]._dom`.
--- @param isHydrating boolean Whether or not we are in hydration
--- @param refQueue any[] an array of elements needed to invoke refs
local function applyDiff(
   parentDom,
   newVNode,
   oldVNode,
   globalContext,
   excessDomChildren,
   commitQueue,
   oldDom,
   isHydrating,
   refQueue
)
    local tmp, newType = nil, newVNode.type;

    if oldVNode._flags & MODE_SUSPENDED then
        isHydrating = !!(oldVNode._flags & MODE_HYDRATE)
        newVNode._dom = oldVNode._dom
		oldDom = oldVNode._dom
		excessDomChildren = { oldDom }
    end

    -- break outer -> goto endDiff
    if (type(newType) == "function") then
        -- TODO: try/catch build

    elseif (not excessDomChildren) and newVNode._original == oldVNode._original then
		newVNode._children = oldVNode._children
		newVNode._dom = oldVNode._dom
	else
		newVNode._dom = diffElementNodes(
			oldVNode._dom,
			newVNode,
			oldVNode,
			globalContext,
			excessDomChildren,
			commitQueue,
			isHydrating,
			refQueue
		)
    end

    ::endDiff::
end

--- Invoke or update a ref, depending on whether it is a function or object ref.
--- @param ref Ref<any> & { _unmount?: unknown }
--- @param component LuaGuiElement
--- @param vnode VNode
local function applyRef(ref, component, vnode)
    if type(ref) == "function" then
        local hasRefUnmount = type(ref._unmount) == "function"
        if hasRefUnmount then
            local status, res = pcall(ref._unmount)
            if not status then
		        options._catchError(res, vnode)
            end
        end

        if (not hasRefUnmount) or (component ~= nil) then
            local status, res = pcall(ref, component)
            if (not status) then
		        options._catchError(res, vnode)
            else
                ref._unmount = res
            end
        end
    else
        ref.current = component
    end
end

--- @param commitQueue LuaGuiElement[] List of components which have callbacks to invoke in commitRoot
--- @param root VNode
--- @param refQueue Ref<any>[]
local function commitRoot(commitQueue, root, refQueue)
    for _, v in ipairs(refQueue) do
        local ref, component, vnode = table.unpack(v)
        applyRef(ref, component, vnode)
    end

    for _, c in pairs(commitQueue) do
        commitQueue = c.tags._renderCallbacks
        c.tags._renderCallbacks = {}
        for _, cb in pairs(commitQueue) do
            local status, err = pcall(cb, c)
            if not status then
                options._catchError(err, c.tags._vnode)
                goto endProcessing
            end
        end
    end

    ::endProcessing::
end

return {
    applyDiff,
    commitRoot,
    applyRef,
}