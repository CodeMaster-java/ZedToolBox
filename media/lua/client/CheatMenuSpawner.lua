local CheatMenuItems = require "CheatMenuItems"
local CheatMenuText = require "CheatMenuText"

local CheatMenuSpawner = {}

local MAX_QUANTITY = 100

local function clampQuantity(value)
    local quantity = tonumber(value) or 1
    quantity = math.floor(quantity)
    if quantity < 1 then
        quantity = 1
    elseif quantity > MAX_QUANTITY then
        quantity = MAX_QUANTITY
    end
    return quantity
end

local function getPlayerObject()
    return getSpecificPlayer(0) or getPlayer()
end

local function spawnOnGround(baseId, quantity, player)
    local square = player and player:getCurrentSquare()
    if not square then
        return false, CheatMenuText.get("UI_ZedToolbox_ErrorGround", "No ground tile available")
    end
    for _ = 1, quantity do
        square:AddWorldInventoryItem(baseId, 0, 0, 0)
    end
    return true, CheatMenuText.get("UI_ZedToolbox_StatusGround", "Spawned %d x %s on ground", quantity, baseId)
end

local function spawnInInventory(baseId, quantity, player)
    local inventory = player and player:getInventory()
    if not inventory then
        return false, CheatMenuText.get("UI_ZedToolbox_ErrorInventory", "Inventory unavailable")
    end
    for _ = 1, quantity do
        inventory:AddItem(baseId)
    end
    return true, CheatMenuText.get("UI_ZedToolbox_StatusInventory", "Added %d x %s to inventory", quantity, baseId)
end

function CheatMenuSpawner.spawn(baseId, quantity, target)
    if not CheatMenuItems.isValid(baseId) then
        return false, CheatMenuText.get("UI_ZedToolbox_ErrorBaseId", "Invalid BaseID")
    end
    local player = getPlayerObject()
    if not player then
        return false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready")
    end
    local qty = clampQuantity(quantity)
    if target == "ground" then
        return spawnOnGround(baseId, qty, player)
    end
    return spawnInInventory(baseId, qty, player)
end

CheatMenuSpawner.MAX_QUANTITY = MAX_QUANTITY

return CheatMenuSpawner
