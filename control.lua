-- https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/aa61fe5e3782ed0b8914caa1ac9986f985000fb0/doc/debugapi.md#detecting-debugging
if __DebugAdapter then
    if script.active_mods["gvv"] then require("__gvv__.gvv")() end
    -- only load the test suite if we're in debug mode
    require("test.init")
end