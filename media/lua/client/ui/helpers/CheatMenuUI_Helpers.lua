local CheatMenuText = require "CheatMenuText"

local helpers = {}

local HOTKEY_SOURCE = {
    { label = "Insert", code = Keyboard.KEY_INSERT },
    { label = "Delete", code = Keyboard.KEY_DELETE },
    { label = "Home", code = Keyboard.KEY_HOME },
    { label = "End", code = Keyboard.KEY_END },
    { label = "F1", code = Keyboard.KEY_F1 },
    { label = "F2", code = Keyboard.KEY_F2 },
    { label = "F3", code = Keyboard.KEY_F3 },
    { label = "F4", code = Keyboard.KEY_F4 },
    { label = "F5", code = Keyboard.KEY_F5 },
    { label = "F6", code = Keyboard.KEY_F6 },
    { label = "F7", code = Keyboard.KEY_F7 },
    { label = "F8", code = Keyboard.KEY_F8 },
    { label = "F9", code = Keyboard.KEY_F9 },
    { label = "F10", code = Keyboard.KEY_F10 },
    { label = "F11", code = Keyboard.KEY_F11 },
    { label = "F12", code = Keyboard.KEY_F12 },
    { label = "Q", code = Keyboard.KEY_Q },
    { label = "E", code = Keyboard.KEY_E },
    { label = "R", code = Keyboard.KEY_R },
    { label = "T", code = Keyboard.KEY_T },
    { label = "Y", code = Keyboard.KEY_Y },
    { label = "U", code = Keyboard.KEY_U },
    { label = "I", code = Keyboard.KEY_I },
    { label = "O", code = Keyboard.KEY_O },
    { label = "P", code = Keyboard.KEY_P },
    { label = "K", code = Keyboard.KEY_K },
    { label = "L", code = Keyboard.KEY_L },
    { label = "Z", code = Keyboard.KEY_Z },
    { label = "X", code = Keyboard.KEY_X },
    { label = "C", code = Keyboard.KEY_C },
    { label = "V", code = Keyboard.KEY_V },
    { label = "B", code = Keyboard.KEY_B }
}

local HOTKEY_OPTIONS_CACHE = nil

function helpers.clamp(value, min, max)
    value = tonumber(value) or min
    if value < min then return min end
    if value > max then return max end
    return value
end

function helpers.getHotkeyOptions()
    if not HOTKEY_OPTIONS_CACHE then
        HOTKEY_OPTIONS_CACHE = {}
        for _, entry in ipairs(HOTKEY_SOURCE) do
            if type(entry.code) == "number" then
                table.insert(HOTKEY_OPTIONS_CACHE, entry)
            end
        end
    end
    return HOTKEY_OPTIONS_CACHE
end

function helpers.getCheatMenuMain()
    if package and package.loaded then
        local loaded = package.loaded["CheatMenuMain"]
        if type(loaded) == "table" then
            return loaded
        end
    end
    local ok, main = pcall(require, "CheatMenuMain")
    if ok and type(main) == "table" then
        return main
    end
    return nil
end

function helpers.lower(text)
    if not text then
        return ""
    end
    return string.lower(text)
end

function helpers.trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function helpers.clearControl(control)
    if not control then
        return
    end
    if type(control.clear) == "function" then
        control:clear()
        return
    end
    if type(control.clearItems) == "function" then
        control:clearItems()
        return
    end
    if control.items then
        control.items = {}
    end
    if control.options then
        control.options = {}
    end
    control.selected = 0
    if type(control.setScrollHeight) == "function" then
        control:setScrollHeight(0)
    end
end

function helpers.getListSelection(list)
    if not list or not list.items then
        return nil
    end
    local index = list.selected or 0
    if index < 1 then
        return nil
    end
    return list.items[index]
end

function helpers.getItemDisplayName(entry)
    if not entry then
        return ""
    end
    if entry.localizedName and entry.localizedName ~= "" then
        return entry.localizedName
    end
    if entry.name and entry.name ~= "" then
        return entry.name
    end
    local fullType = entry.fullType or entry.baseId
    if fullType and ScriptManager and ScriptManager.instance then
        local scriptItem = ScriptManager.instance:FindItem(fullType)
        if scriptItem then
            local display = scriptItem.getDisplayName and scriptItem:getDisplayName()
            if display and display ~= "" then
                return display
            end
            local rawName = scriptItem.getName and scriptItem:getName()
            if rawName and rawName ~= "" then
                return rawName
            end
            local fullName = scriptItem.getFullName and scriptItem:getFullName()
            if fullName and fullName ~= "" then
                return fullName
            end
        end
    end
    return tostring(fullType or "")
end

local CATEGORY_LABEL_FALLBACKS = {
    Weapons = "Weapons",
    Ammo = "Ammo",
    Bags = "Bags",
    Food = "Food",
    Medical = "Medical",
    Misc = "Misc"
}

function helpers.getCategoryLabel(category)
    local raw = tostring(category or "Misc")
    local normalized = CATEGORY_LABEL_FALLBACKS[category] and category or raw
    local fallback = CATEGORY_LABEL_FALLBACKS[normalized] or raw
    local key = string.format("UI_ZedToolbox_Category_%s", normalized)
    return CheatMenuText.get(key, fallback)
end

helpers.MAX_SKILL_LEVEL = 10

local DEFAULT_SKILL_ENTRIES = {
    "Strength",
    "Fitness",
    "Sprinting",
    "Lightfoot",
    "Nimble",
    "Sneak",
    "Maintenance",
    "Axe",
    "LongBlade",
    "SmallBlade",
    "LongBlunt",
    "SmallBlunt",
    "Spear",
    "Woodwork",
    "Cooking",
    "Farming",
    "Doctor",
    "Electricity",
    "MetalWelding",
    "Mechanics",
    "Tailoring",
    "Aiming",
    "Reloading",
    "Fishing",
    "Trapping",
    "PlantScavenging"
}

function helpers.getPlayerCharacter()
    if not getSpecificPlayer then
        return nil
    end
    return getSpecificPlayer(0)
end

function helpers.buildSkillDefinitions()
    local definitions = {}
    if not Perks then
        return definitions
    end
    for _, id in ipairs(DEFAULT_SKILL_ENTRIES) do
        local perkType = Perks[id]
        if perkType then
            local perk = nil
            if PerkFactory and PerkFactory.getPerkFromName then
                perk = PerkFactory.getPerkFromName(id)
            end
            local label = id
            if perk then
                if perk.getName and perk:getName() and perk:getName() ~= "" then
                    label = perk:getName()
                elseif perk.getLabel and perk:getLabel() and perk:getLabel() ~= "" then
                    label = perk:getLabel()
                end
            end
            table.insert(definitions, {
                id = id,
                type = perkType,
                perk = perk,
                label = label
            })
        end
    end
    table.sort(definitions, function(a, b)
        local aLabel = string.lower(tostring(a.label or a.id or ""))
        local bLabel = string.lower(tostring(b.label or b.id or ""))
        return aLabel < bLabel
    end)
    return definitions
end

function helpers.clampSkillLevel(level)
    local numeric = tonumber(level) or 0
    if numeric < 0 then
        numeric = 0
    end
    if numeric > helpers.MAX_SKILL_LEVEL then
        numeric = helpers.MAX_SKILL_LEVEL
    end
    return math.floor(numeric + 0.5)
end

local function getPerkXpForLevel(perk, level)
    local target = helpers.clampSkillLevel(level)
    if target <= 0 then
        return 0
    end
    if perk and perk.getTotalXpForLevel then
        local ok, value = pcall(perk.getTotalXpForLevel, perk, target)
        if ok and type(value) == "number" then
            return value
        end
    end
    return target * 1000
end

function helpers.getPlayerSkillLevel(player, definition)
    if not player or not definition or not definition.type then
        return 0
    end
    if player.getPerkLevel then
        local ok, value = pcall(player.getPerkLevel, player, definition.type)
        if ok and type(value) == "number" then
            return helpers.clampSkillLevel(value)
        end
    end
    local xpSystem = player.getXp and player:getXp()
    if xpSystem and xpSystem.getXP then
        local okXp, currentXp = pcall(xpSystem.getXP, xpSystem, definition.type)
        if okXp and type(currentXp) == "number" then
            local best = 0
            for level = 0, helpers.MAX_SKILL_LEVEL do
                if currentXp >= getPerkXpForLevel(definition.perk, level) then
                    best = level
                else
                    break
                end
            end
            return best
        end
    end
    return 0
end

function helpers.applySkillLevel(player, definition, level)
    if not player or not definition or not definition.type then
        return false
    end
    local xpSystem = player.getXp and player:getXp()
    if not xpSystem then
        return false
    end
    local targetLevel = helpers.clampSkillLevel(level)
    local targetXp = getPerkXpForLevel(definition.perk, targetLevel)
    local xpTargets = { targetXp }
    if targetLevel > 0 then
        local buffer = math.max(5, math.floor(targetXp * 0.02))
        table.insert(xpTargets, targetXp + buffer)
    end

    local function applyXpTarget(xpValue)
        local changed = false
        if type(xpSystem.setXPToLevel) == "function" then
            local ok = pcall(xpSystem.setXPToLevel, xpSystem, definition.type, targetLevel)
            changed = ok and true or changed
        end
        if type(xpSystem.setXP) == "function" then
            local ok = pcall(xpSystem.setXP, xpSystem, definition.type, xpValue)
            changed = ok and true or changed
        end
        if type(xpSystem.AddXP) == "function" and type(xpSystem.getXP) == "function" then
            local okCurrent, currentXp = pcall(xpSystem.getXP, xpSystem, definition.type)
            if okCurrent and type(currentXp) == "number" then
                local delta = xpValue - currentXp
                if math.abs(delta) > 0.01 then
                    local ok = pcall(xpSystem.AddXP, xpSystem, definition.type, delta)
                    changed = ok and true or changed
                end
            end
        end
        if type(xpSystem.addXP) == "function" and type(xpSystem.getXP) == "function" then
            local okCurrent, currentXp = pcall(xpSystem.getXP, xpSystem, definition.type)
            if okCurrent and type(currentXp) == "number" then
                local delta = xpValue - currentXp
                if math.abs(delta) > 0.01 then
                    local ok = pcall(xpSystem.addXP, xpSystem, definition.type, delta)
                    changed = ok and true or changed
                end
            end
        end
        return changed
    end

    local applied = false
    for _, xpValue in ipairs(xpTargets) do
        if applyXpTarget(xpValue) then
            applied = true
            break
        end
    end

    if type(xpSystem.setLevel) == "function" then
        pcall(xpSystem.setLevel, xpSystem, definition.type, targetLevel)
    end
    if type(xpSystem.setPerkBoost) == "function" then
        pcall(xpSystem.setPerkBoost, xpSystem, definition.type, 3)
    end

    local currentLevel = helpers.getPlayerSkillLevel(player, definition)
    if currentLevel ~= targetLevel then
        if targetLevel > currentLevel and type(player.LevelPerk) == "function" then
            for _ = currentLevel + 1, targetLevel do
                pcall(player.LevelPerk, player, definition.type)
            end
            currentLevel = helpers.getPlayerSkillLevel(player, definition)
        elseif targetLevel < currentLevel and type(player.LoseLevel) == "function" then
            for _ = currentLevel - 1, targetLevel, -1 do
                pcall(player.LoseLevel, player, definition.type)
            end
            currentLevel = helpers.getPlayerSkillLevel(player, definition)
        end
    end

    if type(xpSystem.refreshXp) == "function" then
        pcall(xpSystem.refreshXp, xpSystem)
    end
    if type(player.transmitXp) == "function" then
        pcall(player.transmitXp, player)
    end
    if type(player.transmitSkills) == "function" then
        pcall(player.transmitSkills, player)
    end
    if type(player.transmitStats) == "function" then
        pcall(player.transmitStats, player)
    end

    if currentLevel ~= targetLevel then
        return false
    end
    return true
end

return helpers
