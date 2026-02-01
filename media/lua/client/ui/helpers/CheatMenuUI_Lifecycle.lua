return function(CheatMenuUI, deps)
    local clamp = deps.clamp
    local CheatMenuItems = deps.CheatMenuItems
    local CheatMenuUtils = deps.CheatMenuUtils
    local CheatMenuText = deps.CheatMenuText
    local getHotkeyOptions = deps.getHotkeyOptions
    local getCheatMenuMain = deps.getCheatMenuMain
    local getListSelection = deps.getListSelection
    local getCategoryLabel = deps.getCategoryLabel
    local constants = deps.constants

    local PADDING = constants.PADDING
    local COLUMN_GAP = constants.COLUMN_GAP
    local LIST_TOP = constants.LIST_TOP
    local TAB_HEIGHT = constants.TAB_HEIGHT
    local TAB_BUTTON_WIDTH = constants.TAB_BUTTON_WIDTH
    local TAB_GAP = constants.TAB_GAP
    local BOTTOM_HEIGHT = constants.BOTTOM_HEIGHT
    local LEFT_WIDTH = constants.LEFT_WIDTH
    local CENTER_WIDTH = constants.CENTER_WIDTH
    local RIGHT_WIDTH = constants.RIGHT_WIDTH
    local MODDATA_KEY = constants.MODDATA_KEY
    local BUTTON_HEIGHT = constants.BUTTON_HEIGHT
    local BUTTON_GAP = constants.BUTTON_GAP
    local BUTTON_ROW_GAP = constants.BUTTON_ROW_GAP
    local SECTION_GAP = constants.SECTION_GAP
    local PRESET_NAME_HEIGHT = constants.PRESET_NAME_HEIGHT
    local PRESET_NAME_GAP = constants.PRESET_NAME_GAP
    local SPAWN_BUTTON_WIDTH = constants.SPAWN_BUTTON_WIDTH
    local MIN_FAVORITES_HEIGHT = constants.MIN_FAVORITES_HEIGHT
    local MIN_PRESETS_HEIGHT = constants.MIN_PRESETS_HEIGHT
    local SECTION_BG_ALPHA = constants.SECTION_BG_ALPHA
    local SECTION_BORDER_ALPHA = constants.SECTION_BORDER_ALPHA
    local BOTTOM_PANEL_PADDING = constants.BOTTOM_PANEL_PADDING
    local PRIMARY_BUTTON_HEIGHT = constants.PRIMARY_BUTTON_HEIGHT
    local REMOVE_BUTTON_EXTRA_GAP = constants.REMOVE_BUTTON_EXTRA_GAP
    local SEARCH_LABEL_WIDTH = constants.SEARCH_LABEL_WIDTH
    local SEARCH_FIELD_WIDTH = constants.SEARCH_FIELD_WIDTH
    local PRESET_HEADER_GAP = constants.PRESET_HEADER_GAP
    local CREDIT_TEXT = constants.CREDIT_TEXT
    local STATUS_SUCCESS = constants.STATUS_SUCCESS
    local STATUS_ERROR = constants.STATUS_ERROR

    function CheatMenuUI:initialise()
        ISPanel.initialise(self)
        self:createChildren()
        self:populateSkillOptions()
        self:populateSkillLevelOptions(0)
        self:syncSkillUI()
        if self.refreshTraitsUI then
            self:refreshTraitsUI()
        end
        self:refreshCatalog()
        self:loadPersistentData()
        self:refreshFavoritesUI()
        self:refreshPresetsUI()
        if self.refreshTraitsUI then
            self:refreshTraitsUI()
        end
        self:populateHotkeyOptions(self.config and self.config.toggleKey)
        self:populateLanguageOptions()
        self:applyTranslations()
    end

    function CheatMenuUI:createChildren()
        ISPanel.createChildren(self)

        self.closeBtn = ISButton:new(self.width - 36, 12, 24, 24, "X", self, CheatMenuUI.onClose)
        self.closeBtn:initialise()
        self.closeBtn:instantiate()
        self:addChild(self.closeBtn)

        local tabX = PADDING
        local tabY = PADDING

        self.tabSelector = ISComboBox:new(tabX, tabY, TAB_BUTTON_WIDTH, TAB_HEIGHT, self, nil)
        self.tabSelector:initialise()
        self.tabSelector:instantiate()
        self.tabSelector.onChange = function()
            self:onTabSelectionChanged()
        end
        self:addChild(self.tabSelector)
        self:populateTabSelector(self.activeTab)

        local searchLabelX = PADDING
        local searchFieldY = tabY + TAB_HEIGHT + TAB_GAP
        local searchFieldX = searchLabelX + SEARCH_LABEL_WIDTH + 8
        local searchWidth = math.min(SEARCH_FIELD_WIDTH, self.width - searchFieldX - PADDING)
        self.searchBox = ISTextEntryBox:new("", searchFieldX, searchFieldY, searchWidth, 22)
        self.searchBox:initialise()
        self.searchBox:instantiate()
        self.searchBox.onTextChange = function()
            self:onFilterChanged()
        end
        self:addChild(self.searchBox)
        self.searchLabelPos = { x = searchLabelX, y = searchFieldY + 3 }
        self:addToTab("items", self.searchBox)

        local listTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
        local listHeight = self.height - listTop - BOTTOM_HEIGHT

        self.categoryList = ISScrollingListBox:new(PADDING, listTop, LEFT_WIDTH, listHeight)
        self.categoryList:initialise()
        self.categoryList:instantiate()
        self.categoryList.itemheight = 24
        self.categoryList.font = UIFont.Small
        self.categoryList.doDrawItem = function(list, y, item)
            local isSelected = list.selected == item.index
            if isSelected then
                list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
            end
            local tint = isSelected and 1 or 0.9
            list:drawText(item.text, 10, y + 5, tint, tint, tint, 1, UIFont.Small)
            return y + item.height
        end
        self.categoryList.onMouseDown = function(list, x, y)
            ISScrollingListBox.onMouseDown(list, x, y)
            self:onCategoryChanged()
        end
        self:addChild(self.categoryList)
        self:addToTab("items", self.categoryList)

        self.itemsList = ISScrollingListBox:new(PADDING + LEFT_WIDTH + COLUMN_GAP, listTop, CENTER_WIDTH, listHeight)
        self.itemsList:initialise()
        self.itemsList:instantiate()
        self.itemsList.itemheight = 26
        self.itemsList.font = UIFont.Small
        self.itemsList.doDrawItem = function(list, y, item)
            local isSelected = list.selected == item.index
            if isSelected then
                list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
            end
            local tint = isSelected and 1 or 0.9
            list:drawText(item.text, 10, y + 5, tint, tint, tint, 1, UIFont.Small)
            return y + item.height
        end
        self.itemsList.onMouseDown = function(list, x, y)
            ISScrollingListBox.onMouseDown(list, x, y)
            self:onItemSelected()
        end
        self.itemsList.onMouseDoubleClick = function()
            self:onSpawnClicked()
        end
        self:addChild(self.itemsList)
        self:addToTab("items", self.itemsList)

        local rightX = PADDING + LEFT_WIDTH + COLUMN_GAP + CENTER_WIDTH + COLUMN_GAP
        local dualColumnGap = COLUMN_GAP * 2
        local favoritesWidth = math.floor((RIGHT_WIDTH - dualColumnGap) / 2)
        local presetsWidth = RIGHT_WIDTH - favoritesWidth - dualColumnGap
        local favoriteButtonRowWidth = math.floor((favoritesWidth - BUTTON_GAP) / 2)
        local presetButtonRowWidth = math.floor((presetsWidth - BUTTON_GAP) / 2)
        local labelOffset = 18

        local favoritesX = rightX
        local presetsX = favoritesX + favoritesWidth + dualColumnGap

        local favoritesSectionTop = listTop - 30
        self.favoritesCombo = ISComboBox:new(favoritesX, listTop, favoritesWidth, 24, self, nil)
        self.favoritesCombo:initialise()
        self.favoritesCombo:instantiate()
        self.favoritesCombo.onChange = function()
            self:onFavoriteSelected()
        end
        self:addChild(self.favoritesCombo)
        self.favoritesLabelPos = { x = favoritesX, y = self.favoritesCombo.y - 18 }
        self:addToTab("items", self.favoritesCombo)

        local favBtnY = self.favoritesCombo.y + self.favoritesCombo.height + BUTTON_ROW_GAP
        self.addFavoriteBtn = ISButton:new(favoritesX, favBtnY, favoriteButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_AddFavorite", "Add Favorite"), self, CheatMenuUI.onAddFavorite)
        self.addFavoriteBtn:initialise()
        self.addFavoriteBtn:instantiate()
        self:addChild(self.addFavoriteBtn)
        self:addToTab("items", self.addFavoriteBtn)

        self.useFavoriteBtn = ISButton:new(favoritesX + favoriteButtonRowWidth + BUTTON_GAP, favBtnY, favoriteButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_UseFavorite", "Use Favorite"), self, CheatMenuUI.onUseFavorite)
        self.useFavoriteBtn:initialise()
        self.useFavoriteBtn:instantiate()
        self:addChild(self.useFavoriteBtn)
        self:addToTab("items", self.useFavoriteBtn)

        local favSecondRowY = favBtnY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.spawnFavoriteBtn = ISButton:new(favoritesX, favSecondRowY, favoritesWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SpawnFavorite", "Spawn Favorite"), self, CheatMenuUI.onSpawnFavorite)
        self.spawnFavoriteBtn:initialise()
        self.spawnFavoriteBtn:instantiate()
        self:addChild(self.spawnFavoriteBtn)
        self:addToTab("items", self.spawnFavoriteBtn)

        local favFinalRowY = self.spawnFavoriteBtn.y + self.spawnFavoriteBtn.height + BUTTON_ROW_GAP + REMOVE_BUTTON_EXTRA_GAP
        self.removeFavoriteBtn = ISButton:new(favoritesX, favFinalRowY, favoritesWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_RemoveFavorite", "Remove Favorite"), self, CheatMenuUI.onRemoveFavorite)
        self.removeFavoriteBtn:initialise()
        self.removeFavoriteBtn:instantiate()
        self:addChild(self.removeFavoriteBtn)
        self:addToTab("items", self.removeFavoriteBtn)

        local favoritesSectionBottom = self.removeFavoriteBtn.y + self.removeFavoriteBtn.height + SECTION_GAP
        self.favoritesSection = {
            x = favoritesX - 8,
            y = favoritesSectionTop,
            w = favoritesWidth + 16,
            h = favoritesSectionBottom - favoritesSectionTop
        }

        local presetNameTop = listTop
        self.presetNameBox = ISTextEntryBox:new("", presetsX, presetNameTop, presetsWidth, PRESET_NAME_HEIGHT)
        self.presetNameBox:initialise()
        self.presetNameBox:instantiate()
        self:addChild(self.presetNameBox)
        self:addToTab("items", self.presetNameBox)

        local presetsSectionTop = listTop - 30
        local presetLabelY = self.presetNameBox.y + PRESET_NAME_HEIGHT + PRESET_NAME_GAP
        local presetComboY = presetLabelY + labelOffset
        self.presetsCombo = ISComboBox:new(presetsX, presetComboY, presetsWidth, 24, self, nil)
        self.presetsCombo:initialise()
        self.presetsCombo:instantiate()
        self.presetsCombo.onChange = function()
            self:onPresetSelected()
        end
        self:addChild(self.presetsCombo)
        self.presetsLabelPos = { x = presetsX, y = presetLabelY }
        self:addToTab("items", self.presetsCombo)

        local presetBtnY = self.presetsCombo.y + self.presetsCombo.height + BUTTON_GAP
        self.savePresetBtn = ISButton:new(presetsX, presetBtnY, presetButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SavePreset", "Save Preset"), self, CheatMenuUI.onSavePreset)
        self.savePresetBtn:initialise()
        self.savePresetBtn:instantiate()
        self:addChild(self.savePresetBtn)
        self:addToTab("items", self.savePresetBtn)

        self.applyPresetBtn = ISButton:new(presetsX + presetButtonRowWidth + BUTTON_GAP, presetBtnY, presetButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_ApplyPreset", "Apply Preset"), self, CheatMenuUI.onApplyPreset)
        self.applyPresetBtn:initialise()
        self.applyPresetBtn:instantiate()
        self:addChild(self.applyPresetBtn)
        self:addToTab("items", self.applyPresetBtn)

        local presetSecondRowY = presetBtnY + BUTTON_HEIGHT + BUTTON_ROW_GAP
        self.spawnPresetBtn = ISButton:new(presetsX, presetSecondRowY, presetsWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SpawnPreset", "Spawn Preset"), self, CheatMenuUI.onSpawnPreset)
        self.spawnPresetBtn:initialise()
        self.spawnPresetBtn:instantiate()
        self:addChild(self.spawnPresetBtn)
        self:addToTab("items", self.spawnPresetBtn)

        local presetFinalRowY = self.spawnPresetBtn.y + self.spawnPresetBtn.height + BUTTON_ROW_GAP + REMOVE_BUTTON_EXTRA_GAP
        self.removePresetBtn = ISButton:new(presetsX, presetFinalRowY, presetsWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_RemovePreset", "Remove Preset"), self, CheatMenuUI.onRemovePreset)
        self.removePresetBtn:initialise()
        self.removePresetBtn:instantiate()
        self:addChild(self.removePresetBtn)
        self:addToTab("items", self.removePresetBtn)

        local presetsSectionBottom = self.removePresetBtn.y + self.removePresetBtn.height + SECTION_GAP
        self.presetsSection = {
            x = presetsX - 8,
            y = presetsSectionTop,
            w = presetsWidth + 16,
            h = presetsSectionBottom - presetsSectionTop
        }

        local bottomTop = self.height - BOTTOM_HEIGHT + PADDING
        local bottomInnerX = PADDING + BOTTOM_PANEL_PADDING
        local bottomInnerWidth = self.width - (2 * PADDING) - (BOTTOM_PANEL_PADDING * 2)
        local bottomInnerY = bottomTop + BOTTOM_PANEL_PADDING
        local fieldGap = 12

        local baseInputY = bottomInnerY + labelOffset
        local baseIdWidth = math.max(280, bottomInnerWidth - SPAWN_BUTTON_WIDTH - 32)
        self.baseIdBox = ISTextEntryBox:new("", bottomInnerX, baseInputY, baseIdWidth, 26)
        self.baseIdBox:initialise()
        self.baseIdBox:instantiate()
        self:addChild(self.baseIdBox)
        self:addToTab("items", self.baseIdBox)

        local nextRowTop = self.baseIdBox.y + self.baseIdBox.height + fieldGap
        local quantityY = nextRowTop + labelOffset
        local quantityWidth = 130
        self.quantityBox = ISTextEntryBox:new("1", bottomInnerX, quantityY, quantityWidth, 26)
        self.quantityBox:initialise()
        self.quantityBox:instantiate()
        self.quantityBox:setOnlyNumbers(true)
        self:addChild(self.quantityBox)
        self:addToTab("items", self.quantityBox)

        local targetGap = 18
        local targetX = self.quantityBox.x + quantityWidth + targetGap
        local targetWidth = math.max(220, bottomInnerWidth - quantityWidth - targetGap)
        self.targetCombo = ISComboBox:new(targetX, quantityY, targetWidth, 26, self, nil)
        self.targetCombo:initialise()
        self.targetCombo:instantiate()
        self:addChild(self.targetCombo)
        self:addToTab("items", self.targetCombo)

        local spawnX = self.baseIdBox.x + self.baseIdBox.width + 16
        local spawnY = self.baseIdBox.y - 2
        self.spawnBtn = ISButton:new(spawnX, spawnY, SPAWN_BUTTON_WIDTH, PRIMARY_BUTTON_HEIGHT + 4, CheatMenuText.get("UI_ZedToolbox_Spawn", "Spawn"), self, CheatMenuUI.onSpawnClicked)
        self.spawnBtn:initialise()
        self.spawnBtn:instantiate()
        self:addChild(self.spawnBtn)
        self:addToTab("items", self.spawnBtn)

        local bottomContentBottom = math.max(self.spawnBtn.y + self.spawnBtn.height, self.targetCombo.y + self.targetCombo.height)
        local bottomSectionBottom = bottomContentBottom + BOTTOM_PANEL_PADDING
        self.bottomSection = {
            x = PADDING,
            y = bottomTop,
            w = self.width - (2 * PADDING),
            h = bottomSectionBottom - bottomTop
        }

        local utilsSectionTop = listTop - 30
        local utilsComboWidth = 240
        local utilsSpacing = 48
        local utilsX = PADDING

        local godModeY = listTop
        self.utilsLabelPositions.godMode = { x = utilsX, y = godModeY - 18 }
        self.godModeCombo = ISComboBox:new(utilsX, godModeY, utilsComboWidth, 24, self, nil)
        self.godModeCombo:initialise()
        self.godModeCombo:instantiate()
        self.godModeCombo.onChange = function()
            self:onGodModeChanged()
        end
        self:addChild(self.godModeCombo)
        self:addToTab("utils", self.godModeCombo)

        local hitKillY = godModeY + utilsSpacing
        self.utilsLabelPositions.hitKill = { x = utilsX, y = hitKillY - 18 }
        self.hitKillCombo = ISComboBox:new(utilsX, hitKillY, utilsComboWidth, 24, self, nil)
        self.hitKillCombo:initialise()
        self.hitKillCombo:instantiate()
        self.hitKillCombo.onChange = function()
            self:onHitKillChanged()
        end
        self:addChild(self.hitKillCombo)
        self:addToTab("utils", self.hitKillCombo)

        local infiniteY = hitKillY + utilsSpacing
        self.utilsLabelPositions.infiniteStamina = { x = utilsX, y = infiniteY - 18 }
        self.infiniteStaminaCombo = ISComboBox:new(utilsX, infiniteY, utilsComboWidth, 24, self, nil)
        self.infiniteStaminaCombo:initialise()
        self.infiniteStaminaCombo:instantiate()
        self.infiniteStaminaCombo.onChange = function()
            self:onInfiniteStaminaChanged()
        end
        self:addChild(self.infiniteStaminaCombo)
        self:addToTab("utils", self.infiniteStaminaCombo)

        local instantBuildY = infiniteY + utilsSpacing
        self.utilsLabelPositions.instantBuild = { x = utilsX, y = instantBuildY - 18 }
        self.instantBuildCombo = ISComboBox:new(utilsX, instantBuildY, utilsComboWidth, 24, self, nil)
        self.instantBuildCombo:initialise()
        self.instantBuildCombo:instantiate()
        self.instantBuildCombo.onChange = function()
            self:onInstantBuildChanged()
        end
        self:addChild(self.instantBuildCombo)
        self:addToTab("utils", self.instantBuildCombo)

        local noNegativeY = instantBuildY + utilsSpacing
        self.utilsLabelPositions.noNegativeEffects = { x = utilsX, y = noNegativeY - 18 }
        self.noNegativeEffectsCombo = ISComboBox:new(utilsX, noNegativeY, utilsComboWidth, 24, self, nil)
        self.noNegativeEffectsCombo:initialise()
        self.noNegativeEffectsCombo:instantiate()
        self.noNegativeEffectsCombo.onChange = function()
            self:onNoNegativeEffectsChanged()
        end
        self:addChild(self.noNegativeEffectsCombo)
        self:addToTab("utils", self.noNegativeEffectsCombo)

        local noHungerY = noNegativeY + utilsSpacing
        self.utilsLabelPositions.noHungerThirst = { x = utilsX, y = noHungerY - 18 }
        self.noHungerThirstCombo = ISComboBox:new(utilsX, noHungerY, utilsComboWidth, 24, self, nil)
        self.noHungerThirstCombo:initialise()
        self.noHungerThirstCombo:instantiate()
        self.noHungerThirstCombo.onChange = function()
            self:onNoHungerThirstChanged()
        end
        self:addChild(self.noHungerThirstCombo)
        self:addToTab("utils", self.noHungerThirstCombo)

        local speedY = noHungerY + utilsSpacing
        self.utilsLabelPositions.speed = { x = utilsX, y = speedY - 18 }
        self.speedCombo = ISComboBox:new(utilsX, speedY, utilsComboWidth, 24, self, nil)
        self.speedCombo:initialise()
        self.speedCombo:instantiate()
        self.speedCombo.onChange = function()
            self:onSpeedChanged()
        end
        self:addChild(self.speedCombo)
        self:addToTab("utils", self.speedCombo)

        local healY = speedY + utilsSpacing + 6
        self.healButton = ISButton:new(utilsX, healY, 180, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Utils_Heal", "Heal Player"), self, CheatMenuUI.onHealClicked)
        self.healButton:initialise()
        self.healButton:instantiate()
        self:addChild(self.healButton)
        self:addToTab("utils", self.healButton)

        local clearY = healY + BUTTON_HEIGHT + BUTTON_GAP
        local clearRadius = (CheatMenuUtils.getState() and CheatMenuUtils.getState().clearRadius) or 15
        local clearLabel = CheatMenuText.get("UI_ZedToolbox_Utils_ClearZombiesLabel", "Clear Nearby Zombies (%1 tiles)", clearRadius)
        self.clearZombiesButton = ISButton:new(utilsX, clearY, utilsComboWidth, BUTTON_HEIGHT, clearLabel, self, CheatMenuUI.onClearZombiesClicked)
        self.clearZombiesButton:initialise()
        self.clearZombiesButton:instantiate()
        self:addChild(self.clearZombiesButton)
        self:addToTab("utils", self.clearZombiesButton)

        local utilsSectionBottom = self.clearZombiesButton.y + self.clearZombiesButton.height + 40
        self.utilsSection = {
            x = utilsX - 8,
            y = utilsSectionTop,
            w = self.width - (2 * PADDING) + 16,
            h = utilsSectionBottom - utilsSectionTop
        }

        local configContentTop = listTop
        local configComboWidth = 220
        self.languageLabelPos = { x = PADDING, y = configContentTop - 18 }
        self.languageCombo = ISComboBox:new(PADDING, configContentTop, configComboWidth, 24, self, nil)
        self.languageCombo:initialise()
        self.languageCombo:instantiate()
        self:addChild(self.languageCombo)
        self:addToTab("config", self.languageCombo)

        local applyBtnX = PADDING + configComboWidth + BUTTON_GAP
        self.applyLanguageBtn = ISButton:new(applyBtnX, configContentTop, 120, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Apply", "Apply"), self, CheatMenuUI.onApplyLanguage)
        self.applyLanguageBtn:initialise()
        self.applyLanguageBtn:instantiate()
        self:addChild(self.applyLanguageBtn)
        self:addToTab("config", self.applyLanguageBtn)

        local hotkeyY = configContentTop + 44
        self.hotkeyLabelPos = { x = PADDING, y = hotkeyY - 18 }
        self.hotkeyCombo = ISComboBox:new(PADDING, hotkeyY, configComboWidth, 24, self, nil)
        self.hotkeyCombo:initialise()
        self.hotkeyCombo:instantiate()
        self:addChild(self.hotkeyCombo)
        self:addToTab("config", self.hotkeyCombo)

        self.applyHotkeyBtn = ISButton:new(applyBtnX, hotkeyY, 120, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SetHotkey", "Set Key"), self, CheatMenuUI.onApplyHotkey)
        self.applyHotkeyBtn:initialise()
        self.applyHotkeyBtn:instantiate()
        self:addChild(self.applyHotkeyBtn)
        self:addToTab("config", self.applyHotkeyBtn)

        local skillsSectionTop = listTop - 30
        local skillsSectionWidth = self.width - (PADDING * 2)
        local skillsInnerPadding = 12
        local skillsContentX = PADDING + skillsInnerPadding
        local skillsContentWidth = skillsSectionWidth - (skillsInnerPadding * 2)
        local skillComboWidth = math.min(320, skillsContentWidth)
        local skillRowY = skillsSectionTop + 42
        self.skillComboLabelPos = { x = skillsContentX, y = skillRowY - 18 }
        self.skillCombo = ISComboBox:new(skillsContentX, skillRowY, skillComboWidth, 24, self, nil)
        self.skillCombo:initialise()
        self.skillCombo:instantiate()
        self.skillCombo.onChange = function()
            self:onSkillSelectionChanged()
        end
        self:addChild(self.skillCombo)
        self:addToTab("skills", self.skillCombo)

        local levelComboX = skillsContentX + skillComboWidth + 24
        local levelComboWidth = 140
        if levelComboX + levelComboWidth > skillsContentX + skillsContentWidth then
            levelComboX = skillsContentX
        end
        local levelRowY = skillRowY
        if levelComboX == skillsContentX then
            levelRowY = skillRowY + 36
        end
        self.skillLevelLabelPos = { x = levelComboX, y = levelRowY - 18 }
        self.skillLevelCombo = ISComboBox:new(levelComboX, levelRowY, levelComboWidth, 24, self, nil)
        self.skillLevelCombo:initialise()
        self.skillLevelCombo:instantiate()
        self:addChild(self.skillLevelCombo)
        self:addToTab("skills", self.skillLevelCombo)

        local infoY = math.max(skillRowY, levelRowY) + 32
        self.skillCurrentLevelPos = { x = skillsContentX, y = infoY }
        local buttonRowY = infoY + 24
        local tripleWidth = math.floor((skillsContentWidth - (BUTTON_GAP * 2)) / 3)
        if tripleWidth < 140 then
            tripleWidth = 140
        end
        self.skillApplyLevelBtn = ISButton:new(skillsContentX, buttonRowY, tripleWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_ApplyLevel", "Apply Level"), self, CheatMenuUI.onSkillApplyLevel)
        self.skillApplyLevelBtn:initialise()
        self.skillApplyLevelBtn:instantiate()
        self:addChild(self.skillApplyLevelBtn)
        self:addToTab("skills", self.skillApplyLevelBtn)

        local increaseX = skillsContentX + tripleWidth + BUTTON_GAP
        self.skillIncreaseBtn = ISButton:new(increaseX, buttonRowY, tripleWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_Increase", "Increase"), self, CheatMenuUI.onSkillIncrease)
        self.skillIncreaseBtn:initialise()
        self.skillIncreaseBtn:instantiate()
        self:addChild(self.skillIncreaseBtn)
        self:addToTab("skills", self.skillIncreaseBtn)

        local decreaseX = increaseX + tripleWidth + BUTTON_GAP
        self.skillDecreaseBtn = ISButton:new(decreaseX, buttonRowY, tripleWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_Decrease", "Decrease"), self, CheatMenuUI.onSkillDecrease)
        self.skillDecreaseBtn:initialise()
        self.skillDecreaseBtn:instantiate()
        self:addChild(self.skillDecreaseBtn)
        self:addToTab("skills", self.skillDecreaseBtn)

        local secondRowY = buttonRowY + BUTTON_HEIGHT + BUTTON_GAP
        local doubleWidth = math.floor((skillsContentWidth - BUTTON_GAP) / 2)
        self.skillMaxSelectedBtn = ISButton:new(skillsContentX, secondRowY, doubleWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_MaxSelected", "Max Selected"), self, CheatMenuUI.onSkillMaxSelected)
        self.skillMaxSelectedBtn:initialise()
        self.skillMaxSelectedBtn:instantiate()
        self:addChild(self.skillMaxSelectedBtn)
        self:addToTab("skills", self.skillMaxSelectedBtn)

        local resetSelectedX = skillsContentX + doubleWidth + BUTTON_GAP
        self.skillResetSelectedBtn = ISButton:new(resetSelectedX, secondRowY, doubleWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_ResetSelected", "Reset Selected"), self, CheatMenuUI.onSkillResetSelected)
        self.skillResetSelectedBtn:initialise()
        self.skillResetSelectedBtn:instantiate()
        self:addChild(self.skillResetSelectedBtn)
        self:addToTab("skills", self.skillResetSelectedBtn)

        local thirdRowY = secondRowY + BUTTON_HEIGHT + BUTTON_GAP
        self.skillMaxAllBtn = ISButton:new(skillsContentX, thirdRowY, doubleWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_MaxAll", "Max All Skills"), self, CheatMenuUI.onSkillMaxAll)
        self.skillMaxAllBtn:initialise()
        self.skillMaxAllBtn:instantiate()
        self:addChild(self.skillMaxAllBtn)
        self:addToTab("skills", self.skillMaxAllBtn)

        self.skillResetAllBtn = ISButton:new(resetSelectedX, thirdRowY, doubleWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Skills_ResetAll", "Reset All Skills"), self, CheatMenuUI.onSkillResetAll)
        self.skillResetAllBtn:initialise()
        self.skillResetAllBtn:instantiate()
        self:addChild(self.skillResetAllBtn)
        self:addToTab("skills", self.skillResetAllBtn)

        local skillsSectionBottom = thirdRowY + PRIMARY_BUTTON_HEIGHT + 36
        self.skillsSection = {
            x = PADDING,
            y = skillsSectionTop,
            w = skillsSectionWidth,
            h = skillsSectionBottom - skillsSectionTop
        }

        if self.buildMoodlesUI then
            self:buildMoodlesUI()
        end

        if self.buildTraitsUI then
            self:buildTraitsUI()
        end

        if self.buildProfilesUI then
            self:buildProfilesUI()
        end

        self:setActiveTab(self.activeTab)
    end

    function CheatMenuUI:getModData()
        local data = ModData.getOrCreate(constants.MODDATA_KEY)
        data.favorites = data.favorites or {}
        data.presets = data.presets or {}
        data.config = data.config or {}
        data.profiles = data.profiles or {}
        return data
    end

    function CheatMenuUI:loadPersistentData()
        local data = self:getModData()
        self.favorites = data.favorites
        self.presets = data.presets
        self.profiles = data.profiles or {}
        self.config = data.config or {}
        local needsFlush = false
        local utilsChanged = self:ensureUtilsConfig()
        if utilsChanged then
            needsFlush = true
        end
        local toggleKey = tonumber(self.config.toggleKey)
        if not toggleKey then
            toggleKey = self:getDefaultToggleKey()
            self.config.toggleKey = toggleKey
            needsFlush = true
        end
        local main = getCheatMenuMain()
        if main and type(main.setToggleKey) == "function" then
            main.setToggleKey(toggleKey)
        end
        local preferredLanguage = self.config.language or CheatMenuText.getCurrentLanguage() or CheatMenuText.getDefaultLanguage()
        CheatMenuText.setLanguage(preferredLanguage)
        self.config.language = CheatMenuText.getCurrentLanguage()
        if needsFlush then
            self:flushPersistentData()
        end
    end

    function CheatMenuUI:getDefaultToggleKey()
        local main = getCheatMenuMain()
        if main and type(main.Config) == "table" and type(main.Config.toggleKey) == "number" then
            return main.Config.toggleKey
        end
        return Keyboard.KEY_INSERT
    end

    function CheatMenuUI:setActiveTab(tabId)
        local target = tabId or "items"
        if not self.tabControls[target] then
            target = "items"
        end
        self.activeTab = target

        for id, controls in pairs(self.tabControls) do
            local visible = id == target
            for _, control in ipairs(controls) do
                if control.setVisible then
                    control:setVisible(visible)
                else
                    control.visible = visible
                end
                if control.clearStencil then
                    control:clearStencil()
                end
            end
        end

        if self.tabSelector then
            self:populateTabSelector(target)
        end
        if target == "skills" then
            self:syncSkillUI()
        elseif target == "traits" and self.syncTraitsUI then
            self:syncTraitsUI()
        elseif target == "moodles" and self.syncMoodlesUI then
            self:syncMoodlesUI()
        end
    end

    function CheatMenuUI:onTabButtonClicked(button)
        if not button or not button.internal then
            return
        end
        if button.internal ~= self.activeTab then
            self:setActiveTab(button.internal)
        end
    end

    function CheatMenuUI:onApplyLanguage()
        if not self.languageCombo or not self.languageCombo.options then
            return
        end
        local option = self.languageCombo.options[self.languageCombo.selected]
        if not option or not option.data then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusLanguageMissing", "Select a language first."))
            return
        end
        local previous = self.config and self.config.language or CheatMenuText.getCurrentLanguage()
        CheatMenuText.setLanguage(option.data)
        self.config = self.config or {}
        self.config.language = CheatMenuText.getCurrentLanguage()
        self:flushPersistentData()
        self:populateLanguageOptions(self.config.language)
        local selectedItem = self.itemsList and self.itemsList.items and self.itemsList.items[self.itemsList.selected]
        local selectedFullType = selectedItem and selectedItem.item and selectedItem.item.fullType or nil
        CheatMenuItems.refresh()
        self:refreshCatalog()
        if selectedFullType then
            self:selectItemByFullType(selectedFullType)
        end
        self:refreshFavoritesUI()
        self:refreshPresetsUI()
        self:applyTranslations()
        local changed = self.config.language ~= previous
        local messageKey = changed and "UI_ZedToolbox_StatusLanguageApplied" or "UI_ZedToolbox_StatusLanguageApplied"
        self:setStatus(true, CheatMenuText.get(messageKey, "Language updated."))
    end

    function CheatMenuUI:onApplyHotkey()
        if not self.hotkeyCombo or not self.hotkeyCombo.options then
            return
        end
        local option = self.hotkeyCombo.options[self.hotkeyCombo.selected]
        if not option or not option.data then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusHotkeyMissing", "Select a key first."))
            return
        end
        local keyCode = option.data
        self.config = self.config or {}
        local changed = self.config.toggleKey ~= keyCode
        self.config.toggleKey = keyCode
        self:flushPersistentData()
        local main = getCheatMenuMain()
        if main and type(main.setToggleKey) == "function" then
            main.setToggleKey(keyCode)
        end
        self:populateHotkeyOptions(keyCode)
        local messageKey = changed and "UI_ZedToolbox_StatusHotkeyApplied" or "UI_ZedToolbox_StatusHotkeyApplied"
        self:setStatus(true, CheatMenuText.get(messageKey, "Hotkey updated."))
    end

    function CheatMenuUI:onGodModeChanged()
        if not self.godModeCombo or not self.godModeCombo.options then
            return
        end
        local option = self.godModeCombo.options[self.godModeCombo.selected]
        local enabled = option and option.data and true or false
        self:updateUtilsConfig("godMode", enabled)
        CheatMenuUtils.setGodMode(enabled)
        local messageKey = enabled and "UI_ZedToolbox_StatusGodModeOn" or "UI_ZedToolbox_StatusGodModeOff"
        self:setStatus(true, CheatMenuText.get(messageKey, enabled and "God Mode enabled." or "God Mode disabled."))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onHitKillChanged()
        if not self.hitKillCombo or not self.hitKillCombo.options then
            return
        end
        local option = self.hitKillCombo.options[self.hitKillCombo.selected]
        local enabled = option and option.data and true or false
        self:updateUtilsConfig("hitKill", enabled)
        CheatMenuUtils.setHitKill(enabled)
        local messageKey = enabled and "UI_ZedToolbox_StatusHitKillOn" or "UI_ZedToolbox_StatusHitKillOff"
        self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Hit Kill enabled." or "Hit Kill disabled."))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onInfiniteStaminaChanged()
        if not self.infiniteStaminaCombo or not self.infiniteStaminaCombo.options then
            return
        end
        local option = self.infiniteStaminaCombo.options[self.infiniteStaminaCombo.selected]
        local enabled = option and option.data and true or false
        self:updateUtilsConfig("infiniteStamina", enabled)
        CheatMenuUtils.setInfiniteStamina(enabled)
        local messageKey = enabled and "UI_ZedToolbox_StatusInfiniteStaminaOn" or "UI_ZedToolbox_StatusInfiniteStaminaOff"
        self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Infinite stamina enabled." or "Infinite stamina disabled."))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onInstantBuildChanged()
        if not self.instantBuildCombo or not self.instantBuildCombo.options then
            return
        end
        local option = self.instantBuildCombo.options[self.instantBuildCombo.selected]
        local enabled = option and option.data and true or false
        self:updateUtilsConfig("instantBuild", enabled)
        CheatMenuUtils.setInstantBuild(enabled)
        local messageKey = enabled and "UI_ZedToolbox_StatusInstantBuildOn" or "UI_ZedToolbox_StatusInstantBuildOff"
        self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Instant build enabled." or "Instant build disabled."))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onNoNegativeEffectsChanged()
        if not self.noNegativeEffectsCombo or not self.noNegativeEffectsCombo.options then
            return
        end
        local option = self.noNegativeEffectsCombo.options[self.noNegativeEffectsCombo.selected]
        local enabled = option and option.data and true or false
        self:updateUtilsConfig("noNegativeEffects", enabled)
        CheatMenuUtils.setNoNegativeEffects(enabled)
        local messageKey = enabled and "UI_ZedToolbox_StatusNoNegativeEffectsOn" or "UI_ZedToolbox_StatusNoNegativeEffectsOff"
        self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Negative effects cleared automatically." or "Negative effect protection disabled."))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onNoHungerThirstChanged()
        if not self.noHungerThirstCombo or not self.noHungerThirstCombo.options then
            return
        end
        local option = self.noHungerThirstCombo.options[self.noHungerThirstCombo.selected]
        local enabled = option and option.data and true or false
        self:updateUtilsConfig("noHungerThirst", enabled)
        CheatMenuUtils.setNoHungerThirst(enabled)
        local messageKey = enabled and "UI_ZedToolbox_StatusNoHungerThirstOn" or "UI_ZedToolbox_StatusNoHungerThirstOff"
        self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Hunger and thirst disabled." or "Hunger and thirst restored to normal."))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onSpeedChanged()
        if not self.speedCombo or not self.speedCombo.options then
            return
        end
        local option = self.speedCombo.options[self.speedCombo.selected]
        local multiplier = clamp(option and option.data or 1, 0.5, 5)
        self:updateUtilsConfig("speedMultiplier", multiplier)
        CheatMenuUtils.setSpeedMultiplier(multiplier)
        self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSpeedApplied", "Speed set to %1x.", multiplier))
        self:syncUtilsUI()
    end

    function CheatMenuUI:onHealClicked()
        local success = CheatMenuUtils.healPlayer()
        if success then
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusHealed", "Player fully healed."))
        else
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusHealFailed", "Player not ready."))
        end
    end

    function CheatMenuUI:onClearZombiesClicked()
        local utilsState = CheatMenuUtils.getState() or {}
        local finalRadius = utilsState.clearRadius or 15
        local cleared = CheatMenuUtils.clearZombies(finalRadius)
        if cleared > 0 then
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusClearZombies", "%1 zombies removed within %2 tiles.", cleared, finalRadius))
        else
            self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusClearZombiesNone", "No zombies found within %1 tiles.", finalRadius))
        end
    end

    function CheatMenuUI:populateLanguageOptions(selectedId)
        if not self.languageCombo then
            return
        end
        local targetId = selectedId or (self.config and self.config.language) or CheatMenuText.getCurrentLanguage()
        local options = CheatMenuText.getLanguages()
        self.languageCombo:clear()
        local fallbackIndex = 1
        for index, entry in ipairs(options) do
            self.languageCombo:addOptionWithData(entry.label, entry.id)
            if entry.id == targetId then
                fallbackIndex = index
            end
        end
        self.languageCombo.selected = fallbackIndex
    end

    function CheatMenuUI:populateHotkeyOptions(selectedKey)
        if not self.hotkeyCombo then
            return
        end
        local targetKey = tonumber(selectedKey) or tonumber(self.config and self.config.toggleKey) or self:getDefaultToggleKey()
        self.hotkeyCombo:clear()
        local index = 1
        local fallbackIndex = 1
        for _, option in ipairs(getHotkeyOptions()) do
            self.hotkeyCombo:addOptionWithData(option.label, option.code)
            if option.code == targetKey then
                fallbackIndex = index
            end
            index = index + 1
        end
        self.hotkeyCombo.selected = fallbackIndex
    end

    function CheatMenuUI:refreshTargetCombo()
        if not self.targetCombo then
            return
        end
        local previous = self:getTargetSelection()
        self.targetCombo:clear()
        self.targetCombo:addOptionWithData(CheatMenuText.get("UI_ZedToolbox_TargetInventory", "Inventory"), "inventory")
        self.targetCombo:addOptionWithData(CheatMenuText.get("UI_ZedToolbox_TargetGround", "Ground"), "ground")
        self:setTargetSelection(previous)
    end

    function CheatMenuUI:applyTranslations()
        self:populateTabSelector(self.activeTab)
        if self.addFavoriteBtn then
            self.addFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_AddFavorite", "Add Favorite"))
        end
        if self.useFavoriteBtn then
            self.useFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_UseFavorite", "Use Favorite"))
        end
        if self.spawnFavoriteBtn then
            self.spawnFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SpawnFavorite", "Spawn Favorite"))
        end
        if self.removeFavoriteBtn then
            self.removeFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_RemoveFavorite", "Remove Favorite"))
        end
        if self.savePresetBtn then
            self.savePresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SavePreset", "Save Preset"))
        end
        if self.applyPresetBtn then
            self.applyPresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_ApplyPreset", "Apply Preset"))
        end
        if self.spawnPresetBtn then
            self.spawnPresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SpawnPreset", "Spawn Preset"))
        end
        if self.removePresetBtn then
            self.removePresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_RemovePreset", "Remove Preset"))
        end
        if self.spawnBtn then
            self.spawnBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Spawn", "Spawn"))
        end
        if self.applyLanguageBtn then
            self.applyLanguageBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Apply", "Apply"))
        end
        if self.applyHotkeyBtn then
            self.applyHotkeyBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SetHotkey", "Set Key"))
        end
        if self.healButton then
            self.healButton:setTitle(CheatMenuText.get("UI_ZedToolbox_Utils_Heal", "Heal Player"))
        end
        if self.clearZombiesButton then
            self.clearZombiesButton:setTitle(CheatMenuText.get("UI_ZedToolbox_Utils_ClearZombies", "Clear Nearby Zombies"))
        end
        if self.skillApplyLevelBtn then
            self.skillApplyLevelBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_ApplyLevel", "Apply Level"))
        end
        if self.skillIncreaseBtn then
            self.skillIncreaseBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_Increase", "Increase"))
        end
        if self.skillDecreaseBtn then
            self.skillDecreaseBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_Decrease", "Decrease"))
        end
        if self.skillMaxSelectedBtn then
            self.skillMaxSelectedBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_MaxSelected", "Max Selected"))
        end
        if self.skillResetSelectedBtn then
            self.skillResetSelectedBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_ResetSelected", "Reset Selected"))
        end
        if self.skillMaxAllBtn then
            self.skillMaxAllBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_MaxAll", "Max All Skills"))
        end
        if self.skillResetAllBtn then
            self.skillResetAllBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Skills_ResetAll", "Reset All Skills"))
        end
        if self.addTraitBtn then
            self.addTraitBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Traits_Add", "Add Trait"))
        end
        if self.removeTraitBtn then
            self.removeTraitBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Traits_Remove", "Remove Trait"))
        end
        if self.resetTraitsBtn then
            self.resetTraitsBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Traits_Reset", "Reset Traits"))
        end
        if self.addAllPositiveTraitsBtn then
            self.addAllPositiveTraitsBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Traits_AddAllPositive", "Apply All Positive"))
        end
        if self.addAllNegativeTraitsBtn then
            self.addAllNegativeTraitsBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Traits_AddAllNegative", "Apply All Negative"))
        end
        if self.moodleSetMinBtn then
            self.moodleSetMinBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Moodles_SetMin", "Set Minimum"))
        end
        if self.moodleSetMaxBtn then
            self.moodleSetMaxBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Moodles_SetMax", "Set Maximum"))
        end
        if self.moodleNormalizeBtn then
            self.moodleNormalizeBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Moodles_Normalize", "Normalize"))
        end
        if self.moodlesClearNegativeBtn then
            self.moodlesClearNegativeBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Moodles_ClearNegatives", "Clear All Negatives"))
        end
        if self.moodlesMaxAllBtn then
            self.moodlesMaxAllBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Moodles_MaxAll", "Max All Moodles"))
        end
        if self.createProfileBtn then
            self.createProfileBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Profile_Create", "Create"))
        end
        if self.renameProfileBtn then
            self.renameProfileBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Profile_Rename", "Rename"))
        end
        if self.deleteProfileBtn then
            self.deleteProfileBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Profile_Delete", "Delete"))
        end
        if self.applyProfileBtn then
            self.applyProfileBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Profile_Apply", "Apply Profile"))
        end
        local selectedDefinition = self:getSelectedSkillDefinition()
        local selectedType = selectedDefinition and selectedDefinition.type or nil
        local selectedLevel = self:getSelectedSkillLevel()
        self:populateSkillOptions(selectedType)
        self:populateSkillLevelOptions(selectedLevel)
        self:syncSkillUI()
        if self.refreshTraitsUI then
            self:refreshTraitsUI()
        end
        self:refreshProfilesUI()
        if self.refreshMoodlesUI then
            self:refreshMoodlesUI()
        end
        self:refreshTargetCombo()
        self:refreshCategoryLabels()
        self:populateUtilsOptions()
        self:populateLanguageOptions(self.config and self.config.language)
        self:populateHotkeyOptions(self.config and self.config.toggleKey)
        self:syncUtilsUI()
    end

    function CheatMenuUI:refreshCategoryLabels()
        if not self.categoryList or not self.categoryList.items then
            return
        end
        for _, item in ipairs(self.categoryList.items) do
            if item and item.item then
                item.text = deps.getCategoryLabel(item.item)
            end
        end
    end

    function CheatMenuUI:flushPersistentData()
        local data = self:getModData()
        data.favorites = self.favorites
        data.presets = self.presets
        data.config = self.config
        data.profiles = self.profiles
        if ModData.transmit then
            ModData.transmit(constants.MODDATA_KEY)
        end
    end

    function CheatMenuUI:setStatus(success, message)
        self.status.message = message or ""
        self.status.color = success and constants.STATUS_SUCCESS or constants.STATUS_ERROR
    end

    function CheatMenuUI:show()
        self:setVisible(true)
        self:bringToTop()
        self:refreshCatalog()
        self:loadPersistentData()
        self:refreshFavoritesUI()
        self:refreshPresetsUI()
        self:refreshProfilesUI()
        if self.refreshTraitsUI then
            self:refreshTraitsUI()
        end
        if self.refreshMoodlesUI then
            self:refreshMoodlesUI()
        end
        self:populateLanguageOptions(self.config and self.config.language)
        self:populateHotkeyOptions(self.config and self.config.toggleKey)
        self:applyTranslations()
        self:setActiveTab(self.activeTab)
        self:syncSkillUI()
        if self.syncTraitsUI then
            self:syncTraitsUI()
        end
        if self.syncMoodlesUI then
            self:syncMoodlesUI()
        end
        if self.activeTab == "items" then
            self.searchBox:focus()
        end
    end

    function CheatMenuUI:close()
        self:setVisible(false)
        self:clearStatus()
    end

    function CheatMenuUI:clearStatus()
        self.status.message = ""
    end

    function CheatMenuUI:onClose()
        self:close()
    end

    function CheatMenuUI:prerender()
        ISPanel.prerender(self)
        self:drawRect(0, 0, self.width, self.height, 0.92, 0, 0, 0)
        self:drawRectBorder(0, 0, self.width, self.height, 0.9, 0.8, 0.8, 0.8)

        local function drawSection(panel, section)
            if not section then
                return
            end
            panel:drawRect(section.x, section.y, section.w, section.h, SECTION_BG_ALPHA, 0, 0, 0)
            panel:drawRectBorder(section.x, section.y, section.w, section.h, SECTION_BORDER_ALPHA, 0.6, 0.6, 0.6)
        end

        if self.activeTab == "items" then
            drawSection(self, self.favoritesSection)
            drawSection(self, self.presetsSection)
            drawSection(self, self.bottomSection)
        elseif self.activeTab == "utils" then
            drawSection(self, self.utilsSection)
        elseif self.activeTab == "skills" then
            drawSection(self, self.skillsSection)
        elseif self.activeTab == "traits" then
            drawSection(self, self.traitsSection)
        elseif self.activeTab == "moodles" then
            drawSection(self, self.moodlesSection)
        elseif self.activeTab == "profiles" then
            drawSection(self, self.profilesSection)
        end

        if self.status.message ~= "" then
            self:drawText(self.status.message, PADDING, self.height - 36, self.status.color.r, self.status.color.g, self.status.color.b, 1, UIFont.Small)
        end

        self:drawTextRight(CREDIT_TEXT, self.width - PADDING, self.height - 20, 0.7, 0.7, 0.7, 1, UIFont.Small)

        self:drawTextCentre(CheatMenuText.get("UI_ZedToolbox_Title", "Zed Tool"), self.width / 2, 12, 1, 1, 1, 1, UIFont.Medium)
        if self.activeTab == "items" and self.searchLabelPos then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Search", "Search"), self.searchLabelPos.x, self.searchLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "items" then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Categories", "Categories"), self.categoryList.x, self.categoryList.y - 20, 0.8, 0.8, 0.8, 1, UIFont.Small)
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Items", "Items"), self.itemsList.x, self.itemsList.y - 20, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "items" and self.favoritesLabelPos then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Favorites", "Favorites"), self.favoritesLabelPos.x, self.favoritesLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "items" then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_PresetName", "Preset Name"), self.presetNameBox.x, self.presetNameBox.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "items" and self.presetsLabelPos then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Presets", "Presets"), self.presetsLabelPos.x, self.presetsLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "items" then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_BaseId", "Base ID"), self.baseIdBox.x, self.baseIdBox.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Quantity", "Quantity"), self.quantityBox.x, self.quantityBox.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Target", "Target"), self.targetCombo.x, self.targetCombo.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
        elseif self.activeTab == "skills" then
            if self.skillComboLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Skills_LabelSkill", "Skill"), self.skillComboLabelPos.x, self.skillComboLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.skillLevelLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Skills_LabelLevel", "Target Level"), self.skillLevelLabelPos.x, self.skillLevelLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.skillCurrentLevelPos and self.skillCurrentLevelText then
                self:drawText(self.skillCurrentLevelText, self.skillCurrentLevelPos.x, self.skillCurrentLevelPos.y, 0.75, 0.75, 0.75, 1, UIFont.Small)
            end
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.godMode then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_GodMode", "God Mode"), self.utilsLabelPositions.godMode.x, self.utilsLabelPositions.godMode.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.hitKill then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_HitKill", "Hit Kill"), self.utilsLabelPositions.hitKill.x, self.utilsLabelPositions.hitKill.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.infiniteStamina then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_InfiniteStamina", "Infinite Stamina"), self.utilsLabelPositions.infiniteStamina.x, self.utilsLabelPositions.infiniteStamina.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.instantBuild then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_InstantBuild", "Instant Build"), self.utilsLabelPositions.instantBuild.x, self.utilsLabelPositions.instantBuild.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.noNegativeEffects then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_NoNegativeEffects", "No Negative Effects"), self.utilsLabelPositions.noNegativeEffects.x, self.utilsLabelPositions.noNegativeEffects.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.noHungerThirst then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_NoHungerThirst", "No Hunger & Thirst"), self.utilsLabelPositions.noHungerThirst.x, self.utilsLabelPositions.noHungerThirst.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "utils" and self.utilsLabelPositions.speed then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_Speed", "Speed"), self.utilsLabelPositions.speed.x, self.utilsLabelPositions.speed.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "config" and self.languageLabelPos then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_ConfigLanguage", "Language"), self.languageLabelPos.x, self.languageLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "config" and self.hotkeyLabelPos then
            self:drawText(CheatMenuText.get("UI_ZedToolbox_ConfigHotkey", "Toggle Hotkey"), self.hotkeyLabelPos.x, self.hotkeyLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
        if self.activeTab == "traits" then
            if self.traitsListLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Traits", "Traits"), self.traitsListLabelPos.x, self.traitsListLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.traitDetailLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Traits_Details", "Details"), self.traitDetailLabelPos.x, self.traitDetailLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.traitDetail and self.traitDetail.lines and self.traitDetailTextPos then
                local y = self.traitDetailTextPos.y
                for index, line in ipairs(self.traitDetail.lines) do
                    local color = (self.traitDetail.colors and self.traitDetail.colors[index]) or { r = 0.75, g = 0.75, b = 0.75 }
                    self:drawText(line, self.traitDetailTextPos.x, y, color.r, color.g, color.b, 1, UIFont.Small)
                    y = y + 20
                end
            end
        elseif self.activeTab == "moodles" then
            if self.moodlesListLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Moodles_List", "Moodles"), self.moodlesListLabelPos.x, self.moodlesListLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.moodleDetailLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Moodles_Details", "Details"), self.moodleDetailLabelPos.x, self.moodleDetailLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.moodleDetail and self.moodleDetail.lines and self.moodleDetailTextPos then
                local y = self.moodleDetailTextPos.y
                for index, line in ipairs(self.moodleDetail.lines) do
                    local color = (self.moodleDetail.colors and self.moodleDetail.colors[index]) or { r = 0.75, g = 0.75, b = 0.75 }
                    self:drawText(line, self.moodleDetailTextPos.x, y, color.r, color.g, color.b, 1, UIFont.Small)
                    y = y + 20
                end
            end
        end
        if self.activeTab == "profiles" then
            if self.profilesListLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Profiles", "Profiles"), self.profilesListLabelPos.x, self.profilesListLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
            if self.profileNameLabelPos then
                self:drawText(CheatMenuText.get("UI_ZedToolbox_Profile_Name", "Profile Name"), self.profileNameLabelPos.x, self.profileNameLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            end
        end
    end
end
