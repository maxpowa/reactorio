if ... ~= "__react__.react" then
    return require("__react__.react")
end

local core = require("__react__.lib.core")
local hooks = require("__react__.lib.hooks")
local lsx = require("__react__.lib.lsx")

return {
    -- Core
    createElement = core.createElement,
    h = core.createElement,
    render = core.render,

    -- Hooks
    useReducer = hooks.useReducer,
    useState = hooks.useState,
    useEffect = hooks.useEffect,
    useMemo = hooks.useMemo,
    useCallback = hooks.useCallback,
    useRef = hooks.useRef,

    -- LSX
    lsx = lsx.lsx
}