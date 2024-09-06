local hooks = require("__react__.lib.hooks")
local Component = require("__react__.lib.component").Component
local Fragment = require("__react__.lib.create").Fragment

local function shallowEquals(newProps, oldProps)
    if newProps == oldProps then
        return false
    elseif type(newProps) ~= type(oldProps) then
        return true
    elseif type(newProps) ~= "table" then
        return true
    elseif #newProps ~= #oldProps then
        return true
    else
        local keySet = {}
        for k, v in pairs(newProps) do
            if newProps[k] ~= oldProps[k] then
                return true
            end
            keySet[k] = true
        end
        for k2, _ in pairs(oldProps) do
            if not keySet[k2] then
                return true
            end
        end
    end
    return false
end

local function applyDiffChildren(
    parentDom,
    renderResult,
    newParentVNode,
    oldParentVNode,
    globalContext,
    excessDomChildren,
    commitQueue,
    oldDom,
    isHydrating,
    refQueue
)
    local oldChildren = oldParentVNode and oldParentVNode._children or nil
    local newChildrenLength = #renderResult

    newParentVNode._nextDom = oldDom
    oldDom = 
end

local function applyDiffElementNodes(
    dom,
    newVNode,
    oldVNode,
    globalContext,
    excessDomChildren,
    commitQueue,
    isHydrating,
    refQueue
)
    -- this is what should actually create/update LuaGuiElements
end

--- Diff two virtual nodes and apply proper changes to the DOM
--- @param parentDom LuaGuiElement The parent of the DOM element
--- @param newVNode VNode The new virtual node
--- @param oldVNode VNode The old virtual node
--- @param globalContext table The current context object. Modified by getChildContext
--- @param excessDomChildren Component[]
--- @param commitQueue Component[] List of components which have callbacks to invoke in commitRoot
--- @param oldDom LuaGuiElement The current attached DOM element any new dom
---  elements should be placed around. Likely `null` on first render (except when
---  hydrating). Can be a sibling DOM element when diffing Fragments that have
---  siblings. In most cases, it starts out as `oldChildren[0]._dom`.
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
    local newType, isNew = newVNode.type, false

    hooks.on_diff(newVNode)

    -- break outer -> goto endDiff
    if (type(newType) == "function") then
        local newProps = newVNode.props
        local oldProps = oldVNode and oldVNode.props or newProps

        -- TODO: create component from vnode if it doesnt exist yet
        if oldVNode._component then
            newVNode._component = oldVNode._component
        else
            newVNode._component = Component:new{
                _dirty = true,
                _renderFunc = newType,
            }
            isNew = true
        end
        ---@type Component
        local comp = newVNode._component

        -- TODO: implement shallow diff for shouldComponentUpdate
        if (not isNew) and (not shallowEquals(newProps, oldProps)) then
            if (newVNode._original ~= oldVNode._original) then
                comp.state = comp._nextState
                comp._dirty = false
            end

            newVNode._dom = oldVNode._dom
            newVNode._children = oldVNode._children
            for _, vnode in pairs(newVNode._children) do
                if vnode then vnode._parent = newVNode end
            end

            if #comp._renderCallbacks then
                commitQueue[#commitQueue + 1] = comp
            end

            goto endDiff
        end

        local count = 0
        local tmp = nil
        repeat
            comp._dirty = false
            hooks.on_render(newVNode)

            tmp = comp.render(newVNode.props, comp.state, globalContext)

            comp.state = comp._nextState
            count = count + 1
        until (not comp._dirty) or count > 25

        comp.state = comp._nextState

        local isTopLevelFragment = tmp and tmp.type == Fragment
        local renderResult = tmp
        if isTopLevelFragment and tmp then
            renderResult = tmp.props.children
        end

        if not is_array(renderResult) then
            renderResult = { renderResult }
        end

        applyDiffChildren(
            parentDom,
            renderResult,
            newVNode,
            oldVNode,
            globalContext,
            excessDomChildren,
            commitQueue,
            oldDom,
            isHydrating,
            refQueue
        )

        comp.base = newVNode._dom

        if #comp._renderCallbacks > 0 then
            commitQueue[#commitQueue + 1] = comp
        end
    elseif (not excessDomChildren) and newVNode._original == oldVNode._original then
        newVNode._children = oldVNode._children
        newVNode._dom = oldVNode._dom
    else
        newVNode._dom = applyDiffElementNodes(
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

    hooks.on_after_diff(newVNode)

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

--- @param commitQueue Component[] List of components which have callbacks to invoke in commitRoot
--- @param root VNode
--- @param refQueue Ref<any>[]
local function commitRoot(commitQueue, root, refQueue)
    for _, v in ipairs(refQueue) do
        local ref, component, vnode = table.unpack(v)
        applyRef(ref, component, vnode)
    end

    for _, c in pairs(commitQueue) do
        commitQueue = c._renderCallbacks
        c._renderCallbacks = {}
        for _, cb in pairs(commitQueue) do
            local status, err = pcall(cb, c)
            if not status then
                options._catchError(err, c._vnode)
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
