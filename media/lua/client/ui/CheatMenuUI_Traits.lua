return function(CheatMenuUI, deps)
    local PADDING = deps.constants.PADDING
    local COLUMN_GAP = deps.constants.COLUMN_GAP
    local LIST_TOP = deps.constants.LIST_TOP
    local TAB_HEIGHT = deps.constants.TAB_HEIGHT
    local TAB_GAP = deps.constants.TAB_GAP
    local BOTTOM_HEIGHT = deps.constants.BOTTOM_HEIGHT
    local LEFT_WIDTH = deps.constants.LEFT_WIDTH
    local CENTER_WIDTH = deps.constants.CENTER_WIDTH
    local BUTTON_HEIGHT = deps.constants.BUTTON_HEIGHT
    local BUTTON_ROW_GAP = deps.constants.BUTTON_ROW_GAP
    local SECTION_GAP = deps.constants.SECTION_GAP
    local PRIMARY_BUTTON_HEIGHT = deps.constants.PRIMARY_BUTTON_HEIGHT

    local CheatMenuText = deps.CheatMenuText
    local lower = deps.lower
    local getPlayerCharacter = deps.getPlayerCharacter
    local getListSelection = deps.getListSelection

    local function normalizeId(id)
        if not id then
            return ""
        end
        return lower(tostring(id))
    end

    local function toList(raw)
        local result = {}
        if not raw then
            return result
        end
        if type(raw) == "table" then
            for _, value in pairs(raw) do
                table.insert(result, value)
            end
            return result
        end
        if raw.size and raw.get then
            local okSize, size = pcall(raw.size, raw)
            if okSize and type(size) == "number" then
                for index = 0, size - 1 do
                    local okValue, value = pcall(raw.get, raw, index)
                    if okValue and value then
                        table.insert(result, value)
                    end
                end
            end
        end
        return result
    end

    local function getTraitId(trait)
        if not trait then
            return nil
        end
        local value = nil
        if trait.getType then
            local ok, id = pcall(trait.getType, trait)
            if ok and id then
                value = id
            end
        end
        if not value and trait.getName then
            local ok, id = pcall(trait.getName, trait)
            if ok and id then
                value = id
            end
        end
        if not value and trait.type then
            value = trait.type
        end
        if not value and trait.name then
            value = trait.name
        end
        if not value then
            return nil
        end
        return tostring(value)
    end

    local function getTraitLabel(trait, id)
        local label = nil
        if trait then
            if trait.getLabel then
                local ok, value = pcall(trait.getLabel, trait)
                if ok and value and value ~= "" then
                    label = value
                end
            end
            if not label and trait.getName then
                local ok, value = pcall(trait.getName, trait)
                if ok and value and value ~= "" then
                    label = value
                end
            end
        end
        return label or id or "Trait"
    end

    local function getTraitCost(trait)
        if not trait then
            return 0
        end
        local cost = 0
        local ok, value = pcall(function()
            if trait.getCost then
                return trait:getCost()
            end
            return nil
        end)
        if ok and type(value) == "number" then
            cost = value
        end
        if cost == 0 then
            local okAlt, alt = pcall(function()
                if trait.getPointCost then
                    return trait:getPointCost()
                end
                if trait.getPoints then
                    return trait:getPoints()
                end
                return nil
            end)
            if okAlt and type(alt) == "number" then
                cost = alt
            end
        end
        if cost == 0 and trait.cost and type(trait.cost) == "number" then
            cost = trait.cost
        end
        return cost
    end

    local function collectMutualExclusions(trait)
        if not trait then
            return {}
        end
        local raw = nil
        local okPrimary, primary = pcall(function()
            if trait.getMutualExclusiveTraits then
                return trait:getMutualExclusiveTraits()
            end
            return nil
        end)
        if okPrimary and primary then
            raw = primary
        end
        if not raw then
            local okSecondary, secondary = pcall(function()
                if trait.getMutualExclusions then
                    return trait:getMutualExclusions()
                end
                if trait.getMutualExclusive then
                    return trait:getMutualExclusive()
                end
                return nil
            end)
            if okSecondary and secondary then
                raw = secondary
            end
        end
        if not raw and trait.mutualExclusions then
            raw = trait.mutualExclusions
        end
        local exclusions = {}
        for _, entry in ipairs(toList(raw)) do
            local id = nil
            if type(entry) == "string" then
                id = entry
            else
                id = getTraitId(entry)
            end
            if id and id ~= "" then
                table.insert(exclusions, id)
            end
        end
        return exclusions
    end

    local function buildTraitDefinitions()
        local definitions = {}
        if not TraitFactory then
            return definitions
        end
        local raw = nil
        local okPrimary, primary = pcall(function()
            if TraitFactory.getTraits then
                return TraitFactory.getTraits()
            end
            return nil
        end)
        if okPrimary and primary then
            raw = primary
        end
        if not raw then
            local okSecondary, secondary = pcall(function()
                if TraitFactory.getTraitList then
                    return TraitFactory.getTraitList()
                end
                return nil
            end)
            if okSecondary and secondary then
                raw = secondary
            end
        end
        if not raw then
            local okFallback, fallback = pcall(function()
                if TraitFactory.getAvailableTraits then
                    return TraitFactory.getAvailableTraits()
                end
                return nil
            end)
            if okFallback and fallback then
                raw = fallback
            end
        end
        for _, trait in ipairs(toList(raw)) do
            local id = getTraitId(trait)
            if id and id ~= "" then
                local label = getTraitLabel(trait, id)
                local cost = getTraitCost(trait)
                local incompatible = collectMutualExclusions(trait)
                table.insert(definitions, {
                    id = id,
                    idLower = normalizeId(id),
                    label = label,
                    cost = cost,
                    trait = trait,
                    incompatible = incompatible
                })
            end
        end
        table.sort(definitions, function(a, b)
            local aLabel = lower(tostring(a.label or a.id or ""))
            local bLabel = lower(tostring(b.label or b.id or ""))
            return aLabel < bLabel
        end)
        return definitions
    end

    function CheatMenuUI:refreshTraitDefinitions()
        local definitions = buildTraitDefinitions()
        self.traitDefinitions = definitions
        self.traitLabelLookup = {}
        for _, def in ipairs(definitions) do
            self.traitLabelLookup[def.idLower] = def.label or def.id
        end
    end

    function CheatMenuUI:getTraitDefinitions()
        if not self.traitDefinitions then
            self:refreshTraitDefinitions()
        end
        return self.traitDefinitions or {}
    end

    local function getPlayerTraitSet(player)
        local set = {}
        if not player or not player.getTraits then
            return set
        end
        local traits = player:getTraits()
        for _, id in ipairs(toList(traits)) do
            local normalized = normalizeId(id)
            if normalized ~= "" then
                set[normalized] = true
            end
        end
        return set
    end

    local function hasTrait(player, traitId)
        if not player or not traitId then
            return false
        end
        if player.HasTrait then
            local ok, result = pcall(player.HasTrait, player, traitId)
            if ok and result ~= nil then
                return result and true or false
            end
        end
        local set = getPlayerTraitSet(player)
        return set[normalizeId(traitId)] and true or false
    end

    local function transmitTraits(player)
        if player and player.transmitTraits then
            pcall(player.transmitTraits, player)
        end
    end

    local function addTraitToPlayer(player, traitId)
        if not player or not traitId then
            return false
        end
        if hasTrait(player, traitId) then
            return true
        end
        local traits = player.getTraits and player:getTraits()
        if traits and traits.add then
            local ok = pcall(traits.add, traits, traitId)
            transmitTraits(player)
            return ok and true or false
        end
        return false
    end

    local function removeTraitFromPlayer(player, traitId)
        if not player or not traitId then
            return false
        end
        if not hasTrait(player, traitId) then
            return true
        end
        local traits = player.getTraits and player:getTraits()
        if traits and traits.remove then
            local ok = pcall(traits.remove, traits, traitId)
            transmitTraits(player)
            return ok and true or false
        end
        return false
    end

    local function resetAllTraits(player)
        if not player then
            return false
        end
        local traits = player.getTraits and player:getTraits()
        if traits and traits.clear then
            local ok = pcall(traits.clear, traits)
            transmitTraits(player)
            return ok and true or false
        end
        local set = getPlayerTraitSet(player)
        local anyRemoved = false
        for traitId in pairs(set) do
            if removeTraitFromPlayer(player, traitId) then
                anyRemoved = true
            end
        end
        return anyRemoved
    end

    local function formatCost(cost)
        local value = tonumber(cost) or 0
        if value > 0 then
            return string.format("+%s", value)
        end
        return tostring(value)
    end

    local function evaluateTraitState(definition, activeSet, labelLookup)
        local conflicts = false
        local conflictLabels = {}
        local active = activeSet[definition.idLower] and true or false
        for _, other in ipairs(definition.incompatible or {}) do
            local normalized = normalizeId(other)
            if activeSet[normalized] then
                conflicts = true
                table.insert(conflictLabels, labelLookup[normalized] or other)
            end
        end
        return {
            active = active,
            conflicts = conflicts,
            conflictLabels = conflictLabels
        }
    end

    function CheatMenuUI:getSelectedTraitEntry()
        local entry = getListSelection(self.traitsList)
        return entry and entry.item or nil
    end

    function CheatMenuUI:updateTraitDetail(entry)
        local definition = entry and entry.definition
        local name = definition and (definition.label or definition.id) or CheatMenuText.get("UI_ZedToolbox_Traits_Select", "Select a trait first.")
        local costText = definition and CheatMenuText.get("UI_ZedToolbox_Traits_Cost", "Cost: %1", definition.cost or 0) or ""
        local stateText = entry and entry.active and CheatMenuText.get("UI_ZedToolbox_Traits_StateActive", "Status: Active") or CheatMenuText.get("UI_ZedToolbox_Traits_StateInactive", "Status: Inactive")
        local conflictText = nil
        if entry and entry.conflicts and entry.conflictLabels and #entry.conflictLabels > 0 then
            conflictText = CheatMenuText.get("UI_ZedToolbox_Traits_Incompatible", "Incompatible with: %1", table.concat(entry.conflictLabels, ", "))
        else
            conflictText = CheatMenuText.get("UI_ZedToolbox_Traits_NoConflicts", "No conflicts detected.")
        end
        self.traitDetail = {
            lines = { name, costText, stateText, conflictText },
            colors = {
                { r = 0.9, g = 0.9, b = 0.9 },
                { r = 0.78, g = 0.78, b = 0.78 },
                entry and entry.active and { r = 0.55, g = 0.85, b = 0.55 } or { r = 0.75, g = 0.75, b = 0.75 },
                entry and entry.conflicts and { r = 0.95, g = 0.78, b = 0.45 } or { r = 0.7, g = 0.75, b = 0.7 }
            }
        }
    end

    function CheatMenuUI:refreshTraitsUI()
        if not self.traitsList then
            return
        end
        self:refreshTraitDefinitions()
        local definitions = self:getTraitDefinitions()
        local player = getPlayerCharacter()
        local activeSet = getPlayerTraitSet(player)
        local previous = self:getSelectedTraitEntry()
        local previousId = previous and previous.definition and previous.definition.id
        self.traitsList:clear()
        if not definitions or #definitions == 0 then
            self.traitsList:addItem(CheatMenuText.get("UI_ZedToolbox_Traits_None", "No traits available"), {})
            self.traitsList.selected = 1
            self:updateTraitDetail(nil)
            return
        end
        local fallbackIndex = 1
        local index = 1
        for _, definition in ipairs(definitions) do
            local state = evaluateTraitState(definition, activeSet, self.traitLabelLookup or {})
            local itemData = {
                definition = definition,
                active = state.active,
                conflicts = state.conflicts,
                conflictLabels = state.conflictLabels,
                cost = definition.cost,
                costText = formatCost(definition.cost)
            }
            self.traitsList:addItem(definition.label or definition.id or "Trait", itemData)
            if previousId and definition.id == previousId then
                fallbackIndex = index
            end
            index = index + 1
        end
        local itemCount = self.traitsList.items and #self.traitsList.items or 0
        if itemCount > 0 then
            if fallbackIndex > itemCount then
                fallbackIndex = itemCount
            end
            self.traitsList.selected = fallbackIndex
        else
            self.traitsList.selected = 0
        end
        self:updateTraitDetail(self:getSelectedTraitEntry())
    end

    function CheatMenuUI:syncTraitsUI()
        self:refreshTraitsUI()
    end

    function CheatMenuUI:onTraitSelected()
        self:updateTraitDetail(self:getSelectedTraitEntry())
    end

    function CheatMenuUI:onTraitAdd()
        local entry = self:getSelectedTraitEntry()
        if not entry or not entry.definition then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Traits_Select", "Select a trait first."))
            return
        end
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        local success = addTraitToPlayer(player, entry.definition.id)
        self:syncTraitsUI()
        local message = success and CheatMenuText.get("UI_ZedToolbox_Traits_StatusAdded", "%1 added.", entry.definition.label or entry.definition.id) or CheatMenuText.get("UI_ZedToolbox_Traits_StatusFailed", "Could not update traits.")
        self:setStatus(success, message)
    end

    function CheatMenuUI:onTraitRemove()
        local entry = self:getSelectedTraitEntry()
        if not entry or not entry.definition then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Traits_Select", "Select a trait first."))
            return
        end
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        local success = removeTraitFromPlayer(player, entry.definition.id)
        self:syncTraitsUI()
        local message = success and CheatMenuText.get("UI_ZedToolbox_Traits_StatusRemoved", "%1 removed.", entry.definition.label or entry.definition.id) or CheatMenuText.get("UI_ZedToolbox_Traits_StatusFailed", "Could not update traits.")
        self:setStatus(success, message)
    end

    function CheatMenuUI:onTraitsReset()
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        local success = resetAllTraits(player)
        self:syncTraitsUI()
        local message = success and CheatMenuText.get("UI_ZedToolbox_Traits_StatusReset", "All traits cleared.") or CheatMenuText.get("UI_ZedToolbox_Traits_StatusFailed", "Could not update traits.")
        self:setStatus(success, message)
    end

    local function addTraitsByCost(self, costSign)
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        self:refreshTraitDefinitions()
        local definitions = self:getTraitDefinitions()
        local activeSet = getPlayerTraitSet(player)
        local targetSign = costSign == "positive" and 1 or -1
        local applied = 0
        for _, definition in ipairs(definitions) do
            local cost = tonumber(definition.cost) or 0
            if (targetSign > 0 and cost > 0) or (targetSign < 0 and cost < 0) then
                local normalized = normalizeId(definition.id)
                if not activeSet[normalized] then
                    if addTraitToPlayer(player, definition.id) then
                        activeSet[normalized] = true
                        applied = applied + 1
                    end
                end
            end
        end
        self:syncTraitsUI()
        local success = applied > 0
        local key = targetSign > 0 and "UI_ZedToolbox_Traits_StatusAddedAllPositive" or "UI_ZedToolbox_Traits_StatusAddedAllNegative"
        local fallback = targetSign > 0 and "%1 positive traits applied." or "%1 negative traits applied."
        self:setStatus(success, CheatMenuText.get(key, fallback, applied))
    end

    function CheatMenuUI:onTraitAddAllPositive()
        addTraitsByCost(self, "positive")
    end

    function CheatMenuUI:onTraitAddAllNegative()
        addTraitsByCost(self, "negative")
    end

    function CheatMenuUI:buildTraitsUI()
        local listTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
        local listHeight = self.height - listTop - BOTTOM_HEIGHT
        local listWidth = LEFT_WIDTH + COLUMN_GAP + CENTER_WIDTH

        self.traitsList = ISScrollingListBox:new(PADDING, listTop, listWidth, listHeight)
        self.traitsList:initialise()
        self.traitsList:instantiate()
        self.traitsList.itemheight = 26
        self.traitsList.font = UIFont.Small
        self.traitsList.doDrawItem = function(list, y, item)
            local data = item.item or {}
            local isSelected = list.selected == item.index
            if isSelected then
                list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
            end
            local r, g, b = 0.9, 0.9, 0.9
            if data.active then
                r, g, b = 0.55, 0.85, 0.55
            elseif data.conflicts then
                r, g, b = 0.95, 0.78, 0.45
            end
            list:drawText(item.text or "Trait", 10, y + 5, r, g, b, 1, UIFont.Small)
            if data.costText then
                list:drawTextRight(data.costText, list.width - 12, y + 5, r, g, b, 1, UIFont.Small)
            end
            return y + item.height
        end
        self.traitsList.onMouseDown = function(list, x, y)
            ISScrollingListBox.onMouseDown(list, x, y)
            self:onTraitSelected()
        end
        self:addChild(self.traitsList)
        self:addToTab("traits", self.traitsList)
        self.traitsListLabelPos = { x = PADDING, y = listTop - 20 }

        local detailX = PADDING + listWidth + COLUMN_GAP
        local detailWidth = self.width - detailX - PADDING
        self.traitDetailLabelPos = { x = detailX, y = listTop - 20 }
        self.traitDetailTextPos = { x = detailX, y = listTop + 6 }

        local buttonWidth = math.max(200, detailWidth)
        local addY = listTop + 110
        self.addTraitBtn = ISButton:new(detailX, addY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Traits_Add", "Add Trait"), self, CheatMenuUI.onTraitAdd)
        self.addTraitBtn:initialise()
        self.addTraitBtn:instantiate()
        self:addChild(self.addTraitBtn)
        self:addToTab("traits", self.addTraitBtn)

        local removeY = addY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.removeTraitBtn = ISButton:new(detailX, removeY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Traits_Remove", "Remove Trait"), self, CheatMenuUI.onTraitRemove)
        self.removeTraitBtn:initialise()
        self.removeTraitBtn:instantiate()
        self:addChild(self.removeTraitBtn)
        self:addToTab("traits", self.removeTraitBtn)

        local resetY = removeY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.resetTraitsBtn = ISButton:new(detailX, resetY, buttonWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Traits_Reset", "Reset Traits"), self, CheatMenuUI.onTraitsReset)
        self.resetTraitsBtn:initialise()
        self.resetTraitsBtn:instantiate()
        self:addChild(self.resetTraitsBtn)
        self:addToTab("traits", self.resetTraitsBtn)

        local addAllPosY = resetY + PRIMARY_BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.addAllPositiveTraitsBtn = ISButton:new(detailX, addAllPosY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Traits_AddAllPositive", "Apply All Positive"), self, CheatMenuUI.onTraitAddAllPositive)
        self.addAllPositiveTraitsBtn:initialise()
        self.addAllPositiveTraitsBtn:instantiate()
        self:addChild(self.addAllPositiveTraitsBtn)
        self:addToTab("traits", self.addAllPositiveTraitsBtn)

        local addAllNegY = addAllPosY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.addAllNegativeTraitsBtn = ISButton:new(detailX, addAllNegY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Traits_AddAllNegative", "Apply All Negative"), self, CheatMenuUI.onTraitAddAllNegative)
        self.addAllNegativeTraitsBtn:initialise()
        self.addAllNegativeTraitsBtn:instantiate()
        self:addChild(self.addAllNegativeTraitsBtn)
        self:addToTab("traits", self.addAllNegativeTraitsBtn)

        local sectionTop = listTop - 30
        local sectionBottom = addAllNegY + BUTTON_HEIGHT + SECTION_GAP
        self.traitsSection = {
            x = PADDING,
            y = sectionTop,
            w = self.width - (2 * PADDING),
            h = sectionBottom - sectionTop
        }

        self:refreshTraitsUI()
    end
end
