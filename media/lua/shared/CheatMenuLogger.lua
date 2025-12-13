local function emit(context, err, stack)
	print(string.format("[ZedToolbox] %s failed: %s\n%s", context or "unknown", tostring(err or "(nil)"), stack or "(no stack)"))
end

local function createFallback()
	local fallback = {}

	function fallback.writeError(context, err, stack)
		emit(context, err, stack)
	end

	function fallback.safeCall(context, fn, ...)
		if type(fn) ~= "function" then
			return false, "invalid function"
		end
		local ok, result = pcall(fn, ...)
		if not ok then
			local trace = debug and debug.traceback and debug.traceback(result, 2) or tostring(result)
			emit(context, result, trace)
		end
		return ok, result
	end

	function fallback.wrap(target, methodName, context)
		if not target or not methodName then
			return
		end
		local original = target[methodName]
		if type(original) ~= "function" then
			return
		end
		target[methodName] = function(...)
			return fallback.safeCall(context or methodName, original, ...)
		end
	end

	return fallback
end

local function getLogger()
	local ok, logger = pcall(require, "ZedToolboxLogger")
	if ok and type(logger) == "table" and type(logger.safeCall) == "function" then
		return logger
	end
	return createFallback()
end

return getLogger()
