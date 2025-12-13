local CheatMenuText = {}

local function safeGetText(key, ...)
    if not getText then
        return nil
    end
    local ok, result = pcall(getText, key, ...)
    if ok and result and result ~= key then
        return result
    end
    return nil
end

function CheatMenuText.get(key, fallback, ...)
    if key then
        local translated = safeGetText(key, ...)
        if translated then
            return translated
        end
    end
    if select("#", ...) > 0 then
        return string.format(fallback or (key or ""), ...)
    end
    return fallback or key or ""
end

return CheatMenuText
