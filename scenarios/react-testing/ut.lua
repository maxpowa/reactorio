UnitTest = {
    __suites = {},
    __results = {},
    __totalTestCount = 0,
    __passing = 0,
    __failing = 0
}

local function __emit(status, suiteName, testCaseName)
    UnitTest.__results[suiteName] = UnitTest.__results[suiteName] or {}
    table.insert(UnitTest.__results[suiteName], { status = status, testCaseName = testCaseName })
    if status == "pass" then
        UnitTest.__passing = UnitTest.__passing + 1
    else
        UnitTest.__failing = UnitTest.__failing + 1
    end
end

function UnitTest.assert(condition, msg)
    if not condition then
        error(msg)
    end
end

local suiteRef = {}
function UnitTest.describe(suiteName, suiteFn)
    if suiteRef.current then
        error("Test suites cannot be nested")
    end

    UnitTest.__suites[suiteName] = function()
        suiteRef.current = suiteName
        suiteFn()
        suiteRef.current = nil
    end
end

local runnerVArgs = {}
function UnitTest.it(testCaseName, testCaseFn)
    if not suiteRef.current then
        error("Test cases must be defined within a suite (describe block)")
    end

    UnitTest.__totalTestCount = UnitTest.__totalTestCount + 1
    local status, err = pcall(testCaseFn, runnerVArgs.current)
    if status then
        __emit("pass", suiteRef.current, testCaseName)
    else
        __emit("fail", suiteRef.current, testCaseName .. " - " .. err)
    end
end

function UnitTest.reset()
    UnitTest.__suites = {}
    UnitTest.__results = {}
    UnitTest.__totalTestCount = 0
    UnitTest.__passing = 0
    UnitTest.__failing = 0
end

function UnitTest.summary()
    return {
        total = UnitTest.__totalTestCount,
        passing = UnitTest.__passing,
        failing = UnitTest.__failing,
        results = UnitTest.__results,
    }
end

function UnitTest.run(...)
    for _, suiteFn in pairs(UnitTest.__suites) do
        runnerVArgs.current = ...
        suiteFn()
        runnerVArgs.current = nil
    end
    return UnitTest.summary()
end

return UnitTest
