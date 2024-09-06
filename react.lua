if ... ~= "__react__.react" then
    return require("__react__.react")
end

local render = require("__react__.lib.render")
local hooks = require("__react__.lib.hooks")
local lsx = require("__react__.lib.lsx")

return {
    -- Core
    createRoot = create.createRoot,
    createElement = create.createElement,
    h = create.createElement,
    render = render.render,

    -- Hooks
    useReducer = hooks.useReducer,
    useState = hooks.useState,
    useEffect = hooks.useEffect,
    useMemo = hooks.useMemo,
    useCallback = hooks.useCallback,
    useRef = hooks.useRef,
    useEvent = hooks.useEvent,

    -- LSX
    lsx = lsx.lsx
}