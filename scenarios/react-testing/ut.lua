UnitTest = {
    __suites = {},
}

function UnitTest.assert(condition, msg)
    if not condition then
        error(msg)
    end
end

local function buildSuite(suiteName, tests)
    local keys = {}
    for k, _ in pairs(tests) do
        table.insert(keys, k)
    end
    local i = 1
    return {
        name = suiteName,
        tests = tests,
        runAll = function()
            for _, test in pairs(tests) do
                test.run()
            end
        end,
        runNext = function(...)
            if i <= #keys then
                local result = tests[keys[i]].run(...)
                i = i + 1
                return result
            end
            return nil
        end
    }
end

function UnitTest.getRunner()
    local suites = {}
    for k, _ in pairs(UnitTest.__suites) do
        table.insert(suites, buildSuite(k, UnitTest.__suites[k].tests))
    end
    local i = 1

    local function runNext(...)
        if i <= #suites then
            local result = suites[i].runNext(...)
            if (result == nil) then
                i = i + 1
                if (i <= #suites) then
                    return runNext(...)
                end
                return nil
            end
            return result
        end
        return nil
    end

    return {
        runNext = runNext
    }
end

local suiteRef = {
    name = nil,
    tests = {}
}
function UnitTest.describe(suiteName, suiteFn)
    if suiteRef.name then
        error("Test suites cannot be nested")
    end
    if (UnitTest.__suites[suiteName]) then
        error("Suite already exists: " .. suiteName)
    end

    suiteRef.name = suiteName
    suiteRef.tests = {}
    suiteFn()
    suiteRef.name = nil

    UnitTest.__suites[suiteName] = {
        name = suiteName,
        tests = suiteRef.tests,
    }
end

function UnitTest.it(testCaseName, testCaseFn)
    if not suiteRef.name then
        error("Test cases must be defined within a suite (describe block)")
    end

    local suiteName = suiteRef.name

    local fn = function(...)
        local status, err = pcall(testCaseFn, ...)
        return status, err
    end
    table.insert(suiteRef.tests, { name = testCaseName, suite = suiteName, run = fn })
end

return UnitTest
