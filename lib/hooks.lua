local requestAnimationFrame = require("__react__.lib.events").requestAnimationFrame

-- setup the hook render state
local currentIndex, currentComponent, previousComponent, currentHook
local afterPaintEffects = {}

local function on_diff(newVNode)
    currentComponent = nil
end

local function invokeCleanup(hook)
    -- a hook cleanup can call render, which would change the currentComponent context if we aren't careful
    local comp = currentComponent
    local cleanup = hook._cleanup
    if (type(cleanup) == "function") then
        hook._cleanup = nil
        cleanup()
    end
    currentComponent = comp
end

local function invokeEffect(hook)
    local comp = currentComponent
    hook._cleanup = hook._value();
    currentComponent = comp;
end

local function flushAfterPaintEffects()
    if (#afterPaintEffects < 1) then
        return
    end

    local component
    repeat
        component = table.remove(afterPaintEffects, #afterPaintEffects)
        if (component._parentDom and component._hooks) then
            local hooks = component._hooks
            for _, hookItem in ipairs(hooks._pendingEffects) do
                pcall(invokeCleanup, hookItem)
            end
            for _, hookItem in ipairs(hooks._pendingEffects) do
                pcall(invokeEffect, hookItem)
            end
            hooks._pendingEffects = {}
        end
    until component == nil
end

local function afterPaint(newQueueLength)
    if (newQueueLength == 1) then
        requestAnimationFrame(flushAfterPaintEffects)
    end
end

local function on_render(vnode)
    currentComponent = vnode._component
    currentIndex = 0

    local hooks = currentComponent.__hooks
    if hooks then
        if (previousComponent == currentComponent) then
            hooks._pendingEffects = {}
            currentComponent._renderCallbacks = {}
            for _, hookItem in ipairs(hooks._list) do
                if (hookItem._nextValue) then
                    hookItem._value = hookItem._nextValue
                end
                hookItem._pendingArgs = nil
                hookItem._nextValue = nil
            end
        else
            for _, hookItem in ipairs(hooks._pendingEffects) do
                pcall(invokeCleanup, hookItem)
            end
            for _, hookItem in ipairs(hooks._pendingEffects) do
                pcall(invokeEffect, hookItem)
            end
            hooks._pendingEffects = {}
            currentIndex = 0
        end
    end
    previousComponent = currentComponent
end

local function on_after_diff(vnode)
    local c = vnode._component;
    if (c and c.__hooks) then
        if (#c.__hooks._pendingEffects > 0) then
            local index = #afterPaintEffects + 1
            afterPaintEffects[index] = c
            afterPaint(index)
        end
        for _, hookItem in ipairs(c.__hooks._list) do
            if (hookItem._pendingArgs) then
                hookItem._args = hookItem._pendingArgs
            end
            hookItem._pendingArgs = nil
        end
    end
    previousComponent = nil
    currentComponent = nil
end

return {
    on_diff = on_diff,
    on_after_diff = on_after_diff,
    on_render = on_render
}
