--- Reactorio Hooks

if ... ~= "__react__.lib.hooks" then
    return require("__react__.lib.hooks")
end

local function some(tbl, func)
    for i, v in ipairs(tbl) do
        if func(v, i) then
            return true
        end
    end
    return false
end

local hooks
local index = nil
local forceUpdate
local function enableHookContext(h, i, fu)
    hooks = h
    index = i
    forceUpdate = fu
end
local function disableHookContext()
    index = nil
    return hooks
end

local function getHook(value)
    if not index then error("Hooks can only be called inside components") end
    index = index + 1
    local hook = hooks[index]
    if not hook then
        hook = { value = value }
        hooks[index] = hook
    end
    return hook
end

--- A hook that lets you manage local component state with a reducer
--- 
--- @param reducer function a function that takes the current state and an action and returns the new state
--- @param initialState any initial state value
--- @return any state, function dispatch the current state value and a function to update it
--- 
--- @see https://react.dev/reference/react/useReducer
local function useReducer(reducer, initialState)
    local hook = getHook(initialState)
    local update = forceUpdate
    local function dispatch(action)
        hook.value = reducer(hook.value, action)
        update()
    end
    return hook.value, dispatch
end

--- A hook that lets you add state to your component
--- 
--- @param initialState any initial state value
--- @return any state, function setState the current state value and a function to update it
--- 
--- @see https://react.dev/reference/react/useState
local function useState(initialState)
    return useReducer(function(_, v) return v end, initialState)
end

local function changed(a, b)
    return not a or some(b, function(arg, i) return arg ~= a[i + 1] end)
end

--- A hook that lets you synchronize a component with other systems
--- 
--- @param cb function callback to run when dependencies changed
--- @param deps table list of dependencies
--- 
--- Note: Dependencies table must be a flat table of the actual values, not the variable names used in the component
--- 
--- @see https://react.dev/reference/react/useEffect
local function useEffect(cb, deps)
    local dependencies = deps or {}
    local hook = getHook()
    if changed(hook.deps, dependencies) then
        hook.deps = dependencies
        hook.cb = cb
    end
end

--- A hook that lets you memoize expensive calculations
--- 
--- @param factory function a function that returns the value to memoize
--- @param deps table list of dependencies
--- @return any any memoized value
--- 
--- Note: Dependencies table must be a flat table of the actual values, not the variable names used in the component
--- 
--- @see https://react.dev/reference/react/useMemo
local function useMemo(factory, deps)
    local dependencies = deps or {}
    local hook = getHook()
    if changed(hook.deps, dependencies) then
        hook.value = factory()
        hook.deps = dependencies
        hook.factory = factory
    end
    return hook.value
end

--- A hook that lets you memoize functions, useful for event handlers
--- 
--- @param cb function a function to memoize
--- @param deps table list of dependencies
--- @return function any memoized function
--- 
--- Note: Dependencies table must be a flat table of the actual values, not the variable names used in the component
--- 
--- @see https://react.dev/reference/react/useCallback
local function useCallback(cb, deps)
    return useMemo(function() return cb end, deps)
end

return {
    -- Core util for hooks
    enableHookContext = enableHookContext,
    disableHookContext = disableHookContext,

    -- Hooks
    useReducer = useReducer,
    useState = useState,
    useEffect = useEffect,
    useMemo = useMemo,
    useCallback = useCallback
}