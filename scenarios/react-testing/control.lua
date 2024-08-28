-- https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/aa61fe5e3782ed0b8914caa1ac9986f985000fb0/doc/debugapi.md#detecting-debugging
if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-- Load the test suite
require("init")