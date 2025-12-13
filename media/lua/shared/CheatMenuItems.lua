local CheatMenuItems = {}

local CATEGORY_ORDER = { "Weapons", "Ammo", "Bags", "Food", "Medical", "Misc" }

local CATEGORY_RULES = {
    Weapons = {
        displays = { weapon = true, weaponpart = true, rangedweapon = true, melee = true }
    },
    Ammo = {
        displays = { ammo = true, ammoclip = true }
    },
    Bags = {
        displays = { container = true, bag = true }
    },
    Food = {
        displays = { food = true, foodbrewed = true }
    },
    Medical = {
        displays = { medical = true, medicine = true, bandage = true }
    }
}

local catalogCache

local function toKey(text)
    if not text then
        return nil
    end
    return string.lower(text)
end

local function matchesRule(scriptItem, rule)
    local displayCat = toKey(scriptItem:getDisplayCategory())
    if displayCat and rule.displays and rule.displays[displayCat] then
        return true
    end
    return false
end

local function categorize(scriptItem)
    for category, rule in pairs(CATEGORY_RULES) do
        if matchesRule(scriptItem, rule) then
            return category
        end
    end
    return "Misc"
end

local function addEntry(catalog, category, entry)
    catalog[category] = catalog[category] or {}
    table.insert(catalog[category], entry)
end

local function buildCatalog()
    local scriptManager = ScriptManager.instance
    if not scriptManager then
        return {}
    end
    local allItems = scriptManager:getAllItems()
    if not allItems then
        return {}
    end
    local catalog = {}
    for i = 0, allItems:size() - 1 do
        local scriptItem = allItems:get(i)
        if scriptItem and scriptItem:getFullName() then
            local entry = {
                fullType = scriptItem:getFullName(),
                name = scriptItem:getDisplayName() or scriptItem:getName() or scriptItem:getFullName()
            }
            addEntry(catalog, categorize(scriptItem), entry)
        end
    end
    for _, list in pairs(catalog) do
        table.sort(list, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)
    end
    return catalog
end

function CheatMenuItems.getCatalog()
    if not catalogCache then
        catalogCache = buildCatalog()
    end
    return catalogCache
end

function CheatMenuItems.refresh()
    catalogCache = nil
    return CheatMenuItems.getCatalog()
end

function CheatMenuItems.getCategoryOrder()
    return CATEGORY_ORDER
end

function CheatMenuItems.isValid(baseId)
    if not baseId or baseId == "" then
        return false
    end
    local manager = ScriptManager.instance
    return manager and manager:FindItem(baseId) ~= nil
end

return CheatMenuItems
