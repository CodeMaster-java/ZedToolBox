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
    local clamp = deps.clamp
    local CheatMenuSession = require "CheatMenuSession"

    local HOUR_MIN = 0
    local HOUR_MAX = 23
    local MINUTE_MIN = 0
    local MINUTE_MAX = 59
    local MULTIPLIER_MIN = 0
    local MULTIPLIER_MAX = 100
    local SKIP_HOURS_MIN = 1
    local SKIP_HOURS_MAX = 240
    local SKIP_DAYS_MIN = 1
    local SKIP_DAYS_MAX = 365
    local WEATHER_STAGE_SHOWERS = 1
    local WEATHER_STAGE_STORM = 3
    local WEATHER_FOG_INTENSITY = 1
    local GUNSHOT_RADIUS = 500
    local GUNSHOT_VOLUME = 500
    local SCREAM_RADIUS = 350
    local SCREAM_VOLUME = 350

    local weatherOptions = {
        { id = "clear", labelKey = "UI_ZedToolbox_World_WeatherClear", fallback = "Clear" },
        { id = "rain", labelKey = "UI_ZedToolbox_World_WeatherRain", fallback = "Rain" },
        { id = "storm", labelKey = "UI_ZedToolbox_World_WeatherStorm", fallback = "Storm" },
        { id = "fog", labelKey = "UI_ZedToolbox_World_WeatherFog", fallback = "Fog" }
    }

    local eventOptions = {
        { id = "helicopter", labelKey = "UI_ZedToolbox_World_EventHeli", fallback = "Helicopter Event" },
        { id = "gunshot", labelKey = "UI_ZedToolbox_World_EventGunshot", fallback = "Gunshot Meta" },
        { id = "screamer", labelKey = "UI_ZedToolbox_World_EventScreamer", fallback = "Screamer Meta" }
    }

    local function clearCombo(combo)
        if not combo then
            return
        end
        if combo.clear then
            combo:clear()
        end
        combo.options = {}
    end

    local function getSelectedOptionData(combo)
        if not combo or not combo.options then
            return nil
        end
        local selected = combo.options[combo.selected]
        return selected and selected.data or nil
    end

    local function populateCombo(combo, options, selectedId)
        if not combo then
            return
        end
        clearCombo(combo)
        local fallbackIndex = 1
        for index, option in ipairs(options) do
            local label = CheatMenuText.get(option.labelKey, option.fallback)
            if combo.addOptionWithData then
                combo:addOptionWithData(label, option.id)
            else
                combo:addOption(label)
                combo.options = combo.options or {}
                if combo.options[#combo.options] then
                    combo.options[#combo.options].data = option.id
                end
            end
            if option.id == selectedId then
                fallbackIndex = index
            end
        end
        combo.selected = fallbackIndex
    end

    local function getGameTimeSafe()
        if getGameTime then
            return getGameTime()
        end
        if _G.GameTime and _G.GameTime.getInstance then
            return _G.GameTime.getInstance()
        end
        return nil
    end

    local function getClimateManagerSafe()
        if getClimateManager then
            return getClimateManager()
        end
        if _G.getClimateManager then
            return _G.getClimateManager()
        end
        if getWorld and type(getWorld) == "function" then
            local ok, world = pcall(getWorld)
            if ok and world and world.getClimateManager then
                local okMgr, mgr = pcall(function() return world:getClimateManager() end)
                if okMgr and mgr then
                    return mgr
                end
            end
        end
        if _G.ClimateManager then
            if _G.ClimateManager.getInstance then
                return _G.ClimateManager.getInstance()
            end
            if _G.ClimateManager.instance then
                return _G.ClimateManager.instance
            end
        end
        return nil
    end

    local function safeCall(target, method, ...)
        if not target or type(target[method]) ~= "function" then
            return false
        end
        local ok, result = pcall(target[method], target, ...)
        return ok and result ~= nil or ok
    end

    local function triggerWorldSound(player, radius, volume)
        if not player then
            return false
        end
        if safeCall(player, "addWorldSoundUnlessInvisible", radius, volume, false) then
            return true
        end
        local okX, x = pcall(function() return player:getX() end)
        local okY, y = pcall(function() return player:getY() end)
        local okZ, z = pcall(function() return player:getZ() end)
        if okX and okY and okZ then
            return safeCall(_G, "addSound", player, x, y, z, radius, volume)
        end
        return false
    end

    local function getCurrentHourMinute()
        local gt = getGameTimeSafe()
        if not gt then
            return 12, 0
        end
        local hour = 12
        local minute = 0
        local okHour, resultHour = pcall(function() return gt:getHour() end)
        if okHour and resultHour then
            hour = tonumber(resultHour) or hour
        end
        local okMin, resultMin = pcall(function() return gt:getMinutes() end)
        if okMin and resultMin then
            minute = tonumber(resultMin) or minute
        end
        return hour, minute
    end

    local function setTime(hour, minute)
        local gt = getGameTimeSafe()
        if not gt then
            return false
        end
        local clampedHour = clamp(hour, HOUR_MIN, HOUR_MAX)
        local clampedMinute = clamp(minute, MINUTE_MIN, MINUTE_MAX)
        local timeOfDay = clampedHour + (clampedMinute / 60)
        local ok = safeCall(gt, "setTimeOfDay", timeOfDay)
        if not ok then
            ok = safeCall(gt, "setHour", clampedHour) and safeCall(gt, "setMinutes", clampedMinute)
        end
        return ok
    end

    local function setMultiplier(multiplier)
        local gt = getGameTimeSafe()
        if not gt then
            return false
        end
        local value = clamp(multiplier, MULTIPLIER_MIN, MULTIPLIER_MAX)
        local ok = safeCall(gt, "setMultiplier", value)
        return ok
    end

    local function getMultiplier()
        local gt = getGameTimeSafe()
        if not gt then
            return 1
        end
        local ok, result = pcall(function() return gt:getMultiplier() end)
        if ok and result then
            return tonumber(result) or 1
        end
        return 1
    end

    local function addDays(days)
        local gt = getGameTimeSafe()
        if not gt then
            return false
        end
        local okDay, currentDay = pcall(function() return gt:getDay() end)
        local targetDay = (okDay and tonumber(currentDay)) and (tonumber(currentDay) + days) or nil
        if targetDay then
            local ok = safeCall(gt, "setDay", targetDay)
            if ok then
                return true
            end
        end
        return false
    end

    local function addHours(hours)
        local gt = getGameTimeSafe()
        if not gt then
            return false
        end
        local hour, minute = getCurrentHourMinute()
        local totalMinutes = (hour * 60) + minute + math.floor(hours * 60)
        local extraDays = math.floor(totalMinutes / (24 * 60))
        local newMinutes = totalMinutes % (24 * 60)
        local newHour = math.floor(newMinutes / 60)
        local newMinute = newMinutes % 60
        local okTime = setTime(newHour, newMinute)
        if extraDays > 0 then
            addDays(extraDays)
        end
        return okTime
    end

    local function applyWeather(mode)
        local climate = getClimateManagerSafe()
        if not climate then
            return false
        end
        local success = false
        if mode == "clear" then
            success = safeCall(climate, "transmitStopWeather") or success
            success = safeCall(climate, "stopWeatherAndThunder") or success
            success = safeCall(climate, "stopWeather") or success
            success = safeCall(climate, "setFogIntensity", 0) or success
        elseif mode == "rain" then
            success = safeCall(climate, "triggerCustomWeatherStage", WEATHER_STAGE_SHOWERS, 48) or success
            success = safeCall(climate, "triggerCustomWeather", 0.35, true) or success
            success = safeCall(climate, "setFogIntensity", 0) or success
        elseif mode == "storm" then
            success = safeCall(climate, "transmitTriggerStorm", 48) or success
            success = safeCall(climate, "triggerCustomWeatherStage", WEATHER_STAGE_STORM, 48) or success
            success = safeCall(climate, "setFogIntensity", 0) or success
        elseif mode == "fog" then
            success = safeCall(climate, "setFogIntensity", WEATHER_FOG_INTENSITY) or success
            success = safeCall(climate, "setRaining", false) or success
        end
        return success
    end

    local function triggerEvent(eventId)
        local player = CheatMenuSession.getPlayerObject()
        local triggered = false
        if eventId == "helicopter" then
            if type(_G.testHelicopter) == "function" then
                triggered = pcall(_G.testHelicopter)
            end
        elseif eventId == "gunshot" then
            triggered = triggerWorldSound(player, GUNSHOT_RADIUS, GUNSHOT_VOLUME)
        elseif eventId == "screamer" then
            triggered = triggerWorldSound(player, SCREAM_RADIUS, SCREAM_VOLUME)
        end
        return triggered
    end

    function CheatMenuUI:syncWorldUI()
        local hour, minute = getCurrentHourMinute()
        if self.worldHourEntry then
            self.worldHourEntry:setText(tostring(hour))
        end
        if self.worldMinuteEntry then
            self.worldMinuteEntry:setText(tostring(minute))
        end
        if self.worldMultiplierEntry then
            self.worldMultiplierEntry:setText(tostring(getMultiplier()))
        end
        if self.worldSkipHoursEntry then
            self.worldSkipHoursEntry:setText("12")
        end
        if self.worldSkipDaysEntry then
            self.worldSkipDaysEntry:setText("1")
        end
    end

    function CheatMenuUI:onWorldSetTime()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local hour = tonumber(self.worldHourEntry and self.worldHourEntry:getText()) or 0
        local minute = tonumber(self.worldMinuteEntry and self.worldMinuteEntry:getText()) or 0
        local success = setTime(hour, minute)
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusTimeSet" or "UI_ZedToolbox_World_StatusFailed", success and "Time updated." or "Failed to update time."))
        self:syncWorldUI()
    end

    function CheatMenuUI:onWorldSkipHours()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local hours = tonumber(self.worldSkipHoursEntry and self.worldSkipHoursEntry:getText()) or SKIP_HOURS_MIN
        hours = clamp(hours, SKIP_HOURS_MIN, SKIP_HOURS_MAX)
        local success = addHours(hours)
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusTimeSkipped" or "UI_ZedToolbox_World_StatusFailed", success and "%1 hours skipped." or "Failed to update time.", hours))
        self:syncWorldUI()
    end

    function CheatMenuUI:onWorldSkipDays()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local days = tonumber(self.worldSkipDaysEntry and self.worldSkipDaysEntry:getText()) or SKIP_DAYS_MIN
        days = clamp(days, SKIP_DAYS_MIN, SKIP_DAYS_MAX)
        local success = addDays(days)
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusDaysSkipped" or "UI_ZedToolbox_World_StatusFailed", success and "%1 days skipped." or "Failed to update time.", days))
        self:syncWorldUI()
    end

    function CheatMenuUI:onWorldFreeze()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        self.worldMultiplierBackup = self.worldMultiplierBackup or getMultiplier()
        local success = setMultiplier(0)
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusFrozen" or "UI_ZedToolbox_World_StatusFailed", success and "Time frozen." or "Failed to freeze time."))
        self:syncWorldUI()
    end

    function CheatMenuUI:onWorldUnfreeze()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local target = self.worldMultiplierBackup or 1
        local success = setMultiplier(target)
        self.worldMultiplierBackup = nil
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusUnfrozen" or "UI_ZedToolbox_World_StatusFailed", success and "Time resumed." or "Failed to resume time."))
        self:syncWorldUI()
    end

    function CheatMenuUI:onWorldApplyMultiplier()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local multiplier = tonumber(self.worldMultiplierEntry and self.worldMultiplierEntry:getText()) or 1
        multiplier = clamp(multiplier, MULTIPLIER_MIN, MULTIPLIER_MAX)
        local success = setMultiplier(multiplier)
        if success then
            self.worldMultiplierBackup = multiplier
        end
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusMultiplier" or "UI_ZedToolbox_World_StatusFailed", success and "Multiplier set to %1." or "Failed to update multiplier.", multiplier))
        self:syncWorldUI()
    end

    function CheatMenuUI:onWorldApplyWeather()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local selected = self.worldWeatherCombo and self.worldWeatherCombo.options and self.worldWeatherCombo.options[self.worldWeatherCombo.selected]
        local mode = selected and selected.data or "clear"
        local success = applyWeather(mode)
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusWeather" or "UI_ZedToolbox_World_StatusFailed", success and "Weather applied." or "Weather change failed."))
    end

    function CheatMenuUI:onWorldApplyEvent()
        if not CheatMenuSession.ensureSingleplayer(self, CheatMenuText.get("UI_ZedToolbox_World_StatusSingleplayer", "Singleplayer only.")) then
            return
        end
        local selected = self.worldEventCombo and self.worldEventCombo.options and self.worldEventCombo.options[self.worldEventCombo.selected]
        local eventId = selected and selected.data or nil
        local success = eventId and triggerEvent(eventId) or false
        self:setStatus(success, CheatMenuText.get(success and "UI_ZedToolbox_World_StatusEvent" or "UI_ZedToolbox_World_StatusFailed", success and "Event triggered." or "Failed to trigger event."))
    end

    function CheatMenuUI:refreshWorldTranslations()
        if self.worldSetTimeBtn then
            self.worldSetTimeBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_SetTime", "Set Time"))
        end
        if self.worldSkipHoursBtn then
            self.worldSkipHoursBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_SkipHours", "Skip Hours"))
        end
        if self.worldSkipDaysBtn then
            self.worldSkipDaysBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_SkipDays", "Skip Days"))
        end
        if self.worldFreezeBtn then
            self.worldFreezeBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_Freeze", "Freeze Time"))
        end
        if self.worldUnfreezeBtn then
            self.worldUnfreezeBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_Unfreeze", "Unfreeze Time"))
        end
        if self.worldMultiplierBtn then
            self.worldMultiplierBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_SetMultiplier", "Set Time Multiplier"))
        end
        if self.worldWeatherBtn then
            self.worldWeatherBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_ApplyWeather", "Apply Weather"))
        end
        if self.worldEventBtn then
            self.worldEventBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_World_ApplyEvent", "Trigger Event"))
        end
        local selectedWeather = getSelectedOptionData(self.worldWeatherCombo) or "clear"
        local selectedEvent = getSelectedOptionData(self.worldEventCombo)
        populateCombo(self.worldWeatherCombo, weatherOptions, selectedWeather)
        populateCombo(self.worldEventCombo, eventOptions, selectedEvent or (eventOptions[1] and eventOptions[1].id))
    end

    function CheatMenuUI:buildWorldUI()
        local contentTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
        local rowGap = BUTTON_ROW_GAP + 8
        local groupGap = SECTION_GAP + 8
        local labelOffset = 22
        local entryHeight = 24
        local sectionTop = contentTop - 50

        local rowY = contentTop
        local entryWidth = 70
        self.worldHourLabelPos = { x = PADDING, y = rowY - labelOffset }
        self.worldHourEntry = ISTextEntryBox:new("12", PADDING, rowY, entryWidth, entryHeight)
        self.worldHourEntry:initialise()
        self.worldHourEntry:instantiate()
        self.worldHourEntry:setOnlyNumbers(true)
        self:addChild(self.worldHourEntry)
        self:addToTab("world", self.worldHourEntry)

        local minuteX = PADDING + entryWidth + COLUMN_GAP
        self.worldMinuteLabelPos = { x = minuteX, y = rowY - labelOffset }
        self.worldMinuteEntry = ISTextEntryBox:new("0", minuteX, rowY, entryWidth, entryHeight)
        self.worldMinuteEntry:initialise()
        self.worldMinuteEntry:instantiate()
        self.worldMinuteEntry:setOnlyNumbers(true)
        self:addChild(self.worldMinuteEntry)
        self:addToTab("world", self.worldMinuteEntry)

        local applyTimeX = minuteX + entryWidth + COLUMN_GAP
        self.worldSetTimeBtn = ISButton:new(applyTimeX, rowY - 1, 170, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_SetTime", "Set Time"), self, CheatMenuUI.onWorldSetTime)
        self.worldSetTimeBtn:initialise()
        self.worldSetTimeBtn:instantiate()
        self:addChild(self.worldSetTimeBtn)
        self:addToTab("world", self.worldSetTimeBtn)

        local skipHoursY = rowY + BUTTON_HEIGHT + rowGap
        self.worldSkipHoursLabelPos = { x = PADDING, y = skipHoursY - labelOffset }
        self.worldSkipHoursEntry = ISTextEntryBox:new("12", PADDING, skipHoursY, entryWidth, entryHeight)
        self.worldSkipHoursEntry:initialise()
        self.worldSkipHoursEntry:instantiate()
        self.worldSkipHoursEntry:setOnlyNumbers(true)
        self:addChild(self.worldSkipHoursEntry)
        self:addToTab("world", self.worldSkipHoursEntry)

        local skipHoursBtnX = PADDING + entryWidth + COLUMN_GAP
        self.worldSkipHoursBtn = ISButton:new(skipHoursBtnX, skipHoursY - 1, 170, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_SkipHours", "Skip Hours"), self, CheatMenuUI.onWorldSkipHours)
        self.worldSkipHoursBtn:initialise()
        self.worldSkipHoursBtn:instantiate()
        self:addChild(self.worldSkipHoursBtn)
        self:addToTab("world", self.worldSkipHoursBtn)

        local skipDaysY = skipHoursY + BUTTON_HEIGHT + rowGap
        self.worldSkipDaysLabelPos = { x = PADDING, y = skipDaysY - labelOffset }
        self.worldSkipDaysEntry = ISTextEntryBox:new("1", PADDING, skipDaysY, entryWidth, entryHeight)
        self.worldSkipDaysEntry:initialise()
        self.worldSkipDaysEntry:instantiate()
        self.worldSkipDaysEntry:setOnlyNumbers(true)
        self:addChild(self.worldSkipDaysEntry)
        self:addToTab("world", self.worldSkipDaysEntry)

        local skipDaysBtnX = PADDING + entryWidth + COLUMN_GAP
        self.worldSkipDaysBtn = ISButton:new(skipDaysBtnX, skipDaysY - 1, 170, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_SkipDays", "Skip Days"), self, CheatMenuUI.onWorldSkipDays)
        self.worldSkipDaysBtn:initialise()
        self.worldSkipDaysBtn:instantiate()
        self:addChild(self.worldSkipDaysBtn)
        self:addToTab("world", self.worldSkipDaysBtn)

        local freezeY = skipDaysY + BUTTON_HEIGHT + groupGap
        local freezeX = PADDING
        self.worldFreezeBtn = ISButton:new(freezeX, freezeY, 150, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_Freeze", "Freeze Time"), self, CheatMenuUI.onWorldFreeze)
        self.worldFreezeBtn:initialise()
        self.worldFreezeBtn:instantiate()
        self:addChild(self.worldFreezeBtn)
        self:addToTab("world", self.worldFreezeBtn)

        local unfreezeX = freezeX + 170
        self.worldUnfreezeBtn = ISButton:new(unfreezeX, freezeY, 150, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_Unfreeze", "Unfreeze Time"), self, CheatMenuUI.onWorldUnfreeze)
        self.worldUnfreezeBtn:initialise()
        self.worldUnfreezeBtn:instantiate()
        self:addChild(self.worldUnfreezeBtn)
        self:addToTab("world", self.worldUnfreezeBtn)

        local multiplierY = freezeY + BUTTON_HEIGHT + groupGap
        local multiplierLabelY = multiplierY - labelOffset
        local multiplierEntryX = PADDING
        self.worldMultiplierLabelPos = { x = multiplierEntryX, y = multiplierLabelY }
        self.worldMultiplierEntry = ISTextEntryBox:new("1", multiplierEntryX, multiplierY, entryWidth, entryHeight)
        self.worldMultiplierEntry:initialise()
        self.worldMultiplierEntry:instantiate()
        self.worldMultiplierEntry:setOnlyNumbers(true)
        self:addChild(self.worldMultiplierEntry)
        self:addToTab("world", self.worldMultiplierEntry)

        local multiplierBtnX = multiplierEntryX + entryWidth + COLUMN_GAP
        self.worldMultiplierBtn = ISButton:new(multiplierBtnX, multiplierY - 1, 190, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_SetMultiplier", "Set Time Multiplier"), self, CheatMenuUI.onWorldApplyMultiplier)
        self.worldMultiplierBtn:initialise()
        self.worldMultiplierBtn:instantiate()
        self:addChild(self.worldMultiplierBtn)
        self:addToTab("world", self.worldMultiplierBtn)

        local weatherY = multiplierY + BUTTON_HEIGHT + groupGap
        local weatherX = PADDING
        self.worldWeatherLabelPos = { x = weatherX, y = weatherY - labelOffset }
        self.worldWeatherCombo = ISComboBox:new(weatherX, weatherY, 180, 24, self, nil)
        self.worldWeatherCombo:initialise()
        self.worldWeatherCombo:instantiate()
        populateCombo(self.worldWeatherCombo, weatherOptions, "clear")
        self:addChild(self.worldWeatherCombo)
        self:addToTab("world", self.worldWeatherCombo)

        local weatherBtnY = weatherY + BUTTON_HEIGHT + rowGap
        self.worldWeatherBtn = ISButton:new(weatherX, weatherBtnY, 180, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_ApplyWeather", "Apply Weather"), self, CheatMenuUI.onWorldApplyWeather)
        self.worldWeatherBtn:initialise()
        self.worldWeatherBtn:instantiate()
        self:addChild(self.worldWeatherBtn)
        self:addToTab("world", self.worldWeatherBtn)

        local eventX = weatherX + 220
        local eventY = weatherY
        self.worldEventLabelPos = { x = eventX, y = eventY - labelOffset }
        self.worldEventCombo = ISComboBox:new(eventX, eventY, 200, 24, self, nil)
        self.worldEventCombo:initialise()
        self.worldEventCombo:instantiate()
        populateCombo(self.worldEventCombo, eventOptions, eventOptions[1] and eventOptions[1].id)
        self:addChild(self.worldEventCombo)
        self:addToTab("world", self.worldEventCombo)

        local eventBtnY = eventY + BUTTON_HEIGHT + rowGap
        self.worldEventBtn = ISButton:new(eventX, eventBtnY, 200, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_World_ApplyEvent", "Trigger Event"), self, CheatMenuUI.onWorldApplyEvent)
        self.worldEventBtn:initialise()
        self.worldEventBtn:instantiate()
        self:addChild(self.worldEventBtn)
        self:addToTab("world", self.worldEventBtn)

        local sectionBottom = math.max(self.worldEventBtn.y + self.worldEventBtn.height, self.worldWeatherBtn.y + self.worldWeatherBtn.height) + SECTION_GAP
        self.worldSection = {
            x = PADDING,
            y = sectionTop,
            w = self.width - (2 * PADDING),
            h = sectionBottom - sectionTop
        }

        self:syncWorldUI()
    end
end
