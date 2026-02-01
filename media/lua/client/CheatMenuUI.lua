require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISComboBox"
require "ISUI/ISButton"

local CheatMenuItems = require "CheatMenuItems"
local CheatMenuSpawner = require "CheatMenuSpawner"
local CheatMenuText = require "CheatMenuText"
local CheatMenuLogger = require "CheatMenuLogger"
local CheatMenuUtils = require "CheatMenuUtils"

local attachItemsSection = require "ui/CheatMenuUI_Items"
local attachUtilsSection = require "ui/CheatMenuUI_Utils"
local attachSkillsSection = require "ui/CheatMenuUI_Skills"
local attachMoodlesSection = require "ui/CheatMenuUI_Moodles"
local attachZombiesSection = require "ui/CheatMenuUI_Zombies"
local attachTraitsSection = require "ui/CheatMenuUI_Traits"
local attachProfilesSection = require "ui/CheatMenuUI_Profiles"
local attachLifecycleSection = require "ui/helpers/CheatMenuUI_Lifecycle"
local Helpers = require "ui/helpers/CheatMenuUI_Helpers"

local CheatMenuUI = ISPanel:derive("CheatMenuUI")

local PANEL_WIDTH = 1100
local PANEL_HEIGHT = 600
local PADDING = 16
local COLUMN_GAP = 14
local LIST_TOP = 86
local TAB_HEIGHT = 28
local TAB_BUTTON_WIDTH = 160
local TAB_GAP = 10
local BOTTOM_HEIGHT = 190
local LEFT_WIDTH = 180
local CENTER_WIDTH = 440
local RIGHT_WIDTH = PANEL_WIDTH - (PADDING * 2) - LEFT_WIDTH - CENTER_WIDTH - (COLUMN_GAP * 2)
local MODDATA_KEY = "ZedToolbox"
local BUTTON_HEIGHT = 22
local BUTTON_GAP = 4
local BUTTON_ROW_GAP = 12
local SECTION_GAP = 16
local PRESET_NAME_HEIGHT = 24
local PRESET_NAME_GAP = 6
local SPAWN_BUTTON_WIDTH = 220
local MIN_FAVORITES_HEIGHT = 140
local MIN_PRESETS_HEIGHT = 120
local SECTION_BG_ALPHA = 0.22
local SECTION_BORDER_ALPHA = 0.38
local BOTTOM_PANEL_PADDING = 14
local PRIMARY_BUTTON_HEIGHT = 34
local REMOVE_BUTTON_EXTRA_GAP = 6
local SEARCH_LABEL_WIDTH = 60
local SEARCH_FIELD_WIDTH = 280
local PRESET_HEADER_GAP = 10
local CREDIT_TEXT = "by CodeMaster"

CheatMenuUI.Width = PANEL_WIDTH
CheatMenuUI.Height = PANEL_HEIGHT

local STATUS_SUCCESS = { r = 0.55, g = 0.85, b = 0.55 }
local STATUS_ERROR = { r = 0.93, g = 0.4, b = 0.4 }
local clamp = Helpers.clamp
local getHotkeyOptions = Helpers.getHotkeyOptions
local getCheatMenuMain = Helpers.getCheatMenuMain
local lower = Helpers.lower
local trim = Helpers.trim
local clearControl = Helpers.clearControl
local getListSelection = Helpers.getListSelection
local getItemDisplayName = Helpers.getItemDisplayName
local getCategoryLabel = Helpers.getCategoryLabel
local MAX_SKILL_LEVEL = Helpers.MAX_SKILL_LEVEL
local DEFAULT_SKILL_ENTRIES = Helpers.DEFAULT_SKILL_ENTRIES
local getPlayerCharacter = Helpers.getPlayerCharacter
local buildSkillDefinitions = Helpers.buildSkillDefinitions
local clampSkillLevel = Helpers.clampSkillLevel
local getPlayerSkillLevel = Helpers.getPlayerSkillLevel
local applySkillLevel = Helpers.applySkillLevel

local LIFECYCLE_CONSTANTS = {
    PADDING = PADDING,
    COLUMN_GAP = COLUMN_GAP,
    LIST_TOP = LIST_TOP,
    TAB_HEIGHT = TAB_HEIGHT,
    TAB_BUTTON_WIDTH = TAB_BUTTON_WIDTH,
    TAB_GAP = TAB_GAP,
    BOTTOM_HEIGHT = BOTTOM_HEIGHT,
    LEFT_WIDTH = LEFT_WIDTH,
    CENTER_WIDTH = CENTER_WIDTH,
    RIGHT_WIDTH = RIGHT_WIDTH,
    MODDATA_KEY = MODDATA_KEY,
    BUTTON_HEIGHT = BUTTON_HEIGHT,
    BUTTON_GAP = BUTTON_GAP,
    BUTTON_ROW_GAP = BUTTON_ROW_GAP,
    SECTION_GAP = SECTION_GAP,
    PRESET_NAME_HEIGHT = PRESET_NAME_HEIGHT,
    PRESET_NAME_GAP = PRESET_NAME_GAP,
    SPAWN_BUTTON_WIDTH = SPAWN_BUTTON_WIDTH,
    MIN_FAVORITES_HEIGHT = MIN_FAVORITES_HEIGHT,
    MIN_PRESETS_HEIGHT = MIN_PRESETS_HEIGHT,
    SECTION_BG_ALPHA = SECTION_BG_ALPHA,
    SECTION_BORDER_ALPHA = SECTION_BORDER_ALPHA,
    BOTTOM_PANEL_PADDING = BOTTOM_PANEL_PADDING,
    PRIMARY_BUTTON_HEIGHT = PRIMARY_BUTTON_HEIGHT,
    REMOVE_BUTTON_EXTRA_GAP = REMOVE_BUTTON_EXTRA_GAP,
    SEARCH_LABEL_WIDTH = SEARCH_LABEL_WIDTH,
    SEARCH_FIELD_WIDTH = SEARCH_FIELD_WIDTH,
    PRESET_HEADER_GAP = PRESET_HEADER_GAP,
    CREDIT_TEXT = CREDIT_TEXT,
    STATUS_SUCCESS = STATUS_SUCCESS,
    STATUS_ERROR = STATUS_ERROR
}

function CheatMenuUI:new(x, y)
    local o = ISPanel:new(x, y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.moveWithMouse = true
    o:noBackground()
    o.status = { message = "", color = STATUS_SUCCESS }
    o.catalog = {}
    o.selectedCategory = nil
    o.favorites = {}
    o.presets = {}
    o.profiles = {}
    o.config = {}
    o.activeTab = "items"
    o.tabSelector = nil
    o.tabButtons = {}
    o.tabDefinitions = {
        { id = "items", labelKey = "UI_ZedToolbox_TabItems", fallback = "Item Spawns" },
        { id = "utils", labelKey = "UI_ZedToolbox_TabUtils", fallback = "Utils" },
        { id = "zombies", labelKey = "UI_ZedToolbox_TabZombies", fallback = "Zombies" },
        { id = "skills", labelKey = "UI_ZedToolbox_TabSkills", fallback = "Skills" },
        { id = "moodles", labelKey = "UI_ZedToolbox_TabMoodles", fallback = "Moodles" },
        { id = "traits", labelKey = "UI_ZedToolbox_TabTraits", fallback = "Traits" },
        { id = "profiles", labelKey = "UI_ZedToolbox_TabProfiles", fallback = "Profiles" },
        { id = "config", labelKey = "UI_ZedToolbox_TabConfig", fallback = "Config" }
    }
    o.tabControls = { items = {}, utils = {}, zombies = {}, skills = {}, moodles = {}, traits = {}, config = {}, profiles = {} }
    o.utilsSpeedValues = { 1, 1.5, 2, 3, 4, 5 }
    o.utilsLabelPositions = {}
    o.skillDefinitions = buildSkillDefinitions()
    o.skillCurrentLevelText = ""
    return o
end

function CheatMenuUI:addToTab(tabId, control)
    if not control then
        return
    end
    self.tabControls[tabId] = self.tabControls[tabId] or {}
    table.insert(self.tabControls[tabId], control)
end

function CheatMenuUI:populateTabSelector(selectedId)
    if not self.tabSelector then
        return
    end
    local target = selectedId or self.activeTab or "items"
    local fallbackIndex = 1
    if self.tabSelector.clear then
        self.tabSelector:clear()
    end
    for index, definition in ipairs(self.tabDefinitions or {}) do
        local label = CheatMenuText.get(definition.labelKey, definition.fallback)
        if self.tabSelector.addOptionWithData then
            self.tabSelector:addOptionWithData(label, definition.id)
        else
            self.tabSelector:addOption(label)
        end
        if definition.id == target then
            fallbackIndex = index
        end
    end
    self.isUpdatingTabSelector = true
    self.tabSelector.selected = fallbackIndex
    self.isUpdatingTabSelector = false
end

function CheatMenuUI:onTabSelectionChanged(combo)
    if self.isUpdatingTabSelector then
        return
    end
    local source = combo or self.tabSelector
    if not source or not source.options then
        return
    end
    local index = source.selected or 1
    local option = source.options[index]
    local targetId = option and option.data
    if not targetId and self.tabDefinitions then
        local definition = self.tabDefinitions[index]
        targetId = definition and definition.id or targetId
    end
    if targetId and targetId ~= self.activeTab then
        self:setActiveTab(targetId)
    end
end

attachItemsSection(CheatMenuUI, {
    clearControl = clearControl,
    getListSelection = getListSelection,
    getItemDisplayName = getItemDisplayName,
    getCategoryLabel = getCategoryLabel,
    lower = lower,
    trim = trim,
    CheatMenuItems = CheatMenuItems,
    CheatMenuText = CheatMenuText,
    CheatMenuSpawner = CheatMenuSpawner
})

attachUtilsSection(CheatMenuUI, {
    clamp = clamp,
    CheatMenuText = CheatMenuText,
    CheatMenuUtils = CheatMenuUtils
})

attachZombiesSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    CheatMenuUtils = CheatMenuUtils,
    clamp = clamp,
    getPlayerCharacter = getPlayerCharacter
})

attachSkillsSection(CheatMenuUI, {
    buildSkillDefinitions = buildSkillDefinitions,
    clampSkillLevel = clampSkillLevel,
    MAX_SKILL_LEVEL = MAX_SKILL_LEVEL,
    CheatMenuText = CheatMenuText,
    getPlayerCharacter = getPlayerCharacter,
    getPlayerSkillLevel = getPlayerSkillLevel,
    applySkillLevel = applySkillLevel
})

attachMoodlesSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    getPlayerCharacter = getPlayerCharacter,
    getListSelection = getListSelection
})

attachTraitsSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    lower = lower,
    getPlayerCharacter = getPlayerCharacter,
    getListSelection = getListSelection
})

attachProfilesSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    clamp = clamp,
    trim = trim,
    lower = lower,
    getListSelection = getListSelection,
    CheatMenuText = CheatMenuText,
    CheatMenuUtils = CheatMenuUtils,
    getPlayerCharacter = getPlayerCharacter,
    getPlayerSkillLevel = getPlayerSkillLevel,
    applySkillLevel = applySkillLevel
})

attachLifecycleSection(CheatMenuUI, {
    clamp = clamp,
    CheatMenuItems = CheatMenuItems,
    CheatMenuUtils = CheatMenuUtils,
    CheatMenuText = CheatMenuText,
    getHotkeyOptions = getHotkeyOptions,
    getCheatMenuMain = getCheatMenuMain,
    getListSelection = getListSelection,
    getCategoryLabel = getCategoryLabel,
    constants = LIFECYCLE_CONSTANTS
})

local GUARD_METHODS = {
    "onCategoryChanged",
    "onItemSelected",
    "onFilterChanged",
    "onFavoriteSelected",
    "onAddFavorite",
    "onUseFavorite",
    "onSpawnFavorite",
    "onRemoveFavorite",
    "onSavePreset",
    "onPresetSelected",
    "onApplyPreset",
    "onSpawnPreset",
    "onRemovePreset",
    "onApplyHotkey",
    "onSpawnClicked",
    "onGodModeChanged",
    "onHitKillChanged",
    "onInfiniteStaminaChanged",
    "onInstantBuildChanged",
    "onNoNegativeEffectsChanged",
    "onNoHungerThirstChanged",
    "onSpeedChanged",
    "onHealClicked",
    "onClearZombiesClicked",
    "onZombiesKillNearby",
    "onZombiesKillScreen",
    "onZombiesFreeze",
    "onZombiesUnfreeze",
    "onZombiesIgnore",
    "onZombiesRestore",
    "onZombiesSpawn",
    "onTraitSelected",
    "onTraitAdd",
    "onTraitRemove",
    "onTraitAddAllPositive",
    "onTraitAddAllNegative",
    "onTraitsReset",
    "onProfileCreate",
    "onProfileApply",
    "onProfileRename",
    "onProfileDelete",
    "onMoodleSelected",
    "onMoodleSetMin",
    "onMoodleSetMax",
    "onMoodleNormalize",
    "onMoodlesClearNegative",
    "onMoodlesMaxAll",
}

for _, methodName in ipairs(GUARD_METHODS) do
    CheatMenuLogger.wrap(CheatMenuUI, methodName, "UI." .. methodName)
end

return CheatMenuUI