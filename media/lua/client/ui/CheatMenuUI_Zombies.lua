return function(CheatMenuUI, deps)
    local PADDING = deps.constants.PADDING
    local COLUMN_GAP = deps.constants.COLUMN_GAP
    local LIST_TOP = deps.constants.LIST_TOP
    local TAB_HEIGHT = deps.constants.TAB_HEIGHT
    local TAB_GAP = deps.constants.TAB_GAP
    local BUTTON_HEIGHT = deps.constants.BUTTON_HEIGHT
    local BUTTON_ROW_GAP = deps.constants.BUTTON_ROW_GAP
    local SECTION_GAP = deps.constants.SECTION_GAP
    local PRIMARY_BUTTON_HEIGHT = deps.constants.PRIMARY_BUTTON_HEIGHT

    local CheatMenuText = deps.CheatMenuText
    local CheatMenuUtils = deps.CheatMenuUtils
    local clamp = deps.clamp
    local getPlayerCharacter = deps.getPlayerCharacter

    local RADIUS_MIN = 1
    local RADIUS_MAX = 50
    local SPAWN_MIN = 1
    local SPAWN_MAX = 50

    local function isSingleplayer()
        if isClient and isClient() then
            return false
        end
        return true
    end

    local function ensureSingleplayer(self)
        if isSingleplayer() then
            return true
        end
        self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusSingleplayer", "Singleplayer only."))
        return false
    end

    local function getCellZombies()
        local cell = getCell and getCell() or nil
        if cell and cell.getZombieList then
            return cell:getZombieList()
        end
        return nil
    end

    local function safeCall(target, method, ...)
        if not target or type(target[method]) ~= "function" then
            return false
        end
        local ok = pcall(target[method], target, ...)
        return ok and true or false
    end

    local function forEachZombie(filter, action)
        local zombies = getCellZombies()
        if not zombies then
            return 0
        end
        local applied = 0
        for i = zombies:size() - 1, 0, -1 do
            local zombie = zombies:get(i)
            if zombie and (not zombie.isDead or not zombie:isDead()) then
                if not filter or filter(zombie) then
                    local ok, result = pcall(action, zombie)
                    if ok and result then
                        applied = applied + 1
                    end
                end
            end
        end
        return applied
    end

    local function isOnScreen(zombie)
        local ok, result = pcall(function()
            if zombie.isOnScreen then
                return zombie:isOnScreen()
            end
            return false
        end)
        return ok and result or false
    end

    local function killOnScreen()
        local player = getPlayerCharacter()
        if not player then
            return 0
        end
        return forEachZombie(isOnScreen, function(zombie)
            if zombie and not zombie:isDead() then
                if zombie.Kill then
                    zombie:Kill(player)
                    return true
                end
                if zombie.setHealth then
                    zombie:setHealth(0)
                    return true
                end
            end
            return false
        end)
    end

    local function setFrozen(zombie, frozen)
        local changed = false
        changed = safeCall(zombie, "setUseless", frozen) or changed
        changed = safeCall(zombie, "setCanWalk", not frozen) or changed
        changed = safeCall(zombie, "setCanRun", not frozen) or changed
        changed = safeCall(zombie, "setCanCrawl", not frozen) or changed
        changed = safeCall(zombie, "setSpeedMod", frozen and 0 or 1) or changed
        if frozen then
            changed = safeCall(zombie, "stopAllActionQueue") or changed
            changed = safeCall(zombie, "setTarget", nil) or changed
        end
        return changed
    end

    local function setIgnorePlayer(zombie, ignore)
        local changed = false
        changed = safeCall(zombie, "setTarget", ignore and nil or getPlayerCharacter()) or changed
        changed = safeCall(zombie, "setCanAttack", not ignore) or changed
        changed = safeCall(zombie, "setUseless", ignore and true or false) or changed
        return changed
    end

    local function spawnZombiesNear(count, zombieType)
        local player = getPlayerCharacter()
        if not player then
            return 0
        end
        local x = player:getX() + 1
        local y = player:getY() + 1
        local z = player:getZ()
        local spawned = 0
        local ok, result = pcall(function()
            if addZombiesInOutfit then
                return addZombiesInOutfit(x, y, z, count, zombieType or "", nil)
            end
            if addZombies then
                return addZombies(x, y, z, count)
            end
            return 0
        end)
        if ok and result then
            spawned = tonumber(result) or spawned
        end
        if spawned <= 0 and ok then
            spawned = count
        end
        return spawned
    end

    function CheatMenuUI:getZombiesRadius()
        if not self.zombiesRadiusEntry then
            return 15
        end
        local raw = tonumber(self.zombiesRadiusEntry:getText()) or 15
        return clamp(raw, RADIUS_MIN, RADIUS_MAX)
    end

    function CheatMenuUI:getZombiesSpawnCount()
        if not self.zombiesSpawnCountEntry then
            return SPAWN_MIN
        end
        local raw = tonumber(self.zombiesSpawnCountEntry:getText()) or SPAWN_MIN
        return clamp(raw, SPAWN_MIN, SPAWN_MAX)
    end

    function CheatMenuUI:getZombiesSpawnType()
        if not self.zombiesSpawnTypeEntry then
            return ""
        end
        return self.zombiesSpawnTypeEntry:getText() or ""
    end

    function CheatMenuUI:syncZombiesUI()
        local utilsState = CheatMenuUtils.getState() or {}
        if self.zombiesRadiusEntry then
            self.zombiesRadiusEntry:setText(tostring(utilsState.clearRadius or 15))
        end
    end

    function CheatMenuUI:onZombiesKillNearby()
        if not ensureSingleplayer(self) then
            return
        end
        local radius = self:getZombiesRadius()
        CheatMenuUtils.setClearRadius(radius)
        local cleared = CheatMenuUtils.clearZombies(radius)
        if cleared > 0 then
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusKilled", "%1 zombies removed.", cleared))
        else
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusNone", "No zombies found."))
        end
    end

    function CheatMenuUI:onZombiesKillScreen()
        if not ensureSingleplayer(self) then
            return
        end
        local cleared = killOnScreen()
        if cleared > 0 then
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusKilled", "%1 zombies removed.", cleared))
        else
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusNone", "No zombies found."))
        end
    end

    function CheatMenuUI:onZombiesFreeze()
        if not ensureSingleplayer(self) then
            return
        end
        local applied = forEachZombie(nil, function(z)
            return setFrozen(z, true)
        end)
        self:setStatus(applied > 0, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusFrozen", "%1 zombies frozen.", applied))
    end

    function CheatMenuUI:onZombiesUnfreeze()
        if not ensureSingleplayer(self) then
            return
        end
        local applied = forEachZombie(nil, function(z)
            return setFrozen(z, false)
        end)
        self:setStatus(applied > 0, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusUnfrozen", "%1 zombies unfrozen.", applied))
    end

    function CheatMenuUI:onZombiesIgnore()
        if not ensureSingleplayer(self) then
            return
        end
        local applied = forEachZombie(nil, function(z)
            return setIgnorePlayer(z, true)
        end)
        self:setStatus(applied > 0, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusIgnored", "%1 zombies set to ignore you.", applied))
    end

    function CheatMenuUI:onZombiesRestore()
        if not ensureSingleplayer(self) then
            return
        end
        local applied = forEachZombie(nil, function(z)
            local unfrozen = setFrozen(z, false)
            local restored = setIgnorePlayer(z, false)
            return unfrozen or restored
        end)
        self:setStatus(applied > 0, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusRestored", "%1 zombies restored.", applied))
    end

    function CheatMenuUI:onZombiesSpawn()
        if not ensureSingleplayer(self) then
            return
        end
        local count = self:getZombiesSpawnCount()
        local zombieType = self:getZombiesSpawnType()
        local spawned = spawnZombiesNear(count, zombieType)
        if spawned > 0 then
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusSpawned", "%1 zombies spawned.", spawned))
        else
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Zombies_StatusSpawnFailed", "Spawn failed."))
        end
    end

    function CheatMenuUI:buildZombiesUI()
        local contentTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
        local sectionTop = contentTop - 30
        local buttonWidth = 220

        self.zombiesRadiusLabelPos = { x = PADDING, y = contentTop - 18 }
        self.zombiesRadiusEntry = ISTextEntryBox:new(tostring((CheatMenuUtils.getState() and CheatMenuUtils.getState().clearRadius) or 15), PADDING, contentTop, 80, 22)
        self.zombiesRadiusEntry:initialise()
        self.zombiesRadiusEntry:instantiate()
        self.zombiesRadiusEntry:setOnlyNumbers(true)
        self:addChild(self.zombiesRadiusEntry)
        self:addToTab("zombies", self.zombiesRadiusEntry)

        local killNearbyY = contentTop + 30
        self.zombiesKillNearbyBtn = ISButton:new(PADDING, killNearbyY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_KillNearby", "Kill Nearby"), self, CheatMenuUI.onZombiesKillNearby)
        self.zombiesKillNearbyBtn:initialise()
        self.zombiesKillNearbyBtn:instantiate()
        self:addChild(self.zombiesKillNearbyBtn)
        self:addToTab("zombies", self.zombiesKillNearbyBtn)

        local killScreenY = killNearbyY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.zombiesKillScreenBtn = ISButton:new(PADDING, killScreenY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_KillScreen", "Kill On Screen"), self, CheatMenuUI.onZombiesKillScreen)
        self.zombiesKillScreenBtn:initialise()
        self.zombiesKillScreenBtn:instantiate()
        self:addChild(self.zombiesKillScreenBtn)
        self:addToTab("zombies", self.zombiesKillScreenBtn)

        local rightX = PADDING + buttonWidth + COLUMN_GAP + 40
        self.zombiesFreezeBtn = ISButton:new(rightX, killNearbyY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_Freeze", "Freeze Zombies"), self, CheatMenuUI.onZombiesFreeze)
        self.zombiesFreezeBtn:initialise()
        self.zombiesFreezeBtn:instantiate()
        self:addChild(self.zombiesFreezeBtn)
        self:addToTab("zombies", self.zombiesFreezeBtn)

        local unfreezeY = killNearbyY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.zombiesUnfreezeBtn = ISButton:new(rightX, unfreezeY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_Unfreeze", "Unfreeze Zombies"), self, CheatMenuUI.onZombiesUnfreeze)
        self.zombiesUnfreezeBtn:initialise()
        self.zombiesUnfreezeBtn:instantiate()
        self:addChild(self.zombiesUnfreezeBtn)
        self:addToTab("zombies", self.zombiesUnfreezeBtn)

        local ignoreY = killScreenY
        self.zombiesIgnoreBtn = ISButton:new(rightX, ignoreY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_Ignore", "Zombies Ignore Player"), self, CheatMenuUI.onZombiesIgnore)
        self.zombiesIgnoreBtn:initialise()
        self.zombiesIgnoreBtn:instantiate()
        self:addChild(self.zombiesIgnoreBtn)
        self:addToTab("zombies", self.zombiesIgnoreBtn)

        local restoreY = ignoreY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.zombiesRestoreBtn = ISButton:new(rightX, restoreY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_Restore", "Restore Behavior"), self, CheatMenuUI.onZombiesRestore)
        self.zombiesRestoreBtn:initialise()
        self.zombiesRestoreBtn:instantiate()
        self:addChild(self.zombiesRestoreBtn)
        self:addToTab("zombies", self.zombiesRestoreBtn)

        local spawnY = math.max(restoreY + BUTTON_HEIGHT + BUTTON_ROW_GAP, killScreenY + BUTTON_HEIGHT + BUTTON_ROW_GAP)
        local spawnCountY = spawnY
        self.zombiesSpawnCountLabelPos = { x = PADDING, y = spawnCountY - 18 }
        self.zombiesSpawnCountEntry = ISTextEntryBox:new("5", PADDING, spawnCountY, 80, 22)
        self.zombiesSpawnCountEntry:initialise()
        self.zombiesSpawnCountEntry:instantiate()
        self.zombiesSpawnCountEntry:setOnlyNumbers(true)
        self:addChild(self.zombiesSpawnCountEntry)
        self:addToTab("zombies", self.zombiesSpawnCountEntry)

        local spawnTypeX = PADDING + 90 + COLUMN_GAP
        self.zombiesSpawnTypeLabelPos = { x = spawnTypeX, y = spawnCountY - 18 }
        self.zombiesSpawnTypeEntry = ISTextEntryBox:new("", spawnTypeX, spawnCountY, 160, 22)
        self.zombiesSpawnTypeEntry:initialise()
        self.zombiesSpawnTypeEntry:instantiate()
        self:addChild(self.zombiesSpawnTypeEntry)
        self:addToTab("zombies", self.zombiesSpawnTypeEntry)

        local spawnBtnY = spawnCountY + 28
        self.zombiesSpawnBtn = ISButton:new(PADDING, spawnBtnY, buttonWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Zombies_Spawn", "Spawn Zombies"), self, CheatMenuUI.onZombiesSpawn)
        self.zombiesSpawnBtn:initialise()
        self.zombiesSpawnBtn:instantiate()
        self:addChild(self.zombiesSpawnBtn)
        self:addToTab("zombies", self.zombiesSpawnBtn)

        local sectionBottom = self.zombiesSpawnBtn.y + self.zombiesSpawnBtn.height + SECTION_GAP
        self.zombiesSection = {
            x = PADDING,
            y = sectionTop,
            w = self.width - (2 * PADDING),
            h = sectionBottom - sectionTop
        }

        self:syncZombiesUI()
    end
end
