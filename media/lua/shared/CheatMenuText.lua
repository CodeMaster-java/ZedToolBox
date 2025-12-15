local CheatMenuText = {}

local MOD_ID = "zedtoolbox"
local DEFAULT_LANGUAGE = "en"

local languages = {}
local languagesById = {}
local cachedTranslations = {}
local currentLanguage = DEFAULT_LANGUAGE
local LANGUAGE_ALIASES = {
    english = "en",
    en = "en",
    us = "en",
    americanenglish = "en",
    brazilianportuguese = "pt_br",
    brazillianportuguese = "pt_br",
    portuguese = "pt_br",
    pt_br = "pt_br"
}

local LANGUAGE_LABELS = {
    en = "English",
    pt_br = "Português (Brasil)"
}

local function discoverLanguages()
    languagesById = {}
    cachedTranslations = {}
    if getModDirectoryTable then
        local root = getModDirectoryTable(MOD_ID)
        if root and root.children then
            local translateDir = root.children.Translate or root.children.translate
            if translateDir and translateDir.children then
                for name, entry in pairs(translateDir.children) do
                    if entry.children then
                        for fileName, fileEntry in pairs(entry.children) do
                            if fileName:lower():match("%.txt$") then
                                local normalized = name:gsub("[^%w_]", "_"):lower()
                                normalized = normalized:gsub("__+", "_")
                                local languageId = LANGUAGE_ALIASES[normalized] or normalized
                                if languageId ~= "" and not languagesById[languageId] then
                                    local label = LANGUAGE_LABELS[languageId] or entry.displayName or name
                                    local relativePath = string.format("media/lua/shared/Translate/%s/%s", name, fileName)
                                    local absolutePath = fileEntry.fullPath or fileEntry.path
                                    languagesById[languageId] = {
                                        id = languageId,
                                        label = label,
                                        path = relativePath,
                                        absolute = absolutePath
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if not languagesById.en then
        languagesById.en = { id = "en", label = LANGUAGE_LABELS.en or "English", path = "media/lua/shared/Translate/EN/ZedToolbox_EN.txt" }
    end
    if not languagesById.pt_br then
        languagesById.pt_br = { id = "pt_br", label = LANGUAGE_LABELS.pt_br or "Brazilian Portuguese", path = "media/lua/shared/Translate/BrazilianPortuguese/ZedToolbox_BP.txt" }
    end
    languages = {}
    for _, entry in pairs(languagesById) do
        table.insert(languages, entry)
    end
    table.sort(languages, function(a, b)
        return string.lower(a.label) < string.lower(b.label)
    end)
end

discoverLanguages()

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

local function trim(text)
    if not text then
        return ""
    end
    local cleaned = text:gsub("^" .. string.char(0xEF, 0xBB, 0xBF), "")
    return cleaned:gsub("^%s+", ""):gsub("%s+$", "")
end

local function parseTranslation(definition)
    if not definition then
        return nil
    end
    local reader
    if definition.absolute and getFileReader then
        reader = getFileReader(definition.absolute, false)
    end
    if not reader and getModFileReader then
        reader = getModFileReader(MOD_ID, definition.path, false)
    end
    if not reader then
        return nil
    end
    local data = {}
    while true do
        local raw = reader:readLine()
        if not raw then
            break
        end
        local line = trim(raw)
        if line ~= "" and not line:find("^#") then
            local key, value = line:match("([^=]+)=(.*)")
            if key and value then
                data[trim(key)] = trim(value)
            end
        end
    end
    reader:close()
    return data
end

local function getTranslations(languageId)
    if cachedTranslations[languageId] ~= nil then
        return cachedTranslations[languageId]
    end
    local definition = languagesById[languageId]
    if not definition then
        cachedTranslations[languageId] = nil
        return nil
    end
    cachedTranslations[languageId] = parseTranslation(definition)
    return cachedTranslations[languageId]
end

local function lookup(languageId, key)
    local translations = getTranslations(languageId)
    if translations then
        local value = translations[key]
        if value and value ~= "" then
            return value
        end
    end
    return nil
end

local function formatWithArgs(text, ...)
    local argCount = select("#", ...)
    if not text or argCount == 0 then
        return text
    end
    local args = { ... }
    local formatted = text
    if formatted:find("%1", 1, true) then
        formatted = formatted:gsub("%%(%d+)", function(index)
            local position = tonumber(index)
            if position and position >= 1 and position <= argCount then
                return tostring(args[position])
            end
            return "%" .. index
        end)
        return formatted
    end
    local unpackArgs = table.unpack or unpack
    local ok, result = pcall(string.format, formatted, unpackArgs(args, 1, argCount))
    return ok and result or formatted
end

function CheatMenuText.setLanguage(languageId)
    local target = languagesById[languageId] and languageId or DEFAULT_LANGUAGE
    currentLanguage = target
    cachedTranslations = {}
    return currentLanguage
end

function CheatMenuText.getCurrentLanguage()
    return currentLanguage
end

function CheatMenuText.getDefaultLanguage()
    return DEFAULT_LANGUAGE
end

function CheatMenuText.getLanguages()
    discoverLanguages()
    local list = {}
    for _, entry in ipairs(languages) do
        list[#list + 1] = { id = entry.id, label = entry.label }
    end
    return list
end

function CheatMenuText.get(key, fallback, ...)
    if key then
        local text = lookup(currentLanguage, key)
        if not text and currentLanguage ~= DEFAULT_LANGUAGE then
            text = lookup(DEFAULT_LANGUAGE, key)
        end
        if text then
            return formatWithArgs(text, ...)
        end
        local translated = safeGetText(key, ...)
        if translated then
            return translated
        end
    end
    local base = fallback or key or ""
    if select("#", ...) > 0 then
        return formatWithArgs(base, ...)
    end
    return base
end

return CheatMenuText
