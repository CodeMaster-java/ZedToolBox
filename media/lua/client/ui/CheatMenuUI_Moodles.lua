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
    local getPlayerCharacter = deps.getPlayerCharacter
    local getListSelection = deps.getListSelection

    local function getStats(player)
        if not player or not player.getStats then
            return nil
        end
        return player:getStats()
    end

    local function getBody(player)
        if not player or not player.getBodyDamage then
            return nil
        end
        return player:getBodyDamage()
    end

    local function safeCall(target, method, ...)
        if not target or type(target[method]) ~= "function" then
            return nil
        end
        local ok, result = pcall(target[method], target, ...)
        if ok then
            return result
        end
        return nil
    end

    local function buildMoodleDefinitions()
        local defs = {}
        local statsGetter = function(fnName)
            return function(player)
                return safeCall(getStats(player), fnName)
            end
        end
        local statsSetter = function(fnName)
            return function(player, value)
                local stats = getStats(player)
                if not stats then
                    return false
                end
                if type(stats[fnName]) ~= "function" then
                    return false
                end
                local ok = pcall(stats[fnName], stats, value)
                return ok and true or false
            end
        end
        local bodyGetter = function(fnName)
            return function(player)
                return safeCall(getBody(player), fnName)
            end
        end
        local bodySetter = function(fnName)
            return function(player, value)
                local body = getBody(player)
                if not body or type(body[fnName]) ~= "function" then
                    return false
                end
                local ok = pcall(body[fnName], body, value)
                return ok and true or false
            end
        end

        local function add(def)
            defs[#defs + 1] = def
        end

        add({ id = "stress", labelKey = "UI_ZedToolbox_Moodles_Stress", fallback = "Stress", min = 0, max = 1, get = statsGetter("getStress"), set = statsSetter("setStress") })
        add({ id = "panic", labelKey = "UI_ZedToolbox_Moodles_Panic", fallback = "Panic", min = 0, max = 100, get = statsGetter("getPanic"), set = statsSetter("setPanic") })
        add({ id = "pain", labelKey = "UI_ZedToolbox_Moodles_Pain", fallback = "Pain", min = 0, max = 100, get = bodyGetter("getPain"), set = bodySetter("setPain") })
        add({ id = "sickness", labelKey = "UI_ZedToolbox_Moodles_Sickness", fallback = "Sickness", min = 0, max = 100, get = bodyGetter("getFoodSicknessLevel"), set = bodySetter("setFoodSicknessLevel") })
        add({ id = "fatigue", labelKey = "UI_ZedToolbox_Moodles_Fatigue", fallback = "Fatigue", min = 0, max = 1, get = statsGetter("getFatigue"), set = statsSetter("setFatigue") })
        add({ id = "hunger", labelKey = "UI_ZedToolbox_Moodles_Hunger", fallback = "Hunger", min = 0, max = 1, get = statsGetter("getHunger"), set = statsSetter("setHunger") })
        add({ id = "thirst", labelKey = "UI_ZedToolbox_Moodles_Thirst", fallback = "Thirst", min = 0, max = 1, get = statsGetter("getThirst"), set = statsSetter("setThirst") })
        add({ id = "boredom", labelKey = "UI_ZedToolbox_Moodles_Boredom", fallback = "Boredom", min = 0, max = 100, get = statsGetter("getBoredom"), set = statsSetter("setBoredom") })
        add({ id = "unhappiness", labelKey = "UI_ZedToolbox_Moodles_Unhappiness", fallback = "Unhappiness", min = 0, max = 100, get = statsGetter("getUnhappyness"), set = statsSetter("setUnhappyness") })

        return defs
    end

    function CheatMenuUI:refreshMoodleDefinitions()
        self.moodleDefinitions = buildMoodleDefinitions()
    end

    function CheatMenuUI:getMoodleDefinitions()
        if not self.moodleDefinitions then
            self:refreshMoodleDefinitions()
        end
        return self.moodleDefinitions or {}
    end

    local function getMoodleState(player, def)
        local value = nil
        if def and def.get then
            value = def.get(player)
        end
        local numeric = tonumber(value) or 0
        local min = def.min or 0
        local max = def.max or 1
        if numeric < min then numeric = min end
        if numeric > max then numeric = max end
        return numeric, min, max
    end

    local function setMoodleValue(player, def, value)
        if not player or not def or not def.set then
            return false
        end
        local min = def.min or 0
        local max = def.max or 1
        local target = value
        if target < min then target = min end
        if target > max then target = max end
        return def.set(player, target)
    end

    local function formatValue(value, min, max)
        local range = (max - min)
        if range <= 0 then
            return tostring(math.floor(value + 0.5))
        end
        local percent = ((value - min) / range) * 100
        return string.format("%.0f (%.0f%%)", value, percent)
    end

    function CheatMenuUI:getSelectedMoodleEntry()
        if not self.moodlesList then
            return nil
        end
        local entry = getListSelection and getListSelection(self.moodlesList) or nil
        return entry and entry.item or nil
    end

    function CheatMenuUI:updateMoodleDetail(entry)
        local def = entry and entry.definition
        local name = def and CheatMenuText.get(def.labelKey, def.fallback or def.id) or CheatMenuText.get("UI_ZedToolbox_Moodles_Select", "Select a moodle first.")
        local value = entry and entry.value or 0
        local min = entry and entry.min or 0
        local max = entry and entry.max or 0
        local valueText = def and CheatMenuText.get("UI_ZedToolbox_Moodles_Value", "Value: %1", formatValue(value, min, max)) or ""
        local rangeText = def and CheatMenuText.get("UI_ZedToolbox_Moodles_Range", "Range: %1 - %2", min, max) or ""
        self.moodleDetail = {
            lines = { name, valueText, rangeText },
            colors = {
                { r = 0.9, g = 0.9, b = 0.9 },
                { r = 0.78, g = 0.78, b = 0.78 },
                { r = 0.75, g = 0.75, b = 0.75 }
            }
        }
    end

    function CheatMenuUI:refreshMoodlesUI()
        if not self.moodlesList then
            return
        end
        self:refreshMoodleDefinitions()
        local defs = self:getMoodleDefinitions()
        local player = getPlayerCharacter()
        self.moodlesList:clear()
        if not defs or #defs == 0 then
            self.moodlesList:addItem(CheatMenuText.get("UI_ZedToolbox_Moodles_None", "No moodles available"), {})
            self.moodlesList.selected = 1
            self:updateMoodleDetail(nil)
            return
        end
        local fallbackIndex = 1
        local idx = 1
        local previous = self:getSelectedMoodleEntry()
        local previousId = previous and previous.definition and previous.definition.id
        for _, def in ipairs(defs) do
            local value, min, max = getMoodleState(player, def)
            local itemData = {
                definition = def,
                value = value,
                min = min,
                max = max
            }
            local label = CheatMenuText.get(def.labelKey, def.fallback or def.id)
            local display = string.format("%s", label)
            self.moodlesList:addItem(display, itemData)
            if previousId and def.id == previousId then
                fallbackIndex = idx
            end
            idx = idx + 1
        end
        local count = self.moodlesList.items and #self.moodlesList.items or 0
        if count > 0 then
            if fallbackIndex > count then
                fallbackIndex = count
            end
            self.moodlesList.selected = fallbackIndex
        else
            self.moodlesList.selected = 0
        end
        self:updateMoodleDetail(self:getSelectedMoodleEntry())
    end

    function CheatMenuUI:syncMoodlesUI()
        self:refreshMoodlesUI()
    end

    local function applyCurrentMoodle(self, targetValue)
        local entry = self:getSelectedMoodleEntry()
        if not entry or not entry.definition then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Moodles_Select", "Select a moodle first."))
            return
        end
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        local success = setMoodleValue(player, entry.definition, targetValue)
        self:syncMoodlesUI()
        local key = success and "UI_ZedToolbox_Moodles_StatusSet" or "UI_ZedToolbox_Moodles_StatusFailed"
        local fallback = success and "%1 set." or "Could not update moodles."
        self:setStatus(success, CheatMenuText.get(key, fallback, CheatMenuText.get(entry.definition.labelKey, entry.definition.fallback or entry.definition.id)))
    end

    function CheatMenuUI:onMoodleSelected()
        self:updateMoodleDetail(self:getSelectedMoodleEntry())
    end

    function CheatMenuUI:onMoodleSetMin()
        local entry = self:getSelectedMoodleEntry()
        if not entry then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Moodles_Select", "Select a moodle first."))
            return
        end
        applyCurrentMoodle(self, entry.min or 0)
    end

    function CheatMenuUI:onMoodleSetMax()
        local entry = self:getSelectedMoodleEntry()
        if not entry then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Moodles_Select", "Select a moodle first."))
            return
        end
        applyCurrentMoodle(self, entry.max or 1)
    end

    function CheatMenuUI:onMoodleNormalize()
        local entry = self:getSelectedMoodleEntry()
        if not entry then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Moodles_Select", "Select a moodle first."))
            return
        end
        applyCurrentMoodle(self, entry.min or 0)
    end

    function CheatMenuUI:onMoodlesClearNegative()
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        self:refreshMoodleDefinitions()
        local defs = self:getMoodleDefinitions()
        local applied = 0
        for _, def in ipairs(defs) do
            if setMoodleValue(player, def, def.min or 0) then
                applied = applied + 1
            end
        end
        self:syncMoodlesUI()
        local success = applied > 0
        self:setStatus(success, CheatMenuText.get("UI_ZedToolbox_Moodles_StatusCleared", "%1 moodles cleared.", applied))
    end

    function CheatMenuUI:onMoodlesMaxAll()
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        self:refreshMoodleDefinitions()
        local defs = self:getMoodleDefinitions()
        local applied = 0
        for _, def in ipairs(defs) do
            if setMoodleValue(player, def, def.max or 1) then
                applied = applied + 1
            end
        end
        self:syncMoodlesUI()
        local success = applied > 0
        self:setStatus(success, CheatMenuText.get("UI_ZedToolbox_Moodles_StatusMaxAll", "%1 moodles set to max.", applied))
    end

    function CheatMenuUI:buildMoodlesUI()
        local listTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
        local listHeight = self.height - listTop - BOTTOM_HEIGHT
        local listWidth = LEFT_WIDTH + COLUMN_GAP + CENTER_WIDTH

        self.moodlesList = ISScrollingListBox:new(PADDING, listTop, listWidth, listHeight)
        self.moodlesList:initialise()
        self.moodlesList:instantiate()
        self.moodlesList.itemheight = 26
        self.moodlesList.font = UIFont.Small
        self.moodlesList.doDrawItem = function(list, y, item)
            local data = item.item or {}
            local isSelected = list.selected == item.index
            if isSelected then
                list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
            end
            local r, g, b = 0.9, 0.9, 0.9
            list:drawText(item.text or "Moodle", 10, y + 5, r, g, b, 1, UIFont.Small)
            return y + item.height
        end
        self.moodlesList.onMouseDown = function(list, x, y)
            ISScrollingListBox.onMouseDown(list, x, y)
            self:onMoodleSelected()
        end
        self:addChild(self.moodlesList)
        self:addToTab("moodles", self.moodlesList)
        self.moodlesListLabelPos = { x = PADDING, y = listTop - 20 }

        local detailX = PADDING + listWidth + COLUMN_GAP
        local detailWidth = self.width - detailX - PADDING
        self.moodleDetailLabelPos = { x = detailX, y = listTop - 20 }
        self.moodleDetailTextPos = { x = detailX, y = listTop + 6 }

        local buttonWidth = math.max(200, detailWidth)
        local minY = listTop + 90
        self.moodleSetMinBtn = ISButton:new(detailX, minY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Moodles_SetMin", "Set Minimum"), self, CheatMenuUI.onMoodleSetMin)
        self.moodleSetMinBtn:initialise()
        self.moodleSetMinBtn:instantiate()
        self:addChild(self.moodleSetMinBtn)
        self:addToTab("moodles", self.moodleSetMinBtn)

        local maxY = minY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.moodleSetMaxBtn = ISButton:new(detailX, maxY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Moodles_SetMax", "Set Maximum"), self, CheatMenuUI.onMoodleSetMax)
        self.moodleSetMaxBtn:initialise()
        self.moodleSetMaxBtn:instantiate()
        self:addChild(self.moodleSetMaxBtn)
        self:addToTab("moodles", self.moodleSetMaxBtn)

        local normalizeY = maxY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.moodleNormalizeBtn = ISButton:new(detailX, normalizeY, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Moodles_Normalize", "Normalize"), self, CheatMenuUI.onMoodleNormalize)
        self.moodleNormalizeBtn:initialise()
        self.moodleNormalizeBtn:instantiate()
        self:addChild(self.moodleNormalizeBtn)
        self:addToTab("moodles", self.moodleNormalizeBtn)

        local clearAllY = normalizeY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.moodlesClearNegativeBtn = ISButton:new(detailX, clearAllY, buttonWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Moodles_ClearNegatives", "Clear All Negatives"), self, CheatMenuUI.onMoodlesClearNegative)
        self.moodlesClearNegativeBtn:initialise()
        self.moodlesClearNegativeBtn:instantiate()
        self:addChild(self.moodlesClearNegativeBtn)
        self:addToTab("moodles", self.moodlesClearNegativeBtn)

        local maxAllY = clearAllY + PRIMARY_BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.moodlesMaxAllBtn = ISButton:new(detailX, maxAllY, buttonWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Moodles_MaxAll", "Max All Moodles"), self, CheatMenuUI.onMoodlesMaxAll)
        self.moodlesMaxAllBtn:initialise()
        self.moodlesMaxAllBtn:instantiate()
        self:addChild(self.moodlesMaxAllBtn)
        self:addToTab("moodles", self.moodlesMaxAllBtn)

        local sectionTop = listTop - 30
        local sectionBottom = maxAllY + PRIMARY_BUTTON_HEIGHT + SECTION_GAP
        self.moodlesSection = {
            x = PADDING,
            y = sectionTop,
            w = self.width - (2 * PADDING),
            h = sectionBottom - sectionTop
        }

        self:refreshMoodlesUI()
    end
end
