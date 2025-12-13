local Logger = {}

local MOD_ID = "ZedToolbox"
local LOG_DIR = "logs"

local function sanitize(text)
    return (text or "general"):gsub("[^%w_-]", "_")
end

local function buildFileName(context)
    local stamp = os.date("%Y-%m-%d_%H-%M-%S")
    local name = string.format("error-%s-%s.txt", sanitize(context))
    return string.format("%s/%s", LOG_DIR, name), stamp
end

function Logger.writeError(context, err, stack)
    local path, stamp = buildFileName(context or "general")
    local writer
    if getModFileWriter then
        writer = getModFileWriter(MOD_ID, path, true, false)
    end
    local message = string.format("[%s]\nContext: %s\nError: %s\n\nStack Trace:\n%s\n",
        stamp,
        context or "general",
        tostring(err or "(nil)"),
        stack or "(no stack)")
    if writer then
        writer:write(message)
        writer:close()
    end
    print(string.format("[ZedToolbox] Error captured (%s). Log: %s", context or "general", path))
end

function Logger.safeCall(context, fn, ...)
    if type(fn) ~= "function" then
        return false, "invalid function"
    end
    local function handler(err)
        local stack = debug and debug.traceback and debug.traceback(err, 2) or tostring(err)
        Logger.writeError(context, err, stack)
        return err
    end
    if xpcall then
        return xpcall(function()
            return fn(...)
        end, handler)
    end
    local ok, result = pcall(fn, ...)
    if not ok then
        handler(result)
    end
    return ok, result
end

function Logger.wrap(target, methodName, context)
    if not target or not methodName then
        return
    end
    local original = target[methodName]
    if type(original) ~= "function" then
        return
    end
    target[methodName] = function(...)
        return Logger.safeCall(context or methodName, original, ...)
    end
end

return Logger
